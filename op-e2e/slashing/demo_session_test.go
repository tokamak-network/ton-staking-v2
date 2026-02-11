package slashing

import (
	"encoding/json"
	"math/big"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/ethereum-optimism/optimism/op-challenger/game/types"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/common/hexutil"
	rat "github.com/tokamak-network/ton-staking-v2/op-e2e/e2eutils/rat"
)

type TimelineEntry struct {
	Step    string `json:"step"`
	Message string `json:"message"`
	Time    string `json:"time"`
}

type DemoState struct {
	Status                  string          `json:"status"`
	Message                 string          `json:"message"`
	Mode                    string          `json:"mode"`
	OperatorManager         string          `json:"operatorManager"`
	CandidateAddOn          string          `json:"candidateAddOn"`
	GameAddress             string          `json:"gameAddress"`
	GameType                uint32          `json:"gameType"`
	RootClaim               string          `json:"rootClaim"`
	ExtraData               string          `json:"extraData"`
	Challenger              string          `json:"challenger"`
	WinningChallengers      []string        `json:"winningChallengers"`
	StakeBefore             string          `json:"stakeBefore"`
	StakeAfter              string          `json:"stakeAfter"`
	StakeDelta              string          `json:"stakeDelta"`
	ChallengerBalanceBefore string          `json:"challengerBalanceBefore"`
	ChallengerBalanceAfter  string          `json:"challengerBalanceAfter"`
	RewardDelta             string          `json:"rewardDelta"`
	SlashingTxHash          string          `json:"slashingTxHash"`
	Timeline                []TimelineEntry `json:"timeline"`
	LastUpdate              string          `json:"lastUpdate"`
}

type DemoCommand struct {
	Action string `json:"action"`
}

func findProjectRootForDemo() (string, error) {
	wd, err := os.Getwd()
	if err != nil {
		return "", err
	}

	dir := wd
	for {
		devnetPath := filepath.Join(dir, ".devnet")
		if _, err := os.Stat(devnetPath); err == nil {
			return dir, nil
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			break
		}
		dir = parent
	}

	return "", os.ErrNotExist
}

func writeState(path string, state DemoState) error {
	state.LastUpdate = time.Now().Format(time.RFC3339)
	data, _ := json.MarshalIndent(state, "", "  ")
	return os.WriteFile(path, data, 0o644)
}

func readCommand(path string) (*DemoCommand, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var cmd DemoCommand
	if err := json.Unmarshal(data, &cmd); err != nil {
		return nil, err
	}
	return &cmd, nil
}

func addTimeline(state *DemoState, step, message string) {
	state.Timeline = append(state.Timeline, TimelineEntry{
		Step:    step,
		Message: message,
		Time:    time.Now().Format(time.RFC3339),
	})
}

func TestDemoSession(t *testing.T) {
	root, err := findProjectRootForDemo()
	if err != nil {
		t.Fatalf("project root not found")
	}

	sessionDir := filepath.Join(root, ".demo")
	if err := os.MkdirAll(sessionDir, 0o755); err != nil {
		t.Fatalf("failed to create .demo dir: %v", err)
	}

	statePath := filepath.Join(sessionDir, "session.json")
	commandPath := filepath.Join(sessionDir, "command.json")

	mode := os.Getenv("DEMO_MODE")
	if mode == "" {
		mode = "single"
	}

	if mode == "multi" {
		runMultiDemoSession(t, statePath, commandPath)
		return
	}

	runSingleDemoSession(t, statePath, commandPath)
}

