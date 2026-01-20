// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IWTON } from "../stake/interfaces/IWTON.sol";
import { IRollupConfig } from "../layer2/interfaces/IRollupConfig.sol";
import { ILayer2Manager } from "../layer2/interfaces/ILayer2Manager.sol";
import { IDepositManager } from "../stake/interfaces/IDepositManager.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "./OperatorManagerStorage.sol";

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error ZeroAddressError();
error AlreadySetError();
error NotOperatorError();
error InsufficientBalanceError();
error TransferEthError();
error ParameterError();
error SameAddressError();
error SameError();
error SequencerVaultNotSetError();

/// @title OperatorManagerV1_2
/// @notice V3: SequencerVault 연동 추가
/// @dev OperatorManager 주소가 SequencerVault의 시퀀서로 등록됨
contract OperatorManagerV1_2 is Ownable, OperatorManagerStorage {
    using SafeERC20 for IERC20;

    // ==========================================
    // Events
    // ==========================================

    event TransferredManager(address previousManager, address newManager);
    event AddedOperator(address operator);
    event DeletedOperator(address operator);
    event SetAddresses(address _layer2Manager, address _depositManager, address _ton, address _wton);
    event Claimed(address token, address caller, address to, uint256 amount);
    event SetAdditionalNotes(string _additionalNotesl2Info);
    event RequestWithdrawal(address candidate, uint256 amount);
    event ProcessRequest(address candidate);
    event ProcessRequests(address candidate, uint256 n);

    // ==========================================
    // Constructor
    // ==========================================

    constructor() { }

    // ==========================================
    // Modifiers
    // ==========================================

    modifier onlyOwnerOrManager() {
        require(owner() == msg.sender || msg.sender == manager(), "not onlyOwnerOrManager");
        _;
    }

    // ==========================================
    // Admin Functions
    // ==========================================

    /**
     * @notice Set the addresses
     * @param _layer2Manager    the _layer2Manager address
     * @param _depositManager   the _depositManager address
     * @param _ton              the TON address
     * @param _wton             the WTON address
     */
    function setAddresses(address _layer2Manager, address _depositManager, address _ton, address _wton)
        external
        nonZeroAddress(_layer2Manager) nonZeroAddress(_depositManager)
        nonZeroAddress(_ton) nonZeroAddress(_wton) onlyOwner
    {
        _alreadySet(layer2Manager());

        _setStorageAddress(_LAYER2_MANAGER_ADDRESS_SLOT, _layer2Manager);
        _setStorageAddress(_DEPOSIT_MANAGER_ADDRESS_SLOT, _depositManager);
        _setStorageAddress(_TON_ADDRESS_SLOT, _ton);
        _setStorageAddress(_WTON_ADDRESS_SLOT, _wton);

        emit SetAddresses(_layer2Manager, _depositManager, _ton, _wton);
    }

    // ==========================================
    // Manager Functions
    // ==========================================

    function transferManager(address newManager) external nonZeroAddress(newManager) onlyOwnerOrManager {
        address _manager = manager();
        if (_manager == newManager) revert SameAddressError();

        _setStorageAddress(_MANAGER_SLOT, newManager);
        emit TransferredManager(_manager, newManager);
    }

    function claimETH() external onlyOwnerOrManager {
        _claim(address(0), manager(), address(this).balance);
    }

    function claimERC20(address token, uint256 amount) external onlyOwnerOrManager {
        _claim(token, manager(), amount);
    }

    // ==========================================
    // V2 Staking Functions (DepositManager)
    // ==========================================

    function requestWithdrawal(uint256 amount) external onlyOwnerOrManager {
        address candidate = ILayer2Manager(layer2Manager()).candidateAddOnOfOperator(address(this));
        require(IDepositManager(depositManager()).requestWithdrawal(candidate, amount), "fail requestWithdraw");
        emit RequestWithdrawal(candidate, amount);
    }

    function processRequest() external onlyOwnerOrManager {
        address candidate = ILayer2Manager(layer2Manager()).candidateAddOnOfOperator(address(this));
        require(IDepositManager(depositManager()).processRequest(candidate, false), "fail processRequest");
        emit ProcessRequest(candidate);
    }

    function processRequests(uint256 n) external onlyOwnerOrManager {
        address candidate = ILayer2Manager(layer2Manager()).candidateAddOnOfOperator(address(this));
        require(IDepositManager(depositManager()).processRequests(candidate, n, false), "fail processRequests");
        emit ProcessRequests(candidate, n);
    }

    // ==========================================
    // Public Functions
    // ==========================================

    function acquireManager() external {
        address _manager = manager();
        require (msg.sender != _manager, "already manager");
        require (msg.sender == IRollupConfig(rollupConfig()).unsafeBlockSigner(), "not config's seigniorageReceiver");

        _setStorageAddress(_MANAGER_SLOT, msg.sender);
        emit TransferredManager(_manager, msg.sender);
    }

    function isOperator(address addr) public view returns (bool) {
        return (addr != address(0) && addr == manager());
    }

    function checkL1Bridge() public view returns (
        bool result, address l1Bridge, address portal, address l2Ton, uint8 _type, uint8 status, bool rejectedSeigs, bool rejectedL2Deposit
    ) {
        return ILayer2Manager(layer2Manager()).checkL1BridgeDetail(rollupConfig());
    }

    function operator() external view returns (address) { return manager(); }

    // ==========================================
    // Internal Functions
    // ==========================================

    function _nonZeroAddress(address _addr) internal pure {
        if (_addr == address(0)) revert ZeroAddressError();
    }

    function _alreadySet(address _addr) internal pure {
        if (_addr != address(0)) revert AlreadySetError();
    }

    function _claim(address token, address to, uint256 amount) internal {
        if(token == address(0)) {
            if(address(this).balance < amount) revert InsufficientBalanceError();
            (bool success, ) = to.call{value: amount}("");
            if (!success) revert TransferEthError();
        } else {
            if (IERC20(token).balanceOf(address(this)) < amount) revert InsufficientBalanceError();
            IERC20(token).safeTransfer(to, amount);
        }
        emit Claimed(token, msg.sender, to, amount);
    }

    function _depositTo(address layer2, address to) internal {
        address _depositManager = depositManager();
        uint256 amount = _onAapproveHoldingAmount(_depositManager);
        if (amount != 0) IDepositManager(_depositManager).deposit(layer2, to, amount);
    }

    function _onAapproveHoldingAmount(address to) internal returns (uint256) {
        address _wton = wton();
        uint256 amount = IERC20(_wton).balanceOf(address(this));
        if(amount != 0) {
            uint256 allowance = IERC20(_wton).allowance(address(this), to);
            if (allowance < amount) IERC20(_wton).approve(to, type(uint256).max);
        }
        return amount;
    }
}
