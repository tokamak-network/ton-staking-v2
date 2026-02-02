package l2sync

import (
	"testing"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/rlp"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestGetNibbleAt tests nibble extraction from hash keys
func TestGetNibbleAt(t *testing.T) {
	tests := []struct {
		name     string
		key      []byte
		depth    uint64
		expected uint8
	}{
		{
			name:     "first nibble (high bits of byte 0)",
			key:      []byte{0xAB, 0xCD},
			depth:    0,
			expected: 0x0A, // High nibble of 0xAB
		},
		{
			name:     "second nibble (low bits of byte 0)",
			key:      []byte{0xAB, 0xCD},
			depth:    1,
			expected: 0x0B, // Low nibble of 0xAB
		},
		{
			name:     "third nibble (high bits of byte 1)",
			key:      []byte{0xAB, 0xCD},
			depth:    2,
			expected: 0x0C, // High nibble of 0xCD
		},
		{
			name:     "fourth nibble (low bits of byte 1)",
			key:      []byte{0xAB, 0xCD},
			depth:    3,
			expected: 0x0D, // Low nibble of 0xCD
		},
		{
			name:     "out of bounds returns 0",
			key:      []byte{0xAB},
			depth:    10,
			expected: 0x00,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := getNibbleAt(tt.key, tt.depth)
			assert.Equal(t, tt.expected, result)
		})
	}
}

// TestFindChildIndices tests finding child indices in branch node
func TestFindChildIndices(t *testing.T) {
	// Create two keys that differ at a specific nibble
	// keyA: 0x1234... (nibble at depth 0 = 0x1)
	// keyB: 0x5678... (nibble at depth 0 = 0x5)
	keyA := common.HexToHash("0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef")
	keyB := common.HexToHash("0x5678567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef")

	// Create dummy branch node (not actually used, just needs to be non-nil)
	branchNode := []byte{0x01, 0x02, 0x03}

	indexA, indexB, err := FindChildIndices(branchNode, keyA, keyB, 0)

	require.NoError(t, err)
	assert.Equal(t, uint8(0x1), indexA) // First nibble of keyA
	assert.Equal(t, uint8(0x5), indexB) // First nibble of keyB
	assert.Less(t, indexA, indexB, "indexA should be less than indexB")
}

// TestFindChildIndices_InvalidOrder tests error when indexA >= indexB
func TestFindChildIndices_InvalidOrder(t *testing.T) {
	// Both keys start with same nibble - should fail
	keyA := common.HexToHash("0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef")
	keyB := common.HexToHash("0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef")

	branchNode := []byte{0x01, 0x02, 0x03}

	_, _, err := FindChildIndices(branchNode, keyA, keyB, 0)

	assert.Error(t, err)
	assert.Contains(t, err.Error(), "indexA must be < indexB")
}

// TestIsLeafNode tests leaf node detection from RLP-encoded data
func TestIsLeafNode(t *testing.T) {
	tests := []struct {
		name       string
		nodeData   []byte
		expected   bool
		shouldFail bool
	}{
		{
			name:     "empty slot (0x80 decoded)",
			nodeData: []byte{},
			expected: false,
		},
		{
			name:     "32-byte hash (sub-branch reference)",
			nodeData: make([]byte, 32),
			expected: false,
		},
		{
			name: "leaf node with 0x20 prefix (even length)",
			nodeData: func() []byte {
				// Create a 2-element RLP list with leaf prefix
				path := []byte{0x20, 0x12, 0x34} // 0x2 = leaf, even length
				value := []byte("test_value")
				encoded, _ := rlp.EncodeToBytes([][]byte{path, value})
				return encoded
			}(),
			expected: true,
		},
		{
			name: "leaf node with 0x30 prefix (odd length)",
			nodeData: func() []byte {
				// Create a 2-element RLP list with leaf prefix
				path := []byte{0x31, 0x23, 0x45} // 0x3 = leaf, odd length
				value := []byte("test_value")
				encoded, _ := rlp.EncodeToBytes([][]byte{path, value})
				return encoded
			}(),
			expected: true,
		},
		{
			name: "extension node with 0x00 prefix",
			nodeData: func() []byte {
				path := []byte{0x00, 0x12, 0x34} // 0x0 = extension
				hash := make([]byte, 32)
				encoded, _ := rlp.EncodeToBytes([][]byte{path, hash})
				return encoded
			}(),
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := isLeafNode(tt.nodeData)
			if tt.shouldFail {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
				assert.Equal(t, tt.expected, result)
			}
		})
	}
}

