package p2p

import (
	"math/big"

	"github.com/ethereum/go-ethereum/common"
)

// SignatureRequest Aggregator가 브로드캐스트하는 서명 요청
type SignatureRequest struct {
	RequestID [32]byte       `json:"request_id"` // keccak256(user, amount, timestamp, blockNumber)
	User      common.Address `json:"user"`       // 출금 요청 사용자
	Amount    *big.Int       `json:"amount"`     // 출금 금액
	ChainID   *big.Int       `json:"chain_id"`   // L1 체인 ID
	Deadline  uint64         `json:"deadline"`   // 서명 마감 시간 (timestamp)

	// Type 3 specific
	RollupType  uint8    `json:"rollup_type"`  // 3 = OPTIMISM_BEDROCK_WITH_DISPUTE_GAME
	GameIndex   *big.Int `json:"game_index"`   // DisputeGame index
	OutputRoot  [32]byte `json:"output_root"`  // DisputeGame rootClaim
	BlockNumber uint64   `json:"block_number"` // L2 block number

	// Withdrawal transaction info
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

// SignatureResponse Validator가 발행하는 서명 응답
type SignatureResponse struct {
	RequestID     [32]byte       `json:"request_id"`     // 요청 ID
	Validator     common.Address `json:"validator"`      // 서명한 검증자 주소
	Signature     []byte         `json:"signature"`      // BLS 서명 (96 bytes compressed)
	PublicKey     []byte         `json:"public_key"`     // BLS 공개키 (48 bytes compressed)
	Timestamp     uint64         `json:"timestamp"`      // 서명 시간
	ValidatorPeer string         `json:"validator_peer"` // libp2p peer ID
}

// GetSigningMessage 서명할 메시지 생성
func (req *SignatureRequest) GetSigningMessage() []byte {
	// Solidity와 동일한 방식으로 메시지 생성
	// message = keccak256(
	//     "TOKAMAK_FAST_WITHDRAWAL",
	//     requestId,
	//     user,
	//     amount,
	//     chainId
	// )

	// 여기서는 간단하게 requestID를 메시지로 사용
	// 실제로는 Solidity의 abi.encodePacked와 동일하게 구현 필요
	return req.RequestID[:]
}
