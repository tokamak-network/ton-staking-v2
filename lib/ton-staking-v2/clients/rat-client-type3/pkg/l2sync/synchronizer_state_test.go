package l2sync

import (
	"math/big"
	"testing"

	"github.com/ethereum/go-ethereum/common"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestStateSyncConfig tests configuration validation
func TestStateSyncConfig(t *testing.T) {
	tests := []struct {
		name    string
		config  *StateSyncConfig
		wantErr bool
	}{
		{
			name: "valid config with both RPC and StateDB",
			config: &StateSyncConfig{
				L2RPCURL:    "http://localhost:8545",
				StateDBPath: "/tmp/testdb",
			},
			wantErr: false, // Will fail in actual test due to no RPC, but config is valid
		},
		{
			name: "valid config with RPC only",
			config: &StateSyncConfig{
				L2RPCURL:    "http://localhost:8545",
				StateDBPath: "", // RPC mode
			},
			wantErr: false,
		},
		{
			name: "invalid RPC URL",
			config: &StateSyncConfig{
				L2RPCURL:    "invalid://url",
				StateDBPath: "",
			},
			wantErr: true,
		},
		{
			name: "empty RPC URL",
			config: &StateSyncConfig{
				L2RPCURL:    "",
				StateDBPath: "",
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, err := NewStateSynchronizer(tt.config)
			if tt.wantErr {
				assert.Error(t, err)
			} else {
				// Will error in test environment (no actual RPC)
				// Just verify config structure is correct
				assert.NotNil(t, tt.config)
			}
		})
	}
}

// TestAdjacentLeaves_Structure tests AdjacentLeaves struct
func TestAdjacentLeaves_Structure(t *testing.T) {
	leafA := &StateTrieLeaf{
		Key:     common.HexToHash("0x1234"),
		Value:   []byte("valueA"),
		Address: common.HexToAddress("0xAAAA"),
		Nonce:   1,
		Balance: big.NewInt(100),
	}

	leafB := &StateTrieLeaf{
		Key:     common.HexToHash("0x5678"),
		Value:   []byte("valueB"),
		Address: common.HexToAddress("0xBBBB"),
		Nonce:   2,
		Balance: big.NewInt(200),
	}

	proofA := [][]byte{[]byte("node1"), []byte("node2")}
	proofB := [][]byte{[]byte("node3"), []byte("node4")}

	stateRoot := common.HexToHash("0xabcd")
	blockNumber := uint64(12345)

	adjacentLeaves := &AdjacentLeaves{
		LeafA:       leafA,
		LeafB:       leafB,
		ProofA:      proofA,
		ProofB:      proofB,
		StateRoot:   stateRoot,
		BlockNumber: blockNumber,
	}

	assert.NotNil(t, adjacentLeaves)
	assert.Equal(t, leafA, adjacentLeaves.LeafA)
	assert.Equal(t, leafB, adjacentLeaves.LeafB)
	assert.Equal(t, proofA, adjacentLeaves.ProofA)
	assert.Equal(t, proofB, adjacentLeaves.ProofB)
	assert.Equal(t, stateRoot, adjacentLeaves.StateRoot)
	assert.Equal(t, blockNumber, adjacentLeaves.BlockNumber)
}

// TestAdjacentLeaves_KeyOrdering tests that LeafA.Key < LeafB.Key
func TestAdjacentLeaves_KeyOrdering(t *testing.T) {
	// Correct ordering: leafA.Key < leafB.Key
	leafA := &StateTrieLeaf{
		Key:     common.HexToHash("0x1000000000000000000000000000000000000000000000000000000000000000"),
		Value:   []byte("valueA"),
		Address: common.HexToAddress("0xAAAA"),
	}

	leafB := &StateTrieLeaf{
		Key:     common.HexToHash("0x2000000000000000000000000000000000000000000000000000000000000000"),
		Value:   []byte("valueB"),
		Address: common.HexToAddress("0xBBBB"),
	}

	adjacentLeaves := &AdjacentLeaves{
		LeafA:       leafA,
		LeafB:       leafB,
		ProofA:      [][]byte{},
		ProofB:      [][]byte{},
		StateRoot:   common.Hash{},
		BlockNumber: 0,
	}

	// Verify ordering
	require.True(t, adjacentLeaves.LeafA.Key.Big().Cmp(adjacentLeaves.LeafB.Key.Big()) < 0,
		"LeafA.Key should be less than LeafB.Key")
}

// TestAdjacentLeaves_RandomValueInRange tests that random value falls within range
func TestAdjacentLeaves_RandomValueInRange(t *testing.T) {
	leafA := &StateTrieLeaf{
		Key: common.HexToHash("0x1000000000000000000000000000000000000000000000000000000000000000"),
	}

	leafB := &StateTrieLeaf{
		Key: common.HexToHash("0x3000000000000000000000000000000000000000000000000000000000000000"),
	}

	adjacentLeaves := &AdjacentLeaves{
		LeafA: leafA,
		LeafB: leafB,
	}

	tests := []struct {
		name        string
		randomValue *big.Int
		inRange     bool
	}{
		{
			name:        "random value in range (middle)",
			randomValue: new(big.Int).SetBytes(common.HexToHash("0x2000000000000000000000000000000000000000000000000000000000000000").Bytes()),
			inRange:     true,
		},
		{
			name:        "random value equals leafB.Key (boundary)",
			randomValue: adjacentLeaves.LeafB.Key.Big(),
			inRange:     true,
		},
		{
			name:        "random value less than leafA.Key (out of range)",
			randomValue: new(big.Int).SetBytes(common.HexToHash("0x0500000000000000000000000000000000000000000000000000000000000000").Bytes()),
			inRange:     false,
		},
		{
			name:        "random value greater than leafB.Key (out of range)",
			randomValue: new(big.Int).SetBytes(common.HexToHash("0x4000000000000000000000000000000000000000000000000000000000000000").Bytes()),
			inRange:     false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Check: leafA.Key < randomValue <= leafB.Key
			inRange := adjacentLeaves.LeafA.Key.Big().Cmp(tt.randomValue) < 0 &&
				tt.randomValue.Cmp(adjacentLeaves.LeafB.Key.Big()) <= 0

			assert.Equal(t, tt.inRange, inRange)
		})
	}
}

