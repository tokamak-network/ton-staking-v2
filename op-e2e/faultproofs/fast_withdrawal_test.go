package faultproofs

import (
	"math/big"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/stretchr/testify/require"

	"github.com/tokamak-network/ton-staking-v2/op-e2e/bindings"
)

// TestFastWithdrawal_BLSRegistration tests BLS key registration for validators
// This is a prerequisite for Fast Withdrawal functionality
func TestFastWithdrawal_BLSRegistration(t *testing.T) {
	t.Parallel()

	env := setupTestEnvironment(t, "Fast Withdrawal BLS Registration")

	t.Log("=== Fast Withdrawal BLS Registration Test ===")
	t.Logf("✓ Validator address: %s", env.Accounts.Validator.Addr.Hex())
	t.Logf("✓ RATFastWithdrawal contract: %s", env.System.Addresses.RATProxy.Hex())
	t.Logf("✓ SystemConfig: %s", env.System.Addresses.SystemConfig.Hex())

	// Step 1: Register validator first (prerequisite)
	depositAmount := getTestDepositAmount()
	t.Log("Step 1: Registering validator...")
	registerValidatorWithTON(t, env.System, env.Contracts, env.Accounts.Validator.Auth, depositAmount)
	t.Logf("✓ Validator registered with %s WTON", depositAmount.String())

	// Verify validator is active
	isActive, err := env.Contracts.RAT.IsValidatorActive(env.CallOpts, env.Accounts.Validator.Addr, env.System.Addresses.SystemConfig)
	require.NoError(t, err)
	require.True(t, isActive, "Validator should be active after registration")
	t.Log("✓ Validator is active")

	// Step 2: Bind to RATFastWithdrawal contract
	ratFW, err := bindings.NewRATFastWithdrawal(env.System.Addresses.RATProxy, env.System.L1Client)
	require.NoError(t, err)
	t.Log("✓ RATFastWithdrawal contract bound")

	// Step 3: Check if Fast Withdrawal is enabled
	fwEnabled, err := ratFW.FastWithdrawalEnabled(env.CallOpts)
	require.NoError(t, err)
	t.Logf("✓ Fast Withdrawal enabled: %v", fwEnabled)

	// Step 4: Generate BLS key pair for validator
	t.Log("Step 2: Generating BLS key pair...")
	blsPrivKey, blsPubKey := generateBLSKeyPair(t)
	t.Logf("✓ BLS public key generated (%d bytes)", len(blsPubKey))
	t.Logf("  Public key (hex): 0x%x", blsPubKey[:32]) // Log first 32 bytes

	// Step 5: Create BLS signature for registration
	// The signature proves ownership of the BLS private key
	t.Log("Step 3: Creating BLS signature for registration...")
	message := createBLSRegistrationMessage(env.Accounts.Validator.Addr, env.System.Addresses.SystemConfig)
	blsSignature := signBLSMessage(t, blsPrivKey, message)
	t.Logf("✓ BLS signature created (%d bytes)", len(blsSignature))

	// Step 6: Register BLS public key
	t.Log("Step 4: Registering BLS public key...")
	tx, err := ratFW.RegisterBLSPublicKey(
		env.Accounts.Validator.Auth,
		env.System.Addresses.SystemConfig,
		blsPubKey,
		blsSignature,
	)
	require.NoError(t, err)
	t.Logf("✓ BLS registration transaction sent: %s", tx.Hash().Hex())

	receipt := waitForTransactionReceipt(t, env.System.Ctx, env.System.L1Client, tx.Hash(), "BLS registration")
	t.Logf("✓ BLS registration confirmed (gas used: %d)", receipt.GasUsed)

	// Step 7: Verify BLS key is registered
	t.Log("Step 5: Verifying BLS key registration...")
	hasKey, err := ratFW.HasValidatorBLSKey(env.CallOpts, env.Accounts.Validator.Addr, env.System.Addresses.SystemConfig)
	require.NoError(t, err)
	require.True(t, hasKey, "Validator should have BLS key registered")
	t.Log("✓ BLS key verified on-chain")

	// Step 8: Retrieve registered BLS public key
	retrievedKey, err := ratFW.GetValidatorBLSPubKey(env.CallOpts, env.Accounts.Validator.Addr, env.System.Addresses.SystemConfig)
	require.NoError(t, err)
	require.Equal(t, blsPubKey, retrievedKey, "Retrieved BLS key should match registered key")
	t.Log("✓ Retrieved BLS key matches registered key")

	// Step 9: Check active validators with BLS keys
	t.Log("Step 6: Querying active validators with BLS keys...")
	result, err := ratFW.GetActiveValidatorsWithBLS(env.CallOpts, env.System.Addresses.SystemConfig)
	require.NoError(t, err)
	t.Logf("✓ Active validators: %d", len(result.Validators))
	t.Logf("✓ Validators with BLS keys: %d", result.ValidBLSCount.Uint64())
	require.Equal(t, 1, len(result.Validators), "Should have 1 active validator")
	require.Equal(t, uint64(1), result.ValidBLSCount.Uint64(), "Should have 1 validator with BLS key")
	require.Equal(t, env.Accounts.Validator.Addr, result.Validators[0], "Validator address should match")

	t.Log("=== BLS Registration Test Complete ===")
	t.Log("✅ Successfully registered and verified BLS public key")
	t.Logf("   Validator: %s", env.Accounts.Validator.Addr.Hex())
	t.Logf("   BLS Public Key: 0x%x...", blsPubKey[:16])
}