func runSingleDemoSession(t *testing.T, statePath, commandPath string) {
	sys := rat.StartTONStakingSystem(t)
	ctx := sys.Ctx
	accounts := rat.SetupTestAccounts(t, sys)
	contracts := rat.ConnectTestContracts(t, sys)
	slashingContracts := connectSlashingContracts(t, sys)

	operatorStake := new(big.Int).Mul(big.NewInt(100000), new(big.Int).Exp(big.NewInt(10), big.NewInt(27), nil))
	rat.AdjustMinimumCollateral(t, sys, contracts, accounts.Deployer.Auth, operatorStake)

	candidateAddOn, operatorManager, rollupConfig := registerOperatorWithCandidateAddOn(
		t, sys, slashingContracts, accounts.Validator.Auth, operatorStake,
	)
	setupRATForValidator(t, sys, accounts, slashingContracts, candidateAddOn, rollupConfig, operatorStake)

	initialStake := getStakeBalance(t, sys, slashingContracts, candidateAddOn, operatorManager)
	challengerBalanceBefore := getWTONBalance(t, sys, accounts.Challenger.Addr)

	rootClaim := [32]byte{0xAB, 0xCD}
	_, gameAddress := rat.CreateDisputeGame(t, sys, accounts.Proposer.Auth, rootClaim)

	correctClaim := [32]byte{0xEF, 0x01}
	rat.AttackClaim(t, sys, accounts.Challenger.Auth, gameAddress, correctClaim, rootClaim)
	rat.AdvanceTimeAndMine(t, sys, 1209600)
	rat.ResolveGame(t, sys, accounts.Challenger.Auth, gameAddress)

	gameType := uint32(0)
	l2BlockNumber := big.NewInt(100)
	extraData := common.LeftPadBytes(l2BlockNumber.Bytes(), 32)

	state := DemoState{
		Status:                  "ready",
		Message:                 "Game resolved. Ready to slash.",
		Mode:                    "single",
		OperatorManager:         operatorManager.Hex(),
		CandidateAddOn:          candidateAddOn.Hex(),
		GameAddress:             gameAddress.Hex(),
		GameType:                gameType,
		RootClaim:               common.BytesToHash(rootClaim[:]).Hex(),
		ExtraData:               hexutil.Encode(extraData),
		Challenger:              accounts.Challenger.Addr.Hex(),
		WinningChallengers:      []string{accounts.Challenger.Addr.Hex()},
		StakeBefore:             initialStake.String(),
		ChallengerBalanceBefore: challengerBalanceBefore.String(),
	}

	addTimeline(&state, "game_created", "Dispute game created")
	addTimeline(&state, "challenger_won", "Challenger won the game")
	addTimeline(&state, "ready", "Ready to slash operator")

	if err := writeState(statePath, state); err != nil {
		t.Fatalf("failed to write state: %v", err)
	}

	for {
		select {
		case <-ctx.Done():
			return
		default:
			if _, err := os.Stat(commandPath); err == nil {
				cmd, err := readCommand(commandPath)
				if err == nil && cmd.Action == "slash" {
					tx, err := slashingContracts.Layer2ManagerSlashing.SlashingCandidate(
						accounts.Challenger.Auth,
						operatorManager,
						gameType,
						rootClaim,
						extraData,
						gameAddress,
					)
					if err != nil {
						state.Status = "error"
						state.Message = "slashingCandidate failed: " + err.Error()
					} else {
						state.SlashingTxHash = tx.Hash().Hex()
						_, _ = bind.WaitMined(ctx, sys.L1Client, tx)

						finalStake := getStakeBalance(t, sys, slashingContracts, candidateAddOn, operatorManager)
						challengerBalanceAfter := getWTONBalance(t, sys, accounts.Challenger.Addr)

						state.Status = "slashed"
						state.Message = "Slashing executed."
						state.StakeAfter = finalStake.String()
						state.ChallengerBalanceAfter = challengerBalanceAfter.String()

						stakeDelta := new(big.Int).Sub(initialStake, finalStake)
						rewardDelta := new(big.Int).Sub(challengerBalanceAfter, challengerBalanceBefore)
						state.StakeDelta = stakeDelta.String()
						state.RewardDelta = rewardDelta.String()

						addTimeline(&state, "slashed", "Operator slashed and rewards distributed")
					}
					_ = writeState(statePath, state)
				}
				_ = os.Remove(commandPath)
			}
			time.Sleep(2 * time.Second)
		}
	}
}

