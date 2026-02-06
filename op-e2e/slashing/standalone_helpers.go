// Package slashing provides standalone helpers for TON slashing tests.
//
// This file contains helpers that don't require Optimism packages and work with
// MockFaultDisputeGame3 for standalone testing.
package slashing

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

	// TON packages
	"github.com/tokamak-network/ton-staking-v2/op-e2e/bindings"
	rat "github.com/tokamak-network/ton-staking-v2/op-e2e/e2eutils/rat"
)

// ============================================================================
// Types for Standalone Test Environment
// ============================================================================

// StandaloneTestEnv provides a test environment for TON slashing tests
// using MockFaultDisputeGame3 without requiring the full Optimism devnet.
type StandaloneTestEnv struct {
	T *testing.T

	// L1 client from RAT system
	L1Client *ethclient.Client

	// TON deployment addresses
	TONAddresses *StandaloneTONAddresses

	// Context for operations
	Ctx context.Context

	// Slashing contracts connected to L1
	SlashingContracts *SlashingContracts

	// RAT system for TON operations
	RATSystem *rat.TONStakingSystem
}

// StandaloneTONAddresses contains TON contract addresses.
type StandaloneTONAddresses struct {
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

// ============================================================================
// Standalone Test Environment Setup
// ============================================================================

// StartStandaloneTestEnv starts a test environment using the existing
// TON Staking system (Anvil-based) with MockFaultDisputeGame3.
// Use this for faster tests that don't need the full Optimism devnet.
func StartStandaloneTestEnv(t *testing.T) *StandaloneTestEnv {
	ctx := context.Background()

	t.Log("=== Starting Standalone Test Environment ===")

	// Start TON Staking system using existing rat helper
	ratSys := rat.StartTONStakingSystem(t)
	t.Log("✓ TON Staking system started")

	// Convert addresses
	tonAddresses := convertFromRATToStandalone(ratSys.Addresses)
	t.Logf("  TON: %s", tonAddresses.TON.Hex())
	t.Logf("  SeigManager: %s", tonAddresses.SeigManagerProxy.Hex())

	env := &StandaloneTestEnv{
		T:            t,
		L1Client:     ratSys.L1Client,
		TONAddresses: tonAddresses,
		Ctx:          ctx,
		RATSystem:    ratSys,
	}

	// Connect to slashing contracts
	env.SlashingContracts = connectSlashingContracts(t, ratSys)
	t.Log("✓ Slashing contracts connected")

	t.Log("=== Standalone Test Environment Ready ===")
	return env
}

// Close shuts down the test environment.
func (env *StandaloneTestEnv) Close() {
	if env.RATSystem != nil {
		env.RATSystem.Close()
	}
}

// ============================================================================
// TON Challenger Helper for Standalone Tests
// ============================================================================

// StandaloneChallengerHelper provides methods to interact with MockFaultDisputeGame3
// for standalone TON slashing tests.
type StandaloneChallengerHelper struct {
	t       *testing.T
	ctx     context.Context
	env     *StandaloneTestEnv
	auth    *bind.TransactOpts
	address common.Address
}

// NewStandaloneChallengerHelper creates a new standalone challenger helper.
func NewStandaloneChallengerHelper(t *testing.T, ctx context.Context, env *StandaloneTestEnv, auth *bind.TransactOpts) *StandaloneChallengerHelper {
	return &StandaloneChallengerHelper{
		t:       t,
		ctx:     ctx,
		env:     env,
		auth:    auth,
		address: auth.From,
	}
}

// Attack submits an attack move to the dispute game.
func (c *StandaloneChallengerHelper) Attack(gameAddr common.Address, claim [32]byte) error {
	game, err := bindings.NewMockFaultDisputeGame3(gameAddr, c.env.L1Client)
	if err != nil {
		return err
	}

	tx, err := game.Move(c.auth, big.NewInt(0), claim, true)
	if err != nil {
		return err
	}

	_, err = bind.WaitMined(c.ctx, c.env.L1Client, tx)
	return err
}

// ResolveGame resolves all claims and returns the final game status.
func (c *StandaloneChallengerHelper) ResolveGame(gameAddr common.Address) (uint8, error) {
	game, err := bindings.NewMockFaultDisputeGame3(gameAddr, c.env.L1Client)
	if err != nil {
		return 0, err
	}

	// Try to resolve claims
	tx, err := game.ResolveClaim(c.auth, big.NewInt(1))
	if err == nil {
		bind.WaitMined(c.ctx, c.env.L1Client, tx)
	}

	tx, err = game.ResolveClaim(c.auth, big.NewInt(0))
	if err == nil {
		bind.WaitMined(c.ctx, c.env.L1Client, tx)
	}

	// Resolve the game
	tx, err = game.Resolve(c.auth)
	if err != nil {
		return 0, err
	}

	_, err = bind.WaitMined(c.ctx, c.env.L1Client, tx)
	if err != nil {
		return 0, err
	}

	callOpts := &bind.CallOpts{Context: c.ctx}
	return game.Status(callOpts)
}

// IsWinningChallenger checks if this challenger is a winning challenger.
func (c *StandaloneChallengerHelper) IsWinningChallenger(gameAddr common.Address) (bool, error) {
	game, err := bindings.NewMockFaultDisputeGame3(gameAddr, c.env.L1Client)
	if err != nil {
		return false, err
	}

	callOpts := &bind.CallOpts{Context: c.ctx}
	return game.IsWinningChallenger(callOpts, c.address)
}

// ============================================================================
// Account Helpers
// ============================================================================

// GetTestAccount returns a test account for the specified role.
func (env *StandaloneTestEnv) GetTestAccount(role string) (*ecdsa.PrivateKey, *bind.TransactOpts, error) {
	var hexKey string
	switch role {
	case "deployer":
		hexKey = "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
	case "proposer":
		hexKey = "59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
	case "challenger":
		hexKey = "5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"
	case "validator":
		hexKey = "7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6"
	case "delegator":
		hexKey = "47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a"
	case "alice":
		hexKey = "8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba"
	default:
		return nil, nil, fmt.Errorf("unknown role: %s", role)
	}

	key, err := crypto.HexToECDSA(hexKey)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to parse private key: %w", err)
	}

	chainID, err := env.L1Client.ChainID(env.Ctx)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to get chain ID: %w", err)
	}

	auth, err := bind.NewKeyedTransactorWithChainID(key, chainID)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to create transactor: %w", err)
	}
	auth.GasLimit = 5000000

	return key, auth, nil
}

