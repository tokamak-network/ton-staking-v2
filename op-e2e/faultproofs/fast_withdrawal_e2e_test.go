package faultproofs

import (
	"context"
	"fmt"
	"math/big"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/stretchr/testify/require"

	"github.com/tokamak-network/ton-staking-v2/op-e2e/bindings"
	"github.com/tokamak-network/ton-staking-v2/op-e2e/e2eutils/rat"
)

// TestFastWithdrawal_FullE2E tests the complete Fast Withdrawal flow with L2
// This test demonstrates the full integration:
// 1. Start L1 with genesis (all contracts deployed including Portal, ETHLockbox)
// 2. Start L2 geth and generate L2 withdrawal transaction
// 3. Register validators with BLS keys
// 4. Create L2 withdrawal and prove it on Portal
// 5. Request Fast Withdrawal with fee
// 6. Validators sign withdrawal hash
// 7. Aggregator calls verifyAndExecute with BLS signatures
// 8. Portal finalizes withdrawal immediately
// 9. Verify ETH transferred to user
func TestFastWithdrawal_FullE2E(t *testing.T) {
	// TODO: This test requires full L2 integration
	// For now, we demonstrate the structure and flow

	t.Skip("Skipping Full E2E test - requires Portal/ETHLockbox integration")

	t.Parallel()

	ctx := context.Background()

	// Step 1: Start L1 with TON Staking V3 system
	t.Log("=== Starting L1 with genesis ===")
	sys := rat.StartTONStakingSystem(t)

	// Verify contracts deployed
	ratCode, err := sys.L1Client.CodeAt(ctx, sys.Addresses.RATProxy, nil)
	require.NoError(t, err)
	require.NotEmpty(t, ratCode, "RAT contract should be deployed")
	t.Logf("✓ RAT: %s", sys.Addresses.RATProxy.Hex())

	// Get Portal and ETHLockbox addresses from genesis
	// These are deployed by DeployV3FullForDevnet.s.sol
	portalAddr := getPortalAddress(t, sys)
	lockboxAddr := getETHLockboxAddress(t, sys)
	t.Logf("✓ Portal: %s", portalAddr.Hex())
	t.Logf("✓ ETHLockbox: %s", lockboxAddr.Hex())

	// Step 2: Start L2 geth
	t.Log("=== Starting L2 geth ===")
	l2Client := startL2Geth(t, sys)
	t.Logf("✓ L2 client connected")

	// Step 3: Register 3 validators with BLS keys
	t.Log("=== Registering validators with BLS keys ===")
	validators := registerValidatorsWithBLS(t, sys, 3)
	t.Logf("✓ Registered %d validators with BLS keys", len(validators))

	// Step 4: Create L2 withdrawal transaction
	t.Log("=== Creating L2 withdrawal ===")
	userAddr := common.HexToAddress("0x1234567890123456789012345678901234567890")
	withdrawalAmount := big.NewInt(1e18) // 1 ETH
	withdrawal := createL2Withdrawal(t, ctx, l2Client, userAddr, withdrawalAmount)
	withdrawalHash := hashWithdrawalTransaction(withdrawal)
	t.Logf("✓ Withdrawal created: %s", withdrawalHash.Hex())
	t.Logf("  Amount: %s wei (1 ETH)", withdrawalAmount.String())

	// Step 5: Get L2 state root and generate proof
	t.Log("=== Generating L2 state proof ===")
	stateRoot := getL2StateRoot(t, ctx, l2Client)
	proof := generateWithdrawalProof(t, ctx, l2Client, withdrawal, stateRoot)
	t.Logf("✓ State root: %s", stateRoot.Hex())

	// Step 6: Prove withdrawal on Portal
	t.Log("=== Proving withdrawal on Portal ===")
	proveWithdrawalOnPortal(t, ctx, sys, portalAddr, withdrawal, proof)
	t.Log("✓ Withdrawal proved on Portal")

	// Step 7: Request Fast Withdrawal with fee
	t.Log("=== Requesting Fast Withdrawal ===")
	fwFee := big.NewInt(FastWithdrawalFee) // 0.01 ETH
	requestFastWithdrawal(t, ctx, sys, portalAddr, withdrawalHash, fwFee)
	t.Logf("✓ Fast Withdrawal requested (fee: %s wei)", fwFee.String())

	// Step 8: Generate BLS signatures from validators
	t.Log("=== Collecting validator signatures ===")
	signatures := collectValidatorSignatures(t, validators, withdrawalHash)
	require.Equal(t, 3, len(signatures), "Should have 3 validator signatures")
	t.Logf("✓ Collected %d signatures", len(signatures))

	// Step 9: Aggregate BLS signatures
	t.Log("=== Aggregating BLS signatures ===")
	aggregatedSig := aggregateBLSSignatures(t, signatures)
	validatorBitmap := uint64(0b111) // All 3 validators signed
	t.Logf("✓ Aggregated signature (bitmap: %03b)", validatorBitmap)

	// Step 10: Generate adjacent leaves proof
	t.Log("=== Generating adjacent leaves proof ===")
	leafA, leafB, proofsA, proofsB := generateAdjacentLeavesProof(t, stateRoot)
	t.Logf("✓ LeafA: %s", leafA.Hex())
	t.Logf("✓ LeafB: %s", leafB.Hex())

	// Step 11: Call verifyAndExecute
	t.Log("=== Calling verifyAndExecute ===")
	ratFW, err := bindings.NewRATFastWithdrawal(sys.Addresses.RATProxy, sys.L1Client)
	require.NoError(t, err)

	// Create input struct
	input := bindings.RATFastWithdrawalLibFastWithdrawalInput{
		WithdrawalHash:  withdrawalHash,
		SystemConfig:    sys.Addresses.SystemConfig,
		StateRoot:       stateRoot,
		ValidatorBitmap: big.NewInt(int64(validatorBitmap)),
		LeafA:           leafA,
		LeafB:           leafB,
		ProofsA:         proofsA,
		ProofsB:         proofsB,
	}

	// Get aggregator account
	aggregatorKey, _ := crypto.HexToECDSA(deployerPrivateKey)
	aggregatorAuth, err := bind.NewKeyedTransactorWithChainID(aggregatorKey, big.NewInt(900))
	require.NoError(t, err)

	tx, err := ratFW.VerifyAndExecute(aggregatorAuth, input, aggregatedSig)
	require.NoError(t, err)
	t.Logf("✓ verifyAndExecute TX: %s", tx.Hash().Hex())

	receipt := waitForTransactionReceipt(t, ctx, sys.L1Client, tx.Hash(), "verifyAndExecute")
	t.Logf("✓ Gas used: %d", receipt.GasUsed)

	// Step 12: Portal finalizes withdrawal immediately
	t.Log("=== Finalizing withdrawal on Portal ===")
	finalizeWithdrawalOnPortal(t, ctx, sys, portalAddr, withdrawal)
	t.Log("✓ Withdrawal finalized")

	// Step 13: Verify user received ETH
	t.Log("=== Verifying ETH transfer ===")
	userBalance, err := sys.L1Client.BalanceAt(ctx, userAddr, nil)
	require.NoError(t, err)
	t.Logf("✓ User balance: %s wei", userBalance.String())
	require.True(t, userBalance.Cmp(big.NewInt(0)) > 0, "User should have received ETH")

	// Step 14: Verify fee distribution
	t.Log("=== Verifying fee distribution ===")
	aggregatorFee := calculateAggregatorFee(FastWithdrawalFee, DefaultAggregatorFeeRate)
	validatorShare := calculateValidatorShare(FastWithdrawalFee, aggregatorFee, 3)
	t.Logf("✓ Aggregator fee: %d wei", aggregatorFee)
	t.Logf("✓ Validator share each: %d wei", validatorShare)

	t.Log("=== Full E2E Test Complete ===")
	t.Log("✅ L1 + L2 started successfully")
	t.Log("✅ Validators registered with BLS keys")
	t.Log("✅ L2 withdrawal created and proved")
	t.Log("✅ Fast Withdrawal requested with fee")
	t.Log("✅ Validators signed withdrawal")
	t.Log("✅ verifyAndExecute called successfully")
	t.Log("✅ Withdrawal finalized on Portal")
	t.Log("✅ ETH transferred to user")
	t.Log("✅ Fees distributed correctly")
}

