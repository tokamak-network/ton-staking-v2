package slashing

import (
	"encoding/json"
	"math/big"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/common/hexutil"
	rat "github.com/tokamak-network/ton-staking-v2/op-e2e/e2eutils/rat"

	"github.com/tokamak-network/ton-staking-v2/op-e2e/bindings"
)

type TimelineEntry struct {
	Step    string `json:"step"`
	Message string `json:"message"`
	Time    string `json:"time"`
}

type DemoState struct {
	Status                   string            `json:"status"`
	Message                  string            `json:"message"`
	Mode                     string            `json:"mode"`
	OperatorManager          string            `json:"operatorManager"`
	CandidateAddOn           string            `json:"candidateAddOn"`
	GameAddress              string            `json:"gameAddress"`
	GameType                 uint32            `json:"gameType"`
	RootClaim                string            `json:"rootClaim"`
	ExtraData                string            `json:"extraData"`
	Challenger               string            `json:"challenger"`
	WinningChallengers       []string          `json:"winningChallengers"`
	StakeBefore              string            `json:"stakeBefore"`
	StakeAfter               string            `json:"stakeAfter"`
	StakeDelta               string            `json:"stakeDelta"`
	ChallengerBalanceBefore  string            `json:"challengerBalanceBefore"`
	ChallengerBalanceAfter   string            `json:"challengerBalanceAfter"`
	ChallengerBalancesBefore map[string]string `json:"challengerBalancesBefore"`
	ChallengerBalancesAfter  map[string]string `json:"challengerBalancesAfter"`
	RewardDelta              string            `json:"rewardDelta"`
	SlashingTxHash           string            `json:"slashingTxHash"`
	Timeline                 []TimelineEntry   `json:"timeline"`
	LastUpdate               string            `json:"lastUpdate"`
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
	l2BlockNumber := big.NewInt(rat.TestL2BlockNumber)
	extraData := common.LeftPadBytes(l2BlockNumber.Bytes(), 32)

	state := DemoState{
		Status:                   "ready",
		Message:                  "Game resolved. Ready to slash.",
		Mode:                     "single",
		OperatorManager:          operatorManager.Hex(),
		CandidateAddOn:           candidateAddOn.Hex(),
		GameAddress:              gameAddress.Hex(),
		GameType:                 gameType,
		RootClaim:                common.BytesToHash(rootClaim[:]).Hex(),
		ExtraData:                hexutil.Encode(extraData),
		Challenger:               accounts.Challenger.Addr.Hex(),
		WinningChallengers:       []string{accounts.Challenger.Addr.Hex()},
		StakeBefore:              initialStake.String(),
		ChallengerBalanceBefore:  challengerBalanceBefore.String(),
		ChallengerBalancesBefore: map[string]string{accounts.Challenger.Addr.Hex(): challengerBalanceBefore.String()},
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
						state.ChallengerBalancesAfter = map[string]string{
							accounts.Challenger.Addr.Hex(): challengerBalanceAfter.String(),
						}

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

	// Create dispute game on RAT chain
	rootClaim := [32]byte{0xDE, 0xAD}
	_, gameAddress := rat.CreateDisputeGame(t, sys, accounts.Proposer.Auth, rootClaim)

	// Two challengers attack the root claim with different claims
	winnerA := accounts.Challenger.Addr
	winnerB := accounts.Deployer.Addr

	claimA := [32]byte{0xAA, 0x01}
	claimB := [32]byte{0xBB, 0x02}

	rat.AttackClaim(t, sys, accounts.Challenger.Auth, gameAddress, claimA, rootClaim)
	rat.AttackClaim(t, sys, accounts.Deployer.Auth, gameAddress, claimB, rootClaim)

	// Resolve claims to record both challengers as winners
	game, err := bindings.NewFaultDisputeGame(gameAddress, sys.L1Client)
	if err != nil {
		t.Fatalf("failed to bind FaultDisputeGame: %v", err)
	}

	maxClockDuration, err := game.MaxClockDuration(&bind.CallOpts{Context: ctx})
	if err != nil {
		t.Fatalf("failed to read maxClockDuration: %v", err)
	}
	rat.AdvanceTimeAndMine(t, sys, int64(maxClockDuration)+1)

	// Resolve child subgames first (claim indices 1 and 2)
	if tx, err := game.ResolveClaim(accounts.Challenger.Auth, big.NewInt(1), big.NewInt(0)); err == nil {
		_, _ = bind.WaitMined(ctx, sys.L1Client, tx)
	} else {
		t.Fatalf("resolveClaim(1) failed: %v", err)
	}
	if tx, err := game.ResolveClaim(accounts.Challenger.Auth, big.NewInt(2), big.NewInt(0)); err == nil {
		_, _ = bind.WaitMined(ctx, sys.L1Client, tx)
	} else {
		t.Fatalf("resolveClaim(2) failed: %v", err)
	}

	// Resolve root subgame then resolve game
	if tx, err := game.ResolveClaim(accounts.Challenger.Auth, big.NewInt(0), big.NewInt(0)); err == nil {
		_, _ = bind.WaitMined(ctx, sys.L1Client, tx)
	} else {
		t.Fatalf("resolveClaim(0) failed: %v", err)
	}
	if tx, err := game.Resolve(accounts.Challenger.Auth); err == nil {
		_, _ = bind.WaitMined(ctx, sys.L1Client, tx)
	} else {
		t.Fatalf("resolve game failed: %v", err)
	}

	initialStake := getStakeBalance(t, sys, slashingContracts, candidateAddOn, operatorManager)
	winnerABalanceBefore := getWTONBalance(t, sys, winnerA)
	winnerBBalanceBefore := getWTONBalance(t, sys, winnerB)

	gameType := uint32(0)
	l2BlockNumber := big.NewInt(rat.TestL2BlockNumber)
	extraData := common.LeftPadBytes(l2BlockNumber.Bytes(), 32)

	state := DemoState{
		Status:                   "ready",
		Message:                  "Game resolved with two challengers. Ready to slash.",
		Mode:                     "multi",
		OperatorManager:          operatorManager.Hex(),
		CandidateAddOn:           candidateAddOn.Hex(),
		GameAddress:              gameAddress.Hex(),
		GameType:                 gameType,
		RootClaim:                common.BytesToHash(rootClaim[:]).Hex(),
		ExtraData:                hexutil.Encode(extraData),
		Challenger:               winnerA.Hex() + "," + winnerB.Hex(),
		WinningChallengers:       []string{winnerA.Hex(), winnerB.Hex()},
		StakeBefore:              initialStake.String(),
		ChallengerBalanceBefore:  new(big.Int).Add(winnerABalanceBefore, winnerBBalanceBefore).String(),
		ChallengerBalancesBefore: map[string]string{winnerA.Hex(): winnerABalanceBefore.String(), winnerB.Hex(): winnerBBalanceBefore.String()},
	}

	addTimeline(&state, "game_created", "Dispute game created (multi)")
	addTimeline(&state, "challengers_started", "Two challengers attacked root claim")
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
						winnerABalanceAfter := getWTONBalance(t, sys, winnerA)
						winnerBBalanceAfter := getWTONBalance(t, sys, winnerB)

						state.Status = "slashed"
						state.Message = "Slashing executed."
						state.StakeAfter = finalStake.String()
						state.ChallengerBalanceAfter = new(big.Int).Add(winnerABalanceAfter, winnerBBalanceAfter).String()
						state.ChallengerBalancesAfter = map[string]string{
							winnerA.Hex(): winnerABalanceAfter.String(),
							winnerB.Hex(): winnerBBalanceAfter.String(),
						}

						stakeDelta := new(big.Int).Sub(initialStake, finalStake)
						rewardDelta := new(big.Int).Sub(
							new(big.Int).Add(winnerABalanceAfter, winnerBBalanceAfter),
							new(big.Int).Add(winnerABalanceBefore, winnerBBalanceBefore),
						)

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
