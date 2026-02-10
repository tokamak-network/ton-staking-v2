package slashing

import (
	"context"
	"encoding/json"
	"math/big"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum/common"
	rat "github.com/tokamak-network/ton-staking-v2/op-e2e/e2eutils/rat"
)

type DemoState struct {
	Status                  string `json:"status"`
	Message                 string `json:"message"`
	OperatorManager         string `json:"operatorManager"`
	CandidateAddOn          string `json:"candidateAddOn"`
	GameAddress             string `json:"gameAddress"`
	GameType                uint32 `json:"gameType"`
	RootClaim               string `json:"rootClaim"`
	ExtraData               string `json:"extraData"`
	Challenger              string `json:"challenger"`
	StakeBefore             string `json:"stakeBefore"`
	StakeAfter              string `json:"stakeAfter"`
	ChallengerBalanceBefore string `json:"challengerBalanceBefore"`
	ChallengerBalanceAfter  string `json:"challengerBalanceAfter"`
	LastUpdate              string `json:"lastUpdate"`
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

	ctx := context.Background()

	sys := rat.StartTONStakingSystem(t)
	accounts := rat.SetupTestAccounts(t, sys)
	contracts := rat.ConnectTestContracts(t, sys)
	slashingContracts := connectSlashingContracts(t, sys)

	// Setup operator + stake
	operatorStake := new(big.Int).Mul(big.NewInt(100000), new(big.Int).Exp(big.NewInt(10), big.NewInt(27), nil))
	rat.AdjustMinimumCollateral(t, sys, contracts, accounts.Deployer.Auth, operatorStake)

	candidateAddOn, operatorManager, rollupConfig := registerOperatorWithCandidateAddOn(
		t, sys, slashingContracts, accounts.Validator.Auth, operatorStake,
	)

	setupRATForValidator(t, sys, accounts, slashingContracts, candidateAddOn, rollupConfig, operatorStake)

	initialStake := getStakeBalance(t, sys, slashingContracts, candidateAddOn, operatorManager)
	challengerBalanceBefore := getWTONBalance(t, sys, accounts.Challenger.Addr)

	// Create and resolve dispute game (challenger wins)
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
	OperatorManager:         operatorManager.Hex(),
		CandidateAddOn:          candidateAddOn.Hex(),
		GameAddress:             gameAddress.Hex(),
		GameType:                gameType,
	RootClaim:               common.BytesToHash(rootClaim[:]).Hex(),
	ExtraData:               common.Bytes2Hex(extraData),
	Challenger:              accounts.Challenger.Addr.Hex(),
	StakeBefore:             initialStake.String(),
	ChallengerBalanceBefore: challengerBalanceBefore.String(),
	}

	if err := writeState(statePath, state); err != nil {
		t.Fatalf("failed to write state: %v", err)
	}

	t.Log("Demo session ready. Waiting for commands...")

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
						_, _ = waitMined(t, sys.L1Client, tx)

						finalStake := getStakeBalance(t, sys, slashingContracts, candidateAddOn, operatorManager)
						challengerBalanceAfter := getWTONBalance(t, sys, accounts.Challenger.Addr)

						state.Status = "slashed"
						state.Message = "Slashing executed."
						state.StakeAfter = finalStake.String()
						state.ChallengerBalanceAfter = challengerBalanceAfter.String()
					}
					_ = writeState(statePath, state)
				}
				_ = os.Remove(commandPath)
			}
			time.Sleep(2 * time.Second)
	}
	}
