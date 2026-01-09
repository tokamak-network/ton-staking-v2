package derivation

import (
	"context"
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/ethclient"
)

// L1BatchData represents raw batch data from L1
type L1BatchData struct {
	L1BlockNumber uint64
	L1TxHash      common.Hash
	L1TxIndex     uint
	Data          []byte // Calldata or blob data
	IsBlob        bool
}

// BatchFetcher fetches batch data from L1
type BatchFetcher struct {
	l1Client       *ethclient.Client
	batchInbox     common.Address
	batcherAddress common.Address
}

// NewBatchFetcher creates a new batch fetcher
func NewBatchFetcher(
	l1RPCURL string,
	batchInbox common.Address,
	batcherAddress common.Address,
) (*BatchFetcher, error) {
	client, err := ethclient.Dial(l1RPCURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to L1: %w", err)
	}

	return &BatchFetcher{
		l1Client:       client,
		batchInbox:     batchInbox,
		batcherAddress: batcherAddress,
	}, nil
}

// FetchBatches fetches batch data from L1 blocks
func (f *BatchFetcher) FetchBatches(ctx context.Context, fromBlock, toBlock uint64) ([]*L1BatchData, error) {
	var batches []*L1BatchData

	for blockNum := fromBlock; blockNum <= toBlock; blockNum++ {
		block, err := f.l1Client.BlockByNumber(ctx, big.NewInt(int64(blockNum)))
		if err != nil {
			return nil, fmt.Errorf("failed to get block %d: %w", blockNum, err)
		}

		// Find transactions to batchInbox from batcherAddress
		for txIndex, tx := range block.Transactions() {
			if tx.To() == nil || *tx.To() != f.batchInbox {
				continue
			}

			// Get transaction sender
			sender, err := types.Sender(types.LatestSignerForChainID(tx.ChainId()), tx)
			if err != nil {
				continue
			}

			if sender != f.batcherAddress {
				continue
			}

			// Extract batch data
			batchData := &L1BatchData{
				L1BlockNumber: blockNum,
				L1TxHash:      tx.Hash(),
				L1TxIndex:     uint(txIndex),
				Data:          tx.Data(),
				IsBlob:        len(tx.BlobHashes()) > 0,
			}

			// If blob transaction, fetch blob data
			if batchData.IsBlob {
				blobData, err := f.fetchBlobData(ctx, block, tx)
				if err != nil {
					return nil, fmt.Errorf("failed to fetch blob data: %w", err)
				}
				batchData.Data = blobData
			}

			batches = append(batches, batchData)
		}
	}

	return batches, nil
}

// fetchBlobData fetches blob data for a blob transaction (EIP-4844)
func (f *BatchFetcher) fetchBlobData(ctx context.Context, block *types.Block, tx *types.Transaction) ([]byte, error) {
	// EIP-4844 blobs are stored separately from transaction data
	// We need to fetch blob sidecars for this block

	if len(tx.BlobHashes()) == 0 {
		return nil, fmt.Errorf("transaction has no blob hashes")
	}

	// TODO: Implement eth_getBlobSidecars RPC call
	// eth_getBlobSidecars was a temporary method, beacon chain getBlobSidecars is the standard
	//
	// Steps:
	// 1. Get blob sidecars for this block
	//    - RPC: engine_getBlobsV1 or beacon chain API
	// 2. Find blobs matching tx.BlobHashes()
	// 3. Extract blob data (4096 field elements per blob)
	// 4. Decode from BLS12-381 field elements to bytes
	// 5. Concatenate all blobs

	// For MVP, return error
	// In production, would need:
	// - Beacon chain API client
	// - BLS12-381 field element decoding
	// - Blob versioned hash verification

	return nil, fmt.Errorf("EIP-4844 blob fetching not yet implemented - requires beacon chain API")
}

// decodeBlobData decodes BLS12-381 field elements to bytes
func decodeBlobData(blobData []byte) ([]byte, error) {
	// EIP-4844 blobs contain 4096 field elements (32 bytes each)
	// Each field element encodes 31 bytes of actual data
	// Total: 4096 * 31 = 126,976 bytes per blob

	// TODO: Implement field element decoding
	// This requires:
	// - Parsing 4096 field elements
	// - Extracting 31 bytes from each (top byte is always 0)
	// - Concatenating

	return nil, fmt.Errorf("blob decoding not yet implemented")
}

// GetL1OriginForL2Block gets the L1 origin block for an L2 block
// This is used to determine where to start fetching batches from
func (f *BatchFetcher) GetL1OriginForL2Block(ctx context.Context, l2BlockNum uint64) (uint64, error) {
	// TODO: Implement L2 block to L1 origin mapping
	// This requires querying L2 for the L1 origin in the block attributes
	// For now, return a placeholder

	return 0, fmt.Errorf("L1 origin lookup not yet implemented")
}

// Close closes the L1 client connection
func (f *BatchFetcher) Close() {
	if f.l1Client != nil {
		f.l1Client.Close()
	}
}
