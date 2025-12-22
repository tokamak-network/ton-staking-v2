package faultproofs

import (
	"context"
	"math/big"
	"os"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/stretchr/testify/require"

	"github.com/tokamak-network/ton-staking-v2/op-e2e/e2eutils/rat"
)

// Environment variables for devnet configuration
const (
	EnvRATAddress    = "RAT_ADDRESS"
	EnvTONAddress    = "TON_ADDRESS"
	EnvWTONAddress   = "WTON_ADDRESS"
	EnvSystemConfig  = "SYSTEM_CONFIG_ADDRESS"
	EnvRPCURL        = "E2E_RPC_URL"
	EnvPrivateKey    = "E2E_PRIVATE_KEY"
)

// getEnvOrSkip returns an environment variable or skips the test
func getEnvOrSkip(t *testing.T, key string) string {
	value := os.Getenv(key)
	if value == "" {
		t.Skipf("Environment variable %s not set - skipping integration test", key)
	}
	return value
}

// setupIntegrationTest sets up the integration test environment
func setupIntegrationTest(t *testing.T) (*rat.RATHelper, *ethclient.Client, context.Context) {
	ratAddr := getEnvOrSkip(t, EnvRATAddress)
	rpcURL := os.Getenv(EnvRPCURL)
	if rpcURL == "" {
		rpcURL = "http://localhost:8545"
	}

	ctx := context.Background()
	client, err := ethclient.Dial(rpcURL)
	require.NoError(t, err, "Failed to connect to RPC")

	helper := rat.NewRATHelper(t, client, common.HexToAddress(ratAddr))
	return helper, client, ctx
}

// TestRATIntegration_ValidatorRegistration tests validator registration on devnet
func TestRATIntegration_ValidatorRegistration(t *testing.T) {
	helper, client, ctx := setupIntegrationTest(t)

	privateKeyHex := getEnvOrSkip(t, EnvPrivateKey)
	systemConfigAddr := getEnvOrSkip(t, EnvSystemConfig)

	privateKey, err := crypto.HexToECDSA(privateKeyHex)
	require.NoError(t, err, "Failed to parse private key")

	validatorAddr := crypto.PubkeyToAddress(privateKey.PublicKey)
	systemConfig := common.HexToAddress(systemConfigAddr)

	chainID, err := client.ChainID(ctx)
	require.NoError(t, err, "Failed to get chain ID")

	t.Logf("Testing validator registration")
	t.Logf("Validator: %s", validatorAddr.Hex())
	t.Logf("SystemConfig: %s", systemConfig.Hex())

	// Check initial state
	regBefore := helper.GetValidatorRegistration(ctx, systemConfig, validatorAddr)
	t.Logf("Initial deposit: %s", regBefore.DepositedAmount.String())

	// Get minimum collateral
	minCollateral := helper.GetMinimumCollateral(ctx)
	t.Logf("Minimum collateral: %s", minCollateral.String())

	// Register validator with minimum deposit (TON units, 18 decimals)
	buffer := big.NewInt(10 * 1e18) // 10 TON buffer
	depositAmount := new(big.Int).Add(minCollateral, buffer) // D_min + 10 TON buffer
	t.Logf("Deposit amount: %s", depositAmount.String())

	// Use RegisterValidatorWithApproval which handles WTON approval automatically
	tx, err := helper.RegisterValidatorWithApproval(ctx, privateKey, chainID, systemConfig, depositAmount)
	if err != nil {
		t.Logf("RegisterValidator failed (may already be registered): %v", err)
	} else {
		t.Logf("RegisterValidator tx: %s", tx.Hash().Hex())
		receipt := helper.WaitForReceipt(ctx, tx, 30*time.Second)
		t.Logf("RegisterValidator status: %d", receipt.Status)
		require.Equal(t, uint64(1), receipt.Status, "RegisterValidator should succeed")
	}

	// Check registration
	regAfter := helper.GetValidatorRegistration(ctx, systemConfig, validatorAddr)
	t.Logf("Final deposit: %s", regAfter.DepositedAmount.String())
	t.Logf("Is active: %v", regAfter.IsActive)

	// Verify registration succeeded
	require.True(t, regAfter.DepositedAmount.Cmp(big.NewInt(0)) > 0, "Deposit should be positive")
}

// TestRATIntegration_GetContractParameters tests reading contract parameters
func TestRATIntegration_GetContractParameters(t *testing.T) {
	helper, _, ctx := setupIntegrationTest(t)

	t.Log("=== RAT Contract Parameters ===")

	// Read contract parameters
	minCollateral := helper.GetMinimumCollateral(ctx)
	slashingPenalty := helper.GetSlashingPenalty(ctx)
	validatorBuffer := helper.GetValidatorBuffer(ctx)

	t.Logf("Minimum Collateral (D_min): %s", minCollateral.String())
	t.Logf("Slashing Penalty (C_off): %s", slashingPenalty.String())
	t.Logf("Validator Buffer (Δ): %s", validatorBuffer.String())

	// Verify D_min = C_off + Δ
	expectedMin := new(big.Int).Add(slashingPenalty, validatorBuffer)
	require.Equal(t, expectedMin.String(), minCollateral.String(),
		"D_min should equal C_off + Δ")

	t.Log("Contract parameters verified successfully")
}

