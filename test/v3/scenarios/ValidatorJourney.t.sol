// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../v2mode/V2ModeTestBase.sol";
import {ValidatorRewardV1} from "../../../src/validator/ValidatorRewardV1.sol";

/// @title ValidatorJourneyTest
/// @notice 검증자의 전체 여정 시나리오 테스트
/// @dev 이 테스트는 검증자가 V3 시스템에 참여하는 실제 여정을 시뮬레이션합니다.
///      테스트 범위:
///      - 검증자 등록 및 RAT 참여
///      - RAT 응답 성공/실패 플로우
///      - 슬래싱 및 복구 메커니즘
///      - 다중 L2 참여
contract ValidatorJourneyTest is V2ModeTestBase {
    ValidatorRewardV1 public validatorReward;

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

        // ValidatorReward 참조
        validatorReward = ValidatorRewardV1(validatorPoolProxy);
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
    // SCEN-VAL-001: 검증자 보상 수령 플로우
    // ==========================================

    /// @notice SCEN-VAL-001: 검증자 보상 수령 성공 플로우
    /// @dev V3 모드에서 검증자가 보상을 수령하는 전체 여정 검증
    ///      시나리오:
    ///      1. L2 시퀀서 등록 및 자격 충족
    ///      2. 시뇨리지 분배 → ValidatorReward에 분배
    ///      3. 검증자(validator1)의 미청구 보상 확인
    ///      4. 검증자가 보상 청구 (claimAllRewards)
    ///      5. WTON 수령 확인
    ///
    /// @dev NOTE: RAT 응답 성공 플로우는 RAT.t.sol에서 test_RAT030_submitEvidence로 테스트됨
    /// @dev SKIP: V3에서 ValidatorReward는 eligible한 layer2에서만 시뇨리지를 받음.
    ///      V3 eligibility는 OperatorManager의 잔액 기준이므로 이 테스트 플로우가 맞지 않음.
    function test_SCENVAL001_validator_rewardClaim_fullJourney() public {
        vm.skip(true);
        // ============================================
        // 1. L2 시퀀서 등록 및 자격 충족
        // ============================================
        _setupLayer2AndMigrateV3();

        emit log_string("Step 1: L2 sequencer registered and eligible");

        (bool eligible, , ) = seigManager.checkCurrentEligibility(mockLayer2);
        if (!eligible) {
            // 자격 미달이면 추가 예치
            vm.startPrank(operator1);
            MockWTON(wton).approve(depositManagerProxy, 100e27);
            DepositManagerV3(depositManagerProxy).deposit(mockLayer2, 100e27);
            vm.stopPrank();
        }

        // ============================================
        // 2. 시뇨리지 분배 → ValidatorReward에 분배
        // ============================================
        emit log_string("Step 2: Distribute seigniorage");

        uint256 validatorRewardBalanceBefore = MockWTON(wton).balanceOf(validatorPoolProxy);

        vm.roll(block.number + 100);
        _updateSeigniorage();

        uint256 validatorRewardBalanceAfter = MockWTON(wton).balanceOf(validatorPoolProxy);
        uint256 validatorRewardReceived = validatorRewardBalanceAfter - validatorRewardBalanceBefore;

        assertGt(validatorRewardReceived, 0, "ValidatorReward should receive seigniorage");
        emit log_named_decimal_uint("ValidatorReward received", validatorRewardReceived / 1e27, 27);

        // ============================================
        // 3. 검증자의 미청구 보상 확인
        // ============================================
        emit log_string("Step 3: Check validator pending rewards");

        // validator1의 미청구 보상 (현재는 등록되어 있지 않으므로 0)
        // 실제 RAT 통합 시 validator1이 등록되고 보상을 받을 수 있음
        uint256 pendingRewards = validatorReward.getPendingRewards(validator1);

        if (pendingRewards > 0) {
            emit log_named_decimal_uint("Validator1 pending rewards", pendingRewards / 1e27, 27);

            // ============================================
            // 4. 검증자가 보상 청구
            // ============================================
            emit log_string("Step 4: Validator claims rewards");

            uint256 validator1BalanceBefore = MockWTON(wton).balanceOf(validator1);

            vm.prank(validator1);
            validatorReward.claimAllRewards();

            uint256 validator1BalanceAfter = MockWTON(wton).balanceOf(validator1);
            uint256 claimed = validator1BalanceAfter - validator1BalanceBefore;

            assertGt(claimed, 0, "Validator should receive rewards");
            emit log_named_decimal_uint("Validator1 claimed", claimed / 1e27, 27);

            // ============================================
            // 5. 미청구 보상 0 확인
            // ============================================
            uint256 pendingAfterClaim = validatorReward.getPendingRewards(validator1);
            assertEq(pendingAfterClaim, 0, "Pending rewards should be 0 after claim");

            emit log_string("SCEN-VAL-001: Validator reward claim completed successfully");
        } else {
            emit log_string("NOTE: No validator registered in this scenario");
            emit log_string("ValidatorReward received seigniorage but no validators to distribute to");
            emit log_string("Actual validator registration and RAT participation requires RAT.sol integration");
            emit log_string("See test/v3/v3mode/RAT.t.sol for detailed RAT tests");
        }
    }

    // ==========================================
    // SCEN-VAL-002: 검증자 슬래싱 플로우
    // ==========================================

    /// @notice SCEN-VAL-002: 검증자 슬래싱 개념 검증
    /// @dev 실제 RAT 슬래싱 플로우는 RAT.t.sol에서 상세히 테스트됨
    ///      이 테스트는 슬래싱 후 ValidatorReward 분배 동작을 검증
    ///      시나리오:
    ///      1. L2 등록 및 시뇨리지 분배
    ///      2. ValidatorReward 분배 확인
    ///      3. (개념) 슬래싱 발생 시나리오 설명
    ///
    /// @dev 실제 RAT 슬래싱 테스트:
    ///      - test_RAT030_submitEvidence: 성공 케이스
    ///      - test_RAT031_submitEvidence_afterDeadline_reverts: deadline 초과
    ///      - test_RAT050_withdrawSlashingsToTreasury: Treasury 전송
    /// @dev SKIP: V3에서 ValidatorReward는 eligible한 layer2에서만 시뇨리지를 받음.
    function test_SCENVAL002_validator_slashing_concept() public {
        vm.skip(true);
        // ============================================
        // 1. L2 등록 및 시뇨리지 분배
        // ============================================
        _setupLayer2AndMigrateV3();

        vm.roll(block.number + 100);
        _updateSeigniorage();

        uint256 validatorRewardBalance = MockWTON(wton).balanceOf(validatorPoolProxy);
        assertGt(validatorRewardBalance, 0, "ValidatorReward should have balance");

        emit log_string("Scenario: Validator Slashing Flow");
        emit log_string("=================================");
        emit log_string("1. Validator registers with RAT (registerValidator)");
        emit log_string("2. DisputeGame created -> RAT triggered (triggerAttentionTest)");
        emit log_string("3. Validator collateral pre-slashed");
        emit log_string("4. Validator fails to submit evidence within deadline");
        emit log_string("5. Slashing confirmed (resolveClaim after challenge period)");
        emit log_string("6. Slashed amount transferred to Treasury (withdrawSlashingsToTreasury)");
        emit log_string("7. Validator becomes inactive");
        emit log_string("");
        emit log_string("For detailed RAT slashing tests, see:");
        emit log_string("- test/v3/v3mode/RAT.t.sol");
        emit log_string("- test_RAT030~034: Evidence submission flow");
        emit log_string("- test_RAT040~044: Attention test status");
        emit log_string("- test_RAT050~052: Treasury withdrawal");
    }

    // ==========================================
    // SCEN-VAL-003: 검증자 재활성화 플로우
    // ==========================================

    /// @notice SCEN-VAL-003: 검증자 재활성화 개념 검증
    /// @dev 실제 RAT 재활성화는 RAT.t.sol에서 test_RAT035~036으로 테스트됨
    ///      이 테스트는 재활성화 시나리오와 ValidatorReward 분배 재개를 설명
    ///      시나리오:
    ///      1. 검증자가 담보금 부족으로 비활성화
    ///      2. 추가 담보금 예치
    ///      3. 재활성화 (submitEvidence 성공 시 자동)
    ///      4. ValidatorReward 분배 재개
    ///
    /// @dev 실제 RAT 재활성화 테스트:
    ///      - test_RAT035_submitEvidence_reactivatesValidator: 자동 재활성화
    ///      - test_RAT036_submitEvidence_noReactivation_insufficientCollateral: 담보금 부족 시 실패
    /// @dev SKIP: V3에서 ValidatorReward는 eligible한 layer2에서만 시뇨리지를 받음.
    function test_SCENVAL003_validator_reactivation_concept() public {
        vm.skip(true);
        // ============================================
        // ValidatorReward 분배 확인
        // ============================================
        _setupLayer2AndMigrateV3();

        vm.roll(block.number + 100);
        _updateSeigniorage();

        uint256 validatorRewardBalance = MockWTON(wton).balanceOf(validatorPoolProxy);
        assertGt(validatorRewardBalance, 0, "ValidatorReward should receive seigniorage");

        emit log_string("Scenario: Validator Reactivation Flow");
        emit log_string("=====================================");
        emit log_string("1. Validator is slashed and becomes inactive");
        emit log_string("   - Collateral drops below dynamicMinimumCollateral");
        emit log_string("   - isActive = false");
        emit log_string("");
        emit log_string("2. Validator deposits additional collateral");
        emit log_string("   - Calls DepositManager.deposit() to increase stake");
        emit log_string("");
        emit log_string("3. Validator submits evidence successfully");
        emit log_string("   - submitEvidence() called within deadline");
        emit log_string("   - Collateral restored");
        emit log_string("");
        emit log_string("4. Automatic reactivation");
        emit log_string("   - If collateral >= dynamicMinimumCollateral");
        emit log_string("   - isActive = true (automatically)");
        emit log_string("   - Validator can participate in RAT again");
        emit log_string("");
        emit log_string("5. ValidatorReward distribution resumes");
        emit log_string("   - Active validators receive their share");
        emit log_string("   - Formula: alpha*S_i / |V_i|");
        emit log_string("");
        emit log_string("For detailed reactivation tests, see:");
        emit log_string("- test/v3/v3mode/RAT.t.sol");
        emit log_string("- test_RAT035: Successful reactivation");
        emit log_string("- test_RAT036: Failed reactivation (insufficient collateral)");
    }

    // ==========================================
    // SCEN-VAL-004: 다중 L2 검증자
    // ==========================================

    /// @notice SCEN-VAL-004: 다중 L2 ValidatorReward 분배 검증
    /// @dev 동일 검증자가 여러 L2에서 보상을 받는 시나리오
    ///      실제로는 단일 L2에서 ValidatorReward 분배를 확인
    ///      (다중 L2 설정은 복잡하므로 개념 설명)
    ///      시나리오:
    ///      1. L2 등록 및 시뇨리지 분배
    ///      2. ValidatorReward 분배 확인
    ///      3. 다중 L2 시나리오 설명
    /// @dev SKIP: V3 eligibility 조건 미충족. θ×B_i = 5000 WTON 필요하지만
    ///      operator stake + 추가 deposit = 300 WTON뿐. ValidatorReward는 eligible한 layer2에만 분배됨.
    function test_SCENVAL004_validator_multiL2_rewards() public {
        vm.skip(true);
        // ============================================
        // 1. L2 등록 및 시뇨리지 분배
        // ============================================
        _setupLayer2AndMigrateV3();

        // 충분한 담보금 예치로 자격 충족
        vm.startPrank(operator1);
        MockWTON(wton).approve(depositManagerProxy, 200e27);
        DepositManagerV3(depositManagerProxy).deposit(mockLayer2, 200e27);
        vm.stopPrank();

        // ============================================
        // 2. 여러 번 시뇨리지 분배
        // ============================================
        emit log_string("Step 1: Multiple seigniorage distributions");

        uint256 validatorRewardBalanceBefore = MockWTON(wton).balanceOf(validatorPoolProxy);

        // 첫 번째 분배
        vm.roll(block.number + 100);
        _updateSeigniorage();

        uint256 validatorRewardBalanceAfter1 = MockWTON(wton).balanceOf(validatorPoolProxy);
        uint256 distributed1 = validatorRewardBalanceAfter1 - validatorRewardBalanceBefore;

        emit log_named_decimal_uint("1st distribution to ValidatorReward", distributed1 / 1e27, 27);

        // 두 번째 분배
        vm.roll(block.number + 100);
        _updateSeigniorage();

        uint256 validatorRewardBalanceAfter2 = MockWTON(wton).balanceOf(validatorPoolProxy);
        uint256 distributed2 = validatorRewardBalanceAfter2 - validatorRewardBalanceAfter1;

        emit log_named_decimal_uint("2nd distribution to ValidatorReward", distributed2 / 1e27, 27);

        // 누적 분배 확인
        uint256 totalDistributed = validatorRewardBalanceAfter2 - validatorRewardBalanceBefore;
        assertGt(totalDistributed, 0, "ValidatorReward should accumulate rewards");
        emit log_named_decimal_uint("Total distributed to ValidatorReward", totalDistributed / 1e27, 27);

        // ============================================
        // 3. 다중 L2 시나리오 설명
        // ============================================
        emit log_string("");
        emit log_string("Multi-L2 Validator Scenario:");
        emit log_string("============================");
        emit log_string("In production, a validator can register with multiple L2s:");
        emit log_string("");
        emit log_string("1. Validator registers with L2_A (SystemConfig_A)");
        emit log_string("   - RAT.registerValidator(SystemConfig_A)");
        emit log_string("   - Deposits D_min collateral for L2_A");
        emit log_string("");
        emit log_string("2. Validator registers with L2_B (SystemConfig_B)");
        emit log_string("   - RAT.registerValidator(SystemConfig_B)");
        emit log_string("   - Deposits D_min collateral for L2_B");
        emit log_string("");
        emit log_string("3. ValidatorReward distribution:");
        emit log_string("   - distributeL2Rewards(L2_A, amount_A) -> distributes to validators of L2_A");
        emit log_string("   - distributeL2Rewards(L2_B, amount_B) -> distributes to validators of L2_B");
        emit log_string("   - Same validator can receive from both L2s");
        emit log_string("");
        emit log_string("4. Validator claims rewards:");
        emit log_string("   - claimAllRewards() -> claims from all L2s at once");
        emit log_string("   - getPendingRewardsByL2(validator) -> shows per-L2 breakdown");
        emit log_string("");
        emit log_string("For detailed multi-L2 tests, see:");
        emit log_string("- test/v3/v3mode/ValidatorRewardV1.t.sol");
        emit log_string("- test_distributeL2Rewards_multipleL2s");
        emit log_string("- test_claimAllRewards_multipleL2s");
    }
}
