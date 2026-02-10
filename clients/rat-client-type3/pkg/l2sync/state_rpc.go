package l2sync

import (
	"context"
	"encoding/json"
	"fmt"
	"math/big"
	"sort"
	"strings"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/common/hexutil"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"log"
	"github.com/ethereum/go-ethereum/rlp"
	"github.com/ethereum/go-ethereum/rpc"
	"github.com/holiman/uint256"
)

// AccountRangeResult represents the result from debug_accountRange
type AccountRangeResult struct {
	Root     string                  `json:"root"` // hex string without 0x prefix
	Accounts map[string]*AccountInfo `json:"accounts"`
	Next     string                  `json:"next"` // next start key for pagination
}

// GetRootHash returns the root as common.Hash
func (r *AccountRangeResult) GetRootHash() common.Hash {
	// Add 0x prefix if missing
	rootHex := r.Root
	if !strings.HasPrefix(rootHex, "0x") {
		rootHex = "0x" + rootHex
	}
	return common.HexToHash(rootHex)
}

// AccountInfo represents account information from debug_accountRange
// Note: debug_accountRange returns hex strings without 0x prefix
type AccountInfo struct {
	Balance  string `json:"balance"`  // hex string without 0x prefix
	Nonce    uint64 `json:"nonce"`
	Root     string `json:"root"`     // hex string without 0x prefix
	CodeHash string `json:"codeHash"` // hex string without 0x prefix
	Address  string `json:"address"`  // hex string WITH 0x prefix
	Key      string `json:"key"`      // hex string without 0x prefix
}

// GetBalance returns balance as *big.Int
func (a *AccountInfo) GetBalance() *big.Int {
	balance := new(big.Int)
	// Try with 0x prefix first
	if strings.HasPrefix(a.Balance, "0x") {
		balance.SetString(a.Balance[2:], 16)
	} else {
		balance.SetString(a.Balance, 16)
	}
	return balance
}

// GetRoot returns root as common.Hash
func (a *AccountInfo) GetRoot() common.Hash {
	rootHex := a.Root
	if !strings.HasPrefix(rootHex, "0x") {
		rootHex = "0x" + rootHex
	}
	return common.HexToHash(rootHex)
}

// GetCodeHash returns codeHash as common.Hash
func (a *AccountInfo) GetCodeHash() common.Hash {
	codeHashHex := a.CodeHash
	if !strings.HasPrefix(codeHashHex, "0x") {
		codeHashHex = "0x" + codeHashHex
	}
	return common.HexToHash(codeHashHex)
}

// GetAddress returns address as common.Address
func (a *AccountInfo) GetAddress() common.Address {
	return common.HexToAddress(a.Address)
}

// GetKey returns key as common.Hash
func (a *AccountInfo) GetKey() common.Hash {
	keyHex := a.Key
	if !strings.HasPrefix(keyHex, "0x") {
		keyHex = "0x" + keyHex
	}
	return common.HexToHash(keyHex)
}

// SortedAccount is used for sorting accounts by key
type SortedAccount struct {
	Address common.Address
	Key     common.Hash
	Info    *AccountInfo
}

// zeroHashHex is the zero hash used to detect end of pagination
const zeroHashHex = "0x0000000000000000000000000000000000000000000000000000000000000000"

