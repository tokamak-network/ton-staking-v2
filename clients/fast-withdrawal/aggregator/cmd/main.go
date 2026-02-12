package main

import (
	"bytes"
	"context"
	"flag"
	"fmt"
	"math/big"
	"os"
	"os/signal"
	"sort"
	"syscall"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"

	"github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/aggregator/pkg/collector"
	"github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/aggregator/pkg/config"
	"github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/aggregator/pkg/contracts"
	"github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/aggregator/pkg/l2proof"
	"github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/aggregator/pkg/monitor"
	"github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/aggregator/pkg/p2p"
	"github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/aggregator/pkg/submitter"
	"github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/aggregator/pkg/types"
)

var (
	configPath = flag.String("config", "config.yaml", "Path to config file")
	startBlock = flag.Int64("start-block", 0, "Start block for L1 monitoring (0 = latest)")
	version    = "0.1.0"
)

// fallbackDelay Aggregator 인계 대기 시간 (priority 1당 30초)
const fallbackDelay = 30 * time.Second

// Aggregator 메인 서비스 구조체
type Aggregator struct {
	cfg *config.Config

	// Clients
	l1Client        *ethclient.Client
	ratContract     *contracts.RATContract
	l2ProofProvider *l2proof.L2ProofProvider

	// Components
	network       *p2p.AggregatorNetwork
	l1Monitor     *monitor.L1Monitor
	sigCollector  *collector.SignatureCollector
	blsAggregator *collector.BLSAggregator
	l1Submitter   *submitter.L1Submitter

	// Validator set (from RAT contract)
	validatorSet     []common.Address
	sortedValidators []common.Address // 주소순 정렬 (round-robin용)
	myAddress        common.Address   // 이 노드의 validator 주소
	myValidatorIndex int              // 정렬된 목록에서의 인덱스 (-1이면 미포함)

	// Context
	ctx    context.Context
	cancel context.CancelFunc
}

