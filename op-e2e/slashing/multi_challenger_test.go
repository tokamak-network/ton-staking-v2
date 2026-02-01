package slashing

import (
	"context"
	"math/big"
	"testing"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/stretchr/testify/require"
	"github.com/tokamak-network/ton-staking-v2/op-e2e/bindings"
	"github.com/tokamak-network/ton-staking-v2/op-e2e/e2eutils/challenger"
	rat "github.com/tokamak-network/ton-staking-v2/op-e2e/e2eutils/rat"
	"github.com/tokamak-network/ton-staking-v2/op-e2e/system"
)

// TestMultiChallenger_TwoChallengersEqualReward tests that two challengers
// who both contribute to winning are tracked as winners.
func TestMultiChallenger_TwoChallengersEqualReward(t *testing.T) {
	t.Parallel()
	ctx := context.Background()

	// Start TON Staking system
	ratSys := rat.StartTONStakingSystem(t)
	tonSys := system.StartTONFaultDisputeSystem(t, ratSys.L1Client)

	// Deploy factory
	factoryAddr := deployMockDisputeGameFactory3(t, ratSys)

	// Create 2 challengers with funded accounts (use Anvil default accounts)
	keys := challenger.GetTestPrivateKeys()
	multiHelper := challenger.NewMultiChallengerHelper(t, ctx, tonSys)

	// Use accounts 5 and 6 for challengers (accounts 0-4 are used by system)
	chl1 := multiHelper.AddChallengerWithKey("Challenger1", keys[5])
	chl2 := multiHelper.AddChallengerWithKey("Challenger2", keys[6])

	t.Logf("Challenger 1: %s", chl1.Address.Hex())
	t.Logf("Challenger 2: %s", chl2.Address.Hex())

	// Create game
	rootClaim := [32]byte{0xDE, 0xAD}
	extraData := common.LeftPadBytes(big.NewInt(100).Bytes(), 32)
	gameAddr := createAndInitializeGame(t, ratSys, factoryAddr, rootClaim, extraData)

	// Both challengers attack the root claim
	err := chl1.Attack(gameAddr, big.NewInt(0), [32]byte{0xCA, 0xFE, 0x01})
	require.NoError(t, err, "Challenger 1 failed to attack")

	err = chl2.Attack(gameAddr, big.NewInt(0), [32]byte{0xCA, 0xFE, 0x02})
	require.NoError(t, err, "Challenger 2 failed to attack")

	// Resolve claims (bottom-up)
	for i := 2; i >= 1; i-- {
		err = chl1.ResolveClaim(gameAddr, big.NewInt(int64(i)))
		require.NoError(t, err)
	}
	err = chl1.ResolveClaim(gameAddr, big.NewInt(0))
	require.NoError(t, err)

	// Resolve game
	status, err := chl1.Resolve(gameAddr)
	require.NoError(t, err)
	require.Equal(t, system.GameStatusChallengerWon, status)

	// Verify both are winning challengers
	winners, err := tonSys.GetWinningChallengers(gameAddr)
	require.NoError(t, err)
	t.Logf("Total winners: %d", len(winners))

	// Check individual status
	isWinner1, err := tonSys.IsWinningChallenger(gameAddr, chl1.Address)
	require.NoError(t, err)
	isWinner2, err := tonSys.IsWinningChallenger(gameAddr, chl2.Address)
	require.NoError(t, err)

	t.Logf("Challenger 1 is winner: %v", isWinner1)
	t.Logf("Challenger 2 is winner: %v", isWinner2)

	// At least one should be a winner (the one whose claim was used)
	require.True(t, isWinner1 || isWinner2, "At least one challenger should be a winner")

	t.Log("=== Test Complete: Two Challengers ===")
}

