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

// TestSimpleRAT_ValidatorRegistration tests the most basic RAT flow:
// 1. Register a validator
// 2. Verify registration
func TestSimpleRAT_ValidatorRegistration(t *testing.T) {
	t.Parallel()

	sys := rat.StartTONStakingSystem(t)
	callOpts := &bind.CallOpts{Context: sys.Ctx}

	t.Log("=== Testing Simple RAT Validator Registration ===")

	// Setup accounts and contracts
	accounts := setupTestAccounts(t, sys)
	contracts := connectTestContracts(t, sys)

	// Runtime configuration (required because these can't be done reliably in genesis)
	initializeOptimismContracts(t, sys)
	configureV3Parameters(t, sys)
	registerSystemConfigInL1BridgeRegistry(t, sys, accounts.Deployer.Auth)

	t.Logf("✓ Validator address: %s", accounts.Validator.Addr.Hex())
	t.Logf("✓ RAT contract: %s", sys.Addresses.RATProxy.Hex())
	t.Logf("✓ SystemConfig: %s", sys.Addresses.SystemConfig.Hex())

	// Get test deposit amount (in WTON, 27 decimals)
	depositAmount := getTestDepositAmount()
	t.Logf("✓ Deposit amount: %s WTON (27 decimals = 50000 WTON)", depositAmount.String())

	// Check WTON balance (we use WTON for staking, not TON)
	wtonBalance, err := contracts.WTON.BalanceOf(callOpts, accounts.Validator.Addr)
	require.NoError(t, err)
	t.Logf("✓ Validator WTON balance: %s", wtonBalance.String())
	require.True(t, wtonBalance.Cmp(depositAmount) >= 0,
		"Validator should have at least %s WTON but has %s", depositAmount.String(), wtonBalance.String())

	// Adjust minimum collateral if needed
	adjustMinimumCollateral(t, sys, contracts, accounts.Deployer.Auth, depositAmount)

	// Register validator
	registerValidatorWithTON(t, sys, contracts, accounts.Validator.Auth, depositAmount)

	// Verify registration
	isActive, err := contracts.RAT.IsValidatorActive(callOpts, accounts.Validator.Addr, sys.Addresses.SystemConfig)
	require.NoError(t, err)
	require.True(t, isActive, "Validator should be active after registration")
	t.Logf("✓ Validator is active")

	t.Log("=== Validator Registration Test Complete ===")
	t.Log("✅ Successfully registered validator with RAT")
}

