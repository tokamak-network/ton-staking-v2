package client

import (
	"context"
	"fmt"
	"log"
	"sync"

	"github.com/tokamak-network/ton-staking-v2/clients/rat-client-type3/pkg/monitor"
	"github.com/tokamak-network/ton-staking-v2/clients/rat-client-type3/pkg/submitter"
	"github.com/tokamak-network/ton-staking-v2/clients/rat-client-type3/pkg/verification"
)

// RATClientService manages the RAT client lifecycle
type RATClientService struct {
	config *Config

	// Components
	eventMonitor *monitor.EventMonitor
	rpcManager   *RPCManager

	// Lifecycle
	ctx    context.Context
	cancel context.CancelFunc
	wg     sync.WaitGroup
}

// NewRATClientService creates a new RAT client service
func NewRATClientService(config *Config) (*RATClientService, error) {
	if err := config.Validate(); err != nil {
		return nil, fmt.Errorf("invalid config: %w", err)
	}

	ctx, cancel := context.WithCancel(context.Background())

	// Create RPC manager with failover support
	rpcManager := NewRPCManager(config.RPCURLs)

	return &RATClientService{
		config:     config,
		rpcManager: rpcManager,
		ctx:        ctx,
		cancel:     cancel,
	}, nil
}

// Start starts the RAT client service
func (s *RATClientService) Start() error {
	log.Printf("=== RAT Client Type 3 Starting ===")
	log.Printf("Verification Mode: %s", s.config.VerificationMode)
	log.Printf("Validator: %s", s.config.ValidatorAddress.Hex())
	log.Printf("SystemConfig: %s", s.config.SystemConfig.Hex())
	log.Printf("RAT Contract: %s", s.config.RATContract.Hex())
	log.Printf("L1 RPC: %s", s.config.L1RPCURL)
	log.Printf("RPCs: %v", s.config.RPCURLs)

	// Print initial RPC status
	s.rpcManager.PrintStatus()

	// Initialize event monitor
	eventMonitor, err := monitor.NewEventMonitor(
		s.config.L1RPCURL,
		s.config.RATContract,
		s.config.ValidatorAddress,
		s.config.SystemConfig,
		s.config.PollInterval,
		s.config.Confirmations,
		s.config.StartBlockNumber,
	)
	if err != nil {
		return fmt.Errorf("failed to create event monitor: %w", err)
	}
	s.eventMonitor = eventMonitor

	// Start event monitor
	if err := s.eventMonitor.Start(); err != nil {
		return fmt.Errorf("failed to start event monitor: %w", err)
	}

	// Start event processing loop
	s.wg.Add(1)
	go s.processEvents()

	log.Printf("=== RAT Client Started ===")
	return nil
}

// Stop stops the RAT client service
func (s *RATClientService) Stop() {
	log.Printf("=== RAT Client Stopping ===")
	s.cancel()

	if s.eventMonitor != nil {
		s.eventMonitor.Stop()
	}

	if s.rpcManager != nil {
		s.rpcManager.Stop()
	}

	s.wg.Wait()
	log.Printf("=== RAT Client Stopped ===")
}

// Wait waits for the service to stop
func (s *RATClientService) Wait() {
	s.wg.Wait()
}

// processEvents processes incoming AttentionTest events
func (s *RATClientService) processEvents() {
	defer s.wg.Done()

	for {
		select {
		case <-s.ctx.Done():
			return

		case event, ok := <-s.eventMonitor.Events():
			if !ok {
				return // Channel closed
			}

			if err := s.handleAttentionTest(event); err != nil {
				log.Printf("Error handling attention test: %v", err)
			}
		}
	}
}

