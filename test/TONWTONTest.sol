// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TONWTONTest is Test {
    address public ton;
    address public wton;

    function setUp() public {
        // 1. Deploy TON using deployCode
        // TON.json must contain both ABI and Bytecode
        ton = deployCode("abis/TON.json");
        require(ton != address(0), "TON deployment failed");
        
        // 2. Deploy WTON using deployCode with constructor args
        // WTON constructor typically accepts TON address
        bytes memory wtonArgs = abi.encode(ton);
        wton = deployCode("abis/WTON.json", wtonArgs);
        require(wton != address(0), "WTON deployment failed");
    }

    function test_TokenDeployment() public view {
        assertTrue(ton != address(0), "TON should be deployed");
        assertTrue(wton != address(0), "WTON should be deployed");
    }

    function test_TransferTON_ToRandomAccount() public {
        // Create a random account 'Alice'
        address alice = makeAddr("alice");
        uint256 amount = 1000.1 ether; // 1000.1 TON

        // 1. Give this test contract some TON using 'deal'
        // 'deal' works by manipulating storage slots, helpful for testing without minting logic
        deal(ton, address(this), amount);

        // Check initial balance
        uint256 initialBalance = IERC20(ton).balanceOf(address(this));
        assertEq(initialBalance, amount, "Deal failed to set balance");

        // 2. Transfer TON to Alice
        IERC20(ton).transfer(alice, amount);

        // 3. Verify balances
        uint256 aliceBalance = IERC20(ton).balanceOf(alice);
        uint256 myBalance = IERC20(ton).balanceOf(address(this));

        assertEq(aliceBalance, amount, "Alice failed to receive TON");
        assertEq(myBalance, 0, "Sender failed to send TON");
        
    }

    function test_WTON_Swaps() public {
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        uint256 tonAmount = 100 ether; // 100 TON
        
        // 1. Setup Alice with TON
        deal(ton, alice, 1000 ether);
        
        vm.startPrank(alice);
        
        // Approve WTON to spend Alice's TON
        IERC20(ton).approve(wton, type(uint256).max);
        
        // --- Test 1: swapFromTON ---
        // Alice swaps 100 TON to WTON
        // WTON checks allowance and pulls TON
        bool success = IWTONTest(wton).swapFromTON(tonAmount);
        assertTrue(success, "swapFromTON failed");
        
        // Verify WTON balance (TON * 10^9)
        uint256 accWtonBalance = IERC20(wton).balanceOf(alice);
        assertEq(accWtonBalance, tonAmount * 1e9, "WTON balance mismatch after swapFromTON");
        
        // --- Test 2: swapToTON ---
        // Alice swaps half her WTON back to TON
        uint256 wtonSwapAmount = accWtonBalance / 2;
        success = IWTONTest(wton).swapToTON(wtonSwapAmount);
        assertTrue(success, "swapToTON failed");
        
        // Verify TON balance
        // Started with 1000, swapped 100 away (900 left), swapped back 50 worth (950 total)
        assertEq(IERC20(ton).balanceOf(alice), 950 ether, "TON balance mismatch after swapToTON");
        
        // --- Test 3: swapToTONAndTransfer ---
        // Alice swaps remaining WTON to TON and sends to Bob
        uint256 remainingWton = IERC20(wton).balanceOf(alice);
        success = IWTONTest(wton).swapToTONAndTransfer(bob, remainingWton);
        assertTrue(success, "swapToTONAndTransfer failed");
        
        // Check Alice WTON is 0
        assertEq(IERC20(wton).balanceOf(alice), 0, "Alice should have 0 WTON");
        // Check Bob received TON (50 TON worth)
        assertEq(IERC20(ton).balanceOf(bob), 50 ether, "Bob did not receive TON");
        
        // --- Test 4: swapFromTONAndTransfer ---
        // Alice swaps 10 TON to WTON and sends to Bob
        uint256 swapAmount2 = 10 ether;
        success = IWTONTest(wton).swapFromTONAndTransfer(bob, swapAmount2);
        assertTrue(success, "swapFromTONAndTransfer failed");
        
        // Check Bob WTON balance
        assertEq(IERC20(wton).balanceOf(bob), swapAmount2 * 1e9, "Bob did not receive WTON");
        
        vm.stopPrank();
    }
}

interface IWTONTest {
    function swapFromTON(uint256 tonAmount) external returns (bool);
    function swapToTON(uint256 wtonAmount) external returns (bool);
    function swapToTONAndTransfer(address to, uint256 wtonAmount) external returns (bool);
    function swapFromTONAndTransfer(address to, uint256 tonAmount) external returns (bool);
}
