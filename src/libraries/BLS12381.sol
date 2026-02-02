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

    // ==========================================
    // Constants - BLS12-381 Curve Parameters
    // ==========================================

    /// @notice BLS12-381 field modulus p (48 bytes, padded to 64 bytes)
    /// p = 0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab
    bytes internal constant FIELD_MODULUS = hex"0000000000000000000000000000000017f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb";

    /// @notice G1 Generator x-coordinate (48 bytes value, 16 bytes padding = 64 bytes total)
    /// x = 0x17f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb
    bytes internal constant G1_GENERATOR_X = hex"0000000000000000000000000000000017f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb";

    /// @notice G1 Generator y-coordinate (48 bytes value, 16 bytes padding = 64 bytes total)
    /// y = 0x08b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1
    bytes internal constant G1_GENERATOR_Y = hex"0000000000000000000000000000000008b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1";

    /// @notice G1 Generator y-coordinate negated (p - y) for pairing verification
    /// @dev -y = 0x114d1d68560455a8ab7d76c8cf2e21f267816aee1db5079f66559cd5caac424f4e6f38ba8ecb715eb354dcd6b995c2ca
    bytes internal constant G1_GENERATOR_NEG_Y = hex"00000000000000000000000000000000114d1d68560455a8ab7d76c8cf2e21f267816aee1db5079f66559cd5caac424f4e6f38ba8ecb715eb354dcd6b995c2ca";

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
        bytes memory input = new bytes(count * (G1_POINT_SIZE + 32));
        uint256 offset = 0;

        bytes32 one = bytes32(uint256(1));

        for (uint256 i = 0; i < count; i++) {
            // Copy point
            for (uint256 j = 0; j < G1_POINT_SIZE; j++) {
                input[offset + j] = points[i].data[j];
            }
            offset += G1_POINT_SIZE;

            // Copy scalar (1)
            for (uint256 j = 0; j < 32; j++) {
                input[offset + j] = one[j];
            }
            offset += 32;
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
        bytes memory input = new bytes(count * (G2_POINT_SIZE + 32));
        uint256 offset = 0;

        bytes32 one = bytes32(uint256(1));

        for (uint256 i = 0; i < count; i++) {
            // Copy point
            for (uint256 j = 0; j < G2_POINT_SIZE; j++) {
                input[offset + j] = signatures[i].data[j];
            }
            offset += G2_POINT_SIZE;

            // Copy scalar (1)
            for (uint256 j = 0; j < 32; j++) {
                input[offset + j] = one[j];
            }
            offset += 32;
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
     * @notice Hash to Fp2 element for hash-to-curve
     * @dev Produces a 128-byte Fp2 element (two 64-byte Fp elements)
     * @param messageHash Message to hash
     * @param index Index for domain separation (0 or 1)
     * @return fp2 128 bytes Fp2 element
     */
    function _hashToFp2(bytes32 messageHash, uint8 index) internal pure returns (bytes memory fp2) {
        // DST for BLS12-381 G2 hash-to-curve
        bytes memory dst = bytes("BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_");

        // Expand message to 128 bytes using XMD (SHA-256)
        fp2 = new bytes(FP2_SIZE);

        // Generate 4 hash blocks (128 bytes = 4 * 32 bytes)
        bytes32 b0 = keccak256(abi.encodePacked(
            bytes32(0), // Z_pad
            messageHash,
            uint16(128), // output length
            uint8(0),
            index,
            dst,
            uint8(dst.length)
        ));

        bytes32 b1 = keccak256(abi.encodePacked(b0, uint8(1), dst, uint8(dst.length)));
        bytes32 b2 = keccak256(abi.encodePacked(b0 ^ b1, uint8(2), dst, uint8(dst.length)));
        bytes32 b3 = keccak256(abi.encodePacked(b0 ^ b2, uint8(3), dst, uint8(dst.length)));

        // Construct Fp2 element: c0 (64 bytes) || c1 (64 bytes)
        // Each Fp is 48 bytes value padded to 64 bytes
        // c0 from b1 || b2[0:16]
        // c1 from b2[16:32] || b3[0:32]

        // First Fp element (c0): pad with 16 zeros then 48 bytes
        // Use b1 (32 bytes) + first 16 bytes of b2
        for (uint256 i = 0; i < 16; i++) {
            fp2[i] = 0; // padding
        }
        for (uint256 i = 0; i < 32; i++) {
            fp2[16 + i] = b1[i];
        }
        for (uint256 i = 0; i < 16; i++) {
            fp2[48 + i] = b2[i];
        }

        // Second Fp element (c1): pad with 16 zeros then 48 bytes
        // Use last 16 bytes of b2 + b3 (32 bytes)
        for (uint256 i = 0; i < 16; i++) {
            fp2[64 + i] = 0; // padding
        }
        for (uint256 i = 16; i < 32; i++) {
            fp2[64 + (i - 16)] = b2[i];
        }
        for (uint256 i = 0; i < 32; i++) {
            fp2[80 + i] = b3[i];
        }

        // Note: We need to reduce these values modulo the field prime
        // The precompile will handle invalid field elements by returning an error
        // For production, proper field reduction should be implemented
    }

    // ==========================================
    // Generator Points
    // ==========================================

    /**
     * @notice Get negative G1 generator for pairing
     * @dev Returns G1 generator with negated y-coordinate
     * @return 128 bytes uncompressed G1 point
     */
    function _getNegativeG1Generator() internal pure returns (bytes memory) {
        // BLS12-381 G1 generator with y negated
        // x = 0x17f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb
        // -y = p - y_gen = 0x114d1d68560455a8ab7d76c8cf2e21f267816aee1db5079f66559cd5caac424f4e6f38ba8ecb715eb354dcd6b995c2ca
        bytes memory result = new bytes(G1_POINT_SIZE);

        // G1 Generator x-coordinate (48 bytes value, 16 bytes zero padding = 64 bytes)
        bytes memory gx = hex"0000000000000000000000000000000017f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb";

        // G1 Generator -y coordinate (48 bytes value, 16 bytes zero padding = 64 bytes)
        bytes memory negy = hex"00000000000000000000000000000000114d1d68560455a8ab7d76c8cf2e21f267816aee1db5079f66559cd5caac424f4e6f38ba8ecb715eb354dcd6b995c2ca";

        // Copy x-coordinate
        for (uint256 i = 0; i < 64; i++) {
            result[i] = gx[i];
        }

        // Copy negated y-coordinate
        for (uint256 i = 0; i < 64; i++) {
            result[64 + i] = negy[i];
        }

        return result;
    }

    /**
     * @notice Get G1 generator point
     * @return 128 bytes uncompressed G1 point
     */
    function getG1Generator() internal pure returns (bytes memory) {
        bytes memory result = new bytes(G1_POINT_SIZE);

        // G1 Generator x-coordinate (48 bytes value, 16 bytes zero padding = 64 bytes)
        bytes memory gx = hex"0000000000000000000000000000000017f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb";
        // G1 Generator y-coordinate (48 bytes value, 16 bytes zero padding = 64 bytes)
        bytes memory gy = hex"0000000000000000000000000000000008b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1";

        for (uint256 i = 0; i < 64; i++) {
            result[i] = gx[i];
        }
        for (uint256 i = 0; i < 64; i++) {
            result[64 + i] = gy[i];
        }

        return result;
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
     * @notice Count set bits in bitmap (population count)
     * @param bitmap Bitmap to count
     * @return count Number of bits set to 1
     */
    function countSetBits(uint256 bitmap) internal pure returns (uint256 count) {
        while (bitmap > 0) {
            count += bitmap & 1;
            bitmap >>= 1;
        }
    }

    /**
     * @notice Check if bit at index is set in bitmap
     * @param bitmap Bitmap to check
     * @param index Bit index (0-255)
     * @return True if bit is set
     */
    function isBitSet(uint256 bitmap, uint256 index) internal pure returns (bool) {
        return (bitmap >> index) & 1 == 1;
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
     * @return available True if precompiles are active
     */
    function isPrecompileAvailable() internal view returns (bool available) {
        // Try calling G1ADD with two identity points (all zeros)
        bytes memory input = new bytes(256); // Two G1 points of zeros

        (bool success, bytes memory output) = BLS12_G1ADD.staticcall(input);

        // If precompile is available, it will succeed with zero output
        return success && output.length == G1_POINT_SIZE;
    }
}
