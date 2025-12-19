package rat

import (
	"context"
	"crypto/ecdsa"
	"math/big"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/stretchr/testify/require"

	"github.com/tokamak-network/ton-staking-v2/op-e2e/bindings"
)

// RATSystemConfig holds configuration for RAT E2E tests
type RATSystemConfig struct {
	RATAddress            common.Address
	WTONAddress           common.Address
	TONAddress            common.Address
	SeigManagerAddress    common.Address
	DepositManagerAddress common.Address
	SystemConfigAddress   common.Address

	SlashingPenalty          *big.Int // C_off
	ValidatorBuffer          *big.Int // Δ_validator
	MinimumThreshold         *big.Int // D_min
	EvidenceSubmissionPeriod uint64   // in seconds
	RatTriggerProbability    *big.Int // π_a (RAY format)
}

// DefaultRATConfig returns default RAT configuration for testing
func DefaultRATConfig() *RATSystemConfig {
	return &RATSystemConfig{
		SlashingPenalty:          MulRAY(100),                             // 100 WTON
		ValidatorBuffer:          MulRAY(100),                             // 100 WTON
		MinimumThreshold:         MulRAY(200),                             // 200 WTON (C_off + Δ)
		EvidenceSubmissionPeriod: 3600,                                    // 1 hour
		RatTriggerProbability:    new(big.Int).Div(RAY(), big.NewInt(100)), // 1% (0.01 RAY)
	}
}

// RATGameHelper helps manage RAT games in E2E tests
type RATGameHelper struct {
	T            *testing.T
	Ctx          context.Context
	Client       *ethclient.Client
	RATHelper    *RATHelper
	RATContract  *bindings.RAT
	GameAddress  common.Address
	SystemConfig common.Address
	ChainID      *big.Int
}

// NewRATGameHelper creates a new RAT game helper
func NewRATGameHelper(
	t *testing.T,
	ctx context.Context,
	client *ethclient.Client,
	ratAddress common.Address,
	gameAddress common.Address,
	systemConfig common.Address,
) *RATGameHelper {
	chainID, err := client.ChainID(ctx)
	require.NoError(t, err, "Failed to get chain ID")

	helper := NewRATHelper(t, client, ratAddress)

	return &RATGameHelper{
		T:            t,
		Ctx:          ctx,
		Client:       client,
		RATHelper:    helper,
		RATContract:  helper.Contract(),
		GameAddress:  gameAddress,
		SystemConfig: systemConfig,
		ChainID:      chainID,
	}
}

// GetTestId returns the attention test ID for this game
func (g *RATGameHelper) GetTestId() [32]byte {
	return g.RATHelper.GetTestIdByGame(g.Ctx, g.GameAddress)
}

// GetAttentionTest returns the attention test for this game
func (g *RATGameHelper) GetAttentionTest() *AttentionTest {
	testId := g.GetTestId()
	return g.RATHelper.GetAttentionTest(g.Ctx, testId)
}

// RegisterValidator registers a validator with the given deposit
func (g *RATGameHelper) RegisterValidator(privateKey *ecdsa.PrivateKey, depositAmount *big.Int) error {
	opts, err := bind.NewKeyedTransactorWithChainID(privateKey, g.ChainID)
	if err != nil {
		return err
	}
	opts.Context = g.Ctx

	tx, err := g.RATContract.RegisterValidator(opts, g.SystemConfig, depositAmount)
	if err != nil {
		return err
	}

	receipt := g.RATHelper.WaitForReceipt(g.Ctx, tx, DefaultTimeout)
	if receipt.Status != 1 {
		g.T.Fatalf("RegisterValidator transaction failed")
	}
	return nil
}

// SubmitEvidence submits evidence for an attention test
func (g *RATGameHelper) SubmitEvidence(privateKey *ecdsa.PrivateKey, batchIndex uint32, evidence []byte) error {
	opts, err := bind.NewKeyedTransactorWithChainID(privateKey, g.ChainID)
	if err != nil {
		return err
	}
	opts.Context = g.Ctx

	tx, err := g.RATContract.SubmitEvidence(opts, g.SystemConfig, batchIndex, evidence)
	if err != nil {
		return err
	}

	receipt := g.RATHelper.WaitForReceipt(g.Ctx, tx, DefaultTimeout)
	if receipt.Status != 1 {
		g.T.Fatalf("SubmitEvidence transaction failed")
	}
	return nil
}

// DeactivateValidator deactivates a validator
func (g *RATGameHelper) DeactivateValidator(privateKey *ecdsa.PrivateKey) error {
	opts, err := bind.NewKeyedTransactorWithChainID(privateKey, g.ChainID)
	if err != nil {
		return err
	}
	opts.Context = g.Ctx

	tx, err := g.RATContract.DeactivateValidator(opts, g.SystemConfig)
	if err != nil {
		return err
	}

	receipt := g.RATHelper.WaitForReceipt(g.Ctx, tx, DefaultTimeout)
	if receipt.Status != 1 {
		g.T.Fatalf("DeactivateValidator transaction failed")
	}
	return nil
}

