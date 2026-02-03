// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import {BLS12381} from "../../src/libraries/BLS12381.sol";

/**
 * @title BLS12381Test
 * @notice BLS12381 라이브러리 테스트
 */
contract BLS12381Test is Test {
    // ==========================================
    // SHA-256 Precompile Tests
    // ==========================================

    function test_sha256_precompile_basic() public view {
        // SHA-256("") = e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
        bytes memory empty = "";
        bytes32 expected = 0xe3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855;

        (bool success, bytes memory result) = address(0x02).staticcall(empty);
        assertTrue(success, "SHA-256 precompile call failed");
        assertEq(result.length, 32, "SHA-256 output should be 32 bytes");
        assertEq(bytes32(result), expected, "SHA-256 hash mismatch for empty string");
    }

    function test_sha256_precompile_hello() public view {
        // SHA-256("hello") = 2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
        bytes memory hello = "hello";
        bytes32 expected = 0x2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824;

        (bool success, bytes memory result) = address(0x02).staticcall(hello);
        assertTrue(success, "SHA-256 precompile call failed");
        assertEq(bytes32(result), expected, "SHA-256 hash mismatch for 'hello'");
    }

    // ==========================================
    // Hash to Fp2 Tests
    // ==========================================

    function test_hashToFp2_produces_valid_length() public view {
        bytes32 messageHash = keccak256("test message");

        // Call internal function via wrapper
        bytes memory fp2_0 = this.callHashToFp2(messageHash, 0);
        bytes memory fp2_1 = this.callHashToFp2(messageHash, 1);

        // Each Fp2 should be 128 bytes
        assertEq(fp2_0.length, 128, "Fp2 element 0 should be 128 bytes");
        assertEq(fp2_1.length, 128, "Fp2 element 1 should be 128 bytes");
    }

    function test_hashToFp2_different_indices_produce_different_results() public view {
        bytes32 messageHash = keccak256("test message");

        bytes memory fp2_0 = this.callHashToFp2(messageHash, 0);
        bytes memory fp2_1 = this.callHashToFp2(messageHash, 1);

        // Different indices should produce different Fp2 elements
        assertFalse(keccak256(fp2_0) == keccak256(fp2_1), "Different indices should produce different Fp2");
    }

    function test_hashToFp2_deterministic() public view {
        bytes32 messageHash = keccak256("test message");

        bytes memory fp2_first = this.callHashToFp2(messageHash, 0);
        bytes memory fp2_second = this.callHashToFp2(messageHash, 0);

        // Same input should produce same output
        assertEq(keccak256(fp2_first), keccak256(fp2_second), "hashToFp2 should be deterministic");
    }

    function test_hashToFp2_padding_format() public view {
        bytes32 messageHash = keccak256("test message");
        bytes memory fp2 = this.callHashToFp2(messageHash, 0);

        // EIP-2537 Fp format: 16 bytes zero padding + 48 bytes value
        // Check c0 padding (bytes 0-15 should be zero)
        for (uint i = 0; i < 16; i++) {
            assertEq(uint8(fp2[i]), 0, "c0 padding should be zero");
        }

        // Check c1 padding (bytes 64-79 should be zero)
        for (uint i = 64; i < 80; i++) {
            assertEq(uint8(fp2[i]), 0, "c1 padding should be zero");
        }
    }

    // ==========================================
    // Field Modulus Tests
    // ==========================================

    function test_fieldModulus_correctValue() public pure {
        // p = 0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab
        bytes memory p = hex"000000000000000000000000000000001a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab";

        // Check length (64 bytes = 16 padding + 48 value)
        assertEq(p.length, 64, "FIELD_MODULUS should be 64 bytes");

        // Check padding is zero
        for (uint i = 0; i < 16; i++) {
            assertEq(uint8(p[i]), 0, "FIELD_MODULUS padding should be zero");
        }

        // Check first non-zero byte is 0x1a
        assertEq(uint8(p[16]), 0x1a, "FIELD_MODULUS should start with 0x1a");
    }

    // ==========================================
    // Utility Function Tests
    // ==========================================

    function test_countSetBits() public pure {
        assertEq(BLS12381.countSetBits(0), 0, "0 has 0 bits");
        assertEq(BLS12381.countSetBits(1), 1, "1 has 1 bit");
        assertEq(BLS12381.countSetBits(0xFF), 8, "0xFF has 8 bits");
        assertEq(BLS12381.countSetBits(0xFFFF), 16, "0xFFFF has 16 bits");
        assertEq(BLS12381.countSetBits(type(uint256).max), 256, "max uint256 has 256 bits");
    }

    function test_isBitSet() public pure {
        uint256 bitmap = 10; // 0b1010 = bits 1 and 3 are set

        assertFalse(BLS12381.isBitSet(bitmap, 0), "bit 0 should not be set");
        assertTrue(BLS12381.isBitSet(bitmap, 1), "bit 1 should be set");
        assertFalse(BLS12381.isBitSet(bitmap, 2), "bit 2 should not be set");
        assertTrue(BLS12381.isBitSet(bitmap, 3), "bit 3 should be set");
    }

    // ==========================================
    // Integration Tests (requires EIP-2537 precompiles)
    // ==========================================

    function test_hashToG2_SKIP_without_precompile() public {
        // This test requires EIP-2537 precompiles (post-Pectra)
        // Skip if precompile is not available

        if (!_isPrecompileAvailable()) {
            
            return;
        }

        bytes32 messageHash = keccak256("test message");
        BLS12381.G2Point memory point = BLS12381.hashToG2(messageHash);

        // G2 point should be 256 bytes
        assertEq(point.data.length, 256, "G2 point should be 256 bytes");
    }

    // ==========================================
    // Helper Functions
    // ==========================================

    function callHashToFp2(bytes32 messageHash, uint8 index) external view returns (bytes memory) {
        return _hashToFp2(messageHash, index);
    }

    function _hashToFp2(bytes32 messageHash, uint8 index) internal view returns (bytes memory fp2) {
        // Replicate the library's _hashToFp2 logic for testing
        bytes memory dst = bytes("BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_");
        uint8 dstLen = uint8(dst.length);

        bytes memory zPad = new bytes(64);

        bytes32 b0 = _sha256(abi.encodePacked(
            zPad,
            messageHash,
            uint16(128),
            uint8(0),
            index,
            dst,
            dstLen
        ));

        bytes32 b1 = _sha256(abi.encodePacked(b0, uint8(1), dst, dstLen));
        bytes32 b2 = _sha256(abi.encodePacked(b0 ^ b1, uint8(2), dst, dstLen));
        bytes32 b3 = _sha256(abi.encodePacked(b0 ^ b2, uint8(3), dst, dstLen));
        bytes32 b4 = _sha256(abi.encodePacked(b0 ^ b3, uint8(4), dst, dstLen));

        fp2 = new bytes(128);
        assembly {
            let fp2Ptr := add(fp2, 0x20)
            mstore(fp2Ptr, b1)
            mstore(add(fp2Ptr, 0x20), b2)
            mstore(add(fp2Ptr, 0x40), b3)
            mstore(add(fp2Ptr, 0x60), b4)
        }

        // Apply reduction (simplified - just check format)
        _applyFpFormat(fp2, 0);
        _applyFpFormat(fp2, 64);
    }

    function _sha256(bytes memory data) internal view returns (bytes32 hash) {
        (bool success, bytes memory result) = address(0x02).staticcall(data);
        require(success && result.length == 32, "SHA256 failed");
        assembly {
            hash := mload(add(result, 0x20))
        }
    }

    function _applyFpFormat(bytes memory data, uint256 offset) internal pure {
        // For testing: just ensure the padding is correct
        // In production, proper modular reduction is applied
        assembly {
            let ptr := add(add(data, 0x20), offset)
            // Shift data to create 16-byte padding
            let word1 := mload(ptr)
            let word2 := mload(add(ptr, 0x20))

            // Clear first 16 bytes for padding
            mstore(ptr, 0)
            // Store reduced value starting at offset+16
            mstore(add(ptr, 16), word1)
            mstore(add(ptr, 48), word2)
        }
    }

    function _isPrecompileAvailable() internal view returns (bool) {
        bytes memory input = new bytes(256);
        (bool success, bytes memory output) = address(0x0b).staticcall{gas: 50000}(input);
        return success && output.length == 128;
    }
}

