package faultproofs

import (
	"bufio"
	"crypto/ecdsa"
	"fmt"
	"math/big"
	"os/exec"
	"strings"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/stretchr/testify/require"

	"github.com/tokamak-network/ton-staking-v2/op-e2e/bindings"
	"github.com/tokamak-network/ton-staking-v2/op-e2e/e2eutils/rat"
)

// Common test constants
const (
	// Test accounts private keys (Anvil test accounts)
	validatorPrivateKey = "7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6" // Account #3
	deployerPrivateKey  = "59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d" // Account #1
	proposerPrivateKey  = "47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a" // Account #4

	// Test parameters
	testDepositAmountTON = 1000 // 1000 TON
	testL2BlockNumber    = 100

	// Event signatures
	eventDisputeGameCreated     = "0x5b565efe82411da98814f356d0e7bcb8f0219b8d970307c5afb4a6903a8b2e35"
	eventAttentionTestTriggered = "0xcf68a8dafa7b2329d7d7fcde3af620c2a51f64345d1eb2d66ffe7c7f1e9b0c38"
)

// TestAccounts holds all test account information
type TestAccounts struct {
	Validator struct {
		Key  *ecdsa.PrivateKey
		Addr common.Address
		Auth *bind.TransactOpts
	}
	Deployer struct {
		Key  *ecdsa.PrivateKey
		Addr common.Address
		Auth *bind.TransactOpts
	}
	Proposer struct {
		Key  *ecdsa.PrivateKey
		Addr common.Address
		Auth *bind.TransactOpts
	}
}

// TestContracts holds all contract instances
type TestContracts struct {
	RAT *bindings.RAT
	TON *bindings.ERC20
}

// setupTestAccounts creates and configures all test accounts
func setupTestAccounts(t *testing.T, sys *rat.TONStakingSystem) *TestAccounts {
	chainID, err := sys.L1Client.ChainID(sys.Ctx)
	require.NoError(t, err)

	accounts := &TestAccounts{}

	// Setup validator
	accounts.Validator.Key, err = crypto.HexToECDSA(validatorPrivateKey)
	require.NoError(t, err)
	accounts.Validator.Addr = crypto.PubkeyToAddress(accounts.Validator.Key.PublicKey)
	accounts.Validator.Auth, err = bind.NewKeyedTransactorWithChainID(accounts.Validator.Key, chainID)
	require.NoError(t, err)
	accounts.Validator.Auth.GasLimit = 3000000

	// Setup deployer
	accounts.Deployer.Key, err = crypto.HexToECDSA(deployerPrivateKey)
	require.NoError(t, err)
	accounts.Deployer.Addr = crypto.PubkeyToAddress(accounts.Deployer.Key.PublicKey)
	accounts.Deployer.Auth, err = bind.NewKeyedTransactorWithChainID(accounts.Deployer.Key, chainID)
	require.NoError(t, err)
	accounts.Deployer.Auth.GasLimit = 3000000

	// Setup proposer
	accounts.Proposer.Key, err = crypto.HexToECDSA(proposerPrivateKey)
	require.NoError(t, err)
	accounts.Proposer.Addr = crypto.PubkeyToAddress(accounts.Proposer.Key.PublicKey)
	accounts.Proposer.Auth, err = bind.NewKeyedTransactorWithChainID(accounts.Proposer.Key, chainID)
	require.NoError(t, err)
	accounts.Proposer.Auth.GasLimit = 5000000

	return accounts
}

// connectTestContracts connects to RAT and TON contracts
func connectTestContracts(t *testing.T, sys *rat.TONStakingSystem) *TestContracts {
	contracts := &TestContracts{}

	var err error
	contracts.RAT, err = bindings.NewRAT(sys.Addresses.RATProxy, sys.L1Client)
	require.NoError(t, err)

	contracts.TON, err = bindings.NewERC20(sys.Addresses.TON, sys.L1Client)
	require.NoError(t, err)

	return contracts
}

// getTestDepositAmount returns the standard test deposit amount (50000 TON in wei)
func getTestDepositAmount() *big.Int {
	depositAmount := new(big.Int).SetUint64(testDepositAmountTON)
	depositAmount.Mul(depositAmount, big.NewInt(1e18)) // Convert to wei
	return depositAmount
}

