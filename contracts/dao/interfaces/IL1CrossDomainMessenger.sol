// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IL1CrossDomainMessenger {
    function sendNativeTokenMessage(
        address _target,
        uint256 _amount,
        bytes calldata _message,
        uint32 _minGasLimit
    )
        external;

    function sendMessage(
        address _target, 
        bytes calldata _message, 
        uint32 _minGasLimit
    ) 
        external 
        payable;


    function relayMessage(
        uint256 _nonce,
        address _sender,
        address _target,
        uint256 _value,
        uint256 _minGasLimit,
        bytes calldata _message
    )
        external
        payable;

    function messageNonce() 
        external 
        view 
        returns (uint256);

    function baseGas(
        bytes calldata _message, 
        uint32 _minGasLimit
    ) 
        external 
        pure 
        returns (uint64);
}