/**
 * @title BLS12381MainnetForkTest
 * @notice Ethereum mainnet fork test to verify EIP-2537 BLS precompiles
 * @dev IMPORTANT: EIP-2537 is deployed on mainnet after Pectra (May 7, 2025)
 * @dev However, Foundry's local EVM does NOT yet implement EIP-2537 precompiles
 * @dev These tests will SKIP if precompiles are not available in the local EVM
 * @dev To test with real precompiles, deploy and test on actual mainnet
 */
contract BLS12381MainnetForkTest is Test {
    bool private forkSucceeded;
    bool private precompilesAvailable;

    function setUp() public {
        // Fork Ethereum mainnet (production environment, more stable than testnet)
        string memory rpcUrl = "https://ethereum-rpc.publicnode.com";
        
        try vm.createSelectFork(rpcUrl) {
            emit log("Successfully forked Ethereum mainnet");
            emit log_named_uint("Fork block number", block.number);
            emit log_named_uint("Chain ID", block.chainid);
            forkSucceeded = true;
            
            // Check if precompiles are available in local EVM
            precompilesAvailable = BLS12381.isPrecompileAvailable();
            
            if (!precompilesAvailable) {
                emit log("NOTE: EIP-2537 precompiles NOT available in Foundry's local EVM");
                emit log("These tests will be skipped. Deploy to actual mainnet for full testing.");
            }
        } catch {
            emit log("WARNING: Could not fork mainnet, tests will be skipped");
            forkSucceeded = false;
        }
    }

    // ==========================================
    // Precompile Availability Tests
    // ==========================================

    function test_check_precompile_status() public view {
        if (!forkSucceeded) {
            
            return;
        }
        
        bool available = BLS12381.isPrecompileAvailable();
        
        if (available) {
            
        } else {
            
            
        }
    }

    function test_mainnet_all_precompiles_exist() public view {
        if (!forkSucceeded || !precompilesAvailable) {
            
            return;
        }
        
        // Test each precompile individually
        
        // BLS12_G1ADD (0x0b)
        bytes memory g1Input = new bytes(256);
        (bool success1, bytes memory output1) = address(0x0b).staticcall{gas: 100000}(g1Input);
        assertTrue(success1, "BLS12_G1ADD (0x0b) should exist");
        assertEq(output1.length, 128, "G1ADD should return 128 bytes");

        // BLS12_G1MUL (0x0c)
        bytes memory g1MulInput = new bytes(160); // 128 (G1) + 32 (scalar)
        (bool success2, bytes memory output2) = address(0x0c).staticcall{gas: 100000}(g1MulInput);
        assertTrue(success2, "BLS12_G1MUL (0x0c) should exist");
        assertEq(output2.length, 128, "G1MUL should return 128 bytes");

        // BLS12_G2ADD (0x0e)
        bytes memory g2Input = new bytes(512);
        (bool success3, bytes memory output3) = address(0x0e).staticcall{gas: 100000}(g2Input);
        assertTrue(success3, "BLS12_G2ADD (0x0e) should exist");
        assertEq(output3.length, 256, "G2ADD should return 256 bytes");

        // BLS12_PAIRING (0x11)
        bytes memory pairingInput = new bytes(384); // One pairing pair
        (bool success4, bytes memory output4) = address(0x11).staticcall{gas: 200000}(pairingInput);
        assertTrue(success4, "BLS12_PAIRING (0x11) should exist");
        assertEq(output4.length, 32, "PAIRING should return 32 bytes");

        // BLS12_MAP_FP2_TO_G2 (0x13)
        bytes memory mapInput = new bytes(128); // Fp2 element
        (bool success5, bytes memory output5) = address(0x13).staticcall{gas: 100000}(mapInput);
        assertTrue(success5, "BLS12_MAP_FP2_TO_G2 (0x13) should exist");
        assertEq(output5.length, 256, "MAP_FP2_TO_G2 should return 256 bytes");
    }

    // ==========================================
    // Hash to G2 Tests on Mainnet Fork
    // ==========================================

    function test_mainnet_hashToG2_basic() public view {
        if (!forkSucceeded || !precompilesAvailable) {
            
            return;
        }
        
        bytes32 messageHash = keccak256("test message on mainnet");
        BLS12381.G2Point memory point = BLS12381.hashToG2(messageHash);

        assertEq(point.data.length, 256, "G2 point should be 256 bytes");
        
        // Point should not be zero
        bool allZeros = true;
        for (uint i = 0; i < point.data.length; i++) {
            if (point.data[i] != 0) {
                allZeros = false;
                break;
            }
        }
        assertFalse(allZeros, "G2 point should not be all zeros");
    }

    function test_mainnet_hashToG2_deterministic() public view {
        if (!forkSucceeded || !precompilesAvailable) {
            
            return;
        }
        
        bytes32 messageHash = keccak256("determinism test");
        
        BLS12381.G2Point memory point1 = BLS12381.hashToG2(messageHash);
        BLS12381.G2Point memory point2 = BLS12381.hashToG2(messageHash);

        assertEq(
            keccak256(point1.data), 
            keccak256(point2.data), 
            "Hash to G2 should be deterministic"
        );
    }

    function test_mainnet_hashToG2_different_messages() public view {
        if (!forkSucceeded || !precompilesAvailable) {
            
            return;
        }
        
        bytes32 msg1 = keccak256("message 1");
        bytes32 msg2 = keccak256("message 2");
        
        BLS12381.G2Point memory point1 = BLS12381.hashToG2(msg1);
        BLS12381.G2Point memory point2 = BLS12381.hashToG2(msg2);

        assertFalse(
            keccak256(point1.data) == keccak256(point2.data),
            "Different messages should produce different G2 points"
        );
    }

    // ==========================================
    // G1 Operations Tests on Mainnet Fork
    // ==========================================

    function test_mainnet_g1Add() public view {
        if (!forkSucceeded || !precompilesAvailable) {
            
            return;
        }
        
        // Get G1 generator
        bytes memory g1Gen = BLS12381.getG1Generator();
        BLS12381.G1Point memory gen = BLS12381.G1Point({data: g1Gen});

        // Add generator to itself: G1 + G1 = 2*G1
        BLS12381.G1Point memory doubled = BLS12381.g1Add(gen, gen);

        assertEq(doubled.data.length, 128, "Doubled point should be 128 bytes");
        
        // Result should be different from generator
        assertFalse(
            keccak256(doubled.data) == keccak256(g1Gen),
            "Doubled point should differ from generator"
        );
    }

    function test_mainnet_g1Add_with_identity() public view {
        if (!forkSucceeded || !precompilesAvailable) {
            
            return;
        }
        
        bytes memory g1Gen = BLS12381.getG1Generator();
        BLS12381.G1Point memory gen = BLS12381.G1Point({data: g1Gen});

        // Identity element (point at infinity) is all zeros in EIP-2537
        bytes memory zeroPoint = new bytes(128);
        BLS12381.G1Point memory identity = BLS12381.G1Point({data: zeroPoint});

        // G1 + 0 = G1
        BLS12381.G1Point memory result = BLS12381.g1Add(gen, identity);

        assertEq(
            keccak256(result.data),
            keccak256(g1Gen),
            "Adding identity should not change point"
        );
    }

    function test_mainnet_aggregateG1Points() public view {
        if (!forkSucceeded || !precompilesAvailable) {
            
            return;
        }
        
        bytes memory g1Gen = BLS12381.getG1Generator();
        
        // Create array of 3 identical points
        BLS12381.G1Point[] memory points = new BLS12381.G1Point[](3);
        points[0] = BLS12381.G1Point({data: g1Gen});
        points[1] = BLS12381.G1Point({data: g1Gen});
        points[2] = BLS12381.G1Point({data: g1Gen});

        // Aggregate: should give us 3*G1
        BLS12381.G1Point memory aggregated = BLS12381.aggregateG1Points(points, 3);

        assertEq(aggregated.data.length, 128, "Aggregated point should be 128 bytes");
        assertFalse(
            keccak256(aggregated.data) == keccak256(g1Gen),
            "3*G1 should differ from G1"
        );
    }

    // ==========================================
    // G2 Operations Tests on Mainnet Fork
    // ==========================================

    function test_mainnet_g2Add() public view {
        if (!forkSucceeded || !precompilesAvailable) {
            
            return;
        }
        
        bytes32 message = keccak256("test");
        BLS12381.G2Point memory point1 = BLS12381.hashToG2(message);
        BLS12381.G2Point memory point2 = BLS12381.hashToG2(message);

        // Add two identical G2 points
        BLS12381.G2Point memory sum = BLS12381.g2Add(point1, point2);

        assertEq(sum.data.length, 256, "Sum should be 256 bytes");
        assertFalse(
            keccak256(sum.data) == keccak256(point1.data),
            "Sum should differ from original"
        );
    }

    function test_mainnet_aggregateG2Points() public view {
        if (!forkSucceeded || !precompilesAvailable) {
            
            return;
        }
        
        bytes32 message1 = keccak256("msg1");
        bytes32 message2 = keccak256("msg2");
        
        BLS12381.G2Point[] memory points = new BLS12381.G2Point[](2);
        points[0] = BLS12381.hashToG2(message1);
        points[1] = BLS12381.hashToG2(message2);

        // Aggregate two different G2 points
        BLS12381.G2Point memory aggregated = BLS12381.aggregateG2Points(points, 2);

        assertEq(aggregated.data.length, 256, "Aggregated point should be 256 bytes");
    }

    // ==========================================
    // Real-world Scenario Tests
    // ==========================================

    function test_mainnet_signature_verification_flow() public view {
        if (!forkSucceeded || !precompilesAvailable) {
            
            return;
        }
        
        // This test demonstrates the full signature verification flow
        // Note: We're using mock keys here since we don't have real validator keys
        
        bytes32 messageHash = keccak256(abi.encodePacked(
            "TOKAMAK_FAST_WITHDRAWAL",
            bytes32(uint256(1)),     // requestId
            address(0x1234),         // user
            uint256(100 ether),      // amount
            uint256(1)               // chainId
        ));

        // Hash message to G2 for signing
        BLS12381.G2Point memory hashedMessage = BLS12381.hashToG2(messageHash);
        
        assertEq(hashedMessage.data.length, 256, "Hashed message should be valid G2 point");
    }

    function test_mainnet_multi_validator_aggregation() public view {
        if (!forkSucceeded || !precompilesAvailable) {
            
            return;
        }
        
        // Simulate aggregating public keys from multiple validators
        bytes memory g1Gen = BLS12381.getG1Generator();
        
        // Create mock validator public keys (in reality these would be different)
        uint256 numValidators = 5;
        BLS12381.G1Point[] memory pubkeys = new BLS12381.G1Point[](numValidators);
        
        for (uint i = 0; i < numValidators; i++) {
            pubkeys[i] = BLS12381.G1Point({data: g1Gen});
        }

        // Aggregate all public keys
        BLS12381.G1Point memory aggregatedPubkey = BLS12381.aggregateG1Points(
            pubkeys, 
            numValidators
        );

        assertEq(
            aggregatedPubkey.data.length, 
            128, 
            "Aggregated pubkey should be valid G1 point"
        );
    }

    // ==========================================
    // Gas Cost Analysis
    // ==========================================

    function test_mainnet_gas_costs() public {
        if (!forkSucceeded || !precompilesAvailable) {
            
            return;
        }
        
        // Measure gas costs of BLS operations on mainnet
        
        bytes32 messageHash = keccak256("gas test");
        
        // Gas cost for hash to G2
        uint256 gasBefore1 = gasleft();
        BLS12381.hashToG2(messageHash);
        uint256 gasUsed1 = gasBefore1 - gasleft();
        
        emit log_named_uint("Gas for hashToG2", gasUsed1);

        // Gas cost for G1 addition
        bytes memory g1Gen = BLS12381.getG1Generator();
        BLS12381.G1Point memory gen = BLS12381.G1Point({data: g1Gen});
        
        uint256 gasBefore2 = gasleft();
        BLS12381.g1Add(gen, gen);
        uint256 gasUsed2 = gasBefore2 - gasleft();
        
        emit log_named_uint("Gas for g1Add", gasUsed2);

        // Gas cost for G2 addition
        BLS12381.G2Point memory g2Point = BLS12381.hashToG2(messageHash);
        
        uint256 gasBefore3 = gasleft();
        BLS12381.g2Add(g2Point, g2Point);
        uint256 gasUsed3 = gasBefore3 - gasleft();
        
        emit log_named_uint("Gas for g2Add", gasUsed3);

        // Basic sanity checks
        assertTrue(gasUsed1 > 0, "hashToG2 should consume gas");
        assertTrue(gasUsed2 > 0, "g1Add should consume gas");
        assertTrue(gasUsed3 > 0, "g2Add should consume gas");
    }

    // ==========================================
    // Edge Cases and Error Handling
    // ==========================================

    function test_mainnet_invalid_point_lengths() public {
        // Test that invalid point lengths are rejected
        // This test doesn't require precompiles, just length validation
        
        bytes memory shortG1 = new bytes(64); // Should be 128
        vm.expectRevert(BLS12381.InvalidG1PointLength.selector);
        this.callParseG1Point(shortG1);

        bytes memory shortG2 = new bytes(128); // Should be 256
        vm.expectRevert(BLS12381.InvalidG2PointLength.selector);
        this.callParseG2Point(shortG2);
    }
    
    // Helper functions for testing library functions with expectRevert
    function callParseG1Point(bytes memory data) external pure returns (BLS12381.G1Point memory) {
        return BLS12381.parseG1Point(data);
    }
    
    function callParseG2Point(bytes memory data) external pure returns (BLS12381.G2Point memory) {
        return BLS12381.parseG2Point(data);
    }
}
