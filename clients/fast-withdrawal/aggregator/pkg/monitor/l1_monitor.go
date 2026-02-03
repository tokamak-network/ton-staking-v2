package monitor

import (
	"context"
	"fmt"
	"math/big"
	"strings"
	"time"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
)

// FastWithdrawalRequested 이벤트 ABI
// event FastWithdrawalRequested(
//
//	bytes32 indexed requestId,
//	address indexed user,
//	uint256 amount,
//	uint8 rollupType,
//	uint256 gameIndex,
//	bytes32 outputRoot,
//	uint256 l2BlockNumber,
//	uint256 timestamp
//
// );
const fastWithdrawalEventABI = `[{
	"anonymous": false,
	"inputs": [
		{"indexed": true, "internalType": "bytes32", "name": "requestId", "type": "bytes32"},
		{"indexed": true, "internalType": "address", "name": "user", "type": "address"},
		{"indexed": false, "internalType": "uint256", "name": "amount", "type": "uint256"},
		{"indexed": false, "internalType": "uint8", "name": "rollupType", "type": "uint8"},
		{"indexed": false, "internalType": "uint256", "name": "gameIndex", "type": "uint256"},
		{"indexed": false, "internalType": "bytes32", "name": "outputRoot", "type": "bytes32"},
		{"indexed": false, "internalType": "uint256", "name": "l2BlockNumber", "type": "uint256"},
		{"indexed": false, "internalType": "uint256", "name": "timestamp", "type": "uint256"}
	],
	"name": "FastWithdrawalRequested",
	"type": "event"
}]`

var (
	// FastWithdrawalRequested event signature
	// keccak256("FastWithdrawalRequested(bytes32,address,uint256,uint8,uint256,bytes32,uint256,uint256)")
	fastWithdrawalRequestedTopic = crypto.Keccak256Hash(
		[]byte("FastWithdrawalRequested(bytes32,address,uint256,uint8,uint256,bytes32,uint256,uint256)"),
	)
)

// L1Monitor L1 이벤트 모니터
type L1Monitor struct {
	client      *ethclient.Client
	ratContract common.Address
	abi         abi.ABI

	// 이벤트 핸들러
	onWithdrawalRequest func(*FastWithdrawalEvent)
}

// FastWithdrawalEvent Fast Withdrawal 이벤트
type FastWithdrawalEvent struct {
	RequestID   [32]byte
	User        common.Address
	Amount      *big.Int
	Timestamp   uint64
	BlockNumber uint64
	TxHash      common.Hash

	// Type3 specific
	RollupType uint8
	GameIndex  *big.Int
	OutputRoot [32]byte
	L2BlockNum uint64

	// Raw event data
	Raw types.Log
}

// Config L1Monitor 설정
type Config struct {
	Client      *ethclient.Client
	RATContract common.Address
	StartBlock  *big.Int // nil이면 latest
}

// NewL1Monitor 새로운 L1 모니터 생성
func NewL1Monitor(cfg *Config) (*L1Monitor, error) {
	if cfg.Client == nil {
		return nil, fmt.Errorf("L1 client is required")
	}

	// ABI 파싱
	parsedABI, err := abi.JSON(strings.NewReader(fastWithdrawalEventABI))
	if err != nil {
		return nil, fmt.Errorf("failed to parse event ABI: %w", err)
	}

	return &L1Monitor{
		client:      cfg.Client,
		ratContract: cfg.RATContract,
		abi:         parsedABI,
	}, nil
}

// SetWithdrawalRequestHandler 출금 요청 핸들러 설정
func (m *L1Monitor) SetWithdrawalRequestHandler(handler func(*FastWithdrawalEvent)) {
	m.onWithdrawalRequest = handler
}

// Start 이벤트 모니터링 시작
func (m *L1Monitor) Start(ctx context.Context, startBlock *big.Int) error {
	if m.onWithdrawalRequest == nil {
		return fmt.Errorf("withdrawal request handler not set")
	}

	fmt.Printf("🔍 Starting L1 event monitor...\n")
	fmt.Printf("   RAT Contract: %s\n", m.ratContract.Hex())

	// 현재 블록 조회
	currentBlock, err := m.client.BlockNumber(ctx)
	if err != nil {
		return fmt.Errorf("failed to get current block: %w", err)
	}

	if startBlock == nil {
		startBlock = new(big.Int).SetUint64(currentBlock)
	}

	fmt.Printf("   Starting from block: %s\n", startBlock.String())
	fmt.Printf("   Current block: %d\n", currentBlock)

	// 이벤트 구독
	go m.subscribeLoop(ctx, startBlock)

	return nil
}

// subscribeLoop 이벤트 구독 루프
func (m *L1Monitor) subscribeLoop(ctx context.Context, fromBlock *big.Int) {
	ticker := time.NewTicker(12 * time.Second) // Ethereum block time
	defer ticker.Stop()

	lastProcessedBlock := new(big.Int).Set(fromBlock)

	for {
		select {
		case <-ctx.Done():
			fmt.Printf("🛑 L1 monitor stopped\n")
			return

		case <-ticker.C:
			// 최신 블록까지 이벤트 쿼리
			currentBlock, err := m.client.BlockNumber(ctx)
			if err != nil {
				fmt.Printf("⚠️  Failed to get current block: %v\n", err)
				continue
			}

			toBlock := new(big.Int).SetUint64(currentBlock)

			// 새로운 블록이 있으면 처리
			if toBlock.Cmp(lastProcessedBlock) > 0 {
				if err := m.processBlocks(ctx, lastProcessedBlock, toBlock); err != nil {
					fmt.Printf("⚠️  Failed to process blocks: %v\n", err)
					continue
				}

				lastProcessedBlock = toBlock
			}
		}
	}
}

