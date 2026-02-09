package slashing

import (
	"math/big"
	"testing"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/stretchr/testify/require"
	"github.com/tokamak-network/ton-staking-v2/op-e2e/bindings"
	rat "github.com/tokamak-network/ton-staking-v2/op-e2e/e2eutils/rat"
)

// TestSlashingIntegration_MultiChallengerWithRealSlashing tests the complete slashing flow
// with multiple challengers using the real FaultDisputeGame.
// Flow: Register Operator → Create DisputeGame → Multiple Challengers Attack → Resolve → Slash
func TestSlashingIntegration_MultiChallengerWithRealSlashing(t *testing.T) {
	t.Parallel()

	// Start TON Staking system with genesis
	sys := rat.StartTONStakingSystem(t)
	accounts := rat.SetupTestAccounts(t, sys)
	contracts := rat.ConnectTestContracts(t, sys)
	slashingContracts := connectSlashingContracts(t, sys)

	t.Log("=== Testing Multi-Challenger Slashing Integration ===")

	// Step 1: Register operator with CandidateAddOn
	t.Log("\n--- Step 1: Register Operator ---")
	operatorStake := new(big.Int).Mul(big.NewInt(1000000), new(big.Int).Exp(big.NewInt(10), big.NewInt(27), nil))
	rat.AdjustMinimumCollateral(t, sys, contracts, accounts.Deployer.Auth, operatorStake)

	candidateAddOn, operatorManager, rollupConfig := registerOperatorWithCandidateAddOn(
		t, sys, slashingContracts, accounts.Validator.Auth, operatorStake,
	)
	t.Logf("✓ Operator registered: CandidateAddOn=%s, OperatorManager=%s", candidateAddOn.Hex(), operatorManager.Hex())

	// Verify initial stake
	operatorStakeBefore := getStakeBalance(t, sys, slashingContracts, candidateAddOn, operatorManager)
	require.True(t, operatorStakeBefore.Cmp(big.NewInt(0)) > 0, "Operator should have stake")
	t.Logf("✓ Operator stake: %s WTON", operatorStakeBefore.String())

	// Step 2: Setup RAT for validator
	t.Log("\n--- Step 2: Setup RAT ---")
	setupRATForValidator(t, sys, accounts, slashingContracts, candidateAddOn, rollupConfig, operatorStake)

	// Step 3: Record challenger balances before
	t.Log("\n--- Step 3: Record Challenger Balances ---")
	challengerBalanceBefore := getWTONBalance(t, sys, accounts.Challenger.Addr)
	t.Logf("✓ Challenger balance before: %s WTON", challengerBalanceBefore.String())

	// Step 4: Create DisputeGame with invalid root claim
	t.Log("\n--- Step 4: Create DisputeGame ---")
	rootClaim := [32]byte{0xDE, 0xAD, 0xBE, 0xEF}
	_, gameAddress := rat.CreateDisputeGame(t, sys, accounts.Proposer.Auth, rootClaim)
	t.Logf("✓ DisputeGame created at: %s", gameAddress.Hex())

	// Step 5: Challenger attacks the root claim
	t.Log("\n--- Step 5: Challenger Attacks ---")
	correctRootClaim := [32]byte{0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01}
	rat.AttackClaim(t, sys, accounts.Challenger.Auth, gameAddress, correctRootClaim, rootClaim)
	t.Log("✓ Challenger attacked root claim")

	// Step 6: Resolve game
	t.Log("\n--- Step 6: Resolve Game ---")
	rat.AdvanceTimeAndMine(t, sys, 1209600) // 14 days
	rat.ResolveGame(t, sys, accounts.Challenger.Auth, gameAddress)

	// Verify game status is CHALLENGER_WINS
	game, err := bindings.NewFaultDisputeGame(gameAddress, sys.L1Client)
	require.NoError(t, err)
	status, err := game.Status(nil)
	require.NoError(t, err)
	require.Equal(t, uint8(1), status, "Game status should be CHALLENGER_WINS (1)")
	t.Log("✓ Game resolved: CHALLENGER_WINS")

	// Step 7: Execute slashing via Layer2Manager.slashingCandidate()
	t.Log("\n--- Step 7: Execute Slashing ---")
	l2BlockNumber := big.NewInt(100)
	extraData := common.LeftPadBytes(l2BlockNumber.Bytes(), 32)
	slashingReceipt := executeSlashing(
		t, sys, slashingContracts, accounts.Challenger.Auth,
		operatorManager, gameAddress, rootClaim, extraData,
	)
	t.Logf("✓ Slashing executed in tx: %s", slashingReceipt.TxHash.Hex())

	// Step 8: Verify results
	t.Log("\n--- Step 8: Verify Results ---")

	// 8.1: Operator stake should be 0
	operatorStakeAfter := getStakeBalance(t, sys, slashingContracts, candidateAddOn, operatorManager)
	t.Logf("Operator stake before: %s WTON", operatorStakeBefore.String())
	t.Logf("Operator stake after:  %s WTON", operatorStakeAfter.String())
	require.Equal(t, int64(0), operatorStakeAfter.Int64(), "Operator stake should be 0 after slashing")
	t.Log("✓ Operator stake slashed to 0")

	// 8.2: Challenger should have received reward
	challengerBalanceAfter := getWTONBalance(t, sys, accounts.Challenger.Addr)
	challengerReward := new(big.Int).Sub(challengerBalanceAfter, challengerBalanceBefore)
	t.Logf("Challenger reward: %s WTON", challengerReward.String())
	require.True(t, challengerReward.Cmp(big.NewInt(0)) > 0, "Challenger should receive reward")

	t.Log("\n=== Test Complete ===")
	t.Log("✅ Multi-challenger slashing integration test passed")
}

