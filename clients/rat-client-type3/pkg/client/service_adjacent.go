package client

import (
	"context"
	"crypto/ecdsa"
	"fmt"
	"log"
	"math/big"
	"sync"
	"time"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/tokamak-network/ton-staking-v2/clients/rat-client-type3/pkg/bindings"
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
	ratClient    *bindings.RAT // RAT contract instance for reading test data

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

	// Create state synchronizer (for accessing L2 state)
	// If StateDBPath is empty, will use RPC mode instead
	var stateSyncer *l2sync.StateSynchronizer
	var err error

	if config.StateDBPath != "" {
		// StateDB mode (direct access to op-geth database)
		stateSyncer, err = l2sync.NewStateSynchronizer(&l2sync.StateSyncConfig{
			L2RPCURL:    config.L2RPCURL,
			StateDBPath: config.StateDBPath,
		})
		if err != nil {
			cancel()
			return nil, fmt.Errorf("failed to create state synchronizer: %w", err)
		}
		log.Printf("Using StateDB mode (direct database access)")
	} else {
		// RPC mode (use debug_accountRange + eth_getProof)
		stateSyncer, err = l2sync.NewStateSynchronizer(&l2sync.StateSyncConfig{
			L2RPCURL:    config.L2RPCURL,
			StateDBPath: "", // Will skip StateDB opening
		})
		if err != nil {
			cancel()
			return nil, fmt.Errorf("failed to create state synchronizer: %w", err)
		}
		log.Printf("Using RPC mode (debug_accountRange + eth_getProof)")
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

	// Connect to RAT contract for reading test data
	l1Client, err := ethclient.Dial(config.L1RPCURL)
	if err != nil {
		cancel()
		return nil, fmt.Errorf("failed to connect to L1 for RAT contract: %w", err)
	}
	ratClient, err := bindings.NewRAT(config.RATContract, l1Client)
	if err != nil {
		cancel()
		return nil, fmt.Errorf("failed to bind RAT contract: %w", err)
	}

	// Create op-node client (for OutputRootProof)
	var opNodeClient *verification.OpNodeRollupClient
	if config.OpNodeRPCURL != "" {
		opNodeClient, err = verification.NewOpNodeRollupClient(config.OpNodeRPCURL)
		if err != nil {
			cancel()
			return nil, fmt.Errorf("failed to create op-node client: %w", err)
		}
		log.Printf("op-node client created", "opNodeRPC", config.OpNodeRPCURL)
	} else {
		log.Printf("OpNodeRPCURL not configured - OutputRootProof will not be included in evidence")
	}

	log.Printf("Created RAT client service (adjacent leaves mode)",
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
		ratClient:        ratClient,
		ctx:              ctx,
		cancel:           cancel,
	}, nil
}

// Start starts the RAT client service
func (s *RATClientAdjacentService) Start() error {
	log.Printf("=== Starting RAT Client (Adjacent Leaves Mode) ===")

	// Verify L2 RPC connection
	log.Printf("Checking L2 RPC connection...")
	if _, err := s.stateSyncer.GetLatestBlockNumber(context.Background()); err != nil {
		return fmt.Errorf("failed to connect to L2 RPC: %w", err)
	}
	log.Printf("L2 RPC connection verified")

	// Start event monitor
	if err := s.eventMonitor.Start(); err != nil {
		return fmt.Errorf("failed to start event monitor: %w", err)
	}

	// Start event processing loop
	s.wg.Add(1)
	go s.processEvents()

	log.Printf("=== RAT Client Started ===")
	s.printStatus()

	return nil
}

// Stop stops the RAT client service
func (s *RATClientAdjacentService) Stop() {
	log.Printf("=== Stopping RAT Client ===")

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
	log.Printf("=== RAT Client Stopped ===")
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
				log.Printf("Failed to handle attention test", "error", err, "testID", common.BytesToHash(event.TestId[:]).Hex())
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
	// Query the RAT contract to get the full test data including batchHash (state root)
	testData, err := s.ratClient.AttentionTests(nil, event.TestId)
	if err != nil {
		return fmt.Errorf("failed to query attention test from contract: %w", err)
	}

	log.Printf("=== Handling Attention Test === testID=%s validator=%s outputRoot=%s batchIndex=%d deadline=%s",
		common.BytesToHash(event.TestId[:]).Hex(),
		event.Validator.Hex(),
		common.BytesToHash(testData.BatchHash[:]).Hex(),
		testData.BatchIndex,
		time.Unix(event.Deadline.Int64(), 0).String(),
	)

	// Check if we are the target validator
	if event.Validator != s.validatorAddress {
		log.Printf("Not our test, skipping - target=%s", event.Validator.Hex())
		return nil
	}

	// Check deadline
	timeRemaining := event.Deadline.Int64() - time.Now().Unix()
	if timeRemaining < 600 { // 10 minutes buffer
		return fmt.Errorf("deadline too close: %d seconds remaining", timeRemaining)
	}

	log.Printf("Deadline check passed - remaining=%d seconds", timeRemaining)

	// Get L2 block number from DisputeGame contract
	// BatchIndex is the game index, not the L2 block number!
	// We need to query the DisputeGame contract to get l2BlockNumber()
	blockNumber, err := s.getL2BlockNumberFromGame(testData.GameAddress)
	if err != nil {
		return fmt.Errorf("failed to get L2 block number from game %s: %w", testData.GameAddress.Hex(), err)
	}

	log.Printf("Got L2 block number from DisputeGame - blockNumber=%d", blockNumber)

	// Get StateRoot for the specific block
	// In "State Root as Target" mode, we find adjacent leaves that bracket the StateRoot
	stateRoot, err := s.stateSyncer.GetStateRoot(s.ctx, blockNumber)
	if err != nil {
		return fmt.Errorf("failed to get state root for block %d: %w", blockNumber, err)
	}

	// Verify that this block produces the expected OutputRoot (BatchHash)
	// This ensures we have the correct block number and get OutputRootProof
	outputRootProof, err := s.verifyAndGetOutputRoot(blockNumber, stateRoot, testData.BatchHash)
	if err != nil {
		return fmt.Errorf("output root verification failed for block %d: %w", blockNumber, err)
	}

	log.Printf("✓ Verified OutputRoot matches - block %d has correct StateRoot", blockNumber)

	// Use StateRoot as the target value for finding adjacent leaves
	randomValue := new(big.Int).SetBytes(stateRoot[:])

	log.Printf("Got state root for block %d - stateRoot=%s randomValue=%s",
		blockNumber,
		stateRoot.Hex(),
		randomValue.String(),
	)

	// Find adjacent leaves in state trie
	log.Printf("Finding adjacent leaves in state trie - randomValue=%s blockNumber=%d",
		randomValue.String(),
		blockNumber,
	)

	adjacentLeaves, err := s.stateSyncer.FindAdjacentLeaves(s.ctx, randomValue, blockNumber)
	if err != nil {
		return fmt.Errorf("failed to find adjacent leaves: %w", err)
	}

	log.Printf("Found adjacent leaves in state trie - leafA.key=%s leafA.balance=%s leafB.key=%s leafB.balance=%s stateRoot=%s blockNumber=%d",
		adjacentLeaves.LeafA.Key.Hex(),
		adjacentLeaves.LeafA.Balance.String(),
		adjacentLeaves.LeafB.Key.Hex(),
		adjacentLeaves.LeafB.Balance.String(),
		adjacentLeaves.StateRoot.Hex(),
		adjacentLeaves.BlockNumber,
	)

	// Create evidence from state trie leaves
	ev, err := evidence.NewStateLeafEvidence(adjacentLeaves)
	if err != nil {
		return fmt.Errorf("failed to create evidence: %w", err)
	}

	// Add OutputRootProof to evidence (already verified above)
	ev.OutputRootProof = *outputRootProof
	log.Printf("Added OutputRootProof to evidence - version=%s stateRoot=%s messagePasserStorageRoot=%s blockHash=%s",
		common.Bytes2Hex(outputRootProof.Version[:]),
		outputRootProof.StateRoot.Hex(),
		outputRootProof.MessagePasserStorageRoot.Hex(),
		outputRootProof.LatestBlockHash.Hex(),
	)

	// Get OutputRootProof from op-node (if configured) - for verification only
	if s.opNodeClient != nil {
		log.Printf("Fetching OutputRootProof from op-node - blockNumber=%d", adjacentLeaves.BlockNumber)

		opNodeProof, err := s.opNodeClient.GetOutputRootProof(s.ctx, adjacentLeaves.BlockNumber)
		if err != nil {
			log.Printf("Failed to get OutputRootProof from op-node - error=%v", err)
			// Continue without OutputRootProof (backward compatibility)
		} else {
			// Convert opNodeProof to evidence.OutputRootProof
			ev.OutputRootProof = evidence.OutputRootProof{
				Version:                  opNodeProof.Version,
				StateRoot:                opNodeProof.StateRoot,
				MessagePasserStorageRoot: opNodeProof.MessagePasserStorageRoot,
				LatestBlockHash:          opNodeProof.LatestBlockHash,
			}

			log.Printf("OutputRootProof fetched - version=%s stateRoot=%s messagePasserStorageRoot=%s latestBlockHash=%s",
				common.Bytes2Hex(opNodeProof.Version[:]),
				opNodeProof.StateRoot.Hex(),
				opNodeProof.MessagePasserStorageRoot.Hex(),
				opNodeProof.LatestBlockHash.Hex(),
			)

			// Verify StateRoot matches
			if opNodeProof.StateRoot != adjacentLeaves.StateRoot {
				log.Printf("StateRoot mismatch between op-node and state trie - opNodeStateRoot=%s stateTrie StateRoot=%s",
					opNodeProof.StateRoot.Hex(),
					adjacentLeaves.StateRoot.Hex(),
				)
			}
		}
	}

	log.Printf("Evidence created - size=%d bytes", ev.Size())
	log.Printf("Evidence details: %s", ev.String())

	// Submit evidence
	log.Printf("Submitting evidence to L1...")

	receipt, err := s.submitter.SubmitEvidence(s.ctx, event.TestId, randomValue, ev)
	if err != nil {
		return fmt.Errorf("failed to submit evidence: %w", err)
	}

	log.Printf("=== Evidence Submitted Successfully === txHash=%s blockNumber=%d gasUsed=%d status=%d",
		receipt.TxHash.Hex(),
		receipt.BlockNumber.Uint64(),
		receipt.GasUsed,
		receipt.Status,
	)

	return nil
}

// verifyAndGetOutputRoot verifies that the given StateRoot produces the expected OutputRoot
// and returns the OutputRootProof for evidence
// OutputRoot = keccak256(version || stateRoot || messagePasserStorageRoot || blockHash)
func (s *RATClientAdjacentService) verifyAndGetOutputRoot(blockNumber uint64, stateRoot common.Hash, expectedOutputRoot [32]byte) (*evidence.OutputRootProof, error) {
	// Connect to L2
	client, err := ethclient.Dial(s.l2RPCURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to L2: %w", err)
	}
	defer client.Close()

	// Get block header to get blockHash
	header, err := client.HeaderByNumber(s.ctx, new(big.Int).SetUint64(blockNumber))
	if err != nil {
		return nil, fmt.Errorf("failed to get block header: %w", err)
	}
	blockHash := header.Hash()

	// Verify stateRoot matches
	if header.Root != stateRoot {
		return nil, fmt.Errorf("state root mismatch: got %s, expected %s", header.Root.Hex(), stateRoot.Hex())
	}

	// L2ToL1MessagePasser predeploy address (Optimism standard)
	messagePasserAddr := common.HexToAddress("0x4200000000000000000000000000000000000016")

	// Get MessagePasser storage root using eth_getProof
	type StorageResult struct {
		Key   string   `json:"key"`
		Value string   `json:"value"`
		Proof []string `json:"proof"`
	}
	type AccountResult struct {
		Address      common.Address  `json:"address"`
		AccountProof []string        `json:"accountProof"`
		Balance      string          `json:"balance"`
		CodeHash     common.Hash     `json:"codeHash"`
		Nonce        string          `json:"nonce"`
		StorageHash  common.Hash     `json:"storageHash"`
		StorageProof []StorageResult `json:"storageProof"`
	}

	var proofResult AccountResult
	blockHex := fmt.Sprintf("0x%x", blockNumber)
	err = client.Client().CallContext(s.ctx, &proofResult, "eth_getProof", messagePasserAddr, []string{}, blockHex)
	if err != nil {
		return nil, fmt.Errorf("failed to get proof for MessagePasser: %w", err)
	}

	messagePasserStorageRoot := proofResult.StorageHash

	// Calculate OutputRoot = keccak256(abi.encode(version, stateRoot, messagePasserStorageRoot, blockHash))
	// Use ABI encoding (not raw concatenation!)
	var version [32]byte // version 0

	// ABI encode: each 32-byte value is encoded as-is
	uint256Type, _ := abi.NewType("bytes32", "", nil)
	arguments := abi.Arguments{
		{Type: uint256Type},
		{Type: uint256Type},
		{Type: uint256Type},
		{Type: uint256Type},
	}

	encoded, err := arguments.Pack(
		version,
		stateRoot,
		messagePasserStorageRoot,
		blockHash,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to ABI encode OutputRootProof: %w", err)
	}

	computedOutputRoot := crypto.Keccak256Hash(encoded)

	// Compare with expected
	expectedHash := common.BytesToHash(expectedOutputRoot[:])
	if computedOutputRoot != expectedHash {
		return nil, fmt.Errorf("output root mismatch: computed=%s expected=%s (stateRoot=%s blockHash=%s messagePasserStorageRoot=%s)",
			computedOutputRoot.Hex(),
			expectedHash.Hex(),
			stateRoot.Hex(),
			blockHash.Hex(),
			messagePasserStorageRoot.Hex(),
		)
	}

	log.Printf("OutputRoot verification successful - version=%s stateRoot=%s messagePasserStorageRoot=%s blockHash=%s outputRoot=%s",
		common.Bytes2Hex(version[:]),
		stateRoot.Hex(),
		messagePasserStorageRoot.Hex(),
		blockHash.Hex(),
		computedOutputRoot.Hex(),
	)

	// Return OutputRootProof for evidence
	proof := &evidence.OutputRootProof{
		Version:                  version,
		StateRoot:                stateRoot,
		MessagePasserStorageRoot: messagePasserStorageRoot,
		LatestBlockHash:          blockHash,
	}

	return proof, nil
}

// getL2BlockNumberFromGame queries the DisputeGame contract to get L2 block number
func (s *RATClientAdjacentService) getL2BlockNumberFromGame(gameAddress common.Address) (uint64, error) {
	// Connect to L1
	client, err := ethclient.Dial(s.l1RPCURL)
	if err != nil {
		return 0, fmt.Errorf("failed to connect to L1: %w", err)
	}
	defer client.Close()

	// Call l2BlockNumber() on DisputeGame
	// Function signature: l2BlockNumber() returns (uint256)
	// Keccak256("l2BlockNumber()") = 0x8b85902b...
	data := common.Hex2Bytes("8b85902b") // First 4 bytes of keccak256("l2BlockNumber()")

	msg := ethereum.CallMsg{
		To:   &gameAddress,
		Data: data,
	}

	result, err := client.CallContract(s.ctx, msg, nil)
	if err != nil {
		return 0, fmt.Errorf("failed to call l2BlockNumber(): %w", err)
	}

	if len(result) != 32 {
		return 0, fmt.Errorf("unexpected result length: %d", len(result))
	}

	blockNumber := new(big.Int).SetBytes(result)
	return blockNumber.Uint64(), nil
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

	log.Printf("=== Service Status === processedTests=%d successfulSubmissions=%d failedSubmissions=%d l2LatestBlock=%d",
		s.processedTests,
		s.successfulSubmissions,
		s.failedSubmissions,
		latestBlock,
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
