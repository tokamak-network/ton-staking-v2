// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../../../src/mocks/MockWTON.sol";

/// @notice End-to-End 시뇨리지 분배 테스트
/// @dev 전체 시뇨리지 분배 사이클 검증
/// - 누구나 updateSeigniorage() 호출 가능
/// - V2→V3 전환 시나리오
/// - 다중 L2 동시 분배
/// - 슬래싱 후 분배 제외 확인

// ==========================================
// Mock Contracts (for this test only)
// ==========================================

contract SeigniorageFormulaMockTON {
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    constructor(uint256 _totalSupply) {
        totalSupply = _totalSupply;
    }

    function setTotalSupply(uint256 _totalSupply) external {
        totalSupply = _totalSupply;
    }
}


contract MockTot {
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;
    uint256 public factor = 1e27;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
    }

    function setFactor(uint256 _factor) external returns (bool) {
        factor = _factor;
        return true;
    }

    function setBalance(address account, uint256 amount) external {
        totalSupply = totalSupply - balanceOf[account] + amount;
        balanceOf[account] = amount;
    }
}

contract MockLayer2 {
    address public operator;
    address public seigManager;

    constructor(address _operator) {
        operator = _operator;
    }

    function setSeigManager(address _seigManager) external {
        seigManager = _seigManager;
    }

    function updateSeigniorage() external returns (bool) {
        // SeigManager.updateSeigniorage() 호출
        (bool success, ) = seigManager.call(
            abi.encodeWithSignature("updateSeigniorage()")
        );
        return success;
    }
}

contract MockRegistry {
    address[] public layer2s;
    mapping(address => bool) public isLayer2;

    function addLayer2(address layer2) external {
        layer2s.push(layer2);
        isLayer2[layer2] = true;
    }

    function numLayer2s() external view returns (uint256) {
        return layer2s.length;
    }

    function layer2ByIndex(uint256 index) external view returns (address) {
        return layer2s[index];
    }
}

contract MockLayer2Manager {
    mapping(address => address) public rollupConfigs;
    mapping(address => uint8) public status;
    uint256 public totalReceived;
    mapping(address => uint256) public layer2Received;

    function setLayerInfo(address layer2, address rollupConfig, uint8 _status) external {
        rollupConfigs[layer2] = rollupConfig;
        status[rollupConfig] = _status;
    }

    function layerInfo(address layer2) external view returns (address, uint256) {
        return (rollupConfigs[layer2], 0);
    }

    function statusLayer2(address rollupConfig) external view returns (uint8) {
        return status[rollupConfig];
    }

    function transferL2Seigniorage(address layer2, uint256 amount) external {
        totalReceived += amount;
        layer2Received[layer2] += amount;
    }
}

contract MockDepositManager {
    // Empty mock
}

