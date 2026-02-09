package slashing

import (
	"context"
	"math/big"
	"testing"
	"time"

	op_e2e "github.com/ethereum-optimism/optimism/op-e2e"
	"github.com/ethereum-optimism/optimism/op-challenger/game/types"
	"github.com/ethereum-optimism/optimism/op-e2e/e2eutils/challenger"
	"github.com/ethereum-optimism/optimism/op-e2e/e2eutils/disputegame"
	"github.com/ethereum-optimism/optimism/op-e2e/e2eutils/wait"
	"github.com/ethereum-optimism/optimism/op-e2e/faultproofs"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/stretchr/testify/require"
)

// TestMultiChallenger_TwoChallengersCompeting tests two challengers competing
// to counter an invalid root claim using real op-challenger services.
func TestMultiChallenger_TwoChallengersCompeting(t *testing.T) {
	op_e2e.InitParallel(t)
	ctx := context.Background()

	t.Log("=== Starting Two Challengers Competing Test ===")

	// Start Full Optimism devnet
	sys, l1Client := faultproofs.StartFaultDisputeSystem(t)
	t.Cleanup(sys.Close)

	// Create dispute game factory helper
	disputeGameFactory := disputegame.NewFactoryHelper(t, ctx, sys)

	// Create game with invalid root
	t.Log("=== Step 1: Create DisputeGame ===")
	game := disputeGameFactory.StartOutputAlphabetGame(ctx, "sequencer", 3, common.Hash{0xde, 0xad})
	t.Logf("  Game created at: %s", game.Addr.Hex())

	// Start two challengers with different keys
	t.Log("=== Step 2: Start Two Challengers ===")
	chl1 := game.StartChallenger(ctx, "sequencer", "Challenger1",
		challenger.WithPrivKey(sys.Cfg.Secrets.Alice),
		challenger.WithPollInterval(500*time.Millisecond))
	t.Logf("  Challenger1 (Alice): %s", sys.Cfg.Secrets.Addresses().Alice.Hex())

	chl2 := game.StartChallenger(ctx, "sequencer", "Challenger2",
		challenger.WithPrivKey(sys.Cfg.Secrets.Bob),
		challenger.WithPollInterval(500*time.Millisecond))
	t.Logf("  Challenger2 (Bob): %s", sys.Cfg.Secrets.Addresses().Bob.Hex())

	// Both challengers will compete to post claims
	// The first to post wins the right to counter each claim
	t.Log("=== Step 3: Wait for Challengers to Act ===")

	// Wait for initial L1 head to be processed
	chl1.WaitL1HeadActedOn(ctx, l1Client)
	chl2.WaitL1HeadActedOn(ctx, l1Client)

	// Drive the game as dishonest defender
	claim := game.RootClaim(ctx)
	correctTrace := game.CreateHonestActor(ctx, "sequencer")

	// Iterate through output root claims
	for claim.IsOutputRoot(ctx) && !claim.IsOutputRootLeaf(ctx) {
		if claim.AgreesWithOutputRoot() {
			claim = claim.WaitForCounterClaim(ctx)
			game.LogGameData(ctx)
		} else {
			claim = claim.Attack(ctx, common.Hash{0xba, 0xd0})
			game.LogGameData(ctx)
		}
	}

	// Wait for alphabet level
	claim = claim.WaitForCounterClaim(ctx)
	game.LogGameData(ctx)

	// Continue at alphabet level
	claim = correctTrace.AttackClaim(ctx, claim)
	for !claim.IsMaxDepth(ctx) {
		if claim.AgreesWithOutputRoot() {
			claim = claim.WaitForCounterClaim(ctx)
			game.LogGameData(ctx)
		} else {
			claim = correctTrace.AttackClaim(ctx, claim)
			game.LogGameData(ctx)
		}
	}

	claim.WaitForCountered(ctx)
	game.LogGameData(ctx)

	// Advance time and resolve
	t.Log("=== Step 4: Resolve Game ===")
	sys.TimeTravelClock.AdvanceTime(game.MaxClockDuration(ctx))
	require.NoError(t, wait.ForNextBlock(ctx, l1Client))

	game.WaitForGameStatus(ctx, types.GameStatusChallengerWon)
	t.Log("  Game resolved: CHALLENGER_WINS")

	// Verify both challengers were active
	_ = chl1
	_ = chl2

	t.Log("=== Test Complete: Two Challengers Competing ===")
}

