package derivation

import (
	"context"
	"fmt"
	"math/big"
	"sync"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/state"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/ethclient"
)

// StatelessExecutor executes L2 batches using ONLY L1 data
// This is 100% trustless - no L2 RPC dependency!
//
// Design Philosophy:
// - Background sync: Continuously process L1 batches and build L2 state
// - Local state DB: Maintain complete L2 state locally
// - RAT verification: Use local state (fast, 1-5 minutes)
//
// Trade-offs:
// + 100% trustless (L1 data only)
// + Fast verification (1-5 min) once synced
// + No L2 RPC cooperation needed
// - Initial sync time: days to weeks
// - Disk space: 1-5 TB
// - Continuous background processing
//
// Use Cases:
// - Large validators (institutional)
// - High-value staking operations
// - Maximum security requirements
type StatelessExecutor struct {
	l1Client *ethclient.Client

	// L1 contract addresses
	batchInbox     common.Address
	batcherAddress common.Address

	// Local L2 state DB (built from L1 batches)
	stateDB     *state.StateDB
	currentHead uint64 // Current synced L2 block number

	// Sync control
	mu           sync.RWMutex
	syncInterval time.Duration // How often to check for new batches
	stopCh       chan struct{}

	// Config
	chainID *big.Int
}

// NewStatelessExecutor creates a new stateless executor
func NewStatelessExecutor(
	l1RPCURL string,
	batchInbox common.Address,
	batcherAddress common.Address,
	chainID *big.Int,
	genesisStateRoot common.Hash,
) (*StatelessExecutor, error) {
	l1Client, err := ethclient.Dial(l1RPCURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to L1: %w", err)
	}

	// TODO: Initialize state DB with genesis state
	// For now, placeholder
	var stateDB *state.StateDB = nil

	return &StatelessExecutor{
		l1Client:       l1Client,
		batchInbox:     batchInbox,
		batcherAddress: batcherAddress,
		stateDB:        stateDB,
		currentHead:    0,
		syncInterval:   12 * time.Second, // L1 block time
		stopCh:         make(chan struct{}),
		chainID:        chainID,
	}, nil
}

// StartBackgroundSync starts continuous background synchronization
// This should run 24/7 to maintain up-to-date L2 state
func (e *StatelessExecutor) StartBackgroundSync(ctx context.Context) error {
	go e.syncLoop(ctx)
	return nil
}

// syncLoop continuously fetches and processes L1 batches
func (e *StatelessExecutor) syncLoop(ctx context.Context) {
	ticker := time.NewTicker(e.syncInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-e.stopCh:
			return
		case <-ticker.C:
			if err := e.syncNextBatch(ctx); err != nil {
				// Log error but continue
				fmt.Printf("sync error: %v\n", err)
			}
		}
	}
}

// syncNextBatch fetches and processes the next batch from L1
func (e *StatelessExecutor) syncNextBatch(ctx context.Context) error {
	e.mu.Lock()
	defer e.mu.Unlock()

	// 1. Find next batch on L1
	nextBatch, err := e.fetchNextBatchFromL1(ctx, e.currentHead+1)
	if err != nil {
		return fmt.Errorf("failed to fetch next batch: %w", err)
	}

	if nextBatch == nil {
		// No new batch yet
		return nil
	}

	// 2. Execute batch transactions
	if err := e.executeBatch(nextBatch); err != nil {
		return fmt.Errorf("failed to execute batch: %w", err)
	}

	// 3. Update current head
	e.currentHead = nextBatch.L2BlockNumber

	return nil
}

// fetchNextBatchFromL1 fetches the next batch from L1
func (e *StatelessExecutor) fetchNextBatchFromL1(
	ctx context.Context,
	nextL2BlockNum uint64,
) (*ProcessedBatch, error) {
	// TODO: Implement L1 batch fetching
	// Steps:
	// 1. Query L1 for transactions to batchInbox from batcherAddress
	// 2. Decode batch data (calldata or blobs)
	// 3. Parse batch format (SingularBatch or SpanBatch)
	// 4. Return decoded batch

	return nil, fmt.Errorf("L1 batch fetching not yet implemented")
}