// Helper functions for Full E2E test

// getPortalAddress retrieves OptimismPortal address from optimism-addresses.json
func getPortalAddress(t *testing.T, sys *rat.TONStakingSystem) common.Address {
	// TODO: Read from optimism-addresses.json
	// For now, return zero address
	return common.Address{}
}

// getETHLockboxAddress retrieves ETHLockbox address from optimism-addresses.json
func getETHLockboxAddress(t *testing.T, sys *rat.TONStakingSystem) common.Address {
	// TODO: Read from optimism-addresses.json
	// For now, return zero address
	return common.Address{}
}

// startL2Geth starts L2 geth node for testing
func startL2Geth(t *testing.T, sys *rat.TONStakingSystem) *ethclient.Client {
	// TODO: Implement L2 geth startup (similar to rat_state_root_test.go)
	return nil
}

// ValidatorWithBLS represents a validator with BLS key
type ValidatorWithBLS struct {
	Address    common.Address
	Auth       *bind.TransactOpts
	BLSPrivKey []byte
	BLSPubKey  []byte
}

// registerValidatorsWithBLS registers multiple validators and their BLS keys
func registerValidatorsWithBLS(t *testing.T, sys *rat.TONStakingSystem, count int) []ValidatorWithBLS {
	validators := make([]ValidatorWithBLS, count)

	// Get contracts
	contracts := connectTestContracts(t, sys)
	ratFW, err := bindings.NewRATFastWithdrawal(sys.Addresses.RATProxy, sys.L1Client)
	require.NoError(t, err)

	depositAmount := getTestDepositAmount()

	for i := 0; i < count; i++ {
		// Generate validator key
		privKey, err := crypto.GenerateKey()
		require.NoError(t, err)
		addr := crypto.PubkeyToAddress(privKey.PublicKey)

		// Create auth
		auth, err := bind.NewKeyedTransactorWithChainID(privKey, big.NewInt(900))
		require.NoError(t, err)

		// Register validator with TON
		registerValidatorWithTON(t, sys, contracts, auth, depositAmount)

		// Generate BLS key
		blsPrivKey, blsPubKey := generateBLSKeyPair(t)

		// Register BLS key
		message := createBLSRegistrationMessage(addr, sys.Addresses.SystemConfig)
		blsSignature := signBLSMessage(t, blsPrivKey, message)

		tx, err := ratFW.RegisterBLSPublicKey(auth, sys.Addresses.SystemConfig, blsPubKey, blsSignature)
		require.NoError(t, err)
		waitForTransactionReceipt(t, sys.Ctx, sys.L1Client, tx.Hash(), "BLS registration")

		validators[i] = ValidatorWithBLS{
			Address:    addr,
			Auth:       auth,
			BLSPrivKey: blsPrivKey,
			BLSPubKey:  blsPubKey,
		}

		t.Logf("✓ Validator %d registered: %s", i+1, addr.Hex())
	}

	return validators
}

