// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MockProxyAdmin {
    struct AdminChange {
        address proxy;
        address newAdmin;
    }
    AdminChange[] public adminChanges;

    address private _owner;

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    constructor() {
        _owner = _msgSender();
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function _checkOwner() internal view {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        _owner = newOwner;
    }

    function changeProxyAdmin(address payable _proxy, address _newAdmin) external onlyOwner {
        adminChanges.push(AdminChange({
            proxy: _proxy,
            newAdmin: _newAdmin
        }));
    }
}