/// @notice 간소화된 SeigManager (E2E 테스트용)
contract SimpleSeigManagerV3 {
    uint256 constant RAY = 1e27;
    uint256 constant WEI_UNIT = 1e18;

    // 기본 스토리지
    address public ton;
    address public wton;
    address public registry;
    address public depositManager;
    address public layer2Manager;
    address public dao;
    address public validatorReward;

    // V3 파라미터
    uint256 public daoDistributionRatio;      // d
    uint256 public minStakingRatio;           // θ
    uint256 public validatorDistributionRatio; // α
    uint256 public halfSaturationPoint;       // k
    uint256 public stakedSeigFactor;          // λ
    uint256 public relativeSeigRate;          // r

    // 분배 상태
    uint256 public seigPerBlock;
    uint256 public lastSeigBlock;
    bool public v3Migrated;

    // Bridged TON 추적
    struct BridgedTONInfo {
        uint256 currentBridgedTON;
        uint256 effectiveBridgedTON;
        uint256 initialDebt;
        bool isEligible;
    }
    mapping(address => BridgedTONInfo) public bridgedTONInfo;
    uint256 public totalEffectiveBridgedTON;
    uint256 public bridgedTONRewardPerUint;

    // Coinage 매핑
    mapping(address => address) public coinages;
    address public tot;

    // L2 일시정지
    mapping(address => bool) public pausedL2;

    // 분배 결과 추적
    uint256 public lastTotalSeig;
    uint256 public lastStakerSeig;
    uint256 public lastDaoSeig;
    uint256 public lastValidatorSeig;
    uint256 public lastSequencerSeig;

    // Events
    event SeigniorageDistributed(
        uint256 totalSeig,
        uint256 stakerSeig,
        uint256 daoSeig,
        uint256 validatorSeig,
        uint256 sequencerSeig
    );

    event L2SeigniorageDistributed(
        address indexed layer2,
        uint256 amount
    );

    constructor(
        address _ton,
        address _wton,
        address _registry,
        address _depositManager,
        address _layer2Manager,
        address _dao,
        address _tot
    ) {
        ton = _ton;
        wton = _wton;
        registry = _registry;
        depositManager = _depositManager;
        layer2Manager = _layer2Manager;
        dao = _dao;
        tot = _tot;

        // 기본값 설정
        seigPerBlock = 3.92e18; // 약 3.92 TON per block
        lastSeigBlock = block.number;
    }

    // ==========================================
    // 설정 함수
    // ==========================================

    function setV3Parameters(
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

    function setValidatorReward(address _validatorReward) external {
        validatorReward = _validatorReward;
    }

    function setCoinage(address layer2, address coinage) external {
        coinages[layer2] = coinage;
    }

    function migrateToV3() external {
        v3Migrated = true;
    }

    function registerL2(address layer2, uint256 bridgedTON, uint256 stakedAmount) external {
        bridgedTONInfo[layer2] = BridgedTONInfo({
            currentBridgedTON: bridgedTON,
            effectiveBridgedTON: 0,
            initialDebt: 0,
            isEligible: false
        });

        // 자격 확인
        uint256 required = rmul(bridgedTON, minStakingRatio);
        if (stakedAmount >= required) {
            bridgedTONInfo[layer2].isEligible = true;
            bridgedTONInfo[layer2].effectiveBridgedTON = bridgedTON;
            totalEffectiveBridgedTON += bridgedTON;
        }
    }

    function pauseL2(address layer2) external {
        if (bridgedTONInfo[layer2].isEligible) {
            totalEffectiveBridgedTON -= bridgedTONInfo[layer2].effectiveBridgedTON;
            bridgedTONInfo[layer2].effectiveBridgedTON = 0;
            bridgedTONInfo[layer2].isEligible = false;
        }
        pausedL2[layer2] = true;
    }

    function unpauseL2(address layer2) external {
        pausedL2[layer2] = false;
        // 자격 재확인 필요
    }

    // ==========================================
    // 핵심: updateSeigniorage (누구나 호출 가능)
    // ==========================================

    function updateSeigniorage() external returns (bool) {
        if (block.number <= lastSeigBlock) return true;

        uint256 span = block.number - lastSeigBlock;

        // A = 전체 기간 시뇨리지
        uint256 A = span * seigPerBlock;

        // TON/WTON 총 공급량
        uint256 T = SeigniorageFormulaMockTON(ton).totalSupply();
        uint256 S = MockWTON(wton).totalSupply();

        if (T == 0) T = 1e27; // 0 나눗셈 방지

        // ========================================
        // Step 1: 스테이커 지분 시뇨리지 (λ 적용)
        // S_staked = λ · A · (S / T)
        // V3: λ=0 설정 가능 (스테이커 시뇨리지 제거)
        // V2 호환: λ 미설정 시 기본값 사용 안 함 (명시적 설정 필요)
        // ========================================
        uint256 S_staked = rmul(rmul(A, stakedSeigFactor), rdiv(S, T));

        // A₁ = A - S_staked
        uint256 A1 = A > S_staked ? A - S_staked : 0;

        // ========================================
        // Step 2: 스테이커 추가 시뇨리지 (r 적용)
        // S_relative = A₁ · r
        // ========================================
        uint256 S_relative = rmul(A1, relativeSeigRate);

        // A₂ = A₁ - S_relative (V3 분배 재원)
        uint256 A2 = A1 > S_relative ? A1 - S_relative : 0;

        // 스테이커 총 시뇨리지
        uint256 totalStakerSeig = S_staked + S_relative;

        // Tot factor 업데이트 (스테이커 분배)
        if (totalStakerSeig > 0) {
            MockWTON(wton).mint(depositManager, totalStakerSeig);
        }

        // ========================================
        // Step 3: V3 분배 (백서 공식 적용)
        // ========================================
        uint256 daoSeig = 0;
        uint256 validatorSeig = 0;
        uint256 sequencerSeig = 0;

        if (v3Migrated && A2 > 0) {
            (daoSeig, validatorSeig, sequencerSeig) = _distributeV3(A2);
        } else if (!v3Migrated && A2 > 0) {
            // V3 미마이그레이션: A₂ 전체 DAO로
            daoSeig = A2;
            if (dao != address(0)) {
                MockWTON(wton).mint(dao, daoSeig);
            }
        }

        lastSeigBlock = block.number;

        // 결과 저장
        lastTotalSeig = A;
        lastStakerSeig = totalStakerSeig;
        lastDaoSeig = daoSeig;
        lastValidatorSeig = validatorSeig;
        lastSequencerSeig = sequencerSeig;

        emit SeigniorageDistributed(A, totalStakerSeig, daoSeig, validatorSeig, sequencerSeig);

        return true;
    }

    /// @notice V3 분배 로직 (백서 공식 적용)
    function _distributeV3(uint256 A2) internal returns (
        uint256 daoSeig,
        uint256 validatorSeig,
        uint256 sequencerSeig
    ) {
        // ========================================
        // DAO 고정 분배 (백서 공식 7)
        // S_DAO = d · A₂
        // ========================================
        uint256 S_DAO = rmul(A2, daoDistributionRatio);

        // ========================================
        // L2 분배 가능량
        // L = (1 - d) · A₂
        // ========================================
        uint256 L = A2 - S_DAO;

        // ========================================
        // 쌍곡선 포화 함수 (백서 공식 11)
        // y(x) = L · (x / (k + x))
        // ========================================
        uint256 x = totalEffectiveBridgedTON;
        uint256 y = 0;

        if (x > 0 && halfSaturationPoint > 0) {
            y = rdiv(rmul(L, x), halfSaturationPoint + x);
        }

        // 검증자: α · y(x)
        validatorSeig = rmul(y, validatorDistributionRatio);

        // 시퀀서: (1 - α) · y(x)
        sequencerSeig = y - validatorSeig;

        // 미분배분 DAO 귀속: L - y(x)
        uint256 undistributed = L - y;

        // 총 DAO = S_DAO + 미분배분
        daoSeig = S_DAO + undistributed;

        // 분배 실행
        if (daoSeig > 0 && dao != address(0)) {
            MockWTON(wton).mint(dao, daoSeig);
        }
        if (validatorSeig > 0 && validatorReward != address(0)) {
            MockWTON(wton).mint(validatorReward, validatorSeig);
        }
        if (sequencerSeig > 0 && layer2Manager != address(0)) {
            MockWTON(wton).mint(layer2Manager, sequencerSeig);

            // 개별 L2별 분배 (bridgedTONRewardPerUint 누적)
            if (x > 0) {
                bridgedTONRewardPerUint += (sequencerSeig * WEI_UNIT) / x;
            }
        }
    }

    // ==========================================
    // 개별 L2 시뇨리지 정산
    // ==========================================

    function settleL2Seigniorage(address layer2) external returns (uint256 amount) {
        BridgedTONInfo storage info = bridgedTONInfo[layer2];

        if (!info.isEligible || info.effectiveBridgedTON == 0) return 0;
        if (pausedL2[layer2]) return 0;

        amount = (bridgedTONRewardPerUint * info.effectiveBridgedTON) / WEI_UNIT - info.initialDebt;

        if (amount > 0) {
            info.initialDebt = (bridgedTONRewardPerUint * info.effectiveBridgedTON) / WEI_UNIT;
            emit L2SeigniorageDistributed(layer2, amount);
        }
    }

    function getL2PendingSeigniorage(address layer2) external view returns (uint256) {
        BridgedTONInfo memory info = bridgedTONInfo[layer2];
        if (!info.isEligible || info.effectiveBridgedTON == 0) return 0;
        if (pausedL2[layer2]) return 0;

        return (bridgedTONRewardPerUint * info.effectiveBridgedTON) / WEI_UNIT - info.initialDebt;
    }

    // ==========================================
    // RAY 연산
    // ==========================================

    function rmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * y) / RAY;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * RAY) / y;
    }
}

