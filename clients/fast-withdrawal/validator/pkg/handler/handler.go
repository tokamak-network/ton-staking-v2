package handler

import (
	"context"
	"fmt"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"

	"github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/validator/pkg/p2p"
	"github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/validator/pkg/signer"
	"github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/validator/pkg/verifier"
)

// RequestHandler SignatureRequest를 처리하고 서명 생성
type RequestHandler struct {
	signer   *signer.BLSSigner
	verifier verifier.WithdrawalVerifier
	l1Client *ethclient.Client

	validatorAddr common.Address
}

// Config RequestHandler 설정
type Config struct {
	BLSSigner     *signer.BLSSigner
	Verifier      verifier.WithdrawalVerifier
	L1Client      *ethclient.Client
	ValidatorAddr common.Address
}

// NewRequestHandler 새로운 RequestHandler 생성
func NewRequestHandler(cfg *Config) (*RequestHandler, error) {
	if cfg.BLSSigner == nil {
		return nil, fmt.Errorf("BLS signer is required")
	}
	if cfg.Verifier == nil {
		return nil, fmt.Errorf("verifier is required")
	}
	// L1Client는 선택적 (일부 검증에서만 필요)

	return &RequestHandler{
		signer:        cfg.BLSSigner,
		verifier:      cfg.Verifier,
		l1Client:      cfg.L1Client,
		validatorAddr: cfg.ValidatorAddr,
	}, nil
}

// HandleRequest SignatureRequest 처리
func (h *RequestHandler) HandleRequest(ctx context.Context, req *p2p.SignatureRequest) (*p2p.SignatureResponse, error) {
	startTime := time.Now()

	fmt.Printf("\n📥 Received withdrawal request:\n")
	fmt.Printf("   RequestID: %x\n", req.RequestID[:8])
	fmt.Printf("   User: %s\n", req.User.Hex())
	fmt.Printf("   Amount: %s\n", req.Amount.String())
	fmt.Printf("   RollupType: %d\n", req.RollupType)
	fmt.Printf("   BlockNumber: %d\n", req.BlockNumber)

	// 1. 기본 검증
	if err := h.validateBasicRequirements(req); err != nil {
		fmt.Printf("❌ Basic validation failed: %v\n", err)
		return nil, fmt.Errorf("basic validation failed: %w", err)
	}

	// 2. Deadline 체크
	if time.Now().Unix() > int64(req.Deadline) {
		fmt.Printf("❌ Request expired (deadline: %d)\n", req.Deadline)
		return nil, fmt.Errorf("request expired")
	}

	// 3. Rollup type별 검증
	if err := h.verifier.ValidateWithdrawal(ctx, req); err != nil {
		fmt.Printf("❌ Withdrawal validation failed: %v\n", err)
		return nil, fmt.Errorf("withdrawal validation failed: %w", err)
	}

	fmt.Printf("✅ Withdrawal validated successfully\n")

	// 4. BLS 서명 생성
	message := h.buildSigningMessage(req)
	signature, err := h.signer.Sign(message)
	if err != nil {
		fmt.Printf("❌ Failed to sign: %v\n", err)
		return nil, fmt.Errorf("failed to sign: %w", err)
	}

	// 5. SignatureResponse 생성
	resp := &p2p.SignatureResponse{
		RequestID: req.RequestID,
		Validator: h.validatorAddr,
		Signature: signature,
		PublicKey: h.signer.PublicKey(),
		Timestamp: uint64(time.Now().Unix()),
	}

	elapsed := time.Since(startTime)
	fmt.Printf("✅ Signature generated in %v\n", elapsed)
	fmt.Printf("   Signature: %x...\n", signature[:16])

	return resp, nil
}

// validateBasicRequirements 기본 요구사항 검증
func (h *RequestHandler) validateBasicRequirements(req *p2p.SignatureRequest) error {
	// RequestID 검증
	if req.RequestID == [32]byte{} {
		return fmt.Errorf("invalid request ID")
	}

	// User address 검증
	if req.User == (common.Address{}) {
		return fmt.Errorf("invalid user address")
	}

	// Amount 검증
	if req.Amount == nil || req.Amount.Sign() <= 0 {
		return fmt.Errorf("invalid amount")
	}

	// ChainID 검증
	if req.ChainID == nil || req.ChainID.Sign() <= 0 {
		return fmt.Errorf("invalid chain ID")
	}

	// RollupType 검증 (현재는 Type 3만 지원)
	if req.RollupType != 3 {
		return fmt.Errorf("unsupported rollup type: %d (only type 3 supported)", req.RollupType)
	}

	return nil
}

// buildSigningMessage 서명할 메시지 생성
// Solidity의 keccak256(abi.encodePacked(...))와 동일
func (h *RequestHandler) buildSigningMessage(req *p2p.SignatureRequest) []byte {
	// Solidity에서의 메시지 생성:
	// bytes32 messageHash = keccak256(abi.encodePacked(
	//     "TOKAMAK_FAST_WITHDRAWAL",
	//     requestId,
	//     request.user,
	//     request.amount,
	//     block.chainid
	// ));

	message := crypto.Keccak256(
		[]byte("TOKAMAK_FAST_WITHDRAWAL"),
		req.RequestID[:],
		req.User.Bytes(),
		common.LeftPadBytes(req.Amount.Bytes(), 32),
		common.LeftPadBytes(req.ChainID.Bytes(), 32),
	)

	return message
}

// VerifySignature 서명 검증 (테스트용)
func (h *RequestHandler) VerifySignature(req *p2p.SignatureRequest, resp *p2p.SignatureResponse) bool {
	message := h.buildSigningMessage(req)
	return signer.VerifySignature(message, resp.Signature, resp.PublicKey)
}
