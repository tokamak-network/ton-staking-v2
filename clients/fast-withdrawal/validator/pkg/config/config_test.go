package config

import (
	"os"
	"path/filepath"
	"testing"
)

func TestLoadConfig(t *testing.T) {
	// 임시 config 파일 생성
	tmpDir := t.TempDir()
	configPath := filepath.Join(tmpDir, "config.yaml")

	configContent := `
validator:
  address: "0x1234567890123456789012345678901234567890"
  bls_private_key: "0xabcdef1234567890"

l1:
  rpc: "https://eth-mainnet.example.com"
  rat_contract: "0xRATCONTRACT"

l2:
  rpc: "http://localhost:8545"
  opnode_rpc: "http://localhost:9545"

p2p:
  listen_addr: "/ip4/0.0.0.0/tcp/9000"
  bootstrap_peers:
    - "/ip4/1.2.3.4/tcp/9000/p2p/peer1"
  dht_namespace: "/test-namespace"
  withdrawal_topic: "/test/topic"

log:
  level: "debug"
  format: "json"
`

	err := os.WriteFile(configPath, []byte(configContent), 0644)
	if err != nil {
		t.Fatalf("Failed to write test config: %v", err)
	}

	cfg, err := LoadConfig(configPath)
	if err != nil {
		t.Fatalf("Failed to load config: %v", err)
	}

	// 값 검증
	if cfg.Validator.Address != "0x1234567890123456789012345678901234567890" {
		t.Errorf("Unexpected validator address: %s", cfg.Validator.Address)
	}

	if cfg.L1.RPC != "https://eth-mainnet.example.com" {
		t.Errorf("Unexpected L1 RPC: %s", cfg.L1.RPC)
	}

	if cfg.P2P.ListenAddr != "/ip4/0.0.0.0/tcp/9000" {
		t.Errorf("Unexpected listen addr: %s", cfg.P2P.ListenAddr)
	}

	if len(cfg.P2P.BootstrapPeers) != 1 {
		t.Errorf("Unexpected bootstrap peers count: %d", len(cfg.P2P.BootstrapPeers))
	}

	t.Log("✅ Config loaded successfully")
}

func TestLoadConfig_Defaults(t *testing.T) {
	// 기본값 테스트를 위한 최소 config
	tmpDir := t.TempDir()
	configPath := filepath.Join(tmpDir, "config.yaml")

	configContent := `
validator:
  address: "0x1234"
  bls_private_key: "0xkey"

l1:
  rpc: "http://localhost:8545"
  rat_contract: "0xrat"

l2:
  rpc: "http://localhost:8546"

p2p:
  listen_addr: "/ip4/0.0.0.0/tcp/9000"
`

	err := os.WriteFile(configPath, []byte(configContent), 0644)
	if err != nil {
		t.Fatalf("Failed to write test config: %v", err)
	}

	cfg, err := LoadConfig(configPath)
	if err != nil {
		t.Fatalf("Failed to load config: %v", err)
	}

	// 기본값 확인
	if cfg.P2P.DHTNamespace != "/tokamak-rat-validators" {
		t.Errorf("Unexpected default DHT namespace: %s", cfg.P2P.DHTNamespace)
	}

	if cfg.P2P.WithdrawalTopic != "/tokamak/rat/withdrawal/1.0.0" {
		t.Errorf("Unexpected default withdrawal topic: %s", cfg.P2P.WithdrawalTopic)
	}

	if cfg.Log.Level != "info" {
		t.Errorf("Unexpected default log level: %s", cfg.Log.Level)
	}

	if cfg.Log.Format != "text" {
		t.Errorf("Unexpected default log format: %s", cfg.Log.Format)
	}

	t.Log("✅ Default values applied correctly")
}

func TestLoadConfig_FileNotFound(t *testing.T) {
	_, err := LoadConfig("/nonexistent/path/config.yaml")
	if err == nil {
		t.Error("Expected error for nonexistent file")
	}

	t.Log("✅ File not found error handled correctly")
}

func TestLoadConfig_InvalidYAML(t *testing.T) {
	tmpDir := t.TempDir()
	configPath := filepath.Join(tmpDir, "config.yaml")

	// 잘못된 YAML
	err := os.WriteFile(configPath, []byte("invalid: yaml: content:"), 0644)
	if err != nil {
		t.Fatalf("Failed to write test config: %v", err)
	}

	_, err = LoadConfig(configPath)
	if err == nil {
		t.Error("Expected error for invalid YAML")
	}

	t.Log("✅ Invalid YAML error handled correctly")
}

func TestConfig_Validate(t *testing.T) {
	tests := []struct {
		name      string
		config    Config
		expectErr bool
		errMsg    string
	}{
		{
			name: "valid config",
			config: Config{
				Validator: ValidatorConfig{
					Address:       "0x1234",
					BLSPrivateKey: "0xkey",
				},
				L1: L1Config{
					RPC:         "http://localhost:8545",
					RATContract: "0xrat",
				},
				L2: L2Config{
					RPC: "http://localhost:8546",
				},
				P2P: P2PConfig{
					ListenAddr: "/ip4/0.0.0.0/tcp/9000",
				},
			},
			expectErr: false,
		},
		{
			name: "missing validator address",
			config: Config{
				Validator: ValidatorConfig{
					BLSPrivateKey: "0xkey",
				},
			},
			expectErr: true,
			errMsg:    "validator.address is required",
		},
		{
			name: "missing BLS private key",
			config: Config{
				Validator: ValidatorConfig{
					Address: "0x1234",
				},
			},
			expectErr: true,
			errMsg:    "validator.bls_private_key is required",
		},
		{
			name: "missing L1 RPC",
			config: Config{
				Validator: ValidatorConfig{
					Address:       "0x1234",
					BLSPrivateKey: "0xkey",
				},
			},
			expectErr: true,
			errMsg:    "l1.rpc is required",
		},
		{
			name: "missing RAT contract",
			config: Config{
				Validator: ValidatorConfig{
					Address:       "0x1234",
					BLSPrivateKey: "0xkey",
				},
				L1: L1Config{
					RPC: "http://localhost:8545",
				},
			},
			expectErr: true,
			errMsg:    "l1.rat_contract is required",
		},
		{
			name: "missing L2 RPC",
			config: Config{
				Validator: ValidatorConfig{
					Address:       "0x1234",
					BLSPrivateKey: "0xkey",
				},
				L1: L1Config{
					RPC:         "http://localhost:8545",
					RATContract: "0xrat",
				},
			},
			expectErr: true,
			errMsg:    "l2.rpc is required",
		},
		{
			name: "missing listen addr",
			config: Config{
				Validator: ValidatorConfig{
					Address:       "0x1234",
					BLSPrivateKey: "0xkey",
				},
				L1: L1Config{
					RPC:         "http://localhost:8545",
					RATContract: "0xrat",
				},
				L2: L2Config{
					RPC: "http://localhost:8546",
				},
			},
			expectErr: true,
			errMsg:    "p2p.listen_addr is required",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.config.Validate()
			if tt.expectErr {
				if err == nil {
					t.Errorf("Expected error but got nil")
				} else if err.Error() != tt.errMsg {
					t.Errorf("Expected error '%s', got '%s'", tt.errMsg, err.Error())
				}
			} else {
				if err != nil {
					t.Errorf("Unexpected error: %v", err)
				}
			}
		})
	}

	t.Log("✅ Config validation tests passed")
}
