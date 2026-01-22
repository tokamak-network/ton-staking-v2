// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IOnApprove } from "../interfaces/IOnApprove.sol";
import { ILayer2 } from "../../dao/interfaces/ILayer2.sol";
import { ILayer2Registry } from "../../dao/interfaces/ILayer2Registry.sol";
import { ISeigManager } from "../interfaces/ISeigManager.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IWTON } from "../../dao/interfaces/IWTON.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ProxyStorage} from "../../proxy/ProxyStorage.sol";
import { AccessibleCommon } from "../../common/AccessibleCommon.sol";
import { DepositManagerStorage } from "./DepositManagerStorage.sol";
import {DepositManagerV1_1Storage} from './DepositManagerV1_1Storage.sol';

import {IOperator} from '../../layer2/interfaces/IOperator.sol';
import {IL1Bridge} from '../../layer2/interfaces/IL1Bridge.sol';
import {ISeigManagerV3} from "../interfaces/ISeigManagerV3.sol";

interface IIERC20 {
    function ton() external view returns (address);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
}

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

struct L1BridgeInfo {
    address l1Bridge;
    address portal;
    address l2Ton;
    uint8 l2Type;
    uint32 minGasLimit;
}

/**
 * @title DepositManagerV3
 * @dev DepositManager V3 - 단일 구현체로 통합된 버전
 *      기존 DepositManager, DepositManager_setWithdrawalDelay, DepositManagerV1_1, DepositManagerV1_2 통합
 */
