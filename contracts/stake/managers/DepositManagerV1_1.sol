// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {ISeigManager} from '../interfaces/ISeigManager.sol';
import {ILayer2Registry} from '../../dao/interfaces/ILayer2Registry.sol';
import {ILayer2} from '../../dao/interfaces/ILayer2.sol';

import {IWTON} from '../../dao/interfaces/IWTON.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../../proxy/ProxyStorage.sol';
import {AccessibleCommon} from '../../common/AccessibleCommon.sol';
import {DepositManagerStorage} from './DepositManagerStorage.sol';
import {DepositManagerV1_1Storage} from './DepositManagerV1_1Storage.sol';

/**
 * @notice Error that occurs when there is a problem as a result of L2 bridge-related information search
 * @param x 1: checkL1Bridge function call error
 *          2: validity result false in checkL1Bridge function
 *          3: zero L1 bridge address
 *          4: zero optimism portal address
 *          5: unsupported layer2
 *          6: rejectedSeigs or rejectedL2Deposit
 */
error CheckL1BridgeError(uint x);
error OperatorError();
error WithdrawError();
error SwapTonTransferError();
error ZeroValueError();
interface IL1Bridge {
    function depositERC20To(
        address _l1Token,
        address _l2Token,
        address _to,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes calldata _extraData
    ) external;

    function bridgeNativeTokenTo(
        address _to,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes calldata _extraData
    ) external;

}

interface IIERC20 {
    function ton() external view returns (address);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
}
interface IOperator {
    function checkL1Bridge() external view returns (bool,address,address,address,uint8,uint8,bool,bool);
}

/**
 * @dev DepositManager manages WTON deposit and withdrawal from operator and WTON holders.
 */
