// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../OperatorProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../libraries/Create2.sol";

error ZeroAddressError();
error SameVariableError();
error AlreadySetError();

interface IOperator {
    function setSystemConfig(address _systemConfig) external;
    function transferOwnership(address newOwner) external;
    function transferManager(address addr) external;
    function addOperator(address addr) external;
    function upgradeTo(address _logic) external;
    function setAddresses(address _layer2Manager, address _depositManager, address _ton, address _wton) external;
}

interface ISystemConfig {
    function owner() external view returns (address);
}

/**
 * @notice  Error in createOperator function
 * @param x 1: sender is not Layer2Manager
 *          2: zero systemConfig's owner
 *          3: already created Operator
 */
error CreateError(uint x);

contract OperatorFactory is Ownable {

    uint256 private constant CREATE_SALT = 0;
    address public operatorImplementation;
    address public depositManager;
    address public ton;
    address public wton;
    address public layer2Manager;

    /**
     * @notice Event occured when set the addresses
     * @param depositManager    the depositManager address
     * @param ton               TON address
     * @param wton              WTON
     * @param layer2Manager     the layer2Manager address
     */
    event SetAddresses(address depositManager, address ton, address wton, address layer2Manager);

    /**
     * @notice Event occured when change the operator implementaion address
     * @param newOperatorImplementation the operator implementaion address
     */
    event ChangedOperatorImplementaion(address newOperatorImplementation);

    /**
     * @notice Event occured when create the Operator Contract
     * @param systemConfig  the systemConfig address
     * @param owner         the owner address
     * @param manager       the manager address
     * @param operator      the operator address
     */
    event CreatedOperator(address systemConfig, address owner, address manager, address operator);

    constructor(address _operatorImplementation) {
        operatorImplementation = _operatorImplementation;
    }

    /**
     * @notice Change the operator implementaion address by Owner
     * @param newOperatorImplementation the operator implementaion address
     */
    function changeOperatorImplementaion(address newOperatorImplementation) external onlyOwner {
        _nonZeroAddress(newOperatorImplementation);
        if (operatorImplementation == newOperatorImplementation) revert SameVariableError();
        operatorImplementation = newOperatorImplementation;

        emit ChangedOperatorImplementaion(newOperatorImplementation);
    }

    /**
     * @notice Set the addresses by Owner
     * @param _depositManager    the depositManager address
     * @param _ton               TON address
     * @param _wton              WTON
     * @param _layer2Manager     the layer2Manager address
     */
    function setAddresses(address _depositManager, address _ton, address _wton, address _layer2Manager) external onlyOwner {

        require(_depositManager != address(0), "zero _depositManager");
        require(_ton != address(0), "zero _ton");
        require(_wton != address(0), "zero _wton");
        require(_layer2Manager != address(0), "zero _layer2Manager");

        if (depositManager != address(0)) revert AlreadySetError();

        depositManager = _depositManager;
        ton = _ton;
        wton = _wton;
        layer2Manager = _layer2Manager;

        emit SetAddresses(_depositManager, _ton, _wton, _layer2Manager);
    }

    /**
     * @notice  Create an Operator Contract, and return its address.
     *          return revert if the account is already deployed.
     *          Note. Only Layer2Manager Contract can be called.
     *          When creating the Layer2Candidate, create an Operator contract
     *          that is mapped to SystemConfig.
     * @param systemConfig  the systemConfig address
     */
    function createOperator(address systemConfig) external returns (address operator) {
        if (msg.sender != layer2Manager) revert CreateError(1);
        require(getAddress(systemConfig).code.length == 0, "already created");

        address sManager = ISystemConfig(systemConfig).owner();
        if (sManager == address(0)) revert CreateError(2);

        address sOwner = owner();
        operator = address(new OperatorProxy{salt : bytes32(CREATE_SALT)}(systemConfig));
        IOperator(operator).upgradeTo(operatorImplementation);
        IOperator(operator).transferManager(sManager);
        IOperator(operator).addOperator(sManager);
        IOperator(operator).transferOwnership(sOwner);
        IOperator(operator).setAddresses(msg.sender, depositManager, ton, wton);

        emit CreatedOperator(systemConfig, sOwner, sManager, operator);
    }

    /**
     * @notice  Returns the operator contract address matching systemConfig.
     * @param systemConfig  the systemConfig address
     */
    function getAddress(address systemConfig) public view returns (address) {

        return address(uint160(uint(keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                CREATE_SALT,
                keccak256(abi.encodePacked(type(OperatorProxy).creationCode, abi.encode(systemConfig)))
            )
        ))));
    }

    function _nonZeroAddress(address _addr) internal pure {
        if(_addr == address(0)) revert ZeroAddressError();
    }

}

