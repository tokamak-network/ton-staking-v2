// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../helpers/V3TestBase.sol";
import {OnlyLayer2ManagerError, PausedError, NotExcludedError, AlreadyExcludedError} from "../../../src/stake/managers/SeigManagerV3_1.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

/// @title SeigManagerPausableTest
/// @notice SeigManager pause/unpause 및 L2 Seigniorage 제어 기능 테스트
/// @dev 테스트 대상 (SM-050~SM-063):
///      - SM-050~053: pause() 관련 테스트
///      - SM-054~056: unpause() 관련 테스트
///      - SM-057~059: excludeFromL2Seigniorage() 관련 테스트
///      - SM-060~062: includeFromL2Seigniorage() 관련 테스트
///      - SM-063: pause 상태에서 updateSeigniorage 동작
contract SeigManagerPausableTest is V3TestBase {
    // ==========================================
    // Test Addresses
    // ==========================================
    address public pauser = address(0x7001);
    address public notPauser = address(0x7002);

    // PAUSE_ROLE from AuthRole.sol
    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE");

    function setUp() public {
        _v3TestSetup();

        // 추가 셀렉터 등록 (pause, unpause, excludeFromL2Seigniorage, includeFromL2Seigniorage)
        _registerPausableSelectors();

        // L2 등록 (내부에서 자체 prank 사용)
        _registerFirstL2(1000 * RAY);

        // V3 마이그레이션
        vm.startPrank(owner);
        _setupV3AndMigrate();

        // pauser 역할 부여
        IAccessControl(seigManagerProxy).grantRole(PAUSE_ROLE, pauser);
        vm.stopPrank();
    }

    /// @notice includeFromL2Seigniorage 셀렉터 등록
    /// @dev pause/unpause는 _setupSeigManagerV3AllTestSelectors에서 이미 등록됨
    ///      excludeFromL2Seigniorage는 _setupSeigManagerV3ParameterSelectors에서 이미 등록됨
    function _registerPausableSelectors() internal {
        vm.startPrank(owner);
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = SeigManagerV3_1.includeFromL2Seigniorage.selector;
        SeigManagerProxy(payable(seigManagerProxy)).setSelectorImplementations2(selectors, seigManagerV3_1Impl);
        vm.stopPrank();
    }

    // ==========================================
    // pause() 테스트 (SM-050~053)
    // ==========================================

    /// @notice SM-050: pauser가 정상적으로 일시정지
    function test_SM050_pause_success() public {
        // 사전 조건: paused = false
        assertFalse(seigManager.paused(), "Should not be paused initially");

        // updateSeigniorage 먼저 호출하여 _lastSeigBlock 업데이트
        vm.roll(block.number + 10);
        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        // pause 호출
        vm.prank(pauser);
        seigManager.pause();

        // 사후 조건: paused = true
        assertTrue(seigManager.paused(), "Should be paused");
        assertEq(seigManager.pausedBlock(), block.number, "pausedBlock should be set");
    }

    /// @notice SM-051: pauser가 아닌 주소가 호출 시 revert
    function test_SM051_pause_notPauser_reverts() public {
        vm.prank(notPauser);
        vm.expectRevert(bytes("AuthControl: Caller is not a pauser"));
        seigManager.pause();
    }

    /// @notice SM-052: 이미 paused 상태에서 호출 시 revert
    function test_SM052_pause_alreadyPaused_reverts() public {
        // 먼저 pause
        vm.roll(block.number + 10);
        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        vm.prank(pauser);
        seigManager.pause();

        // 다시 pause 시도
        vm.prank(pauser);
        vm.expectRevert(PausedError.selector);
        seigManager.pause();
    }

    /// @notice SM-053: pause 후 다시 pause 하려면 updateSeigniorage 필요
    function test_SM053_pause_updateSeigniorageRequired_reverts() public {
        // 먼저 정상적으로 pause/unpause 수행
        vm.roll(block.number + 10);
        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        vm.prank(pauser);
        seigManager.pause();

        vm.prank(pauser);
        seigManager.unpause();

        // 이 시점에서 _pausedBlock == block.number, _lastSeigBlock < block.number
        // 따라서 _pausedBlock >= _lastSeigBlock 조건 성립
        // 블록 진행 없이 다시 pause 시도하면 revert
        vm.prank(pauser);
        vm.expectRevert(bytes("updateSeigniorage required"));
        seigManager.pause();
    }

    // ==========================================
    // unpause() 테스트 (SM-054~056)
    // ==========================================

    /// @notice SM-054: pauser가 정상적으로 재개
    function test_SM054_unpause_success() public {
        // 먼저 pause
        vm.roll(block.number + 10);
        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        vm.prank(pauser);
        seigManager.pause();

        assertTrue(seigManager.paused(), "Should be paused");

        // unpause 호출
        vm.prank(pauser);
        seigManager.unpause();

        // 사후 조건
        assertFalse(seigManager.paused(), "Should not be paused");
        assertEq(seigManager.unpausedBlock(), block.number, "unpausedBlock should be set");
    }

    /// @notice SM-055: pauser가 아닌 주소가 호출 시 revert
    function test_SM055_unpause_notPauser_reverts() public {
        // 먼저 pause
        vm.roll(block.number + 10);
        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        vm.prank(pauser);
        seigManager.pause();

        // notPauser가 unpause 시도
        vm.prank(notPauser);
        vm.expectRevert(bytes("AuthControl: Caller is not a pauser"));
        seigManager.unpause();
    }

    /// @notice SM-056: paused 상태가 아닐 때 호출 시 revert
    function test_SM056_unpause_notPaused_reverts() public {
        // paused = false 상태에서 unpause 시도
        vm.prank(pauser);
        vm.expectRevert(bytes("Pausable: not paused"));
        seigManager.unpause();
    }

    // ==========================================
    // excludeFromL2Seigniorage() 테스트 (SM-057~059)
    // ==========================================

    /// @notice SM-057: Layer2Manager가 정상적으로 제외
    /// @dev 상태 검증: effectiveBridgedTON = 0, L2별 pause 상태 확인
    function test_SM057_excludeFromL2Seigniorage_success() public {
        // excludeFromL2Seigniorage 내부에서 updateSeigniorage 호출하므로 블록 진행 필요
        vm.roll(block.number + 10);

        // 사전 조건: effectiveBridgedTON 확인 (0이 아닐 수 있음)
        // exclude 후에는 반드시 0이어야 함

        // Layer2Manager에서 호출
        vm.prank(layer2ManagerProxy);
        bool result = seigManager.excludeFromL2Seigniorage(mockLayer2);

        assertTrue(result, "Should return true");

        // 사후 조건: effectiveBridgedTON = 0
        uint256 effectiveBridgedTON = seigManager.getEffectiveBridgedTon(mockLayer2);
        assertEq(effectiveBridgedTON, 0, "effectiveBridgedTON should be 0 after exclude");

        // 다시 exclude 시도하면 AlreadyExcludedError (L2가 pause 상태임을 의미)
        vm.prank(layer2ManagerProxy);
        vm.expectRevert(AlreadyExcludedError.selector);
        seigManager.excludeFromL2Seigniorage(mockLayer2);
    }

    /// @notice SM-058: Layer2Manager가 아닌 주소가 호출 시 revert
    function test_SM058_excludeFromL2Seigniorage_notLayer2Manager_reverts() public {
        vm.prank(notPauser);
        vm.expectRevert(OnlyLayer2ManagerError.selector);
        seigManager.excludeFromL2Seigniorage(mockLayer2);

        vm.prank(owner);
        vm.expectRevert(OnlyLayer2ManagerError.selector);
        seigManager.excludeFromL2Seigniorage(mockLayer2);
    }

    /// @notice SM-059: 이미 제외된 L2 다시 제외 시 revert
    function test_SM059_excludeFromL2Seigniorage_alreadyExcluded_reverts() public {
        vm.roll(block.number + 10);

        // 먼저 제외
        vm.prank(layer2ManagerProxy);
        seigManager.excludeFromL2Seigniorage(mockLayer2);

        // 다시 제외 시도
        vm.prank(layer2ManagerProxy);
        vm.expectRevert(AlreadyExcludedError.selector);
        seigManager.excludeFromL2Seigniorage(mockLayer2);
    }

    // ==========================================
    // includeFromL2Seigniorage() 테스트 (SM-060~062)
    // ==========================================

    /// @notice SM-060: Layer2Manager가 정상적으로 포함
    /// @dev 상태 검증: 제외 해제 후 시뇨리지 수령 가능 확인
    function test_SM060_includeFromL2Seigniorage_success() public {
        // 먼저 L2 자격 획득을 위해 bridgedTON 설정
        vm.prank(owner);
        MockTON(ton).mint(mockPortal, 1000e18);
        vm.prank(mockPortal);
        seigManager.onBridgedTonChange();

        // 자격 확인
        (bool eligibleBefore, , ) = seigManager.checkCurrentEligibility(mockLayer2);
        assertTrue(eligibleBefore, "Should be eligible before exclude");

        // exclude 전 시뇨리지 수령 가능 확인
        vm.roll(block.number + 100);
        uint256 balanceBeforeExclude = MockWTON(wton).balanceOf(operatorManager);
        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();
        uint256 balanceAfterFirstUpdate = MockWTON(wton).balanceOf(operatorManager);
        assertGt(balanceAfterFirstUpdate, balanceBeforeExclude, "Should receive seigniorage before exclude");

        vm.roll(block.number + 10);

        // 먼저 제외
        vm.prank(layer2ManagerProxy);
        seigManager.excludeFromL2Seigniorage(mockLayer2);

        // 제외 상태 확인: effectiveBridgedTON = 0, isEligible = false
        assertEq(seigManager.getEffectiveBridgedTon(mockLayer2), 0, "Should be 0 after exclude");
        (, , , , , , bool isEligibleAfterExclude) = seigManager.bridgedTONInfo(mockLayer2);
        assertFalse(isEligibleAfterExclude, "isEligible should be false after exclude");

        // exclude 후 시뇨리지 수령 안 됨 확인
        vm.roll(block.number + 100);
        uint256 balanceBeforeUpdateWhileExcluded = MockWTON(wton).balanceOf(operatorManager);
        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();
        uint256 balanceAfterUpdateWhileExcluded = MockWTON(wton).balanceOf(operatorManager);
        assertEq(balanceAfterUpdateWhileExcluded, balanceBeforeUpdateWhileExcluded, "Should NOT receive seigniorage while excluded");

        // 블록 진행
        vm.roll(block.number + 10);

        // 다시 포함
        vm.prank(layer2ManagerProxy);
        bool result = seigManager.includeFromL2Seigniorage(mockLayer2);
        assertTrue(result, "Should return true");

        // 사후 조건 1: L2가 더 이상 pause 상태가 아님
        vm.prank(layer2ManagerProxy);
        vm.expectRevert(NotExcludedError.selector);
        seigManager.includeFromL2Seigniorage(mockLayer2);

        // 사후 조건 2: V3 자격 복구 확인 (isEligible = true, effectiveBridgedTON > 0)
        (, , , , , , bool isEligibleAfterInclude) = seigManager.bridgedTONInfo(mockLayer2);
        assertTrue(isEligibleAfterInclude, "isEligible should be true after include");

        uint256 effectiveAfterInclude = seigManager.getEffectiveBridgedTon(mockLayer2);
        assertGt(effectiveAfterInclude, 0, "effectiveBridgedTON should be > 0 after include");

        // 사후 조건 3: 시뇨리지 수령 가능 확인
        vm.roll(block.number + 100);

        uint256 operatorBalanceBefore = MockWTON(wton).balanceOf(operatorManager);
        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();
        uint256 operatorBalanceAfter = MockWTON(wton).balanceOf(operatorManager);

        assertGt(operatorBalanceAfter, operatorBalanceBefore, "Should receive seigniorage after include");
    }

    /// @notice SM-061: Layer2Manager가 아닌 주소가 호출 시 revert
    function test_SM061_includeFromL2Seigniorage_notLayer2Manager_reverts() public {
        vm.prank(notPauser);
        vm.expectRevert(OnlyLayer2ManagerError.selector);
        seigManager.includeFromL2Seigniorage(mockLayer2);
    }

    /// @notice SM-062: 제외되지 않은 L2 포함 시 revert
    function test_SM062_includeFromL2Seigniorage_notExcluded_reverts() public {
        // 제외되지 않은 상태에서 포함 시도
        vm.prank(layer2ManagerProxy);
        vm.expectRevert(NotExcludedError.selector);
        seigManager.includeFromL2Seigniorage(mockLayer2);
    }

    // ==========================================
    // 통합 테스트: pause 상태에서 updateSeigniorage (SM-063)
    // ==========================================

    /// @notice SM-063: pause 상태에서 updateSeigniorage 호출 시 조기 리턴
    function test_SM063_updateSeigniorage_whenPaused_earlyReturn() public {
        // updateSeigniorage 먼저 호출
        vm.roll(block.number + 10);
        vm.prank(mockLayer2);
        seigManager.updateSeigniorage();

        uint256 lastSeigBlockBefore = seigManager.lastSeigBlock();

        // pause
        vm.prank(pauser);
        seigManager.pause();

        // 블록 진행 후 updateSeigniorage
        vm.roll(block.number + 100);
        vm.prank(mockLayer2);
        bool result = seigManager.updateSeigniorage();

        // paused 상태에서는 true 리턴하지만 lastSeigBlock 변경 없음
        assertTrue(result, "Should return true");
        assertEq(seigManager.lastSeigBlock(), lastSeigBlockBefore, "lastSeigBlock should not change when paused");
    }
}
