package verification

import (
	"context"
	"fmt"
	"time"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/common/hexutil"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/rpc"
)

// OpNodeRollupClient implements OutputRollupClient using op-node's Rollup RPC
// This allows RAT client to leverage op-node's L1→L2 derivation pipeline
// for 100% trustless verification
//
// op-node runs the full derivation pipeline:
// L1 batches → decode → execute → L2 state
//
// RAT client queries op-node for:
// - Safe L2 head at L1 block (SafeHeadAtL1Block)
// - Output root at L2 block (OutputAtBlock)
type OpNodeRollupClient struct {
	client *rpc.Client
}

// OutputResponse represents the response from optimism_outputAtBlock
type OutputResponse struct {
	Version               hexutil.Bytes `json:"version"`
	OutputRoot            common.Hash   `json:"outputRoot"`
	BlockRef              L2BlockRef    `json:"blockRef"`
	WithdrawalStorageRoot common.Hash   `json:"withdrawalStorageRoot"`
	StateRoot             common.Hash   `json:"stateRoot"`
	SyncStatus            SyncStatus    `json:"syncStatus"`
}

// SafeHeadResponse represents the response from optimism_safeHeadAtL1Block
type SafeHeadResponse struct {
	L1Block  L1BlockRef `json:"l1Block"`
	SafeHead L2BlockRef `json:"safeHead"`
}

// L1BlockRef represents an L1 block reference
type L1BlockRef struct {
	Hash       common.Hash    `json:"hash"`
	Number     hexutil.Uint64 `json:"number"`
	ParentHash common.Hash    `json:"parentHash"`
	Time       hexutil.Uint64 `json:"timestamp"`
}

// L2BlockRef represents an L2 block reference
type L2BlockRef struct {
	Hash           common.Hash    `json:"hash"`
	Number         hexutil.Uint64 `json:"number"`
	ParentHash     common.Hash    `json:"parentHash"`
	Time           hexutil.Uint64 `json:"timestamp"`
	L1Origin       L1BlockRef     `json:"l1origin"`
	SequenceNumber hexutil.Uint64 `json:"sequenceNumber"`
}

// SyncStatus represents the sync status from op-node
type SyncStatus struct {
	CurrentL1          L1BlockRef `json:"current_l1"`
	CurrentL1Finalized L1BlockRef `json:"current_l1_finalized"`
	HeadL1             L1BlockRef `json:"head_l1"`
	SafeL1             L1BlockRef `json:"safe_l1"`
	FinalizedL1        L1BlockRef `json:"finalized_l1"`
	UnsafeL2           L2BlockRef `json:"unsafe_l2"`
	SafeL2             L2BlockRef `json:"safe_l2"`
	FinalizedL2        L2BlockRef `json:"finalized_l2"`
	PendingSafeL2      L2BlockRef `json:"pending_safe_l2"`
}

// NewOpNodeRollupClient creates a new op-node Rollup RPC client
func NewOpNodeRollupClient(rollupRPC string) (*OpNodeRollupClient, error) {
	client, err := rpc.Dial(rollupRPC)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to op-node rollup RPC at %s: %w", rollupRPC, err)
	}

	return &OpNodeRollupClient{
		client: client,
	}, nil
}

// OutputAtBlock queries op-node for the output root at a specific L2 block
//
// RPC Method: optimism_outputAtBlock
//
// This returns the output root that op-node computed by:
// 1. Deriving L2 state from L1 batches (Derivation Pipeline)
// 2. Executing all transactions
// 3. Computing state root and withdrawal root
// 4. Calculating output root: keccak256(version || stateRoot || withdrawalRoot || blockHash)
//
// This is 100% trustless because op-node derives everything from L1 data
func (c *OpNodeRollupClient) OutputAtBlock(
	ctx context.Context,
	blockNum uint64,
) (*OutputResponse, error) {
	var result OutputResponse

	err := c.client.CallContext(
		ctx,
		&result,
		"optimism_outputAtBlock",
		hexutil.Uint64(blockNum),
	)
	if err != nil {
		return nil, fmt.Errorf("optimism_outputAtBlock(%d) failed: %w", blockNum, err)
	}

	return &result, nil
}