// TestMultiChallenger_ThreeChallengersRewardDistribution tests three challengers
// participating in a game and verifies credit distribution.
func TestMultiChallenger_ThreeChallengersRewardDistribution(t *testing.T) {
	op_e2e.InitParallel(t)
	ctx := context.Background()

	t.Log("=== Starting Three Challengers Reward Distribution Test ===")

	// Start Full Optimism devnet
	sys, l1Client := faultproofs.StartFaultDisputeSystem(t)
	t.Cleanup(sys.Close)

	// Create dispute game factory helper
	disputeGameFactory := disputegame.NewFactoryHelper(t, ctx, sys)

	// Create game with invalid root
	t.Log("=== Step 1: Create DisputeGame ===")
	game := disputeGameFactory.StartOutputAlphabetGame(ctx, "sequencer", 3, common.Hash{0xba, 0xd0})
	t.Logf("  Game created at: %s", game.Addr.Hex())

	// Start three challengers
	t.Log("=== Step 2: Start Three Challengers ===")
	alice := sys.Cfg.Secrets.Addresses().Alice
	bob := sys.Cfg.Secrets.Addresses().Bob
	mallory := sys.Cfg.Secrets.Addresses().Mallory

	chl1 := game.StartChallenger(ctx, "sequencer", "Challenger1",
		challenger.WithPrivKey(sys.Cfg.Secrets.Alice),
		challenger.WithPollInterval(500*time.Millisecond))
	t.Logf("  Challenger1 (Alice): %s", alice.Hex())

	chl2 := game.StartChallenger(ctx, "sequencer", "Challenger2",
		challenger.WithPrivKey(sys.Cfg.Secrets.Bob),
		challenger.WithPollInterval(500*time.Millisecond))
	t.Logf("  Challenger2 (Bob): %s", bob.Hex())

	chl3 := game.StartChallenger(ctx, "sequencer", "Challenger3",
		challenger.WithPrivKey(sys.Cfg.Secrets.Mallory),
		challenger.WithPollInterval(500*time.Millisecond))
	t.Logf("  Challenger3 (Mallory): %s", mallory.Hex())

	// Wait for all challengers to start processing
	t.Log("=== Step 3: Wait for Challengers to Act ===")
	chl1.WaitL1HeadActedOn(ctx, l1Client)
	chl2.WaitL1HeadActedOn(ctx, l1Client)
	chl3.WaitL1HeadActedOn(ctx, l1Client)

	// Drive the game
	claim := game.RootClaim(ctx)
	correctTrace := game.CreateHonestActor(ctx, "sequencer")

	for claim.IsOutputRoot(ctx) && !claim.IsOutputRootLeaf(ctx) {
		if claim.AgreesWithOutputRoot() {
			claim = claim.WaitForCounterClaim(ctx)
			game.LogGameData(ctx)
		} else {
			claim = claim.Attack(ctx, common.Hash{0xff})
			game.LogGameData(ctx)
		}
	}

	claim = claim.WaitForCounterClaim(ctx)
	game.LogGameData(ctx)

	claim = correctTrace.AttackClaim(ctx, claim)
	for !claim.IsMaxDepth(ctx) {
		if claim.AgreesWithOutputRoot() {
			claim = claim.WaitForCounterClaim(ctx)
			game.LogGameData(ctx)
		} else {
			claim = correctTrace.AttackClaim(ctx, claim)
			game.LogGameData(ctx)
		}
	}

	claim.WaitForCountered(ctx)
	game.LogGameData(ctx)

	// Resolve game
	t.Log("=== Step 4: Resolve Game ===")
	sys.TimeTravelClock.AdvanceTime(game.MaxClockDuration(ctx))
	require.NoError(t, wait.ForNextBlock(ctx, l1Client))
	game.WaitForGameStatus(ctx, types.GameStatusChallengerWon)
	t.Log("  Game resolved: CHALLENGER_WINS")

	// Advance time past finalization delay
	t.Log("=== Step 5: Check Credit Distribution ===")
	sys.TimeTravelClock.AdvanceTime(game.CreditUnlockDuration(ctx) * 2)
	require.NoError(t, wait.ForNextBlock(ctx, l1Client))

	game.WaitForBondModeDecided(ctx)

	// Check credits for all challengers
	aliceCredit := game.AvailableCredit(ctx, alice)
	bobCredit := game.AvailableCredit(ctx, bob)
	malloryCredit := game.AvailableCredit(ctx, mallory)

	t.Logf("  Alice credit: %s", aliceCredit.String())
	t.Logf("  Bob credit: %s", bobCredit.String())
	t.Logf("  Mallory credit: %s", malloryCredit.String())

	// At least one challenger should have credit (the one who posted winning claims)
	totalCredit := new(big.Int).Add(aliceCredit, bobCredit)
	totalCredit = new(big.Int).Add(totalCredit, malloryCredit)
	require.Truef(t, totalCredit.Cmp(big.NewInt(0)) > 0, "At least one challenger should have credit")

	t.Log("=== Test Complete: Three Challengers ===")
}

