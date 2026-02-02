package l2sync

import (
	"fmt"
	"log"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/rlp"
)

// FindDivergenceNode finds the divergence point between two Merkle proofs
// Returns the divergence node, indexA, indexB, and depth
func FindDivergenceNode(
	leafAKey common.Hash,
	leafBKey common.Hash,
	proofA [][]byte,
	proofB [][]byte,
) (divergenceNode []byte, indexA uint8, indexB uint8, depth uint64, err error) {
	log.Printf("Finding divergence node: leafAKey=%s leafBKey=%s proofALen=%d proofBLen=%d",
		leafAKey.Hex(),
		leafBKey.Hex(),
		len(proofA),
		len(proofB),
	)

	// Proofs can have different lengths (different depth leaves in trie)
	if len(proofA) == 0 || len(proofB) == 0 {
		return nil, 0, 0, 0, fmt.Errorf("empty proofs")
	}

	// IMPORTANT: eth_getProof returns proofs in Root -> Leaf order
	// This matches Optimism MerkleTrie.verifyInclusionProof which expects top-down proofs
	// proof[0] = root (or node closest to root)
	// proof[n] = leaf parent

	// Find common ancestor by comparing from root to leaf
	var divergenceDepth uint64
	var found bool

	// Compare proofs to find where they diverge
	// We need to handle different length proofs (different depth leaves)
	minLen := len(proofA)
	if len(proofB) < minLen {
		minLen = len(proofB)
	}

	for i := 0; i < minLen; i++ {
		nodeAHash := crypto.Keccak256Hash(proofA[i])
		nodeBHash := crypto.Keccak256Hash(proofB[i])

		if nodeAHash != nodeBHash {
			// Found divergence point
			// The previous node (i-1) is the common ancestor (divergence node)
			if i == 0 {
				// They diverge at root level (shouldn't happen for same state root)
				return nil, 0, 0, 0, fmt.Errorf("proofs diverge at root")
			}

			divergenceNode = proofA[i-1] // Common ancestor
			divergenceDepth = uint64(i - 1)  // Depth from root (0-based)
			found = true

			log.Printf("Found divergence: depth=%d nodeSize=%d",
				divergenceDepth,
				len(divergenceNode),
			)
			break
		}
	}

	// If all common nodes match, divergence is at the end of shorter proof
	if !found {
		if len(proofA) != len(proofB) {
			// Proofs have different lengths but common part matches
			// Divergence is at the last common node
			divergenceDepth = uint64(minLen - 1)
			divergenceNode = proofA[divergenceDepth]
			found = true

			log.Printf("Found divergence at depth boundary: depth=%d proofALen=%d proofBLen=%d",
				divergenceDepth,
				len(proofA),
				len(proofB),
			)
		} else {
			return nil, 0, 0, 0, fmt.Errorf("no divergence found (proofs are identical)")
		}
	}

	if !found {
		return nil, 0, 0, 0, fmt.Errorf("no divergence found (proofs are identical)")
	}

	// Extract indices from the divergence node
	// The divergence node is a branch node with 17 children
	// We need to find which child index corresponds to leafA and leafB

	indexA, indexB, err = FindChildIndices(divergenceNode, leafAKey, leafBKey, divergenceDepth)
	if err != nil {
		return nil, 0, 0, 0, fmt.Errorf("failed to find child indices: %w", err)
	}

	// Verify this is a direct divergence node (best practice)
	// indexA and indexB slots should contain leaf nodes, not sub-branches
	// This prevents the need for boundary proofs
	isDirectDivergence, err := VerifyDirectDivergence(divergenceNode, indexA, indexB)
	if err != nil {
		log.Printf("Warning: failed to verify direct divergence: %v", err)
		// Continue anyway - Solidity verification will catch issues
	} else if !isDirectDivergence {
		log.Printf("Warning: divergence node is not direct (indexA or indexB contains sub-branch)")
		log.Printf("This is still valid but may require additional boundary proofs in stricter implementations")
		// Continue anyway - current Solidity implementation accepts this
	} else {
		log.Printf("Verified: divergence node is direct (both slots contain leaf nodes)")
	}

	// Pre-validate gap between indexA and indexB (early error detection)
	// This catches errors before submitting to on-chain verification, saving gas
	if indexB-indexA > 1 {
		gapValid, err := VerifyGapBetweenIndices(divergenceNode, indexA, indexB)
		if err != nil {
			return nil, 0, 0, 0, fmt.Errorf("failed to verify gap between indices: %w", err)
		}
		if !gapValid {
			return nil, 0, 0, 0, fmt.Errorf("gap validation failed: slots between indexA=%d and indexB=%d are not empty", indexA, indexB)
		}
		log.Printf("Verified: gap between indexA and indexB is empty (all slots are 0x80)")
	}

	log.Printf("Divergence node found: depth=%d indexA=%d indexB=%d directDivergence=%v",
		divergenceDepth,
		indexA,
		indexB,
		isDirectDivergence,
	)

	return divergenceNode, indexA, indexB, divergenceDepth, nil
}

