package submitter

import (
	"context"
	"crypto/ecdsa"
	"fmt"
	"math/big"
	"strings"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"

	aggTypes "github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/aggregator/pkg/types"
)

// RAT Fast Withdrawal ABI (필요한 함수만)
const ratFastWithdrawalABI = `[
	{
		"inputs": [
			{
				"components": [
					{"internalType": "uint256", "name": "nonce", "type": "uint256"},
					{"internalType": "address", "name": "sender", "type": "address"},
					{"internalType": "address", "name": "target", "type": "address"},
					{"internalType": "uint256", "name": "value", "type": "uint256"},
					{"internalType": "uint256", "name": "gasLimit", "type": "uint256"},
					{"internalType": "bytes", "name": "data", "type": "bytes"}
				],
				"internalType": "struct Types.WithdrawalTransaction",
				"name": "_tx",
				"type": "tuple"
			},
			{
				"components": [
					{"internalType": "bytes32", "name": "requestId", "type": "bytes32"},
					{"internalType": "uint256", "name": "gameIndex", "type": "uint256"},
					{"internalType": "bytes32", "name": "outputRoot", "type": "bytes32"},
					{"internalType": "bytes32", "name": "withdrawalHash", "type": "bytes32"},
					{"internalType": "bytes32[]", "name": "withdrawalProof", "type": "bytes32[]"},
					{"internalType": "uint256", "name": "l2OutputIndex", "type": "uint256"},
					{
						"components": [
							{"internalType": "bytes32", "name": "version", "type": "bytes32"},
							{"internalType": "bytes32", "name": "stateRoot", "type": "bytes32"},
							{"internalType": "bytes32", "name": "messagePasserStorageRoot", "type": "bytes32"},
							{"internalType": "bytes32", "name": "latestBlockhash", "type": "bytes32"}
						],
						"internalType": "struct Types.OutputRootProof",
						"name": "outputRootProof",
						"type": "tuple"
					},
					{"internalType": "uint256", "name": "validatorBitmap", "type": "uint256"}
				],
				"internalType": "struct RATFastWithdrawalLib.FastWithdrawalInput",
				"name": "input",
				"type": "tuple"
			},
			{"internalType": "bytes", "name": "_aggregatedSignature", "type": "bytes"}
		],
		"name": "verifyAndExecuteFastWithdrawal",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	}
]`

// L1Submitter L1 트랜잭션 제출
type L1Submitter struct {
	client      *ethclient.Client
	ratContract common.Address
	privateKey  *ecdsa.PrivateKey
	fromAddress common.Address
	abi         abi.ABI

	// Gas settings
	maxGasPrice *big.Int
	gasLimit    uint64
}

// Config L1Submitter 설정
type Config struct {
	Client      *ethclient.Client
	RATContract common.Address
	PrivateKey  string // Hex string

	MaxGasPrice *big.Int // In wei
	GasLimit    uint64
}

// NewL1Submitter 새로운 L1 Submitter 생성
func NewL1Submitter(cfg *Config) (*L1Submitter, error) {
	if cfg.Client == nil {
		return nil, fmt.Errorf("L1 client is required")
	}

	// ABI 파싱
	parsedABI, err := abi.JSON(strings.NewReader(ratFastWithdrawalABI))
	if err != nil {
		return nil, fmt.Errorf("failed to parse RAT Fast Withdrawal ABI: %w", err)
	}

	// Private key 파싱
	privateKey, err := crypto.HexToECDSA(cfg.PrivateKey)
	if err != nil {
		return nil, fmt.Errorf("invalid private key: %w", err)
	}

	// From address 계산
	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		return nil, fmt.Errorf("error casting public key to ECDSA")
	}

	fromAddress := crypto.PubkeyToAddress(*publicKeyECDSA)

	// 기본값 설정
	if cfg.MaxGasPrice == nil {
		cfg.MaxGasPrice = big.NewInt(100 * 1e9) // 100 gwei
	}
	if cfg.GasLimit == 0 {
		cfg.GasLimit = 500000
	}

	fmt.Printf("✅ L1 Submitter initialized\n")
	fmt.Printf("   From: %s\n", fromAddress.Hex())
	fmt.Printf("   RAT Contract: %s\n", cfg.RATContract.Hex())
	fmt.Printf("   Max Gas Price: %s gwei\n", new(big.Int).Div(cfg.MaxGasPrice, big.NewInt(1e9)).String())

	return &L1Submitter{
		client:      cfg.Client,
		ratContract: cfg.RATContract,
		privateKey:  privateKey,
		fromAddress: fromAddress,
		abi:         parsedABI,
		maxGasPrice: cfg.MaxGasPrice,
		gasLimit:    cfg.GasLimit,
	}, nil
}

