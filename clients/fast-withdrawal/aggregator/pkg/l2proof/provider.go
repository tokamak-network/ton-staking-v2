package l2proof

import (
	"context"
	"encoding/hex"
	"fmt"
	"math/big"
	"strings"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/ethereum/go-ethereum/rpc"
)

const (
	// L2ToL1MessagePasser predeploy 주소 (Optimism 표준)
	L2ToL1MessagePasserAddress = "0x4200000000000000000000000000000000000016"
)

// L2ProofProvider L2 증명 조회
type L2ProofProvider struct {
	l2Client    *ethclient.Client
	l2RPC       *rpc.Client
	messagePasser common.Address
}

// NewL2ProofProvider 새로운 L2 증명 제공자 생성
func NewL2ProofProvider(l2RPCURL string) (*L2ProofProvider, error) {
	// RPC 클라이언트 연결
	rpcClient, err := rpc.Dial(l2RPCURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to L2 RPC: %w", err)
	}

	// ethclient 래퍼
	ethClient := ethclient.NewClient(rpcClient)

	return &L2ProofProvider{
		l2Client:      ethClient,
		l2RPC:         rpcClient,
		messagePasser: common.HexToAddress(L2ToL1MessagePasserAddress),
	}, nil
}

// GetOutputRootProof OutputRootProof 조회
func (p *L2ProofProvider) GetOutputRootProof(
	ctx context.Context,
	blockNumber uint64,
) (*OutputRootProof, error) {
	// 1. 블록 헤더 조회
	header, err := p.l2Client.HeaderByNumber(ctx, new(big.Int).SetUint64(blockNumber))
	if err != nil {
		return nil, fmt.Errorf("failed to get block header: %w", err)
	}

	stateRoot := header.Root
	blockHash := header.Hash()

	// 2. L2ToL1MessagePasser 저장소 루트 조회 (eth_getProof)
	var proofResult AccountProofResult
	blockHex := fmt.Sprintf("0x%x", blockNumber)

	err = p.l2RPC.CallContext(ctx, &proofResult, "eth_getProof",
		p.messagePasser.Hex(), []string{}, blockHex)
	if err != nil {
		return nil, fmt.Errorf("failed to get account proof: %w", err)
	}

	messagePasserStorageRoot := proofResult.StorageHash

	// 3. OutputRootProof 구성
	proof := &OutputRootProof{
		Version:                  [32]byte{}, // Version 0
		StateRoot:                stateRoot,
		MessagePasserStorageRoot: messagePasserStorageRoot,
		LatestBlockHash:          blockHash,
	}

	return proof, nil
}

// ComputeOutputRoot OutputRoot 계산
func ComputeOutputRoot(proof *OutputRootProof) common.Hash {
	// OutputRoot = keccak256(version || stateRoot || messagePasserStorageRoot || blockHash)
	data := make([]byte, 0, 128)
	data = append(data, proof.Version[:]...)
	data = append(data, proof.StateRoot[:]...)
	data = append(data, proof.MessagePasserStorageRoot[:]...)
	data = append(data, proof.LatestBlockHash[:]...)
	return crypto.Keccak256Hash(data)
}

// VerifyOutputRoot OutputRoot 검증
func (p *L2ProofProvider) VerifyOutputRoot(
	proof *OutputRootProof,
	expectedOutputRoot common.Hash,
) error {
	computedRoot := ComputeOutputRoot(proof)
	if computedRoot != expectedOutputRoot {
		return fmt.Errorf("output root mismatch: computed=%s, expected=%s",
			computedRoot.Hex(), expectedOutputRoot.Hex())
	}
	return nil
}