func main() {
	flag.Parse()

	fmt.Printf("🚀 Fast Withdrawal Aggregator v%s\n", version)
	fmt.Printf("================================================\n\n")

	// 1. Config 로드
	cfg, err := config.LoadConfig(*configPath)
	if err != nil {
		fmt.Printf("❌ Failed to load config: %v\n", err)
		os.Exit(1)
	}

	if err := cfg.Validate(); err != nil {
		fmt.Printf("❌ Invalid config: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("✅ Config loaded successfully\n")

	// 2. Aggregator 초기화
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	agg, err := NewAggregator(ctx, cfg)
	if err != nil {
		fmt.Printf("❌ Failed to initialize aggregator: %v\n", err)
		os.Exit(1)
	}
	defer agg.Close()

	// 3. 서비스 시작
	var startBlockNum *big.Int
	if *startBlock > 0 {
		startBlockNum = big.NewInt(*startBlock)
	}

	if err := agg.Start(startBlockNum); err != nil {
		fmt.Printf("❌ Failed to start aggregator: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("\n================================================\n")
	fmt.Printf("✅ Aggregator is running!\n")
	fmt.Printf("   Address: %s\n", cfg.Aggregator.Address)
	fmt.Printf("   PeerID: %s\n", agg.network.PeerID())
	fmt.Printf("   RAT Contract: %s\n", cfg.L1.RATContract)
	fmt.Printf("\n💡 Press Ctrl+C to stop\n")
	fmt.Printf("================================================\n\n")

	// 4. Signal 대기
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)

	<-sigCh

	fmt.Printf("\n\n🛑 Shutting down...\n")
	cancel()
	fmt.Printf("✅ Aggregator stopped\n")
}

// NewAggregator 새로운 Aggregator 생성
func NewAggregator(ctx context.Context, cfg *config.Config) (*Aggregator, error) {
	childCtx, cancel := context.WithCancel(ctx)

	agg := &Aggregator{
		cfg:    cfg,
		ctx:    childCtx,
		cancel: cancel,
	}

	// 1. L1 Client 연결
	l1Client, err := ethclient.Dial(cfg.L1.RPC)
	if err != nil {
		cancel()
		return nil, fmt.Errorf("failed to connect to L1: %w", err)
	}
	agg.l1Client = l1Client

	fmt.Printf("✅ Connected to L1: %s\n", cfg.L1.RPC)

	// 1.5. RAT Contract 초기화
	ratContract, err := contracts.NewRATContract(
		l1Client,
		common.HexToAddress(cfg.L1.RATContract),
		common.HexToAddress(cfg.L1.SystemConfig),
	)
	if err != nil {
		cancel()
		l1Client.Close()
		return nil, fmt.Errorf("failed to initialize RAT contract: %w", err)
	}
	agg.ratContract = ratContract

	fmt.Printf("✅ RAT Contract initialized: %s\n", cfg.L1.RATContract)
	fmt.Printf("   SystemConfig: %s\n", cfg.L1.SystemConfig)

	// 1.6. L2 Proof Provider 초기화 (optional)
	if cfg.L2.RPC != "" {
		l2Provider, err := l2proof.NewL2ProofProvider(cfg.L2.RPC)
		if err != nil {
			fmt.Printf("⚠️  Failed to initialize L2 proof provider: %v\n", err)
			fmt.Printf("   Fast withdrawal proof generation will be disabled\n")
		} else {
			agg.l2ProofProvider = l2Provider
			fmt.Printf("✅ L2 Proof Provider initialized: %s\n", cfg.L2.RPC)
		}
	} else {
		fmt.Printf("⚠️  L2 RPC not configured, proof generation disabled\n")
	}

	// 2. libp2p 네트워크 초기화
	network, err := p2p.NewAggregatorNetwork(childCtx, &p2p.Config{
		ListenAddr:      cfg.P2P.ListenAddr,
		BootstrapPeers:  cfg.P2P.BootstrapPeers,
		DHTNamespace:    cfg.P2P.DHTNamespace,
		WithdrawalTopic: cfg.P2P.WithdrawalTopic,
		AggregatorAddr:  common.HexToAddress(cfg.Aggregator.Address),
		SystemConfig:    cfg.L1.SystemConfig,
	})
	if err != nil {
		cancel()
		l1Client.Close()
		return nil, fmt.Errorf("failed to initialize p2p network: %w", err)
	}
	agg.network = network

	// 3. L1 Monitor 초기화
	l1Monitor, err := monitor.NewL1Monitor(&monitor.Config{
		Client:      l1Client,
		RATContract: common.HexToAddress(cfg.L1.RATContract),
	})
	if err != nil {
		cancel()
		network.Close()
		l1Client.Close()
		return nil, fmt.Errorf("failed to initialize L1 monitor: %w", err)
	}
	agg.l1Monitor = l1Monitor

	fmt.Printf("✅ L1 Monitor initialized\n")

	// 4. Signature Collector 초기화
	agg.sigCollector = collector.NewSignatureCollector()

	fmt.Printf("✅ Signature Collector initialized\n")

	// 5. BLS Aggregator 초기화
	agg.blsAggregator = collector.NewBLSAggregator()

	fmt.Printf("✅ BLS Aggregator initialized\n")

	// 6. L1 Submitter 초기화
	l1Sub, err := submitter.NewL1Submitter(&submitter.Config{
		Client:      l1Client,
		RATContract: common.HexToAddress(cfg.L1.RATContract),
		PrivateKey:  cfg.Aggregator.PrivateKey,
		MaxGasPrice: big.NewInt(int64(cfg.FastWithdrawal.MaxGasPrice) * 1e9), // gwei to wei
		GasLimit:    uint64(cfg.FastWithdrawal.SubmissionGasLimit),
	})
	if err != nil {
		cancel()
		network.Close()
		l1Client.Close()
		return nil, fmt.Errorf("failed to initialize L1 submitter: %w", err)
	}
	agg.l1Submitter = l1Sub

	// 7. Validator set 로드 (RAT 컨트랙트에서 조회)
	validatorSet, err := agg.loadValidatorSet()
	if err != nil {
		cancel()
		network.Close()
		l1Client.Close()
		return nil, fmt.Errorf("failed to load validator set: %w", err)
	}
	agg.validatorSet = validatorSet

	// Round-robin용 정렬 및 자기 인덱스 계산
	agg.myAddress = common.HexToAddress(cfg.Aggregator.Address)
	agg.updateSortedValidators()

	return agg, nil
}

// updateSortedValidators validator set을 주소순 정렬하고 자기 인덱스를 계산
func (agg *Aggregator) updateSortedValidators() {
	sorted := make([]common.Address, len(agg.validatorSet))
	copy(sorted, agg.validatorSet)
	sort.Slice(sorted, func(i, j int) bool {
		return bytes.Compare(sorted[i].Bytes(), sorted[j].Bytes()) < 0
	})
	agg.sortedValidators = sorted

	agg.myValidatorIndex = -1
	for i, addr := range sorted {
		if addr == agg.myAddress {
			agg.myValidatorIndex = i
			break
		}
	}

	if agg.myValidatorIndex >= 0 {
		fmt.Printf("📋 Round-robin: my index = %d/%d in sorted validator set\n",
			agg.myValidatorIndex, len(sorted))
	} else {
		fmt.Printf("⚠️  My address %s not found in validator set\n", agg.myAddress.Hex())
	}
}

// Start Aggregator 서비스 시작
func (agg *Aggregator) Start(startBlock *big.Int) error {
	// 1. 핸들러 설정

	// L1 Monitor: 출금 요청 이벤트 처리
	agg.l1Monitor.SetWithdrawalRequestHandler(agg.handleWithdrawalRequest)

	// Network: 서명 응답 처리
	agg.network.SetResponseHandler(agg.handleSignatureResponse)

	// Collector: 만장일치 달성 시 처리
	agg.sigCollector.SetCompleteCallback(agg.handleUnanimousConsensus)

	// 2. 컴포넌트 시작

	// L1 Monitor 시작
	if err := agg.l1Monitor.Start(agg.ctx, startBlock); err != nil {
		return fmt.Errorf("failed to start L1 monitor: %w", err)
	}

	// Network 시작 (서명 응답 수신)
	if err := agg.network.Start(agg.ctx); err != nil {
		return fmt.Errorf("failed to start network: %w", err)
	}

	// Collector cleanup 루프 시작
	go agg.sigCollector.StartCleanupLoop(agg.ctx, 60*time.Second)

	// Validator set 주기적 갱신
	go agg.refreshValidatorSet()

	// Stats 출력 루프 시작
	go agg.statsLoop()

	return nil
}

// handleWithdrawalRequest L1에서 감지된 출금 요청 처리
func (agg *Aggregator) handleWithdrawalRequest(event *monitor.FastWithdrawalEvent) {
	fmt.Printf("\n📨 New Fast Withdrawal Request detected!\n")
	fmt.Printf("   WithdrawalHash: %x\n", event.WithdrawalHash[:8])
	fmt.Printf("   User: %s\n", event.User.Hex())
	fmt.Printf("   Amount: %s\n", event.Amount.String())
	fmt.Printf("   Fee: %s\n", event.Fee.String())
	fmt.Printf("   Deadline: %d\n", event.Deadline)
	fmt.Printf("   Block: %d\n", event.BlockNumber)

	// 1. Validator set 확인
	n := len(agg.sortedValidators)
	if n < agg.cfg.FastWithdrawal.MinValidators {
		fmt.Printf("❌ Not enough validators: %d < %d\n",
			n, agg.cfg.FastWithdrawal.MinValidators)
		return
	}

	if agg.myValidatorIndex < 0 {
		fmt.Printf("⚠️  My address not in validator set, skipping aggregation\n")
		return
	}

	// 2. Round-robin: 블록 번호 기반으로 이번 차례 결정
	selectedIdx := int(event.BlockNumber % uint64(n))
	selectedAddr := agg.sortedValidators[selectedIdx]
	myPriority := (agg.myValidatorIndex - selectedIdx + n) % n

	if myPriority > 0 {
		// 내 차례가 아님 → 타임아웃 후 인계 대기
		delay := time.Duration(myPriority) * fallbackDelay
		fmt.Printf("⏳ Not my turn (block %d → validator[%d] = %s)\n",
			event.BlockNumber, selectedIdx, selectedAddr.Hex()[:10])
		fmt.Printf("   My priority: %d, fallback in %v\n", myPriority, delay)
		go agg.fallbackAggregation(event, delay)
		return
	}

	// 내 차례!
	fmt.Printf("🎯 My turn to aggregate! (block %d → validator[%d] = %s)\n",
		event.BlockNumber, selectedIdx, selectedAddr.Hex()[:10])
	agg.executeAggregation(event)
}

// executeAggregation 실제 aggregation 실행 (서명 수집 시작 + 브로드캐스트)
func (agg *Aggregator) executeAggregation(event *monitor.FastWithdrawalEvent) {
	// 1. SignatureRequest 생성
	chainID, err := agg.l1Client.ChainID(agg.ctx)
	if err != nil {
		fmt.Printf("❌ Failed to get chain ID: %v\n", err)
		return
	}

	req := &types.SignatureRequest{
		RequestID:  event.WithdrawalHash,
		User:       event.User,
		Amount:     event.Amount,
		ChainID:    chainID,
		Deadline:   event.Deadline,
		RollupType: 3, // Type 3: OPTIMISM_BEDROCK_WITH_DISPUTE_GAME
		GameIndex:  event.GameIndex,
		OutputRoot: event.OutputRoot,
	}

	// 2. Collector에 요청 등록
	if err := agg.sigCollector.StartRequest(req, agg.validatorSet); err != nil {
		fmt.Printf("❌ Failed to start signature collection: %v\n", err)
		return
	}

	// 3. Validators에게 서명 요청 브로드캐스트
	if err := agg.network.BroadcastRequest(agg.ctx, req); err != nil {
		fmt.Printf("❌ Failed to broadcast request: %v\n", err)
		return
	}

	fmt.Printf("✅ Signature request broadcasted to %d validators\n", len(agg.validatorSet))
	fmt.Printf("   Deadline: %s\n", time.Unix(int64(event.Deadline), 0).Format(time.RFC3339))
}

// fallbackAggregation 선출된 aggregator가 처리하지 않을 경우 인계
func (agg *Aggregator) fallbackAggregation(event *monitor.FastWithdrawalEvent, delay time.Duration) {
	select {
	case <-time.After(delay):
		// 이미 이 노드에서 처리 중인지 확인
		if _, exists := agg.sigCollector.GetState(event.WithdrawalHash); exists {
			fmt.Printf("⏭️  Request %x already in progress, skipping fallback\n",
				event.WithdrawalHash[:8])
			return
		}
		// 기한 초과 확인
		if time.Now().Unix() > int64(event.Deadline) {
			fmt.Printf("⏭️  Request %x expired, skipping fallback\n",
				event.WithdrawalHash[:8])
			return
		}
		fmt.Printf("🔄 Primary aggregator timed out, taking over for %x\n",
			event.WithdrawalHash[:8])
		agg.executeAggregation(event)
	case <-agg.ctx.Done():
		return
	}
}

// handleSignatureResponse Validator로부터 받은 서명 응답 처리
func (agg *Aggregator) handleSignatureResponse(ctx context.Context, resp *types.SignatureResponse) error {
	fmt.Printf("📥 Received signature from %s\n", resp.Validator.Hex()[:10])

	// Collector에 서명 추가
	if err := agg.sigCollector.AddSignature(resp); err != nil {
		fmt.Printf("⚠️  Failed to add signature: %v\n", err)
		return err
	}

	return nil
}

// handleUnanimousConsensus 만장일치 달성 시 L1 제출
func (agg *Aggregator) handleUnanimousConsensus(requestID [32]byte, state *types.RequestState) {
	fmt.Printf("\n🎉 UNANIMOUS CONSENSUS REACHED!\n")
	fmt.Printf("   RequestID: %x\n", requestID[:8])
	fmt.Printf("   Signatures: %d/%d\n", state.ReceivedCount, state.RequiredCount)

	// 1. BLS 서명 집약
	aggregatedSig, bitmap, err := agg.blsAggregator.AggregateSignatures(state)
	if err != nil {
		fmt.Printf("❌ Failed to aggregate signatures: %v\n", err)
		return
	}

	fmt.Printf("✅ Signatures aggregated\n")
	fmt.Printf("   Bitmap: %d\n", bitmap)

	// 2. L1에 트랜잭션 제출
	txHash, err := agg.l1Submitter.SubmitFastWithdrawal(
		agg.ctx,
		state,
		aggregatedSig,
		bitmap,
	)
	if err != nil {
		fmt.Printf("❌ Failed to submit to L1: %v\n", err)
		// TODO: 재시도 로직
		return
	}

	state.SubmittedTxHash = txHash

	fmt.Printf("✅ Fast Withdrawal executed!\n")
	fmt.Printf("   TxHash: %s\n", txHash.Hex())

	// 3. 완료된 요청 정리
	agg.sigCollector.RemoveRequest(requestID)
}

// loadValidatorSet Validator set 로드 (RAT 컨트랙트에서 조회)
func (agg *Aggregator) loadValidatorSet() ([]common.Address, error) {
	ctx, cancel := context.WithTimeout(agg.ctx, 30*time.Second)
	defer cancel()

	// RAT 컨트랙트에서 활성 검증자 + BLS 키 일괄 조회
	validatorInfos, err := agg.ratContract.GetActiveValidatorsWithBLS(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to load validators from RAT contract: %w", err)
	}

	validators := make([]common.Address, len(validatorInfos))
	for i, info := range validatorInfos {
		validators[i] = info.Address
	}

	fmt.Printf("✅ Loaded %d validators with BLS keys from RAT contract\n", len(validators))
	for _, info := range validatorInfos {
		fmt.Printf("   Validator: %s (BLS key: %d bytes)\n", info.Address.Hex(), len(info.BLSPublicKey))
	}

	return validators, nil
}

// refreshValidatorSet Validator set 주기적 갱신
func (agg *Aggregator) refreshValidatorSet() {
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()

	for {
		select {
		case <-agg.ctx.Done():
			return
		case <-ticker.C:
			newSet, err := agg.loadValidatorSet()
			if err != nil {
				fmt.Printf("⚠️  Failed to refresh validator set: %v\n", err)
				continue
			}
			if len(newSet) > 0 {
				agg.validatorSet = newSet
				agg.updateSortedValidators()
				fmt.Printf("🔄 Validator set refreshed: %d validators\n", len(newSet))
			}
		}
	}
}

// statsLoop 주기적 상태 출력
func (agg *Aggregator) statsLoop() {
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-agg.ctx.Done():
			return
		case <-ticker.C:
			stats := agg.sigCollector.Stats()
			peerCount := agg.network.PeerCount()

			fmt.Printf("📊 Stats: peers=%d, pending=%d, completed=%d\n",
				peerCount,
				stats["pending"],
				stats["completed"])
		}
	}
}

// Close Aggregator 종료
func (agg *Aggregator) Close() error {
	agg.cancel()

	if agg.network != nil {
		if err := agg.network.Close(); err != nil {
			fmt.Printf("Warning: failed to close network: %v\n", err)
		}
	}

	if agg.l2ProofProvider != nil {
		agg.l2ProofProvider.Close()
	}

	if agg.l1Client != nil {
		agg.l1Client.Close()
	}

	return nil
}
