// Package slashing provides helpers for TON slashing tests using real FaultDisputeGame.
//
// This file contains helpers that integrate Full Optimism devnet with TON slashing contracts.
// It replaces the Mock-based helpers with real op-challenger and FaultDisputeGame.sol.
package slashing

import (
	"context"
	"crypto/ecdsa"
	"math/big"
	"testing"
	"time"

	"github.com/ethereum-optimism/optimism/op-challenger/game/types"
	"github.com/ethereum-optimism/optimism/op-e2e/config/secrets"
	"github.com/ethereum-optimism/optimism/op-e2e/e2eutils/challenger"
	"github.com/ethereum-optimism/optimism/op-e2e/e2eutils/disputegame"
	"github.com/ethereum-optimism/optimism/op-e2e/e2eutils/wait"
	"github.com/ethereum-optimism/optimism/op-e2e/faultproofs"
	"github.com/ethereum-optimism/optimism/op-e2e/system/e2esys"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/stretchr/testify/require"
	"github.com/tokamak-network/ton-staking-v2/op-e2e/bindings"
	rat "github.com/tokamak-network/ton-staking-v2/op-e2e/e2eutils/rat"
)

// RealGameTestEnv provides a test environment for TON slashing tests
// using the real FaultDisputeGame.sol and Full Optimism devnet.
type RealGameTestEnv struct {
	T   *testing.T
	Ctx context.Context

	// Full Optimism devnet (L1+L2+op-node+batcher)
	System   *e2esys.System
	L1Client *ethclient.Client

	// Dispute game factory helper (from Optimism)
	GameFactory *disputegame.FactoryHelper

	// TON Staking system (for slashing contracts)
	RATSystem *rat.TONStakingSystem

	// Slashing contracts
	SlashingContracts *SlashingContracts
}

// StartRealGameTestEnv starts a Full Optimism devnet and connects TON slashing contracts.
// This is the main entry point for tests using real FaultDisputeGame.
func StartRealGameTestEnv(t *testing.T) *RealGameTestEnv {
	ctx := context.Background()

	t.Log("=== Starting Real Game Test Environment ===")
	t.Log("Starting Full Optimism devnet (L1+L2+op-node+batcher)...")

	// Start Full Optimism devnet using faultproofs infrastructure
	sys, l1Client := faultproofs.StartFaultDisputeSystem(t)
	t.Cleanup(sys.Close)
	t.Log("  Full Optimism devnet started")

	// Create dispute game factory helper
	gameFactory := disputegame.NewFactoryHelper(t, ctx, sys)
	t.Logf("  DisputeGameFactory: %s", gameFactory.FactoryAddr.Hex())

	// Start TON Staking system (Anvil-based for TON contracts)
	// Note: In this setup, we use Optimism's L1 for dispute games
	// and a separate Anvil instance for TON staking contracts.
	ratSys := rat.StartTONStakingSystem(t)
	t.Log("  TON Staking system started")

	// Connect to slashing contracts
	slashingContracts := connectSlashingContracts(t, ratSys)
	t.Log("  Slashing contracts connected")

	env := &RealGameTestEnv{
		T:                 t,
		Ctx:               ctx,
		System:            sys,
		L1Client:          l1Client,
		GameFactory:       gameFactory,
		RATSystem:         ratSys,
		SlashingContracts: slashingContracts,
	}

	t.Log("=== Real Game Test Environment Ready ===")
	return env
}

// CreateAlphabetGame creates a real FaultDisputeGame using Alphabet trace.
// This is faster than Cannon-based games (~15s vs ~90s) and suitable for most slashing tests.
func (env *RealGameTestEnv) CreateAlphabetGame(
	l2BlockNumber uint64,
	rootClaim common.Hash,
) *disputegame.OutputAlphabetGameHelper {
	env.T.Logf("Creating Alphabet game at L2 block %d with root claim %s", l2BlockNumber, rootClaim.Hex())

	game := env.GameFactory.StartOutputAlphabetGame(env.Ctx, "sequencer", l2BlockNumber, rootClaim)
	env.T.Logf("  Game created at: %s", game.Addr.Hex())

	return game
}

// CreateAlphabetGameWithCorrectRoot creates a game with the correct output root.
func (env *RealGameTestEnv) CreateAlphabetGameWithCorrectRoot(
	l2BlockNumber uint64,
) *disputegame.OutputAlphabetGameHelper {
	env.T.Logf("Creating Alphabet game at L2 block %d with correct root", l2BlockNumber)

	game := env.GameFactory.StartOutputAlphabetGameWithCorrectRoot(env.Ctx, "sequencer", l2BlockNumber)
	env.T.Logf("  Game created at: %s", game.Addr.Hex())

	return game
}

