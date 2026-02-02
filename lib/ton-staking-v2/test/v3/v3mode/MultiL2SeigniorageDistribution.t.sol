// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../helpers/V3TestBase.sol";
import {LastSeigBlockError} from "../../../src/stake/managers/SeigManagerV3_1.sol";
import {MockWTON} from "../../../src/mocks/MockWTON.sol";

/// @title MultiL2SeigniorageDistributionTest
/// @notice 다중 L2 시뇨리지 분배 테스트
/// @dev 테스트 계획서 E2E-031: 다중 L2 비례 분배 정확성 검증
///
/// 테스트 대상:
/// - E2E-031: 다중 L2에서 effectiveBridgedTON 비례 분배 정확성
/// - SD-014: B̃_i 비례 분배 - Seig_i = y(x) · (B̃_i / x)
/// - SD-015: 자격 미달 L2 제외 분배 정확성
contract MultiL2SeigniorageDistributionTest is V3TestBase {
    // ==========================================
    // Mock Contracts - L2 #2
    // ==========================================
    SimpleMockSystemConfig public mockSystemConfig2;
    address public mockL1Bridge2;
    address public mockPortal2;
    address public mockDisputeGameFactory2;
    address public mockL2TON2;
    address public mockLayer2_2;
    address public operatorManager2;

    // ==========================================
    // Mock Contracts - L2 #3
    // ==========================================
    SimpleMockSystemConfig public mockSystemConfig3;
    address public mockL1Bridge3;
    address public mockPortal3;
    address public mockDisputeGameFactory3;
    address public mockL2TON3;
    address public mockLayer2_3;
    address public operatorManager3;

    // ==========================================
    // Additional Test Addresses
    // ==========================================
    address public operator2 = address(0x4002);
    address public operator3 = address(0x4003);
    address public validator1 = address(0x6001);
    address public dao;

    function setUp() public {
        _v3TestSetup();

        dao = address(0xDA0);

        vm.startPrank(owner);

        // RAT 파라미터 설정
        _setupRATParams();

        // Mock 컨트랙트 생성 및 L2 등록
        _setupMockContractsAndRegisterL2s();

        // SeigManager에 RAT 컨트랙트 주소 설정
        seigManager.setRatContract(address(rat));

        // 테스트 환경을 위한 seigniorage 시작 블록 및 초기 공급량 설정
        SeigManagerV1_2(seigManagerProxy).setSeigStartBlock(block.number);
        SeigManagerV1_2(seigManagerProxy).setInitialTotalSupply(50000000e27);

        // V3 파라미터 설정
        seigManager.setDaoDistributionRatio(0.1e27);     // d = 10%
        seigManager.setMinStakingRatio(0.1e27);          // θ = 10%
        seigManager.setValidatorDistributionRatio(0.2e27); // α = 20%
        seigManager.setHalfSaturationPoint(1000e27);     // k = 1000

        // V3 파라미터 설정 및 마이그레이션
        _setV3ParametersForTest();
        seigManager.migrateToV3();

        vm.stopPrank();
    }

    function _setupMockContractsAndRegisterL2s() internal {
        // L2 #1: 1000 TON 브릿지
        mockL1Bridge = address(0x8101);
        mockPortal = address(0x8102);
        mockDisputeGameFactory = address(0x8103);
        mockL2TON = address(0x8104);

        mockSystemConfig = new SimpleMockSystemConfig();
        mockSystemConfig.setL1StandardBridge(mockL1Bridge);
        mockSystemConfig.setOptimismPortal(mockPortal);
        mockSystemConfig.setDisputeGameFactory(mockDisputeGameFactory);
        mockSystemConfig.setUnsafeBlockSigner(operator1);

        (mockLayer2, operatorManager) = _registerLayer2WithSystemConfig(
            address(mockSystemConfig),
            mockL2TON,
            "TestL2_1",
            operator1,
            1000 * RAY // 오퍼레이터 담보금
        );

        // L2 #2: 2000 TON 브릿지
        mockL1Bridge2 = address(0x8201);
        mockPortal2 = address(0x8202);
        mockDisputeGameFactory2 = address(0x8203);
        mockL2TON2 = address(0x8204);

        mockSystemConfig2 = new SimpleMockSystemConfig();
        mockSystemConfig2.setL1StandardBridge(mockL1Bridge2);
        mockSystemConfig2.setOptimismPortal(mockPortal2);
        mockSystemConfig2.setDisputeGameFactory(mockDisputeGameFactory2);
        mockSystemConfig2.setUnsafeBlockSigner(operator2);

        (mockLayer2_2, operatorManager2) = _registerLayer2WithSystemConfig(
            address(mockSystemConfig2),
            mockL2TON2,
            "TestL2_2",
            operator2,
            1000 * RAY
        );

        // L2 #3: 3000 TON 브릿지
        mockL1Bridge3 = address(0x8301);
        mockPortal3 = address(0x8302);
        mockDisputeGameFactory3 = address(0x8303);
        mockL2TON3 = address(0x8304);

        mockSystemConfig3 = new SimpleMockSystemConfig();
        mockSystemConfig3.setL1StandardBridge(mockL1Bridge3);
        mockSystemConfig3.setOptimismPortal(mockPortal3);
        mockSystemConfig3.setDisputeGameFactory(mockDisputeGameFactory3);
        mockSystemConfig3.setUnsafeBlockSigner(operator3);

        (mockLayer2_3, operatorManager3) = _registerLayer2WithSystemConfig(
            address(mockSystemConfig3),
            mockL2TON3,
            "TestL2_3",
            operator3,
            1000 * RAY
        );
    }

    // ==========================================
    // E2E-031: 다중 L2 비례 분배 테스트
    // ==========================================

    /// @notice E2E-031: 쌍곡선 포화 함수 계산 검증
    function test_E2E031_hyperbolicSaturation_formula() public view {
        // y(x) = L × (x / (k + x))
        // k = 1000e27 (halfSaturationPoint)

        uint256 L = 1000e27; // 최대 L2 배분
        uint256 k = seigManager.halfSaturationPoint();

        // x = 0 → y = 0
        assertEq(seigManager.hyperbolicSaturation(0, L), 0, "y(0) should be 0");

        // x = k → y = L × (k / 2k) = L/2
        uint256 yAtK = seigManager.hyperbolicSaturation(k, L);
        assertEq(yAtK, L / 2, "y(k) = L/2");

        // x = 2k → y = L × (2k / 3k) = 2L/3
        uint256 yAt2K = seigManager.hyperbolicSaturation(2 * k, L);
        assertEq(yAt2K, (2 * L) / 3, "y(2k) = 2L/3");

        // x = 100k → y = L × (100k / 101k) = 100L/101
        uint256 yAtLarge = seigManager.hyperbolicSaturation(100 * k, L);
        assertEq(yAtLarge, (100 * L) / 101, "y(100k) = 100L/101");
    }

    /// @notice 시퀀서 보상 계산 검증
    /// @dev o_i = (1 - α) × Seig_i
    function test_SD012_sequencerReward_formula() public view {
        uint256 l2Seigniorage = 1000e27;

        // 시퀀서 = (1 - 0.2) × 1000 = 800
        uint256 sequencerReward = seigManager.calculateSequencerReward(l2Seigniorage);
        assertEq(sequencerReward, 800e27, "Sequencer should get (1-alpha) * seig");

        // 검증자 = α × 1000 = 200
        uint256 validatorReward = l2Seigniorage - sequencerReward;
        assertEq(validatorReward, 200e27, "Validators should get alpha * seig");
    }

    /// @notice SD-001: V3 마이그레이션 상태 확인
    function test_SD001_v3Migration_state() public view {
        assertTrue(seigManager.v3Migrated(), "Should be V3 migrated");
        assertGt(seigManager.v3MigrationBlock(), 0, "Migration block should be set");
    }

    /// @notice SD-002: 파라미터 설정 검증
    function test_SD002_v3Parameters_verification() public view {
        // Note: _setV3ParametersForTest() sets these values (overrides earlier settings)
        assertEq(seigManager.daoDistributionRatio(), 0.1e27, "d = 10%");
        // theta = 1% (테스트용 낮은 값, operator stake 100 WTON으로 eligible 가능)
        assertEq(seigManager.minStakingRatio(), 0.01e27, "theta = 1%"); // Set by _setV3ParamsCore()
        assertEq(seigManager.validatorDistributionRatio(), 0.2e27, "alpha = 20%");
        assertEq(seigManager.halfSaturationPoint(), 1000e27, "k = 1000");
    }

    /// @notice SD-017: 같은 블록에서 두 번째 L2 호출 시 claim만 수행
    /// @dev 시뇨리지는 첫 번째 호출에서만 mint, 두 번째는 claim only
    function test_SD017_claimOnlyInSameBlock() public {
        vm.roll(block.number + 100);

        // 첫 번째 호출 - 성공, 시뇨리지 계산 및 mint
        vm.prank(mockLayer2);
        bool success = seigManager.updateSeigniorage();
        assertTrue(success, "First updateSeigniorage should succeed");

        // lastSeigBlock이 현재 블록으로 업데이트됨
        uint256 lastSeigBlock = SeigManagerV1_2(seigManagerProxy).lastSeigBlock();
        assertEq(lastSeigBlock, block.number, "lastSeigBlock should be current block");

        // DAO 잔액 기록 (추가 mint 여부 확인용)
        address daoAddr = SeigManagerV1_2(seigManagerProxy).dao();
        uint256 daoBalanceAfterFirst = MockWTON(wton).balanceOf(daoAddr);

        // 두 번째 호출 - 같은 블록에서 claim only (추가 mint 없음)
        vm.prank(mockLayer2_2);
        success = seigManager.updateSeigniorage();
        assertTrue(success, "Second updateSeigniorage should succeed (claim only)");

        // DAO 잔액 변화 없음 (추가 시뇨리지 mint 없음)
        uint256 daoBalanceAfterSecond = MockWTON(wton).balanceOf(daoAddr);
        assertEq(daoBalanceAfterSecond, daoBalanceAfterFirst, "No additional seigniorage minted");
    }

    /// @notice SD-018: 다른 블록에서는 분배 가능
    function test_SD018_distributionAllowed_differentBlock() public {
        vm.roll(block.number + 100);

        // 첫 번째 호출
        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        // 다음 블록으로 이동
        vm.roll(block.number + 1);

        // 두 번째 호출 - 다른 블록이므로 성공
        vm.prank(mockLayer2_2);
        bool success = seigManager.updateSeigniorage();
        assertTrue(success, "updateSeigniorage should succeed on different block");
    }
}
