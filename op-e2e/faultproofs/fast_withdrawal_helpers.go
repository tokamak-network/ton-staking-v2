package faultproofs

import (
	"crypto/rand"
	"crypto/sha256"
	"testing"

	"github.com/ethereum/go-ethereum/common"
	"github.com/stretchr/testify/require"
)

// ============================================================================
// BLS Key Generation Helpers
// ============================================================================

// generateBLSKeyPair generates a mock BLS12-381 key pair for testing
// Note: This is a simplified mock implementation. In production, use proper BLS12-381 library.
func generateBLSKeyPair(t *testing.T) (privKey []byte, pubKey []byte) {
	// BLS12-381 private key is 32 bytes
	privKey = make([]byte, 32)
	_, err := rand.Read(privKey)
	require.NoError(t, err, "Failed to generate BLS private key")

	// BLS12-381 public key is 48 bytes (G1 compressed point)
	// For testing, we derive it deterministically from private key
	pubKey = make([]byte, 48)
	hash := sha256.Sum256(privKey)
	copy(pubKey, hash[:])
	// Fill remaining bytes
	for i := 32; i < 48; i++ {
		pubKey[i] = privKey[i-32] ^ 0xFF
	}

	return privKey, pubKey
}

// ============================================================================
// BLS Signature Helpers
// ============================================================================

// createBLSRegistrationMessage creates the message to be signed for BLS registration
// Message format: keccak256(abi.encodePacked(validatorAddress, systemConfig))
func createBLSRegistrationMessage(validator common.Address, systemConfig common.Address) []byte {
	// Concatenate validator address + systemConfig address
	message := append(validator.Bytes(), systemConfig.Bytes()...)

	// Hash the concatenated data
	hash := sha256.Sum256(message)
	return hash[:]
}

// signBLSMessage signs a message with a BLS private key
// Note: This is a simplified mock implementation for testing.
// In production, use proper BLS12-381 signature library (e.g., herumi/bls-eth-go-binary)
func signBLSMessage(t *testing.T, privKey []byte, message []byte) []byte {
	require.NotEmpty(t, privKey, "Private key should not be empty")
	require.NotEmpty(t, message, "Message should not be empty")

	// BLS12-381 signature is 96 bytes (G2 compressed point)
	// For testing, we generate a deterministic signature
	signature := make([]byte, 96)

	// Combine private key and message
	combined := append(privKey, message...)
	hash := sha256.Sum256(combined)

	// Fill first 32 bytes with hash
	copy(signature, hash[:])

	// Fill next 32 bytes with hash of hash
	hash2 := sha256.Sum256(hash[:])
	copy(signature[32:], hash2[:])

	// Fill last 32 bytes with hash of combined
	hash3 := sha256.Sum256(combined)
	copy(signature[64:], hash3[:])

	return signature
}

// aggregateBLSSignatures aggregates multiple BLS signatures
// Note: This is a simplified mock implementation for testing.
// In production, use proper BLS signature aggregation.
func aggregateBLSSignatures(t *testing.T, signatures [][]byte) []byte {
	require.NotEmpty(t, signatures, "Signatures should not be empty")

	// Verify all signatures are 96 bytes
	for i, sig := range signatures {
		require.Equal(t, 96, len(sig), "Signature %d should be 96 bytes", i)
	}

	// For testing, we XOR all signatures together
	aggregated := make([]byte, 96)
	for _, sig := range signatures {
		for i := 0; i < 96; i++ {
			aggregated[i] ^= sig[i]
		}
	}

	return aggregated
}

// ============================================================================
// Fast Withdrawal Helpers
// ============================================================================

// createWithdrawalHash creates a withdrawal hash from withdrawal transaction data
// This follows the Optimism withdrawal hash format:
// keccak256(abi.encode(nonce, sender, target, value, gasLimit, data))
func createWithdrawalHash(
	nonce uint64,
	sender common.Address,
	target common.Address,
	value uint64,
	gasLimit uint64,
	data []byte,
) common.Hash {
	// Simplified hash for testing
	// In production, use proper ABI encoding
	combined := append([]byte{}, byte(nonce))
	combined = append(combined, sender.Bytes()...)
	combined = append(combined, target.Bytes()...)
	combined = append(combined, byte(value))
	combined = append(combined, byte(gasLimit))
	combined = append(combined, data...)

	return sha256.Sum256(combined)
}

