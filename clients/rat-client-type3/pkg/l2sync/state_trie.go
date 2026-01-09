package l2sync

import (
	"fmt"
	"math/big"
	"sort"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/rawdb"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethdb"
	"github.com/ethereum/go-ethereum/log"
	"github.com/ethereum/go-ethereum/rlp"
	"github.com/ethereum/go-ethereum/trie"
	"github.com/ethereum/go-ethereum/triedb"
)

// StateTrieLeaf represents a leaf in the L2 state Patricia trie
type StateTrieLeaf struct {
	Key   common.Hash // keccak256(address)
	Value []byte      // RLP(account)

	// Decoded account data
	Address     common.Address // Derived from key (if tracked)
	Nonce       uint64
	Balance     *big.Int
	StorageRoot common.Hash
	CodeHash    common.Hash
}

// StateTrieIterator iterates over all leaves in state trie
type StateTrieIterator struct {
	tr       *trie.Trie
	iterator *trie.Iterator
}

// NewStateTrieIterator creates iterator for given state root
func NewStateTrieIterator(db ethdb.Database, stateRoot common.Hash) (*StateTrieIterator, error) {
	log.Info("Opening state trie", "stateRoot", stateRoot.Hex())

	// Create trie database with proper config for v1.13+
	// Use simple config - Preimages are needed for SecureTrie
	trDB := triedb.NewDatabase(db, &triedb.Config{
		Preimages: true,
	})

	// Open state trie using StateTrieID for v1.13+
	trieID := trie.StateTrieID(stateRoot)
	tr, err := trie.New(trieID, trDB)
	if err != nil {
		return nil, fmt.Errorf("failed to open state trie: %w", err)
	}

	log.Info("State trie opened successfully")

	// Create node iterator
	nodeIter, err := tr.NodeIterator(nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create node iterator: %w", err)
	}
	it := trie.NewIterator(nodeIter)

	return &StateTrieIterator{
		tr:       tr,
		iterator: it,
	}, nil
}

// Next returns next leaf
func (it *StateTrieIterator) Next() (*StateTrieLeaf, bool) {
	iterCount := 0
	for {
		iterCount++
		if !it.iterator.Next() {
			log.Info("Trie iterator exhausted", "iterations", iterCount)
			return nil, false
		}

		key := it.iterator.Key
		value := it.iterator.Value

		if iterCount <= 5 || iterCount%100 == 0 {
			log.Info("Trie iterator entry",
				"iteration", iterCount,
				"keyLen", len(key),
				"valueLen", len(value))
		}

		// Skip if no value (branch/extension nodes)
		if len(value) == 0 {
			continue
		}

		keyHash := common.BytesToHash(key)

		// Decode RLP account
		var account types.StateAccount
		if err := rlp.DecodeBytes(value, &account); err != nil {
			log.Warn("Failed to decode account", "key", keyHash.Hex(), "error", err)
			continue // Skip invalid entries
		}

		log.Info("Found account in state trie",
			"iteration", iterCount,
			"key", keyHash.Hex(),
			"balance", account.Balance.ToBig().String(),
			"nonce", account.Nonce)

		return &StateTrieLeaf{
			Key:         keyHash,
			Value:       value,
			Nonce:       account.Nonce,
			Balance:     account.Balance.ToBig(), // Convert uint256 to big.Int
			StorageRoot: account.Root,
			CodeHash:    common.BytesToHash(account.CodeHash),
		}, true
	}
}

// CollectAllLeaves collects all leaves from state trie
func CollectAllLeaves(db ethdb.Database, stateRoot common.Hash) ([]*StateTrieLeaf, error) {
	log.Info("Collecting all leaves from state trie", "stateRoot", stateRoot.Hex())

	iter, err := NewStateTrieIterator(db, stateRoot)
	if err != nil {
		return nil, err
	}

	leaves := make([]*StateTrieLeaf, 0, 10000) // Pre-allocate
	count := 0

	for {
		leaf, ok := iter.Next()
		if !ok {
			break
		}
		leaves = append(leaves, leaf)
		count++

		if count%1000 == 0 {
			log.Debug("Collecting leaves", "count", count)
		}
	}

	log.Info("Collected all leaves", "count", len(leaves))

	// Note: Leaves from trie iterator are already sorted by key
	// Patricia trie iterates in lexicographic order of keys
	return leaves, nil
}

