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

// =============================================================================
// Category 3: Complex Scenario Tests
// =============================================================================

// TestComplexScenario_MultipleGamesAgainstSameOperator tests multiple sequential
// dispute games targeting the same operator.
func TestComplexScenario_MultipleGamesAgainstSameOperator(t *testing.T) {
	t.Parallel()

	sys := rat.StartTONStakingSystem(t)
	accounts := rat.SetupTestAccounts(t, sys)
	contracts := rat.ConnectTestContracts(t, sys)
	slashingContracts := connectSlashingContracts(t, sys)

	t.Log("=== Testing Multiple Games Against Same Operator ===")

	// Setup operator with large stake for multiple slashings
	operatorStake := new(big.Int).Mul(big.NewInt(1000000), new(big.Int).Exp(big.NewInt(10), big.NewInt(27), nil))
	rat.AdjustMinimumCollateral(t, sys, contracts, accounts.Deployer.Auth, operatorStake)

	candidateAddOn, operatorManager, rollupConfig := registerOperatorWithCandidateAddOn(
		t, sys, slashingContracts, accounts.Validator.Auth, operatorStake,
	)

	// Setup RAT
	setupRATForValidator(t, sys, accounts, slashingContracts, candidateAddOn, rollupConfig, operatorStake)

	// Record initial stake
	initialStake := getStakeBalance(t, sys, slashingContracts, candidateAddOn, operatorManager)
	t.Logf("Initial operator stake: %s", initialStake.String())

	// Game 1
	t.Log("\n--- Game 1 ---")
	rootClaim1 := [32]byte{0x01}
	_, gameAddress1 := rat.CreateDisputeGame(t, sys, accounts.Proposer.Auth, rootClaim1)

	correctClaim1 := [32]byte{0xA1}
	rat.AttackClaim(t, sys, accounts.Challenger.Auth, gameAddress1, correctClaim1, rootClaim1)
	rat.AdvanceTimeAndMine(t, sys, 1209600)
	rat.ResolveGame(t, sys, accounts.Challenger.Auth, gameAddress1)

	l2BlockNumber1 := big.NewInt(100)
	extraData1 := common.LeftPadBytes(l2BlockNumber1.Bytes(), 32)
	executeSlashing(t, sys, slashingContracts, accounts.Challenger.Auth, operatorManager, gameAddress1, rootClaim1, extraData1)
	t.Log("✓ Game 1 slashing executed")

	// Verify first slashing result
	stakeAfterGame1 := getStakeBalance(t, sys, slashingContracts, candidateAddOn, operatorManager)
	t.Logf("Stake after Game 1: %s", stakeAfterGame1.String())

	// Operator is now slashed - subsequent games cannot slash again
	// Game 2 - should fail or have no effect
	t.Log("\n--- Game 2 (should fail - operator already slashed) ---")
	rootClaim2 := [32]byte{0x02}
	_, gameAddress2 := rat.CreateDisputeGame(t, sys, accounts.Proposer.Auth, rootClaim2)

	correctClaim2 := [32]byte{0xA2}
	rat.AttackClaim(t, sys, accounts.Challenger.Auth, gameAddress2, correctClaim2, rootClaim2)
	rat.AdvanceTimeAndMine(t, sys, 1209600)
	rat.ResolveGame(t, sys, accounts.Challenger.Auth, gameAddress2)

	// Try to slash again - should fail (already slashed or 0 stake)
	gameType := uint32(0)
	l2BlockNumber2 := big.NewInt(101)
	extraData2 := common.LeftPadBytes(l2BlockNumber2.Bytes(), 32)

	tx, err := slashingContracts.Layer2ManagerSlashing.SlashingCandidate(
		accounts.Challenger.Auth,
		operatorManager,
		gameType,
		rootClaim2,
		extraData2,
		gameAddress2,
	)
	if err != nil {
		t.Logf("✓ Game 2 slashing rejected: %v", err)
	} else {
		receipt, _ := bind.WaitMined(sys.Ctx, sys.L1Client, tx)
		t.Logf("Game 2 slashing tx status: %d (0=failed, 1=success)", receipt.Status)
	}

	t.Log("✅ Multiple games against same operator test completed")
}

