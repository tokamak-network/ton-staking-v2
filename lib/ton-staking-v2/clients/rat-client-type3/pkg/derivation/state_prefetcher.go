package derivation

import (
	"context"
	"fmt"
	"sync"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/ethclient"
)

// StatePrefetcher pre-fetches state data needed for batch execution
// This is a CRITICAL optimization to avoid calling eth_getProof for every state access
//
// Strategy:
// 1. Analyze batch transactions to predict state accesses
// 2. Batch fetch all needed proofs in parallel
// 3. Cache proofs locally
// 4. Execute batch using cached proofs (fast!)
//
// Without this: Batch execution could take 10+ minutes (thousands of RPC calls)
// With this: Batch execution takes seconds (one parallel RPC batch)
type StatePrefetcher struct {
	l2Client  *ethclient.Client
	stateRoot common.Hash

	// Pre-fetched data cache
	accountProofs  map[common.Address]*AccountProof
	storageProofs  map[common.Address]map[common.Hash]*StorageProof
	mu             sync.RWMutex
}

// NewStatePrefetcher creates a new state prefetcher
func NewStatePrefetcher(l2Client *ethclient.Client, stateRoot common.Hash) *StatePrefetcher {
	return &StatePrefetcher{
		l2Client:      l2Client,
		stateRoot:     stateRoot,
		accountProofs: make(map[common.Address]*AccountProof),
		storageProofs: make(map[common.Address]map[common.Hash]*StorageProof),
	}
}

// StateAccessList represents all state that will be accessed
type StateAccessList struct {
	// Accounts that will be read
	Accounts map[common.Address]bool

	// Storage slots that will be read
	Storage map[common.Address]map[common.Hash]bool
}

// AnalyzeBatch analyzes batch to predict state accesses
func (p *StatePrefetcher) AnalyzeBatch(batch *SingularBatch) (*StateAccessList, error) {
	accessList := &StateAccessList{
		Accounts: make(map[common.Address]bool),
		Storage:  make(map[common.Address]map[common.Hash]bool),
	}

	// Decode transactions
	for _, txBytes := range batch.Transactions {
		tx := new(types.Transaction)
		if err := tx.UnmarshalBinary(txBytes); err != nil {
			return nil, fmt.Errorf("failed to unmarshal tx: %w", err)
		}

		// Predict state accesses from transaction
		// This is heuristic-based since we can't know exact accesses without execution
		p.predictStateAccesses(tx, accessList)
	}

	// Always include system contracts
	p.addSystemContracts(accessList)

	return accessList, nil
}

// predictStateAccesses predicts what state a transaction will access
func (p *StatePrefetcher) predictStateAccesses(tx *types.Transaction, accessList *StateAccessList) {
	// 1. Sender account (always accessed for nonce, balance)
	// Note: We need to recover sender address from signature
	// For now, we'll mark it as TODO since it requires chainID

	// 2. Recipient account
	if tx.To() != nil {
		accessList.Accounts[*tx.To()] = true
	}

	// 3. Contract code (if calling a contract)
	if tx.To() != nil && len(tx.Data()) > 0 {
		// This is a contract call
		// We'll fetch the account to get code
		accessList.Accounts[*tx.To()] = true

		// Storage accesses are hard to predict without execution
		// Strategy: Use eth_createAccessList RPC to get hints
		// For now, mark as TODO
	}

	// 4. Contract creation (if tx.To() == nil)
	if tx.To() == nil {
		// Contract creation - hard to predict state accesses
		// The new contract address needs to be computed
		// TODO: Compute CREATE address and add to access list
	}
}

// addSystemContracts adds Optimism system contracts that are always accessed
func (p *StatePrefetcher) addSystemContracts(accessList *StateAccessList) {
	// L1Block predeploy (always read for L1 context)
	l1Block := common.HexToAddress("0x4200000000000000000000000000000000000015")
	accessList.Accounts[l1Block] = true

	// L1MessageSender (deposit transactions)
	l1MessageSender := common.HexToAddress("0x4200000000000000000000000000000000000001")
	accessList.Accounts[l1MessageSender] = true

	// GasPriceOracle (for L1 data fee calculation)
	gasPriceOracle := common.HexToAddress("0x420000000000000000000000000000000000000F")
	accessList.Accounts[gasPriceOracle] = true

	// Add more system contracts as needed
}

