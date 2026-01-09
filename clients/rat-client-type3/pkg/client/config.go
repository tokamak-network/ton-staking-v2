package client

import (
	"crypto/ecdsa"
	"fmt"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
)

// VerificationMode determines how RAT Client verifies L2 state
type VerificationMode string

const (
	// VerificationModeOpNode uses op-node Rollup RPC (100% trustless, requires op-node)
	VerificationModeOpNode VerificationMode = "opnode"

	// VerificationModeL2RPC uses L2 RPC with proof verification (fast, requires L2 RPC cooperation)
	VerificationModeL2RPC VerificationMode = "l2rpc"

	// VerificationModeHybrid tries op-node first, falls back to L2 RPC (recommended)
	VerificationModeHybrid VerificationMode = "hybrid"

	// VerificationModeStateless uses local stateless executor (100% trustless, no dependencies)
	VerificationModeStateless VerificationMode = "stateless"
)

// Config holds the configuration for RAT Client Type 3
type Config struct {
	// Verification strategy
	VerificationMode VerificationMode

	// RPC endpoints
	L1RPCURL    string
	L1BeaconURL string   // L1 Beacon API for EIP-4844 blobs
	RPCURLs     []string // RPC endpoints (op-node or L2 geth, multiple for redundancy)
	StateDBPath string   // Path to op-geth state database (for adjacent leaves verification)

	// Validator identity
	PrivateKeyHex    string
	privateKey       *ecdsa.PrivateKey
	ValidatorAddress common.Address

	// Contract addresses
	RATContract         common.Address
	SystemConfig        common.Address
	BatchInbox          common.Address
	BatcherAddress      common.Address
	DisputeGameFactory  common.Address
	L1BridgeRegistry    common.Address
	L2ToL1MessagePasser common.Address

	// Monitoring
	PollInterval     time.Duration
	Confirmations    uint64
	StartBlockNumber uint64

	// Submission
	DeadlineBuffer time.Duration
	GasLimit       uint64
	MaxGasPrice    uint64

	// op-node specific settings
	OpNodeMaxWaitTime   time.Duration // Max time to wait for op-node sync
	OpNodeCheckInterval time.Duration // How often to check op-node sync status

	// L2 RPC specific settings
	EnableProofVerification bool          // Enable Merkle proof verification for L2 RPC
	L2RPCTimeout            time.Duration // Timeout for L2 RPC calls

	// Stateless executor settings
	EnableBackgroundSync bool   // Enable background sync for stateless executor
	StateDBCacheSize     uint64 // State DB cache size in MB
	TrieCacheSize        uint64 // Trie cache size in MB

	// Logging
	LogLevel string
}

// DefaultConfig returns default configuration
func DefaultConfig() *Config {
	return &Config{
		// Verification mode (default: hybrid for safety + flexibility)
		VerificationMode: VerificationModeHybrid,

		// RPC endpoints
		L1RPCURL:    "http://localhost:8545",
		L1BeaconURL: "http://localhost:5052",
		RPCURLs: []string{
			"http://localhost:9545", // Primary RPC (op-node or L2 geth)
		},
		StateDBPath: "", // Path to op-geth chaindata directory (required for adjacent leaves)

		// Monitoring
		PollInterval:     12 * time.Second,
		Confirmations:    64,
		StartBlockNumber: 0,

		// Submission
		DeadlineBuffer: 10 * time.Minute,
		GasLimit:       500000,
		MaxGasPrice:    500_000_000_000,

		// op-node settings
		OpNodeMaxWaitTime:   30 * time.Minute,
		OpNodeCheckInterval: 10 * time.Second,

		// L2 RPC settings
		EnableProofVerification: true,
		L2RPCTimeout:            20 * time.Minute,

		// Stateless executor settings
		EnableBackgroundSync: true,
		StateDBCacheSize:     1024, // 1GB
		TrieCacheSize:        256,  // 256MB

		// Logging
		LogLevel: "info",

		// Contract addresses
		L2ToL1MessagePasser: common.HexToAddress("0x4200000000000000000000000000000000000016"),
	}
}

// LoadPrivateKey loads the private key from hex string
func (c *Config) LoadPrivateKey() error {
	if c.PrivateKeyHex == "" {
		return fmt.Errorf("private key not configured")
	}

	keyHex := c.PrivateKeyHex
	if len(keyHex) >= 2 && keyHex[:2] == "0x" {
		keyHex = keyHex[2:]
	}

	privateKey, err := crypto.HexToECDSA(keyHex)
	if err != nil {
		return fmt.Errorf("failed to parse private key: %w", err)
	}

	c.privateKey = privateKey
	publicKey := privateKey.Public().(*ecdsa.PublicKey)
	c.ValidatorAddress = crypto.PubkeyToAddress(*publicKey)

	return nil
}

// GetPrivateKey returns the loaded private key
func (c *Config) GetPrivateKey() *ecdsa.PrivateKey {
	return c.privateKey
}

// Validate checks configuration
func (c *Config) Validate() error {
	// Common validation
	if c.L1RPCURL == "" {
		return fmt.Errorf("L1 RPC URL required")
	}
	if c.privateKey == nil {
		return fmt.Errorf("private key not loaded")
	}
	if c.RATContract == (common.Address{}) {
		return fmt.Errorf("RAT contract required")
	}
	if c.SystemConfig == (common.Address{}) {
		return fmt.Errorf("SystemConfig required")
	}

	// Verification mode specific validation
	switch c.VerificationMode {
	case VerificationModeOpNode, VerificationModeL2RPC, VerificationModeHybrid:
		if len(c.RPCURLs) == 0 {
			return fmt.Errorf("at least one RPC URL required for %s mode", c.VerificationMode)
		}

	case VerificationModeStateless:
		// Stateless mode only needs L1
		if c.BatchInbox == (common.Address{}) {
			return fmt.Errorf("batch inbox address required for stateless mode")
		}
		if c.L1BeaconURL == "" {
			return fmt.Errorf("L1 Beacon URL required for stateless mode (EIP-4844 blobs)")
		}

	default:
		return fmt.Errorf("invalid verification mode: %s", c.VerificationMode)
	}

	return nil
}

// GetRPCURLs returns all configured RPC URLs
func (c *Config) GetRPCURLs() []string {
	return c.RPCURLs
}

// GetPrimaryRPC returns the first RPC URL
func (c *Config) GetPrimaryRPC() string {
	if len(c.RPCURLs) > 0 {
		return c.RPCURLs[0]
	}
	return ""
}
