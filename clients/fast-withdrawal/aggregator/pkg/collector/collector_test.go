package collector

import (
	"context"
	"math/big"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	bls "github.com/herumi/bls-eth-go-binary/bls"
	"github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/aggregator/pkg/types"
)

func init() {
	// BLS 초기화
	_ = bls.Init(bls.BLS12_381)
	_ = bls.SetETHmode(bls.EthModeDraft07)
}

// 테스트용 BLS 서명 생성 헬퍼
func generateTestSignature(req *types.SignatureRequest) ([]byte, []byte) {
	// BLS 키 생성
	var secKey bls.SecretKey
	secKey.SetByCSPRNG()

	pubKey := secKey.GetPublicKey()

	// 메시지 생성 (collector.go의 buildSigningMessage와 동일)
	message := crypto.Keccak256(
		[]byte("TOKAMAK_FAST_WITHDRAWAL"),
		req.RequestID[:],
		req.User.Bytes(),
		common.LeftPadBytes(req.Amount.Bytes(), 32),
		common.LeftPadBytes(req.ChainID.Bytes(), 32),
	)

	// 서명 생성
	sig := secKey.SignByte(message)

	return sig.Serialize(), pubKey.Serialize()
}

func TestNewSignatureCollector(t *testing.T) {
	collector := NewSignatureCollector()
	if collector == nil {
		t.Fatal("Collector is nil")
	}

	stats := collector.Stats()
	if stats["total"] != 0 {
		t.Errorf("Expected 0 total, got %d", stats["total"])
	}

	t.Log("✅ Collector created successfully")
}

func TestStartRequest(t *testing.T) {
	collector := NewSignatureCollector()

	testReq := &types.SignatureRequest{
		RequestID: [32]byte{1, 2, 3},
		User:      common.HexToAddress("0x1234567890123456789012345678901234567890"),
		Amount:    big.NewInt(1000000),
		ChainID:   big.NewInt(1),
		Deadline:  uint64(time.Now().Add(10 * time.Minute).Unix()),
	}

	validators := []common.Address{
		common.HexToAddress("0xVALIDATOR1"),
		common.HexToAddress("0xVALIDATOR2"),
		common.HexToAddress("0xVALIDATOR3"),
	}

	err := collector.StartRequest(testReq, validators)
	if err != nil {
		t.Fatalf("Failed to start request: %v", err)
	}

	state, exists := collector.GetState(testReq.RequestID)
	if !exists {
		t.Fatal("Request not found")
	}

	if state.RequiredCount != 3 {
		t.Errorf("Expected 3 validators, got %d", state.RequiredCount)
	}

	t.Log("✅ Request started successfully")
}

func TestAddSignature_Unanimous(t *testing.T) {
	collector := NewSignatureCollector()

	testReq := &types.SignatureRequest{
		RequestID: [32]byte{1, 2, 3},
		User:      common.HexToAddress("0x1234567890123456789012345678901234567890"),
		Amount:    big.NewInt(1000000),
		ChainID:   big.NewInt(1),
		Deadline:  uint64(time.Now().Add(10 * time.Minute).Unix()),
	}

	validators := []common.Address{
		common.HexToAddress("0x1111111111111111111111111111111111111111"),
		common.HexToAddress("0x2222222222222222222222222222222222222222"),
		common.HexToAddress("0x3333333333333333333333333333333333333333"),
	}

	err := collector.StartRequest(testReq, validators)
	if err != nil {
		t.Fatalf("Failed to start request: %v", err)
	}

	// 만장일치 콜백 설정
	completed := false
	collector.SetCompleteCallback(func(requestID [32]byte, state *types.RequestState) {
		completed = true
		t.Logf("🎉 Callback triggered for request %x", requestID[:8])
	})

	// 유효한 BLS 서명 생성 및 추가
	for i, validator := range validators {
		// 실제 BLS 서명 생성
		sig, pubKey := generateTestSignature(testReq)

		resp := &types.SignatureResponse{
			RequestID: testReq.RequestID,
			Validator: validator,
			Signature: sig,    // 유효한 BLS 서명
			PublicKey: pubKey, // 유효한 BLS 공개키
			Timestamp: uint64(time.Now().Unix()),
		}

		err := collector.AddSignature(resp)
		if err != nil {
			t.Fatalf("Failed to add signature %d: %v", i, err)
		}
	}

	// 완료 확인
	time.Sleep(100 * time.Millisecond) // 콜백 대기

	state, _ := collector.GetState(testReq.RequestID)
	if !state.Completed {
		t.Error("Request not marked as completed")
	}

	if state.ReceivedCount != 3 {
		t.Errorf("Expected 3 signatures, got %d", state.ReceivedCount)
	}

	if !completed {
		t.Error("Callback not triggered")
	}

	t.Log("✅ Unanimous consensus reached")
}

func TestCleanupExpired(t *testing.T) {
	collector := NewSignatureCollector()

	// 만료된 요청 추가
	expiredReq := &types.SignatureRequest{
		RequestID: [32]byte{1, 2, 3},
		User:      common.HexToAddress("0x1234567890123456789012345678901234567890"),
		Amount:    big.NewInt(1000000),
		ChainID:   big.NewInt(1),
		Deadline:  uint64(time.Now().Add(-1 * time.Hour).Unix()), // 과거
	}

	validators := []common.Address{
		common.HexToAddress("0xVALIDATOR1"),
	}

	err := collector.StartRequest(expiredReq, validators)
	if err != nil {
		t.Fatalf("Failed to start request: %v", err)
	}

	// 정리 실행
	collector.CleanupExpired()

	// 제거 확인
	_, exists := collector.GetState(expiredReq.RequestID)
	if exists {
		t.Error("Expired request not cleaned up")
	}

	t.Log("✅ Expired requests cleaned up")
}

func TestStartCleanupLoop(t *testing.T) {
	collector := NewSignatureCollector()

	ctx, cancel := context.WithTimeout(context.Background(), 1*time.Second)
	defer cancel()

	// Cleanup loop 시작
	go collector.StartCleanupLoop(ctx, 200*time.Millisecond)

	// 테스트 완료 대기
	<-ctx.Done()

	t.Log("✅ Cleanup loop test completed")
}