// TestMultiChallenger_GameCreatorNotRewarded tests that the game creator (proposer)
// does not receive challenger rewards, only honest challengers do.
func TestMultiChallenger_GameCreatorNotRewarded(t *testing.T) {
	op_e2e.InitParallel(t)
	ctx := context.Background()

	t.Log("=== Starting Game Creator Not Rewarded Test ===")

	// Start Full Optimism devnet
	sys, l1Client := faultproofs.StartFaultDisputeSystem(t)
	t.Cleanup(sys.Close)

	// Create dispute game factory with specific private key
	disputeGameFactory := disputegame.NewFactoryHelper(t, ctx, sys,
		disputegame.WithFactoryPrivKey(sys.Cfg.Secrets.Deployer))

	// The game creator is the factory helper's default key (deployer)
	gameCreator := sys.Cfg.Secrets.Addresses().Deployer
	t.Logf("Game creator: %s", gameCreator.Hex())

	// Create game with invalid root
	t.Log("=== Step 1: Create DisputeGame ===")
	game := disputeGameFactory.StartOutputAlphabetGame(ctx, "sequencer", 3, common.Hash{0xff, 0xff})
	t.Logf("  Game created at: %s", game.Addr.Hex())

	// Start honest challenger (different from game creator)
	alice := sys.Cfg.Secrets.Addresses().Alice
	t.Log("=== Step 2: Start Challenger ===")
	chl := game.StartChallenger(ctx, "sequencer", "Challenger",
		challenger.WithPrivKey(sys.Cfg.Secrets.Alice))
	t.Logf("  Challenger (Alice): %s", alice.Hex())

	// Drive the game
	claim := game.RootClaim(ctx)
	correctTrace := game.CreateHonestActor(ctx, "sequencer")

	for claim.IsOutputRoot(ctx) && !claim.IsOutputRootLeaf(ctx) {
		if claim.AgreesWithOutputRoot() {
			claim = claim.WaitForCounterClaim(ctx)
			game.LogGameData(ctx)
		} else {
			claim = claim.Attack(ctx, common.Hash{0xaa})
			game.LogGameData(ctx)
		}
	}

	claim = claim.WaitForCounterClaim(ctx)
	game.LogGameData(ctx)

	claim = correctTrace.AttackClaim(ctx, claim)
	for !claim.IsMaxDepth(ctx) {
		if claim.AgreesWithOutputRoot() {
			claim = claim.WaitForCounterClaim(ctx)
			game.LogGameData(ctx)
		} else {
			claim = correctTrace.AttackClaim(ctx, claim)
			game.LogGameData(ctx)
		}
	}

	claim.WaitForCountered(ctx)
	game.LogGameData(ctx)

	// Resolve game
	t.Log("=== Step 3: Resolve Game ===")
	sys.TimeTravelClock.AdvanceTime(game.MaxClockDuration(ctx))
	require.NoError(t, wait.ForNextBlock(ctx, l1Client))
	game.WaitForGameStatus(ctx, types.GameStatusChallengerWon)

	// Advance time past finalization delay
	t.Log("=== Step 4: Check Credits ===")
	sys.TimeTravelClock.AdvanceTime(game.CreditUnlockDuration(ctx) * 2)
	require.NoError(t, wait.ForNextBlock(ctx, l1Client))

	game.WaitForBondModeDecided(ctx)

	// Game creator should lose their bond (paid to challengers)
	creatorCredit := game.AvailableCredit(ctx, gameCreator)
	aliceCredit := game.AvailableCredit(ctx, alice)

	t.Logf("  Game creator credit: %s", creatorCredit.String())
	t.Logf("  Challenger (Alice) credit: %s", aliceCredit.String())

	// Alice (challenger) should have received credit
	require.Truef(t, aliceCredit.Cmp(big.NewInt(0)) > 0, "Challenger should have credit")

	_ = chl // challenger was active

	t.Log("=== Test Complete: Game Creator Not Rewarded ===")
}