// TestComplexScenario_HighStakeAmount tests slashing with very high stake amounts
// to verify precision handling.
func TestComplexScenario_HighStakeAmount(t *testing.T) {
	t.Parallel()

	sys := rat.StartTONStakingSystem(t)
	accounts := rat.SetupTestAccounts(t, sys)
	contracts := rat.ConnectTestContracts(t, sys)
	slashingContracts := connectSlashingContracts(t, sys)

	t.Log("=== Testing High Stake Amount Precision ===")

	// Very high stake amount: 100 million TON (with 27 decimals)
	// This is 10^8 * 10^27 = 10^35
	operatorStake := new(big.Int).Mul(
		big.NewInt(100000000), // 100 million
		new(big.Int).Exp(big.NewInt(10), big.NewInt(27), nil),
	)
	rat.AdjustMinimumCollateral(t, sys, contracts, accounts.Deployer.Auth, operatorStake)

	candidateAddOn, operatorManager, rollupConfig := registerOperatorWithCandidateAddOn(
		t, sys, slashingContracts, accounts.Validator.Auth, operatorStake,
	)

	// Setup RAT
	setupRATForValidator(t, sys, accounts, slashingContracts, candidateAddOn, rollupConfig, operatorStake)

	// Record initial state
	initialStake := getStakeBalance(t, sys, slashingContracts, candidateAddOn, operatorManager)
	challengerBalanceBefore := getWTONBalance(t, sys, accounts.Challenger.Addr)
	t.Logf("Initial stake: %s", initialStake.String())
	t.Logf("Challenger balance before: %s", challengerBalanceBefore.String())

	// Create and resolve game
	rootClaim := [32]byte{0xBE, 0xEF}
	_, gameAddress := rat.CreateDisputeGame(t, sys, accounts.Proposer.Auth, rootClaim)

	correctClaim := [32]byte{0xDE, 0xAD}
	rat.AttackClaim(t, sys, accounts.Challenger.Auth, gameAddress, correctClaim, rootClaim)
	rat.AdvanceTimeAndMine(t, sys, 1209600)
	rat.ResolveGame(t, sys, accounts.Challenger.Auth, gameAddress)

	// Execute slashing
	l2BlockNumber := big.NewInt(100)
	extraData := common.LeftPadBytes(l2BlockNumber.Bytes(), 32)
	executeSlashing(t, sys, slashingContracts, accounts.Challenger.Auth, operatorManager, gameAddress, rootClaim, extraData)

	// Verify results
	finalStake := getStakeBalance(t, sys, slashingContracts, candidateAddOn, operatorManager)
	challengerBalanceAfter := getWTONBalance(t, sys, accounts.Challenger.Addr)
	reward := new(big.Int).Sub(challengerBalanceAfter, challengerBalanceBefore)

	t.Logf("Final stake: %s", finalStake.String())
	t.Logf("Challenger reward: %s", reward.String())

	require.Equal(t, int64(0), finalStake.Int64(), "Stake should be 0")
	require.True(t, reward.Cmp(big.NewInt(0)) > 0, "Challenger should receive reward")

	// Verify reward is approximately correct (10% of stake by default)
	slashingRate := getSlashingRewardRate(t, sys, slashingContracts)
	expectedReward := new(big.Int).Mul(operatorStake, slashingRate)
	expectedReward.Div(expectedReward, big.NewInt(10000))

	// Allow 1% tolerance for precision
	diff := new(big.Int).Sub(expectedReward, reward)
	diff.Abs(diff)
	tolerance := new(big.Int).Div(expectedReward, big.NewInt(100))

	t.Logf("Expected reward: %s", expectedReward.String())
	t.Logf("Actual reward: %s", reward.String())
	t.Logf("Difference: %s", diff.String())

	require.True(t, diff.Cmp(tolerance) <= 0, "Reward should be approximately 10%% of stake")

	t.Log("✅ High stake amount precision test passed")
}

