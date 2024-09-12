// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

interface IRollupConfig {
    function owner() external view returns (address);
}

interface ILayer2Manager {
    function candidateAddOnOfOperator(address operator) external view returns (address);
    function checkL1Bridge(address _rollupConfig) external view returns (bool result, address l1Bridge, address portal, address l2Ton);
    function checkL1BridgeDetail(address _rollupConfig) external view returns (bool result, address l1Bridge, address portal, address l2Ton, uint8 _type, uint8 status);
}

interface IDepositManager {
    function deposit(address layer2, uint256 amount) external returns (bool);
    function deposit(address layer2, address to, uint256 amount) external returns (bool);
    function requestWithdrawal(address layer2, uint256 amount) external returns (bool);
    function processRequest(address layer2, bool receiveTON) external returns (bool);
    function processRequests(address layer2, uint256 n, bool receiveTON) external returns (bool);
}

/// @title
/// @notice
contract OperatorManagerV1_1 is Ownable, OperatorManagerStorage {
    using SafeERC20 for IERC20;

    /**
     * @notice Event occurs when the transfer manager
     * @param previousManager   the previous manager address
     * @param newManager        the new manager address
     */
    event TransferredManager(address previousManager, address newManager);

    /**
     * @notice Event occurs when adding the operator
     * @param operator  the operator address
     */
    event AddedOperator(address operator);

    /**
     * @notice Event occurs when deleting the operator
     * @param operator  the operator address
     */
    event DeletedOperator(address operator);

    /**
     * @notice Event occurs when setting the addresses
     * @param _layer2Manager    the _layer2Manager address
     * @param _depositManager   the _depositManager address
     * @param _ton              the TON address
     * @param _wton             the WTON address
     */
    event SetAddresses(address _layer2Manager, address _depositManager, address _ton, address _wton);

    /**
     * @notice Event occurs when the claim token
     * @param token     the token address, if token address is address(0), it is ETH
     * @param caller    the caller address
     * @param to        the address received token
     * @param amount    the received token amount
     */
    event Claimed(address token, address caller, address to, uint256 amount);

    /**
     * @notice Event occurs when setting the explorer url
     * @param _explorer a explorer url
     */
    event SetExplorer(string _explorer);

    /**
     * @notice Event occurs when requesting withdraw of staked ton
     * @param candidate     the candidate address
     * @param amount        the amount requesting withdrawal
     */
    event RequestWithdrawal(address candidate, uint256 amount);

    /**
     * @notice Event occurs when processing requesting withdrawal
     * @param candidate     the candidate address
     */
    event ProcessRequest(address candidate);

    /**
     * @notice Event occurs when processing requesting withdrawals
     * @param candidate     the candidate
     * @param n             the number of requests
     */
    event ProcessRequests(address candidate, uint256 n);

    constructor() { }

    modifier onlyOwnerOrManager() {
        require(owner() == msg.sender || msg.sender == manager, "not onlyOwnerOrManager");
        _;
    }

    modifier onlyCandidateAddOn() {
        require(msg.sender == ILayer2Manager(layer2Manager).candidateAddOnOfOperator(address(this)), "not onlyCandidateAddOn");
        _;
    }

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
        _alreadySet(layer2Manager);

        layer2Manager = _layer2Manager;
        depositManager = _depositManager;
        ton = _ton;
        wton = _wton;

        emit SetAddresses(_layer2Manager, _depositManager, _ton, _wton);
    }

    /* ========== onlyOwnerOrManager ========== */

    /**
     * @notice Transfer the manager
     * @param newManager    the new manager address
     */
    function transferManager(address newManager) external nonZeroAddress(newManager) onlyOwnerOrManager {
        if (manager == newManager) revert SameAddressError();

        emit TransferredManager(manager, newManager);
        manager = newManager;
    }

    /**
     * @notice  Give ETH to a manager through the manager(or owner) claim
     */
    function claimETH() external onlyOwnerOrManager {
        _claim(address(0), manager, address(this).balance);
    }

    /**
     * @notice  Give ERC20 to a manager through the manager(or owner) claim
     * @param token     the token address
     * @param amount    the amount claimed token
     */
    function claimERC20(address token, uint256 amount) external onlyOwnerOrManager {
        _claim(token, manager, amount);
    }

    /**
     * @notice  Set the explorer url
     * @param _explorer a explorer url
     */
    function setExplorer(string calldata _explorer) external onlyOwnerOrManager {
        if (keccak256(bytes(explorer)) == keccak256(bytes(_explorer))) revert SameError();
        explorer = _explorer;

        emit SetExplorer(_explorer);
    }

    /**
     * @notice Request withdrawal the staked ton
     * @param amount    the amount requesting withdrawal
     */
    function requestWithdrawal(uint256 amount) external onlyOwnerOrManager {
        address candidate = ILayer2Manager(layer2Manager).candidateAddOnOfOperator(address(this));

        require(IDepositManager(depositManager).requestWithdrawal(candidate, amount), "fail requestWithdraw");

        emit RequestWithdrawal(candidate, amount);
    }

    function processRequest() external onlyOwnerOrManager {
        address candidate = ILayer2Manager(layer2Manager).candidateAddOnOfOperator(address(this));

        require(IDepositManager(depositManager).processRequest(candidate, false), "fail processRequest");

        emit ProcessRequest(candidate);
    }

    function processRequests(uint256 n) external onlyOwnerOrManager {
        address candidate = ILayer2Manager(layer2Manager).candidateAddOnOfOperator(address(this));

        require(IDepositManager(depositManager).processRequests(candidate, n, false), "fail processRequests");

        emit ProcessRequests(candidate, n);
    }

    /* ========== onlyCandidateAddOn ========== */

    /**
     * @notice Deposit wton amount to DepositManager as named Layer2
     * @param amount    the deposit wton amount (ray)
     */
    function depositByCandidateAddOn(uint256 amount) external onlyCandidateAddOn {
        _depositTo(msg.sender, manager, amount);
    }

    /**
     * @notice Claim WTON to a manager
     * @param amount    the deposit wton amount (ray)
     */
    function claimByCandidateAddOn(uint256 amount) external onlyCandidateAddOn {
        _claim(wton, manager, amount);
    }

    /* ========== public ========== */

    /**
     * @notice acquire manager privileges.
     */
    function acquireManager() external {
        require (msg.sender != manager, "already manager");
        require (msg.sender == IRollupConfig(rollupConfig).owner(), "not config's owner");

        emit TransferredManager(manager, msg.sender);
        manager = msg.sender;
    }

    /**
     * @notice Returns true if the the addr is a manager.
     * @param addr the address to check
     */
    function isOperator(address addr) public view returns (bool) {
        return (addr != address(0) && addr == manager);
    }

    /**
     * @notice Returns the availability status of Layer 2, L1 bridge address, portal address, and L2TON address.
     * @return result   the availability status of Layer 2
     * @return l1Bridge the L1 bridge address
     * @return portal   the L1 portal address
     * @return l2Ton    the L2 TON address
     *                  L2TON address is 0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000,
     *                  In this case, the native token of Layer 2 is TON.
     * @return _type    the layer 2 type ( 1: legacy optimism, 2: bedrock optimism with TON native token)
     * @return status           status for giving seigniorage ( 0: none , 1: registered, 2: paused )
     */
    function checkL1Bridge() public view returns (bool result, address l1Bridge, address portal, address l2Ton, uint8 _type, uint8 status) {
        return ILayer2Manager(layer2Manager).checkL1BridgeDetail(rollupConfig);
    }

    /* ========== internal ========== */

    function _nonZeroAddress(address _addr) internal pure {
        if (_addr == address(0)) revert ZeroAddressError();
    }

    function _alreadySet(address _addr) internal pure {
        if (_addr != address(0)) revert AlreadySetError();
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
        emit Claimed(token, msg.sender, to, amount);
    }

    function _deposit(address layer2, uint256 amount) internal {
        address _depositManager = depositManager;
        address _wton = wton;

        uint256 allowance = IERC20(_wton).allowance(address(this), _depositManager);
        if(allowance < amount) IERC20(_wton).approve(_depositManager, type(uint256).max);

        IDepositManager(_depositManager).deposit(layer2, amount);
    }

    function _depositTo(address layer2, address to, uint256 amount) internal {
        address _depositManager = depositManager;
        address _wton = wton;

        uint256 allowance = IERC20(_wton).allowance(address(this), _depositManager);
        if (allowance < amount) IERC20(_wton).approve(_depositManager, type(uint256).max);

        IDepositManager(_depositManager).deposit(layer2, to, amount);
    }
}