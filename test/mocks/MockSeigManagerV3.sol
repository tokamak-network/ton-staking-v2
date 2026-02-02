// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title MockSeigManagerV3
 * @notice Simplified mock of SeigManager V3 for local testing
 * @dev Simulates key V3 functions:
 *      - checkCurrentEligibility
 *      - estimateL2Seigniorage
 *      - updateSeigniorage
 */
contract MockSeigManagerV3 {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 public constant RAY = 1e27;

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    IERC20 public ton;
    IERC20 public wton;
    address public layer2Manager;
    address public depositManager;

    // V3 parameters
    uint256 public minStakingRatio = 0.1e27; // 10% of Bridged TON
    uint256 public seigPerBlock = 3.92e18; // 3.92 TON per block
    uint256 public lastSeigBlock;
    uint256 public daoDistributionRatio = 0.2e27; // 20% to DAO
    uint256 public validatorDistributionRatio = 0.2e27; // 20% to validators

    // L2 tracking
    mapping(address => Layer2Info) public layer2Infos;
    address[] public layer2List;

    struct Layer2Info {
        bool isRegistered;
        uint256 bridgedTON; // B_i
        uint256 stakedTON; // S_i (sequencer stake)
        address operatorManager;
        uint256 pendingSeigniorage;
    }

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event Layer2Registered(address indexed layer2, address indexed operatorManager);
    event BridgedTONUpdated(address indexed layer2, uint256 amount);
    event StakedTONUpdated(address indexed layer2, uint256 amount);
    event SeigniorageDistributed(address indexed layer2, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _ton, address _wton) {
        ton = IERC20(_ton);
        wton = IERC20(_wton);
        lastSeigBlock = block.number;
    }

    /*//////////////////////////////////////////////////////////////
                           SETUP FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setLayer2Manager(address _layer2Manager) external {
        layer2Manager = _layer2Manager;
    }

    function setDepositManager(address _depositManager) external {
        depositManager = _depositManager;
    }

    function setMinStakingRatio(uint256 _ratio) external {
        minStakingRatio = _ratio;
    }

    /*//////////////////////////////////////////////////////////////
                        L2 REGISTRATION FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Register a Layer2 (called by Layer2Manager)
     */
    function registerLayer2(address layer2, address operatorManager) external {
        require(!layer2Infos[layer2].isRegistered, "Already registered");

        layer2Infos[layer2] = Layer2Info({
            isRegistered: true,
            bridgedTON: 0,
            stakedTON: 0,
            operatorManager: operatorManager,
            pendingSeigniorage: 0
        });

        layer2List.push(layer2);

        emit Layer2Registered(layer2, operatorManager);
    }

    /**
     * @notice Update bridged TON for L2 (simulates bridge activity)
     */
    function updateBridgedTON(address layer2, uint256 amount) external {
        require(layer2Infos[layer2].isRegistered, "Not registered");
        layer2Infos[layer2].bridgedTON = amount;
        emit BridgedTONUpdated(layer2, amount);
    }

    /**
     * @notice Update staked TON for L2 (sequencer stake)
     */
    function updateStakedTON(address layer2, uint256 amount) external {
        require(layer2Infos[layer2].isRegistered, "Not registered");
        layer2Infos[layer2].stakedTON = amount;
        emit StakedTONUpdated(layer2, amount);
    }

    /*//////////////////////////////////////////////////////////////
                        V3 VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Check if L2 meets eligibility requirements
     * @dev Eligibility: S_i >= theta * B_i
     */
    function checkCurrentEligibility(
        address layer2
    ) external view returns (bool eligible, uint256 requiredStake, uint256 currentStake) {
        Layer2Info storage info = layer2Infos[layer2];

        if (!info.isRegistered) {
            return (false, 0, 0);
        }

        currentStake = info.stakedTON;
        requiredStake = (info.bridgedTON * minStakingRatio) / RAY;
        eligible = currentStake >= requiredStake;
    }

    /**
     * @notice Estimate seigniorage for L2
     * @dev Returns (sequencerReward, validatorReward)
     */
    function estimateL2Seigniorage(
        address layer2
    ) external view returns (uint256 sequencerReward, uint256 validatorReward) {
        Layer2Info storage info = layer2Infos[layer2];

        if (!info.isRegistered || info.bridgedTON == 0) {
            return (0, 0);
        }

        // Calculate total bridged TON across all L2s
        uint256 totalBridgedTON = _getTotalBridgedTON();
        if (totalBridgedTON == 0) {
            return (0, 0);
        }

        // Calculate blocks since last distribution
        uint256 blocksPassed = block.number - lastSeigBlock;
        uint256 totalSeigniorage = blocksPassed * seigPerBlock;

        // L2's share based on bridged TON ratio
        uint256 l2Share = (totalSeigniorage * info.bridgedTON) / totalBridgedTON;

        // After DAO cut
        uint256 afterDao = (l2Share * (RAY - daoDistributionRatio)) / RAY;

        // Split between sequencer and validators
        validatorReward = (afterDao * validatorDistributionRatio) / RAY;
        sequencerReward = afterDao - validatorReward;

        // Convert to WTON (RAY units)
        sequencerReward = sequencerReward * 1e9; // TON (18 dec) to WTON (27 dec)
        validatorReward = validatorReward * 1e9;
    }

    /**
     * @notice Get sequencer's staked amount
     */
    function getSequencerStaked(address layer2) external view returns (uint256) {
        return layer2Infos[layer2].stakedTON;
    }

    /**
     * @notice Get effective bridged TON (0 if not eligible)
     */
    function getEffectiveBridgedTon(address layer2) external view returns (uint256) {
        Layer2Info storage info = layer2Infos[layer2];

        uint256 requiredStake = (info.bridgedTON * minStakingRatio) / RAY;
        if (info.stakedTON >= requiredStake) {
            return info.bridgedTON;
        }
        return 0;
    }

    /*//////////////////////////////////////////////////////////////
                     SEIGNIORAGE DISTRIBUTION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Trigger seigniorage distribution (simplified)
     * @dev In real V3, this is more complex with updateSeigniorage
     */
    function distributeSeigniorage() external {
        uint256 blocksPassed = block.number - lastSeigBlock;
        if (blocksPassed == 0) return;

        uint256 totalSeigniorage = blocksPassed * seigPerBlock;
        uint256 totalBridgedTON = _getTotalBridgedTON();

        if (totalBridgedTON == 0) {
            lastSeigBlock = block.number;
            return;
        }

        // Distribute to each L2
        for (uint256 i = 0; i < layer2List.length; i++) {
            address layer2 = layer2List[i];
            Layer2Info storage info = layer2Infos[layer2];

            if (!info.isRegistered || info.bridgedTON == 0) continue;

            // Check eligibility
            uint256 requiredStake = (info.bridgedTON * minStakingRatio) / RAY;
            if (info.stakedTON < requiredStake) continue;

            // Calculate L2's share
            uint256 l2Share = (totalSeigniorage * info.bridgedTON) / totalBridgedTON;

            // After DAO cut
            uint256 afterDao = (l2Share * (RAY - daoDistributionRatio)) / RAY;

            // Sequencer reward (after validator cut)
            uint256 sequencerReward = (afterDao * (RAY - validatorDistributionRatio)) / RAY;

            // Convert to WTON and add to pending
            info.pendingSeigniorage += sequencerReward * 1e9;

            emit SeigniorageDistributed(layer2, sequencerReward * 1e9);
        }

        lastSeigBlock = block.number;
    }

    /**
     * @notice Claim seigniorage for an L2's OperatorManager
     */
    function claimSeigniorage(address layer2) external returns (uint256) {
        Layer2Info storage info = layer2Infos[layer2];
        require(info.isRegistered, "Not registered");

        uint256 amount = info.pendingSeigniorage;
        if (amount == 0) return 0;

        info.pendingSeigniorage = 0;

        // Transfer WTON to OperatorManager
        wton.transfer(info.operatorManager, amount);

        return amount;
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _getTotalBridgedTON() internal view returns (uint256 total) {
        for (uint256 i = 0; i < layer2List.length; i++) {
            Layer2Info storage info = layer2Infos[layer2List[i]];
            if (info.isRegistered) {
                // Only count eligible L2s
                uint256 requiredStake = (info.bridgedTON * minStakingRatio) / RAY;
                if (info.stakedTON >= requiredStake) {
                    total += info.bridgedTON;
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getLayer2List() external view returns (address[] memory) {
        return layer2List;
    }

    function getLayer2Info(address layer2) external view returns (Layer2Info memory) {
        return layer2Infos[layer2];
    }
}
