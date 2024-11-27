// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IL2CrossDomainMessenger {
    function xDomainMessageSender() 
        external 
        view 
        returns (address);
}