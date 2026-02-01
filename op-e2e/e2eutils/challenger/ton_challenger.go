// Package challenger provides TON Staking V3 challenger helpers for E2E testing.
// This package provides helpers for creating and managing challengers in dispute games.
package challenger

import (
	"context"
	"crypto/ecdsa"
	"fmt"
	"math/big"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/stretchr/testify/require"
	"github.com/tokamak-network/ton-staking-v2/op-e2e/bindings"
	"github.com/tokamak-network/ton-staking-v2/op-e2e/system"
)

// ChallengerHelper provides methods for interacting with dispute games as a challenger.
type ChallengerHelper struct {
	T          *testing.T
	Ctx        context.Context
	System     *system.TONSystem
	Name       string
	PrivateKey *ecdsa.PrivateKey
	Address    common.Address
	Auth       *bind.TransactOpts
}

// ChallengerOption is a function that modifies a ChallengerHelper.
type ChallengerOption func(*ChallengerHelper)

// WithPrivKey sets the challenger's private key.
func WithPrivKey(key *ecdsa.PrivateKey) ChallengerOption {
	return func(h *ChallengerHelper) {
		h.PrivateKey = key
		h.Address = crypto.PubkeyToAddress(key.PublicKey)
	}
}

// WithName sets the challenger's name.
func WithName(name string) ChallengerOption {
	return func(h *ChallengerHelper) {
		h.Name = name
	}
}

// NewTONChallenger creates a new challenger helper for the TON system.
func NewTONChallenger(t *testing.T, ctx context.Context, sys *system.TONSystem, opts ...ChallengerOption) *ChallengerHelper {
	helper := &ChallengerHelper{
		T:      t,
		Ctx:    ctx,
		System: sys,
		Name:   "Challenger",
	}

	for _, opt := range opts {
		opt(helper)
	}

	// If no private key was set, use the default challenger account
	if helper.PrivateKey == nil {
		account := sys.Challenger()
		helper.PrivateKey = account.PrivateKey
		helper.Address = account.Address
		helper.Auth = account.Auth
	} else {
		// Create auth from the provided private key
		chainID, err := sys.L1Client.ChainID(ctx)
		require.NoError(t, err, "Failed to get chain ID")

		auth, err := bind.NewKeyedTransactorWithChainID(helper.PrivateKey, chainID)
		require.NoError(t, err, "Failed to create transactor")
		auth.GasLimit = 3000000
		helper.Auth = auth
	}

	t.Logf("Created challenger %s at %s", helper.Name, helper.Address.Hex())
	return helper
}

// Attack attacks a claim in a dispute game.
func (h *ChallengerHelper) Attack(gameAddr common.Address, challengeIndex *big.Int, claim [32]byte) error {
	game, err := bindings.NewMockFaultDisputeGame3(gameAddr, h.System.L1Client)
	if err != nil {
		return fmt.Errorf("failed to get game: %w", err)
	}

	tx, err := game.Move(h.Auth, challengeIndex, claim, true) // isAttack = true
	if err != nil {
		return fmt.Errorf("failed to attack: %w", err)
	}

	receipt, err := bind.WaitMined(h.Ctx, h.System.L1Client, tx)
	if err != nil {
		return fmt.Errorf("failed to wait for tx: %w", err)
	}

	if receipt.Status == 0 {
		return fmt.Errorf("attack transaction failed")
	}

	h.T.Logf("%s attacked claim %d in game %s", h.Name, challengeIndex, gameAddr.Hex())
	return nil
}

// Defend defends a claim in a dispute game.
func (h *ChallengerHelper) Defend(gameAddr common.Address, challengeIndex *big.Int, claim [32]byte) error {
	game, err := bindings.NewMockFaultDisputeGame3(gameAddr, h.System.L1Client)
	if err != nil {
		return fmt.Errorf("failed to get game: %w", err)
	}

	tx, err := game.Move(h.Auth, challengeIndex, claim, false) // isAttack = false
	if err != nil {
		return fmt.Errorf("failed to defend: %w", err)
	}

	receipt, err := bind.WaitMined(h.Ctx, h.System.L1Client, tx)
	if err != nil {
		return fmt.Errorf("failed to wait for tx: %w", err)
	}

	if receipt.Status == 0 {
		return fmt.Errorf("defend transaction failed")
	}

	h.T.Logf("%s defended claim %d in game %s", h.Name, challengeIndex, gameAddr.Hex())
	return nil
}

