package l2sync

import (
	"context"
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/rawdb"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/ethereum/go-ethereum/ethdb"
	"log"
)

// StateSynchronizer provides access to L2 state trie
type StateSynchronizer struct {
	stateDB ethdb.Database
	l2RPC   *ethclient.Client
}

// StateSyncConfig configuration for state synchronizer
type StateSyncConfig struct {
	L2RPCURL    string
	StateDBPath string
}

// NewStateSynchronizer creates a new state synchronizer
func NewStateSynchronizer(config *StateSyncConfig) (*StateSynchronizer, error) {
	// Connect to L2 RPC (for block headers)
	client, err := ethclient.Dial(config.L2RPCURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to L2 RPC: %w", err)
	}

	// Verify RPC connection
	chainID, err := client.ChainID(context.Background())
	if err != nil {
		client.Close()
		return nil, fmt.Errorf("failed to get chain ID: %w", err)
	}

	log.Printf("Connected to L2 RPC: rpc=%s, chainID=%v", config.L2RPCURL, chainID)

	// Open state database (LevelDB) only if path is provided
	var stateDB ethdb.Database
	if config.StateDBPath != "" {
		stateDB, err = rawdb.NewLevelDBDatabase(config.StateDBPath, 128, 1024, "ratclient", true)
		if err != nil {
			client.Close()
			return nil, fmt.Errorf("failed to open state DB at %s: %w", config.StateDBPath, err)
		}

		log.Printf("Opened state database: path=%s", config.StateDBPath)
	} else {
		log.Printf("State database path not provided, will use RPC mode")
	}

	return &StateSynchronizer{
		stateDB: stateDB,
		l2RPC:   client,
	}, nil
}

// FindAdjacentLeaves finds adjacent leaves in L2 state trie for given block
func (s *StateSynchronizer) FindAdjacentLeaves(
	ctx context.Context,
	randomValue *big.Int,
	blockNumber uint64,
) (*AdjacentLeaves, error) {
	log.Printf("Finding adjacent leaves: blockNumber=%d, randomValue=%v", blockNumber, randomValue)

	// If stateDB is nil, use RPC mode
	if s.stateDB == nil {
		log.Printf("Using RPC mode (debug_accountRange + eth_getProof)")
		return FindAdjacentLeavesViaRPC(ctx, s.l2RPC.Client(), randomValue, blockNumber)
	}

	// StateDB mode (direct database access)
	log.Printf("Using StateDB mode (direct database access)")

	// 1. Get state root for block
	header, err := s.l2RPC.HeaderByNumber(ctx, new(big.Int).SetUint64(blockNumber))
	if err != nil {
		return nil, fmt.Errorf("failed to get block header: %w", err)
	}

	stateRoot := header.Root

	log.Printf("Got state root: blockNumber=%d, stateRoot=%s", blockNumber, stateRoot.Hex())

	// 2. Find adjacent leaves in state trie
	leafA, leafB, err := FindAdjacentLeavesInStateTrie(s.stateDB, stateRoot, randomValue)
	if err != nil {
		return nil, fmt.Errorf("failed to find adjacent leaves: %w", err)
	}

	// 3. Generate proofs
	log.Printf("Generating Merkle proofs...")

	proofA, err := GenerateStateProof(s.stateDB, stateRoot, leafA.Key)
	if err != nil {
		return nil, fmt.Errorf("failed to generate proof for leafA: %w", err)
	}

	proofB, err := GenerateStateProof(s.stateDB, stateRoot, leafB.Key)
	if err != nil {
		return nil, fmt.Errorf("failed to generate proof for leafB: %w", err)
	}

	log.Printf("Proofs generated: proofA.nodes=%d, proofB.nodes=%d", len(proofA), len(proofB))

	// 4. Verify proofs locally
	if !VerifyStateProof(stateRoot, leafA.Key, leafA.Value, proofA) {
		return nil, fmt.Errorf("leafA proof verification failed")
	}

	if !VerifyStateProof(stateRoot, leafB.Key, leafB.Value, proofB) {
		return nil, fmt.Errorf("leafB proof verification failed")
	}

	log.Printf("Proofs verified locally")

	return &AdjacentLeaves{
		LeafA:       leafA,
		LeafB:       leafB,
		ProofA:      proofA,
		ProofB:      proofB,
		StateRoot:   stateRoot,
		BlockNumber: blockNumber,
	}, nil
}

// GetStateRoot returns state root for given block
func (s *StateSynchronizer) GetStateRoot(ctx context.Context, blockNumber uint64) (common.Hash, error) {
	header, err := s.l2RPC.HeaderByNumber(ctx, new(big.Int).SetUint64(blockNumber))
	if err != nil {
		return common.Hash{}, fmt.Errorf("failed to get block header: %w", err)
	}
	return header.Root, nil
}

// GetLatestBlockNumber returns latest block number from L2
func (s *StateSynchronizer) GetLatestBlockNumber(ctx context.Context) (uint64, error) {
	header, err := s.l2RPC.HeaderByNumber(ctx, nil)
	if err != nil {
		return 0, fmt.Errorf("failed to get latest block: %w", err)
	}
	return header.Number.Uint64(), nil
}

// IsSynced checks if op-geth is synced
func (s *StateSynchronizer) IsSynced(ctx context.Context) (bool, error) {
	// Check if we can get latest block
	_, err := s.GetLatestBlockNumber(ctx)
	if err != nil {
		return false, err
	}

	// If we can get latest block, assume synced
	// More sophisticated sync check could use eth_syncing
	return true, nil
}

// EstimateStateSize estimates number of accounts in current state
func (s *StateSynchronizer) EstimateStateSize(ctx context.Context) (int, error) {
	// Get latest state root
	stateRoot, err := s.GetStateRoot(ctx, 0) // 0 means latest
	if err != nil {
		return 0, err
	}

	return EstimateStateSize(s.stateDB, stateRoot)
}

// Close closes database and RPC connections
func (s *StateSynchronizer) Close() error {
	if s.l2RPC != nil {
		s.l2RPC.Close()
	}

	if s.stateDB != nil {
		return s.stateDB.Close()
	}

	return nil
}

// AdjacentLeaves represents adjacent leaves in state trie with proofs
type AdjacentLeaves struct {
	LeafA       *StateTrieLeaf
	LeafB       *StateTrieLeaf
	ProofA      [][]byte
	ProofB      [][]byte
	StateRoot   common.Hash
	BlockNumber uint64
}
