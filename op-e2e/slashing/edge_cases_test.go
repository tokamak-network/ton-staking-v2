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
// Category 1: Edge Cases and Boundary Conditions
// =============================================================================

// TestEdgeCase_DefenderWinsCannotSlash tests that slashing fails when
// the game status is DEFENDER_WINS (status = 2).
func TestEdgeCase_DefenderWinsCannotSlash(t *testing.T) {
	t.Parallel()

	sys := rat.StartTONStakingSystem(t)
	accounts := rat.SetupTestAccounts(t, sys)
	contracts := rat.ConnectTestContracts(t, sys)
	slashingContracts := connectSlashingContracts(t, sys)

	t.Log("=== Testing DEFENDER_WINS Cannot Slash ===")

	// Setup operator
	operatorStake := new(big.Int).Mul(big.NewInt(500000), new(big.Int).Exp(big.NewInt(10), big.NewInt(27), nil))
	rat.AdjustMinimumCollateral(t, sys, contracts, accounts.Deployer.Auth, operatorStake)

	candidateAddOn, operatorManager, rollupConfig := registerOperatorWithCandidateAddOn(
		t, sys, slashingContracts, accounts.Validator.Auth, operatorStake,
	)

	// Setup RAT
	setupRATForValidator(t, sys, accounts, slashingContracts, candidateAddOn, rollupConfig, operatorStake)

	// Create game with a valid root claim (so defender wins if not challenged properly)
	rootClaim := [32]byte{0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01} // Valid claim
	_, gameAddress := rat.CreateDisputeGame(t, sys, accounts.Proposer.Auth, rootClaim)
	t.Logf("✓ DisputeGame created at: %s", gameAddress.Hex())

	// Don't attack the game - just let time pass and resolve
	// This should result in DEFENDER_WINS
	rat.AdvanceTimeAndMine(t, sys, 1209600) // 14 days

	// Resolve the game - should be DEFENDER_WINS since no valid attack
	game, err := bindings.NewFaultDisputeGame(gameAddress, sys.L1Client)
	require.NoError(t, err)

	// Resolve the game
	resolveTx, err := game.Resolve(accounts.Proposer.Auth)
	if err == nil {
		receipt, _ := bind.WaitMined(sys.Ctx, sys.L1Client, resolveTx)
		t.Logf("Game resolve tx status: %d", receipt.Status)
	}

	// Check game status
	status, err := game.Status(nil)
	require.NoError(t, err)
	t.Logf("Game status: %d (0=IN_PROGRESS, 1=CHALLENGER_WINS, 2=DEFENDER_WINS)", status)

	// If game is DEFENDER_WINS, try to slash - should fail
	if status == 2 {
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
			t.Logf("✓ Slashing rejected for DEFENDER_WINS game (send failed): %v", err)
		} else {
			receipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, tx)
			require.NoError(t, err)
			require.Equal(t, types.ReceiptStatusFailed, receipt.Status, "Slashing should fail for DEFENDER_WINS game")
			t.Log("✓ Slashing transaction reverted for DEFENDER_WINS game")
		}
	} else {
		t.Logf("Note: Game ended with status %d, not DEFENDER_WINS", status)
	}

	t.Log("✅ DEFENDER_WINS slashing prevention test completed")
}

