package test

import (
	"context"
	"math/big"
	"os"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/rawdb"
	"github.com/stretchr/testify/require"
	"github.com/tokamak-network/ton-staking-v2/clients/rat-client-type3/pkg/evidence"
	"github.com/tokamak-network/ton-staking-v2/clients/rat-client-type3/pkg/l2sync"
)

// TestStateLeafE2E tests the full StateLeaf evidence generation and verification flow
// This test requires:
// - op-geth running with accessible state database
// - L2 with some state (accounts)
func TestStateLeafE2E(t *testing.T) {
	// Skip if not in E2E mode
	if os.Getenv("E2E_TEST") != "1" {
		t.Skip("Skipping E2E test. Set E2E_TEST=1 to run.")
	}

	// Configuration from environment
	stateDBPath := getEnvOrDefault("STATE_DB_PATH", "/tmp/op-geth/chaindata")
	stateRootHex := os.Getenv("TEST_STATE_ROOT")
	blockNumberHex := os.Getenv("TEST_BLOCK_NUMBER")

	// Step 1: Open state database directly
	t.Log("Opening state database:", stateDBPath)
	stateDB, err := rawdb.NewLevelDBDatabase(stateDBPath, 128, 1024, "e2etest", false)
	require.NoError(t, err, "Failed to open state database")
	defer stateDB.Close()

	// Step 2: Get state root and block number from environment
	var stateRoot common.Hash
	var blockNumber uint64

	if stateRootHex != "" {
		stateRoot = common.HexToHash(stateRootHex)
		t.Logf("Using state root from env: %s", stateRoot.Hex())
	} else {
		t.Skip("TEST_STATE_ROOT not provided")
	}

	if blockNumberHex != "" {
		blockNumber = hexToUint64(blockNumberHex)
		t.Logf("Using block number from env: %d", blockNumber)
	} else {
		blockNumber = 10 // Default
		t.Logf("Using default block number: %d", blockNumber)
	}

	// Step 3: Check state size
	stateSize, err := l2sync.EstimateStateSize(stateDB, stateRoot)
	require.NoError(t, err, "Failed to estimate state size")
	t.Logf("Estimated state size: %d accounts (sample)", stateSize)
	require.Greater(t, stateSize, 0, "State trie should have at least one account")

	// Step 5: Generate random value (simulate RAT test ID)
	randomValue := big.NewInt(0x123456789abcdef0)
	t.Logf("Random value (test ID): 0x%x", randomValue)

	// Step 4: Find adjacent leaves
	t.Log("Finding adjacent leaves in state trie...")
	startTime := time.Now()
	leafA, leafB, err := l2sync.FindAdjacentLeavesInStateTrie(stateDB, stateRoot, randomValue)
	require.NoError(t, err, "Failed to find adjacent leaves")
	duration := time.Since(startTime)
	t.Logf("Found adjacent leaves in %s", duration)

	// Step 5: Generate proofs
	t.Log("Generating Merkle proofs...")
	proofA, err := l2sync.GenerateStateProof(stateDB, stateRoot, leafA.Key)
	require.NoError(t, err, "Failed to generate proof for leafA")

	proofB, err := l2sync.GenerateStateProof(stateDB, stateRoot, leafB.Key)
	require.NoError(t, err, "Failed to generate proof for leafB")

	// Create AdjacentLeaves structure
	leaves := &l2sync.AdjacentLeaves{
		LeafA:       leafA,
		LeafB:       leafB,
		ProofA:      proofA,
		ProofB:      proofB,
		StateRoot:   stateRoot,
		BlockNumber: blockNumber,
	}

	// Step 7: Verify leaves structure
	require.NotNil(t, leaves.LeafA, "LeafA should not be nil")
	require.NotNil(t, leaves.LeafB, "LeafB should not be nil")
	require.NotEmpty(t, leaves.ProofA, "ProofA should not be empty")
	require.NotEmpty(t, leaves.ProofB, "ProofB should not be empty")
	require.Equal(t, blockNumber, leaves.BlockNumber, "Block number mismatch")

	t.Logf("LeafA key: %s", leaves.LeafA.Key.Hex())
	t.Logf("LeafA balance: %s", leaves.LeafA.Balance.String())
	t.Logf("LeafB key: %s", leaves.LeafB.Key.Hex())
	t.Logf("LeafB balance: %s", leaves.LeafB.Balance.String())
	t.Logf("ProofA nodes: %d", len(leaves.ProofA))
	t.Logf("ProofB nodes: %d", len(leaves.ProofB))
	t.Logf("State root: %s", leaves.StateRoot.Hex())

	// Step 8: Create StateLeafEvidence
	t.Log("Creating StateLeafEvidence...")
	ev, err := evidence.NewStateLeafEvidence(leaves)
	require.NoError(t, err, "Failed to create evidence")

	// Step 9: Validate evidence
	t.Log("Validating evidence...")
	err = ev.Validate()
	require.NoError(t, err, "Evidence validation failed")

	// Step 10: Verify range
	t.Log("Verifying adjacent leaves range...")
	isValidRange := ev.VerifyRange(randomValue)
	require.True(t, isValidRange, "Range verification failed")

	// Step 11: Encode evidence
	t.Log("Encoding evidence...")
	evidenceData, err := ev.Encode()
	require.NoError(t, err, "Failed to encode evidence")
	t.Logf("Evidence size: %d bytes", len(evidenceData))

	// Step 12: Summary
	t.Log("=== E2E Test Summary ===")
	t.Logf("✅ Successfully generated StateLeafEvidence")
	t.Logf("   - Block: %d", blockNumber)
	t.Logf("   - State root: %s", leaves.StateRoot.Hex())
	t.Logf("   - LeafA: %s (balance: %s)", leaves.LeafA.Key.Hex(), leaves.LeafA.Balance.String())
	t.Logf("   - LeafB: %s (balance: %s)", leaves.LeafB.Key.Hex(), leaves.LeafB.Balance.String())
	t.Logf("   - Proof size: %d + %d nodes", len(leaves.ProofA), len(leaves.ProofB))
	t.Logf("   - Evidence size: %d bytes", len(evidenceData))
	t.Logf("   - Generation time: %s", duration)
	t.Log("========================")
}

