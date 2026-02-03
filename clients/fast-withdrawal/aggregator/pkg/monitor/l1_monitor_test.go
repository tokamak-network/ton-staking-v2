package monitor

import (
	"math/big"
	"testing"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
)

func TestNewL1Monitor_NilClient(t *testing.T) {
	cfg := &Config{
		Client:      nil,
		RATContract: common.HexToAddress("0x1234"),
	}

	_, err := NewL1Monitor(cfg)
	if err == nil {
		t.Error("Expected error for nil client")
	}

	t.Log("✅ Nil client error handled correctly")
}

func TestFastWithdrawalRequestedTopic(t *testing.T) {
	// 이벤트 시그니처 검증
	expected := crypto.Keccak256Hash(
		[]byte("FastWithdrawalRequested(bytes32,address,uint256,uint8,uint256,bytes32,uint256,uint256)"),
	)

	if fastWithdrawalRequestedTopic != expected {
		t.Errorf("Topic mismatch:\n  Expected: %s\n  Got: %s",
			expected.Hex(), fastWithdrawalRequestedTopic.Hex())
	}

	t.Logf("✅ Event topic: %s", fastWithdrawalRequestedTopic.Hex())
}

func TestFastWithdrawalEvent_Struct(t *testing.T) {
	event := &FastWithdrawalEvent{
		RequestID:   [32]byte{1, 2, 3},
		User:        common.HexToAddress("0x1234567890123456789012345678901234567890"),
		Amount:      big.NewInt(1000000000000000000),
		Timestamp:   1700000000,
		BlockNumber: 12345678,
		TxHash:      common.HexToHash("0xabcd"),
		RollupType:  3,
		GameIndex:   big.NewInt(42),
		OutputRoot:  [32]byte{0xaa, 0xbb},
		L2BlockNum:  1000000,
	}

	if event.RollupType != 3 {
		t.Errorf("Unexpected rollup type: %d", event.RollupType)
	}

	if event.BlockNumber != 12345678 {
		t.Errorf("Unexpected block number: %d", event.BlockNumber)
	}

	if event.Amount.Cmp(big.NewInt(1000000000000000000)) != 0 {
		t.Error("Unexpected amount")
	}

	t.Log("✅ FastWithdrawalEvent struct works correctly")
}

func TestParseEventManual(t *testing.T) {
	// 테스트용 L1Monitor 생성 (ABI 파싱만 필요)
	monitor := &L1Monitor{}

	// 이벤트 데이터 구성 (192 bytes minimum)
	data := make([]byte, 192)

	// amount (uint256) at offset 0 - 1 ETH
	amount := common.LeftPadBytes(big.NewInt(1000000000000000000).Bytes(), 32)
	copy(data[0:32], amount)

	// rollupType (uint8) at offset 32 - 마지막 바이트만 사용
	data[63] = 3

	// gameIndex (uint256) at offset 64
	gameIndex := common.LeftPadBytes(big.NewInt(42).Bytes(), 32)
	copy(data[64:96], gameIndex)

	// outputRoot (bytes32) at offset 96
	copy(data[96:128], common.HexToHash("0xaabbccdd").Bytes())

	// l2BlockNumber (uint256) at offset 128
	l2Block := common.LeftPadBytes(big.NewInt(1000000).Bytes(), 32)
	copy(data[128:160], l2Block)

	// timestamp (uint256) at offset 160
	timestamp := common.LeftPadBytes(big.NewInt(1700000000).Bytes(), 32)
	copy(data[160:192], timestamp)

	// 로그 생성
	log := &types.Log{
		Topics: []common.Hash{
			fastWithdrawalRequestedTopic,
			common.HexToHash("0x0102030000000000000000000000000000000000000000000000000000000000"),
			common.HexToHash("0x0000000000000000000000001234567890123456789012345678901234567890"),
		},
		Data:        data,
		BlockNumber: 12345678,
		TxHash:      common.HexToHash("0xdeadbeef"),
	}

	// 기본 이벤트 생성
	event := &FastWithdrawalEvent{
		BlockNumber: log.BlockNumber,
		TxHash:      log.TxHash,
		Raw:         *log,
	}
	copy(event.RequestID[:], log.Topics[1].Bytes())
	event.User = common.BytesToAddress(log.Topics[2].Bytes())

	// 수동 파싱
	parsedEvent, err := monitor.parseEventManual(log, event)
	if err != nil {
		t.Fatalf("Failed to parse event manually: %v", err)
	}

	// 검증
	if parsedEvent.RollupType != 3 {
		t.Errorf("Unexpected rollup type: %d", parsedEvent.RollupType)
	}

	if parsedEvent.GameIndex.Cmp(big.NewInt(42)) != 0 {
		t.Errorf("Unexpected game index: %s", parsedEvent.GameIndex.String())
	}

	if parsedEvent.L2BlockNum != 1000000 {
		t.Errorf("Unexpected L2 block: %d", parsedEvent.L2BlockNum)
	}

	if parsedEvent.Timestamp != 1700000000 {
		t.Errorf("Unexpected timestamp: %d", parsedEvent.Timestamp)
	}

	t.Log("✅ Manual event parsing works correctly")
}

func TestParseEventManual_InsufficientData(t *testing.T) {
	monitor := &L1Monitor{}

	// 짧은 데이터 (192 bytes 미만)
	log := &types.Log{
		Data: make([]byte, 100), // 너무 짧음
	}

	event := &FastWithdrawalEvent{}

	_, err := monitor.parseEventManual(log, event)
	if err == nil {
		t.Error("Expected error for insufficient data")
	}

	t.Log("✅ Insufficient data error handled correctly")
}

func TestConfig_Struct(t *testing.T) {
	cfg := &Config{
		RATContract: common.HexToAddress("0x1234"),
		StartBlock:  big.NewInt(12345),
	}

	if cfg.RATContract == (common.Address{}) {
		t.Error("RAT contract should not be empty")
	}

	if cfg.StartBlock.Cmp(big.NewInt(12345)) != 0 {
		t.Error("Unexpected start block")
	}

	t.Log("✅ Config struct works correctly")
}

func TestFastWithdrawalRequestedData_Struct(t *testing.T) {
	data := FastWithdrawalRequestedData{
		Amount:        big.NewInt(1000000),
		RollupType:    3,
		GameIndex:     big.NewInt(42),
		OutputRoot:    [32]byte{1, 2, 3},
		L2BlockNumber: big.NewInt(1000000),
		Timestamp:     big.NewInt(1700000000),
	}

	if data.RollupType != 3 {
		t.Errorf("Unexpected rollup type: %d", data.RollupType)
	}

	if data.Amount.Cmp(big.NewInt(1000000)) != 0 {
		t.Error("Unexpected amount")
	}

	t.Log("✅ FastWithdrawalRequestedData struct works correctly")
}
