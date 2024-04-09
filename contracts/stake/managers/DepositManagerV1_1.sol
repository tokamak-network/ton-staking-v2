// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IWTON } from "../../dao/interfaces/IWTON.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import "../../proxy/ProxyStorage.sol";
import { AccessibleCommon } from "../../common/AccessibleCommon.sol";
import { DepositManagerStorage } from "./DepositManagerStorage.sol";
import { DepositManagerV1_1Storage } from "./DepositManagerV1_1Storage.sol";

// import "hardhat/console.sol";

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

interface IIERC20 {
  function ton() external view returns (address) ;
  function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
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

  function setMinDepositGasLimit(uint32 gasLimit_) external onlyOwner {
    minDepositGasLimit = gasLimit_;
  }

  /**
   * @dev withdrawAndDepositL2 `amount` WTON in RAY
   */
  function withdrawAndDepositL2(address layer2, uint256 amount) external returns (bool) {
    require(ISeigManager(_seigManager).stakeOf(layer2, msg.sender) >= amount, 'staked amount is insufficient');

    address operator = ILayer2(layer2).operator();
    require(operator != address(0) && operator.code.length != 0, 'not operator contract');

    (bool success, bytes memory data) = operator.call(
            abi.encodeWithSelector(IOperator.checkL1Bridge.selector)
        );
    require(success, 'false checkL1Bridge');
    (bool result, address l1Bridge, address l2Ton) = abi.decode(data, (bool,address,address));

    require(result && l1Bridge != address(0), 'Not Allowed Layer2');

    require(ISeigManager(_seigManager).onWithdraw(layer2, msg.sender, amount));
    require(IWTON(_wton).swapToTONAndTransfer(address(this), amount));

    if (minDepositGasLimit == 0) minDepositGasLimit = 210000;
    if (ton == address(0)) ton = IIERC20(_wton).ton();

    uint256 tonAmount = amount/1e9;
    uint256 allowance = IERC20(ton).allowance(address(this), l1Bridge);
    if(allowance < tonAmount) IIERC20(ton).increaseAllowance(l1Bridge, tonAmount-allowance);
    IL1Bridge(l1Bridge).depositERC20To(
      ton,
      l2Ton,
      msg.sender,
      tonAmount,
      minDepositGasLimit,
      '0x'
    );

    emit WithdrawalAndDeposited(layer2, msg.sender, amount);
    return true;
  }

}