// ============================================================================
// Adjacent Leaves Proof Helpers
// ============================================================================

// generateAdjacentLeavesProof generates adjacent leaves proof for a state root
// This proof demonstrates that the validator possesses the full L2 state by
// finding two adjacent leaves in the state trie where: leafA.key < stateRoot <= leafB.key
//
// Note: This is a mock implementation. In production, query L2 node using:
// - debug_accountRange to find adjacent leaves
// - eth_getProof to get Merkle proofs
func generateAdjacentLeavesProof(
	t *testing.T,
	stateRoot common.Hash,
) (leafAKey common.Hash, leafBKey common.Hash, proofsA [][]byte, proofsB [][]byte) {
	// Mock implementation for testing
	// In production, this requires actual L2 state queries

	// Generate mock leafA (key less than stateRoot)
	leafAKey = common.BigToHash(stateRoot.Big().Sub(stateRoot.Big(), common.Big1))

	// Generate mock leafB (key greater than stateRoot)
	leafBKey = common.BigToHash(stateRoot.Big().Add(stateRoot.Big(), common.Big1))

	// Mock Merkle proofs (empty for now)
	proofsA = [][]byte{
		[]byte("mock_proof_a_1"),
		[]byte("mock_proof_a_2"),
	}
	proofsB = [][]byte{
		[]byte("mock_proof_b_1"),
		[]byte("mock_proof_b_2"),
	}

	return
}

// ============================================================================
// Validator Bitmap Helpers
// ============================================================================

// createValidatorBitmap creates a bitmap indicating which validators signed
// Bit i is set if validator i signed the withdrawal
func createValidatorBitmap(validatorIndices []int) uint64 {
	var bitmap uint64
	for _, idx := range validatorIndices {
		if idx < 64 {
			bitmap |= (1 << uint(idx))
		}
	}
	return bitmap
}

// ============================================================================
// Fee Calculation Helpers
// ============================================================================

// calculateAggregatorFee calculates the aggregator fee from total fee
// aggregatorFee = totalFee * aggregatorFeeRate / 10000
func calculateAggregatorFee(totalFee uint64, feeRate uint64) uint64 {
	return (totalFee * feeRate) / 10000
}

// calculateValidatorShare calculates each validator's share of the fee
// validatorShare = (totalFee - aggregatorFee) / validatorCount
func calculateValidatorShare(totalFee uint64, aggregatorFee uint64, validatorCount int) uint64 {
	if validatorCount == 0 {
		return 0
	}
	return (totalFee - aggregatorFee) / uint64(validatorCount)
}

// ============================================================================
// Mock Data Helpers
// ============================================================================

// createMockStateRoot creates a mock L2 state root for testing
func createMockStateRoot() common.Hash {
	return common.HexToHash("0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef")
}

// createMockWithdrawalData creates mock withdrawal transaction data
func createMockWithdrawalData(target common.Address, value uint64) (
	nonce uint64,
	sender common.Address,
	gasLimit uint64,
	data []byte,
) {
	nonce = 1
	sender = common.HexToAddress("0x0000000000000000000000000000000000000000")
	gasLimit = 100000
	data = []byte{}
	return
}

// ============================================================================
// Constants for Fast Withdrawal Testing
// ============================================================================

const (
	// Fast Withdrawal fee in wei (0.01 ETH = 10^16 wei)
	FastWithdrawalFee = 10000000000000000

	// Default aggregator fee rate (10% = 1000 basis points)
	DefaultAggregatorFeeRate = 1000

	// Fast withdrawal timeout (10 minutes = 600 seconds)
	FastWithdrawalTimeout = 600

	// Minimum number of validators for fast withdrawal
	MinValidatorsForFastWithdrawal = 3
)