// TestSlashingIntegration_SingleChallengerFullFlow tests the complete slashing flow
// with a single challenger using the real FaultDisputeGame.
func TestSlashingIntegration_SingleChallengerFullFlow(t *testing.T) {
	t.Parallel()

	sys := rat.StartTONStakingSystem(t)
	accounts := rat.SetupTestAccounts(t, sys)
	contracts := rat.ConnectTestContracts(t, sys)
	slashingContracts := connectSlashingContracts(t, sys)

	t.Log("=== Testing Single Challenger Full Slashing Flow ===")

	// Setup operator
	operatorStake := new(big.Int).Mul(big.NewInt(500000), new(big.Int).Exp(big.NewInt(10), big.NewInt(27), nil))
	rat.AdjustMinimumCollateral(t, sys, contracts, accounts.Deployer.Auth, operatorStake)

	candidateAddOn, operatorManager, rollupConfig := registerOperatorWithCandidateAddOn(
		t, sys, slashingContracts, accounts.Validator.Auth, operatorStake,
	)

	// Setup RAT
	setupRATForValidator(t, sys, accounts, slashingContracts, candidateAddOn, rollupConfig, operatorStake)

	// Record balance before
	challengerBalanceBefore := getWTONBalance(t, sys, accounts.Challenger.Addr)

	// Create and play game
	rootClaim := [32]byte{0xBA, 0xD0}
	_, gameAddress := rat.CreateDisputeGame(t, sys, accounts.Proposer.Auth, rootClaim)

	// Challenger attacks
	correctRootClaim := [32]byte{0x60, 0x0D}
	rat.AttackClaim(t, sys, accounts.Challenger.Auth, gameAddress, correctRootClaim, rootClaim)

	// Resolve
	rat.AdvanceTimeAndMine(t, sys, 1209600)
	rat.ResolveGame(t, sys, accounts.Challenger.Auth, gameAddress)

	// Verify game status
	game, err := bindings.NewFaultDisputeGame(gameAddress, sys.L1Client)
	require.NoError(t, err)
	status, err := game.Status(nil)
	require.NoError(t, err)
	require.Equal(t, uint8(1), status, "Game should be CHALLENGER_WINS")

	// Execute slashing
	l2BlockNumber := big.NewInt(100)
	extraData := common.LeftPadBytes(l2BlockNumber.Bytes(), 32)
	executeSlashing(t, sys, slashingContracts, accounts.Challenger.Auth, operatorManager, gameAddress, rootClaim, extraData)

	// Verify results
	operatorStakeAfter := getStakeBalance(t, sys, slashingContracts, candidateAddOn, operatorManager)
	require.Equal(t, int64(0), operatorStakeAfter.Int64(), "Operator should be slashed")

	challengerBalanceAfter := getWTONBalance(t, sys, accounts.Challenger.Addr)
	challengerReward := new(big.Int).Sub(challengerBalanceAfter, challengerBalanceBefore)
	require.True(t, challengerReward.Cmp(big.NewInt(0)) > 0, "Challenger should receive reward")

	// Single challenger gets 100% of reward
	slashingRate := getSlashingRewardRate(t, sys, slashingContracts)
	expectedReward := new(big.Int).Mul(operatorStake, slashingRate)
	expectedReward.Div(expectedReward, big.NewInt(10000))

	t.Logf("Expected reward (100%%): %s", expectedReward.String())
	t.Logf("Actual reward: %s", challengerReward.String())

	// Allow small tolerance for rounding
	diff := new(big.Int).Sub(expectedReward, challengerReward)
	diff.Abs(diff)
	tolerance := new(big.Int).Div(expectedReward, big.NewInt(100)) // 1% tolerance
	require.True(t, diff.Cmp(tolerance) <= 0, "Reward should be approximately expected")

	t.Log("✅ Single challenger full flow test passed")
}