// SafeHeadAtL1Block queries op-node for the safe L2 head at a specific L1 block
//
// RPC Method: optimism_safeHeadAtL1Block
//
// This returns the L2 safe head that corresponds to the given L1 block.
// The "safe" head is the latest L2 block that can be derived from finalized L1 data.
//
// This is crucial for RAT verification:
// - We need to know which L2 block is considered "safe" based on L1 finality
// - This ensures we're verifying against L1-finalized data only
func (c *OpNodeRollupClient) SafeHeadAtL1Block(
	ctx context.Context,
	l1BlockNum uint64,
) (*SafeHeadResponse, error) {
	var result SafeHeadResponse

	err := c.client.CallContext(
		ctx,
		&result,
		"optimism_safeHeadAtL1Block",
		hexutil.Uint64(l1BlockNum),
	)
	if err != nil {
		return nil, fmt.Errorf("optimism_safeHeadAtL1Block(%d) failed: %w", l1BlockNum, err)
	}

	return &result, nil
}

// SyncStatus queries op-node for its current sync status
//
// RPC Method: optimism_syncStatus
//
// This returns the current sync progress of op-node, including:
// - Current L1 block being processed
// - Safe/Finalized L2 heads
// - Whether op-node is fully synced
func (c *OpNodeRollupClient) SyncStatus(ctx context.Context) (*SyncStatus, error) {
	var result SyncStatus

	err := c.client.CallContext(ctx, &result, "optimism_syncStatus")
	if err != nil {
		return nil, fmt.Errorf("optimism_syncStatus failed: %w", err)
	}

	return &result, nil
}

// Close closes the RPC connection
func (c *OpNodeRollupClient) Close() {
	if c.client != nil {
		c.client.Close()
	}
}

// VerifyOpNodeSynced checks if op-node is synced enough to verify the target block
//
// For RAT verification, we need op-node to be synced at least to the L2 block we're verifying.
func (c *OpNodeRollupClient) VerifyOpNodeSynced(
	ctx context.Context,
	targetL2Block uint64,
) error {
	status, err := c.SyncStatus(ctx)
	if err != nil {
		return fmt.Errorf("failed to get sync status: %w", err)
	}

	// Check if safe L2 head is at or beyond target block
	safeL2Number := uint64(status.SafeL2.Number)
	if safeL2Number < targetL2Block {
		return fmt.Errorf(
			"op-node not synced to target block: safe_l2=%d, target=%d (behind by %d blocks)",
			safeL2Number,
			targetL2Block,
			targetL2Block-safeL2Number,
		)
	}

	return nil
}

// GetOutputRootAtBlock is a convenience method to get just the output root
func (c *OpNodeRollupClient) GetOutputRootAtBlock(
	ctx context.Context,
	blockNum uint64,
) (common.Hash, error) {
	output, err := c.OutputAtBlock(ctx, blockNum)
	if err != nil {
		return common.Hash{}, err
	}

	return output.OutputRoot, nil
}

// GetStateRootAtBlock gets the state root at a specific block
func (c *OpNodeRollupClient) GetStateRootAtBlock(
	ctx context.Context,
	blockNum uint64,
) (common.Hash, error) {
	output, err := c.OutputAtBlock(ctx, blockNum)
	if err != nil {
		return common.Hash{}, err
	}

	return output.StateRoot, nil
}

// EstimateL1BlockForL2Block estimates which L1 block contains the batch for target L2 block
//
// This is useful for finding the L1 block to query for safe head
func (c *OpNodeRollupClient) EstimateL1BlockForL2Block(
	ctx context.Context,
	targetL2Block uint64,
) (uint64, error) {
	// Get current sync status to find relationship
	status, err := c.SyncStatus(ctx)
	if err != nil {
		return 0, err
	}

	// If target is at or before safe L2, we can estimate from current L1
	safeL2Number := uint64(status.SafeL2.Number)
	safeL1Number := uint64(status.SafeL1.Number)

	if targetL2Block <= safeL2Number {
		// Rough estimate: L2 blocks are faster than L1 blocks
		// Typically L2:L1 ratio is ~12:1 for Optimism
		l2BlocksPerL1 := uint64(12)

		l2Distance := safeL2Number - targetL2Block
		l1Distance := l2Distance / l2BlocksPerL1

		estimatedL1 := safeL1Number - l1Distance

		return estimatedL1, nil
	}

	return 0, fmt.Errorf("target L2 block %d is beyond safe L2 head %d", targetL2Block, safeL2Number)
}