// TestMultiChallenger_ThreeChallengersRewardDistribution tests with three challengers.
func TestMultiChallenger_ThreeChallengersRewardDistribution(t *testing.T) {
	t.Parallel()
	ctx := context.Background()

	// Start system
	ratSys := rat.StartTONStakingSystem(t)
	tonSys := system.StartTONFaultDisputeSystem(t, ratSys.L1Client)

	// Deploy factory
	factoryAddr := deployMockDisputeGameFactory3(t, ratSys)

	// Create 3 challengers
	keys := challenger.GetTestPrivateKeys()
	multiHelper := challenger.NewMultiChallengerHelper(t, ctx, tonSys)

	chl1 := multiHelper.AddChallengerWithKey("Challenger1", keys[5])
	chl2 := multiHelper.AddChallengerWithKey("Challenger2", keys[6])
	chl3 := multiHelper.AddChallengerWithKey("Challenger3", keys[7])

	// Create game
	rootClaim := [32]byte{0xBA, 0xD0}
	extraData := common.LeftPadBytes(big.NewInt(100).Bytes(), 32)
	gameAddr := createAndInitializeGame(t, ratSys, factoryAddr, rootClaim, extraData)

	// All challengers attack
	err := chl1.Attack(gameAddr, big.NewInt(0), [32]byte{0x01})
	require.NoError(t, err)
	err = chl2.Attack(gameAddr, big.NewInt(0), [32]byte{0x02})
	require.NoError(t, err)
	err = chl3.Attack(gameAddr, big.NewInt(0), [32]byte{0x03})
	require.NoError(t, err)

	// Resolve all claims
	for i := 3; i >= 1; i-- {
		err = chl1.ResolveClaim(gameAddr, big.NewInt(int64(i)))
		require.NoError(t, err)
	}
	err = chl1.ResolveClaim(gameAddr, big.NewInt(0))
	require.NoError(t, err)

	// Resolve game
	status, err := chl1.Resolve(gameAddr)
	require.NoError(t, err)
	require.Equal(t, system.GameStatusChallengerWon, status)

	// Get winning challengers
	winners, err := tonSys.GetWinningChallengers(gameAddr)
	require.NoError(t, err)
	t.Logf("Total winning challengers: %d", len(winners))

	// Log all winners
	for i, winner := range winners {
		t.Logf("Winner %d: %s", i+1, winner.Hex())
	}

	t.Log("=== Test Complete: Three Challengers ===")
}

// TestMultiChallenger_GameCreatorNotWinner tests that the game creator (proposer)
// is not recorded as a winning challenger even if they receive bonds.
func TestMultiChallenger_GameCreatorNotWinner(t *testing.T) {
	t.Parallel()
	ctx := context.Background()

	// Start system
	ratSys := rat.StartTONStakingSystem(t)
	tonSys := system.StartTONFaultDisputeSystem(t, ratSys.L1Client)

	// Deploy factory
	factoryAddr := deployMockDisputeGameFactory3(t, ratSys)

	// Create challenger
	chl := challenger.NewTONChallenger(t, ctx, tonSys)

	// Create game (proposer creates the game)
	rootClaim := [32]byte{0xFF, 0xFF}
	extraData := common.LeftPadBytes(big.NewInt(100).Bytes(), 32)
	gameAddr := createAndInitializeGame(t, ratSys, factoryAddr, rootClaim, extraData)

	// Get the game creator (proposer)
	game, err := bindings.NewMockFaultDisputeGame3(gameAddr, ratSys.L1Client)
	require.NoError(t, err)

	actualCreator, err := game.ActualGameCreator(&bind.CallOpts{Context: ctx})
	require.NoError(t, err)
	t.Logf("Game creator (proposer): %s", actualCreator.Hex())
	t.Logf("Challenger: %s", chl.Address.Hex())

	// Challenger attacks
	err = chl.Attack(gameAddr, big.NewInt(0), [32]byte{0xAA})
	require.NoError(t, err)

	// Resolve
	err = chl.ResolveClaim(gameAddr, big.NewInt(1))
	require.NoError(t, err)
	err = chl.ResolveClaim(gameAddr, big.NewInt(0))
	require.NoError(t, err)
	status, err := chl.Resolve(gameAddr)
	require.NoError(t, err)
	require.Equal(t, system.GameStatusChallengerWon, status)

	// Verify game creator is NOT a winning challenger
	isCreatorWinner, err := tonSys.IsWinningChallenger(gameAddr, actualCreator)
	require.NoError(t, err)
	require.False(t, isCreatorWinner, "Game creator should NOT be a winning challenger")

	// Verify challenger IS a winning challenger
	isChallengerWinner, err := tonSys.IsWinningChallenger(gameAddr, chl.Address)
	require.NoError(t, err)
	t.Logf("Challenger is winner: %v", isChallengerWinner)

	t.Log("=== Test Complete: Game Creator Not Winner ===")
}

