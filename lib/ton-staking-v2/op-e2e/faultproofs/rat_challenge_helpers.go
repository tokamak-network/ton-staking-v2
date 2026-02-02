package faultproofs

import (
	"bufio"
	"context"
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
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/stretchr/testify/require"

	"github.com/tokamak-network/ton-staking-v2/op-e2e/bindings"
	"github.com/tokamak-network/ton-staking-v2/op-e2e/e2eutils/rat"
)

// ============================================================================
// Package-level ABI definitions (initialized once to avoid repeated parsing)
// ============================================================================

var (
	// stakeOfABI is used to query validator staking amounts from SeigManager
	stakeOfABI abi.ABI

	// layer2ManagerGetLayer2ABI is used to query Layer2 address from Layer2Manager
	layer2ManagerGetLayer2ABI abi.ABI
)

func init() {
	var err error

	stakeOfABI, err = abi.JSON(strings.NewReader(`[{"inputs":[{"internalType":"address","name":"layer2","type":"address"},{"internalType":"address","name":"account","type":"address"}],"name":"stakeOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}]`))
	if err != nil {
		panic("failed to parse stakeOfABI: " + err.Error())
	}

	layer2ManagerGetLayer2ABI, err = abi.JSON(strings.NewReader(`[{"inputs":[{"internalType":"address","name":"systemConfig","type":"address"}],"name":"getLayer2BySystemConfig","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"}]`))
	if err != nil {
		panic("failed to parse layer2ManagerGetLayer2ABI: " + err.Error())
	}
}

// ============================================================================
// Utility functions (reduce code duplication)
// ============================================================================

// waitForTransactionReceipt polls for a transaction receipt with timeout.
// Returns the receipt on success or fails the test on timeout.
func waitForTransactionReceipt(
	t *testing.T,
	ctx context.Context,
	client *ethclient.Client,
	txHash common.Hash,
	description string,
) *types.Receipt {
	for i := 0; i < 50; i++ {
		receipt, err := client.TransactionReceipt(ctx, txHash)
		if err == nil && receipt != nil {
			require.Equal(t, uint64(1), receipt.Status, description+" should succeed")
			t.Logf("✓ %s", description)
			return receipt
		}
		time.Sleep(100 * time.Millisecond)
	}
	t.Fatalf("Timeout waiting for %s receipt", description)
	return nil
}

// waitForTransactionReceiptNoLog polls for a transaction receipt without logging.
// Returns the receipt on success or fails the test on timeout.
func waitForTransactionReceiptNoLog(
	t *testing.T,
	ctx context.Context,
	client *ethclient.Client,
	txHash common.Hash,
	description string,
) *types.Receipt {
	for i := 0; i < 50; i++ {
		receipt, err := client.TransactionReceipt(ctx, txHash)
		if err == nil && receipt != nil {
			return receipt
		}
		time.Sleep(100 * time.Millisecond)
	}
	t.Fatalf("Timeout waiting for %s receipt", description)
	return nil
}

// impersonateAccount starts impersonating an account on Anvil and returns a cleanup function.
// Usage: cleanup := impersonateAccount(t, client, account); defer cleanup()
func impersonateAccount(t *testing.T, client *ethclient.Client, account common.Address) func() {
	var result any
	err := client.Client().Call(&result, "anvil_impersonateAccount", account)
	require.NoError(t, err, "Failed to impersonate account %s", account.Hex())

	return func() {
		client.Client().Call(&result, "anvil_stopImpersonatingAccount", account)
	}
}

// fundAccount sets the balance of an account on Anvil.
func fundAccount(t *testing.T, client *ethclient.Client, account common.Address, balanceHex string) {
	var result any
	err := client.Client().Call(&result, "anvil_setBalance", account, balanceHex)
	require.NoError(t, err, "Failed to set balance for %s", account.Hex())
}

// ============================================================================
// Common test constants
// ============================================================================

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

	// DisputeGameFactory storage slots (matching modified Optimism contract with RAT)
	// Storage layout from forge inspect:
	//   Slot 51: _owner, Slot 101: gameImpls, Slot 102: initBonds,
	//   Slot 103: _disputeGames, Slot 104: _disputeGameList,
	//   Slot 105: rat, Slot 106: systemConfig
	dgfSlotRAT          = 105 // RAT address stored at slot 105
	dgfSlotSystemConfig = 106 // SystemConfig address stored at slot 106
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
	RAT            *bindings.RAT
	TON            *bindings.ERC20
	WTON           *bindings.WTON
	DepositManager *bind.BoundContract // Raw contract binding for DepositManager
}

// readDGFRatFromStorage reads the RAT address from DisputeGameFactory storage slot 52
// This is needed because the Optimism DisputeGameFactory bytecode doesn't have a rat() view function
func readDGFRatFromStorage(client *ethclient.Client, dgfAddress common.Address) (common.Address, error) {
	slot := common.BigToHash(big.NewInt(dgfSlotRAT))
	data, err := client.StorageAt(context.Background(), dgfAddress, slot, nil)
	if err != nil {
		return common.Address{}, err
	}
	return common.BytesToAddress(data), nil
}