// StartChallenger starts an op-challenger service for a game.
// The challenger will automatically participate in the game.
func (env *RealGameTestEnv) StartChallenger(
	game *disputegame.OutputAlphabetGameHelper,
	name string,
	privKey *ecdsa.PrivateKey,
) *challenger.Helper {
	env.T.Logf("Starting challenger '%s' for game %s", name, game.Addr.Hex())

	chl := game.StartChallenger(env.Ctx, "sequencer", name,
		challenger.WithPrivKey(privKey),
	)

	env.T.Logf("  Challenger '%s' started", name)
	return chl
}

// WaitForGameStatus waits for a game to reach the specified status.
func (env *RealGameTestEnv) WaitForGameStatus(
	game *disputegame.OutputAlphabetGameHelper,
	expectedStatus types.GameStatus,
) {
	env.T.Logf("Waiting for game %s to reach status %d", game.Addr.Hex(), expectedStatus)
	game.WaitForGameStatus(env.Ctx, expectedStatus)
	env.T.Logf("  Game reached status %d", expectedStatus)
}

// AdvanceTimeAndResolve advances time past the game duration and resolves the game.
func (env *RealGameTestEnv) AdvanceTimeAndResolve(
	game *disputegame.OutputAlphabetGameHelper,
	expectedStatus types.GameStatus,
) {
	env.T.Log("Advancing time past game duration...")

	// Advance time past the max clock duration
	env.System.TimeTravelClock.AdvanceTime(game.MaxClockDuration(env.Ctx))
	require.NoError(env.T, wait.ForNextBlock(env.Ctx, env.L1Client))

	// Wait for game to reach expected status
	env.WaitForGameStatus(game, expectedStatus)
}

// RegisterOperatorForSlashing registers an operator with CandidateAddOn for slashing tests.
// Returns: candidateAddOn address, operatorManager address, rollupConfig address
func (env *RealGameTestEnv) RegisterOperatorForSlashing(
	operatorAuth *bind.TransactOpts,
	stakeAmount *big.Int,
) (common.Address, common.Address, common.Address) {
	return registerOperatorWithCandidateAddOn(
		env.T,
		env.RATSystem,
		env.SlashingContracts,
		operatorAuth,
		stakeAmount,
	)
}

// ExecuteTONSlashing executes TON slashing for a resolved dispute game.
// This should be called after the game is resolved with CHALLENGER_WINS status.
func (env *RealGameTestEnv) ExecuteTONSlashing(
	challengerAuth *bind.TransactOpts,
	operatorManager common.Address,
	gameAddress common.Address,
	rootClaim [32]byte,
	extraData []byte,
) error {
	env.T.Logf("Executing TON slashing for operator %s", operatorManager.Hex())

	receipt := executeSlashing(
		env.T,
		env.RATSystem,
		env.SlashingContracts,
		challengerAuth,
		operatorManager,
		gameAddress,
		rootClaim,
		extraData,
	)

	if receipt.Status != 1 {
		return &slashingError{msg: "slashing transaction failed"}
	}

	env.T.Logf("  TON slashing executed successfully")
	return nil
}

// GetSystemSecrets returns the secrets from the Optimism system config.
// Use these for creating transaction opts for challengers.
func (env *RealGameTestEnv) GetSystemSecrets() *secrets.Secrets {
	return env.System.Cfg.Secrets
}

// GetTestAccount returns a test account for the specified role.
// Available roles: "alice", "bob", "mallory", "deployer", "proposer", "challenger"
func (env *RealGameTestEnv) GetTestAccount(role string) (*ecdsa.PrivateKey, *bind.TransactOpts, error) {
	secrets := env.System.Cfg.Secrets
	var key *ecdsa.PrivateKey

	switch role {
	case "alice":
		key = secrets.Alice
	case "bob":
		key = secrets.Bob
	case "mallory":
		key = secrets.Mallory
	default:
		// For other roles, use the RAT system's test accounts
		return env.getAnvilTestAccount(role)
	}

	chainID := env.System.Cfg.L1ChainIDBig()
	auth, err := bind.NewKeyedTransactorWithChainID(key, chainID)
	if err != nil {
		return nil, nil, err
	}
	auth.GasLimit = 5000000

	return key, auth, nil
}

