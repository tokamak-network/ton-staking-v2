// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title MockBLS12381
 * @notice Mock BLS12-381 precompile for testing without EIP-2537
 * @dev This contract simulates BLS operations for local testing
 *      DO NOT USE IN PRODUCTION - This is insecure and for testing only
 */
library MockBLS12381 {
    /// @notice Mock Proof of Possession verification
    /// @dev Always returns true in mock mode
    function verifyProofOfPossession(
        uint256 /* chainId */,
        address /* validator */,
        bytes calldata /* blsPublicKey */,
        bytes calldata /* blsProofOfPossession */
    ) internal pure returns (bool) {
        // In mock mode, always accept PoP
        // Real implementation would call EIP-2537 precompile
        return true;
    }

    /// @notice Mock BLS signature verification
    /// @dev Always returns true in mock mode
    function verifySignature(
        bytes memory /* message */,
        bytes memory /* signature */,
        bytes memory /* publicKey */
    ) internal pure returns (bool) {
        // In mock mode, always accept signature
        // Real implementation would call EIP-2537 precompile
        return true;
    }

    /// @notice Mock BLS public key aggregation
    /// @dev Returns concatenation of first public key (mock)
    function aggregatePublicKeys(
        bytes[] memory publicKeys
    ) internal pure returns (bytes memory) {
        require(publicKeys.length > 0, "No public keys to aggregate");
        
        // In mock mode, just return the first public key
        // Real implementation would call EIP-2537 precompile
        return publicKeys[0];
    }

    /// @notice Mock BLS signature aggregation
    /// @dev Returns concatenation of first signature (mock)
    function aggregateSignatures(
        bytes[] memory signatures
    ) internal pure returns (bytes memory) {
        require(signatures.length > 0, "No signatures to aggregate");
        
        // In mock mode, just return the first signature
        // Real implementation would call EIP-2537 precompile
        return signatures[0];
    }
}

/**
 * @title TestBLS12381Helper
 * @notice Helper contract for testing BLS operations
 */
contract TestBLS12381Helper {
    /// @notice Generate a mock BLS public key for testing
    function generateMockPublicKey(address validator) external pure returns (bytes memory) {
        bytes memory pubKey = new bytes(128);
        bytes32 hash = keccak256(abi.encodePacked(validator, "bls-pubkey"));
        
        // Fill with deterministic mock data
        for (uint i = 0; i < 4; i++) {
            bytes32 segment = keccak256(abi.encodePacked(hash, i));
            for (uint j = 0; j < 32 && i * 32 + j < 128; j++) {
                pubKey[i * 32 + j] = segment[j];
            }
        }
        
        return pubKey;
    }

    /// @notice Generate a mock BLS Proof of Possession for testing
    function generateMockProofOfPossession(
        uint256 chainId,
        address validator
    ) external pure returns (bytes memory) {
        bytes memory pop = new bytes(256);
        bytes32 hash = keccak256(abi.encodePacked(chainId, validator, "bls-pop"));
        
        // Fill with deterministic mock data
        for (uint i = 0; i < 8; i++) {
            bytes32 segment = keccak256(abi.encodePacked(hash, i));
            for (uint j = 0; j < 32; j++) {
                pop[i * 32 + j] = segment[j];
            }
        }
        
        return pop;
    }

    /// @notice Generate a mock BLS signature for testing
    function generateMockSignature(
        bytes memory message,
        address validator
    ) external pure returns (bytes memory) {
        bytes memory sig = new bytes(256);
        bytes32 hash = keccak256(abi.encodePacked(message, validator, "bls-sig"));
        
        // Fill with deterministic mock data
        for (uint i = 0; i < 8; i++) {
            bytes32 segment = keccak256(abi.encodePacked(hash, i));
            for (uint j = 0; j < 32; j++) {
                sig[i * 32 + j] = segment[j];
            }
        }
        
        return sig;
    }

    /// @notice Generate mock aggregate signature
    function generateMockAggregateSignature(
        bytes memory message,
        address[] memory validators
    ) external pure returns (bytes memory) {
        bytes memory sig = new bytes(256);
        bytes32 hash = keccak256(abi.encodePacked(message, validators, "bls-agg-sig"));
        
        // Fill with deterministic mock data
        for (uint i = 0; i < 8; i++) {
            bytes32 segment = keccak256(abi.encodePacked(hash, i));
            for (uint j = 0; j < 32; j++) {
                sig[i * 32 + j] = segment[j];
            }
        }
        
        return sig;
    }
}