// GetAccountRangeViaRPC fetches all accounts using debug_accountRange RPC with pagination
func GetAccountRangeViaRPC(ctx context.Context, rpcClient *rpc.Client, blockNumber string) (*AccountRangeResult, error) {
	log.Printf("Fetching account range via RPC: block=%s", blockNumber)

	allAccounts := make(map[string]*AccountInfo)
	var rootHash string
	startKey := zeroHashHex // Start from beginning
	page := 0

	for {
		page++
		var result AccountRangeResult
		err := rpcClient.CallContext(ctx, &result, "debug_accountRange",
			blockNumber, // block number or "latest"
			startKey,    // start address hash
			1000,        // maxResults per page
			false,       // excludeCode
			false,       // excludeStorage
			false,       // incompletes
		)
		if err != nil {
			return nil, fmt.Errorf("failed to call debug_accountRange (page %d): %w", page, err)
		}

		if rootHash == "" {
			rootHash = result.Root
		}

		for k, v := range result.Accounts {
			allAccounts[k] = v
		}

		log.Printf("Fetched account range page %d: pageCount=%d, totalCount=%d, next=%s",
			page, len(result.Accounts), len(allAccounts), result.Next)

		// Check if there are more accounts to fetch
		if result.Next == "" || result.Next == zeroHashHex || len(result.Accounts) == 0 {
			break
		}

		startKey = result.Next
	}

	combined := &AccountRangeResult{
		Root:     rootHash,
		Accounts: allAccounts,
	}

	log.Printf("Fetched all accounts via RPC: totalCount=%d, pages=%d, root=%s",
		len(combined.Accounts), page,
		combined.GetRootHash().Hex())

	return combined, nil
}

