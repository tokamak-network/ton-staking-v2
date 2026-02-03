package p2p

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/libp2p/go-libp2p"
	dht "github.com/libp2p/go-libp2p-kad-dht"
	pubsub "github.com/libp2p/go-libp2p-pubsub"
	"github.com/libp2p/go-libp2p/core/host"
	"github.com/libp2p/go-libp2p/core/peer"
	"github.com/multiformats/go-multiaddr"
)

const (
	// DHTNamespace DHT 프로토콜 네임스페이스
	DefaultDHTNamespace = "/tokamak-rat-validators"

	// WithdrawalTopic Fast Withdrawal pubsub 토픽
	DefaultWithdrawalTopic = "/tokamak/rat/withdrawal/1.0.0"
)

// ValidatorNode libp2p 기반 Validator 노드
type ValidatorNode struct {
	host            host.Host
	dht             *dht.IpfsDHT
	pubsub          *pubsub.PubSub
	withdrawalTopic *pubsub.Topic
	withdrawalSub   *pubsub.Subscription

	validatorAddr common.Address

	// Message handlers
	requestHandler  RequestHandler
	responseHandler ResponseHandler
}

// RequestHandler SignatureRequest 처리 핸들러
type RequestHandler func(ctx context.Context, req *SignatureRequest) (*SignatureResponse, error)

// ResponseHandler SignatureResponse 처리 핸들러 (Aggregator용)
type ResponseHandler func(ctx context.Context, resp *SignatureResponse) error

// Config libp2p 노드 설정
type Config struct {
	ListenAddr      string
	BootstrapPeers  []string
	DHTNamespace    string
	WithdrawalTopic string
	ValidatorAddr   common.Address
}

// NewValidatorNode libp2p Validator 노드 생성
func NewValidatorNode(ctx context.Context, cfg *Config) (*ValidatorNode, error) {
	// 기본값 설정
	if cfg.DHTNamespace == "" {
		cfg.DHTNamespace = DefaultDHTNamespace
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

	// Bootstrap peers 연결
	if len(cfg.BootstrapPeers) > 0 {
		if err := connectBootstrapPeers(ctx, h, cfg.BootstrapPeers); err != nil {
			// Warning만 출력하고 계속 진행
			fmt.Printf("Warning: failed to connect to some bootstrap peers: %v\n", err)
		}
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

	fmt.Printf("✅ libp2p node started\n")
	fmt.Printf("   PeerID: %s\n", h.ID().String())
	fmt.Printf("   Listening on: %s\n", cfg.ListenAddr)
	fmt.Printf("   Topic: %s\n", cfg.WithdrawalTopic)

	return &ValidatorNode{
		host:            h,
		dht:             kadDHT,
		pubsub:          ps,
		withdrawalTopic: topic,
		withdrawalSub:   sub,
		validatorAddr:   cfg.ValidatorAddr,
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
		fmt.Printf("✅ Connected to bootstrap peer: %s\n", peerInfo.ID.String())
	}

	if successCount == 0 && lastErr != nil {
		return fmt.Errorf("failed to connect to any bootstrap peer: %w", lastErr)
	}

	return nil
}

// SetRequestHandler SignatureRequest 핸들러 설정
func (vn *ValidatorNode) SetRequestHandler(handler RequestHandler) {
	vn.requestHandler = handler
}

// SetResponseHandler SignatureResponse 핸들러 설정 (Aggregator용)
func (vn *ValidatorNode) SetResponseHandler(handler ResponseHandler) {
	vn.responseHandler = handler
}

// Start 메시지 수신 시작
func (vn *ValidatorNode) Start(ctx context.Context) error {
	if vn.requestHandler == nil {
		return fmt.Errorf("request handler not set")
	}

	fmt.Printf("🚀 Validator node listening for withdrawal requests...\n")

	go vn.messageLoop(ctx)

	return nil
}

// messageLoop pubsub 메시지 수신 루프
func (vn *ValidatorNode) messageLoop(ctx context.Context) {
	for {
		msg, err := vn.withdrawalSub.Next(ctx)
		if err != nil {
			if ctx.Err() != nil {
				// Context cancelled
				return
			}
			fmt.Printf("Error reading pubsub message: %v\n", err)
			continue
		}

		// 자신이 보낸 메시지는 무시
		if msg.ReceivedFrom == vn.host.ID() {
			continue
		}

		// 메시지 타입 판별 및 처리
		go vn.handleMessage(ctx, msg.Data)
	}
}

// handleMessage 메시지 처리
func (vn *ValidatorNode) handleMessage(ctx context.Context, data []byte) {
	// SignatureRequest 시도
	var req SignatureRequest
	if err := json.Unmarshal(data, &req); err == nil {
		// SignatureRequest 처리
		if vn.requestHandler != nil {
			resp, err := vn.requestHandler(ctx, &req)
			if err != nil {
				fmt.Printf("Error handling request: %v\n", err)
				return
			}

			// SignatureResponse 발행
			if err := vn.PublishSignature(ctx, resp); err != nil {
				fmt.Printf("Error publishing signature: %v\n", err)
			}
		}
		return
	}

	// SignatureResponse 시도
	var resp SignatureResponse
	if err := json.Unmarshal(data, &resp); err == nil {
		// SignatureResponse 처리 (Aggregator용)
		if vn.responseHandler != nil {
			if err := vn.responseHandler(ctx, &resp); err != nil {
				fmt.Printf("Error handling response: %v\n", err)
			}
		}
		return
	}

	// Unknown message type
	fmt.Printf("Warning: unknown message type\n")
}

// PublishSignature SignatureResponse 발행
func (vn *ValidatorNode) PublishSignature(ctx context.Context, resp *SignatureResponse) error {
	// Validator peer ID 추가
	resp.ValidatorPeer = vn.host.ID().String()
	resp.Timestamp = uint64(time.Now().Unix())

	data, err := json.Marshal(resp)
	if err != nil {
		return fmt.Errorf("failed to marshal response: %w", err)
	}

	if err := vn.withdrawalTopic.Publish(ctx, data); err != nil {
		return fmt.Errorf("failed to publish signature: %w", err)
	}

	fmt.Printf("✅ Published signature for request %x\n", resp.RequestID[:8])

	return nil
}

// BroadcastRequest SignatureRequest 브로드캐스트 (Aggregator용)
func (vn *ValidatorNode) BroadcastRequest(ctx context.Context, req *SignatureRequest) error {
	data, err := json.Marshal(req)
	if err != nil {
		return fmt.Errorf("failed to marshal request: %w", err)
	}

	if err := vn.withdrawalTopic.Publish(ctx, data); err != nil {
		return fmt.Errorf("failed to broadcast request: %w", err)
	}

	fmt.Printf("✅ Broadcasted withdrawal request %x\n", req.RequestID[:8])

	return nil
}

// Close 노드 종료
func (vn *ValidatorNode) Close() error {
	if vn.withdrawalSub != nil {
		vn.withdrawalSub.Cancel()
	}

	if err := vn.dht.Close(); err != nil {
		return err
	}

	return vn.host.Close()
}

// PeerID 노드의 peer ID 반환
func (vn *ValidatorNode) PeerID() string {
	return vn.host.ID().String()
}

// PeerCount 연결된 peer 수 반환
func (vn *ValidatorNode) PeerCount() int {
	return len(vn.host.Network().Peers())
}