// ProcessedBatch represents a decoded batch ready for execution
type ProcessedBatch struct {
	L2BlockNumber uint64
	Timestamp     uint64
	Transactions  []*types.Transaction
	L1Origin      L1Origin
}

// L1Origin represents the L1 block that included this batch
type L1Origin struct {
	BlockNumber uint64
	BlockHash   common.Hash
	TxIndex     uint
}

// executeBatch executes all transactions in a batch
func (e *StatelessExecutor) executeBatch(batch *ProcessedBatch) error {
	// TODO: Implement batch execution
	// Steps:
	// 1. Apply L1 attributes deposit transaction (Optimism-specific)
	// 2. Execute each user transaction
	// 3. Update state DB
	// 4. Compute new state root

	return fmt.Errorf("batch execution not yet implemented")
}

// VerifyStateRoot verifies the state root at a specific L2 block
// This is the main function called during RAT verification
//
// Returns:
// - computed state root (from local execution)
// - error if verification fails
func (e *StatelessExecutor) VerifyStateRoot(
	ctx context.Context,
	targetL2Block uint64,
) (common.Hash, error) {
	e.mu.RLock()
	defer e.mu.RUnlock()

	// Check if we've synced to target block
	if e.currentHead < targetL2Block {
		return common.Hash{}, fmt.Errorf(
			"local state not synced to target block: current=%d, target=%d (behind by %d blocks)",
			e.currentHead,
			targetL2Block,
			targetL2Block-e.currentHead,
		)
	}

	// Get state root from local state DB
	// This is 100% trustless - computed from L1 batches only!
	stateRoot := e.getStateRootAtBlock(targetL2Block)

	return stateRoot, nil
}

// getStateRootAtBlock retrieves the state root at a specific block
func (e *StatelessExecutor) getStateRootAtBlock(blockNum uint64) common.Hash {
	// TODO: Query state DB for historical state root
	// For now, placeholder
	return common.Hash{}
}

// GetCurrentSyncProgress returns the current sync progress
func (e *StatelessExecutor) GetCurrentSyncProgress() (currentBlock, latestL1Block uint64, err error) {
	e.mu.RLock()
	defer e.mu.RUnlock()

	// Get latest L1 block
	header, err := e.l1Client.HeaderByNumber(context.Background(), nil)
	if err != nil {
		return 0, 0, err
	}

	return e.currentHead, header.Number.Uint64(), nil
}

// IsSynced checks if the executor is synced to a specific L2 block
func (e *StatelessExecutor) IsSynced(targetL2Block uint64) bool {
	e.mu.RLock()
	defer e.mu.RUnlock()

	return e.currentHead >= targetL2Block
}

// Stop stops the background sync
func (e *StatelessExecutor) Stop() {
	close(e.stopCh)
}

// CatchUp quickly syncs from current head to target block
// This is used when RAT verification is needed but we're behind
func (e *StatelessExecutor) CatchUp(ctx context.Context, targetBlock uint64) error {
	e.mu.Lock()
	defer e.mu.Unlock()

	for e.currentHead < targetBlock {
		batch, err := e.fetchNextBatchFromL1(ctx, e.currentHead+1)
		if err != nil {
			return fmt.Errorf("catch-up failed at block %d: %w", e.currentHead+1, err)
		}

		if batch == nil {
			return fmt.Errorf("batch for block %d not found on L1", e.currentHead+1)
		}

		if err := e.executeBatch(batch); err != nil {
			return fmt.Errorf("catch-up execution failed at block %d: %w", e.currentHead+1, err)
		}

		e.currentHead = batch.L2BlockNumber

		// Check context cancellation
		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
		}
	}

	return nil
}

// EstimateCatchUpTime estimates time needed to catch up to target block
func (e *StatelessExecutor) EstimateCatchUpTime(targetBlock uint64) time.Duration {
	e.mu.RLock()
	defer e.mu.RUnlock()

	if e.currentHead >= targetBlock {
		return 0
	}

	blocksBehind := targetBlock - e.currentHead

	// Rough estimate: 100ms per block execution
	// (includes L1 fetch + batch decode + execution)
	timePerBlock := 100 * time.Millisecond

	return time.Duration(blocksBehind) * timePerBlock
}
