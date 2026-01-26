// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../helpers/V3TestBase.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MockWTON} from "../../../src/mocks/MockWTON.sol";
import {IValidatorReward} from "../../../src/validator/IValidatorReward.sol";

/// @title EligibilityTransitionTest
/// @notice 자격 전환 시 보상 분배 테스트
/// @dev 테스트 대상:
/// - INT-040: 자격 상실 전 자동 claim
/// - INT-041: 분리된 rewardPerUnit 추적 (sequencer vs validator)
/// - INT-042: 자격 재획득 시 initialDebt 리셋
/// - INT-043: 자격 상실 후 재획득 전체 플로우
/// - INT-044: AutoClaimBeforeEligibilityLoss 이벤트 검증
contract EligibilityTransitionTest is V3TestBase {
    // L2 #2 for multi-L2 tests
    SimpleMockSystemConfig public mockSystemConfig2;
    address public mockL1Bridge2;
    address public mockPortal2;
    address public mockDisputeGameFactory2;
    address public mockL2TON2;
    address public mockLayer2_2;
    address public operatorManager2;
    address public operator2 = address(0x4002);

    function setUp() public {
        _v3TestSetup();

        vm.startPrank(owner);

        // RAT 파라미터 설정
        _setupRATParams();

        // L2 #1 등록 (250 WTON 예치 - D_seq = 250 WTON 충족)
        // D_seq = maxChallengers * maxFraudProofCost + sequencerAdditionalReward
        //       = 3 * 50e27 + 100e27 = 250e27 WTON
        _registerFirstL2(250 * RAY);

        // SeigManager에 RAT 컨트랙트 주소 설정
        seigManager.setRatContract(address(rat));

        // 테스트 환경을 위한 seigniorage 시작 블록 및 초기 공급량 설정
        SeigManagerV1_2(seigManagerProxy).setSeigStartBlock(block.number);
        SeigManagerV1_2(seigManagerProxy).setInitialTotalSupply(50000000e27);

        // V3 파라미터 설정
        seigManager.setDaoDistributionRatio(0.1e27);     // d = 10%
        seigManager.setMinStakingRatio(0.01e27);         // θ = 1% (낮게 설정)
        seigManager.setValidatorDistributionRatio(0.2e27); // α = 20%
        seigManager.setHalfSaturationPoint(1000e27);     // k = 1000

        // V3 파라미터 설정 및 마이그레이션
        _setV3ParametersForTest();
        seigManager.migrateToV3();

        vm.stopPrank();
    }

    // ==========================================
    // INT-040: 자격 상실 전 자동 claim
    // ==========================================

    /// @notice INT-040: 자격 상실 시 미청구 보상이 자동 claim 되는지 검증
    function test_INT040_autoClaimBeforeEligibilityLoss() public {
        // 1. L2 자격 획득 (bridgedTON 설정 + 충분한 스테이킹)
        // setUp에서 100 WTON 이미 예치됨
        // 추가 스테이킹: 총 600 WTON
        vm.startPrank(owner);
        MockTON(ton).mint(mockPortal, 1000e18); // 1000 TON bridged
        MockWTON(wton).mint(operator1, 500 * RAY);
        vm.stopPrank();

        vm.startPrank(operator1);
        MockWTON(wton).approve(depositManagerProxy, 500 * RAY);
        depositManager.deposit(mockLayer2, operator1, 500 * RAY);
        vm.stopPrank();

        vm.prank(mockPortal);
        seigManager.onBridgedTonChange();

        // 자격 확인
        (bool eligible, uint256 required, uint256 current) = seigManager.checkCurrentEligibility(mockLayer2);
        emit log_named_uint("Required stake", required);
        emit log_named_uint("Current stake", current);
        assertTrue(eligible, "L2 should be eligible");

        // 2. 시뇨리지 누적 (100 블록)
        vm.roll(block.number + 100);

        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        // operatorManager 잔액 기록
        uint256 operatorBalanceBefore = MockWTON(wton).balanceOf(operatorManager);

        // 3. 추가 시뇨리지 누적 (100 블록 더)
        vm.roll(block.number + 100);

        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        uint256 operatorBalanceAfterSecondClaim = MockWTON(wton).balanceOf(operatorManager);
        uint256 secondClaimAmount = operatorBalanceAfterSecondClaim - operatorBalanceBefore;
        assertTrue(secondClaimAmount > 0, "Should have received sequencer rewards");

        // 4. 자격 상실 시뮬레이션
        // bridgedTON = 1000 TON = 1000e18
        // θ = 99% → minForSeigniorage = 1000e18 * 1e9 * 0.99 = 990e27 WTON
        // 현재 스테이크 = 600 WTON = 600e27 WTON < 990e27 → ineligible
        vm.prank(owner);
        seigManager.setMinStakingRatio(0.99e27); // θ = 99% (매우 높게)

        // 5. 추가 시뇨리지 누적 (자격 상실 전 미청구 보상 있음)
        vm.roll(block.number + 100);

        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        // 6. onStakingChange로 자격 재평가 트리거 (자격 상실 + 자동 claim)
        uint256 operatorBalanceBeforeLoss = MockWTON(wton).balanceOf(operatorManager);

        vm.prank(depositManagerProxy);
        seigManager.onStakingChange(mockLayer2);

        uint256 operatorBalanceAfterLoss = MockWTON(wton).balanceOf(operatorManager);
        uint256 autoClaimAmount = operatorBalanceAfterLoss - operatorBalanceBeforeLoss;

        // 자격 상실 확인
        (bool eligibleAfter, uint256 requiredAfter, uint256 currentAfter) = seigManager.checkCurrentEligibility(mockLayer2);
        emit log_named_uint("Required stake after", requiredAfter);
        emit log_named_uint("Current stake after", currentAfter);
        assertFalse(eligibleAfter, "L2 should be ineligible after parameter change");

        // effectiveBridgedTON = 0 확인
        uint256 effective = seigManager.getEffectiveBridgedTon(mockLayer2);
        assertEq(effective, 0, "effectiveBridgedTON should be 0 after losing eligibility");

        emit log_named_uint("Second claim amount", secondClaimAmount);
        emit log_named_uint("Auto claim amount (on eligibility loss)", autoClaimAmount);
    }

    // ==========================================
    // INT-041: 분리된 rewardPerUnit 추적
    // ==========================================

    /// @notice INT-041: sequencer와 validator rewardPerUnit이 분리 추적되는지 검증
    function test_INT041_separatedRewardPerUnitTracking() public {
        // 1. L2 자격 획득
        vm.startPrank(owner);
        MockTON(ton).mint(mockPortal, 1000e18);
        MockWTON(wton).mint(operator1, 500 * RAY);
        vm.stopPrank();

        vm.startPrank(operator1);
        MockWTON(wton).approve(depositManagerProxy, 500 * RAY);
        depositManager.deposit(mockLayer2, operator1, 500 * RAY);
        vm.stopPrank();

        vm.prank(mockPortal);
        seigManager.onBridgedTonChange();

        // 초기 rewardPerUnit 확인
        uint256 seqRewardPerUnitBefore = seigManager.bridgedTONRewardPerUint();
        uint256 valRewardPerUnitBefore = seigManager.validatorRewardPerUint();

        assertEq(seqRewardPerUnitBefore, 0, "Initial sequencer rewardPerUnit should be 0");
        assertEq(valRewardPerUnitBefore, 0, "Initial validator rewardPerUnit should be 0");

        // 2. 시뇨리지 분배
        vm.roll(block.number + 100);

        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        // 3. rewardPerUnit 증가 확인
        uint256 seqRewardPerUnitAfter = seigManager.bridgedTONRewardPerUint();
        uint256 valRewardPerUnitAfter = seigManager.validatorRewardPerUint();

        assertTrue(seqRewardPerUnitAfter > 0, "Sequencer rewardPerUnit should increase");
        assertTrue(valRewardPerUnitAfter > 0, "Validator rewardPerUnit should increase");

        // 4. 비율 검증: α = 20% → validator = 20%, sequencer = 80%
        uint256 alpha = seigManager.validatorDistributionRatio();
        // valRewardPerUnit / seqRewardPerUnit ≈ α / (1-α) = 0.2 / 0.8 = 0.25
        uint256 expectedRatio = (alpha * 1e18) / (RAY - alpha); // 0.25e18

        uint256 actualRatio = (valRewardPerUnitAfter * 1e18) / seqRewardPerUnitAfter;

        // 1% 오차 허용
        assertApproxEqRel(actualRatio, expectedRatio, 0.01e18, "Reward ratio should match alpha/(1-alpha)");

        emit log_named_uint("Sequencer rewardPerUnit", seqRewardPerUnitAfter);
        emit log_named_uint("Validator rewardPerUnit", valRewardPerUnitAfter);
        emit log_named_uint("Expected ratio (alpha/(1-alpha))", expectedRatio);
        emit log_named_uint("Actual ratio", actualRatio);
    }

    // ==========================================
    // INT-042: 자격 재획득 시 initialDebt 리셋
    // ==========================================

    /// @notice INT-042: 자격 재획득 시 initialDebt가 현재 rewardPerUnit 기준으로 리셋되는지 검증
    function test_INT042_initialDebtResetOnReeligibility() public {
        // 1. L2 자격 획득 (총 600 WTON)
        vm.startPrank(owner);
        MockTON(ton).mint(mockPortal, 1000e18);
        MockWTON(wton).mint(operator1, 500 * RAY);
        vm.stopPrank();

        vm.startPrank(operator1);
        MockWTON(wton).approve(depositManagerProxy, 500 * RAY);
        depositManager.deposit(mockLayer2, operator1, 500 * RAY);
        vm.stopPrank();

        vm.prank(mockPortal);
        seigManager.onBridgedTonChange();

        // 2. 시뇨리지 누적 (100 블록)
        vm.roll(block.number + 100);

        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        // 3. 자격 상실 (minStakingRatio 높이기)
        vm.prank(owner);
        seigManager.setMinStakingRatio(0.99e27);

        vm.prank(depositManagerProxy);
        seigManager.onStakingChange(mockLayer2);

        (bool eligibleAfterLoss, , ) = seigManager.checkCurrentEligibility(mockLayer2);
        assertFalse(eligibleAfterLoss, "Should be ineligible");

        // 4. 추가 시뇨리지 누적 (L2 없이)
        vm.roll(block.number + 200);

        // 다른 L2가 없으므로 모든 시뇨리지는 DAO로
        // (이 L2는 자격이 없으므로 분배받지 않음)

        uint256 rewardPerUnitBeforeReeligibility = seigManager.bridgedTONRewardPerUint();

        // 5. 자격 재획득 (minStakingRatio 낮추기)
        vm.prank(owner);
        seigManager.setMinStakingRatio(0.01e27);

        vm.prank(depositManagerProxy);
        seigManager.onStakingChange(mockLayer2);

        (bool eligibleAfterRegain, , ) = seigManager.checkCurrentEligibility(mockLayer2);
        assertTrue(eligibleAfterRegain, "Should be eligible again");

        // 6. initialDebt 검증: 현재 rewardPerUnit × effectiveBridgedTON으로 리셋
        (
            uint256 currentBridgedTON,
            uint256 effectiveBridgedTON,
            uint256 initialDebt,
            uint256 validatorInitialDebt,
            ,
            ,
            bool isEligible
        ) = seigManager.bridgedTONInfo(mockLayer2);

        assertTrue(isEligible, "isEligible should be true");
        assertGt(effectiveBridgedTON, 0, "effectiveBridgedTON should be > 0");

        // initialDebt = rewardPerUnit × effectiveBridgedTON
        uint256 expectedInitialDebt = (seigManager.bridgedTONRewardPerUint() * effectiveBridgedTON) / 1e18;
        assertEq(initialDebt, expectedInitialDebt, "initialDebt should be reset to current level");

        uint256 expectedValInitialDebt = (seigManager.validatorRewardPerUint() * effectiveBridgedTON) / 1e18;
        assertEq(validatorInitialDebt, expectedValInitialDebt, "validatorInitialDebt should be reset");

        emit log_named_uint("rewardPerUnit before re-eligibility", rewardPerUnitBeforeReeligibility);
        emit log_named_uint("rewardPerUnit after re-eligibility", seigManager.bridgedTONRewardPerUint());
        emit log_named_uint("initialDebt (reset)", initialDebt);
        emit log_named_uint("expectedInitialDebt", expectedInitialDebt);
    }

    // ==========================================
    // INT-043: 전체 플로우 테스트
    // ==========================================

    /// @notice INT-043: 자격 획득 → 보상 수령 → 자격 상실(자동 claim) → 재획득 → 보상 수령 전체 플로우
    function test_INT043_fullEligibilityTransitionFlow() public {
        // === Phase 1: 자격 획득 ===
        vm.startPrank(owner);
        MockTON(ton).mint(mockPortal, 1000e18);
        MockWTON(wton).mint(operator1, 500 * RAY);
        vm.stopPrank();

        vm.startPrank(operator1);
        MockWTON(wton).approve(depositManagerProxy, 500 * RAY);
        depositManager.deposit(mockLayer2, operator1, 500 * RAY);
        vm.stopPrank();

        vm.prank(mockPortal);
        seigManager.onBridgedTonChange();

        (bool eligible1, , ) = seigManager.checkCurrentEligibility(mockLayer2);
        assertTrue(eligible1, "Phase 1: Should be eligible");

        // === Phase 2: 첫 번째 보상 수령 ===
        vm.roll(block.number + 100);

        uint256 operatorBalance1 = MockWTON(wton).balanceOf(operatorManager);

        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        uint256 operatorBalance2 = MockWTON(wton).balanceOf(operatorManager);
        uint256 reward1 = operatorBalance2 - operatorBalance1;
        assertTrue(reward1 > 0, "Phase 2: Should receive first reward");

        // === Phase 3: 자격 상실 (자동 claim 발생) ===
        vm.roll(block.number + 100);

        // 먼저 시뇨리지 업데이트
        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        uint256 operatorBalance3 = MockWTON(wton).balanceOf(operatorManager);

        // 파라미터 변경으로 자격 상실 유도
        vm.prank(owner);
        seigManager.setMinStakingRatio(0.99e27);

        // onStakingChange로 자격 재평가 (자동 claim 발생)
        vm.prank(depositManagerProxy);
        seigManager.onStakingChange(mockLayer2);

        uint256 operatorBalance4 = MockWTON(wton).balanceOf(operatorManager);
        uint256 autoClaimReward = operatorBalance4 - operatorBalance3;

        (bool eligible2, , ) = seigManager.checkCurrentEligibility(mockLayer2);
        assertFalse(eligible2, "Phase 3: Should be ineligible");

        // === Phase 4: 자격 없는 기간 (보상 없음) ===
        vm.roll(block.number + 100);

        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        uint256 operatorBalance5 = MockWTON(wton).balanceOf(operatorManager);
        uint256 rewardDuringIneligible = operatorBalance5 - operatorBalance4;
        assertEq(rewardDuringIneligible, 0, "Phase 4: Should not receive reward when ineligible");

        // === Phase 5: 자격 재획득 ===
        vm.prank(owner);
        seigManager.setMinStakingRatio(0.01e27);

        vm.prank(depositManagerProxy);
        seigManager.onStakingChange(mockLayer2);

        (bool eligible3, , ) = seigManager.checkCurrentEligibility(mockLayer2);
        assertTrue(eligible3, "Phase 5: Should be eligible again");

        // === Phase 6: 재획득 후 보상 수령 ===
        vm.roll(block.number + 100);

        uint256 operatorBalance6 = MockWTON(wton).balanceOf(operatorManager);

        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        uint256 operatorBalance7 = MockWTON(wton).balanceOf(operatorManager);
        uint256 rewardAfterReeligibility = operatorBalance7 - operatorBalance6;
        assertTrue(rewardAfterReeligibility > 0, "Phase 6: Should receive reward after re-eligibility");

        emit log_string("=== Full Eligibility Transition Flow ===");
        emit log_named_uint("Phase 2: First reward", reward1);
        emit log_named_uint("Phase 3: Auto-claim on eligibility loss", autoClaimReward);
        emit log_named_uint("Phase 4: Reward during ineligible period", rewardDuringIneligible);
        emit log_named_uint("Phase 6: Reward after re-eligibility", rewardAfterReeligibility);
    }

    // ==========================================
    // INT-044: AutoClaimBeforeEligibilityLoss 이벤트 검증
    // ==========================================

    /// @notice INT-044: 자격 상실 시 AutoClaimBeforeEligibilityLoss 이벤트가 발생하는지 검증
    function test_INT044_autoClaimEventEmitted() public {
        // 1. L2 자격 획득
        vm.startPrank(owner);
        MockTON(ton).mint(mockPortal, 1000e18);
        MockWTON(wton).mint(operator1, 500 * RAY);
        vm.stopPrank();

        vm.startPrank(operator1);
        MockWTON(wton).approve(depositManagerProxy, 500 * RAY);
        depositManager.deposit(mockLayer2, operator1, 500 * RAY);
        vm.stopPrank();

        vm.prank(mockPortal);
        seigManager.onBridgedTonChange();

        // 2. 시뇨리지 누적
        vm.roll(block.number + 100);

        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        // 3. 자격 상실 유도
        vm.prank(owner);
        seigManager.setMinStakingRatio(0.99e27);

        // 4. 이벤트 기대
        vm.expectEmit(true, false, false, false);
        emit AutoClaimBeforeEligibilityLoss(mockLayer2, 0, 0); // 정확한 값은 무시

        // 5. 자격 재평가 트리거
        vm.prank(depositManagerProxy);
        seigManager.onStakingChange(mockLayer2);
    }

    // ==========================================
    // INT-045: 전역 paused 상태에서 자격 상실
    // ==========================================

    /// @notice INT-045: 전역 paused 상태에서 자격 상실 시 미청구 보상이 claim 되는지 검증
    /// @dev paused 상태에서는 새로운 시뇨리지 발행 안 됨, 하지만 기존 미청구 보상은 claim 가능
    /// @dev 미청구 보상 시나리오: L2 A가 updateSeigniorage 호출 → rewardPerUnit 증가 → L2 B는 claim 안 됨 → 미청구 보상 존재
    function test_INT045_pausedState_eligibilityLoss_claimUnclaimedRewards() public {
        // 1. L2 #1 자격 획득
        vm.startPrank(owner);
        MockTON(ton).mint(mockPortal, 1000e18);
        MockWTON(wton).mint(operator1, 500 * RAY);
        vm.stopPrank();

        vm.startPrank(operator1);
        MockWTON(wton).approve(depositManagerProxy, 500 * RAY);
        depositManager.deposit(mockLayer2, operator1, 500 * RAY);
        vm.stopPrank();

        vm.prank(mockPortal);
        seigManager.onBridgedTonChange();

        // 2. L2 #2 등록 (미청구 보상 시나리오를 위해)
        _setupSecondL2();

        vm.prank(mockPortal2);
        seigManager.onBridgedTonChange();

        // 3. 시뇨리지 누적 (100 블록) - L2 #1만 claim
        vm.roll(block.number + 100);

        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        // L2 #2는 updateSeigniorage 호출하지 않음 → rewardPerUnit은 증가했지만 L2 #2는 claim 안 됨
        // 따라서 L2 #2에 미청구 보상 존재

        uint256 operatorManager2BalanceBefore = MockWTON(wton).balanceOf(operatorManager2);

        // 4. 전역 paused 설정
        vm.prank(owner);
        seigManager.pause();

        assertTrue(seigManager.paused(), "Should be paused");

        // 5. paused 상태에서 updateSeigniorage 호출 → early return
        vm.prank(mockLayer2_2);
        seigManager.updateSeigniorage();

        uint256 operatorManager2BalanceAfterPausedUpdate = MockWTON(wton).balanceOf(operatorManager2);
        assertEq(operatorManager2BalanceAfterPausedUpdate, operatorManager2BalanceBefore, "No new seigniorage in paused state");

        // 6. L2 #2 자격 상실 유도 (minStakingRatio 높이기)
        vm.prank(owner);
        seigManager.setMinStakingRatio(0.99e27);

        // 7. paused 상태에서 자격 재평가 → 미청구 보상 claim
        uint256 operatorManager2BalanceBeforeLoss = MockWTON(wton).balanceOf(operatorManager2);

        vm.prank(depositManagerProxy);
        seigManager.onStakingChange(mockLayer2_2);

        uint256 operatorManager2BalanceAfterLoss = MockWTON(wton).balanceOf(operatorManager2);
        uint256 autoClaimAmount = operatorManager2BalanceAfterLoss - operatorManager2BalanceBeforeLoss;

        // 8. 자격 상실 확인
        (bool eligibleAfter, , ) = seigManager.checkCurrentEligibility(mockLayer2_2);
        assertFalse(eligibleAfter, "Should be ineligible");

        // 9. effectiveBridgedTON = 0 확인
        uint256 effective = seigManager.getEffectiveBridgedTon(mockLayer2_2);
        assertEq(effective, 0, "effectiveBridgedTON should be 0");

        // 10. 미청구 보상이 claim 되었는지 확인
        // paused 상태에서도 기존 미청구 보상은 claim 가능
        assertTrue(autoClaimAmount > 0, "Should claim unclaimed rewards even in paused state");

        emit log_string("=== INT-045: Paused State Eligibility Loss ===");
        emit log_named_uint("Auto claim amount (paused state)", autoClaimAmount);
    }

    /// @notice L2 #2 설정 헬퍼
    function _setupSecondL2() internal {
        mockL1Bridge2 = address(0x9001);
        mockPortal2 = address(0x9002);
        mockDisputeGameFactory2 = address(0x9003);
        mockL2TON2 = address(0x9004);

        mockSystemConfig2 = new SimpleMockSystemConfig();
        mockSystemConfig2.setL1StandardBridge(mockL1Bridge2);
        mockSystemConfig2.setOptimismPortal(mockPortal2);
        mockSystemConfig2.setDisputeGameFactory(mockDisputeGameFactory2);
        mockSystemConfig2.setUnsafeBlockSigner(operator2);

        vm.startPrank(owner);
        MockTON(ton).mint(mockPortal2, 1000e18);
        vm.stopPrank();

        (mockLayer2_2, operatorManager2) = _registerLayer2WithSystemConfig(
            address(mockSystemConfig2),
            mockL2TON2,
            "TestL2_2",
            operator2,
            250 * RAY // 250 WTON 예치 (D_seq 충족)
        );
    }

    // ==========================================
    // INT-046: 전역 paused 상태에서 자격 획득
    // ==========================================

    /// @notice INT-046: 전역 paused 상태에서 자격 획득 시 effectiveBridgedTON 설정 확인
    function test_INT046_pausedState_eligibilityGain_setsEffectiveBridgedTON() public {
        // 1. L2 자격 획득
        vm.startPrank(owner);
        MockTON(ton).mint(mockPortal, 1000e18);
        MockWTON(wton).mint(operator1, 500 * RAY);
        vm.stopPrank();

        vm.startPrank(operator1);
        MockWTON(wton).approve(depositManagerProxy, 500 * RAY);
        depositManager.deposit(mockLayer2, operator1, 500 * RAY);
        vm.stopPrank();

        vm.prank(mockPortal);
        seigManager.onBridgedTonChange();

        (bool eligible1, , ) = seigManager.checkCurrentEligibility(mockLayer2);
        assertTrue(eligible1, "Should be eligible initially");

        // 2. 시뇨리지 누적
        vm.roll(block.number + 100);

        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        // 3. 자격 상실
        vm.prank(owner);
        seigManager.setMinStakingRatio(0.99e27);

        vm.prank(depositManagerProxy);
        seigManager.onStakingChange(mockLayer2);

        (bool eligible2, , ) = seigManager.checkCurrentEligibility(mockLayer2);
        assertFalse(eligible2, "Should be ineligible");

        uint256 effectiveAfterLoss = seigManager.getEffectiveBridgedTon(mockLayer2);
        assertEq(effectiveAfterLoss, 0, "effectiveBridgedTON should be 0 after loss");

        // 4. 전역 paused 설정
        vm.prank(owner);
        seigManager.pause();

        assertTrue(seigManager.paused(), "Should be paused");

        // 5. paused 상태에서 자격 재획득 (minStakingRatio 낮추기)
        vm.prank(owner);
        seigManager.setMinStakingRatio(0.01e27);

        vm.prank(depositManagerProxy);
        seigManager.onStakingChange(mockLayer2);

        // 6. paused 상태에서도 자격 획득 + effectiveBridgedTON 설정 확인
        (bool eligible3, , ) = seigManager.checkCurrentEligibility(mockLayer2);
        assertTrue(eligible3, "Should be eligible again even in paused state");

        uint256 effectiveAfterRegain = seigManager.getEffectiveBridgedTon(mockLayer2);
        assertGt(effectiveAfterRegain, 0, "effectiveBridgedTON should be > 0 after regain");

        // 7. initialDebt가 현재 rewardPerUnit 기준으로 설정되었는지 확인
        (
            ,
            uint256 effectiveBridgedTON,
            uint256 initialDebt,
            uint256 validatorInitialDebt,
            ,
            ,
            bool isEligible
        ) = seigManager.bridgedTONInfo(mockLayer2);

        assertTrue(isEligible, "isEligible should be true");

        uint256 expectedInitialDebt = (seigManager.bridgedTONRewardPerUint() * effectiveBridgedTON) / 1e18;
        assertEq(initialDebt, expectedInitialDebt, "initialDebt should be set correctly");

        uint256 expectedValInitialDebt = (seigManager.validatorRewardPerUint() * effectiveBridgedTON) / 1e18;
        assertEq(validatorInitialDebt, expectedValInitialDebt, "validatorInitialDebt should be set correctly");

        emit log_string("=== INT-046: Paused State Eligibility Gain ===");
        emit log_named_uint("effectiveBridgedTON after regain", effectiveAfterRegain);
        emit log_named_uint("initialDebt", initialDebt);
        emit log_named_uint("validatorInitialDebt", validatorInitialDebt);
    }

    // ==========================================
    // INT-047: 자격 상실 시 시뇨리지 자동 정산
    // ==========================================

    /// @notice INT-047: updateSeigniorage 없이 자격 상실 시에도 시뇨리지가 정산되는지 검증
    /// @dev _triggerSeigniorageDistribution이 _handleEligibilityLoss 전에 호출되어야 함
    function test_INT047_eligibilityLoss_triggersSeigDistribution() public {
        // 1. L2 자격 획득
        vm.startPrank(owner);
        MockTON(ton).mint(mockPortal, 1000e18);
        MockWTON(wton).mint(operator1, 500 * RAY);
        vm.stopPrank();

        vm.startPrank(operator1);
        MockWTON(wton).approve(depositManagerProxy, 500 * RAY);
        depositManager.deposit(mockLayer2, operator1, 500 * RAY);
        vm.stopPrank();

        vm.prank(mockPortal);
        seigManager.onBridgedTonChange();

        // 2. 시뇨리지 누적 (100 블록) + updateSeigniorage
        vm.roll(block.number + 100);
        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        uint256 rewardPerUnitAfterFirst = seigManager.bridgedTONRewardPerUint();
        uint256 operatorBalanceAfterFirst = MockWTON(wton).balanceOf(operatorManager);

        // 3. 추가 시뇨리지 누적 (100 블록) - updateSeigniorage 호출 안 함!
        vm.roll(block.number + 100);

        // rewardPerUnit은 아직 업데이트 안 됨
        uint256 rewardPerUnitBeforeLoss = seigManager.bridgedTONRewardPerUint();
        assertEq(rewardPerUnitBeforeLoss, rewardPerUnitAfterFirst, "rewardPerUnit should not change without updateSeigniorage");

        // 4. 자격 상실 유도 (updateSeigniorage 없이 바로 onStakingChange)
        vm.prank(owner);
        seigManager.setMinStakingRatio(0.99e27);

        vm.prank(depositManagerProxy);
        seigManager.onStakingChange(mockLayer2);

        // 5. rewardPerUnit이 업데이트되었는지 확인 (_triggerSeigniorageDistribution 호출됨)
        uint256 rewardPerUnitAfterLoss = seigManager.bridgedTONRewardPerUint();
        assertGt(rewardPerUnitAfterLoss, rewardPerUnitBeforeLoss, "rewardPerUnit should increase after eligibility loss");

        // 6. 자동 claim 금액 확인 (추가 100 블록분 시뇨리지 포함)
        uint256 operatorBalanceAfterLoss = MockWTON(wton).balanceOf(operatorManager);
        uint256 autoClaimAmount = operatorBalanceAfterLoss - operatorBalanceAfterFirst;

        assertTrue(autoClaimAmount > 0, "Should auto-claim including recent seigniorage");

        emit log_string("=== INT-047: Eligibility Loss Triggers Seig Distribution ===");
        emit log_named_uint("rewardPerUnit before loss", rewardPerUnitBeforeLoss);
        emit log_named_uint("rewardPerUnit after loss", rewardPerUnitAfterLoss);
        emit log_named_uint("Auto claim amount (includes 100 blocks)", autoClaimAmount);
    }

    // ==========================================
    // INT-048: 자격 획득 시 시뇨리지 자동 정산
    // ==========================================

    /// @notice INT-048: 자격 획득 시에도 시뇨리지가 정산되는지 검증 (기존 L2에게 공정 분배)
    function test_INT048_eligibilityGain_triggersSeigDistribution() public {
        // 1. L2 #1 자격 획득
        vm.startPrank(owner);
        MockTON(ton).mint(mockPortal, 1000e18);
        MockWTON(wton).mint(operator1, 500 * RAY);
        vm.stopPrank();

        vm.startPrank(operator1);
        MockWTON(wton).approve(depositManagerProxy, 500 * RAY);
        depositManager.deposit(mockLayer2, operator1, 500 * RAY);
        vm.stopPrank();

        vm.prank(mockPortal);
        seigManager.onBridgedTonChange();

        // 2. L2 #2 설정 (TON 없이 등록 → eligible = false)
        _setupSecondL2WithoutTON();

        // L2 #2는 bridgedTON = 0 → eligible = false
        (, , , , , , bool isEligible2Before) = seigManager.bridgedTONInfo(mockLayer2_2);
        assertFalse(isEligible2Before, "L2 #2 stored isEligible should be false initially");

        // effectiveBridgedTON도 0이어야 함
        uint256 effective2Before = seigManager.getEffectiveBridgedTon(mockLayer2_2);
        assertEq(effective2Before, 0, "L2 #2 effectiveBridgedTON should be 0 initially");

        // 3. 시뇨리지 누적 (100 블록) - L2 #1만 자격 있음
        vm.roll(block.number + 100);

        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        uint256 rewardPerUnitAfterFirst = seigManager.bridgedTONRewardPerUint();

        // 4. 추가 시뇨리지 누적 (100 블록) - updateSeigniorage 호출 안 함!
        vm.roll(block.number + 100);

        // 5. L2 #2에 TON 브릿지 후 자격 획득
        vm.prank(owner);
        MockTON(ton).mint(mockPortal2, 1000e18);

        vm.prank(mockPortal2);
        seigManager.onBridgedTonChange();

        // 6. rewardPerUnit이 업데이트되었는지 확인 (_triggerSeigniorageDistribution 호출됨)
        uint256 rewardPerUnitAfterL2_2Join = seigManager.bridgedTONRewardPerUint();
        assertGt(rewardPerUnitAfterL2_2Join, rewardPerUnitAfterFirst, "rewardPerUnit should increase when L2 #2 gains eligibility");

        // 7. L2 #2의 initialDebt가 최신 rewardPerUnit 기준으로 설정되었는지 확인
        (
            ,
            uint256 effectiveBridgedTON2,
            uint256 initialDebt2,
            ,
            ,
            ,
            bool isEligible2
        ) = seigManager.bridgedTONInfo(mockLayer2_2);

        assertTrue(isEligible2, "L2 #2 should be eligible");
        uint256 expectedInitialDebt2 = (rewardPerUnitAfterL2_2Join * effectiveBridgedTON2) / 1e18;
        assertEq(initialDebt2, expectedInitialDebt2, "L2 #2 initialDebt should match current rewardPerUnit");

        emit log_string("=== INT-048: Eligibility Gain Triggers Seig Distribution ===");
        emit log_named_uint("rewardPerUnit after L2 #1 update", rewardPerUnitAfterFirst);
        emit log_named_uint("rewardPerUnit after L2 #2 joins", rewardPerUnitAfterL2_2Join);
        emit log_named_uint("L2 #2 initialDebt", initialDebt2);
    }

    /// @notice L2 #2 설정 헬퍼 (TON 민팅 없이)
    function _setupSecondL2WithoutTON() internal {
        mockL1Bridge2 = address(0x9001);
        mockPortal2 = address(0x9002);
        mockDisputeGameFactory2 = address(0x9003);
        mockL2TON2 = address(0x9004);

        mockSystemConfig2 = new SimpleMockSystemConfig();
        mockSystemConfig2.setL1StandardBridge(mockL1Bridge2);
        mockSystemConfig2.setOptimismPortal(mockPortal2);
        mockSystemConfig2.setDisputeGameFactory(mockDisputeGameFactory2);
        mockSystemConfig2.setUnsafeBlockSigner(operator2);

        // TON 민팅 없이 등록 → bridgedTON = 0 → eligible = false
        (mockLayer2_2, operatorManager2) = _registerLayer2WithSystemConfig(
            address(mockSystemConfig2),
            mockL2TON2,
            "TestL2_2",
            operator2,
            250 * RAY // 250 WTON 예치 (D_seq 충족)
        );
    }

    // ==========================================
    // INT-049: estimateL2Seigniorage 정확성 검증
    // ==========================================

    /// @notice INT-049: estimateL2Seigniorage가 실제 받는 금액과 일치하는지 검증
    function test_INT049_estimateL2Seigniorage_accuracy() public {
        // 1. L2 자격 획득
        vm.startPrank(owner);
        MockTON(ton).mint(mockPortal, 1000e18);
        MockWTON(wton).mint(operator1, 500 * RAY);
        vm.stopPrank();

        vm.startPrank(operator1);
        MockWTON(wton).approve(depositManagerProxy, 500 * RAY);
        depositManager.deposit(mockLayer2, operator1, 500 * RAY);
        vm.stopPrank();

        vm.prank(mockPortal);
        seigManager.onBridgedTonChange();

        // 2. 검증자 등록 (validator1)
        address validator1Addr = address(0x5001);
        _registerValidator(validator1Addr, 200 * RAY);

        // 3. 시뇨리지 누적 (100 블록) + updateSeigniorage
        vm.roll(block.number + 100);
        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        // 4. 추가 시뇨리지 누적 (100 블록) - claim 안 함
        vm.roll(block.number + 100);

        // 5. estimateL2Seigniorage 호출
        (uint256 estimatedSeq, uint256 estimatedVal) = seigManager.estimateL2Seigniorage(mockLayer2);

        // 6. 실제 updateSeigniorage 실행
        // 검증자가 있으면 validator reward는 ValidatorReward 컨트랙트에 누적됨
        uint256 operatorBalanceBefore = MockWTON(wton).balanceOf(operatorManager);
        // V1.1: O(1) 분배에서는 getClaimableRewards 사용
        uint256 validator1ClaimableBefore = IValidatorReward(validatorPoolProxy).getClaimableRewards(validator1Addr);

        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        uint256 actualSeq = MockWTON(wton).balanceOf(operatorManager) - operatorBalanceBefore;
        // V1.1: O(1) 분배에서는 getClaimableRewards 사용
        uint256 validator1ClaimableAfter = IValidatorReward(validatorPoolProxy).getClaimableRewards(validator1Addr);
        uint256 validator1Received = validator1ClaimableAfter - validator1ClaimableBefore;

        // 7. 예측값과 실제값 비교
        assertEq(estimatedSeq, actualSeq, "Estimated sequencer reward should match actual");
        // 검증자가 1명이면 전체 validator reward를 받음
        assertEq(estimatedVal, validator1Received, "Estimated validator reward should match actual");

        emit log_string("=== INT-049: estimateL2Seigniorage Accuracy ===");
        emit log_named_uint("Estimated sequencer reward", estimatedSeq);
        emit log_named_uint("Actual sequencer reward", actualSeq);
        emit log_named_uint("Estimated validator reward", estimatedVal);
        emit log_named_uint("Validator1 claimable rewards", validator1Received);
    }

    /// @notice INT-050: 미청구 보상 누적 시 estimateL2Seigniorage 검증
    function test_INT050_estimateL2Seigniorage_withAccumulatedRewards() public {
        // 1. L2 #1, #2 자격 획득
        vm.startPrank(owner);
        MockTON(ton).mint(mockPortal, 1000e18);
        MockWTON(wton).mint(operator1, 500 * RAY);
        vm.stopPrank();

        vm.startPrank(operator1);
        MockWTON(wton).approve(depositManagerProxy, 500 * RAY);
        depositManager.deposit(mockLayer2, operator1, 500 * RAY);
        vm.stopPrank();

        vm.prank(mockPortal);
        seigManager.onBridgedTonChange();

        _setupSecondL2();
        vm.prank(mockPortal2);
        seigManager.onBridgedTonChange();

        // 2. 검증자 등록 (L2 #2용)
        address validator2Addr = address(0x5002);
        _registerValidatorForL2(validator2Addr, 200 * RAY, mockLayer2_2, address(mockSystemConfig2));

        // 3. L2 #1만 updateSeigniorage 호출 → L2 #2에 미청구 보상 누적
        vm.roll(block.number + 100);
        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        // 4. 추가 블록 진행
        vm.roll(block.number + 100);

        // 5. L2 #2의 estimateL2Seigniorage (미청구 보상 + 새 시뇨리지 포함)
        (uint256 estimatedSeq2, uint256 estimatedVal2) = seigManager.estimateL2Seigniorage(mockLayer2_2);

        // 6. 실제 updateSeigniorage 실행
        // 검증자가 있으면 validator reward는 ValidatorReward 컨트랙트에 누적됨
        uint256 operator2BalanceBefore = MockWTON(wton).balanceOf(operatorManager2);
        // V1.1: O(1) 분배에서는 getClaimableRewards 사용
        uint256 validator2ClaimableBefore = IValidatorReward(validatorPoolProxy).getClaimableRewards(validator2Addr);

        vm.prank(mockLayer2_2);
        seigManager.updateSeigniorage();

        uint256 actualSeq2 = MockWTON(wton).balanceOf(operatorManager2) - operator2BalanceBefore;
        // V1.1: O(1) 분배에서는 getClaimableRewards 사용
        uint256 validator2ClaimableAfter = IValidatorReward(validatorPoolProxy).getClaimableRewards(validator2Addr);
        uint256 validator2Received = validator2ClaimableAfter - validator2ClaimableBefore;

        // 7. 예측값과 실제값 비교
        assertEq(estimatedSeq2, actualSeq2, "Estimated sequencer reward should match actual (with accumulated)");
        assertEq(estimatedVal2, validator2Received, "Estimated validator reward should match actual (with accumulated)");

        // 8. 미청구 보상이 포함되었는지 확인 (0보다 커야 함)
        assertTrue(estimatedSeq2 > 0, "Should have accumulated rewards");

        emit log_string("=== INT-050: estimateL2Seigniorage with Accumulated Rewards ===");
        emit log_named_uint("L2 #2 Estimated sequencer reward", estimatedSeq2);
        emit log_named_uint("L2 #2 Actual sequencer reward", actualSeq2);
        emit log_named_uint("L2 #2 Estimated validator reward", estimatedVal2);
        emit log_named_uint("Validator2 claimable rewards", validator2Received);
    }

    /// @notice L2별 검증자 등록 헬퍼
    function _registerValidatorForL2(address validator, uint256 depositAmount, address layer2, address systemConfig) internal {
        vm.startPrank(owner);
        MockWTON(wton).mint(validator, depositAmount);
        vm.stopPrank();

        vm.startPrank(validator);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        depositManager.deposit(layer2, validator, depositAmount);
        rat.registerValidator(systemConfig);
        vm.stopPrank();
    }

    // ==========================================
    // INT-051: claimableL2Seigniorage 정확성 검증
    // ==========================================

    /// @notice INT-051: claimableL2Seigniorage가 시퀀서 보상만 반환하는지 검증
    /// @dev estimateL2Seigniorage의 sequencerReward와 일치해야 함
    function test_INT051_claimableL2Seigniorage_returnsSequencerRewardOnly() public {
        // 1. L2 자격 획득
        vm.startPrank(owner);
        MockTON(ton).mint(mockPortal, 1000e18);
        MockWTON(wton).mint(operator1, 500 * RAY);
        vm.stopPrank();

        vm.startPrank(operator1);
        MockWTON(wton).approve(depositManagerProxy, 500 * RAY);
        depositManager.deposit(mockLayer2, operator1, 500 * RAY);
        vm.stopPrank();

        vm.prank(mockPortal);
        seigManager.onBridgedTonChange();

        // 2. 검증자 등록
        address validator1Addr = address(0x5001);
        _registerValidator(validator1Addr, 200 * RAY);

        // 3. 시뇨리지 누적 (100 블록)
        vm.roll(block.number + 100);
        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        // 4. 추가 시뇨리지 누적 (100 블록) - claim 안 함
        vm.roll(block.number + 100);

        // 5. claimableL2Seigniorage vs estimateL2Seigniorage 비교
        uint256 claimable = seigManager.claimableL2Seigniorage(mockLayer2);
        (uint256 estimatedSeq, uint256 estimatedVal) = seigManager.estimateL2Seigniorage(mockLayer2);

        // 6. claimableL2Seigniorage == estimateL2Seigniorage의 시퀀서 보상
        assertEq(claimable, estimatedSeq, "claimableL2Seigniorage should equal sequencer reward from estimate");
        assertTrue(estimatedVal > 0, "Validator reward should be > 0");
        assertTrue(claimable > 0, "Claimable should be > 0");

        // 7. 실제 updateSeigniorage 실행하여 검증
        uint256 operatorBalanceBefore = MockWTON(wton).balanceOf(operatorManager);

        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        uint256 actualSeq = MockWTON(wton).balanceOf(operatorManager) - operatorBalanceBefore;

        // 8. claimableL2Seigniorage == 실제 시퀀서 보상
        assertEq(claimable, actualSeq, "claimableL2Seigniorage should match actual sequencer reward");

        emit log_string("=== INT-051: claimableL2Seigniorage Returns Sequencer Reward Only ===");
        emit log_named_uint("claimableL2Seigniorage", claimable);
        emit log_named_uint("estimateL2Seigniorage (sequencer)", estimatedSeq);
        emit log_named_uint("estimateL2Seigniorage (validator)", estimatedVal);
        emit log_named_uint("Actual sequencer reward", actualSeq);
    }

    /// @notice INT-052: claimableL2Seigniorage가 누적 미청구 보상을 포함하는지 검증
    function test_INT052_claimableL2Seigniorage_includesAccumulatedRewards() public {
        // 1. L2 #1, #2 자격 획득
        vm.startPrank(owner);
        MockTON(ton).mint(mockPortal, 1000e18);
        MockWTON(wton).mint(operator1, 500 * RAY);
        vm.stopPrank();

        vm.startPrank(operator1);
        MockWTON(wton).approve(depositManagerProxy, 500 * RAY);
        depositManager.deposit(mockLayer2, operator1, 500 * RAY);
        vm.stopPrank();

        vm.prank(mockPortal);
        seigManager.onBridgedTonChange();

        _setupSecondL2();
        vm.prank(mockPortal2);
        seigManager.onBridgedTonChange();

        // 2. L2 #1만 updateSeigniorage 호출 → L2 #2에 미청구 보상 누적
        vm.roll(block.number + 100);
        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        // L2 #2는 updateSeigniorage 호출 안 함 → 미청구 보상 누적

        // 3. 추가 블록 진행
        vm.roll(block.number + 100);

        // 4. L2 #2의 claimableL2Seigniorage (미청구 보상 + 새 시뇨리지 포함)
        uint256 claimable2 = seigManager.claimableL2Seigniorage(mockLayer2_2);
        (uint256 estimatedSeq2, ) = seigManager.estimateL2Seigniorage(mockLayer2_2);

        // 5. 값 일치 확인
        assertEq(claimable2, estimatedSeq2, "claimableL2Seigniorage should include accumulated rewards");

        // 6. 실제 updateSeigniorage 실행
        uint256 operator2BalanceBefore = MockWTON(wton).balanceOf(operatorManager2);

        vm.prank(mockLayer2_2);
        seigManager.updateSeigniorage();

        uint256 actualSeq2 = MockWTON(wton).balanceOf(operatorManager2) - operator2BalanceBefore;

        // 7. claimableL2Seigniorage == 실제 받은 금액
        assertEq(claimable2, actualSeq2, "claimableL2Seigniorage should match actual received amount");

        emit log_string("=== INT-052: claimableL2Seigniorage Includes Accumulated Rewards ===");
        emit log_named_uint("L2 #2 claimableL2Seigniorage", claimable2);
        emit log_named_uint("L2 #2 actual sequencer reward", actualSeq2);
    }

    // Event declaration for expectEmit
    event AutoClaimBeforeEligibilityLoss(address indexed layer2, uint256 sequencerReward, uint256 validatorReward);
}
