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
		[]byte("FastWithdrawalRequested(bytes32,address,uint256,uint256,uint256,uint256,bytes32,address)"),
	)

	if fastWithdrawalRequestedTopic != expected {
		t.Errorf("Topic mismatch:\n  Expected: %s\n  Got: %s",
			expected.Hex(), fastWithdrawalRequestedTopic.Hex())
	}

	t.Logf("✅ Event topic: %s", fastWithdrawalRequestedTopic.Hex())
}

func TestFastWithdrawalEvent_Struct(t *testing.T) {
	tenTON := new(big.Int).Mul(big.NewInt(10), big.NewInt(1e18))
	event := &FastWithdrawalEvent{
		WithdrawalHash: [32]byte{1, 2, 3},
		User:           common.HexToAddress("0x1234567890123456789012345678901234567890"),
		Amount:         big.NewInt(1e17), // 0.1 ETH
		Fee:            tenTON,
		Deadline:       1700000000,
		GameIndex:      big.NewInt(8),
		OutputRoot:     [32]byte{0xaa, 0xbb},
		SystemConfig:   common.HexToAddress("0xecf558904405f7b662892ab7bb3544bea3beaf20"),
		BlockNumber:    12345678,
		TxHash:         common.HexToHash("0xabcd"),
	}

	if event.BlockNumber != 12345678 {
		t.Errorf("Unexpected block number: %d", event.BlockNumber)
	}

	if event.Amount.Cmp(big.NewInt(1e17)) != 0 {
		t.Error("Unexpected amount")
	}

	if event.Fee.Cmp(tenTON) != 0 {
		t.Error("Unexpected fee")
	}

	if event.GameIndex.Cmp(big.NewInt(8)) != 0 {
		t.Errorf("Unexpected game index: %s", event.GameIndex.String())
	}

	t.Log("✅ FastWithdrawalEvent struct works correctly")
}

func TestParseEventManual(t *testing.T) {
	monitor := &L1Monitor{}

	// 이벤트 데이터 구성 (192 bytes = 6 * 32)
	data := make([]byte, 192)

	// amount (uint256) at offset 0 - 0.1 ETH
	amount := common.LeftPadBytes(big.NewInt(1e17).Bytes(), 32)
	copy(data[0:32], amount)

	// fee (uint256) at offset 32 - 10 TON
	fee := common.LeftPadBytes(new(big.Int).Mul(big.NewInt(10), big.NewInt(1e18)).Bytes(), 32)
	copy(data[32:64], fee)

	// deadline (uint256) at offset 64
	deadline := common.LeftPadBytes(big.NewInt(1700000000).Bytes(), 32)
	copy(data[64:96], deadline)

	// gameIndex (uint256) at offset 96
	gameIdx := common.LeftPadBytes(big.NewInt(8).Bytes(), 32)
	copy(data[96:128], gameIdx)

	// outputRoot (bytes32) at offset 128
	copy(data[128:160], common.HexToHash("0xaabbccdd").Bytes())

	// sysConfig (address) at offset 160
	sysConfig := common.LeftPadBytes(common.HexToAddress("0xecf558904405f7b662892ab7bb3544bea3beaf20").Bytes(), 32)
	copy(data[160:192], sysConfig)

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
	copy(event.WithdrawalHash[:], log.Topics[1].Bytes())
	event.User = common.BytesToAddress(log.Topics[2].Bytes())

	// 수동 파싱
	parsedEvent, err := monitor.parseEventManual(log, event)
	if err != nil {
		t.Fatalf("Failed to parse event manually: %v", err)
	}

	// 검증
	if parsedEvent.Amount.Cmp(big.NewInt(1e17)) != 0 {
		t.Errorf("Unexpected amount: %s", parsedEvent.Amount.String())
	}

	expectedFee := new(big.Int).Mul(big.NewInt(10), big.NewInt(1e18))
	if parsedEvent.Fee.Cmp(expectedFee) != 0 {
		t.Errorf("Unexpected fee: %s", parsedEvent.Fee.String())
	}

	if parsedEvent.Deadline != 1700000000 {
		t.Errorf("Unexpected deadline: %d", parsedEvent.Deadline)
	}

	if parsedEvent.GameIndex.Cmp(big.NewInt(8)) != 0 {
		t.Errorf("Unexpected game index: %s", parsedEvent.GameIndex.String())
	}

	expectedSysConfig := common.HexToAddress("0xecf558904405f7b662892ab7bb3544bea3beaf20")
	if parsedEvent.SystemConfig != expectedSysConfig {
		t.Errorf("Unexpected sysConfig: %s", parsedEvent.SystemConfig.Hex())
	}

	t.Log("✅ Manual event parsing works correctly")
}

func TestParseEventManual_InsufficientData(t *testing.T) {
	monitor := &L1Monitor{}

	log := &types.Log{
		Data: make([]byte, 160), // 192 bytes 미만
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
	tenTON := new(big.Int).Mul(big.NewInt(10), big.NewInt(1e18))
	data := FastWithdrawalRequestedData{
		Amount:       big.NewInt(1e17),
		Fee:          tenTON,
		Deadline:     big.NewInt(1700000000),
		GameIndex:    big.NewInt(8),
		OutputRoot:   [32]byte{1, 2, 3},
		SystemConfig: common.HexToAddress("0xecf558904405f7b662892ab7bb3544bea3beaf20"),
	}

	if data.Amount.Cmp(big.NewInt(1e17)) != 0 {
		t.Error("Unexpected amount")
	}

	if data.Fee.Cmp(tenTON) != 0 {
		t.Error("Unexpected fee")
	}

	if data.GameIndex.Cmp(big.NewInt(8)) != 0 {
		t.Error("Unexpected game index")
	}

	t.Log("✅ FastWithdrawalRequestedData struct works correctly")
}