// GetWithdrawalProof 출금 증명 조회
func (p *L2ProofProvider) GetWithdrawalProof(
	ctx context.Context,
	withdrawalTx *WithdrawalTransaction,
	blockNumber uint64,
) (*WithdrawalProof, error) {
	// 1. WithdrawalHash 계산
	withdrawalHash := ComputeWithdrawalHash(withdrawalTx)

	// 2. Storage key 계산
	// L2ToL1MessagePasser.sentMessages[withdrawalHash] = true
	// Storage slot = keccak256(withdrawalHash || slot_number)
	// slot_number for sentMessages mapping is 0
	storageKey := ComputeStorageKey(withdrawalHash, 0)

	// 3. Storage proof 조회 (eth_getProof)
	var proofResult AccountProofResult
	blockHex := fmt.Sprintf("0x%x", blockNumber)

	storageKeyHash := common.BytesToHash(storageKey[:])
	err := p.l2RPC.CallContext(ctx, &proofResult, "eth_getProof",
		p.messagePasser.Hex(), []string{storageKeyHash.Hex()}, blockHex)
	if err != nil {
		return nil, fmt.Errorf("failed to get storage proof: %w", err)
	}

	// 4. Storage proof 파싱
	if len(proofResult.StorageProof) == 0 {
		return nil, fmt.Errorf("no storage proof returned")
	}

	storageProofData := proofResult.StorageProof[0]

	// Proof를 [][]byte로 변환
	proofNodes := make([][]byte, len(storageProofData.Proof))
	for i, proofHex := range storageProofData.Proof {
		proofHex = strings.TrimPrefix(proofHex, "0x")
		proofBytes, err := hex.DecodeString(proofHex)
		if err != nil {
			return nil, fmt.Errorf("failed to decode proof node: %w", err)
		}
		proofNodes[i] = proofBytes
	}

	// Storage value 파싱
	var storageValue [32]byte
	valueHex := strings.TrimPrefix(storageProofData.Value, "0x")
	valueBytes, err := hex.DecodeString(valueHex)
	if err == nil && len(valueBytes) <= 32 {
		copy(storageValue[32-len(valueBytes):], valueBytes)
	}

	proof := &WithdrawalProof{
		WithdrawalHash: withdrawalHash,
		StorageProof:   proofNodes,
		StorageKey:     storageKey,
		StorageValue:   storageValue,
		L2BlockNumber:  blockNumber,
		OutputRoot:     ComputeOutputRoot(&OutputRootProof{}), // Will be set later
	}

	return proof, nil
}

// ComputeWithdrawalHash WithdrawalTransaction 해시 계산
func ComputeWithdrawalHash(tx *WithdrawalTransaction) [32]byte {
	// Optimism의 WithdrawalTransaction 해시 계산
	// hash = keccak256(abi.encode(nonce, sender, target, value, gasLimit, data))

	uint256Ty, _ := abi.NewType("uint256", "", nil)
	addressTy, _ := abi.NewType("address", "", nil)
	bytesTy, _ := abi.NewType("bytes", "", nil)

	arguments := abi.Arguments{
		{Type: uint256Ty},  // nonce
		{Type: addressTy},  // sender
		{Type: addressTy},  // target
		{Type: uint256Ty},  // value
		{Type: uint256Ty},  // gasLimit
		{Type: bytesTy},    // data
	}

	nonce := tx.Nonce
	if nonce == nil {
		nonce = big.NewInt(0)
	}
	value := tx.Value
	if value == nil {
		value = big.NewInt(0)
	}
	gasLimit := tx.GasLimit
	if gasLimit == nil {
		gasLimit = big.NewInt(0)
	}
	data := tx.Data
	if data == nil {
		data = []byte{}
	}

	encoded, err := arguments.Pack(nonce, tx.Sender, tx.Target, value, gasLimit, data)
	if err != nil {
		// Fallback: simple concatenation
		return crypto.Keccak256Hash(
			common.LeftPadBytes(nonce.Bytes(), 32),
			tx.Sender.Bytes(),
			tx.Target.Bytes(),
			common.LeftPadBytes(value.Bytes(), 32),
			common.LeftPadBytes(gasLimit.Bytes(), 32),
			data,
		)
	}

	return crypto.Keccak256Hash(encoded)
}

// ComputeStorageKey mapping storage key 계산
func ComputeStorageKey(key [32]byte, slot uint64) [32]byte {
	// Solidity mapping storage key = keccak256(key || slot)
	slotBytes := common.LeftPadBytes(big.NewInt(int64(slot)).Bytes(), 32)
	data := append(key[:], slotBytes...)
	return crypto.Keccak256Hash(data)
}

// GetFullProof 전체 증명 조회 (OutputRootProof + WithdrawalProof)
func (p *L2ProofProvider) GetFullProof(
	ctx context.Context,
	withdrawalTx *WithdrawalTransaction,
	blockNumber uint64,
	expectedOutputRoot common.Hash,
) (*FastWithdrawalProof, error) {
	// 1. OutputRootProof 조회
	outputRootProof, err := p.GetOutputRootProof(ctx, blockNumber)
	if err != nil {
		return nil, fmt.Errorf("failed to get output root proof: %w", err)
	}

	// 2. OutputRoot 검증
	if err := p.VerifyOutputRoot(outputRootProof, expectedOutputRoot); err != nil {
		return nil, fmt.Errorf("output root verification failed: %w", err)
	}

	// 3. WithdrawalProof 조회
	withdrawalProof, err := p.GetWithdrawalProof(ctx, withdrawalTx, blockNumber)
	if err != nil {
		return nil, fmt.Errorf("failed to get withdrawal proof: %w", err)
	}

	withdrawalProof.OutputRoot = expectedOutputRoot

	return &FastWithdrawalProof{
		OutputRootProof: *outputRootProof,
		WithdrawalProof: *withdrawalProof,
		WithdrawalTx:    *withdrawalTx,
	}, nil
}

// Close 연결 종료
func (p *L2ProofProvider) Close() {
	if p.l2RPC != nil {
		p.l2RPC.Close()
	}
}
