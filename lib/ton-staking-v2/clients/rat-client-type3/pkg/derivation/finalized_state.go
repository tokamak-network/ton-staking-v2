package derivation

import (
	"context"
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
)

// FinalizedOutput represents a finalized L2 output on L1
type FinalizedOutput struct {
	OutputRoot    common.Hash
	L2BlockNumber *big.Int
	L1Timestamp   *big.Int
}

// FinalizedStateFetcher fetches finalized L2 state from L1
type FinalizedStateFetcher struct {
	l1Client               *ethclient.Client
	optimismPortal         common.Address
	disputeGameFactory     common.Address
	disputeGameFinalityDelay uint64 // seconds
}

// NewFinalizedStateFetcher creates a new finalized state fetcher
func NewFinalizedStateFetcher(
	l1RPCURL string,
	optimismPortal common.Address,
	disputeGameFactory common.Address,
	finalityDelay uint64,
) (*FinalizedStateFetcher, error) {
	client, err := ethclient.Dial(l1RPCURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to L1: %w", err)
	}

	return &FinalizedStateFetcher{
		l1Client:               client,
		optimismPortal:         optimismPortal,
		disputeGameFactory:     disputeGameFactory,
		disputeGameFinalityDelay: finalityDelay,
	}, nil
}

// GetFinalizedOutput gets the latest finalized L2 output from L1
// This queries OptimismPortal2 or DisputeGameFactory for finalized state
func (f *FinalizedStateFetcher) GetFinalizedOutput(ctx context.Context) (*FinalizedOutput, error) {
	// TODO: Implement actual finalized output lookup
	//
	// Option 1: Query OptimismPortal2.respectedGameType games
	//   - Get all games of respected type
	//   - Filter games older than finality delay
	//   - Find highest L2 block number that's finalized
	//
	// Option 2: Query AnchorStateRegistry.anchors()
	//   - Get anchor for respected game type
	//   - Extract output root and L2 block number
	//
	// Option 3: Use L2 "safe" block as approximation (current implementation)

	// For now, return nil to indicate not implemented
	return nil, fmt.Errorf("finalized output lookup not yet implemented")
}

// GetFinalizedOutputFromPortal queries OptimismPortal2 for finalized output
func (f *FinalizedStateFetcher) GetFinalizedOutputFromPortal(ctx context.Context) (*FinalizedOutput, error) {
	// TODO: Implement OptimismPortal2 query
	//
	// Call OptimismPortal2.finalizedWithdrawalTimestamp()
	// Find L2 outputs older than finalized timestamp
	// Return highest finalized output

	return nil, fmt.Errorf("portal finalized query not implemented")
}

// GetFinalizedOutputFromDisputeGameFactory queries DisputeGameFactory
func (f *FinalizedStateFetcher) GetFinalizedOutputFromDisputeGameFactory(ctx context.Context) (*FinalizedOutput, error) {
	// TODO: Implement DisputeGameFactory query
	//
	// Steps:
	// 1. Get respectedGameType
	// 2. Query all games of that type
	// 3. Filter games by:
	//    - Status == DEFENDER_WINS
	//    - createdAt + finality_delay < now
	// 4. Find game with highest L2 block number
	// 5. Extract output root from that game

	return nil, fmt.Errorf("dispute game factory query not implemented")
}

// IsOutputFinalized checks if a specific output is finalized
func (f *FinalizedStateFetcher) IsOutputFinalized(
	ctx context.Context,
	outputRoot common.Hash,
	l2BlockNumber *big.Int,
	timestamp *big.Int,
) (bool, error) {
	// Check if enough time has passed for finalization
	header, err := f.l1Client.HeaderByNumber(ctx, nil)
	if err != nil {
		return false, fmt.Errorf("failed to get L1 header: %w", err)
	}

	timePassed := header.Time - timestamp.Uint64()
	if timePassed < f.disputeGameFinalityDelay {
		return false, nil
	}

	// TODO: Also check dispute game status
	// Should verify that no successful challenges exist

	return true, nil
}

// GetSafeL2Block gets the L2 "safe" block as approximation (fallback)
func (f *FinalizedStateFetcher) GetSafeL2Block(ctx context.Context, l2Client *ethclient.Client) (*FinalizedOutput, error) {
	// Get L2 safe block (-4 in geth)
	header, err := l2Client.HeaderByNumber(ctx, big.NewInt(-4))
	if err != nil {
		return nil, fmt.Errorf("failed to get safe L2 block: %w", err)
	}

	return &FinalizedOutput{
		OutputRoot:    header.Root, // State root as approximation
		L2BlockNumber: header.Number,
		L1Timestamp:   big.NewInt(int64(header.Time)),
	}, nil
}

// Close closes the L1 client connection
func (f *FinalizedStateFetcher) Close() {
	if f.l1Client != nil {
		f.l1Client.Close()
	}
}

// Helper function to query contract
func (f *FinalizedStateFetcher) callContract(
	ctx context.Context,
	contract common.Address,
	data []byte,
) ([]byte, error) {
	msg := ethereum.CallMsg{
		To:   &contract,
		Data: data,
	}

	return f.l1Client.CallContract(ctx, msg, nil)
}
