package p2p

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/ethereum/go-ethereum/common"
	"github.com/libp2p/go-libp2p"
	dht "github.com/libp2p/go-libp2p-kad-dht"
	pubsub "github.com/libp2p/go-libp2p-pubsub"
	"github.com/libp2p/go-libp2p/core/host"
	"github.com/libp2p/go-libp2p/core/peer"
	"github.com/libp2p/go-libp2p/p2p/discovery/mdns"
	"github.com/multiformats/go-multiaddr"

	"github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/aggregator/pkg/types"
)

const (
	DefaultDHTNamespace    = "/tokamak-rat-validators"
	DefaultWithdrawalTopic = "/tokamak/rat/withdrawal/1.0.0"
)

// AggregatorNetwork Aggregator용 libp2p 네트워크
type AggregatorNetwork struct {
	host            host.Host
	dht             *dht.IpfsDHT
	pubsub          *pubsub.PubSub
	withdrawalTopic *pubsub.Topic
	withdrawalSub   *pubsub.Subscription

	aggregatorAddr common.Address

	// Response handler
	responseHandler ResponseHandler
}

// ResponseHandler SignatureResponse 처리 핸들러
type ResponseHandler func(ctx context.Context, resp *types.SignatureResponse) error

// Config libp2p 네트워크 설정
type Config struct {
	ListenAddr      string
	BootstrapPeers  []string
	DHTNamespace    string
	WithdrawalTopic string
	AggregatorAddr  common.Address
	SystemConfig    string // SystemConfig 주소 — mDNS/DHT 네임스페이스에 사용
}

// mdnsNotifee mDNS 피어 디스커버리 핸들러
type mdnsNotifee struct {
	h host.Host
}

func (n *mdnsNotifee) HandlePeerFound(pi peer.AddrInfo) {
	if pi.ID == n.h.ID() {
		return
	}
	fmt.Printf("🔍 mDNS: discovered peer %s\n", pi.ID.String())
	if err := n.h.Connect(context.Background(), pi); err != nil {
		fmt.Printf("   Warning: failed to connect to mDNS peer: %v\n", err)
	} else {
		fmt.Printf("   ✅ Connected to mDNS peer: %s\n", pi.ID.String())
	}
}

// NewAggregatorNetwork Aggregator 네트워크 생성
func NewAggregatorNetwork(ctx context.Context, cfg *Config) (*AggregatorNetwork, error) {
	// 기본값 설정 — SystemConfig 주소로 네임스페이스 스코핑
	if cfg.DHTNamespace == "" {
		if cfg.SystemConfig != "" {
			cfg.DHTNamespace = "/tokamak-rat/" + cfg.SystemConfig
		} else {
			cfg.DHTNamespace = DefaultDHTNamespace
		}
	}
	if cfg.WithdrawalTopic == "" {
		cfg.WithdrawalTopic = DefaultWithdrawalTopic
	}

	// libp2p host 생성
	h, err := libp2p.New(
		libp2p.ListenAddrStrings(cfg.ListenAddr),
		libp2p.DefaultTransports,
		libp2p.DefaultMuxers,
		libp2p.DefaultSecurity,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create libp2p host: %w", err)
	}

	// DHT 설정
	kadDHT, err := dht.New(ctx, h, dht.Mode(dht.ModeServer))
	if err != nil {
		return nil, fmt.Errorf("failed to create DHT: %w", err)
	}

	// DHT bootstrap
	if err := kadDHT.Bootstrap(ctx); err != nil {
		return nil, fmt.Errorf("failed to bootstrap DHT: %w", err)
	}

	// Bootstrap peers 연결 (상용: 잘 알려진 부트노드 사용)
	if len(cfg.BootstrapPeers) > 0 {
		if err := connectBootstrapPeers(ctx, h, cfg.BootstrapPeers); err != nil {
			fmt.Printf("Warning: failed to connect to some bootstrap peers: %v\n", err)
		}
	}

	// mDNS 피어 디스커버리 (로컬 네트워크/Docker에서 자동 발견)
	mdnsServiceName := "tokamak-rat-validators"
	if cfg.SystemConfig != "" {
		mdnsServiceName = "tokamak-rat-" + cfg.SystemConfig[:10]
	}
	mdnsSvc := mdns.NewMdnsService(h, mdnsServiceName, &mdnsNotifee{h: h})
	if err := mdnsSvc.Start(); err != nil {
		fmt.Printf("Warning: mDNS discovery failed to start: %v\n", err)
	} else {
		fmt.Printf("🔍 mDNS discovery started (service: %s)\n", mdnsServiceName)
	}

	// GossipSub pubsub 설정
	ps, err := pubsub.NewGossipSub(ctx, h)
	if err != nil {
		return nil, fmt.Errorf("failed to create pubsub: %w", err)
	}

	// Withdrawal topic join
	topic, err := ps.Join(cfg.WithdrawalTopic)
	if err != nil {
		return nil, fmt.Errorf("failed to join topic: %w", err)
	}

	// Topic 구독
	sub, err := topic.Subscribe()
	if err != nil {
		return nil, fmt.Errorf("failed to subscribe to topic: %w", err)
	}

	fmt.Printf("✅ Aggregator libp2p network started\n")
	fmt.Printf("   PeerID: %s\n", h.ID().String())
	fmt.Printf("   Listening on: %s\n", cfg.ListenAddr)
	fmt.Printf("   Topic: %s\n", cfg.WithdrawalTopic)

	return &AggregatorNetwork{
		host:            h,
		dht:             kadDHT,
		pubsub:          ps,
		withdrawalTopic: topic,
		withdrawalSub:   sub,
		aggregatorAddr:  cfg.AggregatorAddr,
	}, nil
}

