package slashing

import (
	"math/big"
	"testing"

	"github.com/ethereum/go-ethereum/common"
	"github.com/stretchr/testify/require"
	"github.com/tokamak-network/ton-staking-v2/op-e2e/bindings"
	rat "github.com/tokamak-network/ton-staking-v2/op-e2e/e2eutils/rat"
)

// TestRewardDistribution_SingleChallengerFullReward tests that a single challenger
// receives 100% of the slashing reward.
func TestRewardDistribution_SingleChallengerFullReward(t *testing.T) {
	t.Parallel()

	sys := rat.StartTONStakingSystem(t)
	accounts := rat.SetupTestAccounts(t, sys)
	contracts := rat.ConnectTestContracts(t, sys)
	slashingContracts := connectSlashingContracts(t, sys)

	t.Log("=== Testing Single Challenger Full Reward ===")

	// Setup operator with specific stake for easy calculation
	// 1,000,000 WTON with 10% slashing rate = 100,000 WTON reward
	operatorStake := new(big.Int).Mul(big.NewInt(1000000), new(big.Int).Exp(big.NewInt(10), big.NewInt(27), nil))
	rat.AdjustMinimumCollateral(t, sys, contracts, accounts.Deployer.Auth, operatorStake)

	candidateAddOn, operatorManager, rollupConfig := registerOperatorWithCandidateAddOn(
		t, sys, slashingContracts, accounts.Validator.Auth, operatorStake,
	)

	// Setup RAT
	setupRATForValidator(t, sys, accounts, slashingContracts, candidateAddOn, rollupConfig, operatorStake)

	// Record balance before
	challengerBalanceBefore := getWTONBalance(t, sys, accounts.Challenger.Addr)
	t.Logf("Challenger WTON balance before: %s", challengerBalanceBefore.String())

	// Create and play game
	rootClaim := [32]byte{0xFF}
	_, gameAddress := rat.CreateDisputeGame(t, sys, accounts.Proposer.Auth, rootClaim)

	correctClaim := [32]byte{0x00}
	rat.AttackClaim(t, sys, accounts.Challenger.Auth, gameAddress, correctClaim, rootClaim)
	rat.AdvanceTimeAndMine(t, sys, 1209600) // 14 days
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
	receipt := executeSlashing(t, sys, slashingContracts, accounts.Challenger.Auth, operatorManager, gameAddress, rootClaim, extraData)

	// Parse events for reward amount - sum all ChallengerRewarded events
	totalEventReward := big.NewInt(0)
	eventCount := 0
	for _, log := range receipt.Logs {
		event, err := slashingContracts.DepositManagerSlashing.ParseChallengerRewarded(*log)
		if err == nil {
			t.Logf("ChallengerRewarded event #%d:", eventCount+1)
			t.Logf("  Layer2: %s", event.Layer2.Hex())
			t.Logf("  Challenger: %s", event.Challenger.Hex())
			t.Logf("  Amount: %s", event.Amount.String())
			totalEventReward.Add(totalEventReward, event.Amount)
			eventCount++
		}
	}
	require.True(t, eventCount > 0, "ChallengerRewarded event should be emitted")

	// Verify WTON balance increased
	challengerBalanceAfter := getWTONBalance(t, sys, accounts.Challenger.Addr)
	actualReward := new(big.Int).Sub(challengerBalanceAfter, challengerBalanceBefore)

	t.Logf("\nWTON Transfer Verification:")
	t.Logf("  Balance before: %s", challengerBalanceBefore.String())
	t.Logf("  Balance after:  %s", challengerBalanceAfter.String())
	t.Logf("  Actual reward:  %s", actualReward.String())
	t.Logf("  Event total:    %s (%d events)", totalEventReward.String(), eventCount)

	// Verify actual balance change is positive
	require.True(t, actualReward.Cmp(big.NewInt(0)) > 0, "Challenger should receive reward")

	// Verify reward matches expected (10% of stake)
	slashingRate := getSlashingRewardRate(t, sys, slashingContracts)
	expectedReward := new(big.Int).Mul(operatorStake, slashingRate)
	expectedReward.Div(expectedReward, big.NewInt(10000))

	t.Logf("  Expected:       %s", expectedReward.String())

	diff := new(big.Int).Sub(expectedReward, actualReward)
	diff.Abs(diff)
	tolerance := new(big.Int).Div(expectedReward, big.NewInt(100))
	require.True(t, diff.Cmp(tolerance) <= 0, "Reward should match expected")

	// Verify operator stake is 0
	operatorStakeAfter := getStakeBalance(t, sys, slashingContracts, candidateAddOn, operatorManager)
	require.Equal(t, int64(0), operatorStakeAfter.Int64())

	t.Log("\n=== Test Complete ===")
	t.Log("✅ Single challenger received full reward")
}

