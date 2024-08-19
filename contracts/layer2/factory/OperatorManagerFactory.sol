// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../OperatorManagerProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../libraries/Create2.sol";

error ZeroAddressError();
error SameVariableError();
error AlreadySetError();

interface IOperatorManager {
    function transferOwnership(address newOwner) external;
    function transferManager(address addr) external;
    function upgradeTo(address _logic) external;
    function setAddresses(address _layer2Manager, address _depositManager, address _ton, address _wton) external;
}

interface IRollupConfig {
    function owner() external view returns (address);
}

/**
 * @notice  Error in createOperatorManager function
 * @param x 1: sender is not Layer2Manager
 *          2: zero rollupConfig's owner
 *          3: already created Operator
 */
error CreateError(uint x);

contract OperatorManagerFactory is Ownable {

    uint256 private constant CREATE_SALT = 0;
    address public operatorManagerImp;
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
     * @notice Event occured when change the operatorManager implementaion address
     * @param newOperatorManagerImp the operatorManager implementaion address
     */
    event ChangedOperatorManagerImp(address newOperatorManagerImp);

    /**
     * @notice Event occured when create the OperatorManager Contract
     * @param rollupConfig      the rollupConfig address
     * @param owner             the owner address
     * @param manager           the manager address
     * @param operatorManager   the operatorManager address
     */
    event CreatedOperatorManager(address rollupConfig, address owner, address manager, address operatorManager);

    constructor(address _operatorManagerImplementation) {
        operatorManagerImp = _operatorManagerImplementation;
    }

    /**
     * @notice Change the operatorManager implementaion address by Owner
     * @param newOperatorManagerImp the operatorManager implementaion address
     */
    function changeOperatorManagerImp(address newOperatorManagerImp) external onlyOwner {
        _nonZeroAddress(newOperatorManagerImp);
        if (operatorManagerImp == newOperatorManagerImp) revert SameVariableError();
        operatorManagerImp = newOperatorManagerImp;

        emit ChangedOperatorManagerImp(newOperatorManagerImp);
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
     * @notice  Create an OperatorManager Contract, and return its address.
     *          return revert if the account is already deployed.
     *          Note. Only Layer2Manager Contract can be called.
     *          When creating the CandidateAddOn, create an OperatorManager contract
     *          that is mapped to RollupConfig.
     * @param rollupConfig  the rollupConfig address
     */
    function createOperatorManager(address rollupConfig) external returns (address operatorManager) {
        if (msg.sender != layer2Manager) revert CreateError(1);
        require(getAddress(rollupConfig).code.length == 0, "already created");

        address sManager = IRollupConfig(rollupConfig).owner();
        if (sManager == address(0)) revert CreateError(2);

        address sOwner = owner();
        operatorManager = address(new OperatorManagerProxy{salt : bytes32(CREATE_SALT)}(rollupConfig));
        IOperatorManager(operatorManager).upgradeTo(operatorManagerImp);
        IOperatorManager(operatorManager).transferManager(sManager);
        IOperatorManager(operatorManager).transferOwnership(sOwner);
        IOperatorManager(operatorManager).setAddresses(msg.sender, depositManager, ton, wton);
        emit CreatedOperatorManager(rollupConfig, sOwner, sManager, operatorManager);

    }

    /**
     * @notice  Returns the operatorManager contract address matching rollupConfig.
     * @param rollupConfig  the rollupConfig address
     */
    function getAddress(address rollupConfig) public view returns (address) {

        return address(uint160(uint(keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                CREATE_SALT,
                keccak256(abi.encodePacked(type(OperatorManagerProxy).creationCode, abi.encode(rollupConfig)))
            )
        ))));
    }

    function _nonZeroAddress(address _addr) internal pure {
        if(_addr == address(0)) revert ZeroAddressError();
    }

}