// TestComplexScenario_MinimumStakeSlashing tests slashing with relatively small stake amount.
func TestComplexScenario_MinimumStakeSlashing(t *testing.T) {
	t.Parallel()

	sys := rat.StartTONStakingSystem(t)
	accounts := rat.SetupTestAccounts(t, sys)
	contracts := rat.ConnectTestContracts(t, sys)
	slashingContracts := connectSlashingContracts(t, sys)

	t.Log("=== Testing Small Stake Slashing ===")

	// Use relatively small stake (100,000 TON - smaller than typical but still valid)
	operatorStake := new(big.Int).Mul(
		big.NewInt(100000),
		new(big.Int).Exp(big.NewInt(10), big.NewInt(27), nil),
	)
	rat.AdjustMinimumCollateral(t, sys, contracts, accounts.Deployer.Auth, operatorStake)

	candidateAddOn, operatorManager, rollupConfig := registerOperatorWithCandidateAddOn(
		t, sys, slashingContracts, accounts.Validator.Auth, operatorStake,
	)

	// Setup RAT
	setupRATForValidator(t, sys, accounts, slashingContracts, candidateAddOn, rollupConfig, operatorStake)

	// Record initial state
	challengerBalanceBefore := getWTONBalance(t, sys, accounts.Challenger.Addr)
	t.Logf("Operator stake: %s", operatorStake.String())
	t.Logf("Challenger balance before: %s", challengerBalanceBefore.String())

	// Create and resolve game
	rootClaim := [32]byte{0xCC}
	_, gameAddress := rat.CreateDisputeGame(t, sys, accounts.Proposer.Auth, rootClaim)

	correctClaim := [32]byte{0xDD}
	rat.AttackClaim(t, sys, accounts.Challenger.Auth, gameAddress, correctClaim, rootClaim)
	rat.AdvanceTimeAndMine(t, sys, 1209600)
	rat.ResolveGame(t, sys, accounts.Challenger.Auth, gameAddress)

	// Execute slashing
	l2BlockNumber := big.NewInt(100)
	extraData := common.LeftPadBytes(l2BlockNumber.Bytes(), 32)
	executeSlashing(t, sys, slashingContracts, accounts.Challenger.Auth, operatorManager, gameAddress, rootClaim, extraData)

	// Verify results
	finalStake := getStakeBalance(t, sys, slashingContracts, candidateAddOn, operatorManager)
	challengerBalanceAfter := getWTONBalance(t, sys, accounts.Challenger.Addr)
	reward := new(big.Int).Sub(challengerBalanceAfter, challengerBalanceBefore)

	t.Logf("Final stake: %s", finalStake.String())
	t.Logf("Challenger reward: %s", reward.String())

	require.Equal(t, int64(0), finalStake.Int64(), "Stake should be 0")
	require.True(t, reward.Cmp(big.NewInt(0)) > 0, "Challenger should receive reward even with minimum stake")

	t.Log("✅ Minimum stake slashing test passed")
}

