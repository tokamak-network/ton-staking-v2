// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Test, console2} from "forge-std/Test.sol";
import {RefactorCoinageSnapshot} from "../contracts/stake/tokens/RefactorCoinageSnapshot.sol";

contract RefactorCoinageSnapshotTest is Test {
    RefactorCoinageSnapshot public refacotorcoinagesnapshot;

    function setUp() public {
        refacotorcoinagesnapshot = new RefactorCoinageSnapshot();
        refacotorcoinagesnapshot.initialize(name_, symbol_, factor_, seigManager_);
    }

    function test_setFactor() public {
        refacotorcoinagesnapshot.increment();
        assertEq(refacotorcoinagesnapshot.number(), 1);
    }

    function testFuzz_SetNumber(uint256 x) public {
        refacotorcoinagesnapshot.setNumber(x);
        assertEq(refacotorcoinagesnapshot.number(), x);
    }
}