// SubmitFastWithdrawal Fast Withdrawal 제출
func (s *L1Submitter) SubmitFastWithdrawal(
	ctx context.Context,
	state *aggTypes.RequestState,
	aggregatedSignature []byte,
	validatorBitmap *big.Int,
) (common.Hash, error) {

	fmt.Printf("📤 Submitting fast withdrawal to L1...\n")
	fmt.Printf("   RequestID: %x\n", state.Request.RequestID[:8])
	fmt.Printf("   Validators: %d/%d\n", state.ReceivedCount, state.RequiredCount)

	// 1. Nonce 조회
	nonce, err := s.client.PendingNonceAt(ctx, s.fromAddress)
	if err != nil {
		return common.Hash{}, fmt.Errorf("failed to get nonce: %w", err)
	}

	// 2. Gas Price 조회
	gasPrice, err := s.client.SuggestGasPrice(ctx)
	if err != nil {
		return common.Hash{}, fmt.Errorf("failed to get gas price: %w", err)
	}

	// Max gas price 체크
	if gasPrice.Cmp(s.maxGasPrice) > 0 {
		return common.Hash{}, fmt.Errorf("gas price too high: %s > %s", gasPrice.String(), s.maxGasPrice.String())
	}

	fmt.Printf("   Nonce: %d\n", nonce)
	fmt.Printf("   Gas Price: %s gwei\n", new(big.Int).Div(gasPrice, big.NewInt(1e9)).String())

	// 3. Calldata 구성
	// RAT.verifyAndExecuteFastWithdrawal(tx, input, aggregatedSignature)
	calldata := s.buildCalldata(state, aggregatedSignature, validatorBitmap)

	// 4. 트랜잭션 생성
	tx := types.NewTransaction(
		nonce,
		s.ratContract,
		big.NewInt(0), // value
		s.gasLimit,
		gasPrice,
		calldata,
	)

	// 5. Chain ID 조회
	chainID, err := s.client.ChainID(ctx)
	if err != nil {
		return common.Hash{}, fmt.Errorf("failed to get chain ID: %w", err)
	}

	// 6. 서명
	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(chainID), s.privateKey)
	if err != nil {
		return common.Hash{}, fmt.Errorf("failed to sign transaction: %w", err)
	}

	// 7. 전송
	if err := s.client.SendTransaction(ctx, signedTx); err != nil {
		return common.Hash{}, fmt.Errorf("failed to send transaction: %w", err)
	}

	txHash := signedTx.Hash()

	fmt.Printf("✅ Transaction submitted: %s\n", txHash.Hex())
	fmt.Printf("   Waiting for confirmation...\n")

	// 8. Receipt 대기 (optional)
	receipt, err := bind.WaitMined(ctx, s.client, signedTx)
	if err != nil {
		return txHash, fmt.Errorf("failed to wait for receipt: %w", err)
	}

	if receipt.Status == types.ReceiptStatusSuccessful {
		fmt.Printf("✅ Transaction confirmed in block %d\n", receipt.BlockNumber.Uint64())
		fmt.Printf("   Gas Used: %d\n", receipt.GasUsed)
	} else {
		return txHash, fmt.Errorf("transaction failed: %s", txHash.Hex())
	}

	return txHash, nil
}

