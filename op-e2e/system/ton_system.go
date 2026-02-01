// Package system provides TON Staking V3 system wrappers for E2E testing.
// This package wraps Optimism's e2esys.System with TON-specific contract deployments.
package system

import (
	"context"
	"crypto/ecdsa"
	"encoding/json"
	"fmt"
	"math/big"
	"os"
	"path/filepath"
	"testing"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/stretchr/testify/require"
	"github.com/tokamak-network/ton-staking-v2/op-e2e/bindings"
)

// TONDeploymentAddresses contains all deployed TON Staking V3 contract addresses.
type TONDeploymentAddresses struct {
	ChainID                  int64          `json:"chainId"`
	RPCURL                   string         `json:"rpcUrl"`
	TON                      common.Address `json:"ton"`
	WTON                     common.Address `json:"wton"`
	CoinageFactory           common.Address `json:"coinageFactory"`
	Layer2RegistryProxy      common.Address `json:"layer2RegistryProxy"`
	SeigManagerProxy         common.Address `json:"seigManagerProxy"`
	DepositManagerProxy      common.Address `json:"depositManagerProxy"`
	Layer2ManagerProxy       common.Address `json:"layer2ManagerProxy"`
	L1BridgeRegistryProxy    common.Address `json:"l1BridgeRegistryProxy"`
	OperatorManagerFactory   common.Address `json:"operatorManagerFactory"`
	RATProxy                 common.Address `json:"ratProxy"`
	ValidatorRewardProxy     common.Address `json:"validatorRewardProxy"`
	SequencerVaultProxy      common.Address `json:"sequencerVaultProxy"`
	DisputeGameFactory       common.Address `json:"disputeGameFactory"`
	SystemConfig             common.Address `json:"systemConfig"`
	AnchorStateRegistry      common.Address `json:"anchorStateRegistry"`
	MockLayer2               common.Address `json:"mockLayer2"`
	MockSystemConfig         common.Address `json:"mockSystemConfig"`
	WinningChallengerTracker common.Address `json:"winningChallengerTracker"`
}

// TONSystem represents a running TON Staking V3 system for E2E testing.
// It wraps Optimism's e2esys.System and adds TON-specific functionality.
type TONSystem struct {
	T           *testing.T
	Ctx         context.Context
	L1Client    *ethclient.Client
	L1RPCURL    string
	Addresses   *TONDeploymentAddresses
	PrivateKeys map[string]*ecdsa.PrivateKey
	Accounts    map[string]*TestAccount
}

// TestAccount represents a test account with private key and transactor.
type TestAccount struct {
	Name       string
	PrivateKey *ecdsa.PrivateKey
	Address    common.Address
	Auth       *bind.TransactOpts
}

// TONSystemConfig holds configuration for starting the TON system.
type TONSystemConfig struct {
	// GenesisPath is the path to the genesis file
	GenesisPath string
	// AddressesPath is the path to the addresses file
	AddressesPath string
	// RPCURL is the RPC URL for the L1 client
	RPCURL string
	// ChainID is the chain ID
	ChainID int64
}

// DefaultTONSystemConfig returns the default configuration for TON system.
func DefaultTONSystemConfig(t *testing.T) *TONSystemConfig {
	projectRoot, err := findProjectRoot()
	require.NoError(t, err, "Failed to find project root")

	return &TONSystemConfig{
		GenesisPath:   filepath.Join(projectRoot, ".devnet", "genesis-l1-staking-v3.json"),
		AddressesPath: filepath.Join(projectRoot, ".devnet", "addresses.json"),
		RPCURL:        "", // Will be set dynamically
		ChainID:       900,
	}
}

// TONSystemOption is a function that modifies TONSystemConfig.
type TONSystemOption func(*TONSystemConfig)

// WithGenesisPath sets a custom genesis file path.
func WithGenesisPath(path string) TONSystemOption {
	return func(cfg *TONSystemConfig) {
		cfg.GenesisPath = path
	}
}

// WithAddressesPath sets a custom addresses file path.
func WithAddressesPath(path string) TONSystemOption {
	return func(cfg *TONSystemConfig) {
		cfg.AddressesPath = path
	}
}

// WithRPCURL sets a custom RPC URL.
func WithRPCURL(url string) TONSystemOption {
	return func(cfg *TONSystemConfig) {
		cfg.RPCURL = url
	}
}

// WithChainID sets a custom chain ID.
func WithChainID(chainID int64) TONSystemOption {
	return func(cfg *TONSystemConfig) {
		cfg.ChainID = chainID
	}
}

