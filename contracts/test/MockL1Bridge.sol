// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import "hardhat/console.sol";

interface FwReceiptI {
    function finalizeFastWithdraw(bytes memory _l2Messages)
        external returns (uint8);
}

interface L1MessengerI {
    function setSuccessfulMessages(bytes32 _hashMessages, bool _bool) external;
    function successfulMessages(bytes32 _hashMessages) external view returns (bool);
}

interface MockL1BridgeI {
    function finalizeERC20Withdrawal(
        address _l1Token,
        address _l2Token,
        address _from,
        address _to,
        uint256 _amount,
        bytes memory _data
    ) external;
}

interface IL1CrossDomainMessenger {
    function relayMessage(
            address _target,
            address _sender,
            bytes memory _message,
            uint256 _messageNonce
        )  external;
}

interface MockL2BridgeI {
    function mintToken2(address l2Token, address _to, uint256 _amount) external;
}

contract MockL1Bridge is Ownable {
    using SafeERC20 for IERC20;

    /********************************
     * External Contract References *
     ********************************/
    address public l1Messenger;
    address public l2TokenBridge;

    // Maps L1 token to L2 token to balance of the L1 token deposited
    mapping(address => mapping(address => uint256)) public deposits;

    /** @dev Modifier requiring sender to be EOA.  This check could be bypassed by a malicious
     *  contract via initcode, but it takes care of the user error we want to avoid.
     */
    modifier onlyEOA() {
        // Used to stop deposits from contracts (avoid accidentally lost tokens)
        require(!Address.isContract(msg.sender), "Account not EOA");
        _;
    }

    modifier onlyFromCrossDomainAccount(address _sourceDomainAccount) {
        require(
            msg.sender == l1Messenger,
            "OVM_XCHAIN: messenger contract unauthenticated"
        );

        // require(
        //     getCrossDomainMessenger().xDomainMessageSender() == _sourceDomainAccount,
        //     "OVM_XCHAIN: wrong sender of cross-domain message"
        // );

        _;
    }

    event ERC20DepositInitiated(
        address indexed _l1Token,
        address indexed _l2Token,
        address indexed _from,
        address _to,
        uint256 _amount,
        bytes _data
    );

    constructor() {
    }

    function setAddress(address _l1Messenger, address _l2TokenBridge) external onlyOwner {
         l1Messenger = _l1Messenger;
        l2TokenBridge = _l2TokenBridge;
    }

    function depositERC20(
        address _l1Token,
        address _l2Token,
        uint256 _amount,
        uint32 _l2Gas,
        bytes calldata _data
    ) external virtual onlyEOA {
        _initiateERC20Deposit(_l1Token, _l2Token, msg.sender, msg.sender, _amount, _l2Gas, _data);
    }

    function depositERC20To(
        address _l1Token,
        address _l2Token,
        address _to,
        uint256 _amount,
        uint32 _l2Gas,
        bytes calldata _data
    ) external virtual {

        _initiateERC20Deposit(_l1Token, _l2Token, msg.sender, _to, _amount, _l2Gas, _data);
    }

    function _initiateERC20Deposit(
        address _l1Token,
        address _l2Token,
        address _from,
        address _to,
        uint256 _amount,
        uint32 _l2Gas,
        bytes calldata _data
    ) internal {

        IERC20(_l1Token).safeTransferFrom(_from, address(this), _amount);

        // for test
        MockL2BridgeI(l2TokenBridge).mintToken2(_l2Token, _to, _amount);

        // uint256 balance = IERC20(_l2Token).balanceOf(_to);

        deposits[_l1Token][_l2Token] = deposits[_l1Token][_l2Token] + _amount;

        emit ERC20DepositInitiated(_l1Token, _l2Token, _from, _to, _amount, _data);
    }


    function finalizeERC20Withdrawal(
        address _l1Token,
        address _l2Token,
        address _from,
        address _to,
        uint256 _amount,
        bytes memory _data,
        uint256 _nonce
    // ) external onlyFromCrossDomainAccount(l2TokenBridge) {
    ) external {

        bytes memory _message = abi.encodeWithSelector(MockL1BridgeI.finalizeERC20Withdrawal.selector,
            _l1Token, _l2Token, _from, _to, _amount, _data);

        bytes memory _message2 = abi.encodeWithSelector(IL1CrossDomainMessenger.relayMessage.selector,
            address(this), l2TokenBridge, _message, _nonce);

        bytes32 _key = keccak256(_message2);

        require(!L1MessengerI(l1Messenger).successfulMessages(_key), "already done");

        uint256 bal = IERC20(_l1Token).balanceOf(address(this));

        require(bal >= _amount, "balance is insufficient");

        // deposits[_l1Token][_l2Token] = deposits[_l1Token][_l2Token] - _amount;
        // for test
        if(deposits[_l1Token][_l2Token] > _amount)
            deposits[_l1Token][_l2Token] = deposits[_l1Token][_l2Token] - _amount;

        L1MessengerI(l1Messenger).setSuccessfulMessages(_key, true);

        // When a withdrawal is finalized on L1, the L1 Bridge transfers the funds to the withdrawer
        // slither-disable-next-line reentrancy-events
        IERC20(_l1Token).safeTransfer(_to, _amount);

        // 질문. core evm 에서는 data 실행하는 코드가 왜 없는지..
        // if(_data.length != 0){
        //     (bool success, bytes memory result) = _to.call{value:0}(_message2);
        // }

        // console.logBool(success);
        // console.logBytes(result);

        // (uint8 status) = abi.decode(result,(uint8));
        // console.log(status);

        // // slither-disable-next-line reentrancy-events
        // emit ERC20WithdrawalFinalized(_l1Token, _l2Token, _from, _to, _amount, _data);
    }
}
