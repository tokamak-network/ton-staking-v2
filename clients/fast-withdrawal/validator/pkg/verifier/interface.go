package verifier

import (
	"context"

	"github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/validator/pkg/p2p"
)

// WithdrawalVerifier 출금 검증 인터페이스
// Rollup type별로 다른 구현 제공
type WithdrawalVerifier interface {
	// ValidateWithdrawal 출금 요청 검증
	ValidateWithdrawal(ctx context.Context, req *p2p.SignatureRequest) error
}
