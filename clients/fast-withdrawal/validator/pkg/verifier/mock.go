package verifier

import (
	"context"
	"fmt"

	"github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/validator/pkg/p2p"
)

// MockVerifier 테스트용 Mock Verifier
type MockVerifier struct {
	ShouldFail bool
	FailReason string
}

// NewMockVerifier Mock Verifier 생성
func NewMockVerifier(shouldFail bool) *MockVerifier {
	return &MockVerifier{
		ShouldFail: shouldFail,
		FailReason: "mock validation failed",
	}
}

// ValidateWithdrawal Mock 검증
func (v *MockVerifier) ValidateWithdrawal(ctx context.Context, req *p2p.SignatureRequest) error {
	if v.ShouldFail {
		return fmt.Errorf(v.FailReason)
	}

	// Mock 성공
	return nil
}
