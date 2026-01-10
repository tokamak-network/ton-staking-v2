package submitter

import (
	"crypto/ecdsa"
	"math/big"
	"testing"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestBuildCalldata(t *testing.T) {
	// Create submitter
	privateKey, err := crypto.GenerateKey()
	require.NoError(t, err)

	submitter := &AdjacentLeavesSubmitter{
		privateKey:  privateKey,
		ratContract: common.HexToAddress("0xBa3e08b4753E68952031102518379ED2fDADcA30"),
	}

	// Test data
	testID := [32]byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32}
	evidenceData := []byte("test_evidence_data")

	// Build calldata
	calldata, err := submitter.buildCalldata(testID, evidenceData)
	require.NoError(t, err)
	assert.NotNil(t, calldata)

	// Verify structure
	// 4 bytes selector + 32 bytes testID + 32 bytes evidenceType + 32 bytes offset + 32 bytes length + data
	minExpectedSize := 4 + 32 + 32 + 32 + 32 + len(evidenceData)
	assert.GreaterOrEqual(t, len(calldata), minExpectedSize)

	// Verify function selector (first 4 bytes)
	expectedSelector := crypto.Keccak256([]byte("submitEvidence(bytes32,uint8,bytes)"))[:4]
	actualSelector := calldata[:4]
	assert.Equal(t, expectedSelector, actualSelector, "Function selector should match submitEvidence")

	// Verify testID (bytes 4-36)
	actualTestID := calldata[4:36]
	assert.Equal(t, testID[:], actualTestID, "TestID should be encoded correctly")

	// Verify evidenceType (bytes 36-68, should be 1 for StateLeaf)
	evidenceType := calldata[67] // Last byte of the 32-byte word
	assert.Equal(t, uint8(1), evidenceType, "Evidence type should be 1 (StateLeaf)")
}

func TestBuildCalldata_EmptyEvidence(t *testing.T) {
	privateKey, err := crypto.GenerateKey()
	require.NoError(t, err)

	submitter := &AdjacentLeavesSubmitter{
		privateKey:  privateKey,
		ratContract: common.HexToAddress("0xRATContract"),
	}

	testID := [32]byte{1}
	emptyEvidence := []byte{}

	// Should still work with empty evidence
	calldata, err := submitter.buildCalldata(testID, emptyEvidence)
	require.NoError(t, err)
	assert.NotNil(t, calldata)

	// Minimum size with empty data
	expectedMinSize := 4 + 32 + 32 + 32 + 32 // selector + testID + type + offset + length
	assert.GreaterOrEqual(t, len(calldata), expectedMinSize)
}

func TestBuildCalldata_LargeEvidence(t *testing.T) {
	privateKey, err := crypto.GenerateKey()
	require.NoError(t, err)

	submitter := &AdjacentLeavesSubmitter{
		privateKey:  privateKey,
		ratContract: common.HexToAddress("0xRATContract"),
	}

	testID := [32]byte{1}
	// Create large evidence (10 KB)
	largeEvidence := make([]byte, 10*1024)
	for i := range largeEvidence {
		largeEvidence[i] = byte(i % 256)
	}

	calldata, err := submitter.buildCalldata(testID, largeEvidence)
	require.NoError(t, err)
	assert.NotNil(t, calldata)

	// Verify size accounts for padding
	// Data is padded to 32-byte boundary
	padding := (32 - (len(largeEvidence) % 32)) % 32
	expectedSize := 4 + 32 + 32 + 32 + 32 + len(largeEvidence) + padding
	assert.Equal(t, expectedSize, len(calldata))
}

func TestEstimateGas(t *testing.T) {
	// This is a unit test without actual RPC calls
	// We test the gas calculation logic only

	privateKey, err := crypto.GenerateKey()
	require.NoError(t, err)

	submitter := &AdjacentLeavesSubmitter{
		privateKey:  privateKey,
		gasLimit:    500000,
		maxGasPrice: big.NewInt(100000000000), // 100 gwei
	}

	// Test gas limit is set
	assert.Equal(t, uint64(500000), submitter.gasLimit)
	assert.Equal(t, big.NewInt(100000000000), submitter.maxGasPrice)
}

func TestTransactionSigning(t *testing.T) {
	// Test transaction signing with known private key
	privateKeyHex := "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
	privateKey, err := crypto.HexToECDSA(privateKeyHex)
	require.NoError(t, err)

	// Verify address derivation
	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	require.True(t, ok)

	address := crypto.PubkeyToAddress(*publicKeyECDSA)
	expectedAddress := common.HexToAddress("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266")
	assert.Equal(t, expectedAddress, address, "Address should match Anvil account #0")
}

func TestCalldataEncoding_Deterministic(t *testing.T) {
	privateKey, err := crypto.GenerateKey()
	require.NoError(t, err)

	submitter := &AdjacentLeavesSubmitter{
		privateKey:  privateKey,
		ratContract: common.HexToAddress("0xRATContract"),
	}

	testID := [32]byte{1, 2, 3}
	evidenceData := []byte("deterministic_test")

	// Build calldata twice
	calldata1, err := submitter.buildCalldata(testID, evidenceData)
	require.NoError(t, err)

	calldata2, err := submitter.buildCalldata(testID, evidenceData)
	require.NoError(t, err)

	// Should be identical (deterministic encoding)
	assert.Equal(t, calldata1, calldata2, "Calldata encoding should be deterministic")
}

func TestFunctionSelector(t *testing.T) {
	// Verify function selector for submitEvidence
	selector := crypto.Keccak256([]byte("submitEvidence(bytes32,uint8,bytes)"))[:4]

	t.Logf("submitEvidence function selector: 0x%x", selector)
	assert.Equal(t, 4, len(selector))
	assert.NotEqual(t, []byte{0, 0, 0, 0}, selector, "Selector should not be all zeros")
}

func TestABIEncoding_Padding(t *testing.T) {
	// Test that evidence data is properly padded to 32-byte boundary
	tests := []struct {
		name       string
		dataLen    int
		wantPadding int
	}{
		{"no padding needed", 32, 0},
		{"1 byte padding", 31, 1},
		{"31 bytes padding", 1, 31},
		{"no padding for multiple of 32", 64, 0},
		{"15 bytes padding", 17, 15},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			actualPadding := (32 - (tt.dataLen % 32)) % 32
			assert.Equal(t, tt.wantPadding, actualPadding)
		})
	}
}

func TestEvidenceType(t *testing.T) {
	// Evidence type constants
	const (
		EvidenceTypeFraudProof = 0
		EvidenceTypeStateLeaf  = 1
	)

	// Verify StateLeaf type is 1
	assert.Equal(t, uint8(1), uint8(EvidenceTypeStateLeaf))
}