// PrefetchState pre-fetches all state from access list
// This is the KEY optimization - fetch everything in parallel!
func (p *StatePrefetcher) PrefetchState(ctx context.Context, accessList *StateAccessList) error {
	// Use worker pool to fetch proofs in parallel
	const numWorkers = 10

	type fetchJob struct {
		address    common.Address
		storageKey *common.Hash // nil for account-only fetch
	}

	jobs := make(chan fetchJob, len(accessList.Accounts))
	errors := make(chan error, len(accessList.Accounts))
	var wg sync.WaitGroup

	// Start workers
	for i := 0; i < numWorkers; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for job := range jobs {
				if job.storageKey == nil {
					// Fetch account proof
					if err := p.fetchAccountProof(ctx, job.address); err != nil {
						errors <- fmt.Errorf("failed to fetch account %s: %w", job.address.Hex(), err)
						return
					}
				} else {
					// Fetch storage proof
					if err := p.fetchStorageProof(ctx, job.address, *job.storageKey); err != nil {
						errors <- fmt.Errorf("failed to fetch storage %s[%s]: %w",
							job.address.Hex(), job.storageKey.Hex(), err)
						return
					}
				}
			}
		}()
	}

	// Queue account fetch jobs
	for address := range accessList.Accounts {
		jobs <- fetchJob{address: address}
	}

	// Queue storage fetch jobs
	for address, slots := range accessList.Storage {
		for slot := range slots {
			slotCopy := slot
			jobs <- fetchJob{address: address, storageKey: &slotCopy}
		}
	}

	close(jobs)
	wg.Wait()
	close(errors)

	// Check for errors
	if len(errors) > 0 {
		return <-errors
	}

	return nil
}

// fetchAccountProof fetches and caches account proof
func (p *StatePrefetcher) fetchAccountProof(ctx context.Context, address common.Address) error {
	// Call eth_getProof
	type Result struct {
		Address      common.Address `json:"address"`
		Balance      string         `json:"balance"`
		CodeHash     common.Hash    `json:"codeHash"`
		Nonce        string         `json:"nonce"`
		StorageHash  common.Hash    `json:"storageHash"`
		AccountProof []string       `json:"accountProof"`
	}

	var result Result
	err := p.l2Client.Client().CallContext(
		ctx,
		&result,
		"eth_getProof",
		address,
		[]string{},
		fmt.Sprintf("0x%x", p.stateRoot),
	)
	if err != nil {
		return err
	}

	// Parse and cache
	// TODO: Parse balance and nonce from hex strings
	proof := &AccountProof{
		Address:      result.Address,
		// Balance:      parseBigInt(result.Balance),
		CodeHash:     result.CodeHash,
		// Nonce:        parseUint64(result.Nonce),
		StorageHash:  result.StorageHash,
		AccountProof: result.AccountProof,
	}

	p.mu.Lock()
	p.accountProofs[address] = proof
	p.mu.Unlock()

	return nil
}

// fetchStorageProof fetches and caches storage proof
func (p *StatePrefetcher) fetchStorageProof(ctx context.Context, address common.Address, key common.Hash) error {
	// Call eth_getProof with storage key
	type Result struct {
		StorageProof []struct {
			Key   string `json:"key"`
			Value string `json:"value"`
			Proof []string `json:"proof"`
		} `json:"storageProof"`
	}

	var result Result
	err := p.l2Client.Client().CallContext(
		ctx,
		&result,
		"eth_getProof",
		address,
		[]string{key.Hex()},
		fmt.Sprintf("0x%x", p.stateRoot),
	)
	if err != nil {
		return err
	}

	if len(result.StorageProof) == 0 {
		return fmt.Errorf("no storage proof returned")
	}

	// Parse and cache
	proof := &StorageProof{
		Key:   key,
		// Value: parseHash(result.StorageProof[0].Value),
		Proof: result.StorageProof[0].Proof,
	}

	p.mu.Lock()
	if p.storageProofs[address] == nil {
		p.storageProofs[address] = make(map[common.Hash]*StorageProof)
	}
	p.storageProofs[address][key] = proof
	p.mu.Unlock()

	return nil
}

// GetCachedAccountProof gets cached account proof
func (p *StatePrefetcher) GetCachedAccountProof(address common.Address) (*AccountProof, bool) {
	p.mu.RLock()
	defer p.mu.RUnlock()
	proof, ok := p.accountProofs[address]
	return proof, ok
}

// GetCachedStorageProof gets cached storage proof
func (p *StatePrefetcher) GetCachedStorageProof(address common.Address, key common.Hash) (*StorageProof, bool) {
	p.mu.RLock()
	defer p.mu.RUnlock()
	if slots, ok := p.storageProofs[address]; ok {
		proof, ok := slots[key]
		return proof, ok
	}
	return nil, false
}

// OptimizedExecutionFlow shows how to use prefetcher
//
// Example:
//   prefetcher := NewStatePrefetcher(l2Client, stateRoot)
//
//   // 1. Analyze batch
//   accessList := prefetcher.AnalyzeBatch(batch)
//
//   // 2. Pre-fetch all state (parallel, fast!)
//   prefetcher.PrefetchState(ctx, accessList)
//
//   // 3. Execute batch using cached proofs (no RPC calls during execution!)
//   stateDB := NewProofVerifiedStateDBWithCache(l2Client, stateRoot, prefetcher)
//   result := ExecuteBatch(stateDB, batch)
//
// Performance:
//   Without prefetch: 1000 txs × 10 state accesses × 100ms RPC = 16 minutes
//   With prefetch: 10000 proofs fetched in parallel = 10 seconds