// StartTONFaultDisputeSystem starts a TON Staking V3 system for fault dispute testing.
// It loads deployment addresses and connects to an existing L1 node (e.g., Anvil).
func StartTONFaultDisputeSystem(t *testing.T, l1Client *ethclient.Client, opts ...TONSystemOption) *TONSystem {
	ctx := context.Background()
	cfg := DefaultTONSystemConfig(t)

	for _, opt := range opts {
		opt(cfg)
	}

	// Read deployment addresses
	addresses, err := loadDeploymentAddresses(cfg.AddressesPath)
	require.NoError(t, err, "Failed to load deployment addresses")

	// Setup test accounts with standard mnemonic
	accounts := setupTestAccounts(t, cfg.ChainID)

	sys := &TONSystem{
		T:           t,
		Ctx:         ctx,
		L1Client:    l1Client,
		L1RPCURL:    cfg.RPCURL,
		Addresses:   addresses,
		PrivateKeys: make(map[string]*ecdsa.PrivateKey),
		Accounts:    accounts,
	}

	t.Logf("TON System started with addresses:")
	t.Logf("  TON: %s", addresses.TON.Hex())
	t.Logf("  WTON: %s", addresses.WTON.Hex())
	t.Logf("  SeigManager: %s", addresses.SeigManagerProxy.Hex())
	t.Logf("  DepositManager: %s", addresses.DepositManagerProxy.Hex())
	t.Logf("  DisputeGameFactory: %s", addresses.DisputeGameFactory.Hex())

	return sys
}

// loadDeploymentAddresses loads contract addresses from a JSON file.
func loadDeploymentAddresses(path string) (*TONDeploymentAddresses, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("failed to read addresses file: %w", err)
	}

	var addresses TONDeploymentAddresses
	if err := json.Unmarshal(data, &addresses); err != nil {
		return nil, fmt.Errorf("failed to parse addresses file: %w", err)
	}

	return &addresses, nil
}

// setupTestAccounts creates test accounts from the standard test mnemonic.
// Uses the same mnemonic as Anvil: "test test test test test test test test test test test junk"
func setupTestAccounts(t *testing.T, chainID int64) map[string]*TestAccount {
	// Standard Anvil/Hardhat private keys
	privateKeys := map[string]string{
		"deployer":   "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80", // Account #0
		"proposer":   "59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d", // Account #1
		"challenger": "5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a", // Account #2
		"validator":  "7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6", // Account #3
		"delegator":  "47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a", // Account #4
	}

	accounts := make(map[string]*TestAccount)
	for name, hexKey := range privateKeys {
		key, err := crypto.HexToECDSA(hexKey)
		require.NoError(t, err, "Failed to parse private key for %s", name)

		addr := crypto.PubkeyToAddress(key.PublicKey)
		auth, err := bind.NewKeyedTransactorWithChainID(key, big.NewInt(chainID))
		require.NoError(t, err, "Failed to create transactor for %s", name)
		auth.GasLimit = 3000000

		accounts[name] = &TestAccount{
			Name:       name,
			PrivateKey: key,
			Address:    addr,
			Auth:       auth,
		}
	}

	return accounts
}

// findProjectRoot finds the project root directory.
func findProjectRoot() (string, error) {
	dir, err := os.Getwd()
	if err != nil {
		return "", err
	}

	for {
		makefilePath := filepath.Join(dir, "Makefile")
		devnetPath := filepath.Join(dir, ".devnet")

		if _, err := os.Stat(makefilePath); err == nil {
			if _, err := os.Stat(devnetPath); err == nil {
				return dir, nil
			}
		}

		parent := filepath.Dir(dir)
		if parent == dir {
			return "", fmt.Errorf("project root not found (looking for Makefile + .devnet)")
		}
		dir = parent
	}
}

// GetAccount returns a test account by name.
func (s *TONSystem) GetAccount(name string) *TestAccount {
	return s.Accounts[name]
}

// Deployer returns the deployer account.
func (s *TONSystem) Deployer() *TestAccount {
	return s.Accounts["deployer"]
}

// Proposer returns the proposer account.
func (s *TONSystem) Proposer() *TestAccount {
	return s.Accounts["proposer"]
}

// Challenger returns the challenger account.
func (s *TONSystem) Challenger() *TestAccount {
	return s.Accounts["challenger"]
}

// Validator returns the validator account.
func (s *TONSystem) Validator() *TestAccount {
	return s.Accounts["validator"]
}