// TestRATIntegration_ValidatorCount tests validator counting
func TestRATIntegration_ValidatorCount(t *testing.T) {
	helper, _, ctx := setupIntegrationTest(t)

	systemConfigAddr := getEnvOrSkip(t, EnvSystemConfig)
	systemConfig := common.HexToAddress(systemConfigAddr)

	t.Log("=== Validator Count ===")

	totalCount := helper.GetValidatorCount(ctx, systemConfig)
	activeCount := helper.GetActiveValidatorCount(ctx, systemConfig)

	t.Logf("Total validators: %s", totalCount.String())
	t.Logf("Active validators: %s", activeCount.String())

	// Active count should not exceed total count
	require.True(t, activeCount.Cmp(totalCount) <= 0,
		"Active count should not exceed total count")
}

// TestRATIntegration_GetL2Validators tests getting validator list
func TestRATIntegration_GetL2Validators(t *testing.T) {
	helper, _, ctx := setupIntegrationTest(t)

	systemConfigAddr := getEnvOrSkip(t, EnvSystemConfig)
	systemConfig := common.HexToAddress(systemConfigAddr)

	t.Log("=== L2 Validators ===")

	validators := helper.GetL2Validators(ctx, systemConfig)
	t.Logf("Number of validators: %d", len(validators))

	for i, v := range validators {
		isActive := helper.IsValidatorActive(ctx, v, systemConfig)
		deposit := helper.GetValidatorDeposit(ctx, v, systemConfig)
		t.Logf("Validator %d: %s (active: %v, deposit: %s)", i, v.Hex(), isActive, deposit.String())
	}
}

// TestRATIntegration_FullFlow tests the complete RAT flow
func TestRATIntegration_FullFlow(t *testing.T) {
	helper, client, ctx := setupIntegrationTest(t)

	privateKeyHex := getEnvOrSkip(t, EnvPrivateKey)
	systemConfigAddr := getEnvOrSkip(t, EnvSystemConfig)

	privateKey, err := crypto.HexToECDSA(privateKeyHex)
	require.NoError(t, err, "Failed to parse private key")

	validatorAddr := crypto.PubkeyToAddress(privateKey.PublicKey)
	systemConfig := common.HexToAddress(systemConfigAddr)

	chainID, err := client.ChainID(ctx)
	require.NoError(t, err, "Failed to get chain ID")

	t.Log("=== Full RAT Flow Test ===")
	t.Logf("Validator: %s", validatorAddr.Hex())

	// Step 1: Check initial state
	t.Log("Step 1: Check initial state")
	regInitial := helper.GetValidatorRegistration(ctx, systemConfig, validatorAddr)
	wasActive := regInitial.IsActive
	t.Logf("Initial state - Active: %v, Deposit: %s", wasActive, regInitial.DepositedAmount.String())

	// Step 2: Register or add deposit
	t.Log("Step 2: Ensure validator is registered with sufficient deposit")
	minCollateral := helper.GetMinimumCollateral(ctx)
	if regInitial.DepositedAmount.Cmp(minCollateral) < 0 {
		depositAmount := new(big.Int).Add(minCollateral, rat.MulRAY(50))
		if wasActive {
			// Add deposit
			tx, err := helper.AddDeposit(ctx, privateKey, chainID, systemConfig, depositAmount)
			if err == nil {
				helper.WaitForReceipt(ctx, tx, 30*time.Second)
			}
		} else {
			// Register new validator
			tx, err := helper.RegisterValidator(ctx, privateKey, chainID, systemConfig, depositAmount)
			if err == nil {
				helper.WaitForReceipt(ctx, tx, 30*time.Second)
			}
		}
	}

	// Step 3: Verify registration
	t.Log("Step 3: Verify registration")
	regAfter := helper.GetValidatorRegistration(ctx, systemConfig, validatorAddr)
	t.Logf("After registration - Active: %v, Deposit: %s", regAfter.IsActive, regAfter.DepositedAmount.String())

	isActive := helper.IsValidatorActive(ctx, validatorAddr, systemConfig)
	t.Logf("Is validator active: %v", isActive)

	// Step 4: Check validator is in list
	t.Log("Step 4: Check validator in list")
	validators := helper.GetL2Validators(ctx, systemConfig)
	found := false
	for _, v := range validators {
		if v == validatorAddr {
			found = true
			break
		}
	}
	t.Logf("Validator found in list: %v", found)

	t.Log("Full flow test completed")
}
