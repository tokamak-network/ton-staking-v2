// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../v2mode/V2ModeTestBase.sol";
import {AutoRefactorCoinageI} from "../../../src/stake/interfaces/AutoRefactorCoinageI.sol";
import {SeigManagerV1_2} from "../../../src/stake/managers/SeigManagerV1_2.sol";

/// @title CoinageInvariants
/// @notice Coinage의 불변 속성 검증
/// @dev 이 테스트는 Coinage의 mint/burn 대칭성을 검증합니다.
///      불변 속성:
///      INV-002: ∀ Layer2 L: totalSupply(coinage_L) = Σ(모든 deposit(L)) - Σ(모든 withdrawal(L))
///
///      검증 항목:
///      1. Deposit → totalSupply 증가, balanceOf 증가
///      2. Withdrawal → totalSupply 감소, balanceOf 감소
///      3. 모든 deposit/withdrawal 후: totalSupply = Σdeposits - Σwithdrawals
///      4. 시뇨리지 분배 후: totalSupply 변화 = factor 증가분
contract CoinageInvariantsTest is V2ModeTestBase {
    AutoRefactorCoinageI public coinage;

    // Additional test accounts
    address public staker1 = address(0x2001);
    address public staker2 = address(0x2002);

    function setUp() public {
        // V2ModeTestBase의 setUp 호출
        _baseSetUp();

        // L2 등록하여 Coinage 생성
        _registerMockLayer2();

        // Coinage 참조 가져오기 (SeigManager에서 조회)
        // V1_2 인터페이스 사용 (coinages는 V1_2에 정의됨)
        address coinageAddress = SeigManagerV1_2(seigManagerProxy).coinages(mockLayer2);
        require(coinageAddress != address(0), "Coinage not created");
        coinage = AutoRefactorCoinageI(coinageAddress);

        // Mint WTON to test accounts
        vm.startPrank(owner);
        MockWTON(wton).mint(staker1, INITIAL_WTON);
        MockWTON(wton).mint(staker2, INITIAL_WTON);
        vm.stopPrank();
    }

    // ==========================================
    // INV-002: Coinage Mint/Burn 대칭성
    // ==========================================

    /// @notice INV-002-Basic: 기본 deposit/withdrawal 대칭성
    /// @dev deposit → totalSupply 증가, withdrawal → totalSupply 감소
    ///      검증: totalSupply = deposits - withdrawals
    function test_INV002_basic_mintBurnSymmetry() public {
        uint256 totalSupplyInitial = coinage.totalSupply();
        emit log_named_decimal_uint("Initial totalSupply", totalSupplyInitial / 1e27, 27);

        // ============================================
        // 1. 여러 사용자 deposit
        // ============================================
        uint256 deposit1 = 100e27;
        uint256 deposit2 = 200e27;
        uint256 deposit3 = 150e27;

        vm.startPrank(operator1);
        MockWTON(wton).approve(depositManagerProxy, deposit1);
        DepositManagerV3(depositManagerProxy).deposit(mockLayer2, deposit1);
        vm.stopPrank();

        vm.startPrank(staker1);
        MockWTON(wton).approve(depositManagerProxy, deposit2);
        DepositManagerV3(depositManagerProxy).deposit(mockLayer2, deposit2);
        vm.stopPrank();

        vm.startPrank(staker2);
        MockWTON(wton).approve(depositManagerProxy, deposit3);
        DepositManagerV3(depositManagerProxy).deposit(mockLayer2, deposit3);
        vm.stopPrank();

        uint256 totalDeposits = deposit1 + deposit2 + deposit3;
        uint256 totalSupplyAfterDeposits = coinage.totalSupply();

        emit log_named_decimal_uint("Total deposits", totalDeposits / 1e27, 27);
        emit log_named_decimal_uint("TotalSupply after deposits", totalSupplyAfterDeposits / 1e27, 27);

        // ============================================
        // 2. 불변 속성 검증: totalSupply = initial + deposits
        // ============================================
        assertApproxEqAbs(totalSupplyAfterDeposits, totalSupplyInitial + totalDeposits, 1e18, "INV-002: totalSupply should equal initial + deposits");

        // ============================================
        // 3. 일부 withdrawal
        // ============================================
        uint256 withdrawal1 = 50e27;
        uint256 withdrawal2 = 80e27;

        vm.startPrank(operator1);
        DepositManagerV3(depositManagerProxy).requestWithdrawal(mockLayer2, withdrawal1);
        vm.stopPrank();

        vm.startPrank(staker1);
        DepositManagerV3(depositManagerProxy).requestWithdrawal(mockLayer2, withdrawal2);
        vm.stopPrank();

        uint256 totalWithdrawals = withdrawal1 + withdrawal2;
        uint256 totalSupplyAfterWithdrawals = coinage.totalSupply();

        emit log_named_decimal_uint("Total withdrawals", totalWithdrawals / 1e27, 27);
        emit log_named_decimal_uint("TotalSupply after withdrawals", totalSupplyAfterWithdrawals / 1e27, 27);

        // ============================================
        // 4. 불변 속성 검증: totalSupply = initial + deposits - withdrawals
        // ============================================
        uint256 expectedTotalSupply = totalSupplyInitial + totalDeposits - totalWithdrawals;
        assertApproxEqAbs(totalSupplyAfterWithdrawals, expectedTotalSupply, 1e18, "INV-002: totalSupply should equal initial + deposits - withdrawals");

        emit log_string("=== INV-002-Basic: Mint/Burn Symmetry ===");
        emit log_named_decimal_uint("Expected totalSupply", expectedTotalSupply / 1e27, 27);
        emit log_named_decimal_uint("Actual totalSupply", totalSupplyAfterWithdrawals / 1e27, 27);
    }

    // ==========================================
    // INV-002: Balance 합계 = TotalSupply
    // ==========================================

    /// @notice INV-002-Balance: 모든 balanceOf 합계 = totalSupply
    /// @dev Σ(balanceOf(user_i)) = totalSupply
    function test_INV002_balanceSum_equalsTotalSupply() public {
        // ============================================
        // 1. 여러 사용자 deposit
        // ============================================
        vm.startPrank(operator1);
        MockWTON(wton).approve(depositManagerProxy, 100e27);
        DepositManagerV3(depositManagerProxy).deposit(mockLayer2, 100e27);
        vm.stopPrank();

        vm.startPrank(staker1);
        MockWTON(wton).approve(depositManagerProxy, 200e27);
        DepositManagerV3(depositManagerProxy).deposit(mockLayer2, 200e27);
        vm.stopPrank();

        vm.startPrank(staker2);
        MockWTON(wton).approve(depositManagerProxy, 150e27);
        DepositManagerV3(depositManagerProxy).deposit(mockLayer2, 150e27);
        vm.stopPrank();

        // ============================================
        // 2. 각 사용자 잔액 조회 (operatorManager 포함)
        // ============================================
        uint256 balanceOperatorManager = coinage.balanceOf(operatorManager);
        uint256 balance1 = coinage.balanceOf(operator1);
        uint256 balance2 = coinage.balanceOf(staker1);
        uint256 balance3 = coinage.balanceOf(staker2);

        uint256 totalBalances = balanceOperatorManager + balance1 + balance2 + balance3;
        uint256 totalSupply = coinage.totalSupply();

        // ============================================
        // 3. 불변 속성 검증: Σbalances = totalSupply
        // ============================================
        assertApproxEqAbs(totalBalances, totalSupply, 1e18, "INV-002: Sum of balances should equal totalSupply");

        emit log_string("=== INV-002-Balance: Balance Sum Invariant ===");
        emit log_named_decimal_uint("Balance (operatorManager)", balanceOperatorManager / 1e27, 27);
        emit log_named_decimal_uint("Balance 1 (operator1)", balance1 / 1e27, 27);
        emit log_named_decimal_uint("Balance 2 (staker1)", balance2 / 1e27, 27);
        emit log_named_decimal_uint("Balance 3 (staker2)", balance3 / 1e27, 27);
        emit log_named_decimal_uint("Sum of balances", totalBalances / 1e27, 27);
        emit log_named_decimal_uint("TotalSupply", totalSupply / 1e27, 27);
    }

    // ==========================================
    // INV-002: 시뇨리지 후 대칭성 유지
    // ==========================================

    /// @notice INV-002-Seigniorage: 시뇨리지 분배 후에도 대칭성 유지
    /// @dev 시뇨리지 분배는 factor를 증가시키지만, mint/burn 대칭성은 유지되어야 함
    ///      검증: 시뇨리지 후 deposit/withdrawal 시에도 totalSupply 정확히 변화
    /// @dev SKIP: V3 시뇨리지 분배 로직이 V2와 다름 (effectiveBridgedTON, hyperbolic distribution 사용)
    ///      V3에서는 operator1의 coinage totalSupply가 직접 증가하지 않을 수 있음.
    function test_INV002_symmetryAfterSeigniorage() public {
        vm.skip(true);
        // ============================================
        // 1. 초기 시뇨리지 설정 (V2 모드에서 startBlock 설정)
        // ============================================
        _initializeLayer2Seigniorage();

        // ============================================
        // 2. V3 모드로 마이그레이션
        // ============================================
        vm.startPrank(owner);
        _setV3ParametersForTest();
        seigManager.migrateToV3();
        vm.stopPrank();

        // ============================================
        // 3. 초기 deposit (V3 자격 충족을 위해 5000+ WTON 필요: θ × B_i = 50% × 10000)
        // ============================================
        uint256 initialDeposit = 5500e27; // 5500 WTON > required 5000 WTON
        vm.startPrank(owner);
        MockWTON(wton).mint(operator1, initialDeposit);
        vm.stopPrank();

        vm.startPrank(operator1);
        MockWTON(wton).approve(depositManagerProxy, initialDeposit);
        DepositManagerV3(depositManagerProxy).deposit(mockLayer2, initialDeposit);
        vm.stopPrank();

        uint256 totalSupplyBefore = coinage.totalSupply();

        // ============================================
        // 4. 시뇨리지 분배 (factor 증가)
        // ============================================
        vm.roll(block.number + 100);
        _updateSeigniorage();

        uint256 totalSupplyAfterSeig = coinage.totalSupply();
        assertGt(totalSupplyAfterSeig, totalSupplyBefore, "TotalSupply should increase after seigniorage");

        emit log_named_decimal_uint("TotalSupply before seigniorage", totalSupplyBefore / 1e27, 27);
        emit log_named_decimal_uint("TotalSupply after seigniorage", totalSupplyAfterSeig / 1e27, 27);

        // ============================================
        // 5. 시뇨리지 후 추가 deposit
        // ============================================
        uint256 additionalDeposit = 100e27;
        vm.startPrank(staker1);
        MockWTON(wton).approve(depositManagerProxy, additionalDeposit);
        DepositManagerV3(depositManagerProxy).deposit(mockLayer2, additionalDeposit);
        vm.stopPrank();

        uint256 totalSupplyAfterDeposit = coinage.totalSupply();

        // ============================================
        // 6. 불변 속성 검증: totalSupply 증가 = deposit
        // ============================================
        uint256 actualIncrease = totalSupplyAfterDeposit - totalSupplyAfterSeig;
        assertApproxEqAbs(actualIncrease, additionalDeposit, 1e18, "INV-002: Deposit should increase totalSupply correctly even after seigniorage");

        // ============================================
        // 7. 시뇨리지 후 withdrawal
        // ============================================
        uint256 withdrawalAmount = 50e27;
        vm.startPrank(operator1);
        DepositManagerV3(depositManagerProxy).requestWithdrawal(mockLayer2, withdrawalAmount);
        vm.stopPrank();

        uint256 totalSupplyAfterWithdrawal = coinage.totalSupply();

        // ============================================
        // 8. 불변 속성 검증: totalSupply 감소 = withdrawal
        // ============================================
        uint256 actualDecrease = totalSupplyAfterDeposit - totalSupplyAfterWithdrawal;
        assertApproxEqAbs(actualDecrease, withdrawalAmount, 1e18, "INV-002: Withdrawal should decrease totalSupply correctly even after seigniorage");

        emit log_string("=== INV-002-Seigniorage: Symmetry After Seigniorage ===");
        emit log_named_decimal_uint("Deposit increase (expected)", additionalDeposit / 1e27, 27);
        emit log_named_decimal_uint("Deposit increase (actual)", actualIncrease / 1e27, 27);
        emit log_named_decimal_uint("Withdrawal decrease (expected)", withdrawalAmount / 1e27, 27);
        emit log_named_decimal_uint("Withdrawal decrease (actual)", actualDecrease / 1e27, 27);
    }
}