// ============================================================================
// Game Status Helpers
// ============================================================================

// GetGameStatus returns the current status of a dispute game (MockFaultDisputeGame3).
func (env *StandaloneTestEnv) GetGameStatus(gameAddress common.Address) (uint8, error) {
	game, err := bindings.NewMockFaultDisputeGame3(gameAddress, env.L1Client)
	if err != nil {
		return 0, fmt.Errorf("failed to connect to game: %w", err)
	}

	callOpts := &bind.CallOpts{Context: env.Ctx}
	return game.Status(callOpts)
}

// ============================================================================
// TON Slashing Integration
// ============================================================================

// ExecuteTONSlashing executes TON slashing for a resolved dispute game.
func (env *StandaloneTestEnv) ExecuteTONSlashing(
	ctx context.Context,
	challengerAuth *bind.TransactOpts,
	operatorManager common.Address,
	gameAddress common.Address,
	rootClaim [32]byte,
	extraData []byte,
) error {
	if env.SlashingContracts == nil {
		return fmt.Errorf("slashing contracts not connected")
	}

	gameType := uint32(0) // FaultDisputeGame type

	tx, err := env.SlashingContracts.Layer2ManagerSlashing.SlashingCandidate(
		challengerAuth,
		operatorManager,
		gameType,
		rootClaim,
		extraData,
		gameAddress,
	)
	if err != nil {
		return fmt.Errorf("failed to execute slashing: %w", err)
	}

	receipt, err := bind.WaitMined(ctx, env.L1Client, tx)
	if err != nil {
		return fmt.Errorf("failed to wait for slashing tx: %w", err)
	}

	if receipt.Status != 1 {
		return fmt.Errorf("slashing transaction failed")
	}

	env.T.Logf("✓ TON slashing executed for operator: %s", operatorManager.Hex())
	return nil
}

// RegisterOperatorForSlashingTest registers an operator with CandidateAddOn for testing.
func (env *StandaloneTestEnv) RegisterOperatorForSlashingTest(
	operatorAuth *bind.TransactOpts,
	stakeAmount *big.Int,
) (common.Address, common.Address, common.Address, error) {
	if env.SlashingContracts == nil || env.RATSystem == nil {
		return common.Address{}, common.Address{}, common.Address{}, fmt.Errorf("TON contracts not connected")
	}

	candidateAddOn, operatorManager, rollupConfig := registerOperatorWithCandidateAddOn(
		env.T,
		env.RATSystem,
		env.SlashingContracts,
		operatorAuth,
		stakeAmount,
	)

	return candidateAddOn, operatorManager, rollupConfig, nil
}

// ============================================================================
// Internal Helper Functions
// ============================================================================

func loadStandaloneTONAddressesFromGenesis(t *testing.T) (*StandaloneTONAddresses, error) {
	projectRoot, err := findProjectRootForStandalone()
	if err != nil {
		return nil, fmt.Errorf("failed to find project root: %w", err)
	}

	addressesPath := filepath.Join(projectRoot, ".devnet", "addresses.json")
	data, err := os.ReadFile(addressesPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read addresses file: %w", err)
	}

	var addresses StandaloneTONAddresses
	if err := json.Unmarshal(data, &addresses); err != nil {
		return nil, fmt.Errorf("failed to parse addresses file: %w", err)
	}

	return &addresses, nil
}

func findProjectRootForStandalone() (string, error) {
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

func convertFromRATToStandalone(ratAddr *rat.DeploymentAddresses) *StandaloneTONAddresses {
	return &StandaloneTONAddresses{
		ChainID:                ratAddr.ChainID,
		RPCURL:                 ratAddr.RPCURL,
		TON:                    ratAddr.TON,
		WTON:                   ratAddr.WTON,
		CoinageFactory:         ratAddr.CoinageFactory,
		Layer2RegistryProxy:    ratAddr.Layer2RegistryProxy,
		SeigManagerProxy:       ratAddr.SeigManagerProxy,
		DepositManagerProxy:    ratAddr.DepositManagerProxy,
		Layer2ManagerProxy:     ratAddr.Layer2ManagerProxy,
		L1BridgeRegistryProxy:  ratAddr.L1BridgeRegistryProxy,
		OperatorManagerFactory: ratAddr.OperatorManagerFactory,
		RATProxy:               ratAddr.RATProxy,
		ValidatorRewardProxy:   ratAddr.ValidatorRewardProxy,
		SequencerVaultProxy:    ratAddr.SequencerVaultProxy,
		DisputeGameFactory:     ratAddr.DisputeGameFactory,
		SystemConfig:           ratAddr.SystemConfig,
		AnchorStateRegistry:    ratAddr.AnchorStateRegistry,
		MockLayer2:             ratAddr.MockLayer2,
		MockSystemConfig:       ratAddr.MockSystemConfig,
	}
}