func runMultiDemoSession(t *testing.T, statePath, commandPath string) {
	env := StartRealGameTestEnv(t)

	sys := env.RATSystem
	ctx := sys.Ctx

	accounts := rat.SetupTestAccounts(t, sys)
	contracts := rat.ConnectTestContracts(t, sys)

	operatorStake := new(big.Int).Mul(big.NewInt(100000), new(big.Int).Exp(big.NewInt(10), big.NewInt(27), nil))
	rat.AdjustMinimumCollateral(t, sys, contracts, accounts.Deployer.Auth, operatorStake)

	candidateAddOn, operatorManager, rollupConfig := registerOperatorWithCandidateAddOn(
		t, sys, env.SlashingContracts, accounts.Validator.Auth, operatorStake,
	)
	setupRATForValidator(t, sys, accounts, env.SlashingContracts, candidateAddOn, rollupConfig, operatorStake)

	aliceAddr := env.System.Cfg.Secrets.Addresses().Alice
	bobAddr := env.System.Cfg.Secrets.Addresses().Bob
	challengerBalanceBefore := new(big.Int).Add(
		getWTONBalance(t, sys, aliceAddr),
		getWTONBalance(t, sys, bobAddr),
	)

	initialStake := getStakeBalance(t, sys, env.SlashingContracts, candidateAddOn, operatorManager)

	l2BlockNumber := uint64(1)
	invalidRoot := common.HexToHash("0xdeadbeef")
	game := env.CreateAlphabetGame(l2BlockNumber, invalidRoot)

	key1 := env.System.Cfg.Secrets.Alice
	key2 := env.System.Cfg.Secrets.Bob

	multi := NewMultiChallengerEnv(env)
	multi.AddChallenger(game, "challenger-1", key1)
	multi.AddChallenger(game, "challenger-2", key2)
	multi.WaitForAllChallengersToAct()

	claim := game.RootClaim(env.Ctx)
	correctTrace := game.CreateHonestActor(env.Ctx, "sequencer")

	for claim.IsOutputRoot(env.Ctx) && !claim.IsOutputRootLeaf(env.Ctx) {
		if claim.AgreesWithOutputRoot() {
			claim = claim.WaitForCounterClaim(env.Ctx)
			game.LogGameData(env.Ctx)
		} else {
			claim = claim.Attack(env.Ctx, common.Hash{0xba, 0xd0})
			game.LogGameData(env.Ctx)
		}
	}

	claim = claim.WaitForCounterClaim(env.Ctx)
	game.LogGameData(env.Ctx)

	claim = correctTrace.AttackClaim(env.Ctx, claim)
	for !claim.IsMaxDepth(env.Ctx) {
		if claim.AgreesWithOutputRoot() {
			claim = claim.WaitForCounterClaim(env.Ctx)
			game.LogGameData(env.Ctx)
		} else {
			claim = correctTrace.AttackClaim(env.Ctx, claim)
			game.LogGameData(env.Ctx)
		}
	}

	claim.WaitForCountered(env.Ctx)
	game.LogGameData(env.Ctx)

	const challengerWins types.GameStatus = 1
	env.AdvanceTimeAndResolve(game, challengerWins)

	rootClaimBytes := [32]byte(invalidRoot)

	gameType := uint32(0)
	extraData := common.LeftPadBytes(new(big.Int).SetUint64(l2BlockNumber).Bytes(), 32)

	alice := env.System.Cfg.Secrets.Addresses().Alice
	bob := env.System.Cfg.Secrets.Addresses().Bob

	state := DemoState{
		Status:                  "ready",
		Message:                 "Game resolved with two challengers. Ready to slash.",
		Mode:                    "multi",
		OperatorManager:         operatorManager.Hex(),
		CandidateAddOn:          candidateAddOn.Hex(),
		GameAddress:             game.Addr.Hex(),
		GameType:                gameType,
		RootClaim:               invalidRoot.Hex(),
		ExtraData:               hexutil.Encode(extraData),
		Challenger:              alice.Hex() + "," + bob.Hex(),
		WinningChallengers:      []string{alice.Hex(), bob.Hex()},
		StakeBefore:             initialStake.String(),
		ChallengerBalanceBefore: challengerBalanceBefore.String(),
	}

	addTimeline(&state, "game_created", "Dispute game created (multi)")
	addTimeline(&state, "challengers_started", "Two challengers started")
	addTimeline(&state, "challenger_won", "Challengers won the game")
	addTimeline(&state, "ready", "Ready to slash operator")

	if err := writeState(statePath, state); err != nil {
		t.Fatalf("failed to write state: %v", err)
	}

	for {
		select {
		case <-ctx.Done():
			return
		default:
			if _, err := os.Stat(commandPath); err == nil {
				cmd, err := readCommand(commandPath)
				if err == nil && cmd.Action == "slash" {
					tx, err := env.SlashingContracts.Layer2ManagerSlashing.SlashingCandidate(
						accounts.Challenger.Auth,
						operatorManager,
						gameType,
						rootClaimBytes,
						extraData,
						game.Addr,
					)
					if err != nil {
						state.Status = "error"
						state.Message = "slashingCandidate failed: " + err.Error()
					} else {
						state.SlashingTxHash = tx.Hash().Hex()
						_, _ = bind.WaitMined(ctx, sys.L1Client, tx)

						finalStake := getStakeBalance(t, sys, env.SlashingContracts, candidateAddOn, operatorManager)

						challengerBalanceAfter := new(big.Int).Add(
							getWTONBalance(t, sys, aliceAddr),
							getWTONBalance(t, sys, bobAddr),
						)

						state.Status = "slashed"
						state.Message = "Slashing executed."
						state.StakeAfter = finalStake.String()
						state.ChallengerBalanceAfter = challengerBalanceAfter.String()

						stakeDelta := new(big.Int).Sub(initialStake, finalStake)
						rewardDelta := new(big.Int).Sub(challengerBalanceAfter, challengerBalanceBefore)
						state.StakeDelta = stakeDelta.String()
						state.RewardDelta = rewardDelta.String()

						addTimeline(&state, "slashed", "Operator slashed and rewards distributed")
					}
					_ = writeState(statePath, state)
				}
				_ = os.Remove(commandPath)
			}
			time.Sleep(2 * time.Second)
		}
	}
}