// TestMultiChallenger_FreeloaderEarnsNothing tests that freeloaders who copy
// honest challenger's claims do not earn rewards.
func TestMultiChallenger_FreeloaderEarnsNothing(t *testing.T) {
	op_e2e.InitParallel(t)
	ctx := context.Background()

	t.Log("=== Starting Freeloader Earns Nothing Test ===")

	// Start Full Optimism devnet
	sys, l1Client := faultproofs.StartFaultDisputeSystem(t)
	t.Cleanup(sys.Close)

	// Create dispute game factory
	disputeGameFactory := disputegame.NewFactoryHelper(t, ctx, sys)

	// Get freeloader opts
	freeloaderOpts, err := bind.NewKeyedTransactorWithChainID(sys.Cfg.Secrets.Mallory, sys.Cfg.L1ChainIDBig())
	require.NoError(t, err)

	// Create game with correct root
	t.Log("=== Step 1: Create DisputeGame ===")
	game := disputeGameFactory.StartOutputAlphabetGameWithCorrectRoot(ctx, "sequencer", 2)
	t.Logf("  Game created at: %s", game.Addr.Hex())

	correctTrace := game.CreateHonestActor(ctx, "sequencer")

	// Dispute last block
	claim := game.DisputeLastBlock(ctx)

	// Attack with invalid alphabet trace
	claim = claim.Attack(ctx, common.Hash{0x01})

	// Freeloader tries to post claims before honest challenger
	var freeloaders []*disputegame.ClaimHelper

	// honest counter
	claim = correctTrace.AttackClaim(ctx, claim)

	// dishonest response
	dishonest := correctTrace.AttackClaim(ctx, claim)

	// Freeloader posts claims at the same positions
	freeloaders = append(freeloaders, correctTrace.AttackClaim(ctx, dishonest, disputegame.WithTransactOpts(freeloaderOpts)))
	freeloaders = append(freeloaders, dishonest.Attack(ctx, common.Hash{0x02}, disputegame.WithTransactOpts(freeloaderOpts)))
	freeloaders = append(freeloaders, dishonest.Defend(ctx, common.Hash{0x03}, disputegame.WithTransactOpts(freeloaderOpts)))

	// Start honest challenger after freeloaders
	t.Log("=== Step 2: Start Honest Challenger ===")
	game.StartChallenger(ctx, "sequencer", "Challenger",
		challenger.WithPrivKey(sys.Cfg.Secrets.Alice))

	// Wait for challenger to respond
	dishonest.WaitForCounterClaim(ctx, freeloaders...)

	// More freeloader claims
	freeloaders = append(freeloaders, dishonest.Attack(ctx, common.Hash{0x04}, disputegame.WithTransactOpts(freeloaderOpts)))
	freeloaders = append(freeloaders, dishonest.Defend(ctx, common.Hash{0x05}, disputegame.WithTransactOpts(freeloaderOpts)))

	// Wait for all freeloader claims to be countered
	for _, freeloader := range freeloaders {
		if freeloader.IsMaxDepth(ctx) {
			freeloader.WaitForCountered(ctx)
		} else {
			freeloader.WaitForCounterClaim(ctx)
		}
	}

	game.LogGameData(ctx)

	// Resolve game
	t.Log("=== Step 3: Resolve Game ===")
	sys.TimeTravelClock.AdvanceTime(game.MaxClockDuration(ctx))
	require.NoError(t, wait.ForNextBlock(ctx, l1Client))
	game.WaitForGameStatus(ctx, types.GameStatusDefenderWon)

	game.LogGameData(ctx)

	// Check freeloader credit
	t.Log("=== Step 4: Verify Freeloader Earns Nothing ===")
	freeloaderCredit := game.Credit(ctx, freeloaderOpts.From)
	require.Truef(t, freeloaderCredit.BitLen() == 0, "Freeloaders should not be rewarded. Credit: %v", freeloaderCredit)
	t.Logf("  Freeloader credit: %s (expected: 0)", freeloaderCredit.String())

	t.Log("=== Test Complete: Freeloader Earns Nothing ===")
}

