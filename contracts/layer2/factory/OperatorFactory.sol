// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../OperatorProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "../../libraries/Create2.sol";

interface IOperator {
    function transferOwnership(address newOwner) external;
    function upgradeTo(address _logic) external;
}

interface ISystemConfig {
    function owner() external view returns (address);
}

contract OperatorFactory is Ownable {

    address public operatorImplementation;

    event ChangedOperatorImplementaion(address newOperatorImplementation);
    event CreatedOperator(address systemConfig, address owner, address operator);

    constructor(address _operatorImplementation) {
        operatorImplementation = _operatorImplementation;
    }

    function changeOperatorImplementaion(address newOperatorImplementation) external onlyOwner {
        require(newOperatorImplementation != address(0), "zero address");
        require(operatorImplementation != newOperatorImplementation, "same");

        operatorImplementation = newOperatorImplementation;
        emit ChangedOperatorImplementaion(newOperatorImplementation);
    }

    /**
     * create an account, and return its address.
     * returns the address even if the account is already deployed.
     * Note that during UserOperation execution, this method is called only if the account is not deployed.
     * This method returns an existing account address so that entryPoint.getSenderAddress() would work even after account creation
     */
    function createOperator(address systemConfig) external returns (address operator) {
        address owner = ISystemConfig(systemConfig).owner();
        require(owner != address(0), "zero owner");
        require(owner != msg.sender, "not a systemConfig's owner");

        uint256 salt = 0;
        address addr = getAddress(systemConfig);
        uint codeSize = addr.code.length;
        require(codeSize == 0, "already created");

        operator = address(new OperatorProxy{salt : bytes32(salt)}(systemConfig));
        IOperator(operator).upgradeTo(operatorImplementation);
        IOperator(operator).transferOwnership(owner);

        emit CreatedOperator(systemConfig, owner, operator);
    }

    /**
     * calculate the counterfactual address of this account as it would be returned by createAccount()
     */
    // function getAddress(address systemConfig) public view returns (address) {
    //     uint256 salt = 0;
    //     return Create2.computeAddress(bytes32(salt), keccak256(abi.encodePacked(
    //             type(OperatorProxy).creationCode, systemConfig
    //         )));
    // }

    function getAddress(address systemConfig) public view returns (address) {
        uint256 salt = 0;

        bytes32 deploymentAddressHash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt,
                keccak256(abi.encodePacked(type(OperatorProxy).creationCode, systemConfig))));

        return address(uint160(uint(deploymentAddressHash)));
    }

}

