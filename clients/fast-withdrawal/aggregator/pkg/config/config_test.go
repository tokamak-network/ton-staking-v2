package config

import (
	"os"
	"path/filepath"
	"testing"
)

func TestLoadConfig(t *testing.T) {
	tmpDir := t.TempDir()
	configPath := filepath.Join(tmpDir, "config.yaml")

	configContent := `
aggregator:
  address: "0xAGGREGATOR_ADDRESS"
  private_key: "0xPRIVATE_KEY"

l1:
  rpc: "https://ethereum-rpc.example.com"
  rat_contract: "0xRAT_CONTRACT_ADDRESS"
  fast_withdrawal_contract: "0xFAST_WITHDRAWAL_CONTRACT"

l2:
  rpc: "https://l2-rpc.example.com"

p2p:
  listen_addr: "/ip4/0.0.0.0/tcp/9001"
  bootstrap_peers:
    - "/ip4/validator1.example.com/tcp/9000/p2p/QmValidator1"
  dht_namespace: "/test-dht"
  withdrawal_topic: "/test/withdrawal"

fast_withdrawal:
  response_timeout: 600
  min_validators: 5
  max_gas_price: 200
  submission_gas_limit: 1000000

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
	if cfg.Aggregator.Address != "0xAGGREGATOR_ADDRESS" {
		t.Errorf("Unexpected aggregator address: %s", cfg.Aggregator.Address)
	}

	if cfg.L1.RPC != "https://ethereum-rpc.example.com" {
		t.Errorf("Unexpected L1 RPC: %s", cfg.L1.RPC)
	}

	if cfg.FastWithdrawal.ResponseTimeout != 600 {
		t.Errorf("Unexpected response timeout: %d", cfg.FastWithdrawal.ResponseTimeout)
	}

	if cfg.FastWithdrawal.MinValidators != 5 {
		t.Errorf("Unexpected min validators: %d", cfg.FastWithdrawal.MinValidators)
	}

	t.Log("✅ Config loaded successfully")
}

func TestLoadConfig_Defaults(t *testing.T) {
	tmpDir := t.TempDir()
	configPath := filepath.Join(tmpDir, "config.yaml")

	configContent := `
aggregator:
  address: "0x1234"
  private_key: "0xkey"

l1:
  rpc: "http://localhost:8545"
  rat_contract: "0xrat"

p2p:
  listen_addr: "/ip4/0.0.0.0/tcp/9001"
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

	if cfg.FastWithdrawal.ResponseTimeout != 300 {
		t.Errorf("Unexpected default response timeout: %d", cfg.FastWithdrawal.ResponseTimeout)
	}

	if cfg.FastWithdrawal.MinValidators != 3 {
		t.Errorf("Unexpected default min validators: %d", cfg.FastWithdrawal.MinValidators)
	}

	if cfg.Log.Level != "info" {
		t.Errorf("Unexpected default log level: %s", cfg.Log.Level)
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
				Aggregator: AggregatorConfig{
					Address:    "0x1234",
					PrivateKey: "0xkey",
				},
				L1: L1Config{
					RPC:          "http://localhost:8545",
					RATContract:  "0xrat",
					SystemConfig: "0xsysconfig",
				},
				P2P: P2PConfig{
					ListenAddr: "/ip4/0.0.0.0/tcp/9001",
				},
			},
			expectErr: false,
		},
		{
			name: "missing aggregator address",
			config: Config{
				Aggregator: AggregatorConfig{
					PrivateKey: "0xkey",
				},
			},
			expectErr: true,
			errMsg:    "aggregator.address is required",
		},
		{
			name: "missing private key",
			config: Config{
				Aggregator: AggregatorConfig{
					Address: "0x1234",
				},
			},
			expectErr: true,
			errMsg:    "aggregator.private_key is required",
		},
		{
			name: "missing L1 RPC",
			config: Config{
				Aggregator: AggregatorConfig{
					Address:    "0x1234",
					PrivateKey: "0xkey",
				},
			},
			expectErr: true,
			errMsg:    "l1.rpc is required",
		},
		{
			name: "missing RAT contract",
			config: Config{
				Aggregator: AggregatorConfig{
					Address:    "0x1234",
					PrivateKey: "0xkey",
				},
				L1: L1Config{
					RPC: "http://localhost:8545",
				},
			},
			expectErr: true,
			errMsg:    "l1.rat_contract is required",
		},
		{
			name: "missing system config",
			config: Config{
				Aggregator: AggregatorConfig{
					Address:    "0x1234",
					PrivateKey: "0xkey",
				},
				L1: L1Config{
					RPC:         "http://localhost:8545",
					RATContract: "0xrat",
				},
			},
			expectErr: true,
			errMsg:    "l1.system_config is required",
		},
		{
			name: "missing listen addr",
			config: Config{
				Aggregator: AggregatorConfig{
					Address:    "0x1234",
					PrivateKey: "0xkey",
				},
				L1: L1Config{
					RPC:          "http://localhost:8545",
					RATContract:  "0xrat",
					SystemConfig: "0xsysconfig",
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