/// @title SeigniorageFormulaValidation
/// @notice 전체 시뇨리지 분배 사이클 테스트
contract SeigniorageFormulaValidation is Test {
    SimpleSeigManagerV3 public seigManager;
    SeigniorageFormulaMockTON public ton;
    MockWTON public wton;
    MockRegistry public registry;
    MockDepositManager public depositManager;
    MockLayer2Manager public layer2Manager;
    MockTot public tot;

    address public dao = address(0x4001);
    address public validatorReward = address(0x4002);
    address public layer2_1 = address(0x5001);
    address public layer2_2 = address(0x5002);
    address public layer2_3 = address(0x5003);
    address public anyUser = address(0x9999);

    uint256 constant RAY = 1e27;

    function setUp() public {
        // Mock 컨트랙트 배포
        ton = new SeigniorageFormulaMockTON(50_000_000e27); // 5천만 TON (RAY 단위)
        wton = new MockWTON();
        registry = new MockRegistry();
        depositManager = new MockDepositManager();
        layer2Manager = new MockLayer2Manager();
        tot = new MockTot();

        // SeigManager 배포
        seigManager = new SimpleSeigManagerV3(
            address(ton),
            address(wton),
            address(registry),
            address(depositManager),
            address(layer2Manager),
            dao,
            address(tot)
        );

        // V3 파라미터 설정
        seigManager.setV3Parameters(
            0.1e27,  // d = 10% (DAO)
            0.1e27,  // θ = 10% (최소 스테이킹)
            0.2e27,  // α = 20% (검증자)
            1000e27, // k = 1000
            RAY,     // λ = 1 (V2 모드)
            0.4e27   // r = 40%
        );

        seigManager.setValidatorReward(validatorReward);

        // 초기 WTON 공급
        wton.mint(address(depositManager), 10_000_000e27);
    }

    // ==========================================
    // 1. 기본 분배 테스트
    // ==========================================

    /// @notice SD-003: 누구나 updateSeigniorage 호출 가능
    function test_SD003_anyoneCanCallUpdateSeigniorage() public {
        seigManager.migrateToV3();
        seigManager.registerL2(layer2_1, 500e27, 100e27);

        // 블록 진행
        vm.roll(block.number + 100);

        // 임의의 사용자가 호출
        vm.prank(anyUser);
        bool success = seigManager.updateSeigniorage();

        assertTrue(success, "Anyone should be able to call updateSeigniorage");
        assertTrue(seigManager.lastTotalSeig() > 0, "Seigniorage should be distributed");
    }

    /// @notice SD-004: V2 모드 (λ=1, r=0.4) 분배 테스트
    function test_SD004_v2ModeDistribution() public {
        // V3 마이그레이션 안 함 (V2 모드)
        seigManager.setV3Parameters(
            0.1e27,  // d = 10%
            0.1e27,  // θ = 10%
            0.2e27,  // α = 20%
            1000e27, // k = 1000
            RAY,     // λ = 1
            0.4e27   // r = 40%
        );

        vm.roll(block.number + 100);

        seigManager.updateSeigniorage();

        // totalSeig = seigManager.lastTotalSeig();
        uint256 stakerSeig = seigManager.lastStakerSeig();
        uint256 daoSeig = seigManager.lastDaoSeig();

        // λ=1: S_staked = A * (S/T) 비례
        // 스테이커가 대부분 받음
        assertTrue(stakerSeig > 0, "Stakers should receive seigniorage");

        // V3 미마이그레이션: A₂가 DAO로
        assertTrue(daoSeig > 0, "DAO should receive remaining");
    }

    /// @notice SD-005: V3 완전 모드 (λ=0, r=0) 분배 테스트
    function test_SD005_v3FullModeDistribution() public {
        seigManager.setV3Parameters(
            0.1e27,  // d = 10%
            0.1e27,  // θ = 10%
            0.2e27,  // α = 20%
            500e27,  // k = 500
            0,       // λ = 0 (V3 완전 모드)
            0        // r = 0
        );

        seigManager.migrateToV3();
        seigManager.registerL2(layer2_1, 500e27, 100e27); // 자격 충족

        vm.roll(block.number + 100);

        uint256 daoBefore = wton.balanceOf(dao);
        uint256 validatorBefore = wton.balanceOf(validatorReward);
        uint256 l2ManagerBefore = wton.balanceOf(address(layer2Manager));

        seigManager.updateSeigniorage();

        uint256 stakerSeig = seigManager.lastStakerSeig();
        uint256 daoSeig = seigManager.lastDaoSeig();
        uint256 validatorSeig = seigManager.lastValidatorSeig();
        uint256 sequencerSeig = seigManager.lastSequencerSeig();

        // λ=0: 스테이커 시뇨리지 없음
        assertEq(stakerSeig, 0, "Staker seig should be 0 with lambda=0");

        // V3 분배 확인
        assertTrue(daoSeig > 0, "DAO should receive d*A2 + undistributed");
        assertTrue(validatorSeig > 0, "Validators should receive alpha*y");
        assertTrue(sequencerSeig > 0, "Sequencers should receive (1-alpha)*y");

        // 실제 전송 확인
        assertEq(wton.balanceOf(dao) - daoBefore, daoSeig, "DAO balance mismatch");
        assertEq(wton.balanceOf(validatorReward) - validatorBefore, validatorSeig, "Validator balance mismatch");
        assertEq(wton.balanceOf(address(layer2Manager)) - l2ManagerBefore, sequencerSeig, "L2Manager balance mismatch");
    }

    // ==========================================
    // 2. V2→V3 점진적 전환 테스트
    // ==========================================

    /// @notice SD-006: λ 감소에 따른 스테이커 시뇨리지 감소
    /// @dev λ=0일 때도 r > 0이면 S_relative가 남음
    ///      완전한 V3 모드(λ=0, r=0)에서만 staker seig = 0
    function test_SD006_transitionLambdaDecrease() public {
        seigManager.migrateToV3();
        seigManager.registerL2(layer2_1, 500e27, 100e27);

        uint256[] memory lambdaValues = new uint256[](5);
        lambdaValues[0] = RAY;       // 100%
        lambdaValues[1] = 0.75e27;   // 75%
        lambdaValues[2] = 0.5e27;    // 50%
        lambdaValues[3] = 0.25e27;   // 25%
        lambdaValues[4] = 0;         // 0%

        uint256 prevStakerSeig = type(uint256).max;

        for (uint256 i = 0; i < lambdaValues.length; i++) {
            seigManager.setV3Parameters(
                0.1e27,
                0.1e27,
                0.2e27,
                500e27,
                lambdaValues[i],
                0.4e27
            );

            vm.roll(block.number + 100);
            seigManager.updateSeigniorage();

            uint256 stakerSeig = seigManager.lastStakerSeig();

            // λ 감소 → 스테이커 시뇨리지 감소
            assertTrue(stakerSeig <= prevStakerSeig, "Staker seig should decrease as lambda decreases");
            prevStakerSeig = stakerSeig;
        }

        // λ=0, r=0.4일 때: S_staked=0, S_relative = A * r = 0.4 * A
        // 따라서 stakerSeig > 0 (S_relative 때문)
        // 완전한 V3 모드(λ=0, r=0)에서만 staker seig = 0
        assertTrue(prevStakerSeig > 0, "With r>0, staker seig includes S_relative even at lambda=0");
    }

    /// @notice SD-007: r 감소에 따른 V3 분배 재원 증가
    function test_SD007_transitionRDecrease() public {
        seigManager.migrateToV3();
        seigManager.registerL2(layer2_1, 500e27, 100e27);

        uint256 prevValidatorSeig = 0;

        uint256[] memory rValues = new uint256[](4);
        rValues[0] = 0.4e27;  // 40%
        rValues[1] = 0.2e27;  // 20%
        rValues[2] = 0.1e27;  // 10%
        rValues[3] = 0;       // 0%

        for (uint256 i = 0; i < rValues.length; i++) {
            seigManager.setV3Parameters(
                0.1e27,
                0.1e27,
                0.2e27,
                500e27,
                RAY,      // λ = 1 고정
                rValues[i]
            );

            vm.roll(block.number + 100);
            seigManager.updateSeigniorage();

            uint256 validatorSeig = seigManager.lastValidatorSeig();

            // r 감소 → A₂ 증가 → 검증자 시뇨리지 증가
            assertTrue(validatorSeig >= prevValidatorSeig, "Validator seig should increase as r decreases");
            prevValidatorSeig = validatorSeig;
        }
    }

    // ==========================================
    // 3. 다중 L2 분배 테스트
    // ==========================================

    /// @notice SD-008: 여러 L2가 Bridged TON 비례로 분배
    function test_SD008_multipleL2Distribution() public {
        seigManager.setV3Parameters(
            0.1e27,  // d = 10%
            0.1e27,  // θ = 10%
            0.2e27,  // α = 20%
            1000e27, // k = 1000
            0,       // λ = 0
            0        // r = 0
        );

        seigManager.migrateToV3();

        // 3개 L2 등록 (자격 모두 충족)
        seigManager.registerL2(layer2_1, 300e27, 50e27);  // 300 TON
        seigManager.registerL2(layer2_2, 500e27, 80e27);  // 500 TON
        seigManager.registerL2(layer2_3, 200e27, 30e27);  // 200 TON

        // 총 유효 Bridged TON = 1000
        assertEq(seigManager.totalEffectiveBridgedTON(), 1000e27);

        vm.roll(block.number + 100);
        seigManager.updateSeigniorage();

        // 각 L2의 대기 시뇨리지 확인
        uint256 pending1 = seigManager.getL2PendingSeigniorage(layer2_1);
        uint256 pending2 = seigManager.getL2PendingSeigniorage(layer2_2);
        uint256 pending3 = seigManager.getL2PendingSeigniorage(layer2_3);

        // 비례 분배 확인: 300:500:200 = 3:5:2
        // 약간의 오차 허용 (RAY 연산)
        uint256 total = pending1 + pending2 + pending3;

        if (total > 0) {
            // 비율 검증 (10% 오차 허용)
            assertApproxEqRel(pending1 * 10, total * 3, 0.1e18, "L2_1 should get ~30%");
            assertApproxEqRel(pending2 * 10, total * 5, 0.1e18, "L2_2 should get ~50%");
            assertApproxEqRel(pending3 * 10, total * 2, 0.1e18, "L2_3 should get ~20%");
        }
    }

    /// @notice 자격 미달 L2는 분배에서 제외
    function test_SD013_ineligibleL2Excluded() public {
        seigManager.setV3Parameters(
            0.1e27,
            0.1e27,  // θ = 10%
            0.2e27,
            500e27,
            0,
            0
        );

        seigManager.migrateToV3();

        // layer2_1: 자격 충족 (S=100 >= θ*B = 50)
        seigManager.registerL2(layer2_1, 500e27, 100e27);

        // layer2_2: 자격 미달 (S=30 < θ*B = 50)
        seigManager.registerL2(layer2_2, 500e27, 30e27);

        // layer2_1만 유효
        assertEq(seigManager.totalEffectiveBridgedTON(), 500e27);

        vm.roll(block.number + 100);
        seigManager.updateSeigniorage();

        uint256 pending1 = seigManager.getL2PendingSeigniorage(layer2_1);
        uint256 pending2 = seigManager.getL2PendingSeigniorage(layer2_2);

        assertTrue(pending1 > 0, "Eligible L2 should have pending seigniorage");
        assertEq(pending2, 0, "Ineligible L2 should have 0 pending seigniorage");
    }

    // ==========================================
    // 4. 슬래싱 후 분배 제외 테스트
    // ==========================================

    /// @notice 슬래싱된 L2는 분배에서 제외
    function test_SD014_slashedL2Excluded() public {
        seigManager.setV3Parameters(0.1e27, 0.1e27, 0.2e27, 500e27, 0, 0);
        seigManager.migrateToV3();

        seigManager.registerL2(layer2_1, 500e27, 100e27);
        seigManager.registerL2(layer2_2, 500e27, 100e27);

        // 초기: 둘 다 유효
        assertEq(seigManager.totalEffectiveBridgedTON(), 1000e27);

        // layer2_1 슬래싱 (일시정지)
        seigManager.pauseL2(layer2_1);

        // layer2_2만 유효
        assertEq(seigManager.totalEffectiveBridgedTON(), 500e27);

        vm.roll(block.number + 100);
        seigManager.updateSeigniorage();

        uint256 pending1 = seigManager.getL2PendingSeigniorage(layer2_1);
        uint256 pending2 = seigManager.getL2PendingSeigniorage(layer2_2);

        assertEq(pending1, 0, "Slashed L2 should have 0 pending");
        assertTrue(pending2 > 0, "Non-slashed L2 should have pending");
    }

    /// @notice 모든 L2 슬래싱 시 전액 DAO로
    function test_SD015_allL2Slashed_allToDAO() public {
        seigManager.setV3Parameters(0.1e27, 0.1e27, 0.2e27, 500e27, 0, 0);
        seigManager.migrateToV3();

        seigManager.registerL2(layer2_1, 500e27, 100e27);
        seigManager.pauseL2(layer2_1);

        // x = 0
        assertEq(seigManager.totalEffectiveBridgedTON(), 0);

        vm.roll(block.number + 100);

        uint256 daoBefore = wton.balanceOf(dao);
        seigManager.updateSeigniorage();
        uint256 daoAfter = wton.balanceOf(dao);

        // totalSeig = seigManager.lastTotalSeig();
        uint256 daoSeig = seigManager.lastDaoSeig();
        uint256 validatorSeig = seigManager.lastValidatorSeig();
        uint256 sequencerSeig = seigManager.lastSequencerSeig();

        // y(0) = 0 이므로 L = (1-d)*A2 전체가 미분배분으로 DAO 귀속
        assertEq(validatorSeig, 0, "No validator seig when x=0");
        assertEq(sequencerSeig, 0, "No sequencer seig when x=0");
        assertTrue(daoSeig > 0, "All goes to DAO");
        assertEq(daoAfter - daoBefore, daoSeig, "DAO received correct amount");
    }

    // ==========================================
    // 5. 연속 분배 테스트
    // ==========================================

    /// @notice SD-009: 여러 번 연속 updateSeigniorage 호출
    function test_SD009_consecutiveUpdates() public {
        seigManager.setV3Parameters(0.1e27, 0.1e27, 0.2e27, 500e27, 0, 0);
        seigManager.migrateToV3();
        seigManager.registerL2(layer2_1, 500e27, 100e27);

        uint256 totalDistributed = 0;

        for (uint256 i = 0; i < 5; i++) {
            vm.roll(block.number + 100);

            uint256 daoBefore = wton.balanceOf(dao);
            uint256 validatorBefore = wton.balanceOf(validatorReward);
            uint256 l2ManagerBefore = wton.balanceOf(address(layer2Manager));

            seigManager.updateSeigniorage();

            uint256 daoGain = wton.balanceOf(dao) - daoBefore;
            uint256 validatorGain = wton.balanceOf(validatorReward) - validatorBefore;
            uint256 l2ManagerGain = wton.balanceOf(address(layer2Manager)) - l2ManagerBefore;

            totalDistributed += daoGain + validatorGain + l2ManagerGain;
        }

        assertTrue(totalDistributed > 0, "Total distributed should be positive");
    }

    // ==========================================
    // 6. 쌍곡선 함수 동작 검증
    // ==========================================

    /// @notice x가 증가할수록 y는 L에 수렴
    function test_EDGE003_hyperbolicSaturationConvergence() public {
        seigManager.setV3Parameters(0.1e27, 0.1e27, 0.2e27, 500e27, 0, 0);
        seigManager.migrateToV3();

        uint256 prevY = 0;

        // x를 10배씩 증가
        uint256[] memory xValues = new uint256[](5);
        xValues[0] = 100e27;
        xValues[1] = 500e27;   // k와 동일
        xValues[2] = 1000e27;
        xValues[3] = 5000e27;
        xValues[4] = 10000e27;

        for (uint256 i = 0; i < xValues.length; i++) {
            // 이전 등록 제거 (새로 등록)
            seigManager.pauseL2(layer2_1);

            // 새 값으로 등록
            seigManager.registerL2(layer2_1, xValues[i], xValues[i] / 5); // 자격 충족

            vm.roll(block.number + 100);
            seigManager.updateSeigniorage();

            uint256 sequencerSeig = seigManager.lastSequencerSeig();

            // y는 단조 증가
            assertTrue(sequencerSeig >= prevY, "y should monotonically increase");
            prevY = sequencerSeig;
        }
    }

    /// @notice k=x일 때 y = L/2
    function test_EDGE002_halfSaturationPoint() public {
        uint256 k = 500e27;

        seigManager.setV3Parameters(
            0,       // d = 0 (DAO 없음, L = A2)
            0.1e27,
            0,       // α = 0 (검증자 없음, 전액 시퀀서)
            k,       // k = 500
            0,       // λ = 0
            0        // r = 0
        );

        seigManager.migrateToV3();

        // x = k = 500
        seigManager.registerL2(layer2_1, k, k / 5);

        vm.roll(block.number + 100);
        seigManager.updateSeigniorage();

        uint256 totalSeig = seigManager.lastTotalSeig();    // A = A2 (λ=0, r=0)
        uint256 sequencerSeig = seigManager.lastSequencerSeig(); // (1-α)*y = y (α=0)

        // x = k일 때 y = L * (k / 2k) = L/2
        // L = (1-d) * A2 = A2 (d=0)
        // 따라서 y = A2 / 2
        uint256 expectedY = totalSeig / 2;

        // 약간의 RAY 연산 오차 허용 (1%)
        assertApproxEqRel(sequencerSeig, expectedY, 0.01e18, "y should be L/2 at x=k");
    }
}
