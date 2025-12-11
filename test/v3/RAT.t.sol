// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import {RAT} from "../../src/validator/RAT.sol";
import {RATStorage} from "../../src/validator/RATStorage.sol";
import {MockWTON} from "./mocks/MockWTON.sol";
import {MockTON} from "./mocks/MockTON.sol";

/// @title RATTest
/// @notice RAT (Randomized Attention Test) 단위 테스트
/// @dev Tokamak Economics Whitepaper V2 (December 9, 2025) 기준
contract RATTest is Test {
    RAT public rat;
    MockWTON public wton;
    MockTON public ton;

    address public owner = address(this);
    address public seigManager = address(0x1);
    address public depositManager = address(0x2);
    address public authorizedTrigger = address(0x3);
    address public treasury = address(0x4);

    address public systemConfig1 = address(0x10);
    address public systemConfig2 = address(0x20);

    address public validator1 = address(0x100);
    address public validator2 = address(0x200);
    address public validator3 = address(0x300);

    uint256 internal constant RAY = 1e27;

    // 백서 V2 기본값
    uint256 public slashingPenalty = 100e27;       // C_off = 100 WTON
    uint256 public validatorBuffer = 100e27;       // Δ_validator = 100 WTON
    uint256 public minimumThreshold = 150e27;      // D_min = 150 WTON
    uint256 public minimumDeposit = 200e27;        // D_validator = C_off + Δ_validator
    uint256 public evidenceSubmissionPeriod = 1 hours;

    function setUp() public {
        // Deploy mocks
        wton = new MockWTON();
        ton = new MockTON();
        wton.setTON(address(ton));

        // Deploy RAT
        rat = new RAT();
        rat.initialize(
            seigManager,
            address(wton),
            address(ton),
            depositManager,
            owner
        );

        // 백서 V2 파라미터 설정
        rat.setSlashingPenalty(slashingPenalty);
        rat.setValidatorBuffer(validatorBuffer);
        rat.setMinimumThreshold(minimumThreshold);
        rat.setAuthorizedTrigger(authorizedTrigger);
        rat.setTreasury(treasury);
        rat.setEvidenceSubmissionPeriod(evidenceSubmissionPeriod);

        // Mint WTON to validators
        wton.mint(validator1, 10000e27);
        wton.mint(validator2, 10000e27);
        wton.mint(validator3, 10000e27);

        // Approve
        vm.prank(validator1);
        wton.approve(address(rat), type(uint256).max);
        vm.prank(validator2);
        wton.approve(address(rat), type(uint256).max);
        vm.prank(validator3);
        wton.approve(address(rat), type(uint256).max);
    }

    // ==========================================
    // 최소 담보금 테스트
    // ==========================================

    /// @notice 백서 공식 (5): D_validator = C_off + Δ_validator
    function test_getMinimumCollateral() public view {
        uint256 minCollateral = rat.getMinimumCollateral();

        // D_validator = slashingPenalty + validatorBuffer = 100 + 100 = 200
        assertEq(minCollateral, slashingPenalty + validatorBuffer, "Minimum collateral calculation");
    }

    // ==========================================
    // 검증자 등록 테스트
    // ==========================================

    /// @notice 검증자 등록 성공
    function test_registerValidator_success() public {
        uint256 depositAmount = 500e27;

        vm.prank(validator1);
        rat.registerValidator(systemConfig1, depositAmount);

        // 검증
        (
            uint256 depositedAmount,
            uint256 totalBondForRAT,
            uint256 pendingRewards,
            ,
            uint32 validatorIndex,
            bool isActive
        ) = rat.getValidatorRegistration(validator1, systemConfig1);

        assertTrue(isActive, "Validator should be active");
        assertEq(depositedAmount, depositAmount, "Deposit amount should match");
        assertEq(totalBondForRAT, 0, "No bonds initially");
        assertEq(pendingRewards, 0, "No pending rewards");
        assertEq(validatorIndex, 0, "First validator index");
        assertEq(rat.getActiveValidatorCount(systemConfig1), 1, "Active count should be 1");
    }

    /// @notice 불충분한 담보금으로 등록 실패
    function test_registerValidator_insufficientDeposit() public {
        uint256 minDeposit = rat.getMinimumCollateral();
        uint256 insufficientDeposit = minDeposit - 1;

        vm.prank(validator1);
        vm.expectRevert();
        rat.registerValidator(systemConfig1, insufficientDeposit);
    }

    /// @notice 중복 등록 실패
    function test_registerValidator_alreadyRegistered() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1, 500e27);

        vm.prank(validator1);
        vm.expectRevert();
        rat.registerValidator(systemConfig1, 500e27);
    }

    /// @notice 여러 L2에 등록 가능
    function test_registerValidator_multipleL2() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1, 500e27);

        vm.prank(validator1);
        rat.registerValidator(systemConfig2, 500e27);

        assertEq(rat.getActiveValidatorCount(systemConfig1), 1, "L2_1 active count");
        assertEq(rat.getActiveValidatorCount(systemConfig2), 1, "L2_2 active count");
    }

    /// @notice 여러 검증자 등록
    function test_registerMultipleValidators() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1, 500e27);

        vm.prank(validator2);
        rat.registerValidator(systemConfig1, 600e27);

        vm.prank(validator3);
        rat.registerValidator(systemConfig1, 700e27);

        assertEq(rat.getActiveValidatorCount(systemConfig1), 3, "Should have 3 active validators");
    }

    // ==========================================
    // 담보금 추가 테스트
    // ==========================================

    /// @notice 담보금 추가
    function test_addDeposit() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1, 500e27);

        vm.prank(validator1);
        rat.addDeposit(systemConfig1, 200e27);

        (
            uint256 depositedAmount,
            ,
            ,
            ,
            ,
        ) = rat.getValidatorRegistration(validator1, systemConfig1);

        assertEq(depositedAmount, 700e27, "Deposit should be increased");
    }

    /// @notice 비활성 검증자 담보금 추가 실패
    function test_addDeposit_notActive() public {
        vm.prank(validator1);
        vm.expectRevert();
        rat.addDeposit(systemConfig1, 200e27);
    }

    // ==========================================
    // 검증자 비활성화 테스트
    // ==========================================

    /// @notice 검증자 비활성화
    function test_deactivateValidator() public {
        uint256 depositAmount = 500e27;

        vm.prank(validator1);
        rat.registerValidator(systemConfig1, depositAmount);

        uint256 balanceBefore = wton.balanceOf(validator1);

        vm.prank(validator1);
        rat.deactivateValidator(systemConfig1);

        // 검증
        (
            uint256 depositedAmount,
            ,
            ,
            ,
            ,
            bool isActive
        ) = rat.getValidatorRegistration(validator1, systemConfig1);

        assertFalse(isActive, "Validator should be inactive");
        assertEq(depositedAmount, 0, "Deposit should be 0");
        assertEq(rat.getActiveValidatorCount(systemConfig1), 0, "Active count should be 0");

        // 담보금 반환 확인
        assertEq(
            wton.balanceOf(validator1),
            balanceBefore + depositAmount,
            "Deposit should be returned"
        );
    }

    // ==========================================
    // RAT 트리거 테스트
    // ==========================================

    /// @notice RAT 트리거 성공
    function test_triggerAttentionTest() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1, 500e27);

        uint32 batchIndex = 1;
        bytes32 batchHash = keccak256("batch1");
        bytes32 blockHash = keccak256("block1");

        vm.prank(authorizedTrigger);
        rat.triggerAttentionTest(systemConfig1, batchIndex, batchHash, blockHash);

        // 검증자의 담보금 선차감 확인
        (
            uint256 depositedAmount,
            uint256 totalBondForRAT,
            ,
            ,
            ,
        ) = rat.getValidatorRegistration(validator1, systemConfig1);

        // 초기 500 - C_off(100) = 400
        assertEq(depositedAmount, 400e27, "Deposit should be reduced by C_off");
        assertEq(totalBondForRAT, 100e27, "Bond for RAT should be C_off");
    }

    /// @notice 권한 없는 RAT 트리거 실패
    function test_triggerAttentionTest_notAuthorized() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1, 500e27);

        vm.prank(validator1);
        vm.expectRevert();
        rat.triggerAttentionTest(systemConfig1, 1, keccak256("batch1"), keccak256("block1"));
    }

    /// @notice 활성 검증자 없을 때 RAT 트리거 (무시됨)
    function test_triggerAttentionTest_noActiveValidators() public {
        // 검증자 없는 상태에서 트리거
        vm.prank(authorizedTrigger);
        rat.triggerAttentionTest(systemConfig1, 1, keccak256("batch1"), keccak256("block1"));

        // 테스트가 생성되지 않음 확인
        assertEq(rat.activeTestCount(systemConfig1), 0, "No test should be created");
    }

    // ==========================================
    // 증거 제출 테스트
    // ==========================================

    /// @notice 증거 제출 성공 (담보금 복구)
    function test_submitEvidence_success() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1, 500e27);

        uint32 batchIndex = 1;
        bytes32 batchHash = keccak256("batch1");
        bytes32 blockHash = keccak256("block1");

        vm.prank(authorizedTrigger);
        rat.triggerAttentionTest(systemConfig1, batchIndex, batchHash, blockHash);

        // 증거 제출
        vm.prank(validator1);
        rat.submitEvidence(systemConfig1, batchIndex, "evidence_data");

        // 담보금 복구 확인
        (
            uint256 depositedAmount,
            uint256 totalBondForRAT,
            ,
            ,
            ,
        ) = rat.getValidatorRegistration(validator1, systemConfig1);

        assertEq(depositedAmount, 500e27, "Deposit should be restored");
        assertEq(totalBondForRAT, 0, "No more bond for RAT");
    }

    /// @notice 마감 후 증거 제출 실패
    function test_submitEvidence_deadlinePassed() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1, 500e27);

        uint32 batchIndex = 1;
        bytes32 batchHash = keccak256("batch1");
        bytes32 blockHash = keccak256("block1");

        vm.prank(authorizedTrigger);
        rat.triggerAttentionTest(systemConfig1, batchIndex, batchHash, blockHash);

        // 마감 경과
        vm.warp(block.timestamp + evidenceSubmissionPeriod + 1);

        vm.prank(validator1);
        vm.expectRevert();
        rat.submitEvidence(systemConfig1, batchIndex, "evidence_data");
    }

    /// @notice 선택되지 않은 검증자가 증거 제출 실패
    function test_submitEvidence_notSelectedValidator() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1, 500e27);

        uint32 batchIndex = 1;
        vm.prank(authorizedTrigger);
        rat.triggerAttentionTest(systemConfig1, batchIndex, keccak256("batch1"), keccak256("block1"));

        // 다른 검증자가 제출 시도
        vm.prank(validator2);
        vm.expectRevert();
        rat.submitEvidence(systemConfig1, batchIndex, "evidence_data");
    }

    // ==========================================
    // 슬래싱 테스트 (백서 V2)
    // ==========================================

    /// @notice 미응답 검증자 슬래싱
    function test_finalizeSlash() public {
        uint256 initialDeposit = 500e27;

        vm.prank(validator1);
        rat.registerValidator(systemConfig1, initialDeposit);

        uint32 batchIndex = 1;
        vm.prank(authorizedTrigger);
        rat.triggerAttentionTest(systemConfig1, batchIndex, keccak256("batch1"), keccak256("block1"));

        // testId 가져오기
        bytes32 testId = rat.batchToTestId(systemConfig1, batchIndex);

        // 마감 경과
        vm.warp(block.timestamp + evidenceSubmissionPeriod + 1);

        // 슬래싱 실행
        rat.finalizeSlash(testId);

        // 검증
        (
            uint256 depositedAmount,
            uint256 totalBondForRAT,
            ,
            ,
            ,
            bool isActive
        ) = rat.getValidatorRegistration(validator1, systemConfig1);

        // 담보금: 500 - 100 (선차감) = 400
        assertEq(depositedAmount, 400e27, "Deposit after slash");
        assertEq(totalBondForRAT, 0, "Bond cleared after slash");

        // 400 > D_min(150)이므로 여전히 활성
        assertTrue(isActive, "Should still be active (deposit > D_min)");

        // 누적 슬래싱 확인
        assertEq(rat.accumulatedSlashings(), 100e27, "Accumulated slashings should be C_off");
    }

    /// @notice 슬래싱 후 D_min 미만이면 비활성화
    function test_finalizeSlash_belowThreshold() public {
        // 최소 담보금으로 등록 (200 = C_off + buffer)
        uint256 initialDeposit = minimumDeposit;

        vm.prank(validator1);
        rat.registerValidator(systemConfig1, initialDeposit);

        uint32 batchIndex = 1;
        vm.prank(authorizedTrigger);
        rat.triggerAttentionTest(systemConfig1, batchIndex, keccak256("batch1"), keccak256("block1"));

        bytes32 testId = rat.batchToTestId(systemConfig1, batchIndex);

        // 마감 경과
        vm.warp(block.timestamp + evidenceSubmissionPeriod + 1);

        // 슬래싱 실행
        rat.finalizeSlash(testId);

        // 검증
        (
            uint256 depositedAmount,
            ,
            ,
            ,
            ,
            bool isActive
        ) = rat.getValidatorRegistration(validator1, systemConfig1);

        // 담보금: 200 - 100 (선차감) = 100 < D_min(150)
        assertEq(depositedAmount, 100e27, "Deposit after slash");
        assertFalse(isActive, "Should be deactivated (deposit < D_min)");
        assertEq(rat.getActiveValidatorCount(systemConfig1), 0, "Active count should be 0");
    }

    /// @notice 마감 전 슬래싱 실패
    function test_finalizeSlash_deadlineNotPassed() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1, 500e27);

        uint32 batchIndex = 1;
        vm.prank(authorizedTrigger);
        rat.triggerAttentionTest(systemConfig1, batchIndex, keccak256("batch1"), keccak256("block1"));

        bytes32 testId = rat.batchToTestId(systemConfig1, batchIndex);

        // 마감 전에 슬래싱 시도
        vm.expectRevert();
        rat.finalizeSlash(testId);
    }

    /// @notice 이미 응답한 테스트 슬래싱 실패
    function test_finalizeSlash_alreadyResponded() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1, 500e27);

        uint32 batchIndex = 1;
        vm.prank(authorizedTrigger);
        rat.triggerAttentionTest(systemConfig1, batchIndex, keccak256("batch1"), keccak256("block1"));

        // 증거 제출
        vm.prank(validator1);
        rat.submitEvidence(systemConfig1, batchIndex, "evidence_data");

        bytes32 testId = rat.batchToTestId(systemConfig1, batchIndex);

        // 마감 경과
        vm.warp(block.timestamp + evidenceSubmissionPeriod + 1);

        // 슬래싱 시도
        vm.expectRevert();
        rat.finalizeSlash(testId);
    }

    // ==========================================
    // 보상 분배 테스트
    // ==========================================

    /// @notice 검증자 보상 분배 (v_i = amount / n)
    function test_distributeValidatorReward() public {
        // 3명의 검증자 등록
        vm.prank(validator1);
        rat.registerValidator(systemConfig1, 500e27);
        vm.prank(validator2);
        rat.registerValidator(systemConfig1, 500e27);
        vm.prank(validator3);
        rat.registerValidator(systemConfig1, 500e27);

        // 보상 민트
        uint256 totalReward = 3000e27;
        wton.mint(address(rat), totalReward);

        // SeigManager에서 분배
        vm.prank(seigManager);
        rat.distributeValidatorReward(systemConfig1, totalReward);

        // 각 검증자에게 1000 WTON씩 분배
        assertEq(rat.getPendingRewards(validator1, systemConfig1), 1000e27, "Validator1 reward");
        assertEq(rat.getPendingRewards(validator2, systemConfig1), 1000e27, "Validator2 reward");
        assertEq(rat.getPendingRewards(validator3, systemConfig1), 1000e27, "Validator3 reward");
    }

    /// @notice 보상 청구
    function test_claimRewards() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1, 500e27);

        wton.mint(address(rat), 1000e27);

        vm.prank(seigManager);
        rat.distributeValidatorReward(systemConfig1, 1000e27);

        uint256 balanceBefore = wton.balanceOf(validator1);

        vm.prank(validator1);
        rat.claimRewards(systemConfig1);

        assertEq(rat.getPendingRewards(validator1, systemConfig1), 0, "Pending rewards should be 0");
        assertEq(
            wton.balanceOf(validator1),
            balanceBefore + 1000e27,
            "Balance should increase"
        );
    }

    /// @notice 보상 일괄 청구
    function test_claimRewardsBatch() public {
        // 2개 L2에 등록
        vm.prank(validator1);
        rat.registerValidator(systemConfig1, 500e27);
        vm.prank(validator1);
        rat.registerValidator(systemConfig2, 500e27);

        wton.mint(address(rat), 2000e27);

        vm.prank(seigManager);
        rat.distributeValidatorReward(systemConfig1, 1000e27);
        vm.prank(seigManager);
        rat.distributeValidatorReward(systemConfig2, 1000e27);

        uint256 balanceBefore = wton.balanceOf(validator1);

        address[] memory configs = new address[](2);
        configs[0] = systemConfig1;
        configs[1] = systemConfig2;

        vm.prank(validator1);
        rat.claimRewardsBatch(configs);

        assertEq(
            wton.balanceOf(validator1),
            balanceBefore + 2000e27,
            "Balance should increase by total rewards"
        );
    }

    /// @notice 보상 없을 때 청구 실패
    function test_claimRewards_noRewards() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1, 500e27);

        vm.prank(validator1);
        vm.expectRevert();
        rat.claimRewards(systemConfig1);
    }

    // ==========================================
    // 거버넌스 테스트
    // ==========================================

    /// @notice 슬래싱 페널티 설정 (owner only)
    function test_setSlashingPenalty() public {
        rat.setSlashingPenalty(200e27);
        assertEq(rat.slashingPenalty(), 200e27);
    }

    /// @notice 최소 임계값 설정 (owner only)
    function test_setMinimumThreshold() public {
        rat.setMinimumThreshold(300e27);
        assertEq(rat.minimumThreshold(), 300e27);
    }

    /// @notice 비소유자 설정 실패
    function test_setSlashingPenalty_notOwner() public {
        vm.prank(validator1);
        vm.expectRevert();
        rat.setSlashingPenalty(200e27);
    }

    // ==========================================
    // 백서 공식 (4) 검증 테스트
    // ==========================================

    /// @notice C_off ≥ (c_m · n) / π_a 검증
    function test_validateSlashingPenalty() public {
        // attentionCost 설정 (기본값 0이므로 설정 필요)
        rat.setAttentionCost(0.0001e27); // c_m = 0.01%
        rat.setRatTriggerProbability(0.01e27); // π_a = 1%

        // n = 3
        bool isValid = rat.validateSlashingPenalty(3);

        // C_off(100) >= (c_m(0.0001) * 3) / π_a(0.01) = 0.03
        assertTrue(isValid, "Slashing penalty should be valid for n=3");
    }

    /// @notice 슬래싱 누적 금액 Treasury 전송
    function test_withdrawSlashingsToTreasury() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1, 500e27);

        uint32 batchIndex = 1;
        vm.prank(authorizedTrigger);
        rat.triggerAttentionTest(systemConfig1, batchIndex, keccak256("batch1"), keccak256("block1"));

        bytes32 testId = rat.batchToTestId(systemConfig1, batchIndex);

        vm.warp(block.timestamp + evidenceSubmissionPeriod + 1);
        rat.finalizeSlash(testId);

        uint256 treasuryBefore = wton.balanceOf(treasury);
        rat.withdrawSlashingsToTreasury();

        assertEq(wton.balanceOf(treasury), treasuryBefore + 100e27, "Treasury should receive slashed amount");
        assertEq(rat.accumulatedSlashings(), 0, "Accumulated slashings should be 0");
    }

    /// @notice getTotalPendingRewards 테스트
    function test_getTotalPendingRewards() public {
        // 2개 L2에 등록
        vm.prank(validator1);
        rat.registerValidator(systemConfig1, 500e27);
        vm.prank(validator1);
        rat.registerValidator(systemConfig2, 500e27);

        wton.mint(address(rat), 3000e27);

        vm.prank(seigManager);
        rat.distributeValidatorReward(systemConfig1, 1000e27);
        vm.prank(seigManager);
        rat.distributeValidatorReward(systemConfig2, 2000e27);

        uint256 totalRewards = rat.getTotalPendingRewards(validator1);
        assertEq(totalRewards, 3000e27, "Total pending rewards should be sum of all L2s");
    }
}
