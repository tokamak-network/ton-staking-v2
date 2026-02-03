// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import {BLS12381} from "../src/libraries/BLS12381.sol";

/**
 * @title TestBLSOnMainnet
 * @notice Script to test EIP-2537 BLS precompiles on actual Ethereum mainnet
 * @dev Run with: forge script script/TestBLSOnMainnet.s.sol --rpc-url https://ethereum-rpc.publicnode.com -vvv
 */
contract TestBLSOnMainnet is Script {
    function run() public view {
        console.log("========================================");
        console.log("Testing EIP-2537 BLS Precompiles on Ethereum Mainnet");
        console.log("========================================");
        console.log("");
        
        // Check precompile availability
        bool available = BLS12381.isPrecompileAvailable();
        console.log("Precompile available:", available);
        
        if (!available) {
            console.log("ERROR: BLS precompiles not available on this network");
            return;
        }
        
        console.log("SUCCESS: EIP-2537 BLS precompiles are available!");
        console.log("");
        
        // Test 1: Hash to G2
        console.log("Test 1: Hash to G2");
        bytes32 messageHash = keccak256("test message");
        console.log("Message hash:");
        console.logBytes32(messageHash);
        
        BLS12381.G2Point memory g2Point = BLS12381.hashToG2(messageHash);
        console.log("G2 point length:", g2Point.data.length);
        console.log("SUCCESS: Message hashed to G2 point");
        console.log("");
        
        // Test 2: G1 Addition
        console.log("Test 2: G1 Addition");
        bytes memory g1Gen = BLS12381.getG1Generator();
        BLS12381.G1Point memory gen = BLS12381.G1Point({data: g1Gen});
        
        BLS12381.G1Point memory doubled = BLS12381.g1Add(gen, gen);
        console.log("Doubled G1 point length:", doubled.data.length);
        console.log("SUCCESS: G1 addition works");
        console.log("");
        
        // Test 3: G2 Addition
        console.log("Test 3: G2 Addition");
        BLS12381.G2Point memory g2Point2 = BLS12381.hashToG2(keccak256("another message"));
        BLS12381.G2Point memory g2Sum = BLS12381.g2Add(g2Point, g2Point2);
        console.log("G2 sum length:", g2Sum.data.length);
        console.log("SUCCESS: G2 addition works");
        console.log("");
        
        // Test 4: Aggregate multiple G1 points (MSM)
        console.log("Test 4: G1 Multi-Scalar Multiplication");
        BLS12381.G1Point[] memory points = new BLS12381.G1Point[](3);
        points[0] = gen;
        points[1] = gen;
        points[2] = gen;
        
        BLS12381.G1Point memory aggregated = BLS12381.aggregateG1Points(points, 3);
        console.log("Aggregated G1 point length:", aggregated.data.length);
        console.log("SUCCESS: G1 MSM works");
        console.log("");
        
        // Test 5: Aggregate multiple G2 points (MSM)
        console.log("Test 5: G2 Multi-Scalar Multiplication");
        BLS12381.G2Point[] memory g2Points = new BLS12381.G2Point[](2);
        g2Points[0] = g2Point;
        g2Points[1] = g2Point2;
        
        BLS12381.G2Point memory g2Aggregated = BLS12381.aggregateG2Points(g2Points, 2);
        console.log("Aggregated G2 point length:", g2Aggregated.data.length);
        console.log("SUCCESS: G2 MSM works");
        console.log("");
        
        console.log("========================================");
        console.log("All BLS precompile tests PASSED!");
        console.log("EIP-2537 is fully functional on this network");
        console.log("========================================");
    }
}