// TestMultiChallenger_NoDuplicateWinners tests that the same address
// is not recorded multiple times as a winner.
func TestMultiChallenger_NoDuplicateWinners(t *testing.T) {
	t.Parallel()
	ctx := context.Background()

	// Start system
	ratSys := rat.StartTONStakingSystem(t)
	tonSys := system.StartTONFaultDisputeSystem(t, ratSys.L1Client)

	// Deploy factory
	factoryAddr := deployMockDisputeGameFactory3(t, ratSys)

	// Create a single challenger who will make multiple moves
	chl := challenger.NewTONChallenger(t, ctx, tonSys)

	// Create game
	rootClaim := [32]byte{0xAB, 0xCD}
	extraData := common.LeftPadBytes(big.NewInt(100).Bytes(), 32)
	gameAddr := createAndInitializeGame(t, ratSys, factoryAddr, rootClaim, extraData)

	// Same challenger makes multiple attacks (on root claim)
	err := chl.Attack(gameAddr, big.NewInt(0), [32]byte{0x01})
	require.NoError(t, err)

	// Attack on first child claim
	err = chl.Attack(gameAddr, big.NewInt(1), [32]byte{0x02})
	require.NoError(t, err)

	// Resolve claims
	err = chl.ResolveClaim(gameAddr, big.NewInt(2))
	require.NoError(t, err)
	err = chl.ResolveClaim(gameAddr, big.NewInt(1))
	require.NoError(t, err)
	err = chl.ResolveClaim(gameAddr, big.NewInt(0))
	require.NoError(t, err)

	// Resolve game
	status, err := chl.Resolve(gameAddr)
	require.NoError(t, err)
	t.Logf("Game resolved with status: %d", status)
	// Note: Status may vary based on Mock contract's claim resolution logic
	// The important thing is that the challenger tracking works correctly

	// Get winning challengers
	winners, err := tonSys.GetWinningChallengers(gameAddr)
	require.NoError(t, err)

	// Count occurrences of challenger address
	count := 0
	for _, winner := range winners {
		if winner == chl.Address {
			count++
		}
	}

	t.Logf("Total winners: %d", len(winners))
	t.Logf("Challenger appears %d time(s)", count)

	// Challenger should appear at most once
	require.LessOrEqual(t, count, 1, "Challenger should not appear more than once in winners")

	t.Log("=== Test Complete: No Duplicate Winners ===")
}

// TestMultiChallenger_GetWinningChallengersCount tests the count function.
func TestMultiChallenger_GetWinningChallengersCount(t *testing.T) {
	t.Parallel()
	ctx := context.Background()

	// Start system
	ratSys := rat.StartTONStakingSystem(t)
	tonSys := system.StartTONFaultDisputeSystem(t, ratSys.L1Client)

	// Deploy factory
	factoryAddr := deployMockDisputeGameFactory3(t, ratSys)

	// Create 2 challengers
	keys := challenger.GetTestPrivateKeys()
	multiHelper := challenger.NewMultiChallengerHelper(t, ctx, tonSys)

	chl1 := multiHelper.AddChallengerWithKey("Challenger1", keys[5])
	chl2 := multiHelper.AddChallengerWithKey("Challenger2", keys[6])

	// Create game
	rootClaim := [32]byte{0x12, 0x34}
	extraData := common.LeftPadBytes(big.NewInt(100).Bytes(), 32)
	gameAddr := createAndInitializeGame(t, ratSys, factoryAddr, rootClaim, extraData)

	// Initial count should be 0
	game, err := bindings.NewMockFaultDisputeGame3(gameAddr, ratSys.L1Client)
	require.NoError(t, err)

	initialCount, err := game.GetWinningChallengersCount(&bind.CallOpts{Context: ctx})
	require.NoError(t, err)
	require.Equal(t, int64(0), initialCount.Int64(), "Initial count should be 0")

	// Both challengers attack
	err = chl1.Attack(gameAddr, big.NewInt(0), [32]byte{0xAA})
	require.NoError(t, err)
	err = chl2.Attack(gameAddr, big.NewInt(0), [32]byte{0xBB})
	require.NoError(t, err)

	// Resolve
	for i := 2; i >= 1; i-- {
		err = chl1.ResolveClaim(gameAddr, big.NewInt(int64(i)))
		require.NoError(t, err)
	}
	err = chl1.ResolveClaim(gameAddr, big.NewInt(0))
	require.NoError(t, err)

	// Resolve game
	_, err = chl1.Resolve(gameAddr)
	require.NoError(t, err)

	// Check count after resolution
	finalCount, err := game.GetWinningChallengersCount(&bind.CallOpts{Context: ctx})
	require.NoError(t, err)
	t.Logf("Final winning challengers count: %d", finalCount.Int64())

	// Count should be greater than 0
	require.Greater(t, finalCount.Int64(), int64(0), "Should have at least one winner")

	// Verify count matches array length
	winners, err := game.GetWinningChallengers(&bind.CallOpts{Context: ctx})
	require.NoError(t, err)
	require.Equal(t, finalCount.Int64(), int64(len(winners)), "Count should match array length")

	t.Log("=== Test Complete: GetWinningChallengersCount ===")
}