// handleAttentionTest handles a single attention test event
func (s *RATClientService) handleAttentionTest(event *monitor.AttentionTestTriggered) error {
	log.Printf("========================================")
	log.Printf("Handling AttentionTest")
	log.Printf("  TestID: %x", event.TestId)
	log.Printf("  BatchIndex: %d", event.BatchIndex)
	log.Printf("  GameAddress: %s", event.GameAddress.Hex())
	log.Printf("  Deadline: %s", event.Deadline.String())
	log.Printf("  Verification Mode: %s", s.config.VerificationMode)
	log.Printf("========================================")

	// Handle based on verification mode
	switch s.config.VerificationMode {
	case VerificationModeOpNode:
		return s.handleOpNodeMode(event)
	case VerificationModeL2RPC:
		return s.handleL2RPCMode(event)
	case VerificationModeHybrid:
		return s.handleHybridMode(event)
	case VerificationModeStateless:
		return s.handleStatelessMode(event)
	default:
		return fmt.Errorf("unknown verification mode: %s", s.config.VerificationMode)
	}
}

// handleOpNodeMode handles verification using op-node
func (s *RATClientService) handleOpNodeMode(event *monitor.AttentionTestTriggered) error {
	log.Printf("🔍 Using op-node verification mode")

	// TODO: Get target L2 block number and claimed output root from event
	// For now, use placeholder values
	targetL2Block := uint64(0) // TODO: derive from batchIndex
	claimedOutputRoot := event.BatchHash

	var result *verification.OpNodeVerificationResult

	// Try verification with RPC failover
	err := s.tryRPCOperation(func(rpcURL string) error {
		log.Printf("Using RPC: %s", rpcURL)

		// Create OpNodeVerifier
		verifier, err := verification.NewOpNodeVerifier(s.config.L1RPCURL, rpcURL)
		if err != nil {
			return fmt.Errorf("failed to create op-node verifier: %w", err)
		}
		defer verifier.Close()

		// Set timeouts from config
		verifier.SetMaxWaitTime(s.config.OpNodeMaxWaitTime)
		verifier.SetCheckInterval(s.config.OpNodeCheckInterval)

		// Verify batch using op-node
		log.Printf("⏳ Verifying batch at L2 block %d...", targetL2Block)
		result, err = verifier.VerifyBatch(context.Background(), targetL2Block, claimedOutputRoot)
		if err != nil {
			return fmt.Errorf("verification failed: %w", err)
		}

		return nil
	})

	if err != nil {
		return fmt.Errorf("all RPC attempts failed: %w", err)
	}

	// Check if verification passed
	if result.IsValid {
		log.Printf("✅ Verification PASSED - Output roots match!")
		log.Printf("   No evidence needed, validator is honest")
		return nil
	}

	// Verification failed - fraud detected!
	log.Printf("❌ FRAUD DETECTED!")
	log.Printf("   Claimed:  %s", result.ClaimedOutputRoot.Hex())
	log.Printf("   Computed: %s", result.ComputedOutputRoot.Hex())
	log.Printf("   → Submitting evidence to RAT contract...")

	// Build evidence
	evidence := s.buildOpNodeEvidence(result)

	// Submit evidence
	return s.submitEvidence(event, evidence)
}

// handleL2RPCMode handles verification using L2 RPC + proofs
func (s *RATClientService) handleL2RPCMode(event *monitor.AttentionTestTriggered) error {
	log.Printf("🔍 Using L2 RPC + proof verification mode")
	// TODO: Implement L2 RPC mode
	return fmt.Errorf("L2 RPC mode not yet implemented")
}

// handleHybridMode handles verification using hybrid approach
func (s *RATClientService) handleHybridMode(event *monitor.AttentionTestTriggered) error {
	log.Printf("🔍 Using hybrid verification mode")

	// Try op-node first
	err := s.handleOpNodeMode(event)
	if err == nil {
		return nil
	}

	log.Printf("⚠️  op-node verification failed: %v", err)
	log.Printf("   Falling back to L2 RPC mode...")

	// Fallback to L2 RPC
	return s.handleL2RPCMode(event)
}

// handleStatelessMode handles verification using stateless executor
func (s *RATClientService) handleStatelessMode(event *monitor.AttentionTestTriggered) error {
	log.Printf("🔍 Using stateless verification mode")
	// TODO: Implement stateless mode
	return fmt.Errorf("stateless mode not yet implemented")
}