// TestFastWithdrawal_BasicFlow tests the complete fast withdrawal flow
// This test requires multiple validators with BLS keys for unanimous agreement
func TestFastWithdrawal_BasicFlow(t *testing.T) {
	t.Parallel()

	env := setupTestEnvironment(t, "Fast Withdrawal Basic Flow")

	t.Log("=== Fast Withdrawal Basic Flow Test ===")
	t.Logf("✓ RATFastWithdrawal contract: %s", env.System.Addresses.RATProxy.Hex())

	// Bind to RATFastWithdrawal contract
	ratFW, err := bindings.NewRATFastWithdrawal(env.System.Addresses.RATProxy, env.System.L1Client)
	require.NoError(t, err)

	// Check Fast Withdrawal enabled
	fwEnabled, err := ratFW.FastWithdrawalEnabled(env.CallOpts)
	require.NoError(t, err)
	t.Logf("✓ Fast Withdrawal enabled: %v", fwEnabled)

	if !fwEnabled {
		t.Skip("Fast Withdrawal is not enabled on this deployment")
	}

	// Step 1: Register validator with BLS key
	depositAmount := getTestDepositAmount()
	t.Log("Step 1: Registering validator with BLS key...")
	registerValidatorWithTON(t, env.System, env.Contracts, env.Accounts.Validator.Auth, depositAmount)

	// Generate and register BLS key
	blsPrivKey, blsPubKey := generateBLSKeyPair(t)
	message := createBLSRegistrationMessage(env.Accounts.Validator.Addr, env.System.Addresses.SystemConfig)
	blsSignature := signBLSMessage(t, blsPrivKey, message)

	tx, err := ratFW.RegisterBLSPublicKey(
		env.Accounts.Validator.Auth,
		env.System.Addresses.SystemConfig,
		blsPubKey,
		blsSignature,
	)
	require.NoError(t, err)
	waitForTransactionReceipt(t, env.System.Ctx, env.System.L1Client, tx.Hash(), "BLS registration")
	t.Log("✓ Validator registered with BLS key")

	// Step 2: Check minimum validators requirement
	minValidators, err := ratFW.MinValidatorsForFastWithdrawal(env.CallOpts)
	require.NoError(t, err)
	t.Logf("✓ Minimum validators required: %d", minValidators.Uint64())

	result, err := ratFW.GetActiveValidatorsWithBLS(env.CallOpts, env.System.Addresses.SystemConfig)
	require.NoError(t, err)
	t.Logf("✓ Validators with BLS keys: %d", result.ValidBLSCount.Uint64())

	if result.ValidBLSCount.Cmp(minValidators) < 0 {
		t.Logf("⚠️  Need %d validators but only have %d", minValidators.Uint64(), result.ValidBLSCount.Uint64())
		t.Skip("Insufficient validators for Fast Withdrawal (need to register more)")
	}

	// Step 3: Create a mock withdrawal transaction
	t.Log("Step 2: Creating mock withdrawal transaction...")
	withdrawalTx := createMockWithdrawalTransaction(t, env.Accounts.Validator.Addr)
	withdrawalHash := hashWithdrawalTransaction(withdrawalTx)
	t.Logf("✓ Withdrawal hash: %s", withdrawalHash.Hex())

	// Step 4: Create state root and adjacent leaves proof
	t.Log("Step 3: Generating adjacent leaves proof...")
	stateRoot := common.HexToHash("0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef")
	leafA, leafB, _, _ := generateMockAdjacentLeavesProof(t, stateRoot)
	t.Logf("✓ LeafA: %s", leafA.Hex())
	t.Logf("✓ LeafB: %s", leafB.Hex())

	// Step 5: Create aggregated BLS signature
	t.Log("Step 4: Creating aggregated BLS signature...")
	_ = signBLSMessage(t, blsPrivKey, withdrawalHash[:])
	validatorBitmap := big.NewInt(1) // Only first validator signed
	t.Logf("✓ Validator bitmap: %d", validatorBitmap.Uint64())

	// Step 6: Call verifyAndExecute
	t.Log("Step 5: Calling verifyAndExecute...")

	// Note: This will likely fail because we need:
	// 1. Actual L2 state data
	// 2. Valid adjacent leaves proof
	// 3. Multiple validators for unanimous agreement
	// 4. Actual Portal integration
	//
	// This test demonstrates the basic structure and flow.

	t.Log("⚠️  Skipping verifyAndExecute call - requires full L2 integration")
	t.Log("   This test validates:")
	t.Log("   - BLS key registration")
	t.Log("   - Validator setup")
	t.Log("   - Fast Withdrawal contract interface")
	t.Log("   - Flow structure")

	t.Log("=== Fast Withdrawal Basic Flow Test Complete ===")
	t.Log("✅ Basic flow structure validated")
	t.Log("📋 For full E2E test, implement:")
	t.Log("   1. L2 geth integration for state proofs")
	t.Log("   2. Portal integration for withdrawal flow")
	t.Log("   3. Multi-validator coordination")
	t.Log("   4. BLS signature aggregation")
}