// processBlocks 블록 범위의 이벤트 처리
func (m *L1Monitor) processBlocks(ctx context.Context, fromBlock, toBlock *big.Int) error {
	// FastWithdrawalRequested 이벤트만 필터링
	query := ethereum.FilterQuery{
		FromBlock: fromBlock,
		ToBlock:   toBlock,
		Addresses: []common.Address{m.ratContract},
		Topics:    [][]common.Hash{{fastWithdrawalRequestedTopic}},
	}

	logs, err := m.client.FilterLogs(ctx, query)
	if err != nil {
		return fmt.Errorf("failed to filter logs: %w", err)
	}

	if len(logs) > 0 {
		fmt.Printf("📬 Found %d events in blocks %s-%s\n", len(logs), fromBlock.String(), toBlock.String())
	}

	for _, log := range logs {
		event, err := m.parseEvent(&log)
		if err != nil {
			fmt.Printf("⚠️  Failed to parse event: %v\n", err)
			continue
		}

		if event != nil && m.onWithdrawalRequest != nil {
			fmt.Printf("📨 FastWithdrawalRequested:\n")
			fmt.Printf("   RequestID: %x\n", event.RequestID[:8])
			fmt.Printf("   User: %s\n", event.User.Hex())
			fmt.Printf("   Amount: %s\n", event.Amount.String())
			fmt.Printf("   Block: %d\n", event.BlockNumber)

			m.onWithdrawalRequest(event)
		}
	}

	return nil
}

// FastWithdrawalRequestedData non-indexed 이벤트 데이터
type FastWithdrawalRequestedData struct {
	Amount        *big.Int
	RollupType    uint8
	GameIndex     *big.Int
	OutputRoot    [32]byte
	L2BlockNumber *big.Int
	Timestamp     *big.Int
}

// parseEvent 로그를 이벤트로 파싱
func (m *L1Monitor) parseEvent(log *types.Log) (*FastWithdrawalEvent, error) {
	// Topic 검증
	if len(log.Topics) < 3 {
		return nil, nil // FastWithdrawalRequested 이벤트가 아님
	}

	// Topic[0] == event signature 확인
	if log.Topics[0] != fastWithdrawalRequestedTopic {
		return nil, nil // 다른 이벤트
	}

	// 기본 이벤트 구조체 생성
	event := &FastWithdrawalEvent{
		BlockNumber: log.BlockNumber,
		TxHash:      log.TxHash,
		Raw:         *log,
	}

	// Topic[1]: requestId (indexed bytes32)
	copy(event.RequestID[:], log.Topics[1].Bytes())

	// Topic[2]: user (indexed address)
	event.User = common.BytesToAddress(log.Topics[2].Bytes())

	// Non-indexed 데이터 ABI 디코딩
	if len(log.Data) > 0 {
		var data FastWithdrawalRequestedData
		err := m.abi.UnpackIntoInterface(&data, "FastWithdrawalRequested", log.Data)
		if err != nil {
			// ABI 디코딩 실패 시 수동 파싱 시도
			return m.parseEventManual(log, event)
		}

		event.Amount = data.Amount
		event.RollupType = data.RollupType
		event.GameIndex = data.GameIndex
		event.OutputRoot = data.OutputRoot
		event.L2BlockNum = data.L2BlockNumber.Uint64()
		event.Timestamp = data.Timestamp.Uint64()
	} else {
		// Data가 없으면 기본값 사용
		event.Amount = big.NewInt(0)
		event.RollupType = 3
		event.GameIndex = big.NewInt(0)
		event.L2BlockNum = 0
		event.Timestamp = uint64(time.Now().Unix())
	}

	return event, nil
}

// parseEventManual 수동 이벤트 파싱 (ABI 디코딩 실패 시 fallback)
func (m *L1Monitor) parseEventManual(log *types.Log, event *FastWithdrawalEvent) (*FastWithdrawalEvent, error) {
	data := log.Data

	// 최소 데이터 길이 확인 (6 * 32 bytes = 192 bytes)
	if len(data) < 192 {
		return nil, fmt.Errorf("insufficient data length: %d", len(data))
	}

	// amount (uint256) - offset 0
	event.Amount = new(big.Int).SetBytes(data[0:32])

	// rollupType (uint8) - offset 32 (마지막 1 byte)
	event.RollupType = data[63]

	// gameIndex (uint256) - offset 64
	event.GameIndex = new(big.Int).SetBytes(data[64:96])

	// outputRoot (bytes32) - offset 96
	copy(event.OutputRoot[:], data[96:128])

	// l2BlockNumber (uint256) - offset 128
	l2BlockNum := new(big.Int).SetBytes(data[128:160])
	event.L2BlockNum = l2BlockNum.Uint64()

	// timestamp (uint256) - offset 160
	timestamp := new(big.Int).SetBytes(data[160:192])
	event.Timestamp = timestamp.Uint64()

	return event, nil
}

// GetLatestBlock 최신 블록 번호 조회
func (m *L1Monitor) GetLatestBlock(ctx context.Context) (uint64, error) {
	return m.client.BlockNumber(ctx)
}
