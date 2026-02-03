package collector

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	bls "github.com/herumi/bls-eth-go-binary/bls"
	"github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/aggregator/pkg/types"
)

func init() {
	// BLS12-381 초기화 (aggregator.go와 중복되지만 안전을 위해)
	_ = bls.Init(bls.BLS12_381)
	_ = bls.SetETHmode(bls.EthModeDraft07)
}

// SignatureCollector BLS 서명 수집 및 관리
type SignatureCollector struct {
	mu sync.RWMutex

	// 진행 중인 요청들
	requests map[[32]byte]*types.RequestState

	// 완료 콜백
	onComplete func(requestID [32]byte, state *types.RequestState)
}

// NewSignatureCollector 새로운 Collector 생성
func NewSignatureCollector() *SignatureCollector {
	return &SignatureCollector{
		requests: make(map[[32]byte]*types.RequestState),
	}
}

// SetCompleteCallback 만장일치 달성 시 호출될 콜백 설정
func (sc *SignatureCollector) SetCompleteCallback(cb func([32]byte, *types.RequestState)) {
	sc.onComplete = cb
}

// StartRequest 새로운 서명 수집 시작
func (sc *SignatureCollector) StartRequest(
	req *types.SignatureRequest,
	validatorSet []common.Address,
) error {
	sc.mu.Lock()
	defer sc.mu.Unlock()

	// 이미 진행 중인지 확인
	if _, exists := sc.requests[req.RequestID]; exists {
		return fmt.Errorf("request already in progress")
	}

	state := &types.RequestState{
		Request:       req,
		Signatures:    make(map[common.Address]*types.SignatureResponse),
		ValidatorSet:  validatorSet,
		RequiredCount: len(validatorSet),
		ReceivedCount: 0,
		Completed:     false,
	}

	sc.requests[req.RequestID] = state

	fmt.Printf("📊 Started signature collection:\n")
	fmt.Printf("   RequestID: %x\n", req.RequestID[:8])
	fmt.Printf("   Validators: %d (100%% required)\n", len(validatorSet))
	fmt.Printf("   Deadline: %d\n", req.Deadline)

	return nil
}

// AddSignature 서명 추가
func (sc *SignatureCollector) AddSignature(resp *types.SignatureResponse) error {
	sc.mu.Lock()
	defer sc.mu.Unlock()

	state, exists := sc.requests[resp.RequestID]
	if !exists {
		return fmt.Errorf("request not found: %x", resp.RequestID[:8])
	}

	if state.Completed {
		return fmt.Errorf("request already completed")
	}

	// 이미 받은 서명인지 확인
	if _, exists := state.Signatures[resp.Validator]; exists {
		return fmt.Errorf("signature already received from validator %s", resp.Validator.Hex())
	}

	// Validator가 validator set에 포함되어 있는지 확인
	validValidator := false
	for _, v := range state.ValidatorSet {
		if v == resp.Validator {
			validValidator = true
			break
		}
	}

	if !validValidator {
		return fmt.Errorf("signature from unknown validator: %s", resp.Validator.Hex())
	}

	// 오프체인 BLS 서명 검증
	if err := sc.verifySignature(state.Request, resp); err != nil {
		return fmt.Errorf("invalid signature from %s: %w", resp.Validator.Hex()[:10], err)
	}

	// 서명 추가
	state.Signatures[resp.Validator] = resp
	state.ReceivedCount++

	fmt.Printf("✅ Signature received from %s (%d/%d)\n",
		resp.Validator.Hex()[:10],
		state.ReceivedCount,
		state.RequiredCount)

	// 만장일치 확인 (100%)
	if state.ReceivedCount == state.RequiredCount {
		state.Completed = true
		fmt.Printf("🎉 UNANIMOUS consensus reached! (%d/%d)\n",
			state.ReceivedCount,
			state.RequiredCount)

		// 콜백 호출
		if sc.onComplete != nil {
			go sc.onComplete(resp.RequestID, state)
		}
	}

	return nil
}

// GetState 요청 상태 조회
func (sc *SignatureCollector) GetState(requestID [32]byte) (*types.RequestState, bool) {
	sc.mu.RLock()
	defer sc.mu.RUnlock()

	state, exists := sc.requests[requestID]
	return state, exists
}

// RemoveRequest 완료된 요청 제거
func (sc *SignatureCollector) RemoveRequest(requestID [32]byte) {
	sc.mu.Lock()
	defer sc.mu.Unlock()

	delete(sc.requests, requestID)
	fmt.Printf("🗑️  Removed completed request %x\n", requestID[:8])
}

// CleanupExpired 만료된 요청 정리
func (sc *SignatureCollector) CleanupExpired() {
	sc.mu.Lock()
	defer sc.mu.Unlock()

	now := uint64(time.Now().Unix())
	expired := []([32]byte){}

	for requestID, state := range sc.requests {
		if state.Request.Deadline < now && !state.Completed {
			expired = append(expired, requestID)
		}
	}

	for _, requestID := range expired {
		fmt.Printf("⏰ Request expired: %x\n", requestID[:8])
		delete(sc.requests, requestID)
	}

	if len(expired) > 0 {
		fmt.Printf("🗑️  Cleaned up %d expired requests\n", len(expired))
	}
}

// StartCleanupLoop 주기적 정리 루프
func (sc *SignatureCollector) StartCleanupLoop(ctx context.Context, interval time.Duration) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			sc.CleanupExpired()
		}
	}
}

// verifySignature 오프체인 BLS 서명 검증
func (sc *SignatureCollector) verifySignature(req *types.SignatureRequest, resp *types.SignatureResponse) error {
	// 1. 공개키 파싱
	var pubKey bls.PublicKey
	if err := pubKey.Deserialize(resp.PublicKey); err != nil {
		return fmt.Errorf("failed to deserialize public key: %w", err)
	}

	// 2. 서명 파싱
	var sig bls.Sign
	if err := sig.Deserialize(resp.Signature); err != nil {
		return fmt.Errorf("failed to deserialize signature: %w", err)
	}

	// 3. 메시지 재구성 (Solidity와 동일한 방식)
	message := buildSigningMessage(req)

	// 4. BLS 검증
	if !sig.VerifyByte(&pubKey, message) {
		return fmt.Errorf("BLS signature verification failed")
	}

	return nil
}

// buildSigningMessage 서명 메시지 생성 (Validator와 동일)
func buildSigningMessage(req *types.SignatureRequest) []byte {
	return crypto.Keccak256(
		[]byte("TOKAMAK_FAST_WITHDRAWAL"),
		req.RequestID[:],
		req.User.Bytes(),
		common.LeftPadBytes(req.Amount.Bytes(), 32),
		common.LeftPadBytes(req.ChainID.Bytes(), 32),
	)
}

// Stats 현재 상태 통계
func (sc *SignatureCollector) Stats() map[string]int {
	sc.mu.RLock()
	defer sc.mu.RUnlock()

	pending := 0
	completed := 0

	for _, state := range sc.requests {
		if state.Completed {
			completed++
		} else {
			pending++
		}
	}

	return map[string]int{
		"pending":   pending,
		"completed": completed,
		"total":     len(sc.requests),
	}
}
