package faultproofs

import (
	"math/big"
	"testing"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/stretchr/testify/require"

	"github.com/tokamak-network/ton-staking-v2/op-e2e/e2eutils/rat"
)

// TestTONStakingSystemStartup verifies that TON Staking V3 system starts correctly
// This is the most basic test - just start the system and verify contracts are deployed
func TestTONStakingSystemStartup(t *testing.T) {
	t.Parallel()

	// Start system using allocs-l1-staking-v3.json
	sys := rat.StartTONStakingSystem(t)
	ctx := sys.Ctx

	t.Log("=== Verifying System Startup ===")

	// Verify L1 client is connected
	chainID, err := sys.L1Client.ChainID(ctx)
	require.NoError(t, err)
	require.Equal(t, int64(900), chainID.Int64(), "Chain ID should be 900")
	t.Logf("✓ L1 client connected (Chain ID: %d)", chainID.Int64())

	// Verify TON contract exists
	tonCode, err := sys.L1Client.CodeAt(ctx, sys.Addresses.TON, nil)
	require.NoError(t, err)
	require.NotEmpty(t, tonCode, "TON contract should have code")
	t.Logf("✓ TON contract deployed at %s (%d bytes)", sys.Addresses.TON.Hex(), len(tonCode))

	// Verify WTON contract exists
	wtonCode, err := sys.L1Client.CodeAt(ctx, sys.Addresses.WTON, nil)
	require.NoError(t, err)
	require.NotEmpty(t, wtonCode, "WTON contract should have code")
	t.Logf("✓ WTON contract deployed at %s (%d bytes)", sys.Addresses.WTON.Hex(), len(wtonCode))

	// Verify RAT contract exists
	ratCode, err := sys.L1Client.CodeAt(ctx, sys.Addresses.RATProxy, nil)
	require.NoError(t, err)
	require.NotEmpty(t, ratCode, "RAT contract should have code")
	t.Logf("✓ RAT contract deployed at %s (%d bytes)", sys.Addresses.RATProxy.Hex(), len(ratCode))

	// Verify SeigManager contract exists
	seigCode, err := sys.L1Client.CodeAt(ctx, sys.Addresses.SeigManagerProxy, nil)
	require.NoError(t, err)
	require.NotEmpty(t, seigCode, "SeigManager contract should have code")
	t.Logf("✓ SeigManager contract deployed at %s (%d bytes)", sys.Addresses.SeigManagerProxy.Hex(), len(seigCode))

	// Verify DisputeGameFactory contract exists
	dgfCode, err := sys.L1Client.CodeAt(ctx, sys.Addresses.DisputeGameFactory, nil)
	require.NoError(t, err)
	require.NotEmpty(t, dgfCode, "DisputeGameFactory contract should have code")
	t.Logf("✓ DisputeGameFactory contract deployed at %s (%d bytes)", sys.Addresses.DisputeGameFactory.Hex(), len(dgfCode))

	t.Log("=== System Startup Verification Complete ===")
}

// TestAccountBalances verifies that test accounts have initial balances
func TestAccountBalances(t *testing.T) {
	t.Parallel()

	sys := rat.StartTONStakingSystem(t)
	ctx := sys.Ctx

	t.Log("=== Verifying Account Balances ===")

	// Get deployer account from addresses
	tonStakingDeployer := sys.Addresses.Accounts["tonStakingDeployer"]
	require.NotEqual(t, common.Address{}, tonStakingDeployer, "TON Staking deployer should be set")

	// Check ETH balance
	balance, err := sys.L1Client.BalanceAt(ctx, tonStakingDeployer, nil)
	require.NoError(t, err)
	require.True(t, balance.Cmp(big.NewInt(0)) > 0, "Deployer should have ETH balance")
	t.Logf("✓ Deployer %s has %s wei", tonStakingDeployer.Hex(), balance.String())

	// Check validator account
	validator := sys.Addresses.Accounts["validator"]
	require.NotEqual(t, common.Address{}, validator, "Validator should be set")

	validatorBalance, err := sys.L1Client.BalanceAt(ctx, validator, nil)
	require.NoError(t, err)
	require.True(t, validatorBalance.Cmp(big.NewInt(0)) > 0, "Validator should have ETH balance")
	t.Logf("✓ Validator %s has %s wei", validator.Hex(), validatorBalance.String())

	t.Log("=== Account Balance Verification Complete ===")
}

// TestRATContractCall verifies we can call RAT contract functions
func TestRATContractCall(t *testing.T) {
	t.Parallel()

	sys := rat.StartTONStakingSystem(t)

	t.Log("=== Testing RAT Contract Calls ===")

	// Connect to RAT contract using bindings
	contracts := connectTestContracts(t, sys)
	callOpts := &bind.CallOpts{Context: sys.Ctx}

	// Test view function calls
	minCollateral, err := contracts.RAT.GetMinimumCollateral(callOpts)
	require.NoError(t, err)
	t.Logf("✓ RAT.getMinimumCollateral(): %s WTON", minCollateral.String())

	// Test getActiveValidatorCount (should be 0 initially)
	validatorCount, err := contracts.RAT.GetActiveValidatorCount(callOpts, sys.Addresses.SystemConfig)
	require.NoError(t, err)
	t.Logf("✓ RAT.getActiveValidatorCount(): %d", validatorCount.Uint64())

	t.Logf("✓ RAT contract ready for calls at %s", sys.Addresses.RATProxy.Hex())

	t.Log("=== RAT Contract Call Test Complete ===")
}