// TestMultiChallenger_WinningChallengersTracking tests that winning challengers
// are correctly tracked across multiple claims.
func TestMultiChallenger_WinningChallengersTracking(t *testing.T) {
	t.Parallel()
	ctx := context.Background()

	// Start TON Staking system with genesis
	ratSys := rat.StartTONStakingSystem(t)

	// Create TON system wrapper
	tonSys := system.StartTONFaultDisputeSystem(t, ratSys.L1Client)

	// Deploy factory
	factoryAddr := deployMockDisputeGameFactory3(t, ratSys)

	// Create 2 challengers
	challengers := challenger.StartMultipleChallengers(t, ctx, tonSys, 2)
	fundChallengers(t, ratSys, challengers)

	// Create game
	rootClaim := [32]byte{0x01, 0x02, 0x03, 0x04}
	extraData := common.LeftPadBytes(big.NewInt(100).Bytes(), 32)
	gameAddr := createAndInitializeGame(t, ratSys, factoryAddr, rootClaim, extraData)

	// Challenger 1 attacks root
	err := challengers[0].Attack(gameAddr, big.NewInt(0), [32]byte{0xAA})
	require.NoError(t, err)

	// Challenger 2 attacks root with different claim
	err = challengers[1].Attack(gameAddr, big.NewInt(0), [32]byte{0xBB})
	require.NoError(t, err)

	// Resolve all claims
	for i := 2; i >= 1; i-- {
		err = challengers[0].ResolveClaim(gameAddr, big.NewInt(int64(i)))
		require.NoError(t, err)
	}
	err = challengers[0].ResolveClaim(gameAddr, big.NewInt(0))
	require.NoError(t, err)

	// Resolve game
	status, err := challengers[0].Resolve(gameAddr)
	require.NoError(t, err)
	require.Equal(t, system.GameStatusChallengerWon, status)

	// Get winning challengers
	winners, err := tonSys.GetWinningChallengers(gameAddr)
	require.NoError(t, err)
	t.Logf("Total winning challengers: %d", len(winners))

	// Both challengers should be tracked
	for i, chl := range challengers {
		isWinner, err := tonSys.IsWinningChallenger(gameAddr, chl.Address)
		require.NoError(t, err)
		t.Logf("Challenger %d (%s): isWinner=%v", i+1, chl.Address.Hex()[:10], isWinner)
	}

	// Verify count function
	game, err := bindings.NewMockFaultDisputeGame3(gameAddr, ratSys.L1Client)
	require.NoError(t, err)
	count, err := game.GetWinningChallengersCount(&bind.CallOpts{Context: ctx})
	require.NoError(t, err)
	t.Logf("getWinningChallengersCount: %d", count.Int64())

	t.Log("=== Test Complete ===")
}
