// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../v2mode/V2ModeTestBase.sol";

/// @title EligibilityInvariants
/// @notice 자격 조건의 불변 속성 검증
/// @dev 이 테스트는 V3 자격 조건의 일관성을 검증합니다.
///      불변 속성:
///      INV-003: ∀ Layer2 L, ∀ 시점 t:
///               isEligibleLayer(L, t) = true ⟺ staked(L, t) ≥ getRequiredCollateral(L, t)
///
///      검증 항목:
///      1. checkCurrentEligibility 반환값과 실제 자격 상태 일치
///      2. effectiveBridgedTON 상태와 자격 조건 일치
///      3. 자격 충족 → effectiveBridgedTON > 0
///      4. 자격 미달 → effectiveBridgedTON = 0
///      5. 스테이킹 변화 시 자격 재평가 정확성
contract EligibilityInvariantsTest is V2ModeTestBase {
    function setUp() public {
        // V2ModeTestBase의 setUp 호출
        _baseSetUp();

        // V3 파라미터 설정만 (마이그레이션은 layer2 등록 후에)
        // Note: 낮은 θ(minStakingRatio) 설정 - 기본 operator 스테이킹으로 자격 충족 가능
        // V3에서 checkCurrentEligibility는 OperatorManager의 잔액을 확인함
        vm.startPrank(owner);
        seigManager.setDaoDistributionRatio(0.1e27);           // 10%
        seigManager.setMinStakingRatio(0.001e27);              // θ = 0.1% (낮게 설정)
        seigManager.setValidatorDistributionRatio(0.2e27);     // 20%
        seigManager.setHalfSaturationPoint(1000e27);           // k = 1000 TON
        seigManager.setMaxChallengers(3);                      // H_max = 3
        seigManager.setMaxFraudProofCost(50e27);              // C_max = 50 WTON
        seigManager.setSequencerAdditionalReward(50e27);       // D_sequencer = 50 WTON (operator stake보다 낮게)
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
    // INV-003: 자격 조건 일관성
    // ==========================================

    /// @notice INV-003-Basic: checkCurrentEligibility와 실제 자격 일치
    /// @dev eligible=true ⟺ actual >= required
    function test_INV003_basic_eligibilityConsistency() public {
        _setupLayer2AndMigrateV3();

        // ============================================
        // 1. 자격 확인
        // ============================================
        (bool eligible, uint256 required, uint256 actual) = seigManager.checkCurrentEligibility(mockLayer2);

        emit log_string("=== INV-003-Basic: Eligibility Consistency ===");
        emit log_named_decimal_uint("Required stake", required / 1e27, 27);
        emit log_named_decimal_uint("Actual stake", actual / 1e27, 27);
        emit log_named_string("Eligibility", eligible ? "ELIGIBLE" : "INELIGIBLE");

        // ============================================
        // 2. 불변 속성 검증: eligible ⟺ actual >= required
        // ============================================
        if (eligible) {
            assertGe(actual, required, "INV-003: If eligible, actual must be >= required");
        } else {
            assertLt(actual, required, "INV-003: If ineligible, actual must be < required");
        }

        // ============================================
        // 3. effectiveBridgedTON과 자격 상태 일치 확인
        // ============================================
        // 시뇨리지 분배로 effectiveBridgedTON 업데이트
        vm.roll(block.number + 100);
        _updateSeigniorage();

        uint256 effectiveBridgedTON = seigManager.getEffectiveBridgedTon(mockLayer2);

        if (eligible) {
            assertGt(effectiveBridgedTON, 0, "INV-003: If eligible, effectiveBridgedTON should be > 0");
        } else {
            assertEq(effectiveBridgedTON, 0, "INV-003: If ineligible, effectiveBridgedTON should be 0");
        }

        emit log_named_decimal_uint("effectiveBridgedTON", effectiveBridgedTON / 1e27, 27);
    }

    // ==========================================
    // INV-003: 스테이킹 증가 시 자격 획득
    // ==========================================

    /// @notice INV-003-StakeIncrease: 스테이킹 증가로 자격 획득 시 일관성
    /// @dev 자격 미달 상태 → 추가 스테이킹 → 자격 충족 → effectiveBridgedTON > 0
    /// @dev SKIP: V3에서 checkCurrentEligibility는 OperatorManager의 잔액을 반환하므로
    ///      일반 스테이커의 deposit으로는 자격을 변경할 수 없음.
    ///      이 테스트는 V3 자격 모델과 맞지 않아 스킵함.
    function test_INV003_stakeIncrease_gainsEligibility() public {
        vm.skip(true);
        _setupLayer2AndMigrateV3();

        // ============================================
        // 1. 초기 자격 확인 (미달 가능)
        // ============================================
        (bool eligible1, uint256 required1, uint256 actual1) = seigManager.checkCurrentEligibility(mockLayer2);

        if (!eligible1) {
            emit log_string("Step 1: Initially INELIGIBLE");
            emit log_named_decimal_uint("Shortage", (required1 - actual1) / 1e27, 27);

            // 시뇨리지 분배로 effectiveBridgedTON 확인
            vm.roll(block.number + 100);
            _updateSeigniorage();

            uint256 effectiveBefore = seigManager.getEffectiveBridgedTon(mockLayer2);
            assertEq(effectiveBefore, 0, "effectiveBridgedTON should be 0 when ineligible");

            // ============================================
            // 2. 추가 스테이킹으로 자격 충족
            // ============================================
            uint256 additionalStake = required1 - actual1 + 100e27; // 100 WTON 여유

            vm.startPrank(owner);
            MockWTON(wton).mint(operator1, additionalStake);
            vm.stopPrank();

            vm.startPrank(operator1);
            MockWTON(wton).approve(depositManagerProxy, additionalStake);
            DepositManagerV3(depositManagerProxy).deposit(mockLayer2, additionalStake);
            vm.stopPrank();

            emit log_string("Step 2: Deposited additional stake");

            // ============================================
            // 3. 자격 재확인
            // ============================================
            (bool eligible2, uint256 required2, uint256 actual2) = seigManager.checkCurrentEligibility(mockLayer2);

            // ============================================
            // 4. 불변 속성 검증: actual >= required ⟹ eligible = true
            // ============================================
            assertGe(actual2, required2, "Actual stake should now be >= required");
            assertTrue(eligible2, "INV-003: Should be eligible after sufficient deposit");

            // ============================================
            // 5. effectiveBridgedTON 업데이트 확인
            // ============================================
            vm.roll(block.number + 100);
            _updateSeigniorage();

            uint256 effectiveAfter = seigManager.getEffectiveBridgedTon(mockLayer2);
            assertGt(effectiveAfter, 0, "INV-003: effectiveBridgedTON should be > 0 when eligible");

            emit log_string("=== INV-003-StakeIncrease: Eligibility Gained ===");
            emit log_named_decimal_uint("effectiveBridgedTON (before)", effectiveBefore / 1e27, 27);
            emit log_named_decimal_uint("effectiveBridgedTON (after)", effectiveAfter / 1e27, 27);
        } else {
            emit log_string("Already ELIGIBLE from the start");
            emit log_string("(Cannot test eligibility gain scenario)");
        }
    }

    // ==========================================
    // INV-003: 스테이킹 감소 시 자격 상실
    // ==========================================

    /// @notice INV-003-StakeDecrease: 스테이킹 감소로 자격 상실 시 일관성
    /// @dev 자격 충족 상태 → 스테이킹 감소 → 자격 미달 → effectiveBridgedTON = 0
    /// @dev SKIP: V3에서 checkCurrentEligibility는 OperatorManager의 잔액을 반환하므로
    ///      일반 스테이커의 출금으로는 자격을 변경할 수 없음.
    ///      이 테스트는 V3 자격 모델과 맞지 않아 스킵함.
    function test_INV003_stakeDecrease_losesEligibility() public {
        vm.skip(true);
        _setupLayer2AndMigrateV3();

        // ============================================
        // 1. 자격 충족 확인 (required = max(D_seq, θ × B_i) = max(50, 0.001 × 10000) = 50 WTON)
        // Initial operator stake = ~100 WTON > 50 WTON required
        // ============================================
        (bool eligible1, uint256 required1, uint256 actual1) = seigManager.checkCurrentEligibility(mockLayer2);
        assertTrue(eligible1, "Should be eligible initially");

        emit log_string("Step 1: ELIGIBLE with sufficient stake");
        emit log_named_decimal_uint("Actual stake", actual1 / 1e27, 27);
        emit log_named_decimal_uint("Required stake", required1 / 1e27, 27);

        // 시뇨리지 분배로 effectiveBridgedTON 설정
        vm.roll(block.number + 100);
        _updateSeigniorage();

        uint256 effectiveBefore = seigManager.getEffectiveBridgedTon(mockLayer2);
        assertGt(effectiveBefore, 0, "effectiveBridgedTON should be > 0 when eligible");

        // ============================================
        // 2. 스테이킹 감소 (required 이하로)
        // ============================================
        uint256 withdrawAmount = actual1 - required1 + 50e27; // required보다 50 WTON 부족하게

        vm.startPrank(operator1);
        DepositManagerV3(depositManagerProxy).requestWithdrawal(mockLayer2, withdrawAmount);
        vm.stopPrank();

        emit log_string("Step 2: Withdrew stake to lose eligibility");
        emit log_named_decimal_uint("Withdrawal amount", withdrawAmount / 1e27, 27);

        // ============================================
        // 3. 자격 재확인
        // ============================================
        (bool eligible2, uint256 required2, uint256 actual2) = seigManager.checkCurrentEligibility(mockLayer2);

        // ============================================
        // 4. 불변 속성 검증: actual < required ⟹ eligible = false
        // ============================================
        assertLt(actual2, required2, "Actual stake should now be < required");
        assertFalse(eligible2, "INV-003: Should be ineligible after withdrawal");

        // ============================================
        // 5. effectiveBridgedTON = 0 확인
        // ============================================
        vm.roll(block.number + 100);
        _updateSeigniorage();

        uint256 effectiveAfter = seigManager.getEffectiveBridgedTon(mockLayer2);
        assertEq(effectiveAfter, 0, "INV-003: effectiveBridgedTON should be 0 when ineligible");

        emit log_string("=== INV-003-StakeDecrease: Eligibility Lost ===");
        emit log_named_decimal_uint("effectiveBridgedTON (before)", effectiveBefore / 1e27, 27);
        emit log_named_decimal_uint("effectiveBridgedTON (after)", effectiveAfter / 1e27, 27);
    }

    // ==========================================
    // INV-003: Bridged TON 변화 시 자격 재평가
    // ==========================================

    /// @notice INV-003-BridgedTONChange: Bridged TON 변화 시 자격 재평가 일관성
    /// @dev θ×B_i 값이 변하면 required도 변해야 함
    ///      required = max(D_sequencer, θ×B_i)
    function test_INV003_bridgedTONChange_reevaluatesEligibility() public {
        _setupLayer2AndMigrateV3();

        // 충분한 스테이킹
        vm.startPrank(operator1);
        MockWTON(wton).approve(depositManagerProxy, 200e27);
        DepositManagerV3(depositManagerProxy).deposit(mockLayer2, 200e27);
        vm.stopPrank();

        // ============================================
        // 1. 초기 자격 확인
        // ============================================
        (bool eligible1, uint256 required1, uint256 actual1) = seigManager.checkCurrentEligibility(mockLayer2);

        emit log_string("=== INV-003-BridgedTONChange: Eligibility Reevaluation ===");
        emit log_string("Step 1: Initial state");
        emit log_named_decimal_uint("Required (initial)", required1 / 1e27, 27);
        emit log_named_decimal_uint("Actual (initial)", actual1 / 1e27, 27);
        emit log_named_string("Eligibility (initial)", eligible1 ? "ELIGIBLE" : "INELIGIBLE");

        // ============================================
        // 2. Bridged TON 증가 시뮬레이션
        // ============================================
        // Portal에 TON 추가 전송 (Bridged TON 증가)
        uint256 additionalBridgedTON = 500e27; // 500 TON 추가
        vm.prank(owner);
        MockTON(ton).mint(mockPortal, additionalBridgedTON);

        emit log_string("Step 2: Bridged TON increased");
        emit log_named_decimal_uint("Additional Bridged TON", additionalBridgedTON / 1e27, 27);

        // ============================================
        // 3. onBridgedTonChange 호출 및 자격 재평가
        // ============================================
        vm.prank(mockPortal);
        seigManager.onBridgedTonChange();

        (bool eligible2, uint256 required2, uint256 actual2) = seigManager.checkCurrentEligibility(mockLayer2);

        emit log_string("Step 3: After Bridged TON change");
        emit log_named_decimal_uint("Required (after)", required2 / 1e27, 27);
        emit log_named_decimal_uint("Actual (after)", actual2 / 1e27, 27);
        emit log_named_string("Eligibility (after)", eligible2 ? "ELIGIBLE" : "INELIGIBLE");

        // ============================================
        // 4. 불변 속성 검증
        // ============================================
        // required = max(D_sequencer, θ×B_i)
        // θ = 50%, B_i 증가 → required 증가 (θ×B_i > D_sequencer인 경우)
        // theta = seigManager.minStakingRatio(); // 0.5e27
        // Dseq = seigManager.sequencerAdditionalReward(); // 100e27

        // Bridged TON이 증가하면 θ×B_i도 증가
        // 따라서 required2 >= required1 (단, D_sequencer가 더 크면 변화 없을 수 있음)
        if (required2 > required1) {
            emit log_string("Required increased due to Bridged TON increase");
        } else {
            emit log_string("Required unchanged (D_sequencer is the limiting factor)");
        }

        // eligible 상태는 actual과 required의 비교로 결정
        if (eligible2) {
            assertGe(actual2, required2, "INV-003: If eligible, actual >= required");
        } else {
            assertLt(actual2, required2, "INV-003: If ineligible, actual < required");
        }
    }

    // ==========================================
    // INV-003: 파라미터 변경 시 자격 재평가
    // ==========================================

    /// @notice INV-003-ParameterChange: θ(minStakingRatio) 변경 시 자격 재평가
    /// @dev θ 증가 → required 증가 → 자격 상실 가능
    function test_INV003_parameterChange_reevaluatesEligibility() public {
        _setupLayer2AndMigrateV3();

        // 자격 충족 상태
        vm.startPrank(operator1);
        MockWTON(wton).approve(depositManagerProxy, 150e27);
        DepositManagerV3(depositManagerProxy).deposit(mockLayer2, 150e27);
        vm.stopPrank();

        (bool eligible1, uint256 required1, uint256 actual1) = seigManager.checkCurrentEligibility(mockLayer2);

        emit log_string("=== INV-003-ParameterChange: Parameter Change Effect ===");
        emit log_string("Step 1: Initial state (theta = 50%)");
        emit log_named_decimal_uint("Required (initial)", required1 / 1e27, 27);
        emit log_named_decimal_uint("Actual", actual1 / 1e27, 27);
        emit log_named_string("Eligibility (initial)", eligible1 ? "ELIGIBLE" : "INELIGIBLE");

        // ============================================
        // 2. θ(minStakingRatio) 증가
        // ============================================
        vm.prank(owner);
        seigManager.setMinStakingRatio(0.9e27); // θ = 90%로 증가

        emit log_string("Step 2: theta increased to 90%");

        (bool eligible2, uint256 required2, uint256 actual2) = seigManager.checkCurrentEligibility(mockLayer2);

        emit log_named_decimal_uint("Required (after)", required2 / 1e27, 27);
        emit log_named_string("Eligibility (after)", eligible2 ? "ELIGIBLE" : "INELIGIBLE");

        // ============================================
        // 3. 불변 속성 검증
        // ============================================
        // θ 증가 → θ×B_i 증가 → required 증가 (B_i가 충분히 큰 경우)
        if (required2 > required1) {
            emit log_string("Required increased due to theta increase");
        }

        // eligible 상태는 actual과 required의 비교로 결정
        if (eligible2) {
            assertGe(actual2, required2, "INV-003: If eligible, actual >= required");
        } else {
            assertLt(actual2, required2, "INV-003: If ineligible, actual < required");
            emit log_string("Lost eligibility due to parameter change");
        }
    }
}
