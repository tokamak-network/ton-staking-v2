package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"os/signal"
	"syscall"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"

	"github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/validator/pkg/config"
	"github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/validator/pkg/handler"
	"github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/validator/pkg/p2p"
	"github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/validator/pkg/signer"
	"github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/validator/pkg/verifier"
)

var (
	configPath = flag.String("config", "config.yaml", "Path to config file")
	version    = "0.1.0"
)

func main() {
	flag.Parse()

	fmt.Printf("🚀 Fast Withdrawal Validator v%s\n", version)
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

	// 2. BLS Signer 초기화
	blsSigner, err := signer.NewBLSSigner(cfg.Validator.BLSPrivateKey)
	if err != nil {
		fmt.Printf("❌ Failed to initialize BLS signer: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("✅ BLS Signer initialized\n")
	fmt.Printf("   Public Key: 0x%x...\n", blsSigner.PublicKey()[:16])

	// 3. L1 Client 연결
	l1Client, err := ethclient.Dial(cfg.L1.RPC)
	if err != nil {
		fmt.Printf("❌ Failed to connect to L1: %v\n", err)
		os.Exit(1)
	}
	defer l1Client.Close()

	fmt.Printf("✅ Connected to L1: %s\n", cfg.L1.RPC)

	// 3.5. L2 Client 연결
	l2Client, err := ethclient.Dial(cfg.L2.RPC)
	if err != nil {
		fmt.Printf("❌ Failed to connect to L2: %v\n", err)
		os.Exit(1)
	}
	defer l2Client.Close()

	fmt.Printf("✅ Connected to L2: %s\n", cfg.L2.RPC)

	// 4. Verifier 초기화
	var withdrawalVerifier verifier.WithdrawalVerifier

	// Type3 Verifier 사용 (실제 L2 검증)
	type3Verifier, err := verifier.NewType3Verifier(&verifier.Type3Config{
		L1Client:           l1Client,
		L2Client:           l2Client,
		DisputeGameFactory: common.HexToAddress(cfg.L1.RATContract), // TODO: 별도 설정
	})
	if err != nil {
		fmt.Printf("⚠️  Failed to initialize Type3 Verifier: %v\n", err)
		fmt.Printf("   Falling back to Mock Verifier\n")
		withdrawalVerifier = verifier.NewMockVerifier(false)
	} else {
		withdrawalVerifier = type3Verifier
		fmt.Printf("✅ Verifier initialized (Type3 mode)\n")
	}

	// 5. Request Handler 초기화
	requestHandler, err := handler.NewRequestHandler(&handler.Config{
		BLSSigner:     blsSigner,
		Verifier:      withdrawalVerifier,
		L1Client:      l1Client,
		ValidatorAddr: common.HexToAddress(cfg.Validator.Address),
	})
	if err != nil {
		fmt.Printf("❌ Failed to initialize request handler: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("✅ Request Handler initialized\n")

	// 6. libp2p Node 초기화
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	node, err := p2p.NewValidatorNode(ctx, &p2p.Config{
		ListenAddr:      cfg.P2P.ListenAddr,
		BootstrapPeers:  cfg.P2P.BootstrapPeers,
		DHTNamespace:    cfg.P2P.DHTNamespace,
		WithdrawalTopic: cfg.P2P.WithdrawalTopic,
		ValidatorAddr:   common.HexToAddress(cfg.Validator.Address),
		SystemConfig:    cfg.L1.SystemConfig,
	})
	if err != nil {
		fmt.Printf("❌ Failed to initialize libp2p node: %v\n", err)
		os.Exit(1)
	}
	defer node.Close()

	// 7. Request Handler 등록
	node.SetRequestHandler(func(ctx context.Context, req *p2p.SignatureRequest) (*p2p.SignatureResponse, error) {
		return requestHandler.HandleRequest(ctx, req)
	})

	// 8. 메시지 수신 시작
	if err := node.Start(ctx); err != nil {
		fmt.Printf("❌ Failed to start node: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("\n================================================\n")
	fmt.Printf("✅ Validator node is running!\n")
	fmt.Printf("   Validator: %s\n", cfg.Validator.Address)
	fmt.Printf("   PeerID: %s\n", node.PeerID())
	fmt.Printf("   Listening: %s\n", cfg.P2P.ListenAddr)
	fmt.Printf("\n💡 Press Ctrl+C to stop\n")
	fmt.Printf("================================================\n\n")

	// 9. Signal 대기
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)

	<-sigCh

	fmt.Printf("\n\n🛑 Shutting down...\n")
	cancel()
	fmt.Printf("✅ Validator stopped\n")
}