// readDGFSystemConfigFromStorage reads the SystemConfig address from DisputeGameFactory storage slot 103
// This is needed because the Optimism DisputeGameFactory bytecode doesn't have a systemConfig() view function
func readDGFSystemConfigFromStorage(client *ethclient.Client, dgfAddress common.Address) (common.Address, error) {
	slot := common.BigToHash(big.NewInt(dgfSlotSystemConfig))
	data, err := client.StorageAt(context.Background(), dgfAddress, slot, nil)
	if err != nil {
		return common.Address{}, err
	}
	return common.BytesToAddress(data), nil
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

// connectTestContracts connects to RAT, TON, WTON, and DepositManager contracts
func connectTestContracts(t *testing.T, sys *rat.TONStakingSystem) *TestContracts {
	contracts := &TestContracts{}

	var err error
	contracts.RAT, err = bindings.NewRAT(sys.Addresses.RATProxy, sys.L1Client)
	require.NoError(t, err)

	contracts.TON, err = bindings.NewERC20(sys.Addresses.TON, sys.L1Client)
	require.NoError(t, err)

	contracts.WTON, err = bindings.NewWTON(sys.Addresses.WTON, sys.L1Client)
	require.NoError(t, err)

	// DepositManager ABI (minimal interface)
	depositManagerABI := `[{"inputs":[{"internalType":"address","name":"layer2","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"deposit","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"}]`
	parsedABI, err := abi.JSON(strings.NewReader(depositManagerABI))
	require.NoError(t, err)
	contracts.DepositManager = bind.NewBoundContract(sys.Addresses.DepositManagerProxy, parsedABI, sys.L1Client, sys.L1Client, sys.L1Client)

	return contracts
}

// V3 Configuration Constants (matching DeployV3FullForDevnet.s.sol)
const (
	// V3 Seigniorage Distribution Parameters
	daoDistributionRatio       = "200000000000000000000000000"         // 0.2e27 = 20%
	minStakingRatio            = "100000000000000000000000000"         // 0.1e27 = 10%
	validatorDistributionRatio = "200000000000000000000000000"         // 0.2e27 = 20%
	halfSaturationPoint        = "10000000000000000000000000000000000" // 10_000_000e27 = 10M TON

	// V3 Sequencer Parameters
	maxChallengers            = 10
	maxFraudProofCost         = "1000000000000000000000000000000" // 1000e27 = 1000 WTON
	sequencerAdditionalReward = "100000000000000000000000000000"  // 100e27 = 100 WTON
)

// configureV3Parameters sets up SeigManager V3 parameters at runtime.
// This is called at test start because these function calls may not work reliably in offline genesis mode.
func configureV3Parameters(t *testing.T, sys *rat.TONStakingSystem) {
	t.Log("Configuring V3 parameters at runtime...")

	deployer := common.HexToAddress("0x70997970C51812dc3A010C7d01b50e0d17dc79C8") // TON Staking deployer

	// Impersonate and fund deployer
	cleanup := impersonateAccount(t, sys.L1Client, deployer)
	defer cleanup()
	fundAccount(t, sys.L1Client, deployer, "0x56BC75E2D63100000") // 100 ETH

	// SeigManagerV1_4 ABI for V3 functions
	seigManagerABI, err := abi.JSON(strings.NewReader(`[
		{"inputs":[{"internalType":"uint256","name":"_ratio","type":"uint256"}],"name":"setDaoDistributionRatio","outputs":[],"stateMutability":"nonpayable","type":"function"},
		{"inputs":[{"internalType":"uint256","name":"_ratio","type":"uint256"}],"name":"setMinStakingRatio","outputs":[],"stateMutability":"nonpayable","type":"function"},
		{"inputs":[{"internalType":"uint256","name":"_ratio","type":"uint256"}],"name":"setValidatorDistributionRatio","outputs":[],"stateMutability":"nonpayable","type":"function"},
		{"inputs":[{"internalType":"uint256","name":"_point","type":"uint256"}],"name":"setHalfSaturationPoint","outputs":[],"stateMutability":"nonpayable","type":"function"},
		{"inputs":[{"internalType":"uint256","name":"_max","type":"uint256"}],"name":"setMaxChallengers","outputs":[],"stateMutability":"nonpayable","type":"function"},
		{"inputs":[{"internalType":"uint256","name":"_max","type":"uint256"}],"name":"setMaxFraudProofCost","outputs":[],"stateMutability":"nonpayable","type":"function"},
		{"inputs":[{"internalType":"uint256","name":"_reward","type":"uint256"}],"name":"setSequencerAdditionalReward","outputs":[],"stateMutability":"nonpayable","type":"function"},
		{"inputs":[{"internalType":"address","name":"_rat","type":"address"}],"name":"setRATContract","outputs":[],"stateMutability":"nonpayable","type":"function"},
		{"inputs":[],"name":"migrateToV3","outputs":[],"stateMutability":"nonpayable","type":"function"},
		{"inputs":[],"name":"v3Migrated","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"}
	]`))
	require.NoError(t, err)

	gasPrice, err := sys.L1Client.SuggestGasPrice(sys.Ctx)
	require.NoError(t, err)

	// Helper to send transaction
	sendTx := func(method string, args ...interface{}) {
		callData, err := seigManagerABI.Pack(method, args...)
		require.NoError(t, err, "Failed to pack "+method)

		txArgs := map[string]any{
			"from":     deployer,
			"to":       sys.Addresses.SeigManagerProxy,
			"gas":      "0x100000", // 1M gas
			"gasPrice": "0x" + gasPrice.Text(16),
			"data":     "0x" + common.Bytes2Hex(callData),
		}

		var txHash common.Hash
		err = sys.L1Client.Client().Call(&txHash, "eth_sendTransaction", txArgs)
		require.NoError(t, err, "Failed to send "+method)

		waitForTransactionReceipt(t, sys.Ctx, sys.L1Client, txHash, method)
	}

	// Check if already migrated
	callData, _ := seigManagerABI.Pack("v3Migrated")
	resultBytes, err := sys.L1Client.CallContract(sys.Ctx, ethereum.CallMsg{
		To:   &sys.Addresses.SeigManagerProxy,
		Data: callData,
	}, nil)

	var migrated bool
	if err == nil && len(resultBytes) > 0 {
		seigManagerABI.UnpackIntoInterface(&migrated, "v3Migrated", resultBytes)
	}

	if migrated {
		t.Log("✓ V3 already migrated, skipping configuration")
	} else {
		// Set V3 parameters
		daoRatio, _ := new(big.Int).SetString(daoDistributionRatio, 10)
		sendTx("setDaoDistributionRatio", daoRatio)

		minRatio, _ := new(big.Int).SetString(minStakingRatio, 10)
		sendTx("setMinStakingRatio", minRatio)

		validatorRatio, _ := new(big.Int).SetString(validatorDistributionRatio, 10)
		sendTx("setValidatorDistributionRatio", validatorRatio)

		halfSat, _ := new(big.Int).SetString(halfSaturationPoint, 10)
		sendTx("setHalfSaturationPoint", halfSat)

		sendTx("setMaxChallengers", big.NewInt(maxChallengers))

		maxFraud, _ := new(big.Int).SetString(maxFraudProofCost, 10)
		sendTx("setMaxFraudProofCost", maxFraud)

		seqReward, _ := new(big.Int).SetString(sequencerAdditionalReward, 10)
		sendTx("setSequencerAdditionalReward", seqReward)

		// Set RAT contract
		sendTx("setRATContract", sys.Addresses.RATProxy)

		// Migrate to V3
		sendTx("migrateToV3")
	}

	t.Log("✓ V3 parameters configured")
}

// setRATTriggerProbabilityTo100Percent sets RAT trigger probability to 100% for testing
func setRATTriggerProbabilityTo100Percent(t *testing.T, sys *rat.TONStakingSystem) {
	t.Log("Setting RAT trigger probability to 100%...")

	// RAT owner is deployer (Account #1)
	ratOwner := common.HexToAddress("0x70997970C51812dc3A010C7d01b50e0d17dc79C8")

	// Impersonate and fund owner
	cleanup := impersonateAccount(t, sys.L1Client, ratOwner)
	defer cleanup()
	fundAccount(t, sys.L1Client, ratOwner, "0x56BC75E2D63100000") // 100 ETH

	// RAT ABI for setRatTriggerProbability
	ratABI, err := abi.JSON(strings.NewReader(`[
		{"inputs":[{"internalType":"uint256","name":"probability","type":"uint256"}],"name":"setRatTriggerProbability","outputs":[],"stateMutability":"nonpayable","type":"function"},
		{"inputs":[],"name":"ratTriggerProbability","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}
	]`))
	require.NoError(t, err)

	gasPrice, err := sys.L1Client.SuggestGasPrice(sys.Ctx)
	require.NoError(t, err)

	// Set probability to 1e27 (100%)
	ray := new(big.Int).Exp(big.NewInt(10), big.NewInt(27), nil) // 1e27
	callData, err := ratABI.Pack("setRatTriggerProbability", ray)
	require.NoError(t, err)

	txArgs := map[string]any{
		"from":     ratOwner,
		"to":       sys.Addresses.RATProxy,
		"gas":      "0x100000", // 1M gas
		"gasPrice": "0x" + gasPrice.Text(16),
		"data":     "0x" + common.Bytes2Hex(callData),
	}

	var txHash common.Hash
	err = sys.L1Client.Client().Call(&txHash, "eth_sendTransaction", txArgs)
	require.NoError(t, err, "Failed to send setRatTriggerProbability")

	waitForTransactionReceipt(t, sys.Ctx, sys.L1Client, txHash, "setRatTriggerProbability")

	// Verify the setting
	verifyData, _ := ratABI.Pack("ratTriggerProbability")
	resultBytes, err := sys.L1Client.CallContract(sys.Ctx, ethereum.CallMsg{
		To:   &sys.Addresses.RATProxy,
		Data: verifyData,
	}, nil)
	require.NoError(t, err)

	var actualProbability *big.Int
	ratABI.UnpackIntoInterface(&actualProbability, "ratTriggerProbability", resultBytes)
	t.Logf("✓ RAT trigger probability set to: %s (1e27 = %s)", actualProbability.String(), ray.String())
	require.Equal(t, ray.String(), actualProbability.String(), "RAT trigger probability should be 1e27")
}

// initializeOptimismContracts initializes Optimism contracts at runtime.
//
// This function initializes:
// - MockAnchorStateRegistry.initialize(systemConfig, disputeGameFactory, anchorRoot, gameType)
// - DisputeGameFactory.setRAT(ratProxy)
// - DisputeGameFactory.setInitBond(gameType, bond)
func initializeOptimismContracts(t *testing.T, sys *rat.TONStakingSystem) {
	t.Log("Initializing Optimism contracts at runtime...")

	// Use Optimism deployer (Account #0) for Optimism contracts
	optimismDeployer := common.HexToAddress("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266")

	// Impersonate and fund deployer
	cleanup := impersonateAccount(t, sys.L1Client, optimismDeployer)
	defer cleanup()
	fundAccount(t, sys.L1Client, optimismDeployer, "0x56BC75E2D63100000") // 100 ETH

	gasPrice, err := sys.L1Client.SuggestGasPrice(sys.Ctx)
	require.NoError(t, err)

	// Helper to send transaction
	sendTx := func(to common.Address, callData []byte, description string) {
		txArgs := map[string]any{
			"from":     optimismDeployer,
			"to":       to,
			"gas":      "0x100000", // 1M gas
			"gasPrice": "0x" + gasPrice.Text(16),
			"data":     "0x" + common.Bytes2Hex(callData),
		}

		var txHash common.Hash
		err := sys.L1Client.Client().Call(&txHash, "eth_sendTransaction", txArgs)
		require.NoError(t, err, "Failed to send "+description)

		waitForTransactionReceipt(t, sys.Ctx, sys.L1Client, txHash, description)
	}

	// ===========================================
	// 1. Initialize MockAnchorStateRegistry
	// ===========================================
	if sys.Addresses.AnchorStateRegistry != (common.Address{}) {
		asrABI, err := abi.JSON(strings.NewReader(`[
			{"inputs":[{"internalType":"address","name":"_systemConfig","type":"address"},{"internalType":"address","name":"_disputeGameFactory","type":"address"},{"internalType":"bytes32","name":"_startingAnchorRoot","type":"bytes32"},{"internalType":"uint32","name":"_startingRespectedGameType","type":"uint32"}],"name":"initialize","outputs":[],"stateMutability":"nonpayable","type":"function"}
		]`))
		require.NoError(t, err)

		// Initialize with systemConfig, disputeGameFactory, zero anchor root, game type 0
		initData, err := asrABI.Pack("initialize",
			sys.Addresses.SystemConfig,
			sys.Addresses.DisputeGameFactory,
			[32]byte{}, // startingAnchorRoot (zero for devnet)
			uint32(0),  // startingRespectedGameType
		)
		require.NoError(t, err)
		sendTx(sys.Addresses.AnchorStateRegistry, initData, "MockAnchorStateRegistry.initialize")
	} else {
		t.Log("Note: AnchorStateRegistry address not available, skipping initialization")
	}

	// ===========================================
	// 2. DisputeGameFactory.setRAT() and setSystemConfig()
	// ===========================================
	dgfABI, err := abi.JSON(strings.NewReader(`[
		{"inputs":[{"internalType":"address","name":"_rat","type":"address"}],"name":"setRAT","outputs":[],"stateMutability":"nonpayable","type":"function"},
		{"inputs":[{"internalType":"address","name":"_systemConfig","type":"address"}],"name":"setSystemConfig","outputs":[],"stateMutability":"nonpayable","type":"function"},
		{"inputs":[{"internalType":"uint32","name":"_gameType","type":"uint32"},{"internalType":"uint256","name":"_initBond","type":"uint256"}],"name":"setInitBond","outputs":[],"stateMutability":"nonpayable","type":"function"}
	]`))
	require.NoError(t, err)

	// Set RAT on DisputeGameFactory
	setRATData, err := dgfABI.Pack("setRAT", sys.Addresses.RATProxy)
	require.NoError(t, err)
	sendTx(sys.Addresses.DisputeGameFactory, setRATData, "DisputeGameFactory.setRAT")

	// Set SystemConfig on DisputeGameFactory
	setSystemConfigData, err := dgfABI.Pack("setSystemConfig", sys.Addresses.SystemConfig)
	require.NoError(t, err)
	sendTx(sys.Addresses.DisputeGameFactory, setSystemConfigData, "DisputeGameFactory.setSystemConfig")

	// ===========================================
	// 3. DisputeGameFactory.setInitBond()
	// ===========================================
	// Game type 0, init bond 0.08 ETH
	gameType := uint32(0)
	initBond := big.NewInt(80000000000000000) // 0.08 ETH

	setInitBondData, err := dgfABI.Pack("setInitBond", gameType, initBond)
	require.NoError(t, err)
	sendTx(sys.Addresses.DisputeGameFactory, setInitBondData, "DisputeGameFactory.setInitBond")

	t.Log("✓ Optimism contracts initialized")
}

// registerSystemConfigInL1BridgeRegistry sets up runtime configuration for Optimism integration via transactions.
//
// NOTE: RAT.setL1BridgeRegistry() is already called in Genesis (pure TON staking config).
// This function only handles SystemConfig registration (Optimism integration):
// - L1BridgeRegistry.addManager() - grants manager role to deployer
// - L1BridgeRegistry.registerRollupConfigByManager() - registers SystemConfig with DisputeGameFactory mapping
func registerSystemConfigInL1BridgeRegistry(t *testing.T, sys *rat.TONStakingSystem, _ *bind.TransactOpts) {
	t.Log("Setting up Optimism integration via transactions (SystemConfig registration)...")

	deployer := common.HexToAddress("0x70997970C51812dc3A010C7d01b50e0d17dc79C8") // TON Staking deployer

	// Impersonate and fund deployer
	cleanup := impersonateAccount(t, sys.L1Client, deployer)
	defer cleanup()
	fundAccount(t, sys.L1Client, deployer, "0x56BC75E2D63100000") // 100 ETH

	gasPrice, err := sys.L1Client.SuggestGasPrice(sys.Ctx)
	require.NoError(t, err)

	// NOTE: RAT.setL1BridgeRegistry() is already called in Genesis script (_setupCrossReferences)
	// No need to call it again at runtime.

	// ===========================================
	// Call L1BridgeRegistry.addManager() to grant manager role (if not already granted)
	// ===========================================
	l1BridgeRegistryABI, err := abi.JSON(strings.NewReader(`[
		{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"addManager","outputs":[],"stateMutability":"nonpayable","type":"function"},
		{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"isManager","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},
		{"inputs":[{"internalType":"address","name":"rollupConfig","type":"address"},{"internalType":"uint8","name":"rollupType","type":"uint8"},{"internalType":"address","name":"l2TON","type":"address"},{"internalType":"string","name":"name","type":"string"}],"name":"registerRollupConfigByManager","outputs":[],"stateMutability":"nonpayable","type":"function"},
		{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"rollupConfigWithDisputeGameFactory","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"}
	]`))
	require.NoError(t, err)

	// Check if deployer is already a manager
	callData, err := l1BridgeRegistryABI.Pack("isManager", deployer)
	require.NoError(t, err)

	var isManagerResult string
	err = sys.L1Client.Client().Call(&isManagerResult, "eth_call", map[string]any{
		"to":   sys.Addresses.L1BridgeRegistryProxy,
		"data": "0x" + common.Bytes2Hex(callData),
	}, "latest")
	require.NoError(t, err, "Failed to check isManager")

	// Parse the result (32 bytes boolean)
	isManager := isManagerResult != "0x0000000000000000000000000000000000000000000000000000000000000000" && isManagerResult != "0x"

	// Prepare transaction arguments (will be reused for multiple transactions)
	var txHash common.Hash
	txArgs := map[string]any{
		"from":     deployer,
		"to":       sys.Addresses.L1BridgeRegistryProxy,
		"gas":      "0x100000",
		"gasPrice": "0x" + gasPrice.Text(16),
	}

	// Add deployer as manager only if not already a manager
	if !isManager {
		t.Log("Adding deployer as manager...")
		callData, err = l1BridgeRegistryABI.Pack("addManager", deployer)
		require.NoError(t, err)

		txArgs["data"] = "0x" + common.Bytes2Hex(callData)

		err = sys.L1Client.Client().Call(&txHash, "eth_sendTransaction", txArgs)
		require.NoError(t, err, "Failed to send L1BridgeRegistry.addManager")

		waitForTransactionReceipt(t, sys.Ctx, sys.L1Client, txHash, "L1BridgeRegistry.addManager")
	} else {
		t.Log("Deployer is already a manager (set in genesis), skipping addManager call")
	}

	// ===========================================
	// Call L1BridgeRegistry.registerRollupConfigByManager() via transaction
	// ===========================================
	// TYPE 3: OPTIMISM_BEDROCK_WITH_DISPUTE_GAME
	callData, err = l1BridgeRegistryABI.Pack("registerRollupConfigByManager",
		sys.Addresses.SystemConfig, // rollupConfig
		uint8(3),                   // rollupType = OPTIMISM_BEDROCK_WITH_DISPUTE_GAME
		sys.Addresses.TON,          // l2TON
		"DevnetOptimism",           // name
	)
	require.NoError(t, err)

	txArgs["data"] = "0x" + common.Bytes2Hex(callData)

	err = sys.L1Client.Client().Call(&txHash, "eth_sendTransaction", txArgs)
	require.NoError(t, err, "Failed to send L1BridgeRegistry.registerRollupConfigByManager")

	waitForTransactionReceipt(t, sys.Ctx, sys.L1Client, txHash, "L1BridgeRegistry.registerRollupConfigByManager")

	// ===========================================
	// Call SeigManager.migrateToV3() for V3 migration
	// ===========================================
	seigManagerMigrateABI, err := abi.JSON(strings.NewReader(`[
		{"inputs":[],"name":"migrateToV3","outputs":[],"stateMutability":"nonpayable","type":"function"},
		{"inputs":[],"name":"v3Migrated","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"}
	]`))
	require.NoError(t, err)

	// Check if already migrated
	checkMigrateData, _ := seigManagerMigrateABI.Pack("v3Migrated")
	migrateCheckResult, err := sys.L1Client.CallContract(sys.Ctx, ethereum.CallMsg{
		To:   &sys.Addresses.SeigManagerProxy,
		Data: checkMigrateData,
	}, nil)
	require.NoError(t, err)

	var alreadyMigrated bool
	seigManagerMigrateABI.UnpackIntoInterface(&alreadyMigrated, "v3Migrated", migrateCheckResult)

	if !alreadyMigrated {
		migrateData, _ := seigManagerMigrateABI.Pack("migrateToV3")
		txArgs["to"] = sys.Addresses.SeigManagerProxy
		txArgs["data"] = "0x" + common.Bytes2Hex(migrateData)

		err = sys.L1Client.Client().Call(&txHash, "eth_sendTransaction", txArgs)
		require.NoError(t, err, "Failed to send SeigManager.migrateToV3")

		waitForTransactionReceipt(t, sys.Ctx, sys.L1Client, txHash, "SeigManager.migrateToV3")
	} else {
		t.Log("✓ SeigManager already migrated to V3, skipping migrateToV3()")
	}

	// ===========================================
	// Verification
	// ===========================================
	verifyCallData, err := l1BridgeRegistryABI.Pack("rollupConfigWithDisputeGameFactory", sys.Addresses.DisputeGameFactory)
	require.NoError(t, err)

	resultBytes, err := sys.L1Client.CallContract(context.Background(), ethereum.CallMsg{
		To:   &sys.Addresses.L1BridgeRegistryProxy,
		Data: verifyCallData,
	}, nil)
	require.NoError(t, err)

	var rollupConfigFromCall common.Address
	err = l1BridgeRegistryABI.UnpackIntoInterface(&rollupConfigFromCall, "rollupConfigWithDisputeGameFactory", resultBytes)
	require.NoError(t, err)

	require.Equal(t, sys.Addresses.SystemConfig, rollupConfigFromCall,
		"rollupConfigWithDisputeGameFactory should return SystemConfig")
	t.Logf("✓ Verified: rollupConfigWithDisputeGameFactory[%s] = %s",
		sys.Addresses.DisputeGameFactory.Hex(), rollupConfigFromCall.Hex())
	t.Log("✓ L1BridgeRegistry configured via transactions")
}

// getTestDepositAmount returns the standard test deposit amount (50000 WTON in RAY, 27 decimals)
func getTestDepositAmount() *big.Int {
	depositAmount := new(big.Int).SetUint64(testDepositAmountTON)
	// WTON uses 27 decimals (RAY scale), not 18
	depositAmount.Mul(depositAmount, big.NewInt(1e18))
	depositAmount.Mul(depositAmount, big.NewInt(1e9)) // 1e27 total = 1e18 * 1e9
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

// createMockLayer2 dynamically creates a Layer2 (CandidateAddOn) for testing
func createMockLayer2(t *testing.T, sys *rat.TONStakingSystem) common.Address {
	// Get deployer auth using setupTestAccounts
	chainID, err := sys.L1Client.ChainID(context.Background())
	require.NoError(t, err)

	deployerKey, err := crypto.HexToECDSA("ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80")
	require.NoError(t, err)

	deployerAuth, err := bind.NewKeyedTransactorWithChainID(deployerKey, chainID)
	require.NoError(t, err)
	deployerAuth.GasLimit = 10000000 // 10M gas - high limit for complex contract deployment

	// Connect to contracts
	wton, err := bindings.NewWTON(sys.Addresses.WTON, sys.L1Client)
	require.NoError(t, err)

	layer2ManagerABI, err := abi.JSON(strings.NewReader(`[
		{"inputs":[{"internalType":"address","name":"rollupConfig","type":"address"},{"internalType":"uint256","name":"operatorDeposit","type":"uint256"},{"internalType":"bool","name":"flagTon","type":"bool"},{"internalType":"string","name":"memo","type":"string"}],"name":"registerCandidateAddOn","outputs":[],"stateMutability":"nonpayable","type":"function"},
		{"inputs":[{"internalType":"address","name":"rollupConfig","type":"address"}],"name":"getLayer2BySystemConfig","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"}
	]`))
	require.NoError(t, err)

	layer2Manager := bind.NewBoundContract(
		sys.Addresses.Layer2ManagerProxy,
		layer2ManagerABI,
		sys.L1Client, sys.L1Client, sys.L1Client,
	)

	// Calculate operator deposit (using the same logic as deployment script)
	// SeigManager minimumAmount = 1000.1e27 WTON (from deployment)
	// Minimum deposit: must be >= SeigManager minimumAmount
	operatorDeposit := new(big.Int)
	operatorDeposit.SetString("1001000000000000000000000000000", 10) // ~1001 WTON in RAY (27 decimals) > 1000.1 WTON minimum

	t.Logf("Creating MockLayer2 with operator deposit: %s WTON", operatorDeposit.String())

	// Debug: Check Layer2Manager storage variables
	layer2ManagerDebugABI, _ := abi.JSON(strings.NewReader(`[
		{"inputs":[],"name":"dao","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},
		{"inputs":[],"name":"operatorManagerFactory","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},
		{"inputs":[],"name":"depositManager","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"}
	]`))
	layer2ManagerDebug := bind.NewBoundContract(sys.Addresses.Layer2ManagerProxy, layer2ManagerDebugABI, sys.L1Client, sys.L1Client, sys.L1Client)
	var daoResult, operatorFactoryResult, depositManagerResult []interface{}
	debugOpts := &bind.CallOpts{Context: sys.Ctx}
	layer2ManagerDebug.Call(debugOpts, &daoResult, "dao")
	layer2ManagerDebug.Call(debugOpts, &operatorFactoryResult, "operatorManagerFactory")
	layer2ManagerDebug.Call(debugOpts, &depositManagerResult, "depositManager")
	if len(daoResult) > 0 {
		t.Logf("DEBUG: Layer2Manager.dao = %s", daoResult[0].(common.Address).Hex())
	}
	if len(operatorFactoryResult) > 0 {
		t.Logf("DEBUG: Layer2Manager.operatorManagerFactory = %s", operatorFactoryResult[0].(common.Address).Hex())
	}
	if len(depositManagerResult) > 0 {
		t.Logf("DEBUG: Layer2Manager.depositManager = %s", depositManagerResult[0].(common.Address).Hex())
	}

	// Debug: Check DAO storage variables
	daoDebugABI, _ := abi.JSON(strings.NewReader(`[
		{"inputs":[],"name":"candidateAddOnFactory","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},
		{"inputs":[],"name":"layer2Manager","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},
		{"inputs":[],"name":"layer2Registry","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},
		{"inputs":[],"name":"seigManager","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"}
	]`))
	if len(daoResult) > 0 {
		daoAddress := daoResult[0].(common.Address)
		daoDebug := bind.NewBoundContract(daoAddress, daoDebugABI, sys.L1Client, sys.L1Client, sys.L1Client)
		var candidateAddOnFactoryResult, daoLayer2ManagerResult, layer2RegistryResult, seigManagerResult []any
		daoDebug.Call(debugOpts, &candidateAddOnFactoryResult, "candidateAddOnFactory")
		daoDebug.Call(debugOpts, &daoLayer2ManagerResult, "layer2Manager")
		daoDebug.Call(debugOpts, &layer2RegistryResult, "layer2Registry")
		daoDebug.Call(debugOpts, &seigManagerResult, "seigManager")
		if len(candidateAddOnFactoryResult) > 0 {
			t.Logf("DEBUG: DAO.candidateAddOnFactory = %s", candidateAddOnFactoryResult[0].(common.Address).Hex())
		}
		if len(daoLayer2ManagerResult) > 0 {
			t.Logf("DEBUG: DAO.layer2Manager = %s (expected: %s)", daoLayer2ManagerResult[0].(common.Address).Hex(), sys.Addresses.Layer2ManagerProxy.Hex())
		}
		if len(layer2RegistryResult) > 0 {
			t.Logf("DEBUG: DAO.layer2Registry = %s", layer2RegistryResult[0].(common.Address).Hex())
		}
		if len(seigManagerResult) > 0 {
			t.Logf("DEBUG: DAO.seigManager = %s", seigManagerResult[0].(common.Address).Hex())
		}

		// Debug: Check CandidateAddOnFactory storage (inside daoResult block)
		if len(candidateAddOnFactoryResult) > 0 {
			caofAddress := candidateAddOnFactoryResult[0].(common.Address)
			caofDebugABI, _ := abi.JSON(strings.NewReader(`[
				{"inputs":[],"name":"daoCommittee","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},
				{"inputs":[],"name":"candidateAddOnImp","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},
				{"inputs":[],"name":"depositManager","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},
				{"inputs":[],"name":"ton","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},
				{"inputs":[],"name":"wton","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},
				{"inputs":[],"name":"onDemandL1BridgeRegistry","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"}
			]`))
			caofDebug := bind.NewBoundContract(caofAddress, caofDebugABI, sys.L1Client, sys.L1Client, sys.L1Client)
			var caofDaoCommittee, caofCandidateImpl, caofDepositMgr, caofTon, caofWton, caofL1Bridge []any
			caofDebug.Call(debugOpts, &caofDaoCommittee, "daoCommittee")
			caofDebug.Call(debugOpts, &caofCandidateImpl, "candidateAddOnImp")
			caofDebug.Call(debugOpts, &caofDepositMgr, "depositManager")
			caofDebug.Call(debugOpts, &caofTon, "ton")
			caofDebug.Call(debugOpts, &caofWton, "wton")
			caofDebug.Call(debugOpts, &caofL1Bridge, "onDemandL1BridgeRegistry")
			if len(caofDaoCommittee) > 0 {
				t.Logf("DEBUG: CandidateAddOnFactory.daoCommittee = %s (expected: %s)", caofDaoCommittee[0].(common.Address).Hex(), daoAddress.Hex())
			}
			if len(caofCandidateImpl) > 0 {
				t.Logf("DEBUG: CandidateAddOnFactory.candidateAddOnImp = %s", caofCandidateImpl[0].(common.Address).Hex())
			}
			if len(caofDepositMgr) > 0 {
				t.Logf("DEBUG: CandidateAddOnFactory.depositManager = %s", caofDepositMgr[0].(common.Address).Hex())
			}
			if len(caofTon) > 0 {
				t.Logf("DEBUG: CandidateAddOnFactory.ton = %s", caofTon[0].(common.Address).Hex())
			}
			if len(caofWton) > 0 {
				t.Logf("DEBUG: CandidateAddOnFactory.wton = %s", caofWton[0].(common.Address).Hex())
			}
			if len(caofL1Bridge) > 0 {
				t.Logf("DEBUG: CandidateAddOnFactory.onDemandL1BridgeRegistry = %s", caofL1Bridge[0].(common.Address).Hex())
			}
		}

		// Debug: Check Layer2Registry MINTER_ROLE for DAO
		if len(layer2RegistryResult) > 0 {
			layer2RegistryAddr := layer2RegistryResult[0].(common.Address)
			// MINTER_ROLE = keccak256("MINTER") - from AuthRole.sol
			minterRole := crypto.Keccak256Hash([]byte("MINTER"))
			// DEFAULT_ADMIN_ROLE = 0x00
			defaultAdminRole := common.Hash{}
			l2rDebugABI, _ := abi.JSON(strings.NewReader(`[
				{"inputs":[{"internalType":"bytes32","name":"role","type":"bytes32"},{"internalType":"address","name":"account","type":"address"}],"name":"hasRole","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},
				{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"isAdmin","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"}
			]`))
			l2rDebug := bind.NewBoundContract(layer2RegistryAddr, l2rDebugABI, sys.L1Client, sys.L1Client, sys.L1Client)
			var hasRoleResult, isAdminResult, hasAdminRoleDeployer []any
			// tonStakingDeployer = Account #1
			tonStakingDeployer := common.HexToAddress("0x70997970C51812dc3A010C7d01b50e0d17dc79C8")
			l2rDebug.Call(debugOpts, &hasRoleResult, "hasRole", minterRole, daoAddress)
			l2rDebug.Call(debugOpts, &isAdminResult, "isAdmin", daoAddress)
			l2rDebug.Call(debugOpts, &hasAdminRoleDeployer, "hasRole", defaultAdminRole, tonStakingDeployer)
			if len(hasRoleResult) > 0 {
				t.Logf("DEBUG: Layer2Registry.hasRole(MINTER_ROLE, DAO=%s) = %v", daoAddress.Hex(), hasRoleResult[0].(bool))
			}
			if len(isAdminResult) > 0 {
				t.Logf("DEBUG: Layer2Registry.isAdmin(DAO=%s) = %v", daoAddress.Hex(), isAdminResult[0].(bool))
			}
			if len(hasAdminRoleDeployer) > 0 {
				t.Logf("DEBUG: Layer2Registry.hasRole(DEFAULT_ADMIN_ROLE, deployer=%s) = %v", tonStakingDeployer.Hex(), hasAdminRoleDeployer[0].(bool))
			}
			// Also check SeigManager MINTER_ROLE
			var hasMinterRoleSeigManager []any
			l2rDebug.Call(debugOpts, &hasMinterRoleSeigManager, "hasRole", minterRole, seigManagerResult[0].(common.Address))
			if len(hasMinterRoleSeigManager) > 0 {
				t.Logf("DEBUG: Layer2Registry.hasRole(MINTER_ROLE, SeigManager=%s) = %v", seigManagerResult[0].(common.Address).Hex(), hasMinterRoleSeigManager[0].(bool))
			}
		}
	}

	// Debug: Check L1BridgeRegistry.getRollupInfo before creating Layer2
	debugABI, _ := abi.JSON(strings.NewReader(`[
		{"inputs":[{"internalType":"address","name":"rollupConfig","type":"address"}],"name":"getRollupInfo","outputs":[{"internalType":"uint8","name":"type_","type":"uint8"},{"internalType":"address","name":"l2TON_","type":"address"},{"internalType":"bool","name":"rejectedSeigs_","type":"bool"},{"internalType":"bool","name":"rejectedL2Deposit_","type":"bool"},{"internalType":"string","name":"name_","type":"string"}],"stateMutability":"view","type":"function"}
	]`))
	debugContract := bind.NewBoundContract(sys.Addresses.L1BridgeRegistryProxy, debugABI, sys.L1Client, sys.L1Client, sys.L1Client)
	var rollupInfoResult []any
	debugCallOpts := &bind.CallOpts{Context: sys.Ctx}
	debugErr := debugContract.Call(debugCallOpts, &rollupInfoResult, "getRollupInfo", sys.Addresses.SystemConfig)
	if debugErr != nil {
		t.Logf("⚠️ getRollupInfo error: %v", debugErr)
	} else {
		rollupType := rollupInfoResult[0].(uint8)
		l2TON := rollupInfoResult[1].(common.Address)
		t.Logf("DEBUG: L1BridgeRegistry.getRollupInfo(%s) = type=%d, l2TON=%s", sys.Addresses.SystemConfig.Hex(), rollupType, l2TON.Hex())
	}

	// Runtime permission setup: Grant MINTER_ROLE to DAO on Layer2Registry
	// (This should be done in genesis but vm.dumpState doesn't capture broadcast transactions)
	// Use TON Staking deployer (Account #1) who has DEFAULT_ADMIN_ROLE on Layer2Registry
	if len(daoResult) > 0 {
		daoAddr := daoResult[0].(common.Address)
		// MINTER_ROLE = keccak256("MINTER") - from AuthRole.sol
		minterRole := crypto.Keccak256Hash([]byte("MINTER"))

		// Check if DAO already has MINTER_ROLE
		hasRoleABI, _ := abi.JSON(strings.NewReader(`[
			{"inputs":[{"internalType":"bytes32","name":"role","type":"bytes32"},{"internalType":"address","name":"account","type":"address"}],"name":"hasRole","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},
			{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"addMinter","outputs":[],"stateMutability":"nonpayable","type":"function"}
		]`))
		layer2RegistryContract := bind.NewBoundContract(sys.Addresses.Layer2RegistryProxy, hasRoleABI, sys.L1Client, sys.L1Client, sys.L1Client)

		var hasMinterRoleResult []any
		checkOpts := &bind.CallOpts{Context: sys.Ctx}
		layer2RegistryContract.Call(checkOpts, &hasMinterRoleResult, "hasRole", minterRole, daoAddr)

		daoHasMinterRole := len(hasMinterRoleResult) > 0 && hasMinterRoleResult[0].(bool)
		t.Logf("DEBUG: Layer2Registry.hasRole(MINTER_ROLE, DAO=%s) = %v (before addMinter)", daoAddr.Hex(), daoHasMinterRole)

		if !daoHasMinterRole {
			// Account #1 = TON Staking deployer (has admin on Layer2Registry)
			tonDeployerKey, _ := crypto.HexToECDSA("59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d")
			tonDeployerAuth, _ := bind.NewKeyedTransactorWithChainID(tonDeployerKey, chainID)
			tonDeployerAuth.GasLimit = 500000

			addMinterTx, err := layer2RegistryContract.Transact(tonDeployerAuth, "addMinter", daoAddr)
			require.NoError(t, err)
			addMinterReceipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, addMinterTx)
			require.NoError(t, err)
			require.Equal(t, uint64(1), addMinterReceipt.Status, "Layer2Registry.addMinter(DAO) should succeed")
			t.Logf("✓ Runtime: Layer2Registry.addMinter(DAO=%s) done by tonDeployer", daoAddr.Hex())
		} else {
			t.Logf("✓ DAO already has MINTER_ROLE on Layer2Registry, skipping addMinter")
		}
	}

	// Additional permission checks
	t.Log("=== Additional Permission Checks ===")

	// 1. SeigManager.registry() should return Layer2RegistryProxy
	seigDebugABI, _ := abi.JSON(strings.NewReader(`[
		{"inputs":[],"name":"registry","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},
		{"inputs":[],"name":"factory","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"}
	]`))
	seigDebug := bind.NewBoundContract(sys.Addresses.SeigManagerProxy, seigDebugABI, sys.L1Client, sys.L1Client, sys.L1Client)
	var seigRegistryResult, seigFactoryResult []any
	checkOpts := &bind.CallOpts{Context: sys.Ctx}
	seigDebug.Call(checkOpts, &seigRegistryResult, "registry")
	seigDebug.Call(checkOpts, &seigFactoryResult, "factory")
	if len(seigRegistryResult) > 0 {
		registryAddr := seigRegistryResult[0].(common.Address)
		t.Logf("DEBUG: SeigManager.registry = %s (expected: %s) [match: %v]",
			registryAddr.Hex(), sys.Addresses.Layer2RegistryProxy.Hex(),
			registryAddr == sys.Addresses.Layer2RegistryProxy)
	}
	if len(seigFactoryResult) > 0 {
		coinageFactoryAddr := seigFactoryResult[0].(common.Address)
		t.Logf("DEBUG: SeigManager.factory (CoinageFactory) = %s", coinageFactoryAddr.Hex())

		// Check CoinageFactory.autoCoinageLogic
		cfDebugABI, _ := abi.JSON(strings.NewReader(`[
			{"inputs":[],"name":"autoCoinageLogic","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"}
		]`))
		cfDebug := bind.NewBoundContract(coinageFactoryAddr, cfDebugABI, sys.L1Client, sys.L1Client, sys.L1Client)
		var coinageLogicResult []any
		cfDebug.Call(checkOpts, &coinageLogicResult, "autoCoinageLogic")
		if len(coinageLogicResult) > 0 {
			t.Logf("DEBUG: CoinageFactory.autoCoinageLogic = %s", coinageLogicResult[0].(common.Address).Hex())
		}
	}

	// Check SeigManager.minimumAmount
	seigMinAmountABI, _ := abi.JSON(strings.NewReader(`[
		{"inputs":[],"name":"minimumAmount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}
	]`))
	seigMinAmountContract := bind.NewBoundContract(sys.Addresses.SeigManagerProxy, seigMinAmountABI, sys.L1Client, sys.L1Client, sys.L1Client)
	var seigMinAmountResult []any
	seigMinAmountContract.Call(checkOpts, &seigMinAmountResult, "minimumAmount")
	if len(seigMinAmountResult) > 0 {
		t.Logf("DEBUG: SeigManager.minimumAmount = %s WTON", seigMinAmountResult[0].(*big.Int).String())
	}

	// 2. WTON.isMinter(SeigManager)
	wtonDebugABI, _ := abi.JSON(strings.NewReader(`[
		{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"isMinter","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"}
	]`))
	wtonDebug := bind.NewBoundContract(sys.Addresses.WTON, wtonDebugABI, sys.L1Client, sys.L1Client, sys.L1Client)
	var wtonIsMinterResult []any
	wtonDebug.Call(checkOpts, &wtonIsMinterResult, "isMinter", sys.Addresses.SeigManagerProxy)
	if len(wtonIsMinterResult) > 0 {
		t.Logf("DEBUG: WTON.isMinter(SeigManager=%s) = %v", sys.Addresses.SeigManagerProxy.Hex(), wtonIsMinterResult[0].(bool))
	}

	// 3. OperatorManagerFactory.layer2Manager() should return Layer2ManagerProxy
	if len(operatorFactoryResult) > 0 {
		opFactoryAddr := operatorFactoryResult[0].(common.Address)
		opFactoryDebugABI, _ := abi.JSON(strings.NewReader(`[
			{"inputs":[],"name":"layer2Manager","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},
			{"inputs":[],"name":"depositManager","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},
			{"inputs":[],"name":"operatorManagerImp","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"}
		]`))
		opFactoryDebug := bind.NewBoundContract(opFactoryAddr, opFactoryDebugABI, sys.L1Client, sys.L1Client, sys.L1Client)
		var opFactoryL2MResult, opFactoryDepositResult, opFactoryImpResult []any
		opFactoryDebug.Call(checkOpts, &opFactoryL2MResult, "layer2Manager")
		opFactoryDebug.Call(checkOpts, &opFactoryDepositResult, "depositManager")
		opFactoryDebug.Call(checkOpts, &opFactoryImpResult, "operatorManagerImp")
		if len(opFactoryL2MResult) > 0 {
			l2mAddr := opFactoryL2MResult[0].(common.Address)
			t.Logf("DEBUG: OperatorManagerFactory.layer2Manager = %s (expected: %s) [match: %v]",
				l2mAddr.Hex(), sys.Addresses.Layer2ManagerProxy.Hex(),
				l2mAddr == sys.Addresses.Layer2ManagerProxy)
		}
		if len(opFactoryDepositResult) > 0 {
			t.Logf("DEBUG: OperatorManagerFactory.depositManager = %s", opFactoryDepositResult[0].(common.Address).Hex())
		}
		if len(opFactoryImpResult) > 0 {
			t.Logf("DEBUG: OperatorManagerFactory.operatorManagerImp = %s", opFactoryImpResult[0].(common.Address).Hex())
		}
	}

	// 4. SystemConfig.unsafeBlockSigner() - needed for OperatorManager creation
	sysConfigDebugABI, _ := abi.JSON(strings.NewReader(`[
		{"inputs":[],"name":"unsafeBlockSigner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"}
	]`))
	sysConfigDebug := bind.NewBoundContract(sys.Addresses.SystemConfig, sysConfigDebugABI, sys.L1Client, sys.L1Client, sys.L1Client)
	var unsafeBlockSignerResult []any
	sysConfigDebug.Call(checkOpts, &unsafeBlockSignerResult, "unsafeBlockSigner")
	if len(unsafeBlockSignerResult) > 0 {
		t.Logf("DEBUG: SystemConfig.unsafeBlockSigner = %s", unsafeBlockSignerResult[0].(common.Address).Hex())
	}

	t.Log("=== End Permission Checks ===")

	// Mint WTON to deployer
	mintTx, err := wton.Mint(deployerAuth, deployerAuth.From, operatorDeposit)
	require.NoError(t, err)
	_, err = bind.WaitMined(sys.Ctx, sys.L1Client, mintTx)
	require.NoError(t, err)
	t.Logf("✓ Minted %s WTON to deployer", operatorDeposit.String())

	// Register SystemConfig to L1BridgeRegistry before registerCandidateAddOn
	t.Log("=== Registering SystemConfig to L1BridgeRegistry ===")

	// Create L1BridgeRegistry contract binding
	l1BridgeRegistryABI, err := abi.JSON(strings.NewReader(`[
		{"inputs":[{"internalType":"address","name":"rollupConfig","type":"address"},{"internalType":"address","name":"bridge","type":"address"},{"internalType":"address","name":"portal","type":"address"},{"internalType":"uint256","name":"registryType","type":"uint256"}],"name":"registerRollupConfig","outputs":[],"stateMutability":"nonpayable","type":"function"},
		{"inputs":[{"internalType":"address","name":"rollupConfig","type":"address"}],"name":"getRollupInfo","outputs":[{"internalType":"uint8","name":"rollupType_","type":"uint8"},{"internalType":"address","name":"l2TON","type":"address"}],"stateMutability":"view","type":"function"}
	]`))
	require.NoError(t, err)

	l1BridgeRegistry := bind.NewBoundContract(sys.Addresses.L1BridgeRegistryProxy, l1BridgeRegistryABI, sys.L1Client, sys.L1Client, sys.L1Client)

	// Check if already registered (rollupType == 0 means not registered)
	var rollupInfoCheck []any
	checkOpts2 := &bind.CallOpts{Context: sys.Ctx}
	checkErr := l1BridgeRegistry.Call(checkOpts2, &rollupInfoCheck, "getRollupInfo", sys.Addresses.SystemConfig)
	require.NoError(t, checkErr)

	rollupType := uint8(0)
	if len(rollupInfoCheck) > 0 {
		rollupType = rollupInfoCheck[0].(uint8)
	}

	if rollupType == 0 {
		t.Log("SystemConfig not registered in L1BridgeRegistry, registering now...")

		// Use the owner account from genesis (has admin permissions)
		// This is the same pattern used in registerSystemConfigInL1BridgeRegistry
		owner := common.HexToAddress("0x70997970C51812dc3A010C7d01b50e0d17dc79C8") // TON Staking deployer from genesis

		// Impersonate and fund owner account
		cleanup := impersonateAccount(t, sys.L1Client, owner)
		defer cleanup()
		fundAccount(t, sys.L1Client, owner, "0x56BC75E2D63100000") // 100 ETH

		gasPrice, err := sys.L1Client.SuggestGasPrice(sys.Ctx)
		require.NoError(t, err)

		// Add manager and registrant roles to deployer
		l1BridgeRegistryRoleABI, err := abi.JSON(strings.NewReader(`[
			{"inputs":[{"internalType":"address","name":"manager","type":"address"}],"name":"addManager","outputs":[],"stateMutability":"nonpayable","type":"function"},
			{"inputs":[{"internalType":"address","name":"registrant","type":"address"}],"name":"addRegistrant","outputs":[],"stateMutability":"nonpayable","type":"function"},
			{"inputs":[{"internalType":"address","name":"manager","type":"address"}],"name":"isManager","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},
			{"inputs":[{"internalType":"address","name":"registrant","type":"address"}],"name":"isRegistrant","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"}
		]`))
		require.NoError(t, err)

		// Check if deployer is manager, if not add them
		var isManagerResult []any
		checkOpts3 := &bind.CallOpts{Context: sys.Ctx}
		l1BridgeRegistry.Call(checkOpts3, &isManagerResult, "isManager", deployerAuth.From)
		if len(isManagerResult) == 0 || !isManagerResult[0].(bool) {
			// Pack addManager call
			callData, err := l1BridgeRegistryRoleABI.Pack("addManager", deployerAuth.From)
			require.NoError(t, err)

			txArgs := map[string]any{
				"from":     owner,
				"to":       sys.Addresses.L1BridgeRegistryProxy,
				"gas":      "0x100000",
				"gasPrice": "0x" + gasPrice.Text(16),
				"data":     "0x" + common.Bytes2Hex(callData),
			}

			var txHash common.Hash
			err = sys.L1Client.Client().Call(&txHash, "eth_sendTransaction", txArgs)
			require.NoError(t, err)
			waitForTransactionReceipt(t, sys.Ctx, sys.L1Client, txHash, "L1BridgeRegistry.addManager")
			t.Log("✓ Added deployer as manager")
		} else {
			t.Log("✓ Deployer already has manager role")
		}

		// Check if deployer is registrant, if not add them
		// Note: addRegistrant can only be called by a manager, so deployer (now a manager) adds themselves
		var isRegistrantResult []any
		l1BridgeRegistry.Call(checkOpts3, &isRegistrantResult, "isRegistrant", deployerAuth.From)
		if len(isRegistrantResult) == 0 || !isRegistrantResult[0].(bool) {
			// Pack addRegistrant call - deployer (now manager) adds themselves as registrant
			callData, err := l1BridgeRegistryRoleABI.Pack("addRegistrant", deployerAuth.From)
			require.NoError(t, err)

			txArgs := map[string]any{
				"from":     deployerAuth.From, // deployer is now a manager, can call addRegistrant
				"to":       sys.Addresses.L1BridgeRegistryProxy,
				"gas":      "0x100000",
				"gasPrice": "0x" + gasPrice.Text(16),
				"data":     "0x" + common.Bytes2Hex(callData),
			}

			var txHash common.Hash
			err = sys.L1Client.Client().Call(&txHash, "eth_sendTransaction", txArgs)
			require.NoError(t, err)
			waitForTransactionReceipt(t, sys.Ctx, sys.L1Client, txHash, "L1BridgeRegistry.addRegistrant")
			t.Log("✓ Added deployer as registrant")
		} else {
			t.Log("✓ Deployer already has registrant role")
		}

		// Now register the rollup config using deployer account (which now has permissions)
		// Use registerRollupConfigByManager instead (TYPE 3)
		registerByManagerABI, err := abi.JSON(strings.NewReader(`[
			{"inputs":[{"internalType":"address","name":"rollupConfig","type":"address"},{"internalType":"uint8","name":"rollupType","type":"uint8"},{"internalType":"address","name":"l2TON","type":"address"},{"internalType":"string","name":"name","type":"string"}],"name":"registerRollupConfigByManager","outputs":[],"stateMutability":"nonpayable","type":"function"}
		]`))
		require.NoError(t, err)

		callData, err := registerByManagerABI.Pack("registerRollupConfigByManager",
			sys.Addresses.SystemConfig,
			uint8(3), // TYPE 3: OPTIMISM_BEDROCK_WITH_DISPUTE_GAME
			sys.Addresses.TON,
			"TestOptimism",
		)
		require.NoError(t, err)

		txArgs := map[string]any{
			"from":     deployerAuth.From,
			"to":       sys.Addresses.L1BridgeRegistryProxy,
			"gas":      "0x100000",
			"gasPrice": "0x" + gasPrice.Text(16),
			"data":     "0x" + common.Bytes2Hex(callData),
		}

		var txHash common.Hash
		err = sys.L1Client.Client().Call(&txHash, "eth_sendTransaction", txArgs)
		require.NoError(t, err)
		registerReceipt := waitForTransactionReceipt(t, sys.Ctx, sys.L1Client, txHash, "L1BridgeRegistry.registerRollupConfigByManager")
		require.Equal(t, uint64(1), registerReceipt.Status, "L1BridgeRegistry.registerRollupConfigByManager should succeed")
		t.Logf("✓ Registered SystemConfig to L1BridgeRegistry (type=3)")
	} else {
		t.Log("✓ SystemConfig already registered in L1BridgeRegistry")
	}

	// Approve WTON to Layer2Manager
	approveTx, err := wton.Approve(deployerAuth, sys.Addresses.Layer2ManagerProxy, operatorDeposit)
	require.NoError(t, err)
	approveReceipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, approveTx)
	require.NoError(t, err)
	require.Equal(t, uint64(1), approveReceipt.Status, "TON approval failed")

	// Step-by-step debugging
	t.Log("=== Step-by-step Debug ===")
	simulateOpts := &bind.CallOpts{
		Context: sys.Ctx,
		From:    deployerAuth.From,
	}

	// 1. Check availableRegister
	var availableResult []any
	layer2Manager.Call(simulateOpts, &availableResult, "availableRegister", sys.Addresses.SystemConfig)
	if len(availableResult) > 0 {
		t.Logf("DEBUG: Layer2Manager.availableRegister(%s) = %v", sys.Addresses.SystemConfig.Hex(), availableResult[0].(bool))
	}

	// 2. Check WTON balance of deployer
	var wtonBalance []any
	wtonABI, _ := abi.JSON(strings.NewReader(`[
		{"inputs":[{"internalType":"address","name":"owner","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},
		{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}
	]`))
	wtonContract := bind.NewBoundContract(sys.Addresses.WTON, wtonABI, sys.L1Client, sys.L1Client, sys.L1Client)
	wtonContract.Call(simulateOpts, &wtonBalance, "balanceOf", deployerAuth.From)
	if len(wtonBalance) > 0 {
		t.Logf("DEBUG: WTON.balanceOf(deployer) = %s", wtonBalance[0].(*big.Int).String())
	}

	// 3. Check WTON allowance to Layer2Manager
	var wtonAllowance []any
	wtonContract.Call(simulateOpts, &wtonAllowance, "allowance", deployerAuth.From, sys.Addresses.Layer2ManagerProxy)
	if len(wtonAllowance) > 0 {
		t.Logf("DEBUG: WTON.allowance(deployer, Layer2Manager) = %s", wtonAllowance[0].(*big.Int).String())
	}

	// 4. Check Layer2Manager.minimumInitialDepositAmount (it's public)
	var minDepositResult []any
	minDepositABI, _ := abi.JSON(strings.NewReader(`[
		{"inputs":[],"name":"minimumInitialDepositAmount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}
	]`))
	minDepositContract := bind.NewBoundContract(sys.Addresses.Layer2ManagerProxy, minDepositABI, sys.L1Client, sys.L1Client, sys.L1Client)
	minDepositContract.Call(simulateOpts, &minDepositResult, "minimumInitialDepositAmount")
	if len(minDepositResult) > 0 {
		t.Logf("DEBUG: Layer2Manager.minimumInitialDepositAmount = %s", minDepositResult[0].(*big.Int).String())
	}

	// 5. Simulate registerCandidateAddOn
	t.Log("=== Simulating registerCandidateAddOn with eth_call ===")
	var simulateResult []any
	simulateErr := layer2Manager.Call(simulateOpts, &simulateResult, "registerCandidateAddOn",
		sys.Addresses.SystemConfig, operatorDeposit, false, "OptimismL2")
	if simulateErr != nil {
		t.Logf("⚠️ Simulation failed: %v", simulateErr)
	} else {
		t.Log("✓ Simulation succeeded")
	}

	// Call registerCandidateAddOn
	registerTx, err := layer2Manager.Transact(
		deployerAuth,
		"registerCandidateAddOn",
		sys.Addresses.SystemConfig, // rollupConfig
		operatorDeposit,            // operatorDeposit
		false,                      // flagTon (false = use WTON)
		"OptimismL2",               // memo (string)
	)
	require.NoError(t, err)
	registerReceipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, registerTx)
	require.NoError(t, err)
	require.Equal(t, uint64(1), registerReceipt.Status, "registerCandidateAddOn should succeed")
	t.Log("✓ Called Layer2Manager.registerCandidateAddOn")

	// Get created Layer2 address
	callOpts := &bind.CallOpts{Context: sys.Ctx}
	var result []interface{}
	err = layer2Manager.Call(callOpts, &result, "getLayer2BySystemConfig", sys.Addresses.SystemConfig)
	require.NoError(t, err)
	layer2Address := result[0].(common.Address)

	t.Logf("✓ MockLayer2 created: %s", layer2Address.Hex())
	return layer2Address
}

