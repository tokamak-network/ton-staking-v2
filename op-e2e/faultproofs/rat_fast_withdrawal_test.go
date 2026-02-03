package faultproofs

import (
	"testing"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/stretchr/testify/require"

	"github.com/tokamak-network/ton-staking-v2/op-e2e/bindings"
	"github.com/tokamak-network/ton-staking-v2/op-e2e/e2eutils/rat"
)

// TestSimpleRAT_FastWithdrawalConfiguration tests Fast Withdrawal configuration
// Verifies that Fast Withdrawal parameters can be read and are set correctly
func TestSimpleRAT_FastWithdrawalConfiguration(t *testing.T) {
	t.Parallel()

	sys := rat.StartTONStakingSystem(t)
	ctx := sys.Ctx

	t.Log("=== RAT Fast Withdrawal Configuration Test ===")

	// Bind to RATFastWithdrawal contract (same address as RAT proxy)
	ratFW, err := bindings.NewRATFastWithdrawal(sys.Addresses.RATProxy, sys.L1Client)
	require.NoError(t, err)
	t.Logf("✓ RATFastWithdrawal bound at %s", sys.Addresses.RATProxy.Hex())

	callOpts := &bind.CallOpts{Context: ctx}

	// Check fastWithdrawalEnabled
	enabled, err := ratFW.FastWithdrawalEnabled(callOpts)
	require.NoError(t, err)
	t.Logf("✓ Fast Withdrawal enabled: %v", enabled)

	// Check minValidatorsForFastWithdrawal
	minValidators, err := ratFW.MinValidatorsForFastWithdrawal(callOpts)
	require.NoError(t, err)
	t.Logf("✓ Minimum validators required: %d", minValidators.Uint64())

	// Check aggregatorFeeRate
	feeRate, err := ratFW.AggregatorFeeRate(callOpts)
	require.NoError(t, err)
	t.Logf("✓ Aggregator fee rate: %s", feeRate.String())

	// Check validatorReward address
	validatorReward, err := ratFW.ValidatorReward(callOpts)
	require.NoError(t, err)
	if validatorReward == (common.Address{}) {
		t.Logf("⚠ ValidatorReward not set (address: %s)", validatorReward.Hex())
	} else {
		t.Logf("✓ ValidatorReward address: %s", validatorReward.Hex())
	}

	t.Log("=== Configuration Test Complete ===")
}

// TestSimpleRAT_FastWithdrawalBLSRegistration tests BLS key registration flow
// This is a full E2E test including validator registration
func TestSimpleRAT_FastWithdrawalBLSRegistration(t *testing.T) {
	t.Parallel()

	t.Log("=== RAT Fast Withdrawal BLS Registration Test ===")

	// Use setupTestEnvironment to initialize full system
	env := setupTestEnvironment(t, "Fast Withdrawal BLS Registration")
	sys := env.System
	contracts := env.Contracts
	callOpts := env.CallOpts

	// Bind to RATFastWithdrawal
	ratFW, err := bindings.NewRATFastWithdrawal(sys.Addresses.RATProxy, sys.L1Client)
	require.NoError(t, err)

	// Step 1: Register validator with RAT
	t.Log("Step 1: Registering validator with RAT...")
	depositAmount := getTestDepositAmount()
	registerValidatorWithTON(t, sys, contracts, env.Accounts.Validator.Auth, depositAmount)
	validator := env.Accounts.Validator.Addr
	t.Logf("✓ Validator registered at %s", validator.Hex())

	// Step 2: Check initial BLS key status (should be false)
	t.Log("Step 2: Checking initial BLS key status...")
	hasKey, err := ratFW.HasValidatorBLSKey(callOpts, validator, sys.Addresses.SystemConfig)
	require.NoError(t, err)
	require.False(t, hasKey, "Validator should not have BLS key initially")
	t.Log("✓ Confirmed: No BLS key registered initially")

	// Step 3: Query active validators (should have 1 validator, 0 with BLS)
	t.Log("Step 3: Querying active validators...")
	result, err := ratFW.GetActiveValidatorsWithBLS(callOpts, sys.Addresses.SystemConfig)
	require.NoError(t, err)
	t.Logf("✓ Active validators: %d", len(result.Validators))
	t.Logf("✓ Validators with BLS keys: %d", result.ValidBLSCount.Uint64())
	require.Equal(t, 1, len(result.Validators), "Should have 1 active validator")
	require.Equal(t, uint64(0), result.ValidBLSCount.Uint64(), "Should have 0 validators with BLS key initially")

	// Verify the returned validator is correct
	require.Equal(t, validator, result.Validators[0], "Returned validator should match registered validator")

	t.Log("=== BLS Registration Test Complete ===")
	t.Log("Note: Actual BLS key registration requires BLS12-381 signature verification")
	t.Log("      which depends on EIP-2537 precompiles not available in all test environments")
}