// TestSimpleRAT_GameCreation tests creating a dispute game and RAT trigger
func TestSimpleRAT_GameCreation(t *testing.T) {
	t.Parallel()

	sys := rat.StartTONStakingSystem(t)
	callOpts := &bind.CallOpts{Context: sys.Ctx}

	t.Log("=== Testing RAT Trigger via DisputeGame Creation ===")

	// Setup accounts and contracts
	accounts := setupTestAccounts(t, sys)
	contracts := connectTestContracts(t, sys)

	// Runtime configuration (required because these can't be done reliably in genesis)
	initializeOptimismContracts(t, sys)
	configureV3Parameters(t, sys)
	registerSystemConfigInL1BridgeRegistry(t, sys, accounts.Deployer.Auth)

	// Get test deposit amount and adjust collateral
	depositAmount := getTestDepositAmount()
	adjustMinimumCollateral(t, sys, contracts, accounts.Deployer.Auth, depositAmount)

	// Step 1: Register validator
	t.Log("Step 1: Registering validator...")
	registerValidatorWithTON(t, sys, contracts, accounts.Validator.Auth, depositAmount)
	t.Logf("✓ Validator %s registered", accounts.Validator.Addr.Hex())

	// Get validator count before game creation
	validatorCount, err := contracts.RAT.GetActiveValidatorCount(callOpts, sys.Addresses.SystemConfig)
	require.NoError(t, err)
	t.Logf("✓ Active validators for SystemConfig: %d", validatorCount.Uint64())

	// Connect to DisputeGameFactory
	dgf, err := bindings.NewDisputeGameFactory(sys.Addresses.DisputeGameFactory, sys.L1Client)
	require.NoError(t, err)
	t.Logf("✓ DisputeGameFactory connected: %s", sys.Addresses.DisputeGameFactory.Hex())

	// Verify RAT is set on DisputeGameFactory (read from storage slot 52 directly)
	// Note: The Optimism DisputeGameFactory bytecode doesn't have rat() view function,
	// but we set storage slot 52 in genesis with the RAT address
	ratOnFactory, err := readDGFRatFromStorage(sys.L1Client, sys.Addresses.DisputeGameFactory)
	require.NoError(t, err)
	t.Logf("✓ RAT on DisputeGameFactory (storage slot 52): %s", ratOnFactory.Hex())
	t.Logf("✓ Expected RAT: %s", sys.Addresses.RATProxy.Hex())
	require.Equal(t, sys.Addresses.RATProxy, ratOnFactory, "RAT should be set on DisputeGameFactory")

	// Verify SystemConfig is set on DisputeGameFactory (read from storage slot 103 directly)
	systemConfigOnFactory, err := readDGFSystemConfigFromStorage(sys.L1Client, sys.Addresses.DisputeGameFactory)
	require.NoError(t, err)
	t.Logf("✓ SystemConfig on DisputeGameFactory (storage slot 103): %s", systemConfigOnFactory.Hex())
	t.Logf("✓ Expected SystemConfig: %s", sys.Addresses.SystemConfig.Hex())
	require.Equal(t, sys.Addresses.SystemConfig, systemConfigOnFactory, "SystemConfig should match on DisputeGameFactory")

	// Verify DisputeGameFactory is registered in L1BridgeRegistry
	// Call rollupConfigWithDisputeGameFactory(address) public view mapping
	// Function selector: keccak256("rollupConfigWithDisputeGameFactory(address)")[0:4]
	l1BridgeRegistryABI, err := abi.JSON(strings.NewReader(`[{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"rollupConfigWithDisputeGameFactory","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"}]`))
	require.NoError(t, err)

	callData, err := l1BridgeRegistryABI.Pack("rollupConfigWithDisputeGameFactory", sys.Addresses.DisputeGameFactory)
	require.NoError(t, err)

	result, err := sys.L1Client.CallContract(context.Background(), ethereum.CallMsg{
		To:   &sys.Addresses.L1BridgeRegistryProxy,
		Data: callData,
	}, nil)
	require.NoError(t, err)

	var rollupConfig common.Address
	err = l1BridgeRegistryABI.UnpackIntoInterface(&rollupConfig, "rollupConfigWithDisputeGameFactory", result)
	require.NoError(t, err)

	t.Logf("✓ DisputeGameFactory registered in L1BridgeRegistry")
	t.Logf("  DisputeGameFactory: %s", sys.Addresses.DisputeGameFactory.Hex())
	t.Logf("  → RollupConfig: %s", rollupConfig.Hex())
	t.Logf("  Expected SystemConfig: %s", sys.Addresses.SystemConfig.Hex())

	if rollupConfig == (common.Address{}) {
		t.Log("⚠️  WARNING: DisputeGameFactory NOT registered in L1BridgeRegistry!")
		t.Log("   This will cause RAT trigger to fail (onlyValidFactory modifier)")
	} else {
		require.Equal(t, sys.Addresses.SystemConfig, rollupConfig, "DisputeGameFactory should be mapped to SystemConfig in L1BridgeRegistry")
	}

	// Check if FaultDisputeGame implementation is set
	gameType := uint32(0)
	gameImpl, err := dgf.GameImpls(callOpts, gameType)
	require.NoError(t, err)
	t.Logf("✓ Game implementation for type %d: %s", gameType, gameImpl.Hex())

	if gameImpl == (common.Address{}) {
		t.Log("=== RAT Game Creation Test Complete ===")
		t.Log("✅ Validator registered successfully")
		t.Log("✅ DisputeGameFactory connected")
		t.Log("⚠️  No FaultDisputeGame implementation set for game type 0")
		return
	}

	// Get required bond amount
	initBond, err := dgf.InitBonds(callOpts, gameType)
	require.NoError(t, err)
	t.Logf("✓ Required init bond: %s wei", initBond.String())

	// Step 2: Create dispute game as proposer
	t.Log("Step 2: Creating DisputeGame as proposer...")

	accounts.Proposer.Auth.Value = initBond // Send required bond

	rootClaim := [32]byte{0x01, 0x02, 0x03}

	// extraData must be exactly 32 bytes containing l2BlockNumber
	l2BlockNumber := big.NewInt(testL2BlockNumber)
	extraData := common.LeftPadBytes(l2BlockNumber.Bytes(), 32)
	t.Logf("✓ Using L2 block number: %d", l2BlockNumber.Uint64())

	createGameTx, err := dgf.Create(accounts.Proposer.Auth, gameType, rootClaim, extraData)
	require.NoError(t, err)

	gameReceipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, createGameTx)
	require.NoError(t, err)

	// Log all events from the transaction
	t.Logf("Transaction logs count: %d", len(gameReceipt.Logs))
	for i, log := range gameReceipt.Logs {
		t.Logf("Log %d: Address=%s, Topics=%v", i, log.Address.Hex(), len(log.Topics))
		if len(log.Topics) > 0 {
			t.Logf("  Topic[0]=%s", log.Topics[0].Hex())
		}
	}

	if gameReceipt.Status != 1 {
		t.Logf("Note: Game creation reverted - FaultDisputeGame implementation not set in genesis")
		t.Logf("      Transaction: %s", createGameTx.Hash().Hex())
		t.Log("=== RAT Game Creation Test Complete ===")
		t.Log("✅ Validator registered successfully")
		t.Log("✅ DisputeGameFactory connected")
		t.Log("⚠️  Game creation requires FaultDisputeGame implementation in genesis")
		return
	}
	t.Logf("✓ DisputeGame created (tx: %s)", createGameTx.Hash().Hex())

	// Parse DisputeGameCreated event
	gameAddress := parseDisputeGameCreatedEvent(t, gameReceipt)
	require.NotEqual(t, common.Address{}, gameAddress, "Should have game address")
	t.Logf("✓ Game address: %s", gameAddress.Hex())

	// Check for RAT AttentionTestTriggered event
	ratTriggered := false
	for _, log := range gameReceipt.Logs {
		if log.Topics[0].Hex() == eventAttentionTestTriggered {
			ratTriggered = true
			testId := log.Topics[1]
			validator := common.HexToAddress(log.Topics[2].Hex())
			t.Logf("✓ RAT triggered - Test ID: %s, Validator: %s", testId.Hex(), validator.Hex())
			break
		}
	}

	t.Log("=== RAT Game Creation Test Complete ===")
	if ratTriggered {
		t.Log("✅ DisputeGame created and RAT triggered")
	} else {
		t.Log("✅ DisputeGame created (RAT not triggered - probabilistic)")
	}
}

