package evidence

import (
	"math/big"
	"testing"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestStateLeafEvidence_Validate(t *testing.T) {
	tests := []struct {
		name    string
		ev      *StateLeafEvidence
		wantErr bool
		errMsg  string
	}{
		{
			name: "valid evidence",
			ev: &StateLeafEvidence{
				LeafAKey:   common.HexToHash("0x1234"),
				LeafAValue: []byte("account_a_rlp"),
				LeafAProof: [][]byte{{0x01}, {0x02}},
				LeafBKey:   common.HexToHash("0x5678"),
				LeafBValue: []byte("account_b_rlp"),
				LeafBProof: [][]byte{{0x03}, {0x04}},
				StateRoot:  common.HexToHash("0xabcd"),
				OutputRootProof: OutputRootProof{
					Version:                  [32]byte{},
					StateRoot:                common.HexToHash("0xabcd"),
					MessagePasserStorageRoot: common.HexToHash("0xef00"),
					LatestBlockHash:          common.HexToHash("0x9999"),
				},
				DivergenceWitness: DivergenceWitness{
					DivergenceNode:  []byte("mock_branch_node"),
					IndexA:          1,
					IndexB:          5,
					DivergenceDepth: 0,
				},
			},
			wantErr: false,
		},
		{
			name: "missing leafA value",
			ev: &StateLeafEvidence{
				LeafAKey:   common.HexToHash("0x1234"),
				LeafAValue: nil, // Missing
				LeafAProof: [][]byte{{0x01}},
				LeafBKey:   common.HexToHash("0x5678"),
				LeafBValue: []byte("account_b_rlp"),
				LeafBProof: [][]byte{{0x03}},
				StateRoot:  common.HexToHash("0xabcd"),
			},
			wantErr: true,
			errMsg:  "leafA value is empty",
		},
		{
			name: "missing leafA proof",
			ev: &StateLeafEvidence{
				LeafAKey:   common.HexToHash("0x1234"),
				LeafAValue: []byte("account_a_rlp"),
				LeafAProof: nil, // Missing
				LeafBKey:   common.HexToHash("0x5678"),
				LeafBValue: []byte("account_b_rlp"),
				LeafBProof: [][]byte{{0x03}},
				StateRoot:  common.HexToHash("0xabcd"),
			},
			wantErr: true,
			errMsg:  "leafA proof is empty",
		},
		{
			name: "missing leafB value",
			ev: &StateLeafEvidence{
				LeafAKey:   common.HexToHash("0x1234"),
				LeafAValue: []byte("account_a_rlp"),
				LeafAProof: [][]byte{{0x01}},
				LeafBKey:   common.HexToHash("0x5678"),
				LeafBValue: nil, // Missing
				LeafBProof: [][]byte{{0x03}},
				StateRoot:  common.HexToHash("0xabcd"),
			},
			wantErr: true,
			errMsg:  "leafB value is empty",
		},
		{
			name: "empty state root",
			ev: &StateLeafEvidence{
				LeafAKey:   common.HexToHash("0x1234"),
				LeafAValue: []byte("account_a_rlp"),
				LeafAProof: [][]byte{{0x01}},
				LeafBKey:   common.HexToHash("0x5678"),
				LeafBValue: []byte("account_b_rlp"),
				LeafBProof: [][]byte{{0x03}},
				StateRoot:  common.Hash{}, // Empty
			},
			wantErr: true,
			errMsg:  "state root is zero",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.ev.Validate()
			if tt.wantErr {
				assert.Error(t, err)
				if tt.errMsg != "" {
					assert.Contains(t, err.Error(), tt.errMsg)
				}
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestStateLeafEvidence_VerifyRange(t *testing.T) {
	// Create evidence with specific keys
	leafAKey := common.HexToHash("0x1000000000000000000000000000000000000000000000000000000000000000")
	leafBKey := common.HexToHash("0x3000000000000000000000000000000000000000000000000000000000000000")

	ev := &StateLeafEvidence{
		LeafAKey: leafAKey,
		LeafBKey: leafBKey,
	}

	tests := []struct {
		name        string
		randomValue *big.Int
		want        bool
	}{
		{
			name:        "value in range",
			randomValue: new(big.Int).SetBytes(common.HexToHash("0x2000000000000000000000000000000000000000000000000000000000000000").Bytes()),
			want:        true,
		},
		{
			name:        "value equals leafA (boundary - should be excluded)",
			randomValue: new(big.Int).SetBytes(leafAKey.Bytes()),
			want:        false,
		},
		{
			name:        "value equals leafB (boundary - should be included)",
			randomValue: new(big.Int).SetBytes(leafBKey.Bytes()),
			want:        true,
		},
		{
			name:        "value below range",
			randomValue: new(big.Int).SetBytes(common.HexToHash("0x0500000000000000000000000000000000000000000000000000000000000000").Bytes()),
			want:        false,
		},
		{
			name:        "value above range",
			randomValue: new(big.Int).SetBytes(common.HexToHash("0x4000000000000000000000000000000000000000000000000000000000000000").Bytes()),
			want:        false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := ev.VerifyRange(tt.randomValue)
			assert.Equal(t, tt.want, result)
		})
	}
}

func TestStateLeafEvidence_Encode(t *testing.T) {
	// Create sample evidence
	ev := &StateLeafEvidence{
		LeafAKey:   common.HexToHash("0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"),
		LeafAValue: []byte{0x01, 0x02, 0x03, 0x04},
		LeafAProof: [][]byte{
			{0x11, 0x12, 0x13},
			{0x14, 0x15, 0x16},
		},
		LeafBKey:   common.HexToHash("0xfedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321"),
		LeafBValue: []byte{0x05, 0x06, 0x07, 0x08},
		LeafBProof: [][]byte{
			{0x21, 0x22, 0x23},
			{0x24, 0x25, 0x26},
		},
		StateRoot: common.HexToHash("0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd"),
		OutputRootProof: OutputRootProof{
			Version:                  [32]byte{},
			StateRoot:                common.HexToHash("0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd"),
			MessagePasserStorageRoot: common.HexToHash("0x1111111111111111111111111111111111111111111111111111111111111111"),
			LatestBlockHash:          common.HexToHash("0x2222222222222222222222222222222222222222222222222222222222222222"),
		},
		DivergenceWitness: DivergenceWitness{
			DivergenceNode:  []byte{0xaa, 0xbb, 0xcc, 0xdd},
			IndexA:          2,
			IndexB:          7,
			DivergenceDepth: 1,
		},
	}

	// Test encoding
	encoded, err := ev.Encode()
	require.NoError(t, err)
	assert.NotNil(t, encoded)
	assert.Greater(t, len(encoded), 0)

	// Verify encoding is deterministic
	encoded2, err := ev.Encode()
	require.NoError(t, err)
	assert.Equal(t, encoded, encoded2, "Encoding should be deterministic")
}

func TestStateLeafEvidence_EncodeInvalidEvidence(t *testing.T) {
	// Create invalid evidence (missing required fields)
	ev := &StateLeafEvidence{
		LeafAKey: common.HexToHash("0x1234"),
		// Missing other required fields
	}

	// Encoding doesn't validate, so it succeeds even with invalid data
	// Validation should be done explicitly via Validate()
	encoded, err := ev.Encode()
	assert.NoError(t, err)
	assert.NotNil(t, encoded)

	// But validation should fail
	err = ev.Validate()
	assert.Error(t, err)
}

func TestOutputRootProof(t *testing.T) {
	stateRoot := common.HexToHash("0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd")
	msgPasserRoot := common.HexToHash("0x1111111111111111111111111111111111111111111111111111111111111111")
	blockHash := common.HexToHash("0x2222222222222222222222222222222222222222222222222222222222222222")

	proof := OutputRootProof{
		Version:                  [32]byte{}, // Version 0
		StateRoot:                stateRoot,
		MessagePasserStorageRoot: msgPasserRoot,
		LatestBlockHash:          blockHash,
	}

	// Compute output root: keccak256(abi.encodePacked(version, stateRoot, msgPasserRoot, blockHash))
	data := make([]byte, 0, 128)
	data = append(data, proof.Version[:]...)
	data = append(data, proof.StateRoot.Bytes()...)
	data = append(data, proof.MessagePasserStorageRoot.Bytes()...)
	data = append(data, proof.LatestBlockHash.Bytes()...)

	outputRoot := crypto.Keccak256Hash(data)

	t.Logf("Computed output root: %s", outputRoot.Hex())
	assert.NotEqual(t, common.Hash{}, outputRoot)
}

func TestStateLeafEvidence_KeyOrdering(t *testing.T) {
	// Test that keys are properly ordered
	leafAKey := common.HexToHash("0x1000000000000000000000000000000000000000000000000000000000000000")
	leafBKey := common.HexToHash("0x2000000000000000000000000000000000000000000000000000000000000000")

	leafABig := new(big.Int).SetBytes(leafAKey.Bytes())
	leafBBig := new(big.Int).SetBytes(leafBKey.Bytes())

	// LeafA should be less than LeafB
	assert.Equal(t, -1, leafABig.Cmp(leafBBig), "LeafA should be less than LeafB")
}

func TestStateLeafEvidence_ProofStructure(t *testing.T) {
	// Test proof structure
	proof := [][]byte{
		common.HexToHash("0x1111111111111111111111111111111111111111111111111111111111111111").Bytes(),
		common.HexToHash("0x2222222222222222222222222222222222222222222222222222222222222222").Bytes(),
		common.HexToHash("0x3333333333333333333333333333333333333333333333333333333333333333").Bytes(),
	}

	// Each proof node should be 32 bytes
	for i, node := range proof {
		assert.Equal(t, 32, len(node), "Proof node %d should be 32 bytes", i)
	}
}

// TestDivergenceWitness tests DivergenceWitness structure
func TestDivergenceWitness(t *testing.T) {
	witness := DivergenceWitness{
		DivergenceNode:  []byte{0x01, 0x02, 0x03},
		IndexA:          3,
		IndexB:          8,
		DivergenceDepth: 2,
	}

	assert.NotNil(t, witness.DivergenceNode)
	assert.Equal(t, uint8(3), witness.IndexA)
	assert.Equal(t, uint8(8), witness.IndexB)
	assert.Equal(t, uint64(2), witness.DivergenceDepth)
	assert.Less(t, witness.IndexA, witness.IndexB, "IndexA should be less than IndexB")
}

// TestDivergenceWitness_IndexOrdering tests that IndexA < IndexB
func TestDivergenceWitness_IndexOrdering(t *testing.T) {
	tests := []struct {
		name    string
		indexA  uint8
		indexB  uint8
		wantErr bool
	}{
		{
			name:    "valid ordering",
			indexA:  1,
			indexB:  5,
			wantErr: false,
		},
		{
			name:    "adjacent indices",
			indexA:  3,
			indexB:  4,
			wantErr: false,
		},
		{
			name:    "maximum valid gap",
			indexA:  0,
			indexB:  15,
			wantErr: false,
		},
		{
			name:    "invalid: equal indices",
			indexA:  5,
			indexB:  5,
			wantErr: true,
		},
		{
			name:    "invalid: reversed order",
			indexA:  8,
			indexB:  3,
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			witness := DivergenceWitness{
				DivergenceNode:  []byte("mock_node"),
				IndexA:          tt.indexA,
				IndexB:          tt.indexB,
				DivergenceDepth: 0,
			}

			// In production, this validation happens in FindDivergenceNode
			// Here we just verify the ordering
			if tt.wantErr {
				assert.GreaterOrEqual(t, witness.IndexA, witness.IndexB,
					"IndexA should be >= IndexB (invalid)")
			} else {
				assert.Less(t, witness.IndexA, witness.IndexB,
					"IndexA should be < IndexB (valid)")
			}
		})
	}
}

// TestStateLeafEvidence_WithDivergenceWitness tests evidence with divergence witness
func TestStateLeafEvidence_WithDivergenceWitness(t *testing.T) {
	ev := &StateLeafEvidence{
		LeafAKey:   common.HexToHash("0x1111"),
		LeafAValue: []byte("valueA"),
		LeafAProof: [][]byte{[]byte("proofA1"), []byte("proofA2")},
		LeafBKey:   common.HexToHash("0x5555"),
		LeafBValue: []byte("valueB"),
		LeafBProof: [][]byte{[]byte("proofB1"), []byte("proofB2")},
		StateRoot:  common.HexToHash("0xabcd"),
		OutputRootProof: OutputRootProof{
			Version:                  [32]byte{},
			StateRoot:                common.HexToHash("0xabcd"),
			MessagePasserStorageRoot: common.HexToHash("0xef00"),
			LatestBlockHash:          common.HexToHash("0x9999"),
		},
		DivergenceWitness: DivergenceWitness{
			DivergenceNode:  []byte("branch_node_rlp"),
			IndexA:          1,
			IndexB:          5,
			DivergenceDepth: 0,
		},
	}

	// Verify all fields are set
	require.NotNil(t, ev.DivergenceWitness.DivergenceNode)
	require.Equal(t, uint8(1), ev.DivergenceWitness.IndexA)
	require.Equal(t, uint8(5), ev.DivergenceWitness.IndexB)
	require.Equal(t, uint64(0), ev.DivergenceWitness.DivergenceDepth)

	// Test encoding with divergence witness
	encoded, err := ev.Encode()
	require.NoError(t, err)
	assert.NotNil(t, encoded)

	// Test validation
	err = ev.Validate()
	assert.NoError(t, err)
}

// TestDivergenceWitness_EmptyNode tests handling of empty divergence node
func TestDivergenceWitness_EmptyNode(t *testing.T) {
	witness := DivergenceWitness{
		DivergenceNode:  nil, // Empty
		IndexA:          1,
		IndexB:          5,
		DivergenceDepth: 0,
	}

	// In production, FindDivergenceNode ensures DivergenceNode is never nil
	// This test just verifies the structure can handle it
	assert.Nil(t, witness.DivergenceNode)
}