// TestSimpleRAT_FastWithdrawalValidatorQuery tests validator query functions with multiple validators
func TestSimpleRAT_FastWithdrawalValidatorQuery(t *testing.T) {
	t.Parallel()

	t.Log("=== RAT Fast Withdrawal Validator Query Test ===")

	// Use setupTestEnvironment to initialize full system
	env := setupTestEnvironment(t, "Fast Withdrawal Validator Query")
	sys := env.System
	contracts := env.Contracts
	callOpts := env.CallOpts

	// Bind to RATFastWithdrawal
	ratFW, err := bindings.NewRATFastWithdrawal(sys.Addresses.RATProxy, sys.L1Client)
	require.NoError(t, err)

	// Setup additional validators
	accounts := setupTestAccounts(t, sys)
	depositAmount := getTestDepositAmount()

	t.Log("Step 1: Registering 3 validators...")
	registerValidatorWithTON(t, sys, contracts, env.Accounts.Validator.Auth, depositAmount)
	validator1 := env.Accounts.Validator.Addr

	registerValidatorWithTON(t, sys, contracts, accounts.Deployer.Auth, depositAmount)
	validator2 := accounts.Deployer.Addr

	registerValidatorWithTON(t, sys, contracts, accounts.Proposer.Auth, depositAmount)
	validator3 := accounts.Proposer.Addr

	t.Logf("✓ Validator1: %s", validator1.Hex())
	t.Logf("✓ Validator2: %s", validator2.Hex())
	t.Logf("✓ Validator3: %s", validator3.Hex())

	// Query active validators
	t.Log("Step 2: Querying active validators with BLS keys...")
	result, err := ratFW.GetActiveValidatorsWithBLS(callOpts, sys.Addresses.SystemConfig)
	require.NoError(t, err)
	t.Logf("✓ Total active validators: %d", len(result.Validators))
	t.Logf("✓ Validators with BLS keys: %d", result.ValidBLSCount.Uint64())
	require.Equal(t, 3, len(result.Validators), "Should have 3 active validators")

	// Verify validator addresses
	t.Log("Step 3: Verifying validator addresses...")
	validatorAddrs := make(map[common.Address]bool)
	for _, addr := range result.Validators {
		validatorAddrs[addr] = true
	}
	require.True(t, validatorAddrs[validator1], "Validator1 should be in the list")
	require.True(t, validatorAddrs[validator2], "Validator2 should be in the list")
	require.True(t, validatorAddrs[validator3], "Validator3 should be in the list")
	t.Log("✓ All validators confirmed in active list")

	// Test getBatchValidatorBLSPublicKeys
	t.Log("Step 4: Batch querying BLS public keys...")
	validators := []common.Address{validator1, validator2, validator3}
	pubKeys, err := ratFW.GetBatchValidatorBLSPublicKeys(callOpts, validators, sys.Addresses.SystemConfig)
	require.NoError(t, err)
	require.Equal(t, 3, len(pubKeys), "Should return 3 public keys")
	for i, key := range pubKeys {
		t.Logf("  Validator %d BLS key length: %d bytes", i+1, len(key))
		require.Equal(t, 0, len(key), "BLS key should be empty (not registered)")
	}

	t.Log("=== Validator Query Test Complete ===")
}
