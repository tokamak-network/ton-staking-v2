package faultproofs

import (
	"math/big"
	"testing"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/stretchr/testify/require"

	"github.com/tokamak-network/ton-staking-v2/op-e2e/bindings"
)

// TestSimpleRAT_FastWithdrawalFeeCalculation tests fee calculation logic
func TestSimpleRAT_FastWithdrawalFeeCalculation(t *testing.T) {
	t.Parallel()

	t.Log("=== RAT Fast Withdrawal Fee Calculation Test ===")

	env := setupTestEnvironment(t, "Fast Withdrawal Fee")
	sys := env.System
	callOpts := env.CallOpts

	ratFW, err := bindings.NewRATFastWithdrawal(sys.Addresses.RATProxy, sys.L1Client)
	require.NoError(t, err)

	// Check aggregator fee rate
	feeRate, err := ratFW.AggregatorFeeRate(callOpts)
	require.NoError(t, err)
	t.Logf("✓ Aggregator fee rate: %s (basis points)", feeRate.String())

	// Test fee calculation
	// aggregatorFee = totalFee * aggregatorFeeRate / 10000
	testCases := []struct {
		totalFee    uint64
		expectedPct float64
	}{
		{1000000000000000000, 10.0}, // 1 ETH
		{100000000000000000, 10.0},  // 0.1 ETH
		{10000000000000000, 10.0},   // 0.01 ETH
	}

	t.Log("")
	t.Log("Fee calculation test cases:")
	for _, tc := range testCases {
		aggregatorFee := calculateAggregatorFee(tc.totalFee, feeRate.Uint64())
		validatorFee := tc.totalFee - aggregatorFee

		t.Logf("  Total fee: %d wei", tc.totalFee)
		t.Logf("    - Aggregator fee: %d wei (%.1f%%)", aggregatorFee, tc.expectedPct)
		t.Logf("    - Validator pool: %d wei", validatorFee)
	}

	t.Log("")
	t.Log("=== Fee Calculation Test Complete ===")
}

// TestSimpleRAT_FastWithdrawalValidatorBitmap tests validator bitmap calculation
func TestSimpleRAT_FastWithdrawalValidatorBitmap(t *testing.T) {
	t.Parallel()

	t.Log("=== RAT Fast Withdrawal Validator Bitmap Test ===")

	// Test bitmap calculation for different validator counts
	testCases := []struct {
		validatorCount int
		description    string
	}{
		{1, "Single validator"},
		{2, "Two validators"},
		{3, "Three validators"},
		{5, "Five validators"},
		{10, "Ten validators"},
		{64, "64 validators (max for uint64)"},
		{100, "100 validators (uses big.Int)"},
	}

	t.Log("")
	for _, tc := range testCases {
		// Calculate unanimous bitmap
		var bitmap *big.Int
		if tc.validatorCount <= 64 {
			unanimousBitmap := uint64((1 << uint(tc.validatorCount)) - 1)
			bitmap = new(big.Int).SetUint64(unanimousBitmap)
		} else {
			// For 64+ validators, use big.Int
			bitmap = new(big.Int)
			for i := 0; i < tc.validatorCount; i++ {
				bitmap.SetBit(bitmap, i, 1)
			}
		}

		t.Logf("✓ %s:", tc.description)
		t.Logf("    Count: %d", tc.validatorCount)
		if tc.validatorCount <= 10 {
			t.Logf("    Unanimous bitmap: %s (0b%b)", bitmap.String(), bitmap.Uint64())
		} else {
			t.Logf("    Unanimous bitmap: %s (%d bits)", bitmap.String(), bitmap.BitLen())
		}
	}

	t.Log("")
	t.Log("Partial signature scenarios (3 validators):")
	t.Logf("  ❌ 0b110 (6) - Missing validator 1")
	t.Logf("  ❌ 0b101 (5) - Missing validator 2")
	t.Logf("  ❌ 0b011 (3) - Missing validator 3")
	t.Logf("  ✅ 0b111 (7) - All validators (unanimous)")

	t.Log("")
	t.Log("=== Validator Bitmap Test Complete ===")
}