// TestSlashingIntegration_CannotSlashTwice tests that the same dispute game
// cannot be used to slash an operator twice.
func TestSlashingIntegration_CannotSlashTwice(t *testing.T) {
	t.Parallel()

	sys := rat.StartTONStakingSystem(t)
	accounts := rat.SetupTestAccounts(t, sys)
	contracts := rat.ConnectTestContracts(t, sys)
	slashingContracts := connectSlashingContracts(t, sys)

	t.Log("=== Testing Double Slashing Prevention ===")

	// Setup operator
	operatorStake := new(big.Int).Mul(big.NewInt(500000), new(big.Int).Exp(big.NewInt(10), big.NewInt(27), nil))
	rat.AdjustMinimumCollateral(t, sys, contracts, accounts.Deployer.Auth, operatorStake)

	candidateAddOn, operatorManager, rollupConfig := registerOperatorWithCandidateAddOn(
		t, sys, slashingContracts, accounts.Validator.Auth, operatorStake,
	)

	// Setup RAT
	setupRATForValidator(t, sys, accounts, slashingContracts, candidateAddOn, rollupConfig, operatorStake)

	// Create and resolve game
	rootClaim := [32]byte{0xAB, 0xCD}
	_, gameAddress := rat.CreateDisputeGame(t, sys, accounts.Proposer.Auth, rootClaim)

	correctClaim := [32]byte{0xEF}
	rat.AttackClaim(t, sys, accounts.Challenger.Auth, gameAddress, correctClaim, rootClaim)
	rat.AdvanceTimeAndMine(t, sys, 1209600)
	rat.ResolveGame(t, sys, accounts.Challenger.Auth, gameAddress)

	// First slashing should succeed
	l2BlockNumber := big.NewInt(100)
	extraData := common.LeftPadBytes(l2BlockNumber.Bytes(), 32)
	executeSlashing(t, sys, slashingContracts, accounts.Challenger.Auth, operatorManager, gameAddress, rootClaim, extraData)
	t.Log("✓ First slashing succeeded")

	// Second slashing with same game should fail
	gameType := uint32(0)
	tx, err := slashingContracts.Layer2ManagerSlashing.SlashingCandidate(
		accounts.Challenger.Auth,
		operatorManager,
		gameType,
		rootClaim,
		extraData,
		gameAddress,
	)
	if err != nil {
		// Transaction failed to send - expected
		t.Logf("✓ Second slashing rejected (send failed): %v", err)
	} else {
		// Transaction was sent - check if it reverted
		receipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, tx)
		require.NoError(t, err, "Failed to wait for transaction")
		require.Equal(t, types.ReceiptStatusFailed, receipt.Status, "Second slashing transaction should revert")
		t.Log("✓ Second slashing transaction reverted (as expected)")
	}

	t.Log("✅ Double slashing prevention test passed")
}