// TestRewardDistribution_VerifyWTONTransfer tests the actual WTON transfer
// to challenger address and verifies events are emitted correctly.
func TestRewardDistribution_VerifyWTONTransfer(t *testing.T) {
	t.Parallel()

	sys := rat.StartTONStakingSystem(t)
	accounts := rat.SetupTestAccounts(t, sys)
	contracts := rat.ConnectTestContracts(t, sys)
	slashingContracts := connectSlashingContracts(t, sys)

	t.Log("=== Testing WTON Transfer Verification ===")

	// Setup operator
	operatorStake := new(big.Int).Mul(big.NewInt(500000), new(big.Int).Exp(big.NewInt(10), big.NewInt(27), nil))
	rat.AdjustMinimumCollateral(t, sys, contracts, accounts.Deployer.Auth, operatorStake)

	candidateAddOn, operatorManager, rollupConfig := registerOperatorWithCandidateAddOn(
		t, sys, slashingContracts, accounts.Validator.Auth, operatorStake,
	)

	// Setup RAT
	setupRATForValidator(t, sys, accounts, slashingContracts, candidateAddOn, rollupConfig, operatorStake)

	// Record challenger balance before
	challengerBalanceBefore := getWTONBalance(t, sys, accounts.Challenger.Addr)

	// Create and play game
	rootClaim := [32]byte{0xAA, 0xBB}
	_, gameAddress := rat.CreateDisputeGame(t, sys, accounts.Proposer.Auth, rootClaim)

	correctClaim := [32]byte{0xCC, 0xDD}
	rat.AttackClaim(t, sys, accounts.Challenger.Auth, gameAddress, correctClaim, rootClaim)
	rat.AdvanceTimeAndMine(t, sys, 1209600)
	rat.ResolveGame(t, sys, accounts.Challenger.Auth, gameAddress)

	// Execute slashing
	l2BlockNumber := big.NewInt(100)
	extraData := common.LeftPadBytes(l2BlockNumber.Bytes(), 32)
	receipt := executeSlashing(t, sys, slashingContracts, accounts.Challenger.Auth, operatorManager, gameAddress, rootClaim, extraData)

	// Parse Slashed event
	for _, log := range receipt.Logs {
		slashedEvent, err := slashingContracts.DepositManagerSlashing.ParseSlashed(*log)
		if err == nil {
			t.Logf("Slashed event:")
			t.Logf("  Layer2: %s", slashedEvent.Layer2.Hex())
			t.Logf("  Operator: %s", slashedEvent.Operator.Hex())
			t.Logf("  Challenger: %s", slashedEvent.Challenger.Hex())
			t.Logf("  SlashedAmount: %s", slashedEvent.SlashedAmount.String())
			t.Logf("  RewardAmount: %s", slashedEvent.RewardAmount.String())
		}
	}

	// Verify challenger received reward
	challengerBalanceAfter := getWTONBalance(t, sys, accounts.Challenger.Addr)
	challengerReward := new(big.Int).Sub(challengerBalanceAfter, challengerBalanceBefore)
	t.Logf("Challenger reward: %s", challengerReward.String())
	require.True(t, challengerReward.Cmp(big.NewInt(0)) > 0, "Challenger should receive reward")

	t.Log("✅ WTON transfer verified")
}

