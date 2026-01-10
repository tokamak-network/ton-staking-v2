package monitor

import (
	"context"
	"fmt"
	"log"
	"math/big"
	"time"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
)

// AttentionTestTriggered represents the parsed event
type AttentionTestTriggered struct {
	TestId       [32]byte
	Validator    common.Address
	SystemConfig common.Address
	GameAddress  common.Address
	BatchIndex   uint32
	Deadline     *big.Int
	BatchHash    common.Hash // Output root claimed by proposer (from triggerAttentionTest)
	BlockNumber  uint64
	TxHash       common.Hash
}

// EventMonitor monitors L1 for AttentionTestTriggered events
type EventMonitor struct {
	l1Client         *ethclient.Client
	ratContract      common.Address
	validatorAddress common.Address
	systemConfig     common.Address
	pollInterval     time.Duration
	confirmations    uint64

	// Event topic hash for AttentionTestTriggered
	eventTopic common.Hash

	// Last processed block
	lastProcessedBlock uint64

	// Output channel
	eventsChan chan *AttentionTestTriggered

	// Context for cancellation
	ctx    context.Context
	cancel context.CancelFunc
}

// NewEventMonitor creates a new event monitor
func NewEventMonitor(
	l1RPCURL string,
	ratContract common.Address,
	validatorAddress common.Address,
	systemConfig common.Address,
	pollInterval time.Duration,
	confirmations uint64,
	startBlock uint64,
) (*EventMonitor, error) {
	client, err := ethclient.Dial(l1RPCURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to L1: %w", err)
	}

	// Compute event topic: keccak256("AttentionTestTriggered(bytes32,address,address,address,uint32,uint256)")
	eventSig := []byte("AttentionTestTriggered(bytes32,address,address,address,uint32,uint256)")
	eventTopic := crypto.Keccak256Hash(eventSig)

	ctx, cancel := context.WithCancel(context.Background())

	// Initialize lastProcessedBlock to startBlock - 1
	// so that first poll includes startBlock
	var initialLastProcessed uint64
	if startBlock > 0 {
		initialLastProcessed = startBlock - 1
	} else {
		initialLastProcessed = 0
	}

	log.Printf("[DEBUG] EventMonitor initialized with startBlock=%d, lastProcessedBlock=%d", startBlock, initialLastProcessed)

	return &EventMonitor{
		l1Client:           client,
		ratContract:        ratContract,
		validatorAddress:   validatorAddress,
		systemConfig:       systemConfig,
		pollInterval:       pollInterval,
		confirmations:      confirmations,
		eventTopic:         eventTopic,
		lastProcessedBlock: initialLastProcessed,
		eventsChan:         make(chan *AttentionTestTriggered, 10),
		ctx:                ctx,
		cancel:             cancel,
	}, nil
}

// Start begins monitoring for events
func (m *EventMonitor) Start() error {
	log.Printf("Starting event monitor...")
	log.Printf("  RAT Contract: %s", m.ratContract.Hex())
	log.Printf("  Validator: %s", m.validatorAddress.Hex())
	log.Printf("  SystemConfig: %s", m.systemConfig.Hex())
	log.Printf("  Poll Interval: %v", m.pollInterval)
	log.Printf("  lastProcessedBlock: %d", m.lastProcessedBlock)

	go m.pollLoop()
	return nil
}

// Stop stops the event monitor
func (m *EventMonitor) Stop() {
	log.Printf("Stopping event monitor...")
	m.cancel()
	close(m.eventsChan)
}

// Events returns the channel for receiving events
func (m *EventMonitor) Events() <-chan *AttentionTestTriggered {
	return m.eventsChan
}

// pollLoop continuously polls for new events
func (m *EventMonitor) pollLoop() {
	log.Printf("[DEBUG] pollLoop started, performing immediate poll...")

	// Do an immediate poll to catch up on any missed events
	if err := m.poll(); err != nil {
		log.Printf("Error in initial poll: %v", err)
	}

	ticker := time.NewTicker(m.pollInterval)
	defer ticker.Stop()

	for {
		select {
		case <-m.ctx.Done():
			log.Printf("[DEBUG] pollLoop context done, exiting")
			return
		case <-ticker.C:
			if err := m.poll(); err != nil {
				log.Printf("Error polling events: %v", err)
			}
		}
	}
}