// adjustMinimumCollateral adjusts RAT minimum collateral requirements if needed
func adjustMinimumCollateral(t *testing.T, sys *rat.TONStakingSystem, contracts *TestContracts, deployerAuth *bind.TransactOpts, depositAmount *big.Int) {
	callOpts := &bind.CallOpts{Context: sys.Ctx}
	minCollateral, err := contracts.RAT.GetMinimumCollateral(callOpts)
	require.NoError(t, err)

	// If deposit is sufficient, no adjustment needed
	if depositAmount.Cmp(minCollateral) >= 0 {
		return
	}

	t.Logf("Adjusting minimum collateral from %s to fit deposit %s", minCollateral.String(), depositAmount.String())

	// Set slashing penalty and validator buffer to 1/4 of deposit each
	quarterDeposit := new(big.Int).Div(depositAmount, big.NewInt(4))

	_, err = contracts.RAT.SetSlashingPenalty(deployerAuth, quarterDeposit)
	require.NoError(t, err)

	_, err = contracts.RAT.SetValidatorBuffer(deployerAuth, quarterDeposit)
	require.NoError(t, err)

	t.Logf("✓ Collateral requirements adjusted")
}

// registerValidatorWithTON registers a validator with TON deposit
func registerValidatorWithTON(t *testing.T, sys *rat.TONStakingSystem, contracts *TestContracts, validatorAuth *bind.TransactOpts, depositAmount *big.Int) {
	// Approve TON to RAT
	approveTx, err := contracts.TON.Approve(validatorAuth, sys.Addresses.RATProxy, depositAmount)
	require.NoError(t, err)
	approveReceipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, approveTx)
	require.NoError(t, err)
	require.Equal(t, uint64(1), approveReceipt.Status, "TON approval failed")

	// Register validator
	registerTx, err := contracts.RAT.RegisterValidator(validatorAuth, sys.Addresses.SystemConfig, depositAmount)
	require.NoError(t, err)
	registerReceipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, registerTx)
	require.NoError(t, err)
	require.Equal(t, uint64(1), registerReceipt.Status, "Validator registration failed")

	t.Logf("✓ Validator registered with deposit: %s TON", depositAmount.String())
}

// createDisputeGameWithWrongClaim creates a DisputeGame with a wrong root claim
func createDisputeGameWithWrongClaim(t *testing.T, sys *rat.TONStakingSystem, proposerAuth *bind.TransactOpts, l2BlockNumber uint64) (*types.Receipt, common.Address) {
	callOpts := &bind.CallOpts{Context: sys.Ctx}

	// Connect to DisputeGameFactory
	dgf, err := bindings.NewDisputeGameFactory(sys.Addresses.DisputeGameFactory, sys.L1Client)
	require.NoError(t, err)

	// Get required init bond
	gameType := uint32(0)
	initBond, err := dgf.InitBonds(callOpts, gameType)
	require.NoError(t, err)

	// Set bond value
	proposerAuth.Value = initBond

	// Create wrong root claim (obviously incorrect)
	rootClaim := [32]byte{0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF}

	// extraData: 32 bytes containing l2BlockNumber
	l2BlockNumberBig := big.NewInt(int64(l2BlockNumber))
	extraData := common.LeftPadBytes(l2BlockNumberBig.Bytes(), 32)

	// Create game
	createGameTx, err := dgf.Create(proposerAuth, gameType, rootClaim, extraData)
	require.NoError(t, err)

	receipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, createGameTx)
	require.NoError(t, err)

	// Parse game address from DisputeGameCreated event
	var gameAddress common.Address
	for _, log := range receipt.Logs {
		if log.Topics[0].Hex() == eventDisputeGameCreated {
			gameAddress = common.HexToAddress(log.Topics[1].Hex())
			break
		}
	}
	require.NotEqual(t, common.Address{}, gameAddress, "Should have game address")

	t.Logf("✓ DisputeGame created at: %s", gameAddress.Hex())

	return receipt, gameAddress
}

// parseRATTriggerEvent parses the AttentionTestTriggered event from receipt
func parseRATTriggerEvent(t *testing.T, receipt *types.Receipt, expectedValidator common.Address) (testID [32]byte, triggered bool) {
	for _, log := range receipt.Logs {
		if log.Topics[0].Hex() == eventAttentionTestTriggered {
			triggered = true
			testID = log.Topics[1]
			selectedValidator := common.HexToAddress(log.Topics[2].Hex())

			t.Logf("✓ RAT triggered - Test ID: %s, Validator: %s",
				common.BytesToHash(testID[:]).Hex(), selectedValidator.Hex())

			require.Equal(t, expectedValidator, selectedValidator, "Wrong validator selected")
			return testID, true
		}
	}

	return [32]byte{}, false
}

// advanceTimeAndMine advances time in Anvil and mines a block
func advanceTimeAndMine(t *testing.T, sys *rat.TONStakingSystem, seconds int64) {
	var timeResult interface{}
	err := sys.L1Client.Client().Call(&timeResult, "evm_increaseTime", seconds)
	require.NoError(t, err, "Failed to advance time")
	t.Logf("✓ Time advanced by %d seconds", seconds)

	var mineResult interface{}
	err = sys.L1Client.Client().Call(&mineResult, "evm_mine")
	require.NoError(t, err, "Failed to mine block")
	t.Logf("✓ Block mined")
}