// Delegator returns the delegator account.
func (s *TONSystem) Delegator() *TestAccount {
	return s.Accounts["delegator"]
}

// AdvanceTime advances the blockchain time by the specified seconds.
func (s *TONSystem) AdvanceTime(seconds int64) error {
	var result interface{}
	err := s.L1Client.Client().Call(&result, "evm_increaseTime", seconds)
	if err != nil {
		return fmt.Errorf("failed to advance time: %w", err)
	}

	// Mine a block to apply the time change
	err = s.L1Client.Client().Call(&result, "evm_mine")
	if err != nil {
		return fmt.Errorf("failed to mine block: %w", err)
	}

	return nil
}

// AdvanceBlocks mines the specified number of blocks.
func (s *TONSystem) AdvanceBlocks(numBlocks int) error {
	var result interface{}
	err := s.L1Client.Client().Call(&result, "anvil_mine", numBlocks)
	if err != nil {
		return fmt.Errorf("failed to mine blocks: %w", err)
	}
	return nil
}

// GetWTON returns a WTON contract binding.
func (s *TONSystem) GetWTON() (*bindings.WTON, error) {
	return bindings.NewWTON(s.Addresses.WTON, s.L1Client)
}

// GetDepositManager returns a DepositManager contract binding.
func (s *TONSystem) GetDepositManager() (*bindings.DepositManagerSlashing, error) {
	return bindings.NewDepositManagerSlashing(s.Addresses.DepositManagerProxy, s.L1Client)
}

// GetLayer2Manager returns a Layer2Manager contract binding.
func (s *TONSystem) GetLayer2Manager() (*bindings.Layer2ManagerSlashing, error) {
	return bindings.NewLayer2ManagerSlashing(s.Addresses.Layer2ManagerProxy, s.L1Client)
}

// GetSeigManager returns a SeigManager contract binding.
func (s *TONSystem) GetSeigManager() (*bindings.SeigManagerSlashing, error) {
	return bindings.NewSeigManagerSlashing(s.Addresses.SeigManagerProxy, s.L1Client)
}

// GetDisputeGameFactory3 returns a MockDisputeGameFactory3 contract binding.
func (s *TONSystem) GetDisputeGameFactory3(addr common.Address) (*bindings.MockDisputeGameFactory3, error) {
	return bindings.NewMockDisputeGameFactory3(addr, s.L1Client)
}

// GetFaultDisputeGame3 returns a MockFaultDisputeGame3 contract binding.
func (s *TONSystem) GetFaultDisputeGame3(addr common.Address) (*bindings.MockFaultDisputeGame3, error) {
	return bindings.NewMockFaultDisputeGame3(addr, s.L1Client)
}

// CreateDisputeGame creates a new dispute game using MockDisputeGameFactory3.
func (s *TONSystem) CreateDisputeGame(auth *bind.TransactOpts, factoryAddr common.Address, gameType uint32, rootClaim [32]byte, extraData []byte) (common.Address, error) {
	factory, err := s.GetDisputeGameFactory3(factoryAddr)
	if err != nil {
		return common.Address{}, fmt.Errorf("failed to get factory: %w", err)
	}

	tx, err := factory.Create(auth, gameType, rootClaim, extraData)
	if err != nil {
		return common.Address{}, fmt.Errorf("failed to create game: %w", err)
	}

	receipt, err := bind.WaitMined(s.Ctx, s.L1Client, tx)
	if err != nil {
		return common.Address{}, fmt.Errorf("failed to wait for tx: %w", err)
	}

	// Parse the DisputeGameCreated event to get the game address
	for _, log := range receipt.Logs {
		if len(log.Topics) >= 2 {
			// DisputeGameCreated event has game address as first indexed topic
			gameAddr := common.BytesToAddress(log.Topics[1].Bytes())
			return gameAddr, nil
		}
	}

	return common.Address{}, fmt.Errorf("game address not found in logs")
}

// GetWinningChallengers returns the winning challengers from a dispute game.
func (s *TONSystem) GetWinningChallengers(gameAddr common.Address) ([]common.Address, error) {
	game, err := s.GetFaultDisputeGame3(gameAddr)
	if err != nil {
		return nil, fmt.Errorf("failed to get game: %w", err)
	}

	challengers, err := game.GetWinningChallengers(&bind.CallOpts{Context: s.Ctx})
	if err != nil {
		return nil, fmt.Errorf("failed to get winning challengers: %w", err)
	}

	return challengers, nil
}

