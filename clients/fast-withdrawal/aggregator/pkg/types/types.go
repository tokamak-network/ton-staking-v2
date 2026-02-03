package types

import (
	"math/big"

	"github.com/ethereum/go-ethereum/common"
)

// SignatureRequest Validator에게 보내는 서명 요청 (validator와 동일)
type SignatureRequest struct {
	RequestID [32]byte       `json:"request_id"`
	User      common.Address `json:"user"`
	Amount    *big.Int       `json:"amount"`
	ChainID   *big.Int       `json:"chain_id"`
	Deadline  uint64         `json:"deadline"`

	RollupType  uint8    `json:"rollup_type"`
	GameIndex   *big.Int `json:"game_index"`
	OutputRoot  [32]byte `json:"output_root"`
	BlockNumber uint64   `json:"block_number"`

	WithdrawalTx WithdrawalTransaction `json:"withdrawal_tx"`
}

// WithdrawalTransaction Optimism 출금 트랜잭션
type WithdrawalTransaction struct {
	Nonce    *big.Int       `json:"nonce"`
	Sender   common.Address `json:"sender"`
	Target   common.Address `json:"target"`
	Value    *big.Int       `json:"value"`
	GasLimit *big.Int       `json:"gas_limit"`
	Data     []byte         `json:"data"`
}

// SignatureResponse Validator로부터 받는 서명 응답
type SignatureResponse struct {
	RequestID     [32]byte       `json:"request_id"`
	Validator     common.Address `json:"validator"`
	Signature     []byte         `json:"signature"`  // 96 bytes BLS
	PublicKey     []byte         `json:"public_key"` // 48 bytes BLS
	Timestamp     uint64         `json:"timestamp"`
	ValidatorPeer string         `json:"validator_peer"` // libp2p peer ID
}

// RequestState 서명 수집 상태
type RequestState struct {
	Request         *SignatureRequest
	Signatures      map[common.Address]*SignatureResponse
	ValidatorSet    []common.Address
	RequiredCount   int
	ReceivedCount   int
	Completed       bool
	SubmittedTxHash common.Hash
}