// registerValidatorWithTON registers a validator with TON deposit (V3 method)
func registerValidatorWithTON(t *testing.T, sys *rat.TONStakingSystem, contracts *TestContracts, validatorAuth *bind.TransactOpts, depositAmount *big.Int) {
	// Step 1: Get or create MockLayer2 address
	layer2 := sys.Addresses.MockLayer2

	// If MockLayer2 not in genesis (offline mode), create it dynamically
	if layer2 == (common.Address{}) {
		t.Log("MockLayer2 not in genesis, creating dynamically...")
		layer2 = createMockLayer2(t, sys)
		sys.Addresses.MockLayer2 = layer2 // Update for future use
	}

	t.Logf("Layer2 address: %s", layer2.Hex())

	// Step 2: Increase deposit amount by 1% to account for coinage rounding
	// When staking 100, the actual staked amount may be slightly less due to share calculation
	adjustedAmount := new(big.Int).Mul(depositAmount, big.NewInt(101))
	adjustedAmount.Div(adjustedAmount, big.NewInt(100))
	t.Logf("Adjusted deposit amount: %s WTON (original: %s)", adjustedAmount.String(), depositAmount.String())

	// Step 3: Mint WTON to validator (for testing, we directly mint WTON instead of swapping TON)
	// In production, user would swap TON to WTON first
	mintTx, err := contracts.WTON.Mint(validatorAuth, validatorAuth.From, adjustedAmount)
	require.NoError(t, err)
	_, err = bind.WaitMined(sys.Ctx, sys.L1Client, mintTx)
	require.NoError(t, err)
	t.Logf("✓ Minted %s WTON to validator", adjustedAmount.String())

	// Step 4: Approve WTON to DepositManager using WTON's Approve method
	approveTx, err := contracts.WTON.Approve(validatorAuth, sys.Addresses.DepositManagerProxy, adjustedAmount)
	require.NoError(t, err)
	_, err = bind.WaitMined(sys.Ctx, sys.L1Client, approveTx)
	require.NoError(t, err)
	t.Logf("✓ Approved %s WTON to DepositManager", adjustedAmount.String())

	// Step 5: Deposit WTON to Layer2 via DepositManager
	depositTx, err := contracts.DepositManager.Transact(validatorAuth, "deposit", layer2, adjustedAmount)
	require.NoError(t, err)
	_, err = bind.WaitMined(sys.Ctx, sys.L1Client, depositTx)
	require.NoError(t, err)
	t.Logf("✓ Deposited %s WTON to Layer2", adjustedAmount.String())

	// Check actual staked amount immediately after deposit (using package-level stakeOfABI)
	stakeOfCallData, _ := stakeOfABI.Pack("stakeOf", layer2, validatorAuth.From)
	stakeOfResult, err := sys.L1Client.CallContract(sys.Ctx, ethereum.CallMsg{
		To:   &sys.Addresses.SeigManagerProxy,
		Data: stakeOfCallData,
	}, nil)
	require.NoError(t, err)
	var actualStaked *big.Int
	stakeOfABI.UnpackIntoInterface(&actualStaked, "stakeOf", stakeOfResult)
	t.Logf("✓ Actual staked amount immediately after deposit: %s WTON (deposited: %s WTON, diff: %s WTON)",
		actualStaked.String(),
		adjustedAmount.String(),
		new(big.Int).Sub(actualStaked, adjustedAmount).String())

	// Step 6: Register validator with RAT (no deposit needed, uses coinage balance)
	// Check staking balance before registration
	stakeBeforeReg, err := sys.L1Client.CallContract(sys.Ctx, ethereum.CallMsg{
		To:   &sys.Addresses.SeigManagerProxy,
		Data: stakeOfCallData,
	}, nil)
	require.NoError(t, err)
	var stakedBeforeReg *big.Int
	stakeOfABI.UnpackIntoInterface(&stakedBeforeReg, "stakeOf", stakeBeforeReg)
	t.Logf("✓ Staking balance BEFORE RAT registration: %s WTON", stakedBeforeReg.String())

	registerTx, err := contracts.RAT.RegisterValidator(validatorAuth, sys.Addresses.SystemConfig)
	require.NoError(t, err)
	registerReceipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, registerTx)
	require.NoError(t, err)
	require.Equal(t, uint64(1), registerReceipt.Status, "Validator registration failed")

	// Check staking balance after registration
	stakeAfterReg, err := sys.L1Client.CallContract(sys.Ctx, ethereum.CallMsg{
		To:   &sys.Addresses.SeigManagerProxy,
		Data: stakeOfCallData,
	}, nil)
	require.NoError(t, err)
	var stakedAfterReg *big.Int
	stakeOfABI.UnpackIntoInterface(&stakedAfterReg, "stakeOf", stakeAfterReg)
	t.Logf("✓ Staking balance AFTER RAT registration: %s WTON", stakedAfterReg.String())

	// Check if registration changed the staking balance
	if stakedAfterReg.Cmp(stakedBeforeReg) != 0 {
		diff := new(big.Int).Sub(stakedAfterReg, stakedBeforeReg)
		t.Logf("⚠ WARNING: Staking balance changed during registration by %s WTON", diff.String())
	}

	t.Logf("✓ Validator registered with RAT (collateral from staking: %s WTON)", stakedAfterReg.String())
}

