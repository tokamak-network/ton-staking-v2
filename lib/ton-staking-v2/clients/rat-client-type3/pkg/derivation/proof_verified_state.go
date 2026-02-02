package derivation

import (
	"bytes"
	"context"
	"encoding/hex"
	"fmt"
	"math/big"
	"strings"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/state"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/ethereum/go-ethereum/rlp"
	"github.com/ethereum/go-ethereum/trie"
)

// ProofVerifiedStateDB is a StateDB that verifies all data with Merkle proofs
// This allows trustless execution using L2 RPC data without trusting the L2 node
//
// How it works:
// 1. Start with finalized state root from L1 (trustless)
// 2. On each state access (account/storage):
//    a. Fetch data + Merkle proof from L2 RPC via eth_getProof
//    b. Verify proof against the state root
//    c. If valid → cache and use data (trustless!)
//    d. If invalid → reject (L2 RPC lied!)
//
// L2 RPC CANNOT provide invalid data because it cannot forge Merkle proofs!
type ProofVerifiedStateDB struct {
	l2Client  *ethclient.Client
	stateRoot common.Hash

	// Cache of verified accounts and storage
	accountCache  map[common.Address]*AccountData
	storageCache  map[common.Address]map[common.Hash]common.Hash

	// Underlying state DB for execution
	stateDB *state.StateDB
}

// AccountData represents verified account data
type AccountData struct {
	Nonce       uint64
	Balance     *big.Int
	StorageHash common.Hash
	CodeHash    common.Hash
	Code        []byte
	Verified    bool // Has this been verified with proof?
}

// NewProofVerifiedStateDB creates a new proof-verified state DB
func NewProofVerifiedStateDB(
	ctx context.Context,
	l2Client *ethclient.Client,
	stateRoot common.Hash,
) (*ProofVerifiedStateDB, error) {
	// TODO: Create actual state.StateDB with custom backend
	// For now, return the structure

	return &ProofVerifiedStateDB{
		l2Client:     l2Client,
		stateRoot:    stateRoot,
		accountCache: make(map[common.Address]*AccountData),
		storageCache: make(map[common.Address]map[common.Hash]common.Hash),
	}, nil
}

// GetAccount gets account data with proof verification
func (s *ProofVerifiedStateDB) GetAccount(
	ctx context.Context,
	address common.Address,
) (*AccountData, error) {
	// Check cache first
	if cached, ok := s.accountCache[address]; ok && cached.Verified {
		return cached, nil
	}

	// Fetch account proof from L2 RPC
	accountProof, err := s.getAccountProof(ctx, address)
	if err != nil {
		return nil, fmt.Errorf("failed to get account proof: %w", err)
	}

	// Verify proof against state root
	if err := s.verifyAccountProof(address, accountProof); err != nil {
		return nil, fmt.Errorf("account proof verification failed (L2 RPC lied!): %w", err)
	}

	// Proof is valid! Cache the verified data
	accountData := &AccountData{
		Nonce:       accountProof.Nonce,
		Balance:     accountProof.Balance,
		StorageHash: accountProof.StorageHash,
		CodeHash:    accountProof.CodeHash,
		Verified:    true,
	}

	// Fetch code if needed and VERIFY it!
	if accountProof.CodeHash != (common.Hash{}) && accountProof.CodeHash != emptyCodeHash {
		// Get code from L2 RPC
		code, err := s.l2Client.CodeAt(ctx, address, nil)
		if err != nil {
			return nil, fmt.Errorf("failed to get code: %w", err)
		}

		// CRITICAL: Verify code hash!
		// L2 RPC could lie about the code, but it cannot forge the hash
		computedCodeHash := crypto.Keccak256Hash(code)
		if computedCodeHash != accountProof.CodeHash {
			return nil, fmt.Errorf(
				"code hash mismatch (L2 RPC lied about code!): computed=%s, claimed=%s",
				computedCodeHash.Hex(),
				accountProof.CodeHash.Hex(),
			)
		}

		// Code is verified! Safe to use
		accountData.Code = code
	}

	s.accountCache[address] = accountData
	return accountData, nil
}

// GetStorage gets storage value with proof verification
func (s *ProofVerifiedStateDB) GetStorage(
	ctx context.Context,
	address common.Address,
	key common.Hash,
) (common.Hash, error) {
	// Check cache
	if addrCache, ok := s.storageCache[address]; ok {
		if value, ok := addrCache[key]; ok {
			return value, nil
		}
	}

	// Fetch storage proof from L2 RPC
	storageProof, err := s.getStorageProof(ctx, address, key)
	if err != nil {
		return common.Hash{}, fmt.Errorf("failed to get storage proof: %w", err)
	}

	// Verify proof against account's storage root
	accountData, err := s.GetAccount(ctx, address)
	if err != nil {
		return common.Hash{}, fmt.Errorf("failed to get account: %w", err)
	}

	if err := s.verifyStorageProof(accountData.StorageHash, key, storageProof); err != nil {
		return common.Hash{}, fmt.Errorf("storage proof verification failed (L2 RPC lied!): %w", err)
	}

	// Proof is valid! Cache the verified value
	value := storageProof.Value
	if s.storageCache[address] == nil {
		s.storageCache[address] = make(map[common.Hash]common.Hash)
	}
	s.storageCache[address][key] = value

	return value, nil
}