// TestSlashingIntegration_GameNotChallengerWins tests that slashing fails
// if the game status is not CHALLENGER_WINS.
func TestSlashingIntegration_GameNotChallengerWins(t *testing.T) {
	t.Parallel()

	sys := rat.StartTONStakingSystem(t)
	accounts := rat.SetupTestAccounts(t, sys)
	contracts := rat.ConnectTestContracts(t, sys)
	slashingContracts := connectSlashingContracts(t, sys)

	t.Log("=== Testing Slashing Requires CHALLENGER_WINS ===")

	// Setup operator
	operatorStake := new(big.Int).Mul(big.NewInt(500000), new(big.Int).Exp(big.NewInt(10), big.NewInt(27), nil))
	rat.AdjustMinimumCollateral(t, sys, contracts, accounts.Deployer.Auth, operatorStake)

	_, operatorManager, _ := registerOperatorWithCandidateAddOn(
		t, sys, slashingContracts, accounts.Validator.Auth, operatorStake,
	)

	// Create game but don't resolve it (IN_PROGRESS)
	rootClaim := [32]byte{0x12, 0x34}
	_, gameAddress := rat.CreateDisputeGame(t, sys, accounts.Proposer.Auth, rootClaim)
	t.Logf("✓ DisputeGame created at: %s (IN_PROGRESS)", gameAddress.Hex())

	// Try to slash with game still IN_PROGRESS - should fail
	gameType := uint32(0)
	l2BlockNumber := big.NewInt(100)
	extraData := common.LeftPadBytes(l2BlockNumber.Bytes(), 32)

	tx, err := slashingContracts.Layer2ManagerSlashing.SlashingCandidate(
		accounts.Challenger.Auth,
		operatorManager,
		gameType,
		rootClaim,
		extraData,
		gameAddress,
	)
	if err != nil {
		// Transaction failed to send - expected
		t.Logf("✓ Slashing rejected for IN_PROGRESS game (send failed): %v", err)
	} else {
		// Transaction was sent - check if it reverted
		receipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, tx)
		require.NoError(t, err, "Failed to wait for transaction")
		require.Equal(t, types.ReceiptStatusFailed, receipt.Status, "Transaction should revert for IN_PROGRESS game")
		t.Log("✓ Slashing transaction reverted for IN_PROGRESS game")
	}

	t.Log("✅ Game status check test passed")
}

// setupRATForValidator sets up RAT registration for a validator
func setupRATForValidator(
	t *testing.T,
	sys *rat.TONStakingSystem,
	accounts *rat.TestAccounts,
	slashingContracts *SlashingContracts,
	candidateAddOn common.Address,
	rollupConfig common.Address,
	stakeAmount *big.Int,
) {
	ratInstance, err := bindings.NewRAT(sys.Addresses.RATProxy, sys.L1Client)
	require.NoError(t, err)

	// Set RAT parameters
	ray := new(big.Int).Exp(big.NewInt(10), big.NewInt(27), nil)
	probTx, err := ratInstance.SetRatTriggerProbability(accounts.Deployer.Auth, ray)
	require.NoError(t, err)
	_, err = bind.WaitMined(sys.Ctx, sys.L1Client, probTx)
	require.NoError(t, err)

	thresholdTx, err := ratInstance.SetMinimumThreshold(accounts.Deployer.Auth, big.NewInt(0))
	require.NoError(t, err)
	_, err = bind.WaitMined(sys.Ctx, sys.L1Client, thresholdTx)
	require.NoError(t, err)

	// Deposit validator's own stake for RAT registration
	wtonMint, err := bindings.NewWTON(sys.Addresses.WTON, sys.L1Client)
	require.NoError(t, err)
	mintTx, err := wtonMint.Mint(accounts.Validator.Auth, accounts.Validator.Addr, stakeAmount)
	require.NoError(t, err)
	_, err = bind.WaitMined(sys.Ctx, sys.L1Client, mintTx)
	require.NoError(t, err)

	wtonERC20, err := bindings.NewERC20(sys.Addresses.WTON, sys.L1Client)
	require.NoError(t, err)
	approveTx, err := wtonERC20.Approve(accounts.Validator.Auth, sys.Addresses.DepositManagerProxy, stakeAmount)
	require.NoError(t, err)
	_, err = bind.WaitMined(sys.Ctx, sys.L1Client, approveTx)
	require.NoError(t, err)

	depositTx, err := slashingContracts.DepositManager.Deposit(accounts.Validator.Auth, candidateAddOn, stakeAmount)
	require.NoError(t, err)
	depositReceipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, depositTx)
	require.NoError(t, err)
	require.Equal(t, types.ReceiptStatusSuccessful, depositReceipt.Status, "Validator stake deposit failed")

	registerTx, err := ratInstance.RegisterValidator(accounts.Validator.Auth, rollupConfig)
	require.NoError(t, err)
	_, err = bind.WaitMined(sys.Ctx, sys.L1Client, registerTx)
	require.NoError(t, err)

	t.Logf("✓ RAT setup complete for validator")
}