// FindAdjacentLeavesViaRPC finds two adjacent leaves using RPC
func FindAdjacentLeavesViaRPC(
	ctx context.Context,
	rpcClient *rpc.Client,
	randomValue *big.Int,
	blockNumber uint64,
) (*AdjacentLeaves, error) {
	log.Printf("Finding adjacent leaves via RPC: randomValue=%s, blockNumber=%d",
		randomValue.String(),
		blockNumber)

	// Convert block number to hex
	blockHex := fmt.Sprintf("0x%x", blockNumber)

	// 1. Get all accounts via debug_accountRange
	result, err := GetAccountRangeViaRPC(ctx, rpcClient, blockHex)
	if err != nil {
		return nil, err
	}

	if len(result.Accounts) < 2 {
		return nil, fmt.Errorf("not enough accounts: %d", len(result.Accounts))
	}

	// 2. Convert to sorted slice
	sorted := make([]SortedAccount, 0, len(result.Accounts))
	for _, info := range result.Accounts {
		sorted = append(sorted, SortedAccount{
			Address: info.GetAddress(),
			Key:     info.GetKey(),
			Info:    info,
		})
	}

	// 2.5. Add precompile accounts (0x01-0x09) which exist in state trie
	// but are not returned by debug_accountRange
	for i := 1; i <= 9; i++ {
		addr := common.BytesToAddress([]byte{byte(i)})
		key := crypto.Keccak256Hash(addr.Bytes())

		// Check if already in the list
		alreadyExists := false
		for _, s := range sorted {
			if s.Address == addr {
				alreadyExists = true
				break
			}
		}
		if alreadyExists {
			continue
		}

		proofResult, err := GetProofViaRPC(ctx, rpcClient, addr, blockHex)
		if err != nil {
			continue
		}

		balance := proofResult.Balance.ToInt()
		if balance.Sign() > 0 || uint64(proofResult.Nonce) > 0 {
			sorted = append(sorted, SortedAccount{
				Address: addr,
				Key:     key,
				Info: &AccountInfo{
					Balance: fmt.Sprintf("%x", balance),
					Nonce:   uint64(proofResult.Nonce),
					Root:    proofResult.StorageHash.Hex()[2:],
					CodeHash: proofResult.CodeHash.Hex()[2:],
					Address: addr.Hex(),
					Key:     key.Hex()[2:],
				},
			})
			log.Printf("Added precompile account: addr=%s, key=%s, balance=%s",
				addr.Hex(), key.Hex(), balance.String())
		}
	}

	// 3. Sort by key (address hash)
	sort.Slice(sorted, func(i, j int) bool {
		return sorted[i].Key.Big().Cmp(sorted[j].Key.Big()) < 0
	})

	log.Printf("Sorted accounts by key: count=%d, firstKey=%s, lastKey=%s",
		len(sorted),
		sorted[0].Key.Hex(),
		sorted[len(sorted)-1].Key.Hex())

	// 4. Binary search for position
	randomHash := common.BigToHash(randomValue)
	idx := sort.Search(len(sorted), func(i int) bool {
		return sorted[i].Key.Big().Cmp(randomHash.Big()) >= 0
	})

	log.Printf("Binary search result: index=%d", idx)

	// 5. Select adjacent leaves
	var accountA, accountB SortedAccount

	if idx == 0 {
		// Random value smaller than all leaves
		accountA = sorted[0]
		accountB = sorted[1]
		log.Printf("Random value smaller than all leaves, using first two")
	} else if idx >= len(sorted) {
		// Random value larger than all leaves
		accountA = sorted[len(sorted)-2]
		accountB = sorted[len(sorted)-1]
		log.Printf("Random value larger than all leaves, using last two")
	} else {
		// Normal case
		accountA = sorted[idx-1]
		accountB = sorted[idx]
		log.Printf("Found adjacent leaves in middle")
	}

	log.Printf("Selected adjacent accounts: accountA=%s, keyA=%s, balanceA=%s, accountB=%s, keyB=%s, balanceB=%s",
		accountA.Address.Hex(),
		accountA.Key.Hex(),
		accountA.Info.GetBalance().String(),
		accountB.Address.Hex(),
		accountB.Key.Hex(),
		accountB.Info.GetBalance().String())

	// 6. Get proofs via eth_getProof
	// IMPORTANT: Use the account state from eth_getProof, not from debug_accountRange
	// The proof contains the actual account state at the specified block
	proofResultA, err := GetProofViaRPC(ctx, rpcClient, accountA.Address, blockHex)
	if err != nil {
		return nil, fmt.Errorf("failed to get proof for accountA: %w", err)
	}

	proofResultB, err := GetProofViaRPC(ctx, rpcClient, accountB.Address, blockHex)
	if err != nil {
		return nil, fmt.Errorf("failed to get proof for accountB: %w", err)
	}

	// 7. Convert proof to [][]byte
	proofABytes, err := proofResultA.GetProofBytes()
	if err != nil {
		return nil, fmt.Errorf("failed to decode proofA: %w", err)
	}

	proofBBytes, err := proofResultB.GetProofBytes()
	if err != nil {
		return nil, fmt.Errorf("failed to decode proofB: %w", err)
	}

	// 8. Create state trie leaves using account state from eth_getProof
	// RLP-encode account for leafA (using eth_getProof result)
	balanceA, _ := uint256.FromBig(proofResultA.Balance.ToInt())
	accountAData := &types.StateAccount{
		Nonce:    uint64(proofResultA.Nonce),
		Balance:  balanceA,
		Root:     proofResultA.StorageHash,
		CodeHash: proofResultA.CodeHash.Bytes(),
	}
	valueA, err := rlp.EncodeToBytes(accountAData)
	if err != nil {
		return nil, fmt.Errorf("failed to encode accountA: %w", err)
	}

	log.Printf("Account A from eth_getProof: address=%s, nonce=%d, balance=%s, storageHash=%s, codeHash=%s",
		accountA.Address.Hex(),
		proofResultA.Nonce,
		proofResultA.Balance.ToInt().String(),
		proofResultA.StorageHash.Hex(),
		proofResultA.CodeHash.Hex())

	leafA := &StateTrieLeaf{
		Key:         accountA.Key,
		Value:       valueA,
		Address:     accountA.Address,
		Nonce:       uint64(proofResultA.Nonce),
		Balance:     proofResultA.Balance.ToInt(),
		StorageRoot: proofResultA.StorageHash,
		CodeHash:    proofResultA.CodeHash,
	}

	// RLP-encode account for leafB (using eth_getProof result)
	balanceB, _ := uint256.FromBig(proofResultB.Balance.ToInt())
	accountBData := &types.StateAccount{
		Nonce:    uint64(proofResultB.Nonce),
		Balance:  balanceB,
		Root:     proofResultB.StorageHash,
		CodeHash: proofResultB.CodeHash.Bytes(),
	}
	valueB, err := rlp.EncodeToBytes(accountBData)
	if err != nil {
		return nil, fmt.Errorf("failed to encode accountB: %w", err)
	}

	log.Printf("Account B from eth_getProof: address=%s, nonce=%d, balance=%s, storageHash=%s, codeHash=%s",
		accountB.Address.Hex(),
		proofResultB.Nonce,
		proofResultB.Balance.ToInt().String(),
		proofResultB.StorageHash.Hex(),
		proofResultB.CodeHash.Hex())

	leafB := &StateTrieLeaf{
		Key:         accountB.Key,
		Value:       valueB,
		Address:     accountB.Address,
		Nonce:       uint64(proofResultB.Nonce),
		Balance:     proofResultB.Balance.ToInt(),
		StorageRoot: proofResultB.StorageHash,
		CodeHash:    proofResultB.CodeHash,
	}

	// 9. Create AdjacentLeaves
	leaves := &AdjacentLeaves{
		LeafA:       leafA,
		LeafB:       leafB,
		ProofA:      proofABytes,
		ProofB:      proofBBytes,
		StateRoot:   result.GetRootHash(),
		BlockNumber: blockNumber,
	}

	log.Printf("Successfully created adjacent leaves via RPC: proofANodes=%d, proofBNodes=%d",
		len(proofABytes),
		len(proofBBytes))

	return leaves, nil
}

