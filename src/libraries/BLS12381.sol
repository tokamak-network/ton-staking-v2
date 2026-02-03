// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title BLS12381
 * @notice BLS12-381 signature verification library using EIP-2537 precompiles
 * @dev Reference: https://eips.ethereum.org/EIPS/eip-2537
 *
 * EIP-2537 Precompile Addresses (Pectra upgrade):
 * - BLS12_G1ADD:         0x0b (11)
 * - BLS12_G1MUL:         0x0c (12)
 * - BLS12_G1MSM:         0x0d (13)
 * - BLS12_G2ADD:         0x0e (14)
 * - BLS12_G2MUL:         0x0f (15)
 * - BLS12_G2MSM:         0x10 (16)
 * - BLS12_PAIRING:       0x11 (17)
 * - BLS12_MAP_FP_TO_G1:  0x12 (18)
 * - BLS12_MAP_FP2_TO_G2: 0x13 (19)
 *
 * Point Formats (EIP-2537 uses uncompressed points):
 * - G1: 128 bytes (64 bytes x + 64 bytes y, each zero-padded to 64 bytes)
 * - G2: 256 bytes (128 bytes x + 128 bytes y, each coordinate is Fp2)
 * - Fp element: 64 bytes (48-byte value zero-padded to 64 bytes)
 * - Fp2 element: 128 bytes (two Fp elements: c0 + c1*i)
 */
