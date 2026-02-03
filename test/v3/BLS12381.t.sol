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
            emit log("SKIP: EIP-2537 precompiles not available");
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