contract DepositManagerV3 is ProxyStorage, AccessibleCommon, DepositManagerStorage, DepositManagerV1_1Storage {
    using SafeERC20 for IERC20;
    uint256 public constant MAX_DELAY_BLOCKS =  216_000; // 60*60*24*30/12 = 216000 (1 block = 12 sec)
    uint256 internal constant GWEI_UNIT = 1e9;
    address internal constant LEGACY_ERC20_NATIVE_TOKEN = 0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000;

    ////////////////////
    // Modifiers
    ////////////////////

    modifier onlyLayer2(address layer2) {
        _onlyLayer2(layer2);
        _;
    }

    function _onlyLayer2(address layer2) internal view {
        require(ILayer2Registry(_registry).layer2s(layer2), "Caller is not a Layer2");
    }

    modifier onlySeigManager() {
        _onlySeigManager();
        _;
    }

    function _onlySeigManager() internal view {
        require(msg.sender == _seigManager, "Caller is not a SeigManager");
    }

    ////////////////////
    // Events
    ////////////////////

    event Deposited(address indexed layer2, address depositor, uint256 amount);
    event WithdrawalRequested(address indexed layer2, address depositor, uint256 amount);
    event WithdrawalProcessed(address indexed layer2, address depositor, uint256 amount);

    /**
     * @notice Event that occurs when calling the setWithdrawalDelay function
     * @param layer2              The layer2 address
     * @param withdrawalDelay_    The number of withdrawal delay blocks
     */
    event SetWithdrawalDelay(address indexed layer2, uint256 withdrawalDelay_);

    /**
     * @notice Event that occurs when calling the setWithdrawalDelayByOwner function
     * @param layer2              The layer2 address
     * @param withdrawalDelay_    The number of withdrawal delay blocks
     */
    event SetWithdrawalDelayByOwner(address indexed layer2, uint256 withdrawalDelay_);
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

    function initialize (
        address wton_,
        address registry_,
        address seigManager_,
        uint256 globalWithdrawalDelay_,
        address oldDepositManager_
    ) external {
        require(_wton == address(0), "already initialized");

        _wton = wton_;
        _registry = registry_;
        _seigManager = seigManager_;
        globalWithdrawalDelay = globalWithdrawalDelay_;
        oldDepositManager = oldDepositManager_;
        _registerInterface(IOnApprove.onApprove.selector);
    }

    ////////////////////
    // SeiManager function
    ////////////////////

    function setSeigManager(address seigManager_) external onlyOwner {
        _seigManager = seigManager_;
    }

    ////////////////////
    // ERC20 Approve callback
    ////////////////////

    function onApprove(
        address owner,
        address /* spender */,
        uint256 amount,
        bytes calldata data
    ) external returns (bool) {
        require(msg.sender == _wton, "DepositManager: only accept WTON approve callback");

        address layer2 = _decodeDepositManagerOnApproveData(data);
        require(_deposit(layer2, owner, amount, owner), "fail deposit");

        return true;
    }

    function _decodeDepositManagerOnApproveData(
        bytes memory data
    ) internal pure returns (address layer2) {
        require(data.length == 0x20, "data length error");

        assembly {
        layer2 := mload(add(data, 0x20))
        }
    }

    ////////////////////
    // Deposit function
    ////////////////////

    /**
     * @dev deposit `amount` WTON in RAY
     */

    function deposit(address layer2, uint256 amount) external returns (bool) {
        require(_deposit(layer2, msg.sender, amount, msg.sender), "fail deposit");
        return true;
    }

    function deposit(address layer2, address account, uint256 amount) external returns (bool) {
        require(_deposit(layer2, account, amount, msg.sender), "fail deposit");
        return true;
    }

    function deposit(address layer2, address[] memory accounts, uint256[] memory amounts) external returns (bool) {
        require(accounts.length != 0, 'no account');
        require(accounts.length == amounts.length, 'wrong lenth');

        for (uint256 i = 0; i < accounts.length; i++){
        require(_deposit(layer2, accounts[i], amounts[i], msg.sender), "fail deposit");
        }

        return true;
    }

    function _deposit(address layer2, address account, uint256 amount, address payer) internal onlyLayer2(layer2) returns (bool) {
        require(account != address(0) && amount != 0, "zero amount or zero address");

        // _accStaked[layer2][account] = _accStaked[layer2][account] + amount;
        // _accStakedLayer2[layer2] = _accStakedLayer2[layer2] + amount;
        // _accStakedAccount[account] = _accStakedAccount[account] + amount;

        IERC20(_wton).safeTransferFrom(payer, address(this), amount);

        emit Deposited(layer2, account, amount);

        require(ISeigManager(_seigManager).onDeposit(layer2, account, amount), "fail SeigManager.onDeposit");

        return true;
    }

    ////////////////////
    // Re-deposit function
    ////////////////////

    /**
     * @dev re-deposit pending requests in the pending queue
     */

    function redeposit(address layer2) external returns (bool) {
        uint256 i = _withdrawalRequestIndex[layer2][msg.sender];
        require(_redeposit(layer2, i, 1), "fail redeposit");
        return true;
    }

    function redepositMulti(address layer2, uint256 n) external returns (bool) {
        uint256 i = _withdrawalRequestIndex[layer2][msg.sender];
        require(_redeposit(layer2, i, n), "fail redeposit");
        return true;
    }

    function _redeposit(address layer2, uint256 i, uint256 n) internal onlyLayer2(layer2) returns (bool) {
        uint256 accAmount;

        WithdrawalReqeust[] memory requsts = _withdrawalRequests[layer2][msg.sender];

        require(requsts.length > 0, "DepositManager: no request");
        require(requsts.length - i >= n, "DepositManager: n exceeds num of pending requests");

        uint256 e = i + n;
        for (; i < e; i++) {
        // WithdrawalReqeust storage r = _withdrawalRequests[layer2][msg.sender][i];
        WithdrawalReqeust memory r = requsts[i];

        uint256 amount = r.amount;

        require(!r.processed, "DepositManager: pending request already processed");
        require(amount > 0, "DepositManager: no valid pending request");

        accAmount = accAmount + amount;
        r.processed = true;
        _withdrawalRequests[layer2][msg.sender][i] = r;
        }


        // deposit-related storages
        // _accStaked[layer2][msg.sender] = _accStaked[layer2][msg.sender] + accAmount;
        // _accStakedLayer2[layer2] = _accStakedLayer2[layer2] + accAmount;
        // _accStakedAccount[msg.sender] = _accStakedAccount[msg.sender] + accAmount;

        // withdrawal-related storages
        _pendingUnstaked[layer2][msg.sender] = _pendingUnstaked[layer2][msg.sender] - accAmount;
        _pendingUnstakedLayer2[layer2] = _pendingUnstakedLayer2[layer2] - accAmount;
        _pendingUnstakedAccount[msg.sender] = _pendingUnstakedAccount[msg.sender] - accAmount;

        _withdrawalRequestIndex[layer2][msg.sender] += n;

        emit Deposited(layer2, msg.sender, accAmount);

        require(ISeigManager(_seigManager).onDeposit(layer2, msg.sender, accAmount), "fail SeigManager.onDeposit");

        return true;
    }

    ////////////////////
    // Setter
    ////////////////////

    function setGlobalWithdrawalDelay(uint256 globalWithdrawalDelay_) external onlyOwner {
        globalWithdrawalDelay = globalWithdrawalDelay_;
    }

    /**
     * @dev The operator of that layer can set the withdrawal delay block to be greater than the global delay block or less than one month.
     * @param layer2               The layer2 address
     * @param withdrawalDelay_      The number of withdrawal delay blocks
    */
    function setWithdrawalDelay(address layer2, uint256 withdrawalDelay_) external {
        require(_isOperator(layer2, msg.sender), "Caller is not an operator");
        require(withdrawalDelay_ > globalWithdrawalDelay && withdrawalDelay_ <= MAX_DELAY_BLOCKS, "Not acceptable");

        withdrawalDelay[layer2] = withdrawalDelay_;
        emit SetWithdrawalDelay(layer2, withdrawalDelay_);
    }

    /**
     * @dev The administrator can set a withdrawal delay block.
     * @param layer2               The layer2 address
     * @param withdrawalDelay_      The number of withdrawal delay blocks
    */
    function setWithdrawalDelayByOwner(address layer2, uint256 withdrawalDelay_) external onlyOwner {
        require(withdrawalDelay_ > globalWithdrawalDelay && withdrawalDelay_ <= MAX_DELAY_BLOCKS, "Not acceptable");
        withdrawalDelay[layer2] = withdrawalDelay_;
        emit SetWithdrawalDelayByOwner(layer2, withdrawalDelay_);
    }

    ////////////////////
    // Withdrawal functions
    ////////////////////

     function requestWithdrawal(address layer2, uint256 amount) external returns (bool) {
        return _requestWithdrawal(layer2, amount, _getDelayBlocks(layer2));
    }


    function _requestWithdrawal(
        address layer2,
        uint256 amount,
        uint256 delay
    ) internal onlyLayer2(layer2) returns (bool) {
        require(amount > 0, "DepositManager: amount must not be zero");
        require(amount < type(uint128).max, "Out of range");
        require(block.number + delay < type(uint128).max, "Block number overflow");

        // forge-lint: disable-next-line(unsafe-typecast)
        // Safe: block.number + delay is validated < type(uint128).max above
        _withdrawalRequests[layer2][msg.sender].push(
            WithdrawalReqeust({
                // forge-lint: disable-next-line(unsafe-typecast)
                withdrawableBlockNumber: uint128(block.number + delay),
                // forge-lint: disable-next-line(unsafe-typecast)
                amount: uint128(amount),
                processed: false
            })
        );

        _pendingUnstaked[layer2][msg.sender] = _pendingUnstaked[layer2][msg.sender] + amount;
        _pendingUnstakedLayer2[layer2] = _pendingUnstakedLayer2[layer2] + amount;
        _pendingUnstakedAccount[msg.sender] = _pendingUnstakedAccount[msg.sender] + amount;

        emit WithdrawalRequested(layer2, msg.sender, amount);

        require(ISeigManager(_seigManager).onWithdraw(layer2, msg.sender, amount));

        return true;
    }
    function _getDelayBlocks(address layer2) internal view returns (uint256) {
        return
            globalWithdrawalDelay > withdrawalDelay[layer2]
                ? globalWithdrawalDelay
                : withdrawalDelay[layer2];
    }
    function processRequest(address layer2, bool receiveTon) external returns (bool) {
        return _processRequest(layer2, receiveTon);
    }

    function _processRequest(address layer2, bool receiveTon) internal returns (bool) {
        uint256 index = _withdrawalRequestIndex[layer2][msg.sender];
        require(_withdrawalRequests[layer2][msg.sender].length > index, "DepositManager: no request to process");

        WithdrawalReqeust storage r = _withdrawalRequests[layer2][msg.sender][index];

        require(r.withdrawableBlockNumber <= block.number, "DepositManager: wait for withdrawal delay");
        r.processed = true;

        _withdrawalRequestIndex[layer2][msg.sender] += 1;

        uint256 amount = r.amount;

        _pendingUnstaked[layer2][msg.sender] = _pendingUnstaked[layer2][msg.sender] - amount;
        _pendingUnstakedLayer2[layer2] = _pendingUnstakedLayer2[layer2] - amount;
        _pendingUnstakedAccount[msg.sender] = _pendingUnstakedAccount[msg.sender] - amount;

        // _accUnstaked[layer2][msg.sender] = _accUnstaked[layer2][msg.sender] + amount;
        // _accUnstakedLayer2[layer2] = _accUnstakedLayer2[layer2] + amount;
        // _accUnstakedAccount[msg.sender] = _accUnstakedAccount[msg.sender] + amount;

        if (receiveTon) {
        require(IWTON(_wton).swapToTONAndTransfer(msg.sender, amount), "fail swapToTONAndTransfer");
        } else {
        IERC20(_wton).safeTransfer(msg.sender, amount);
        }

        emit WithdrawalProcessed(layer2, msg.sender, amount);
        return true;
    }

    function requestWithdrawalAll(address layer2) external onlyLayer2(layer2) returns (bool) {
        uint256 amount = ISeigManager(_seigManager).stakeOf(layer2, msg.sender);
        return _requestWithdrawal(layer2, amount, getDelayBlocks(layer2));
    }

    function processRequests(address layer2, uint256 n, bool receiveTon) external returns (bool) {
        for (uint256 i = 0; i < n; i++) {
        require(_processRequest(layer2, receiveTon), "fail processRequests");
        }
        return true;
    }

    function _getL1BridgeInfo(address layer2) internal returns (L1BridgeInfo memory info) {
        address operator = ILayer2(layer2).operator();
        if (operator == address(0)) revert OperatorError();
        if (operator.code.length == 0) revert OperatorError();

        if (l1BridgeRegistry == address(0))
            l1BridgeRegistry = ISeigManager(_seigManager).l1BridgeRegistry();

        (bool success, bytes memory data) = operator.call(
            abi.encodeWithSelector(IOperator.checkL1Bridge.selector)
        );
        if (!success) revert CheckL1BridgeError(1);

        _decodeL1BridgeInfo(data, info);
    }

    function _decodeL1BridgeInfo(bytes memory data, L1BridgeInfo memory info) internal pure {
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
        require(l2Ton != address(0), "l2Ton: zero address");
        if ((l2Type != 1 && l2Type != 2 && l2Type != 3) || status != 1) revert CheckL1BridgeError(5);
        if (l2Type != 1 && portal == address(0)) revert CheckL1BridgeError(4);

        info.l1Bridge = l1Bridge;
        info.portal = portal;
        info.l2Ton = l2Ton;
        info.l2Type = l2Type;
        info.minGasLimit = l2Ton != LEGACY_ERC20_NATIVE_TOKEN ? 210_000 : 0;
    }

    /**
     * @notice Withdrawal from L1 and deposit to L2
     * @param layer2    The layer2(candidate) address
     * @param amount    The amount to be withdrawal and deposit L2. ()`amount` WTON in RAY)
     */
    function withdrawAndDepositL2(address layer2, uint256 amount) external ifFree returns (bool) {
        if (amount == 0) revert ZeroValueError();
        require(
            ISeigManager(_seigManager).stakeOf(layer2, msg.sender) >= amount,
            "staked amount is insufficient"
        );

        L1BridgeInfo memory info = _getL1BridgeInfo(layer2);

        if (!ISeigManager(_seigManager).onWithdraw(layer2, msg.sender, amount)) revert WithdrawError();
        if (!IWTON(_wton).swapToTONAndTransfer(address(this), amount))
            revert SwapTonTransferError();

        if (ton == address(0)) ton = IIERC20(_wton).ton();
        address _ton = ton;
        uint256 tonAmount = amount / GWEI_UNIT;

        {
            uint256 allowance = IERC20(_ton).allowance(address(this), info.l1Bridge);
            unchecked {
                if (allowance < tonAmount) {
                    IIERC20(_ton).increaseAllowance(info.l1Bridge, tonAmount - allowance);
                }
            }
        }

        uint256 bal;
        if (info.l2Type == 2 || info.l2Type == 3) {
            bal = IERC20(_ton).balanceOf(info.portal);
            IL1Bridge(info.l1Bridge).bridgeNativeTokenTo(msg.sender, tonAmount, info.minGasLimit, "");
            bal = IERC20(_ton).balanceOf(info.portal) - bal;
        } else {
            bal = IERC20(_ton).balanceOf(info.l1Bridge);
            IL1Bridge(info.l1Bridge).depositERC20To(_ton, info.l2Ton, msg.sender, tonAmount, info.minGasLimit, "");
            bal = IERC20(_ton).balanceOf(info.l1Bridge) - bal;
        }

        require(bal == tonAmount, "fail depositERC20To");

        // V3: 스테이킹 변경 알림 (자격 재평가용)
        _notifyStakingChange(layer2);

        emit DepositedERC20To(info.l1Bridge, _ton, info.l2Ton, msg.sender, tonAmount, info.minGasLimit);
        emit WithdrawalAndDeposited(layer2, msg.sender, amount);
        return true;
    }



    function numRequests(address layer2, address account) external view returns (uint256) {
        return _withdrawalRequests[layer2][account].length;
    }

    function numPendingRequests(address layer2, address account) external view returns (uint256) {
        uint256 numRequests_ = _withdrawalRequests[layer2][account].length;
        uint256 index = _withdrawalRequestIndex[layer2][account];

        if (numRequests_ == 0) return 0;

        return numRequests_ - index;
    }

    function _isOperator(address layer2, address operator) internal view returns (bool) {
        return operator == ILayer2(layer2).operator();
    }

    function getDelayBlocks(address layer2) public view returns (uint256){
        return  globalWithdrawalDelay > withdrawalDelay[layer2] ? globalWithdrawalDelay : withdrawalDelay[layer2];
    }

    /// @notice 스테이킹 변경 후 SeigManager에 알림 (V3)
    /// @dev SeigManager가 내부적으로 자격 재평가 및 캐시 갱신
    /// @param layer2 L2 주소
    function _notifyStakingChange(address layer2) internal {
        try ISeigManagerV3(_seigManager).onStakingChange(layer2) {} catch {}
    }

    ////////////////////
    // Storage getters
    ////////////////////

    // solium-disable
    function wton() external view returns (address) { return _wton; }
    function registry() external view returns (address) { return _registry; }
    function seigManager() external view returns (address) { return _seigManager; }

    // function accStaked(address layer2, address account) external view returns (uint256 wtonAmount) { return _accStaked[layer2][account]; }
    // function accStakedLayer2(address layer2) external view returns (uint256 wtonAmount) { return _accStakedLayer2[layer2]; }
    // function accStakedAccount(address account) external view returns (uint256 wtonAmount) { return _accStakedAccount[account]; }

    function pendingUnstaked(address layer2, address account) external view returns (uint256 wtonAmount) { return _pendingUnstaked[layer2][account]; }
    function pendingUnstakedLayer2(address layer2) external view returns (uint256 wtonAmount) { return _pendingUnstakedLayer2[layer2]; }
    function pendingUnstakedAccount(address account) external view returns (uint256 wtonAmount) { return _pendingUnstakedAccount[account]; }

    // function accUnstaked(address layer2, address account) external view returns (uint256 wtonAmount) { return _accUnstaked[layer2][account]; }
    // function accUnstakedLayer2(address layer2) external view returns (uint256 wtonAmount) { return _accUnstakedLayer2[layer2]; }
    // function accUnstakedAccount(address account) external view returns (uint256 wtonAmount) { return _accUnstakedAccount[account]; }

    function withdrawalRequestIndex(address layer2, address account) external view returns (uint256 index) { return _withdrawalRequestIndex[layer2][account]; }
    function withdrawalRequest(address layer2, address account, uint256 index) external view returns (uint128 withdrawableBlockNumber, uint128 amount, bool processed ) {

        WithdrawalReqeust memory wrequests = _withdrawalRequests[layer2][account][index];
        withdrawableBlockNumber = wrequests.withdrawableBlockNumber;
        amount = wrequests.amount;
        processed = wrequests.processed;
    }

  // solium-enable
}