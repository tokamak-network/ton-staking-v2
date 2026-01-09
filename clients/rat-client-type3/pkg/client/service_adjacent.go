package client

import (
	"context"
	"crypto/ecdsa"
	"fmt"
	"math/big"
	"sync"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/log"
	"github.com/tokamak-network/ton-staking-v2/clients/rat-client-type3/pkg/evidence"
	"github.com/tokamak-network/ton-staking-v2/clients/rat-client-type3/pkg/l2sync"
	"github.com/tokamak-network/ton-staking-v2/clients/rat-client-type3/pkg/monitor"
	"github.com/tokamak-network/ton-staking-v2/clients/rat-client-type3/pkg/submitter"
	"github.com/tokamak-network/ton-staking-v2/clients/rat-client-type3/pkg/verification"
)

// RATClientAdjacentService implements RAT client using adjacent leaves verification
type RATClientAdjacentService struct {
	// Configuration
	l1RPCURL         string
	l2RPCURL         string
	opNodeRPCURL     string
	ratContract      common.Address
	stakingContract  common.Address
	validatorAddress common.Address
	privateKey       *ecdsa.PrivateKey

	// Components
	eventMonitor *monitor.EventMonitor
	stateSyncer  *l2sync.StateSynchronizer
	submitter    *submitter.AdjacentLeavesSubmitter
	opNodeClient *verification.OpNodeRollupClient

	// Lifecycle
	ctx    context.Context
	cancel context.CancelFunc
	wg     sync.WaitGroup

	// Metrics
	mu                    sync.RWMutex
	processedTests        uint64
	successfulSubmissions uint64
	failedSubmissions     uint64
}

// AdjacentServiceConfig configuration for the adjacent leaves service
type AdjacentServiceConfig struct {
	// L1 Configuration
	L1RPCURL         string
	RATContract      common.Address
	PollInterval     time.Duration
	Confirmations    uint64
	StartBlockNumber uint64

	// L2 Configuration
	L2RPCURL        string
	OpNodeRPCURL    string         // op-node Rollup RPC URL (for OutputRootProof)
	StateDBPath     string         // Path to op-geth state database
	StakingContract common.Address // Not used in state trie mode, kept for compatibility

	// Validator
	ValidatorAddress common.Address
	PrivateKey       *ecdsa.PrivateKey

	// Gas settings
	GasLimit    uint64
	MaxGasPrice *big.Int
}

// NewRATClientAdjacentService creates a new RAT client service using adjacent leaves
func NewRATClientAdjacentService(config *AdjacentServiceConfig) (*RATClientAdjacentService, error) {
	ctx, cancel := context.WithCancel(context.Background())

	// Create state synchronizer (for accessing op-geth state trie)
	stateSyncer, err := l2sync.NewStateSynchronizer(&l2sync.StateSyncConfig{
		L2RPCURL:    config.L2RPCURL,
		StateDBPath: config.StateDBPath,
	})
	if err != nil {
		cancel()
		return nil, fmt.Errorf("failed to create state synchronizer: %w", err)
	}

	// Create event monitor
	eventMonitor, err := monitor.NewEventMonitor(
		config.L1RPCURL,
		config.RATContract,
		config.ValidatorAddress,
		common.Address{}, // SystemConfig not used in adjacent leaves mode
		config.PollInterval,
		config.Confirmations,
		config.StartBlockNumber,
	)
	if err != nil {
		cancel()
		return nil, fmt.Errorf("failed to create event monitor: %w", err)
	}

	// Create submitter
	evidenceSubmitter, err := submitter.NewAdjacentLeavesSubmitter(
		config.L1RPCURL,
		config.PrivateKey,
		config.RATContract,
		config.GasLimit,
		config.MaxGasPrice,
	)
	if err != nil {
		cancel()
		return nil, fmt.Errorf("failed to create submitter: %w", err)
	}

	// Create op-node client (for OutputRootProof)
	var opNodeClient *verification.OpNodeRollupClient
	if config.OpNodeRPCURL != "" {
		opNodeClient, err = verification.NewOpNodeRollupClient(config.OpNodeRPCURL)
		if err != nil {
			cancel()
			return nil, fmt.Errorf("failed to create op-node client: %w", err)
		}
		log.Info("op-node client created", "opNodeRPC", config.OpNodeRPCURL)
	} else {
		log.Warn("OpNodeRPCURL not configured - OutputRootProof will not be included in evidence")
	}

	log.Info("Created RAT client service (adjacent leaves mode)",
		"l1RPC", config.L1RPCURL,
		"l2RPC", config.L2RPCURL,
		"opNodeRPC", config.OpNodeRPCURL,
		"ratContract", config.RATContract.Hex(),
		"stakingContract", config.StakingContract.Hex(),
		"validator", config.ValidatorAddress.Hex(),
	)

	return &RATClientAdjacentService{
		l1RPCURL:         config.L1RPCURL,
		l2RPCURL:         config.L2RPCURL,
		opNodeRPCURL:     config.OpNodeRPCURL,
		ratContract:      config.RATContract,
		stakingContract:  config.StakingContract,
		validatorAddress: config.ValidatorAddress,
		privateKey:       config.PrivateKey,
		eventMonitor:     eventMonitor,
		stateSyncer:      stateSyncer,
		submitter:        evidenceSubmitter,
		opNodeClient:     opNodeClient,
		ctx:              ctx,
		cancel:           cancel,
	}, nil
}