// poll queries L1 for new events
func (m *EventMonitor) poll() error {
	log.Printf("[DEBUG] ===== poll() called, lastProcessedBlock=%d =====", m.lastProcessedBlock)

	// Get current block number
	log.Printf("[DEBUG] Getting current block number...")
	currentBlock, err := m.l1Client.BlockNumber(m.ctx)
	if err != nil {
		return fmt.Errorf("failed to get current block: %w", err)
	}
	log.Printf("[DEBUG] Current block: %d", currentBlock)

	// Apply confirmations (check for underflow)
	var safeBlock uint64
	if currentBlock > m.confirmations {
		safeBlock = currentBlock - m.confirmations
	} else {
		safeBlock = 0
	}
	log.Printf("[DEBUG] safeBlock (currentBlock %d - confirmations %d) = %d", currentBlock, m.confirmations, safeBlock)

	if safeBlock <= m.lastProcessedBlock {
		log.Printf("[DEBUG] Nothing new to process (safeBlock=%d, lastProcessed=%d)", safeBlock, m.lastProcessedBlock)
		return nil // Nothing new to process
	}

	// Query logs from lastProcessedBlock+1 to safeBlock
	fromBlock := m.lastProcessedBlock + 1
	toBlock := safeBlock

	log.Printf("[DEBUG] Preparing FilterLogs query from block %d to %d", fromBlock, toBlock)

	topics := [][]common.Hash{
		{m.eventTopic},                                   // event signature
		{},                                               // testId (any)
		{common.BytesToHash(m.validatorAddress.Bytes())}, // validator (filter our address)
	}

	// Only filter by systemConfig if it's not empty
	if m.systemConfig != (common.Address{}) {
		log.Printf("[DEBUG] Filtering by systemConfig: %s", m.systemConfig.Hex())
		topics = append(topics, []common.Hash{common.BytesToHash(m.systemConfig.Bytes())})
	} else {
		log.Printf("[DEBUG] SystemConfig is empty, not filtering by it")
	}

	log.Printf("[DEBUG] Query parameters:")
	log.Printf("[DEBUG]   FromBlock: %d", fromBlock)
	log.Printf("[DEBUG]   ToBlock: %d", toBlock)
	log.Printf("[DEBUG]   RAT Contract: %s", m.ratContract.Hex())
	log.Printf("[DEBUG]   Validator: %s", m.validatorAddress.Hex())
	log.Printf("[DEBUG]   Event Topic: %s", m.eventTopic.Hex())
	log.Printf("[DEBUG]   Topics count: %d", len(topics))

	query := ethereum.FilterQuery{
		FromBlock: big.NewInt(int64(fromBlock)),
		ToBlock:   big.NewInt(int64(toBlock)),
		Addresses: []common.Address{m.ratContract},
		Topics:    topics,
	}

	log.Printf("[DEBUG] Calling FilterLogs...")
	logs, err := m.l1Client.FilterLogs(m.ctx, query)
	if err != nil {
		log.Printf("[DEBUG] FilterLogs failed with error: %v", err)
		log.Printf("[DEBUG] Error type: %T", err)
		return fmt.Errorf("failed to filter logs: %w", err)
	}
	log.Printf("[DEBUG] FilterLogs returned %d logs", len(logs))

	log.Printf("Polled blocks %d-%d: found %d events", fromBlock, toBlock, len(logs))

	// Parse and send events
	for _, vLog := range logs {
		event, err := m.parseEvent(vLog)
		if err != nil {
			log.Printf("Failed to parse event: %v", err)
			continue
		}

		log.Printf("⚠️  AttentionTest triggered: testId=%x, batch=%d, deadline=%s",
			event.TestId, event.BatchIndex, time.Unix(event.Deadline.Int64(), 0))

		// Send to channel (non-blocking)
		select {
		case m.eventsChan <- event:
		case <-m.ctx.Done():
			return nil
		default:
			log.Printf("Warning: event channel full, dropping event")
		}
	}

	// Update last processed block
	m.lastProcessedBlock = toBlock

	return nil
}

// parseEvent parses a raw log into AttentionTestTriggered
func (m *EventMonitor) parseEvent(vLog types.Log) (*AttentionTestTriggered, error) {
	if len(vLog.Topics) < 4 {
		return nil, fmt.Errorf("invalid number of topics: %d", len(vLog.Topics))
	}

	// Topics[0] = event signature (already filtered)
	// Topics[1] = testId (indexed bytes32)
	// Topics[2] = validator (indexed address)
	// Topics[3] = systemConfig (indexed address)

	var testId [32]byte
	copy(testId[:], vLog.Topics[1].Bytes())

	validator := common.BytesToAddress(vLog.Topics[2].Bytes())
	systemConfig := common.BytesToAddress(vLog.Topics[3].Bytes())

	// Parse data: gameAddress (address), batchIndex (uint32), deadline (uint256)
	if len(vLog.Data) < 96 {
		return nil, fmt.Errorf("invalid data length: %d", len(vLog.Data))
	}

	gameAddress := common.BytesToAddress(vLog.Data[0:32])
	batchIndex := new(big.Int).SetBytes(vLog.Data[32:64]).Uint64()
	deadline := new(big.Int).SetBytes(vLog.Data[64:96])

	return &AttentionTestTriggered{
		TestId:       testId,
		Validator:    validator,
		SystemConfig: systemConfig,
		GameAddress:  gameAddress,
		BatchIndex:   uint32(batchIndex),
		Deadline:     deadline,
		BlockNumber:  vLog.BlockNumber,
		TxHash:       vLog.TxHash,
	}, nil
}
