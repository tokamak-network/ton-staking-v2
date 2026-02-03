package collector

import (
	"fmt"

	bls "github.com/herumi/bls-eth-go-binary/bls"
	"github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/aggregator/pkg/types"
)

func init() {
	// BLS12-381 초기화
	_ = bls.Init(bls.BLS12_381)
	_ = bls.SetETHmode(bls.EthModeDraft07)
}

// BLSAggregator BLS 서명 집약
type BLSAggregator struct{}

// NewBLSAggregator 새로운 Aggregator 생성
func NewBLSAggregator() *BLSAggregator {
	return &BLSAggregator{}
}

// AggregateSignatures BLS 서명들을 집약
// returns: (aggregatedSignature, validatorBitmap, error)
func (ba *BLSAggregator) AggregateSignatures(
	state *types.RequestState,
) ([]byte, uint256, error) {
	if len(state.Signatures) == 0 {
		return nil, 0, fmt.Errorf("no signatures to aggregate")
	}

	if state.ReceivedCount != state.RequiredCount {
		return nil, 0, fmt.Errorf("not unanimous: %d/%d",
			state.ReceivedCount,
			state.RequiredCount)
	}

	fmt.Printf("🔄 Aggregating %d BLS signatures...\n", len(state.Signatures))

	// 1. Validator 순서대로 서명 수집
	signatures := make([]*bls.Sign, 0, len(state.ValidatorSet))
	bitmap := uint64(0)

	for i, validator := range state.ValidatorSet {
		resp, exists := state.Signatures[validator]
		if !exists {
			return nil, 0, fmt.Errorf("missing signature from validator %s", validator.Hex())
		}

		// BLS 서명 파싱
		var sig bls.Sign
		if err := sig.Deserialize(resp.Signature); err != nil {
			return nil, 0, fmt.Errorf("failed to deserialize signature: %w", err)
		}

		signatures = append(signatures, &sig)

		// Bitmap 설정 (i번째 비트를 1로)
		bitmap |= (1 << uint(i))
	}

	// 2. BLS 서명 집약 (G2 addition)
	var aggregatedSig bls.Sign
	aggregatedSig.Add(signatures[0])

	for i := 1; i < len(signatures); i++ {
		aggregatedSig.Add(signatures[i])
	}

	// 3. 직렬화
	aggregatedBytes := aggregatedSig.Serialize()

	fmt.Printf("✅ Signatures aggregated successfully\n")
	fmt.Printf("   Aggregated signature: %x...\n", aggregatedBytes[:16])
	fmt.Printf("   Validator bitmap: 0b%b (%d)\n", bitmap, bitmap)

	return aggregatedBytes, uint256(bitmap), nil
}

// VerifyAggregatedSignature 집약된 서명 검증 (테스트용)
func (ba *BLSAggregator) VerifyAggregatedSignature(
	message []byte,
	aggregatedSig []byte,
	publicKeys [][]byte,
) bool {
	if len(publicKeys) == 0 {
		return false
	}

	// 집약된 서명 파싱
	var sig bls.Sign
	if err := sig.Deserialize(aggregatedSig); err != nil {
		return false
	}

	// 공개키 집약
	var aggregatedPubKey bls.PublicKey
	for i, pkBytes := range publicKeys {
		var pk bls.PublicKey
		if err := pk.Deserialize(pkBytes); err != nil {
			return false
		}

		if i == 0 {
			aggregatedPubKey = pk
		} else {
			aggregatedPubKey.Add(&pk)
		}
	}

	// 검증
	return sig.VerifyByte(&aggregatedPubKey, message)
}

// uint256을 Go의 기본 타입으로 표현 (간단하게)
type uint256 uint64
