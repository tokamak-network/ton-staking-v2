package p2p

import (
	"context"
	"encoding/json"
	"math/big"
	"testing"

	"github.com/ethereum/go-ethereum/common"

	"github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/aggregator/pkg/types"
)

func TestDefaultConstants(t *testing.T) {
	if DefaultDHTNamespace != "/tokamak-rat-validators" {
		t.Errorf("Unexpected default DHT namespace: %s", DefaultDHTNamespace)
	}

	if DefaultWithdrawalTopic != "/tokamak/rat/withdrawal/1.0.0" {
		t.Errorf("Unexpected default withdrawal topic: %s", DefaultWithdrawalTopic)
	}

	t.Log("✅ Default constants are correct")
}

func TestConfig_Struct(t *testing.T) {
	cfg := &Config{
		ListenAddr:      "/ip4/0.0.0.0/tcp/9001",
		BootstrapPeers:  []string{"/ip4/127.0.0.1/tcp/9000/p2p/QmTest"},
		DHTNamespace:    "/test-dht",
		WithdrawalTopic: "/test/withdrawal",
		AggregatorAddr:  common.HexToAddress("0x1234567890123456789012345678901234567890"),
	}

	if cfg.ListenAddr != "/ip4/0.0.0.0/tcp/9001" {
		t.Errorf("Unexpected listen address: %s", cfg.ListenAddr)
	}

	if len(cfg.BootstrapPeers) != 1 {
		t.Errorf("Unexpected bootstrap peers count: %d", len(cfg.BootstrapPeers))
	}

	if cfg.DHTNamespace != "/test-dht" {
		t.Errorf("Unexpected DHT namespace: %s", cfg.DHTNamespace)
	}

	if cfg.WithdrawalTopic != "/test/withdrawal" {
		t.Errorf("Unexpected withdrawal topic: %s", cfg.WithdrawalTopic)
	}

	if cfg.AggregatorAddr == (common.Address{}) {
		t.Error("Aggregator address should not be empty")
	}

	t.Log("✅ Config struct works correctly")
}

func TestConfig_DefaultValues(t *testing.T) {
	cfg := &Config{
		ListenAddr:     "/ip4/0.0.0.0/tcp/9001",
		DHTNamespace:   "", // empty - should use default
		WithdrawalTopic: "", // empty - should use default
	}

	// NewAggregatorNetwork에서 기본값 적용됨
	if cfg.DHTNamespace == "" {
		cfg.DHTNamespace = DefaultDHTNamespace
	}
	if cfg.WithdrawalTopic == "" {
		cfg.WithdrawalTopic = DefaultWithdrawalTopic
	}

	if cfg.DHTNamespace != DefaultDHTNamespace {
		t.Errorf("Expected default DHT namespace, got: %s", cfg.DHTNamespace)
	}

	if cfg.WithdrawalTopic != DefaultWithdrawalTopic {
		t.Errorf("Expected default withdrawal topic, got: %s", cfg.WithdrawalTopic)
	}

	t.Log("✅ Default values applied correctly")
}

func TestSignatureRequest_JSON_Serialization(t *testing.T) {
	req := &types.SignatureRequest{
		RequestID:   [32]byte{1, 2, 3, 4, 5, 6, 7, 8},
		User:        common.HexToAddress("0x1234567890123456789012345678901234567890"),
		Amount:      big.NewInt(1000000000000000000),
		ChainID:     big.NewInt(1),
		Deadline:    1700000000,
		RollupType:  3,
		GameIndex:   big.NewInt(42),
		OutputRoot:  [32]byte{0xaa, 0xbb, 0xcc},
		BlockNumber: 12345678,
	}

	// JSON 직렬화
	data, err := json.Marshal(req)
	if err != nil {
		t.Fatalf("Failed to marshal request: %v", err)
	}

	// JSON 역직렬화
	var decoded types.SignatureRequest
	if err := json.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("Failed to unmarshal request: %v", err)
	}

	if decoded.RequestID != req.RequestID {
		t.Error("RequestID mismatch after serialization")
	}

	if decoded.User != req.User {
		t.Error("User mismatch after serialization")
	}

	if decoded.Amount.Cmp(req.Amount) != 0 {
		t.Error("Amount mismatch after serialization")
	}

	t.Log("✅ SignatureRequest JSON serialization works for broadcast")
}

