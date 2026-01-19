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
    mapping(address => address) public rollupConfigWithDisputeGameFactory;

    function setFactory(address factory, address rollupConfig) external {
        rollupConfigWithDisputeGameFactory[factory] = rollupConfig;
    }
}

/// @notice Mock Layer2Manager for V3
contract MockLayer2Manager {
    mapping(address => address) public systemConfigToLayer2;

    function setLayer2(address systemConfig, address layer2) external {
        systemConfigToLayer2[systemConfig] = layer2;
    }

    function getLayer2BySystemConfig(address systemConfig) external view returns (address) {
        return systemConfigToLayer2[systemConfig];
    }
}

/// @notice Mock SeigManager for V3
contract MockSeigManager {
    address public ratContract;
    mapping(address => mapping(address => uint256)) public stakes;

    function setRATContract(address _rat) external {
        ratContract = _rat;
    }

    function setStake(address layer2, address account, uint256 amount) external {
        stakes[layer2][account] = amount;
    }

    function stakeOf(address layer2, address account) external view returns (uint256) {
        return stakes[layer2][account];
    }

    function coinages(address) external pure returns (address) {
        return address(0);
    }

    function transferCoinageToRAT(address layer2, address validator, uint256 amount) external {
        require(stakes[layer2][validator] >= amount, "insufficient stake");
        stakes[layer2][validator] -= amount;
        stakes[layer2][ratContract] += amount;
    }

    function transferCoinageFromRAT(address layer2, address validator, uint256 amount) external {
        require(stakes[layer2][ratContract] >= amount, "insufficient RAT stake");
        stakes[layer2][ratContract] -= amount;
        stakes[layer2][validator] += amount;
    }

    function transferCoinageFromRATTo(address layer2, address recipient, uint256 amount) external {
        require(stakes[layer2][ratContract] >= amount, "insufficient RAT stake");
        stakes[layer2][ratContract] -= amount;
        stakes[layer2][recipient] += amount;
    }
}

