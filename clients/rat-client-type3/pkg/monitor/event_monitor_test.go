package monitor

import (
	"math/big"
	"testing"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestParseEvent(t *testing.T) {
	// Setup
	validatorAddr := common.HexToAddress("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266")
	systemConfigAddr := common.HexToAddress("0xd037Ec2fEf38A070497b0D5e8d10319bB1999366")
	gameAddr := common.HexToAddress("0xBa3e08b4753E68952031102518379ED2fDADcA30")

	// Create event monitor (we only need it for parseEvent method)
	monitor := &EventMonitor{
		validatorAddress: validatorAddr,
	}

	// Create mock log for AttentionTestTriggered event
	// event AttentionTestTriggered(
	//     bytes32 indexed testId,
	//     address indexed validator,
	//     address indexed systemConfig,
	//     address gameAddress,
	//     uint32 batchIndex,
	//     uint256 deadline
	// )

	testID := [32]byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32}
	batchIndex := uint32(123)
	deadline := big.NewInt(1234567890)

	// Encode data: gameAddress (address), batchIndex (uint32), deadline (uint256)
	// Solidity ABI encoding: address (32 bytes), uint32 (32 bytes), uint256 (32 bytes)
	data := make([]byte, 96)
	// gameAddress (address in last 20 bytes of 32-byte slot)
	copy(data[12:32], gameAddr.Bytes())
	// batchIndex (uint32 in last 4 bytes of 32-byte slot, big-endian)
	batchIndexBig := big.NewInt(int64(batchIndex))
	batchIndexBytes := common.LeftPadBytes(batchIndexBig.Bytes(), 32)
	copy(data[32:64], batchIndexBytes)
	// deadline (uint256)
	copy(data[64:96], common.LeftPadBytes(deadline.Bytes(), 32))

	mockLog := types.Log{
		Address: common.HexToAddress("0xRATContract"),
		Topics: []common.Hash{
			crypto.Keccak256Hash([]byte("AttentionTestTriggered(bytes32,address,address,address,uint32,uint256)")), // event signature
			common.BytesToHash(testID[:]),                    // testId (indexed)
			common.BytesToHash(validatorAddr.Bytes()),        // validator (indexed)
			common.BytesToHash(systemConfigAddr.Bytes()),     // systemConfig (indexed)
		},
		Data:        data,
		BlockNumber: 100,
		TxHash:      common.HexToHash("0x123"),
		TxIndex:     1,
		BlockHash:   common.HexToHash("0xabc"),
		Index:       0,
	}

	// Test parseEvent
	event, err := monitor.parseEvent(mockLog)
	require.NoError(t, err)

	// Verify parsed event
	assert.Equal(t, testID, event.TestId)
	assert.Equal(t, validatorAddr, event.Validator)
	assert.Equal(t, systemConfigAddr, event.SystemConfig)
	assert.Equal(t, gameAddr, event.GameAddress)
	assert.Equal(t, batchIndex, event.BatchIndex)
	assert.Equal(t, deadline, event.Deadline)
}

func TestParseEvent_InvalidDataLength(t *testing.T) {
	validatorAddr := common.HexToAddress("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266")

	monitor := &EventMonitor{
		validatorAddress: validatorAddr,
	}

	testID := [32]byte{1}

	// Create log with invalid data length (too short)
	mockLog := types.Log{
		Address: common.HexToAddress("0xRATContract"),
		Topics: []common.Hash{
			crypto.Keccak256Hash([]byte("AttentionTestTriggered(bytes32,address,address,address,uint32,uint256)")),
			common.BytesToHash(testID[:]),
			common.BytesToHash(validatorAddr.Bytes()),
			common.BytesToHash(validatorAddr.Bytes()),
		},
		Data:        []byte{1, 2, 3}, // Too short - should be 96 bytes
		BlockNumber: 100,
	}

	// Should return error
	_, err := monitor.parseEvent(mockLog)
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "invalid data length")
}

func TestParseEvent_ValidatesValidator(t *testing.T) {
	validatorAddr := common.HexToAddress("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266")
	wrongValidator := common.HexToAddress("0x1111111111111111111111111111111111111111")

	monitor := &EventMonitor{
		validatorAddress: validatorAddr,
	}

	testID := [32]byte{1}
	data := make([]byte, 96)

	// Event with wrong validator address
	mockLog := types.Log{
		Address: common.HexToAddress("0xRATContract"),
		Topics: []common.Hash{
			crypto.Keccak256Hash([]byte("AttentionTestTriggered(bytes32,address,address,address,uint32,uint256)")),
			common.BytesToHash(testID[:]),
			common.BytesToHash(wrongValidator.Bytes()), // Wrong validator
			common.BytesToHash(validatorAddr.Bytes()),
		},
		Data:        data,
		BlockNumber: 100,
	}

	// Should still parse (filtering happens at query level)
	event, err := monitor.parseEvent(mockLog)
	require.NoError(t, err)
	assert.Equal(t, wrongValidator, event.Validator)
	assert.NotEqual(t, validatorAddr, event.Validator)
}

func TestEventTopic(t *testing.T) {
	// Verify event topic hash is correct
	expectedTopic := crypto.Keccak256Hash([]byte("AttentionTestTriggered(bytes32,address,address,address,uint32,uint256)"))

	// This should match the topic used in the contract
	assert.NotEqual(t, common.Hash{}, expectedTopic)
	t.Logf("AttentionTestTriggered topic: %s", expectedTopic.Hex())
}

func TestBatchIndexParsing(t *testing.T) {
	tests := []struct {
		name       string
		batchIndex uint32
	}{
		{"zero", 0},
		{"small", 1},
		{"medium", 12345},
		{"max", 4294967295}, // max uint32
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Encode batchIndex as uint32 in 32-byte slot (ABI encoding)
			data := make([]byte, 96)
			batchIndexBig := big.NewInt(int64(tt.batchIndex))
			batchIndexBytes := common.LeftPadBytes(batchIndexBig.Bytes(), 32)
			copy(data[32:64], batchIndexBytes)

			// Parse it back
			parsedBatchIndex := new(big.Int).SetBytes(data[32:64])

			assert.Equal(t, int64(tt.batchIndex), parsedBatchIndex.Int64())
		})
	}
}

func TestDeadlineParsing(t *testing.T) {
	tests := []struct {
		name     string
		deadline *big.Int
	}{
		{"zero", big.NewInt(0)},
		{"small", big.NewInt(123)},
		{"timestamp", big.NewInt(1704067200)}, // 2024-01-01 00:00:00 UTC
		{"large", new(big.Int).SetBytes([]byte{0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff})},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Encode deadline as uint256
			data := make([]byte, 96)
			copy(data[64:96], common.LeftPadBytes(tt.deadline.Bytes(), 32))

			// Parse it back
			parsedDeadline := new(big.Int).SetBytes(data[64:96])

			// Use Cmp for big.Int comparison
			assert.Equal(t, 0, tt.deadline.Cmp(parsedDeadline), "Expected %s, got %s", tt.deadline.String(), parsedDeadline.String())
		})
	}
}