// WithdrawalTransaction Solidity struct 매핑
type WithdrawalTransaction struct {
	Nonce    *big.Int
	Sender   common.Address
	Target   common.Address
	Value    *big.Int
	GasLimit *big.Int
	Data     []byte
}

// OutputRootProof Solidity struct 매핑
type OutputRootProof struct {
	Version                  [32]byte
	StateRoot                [32]byte
	MessagePasserStorageRoot [32]byte
	LatestBlockhash          [32]byte
}

// FastWithdrawalInput Solidity struct 매핑
type FastWithdrawalInput struct {
	RequestId       [32]byte
	GameIndex       *big.Int
	OutputRoot      [32]byte
	WithdrawalHash  [32]byte
	WithdrawalProof [][32]byte
	L2OutputIndex   *big.Int
	OutputRootProof OutputRootProof
	ValidatorBitmap *big.Int
}

// buildCalldata verifyAndExecuteFastWithdrawal 호출을 위한 calldata 구성
func (s *L1Submitter) buildCalldata(
	state *aggTypes.RequestState,
	aggregatedSignature []byte,
	validatorBitmap *big.Int,
) []byte {
	req := state.Request

	// 1. WithdrawalTransaction 구성
	withdrawalTx := WithdrawalTransaction{
		Nonce:    req.WithdrawalTx.Nonce,
		Sender:   req.WithdrawalTx.Sender,
		Target:   req.WithdrawalTx.Target,
		Value:    req.WithdrawalTx.Value,
		GasLimit: req.WithdrawalTx.GasLimit,
		Data:     req.WithdrawalTx.Data,
	}

	// Handle nil values
	if withdrawalTx.Nonce == nil {
		withdrawalTx.Nonce = big.NewInt(0)
	}
	if withdrawalTx.Value == nil {
		withdrawalTx.Value = big.NewInt(0)
	}
	if withdrawalTx.GasLimit == nil {
		withdrawalTx.GasLimit = big.NewInt(100000)
	}

	// 2. FastWithdrawalInput 구성
	// TODO: 실제 OutputRootProof와 WithdrawalProof는 L2에서 조회 필요
	input := FastWithdrawalInput{
		RequestId:       req.RequestID,
		GameIndex:       req.GameIndex,
		OutputRoot:      req.OutputRoot,
		WithdrawalHash:  [32]byte{}, // TODO: 계산 필요
		WithdrawalProof: [][32]byte{},
		L2OutputIndex:   big.NewInt(0),
		OutputRootProof: OutputRootProof{},
		ValidatorBitmap: validatorBitmap,
	}

	if input.GameIndex == nil {
		input.GameIndex = big.NewInt(0)
	}

	// 3. ABI 인코딩
	calldata, err := s.abi.Pack(
		"verifyAndExecuteFastWithdrawal",
		withdrawalTx,
		input,
		aggregatedSignature,
	)
	if err != nil {
		fmt.Printf("⚠️  Failed to pack calldata: %v\n", err)
		// Fallback: 빈 calldata 반환 (트랜잭션은 실패할 것)
		return make([]byte, 4)
	}

	fmt.Printf("✅ Calldata built: %d bytes\n", len(calldata))

	return calldata
}

// EstimateGas 가스 예측
func (s *L1Submitter) EstimateGas(
	ctx context.Context,
	state *aggTypes.RequestState,
	aggregatedSignature []byte,
	validatorBitmap *big.Int,
) (uint64, error) {

	calldata := s.buildCalldata(state, aggregatedSignature, validatorBitmap)

	msg := ethereum.CallMsg{
		From: s.fromAddress,
		To:   &s.ratContract,
		Data: calldata,
	}

	gasLimit, err := s.client.EstimateGas(ctx, msg)
	if err != nil {
		return 0, fmt.Errorf("failed to estimate gas: %w", err)
	}

	// 10% 버퍼 추가
	gasLimit = gasLimit * 110 / 100

	return gasLimit, nil
}

// GetBalance 계정 잔액 조회
func (s *L1Submitter) GetBalance(ctx context.Context) (*big.Int, error) {
	return s.client.BalanceAt(ctx, s.fromAddress, nil)
}