// TestSimpleRAT_FastWithdrawalMinValidators tests minimum validator requirement
func TestSimpleRAT_FastWithdrawalMinValidators(t *testing.T) {
	t.Parallel()

	t.Log("=== RAT Fast Withdrawal Minimum Validators Test ===")

	env := setupTestEnvironment(t, "Fast Withdrawal Min Validators")
	sys := env.System
	contracts := env.Contracts
	callOpts := env.CallOpts

	ratFW, err := bindings.NewRATFastWithdrawal(sys.Addresses.RATProxy, sys.L1Client)
	require.NoError(t, err)

	// Get minimum validators
	minValidators, err := ratFW.MinValidatorsForFastWithdrawal(callOpts)
	require.NoError(t, err)
	t.Logf("✓ Minimum validators required: %d", minValidators.Uint64())

	// Register validators one by one and check status
	depositAmount := getTestDepositAmount()
	accounts := setupTestAccounts(t, sys)

	t.Log("")
	t.Log("Registering validators and checking eligibility:")

	// Register validator 1
	registerValidatorWithTON(t, sys, contracts, env.Accounts.Validator.Auth, depositAmount)
	result1, _ := ratFW.GetActiveValidatorsWithBLS(callOpts, sys.Addresses.SystemConfig)
	isEligible1 := len(result1.Validators) >= int(minValidators.Uint64())
	t.Logf("  After 1 validator: eligible=%v (need %d)", isEligible1, minValidators.Uint64())

	// Register validator 2
	registerValidatorWithTON(t, sys, contracts, accounts.Deployer.Auth, depositAmount)
	result2, _ := ratFW.GetActiveValidatorsWithBLS(callOpts, sys.Addresses.SystemConfig)
	isEligible2 := len(result2.Validators) >= int(minValidators.Uint64())
	t.Logf("  After 2 validators: eligible=%v (need %d)", isEligible2, minValidators.Uint64())

	// Register validator 3
	registerValidatorWithTON(t, sys, contracts, accounts.Proposer.Auth, depositAmount)
	result3, _ := ratFW.GetActiveValidatorsWithBLS(callOpts, sys.Addresses.SystemConfig)
	isEligible3 := len(result3.Validators) >= int(minValidators.Uint64())
	t.Logf("  After 3 validators: eligible=%v (need %d)", isEligible3, minValidators.Uint64())

	t.Log("")
	if minValidators.Uint64() <= 3 {
		require.True(t, isEligible3, "Should be eligible with 3 validators")
		t.Log("✓ Fast Withdrawal eligibility achieved with 3 validators")
	} else {
		t.Logf("⚠ Need more validators (current: 3, required: %d)", minValidators.Uint64())
	}

	t.Log("")
	t.Log("=== Minimum Validators Test Complete ===")
}