// TestRewardDistribution_ZeroRewardRate tests behavior when slashing reward rate is 0%
func TestRewardDistribution_ZeroRewardRate(t *testing.T) {
	t.Parallel()

	sys := rat.StartTONStakingSystem(t)
	accounts := rat.SetupTestAccounts(t, sys)
	contracts := rat.ConnectTestContracts(t, sys)
	slashingContracts := connectSlashingContracts(t, sys)

	t.Log("=== Testing Zero Reward Rate ===")

	// Setup operator
	operatorStake := new(big.Int).Mul(big.NewInt(500000), new(big.Int).Exp(big.NewInt(10), big.NewInt(27), nil))
	rat.AdjustMinimumCollateral(t, sys, contracts, accounts.Deployer.Auth, operatorStake)

	candidateAddOn, operatorManager, rollupConfig := registerOperatorWithCandidateAddOn(
		t, sys, slashingContracts, accounts.Validator.Auth, operatorStake,
	)

	// Set reward rate to 0%
	setSlashingRewardRate(t, sys, slashingContracts, accounts.Deployer.Auth, big.NewInt(0))
	t.Log("✓ Set slashing reward rate to 0%")

	// Setup RAT
	setupRATForValidator(t, sys, accounts, slashingContracts, candidateAddOn, rollupConfig, operatorStake)

	// Record balance before
	challengerBalanceBefore := getWTONBalance(t, sys, accounts.Challenger.Addr)

	// Create and play game
	rootClaim := [32]byte{0xAA}
	_, gameAddress := rat.CreateDisputeGame(t, sys, accounts.Proposer.Auth, rootClaim)

	correctClaim := [32]byte{0xBB}
	rat.AttackClaim(t, sys, accounts.Challenger.Auth, gameAddress, correctClaim, rootClaim)
	rat.AdvanceTimeAndMine(t, sys, 1209600)
	rat.ResolveGame(t, sys, accounts.Challenger.Auth, gameAddress)

	// Execute slashing
	l2BlockNumber := big.NewInt(100)
	extraData := common.LeftPadBytes(l2BlockNumber.Bytes(), 32)
	executeSlashing(t, sys, slashingContracts, accounts.Challenger.Auth, operatorManager, gameAddress, rootClaim, extraData)

	// Verify operator is slashed
	operatorStakeAfter := getStakeBalance(t, sys, slashingContracts, candidateAddOn, operatorManager)
	require.Equal(t, int64(0), operatorStakeAfter.Int64(), "Operator should be slashed")

	// Verify challenger received no reward
	challengerBalanceAfter := getWTONBalance(t, sys, accounts.Challenger.Addr)
	reward := new(big.Int).Sub(challengerBalanceAfter, challengerBalanceBefore)

	t.Logf("Challenger reward with 0%% rate: %s", reward.String())
	require.Equal(t, int64(0), reward.Int64(), "Challenger should receive no reward with 0% rate")

	t.Log("✅ Zero reward rate test passed - stake burned, no rewards")
}

