// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title MockOperatorManagerV3
 * @notice Simplified mock of OperatorManager V3 for local testing
 * @dev Handles seigniorage claiming for a specific L2
 */
contract MockOperatorManagerV3 {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public operator;
    IERC20 public wton;
    address public layer2Manager;
    address public layer2;

    // Authorized claimers (DelegateStaking contracts)
    mapping(address => bool) public authorizedClaimers;

    // Pending rewards that can be claimed
    uint256 public pendingRewards;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event ClaimerAuthorized(address indexed claimer);
    event ClaimerRevoked(address indexed claimer);
    event RewardsReceived(uint256 amount);
    event RewardsClaimed(address indexed claimer, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _operator,
        address _wton,
        address _layer2Manager,
        address _layer2
    ) {
        operator = _operator;
        wton = IERC20(_wton);
        layer2Manager = _layer2Manager;
        layer2 = _layer2;
    }

    /*//////////////////////////////////////////////////////////////
                           AUTHORIZATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Authorize a claimer (e.g., DelegateStaking contract)
     * @param claimer Address to authorize
     */
    function authorizeClaimer(address claimer) external {
        require(msg.sender == operator, "Only operator");
        authorizedClaimers[claimer] = true;
        emit ClaimerAuthorized(claimer);
    }

    /**
     * @notice Revoke claimer authorization
     * @param claimer Address to revoke
     */
    function revokeClaimer(address claimer) external {
        require(msg.sender == operator, "Only operator");
        authorizedClaimers[claimer] = false;
        emit ClaimerRevoked(claimer);
    }

    /*//////////////////////////////////////////////////////////////
                           REWARD FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Receive WTON rewards (called when tokens are transferred)
     * @dev Updates pending rewards based on balance increase
     */
    function notifyRewardAmount(uint256 amount) external {
        pendingRewards += amount;
        emit RewardsReceived(amount);
    }

    /**
     * @notice Claim pending rewards
     * @dev Called by authorized claimers (DelegateStaking)
     * @return amount Amount of WTON claimed
     */
    function claimRewards() external returns (uint256 amount) {
        require(authorizedClaimers[msg.sender], "Not authorized");

        amount = pendingRewards;
        if (amount > 0) {
            pendingRewards = 0;

            // Get actual balance (in case tokens were transferred directly)
            uint256 balance = wton.balanceOf(address(this));
            if (balance < amount) {
                amount = balance;
            }

            if (amount > 0) {
                wton.safeTransfer(msg.sender, amount);
                emit RewardsClaimed(msg.sender, amount);
            }
        }
    }

    /**
     * @notice Claim specific amount
     * @param claimAmount Amount to claim
     */
    function claimRewardsAmount(uint256 claimAmount) external returns (uint256) {
        require(authorizedClaimers[msg.sender], "Not authorized");
        require(claimAmount <= pendingRewards, "Insufficient pending");

        uint256 balance = wton.balanceOf(address(this));
        require(claimAmount <= balance, "Insufficient balance");

        pendingRewards -= claimAmount;
        wton.safeTransfer(msg.sender, claimAmount);

        emit RewardsClaimed(msg.sender, claimAmount);
        return claimAmount;
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get pending rewards for this OperatorManager
     */
    function getPendingRewards() external view returns (uint256) {
        return pendingRewards;
    }

    /**
     * @notice Get actual WTON balance
     */
    function getBalance() external view returns (uint256) {
        return wton.balanceOf(address(this));
    }

    /**
     * @notice Check if address is authorized claimer
     */
    function isAuthorizedClaimer(address claimer) external view returns (bool) {
        return authorizedClaimers[claimer];
    }

    /**
     * @notice Get operator address
     */
    function getOperator() external view returns (address) {
        return operator;
    }

    /**
     * @notice Check if address is the operator (required by DelegateStakingV3)
     * @param addr Address to check
     * @return True if address is the operator
     */
    function isOperator(address addr) external view returns (bool) {
        return addr == operator;
    }

    /**
     * @notice Claim ERC20 tokens (required by DelegateStakingV3._claimFromOperatorManager)
     * @param token Token address to claim
     * @param amount Amount to claim (max uint256 for all)
     */
    function claimERC20(address token, uint256 amount) external {
        // Get either pending rewards or actual balance (whichever is set)
        uint256 claimable = pendingRewards;
        uint256 balance = IERC20(token).balanceOf(address(this));

        // Use the smaller of claimable, balance, or requested amount
        uint256 claimAmount = claimable > 0 ? claimable : balance;
        if (amount < claimAmount) {
            claimAmount = amount;
        }
        if (claimAmount > balance) {
            claimAmount = balance;
        }

        if (claimAmount > 0) {
            if (pendingRewards >= claimAmount) {
                pendingRewards -= claimAmount;
            } else {
                pendingRewards = 0;
            }
            IERC20(token).safeTransfer(msg.sender, claimAmount);
            emit RewardsClaimed(msg.sender, claimAmount);
        }
    }

    /**
     * @notice Get layer2 address
     */
    function getLayer2() external view returns (address) {
        return layer2;
    }

    /*//////////////////////////////////////////////////////////////
                           MOCK HELPERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Simulate receiving seigniorage (for testing)
     * @dev Transfers WTON from sender to this contract
     */
    function mockReceiveSeigniorage(uint256 amount) external {
        wton.safeTransferFrom(msg.sender, address(this), amount);
        pendingRewards += amount;
        emit RewardsReceived(amount);
    }

    /**
     * @notice Directly set pending rewards (for testing)
     */
    function mockSetPendingRewards(uint256 amount) external {
        pendingRewards = amount;
    }
}
