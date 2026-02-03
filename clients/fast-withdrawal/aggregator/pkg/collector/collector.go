package collector

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/aggregator/pkg/types"
)

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