// createDisputeGameWithWrongClaim creates a DisputeGame with a wrong root claim
func createDisputeGameWithWrongClaim(t *testing.T, sys *rat.TONStakingSystem, proposerAuth *bind.TransactOpts, l2BlockNumber uint64) (*types.Receipt, common.Address) {
	callOpts := &bind.CallOpts{Context: sys.Ctx}

	// Measure validator staking at START of this function (using package-level stakeOfABI)
	accounts := setupTestAccounts(t, sys)
	stakeCallData, _ := stakeOfABI.Pack("stakeOf", sys.Addresses.MockLayer2, accounts.Validator.Addr)
	stakeStartResult, _ := sys.L1Client.CallContract(sys.Ctx, ethereum.CallMsg{
		To:   &sys.Addresses.SeigManagerProxy,
		Data: stakeCallData,
	}, nil)
	var stakeStart *big.Int
	stakeOfABI.UnpackIntoInterface(&stakeStart, "stakeOf", stakeStartResult)
	t.Logf("  [createDisputeGameWithWrongClaim START] Validator stake: %s WTON", stakeStart.String())

	// Connect to DisputeGameFactory
	dgf, err := bindings.NewDisputeGameFactory(sys.Addresses.DisputeGameFactory, sys.L1Client)
	require.NoError(t, err)

	// Verify RAT is set on DisputeGameFactory (read from storage slot 52 directly)
	// Note: The Optimism DisputeGameFactory bytecode doesn't have rat() view function
	ratAddr, err := readDGFRatFromStorage(sys.L1Client, sys.Addresses.DisputeGameFactory)
	require.NoError(t, err)
	t.Logf("DisputeGameFactory RAT address (storage slot 52): %s", ratAddr.Hex())
	t.Logf("Expected RAT address: %s", sys.Addresses.RATProxy.Hex())
	require.Equal(t, sys.Addresses.RATProxy, ratAddr, "RAT address mismatch on DisputeGameFactory")

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

	// Measure validator staking at END of this function
	stakeEndResult, _ := sys.L1Client.CallContract(sys.Ctx, ethereum.CallMsg{
		To:   &sys.Addresses.SeigManagerProxy,
		Data: stakeCallData,
	}, nil)
	var stakeEnd *big.Int
	stakeOfABI.UnpackIntoInterface(&stakeEnd, "stakeOf", stakeEndResult)
	t.Logf("  [createDisputeGameWithWrongClaim END] Validator stake: %s WTON", stakeEnd.String())

	// Calculate change
	stakeChange := new(big.Int).Sub(stakeEnd, stakeStart)
	if stakeChange.Sign() != 0 {
		t.Logf("  ⚠️  STAKE CHANGED in createDisputeGameWithWrongClaim: %s WTON", stakeChange.String())
	}

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
func parseDisputeGameCreatedEvent(_ *testing.T, receipt *types.Receipt) common.Address {
	for _, log := range receipt.Logs {
		if log.Topics[0].Hex() == eventDisputeGameCreated {
			gameAddress := common.HexToAddress(log.Topics[1].Hex())
			return gameAddress
		}
	}
	return common.Address{}
}

// triggerRATDirectly triggers RAT.triggerAttentionTest directly by impersonating DisputeGameFactory
// This is used for testing when the DisputeGameFactory bytecode doesn't have RAT integration
func triggerRATDirectly(t *testing.T, sys *rat.TONStakingSystem, gameAddress common.Address, batchIndex uint32) *types.Receipt {
	// Impersonate and fund DisputeGameFactory
	cleanup := impersonateAccount(t, sys.L1Client, sys.Addresses.DisputeGameFactory)
	defer cleanup()
	t.Logf("✓ Impersonating DisputeGameFactory: %s", sys.Addresses.DisputeGameFactory.Hex())
	fundAccount(t, sys.L1Client, sys.Addresses.DisputeGameFactory, "0x56BC75E2D63100000") // 100 ETH

	// Get current block for blockHash
	currentBlock, err := sys.L1Client.BlockByNumber(sys.Ctx, nil)
	require.NoError(t, err)
	blockHash := currentBlock.Hash()

	// Create batchHash (using game address and batch index)
	batchHash := crypto.Keccak256Hash(gameAddress.Bytes(), big.NewInt(int64(batchIndex)).Bytes())

	// Build triggerAttentionTest call data
	ratABI, err := abi.JSON(strings.NewReader(bindings.RATABI))
	require.NoError(t, err)

	callData, err := ratABI.Pack("triggerAttentionTest",
		gameAddress,
		sys.Addresses.SystemConfig,
		batchIndex,
		batchHash,
		blockHash,
	)
	require.NoError(t, err)

	// Get gas price
	gasPrice, err := sys.L1Client.SuggestGasPrice(sys.Ctx)
	require.NoError(t, err)

	// Send transaction from DisputeGameFactory
	tx := types.NewTransaction(
		0, // nonce will be set automatically
		sys.Addresses.RATProxy,
		big.NewInt(0),
		3000000, // gas limit
		gasPrice,
		callData,
	)

	// Send transaction
	err = sys.L1Client.SendTransaction(sys.Ctx, tx)
	require.NoError(t, err)

	// Wait for receipt
	receipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, tx)
	require.NoError(t, err)

	return receipt
}

