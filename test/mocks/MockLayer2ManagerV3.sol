// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MockOperatorManagerV3} from "./MockOperatorManagerV3.sol";

/**
 * @title MockLayer2ManagerV3
 * @notice Simplified mock of Layer2Manager V3 for local testing
 * @dev Handles L2 registration and OperatorManager creation
 */
contract MockLayer2ManagerV3 {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    IERC20 public ton;
    IERC20 public wton;
    address public seigManager;
    address public depositManager;

    // L2 tracking
    mapping(address => Layer2Data) public layer2Data;
    address[] public registeredLayer2s;

    struct Layer2Data {
        bool isRegistered;
        address operator; // Sequencer address
        address operatorManager;
        uint256 registeredAt;
    }

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event Layer2Registered(
        address indexed layer2,
        address indexed operator,
        address indexed operatorManager
    );
    event SeigniorageTransferred(
        address indexed layer2,
        address indexed operatorManager,
        uint256 amount
    );

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _ton, address _wton) {
        ton = IERC20(_ton);
        wton = IERC20(_wton);
    }

    /*//////////////////////////////////////////////////////////////
                           SETUP FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setSeigManager(address _seigManager) external {
        seigManager = _seigManager;
    }

    function setDepositManager(address _depositManager) external {
        depositManager = _depositManager;
    }

    /*//////////////////////////////////////////////////////////////
                        L2 REGISTRATION FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Register a new Layer2 with automatic OperatorManager creation
     * @param layer2 The Layer2 contract address
     * @param operator The sequencer/operator address
     */
    function registerLayer2(address layer2, address operator) external returns (address operatorManager) {
        require(!layer2Data[layer2].isRegistered, "Already registered");
        require(layer2 != address(0), "Invalid layer2");
        require(operator != address(0), "Invalid operator");

        // Create OperatorManager for this L2
        operatorManager = address(new MockOperatorManagerV3(
            operator,
            address(wton),
            address(this),
            layer2
        ));

        // Register in Layer2Manager
        layer2Data[layer2] = Layer2Data({
            isRegistered: true,
            operator: operator,
            operatorManager: operatorManager,
            registeredAt: block.timestamp
        });

        registeredLayer2s.push(layer2);

        // Register in SeigManager if set
        if (seigManager != address(0)) {
            (bool success, ) = seigManager.call(
                abi.encodeWithSignature(
                    "registerLayer2(address,address)",
                    layer2,
                    operatorManager
                )
            );
            require(success, "SeigManager registration failed");
        }

        emit Layer2Registered(layer2, operator, operatorManager);
    }

    /**
     * @notice Transfer seigniorage to L2's OperatorManager
     * @dev Called by SeigManager when distributing rewards
     */
    function transferL2Seigniorage(address layer2, uint256 amount) external {
        require(msg.sender == seigManager, "Only SeigManager");
        Layer2Data storage data = layer2Data[layer2];
        require(data.isRegistered, "Not registered");

        if (amount > 0) {
            wton.transfer(data.operatorManager, amount);
            emit SeigniorageTransferred(layer2, data.operatorManager, amount);
        }
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getOperatorManager(address layer2) external view returns (address) {
        return layer2Data[layer2].operatorManager;
    }

    function getOperator(address layer2) external view returns (address) {
        return layer2Data[layer2].operator;
    }

    function isRegistered(address layer2) external view returns (bool) {
        return layer2Data[layer2].isRegistered;
    }

    function getRegisteredLayer2s() external view returns (address[] memory) {
        return registeredLayer2s;
    }

    function getLayer2Data(address layer2) external view returns (Layer2Data memory) {
        return layer2Data[layer2];
    }

    /**
     * @notice Get Layer2 by operator address
     */
    function getLayer2ByOperator(address operator) external view returns (address) {
        for (uint256 i = 0; i < registeredLayer2s.length; i++) {
            if (layer2Data[registeredLayer2s[i]].operator == operator) {
                return registeredLayer2s[i];
            }
        }
        return address(0);
    }
}
