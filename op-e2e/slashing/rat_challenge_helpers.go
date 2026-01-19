package slashing

import (
	"crypto/ecdsa"
	"math/big"
	"strings"
	"testing"

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
	testDepositAmountTON = 50000 // 50000 TON
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
	_, err = bind.WaitMined(sys.Ctx, sys.L1Client, approveTx)
	require.NoError(t, err)

	// Register validator
	registerTx, err := contracts.RAT.RegisterValidator(validatorAuth, sys.Addresses.SystemConfig, depositAmount)
	require.NoError(t, err)
	_, err = bind.WaitMined(sys.Ctx, sys.L1Client, registerTx)
	require.NoError(t, err)

	t.Logf("✓ Validator registered with deposit: %s TON", depositAmount.String())
}

// createDisputeGameWithWrongClaim creates a DisputeGame with a wrong root claim
func createDisputeGameWithWrongClaim(t *testing.T, sys *rat.TONStakingSystem, proposerAuth *bind.TransactOpts) (*types.Receipt, common.Address) {
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
	l2BlockNumber := big.NewInt(testL2BlockNumber)
	extraData := common.LeftPadBytes(l2BlockNumber.Bytes(), 32)

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

// createDisputeGame creates a dispute game with a given root claim
func createDisputeGame(t *testing.T, sys *rat.TONStakingSystem, proposerAuth *bind.TransactOpts, rootClaim [32]byte) (*types.Receipt, common.Address) {
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
	l2BlockNumber := big.NewInt(testL2BlockNumber)
	extraData := common.LeftPadBytes(l2BlockNumber.Bytes(), 32)

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