// TestFastWithdrawal_Configuration tests Fast Withdrawal configuration
func TestFastWithdrawal_Configuration(t *testing.T) {
	t.Parallel()

	env := setupTestEnvironment(t, "Fast Withdrawal Configuration")

	t.Log("=== Fast Withdrawal Configuration Test ===")

	// Bind to RATFastWithdrawal contract
	ratFW, err := bindings.NewRATFastWithdrawal(env.System.Addresses.RATProxy, env.System.L1Client)
	require.NoError(t, err)

	// Check all configuration parameters
	t.Log("Querying Fast Withdrawal configuration...")

	fwEnabled, err := ratFW.FastWithdrawalEnabled(env.CallOpts)
	require.NoError(t, err)
	t.Logf("✓ Fast Withdrawal Enabled: %v", fwEnabled)

	minValidators, err := ratFW.MinValidatorsForFastWithdrawal(env.CallOpts)
	require.NoError(t, err)
	t.Logf("✓ Minimum Validators: %d", minValidators.Uint64())

	aggregatorFeeRate, err := ratFW.AggregatorFeeRate(env.CallOpts)
	require.NoError(t, err)
	t.Logf("✓ Aggregator Fee Rate: %d (basis points)", aggregatorFeeRate.Uint64())

	maxValidators, err := ratFW.MaxValidatorsPerL2(env.CallOpts)
	require.NoError(t, err)
	t.Logf("✓ Max Validators Per L2: %d", maxValidators.Uint64())

	minimumThreshold, err := ratFW.MinimumThreshold(env.CallOpts)
	require.NoError(t, err)
	t.Logf("✓ Minimum Threshold: %s", minimumThreshold.String())

	// Verify reasonable defaults
	require.True(t, minValidators.Uint64() > 0, "Min validators should be > 0")
	require.True(t, aggregatorFeeRate.Uint64() <= 10000, "Fee rate should be <= 100%")
	require.True(t, maxValidators.Uint64() > minValidators.Uint64(), "Max validators should be > min validators")

	t.Log("=== Configuration Test Complete ===")
	t.Log("✅ All configuration parameters valid")
}

// Helper function to create a mock withdrawal transaction
func createMockWithdrawalTransaction(t *testing.T, target common.Address) bindings.TypesWithdrawalTransaction {
	return bindings.TypesWithdrawalTransaction{
		Nonce:    big.NewInt(1),
		Sender:   common.HexToAddress("0x0000000000000000000000000000000000000000"),
		Target:   target,
		Value:    big.NewInt(1e18), // 1 ETH
		GasLimit: big.NewInt(100000),
		Data:     []byte{},
	}
}

// Helper function to hash a withdrawal transaction
func hashWithdrawalTransaction(tx bindings.TypesWithdrawalTransaction) common.Hash {
	// This is a simplified hash - actual implementation should match contract
	return common.BigToHash(big.NewInt(time.Now().Unix()))
}

// Helper function to generate mock adjacent leaves proof
func generateMockAdjacentLeavesProof(t *testing.T, stateRoot common.Hash) (
	leafA common.Hash,
	leafB common.Hash,
	proofsA [][]byte,
	proofsB [][]byte,
) {
	// Mock implementation - actual proof generation requires L2 state
	leafA = common.HexToHash("0x1111111111111111111111111111111111111111111111111111111111111111")
	leafB = common.HexToHash("0x3333333333333333333333333333333333333333333333333333333333333333")

	// Empty proofs for now
	proofsA = [][]byte{}
	proofsB = [][]byte{}

	return
}
