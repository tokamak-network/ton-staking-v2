// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import {ValidatorRewardV1} from "../../src/validator/ValidatorRewardV1.sol";
import {IValidatorReward} from "../../src/validator/IValidatorReward.sol";
import {MockWTON} from "../../src/mocks/MockWTON.sol";
import {MockTON} from "../../src/mocks/MockTON.sol";

/// @notice Mock RAT contract for ValidatorReward tests
contract MockRAT {
    mapping(address => address[]) internal _validators;
    mapping(address => mapping(address => bool)) internal _isActive;

    function addValidator(address systemConfig, address validator) external {
        _validators[systemConfig].push(validator);
        _isActive[systemConfig][validator] = true;
    }

    function setActive(address systemConfig, address validator, bool active) external {
        _isActive[systemConfig][validator] = active;
    }

    function getL2Validators(address systemConfig) external view returns (address[] memory) {
        return _validators[systemConfig];
    }

    function isValidatorActive(address validator, address systemConfig) external view returns (bool) {
        return _isActive[systemConfig][validator];
    }

    function getActiveValidatorCount(address systemConfig) external view returns (uint256) {
        uint256 count = 0;
        address[] memory validators = _validators[systemConfig];
        for (uint256 i = 0; i < validators.length; i++) {
            if (_isActive[systemConfig][validators[i]]) {
                count++;
            }
        }
        return count;
    }
}