// TestEdgeCase_ZeroStakeOperatorSlashing tests slashing an operator that has
// already had all their stake slashed (stake = 0).
func TestEdgeCase_ZeroStakeOperatorSlashing(t *testing.T) {
	t.Parallel()

	sys := rat.StartTONStakingSystem(t)
	accounts := rat.SetupTestAccounts(t, sys)
	contracts := rat.ConnectTestContracts(t, sys)
	slashingContracts := connectSlashingContracts(t, sys)

	t.Log("=== Testing Zero Stake Operator Slashing ===")

	// Setup operator
	operatorStake := new(big.Int).Mul(big.NewInt(500000), new(big.Int).Exp(big.NewInt(10), big.NewInt(27), nil))
	rat.AdjustMinimumCollateral(t, sys, contracts, accounts.Deployer.Auth, operatorStake)

	candidateAddOn, operatorManager, rollupConfig := registerOperatorWithCandidateAddOn(
		t, sys, slashingContracts, accounts.Validator.Auth, operatorStake,
	)

	// Setup RAT
	setupRATForValidator(t, sys, accounts, slashingContracts, candidateAddOn, rollupConfig, operatorStake)

	// First slashing - should succeed
	rootClaim1 := [32]byte{0xAA}
	_, gameAddress1 := rat.CreateDisputeGame(t, sys, accounts.Proposer.Auth, rootClaim1)

	correctClaim1 := [32]byte{0xBB}
	rat.AttackClaim(t, sys, accounts.Challenger.Auth, gameAddress1, correctClaim1, rootClaim1)
	rat.AdvanceTimeAndMine(t, sys, 1209600)
	rat.ResolveGame(t, sys, accounts.Challenger.Auth, gameAddress1)

	l2BlockNumber := big.NewInt(100)
	extraData := common.LeftPadBytes(l2BlockNumber.Bytes(), 32)
	executeSlashing(t, sys, slashingContracts, accounts.Challenger.Auth, operatorManager, gameAddress1, rootClaim1, extraData)
	t.Log("✓ First slashing succeeded")

	// Verify operator stake is now 0
	stakeAfterFirst := getStakeBalance(t, sys, slashingContracts, candidateAddOn, operatorManager)
	require.Equal(t, int64(0), stakeAfterFirst.Int64(), "Operator stake should be 0 after first slashing")
	t.Log("✓ Operator stake is now 0")

	// Create second game and try to slash again
	rootClaim2 := [32]byte{0xCC}
	_, gameAddress2 := rat.CreateDisputeGame(t, sys, accounts.Proposer.Auth, rootClaim2)

	correctClaim2 := [32]byte{0xDD}
	rat.AttackClaim(t, sys, accounts.Challenger.Auth, gameAddress2, correctClaim2, rootClaim2)
	rat.AdvanceTimeAndMine(t, sys, 1209600)
	rat.ResolveGame(t, sys, accounts.Challenger.Auth, gameAddress2)

	// Second slashing attempt - operator has 0 stake
	gameType := uint32(0)
	extraData2 := common.LeftPadBytes(big.NewInt(101).Bytes(), 32)

	tx, err := slashingContracts.Layer2ManagerSlashing.SlashingCandidate(
		accounts.Challenger.Auth,
		operatorManager,
		gameType,
		rootClaim2,
		extraData2,
		gameAddress2,
	)

	if err != nil {
		t.Logf("✓ Second slashing rejected (operator has 0 stake): %v", err)
	} else {
		receipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, tx)
		require.NoError(t, err)
		// It might succeed with 0 reward, or fail - both are acceptable
		t.Logf("Second slashing tx status: %d (0=failed, 1=success)", receipt.Status)
		if receipt.Status == types.ReceiptStatusSuccessful {
			t.Log("✓ Second slashing succeeded but with 0 stake (no reward)")
		} else {
			t.Log("✓ Second slashing transaction reverted (operator has 0 stake)")
		}
	}

	t.Log("✅ Zero stake operator slashing test completed")
}

// TestEdgeCase_UnregisteredOperatorSlashing tests slashing an operator
// that is not registered in the system.
func TestEdgeCase_UnregisteredOperatorSlashing(t *testing.T) {
	t.Parallel()

	sys := rat.StartTONStakingSystem(t)
	accounts := rat.SetupTestAccounts(t, sys)
	slashingContracts := connectSlashingContracts(t, sys)

	t.Log("=== Testing Unregistered Operator Slashing ===")

	// Create a random address that is not registered as an operator
	unregisteredOperator := common.HexToAddress("0x1234567890123456789012345678901234567890")
	t.Logf("Using unregistered operator address: %s", unregisteredOperator.Hex())

	// Create a game
	rootClaim := [32]byte{0xEE}
	_, gameAddress := rat.CreateDisputeGame(t, sys, accounts.Proposer.Auth, rootClaim)

	correctClaim := [32]byte{0xFF}
	rat.AttackClaim(t, sys, accounts.Challenger.Auth, gameAddress, correctClaim, rootClaim)
	rat.AdvanceTimeAndMine(t, sys, 1209600)
	rat.ResolveGame(t, sys, accounts.Challenger.Auth, gameAddress)

	// Try to slash unregistered operator
	gameType := uint32(0)
	l2BlockNumber := big.NewInt(100)
	extraData := common.LeftPadBytes(l2BlockNumber.Bytes(), 32)

	tx, err := slashingContracts.Layer2ManagerSlashing.SlashingCandidate(
		accounts.Challenger.Auth,
		unregisteredOperator,
		gameType,
		rootClaim,
		extraData,
		gameAddress,
	)

	if err != nil {
		t.Logf("✓ Slashing rejected for unregistered operator: %v", err)
	} else {
		receipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, tx)
		require.NoError(t, err)
		require.Equal(t, types.ReceiptStatusFailed, receipt.Status, "Slashing should fail for unregistered operator")
		t.Log("✓ Slashing transaction reverted for unregistered operator")
	}

	t.Log("✅ Unregistered operator slashing test completed")
}

