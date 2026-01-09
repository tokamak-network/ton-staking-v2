package test

import (
	"context"
	"math/big"
	"os"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum/rpc"
	"github.com/stretchr/testify/require"
	"github.com/tokamak-network/ton-staking-v2/clients/rat-client-type3/pkg/evidence"
	"github.com/tokamak-network/ton-staking-v2/clients/rat-client-type3/pkg/l2sync"
)

// TestStateLeafRPCE2E tests StateLeaf evidence generation using RPC
// This is the RECOMMENDED approach for Geth v1.13+ with PBSS
func TestStateLeafRPCE2E(t *testing.T) {
	// Skip if not in E2E mode
	if os.Getenv("E2E_TEST") != "1" {
		t.Skip("Skipping E2E test. Set E2E_TEST=1 to run.")
	}

	// Configuration from environment
	l2RPCURL := getEnvOrDefault("L2_RPC_URL", "http://localhost:9545")
	t.Logf("Connecting to L2 RPC: %s", l2RPCURL)

	// Create context
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()

	// Connect to RPC
	rpcClient, err := rpc.DialContext(ctx, l2RPCURL)
	require.NoError(t, err, "Failed to connect to RPC")
	defer rpcClient.Close()

	// Get latest block number
	var blockNumberHex string
	err = rpcClient.CallContext(ctx, &blockNumberHex, "eth_blockNumber")
	require.NoError(t, err, "Failed to get block number")

	blockNumber := hexToUint64(blockNumberHex)
	t.Logf("Latest block number: %d", blockNumber)

	// Use a block that's a few blocks old to ensure it's finalized
	if blockNumber > 5 {
		blockNumber -= 3
	}
	t.Logf("Using block number: %d", blockNumber)

	// Generate random value (simulate RAT test ID)
	// Use a value in the middle of the hash space to ensure it falls between leaves
	randomValue := new(big.Int)
	randomValue.SetString("5000000000000000000000000000000000000000000000000000000000000000", 16)
	t.Logf("Random value (test ID): 0x%x", randomValue)

	// Find adjacent leaves using RPC
	t.Log("Finding adjacent leaves via RPC...")
	startTime := time.Now()
	leaves, err := l2sync.FindAdjacentLeavesViaRPC(ctx, rpcClient, randomValue, blockNumber)
	require.NoError(t, err, "Failed to find adjacent leaves")
	duration := time.Since(startTime)
	t.Logf("Found adjacent leaves in %s", duration)

	// Verify leaves structure
	require.NotNil(t, leaves.LeafA, "LeafA should not be nil")
	require.NotNil(t, leaves.LeafB, "LeafB should not be nil")
	require.NotEmpty(t, leaves.ProofA, "ProofA should not be empty")
	require.NotEmpty(t, leaves.ProofB, "ProofB should not be empty")
	require.Equal(t, blockNumber, leaves.BlockNumber, "Block number mismatch")

	t.Logf("LeafA address: %s", leaves.LeafA.Address.Hex())
	t.Logf("LeafA key: %s", leaves.LeafA.Key.Hex())
	t.Logf("LeafA balance: %s", leaves.LeafA.Balance.String())
	t.Logf("LeafB address: %s", leaves.LeafB.Address.Hex())
	t.Logf("LeafB key: %s", leaves.LeafB.Key.Hex())
	t.Logf("LeafB balance: %s", leaves.LeafB.Balance.String())
	t.Logf("ProofA nodes: %d", len(leaves.ProofA))
	t.Logf("ProofB nodes: %d", len(leaves.ProofB))
	t.Logf("State root: %s", leaves.StateRoot.Hex())

	// Verify ordering: leafA.key < leafB.key
	require.True(t, leaves.LeafA.Key.Big().Cmp(leaves.LeafB.Key.Big()) < 0,
		"LeafA key should be less than LeafB key")

	// Create StateLeafEvidence
	t.Log("Creating StateLeafEvidence...")
	ev, err := evidence.NewStateLeafEvidence(leaves)
	require.NoError(t, err, "Failed to create evidence")

	// Validate evidence
	t.Log("Validating evidence...")
	err = ev.Validate()
	require.NoError(t, err, "Evidence validation failed")

	// Verify range
	t.Log("Verifying adjacent leaves range...")
	isValidRange := ev.VerifyRange(randomValue)
	require.True(t, isValidRange, "Range verification failed")

	// Encode evidence
	t.Log("Encoding evidence...")
	evidenceData, err := ev.Encode()
	require.NoError(t, err, "Failed to encode evidence")
	t.Logf("Evidence size: %d bytes", len(evidenceData))

	// Summary
	t.Log("=== E2E Test Summary ===")
	t.Logf("✅ Successfully generated StateLeafEvidence via RPC")
	t.Logf("   - Block: %d", blockNumber)
	t.Logf("   - State root: %s", leaves.StateRoot.Hex())
	t.Logf("   - LeafA: %s (balance: %s)", leaves.LeafA.Address.Hex(), leaves.LeafA.Balance.String())
	t.Logf("   - LeafB: %s (balance: %s)", leaves.LeafB.Address.Hex(), leaves.LeafB.Balance.String())
	t.Logf("   - Proof size: %d + %d nodes", len(leaves.ProofA), len(leaves.ProofB))
	t.Logf("   - Evidence size: %d bytes", len(evidenceData))
	t.Logf("   - Generation time: %s", duration)
	t.Log("========================")
}