// getAnvilTestAccount returns a test account from the Anvil mnemonic.
func (env *RealGameTestEnv) getAnvilTestAccount(role string) (*ecdsa.PrivateKey, *bind.TransactOpts, error) {
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
	default:
		return nil, nil, &unknownRoleError{role: role}
	}

	key, err := crypto.HexToECDSA(hexKey)
	if err != nil {
		return nil, nil, err
	}

	chainID, err := env.RATSystem.L1Client.ChainID(env.Ctx)
	if err != nil {
		return nil, nil, err
	}

	auth, err := bind.NewKeyedTransactorWithChainID(key, chainID)
	if err != nil {
		return nil, nil, err
	}
	auth.GasLimit = 5000000

	return key, auth, nil
}

// GetStakeBalance returns the stake balance for an account in a candidateAddOn.
func (env *RealGameTestEnv) GetStakeBalance(
	candidateAddOn common.Address,
	account common.Address,
) *big.Int {
	return getStakeBalance(env.T, env.RATSystem, env.SlashingContracts, candidateAddOn, account)
}

// GetWTONBalance returns the WTON balance for an account.
func (env *RealGameTestEnv) GetWTONBalance(account common.Address) *big.Int {
	return getWTONBalance(env.T, env.RATSystem, account)
}

// GetSlashingRewardRate returns the current slashing reward rate.
func (env *RealGameTestEnv) GetSlashingRewardRate() *big.Int {
	return getSlashingRewardRate(env.T, env.RATSystem, env.SlashingContracts)
}

// SetSlashingRewardRate sets the slashing reward rate (only deployer can call).
func (env *RealGameTestEnv) SetSlashingRewardRate(
	deployerAuth *bind.TransactOpts,
	rate *big.Int,
) {
	setSlashingRewardRate(env.T, env.RATSystem, env.SlashingContracts, deployerAuth, rate)
}

// DelegatorDeposit deposits WTON for a delegator to a candidate.
func (env *RealGameTestEnv) DelegatorDeposit(
	delegatorAuth *bind.TransactOpts,
	candidateAddOn common.Address,
	amount *big.Int,
) {
	delegatorDeposit(env.T, env.RATSystem, env.SlashingContracts, delegatorAuth, candidateAddOn, amount)
}

// MintWTON mints WTON to an account.
func (env *RealGameTestEnv) MintWTON(
	auth *bind.TransactOpts,
	recipient common.Address,
	amount *big.Int,
) {
	wton, err := bindings.NewWTON(env.RATSystem.Addresses.WTON, env.RATSystem.L1Client)
	require.NoError(env.T, err, "Failed to connect to WTON")

	tx, err := wton.Mint(auth, recipient, amount)
	require.NoError(env.T, err, "Failed to mint WTON")

	_, err = bind.WaitMined(env.Ctx, env.RATSystem.L1Client, tx)
	require.NoError(env.T, err, "Failed to wait for WTON mint")

	env.T.Logf("  Minted %s WTON to %s", amount.String(), recipient.Hex())
}

// MultiChallengerEnv provides helpers for multi-challenger tests.
type MultiChallengerEnv struct {
	*RealGameTestEnv
	Challengers []*challenger.Helper
}

// NewMultiChallengerEnv creates a new multi-challenger test environment.
func NewMultiChallengerEnv(env *RealGameTestEnv) *MultiChallengerEnv {
	return &MultiChallengerEnv{
		RealGameTestEnv: env,
		Challengers:     make([]*challenger.Helper, 0),
	}
}

// AddChallenger adds a challenger to the game.
func (m *MultiChallengerEnv) AddChallenger(
	game *disputegame.OutputAlphabetGameHelper,
	name string,
	privKey *ecdsa.PrivateKey,
) *challenger.Helper {
	chl := m.StartChallenger(game, name, privKey)
	m.Challengers = append(m.Challengers, chl)
	return chl
}

// WaitForAllChallengersToAct waits for all challengers to process the current L1 head.
func (m *MultiChallengerEnv) WaitForAllChallengersToAct() {
	m.T.Log("Waiting for all challengers to act on L1 head...")
	for _, chl := range m.Challengers {
		chl.WaitL1HeadActedOn(m.Ctx, m.L1Client)
	}
	m.T.Log("  All challengers have acted")
}

// slashingError represents a slashing-related error.
type slashingError struct {
	msg string
}

func (e *slashingError) Error() string {
	return e.msg
}

// unknownRoleError represents an unknown role error.
type unknownRoleError struct {
	role string
}

func (e *unknownRoleError) Error() string {
	return "unknown role: " + e.role
}

// GameStatusChallengerWon is the game status constant for challenger victory.
const GameStatusChallengerWon = types.GameStatusChallengerWon

// GameStatusDefenderWon is the game status constant for defender victory.
const GameStatusDefenderWon = types.GameStatusDefenderWon

// DefaultGameClockDuration is a helper to wait for game clock expiry.
func DefaultGameClockDuration() time.Duration {
	return 5 * time.Minute
}