//ERC165
contract DepositManagerV1_1 is
    ProxyStorage,
    AccessibleCommon,
    DepositManagerStorage,
    DepositManagerV1_1Storage
{
    using SafeERC20 for IERC20;

    uint256 internal constant GWEI_UNIT = 1e9;
    // address internal constant LEGACY_ERC20_NATIVE_TOKEN = 0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000;

    modifier onlyLayer2(address layer2) {
        require(ILayer2Registry(_registry).layer2s(layer2));
        _;
    }

    ////////////////////
    // Events
    ////////////////////

    event WithdrawalRequested(address indexed layer2, address depositor, uint256 amount);

    /**
     * @notice Event that occurs when calling the withdrawAndDepositL2 function
     * @param layer2    The layer2(candidate) address
     * @param account   The account address
     * @param amount    The amount of withdrawal and deposit L2
     */
    event WithdrawalAndDeposited(address indexed layer2, address account, uint256 amount);

    event DepositedERC20To(
        address l1Bridge,
        address l1Ton,
        address l2Ton,
        address caller,
        uint256 tonAmount,
        uint32 minDepositGasLimit
    );
    event SetAddresses(address l1BridgeRegistry_, address layer2Manager_);
    event SetMinDepositGasLimit(uint32 gasLimit_);

    function setMinDepositGasLimit(uint32 gasLimit_) external onlyOwner {
        minDepositGasLimit = gasLimit_;
        emit SetMinDepositGasLimit(gasLimit_);
    }

    function setAddresses(address _l1BridgeRegistry, address _layer2Manager) external onlyOwner {
        l1BridgeRegistry = _l1BridgeRegistry;
        layer2Manager = _layer2Manager;
        emit SetAddresses(_l1BridgeRegistry, _layer2Manager);
    }
    /**
     * @notice Withdrawal from L1 and deposit to L2
     * @param layer2    The layer2(candidate) address
     * @param amount    The amount to be withdrawal and deposit L2. ()`amount` WTON in RAY)
     */
    function withdrawAndDepositL2(address layer2, uint256 amount) external ifFree returns (bool) {
        if (amount == 0) revert ZeroValueError();
        address _seig = _seigManager;
        require(
            ISeigManager(_seig).stakeOf(layer2, msg.sender) >= amount,
            'staked amount is insufficient'
        );

        address operator = ILayer2(layer2).operator();
        if (operator == address(0)) revert OperatorError();
        if (operator.code.length == 0) revert OperatorError();

        if (l1BridgeRegistry == address(0))
            l1BridgeRegistry = ISeigManager(_seigManager).l1BridgeRegistry();

        // require(operator.code.length != 0, 'not operator contract');
        (bool success, bytes memory data) = operator.call(abi.encodeWithSelector(IOperator.checkL1Bridge.selector));

        if (!success) revert CheckL1BridgeError(1);

        // require(success, 'false checkL1Bridge');
        (
            bool result,
            address l1Bridge,
            address portal,
            address l2Ton,
            uint8 l2Type,
            uint8 status,
            bool rejectedSeigs,
            bool rejectedL2Deposit
        ) = abi.decode(data, (bool, address, address, address, uint8, uint8, bool, bool));
        if (!result) revert CheckL1BridgeError(2);

        if (rejectedSeigs || rejectedL2Deposit) revert CheckL1BridgeError(6);
        if (l1Bridge == address(0)) revert CheckL1BridgeError(3);
        require(l2Ton != address(0), 'l2Ton: zero address');
        if ((l2Type != 1 && l2Type != 2) || status != 1) revert CheckL1BridgeError(5);

        uint32 _minDepositGasLimit = minDepositGasLimit;
        if (_minDepositGasLimit == 0) _minDepositGasLimit = 210_000;

        if (l2Type != 1 && portal == address(0)) revert CheckL1BridgeError(4);

        if (!ISeigManager(_seig).onWithdraw(layer2, msg.sender, amount)) revert WithdrawError();
        if (!IWTON(_wton).swapToTONAndTransfer(address(this), amount))
            revert SwapTonTransferError();

        if (ton == address(0)) ton = IIERC20(_wton).ton();
        address _ton = ton;
        uint256 tonAmount = amount / GWEI_UNIT;
        uint256 allowance = IERC20(_ton).allowance(address(this), l1Bridge);

        unchecked {
            if (allowance < tonAmount) {
                IIERC20(_ton).increaseAllowance(l1Bridge, tonAmount - allowance);
            }
        }

        uint256 bal;

        if (l2Type == 2) {
            bal = IERC20(_ton).balanceOf(portal);

            IL1Bridge(l1Bridge).bridgeNativeTokenTo(
                msg.sender,
                tonAmount,
                _minDepositGasLimit,
                ''
            );

            bal = IERC20(_ton).balanceOf(portal) - bal;

        } else {

            bal = IERC20(_ton).balanceOf(l1Bridge);

            IL1Bridge(l1Bridge).depositERC20To(
                _ton,
                l2Ton,
                msg.sender,
                tonAmount,
                _minDepositGasLimit,
                ''
            );

            bal = IERC20(_ton).balanceOf(l1Bridge) - bal;
        }

        require(bal == tonAmount, 'fail depositERC20To');

        emit DepositedERC20To(l1Bridge, _ton, l2Ton, msg.sender, tonAmount, _minDepositGasLimit);
        emit WithdrawalAndDeposited(layer2, msg.sender, amount);
        return true;
    }


    function requestWithdrawal(address layer2, uint256 amount) external returns (bool) {
        return _requestWithdrawal(layer2, amount, _getDelayBlocks(layer2));
    }

    function _requestWithdrawal(address layer2, uint256 amount, uint256 delay) internal onlyLayer2(layer2) returns (bool) {
        require(amount > 0, "DepositManager: amount must not be zero");
        require(amount < type(uint128).max, "Out of range");

        // uint256 delay = globalWithdrawalDelay > withdrawalDelay[layer2] ? globalWithdrawalDelay : withdrawalDelay[layer2];
        _withdrawalRequests[layer2][msg.sender].push(WithdrawalReqeust({
        withdrawableBlockNumber: uint128(block.number + delay),
        amount: uint128(amount),
        processed: false
        }));

        _pendingUnstaked[layer2][msg.sender] = _pendingUnstaked[layer2][msg.sender] + amount;
        _pendingUnstakedLayer2[layer2] = _pendingUnstakedLayer2[layer2] + amount;
        _pendingUnstakedAccount[msg.sender] = _pendingUnstakedAccount[msg.sender] + amount;

        emit WithdrawalRequested(layer2, msg.sender, amount);

        require(ISeigManager(_seigManager).onWithdraw(layer2, msg.sender, amount));

        return true;
    }

    function _getDelayBlocks(address layer2) internal view returns (uint256){
        return  globalWithdrawalDelay > withdrawalDelay[layer2] ? globalWithdrawalDelay : withdrawalDelay[layer2];
    }
}