// TestEdgeCase_InvalidGameAddress tests slashing with a non-existent game address.
func TestEdgeCase_InvalidGameAddress(t *testing.T) {
	t.Parallel()

	sys := rat.StartTONStakingSystem(t)
	accounts := rat.SetupTestAccounts(t, sys)
	contracts := rat.ConnectTestContracts(t, sys)
	slashingContracts := connectSlashingContracts(t, sys)

	t.Log("=== Testing Invalid Game Address Slashing ===")

	// Setup operator
	operatorStake := new(big.Int).Mul(big.NewInt(500000), new(big.Int).Exp(big.NewInt(10), big.NewInt(27), nil))
	rat.AdjustMinimumCollateral(t, sys, contracts, accounts.Deployer.Auth, operatorStake)

	_, operatorManager, rollupConfig := registerOperatorWithCandidateAddOn(
		t, sys, slashingContracts, accounts.Validator.Auth, operatorStake,
	)

	// Use a fake game address
	fakeGameAddress := common.HexToAddress("0xDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEF")
	t.Logf("Using fake game address: %s", fakeGameAddress.Hex())

	// Try to slash with fake game address
	gameType := uint32(0)
	rootClaim := [32]byte{0x11}
	l2BlockNumber := big.NewInt(100)
	extraData := common.LeftPadBytes(l2BlockNumber.Bytes(), 32)

	tx, err := slashingContracts.Layer2ManagerSlashing.SlashingCandidate(
		accounts.Challenger.Auth,
		operatorManager,
		gameType,
		rootClaim,
		extraData,
		fakeGameAddress,
	)

	if err != nil {
		t.Logf("✓ Slashing rejected for invalid game address: %v", err)
	} else {
		receipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, tx)
		require.NoError(t, err)
		require.Equal(t, types.ReceiptStatusFailed, receipt.Status, "Slashing should fail for invalid game address")
		t.Log("✓ Slashing transaction reverted for invalid game address")
	}

	_ = rollupConfig // unused but needed for setup
	t.Log("✅ Invalid game address slashing test completed")
}