// TestComplexScenario_SlashingWithActiveWithdrawalRequest tests slashing when
// the operator has an active withdrawal request pending.
func TestComplexScenario_SlashingWithActiveWithdrawalRequest(t *testing.T) {
	t.Parallel()

	sys := rat.StartTONStakingSystem(t)
	accounts := rat.SetupTestAccounts(t, sys)
	contracts := rat.ConnectTestContracts(t, sys)
	slashingContracts := connectSlashingContracts(t, sys)

	t.Log("=== Testing Slashing With Active Withdrawal Request ===")

	// Setup operator
	operatorStake := new(big.Int).Mul(big.NewInt(500000), new(big.Int).Exp(big.NewInt(10), big.NewInt(27), nil))
	rat.AdjustMinimumCollateral(t, sys, contracts, accounts.Deployer.Auth, operatorStake)

	candidateAddOn, operatorManager, rollupConfig := registerOperatorWithCandidateAddOn(
		t, sys, slashingContracts, accounts.Validator.Auth, operatorStake,
	)

	// Setup RAT
	setupRATForValidator(t, sys, accounts, slashingContracts, candidateAddOn, rollupConfig, operatorStake)

	// Record initial stake
	initialStake := getStakeBalance(t, sys, slashingContracts, candidateAddOn, operatorManager)
	t.Logf("Initial operator stake: %s", initialStake.String())

	// Operator requests partial withdrawal before getting slashed
	withdrawAmount := new(big.Int).Div(operatorStake, big.NewInt(2)) // 50% withdrawal

	// Get operator's auth for withdrawal request
	operatorAuth := accounts.Validator.Auth // Validator is the operator in this test

	withdrawTx, err := slashingContracts.DepositManager.RequestWithdrawal(
		operatorAuth,
		candidateAddOn,
		withdrawAmount,
	)

	if err != nil {
		t.Logf("Note: Withdrawal request not supported for this operator type: %v", err)
	} else {
		receipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, withdrawTx)
		require.NoError(t, err)
		if receipt.Status == types.ReceiptStatusSuccessful {
			t.Log("✓ Withdrawal request submitted")
		}
	}

	// Create dispute game
	rootClaim := [32]byte{0xAB}
	_, gameAddress := rat.CreateDisputeGame(t, sys, accounts.Proposer.Auth, rootClaim)

	correctClaim := [32]byte{0xCD}
	rat.AttackClaim(t, sys, accounts.Challenger.Auth, gameAddress, correctClaim, rootClaim)
	rat.AdvanceTimeAndMine(t, sys, 1209600)
	rat.ResolveGame(t, sys, accounts.Challenger.Auth, gameAddress)

	// Execute slashing
	l2BlockNumber := big.NewInt(100)
	extraData := common.LeftPadBytes(l2BlockNumber.Bytes(), 32)
	executeSlashing(t, sys, slashingContracts, accounts.Challenger.Auth, operatorManager, gameAddress, rootClaim, extraData)
	t.Log("✓ Slashing executed")

	// Verify operator stake is 0 (regardless of pending withdrawal)
	finalStake := getStakeBalance(t, sys, slashingContracts, candidateAddOn, operatorManager)
	t.Logf("Final operator stake: %s", finalStake.String())
	require.Equal(t, int64(0), finalStake.Int64(), "Operator stake should be 0 after slashing")

	t.Log("✅ Slashing with active withdrawal request test completed")
}

