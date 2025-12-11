// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import {ValidatorPoolV1} from "../../src/validator/ValidatorPoolV1.sol";
import {MockWTON} from "./mocks/MockWTON.sol";
import {MockTON} from "./mocks/MockTON.sol";

/// @title ValidatorPoolV1Test
/// @notice ValidatorPoolV1 단위 테스트
/// @dev Tokamak Economics Whitepaper V2 (December 9, 2025) 기준
contract ValidatorPoolV1Test is Test {
    ValidatorPoolV1 public validatorPool;
    MockWTON public wton;
    MockTON public ton;

    address public owner = address(this);
    address public seigManager = address(0x1);
    address public ratIssuer = address(0x2);
    address public validator1 = address(0x100);
    address public validator2 = address(0x200);
    address public validator3 = address(0x300);

    uint256 internal constant RAY = 1e27;

    // 백서 V2 기본값
    uint256 public slashingPenalty = 100e27;       // C_off = 100 WTON
    uint256 public validatorBuffer = 100e27;       // Δ_validator = 100 WTON
    uint256 public minimumThreshold = 150e27;      // D_min = 150 WTON
    uint256 public minimumDeposit = 200e27;        // D_validator = C_off + Δ_validator

    function setUp() public {
        // Deploy mocks
        wton = new MockWTON();
        ton = new MockTON();
        wton.setTON(address(ton));

        // Deploy ValidatorPool
        validatorPool = new ValidatorPoolV1();
        validatorPool.initialize(
            seigManager,
            address(wton),
            address(ton),
            owner
        );

        // 백서 V2 파라미터 설정
        validatorPool.setSlashingPenalty(slashingPenalty);
        validatorPool.setValidatorBuffer(validatorBuffer);
        validatorPool.setMinimumThreshold(minimumThreshold);
        validatorPool.setRatIssuer(ratIssuer);

        // Mint WTON to validators
        wton.mint(validator1, 10000e27);
        wton.mint(validator2, 10000e27);
        wton.mint(validator3, 10000e27);

        // Approve
        vm.prank(validator1);
        wton.approve(address(validatorPool), type(uint256).max);
        vm.prank(validator2);
        wton.approve(address(validatorPool), type(uint256).max);
        vm.prank(validator3);
        wton.approve(address(validatorPool), type(uint256).max);
    }

    // ==========================================
    // 검증자 등록 테스트
    // ==========================================

    /// @notice 백서 공식 (5): D_validator = C_off + Δ_validator
    function test_getMinimumDeposit() public view {
        uint256 minDeposit = validatorPool.getMinimumDeposit();

        // D_validator = slashingPenalty + validatorBuffer = 100 + 100 = 200
        assertEq(minDeposit, slashingPenalty + validatorBuffer, "Minimum deposit calculation");
    }

    /// @notice 검증자 등록 성공
    function test_registerValidator_success() public {
        uint256 depositAmount = 500e27;

        vm.prank(validator1);
        validatorPool.registerValidator(depositAmount);

        // 검증
        (
            bool isActive,
            uint256 depositAmt,
            ,
            ,
        ) = validatorPool.getValidatorInfo(validator1);

        assertTrue(isActive, "Validator should be active");
        assertEq(depositAmt, depositAmount, "Deposit amount should match");
        assertEq(validatorPool.activeValidatorCount(), 1, "Active count should be 1");
    }

    /// @notice 불충분한 담보금으로 등록 실패
    function test_registerValidator_insufficientDeposit() public {
        uint256 minDeposit = validatorPool.getMinimumDeposit();
        uint256 insufficientDeposit = minDeposit - 1;

        vm.prank(validator1);
        vm.expectRevert();
        validatorPool.registerValidator(insufficientDeposit);
    }

    /// @notice 중복 등록 실패
    function test_registerValidator_alreadyRegistered() public {
        vm.prank(validator1);
        validatorPool.registerValidator(500e27);

        vm.prank(validator1);
        vm.expectRevert();
        validatorPool.registerValidator(500e27);
    }

    /// @notice 여러 검증자 등록
    function test_registerMultipleValidators() public {
        vm.prank(validator1);
        validatorPool.registerValidator(500e27);

        vm.prank(validator2);
        validatorPool.registerValidator(600e27);

        vm.prank(validator3);
        validatorPool.registerValidator(700e27);

        assertEq(validatorPool.activeValidatorCount(), 3, "Should have 3 active validators");

        address[] memory validators = validatorPool.getValidators();
        assertEq(validators.length, 3, "Validators array length");
        assertEq(validators[0], validator1, "First validator");
        assertEq(validators[1], validator2, "Second validator");
        assertEq(validators[2], validator3, "Third validator");
    }

    // ==========================================
    // 담보금 추가 테스트
    // ==========================================

    /// @notice 담보금 추가
    function test_addDeposit() public {
        vm.prank(validator1);
        validatorPool.registerValidator(500e27);

        vm.prank(validator1);
        validatorPool.addDeposit(200e27);

        (
            ,
            uint256 depositAmt,
            ,
            ,
        ) = validatorPool.getValidatorInfo(validator1);

        assertEq(depositAmt, 700e27, "Deposit should be increased");
    }

    /// @notice 비활성 검증자 담보금 추가 실패
    function test_addDeposit_notActive() public {
        vm.prank(validator1);
        vm.expectRevert();
        validatorPool.addDeposit(200e27);
    }

    // ==========================================
    // 검증자 비활성화 테스트
    // ==========================================

    /// @notice 검증자 비활성화
    function test_deactivateValidator() public {
        uint256 depositAmount = 500e27;

        vm.prank(validator1);
        validatorPool.registerValidator(depositAmount);

        uint256 balanceBefore = wton.balanceOf(validator1);

        vm.prank(validator1);
        validatorPool.deactivateValidator();

        // 검증
        (
            bool isActive,
            uint256 depositAmt,
            ,
            ,
        ) = validatorPool.getValidatorInfo(validator1);

        assertFalse(isActive, "Validator should be inactive");
        assertEq(depositAmt, 0, "Deposit should be 0");
        assertEq(validatorPool.activeValidatorCount(), 0, "Active count should be 0");

        // 담보금 반환 확인
        assertEq(
            wton.balanceOf(validator1),
            balanceBefore + depositAmount,
            "Deposit should be returned"
        );
    }

    // ==========================================
    // RAT 테스트
    // ==========================================

    /// @notice RAT 발행 (이 컨트랙트에서는 ratIssuer만 가능)
    function test_issueRAT() public {
        vm.prank(validator1);
        validatorPool.registerValidator(500e27);

        // RATIssuer로 호출
        vm.prank(ratIssuer);
        validatorPool.issueRAT(validator1, 1);

        // 챌린지 확인은 내부 상태 확인 필요
    }

    /// @notice RAT 응답
    function test_respondToRAT() public {
        vm.prank(validator1);
        validatorPool.registerValidator(500e27);

        vm.prank(ratIssuer);
        validatorPool.issueRAT(validator1, 1);

        vm.prank(validator1);
        validatorPool.respondToRAT(1, true);

        // lastRATResponse 업데이트 확인
        (
            ,
            ,
            ,
            ,
            uint256 lastRATResponse
        ) = validatorPool.getValidatorInfo(validator1);

        assertEq(lastRATResponse, block.timestamp, "lastRATResponse should be updated");
    }

    // ==========================================
    // 슬래싱 테스트 (백서 V2)
    // ==========================================

    /// @notice 백서 V2: C_off 기반 슬래싱
    function test_slashUnresponsiveValidator() public {
        uint256 initialDeposit = 500e27;

        vm.prank(validator1);
        validatorPool.registerValidator(initialDeposit);

        // RAT 발행
        vm.prank(ratIssuer);
        validatorPool.issueRAT(validator1, 1);

        // 응답 윈도우 경과
        vm.warp(block.timestamp + 2 hours);

        // 슬래싱
        validatorPool.slashUnresponsiveValidator(validator1, 1);

        (
            bool isActive,
            uint256 depositAmt,
            ,
            ,
        ) = validatorPool.getValidatorInfo(validator1);

        // C_off만 슬래싱 (100 WTON)
        uint256 expectedDeposit = initialDeposit - slashingPenalty;
        assertEq(depositAmt, expectedDeposit, "Should only slash C_off");

        // D_min (150) 이상이므로 여전히 활성
        assertTrue(isActive, "Should still be active (deposit > D_min)");
    }

    /// @notice 슬래싱 후 D_min 미만이면 비활성화
    function test_slashUnresponsiveValidator_belowThreshold() public {
        // 최소 담보금으로 등록 (200 = C_off + buffer)
        uint256 initialDeposit = minimumDeposit;

        vm.prank(validator1);
        validatorPool.registerValidator(initialDeposit);

        // RAT 발행
        vm.prank(ratIssuer);
        validatorPool.issueRAT(validator1, 1);

        // 응답 윈도우 경과
        vm.warp(block.timestamp + 2 hours);

        // 슬래싱
        validatorPool.slashUnresponsiveValidator(validator1, 1);

        (
            bool isActive,
            uint256 depositAmt,
            ,
            ,
        ) = validatorPool.getValidatorInfo(validator1);

        // C_off 슬래싱 후 100 WTON 남음 (< D_min = 150)
        assertEq(depositAmt, initialDeposit - slashingPenalty, "Remaining deposit");
        assertFalse(isActive, "Should be deactivated (deposit < D_min)");
        assertEq(validatorPool.activeValidatorCount(), 0, "Active count should be 0");
    }

    /// @notice 이미 응답한 RAT에 대한 슬래싱 실패
    function test_slashUnresponsiveValidator_alreadyResponded() public {
        vm.prank(validator1);
        validatorPool.registerValidator(500e27);

        vm.prank(ratIssuer);
        validatorPool.issueRAT(validator1, 1);

        vm.prank(validator1);
        validatorPool.respondToRAT(1, true);

        vm.warp(block.timestamp + 2 hours);

        vm.expectRevert();
        validatorPool.slashUnresponsiveValidator(validator1, 1);
    }

    /// @notice 마감 전 슬래싱 실패
    function test_slashUnresponsiveValidator_deadlineNotPassed() public {
        vm.prank(validator1);
        validatorPool.registerValidator(500e27);

        vm.prank(ratIssuer);
        validatorPool.issueRAT(validator1, 1);

        // 마감 전에 슬래싱 시도
        vm.expectRevert();
        validatorPool.slashUnresponsiveValidator(validator1, 1);
    }

    // ==========================================
    // 보상 분배 테스트
    // ==========================================

    /// @notice 백서 공식 (13): v_i = (α/n) · y(x)
    function test_distributePeriodRewards() public {
        // 3명의 검증자 등록
        vm.prank(validator1);
        validatorPool.registerValidator(500e27);
        vm.prank(validator2);
        validatorPool.registerValidator(500e27);
        vm.prank(validator3);
        validatorPool.registerValidator(500e27);

        // 보상 민트
        uint256 totalReward = 3000e27; // α · y(x) = 3000 WTON
        wton.mint(address(validatorPool), totalReward);

        // SeigManager에서 분배
        vm.prank(seigManager);
        validatorPool.distributePeriodRewards(1, totalReward);

        // 각 검증자에게 1000 WTON씩 분배
        (
            ,
            ,
            uint256 pendingRewards1,
            ,
        ) = validatorPool.getValidatorInfo(validator1);
        (
            ,
            ,
            uint256 pendingRewards2,
            ,
        ) = validatorPool.getValidatorInfo(validator2);
        (
            ,
            ,
            uint256 pendingRewards3,
            ,
        ) = validatorPool.getValidatorInfo(validator3);

        assertEq(pendingRewards1, 1000e27, "Validator1 reward");
        assertEq(pendingRewards2, 1000e27, "Validator2 reward");
        assertEq(pendingRewards3, 1000e27, "Validator3 reward");
    }

    /// @notice 보상 청구
    function test_claimRewards() public {
        vm.prank(validator1);
        validatorPool.registerValidator(500e27);

        wton.mint(address(validatorPool), 1000e27);

        vm.prank(seigManager);
        validatorPool.distributePeriodRewards(1, 1000e27);

        uint256 balanceBefore = wton.balanceOf(validator1);

        vm.prank(validator1);
        validatorPool.claimRewards();

        (
            ,
            ,
            uint256 pendingRewards,
            ,
        ) = validatorPool.getValidatorInfo(validator1);

        assertEq(pendingRewards, 0, "Pending rewards should be 0");
        assertEq(
            wton.balanceOf(validator1),
            balanceBefore + 1000e27,
            "Balance should increase"
        );
    }

    /// @notice 보상 없을 때 청구 실패
    function test_claimRewards_noRewards() public {
        vm.prank(validator1);
        validatorPool.registerValidator(500e27);

        vm.prank(validator1);
        vm.expectRevert();
        validatorPool.claimRewards();
    }

    // ==========================================
    // 거버넌스 테스트
    // ==========================================

    /// @notice 슬래싱 페널티 설정 (owner only)
    function test_setSlashingPenalty() public {
        validatorPool.setSlashingPenalty(200e27);
        assertEq(validatorPool.slashingPenalty(), 200e27);
    }

    /// @notice 최소 임계값 설정 (owner only)
    function test_setMinimumThreshold() public {
        validatorPool.setMinimumThreshold(300e27);
        assertEq(validatorPool.minimumThreshold(), 300e27);
    }

    /// @notice 비소유자 설정 실패
    function test_setSlashingPenalty_notOwner() public {
        vm.prank(validator1);
        vm.expectRevert();
        validatorPool.setSlashingPenalty(200e27);
    }

    // ==========================================
    // 백서 공식 (4) 검증 테스트
    // ==========================================

    /// @notice C_off ≥ (c_m · n) / π_a 검증
    function test_validateSlashingPenalty() public view {
        // n = 3
        bool isValid = validatorPool.validateSlashingPenalty(3);

        // attentionCost와 ratProbability에 따라 결과가 달라짐
        // 기본 설정에서는 유효해야 함
        assertTrue(isValid, "Slashing penalty should be valid for n=3");
    }
}
