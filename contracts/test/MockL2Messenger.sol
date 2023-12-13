// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
contract MockL2Messenger  {

    uint256 public messageNonce;
    address internal xDomainMsgSender;
    address public l1CrossDomainMessenger;

    event RelayedMessage(
        address indexed target,
        address sender,
        bytes message,
        uint256 messageNonce
    );

    event FailedRelayedMessage(
        address indexed target,
        address sender,
        bytes message,
        uint256 messageNonce
    );

    constructor() {
    }

    function xDomainMessageSender() public view returns (address) {
        require(
            xDomainMsgSender != address(0),
            "xDomainMessageSender is not set"
        );
        return xDomainMsgSender;
    }

    function relayMessage(
        address _target,
        address _sender,
        bytes memory _message,
        uint256 _messageNonce
    ) public {
        console.log("MockL2Messenger relayMessage _target %s", _target);

        xDomainMsgSender = _sender;
        // slither-disable-next-line reentrancy-no-eth, reentrancy-events, reentrancy-benign
        (bool success, ) = _target.call{gas:10000000000}(_message);
        // slither-disable-next-line reentrancy-benign
        console.logBool(success);

        xDomainMsgSender = address(0);
        if(success) {
            emit RelayedMessage(_target, _sender, _message, _messageNonce);
        } else {
            emit FailedRelayedMessage(_target, _sender, _message, _messageNonce);
        }
        console.log("MockL2Messenger relayMessage end ");

    }

}
