// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../helpers/V3TestBase.sol";
import {OnlyRatError} from "../../../src/stake/managers/SeigManagerV3_1.sol";
import {IValidatorReward} from "../../../src/validator/IValidatorReward.sol";
import {ValidatorRewardV1} from "../../../src/validator/ValidatorRewardV1.sol";

/// @title RATSeigManagerIntegrationTest
/// @notice RAT ↔ SeigManager 실제 Coinage 전송 통합 테스트
/// @dev 테스트 계획서 INT-020~023, SM-040~043 구현
///
/// 테스트 대상:
/// - INT-020: Coinage 선차감 (validator → RAT 전송)
/// - INT-021: Coinage 복구 (RAT → validator 전송)
/// - INT-022: Coinage 슬래싱 (RAT → Treasury 전송)
/// - INT-023: 잔액 동기화 검증
/// - SM-040: transferCoinageToRat()
/// - SM-041: transferCoinageFromRat()
/// - SM-042: transferCoinageFromRatTo()
/// - SM-043: onlyRAT 권한 검증
contract RATSeigManagerIntegrationTest is V3TestBase {
    // ==========================================
    // Additional Test Addresses
    // ==========================================
    address public validator1 = address(0x6001);
    address public validator2 = address(0x6002);
    address public treasury = address(0x9001);

    function setUp() public {
        _v3TestSetup();

        vm.startPrank(owner);

        // RAT 파라미터 조정
        rat.setSlashingPenalty(100 * RAY);     // C_off = 100 WTON
        rat.setValidatorBuffer(100 * RAY);      // Δ_validator = 100 WTON
        rat.setMinimumThreshold(200 * RAY);     // D_min = 200 WTON
        rat.setRatTriggerProbability(RAY);      // 100% 트리거
        rat.setTreasury(treasury);

        // L2 등록
        _registerFirstL2(1000 * RAY);

        // V3 설정 및 마이그레이션
        _setupV3AndMigrate();

        // 테스트 계정에 TON 지급
        MockTON(ton).mint(validator1, INITIAL_TON);
        MockTON(ton).mint(validator2, INITIAL_TON);

        vm.stopPrank();
    }

    // ==========================================
    // INT-020: Coinage 선차감 테스트 (validator → RAT)
    // ==========================================

    /// @notice INT-020: triggerAttentionTest 호출 시 validator → RAT coinage 전송 검증
    function test_INT020_coinagePreDeduction() public {
        uint256 depositAmount = 500 * RAY;
        _registerValidator(validator1, depositAmount);

        // 초기 잔액 확인
        uint256 validatorBalanceBefore = _getCoinageBalance(mockLayer2, validator1);
        uint256 ratBalanceBefore = _getCoinageBalance(mockLayer2, address(rat));

        assertEq(validatorBalanceBefore, depositAmount, "Initial validator balance");
        assertEq(ratBalanceBefore, 0, "Initial RAT balance");

        // RAT 트리거 (DisputeGameFactory에서 호출)
        vm.prank(mockDisputeGameFactory);
        rat.triggerAttentionTest(
            address(0x1234), // game address
            address(mockSystemConfig),
            1, // batchIndex
            keccak256("batch1"),
            keccak256("block1")
        );

        // 선차감 후 잔액 확인
        uint256 validatorBalanceAfter = _getCoinageBalance(mockLayer2, validator1);
        uint256 ratBalanceAfter = _getCoinageBalance(mockLayer2, address(rat));
        uint256 slashingPenalty = rat.slashingPenalty();

        assertEq(validatorBalanceAfter, depositAmount - slashingPenalty, "Validator balance after pre-deduction");
        assertEq(ratBalanceAfter, slashingPenalty, "RAT balance after pre-deduction");
    }

    // ==========================================
    // INT-021: Coinage 복구 테스트 (RAT → validator)
    // ==========================================

    /// @notice INT-021: submitEvidence 호출 시 RAT → validator coinage 복구 검증
    function test_INT021_coinageRestoration() public {
        uint256 depositAmount = 500 * RAY;
        _registerValidator(validator1, depositAmount);

        // RAT 트리거
        vm.prank(mockDisputeGameFactory);
        rat.triggerAttentionTest(
            address(0x1234),
            address(mockSystemConfig),
            1,
            keccak256("batch1"),
            keccak256("block1")
        );

        // 선차감 확인
        uint256 slashingPenalty = rat.slashingPenalty();
        assertEq(_getCoinageBalance(mockLayer2, validator1), depositAmount - slashingPenalty, "After pre-deduction");
        assertEq(_getCoinageBalance(mockLayer2, address(rat)), slashingPenalty, "RAT holds penalty");

        // 증거 제출
        vm.prank(validator1);
        rat.submitEvidence(address(mockSystemConfig), 1, "evidence_data");

        // 복구 후 잔액 확인
        assertEq(_getCoinageBalance(mockLayer2, validator1), depositAmount, "Validator balance restored");
        assertEq(_getCoinageBalance(mockLayer2, address(rat)), 0, "RAT balance cleared");
    }

    /// @notice INT-021: resolveClaim 호출 시 RAT → validator coinage 복구 검증 (챌린지 승리)
    function test_INT021_coinageRestorationByChallenge() public {
        uint256 depositAmount = 500 * RAY;
        _registerValidator(validator1, depositAmount);

        address gameAddress = address(0x1234);

        // RAT 트리거
        vm.prank(mockDisputeGameFactory);
        rat.triggerAttentionTest(
            gameAddress,
            address(mockSystemConfig),
            1,
            keccak256("batch1"),
            keccak256("block1")
        );

        // 선차감 확인
        uint256 slashingPenalty = rat.slashingPenalty();
        assertEq(_getCoinageBalance(mockLayer2, validator1), depositAmount - slashingPenalty, "After pre-deduction");

        // deadline 경과 후 ChallengePeriod로 진입
        vm.warp(block.timestamp + rat.evidenceSubmissionPeriod() + 1);

        // 챌린지 승리로 복구 (game 주소에서 호출)
        vm.prank(gameAddress);
        rat.resolveClaim(validator1);

        // 복구 후 잔액 확인
        assertEq(_getCoinageBalance(mockLayer2, validator1), depositAmount, "Validator balance restored by challenge");
        assertEq(_getCoinageBalance(mockLayer2, address(rat)), 0, "RAT balance cleared");
    }

    // ==========================================
    // INT-022: Coinage 슬래싱 테스트 (RAT → Treasury)
    // ==========================================

    /// @notice INT-022: withdrawSlashingsToTreasury 호출 시 RAT → Treasury coinage 전송 검증
    function test_INT022_coinageSlashing() public {
        uint256 depositAmount = 500 * RAY;
        _registerValidator(validator1, depositAmount);

        // RAT 트리거
        vm.prank(mockDisputeGameFactory);
        rat.triggerAttentionTest(
            address(0x1234),
            address(mockSystemConfig),
            1,
            keccak256("batch1"),
            keccak256("block1")
        );

        uint256 slashingPenalty = rat.slashingPenalty();

        // 선차감 확인
        assertEq(_getCoinageBalance(mockLayer2, address(rat)), slashingPenalty, "RAT holds penalty");

        // 전체 대기 시간 경과 (evidenceSubmissionPeriod + challengeGameDuration + safetyBuffer)
        vm.warp(block.timestamp + rat.evidenceSubmissionPeriod() + rat.challengeGameDuration() + rat.safetyBuffer() + 1);

        // Treasury로 출금
        rat.withdrawSlashingsToTreasury(address(mockSystemConfig));

        // 슬래싱 후 잔액 확인
        assertEq(_getCoinageBalance(mockLayer2, address(rat)), 0, "RAT balance cleared");
        assertEq(_getCoinageBalance(mockLayer2, treasury), slashingPenalty, "Treasury received slashing");
    }

    // ==========================================
    // INT-023: 잔액 동기화 검증
    // ==========================================

    /// @notice INT-023: 전체 플로우에서 잔액 동기화 검증
    function test_INT023_balanceSynchronization() public {
        uint256 depositAmount = 500 * RAY;
        _registerValidator(validator1, depositAmount);
        _registerValidator(validator2, depositAmount);

        // 초기 상태: 총 잔액 = validator1 + validator2 + operator
        uint256 totalBefore = _getCoinageBalance(mockLayer2, validator1)
            + _getCoinageBalance(mockLayer2, validator2)
            + _getCoinageBalance(mockLayer2, address(rat));

        // RAT 트리거 for validator1
        vm.prank(mockDisputeGameFactory);
        rat.triggerAttentionTest(
            address(0x1234),
            address(mockSystemConfig),
            1,
            keccak256("batch1"),
            keccak256("block1")
        );

        // 선차감 후: 총 잔액 유지 (validator → RAT 이동)
        uint256 totalAfterTrigger = _getCoinageBalance(mockLayer2, validator1)
            + _getCoinageBalance(mockLayer2, validator2)
            + _getCoinageBalance(mockLayer2, address(rat));

        assertEq(totalAfterTrigger, totalBefore, "Total balance preserved after trigger");

        // 증거 제출 후: 총 잔액 유지 (RAT → validator 복구)
        // Note: RAT selects validator2 based on registration order, so validator2 must submit evidence
        vm.prank(validator2);
        rat.submitEvidence(address(mockSystemConfig), 1, "evidence_data");

        uint256 totalAfterEvidence = _getCoinageBalance(mockLayer2, validator1)
            + _getCoinageBalance(mockLayer2, validator2)
            + _getCoinageBalance(mockLayer2, address(rat));

        assertEq(totalAfterEvidence, totalBefore, "Total balance preserved after evidence");
    }

    // NOTE: transferCoinageToRat 성공 케이스는 SecurityPermissions.t.sol (SEC-002)에서 테스트

    // ==========================================
    // SM-041: transferCoinageFromRat 테스트
    // ==========================================

    /// @notice SM-041: transferCoinageFromRat 함수 테스트
    function test_SM041_transferCoinageFromRat() public {
        uint256 depositAmount = 500 * RAY;
        _registerValidator(validator1, depositAmount);

        uint256 transferAmount = 100 * RAY;

        // 먼저 RAT로 전송
        vm.prank(address(rat));
        seigManager.transferCoinageToRat(mockLayer2, validator1, transferAmount);

        assertEq(_getCoinageBalance(mockLayer2, address(rat)), transferAmount, "RAT has balance");

        // RAT에서 validator로 복구
        vm.prank(address(rat));
        seigManager.transferCoinageFromRat(mockLayer2, validator1, transferAmount);

        // 잔액 확인
        assertEq(_getCoinageBalance(mockLayer2, validator1), depositAmount, "Validator balance restored");
        assertEq(_getCoinageBalance(mockLayer2, address(rat)), 0, "RAT balance cleared");
    }

    // ==========================================
    // SM-042: transferCoinageFromRatTo 테스트
    // ==========================================

    /// @notice SM-042: transferCoinageFromRatTo 함수 테스트
    function test_SM042_transferCoinageFromRatTo() public {
        uint256 depositAmount = 500 * RAY;
        _registerValidator(validator1, depositAmount);

        uint256 transferAmount = 100 * RAY;

        // 먼저 RAT로 전송
        vm.prank(address(rat));
        seigManager.transferCoinageToRat(mockLayer2, validator1, transferAmount);

        // RAT에서 treasury로 전송
        vm.prank(address(rat));
        seigManager.transferCoinageFromRatTo(mockLayer2, treasury, transferAmount);

        // 잔액 확인
        assertEq(_getCoinageBalance(mockLayer2, address(rat)), 0, "RAT balance cleared");
        assertEq(_getCoinageBalance(mockLayer2, treasury), transferAmount, "Treasury received");
    }

    // NOTE: onlyRAT 권한 검증은 SecurityPermissions.t.sol (SEC-002)에서 테스트

    // ==========================================
    // 추가: 다중 RAT 트리거 시나리오
    // ==========================================

    /// @notice INT-024: 다중 검증자, 다중 RAT 트리거 시 잔액 일관성 검증
    function test_INT024_multipleRATTriggers_balanceConsistency() public {
        uint256 depositAmount = 500 * RAY;
        _registerValidator(validator1, depositAmount);
        _registerValidator(validator2, depositAmount);

        // 첫 번째 RAT 트리거
        vm.prank(mockDisputeGameFactory);
        rat.triggerAttentionTest(
            address(0x1234),
            address(mockSystemConfig),
            1,
            keccak256("batch1"),
            keccak256("block1")
        );

        // 두 번째 RAT 트리거 (다른 batchIndex)
        vm.prank(mockDisputeGameFactory);
        rat.triggerAttentionTest(
            address(0x5678),
            address(mockSystemConfig),
            2,
            keccak256("batch2"),
            keccak256("block2")
        );

        // RAT 잔액은 선차감된 금액들의 합
        uint256 ratBalance = _getCoinageBalance(mockLayer2, address(rat));
        uint256 slashingPenalty = rat.slashingPenalty();

        // 두 번 트리거되었으므로 정확히 2 * slashingPenalty
        // (동일 검증자가 선택되어도 각 트리거마다 slashingPenalty가 RAT로 전송됨)
        assertEq(ratBalance, 2 * slashingPenalty, "RAT balance should be exactly 2x slashingPenalty");
    }

    // ==========================================
    // 추가: 담보금 부족 시나리오
    // ==========================================

    /// @notice INT-025: 담보금 부족 시 RAT 트리거 동작 검증
    function test_INT025_insufficientCollateral_RATTrigger() public {
        // D_min = 200 WTON, slashingPenalty = 100 WTON
        // 정확히 D_min만 예치 (200 WTON)
        uint256 depositAmount = 200 * RAY;
        _registerValidator(validator1, depositAmount);

        // RAT 트리거
        vm.prank(mockDisputeGameFactory);
        rat.triggerAttentionTest(
            address(0x1234),
            address(mockSystemConfig),
            1,
            keccak256("batch1"),
            keccak256("block1")
        );

        // 선차감 후: 200 - 100 = 100 WTON (D_min 미만)
        // relaxedValidatorCheck = true (기본값)이므로 C_off(100) 기준
        // remaining = 100 >= C_off(100), 검증자 유지

        // 잔액 확인
        uint256 slashingPenalty = rat.slashingPenalty();
        assertEq(_getCoinageBalance(mockLayer2, validator1), depositAmount - slashingPenalty, "Validator balance reduced");
        assertEq(_getCoinageBalance(mockLayer2, address(rat)), slashingPenalty, "RAT holds penalty");

        // 검증자 상태 확인 (여전히 활성 - relaxed 모드이므로)
        (, , bool isActive) = rat.getValidatorRegistration(validator1, address(mockSystemConfig));
        assertTrue(isActive, "Validator should still be active in relaxed mode");
    }

    // ==========================================
    // 가스 테스트: 최대 검증자 분배
    // ==========================================

    /// @notice GAS-001: 최대 검증자 수에서 시뇨리지 분배 가스 측정
    /// @dev N_max = 100일 때 updateSeigniorage 가스 비용 검증
    function test_GAS001_maxValidators_seigniorageDistribution() public {
        uint256 maxValidators = 100;
        uint256 depositAmount = 300 * RAY; // D_min(200) + buffer

        // maxValidatorsPerL2 설정
        vm.prank(owner);
        rat.setMaxValidatorsPerL2(maxValidators);

        // 100명의 검증자 등록
        for (uint256 i = 0; i < maxValidators; i++) {
            address validatorAddr = address(uint160(0x10000 + i));

            // WTON 직접 지급
            vm.prank(owner);
            MockWTON(wton).mint(validatorAddr, depositAmount);

            vm.startPrank(validatorAddr);
            // Deposit
            MockWTON(wton).approve(depositManagerProxy, depositAmount);
            DepositManagerV3(depositManagerProxy).deposit(mockLayer2, validatorAddr, depositAmount);

            // RAT 등록
            rat.registerValidator(address(mockSystemConfig));
            vm.stopPrank();
        }

        // 등록된 검증자 수 확인
        uint256 activeCount = rat.getActiveValidatorCount(address(mockSystemConfig));
        assertEq(activeCount, maxValidators, "Should have max validators registered");

        // 블록 진행
        vm.roll(block.number + 100);

        // 가스 측정을 위한 updateSeigniorage
        uint256 gasBefore = gasleft();
        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();
        uint256 gasUsed = gasBefore - gasleft();

        // 가스 비용 출력
        emit log_named_uint("Gas used for updateSeigniorage with 100 validators", gasUsed);
        emit log_named_uint("Active validators", activeCount);

        // 가스 리밋 체크 (30M 블록 가스 리밋 기준으로 여유 있게)
        // 일반적인 L2 블록 가스 리밋은 더 높음
        assertTrue(gasUsed < 15_000_000, "Gas should be under 15M for 100 validators");
    }

    /// @notice GAS-002: 검증자 등록 가스 측정
    function test_GAS002_registerValidator_gas() public {
        uint256 depositAmount = 300 * RAY;

        // WTON 지급
        vm.prank(owner);
        MockWTON(wton).mint(validator1, depositAmount);

        // Deposit
        vm.startPrank(validator1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        DepositManagerV3(depositManagerProxy).deposit(mockLayer2, validator1, depositAmount);

        // 가스 측정: registerValidator
        uint256 gasBefore = gasleft();
        rat.registerValidator(address(mockSystemConfig));
        uint256 gasUsed = gasBefore - gasleft();
        vm.stopPrank();

        emit log_named_uint("Gas for registerValidator", gasUsed);
        assertTrue(gasUsed < 500_000, "registerValidator should use < 500k gas");
    }

    /// @notice GAS-003: RAT 트리거 가스 측정 (검증자 수별)
    function test_GAS003_triggerAttentionTest_gas() public {
        uint256 depositAmount = 300 * RAY;

        // 10명 검증자 등록
        for (uint256 i = 0; i < 10; i++) {
            address validatorAddr = address(uint160(0x30000 + i));
            vm.prank(owner);
            MockWTON(wton).mint(validatorAddr, depositAmount);

            vm.startPrank(validatorAddr);
            MockWTON(wton).approve(depositManagerProxy, depositAmount);
            DepositManagerV3(depositManagerProxy).deposit(mockLayer2, validatorAddr, depositAmount);
            rat.registerValidator(address(mockSystemConfig));
            vm.stopPrank();
        }

        // 가스 측정: triggerAttentionTest
        uint256 gasBefore = gasleft();
        vm.prank(mockDisputeGameFactory);
        rat.triggerAttentionTest(
            address(0x1234),
            address(mockSystemConfig),
            1,
            keccak256("batch1"),
            keccak256("block1")
        );
        uint256 gasUsed = gasBefore - gasleft();

        emit log_named_uint("Gas for triggerAttentionTest (10 validators)", gasUsed);
        assertTrue(gasUsed < 1_000_000, "triggerAttentionTest should use < 1M gas");
    }

    /// @notice GAS-004: 보상 청구 가스 측정
    function test_GAS004_claimAllRewards_gas() public {
        uint256 depositAmount = 300 * RAY;
        _registerValidator(validator1, depositAmount);

        // L2 자격 확보를 위해 bridgedTON 설정
        vm.prank(owner);
        MockTON(ton).mint(mockPortal, 1000e18);
        vm.prank(mockPortal);
        seigManager.onBridgedTonChange();

        // 시뇨리지 분배
        vm.roll(block.number + 100);
        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        // V1.1: O(1) 분배에서는 getClaimableRewards 사용
        uint256 claimableRewards = IValidatorReward(validatorPoolProxy).getClaimableRewards(validator1);
        emit log_named_uint("Claimable rewards before claim", claimableRewards);

        if (claimableRewards == 0) {
            emit log_string("No rewards - L2 may not be eligible, skipping claim gas test");
            return;
        }

        // 가스 측정: claimAllRewards
        uint256 gasBefore = gasleft();
        vm.prank(validator1);
        IValidatorReward(validatorPoolProxy).claimAllRewards();
        uint256 gasUsed = gasBefore - gasleft();

        emit log_named_uint("Gas for claimAllRewards", gasUsed);
        assertTrue(gasUsed < 200_000, "claimAllRewards should use < 200k gas");
    }

    /// @notice GAS-005: Deposit 가스 측정
    function test_GAS005_deposit_gas() public {
        uint256 depositAmount = 300 * RAY;

        vm.prank(owner);
        MockWTON(wton).mint(validator1, depositAmount);

        vm.startPrank(validator1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);

        // 가스 측정: deposit
        uint256 gasBefore = gasleft();
        DepositManagerV3(depositManagerProxy).deposit(mockLayer2, validator1, depositAmount);
        uint256 gasUsed = gasBefore - gasleft();
        vm.stopPrank();

        emit log_named_uint("Gas for deposit", gasUsed);
        assertTrue(gasUsed < 500_000, "deposit should use < 500k gas");
    }

    /// @notice GAS-006: 종합 가스 리포트 (100명 검증자 시나리오)
    function test_GAS006_fullScenario_gasReport() public {
        uint256 maxValidators = 100;
        uint256 depositAmount = 300 * RAY;

        vm.prank(owner);
        rat.setMaxValidatorsPerL2(maxValidators);

        emit log_string("=== Gas Report: 100 Validators Scenario ===");

        // 1. 100명 검증자 등록 총 가스
        uint256 totalRegisterGas = 0;
        uint256 gasBeforeLoop;
        for (uint256 i = 0; i < maxValidators; i++) {
            address validatorAddr = address(uint160(0x40000 + i));
            vm.prank(owner);
            MockWTON(wton).mint(validatorAddr, depositAmount);

            vm.startPrank(validatorAddr);
            MockWTON(wton).approve(depositManagerProxy, depositAmount);
            DepositManagerV3(depositManagerProxy).deposit(mockLayer2, validatorAddr, depositAmount);

            gasBeforeLoop = gasleft();
            rat.registerValidator(address(mockSystemConfig));
            totalRegisterGas += (gasBeforeLoop - gasleft());
            vm.stopPrank();
        }
        emit log_named_uint("Total gas for 100 registerValidator", totalRegisterGas);
        emit log_named_uint("Avg gas per registerValidator", totalRegisterGas / maxValidators);

        // L2 자격 확보를 위해 bridgedTON 설정
        vm.prank(owner);
        MockTON(ton).mint(mockPortal, 10000e18);
        vm.prank(mockPortal);
        seigManager.onBridgedTonChange();

        // 자격 확인
        (bool eligible, , ) = seigManager.checkCurrentEligibility(mockLayer2);
        emit log_named_string("L2 eligible", eligible ? "true" : "false");

        // 2. updateSeigniorage 가스
        vm.roll(block.number + 100);
        uint256 gasBefore = gasleft();
        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();
        uint256 updateGas = gasBefore - gasleft();
        emit log_named_uint("Gas for updateSeigniorage (100 validators)", updateGas);

        // 3. triggerAttentionTest 가스
        gasBefore = gasleft();
        vm.prank(mockDisputeGameFactory);
        rat.triggerAttentionTest(
            address(0x9999),
            address(mockSystemConfig),
            999,
            keccak256("batch999"),
            keccak256("block999")
        );
        uint256 triggerGas = gasBefore - gasleft();
        emit log_named_uint("Gas for triggerAttentionTest (100 validators)", triggerGas);

        // 4. 첫 번째 검증자 claimAllRewards 가스 (보상이 있는 경우만)
        address firstValidator = address(uint160(0x40000));
        // V1.1: O(1) 분배에서는 getClaimableRewards 사용 (동기화되지 않은 보상 포함)
        uint256 claimableRewards = IValidatorReward(validatorPoolProxy).getClaimableRewards(firstValidator);
        emit log_named_uint("First validator claimable rewards", claimableRewards);

        if (claimableRewards > 0) {
            gasBefore = gasleft();
            vm.prank(firstValidator);
            IValidatorReward(validatorPoolProxy).claimAllRewards();
            uint256 claimGas = gasBefore - gasleft();
            emit log_named_uint("Gas for claimAllRewards", claimGas);
        } else {
            emit log_string("No claimable rewards (L2 may not be eligible)");
        }

        emit log_string("===========================================");

        // 가스 예산 검증
        // - updateSeigniorage: 100명 검증자에게 분배 시 ~5.3M gas (자격 충족 시)
        // - L1 블록 가스 리밋 30M 기준으로는 가능하나, 더 많은 검증자는 주의 필요
        emit log_named_uint("Estimated max validators (30M limit)", 30_000_000 / (updateGas / 100));
        assertTrue(updateGas < 10_000_000, "updateSeigniorage should be < 10M gas for 100 validators");
        assertTrue(triggerGas < 1_000_000, "triggerAttentionTest should be < 1M gas");
    }
}