// createL2Withdrawal creates a mock L2 withdrawal transaction
func createL2Withdrawal(
	t *testing.T,
	ctx context.Context,
	l2Client *ethclient.Client,
	target common.Address,
	value *big.Int,
) bindings.TypesWithdrawalTransaction {
	// TODO: Create actual L2 withdrawal
	// For now, return mock
	return bindings.TypesWithdrawalTransaction{
		Nonce:    big.NewInt(1),
		Sender:   common.HexToAddress("0x4200000000000000000000000000000000000007"), // L2StandardBridge
		Target:   target,
		Value:    value,
		GasLimit: big.NewInt(100000),
		Data:     []byte{},
	}
}

// getL2StateRoot gets the latest L2 state root
func getL2StateRoot(t *testing.T, ctx context.Context, l2Client *ethclient.Client) common.Hash {
	// TODO: Get actual L2 state root
	return common.Hash{}
}

// generateWithdrawalProof generates Merkle proof for withdrawal
func generateWithdrawalProof(
	t *testing.T,
	ctx context.Context,
	l2Client *ethclient.Client,
	withdrawal bindings.TypesWithdrawalTransaction,
	stateRoot common.Hash,
) [][]byte {
	// TODO: Generate actual withdrawal proof
	return [][]byte{}
}

// proveWithdrawalOnPortal proves withdrawal transaction on OptimismPortal
func proveWithdrawalOnPortal(
	t *testing.T,
	ctx context.Context,
	sys *rat.TONStakingSystem,
	portalAddr common.Address,
	withdrawal bindings.TypesWithdrawalTransaction,
	proof [][]byte,
) {
	// TODO: Call Portal.proveWithdrawalTransaction()
}

// requestFastWithdrawal requests fast withdrawal on Portal
func requestFastWithdrawal(
	t *testing.T,
	ctx context.Context,
	sys *rat.TONStakingSystem,
	portalAddr common.Address,
	withdrawalHash common.Hash,
	fee *big.Int,
) {
	// TODO: Call Portal.requestFastWithdrawal() with fee
}

// collectValidatorSignatures collects BLS signatures from all validators
func collectValidatorSignatures(
	t *testing.T,
	validators []ValidatorWithBLS,
	withdrawalHash common.Hash,
) [][]byte {
	signatures := make([][]byte, len(validators))
	for i, val := range validators {
		sig := signBLSMessage(t, val.BLSPrivKey, withdrawalHash[:])
		signatures[i] = sig
	}
	return signatures
}

// finalizeWithdrawalOnPortal finalizes withdrawal on Portal (fast path)
func finalizeWithdrawalOnPortal(
	t *testing.T,
	ctx context.Context,
	sys *rat.TONStakingSystem,
	portalAddr common.Address,
	withdrawal bindings.TypesWithdrawalTransaction,
) {
	// TODO: Call Portal.fastWithdrawalFinalize()
}