// TestRewardDistribution_FullRewardRate tests behavior when slashing reward rate is 100%
func TestRewardDistribution_FullRewardRate(t *testing.T) {
	t.Parallel()

	sys := rat.StartTONStakingSystem(t)
	accounts := rat.SetupTestAccounts(t, sys)
	contracts := rat.ConnectTestContracts(t, sys)
	slashingContracts := connectSlashingContracts(t, sys)

	t.Log("=== Testing 100% Reward Rate ===")

	// Setup operator
	operatorStake := new(big.Int).Mul(big.NewInt(500000), new(big.Int).Exp(big.NewInt(10), big.NewInt(27), nil))
	rat.AdjustMinimumCollateral(t, sys, contracts, accounts.Deployer.Auth, operatorStake)

	candidateAddOn, operatorManager, rollupConfig := registerOperatorWithCandidateAddOn(
		t, sys, slashingContracts, accounts.Validator.Auth, operatorStake,
	)

	// Set reward rate to 100% (10000 basis points)
	setSlashingRewardRate(t, sys, slashingContracts, accounts.Deployer.Auth, big.NewInt(10000))
	t.Log("✓ Set slashing reward rate to 100%")

	// Setup RAT
	setupRATForValidator(t, sys, accounts, slashingContracts, candidateAddOn, rollupConfig, operatorStake)

	// Record balance before
	challengerBalanceBefore := getWTONBalance(t, sys, accounts.Challenger.Addr)

	// Create and play game
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

	// Verify operator is slashed
	operatorStakeAfter := getStakeBalance(t, sys, slashingContracts, candidateAddOn, operatorManager)
	require.Equal(t, int64(0), operatorStakeAfter.Int64())

	// Verify challenger received full amount
	challengerBalanceAfter := getWTONBalance(t, sys, accounts.Challenger.Addr)
	reward := new(big.Int).Sub(challengerBalanceAfter, challengerBalanceBefore)

	t.Logf("Operator stake: %s", operatorStake.String())
	t.Logf("Challenger reward: %s", reward.String())

	// Reward should be approximately equal to operator stake (within 1%)
	diff := new(big.Int).Sub(operatorStake, reward)
	diff.Abs(diff)
	tolerance := new(big.Int).Div(operatorStake, big.NewInt(100))

	require.True(t, diff.Cmp(tolerance) <= 0, "Challenger should receive approximately 100% of slashed stake")

	t.Log("✅ Full reward rate test passed - challenger received ~100%")
}

// TestRewardDistribution_SlashedEventEmitted tests that Slashed event is properly emitted
func TestRewardDistribution_SlashedEventEmitted(t *testing.T) {
	t.Parallel()

	sys := rat.StartTONStakingSystem(t)
	accounts := rat.SetupTestAccounts(t, sys)
	contracts := rat.ConnectTestContracts(t, sys)
	slashingContracts := connectSlashingContracts(t, sys)

	t.Log("=== Testing Slashed Event Emission ===")

	// Setup operator
	operatorStake := new(big.Int).Mul(big.NewInt(500000), new(big.Int).Exp(big.NewInt(10), big.NewInt(27), nil))
	rat.AdjustMinimumCollateral(t, sys, contracts, accounts.Deployer.Auth, operatorStake)

	candidateAddOn, operatorManager, rollupConfig := registerOperatorWithCandidateAddOn(
		t, sys, slashingContracts, accounts.Validator.Auth, operatorStake,
	)

	// Setup RAT
	setupRATForValidator(t, sys, accounts, slashingContracts, candidateAddOn, rollupConfig, operatorStake)

	// Create and play game
	rootClaim := [32]byte{0xEE}
	_, gameAddress := rat.CreateDisputeGame(t, sys, accounts.Proposer.Auth, rootClaim)

	correctClaim := [32]byte{0xFF}
	rat.AttackClaim(t, sys, accounts.Challenger.Auth, gameAddress, correctClaim, rootClaim)
	rat.AdvanceTimeAndMine(t, sys, 1209600)
	rat.ResolveGame(t, sys, accounts.Challenger.Auth, gameAddress)

	// Execute slashing
	l2BlockNumber := big.NewInt(100)
	extraData := common.LeftPadBytes(l2BlockNumber.Bytes(), 32)
	receipt := executeSlashing(t, sys, slashingContracts, accounts.Challenger.Auth, operatorManager, gameAddress, rootClaim, extraData)

	// Parse and verify Slashed event
	var slashedEvent *bindings.DepositManagerSlashingSlashed
	for _, log := range receipt.Logs {
		event, err := slashingContracts.DepositManagerSlashing.ParseSlashed(*log)
		if err == nil {
			slashedEvent = event
			break
		}
	}

	require.NotNil(t, slashedEvent, "Slashed event should be emitted")
	t.Logf("Slashed event found:")
	t.Logf("  Layer2: %s", slashedEvent.Layer2.Hex())
	t.Logf("  Operator: %s", slashedEvent.Operator.Hex())
	t.Logf("  Challenger: %s", slashedEvent.Challenger.Hex())
	t.Logf("  SlashedAmount: %s", slashedEvent.SlashedAmount.String())
	t.Logf("  RewardAmount: %s", slashedEvent.RewardAmount.String())

	// Verify event fields
	require.Equal(t, candidateAddOn, slashedEvent.Layer2, "Layer2 should match")
	require.Equal(t, operatorManager, slashedEvent.Operator, "Operator should match")
	require.True(t, slashedEvent.SlashedAmount.Cmp(big.NewInt(0)) > 0, "SlashedAmount should be > 0")

	// Calculate expected values
	slashingRate := getSlashingRewardRate(t, sys, slashingContracts)
	expectedReward := new(big.Int).Mul(operatorStake, slashingRate)
	expectedReward.Div(expectedReward, big.NewInt(10000))

	diff := new(big.Int).Sub(expectedReward, slashedEvent.RewardAmount)
	diff.Abs(diff)
	tolerance := new(big.Int).Div(expectedReward, big.NewInt(100))
	require.True(t, diff.Cmp(tolerance) <= 0, "RewardAmount should match expected")

	t.Log("✅ Slashed event correctly emitted")
}