// submitEvidenceToRAT submits evidence to RAT contract and returns receipt
// Updated to use new signature: submitEvidence(address systemConfig, uint32 batchIndex, bytes evidence)
func submitEvidenceToRAT(t *testing.T, sys *rat.TONStakingSystem, contracts *TestContracts, validatorAuth *bind.TransactOpts, systemConfig common.Address, batchIndex uint32, evidenceData []byte) (*types.Receipt, error) {
	t.Logf("Submitting evidence: systemConfig=%s, batchIndex=%d, dataLen=%d", systemConfig.Hex(), batchIndex, len(evidenceData))

	evidenceTx, err := contracts.RAT.SubmitEvidence(validatorAuth, systemConfig, batchIndex, evidenceData)
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

	eventSig := crypto.Keccak256Hash([]byte("EvidenceSubmitted(bytes32,address,address,address,uint32)"))
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
						t.Logf("✓ Validator locked for RAT after evidence: %s", registration.LockedForRAT.String())
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

// High-Level Test Setup Helpers (Pattern 1)
// ============================================================================

type TestEnvironment struct {
	System    *rat.TONStakingSystem
	Accounts  *TestAccounts
	Contracts *TestContracts
	CallOpts  *bind.CallOpts
}

func setupTestEnvironment(t *testing.T, testName string) *TestEnvironment {
	t.Logf("=== Testing %s ===", testName)

	sys := rat.StartTONStakingSystem(t)
	callOpts := &bind.CallOpts{Context: sys.Ctx}

	accounts := setupTestAccounts(t, sys)
	contracts := connectTestContracts(t, sys)

	initializeOptimismContracts(t, sys)
	configureV3Parameters(t, sys)
	registerSystemConfigInL1BridgeRegistry(t, sys, accounts.Deployer.Auth)

	depositAmount := getTestDepositAmount()
	adjustMinimumCollateral(t, sys, contracts, accounts.Deployer.Auth, depositAmount)

	return &TestEnvironment{
		System:    sys,
		Accounts:  accounts,
		Contracts: contracts,
		CallOpts:  callOpts,
	}
}

// ============================================================================
// Contract Query Helpers (Pattern 3, 4)
// ============================================================================

func getValidatorStake(t *testing.T, sys *rat.TONStakingSystem, layer2, validator common.Address) *big.Int {
	// Using package-level stakeOfABI
	callData, err := stakeOfABI.Pack("stakeOf", layer2, validator)
	require.NoError(t, err)

	result, err := sys.L1Client.CallContract(sys.Ctx, ethereum.CallMsg{
		To:   &sys.Addresses.SeigManagerProxy,
		Data: callData,
	}, nil)
	require.NoError(t, err)

	var stake *big.Int
	err = stakeOfABI.UnpackIntoInterface(&stake, "stakeOf", result)
	require.NoError(t, err)

	return stake
}

type AttentionTestInfo struct {
	ValidatorAddress common.Address
	SystemConfig     common.Address
	BatchIndex       uint32
	BatchHash        [32]byte
	BondAmount       *big.Int
	CreatedAt        *big.Int
	Deadline         *big.Int
	Status           uint8
}

func getAttentionTestInfo(t *testing.T, sys *rat.TONStakingSystem, testID [32]byte) *AttentionTestInfo {
	getTestABI, err := abi.JSON(strings.NewReader(`[{"inputs":[{"internalType":"bytes32","name":"testId","type":"bytes32"}],"name":"getAttentionTest","outputs":[{"internalType":"address","name":"validatorAddress","type":"address"},{"internalType":"address","name":"systemConfig","type":"address"},{"internalType":"uint32","name":"batchIndex","type":"uint32"},{"internalType":"bytes32","name":"batchHash","type":"bytes32"},{"internalType":"uint256","name":"bondAmount","type":"uint256"},{"internalType":"uint256","name":"createdAt","type":"uint256"},{"internalType":"uint256","name":"deadline","type":"uint256"},{"internalType":"uint8","name":"status","type":"uint8"}],"stateMutability":"view","type":"function"}]`))
	require.NoError(t, err)

	callData, err := getTestABI.Pack("getAttentionTest", testID)
	require.NoError(t, err)

	result, err := sys.L1Client.CallContract(sys.Ctx, ethereum.CallMsg{
		To:   &sys.Addresses.RATProxy,
		Data: callData,
	}, nil)
	require.NoError(t, err)

	var info AttentionTestInfo
	err = getTestABI.UnpackIntoInterface(&info, "getAttentionTest", result)
	require.NoError(t, err)

	return &info
}

// ============================================================================
// Game Resolution Helpers (Pattern 5)
// ============================================================================

type GameResolutionResult struct {
	ClaimReceipts []*types.Receipt
	GameReceipt   *types.Receipt
}

func resolveGameWithClaims(
	t *testing.T,
	sys *rat.TONStakingSystem,
	game *bindings.FaultDisputeGame,
	auth *bind.TransactOpts,
	claimIndices []int64,
) *GameResolutionResult {
	result := &GameResolutionResult{
		ClaimReceipts: make([]*types.Receipt, 0, len(claimIndices)),
	}

	for _, idx := range claimIndices {
		tx, err := game.ResolveClaim(auth, big.NewInt(idx), big.NewInt(0))
		require.NoError(t, err)

		receipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, tx)
		require.NoError(t, err)

		result.ClaimReceipts = append(result.ClaimReceipts, receipt)
		t.Logf("✓ Resolved claim %d", idx)
	}

	tx, err := game.Resolve(auth)
	require.NoError(t, err)

	receipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, tx)
	require.NoError(t, err)

	result.GameReceipt = receipt
	t.Logf("✓ Game resolved (tx: %s)", tx.Hash().Hex())

	return result
}

// ============================================================================
// Event Parsing Helpers (Pattern 6)
// ============================================================================

type BondRestoredEventData struct {
	Found  bool
	Amount *big.Int
	TxName string
}

func findBondRestoredEvent(receipts []*types.Receipt, receiptNames []string) *BondRestoredEventData {
	bondRestoredEventSig := crypto.Keccak256Hash([]byte("BondRestored(bytes32,address,address,address,uint256)"))
	result := &BondRestoredEventData{Found: false}

	for idx, receipt := range receipts {
		for _, log := range receipt.Logs {
			if len(log.Topics) > 0 && log.Topics[0] == bondRestoredEventSig {
				result.Found = true
				result.TxName = receiptNames[idx]
				if len(log.Data) >= 32 {
					result.Amount = new(big.Int).SetBytes(log.Data[len(log.Data)-32:])
				}
				return result
			}
		}
	}

	return result
}