// IsWinningChallenger checks if an address is a winning challenger.
func (s *TONSystem) IsWinningChallenger(gameAddr common.Address, challenger common.Address) (bool, error) {
	game, err := s.GetFaultDisputeGame3(gameAddr)
	if err != nil {
		return false, fmt.Errorf("failed to get game: %w", err)
	}

	isWinner, err := game.IsWinningChallenger(&bind.CallOpts{Context: s.Ctx}, challenger)
	if err != nil {
		return false, fmt.Errorf("failed to check winning challenger: %w", err)
	}

	return isWinner, nil
}

// GetGameStatus returns the status of a dispute game.
func (s *TONSystem) GetGameStatus(gameAddr common.Address) (uint8, error) {
	game, err := s.GetFaultDisputeGame3(gameAddr)
	if err != nil {
		return 0, fmt.Errorf("failed to get game: %w", err)
	}

	status, err := game.Status(&bind.CallOpts{Context: s.Ctx})
	if err != nil {
		return 0, fmt.Errorf("failed to get game status: %w", err)
	}

	return status, nil
}

// GameStatus constants matching the Solidity enum.
const (
	GameStatusInProgress    uint8 = 0
	GameStatusChallengerWon uint8 = 1
	GameStatusDefenderWon   uint8 = 2
)

// GetWinningChallengerTracker returns a WinningChallengerTracker contract binding.
func (s *TONSystem) GetWinningChallengerTracker(addr common.Address) (*bindings.WinningChallengerTracker, error) {
	return bindings.NewWinningChallengerTracker(addr, s.L1Client)
}

// DeployWinningChallengerTracker deploys a new WinningChallengerTracker contract.
func (s *TONSystem) DeployWinningChallengerTracker(auth *bind.TransactOpts) (common.Address, *bindings.WinningChallengerTracker, error) {
	addr, tx, tracker, err := bindings.DeployWinningChallengerTracker(auth, s.L1Client)
	if err != nil {
		return common.Address{}, nil, fmt.Errorf("failed to deploy WinningChallengerTracker: %w", err)
	}

	_, err = bind.WaitMined(s.Ctx, s.L1Client, tx)
	if err != nil {
		return common.Address{}, nil, fmt.Errorf("failed to wait for deployment tx: %w", err)
	}

	return addr, tracker, nil
}

// GetWinningChallengersFromTracker returns the winning challengers from a dispute game
// using the external WinningChallengerTracker contract.
func (s *TONSystem) GetWinningChallengersFromTracker(trackerAddr, gameAddr common.Address) ([]common.Address, error) {
	tracker, err := s.GetWinningChallengerTracker(trackerAddr)
	if err != nil {
		return nil, fmt.Errorf("failed to get tracker: %w", err)
	}

	challengers, err := tracker.GetWinningChallengers(&bind.CallOpts{Context: s.Ctx}, gameAddr)
	if err != nil {
		return nil, fmt.Errorf("failed to get winning challengers from tracker: %w", err)
	}

	return challengers, nil
}

// IsWinningChallengerFromTracker checks if an address is a winning challenger
// using the external WinningChallengerTracker contract.
func (s *TONSystem) IsWinningChallengerFromTracker(trackerAddr, gameAddr, challenger common.Address) (bool, error) {
	tracker, err := s.GetWinningChallengerTracker(trackerAddr)
	if err != nil {
		return false, fmt.Errorf("failed to get tracker: %w", err)
	}

	isWinner, err := tracker.IsWinningChallenger(&bind.CallOpts{Context: s.Ctx}, gameAddr, challenger)
	if err != nil {
		return false, fmt.Errorf("failed to check winning challenger from tracker: %w", err)
	}

	return isWinner, nil
}

// GetWinningChallengersCountFromTracker returns the count of winning challengers
// for a dispute game using the external WinningChallengerTracker contract.
func (s *TONSystem) GetWinningChallengersCountFromTracker(trackerAddr, gameAddr common.Address) (*big.Int, error) {
	tracker, err := s.GetWinningChallengerTracker(trackerAddr)
	if err != nil {
		return nil, fmt.Errorf("failed to get tracker: %w", err)
	}

	count, err := tracker.GetWinningChallengersCount(&bind.CallOpts{Context: s.Ctx}, gameAddr)
	if err != nil {
		return nil, fmt.Errorf("failed to get winning challengers count from tracker: %w", err)
	}

	return count, nil
}