// Step performs a step against a claim in a dispute game.
func (h *ChallengerHelper) Step(gameAddr common.Address, claimIndex *big.Int) error {
	game, err := bindings.NewMockFaultDisputeGame3(gameAddr, h.System.L1Client)
	if err != nil {
		return fmt.Errorf("failed to get game: %w", err)
	}

	tx, err := game.Step(h.Auth, claimIndex)
	if err != nil {
		return fmt.Errorf("failed to step: %w", err)
	}

	receipt, err := bind.WaitMined(h.Ctx, h.System.L1Client, tx)
	if err != nil {
		return fmt.Errorf("failed to wait for tx: %w", err)
	}

	if receipt.Status == 0 {
		return fmt.Errorf("step transaction failed")
	}

	h.T.Logf("%s stepped against claim %d in game %s", h.Name, claimIndex, gameAddr.Hex())
	return nil
}

// ResolveClaim resolves a claim in a dispute game.
func (h *ChallengerHelper) ResolveClaim(gameAddr common.Address, claimIndex *big.Int) error {
	game, err := bindings.NewMockFaultDisputeGame3(gameAddr, h.System.L1Client)
	if err != nil {
		return fmt.Errorf("failed to get game: %w", err)
	}

	tx, err := game.ResolveClaim(h.Auth, claimIndex)
	if err != nil {
		return fmt.Errorf("failed to resolve claim: %w", err)
	}

	receipt, err := bind.WaitMined(h.Ctx, h.System.L1Client, tx)
	if err != nil {
		return fmt.Errorf("failed to wait for tx: %w", err)
	}

	if receipt.Status == 0 {
		return fmt.Errorf("resolve claim transaction failed")
	}

	h.T.Logf("%s resolved claim %d in game %s", h.Name, claimIndex, gameAddr.Hex())
	return nil
}

// Resolve resolves the entire dispute game.
func (h *ChallengerHelper) Resolve(gameAddr common.Address) (uint8, error) {
	game, err := bindings.NewMockFaultDisputeGame3(gameAddr, h.System.L1Client)
	if err != nil {
		return 0, fmt.Errorf("failed to get game: %w", err)
	}

	tx, err := game.Resolve(h.Auth)
	if err != nil {
		return 0, fmt.Errorf("failed to resolve: %w", err)
	}

	receipt, err := bind.WaitMined(h.Ctx, h.System.L1Client, tx)
	if err != nil {
		return 0, fmt.Errorf("failed to wait for tx: %w", err)
	}

	if receipt.Status == 0 {
		return 0, fmt.Errorf("resolve transaction failed")
	}

	// Get the final status
	status, err := game.Status(&bind.CallOpts{Context: h.Ctx})
	if err != nil {
		return 0, fmt.Errorf("failed to get status: %w", err)
	}

	h.T.Logf("%s resolved game %s with status %d", h.Name, gameAddr.Hex(), status)
	return status, nil
}

// WaitForGameStatus waits for the game to reach the specified status.
func (h *ChallengerHelper) WaitForGameStatus(gameAddr common.Address, expectedStatus uint8, timeout time.Duration) error {
	game, err := bindings.NewMockFaultDisputeGame3(gameAddr, h.System.L1Client)
	if err != nil {
		return fmt.Errorf("failed to get game: %w", err)
	}

	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		status, err := game.Status(&bind.CallOpts{Context: h.Ctx})
		if err != nil {
			return fmt.Errorf("failed to get status: %w", err)
		}

		if status == expectedStatus {
			h.T.Logf("Game %s reached status %d", gameAddr.Hex(), status)
			return nil
		}

		time.Sleep(1 * time.Second)
	}

	return fmt.Errorf("timeout waiting for game status %d", expectedStatus)
}

// IsWinningChallenger checks if this challenger is a winning challenger.
func (h *ChallengerHelper) IsWinningChallenger(gameAddr common.Address) (bool, error) {
	return h.System.IsWinningChallenger(gameAddr, h.Address)
}

// MultiChallengerHelper manages multiple challengers for testing.
type MultiChallengerHelper struct {
	T           *testing.T
	Ctx         context.Context
	System      *system.TONSystem
	Challengers []*ChallengerHelper
}

