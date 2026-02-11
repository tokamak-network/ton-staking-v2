// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title BLS12381
 * @notice BLS12-381 signature verification library using EIP-2537 precompiles
 * @dev Reference: https://eips.ethereum.org/EIPS/eip-2537
 *
 * EIP-2537 Precompile Addresses (Pectra / Prague):
 * - BLS12_G1ADD:         0x0b (11)
 * - BLS12_G1MSM:         0x0c (12)
 * - BLS12_G2ADD:         0x0d (13)
 * - BLS12_G2MSM:         0x0e (14)
 * - BLS12_PAIRING:       0x0f (15)
 * - BLS12_MAP_FP_TO_G1:  0x10 (16)
 * - BLS12_MAP_FP2_TO_G2: 0x11 (17)
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

    /// @notice BLS12_G1MSM precompile address (multi-scalar multiplication, also handles single MUL)
    address internal constant BLS12_G1MSM = address(0x0c);

    /// @notice BLS12_G2ADD precompile address
    address internal constant BLS12_G2ADD = address(0x0d);

    /// @notice BLS12_G2MSM precompile address (multi-scalar multiplication, also handles single MUL)
    address internal constant BLS12_G2MSM = address(0x0e);

    /// @notice BLS12_PAIRING precompile address
    address internal constant BLS12_PAIRING = address(0x0f);

    /// @notice BLS12_MAP_FP_TO_G1 precompile address
    address internal constant BLS12_MAP_FP_TO_G1 = address(0x10);

    /// @notice BLS12_MAP_FP2_TO_G2 precompile address
    address internal constant BLS12_MAP_FP2_TO_G2 = address(0x11);

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
    bytes internal constant NEG_G1_GENERATOR = hex"0000000000000000000000000000000017f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb00000000000000000000000000000000114d1d6855d545a8aa7d76c8cf2e21f267816aef1db507c96655b9d5caac42364e6f38ba0ecb751bad54dcd6b939c2ca";

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
     * @dev Implements hash-to-curve following RFC 9380 (hash_to_field + map_to_curve)
     * @dev Uses a single expand_message_xmd call producing 256 bytes of uniform randomness
     * @dev Parameters: count=2, m=2 (Fp2), L=64 → len_in_bytes = 2*2*64 = 256
     * @param messageHash 32 bytes message hash
     * @return G2 point
     */
    function hashToG2(bytes32 messageHash) internal view returns (G2Point memory) {
        // RFC 9380 expand_message_xmd: produce 256 bytes of uniform randomness
        bytes memory uniformBytes = _expandMessageXMD(messageHash);

        // Split into two Fp2 elements (128 bytes each)
        bytes memory u0 = new bytes(FP2_SIZE);
        bytes memory u1 = new bytes(FP2_SIZE);

        assembly {
            let src := add(uniformBytes, 0x20)
            let u0Ptr := add(u0, 0x20)
            let u1Ptr := add(u1, 0x20)

            // Copy first 128 bytes to u0
            mstore(u0Ptr, mload(src))
            mstore(add(u0Ptr, 0x20), mload(add(src, 0x20)))
            mstore(add(u0Ptr, 0x40), mload(add(src, 0x40)))
            mstore(add(u0Ptr, 0x60), mload(add(src, 0x60)))

            // Copy next 128 bytes to u1
            mstore(u1Ptr, mload(add(src, 0x80)))
            mstore(add(u1Ptr, 0x20), mload(add(src, 0xa0)))
            mstore(add(u1Ptr, 0x40), mload(add(src, 0xc0)))
            mstore(add(u1Ptr, 0x60), mload(add(src, 0xe0)))
        }

        // Reduce each 64-byte chunk mod p to get proper EIP-2537 Fp format
        _reduceToFpFormat(u0, 0);   // u[0].c0: bytes 0-63
        _reduceToFpFormat(u0, 64);  // u[0].c1: bytes 64-127
        _reduceToFpFormat(u1, 0);   // u[1].c0: bytes 0-63 (originally 128-191)
        _reduceToFpFormat(u1, 64);  // u[1].c1: bytes 64-127 (originally 192-255)

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
     * @notice RFC 9380 expand_message_xmd with SHA-256, producing 256 bytes
     * @dev DST: "BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_"
     * @dev ell = ceil(256 / 32) = 8 SHA-256 blocks
     * @param messageHash 32-byte message to expand
     * @return result 256 bytes of pseudo-random output
     */
    function _expandMessageXMD(bytes32 messageHash) internal view returns (bytes memory result) {
        bytes memory dst = bytes("BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_");
        uint8 dstLen = uint8(dst.length); // 39

        // Z_pad = I2OSP(0, s_in_bytes) where s_in_bytes = 64 for SHA-256
        bytes memory zPad = new bytes(64);

        // b_0 = SHA256(Z_pad || msg || l_i_b_str || I2OSP(0, 1) || DST_prime)
        // l_i_b_str = I2OSP(256, 2) = 0x0100
        bytes32 b0 = _sha256(abi.encodePacked(
            zPad,
            messageHash,
            uint16(256),  // l_i_b_str (big-endian)
            uint8(0),     // I2OSP(0, 1)
            dst,
            dstLen        // DST_prime = DST || I2OSP(len(DST), 1)
        ));

        // b_1 = SHA256(b_0 || I2OSP(1, 1) || DST_prime)
        bytes32 b1 = _sha256(abi.encodePacked(b0, uint8(1), dst, dstLen));

        // b_i = SHA256(strxor(b_0, b_{i-1}) || I2OSP(i, 1) || DST_prime)
        bytes32 b2 = _sha256(abi.encodePacked(b0 ^ b1, uint8(2), dst, dstLen));
        bytes32 b3 = _sha256(abi.encodePacked(b0 ^ b2, uint8(3), dst, dstLen));
        bytes32 b4 = _sha256(abi.encodePacked(b0 ^ b3, uint8(4), dst, dstLen));
        bytes32 b5 = _sha256(abi.encodePacked(b0 ^ b4, uint8(5), dst, dstLen));
        bytes32 b6 = _sha256(abi.encodePacked(b0 ^ b5, uint8(6), dst, dstLen));
        bytes32 b7 = _sha256(abi.encodePacked(b0 ^ b6, uint8(7), dst, dstLen));
        bytes32 b8 = _sha256(abi.encodePacked(b0 ^ b7, uint8(8), dst, dstLen));

        // uniform_bytes = b_1 || b_2 || ... || b_8 (256 bytes)
        result = new bytes(256);
        assembly {
            let ptr := add(result, 0x20)
            mstore(ptr, b1)
            mstore(add(ptr, 0x20), b2)
            mstore(add(ptr, 0x40), b3)
            mstore(add(ptr, 0x60), b4)
            mstore(add(ptr, 0x80), b5)
            mstore(add(ptr, 0xa0), b6)
            mstore(add(ptr, 0xc0), b7)
            mstore(add(ptr, 0xe0), b8)
        }
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
            // Only need 16 bytes, but mstore writes 32 — use masking to
            // avoid overwriting the adjacent Fp element's data
            let word2 := mload(add(srcPtr, 32))
            let existing := mload(add(dstPtr, 48))
            mstore(add(dstPtr, 48), or(
                and(word2, 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000),
                and(existing, 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff)
            ))
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

        // p is 381 bits (> 2^256), so any 256-bit value is automatically < p.
        // For a 512-bit value v = hi * 2^256 + lo:
        // - If hi == 0: lo < 2^256 < p, no reduction needed
        // - If hi != 0: binary long division by p (at most 132 iterations)

        if (hi == bytes32(0)) {
            // lo < 2^256 < p, just copy
            _reduceSingleWord(lo, result);
        } else {
            // Full 512-bit reduction using binary long division
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
     * @dev Computes (hi * 2^256 + lo) mod p using binary long division
     * @dev Since p (381 bits) > 2^256, we operate on (uint256, uint256) pairs
     * @dev Maximum 132 iterations (quotient < 2^132)
     * @param hi Upper 256 bits
     * @param lo Lower 256 bits
     * @param result Output buffer (48 bytes)
     */
    function _reduceFullValue(bytes32 hi, bytes32 lo, bytes memory result) internal pure {
        uint256 vHi = uint256(hi);
        uint256 vLo = uint256(lo);

        // p as two 256-bit words: p = pHi * 2^256 + pLo (381 bits total)
        uint256 sHi = 0x000000000000000000000000000000001a0111ea397fe69a4b1ba7b6434bacd7;
        uint256 sLo = 0x64774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab;

        // Phase 1: Left-shift p to align with v's MSB (at most 131 shifts)
        uint256 shifts;
        for (uint256 i; i < 132; ++i) {
            // Can't shift if MSB of sHi is set (would overflow 512 bits)
            if (sHi >> 255 != 0) break;

            // Compute (sHi, sLo) << 1
            uint256 nHi = (sHi << 1) | (sLo >> 255);
            uint256 nLo = sLo << 1;

            // Stop if shifted p would exceed v
            if (nHi > vHi || (nHi == vHi && nLo > vLo)) break;

            sHi = nHi;
            sLo = nLo;
            unchecked { ++shifts; }
        }

        // Phase 2: Binary long division (subtract shifted p, then shift right)
        for (uint256 i; i <= shifts; ++i) {
            // If v >= shifted_p, subtract
            if (vHi > sHi || (vHi == sHi && vLo >= sLo)) {
                unchecked {
                    uint256 newLo = vLo - sLo;
                    uint256 borrow;
                    assembly { borrow := lt(vLo, sLo) }
                    vHi = vHi - sHi - borrow;
                    vLo = newLo;
                }
            }

            // Shift p right by 1
            sLo = (sLo >> 1) | (sHi << 255);
            sHi = sHi >> 1;
        }

        // v = (vHi, vLo) is now v mod p (< 2^381)
        // Encode as 48 bytes: [vHi as 16 bytes][vLo as 32 bytes]
        assembly {
            let resultPtr := add(result, 0x20)
            mstore(resultPtr, or(shl(128, vHi), shr(128, vLo)))
            mstore(add(resultPtr, 32), shl(128, vLo))
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
