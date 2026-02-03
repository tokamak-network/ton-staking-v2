package l2proof

import (
	"math/big"

	"github.com/ethereum/go-ethereum/common"
)

// OutputRootProof OutputRoot 증명 (Optimism 표준)
type OutputRootProof struct {
	Version                  [32]byte    // Version (항상 0x0)
	StateRoot                common.Hash // L2 state root
	MessagePasserStorageRoot common.Hash // L2ToL1MessagePasser storage root
	LatestBlockHash          common.Hash // L2 block hash
}

// WithdrawalProof 출금 Merkle 증명
type WithdrawalProof struct {
	// Withdrawal hash와 proof
	WithdrawalHash [32]byte   // keccak256(withdrawal transaction)
	StorageProof   [][]byte   // Merkle proof from MessagePasser storage root
	StorageKey     [32]byte   // Storage slot key
	StorageValue   [32]byte   // Storage slot value (should be 1 for valid withdrawal)

	// L2 output 정보
	L2OutputIndex uint64      // L2 output index in DisputeGame
	L2BlockNumber uint64      // L2 block number
	OutputRoot    common.Hash // Computed output root
}

// WithdrawalTransaction Optimism 출금 트랜잭션
type WithdrawalTransaction struct {
	Nonce    *big.Int
	Sender   common.Address
	Target   common.Address
	Value    *big.Int
	GasLimit *big.Int
	Data     []byte
}

// AccountProofResult eth_getProof RPC 결과
type AccountProofResult struct {
	Address      common.Address `json:"address"`
	AccountProof []string       `json:"accountProof"`
	Balance      string         `json:"balance"`
	CodeHash     common.Hash    `json:"codeHash"`
	Nonce        string         `json:"nonce"`
	StorageHash  common.Hash    `json:"storageHash"`
	StorageProof []StorageProof `json:"storageProof"`
}

// StorageProof 스토리지 증명
type StorageProof struct {
	Key   string   `json:"key"`
	Value string   `json:"value"`
	Proof []string `json:"proof"`
}

// FastWithdrawalProof Fast Withdrawal에 필요한 모든 증명
type FastWithdrawalProof struct {
	OutputRootProof  OutputRootProof
	WithdrawalProof  WithdrawalProof
	WithdrawalTx     WithdrawalTransaction
}
