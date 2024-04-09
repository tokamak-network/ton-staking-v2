// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IWTON } from "../../dao/interfaces/IWTON.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../proxy/ProxyStorage.sol";
import { AccessibleCommon } from "../../common/AccessibleCommon.sol";
import { DepositManagerStorage } from "./DepositManagerStorage.sol";
import { DepositManagerV1_1Storage } from "./DepositManagerV1_1Storage.sol";


interface ILayer2 {
  function operator() external view returns (address);
}

interface ISeigManager {
  function stakeOf(address layer2, address account) external view returns (uint256);
  function onWithdraw(address layer2, address account, uint256 amount) external returns (bool);
}

interface IOperator {
  function checkL1Bridge() external view returns (bool result, address l1Bridge, address l2Ton);
}

interface IL1Bridge {
  function depositERC20To(
        address _l1Token,
        address _l2Token,
        address _to,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes calldata _extraData
    ) external ;
}

interface IIWTON {
  function ton() external view returns (address) ;
}
/**
 * @dev DepositManager manages WTON deposit and withdrawal from operator and WTON holders.
 */
//ERC165
contract DepositManagerV1_1 is ProxyStorage, AccessibleCommon, DepositManagerStorage, DepositManagerV1_1Storage{
  using SafeERC20 for IERC20;

  ////////////////////
  // Events
  ////////////////////

  event WithdrawalAndDeposited(address indexed layer2, address account, uint256 amount);

  function setMinDepositGasLimit(uint256 gasLimit_) external onlyOwner {
    minDepositGasLimit = gasLimit_;
  }

  ////////////////////
  // withdrawAndDepositL2 function
  ////////////////////

  /**
   * @dev withdrawAndDepositL2 `amount` WTON in RAY
   */

  function withdrawAndDepositL2(address layer2, uint256 amount) external returns (bool) {
    require(ISeigManager(_seigManager).stakeOf(layer2, msg.sender) >= amount, 'staked amount is insufficient');

    address operator = ILayer2(layer2).operator();

    address l1Bridge;
    address l2Ton;
    try IOperator(operator).checkL1Bridge() returns (bool result, address l1Bridge_,  address l2Ton_) {
        require(result, 'Not Allowed Layer2');
        l1Bridge = l1Bridge_;
        l2Ton = l2Ton_;
    } catch (bytes memory ) {
        revert("WrongOperator");
    }

    require(ISeigManager(_seigManager).onWithdraw(layer2, msg.sender, amount));
    require(IWTON(_wton).swapToTONAndTransfer(address(this), amount));

    if (minDepositGasLimit == 0) minDepositGasLimit = 210000;
    if (ton == address(0)) ton = IIWTON(_wton).ton();

    IL1Bridge(l1Bridge).depositERC20To(
      ton,
      l2Ton,
      msg.sender,
      amount/1e9,
      21000,
      '0x'
    );

    emit WithdrawalAndDeposited(layer2, msg.sender, amount);
    return true;
  }

}