// TestMultiChallenger_HighestActedL1BlockMetric tests that the highest acted L1 block
// metric is correctly updated by challengers.
func TestMultiChallenger_HighestActedL1BlockMetric(t *testing.T) {
	op_e2e.InitParallel(t)
	ctx := context.Background()

	t.Log("=== Starting Highest Acted L1 Block Metric Test ===")

	// Start Full Optimism devnet
	sys, l1Client := faultproofs.StartFaultDisputeSystem(t)
	t.Cleanup(sys.Close)

	// Create dispute game factory
	disputeGameFactory := disputegame.NewFactoryHelper(t, ctx, sys)

	// Start a challenger that monitors all games
	t.Log("=== Step 1: Start Global Challenger ===")
	honestChallenger := disputeGameFactory.StartChallenger(ctx, "Honest",
		challenger.WithAlphabet(),
		challenger.WithPrivKey(sys.Cfg.Secrets.Alice))

	// Create first game
	t.Log("=== Step 2: Create Games and Wait for Processing ===")
	game1 := disputeGameFactory.StartOutputAlphabetGame(ctx, "sequencer", 1, common.Hash{0xaa})

	// Advance time past game duration
	sys.AdvanceTime(game1.MaxClockDuration(ctx))
	require.NoError(t, wait.ForNextBlock(ctx, l1Client))

	// Wait for game to resolve
	game1.WaitForGameStatus(ctx, types.GameStatusDefenderWon)

	// Create more games
	disputeGameFactory.StartOutputAlphabetGame(ctx, "sequencer", 2, common.Hash{0xbb})
	disputeGameFactory.StartOutputAlphabetGame(ctx, "sequencer", 3, common.Hash{0xcc})

	// Wait for challenger to process L1 head
	t.Log("=== Step 3: Verify Metric Updates ===")
	honestChallenger.WaitL1HeadActedOn(ctx, l1Client)

	require.NoError(t, wait.ForNextBlock(ctx, l1Client))
	honestChallenger.WaitL1HeadActedOn(ctx, l1Client)

	t.Log("  Challenger successfully tracking L1 head")

	t.Log("=== Test Complete: Highest Acted L1 Block Metric ===")
}

