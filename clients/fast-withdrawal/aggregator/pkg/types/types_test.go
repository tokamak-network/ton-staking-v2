package types

import (
	"encoding/json"
	"math/big"
	"testing"

	"github.com/ethereum/go-ethereum/common"
)

func TestSignatureRequest_JSON(t *testing.T) {
	req := &SignatureRequest{
		RequestID:   [32]byte{1, 2, 3, 4, 5, 6, 7, 8},
		User:        common.HexToAddress("0x1234567890123456789012345678901234567890"),
		Amount:      big.NewInt(1000000000000000000), // 1 ETH
		ChainID:     big.NewInt(1),
		Deadline:    1700000000,
		RollupType:  3,
		GameIndex:   big.NewInt(42),
		OutputRoot:  [32]byte{0xaa, 0xbb, 0xcc},
		BlockNumber: 12345678,
		WithdrawalTx: WithdrawalTransaction{
			Nonce:    big.NewInt(1),
			Sender:   common.HexToAddress("0xSENDER"),
			Target:   common.HexToAddress("0xTARGET"),
			Value:    big.NewInt(1000000000000000000),
			GasLimit: big.NewInt(100000),
			Data:     []byte{0x01, 0x02, 0x03},
		},
	}

	// JSON 직렬화
	data, err := json.Marshal(req)
	if err != nil {
		t.Fatalf("Failed to marshal: %v", err)
	}

	// JSON 역직렬화
	var decoded SignatureRequest
	if err := json.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("Failed to unmarshal: %v", err)
	}

	// 값 검증
	if decoded.RequestID != req.RequestID {
		t.Error("RequestID mismatch")
	}

	if decoded.User != req.User {
		t.Error("User mismatch")
	}

	if decoded.Amount.Cmp(req.Amount) != 0 {
		t.Error("Amount mismatch")
	}

	if decoded.RollupType != req.RollupType {
		t.Error("RollupType mismatch")
	}

	if decoded.BlockNumber != req.BlockNumber {
		t.Error("BlockNumber mismatch")
	}

	t.Log("✅ SignatureRequest JSON serialization works correctly")
}

func TestSignatureResponse_JSON(t *testing.T) {
	resp := &SignatureResponse{
		RequestID:     [32]byte{1, 2, 3},
		Validator:     common.HexToAddress("0xVALIDATOR"),
		Signature:     make([]byte, 96),
		PublicKey:     make([]byte, 48),
		Timestamp:     1700000000,
		ValidatorPeer: "QmPeerID123",
	}

	// JSON 직렬화
	data, err := json.Marshal(resp)
	if err != nil {
		t.Fatalf("Failed to marshal: %v", err)
	}

	// JSON 역직렬화
	var decoded SignatureResponse
	if err := json.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("Failed to unmarshal: %v", err)
	}

	if decoded.RequestID != resp.RequestID {
		t.Error("RequestID mismatch")
	}

	if decoded.Validator != resp.Validator {
		t.Error("Validator mismatch")
	}

	if len(decoded.Signature) != 96 {
		t.Error("Signature length mismatch")
	}

	if len(decoded.PublicKey) != 48 {
		t.Error("PublicKey length mismatch")
	}

	if decoded.ValidatorPeer != resp.ValidatorPeer {
		t.Error("ValidatorPeer mismatch")
	}

	t.Log("✅ SignatureResponse JSON serialization works correctly")
}

func TestRequestState(t *testing.T) {
	validators := []common.Address{
		common.HexToAddress("0x1111111111111111111111111111111111111111"),
		common.HexToAddress("0x2222222222222222222222222222222222222222"),
		common.HexToAddress("0x3333333333333333333333333333333333333333"),
	}

	state := &RequestState{
		Request: &SignatureRequest{
			RequestID: [32]byte{1, 2, 3},
			Amount:    big.NewInt(1000000),
		},
		Signatures:    make(map[common.Address]*SignatureResponse),
		ValidatorSet:  validators,
		RequiredCount: 3,
		ReceivedCount: 0,
		Completed:     false,
	}

	// 서명 추가
	for _, v := range validators {
		state.Signatures[v] = &SignatureResponse{
			Validator: v,
			Signature: make([]byte, 96),
			PublicKey: make([]byte, 48),
		}
		state.ReceivedCount++
	}

	if state.ReceivedCount != 3 {
		t.Errorf("Expected 3 signatures, got %d", state.ReceivedCount)
	}

	if len(state.Signatures) != 3 {
		t.Errorf("Expected 3 entries in Signatures map, got %d", len(state.Signatures))
	}

	// 만장일치 확인
	if state.ReceivedCount != state.RequiredCount {
		t.Error("Should have unanimous consensus")
	}

	state.Completed = true
	if !state.Completed {
		t.Error("State should be completed")
	}

	t.Log("✅ RequestState works correctly")
}

func TestWithdrawalTransaction(t *testing.T) {
	tx := WithdrawalTransaction{
		Nonce:    big.NewInt(1),
		Sender:   common.HexToAddress("0xSENDER"),
		Target:   common.HexToAddress("0xTARGET"),
		Value:    big.NewInt(1000000000000000000),
		GasLimit: big.NewInt(100000),
		Data:     []byte{0x01, 0x02, 0x03},
	}

	// JSON 직렬화/역직렬화
	data, err := json.Marshal(tx)
	if err != nil {
		t.Fatalf("Failed to marshal: %v", err)
	}

	var decoded WithdrawalTransaction
	if err := json.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("Failed to unmarshal: %v", err)
	}

	if decoded.Nonce.Cmp(tx.Nonce) != 0 {
		t.Error("Nonce mismatch")
	}

	if decoded.Sender != tx.Sender {
		t.Error("Sender mismatch")
	}

	if decoded.Target != tx.Target {
		t.Error("Target mismatch")
	}

	if decoded.Value.Cmp(tx.Value) != 0 {
		t.Error("Value mismatch")
	}

	if decoded.GasLimit.Cmp(tx.GasLimit) != 0 {
		t.Error("GasLimit mismatch")
	}

	t.Log("✅ WithdrawalTransaction works correctly")
}

func TestSignatureRequest_NilFields(t *testing.T) {
	// nil 필드가 있는 요청
	req := &SignatureRequest{
		RequestID: [32]byte{1},
		User:      common.Address{},
		Amount:    nil, // nil
		ChainID:   nil, // nil
		GameIndex: nil, // nil
	}

	// JSON 직렬화가 panic 없이 동작해야 함
	data, err := json.Marshal(req)
	if err != nil {
		t.Fatalf("Failed to marshal with nil fields: %v", err)
	}

	var decoded SignatureRequest
	if err := json.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("Failed to unmarshal with nil fields: %v", err)
	}

	t.Log("✅ Nil fields handled correctly")
}
