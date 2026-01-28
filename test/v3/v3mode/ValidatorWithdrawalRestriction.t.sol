// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../helpers/V3TestBase.sol";
import {ValidatorMinCollateralError} from "../../../src/stake/managers/SeigManagerV3_1.sol";

/// @title ValidatorWithdrawalRestrictionTest
/// @notice 검증자 출금 제한 테스트 (INT-013)
/// @dev 테스트 계획서 INT-013: 검증자 출금 제한 D_min 이상 유지 검증
///
/// 테스트 대상:
/// - INT-013: 검증자가 D_min(동적 최소 담보금) 이상 유지해야 출금 가능
/// - 검증자가 활성 상태일 때 출금 시 최소 담보금 체크
/// - 비활성 검증자는 제한 없이 출금 가능
contract ValidatorWithdrawalRestrictionTest is V3TestBase {
    // ==========================================
    // Additional Test Addresses
    // ==========================================
    address public validator1 = address(0x6001);
    address public validator2 = address(0x6002);
    address public user1 = address(0x7001);

    function setUp() public {
        _v3TestSetup();

        vm.startPrank(owner);

        // RAT 파라미터: D_min = C_off + validatorBuffer = 100 + 100 = 200 WTON
        rat.setSlashingPenalty(100 * RAY);
        rat.setValidatorBuffer(100 * RAY);
        rat.setMinimumThreshold(200 * RAY);
        rat.setRatTriggerProbability(RAY);

        // L2 등록
        _registerFirstL2(1000 * RAY);

        // V3 마이그레이션
        seigManager.setRatContract(address(rat));
        seigManager.setDaoDistributionRatio(0.1e27);
        seigManager.setMinStakingRatio(0.1e27);
        seigManager.setValidatorDistributionRatio(0.2e27);
        seigManager.setHalfSaturationPoint(1000e27);
        seigManager.setMaxChallengers(3);
        seigManager.setMaxFraudProofCost(50e27);
        seigManager.setValidatorReward(validatorPoolProxy);
        seigManager.migrateToV3();

        MockTON(ton).mint(validator1, INITIAL_TON);
        MockTON(ton).mint(validator2, INITIAL_TON);
        MockTON(ton).mint(user1, INITIAL_TON);

        vm.stopPrank();
    }

    // ==========================================
    // INT-013: 검증자 출금 제한 테스트
    // ==========================================

    /// @notice INT-013: 활성 검증자가 D_min 이상 유지 시 출금 성공
    function test_INT013_validatorWithdrawal_aboveMinimum_success() public {
        // D_min = 200 WTON
        uint256 depositAmount = 500 * RAY;
        _registerValidator(validator1, depositAmount);

        uint256 dMin = rat.getDynamicMinimumCollateral(address(mockSystemConfig));
        assertEq(dMin, 200 * RAY, "D_min should be 200 WTON");

        // 출금 후에도 D_min 이상 유지되는 금액 출금
        uint256 withdrawAmount = 200 * RAY; // 500 - 200 = 300 >= D_min(200)

        vm.startPrank(validator1);
        depositManager.requestWithdrawal(mockLayer2, withdrawAmount);
        vm.stopPrank();

        // 출금 요청 성공 확인
        uint256 balanceAfter = _getCoinageBalance(mockLayer2, validator1);
        assertEq(balanceAfter, depositAmount - withdrawAmount, "Withdrawal request should succeed");
    }

    /// @notice INT-013: 활성 검증자가 D_min 미만으로 출금 시 revert
    /// @dev SeigManager.onWithdraw에서 ValidatorMinCollateralError 발생
    function test_INT013_validatorWithdrawal_belowMinimum_reverts() public {
        // D_min = 200 WTON (slashingPenalty=100 + validatorBuffer=100)
        uint256 depositAmount = 300 * RAY;
        _registerValidator(validator1, depositAmount);

        // D_min 확인
        uint256 dMin = rat.getDynamicMinimumCollateral(address(mockSystemConfig));
        assertEq(dMin, 200 * RAY, "D_min should be 200 WTON");

        // 현재 잔액 확인
        uint256 currentBalance = _getCoinageBalance(mockLayer2, validator1);
        assertEq(currentBalance, depositAmount, "Balance should be 300 WTON");

        // 출금 후 D_min 미만이 되는 금액 출금 시도
        // 300 - 150 = 150 < D_min(200) → revert
        uint256 withdrawAmount = 150 * RAY;

        vm.startPrank(validator1);
        vm.expectRevert(ValidatorMinCollateralError.selector);
        depositManager.requestWithdrawal(mockLayer2, withdrawAmount);
        vm.stopPrank();

        // 잔액 변화 없음 확인
        assertEq(_getCoinageBalance(mockLayer2, validator1), depositAmount, "Balance should not change");
    }

    /// @notice INT-013: 활성 검증자가 정확히 D_min까지 출금 시 성공
    function test_INT013_validatorWithdrawal_exactMinimum_success() public {
        // D_min = 200 WTON
        uint256 depositAmount = 500 * RAY;
        _registerValidator(validator1, depositAmount);

        // 출금 후 정확히 D_min 유지
        // 500 - 300 = 200 = D_min → 성공
        uint256 withdrawAmount = 300 * RAY;

        vm.startPrank(validator1);
        depositManager.requestWithdrawal(mockLayer2, withdrawAmount);
        vm.stopPrank();

        uint256 balanceAfter = _getCoinageBalance(mockLayer2, validator1);
        assertEq(balanceAfter, 200 * RAY, "Balance should be exactly D_min");
    }

    /// @notice INT-013: 비활성 검증자는 제한 없이 출금 가능
    function test_INT013_inactiveValidator_noRestriction() public {
        uint256 depositAmount = 300 * RAY;
        _registerValidator(validator1, depositAmount);

        // 검증자 탈퇴
        vm.prank(validator1);
        rat.deactivateValidator(address(mockSystemConfig));

        // 비활성 상태 확인
        (, , bool isActive) = rat.getValidatorRegistration(validator1, address(mockSystemConfig));
        assertFalse(isActive, "Validator should be inactive");

        // 비활성 검증자는 전액 출금 가능
        vm.startPrank(validator1);
        depositManager.requestWithdrawal(mockLayer2, depositAmount);
        vm.stopPrank();

        uint256 balanceAfter = _getCoinageBalance(mockLayer2, validator1);
        assertEq(balanceAfter, 0, "Inactive validator can withdraw all");
    }

    /// @notice INT-013: 일반 스테이커(비검증자)는 제한 없이 출금 가능
    function test_INT013_nonValidator_noRestriction() public {
        uint256 depositAmount = 100 * RAY; // D_min 미만

        _depositOnly(user1, depositAmount);

        // 일반 스테이커는 전액 출금 가능
        vm.startPrank(user1);
        depositManager.requestWithdrawal(mockLayer2, depositAmount);
        vm.stopPrank();

        uint256 balanceAfter = _getCoinageBalance(mockLayer2, user1);
        assertEq(balanceAfter, 0, "Non-validator can withdraw all");
    }

    /// @notice INT-013: 동적 D_min 변경 시 출금 제한 업데이트
    function test_INT013_dynamicMinimum_changesWithValidatorCount() public {
        // 검증자 1명 등록
        uint256 depositAmount = 500 * RAY;
        _registerValidator(validator1, depositAmount);

        // attentionCost를 설정하면 동적으로 변함
        vm.prank(owner);
        rat.setAttentionCost(50 * RAY);

        _registerValidator(validator2, depositAmount);

        uint256 dMinWith2 = rat.getDynamicMinimumCollateral(address(mockSystemConfig));

        // attentionCost > 0이면 C_off = max(slashingPenalty, (c_m × N) / π_a)
        // c_m = 50, N = 2, π_a = 1 → (50 × 2 × 1e27) / 1e27 = 100
        // max(100, 100) = 100
        // D_min = 100 + 100 = 200
        assertEq(dMinWith2, 200 * RAY, "D_min with 2 validators");
    }

    /// @notice INT-013: 부분 출금 후 남은 잔액이 D_min 이상이면 여전히 활성
    function test_INT013_partialWithdrawal_remainsActive() public {
        uint256 depositAmount = 500 * RAY;
        _registerValidator(validator1, depositAmount);

        // 부분 출금 (D_min 이상 유지)
        uint256 withdrawAmount = 100 * RAY;

        vm.startPrank(validator1);
        depositManager.requestWithdrawal(mockLayer2, withdrawAmount);
        vm.stopPrank();

        // 검증자 여전히 활성 상태
        (, , bool isActive) = rat.getValidatorRegistration(validator1, address(mockSystemConfig));
        assertTrue(isActive, "Validator should remain active after partial withdrawal");
    }

    /// @notice INT-013: RAT 선차감 후 출금 시도
    function test_INT013_withdrawAfterRATDeduction() public {
        uint256 depositAmount = 400 * RAY;
        _registerValidator(validator1, depositAmount);

        // RAT 트리거 (100 WTON 선차감)
        vm.prank(mockDisputeGameFactory);
        rat.triggerAttentionTest(
            address(0x1234),
            address(mockSystemConfig),
            1,
            keccak256("batch1"),
            keccak256("block1")
        );

        // 선차감 후 잔액: 400 - 100 = 300 WTON
        uint256 balanceAfterDeduction = _getCoinageBalance(mockLayer2, validator1);
        assertEq(balanceAfterDeduction, 300 * RAY, "Balance after RAT deduction");

        // D_min = 200 WTON, 현재 잔액 = 300 WTON
        // 100 WTON 출금 시도 → 300 - 100 = 200 >= D_min → 성공
        vm.startPrank(validator1);
        depositManager.requestWithdrawal(mockLayer2, 100 * RAY);
        vm.stopPrank();

        assertEq(_getCoinageBalance(mockLayer2, validator1), 200 * RAY, "Withdrawal should succeed");
    }

    /// @notice INT-013: RAT 선차감 후 D_min 미만 출금 시도 → revert
    /// @dev SeigManager.onWithdraw에서 ValidatorMinCollateralError 발생
    function test_INT013_withdrawBelowMinAfterRATDeduction_reverts() public {
        uint256 depositAmount = 350 * RAY;
        _registerValidator(validator1, depositAmount);

        // D_min 확인
        uint256 dMin = rat.getDynamicMinimumCollateral(address(mockSystemConfig));
        assertEq(dMin, 200 * RAY, "D_min should be 200 WTON");

        // RAT 트리거 (slashingPenalty=100 WTON 선차감)
        vm.prank(mockDisputeGameFactory);
        rat.triggerAttentionTest(
            address(0x1234),
            address(mockSystemConfig),
            1,
            keccak256("batch1"),
            keccak256("block1")
        );

        // 선차감 후 잔액 확인: 350 - 100 = 250 WTON
        uint256 balanceAfterDeduction = _getCoinageBalance(mockLayer2, validator1);
        assertEq(balanceAfterDeduction, 250 * RAY, "Balance after RAT deduction should be 250 WTON");

        // D_min = 200 WTON
        // 100 WTON 출금 시도 → 250 - 100 = 150 < D_min(200) → revert
        vm.startPrank(validator1);
        vm.expectRevert(ValidatorMinCollateralError.selector);
        depositManager.requestWithdrawal(mockLayer2, 100 * RAY);
        vm.stopPrank();

        // 잔액 변화 없음 확인
        assertEq(_getCoinageBalance(mockLayer2, validator1), balanceAfterDeduction, "Balance should not change");
    }

    // ==========================================
    // 추가: getValidatorMinCollateralForLayer2 테스트
    // ==========================================

    /// @notice INT-014: getValidatorMinCollateralForLayer2 - 활성 검증자 → D_min 반환
    function test_INT014_getValidatorMinCollateralForLayer2_activeValidator() public {
        uint256 depositAmount = 500 * RAY;
        _registerValidator(validator1, depositAmount);

        uint256 minCollateral = rat.getValidatorMinCollateralForLayer2(mockLayer2, validator1);
        uint256 expectedDmin = rat.getDynamicMinimumCollateral(address(mockSystemConfig));

        assertEq(minCollateral, expectedDmin, "Should return D_min for active validator");
    }

    /// @notice INT-014: getValidatorMinCollateralForLayer2 - 비활성 검증자 → 0 반환
    function test_INT014_getValidatorMinCollateralForLayer2_inactiveValidator() public {
        uint256 depositAmount = 500 * RAY;
        _registerValidator(validator1, depositAmount);

        // 검증자 탈퇴
        vm.prank(validator1);
        rat.deactivateValidator(address(mockSystemConfig));

        uint256 minCollateral = rat.getValidatorMinCollateralForLayer2(mockLayer2, validator1);
        assertEq(minCollateral, 0, "Should return 0 for inactive validator");
    }

    /// @notice INT-014: getValidatorMinCollateralForLayer2 - 비검증자 → 0 반환
    function test_INT014_getValidatorMinCollateralForLayer2_nonValidator() public {
        _depositOnly(user1, 500 * RAY);

        uint256 minCollateral = rat.getValidatorMinCollateralForLayer2(mockLayer2, user1);
        assertEq(minCollateral, 0, "Should return 0 for non-validator");
    }
}
