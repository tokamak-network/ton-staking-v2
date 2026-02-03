package collector

import (
	"fmt"
	"math/big"

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
) ([]byte, *big.Int, error) {
	if len(state.Signatures) == 0 {
		return nil, nil, fmt.Errorf("no signatures to aggregate")
	}

	if state.ReceivedCount != state.RequiredCount {
		return nil, nil, fmt.Errorf("not unanimous: %d/%d",
			state.ReceivedCount,
			state.RequiredCount)
	}

	fmt.Printf("🔄 Aggregating %d BLS signatures...\n", len(state.Signatures))

	// 1. Validator 순서대로 서명 수집
	signatures := make([]*bls.Sign, 0, len(state.ValidatorSet))
	bitmap := big.NewInt(0)

	for i, validator := range state.ValidatorSet {
		resp, exists := state.Signatures[validator]
		if !exists {
			return nil, nil, fmt.Errorf("missing signature from validator %s", validator.Hex())
		}

		// BLS 서명 파싱
		var sig bls.Sign
		if err := sig.Deserialize(resp.Signature); err != nil {
			return nil, nil, fmt.Errorf("failed to deserialize signature: %w", err)
		}

		signatures = append(signatures, &sig)

		// Bitmap 설정 (i번째 비트를 1로) - *big.Int로 64명 이상 지원
		bitmap.SetBit(bitmap, i, 1)
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
	fmt.Printf("   Validator bitmap: %s\n", bitmap.Text(2))

	return aggregatedBytes, bitmap, nil
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