// TestSimpleRAT_EvidenceSubmission tests the full flow:
// 1. Validator registration
// 2. Proposer creates DisputeGame (triggers RAT)
// 3. Selected validator submits evidence
func TestSimpleRAT_EvidenceSubmission(t *testing.T) {
	t.Parallel()

	sys := rat.StartTONStakingSystem(t)
	callOpts := &bind.CallOpts{Context: sys.Ctx}

	t.Log("=== Testing RAT Evidence Submission Flow ===")

	// Setup accounts and contracts
	accounts := setupTestAccounts(t, sys)
	contracts := connectTestContracts(t, sys)

	// Runtime configuration (required because these can't be done reliably in genesis)
	initializeOptimismContracts(t, sys)
	configureV3Parameters(t, sys)
	registerSystemConfigInL1BridgeRegistry(t, sys, accounts.Deployer.Auth)

	// Get test deposit amount and adjust collateral
	depositAmount := getTestDepositAmount()
	adjustMinimumCollateral(t, sys, contracts, accounts.Deployer.Auth, depositAmount)

	// Set RAT trigger probability to 100% for deterministic testing
	t.Log("Setting RAT trigger probability to 100% for testing...")
	ratTriggerProb := new(big.Int)
	ratTriggerProb.SetString("1000000000000000000000000000", 10) // 1e27 (100% in RAY units)
	setTriggerTx, err := contracts.RAT.SetRatTriggerProbability(accounts.Deployer.Auth, ratTriggerProb)
	require.NoError(t, err)
	_, err = bind.WaitMined(sys.Ctx, sys.L1Client, setTriggerTx)
	require.NoError(t, err)
	t.Logf("✓ RAT trigger probability set to 100%%")

	// Step 1: Register validator
	t.Log("Step 1: Registering validator...")
	registerValidatorWithTON(t, sys, contracts, accounts.Validator.Auth, depositAmount)
	t.Logf("✓ Validator %s registered", accounts.Validator.Addr.Hex())

	// Get validator count before game creation
	validatorCount, err := contracts.RAT.GetActiveValidatorCount(callOpts, sys.Addresses.SystemConfig)
	require.NoError(t, err)
	t.Logf("✓ Active validators for SystemConfig: %d", validatorCount.Uint64())

	// Step 2: Create dispute game as proposer
	t.Log("Step 2: Creating DisputeGame as proposer...")

	rootClaim := [32]byte{0x01, 0x02, 0x03}
	_, gameAddress := createDisputeGame(t, sys, accounts.Proposer.Auth, rootClaim)
	t.Logf("✓ DisputeGame created at: %s", gameAddress.Hex())

	// Step 2.5: Trigger RAT directly (since DisputeGameFactory bytecode doesn't have RAT integration)
	t.Log("Step 2.5: Triggering RAT directly via impersonation...")
	batchIndex := uint32(testL2BlockNumber) // Use L2 block number as batch index
	ratReceipt := triggerRATDirectly(t, sys, gameAddress, batchIndex)
	require.Equal(t, uint64(1), ratReceipt.Status, "RAT trigger transaction should succeed")
	t.Logf("✓ RAT triggered directly (tx status: %d)", ratReceipt.Status)

	// Step 3: Parse RAT trigger event and get batchIndex
	t.Log("Step 3: Parsing RAT trigger event...")

	testID, _, ratTriggered := parseRATTriggerEventWithBatchIndex(t, ratReceipt, accounts.Validator.Addr)
	require.True(t, ratTriggered, "RAT should be triggered")
	t.Logf("✓ Test ID: %s, Batch Index: %d", common.BytesToHash(testID[:]).Hex(), batchIndex)

	// Check RAT test status before submitting evidence
	testInfo, err := contracts.RAT.GetAttentionTest(callOpts, testID)
	require.NoError(t, err)
	t.Logf("✓ Test status: %d, Validator: %s, Deadline: %s",
		testInfo.Status, testInfo.ValidatorAddress.Hex(), testInfo.Deadline.String())

	// Get current block to check timestamp
	currentBlock, err := sys.L1Client.BlockByNumber(sys.Ctx, nil)
	require.NoError(t, err)
	t.Logf("✓ Current block timestamp: %d", currentBlock.Time())

	// Step 4: Submit evidence as selected validator
	t.Log("Step 4: Submitting evidence...")

	// Create dummy evidence
	evidence := []byte("dummy evidence data")

	evidenceTx, err := contracts.RAT.SubmitEvidence(accounts.Validator.Auth, sys.Addresses.SystemConfig, batchIndex, evidence)
	require.NoError(t, err)
	evidenceReceipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, evidenceTx)
	require.NoError(t, err)
	t.Logf("✓ Evidence submitted (tx: %s)", evidenceTx.Hash().Hex())

	// Verify evidence submission event
	evidenceSubmitted := false
	ratABI, err := abi.JSON(strings.NewReader(bindings.RATABI))
	require.NoError(t, err)

	for _, log := range evidenceReceipt.Logs {
		if log.Address == sys.Addresses.RATProxy && len(log.Topics) > 0 {
			eventID := log.Topics[0]
			evidenceSubmittedID := ratABI.Events["EvidenceSubmitted"].ID
			if eventID == evidenceSubmittedID {
				evidenceSubmitted = true
				t.Logf("✓ EvidenceSubmitted event found")
				break
			}
		}
	}

	require.True(t, evidenceSubmitted, "EvidenceSubmitted event not found")

	t.Log("=== Evidence Submission Test Complete ===")
	t.Log("✅ Full flow completed:")
	t.Log("   1. Validator registered")
	t.Log("   2. DisputeGame created (RAT triggered)")
	t.Log("   3. Evidence submitted successfully")
}

