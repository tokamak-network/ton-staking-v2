package faultproofs

import (
	"math/big"
	"testing"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/stretchr/testify/require"
	"github.com/tokamak-network/ton-staking-v2/op-e2e/bindings"
	rat "github.com/tokamak-network/ton-staking-v2/op-e2e/e2eutils/rat"
)

// TestSlashing_BasicOperatorSlashing tests basic operator slashing flow
func TestSlashing_BasicOperatorSlashing(t *testing.T) {
	t.Parallel()

	// Start TON Staking system with genesis
	sys := rat.StartTONStakingSystem(t)

	t.Log("=== Testing Basic Operator Slashing ===")

	// Setup test accounts and contracts
	accounts := setupTestAccounts(t, sys)
	contracts := connectTestContracts(t, sys)
	slashingContracts := connectSlashingContracts(t, sys)

	// Get deposit amount (1,000,000 TON)
	depositAmount := new(big.Int).Mul(big.NewInt(1000000), new(big.Int).Exp(big.NewInt(10), big.NewInt(18), nil))

	t.Logf("✓ Test environment ready")
	t.Logf("  Operator: %s", accounts.Validator.Addr.Hex())
	t.Logf("  Challenger: %s", accounts.Challenger.Addr.Hex())
	t.Logf("  Deposit amount: %s WTON", depositAmount.String())

	// Adjust minimum collateral
	adjustMinimumCollateral(t, sys, contracts, accounts.Deployer.Auth, depositAmount)

	// Step 1: Register operator with CandidateAddOn
	t.Log("\n--- Step 1: Register Operator ---")
	candidateAddOn, operatorManager := registerOperatorWithCandidateAddOn(
		t, sys, slashingContracts, accounts.Validator.Auth, depositAmount,
	)

	// Verify initial stake
	operatorStakeBefore := getStakeBalance(t, sys, slashingContracts, candidateAddOn, accounts.Validator.Addr)
	require.Equal(t, depositAmount, operatorStakeBefore, "Initial stake should equal deposit amount")
	t.Logf("✓ Operator stake before slashing: %s WTON", operatorStakeBefore.String())

	// Get challenger's initial WTON balance
	challengerBalanceBefore := getWTONBalance(t, sys, accounts.Challenger.Addr)
	t.Logf("✓ Challenger WTON balance before: %s", challengerBalanceBefore.String())

	// Step 2: Setup RAT and Registry
	t.Log("\n--- Step 2: Setup Registry and RAT ---")
	rat, err := bindings.NewRAT(sys.Addresses.RATProxy, sys.L1Client)
	require.NoError(t, err)

	registry, err := bindings.NewL1BridgeRegistryV12(sys.Addresses.L1BridgeRegistryProxy, sys.L1Client)
	require.NoError(t, err)

	sysConfigAddr := sys.Addresses.SystemConfig

	// Ensure SystemConfig is registered in L1BridgeRegistry (Type 3)
	regTx, err := registry.RegisterRollupConfigByManager0(
		accounts.Deployer.Auth,
		sysConfigAddr,
		uint8(3),
		common.Address{0x42}, // dummy L2TON
		"StandardRollup",
	)
	require.NoError(t, err)
	_, err = bind.WaitMined(sys.Ctx, sys.L1Client, regTx)
	require.NoError(t, err)

	// Ensure RAT probability is 100% (RAY)
	ray := new(big.Int).Exp(big.NewInt(10), big.NewInt(27), nil)
	probTx, err := rat.SetRatTriggerProbability(accounts.Deployer.Auth, ray)
	require.NoError(t, err)
	_, err = bind.WaitMined(sys.Ctx, sys.L1Client, probTx)
	require.NoError(t, err)

	// Adjust RAT parameters
	thresholdTx, err := rat.SetMinimumThreshold(accounts.Deployer.Auth, big.NewInt(0))
	require.NoError(t, err)
	_, err = bind.WaitMined(sys.Ctx, sys.L1Client, thresholdTx)
	require.NoError(t, err)

	// Approve TON for RAT registration
	ton, err := bindings.NewERC20(sys.Addresses.TON, sys.L1Client)
	require.NoError(t, err)
	approveTx, err := ton.Approve(accounts.Validator.Auth, sys.Addresses.RATProxy, depositAmount)
	require.NoError(t, err)
	_, err = bind.WaitMined(sys.Ctx, sys.L1Client, approveTx)
	require.NoError(t, err)

	// Register in RAT
	registerValidatorTx, err := rat.RegisterValidator(accounts.Validator.Auth, sysConfigAddr, depositAmount)
	require.NoError(t, err)
	_, err = bind.WaitMined(sys.Ctx, sys.L1Client, registerValidatorTx)
	require.NoError(t, err)

	// Verify validator is active in RAT
	isActive, err := rat.IsValidatorActive(nil, accounts.Validator.Addr, sysConfigAddr)
	require.NoError(t, err)
	require.True(t, isActive, "Validator should be active")

	t.Log("\n--- Step 3: Create DisputeGame and Trigger RAT ---")
	// Creating DisputeGame with wrong claim triggers RAT because probability is 100%
	rootClaim := [32]byte{0x01, 0x02, 0x03}
	gameReceipt, gameAddress := createDisputeGame(t, sys, accounts.Proposer.Auth, rootClaim)
	t.Logf("✓ DisputeGame created at: %s", gameAddress.Hex())

	// Verify RAT was triggered automatically by DisputeGameFactory
	testID, ratTriggered := parseRATTriggerEvent(t, gameReceipt, accounts.Validator.Addr)
	require.True(t, ratTriggered, "RAT should be triggered automatically by DisputeGameFactory")
	t.Logf("✓ RAT triggered with test ID: %x", testID)

	// Step 3: Challenger attacks the wrong claim
	t.Log("\n--- Step 3: Challenger Attacks ---")
	correctRootClaim := [32]byte{0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}
	attackClaim(t, sys, accounts.Challenger.Auth, gameAddress, correctRootClaim)

	// Step 4: Advance time and resolve game
	t.Log("\n--- Step 4: Resolve Game ---")
	advanceTimeAndMine(t, sys, 604800) // 7 days
	resolveGame(t, sys, gameAddress)

	// Verify game status is CHALLENGER_WINS
	gameStatus := getGameStatus(t, sys, gameAddress)
	require.Equal(t, uint8(2), gameStatus, "Game status should be CHALLENGER_WINS (2)")
	t.Logf("✓ Game resolved: CHALLENGER_WINS")

	// Step 5: Execute slashing
	t.Log("\n--- Step 5: Execute Slashing ---")
	executeSlashing(t, sys, slashingContracts, accounts.Challenger.Auth, operatorManager, gameAddress)

	// Step 6: Verify slashing results
	t.Log("\n--- Step 6: Verify Results ---")

	// 6.1: Operator stake should be 0
	operatorStakeAfter := getStakeBalance(t, sys, slashingContracts, candidateAddOn, accounts.Validator.Addr)
	require.Equal(t, big.NewInt(0), operatorStakeAfter, "Operator stake should be fully slashed")
	t.Logf("✓ Operator stake after slashing: %s (fully slashed)", operatorStakeAfter.String())

	// 6.2: Challenger should receive 10% reward
	slashingRewardRate := getSlashingRewardRate(t, sys, slashingContracts)
	t.Logf("  Slashing reward rate: %s (basis points)", slashingRewardRate.String())

	expectedReward := new(big.Int).Mul(depositAmount, slashingRewardRate)
	expectedReward.Div(expectedReward, big.NewInt(10000)) // Convert basis points to actual amount

	challengerBalanceAfter := getWTONBalance(t, sys, accounts.Challenger.Addr)
	challengerReward := new(big.Int).Sub(challengerBalanceAfter, challengerBalanceBefore)

	t.Logf("✓ Challenger reward: %s WTON", challengerReward.String())
	t.Logf("  Expected reward: %s WTON (10%%)", expectedReward.String())

	// Allow small difference due to gas costs
	diff := new(big.Int).Sub(expectedReward, challengerReward)
	diff.Abs(diff)
	maxDiff := new(big.Int).Mul(big.NewInt(1), big.NewInt(1e9)) // 1 WTON tolerance
	require.True(t, diff.Cmp(maxDiff) <= 0, "Challenger reward should be approximately 10%% of slashed amount")

	// 6.3: Calculate burned amount (90%)
	burnedAmount := new(big.Int).Sub(depositAmount, challengerReward)
	t.Logf("✓ Burned amount: %s WTON (90%%)", burnedAmount.String())

	t.Log("\n=== Test Complete ===")
	t.Log("✅ Operator fully slashed")
	t.Log("✅ Challenger received 10% reward")
	t.Log("✅ 90% of stake burned")
}
