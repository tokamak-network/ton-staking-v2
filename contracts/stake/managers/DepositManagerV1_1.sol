// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IWTON } from "../../dao/interfaces/IWTON.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../proxy/ProxyStorage.sol";
import { AccessibleCommon } from "../../common/AccessibleCommon.sol";
import { DepositManagerStorage } from "./DepositManagerStorage.sol";
import { DepositManagerV1_1Storage } from "./DepositManagerV1_1Storage.sol";

// error ZeroPortalError();
/**
 * @notice Error that occurs when there is a problem as a result of L2 bridge-related information search
 * @param x 1: checkL1Bridge function call error
 *          2: validity result false in checkL1Bridge function
 *          3: zero L1 bridge address
 *          4: zero optimism portal address
 */
error CheckL1BridgeError(uint x);
error OperatorError();
error WithdrawError();
error SwapTonTransferError();
error ZeroValueError();

interface ILayer2 {
  function operator() external view returns (address);
}

interface ISeigManager {
  function stakeOf(address layer2, address account) external view returns (uint256);
  function onWithdraw(address layer2, address account, uint256 amount) external returns (bool);
}

// interface IOperator {
//   function checkL1Bridge() external view returns (bool result, address l1Bridge, address l2Ton);
// }

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

  address internal constant LEGACY_ERC20_NATIVE_TOKEN = 0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000;
  bytes4 internal constant SELECTOR_CHECK_L1_BRIDGE = 0x632b03ad; //checkL1Bridge()
  bytes4 internal constant SELECTOR_ON_WITHDRAW = 0xf850ffaa; //onWithdraw(address,address,uint256)
  bytes4 internal constant SELECTOR_SWAP_TOON_AND_TRANSFER = 0xe3b99e85; //swapToTONAndTransfer(address,uint256)

  ////////////////////
  // Events
  ////////////////////

  /**
   * @notice Event that occurs when calling the withdrawAndDepositL2 function
   * @param layer2    The layer2 address
   * @param account   The account address
   * @param amount    The amount of withdrawal and deposit L2
   */
  event WithdrawalAndDeposited(address indexed layer2, address account, uint256 amount);

  function setMinDepositGasLimit(uint32 gasLimit_) external onlyOwner {
    minDepositGasLimit = gasLimit_;
  }

  /**
   * @notice Withdrawal from L1 and deposit to L2
   * @param layer2    The layer2 address
   * @param amount    The amount to be withdrawal and deposit L2. ()`amount` WTON in RAY)
   */
  function withdrawAndDepositL2(address layer2, uint256 amount) external ifFree returns (bool) {
    if (amount == 0) revert ZeroValueError();
    address _seig = _seigManager;
    require(ISeigManager(_seig).stakeOf(layer2, msg.sender) >= amount, 'staked amount is insufficient');

    address operator = ILayer2(layer2).operator();
    if (operator == address(0)) revert OperatorError();
    if (operator.code.length == 0) revert OperatorError();

    // require(operator.code.length != 0, 'not operator contract');
    // (bool success, bytes memory data) = operator.call(abi.encodeWithSelector(IOperator.checkL1Bridge.selector));

    (bool success, bytes memory data) = operator.call(abi.encode(SELECTOR_CHECK_L1_BRIDGE));
    if (!success) revert CheckL1BridgeError(1);

    // require(success, 'false checkL1Bridge');
    (bool result, address l1Bridge, address portal, address l2Ton) = abi.decode(data, (bool,address,address,address));
    if (!result) revert CheckL1BridgeError(2);
    if (l1Bridge == address(0)) revert CheckL1BridgeError(3);

    uint32 _minDepositGasLimit = 0;
    if (l2Ton != LEGACY_ERC20_NATIVE_TOKEN) _minDepositGasLimit = 210000; // minDepositGasLimit check
    else if (portal == address(0)) revert CheckL1BridgeError(4);

    if (!ISeigManager(_seig).onWithdraw(layer2, msg.sender, amount)) revert WithdrawError();
    if (!IWTON(_wton).swapToTONAndTransfer(address(this), amount)) revert SwapTonTransferError();

    if (ton == address(0)) ton = IIERC20(_wton).ton();
    address _ton = ton;
    uint256 tonAmount = amount/1e9;
    uint256 allowance = IERC20(_ton).allowance(address(this), l1Bridge);
    if(allowance < tonAmount) IIERC20(_ton).increaseAllowance(l1Bridge, tonAmount-allowance);

    address checkAddress = l1Bridge;
    if (portal != address(0)) checkAddress = portal;
    uint256 bal = IERC20(_ton).balanceOf(checkAddress);

    IL1Bridge(l1Bridge).depositERC20To(
      _ton,
      l2Ton,
      msg.sender,
      tonAmount,
      _minDepositGasLimit,
      '0x'
    );

    require(IERC20(_ton).balanceOf(checkAddress) == bal + tonAmount, "fail depositERC20To");

    emit WithdrawalAndDeposited(layer2, msg.sender, amount);
    return true;
  }

}