// createDisputeGame creates a dispute game with a given root claim and L2 block number
func createDisputeGame(t *testing.T, sys *rat.TONStakingSystem, proposerAuth *bind.TransactOpts, rootClaim [32]byte, l2BlockNumber uint64) (*types.Receipt, common.Address) {
	callOpts := &bind.CallOpts{Context: sys.Ctx}

	// Connect to DisputeGameFactory
	dgf, err := bindings.NewDisputeGameFactory(sys.Addresses.DisputeGameFactory, sys.L1Client)
	require.NoError(t, err)

	// Get required init bond
	gameType := uint32(0)
	initBond, err := dgf.InitBonds(callOpts, gameType)
	require.NoError(t, err)

	// Set bond value
	proposerAuth.Value = initBond

	// extraData: 32 bytes containing l2BlockNumber
	l2BlockNumberBig := big.NewInt(int64(l2BlockNumber))
	extraData := common.LeftPadBytes(l2BlockNumberBig.Bytes(), 32)

	// Create game
	createGameTx, err := dgf.Create(proposerAuth, gameType, rootClaim, extraData)
	require.NoError(t, err)

	receipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, createGameTx)
	require.NoError(t, err)

	// Parse game address from DisputeGameCreated event
	gameAddress := parseDisputeGameCreatedEvent(t, receipt)
	require.NotEqual(t, common.Address{}, gameAddress, "Should have game address")

	t.Logf("✓ DisputeGame created at: %s", gameAddress.Hex())

	return receipt, gameAddress
}

// parseDisputeGameCreatedEvent parses the DisputeGameCreated event from receipt
func parseDisputeGameCreatedEvent(t *testing.T, receipt *types.Receipt) common.Address {
	for _, log := range receipt.Logs {
		if log.Topics[0].Hex() == eventDisputeGameCreated {
			gameAddress := common.HexToAddress(log.Topics[1].Hex())
			return gameAddress
		}
	}
	return common.Address{}
}

// submitEvidenceToRAT submits evidence to RAT contract and returns receipt
func submitEvidenceToRAT(t *testing.T, sys *rat.TONStakingSystem, contracts *TestContracts, validatorAuth *bind.TransactOpts, testID [32]byte, evidenceType uint8, evidenceData []byte) (*types.Receipt, error) {
	t.Logf("Submitting evidence: testID=%s, type=%d, dataLen=%d", common.BytesToHash(testID[:]).Hex(), evidenceType, len(evidenceData))

	evidenceTx, err := contracts.RAT.SubmitEvidence(validatorAuth, testID, evidenceType, evidenceData)
	if err != nil {
		return nil, err
	}

	receipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, evidenceTx)
	if err != nil {
		return nil, err
	}

	return receipt, nil
}

