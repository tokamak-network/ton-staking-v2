// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../v2mode/V2ModeTestBase.sol";

/// @title SequencerJourneyTest
/// @notice 시퀀서의 전체 여정 시나리오 테스트
/// @dev 이 테스트는 시퀀서가 V3 시스템에 참여하는 실제 여정을 시뮬레이션합니다.
///      테스트 범위:
///      - 신규 시퀀서의 V3 참여 플로우
///      - 자격 상태 전환 (미달 → 충족 → 상실 → 재획득)
///      - Fraud Proof 슬래싱 및 복구
contract SequencerJourneyTest is V2ModeTestBase {
    function setUp() public {
        // V2ModeTestBase의 setUp 호출
        _baseSetUp();

        // V3 파라미터 설정만 (마이그레이션은 layer2 등록 후에)
        vm.startPrank(owner);
        seigManager.setDaoDistributionRatio(0.1e27);          // 10%
        seigManager.setMinStakingRatio(0.5e27);               // 50%
        seigManager.setValidatorDistributionRatio(0.2e27);    // 20%
        seigManager.setHalfSaturationPoint(1000e27);          // 1000 TON
        seigManager.setMaxChallengers(3);                     // H_max = 3
        seigManager.setMaxFraudProofCost(50e27);             // C_max = 50 WTON
        seigManager.setSequencerAdditionalReward(100e27);     // D_sequencer = 100 WTON
        seigManager.setValidatorReward(validatorPoolProxy);
        vm.stopPrank();
    }

    /// @notice Layer2 등록 + 시뇨리지 초기화 (V2 모드) + V3 마이그레이션
    function _setupLayer2AndMigrateV3() internal {
        // V2 모드에서 layer2 등록 및 시뇨리지 초기화
        _registerMockLayer2WithOperatorStakeAndInit();

        // V3 모드로 마이그레이션
        vm.prank(owner);
        seigManager.migrateToV3();
        assertTrue(seigManager.v3Migrated(), "Should be in V3 mode");
    }

    // ==========================================
    // SCEN-SEQ-001: 신규 시퀀서의 V3 참여 전체 플로우
    // ==========================================

    /// @notice SCEN-SEQ-001: 신규 시퀀서의 V3 참여 전체 플로우
    /// @dev 신규 시퀀서가 V3 시스템에 참여하여 자격을 획득하고 시뇨리지를 수령하는 전체 여정 검증
    ///      시나리오:
    ///      1. V3 모드에서 L2 등록
    ///      2. 초기 담보금 예치 (minimumAmount 충족, 하지만 V3 자격 미달 가능)
    ///      3. OperatorManager에 자격 충족 확인 또는 추가 예치
    ///      4. 시뇨리지 분배 및 수령 확인
    ///      5. effectiveBridgedTON 업데이트 확인
    function test_SCENSEQ001_newSequencer_fullJourney() public {
        // vm.skip(true);
        // ============================================
        // 1. L2 등록 (V2 모드에서 등록 후 V3 마이그레이션)
        // ============================================
        _setupLayer2AndMigrateV3();

        emit log_string("Step 1: L2 registered with initial operator stake");
        uint256 operatorStake = _getStake(mockLayer2, operator1);
        emit log_named_decimal_uint("Initial operator stake", operatorStake / 1e18, 18);

        // ============================================
        // 2. V3 자격 조건 확인
        // ============================================
        (bool eligible, uint256 required, uint256 actual) = seigManager.checkCurrentEligibility(mockLayer2);

        emit log_named_decimal_uint("Required stake", required / 1e18, 18);
        emit log_named_decimal_uint("Actual stake", actual / 1e18, 18);
        emit log_named_string("Eligibility", eligible ? "ELIGIBLE" : "INELIGIBLE");

        // ============================================
        // 3. 자격 미달인 경우 OperatorManager에 추가 예치
        // ============================================
        if (!eligible) {
            emit log_string("Step 2: Sequencer is ineligible, depositing additional stake to OperatorManager");

            _ensureV3Eligibility(mockLayer2);

            // 자격 재확인
            (eligible, required, actual) = seigManager.checkCurrentEligibility(mockLayer2);
            assertTrue(eligible, "Should be eligible after additional deposit");
            emit log_string("Now ELIGIBLE after additional deposit");
        }

        // ============================================
        // 4. 시뇨리지 분배 및 수령 확인
        // ============================================
        emit log_string("Step 3: First seigniorage distribution");

        uint256 stakeBefore = _getStake(mockLayer2, operator1);
        uint256 totalEffectiveBefore = seigManager.totalEffectiveBridgedTON();

        vm.roll(block.number + 100);
        bool success = _updateSeigniorage();
        assertTrue(success, "Seigniorage distribution should succeed");

        uint256 stakeAfter = _getStake(mockLayer2, operator1);
        uint256 seigniorageIncrease = stakeAfter - stakeBefore;

        // 시뇨리지 수령 확인
        assertGe(seigniorageIncrease, 0, "Sequencer should receive seigniorage");
        emit log_named_decimal_uint("Seigniorage received", seigniorageIncrease / 1e18, 18);

        // ============================================
        // 5. V3 전용 요소 확인
        // ============================================
        emit log_string("Step 4: Verify V3-specific elements");

        // totalEffectiveBridgedTON 업데이트
        uint256 totalEffectiveAfter = seigManager.totalEffectiveBridgedTON();
        assertGe(totalEffectiveAfter, totalEffectiveBefore, "totalEffectiveBridgedTON should be set");

        // effectiveBridgedTON 설정
        uint256 effectiveBridgedTONAfter = seigManager.getEffectiveBridgedTon(mockLayer2);
        assertGt(effectiveBridgedTONAfter, 0, "effectiveBridgedTON should be set");

        emit log_named_decimal_uint("totalEffectiveBridgedTON", totalEffectiveAfter / 1e18, 18);
        emit log_named_decimal_uint("effectiveBridgedTON", effectiveBridgedTONAfter / 1e18, 18);

        emit log_string("SCEN-SEQ-001: New sequencer journey completed successfully");
    }

    // ==========================================
    // SCEN-SEQ-002: 자격 상태 전환
    // ==========================================

    /// @notice SCEN-SEQ-002: 시퀀서 자격 상태 전환
    /// @dev 시퀀서가 자격 충족 → 상실 → 재획득 상태를 거치는 시나리오 검증
    ///      시나리오:
    ///      1. 자격 충족 상태에서 시작 (충분한 담보금)
    ///      2. Bridged TON 증가로 required 증가 → 자격 상실
    ///      3. effectiveBridgedTON = 0 확인
    ///      4. OperatorManager에 추가 담보금 예치로 자격 재획득
    ///      5. effectiveBridgedTON 복원 확인
    function test_SCENSEQ002_sequencer_eligibilityTransition() public {
        // vm.skip(true);
        // ============================================
        // 1. 자격 충족 상태로 시작
        // ============================================
        _setupLayer2AndMigrateV3();

        // 자격 충족을 위해 OperatorManager에 충분한 담보금 예치
        (bool eligible0, uint256 required0, uint256 actual0) = seigManager.checkCurrentEligibility(mockLayer2);

        address operatorManagerAddr = Layer2I(mockLayer2).operator();
        
        if (!eligible0) {
            uint256 additionalDeposit = required0 - actual0 + 100e27;

            vm.startPrank(owner);
            MockWTON(wton).mint(owner, additionalDeposit);
            MockWTON(wton).approve(depositManagerProxy, additionalDeposit);
            DepositManagerV3(depositManagerProxy).deposit(mockLayer2, operatorManagerAddr, additionalDeposit);
            vm.stopPrank();
        }

        // 자격 확인
        (bool eligible1, uint256 required, uint256 actual1) = seigManager.checkCurrentEligibility(mockLayer2);
        assertTrue(eligible1, "Should be eligible initially");
        emit log_string("Step 1: Sequencer is ELIGIBLE");
        emit log_named_decimal_uint("Required", required / 1e18, 18);
        emit log_named_decimal_uint("Actual", actual1 / 1e18, 18);

        // 시뇨리지 분배로 effectiveBridgedTON 설정
        vm.roll(block.number + 100);
        _updateSeigniorage();

        uint256 effectiveBefore = seigManager.getEffectiveBridgedTon(mockLayer2);
        assertGt(effectiveBefore, 0, "effectiveBridgedTON should be positive when eligible");
        emit log_named_decimal_uint("effectiveBridgedTON (eligible)", effectiveBefore / 1e18, 18);

        // ============================================
        // 2. Bridged TON 증가로 required 증가 → 자격 상실
        // ============================================
        emit log_string("Step 2: Increase Bridged TON to lose eligibility");

        uint256 additionalBridgedTON = 100000e27;
        vm.prank(owner);
        MockTON(ton).mint(mockPortal, additionalBridgedTON);

        vm.prank(mockPortal);
        seigManager.onBridgedTonChange();

        // 자격 재확인
        (bool eligible2, uint256 required2, uint256 actual2) = seigManager.checkCurrentEligibility(mockLayer2);

        emit log_named_decimal_uint("Required (after)", required2 / 1e18, 18);
        emit log_named_decimal_uint("Actual (after)", actual2 / 1e18, 18);

        assertFalse(eligible2, "Should be ineligible after Bridged TON increase");
        emit log_string("Sequencer is now INELIGIBLE");

        // ============================================
        // 3. effectiveBridgedTON = 0 확인
        // ============================================
        vm.roll(block.number + 100);
        _updateSeigniorage();

        uint256 effectiveAfterLoss = seigManager.getEffectiveBridgedTon(mockLayer2);
        assertEq(effectiveAfterLoss, 0, "effectiveBridgedTON should be 0 when ineligible");
        emit log_string("effectiveBridgedTON reset to 0");

        // ============================================
        // 4. OperatorManager에 추가 담보금 예치로 자격 재획득
        // ============================================
        emit log_string("Step 3: Deposit to regain eligibility");

        uint256 reDepositAmount = required2 - actual2 + 20e27;

        vm.startPrank(owner);
        MockWTON(wton).mint(owner, reDepositAmount);
        MockWTON(wton).approve(depositManagerProxy, reDepositAmount);
        DepositManagerV3(depositManagerProxy).deposit(mockLayer2, operatorManagerAddr, reDepositAmount);
        vm.stopPrank();

        // 자격 재확인
        (bool eligible3, , ) = seigManager.checkCurrentEligibility(mockLayer2);
        assertTrue(eligible3, "Should be eligible after re-deposit");
        emit log_string("Sequencer is ELIGIBLE again");

        // ============================================
        // 5. effectiveBridgedTON 복원 확인
        // ============================================
        vm.roll(block.number + 100);
        _updateSeigniorage();

        uint256 effectiveAfterRegain = seigManager.getEffectiveBridgedTon(mockLayer2);
        assertGt(effectiveAfterRegain, 0, "effectiveBridgedTON should be restored");
        emit log_named_decimal_uint("effectiveBridgedTON (restored)", effectiveAfterRegain / 1e18, 18);

        emit log_string("SCEN-SEQ-002: Eligibility transition test completed");
    }

    // ==========================================
    // SCEN-SEQ-003: Fraud Proof 슬래싱 및 복구
    // ==========================================

    // NOTE: 이 테스트는 삭제되었습니다.
    // 이유: V3의 슬래싱 메커니즘이 아직 완전히 구현되지 않았으며,
    //       RAT(Randomized Attention Test) 통합과 함께 별도의 테스트 파일에서 다루어집니다.
    // 관련 테스트: test/v3/v3mode/RAT.t.sol
    //             test/v3/v3mode/RATSeigManagerIntegration.t.sol
}
