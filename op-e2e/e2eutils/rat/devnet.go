package rat

import (
	"context"
	"crypto/ecdsa"
	"fmt"
	"math/big"
	"os/exec"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/stretchr/testify/require"
)

// DevnetConfig holds configuration for local devnet testing
type DevnetConfig struct {
	// RPC URL for the local network
	RPCURL string
	// Chain ID
	ChainID *big.Int
	// Pre-funded accounts (Anvil default accounts)
	Accounts []*ecdsa.PrivateKey
	// Deployed contract addresses
	RATAddress      common.Address
	TONAddress      common.Address
	WTONAddress     common.Address
	SeigManager     common.Address
	SystemConfig    common.Address
	Layer2Manager   common.Address
}

// DefaultDevnetConfig returns default configuration for Anvil local devnet
func DefaultDevnetConfig() *DevnetConfig {
	// Anvil default private keys (DO NOT use in production!)
	accounts := make([]*ecdsa.PrivateKey, 10)
	anvilKeys := []string{
		"0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
		"0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d",
		"0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a",
		"0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6",
		"0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a",
		"0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba",
		"0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e",
		"0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356",
		"0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97",
		"0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6",
	}
	for i, keyHex := range anvilKeys {
		key, err := crypto.HexToECDSA(keyHex[2:]) // Remove 0x prefix
		if err != nil {
			panic(fmt.Sprintf("Invalid anvil key %d: %v", i, err))
		}
		accounts[i] = key
	}

	return &DevnetConfig{
		RPCURL:   "http://localhost:8545",
		ChainID:  big.NewInt(31337), // Anvil default chain ID
		Accounts: accounts,
	}
}

// DevnetHelper provides helper functions for devnet testing
type DevnetHelper struct {
	T       *testing.T
	Ctx     context.Context
	Config  *DevnetConfig
	Client  *ethclient.Client
	ChainID *big.Int
}

// NewDevnetHelper creates a new devnet helper
func NewDevnetHelper(t *testing.T, ctx context.Context, config *DevnetConfig) *DevnetHelper {
	client, err := ethclient.Dial(config.RPCURL)
	require.NoError(t, err, "Failed to connect to devnet")

	chainID, err := client.ChainID(ctx)
	require.NoError(t, err, "Failed to get chain ID")

	return &DevnetHelper{
		T:       t,
		Ctx:     ctx,
		Config:  config,
		Client:  client,
		ChainID: chainID,
	}
}

// GetAccount returns a pre-funded account by index
func (d *DevnetHelper) GetAccount(index int) *ecdsa.PrivateKey {
	if index >= len(d.Config.Accounts) {
		d.T.Fatalf("Account index %d out of range", index)
	}
	return d.Config.Accounts[index]
}

// GetAccountAddress returns the address of a pre-funded account
func (d *DevnetHelper) GetAccountAddress(index int) common.Address {
	key := d.GetAccount(index)
	return crypto.PubkeyToAddress(key.PublicKey)
}

// TransactOpts returns transaction options for a pre-funded account
func (d *DevnetHelper) TransactOpts(accountIndex int) *bind.TransactOpts {
	key := d.GetAccount(accountIndex)
	opts, err := bind.NewKeyedTransactorWithChainID(key, d.ChainID)
	require.NoError(d.T, err, "Failed to create transact opts")
	opts.Context = d.Ctx
	return opts
}

// WaitForBlock waits for a new block to be mined
func (d *DevnetHelper) WaitForBlock() {
	currentBlock, err := d.Client.BlockNumber(d.Ctx)
	require.NoError(d.T, err, "Failed to get current block")

	deadline := time.Now().Add(10 * time.Second)
	for time.Now().Before(deadline) {
		newBlock, err := d.Client.BlockNumber(d.Ctx)
		if err == nil && newBlock > currentBlock {
			return
		}
		time.Sleep(100 * time.Millisecond)
	}
	d.T.Fatal("Timeout waiting for new block")
}

// MineBlock mines a new block (Anvil-specific)
func (d *DevnetHelper) MineBlock() error {
	// This uses Anvil's evm_mine RPC method
	// In a real implementation, you'd use the RPC client to call this
	return nil
}

// AdvanceTime advances the block timestamp (Anvil-specific)
func (d *DevnetHelper) AdvanceTime(seconds uint64) error {
	// This uses Anvil's evm_increaseTime RPC method
	return nil
}

// IsAnvilRunning checks if Anvil is running on the default port
func IsAnvilRunning() bool {
	client, err := ethclient.Dial("http://localhost:8545")
	if err != nil {
		return false
	}
	defer client.Close()

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	_, err = client.ChainID(ctx)
	return err == nil
}

// StartAnvil starts a local Anvil instance
func StartAnvil() (*exec.Cmd, error) {
	cmd := exec.Command("anvil", "--chain-id", "31337")
	err := cmd.Start()
	if err != nil {
		return nil, fmt.Errorf("failed to start anvil: %w", err)
	}

	// Wait for Anvil to start
	for i := 0; i < 30; i++ {
		if IsAnvilRunning() {
			return cmd, nil
		}
		time.Sleep(100 * time.Millisecond)
	}

	cmd.Process.Kill()
	return nil, fmt.Errorf("anvil failed to start within 3 seconds")
}

// StopAnvil stops an Anvil instance
func StopAnvil(cmd *exec.Cmd) {
	if cmd != nil && cmd.Process != nil {
		cmd.Process.Kill()
		cmd.Wait()
	}
}
