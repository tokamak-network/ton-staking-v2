package l2proof

import (
	"math/big"
	"testing"

	"github.com/ethereum/go-ethereum/common"
)

func TestComputeOutputRoot(t *testing.T) {
	proof := &OutputRootProof{
		Version:                  [32]byte{},
		StateRoot:                common.HexToHash("0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"),
		MessagePasserStorageRoot: common.HexToHash("0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"),
		LatestBlockHash:          common.HexToHash("0xdeadbeef00000000000000000000000000000000000000000000000000000000"),
	}

	outputRoot := ComputeOutputRoot(proof)

	// Output root는 32 bytes여야 함
	if len(outputRoot) != 32 {
		t.Errorf("Unexpected output root length: %d", len(outputRoot))
	}

	// 동일한 입력에 대해 동일한 출력이 나와야 함
	outputRoot2 := ComputeOutputRoot(proof)
	if outputRoot != outputRoot2 {
		t.Error("Output root should be deterministic")
	}

	t.Logf("✅ Output root computed: %s", outputRoot.Hex())
}

func TestComputeWithdrawalHash(t *testing.T) {
	tx := &WithdrawalTransaction{
		Nonce:    big.NewInt(1),
		Sender:   common.HexToAddress("0x1234567890123456789012345678901234567890"),
		Target:   common.HexToAddress("0xabcdefabcdefabcdefabcdefabcdefabcdefabcd"),
		Value:    big.NewInt(1000000000000000000), // 1 ETH
		GasLimit: big.NewInt(100000),
		Data:     []byte{0x01, 0x02, 0x03},
	}

	hash := ComputeWithdrawalHash(tx)

	// Hash는 32 bytes여야 함
	if len(hash) != 32 {
		t.Errorf("Unexpected hash length: %d", len(hash))
	}

	// 동일한 입력에 대해 동일한 해시가 나와야 함
	hash2 := ComputeWithdrawalHash(tx)
	if hash != hash2 {
		t.Error("Withdrawal hash should be deterministic")
	}

	t.Logf("✅ Withdrawal hash computed: %x", hash[:])
}

func TestComputeWithdrawalHash_NilFields(t *testing.T) {
	// nil 필드가 있는 경우
	tx := &WithdrawalTransaction{
		Nonce:    nil,
		Sender:   common.Address{},
		Target:   common.Address{},
		Value:    nil,
		GasLimit: nil,
		Data:     nil,
	}

	// panic 없이 해시가 계산되어야 함
	hash := ComputeWithdrawalHash(tx)
	if len(hash) != 32 {
		t.Errorf("Unexpected hash length for nil fields: %d", len(hash))
	}

	t.Log("✅ Nil fields handled correctly in withdrawal hash")
}

func TestComputeStorageKey(t *testing.T) {
	key := [32]byte{1, 2, 3, 4}
	slot := uint64(0)

	storageKey := ComputeStorageKey(key, slot)

	// Storage key는 32 bytes여야 함
	if len(storageKey) != 32 {
		t.Errorf("Unexpected storage key length: %d", len(storageKey))
	}

	// 동일한 입력에 대해 동일한 결과
	storageKey2 := ComputeStorageKey(key, slot)
	if storageKey != storageKey2 {
		t.Error("Storage key should be deterministic")
	}

	// 다른 slot에 대해 다른 결과
	storageKey3 := ComputeStorageKey(key, 1)
	if storageKey == storageKey3 {
		t.Error("Different slots should produce different storage keys")
	}

	t.Logf("✅ Storage key computed: %x", storageKey[:])
}

func TestOutputRootProof_Struct(t *testing.T) {
	proof := &OutputRootProof{
		Version:                  [32]byte{0x00},
		StateRoot:                common.HexToHash("0x1111111111111111111111111111111111111111111111111111111111111111"),
		MessagePasserStorageRoot: common.HexToHash("0x2222222222222222222222222222222222222222222222222222222222222222"),
		LatestBlockHash:          common.HexToHash("0x3333333333333333333333333333333333333333333333333333333333333333"),
	}

	// Version 0 확인
	zeroVersion := [32]byte{}
	if proof.Version != zeroVersion {
		// Version이 0x00으로 시작하면 OK
		if proof.Version[0] != 0 {
			t.Error("Version should be 0")
		}
	}

	if proof.StateRoot == (common.Hash{}) {
		t.Error("StateRoot should not be empty")
	}

	if proof.MessagePasserStorageRoot == (common.Hash{}) {
		t.Error("MessagePasserStorageRoot should not be empty")
	}

	if proof.LatestBlockHash == (common.Hash{}) {
		t.Error("LatestBlockHash should not be empty")
	}

	t.Log("✅ OutputRootProof struct works correctly")
}

