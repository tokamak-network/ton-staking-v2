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

	return &EventMonitor{
		l1Client:           client,
		ratContract:        ratContract,
		validatorAddress:   validatorAddress,
		systemConfig:       systemConfig,
		pollInterval:       pollInterval,
		confirmations:      confirmations,
		eventTopic:         eventTopic,
		lastProcessedBlock: startBlock,
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
	ticker := time.NewTicker(m.pollInterval)
	defer ticker.Stop()

	for {
		select {
		case <-m.ctx.Done():
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
	// Get current block number
	currentBlock, err := m.l1Client.BlockNumber(m.ctx)
	if err != nil {
		return fmt.Errorf("failed to get current block: %w", err)
	}

	// Apply confirmations
	safeBlock := currentBlock - m.confirmations
	if safeBlock <= m.lastProcessedBlock {
		return nil // Nothing new to process
	}

	// Query logs from lastProcessedBlock+1 to safeBlock
	fromBlock := m.lastProcessedBlock + 1
	toBlock := safeBlock

	query := ethereum.FilterQuery{
		FromBlock: big.NewInt(int64(fromBlock)),
		ToBlock:   big.NewInt(int64(toBlock)),
		Addresses: []common.Address{m.ratContract},
		Topics: [][]common.Hash{
			{m.eventTopic},                                      // event signature
			{},                                                  // testId (any)
			{common.BytesToHash(m.validatorAddress.Bytes())},    // validator (filter our address)
			{common.BytesToHash(m.systemConfig.Bytes())},        // systemConfig (filter our config)
		},
	}

	logs, err := m.l1Client.FilterLogs(m.ctx, query)
	if err != nil {
		return fmt.Errorf("failed to filter logs: %w", err)
	}

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
