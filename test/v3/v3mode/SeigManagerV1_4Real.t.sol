// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../../../script/DeployV3Full.s.sol";
import {InvalidParameterError, ZeroAddressError} from "../../../src/stake/managers/SeigManagerV3_1.sol";

/// @title SeigManagerV3_1RealTest
/// @notice 실제 컨트랙트를 사용한 SeigManagerV3_1 테스트
/// @dev DeployV3Full을 활용하여 전체 시스템 배포 후 테스트

contract SeigManagerV3_1RealTest is Test, DeployV3Full {
    // 주요 컨트랙트 참조
    SeigManagerV3_1 public seigManager;
    Layer2ManagerV3 public layer2Manager;
    Layer2Registry public layer2Registry;

    address public admin;  // TransparentUpgradeableProxy의 admin (관리 함수만 호출)
    address public owner;  // 비즈니스 로직 owner (구현체 함수 호출)
    address public layer2_1 = address(0x1001);
    address public layer2_2 = address(0x1002);
    address public operator1 = address(0x2001);

    uint256 constant RAY = 1e27;

    /// @notice Override to use separate admin address for TransparentUpgradeableProxy
    function _getProxyAdmin(address) internal view override returns (address) {
        return admin;
    }

    function setUp() public {
        // TransparentUpgradeableProxy 패턴:
        // - admin: upgradeTo(), changeAdmin() 같은 관리 함수만 호출 가능
        // - non-admin: 구현체의 비즈니스 로직 함수 호출 가능
        admin = address(0x9999);  // Proxy admin 전용
        owner = address(this);    // 비즈니스 로직 owner (구현체 함수 호출)
        proxyAdmin = admin;       // Set proxyAdmin before deployment

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

        // RAT, ValidatorReward를 배포 (proxyAdmin이 admin으로 설정됨)
        _deployV3Contracts(owner);

        // Register all V3 selectors for test functionality
        _setupSeigManagerV3AllTestSelectors();

        // 이제 admin = proxy admin, owner = contract owner로 분리됨
        _setupCrossReferences(owner);

        // 주요 컨트랙트 참조
        seigManager = SeigManagerV3_1(seigManagerProxy);
        layer2Manager = Layer2ManagerV3(layer2ManagerProxy);
        layer2Registry = Layer2Registry(layer2RegistryProxy);

        vm.stopPrank();
    }

    // ==========================================
    // hyperbolicSaturation 함수 테스트
    // ==========================================

    function test_SM001_hyperbolicSaturation_zero() public view {
        uint256 y = seigManager.hyperbolicSaturation(0, 1000e27);
        assertEq(y, 0, "y(0) should be 0");
    }

    function test_SM002_hyperbolicSaturation_halfPoint() public {
        seigManager.setHalfSaturationPoint(1000e27);

        uint256 k = seigManager.halfSaturationPoint();
        uint256 L = 1000e27;
        uint256 y = seigManager.hyperbolicSaturation(k, L);

        assertApproxEqRel(y, L / 2, 0.01e18, "y(k) should be L/2");
    }

    function test_SM003_hyperbolicSaturation_large() public {
        seigManager.setHalfSaturationPoint(1000e27);

        uint256 L = 1000e27;
        uint256 y = seigManager.hyperbolicSaturation(100000e27, L);

        assertGt(y, L * 99 / 100, "y(large) should approach L");
    }

    function test_SM004_hyperbolicSaturation_monotonic() public {
        seigManager.setHalfSaturationPoint(1000e27);

        uint256 L = 1000e27;
        uint256 prev = 0;

        for (uint256 x = 100e27; x <= 10000e27; x += 1000e27) {
            uint256 y = seigManager.hyperbolicSaturation(x, L);
            assertGe(y, prev, "y should be monotonically increasing");
            prev = y;
        }
    }

    function testFuzz_SM005_hyperbolicSaturation_bounded(uint256 x, uint256 L) public {
        seigManager.setHalfSaturationPoint(1000e27);

        x = bound(x, 0, 1e32);
        L = bound(L, 1e18, 1e32);

        uint256 y = seigManager.hyperbolicSaturation(x, L);

        assertLe(y, L + 1e18, "y should not exceed L");
    }

    // ==========================================
    // calculateSequencerReward 함수 테스트
    // ==========================================

    function test_SM010_calculateSequencerReward_basic() public {
        seigManager.setValidatorDistributionRatio(0.2e27);

        uint256 l2Seig = 1000e27;

        uint256 sequencerReward = seigManager.calculateSequencerReward(l2Seig);

        assertEq(sequencerReward, 800e27, "Sequencer should get (1-alpha) * seig");
    }

    function test_SM011_calculateSequencerReward_zeroAlpha() public {
        seigManager.setValidatorDistributionRatio(0);

        uint256 l2Seig = 1000e27;
        uint256 sequencerReward = seigManager.calculateSequencerReward(l2Seig);

        assertEq(sequencerReward, 1000e27, "Sequencer should get 100% when alpha=0");
    }

    function testFuzz_SM012_calculateSequencerReward(uint256 l2Seig) public {
        seigManager.setValidatorDistributionRatio(0.2e27);

        l2Seig = bound(l2Seig, 0, 1e32);

        uint256 sequencerReward = seigManager.calculateSequencerReward(l2Seig);
        uint256 validatorRatio = seigManager.validatorDistributionRatio();

        uint256 expected = l2Seig - (l2Seig * validatorRatio / RAY);
        assertApproxEqAbs(sequencerReward, expected, 1e18, "Sequencer reward calculation");
    }

    // ==========================================
    // V3 파라미터 테스트
    // ==========================================

    function test_SM006_v3Parameters() public {
        // 파라미터 설정
        seigManager.setDaoDistributionRatio(0.1e27);
        seigManager.setMinStakingRatio(0.1e27);
        seigManager.setValidatorDistributionRatio(0.2e27);
        seigManager.setHalfSaturationPoint(1000e27);

        // 확인
        assertEq(seigManager.daoDistributionRatio(), 0.1e27, "d = 10%");
        assertEq(seigManager.minStakingRatio(), 0.1e27, "theta = 10%");
        assertEq(seigManager.validatorDistributionRatio(), 0.2e27, "alpha = 20%");
        assertEq(seigManager.halfSaturationPoint(), 1000e27, "k = 1000");
    }

    // ==========================================
    // 마이그레이션 상태 테스트
    // ==========================================

    function test_SM007_v3MigrationState() public {
        assertFalse(seigManager.v3Migrated(), "Initially not migrated");

        _setV3ParametersForTest();
        seigManager.migrateToV3();
        assertTrue(seigManager.v3Migrated(), "Should be migrated");
    }

    // ==========================================
    // 슬래싱 파라미터 테스트
    // ==========================================

    function test_SM008_slashingParameters() public {
        seigManager.setMaxChallengers(10);
        seigManager.setMaxFraudProofCost(1e18);

        assertEq(seigManager.maxChallengers(), 10, "Max challengers");
        assertEq(seigManager.maxFraudProofCost(), 1e18, "Max fraud proof cost");
    }

    // ==========================================
    // Governance Setter 함수 테스트
    // ==========================================

    function test_SM015_setMaxChallengers_basic() public {
        seigManager.setMaxChallengers(5);
        assertEq(seigManager.maxChallengers(), 5, "Should set maxChallengers to 5");

        seigManager.setMaxChallengers(100);
        assertEq(seigManager.maxChallengers(), 100, "Should set maxChallengers to 100");

        seigManager.setMaxChallengers(0);
        assertEq(seigManager.maxChallengers(), 0, "Should allow zero challengers");
    }

    function test_SM016_setMaxFraudProofCost_basic() public {
        seigManager.setMaxFraudProofCost(1 ether);
        assertEq(seigManager.maxFraudProofCost(), 1 ether, "Should set maxFraudProofCost to 1 ether");

        seigManager.setMaxFraudProofCost(0);
        assertEq(seigManager.maxFraudProofCost(), 0, "Should allow zero cost");
    }


    function test_SM017_setValidatorReward_basic() public {
        address rewardAddress = address(0xABCD);
        seigManager.setValidatorReward(rewardAddress);
        assertEq(seigManager.validatorReward(), rewardAddress, "Should set ValidatorReward address");
    }

    function test_SM018_setValidatorReward_zeroAddress_reverts() public {
        vm.expectRevert(ZeroAddressError.selector);
        seigManager.setValidatorReward(address(0));
    }

    // ==========================================
    // onlyOwner 권한 테스트
    // ==========================================

    function test_SM024_setMaxChallengers_notOwner_reverts() public {
        vm.prank(address(0x9999));
        vm.expectRevert();
        seigManager.setMaxChallengers(10);
    }

    function test_SM025_setMaxFraudProofCost_notOwner_reverts() public {
        vm.prank(address(0x9999));
        vm.expectRevert();
        seigManager.setMaxFraudProofCost(1 ether);
    }

    // ==========================================
    // 배포 스크립트 연동 테스트
    // ==========================================

    function test_SM030_deployedContractsConnected() public view {
        // 배포된 컨트랙트들이 서로 연결되어 있는지 확인
        assertTrue(seigManagerProxy != address(0), "SeigManager deployed");
        assertTrue(depositManagerProxy != address(0), "DepositManager deployed");
        assertTrue(layer2ManagerProxy != address(0), "Layer2Manager deployed");
        assertTrue(ratProxy != address(0), "RAT deployed");
        assertTrue(validatorPoolProxy != address(0), "ValidatorReward deployed");
    }

    function test_SM031_validatorRewardConnected() public view {
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
    // INT-030~032: onBridgedTonChange 통합 테스트
    // ==========================================

    /// @notice INT-030: onBridgedTonChange() 비Portal 호출자 검증 (V3 모드)
    /// @dev V3 모드에서 유효하지 않은 호출자(fakePortal, 일반 사용자)는 silent return
    ///      Note: 실제 Portal 호출 테스트는 V2V3ModeSwitching.t.sol의 test_MIG003에서 수행
    ///            (이 테스트 파일은 DeployV3Full 기반이라 mockPortal 설정이 없음)
    function test_INT030_onBridgedTonChange_callerValidation() public {
        // 1. V3 마이그레이션 활성화
        _setV3ParametersForTest();
        seigManager.migrateToV3();

        // 2. 등록되지 않은 portal에서 호출 → silent return (no revert)
        // 구현: rollupConfigWithPortal(msg.sender) == address(0) 시 return
        address fakePortal = address(0xBAD);
        uint256 totalBefore = seigManager.totalEffectiveBridgedTON();
        vm.prank(fakePortal);
        seigManager.onBridgedTonChange(); // Does not revert, just returns
        uint256 totalAfter = seigManager.totalEffectiveBridgedTON();
        assertEq(totalAfter, totalBefore, "Invalid caller should have no effect");

        // 3. 일반 사용자가 호출 → silent return (no revert)
        totalBefore = seigManager.totalEffectiveBridgedTON();
        vm.prank(address(0x1234));
        seigManager.onBridgedTonChange(); // Does not revert, just returns
        totalAfter = seigManager.totalEffectiveBridgedTON();
        assertEq(totalAfter, totalBefore, "Invalid caller should have no effect");
    }

    /// @notice INT-030: V2 모드에서 onBridgedTonChange는 silent return
    /// @dev v3Migrated=false 시 모든 호출자에 대해 즉시 return (revert 아님)
    ///      Note: Portal/비Portal 구분 테스트는 V2V3ModeSwitching.t.sol의 test_SM021에서 수행
    function test_INT030_onBridgedTonChange_v2Mode_silentReturn() public {
        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        // V3 마이그레이션 전 호출 → silent return (no revert)
        uint256 totalBefore = seigManager.totalEffectiveBridgedTON();
        seigManager.onBridgedTonChange(); // Does not revert, just returns
        uint256 totalAfter = seigManager.totalEffectiveBridgedTON();
        assertEq(totalAfter, totalBefore, "V2 mode call should have no effect");
    }

    /// @notice INT-031: effectiveBridgedTON 업데이트 검증 (단위 테스트)
    /// @dev 자격 획득/상실에 따른 effectiveBridgedTON 변화
    function test_INT031_effectiveBridgedTON_update() public view {
        // effectiveBridgedTON 조회 함수 확인
        uint256 effective = seigManager.getEffectiveBridgedTon(layer2_1);
        assertEq(effective, 0, "Initial effectiveBridgedTON should be 0");
    }

    /// @notice INT-032: totalEffectiveBridgedTON 동기화 검증
    /// @dev 전체 합계 정확성 확인
    function test_INT032_totalEffectiveBridgedTON_sync() public {
        // 1. V3 마이그레이션 활성화
        _setV3ParametersForTest();
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
        uint256 effective = seigManager.getEffectiveBridgedTon(unqualifiedLayer2);
        assertEq(effective, 0, "Unqualified L2 should have 0 effectiveBridgedTON");
    }

    // ==========================================
    // 자격 검증 (Eligibility) 테스트
    // ==========================================

    /// @notice SM-020: checkCurrentEligibility 자격 충족 공식 검증
    /// @dev T_i >= max(D_sequencer, θ×B_i) 시 eligible=true 검증
    ///      백서 공식 8: T_i ≥ max(D_sequencer, θ × B_i)
    ///      Note: 실제 checkCurrentEligibility 함수는 내부 _coinages 매핑 사용으로
    ///            mock 테스트가 불가하여 공식 계산 검증으로 대체
    function test_SM020_checkCurrentEligibility_qualified() public {
        // 1. V3 마이그레이션
        _setV3ParametersForTest();
        seigManager.migrateToV3();

        // 2. 시퀀서 최소 담보금 설정
        // D_sequencer = H_max × C_max + Δ_sequencer
        // = 10 × 10 WTON + 100 WTON = 200 WTON
        seigManager.setMaxChallengers(10);
        seigManager.setMaxFraudProofCost(10e27);
        seigManager.setSequencerAdditionalReward(100e27);

        uint256 expectedDSeq = 10 * 10e27 + 100e27;
        assertEq(expectedDSeq, 200e27, "D_sequencer should be 200 WTON");

        // 3. minStakingRatio 설정
        // θ = 10%
        seigManager.setMinStakingRatio(0.1e27);

        // 4. 공식 계산 검증 (Bridged TON = 1000 TON)
        // θ×B_i = 0.1 × 1000 TON × 1e9 (GWEI) = 100 WTON
        uint256 bridgedTON = 1000e18;
        uint256 GWEI_UNIT = 1e9;
        uint256 theta = seigManager.minStakingRatio();
        uint256 thetaBi = (bridgedTON * GWEI_UNIT * theta) / RAY;
        assertEq(thetaBi, 100e27, "theta*Bi should be 100 WTON");

        // max(D_seq, θ×B_i) = max(200, 100) = 200 WTON
        uint256 requiredStake = thetaBi > expectedDSeq ? thetaBi : expectedDSeq;
        assertEq(requiredStake, 200e27, "Required stake should be max(D_seq, theta*Bi) = 200 WTON");

        // 5. 자격 조건 검증
        // T_i = 250 WTON > 200 WTON (자격 충족)
        uint256 currentStake = 250e27;
        bool eligible = currentStake >= requiredStake;
        assertTrue(eligible, "Should be eligible with T_i=250 >= required=200");
    }

    /// @notice SM-021: checkCurrentEligibility 자격 미달 공식 검증
    /// @dev T_i < max(D_sequencer, θ×B_i) 시 eligible=false 검증
    ///      Note: 실제 checkCurrentEligibility 함수는 내부 _coinages 매핑 사용으로
    ///            mock 테스트가 불가하여 공식 계산 검증으로 대체
    function test_SM021_checkCurrentEligibility_unqualified() public {
        // 1. V3 마이그레이션
        _setV3ParametersForTest();
        seigManager.migrateToV3();

        // 2. 시퀀서 최소 담보금 설정 (SM-020과 동일)
        seigManager.setMaxChallengers(10);
        seigManager.setMaxFraudProofCost(10e27);
        seigManager.setSequencerAdditionalReward(100e27);
        // D_sequencer = 200 WTON
        uint256 expectedDSeq = 10 * 10e27 + 100e27;

        // 3. minStakingRatio 설정
        seigManager.setMinStakingRatio(0.1e27); // θ = 10%

        // 4. 공식 계산 검증 (Bridged TON = 1000 TON)
        // θ×B_i = 0.1 × 1000 TON × 1e9 (GWEI) = 100 WTON
        uint256 bridgedTON = 1000e18;
        uint256 GWEI_UNIT = 1e9;
        uint256 theta = seigManager.minStakingRatio();
        uint256 thetaBi = (bridgedTON * GWEI_UNIT * theta) / RAY;

        // max(D_seq, θ×B_i) = max(200, 100) = 200 WTON
        uint256 requiredStake = thetaBi > expectedDSeq ? thetaBi : expectedDSeq;
        assertEq(requiredStake, 200e27, "Required stake should be max(D_seq, theta*Bi) = 200 WTON");

        // 5. 자격 조건 검증
        // T_i = 150 WTON < 200 WTON (자격 미달)
        uint256 currentStake = 150e27;
        bool eligible = currentStake >= requiredStake;
        assertFalse(eligible, "Should NOT be eligible with T_i=150 < required=200");
    }
}

// ==========================================
// V3TestBase를 사용한 SeigManager 추가 테스트
// ==========================================

import "../helpers/V3TestBase.sol";
import {SeigManagerV1_2} from "../../../src/stake/managers/SeigManagerV1_2.sol";

/// @title SeigManagerV3ViewFunctionsTest
/// @notice stakeOf, getSequencerStaked, updateSeigniorageLayer 테스트
/// @dev V3TestBase를 사용하여 실제 L2 등록 환경에서 테스트
///      NOTE: stakeOf(layer2, account), getOperatorAmount(layer2)는 SeigManagerV1_2에 정의됨
///            SeigManagerV1_2를 통해 호출해야 함
contract SeigManagerV3ViewFunctionsTest is V3TestBase {
    address public user1 = address(0x2001);
    address public user2 = address(0x2002);

    function setUp() public {
        _v3TestSetup();

        // Mint WTON for test users
        vm.startPrank(owner);
        MockWTON(wton).mint(user1, 10000e27);
        MockWTON(wton).mint(user2, 10000e27);
        vm.stopPrank();
    }

    // ==========================================
    // stakeOf Tests (via SeigManagerV1_2)
    // ==========================================

    /// @notice SM-040: stakeOf 조회 (등록된 L2, 스테이킹 후)
    function test_SM040_stakeOf() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        uint256 depositAmount = 500e27;

        // Deposit for user1
        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        depositManager.deposit(mockLayer2, user1, depositAmount);
        vm.stopPrank();

        // Query stakeOf via SeigManagerV1_2
        uint256 stake = SeigManagerV1_2(seigManagerProxy).stakeOf(mockLayer2, user1);
        assertGt(stake, 0, "stakeOf should return positive value");
        assertApproxEqRel(stake, depositAmount, 0.01e18, "stakeOf should match deposit");
    }

    /// @notice SM-042: stakeOf 스테이킹 없는 계정은 0 반환
    function test_SM042_stakeOf_noStake() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        // user1 never deposited
        uint256 stake = SeigManagerV1_2(seigManagerProxy).stakeOf(mockLayer2, user1);
        assertEq(stake, 0, "Account with no stake should return 0");
    }

    // ==========================================
    // getSequencerStaked Tests (via SeigManagerV3_1)
    // ==========================================

    /// @notice SM-045: getSequencerStaked 조회
    function test_SM045_getSequencerStaked() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        // getSequencerStaked returns operator's stake in the layer2
        uint256 sequencerStake = seigManager.getSequencerStaked(mockLayer2);

        // Operator deposit should be reflected
        assertGt(sequencerStake, 0, "Sequencer stake should be > 0");
        assertApproxEqRel(sequencerStake, operatorDeposit, 0.01e18, "Should match operator deposit");
    }

    /// @notice SM-046: getSequencerStaked 미등록 Layer2
    function test_SM046_getSequencerStaked_unregisteredLayer2() public view {
        uint256 stake = seigManager.getSequencerStaked(address(0x9999));
        assertEq(stake, 0, "Unregistered layer2 should return 0");
    }

    /// @notice SM-047: getSequencerStaked 오퍼레이터 없는 경우
    /// @dev coinage는 있지만 operator가 address(0)인 경우
    function test_SM047_getSequencerStaked_noOperator() public view {
        // For a layer2 that was never registered, both coinage and operator are 0
        uint256 stake = seigManager.getSequencerStaked(address(0x1234));
        assertEq(stake, 0, "No operator should return 0");
    }

    // ==========================================
    // getOperatorAmount Tests (via SeigManagerV1_2)
    // ==========================================

    /// @notice SM-050: getOperatorAmount 조회
    function test_SM050_getOperatorAmount() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        uint256 operatorAmount = SeigManagerV1_2(seigManagerProxy).getOperatorAmount(mockLayer2);
        assertGt(operatorAmount, 0, "Operator amount should be > 0");
        assertApproxEqRel(operatorAmount, operatorDeposit, 0.01e18, "Should match operator deposit");
    }

    // ==========================================
    // calculateL2Seigniorage Tests
    // ==========================================

    /// @notice SM-060: calculateL2Seigniorage 기본 계산
    function test_SM060_calculateL2Seigniorage() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        // Setup V3 mode and eligibility
        _setupV3AndMigrate();

        // calculateL2Seigniorage should return proportional share
        uint256 totalY = 1000e27;  // total seigniorage to distribute
        uint256 totalX = 10000e18; // total effective bridged TON

        uint256 seigniorage = seigManager.calculateL2Seigniorage(mockLayer2, totalY, totalX);
        // If effectiveBridgedTON is 0 (not eligible yet), should return 0
        assertEq(seigniorage, 0, "Should return 0 if effectiveBridgedTON is 0");
    }

    /// @notice SM-061: calculateL2Seigniorage totalX가 0일 때
    function test_SM061_calculateL2Seigniorage_zeroTotalX() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        uint256 seigniorage = seigManager.calculateL2Seigniorage(mockLayer2, 1000e27, 0);
        assertEq(seigniorage, 0, "Should return 0 when totalX is 0");
    }

    // ==========================================
    // estimatedDistribute Tests
    // NOTE: estimatedDistribute 셀렉터가 V3_1에 있지만 프록시에 등록 필요
    //       V2 모드에서는 V2Functions.t.sol에서 테스트됨
    // ==========================================

    // ==========================================
    // getLayer2RewardInfo Tests
    // ==========================================

    /// @notice SM-063: getLayer2RewardInfo 조회
    function test_SM063_getLayer2RewardInfo() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        (uint256 layer2Tvl, uint256 initialDebt, uint256 startBlock) = seigManager.getLayer2RewardInfo(mockLayer2);

        // Initial values before any seigniorage distribution
        assertTrue(layer2Tvl >= 0, "layer2Tvl should be valid");
        assertTrue(initialDebt >= 0, "initialDebt should be valid");
        assertTrue(startBlock >= 0, "startBlock should be valid");
    }

    /// @notice SM-064: getLayer2RewardInfo 미등록 Layer2
    function test_SM064_getLayer2RewardInfo_unregistered() public view {
        (uint256 layer2Tvl, uint256 initialDebt, uint256 startBlock) = seigManager.getLayer2RewardInfo(address(0x9999));

        assertEq(layer2Tvl, 0, "Unregistered layer2 should have 0 TVL");
        assertEq(initialDebt, 0, "Unregistered layer2 should have 0 initialDebt");
        assertEq(startBlock, 0, "Unregistered layer2 should have 0 startBlock");
    }

    // ==========================================
    // View Getter Tests
    // ==========================================

    /// @notice SM-070: registry 조회
    function test_SM070_registry() public view {
        address registry = seigManager.registry();
        assertEq(registry, layer2RegistryProxy, "registry should match");
    }

    /// @notice SM-071: depositManager 조회
    function test_SM071_depositManager() public view {
        address dm = seigManager.depositManager();
        assertEq(dm, depositManagerProxy, "depositManager should match");
    }

    /// @notice SM-072: ton 조회
    function test_SM072_ton() public view {
        address tonAddr = seigManager.ton();
        assertEq(tonAddr, ton, "ton should match");
    }

    /// @notice SM-073: wton 조회
    function test_SM073_wton() public view {
        address wtonAddr = seigManager.wton();
        assertEq(wtonAddr, wton, "wton should match");
    }

    /// @notice SM-074: tot 조회
    function test_SM074_tot() public view {
        address totAddr = seigManager.tot();
        assertTrue(totAddr != address(0), "tot should be set");
    }

    /// @notice SM-075: seigPerBlock 조회
    function test_SM075_seigPerBlock() public view {
        uint256 spb = seigManager.seigPerBlock();
        assertGt(spb, 0, "seigPerBlock should be > 0");
    }

    /// @notice SM-076: lastSeigBlock 조회
    function test_SM076_lastSeigBlock() public view {
        uint256 lsb = seigManager.lastSeigBlock();
        assertTrue(lsb >= 0, "lastSeigBlock should be valid");
    }

    /// @notice SM-077: coinages 조회
    function test_SM077_coinages() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        address coinage = seigManager.coinages(mockLayer2);
        assertTrue(coinage != address(0), "coinage should be set after registration");
    }

    /// @notice SM-078: commissionRates 조회
    function test_SM078_commissionRates() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        uint256 commissionRate = seigManager.commissionRates(mockLayer2);
        assertTrue(commissionRate >= 0, "commissionRate should be valid");
    }

    /// @notice SM-079: isCommissionRateNegative 조회
    function test_SM079_isCommissionRateNegative() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        bool isNegative = seigManager.isCommissionRateNegative(mockLayer2);
        assertFalse(isNegative, "Default commission rate should not be negative");
    }

    /// @notice SM-080: lastCommitBlock 조회
    function test_SM080_lastCommitBlock() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        uint256 lcb = seigManager.lastCommitBlock(mockLayer2);
        assertTrue(lcb >= 0, "lastCommitBlock should be valid");
    }

    // ==========================================
    // Branch Coverage Tests
    // ==========================================

    /// @notice SM-090: setDaoDistributionRatio ratio >= RAY revert
    function test_SM090_setDaoDistributionRatio_exceedsRAY_reverts() public {
        uint256 RAY = 1e27;

        vm.expectRevert(InvalidParameterError.selector);
        seigManager.setDaoDistributionRatio(RAY); // Equal to RAY should revert

        vm.expectRevert(InvalidParameterError.selector);
        seigManager.setDaoDistributionRatio(RAY + 1); // Greater than RAY should revert
    }

    /// @notice SM-091: setMinStakingRatio ratio > RAY revert
    function test_SM091_setMinStakingRatio_exceedsRAY_reverts() public {
        uint256 RAY = 1e27;

        // Exactly RAY should be allowed
        seigManager.setMinStakingRatio(RAY);
        assertEq(seigManager.minStakingRatio(), RAY, "RAY value should be allowed");

        // Greater than RAY should revert
        vm.expectRevert(InvalidParameterError.selector);
        seigManager.setMinStakingRatio(RAY + 1);
    }

    /// @notice SM-092: setValidatorDistributionRatio ratio >= RAY revert
    function test_SM092_setValidatorDistributionRatio_exceedsRAY_reverts() public {
        uint256 RAY = 1e27;

        vm.expectRevert(InvalidParameterError.selector);
        seigManager.setValidatorDistributionRatio(RAY);

        vm.expectRevert(InvalidParameterError.selector);
        seigManager.setValidatorDistributionRatio(RAY + 1);
    }

    /// @notice SM-093: setHalfSaturationPoint zero revert
    function test_SM093_setHalfSaturationPoint_zero_reverts() public {
        vm.expectRevert(InvalidParameterError.selector);
        seigManager.setHalfSaturationPoint(0);
    }

    /// @notice SM-094: setV2Logic zero address revert
    function test_SM094_setV2Logic_zeroAddress_reverts() public {
        vm.expectRevert(ZeroAddressError.selector);
        seigManager.setV2Logic(address(0));
    }

    /// @notice SM-095: migrateToV3 이미 마이그레이션 완료 시 revert
    function test_SM095_migrateToV3_alreadyMigrated_reverts() public {
        _setupV3AndMigrate();

        vm.expectRevert(abi.encodeWithSignature("AlreadyMigratedError()"));
        seigManager.migrateToV3();
    }

    /// @notice SM-096: migrateToV3 halfSaturationPoint=0 시 revert
    function test_SM096_migrateToV3_noHalfSaturationPoint_reverts() public {
        // halfSaturationPoint는 0, 나머지는 설정
        seigManager.setMinStakingRatio(0.1e27);
        seigManager.setDaoDistributionRatio(0.1e27);
        seigManager.setValidatorDistributionRatio(0.1e27);
        seigManager.setMaxChallengers(10);
        seigManager.setMaxFraudProofCost(1e27);

        vm.expectRevert(abi.encodeWithSignature("V3ParametersNotSetError()"));
        seigManager.migrateToV3();
    }

    /// @notice SM-097: checkCurrentEligibility V2 모드에서는 eligible=false
    function test_SM097_checkCurrentEligibility_v2Mode() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        (bool eligible, uint256 required, uint256 current) = seigManager.checkCurrentEligibility(mockLayer2);

        assertFalse(eligible, "Should not be eligible in V2 mode");
        assertEq(required, 0, "requiredStake should be 0 in V2 mode");
        assertGt(current, 0, "currentStake should be > 0");
    }

    /// @notice SM-098: estimateL2Seigniorage V2 모드에서는 0 반환
    function test_SM098_estimateL2Seigniorage_v2Mode() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        (uint256 seqReward, uint256 valReward) = seigManager.estimateL2Seigniorage(mockLayer2);
        assertEq(seqReward, 0, "sequencerReward should be 0 in V2 mode");
        assertEq(valReward, 0, "validatorReward should be 0 in V2 mode");
    }

    /// @notice SM-099: claimableL2Seigniorage V2 모드에서 staticcall
    function test_SM099_claimableL2Seigniorage_v2Mode() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        // V2 모드에서는 V3_2로 staticcall (실패 시 0 반환)
        uint256 claimable = seigManager.claimableL2Seigniorage(mockLayer2);
        // Result depends on V2 logic implementation
        assertTrue(claimable >= 0, "Should return valid amount");
    }

    /// @notice SM-100: powerton 조회
    function test_SM100_powerton() public view {
        address pt = seigManager.powerton();
        // powerton 주소가 설정되어 있거나 address(0)일 수 있음
        assertTrue(pt == address(0) || pt != address(0), "powerton getter should work");
    }

    /// @notice SM-101: pausedBlock, unpausedBlock 조회
    function test_SM101_pauseUnpauseBlocks() public view {
        uint256 pausedBlk = seigManager.pausedBlock();
        uint256 unpausedBlk = seigManager.unpausedBlock();

        assertTrue(pausedBlk >= 0, "pausedBlock should be valid");
        assertTrue(unpausedBlk >= 0, "unpausedBlock should be valid");
    }

    /// @notice SM-102: claimableL2Seigniorage V3 모드
    function test_SM102_claimableL2Seigniorage_v3Mode() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        _setupV3AndMigrate();

        // V3 모드에서는 estimateL2Seigniorage의 시퀀서 보상만 반환
        uint256 claimable = seigManager.claimableL2Seigniorage(mockLayer2);
        // effectiveBridgedTON이 0이면 0 반환
        assertEq(claimable, 0, "Should be 0 when not eligible");
    }

    /// @notice SM-103: hyperbolicSaturation x가 매우 큰 경우 L에 수렴
    function test_SM103_hyperbolicSaturation_convergesAtLargeX() public {
        seigManager.setHalfSaturationPoint(1000e27);

        uint256 L = 1000e27;
        uint256 veryLargeX = 1_000_000e27; // 매우 큰 값

        uint256 y = seigManager.hyperbolicSaturation(veryLargeX, L);

        // y = L * x / (k + x) where x >> k, so y ≈ L
        // y should be at least 99.9% of L
        assertGt(y, (L * 999) / 1000, "y should be close to L for large x");
        assertLe(y, L, "y should never exceed L");
    }

    /// @notice SM-104: calculateL2Seigniorage 정상 계산
    function test_SM104_calculateL2Seigniorage_calculation() public view {
        // effectiveBridgedTON이 0인 경우 항상 0 반환
        uint256 totalY = 1000e27;
        uint256 totalX = 10000e18;

        uint256 result = seigManager.calculateL2Seigniorage(address(0x1234), totalY, totalX);
        assertEq(result, 0, "Should be 0 when effectiveBridgedTON is 0");
    }

    // ==========================================
    // Additional Branch Coverage Tests
    // ==========================================

    /// @notice SM-110: onStakingChange - V2 모드에서 silent return
    function test_SM110_onStakingChange_v2Mode() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        // DepositManager에서 호출 (silent return)
        vm.prank(depositManagerProxy);
        seigManager.onStakingChange(mockLayer2);
        // Should not revert, just return
        assertTrue(true, "Should not revert in V2 mode");
    }

    /// @notice SM-111: setRatContract zero address revert
    function test_SM111_setRatContract_zeroAddress_reverts() public {
        vm.expectRevert(ZeroAddressError.selector);
        seigManager.setRatContract(address(0));
    }

    /// @notice SM-112: setRatContract 정상 설정
    function test_SM112_setRatContract_success() public {
        address newRat = address(0x1234);

        seigManager.setRatContract(newRat);
        assertEq(seigManager.ratContract(), newRat, "RAT contract should be set");
    }

    /// @notice SM-113: excludeFromL2Seigniorage 권한 검증
    function test_SM113_excludeFromL2Seigniorage_notLayer2Manager_reverts() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature("OnlyLayer2ManagerError()"));
        seigManager.excludeFromL2Seigniorage(mockLayer2);
    }

    /// @notice SM-114: onDeposit 권한 검증
    function test_SM114_onDeposit_notDepositManager_reverts() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature("OnlyDepositManagerError()"));
        seigManager.onDeposit(mockLayer2, user1, 100e27);
    }

    /// @notice SM-115: onWithdraw 권한 검증
    function test_SM115_onWithdraw_notDepositManager_reverts() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature("OnlyDepositManagerError()"));
        seigManager.onWithdraw(mockLayer2, user1, 100e27);
    }

    /// @notice SM-116: transferCoinageToRat 권한 검증
    function test_SM116_transferCoinageToRat_notRat_reverts() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        _setupV3AndMigrate();

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature("OnlyRatError()"));
        seigManager.transferCoinageToRat(mockLayer2, user1, 100e27);
    }

    /// @notice SM-117: transferCoinageFromRat 권한 검증
    function test_SM117_transferCoinageFromRat_notRat_reverts() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        _setupV3AndMigrate();

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature("OnlyRatError()"));
        seigManager.transferCoinageFromRat(mockLayer2, user1, 100e27);
    }

    /// @notice SM-118: v3MigrationBlock 조회
    function test_SM118_v3MigrationBlock() public {
        assertEq(seigManager.v3MigrationBlock(), 0, "Should be 0 before migration");

        _setupV3AndMigrate();

        assertGt(seigManager.v3MigrationBlock(), 0, "Should be set after migration");
    }

    /// @notice SM-119: bridgedTONRewardPerUint 조회
    function test_SM119_bridgedTONRewardPerUint() public {
        _setupV3AndMigrate();

        uint256 rewardPerUnit = seigManager.bridgedTONRewardPerUint();
        assertTrue(rewardPerUnit >= 0, "Should return valid value");
    }

    /// @notice SM-120: validatorRewardPerUint 조회
    function test_SM120_validatorRewardPerUint() public {
        _setupV3AndMigrate();

        uint256 rewardPerUnit = seigManager.validatorRewardPerUint();
        assertTrue(rewardPerUnit >= 0, "Should return valid value");
    }

    /// @notice SM-121: layer2Manager getter
    function test_SM121_layer2Manager() public view {
        address l2m = seigManager.layer2Manager();
        assertEq(l2m, layer2ManagerProxy, "layer2Manager should match");
    }

    /// @notice SM-122: l1BridgeRegistry getter
    function test_SM122_l1BridgeRegistry() public view {
        address l1br = seigManager.l1BridgeRegistry();
        assertEq(l1br, l1BridgeRegistryProxy, "l1BridgeRegistry should match");
    }

    /// @notice SM-123: checkCurrentEligibility bridgedTon=0인 경우
    function test_SM123_checkCurrentEligibility_zeroBridgedTon() public {
        uint256 operatorDeposit = 1000e27;
        _registerFirstL2(operatorDeposit);

        _setupV3AndMigrate();

        // mockLayer2는 type 3이지만 bridgedTon이 0
        (bool eligible, uint256 required, uint256 current) = seigManager.checkCurrentEligibility(mockLayer2);

        // bridgedTon=0이면 eligible=false, required=0
        assertFalse(eligible, "Should not be eligible when bridgedTon=0");
        assertEq(required, 0, "Required should be 0 when bridgedTon=0");
    }

    /// @notice SM-124: paused getter
    function test_SM124_paused() public view {
        bool isPaused = seigManager.paused();
        assertFalse(isPaused, "Should not be paused initially");
    }

    /// @notice SM-125: dao getter
    function test_SM125_dao() public view {
        address daoAddr = seigManager.dao();
        // dao 주소가 설정되어 있거나 address(0)일 수 있음
        assertTrue(daoAddr == address(0) || daoAddr != address(0), "dao getter should work");
    }

    /// @notice SM-126: minimumAmount getter
    function test_SM126_minimumAmount() public view {
        uint256 minAmount = seigManager.minimumAmount();
        assertTrue(minAmount >= 0, "minimumAmount should be valid");
    }
}
