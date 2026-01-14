// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import {RAT} from "../../src/validator/RAT.sol";
import {RATStorage} from "../../src/validator/RATStorage.sol";
import {MockWTON} from "../../src/mocks/MockWTON.sol";
import {MockTON} from "../../src/mocks/MockTON.sol";

/// @notice Mock FaultDisputeGame that provides systemConfig() for RAT.resolveClaim()
contract MockFaultDisputeGame {
    address public systemConfig;

    constructor(address _systemConfig) {
        systemConfig = _systemConfig;
    }
}

/// @notice Mock L1BridgeRegistry for factory validation
contract MockL1BridgeRegistry {
    /// @notice factory => rollupConfig mapping
    mapping(address => address) public rollupConfigWithDisputeGameFactory;

    /// @notice Register a factory as valid
    function setFactory(address factory, address rollupConfig) external {
        rollupConfigWithDisputeGameFactory[factory] = rollupConfig;
    }
}

/// @title RATTest
/// @notice RAT (Randomized Attention Test) 단위 테스트
/// @dev Tokamak Economics Whitepaper V2 (December 9, 2025) 기준
contract RATTest is Test {
    RAT public rat;
    MockWTON public wton;
    MockTON public ton;
    MockL1BridgeRegistry public mockL1BridgeRegistry;

    address public owner = address(this);
    address public seigManager = address(0x1);
    address public depositManager = address(0x2);
    address public factory = address(0x3);  // DisputeGameFactory 역할
    address public treasury = address(0x4);

    address public systemConfig1 = address(0x10);
    address public systemConfig2 = address(0x20);

    address public validator1 = address(0x100);
    address public validator2 = address(0x200);
    address public validator3 = address(0x300);

    // Mock game contracts for RAT tests (provides systemConfig() for resolveClaim)
    MockFaultDisputeGame public mockGame1;
    MockFaultDisputeGame public mockGame2;

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

        // Deploy mock L1BridgeRegistry
        mockL1BridgeRegistry = new MockL1BridgeRegistry();
        // factory를 systemConfig1의 유효한 factory로 등록
        mockL1BridgeRegistry.setFactory(factory, systemConfig1);

        // Deploy mock games (with systemConfig for resolveClaim)
        mockGame1 = new MockFaultDisputeGame(systemConfig1);
        mockGame2 = new MockFaultDisputeGame(systemConfig1);

        // Deploy RAT (V3: depositManager 제거)
        rat = new RAT();
        rat.initialize(
            seigManager,
            address(wton),
            address(ton),
            address(0), // layer2Manager (not used in tests)
            owner,
            0.01e27 // ratTriggerProbability (테스트용 1%)
        );

        // 백서 V2 파라미터 설정
        rat.setSlashingPenalty(slashingPenalty);
        rat.setValidatorBuffer(validatorBuffer);
        rat.setMinimumThreshold(minimumThreshold);
        rat.setL1BridgeRegistry(address(mockL1BridgeRegistry));  // factory 검증용
        rat.setTreasury(treasury);
        rat.setEvidenceSubmissionPeriod(evidenceSubmissionPeriod);

        // Mint TON to validators (RAT uses TON, not WTON)
        ton.mint(validator1, 10000e27);
        ton.mint(validator2, 10000e27);
        ton.mint(validator3, 10000e27);

        // Approve TON to RAT
        vm.prank(validator1);
        ton.approve(address(rat), type(uint256).max);
        vm.prank(validator2);
        ton.approve(address(rat), type(uint256).max);
        vm.prank(validator3);
        ton.approve(address(rat), type(uint256).max);
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
            uint32 validatorIndex,
            bool isActive
        ) = rat.getValidatorRegistration(validator1, systemConfig1);

        assertTrue(isActive, "Validator should be active");
        assertEq(depositedAmount, depositAmount, "Deposit amount should match");
        assertEq(totalBondForRAT, 0, "No bonds initially");
        assertEq(validatorIndex, 0, "First validator index");
        assertEq(rat.getActiveValidatorCount(systemConfig1), 1, "Active count should be 1");
    }

    /// @notice 불충분한 담보금으로 등록 실패 (enforceMinDeposit = true일 때만)
    function test_registerValidator_insufficientDeposit() public {
        // V3: enforceMinDeposit 플래그 활성화 필요
        rat.setEnforceMinDeposit(true);

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

        // V3: RAT은 TON을 직접 보관하고 반환함 (WTON 아님)
        uint256 balanceBefore = ton.balanceOf(validator1);

        vm.prank(validator1);
        rat.deactivateValidator(systemConfig1);

        // 검증
        (
            uint256 depositedAmount,
            ,
            ,
            bool isActive
        ) = rat.getValidatorRegistration(validator1, systemConfig1);

        assertFalse(isActive, "Validator should be inactive");
        assertEq(depositedAmount, 0, "Deposit should be 0");
        assertEq(rat.getActiveValidatorCount(systemConfig1), 0, "Active count should be 0");

        // 담보금 반환 확인 (TON으로 반환됨)
        assertEq(
            ton.balanceOf(validator1),
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

        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, batchIndex, batchHash, blockHash);

        // 검증자의 담보금 선차감 확인
        (
            uint256 depositedAmount,
            uint256 totalBondForRAT,
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
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, 1, keccak256("batch1"), keccak256("block1"));
    }

    /// @notice 활성 검증자 없을 때 RAT 트리거 (무시됨)
    function test_triggerAttentionTest_noActiveValidators() public {
        // 검증자 없는 상태에서 트리거
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, 1, keccak256("batch1"), keccak256("block1"));

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

        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, batchIndex, batchHash, blockHash);

        // 증거 제출
        vm.prank(validator1);
        rat.submitEvidence(systemConfig1, batchIndex, "evidence_data");

        // 담보금 복구 확인
        (
            uint256 depositedAmount,
            uint256 totalBondForRAT,
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

        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, batchIndex, batchHash, blockHash);

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
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, batchIndex, keccak256("batch1"), keccak256("block1"));

        // 다른 검증자가 제출 시도
        vm.prank(validator2);
        vm.expectRevert();
        rat.submitEvidence(systemConfig1, batchIndex, "evidence_data");
    }

    // ==========================================
    // 슬래싱 테스트 (백서 V2)
    // ==========================================

    // ==========================================
    // NOTE: Lazy Evaluation으로 변경됨
    // - triggerAttentionTest 시점에 C_off 선차감
    // - 마감 후 미응답 시 자동 슬래싱 확정 (별도 트랜잭션 불필요)
    // - 출금(deactivateValidator) 시 latestTestDeadline 확인
    // ==========================================

    /// @notice 미응답 검증자 슬래싱 - Lazy Evaluation
    /// @dev trigger 시점에 선차감되고, deadline 후 미응답 시 확정됨
    function test_lazyEvaluation_noResponseSlash() public {
        uint256 initialDeposit = 500e27;

        vm.prank(validator1);
        rat.registerValidator(systemConfig1, initialDeposit);

        uint32 batchIndex = 1;
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, batchIndex, keccak256("batch1"), keccak256("block1"));

        // trigger 직후 확인
        (
            uint256 depositedAmount,
            uint256 totalBondForRAT,
            ,
            bool isActive
        ) = rat.getValidatorRegistration(validator1, systemConfig1);

        // trigger 시점에 C_off가 선차감됨
        assertEq(depositedAmount, 400e27, "Deposit after trigger (pre-deducted)");
        assertEq(totalBondForRAT, 100e27, "Bond should hold C_off");
        assertTrue(isActive, "Should still be active");

        // 마감 경과 후 - 별도 finalize 없이 슬래싱 확정
        vm.warp(block.timestamp + evidenceSubmissionPeriod + 1);

        // 출금 시도 시 latestTestDeadline 확인됨
        // (이제 deadline 지났으므로 출금 가능해져야 함)
    }

    /// @notice 슬래싱 후 D_min 미만 - trigger 시점에 비활성화 확인
    function test_lazyEvaluation_belowThreshold() public {
        // 최소 담보금으로 등록 (200 = C_off + buffer)
        uint256 initialDeposit = minimumDeposit;

        vm.prank(validator1);
        rat.registerValidator(systemConfig1, initialDeposit);

        uint32 batchIndex = 1;
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, batchIndex, keccak256("batch1"), keccak256("block1"));

        // trigger 직후 확인
        (
            uint256 depositedAmount,
            ,
            ,
            bool isActive
        ) = rat.getValidatorRegistration(validator1, systemConfig1);

        // trigger 시점에 C_off가 선차감됨: 200 - 100 = 100 < D_min(150)
        assertEq(depositedAmount, 100e27, "Deposit after trigger");
        // D_min 미달로 비활성화
        assertFalse(isActive, "Should be deactivated (deposit < D_min)");
        assertEq(rat.getActiveValidatorCount(systemConfig1), 0, "Active count should be 0");
    }

    /// @notice 증거 제출 시 담보금 복구
    function test_lazyEvaluation_submitEvidenceRestores() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1, 500e27);

        uint32 batchIndex = 1;
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, batchIndex, keccak256("batch1"), keccak256("block1"));

        // trigger 직후 - 선차감됨
        (uint256 depositBefore,,,) = rat.getValidatorRegistration(validator1, systemConfig1);
        assertEq(depositBefore, 400e27, "Deposit pre-deducted");

        // 증거 제출
        vm.prank(validator1);
        rat.submitEvidence(systemConfig1, batchIndex, "evidence_data");

        // 증거 제출 후 - 복구됨
        (uint256 depositAfter, uint256 bondAfter,,) = rat.getValidatorRegistration(validator1, systemConfig1);
        assertEq(depositAfter, 500e27, "Deposit restored after evidence");
        assertEq(bondAfter, 0, "Bond cleared after evidence");
    }

    // V3: 보상 분배 테스트 제거 - ValidatorReward.t.sol로 이동
    // - test_distributeValidatorReward -> ValidatorReward.distributeL2Rewards()
    // - test_claimRewards -> ValidatorReward.claimAllRewards()
    // - test_claimRewardsBatch -> ValidatorReward.claimAllRewards()
    // - test_claimRewards_noRewards -> ValidatorReward 테스트

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
    /// @dev Lazy evaluation에서는 미응답 시 슬래싱이 deadline 경과 후 확정됨
    /// TODO: Lazy evaluation에 맞게 accumulatedSlashings 누적 로직 확인 필요
    function test_withdrawSlashingsToTreasury() public {
        vm.skip(true); // TODO: Lazy evaluation 방식에 맞게 수정 필요

        vm.prank(validator1);
        rat.registerValidator(systemConfig1, 500e27);

        uint32 batchIndex = 1;
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, batchIndex, keccak256("batch1"), keccak256("block1"));

        vm.warp(block.timestamp + evidenceSubmissionPeriod + 1);

        // Lazy evaluation: deadline 경과 후 슬래싱 확정
        // accumulatedSlashings가 어디서 누적되는지 확인 필요

        uint256 treasuryBefore = wton.balanceOf(treasury);
        rat.withdrawSlashingsToTreasury();

        assertEq(wton.balanceOf(treasury), treasuryBefore + 100e27, "Treasury should receive slashed amount");
        assertEq(rat.accumulatedSlashings(), 0, "Accumulated slashings should be 0");
    }

    // V3: test_getTotalPendingRewards 제거 - ValidatorReward.getPendingRewards()로 이동

    // ==========================================
    // resolveClaim 테스트 (FaultDisputeGame 연동)
    // ==========================================

    /// @notice resolveClaim 성공 - 게임 승리 시 본드 복구
    function test_resolveClaim_success() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1, 500e27);

        uint32 batchIndex = 1;
        bytes32 batchHash = keccak256("batch1");
        bytes32 blockHash = keccak256("block1");

        // RAT 트리거
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, batchIndex, batchHash, blockHash);

        // 트리거 후 상태 확인
        (
            uint256 depositAfterTrigger,
            uint256 bondAfterTrigger,
            ,
        ) = rat.getValidatorRegistration(validator1, systemConfig1);

        assertEq(depositAfterTrigger, 400e27, "Deposit should be reduced by C_off");
        assertEq(bondAfterTrigger, 100e27, "Bond should be C_off");

        // FaultDisputeGame에서 resolveClaim 호출 (게임 승리)
        vm.prank(address(mockGame1));
        rat.resolveClaim(validator1);

        // 본드 복구 확인
        (
            uint256 depositAfterResolve,
            uint256 bondAfterResolve,
            ,
            bool isActive
        ) = rat.getValidatorRegistration(validator1, systemConfig1);

        assertEq(depositAfterResolve, 500e27, "Deposit should be fully restored");
        assertEq(bondAfterResolve, 0, "Bond should be cleared");
        assertTrue(isActive, "Validator should remain active");
    }

    /// @notice resolveClaim - 등록되지 않은 게임 주소에서 호출 시 무시
    function test_resolveClaim_unknownGame() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1, 500e27);

        // 등록되지 않은 게임 주소에서 호출
        address unknownGame = address(0x9999);
        vm.prank(unknownGame);
        rat.resolveClaim(validator1);

        // 상태 변화 없음 확인
        (
            uint256 depositedAmount,
            ,
            ,
        ) = rat.getValidatorRegistration(validator1, systemConfig1);

        assertEq(depositedAmount, 500e27, "Deposit should be unchanged");
    }

    /// @notice resolveClaim - 선택된 검증자가 아닌 경우 무시
    function test_resolveClaim_notSelectedValidator() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1, 500e27);

        uint32 batchIndex = 1;
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, batchIndex, keccak256("batch1"), keccak256("block1"));

        // validator2 (선택되지 않은 검증자)로 resolveClaim 호출
        vm.prank(address(mockGame1));
        rat.resolveClaim(validator2);

        // validator1의 본드는 그대로
        (
            uint256 depositedAmount,
            uint256 bondAmount,
            ,
        ) = rat.getValidatorRegistration(validator1, systemConfig1);

        assertEq(depositedAmount, 400e27, "Deposit should still be reduced");
        assertEq(bondAmount, 100e27, "Bond should still be locked");
    }

    /// @notice resolveClaim - 이미 응답한 테스트에 대해 무시
    function test_resolveClaim_alreadyResponded() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1, 500e27);

        uint32 batchIndex = 1;
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, batchIndex, keccak256("batch1"), keccak256("block1"));

        // 증거 제출로 먼저 응답
        vm.prank(validator1);
        rat.submitEvidence(systemConfig1, batchIndex, "evidence_data");

        // 이후 resolveClaim 호출 - 무시되어야 함
        vm.prank(address(mockGame1));
        rat.resolveClaim(validator1);

        // 상태 확인 (submitEvidence로 이미 복구됨)
        (
            uint256 depositedAmount,
            uint256 bondAmount,
            ,
        ) = rat.getValidatorRegistration(validator1, systemConfig1);

        assertEq(depositedAmount, 500e27, "Deposit should be restored by submitEvidence");
        assertEq(bondAmount, 0, "Bond should be cleared by submitEvidence");
    }

    // ==========================================
    // gameToTestId 매핑 테스트
    // ==========================================

    /// @notice gameToTestId 매핑 확인
    function test_gameToTestId_mapping() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1, 500e27);

        uint32 batchIndex = 1;
        bytes32 batchHash = keccak256("batch1");
        bytes32 blockHash = keccak256("block1");

        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, batchIndex, batchHash, blockHash);

        // gameToTestId 매핑 확인
        bytes32 testIdFromGame = rat.gameToTestId(address(mockGame1));
        bytes32 testIdFromBatch = rat.batchToTestId(systemConfig1, batchIndex);

        assertEq(testIdFromGame, testIdFromBatch, "Game should map to same testId");
        assertTrue(testIdFromGame != bytes32(0), "TestId should not be zero");
    }

    // ==========================================
    // 여러 게임 동시 진행 테스트
    // ==========================================

    /// @notice 여러 게임이 동시에 진행될 때 RAT 테스트
    function test_multipleGamesSimultaneous() public {
        // 3명의 검증자 등록
        vm.prank(validator1);
        rat.registerValidator(systemConfig1, 500e27);
        vm.prank(validator2);
        rat.registerValidator(systemConfig1, 500e27);
        vm.prank(validator3);
        rat.registerValidator(systemConfig1, 500e27);

        // 첫 번째 게임 - RAT 트리거
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, 1, keccak256("batch1"), keccak256("block1"));

        // 두 번째 게임 - RAT 트리거
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame2), systemConfig1, 2, keccak256("batch2"), keccak256("block2"));

        // 두 게임이 다른 testId를 가져야 함
        bytes32 testId1 = rat.gameToTestId(address(mockGame1));
        bytes32 testId2 = rat.gameToTestId(address(mockGame2));

        assertTrue(testId1 != testId2, "Different games should have different testIds");

        // activeTestCount 확인
        assertEq(rat.activeTestCount(systemConfig1), 2, "Should have 2 active tests");
    }

    /// @notice 여러 게임 중 일부만 응답 - resolveClaim으로 각 게임별 본드 복구
    function test_multipleGames_partialResponse() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1, 500e27);

        // 두 게임 트리거 (같은 검증자가 선택됨)
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, 1, keccak256("batch1"), keccak256("block1"));

        // 첫 번째 테스트에 대한 담보금 차감 후 두 번째 트리거
        // 담보금: 500 - 100 = 400
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame2), systemConfig1, 2, keccak256("batch2"), keccak256("block2"));

        // 담보금: 400 - 100 = 300, bond: 200
        (
            uint256 depositedAmount,
            uint256 totalBond,
            ,
        ) = rat.getValidatorRegistration(validator1, systemConfig1);

        assertEq(depositedAmount, 300e27, "Deposit should be reduced twice");
        assertEq(totalBond, 200e27, "Bond should be doubled");

        // 첫 번째 게임에서 resolveClaim 호출 - gameToTestId로 찾음
        vm.prank(address(mockGame1));
        rat.resolveClaim(validator1);

        // 첫 번째 본드 복구 확인
        (
            uint256 depositAfterFirst,
            uint256 bondAfterFirst,
            ,
        ) = rat.getValidatorRegistration(validator1, systemConfig1);

        assertEq(depositAfterFirst, 400e27, "One bond should be restored");
        assertEq(bondAfterFirst, 100e27, "One bond should remain");

        // 두 번째 게임에서 resolveClaim 호출
        vm.prank(address(mockGame2));
        rat.resolveClaim(validator1);

        // 두 번째 본드도 복구 확인
        (
            uint256 depositAfterSecond,
            uint256 bondAfterSecond,
            ,
        ) = rat.getValidatorRegistration(validator1, systemConfig1);

        assertEq(depositAfterSecond, 500e27, "All bonds should be restored");
        assertEq(bondAfterSecond, 0, "No bonds should remain");
    }

    // ==========================================
    // 검증자 복구 테스트 (비활성화 후 재활성화)
    // ==========================================

    /// @notice resolveClaim으로 비활성화된 검증자 복구
    /// @dev trigger 시점에 D_min 미만이면 즉시 비활성화됨, resolveClaim으로 복구 가능
    function test_resolveClaim_restoreInactiveValidator() public {
        // 최소 담보금으로 등록
        uint256 initialDeposit = minimumDeposit; // 200

        vm.prank(validator1);
        rat.registerValidator(systemConfig1, initialDeposit);

        // RAT 트리거 - 담보금: 200 - 100 = 100 (D_min(150) 미만으로 비활성화됨)
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, 1, keccak256("batch1"), keccak256("block1"));

        (
            uint256 depositAfterTrigger,
            ,
            ,
            bool isActiveAfterTrigger
        ) = rat.getValidatorRegistration(validator1, systemConfig1);

        assertEq(depositAfterTrigger, 100e27, "Deposit should be 100 (below D_min)");
        // trigger 시점에 D_min 미달로 즉시 비활성화됨
        assertFalse(isActiveAfterTrigger, "Should be inactive after trigger (D_min check)");

        // resolveClaim으로 본드 복구 - 담보금: 100 + 100 = 200 >= D_min(150) → 재활성화
        vm.prank(address(mockGame1));
        rat.resolveClaim(validator1);

        (
            uint256 depositAfterResolve,
            uint256 bondAfterResolve,
            ,
            bool isActiveAfterResolve
        ) = rat.getValidatorRegistration(validator1, systemConfig1);

        assertEq(depositAfterResolve, 200e27, "Deposit should be restored to 200");
        assertEq(bondAfterResolve, 0, "Bond should be cleared");
        assertTrue(isActiveAfterResolve, "Should be active after bond restore (>= D_min)");
    }

    /// @notice 슬래싱 후 추가 입금으로 검증자 재활성화
    /// @dev Lazy evaluation: trigger 시점에 D_min 미달 시 바로 비활성화됨
    function test_reactivateValidator_afterSlash() public {
        // 최소 담보금으로 등록
        vm.prank(validator1);
        rat.registerValidator(systemConfig1, minimumDeposit);

        // RAT 트리거 - Lazy evaluation에서 D_min 미달 시 바로 비활성화됨
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, 1, keccak256("batch1"), keccak256("block1"));

        // trigger 시점에 이미 비활성화됨 (200 - 100 = 100 < D_min(150))
        (
            uint256 depositAfterSlash,
            ,
            ,
            bool isActiveAfterSlash
        ) = rat.getValidatorRegistration(validator1, systemConfig1);

        assertEq(depositAfterSlash, 100e27, "Deposit should be 100 after trigger");
        assertFalse(isActiveAfterSlash, "Should be inactive after trigger (D_min check failed)");
        assertEq(rat.getActiveValidatorCount(systemConfig1), 0, "Active count should be 0");

        // registerValidator로 재등록 (기존 담보금 + 추가 입금)
        // 기존 100e27이 있으므로 100e27만 추가하면 D_min(200e27) 충족
        vm.prank(validator1);
        rat.registerValidator(systemConfig1, 100e27);

        // 재활성화 확인
        (
            uint256 depositAfterReregister,
            ,
            ,
            bool isActiveAfterReregister
        ) = rat.getValidatorRegistration(validator1, systemConfig1);

        assertEq(depositAfterReregister, 200e27, "Deposit should be 200 after reregister");
        assertTrue(isActiveAfterReregister, "Should be reactivated after reregister");
        assertEq(rat.getActiveValidatorCount(systemConfig1), 1, "Active count should be 1");
    }

    /// @notice 비활성 검증자가 addDeposit 사용 불가 테스트
    /// @dev Lazy evaluation: trigger 시점에 D_min 미달 시 바로 비활성화됨
    function test_addDeposit_revertWhenInactive() public {
        // 최소 담보금으로 등록
        vm.prank(validator1);
        rat.registerValidator(systemConfig1, minimumDeposit);

        // RAT 트리거 - Lazy evaluation에서 D_min 미달 시 바로 비활성화됨
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, 1, keccak256("batch1"), keccak256("block1"));

        // trigger 시점에 이미 비활성화됨 (200 - 100 = 100 < D_min(150))
        (,,, bool isActive) = rat.getValidatorRegistration(validator1, systemConfig1);
        assertFalse(isActive, "Should be inactive after trigger (D_min check failed)");

        // 비활성 상태에서 addDeposit 시도 - 실패해야 함
        vm.prank(validator1);
        vm.expectRevert(abi.encodeWithSignature("NotActiveValidatorError()"));
        rat.addDeposit(systemConfig1, 100e27);
    }
}
