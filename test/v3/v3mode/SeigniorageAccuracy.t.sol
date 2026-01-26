// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../helpers/V3TestBase.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LastSeigBlockError} from "../../../src/stake/managers/SeigManagerV3_1.sol";

/// @title SeigniorageAccuracyTest
/// @notice 시뇨리지 정확성 테스트 - span × seigPerBlock 검증
/// @dev 테스트 전략서 SM-016-V3: 블록 수 기반 시뇨리지 계산 정확성 검증
///
/// 테스트 대상:
/// - SM-016-V3: span × seigPerBlock = 총 시뇨리지 정확성
/// - 블록 간격에 따른 시뇨리지 민팅량 검증
/// - DAO + L2 분배 총액 = 예상 시뇨리지 검증
contract SeigniorageAccuracyTest is V3TestBase {
    // ==========================================
    // Additional Test Addresses
    // ==========================================
    address public daoAddress;

    uint256 constant WEI = 1e18;

    function setUp() public {
        _v3TestSetup();

        daoAddress = address(0xDA0);

        vm.startPrank(owner);

        // RAT 파라미터 설정
        _setupRATParams();

        // Mock 컨트랙트 생성 및 L2 등록
        _registerFirstL2(1000 * RAY);

        // V3 설정 및 마이그레이션
        seigManager.setRatContract(address(rat));

        // 테스트 환경을 위한 seigniorage 시작 블록 및 초기 공급량 설정
        SeigManagerV1_2(seigManagerProxy).setSeigStartBlock(block.number);
        SeigManagerV1_2(seigManagerProxy).setInitialTotalSupply(50000000e27);

        // V3 파라미터 설정
        seigManager.setDaoDistributionRatio(0.1e27);     // d = 10%
        seigManager.setMinStakingRatio(0.1e27);          // θ = 10%
        seigManager.setValidatorDistributionRatio(0.2e27); // α = 20%
        seigManager.setHalfSaturationPoint(1000e27);     // k = 1000

        // V3 파라미터 설정 및 마이그레이션
        _setV3ParametersForTest();
        seigManager.migrateToV3();

        vm.stopPrank();
    }

    // ==========================================
    // SM-016-V3: span × seigPerBlock = 총 시뇨리지 정확성 테스트
    // ==========================================

    /// @notice SM-016-V3: 단일 블록 진행 시 시뇨리지 정확성
    /// @dev span = 1 블록에서 seigPerBlock만큼 정확히 분배되는지 검증
    function test_SM016_v3_updateSeigniorage_exactAmountByBlocks_singleBlock() public {
        // Setup: seigPerBlock 값 조회
        uint256 seigPerBlock = SeigManagerV1_2(seigManagerProxy).seigPerBlock();
        assertTrue(seigPerBlock > 0, "seigPerBlock should be set");

        // 현재 lastSeigBlock 기록
        uint256 lastSeigBlockBefore = SeigManagerV1_2(seigManagerProxy).lastSeigBlock();

        // 1 블록 진행
        uint256 blocksToAdvance = 1;
        vm.roll(block.number + blocksToAdvance);

        // 예상 시뇨리지 계산
        uint256 expectedTotalSeigniorage = blocksToAdvance * seigPerBlock;

        // DAO 잔액 기록 (DAO가 모든 시뇨리지를 받음 - L2 자격 미충족 시)
        address daoAddr = SeigManagerV1_2(seigManagerProxy).dao();
        uint256 daoBalanceBefore = IERC20(wton).balanceOf(daoAddr);

        // updateSeigniorage 호출
        vm.prank(mockLayer2);
        bool success = seigManager.updateSeigniorage();
        assertTrue(success, "updateSeigniorage should succeed");

        // lastSeigBlock 업데이트 확인
        uint256 lastSeigBlockAfter = SeigManagerV1_2(seigManagerProxy).lastSeigBlock();
        assertEq(lastSeigBlockAfter - lastSeigBlockBefore, blocksToAdvance, "lastSeigBlock should advance by 1");

        // DAO 잔액 변화 확인 (totalEffectiveBridgedTON = 0이면 전액 DAO로)
        uint256 daoBalanceAfter = IERC20(wton).balanceOf(daoAddr);
        uint256 daoReceived = daoBalanceAfter - daoBalanceBefore;

        // L2가 자격 미충족 시: 전액 DAO
        // 예상: S_DAO = d × A + (L - y(x)) = A (when y(x) = 0)
        assertEq(daoReceived, expectedTotalSeigniorage, "DAO should receive all seigniorage when no eligible L2");

        emit log_named_uint("seigPerBlock", seigPerBlock);
        emit log_named_uint("blocksAdvanced", blocksToAdvance);
        emit log_named_uint("expectedTotalSeigniorage", expectedTotalSeigniorage);
        emit log_named_uint("daoReceived", daoReceived);
    }

    /// @notice SM-016-V3: 다중 블록 진행 시 시뇨리지 정확성
    /// @dev span = 100 블록에서 100 × seigPerBlock만큼 정확히 분배되는지 검증
    function test_SM016_v3_updateSeigniorage_exactAmountByBlocks_multipleBlocks() public {
        // Setup: seigPerBlock 값 조회
        uint256 seigPerBlock = SeigManagerV1_2(seigManagerProxy).seigPerBlock();

        // 100 블록 진행
        uint256 blocksToAdvance = 100;
        vm.roll(block.number + blocksToAdvance);

        // 예상 시뇨리지 계산
        uint256 expectedTotalSeigniorage = blocksToAdvance * seigPerBlock;

        // DAO 잔액 기록
        address daoAddr = SeigManagerV1_2(seigManagerProxy).dao();
        uint256 daoBalanceBefore = IERC20(wton).balanceOf(daoAddr);

        // updateSeigniorage 호출
        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        // DAO 잔액 변화 확인
        uint256 daoBalanceAfter = IERC20(wton).balanceOf(daoAddr);
        uint256 daoReceived = daoBalanceAfter - daoBalanceBefore;

        assertEq(daoReceived, expectedTotalSeigniorage, "span * seigPerBlock = total seigniorage");

        emit log_named_uint("blocksAdvanced", blocksToAdvance);
        emit log_named_uint("expectedTotalSeigniorage", expectedTotalSeigniorage);
        emit log_named_uint("actualDaoReceived", daoReceived);
    }

    /// @notice SM-016-V3: L2 자격 충족 시 분배 정확성
    /// @dev span × seigPerBlock = DAO분배 + L2분배 검증
    ///      실제로 자격을 충족하는 L2를 설정하여 y(x) > 0인 경우 테스트
    function test_SM016_v3_updateSeigniorage_exactAmountByBlocks_withEligibleL2() public {
        vm.startPrank(owner);

        // 1. Portal에 TON 전송 (브릿지된 TON 역할)
        uint256 bridgedAmount = 1000e18; // TON 단위 (18 decimals)
        MockTON(ton).mint(mockPortal, bridgedAmount);

        // 2. Operator에게 충분한 담보금 예치
        // θ = 10% (V3TestBase 파라미터), B_i = 1000 TON
        // 필요 담보금 = θ × B_i = 0.1 × 1000e18 × 1e9 (RAY 변환) = 100e27
        // 넉넉하게 200 WTON 예치
        MockWTON(wton).mint(operator1, 200 * RAY);
        vm.stopPrank();

        vm.startPrank(operator1);
        MockWTON(wton).approve(depositManagerProxy, 200 * RAY);
        depositManager.deposit(mockLayer2, operator1, 200 * RAY);
        vm.stopPrank();

        // 3. onBridgedTonChange 호출하여 effectiveBridgedTON 업데이트
        vm.prank(mockPortal);
        seigManager.onBridgedTonChange();

        // 4. 자격 확인
        (bool eligible, uint256 required, uint256 current) = seigManager.checkCurrentEligibility(mockLayer2);

        emit log_named_uint("required stake", required);
        emit log_named_uint("current stake", current);
        emit log_named_uint("eligible", eligible ? 1 : 0);

        assertTrue(eligible, "L2 should be eligible");

        uint256 totalEffective = seigManager.totalEffectiveBridgedTON();
        assertTrue(totalEffective > 0, "totalEffectiveBridgedTON should be > 0");

        // 5. 블록 진행 후 시뇨리지 분배
        uint256 seigPerBlock = SeigManagerV1_2(seigManagerProxy).seigPerBlock();
        uint256 blocksToAdvance = 50;
        vm.roll(block.number + blocksToAdvance);

        uint256 expectedTotalSeigniorage = blocksToAdvance * seigPerBlock;

        // 잔액 기록 (V3에서는 분배 후 최종 목적지 추적 필요)
        // - DAO: 직접 분배 + ValidatorReward에서 전달 (validator 없을 때)
        // - OperatorManager: Layer2Manager에서 전달
        // - ValidatorRewardProxy: 실제 validator reward 주소
        address daoAddr = SeigManagerV1_2(seigManagerProxy).dao();
        address operatorMgr = operatorManager;
        address validatorRewardAddr = seigManager.validatorReward();

        uint256 daoBalanceBefore = IERC20(wton).balanceOf(daoAddr);
        uint256 operatorBalanceBefore = IERC20(wton).balanceOf(operatorMgr);
        uint256 validatorRewardBefore = IERC20(wton).balanceOf(validatorRewardAddr);

        // updateSeigniorage 호출
        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        // 잔액 변화 계산
        uint256 daoReceived = IERC20(wton).balanceOf(daoAddr) - daoBalanceBefore;
        uint256 operatorReceived = IERC20(wton).balanceOf(operatorMgr) - operatorBalanceBefore;
        uint256 validatorReceived = IERC20(wton).balanceOf(validatorRewardAddr) - validatorRewardBefore;

        // 총 분배량 = DAO + Operator + ValidatorReward 잔액 변화
        // Note: ValidatorReward에서 DAO로 전송되므로 validatorReceived = 0일 수 있음
        uint256 totalDistributed = daoReceived + operatorReceived + validatorReceived;

        // 핵심 검증: span × seigPerBlock = 총 분배량
        assertEq(totalDistributed, expectedTotalSeigniorage, "span * seigPerBlock = total distributed");

        // L2 분배가 실제로 일어났는지 확인 (y(x) > 0)
        assertTrue(operatorReceived > 0, "Operator should receive L2 seigniorage");

        emit log_named_uint("expectedTotalSeigniorage", expectedTotalSeigniorage);
        emit log_named_uint("daoReceived", daoReceived);
        emit log_named_uint("operatorReceived", operatorReceived);
        emit log_named_uint("validatorReceived", validatorReceived);
        emit log_named_uint("totalDistributed", totalDistributed);
    }

    /// @notice SM-016-V3: 연속 호출 시 누적 정확성
    /// @dev 여러 번 updateSeigniorage 호출 시 누적 시뇨리지 정확성 검증
    function test_SM016_v3_updateSeigniorage_exactAmountByBlocks_cumulative() public {
        uint256 seigPerBlock = SeigManagerV1_2(seigManagerProxy).seigPerBlock();
        address daoAddr = SeigManagerV1_2(seigManagerProxy).dao();

        uint256 totalBlocksAdvanced = 0;
        uint256 initialDaoBalance = IERC20(wton).balanceOf(daoAddr);

        // 첫 번째 호출: 10 블록
        vm.roll(block.number + 10);
        totalBlocksAdvanced += 10;
        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        // 두 번째 호출: 20 블록
        vm.roll(block.number + 20);
        totalBlocksAdvanced += 20;
        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        // 세 번째 호출: 30 블록
        vm.roll(block.number + 30);
        totalBlocksAdvanced += 30;
        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        // 누적 검증
        uint256 expectedCumulativeSeigniorage = totalBlocksAdvanced * seigPerBlock;
        uint256 actualCumulativeDaoReceived = IERC20(wton).balanceOf(daoAddr) - initialDaoBalance;

        assertEq(actualCumulativeDaoReceived, expectedCumulativeSeigniorage,
            "Cumulative seigniorage = sum of (span * seigPerBlock)");

        emit log_named_uint("totalBlocksAdvanced", totalBlocksAdvanced);
        emit log_named_uint("expectedCumulativeSeigniorage", expectedCumulativeSeigniorage);
        emit log_named_uint("actualCumulativeDaoReceived", actualCumulativeDaoReceived);
    }

    /// @notice SM-016-V3: Fuzz 테스트 - 임의 블록 수에서 정확성
    /// @dev 임의의 블록 수에서 span × seigPerBlock = 총 시뇨리지 검증
    function testFuzz_SM016_v3_updateSeigniorage_exactAmountByBlocks(uint256 blocksToAdvance) public {
        // 블록 수 범위 제한 (1 ~ 10000)
        blocksToAdvance = bound(blocksToAdvance, 1, 10000);

        uint256 seigPerBlock = SeigManagerV1_2(seigManagerProxy).seigPerBlock();
        address daoAddr = SeigManagerV1_2(seigManagerProxy).dao();
        uint256 daoBalanceBefore = IERC20(wton).balanceOf(daoAddr);

        // 블록 진행
        vm.roll(block.number + blocksToAdvance);

        // updateSeigniorage 호출
        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        // 검증
        uint256 expectedTotalSeigniorage = blocksToAdvance * seigPerBlock;
        uint256 daoReceived = IERC20(wton).balanceOf(daoAddr) - daoBalanceBefore;

        assertEq(daoReceived, expectedTotalSeigniorage, "span * seigPerBlock = total seigniorage (fuzz)");
    }

    /// @notice SM-016-V3: 대량 블록 진행 시 오버플로우 방지
    /// @dev 큰 span 값에서도 정확한 계산 검증
    function test_SM016_v3_updateSeigniorage_exactAmountByBlocks_largeSpan() public {
        uint256 seigPerBlock = SeigManagerV1_2(seigManagerProxy).seigPerBlock();
        address daoAddr = SeigManagerV1_2(seigManagerProxy).dao();
        uint256 daoBalanceBefore = IERC20(wton).balanceOf(daoAddr);

        // 큰 블록 수 진행 (1년 ≈ 2,628,000 블록)
        uint256 blocksToAdvance = 1_000_000;
        vm.roll(block.number + blocksToAdvance);

        uint256 expectedTotalSeigniorage = blocksToAdvance * seigPerBlock;

        // updateSeigniorage 호출
        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        // 검증
        uint256 daoReceived = IERC20(wton).balanceOf(daoAddr) - daoBalanceBefore;
        assertEq(daoReceived, expectedTotalSeigniorage, "Large span calculation accurate");

        emit log_named_uint("blocksAdvanced (1M)", blocksToAdvance);
        emit log_named_uint("expectedTotalSeigniorage", expectedTotalSeigniorage);
        emit log_named_uint("daoReceived", daoReceived);
    }

    /// @notice SM-016-V3: span = 0 시 시뇨리지 없음 (claim only)
    /// @dev 같은 블록에서 두 번째 호출은 revert하지 않고 claim만 수행
    ///      (다른 L2가 자기 몫을 받을 수 있도록 허용)
    function test_SM016_v3_updateSeigniorage_zeroSpan_claimOnly() public {
        // 첫 번째 호출을 위해 블록 진행
        vm.roll(block.number + 10);

        // 첫 번째 호출 - 성공
        vm.prank(mockLayer2);
        bool success = seigManager.updateSeigniorage();
        assertTrue(success, "First call should succeed");

        // lastSeigBlock 업데이트 확인
        uint256 lastSeigBlock = SeigManagerV1_2(seigManagerProxy).lastSeigBlock();
        assertEq(lastSeigBlock, block.number, "lastSeigBlock should be updated");

        // DAO 잔액 기록
        address daoAddr = SeigManagerV1_2(seigManagerProxy).dao();
        uint256 daoBalanceAfterFirst = IERC20(wton).balanceOf(daoAddr);

        // 같은 블록에서 두 번째 호출 - claim only (추가 mint 없음)
        vm.prank(mockLayer2);
        success = seigManager.updateSeigniorage();
        assertTrue(success, "Second call should succeed (claim only)");

        // DAO 잔액 변화 없음 (새 시뇨리지 mint 없음)
        uint256 daoBalanceAfterSecond = IERC20(wton).balanceOf(daoAddr);
        assertEq(daoBalanceAfterSecond, daoBalanceAfterFirst, "No additional seigniorage should be minted");
    }

    // ==========================================
    // Helper: V3 분배 공식 검증
    // ==========================================

    /// @notice V3 분배 공식 직접 계산 검증
    /// @dev A = span × seigPerBlock
    ///      S_DAO = d × A
    ///      L = A - S_DAO = (1 - d) × A
    ///      y(x) = L × (x / (k + x))
    ///      총 DAO = S_DAO + (L - y(x))
    ///      L2 시퀀서 = (1 - α) × y(x) × (B̃_i / x)
    ///      L2 검증자 = α × y(x) × (B̃_i / x)
    function test_SM016_v3_formulaVerification_daoOnlyCase() public {
        uint256 seigPerBlock = SeigManagerV1_2(seigManagerProxy).seigPerBlock();
        uint256 daoRatio = seigManager.daoDistributionRatio(); // 0.1e27

        uint256 blocksToAdvance = 100;
        vm.roll(block.number + blocksToAdvance);

        // 수동 계산
        uint256 A = blocksToAdvance * seigPerBlock;
        uint256 S_DAO = (A * daoRatio) / RAY;
        uint256 L = A - S_DAO;

        // totalEffectiveBridgedTON = 0이면 y(x) = 0
        uint256 totalEffective = seigManager.totalEffectiveBridgedTON();
        uint256 y = 0;
        if (totalEffective > 0) {
            uint256 k = seigManager.halfSaturationPoint();
            y = (L * totalEffective) / (k + totalEffective);
        }

        // 총 DAO 수령 = S_DAO + (L - y)
        uint256 expectedDaoTotal = S_DAO + (L - y);

        // 실제 분배
        address daoAddr = SeigManagerV1_2(seigManagerProxy).dao();
        uint256 daoBalanceBefore = IERC20(wton).balanceOf(daoAddr);

        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        uint256 daoReceived = IERC20(wton).balanceOf(daoAddr) - daoBalanceBefore;

        // y = 0일 때: expectedDaoTotal = S_DAO + L = A (전액 DAO)
        assertEq(expectedDaoTotal, A, "When y=0, all seigniorage goes to DAO");
        assertEq(daoReceived, expectedDaoTotal, "DAO receives expected amount");

        emit log_named_uint("A (span * seigPerBlock)", A);
        emit log_named_uint("S_DAO (d * A)", S_DAO);
        emit log_named_uint("L (A - S_DAO)", L);
        emit log_named_uint("totalEffectiveBridgedTON", totalEffective);
        emit log_named_uint("y (hyperbolic)", y);
        emit log_named_uint("expectedDaoTotal", expectedDaoTotal);
        emit log_named_uint("actualDaoReceived", daoReceived);
    }

    // ==========================================
    // 자격 충족 L2 추가 테스트
    // ==========================================

    /// @notice SM-016-V3-EX1: 자격 충족 L2의 V3 공식 검증 (y(x) > 0)
    /// @dev A = span × seigPerBlock
    ///      S_DAO = d × A (10%)
    ///      L = A - S_DAO (90%)
    ///      y(x) = L × (x / (k + x)) where x = totalEffectiveBridgedTON
    ///      Sequencer = (1 - α) × y(x) (80% of y)
    ///      Validator = α × y(x) (20% of y)
    ///      DAO Total = S_DAO + (L - y(x))
    function test_SM016_v3_EX1_formulaVerification_withEligibleL2() public {
        // 1. Setup L2 with eligibility
        _setupEligibleL2();

        // 2. Get parameters
        uint256 seigPerBlock = SeigManagerV1_2(seigManagerProxy).seigPerBlock();
        uint256 x = seigManager.totalEffectiveBridgedTON();
        assertTrue(x > 0, "totalEffectiveBridgedTON should be > 0 after setup");

        vm.roll(block.number + 100);

        // 3. Calculate expected values
        uint256 A = 100 * seigPerBlock;

        // 4. Execute seigniorage distribution
        // Note: V3에서 분배 후 최종 목적지:
        // - DAO: 직접 분배 + ValidatorReward에서 전달 (validator 없을 때)
        // - OperatorManager: Layer2Manager에서 전달
        address daoAddr = SeigManagerV1_2(seigManagerProxy).dao();
        address validatorRewardAddr = seigManager.validatorReward();
        uint256 daoBefore = IERC20(wton).balanceOf(daoAddr);
        uint256 operatorBefore = IERC20(wton).balanceOf(operatorManager);
        uint256 valBefore = IERC20(wton).balanceOf(validatorRewardAddr);

        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        // 5. Verify distribution
        uint256 daoReceived = IERC20(wton).balanceOf(daoAddr) - daoBefore;
        uint256 operatorReceived = IERC20(wton).balanceOf(operatorManager) - operatorBefore;
        uint256 valReceived = IERC20(wton).balanceOf(validatorRewardAddr) - valBefore;
        uint256 totalDistributed = daoReceived + operatorReceived + valReceived;

        assertEq(totalDistributed, A, "Total distributed should equal A");
        assertTrue(operatorReceived > 0, "Operator should receive L2 seigniorage (y(x) > 0)");
    }

    /// @notice Helper: Setup eligible L2 with bridged TON
    function _setupEligibleL2() internal {
        vm.startPrank(owner);
        // Portal에 TON 전송 (브릿지된 TON 역할)
        MockTON(ton).mint(mockPortal, 1000e18);
        MockWTON(wton).mint(operator1, 500 * RAY);
        vm.stopPrank();

        vm.startPrank(operator1);
        MockWTON(wton).approve(depositManagerProxy, 500 * RAY);
        depositManager.deposit(mockLayer2, operator1, 500 * RAY);
        vm.stopPrank();

        vm.prank(mockPortal);
        seigManager.onBridgedTonChange();

        (bool eligible, , ) = seigManager.checkCurrentEligibility(mockLayer2);
        assertTrue(eligible, "L2 should be eligible");
    }

    /// @notice SM-016-V3-EX2: 다중 블록에서 자격 충족 L2 정확성
    function test_SM016_v3_EX2_multipleBlocks_withEligibleL2() public {
        _setupEligibleL2();

        uint256 seigPerBlock = SeigManagerV1_2(seigManagerProxy).seigPerBlock();
        address daoAddr = SeigManagerV1_2(seigManagerProxy).dao();
        address validatorRewardAddr = seigManager.validatorReward();

        uint256 totalExpected = 0;
        uint256 initDao = IERC20(wton).balanceOf(daoAddr);
        uint256 initOperator = IERC20(wton).balanceOf(operatorManager);
        uint256 initVal = IERC20(wton).balanceOf(validatorRewardAddr);

        // 3회 연속 분배
        uint256[3] memory blocks = [uint256(50), uint256(75), uint256(100)];

        for (uint256 i = 0; i < blocks.length; i++) {
            vm.roll(block.number + blocks[i]);
            totalExpected += blocks[i] * seigPerBlock;
            vm.prank(mockLayer2);
            seigManager.updateSeigniorage();
        }

        // 총 누적 분배량 검증
        uint256 totalDistributed = (IERC20(wton).balanceOf(daoAddr) - initDao)
            + (IERC20(wton).balanceOf(operatorManager) - initOperator)
            + (IERC20(wton).balanceOf(validatorRewardAddr) - initVal);

        assertEq(totalDistributed, totalExpected, "Cumulative distribution match");
    }

    /// @notice SM-016-V3-EX3: Hyperbolic saturation 공식 검증
    /// @dev y(x) = L × (x / (k + x))
    ///      L2로 분배된 실제 금액이 공식에 맞는지 검증
    function test_SM016_v3_EX3_halfSaturationPoint_verification() public {
        _setupEligibleL2();

        uint256 k = seigManager.halfSaturationPoint();
        uint256 x = seigManager.totalEffectiveBridgedTON();
        assertTrue(x > 0, "totalEffectiveBridgedTON should be > 0");

        vm.roll(block.number + 100);

        uint256 seigPerBlock = SeigManagerV1_2(seigManagerProxy).seigPerBlock();
        uint256 A = 100 * seigPerBlock;
        uint256 d = seigManager.daoDistributionRatio();
        uint256 L = A - (A * d) / RAY;

        // y(x) = L × (x / (k + x))
        uint256 expectedY = (L * x) / (k + x);

        // V3 분배 후 실제 L2로 간 금액 추적
        // - OperatorManager: Layer2Manager에서 전달받음
        // - ValidatorReward: 직접 mint받음 (validator 없으면 DAO로 전송됨)
        address validatorRewardAddr = seigManager.validatorReward();
        uint256 operatorBefore = IERC20(wton).balanceOf(operatorManager);
        uint256 valBefore = IERC20(wton).balanceOf(validatorRewardAddr);

        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        uint256 operatorReceived = IERC20(wton).balanceOf(operatorManager) - operatorBefore;
        uint256 valReceived = IERC20(wton).balanceOf(validatorRewardAddr) - valBefore;

        // actualY = L2로 분배된 총액 (operator + validator 부분)
        // Note: ValidatorReward에서 DAO로 전송되더라도 원래 y의 일부임
        // validator 부분은 α × y, sequencer 부분은 (1-α) × y
        // 여기서는 sequencer 부분(operatorReceived)만 측정 가능
        uint256 alpha = seigManager.validatorDistributionRatio();
        uint256 sequencerRatio = RAY - alpha; // 80%

        // operatorReceived = (1-α) × y → y = operatorReceived / (1-α)
        uint256 reconstructedY = (operatorReceived * RAY) / sequencerRatio;

        emit log_named_uint("k (halfSaturationPoint)", k);
        emit log_named_uint("x (totalEffectiveBridgedTON)", x);
        emit log_named_uint("L (max L2 allocation)", L);
        emit log_named_uint("expectedY (L*x/(k+x))", expectedY);
        emit log_named_uint("operatorReceived", operatorReceived);
        emit log_named_uint("reconstructedY", reconstructedY);

        // y(x) = L × (x / (k + x)) 검증
        assertApproxEqRel(reconstructedY, expectedY, 0.05e18, "y(x) = L * x / (k + x)");
    }

    // ==========================================
    // bridgedTON > 0 추가 테스트
    // ==========================================

    /// @notice SM-016-V3-EX4: 소량 bridgedTON (x << k) 분배 검증
    /// @dev x가 k보다 훨씬 작을 때 y(x) ≈ L × (x/k) 근사 확인
    function test_SM016_v3_EX4_smallBridgedTON_distribution() public {
        // k = 1000e27 (setUp에서 설정)
        // x = 10e27 (k의 1%)로 설정
        uint256 smallBridgedTON = 10e18; // 10 TON

        vm.startPrank(owner);
        MockTON(ton).mint(mockPortal, smallBridgedTON);
        MockWTON(wton).mint(operator1, 500 * RAY);
        vm.stopPrank();

        vm.startPrank(operator1);
        MockWTON(wton).approve(depositManagerProxy, 500 * RAY);
        depositManager.deposit(mockLayer2, operator1, 500 * RAY);
        vm.stopPrank();

        vm.prank(mockPortal);
        seigManager.onBridgedTonChange();

        uint256 k = seigManager.halfSaturationPoint();
        uint256 x = seigManager.totalEffectiveBridgedTON();
        assertTrue(x > 0, "x should be > 0");
        assertTrue(x < k / 10, "x should be << k for this test");

        vm.roll(block.number + 100);

        uint256 seigPerBlock = SeigManagerV1_2(seigManagerProxy).seigPerBlock();
        uint256 A = 100 * seigPerBlock;
        uint256 d = seigManager.daoDistributionRatio();
        uint256 L = A - (A * d) / RAY;

        // 잔액 추적을 위한 배열 사용 (stack too deep 방지)
        uint256[3] memory balancesBefore;
        address daoAddr = SeigManagerV1_2(seigManagerProxy).dao();
        balancesBefore[0] = IERC20(wton).balanceOf(daoAddr);
        balancesBefore[1] = IERC20(wton).balanceOf(operatorManager);
        balancesBefore[2] = IERC20(wton).balanceOf(seigManager.validatorReward());

        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        uint256 daoReceived = IERC20(wton).balanceOf(daoAddr) - balancesBefore[0];
        uint256 operatorReceived = IERC20(wton).balanceOf(operatorManager) - balancesBefore[1];
        uint256 valReceived = IERC20(wton).balanceOf(seigManager.validatorReward()) - balancesBefore[2];

        // 총 분배량 검증 (DAO + Sequencer + Validator)
        assertApproxEqRel(daoReceived + operatorReceived + valReceived, A, 0.0001e18, "Total should equal A");

        // x << k이므로 대부분 DAO로 가야 함 (y가 작음)
        assertTrue(daoReceived > operatorReceived * 5, "DAO should receive much more when x << k");
    }

    /// @notice SM-016-V3-EX5: 대량 bridgedTON (x >> k) 분배 검증
    /// @dev x가 k보다 훨씬 클 때 y(x) ≈ L 근사 확인
    function test_SM016_v3_EX5_largeBridgedTON_distribution() public {
        // k = 1000e27 (setUp에서 설정)
        // x = 10000e27 (k의 10배)로 설정
        uint256 largeBridgedTON = 10000e18; // 10000 TON

        vm.startPrank(owner);
        MockTON(ton).mint(mockPortal, largeBridgedTON);
        MockWTON(wton).mint(operator1, 2000 * RAY); // 더 많은 담보금 필요
        vm.stopPrank();

        vm.startPrank(operator1);
        MockWTON(wton).approve(depositManagerProxy, 2000 * RAY);
        depositManager.deposit(mockLayer2, operator1, 2000 * RAY);
        vm.stopPrank();

        vm.prank(mockPortal);
        seigManager.onBridgedTonChange();

        uint256 k = seigManager.halfSaturationPoint();
        uint256 x = seigManager.totalEffectiveBridgedTON();
        assertTrue(x > 0, "x should be > 0");
        assertTrue(x > k * 5, "x should be >> k for this test");

        vm.roll(block.number + 100);

        uint256 seigPerBlock = SeigManagerV1_2(seigManagerProxy).seigPerBlock();
        uint256 A = 100 * seigPerBlock;
        uint256 d = seigManager.daoDistributionRatio();
        uint256 L = A - (A * d) / RAY;

        // x >> k일 때: y ≈ L (포화 상태)
        uint256 expectedY = (L * x) / (k + x);

        // 잔액 추적을 위한 배열 사용 (stack too deep 방지)
        uint256[3] memory balancesBefore;
        address daoAddr = SeigManagerV1_2(seigManagerProxy).dao();
        balancesBefore[0] = IERC20(wton).balanceOf(daoAddr);
        balancesBefore[1] = IERC20(wton).balanceOf(operatorManager);
        balancesBefore[2] = IERC20(wton).balanceOf(seigManager.validatorReward());

        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        uint256 daoReceived = IERC20(wton).balanceOf(daoAddr) - balancesBefore[0];
        uint256 operatorReceived = IERC20(wton).balanceOf(operatorManager) - balancesBefore[1];
        uint256 valReceived = IERC20(wton).balanceOf(seigManager.validatorReward()) - balancesBefore[2];

        // 총 분배량 검증 (DAO + Sequencer + Validator)
        assertApproxEqRel(daoReceived + operatorReceived + valReceived, A, 0.0001e18, "Total should equal A");

        // x >> k이므로 L2 분배가 L에 가까워야 함
        // sequencer = (1-α) × y ≈ 0.8 × L
        uint256 expectedSequencer = (expectedY * (RAY - seigManager.validatorDistributionRatio())) / RAY;
        assertApproxEqRel(operatorReceived, expectedSequencer, 0.05e18, "Operator should receive ~80% of y");
    }

    /// @notice SM-016-V3-EX6: x = k일 때 y = L/2 정확히 검증
    /// @dev Half saturation point에서 정확히 L/2 분배 확인
    function test_SM016_v3_EX6_exactHalfSaturation() public {
        // k = 1000e27, x = 1000e27 (k와 동일하게 설정)
        // halfSaturationPoint를 bridgedTON과 맞추기 위해 조정
        uint256 targetBridgedTON = 1000e18; // 1000 TON

        vm.startPrank(owner);
        MockTON(ton).mint(mockPortal, targetBridgedTON);
        MockWTON(wton).mint(operator1, 500 * RAY);
        vm.stopPrank();

        vm.startPrank(operator1);
        MockWTON(wton).approve(depositManagerProxy, 500 * RAY);
        depositManager.deposit(mockLayer2, operator1, 500 * RAY);
        vm.stopPrank();

        vm.prank(mockPortal);
        seigManager.onBridgedTonChange();

        uint256 k = seigManager.halfSaturationPoint();
        uint256 x = seigManager.totalEffectiveBridgedTON();

        // k와 x가 같도록 halfSaturationPoint 조정
        vm.prank(owner);
        seigManager.setHalfSaturationPoint(x);
        k = seigManager.halfSaturationPoint();

        assertEq(k, x, "k should equal x for half saturation test");

        vm.roll(block.number + 100);

        uint256 seigPerBlock = SeigManagerV1_2(seigManagerProxy).seigPerBlock();
        uint256 A = 100 * seigPerBlock;
        uint256 d = seigManager.daoDistributionRatio();
        uint256 L = A - (A * d) / RAY;

        // x = k일 때: y = L/2 정확히
        uint256 expectedY = L / 2;

        address daoAddr = SeigManagerV1_2(seigManagerProxy).dao();
        uint256 daoBefore = IERC20(wton).balanceOf(daoAddr);
        uint256 operatorBefore = IERC20(wton).balanceOf(operatorManager);

        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        uint256 daoReceived = IERC20(wton).balanceOf(daoAddr) - daoBefore;
        uint256 operatorReceived = IERC20(wton).balanceOf(operatorManager) - operatorBefore;

        // y = L/2 검증
        uint256 alpha = seigManager.validatorDistributionRatio();
        uint256 expectedSequencer = (expectedY * (RAY - alpha)) / RAY;
        uint256 reconstructedY = (operatorReceived * RAY) / (RAY - alpha);

        // 총 분배량 검증
        assertEq(daoReceived + operatorReceived, A, "Total should equal A");

        // y = L/2 검증 (1% 오차 허용)
        assertApproxEqRel(reconstructedY, expectedY, 0.01e18, "y should equal L/2 when x = k");

        emit log_named_uint("k", k);
        emit log_named_uint("x", x);
        emit log_named_uint("L", L);
        emit log_named_uint("expectedY (L/2)", expectedY);
        emit log_named_uint("reconstructedY", reconstructedY);
    }

    /// @notice SM-016-V3-EX7: DAO/Sequencer/Validator 분배 비율 검증
    /// @dev d=10%, α=20%일 때 정확한 분배 비율 확인
    function test_SM016_v3_EX7_distributionRatios_verification() public {
        _setupEligibleL2();

        // 파라미터 및 예상값을 struct로 관리하여 stack 사용 최소화
        uint256 A;
        uint256 sequencerPart;
        uint256 expectedDaoTotal;

        {
            uint256 d = seigManager.daoDistributionRatio();
            uint256 alpha = seigManager.validatorDistributionRatio();
            uint256 k = seigManager.halfSaturationPoint();
            uint256 x = seigManager.totalEffectiveBridgedTON();

            vm.roll(block.number + 100);

            uint256 seigPerBlock = SeigManagerV1_2(seigManagerProxy).seigPerBlock();
            A = 100 * seigPerBlock;

            // 예상 분배량 계산
            uint256 S_DAO = (A * d) / RAY;           // 10% of A
            uint256 L = A - S_DAO;                   // 90% of A
            uint256 y = (L * x) / (k + x);           // hyperbolic
            uint256 validatorPart = (y * alpha) / RAY;      // 20% of y
            sequencerPart = y - validatorPart;              // 80% of y
            uint256 daoTotal = S_DAO + (L - y);             // DAO 기본 + 미분배

            // DAO는 기본 분배 + validator part (validator 없으면)
            expectedDaoTotal = daoTotal + validatorPart;

            emit log_named_uint("A (total seigniorage)", A);
            emit log_named_uint("S_DAO (d*A = 10%)", S_DAO);
            emit log_named_uint("L (A - S_DAO = 90%)", L);
            emit log_named_uint("y (hyperbolic)", y);
            emit log_named_uint("validatorPart (20% of y)", validatorPart);
            emit log_named_uint("sequencerPart (80% of y)", sequencerPart);
            emit log_named_uint("daoTotal (S_DAO + L - y)", daoTotal);
        }

        // 분배 실행 및 검증
        address daoAddr = SeigManagerV1_2(seigManagerProxy).dao();
        address validatorRewardAddr = seigManager.validatorReward();

        uint256 daoBefore = IERC20(wton).balanceOf(daoAddr);
        uint256 operatorBefore = IERC20(wton).balanceOf(operatorManager);
        uint256 valBefore = IERC20(wton).balanceOf(validatorRewardAddr);

        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        uint256 daoReceived = IERC20(wton).balanceOf(daoAddr) - daoBefore;
        uint256 operatorReceived = IERC20(wton).balanceOf(operatorManager) - operatorBefore;
        uint256 valReceived = IERC20(wton).balanceOf(validatorRewardAddr) - valBefore;

        // 분배 비율 검증
        assertEq(daoReceived + operatorReceived + valReceived, A, "Total = A");
        assertApproxEqRel(operatorReceived, sequencerPart, 0.01e18, "Sequencer part correct");
        assertApproxEqRel(daoReceived, expectedDaoTotal, 0.01e18, "DAO total correct");

        emit log_named_uint("actual daoReceived", daoReceived);
        emit log_named_uint("actual operatorReceived", operatorReceived);
    }

    /// @notice SM-016-V3-EX8: 연속 블록에서 bridgedTON 분배 누적 정확성
    /// @dev 여러 번 updateSeigniorage 호출 시 공식 일관성 확인
    function test_SM016_v3_EX8_cumulativeDistribution_withBridgedTON() public {
        _setupEligibleL2();

        uint256 seigPerBlock = SeigManagerV1_2(seigManagerProxy).seigPerBlock();
        uint256 k = seigManager.halfSaturationPoint();
        uint256 x = seigManager.totalEffectiveBridgedTON();
        uint256 d = seigManager.daoDistributionRatio();
        uint256 alpha = seigManager.validatorDistributionRatio();

        address daoAddr = SeigManagerV1_2(seigManagerProxy).dao();
        uint256 initDao = IERC20(wton).balanceOf(daoAddr);
        uint256 initOperator = IERC20(wton).balanceOf(operatorManager);

        uint256 totalExpectedA = 0;
        uint256 totalExpectedSequencer = 0;

        // 5회 연속 분배
        uint256[5] memory blocks = [uint256(20), uint256(30), uint256(50), uint256(40), uint256(60)];

        for (uint256 i = 0; i < blocks.length; i++) {
            vm.roll(block.number + blocks[i]);

            uint256 A = blocks[i] * seigPerBlock;
            uint256 L = A - (A * d) / RAY;
            uint256 y = (L * x) / (k + x);
            uint256 sequencerPart = (y * (RAY - alpha)) / RAY;

            totalExpectedA += A;
            totalExpectedSequencer += sequencerPart;

            vm.prank(mockLayer2);
            seigManager.updateSeigniorage();
        }

        uint256 totalDaoReceived = IERC20(wton).balanceOf(daoAddr) - initDao;
        uint256 totalOperatorReceived = IERC20(wton).balanceOf(operatorManager) - initOperator;
        uint256 totalDistributed = totalDaoReceived + totalOperatorReceived;

        // 누적 검증
        assertEq(totalDistributed, totalExpectedA, "Cumulative total = sum of A");
        assertApproxEqRel(totalOperatorReceived, totalExpectedSequencer, 0.02e18, "Cumulative sequencer correct");

        emit log_named_uint("total blocks", 20 + 30 + 50 + 40 + 60);
        emit log_named_uint("totalExpectedA", totalExpectedA);
        emit log_named_uint("totalExpectedSequencer", totalExpectedSequencer);
        emit log_named_uint("totalDaoReceived", totalDaoReceived);
        emit log_named_uint("totalOperatorReceived", totalOperatorReceived);
    }

    /// @notice SM-016-V3-EX9: 서로 다른 bridgedTON 값에 따른 분배 비율 변화 검증
    /// @dev 동일 L2가 다른 초기 bridgedTON 값일 때 분배 차이 확인
    /// Note: V3 설계상 eligibility는 시뇨리지 정산 시점에 업데이트됨
    function test_SM016_v3_EX9_differentBridgedTONRatios() public {
        // 시나리오 1: 작은 bridgedTON (x << k)
        uint256 smallBridgedTON = 100e18;  // 100 TON
        uint256 operatorReceived1;
        {
            _setupEligibleL2WithBridgedAmount(smallBridgedTON);
            uint256 x = seigManager.totalEffectiveBridgedTON();
            emit log_named_uint("Scenario 1 - x (small)", x);

            vm.roll(block.number + 100);
            uint256 opBefore = IERC20(wton).balanceOf(operatorManager);
            vm.prank(mockLayer2);
            seigManager.updateSeigniorage();
            operatorReceived1 = IERC20(wton).balanceOf(operatorManager) - opBefore;
            emit log_named_uint("Scenario 1 - operatorReceived", operatorReceived1);
        }

        // setUp 초기화 후 다시 설정
        setUp();

        // 시나리오 2: 큰 bridgedTON (x = k)
        uint256 largeBridgedTON = 1000e18;  // 1000 TON (= k)
        uint256 operatorReceived2;
        {
            _setupEligibleL2WithBridgedAmount(largeBridgedTON);
            uint256 x = seigManager.totalEffectiveBridgedTON();
            emit log_named_uint("Scenario 2 - x (large)", x);

            vm.roll(block.number + 100);
            uint256 opBefore = IERC20(wton).balanceOf(operatorManager);
            vm.prank(mockLayer2);
            seigManager.updateSeigniorage();
            operatorReceived2 = IERC20(wton).balanceOf(operatorManager) - opBefore;
            emit log_named_uint("Scenario 2 - operatorReceived", operatorReceived2);
        }

        // x가 클수록 sequencer 분배가 커야 함
        assertTrue(operatorReceived2 > operatorReceived1, "Larger bridgedTON should give more to sequencer");

        // 예상 비율 검증
        // y(x) = L * x / (k + x)
        // x=100e27일 때: y = L * 100 / (1000 + 100) ≈ L/11
        // x=1000e27일 때: y = L * 1000 / (1000 + 1000) = L/2
        // 따라서 y2/y1 ≈ 5.5
        uint256 ratio = (operatorReceived2 * 100) / operatorReceived1;
        emit log_named_uint("operatorReceived ratio (x100)", ratio);
        assertTrue(ratio > 400 && ratio < 600, "Ratio should be approximately 5.5x");
    }

    /// @dev 특정 bridgedTON 값으로 eligible L2 설정
    function _setupEligibleL2WithBridgedAmount(uint256 bridgedAmount) internal {
        vm.startPrank(owner);
        // Portal에 TON 전송 (브릿지된 TON 역할)
        MockTON(ton).mint(mockPortal, bridgedAmount);
        MockWTON(wton).mint(operator1, 500 * RAY);
        vm.stopPrank();

        vm.startPrank(operator1);
        MockWTON(wton).approve(depositManagerProxy, 500 * RAY);
        depositManager.deposit(mockLayer2, operator1, 500 * RAY);
        vm.stopPrank();

        vm.prank(mockPortal);
        seigManager.onBridgedTonChange();

        (bool eligible, , ) = seigManager.checkCurrentEligibility(mockLayer2);
        assertTrue(eligible, "L2 should be eligible");
    }

    // ==========================================
    // 다중 L2 시뇨리지 분배 정확성 테스트 (V3 핵심 검증)
    // ==========================================

    /// @notice SM-016-V3-MULTI-1: 2개 L2가 다른 시점에 updateSeigniorage 호출 시 정확성
    /// @dev 핵심 버그 검증: 늦게 호출한 L2도 과거 기간의 몫을 정확히 받아야 함
    function test_SM016_v3_MULTI1_twoL2s_differentCallTimes() public {
        // 2개 L2 설정
        (address l2_A, address opMgr_A, ) = _setupL2("L2_A", address(0x7001), 1000e18);
        (address l2_B, address opMgr_B, ) = _setupL2("L2_B", address(0x7002), 1000e18);

        uint256 xTotal = seigManager.totalEffectiveBridgedTON();
        uint256 expectedSeq_period1;

        // ====== Period 1: Block 0-100, L2_A만 호출 ======
        uint256 opMgr_A_received1;
        {
            vm.roll(block.number + 100);
            expectedSeq_period1 = _calcExpectedSeqReward(100, xTotal, 1000e27);

            uint256 before = IERC20(wton).balanceOf(opMgr_A);
            vm.prank(l2_A);
            seigManager.updateSeigniorage();
            opMgr_A_received1 = IERC20(wton).balanceOf(opMgr_A) - before;

            emit log_named_uint("Period 1 - L2_A received", opMgr_A_received1);
            assertApproxEqRel(opMgr_A_received1, expectedSeq_period1, 0.01e18, "L2_A should receive only its share");
        }

        // ====== Period 2: Block 100-200, L2_B 호출 (P1+P2 받아야 함) ======
        {
            vm.roll(block.number + 100);
            uint256 expectedSeq_period2 = _calcExpectedSeqReward(100, xTotal, 1000e27);
            uint256 expectedB_total = expectedSeq_period1 + expectedSeq_period2;

            uint256 before = IERC20(wton).balanceOf(opMgr_B);
            vm.prank(l2_B);
            seigManager.updateSeigniorage();
            uint256 received = IERC20(wton).balanceOf(opMgr_B) - before;

            emit log_named_uint("Period 2 - L2_B received (P1+P2)", received);
            emit log_named_uint("Period 2 - expected L2_B total", expectedB_total);
            assertApproxEqRel(received, expectedB_total, 0.02e18, "L2_B should receive both Period 1 and Period 2 share");
        }

        // ====== L2_A도 Period 2의 몫을 받음 ======
        {
            uint256 expectedSeq_period2 = _calcExpectedSeqReward(100, xTotal, 1000e27);
            uint256 before = IERC20(wton).balanceOf(opMgr_A);
            vm.prank(l2_A);
            seigManager.updateSeigniorage();
            uint256 received = IERC20(wton).balanceOf(opMgr_A) - before;

            emit log_named_uint("Period 2 - L2_A additional received", received);
            assertApproxEqRel(received, expectedSeq_period2, 0.02e18, "L2_A should receive Period 2 share");
        }
    }

    /// @dev 예상 sequencer 보상 계산 헬퍼
    function _calcExpectedSeqReward(uint256 blocks, uint256 xTotal, uint256 l2Share) internal view returns (uint256) {
        uint256 seigPerBlock = SeigManagerV1_2(seigManagerProxy).seigPerBlock();
        uint256 d = seigManager.daoDistributionRatio();
        uint256 k = seigManager.halfSaturationPoint();
        uint256 alpha = seigManager.validatorDistributionRatio();

        uint256 A = blocks * seigPerBlock;
        uint256 L = A - (A * d) / RAY;
        uint256 y = (L * xTotal) / (k + xTotal);
        uint256 l2Total = (y * l2Share) / xTotal;
        return (l2Total * (RAY - alpha)) / RAY;
    }

    /// @notice SM-016-V3-MULTI-2: 전체 mint량 = 기대값 검증
    /// @dev 핵심 검증: 전체 y가 mint되고, 각 L2가 자기 몫을 받음
    ///      이전 버그: 호출한 L2 몫만 mint되어 전체 합이 부족했음
    function test_SM016_v3_MULTI2_totalMintedEqualsExpected() public {
        // 2개 L2 설정 (각각 1000e18 bridgedTON)
        (address l2_A, address opMgr_A, ) = _setupL2("L2_A", address(0x7001), 1000e18);
        (, address opMgr_B, ) = _setupL2("L2_B", address(0x7002), 1000e18);

        uint256 xTotal = seigManager.totalEffectiveBridgedTON();
        address daoAddr = SeigManagerV1_2(seigManagerProxy).dao();

        // 예상값 계산용 변수
        uint256 A;
        uint256 expectedSeqTotal;

        // 초기 잔액 및 예상값 계산
        uint256[5] memory balBefore;
        {
            balBefore[0] = IERC20(wton).balanceOf(daoAddr);               // DAO
            balBefore[1] = IERC20(wton).balanceOf(layer2ManagerProxy);    // Layer2Manager
            balBefore[2] = IERC20(wton).balanceOf(seigManager.validatorReward()); // ValidatorReward
            balBefore[3] = IERC20(wton).balanceOf(opMgr_A);               // OpMgr_A
            balBefore[4] = IERC20(wton).balanceOf(opMgr_B);               // OpMgr_B

            uint256 seigPerBlock = SeigManagerV1_2(seigManagerProxy).seigPerBlock();
            A = 100 * seigPerBlock;
            uint256 L = A - (A * seigManager.daoDistributionRatio()) / RAY;
            uint256 y = (L * xTotal) / (seigManager.halfSaturationPoint() + xTotal);
            expectedSeqTotal = (y * (RAY - seigManager.validatorDistributionRatio())) / RAY;
        }

        vm.roll(block.number + 100);

        // L2_A 호출: 시뇨리지 계산 + L2_A claim
        vm.prank(l2_A);
        seigManager.updateSeigniorage();

        // 잔액 변화 및 검증
        uint256[5] memory received;
        {
            received[0] = IERC20(wton).balanceOf(daoAddr) - balBefore[0];
            received[1] = IERC20(wton).balanceOf(layer2ManagerProxy) - balBefore[1];
            received[2] = IERC20(wton).balanceOf(seigManager.validatorReward()) - balBefore[2];
            received[3] = IERC20(wton).balanceOf(opMgr_A) - balBefore[3];
            received[4] = IERC20(wton).balanceOf(opMgr_B) - balBefore[4];
        }

        emit log_named_uint("A (total seigniorage)", A);
        emit log_named_uint("DAO received", received[0]);
        emit log_named_uint("ValidatorReward received", received[2]);
        emit log_named_uint("OperatorMgr_A received", received[3]);
        emit log_named_uint("Layer2Manager remaining", received[1]);
        emit log_named_uint("Expected seq total", expectedSeqTotal);

        // 핵심 검증: 전체 분배량 = A
        uint256 totalDistributed = received[0] + received[1] + received[2] + received[3] + received[4];
        assertApproxEqRel(totalDistributed, A, 0.01e18, "Total distributed should equal A");

        // 핵심 검증: L2_A만 호출했으므로 L2_A만 받고, L2_B는 Layer2Manager에 남아있음
        // L2_A received + Layer2Manager remaining = expectedSeqTotal
        uint256 actualSeqTotal = received[3] + received[1];
        assertApproxEqRel(actualSeqTotal, expectedSeqTotal, 0.01e18,
            "Sequencer total (claimed + remaining) should equal expected");
    }

    /// @notice SM-016-V3-MULTI-3: 4개 L2, 모두 다른 시점에 호출
    /// @dev 복잡한 시나리오에서 각 L2가 정확한 몫을 받는지 검증
    function test_SM016_v3_MULTI3_fourL2s_staggeredCalls() public {
        // 4개 L2 설정
        (address l2_A, , ) = _setupL2("L2_A", address(0x7001), 1000e18);
        (address l2_B, , ) = _setupL2("L2_B", address(0x7002), 1000e18);
        (address l2_C, , ) = _setupL2("L2_C", address(0x7003), 1000e18);
        (address l2_D, address opMgr_D, ) = _setupL2("L2_D", address(0x7004), 1000e18);

        uint256 xTotal = seigManager.totalEffectiveBridgedTON();

        // 각 기간별로 다른 L2가 호출
        vm.roll(block.number + 100);
        vm.prank(l2_A);
        seigManager.updateSeigniorage();

        vm.roll(block.number + 100);
        vm.prank(l2_B);
        seigManager.updateSeigniorage();

        vm.roll(block.number + 100);
        vm.prank(l2_C);
        seigManager.updateSeigniorage();

        // L2_D: 4개 기간의 누적 몫 받음
        vm.roll(block.number + 100);
        uint256 opMgr_D_before = IERC20(wton).balanceOf(opMgr_D);
        vm.prank(l2_D);
        seigManager.updateSeigniorage();
        uint256 opMgr_D_received = IERC20(wton).balanceOf(opMgr_D) - opMgr_D_before;

        // L2_D 예상: 400 블록 × 25% 지분
        uint256 l2D_expected = _calcExpectedSeqReward(400, xTotal, 1000e27);

        emit log_named_uint("L2_D received (4 periods)", opMgr_D_received);
        emit log_named_uint("L2_D expected", l2D_expected);

        assertApproxEqRel(opMgr_D_received, l2D_expected, 0.05e18,
            "L2_D should receive accumulated share from all 4 periods");
    }

    /// @notice SM-016-V3-MULTI-4: bridgedTONRewardPerUint 누적 검증
    /// @dev debt 패턴의 핵심: rewardPerUnit이 올바르게 누적되는지 확인
    function test_SM016_v3_MULTI4_rewardPerUnitAccumulation() public {
        _setupEligibleL2();

        uint256 rewardPerUnit_initial = seigManager.bridgedTONRewardPerUint();
        emit log_named_uint("Initial bridgedTONRewardPerUint", rewardPerUnit_initial);

        // 첫 번째 updateSeigniorage
        vm.roll(block.number + 100);
        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        uint256 rewardPerUnit_after1 = seigManager.bridgedTONRewardPerUint();
        emit log_named_uint("After period 1 bridgedTONRewardPerUint", rewardPerUnit_after1);
        assertTrue(rewardPerUnit_after1 > rewardPerUnit_initial, "RewardPerUnit should increase");

        // 두 번째 updateSeigniorage
        vm.roll(block.number + 100);
        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        uint256 rewardPerUnit_after2 = seigManager.bridgedTONRewardPerUint();
        emit log_named_uint("After period 2 bridgedTONRewardPerUint", rewardPerUnit_after2);
        assertTrue(rewardPerUnit_after2 > rewardPerUnit_after1, "RewardPerUnit should keep increasing");

        // 증가량이 일정한지 확인 (동일 기간, 동일 조건)
        uint256 increase1 = rewardPerUnit_after1 - rewardPerUnit_initial;
        uint256 increase2 = rewardPerUnit_after2 - rewardPerUnit_after1;
        emit log_named_uint("Period 1 increase", increase1);
        emit log_named_uint("Period 2 increase", increase2);

        assertApproxEqRel(increase1, increase2, 0.01e18, "Increases should be equal for same period length");
    }

    // ==========================================
    // 헬퍼 함수
    // ==========================================

    /// @dev 새로운 L2 설정 (테스트용)
    function _setupL2(
        string memory name,
        address operatorAddr,
        uint256 bridgedAmount
    ) internal returns (address layer2Addr, address opMgrAddr, address portalAddr) {
        address l1Bridge = address(uint160(uint256(keccak256(abi.encodePacked(name, "bridge")))));
        portalAddr = address(uint160(uint256(keccak256(abi.encodePacked(name, "portal")))));
        address dgf = address(uint160(uint256(keccak256(abi.encodePacked(name, "dgf")))));
        address l2ton = address(uint160(uint256(keccak256(abi.encodePacked(name, "l2ton")))));

        SimpleMockSystemConfig sysConfig = new SimpleMockSystemConfig();
        sysConfig.setL1StandardBridge(l1Bridge);
        sysConfig.setOptimismPortal(portalAddr);
        sysConfig.setDisputeGameFactory(dgf);
        sysConfig.setUnsafeBlockSigner(operatorAddr);

        (layer2Addr, opMgrAddr) = _registerLayer2WithSystemConfig(
            address(sysConfig),
            l2ton,
            name,
            operatorAddr,
            1000 * RAY
        );

        // Portal에 TON mint 및 스테이킹
        vm.prank(owner);
        MockTON(ton).mint(portalAddr, bridgedAmount);

        vm.startPrank(operatorAddr);
        MockWTON(wton).mint(operatorAddr, 500 * RAY);
        MockWTON(wton).approve(depositManagerProxy, 500 * RAY);
        depositManager.deposit(layer2Addr, operatorAddr, 500 * RAY);
        vm.stopPrank();

        vm.prank(portalAddr);
        seigManager.onBridgedTonChange();

        (bool eligible, , ) = seigManager.checkCurrentEligibility(layer2Addr);
        assertTrue(eligible, string(abi.encodePacked(name, " should be eligible")));
    }
}