/// @title ValidatorRewardV1Test
/// @notice ValidatorRewardV1 단위 테스트
/// @dev Tokamak Economics Whitepaper V3 (December 16, 2025) 기준
/// gap-analysis.md Priority 1 항목
contract ValidatorRewardV1Test is Test {
    // Event declarations for testing
    event L2RewardDistributed(
        address indexed systemConfig,
        uint256 totalAmount,
        uint256 activeValidatorCount,
        uint256 perValidator
    );
    event ValidatorRewardReceived(
        address indexed validator,
        address indexed systemConfig,
        uint256 amount
    );
    event RewardsClaimed(
        address indexed validator,
        uint256 amount
    );
    event RewardToDAO(
        address indexed systemConfig,
        uint256 amount
    );

    ValidatorRewardV1 public validatorReward;
    MockWTON public wton;
    MockTON public ton;
    MockRAT public mockRat;

    address public owner = address(this);
    address public seigManager = address(0x1);
    address public dao = address(0x4); // DAO = daoVault (SeigManager.dao() 반환값)

    address public systemConfig1 = address(0x10);
    address public systemConfig2 = address(0x20);

    address public validator1 = address(0x100);
    address public validator2 = address(0x200);
    address public validator3 = address(0x300);

    uint256 internal constant RAY = 1e27;

    function setUp() public {
        // Deploy mocks
        wton = new MockWTON();
        ton = new MockTON();
        wton.setTON(address(ton));
        mockRat = new MockRAT();

        // Deploy ValidatorReward directly (without proxy for unit testing)
        // Proxy integration is tested separately in DeployV3Fork.t.sol
        validatorReward = new ValidatorRewardV1();
        // NOTE: treasury 파라미터 제거됨 - SeigManager.dao() 사용
        validatorReward.initialize(
            seigManager,
            address(wton),
            address(mockRat),
            owner
        );

        // Mock SeigManager.dao() to return dao address
        vm.mockCall(
            seigManager,
            abi.encodeWithSignature("dao()"),
            abi.encode(dao)
        );

        // Mint WTON to seigManager for distribution
        wton.mint(seigManager, 100_000_000 * RAY);
        vm.prank(seigManager);
        wton.approve(address(validatorReward), type(uint256).max);

        // Transfer WTON to validatorReward (simulating SeigManager distribution)
        vm.prank(seigManager);
        wton.transfer(address(validatorReward), 10_000_000 * RAY);
    }

    // ==========================================
    // Initialization Tests
    // ==========================================

    function test_initialize_success() public view {
        assertEq(validatorReward.seigManager(), seigManager, "SeigManager should be set");
        assertEq(validatorReward.wton(), address(wton), "WTON should be set");
        assertEq(validatorReward.ratContract(), address(mockRat), "RAT should be set");
        // treasury는 더 이상 initialize에서 설정되지 않음 (SeigManager.dao() 사용)
        assertEq(validatorReward.owner(), owner, "Owner should be set");
    }

    function test_initialize_cannotReinitialize() public {
        vm.expectRevert("already initialized");
        validatorReward.initialize(seigManager, address(wton), address(mockRat), owner);
    }

    // ==========================================
    // distributeL2Rewards Tests
    // ==========================================

    /// @notice 기본 L2 보상 분배 테스트
    function test_distributeL2Rewards_basic() public {
        // Setup: 1 validator
        mockRat.addValidator(systemConfig1, validator1);

        uint256 rewardAmount = 1000 * RAY;

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, rewardAmount);

        // Verify pending rewards
        uint256 pending = validatorReward.getPendingRewards(validator1);
        assertEq(pending, rewardAmount, "Validator should receive full reward");

        // Verify per-L2 pending rewards
        uint256 pendingL2 = validatorReward.getPendingRewardsByL2(validator1, systemConfig1);
        assertEq(pendingL2, rewardAmount, "Per-L2 reward should match");
    }

    /// @notice 여러 검증자에게 균등 분배 테스트
    /// @dev 백서 V3 공식 (13): v_j = (α · S_i) / |V_i|
    function test_distributeL2Rewards_multipleValidators() public {
        // Setup: 3 validators
        mockRat.addValidator(systemConfig1, validator1);
        mockRat.addValidator(systemConfig1, validator2);
        mockRat.addValidator(systemConfig1, validator3);

        uint256 rewardAmount = 3000 * RAY;
        uint256 expectedPerValidator = rewardAmount / 3;

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, rewardAmount);

        // Verify each validator receives equal share
        assertEq(validatorReward.getPendingRewards(validator1), expectedPerValidator, "Validator1 reward");
        assertEq(validatorReward.getPendingRewards(validator2), expectedPerValidator, "Validator2 reward");
        assertEq(validatorReward.getPendingRewards(validator3), expectedPerValidator, "Validator3 reward");
    }

    /// @notice 검증자 없을 때 DAO(daoVault)로 전송
    function test_distributeL2Rewards_noValidators_toDAO() public {
        // No validators registered
        uint256 rewardAmount = 1000 * RAY;
        uint256 daoBefore = wton.balanceOf(dao);

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, rewardAmount);

        // Verify DAO received the reward
        assertEq(
            wton.balanceOf(dao),
            daoBefore + rewardAmount,
            "DAO should receive reward when no validators"
        );
    }

    /// @notice 비활성 검증자 제외 테스트
    function test_distributeL2Rewards_excludeInactiveValidators() public {
        // Setup: 3 validators, 1 inactive
        mockRat.addValidator(systemConfig1, validator1);
        mockRat.addValidator(systemConfig1, validator2);
        mockRat.addValidator(systemConfig1, validator3);
        mockRat.setActive(systemConfig1, validator2, false);

        uint256 rewardAmount = 2000 * RAY;
        uint256 expectedPerValidator = rewardAmount / 2; // Only 2 active validators

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, rewardAmount);

        assertEq(validatorReward.getPendingRewards(validator1), expectedPerValidator, "Validator1 reward");
        assertEq(validatorReward.getPendingRewards(validator2), 0, "Inactive validator should get 0");
        assertEq(validatorReward.getPendingRewards(validator3), expectedPerValidator, "Validator3 reward");
    }

    /// @notice 여러 L2에서 보상 분배 테스트
    function test_distributeL2Rewards_multipleL2s() public {
        // Setup validators for different L2s
        mockRat.addValidator(systemConfig1, validator1);
        mockRat.addValidator(systemConfig2, validator1);
        mockRat.addValidator(systemConfig2, validator2);

        // Distribute to L2_1
        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, 1000 * RAY);

        // Distribute to L2_2
        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig2, 2000 * RAY);

        // Verify validator1 receives from both L2s
        uint256 totalPending = validatorReward.getPendingRewards(validator1);
        assertEq(totalPending, 1000 * RAY + 1000 * RAY, "Validator1 total from both L2s");

        // Verify per-L2 breakdown
        assertEq(validatorReward.getPendingRewardsByL2(validator1, systemConfig1), 1000 * RAY, "V1 from L2_1");
        assertEq(validatorReward.getPendingRewardsByL2(validator1, systemConfig2), 1000 * RAY, "V1 from L2_2");
        assertEq(validatorReward.getPendingRewardsByL2(validator2, systemConfig2), 1000 * RAY, "V2 from L2_2");
    }

    /// @notice 0 금액 분배 시 무시
    function test_distributeL2Rewards_zeroAmount() public {
        mockRat.addValidator(systemConfig1, validator1);

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, 0);

        assertEq(validatorReward.getPendingRewards(validator1), 0, "No reward for 0 amount");
    }

    /// @notice SeigManager만 호출 가능
    function test_distributeL2Rewards_onlySeigManager() public {
        mockRat.addValidator(systemConfig1, validator1);

        vm.prank(validator1);
        vm.expectRevert(abi.encodeWithSignature("NotSeigManagerError()"));
        validatorReward.distributeL2Rewards(systemConfig1, 1000 * RAY);
    }

    /// @notice 연속 분배 테스트 (보상 누적)
    function test_distributeL2Rewards_accumulation() public {
        mockRat.addValidator(systemConfig1, validator1);

        // First distribution
        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, 1000 * RAY);

        // Second distribution
        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, 500 * RAY);

        // Third distribution
        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, 250 * RAY);

        assertEq(validatorReward.getPendingRewards(validator1), 1750 * RAY, "Rewards should accumulate");
    }

    /// @notice 소수점 분배 시 나머지 처리 (버림)
    function test_distributeL2Rewards_remainder() public {
        // Setup: 3 validators
        mockRat.addValidator(systemConfig1, validator1);
        mockRat.addValidator(systemConfig1, validator2);
        mockRat.addValidator(systemConfig1, validator3);

        // 1000 / 3 = 333.33... (remainder exists)
        uint256 rewardAmount = 1000 * RAY;

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, rewardAmount);

        uint256 perValidator = rewardAmount / 3;
        assertEq(validatorReward.getPendingRewards(validator1), perValidator, "Validator1 reward");
        assertEq(validatorReward.getPendingRewards(validator2), perValidator, "Validator2 reward");
        assertEq(validatorReward.getPendingRewards(validator3), perValidator, "Validator3 reward");

        // Note: Remainder (1 RAY) stays in contract
    }

    // ==========================================
    // claimAllRewards Tests
    // ==========================================

    /// @notice 보상 청구 성공
    function test_claimAllRewards_success() public {
        mockRat.addValidator(systemConfig1, validator1);

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, 1000 * RAY);

        uint256 balanceBefore = wton.balanceOf(validator1);

        vm.prank(validator1);
        validatorReward.claimAllRewards();

        uint256 balanceAfter = wton.balanceOf(validator1);

        assertEq(balanceAfter - balanceBefore, 1000 * RAY, "Should receive rewards");
        assertEq(validatorReward.getPendingRewards(validator1), 0, "Pending should be 0 after claim");
    }

    /// @notice 보상 없을 때 청구 실패
    function test_claimAllRewards_noRewards_reverts() public {
        vm.prank(validator1);
        vm.expectRevert(abi.encodeWithSignature("NoRewardsError()"));
        validatorReward.claimAllRewards();
    }

    /// @notice 여러 L2 보상 한번에 청구
    function test_claimAllRewards_multipleL2s() public {
        // Setup validator on multiple L2s
        mockRat.addValidator(systemConfig1, validator1);
        mockRat.addValidator(systemConfig2, validator1);

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, 1000 * RAY);

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig2, 2000 * RAY);

        uint256 balanceBefore = wton.balanceOf(validator1);

        vm.prank(validator1);
        validatorReward.claimAllRewards();

        uint256 balanceAfter = wton.balanceOf(validator1);

        assertEq(balanceAfter - balanceBefore, 3000 * RAY, "Should receive all rewards");
        assertEq(validatorReward.getPendingRewards(validator1), 0, "Pending should be 0");
    }

    /// @notice 부분 청구 후 추가 분배 및 재청구
    function test_claimAllRewards_claimDistributeClaim() public {
        mockRat.addValidator(systemConfig1, validator1);

        // First distribution and claim
        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, 1000 * RAY);

        vm.prank(validator1);
        validatorReward.claimAllRewards();

        assertEq(validatorReward.getPendingRewards(validator1), 0, "Pending should be 0 after first claim");

        // Second distribution
        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, 500 * RAY);

        assertEq(validatorReward.getPendingRewards(validator1), 500 * RAY, "New pending rewards");

        // Second claim
        uint256 balanceBefore = wton.balanceOf(validator1);

        vm.prank(validator1);
        validatorReward.claimAllRewards();

        uint256 balanceAfter = wton.balanceOf(validator1);
        assertEq(balanceAfter - balanceBefore, 500 * RAY, "Should receive second batch");
    }

    // ==========================================
    // getPendingRewards Tests
    // ==========================================

    /// @notice 미청구 보상 조회
    function test_getPendingRewards_accurate() public {
        mockRat.addValidator(systemConfig1, validator1);

        assertEq(validatorReward.getPendingRewards(validator1), 0, "Initial pending should be 0");

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, 1000 * RAY);

        assertEq(validatorReward.getPendingRewards(validator1), 1000 * RAY, "Pending after distribution");
    }

    /// @notice L2별 미청구 보상 조회
    function test_getPendingRewardsByL2_accurate() public {
        mockRat.addValidator(systemConfig1, validator1);
        mockRat.addValidator(systemConfig2, validator1);

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, 1000 * RAY);

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig2, 2000 * RAY);

        assertEq(validatorReward.getPendingRewardsByL2(validator1, systemConfig1), 1000 * RAY, "L2_1 pending");
        assertEq(validatorReward.getPendingRewardsByL2(validator1, systemConfig2), 2000 * RAY, "L2_2 pending");
    }

    // ==========================================
    // Reward Calculation Tests
    // ==========================================

    /// @notice 공식 검증: v_j = (α · S_i) / |V_i|
    /// @dev α는 SeigManager에서 적용되므로 여기서는 amount / activeCount 검증
    function test_rewardCalculation_formula() public {
        // Setup: 5 validators
        mockRat.addValidator(systemConfig1, validator1);
        mockRat.addValidator(systemConfig1, validator2);
        mockRat.addValidator(systemConfig1, validator3);
        mockRat.addValidator(systemConfig1, address(0x400));
        mockRat.addValidator(systemConfig1, address(0x500));

        uint256 totalReward = 5000 * RAY;
        uint256 expectedPerValidator = totalReward / 5;

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, totalReward);

        assertEq(validatorReward.getPendingRewards(validator1), expectedPerValidator, "Formula check");
        assertEq(validatorReward.getPendingRewards(validator2), expectedPerValidator, "Formula check");
        assertEq(validatorReward.getPendingRewards(validator3), expectedPerValidator, "Formula check");
    }

    /// @notice 정밀도 테스트 (작은 금액)
    function test_rewardCalculation_precision() public {
        mockRat.addValidator(systemConfig1, validator1);
        mockRat.addValidator(systemConfig1, validator2);

        // Very small amount
        uint256 smallAmount = 3; // 3 wei (not 3 RAY)

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, smallAmount);

        // 3 / 2 = 1 per validator (integer division)
        assertEq(validatorReward.getPendingRewards(validator1), 1, "Small amount precision");
        assertEq(validatorReward.getPendingRewards(validator2), 1, "Small amount precision");
    }

    // ==========================================
    // Governance Tests
    // ==========================================

    /// @notice RAT 컨트랙트 설정
    function test_setRatContract() public {
        address newRat = address(0x999);

        validatorReward.setRatContract(newRat);
        assertEq(validatorReward.ratContract(), newRat, "RAT should be updated");
    }

    /// @notice RAT 컨트랙트 설정 - 0 주소 실패
    function test_setRatContract_zeroAddress_reverts() public {
        vm.expectRevert(abi.encodeWithSignature("ZeroAddressError()"));
        validatorReward.setRatContract(address(0));
    }

    /// @notice Treasury 설정 - DEPRECATED
    /// @dev treasury는 더 이상 사용되지 않음, SeigManager.dao() 사용
    function test_setTreasury_deprecated_reverts() public {
        vm.expectRevert("deprecated: use SeigManager.dao()");
        validatorReward.setTreasury(address(0x888));
    }

    /// @notice SeigManager 설정
    function test_setSeigManager() public {
        address newSeigManager = address(0x777);

        validatorReward.setSeigManager(newSeigManager);
        assertEq(validatorReward.seigManager(), newSeigManager, "SeigManager should be updated");
    }

    /// @notice SeigManager 설정 - 0 주소 실패
    function test_setSeigManager_zeroAddress_reverts() public {
        vm.expectRevert(abi.encodeWithSignature("ZeroAddressError()"));
        validatorReward.setSeigManager(address(0));
    }

    /// @notice 소유권 이전
    function test_transferOwnership() public {
        address newOwner = address(0x666);

        validatorReward.transferOwnership(newOwner);
        assertEq(validatorReward.owner(), newOwner, "Owner should be transferred");
    }

    /// @notice 소유권 이전 - 0 주소 실패
    function test_transferOwnership_zeroAddress_reverts() public {
        vm.expectRevert("zero address");
        validatorReward.transferOwnership(address(0));
    }

    /// @notice 비소유자 거버넌스 함수 호출 실패
    function test_governance_onlyOwner() public {
        vm.startPrank(validator1);

        vm.expectRevert("not owner");
        validatorReward.setRatContract(address(0x999));

        // setTreasury는 deprecated - onlyOwner 체크 없이 항상 revert
        // 별도의 test_setTreasury_deprecated_reverts에서 테스트

        vm.expectRevert("not owner");
        validatorReward.setSeigManager(address(0x777));

        vm.expectRevert("not owner");
        validatorReward.transferOwnership(address(0x666));

        vm.stopPrank();
    }

    // ==========================================
    // Emergency Functions Tests
    // ==========================================

    /// @notice 비상 출금 테스트
    function test_emergencyWithdraw() public {
        uint256 contractBalance = wton.balanceOf(address(validatorReward));
        uint256 ownerBefore = wton.balanceOf(owner);

        validatorReward.emergencyWithdraw(address(wton), contractBalance);

        assertEq(wton.balanceOf(owner), ownerBefore + contractBalance, "Owner should receive tokens");
        assertEq(wton.balanceOf(address(validatorReward)), 0, "Contract should be empty");
    }

    /// @notice 비상 출금 - 비소유자 실패
    function test_emergencyWithdraw_onlyOwner() public {
        vm.prank(validator1);
        vm.expectRevert("not owner");
        validatorReward.emergencyWithdraw(address(wton), 100 * RAY);
    }

    // ==========================================
    // Event Tests
    // ==========================================

    /// @notice L2RewardDistributed 이벤트
    function test_event_L2RewardDistributed() public {
        mockRat.addValidator(systemConfig1, validator1);
        mockRat.addValidator(systemConfig1, validator2);

        uint256 rewardAmount = 2000 * RAY;

        vm.expectEmit(true, false, false, true);
        emit L2RewardDistributed(systemConfig1, rewardAmount, 2, rewardAmount / 2);

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, rewardAmount);
    }

    /// @notice ValidatorRewardReceived 이벤트
    function test_event_ValidatorRewardReceived() public {
        mockRat.addValidator(systemConfig1, validator1);

        uint256 rewardAmount = 1000 * RAY;

        vm.expectEmit(true, true, false, true);
        emit ValidatorRewardReceived(validator1, systemConfig1, rewardAmount);

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, rewardAmount);
    }

    /// @notice RewardsClaimed 이벤트
    function test_event_RewardsClaimed() public {
        mockRat.addValidator(systemConfig1, validator1);

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, 1000 * RAY);

        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(validator1, 1000 * RAY);

        vm.prank(validator1);
        validatorReward.claimAllRewards();
    }

    /// @notice RewardToDAO 이벤트
    function test_event_RewardToDAO() public {
        uint256 rewardAmount = 1000 * RAY;

        vm.expectEmit(true, false, false, true);
        emit RewardToDAO(systemConfig1, rewardAmount);

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, rewardAmount);
    }
}
