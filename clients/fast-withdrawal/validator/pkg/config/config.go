package config

import (
	"fmt"
	"os"

	"gopkg.in/yaml.v3"
)

// Config 전체 설정 구조
type Config struct {
	// Validator Identity
	Validator ValidatorConfig `yaml:"validator"`

	// L1 Connection
	L1 L1Config `yaml:"l1"`

	// L2 Connection (Type3 검증용)
	L2 L2Config `yaml:"l2"`

	// libp2p Network
	P2P P2PConfig `yaml:"p2p"`

	// Logging
	Log LogConfig `yaml:"log"`
}

type ValidatorConfig struct {
	Address       string `yaml:"address"`         // Ethereum address
	BLSPrivateKey string `yaml:"bls_private_key"` // Hex string or keystore path
}

type L1Config struct {
	RPC          string `yaml:"rpc"`
	RATContract  string `yaml:"rat_contract"`
	SystemConfig string `yaml:"system_config"` // mDNS/DHT 디스커버리용
}

type L2Config struct {
	RPC       string `yaml:"rpc"`        // op-geth with debug API
	OpNodeRPC string `yaml:"opnode_rpc"` // optional, for OutputRootProof
}

type P2PConfig struct {
	ListenAddr      string   `yaml:"listen_addr"` // e.g. "/ip4/0.0.0.0/tcp/9000"
	BootstrapPeers  []string `yaml:"bootstrap_peers"`
	DHTNamespace    string   `yaml:"dht_namespace"`    // default: "/tokamak-rat-validators"
	WithdrawalTopic string   `yaml:"withdrawal_topic"` // default: "/tokamak/rat/withdrawal/1.0.0"
}

type LogConfig struct {
	Level  string `yaml:"level"`  // debug, info, warn, error
	Format string `yaml:"format"` // json, text
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
	if c.Validator.Address == "" {
		return fmt.Errorf("validator.address is required")
	}
	if c.Validator.BLSPrivateKey == "" {
		return fmt.Errorf("validator.bls_private_key is required")
	}
	if c.L1.RPC == "" {
		return fmt.Errorf("l1.rpc is required")
	}
	if c.L1.RATContract == "" {
		return fmt.Errorf("l1.rat_contract is required")
	}
	if c.L2.RPC == "" {
		return fmt.Errorf("l2.rpc is required")
	}
	if c.P2P.ListenAddr == "" {
		return fmt.Errorf("p2p.listen_addr is required")
	}

	return nil
}