// buildOpNodeEvidence builds evidence from op-node verification result
func (s *RATClientService) buildOpNodeEvidence(result *verification.OpNodeVerificationResult) []byte {
	// For op-node mode, we can use a simple evidence structure
	// since op-node already computed everything trustlessly

	log.Printf("🔨 Building evidence from op-node verification result...")

	// Create Evidence struct (matches Type3EvidenceVerifier.sol)
	evidence := &submitter.Type3Evidence{
		// L2 data (from op-node verification)
		L2BlockNumber:  result.TargetL2Block,
		L2BlockHash:    result.L2BlockHash,
		L2StateRoot:    result.ComputedStateRoot,
		WithdrawalRoot: result.WithdrawalRoot,
		OutputRoot:     result.ComputedOutputRoot,

		// L1 source information - TODO: Need to query from op-node
		// These would be obtained by:
		// 1. Query op-node for L1 origin of this L2 block
		// 2. Fetch the L1 block and transaction that contains the batch
		L1BlockNumber:  0, // TODO: Get from op-node (L1 block containing batch)
		L1BlockHash:    [32]byte{}, // TODO: Get from L1 client
		L1TxIndex:      0, // TODO: Get transaction index in L1 block
		L1TxHash:       [32]byte{}, // TODO: Get L1 tx hash containing batch
		BatchData:      []byte{}, // TODO: Extract from L1 transaction calldata/blobs

		// Merkle proofs - TODO: Generate proofs
		// For op-node mode, these may not be strictly necessary since
		// op-node already performed trustless derivation, but the contract
		// requires them for on-chain verification
		StateProof:      [][32]byte{}, // TODO: Generate state proof
		WithdrawalProof: [][32]byte{}, // TODO: Generate withdrawal proof
		BatchProof:      [][32]byte{}, // TODO: Generate batch proof
		L2HeaderRLP:     []byte{}, // TODO: Build L2 header RLP
	}

	// Encode evidence using ABI encoding
	encodedEvidence, err := submitter.EncodeType3Evidence(evidence)
	if err != nil {
		log.Printf("❌ Failed to encode evidence: %v", err)
		return []byte{}
	}

	log.Printf("✅ Evidence encoded: %d bytes", len(encodedEvidence))
	log.Printf("   L2 Block: %d", evidence.L2BlockNumber)
	log.Printf("   L2 Block Hash: %s", evidence.L2BlockHash.Hex())
	log.Printf("   Computed State Root: %s", evidence.L2StateRoot.Hex())
	log.Printf("   Computed Output Root: %s", evidence.OutputRoot.Hex())

	return encodedEvidence
}

// submitEvidence submits evidence to RAT contract
func (s *RATClientService) submitEvidence(event *monitor.AttentionTestTriggered, evidence []byte) error {
	log.Printf("📤 Submitting evidence to RAT contract...")

	// Create evidence submitter
	evidenceSubmitter, err := submitter.NewEvidenceSubmitter(
		s.config.L1RPCURL,
		s.config.GetPrivateKey(),
		s.config.RATContract,
		s.config.GasLimit,
		s.config.MaxGasPrice,
	)
	if err != nil {
		return fmt.Errorf("failed to create evidence submitter: %w", err)
	}
	defer evidenceSubmitter.Close()

	// Submit evidence
	receipt, err := evidenceSubmitter.SubmitEvidence(
		context.Background(),
		event.TestId,
		s.config.SystemConfig,
		event.BatchIndex,
		evidence,
		event.Deadline,
	)
	if err != nil {
		return fmt.Errorf("failed to submit evidence: %w", err)
	}

	log.Printf("✅ Evidence submitted successfully!")
	log.Printf("   TX: %s", receipt.TxHash.Hex())
	log.Printf("   Block: %d", receipt.BlockNumber.Uint64())
	log.Printf("   Gas used: %d", receipt.GasUsed)

	return nil
}

// getRPCWithFailover returns RPC URL with failover support
func (s *RATClientService) getRPCWithFailover() (string, error) {
	return s.rpcManager.GetHealthyRPC()
}

// tryRPCOperation tries an RPC operation with automatic failover
func (s *RATClientService) tryRPCOperation(operation func(rpcURL string) error) error {
	return s.rpcManager.TryWithFailover(operation)
}
