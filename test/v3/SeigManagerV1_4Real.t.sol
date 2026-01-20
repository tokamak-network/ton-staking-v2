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
}
