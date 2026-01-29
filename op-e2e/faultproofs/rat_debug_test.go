package faultproofs

import (
	"testing"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/stretchr/testify/require"
)

// TestRAT_DirectTrigger tests calling RAT.triggerAttentionTest() directly to see if it reverts
func TestRAT_DirectTrigger(t *testing.T) {
	t.Parallel()

	// Use setupTestEnvironment for cleaner initialization
	env := setupTestEnvironment(t, "Direct RAT Trigger")
	sys := env.System
	accounts := env.Accounts
	contracts := env.Contracts
	callOpts := env.CallOpts

	depositAmount := getTestDepositAmount()

	// Register validator
	t.Log("Registering validator...")
	registerValidatorWithTON(t, sys, contracts, accounts.Validator.Auth, depositAmount)

	// Verify validator is active
	isActive, err := contracts.RAT.IsValidatorActive(callOpts, accounts.Validator.Addr, sys.Addresses.SystemConfig)
	require.NoError(t, err)
	require.True(t, isActive, "Validator should be active")
	t.Logf("✓ Validator is active")

	// Get active validator count
	validatorCount, err := contracts.RAT.GetActiveValidatorCount(callOpts, sys.Addresses.SystemConfig)
	require.NoError(t, err)
	t.Logf("✓ Active validators: %d", validatorCount.Uint64())

	// Try to call triggerAttentionTest directly from DisputeGameFactory account
	// This should help us see if there's a revert and what the error is
	t.Log("")
	t.Log("=== Attempting Direct RAT Trigger ===")

	// Use proposer auth to simulate DisputeGameFactory calling RAT
	gameAddress := common.HexToAddress("0x1234567890123456789012345678901234567890")
	batchIndex := uint32(0)
	batchHash := [32]byte{0x01, 0x02, 0x03}
	blockHash := [32]byte{0x04, 0x05, 0x06}

	// This will likely fail because proposer is not the factory, but we can see the error
	tx, err := contracts.RAT.TriggerAttentionTest(
		accounts.Proposer.Auth,
		gameAddress,
		sys.Addresses.SystemConfig,
		batchIndex,
		batchHash,
		blockHash,
	)

	if err != nil {
		t.Logf("❌ triggerAttentionTest failed (expected - proposer is not factory): %v", err)
	} else {
		receipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, tx)
		require.NoError(t, err)

		if receipt.Status == 0 {
			t.Logf("❌ Transaction reverted")
		} else {
			t.Logf("✅ Transaction succeeded!")
			t.Logf("   Logs count: %d", len(receipt.Logs))
			for i, log := range receipt.Logs {
				t.Logf("   Log %d: Address=%s, Topics=%d", i, log.Address.Hex(), len(log.Topics))
				if len(log.Topics) > 0 {
					t.Logf("     Topic[0]=%s", log.Topics[0].Hex())
				}
			}
		}
	}

	t.Log("=== Direct Trigger Test Complete ===")
}