/// @title RATTest
/// @notice RAT (Randomized Attention Test) V3 단위 테스트
contract RATTest is Test {
    RAT public rat;
    MockWTON public wton;
    MockTON public ton;
    MockL1BridgeRegistry public mockL1BridgeRegistry;
    MockLayer2Manager public mockLayer2Manager;
    MockSeigManager public mockSeigManager;

    address public owner = address(this);
    address public factory = address(0x3);
    address public treasury = address(0x4);

    address public systemConfig1 = address(0x10);
    address public systemConfig2 = address(0x20);
    address public layer2_1 = address(0x11);
    address public layer2_2 = address(0x21);

    address public validator1 = address(0x100);
    address public validator2 = address(0x200);
    address public validator3 = address(0x300);

    MockFaultDisputeGame public mockGame1;

    uint256 internal constant RAY = 1e27;

    uint256 public slashingPenalty = 100e27;
    uint256 public validatorBuffer = 100e27;
    uint256 public minimumThreshold = 200e27;
    uint256 public evidenceSubmissionPeriod = 1 hours;
    uint256 public ratTriggerProbability = RAY; // 100% for testing
    uint256 public maxValidatorsPerL2 = 100;
    uint256 public challengeGameDuration = 7 days; // 챌린지 게임 기간
    uint256 public safetyBuffer = 1 days; // 안전 버퍼

    function setUp() public {
        wton = new MockWTON();
        ton = new MockTON();
        wton.setTON(address(ton));

        mockL1BridgeRegistry = new MockL1BridgeRegistry();
        mockL1BridgeRegistry.setFactory(factory, systemConfig1);

        mockLayer2Manager = new MockLayer2Manager();
        mockLayer2Manager.setLayer2(systemConfig1, layer2_1);
        mockLayer2Manager.setLayer2(systemConfig2, layer2_2);

        mockSeigManager = new MockSeigManager();

        mockGame1 = new MockFaultDisputeGame(systemConfig1);

        rat = new RAT();
        rat.initialize(
            address(mockSeigManager),
            address(wton),
            address(ton),
            address(mockLayer2Manager),
            owner,
            ratTriggerProbability,
            evidenceSubmissionPeriod,
            slashingPenalty,
            validatorBuffer,
            minimumThreshold,
            maxValidatorsPerL2,
            challengeGameDuration,
            safetyBuffer
        );

        mockSeigManager.setRATContract(address(rat));
        rat.setL1BridgeRegistry(address(mockL1BridgeRegistry));
        rat.setTreasury(treasury);

        // Setup validator stakes
        mockSeigManager.setStake(layer2_1, validator1, 500e27);
        mockSeigManager.setStake(layer2_1, validator2, 600e27);
        mockSeigManager.setStake(layer2_1, validator3, 700e27);
        mockSeigManager.setStake(layer2_2, validator1, 500e27);
    }

    // ==========================================
    // 기본 테스트
    // ==========================================

    function test_getDynamicMinimumCollateral() public view {
        // N=1 (기본값), attentionCost=0 이면 C_off = slashingPenalty
        uint256 minCollateral = rat.getDynamicMinimumCollateral(systemConfig1);
        assertEq(minCollateral, slashingPenalty + validatorBuffer);
    }

    function test_getCoffWithRelaxedCheck_relaxedMode() public {
        // relaxedValidatorCheck = true (기본값)
        // C_off는 항상 slashingPenalty

        // 검증자 3명 등록
        vm.prank(validator1);
        rat.registerValidator(systemConfig1);
        vm.prank(validator2);
        rat.registerValidator(systemConfig1);
        vm.prank(validator3);
        rat.registerValidator(systemConfig1);

        uint256 coff = rat.getCoffWithRelaxedCheck(systemConfig1);
        assertEq(coff, slashingPenalty);
    }

    function test_getCoffWithRelaxedCheck_strictMode() public {
        // relaxedValidatorCheck = false
        // C_off = max(slashingPenalty, (c_m × N × RAY) / π_a)

        rat.setRelaxedValidatorCheck(false);
        rat.setAttentionCost(50e27); // c_m 설정

        // 검증자 3명 등록
        vm.prank(validator1);
        rat.registerValidator(systemConfig1);
        vm.prank(validator2);
        rat.registerValidator(systemConfig1);
        vm.prank(validator3);
        rat.registerValidator(systemConfig1);

        uint256 coff = rat.getCoffWithRelaxedCheck(systemConfig1);

        // 예상값 계산: (50e27 × 3 × 1e27) / 1e27 = 150e27
        uint256 expected = (50e27 * 3 * RAY) / RAY;
        assertEq(coff, expected);
        assertTrue(coff > slashingPenalty);
    }

    function test_getDynamicCoff_withFormula() public view {
        // attentionCost=0 이므로 항상 slashingPenalty 반환
        uint256 coff = rat.getDynamicCoff(systemConfig1);
        assertEq(coff, slashingPenalty);
    }

    function test_getDynamicCoff_withAttentionCost() public {
        // attentionCost 설정 후 formula 기반 계산
        rat.setAttentionCost(50e27);

        // 검증자 5명 등록
        vm.prank(validator1);
        rat.registerValidator(systemConfig1);
        vm.prank(validator2);
        rat.registerValidator(systemConfig1);
        vm.prank(validator3);
        rat.registerValidator(systemConfig1);

        uint256 coff = rat.getDynamicCoff(systemConfig1);

        // 예상값: max(100e27, (50e27 × 3 × 1e27) / 1e27) = 150e27
        uint256 expected = (50e27 * 3 * RAY) / RAY;
        assertEq(coff, expected);
    }

    function test_getMinimumCollateralWithRelaxedCheck_relaxedMode() public {
        // relaxedValidatorCheck = true (기본값)
        // D_min = C_off + validatorBuffer = slashingPenalty + validatorBuffer

        uint256 dmin = rat.getMinimumCollateralWithRelaxedCheck(systemConfig1);
        assertEq(dmin, slashingPenalty + validatorBuffer);
    }

    function test_getMinimumCollateralWithRelaxedCheck_strictMode() public {
        // relaxedValidatorCheck = false
        // D_min = C_off(dynamic) + validatorBuffer

        rat.setRelaxedValidatorCheck(false);
        rat.setAttentionCost(50e27);

        // 검증자 3명 등록
        vm.prank(validator1);
        rat.registerValidator(systemConfig1);
        vm.prank(validator2);
        rat.registerValidator(systemConfig1);
        vm.prank(validator3);
        rat.registerValidator(systemConfig1);

        uint256 dmin = rat.getMinimumCollateralWithRelaxedCheck(systemConfig1);

        // 예상값: (50e27 × 3 × 1e27) / 1e27 + 100e27 = 250e27
        uint256 expectedCoff = (50e27 * 3 * RAY) / RAY;
        uint256 expected = expectedCoff + validatorBuffer;
        assertEq(dmin, expected);
    }

    // ==========================================
    // 검증자 등록 테스트
    // ==========================================

    function test_registerValidator_success() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1);

        (uint256 collateral, uint32 validatorIndex, bool isActive) =
            rat.getValidatorRegistration(validator1, systemConfig1);

        assertTrue(isActive);
        assertEq(collateral, 500e27);
        assertEq(validatorIndex, 0);
        assertEq(rat.getActiveValidatorCount(systemConfig1), 1);
    }

    function test_registerValidator_insufficientDeposit() public {
        mockSeigManager.setStake(layer2_1, validator1, minimumThreshold - 1);

        vm.prank(validator1);
        vm.expectRevert();
        rat.registerValidator(systemConfig1);
    }

    function test_registerValidator_alreadyRegistered() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1);

        vm.prank(validator1);
        vm.expectRevert();
        rat.registerValidator(systemConfig1);
    }

    function test_registerMultipleValidators() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1);

        vm.prank(validator2);
        rat.registerValidator(systemConfig1);

        vm.prank(validator3);
        rat.registerValidator(systemConfig1);

        assertEq(rat.getActiveValidatorCount(systemConfig1), 3);
    }

    // ==========================================
    // 검증자 비활성화 테스트
    // ==========================================

    function test_deactivateValidator() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1);

        vm.prank(validator1);
        rat.deactivateValidator(systemConfig1);

        (uint256 collateral, , bool isActive) =
            rat.getValidatorRegistration(validator1, systemConfig1);

        assertFalse(isActive);
        assertEq(collateral, 500e27); // coinage unchanged
        assertEq(rat.getActiveValidatorCount(systemConfig1), 0);
    }

    // ==========================================
    // RAT 트리거 테스트
    // ==========================================

    function test_triggerAttentionTest() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1);

        uint32 batchIndex = 1;
        bytes32 batchHash = keccak256("batch1");
        bytes32 blockHash = keccak256("block1");

        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, batchIndex, batchHash, blockHash);

        // Check validator stake was reduced (pre-deducted)
        uint256 validatorStake = mockSeigManager.stakeOf(layer2_1, validator1);
        assertEq(validatorStake, 500e27 - slashingPenalty);

        // Check RAT received the stake
        uint256 ratStake = mockSeigManager.stakeOf(layer2_1, address(rat));
        assertEq(ratStake, slashingPenalty);
    }

    function test_triggerAttentionTest_noValidators() public {
        uint32 batchIndex = 1;
        bytes32 batchHash = keccak256("batch1");
        bytes32 blockHash = keccak256("block1");

        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, batchIndex, batchHash, blockHash);

        // Should not revert, just return early
    }

    // ==========================================
    // 증거 제출 테스트
    // ==========================================

    function test_submitEvidence() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1);

        uint32 batchIndex = 1;
        bytes32 batchHash = keccak256("batch1");
        bytes32 blockHash = keccak256("block1");

        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, batchIndex, batchHash, blockHash);

        // Before evidence: validator stake reduced
        assertEq(mockSeigManager.stakeOf(layer2_1, validator1), 400e27);

        vm.prank(validator1);
        rat.submitEvidence(systemConfig1, batchIndex, "evidence_data");

        // After evidence: stake restored
        assertEq(mockSeigManager.stakeOf(layer2_1, validator1), 500e27);
        assertEq(mockSeigManager.stakeOf(layer2_1, address(rat)), 0);
    }

    // ==========================================
    // 상태 조회 테스트 (시간 기반)
    // ==========================================

    function test_getAttentionTestStatus_evidencePeriod() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1);

        uint32 batchIndex = 1;
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, batchIndex, keccak256("batch1"), keccak256("block1"));

        bytes32 testId = rat.batchToTestId(systemConfig1, batchIndex);

        // deadline 전에는 EvidencePeriod
        RATStorage.AttentionTestStatus status = rat.getAttentionTestStatus(testId);
        assertEq(uint256(status), uint256(RATStorage.AttentionTestStatus.EvidencePeriod));
    }

    function test_getAttentionTestStatus_challengePeriod() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1);

        uint32 batchIndex = 1;
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, batchIndex, keccak256("batch1"), keccak256("block1"));

        bytes32 testId = rat.batchToTestId(systemConfig1, batchIndex);

        // deadline 경과 후 ~ challengeGameDuration 내에는 ChallengePeriod
        vm.warp(block.timestamp + evidenceSubmissionPeriod + 1);

        RATStorage.AttentionTestStatus status = rat.getAttentionTestStatus(testId);
        assertEq(uint256(status), uint256(RATStorage.AttentionTestStatus.ChallengePeriod));

        // 검증자 스테이크는 선차감 상태
        assertEq(mockSeigManager.stakeOf(layer2_1, validator1), 400e27);
        assertEq(mockSeigManager.stakeOf(layer2_1, address(rat)), 100e27);
    }

    function test_getAttentionTestStatus_slashed() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1);

        uint32 batchIndex = 1;
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, batchIndex, keccak256("batch1"), keccak256("block1"));

        bytes32 testId = rat.batchToTestId(systemConfig1, batchIndex);

        // deadline + challengeGameDuration 경과 후에 Slashed
        vm.warp(block.timestamp + evidenceSubmissionPeriod + challengeGameDuration + 1);

        RATStorage.AttentionTestStatus status = rat.getAttentionTestStatus(testId);
        assertEq(uint256(status), uint256(RATStorage.AttentionTestStatus.Slashed));

        // 검증자 스테이크는 여전히 선차감 상태 (treasury 출금 전)
        assertEq(mockSeigManager.stakeOf(layer2_1, validator1), 400e27);
        assertEq(mockSeigManager.stakeOf(layer2_1, address(rat)), 100e27);
    }

    function test_getAttentionTestStatus_restoredByEvidence() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1);

        uint32 batchIndex = 1;
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, batchIndex, keccak256("batch1"), keccak256("block1"));

        bytes32 testId = rat.batchToTestId(systemConfig1, batchIndex);

        // 증거 제출
        vm.prank(validator1);
        rat.submitEvidence(systemConfig1, batchIndex, "evidence");

        RATStorage.AttentionTestStatus status = rat.getAttentionTestStatus(testId);
        assertEq(uint256(status), uint256(RATStorage.AttentionTestStatus.RestoredByEvidence));
    }

    // ==========================================
    // Treasury 출금 테스트
    // ==========================================

    function test_withdrawSlashingsToTreasury() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1);

        uint32 batchIndex = 1;
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, batchIndex, keccak256("batch1"), keccak256("block1"));

        // 아직 출금 불가 (deadline + 챌린지 게임 기간 + 안전 버퍼 대기 필요)
        vm.expectRevert("pending tests not expired");
        rat.withdrawSlashingsToTreasury(systemConfig1);

        // 전체 대기 시간 경과 후 출금 가능
        // deadline = 현재 + evidenceSubmissionPeriod
        // withdrawableAfter = deadline + challengeGameDuration + safetyBuffer
        vm.warp(block.timestamp + evidenceSubmissionPeriod + challengeGameDuration + safetyBuffer + 1);

        // Withdraw to treasury
        rat.withdrawSlashingsToTreasury(systemConfig1);

        assertEq(mockSeigManager.stakeOf(layer2_1, address(rat)), 0);
        assertEq(mockSeigManager.stakeOf(layer2_1, treasury), slashingPenalty);
    }

    // ==========================================
    // 확률적 트리거 테스트
    // ==========================================

    function test_probabilisticTrigger() public {
        // Set probability to 0 (should never trigger)
        rat.setRatTriggerProbability(0);

        vm.prank(validator1);
        rat.registerValidator(systemConfig1);

        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, 1, keccak256("batch1"), keccak256("block1"));

        // No test should be created
        bytes32 testId = rat.batchToTestId(systemConfig1, 1);
        assertEq(testId, bytes32(0));
    }

    // ==========================================
    // resolveClaim 테스트 (챌린지 복구)
    // ==========================================

    function test_resolveClaim_duringChallengePeriod() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1);

        uint32 batchIndex = 1;
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, batchIndex, keccak256("batch1"), keccak256("block1"));

        bytes32 testId = rat.batchToTestId(systemConfig1, batchIndex);

        // deadline 경과 후 ChallengePeriod로 진입
        vm.warp(block.timestamp + evidenceSubmissionPeriod + 1);

        // 챌린지 승리 시 resolveClaim 호출 (게임 주소에서 호출)
        vm.prank(address(mockGame1));
        rat.resolveClaim(validator1);

        // 상태가 RestoredByChallenge로 변경됨
        RATStorage.AttentionTestStatus status = rat.getAttentionTestStatus(testId);
        assertEq(uint256(status), uint256(RATStorage.AttentionTestStatus.RestoredByChallenge));

        // 담보금 복구됨
        assertEq(mockSeigManager.stakeOf(layer2_1, validator1), 500e27);
        assertEq(mockSeigManager.stakeOf(layer2_1, address(rat)), 0);
    }

    function test_resolveClaim_afterChallengePeriod_fails() public {
        vm.prank(validator1);
        rat.registerValidator(systemConfig1);

        uint32 batchIndex = 1;
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, batchIndex, keccak256("batch1"), keccak256("block1"));

        // deadline + challengeGameDuration 경과 후에는 복구 불가
        vm.warp(block.timestamp + evidenceSubmissionPeriod + challengeGameDuration + 1);

        vm.prank(address(mockGame1));
        rat.resolveClaim(validator1);

        // 상태는 Slashed로 유지 (복구 실패)
        bytes32 testId = rat.batchToTestId(systemConfig1, batchIndex);
        RATStorage.AttentionTestStatus status = rat.getAttentionTestStatus(testId);
        assertEq(uint256(status), uint256(RATStorage.AttentionTestStatus.Slashed));

        // 담보금 복구되지 않음
        assertEq(mockSeigManager.stakeOf(layer2_1, validator1), 400e27);
        assertEq(mockSeigManager.stakeOf(layer2_1, address(rat)), 100e27);
    }

    // ==========================================
    // relaxedValidatorCheck 테스트
    // ==========================================

    function test_relaxedValidatorCheck_true_removesAtCoff() public {
        // relaxedValidatorCheck = true (기본값)
        // 본드 사용 후 remaining < C_off 이면 제거

        // 먼저 D_min으로 등록
        mockSeigManager.setStake(layer2_1, validator1, minimumThreshold);

        vm.prank(validator1);
        rat.registerValidator(systemConfig1);

        assertEq(rat.getActiveValidatorCount(systemConfig1), 1);

        // 등록 후 담보금을 C_off * 2 - 1 로 변경 (본드 후 remaining = C_off - 1)
        mockSeigManager.setStake(layer2_1, validator1, slashingPenalty * 2 - 1);

        // RAT 트리거
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, 1, keccak256("batch1"), keccak256("block1"));

        // 본드 후 remaining = (200e27 - 1) - 100e27 = 100e27 - 1 < C_off(100e27)
        // 검증자가 제거되어야 함
        assertEq(rat.getActiveValidatorCount(systemConfig1), 0);
    }

    function test_relaxedValidatorCheck_false_removesAtDmin() public {
        // relaxedValidatorCheck = false 설정
        rat.setRelaxedValidatorCheck(false);

        // 검증자 담보금을 D_min + C_off - 1 로 설정 (본드 후 remaining = D_min - 1)
        mockSeigManager.setStake(layer2_1, validator1, minimumThreshold + slashingPenalty - 1);

        vm.prank(validator1);
        rat.registerValidator(systemConfig1);

        assertEq(rat.getActiveValidatorCount(systemConfig1), 1);

        // RAT 트리거
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, 1, keccak256("batch1"), keccak256("block1"));

        // 본드 후 remaining = (300e27 - 1) - 100e27 = 200e27 - 1 < D_min(200e27)
        // 검증자가 제거되어야 함
        assertEq(rat.getActiveValidatorCount(systemConfig1), 0);
    }

    function test_relaxedValidatorCheck_false_keepAboveDmin() public {
        // relaxedValidatorCheck = false 설정
        rat.setRelaxedValidatorCheck(false);

        // 검증자 담보금을 D_min + C_off 로 설정 (본드 후 remaining = D_min)
        mockSeigManager.setStake(layer2_1, validator1, minimumThreshold + slashingPenalty);

        vm.prank(validator1);
        rat.registerValidator(systemConfig1);

        // RAT 트리거
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, 1, keccak256("batch1"), keccak256("block1"));

        // 본드 후 remaining = 300e27 - 100e27 = 200e27 >= D_min(200e27)
        // 검증자가 유지되어야 함
        assertEq(rat.getActiveValidatorCount(systemConfig1), 1);
    }

    // ==========================================
    // 담보금 부족 시나리오 테스트
    // ==========================================

    function test_triggerAttentionTest_zeroCollateral() public {
        // 담보금 0으로 설정
        mockSeigManager.setStake(layer2_1, validator1, minimumThreshold);

        vm.prank(validator1);
        rat.registerValidator(systemConfig1);

        // 담보금을 0으로 변경
        mockSeigManager.setStake(layer2_1, validator1, 0);

        assertEq(rat.getActiveValidatorCount(systemConfig1), 1);

        // RAT 트리거 - 담보금 0이면 테스트 없이 검증자 제거
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, 1, keccak256("batch1"), keccak256("block1"));

        // 검증자 제거됨
        assertEq(rat.getActiveValidatorCount(systemConfig1), 0);

        // 테스트는 생성되지 않음
        bytes32 testId = rat.batchToTestId(systemConfig1, 1);
        assertEq(testId, bytes32(0));
    }

    function test_triggerAttentionTest_partialBond() public {
        // 담보금을 C_off 미만으로 설정 (50e27)
        mockSeigManager.setStake(layer2_1, validator1, minimumThreshold);

        vm.prank(validator1);
        rat.registerValidator(systemConfig1);

        // 담보금을 50e27로 변경 (C_off = 100e27 미만)
        mockSeigManager.setStake(layer2_1, validator1, 50e27);

        // RAT 트리거
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, 1, keccak256("batch1"), keccak256("block1"));

        // bondAmount는 available(50e27)로 조정됨
        // remaining = 50e27 - 50e27 = 0 < C_off, 검증자 제거됨
        assertEq(rat.getActiveValidatorCount(systemConfig1), 0);

        // 하지만 테스트는 생성됨 (담보금 > 0이므로)
        bytes32 testId = rat.batchToTestId(systemConfig1, 1);
        assertTrue(testId != bytes32(0));

        // RAT에 50e27 선차감됨
        assertEq(mockSeigManager.stakeOf(layer2_1, address(rat)), 50e27);
        assertEq(mockSeigManager.stakeOf(layer2_1, validator1), 0);
    }

    // ==========================================
    // 재활성화 테스트
    // ==========================================

    /// @notice submitEvidence 후 자동 재활성화 테스트 (충분한 담보금)
    function test_submitEvidence_reactivatesValidator() public {
        // relaxedValidatorCheck = true (C_off 기준)
        vm.prank(owner);
        rat.setRelaxedValidatorCheck(true);

        vm.prank(validator1);
        rat.registerValidator(systemConfig1);

        // 검증자 활성 상태 확인
        (,,,, bool isActive) = rat.validatorRegistrations(systemConfig1, validator1);
        assertTrue(isActive);

        // 담보금을 낮춰서 triggerAttentionTest 시 제거되도록 설정
        // remaining = 150e27 - 100e27 = 50e27 < C_off(100e27) → 제거
        mockSeigManager.setStake(layer2_1, validator1, 150e27);

        uint32 batchIndex = 1;
        bytes32 batchHash = keccak256("batch1");
        bytes32 blockHash = keccak256("block1");

        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, batchIndex, batchHash, blockHash);

        // 검증자가 제거되었는지 확인
        (,,,, isActive) = rat.validatorRegistrations(systemConfig1, validator1);
        assertFalse(isActive);
        assertEq(rat.getActiveValidatorCount(systemConfig1), 0);

        // 담보금: validator=50e27, RAT=100e27
        assertEq(mockSeigManager.stakeOf(layer2_1, validator1), 50e27);
        assertEq(mockSeigManager.stakeOf(layer2_1, address(rat)), 100e27);

        // 증거 제출 → 담보금 복구 (50e27 + 100e27 = 150e27)
        vm.prank(validator1);
        rat.submitEvidence(systemConfig1, batchIndex, "evidence_data");

        // 복구 후 담보금이 150e27 >= C_off(100e27) → 자동 재활성화
        assertEq(mockSeigManager.stakeOf(layer2_1, validator1), 150e27);
        assertEq(mockSeigManager.stakeOf(layer2_1, address(rat)), 0);

        // 재활성화 확인
        (,,,, isActive) = rat.validatorRegistrations(systemConfig1, validator1);
        assertTrue(isActive);
        assertEq(rat.getActiveValidatorCount(systemConfig1), 1);
    }

    /// @notice submitEvidence 후 재활성화 실패 (담보금 부족)
    function test_submitEvidence_noReactivation_insufficientCollateral() public {
        // relaxedValidatorCheck = true (C_off 기준)
        vm.prank(owner);
        rat.setRelaxedValidatorCheck(true);

        vm.prank(validator1);
        rat.registerValidator(systemConfig1);

        // 담보금을 50e27로 낮춤 (C_off = 100e27 미만)
        mockSeigManager.setStake(layer2_1, validator1, 50e27);

        uint32 batchIndex = 1;
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, batchIndex, keccak256("batch1"), keccak256("block1"));

        // 검증자 제거 확인 (담보금 전액 차감됨)
        (,,,, bool isActive) = rat.validatorRegistrations(systemConfig1, validator1);
        assertFalse(isActive);

        // 담보금 전액 RAT로 이동: validator=0, RAT=50e27
        assertEq(mockSeigManager.stakeOf(layer2_1, validator1), 0);
        assertEq(mockSeigManager.stakeOf(layer2_1, address(rat)), 50e27);

        // 증거 제출 → 담보금 복구 (0 + 50e27 = 50e27)
        vm.prank(validator1);
        rat.submitEvidence(systemConfig1, batchIndex, "evidence_data");

        // 복구 후 담보금 50e27 < C_off(100e27) → 재활성화 안 됨
        assertEq(mockSeigManager.stakeOf(layer2_1, validator1), 50e27);
        (,,,, isActive) = rat.validatorRegistrations(systemConfig1, validator1);
        assertFalse(isActive);
        assertEq(rat.getActiveValidatorCount(systemConfig1), 0);
    }

    /// @notice resolveClaim 후 자동 재활성화 테스트
    function test_resolveClaim_reactivatesValidator() public {
        // relaxedValidatorCheck = true (C_off 기준)
        vm.prank(owner);
        rat.setRelaxedValidatorCheck(true);

        vm.prank(validator1);
        rat.registerValidator(systemConfig1);

        // 담보금을 낮춰서 제거되도록 설정
        mockSeigManager.setStake(layer2_1, validator1, 150e27);

        uint32 batchIndex = 1;
        vm.prank(factory);
        address gameAddress = address(mockGame1);
        rat.triggerAttentionTest(gameAddress, systemConfig1, batchIndex, keccak256("batch1"), keccak256("block1"));

        // 검증자 제거 확인
        (,,,, bool isActive) = rat.validatorRegistrations(systemConfig1, validator1);
        assertFalse(isActive);

        // 챌린지 게임 승리로 담보금 복구
        vm.prank(gameAddress);
        rat.resolveClaim(validator1);

        // 복구 후 담보금 150e27 >= C_off(100e27) → 자동 재활성화
        assertEq(mockSeigManager.stakeOf(layer2_1, validator1), 150e27);
        (,,,, isActive) = rat.validatorRegistrations(systemConfig1, validator1);
        assertTrue(isActive);
        assertEq(rat.getActiveValidatorCount(systemConfig1), 1);
    }

    /// @notice relaxedValidatorCheck=false 일 때 재활성화 테스트 (D_min 기준)
    function test_reactivation_strictMode_Dmin() public {
        // relaxedValidatorCheck = false (D_min 기준)
        vm.prank(owner);
        rat.setRelaxedValidatorCheck(false);

        // D_min = C_off + validatorBuffer = 100e27 + 100e27 = 200e27
        vm.prank(validator1);
        rat.registerValidator(systemConfig1);

        // 담보금을 250e27로 설정
        // triggerAttentionTest 시: remaining = 250e27 - 100e27 = 150e27
        // 150e27 < D_min(200e27) → 제거
        mockSeigManager.setStake(layer2_1, validator1, 250e27);

        uint32 batchIndex = 1;
        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), systemConfig1, batchIndex, keccak256("batch1"), keccak256("block1"));

        // 검증자 제거 확인
        (,,,, bool isActive) = rat.validatorRegistrations(systemConfig1, validator1);
        assertFalse(isActive);

        // 담보금 복구: 150e27 + 100e27 = 250e27
        vm.prank(validator1);
        rat.submitEvidence(systemConfig1, batchIndex, "evidence_data");

        // 복구 후 250e27 >= D_min(200e27) → 자동 재활성화
        assertEq(mockSeigManager.stakeOf(layer2_1, validator1), 250e27);
        (,,,, isActive) = rat.validatorRegistrations(systemConfig1, validator1);
        assertTrue(isActive);
        assertEq(rat.getActiveValidatorCount(systemConfig1), 1);
    }
}
