package p2p

import (
	"context"
	"math/big"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum/common"
)

func TestNewValidatorNode(t *testing.T) {
	ctx := context.Background()

	cfg := &Config{
		ListenAddr:      "/ip4/127.0.0.1/tcp/0", // 랜덤 포트
		BootstrapPeers:  []string{},
		DHTNamespace:    DefaultDHTNamespace,
		WithdrawalTopic: DefaultWithdrawalTopic,
		ValidatorAddr:   common.HexToAddress("0x1234567890123456789012345678901234567890"),
	}

	node, err := NewValidatorNode(ctx, cfg)
	if err != nil {
		t.Fatalf("Failed to create node: %v", err)
	}
	defer node.Close()

	if node.PeerID() == "" {
		t.Error("PeerID is empty")
	}

	t.Logf("Node created successfully")
	t.Logf("PeerID: %s", node.PeerID())
}

func TestTwoNodesCanConnect(t *testing.T) {
	ctx := context.Background()

	// Node 1 생성
	node1, err := NewValidatorNode(ctx, &Config{
		ListenAddr:     "/ip4/127.0.0.1/tcp/0",
		BootstrapPeers: []string{},
		ValidatorAddr:  common.HexToAddress("0x1111111111111111111111111111111111111111"),
	})
	if err != nil {
		t.Fatalf("Failed to create node1: %v", err)
	}
	defer node1.Close()

	// Node 1의 주소 가져오기
	addrs := node1.host.Addrs()
	if len(addrs) == 0 {
		t.Fatal("Node1 has no addresses")
	}

	// Node 2 생성 (Node 1을 bootstrap peer로 사용)
	bootstrapAddr := addrs[0].String() + "/p2p/" + node1.PeerID()

	node2, err := NewValidatorNode(ctx, &Config{
		ListenAddr:     "/ip4/127.0.0.1/tcp/0",
		BootstrapPeers: []string{bootstrapAddr},
		ValidatorAddr:  common.HexToAddress("0x2222222222222222222222222222222222222222"),
	})
	if err != nil {
		t.Fatalf("Failed to create node2: %v", err)
	}
	defer node2.Close()

	// 연결 대기
	time.Sleep(2 * time.Second)

	// Peer 수 확인
	t.Logf("Node1 peers: %d", node1.PeerCount())
	t.Logf("Node2 peers: %d", node2.PeerCount())

	if node2.PeerCount() == 0 {
		t.Error("Node2 has no peers")
	}
}

func TestPubSubMessaging(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Node 1 (Aggregator)
	node1, err := NewValidatorNode(ctx, &Config{
		ListenAddr:     "/ip4/127.0.0.1/tcp/0",
		BootstrapPeers: []string{},
		ValidatorAddr:  common.HexToAddress("0x1111111111111111111111111111111111111111"),
	})
	if err != nil {
		t.Fatalf("Failed to create node1: %v", err)
	}
	defer node1.Close()

	// Node 2 (Validator)
	bootstrapAddr := node1.host.Addrs()[0].String() + "/p2p/" + node1.PeerID()

	node2, err := NewValidatorNode(ctx, &Config{
		ListenAddr:     "/ip4/127.0.0.1/tcp/0",
		BootstrapPeers: []string{bootstrapAddr},
		ValidatorAddr:  common.HexToAddress("0x2222222222222222222222222222222222222222"),
	})
	if err != nil {
		t.Fatalf("Failed to create node2: %v", err)
	}
	defer node2.Close()

	// 연결 대기
	time.Sleep(2 * time.Second)

	// Node2에 request handler 설정
	received := make(chan bool, 1)
	node2.SetRequestHandler(func(ctx context.Context, req *SignatureRequest) (*SignatureResponse, error) {
		t.Logf("Node2 received request: %x", req.RequestID[:8])
		received <- true

		// Mock response
		return &SignatureResponse{
			RequestID: req.RequestID,
			Validator: node2.validatorAddr,
			Signature: []byte("mock_signature"),
			PublicKey: []byte("mock_public_key"),
		}, nil
	})

	// Node2 메시지 수신 시작
	if err := node2.Start(ctx); err != nil {
		t.Fatalf("Failed to start node2: %v", err)
	}

	// Node1에서 request 브로드캐스트
	testReq := &SignatureRequest{
		RequestID:   [32]byte{1, 2, 3, 4, 5, 6, 7, 8},
		User:        common.HexToAddress("0xUSER"),
		Amount:      big.NewInt(1000000),
		ChainID:     big.NewInt(1),
		Deadline:    uint64(time.Now().Add(10 * time.Minute).Unix()),
		RollupType:  3,
		GameIndex:   big.NewInt(100),
		BlockNumber: 12345,
	}

	if err := node1.BroadcastRequest(ctx, testReq); err != nil {
		t.Fatalf("Failed to broadcast request: %v", err)
	}

	// 메시지 수신 대기
	select {
	case <-received:
		t.Log("✅ Message received successfully")
	case <-time.After(5 * time.Second):
		t.Error("Timeout: message not received")
	}
}