// AddDeposit adds additional deposit to a validator
func (g *RATGameHelper) AddDeposit(privateKey *ecdsa.PrivateKey, amount *big.Int) error {
	opts, err := bind.NewKeyedTransactorWithChainID(privateKey, g.ChainID)
	if err != nil {
		return err
	}
	opts.Context = g.Ctx

	tx, err := g.RATContract.AddDeposit(opts, g.SystemConfig, amount)
	if err != nil {
		return err
	}

	receipt := g.RATHelper.WaitForReceipt(g.Ctx, tx, DefaultTimeout)
	if receipt.Status != 1 {
		g.T.Fatalf("AddDeposit transaction failed")
	}
	return nil
}

// GetValidatorRegistration returns the validator registration for the given address
func (g *RATGameHelper) GetValidatorRegistration(validator common.Address) *ValidatorRegistration {
	return g.RATHelper.GetValidatorRegistration(g.Ctx, g.SystemConfig, validator)
}

// LogGameData logs the current state of the RAT game
func (g *RATGameHelper) LogGameData() {
	g.T.Logf("=== RAT Game State ===")
	g.T.Logf("Game Address: %s", g.GameAddress.Hex())
	g.T.Logf("RAT Contract: %s", g.RATHelper.Address().Hex())
	g.T.Logf("System Config: %s", g.SystemConfig.Hex())

	testId := g.GetTestId()
	if testId != [32]byte{} {
		test := g.GetAttentionTest()
		g.T.Logf("Test ID: %x", testId)
		g.T.Logf("Validator: %s", test.ValidatorAddress.Hex())
		g.T.Logf("Bond Amount: %s", test.BondAmount.String())
		g.T.Logf("Status: %d", test.Status)
		g.T.Logf("Deadline: %s", test.Deadline.String())
	} else {
		g.T.Log("No attention test found for this game")
	}
	g.T.Log("======================")
}

// RequireAttentionTestTriggered verifies that an attention test was triggered
func (g *RATGameHelper) RequireAttentionTestTriggered() {
	testId := g.GetTestId()
	require.NotEqual(g.T, [32]byte{}, testId, "Expected attention test to be triggered")
}

// RequireValidatorBondLocked verifies that validator bond was locked
func (g *RATGameHelper) RequireValidatorBondLocked(validator common.Address, expectedBond *big.Int) {
	reg := g.GetValidatorRegistration(validator)
	require.True(g.T, reg.TotalBondForRAT.Cmp(expectedBond) >= 0,
		"Expected bond to be at least %s, got %s", expectedBond.String(), reg.TotalBondForRAT.String())
}

// RequireValidatorActive verifies that a validator is active
func (g *RATGameHelper) RequireValidatorActive(validator common.Address) {
	active := g.RATHelper.IsValidatorActive(g.Ctx, validator, g.SystemConfig)
	require.True(g.T, active, "Expected validator %s to be active", validator.Hex())
}

// RequireValidatorNotActive verifies that a validator is not active
func (g *RATGameHelper) RequireValidatorNotActive(validator common.Address) {
	active := g.RATHelper.IsValidatorActive(g.Ctx, validator, g.SystemConfig)
	require.False(g.T, active, "Expected validator %s to not be active", validator.Hex())
}

// WaitForGameCompletion waits for the game to complete
func (g *RATGameHelper) WaitForGameCompletion(timeout time.Duration) {
	// In real implementation, this would wait for the game status to change
	// For now, just wait a bit
	time.Sleep(100 * time.Millisecond)
}

// WaitForAttentionTest waits for an attention test to be created
func (g *RATGameHelper) WaitForAttentionTest(timeout time.Duration) *AttentionTest {
	return g.RATHelper.WaitForAttentionTest(g.Ctx, g.GameAddress, timeout)
}

// GetMinimumCollateral returns the minimum collateral required
func (g *RATGameHelper) GetMinimumCollateral() *big.Int {
	return g.RATHelper.GetMinimumCollateral(g.Ctx)
}

// GetSlashingPenalty returns the slashing penalty amount
func (g *RATGameHelper) GetSlashingPenalty() *big.Int {
	return g.RATHelper.GetSlashingPenalty(g.Ctx)
}

// GetValidatorBuffer returns the validator buffer amount
func (g *RATGameHelper) GetValidatorBuffer() *big.Int {
	return g.RATHelper.GetValidatorBuffer(g.Ctx)
}

// GetValidatorCount returns the validator count for this system config
func (g *RATGameHelper) GetValidatorCount() *big.Int {
	return g.RATHelper.GetValidatorCount(g.Ctx, g.SystemConfig)
}

// GetActiveValidatorCount returns the active validator count for this system config
func (g *RATGameHelper) GetActiveValidatorCount() *big.Int {
	return g.RATHelper.GetActiveValidatorCount(g.Ctx, g.SystemConfig)
}

// GetL2Validators returns the list of validators for this system config
func (g *RATGameHelper) GetL2Validators() []common.Address {
	return g.RATHelper.GetL2Validators(g.Ctx, g.SystemConfig)
}
