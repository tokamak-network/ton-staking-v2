// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPauser {
    function pause() external ;
    function unpause() external;
}