// TestRewardDistribution_ChallengerRewardedEventEmitted tests that ChallengerRewarded events are emitted
func TestRewardDistribution_ChallengerRewardedEventEmitted(t *testing.T) {
	t.Parallel()

	sys := rat.StartTONStakingSystem(t)
	accounts := rat.SetupTestAccounts(t, sys)
	contracts := rat.ConnectTestContracts(t, sys)
	slashingContracts := connectSlashingContracts(t, sys)

	t.Log("=== Testing ChallengerRewarded Event Emission ===")

	// Setup operator
	operatorStake := new(big.Int).Mul(big.NewInt(500000), new(big.Int).Exp(big.NewInt(10), big.NewInt(27), nil))
	rat.AdjustMinimumCollateral(t, sys, contracts, accounts.Deployer.Auth, operatorStake)

	candidateAddOn, operatorManager, rollupConfig := registerOperatorWithCandidateAddOn(
		t, sys, slashingContracts, accounts.Validator.Auth, operatorStake,
	)

	// Setup RAT
	setupRATForValidator(t, sys, accounts, slashingContracts, candidateAddOn, rollupConfig, operatorStake)

	// Create and play game
	rootClaim := [32]byte{0x11}
	_, gameAddress := rat.CreateDisputeGame(t, sys, accounts.Proposer.Auth, rootClaim)

	correctClaim := [32]byte{0x22}
	rat.AttackClaim(t, sys, accounts.Challenger.Auth, gameAddress, correctClaim, rootClaim)
	rat.AdvanceTimeAndMine(t, sys, 1209600)
	rat.ResolveGame(t, sys, accounts.Challenger.Auth, gameAddress)

	// Execute slashing
	l2BlockNumber := big.NewInt(100)
	extraData := common.LeftPadBytes(l2BlockNumber.Bytes(), 32)
	receipt := executeSlashing(t, sys, slashingContracts, accounts.Challenger.Auth, operatorManager, gameAddress, rootClaim, extraData)

	// Parse and verify ChallengerRewarded event
	var rewardedEvent *bindings.DepositManagerSlashingChallengerRewarded
	for _, log := range receipt.Logs {
		event, err := slashingContracts.DepositManagerSlashing.ParseChallengerRewarded(*log)
		if err == nil {
			rewardedEvent = event
			break
		}
	}

	require.NotNil(t, rewardedEvent, "ChallengerRewarded event should be emitted")
	t.Logf("ChallengerRewarded event found:")
	t.Logf("  Layer2: %s", rewardedEvent.Layer2.Hex())
	t.Logf("  Challenger: %s", rewardedEvent.Challenger.Hex())
	t.Logf("  Amount: %s", rewardedEvent.Amount.String())

	// Verify event fields
	require.Equal(t, candidateAddOn, rewardedEvent.Layer2, "Layer2 should match")
	require.Equal(t, accounts.Challenger.Addr, rewardedEvent.Challenger, "Challenger should match")
	require.True(t, rewardedEvent.Amount.Cmp(big.NewInt(0)) > 0, "Amount should be > 0")

	t.Log("✅ ChallengerRewarded event correctly emitted")
}