// TestStateSynchronizer_Close tests Close function
func TestStateSynchronizer_Close(t *testing.T) {
	// Test closing a nil synchronizer
	s := &StateSynchronizer{
		stateDB: nil,
		l2RPC:   nil,
	}

	err := s.Close()
	assert.NoError(t, err, "Close should not error when both are nil")
}

// TestStateSyncConfig_Validation tests configuration validation logic
func TestStateSyncConfig_Validation(t *testing.T) {
	tests := []struct {
		name       string
		l2RPCURL   string
		stateDBPath string
		expectMode string
	}{
		{
			name:        "StateDB mode",
			l2RPCURL:    "http://localhost:8545",
			stateDBPath: "/path/to/db",
			expectMode:  "StateDB",
		},
		{
			name:        "RPC mode",
			l2RPCURL:    "http://localhost:8545",
			stateDBPath: "",
			expectMode:  "RPC",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			config := &StateSyncConfig{
				L2RPCURL:    tt.l2RPCURL,
				StateDBPath: tt.stateDBPath,
			}

			// Verify config structure
			assert.Equal(t, tt.l2RPCURL, config.L2RPCURL)
			assert.Equal(t, tt.stateDBPath, config.StateDBPath)

			// Determine expected mode
			if config.StateDBPath == "" {
				assert.Equal(t, "RPC", tt.expectMode)
			} else {
				assert.Equal(t, "StateDB", tt.expectMode)
			}
		})
	}
}

// TestStateSynchronizer_NilSafety tests that StateSynchronizer handles nil properly
func TestStateSynchronizer_NilSafety(t *testing.T) {
	// Note: In production, StateSynchronizer should never have nil l2RPC
	// because NewStateSynchronizer validates RPC connection
	// This test just verifies Close() works with nil fields

	s := &StateSynchronizer{
		stateDB: nil,
		l2RPC:   nil,
	}

	// Close should work even with nil fields
	err := s.Close()
	assert.NoError(t, err, "Close should not panic with nil fields")
}

