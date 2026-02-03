package handler

import (
	"context"
	"math/big"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/validator/pkg/p2p"
	"github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/validator/pkg/signer"
	"github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/validator/pkg/verifier"
)

func TestNewRequestHandler(t *testing.T) {
	blsSigner, err := signer.GenerateKey()
	if err != nil {
		t.Fatalf("Failed to generate BLS key: %v", err)
	}

	mockVerifier := verifier.NewMockVerifier(false)

	handler, err := NewRequestHandler(&Config{
		BLSSigner:     blsSigner,
		Verifier:      mockVerifier,
		L1Client:      nil, // Mock이므로 불필요
		ValidatorAddr: common.HexToAddress("0x1234567890123456789012345678901234567890"),
	})

	if err != nil {
		t.Fatalf("Failed to create handler: %v", err)
	}

	if handler == nil {
		t.Fatal("Handler is nil")
	}

	t.Log("✅ RequestHandler created successfully")
}

func TestHandleRequest_Success(t *testing.T) {
	ctx := context.Background()

	// BLS Signer 생성
	blsSigner, err := signer.GenerateKey()
	if err != nil {
		t.Fatalf("Failed to generate BLS key: %v", err)
	}

	// Mock Verifier (항상 성공)
	mockVerifier := verifier.NewMockVerifier(false)

	// Handler 생성
	handler, err := NewRequestHandler(&Config{
		BLSSigner:     blsSigner,
		Verifier:      mockVerifier,
		L1Client:      nil,
		ValidatorAddr: common.HexToAddress("0x1111111111111111111111111111111111111111"),
	})
	if err != nil {
		t.Fatalf("Failed to create handler: %v", err)
	}

	// SignatureRequest 생성
	testReq := &p2p.SignatureRequest{
		RequestID:   [32]byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16},
		User:        common.HexToAddress("0x1234567890123456789012345678901234567890"),
		Amount:      big.NewInt(1000000),
		ChainID:     big.NewInt(1),
		Deadline:    uint64(time.Now().Add(10 * time.Minute).Unix()),
		RollupType:  3,
		GameIndex:   big.NewInt(100),
		BlockNumber: 12345,
	}

	// Request 처리
	resp, err := handler.HandleRequest(ctx, testReq)
	if err != nil {
		t.Fatalf("Failed to handle request: %v", err)
	}

	// Response 검증
	if resp.RequestID != testReq.RequestID {
		t.Errorf("RequestID mismatch")
	}

	if resp.Validator != handler.validatorAddr {
		t.Errorf("Validator address mismatch")
	}

	if len(resp.Signature) != 96 {
		t.Errorf("Invalid signature length: %d", len(resp.Signature))
	}

	if len(resp.PublicKey) != 48 {
		t.Errorf("Invalid public key length: %d", len(resp.PublicKey))
	}

	// 서명 검증
	if !handler.VerifySignature(testReq, resp) {
		t.Error("Signature verification failed")
	}

	t.Log("✅ Request handled successfully")
	t.Logf("   RequestID: %x", resp.RequestID[:8])
	t.Logf("   Validator: %s", resp.Validator.Hex())
	t.Logf("   Signature: %x...", resp.Signature[:16])
}

func TestHandleRequest_ValidationFailed(t *testing.T) {
	ctx := context.Background()

	blsSigner, err := signer.GenerateKey()
	if err != nil {
		t.Fatalf("Failed to generate BLS key: %v", err)
	}

	// Mock Verifier (항상 실패)
	mockVerifier := verifier.NewMockVerifier(true)
	mockVerifier.FailReason = "test validation failed"

	handler, err := NewRequestHandler(&Config{
		BLSSigner:     blsSigner,
		Verifier:      mockVerifier,
		L1Client:      nil,
		ValidatorAddr: common.HexToAddress("0x1111111111111111111111111111111111111111"),
	})
	if err != nil {
		t.Fatalf("Failed to create handler: %v", err)
	}

	testReq := &p2p.SignatureRequest{
		RequestID:   [32]byte{1, 2, 3},
		User:        common.HexToAddress("0xUSER"),
		Amount:      big.NewInt(1000000),
		ChainID:     big.NewInt(1),
		Deadline:    uint64(time.Now().Add(10 * time.Minute).Unix()),
		RollupType:  3,
		GameIndex:   big.NewInt(100),
		BlockNumber: 12345,
	}

	// Request 처리 (실패 예상)
	_, err = handler.HandleRequest(ctx, testReq)
	if err == nil {
		t.Error("Expected error but got nil")
	}

	t.Logf("✅ Validation correctly failed: %v", err)
}

func TestHandleRequest_Expired(t *testing.T) {
	ctx := context.Background()

	blsSigner, err := signer.GenerateKey()
	if err != nil {
		t.Fatalf("Failed to generate BLS key: %v", err)
	}

	mockVerifier := verifier.NewMockVerifier(false)

	handler, err := NewRequestHandler(&Config{
		BLSSigner:     blsSigner,
		Verifier:      mockVerifier,
		L1Client:      nil,
		ValidatorAddr: common.HexToAddress("0x1111111111111111111111111111111111111111"),
	})
	if err != nil {
		t.Fatalf("Failed to create handler: %v", err)
	}

	// 이미 만료된 요청
	testReq := &p2p.SignatureRequest{
		RequestID:   [32]byte{1, 2, 3},
		User:        common.HexToAddress("0xUSER"),
		Amount:      big.NewInt(1000000),
		ChainID:     big.NewInt(1),
		Deadline:    uint64(time.Now().Add(-1 * time.Hour).Unix()), // 과거
		RollupType:  3,
		GameIndex:   big.NewInt(100),
		BlockNumber: 12345,
	}

	// Request 처리 (실패 예상)
	_, err = handler.HandleRequest(ctx, testReq)
	if err == nil {
		t.Error("Expected error for expired request but got nil")
	}

	t.Logf("✅ Expired request correctly rejected: %v", err)
}

func TestHandleRequest_InvalidRollupType(t *testing.T) {
	ctx := context.Background()

	blsSigner, err := signer.GenerateKey()
	if err != nil {
		t.Fatalf("Failed to generate BLS key: %v", err)
	}

	mockVerifier := verifier.NewMockVerifier(false)

	handler, err := NewRequestHandler(&Config{
		BLSSigner:     blsSigner,
		Verifier:      mockVerifier,
		L1Client:      nil,
		ValidatorAddr: common.HexToAddress("0x1111111111111111111111111111111111111111"),
	})
	if err != nil {
		t.Fatalf("Failed to create handler: %v", err)
	}

	// 지원하지 않는 rollup type
	testReq := &p2p.SignatureRequest{
		RequestID:   [32]byte{1, 2, 3},
		User:        common.HexToAddress("0xUSER"),
		Amount:      big.NewInt(1000000),
		ChainID:     big.NewInt(1),
		Deadline:    uint64(time.Now().Add(10 * time.Minute).Unix()),
		RollupType:  99, // 지원하지 않음
		GameIndex:   big.NewInt(100),
		BlockNumber: 12345,
	}

	// Request 처리 (실패 예상)
	_, err = handler.HandleRequest(ctx, testReq)
	if err == nil {
		t.Error("Expected error for invalid rollup type but got nil")
	}

	t.Logf("✅ Invalid rollup type correctly rejected: %v", err)
}