// connectBootstrapPeers bootstrap peers에 연결
func connectBootstrapPeers(ctx context.Context, h host.Host, peers []string) error {
	var lastErr error
	successCount := 0

	for _, peerAddr := range peers {
		maddr, err := multiaddr.NewMultiaddr(peerAddr)
		if err != nil {
			lastErr = err
			continue
		}

		peerInfo, err := peer.AddrInfoFromP2pAddr(maddr)
		if err != nil {
			lastErr = err
			continue
		}

		if err := h.Connect(ctx, *peerInfo); err != nil {
			lastErr = err
			fmt.Printf("Warning: failed to connect to bootstrap peer %s: %v\n", peerInfo.ID, err)
			continue
		}

		successCount++
		fmt.Printf("✅ Connected to validator peer: %s\n", peerInfo.ID.String())
	}

	if successCount == 0 && lastErr != nil {
		return fmt.Errorf("failed to connect to any bootstrap peer: %w", lastErr)
	}

	return nil
}

// SetResponseHandler SignatureResponse 핸들러 설정
func (an *AggregatorNetwork) SetResponseHandler(handler ResponseHandler) {
	an.responseHandler = handler
}

// Start 메시지 수신 시작
func (an *AggregatorNetwork) Start(ctx context.Context) error {
	if an.responseHandler == nil {
		return fmt.Errorf("response handler not set")
	}

	fmt.Printf("🚀 Aggregator listening for signature responses...\n")

	go an.messageLoop(ctx)

	return nil
}

// messageLoop pubsub 메시지 수신 루프
func (an *AggregatorNetwork) messageLoop(ctx context.Context) {
	for {
		msg, err := an.withdrawalSub.Next(ctx)
		if err != nil {
			if ctx.Err() != nil {
				return
			}
			fmt.Printf("Error reading pubsub message: %v\n", err)
			continue
		}

		// 자신이 보낸 메시지는 무시
		if msg.ReceivedFrom == an.host.ID() {
			continue
		}

		// SignatureResponse 처리
		go an.handleMessage(ctx, msg.Data)
	}
}

// handleMessage 메시지 처리
func (an *AggregatorNetwork) handleMessage(ctx context.Context, data []byte) {
	// SignatureResponse 파싱
	var resp types.SignatureResponse
	if err := json.Unmarshal(data, &resp); err != nil {
		return
	}

	// SignatureRequest가 GossipSub 릴레이로 들어올 수 있음 — 필터링
	// 유효한 SignatureResponse는 반드시 Signature와 Validator가 있어야 함
	if len(resp.Signature) == 0 || resp.Validator == (common.Address{}) {
		return
	}

	// Response 처리
	if an.responseHandler != nil {
		if err := an.responseHandler(ctx, &resp); err != nil {
			fmt.Printf("Error handling signature response: %v\n", err)
		}
	}
}

// BroadcastRequest SignatureRequest 브로드캐스트
func (an *AggregatorNetwork) BroadcastRequest(ctx context.Context, req *types.SignatureRequest) error {
	data, err := json.Marshal(req)
	if err != nil {
		return fmt.Errorf("failed to marshal request: %w", err)
	}

	if err := an.withdrawalTopic.Publish(ctx, data); err != nil {
		return fmt.Errorf("failed to broadcast request: %w", err)
	}

	fmt.Printf("📡 Broadcasted signature request %x to validators\n", req.RequestID[:8])

	return nil
}

// Close 네트워크 종료
func (an *AggregatorNetwork) Close() error {
	if an.withdrawalSub != nil {
		an.withdrawalSub.Cancel()
	}

	if err := an.dht.Close(); err != nil {
		return err
	}

	return an.host.Close()
}

// PeerID 네트워크 peer ID 반환
func (an *AggregatorNetwork) PeerID() string {
	return an.host.ID().String()
}

// PeerCount 연결된 peer 수 반환
func (an *AggregatorNetwork) PeerCount() int {
	return len(an.host.Network().Peers())
}