// AccountProof represents eth_getProof result for account
type AccountProof struct {
	Address      common.Address
	Balance      *big.Int
	CodeHash     common.Hash
	Nonce        uint64
	StorageHash  common.Hash
	AccountProof []string // Merkle proof nodes (hex-encoded)
}

// getAccountProof calls eth_getProof to get account proof
func (s *ProofVerifiedStateDB) getAccountProof(
	ctx context.Context,
	address common.Address,
) (*AccountProof, error) {
	// Call eth_getProof RPC
	type Result struct {
		Address      common.Address `json:"address"`
		Balance      *big.Int       `json:"balance"`
		CodeHash     common.Hash    `json:"codeHash"`
		Nonce        uint64         `json:"nonce"`
		StorageHash  common.Hash    `json:"storageHash"`
		AccountProof []string       `json:"accountProof"`
	}

	var result Result
	err := s.l2Client.Client().CallContext(
		ctx,
		&result,
		"eth_getProof",
		address,
		[]string{}, // No storage keys for account proof
		fmt.Sprintf("0x%x", s.stateRoot),
	)
	if err != nil {
		return nil, fmt.Errorf("eth_getProof call failed: %w", err)
	}

	return &AccountProof{
		Address:      result.Address,
		Balance:      result.Balance,
		CodeHash:     result.CodeHash,
		Nonce:        result.Nonce,
		StorageHash:  result.StorageHash,
		AccountProof: result.AccountProof,
	}, nil
}

// StorageProof represents eth_getProof result for storage
type StorageProof struct {
	Key   common.Hash
	Value common.Hash
	Proof []string // Merkle proof nodes
}

// getStorageProof calls eth_getProof to get storage proof
func (s *ProofVerifiedStateDB) getStorageProof(
	ctx context.Context,
	address common.Address,
	key common.Hash,
) (*StorageProof, error) {
	// Call eth_getProof with storage key
	type Result struct {
		StorageProof []struct {
			Key   string   `json:"key"`
			Value *big.Int `json:"value"`
			Proof []string `json:"proof"`
		} `json:"storageProof"`
	}

	var result Result
	err := s.l2Client.Client().CallContext(
		ctx,
		&result,
		"eth_getProof",
		address,
		[]string{key.Hex()},
		fmt.Sprintf("0x%x", s.stateRoot),
	)
	if err != nil {
		return nil, fmt.Errorf("eth_getProof call failed: %w", err)
	}

	if len(result.StorageProof) == 0 {
		return nil, fmt.Errorf("no storage proof returned")
	}

	proof := result.StorageProof[0]
	value := common.BigToHash(proof.Value)

	return &StorageProof{
		Key:   key,
		Value: value,
		Proof: proof.Proof,
	}, nil
}

// verifyAccountProof verifies account Merkle proof against state root
func (s *ProofVerifiedStateDB) verifyAccountProof(
	address common.Address,
	proof *AccountProof,
) error {
	// Step 1: Convert proof nodes from hex strings to bytes
	proofDB, err := convertProofToNodeSet(proof.AccountProof)
	if err != nil {
		return fmt.Errorf("failed to convert account proof: %w", err)
	}

	// Step 2: Compute account key (Patricia Merkle Trie uses keccak256(address) as key)
	accountKey := crypto.Keccak256(address.Bytes())

	// Step 3: Encode account data as RLP
	// Account structure in Ethereum: [nonce, balance, storageRoot, codeHash]
	accountData := []interface{}{
		proof.Nonce,
		proof.Balance,
		proof.StorageHash,
		proof.CodeHash,
	}

	expectedValue, err := rlp.EncodeToBytes(accountData)
	if err != nil {
		return fmt.Errorf("failed to RLP encode account data: %w", err)
	}

	// Step 4: Verify Merkle proof using trie.VerifyProof
	// This cryptographically proves that the account exists in the state trie
	value, err := trie.VerifyProof(s.stateRoot, accountKey, proofDB)
	if err != nil {
		return fmt.Errorf("Merkle proof verification failed: %w", err)
	}

	// Step 5: Verify the returned value matches expected account data
	if value == nil {
		// Account doesn't exist in the state trie
		// Check if this is an empty account (zero nonce, zero balance, empty storage, empty code)
		if proof.Nonce != 0 || proof.Balance.Sign() != 0 ||
			proof.StorageHash != emptyStorageHash || proof.CodeHash != emptyCodeHash {
			return fmt.Errorf("account proof claims non-empty account but trie proof shows no account")
		}
		return nil // Empty account is valid
	}

	// Step 6: Compare the retrieved value with expected value
	if !bytes.Equal(value, expectedValue) {
		return fmt.Errorf(
			"account data mismatch: proof value doesn't match RLP-encoded account data (L2 RPC provided invalid proof!)",
		)
	}

	return nil
}