// Start starts the RAT client service
func (s *RATClientAdjacentService) Start() error {
	log.Info("=== Starting RAT Client (Adjacent Leaves Mode) ===")

	// Verify state database is accessible
	log.Info("Checking op-geth state database access...")
	if _, err := s.stateSyncer.GetLatestBlockNumber(context.Background()); err != nil {
		return fmt.Errorf("failed to access state database: %w", err)
	}
	log.Info("State database access verified")

	// Start event monitor
	if err := s.eventMonitor.Start(); err != nil {
		return fmt.Errorf("failed to start event monitor: %w", err)
	}

	// Start event processing loop
	s.wg.Add(1)
	go s.processEvents()

	log.Info("=== RAT Client Started ===")
	s.printStatus()

	return nil
}

// Stop stops the RAT client service
func (s *RATClientAdjacentService) Stop() {
	log.Info("=== Stopping RAT Client ===")

	s.cancel()

	if s.eventMonitor != nil {
		s.eventMonitor.Stop()
	}

	if s.stateSyncer != nil {
		s.stateSyncer.Close()
	}

	if s.submitter != nil {
		s.submitter.Close()
	}

	if s.opNodeClient != nil {
		s.opNodeClient.Close()
	}

	s.wg.Wait()

	s.printStatus()
	log.Info("=== RAT Client Stopped ===")
}

// processEvents processes attention test events
func (s *RATClientAdjacentService) processEvents() {
	defer s.wg.Done()

	for {
		select {
		case <-s.ctx.Done():
			return

		case event := <-s.eventMonitor.Events():
			if err := s.handleAttentionTest(event); err != nil {
				log.Error("Failed to handle attention test", "error", err, "testID", common.BytesToHash(event.TestId[:]).Hex())
				s.mu.Lock()
				s.failedSubmissions++
				s.mu.Unlock()
			} else {
				s.mu.Lock()
				s.successfulSubmissions++
				s.mu.Unlock()
			}

			s.mu.Lock()
			s.processedTests++
			s.mu.Unlock()
		}
	}
}