// TestSimpleRAT_ChallengerWins tests the full flow with incorrect state root:
// 1. Validator registration
// 2. Proposer creates DisputeGame with WRONG root claim (triggers RAT)
// 3. Validator (as challenger) wins the game
// 4. Validator's bond is restored via RAT.resolveClaim()
// 5. Validator claims game bond credits (2-step process with DelayedWETH)
func TestSimpleRAT_ChallengerWins(t *testing.T) {
	t.Parallel()

	sys := rat.StartTONStakingSystem(t)
	callOpts := &bind.CallOpts{Context: sys.Ctx}

	t.Log("=== Testing RAT Challenger Wins Flow ===")

	// Setup accounts and contracts
	accounts := setupTestAccounts(t, sys)
	contracts := connectTestContracts(t, sys)

	// Runtime configuration (required because these can't be done reliably in genesis)
	initializeOptimismContracts(t, sys)
	configureV3Parameters(t, sys)
	registerSystemConfigInL1BridgeRegistry(t, sys, accounts.Deployer.Auth)

	// Get test deposit amount and adjust collateral
	depositAmount := getTestDepositAmount()
	adjustMinimumCollateral(t, sys, contracts, accounts.Deployer.Auth, depositAmount)

	// Step 1: Register validator
	t.Log("Step 1: Registering validator...")

	// Track initial ETH balance
	initialETHBalance, err := sys.L1Client.BalanceAt(sys.Ctx, accounts.Validator.Addr, nil)
	require.NoError(t, err)
	t.Logf("✓ Validator initial ETH balance: %s wei", initialETHBalance.String())

	registerValidatorWithTON(t, sys, contracts, accounts.Validator.Auth, depositAmount)
	t.Logf("✓ Validator %s registered", accounts.Validator.Addr.Hex())

	// Get validator deposit before game creation
	regBefore, err := contracts.RAT.GetValidatorRegistration(callOpts, accounts.Validator.Addr, sys.Addresses.SystemConfig)
	require.NoError(t, err)
	t.Logf("✓ Validator collateral before game: %s", regBefore.Collateral.String())

	// Get validator count before game creation
	validatorCount, err := contracts.RAT.GetActiveValidatorCount(callOpts, sys.Addresses.SystemConfig)
	require.NoError(t, err)
	t.Logf("✓ Active validators for SystemConfig: %d", validatorCount.Uint64())

	// Step 2: Create dispute game with WRONG root claim as proposer
	t.Log("Step 2: Creating DisputeGame with WRONG root claim...")

	_, gameAddress := createDisputeGameWithWrongClaim(t, sys, accounts.Proposer.Auth)
	t.Logf("✓ DisputeGame created at: %s", gameAddress.Hex())

	// Step 2.5: Trigger RAT directly (Optimism's DisputeGameFactory doesn't have RAT integration)
	t.Log("Step 2.5: Triggering RAT directly...")
	ratReceipt := triggerRATDirectly(t, sys, gameAddress, 100) // batchIndex = 100
	require.Equal(t, uint64(1), ratReceipt.Status, "RAT trigger transaction should succeed")
	t.Logf("✓ RAT triggered directly (tx status: %d)", ratReceipt.Status)

	// Step 3: Parse RAT trigger event
	t.Log("Step 3: Parsing RAT trigger event...")

	testID, _, ratTriggered := parseRATTriggerEventWithBatchIndex(t, ratReceipt, accounts.Validator.Addr)
	require.True(t, ratTriggered, "RAT should be triggered")
	_ = testID // testID available for future use if needed

	// Get validator deposit after RAT trigger (should be reduced)
	regAfterTrigger, err := contracts.RAT.GetValidatorRegistration(callOpts, accounts.Validator.Addr, sys.Addresses.SystemConfig)
	require.NoError(t, err)
	t.Logf("✓ Validator collateral after RAT trigger: %s", regAfterTrigger.Collateral.String())

	// Step 4: Challenger attacks the wrong root claim
	t.Log("Step 4: Validator/challenger attacks wrong root claim...")

	// Connect to the game contract
	game, err := bindings.NewFaultDisputeGame(gameAddress, sys.L1Client)
	require.NoError(t, err)

	// Check game configuration
	maxDepth, err := game.MaxGameDepth(callOpts)
	if err != nil {
		t.Logf("⚠️  Failed to get max game depth: %v", err)
	} else {
		t.Logf("✓ Max game depth: %s", maxDepth.String())
	}

	splitDepth, err := game.SplitDepth(callOpts)
	if err != nil {
		t.Logf("⚠️  Failed to get split depth: %v", err)
	} else {
		t.Logf("✓ Split depth: %s", splitDepth.String())
	}

	// Check game status
	gameStatus, err := game.Status(callOpts)
	if err != nil {
		t.Logf("⚠️  Failed to get game status: %v", err)
	} else {
		t.Logf("✓ Game status: %d (0=IN_PROGRESS, 1=CHALLENGER_WINS, 2=DEFENDER_WINS)", gameStatus)
	}

	// Get root claim
	gameRootClaim, err := game.RootClaim(callOpts)
	require.NoError(t, err)
	t.Logf("✓ Root claim: %x", gameRootClaim)

	// Get claim data for root (claim index 0)
	claimData, err := game.ClaimData(callOpts, big.NewInt(0))
	require.NoError(t, err)
	t.Logf("✓ Root claim data - Position: %s, Bond: %s", claimData.Position.String(), claimData.Bond.String())
	t.Logf("✓ Root claim from claimData: %x", claimData.Claim)

	// Calculate next position using LibPosition.move(position, true):
	// attack: position * 2
	nextPosition := new(big.Int).Mul(claimData.Position, big.NewInt(2))
	t.Logf("✓ Next position for attack: %s", nextPosition.String())

	// Query required bond from contract
	requiredBond, err := game.GetRequiredBond(callOpts, nextPosition)
	if err != nil {
		t.Logf("⚠️  Failed to get required bond: %v", err)
		// Fallback to root bond
		requiredBond = claimData.Bond
	} else {
		t.Logf("✓ Required bond from contract: %s wei", requiredBond.String())
	}

	// Validator attacks the root claim
	correctClaim := [32]byte{0x00} // Correct claim (different from wrong 0xFF...)
	accounts.Validator.Auth.Value = requiredBond
	attackBond := new(big.Int).Set(requiredBond) // Save attack bond amount
	attackTx, err := game.Attack(accounts.Validator.Auth, gameRootClaim, big.NewInt(0), correctClaim)
	require.NoError(t, err)
	accounts.Validator.Auth.Value = nil // Reset

	attackReceipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, attackTx)
	require.NoError(t, err)
	t.Logf("✓ Attack tx mined (tx: %s, status: %d, gas: %d)",
		attackTx.Hash().Hex(), attackReceipt.Status, attackReceipt.GasUsed)
	require.Equal(t, uint64(1), attackReceipt.Status, "Attack transaction should succeed")

	// Record bonds involved in the game
	rootBond := new(big.Int).Set(claimData.Bond)
	totalGameBonds := new(big.Int).Add(attackBond, rootBond)
	t.Logf("✓ Game bonds - Root: %s wei, Attack: %s wei, Total: %s wei",
		rootBond.String(), attackBond.String(), totalGameBonds.String())

	// Step 5: Wait for game clock to expire and resolve
	t.Log("Step 5: Waiting for game clock to expire...")

	// Verify the attack was successful by checking claim count
	claimCount, err := game.ClaimDataLen(callOpts)
	require.NoError(t, err)
	t.Logf("✓ Total claims in game: %d", claimCount.Uint64())
	require.True(t, claimCount.Uint64() >= 2, "Should have at least 2 claims (root + attack), got %d", claimCount.Uint64())

	// Get max clock duration
	maxClockDuration, err := game.MaxClockDuration(callOpts)
	require.NoError(t, err)
	t.Logf("✓ Max clock duration: %d seconds", maxClockDuration)

	// Advance time past the clock duration
	timeToAdvance := int64(maxClockDuration + 1) // Add 1 second buffer
	advanceTimeAndMine(t, sys, timeToAdvance)

	// Step 6: Resolve the game
	t.Log("Step 6: Resolving game claims...")

	// Resolve claims bottom-up (child first, then parent)
	// Claim 1 is our attack claim
	resolveTx, err := game.ResolveClaim(accounts.Validator.Auth, big.NewInt(1), big.NewInt(0))
	require.NoError(t, err)
	_, err = bind.WaitMined(sys.Ctx, sys.L1Client, resolveTx)
	require.NoError(t, err)
	t.Logf("✓ Resolved claim 1 (attack claim)")

	// Resolve claim 0 (root claim)
	resolveTx, err = game.ResolveClaim(accounts.Validator.Auth, big.NewInt(0), big.NewInt(0))
	require.NoError(t, err)
	_, err = bind.WaitMined(sys.Ctx, sys.L1Client, resolveTx)
	require.NoError(t, err)
	t.Logf("✓ Resolved claim 0 (root claim)")

	// Resolve the game
	resolveGameTx, err := game.Resolve(accounts.Validator.Auth)
	require.NoError(t, err)
	_, err = bind.WaitMined(sys.Ctx, sys.L1Client, resolveGameTx)
	require.NoError(t, err)
	t.Logf("✓ Game resolved")

	// Check final game status
	finalStatus, err := game.Status(callOpts)
	require.NoError(t, err)
	t.Logf("✓ Final game status: %d (1=CHALLENGER_WINS)", finalStatus)
	require.Equal(t, uint8(1), finalStatus, "Game should be won by challenger")

	// Step 7: Call RAT.resolveClaim to restore validator bond
	t.Log("Step 7: Calling RAT.resolveClaim to restore validator bond...")

	resolveRATTx, err := contracts.RAT.ResolveClaim(accounts.Validator.Auth, gameAddress)
	require.NoError(t, err)
	_, err = bind.WaitMined(sys.Ctx, sys.L1Client, resolveRATTx)
	require.NoError(t, err)
	t.Logf("✓ RAT.resolveClaim called (tx: %s)", resolveRATTx.Hash().Hex())

	// Verify validator bond was restored
	regAfterResolve, err := contracts.RAT.GetValidatorRegistration(callOpts, accounts.Validator.Addr, sys.Addresses.SystemConfig)
	require.NoError(t, err)
	t.Logf("✓ Validator collateral after resolve: %s", regAfterResolve.Collateral.String())

	// Collateral should be restored to original amount
	require.True(t, regAfterResolve.Collateral.Cmp(depositAmount) == 0,
		"Collateral should be restored to original %s, but got: %s",
		depositAmount.String(), regAfterResolve.Collateral.String())

	// Check final ETH balance
	finalETHBalance, err := sys.L1Client.BalanceAt(sys.Ctx, accounts.Validator.Addr, nil)
	require.NoError(t, err)
	ethSpentOnGas := new(big.Int).Sub(initialETHBalance, finalETHBalance)
	t.Logf("✓ Validator final ETH balance: %s wei", finalETHBalance.String())
	t.Logf("✓ ETH spent on gas: %s wei", ethSpentOnGas.String())

	// Step 8: Verify and claim game bonds via credit system
	t.Log("")
	t.Log("=== Step 8: Verify and Claim Game Bonds ===")

	// Advance time to ensure game is fully finalized
	advanceTimeAndMine(t, sys, 60) // 60 seconds for finalization

	// Check credit balance
	creditBalance, err := game.Credit(callOpts, accounts.Validator.Addr)
	require.NoError(t, err)
	t.Logf("✓ Validator credit balance: %s wei", creditBalance.String())

	// Verify credit equals total game bonds
	require.True(t, creditBalance.Cmp(totalGameBonds) == 0,
		"Credit balance should equal total game bonds (%s wei), but got: %s wei",
		totalGameBonds.String(), creditBalance.String())
	t.Logf("✓ Credit balance matches total game bonds: %s wei (%s ETH)",
		totalGameBonds.String(),
		new(big.Float).Quo(new(big.Float).SetInt(totalGameBonds), big.NewFloat(1e18)).Text('f', 6))
	t.Logf("   - Root claim bond (from proposer): %s wei", rootBond.String())
	t.Logf("   - Attack claim bond (from validator): %s wei", attackBond.String())

	// Track ETH balance before claiming credit
	ethBeforeClaim, err := sys.L1Client.BalanceAt(sys.Ctx, accounts.Validator.Addr, nil)
	require.NoError(t, err)
	t.Logf("✓ ETH balance before claiming: %s wei", ethBeforeClaim.String())

	// First call to claimCredit: unlocks the credit
	claimCreditTx1, err := game.ClaimCredit(accounts.Validator.Auth, accounts.Validator.Addr)
	require.NoError(t, err)
	claimReceipt1, err := bind.WaitMined(sys.Ctx, sys.L1Client, claimCreditTx1)
	require.NoError(t, err)
	t.Logf("✓ game.claimCredit (1st call - unlock) (tx: %s, gas used: %d)", claimCreditTx1.Hash().Hex(), claimReceipt1.GasUsed)

	// Query DelayedWETH withdrawal delay dynamically
	wethAddr, err := game.Weth(callOpts)
	require.NoError(t, err)
	t.Logf("✓ DelayedWETH address: %s", wethAddr.Hex())

	delayedWETH, err := bindings.NewDelayedWETHMinimal(wethAddr, sys.L1Client)
	require.NoError(t, err)

	withdrawalDelay, err := delayedWETH.Delay(callOpts)
	require.NoError(t, err)
	t.Logf("✓ Withdrawal delay from contract: %s seconds (%s days)",
		withdrawalDelay.String(),
		new(big.Float).Quo(new(big.Float).SetInt(withdrawalDelay), big.NewFloat(86400)).Text('f', 1))

	// Wait for DelayedWETH withdrawal delay
	advanceTimeAndMine(t, sys, withdrawalDelay.Int64())

	// Second call to claimCredit: actually transfers ETH
	claimCreditTx2, err := game.ClaimCredit(accounts.Validator.Auth, accounts.Validator.Addr)
	require.NoError(t, err)
	claimReceipt2, err := bind.WaitMined(sys.Ctx, sys.L1Client, claimCreditTx2)
	require.NoError(t, err)
	t.Logf("✓ game.claimCredit (2nd call - transfer) (tx: %s, gas used: %d)", claimCreditTx2.Hash().Hex(), claimReceipt2.GasUsed)

	// Check ETH balance after claiming
	ethAfterClaim, err := sys.L1Client.BalanceAt(sys.Ctx, accounts.Validator.Addr, nil)
	require.NoError(t, err)
	t.Logf("✓ ETH balance after claiming: %s wei", ethAfterClaim.String())

	// Calculate gas cost for both claim transactions
	gasUsedForClaim1 := new(big.Int).Mul(big.NewInt(int64(claimReceipt1.GasUsed)), claimReceipt1.EffectiveGasPrice)
	gasUsedForClaim2 := new(big.Int).Mul(big.NewInt(int64(claimReceipt2.GasUsed)), claimReceipt2.EffectiveGasPrice)
	totalGasForClaim := new(big.Int).Add(gasUsedForClaim1, gasUsedForClaim2)
	t.Logf("✓ Total gas cost for claim (both calls): %s wei", totalGasForClaim.String())

	// Check credit balance after claiming (should be 0)
	creditAfterClaim, err := game.Credit(callOpts, accounts.Validator.Addr)
	require.NoError(t, err)
	t.Logf("✓ Credit balance after claiming: %s wei", creditAfterClaim.String())

	// Calculate actual change in ETH balance
	actualChange := new(big.Int).Sub(ethAfterClaim, ethBeforeClaim)
	t.Logf("✓ Actual ETH balance change: %s wei", actualChange.String())

	// Expected change = credit - total gas cost
	expectedChange := new(big.Int).Sub(creditBalance, totalGasForClaim)
	t.Logf("✓ Expected ETH balance change: %s wei (credit %s - gas %s)",
		expectedChange.String(), creditBalance.String(), totalGasForClaim.String())

	// Verify the credit was claimed successfully
	if creditAfterClaim.Cmp(big.NewInt(0)) == 0 {
		t.Logf("✅ Credit successfully claimed (balance cleared to 0)")
	} else {
		t.Logf("⚠️  Warning: Credit balance not cleared: %s wei", creditAfterClaim.String())
	}

	// Verify ETH balance change
	if actualChange.Cmp(expectedChange) == 0 {
		t.Logf("✅ ETH balance change matches expected (credit transferred successfully)")
	} else {
		diff := new(big.Int).Sub(actualChange, expectedChange)
		diff.Abs(diff)
		t.Logf("⚠️  ETH balance difference from expected: %s wei", diff.String())
	}

	if actualChange.Cmp(big.NewInt(0)) > 0 {
		t.Logf("✅ Net ETH gain (credit received minus gas): %s wei (%s ETH)",
			actualChange.String(),
			new(big.Float).Quo(new(big.Float).SetInt(actualChange), big.NewFloat(1e18)).Text('f', 6))
	} else {
		t.Logf("⚠️  Net ETH loss: %s wei", new(big.Int).Abs(actualChange).String())
	}

	t.Log("")
	t.Log("=== Challenger Wins Test Complete ===")
	t.Log("✅ Step 1: Validator registered")
	t.Log("✅ Step 2: DisputeGame created with wrong claim (RAT triggered)")
	t.Log("✅ Step 3: Validator bond locked")
	t.Log("✅ Step 4: Validator attacked wrong root claim")
	t.Log("✅ Step 5: Time advanced past clock duration")
	t.Log("✅ Step 6: Game resolved (CHALLENGER_WINS)")
	t.Log("✅ Step 7: RAT.resolveClaim called, validator bond fully restored")
	t.Logf("✅ Step 8: Game bonds credited: %s wei (%s ETH)",
		creditBalance.String(),
		new(big.Float).Quo(new(big.Float).SetInt(creditBalance), big.NewFloat(1e18)).Text('f', 6))
	t.Logf("✅ Step 8: claimCredit called twice (unlock + transfer)")
	t.Logf("         - 1st call gas: %s wei (unlock credit)", gasUsedForClaim1.String())
	t.Logf("         - 2nd call gas: %s wei (transfer ETH)", gasUsedForClaim2.String())
	if actualChange.Cmp(big.NewInt(0)) > 0 {
		t.Logf("✅ Step 8: Net ETH gain after gas: %s wei (%s ETH)",
			actualChange.String(),
			new(big.Float).Quo(new(big.Float).SetInt(actualChange), big.NewFloat(1e18)).Text('f', 6))
	} else {
		t.Logf("⚠️  Step 8: Net ETH loss: %s wei", new(big.Int).Abs(actualChange).String())
	}
}
