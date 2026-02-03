package main

import (
	"context"
	"flag"
	"fmt"
	"math/big"
	"os"
	"os/signal"
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

// Aggregator 메인 서비스 구조체
type Aggregator struct {
	cfg *config.Config

	// Clients
	l1Client       *ethclient.Client
	ratContract    *contracts.RATContract
	l2ProofProvider *l2proof.L2ProofProvider

	// Components
	network       *p2p.AggregatorNetwork
	l1Monitor     *monitor.L1Monitor
	sigCollector  *collector.SignatureCollector
	blsAggregator *collector.BLSAggregator
	l1Submitter   *submitter.L1Submitter

	// Validator set (from RAT contract)
	validatorSet []common.Address

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
	ratContract, err := contracts.NewRATContract(l1Client, common.HexToAddress(cfg.L1.RATContract))
	if err != nil {
		cancel()
		l1Client.Close()
		return nil, fmt.Errorf("failed to initialize RAT contract: %w", err)
	}
	agg.ratContract = ratContract

	fmt.Printf("✅ RAT Contract initialized: %s\n", cfg.L1.RATContract)

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

	// 7. Validator set 로드 (TODO: 실제로는 RAT 컨트랙트에서 조회)
	agg.validatorSet = agg.loadValidatorSet()

	fmt.Printf("✅ Validator set loaded: %d validators\n", len(agg.validatorSet))

	return agg, nil
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
	fmt.Printf("   RequestID: %x\n", event.RequestID[:8])
	fmt.Printf("   User: %s\n", event.User.Hex())
	fmt.Printf("   Amount: %s\n", event.Amount.String())
	fmt.Printf("   Block: %d\n", event.BlockNumber)

	// 1. Validator set 확인
	if len(agg.validatorSet) < agg.cfg.FastWithdrawal.MinValidators {
		fmt.Printf("❌ Not enough validators: %d < %d\n",
			len(agg.validatorSet),
			agg.cfg.FastWithdrawal.MinValidators)
		return
	}

	// 2. SignatureRequest 생성
	chainID, err := agg.l1Client.ChainID(agg.ctx)
	if err != nil {
		fmt.Printf("❌ Failed to get chain ID: %v\n", err)
		return
	}

	deadline := uint64(time.Now().Unix()) + uint64(agg.cfg.FastWithdrawal.ResponseTimeout)

	req := &types.SignatureRequest{
		RequestID:   event.RequestID,
		User:        event.User,
		Amount:      event.Amount,
		ChainID:     chainID,
		Deadline:    deadline,
		RollupType:  event.RollupType,
		GameIndex:   event.GameIndex,
		OutputRoot:  event.OutputRoot,
		BlockNumber: event.L2BlockNum,
	}

	// 3. Collector에 요청 등록
	if err := agg.sigCollector.StartRequest(req, agg.validatorSet); err != nil {
		fmt.Printf("❌ Failed to start signature collection: %v\n", err)
		return
	}

	// 4. Validators에게 서명 요청 브로드캐스트
	if err := agg.network.BroadcastRequest(agg.ctx, req); err != nil {
		fmt.Printf("❌ Failed to broadcast request: %v\n", err)
		return
	}

	fmt.Printf("✅ Signature request broadcasted to %d validators\n", len(agg.validatorSet))
	fmt.Printf("   Deadline: %s\n", time.Unix(int64(deadline), 0).Format(time.RFC3339))
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
func (agg *Aggregator) loadValidatorSet() []common.Address {
	ctx, cancel := context.WithTimeout(agg.ctx, 30*time.Second)
	defer cancel()

	// RAT 컨트랙트에서 활성 검증자 조회
	validators, err := agg.ratContract.GetActiveValidators(ctx)
	if err != nil {
		fmt.Printf("⚠️  Failed to load validators from RAT contract: %v\n", err)
		fmt.Printf("⚠️  Using mock validator set as fallback\n")

		// Fallback: Mock validators
		return []common.Address{
			common.HexToAddress("0x0000000000000000000000000000000000000001"),
			common.HexToAddress("0x0000000000000000000000000000000000000002"),
			common.HexToAddress("0x0000000000000000000000000000000000000003"),
		}
	}

	// BLS 공개키가 등록된 검증자만 필터링
	validValidators := make([]common.Address, 0, len(validators))
	for _, validator := range validators {
		pubKey, err := agg.ratContract.GetBLSPublicKey(ctx, validator)
		if err != nil {
			fmt.Printf("⚠️  Validator %s has no BLS key: %v\n", validator.Hex()[:10], err)
			continue
		}
		if len(pubKey) == 0 {
			fmt.Printf("⚠️  Validator %s has empty BLS key\n", validator.Hex()[:10])
			continue
		}
		validValidators = append(validValidators, validator)
	}

	fmt.Printf("✅ Loaded %d validators with BLS keys (total: %d)\n", len(validValidators), len(validators))

	return validValidators
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
			newSet := agg.loadValidatorSet()
			if len(newSet) > 0 {
				agg.validatorSet = newSet
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
