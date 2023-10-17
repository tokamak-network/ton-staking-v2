// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { AccessibleCommon } from "../common/AccessibleCommon.sol";
interface ERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract TestSeigManager is AccessibleCommon{

    address public oldDepositManager;
    address public newDepositManager;
    address public wton;

    constructor () {}

    function setAddresses(address oldDepositManager_, address newDepositManager_, address wton_) external {
        oldDepositManager = oldDepositManager_;
        newDepositManager = newDepositManager_;
        wton = wton_;
    }

    function onWithdraw(address layer2, address account, uint256 amount)
    external
    returns (bool) {
        require (msg.sender == oldDepositManager, "sender is not oldDepositManager");
        require (account == newDepositManager, "account is not newDepositManager");
        require (amount <=  ERC20(wton).balanceOf(oldDepositManager), "amount excceed oldDepositManager's balance");

        return true;
    }

}// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { AccessibleCommon } from "../common/AccessibleCommon.sol";
interface ERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract TestSeigManager is AccessibleCommon{

    address public oldDepositManager;
    address public newDepositManager;
    address public wton;

    constructor () {}

    function setAddresses(address oldDepositManager_, address newDepositManager_, address wton_) external {
        oldDepositManager = oldDepositManager_;
        newDepositManager = newDepositManager_;
        wton = wton_;
    }

    function onWithdraw(address layer2, address account, uint256 amount) external returns (bool) {
        require (msg.sender == oldDepositManager, "sender is not oldDepositManager");
        require (account == newDepositManager, "account is not newDepositManager");
        require (amount <=  ERC20(wton).balanceOf(oldDepositManager), "amount excceed oldDepositManager's balance");

        return true;
    }

}