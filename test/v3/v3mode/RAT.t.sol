// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../helpers/V3TestBase.sol";
import {SimpleMockSystemConfig} from "../../../src/mocks/SimpleMockSystemConfig.sol";
import {
    MaxValidatorsReachedError,
    TestAlreadyExistsError,
    AlreadyRegisteredError,
    InsufficientCollateralError,
    DeadlinePassedError,
    NotSelectedValidatorError
} from "../../../src/validator/RAT.sol";
import {RATStorage} from "../../../src/validator/RATStorage.sol";
import {RATConfigParams} from "../../../src/validator/RATTypes.sol";
import {RefactorCoinageSnapshotI} from "../../../src/stake/interfaces/RefactorCoinageSnapshotI.sol";

/// @notice Mock FaultDisputeGame that provides systemConfig() for RAT.resolveClaim()
contract MockFaultDisputeGame {
    address public systemConfig;

    constructor(address _systemConfig) {
        systemConfig = _systemConfig;
    }
}

/// @title RATTest
/// @notice RAT (Randomized Attention Test) V3 단위 테스트
/// @dev V3TestBase를 활용하여 통합 테스트 수행
contract RATTest is V3TestBase {
    // ==========================================
    // Additional Mock for second L2
    // ==========================================
    SimpleMockSystemConfig public mockSystemConfig2;
    address public mockL2TON2;
    address public mockLayer2_2;
    address public operatorManager2;

    // ==========================================
    // Test Addresses (file-specific)
    // ==========================================
    address public factory;
    address public operator2 = address(0x4002);
    address public validator1 = address(0x6001);
    address public validator2 = address(0x6002);
    address public validator3 = address(0x6003);
    address public treasury = address(0x9001);

    MockFaultDisputeGame public mockGame1;

    uint256 public slashingPenalty = 100e27;
    uint256 public validatorBuffer = 100e27;
    uint256 public minimumThreshold = 200e27;
    uint256 public evidenceSubmissionPeriod = 1 hours;
    uint256 public ratTriggerProbability = RAY; // 100% for testing
    uint256 public maxValidatorsPerL2 = 100;
    uint256 public challengeGameDuration = 7 days;
    uint256 public safetyBuffer = 1 days;
    uint256 public attentionCost = 1e27;
    bool public relaxedValidatorCheck = true;

    function setUp() public {
        _v3TestSetup();

        vm.startPrank(owner);

        // RAT 파라미터 설정
        rat.setSlashingPenalty(slashingPenalty);
        rat.setValidatorBuffer(validatorBuffer);
        rat.setMinimumThreshold(minimumThreshold);
        rat.setRatTriggerProbability(ratTriggerProbability);
        rat.setEvidenceSubmissionPeriod(evidenceSubmissionPeriod);
        rat.setChallengeGameDuration(challengeGameDuration);
        rat.setSafetyBuffer(safetyBuffer);
        rat.setAttentionCost(attentionCost);
        rat.setRelaxedValidatorCheck(relaxedValidatorCheck);
        rat.setMaxValidatorsPerL2(maxValidatorsPerL2);
        rat.setTreasury(treasury);

        // Layer2 등록 (systemConfig1)
        (mockLayer2, operatorManager) = _registerLayer2WithSystemConfig(
            address(mockSystemConfig),
            mockL2TON,
            "TestL2",
            operator1,
            1000 * RAY
        );

        // Factory 설정 (DisputeGameFactory를 factory로 사용)
        factory = mockDisputeGameFactory;

        // MockFaultDisputeGame 생성 (systemConfig1 사용)
        mockGame1 = new MockFaultDisputeGame(address(mockSystemConfig));

        // V3 설정 및 마이그레이션
        _setupV3AndMigrate();

        vm.stopPrank();

        // 검증자들 스테이킹 (WTON 단위: 500, 600, 700 WTON)
        _stakeForValidator(validator1, mockLayer2, 500 * RAY);
        _stakeForValidator(validator2, mockLayer2, 600 * RAY);
        _stakeForValidator(validator3, mockLayer2, 700 * RAY);
    }

    // ==========================================
    // 기본 테스트
    // ==========================================

    function test_RAT010_getDynamicMinimumCollateral() public {
        // D_min = max(slashingPenalty, (c_m × N × RAY) / π_a) + validatorBuffer
        // 기본값: slashingPenalty=100e27, validatorBuffer=100e27, π_a=1e27 (100%)
        // NOTE: getDynamicMinimumCollateral은 relaxedValidatorCheck를 무시하고 항상 동적 공식 사용

        // relaxedValidatorCheck 상태 확인 (이 함수는 무시하지만 명시적으로 확인)
        assertTrue(rat.relaxedValidatorCheck(), "relaxedValidatorCheck should be true (default)");

        // attentionCost 설정 (동적 공식 적용되도록)
        vm.prank(owner);
        rat.setAttentionCost(150e27);

        // Case 1: N=1 (검증자 없음, 최소 1명 기준)
        // C_off = max(100e27, (150e27 × 1 × 1e27) / 1e27) = max(100e27, 150e27) = 150e27
        // D_min = 150e27 + 100e27 = 250e27
        uint256 minCollateral1 = rat.getDynamicMinimumCollateral(address(mockSystemConfig));
        uint256 expectedCoff1 = (150e27 * 1 * RAY) / RAY; // 150e27
        assertEq(minCollateral1, expectedCoff1 + validatorBuffer, "N=1: D_min = formula + buffer");

        // Case 2: N=3 (검증자 3명 등록)
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));
        vm.prank(validator2);
        rat.registerValidator(address(mockSystemConfig));
        vm.prank(validator3);
        rat.registerValidator(address(mockSystemConfig));

        // C_off = max(100e27, (150e27 × 3 × 1e27) / 1e27) = max(100e27, 450e27) = 450e27
        // D_min = 450e27 + 100e27 = 550e27
        uint256 minCollateral3 = rat.getDynamicMinimumCollateral(address(mockSystemConfig));
        uint256 expectedCoff3 = (150e27 * 3 * RAY) / RAY; // 450e27
        assertEq(minCollateral3, expectedCoff3 + validatorBuffer, "N=3: D_min = formula + buffer");

        // N 증가 → D_min 증가 확인
        assertTrue(minCollateral3 > minCollateral1, "D_min should increase with N");
    }

    function test_RAT012a_getCoffWithRelaxedCheck_relaxedMode() public {
        // relaxedValidatorCheck = true (기본값)
        // C_off는 항상 slashingPenalty

        // 검증자 3명 등록
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));
        vm.prank(validator2);
        rat.registerValidator(address(mockSystemConfig));
        vm.prank(validator3);
        rat.registerValidator(address(mockSystemConfig));

        uint256 coff = rat.getCoffWithRelaxedCheck(address(mockSystemConfig));
        assertEq(coff, slashingPenalty);
    }

    function test_RAT013a_getCoffWithRelaxedCheck_strictMode() public {
        // relaxedValidatorCheck = false
        // C_off = max(slashingPenalty, (c_m × N × RAY) / π_a)

        vm.prank(owner);
        rat.setRelaxedValidatorCheck(false);
        vm.prank(owner);
        rat.setAttentionCost(50e27); // c_m 설정

        // 검증자 3명 등록
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));
        vm.prank(validator2);
        rat.registerValidator(address(mockSystemConfig));
        vm.prank(validator3);
        rat.registerValidator(address(mockSystemConfig));

        uint256 coff = rat.getCoffWithRelaxedCheck(address(mockSystemConfig));

        // 예상값 계산: (50e27 × 3 × 1e27) / 1e27 = 150e27
        uint256 expected = (50e27 * 3 * RAY) / RAY;
        assertEq(coff, expected);
        assertTrue(coff > slashingPenalty);
    }

    function test_RAT011_getDynamicCoff_withFormula() public {
        // C_off = max(slashingPenalty, (c_m × N × RAY) / π_a)
        // 기본값: slashingPenalty=100e27, π_a=1e27 (100%)
        // NOTE: getDynamicCoff는 relaxedValidatorCheck를 무시하고 항상 동적 공식 사용

        // relaxedValidatorCheck 상태 확인 (이 함수는 무시하지만 명시적으로 확인)
        assertTrue(rat.relaxedValidatorCheck(), "relaxedValidatorCheck should be true (default)");

        // attentionCost 설정 (동적 공식 적용되도록)
        vm.prank(owner);
        rat.setAttentionCost(150e27);

        // Case 1: N=1 (검증자 없음, 최소 1명 기준)
        // C_off = max(100e27, (150e27 × 1 × 1e27) / 1e27) = max(100e27, 150e27) = 150e27
        uint256 coff1 = rat.getDynamicCoff(address(mockSystemConfig));
        uint256 expectedCoff1 = (150e27 * 1 * RAY) / RAY; // 150e27
        assertEq(coff1, expectedCoff1, "N=1: C_off = formula");

        // Case 2: N=3 (검증자 3명 등록)
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));
        vm.prank(validator2);
        rat.registerValidator(address(mockSystemConfig));
        vm.prank(validator3);
        rat.registerValidator(address(mockSystemConfig));

        // C_off = max(100e27, (150e27 × 3 × 1e27) / 1e27) = max(100e27, 450e27) = 450e27
        uint256 coff3 = rat.getDynamicCoff(address(mockSystemConfig));
        uint256 expectedCoff3 = (150e27 * 3 * RAY) / RAY; // 450e27
        assertEq(coff3, expectedCoff3, "N=3: C_off = formula");

        // N 증가 → C_off 증가 확인
        assertTrue(coff3 > coff1, "C_off should increase with N");
    }

    function test_RAT012b_getMinimumCollateralWithRelaxedCheck_relaxedMode() public view {
        // relaxedValidatorCheck = true (기본값)
        // D_min = C_off + validatorBuffer = slashingPenalty + validatorBuffer

        uint256 dmin = rat.getMinimumCollateralWithRelaxedCheck(address(mockSystemConfig));
        assertEq(dmin, slashingPenalty + validatorBuffer);
    }

    function test_RAT013b_getMinimumCollateralWithRelaxedCheck_strictMode() public {
        // relaxedValidatorCheck = false
        // D_min = C_off(dynamic) + validatorBuffer

        vm.prank(owner);
        rat.setRelaxedValidatorCheck(false);
        vm.prank(owner);
        rat.setAttentionCost(50e27);

        // 검증자 3명 등록
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));
        vm.prank(validator2);
        rat.registerValidator(address(mockSystemConfig));
        vm.prank(validator3);
        rat.registerValidator(address(mockSystemConfig));

        uint256 dmin = rat.getMinimumCollateralWithRelaxedCheck(address(mockSystemConfig));

        // 예상값: (50e27 × 3 × 1e27) / 1e27 + 100e27 = 250e27
        uint256 expectedCoff = (50e27 * 3 * RAY) / RAY;
        uint256 expected = expectedCoff + validatorBuffer;
        assertEq(dmin, expected);
    }

    // ==========================================
    // 검증자 등록 테스트
    // ==========================================

    function test_RAT001_registerValidator_success() public {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        (uint256 collateral, uint32 validatorIndex, bool isActive) =
            rat.getValidatorRegistration(validator1, address(mockSystemConfig));

        assertTrue(isActive);
        // 스테이킹된 금액 기반 collateral (factor 적용으로 약간 적을 수 있음)
        assertTrue(collateral > 0);
        assertEq(validatorIndex, 0);
        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 1);
    }

    function test_RAT002_registerValidator_insufficientDeposit() public {
        // 새 검증자에게 최소 기준 미달 금액 스테이킹
        address poorValidator = address(0x7777);
        _stakeForValidator(poorValidator, mockLayer2, 100 * RAY); // minimumThreshold(200e27) 미달

        // 스테이킹된 금액 확인
        uint256 stake = _getValidatorStake(mockLayer2, poorValidator);
        assertTrue(stake < minimumThreshold, "Stake should be below minimumThreshold");

        vm.prank(poorValidator);
        vm.expectRevert(InsufficientCollateralError.selector);
        rat.registerValidator(address(mockSystemConfig));

        // 검증자 수 변화 없음 확인
        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 0, "No validator should be registered");
    }

    function test_RAT003_registerValidator_alreadyRegistered() public {
        // 첫 번째 등록 성공
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));
        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 1, "First registration success");

        // 등록 상태 확인
        (, , bool isActive) = rat.getValidatorRegistration(validator1, address(mockSystemConfig));
        assertTrue(isActive, "Validator should be active");

        // 중복 등록 시도 → AlreadyRegisteredError
        vm.prank(validator1);
        vm.expectRevert(AlreadyRegisteredError.selector);
        rat.registerValidator(address(mockSystemConfig));

        // 검증자 수 변화 없음
        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 1, "Count unchanged after failed re-registration");
    }

    function test_RAT006_registerMultipleValidators() public {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(validator2);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(validator3);
        rat.registerValidator(address(mockSystemConfig));

        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 3);
    }

    // ==========================================
    // 검증자 비활성화 테스트
    // ==========================================

    function test_RAT004_deactivateValidator() public {
        uint256 stakeBefore = _getValidatorStake(mockLayer2, validator1);

        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(validator1);
        rat.deactivateValidator(address(mockSystemConfig));

        (uint256 collateral, , bool isActive) =
            rat.getValidatorRegistration(validator1, address(mockSystemConfig));

        assertFalse(isActive);
        // collateral은 저장된 값 유지
        assertTrue(collateral > 0);
        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 0);

        // 스테이크는 변경 없음
        uint256 stakeAfter = _getValidatorStake(mockLayer2, validator1);
        assertEq(stakeAfter, stakeBefore);
    }

    // ==========================================
    // RAT 트리거 테스트
    // ==========================================

    // Note: test_RAT020_triggerAttentionTest moved to RATSeigManagerIntegration.t.sol (INT-020)

    function test_RAT022_triggerAttentionTest_noValidators() public {
        // 검증자 없을 때 triggerAttentionTest는 revert 없이 early return
        uint32 batchIndex = 1;
        bytes32 batchHash = keccak256("batch1");
        bytes32 blockHash = keccak256("block1");

        // 검증자 없음 확인
        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 0, "No validators");

        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), batchIndex, batchHash, blockHash);

        // 테스트가 생성되지 않았음을 확인
        bytes32 testId = rat.batchToTestId(address(mockSystemConfig), batchIndex);
        assertEq(testId, bytes32(0), "No test should be created");
    }

    // ==========================================
    // 증거 제출 테스트
    // ==========================================

    // Note: test_RAT030_submitEvidence moved to RATSeigManagerIntegration.t.sol (INT-021)

    /// @notice RAT-031: deadline 초과 후 증거 제출 실패
    function test_RAT031_submitEvidence_afterDeadline_reverts() public {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        uint256 stakeBefore = _getValidatorStake(mockLayer2, validator1);

        uint32 batchIndex = 1;
        bytes32 batchHash = keccak256("batch1");
        bytes32 blockHash = keccak256("block1");

        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), batchIndex, batchHash, blockHash);

        // evidenceSubmissionPeriod 경과 (deadline 초과)
        uint256 evidencePeriod = rat.evidenceSubmissionPeriod();
        vm.warp(block.timestamp + evidencePeriod + 1);

        // deadline 초과 후 증거 제출 시도 → DeadlinePassedError
        vm.prank(validator1);
        vm.expectRevert(DeadlinePassedError.selector);
        rat.submitEvidence(address(mockSystemConfig), batchIndex, "late_evidence");

        // 검증자의 스테이크가 복구되지 않았는지 확인
        uint256 stakeAfter = _getValidatorStake(mockLayer2, validator1);
        assertEq(stakeAfter, stakeBefore - slashingPenalty, "Stake should remain slashed after deadline");

        // RAT이 여전히 담보금 보유
        uint256 ratStake = _getValidatorStake(mockLayer2, address(rat));
        assertEq(ratStake, slashingPenalty, "RAT should still hold the slashed amount");
    }

    /// @notice RAT-032: 비선택 검증자가 증거 제출 시 실패
    function test_RAT032_submitEvidence_notSelected_reverts() public {
        // 두 검증자 등록
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(validator2);
        rat.registerValidator(address(mockSystemConfig));

        uint256 stake1Before = _getValidatorStake(mockLayer2, validator1);
        uint256 stake2Before = _getValidatorStake(mockLayer2, validator2);

        // RAT 트리거 (랜덤으로 한 명만 선택됨)
        uint32 batchIndex = 1;
        bytes32 batchHash = keccak256("batch1");
        bytes32 blockHash = keccak256("block1");

        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), batchIndex, batchHash, blockHash);

        // 어느 검증자가 선택되었는지 확인
        uint256 stake1After = _getValidatorStake(mockLayer2, validator1);
        uint256 stake2After = _getValidatorStake(mockLayer2, validator2);

        address selectedValidator;
        address notSelectedValidator;
        uint256 selectedStakeBefore;

        if (stake1After < stake1Before) {
            // validator1이 선택됨
            selectedValidator = validator1;
            notSelectedValidator = validator2;
            selectedStakeBefore = stake1Before;
            assertEq(stake1After, stake1Before - slashingPenalty, "validator1 should be slashed");
            assertEq(stake2After, stake2Before, "validator2 should not be slashed");
        } else {
            // validator2가 선택됨
            selectedValidator = validator2;
            notSelectedValidator = validator1;
            selectedStakeBefore = stake2Before;
            assertEq(stake2After, stake2Before - slashingPenalty, "validator2 should be slashed");
            assertEq(stake1After, stake1Before, "validator1 should not be slashed");
        }

        // 비선택 검증자가 증거 제출 시도 → NotSelectedValidatorError
        vm.prank(notSelectedValidator);
        vm.expectRevert(NotSelectedValidatorError.selector);
        rat.submitEvidence(address(mockSystemConfig), batchIndex, "evidence_from_wrong_validator");

        // 비선택 검증자의 스테이크 변화 없음 확인
        uint256 notSelectedStake = _getValidatorStake(mockLayer2, notSelectedValidator);
        if (notSelectedValidator == validator1) {
            assertEq(notSelectedStake, stake1Before, "notSelected validator stake unchanged");
        } else {
            assertEq(notSelectedStake, stake2Before, "notSelected validator stake unchanged");
        }

        // 선택된 검증자만 증거 제출 가능 (정상 동작 확인)
        vm.prank(selectedValidator);
        rat.submitEvidence(address(mockSystemConfig), batchIndex, "correct_evidence");

        // 선택된 검증자의 스테이크 복구 확인
        assertEq(_getValidatorStake(mockLayer2, selectedValidator), selectedStakeBefore, "selected validator should be restored");

        // 상태 확인: RestoredByEvidence
        bytes32 testId = rat.batchToTestId(address(mockSystemConfig), batchIndex);
        RATStorage.AttentionTestStatus status = rat.getAttentionTestStatus(testId);
        assertEq(uint256(status), uint256(RATStorage.AttentionTestStatus.RestoredByEvidence), "Status should be RestoredByEvidence");
    }

    // ==========================================
    // 상태 조회 테스트 (시간 기반)
    // ==========================================

    function test_RAT040_getAttentionTestStatus_evidencePeriod() public {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        uint32 batchIndex = 1;
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), batchIndex, keccak256("batch1"), keccak256("block1"));

        bytes32 testId = rat.batchToTestId(address(mockSystemConfig), batchIndex);

        // deadline 전에는 EvidencePeriod
        RATStorage.AttentionTestStatus status = rat.getAttentionTestStatus(testId);
        assertEq(uint256(status), uint256(RATStorage.AttentionTestStatus.EvidencePeriod));
    }

    function test_RAT041_getAttentionTestStatus_challengePeriod() public {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        uint32 batchIndex = 1;
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), batchIndex, keccak256("batch1"), keccak256("block1"));

        bytes32 testId = rat.batchToTestId(address(mockSystemConfig), batchIndex);

        // deadline 경과 후 ~ challengeGameDuration 내에는 ChallengePeriod
        vm.warp(block.timestamp + evidenceSubmissionPeriod + 1);

        RATStorage.AttentionTestStatus status = rat.getAttentionTestStatus(testId);
        assertEq(uint256(status), uint256(RATStorage.AttentionTestStatus.ChallengePeriod));
    }

    function test_RAT042_getAttentionTestStatus_slashed() public {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        uint256 stakeBefore = _getValidatorStake(mockLayer2, validator1);

        uint32 batchIndex = 1;
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), batchIndex, keccak256("batch1"), keccak256("block1"));

        bytes32 testId = rat.batchToTestId(address(mockSystemConfig), batchIndex);

        // deadline + challengeGameDuration 경과 후에 Slashed
        vm.warp(block.timestamp + evidenceSubmissionPeriod + challengeGameDuration + 1);

        RATStorage.AttentionTestStatus status = rat.getAttentionTestStatus(testId);
        assertEq(uint256(status), uint256(RATStorage.AttentionTestStatus.Slashed));

        // 검증자 스테이크는 여전히 선차감 상태 (treasury 출금 전)
        assertEq(_getValidatorStake(mockLayer2, validator1), stakeBefore - slashingPenalty);
        assertEq(_getValidatorStake(mockLayer2, address(rat)), slashingPenalty);
    }

    function test_RAT043_getAttentionTestStatus_restoredByEvidence() public {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        uint32 batchIndex = 1;
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), batchIndex, keccak256("batch1"), keccak256("block1"));

        bytes32 testId = rat.batchToTestId(address(mockSystemConfig), batchIndex);

        // 증거 제출
        vm.prank(validator1);
        rat.submitEvidence(address(mockSystemConfig), batchIndex, "evidence");

        RATStorage.AttentionTestStatus status = rat.getAttentionTestStatus(testId);
        assertEq(uint256(status), uint256(RATStorage.AttentionTestStatus.RestoredByEvidence));
    }

    // ==========================================
    // Treasury 출금 테스트
    // ==========================================

    // Note: test_RAT050_withdrawSlashingsToTreasury moved to RATSeigManagerIntegration.t.sol (INT-022)

    // ==========================================
    // 확률적 트리거 테스트
    // ==========================================

    function test_RAT021a_probabilisticTrigger_zeroProbability() public {
        // 확률 0% → 트리거 안 됨
        vm.prank(owner);
        rat.setRatTriggerProbability(0);

        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        uint256 stakeBefore = _getValidatorStake(mockLayer2, validator1);

        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), 1, keccak256("batch1"), keccak256("block1"));

        // 테스트 생성 안 됨
        bytes32 testId = rat.batchToTestId(address(mockSystemConfig), 1);
        assertEq(testId, bytes32(0), "No test created with 0% probability");

        // 스테이크 변화 없음
        assertEq(_getValidatorStake(mockLayer2, validator1), stakeBefore, "Stake unchanged");

        // 검증자 여전히 활성
        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 1, "Validator still active");
    }

    function test_RAT021b_probabilisticTrigger_fullProbability() public {
        // 확률 100% (기본값) → 항상 트리거
        assertEq(rat.ratTriggerProbability(), RAY, "Default probability is 100%");

        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        uint256 stakeBefore = _getValidatorStake(mockLayer2, validator1);

        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), 1, keccak256("batch1"), keccak256("block1"));

        // 테스트 생성됨
        bytes32 testId = rat.batchToTestId(address(mockSystemConfig), 1);
        assertTrue(testId != bytes32(0), "Test created with 100% probability");

        // 스테이크 슬래싱됨
        assertEq(_getValidatorStake(mockLayer2, validator1), stakeBefore - slashingPenalty, "Stake slashed");

        // 상태 확인
        RATStorage.AttentionTestStatus status = rat.getAttentionTestStatus(testId);
        assertEq(uint256(status), uint256(RATStorage.AttentionTestStatus.EvidencePeriod), "Status is EvidencePeriod");
    }

    // ==========================================
    // resolveClaim 테스트 (챌린지 복구)
    // ==========================================

    // Note: test_RAT033_resolveClaim_duringChallengePeriod moved to RATSeigManagerIntegration.t.sol (INT-021 challenge)

    function test_RAT034_resolveClaim_afterChallengePeriod_fails() public {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        uint256 stakeBefore = _getValidatorStake(mockLayer2, validator1);

        uint32 batchIndex = 1;
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), batchIndex, keccak256("batch1"), keccak256("block1"));

        // 테스트 생성 확인
        bytes32 testId = rat.batchToTestId(address(mockSystemConfig), batchIndex);
        assertTrue(testId != bytes32(0), "Test should be created");

        // 즉시 슬래싱됨 확인
        assertEq(_getValidatorStake(mockLayer2, validator1), stakeBefore - slashingPenalty, "Stake slashed immediately");

        // deadline + challengeGameDuration 경과 후에는 복구 불가
        vm.warp(block.timestamp + evidenceSubmissionPeriod + challengeGameDuration + 1);

        // 시간 경과 후 상태 확인
        RATStorage.AttentionTestStatus statusBefore = rat.getAttentionTestStatus(testId);
        assertEq(uint256(statusBefore), uint256(RATStorage.AttentionTestStatus.Slashed), "Status should be Slashed before resolveClaim");

        // resolveClaim 호출 (챌린지 기간 이후 → 복구 실패)
        vm.prank(address(mockGame1));
        rat.resolveClaim(validator1);

        // 상태는 Slashed로 유지 (복구 실패)
        RATStorage.AttentionTestStatus statusAfter = rat.getAttentionTestStatus(testId);
        assertEq(uint256(statusAfter), uint256(RATStorage.AttentionTestStatus.Slashed), "Status still Slashed after failed resolveClaim");

        // 담보금 복구되지 않음
        assertEq(_getValidatorStake(mockLayer2, validator1), stakeBefore - slashingPenalty, "Validator stake not restored");
        assertEq(_getValidatorStake(mockLayer2, address(rat)), slashingPenalty, "RAT still holds slashed amount");

        // 검증자 활성 상태 확인 (relaxed mode: 400 RAY remaining >= 100 RAY C_off → 활성)
        (, , bool isActive) = rat.getValidatorRegistration(validator1, address(mockSystemConfig));
        assertTrue(isActive, "Validator still active (relaxed mode)");
    }

    // ==========================================
    // relaxedValidatorCheck 테스트
    // ==========================================

    function test_RAT025_relaxedValidatorCheck_thresholdIsCoffOnly() public {
        // relaxedValidatorCheck = true 일 때:
        // - bondAmount = C_off (slashingPenalty = 100 RAY)
        // - removalThreshold = C_off (validatorBuffer 미포함, 완화 모드)
        // - remaining >= C_off 이면 유지

        assertTrue(rat.relaxedValidatorCheck(), "relaxedValidatorCheck should be true (default)");

        // 검증자 등록 (minimumThreshold = C_off + validatorBuffer = 200 RAY)
        address testValidator = address(0x7001);
        MockTON(ton).mint(testValidator, 300 * RAY);
        _stakeForValidator(testValidator, mockLayer2, 200 * RAY);

        vm.prank(testValidator);
        rat.registerValidator(address(mockSystemConfig));
        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 1, "Validator registered");

        // RAT 트리거: bond = C_off = 100 RAY
        // remaining = 200 - 100 = 100 RAY
        // relaxed mode threshold = C_off = 100 RAY
        // 100 >= 100 → 유지
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), 1, keccak256("batch1"), keccak256("block1"));

        // 검증자 유지 확인 (remaining = C_off 이상)
        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 1, "Validator stays when remaining >= C_off");

        // relaxed mode에서 threshold = C_off 임을 확인
        uint256 coffRelaxed = rat.getCoffWithRelaxedCheck(address(mockSystemConfig));
        assertEq(coffRelaxed, slashingPenalty, "Relaxed mode: threshold = slashingPenalty (C_off)");

        // 검증자 활성 상태 확인
        (, , bool isActive) = rat.getValidatorRegistration(testValidator, address(mockSystemConfig));
        assertTrue(isActive, "Validator should remain active in relaxed mode");
    }

    function test_RAT026_strictValidatorCheck_thresholdIsCoffPlusBuffer() public {
        // relaxedValidatorCheck = false 일 때:
        // - bondAmount = C_off (slashingPenalty = 100 RAY)
        // - removalThreshold = C_off + validatorBuffer (엄격 모드)
        // - remaining < (C_off + validatorBuffer) 이면 제거

        // strict 모드로 변경
        vm.prank(owner);
        rat.setRelaxedValidatorCheck(false);
        assertFalse(rat.relaxedValidatorCheck(), "relaxedValidatorCheck should be false");

        // 검증자 등록 (minimumThreshold = C_off + validatorBuffer = 200 RAY)
        address testValidator = address(0x7002);
        MockTON(ton).mint(testValidator, 300 * RAY);
        _stakeForValidator(testValidator, mockLayer2, 200 * RAY);

        vm.prank(testValidator);
        rat.registerValidator(address(mockSystemConfig));
        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 1, "Validator registered");

        // RAT 트리거 전 스테이크 확인
        uint256 stakeBefore = _getValidatorStake(mockLayer2, testValidator);
        assertEq(stakeBefore, 200 * RAY, "Initial stake = 200 RAY");

        // RAT 트리거: bond = C_off = 100 RAY
        // remaining = 200 - 100 = 100 RAY
        // strict mode threshold = C_off + validatorBuffer = 200 RAY
        // 100 < 200 → 제거
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), 1, keccak256("batch1"), keccak256("block1"));

        // 검증자 제거 확인 (remaining < threshold)
        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 0, "Validator removed in strict mode");

        // strict mode에서:
        // - C_off = slashingPenalty (100 RAY)
        // - 제거 임계값 (D_min) = C_off + validatorBuffer (200 RAY)
        uint256 coffStrict = rat.getCoffWithRelaxedCheck(address(mockSystemConfig));
        assertEq(coffStrict, slashingPenalty, "Strict mode: C_off = slashingPenalty");

        uint256 dminStrict = rat.getMinimumCollateralWithRelaxedCheck(address(mockSystemConfig));
        assertEq(dminStrict, slashingPenalty + validatorBuffer, "Strict mode: D_min = C_off + validatorBuffer");

        // 검증자 비활성 상태 확인
        (, , bool isActive) = rat.getValidatorRegistration(testValidator, address(mockSystemConfig));
        assertFalse(isActive, "Validator should be deactivated in strict mode");

        // 스테이크는 슬래싱됨
        uint256 stakeAfter = _getValidatorStake(mockLayer2, testValidator);
        assertEq(stakeAfter, stakeBefore - slashingPenalty, "Stake reduced by slashingPenalty");
    }

    function test_RAT027_strictMode_validatorStaysWithSufficientStake() public {
        // strict 모드에서도 충분한 담보금이 있으면 유지됨
        // remaining >= (C_off + validatorBuffer) 이면 유지

        vm.prank(owner);
        rat.setRelaxedValidatorCheck(false);

        // 검증자에게 충분한 스테이킹 (300 RAY)
        address testValidator = address(0x7003);
        MockTON(ton).mint(testValidator, 400 * RAY);
        _stakeForValidator(testValidator, mockLayer2, 300 * RAY);

        vm.prank(testValidator);
        rat.registerValidator(address(mockSystemConfig));
        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 1, "Validator registered");

        // RAT 트리거: bond = 100 RAY
        // remaining = 300 - 100 = 200 RAY
        // strict mode threshold = 200 RAY
        // 200 >= 200 → 유지
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), 1, keccak256("batch1"), keccak256("block1"));

        // 검증자 유지 확인
        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 1, "Validator stays with sufficient stake");

        (, , bool isActive) = rat.getValidatorRegistration(testValidator, address(mockSystemConfig));
        assertTrue(isActive, "Validator should remain active");
    }

    // ==========================================
    // RAT-007: N_max 초과 검증 테스트
    // ==========================================

    function test_RAT007a_maxValidators_exceeded_reverts() public {
        // maxValidatorsPerL2 = 3으로 설정
        vm.prank(owner);
        rat.setMaxValidatorsPerL2(3);

        // 추가 검증자 생성
        address validator4 = address(0x6004);
        MockTON(ton).mint(validator4, INITIAL_TON);
        _stakeForValidator(validator4, mockLayer2, 500 * RAY);

        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(validator2);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(validator3);
        rat.registerValidator(address(mockSystemConfig));

        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 3, "Should have 3 validators");

        // 4번째 검증자 등록 시도 → revert
        vm.prank(validator4);
        vm.expectRevert(MaxValidatorsReachedError.selector);
        rat.registerValidator(address(mockSystemConfig));
    }

    function test_RAT007b_maxValidators_zeroNotAllowed() public {
        // maxValidatorsPerL2 = 0은 허용되지 않음 (DoS 방지)
        vm.prank(owner);
        vm.expectRevert("invalid maxValidatorsPerL2");
        rat.setMaxValidatorsPerL2(0);
    }

    function test_RAT007c_maxValidators_reregisterAfterDeactivation() public {
        vm.prank(owner);
        rat.setMaxValidatorsPerL2(2);

        address validator4 = address(0x6004);
        MockTON(ton).mint(validator4, INITIAL_TON);
        _stakeForValidator(validator4, mockLayer2, 500 * RAY);

        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(validator2);
        rat.registerValidator(address(mockSystemConfig));

        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 2);

        // validator4 등록 시도 → revert
        vm.prank(validator4);
        vm.expectRevert(MaxValidatorsReachedError.selector);
        rat.registerValidator(address(mockSystemConfig));

        // validator1 탈퇴
        vm.prank(validator1);
        rat.deactivateValidator(address(mockSystemConfig));

        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 1);

        // 이제 validator4 등록 가능
        vm.prank(validator4);
        rat.registerValidator(address(mockSystemConfig));

        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 2);
    }

    // ==========================================
    // RAT-052: Treasury 미설정 테스트
    // ==========================================

    function test_RAT052a_treasury_zeroAddress_reverts() public {
        // treasury를 address(0)으로 설정
        vm.prank(owner);
        rat.setTreasury(address(0));

        // treasury가 0일 때 withdrawSlashingsToTreasury 호출 시 revert
        vm.expectRevert("treasury not set");
        rat.withdrawSlashingsToTreasury(address(mockSystemConfig));
    }

    function test_RAT052b_treasury_setAndWithdraw() public {
        // 검증자 등록
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        // RAT 트리거
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), 1, keccak256("batch1"), keccak256("block1"));

        // 전체 기간 경과
        vm.warp(block.timestamp + evidenceSubmissionPeriod + challengeGameDuration + safetyBuffer + 1);

        // treasury 잔액 확인
        uint256 treasuryBefore = _getValidatorStake(mockLayer2, treasury);

        // 슬래싱 금액 출금
        rat.withdrawSlashingsToTreasury(address(mockSystemConfig));

        // treasury로 슬래싱 금액 전송됨
        uint256 treasuryAfter = _getValidatorStake(mockLayer2, treasury);
        assertEq(treasuryAfter - treasuryBefore, slashingPenalty, "Treasury should receive slashing penalty");
    }

    // ==========================================
    // EDGE-010: 동시 RAT 트리거 테스트
    // ==========================================

    function test_EDGE010_duplicateTrigger_sameBatch_reverts() public {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        uint32 batchIndex = 1;

        // 첫 번째 트리거 성공
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), batchIndex, keccak256("batch1"), keccak256("block1"));

        // 동일 batchIndex로 재트리거 시도 → revert
        vm.prank(factory);
        vm.expectRevert(TestAlreadyExistsError.selector);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), batchIndex, keccak256("batch1"), keccak256("block1"));
    }

    function test_EDGE010_differentBatch_allowed() public {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));
        vm.prank(validator2);
        rat.registerValidator(address(mockSystemConfig));

        // batchIndex 1 트리거
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), 1, keccak256("batch1"), keccak256("block1"));

        // batchIndex 2 트리거 (다른 batch이므로 가능)
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), 2, keccak256("batch2"), keccak256("block2"));

        // 두 테스트 모두 존재
        bytes32 testId1 = rat.batchToTestId(address(mockSystemConfig), 1);
        bytes32 testId2 = rat.batchToTestId(address(mockSystemConfig), 2);
        assertTrue(testId1 != bytes32(0), "Test 1 should exist");
        assertTrue(testId2 != bytes32(0), "Test 2 should exist");
    }

    // ==========================================
    // E2E-014: 다중 L2 검증자 테스트
    // ==========================================

    function test_E2E014_multipleL2_sameValidator() public {
        // 두 번째 L2 설정
        _setupSecondL2();

        // validator1이 두 L2에 모두 스테이킹되어 있어야 함
        _stakeForValidator(validator1, mockLayer2_2, 500 * RAY);

        // validator1이 첫 번째 L2에 등록
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        // validator1이 두 번째 L2에도 등록
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig2));

        // 두 L2 모두에서 활성 검증자
        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 1, "Should have 1 validator in L2_1");
        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig2)), 1, "Should have 1 validator in L2_2");

        // 동일 검증자의 등록 정보 확인
        (, , bool isActive1) = rat.getValidatorRegistration(validator1, address(mockSystemConfig));
        (, , bool isActive2) = rat.getValidatorRegistration(validator1, address(mockSystemConfig2));
        assertTrue(isActive1, "Validator should be active in L2_1");
        assertTrue(isActive2, "Validator should be active in L2_2");
    }

    function test_E2E014_slashingOneL2_noAffectOther() public {
        // 두 번째 L2 설정
        _setupSecondL2();

        // validator1이 두 L2에 모두 스테이킹
        _stakeForValidator(validator1, mockLayer2_2, 500 * RAY);

        uint256 stake1Before = _getValidatorStake(mockLayer2, validator1);
        uint256 stake2Before = _getValidatorStake(mockLayer2_2, validator1);

        // 두 L2에 등록
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig2));

        // 등록 확인
        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 1, "L2_1 has 1 validator");
        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig2)), 1, "L2_2 has 1 validator");

        // L2_1에서 RAT 트리거 및 슬래싱
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), address(mockSystemConfig), 1, keccak256("batch1"), keccak256("block1"));

        // L2_1 잔액 감소
        assertEq(_getValidatorStake(mockLayer2, validator1), stake1Before - slashingPenalty, "L2_1 balance reduced");

        // L2_2 잔액 영향 없음
        assertEq(_getValidatorStake(mockLayer2_2, validator1), stake2Before, "L2_2 balance unchanged");

        // L2_1에서 여전히 활성 검증자 (relaxed mode: remaining >= C_off)
        // remaining = 500 - 100 = 400 RAY >= 100 RAY (C_off) → 유지
        (, , bool isActive1) = rat.getValidatorRegistration(validator1, address(mockSystemConfig));
        assertTrue(isActive1, "Validator still active in L2_1 (relaxed mode)");

        // L2_2에서 여전히 활성 검증자 (슬래싱 영향 없음)
        (, , bool isActive2) = rat.getValidatorRegistration(validator1, address(mockSystemConfig2));
        assertTrue(isActive2, "Validator still active in L2_2");

        // 활성 검증자 수 확인
        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 1, "L2_1 still has 1 validator");
        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig2)), 1, "L2_2 still has 1 validator");
    }

    /// @notice 두 번째 L2 설정 헬퍼
    function _setupSecondL2() internal {
        vm.startPrank(owner);

        // 두 번째 Mock 컨트랙트 생성
        mockL2TON2 = address(0x8014);
        address mockDisputeGameFactory2 = address(0x8013); // 다른 factory 사용

        mockSystemConfig2 = new SimpleMockSystemConfig();
        mockSystemConfig2.setL1StandardBridge(address(0x8011));
        mockSystemConfig2.setOptimismPortal(address(0x8012));
        mockSystemConfig2.setDisputeGameFactory(mockDisputeGameFactory2); // 다른 factory
        mockSystemConfig2.setUnsafeBlockSigner(operator2);

        // Layer2 등록
        (mockLayer2_2, operatorManager2) = _registerLayer2WithSystemConfig(
            address(mockSystemConfig2),
            mockL2TON2,
            "TestL2_2",
            operator2,
            1000 * RAY
        );

        vm.stopPrank();
    }
}
