// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "../../libraries/BytesLib.sol";

import { AccessibleCommon } from "../../common/AccessibleCommon.sol";
import "../../proxy/ProxyStorage.sol";
import "./L2PowerTonStorage.sol";

// import "hardhat/console.sol";

interface IL2DividendPoolForStos {
    function distribute(address token, uint256 amount) external ;
}

interface IUniversalStos {
    function totalSupply() external view returns (uint256 amount);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256 amount);
}

contract L2PowerTon is ProxyStorage, AccessibleCommon, L2PowerTonStorage {
    using BytesLib for bytes;
    address constant NativeTonAddress = address(0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000);

    event Distributed(address indexed token, uint256 amount);

    modifier nonZero(uint256 _val) {
        require(_val != 0, "zero value");
        _;
    }

    function initialize(
        address _l2DividendPoolForStos,
        address _universalStos
    ) external onlyOwner {
        l2DividendPoolForStos = _l2DividendPoolForStos;
        universalStos = _universalStos;
    }

    function setL2DividendPoolForStos(address _l2DividendPoolForStos) external onlyOwner {
        require(l2DividendPoolForStos != _l2DividendPoolForStos, "same");
        l2DividendPoolForStos = _l2DividendPoolForStos;
    }

    /*** Public ***/

    /// distribute the token that this contract is holding
    /// @param token token address to dividend,
    ///              if you want to distribute the native ton,
    ///              you should use token address to 0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000
    function distribute(address token) public payable {
        uint256 stosTotal = IUniversalStos(universalStos).totalSupply();
        // require(stosTotal != 0, "distribute: zero universalStos\' totalSupply");

        if (stosTotal != 0) {
            uint256 amount = 0;
            if (token != NativeTonAddress) {
                amount = IERC20(token).balanceOf(address(this));
                require (amount > 1 ether, "distribute: token balance is less than 1 ether.");
                IL2DividendPoolForStos(l2DividendPoolForStos).distribute(token, amount);
            } else {
                amount = address(this).balance;
                require (amount != 0, "distribute: zero balance");
                bytes memory callData = abi.encodeWithSelector(
                    IL2DividendPoolForStos.distribute.selector,
                    token,
                    amount);
                (bool success,) = payable(l2DividendPoolForStos).call{value:amount}(callData);
                require(success, "fail distribute");
            }
            emit Distributed(token, amount);
        }
    }

}