library BLS12381 {
    // ==========================================
    // Constants - Point Sizes
    // ==========================================

    /// @notice G1 point size (uncompressed) for EIP-2537: 128 bytes
    uint256 internal constant G1_POINT_SIZE = 128;

    /// @notice G2 point size (uncompressed) for EIP-2537: 256 bytes
    uint256 internal constant G2_POINT_SIZE = 256;

    /// @notice Fp element size: 64 bytes (48-byte value padded)
    uint256 internal constant FP_SIZE = 64;

    /// @notice Fp2 element size: 128 bytes (two Fp elements)
    uint256 internal constant FP2_SIZE = 128;

    // ==========================================
    // Constants - Precompile Addresses
    // ==========================================

    /// @notice BLS12_G1ADD precompile address
    address internal constant BLS12_G1ADD = address(0x0b);

    /// @notice BLS12_G1MUL precompile address
    address internal constant BLS12_G1MUL = address(0x0c);

    /// @notice BLS12_G1MSM precompile address (multi-scalar multiplication)
    address internal constant BLS12_G1MSM = address(0x0d);

    /// @notice BLS12_G2ADD precompile address
    address internal constant BLS12_G2ADD = address(0x0e);

    /// @notice BLS12_G2MUL precompile address
    address internal constant BLS12_G2MUL = address(0x0f);

    /// @notice BLS12_G2MSM precompile address
    address internal constant BLS12_G2MSM = address(0x10);

    /// @notice BLS12_PAIRING precompile address
    address internal constant BLS12_PAIRING = address(0x11);

    /// @notice BLS12_MAP_FP_TO_G1 precompile address
    address internal constant BLS12_MAP_FP_TO_G1 = address(0x12);

    /// @notice BLS12_MAP_FP2_TO_G2 precompile address
    address internal constant BLS12_MAP_FP2_TO_G2 = address(0x13);

    /// @notice SHA-256 precompile address
    address internal constant SHA256_PRECOMPILE = address(0x02);

    // ==========================================
    // Constants - BLS12-381 Curve Parameters
    // ==========================================

    /// @notice BLS12-381 field modulus p (48 bytes, padded to 64 bytes)
    /// p = 0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab
    bytes internal constant FIELD_MODULUS = hex"000000000000000000000000000000001a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab";

    /// @notice G1 Generator x-coordinate (48 bytes value, 16 bytes padding = 64 bytes total)
    /// x = 0x17f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb
    bytes internal constant G1_GENERATOR_X = hex"0000000000000000000000000000000017f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb";

    /// @notice G1 Generator y-coordinate (48 bytes value, 16 bytes padding = 64 bytes total)
    /// y = 0x08b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1
    bytes internal constant G1_GENERATOR_Y = hex"0000000000000000000000000000000008b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1";

    /// @notice G1 Generator y-coordinate negated (p - y) for pairing verification
    /// @dev -y = 0x114d1d68560455a8ab7d76c8cf2e21f267816aee1db5079f66559cd5caac424f4e6f38ba8ecb715eb354dcd6b995c2ca
    bytes internal constant G1_GENERATOR_NEG_Y = hex"00000000000000000000000000000000114d1d68560455a8ab7d76c8cf2e21f267816aee1db5079f66559cd5caac424f4e6f38ba8ecb715eb354dcd6b995c2ca";

    /// @notice Negative G1 generator (precomputed for pairing)
    /// @dev Cached to avoid repeated encodePacked calls
    bytes internal constant NEG_G1_GENERATOR = hex"0000000000000000000000000000000017f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb00000000000000000000000000000000114d1d68560455a8ab7d76c8cf2e21f267816aee1db5079f66559cd5caac424f4e6f38ba8ecb715eb354dcd6b995c2ca";

    // ==========================================
    // Errors
    // ==========================================

    error InvalidG1PointLength();
    error InvalidG2PointLength();
    error G1AdditionFailed();
    error G2AdditionFailed();
    error PairingCheckFailed();
    error MapToG2Failed();
    error InvalidPointsCount();
    error PrecompileCallFailed();
    error PrecompileNotAvailable();
    error InvalidFieldElement();

    // ==========================================
    // Structs
    // ==========================================

    /// @notice G1 point (public key) - 128 bytes uncompressed
    struct G1Point {
        bytes data;
    }

    /// @notice G2 point (signature) - 256 bytes uncompressed
    struct G2Point {
        bytes data;
    }

    // ==========================================
    // G1 Point Operations
    // ==========================================

    /**
     * @notice Parse and validate G1 point
     * @param data 128 bytes uncompressed G1 point
     * @return G1Point struct
     */
    function parseG1Point(bytes memory data) internal pure returns (G1Point memory) {
        if (data.length != G1_POINT_SIZE) revert InvalidG1PointLength();
        return G1Point({data: data});
    }

    /**
     * @notice Validate G1 point length
     * @param point G1 point to validate
     * @return true if valid length
     */
    function isValidG1Point(G1Point memory point) internal pure returns (bool) {
        return point.data.length == G1_POINT_SIZE;
    }

    /**
     * @notice Add two G1 points using BLS12_G1ADD precompile
     * @param a First G1 point (128 bytes)
     * @param b Second G1 point (128 bytes)
     * @return result Sum of a and b (128 bytes)
     */
    function g1Add(G1Point memory a, G1Point memory b) internal view returns (G1Point memory result) {
        bytes memory input = abi.encodePacked(a.data, b.data);

        (bool success, bytes memory output) = BLS12_G1ADD.staticcall(input);
        if (!success || output.length != G1_POINT_SIZE) revert G1AdditionFailed();

        result.data = output;
    }

    /**
     * @notice Aggregate multiple G1 points using multi-scalar multiplication
     * @dev Uses BLS12_G1MSM for efficient aggregation
     * @param points Array of G1 points to aggregate
     * @param count Number of points to aggregate
     * @return aggregated Aggregated G1 point
     */
    function aggregateG1Points(
        G1Point[] memory points,
        uint256 count
    ) internal view returns (G1Point memory aggregated) {
        if (count == 0) revert InvalidPointsCount();
        if (count == 1) return points[0];

        // For aggregation, we use scalar = 1 for each point
        // MSM input: (point_1, scalar_1, point_2, scalar_2, ...)
        // Each scalar is 32 bytes
        // Pre-allocate exact size to avoid reallocation
        uint256 inputSize = count * (G1_POINT_SIZE + 32);
        bytes memory input = new bytes(inputSize);
        bytes32 one = bytes32(uint256(1));
        
        uint256 offset;
        unchecked {
            for (uint256 i = 0; i < count; ++i) {
                bytes memory pointData = points[i].data;
                
                // Copy point (128 bytes)
                assembly {
                    let src := add(pointData, 0x20)
                    let dst := add(add(input, 0x20), offset)
                    
                    // Copy in 32-byte chunks
                    mstore(dst, mload(src))
                    mstore(add(dst, 0x20), mload(add(src, 0x20)))
                    mstore(add(dst, 0x40), mload(add(src, 0x40)))
                    mstore(add(dst, 0x60), mload(add(src, 0x60)))
                }
                offset += G1_POINT_SIZE;
                
                // Copy scalar (32 bytes)
                assembly {
                    mstore(add(add(input, 0x20), offset), one)
                }
                offset += 32;
            }
        }

        (bool success, bytes memory output) = BLS12_G1MSM.staticcall(input);
        if (!success || output.length != G1_POINT_SIZE) revert G1AdditionFailed();

        aggregated.data = output;
    }

    // ==========================================
    // G2 Point Operations
    // ==========================================

    /**
     * @notice Parse and validate G2 point
     * @param data 256 bytes uncompressed G2 point
     * @return G2Point struct
     */
    function parseG2Point(bytes memory data) internal pure returns (G2Point memory) {
        if (data.length != G2_POINT_SIZE) revert InvalidG2PointLength();
        return G2Point({data: data});
    }

    /**
     * @notice Validate G2 point length
     * @param point G2 point to validate
     * @return true if valid length
     */
    function isValidG2Point(G2Point memory point) internal pure returns (bool) {
        return point.data.length == G2_POINT_SIZE;
    }

    /**
     * @notice Add two G2 points using BLS12_G2ADD precompile
     * @param a First G2 point (256 bytes)
     * @param b Second G2 point (256 bytes)
     * @return result Sum of a and b (256 bytes)
     */
    function g2Add(G2Point memory a, G2Point memory b) internal view returns (G2Point memory result) {
        bytes memory input = abi.encodePacked(a.data, b.data);

        (bool success, bytes memory output) = BLS12_G2ADD.staticcall(input);
        if (!success || output.length != G2_POINT_SIZE) revert G2AdditionFailed();

        result.data = output;
    }

    /**
     * @notice Aggregate multiple G2 points (signatures)
     * @dev Uses BLS12_G2MSM for efficient aggregation
     * @param signatures Array of G2 points to aggregate
     * @param count Number of signatures to aggregate
     * @return aggregated Aggregated G2 point
     */
    function aggregateG2Points(
        G2Point[] memory signatures,
        uint256 count
    ) internal view returns (G2Point memory aggregated) {
        if (count == 0) revert InvalidPointsCount();
        if (count == 1) return signatures[0];

        // MSM input format: (point_1, scalar_1, point_2, scalar_2, ...)
        // Pre-allocate exact size to avoid reallocation
        uint256 inputSize = count * (G2_POINT_SIZE + 32);
        bytes memory input = new bytes(inputSize);
        bytes32 one = bytes32(uint256(1));
        
        uint256 offset;
        unchecked {
            for (uint256 i = 0; i < count; ++i) {
                bytes memory sigData = signatures[i].data;
                
                // Copy signature (256 bytes)
                assembly {
                    let src := add(sigData, 0x20)
                    let dst := add(add(input, 0x20), offset)
                    
                    // Copy in 32-byte chunks (8 chunks for 256 bytes)
                    for { let j := 0 } lt(j, 8) { j := add(j, 1) } {
                        mstore(add(dst, mul(j, 0x20)), mload(add(src, mul(j, 0x20))))
                    }
                }
                offset += G2_POINT_SIZE;
                
                // Copy scalar (32 bytes)
                assembly {
                    mstore(add(add(input, 0x20), offset), one)
                }
                offset += 32;
            }
        }

        (bool success, bytes memory output) = BLS12_G2MSM.staticcall(input);
        if (!success || output.length != G2_POINT_SIZE) revert G2AdditionFailed();

        aggregated.data = output;
    }

    // ==========================================
    // Signature Verification
    // ==========================================

    /**
     * @notice Verify BLS signature using pairing check
     * @dev Verifies: e(pubkey, H(m)) == e(G1, signature)
     * @dev Equivalent: e(pubkey, H(m)) * e(-G1, signature) == 1
     * @param pubkey BLS public key (G1 point, 128 bytes)
     * @param signature BLS signature (G2 point, 256 bytes)
     * @param messageHash Message hash to verify
     * @return valid True if signature is valid
     */
    function verifySignature(
        G1Point memory pubkey,
        G2Point memory signature,
        bytes32 messageHash
    ) internal view returns (bool valid) {
        // Check precompile availability
        if (!isPrecompileAvailable()) revert PrecompileNotAvailable();
        
        // Hash message to G2 point
        G2Point memory hashedMessage = hashToG2(messageHash);

        // Verify pairing
        return _verifyPairing(pubkey, hashedMessage, signature);
    }

    /**
     * @notice Verify aggregated BLS signature
     * @dev All signers must have signed the same message
     * @param aggregatedPubkey Aggregated public key (G1 point)
     * @param aggregatedSignature Aggregated signature (G2 point)
     * @param messageHash Message hash that was signed
     * @return valid True if aggregated signature is valid
     */
    function verifyAggregatedSignature(
        G1Point memory aggregatedPubkey,
        G2Point memory aggregatedSignature,
        bytes32 messageHash
    ) internal view returns (bool valid) {
        // Check precompile availability
        if (!isPrecompileAvailable()) revert PrecompileNotAvailable();
        
        G2Point memory hashedMessage = hashToG2(messageHash);
        return _verifyPairing(aggregatedPubkey, hashedMessage, aggregatedSignature);
    }

    /**
     * @notice Verify aggregated BLS signature (bytes interface)
     * @dev Wrapper for RAT contract compatibility
     * @param aggregatedPubkey Aggregated BLS public key (128 bytes)
     * @param messageHash 32 bytes message hash
     * @param aggregatedSignature Aggregated BLS signature (256 bytes)
     * @return valid True if aggregated signature is valid
     */
    function verifyAggregatedSignature(
        bytes memory aggregatedPubkey,
        bytes32 messageHash,
        bytes calldata aggregatedSignature
    ) internal view returns (bool valid) {
        if (aggregatedPubkey.length != G1_POINT_SIZE) revert InvalidG1PointLength();
        if (aggregatedSignature.length != G2_POINT_SIZE) revert InvalidG2PointLength();

        G1Point memory pubkey = G1Point({data: aggregatedPubkey});
        G2Point memory sig = G2Point({data: aggregatedSignature});

        return verifyAggregatedSignature(pubkey, sig, messageHash);
    }

    /**
     * @notice Internal pairing verification
     * @dev Checks: e(P1, Q1) * e(P2, Q2) == 1
     * @dev For signature: e(pubkey, H(m)) * e(-G1, signature) == 1
     * @param pubkey Public key (G1)
     * @param hashedMessage Hashed message (G2)
     * @param signature Signature (G2)
     * @return True if pairing check passes
     */
    function _verifyPairing(
        G1Point memory pubkey,
        G2Point memory hashedMessage,
        G2Point memory signature
    ) internal view returns (bool) {
        // Get negative G1 generator
        bytes memory negG1Gen = _getNegativeG1Generator();

        // Pairing input: (P1, Q1, P2, Q2)
        // P1 = pubkey (G1), Q1 = hashedMessage (G2)
        // P2 = -G1_generator (G1), Q2 = signature (G2)
        bytes memory input = abi.encodePacked(
            pubkey.data,      // 128 bytes
            hashedMessage.data, // 256 bytes
            negG1Gen,         // 128 bytes
            signature.data    // 256 bytes
        );

        (bool success, bytes memory output) = BLS12_PAIRING.staticcall(input);
        if (!success) revert PairingCheckFailed();

        // Output is 32 bytes: 1 if pairing product is identity, 0 otherwise
        return output.length == 32 && uint256(bytes32(output)) == 1;
    }

    // ==========================================
    // Hash to Curve (RFC 9380)
    // ==========================================

    /**
     * @notice Hash message to G2 point using BLS12_MAP_FP2_TO_G2
     * @dev Implements simplified hash-to-curve following RFC 9380 structure
     * @param messageHash 32 bytes message hash
     * @return G2 point
     */
    function hashToG2(bytes32 messageHash) internal view returns (G2Point memory) {
        // Expand message to two Fp2 elements (256 bytes total)
        // Each Fp2 element is 128 bytes (two 64-byte Fp elements)
        bytes memory u0 = _hashToFp2(messageHash, 0);
        bytes memory u1 = _hashToFp2(messageHash, 1);

        // Map each Fp2 element to G2
        (bool success0, bytes memory q0) = BLS12_MAP_FP2_TO_G2.staticcall(u0);
        if (!success0) revert MapToG2Failed();

        (bool success1, bytes memory q1) = BLS12_MAP_FP2_TO_G2.staticcall(u1);
        if (!success1) revert MapToG2Failed();

        // Add the two G2 points
        G2Point memory p0 = G2Point({data: q0});
        G2Point memory p1 = G2Point({data: q1});

        return g2Add(p0, p1);
    }

    /**
     * @notice Hash to Fp2 element for hash-to-curve using XMD-SHA256
     * @dev Implements RFC 9380 expand_message_xmd with SHA-256 precompile
     * @dev Produces a 128-byte Fp2 element (two 64-byte Fp elements)
     * @param messageHash Message to hash
     * @param index Index for domain separation (0 or 1)
     * @return fp2 128 bytes Fp2 element
     */
    function _hashToFp2(bytes32 messageHash, uint8 index) internal view returns (bytes memory fp2) {
        // DST for BLS12-381 G2 hash-to-curve (RFC 9380)
        bytes memory dst = bytes("BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_");
        uint8 dstLen = uint8(dst.length); // 39 bytes

        // RFC 9380 expand_message_xmd algorithm:
        // We need 64 bytes per Fp element for proper reduction
        // Total: 128 bytes = 4 blocks of 32 bytes (SHA-256 output)

        // Z_pad = I2OSP(0, s_in_bytes) where s_in_bytes = 64 for SHA-256
        bytes memory zPad = new bytes(64);

        // l_i_b_str = I2OSP(len_in_bytes, 2) = I2OSP(128, 2) = 0x0080
        // DST_prime = DST || I2OSP(len(DST), 1)

        // b_0 = SHA256(Z_pad || msg || l_i_b_str || 0x00 || index || DST_prime)
        bytes32 b0 = _sha256(abi.encodePacked(
            zPad,
            messageHash,
            uint16(128),  // l_i_b_str (big-endian)
            uint8(0),
            index,
            dst,
            dstLen
        ));

        // b_1 = SHA256(b_0 || 0x01 || DST_prime)
        bytes32 b1 = _sha256(abi.encodePacked(b0, uint8(1), dst, dstLen));

        // b_2 = SHA256(b_0 XOR b_1 || 0x02 || DST_prime)
        bytes32 b2 = _sha256(abi.encodePacked(b0 ^ b1, uint8(2), dst, dstLen));

        // b_3 = SHA256(b_0 XOR b_2 || 0x03 || DST_prime)
        bytes32 b3 = _sha256(abi.encodePacked(b0 ^ b2, uint8(3), dst, dstLen));

        // b_4 = SHA256(b_0 XOR b_3 || 0x04 || DST_prime)
        bytes32 b4 = _sha256(abi.encodePacked(b0 ^ b3, uint8(4), dst, dstLen));

        // uniform_bytes = b_1 || b_2 || b_3 || b_4 (128 bytes)
        // Split into two 64-byte chunks for Fp elements

        // Allocate result
        fp2 = new bytes(FP2_SIZE);

        // Store uniform bytes: b1 || b2 || b3 || b4
        assembly {
            let fp2Ptr := add(fp2, 0x20)
            mstore(fp2Ptr, b1)
            mstore(add(fp2Ptr, 0x20), b2)
            mstore(add(fp2Ptr, 0x40), b3)
            mstore(add(fp2Ptr, 0x60), b4)
        }

        // Convert to proper Fp2 format with modular reduction
        // Each Fp: reduce 64-byte value mod p, then format as 16-byte padding + 48-byte value
        _reduceToFpFormat(fp2, 0);   // Process c0 (bytes 0-63)
        _reduceToFpFormat(fp2, 64);  // Process c1 (bytes 64-127)
    }

    /**
     * @notice Call SHA-256 precompile
     * @param data Input data to hash
     * @return hash SHA-256 hash result (32 bytes)
     */
    function _sha256(bytes memory data) internal view returns (bytes32 hash) {
        (bool success, bytes memory result) = SHA256_PRECOMPILE.staticcall(data);
        if (!success || result.length != 32) revert PrecompileCallFailed();
        assembly {
            hash := mload(add(result, 0x20))
        }
    }

    /**
     * @notice Reduce 64-byte value mod p and reformat to EIP-2537 Fp format
     * @dev Takes 64 bytes at offset, reduces mod p, stores as 16-byte padding + 48-byte value
     * @param data The data array (modified in place)
     * @param offset Starting offset (0 or 64)
     */
    function _reduceToFpFormat(bytes memory data, uint256 offset) internal pure {
        // Extract 64 bytes as two 256-bit words (big-endian)
        bytes32 hi;
        bytes32 lo;
        assembly {
            let ptr := add(add(data, 0x20), offset)
            hi := mload(ptr)
            lo := mload(add(ptr, 0x20))
        }

        // Reduce (hi * 2^256 + lo) mod p
        // Since p is ~381 bits and our input is 512 bits, we need proper reduction
        //
        // We use the identity: value mod p = (hi * (2^256 mod p) + lo) mod p
        // 2^256 mod p = 0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001
        // (precomputed constant)

        // For efficiency, we implement Barrett-like reduction inline
        bytes memory reduced = _mod512BitByP(hi, lo);

        // Copy reduced 48 bytes to output with 16-byte zero padding
        assembly {
            let dstPtr := add(add(data, 0x20), offset)
            let srcPtr := add(reduced, 0x20)

            // Clear first 16 bytes (zero padding)
            mstore(dstPtr, 0)

            // Copy 48 bytes of reduced value
            // reduced is 48 bytes, we need to copy it starting at offset+16
            // Copy bytes 0-31 of reduced to dst+16
            let word1 := mload(srcPtr)
            mstore(add(dstPtr, 16), word1)

            // Copy bytes 32-47 of reduced to dst+48
            // Only need 16 bytes, but mstore writes 32
            // The extra 16 bytes will be overwritten by next Fp or are beyond array
            let word2 := mload(add(srcPtr, 32))
            mstore(add(dstPtr, 48), word2)
        }
    }

    /**
     * @notice Compute (hi * 2^256 + lo) mod p for 512-bit input
     * @dev Uses optimized reduction for BLS12-381 field
     * @param hi Upper 256 bits
     * @param lo Lower 256 bits
     * @return result 48-byte result (mod p)
     */
    function _mod512BitByP(bytes32 hi, bytes32 lo) internal pure returns (bytes memory result) {
        result = new bytes(48);

        // p = 0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab
        //
        // For a 512-bit value v = hi * 2^256 + lo:
        // v mod p = ((hi mod p) * (2^256 mod p) + (lo mod p)) mod p
        //
        // 2^256 mod p = 0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001
        //
        // Since hi and lo are each 256 bits and p is ~381 bits:
        // - If hi == 0: result = lo mod p (simple comparison and subtraction)
        // - If hi != 0: need full modular multiplication

        if (hi == bytes32(0)) {
            // Simple case: just reduce lo mod p
            _reduceSingleWord(lo, result);
        } else {
            // Full reduction using the formula:
            // result = (hi * R + lo) mod p where R = 2^256 mod p
            _reduceFullValue(hi, lo, result);
        }
    }

    /**
     * @notice Reduce a single 256-bit word mod p
     * @param value 256-bit value to reduce
     * @param result Output buffer (48 bytes)
     */
    function _reduceSingleWord(bytes32 value, bytes memory result) internal pure {
        // p = 0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab
        // p fits in 48 bytes (381 bits)
        // value is 256 bits, which is less than p (381 bits)
        // So value < p is always true for 256-bit values
        // Just copy the value to result (right-aligned in 48 bytes)

        assembly {
            let resultPtr := add(result, 0x20)
            // Zero the first 16 bytes
            mstore(resultPtr, 0)
            // Store value in bytes 16-47 (last 32 bytes of 48)
            mstore(add(resultPtr, 16), value)
        }
    }

    /**
     * @notice Full modular reduction for 512-bit value
     * @dev Computes (hi * 2^256 + lo) mod p using schoolbook multiplication
     * @param hi Upper 256 bits
     * @param lo Lower 256 bits
     * @param result Output buffer (48 bytes)
     */
    function _reduceFullValue(bytes32 hi, bytes32 lo, bytes memory result) internal pure {
        // R = 2^256 mod p = 0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001
        // We need to compute (hi * R + lo) mod p
        //
        // Since hi * R can be up to ~637 bits (256 + 381), we need careful handling
        //
        // Approach: Use 128-bit limb arithmetic
        // Split hi into 4 x 64-bit limbs: hi = h3*2^192 + h2*2^128 + h1*2^64 + h0
        // Split R into limbs similarly
        // Perform schoolbook multiplication, then reduce

        // hi * R where R = 2^256 mod p fits in 256 bits
        // Result can be up to 512 bits
        uint256 hiVal = uint256(hi);
        uint256 R = 0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001;

        // We need (hi * R + lo) mod p
        // Since this requires 512-bit arithmetic, we split the computation:
        // 1. Compute hi * R (up to 512 bits)
        // 2. Add lo (may cause carry)
        // 3. Reduce mod p

        // Compute hi * R using assembly for 512-bit result
        uint256 prodLo;
        uint256 prodHi;

        assembly {
            // mulmod gives us (hi * R) mod (2^256)
            prodLo := mulmod(hiVal, R, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)

            // For prodHi, we use the fact that hi * R = prodHi * 2^256 + prodLo
            // prodHi = (hi * R - prodLo) / 2^256
            // This is tricky in assembly, so we compute it differently:
            // Use the identity: (a * b) >> 256 can be computed via:
            // hi_result = (a * b - (a * b mod 2^256)) / 2^256

            // Alternative: use two multiplications
            // hi * R = (hi_high * 2^128 + hi_low) * R
            //        = hi_high * R * 2^128 + hi_low * R

            let hiHigh := shr(128, hiVal)
            let hiLow := and(hiVal, 0xffffffffffffffffffffffffffffffff)

            // hi_low * R (fits in ~384 bits since hiLow is 128 bits and R is 256 bits)
            let loRLo := mul(hiLow, R)

            // hi_high * R * 2^128 - this is the tricky part
            // hi_high is 128 bits, R is 256 bits, so hi_high * R is ~384 bits
            // Shifted by 128, it's ~512 bits total

            // Actually, let's use a simpler approach:
            // Compute prodLo = (hi * R) mod 2^256 using mul
            prodLo := mul(hiVal, R)

            // Compute prodHi using mulmod trick:
            // (hi * R) / 2^256 = hi * (R / 2^256) + (hi * (R mod 2^256)) / 2^256
            // Since R < 2^256, R / 2^256 = 0
            // So prodHi comes from overflow of hi * R

            // Use mul overflow detection:
            // If hi * R overflows, prodHi = floor((hi * R) / 2^256)
            // prodHi = hi * R / 2^256 (integer division)

            // EVM doesn't have direct 512-bit multiply, so we approximate:
            // For values where hi < 2^256 and R < 2^256:
            // prodHi = (hi >> 128) * (R >> 128) + ((hi >> 128) * (R & mask) + (hi & mask) * (R >> 128)) >> 128

            let mask128 := 0xffffffffffffffffffffffffffffffff
            let hiH := shr(128, hiVal)
            let hiL := and(hiVal, mask128)
            let rH := shr(128, R)
            let rL := and(R, mask128)

            // hi * R = hiH*rH*2^256 + (hiH*rL + hiL*rH)*2^128 + hiL*rL
            let term1 := mul(hiH, rH)  // This is prodHi base
            let term2a := mul(hiH, rL)
            let term2b := mul(hiL, rH)
            let term3 := mul(hiL, rL)  // This contributes to prodLo

            // prodLo = (term2a + term2b) << 128 + term3
            // But we already have prodLo from mul(hi, R), which handles lower 256 bits

            // prodHi = term1 + ((term2a + term2b) >> 128) + carry from prodLo
            let term2Sum := add(term2a, term2b)
            let term2Overflow := lt(term2Sum, term2a)  // Check for overflow in term2a + term2b

            prodHi := add(term1, shr(128, term2Sum))
            prodHi := add(prodHi, term2Overflow)  // Add overflow from term2 sum

            // Check if lower part overflowed into prodHi
            // (term2a + term2b) << 128 + term3 might overflow
            let lowerPart := add(shl(128, term2Sum), term3)
            let lowerOverflow := lt(lowerPart, term3)
            prodHi := add(prodHi, lowerOverflow)
        }

        // Now add lo to (prodHi, prodLo)
        uint256 sumLo;
        uint256 sumHi;
        assembly {
            sumLo := add(prodLo, lo)
            let carry := lt(sumLo, prodLo)
            sumHi := add(prodHi, carry)
        }

        // Now reduce (sumHi, sumLo) mod p
        // Iteratively subtract p while value >= p
        bytes memory pBytes = FIELD_MODULUS;

        // Convert to bytes for comparison and subtraction
        // sumHi || sumLo is 512 bits = 64 bytes
        // We need to compare with p (48 bytes, or 64 bytes with padding)

        // Store sum in temporary buffer
        bytes memory sumBytes = new bytes(64);
        assembly {
            let ptr := add(sumBytes, 0x20)
            mstore(ptr, sumHi)
            mstore(add(ptr, 0x20), sumLo)
        }

        // Reduce: while sumBytes >= p (as 512-bit vs 384-bit), subtract p
        // p extended to 64 bytes is: 16 zero bytes || p (48 bytes)

        while (_isGreaterOrEqualP(sumBytes, pBytes)) {
            _subtractP(sumBytes, pBytes);
        }

        // Copy lower 48 bytes to result (the reduced value)
        // sumBytes now contains the result in the lower 48 bytes (indices 16-63)
        assembly {
            let resultPtr := add(result, 0x20)
            let srcPtr := add(sumBytes, 0x20)

            // Copy bytes 16-47 of sumBytes to result 0-31
            mstore(resultPtr, mload(add(srcPtr, 16)))
            // Copy bytes 48-63 of sumBytes to result 32-47
            mstore(add(resultPtr, 32), mload(add(srcPtr, 48)))
        }
    }

    /**
     * @notice Check if 64-byte value >= 64-byte p (with padding)
     * @param value 64-byte value
     * @param p 64-byte modulus (16-byte padding + 48-byte value)
     * @return True if value >= p
     */
    function _isGreaterOrEqualP(bytes memory value, bytes memory p) internal pure returns (bool) {
        unchecked {
            for (uint256 i = 0; i < 64; ++i) {
                uint8 vByte = uint8(value[i]);
                uint8 pByte;

                // p is stored with 16-byte padding at the start
                // For comparison, treat first 16 bytes of p as 0
                if (i < 16) {
                    pByte = 0;
                } else {
                    pByte = uint8(p[i - 16 + 16]); // p has 16-byte internal padding
                }
                // Actually, p (FIELD_MODULUS) is already 64 bytes with padding
                pByte = uint8(p[i]);

                if (vByte > pByte) return true;
                if (vByte < pByte) return false;
            }
        }
        return true; // Equal
    }

    /**
     * @notice Subtract p from 64-byte value in place
     * @param value 64-byte value (modified in place)
     * @param p 64-byte modulus
     */
    function _subtractP(bytes memory value, bytes memory p) internal pure {
        int256 borrow = 0;
        unchecked {
            for (uint256 i = 63; i < 64; --i) { // Loop from 63 down to 0
                int256 v = int256(uint256(uint8(value[i])));
                int256 pv = int256(uint256(uint8(p[i])));
                int256 diff = v - pv - borrow;

                if (diff < 0) {
                    diff += 256;
                    borrow = 1;
                } else {
                    borrow = 0;
                }

                value[i] = bytes1(uint8(uint256(diff)));

                if (i == 0) break;
            }
        }
    }

    // ==========================================
    // Generator Points
    // ==========================================

    /**
     * @notice Get negative G1 generator for pairing
     * @dev Returns precomputed constant to avoid repeated allocation
     * @return 128 bytes uncompressed G1 point
     */
    function _getNegativeG1Generator() internal pure returns (bytes memory) {
        return NEG_G1_GENERATOR;
    }

    /**
     * @notice Get G1 generator point
     * @return 128 bytes uncompressed G1 point
     */
    function getG1Generator() internal pure returns (bytes memory) {
        return abi.encodePacked(
            G1_GENERATOR_X,
            G1_GENERATOR_Y
        );
    }

    // ==========================================
    // Proof of Possession
    // ==========================================

    /**
     * @notice Verify Proof of Possession
     * @dev Prevents rogue key attacks by requiring proof of private key ownership
     * @param chainId Chain ID
     * @param validatorAddress Validator's Ethereum address
     * @param publicKey BLS public key (128 bytes uncompressed)
     * @param proofOfPossession PoP signature (256 bytes uncompressed)
     * @return valid True if PoP is valid
     */
    function verifyProofOfPossession(
        uint256 chainId,
        address validatorAddress,
        bytes calldata publicKey,
        bytes calldata proofOfPossession
    ) internal view returns (bool valid) {
        // Check precompile availability
        if (!isPrecompileAvailable()) revert PrecompileNotAvailable();
        
        if (publicKey.length != G1_POINT_SIZE) revert InvalidG1PointLength();
        if (proofOfPossession.length != G2_POINT_SIZE) revert InvalidG2PointLength();

        bytes32 popMessage = keccak256(
            abi.encodePacked("BLS_POP", chainId, validatorAddress, publicKey)
        );

        G1Point memory pubkey = G1Point({data: publicKey});
        G2Point memory signature = G2Point({data: proofOfPossession});

        return verifySignature(pubkey, signature, popMessage);
    }

    // ==========================================
    // Fast Withdrawal Message Construction
    // ==========================================

    /**
     * @notice Construct Fast Withdrawal signing message
     * @param requestId Withdrawal request ID
     * @param user User address
     * @param amount Withdrawal amount
     * @param chainId Chain ID
     * @return messageHash Hash to be signed
     */
    function constructWithdrawalMessage(
        bytes32 requestId,
        address user,
        uint256 amount,
        uint256 chainId
    ) internal pure returns (bytes32 messageHash) {
        return keccak256(
            abi.encodePacked(
                "TOKAMAK_FAST_WITHDRAWAL",
                requestId,
                user,
                amount,
                chainId
            )
        );
    }

    // ==========================================
    // Utility Functions
    // ==========================================

    /**
     * @notice Count set bits in bitmap (Brian Kernighan's algorithm)
     * @param bitmap Bitmap to count
     * @return count Number of bits set to 1
     */
    function countSetBits(uint256 bitmap) internal pure returns (uint256 count) {
        unchecked {
            while (bitmap != 0) {
                bitmap &= bitmap - 1;
                ++count;
            }
        }
    }

    /**
     * @notice Check if bit at index is set in bitmap
     * @param bitmap Bitmap to check
     * @param index Bit index (0-255)
     * @return True if bit is set
     */
    function isBitSet(uint256 bitmap, uint256 index) internal pure returns (bool) {
        return ((bitmap >> index) & 1) == 1;
    }

    /**
     * @notice Aggregate two public keys (bytes interface)
     * @param pubkeyA First public key (128 bytes)
     * @param pubkeyB Second public key (128 bytes)
     * @return aggregated Aggregated public key (128 bytes)
     */
    function aggregatePublicKeys(
        bytes memory pubkeyA,
        bytes memory pubkeyB
    ) internal view returns (bytes memory aggregated) {
        // Check precompile availability
        if (!isPrecompileAvailable()) revert PrecompileNotAvailable();
        
        if (pubkeyA.length != G1_POINT_SIZE) revert InvalidG1PointLength();
        if (pubkeyB.length != G1_POINT_SIZE) revert InvalidG1PointLength();

        G1Point memory a = G1Point({data: pubkeyA});
        G1Point memory b = G1Point({data: pubkeyB});

        G1Point memory result = g1Add(a, b);
        return result.data;
    }

    /**
     * @notice Check if EIP-2537 precompiles are available
     * @dev Calls G1ADD with identity point to verify precompile exists
     * @dev IMPORTANT: Call this before using BLS operations on new chains
     * @return available True if precompiles are active (post-Pectra upgrade)
     */
    function isPrecompileAvailable() internal view returns (bool available) {
        // Try calling G1ADD with two identity points (all zeros)
        bytes memory input = new bytes(256); // Two G1 points of zeros

        (bool success, bytes memory output) = BLS12_G1ADD.staticcall{gas: 50000}(input);

        // If precompile is available, it will succeed with zero output
        return success && output.length == G1_POINT_SIZE;
    }
    
    /**
     * @notice Require precompile availability with custom error
     * @dev Useful for constructor or initialization checks
     */
    function requirePrecompileAvailable() internal view {
        if (!isPrecompileAvailable()) revert PrecompileNotAvailable();
    }
}
