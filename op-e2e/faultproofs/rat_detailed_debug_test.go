package faultproofs

import (
	"context"
	"math/big"
	"strings"
	"testing"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/stretchr/testify/require"

	"github.com/tokamak-network/ton-staking-v2/op-e2e/bindings"
	"github.com/tokamak-network/ton-staking-v2/op-e2e/e2eutils/rat"
)

// TestRAT_DetailedDebug performs detailed debugging of RAT trigger conditions
func TestRAT_DetailedDebug(t *testing.T) {
	t.Parallel()

	sys := rat.StartTONStakingSystem(t)
	callOpts := &bind.CallOpts{Context: sys.Ctx}

	t.Log("=== RAT Detailed Debug Test ===")

	// Setup
	accounts := setupTestAccounts(t, sys)
	contracts := connectTestContracts(t, sys)

	// Register SystemConfig in L1BridgeRegistry
	registerSystemConfigInL1BridgeRegistry(t, sys, accounts.Deployer.Auth)

	// Register validator
	depositAmount := getTestDepositAmount()
	adjustMinimumCollateral(t, sys, contracts, accounts.Deployer.Auth, depositAmount)
	registerValidatorWithTON(t, sys, contracts, accounts.Validator.Auth, depositAmount)

	// === Step 1: Check validator pool state ===
	t.Log("\n=== Step 1: Checking Validator Pool State ===")

	activeCount, err := contracts.RAT.GetActiveValidatorCount(callOpts, sys.Addresses.SystemConfig)
	require.NoError(t, err)
	t.Logf("Active validator count: %d", activeCount.Uint64())

	// Get validators list using getL2Validators
	getL2ValidatorsABI, err := abi.JSON(strings.NewReader(`[{"inputs":[{"internalType":"address","name":"systemConfig","type":"address"}],"name":"getL2Validators","outputs":[{"internalType":"address[]","name":"","type":"address[]"}],"stateMutability":"view","type":"function"}]`))
	require.NoError(t, err)

	callData, err := getL2ValidatorsABI.Pack("getL2Validators", sys.Addresses.SystemConfig)
	require.NoError(t, err)

	result, err := sys.L1Client.CallContract(context.Background(), ethereum.CallMsg{
		To:   &sys.Addresses.RATProxy,
		Data: callData,
	}, nil)
	require.NoError(t, err)

	var validators []common.Address
	err = getL2ValidatorsABI.UnpackIntoInterface(&validators, "getL2Validators", result)
	require.NoError(t, err)
	require.True(t, len(validators) > 0, "Expected at least one validator")
	t.Logf("Validator at index 0: %s", validators[0].Hex())
	t.Logf("Expected validator: %s", accounts.Validator.Addr.Hex())

	// === Step 2: Check RAT parameters ===
	t.Log("\n=== Step 2: Checking RAT Parameters ===")

	// Check ratTriggerProbability (slot 356)
	ratTriggerProbSlot := common.BigToHash(big.NewInt(356))
	ratTriggerProb, err := sys.L1Client.StorageAt(context.Background(), sys.Addresses.RATProxy, ratTriggerProbSlot, nil)
	require.NoError(t, err)
	t.Logf("ratTriggerProbability (slot 356): %s", common.BytesToHash(ratTriggerProb).Hex())
	expectedRAY, _ := new(big.Int).SetString("1000000000000000000000000000", 10) // 1e27
	t.Logf("Expected (1e27 / RAY): %s", common.BigToHash(expectedRAY).Hex())

	// Check minimumCollateral (slot 357)
	minCollSlot := common.BigToHash(big.NewInt(357))
	minColl, err := sys.L1Client.StorageAt(context.Background(), sys.Addresses.RATProxy, minCollSlot, nil)
	require.NoError(t, err)
	t.Logf("minimumCollateral (slot 357): %s", common.BytesToHash(minColl).Hex())

	// Check l1BridgeRegistry (slot 360)
	l1BridgeRegSlot := common.BigToHash(big.NewInt(360))
	l1BridgeReg, err := sys.L1Client.StorageAt(context.Background(), sys.Addresses.RATProxy, l1BridgeRegSlot, nil)
	require.NoError(t, err)
	t.Logf("l1BridgeRegistry (slot 360): %s", common.BytesToAddress(l1BridgeReg).Hex())
	t.Logf("Expected: %s", sys.Addresses.L1BridgeRegistryProxy.Hex())

	// === Step 3: Check DisputeGameFactory state ===
	t.Log("\n=== Step 3: Checking DisputeGameFactory State ===")

	dgf, err := bindings.NewDisputeGameFactory(sys.Addresses.DisputeGameFactory, sys.L1Client)
	require.NoError(t, err)

	ratOnFactory, err := dgf.Rat(callOpts)
	require.NoError(t, err)
	t.Logf("RAT on DisputeGameFactory: %s", ratOnFactory.Hex())

	systemConfigOnFactory, err := dgf.SystemConfig(callOpts)
	require.NoError(t, err)
	t.Logf("SystemConfig on DisputeGameFactory: %s", systemConfigOnFactory.Hex())

	// Check initBonds
	initBond, err := dgf.InitBonds(callOpts, uint32(0))
	require.NoError(t, err)
	t.Logf("InitBond for game type 0: %s wei", initBond.String())

	// === Step 4: Check L1BridgeRegistry mapping ===
	t.Log("\n=== Step 4: Checking L1BridgeRegistry Mapping ===")

	l1BridgeRegistryABI, err := abi.JSON(strings.NewReader(`[{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"rollupConfigWithDisputeGameFactory","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"}]`))
	require.NoError(t, err)

	callData, err = l1BridgeRegistryABI.Pack("rollupConfigWithDisputeGameFactory", sys.Addresses.DisputeGameFactory)
	require.NoError(t, err)

	result, err = sys.L1Client.CallContract(context.Background(), ethereum.CallMsg{
		To:   &sys.Addresses.L1BridgeRegistryProxy,
		Data: callData,
	}, nil)
	require.NoError(t, err)

	var rollupConfig common.Address
	err = l1BridgeRegistryABI.UnpackIntoInterface(&rollupConfig, "rollupConfigWithDisputeGameFactory", result)
	require.NoError(t, err)
	t.Logf("rollupConfigWithDisputeGameFactory[%s] = %s", sys.Addresses.DisputeGameFactory.Hex(), rollupConfig.Hex())
	t.Logf("Expected SystemConfig: %s", sys.Addresses.SystemConfig.Hex())

	if rollupConfig != sys.Addresses.SystemConfig {
		t.Fatalf("❌ L1BridgeRegistry mapping is incorrect! This will cause onlyValidFactory to fail.")
	}

	// === Step 5: Check validator collateral ===
	t.Log("\n=== Step 5: Checking Validator Collateral ===")

	isActive, err := contracts.RAT.IsValidatorActive(callOpts, accounts.Validator.Addr, sys.Addresses.SystemConfig)
	require.NoError(t, err)
	t.Logf("Is validator active: %v", isActive)

	// Get validator deposit using getValidatorDeposit
	getValidatorDepositABI, err := abi.JSON(strings.NewReader(`[{"inputs":[{"internalType":"address","name":"validator","type":"address"},{"internalType":"address","name":"systemConfig","type":"address"}],"name":"getValidatorDeposit","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}]`))
	require.NoError(t, err)

	callData, err = getValidatorDepositABI.Pack("getValidatorDeposit", accounts.Validator.Addr, sys.Addresses.SystemConfig)
	require.NoError(t, err)

	result, err = sys.L1Client.CallContract(context.Background(), ethereum.CallMsg{
		To:   &sys.Addresses.RATProxy,
		Data: callData,
	}, nil)
	require.NoError(t, err)

	var collateral *big.Int
	err = getValidatorDepositABI.UnpackIntoInterface(&collateral, "getValidatorDeposit", result)
	require.NoError(t, err)
	t.Logf("Validator deposit: %s WTON", collateral.String())

	// === Step 6: Get current block and check blockhash ===
	t.Log("\n=== Step 6: Checking Block State ===")

	currentBlock, err := sys.L1Client.BlockNumber(context.Background())
	require.NoError(t, err)
	t.Logf("Current block number: %d", currentBlock)

	// Get current block header
	currentHeader, err := sys.L1Client.HeaderByNumber(context.Background(), big.NewInt(int64(currentBlock)))
	require.NoError(t, err)
	t.Logf("Current block hash: %s", currentHeader.Hash().Hex())
	t.Logf("Current block timestamp: %d", currentHeader.Time)

	if currentBlock > 0 {
		prevHeader, err := sys.L1Client.HeaderByNumber(context.Background(), big.NewInt(int64(currentBlock-1)))
		require.NoError(t, err)
		t.Logf("Previous block hash: %s", prevHeader.Hash().Hex())
		t.Logf("Previous block timestamp: %d", prevHeader.Time)
	}

	// === Step 7: Create DisputeGame and check events ===
	t.Log("\n=== Step 7: Creating DisputeGame ===")

	gameType := uint32(0)
	gameImpl, err := dgf.GameImpls(callOpts, gameType)
	require.NoError(t, err)
	t.Logf("Game implementation for type %d: %s", gameType, gameImpl.Hex())

	if gameImpl == (common.Address{}) {
		t.Log("⚠️  No FaultDisputeGame implementation set for game type 0")
		t.Log("=== Test Complete (Cannot create game) ===")
		return
	}

	accounts.Proposer.Auth.Value = initBond
	rootClaim := [32]byte{0x01, 0x02, 0x03}
	l2BlockNumber := big.NewInt(testL2BlockNumber)
	extraData := common.LeftPadBytes(l2BlockNumber.Bytes(), 32)

	t.Logf("Creating game with rootClaim=%x, l2BlockNumber=%d", rootClaim, l2BlockNumber.Uint64())

	createGameTx, err := dgf.Create(accounts.Proposer.Auth, gameType, rootClaim, extraData)
	require.NoError(t, err)

	gameReceipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, createGameTx)
	require.NoError(t, err)

	t.Logf("Game creation tx: %s", createGameTx.Hash().Hex())
	t.Logf("Transaction status: %d (1=success)", gameReceipt.Status)
	t.Logf("Block number: %d", gameReceipt.BlockNumber.Uint64())
	t.Logf("Gas used: %d", gameReceipt.GasUsed)

	// === Step 8: Analyze all events ===
	t.Log("\n=== Step 8: Analyzing Transaction Events ===")

	t.Logf("Total logs: %d", len(gameReceipt.Logs))
	for i, log := range gameReceipt.Logs {
		t.Logf("Log %d:", i)
		t.Logf("  Address: %s", log.Address.Hex())
		t.Logf("  Topics: %d", len(log.Topics))
		for j, topic := range log.Topics {
			t.Logf("    Topic[%d]: %s", j, topic.Hex())
		}
		t.Logf("  Data length: %d", len(log.Data))
	}

	// Check for specific events
	ratTriggered := false
	gameCreated := false

	for _, log := range gameReceipt.Logs {
		if len(log.Topics) > 0 {
			topicHash := log.Topics[0].Hex()

			// DisputeGameCreated: 0x5b565efe82411da98814f356d0e7bcb8f0219b8d970307c5afb4a6903a8b2e35
			if topicHash == "0x5b565efe82411da98814f356d0e7bcb8f0219b8d970307c5afb4a6903a8b2e35" {
				gameCreated = true
				t.Log("✓ Found DisputeGameCreated event")
			}

			// AttentionTestTriggered
			if topicHash == eventAttentionTestTriggered {
				ratTriggered = true
				t.Log("✓ Found AttentionTestTriggered event")
				if len(log.Topics) > 1 {
					testId := log.Topics[1]
					t.Logf("  Test ID: %s", testId.Hex())
				}
				if len(log.Topics) > 2 {
					validator := common.HexToAddress(log.Topics[2].Hex())
					t.Logf("  Validator: %s", validator.Hex())
				}
			}
		}
	}

	t.Log("\n=== Test Summary ===")
	t.Logf("DisputeGame created: %v", gameCreated)
	t.Logf("RAT triggered: %v", ratTriggered)

	if !ratTriggered {
		t.Log("\n❌ RAT DID NOT TRIGGER")
		t.Log("Possible reasons:")
		t.Log("  1. Probability check failed (unlikely with 100% probability)")
		t.Log("  2. activeCount == 0 (checked above, should be 1)")
		t.Log("  3. Test already exists for this batch")
		t.Log("  4. _selectRandomValidator returned address(0)")
		t.Log("  5. onlyValidFactory modifier failed (L1BridgeRegistry mapping)")
		t.Log("  6. Some other condition in RAT contract failed silently")
	} else {
		t.Log("\n✅ RAT TRIGGERED SUCCESSFULLY")
	}
}
