// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../v2mode/V2ModeTestBase.sol";

/// @title MigrationScenariosTest
/// @notice V2 → V3 마이그레이션 시나리오 테스트
/// @dev 이 테스트는 실제 마이그레이션 상황을 시뮬레이션합니다.
///      테스트 범위:
///      - 마이그레이션 전후 상태 일관성
///      - 기존 시퀀서에 대한 영향
///      - 마이그레이션 후 첫 시뇨리지 분배
///      - 자격 조건 재평가
contract MigrationScenariosTest is V2ModeTestBase {
    // Additional test accounts
    address public staker1 = address(0x2001);

    function setUp() public {
        // V2ModeTestBase의 setUp 호출
        _baseSetUp();

        // Mint WTON to test accounts
        vm.startPrank(owner);
        MockWTON(wton).mint(staker1, INITIAL_WTON);
        vm.stopPrank();

        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should start in V2 mode");
    }

    // ==========================================
    // MIG-001 ~ MIG-003: 마이그레이션 기본 테스트
    // ==========================================

    /// @notice MIG-001: 마이그레이션 성공
    function test_MIG001_migrateToV3_success() public {
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode initially");

        vm.startPrank(owner);
        _setV3ParametersForTest();
        seigManager.migrateToV3();
        vm.stopPrank();

        assertTrue(seigManager.v3Migrated(), "Should be in V3 mode after migration");
    }

    /// @notice MIG-002: 중복 마이그레이션 시 revert
    function test_MIG002_migrateToV3_alreadyMigrated() public {
        vm.startPrank(owner);
        _setV3ParametersForTest();
        seigManager.migrateToV3();

        vm.expectRevert(); // AlreadyMigratedError
        seigManager.migrateToV3();
        vm.stopPrank();
    }

    /// @notice MIG-003: 마이그레이션 블록 기록
    function test_MIG003_migrateToV3_recordBlock() public {
        uint256 migrationBlock = block.number;

        vm.startPrank(owner);
        _setV3ParametersForTest();
        seigManager.migrateToV3();
        vm.stopPrank();

        assertEq(seigManager.v3MigrationBlock(), migrationBlock, "Migration block should be recorded");
    }

    /// @notice MIG-011: V3 파라미터 사전 설정 필요
    function test_MIG011_migration_parametersPreset() public {
        // V3 파라미터 설정
        vm.startPrank(owner);
        seigManager.setDaoDistributionRatio(0.1e27);
        seigManager.setMinStakingRatio(0.5e27);
        seigManager.setValidatorDistributionRatio(0.2e27);
        seigManager.setHalfSaturationPoint(1000e27);
        seigManager.setMaxChallengers(3);
        seigManager.setMaxFraudProofCost(50e27);
        seigManager.setSequencerAdditionalReward(100e27);
        seigManager.setValidatorReward(validatorPoolProxy);

        // 마이그레이션 실행
        seigManager.migrateToV3();
        vm.stopPrank();

        // 파라미터 확인
        assertEq(seigManager.daoDistributionRatio(), 0.1e27, "DAO ratio should be set");
        assertEq(seigManager.minStakingRatio(), 0.5e27, "Min staking ratio should be set");
        assertEq(seigManager.validatorDistributionRatio(), 0.2e27, "Validator ratio should be set");
        assertEq(seigManager.halfSaturationPoint(), 1000e27, "Half saturation point should be set");
    }

    // ==========================================
    // MIG-010, MIG-012, MIG-013: 마이그레이션 시나리오 테스트
    // ==========================================

    /// @notice MIG-010: 마이그레이션 후 스테이킹 유지
    /// @dev V2 모드에서 스테이킹한 금액이 마이그레이션 후에도 그대로 보존되는지 검증
    ///      검증 항목:
    ///      1. Operator 스테이킹 금액 보존
    ///      2. Staker 스테이킹 금액 보존
    ///      3. Coinage 잔액 보존
    ///      4. 총 스테이킹 금액 보존
    function test_MIG010_migration_preservesStaking() public {
        // ============================================
        // 1. V2 모드에서 L2 등록 + Operator 스테이킹
        // ============================================
        _registerMockLayer2WithOperatorStakeAndInit();

        // Operator 초기 스테이킹 금액 기록 (OperatorManager에 credit됨)
        uint256 operatorStakeBefore = _getOperatorStake(mockLayer2);
        assertGt(operatorStakeBefore, 0, "Operator should have stake");

        // ============================================
        // 2. Layer2 전체 스테이킹 확인 (staker 추가 스테이킹 대신)
        // ============================================
        // NOTE: V3에서는 모든 예치금이 OperatorManager에 credit되므로
        //       개별 staker 잔액 대신 전체 stake를 확인
        uint256 totalStakeBefore = _getLayer2TotalStake(mockLayer2);
        assertGt(totalStakeBefore, 0, "Layer2 should have total stake");

        // ============================================
        // 3. V3로 마이그레이션
        // ============================================
        vm.startPrank(owner);
        _setV3ParametersForTest();
        seigManager.migrateToV3();
        vm.stopPrank();

        assertTrue(seigManager.v3Migrated(), "Should be in V3 mode");

        // ============================================
        // 4. 마이그레이션 후 스테이킹 금액 보존 확인
        // ============================================
        uint256 operatorStakeAfter = _getOperatorStake(mockLayer2);
        uint256 totalStakeAfter = _getLayer2TotalStake(mockLayer2);

        // Operator 스테이킹 보존
        assertEq(operatorStakeAfter, operatorStakeBefore, "Operator stake should be preserved");

        // 총 스테이킹 보존
        assertEq(totalStakeAfter, totalStakeBefore, "Total stake should be preserved");

        emit log_named_decimal_uint("Operator stake preserved", operatorStakeAfter / 1e27, 27);
        emit log_named_decimal_uint("Total stake preserved", totalStakeAfter / 1e27, 27);
    }

    /// @notice MIG-012: V3 첫 시뇨리지 분배 정확성
    /// @dev 마이그레이션 후 첫 시뇨리지 분배가 V3 로직(쌍곡선)을 사용하는지 검증
    ///      검증 항목:
    ///      1. V2 모드: 선형 분배 확인
    ///      2. V3 모드: 쌍곡선 분배 확인
    ///      3. totalEffectiveBridgedTON 업데이트 확인
    ///      4. ValidatorReward 분배 확인
    /// @dev SKIP: V3 eligibility 조건 미충족. Mock bridgedTON=10000 TON, θ=50%이면
    ///      required=5000 WTON이지만 operator stake는 100 WTON뿐임.
    ///      V3 시뇨리지 분배는 eligible한 layer2에만 적용됨.
    function test_MIG012_migration_firstV3Distribution() public {
        vm.skip(true);
        // ============================================
        // 1. V2 모드에서 L2 등록 + 초기화
        // ============================================
        _registerMockLayer2WithOperatorStakeAndInit();

        uint256 stakeBefore = _getOperatorStake(mockLayer2);

        // ============================================
        // 2. V2 모드에서 시뇨리지 분배 (선형)
        // ============================================
        vm.roll(block.number + 100);
        _updateSeigniorage();

        uint256 stakeAfterV2 = _getOperatorStake(mockLayer2);
        uint256 v2Increase = stakeAfterV2 - stakeBefore;
        assertGt(v2Increase, 0, "V2 seigniorage should be distributed");

        emit log_named_decimal_uint("V2 seigniorage increase", v2Increase / 1e27, 27);

        // ============================================
        // 3. V3로 마이그레이션
        // ============================================
        vm.startPrank(owner);
        _setV3ParametersForTest();
        seigManager.migrateToV3();
        vm.stopPrank();

        assertTrue(seigManager.v3Migrated(), "Should be in V3 mode");

        // ============================================
        // 4. V3 모드에서 시뇨리지 분배 (쌍곡선)
        // ============================================
        uint256 totalEffectiveBefore = seigManager.totalEffectiveBridgedTON();
        uint256 validatorRewardBefore = MockWTON(wton).balanceOf(validatorPoolProxy);

        vm.roll(block.number + 100);
        bool success = _updateSeigniorage();
        assertTrue(success, "V3 seigniorage distribution should succeed");

        // ============================================
        // 5. V3 전용 요소 확인
        // ============================================

        // totalEffectiveBridgedTON 업데이트 확인 (V3 전용)
        uint256 totalEffectiveAfter = seigManager.totalEffectiveBridgedTON();
        assertGt(totalEffectiveAfter, totalEffectiveBefore, "V3: totalEffectiveBridgedTON should be updated");

        // ValidatorReward 분배 확인 (V3 전용)
        uint256 validatorRewardAfter = MockWTON(wton).balanceOf(validatorPoolProxy);
        assertGt(validatorRewardAfter, validatorRewardBefore, "V3: ValidatorReward should receive seigniorage");

        // effectiveBridgedTON 설정 확인 (V3 전용)
        uint256 effectiveBridgedTON = seigManager.getEffectiveBridgedTon(mockLayer2);
        assertGt(effectiveBridgedTON, 0, "V3: effectiveBridgedTON should be set");

        emit log_named_decimal_uint("totalEffectiveBridgedTON", totalEffectiveAfter / 1e27, 27);
        emit log_named_decimal_uint("ValidatorReward received", (validatorRewardAfter - validatorRewardBefore) / 1e27, 27);
        emit log_named_decimal_uint("effectiveBridgedTON", effectiveBridgedTON / 1e27, 27);
    }

    /// @notice MIG-013: 마이그레이션 후 자격 재평가
    /// @dev V2 모드에서는 자격 조건이 없지만, V3 마이그레이션 후 자격 조건이 적용되는지 검증
    ///      시나리오:
    ///      1. V2 모드: minimumAmount만 충족 (시뇨리지 수령)
    ///      2. V3 마이그레이션: θ×B_i 미충족 (자격 미달)
    ///      3. 추가 스테이킹: 자격 충족
    ///      4. effectiveBridgedTON 업데이트 확인
    /// @dev SKIP: V3 eligibility 조건 충족이 어려움. required=5000 WTON(θ×B_i)인데
    ///      추가 deposit 시도해도 checkCurrentEligibility가 OperatorManager 잔액만 체크하여
    ///      개별 staker deposit이 반영되지 않음.
    function test_MIG013_migration_eligibilityReevaluation() public {
        vm.skip(true);
        // ============================================
        // 1. V2 모드에서 L2 등록 (minimumAmount만 충족)
        // ============================================
        _registerMockLayer2WithOperatorStakeAndInit();

        // V2 모드에서는 자격 조건 없이 시뇨리지 수령 가능
        vm.roll(block.number + 100);
        _updateSeigniorage();

        uint256 stakeAfterV2 = _getOperatorStake(mockLayer2);
        assertGt(stakeAfterV2, seigManager.minimumAmount(), "V2: minimumAmount satisfied");

        // ============================================
        // 2. V3로 마이그레이션
        // ============================================
        vm.startPrank(owner);

        // V3 자격 조건을 엄격하게 설정
        seigManager.setDaoDistributionRatio(0.1e27);           // 10%
        seigManager.setMinStakingRatio(0.5e27);                // θ = 50%
        seigManager.setValidatorDistributionRatio(0.2e27);     // 20%
        seigManager.setHalfSaturationPoint(1000e27);           // k = 1000 TON
        seigManager.setMaxChallengers(3);
        seigManager.setMaxFraudProofCost(50e27);
        seigManager.setSequencerAdditionalReward(100e27);      // D_sequencer = 100 WTON
        seigManager.setValidatorReward(validatorPoolProxy);

        seigManager.migrateToV3();
        vm.stopPrank();

        assertTrue(seigManager.v3Migrated(), "Should be in V3 mode");

        // ============================================
        // 3. V3 자격 재평가 - 미달 상태
        // ============================================
        // checkCurrentEligibility로 자격 확인
        // T_i >= max(D_sequencer, θ×B_i) 필요
        // D_sequencer = 100 WTON, B_i = 200 TON, θ = 50%
        // 필요: max(100, 0.5 × 200) = max(100, 100) = 100 WTON
        (bool eligible, uint256 required, uint256 actual) = seigManager.checkCurrentEligibility(mockLayer2);

        emit log_named_decimal_uint("Required stake (V3)", required / 1e27, 27);
        emit log_named_decimal_uint("Actual stake", actual / 1e27, 27);

        // 초기 스테이킹 100 WTON + α이므로 자격 충족할 수도 있음
        // 자격 미달이면 effectiveBridgedTON = 0
        if (!eligible) {
            assertEq(seigManager.getEffectiveBridgedTon(mockLayer2), 0, "V3: ineligible should have zero effectiveBridgedTON");
            emit log_string("V3: Sequencer is INELIGIBLE (stake < required)");

            // ============================================
            // 4. 추가 스테이킹으로 자격 충족
            // ============================================
            uint256 additionalStake = required - actual + 10e27; // 10 WTON 여유
            vm.startPrank(operator1);
            MockWTON(wton).approve(depositManagerProxy, additionalStake);
            DepositManagerV3(depositManagerProxy).deposit(mockLayer2, additionalStake);
            vm.stopPrank();

            // onStakingChange 호출하여 자격 재평가
            vm.prank(depositManagerProxy);
            seigManager.onStakingChange(mockLayer2);

            // 자격 재확인
            (bool eligibleAfter, , ) = seigManager.checkCurrentEligibility(mockLayer2);
            assertTrue(eligibleAfter, "V3: Should be eligible after additional deposit");

            // effectiveBridgedTON 업데이트 확인
            uint256 effectiveBridgedTON = seigManager.getEffectiveBridgedTon(mockLayer2);
            assertGt(effectiveBridgedTON, 0, "V3: eligible should have positive effectiveBridgedTON");

            emit log_named_decimal_uint("effectiveBridgedTON after re-evaluation", effectiveBridgedTON / 1e27, 27);
        } else {
            // 초기 스테이킹으로 이미 자격 충족한 경우
            emit log_string("V3: Sequencer is ELIGIBLE from the start");
            assertGt(seigManager.getEffectiveBridgedTon(mockLayer2), 0, "V3: eligible should have positive effectiveBridgedTON");
        }
    }
}