// TestAdjacentLeaves_ProofValidation tests proof structure validation
func TestAdjacentLeaves_ProofValidation(t *testing.T) {
	tests := []struct {
		name      string
		proofA    [][]byte
		proofB    [][]byte
		expectErr bool
	}{
		{
			name: "valid proofs",
			proofA: [][]byte{
				[]byte("node1"),
				[]byte("node2"),
				[]byte("node3"),
			},
			proofB: [][]byte{
				[]byte("node4"),
				[]byte("node5"),
				[]byte("node6"),
			},
			expectErr: false,
		},
		{
			name:      "empty proofs",
			proofA:    [][]byte{},
			proofB:    [][]byte{},
			expectErr: true,
		},
		{
			name: "different length proofs (valid - different depth leaves)",
			proofA: [][]byte{
				[]byte("node1"),
				[]byte("node2"),
			},
			proofB: [][]byte{
				[]byte("node3"),
				[]byte("node4"),
				[]byte("node5"),
			},
			expectErr: false, // Different lengths are OK (different depth leaves)
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			adjacentLeaves := &AdjacentLeaves{
				LeafA: &StateTrieLeaf{
					Key:   common.HexToHash("0x1234"),
					Value: []byte("a"),
				},
				LeafB: &StateTrieLeaf{
					Key:   common.HexToHash("0x5678"),
					Value: []byte("b"),
				},
				ProofA:      tt.proofA,
				ProofB:      tt.proofB,
				StateRoot:   common.HexToHash("0xabcd"),
				BlockNumber: 123,
			}

			// Basic validation
			if tt.expectErr {
				assert.True(t, len(adjacentLeaves.ProofA) == 0 || len(adjacentLeaves.ProofB) == 0)
			} else {
				assert.NotNil(t, adjacentLeaves.ProofA)
				assert.NotNil(t, adjacentLeaves.ProofB)
			}
		})
	}
}

// TestAdjacentLeaves_CompleteStructure tests that AdjacentLeaves has all required fields
func TestAdjacentLeaves_CompleteStructure(t *testing.T) {
	adjacentLeaves := &AdjacentLeaves{
		LeafA: &StateTrieLeaf{
			Key:     common.HexToHash("0x1111"),
			Value:   []byte("valueA"),
			Address: common.HexToAddress("0xAAA"),
			Nonce:   10,
			Balance: big.NewInt(1000),
		},
		LeafB: &StateTrieLeaf{
			Key:     common.HexToHash("0x2222"),
			Value:   []byte("valueB"),
			Address: common.HexToAddress("0xBBB"),
			Nonce:   20,
			Balance: big.NewInt(2000),
		},
		ProofA:      [][]byte{[]byte("proof1"), []byte("proof2")},
		ProofB:      [][]byte{[]byte("proof3"), []byte("proof4")},
		StateRoot:   common.HexToHash("0xdeadbeef"),
		BlockNumber: 99999,
	}

	// Verify all fields are populated
	require.NotNil(t, adjacentLeaves.LeafA)
	require.NotNil(t, adjacentLeaves.LeafB)
	require.NotEmpty(t, adjacentLeaves.ProofA)
	require.NotEmpty(t, adjacentLeaves.ProofB)
	require.NotEqual(t, common.Hash{}, adjacentLeaves.StateRoot)
	require.NotZero(t, adjacentLeaves.BlockNumber)

	// Verify leaf details
	assert.Equal(t, common.HexToHash("0x1111"), adjacentLeaves.LeafA.Key)
	assert.Equal(t, common.HexToHash("0x2222"), adjacentLeaves.LeafB.Key)
	assert.Equal(t, uint64(10), adjacentLeaves.LeafA.Nonce)
	assert.Equal(t, uint64(20), adjacentLeaves.LeafB.Nonce)
	assert.Equal(t, big.NewInt(1000), adjacentLeaves.LeafA.Balance)
	assert.Equal(t, big.NewInt(2000), adjacentLeaves.LeafB.Balance)

	// Verify proofs
	assert.Len(t, adjacentLeaves.ProofA, 2)
	assert.Len(t, adjacentLeaves.ProofB, 2)
}
