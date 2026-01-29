// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import {ValidatorRewardV1} from "../../../src/validator/ValidatorRewardV1.sol";
import {IValidatorReward} from "../../../src/validator/IValidatorReward.sol";
import {MockWTON} from "../../../src/mocks/MockWTON.sol";
import {MockTON} from "../../../src/mocks/MockTON.sol";

/// @notice Mock RAT contract for ValidatorReward tests
/// @dev V1.1: O(1) 분배를 위해 ValidatorReward에 검증자 등록 기능 추가
contract MockRAT {
    mapping(address => address[]) internal _validators;
    mapping(address => mapping(address => bool)) internal _isActive;

    // V1.1: ValidatorReward 컨트랙트 주소
    address public validatorReward;

    function setValidatorReward(address _validatorReward) external {
        validatorReward = _validatorReward;
    }

    function addValidator(address systemConfig, address validator) external {
        _validators[systemConfig].push(validator);
        _isActive[systemConfig][validator] = true;

        // V1.1: ValidatorReward에 검증자 등록
        if (validatorReward != address(0)) {
            IValidatorReward(validatorReward).registerValidatorToL2(validator, systemConfig);
        }
    }

    function setActive(address systemConfig, address validator, bool active) external {
        // V1.1: 비활성화 시 보상 동기화, 활성화 시 debt 리셋
        if (validatorReward != address(0)) {
            if (!active && _isActive[systemConfig][validator]) {
                IValidatorReward(validatorReward).syncValidatorReward(validator, systemConfig);
            } else if (active && !_isActive[systemConfig][validator]) {
                IValidatorReward(validatorReward).resetValidatorDebt(validator, systemConfig);
            }
        }
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

        // V1.1: MockRAT에 ValidatorReward 연결 (O(1) 분배용)
        mockRat.setValidatorReward(address(validatorReward));
    }

    // ==========================================
    // Initialization Tests
    // ==========================================

    function test_VR005_initialize_success() public view {
        assertEq(validatorReward.seigManager(), seigManager, "SeigManager should be set");
        assertEq(validatorReward.wton(), address(wton), "WTON should be set");
        assertEq(validatorReward.ratContract(), address(mockRat), "RAT should be set");
        // treasury는 더 이상 initialize에서 설정되지 않음 (SeigManager.dao() 사용)
        assertEq(validatorReward.owner(), owner, "Owner should be set");
    }

    function test_VR006_initialize_cannotReinitialize() public {
        vm.expectRevert("already initialized");
        validatorReward.initialize(seigManager, address(wton), address(mockRat), owner);
    }

    // ==========================================
    // distributeL2Rewards Tests
    // ==========================================

    /// @notice 기본 L2 보상 분배 테스트
    /// @dev V1.1: O(1) 분배에서는 getClaimableRewards 사용
    function test_VR001_distributeL2Rewards_basic() public {
        // Setup: 1 validator
        mockRat.addValidator(systemConfig1, validator1);

        uint256 rewardAmount = 1000 * RAY;

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, rewardAmount);

        // V1.1: O(1) 분배에서는 getClaimableRewards 사용 (동기화되지 않은 보상 포함)
        uint256 claimable = validatorReward.getClaimableRewards(validator1);
        assertEq(claimable, rewardAmount, "Validator should receive full reward");

        // rewardPerValidator 확인
        assertEq(validatorReward.rewardPerValidator(systemConfig1), rewardAmount, "rewardPerValidator should match");
    }

    /// @notice 여러 검증자에게 균등 분배 테스트
    /// @dev 백서 V3 공식 (13): v_j = (α · S_i) / |V_i|
    /// @dev V1.1: O(1) 분배에서는 getClaimableRewards 사용
    function test_VR003_distributeL2Rewards_multipleValidators() public {
        // Setup: 3 validators
        mockRat.addValidator(systemConfig1, validator1);
        mockRat.addValidator(systemConfig1, validator2);
        mockRat.addValidator(systemConfig1, validator3);

        uint256 rewardAmount = 3000 * RAY;
        uint256 expectedPerValidator = rewardAmount / 3;

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, rewardAmount);

        // V1.1: O(1) 분배에서는 getClaimableRewards 사용
        assertEq(validatorReward.getClaimableRewards(validator1), expectedPerValidator, "Validator1 reward");
        assertEq(validatorReward.getClaimableRewards(validator2), expectedPerValidator, "Validator2 reward");
        assertEq(validatorReward.getClaimableRewards(validator3), expectedPerValidator, "Validator3 reward");
    }

    /// @notice 검증자 없을 때 DAO(daoVault)로 전송
    function test_VR002_distributeL2Rewards_noValidators_toDAO() public {
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

    /// @notice VR-007: 비활성 검증자 제외 테스트
    /// @dev V1.1: O(1) 분배에서는 getClaimableRewards 사용
    function test_VR007_distributeL2Rewards_excludeInactiveValidators() public {
        // Setup: 3 validators, 1 inactive
        mockRat.addValidator(systemConfig1, validator1);
        mockRat.addValidator(systemConfig1, validator2);
        mockRat.addValidator(systemConfig1, validator3);
        mockRat.setActive(systemConfig1, validator2, false);

        uint256 rewardAmount = 2000 * RAY;
        uint256 expectedPerValidator = rewardAmount / 2; // Only 2 active validators

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, rewardAmount);

        // V1.1: O(1) 분배에서는 getClaimableRewards 사용
        assertEq(validatorReward.getClaimableRewards(validator1), expectedPerValidator, "Validator1 reward");
        assertEq(validatorReward.getClaimableRewards(validator2), 0, "Inactive validator should get 0");
        assertEq(validatorReward.getClaimableRewards(validator3), expectedPerValidator, "Validator3 reward");
    }

    /// @notice VR-034: 재등록 시 비활성화 기간 보상 받지 않음
    /// @dev 탈퇴 후 재등록 시 debt가 리셋되어 비활성화 기간 보상 차단
    function test_VR034_reregistration_debtReset() public {
        // 1. 검증자 등록
        mockRat.addValidator(systemConfig1, validator1);

        // 2. 첫 보상 분배 (validator1 활성 상태)
        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, 1000 * RAY);

        assertEq(validatorReward.getClaimableRewards(validator1), 1000 * RAY, "Step 2: Should have 1000 RAY");

        // 3. 검증자 비활성화 (보상 동기화 시뮬레이션)
        mockRat.setActive(systemConfig1, validator1, false);

        // 4. 비활성화 기간 동안 추가 보상 분배
        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, 2000 * RAY);

        // 비활성화 상태이므로 새 보상 못 받음 (기존 1000만 유지)
        assertEq(validatorReward.getClaimableRewards(validator1), 1000 * RAY, "Step 4: Still 1000 RAY (inactive)");

        // 5. 검증자 재등록 (재활성화)
        // MockRAT에서 addValidator 재호출 시 registerValidatorToL2 호출
        mockRat.setActive(systemConfig1, validator1, true);
        // 재등록 시 debt 리셋을 위해 registerValidatorToL2 재호출
        vm.prank(address(mockRat));
        validatorReward.registerValidatorToL2(validator1, systemConfig1);

        // debt가 현재 rewardPerValidator(3000)로 리셋되어야 함
        // 기존 동기화된 보상(1000)만 청구 가능
        assertEq(validatorReward.getClaimableRewards(validator1), 1000 * RAY, "Step 5: Still 1000 RAY after re-registration");

        // 6. 재등록 후 새 보상 분배
        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, 500 * RAY);

        // 기존 1000 + 새 보상 500 = 1500
        assertEq(validatorReward.getClaimableRewards(validator1), 1500 * RAY, "Step 6: 1000 + 500 = 1500 RAY");
    }

    /// @notice VR-008: 여러 L2에서 보상 분배 테스트
    /// @dev V1.1: O(1) 분배에서는 getClaimableRewards 사용
    function test_VR008_distributeL2Rewards_multipleL2s() public {
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

        // V1.1: O(1) 분배에서는 getClaimableRewards 사용 (총 청구 가능 금액)
        uint256 totalClaimable = validatorReward.getClaimableRewards(validator1);
        assertEq(totalClaimable, 1000 * RAY + 1000 * RAY, "Validator1 total from both L2s");

        // Verify rewardPerValidator per L2
        assertEq(validatorReward.rewardPerValidator(systemConfig1), 1000 * RAY, "rewardPerValidator L2_1");
        assertEq(validatorReward.rewardPerValidator(systemConfig2), 1000 * RAY, "rewardPerValidator L2_2");
        assertEq(validatorReward.getClaimableRewards(validator2), 1000 * RAY, "V2 from L2_2");
    }

    /// @notice VR-009: 0 금액 분배 시 무시
    function test_VR009_distributeL2Rewards_zeroAmount() public {
        mockRat.addValidator(systemConfig1, validator1);

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, 0);

        // V1.1: O(1) 분배에서는 getClaimableRewards 사용
        assertEq(validatorReward.getClaimableRewards(validator1), 0, "No reward for 0 amount");
    }

    /// @notice VR-010: SeigManager만 호출 가능
    function test_VR010_distributeL2Rewards_onlySeigManager() public {
        mockRat.addValidator(systemConfig1, validator1);

        vm.prank(validator1);
        vm.expectRevert(abi.encodeWithSignature("NotSeigManagerError()"));
        validatorReward.distributeL2Rewards(systemConfig1, 1000 * RAY);
    }

    /// @notice VR-011: 연속 분배 테스트 (보상 누적)
    /// @dev V1.1: O(1) 분배에서는 getClaimableRewards 사용
    function test_VR011_distributeL2Rewards_accumulation() public {
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

        // V1.1: O(1) 분배에서는 getClaimableRewards 사용
        assertEq(validatorReward.getClaimableRewards(validator1), 1750 * RAY, "Rewards should accumulate");
    }

    /// @notice VR-012: 소수점 분배 시 나머지 처리 (버림)
    /// @dev V1.1: O(1) 분배에서는 getClaimableRewards 사용
    function test_VR012_distributeL2Rewards_remainder() public {
        // Setup: 3 validators
        mockRat.addValidator(systemConfig1, validator1);
        mockRat.addValidator(systemConfig1, validator2);
        mockRat.addValidator(systemConfig1, validator3);

        // 1000 / 3 = 333.33... (remainder exists)
        uint256 rewardAmount = 1000 * RAY;

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, rewardAmount);

        // V1.1: O(1) 분배에서는 getClaimableRewards 사용
        uint256 perValidator = rewardAmount / 3;
        assertEq(validatorReward.getClaimableRewards(validator1), perValidator, "Validator1 reward");
        assertEq(validatorReward.getClaimableRewards(validator2), perValidator, "Validator2 reward");
        assertEq(validatorReward.getClaimableRewards(validator3), perValidator, "Validator3 reward");

        // Note: Remainder (1 RAY) stays in contract
    }

    // ==========================================
    // claimAllRewards Tests
    // ==========================================

    /// @notice 보상 청구 성공
    function test_VR004_claimAllRewards_success() public {
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

    /// @notice VR-013: 보상 없을 때 청구 실패
    function test_VR013_claimAllRewards_noRewards_reverts() public {
        vm.prank(validator1);
        vm.expectRevert(abi.encodeWithSignature("NoRewardsError()"));
        validatorReward.claimAllRewards();
    }

    /// @notice VR-014: 여러 L2 보상 한번에 청구
    function test_VR014_claimAllRewards_multipleL2s() public {
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

    /// @notice VR-015: 부분 청구 후 추가 분배 및 재청구
    /// @dev V1.1: O(1) 분배에서는 getClaimableRewards 사용
    function test_VR015_claimAllRewards_claimDistributeClaim() public {
        mockRat.addValidator(systemConfig1, validator1);

        // First distribution and claim
        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, 1000 * RAY);

        vm.prank(validator1);
        validatorReward.claimAllRewards();

        assertEq(validatorReward.getClaimableRewards(validator1), 0, "Claimable should be 0 after first claim");

        // Second distribution
        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, 500 * RAY);

        // V1.1: O(1) 분배에서는 getClaimableRewards 사용
        assertEq(validatorReward.getClaimableRewards(validator1), 500 * RAY, "New claimable rewards");

        // Second claim
        uint256 balanceBefore = wton.balanceOf(validator1);

        vm.prank(validator1);
        validatorReward.claimAllRewards();

        uint256 balanceAfter = wton.balanceOf(validator1);
        assertEq(balanceAfter - balanceBefore, 500 * RAY, "Should receive second batch");
    }

    /// @notice VR-035: claimRewardsByL2s - 특정 L2만 청구
    /// @dev 가스 최적화를 위한 배치 청구 기능 테스트
    function test_VR035_claimRewardsByL2s_specificL2s() public {
        // Setup validator on 3 L2s
        mockRat.addValidator(systemConfig1, validator1);
        mockRat.addValidator(systemConfig2, validator1);
        address systemConfig3 = address(0x3333);
        mockRat.addValidator(systemConfig3, validator1);

        // Distribute rewards to all 3 L2s
        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, 1000 * RAY);

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig2, 2000 * RAY);

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig3, 3000 * RAY);

        // Claim from only 2 L2s
        address[] memory l2sToClaim = new address[](2);
        l2sToClaim[0] = systemConfig1;
        l2sToClaim[1] = systemConfig2;

        uint256 balanceBefore = wton.balanceOf(validator1);

        vm.prank(validator1);
        validatorReward.claimRewardsByL2s(l2sToClaim);

        uint256 balanceAfter = wton.balanceOf(validator1);

        // Should receive rewards from L2_1 + L2_2 = 3000 RAY
        assertEq(balanceAfter - balanceBefore, 3000 * RAY, "Should receive rewards from specified L2s only");

        // L2_3 rewards should still be claimable
        assertEq(validatorReward.getClaimableRewards(validator1), 3000 * RAY, "L2_3 rewards should remain");
    }

    /// @notice VR-036: claimRewardsByL2s - 배치 청구 후 나머지 청구
    function test_VR036_claimRewardsByL2s_batchThenRemainder() public {
        mockRat.addValidator(systemConfig1, validator1);
        mockRat.addValidator(systemConfig2, validator1);

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, 1000 * RAY);

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig2, 2000 * RAY);

        // First batch: claim L2_1 only
        address[] memory batch1 = new address[](1);
        batch1[0] = systemConfig1;

        vm.prank(validator1);
        validatorReward.claimRewardsByL2s(batch1);

        // Second batch: claim L2_2
        address[] memory batch2 = new address[](1);
        batch2[0] = systemConfig2;

        uint256 balanceBefore = wton.balanceOf(validator1);

        vm.prank(validator1);
        validatorReward.claimRewardsByL2s(batch2);

        uint256 balanceAfter = wton.balanceOf(validator1);

        assertEq(balanceAfter - balanceBefore, 2000 * RAY, "Should receive L2_2 rewards");
        assertEq(validatorReward.getClaimableRewards(validator1), 0, "All rewards should be claimed");
    }

    /// @notice VR-037: claimRewardsByL2s - 미등록 L2 포함 시 스킵
    function test_VR037_claimRewardsByL2s_skipsUnregisteredL2() public {
        mockRat.addValidator(systemConfig1, validator1);

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, 1000 * RAY);

        // Try to claim from registered + unregistered L2
        address[] memory l2sToClaim = new address[](2);
        l2sToClaim[0] = systemConfig1;
        l2sToClaim[1] = address(0x9999); // unregistered

        uint256 balanceBefore = wton.balanceOf(validator1);

        vm.prank(validator1);
        validatorReward.claimRewardsByL2s(l2sToClaim);

        uint256 balanceAfter = wton.balanceOf(validator1);

        // Should only receive from registered L2
        assertEq(balanceAfter - balanceBefore, 1000 * RAY, "Should receive from registered L2 only");
    }

    // ==========================================
    // getPendingRewards Tests
    // ==========================================

    /// @notice VR-016: 미청구 보상 조회
    /// @dev V1.1: O(1) 분배에서는 getClaimableRewards 사용
    function test_VR016_getPendingRewards_accurate() public {
        mockRat.addValidator(systemConfig1, validator1);

        assertEq(validatorReward.getClaimableRewards(validator1), 0, "Initial claimable should be 0");

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, 1000 * RAY);

        // V1.1: O(1) 분배에서는 getClaimableRewards 사용
        assertEq(validatorReward.getClaimableRewards(validator1), 1000 * RAY, "Claimable after distribution");
    }

    /// @notice VR-017: L2별 미청구 보상 조회
    /// @dev V1.1: O(1) 분배에서는 rewardPerValidator 확인
    function test_VR017_getPendingRewardsByL2_accurate() public {
        mockRat.addValidator(systemConfig1, validator1);
        mockRat.addValidator(systemConfig2, validator1);

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, 1000 * RAY);

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig2, 2000 * RAY);

        // V1.1: O(1) 분배에서는 rewardPerValidator 확인 (L2별 누적 보상)
        assertEq(validatorReward.rewardPerValidator(systemConfig1), 1000 * RAY, "L2_1 rewardPerValidator");
        assertEq(validatorReward.rewardPerValidator(systemConfig2), 2000 * RAY, "L2_2 rewardPerValidator");
        // 총 청구 가능 금액 확인
        assertEq(validatorReward.getClaimableRewards(validator1), 3000 * RAY, "Total claimable");
    }

    // ==========================================
    // Reward Calculation Tests
    // ==========================================

    /// @notice VR-018: 공식 검증: v_j = (α · S_i) / |V_i|
    /// @dev α는 SeigManager에서 적용되므로 여기서는 amount / activeCount 검증
    /// @dev V1.1: O(1) 분배에서는 getClaimableRewards 사용
    function test_VR018_rewardCalculation_formula() public {
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

        // V1.1: O(1) 분배에서는 getClaimableRewards 사용
        assertEq(validatorReward.getClaimableRewards(validator1), expectedPerValidator, "Formula check");
        assertEq(validatorReward.getClaimableRewards(validator2), expectedPerValidator, "Formula check");
        assertEq(validatorReward.getClaimableRewards(validator3), expectedPerValidator, "Formula check");
    }

    /// @notice VR-019: 정밀도 테스트 (작은 금액)
    /// @dev V1.1: O(1) 분배에서는 getClaimableRewards 사용
    function test_VR019_rewardCalculation_precision() public {
        mockRat.addValidator(systemConfig1, validator1);
        mockRat.addValidator(systemConfig1, validator2);

        // Very small amount
        uint256 smallAmount = 3; // 3 wei (not 3 RAY)

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, smallAmount);

        // 3 / 2 = 1 per validator (integer division)
        // V1.1: O(1) 분배에서는 getClaimableRewards 사용
        assertEq(validatorReward.getClaimableRewards(validator1), 1, "Small amount precision");
        assertEq(validatorReward.getClaimableRewards(validator2), 1, "Small amount precision");
    }

    // ==========================================
    // Governance Tests
    // ==========================================

    /// @notice VR-020: RAT 컨트랙트 설정
    function test_VR020_setRatContract() public {
        address newRat = address(0x999);

        validatorReward.setRatContract(newRat);
        assertEq(validatorReward.ratContract(), newRat, "RAT should be updated");
    }

    /// @notice VR-021: RAT 컨트랙트 설정 - 0 주소 실패
    function test_VR021_setRatContract_zeroAddress_reverts() public {
        vm.expectRevert(abi.encodeWithSignature("ZeroAddressError()"));
        validatorReward.setRatContract(address(0));
    }

    /// @notice VR-022: Treasury 설정 - DEPRECATED
    /// @dev treasury는 더 이상 사용되지 않음, SeigManager.dao() 사용
    function test_VR022_setTreasury_deprecated_reverts() public {
        vm.expectRevert("deprecated: use SeigManager.dao()");
        validatorReward.setTreasury(address(0x888));
    }

    /// @notice VR-023: SeigManager 설정
    function test_VR023_setSeigManager() public {
        address newSeigManager = address(0x777);

        validatorReward.setSeigManager(newSeigManager);
        assertEq(validatorReward.seigManager(), newSeigManager, "SeigManager should be updated");
    }

    /// @notice VR-024: SeigManager 설정 - 0 주소 실패
    function test_VR024_setSeigManager_zeroAddress_reverts() public {
        vm.expectRevert(abi.encodeWithSignature("ZeroAddressError()"));
        validatorReward.setSeigManager(address(0));
    }

    /// @notice VR-025: 소유권 이전
    function test_VR025_transferOwnership() public {
        address newOwner = address(0x666);

        validatorReward.transferOwnership(newOwner);
        assertEq(validatorReward.owner(), newOwner, "Owner should be transferred");
    }

    /// @notice VR-026: 소유권 이전 - 0 주소 실패
    function test_VR026_transferOwnership_zeroAddress_reverts() public {
        vm.expectRevert("zero address");
        validatorReward.transferOwnership(address(0));
    }

    /// @notice VR-027: 비소유자 거버넌스 함수 호출 실패
    function test_VR027_governance_onlyOwner() public {
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

    /// @notice VR-028: 비상 출금 테스트
    function test_VR028_emergencyWithdraw() public {
        uint256 contractBalance = wton.balanceOf(address(validatorReward));
        uint256 ownerBefore = wton.balanceOf(owner);

        validatorReward.emergencyWithdraw(address(wton), contractBalance);

        assertEq(wton.balanceOf(owner), ownerBefore + contractBalance, "Owner should receive tokens");
        assertEq(wton.balanceOf(address(validatorReward)), 0, "Contract should be empty");
    }

    /// @notice VR-029: 비상 출금 - 비소유자 실패
    function test_VR029_emergencyWithdraw_onlyOwner() public {
        vm.prank(validator1);
        vm.expectRevert("not owner");
        validatorReward.emergencyWithdraw(address(wton), 100 * RAY);
    }

    // ==========================================
    // Event Tests
    // ==========================================

    /// @notice VR-030: L2RewardDistributed 이벤트
    function test_VR030_event_L2RewardDistributed() public {
        mockRat.addValidator(systemConfig1, validator1);
        mockRat.addValidator(systemConfig1, validator2);

        uint256 rewardAmount = 2000 * RAY;

        vm.expectEmit(true, false, false, true);
        emit L2RewardDistributed(systemConfig1, rewardAmount, 2, rewardAmount / 2);

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, rewardAmount);
    }

    /// @notice VR-031: ValidatorRewardReceived 이벤트
    /// @dev V1.1: O(1) 분배에서는 claimAllRewards 호출 시 동기화되면서 이벤트 발생
    function test_VR031_event_ValidatorRewardReceived() public {
        mockRat.addValidator(systemConfig1, validator1);

        uint256 rewardAmount = 1000 * RAY;

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, rewardAmount);

        // V1.1: O(1) 분배에서는 claimAllRewards 호출 시 동기화되면서 이벤트 발생
        vm.expectEmit(true, true, false, true);
        emit ValidatorRewardReceived(validator1, systemConfig1, rewardAmount);

        vm.prank(validator1);
        validatorReward.claimAllRewards();
    }

    /// @notice VR-032: RewardsClaimed 이벤트
    function test_VR032_event_RewardsClaimed() public {
        mockRat.addValidator(systemConfig1, validator1);

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, 1000 * RAY);

        // V1.1: O(1) 분배에서는 claimAllRewards가 동기화 후 청구하므로 이벤트 순서 확인
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(validator1, 1000 * RAY);

        vm.prank(validator1);
        validatorReward.claimAllRewards();
    }

    /// @notice VR-033: RewardToDAO 이벤트
    function test_VR033_event_RewardToDAO() public {
        uint256 rewardAmount = 1000 * RAY;

        vm.expectEmit(true, false, false, true);
        emit RewardToDAO(systemConfig1, rewardAmount);

        vm.prank(seigManager);
        validatorReward.distributeL2Rewards(systemConfig1, rewardAmount);
    }
}
