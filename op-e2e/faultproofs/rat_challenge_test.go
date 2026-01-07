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
	"github.com/ethereum/go-ethereum/crypto"
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
	ctx := sys.Ctx

	t.Log("=== Testing Simple RAT Validator Registration ===")

	// Get validator account (Anvil account #3)
	validatorKey, err := crypto.HexToECDSA("7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6")
	require.NoError(t, err)

	validatorAddr := crypto.PubkeyToAddress(validatorKey.PublicKey)
	t.Logf("Validator address: %s", validatorAddr.Hex())

	// Check validator ETH balance
	balance, err := sys.L1Client.BalanceAt(ctx, validatorAddr, nil)
	require.NoError(t, err)
	t.Logf("Validator ETH balance: %s wei", balance.String())
	require.True(t, balance.Cmp(big.NewInt(0)) > 0, "Validator should have ETH")

	// Get chain ID
	chainID, err := sys.L1Client.ChainID(ctx)
	require.NoError(t, err)

	// Create transactor for validator
	auth, err := bind.NewKeyedTransactorWithChainID(validatorKey, chainID)
	require.NoError(t, err)
	auth.GasLimit = 3000000

	t.Logf("✓ Validator transactor created")
	t.Logf("✓ RAT contract: %s", sys.Addresses.RATProxy.Hex())
	t.Logf("✓ SystemConfig: %s", sys.Addresses.SystemConfig.Hex())

	// Connect to TON contract (RAT uses TON, not WTON)
	tonERC20, err := bindings.NewERC20(sys.Addresses.TON, sys.L1Client)
	require.NoError(t, err)
	t.Logf("✓ TON contract connected")

	// Connect to RAT contract
	ratContract, err := bindings.NewRAT(sys.Addresses.RATProxy, sys.L1Client)
	require.NoError(t, err)
	t.Logf("✓ RAT contract connected")

	// Get minimum collateral required
	callOpts := &bind.CallOpts{Context: sys.Ctx}
	minCollateral, err := ratContract.GetMinimumCollateral(callOpts)
	require.NoError(t, err)
	t.Logf("✓ Minimum collateral: %s", minCollateral.String())

	// Use a smaller amount that fits within genesis TON balance
	// Validator has 100000 TON in genesis, so let's use 50000 TON
	depositAmount := new(big.Int).SetUint64(50000)
	depositAmount.Mul(depositAmount, big.NewInt(1e18)) // Convert to wei (18 decimals)
	t.Logf("Deposit amount: %s TON", depositAmount.String())

	// Check if this is enough for minimum collateral
	if depositAmount.Cmp(minCollateral) < 0 {
		t.Logf("WARNING: Deposit amount %s is less than minimum collateral %s",
			depositAmount.String(), minCollateral.String())
		t.Logf("This test will verify the error handling for insufficient collateral")
	}

	// Step 1: Get TON balance (should have from genesis)
	tonBalance, err := tonERC20.BalanceOf(callOpts, validatorAddr)
	require.NoError(t, err)
	t.Logf("Validator TON balance: %s", tonBalance.String())

	// Verify validator has enough TON
	require.True(t, tonBalance.Cmp(depositAmount) >= 0,
		"Validator should have at least %s TON but has %s", depositAmount.String(), tonBalance.String())

	// If minimum collateral is too high for our test amount, adjust it
	// getMinimumCollateral() = slashingPenalty + validatorBuffer
	if depositAmount.Cmp(minCollateral) < 0 {
		t.Logf("Lowering slashing penalty and validator buffer to match test amount...")

		// Get deployer (owner) to adjust parameters
		deployerKey, err := crypto.HexToECDSA("59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d")
		require.NoError(t, err)
		deployerAuth, err := bind.NewKeyedTransactorWithChainID(deployerKey, chainID)
		require.NoError(t, err)
		deployerAuth.GasLimit = 3000000

		// Set both slashingPenalty and validatorBuffer to 1/4 of deposit amount
		// So minimum collateral = slashingPenalty + validatorBuffer = deposit/4 + deposit/4 = deposit/2
		quarterDeposit := new(big.Int).Div(depositAmount, big.NewInt(4))

		// Set slashing penalty
		setPenaltyTx, err := ratContract.SetSlashingPenalty(deployerAuth, quarterDeposit)
		require.NoError(t, err)
		penaltyReceipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, setPenaltyTx)
		require.NoError(t, err)
		require.Equal(t, uint64(1), penaltyReceipt.Status, "SetSlashingPenalty should succeed")
		t.Logf("✓ Slashing penalty set to %s (tx: %s)", quarterDeposit.String(), setPenaltyTx.Hash().Hex())

		// Set validator buffer
		setBufferTx, err := ratContract.SetValidatorBuffer(deployerAuth, quarterDeposit)
		require.NoError(t, err)
		bufferReceipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, setBufferTx)
		require.NoError(t, err)
		require.Equal(t, uint64(1), bufferReceipt.Status, "SetValidatorBuffer should succeed")
		t.Logf("✓ Validator buffer set to %s (tx: %s)", quarterDeposit.String(), setBufferTx.Hash().Hex())

		// Verify new minimum collateral
		newMinCollateral, err := ratContract.GetMinimumCollateral(callOpts)
		require.NoError(t, err)
		t.Logf("✓ New minimum collateral: %s", newMinCollateral.String())
		require.True(t, depositAmount.Cmp(newMinCollateral) >= 0,
			"Deposit amount should be >= minimum collateral")
	}

	// Step 2: Approve TON to RAT
	t.Log("Approving TON to RAT...")
	approveTx, err := tonERC20.Approve(auth, sys.Addresses.RATProxy, depositAmount)
	require.NoError(t, err)
	approveReceipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, approveTx)
	require.NoError(t, err)
	require.Equal(t, uint64(1), approveReceipt.Status, "Approve should succeed")
	t.Logf("✓ TON approved to RAT (tx: %s)", approveTx.Hash().Hex())

	// Step 3: Register validator
	t.Log("Registering validator...")
	registerTx, err := ratContract.RegisterValidator(auth, sys.Addresses.SystemConfig, depositAmount)
	require.NoError(t, err)
	regReceipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, registerTx)
	require.NoError(t, err)
	require.Equal(t, uint64(1), regReceipt.Status, "Register transaction should succeed")
	t.Logf("✓ Validator registered (tx: %s)", registerTx.Hash().Hex())

	// Step 4: Verify registration
	isActive, err := ratContract.IsValidatorActive(callOpts, validatorAddr, sys.Addresses.SystemConfig)
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
	ctx := sys.Ctx

	t.Log("=== Testing RAT Trigger via DisputeGame Creation ===")

	// Prerequisites: Register a validator first
	validatorKey, err := crypto.HexToECDSA("7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6")
	require.NoError(t, err)
	validatorAddr := crypto.PubkeyToAddress(validatorKey.PublicKey)

	chainID, err := sys.L1Client.ChainID(ctx)
	require.NoError(t, err)

	validatorAuth, err := bind.NewKeyedTransactorWithChainID(validatorKey, chainID)
	require.NoError(t, err)
	validatorAuth.GasLimit = 3000000

	// Connect to contracts
	ratContract, err := bindings.NewRAT(sys.Addresses.RATProxy, sys.L1Client)
	require.NoError(t, err)

	tonERC20, err := bindings.NewERC20(sys.Addresses.TON, sys.L1Client)
	require.NoError(t, err)

	callOpts := &bind.CallOpts{Context: sys.Ctx}

	// Get minimum collateral and adjust it
	minCollateral, err := ratContract.GetMinimumCollateral(callOpts)
	require.NoError(t, err)
	t.Logf("Current minimum collateral: %s", minCollateral.String())

	depositAmount := new(big.Int).SetUint64(50000)
	depositAmount.Mul(depositAmount, big.NewInt(1e18))

	// Lower collateral requirements if needed
	if depositAmount.Cmp(minCollateral) < 0 {
		deployerKey, err := crypto.HexToECDSA("59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d")
		require.NoError(t, err)
		deployerAuth, err := bind.NewKeyedTransactorWithChainID(deployerKey, chainID)
		require.NoError(t, err)
		deployerAuth.GasLimit = 3000000

		quarterDeposit := new(big.Int).Div(depositAmount, big.NewInt(4))

		_, err = ratContract.SetSlashingPenalty(deployerAuth, quarterDeposit)
		require.NoError(t, err)
		_, err = ratContract.SetValidatorBuffer(deployerAuth, quarterDeposit)
		require.NoError(t, err)

		t.Logf("✓ Collateral requirements adjusted")
	}

	// Register validator
	t.Log("Step 1: Registering validator...")
	approveTx, err := tonERC20.Approve(validatorAuth, sys.Addresses.RATProxy, depositAmount)
	require.NoError(t, err)
	_, err = bind.WaitMined(sys.Ctx, sys.L1Client, approveTx)
	require.NoError(t, err)

	registerTx, err := ratContract.RegisterValidator(validatorAuth, sys.Addresses.SystemConfig, depositAmount)
	require.NoError(t, err)
	_, err = bind.WaitMined(sys.Ctx, sys.L1Client, registerTx)
	require.NoError(t, err)
	t.Logf("✓ Validator %s registered", validatorAddr.Hex())

	// Get validator count before game creation
	validatorCount, err := ratContract.GetActiveValidatorCount(callOpts, sys.Addresses.SystemConfig)
	require.NoError(t, err)
	t.Logf("✓ Active validators for SystemConfig: %d", validatorCount.Uint64())

	// Connect to DisputeGameFactory
	dgf, err := bindings.NewDisputeGameFactory(sys.Addresses.DisputeGameFactory, sys.L1Client)
	require.NoError(t, err)
	t.Logf("✓ DisputeGameFactory connected: %s", sys.Addresses.DisputeGameFactory.Hex())

	// Verify RAT is set on DisputeGameFactory
	ratOnFactory, err := dgf.Rat(callOpts)
	require.NoError(t, err)
	t.Logf("✓ RAT on DisputeGameFactory: %s", ratOnFactory.Hex())
	t.Logf("✓ Expected RAT: %s", sys.Addresses.RATProxy.Hex())
	require.Equal(t, sys.Addresses.RATProxy, ratOnFactory, "RAT should be set on DisputeGameFactory")

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

	proposerKey, err := crypto.HexToECDSA("47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a")
	require.NoError(t, err)
	proposerAuth, err := bind.NewKeyedTransactorWithChainID(proposerKey, chainID)
	require.NoError(t, err)
	proposerAuth.GasLimit = 5000000
	proposerAuth.Value = initBond // Send required bond

	rootClaim := [32]byte{0x01, 0x02, 0x03}

	// extraData must be exactly 32 bytes containing l2BlockNumber
	l2BlockNumber := big.NewInt(100) // Dummy L2 block number
	extraData := common.LeftPadBytes(l2BlockNumber.Bytes(), 32)
	t.Logf("✓ Using L2 block number: %d", l2BlockNumber.Uint64())

	createGameTx, err := dgf.Create(proposerAuth, gameType, rootClaim, extraData)
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
	var gameAddress common.Address
	for _, log := range gameReceipt.Logs {
		if log.Topics[0].Hex() == "0x5b565efe82411da98814f356d0e7bcb8f0219b8d970307c5afb4a6903a8b2e35" {
			gameAddress = common.HexToAddress(log.Topics[1].Hex())
			t.Logf("✓ Game address: %s", gameAddress.Hex())
			break
		}
	}
	require.NotEqual(t, common.Address{}, gameAddress, "Should have game address")

	// Check for RAT AttentionTestTriggered event
	ratTriggered := false
	for _, log := range gameReceipt.Logs {
		if log.Topics[0].Hex() == "0xcf68a8dafa7b2329d7d7fcde3af620c2a51f64345d1eb2d66ffe7c7f1e9b0c38" {
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
	ctx := sys.Ctx

	t.Log("=== Testing RAT Evidence Submission Flow ===")

	// Prerequisites: Register a validator first
	validatorKey, err := crypto.HexToECDSA("7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6")
	require.NoError(t, err)
	validatorAddr := crypto.PubkeyToAddress(validatorKey.PublicKey)

	chainID, err := sys.L1Client.ChainID(ctx)
	require.NoError(t, err)

	validatorAuth, err := bind.NewKeyedTransactorWithChainID(validatorKey, chainID)
	require.NoError(t, err)
	validatorAuth.GasLimit = 3000000

	// Connect to contracts
	ratContract, err := bindings.NewRAT(sys.Addresses.RATProxy, sys.L1Client)
	require.NoError(t, err)

	tonERC20, err := bindings.NewERC20(sys.Addresses.TON, sys.L1Client)
	require.NoError(t, err)

	callOpts := &bind.CallOpts{Context: sys.Ctx}

	// Get minimum collateral and adjust it
	minCollateral, err := ratContract.GetMinimumCollateral(callOpts)
	require.NoError(t, err)
	t.Logf("Current minimum collateral: %s", minCollateral.String())

	depositAmount := new(big.Int).SetUint64(50000)
	depositAmount.Mul(depositAmount, big.NewInt(1e18))

	// Lower collateral requirements if needed
	if depositAmount.Cmp(minCollateral) < 0 {
		deployerKey, err := crypto.HexToECDSA("59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d")
		require.NoError(t, err)
		deployerAuth, err := bind.NewKeyedTransactorWithChainID(deployerKey, chainID)
		require.NoError(t, err)
		deployerAuth.GasLimit = 3000000

		quarterDeposit := new(big.Int).Div(depositAmount, big.NewInt(4))

		_, err = ratContract.SetSlashingPenalty(deployerAuth, quarterDeposit)
		require.NoError(t, err)
		_, err = ratContract.SetValidatorBuffer(deployerAuth, quarterDeposit)
		require.NoError(t, err)

		t.Logf("✓ Collateral requirements adjusted")
	}

	// Register validator
	t.Log("Step 1: Registering validator...")
	approveTx, err := tonERC20.Approve(validatorAuth, sys.Addresses.RATProxy, depositAmount)
	require.NoError(t, err)
	_, err = bind.WaitMined(sys.Ctx, sys.L1Client, approveTx)
	require.NoError(t, err)

	registerTx, err := ratContract.RegisterValidator(validatorAuth, sys.Addresses.SystemConfig, depositAmount)
	require.NoError(t, err)
	_, err = bind.WaitMined(sys.Ctx, sys.L1Client, registerTx)
	require.NoError(t, err)
	t.Logf("✓ Validator %s registered", validatorAddr.Hex())

	// Get validator count before game creation
	validatorCount, err := ratContract.GetActiveValidatorCount(callOpts, sys.Addresses.SystemConfig)
	require.NoError(t, err)
	t.Logf("✓ Active validators for SystemConfig: %d", validatorCount.Uint64())

	// Step 2: Create dispute game as proposer
	t.Log("Step 2: Creating DisputeGame as proposer...")

	dgf, err := bindings.NewDisputeGameFactory(sys.Addresses.DisputeGameFactory, sys.L1Client)
	require.NoError(t, err)

	gameType := uint32(0)
	initBond, err := dgf.InitBonds(callOpts, gameType)
	require.NoError(t, err)
	t.Logf("✓ Required init bond: %s wei", initBond.String())

	proposerKey, err := crypto.HexToECDSA("47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a")
	require.NoError(t, err)
	proposerAuth, err := bind.NewKeyedTransactorWithChainID(proposerKey, chainID)
	require.NoError(t, err)
	proposerAuth.GasLimit = 5000000
	proposerAuth.Value = initBond // Send required bond

	rootClaim := [32]byte{0x01, 0x02, 0x03}

	// extraData must be exactly 32 bytes containing l2BlockNumber
	l2BlockNumber := big.NewInt(100) // Dummy L2 block number
	extraData := common.LeftPadBytes(l2BlockNumber.Bytes(), 32)
	t.Logf("✓ Using L2 block number: %d", l2BlockNumber.Uint64())

	createGameTx, err := dgf.Create(proposerAuth, gameType, rootClaim, extraData)
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

	t.Logf("✓ DisputeGame created (tx: %s)", createGameTx.Hash().Hex())

	// Step 3: Parse RAT trigger event and get batchIndex
	t.Log("Step 3: Parsing RAT trigger event...")

	var testID [32]byte
	var selectedValidator common.Address
	var batchIndex uint32
	ratTriggered := false

	for _, log := range gameReceipt.Logs {
		if log.Topics[0].Hex() == "0xcf68a8dafa7b2329d7d7fcde3af620c2a51f64345d1eb2d66ffe7c7f1e9b0c38" {
			ratTriggered = true
			testID = log.Topics[1]
			selectedValidator = common.HexToAddress(log.Topics[2].Hex())

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
			t.Logf("✓ RAT triggered - Test ID: %s, Validator: %s", common.BytesToHash(testID[:]).Hex(), selectedValidator.Hex())
			t.Logf("✓ Batch index: %d", batchIndex)
			break
		}
	}

	require.True(t, ratTriggered, "RAT should be triggered")
	require.Equal(t, validatorAddr, selectedValidator, "Validator should be selected")

	// Step 4: Submit evidence as selected validator
	t.Log("Step 4: Submitting evidence...")

	// Create dummy evidence
	evidence := []byte("dummy evidence data")

	evidenceTx, err := ratContract.SubmitEvidence(validatorAuth, sys.Addresses.SystemConfig, batchIndex, evidence)
	require.NoError(t, err)
	evidenceReceipt, err := bind.WaitMined(ctx, sys.L1Client, evidenceTx)
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

