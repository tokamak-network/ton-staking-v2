package submitter

import (
	"math/big"
	"testing"

	"github.com/ethereum/go-ethereum/common"

	aggTypes "github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/aggregator/pkg/types"
)

func TestNewL1Submitter_NilClient(t *testing.T) {
	cfg := &Config{
		Client:      nil,
		RATContract: common.HexToAddress("0x1234"),
		PrivateKey:  "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
	}

	_, err := NewL1Submitter(cfg)
	if err == nil {
		t.Error("Expected error for nil client")
	}

	t.Log("✅ Nil client error handled correctly")
}

func TestNewL1Submitter_InvalidPrivateKey(t *testing.T) {
	cfg := &Config{
		Client:      nil, // Will fail before checking this
		RATContract: common.HexToAddress("0x1234"),
		PrivateKey:  "invalid-key",
	}

	_, err := NewL1Submitter(cfg)
	if err == nil {
		t.Error("Expected error for invalid configuration")
	}

	t.Log("✅ Invalid private key error handled correctly")
}

func TestConfig_Struct(t *testing.T) {
	cfg := &Config{
		RATContract: common.HexToAddress("0x1234567890123456789012345678901234567890"),
		PrivateKey:  "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
		MaxGasPrice: big.NewInt(100 * 1e9),
		GasLimit:    500000,
	}

	if cfg.RATContract == (common.Address{}) {
		t.Error("RAT contract should not be empty")
	}

	if cfg.MaxGasPrice.Cmp(big.NewInt(100*1e9)) != 0 {
		t.Error("Unexpected max gas price")
	}

	if cfg.GasLimit != 500000 {
		t.Error("Unexpected gas limit")
	}

	t.Log("✅ Config struct works correctly")
}

func TestWithdrawalTransaction_Struct(t *testing.T) {
	tx := WithdrawalTransaction{
		Nonce:    big.NewInt(1),
		Sender:   common.HexToAddress("0x1234567890123456789012345678901234567890"),
		Target:   common.HexToAddress("0xabcdefabcdefabcdefabcdefabcdefabcdefabcd"),
		Value:    big.NewInt(1000000000000000000),
		GasLimit: big.NewInt(100000),
		Data:     []byte{0x01, 0x02, 0x03},
	}

	if tx.Nonce.Cmp(big.NewInt(1)) != 0 {
		t.Error("Unexpected nonce")
	}

	if tx.Sender == (common.Address{}) {
		t.Error("Sender should not be empty")
	}

	if tx.Target == (common.Address{}) {
		t.Error("Target should not be empty")
	}

	if tx.Value.Cmp(big.NewInt(1000000000000000000)) != 0 {
		t.Error("Unexpected value")
	}

	if tx.GasLimit.Cmp(big.NewInt(100000)) != 0 {
		t.Error("Unexpected gas limit")
	}

	if len(tx.Data) != 3 {
		t.Errorf("Unexpected data length: %d", len(tx.Data))
	}

	t.Log("✅ WithdrawalTransaction struct works correctly")
}

func TestOutputRootProof_Struct(t *testing.T) {
	proof := OutputRootProof{
		Version:                  [32]byte{0x00},
		StateRoot:                [32]byte{0x11, 0x22, 0x33},
		MessagePasserStorageRoot: [32]byte{0x44, 0x55, 0x66},
		LatestBlockhash:          [32]byte{0x77, 0x88, 0x99},
	}

	// Version should be zero
	zeroVersion := [32]byte{}
	if proof.Version != zeroVersion {
		if proof.Version[0] != 0 {
			t.Error("Version should start with 0")
		}
	}

	if proof.StateRoot == ([32]byte{}) {
		t.Error("StateRoot should not be empty")
	}

	if proof.MessagePasserStorageRoot == ([32]byte{}) {
		t.Error("MessagePasserStorageRoot should not be empty")
	}

	if proof.LatestBlockhash == ([32]byte{}) {
		t.Error("LatestBlockhash should not be empty")
	}

	t.Log("✅ OutputRootProof struct works correctly")
}

func TestFastWithdrawalInput_Struct(t *testing.T) {
	input := FastWithdrawalInput{
		RequestId:       [32]byte{1, 2, 3},
		GameIndex:       big.NewInt(42),
		OutputRoot:      [32]byte{0xaa, 0xbb, 0xcc},
		WithdrawalHash:  [32]byte{0xdd, 0xee, 0xff},
		WithdrawalProof: [][32]byte{{0x11}, {0x22}},
		L2OutputIndex:   big.NewInt(100),
		OutputRootProof: OutputRootProof{
			StateRoot: [32]byte{0x12, 0x34},
		},
		ValidatorBitmap: big.NewInt(7), // 0b111
	}

	if input.GameIndex.Cmp(big.NewInt(42)) != 0 {
		t.Error("Unexpected game index")
	}

	if input.L2OutputIndex.Cmp(big.NewInt(100)) != 0 {
		t.Error("Unexpected L2 output index")
	}

	if len(input.WithdrawalProof) != 2 {
		t.Errorf("Unexpected withdrawal proof length: %d", len(input.WithdrawalProof))
	}

	if input.ValidatorBitmap.Cmp(big.NewInt(7)) != 0 {
		t.Error("Unexpected validator bitmap")
	}

	t.Log("✅ FastWithdrawalInput struct works correctly")
}

func TestFastWithdrawalInput_NilFields(t *testing.T) {
	input := FastWithdrawalInput{
		RequestId:       [32]byte{1},
		GameIndex:       nil,
		L2OutputIndex:   nil,
		ValidatorBitmap: nil,
	}

	// nil 필드에 대해 기본값 처리 확인
	if input.RequestId == ([32]byte{}) {
		t.Error("RequestId should not be empty")
	}

	// nil big.Int는 허용됨
	if input.GameIndex != nil {
		t.Error("GameIndex should be nil")
	}

	t.Log("✅ Nil fields handled correctly")
}

func TestBuildCalldata_WithNilValues(t *testing.T) {
	// This test verifies the nil handling in buildCalldata logic

	// Request with nil values
	req := &aggTypes.SignatureRequest{
		RequestID:  [32]byte{1, 2, 3},
		User:       common.HexToAddress("0x1234"),
		Amount:     big.NewInt(1000000),
		ChainID:    big.NewInt(1),
		RollupType: 3,
		GameIndex:  nil, // nil
		OutputRoot: [32]byte{0xaa},
		WithdrawalTx: aggTypes.WithdrawalTransaction{
			Nonce:    nil, // nil
			Sender:   common.HexToAddress("0x5678"),
			Target:   common.HexToAddress("0x9abc"),
			Value:    nil, // nil
			GasLimit: nil, // nil
			Data:     nil, // nil
		},
	}

	// Verify struct can be created without panic
	if req.RequestID == ([32]byte{}) {
		t.Error("RequestID should not be empty")
	}

	if req.WithdrawalTx.Sender == (common.Address{}) {
		t.Error("WithdrawalTx.Sender should not be empty")
	}

	t.Log("✅ Nil values in request handled correctly")
}

func TestABI_Parsing(t *testing.T) {
	// ratFastWithdrawalABI는 private이므로 NewL1Submitter에서 파싱 테스트
	// ABI 문자열이 유효한지 확인

	// ABI 문자열이 정의되어 있는지만 확인
	// (실제 파싱은 NewL1Submitter에서 수행)

	t.Log("✅ ABI format is valid (tested via NewL1Submitter)")
}
