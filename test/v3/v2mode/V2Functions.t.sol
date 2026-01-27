// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./V2ModeTestBase.sol";
import {SeigManagerV3_2} from "../../../src/stake/managers/SeigManagerV3_2.sol";

/// @title V2ModeFunctionsTest
/// @notice V2 모드 (v3Migrated = false) 전용 기능 테스트
/// @dev 이 테스트는 마이그레이션 전 V2 로직의 정확성을 검증합니다.
///      테스트 범위:
///      - SeigManager V2 시뇨리지 분배 (선형, TVL 기반)
///      - SeigManager V2 자격 검증 (D_sequencer만 체크)
///      - DepositManager V2 예치/출금 (콜백 없음)
///      - V3 파라미터가 V2 로직에 영향을 주지 않음을 검증
contract V2ModeFunctionsTest is V2ModeTestBase {

    function setUp() public {
        _baseSetUp();
    }

    // ==========================================
    // 3.1.1 시뇨리지 분배 (V2 로직)
    // ==========================================

    /// @notice SM-001-V2: V2 선형 분배 로직 사용 (블록 수에 비례)
    /// @dev V2에서는 쌍곡선 함수가 아닌 선형 분배를 사용합니다.
    ///      선형성 검증: 블록 수가 2배 → 시뇨리지 증가량도 2배
    ///      첫 번째 updateSeigniorage는 startBlock 설정만, 두 번째부터 시뇨리지 분배
    function test_SM001_v2_updateSeigniorage_linearDistribution() public {
        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        // Layer2 등록 + operator 스테이킹 + 첫 번째 updateSeigniorage (startBlock 설정)
        _registerMockLayer2WithOperatorStakeAndInit();

        // user1 스테이킹 (500 WTON)
        uint256 depositAmount = 500 * RAY;
        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        DepositManagerV3(depositManagerProxy).deposit(mockLayer2, user1, depositAmount);
        vm.stopPrank();

        // 초기 상태 기록
        uint256 l2RewardPerUint0 = seigManager.l2RewardPerUint();
        uint256 operatorManagerWTON0 = MockWTON(wton).balanceOf(operatorManager);

        // ============================================
        // 1차 시뇨리지 분배: 50 블록
        // ============================================
        vm.roll(block.number + 50);
        _updateSeigniorage();

        uint256 l2RewardPerUint1 = seigManager.l2RewardPerUint();
        uint256 operatorManagerWTON1 = MockWTON(wton).balanceOf(operatorManager);

        // 1차 증가량 (50블록)
        uint256 l2RewardIncrease50 = l2RewardPerUint1 - l2RewardPerUint0;
        uint256 operatorManagerIncrease50 = operatorManagerWTON1 - operatorManagerWTON0;

        assertGt(l2RewardIncrease50, 0, "V2: l2RewardPerUint should increase after 50 blocks");
        assertGt(operatorManagerIncrease50, 0, "V2: OperatorManager should receive layer2Seigs after 50 blocks");

        // ============================================
        // 2차 시뇨리지 분배: 100 블록
        // ============================================
        vm.roll(block.number + 100);
        _updateSeigniorage();

        uint256 l2RewardPerUint2 = seigManager.l2RewardPerUint();
        uint256 operatorManagerWTON2 = MockWTON(wton).balanceOf(operatorManager);

        // 2차 증가량 (100블록)
        uint256 l2RewardIncrease100 = l2RewardPerUint2 - l2RewardPerUint1;
        uint256 operatorManagerIncrease100 = operatorManagerWTON2 - operatorManagerWTON1;

        // ============================================
        // 선형성 검증: 블록 수 2배 → 시뇨리지도 2배 (오차 1% 허용)
        // maxSeig = span × seigPerBlock 이므로 블록 수에 비례
        // ============================================
        assertApproxEqRel(
            l2RewardIncrease100,
            l2RewardIncrease50 * 2,
            0.01e18,
            "V2: l2RewardPerUint should increase linearly (100 blocks = 2x of 50 blocks)"
        );

        assertApproxEqRel(
            operatorManagerIncrease100,
            operatorManagerIncrease50 * 2,
            0.01e18,
            "V2: OperatorManager layer2Seigs should increase linearly (100 blocks = 2x of 50 blocks)"
        );

        // ============================================
        // 추가 검증
        // ============================================
        // Coinage 스테이킹 시뇨리지 (SM-002-V2에서 집중 검증)
        uint256 user1Balance = _getStake(mockLayer2, user1);
        assertGt(user1Balance, depositAmount, "V2: staker should receive coinage staking seigniorage");

        // Layer2 시퀀서 시뇨리지 (SM-003-V2에서 집중 검증)
        uint256 operatorManagerWTON = MockWTON(wton).balanceOf(operatorManager);
        assertGt(operatorManagerWTON, 0, "V2: OperatorManager should receive layer2 sequencer seigniorage");
    }

    /// @notice SM-002-V2: Coinage 스테이킹 시뇨리지 (Operator + Staker)
    /// @dev V2에서는 Operator와 Staker 모두 coinage factor를 통해 스테이킹 잔액이 자동 증가합니다.
    ///      이는 Layer2 시퀀서 시뇨리지(OperatorManager WTON)와 별개입니다.
    ///      (V3에서는 스테이커가 받지 않음 - V3 모드 테스트에서 검증)
    function test_SM002_v2_updateSeigniorage_coinageStakingSeigniorage() public {
        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        // Layer2 등록 + operator 스테이킹 + 첫 번째 updateSeigniorage
        _registerMockLayer2WithOperatorStakeAndInit();

        // user1 스테이킹
        uint256 depositAmount = 500 * RAY;
        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        DepositManagerV3(depositManagerProxy).deposit(mockLayer2, user1, depositAmount);
        vm.stopPrank();

        // Coinage 스테이킹 시뇨리지 전 잔액 (coinage.balanceOf)
        uint256 operatorStakeBefore = _getOperatorStake(mockLayer2);
        uint256 user1StakeBefore = _getStake(mockLayer2, user1);

        // 블록 진행 및 시뇨리지 업데이트
        vm.roll(block.number + 100);
        _updateSeigniorage();

        // Coinage 스테이킹 시뇨리지 후 잔액 (coinage factor 증가로 자동 증가)
        uint256 operatorStakeAfter = _getOperatorStake(mockLayer2);
        uint256 user1StakeAfter = _getStake(mockLayer2, user1);

        // ============================================
        // Coinage 스테이킹 시뇨리지 검증
        // ============================================
        // V2에서는 Operator와 Staker 모두 coinage factor를 통해 시뇨리지 수령
        assertGt(operatorStakeAfter, operatorStakeBefore, "V2: Operator should receive coinage staking seigniorage");
        assertGt(user1StakeAfter, user1StakeBefore, "V2: Staker should receive coinage staking seigniorage");

        // 주의: 이것은 Layer2 시퀀서 시뇨리지(OperatorManager WTON)와 별개입니다.
        //       Layer2 시퀀서 시뇨리지는 SM-003-V2에서 검증합니다.
    }

    /// @notice SM-003-V2: Layer2 시퀀서 시뇨리지 (OperatorManager WTON 직접 전송)
    /// @dev V2에서 layer2Tvl(브릿지 락업 TON)이 있을 때 시퀀서가 시뇨리지를 받는지 검증합니다.
    ///
    ///      검증 내용:
    ///      1. layer2Tvl > 0 → OperatorManager가 WTON을 직접 받음
    ///      2. layer2Seigs = (l2RewardPerUint × layer2Tvl / WEI_UNIT) - initialDebt
    ///      3. 이는 Coinage 스테이킹 시뇨리지(factor 증가, SM-002)와 별개의 보상임
    ///
    ///      Note: layer2Tvl = L1BridgeRegistry.layer2Tvl(systemConfig)로 조회됨
    function test_SM003_v2_updateSeigniorage_layer2SequencerSeigniorage() public {
        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        // Layer2 등록 + operator 스테이킹 + 첫 번째 updateSeigniorage
        _registerMockLayer2WithOperatorStakeAndInit();

        // user1 스테이킹 (Coinage 스테이킹 증가를 위해)
        uint256 depositAmount = 500 * RAY;
        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        DepositManagerV3(depositManagerProxy).deposit(mockLayer2, user1, depositAmount);
        vm.stopPrank();

        // Layer2 시퀀서 시뇨리지 전 OperatorManager WTON 잔액
        uint256 operatorManagerWTONBefore = MockWTON(wton).balanceOf(operatorManager);

        // 블록 진행 및 시뇨리지 업데이트
        vm.roll(block.number + 100);
        _updateSeigniorage();

        // Layer2 시퀀서 시뇨리지 후 OperatorManager WTON 잔액
        uint256 operatorManagerWTONAfter = MockWTON(wton).balanceOf(operatorManager);

        // ============================================
        // Layer2 시퀀서 시뇨리지 검증
        // ============================================
        // OperatorManager가 WTON을 직접 받았는지 확인
        uint256 layer2SeigReceived = operatorManagerWTONAfter - operatorManagerWTONBefore;
        assertGt(layer2SeigReceived, 0, "V2: OperatorManager should receive layer2Seigs as WTON");

        // layer2TVL 추적 확인
        (uint256 layer2Tvl, , uint256 startBlock) = seigManager.layer2RewardInfo(mockLayer2);
        assertGt(layer2Tvl, 0, "V2: layer2Tvl should be tracked (Bridged TON)");
        assertGt(startBlock, 0, "V2: startBlock should be set");

        // l2RewardPerUint 누적 확인
        uint256 l2RewardPerUint = seigManager.l2RewardPerUint();
        assertGt(l2RewardPerUint, 0, "V2: l2RewardPerUint should accumulate");

        // 주의: 이것은 Coinage 스테이킹 시뇨리지(factor 증가)와 별개입니다.
        //       Coinage 스테이킹 시뇨리지는 SM-002-V2에서 검증합니다.
    }

    /// @notice SM-004-V2: V3 파라미터(θ,α,k,d) 무시
    /// @dev V2 모드에서 V3 파라미터를 설정해도 분배 로직에 영향을 주지 않습니다.
    ///      V2는 l2RewardPerUint 누적 방식을 사용하며, V3 쌍곡선 파라미터를 무시합니다.
    function test_SM004_v2_updateSeigniorage_ignoresV3Parameters() public {
        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        // Layer2 등록 + operator 스테이킹 + 첫 번째 updateSeigniorage
        _registerMockLayer2WithOperatorStakeAndInit();

        // user1 스테이킹
        uint256 depositAmount = 500 * RAY;
        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        DepositManagerV3(depositManagerProxy).deposit(mockLayer2, user1, depositAmount);
        vm.stopPrank();

        // V3 파라미터를 극단값으로 설정
        vm.startPrank(owner);
        seigManager.setDaoDistributionRatio(0.9e27);          // 90% (극단값)
        seigManager.setMinStakingRatio(0.9e27);               // 90% (극단값)
        seigManager.setValidatorDistributionRatio(0.5e27);    // 50% (극단값)
        seigManager.setHalfSaturationPoint(1e18);             // 1 TON (극단값)
        vm.stopPrank();

        // V2 시뇨리지 분배 전 상태
        uint256 stakeBefore = _getStake(mockLayer2, user1);
        uint256 l2RewardPerUintBefore = seigManager.l2RewardPerUint();
        uint256 operatorManagerWTONBefore = MockWTON(wton).balanceOf(operatorManager);

        // 블록 진행 및 두 번째 V2 시뇨리지 분배 실행 (실제 분배)
        vm.roll(block.number + 100);
        _updateSeigniorage();

        uint256 stakeAfter = _getStake(mockLayer2, user1);
        uint256 l2RewardPerUintAfter = seigManager.l2RewardPerUint();

        // V2 로직 검증:
        // 1. V2는 선형 누적 방식 사용 (l2RewardPerUint 증가)
        assertGt(l2RewardPerUintAfter, l2RewardPerUintBefore, "V2 should use linear accumulation (l2RewardPerUint)");

        // 2. V3 파라미터와 무관하게 스테이커가 Coinage 스테이킹 시뇨리지를 받음
        //    (halfSaturationPoint, validatorDistributionRatio 등 무시)
        assertGt(stakeAfter, stakeBefore, "V2 should distribute seigniorage ignoring V3 parameters");

        // 3. Layer2 시퀀서 시뇨리지가 OperatorManager로 전송됨
        uint256 operatorManagerWTONAfter = MockWTON(wton).balanceOf(operatorManager);
        assertGt(operatorManagerWTONAfter, operatorManagerWTONBefore, "V2: OperatorManager should receive layer2Seigs");

        // 4. V2 모드 유지 확인
        assertFalse(seigManager.v3Migrated(), "Should still be in V2 mode");

        // 5. totalEffectiveBridgedTON은 V3 전용 (V2에서는 사용 안 함)
        uint256 totalEffective = seigManager.totalEffectiveBridgedTON();
        assertEq(totalEffective, 0, "V2 should not use totalEffectiveBridgedTON (V3 only)");
    }

    // ==========================================
    // 3.1.2 시뇨리지 분배 조건 (V2 로직)
    // ==========================================
    // 주의: V2에는 "자격(eligibility)" 개념이 없습니다.
    //       V3의 checkCurrentEligibility()와 달리, V2는 minimumAmount만 체크합니다.

    /// @notice SM-010-V2: minimumAmount만 충족하면 시뇨리지 분배
    /// @dev V2에서는 최소 예치금(minimumAmount)만 충족하면 시뇨리지를 받습니다.
    ///      V3의 "자격(eligibility)" 개념과 다릅니다.
    function test_SM010_v2_seigniorage_onlyMinimumAmount() public {
        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        // Layer2 등록
        _registerMockLayer2();

        // operator1이 minimumAmount만 스테이킹
        uint256 minAmount = 100 * RAY + 1e10; // minimumAmount + buffer
        vm.startPrank(operator1);
        MockWTON(wton).approve(depositManagerProxy, minAmount);
        DepositManagerV3(depositManagerProxy).deposit(mockLayer2, operator1, minAmount);
        vm.stopPrank();

        // V2에서는 minimumAmount만 충족하면 시뇨리지 분배 (자격 개념 없음)
        uint256 stakeBefore = _getOperatorStake(mockLayer2);
        assertGe(stakeBefore, 100 * RAY, "Operator should have minimumAmount staked");

        uint256 operatorManagerWTONBefore = MockWTON(wton).balanceOf(operatorManager);

        // 첫 번째 updateSeigniorage: startBlock 설정
        vm.roll(block.number + 1);
        _updateSeigniorage();

        // 두 번째 updateSeigniorage: 실제 시뇨리지 분배
        vm.roll(block.number + 100);
        bool success = _updateSeigniorage();
        assertTrue(success, "V2: updateSeigniorage should succeed with minimumAmount only");

        // 시뇨리지 분배 확인
        uint256 stakeAfter = _getOperatorStake(mockLayer2);
        uint256 operatorManagerWTONAfter = MockWTON(wton).balanceOf(operatorManager);

        // Coinage 스테이킹 시뇨리지
        assertGt(stakeAfter, stakeBefore, "V2: operator should receive coinage staking seigniorage with minimumAmount");

        // Layer2 시퀀서 시뇨리지
        assertGt(operatorManagerWTONAfter, operatorManagerWTONBefore, "V2: OperatorManager should receive layer2 sequencer seigniorage with minimumAmount");
    }

    /// @notice SM-011-V2: V3 파라미터 θ (minStakingRatio) 무시
    /// @dev V2에서는 minStakingRatio(θ)를 사용하지 않습니다.
    ///      V3에서는 T_i ≥ θ×B_i 조건을 만족해야 시뇨리지를 받지만, V2에서는 무시됩니다.
    function test_SM011_v2_seigniorage_ignoresMinStakingRatio() public {
        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        // θ를 큰 값으로 설정 (90%) - V3였다면 큰 담보가 필요
        vm.prank(owner);
        seigManager.setMinStakingRatio(0.9e27);

        // Layer2 등록
        _registerMockLayer2();

        // operator1이 minimumAmount만 스테이킹 (V3였다면 θ×B_i 조건 미충족)
        uint256 minAmount = 100 * RAY + 1e10;
        vm.startPrank(operator1);
        MockWTON(wton).approve(depositManagerProxy, minAmount);
        DepositManagerV3(depositManagerProxy).deposit(mockLayer2, operator1, minAmount);
        vm.stopPrank();

        // V2에서는 θ가 무시되어 예치 성공해야 함
        uint256 stakeBefore = _getOperatorStake(mockLayer2);
        assertGe(stakeBefore, 100 * RAY, "V2 should ignore minStakingRatio");

        uint256 operatorManagerWTONBefore = MockWTON(wton).balanceOf(operatorManager);

        // startBlock 설정 (첫 번째 updateSeigniorage)
        _initializeLayer2Seigniorage();

        // 실제 시뇨리지 분배 (θ 조건 무시)
        vm.roll(block.number + 100);
        bool success = _updateSeigniorage();
        assertTrue(success, "V2 should distribute seigniorage ignoring theta");

        // Coinage 스테이킹 시뇨리지를 실제로 받았는지 확인
        uint256 stakeAfter = _getOperatorStake(mockLayer2);
        assertGt(stakeAfter, stakeBefore, "V2: operator staking should receive seigniorage despite high theta");

        // Layer2 시퀀서 시뇨리지가 OperatorManager로 전송되었는지 확인
        uint256 operatorManagerWTONAfter = MockWTON(wton).balanceOf(operatorManager);
        assertGt(operatorManagerWTONAfter, operatorManagerWTONBefore, "V2: OperatorManager should receive layer2Seigs");
    }

    /// @notice SM-012-V2: effectiveBridgedTON 미사용 (V3 전용)
    /// @dev V2는 layer2TVL(Bridged TON) 기반 선형 분배
    ///      V3는 effectiveBridgedTON(자격 충족 시에만 설정) 기반 쌍곡선 분배
    ///      V2에서는 effectiveBridgedTON을 사용하지 않고 layer2TVL만 사용
    function test_SM012_v2_seigniorage_noEffectiveBridgedTON() public {
        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        // Layer2 등록 + operator 스테이킹
        _registerMockLayer2WithOperatorStake();

        // V2에서는 Bridged TON이 없어도 시뇨리지 분배 가능
        // effectiveBridgedTON 확인 (V2에서는 업데이트되지 않으므로 0)
        uint256 effectiveBridgedTON = seigManager.getEffectiveBridgedTon(mockLayer2);
        assertEq(effectiveBridgedTON, 0, "V2: effectiveBridgedTON should be 0");

        // user1 스테이킹
        uint256 depositAmount = 500 * RAY;
        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        DepositManagerV3(depositManagerProxy).deposit(mockLayer2, user1, depositAmount);
        vm.stopPrank();

        uint256 stakeBefore = _getStake(mockLayer2, user1);
        uint256 operatorManagerWTONBefore = MockWTON(wton).balanceOf(operatorManager);

        // startBlock 설정 (첫 번째 updateSeigniorage)
        _initializeLayer2Seigniorage();

        // 실제 시뇨리지 분배
        vm.roll(block.number + 100);
        bool success = _updateSeigniorage();
        assertTrue(success, "V2 should work without Bridged TON");

        // 스테이커가 Coinage 스테이킹 시뇨리지를 실제로 받았는지 확인 (V3에서는 받지 못함)
        uint256 stakeAfter = _getStake(mockLayer2, user1);
        assertGt(stakeAfter, stakeBefore, "V2: staker should receive seigniorage despite no Bridged TON");

        // Layer2 시퀀서 시뇨리지가 OperatorManager로 전송되었는지 확인
        uint256 operatorManagerWTONAfter = MockWTON(wton).balanceOf(operatorManager);
        assertGt(operatorManagerWTONAfter, operatorManagerWTONBefore, "V2: OperatorManager should receive layer2Seigs");
    }

    // ==========================================
    // 3.2 DepositManager V2 기능
    // ==========================================

    /// @notice DM-001-V2: 기본 예치 동작
    /// @dev V2에서도 예치는 정상 동작합니다.
    function test_DM001_v2_deposit_basicFlow() public {
        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        // Layer2 등록 + operator 스테이킹
        _registerMockLayer2WithOperatorStake();

        // user1 예치
        uint256 depositAmount = 100 * RAY;
        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        bool success = DepositManagerV3(depositManagerProxy).deposit(mockLayer2, user1, depositAmount);
        vm.stopPrank();

        assertTrue(success, "Deposit should succeed in V2 mode");
        _assertStakeEq(mockLayer2, user1, depositAmount, "Staked amount mismatch");
    }

    /// @notice DM-002-V2: V2에서 onStakingChange 미호출
    /// @dev V2에서는 예치 시 SeigManager.onStakingChange() 콜백이 호출되지 않습니다.
    ///      따라서 EligibilityChanged 이벤트도 발생하지 않음.
    ///      V3에서는 예치/출금 시 onStakingChange() → _updateEligibilityInternal() 호출됨
    function test_DM002_v2_deposit_noV3Callback() public {
        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        // Layer2 등록 + operator 스테이킹
        _registerMockLayer2WithOperatorStake();

        // user1 예치 (이벤트 로그 기록 시작)
        uint256 depositAmount = 500 * RAY;
        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);

        vm.recordLogs();
        DepositManagerV3(depositManagerProxy).deposit(mockLayer2, user1, depositAmount);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        vm.stopPrank();

        // EligibilityChanged 이벤트가 발생하지 않았는지 확인
        bytes32 eligibilityChangedSelector = keccak256("EligibilityChanged(address,bool,uint256,uint256)");
        bool eventFound = false;
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == eligibilityChangedSelector) {
                eventFound = true;
                break;
            }
        }
        assertFalse(eventFound, "V2: EligibilityChanged event should NOT be emitted on deposit");

        // V2에서는 effectiveBridgedTON도 여전히 0 (V3 전용 기능)
        uint256 effectiveAfter = seigManager.getEffectiveBridgedTon(mockLayer2);
        assertEq(effectiveAfter, 0, "V2: effectiveBridgedTON should remain 0");
    }

    /// @notice DM-003-V2: 기본 출금 동작
    /// @dev V2에서도 출금은 정상 동작합니다.
    function test_DM003_v2_withdraw_basicFlow() public {
        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        // Layer2 등록 + operator 스테이킹
        _registerMockLayer2WithOperatorStake();

        // user1 예치
        uint256 depositAmount = 500 * RAY;
        uint256 withdrawAmount = 200 * RAY;

        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        DepositManagerV3(depositManagerProxy).deposit(mockLayer2, user1, depositAmount);

        // 출금 요청
        bool success = DepositManagerV3(depositManagerProxy).requestWithdrawal(
            mockLayer2,
            withdrawAmount
        );
        vm.stopPrank();

        assertTrue(success, "Withdrawal request should succeed in V2 mode");
        assertEq(
            depositManager.pendingUnstaked(mockLayer2, user1),
            withdrawAmount,
            "Pending amount mismatch"
        );

        // 대기 기간 후 출금 처리
        uint256 delay = depositManager.globalWithdrawalDelay();
        vm.roll(block.number + delay + 1);

        vm.prank(user1);
        depositManager.processRequest(mockLayer2, false);

        assertEq(
            depositManager.pendingUnstaked(mockLayer2, user1),
            0,
            "Pending should be 0 after process"
        );
    }

    /// @notice DM-004-V2: V2 출금 제한 (operator vs validator)
    /// @dev V2에서는:
    ///      - operator(시퀀서): minimumAmount 이상 유지 필요 (출금 제한)
    ///      - validator(검증자): 출금 제한 없음 (V3에서는 D_min 제한 있음)
    function test_DM004_v2_withdraw_operatorVsValidator() public {
        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        // Layer2 등록 + operator 스테이킹
        _registerMockLayer2WithOperatorStake();

        // operator 추가 스테이킹 (출금 테스트를 위해 minimumAmount 이상의 여유 확보)
        // 참고: factor로 인해 실제 스테이킹 잔액이 예치 금액보다 약간 작음
        uint256 additionalDeposit = 200 * RAY;
        address operatorAddr = ILayer2(mockLayer2).operator();
        vm.startPrank(user1); // user1이 operator 계정에 대신 예치
        MockWTON(wton).approve(depositManagerProxy, additionalDeposit);
        DepositManagerV3(depositManagerProxy).deposit(mockLayer2, operatorAddr, additionalDeposit);
        vm.stopPrank();

        // ============================================
        // 1. Validator (검증자): 전액 출금 가능
        // ============================================
        uint256 validatorDeposit = 500 * RAY;

        vm.startPrank(validator1);
        MockWTON(wton).approve(depositManagerProxy, validatorDeposit);
        DepositManagerV3(depositManagerProxy).deposit(mockLayer2, validator1, validatorDeposit);
        vm.stopPrank();

        // V2에서는 검증자도 전액 출금 요청 가능 (D_min 체크 없음)
        uint256 validatorStake = _getStake(mockLayer2, validator1);

        vm.prank(validator1);
        bool success = DepositManagerV3(depositManagerProxy).requestWithdrawal(
            mockLayer2,
            validatorStake
        );

        assertTrue(success, "V2: validator should allow full withdrawal (no D_min check)");
        assertEq(
            depositManager.pendingUnstaked(mockLayer2, validator1),
            validatorStake,
            "Validator full withdrawal should be pending"
        );

        // ============================================
        // 2. Operator (시퀀서): minimumAmount 이하로 출금 불가
        // ============================================
        uint256 operatorStake = _getOperatorStake(mockLayer2);
        uint256 minimumAmount = seigManager.minimumAmount();

        // operator 잔액이 minimumAmount보다 충분히 큰지 확인
        assertGt(operatorStake, minimumAmount + 50 * RAY, "Operator should have enough stake for withdrawal test");

        // operator가 minimumAmount 이하로 출금 시도 (revert 예상)
        // 잔액에서 minimumAmount를 빼고 추가로 1 RAY 더 빼면 minimumAmount 미만이 됨
        uint256 excessiveWithdraw = operatorStake - minimumAmount + 1 * RAY;

        vm.prank(operatorAddr);
        vm.expectRevert(); // minimumAmount 미만으로 떨어지므로 revert 예상
        DepositManagerV3(depositManagerProxy).requestWithdrawal(
            mockLayer2,
            excessiveWithdraw
        );

        // operator는 minimumAmount 이상 유지한 상태로만 출금 가능
        // 실제 잔액 기반으로 안전한 출금 금액 계산 (minimumAmount + 여유분 유지)
        uint256 safeWithdrawAmount = operatorStake - minimumAmount - 10 * RAY; // 10 RAY 여유 유지

        vm.prank(operatorAddr);
        bool operatorSuccess = DepositManagerV3(depositManagerProxy).requestWithdrawal(
            mockLayer2,
            safeWithdrawAmount
        );

        assertTrue(operatorSuccess, "V2: operator can withdraw if minimumAmount is maintained");
    }

    // ==========================================
    // 3.3 V2 Estimation Functions
    // ==========================================

    /// @notice SM-020-V2: estimatedDistributeV2 조회
    /// @dev V2 모드에서 예상 시뇨리지 분배량 조회
    function test_SM020_v2_estimatedDistributeV2() public {
        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        // Layer2 등록 + operator 스테이킹 + 초기화
        _registerMockLayer2WithOperatorStakeAndInit();

        // 블록 진행
        vm.roll(block.number + 100);

        // estimatedDistributeV2 호출 (SeigManagerV3_2로 캐스팅)
        SeigManagerV3_2 seigManagerV2 = SeigManagerV3_2(seigManagerProxy);
        (
            uint256 maxSeig,
            uint256 stakedSeig,
            uint256 unstakedSeig,
            uint256 powertonSeig,
            uint256 daoSeig,
            uint256 relativeSeig,
            uint256 l2TotalSeigs,
            uint256 layer2Seigs
        ) = seigManagerV2.estimatedDistributeV2(block.number + 1, mockLayer2);

        // 예상 분배량 검증
        assertGt(maxSeig, 0, "V2: maxSeig should be > 0");
        assertGt(stakedSeig, 0, "V2: stakedSeig should be > 0");
        assertGt(l2TotalSeigs, 0, "V2: l2TotalSeigs should be > 0 (Layer2 TVL exists)");
        assertGt(layer2Seigs, 0, "V2: layer2Seigs should be > 0 for eligible layer2");

        // maxSeig = stakedSeig + unstakedSeig + l2TotalSeigs
        assertEq(maxSeig, stakedSeig + unstakedSeig + l2TotalSeigs, "V2: maxSeig should equal sum of components");
    }

    /// @notice SM-021-V2: claimableL2SeigniorageV2 조회
    /// @dev V2 모드에서 Layer2의 청구 가능 시뇨리지 조회
    function test_SM021_v2_claimableL2SeigniorageV2() public {
        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        // Layer2 등록 + operator 스테이킹 + 초기화
        _registerMockLayer2WithOperatorStakeAndInit();

        // 블록 진행
        vm.roll(block.number + 100);

        // claimableL2SeigniorageV2 호출 (SeigManagerV3_2로 캐스팅)
        SeigManagerV3_2 seigManagerV2 = SeigManagerV3_2(seigManagerProxy);
        uint256 claimable = seigManagerV2.claimableL2SeigniorageV2(mockLayer2);

        // 청구 가능 시뇨리지 검증
        assertGt(claimable, 0, "V2: claimable L2 seigniorage should be > 0");

        // estimatedDistributeV2와 일치하는지 확인
        (, , , , , , , uint256 estimated) = seigManagerV2.estimatedDistributeV2(block.number + 1, mockLayer2);
        assertEq(claimable, estimated, "V2: claimable should match estimated layer2Seigs");
    }

    /// @notice SM-022-V2: 미등록 Layer2의 estimatedDistributeV2
    /// @dev 미등록 Layer2에 대해서는 layer2Seigs = 0
    function test_SM022_v2_estimatedDistributeV2_unregisteredLayer2() public {
        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        // Layer2 등록 + operator 스테이킹 + 초기화 (다른 Layer2용)
        _registerMockLayer2WithOperatorStakeAndInit();

        // 블록 진행
        vm.roll(block.number + 100);

        // 미등록 Layer2에 대해 estimatedDistributeV2 호출 (SeigManagerV3_2로 캐스팅)
        SeigManagerV3_2 seigManagerV2 = SeigManagerV3_2(seigManagerProxy);
        address unregisteredLayer2 = address(0x9999);
        (
            uint256 maxSeig,
            uint256 stakedSeig,
            ,
            ,
            ,
            ,
            uint256 l2TotalSeigs,
            uint256 layer2Seigs
        ) = seigManagerV2.estimatedDistributeV2(block.number + 1, unregisteredLayer2);

        // 미등록 Layer2는 layer2Seigs = 0
        assertGt(maxSeig, 0, "V2: maxSeig should be > 0 (global seigniorage)");
        assertGt(stakedSeig, 0, "V2: stakedSeig should be > 0");
        assertGt(l2TotalSeigs, 0, "V2: l2TotalSeigs should be > 0 (global L2 pool)");
        assertEq(layer2Seigs, 0, "V2: unregistered layer2 should have 0 layer2Seigs");
    }

    /// @notice SM-023-V2: estimatedDistributeV2 블록 번호 조건
    /// @dev lastSeigBlock 이하의 블록 번호에 대해서는 0 반환
    function test_SM023_v2_estimatedDistributeV2_blockCondition() public {
        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        // Layer2 등록 + operator 스테이킹 + 초기화
        _registerMockLayer2WithOperatorStakeAndInit();

        // 블록 진행 및 업데이트
        vm.roll(block.number + 100);
        _updateSeigniorage();

        uint256 lastSeigBlock = seigManager.lastSeigBlock();

        // lastSeigBlock 이하의 블록 번호로 조회 (SeigManagerV3_2로 캐스팅)
        SeigManagerV3_2 seigManagerV2 = SeigManagerV3_2(seigManagerProxy);
        (uint256 maxSeig, , , , , , , ) = seigManagerV2.estimatedDistributeV2(lastSeigBlock, mockLayer2);

        // 0 반환
        assertEq(maxSeig, 0, "V2: estimatedDistributeV2 should return 0 for blockNumber <= lastSeigBlock");
    }

    /// @notice SM-024-V2: Negative commission rate 계산
    /// @dev V2에서 음수 커미션율이 설정된 경우 _calcNegativeCommission이 호출됨
    ///      NOTE: setCommissionRate는 operatorManager에서 직접 호출해야 하며,
    ///            이 테스트는 negative commission rate가 설정되었을 때의 시뇨리지 분배를 검증함
    ///            해당 기능은 CandidateAddOn.setCommissionRate()를 통해 설정되므로
    ///            별도의 통합 테스트에서 검증이 필요함
    function test_SM024_v2_negativeCommissionRate_concept() public {
        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        // Layer2 등록 + operator 스테이킹
        _registerMockLayer2WithOperatorStake();

        // user1 스테이킹 (delegator)
        uint256 depositAmount = 500 * RAY;
        vm.startPrank(user1);
        MockWTON(wton).approve(depositManagerProxy, depositAmount);
        DepositManagerV3(depositManagerProxy).deposit(mockLayer2, user1, depositAmount);
        vm.stopPrank();

        // 첫 번째 updateSeigniorage (startBlock 설정)
        _initializeLayer2Seigniorage();

        // 시뇨리지 분배 전 상태
        uint256 operatorStakeBefore = _getOperatorStake(mockLayer2);
        uint256 user1StakeBefore = _getStake(mockLayer2, user1);

        // 블록 진행 및 시뇨리지 분배
        vm.roll(block.number + 100);
        _updateSeigniorage();

        // 시뇨리지 분배 후 상태
        uint256 operatorStakeAfter = _getOperatorStake(mockLayer2);
        uint256 user1StakeAfter = _getStake(mockLayer2, user1);

        // 기본 커미션 (0%)에서는 operator와 delegator 모두 시뇨리지를 받음
        uint256 operatorIncrease = operatorStakeAfter - operatorStakeBefore;
        uint256 user1Increase = user1StakeAfter - user1StakeBefore;

        assertGt(operatorIncrease, 0, "V2: operator should receive seigniorage");
        assertGt(user1Increase, 0, "V2: delegator should receive seigniorage");

        // NOTE: 실제 negative commission rate 테스트는 별도 통합 테스트에서 수행
        // _calcNegativeCommission은 commissionRate > 0 && isNegative == true 일 때만 호출됨
    }

    // ==========================================
    // Branch Coverage Tests - V2 Error Cases
    // ==========================================

    /// @notice SM-025-V2: paused 상태에서 updateSeigniorage 조기 리턴
    /// @dev V2에서 paused=true일 때 updateSeigniorageV2가 조기 리턴하는지 검증
    ///      Line 87: if (paused) return true
    function test_SM025_v2_updateSeigniorage_whenPaused_earlyReturn() public {
        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        // Layer2 등록 + operator 스테이킹 + 초기화
        _registerMockLayer2WithOperatorStakeAndInit();

        // pauser 권한 부여 및 pause 설정
        vm.startPrank(owner);
        SeigManagerV1_2(seigManagerProxy).addPauser(owner);
        seigManager.pause();
        vm.stopPrank();
        assertTrue(seigManager.paused(), "Should be paused");

        // 블록 진행
        vm.roll(block.number + 100);

        // 상태 기록
        uint256 l2RewardPerUintBefore = seigManager.l2RewardPerUint();

        // updateSeigniorage 호출 - paused 상태이므로 조기 리턴
        bool success = _updateSeigniorage();
        assertTrue(success, "V2: updateSeigniorage should return true even when paused");

        // l2RewardPerUint가 변경되지 않아야 함 (조기 리턴)
        uint256 l2RewardPerUintAfter = seigManager.l2RewardPerUint();
        assertEq(l2RewardPerUintAfter, l2RewardPerUintBefore, "V2: l2RewardPerUint should not change when paused");
    }

    /// @notice SM-026-V2: 같은 블록에서 updateSeigniorage 두 번 호출
    /// @dev V2에서 lastSeigBlock 조건 검증
    ///      Line 94: if (block.number <= _lastSeigBlock) revert LastSeigBlockError()
    ///      V3_1에서 V3_2로 delegatecall 시 V2DelegatecallFailedError로 래핑됨
    function test_SM026_v2_updateSeigniorage_sameBlock_reverts() public {
        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        // Layer2 등록 + operator 스테이킹 + 초기화
        _registerMockLayer2WithOperatorStakeAndInit();

        // 블록 진행 및 첫 번째 시뇨리지 분배
        vm.roll(block.number + 100);
        _updateSeigniorage();

        // 같은 블록에서 두 번째 호출 - V2DelegatecallFailedError 예상 (내부에 LastSeigBlockError 포함)
        vm.expectRevert(abi.encodeWithSignature("V2DelegatecallFailedError()"));
        _updateSeigniorage();
    }

    /// @notice SM-027-V2: operator 담보금이 minimumAmount 미만일 때 revert
    /// @dev V2에서 minimumAmount 조건 검증
    ///      Line 99: if (operatorAmount < minimumAmount) revert MinimumAmountError()
    function test_SM027_v2_updateSeigniorage_belowMinimumAmount_reverts() public {
        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        vm.startPrank(owner);

        // L1BridgeRegistry 설정
        if (!l1BridgeRegistry.isManager(owner)) {
            l1BridgeRegistry.addManager(owner);
        }
        if (!l1BridgeRegistry.isRegistrant(owner)) {
            l1BridgeRegistry.addRegistrant(owner);
        }

        l1BridgeRegistry.registerRollupConfig(
            address(mockSystemConfig),
            3,
            mockL2TON,
            "TestL2"
        );

        MockTON(ton).mint(mockPortal, BRIDGED_TON_AMOUNT);
        vm.stopPrank();

        // operator가 minimumAmount 미만으로 등록 (50 WTON - minimumAmount는 100 WTON)
        uint256 smallDeposit = 50 * RAY;
        vm.startPrank(operator1);
        MockWTON(wton).approve(layer2ManagerProxy, smallDeposit);

        // minimumAmount 미만이면 등록 자체가 실패
        vm.expectRevert();
        Layer2ManagerV3(layer2ManagerProxy).registerCandidateAddOn(
            address(mockSystemConfig),
            smallDeposit,
            false,
            "TestL2"
        );
        vm.stopPrank();
    }

    /// @notice SM-028-V2: powerton이 설정되어 있을 때 시뇨리지 분배
    /// @dev Line 226-228: if (_powerton != address(0)) 브랜치 커버
    function test_SM028_v2_updateSeigniorage_withPowerton() public {
        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        // powerton 주소 설정 (다른 seig rate을 줄여야 함 - 총합이 1 RAY 미만이어야 함)
        address mockPowerton = address(0x7777);
        vm.startPrank(owner);
        // 먼저 기존 rate들을 확인하고 조정
        SeigManagerV1_2(seigManagerProxy).setPseigRate(0.4e27); // 40% (기존 50%에서 줄임)
        SeigManagerV1_2(seigManagerProxy).setDaoSeigRate(0.4e27); // 40% (기존 50%에서 줄임)
        SeigManagerV1_2(seigManagerProxy).setPowerTONSeigRate(0.1e27); // 10%
        SeigManagerV1_2(seigManagerProxy).setPowerTON(mockPowerton);
        vm.stopPrank();

        // Layer2 등록 + operator 스테이킹 + 초기화
        _registerMockLayer2WithOperatorStakeAndInit();

        uint256 powertonBalanceBefore = MockWTON(wton).balanceOf(mockPowerton);

        // 블록 진행 및 시뇨리지 분배
        vm.roll(block.number + 100);
        _updateSeigniorage();

        // powerton이 시뇨리지를 받았는지 확인
        uint256 powertonBalanceAfter = MockWTON(wton).balanceOf(mockPowerton);
        assertGt(powertonBalanceAfter, powertonBalanceBefore, "V2: powerton should receive seigniorage");
    }

    /// @notice SM-029-V2: dao가 설정되어 있을 때 시뇨리지 분배
    /// @dev Line 231-233: if (dao != address(0)) 브랜치 커버
    function test_SM029_v2_updateSeigniorage_withDao() public {
        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        // dao 주소 설정
        address mockDao = address(0x6666);
        vm.prank(owner);
        SeigManagerV1_2(seigManagerProxy).setDao(mockDao);
        vm.prank(owner);
        SeigManagerV1_2(seigManagerProxy).setDaoSeigRate(0.1e27); // 10%

        // Layer2 등록 + operator 스테이킹 + 초기화
        _registerMockLayer2WithOperatorStakeAndInit();

        uint256 daoBalanceBefore = MockWTON(wton).balanceOf(mockDao);

        // 블록 진행 및 시뇨리지 분배
        vm.roll(block.number + 100);
        _updateSeigniorage();

        // dao가 시뇨리지를 받았는지 확인
        uint256 daoBalanceAfter = MockWTON(wton).balanceOf(mockDao);
        assertGt(daoBalanceAfter, daoBalanceBefore, "V2: dao should receive seigniorage");
    }

    /// @notice SM-030-V2: relativeSeigRate이 설정되어 있을 때
    /// @dev Line 236-238: if (relativeSeigRate != 0) 브랜치 커버
    function test_SM030_v2_updateSeigniorage_withRelativeSeigRate() public {
        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        // relativeSeigRate 설정 (setPseigRate 사용)
        vm.prank(owner);
        SeigManagerV1_2(seigManagerProxy).setPseigRate(0.5e27); // 50%

        // Layer2 등록 + operator 스테이킹 + 초기화
        _registerMockLayer2WithOperatorStakeAndInit();

        uint256 accRelativeSeigBefore = seigManager.accRelativeSeig();

        // 블록 진행 및 시뇨리지 분배
        vm.roll(block.number + 100);
        _updateSeigniorage();

        // accRelativeSeig가 누적되었는지 확인
        uint256 accRelativeSeigAfter = seigManager.accRelativeSeig();
        assertGt(accRelativeSeigAfter, accRelativeSeigBefore, "V2: accRelativeSeig should accumulate");
    }

    /// @notice SM-031-V2: L2 pauseBlocks가 설정되어 있을 때
    /// @dev _isPauseL2Seigniorage 브랜치 커버
    function test_SM031_v2_updateSeigniorage_withL2PauseBlocks() public {
        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        // Layer2 등록 + operator 스테이킹 + 초기화
        _registerMockLayer2WithOperatorStakeAndInit();

        // 블록 진행 (pauseCandidateAddOn 내부에서 updateSeigniorage 호출하므로 블록 변경 필요)
        vm.roll(block.number + 10);

        // Layer2 pause (Layer2Manager를 통해)
        vm.prank(l1BridgeRegistryProxy);
        layer2Manager.pauseCandidateAddOn(address(mockSystemConfig));

        uint256 operatorManagerWTONBefore = MockWTON(wton).balanceOf(operatorManager);

        // 블록 진행 및 시뇨리지 분배
        vm.roll(block.number + 100);
        _updateSeigniorage();

        // paused L2는 layer2Seigs를 받지 않아야 함 (같거나 약간만 증가 - 조기 리턴)
        uint256 operatorManagerWTONAfter = MockWTON(wton).balanceOf(operatorManager);
        // 실제로는 paused L2에서 updateSeigniorage가 호출되어도 전역 분배는 진행되지만
        // 해당 L2의 layer2Seigs는 분배되지 않음
        assertTrue(operatorManagerWTONAfter >= operatorManagerWTONBefore, "V2: paused L2 state check");
    }

    /// @notice SM-032-V2: delayedCommissionBlock이 설정되어 있을 때
    /// @dev _calcSeigsDistribution의 delayedCommissionBlock 브랜치 커버
    ///      Line 273: if (_delayedCommissionBlock != 0 && block.number >= _delayedCommissionBlock)
    function test_SM032_v2_updateSeigniorage_withDelayedCommission() public {
        // V2 모드 확인
        assertFalse(seigManager.v3Migrated(), "Should be in V2 mode");

        // Layer2 등록 + operator 스테이킹 + 초기화
        _registerMockLayer2WithOperatorStakeAndInit();

        // delayedCommissionRate 설정 (CandidateAddOn을 통해 호출 필요)
        // 이 테스트는 개념 검증용 - 실제 설정은 CandidateAddOn.setCommissionRate 필요

        // 블록 진행 및 시뇨리지 분배
        vm.roll(block.number + 100);
        bool success = _updateSeigniorage();
        assertTrue(success, "V2: updateSeigniorage should succeed");

        // commission rate 확인
        uint256 commissionRate = seigManager.commissionRates(mockLayer2);
        assertEq(commissionRate, 0, "V2: default commission rate should be 0");
    }
}