// FindChildIndices finds which child indices in a branch node correspond to two keys
// Based on the nibble at the given depth
func FindChildIndices(
	branchNode []byte,
	keyA common.Hash,
	keyB common.Hash,
	depth uint64,
) (indexA uint8, indexB uint8, err error) {
	// In Patricia trie, each level of depth corresponds to one nibble (4 bits)
	// Key is 32 bytes = 256 bits = 64 nibbles

	// Calculate nibble index in the key
	// depth 0 = first nibble, depth 1 = second nibble, etc.

	if depth >= 64 {
		return 0, 0, fmt.Errorf("depth exceeds key length: %d", depth)
	}

	// Get the nibble at this depth
	indexA = getNibbleAt(keyA[:], depth)
	indexB = getNibbleAt(keyB[:], depth)

	// Verify indexA < indexB
	if indexA >= indexB {
		return 0, 0, fmt.Errorf("indexA must be < indexB: indexA=%d, indexB=%d", indexA, indexB)
	}

	log.Printf("Child indices: depth=%d indexA=%d indexB=%d",
		depth,
		indexA,
		indexB,
	)

	return indexA, indexB, nil
}

// getNibbleAt extracts the nibble (4 bits) at a given depth from a byte array
// depth 0 = first nibble (high bits of byte 0)
// depth 1 = second nibble (low bits of byte 0)
// depth 2 = third nibble (high bits of byte 1)
// etc.
func getNibbleAt(key []byte, depth uint64) uint8 {
	byteIndex := depth / 2
	isHighNibble := depth%2 == 0

	if byteIndex >= uint64(len(key)) {
		return 0
	}

	b := key[byteIndex]

	if isHighNibble {
		// High nibble (bits 4-7)
		return b >> 4
	} else {
		// Low nibble (bits 0-3)
		return b & 0x0F
	}
}

// VerifyDirectDivergence checks if the divergence node is a "direct divergence"
// meaning indexA and indexB slots contain leaf nodes (not sub-branches)
// This is best practice to avoid needing boundary proofs
func VerifyDirectDivergence(branchNode []byte, indexA, indexB uint8) (bool, error) {
	// RLP decode the branch node
	// Branch node is a 17-element list [child0, ..., child15, value]

	var items [][]byte
	err := rlp.DecodeBytes(branchNode, &items)
	if err != nil {
		return false, fmt.Errorf("failed to RLP decode branch node: %w", err)
	}

	// Branch node must have exactly 17 elements
	if len(items) != 17 {
		return false, fmt.Errorf("invalid branch node: expected 17 items, got %d", len(items))
	}

	// Check if indexA and indexB slots contain leaf nodes
	// Leaf nodes in Patricia trie are 2-element lists: [compact_encoded_path, value]
	// The compact encoding prefix indicates node type:
	// - 0x00, 0x01: Extension node (even/odd length)
	// - 0x20, 0x30: Leaf node (even/odd length)
	// - 32-byte hash: Reference to another node (sub-branch)

	slotAIsLeaf, err := isLeafNode(items[indexA])
	if err != nil {
		log.Printf("Warning: failed to check indexA slot: %v", err)
		return false, err
	}

	slotBIsLeaf, err := isLeafNode(items[indexB])
	if err != nil {
		log.Printf("Warning: failed to check indexB slot: %v", err)
		return false, err
	}

	isDirect := slotAIsLeaf && slotBIsLeaf

	if isDirect {
		log.Printf("Direct divergence verified: both slots contain leaf nodes")
	} else {
		log.Printf("Not direct divergence: slotA=%v, slotB=%v", slotAIsLeaf, slotBIsLeaf)
	}

	return isDirect, nil
}

// VerifyGapBetweenIndices verifies that all slots between indexA and indexB are empty
// This is a pre-validation step to catch errors before on-chain submission
//
// Note: In Ethereum Patricia Trie, empty slots are encoded as 0x80 in RLP.
// After rlp.DecodeBytes, this becomes a zero-length byte array ([]byte{}), not 0x80.
func VerifyGapBetweenIndices(branchNode []byte, indexA, indexB uint8) (bool, error) {
	// RLP decode the branch node
	// Branch node is a 17-element list [child0, ..., child15, value]
	var items [][]byte
	err := rlp.DecodeBytes(branchNode, &items)
	if err != nil {
		return false, fmt.Errorf("failed to RLP decode branch node: %w", err)
	}

	// Branch node must have exactly 17 elements
	if len(items) != 17 {
		return false, fmt.Errorf("invalid branch node: expected 17 items, got %d", len(items))
	}

	// Check all slots between indexA and indexB (exclusive)
	// Empty slots in raw RLP: 0x80
	// Empty slots after RLP decode: []byte{} (zero-length array)
	for i := indexA + 1; i < indexB; i++ {
		slot := items[i]

		// After RLP decoding, empty slot becomes zero-length byte array
		if len(slot) != 0 {
			log.Printf("Gap validation failed: slot %d is not empty (length=%d, data=%x)",
				i, len(slot), slot)
			return false, nil
		}
	}

	return true, nil
}

// isLeafNode checks if an RLP-encoded node is a leaf node
func isLeafNode(nodeData []byte) (bool, error) {
	if len(nodeData) == 0 {
		// Empty slot (0x80) - not a leaf
		return false, nil
	}

	if len(nodeData) == 32 {
		// 32-byte hash reference to another node (sub-branch)
		return false, nil
	}

	// Try to decode as a 2-element list [path, value]
	var items [][]byte
	err := rlp.DecodeBytes(nodeData, &items)
	if err != nil {
		// Not a list - might be inline data, treat as leaf
		return true, nil
	}

	if len(items) != 2 {
		// Not 2-element list - not a leaf or extension
		return false, nil
	}

	// Check the compact encoding prefix
	// Patricia trie compact encoding:
	// - First nibble: 0x0/0x1 = extension, 0x2/0x3 = leaf
	if len(items[0]) == 0 {
		return false, nil
	}

	firstNibble := items[0][0] >> 4 // High 4 bits

	// 0x2 or 0x3 = leaf node
	return firstNibble == 2 || firstNibble == 3, nil
}