// FindAdjacentLeavesInStateTrie finds two adjacent leaves in state trie
// where leafA.key < randomValue <= leafB.key
func FindAdjacentLeavesInStateTrie(
	db ethdb.Database,
	stateRoot common.Hash,
	randomValue *big.Int,
) (*StateTrieLeaf, *StateTrieLeaf, error) {
	log.Info("Finding adjacent leaves in state trie",
		"stateRoot", stateRoot.Hex(),
		"randomValue", randomValue.String(),
	)

	// 1. Collect all leaves
	leaves, err := CollectAllLeaves(db, stateRoot)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to collect leaves: %w", err)
	}

	if len(leaves) < 2 {
		return nil, nil, fmt.Errorf("not enough leaves in state trie: %d", len(leaves))
	}

	// 2. Convert random value to hash for comparison
	randomHash := common.BigToHash(randomValue)

	log.Info("Search parameters",
		"randomHash", randomHash.Hex(),
		"totalLeaves", len(leaves),
		"firstLeafKey", leaves[0].Key.Hex(),
		"lastLeafKey", leaves[len(leaves)-1].Key.Hex(),
	)

	// 3. Binary search for position
	// Find first index where leaves[i].Key >= randomHash
	idx := sort.Search(len(leaves), func(i int) bool {
		// Compare as big integers
		return leaves[i].Key.Big().Cmp(randomHash.Big()) >= 0
	})

	log.Debug("Binary search result", "index", idx)

	// 4. Handle edge cases
	var leafA, leafB *StateTrieLeaf

	if idx == 0 {
		// Random value is smaller than all leaves
		leafA = leaves[0]
		leafB = leaves[1]
		log.Info("Random value smaller than all leaves, using first two")
	} else if idx >= len(leaves) {
		// Random value is larger than all leaves
		leafA = leaves[len(leaves)-2]
		leafB = leaves[len(leaves)-1]
		log.Info("Random value larger than all leaves, using last two")
	} else {
		// Normal case: found position between two leaves
		leafA = leaves[idx-1] // Key < randomValue
		leafB = leaves[idx]   // Key >= randomValue
		log.Info("Found adjacent leaves")
	}

	log.Info("Adjacent leaves selected",
		"leafA.key", leafA.Key.Hex(),
		"leafA.balance", leafA.Balance,
		"leafB.key", leafB.Key.Hex(),
		"leafB.balance", leafB.Balance,
	)

	return leafA, leafB, nil
}

// GenerateStateProof generates Merkle proof for a leaf in state trie
func GenerateStateProof(
	db ethdb.Database,
	stateRoot common.Hash,
	leafKey common.Hash,
) ([][]byte, error) {
	log.Debug("Generating state proof", "stateRoot", stateRoot.Hex(), "leafKey", leafKey.Hex())

	// Open trie
	trieDB := triedb.NewDatabase(db, nil)
	tr, err := trie.NewSecure(common.Hash{}, stateRoot, common.Hash{}, trieDB)
	if err != nil {
		return nil, fmt.Errorf("failed to open trie: %w", err)
	}

	// Generate proof using memory database
	proofDB := rawdb.NewMemoryDatabase()
	if err := tr.Prove(leafKey.Bytes(), proofDB); err != nil {
		return nil, fmt.Errorf("failed to generate proof: %w", err)
	}

	// Convert to slice
	proofNodes := make([][]byte, 0)
	iter := proofDB.NewIterator(nil, nil)
	defer iter.Release()

	for iter.Next() {
		proofNodes = append(proofNodes, common.CopyBytes(iter.Value()))
	}

	log.Debug("Generated proof", "nodes", len(proofNodes))

	return proofNodes, nil
}

// VerifyStateProof verifies a Merkle proof against state root
func VerifyStateProof(
	stateRoot common.Hash,
	leafKey common.Hash,
	leafValue []byte,
	proof [][]byte,
) bool {
	// Convert proof to database
	proofDB := rawdb.NewMemoryDatabase()
	for _, node := range proof {
		// Calculate node hash
		nodeHash := crypto.Keccak256Hash(node)
		proofDB.Put(nodeHash.Bytes(), node)
	}

	// Verify proof
	value, err := trie.VerifyProof(stateRoot, leafKey.Bytes(), proofDB)
	if err != nil {
		log.Warn("Proof verification failed", "error", err)
		return false
	}

	// Compare values
	if len(value) != len(leafValue) {
		log.Warn("Proof value length mismatch", "expected", len(leafValue), "got", len(value))
		return false
	}

	for i := range value {
		if value[i] != leafValue[i] {
			log.Warn("Proof value mismatch at index", "index", i)
			return false
		}
	}

	return true
}

// EstimateStateSize estimates the number of accounts in state trie
// This is a quick estimation without full iteration
func EstimateStateSize(db ethdb.Database, stateRoot common.Hash) (int, error) {
	iter, err := NewStateTrieIterator(db, stateRoot)
	if err != nil {
		return 0, err
	}

	// Sample first 100 leaves
	count := 0
	for i := 0; i < 100; i++ {
		if _, ok := iter.Next(); !ok {
			return count, nil
		}
		count++
	}

	// If we got 100, there are likely many more
	return count, nil
}