// WaitForL2BlockSync waits for op-node to sync to the target L2 block
//
// This is useful when RAT is triggered but op-node hasn't caught up yet
func (c *OpNodeRollupClient) WaitForL2BlockSync(
	ctx context.Context,
	targetL2Block uint64,
	checkInterval int64, // in seconds
) error {
	ticker := time.NewTicker(time.Duration(checkInterval) * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-ticker.C:
			err := c.VerifyOpNodeSynced(ctx, targetL2Block)
			if err == nil {
				// Synced!
				return nil
			}

			// Still syncing, continue waiting
			fmt.Printf("op-node still syncing to block %d: %v\n", targetL2Block, err)
		}
	}
}

// OutputRootProof represents Optimism OutputRootProof structure
// Matches Solidity struct in Type3EvidenceVerifier.sol
type OutputRootProof struct {
	Version                  [32]byte    // Version (always 0x0)
	StateRoot                common.Hash // L2 state root
	MessagePasserStorageRoot common.Hash // L2ToL1MessagePasser storage root
	LatestBlockHash          common.Hash // L2 block hash
}

// HashOutputRootProof computes keccak256(abi.encode(OutputRootProof))
//
// This matches the Solidity implementation:
// keccak256(abi.encode(proof.version, proof.stateRoot, proof.messagePasserStorageRoot, proof.latestBlockhash))
func HashOutputRootProof(proof *OutputRootProof) common.Hash {
	bytes32Ty, _ := abi.NewType("bytes32", "", nil)

	arguments := abi.Arguments{
		{Type: bytes32Ty}, // version
		{Type: bytes32Ty}, // stateRoot
		{Type: bytes32Ty}, // messagePasserStorageRoot
		{Type: bytes32Ty}, // latestBlockhash
	}

	encoded, err := arguments.Pack(
		proof.Version,
		proof.StateRoot,
		proof.MessagePasserStorageRoot,
		proof.LatestBlockHash,
	)
	if err != nil {
		// This should never happen with valid data
		panic(fmt.Sprintf("failed to encode OutputRootProof: %v", err))
	}

	return crypto.Keccak256Hash(encoded)
}

// GetOutputRootProof queries op-node and constructs OutputRootProof
//
// This creates the OutputRootProof structure that will be:
// 1. Included in StateLeafEvidence
// 2. Verified on-chain: hash(OutputRootProof) == DisputeGame.rootClaim()
func (c *OpNodeRollupClient) GetOutputRootProof(
	ctx context.Context,
	blockNum uint64,
) (*OutputRootProof, error) {
	output, err := c.OutputAtBlock(ctx, blockNum)
	if err != nil {
		return nil, fmt.Errorf("failed to get output at block %d: %w", blockNum, err)
	}

	return &OutputRootProof{
		Version:                  [32]byte{}, // Version 0
		StateRoot:                output.StateRoot,
		MessagePasserStorageRoot: output.WithdrawalStorageRoot,
		LatestBlockHash:          output.BlockRef.Hash,
	}, nil
}

// VerifyOutputRootProof verifies that hash(OutputRootProof) == expectedRootClaim
//
// This is the same verification that happens on-chain in Type3EvidenceVerifier.sol
func (c *OpNodeRollupClient) VerifyOutputRootProof(
	proof *OutputRootProof,
	expectedRootClaim common.Hash,
) error {
	computedHash := HashOutputRootProof(proof)

	if computedHash != expectedRootClaim {
		return fmt.Errorf(
			"OutputRootProof hash mismatch: computed=%s, expected=%s",
			computedHash.Hex(),
			expectedRootClaim.Hex(),
		)
	}

	return nil
}