// ProofResult represents the result from eth_getProof
type ProofResult struct {
	Address      common.Address  `json:"address"`
	AccountProof []string        `json:"accountProof"`
	Balance      *hexutil.Big    `json:"balance"`
	CodeHash     common.Hash     `json:"codeHash"`
	Nonce        hexutil.Uint64  `json:"nonce"`
	StorageHash  common.Hash     `json:"storageHash"`
	StorageProof []StorageProof  `json:"storageProof"`
}

// StorageProof represents a storage proof
type StorageProof struct {
	Key   string   `json:"key"`
	Value *hexutil.Big `json:"value"`
	Proof []string `json:"proof"`
}

// GetProofViaRPC gets Merkle proof for an account via eth_getProof
// Returns the full ProofResult which includes both proof and account state
func GetProofViaRPC(ctx context.Context, rpcClient *rpc.Client, address common.Address, blockNumber string) (*ProofResult, error) {
	log.Printf("Getting proof via RPC: address=%s, block=%s", address.Hex(), blockNumber)

	var result ProofResult
	err := rpcClient.CallContext(ctx, &result, "eth_getProof",
		address,
		[]string{}, // empty storage keys
		blockNumber,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to call eth_getProof: %w", err)
	}

	log.Printf("Got proof via RPC: nodes=%d, nonce=%d, balance=%s",
		len(result.AccountProof),
		result.Nonce,
		result.Balance.ToInt().String())

	return &result, nil
}

// GetProofBytes converts ProofResult.AccountProof to [][]byte
func (pr *ProofResult) GetProofBytes() ([][]byte, error) {
	proof := make([][]byte, len(pr.AccountProof))
	for i, hexProof := range pr.AccountProof {
		proofBytes, err := hexutil.Decode(hexProof)
		if err != nil {
			return nil, fmt.Errorf("failed to decode proof node %d: %w", i, err)
		}
		proof[i] = proofBytes
	}
	return proof, nil
}

// GetStateRootViaRPC gets the state root for a block
func GetStateRootViaRPC(ctx context.Context, rpcClient *rpc.Client, blockNumber uint64) (common.Hash, error) {
	blockHex := fmt.Sprintf("0x%x", blockNumber)

	var result map[string]interface{}
	err := rpcClient.CallContext(ctx, &result, "eth_getBlockByNumber", blockHex, false)
	if err != nil {
		return common.Hash{}, fmt.Errorf("failed to get block: %w", err)
	}

	stateRootHex, ok := result["stateRoot"].(string)
	if !ok {
		return common.Hash{}, fmt.Errorf("state root not found in block")
	}

	return common.HexToHash(stateRootHex), nil
}

// MarshalJSON implements json.Marshaler for debugging
func (a *AccountInfo) MarshalJSON() ([]byte, error) {
	type Alias AccountInfo
	return json.Marshal(&struct {
		Balance string `json:"balance"`
		*Alias
	}{
		Balance: a.GetBalance().String(),
		Alias:   (*Alias)(a),
	})
}