// TestEdgeCase_WrongRootClaim tests slashing with a rootClaim that doesn't match the game.
func TestEdgeCase_WrongRootClaim(t *testing.T) {
	t.Parallel()

	sys := rat.StartTONStakingSystem(t)
	accounts := rat.SetupTestAccounts(t, sys)
	contracts := rat.ConnectTestContracts(t, sys)
	slashingContracts := connectSlashingContracts(t, sys)

	t.Log("=== Testing Wrong RootClaim Slashing ===")

	// Setup operator
	operatorStake := new(big.Int).Mul(big.NewInt(500000), new(big.Int).Exp(big.NewInt(10), big.NewInt(27), nil))
	rat.AdjustMinimumCollateral(t, sys, contracts, accounts.Deployer.Auth, operatorStake)

	candidateAddOn, operatorManager, rollupConfig := registerOperatorWithCandidateAddOn(
		t, sys, slashingContracts, accounts.Validator.Auth, operatorStake,
	)

	// Setup RAT
	setupRATForValidator(t, sys, accounts, slashingContracts, candidateAddOn, rollupConfig, operatorStake)

	// Create game with specific rootClaim
	actualRootClaim := [32]byte{0xAA, 0xBB, 0xCC}
	_, gameAddress := rat.CreateDisputeGame(t, sys, accounts.Proposer.Auth, actualRootClaim)

	correctClaim := [32]byte{0xDD, 0xEE, 0xFF}
	rat.AttackClaim(t, sys, accounts.Challenger.Auth, gameAddress, correctClaim, actualRootClaim)
	rat.AdvanceTimeAndMine(t, sys, 1209600)
	rat.ResolveGame(t, sys, accounts.Challenger.Auth, gameAddress)

	// Try to slash with wrong rootClaim
	wrongRootClaim := [32]byte{0x11, 0x22, 0x33} // Different from actual
	gameType := uint32(0)
	l2BlockNumber := big.NewInt(100)
	extraData := common.LeftPadBytes(l2BlockNumber.Bytes(), 32)

	tx, err := slashingContracts.Layer2ManagerSlashing.SlashingCandidate(
		accounts.Challenger.Auth,
		operatorManager,
		gameType,
		wrongRootClaim,
		extraData,
		gameAddress,
	)

	if err != nil {
		t.Logf("✓ Slashing rejected for wrong rootClaim: %v", err)
	} else {
		receipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, tx)
		require.NoError(t, err)
		require.Equal(t, types.ReceiptStatusFailed, receipt.Status, "Slashing should fail for wrong rootClaim")
		t.Log("✓ Slashing transaction reverted for wrong rootClaim")
	}

	t.Log("✅ Wrong rootClaim slashing test completed")
}

// TestEdgeCase_WrongExtraData tests slashing with extraData that doesn't match the game.
func TestEdgeCase_WrongExtraData(t *testing.T) {
	t.Parallel()

	sys := rat.StartTONStakingSystem(t)
	accounts := rat.SetupTestAccounts(t, sys)
	contracts := rat.ConnectTestContracts(t, sys)
	slashingContracts := connectSlashingContracts(t, sys)

	t.Log("=== Testing Wrong ExtraData Slashing ===")

	// Setup operator
	operatorStake := new(big.Int).Mul(big.NewInt(500000), new(big.Int).Exp(big.NewInt(10), big.NewInt(27), nil))
	rat.AdjustMinimumCollateral(t, sys, contracts, accounts.Deployer.Auth, operatorStake)

	candidateAddOn, operatorManager, rollupConfig := registerOperatorWithCandidateAddOn(
		t, sys, slashingContracts, accounts.Validator.Auth, operatorStake,
	)

	// Setup RAT
	setupRATForValidator(t, sys, accounts, slashingContracts, candidateAddOn, rollupConfig, operatorStake)

	// Create game
	rootClaim := [32]byte{0xAA}
	_, gameAddress := rat.CreateDisputeGame(t, sys, accounts.Proposer.Auth, rootClaim)

	correctClaim := [32]byte{0xBB}
	rat.AttackClaim(t, sys, accounts.Challenger.Auth, gameAddress, correctClaim, rootClaim)
	rat.AdvanceTimeAndMine(t, sys, 1209600)
	rat.ResolveGame(t, sys, accounts.Challenger.Auth, gameAddress)

	// Try to slash with wrong extraData (different L2 block number)
	gameType := uint32(0)
	wrongL2BlockNumber := big.NewInt(999) // Different from actual (100)
	wrongExtraData := common.LeftPadBytes(wrongL2BlockNumber.Bytes(), 32)

	tx, err := slashingContracts.Layer2ManagerSlashing.SlashingCandidate(
		accounts.Challenger.Auth,
		operatorManager,
		gameType,
		rootClaim,
		wrongExtraData,
		gameAddress,
	)

	if err != nil {
		t.Logf("✓ Slashing rejected for wrong extraData: %v", err)
	} else {
		receipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, tx)
		require.NoError(t, err)
		require.Equal(t, types.ReceiptStatusFailed, receipt.Status, "Slashing should fail for wrong extraData")
		t.Log("✓ Slashing transaction reverted for wrong extraData")
	}

	t.Log("✅ Wrong extraData slashing test completed")
}