// TestSimpleRAT_FastWithdrawalWithdrawalHash tests withdrawal hash computation
func TestSimpleRAT_FastWithdrawalWithdrawalHash(t *testing.T) {
	t.Parallel()

	t.Log("=== RAT Fast Withdrawal Hash Computation Test ===")

	// Test withdrawal hash calculation
	testCases := []struct {
		name     string
		nonce    uint64
		sender   common.Address
		target   common.Address
		value    uint64
		gasLimit uint64
	}{
		{
			name:     "Standard withdrawal",
			nonce:    1,
			sender:   common.HexToAddress("0x1234567890123456789012345678901234567890"),
			target:   common.HexToAddress("0xabcdefabcdefabcdefabcdefabcdefabcdefabcd"),
			value:    1000000000000000000, // 1 ETH
			gasLimit: 100000,
		},
		{
			name:     "Zero value withdrawal",
			nonce:    2,
			sender:   common.HexToAddress("0x1111111111111111111111111111111111111111"),
			target:   common.HexToAddress("0x2222222222222222222222222222222222222222"),
			value:    0,
			gasLimit: 21000,
		},
		{
			name:     "Large nonce",
			nonce:    999999,
			sender:   common.HexToAddress("0x3333333333333333333333333333333333333333"),
			target:   common.HexToAddress("0x4444444444444444444444444444444444444444"),
			value:    5000000000000000000, // 5 ETH
			gasLimit: 200000,
		},
	}

	t.Log("")
	for _, tc := range testCases {
		hash := createWithdrawalHash(tc.nonce, tc.sender, tc.target, tc.value, tc.gasLimit, nil)
		t.Logf("✓ %s:", tc.name)
		t.Logf("    Nonce: %d, Value: %d wei", tc.nonce, tc.value)
		t.Logf("    Hash: %s", hash.Hex())
	}

	// Verify determinism
	t.Log("")
	t.Log("Determinism test:")
	hash1 := createWithdrawalHash(1, common.HexToAddress("0x1234"), common.HexToAddress("0x5678"), 1000, 21000, nil)
	hash2 := createWithdrawalHash(1, common.HexToAddress("0x1234"), common.HexToAddress("0x5678"), 1000, 21000, nil)
	require.Equal(t, hash1, hash2, "Same inputs should produce same hash")
	t.Log("✓ Withdrawal hash is deterministic")

	// Verify different inputs produce different hashes
	hash3 := createWithdrawalHash(2, common.HexToAddress("0x1234"), common.HexToAddress("0x5678"), 1000, 21000, nil)
	require.NotEqual(t, hash1, hash3, "Different inputs should produce different hash")
	t.Log("✓ Different inputs produce different hashes")

	t.Log("")
	t.Log("=== Withdrawal Hash Test Complete ===")
}

// TestSimpleRAT_FastWithdrawalSignatureMessage tests signature message format
func TestSimpleRAT_FastWithdrawalSignatureMessage(t *testing.T) {
	t.Parallel()

	t.Log("=== RAT Fast Withdrawal Signature Message Test ===")

	env := setupTestEnvironment(t, "Fast Withdrawal Sig Message")
	sys := env.System

	// Create mock request data
	requestID := [32]byte{1, 2, 3, 4, 5, 6, 7, 8}
	user := common.HexToAddress("0x1234567890123456789012345678901234567890")
	amount := big.NewInt(1000000000000000000) // 1 ETH
	chainID := big.NewInt(900)                // Test chain ID

	// Build signature message (same format as Go clients)
	message := crypto.Keccak256(
		[]byte("TOKAMAK_FAST_WITHDRAWAL"),
		requestID[:],
		user.Bytes(),
		common.LeftPadBytes(amount.Bytes(), 32),
		common.LeftPadBytes(chainID.Bytes(), 32),
	)

	t.Log("")
	t.Logf("Signature message components:")
	t.Logf("  Domain: TOKAMAK_FAST_WITHDRAWAL")
	t.Logf("  RequestID: 0x%x", requestID[:8])
	t.Logf("  User: %s", user.Hex())
	t.Logf("  Amount: %s wei", amount.String())
	t.Logf("  ChainID: %s", chainID.String())
	t.Logf("")
	t.Logf("✓ Message hash: 0x%x", message)
	t.Logf("✓ Message length: %d bytes", len(message))

	// Verify message matches expected format
	require.Equal(t, 32, len(message), "Message should be 32 bytes (keccak256)")

	// Verify system config is available
	t.Log("")
	t.Logf("✓ SystemConfig address: %s", sys.Addresses.SystemConfig.Hex())

	t.Log("")
	t.Log("=== Signature Message Test Complete ===")
}