// TestStateLeafRPCWithMultipleBlocks tests adjacent leaves across different blocks using RPC
func TestStateLeafRPCWithMultipleBlocks(t *testing.T) {
	if os.Getenv("E2E_TEST") != "1" {
		t.Skip("Skipping E2E test. Set E2E_TEST=1 to run.")
	}

	l2RPCURL := getEnvOrDefault("L2_RPC_URL", "http://localhost:9545")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	rpcClient, err := rpc.DialContext(ctx, l2RPCURL)
	require.NoError(t, err)
	defer rpcClient.Close()

	// Get latest block
	var blockNumberHex string
	err = rpcClient.CallContext(ctx, &blockNumberHex, "eth_blockNumber")
	require.NoError(t, err)
	latestBlock := hexToUint64(blockNumberHex)

	// Test with 3 different blocks
	blocksToTest := []uint64{
		latestBlock,
	}
	if latestBlock >= 10 {
		blocksToTest = append(blocksToTest, latestBlock-10)
	}
	if latestBlock >= 20 {
		blocksToTest = append(blocksToTest, latestBlock-20)
	}

	randomValue := big.NewInt(0xdeadbeef)

	for _, blockNum := range blocksToTest {
		if blockNum == 0 {
			continue
		}

		t.Logf("Testing block %d", blockNum)

		leaves, err := l2sync.FindAdjacentLeavesViaRPC(ctx, rpcClient, randomValue, blockNum)
		require.NoError(t, err, "Failed for block %d", blockNum)

		ev, err := evidence.NewStateLeafEvidence(leaves)
		require.NoError(t, err, "Failed to create evidence for block %d", blockNum)

		err = ev.Validate()
		require.NoError(t, err, "Validation failed for block %d", blockNum)

		t.Logf("✅ Block %d: %d + %d proof nodes", blockNum, len(leaves.ProofA), len(leaves.ProofB))
	}
}

// TestStateLeafRPCEdgeCases tests edge cases for adjacent leaves via RPC
func TestStateLeafRPCEdgeCases(t *testing.T) {
	if os.Getenv("E2E_TEST") != "1" {
		t.Skip("Skipping E2E test. Set E2E_TEST=1 to run.")
	}

	l2RPCURL := getEnvOrDefault("L2_RPC_URL", "http://localhost:9545")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	rpcClient, err := rpc.DialContext(ctx, l2RPCURL)
	require.NoError(t, err)
	defer rpcClient.Close()

	// Get latest block
	var blockNumberHex string
	err = rpcClient.CallContext(ctx, &blockNumberHex, "eth_blockNumber")
	require.NoError(t, err)
	blockNumber := hexToUint64(blockNumberHex)

	if blockNumber > 5 {
		blockNumber -= 3
	}

	testCases := []struct {
		name        string
		randomValue *big.Int
		description string
	}{
		{
			name:        "Very small value",
			randomValue: big.NewInt(1),
			description: "Should return first two leaves",
		},
		{
			name: "Very large value",
			randomValue: func() *big.Int {
				val := big.NewInt(1)
				return val.Lsh(val, 255) // 2^255
			}(),
			description: "Should return last two leaves",
		},
		{
			name: "Medium value",
			randomValue: func() *big.Int {
				val := big.NewInt(1)
				return val.Lsh(val, 128) // 2^128
			}(),
			description: "Should return adjacent leaves in middle of trie",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			t.Logf("Testing: %s", tc.description)
			t.Logf("Random value: 0x%x", tc.randomValue)

			leaves, err := l2sync.FindAdjacentLeavesViaRPC(ctx, rpcClient, tc.randomValue, blockNumber)
			require.NoError(t, err)

			require.NotNil(t, leaves.LeafA)
			require.NotNil(t, leaves.LeafB)

			// Verify ordering: leafA.key < leafB.key
			require.True(t, leaves.LeafA.Key.Big().Cmp(leaves.LeafB.Key.Big()) < 0,
				"LeafA key should be less than LeafB key")

			t.Logf("✅ %s: LeafA=%s, LeafB=%s",
				tc.name, leaves.LeafA.Key.Hex()[:10], leaves.LeafB.Key.Hex()[:10])
		})
	}
}
