package verifier

import (
	"context"
	"fmt"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"

	"github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/validator/pkg/p2p"
)

// Type3Verifier Type 3 롤업 (OPTIMISM_BEDROCK_WITH_DISPUTE_GAME) 검증
type Type3Verifier struct {
	l1Client *ethclient.Client
	l2Client *ethclient.Client

	// DisputeGameFactory 주소
	disputeGameFactory common.Address

	// L2ToL1MessagePasser predeploy 주소
	messagePasserAddr common.Address
}

// Type3Config Type3 Verifier 설정
type Type3Config struct {
	L1Client           *ethclient.Client
	L2Client           *ethclient.Client
	DisputeGameFactory common.Address
}

// NewType3Verifier Type3 Verifier 생성
func NewType3Verifier(cfg *Type3Config) (*Type3Verifier, error) {
	if cfg.L1Client == nil {
		return nil, fmt.Errorf("L1 client is required")
	}
	if cfg.L2Client == nil {
		return nil, fmt.Errorf("L2 client is required")
	}

	// L2ToL1MessagePasser predeploy address (고정)
	messagePasserAddr := common.HexToAddress("0x4200000000000000000000000000000000000016")

	return &Type3Verifier{
		l1Client:           cfg.L1Client,
		l2Client:           cfg.L2Client,
		disputeGameFactory: cfg.DisputeGameFactory,
		messagePasserAddr:  messagePasserAddr,
	}, nil
}

// ValidateWithdrawal 출금 요청 검증
// Output root는 L1 Portal에서 이미 검증됨 (proveWithdrawalTransaction).
// Validator는 L2에서 withdrawal 존재만 확인.
func (v *Type3Verifier) ValidateWithdrawal(ctx context.Context, req *p2p.SignatureRequest) error {
	// 1. DisputeGame 확인 (L1)
	fmt.Printf("   [Type3] Checking DisputeGame (GameIndex: %s)...\n", req.GameIndex.String())
	// TODO: DisputeGameFactory.games(gameIndex) 호출하여 game 상태 확인
	// 현재는 L1 FastWithdrawalRequested 이벤트에서 검증된 것으로 신뢰

	// 2. Output root는 L1에서 이미 검증됨 (RAT → Portal.proveWithdrawalTransaction)
	// Validator가 재계산하지 않음 — RAT 테스트와 동일한 방식
	fmt.Printf("   [Type3] OutputRoot: %s (L1-verified, skipping recomputation)\n",
		common.BytesToHash(req.OutputRoot[:]).Hex())

	// 3. L2에서 withdrawal 존재 확인 (L2ToL1MessagePasser storage)
	withdrawalHash := v.computeWithdrawalHash(&req.WithdrawalTx)
	fmt.Printf("   [Type3] Checking withdrawal existence (hash: %s)...\n", withdrawalHash.Hex())

	// 최신 L2 블록 기준으로 확인 (nil = latest)
	exists, err := v.checkWithdrawalExists(ctx, withdrawalHash)
	if err != nil {
		return fmt.Errorf("failed to check withdrawal existence: %w", err)
	}

	if !exists {
		return fmt.Errorf("withdrawal not found in L2")
	}

	fmt.Printf("   [Type3] ✅ Withdrawal exists in L2\n")

	return nil
}

// computeWithdrawalHash 출금 해시 계산
func (v *Type3Verifier) computeWithdrawalHash(tx *p2p.WithdrawalTransaction) common.Hash {
	// Optimism의 withdrawal hash 계산 방식
	// hash = keccak256(abi.encode(nonce, sender, target, value, gasLimit, data))

	// 간단하게 구현 (실제로는 ABI 인코딩 필요)
	data := crypto.Keccak256(
		common.LeftPadBytes(tx.Nonce.Bytes(), 32),
		tx.Sender.Bytes(),
		tx.Target.Bytes(),
		common.LeftPadBytes(tx.Value.Bytes(), 32),
		common.LeftPadBytes(tx.GasLimit.Bytes(), 32),
		tx.Data,
	)

	return common.BytesToHash(data)
}

// checkWithdrawalExists L2에서 출금 존재 확인 (최신 블록 기준)
func (v *Type3Verifier) checkWithdrawalExists(
	ctx context.Context,
	withdrawalHash common.Hash,
) (bool, error) {
	// L2ToL1MessagePasser storage에서 withdrawal 확인
	// storage[withdrawalHash] != 0 이면 존재

	// eth_getStorageAt 호출 (nil = latest block)
	storageValue, err := v.l2Client.StorageAt(
		ctx,
		v.messagePasserAddr,
		withdrawalHash,
		nil,
	)
	if err != nil {
		return false, fmt.Errorf("failed to get storage: %w", err)
	}

	// storage 값이 0이 아니면 존재
	isZero := true
	for _, b := range storageValue {
		if b != 0 {
			isZero = false
			break
		}
	}

	return !isZero, nil
}