// verifyStorageProof verifies storage Merkle proof against storage root
func (s *ProofVerifiedStateDB) verifyStorageProof(
	storageRoot common.Hash,
	key common.Hash,
	proof *StorageProof,
) error {
	// Step 1: Convert proof nodes from hex strings to bytes
	proofDB, err := convertProofToNodeSet(proof.Proof)
	if err != nil {
		return fmt.Errorf("failed to convert storage proof: %w", err)
	}

	// Step 2: Compute storage key (Patricia Merkle Trie uses keccak256(key) as key)
	storageKey := crypto.Keccak256(key.Bytes())

	// Step 3: Encode storage value as RLP
	// Storage values are RLP-encoded
	expectedValue, err := rlp.EncodeToBytes(proof.Value.Bytes())
	if err != nil {
		return fmt.Errorf("failed to RLP encode storage value: %w", err)
	}

	// Step 4: Verify Merkle proof using trie.VerifyProof
	// This cryptographically proves that the storage value exists in the storage trie
	value, err := trie.VerifyProof(storageRoot, storageKey, proofDB)
	if err != nil {
		return fmt.Errorf("storage Merkle proof verification failed: %w", err)
	}

	// Step 5: Handle zero storage values (not present in trie)
	if value == nil {
		// Storage slot doesn't exist in the trie
		// This is valid only if the claimed value is zero
		if proof.Value != (common.Hash{}) {
			return fmt.Errorf("storage proof claims non-zero value but trie proof shows no storage slot")
		}
		return nil // Zero value is valid
	}

	// Step 6: Compare the retrieved value with expected value
	if !bytes.Equal(value, expectedValue) {
		return fmt.Errorf(
			"storage value mismatch: proof value doesn't match RLP-encoded storage value (L2 RPC provided invalid proof!)",
		)
	}

	return nil
}

var (
	// emptyCodeHash is keccak256("") - the hash of empty code
	emptyCodeHash = common.HexToHash("0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470")

	// emptyStorageHash is the hash of empty storage trie
	emptyStorageHash = common.HexToHash("0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421")
)

// proofDB is a simple in-memory key-value store for Merkle proof nodes
// It implements the ethdb.KeyValueReader interface required by trie.VerifyProof
type proofDB struct {
	nodes map[string][]byte
}

func newProofDB() *proofDB {
	return &proofDB{
		nodes: make(map[string][]byte),
	}
}

// Has returns true if the key exists in the database
func (db *proofDB) Has(key []byte) (bool, error) {
	_, ok := db.nodes[string(key)]
	return ok, nil
}

// Get retrieves the value for the given key
func (db *proofDB) Get(key []byte) ([]byte, error) {
	value, ok := db.nodes[string(key)]
	if !ok {
		return nil, fmt.Errorf("key not found")
	}
	return value, nil
}

// Put stores a key-value pair in the database
func (db *proofDB) Put(key, value []byte) error {
	db.nodes[string(key)] = value
	return nil
}

// convertProofToNodeSet converts hex-encoded proof nodes to proofDB
// eth_getProof returns proof as array of hex-encoded RLP nodes
func convertProofToNodeSet(proofHex []string) (*proofDB, error) {
	db := newProofDB()

	for i, hexNode := range proofHex {
		// Remove "0x" prefix if present
		hexNode = strings.TrimPrefix(hexNode, "0x")

		// Decode hex to bytes
		nodeBytes, err := hex.DecodeString(hexNode)
		if err != nil {
			return nil, fmt.Errorf("failed to decode proof node %d: %w", i, err)
		}

		// Compute node hash (key in proof DB)
		nodeHash := crypto.Keccak256(nodeBytes)

		// Add to proof DB
		if err := db.Put(nodeHash, nodeBytes); err != nil {
			return nil, fmt.Errorf("failed to store proof node %d: %w", i, err)
		}
	}

	return db, nil
}

// AsStateDB returns the underlying state.StateDB
// TODO: Implement custom state.Database that uses proof verification
func (s *ProofVerifiedStateDB) AsStateDB() (*state.StateDB, error) {
	return nil, fmt.Errorf("state.StateDB integration not yet implemented")
}