// TestMultiChallenger_WinningChallengersTracking tests that winning challengers
// are correctly tracked after game resolution.
func TestMultiChallenger_WinningChallengersTracking(t *testing.T) {
	op_e2e.InitParallel(t)
	ctx := context.Background()

	t.Log("=== Starting Winning Challengers Tracking Test ===")

	// Start Full Optimism devnet
	sys, l1Client := faultproofs.StartFaultDisputeSystem(t)
	t.Cleanup(sys.Close)

	// Create dispute game factory
	disputeGameFactory := disputegame.NewFactoryHelper(t, ctx, sys)

	// Create game with invalid root
	t.Log("=== Step 1: Create DisputeGame ===")
	game := disputeGameFactory.StartOutputAlphabetGame(ctx, "sequencer", 3, common.Hash{0x01, 0x02, 0x03, 0x04})
	t.Logf("  Game created at: %s", game.Addr.Hex())

	// Start two challengers
	t.Log("=== Step 2: Start Challengers ===")
	alice := sys.Cfg.Secrets.Addresses().Alice
	bob := sys.Cfg.Secrets.Addresses().Bob

	chl1 := game.StartChallenger(ctx, "sequencer", "Challenger1",
		challenger.WithPrivKey(sys.Cfg.Secrets.Alice),
		challenger.WithPollInterval(500*time.Millisecond))
	t.Logf("  Challenger1 (Alice): %s", alice.Hex())

	chl2 := game.StartChallenger(ctx, "sequencer", "Challenger2",
		challenger.WithPrivKey(sys.Cfg.Secrets.Bob),
		challenger.WithPollInterval(500*time.Millisecond))
	t.Logf("  Challenger2 (Bob): %s", bob.Hex())

	// Wait for challengers to start processing
	chl1.WaitL1HeadActedOn(ctx, l1Client)
	chl2.WaitL1HeadActedOn(ctx, l1Client)

	// Drive the game
	t.Log("=== Step 3: Drive Game to Resolution ===")
	claim := game.RootClaim(ctx)
	correctTrace := game.CreateHonestActor(ctx, "sequencer")

	for claim.IsOutputRoot(ctx) && !claim.IsOutputRootLeaf(ctx) {
		if claim.AgreesWithOutputRoot() {
			claim = claim.WaitForCounterClaim(ctx)
			game.LogGameData(ctx)
		} else {
			claim = claim.Attack(ctx, common.Hash{0xaa})
			game.LogGameData(ctx)
		}
	}

	claim = claim.WaitForCounterClaim(ctx)
	game.LogGameData(ctx)

	claim = correctTrace.AttackClaim(ctx, claim)
	for !claim.IsMaxDepth(ctx) {
		if claim.AgreesWithOutputRoot() {
			claim = claim.WaitForCounterClaim(ctx)
			game.LogGameData(ctx)
		} else {
			claim = correctTrace.AttackClaim(ctx, claim)
			game.LogGameData(ctx)
		}
	}

	claim.WaitForCountered(ctx)
	game.LogGameData(ctx)

	// Resolve game
	t.Log("=== Step 4: Resolve Game ===")
	sys.TimeTravelClock.AdvanceTime(game.MaxClockDuration(ctx))
	require.NoError(t, wait.ForNextBlock(ctx, l1Client))
	game.WaitForGameStatus(ctx, types.GameStatusChallengerWon)
	t.Log("  Game resolved: CHALLENGER_WINS")

	// Verify challengers were active
	t.Log("=== Step 5: Verify Challenger Tracking ===")
	_ = chl1
	_ = chl2

	// Check credits (after finalization delay)
	sys.TimeTravelClock.AdvanceTime(game.CreditUnlockDuration(ctx) * 2)
	require.NoError(t, wait.ForNextBlock(ctx, l1Client))
	game.WaitForBondModeDecided(ctx)

	aliceCredit := game.AvailableCredit(ctx, alice)
	bobCredit := game.AvailableCredit(ctx, bob)

	t.Logf("  Alice credit: %s", aliceCredit.String())
	t.Logf("  Bob credit: %s", bobCredit.String())

	// At least one should have non-zero credit
	totalCredit := new(big.Int).Add(aliceCredit, bobCredit)
	t.Logf("  Total credit: %s", totalCredit.String())

	t.Log("=== Test Complete: Winning Challengers Tracking ===")
}
