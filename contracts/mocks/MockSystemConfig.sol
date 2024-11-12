// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface ITarget {
    function transferOwnership(address newOwner) external ;
}

contract MockL1StandardBridge {

    address public portal;

    constructor() {}
    receive() external payable {
        revert("cannot receive Ether");
    }

    function setPortal(address _addr) external {
        require(portal == address(0), "already set");
        portal = _addr;
    }

    function depositERC20To(
        address _l1Token,
        address _l2Token,
        address _to,
        uint256 _amount,
        uint32 _l2Gas,
        bytes calldata _data
    ) external {

        require(IERC20(_l1Token).transferFrom(msg.sender, address(this), _amount) , "fail transferFrom");
        require(IERC20(_l1Token).transfer(portal, _amount), "fail transfer");

    }
}

contract MockOptimismPortal is Ownable {
    constructor() {}
    receive() external payable {
        revert("cannot receive Ether");
    }

    function claim(address token, address to, uint256 amount) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }
}


contract MockSystemConfig is Ownable {

    /// @notice Struct representing the addresses of L1 system contracts. These should be the
    ///         proxies and will differ for each OP Stack chain.
    struct Addresses {
        address l1CrossDomainMessenger;
        address l1ERC721Bridge;
        address l1StandardBridge;
        address l2OutputOracle;
        address optimismPortal;
        address optimismMintableERC20Factory;
    }

    Addresses public addresses;
    string public name;

    /* ========== CONSTRUCTOR ========== */
    constructor() {

        address portal = address(new MockOptimismPortal());
        MockL1StandardBridge bridge = new MockL1StandardBridge();
        bridge.setPortal(portal);

        addresses = Addresses(
            address(0),
            address(0),
            address(bridge),
            address(0),
            portal,
            address(0)
        );
    }

    receive() external payable {
        revert("cannot receive Ether");
    }

    function setName(string calldata _name) external {
        require(bytes(name).length == 0, "already set");
        name = _name;
    }

    function setTargetOwner(address _target, address _addr) external {
        ITarget(_target).transferOwnership(_addr);
    }

    /* ========== view ========== */

    function l1CrossDomainMessenger() external view returns (address addr_) {
        addr_ = addresses.l1CrossDomainMessenger;
    }

    function l1ERC721Bridge() external view returns (address addr_) {
        addr_ = addresses.l1ERC721Bridge;
    }

    function l1StandardBridge() external view returns (address addr_) {
        addr_ = addresses.l1StandardBridge;
    }

    function l2OutputOracle() external view returns (address addr_) {
        addr_ = addresses.l2OutputOracle;
    }

    function optimismPortal() external view returns (address addr_) {
        addr_ = addresses.optimismPortal;
    }

    function optimismMintableERC20Factory() external view returns (address addr_) {
        addr_ = addresses.optimismMintableERC20Factory;
    }

}
