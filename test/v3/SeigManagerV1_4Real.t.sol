// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../../src/stake/managers/SeigManagerV1_4.sol";
import "../../src/stake/managers/SeigManagerV1_4Storage.sol";
import "../../src/stake/managers/SeigManagerStorage.sol";

/// @title SeigManagerV1_4RealTest
/// @notice 실제 SeigManagerV1_4 컨트랙트의 순수 함수 테스트
/// @dev View 함수 및 계산 로직 검증 (커버리지용)

// ==========================================
// Minimal Mock for coinage
// ==========================================
contract MinimalCoinage {
    uint256 public totalSupply;
    uint256 public factor = 1e27;
    mapping(address => uint256) public balanceOf;

    function setTotalSupply(uint256 _supply) external {
        totalSupply = _supply;
    }

    function setBalance(address account, uint256 amount) external {
        totalSupply = totalSupply - balanceOf[account] + amount;
        balanceOf[account] = amount;
    }
}

/// @notice SeigManagerV1_4의 순수 계산 함수 테스트를 위한 Harness
contract SeigManagerV1_4Harness is SeigManagerV1_4 {

    // 초기화 함수 (owner 설정)
    function initialize() external {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // 내부 스토리지 직접 설정 (테스트용)
    function setStorageValues(
        uint256 _d,
        uint256 _theta,
        uint256 _alpha,
        uint256 _k,
        uint256 _lambda,
        uint256 _r
    ) external {
        daoDistributionRatio = _d;
        minStakingRatio = _theta;
        validatorDistributionRatio = _alpha;
        halfSaturationPoint = _k;
        stakedSeigFactor = _lambda;
        relativeSeigRate = _r;
    }

    function setMigrated(bool _migrated) external {
        v3Migrated = _migrated;
    }

    function setCoinage(address layer2, address coinage) external {
        _coinages[layer2] = RefactorCoinageSnapshotI(coinage);
    }

    // Bridged TON 직접 설정
    function setupBridgedTON(
        address layer2,
        uint256 currentBridged,
        uint256 effectiveBridged,
        bool isEligible
    ) external {
        bridgedTONInfo[layer2] = BridgedTONInfo({
            currentBridgedTON: currentBridged,
            effectiveBridgedTON: effectiveBridged,
            initialDebt: 0,
            startBlock: block.number,
            lastUpdateTime: block.timestamp,
            isEligible: isEligible
        });

        if (isEligible && effectiveBridged > 0) {
            totalEffectiveBridgedTON += effectiveBridged;
        }
    }

    function setTotalEffectiveBridgedTON(uint256 amount) external {
        totalEffectiveBridgedTON = amount;
    }

    // 슬래싱 관련 파라미터 설정
    function setSlashingParams(uint256 _maxChallengers, uint256 _maxFraudProofCost) external {
        maxChallengers = _maxChallengers;
        maxFraudProofCost = _maxFraudProofCost;
    }
}

contract SeigManagerV1_4RealTest is Test {
    SeigManagerV1_4Harness public seigManager;
    MinimalCoinage public coinage1;
    MinimalCoinage public coinage2;

    address public layer2_1 = address(0x1001);
    address public layer2_2 = address(0x1002);
    address public operator1 = address(0x2001);
    address public operator2 = address(0x2002);

    uint256 constant RAY = 1e27;

    function setUp() public {
        seigManager = new SeigManagerV1_4Harness();
        seigManager.initialize();

        coinage1 = new MinimalCoinage();
        coinage2 = new MinimalCoinage();

        // 기본 V3 파라미터 설정
        seigManager.setStorageValues(
            0.1e27,  // d = 10%
            0.1e27,  // θ = 10%
            0.2e27,  // α = 20%
            1000e27, // k = 1000
            RAY,     // λ = 1
            0.4e27   // r = 40%
        );

        // Coinage 설정
        seigManager.setCoinage(layer2_1, address(coinage1));
        seigManager.setCoinage(layer2_2, address(coinage2));

        // 스테이킹 설정
        coinage1.setBalance(operator1, 100e27);
        coinage2.setBalance(operator2, 100e27);
    }

    // ==========================================
    // hyperbolicSaturation 함수 테스트
    // ==========================================

    function test_hyperbolicSaturation_zero() public view {
        uint256 y = seigManager.hyperbolicSaturation(0, 1000e27);
        assertEq(y, 0, "y(0) should be 0");
    }

    function test_hyperbolicSaturation_halfPoint() public view {
        uint256 k = seigManager.halfSaturationPoint();
        uint256 L = 1000e27;
        uint256 y = seigManager.hyperbolicSaturation(k, L);

        // y(k) = L * k / (k + k) = L/2
        assertApproxEqRel(y, L / 2, 0.01e18, "y(k) should be L/2");
    }

    function test_hyperbolicSaturation_large() public view {
        uint256 L = 1000e27;
        uint256 y = seigManager.hyperbolicSaturation(100000e27, L);

        // y가 L에 근접해야 함
        assertGt(y, L * 99 / 100, "y(large) should approach L");
    }

    function test_hyperbolicSaturation_monotonic() public view {
        uint256 L = 1000e27;
        uint256 prev = 0;

        for (uint256 x = 100e27; x <= 10000e27; x += 1000e27) {
            uint256 y = seigManager.hyperbolicSaturation(x, L);
            assertGe(y, prev, "y should be monotonically increasing");
            prev = y;
        }
    }

    function testFuzz_hyperbolicSaturation_bounded(uint256 x, uint256 L) public view {
        x = bound(x, 0, 1e32); // 합리적인 범위로 제한
        L = bound(L, 1e18, 1e32);

        uint256 y = seigManager.hyperbolicSaturation(x, L);

        assertLe(y, L + 1e18, "y should not exceed L");
    }

    // ==========================================
    // checkEligibility 함수 테스트
    // ==========================================

    function test_checkEligibility_sufficient() public {
        // Bridged TON: 500, Staked: 100 (≥ 10% of 500 = 50)
        seigManager.setupBridgedTON(layer2_1, 500e27, 500e27, true);

        (bool eligible, uint256 required, uint256 current) = seigManager.checkEligibility(layer2_1);

        assertEq(required, 50e27, "Required should be 10% of Bridged TON");
        assertEq(current, 100e27, "Current should be staked amount");
        assertTrue(eligible, "Should be eligible");
    }

    function test_checkEligibility_insufficient() public {
        // Bridged TON: 2000, Staked: 100 (< 10% of 2000 = 200)
        seigManager.setupBridgedTON(layer2_1, 2000e27, 0, false);

        (bool eligible, uint256 required, uint256 current) = seigManager.checkEligibility(layer2_1);

        assertEq(required, 200e27, "Required should be 10% of Bridged TON");
        assertEq(current, 100e27, "Current should be staked amount");
        assertFalse(eligible, "Should not be eligible");
    }

    function test_checkEligibility_exact() public {
        // Bridged TON: 1000, Staked: 100 (= 10% of 1000)
        seigManager.setupBridgedTON(layer2_1, 1000e27, 1000e27, true);

        (bool eligible, uint256 required, uint256 current) = seigManager.checkEligibility(layer2_1);

        assertEq(required, 100e27, "Required should be 10% of Bridged TON");
        assertEq(current, 100e27, "Current should equal required");
        assertTrue(eligible, "Should be eligible when equal");
    }

    function testFuzz_checkEligibility(uint256 bridgedTON, uint256 stakedAmount) public {
        bridgedTON = bound(bridgedTON, 1e18, 1e32);
        stakedAmount = bound(stakedAmount, 0, 1e32);

        coinage1.setBalance(operator1, stakedAmount);
        seigManager.setupBridgedTON(layer2_1, bridgedTON, bridgedTON, true);

        (bool eligible, uint256 required, uint256 current) = seigManager.checkEligibility(layer2_1);

        // RAY 연산으로 인한 반올림 오차 허용 (1 wei)
        assertApproxEqAbs(required, bridgedTON / 10, 1, "Required should be ~10% of Bridged TON");
        assertEq(current, stakedAmount, "Current should match staked amount");
        assertEq(eligible, stakedAmount >= required, "Eligibility check");
    }

    // ==========================================
    // calculateL2Seigniorage 함수 테스트
    // ==========================================

    function test_calculateL2Seigniorage_proportional() public {
        seigManager.setupBridgedTON(layer2_1, 300e27, 300e27, true);

        uint256 totalY = 1000e27;
        uint256 totalX = 1000e27;

        uint256 seig = seigManager.calculateL2Seigniorage(layer2_1, totalY, totalX);

        // 300/1000 * 1000 = 300
        assertApproxEqRel(seig, 300e27, 0.01e18, "Should get proportional share");
    }

    function test_calculateL2Seigniorage_zeroEffective() public {
        seigManager.setupBridgedTON(layer2_1, 500e27, 0, false);

        uint256 seig = seigManager.calculateL2Seigniorage(layer2_1, 1000e27, 1000e27);

        assertEq(seig, 0, "Zero effective should get 0");
    }

    function test_calculateL2Seigniorage_zeroTotalX() public {
        seigManager.setupBridgedTON(layer2_1, 500e27, 500e27, true);

        uint256 seig = seigManager.calculateL2Seigniorage(layer2_1, 1000e27, 0);

        assertEq(seig, 0, "Zero totalX should return 0");
    }

    // ==========================================
    // calculateSequencerReward 함수 테스트
    // ==========================================

    function test_calculateSequencerReward_basic() public view {
        uint256 l2Seig = 1000e27;

        // α = 20%, 시퀀서 = (1-α) = 80%
        uint256 sequencerReward = seigManager.calculateSequencerReward(l2Seig);

        assertEq(sequencerReward, 800e27, "Sequencer should get (1-alpha) * seig");
    }

    function test_calculateSequencerReward_zeroAlpha() public {
        // α = 0 설정
        seigManager.setStorageValues(0.1e27, 0.1e27, 0, 1000e27, RAY, 0.4e27);

        uint256 l2Seig = 1000e27;
        uint256 sequencerReward = seigManager.calculateSequencerReward(l2Seig);

        assertEq(sequencerReward, 1000e27, "Sequencer should get 100% when alpha=0");
    }

    function testFuzz_calculateSequencerReward(uint256 l2Seig) public view {
        l2Seig = bound(l2Seig, 0, 1e32);

        uint256 sequencerReward = seigManager.calculateSequencerReward(l2Seig);
        uint256 validatorRatio = seigManager.validatorDistributionRatio();

        // sequencerReward = (1 - alpha) * l2Seig
        uint256 expected = l2Seig - (l2Seig * validatorRatio / RAY);
        assertApproxEqAbs(sequencerReward, expected, 1e18, "Sequencer reward calculation");
    }

    // ==========================================
    // V3 파라미터 View 함수 테스트
    // ==========================================

    function test_v3Parameters() public view {
        assertEq(seigManager.daoDistributionRatio(), 0.1e27, "d = 10%");
        assertEq(seigManager.minStakingRatio(), 0.1e27, "theta = 10%");
        assertEq(seigManager.validatorDistributionRatio(), 0.2e27, "alpha = 20%");
        assertEq(seigManager.halfSaturationPoint(), 1000e27, "k = 1000");
        assertEq(seigManager.stakedSeigFactor(), RAY, "lambda = 1");
        assertEq(seigManager.relativeSeigRate(), 0.4e27, "r = 40%");
    }

    // ==========================================
    // Bridged TON 추적 테스트
    // ==========================================

    function test_bridgedTONInfo() public {
        seigManager.setupBridgedTON(layer2_1, 1000e27, 1000e27, true);

        (
            uint256 currentBridged,
            uint256 effectiveBridged,
            ,
            ,
            ,
            bool isEligible
        ) = seigManager.bridgedTONInfo(layer2_1);

        assertEq(currentBridged, 1000e27, "Current bridged TON");
        assertEq(effectiveBridged, 1000e27, "Effective bridged TON");
        assertTrue(isEligible, "Should be eligible");
    }

    function test_totalEffectiveBridgedTON() public {
        seigManager.setupBridgedTON(layer2_1, 300e27, 300e27, true);
        seigManager.setupBridgedTON(layer2_2, 700e27, 700e27, true);

        assertEq(seigManager.totalEffectiveBridgedTON(), 1000e27, "Total should be sum");
    }

    function test_getEffectiveBridgedTON() public {
        seigManager.setupBridgedTON(layer2_1, 500e27, 500e27, true);

        uint256 effective = seigManager.getEffectiveBridgedTON(layer2_1);
        assertEq(effective, 500e27, "Should return effective bridged TON");
    }

    // ==========================================
    // 마이그레이션 상태 테스트
    // ==========================================

    function test_v3MigrationState() public {
        assertFalse(seigManager.v3Migrated(), "Initially not migrated");

        seigManager.setMigrated(true);
        assertTrue(seigManager.v3Migrated(), "Should be migrated");
    }

    // ==========================================
    // 슬래싱 파라미터 테스트
    // ==========================================

    function test_slashingParameters() public {
        seigManager.setSlashingParams(10, 1e18);

        assertEq(seigManager.maxChallengers(), 10, "Max challengers");
        assertEq(seigManager.maxFraudProofCost(), 1e18, "Max fraud proof cost");
    }
}