func TestWithdrawalProof_Struct(t *testing.T) {
	proof := &WithdrawalProof{
		WithdrawalHash: [32]byte{1, 2, 3},
		StorageProof:   [][]byte{{0x01}, {0x02}},
		StorageKey:     [32]byte{4, 5, 6},
		StorageValue:   [32]byte{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1}, // true
		L2OutputIndex:  42,
		L2BlockNumber:  12345678,
		OutputRoot:     common.HexToHash("0xabcd"),
	}

	if proof.L2BlockNumber != 12345678 {
		t.Errorf("Unexpected block number: %d", proof.L2BlockNumber)
	}

	if proof.L2OutputIndex != 42 {
		t.Errorf("Unexpected output index: %d", proof.L2OutputIndex)
	}

	if len(proof.StorageProof) != 2 {
		t.Errorf("Unexpected storage proof length: %d", len(proof.StorageProof))
	}

	t.Log("✅ WithdrawalProof struct works correctly")
}

func TestFastWithdrawalProof_Struct(t *testing.T) {
	proof := &FastWithdrawalProof{
		OutputRootProof: OutputRootProof{
			StateRoot: common.HexToHash("0x1234"),
		},
		WithdrawalProof: WithdrawalProof{
			L2BlockNumber: 100,
		},
		WithdrawalTx: WithdrawalTransaction{
			Value: big.NewInt(1000),
		},
	}

	if proof.OutputRootProof.StateRoot == (common.Hash{}) {
		t.Error("OutputRootProof.StateRoot should not be empty")
	}

	if proof.WithdrawalProof.L2BlockNumber != 100 {
		t.Errorf("Unexpected block number: %d", proof.WithdrawalProof.L2BlockNumber)
	}

	if proof.WithdrawalTx.Value.Cmp(big.NewInt(1000)) != 0 {
		t.Error("Unexpected withdrawal value")
	}

	t.Log("✅ FastWithdrawalProof struct works correctly")
}

func TestAccountProofResult_Struct(t *testing.T) {
	result := &AccountProofResult{
		Address:      common.HexToAddress("0x4200000000000000000000000000000000000016"),
		AccountProof: []string{"0x01", "0x02", "0x03"},
		Balance:      "0x0",
		CodeHash:     common.HexToHash("0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"),
		Nonce:        "0x1",
		StorageHash:  common.HexToHash("0x5678"),
		StorageProof: []StorageProof{
			{
				Key:   "0xkey",
				Value: "0x1",
				Proof: []string{"0xproof1"},
			},
		},
	}

	if result.Address != common.HexToAddress("0x4200000000000000000000000000000000000016") {
		t.Error("Unexpected address")
	}

	if len(result.AccountProof) != 3 {
		t.Errorf("Unexpected account proof length: %d", len(result.AccountProof))
	}

	if len(result.StorageProof) != 1 {
		t.Errorf("Unexpected storage proof count: %d", len(result.StorageProof))
	}

	if result.StorageProof[0].Value != "0x1" {
		t.Error("Unexpected storage value")
	}

	t.Log("✅ AccountProofResult struct works correctly")
}

func TestL2ToL1MessagePasserAddress(t *testing.T) {
	// L2ToL1MessagePasser 주소 확인
	expectedAddress := "0x4200000000000000000000000000000000000016"
	if L2ToL1MessagePasserAddress != expectedAddress {
		t.Errorf("Unexpected L2ToL1MessagePasser address: %s", L2ToL1MessagePasserAddress)
	}

	t.Log("✅ L2ToL1MessagePasser address is correct")
}