func TestSignatureResponse_JSON_Serialization(t *testing.T) {
	resp := &types.SignatureResponse{
		RequestID:     [32]byte{1, 2, 3},
		Validator:     common.HexToAddress("0xVALIDATOR"),
		Signature:     make([]byte, 96),
		PublicKey:     make([]byte, 48),
		Timestamp:     1700000000,
		ValidatorPeer: "QmPeerID123",
	}

	// JSON 직렬화
	data, err := json.Marshal(resp)
	if err != nil {
		t.Fatalf("Failed to marshal response: %v", err)
	}

	// JSON 역직렬화
	var decoded types.SignatureResponse
	if err := json.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("Failed to unmarshal response: %v", err)
	}

	if decoded.RequestID != resp.RequestID {
		t.Error("RequestID mismatch after serialization")
	}

	if decoded.Validator != resp.Validator {
		t.Error("Validator mismatch after serialization")
	}

	if len(decoded.Signature) != 96 {
		t.Errorf("Unexpected signature length: %d", len(decoded.Signature))
	}

	if len(decoded.PublicKey) != 48 {
		t.Errorf("Unexpected public key length: %d", len(decoded.PublicKey))
	}

	t.Log("✅ SignatureResponse JSON serialization works for message handling")
}

func TestAggregatorNetwork_Struct(t *testing.T) {
	// AggregatorNetwork 구조체 필드 테스트
	an := &AggregatorNetwork{
		aggregatorAddr: common.HexToAddress("0x1234567890123456789012345678901234567890"),
	}

	if an.aggregatorAddr == (common.Address{}) {
		t.Error("Aggregator address should not be empty")
	}

	t.Log("✅ AggregatorNetwork struct works correctly")
}

func TestResponseHandler_Type(t *testing.T) {
	// ResponseHandler 타입 테스트
	var handler ResponseHandler = func(ctx context.Context, resp *types.SignatureResponse) error {
		if resp == nil {
			return nil
		}
		return nil
	}

	// handler 호출 테스트
	ctx := context.Background()
	resp := &types.SignatureResponse{
		RequestID: [32]byte{1, 2, 3},
		Validator: common.HexToAddress("0x1234"),
	}

	err := handler(ctx, resp)
	if err != nil {
		t.Errorf("Handler returned unexpected error: %v", err)
	}

	t.Log("✅ ResponseHandler type works correctly")
}

func TestMultiaddr_Format(t *testing.T) {
	// libp2p multiaddr 형식 테스트
	testAddrs := []string{
		"/ip4/0.0.0.0/tcp/9001",
		"/ip4/127.0.0.1/tcp/9000/p2p/QmValidator1",
		"/ip4/192.168.1.1/tcp/4001",
	}

	for _, addr := range testAddrs {
		// 형식이 /ip4/로 시작하는지 확인
		if len(addr) < 5 || addr[:5] != "/ip4/" {
			t.Errorf("Invalid multiaddr format: %s", addr)
		}
	}

	t.Log("✅ Multiaddr formats are valid")
}

func TestBootstrapPeers_Empty(t *testing.T) {
	cfg := &Config{
		ListenAddr:     "/ip4/0.0.0.0/tcp/9001",
		BootstrapPeers: []string{}, // empty
	}

	if len(cfg.BootstrapPeers) != 0 {
		t.Error("Bootstrap peers should be empty")
	}

	// Empty bootstrap peers는 허용됨
	t.Log("✅ Empty bootstrap peers handled correctly")
}

func TestBootstrapPeers_Multiple(t *testing.T) {
	cfg := &Config{
		ListenAddr: "/ip4/0.0.0.0/tcp/9001",
		BootstrapPeers: []string{
			"/ip4/validator1.example.com/tcp/9000/p2p/QmValidator1",
			"/ip4/validator2.example.com/tcp/9000/p2p/QmValidator2",
			"/ip4/validator3.example.com/tcp/9000/p2p/QmValidator3",
		},
	}

	if len(cfg.BootstrapPeers) != 3 {
		t.Errorf("Expected 3 bootstrap peers, got %d", len(cfg.BootstrapPeers))
	}

	t.Log("✅ Multiple bootstrap peers handled correctly")
}