// TestVerifyGapBetweenIndices tests gap validation between indices
func TestVerifyGapBetweenIndices(t *testing.T) {
	tests := []struct {
		name        string
		indexA      uint8
		indexB      uint8
		setupBranch func() []byte
		expected    bool
		shouldFail  bool
	}{
		{
			name:   "adjacent indices (no gap)",
			indexA: 3,
			indexB: 4,
			setupBranch: func() []byte {
				// Create a branch node with 17 elements
				// indexA=3, indexB=4, so no gap to check
				items := make([][]byte, 17)
				for i := 0; i < 17; i++ {
					items[i] = []byte{} // Empty slots
				}
				items[3] = []byte("leaf_a")
				items[4] = []byte("leaf_b")
				encoded, _ := rlp.EncodeToBytes(items)
				return encoded
			},
			expected: true, // No gap to check, should pass
		},
		{
			name:   "gap with all empty slots",
			indexA: 2,
			indexB: 5,
			setupBranch: func() []byte {
				items := make([][]byte, 17)
				for i := 0; i < 17; i++ {
					items[i] = []byte{} // All empty (0x80 when encoded)
				}
				items[2] = []byte("leaf_a")
				items[5] = []byte("leaf_b")
				encoded, _ := rlp.EncodeToBytes(items)
				return encoded
			},
			expected: true, // Gap slots (3, 4) are empty
		},
		{
			name:   "gap with non-empty slot",
			indexA: 2,
			indexB: 5,
			setupBranch: func() []byte {
				items := make([][]byte, 17)
				for i := 0; i < 17; i++ {
					items[i] = []byte{}
				}
				items[2] = []byte("leaf_a")
				items[3] = []byte("unexpected_node") // Non-empty slot in gap!
				items[5] = []byte("leaf_b")
				encoded, _ := rlp.EncodeToBytes(items)
				return encoded
			},
			expected: false, // Gap has non-empty slot
		},
		{
			name:   "invalid branch node (not 17 elements)",
			indexA: 2,
			indexB: 5,
			setupBranch: func() []byte {
				items := make([][]byte, 10) // Only 10 elements!
				encoded, _ := rlp.EncodeToBytes(items)
				return encoded
			},
			shouldFail: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			branchNode := tt.setupBranch()
			result, err := VerifyGapBetweenIndices(branchNode, tt.indexA, tt.indexB)

			if tt.shouldFail {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
				assert.Equal(t, tt.expected, result)
			}
		})
	}
}

// TestVerifyDirectDivergence tests direct divergence verification
func TestVerifyDirectDivergence(t *testing.T) {
	tests := []struct {
		name        string
		indexA      uint8
		indexB      uint8
		setupBranch func() []byte
		expected    bool
		shouldFail  bool
	}{
		{
			name:   "both slots are leaf nodes",
			indexA: 2,
			indexB: 5,
			setupBranch: func() []byte {
				items := make([][]byte, 17)
				for i := 0; i < 17; i++ {
					items[i] = []byte{}
				}
				// Create leaf nodes with 0x20 prefix (leaf, even length)
				path := []byte{0x20, 0x12}
				value := []byte("val")
				leafNode, _ := rlp.EncodeToBytes([][]byte{path, value})
				items[2] = leafNode
				items[5] = leafNode
				encoded, _ := rlp.EncodeToBytes(items)
				return encoded
			},
			expected: true,
		},
		{
			name:   "indexA is leaf, indexB is 32-byte hash (sub-branch)",
			indexA: 2,
			indexB: 5,
			setupBranch: func() []byte {
				items := make([][]byte, 17)
				for i := 0; i < 17; i++ {
					items[i] = []byte{}
				}
				// indexA: leaf node
				path := []byte{0x20, 0x12}
				value := []byte("val")
				leafNode, _ := rlp.EncodeToBytes([][]byte{path, value})
				items[2] = leafNode
				// indexB: 32-byte hash (sub-branch reference)
				items[5] = make([]byte, 32)
				encoded, _ := rlp.EncodeToBytes(items)
				return encoded
			},
			expected: false, // Not direct divergence
		},
		{
			name:   "both slots are extension nodes (0x00 prefix)",
			indexA: 2,
			indexB: 5,
			setupBranch: func() []byte {
				items := make([][]byte, 17)
				for i := 0; i < 17; i++ {
					items[i] = []byte{}
				}
				// Extension nodes with 0x00 prefix
				path := []byte{0x00, 0x12}
				hash := make([]byte, 32)
				extNode, _ := rlp.EncodeToBytes([][]byte{path, hash})
				items[2] = extNode
				items[5] = extNode
				encoded, _ := rlp.EncodeToBytes(items)
				return encoded
			},
			expected: false, // Extension nodes, not leaf nodes
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			branchNode := tt.setupBranch()
			result, err := VerifyDirectDivergence(branchNode, tt.indexA, tt.indexB)

			if tt.shouldFail {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
				assert.Equal(t, tt.expected, result)
			}
		})
	}
}