// NewMultiChallengerHelper creates a helper for managing multiple challengers.
func NewMultiChallengerHelper(t *testing.T, ctx context.Context, sys *system.TONSystem) *MultiChallengerHelper {
	return &MultiChallengerHelper{
		T:           t,
		Ctx:         ctx,
		System:      sys,
		Challengers: make([]*ChallengerHelper, 0),
	}
}

// AddChallenger adds a new challenger with a generated private key.
func (m *MultiChallengerHelper) AddChallenger(name string) *ChallengerHelper {
	// Generate a deterministic private key based on name
	key := generateDeterministicKey(name)
	
	challenger := NewTONChallenger(m.T, m.Ctx, m.System,
		WithName(name),
		WithPrivKey(key),
	)
	
	m.Challengers = append(m.Challengers, challenger)
	return challenger
}

// AddChallengerWithKey adds a new challenger with a specific private key.
func (m *MultiChallengerHelper) AddChallengerWithKey(name string, key *ecdsa.PrivateKey) *ChallengerHelper {
	challenger := NewTONChallenger(m.T, m.Ctx, m.System,
		WithName(name),
		WithPrivKey(key),
	)
	
	m.Challengers = append(m.Challengers, challenger)
	return challenger
}

// StartMultipleChallengers creates multiple challengers with generated keys.
func StartMultipleChallengers(t *testing.T, ctx context.Context, sys *system.TONSystem, count int) []*ChallengerHelper {
	helper := NewMultiChallengerHelper(t, ctx, sys)
	
	for i := 0; i < count; i++ {
		name := fmt.Sprintf("Challenger%d", i+1)
		helper.AddChallenger(name)
	}
	
	return helper.Challengers
}

// GetAllChallengers returns all challengers.
func (m *MultiChallengerHelper) GetAllChallengers() []*ChallengerHelper {
	return m.Challengers
}

// GetChallengerAddresses returns all challenger addresses.
func (m *MultiChallengerHelper) GetChallengerAddresses() []common.Address {
	addresses := make([]common.Address, len(m.Challengers))
	for i, c := range m.Challengers {
		addresses[i] = c.Address
	}
	return addresses
}

// AllAttack has all challengers attack the same claim.
func (m *MultiChallengerHelper) AllAttack(gameAddr common.Address, challengeIndex *big.Int, claim [32]byte) error {
	for _, challenger := range m.Challengers {
		if err := challenger.Attack(gameAddr, challengeIndex, claim); err != nil {
			return fmt.Errorf("%s failed to attack: %w", challenger.Name, err)
		}
	}
	return nil
}

// VerifyWinningChallengers verifies that all challengers are winning challengers.
func (m *MultiChallengerHelper) VerifyWinningChallengers(gameAddr common.Address) error {
	for _, challenger := range m.Challengers {
		isWinner, err := challenger.IsWinningChallenger(gameAddr)
		if err != nil {
			return fmt.Errorf("failed to check %s: %w", challenger.Name, err)
		}
		if !isWinner {
			return fmt.Errorf("%s is not a winning challenger", challenger.Name)
		}
		m.T.Logf("%s is a winning challenger", challenger.Name)
	}
	return nil
}

// generateDeterministicKey generates a deterministic private key from a name.
// This is for testing purposes only.
func generateDeterministicKey(name string) *ecdsa.PrivateKey {
	// Create a deterministic seed from the name
	hash := crypto.Keccak256([]byte(name + "_challenger_seed"))
	key, err := crypto.ToECDSA(hash)
	if err != nil {
		panic(fmt.Sprintf("failed to generate key for %s: %v", name, err))
	}
	return key
}

// GetTestPrivateKeys returns a map of predefined private keys for testing.
// These correspond to Anvil's default accounts.
func GetTestPrivateKeys() map[int]*ecdsa.PrivateKey {
	hexKeys := []string{
		"ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80", // #0
		"59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d", // #1
		"5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a", // #2
		"7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6", // #3
		"47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a", // #4
		"8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba", // #5
		"92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e", // #6
		"4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356", // #7
		"dbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97", // #8
		"2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6", // #9
	}

	keys := make(map[int]*ecdsa.PrivateKey)
	for i, hexKey := range hexKeys {
		key, err := crypto.HexToECDSA(hexKey)
		if err != nil {
			panic(fmt.Sprintf("failed to parse key %d: %v", i, err))
		}
		keys[i] = key
	}

	return keys
}
