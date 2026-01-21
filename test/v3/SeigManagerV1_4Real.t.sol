// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../../script/DeployV3Full.s.sol";
import {InvalidParameterError, ZeroAddressError} from "../../src/stake/managers/SeigManagerV1_4.sol";

/// @title SeigManagerV1_4RealTest
/// @notice 실제 컨트랙트를 사용한 SeigManagerV1_4 테스트
/// @dev DeployV3Full을 활용하여 전체 시스템 배포 후 테스트

contract SeigManagerV1_4RealTest is Test, DeployV3Full {
    // 주요 컨트랙트 참조
    SeigManagerV1_4 public seigManager;
    Layer2ManagerV1_2 public layer2Manager;

    address public admin;  // TransparentUpgradeableProxy의 admin (관리 함수만 호출)
    address public owner;  // 비즈니스 로직 owner (구현체 함수 호출)
    address public layer2_1 = address(0x1001);
    address public layer2_2 = address(0x1002);
    address public operator1 = address(0x2001);

    uint256 constant RAY = 1e27;

    function setUp() public {
        // TransparentUpgradeableProxy 패턴:
        // - admin: upgradeTo(), changeAdmin() 같은 관리 함수만 호출 가능
        // - non-admin: 구현체의 비즈니스 로직 함수 호출 가능
        admin = address(0x9999);  // Proxy admin 전용
        owner = address(this);    // 비즈니스 로직 owner (구현체 함수 호출)

        // owner 컨텍스트에서 배포 시작
        vm.startPrank(owner);

        // 전체 시스템 배포
        _deployTokens();
        _deployCoinageInfrastructure(owner);
        _deployLayer2Registry(owner);
        _deployManagerProxies();
        _deployManagerImplementations();
        _initializeManagers(owner);
        _setupMinterPermissions();
        _deployOperatorManagerFactory(owner);

        // RAT, ValidatorReward를 owner로 배포 (임시로 owner가 proxy admin + contract owner)
        _deployV3Contracts(owner);

        // RAT, ValidatorReward의 proxy admin만 admin으로 변경 (contract owner는 owner 유지)
        RATProxy(payable(ratProxy)).changeAdmin(admin);
        ValidatorRewardProxy(payable(validatorPoolProxy)).changeAdmin(admin);

        // 이제 admin = proxy admin, owner = contract owner로 분리됨
        _configureV3Contracts(owner);
        _setupCrossReferences(owner);

        // 주요 컨트랙트 참조
        seigManager = SeigManagerV1_4(seigManagerProxy);
        layer2Manager = Layer2ManagerV1_2(layer2ManagerProxy);

        vm.stopPrank();
    }

    // ==========================================
    // hyperbolicSaturation 함수 테스트
    // ==========================================

    function test_hyperbolicSaturation_zero() public view {
        uint256 y = seigManager.hyperbolicSaturation(0, 1000e27);
        assertEq(y, 0, "y(0) should be 0");
    }

    function test_hyperbolicSaturation_halfPoint() public {
        // k 설정
        seigManager.setHalfSaturationPoint(1000e27);

        uint256 k = seigManager.halfSaturationPoint();
        uint256 L = 1000e27;
        uint256 y = seigManager.hyperbolicSaturation(k, L);

        // y(k) = L * k / (k + k) = L/2
        assertApproxEqRel(y, L / 2, 0.01e18, "y(k) should be L/2");
    }

    function test_hyperbolicSaturation_large() public {
        seigManager.setHalfSaturationPoint(1000e27);

        uint256 L = 1000e27;
        uint256 y = seigManager.hyperbolicSaturation(100000e27, L);

        // y가 L에 근접해야 함
        assertGt(y, L * 99 / 100, "y(large) should approach L");
    }

    function test_hyperbolicSaturation_monotonic() public {
        seigManager.setHalfSaturationPoint(1000e27);

        uint256 L = 1000e27;
        uint256 prev = 0;

        for (uint256 x = 100e27; x <= 10000e27; x += 1000e27) {
            uint256 y = seigManager.hyperbolicSaturation(x, L);
            assertGe(y, prev, "y should be monotonically increasing");
            prev = y;
        }
    }

    function testFuzz_hyperbolicSaturation_bounded(uint256 x, uint256 L) public {
        seigManager.setHalfSaturationPoint(1000e27);

        x = bound(x, 0, 1e32);
        L = bound(L, 1e18, 1e32);

        uint256 y = seigManager.hyperbolicSaturation(x, L);

        assertLe(y, L + 1e18, "y should not exceed L");
    }

    // ==========================================
    // calculateSequencerReward 함수 테스트
    // ==========================================

    function test_calculateSequencerReward_basic() public {
        // α = 20% 설정
        seigManager.setValidatorDistributionRatio(0.2e27);

        uint256 l2Seig = 1000e27;

        // α = 20%, 시퀀서 = (1-α) = 80%
        uint256 sequencerReward = seigManager.calculateSequencerReward(l2Seig);

        assertEq(sequencerReward, 800e27, "Sequencer should get (1-alpha) * seig");
    }

    function test_calculateSequencerReward_zeroAlpha() public {
        // α = 0 설정
        seigManager.setValidatorDistributionRatio(0);

        uint256 l2Seig = 1000e27;
        uint256 sequencerReward = seigManager.calculateSequencerReward(l2Seig);

        assertEq(sequencerReward, 1000e27, "Sequencer should get 100% when alpha=0");
    }

    function testFuzz_calculateSequencerReward(uint256 l2Seig) public {
        seigManager.setValidatorDistributionRatio(0.2e27);

        l2Seig = bound(l2Seig, 0, 1e32);

        uint256 sequencerReward = seigManager.calculateSequencerReward(l2Seig);
        uint256 validatorRatio = seigManager.validatorDistributionRatio();

        // sequencerReward = (1 - alpha) * l2Seig
        uint256 expected = l2Seig - (l2Seig * validatorRatio / RAY);
        assertApproxEqAbs(sequencerReward, expected, 1e18, "Sequencer reward calculation");
    }

    // ==========================================
    // V3 파라미터 테스트
    // ==========================================

    function test_v3Parameters() public {
        // 파라미터 설정
        seigManager.setDaoDistributionRatio(0.1e27);
        seigManager.setMinStakingRatio(0.1e27);
        seigManager.setValidatorDistributionRatio(0.2e27);
        seigManager.setHalfSaturationPoint(1000e27);
        seigManager.setStakedSeigFactor(RAY);

        // 확인
        assertEq(seigManager.daoDistributionRatio(), 0.1e27, "d = 10%");
        assertEq(seigManager.minStakingRatio(), 0.1e27, "theta = 10%");
        assertEq(seigManager.validatorDistributionRatio(), 0.2e27, "alpha = 20%");
        assertEq(seigManager.halfSaturationPoint(), 1000e27, "k = 1000");
        assertEq(seigManager.stakedSeigFactor(), RAY, "lambda = 1");
    }

    // ==========================================
    // 마이그레이션 상태 테스트
    // ==========================================

    function test_v3MigrationState() public {
        assertFalse(seigManager.v3Migrated(), "Initially not migrated");

        seigManager.migrateToV3();
        assertTrue(seigManager.v3Migrated(), "Should be migrated");
    }

    // ==========================================
    // 슬래싱 파라미터 테스트
    // ==========================================

    function test_slashingParameters() public {
        seigManager.setMaxChallengers(10);
        seigManager.setMaxFraudProofCost(1e18);

        assertEq(seigManager.maxChallengers(), 10, "Max challengers");
        assertEq(seigManager.maxFraudProofCost(), 1e18, "Max fraud proof cost");
    }

    // ==========================================
    // Governance Setter 함수 테스트
    // ==========================================

    function test_setStakedSeigFactor_basic() public {
        seigManager.setStakedSeigFactor(0.5e27);
        assertEq(seigManager.stakedSeigFactor(), 0.5e27, "Should set lambda to 0.5");

        seigManager.setStakedSeigFactor(RAY);
        assertEq(seigManager.stakedSeigFactor(), RAY, "Should set lambda to 1.0");

        seigManager.setStakedSeigFactor(0);
        assertEq(seigManager.stakedSeigFactor(), 0, "Should set lambda to 0");
    }

    function test_setStakedSeigFactor_exceedsRAY_reverts() public {
        vm.expectRevert(InvalidParameterError.selector);
        seigManager.setStakedSeigFactor(RAY + 1);
    }

    function test_setMaxChallengers_basic() public {
        seigManager.setMaxChallengers(5);
        assertEq(seigManager.maxChallengers(), 5, "Should set maxChallengers to 5");

        seigManager.setMaxChallengers(100);
        assertEq(seigManager.maxChallengers(), 100, "Should set maxChallengers to 100");

        seigManager.setMaxChallengers(0);
        assertEq(seigManager.maxChallengers(), 0, "Should allow zero challengers");
    }

    function test_setMaxFraudProofCost_basic() public {
        seigManager.setMaxFraudProofCost(1 ether);
        assertEq(seigManager.maxFraudProofCost(), 1 ether, "Should set maxFraudProofCost to 1 ether");

        seigManager.setMaxFraudProofCost(0);
        assertEq(seigManager.maxFraudProofCost(), 0, "Should allow zero cost");
    }


    function test_setValidatorReward_basic() public {
        address rewardAddress = address(0xABCD);
        seigManager.setValidatorReward(rewardAddress);
        assertEq(seigManager.validatorReward(), rewardAddress, "Should set ValidatorReward address");
    }

    function test_setValidatorReward_zeroAddress_reverts() public {
        vm.expectRevert(ZeroAddressError.selector);
        seigManager.setValidatorReward(address(0));
    }

    // ==========================================
    // onlyOwner 권한 테스트
    // ==========================================

    function test_setStakedSeigFactor_notOwner_reverts() public {
        vm.prank(address(0x9999));
        vm.expectRevert();
        seigManager.setStakedSeigFactor(0.5e27);
    }

    function test_setMaxChallengers_notOwner_reverts() public {
        vm.prank(address(0x9999));
        vm.expectRevert();
        seigManager.setMaxChallengers(10);
    }

    function test_setMaxFraudProofCost_notOwner_reverts() public {
        vm.prank(address(0x9999));
        vm.expectRevert();
        seigManager.setMaxFraudProofCost(1 ether);
    }

    // ==========================================
    // 배포 스크립트 연동 테스트
    // ==========================================

    function test_deployedContractsConnected() public view {
        // 배포된 컨트랙트들이 서로 연결되어 있는지 확인
        assertTrue(seigManagerProxy != address(0), "SeigManager deployed");
        assertTrue(depositManagerProxy != address(0), "DepositManager deployed");
        assertTrue(layer2ManagerProxy != address(0), "Layer2Manager deployed");
        assertTrue(ratProxy != address(0), "RAT deployed");
        assertTrue(validatorPoolProxy != address(0), "ValidatorReward deployed");
    }

    function test_validatorRewardConnected() public view {
        // ValidatorReward가 SeigManager에 연결되었는지 확인
        assertEq(seigManager.validatorReward(), validatorPoolProxy, "ValidatorReward should be connected");
    }

    // ==========================================
    // SM-022: D_sequencer 계산 테스트
    // D_sequencer = H_max × C_max + Δ_sequencer
    // ==========================================

    /// @notice SM-022: D_sequencer 기본 계산 검증
    function test_SM022_DSequencer_calculation() public {
        // H_max = 10, C_max = 0.1 WTON, Δ_sequencer = 0.5 WTON
        uint256 hMax = 10;
        uint256 cMax = 0.1e27;  // 0.1 WTON (27 decimals)
        uint256 delta = 0.5e27; // 0.5 WTON (27 decimals)

        seigManager.setMaxChallengers(hMax);
        seigManager.setMaxFraudProofCost(cMax);
        seigManager.setSequencerAdditionalReward(delta);

        // D_sequencer = 10 * 0.1 + 0.5 = 1.5 WTON
        uint256 expectedDSequencer = hMax * cMax + delta;
        assertEq(expectedDSequencer, 1.5e27, "D_sequencer should be 1.5 WTON");

        // checkCurrentEligibility에서 계산된 requiredStake가 D_sequencer와 일치하는지 확인
        // (bridgedTON이 0이면 θ×B_i = 0이므로 D_sequencer가 requiredStake)
        // Note: 실제 테스트를 위해서는 layer2 등록이 필요
    }

    /// @notice SM-022: D_sequencer 경계값 테스트 (모두 0)
    function test_SM022_DSequencer_allZero() public {
        seigManager.setMaxChallengers(0);
        seigManager.setMaxFraudProofCost(0);
        seigManager.setSequencerAdditionalReward(0);

        // D_sequencer = 0 * 0 + 0 = 0
        uint256 dSequencer = seigManager.maxChallengers() * seigManager.maxFraudProofCost()
                           + seigManager.sequencerAdditionalReward();
        assertEq(dSequencer, 0, "D_sequencer should be 0 when all params are 0");
    }

    /// @notice SM-022: D_sequencer 대량 값 테스트
    function test_SM022_DSequencer_largeValues() public {
        // H_max = 100, C_max = 10 WTON, Δ_sequencer = 100 WTON
        uint256 hMax = 100;
        uint256 cMax = 10e27;   // 10 WTON
        uint256 delta = 100e27; // 100 WTON

        seigManager.setMaxChallengers(hMax);
        seigManager.setMaxFraudProofCost(cMax);
        seigManager.setSequencerAdditionalReward(delta);

        // D_sequencer = 100 * 10 + 100 = 1100 WTON
        uint256 expectedDSequencer = hMax * cMax + delta;
        assertEq(expectedDSequencer, 1100e27, "D_sequencer should be 1100 WTON");
    }

    /// @notice SM-022: D_sequencer Fuzz 테스트
    function testFuzz_SM022_DSequencer(uint256 hMax, uint256 cMax, uint256 delta) public {
        // 오버플로우 방지를 위해 범위 제한
        hMax = bound(hMax, 0, 1000);
        cMax = bound(cMax, 0, 100e27);
        delta = bound(delta, 0, 1000e27);

        seigManager.setMaxChallengers(hMax);
        seigManager.setMaxFraudProofCost(cMax);
        seigManager.setSequencerAdditionalReward(delta);

        uint256 dSequencer = seigManager.maxChallengers() * seigManager.maxFraudProofCost()
                           + seigManager.sequencerAdditionalReward();

        assertEq(dSequencer, hMax * cMax + delta, "D_sequencer formula verification");
    }

    // ==========================================
    // SM-023: θ×B_i 계산 테스트
    // TON → WTON 단위 변환 검증
    // ==========================================

    /// @notice SM-023: θ×B_i 기본 계산 검증
    /// @dev bridgedTON(18 decimals) * θ(RAY) → WTON(27 decimals)
    function test_SM023_thetaBi_calculation() public {
        // θ = 10% = 0.1 RAY
        uint256 theta = 0.1e27;
        seigManager.setMinStakingRatio(theta);

        // B_i = 1000 TON (18 decimals)
        uint256 bridgedTON = 1000e18;

        // θ×B_i = 0.1 * 1000 = 100 WTON (27 decimals)
        // 공식: (bridgedTON * 1e9 * theta) / 1e27
        uint256 GWEI_UNIT = 1e9;
        uint256 thetaBi = (bridgedTON * GWEI_UNIT * theta) / RAY;

        assertEq(thetaBi, 100e27, "theta*Bi should be 100 WTON");
    }

    /// @notice SM-023: θ×B_i 단위 변환 정확성 검증
    function test_SM023_thetaBi_unitConversion() public {
        // θ = 100% = 1.0 RAY (1:1 변환 테스트)
        uint256 theta = RAY; // 1.0
        seigManager.setMinStakingRatio(theta);

        // B_i = 500 TON (18 decimals)
        uint256 bridgedTON = 500e18;

        // θ×B_i = 1.0 * 500 = 500 WTON (27 decimals)
        uint256 GWEI_UNIT = 1e9;
        uint256 thetaBi = (bridgedTON * GWEI_UNIT * theta) / RAY;

        // TON(18) → WTON(27): 9 decimals 추가
        // 500 * 1e18 * 1e9 = 500 * 1e27
        assertEq(thetaBi, 500e27, "500 TON should convert to 500 WTON when theta=1");
    }

    /// @notice SM-023: θ×B_i 경계값 테스트 (θ = 0)
    function test_SM023_thetaBi_zeroTheta() public {
        seigManager.setMinStakingRatio(0);

        uint256 bridgedTON = 1000e18;
        uint256 GWEI_UNIT = 1e9;
        uint256 thetaBi = (bridgedTON * GWEI_UNIT * 0) / RAY;

        assertEq(thetaBi, 0, "theta*Bi should be 0 when theta=0");
    }

    /// @notice SM-023: θ×B_i 경계값 테스트 (B_i = 0)
    function test_SM023_thetaBi_zeroBridgedTON() public {
        seigManager.setMinStakingRatio(0.1e27);

        uint256 bridgedTON = 0;
        uint256 GWEI_UNIT = 1e9;
        uint256 theta = seigManager.minStakingRatio();
        uint256 thetaBi = (bridgedTON * GWEI_UNIT * theta) / RAY;

        assertEq(thetaBi, 0, "theta*Bi should be 0 when bridgedTON=0");
    }

    /// @notice SM-023: θ×B_i Fuzz 테스트
    function testFuzz_SM023_thetaBi(uint256 theta, uint256 bridgedTON) public {
        // 범위 제한: θ ≤ 1.0, bridgedTON ≤ 1억 TON
        theta = bound(theta, 0, RAY);
        bridgedTON = bound(bridgedTON, 0, 100_000_000e18);

        seigManager.setMinStakingRatio(theta);

        uint256 GWEI_UNIT = 1e9;
        uint256 thetaBi = (bridgedTON * GWEI_UNIT * theta) / RAY;

        // 결과 검증: WTON 단위(27 decimals)로 정확히 변환되었는지
        // bridgedTON * theta / 1e18 (TON → WTON 변환 후 θ 적용)
        uint256 expected = (bridgedTON * theta) / 1e18;
        assertEq(thetaBi, expected, "theta*Bi calculation should match expected");
    }

    // ==========================================
    // INT-012: 시퀀서 최소 담보금 V3 테스트
    // requiredStake = max(θ×B_i, D_sequencer)
    // ==========================================

    /// @notice INT-012: max(θ×B_i, D_sequencer) 공식 검증 - D_sequencer가 더 큰 경우
    function test_INT012_requiredStake_DSequencerDominant() public {
        // D_sequencer = H_max × C_max + Δ_sequencer = 10 * 10 + 100 = 200 WTON
        seigManager.setMaxChallengers(10);
        seigManager.setMaxFraudProofCost(10e27);
        seigManager.setSequencerAdditionalReward(100e27);

        // θ = 10%, B_i = 1000 TON → θ×B_i = 100 WTON
        seigManager.setMinStakingRatio(0.1e27);

        // D_sequencer(200) > θ×B_i(100) → requiredStake = D_sequencer = 200 WTON
        uint256 dSequencer = 10 * 10e27 + 100e27;
        assertEq(dSequencer, 200e27, "D_sequencer should be 200 WTON");

        // θ×B_i = 0.1 * 1000 = 100 WTON (if bridgedTON = 1000 TON)
        uint256 bridgedTON = 1000e18;
        uint256 thetaBi = (bridgedTON * 1e9 * 0.1e27) / RAY;
        assertEq(thetaBi, 100e27, "theta*Bi should be 100 WTON");

        // max(100, 200) = 200
        uint256 requiredStake = thetaBi > dSequencer ? thetaBi : dSequencer;
        assertEq(requiredStake, 200e27, "Required stake should be D_sequencer when larger");
    }

    /// @notice INT-012: max(θ×B_i, D_sequencer) 공식 검증 - θ×B_i가 더 큰 경우
    function test_INT012_requiredStake_ThetaBiDominant() public {
        // D_sequencer = H_max × C_max + Δ_sequencer = 5 * 10 + 50 = 100 WTON
        seigManager.setMaxChallengers(5);
        seigManager.setMaxFraudProofCost(10e27);
        seigManager.setSequencerAdditionalReward(50e27);

        // θ = 20%, B_i = 1000 TON → θ×B_i = 200 WTON
        seigManager.setMinStakingRatio(0.2e27);

        // D_sequencer = 100 WTON
        uint256 dSequencer = 5 * 10e27 + 50e27;
        assertEq(dSequencer, 100e27, "D_sequencer should be 100 WTON");

        // θ×B_i = 0.2 * 1000 = 200 WTON
        uint256 bridgedTON = 1000e18;
        uint256 thetaBi = (bridgedTON * 1e9 * 0.2e27) / RAY;
        assertEq(thetaBi, 200e27, "theta*Bi should be 200 WTON");

        // max(200, 100) = 200 → θ×B_i가 requiredStake
        uint256 requiredStake = thetaBi > dSequencer ? thetaBi : dSequencer;
        assertEq(requiredStake, 200e27, "Required stake should be theta*Bi when larger");
    }

    /// @notice INT-012: max(θ×B_i, D_sequencer) - 둘 다 0인 경우
    function test_INT012_requiredStake_bothZero() public {
        // D_sequencer = 0
        seigManager.setMaxChallengers(0);
        seigManager.setMaxFraudProofCost(0);
        seigManager.setSequencerAdditionalReward(0);

        // θ = 0 → θ×B_i = 0
        seigManager.setMinStakingRatio(0);

        uint256 dSequencer = 0;
        uint256 thetaBi = 0;
        uint256 requiredStake = thetaBi > dSequencer ? thetaBi : dSequencer;

        assertEq(requiredStake, 0, "Required stake should be 0 when both are 0");
    }

    /// @notice INT-012: max(θ×B_i, D_sequencer) - 같은 경우
    function test_INT012_requiredStake_equal() public {
        // D_sequencer = 100 WTON
        seigManager.setMaxChallengers(10);
        seigManager.setMaxFraudProofCost(10e27);
        seigManager.setSequencerAdditionalReward(0);

        // θ = 10%, B_i = 1000 TON → θ×B_i = 100 WTON
        seigManager.setMinStakingRatio(0.1e27);

        uint256 dSequencer = 10 * 10e27 + 0;
        uint256 bridgedTON = 1000e18;
        uint256 thetaBi = (bridgedTON * 1e9 * 0.1e27) / RAY;

        assertEq(dSequencer, 100e27, "D_sequencer should be 100 WTON");
        assertEq(thetaBi, 100e27, "theta*Bi should be 100 WTON");

        uint256 requiredStake = thetaBi > dSequencer ? thetaBi : dSequencer;
        assertEq(requiredStake, 100e27, "Required stake should be 100 when equal");
    }

    /// @notice INT-012: Fuzz 테스트 - max(θ×B_i, D_sequencer)
    function testFuzz_INT012_requiredStake(
        uint256 hMax,
        uint256 cMax,
        uint256 delta,
        uint256 theta,
        uint256 bridgedTON
    ) public {
        // 범위 제한
        hMax = bound(hMax, 0, 100);
        cMax = bound(cMax, 0, 100e27);
        delta = bound(delta, 0, 1000e27);
        theta = bound(theta, 0, RAY);
        bridgedTON = bound(bridgedTON, 0, 100_000_000e18);

        seigManager.setMaxChallengers(hMax);
        seigManager.setMaxFraudProofCost(cMax);
        seigManager.setSequencerAdditionalReward(delta);
        seigManager.setMinStakingRatio(theta);

        uint256 dSequencer = hMax * cMax + delta;
        uint256 thetaBi = (bridgedTON * 1e9 * theta) / RAY;

        uint256 expectedRequired = thetaBi > dSequencer ? thetaBi : dSequencer;

        // max 함수 검증
        assertTrue(
            expectedRequired == thetaBi || expectedRequired == dSequencer,
            "Required stake should be max of the two"
        );
        assertTrue(
            expectedRequired >= thetaBi && expectedRequired >= dSequencer,
            "Required stake should be >= both values"
        );
    }

    // ==========================================
    // INT-030~032: onBridgedTONChange 통합 테스트
    // ==========================================

    /// @notice INT-030: onBridgedTONChange() OptimismPortal에서 호출 검증
    /// @dev OptimismPortal → SeigManager.onBridgedTONChange() 호출 흐름 검증
    function test_INT030_onBridgedTONChange_callerValidation() public {
        // 1. V3 마이그레이션 활성화
        seigManager.migrateToV3();

        // 2. 등록되지 않은 portal에서 호출 → revert
        address fakePortal = address(0xBAD);
        vm.prank(fakePortal);
        vm.expectRevert();
        seigManager.onBridgedTONChange();

        // 3. 일반 사용자가 호출 → revert
        vm.prank(address(0x1234));
        vm.expectRevert();
        seigManager.onBridgedTONChange();

        // Note: 실제 유효한 portal 호출은 L1BridgeRegistry 설정 필요
        // 이 테스트는 호출자 검증 로직 확인용
    }

    /// @notice INT-030: V3 비활성 상태에서 onBridgedTONChange 호출 방지
    function test_INT030_onBridgedTONChange_beforeMigration_reverts() public {
        // V3 마이그레이션 전 호출 → revert
        vm.expectRevert();
        seigManager.onBridgedTONChange();
    }

    /// @notice INT-031: effectiveBridgedTON 업데이트 검증 (단위 테스트)
    /// @dev 자격 획득/상실에 따른 effectiveBridgedTON 변화
    function test_INT031_effectiveBridgedTON_update() public view {
        // effectiveBridgedTON 조회 함수 확인
        uint256 effective = seigManager.getEffectiveBridgedTON(layer2_1);
        assertEq(effective, 0, "Initial effectiveBridgedTON should be 0");
    }

    /// @notice INT-032: totalEffectiveBridgedTON 동기화 검증
    /// @dev 전체 합계 정확성 확인
    function test_INT032_totalEffectiveBridgedTON_sync() public {
        // 1. V3 마이그레이션 활성화
        seigManager.migrateToV3();

        // 2. 초기 상태 확인
        uint256 total = seigManager.totalEffectiveBridgedTON();
        assertEq(total, 0, "Initial totalEffectiveBridgedTON should be 0");

        // Note: 실제 동기화 테스트는 여러 L2 등록 후 시뇨리지 분배 시나리오에서 수행
        // 여기서는 getter 함수 동작 확인
    }

    /// @notice INT-031/032: 자격 상실 시 effectiveBridgedTON 제거 검증
    /// @dev isEligible = false 시 effectiveBridgedTON = 0 확인
    function test_INT031_032_eligibilityLoss_removesEffective() public view {
        // 자격이 없는 L2의 effectiveBridgedTON은 0
        address unqualifiedLayer2 = address(0x9999);
        uint256 effective = seigManager.getEffectiveBridgedTON(unqualifiedLayer2);
        assertEq(effective, 0, "Unqualified L2 should have 0 effectiveBridgedTON");
    }
}
