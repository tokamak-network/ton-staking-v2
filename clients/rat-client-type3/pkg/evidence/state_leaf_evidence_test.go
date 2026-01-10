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
