package verifier

import (
	"context"
	"math/big"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/validator/pkg/p2p"
)

func TestNewType3Verifier(t *testing.T) {
	// L1/L2 클라이언트 없이는 생성 불가
	_, err := NewType3Verifier(&Type3Config{
		L1Client:           nil,
		L2Client:           nil,
		DisputeGameFactory: common.HexToAddress("0x1234"),
	})

	if err == nil {
		t.Error("Expected error for nil clients")
	}

	t.Log("✅ Type3Verifier requires L1/L2 clients")
}

func TestComputeWithdrawalHash(t *testing.T) {
	verifier := &Type3Verifier{
		messagePasserAddr: common.HexToAddress("0x4200000000000000000000000000000000000016"),
	}

	tx := &p2p.WithdrawalTransaction{
		Nonce:    big.NewInt(1),
		Sender:   common.HexToAddress("0xSENDER"),
		Target:   common.HexToAddress("0xTARGET"),
		Value:    big.NewInt(1000000),
		GasLimit: big.NewInt(100000),
		Data:     []byte("test data"),
	}

	hash := verifier.computeWithdrawalHash(tx)

	if hash == (common.Hash{}) {
		t.Error("Withdrawal hash is empty")
	}

	t.Logf("✅ Withdrawal hash computed: %s", hash.Hex())
}

// TestType3Verifier_MockValidation Mock으로 전체 플로우 테스트
func TestType3Verifier_MockValidation(t *testing.T) {
	t.Skip("Requires live L1/L2 RPC - skipping")

	// 실제 RPC 필요
	// verifier, err := NewType3Verifier(&Type3Config{
	// 	L1Client: l1Client,
	// 	L2Client: l2Client,
	// 	DisputeGameFactory: common.HexToAddress("0x..."),
	// })

	ctx := context.Background()

	testReq := &p2p.SignatureRequest{
		RequestID:   [32]byte{1, 2, 3},
		User:        common.HexToAddress("0x1234567890123456789012345678901234567890"),
		Amount:      big.NewInt(1000000),
		ChainID:     big.NewInt(1),
		Deadline:    uint64(time.Now().Add(10 * time.Minute).Unix()),
		RollupType:  3,
		GameIndex:   big.NewInt(100),
		OutputRoot:  [32]byte{},
		BlockNumber: 12345,
		WithdrawalTx: p2p.WithdrawalTransaction{
			Nonce:    big.NewInt(1),
			Sender:   common.HexToAddress("0xSENDER"),
			Target:   common.HexToAddress("0xTARGET"),
			Value:    big.NewInt(1000000),
			GasLimit: big.NewInt(100000),
			Data:     []byte{},
		},
	}

	_ = ctx
	_ = testReq

	// err = verifier.ValidateWithdrawal(ctx, testReq)
	// if err != nil {
	// 	t.Errorf("Validation failed: %v", err)
	// }

	t.Log("✅ Mock validation test structure ready")
}
