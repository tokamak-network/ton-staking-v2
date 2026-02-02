package verification

import (
	"context"
	"fmt"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
)

// OpNodeVerifier uses op-node's Rollup RPC for 100% trustless verification
//
// Architecture:
//   RAT Client → op-node Rollup RPC → Derivation Pipeline → L1 Batches
//
// This leverages op-node's existing L1→L2 derivation pipeline:
// - L1 batch extraction
// - Frame/Channel/Batch decoding
// - L2 state execution
// - Output root computation
//
// All derived from L1 data only (100% trustless!)
type OpNodeVerifier struct {
	l1Client      *ethclient.Client
	rollupClient  *OpNodeRollupClient

	// Config
	maxWaitTime   time.Duration // Max time to wait for op-node sync
	checkInterval time.Duration // How often to check sync status
}

// NewOpNodeVerifier creates a new op-node based verifier
func NewOpNodeVerifier(
	l1RPCURL string,
	rollupRPCURL string,
) (*OpNodeVerifier, error) {
	l1Client, err := ethclient.Dial(l1RPCURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to L1: %w", err)
	}

	rollupClient, err := NewOpNodeRollupClient(rollupRPCURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to op-node: %w", err)
	}

	return &OpNodeVerifier{
		l1Client:      l1Client,
		rollupClient:  rollupClient,
		maxWaitTime:   30 * time.Minute, // RAT deadline is 1 hour, use 30 min for sync
		checkInterval: 10 * time.Second,
	}, nil
}

// VerifyBatch verifies a batch using op-node
//
// Process:
// 1. Check if op-node is synced to target L2 block
// 2. If not synced, wait (up to maxWaitTime)
// 3. Query op-node for output root at target block
// 4. Compare with claimed output root
// 5. Generate evidence if mismatch
func (v *OpNodeVerifier) VerifyBatch(
	ctx context.Context,
	targetL2Block uint64,
	claimedOutputRoot common.Hash,
) (*OpNodeVerificationResult, error) {
	startTime := time.Now()
	result := &OpNodeVerificationResult{
		TargetL2Block:     targetL2Block,
		ClaimedOutputRoot: claimedOutputRoot,
	}

	// Step 1: Check if op-node is synced
	fmt.Printf("Checking if op-node is synced to block %d...\n", targetL2Block)
	err := v.rollupClient.VerifyOpNodeSynced(ctx, targetL2Block)
	if err != nil {
		fmt.Printf("op-node not synced yet: %v\n", err)

		// Step 2: Wait for sync (with timeout)
		fmt.Printf("Waiting for op-node to sync (max %v)...\n", v.maxWaitTime)
		waitCtx, cancel := context.WithTimeout(ctx, v.maxWaitTime)
		defer cancel()

		err = v.rollupClient.WaitForL2BlockSync(waitCtx, targetL2Block, int64(v.checkInterval.Seconds()))
		if err != nil {
			result.Error = fmt.Errorf("op-node sync timeout: %w", err)
			result.VerificationTime = time.Since(startTime)
			return result, result.Error
		}

		fmt.Printf("op-node synced to block %d!\n", targetL2Block)
	}

	// Step 3: Query op-node for output at target block
	fmt.Printf("Querying op-node for output root at block %d...\n", targetL2Block)
	output, err := v.rollupClient.OutputAtBlock(ctx, targetL2Block)
	if err != nil {
		result.Error = fmt.Errorf("failed to get output from op-node: %w", err)
		result.VerificationTime = time.Since(startTime)
		return result, result.Error
	}

	result.ComputedOutputRoot = output.OutputRoot
	result.ComputedStateRoot = output.StateRoot
	result.WithdrawalRoot = output.WithdrawalStorageRoot
	result.L2BlockHash = output.BlockRef.Hash

	// Step 4: Compare computed vs claimed
	result.IsValid = (result.ComputedOutputRoot == claimedOutputRoot)
	result.VerificationTime = time.Since(startTime)

	if result.IsValid {
		fmt.Printf("✅ Verification PASSED: output roots match\n")
		fmt.Printf("   Computed: %s\n", result.ComputedOutputRoot.Hex())
		fmt.Printf("   Claimed:  %s\n", claimedOutputRoot.Hex())
	} else {
		fmt.Printf("❌ Verification FAILED: output root mismatch!\n")
		fmt.Printf("   Computed: %s\n", result.ComputedOutputRoot.Hex())
		fmt.Printf("   Claimed:  %s\n", claimedOutputRoot.Hex())
		fmt.Printf("   → Fraud detected! Need to submit evidence.\n")
	}

	fmt.Printf("Verification completed in %v\n", result.VerificationTime)

	return result, nil
}

// GetSafeL2HeadAtL1 gets the safe L2 head corresponding to an L1 block
//
// This is useful for determining which L2 blocks are considered "safe"
// based on L1 finality
func (v *OpNodeVerifier) GetSafeL2HeadAtL1(
	ctx context.Context,
	l1BlockNum uint64,
) (uint64, error) {
	resp, err := v.rollupClient.SafeHeadAtL1Block(ctx, l1BlockNum)
	if err != nil {
		return 0, err
	}

	return uint64(resp.SafeHead.Number), nil
}

// GetSyncStatus gets the current sync status from op-node
func (v *OpNodeVerifier) GetSyncStatus(ctx context.Context) (*SyncStatus, error) {
	return v.rollupClient.SyncStatus(ctx)
}

// Close closes all connections
func (v *OpNodeVerifier) Close() {
	if v.rollupClient != nil {
		v.rollupClient.Close()
	}
	if v.l1Client != nil {
		v.l1Client.Close()
	}
}

// OpNodeVerificationResult contains the verification result
type OpNodeVerificationResult struct {
	// Input
	TargetL2Block     uint64
	ClaimedOutputRoot common.Hash

	// Computed (from op-node)
	ComputedOutputRoot common.Hash
	ComputedStateRoot  common.Hash
	WithdrawalRoot     common.Hash
	L2BlockHash        common.Hash

	// Result
	IsValid          bool
	VerificationTime time.Duration

	// Error (if any)
	Error error
}

// SetMaxWaitTime sets the maximum time to wait for op-node sync
func (v *OpNodeVerifier) SetMaxWaitTime(d time.Duration) {
	v.maxWaitTime = d
}

// SetCheckInterval sets how often to check op-node sync status
func (v *OpNodeVerifier) SetCheckInterval(d time.Duration) {
	v.checkInterval = d
}