// startRATClient starts RAT client subprocess and waits for evidence submission
func startRATClient(t *testing.T, sys *rat.TONStakingSystem, contracts *TestContracts, l1RPCURL, l2RPCURL string, validatorPrivKey string, testID [32]byte, validatorAddr common.Address, startBlock uint64) *types.Receipt {
	ctx := sys.Ctx

	// Find project root (ton-staking-v2 directory)
	projectRoot, err := rat.FindProjectRoot()
	if err != nil {
		t.Fatalf("Failed to find project root: %v", err)
	}

	// Build RAT client binary if not exists
	t.Log("Building RAT client binary...")
	buildCmd := exec.Command("make", "rat-client-build")
	buildCmd.Dir = projectRoot
	buildOutput, err := buildCmd.CombinedOutput()
	if err != nil {
		t.Logf("Build output: %s", buildOutput)
		t.Fatalf("Failed to build RAT client: %v", err)
	}
	t.Log("✓ RAT client binary built")

	// Prepare RAT client arguments
	ratClientBinary := "clients/rat-client-type3/bin/rat-client-type3"
	args := []string{
		"--l1-rpc", l1RPCURL,
		"--l2-rpc", l2RPCURL,
		"--private-key", validatorPrivKey,
		"--rat-contract", sys.Addresses.RATProxy.Hex(),
		"--system-config", sys.Addresses.SystemConfig.Hex(),
		"--start-block", fmt.Sprintf("%d", startBlock),
	}

	t.Logf("Starting RAT client:")
	t.Logf("  Binary: %s", ratClientBinary)
	t.Logf("  L1 RPC: %s", l1RPCURL)
	t.Logf("  L2 RPC: %s", l2RPCURL)
	t.Logf("  RAT Contract: %s", sys.Addresses.RATProxy.Hex())
	t.Logf("  System Config: %s", sys.Addresses.SystemConfig.Hex())

	// Start RAT client process
	ratClient := exec.Command(ratClientBinary, args...)
	ratClient.Dir = projectRoot

	// Capture output
	ratClientStdout, err := ratClient.StdoutPipe()
	if err != nil {
		t.Fatalf("Failed to create stdout pipe: %v", err)
	}
	ratClientStderr, err := ratClient.StderrPipe()
	if err != nil {
		t.Fatalf("Failed to create stderr pipe: %v", err)
	}

	// Start the process
	if err := ratClient.Start(); err != nil {
		t.Fatalf("Failed to start RAT client: %v", err)
	}
	t.Logf("✓ RAT client started (PID: %d)", ratClient.Process.Pid)

	// Log output in background
	go func() {
		scanner := bufio.NewScanner(ratClientStdout)
		for scanner.Scan() {
			t.Logf("[rat-client] %s", scanner.Text())
		}
	}()
	go func() {
		scanner := bufio.NewScanner(ratClientStderr)
		for scanner.Scan() {
			t.Logf("[rat-client-err] %s", scanner.Text())
		}
	}()

	// Ensure cleanup
	defer func() {
		if ratClient.Process != nil {
			t.Logf("Stopping RAT client (PID: %d)", ratClient.Process.Pid)
			ratClient.Process.Kill()
			ratClient.Wait()
		}
	}()

	// Wait for evidence submission (monitor EvidenceSubmitted event)
	t.Log("Waiting for evidence submission...")

	eventSig := crypto.Keccak256Hash([]byte("EvidenceSubmitted(bytes32,address,address,uint32)"))
	evidenceStartBlock := startBlock // Start monitoring from the same block as RAT event

	// Poll for evidence submission event (timeout after 2 minutes)
	timeout := time.After(2 * time.Minute)
	ticker := time.NewTicker(2 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-timeout:
			t.Fatal("Timeout waiting for evidence submission (2 minutes)")
			return nil

		case <-ticker.C:
			// Get current block
			currentBlock, err := sys.L1Client.BlockNumber(ctx)
			if err != nil {
				t.Logf("Failed to get block number: %v", err)
				continue
			}

			// Query logs for EvidenceSubmitted event
			logs, err := sys.L1Client.FilterLogs(ctx, ethereum.FilterQuery{
				FromBlock: new(big.Int).SetUint64(evidenceStartBlock),
				ToBlock:   new(big.Int).SetUint64(currentBlock),
				Addresses: []common.Address{sys.Addresses.RATProxy},
				Topics:    [][]common.Hash{{eventSig}, {testID}},
			})
			if err != nil {
				t.Logf("Failed to filter logs: %v", err)
				continue
			}

			if len(logs) > 0 {
				log := logs[0]
				t.Logf("✓ Evidence submitted in block %d, tx %s", log.BlockNumber, log.TxHash.Hex())

				// Get receipt
				receipt, err := sys.L1Client.TransactionReceipt(ctx, log.TxHash)
				if err != nil {
					t.Fatalf("Failed to get receipt: %v", err)
				}

				if receipt.Status == 1 {
					t.Log("✓ Evidence submission successful")

					// Verify bond recovery
					callOpts := &bind.CallOpts{Context: ctx}
					registration, err := contracts.RAT.ValidatorRegistrations(callOpts, sys.Addresses.SystemConfig, validatorAddr)
					if err == nil {
						t.Logf("✓ Validator deposit after evidence: %s", registration.DepositedAmount.String())
					}
				} else {
					t.Log("⚠ Evidence submission transaction reverted")
				}

				return receipt
			}

			startBlock = currentBlock + 1
		}
	}
}

// parseRATTriggerEventWithBatchIndex parses the AttentionTestTriggered event with batchIndex from receipt
func parseRATTriggerEventWithBatchIndex(t *testing.T, receipt *types.Receipt, expectedValidator common.Address) (testID [32]byte, batchIndex uint32, triggered bool) {
	for _, log := range receipt.Logs {
		if log.Topics[0].Hex() == eventAttentionTestTriggered {
			triggered = true
			testID = log.Topics[1]
			selectedValidator := common.HexToAddress(log.Topics[2].Hex())

			// Parse non-indexed data for batchIndex
			ratABI, err := abi.JSON(strings.NewReader(bindings.RATABI))
			require.NoError(t, err)

			type EventData struct {
				GameAddress common.Address
				BatchIndex  uint32
				Deadline    *big.Int
			}
			var data EventData
			err = ratABI.UnpackIntoInterface(&data, "AttentionTestTriggered", log.Data)
			require.NoError(t, err)

			batchIndex = data.BatchIndex
			t.Logf("✓ RAT triggered - Test ID: %s, Validator: %s, Batch: %d",
				common.BytesToHash(testID[:]).Hex(), selectedValidator.Hex(), batchIndex)

			require.Equal(t, expectedValidator, selectedValidator, "Wrong validator selected")
			return testID, batchIndex, true
		}
	}

	return [32]byte{}, 0, false
}
