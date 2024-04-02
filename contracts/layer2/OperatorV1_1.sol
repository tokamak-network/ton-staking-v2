// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./OperatorStorage.sol";

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISystemConfig {
    function owner() external view returns (address);
}

interface ILayer2Manager {
    function layer2CandidateOfOperator(address operator) external view returns (address);
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
        external nonZeroAddress(_layer2Manager) nonZeroAddress(_depositManager)
        nonZeroAddress(_ton) nonZeroAddress(_wton)
    {
        require(layer2Manager == address(0), "already set");
        layer2Manager = _layer2Manager;
        depositManager = _depositManager;
        ton = _ton;
        wton = _wton;

        emit SetAddresses(_layer2Manager, _depositManager, _ton, _wton);
    }

    /* ========== onlyOwnerOrManager ========== */

    function transferManager(address newManager) external nonZeroAddress(newManager) onlyOwnerOrManager {
        require (manager != newManager, "same");
        address prevManager = manager;
        manager = newManager;
        emit TransferredManager(prevManager, manager);
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
    // function deposit(uint256 amount) external onlyOperator {
    //     _deposit(ILayer2Manager(layer2Manager).layer2CandidateOfOperator(address(this)), amount);
    // }

    // function unstaking(uint256 amount) external onlyOperator {
    //     _deposit(ILayer2Manager(layer2Manager).layer2CandidateOfOperator(address(this)), amount);
    // }

    // function claim(address token, address to, uint256 amount) external onlyOperator {
    //     require(amount != 0, "zero");
    //     _claim(token, to, amount);
    // }

    /*
    execute a transaction (called directly from owner, or by entryPoint)
    */
    function execute(address dest, uint256 value, bytes calldata func) external onlyOperator {
        _call(dest, value, func);
    }

    /**
     * execute a sequence of transactions
     */
    function executeBatch(address[] calldata dest, bytes[] calldata func) external onlyOperator {
        require(dest.length == func.length, "wrong array lengths");
        for (uint256 i = 0; i < dest.length; i++) {
            _call(dest[i], 0, func[i]);
        }
    }

    /* ========== public ========== */

    function acquireManager() external {
        require (msg.sender != manager, "already manager");
        require (msg.sender == ISystemConfig(systemConfig).owner(), "not config's owner");
        address prevManager = manager;
        manager = msg.sender;
        emit TransferredManager(prevManager, manager);
    }

    function isOperator(address addr) public view returns (bool) {
        return operator[addr];
    }

    /* ========== internal ========== */

    function _claim(address token, address to, uint256 amount) internal {
        if(token == address(0)) {
            require(address(this).balance >= amount, "insufficient balance");
            payable(to).transfer(amount);

        } else {
            require(IERC20(token).balanceOf(address(this)) >= amount, "insufficient balance");
            IERC20(token).safeTransfer(to, amount);
        }
    }

    function _deposit(address layer2, uint256 amount) internal {
        uint256 allowance = IERC20(wton).allowance(address(this), depositManager);
        if(allowance < amount) IERC20(wton).approve(depositManager, type(uint256).max);

        IDepositManager(depositManager).deposit(layer2, amount);
    }

    // function _unstaking(address layer2, uint256 amount) internal {
    //     IDepositManager(depositManager).requestWithdrawal(layer2, amount);
    // }

    // function _withdraw(address layer2, bool receiveTON) internal {
    //     IDepositManager(depositManager).processRequest(layer2, receiveTON);
    // }

    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value : value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }


}