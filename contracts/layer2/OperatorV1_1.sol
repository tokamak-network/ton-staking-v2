// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./OperatorStorage.sol";

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error ZeroAddressError();
error AlreadySetError();
error NotOperatorError();
error InsufficientBalanceError();
error TransferEthError();
error ParameterError();
error SameAddressError();

interface ISystemConfig {
    function owner() external view returns (address);
}

interface ILayer2Manager {
    function layer2CandidateOfOperator(address operator) external view returns (address);
    function checkL1Bridge(address _systemConfig) external view returns (bool result, address l1Bridge, address portal, address l2Ton);
}

interface IDepositManager {
    function deposit(address layer2, uint256 amount) external returns (bool);
    function requestWithdrawal(address layer2, uint256 amount) external returns (bool);
    function processRequest(address layer2, bool receiveTON) external returns (bool);
}

/// @title
/// @notice
contract OperatorV1_1 is Ownable, OperatorStorage {
    using SafeERC20 for IERC20;

    event TransferredManager(address previousManager, address newManager);
    event AddedOperator(address operator);
    event DeletedOperator(address operator);
    event SetAddresses(address _layer2Manager, address _depositManager, address _ton, address _wton);

    constructor() { }

    modifier onlyOwnerOrManager() {
        require(owner() == msg.sender || msg.sender == manager, "not onlyOwnerOrManager");
        _;
    }

    modifier onlyLayer2Candidate() {
        require(msg.sender == ILayer2Manager(layer2Manager).layer2CandidateOfOperator(address(this)), "not onlyLayer2Candidate");
        _;
    }

    function setAddresses(address _layer2Manager, address _depositManager, address _ton, address _wton)
        external
        nonZeroAddress(_layer2Manager) nonZeroAddress(_depositManager)
        nonZeroAddress(_ton) nonZeroAddress(_wton)
    {
        _alreadySet(layer2Manager);

        layer2Manager = _layer2Manager;
        depositManager = _depositManager;
        ton = _ton;
        wton = _wton;

        emit SetAddresses(_layer2Manager, _depositManager, _ton, _wton);
    }

    /* ========== onlyOwnerOrManager ========== */

    function transferManager(address newManager) external nonZeroAddress(newManager) onlyOwnerOrManager {
        if (manager == newManager) revert SameAddressError();

        emit TransferredManager(manager, newManager);
        manager = newManager;
    }

    function addOperator(address addr_) external nonZeroAddress(addr_) onlyOwnerOrManager {
        require(!operator[addr_], "already added");
        operator[addr_] = true;
        emit AddedOperator(addr_);
    }

    function deleteOperator(address addr_) external nonZeroAddress(addr_) onlyOwnerOrManager {
        require(operator[addr_], "not operator");
        operator[addr_] = false;
        emit DeletedOperator(addr_);
    }

    /* ========== onlyLayer2Candidate ========== */

    function depositByLayer2Canddiate(uint256 amount) external onlyLayer2Candidate {
        _deposit(msg.sender, amount);
    }

    function claimByLayer2Candidate(uint256 amount) external onlyLayer2Candidate {
        _claim(wton, manager, amount);
    }

    /* ========== onlyOperator ========== */

    /*
    execute a transaction (called directly from owner, or by entryPoint)
    */
    function execute(address dest, uint256 value, bytes calldata func) external {
        _onlyOperator();
        _call(dest, value, func);
    }

    /**
     * execute a sequence of transactions
     */
    function executeBatch(address[] calldata dest, bytes[] calldata func) external {
        _onlyOperator();
        if (dest.length != func.length || dest.length == 0) revert ParameterError();
        for (uint256 i = 0; i < dest.length; i++) {
            _call(dest[i], 0, func[i]);
        }
    }

    /* ========== public ========== */

    function acquireManager() external {
        require (msg.sender != manager, "already manager");
        require (msg.sender == ISystemConfig(systemConfig).owner(), "not config's owner");

        emit TransferredManager(manager, msg.sender);
        manager = msg.sender;
    }

    function isOperator(address addr) public view returns (bool) {
        return operator[addr];
    }

    function checkL1Bridge() public view returns (bool result, address l1Bridge, address portal, address l2Ton) {
        return ILayer2Manager(layer2Manager).checkL1Bridge(systemConfig);
    }

    /* ========== internal ========== */

    function _nonZeroAddress(address _addr) internal pure {
        if (_addr == address(0)) revert ZeroAddressError();
    }

    function _alreadySet(address _addr) internal pure {
        if (_addr != address(0)) revert AlreadySetError();
    }

    function _onlyOperator() internal view {
        if (!operator[msg.sender]) revert NotOperatorError();
    }

    function _claim(address token, address to, uint256 amount) internal {
        address thisAccount = address(this);
        if(token == address(0)) {
            if(thisAccount.balance < amount) revert InsufficientBalanceError();
            (bool success, ) = to.call{value: amount}("");
            if (!success) revert TransferEthError();
        } else {
            if (IERC20(token).balanceOf(thisAccount) < amount) revert InsufficientBalanceError();
            IERC20(token).safeTransfer(to, amount);
        }
    }

    function _deposit(address layer2, uint256 amount) internal {
        address _depositManager = depositManager;
        address _wton = wton;

        uint256 allowance = IERC20(_wton).allowance(address(this), _depositManager);
        if(allowance < amount) IERC20(_wton).approve(_depositManager, type(uint256).max);

        IDepositManager(_depositManager).deposit(layer2, amount);
    }


    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value : value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }


}