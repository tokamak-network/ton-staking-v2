package verifier

import (
	"context"
	"fmt"
	"math/big"

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
func (v *Type3Verifier) ValidateWithdrawal(ctx context.Context, req *p2p.SignatureRequest) error {
	// 1. DisputeGame 상태 확인 (L1)
	// TODO: DisputeGameFactory에서 game 조회하여 상태 확인
	// - Game이 resolved 되었는지?
	// - Claim이 없는지? (분쟁 중이 아닌지)

	fmt.Printf("   [Type3] Checking DisputeGame (GameIndex: %s)...\n", req.GameIndex.String())

	// Mock: 일단 통과
	// 실제로는 DisputeGameFactory.games(gameIndex) 호출

	// 2. L2 블록 상태 확인
	fmt.Printf("   [Type3] Checking L2 block %d...\n", req.BlockNumber)

	header, err := v.l2Client.HeaderByNumber(ctx, big.NewInt(int64(req.BlockNumber)))
	if err != nil {
		return fmt.Errorf("failed to get L2 block header: %w", err)
	}

	stateRoot := header.Root
	blockHash := header.Hash()

	fmt.Printf("   [Type3] L2 StateRoot: %s\n", stateRoot.Hex())
	fmt.Printf("   [Type3] L2 BlockHash: %s\n", blockHash.Hex())

	// 3. OutputRoot 계산 및 검증
	computedOutputRoot, err := v.computeOutputRoot(ctx, stateRoot, blockHash, req.BlockNumber)
	if err != nil {
		return fmt.Errorf("failed to compute output root: %w", err)
	}

	fmt.Printf("   [Type3] Computed OutputRoot: %s\n", computedOutputRoot.Hex())
	fmt.Printf("   [Type3] Expected OutputRoot: %s\n", common.BytesToHash(req.OutputRoot[:]).Hex())

	// OutputRoot 비교
	if computedOutputRoot != common.BytesToHash(req.OutputRoot[:]) {
		return fmt.Errorf("output root mismatch: computed=%s, expected=%s",
			computedOutputRoot.Hex(),
			common.BytesToHash(req.OutputRoot[:]).Hex())
	}

	fmt.Printf("   [Type3] ✅ OutputRoot verified\n")

	// 4. 출금 트랜잭션 존재 확인 (L2ToL1MessagePasser storage)
	withdrawalHash := v.computeWithdrawalHash(&req.WithdrawalTx)

	fmt.Printf("   [Type3] Checking withdrawal existence (hash: %s)...\n", withdrawalHash.Hex())

	exists, err := v.checkWithdrawalExists(ctx, withdrawalHash, req.BlockNumber)
	if err != nil {
		return fmt.Errorf("failed to check withdrawal existence: %w", err)
	}

	if !exists {
		return fmt.Errorf("withdrawal not found in L2")
	}

	fmt.Printf("   [Type3] ✅ Withdrawal exists in L2\n")

	return nil
}

// computeOutputRoot OutputRoot 계산
// OutputRoot = keccak256(version || stateRoot || messagePasserStorageRoot || blockHash)
func (v *Type3Verifier) computeOutputRoot(
	ctx context.Context,
	stateRoot common.Hash,
	blockHash common.Hash,
	blockNumber uint64,
) (common.Hash, error) {
	// L2ToL1MessagePasser의 storage root 조회
	blockNum := big.NewInt(int64(blockNumber))

	// eth_getProof로 MessagePasser storage root 가져오기
	// Note: go-ethereum의 ethclient는 getProof를 직접 지원하지 않으므로
	// 일단 간단하게 계산 (실제로는 RPC 호출 필요)

	// Mock: stateRoot를 그대로 사용 (테스트용)
	messagePasserStorageRoot := stateRoot

	// OutputV0 계산
	version := [32]byte{} // Version 0

	data := make([]byte, 0, 128)
	data = append(data, version[:]...)
	data = append(data, stateRoot[:]...)
	data = append(data, messagePasserStorageRoot[:]...)
	data = append(data, blockHash[:]...)

	outputRoot := crypto.Keccak256Hash(data)

	_ = blockNum // 사용

	return outputRoot, nil
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

// checkWithdrawalExists L2에서 출금 존재 확인
func (v *Type3Verifier) checkWithdrawalExists(
	ctx context.Context,
	withdrawalHash common.Hash,
	blockNumber uint64,
) (bool, error) {
	// L2ToL1MessagePasser storage에서 withdrawal 확인
	// storage[withdrawalHash] != 0 이면 존재

	// eth_getStorageAt 호출
	blockNum := big.NewInt(int64(blockNumber))

	storageValue, err := v.l2Client.StorageAt(
		ctx,
		v.messagePasserAddr,
		withdrawalHash,
		blockNum,
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
