package faultproofs

import (
	"testing"

	"github.com/stretchr/testify/require"
	rat "github.com/tokamak-network/ton-staking-v2/op-e2e/e2eutils/rat"
)

// TestSlashing_Simple - 간단한 버전으로 먼저 테스트
func TestSlashing_Simple(t *testing.T) {
	t.Parallel()

	// Start TON Staking system
	sys := rat.StartTONStakingSystem(t)

	t.Log("=== Simple Slashing Test ===")
	t.Logf("RAT: %s", sys.Addresses.RATProxy.Hex())
	t.Logf("SeigManager: %s", sys.Addresses.SeigManagerProxy.Hex())
	t.Logf("Layer2Manager: %s", sys.Addresses.Layer2ManagerProxy.Hex())

	// Setup accounts
	accounts := setupTestAccounts(t, sys)
	t.Logf("Operator: %s", accounts.Validator.Addr.Hex())

	// For now, just verify the system is running
	require.NotNil(t, sys.L1Client, "L1 client should be connected")

	t.Log("✅ System is ready for slashing tests!")
	t.Log("Next step: Implement operator registration without rollupConfig dependency")
}