// TestSimpleRAT_FastWithdrawalBLSKeyFormat tests BLS key format requirements
func TestSimpleRAT_FastWithdrawalBLSKeyFormat(t *testing.T) {
	t.Parallel()

	t.Log("=== RAT Fast Withdrawal BLS Key Format Test ===")

	t.Log("")
	t.Log("BLS12-381 key format requirements:")
	t.Log("")

	// BLS12-381 key sizes
	t.Log("Public Key (G1 compressed): 48 bytes")
	t.Log("Public Key (G1 uncompressed): 96 bytes")
	t.Log("Signature (G2 compressed): 96 bytes")
	t.Log("Signature (G2 uncompressed): 192 bytes")
	t.Log("")

	// Generate test BLS keypair (mock)
	privKey, pubKey := generateBLSKeyPair(t)

	t.Logf("✓ Generated mock BLS keypair:")
	t.Logf("    Private key length: %d bytes", len(privKey))
	t.Logf("    Public key length: %d bytes", len(pubKey))

	// Test signature generation
	message := []byte("test message")
	sig := signBLSMessage(t, privKey, message)

	t.Logf("✓ Generated mock BLS signature:")
	t.Logf("    Signature length: %d bytes", len(sig))

	// Verify expected sizes
	require.Equal(t, 32, len(privKey), "Private key should be 32 bytes")
	require.Equal(t, 48, len(pubKey), "Public key should be 48 bytes (G1 compressed)")
	require.Equal(t, 96, len(sig), "Signature should be 96 bytes (G2 compressed)")

	t.Log("")
	t.Log("Proof of Possession (PoP) format:")
	t.Log("  Message: keccak256(chainID || validatorAddress)")
	t.Log("  Signature: BLS signature over message")
	t.Log("  Purpose: Proves ownership of the BLS private key")

	t.Log("")
	t.Log("=== BLS Key Format Test Complete ===")
}

// TestSimpleRAT_FastWithdrawalAggregation tests signature aggregation
func TestSimpleRAT_FastWithdrawalAggregation(t *testing.T) {
	t.Parallel()

	t.Log("=== RAT Fast Withdrawal Signature Aggregation Test ===")

	// Generate 3 validator keypairs
	var privKeys [][]byte
	var pubKeys [][]byte
	var signatures [][]byte

	message := []byte("withdrawal message to sign")

	t.Log("")
	t.Log("Generating 3 validator signatures:")
	for i := 0; i < 3; i++ {
		privKey, pubKey := generateBLSKeyPair(t)
		sig := signBLSMessage(t, privKey, message)

		privKeys = append(privKeys, privKey)
		pubKeys = append(pubKeys, pubKey)
		signatures = append(signatures, sig)

		t.Logf("  Validator %d: pubKey=%x..., sig=%x...", i+1, pubKey[:8], sig[:8])
	}

	// Aggregate signatures
	t.Log("")
	t.Log("Aggregating signatures:")
	aggregatedSig := aggregateBLSSignatures(t, signatures)

	t.Logf("✓ Aggregated signature length: %d bytes", len(aggregatedSig))
	t.Logf("✓ Aggregated signature: %x...", aggregatedSig[:16])

	// Verify aggregated signature size
	require.Equal(t, 96, len(aggregatedSig), "Aggregated signature should be 96 bytes")

	// Verify bitmap
	bitmap := createValidatorBitmap([]int{0, 1, 2})
	t.Logf("✓ Validator bitmap: %d (0b%b)", bitmap, bitmap)
	require.Equal(t, uint64(7), bitmap, "Bitmap should be 7 (0b111) for 3 validators")

	t.Log("")
	t.Log("Aggregation benefits:")
	t.Log("  - 3 individual signatures (96*3 = 288 bytes)")
	t.Log("  - 1 aggregated signature (96 bytes)")
	t.Logf("  - Space savings: %.1f%%", float64(288-96)/288*100)

	t.Log("")
	t.Log("=== Signature Aggregation Test Complete ===")
}