// TestFindDivergenceNode_Integration is an integration test using real-like proof data
func TestFindDivergenceNode_Integration(t *testing.T) {
	// Use pre-computed keys where we know keyA < keyB
	// keyA has first nibble < keyB's first nibble
	keyA := common.HexToHash("0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef")
	keyB := common.HexToHash("0x5678567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef")

	// Verify keyA < keyB
	require.True(t, keyA.Big().Cmp(keyB.Big()) < 0, "keyA should be < keyB")

	// Create a proper RLP-encoded branch node (like DifferentDepths test)
	branchItems := make([][]byte, 17)
	for i := 0; i < 17; i++ {
		branchItems[i] = []byte{} // Empty slots
	}
	// Put leaf nodes in slots 1 and 5
	leafPath := []byte{0x20, 0x12}
	leafValue := []byte("val")
	leafNode, _ := rlp.EncodeToBytes([][]byte{leafPath, leafValue})
	branchItems[1] = leafNode
	branchItems[5] = leafNode
	rootNode, _ := rlp.EncodeToBytes(branchItems)

	// Create mock proofs (Root -> Leaf order)
	nodeA1 := []byte("path_to_A_intermediate")
	nodeA2 := []byte("leaf_A_parent")
	nodeB1 := []byte("path_to_B_intermediate") // Different from nodeA1
	nodeB2 := []byte("leaf_B_parent")

	proofA := [][]byte{rootNode, nodeA1, nodeA2}
	proofB := [][]byte{rootNode, nodeB1, nodeB2}

	divergenceNode, indexA, indexB, depth, err := FindDivergenceNode(keyA, keyB, proofA, proofB)

	require.NoError(t, err)
	assert.NotNil(t, divergenceNode)
	assert.Equal(t, rootNode, divergenceNode, "Divergence should be at root (common ancestor)")
	assert.Equal(t, uint64(0), depth, "Depth should be 0 (root level)")
	assert.Equal(t, uint8(1), indexA)
	assert.Equal(t, uint8(5), indexB)
	assert.Less(t, indexA, indexB, "indexA should be less than indexB")
}

// TestFindDivergenceNode_DifferentDepths tests handling of different depth proofs
func TestFindDivergenceNode_DifferentDepths(t *testing.T) {
	// Create keys
	keyA := common.HexToHash("0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef")
	keyB := common.HexToHash("0x5678567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef")

	// Create a proper RLP-encoded branch node for testing
	// Branch node is a 17-element array
	branchItems := make([][]byte, 17)
	for i := 0; i < 17; i++ {
		branchItems[i] = []byte{} // Empty slots
	}
	// Put some data in indexA (1) and indexB (5) slots
	leafPath := []byte{0x20, 0x12} // Leaf node prefix
	leafValue := []byte("val")
	leafNode, _ := rlp.EncodeToBytes([][]byte{leafPath, leafValue})
	branchItems[1] = leafNode // indexA
	branchItems[5] = leafNode // indexB

	rootNode, _ := rlp.EncodeToBytes(branchItems)

	nodeA1 := []byte("A_intermediate_1")
	nodeA2 := []byte("A_intermediate_2")
	nodeA3 := []byte("A_leaf_parent")

	nodeB1 := []byte("B_intermediate")

	// ProofA has depth 4, ProofB has depth 2
	proofA := [][]byte{rootNode, nodeA1, nodeA2, nodeA3}
	proofB := [][]byte{rootNode, nodeB1}

	divergenceNode, indexA, indexB, depth, err := FindDivergenceNode(keyA, keyB, proofA, proofB)

	require.NoError(t, err)
	assert.NotNil(t, divergenceNode)
	assert.Equal(t, rootNode, divergenceNode)
	assert.Equal(t, uint64(0), depth)
	assert.Equal(t, uint8(1), indexA, "indexA should be 1 (first nibble of keyA)")
	assert.Equal(t, uint8(5), indexB, "indexB should be 5 (first nibble of keyB)")
	assert.Less(t, indexA, indexB)
}

// TestFindDivergenceNode_EmptyProofs tests error handling for empty proofs
func TestFindDivergenceNode_EmptyProofs(t *testing.T) {
	keyA := common.HexToHash("0x1234")
	keyB := common.HexToHash("0x5678")

	tests := []struct {
		name   string
		proofA [][]byte
		proofB [][]byte
	}{
		{
			name:   "both proofs empty",
			proofA: [][]byte{},
			proofB: [][]byte{},
		},
		{
			name:   "proofA empty",
			proofA: [][]byte{},
			proofB: [][]byte{[]byte("node")},
		},
		{
			name:   "proofB empty",
			proofA: [][]byte{[]byte("node")},
			proofB: [][]byte{},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, _, _, _, err := FindDivergenceNode(keyA, keyB, tt.proofA, tt.proofB)
			assert.Error(t, err)
			assert.Contains(t, err.Error(), "empty proofs")
		})
	}
}

// TestFindDivergenceNode_IdenticalProofs tests error for identical proofs
func TestFindDivergenceNode_IdenticalProofs(t *testing.T) {
	keyA := common.HexToHash("0x1234")
	keyB := common.HexToHash("0x5678")

	// Identical proofs
	rootNode := []byte("root")
	node1 := []byte("node1")
	proofA := [][]byte{rootNode, node1}
	proofB := [][]byte{rootNode, node1}

	_, _, _, _, err := FindDivergenceNode(keyA, keyB, proofA, proofB)

	assert.Error(t, err)
	assert.Contains(t, err.Error(), "no divergence found")
}
