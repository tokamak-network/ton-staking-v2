// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../OperatorProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../libraries/Create2.sol";

import "hardhat/console.sol";

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

contract OperatorFactory is Ownable {

    address public operatorImplementation;
    address public depositManager;
    address public ton;
    address public wton;

    event ChangedOperatorImplementaion(address newOperatorImplementation);
    event CreatedOperator(address systemConfig, address owner, address manager, address operator);
    event SetAddresses(address depositManager, address ton, address wton);

    constructor(address _operatorImplementation) {
        operatorImplementation = _operatorImplementation;
    }

    function changeOperatorImplementaion(address newOperatorImplementation) external onlyOwner {
        require(newOperatorImplementation != address(0), "zero address");
        require(operatorImplementation != newOperatorImplementation, "same");

        operatorImplementation = newOperatorImplementation;
        emit ChangedOperatorImplementaion(newOperatorImplementation);
    }

    function setAddresses(address _depositManager, address _ton, address _wton) external onlyOwner {
        require(depositManager == address(0), "already set");
        require(_depositManager != address(0), "zero _depositManager");
        require(_ton != address(0), "zero _ton");
        require(_wton != address(0), "zero _wton");

        depositManager = _depositManager;
        ton = _ton;
        wton = _wton;

        emit SetAddresses(_depositManager, _ton, _wton);
    }

    /**
     * create an account, and return its address.
     * returns the address even if the account is already deployed.
     * Note that during UserOperation execution, this method is called only if the account is not deployed.
     * This method returns an existing account address so that entryPoint.getSenderAddress() would work even after account creation
     */
    function createOperator(address systemConfig) external returns (address operator) {
        address sOwner = owner();
        address sManager = ISystemConfig(systemConfig).owner();
        require(sManager != address(0), "zero config's owner");
        // require(sManager == msg.sender, "not config's owner");

        uint256 salt = 0;
        address addr = getAddress(systemConfig);

        // uint codeSize = addr.code.length;
        require(addr.code.length == 0, "already created");

        operator = address(new OperatorProxy{salt : bytes32(salt)}(systemConfig));

        IOperator(operator).upgradeTo(operatorImplementation);
        IOperator(operator).transferManager(sManager);
        IOperator(operator).addOperator(sManager);
        IOperator(operator).transferOwnership(owner());
        IOperator(operator).setAddresses(msg.sender, depositManager, ton, wton);

        emit CreatedOperator(systemConfig, sOwner, sManager, operator);
    }

    function getAddress(address systemConfig) public view returns (address) {
        uint _salt =0;
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                _salt,
                keccak256(abi.encodePacked(type(OperatorProxy).creationCode, abi.encode(systemConfig)))
            )
        );

        return address(uint160(uint(hash)));
    }

}