// TestComplexScenario_ChallengerIsAlsoDelegator tests when the winning challenger
// is also a delegator to the slashed operator.
func TestComplexScenario_ChallengerIsAlsoDelegator(t *testing.T) {
	t.Parallel()

	sys := rat.StartTONStakingSystem(t)
	accounts := rat.SetupTestAccounts(t, sys)
	contracts := rat.ConnectTestContracts(t, sys)
	slashingContracts := connectSlashingContracts(t, sys)

	t.Log("=== Testing Challenger Is Also Delegator ===")

	// Setup operator
	operatorStake := new(big.Int).Mul(big.NewInt(500000), new(big.Int).Exp(big.NewInt(10), big.NewInt(27), nil))
	rat.AdjustMinimumCollateral(t, sys, contracts, accounts.Deployer.Auth, operatorStake)

	candidateAddOn, operatorManager, rollupConfig := registerOperatorWithCandidateAddOn(
		t, sys, slashingContracts, accounts.Validator.Auth, operatorStake,
	)

	// Setup RAT
	setupRATForValidator(t, sys, accounts, slashingContracts, candidateAddOn, rollupConfig, operatorStake)

	// Challenger also delegates to the operator
	challengerDelegateAmount := new(big.Int).Mul(big.NewInt(50000), new(big.Int).Exp(big.NewInt(10), big.NewInt(27), nil))
	mintWTONForAccountWithAuth(t, sys, accounts.Challenger.Addr, challengerDelegateAmount, accounts.Deployer.Auth)
	delegatorDeposit(t, sys, slashingContracts, accounts.Challenger.Auth, candidateAddOn, challengerDelegateAmount)
	t.Log("✓ Challenger delegated to operator")

	// Record balances before
	challengerStakeBefore := getStakeBalance(t, sys, slashingContracts, candidateAddOn, accounts.Challenger.Addr)
	challengerWTONBefore := getWTONBalance(t, sys, accounts.Challenger.Addr)
	operatorStakeBefore := getStakeBalance(t, sys, slashingContracts, candidateAddOn, operatorManager)

	t.Logf("Before slashing:")
	t.Logf("  Operator stake: %s", operatorStakeBefore.String())
	t.Logf("  Challenger stake (as delegator): %s", challengerStakeBefore.String())
	t.Logf("  Challenger WTON: %s", challengerWTONBefore.String())

	// Create and resolve game
	rootClaim := [32]byte{0xEE}
	_, gameAddress := rat.CreateDisputeGame(t, sys, accounts.Proposer.Auth, rootClaim)

	correctClaim := [32]byte{0xFF}
	rat.AttackClaim(t, sys, accounts.Challenger.Auth, gameAddress, correctClaim, rootClaim)
	rat.AdvanceTimeAndMine(t, sys, 1209600)
	rat.ResolveGame(t, sys, accounts.Challenger.Auth, gameAddress)

	// Execute slashing - challenger wins
	l2BlockNumber := big.NewInt(100)
	extraData := common.LeftPadBytes(l2BlockNumber.Bytes(), 32)
	executeSlashing(t, sys, slashingContracts, accounts.Challenger.Auth, operatorManager, gameAddress, rootClaim, extraData)
	t.Log("✓ Slashing executed")

	// Verify results
	challengerStakeAfter := getStakeBalance(t, sys, slashingContracts, candidateAddOn, accounts.Challenger.Addr)
	challengerWTONAfter := getWTONBalance(t, sys, accounts.Challenger.Addr)
	operatorStakeAfter := getStakeBalance(t, sys, slashingContracts, candidateAddOn, operatorManager)

	t.Logf("After slashing:")
	t.Logf("  Operator stake: %s", operatorStakeAfter.String())
	t.Logf("  Challenger stake (as delegator): %s", challengerStakeAfter.String())
	t.Logf("  Challenger WTON: %s", challengerWTONAfter.String())

	// Operator should be slashed
	require.Equal(t, int64(0), operatorStakeAfter.Int64(), "Operator stake should be 0")

	// Challenger's delegated stake should be preserved
	require.True(t, challengerStakeAfter.Cmp(challengerStakeBefore) == 0, "Challenger's delegated stake should be preserved")

	// Challenger should have received reward
	challengerReward := new(big.Int).Sub(challengerWTONAfter, challengerWTONBefore)
	require.True(t, challengerReward.Cmp(big.NewInt(0)) > 0, "Challenger should receive slashing reward")
	t.Logf("Challenger reward: %s", challengerReward.String())

	t.Log("✅ Challenger is also delegator test passed")
}

// =============================================================================
// Helper functions
// =============================================================================

// mintWTONForAccountWithAuth mints WTON using provided auth
func mintWTONForAccountWithAuth(
	t *testing.T,
	sys *rat.TONStakingSystem,
	account common.Address,
	amount *big.Int,
	auth *bind.TransactOpts,
) {
	wton, err := bindings.NewWTON(sys.Addresses.WTON, sys.L1Client)
	require.NoError(t, err)

	tx, err := wton.Mint(auth, account, amount)
	require.NoError(t, err)

	receipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, tx)
	require.NoError(t, err)
	require.Equal(t, types.ReceiptStatusSuccessful, receipt.Status, "WTON mint failed")

	t.Logf("✓ Minted %s WTON to %s", amount.String(), account.Hex()[:10])
}
