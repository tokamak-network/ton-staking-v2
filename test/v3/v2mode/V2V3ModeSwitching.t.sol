// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./V2ModeTestBase.sol";

/// @title V2V3ModeSwitchingTest
/// @notice V2/V3 모드 전환 및 V2에서 V3 함수 호출 차단 테스트
/// @dev 이 테스트는 v3Migrated 플래그에 따른 함수 접근 제어를 검증합니다.
///      테스트 범위:
///      - V2 모드에서 V3 전용 함수 호출 시 적절한 차단/처리
///      - hyperbolicSaturation, onBridgedTonChange, RAT 연동 함수 등
///      - V2 → V3 마이그레이션 전환 테스트
contract V2V3ModeSwitchingTest is V2ModeTestBase {
    // V3 전용 컨트랙트 참조
    RAT public rat;

    // EligibilityChanged 이벤트 selector (재사용)
    bytes32 constant ELIGIBILITY_CHANGED_SELECTOR = keccak256("EligibilityChanged(address,bool,uint256,uint256)");

    function setUp() public {
        _baseSetUp();

        // RAT 참조 설정
        rat = RAT(ratProxy);
    }

    // ==========================================
    // 공통 헬퍼 함수
    // ==========================================

    /// @notice V3 마이그레이션 실행 (파라미터 설정 포함)
    function _migrateToV3() internal {
        vm.startPrank(owner);
        _setV3ParametersForTest();
        seigManager.migrateToV3();
        vm.stopPrank();
    }

    /// @notice V3 eligibility 충족을 위한 operator 추가 예치
    function _depositForV3Eligibility() internal {
        address operatorAddr = ILayer2(mockLayer2).operator();
        uint256 depositAmount = 6000 * RAY;
        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        DepositManagerV3(depositManagerProxy).deposit(mockLayer2, operatorAddr, depositAmount);
        vm.stopPrank();
    }

    /// @notice EligibilityChanged 이벤트가 발생하지 않았는지 확인
    function _assertNoEligibilityChangedEvent(Vm.Log[] memory logs, string memory message) internal pure {
        bool eventFound = false;
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == ELIGIBILITY_CHANGED_SELECTOR) {
                eventFound = true;
                break;
            }
        }
        assertFalse(eventFound, message);
    }

    /// @notice EligibilityChanged 이벤트가 발생했는지 확인
    function _assertEligibilityChangedEvent(Vm.Log[] memory logs, string memory message) internal pure {
        bool eventFound = false;
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == ELIGIBILITY_CHANGED_SELECTOR) {
                eventFound = true;
                break;
            }
        }
        assertTrue(eventFound, message);
    }

    /// @notice ValidatorReward 및 DAO 잔액 조회
    function _getValidatorRewardAndDAOBalances() internal view returns (
        address validatorRewardAddr,
        address daoAddr,
        uint256 validatorRewardBalance,
        uint256 daoBalance
    ) {
        validatorRewardAddr = seigManager.validatorReward();
        daoAddr = seigManager.dao();
        validatorRewardBalance = MockWTON(wton).balanceOf(validatorRewardAddr);
        daoBalance = MockWTON(wton).balanceOf(daoAddr);
    }

    // ==========================================
    // 3.1.3 V3 함수 호출 시 동작
    // ==========================================

    /// @notice SM-020-V2: V2에서 쌍곡선 함수 미사용 확인
    /// @dev V2에서는 hyperbolicSaturation이 호출되지 않아야 하거나, 호출되어도 분배에 영향 없음
    function test_SM020_v2_hyperbolicSaturation_notUsed() public view {
        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        // hyperbolicSaturation 함수 자체는 호출 가능 (pure/view 함수)
        uint256 L = 10000e27;
        uint256 x = 1000e27;

        uint256 result = seigManager.hyperbolicSaturation(x, L);

        // 함수는 동작: y(x) = L * x / (k + x)
        // x = k일 때 y = L/2
        assertGt(result, 0, "Function should return a value");

        // 하지만 V2 updateSeigniorage에서는 이 함수가 사용되지 않음
        // 실제 분배 검증은 V2Functions.t.sol의 SM-004-V2에서 수행
    }

    /// @notice SM-021-V2: V2에서 onBridgedTonChange 호출 테스트
    /// @dev V2 모드에서는 호출자(Portal/비Portal)에 관계없이 early return
    ///      revert하면 Portal 트랜잭션이 실패하므로 위험
    function test_SM021_v2_onBridgedTonChange_succeeds() public {
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        uint256 effectiveBefore = seigManager.getEffectiveBridgedTon(mockLayer2);

        // 1. Portal 호출 → V2에서는 아무 효과 없이 성공
        vm.prank(mockPortal);
        seigManager.onBridgedTonChange();
        assertEq(seigManager.getEffectiveBridgedTon(mockLayer2), effectiveBefore, "V2: Portal call should have no effect");

        // 2. 비Portal 호출 → 아무 효과 없이 성공 (revert 아님)
        vm.prank(address(0x1234));
        seigManager.onBridgedTonChange();
        assertEq(seigManager.getEffectiveBridgedTon(mockLayer2), effectiveBefore, "V2: Non-portal call should have no effect");

        // 3. EligibilityChanged 이벤트 미발생 확인
        vm.recordLogs();
        vm.prank(mockPortal);
        seigManager.onBridgedTonChange();
        _assertNoEligibilityChangedEvent(vm.getRecordedLogs(), "V2: EligibilityChanged event should NOT be emitted");
    }

    /// @notice SM-022-V2: V2에서 RAT 연동 함수는 설정은 가능하지만 실제 동작은 V3에서만
    /// @dev setRatContract는 V2에서도 호출 가능 (V3 마이그레이션 준비용)
    ///      하지만 transferCoinageToRat는 whenV3Active modifier에 의해 V2에서 revert
    ///      RAT 관련 전송 함수는 V3 전용 기능이므로 V2에서 차단됨
    function test_SM022_v2_transferCoinageToRat_revertInV2() public {
        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        // setRatContract는 V2에서도 호출 가능 (V3 마이그레이션 준비용)
        vm.prank(owner);
        seigManager.setRatContract(address(rat));
        assertEq(seigManager.ratContract(), address(rat), "RAT contract should be set in V2");

        // transferCoinageToRat는 whenV3Active modifier에 의해 V2에서 revert
        // RAT는 V3 전용 기능이므로 V2 모드에서는 사용 불가
        vm.prank(address(rat));
        vm.expectRevert(NotMigratedError.selector);
        seigManager.transferCoinageToRat(mockLayer2, validator1, 100e27);
    }

    /// @notice RAT-V2-001: V2에서 검증자 등록 시 revert
    /// @dev V2 모드에서는 RAT.registerValidator 호출 시 NotMigratedError
    ///      검증자 등록은 V3 마이그레이션 후에만 가능
    function test_RAT_v2_registerValidator_revertInV2() public {
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");
        _registerMockLayer2WithOperatorStakeAndInit();

        // validator1이 스테이킹 (D_min = 200 WTON 충족)
        vm.startPrank(validator1);
        MockWTON(wton).approve(depositManagerProxy, 300 * RAY);
        DepositManagerV3(depositManagerProxy).deposit(mockLayer2, validator1, 300 * RAY);

        // V2 모드에서 검증자 등록 시도 → NotMigratedError
        vm.expectRevert(NotMigratedError.selector);
        rat.registerValidator(address(mockSystemConfig));
        vm.stopPrank();
    }

    /// @notice SM-023-V2: V2에서 onStakingChange 호출 시 silent return
    /// @dev V2 모드에서는 onStakingChange가 아무 작업 없이 성공 반환
    ///      EligibilityChanged 이벤트 미발생 확인
    function test_SM023_v2_onStakingChange_succeeds() public {
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");
        _registerMockLayer2();

        vm.recordLogs();
        vm.prank(depositManagerProxy);
        seigManager.onStakingChange(mockLayer2);

        _assertNoEligibilityChangedEvent(vm.getRecordedLogs(), "V2: EligibilityChanged event should NOT be emitted");
    }

    /// @notice SM-024-V2: V2에서 ValidatorReward 분배 없음
    /// @dev V2 모드에서는 검증자 보상이 ValidatorReward로 분배되지 않음
    function test_SM024_v2_validatorReward_shouldNotDistribute() public {
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");
        _registerMockLayer2WithOperatorStakeAndInit();

        (address validatorRewardAddr,, uint256 validatorRewardBefore, uint256 daoBefore) = _getValidatorRewardAndDAOBalances();

        vm.roll(block.number + 100);
        _updateSeigniorage();

        uint256 validatorRewardAfter = MockWTON(wton).balanceOf(validatorRewardAddr);
        assertEq(validatorRewardAfter, validatorRewardBefore, "V2: ValidatorReward should not receive seigniorage");

        emit log_named_uint("V2 DAO balance change", MockWTON(wton).balanceOf(seigManager.dao()) - daoBefore);
    }

    /// @notice SM-024-V3-NoValidators: V3에서 검증자 0명 시 ValidatorReward → DAO로 전송
    /// @dev 검증자 없으면 ValidatorReward에 민팅 후 즉시 DAO로 전송됨
    function test_SM024_v3_noValidators_goesToDAO() public {
        _registerMockLayer2WithOperatorStakeAndInit();
        _migrateToV3();
        assertTrue(seigManager.v3Migrated(), "Should be in V3 mode");

        _depositForV3Eligibility();

        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 0, "V3: Should have 0 validators");

        (address validatorRewardAddr, address daoAddr, uint256 validatorRewardBefore, uint256 daoBefore) = _getValidatorRewardAndDAOBalances();

        vm.roll(block.number + 100);
        _updateSeigniorage();

        assertEq(MockWTON(wton).balanceOf(validatorRewardAddr), validatorRewardBefore, "V3 no validators: ValidatorReward balance unchanged");
        assertGt(MockWTON(wton).balanceOf(daoAddr), daoBefore, "V3 no validators: DAO should receive validator rewards");

        emit log_named_uint("V3 (0 validators) DAO balance increase", MockWTON(wton).balanceOf(daoAddr) - daoBefore);
    }

    /// @notice SM-024-V3-WithValidators: V3에서 검증자 1명+ 시 ValidatorReward에 시뇨리지 잔류
    /// @dev 검증자가 있으면 ValidatorReward에 시뇨리지가 pendingRewards로 누적됨
    function test_SM024_v3_withValidators_staysInValidatorReward() public {
        _registerMockLayer2WithOperatorStakeAndInit();
        _migrateToV3();
        assertTrue(seigManager.v3Migrated(), "Should be in V3 mode");

        _depositForV3Eligibility();

        // Portal 호출로 eligibility 업데이트
        vm.prank(mockPortal);
        seigManager.onBridgedTonChange();

        // 자격 상태 로깅
        (bool eligible, uint256 required, uint256 current) = seigManager.checkCurrentEligibility(mockLayer2);
        emit log_named_string("Eligible after Portal call", eligible ? "true" : "false");
        emit log_named_uint("Required stake", required);
        emit log_named_uint("Current stake", current);
        emit log_named_uint("effectiveBridgedTON", seigManager.getEffectiveBridgedTon(mockLayer2));

        // validator1 스테이킹 및 RAT 등록 (D_min = 200 WTON)
        vm.startPrank(validator1);
        MockWTON(wton).approve(depositManagerProxy, 300 * RAY);
        DepositManagerV3(depositManagerProxy).deposit(mockLayer2, validator1, 300 * RAY);
        rat.registerValidator(address(mockSystemConfig));
        vm.stopPrank();

        assertEq(rat.getActiveValidatorCount(address(mockSystemConfig)), 1, "V3: Should have 1 validator");

        address validatorRewardAddr = seigManager.validatorReward();
        uint256 validatorRewardBefore = MockWTON(wton).balanceOf(validatorRewardAddr);
        uint256 pendingRewardsBefore = IValidatorReward(validatorRewardAddr).getPendingRewards(validator1);
        assertEq(pendingRewardsBefore, 0, "V3 with validators: Initial pending rewards should be 0");

        vm.roll(block.number + 100);
        _updateSeigniorage();

        uint256 validatorRewardAfter = MockWTON(wton).balanceOf(validatorRewardAddr);
        assertGt(validatorRewardAfter, validatorRewardBefore, "V3 with validators: ValidatorReward should increase");

        uint256 pendingRewardsAfter = IValidatorReward(validatorRewardAddr).getPendingRewards(validator1);
        assertGt(pendingRewardsAfter, 0, "V3 with validators: Validator should have pending rewards");

        emit log_named_uint("V3 (1 validator) ValidatorReward balance increase", validatorRewardAfter - validatorRewardBefore);
        emit log_named_uint("V3 (1 validator) validator1 pending rewards", pendingRewardsAfter);
    }

    // ==========================================
    // 마이그레이션 전환 테스트
    // ==========================================

    /// @notice MIG-001: 마이그레이션 전후 v3Migrated 상태 확인
    function test_MIG001_migration_stateChange() public {
        // 초기 상태: V2
        assertFalse(seigManager.v3Migrated(), "Should start in V2 mode");
        assertEq(seigManager.v3MigrationBlock(), 0, "Migration block should be 0");

        // 마이그레이션 실행
        _migrateToV3();

        // 마이그레이션 후: V3
        assertTrue(seigManager.v3Migrated(), "Should be in V3 mode after migration");
        assertEq(seigManager.v3MigrationBlock(), block.number, "Migration block should be recorded");
    }

    /// @notice MIG-002: 중복 마이그레이션 시도 시 revert
    /// @dev 이미 마이그레이션된 상태에서 재시도 시 AlreadyMigratedError 발생
    function test_MIG002_migration_duplicateReverts() public {
        // 첫 번째 마이그레이션
        _migrateToV3();

        // 두 번째 마이그레이션 시도 - AlreadyMigratedError revert 예상
        vm.prank(owner);
        vm.expectRevert(AlreadyMigratedError.selector);
        seigManager.migrateToV3();
    }

    /// @notice MIG-006: V3에서 V2로 다운그레이드 불가
    /// @dev v3Migrated 플래그를 false로 되돌리는 함수가 없음
    ///      한번 V3로 마이그레이션하면 영구적으로 V3 모드 유지
    function test_MIG006_v3ToV2_downgradeNotPossible() public {
        // V2 → V3 마이그레이션
        assertFalse(seigManager.v3Migrated(), "Should start in V2 mode");
        _migrateToV3();
        assertTrue(seigManager.v3Migrated(), "Should be in V3 mode after migration");
        uint256 migrationBlock = seigManager.v3MigrationBlock();
        assertGt(migrationBlock, 0, "Migration block should be recorded");

        // 블록 진행 후에도 v3Migrated = true 유지
        vm.roll(block.number + 1000);
        assertTrue(seigManager.v3Migrated(), "V3 mode should persist after blocks");
        assertEq(seigManager.v3MigrationBlock(), migrationBlock, "Migration block should not change");

        // owner가 다시 migrateToV3 호출해도 revert (이미 V3)
        vm.prank(owner);
        vm.expectRevert(AlreadyMigratedError.selector);
        seigManager.migrateToV3();

        // v3Migrated는 여전히 true - 다운그레이드 경로 없음
        assertTrue(seigManager.v3Migrated(), "V3 mode is permanent - no downgrade path exists");

        // 참고: v3Migrated를 false로 설정하는 함수가 컨트랙트에 없음
        // migrateToV2() 같은 함수가 존재하지 않음
    }

    /// @notice MIG-003-Type3: Type 3 rollup에서 getEffectiveBridgedTon 업데이트 확인
    /// @dev Type 3: Portal에 브릿지된 TON + DisputeGameFactory 있음
    ///      Portal 호출 시 onBridgedTonChange → effectiveBridgedTON 업데이트
    function test_MIG003_type3_getEffectiveBridgedTon_shouldUpdate() public {
        // Type 3 Layer2 등록 (기본값)
        _registerMockLayer2WithOperatorStakeAndInit();

        // V3 마이그레이션 실행
        _migrateToV3();
        assertTrue(seigManager.v3Migrated(), "Should be in V3 mode");

        // V3 자격 충족을 위해 추가 예치
        _depositForV3Eligibility();

        // 초기 상태: effectiveBridgedTON = 0
        uint256 effectiveBefore = seigManager.getEffectiveBridgedTon(mockLayer2);
        emit log_named_uint("Type 3 effectiveBridgedTON before Portal call", effectiveBefore);

        // Portal에 추가 TON 전송 (브릿지 시뮬레이션)
        uint256 additionalTON = 5000 * 1e18;
        MockTON(ton).mint(mockPortal, additionalTON);

        // Portal 호출 → effectiveBridgedTON 업데이트
        vm.recordLogs();
        vm.prank(mockPortal);
        seigManager.onBridgedTonChange();
        Vm.Log[] memory logs = vm.getRecordedLogs();

        uint256 effectiveAfterPortal = seigManager.getEffectiveBridgedTon(mockLayer2);

        // Type 3: eligible이면 effectiveBridgedTON > 0
        (bool eligible, , ) = seigManager.checkCurrentEligibility(mockLayer2);
        assertTrue(eligible, "Type 3: Should be eligible after deposit");
        assertGt(effectiveAfterPortal, effectiveBefore, "Type 3: effectiveBridgedTON should increase after Portal call");
        _assertEligibilityChangedEvent(logs, "Type 3: EligibilityChanged event should be emitted");

        emit log_named_uint("Type 3 effectiveBridgedTON after Portal call", effectiveAfterPortal);
    }

    /// @notice MIG-003-Type2: Type 2 rollup에서 onBridgedTonChange 미지원 확인
    /// @dev Type 2: Portal에 브릿지된 TON (DisputeGameFactory 없음)
    ///      Type 2는 onBridgedTonChange 미지원 (rollupType != 3 이면 early return)
    function test_MIG003_type2_getEffectiveBridgedTon_shouldUpdate() public {
        // Type 2 Layer2 등록
        _registerMockLayer2Type2WithOperatorStakeAndInit();

        // V3 마이그레이션 실행
        _migrateToV3();
        assertTrue(seigManager.v3Migrated(), "Should be in V3 mode");

        // V3 자격 충족을 위해 추가 예치
        _depositForV3Eligibility();

        // 초기 상태: effectiveBridgedTON = 0
        uint256 effectiveBefore = seigManager.getEffectiveBridgedTon(mockLayer2);
        emit log_named_uint("Type 2 effectiveBridgedTON before Portal call", effectiveBefore);

        // Portal에 추가 TON 전송 (브릿지 시뮬레이션)
        uint256 additionalTON = 5000 * 1e18;
        MockTON(ton).mint(mockPortal, additionalTON);

        // Portal 호출 → Type 2는 onBridgedTonChange가 rollupType != 3 이면 early return
        vm.recordLogs();
        vm.prank(mockPortal);
        seigManager.onBridgedTonChange();
        Vm.Log[] memory logs = vm.getRecordedLogs();

        uint256 effectiveAfterPortal = seigManager.getEffectiveBridgedTon(mockLayer2);

        // Type 2: checkCurrentEligibility는 rollupType 3이 아니면 eligible=false 반환
        (bool eligible, uint256 requiredStake, ) = seigManager.checkCurrentEligibility(mockLayer2);
        assertFalse(eligible, "Type 2: Should NOT be eligible (rollupType != 3)");
        assertEq(requiredStake, 0, "Type 2: requiredStake should be 0");

        // Type 2: onBridgedTonChange는 효과 없음 (Type 3 전용)
        assertEq(effectiveAfterPortal, effectiveBefore, "Type 2: onBridgedTonChange should have no effect");
        _assertNoEligibilityChangedEvent(logs, "Type 2: EligibilityChanged event should NOT be emitted");

        emit log_named_uint("Type 2 effectiveBridgedTON after Portal call (no change)", effectiveAfterPortal);
    }

    /// @notice MIG-004-Type3: Type 3 rollup 마이그레이션 후 V3 함수 활성화 확인
    /// @dev Type 3 rollup에서 마이그레이션 후 V3 전용 함수들이 활성화되는지 검증
    function test_MIG004_type3_afterMigration_v3Functions_shouldActivate() public {
        // Layer2 등록 + operator 스테이킹 + 첫 번째 updateSeigniorage (마이그레이션 전)
        _registerMockLayer2WithOperatorStakeAndInit();

        // V3 마이그레이션 실행
        _migrateToV3();
        assertTrue(seigManager.v3Migrated(), "Should be in V3 mode");
        assertGt(seigManager.v3MigrationBlock(), 0, "Migration block should be recorded");

        // V3 자격 충족을 위해 operator에게 추가 예치
        _depositForV3Eligibility();

        // ============================================
        // V3 모드 활성화 검증
        // ============================================

        // 1. V3 파라미터가 설정되어 있음
        assertGt(seigManager.halfSaturationPoint(), 0, "V3: halfSaturationPoint should be set");
        assertGt(seigManager.minStakingRatio(), 0, "V3: minStakingRatio should be set");
        assertGt(seigManager.daoDistributionRatio(), 0, "V3: daoDistributionRatio should be set");
        assertGt(seigManager.validatorDistributionRatio(), 0, "V3: validatorDistributionRatio should be set");

        // 2. V3 모드에서 checkCurrentEligibility 확인 (Type 3 rollup)
        (bool eligible, uint256 requiredStake, uint256 currentStake) =
            seigManager.checkCurrentEligibility(mockLayer2);

        // Type 3 rollup: V3 eligibility 적용
        // requiredStake = max(θ×B_i, D_seq), currentStake = operator 스테이킹
        assertGt(currentStake, 0, "V3: currentStake should be > 0");
        assertGt(requiredStake, 0, "V3: Type 3 rollup requiredStake should be > 0");
        // eligible 여부는 currentStake >= requiredStake 에 따라 결정
        emit log_named_uint("V3 eligible", eligible ? 1 : 0);
        emit log_named_uint("V3 requiredStake", requiredStake);
        emit log_named_uint("V3 currentStake", currentStake);

        // 3. V3 모드에서 hyperbolicSaturation 함수 동작
        uint256 result = seigManager.hyperbolicSaturation(1000e27, 10000e27);
        assertGt(result, 0, "V3: hyperbolicSaturation should work");
        assertLt(result, 10000e27, "V3: result should be less than maxL2Allocation");

        // 4. updateSeigniorage가 V3 모드에서 성공
        vm.roll(block.number + 100);
        bool success = _updateSeigniorage();
        assertTrue(success, "V3: updateSeigniorage should succeed");
    }

    /// @notice MIG-004-Type2: Type 2 rollup 마이그레이션 후 V3 함수 동작 확인
    /// @dev Type 2 rollup에서는 checkCurrentEligibility가 eligible=false 반환
    function test_MIG004_type2_afterMigration_v3Functions_shouldActivate() public {
        // Type 2 Layer2 등록 + operator 스테이킹 + 첫 번째 updateSeigniorage (마이그레이션 전)
        _registerMockLayer2Type2WithOperatorStakeAndInit();

        // V3 마이그레이션 실행
        _migrateToV3();
        assertTrue(seigManager.v3Migrated(), "Should be in V3 mode");
        assertGt(seigManager.v3MigrationBlock(), 0, "Migration block should be recorded");

        // V3 자격 충족을 위해 operator에게 추가 예치
        _depositForV3Eligibility();

        // ============================================
        // V3 모드 활성화 검증 (Type 2 rollup)
        // ============================================

        // 1. V3 파라미터가 설정되어 있음
        assertGt(seigManager.halfSaturationPoint(), 0, "V3: halfSaturationPoint should be set");
        assertGt(seigManager.minStakingRatio(), 0, "V3: minStakingRatio should be set");
        assertGt(seigManager.daoDistributionRatio(), 0, "V3: daoDistributionRatio should be set");
        assertGt(seigManager.validatorDistributionRatio(), 0, "V3: validatorDistributionRatio should be set");

        // 2. Type 2 rollup에서 checkCurrentEligibility 확인
        (bool eligible, uint256 requiredStake, uint256 currentStake) =
            seigManager.checkCurrentEligibility(mockLayer2);

        // Type 2 rollup: rollupType != 3 이므로 eligible=false, requiredStake=0
        assertFalse(eligible, "V3: Type 2 rollup should NOT be eligible");
        assertEq(requiredStake, 0, "V3: Type 2 rollup requiredStake should be 0");
        assertGt(currentStake, 0, "V3: currentStake should be > 0");

        emit log_named_uint("Type 2 V3 eligible", eligible ? 1 : 0);
        emit log_named_uint("Type 2 V3 requiredStake", requiredStake);
        emit log_named_uint("Type 2 V3 currentStake", currentStake);

        // 3. V3 모드에서 hyperbolicSaturation 함수 동작 (Type 2에서도 호출 가능)
        uint256 result = seigManager.hyperbolicSaturation(1000e27, 10000e27);
        assertGt(result, 0, "V3: hyperbolicSaturation should work");
        assertLt(result, 10000e27, "V3: result should be less than maxL2Allocation");

        // 4. updateSeigniorage가 V3 모드에서 성공
        vm.roll(block.number + 100);
        bool success = _updateSeigniorage();
        assertTrue(success, "V3: updateSeigniorage should succeed");

        // Type 2는 onBridgedTonChange 미지원, effectiveBridgedTON=0 유지
        uint256 effectiveBridgedTON = seigManager.getEffectiveBridgedTon(mockLayer2);
        assertEq(effectiveBridgedTON, 0, "Type 2: effectiveBridgedTON should remain 0");
    }

    /// @notice MIG-005-Type3: Type 3 마이그레이션 후 deposit으로 자격 변경 확인
    /// @dev Type 3 rollup에서 deposit을 통해 currentStake 증가 및 자격 충족 확인
    function test_MIG005_type3_afterMigration_onStakingChange_shouldWork() public {
        // V3 마이그레이션 실행
        _migrateToV3();
        assertTrue(seigManager.v3Migrated(), "Should be in V3 mode");

        // Type 3 Layer2 등록 + operator 스테이킹 (V3 모드에서)
        _registerMockLayer2WithOperatorStake();

        // ============================================
        // deposit 전후 자격 상태 확인 (Type 3)
        // ============================================

        // 자격 상태 확인 (초기 - 자격 미달)
        (bool eligibleBefore, uint256 requiredBefore, uint256 currentBefore) =
            seigManager.checkCurrentEligibility(mockLayer2);

        emit log_named_uint("Type 3 before deposit - eligible", eligibleBefore ? 1 : 0);
        emit log_named_uint("Type 3 before deposit - requiredStake", requiredBefore);
        emit log_named_uint("Type 3 before deposit - currentStake", currentBefore);

        // Type 3: requiredStake > 0
        assertGt(requiredBefore, 0, "Type 3: requiredStake should be > 0");
        // 초기 자격 미달 확인 (currentStake < requiredStake)
        assertFalse(eligibleBefore, "Type 3: should NOT be eligible before additional deposit");
        assertLt(currentBefore, requiredBefore, "Type 3: currentStake should be less than requiredStake initially");

        // 추가 deposit으로 자격 충족
        address operatorAddr = ILayer2(mockLayer2).operator();
        uint256 depositAmount = 6000 * RAY;
        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        DepositManagerV3(depositManagerProxy).deposit(mockLayer2, operatorAddr, depositAmount);
        vm.stopPrank();

        // 자격 상태 확인 (이후 - 자격 충족)
        (bool eligibleAfter, uint256 requiredAfter, uint256 currentAfter) =
            seigManager.checkCurrentEligibility(mockLayer2);

        emit log_named_uint("Type 3 after deposit - eligible", eligibleAfter ? 1 : 0);
        emit log_named_uint("Type 3 after deposit - requiredStake", requiredAfter);
        emit log_named_uint("Type 3 after deposit - currentStake", currentAfter);

        // 추가 예치로 currentStake 증가
        assertGt(currentAfter, currentBefore, "Type 3: currentStake should increase after deposit");
        // 자격 충족 확인 (currentStake >= requiredStake)
        assertTrue(eligibleAfter, "Type 3: should be eligible after deposit");
        assertGe(currentAfter, requiredAfter, "Type 3: currentStake should be >= requiredStake");
    }

    /// @notice MIG-005-Type2: Type 2 마이그레이션 후 deposit해도 자격 항상 미달
    /// @dev Type 2 rollup에서는 deposit으로 currentStake 증가해도 eligible=false (rollupType != 3)
    function test_MIG005_type2_afterMigration_onStakingChange_shouldWork() public {
        // V3 마이그레이션 실행
        _migrateToV3();
        assertTrue(seigManager.v3Migrated(), "Should be in V3 mode");

        // Type 2 Layer2 등록 + operator 스테이킹 (V3 모드에서)
        _registerMockLayer2Type2WithOperatorStake();

        // ============================================
        // deposit 전후 자격 상태 확인 (Type 2)
        // ============================================

        // 자격 상태 확인 (초기)
        (bool eligibleBefore, uint256 requiredBefore, uint256 currentBefore) =
            seigManager.checkCurrentEligibility(mockLayer2);

        emit log_named_uint("Type 2 before deposit - eligible", eligibleBefore ? 1 : 0);
        emit log_named_uint("Type 2 before deposit - requiredStake", requiredBefore);
        emit log_named_uint("Type 2 before deposit - currentStake", currentBefore);

        // Type 2: eligible=false, requiredStake=0 (rollupType != 3)
        assertFalse(eligibleBefore, "Type 2: should NOT be eligible before deposit");
        assertEq(requiredBefore, 0, "Type 2: requiredStake should be 0");

        // 추가 deposit
        address operatorAddr = ILayer2(mockLayer2).operator();
        uint256 depositAmount = 6000 * RAY;
        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        DepositManagerV3(depositManagerProxy).deposit(mockLayer2, operatorAddr, depositAmount);
        vm.stopPrank();

        // 자격 상태 확인 (이후)
        (bool eligibleAfter, uint256 requiredAfter, uint256 currentAfter) =
            seigManager.checkCurrentEligibility(mockLayer2);

        emit log_named_uint("Type 2 after deposit - eligible", eligibleAfter ? 1 : 0);
        emit log_named_uint("Type 2 after deposit - requiredStake", requiredAfter);
        emit log_named_uint("Type 2 after deposit - currentStake", currentAfter);

        // Type 2: eligible=false, requiredStake=0 유지 (rollupType != 3)
        assertFalse(eligibleAfter, "Type 2: should still NOT be eligible after deposit");
        assertEq(requiredAfter, 0, "Type 2: requiredStake should still be 0");
        // 추가 예치로 currentStake 증가
        assertGt(currentAfter, currentBefore, "Type 2: currentStake should increase after deposit");
    }

    // ==========================================
    // 엣지 케이스
    // ==========================================

    /// @notice SM-025-V2: V3 파라미터 설정은 V2에서도 가능
    /// @dev V2에서 V3 파라미터를 미리 설정할 수 있지만, 분배에는 영향 없음
    function test_SM025_v2_canSetV3Parameters() public {
        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        // V3 파라미터 설정은 가능
        vm.startPrank(owner);
        seigManager.setDaoDistributionRatio(0.1e27);
        seigManager.setMinStakingRatio(0.5e27);
        seigManager.setValidatorDistributionRatio(0.2e27);
        seigManager.setHalfSaturationPoint(1000e27);
        vm.stopPrank();

        // 파라미터는 설정되지만, V2 분배에는 영향 없음
        assertEq(seigManager.daoDistributionRatio(), 0.1e27, "Parameter should be set");
        assertFalse(seigManager.v3Migrated(), "Still in V2 mode");
    }

    /// @notice SM-026-V2: V2에서 V3 컨트랙트 설정은 가능하지만 사용되지 않음
    /// @dev setRatContract, setValidatorReward는 V1_4에 정의되어 프록시에 등록됨
    ///      V2 모드에서도 호출 가능하지만, V3로 마이그레이션하기 전까지 실제 사용되지 않음
    function test_SM026_v2_canSetV3Contracts() public {
        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        // setRatContract와 setValidatorReward는 V1_4에 정의되어 있고 프록시에 등록됨
        // V2 모드에서도 호출 가능 (V3 마이그레이션 준비용)
        vm.startPrank(owner);
        seigManager.setRatContract(address(rat));
        seigManager.setValidatorReward(validatorPoolProxy);
        vm.stopPrank();

        // 설정은 완료되었지만 V3로 마이그레이션하기 전까지 사용되지 않음
        assertEq(seigManager.ratContract(), address(rat), "RAT contract should be set");
        assertEq(seigManager.validatorReward(), validatorPoolProxy, "Validator reward should be set");
        assertFalse(seigManager.v3Migrated(), "Still in V2 mode");
    }

    /// @notice SM-027-V2: V2에서 checkCurrentEligibility 호출
    /// @dev V3 전용 함수이지만 V2에서도 호출 가능
    ///      V2에서는 명시적으로 eligible=false, required=0 반환
    function test_SM027_v2_checkCurrentEligibility_returnsZero() public {
        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        // Layer2 등록 + operator 스테이킹
        _registerMockLayer2WithOperatorStake();

        // checkCurrentEligibility는 view 함수이므로 호출 가능
        (bool eligible, uint256 required, uint256 current) = seigManager.checkCurrentEligibility(mockLayer2);

        // V2 모드에서는 이 함수가 의미 없으므로:
        // - eligible = false (V3 전용 함수이므로 V2에서는 항상 부적격)
        // - required = 0 (V2에서는 의미 없음)
        // - current = operator의 실제 coinage 잔액
        assertFalse(eligible, "V2 mode: checkCurrentEligibility always returns false");
        assertEq(required, 0, "V2 mode: required should be 0");
        assertGt(current, 0, "Current stake should be > 0 (actual operator balance)");
    }

    /// @notice SM-028-V2: V2에서 getEffectiveBridgedTon 호출
    /// @dev V3 전용 storage이므로 V2에서는 초기값 0 반환
    ///      effectiveBridgedTON은 onBridgedTonChange() 호출 시에만 업데이트됨 (V3 전용)
    function test_SM028_v2_getEffectiveBridgedTon_returnsZero() public {
        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        // Layer2 등록 + operator 스테이킹
        _registerMockLayer2WithOperatorStake();

        // V2에서는 effectiveBridgedTON이 업데이트되지 않음 (V3 전용 storage)
        // 초기값 0 반환
        uint256 effective = seigManager.getEffectiveBridgedTon(mockLayer2);
        assertEq(effective, 0, "V2 mode: effectiveBridgedTON should be 0 (never updated)");
    }

    /// @notice SM-029-V2: V2 시뇨리지 연속 누적의 가법성 검증
    /// @dev V2는 선형 누적 방식으로, 여러 번의 분배에서 누적합 = 개별 증가량의 합
    ///      SM-001-V2와 차별화: SM-001은 블록 수 비례성만 검증, 이 테스트는 누적의 가법성 검증
    ///      (additivity: total = sum of parts)
    function test_SM029_v2_seigniorage_linearAccumulation() public {
        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        // Layer2 등록 + operator 스테이킹 + 첫 번째 updateSeigniorage
        _registerMockLayer2WithOperatorStakeAndInit();

        // 초기 상태 (첫 번째 updateSeigniorage 직후)
        uint256 l2Reward0 = seigManager.l2RewardPerUint();

        // 두 번째 분배 (80 블록)
        vm.roll(block.number + 80);
        _updateSeigniorage();
        uint256 l2Reward1 = seigManager.l2RewardPerUint();
        uint256 increase1 = l2Reward1 - l2Reward0;

        // 세 번째 분배 (120 블록)
        vm.roll(block.number + 120);
        _updateSeigniorage();
        uint256 l2Reward2 = seigManager.l2RewardPerUint();
        uint256 increase2 = l2Reward2 - l2Reward1;

        // 네 번째 분배 (50 블록)
        vm.roll(block.number + 50);
        _updateSeigniorage();
        uint256 l2Reward3 = seigManager.l2RewardPerUint();
        uint256 increase3 = l2Reward3 - l2Reward2;

        // 검증: 연속 누적의 가법성
        // 전체 증가량 = 각 개별 증가량의 합
        uint256 totalIncrease = l2Reward3 - l2Reward0;
        uint256 sumOfIncreases = increase1 + increase2 + increase3;

        assertGt(increase1, 0, "First increase > 0");
        assertGt(increase2, 0, "Second increase > 0");
        assertGt(increase3, 0, "Third increase > 0");

        // 가법성: total = sum of parts
        assertApproxEqRel(totalIncrease, sumOfIncreases, 0.01e18, "Additivity: total = sum of individual increases");

        // 각 증가량이 블록 수에 대해 독립적으로 계산됨을 확인
        // 80블록:120블록:50블록 비율 검증
        assertApproxEqRel(increase1 * 120, increase2 * 80, 0.01e18, "80 blocks : 120 blocks ratio");
        assertApproxEqRel(increase2 * 50, increase3 * 120, 0.01e18, "120 blocks : 50 blocks ratio");
    }
}