// handleAttentionTest handles an attention test event
func (s *RATClientAdjacentService) handleAttentionTest(event *monitor.AttentionTestTriggered) error {
	// Convert testId to randomValue
	// testId is bytes32, convert to uint256 for random value
	randomValue := new(big.Int).SetBytes(event.TestId[:])

	log.Info("=== Handling Attention Test ===",
		"testID", common.BytesToHash(event.TestId[:]).Hex(),
		"validator", event.Validator.Hex(),
		"randomValue", randomValue,
		"deadline", time.Unix(event.Deadline.Int64(), 0),
	)

	// Check if we are the target validator
	if event.Validator != s.validatorAddress {
		log.Info("Not our test, skipping", "target", event.Validator.Hex())
		return nil
	}

	// Check deadline
	timeRemaining := event.Deadline.Int64() - time.Now().Unix()
	if timeRemaining < 600 { // 10 minutes buffer
		return fmt.Errorf("deadline too close: %d seconds remaining", timeRemaining)
	}

	log.Info("Deadline check passed", "remaining", timeRemaining, "seconds")

	// Get current L2 block number
	currentBlock, err := s.stateSyncer.GetLatestBlockNumber(s.ctx)
	if err != nil {
		return fmt.Errorf("failed to get latest block: %w", err)
	}

	// Find adjacent leaves in state trie
	log.Info("Finding adjacent leaves in state trie",
		"randomValue", randomValue,
		"blockNumber", currentBlock,
	)

	adjacentLeaves, err := s.stateSyncer.FindAdjacentLeaves(s.ctx, randomValue, currentBlock)
	if err != nil {
		return fmt.Errorf("failed to find adjacent leaves: %w", err)
	}

	log.Info("Found adjacent leaves in state trie",
		"leafA.key", adjacentLeaves.LeafA.Key.Hex(),
		"leafA.balance", adjacentLeaves.LeafA.Balance,
		"leafB.key", adjacentLeaves.LeafB.Key.Hex(),
		"leafB.balance", adjacentLeaves.LeafB.Balance,
		"stateRoot", adjacentLeaves.StateRoot.Hex(),
		"blockNumber", adjacentLeaves.BlockNumber,
	)

	// Create evidence from state trie leaves
	ev, err := evidence.NewStateLeafEvidence(adjacentLeaves)
	if err != nil {
		return fmt.Errorf("failed to create evidence: %w", err)
	}

	// Get OutputRootProof from op-node (if configured)
	if s.opNodeClient != nil {
		log.Info("Fetching OutputRootProof from op-node", "blockNumber", adjacentLeaves.BlockNumber)

		opNodeProof, err := s.opNodeClient.GetOutputRootProof(s.ctx, adjacentLeaves.BlockNumber)
		if err != nil {
			log.Warn("Failed to get OutputRootProof from op-node", "error", err)
			// Continue without OutputRootProof (backward compatibility)
		} else {
			// Convert opNodeProof to evidence.OutputRootProof
			ev.OutputRootProof = evidence.OutputRootProof{
				Version:                  opNodeProof.Version,
				StateRoot:                opNodeProof.StateRoot,
				MessagePasserStorageRoot: opNodeProof.MessagePasserStorageRoot,
				LatestBlockHash:          opNodeProof.LatestBlockHash,
			}

			log.Info("OutputRootProof fetched",
				"version", common.Bytes2Hex(opNodeProof.Version[:]),
				"stateRoot", opNodeProof.StateRoot.Hex(),
				"messagePasserStorageRoot", opNodeProof.MessagePasserStorageRoot.Hex(),
				"latestBlockHash", opNodeProof.LatestBlockHash.Hex(),
			)

			// Verify StateRoot matches
			if opNodeProof.StateRoot != adjacentLeaves.StateRoot {
				log.Warn("StateRoot mismatch between op-node and state trie",
					"opNodeStateRoot", opNodeProof.StateRoot.Hex(),
					"stateTrie StateRoot", adjacentLeaves.StateRoot.Hex(),
				)
			}
		}
	}

	log.Info("Evidence created", "size", ev.Size(), "bytes")
	log.Debug("Evidence details", "evidence", ev.String())

	// Submit evidence
	log.Info("Submitting evidence to L1...")

	receipt, err := s.submitter.SubmitEvidence(s.ctx, event.TestId, randomValue, ev)
	if err != nil {
		return fmt.Errorf("failed to submit evidence: %w", err)
	}

	log.Info("=== Evidence Submitted Successfully ===",
		"txHash", receipt.TxHash.Hex(),
		"blockNumber", receipt.BlockNumber,
		"gasUsed", receipt.GasUsed,
		"status", receipt.Status,
	)

	return nil
}

// waitForL2Sync is not needed for state trie approach
// State DB is already synced by op-geth
// This function is kept for compatibility but does nothing
func (s *RATClientAdjacentService) waitForL2Sync() error {
	// State synchronizer just accesses op-geth's database
	// No need to wait for sync
	return nil
}

// printStatus prints current service status
func (s *RATClientAdjacentService) printStatus() {
	s.mu.RLock()
	defer s.mu.RUnlock()

	// Get latest block from state DB
	latestBlock, err := s.stateSyncer.GetLatestBlockNumber(context.Background())
	if err != nil {
		latestBlock = 0
	}

	log.Info("=== Service Status ===",
		"processedTests", s.processedTests,
		"successfulSubmissions", s.successfulSubmissions,
		"failedSubmissions", s.failedSubmissions,
		"l2LatestBlock", latestBlock,
	)
}

// GetMetrics returns service metrics
func (s *RATClientAdjacentService) GetMetrics() map[string]interface{} {
	s.mu.RLock()
	defer s.mu.RUnlock()

	// Get latest block from state DB
	latestBlock, err := s.stateSyncer.GetLatestBlockNumber(context.Background())
	if err != nil {
		latestBlock = 0
	}

	return map[string]interface{}{
		"processed_tests":        s.processedTests,
		"successful_submissions": s.successfulSubmissions,
		"failed_submissions":     s.failedSubmissions,
		"l2_latest_block":        latestBlock,
	}
}
