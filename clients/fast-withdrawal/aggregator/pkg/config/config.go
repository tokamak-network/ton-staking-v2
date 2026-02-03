package config

import (
	"fmt"
	"os"

	"gopkg.in/yaml.v3"
)

// Config Aggregator 설정
type Config struct {
	// Aggregator Identity
	Aggregator AggregatorConfig `yaml:"aggregator"`

	// L1 Connection
	L1 L1Config `yaml:"l1"`

	// L2 Connection
	L2 L2Config `yaml:"l2"`

	// libp2p Network
	P2P P2PConfig `yaml:"p2p"`

	// Fast Withdrawal Settings
	FastWithdrawal FastWithdrawalConfig `yaml:"fast_withdrawal"`

	// Logging
	Log LogConfig `yaml:"log"`
}

type AggregatorConfig struct {
	Address    string `yaml:"address"`     // Ethereum address
	PrivateKey string `yaml:"private_key"` // For submitting transactions
}

type L1Config struct {
	RPC                    string `yaml:"rpc"`
	RATContract            string `yaml:"rat_contract"`
	FastWithdrawalContract string `yaml:"fast_withdrawal_contract"` // Portal or dedicated contract
}

type L2Config struct {
	RPC string `yaml:"rpc"` // L2 RPC endpoint (op-geth)
}

type P2PConfig struct {
	ListenAddr      string   `yaml:"listen_addr"`
	BootstrapPeers  []string `yaml:"bootstrap_peers"`
	DHTNamespace    string   `yaml:"dht_namespace"`
	WithdrawalTopic string   `yaml:"withdrawal_topic"`
}

type FastWithdrawalConfig struct {
	ResponseTimeout    int `yaml:"response_timeout"` // seconds
	MinValidators      int `yaml:"min_validators"`   // minimum validators required
	MaxGasPrice        int `yaml:"max_gas_price"`    // gwei
	SubmissionGasLimit int `yaml:"submission_gas_limit"`
}

type LogConfig struct {
	Level  string `yaml:"level"`
	Format string `yaml:"format"`
}

// LoadConfig YAML 파일에서 설정 로드
func LoadConfig(path string) (*Config, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	var cfg Config
	if err := yaml.Unmarshal(data, &cfg); err != nil {
		return nil, fmt.Errorf("failed to parse config: %w", err)
	}

	// 기본값 설정
	if cfg.P2P.DHTNamespace == "" {
		cfg.P2P.DHTNamespace = "/tokamak-rat-validators"
	}
	if cfg.P2P.WithdrawalTopic == "" {
		cfg.P2P.WithdrawalTopic = "/tokamak/rat/withdrawal/1.0.0"
	}
	if cfg.FastWithdrawal.ResponseTimeout == 0 {
		cfg.FastWithdrawal.ResponseTimeout = 300 // 5 minutes
	}
	if cfg.FastWithdrawal.MinValidators == 0 {
		cfg.FastWithdrawal.MinValidators = 3
	}
	if cfg.Log.Level == "" {
		cfg.Log.Level = "info"
	}
	if cfg.Log.Format == "" {
		cfg.Log.Format = "text"
	}

	return &cfg, nil
}

// Validate 설정 유효성 검사
func (c *Config) Validate() error {
	if c.Aggregator.Address == "" {
		return fmt.Errorf("aggregator.address is required")
	}
	if c.Aggregator.PrivateKey == "" {
		return fmt.Errorf("aggregator.private_key is required")
	}
	if c.L1.RPC == "" {
		return fmt.Errorf("l1.rpc is required")
	}
	if c.L1.RATContract == "" {
		return fmt.Errorf("l1.rat_contract is required")
	}
	if c.P2P.ListenAddr == "" {
		return fmt.Errorf("p2p.listen_addr is required")
	}

	return nil
}