// TestStateLeafWithMultipleBlocks tests adjacent leaves across different blocks
func TestStateLeafWithMultipleBlocks(t *testing.T) {
	if os.Getenv("E2E_TEST") != "1" {
		t.Skip("Skipping E2E test. Set E2E_TEST=1 to run.")
	}

	l2RPCURL := getEnvOrDefault("L2_RPC_URL", "http://localhost:9545")
	stateDBPath := getEnvOrDefault("STATE_DB_PATH", "/tmp/op-geth/chaindata")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	stateSyncer, err := l2sync.NewStateSynchronizer(&l2sync.StateSyncConfig{
		L2RPCURL:    l2RPCURL,
		StateDBPath: stateDBPath,
	})
	require.NoError(t, err)
	defer stateSyncer.Close()

	latestBlock, err := stateSyncer.GetLatestBlockNumber(ctx)
	require.NoError(t, err)

	// Test with 3 different blocks
	blocksToTest := []uint64{
		latestBlock,
		latestBlock - 10,
		latestBlock - 20,
	}

	randomValue := big.NewInt(0xdeadbeef)

	for _, blockNum := range blocksToTest {
		if blockNum == 0 {
			continue
		}

		t.Logf("Testing block %d", blockNum)

		leaves, err := stateSyncer.FindAdjacentLeaves(ctx, randomValue, blockNum)
		require.NoError(t, err, "Failed for block %d", blockNum)

		ev, err := evidence.NewStateLeafEvidence(leaves)
		require.NoError(t, err, "Failed to create evidence for block %d", blockNum)

		err = ev.Validate()
		require.NoError(t, err, "Validation failed for block %d", blockNum)

		t.Logf("✅ Block %d: %d + %d proof nodes", blockNum, len(leaves.ProofA), len(leaves.ProofB))
	}
}

// TestEdgeCases tests edge cases for adjacent leaves
func TestEdgeCases(t *testing.T) {
	if os.Getenv("E2E_TEST") != "1" {
		t.Skip("Skipping E2E test. Set E2E_TEST=1 to run.")
	}

	l2RPCURL := getEnvOrDefault("L2_RPC_URL", "http://localhost:9545")
	stateDBPath := getEnvOrDefault("STATE_DB_PATH", "/tmp/op-geth/chaindata")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	stateSyncer, err := l2sync.NewStateSynchronizer(&l2sync.StateSyncConfig{
		L2RPCURL:    l2RPCURL,
		StateDBPath: stateDBPath,
	})
	require.NoError(t, err)
	defer stateSyncer.Close()

	latestBlock, err := stateSyncer.GetLatestBlockNumber(ctx)
	require.NoError(t, err)

	blockNumber := latestBlock
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

			leaves, err := stateSyncer.FindAdjacentLeaves(ctx, tc.randomValue, blockNumber)
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

// Helper function to get environment variable with default
func getEnvOrDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// Helper function to convert hex string to uint64
func hexToUint64(hexStr string) uint64 {
	// Remove 0x prefix if present
	hexStr = strings.TrimPrefix(hexStr, "0x")
	val, err := strconv.ParseUint(hexStr, 16, 64)
	if err != nil {
		return 0
	}
	return val
}
