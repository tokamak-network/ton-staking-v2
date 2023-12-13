// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
interface L2CrossDomainMessengerI {
    function relayMessage(
        address _target,
        address _sender,
        bytes memory _message,
        uint256 _messageNonce
    ) external;
}

contract MockL1Messenger  {

    mapping(bytes32 => bool) public successfulMessages;

    uint256 public messageNonce;
    address public l2messenger;

    event SentMessage(
        address indexed target,
        address sender,
        bytes message,
        uint256 messageNonce,
        uint256 gasLimit
    );

    constructor() {
    }


    function setL2messenger(address _l2messagenger) external {
        require(l2messenger == address(0), 'already set');
        l2messenger = _l2messagenger;
    }

    function setSuccessfulMessages(bytes32 _hashMessages, bool _bool) external {
        successfulMessages[_hashMessages] = _bool;
    }

    function sendMessage(
        address _target,
        bytes memory _message,
        uint32 _gasLimit
    ) public {

        console.log("MockL1Messenger sendMessage _target %s", _target);

        emit SentMessage(_target, msg.sender, _message, ++messageNonce, _gasLimit);

        L2CrossDomainMessengerI(l2messenger).relayMessage(
            _target,
            msg.sender,
            _message,
            messageNonce
        );

        console.log("MockL1Messenger sendMessage end  ");
    }

}
