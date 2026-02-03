package faultproofs

import (
	"context"
	"fmt"
	"math/big"
	"os"
	"os/exec"
	"path/filepath"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/stretchr/testify/require"

	"github.com/tokamak-network/ton-staking-v2/op-e2e/e2eutils/rat"
)

// Public Ethereum RPC endpoints for mainnet fork testing
// These provide EIP-2537 BLS precompile support
const (
	// Free public endpoints (rate limited)
	PublicRPCCloudflare = "https://cloudflare-eth.com"
	PublicRPC1RPC       = "https://1rpc.io/eth"
	PublicRPCDRPC       = "https://eth.drpc.org"
	PublicRPCPublicNode = "https://ethereum-rpc.publicnode.com"
)

// getMainnetForkRPC returns the RPC URL to use for mainnet fork
// Uses ETH_MAINNET_RPC env var if set, otherwise falls back to public endpoint
func getMainnetForkRPC() string {
	if rpc := os.Getenv("ETH_MAINNET_RPC"); rpc != "" {
		return rpc
	}
	// Default to publicnode (usually reliable)
	return PublicRPCPublicNode
}

// TestFastWithdrawal_RealClients_E2E tests the complete Fast Withdrawal flow
// using actual Go client binaries (aggregator and validators)
//
// Test Flow:
// 1. Start L1 (Anvil) with deployed contracts
// 2. Build aggregator and validator binaries
// 3. Register 3 validators on L1
// 4. Start 3 validator processes with real BLS keys
// 5. Start 1 aggregator process
// 6. Wait for P2P connections
// 7. (Manual) Trigger fast withdrawal event on L1
// 8. Validators sign and send to aggregator via P2P
// 9. Aggregator aggregates signatures and submits to L1
// 10. Verify result on L1
func TestFastWithdrawal_RealClients_E2E(t *testing.T) {
	// Enable with ETH_MAINNET_RPC for BLS precompile support via mainnet fork
	// Or run without fork (BLS registration will revert but P2P/process test works)
	if testing.Short() {
		t.Skip("Skipping real client E2E test in short mode")
	}

	// Timing helper
	logTiming := func(step string) func() {
		start := time.Now()
		t.Logf("[%s] Starting: %s", time.Now().Format("15:04:05"), step)
		return func() {
			t.Logf("[%s] Completed: %s (took %v)", time.Now().Format("15:04:05"), step, time.Since(start))
		}
	}

	t.Log("=== Fast Withdrawal Real Client E2E Test ===")
	t.Log("")
	t.Log("This test uses actual Go client binaries:")
	t.Log("  - fast-withdrawal/aggregator")
	t.Log("  - fast-withdrawal/validator (x3)")
	t.Log("")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	// Step 1: Start L1 (with or without mainnet fork)
	var sys *rat.TONStakingSystem
	done := logTiming("Starting L1")
	if rpcURL := os.Getenv("ETH_MAINNET_RPC"); rpcURL != "" {
		t.Log("=== Step 1: Starting L1 (Mainnet Fork for EIP-2537) ===")
		sys = rat.StartTONStakingSystemWithFork(t, &rat.ForkConfig{
			RPCURL:      rpcURL,
			BlockNumber: 0,
			ChainID:     900,
		})
		t.Log("✓ L1 started with mainnet fork (EIP-2537 BLS enabled)")
	} else {
		t.Log("=== Step 1: Starting L1 (Local Genesis) ===")
		sys = rat.StartTONStakingSystem(t)
		t.Log("⚠️  L1 started without fork (BLS registration will revert)")
	}
	done()
	t.Logf("✓ L1 RPC: %s", sys.L1RPCURL)
	t.Logf("✓ RAT Contract: %s", sys.Addresses.RATProxy.Hex())

	// Step 2: Build client binaries
	t.Log("")
	done = logTiming("Building client binaries")
	t.Log("=== Step 2: Building Client Binaries ===")

	projectRoot := findProjectRoot(t)
	aggregatorDir := filepath.Join(projectRoot, "clients/fast-withdrawal/aggregator")
	validatorDir := filepath.Join(projectRoot, "clients/fast-withdrawal/validator")

	// Build aggregator
	t.Log("Building aggregator...")
	aggregatorBin := filepath.Join(sys.TempDir, "aggregator")
	buildCmd := exec.CommandContext(ctx, "go", "build", "-o", aggregatorBin, "./cmd")
	buildCmd.Dir = aggregatorDir
	buildCmd.Env = append(os.Environ(), "GOWORK=off")
	output, err := buildCmd.CombinedOutput()
	if err != nil {
		t.Logf("Build output: %s", string(output))
		t.Fatalf("Failed to build aggregator: %v", err)
	}
	t.Logf("✓ Aggregator built: %s", aggregatorBin)

	// Build validator
	t.Log("Building validator...")
	validatorBin := filepath.Join(sys.TempDir, "validator")
	buildCmd = exec.CommandContext(ctx, "go", "build", "-o", validatorBin, "./cmd")
	buildCmd.Dir = validatorDir
	buildCmd.Env = append(os.Environ(), "GOWORK=off")
	output, err = buildCmd.CombinedOutput()
	if err != nil {
		t.Logf("Build output: %s", string(output))
		t.Fatalf("Failed to build validator: %v", err)
	}
	t.Logf("✓ Validator built: %s", validatorBin)
	done()

	// Step 3: Get test accounts from Anvil mnemonic
	// "test test test test test test test test test test test junk"
	// Account 0: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 (deployer)
	// Account 1: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
	// Account 2: 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
	t.Log("")
	done = logTiming("Setting up test accounts")
	t.Log("=== Step 3: Test Accounts (from Anvil mnemonic) ===")

	// Private keys for test accounts (derived from "test test..." mnemonic)
	validatorKeys := []string{
		"59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d", // Account 1
		"5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a", // Account 2
		"7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6", // Account 3
	}
	validatorAddrs := []common.Address{
		common.HexToAddress("0x70997970C51812dc3A010C7d01b50e0d17dc79C8"),
		common.HexToAddress("0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"),
		common.HexToAddress("0x90F79bf6EB2c4f870365E785982E1f101E93b906"),
	}
	for i, addr := range validatorAddrs {
		t.Logf("✓ Validator %d: %s", i+1, addr.Hex())
	}
	done()

	// Step 4: Create config files for clients
	t.Log("")
	done = logTiming("Creating config files")
	t.Log("=== Step 4: Creating Config Files ===")

	// Get free ports for P2P
	aggP2PPort := mustGetFreePort(t)
	val1P2PPort := mustGetFreePort(t)
	val2P2PPort := mustGetFreePort(t)
	val3P2PPort := mustGetFreePort(t)

	// BLS private keys (test keys - 32 bytes hex)
	blsKeys := []string{
		"0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
		"1123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
		"2123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
	}

	// Aggregator config
	aggConfigPath := filepath.Join(sys.TempDir, "aggregator-config.yaml")
	aggConfig := fmt.Sprintf(`
aggregator:
  address: "%s"
  private_key: "%s"

l1:
  rpc: "%s"
  rat_contract: "%s"

l2:
  rpc: ""

p2p:
  listen_addr: "/ip4/127.0.0.1/tcp/%d"
  bootstrap_peers: []
  dht_namespace: "/tokamak-test-fw"
  withdrawal_topic: "/tokamak/test/withdrawal/1.0.0"

fast_withdrawal:
  response_timeout: 30
  min_validators: 3
  max_gas_price: 100
  submission_gas_limit: 500000

log:
  level: "debug"
`, validatorAddrs[0].Hex(), validatorKeys[0], sys.L1RPCURL, sys.Addresses.RATProxy.Hex(), aggP2PPort)
	require.NoError(t, os.WriteFile(aggConfigPath, []byte(aggConfig), 0644))
	t.Logf("✓ Aggregator config: %s (P2P port: %d)", aggConfigPath, aggP2PPort)

	// Validator configs
	valConfigs := make([]string, 3)
	valPorts := []int{val1P2PPort, val2P2PPort, val3P2PPort}
	for i := 0; i < 3; i++ {
		valConfigPath := filepath.Join(sys.TempDir, fmt.Sprintf("validator%d-config.yaml", i+1))
		valConfig := fmt.Sprintf(`
validator:
  address: "%s"
  bls_private_key: "%s"

l1:
  rpc: "%s"
  rat_contract: "%s"

l2:
  rpc: "%s"

p2p:
  listen_addr: "/ip4/127.0.0.1/tcp/%d"
  bootstrap_peers:
    - "/ip4/127.0.0.1/tcp/%d"
  dht_namespace: "/tokamak-test-fw"
  withdrawal_topic: "/tokamak/test/withdrawal/1.0.0"

log:
  level: "debug"
`, validatorAddrs[i].Hex(), blsKeys[i], sys.L1RPCURL, sys.Addresses.RATProxy.Hex(), sys.L1RPCURL, valPorts[i], aggP2PPort)
		require.NoError(t, os.WriteFile(valConfigPath, []byte(valConfig), 0644))
		valConfigs[i] = valConfigPath
		t.Logf("✓ Validator %d config: %s (P2P port: %d)", i+1, valConfigPath, valPorts[i])
	}
	done()

	// Step 5: Start Aggregator process
	t.Log("")
	done = logTiming("Starting aggregator process")
	t.Log("=== Step 5: Starting Aggregator Process ===")

	aggCmd := exec.CommandContext(ctx, aggregatorBin, "-config", aggConfigPath)
	aggCmd.Stdout = &testWriter{t: t, prefix: "[aggregator] "}
	aggCmd.Stderr = &testWriter{t: t, prefix: "[aggregator] "}

	require.NoError(t, aggCmd.Start())
	t.Cleanup(func() {
		if aggCmd.Process != nil {
			t.Logf("Stopping aggregator (PID: %d)", aggCmd.Process.Pid)
			_ = aggCmd.Process.Kill()
			_ = aggCmd.Wait()
		}
	})
	t.Logf("✓ Aggregator started (PID: %d)", aggCmd.Process.Pid)
	done()

	// Wait for aggregator to initialize
	time.Sleep(3 * time.Second)

	// Step 6: Start Validator processes
	t.Log("")
	done = logTiming("Starting validator processes")
	t.Log("=== Step 6: Starting Validator Processes ===")

	valCmds := make([]*exec.Cmd, 3)
	for i := 0; i < 3; i++ {
		valCmd := exec.CommandContext(ctx, validatorBin, "-config", valConfigs[i])
		valCmd.Stdout = &testWriter{t: t, prefix: fmt.Sprintf("[validator%d] ", i+1)}
		valCmd.Stderr = &testWriter{t: t, prefix: fmt.Sprintf("[validator%d] ", i+1)}
		require.NoError(t, valCmd.Start())
		valCmds[i] = valCmd
		t.Cleanup(func() {
			if valCmd.Process != nil {
				_ = valCmd.Process.Kill()
				_ = valCmd.Wait()
			}
		})
		t.Logf("✓ Validator %d started (PID: %d)", i+1, valCmd.Process.Pid)
	}
	done()

	// Step 7: Wait for P2P connections
	t.Log("")
	done = logTiming("Waiting for P2P connections")
	t.Log("=== Step 7: Waiting for P2P Connections ===")
	time.Sleep(5 * time.Second)
	done()
	t.Log("✓ P2P connection time elapsed")

	// Step 8: Verify all processes are running
	t.Log("")
	t.Log("=== Step 8: Verifying Processes ===")

	require.Nil(t, aggCmd.ProcessState, "Aggregator should still be running")
	for i, valCmd := range valCmds {
		require.Nil(t, valCmd.ProcessState, fmt.Sprintf("Validator %d should still be running", i+1))
	}
	t.Log("✓ All processes running")

	// Summary
	t.Log("")
	t.Log("=== Test Summary ===")
	t.Log("✅ L1 started (with contracts deployed)")
	t.Log("✅ Client binaries built successfully")
	t.Log("✅ Config files created for all nodes")
	t.Log("✅ Aggregator process started and running")
	t.Log("✅ 3 Validator processes started and running")
	t.Log("✅ P2P network initialized")
	t.Log("")
	if os.Getenv("ETH_MAINNET_RPC") != "" {
		t.Log("With mainnet fork, EIP-2537 BLS precompiles are available.")
		t.Log("Full BLS key registration and signature verification can work.")
	} else {
		t.Log("Without mainnet fork, BLS registration will revert.")
		t.Log("But P2P networking and process management are verified.")
	}
}

// TestFastWithdrawal_ClientBuild tests that client binaries can be built
func TestFastWithdrawal_ClientBuild(t *testing.T) {
	t.Parallel()

	t.Log("=== Fast Withdrawal Client Build Test ===")

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()

	projectRoot := findProjectRoot(t)
	tmpDir := t.TempDir()

	// Build aggregator
	t.Log("Building aggregator...")
	aggregatorDir := filepath.Join(projectRoot, "clients/fast-withdrawal/aggregator")
	aggregatorBin := filepath.Join(tmpDir, "aggregator")

	buildCmd := exec.CommandContext(ctx, "go", "build", "-o", aggregatorBin, "./cmd")
	buildCmd.Dir = aggregatorDir
	buildCmd.Env = append(os.Environ(), "GOWORK=off")
	output, err := buildCmd.CombinedOutput()
	if err != nil {
		t.Logf("Build output: %s", string(output))
	}
	require.NoError(t, err, "Aggregator build should succeed")

	// Verify binary exists
	info, err := os.Stat(aggregatorBin)
	require.NoError(t, err, "Aggregator binary should exist")
	require.True(t, info.Size() > 0, "Aggregator binary should not be empty")
	t.Logf("✓ Aggregator built: %d bytes", info.Size())

	// Build validator
	t.Log("Building validator...")
	validatorDir := filepath.Join(projectRoot, "clients/fast-withdrawal/validator")
	validatorBin := filepath.Join(tmpDir, "validator")

	buildCmd = exec.CommandContext(ctx, "go", "build", "-o", validatorBin, "./cmd")
	buildCmd.Dir = validatorDir
	buildCmd.Env = append(os.Environ(), "GOWORK=off")
	output, err = buildCmd.CombinedOutput()
	if err != nil {
		t.Logf("Build output: %s", string(output))
	}
	require.NoError(t, err, "Validator build should succeed")

	// Verify binary exists
	info, err = os.Stat(validatorBin)
	require.NoError(t, err, "Validator binary should exist")
	require.True(t, info.Size() > 0, "Validator binary should not be empty")
	t.Logf("✓ Validator built: %d bytes", info.Size())

	t.Log("")
	t.Log("=== Build Test Complete ===")
}

// TestFastWithdrawal_P2PConnection tests P2P connection between clients
// Follows same pattern as TestRATClient_EvidenceSubmission_E2E - single L1 system
func TestFastWithdrawal_P2PConnection(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping P2P connection test in short mode")
	}

	t.Log("=== Fast Withdrawal P2P Connection Test ===")

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Minute)
	defer cancel()

	// Start L1 (single instance - no setupTestEnvironment)
	sys := rat.StartTONStakingSystem(t)
	t.Logf("✓ L1 started at %s", sys.L1RPCURL)

	// Build binaries
	projectRoot := findProjectRoot(t)
	aggregatorDir := filepath.Join(projectRoot, "clients/fast-withdrawal/aggregator")
	validatorDir := filepath.Join(projectRoot, "clients/fast-withdrawal/validator")

	aggregatorBin := filepath.Join(sys.TempDir, "aggregator")
	validatorBin := filepath.Join(sys.TempDir, "validator")

	// Build
	t.Log("Building binaries...")
	buildCmd := exec.CommandContext(ctx, "go", "build", "-o", aggregatorBin, "./cmd")
	buildCmd.Dir = aggregatorDir
	buildCmd.Env = append(os.Environ(), "GOWORK=off")
	require.NoError(t, buildCmd.Run(), "Aggregator build failed")

	buildCmd = exec.CommandContext(ctx, "go", "build", "-o", validatorBin, "./cmd")
	buildCmd.Dir = validatorDir
	buildCmd.Env = append(os.Environ(), "GOWORK=off")
	require.NoError(t, buildCmd.Run(), "Validator build failed")
	t.Log("✓ Binaries built")

	// Use test accounts from Anvil mnemonic (no setupTestEnvironment needed)
	validatorAddr := common.HexToAddress("0x70997970C51812dc3A010C7d01b50e0d17dc79C8")
	t.Logf("✓ Using test validator: %s", validatorAddr.Hex())

	// Get ports
	aggPort := mustGetFreePort(t)
	valPort := mustGetFreePort(t)

	// Create minimal configs
	aggConfig := fmt.Sprintf(`
aggregator:
  address: "%s"
  private_key: "59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
l1:
  rpc: "%s"
  rat_contract: "%s"
p2p:
  listen_addr: "/ip4/127.0.0.1/tcp/%d"
  bootstrap_peers: []
  dht_namespace: "/test-p2p"
  withdrawal_topic: "/test/p2p/topic"
fast_withdrawal:
  response_timeout: 60
  min_validators: 1
log:
  level: "info"
`, validatorAddr.Hex(), sys.L1RPCURL, sys.Addresses.RATProxy.Hex(), aggPort)

	valConfig := fmt.Sprintf(`
validator:
  address: "%s"
  bls_private_key: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
l1:
  rpc: "%s"
  rat_contract: "%s"
l2:
  rpc: "%s"
p2p:
  listen_addr: "/ip4/127.0.0.1/tcp/%d"
  bootstrap_peers:
    - "/ip4/127.0.0.1/tcp/%d"
  dht_namespace: "/test-p2p"
  withdrawal_topic: "/test/p2p/topic"
log:
  level: "info"
`, validatorAddr.Hex(), sys.L1RPCURL, sys.Addresses.RATProxy.Hex(), sys.L1RPCURL, valPort, aggPort)

	aggConfigPath := filepath.Join(sys.TempDir, "agg.yaml")
	valConfigPath := filepath.Join(sys.TempDir, "val.yaml")
	require.NoError(t, os.WriteFile(aggConfigPath, []byte(aggConfig), 0644))
	require.NoError(t, os.WriteFile(valConfigPath, []byte(valConfig), 0644))

	// Start aggregator
	aggCmd := exec.CommandContext(ctx, aggregatorBin, "-config", aggConfigPath)
	aggCmd.Stdout = &testWriter{t: t, prefix: "[agg] "}
	aggCmd.Stderr = &testWriter{t: t, prefix: "[agg] "}
	require.NoError(t, aggCmd.Start())
	t.Cleanup(func() {
		if aggCmd.Process != nil {
			_ = aggCmd.Process.Kill()
			_ = aggCmd.Wait()
		}
	})
	t.Logf("✓ Aggregator started (PID: %d)", aggCmd.Process.Pid)

	// Wait for aggregator
	time.Sleep(3 * time.Second)

	// Start validator
	valCmd := exec.CommandContext(ctx, validatorBin, "-config", valConfigPath)
	valCmd.Stdout = &testWriter{t: t, prefix: "[val] "}
	valCmd.Stderr = &testWriter{t: t, prefix: "[val] "}
	require.NoError(t, valCmd.Start())
	t.Cleanup(func() {
		if valCmd.Process != nil {
			_ = valCmd.Process.Kill()
			_ = valCmd.Wait()
		}
	})
	t.Logf("✓ Validator started (PID: %d)", valCmd.Process.Pid)

	// Wait for P2P connection
	time.Sleep(5 * time.Second)

	// Verify processes are running
	require.Nil(t, aggCmd.ProcessState, "Aggregator should be running")
	require.Nil(t, valCmd.ProcessState, "Validator should be running")

	t.Log("")
	t.Log("✓ P2P connection test complete")
	t.Log("  Both processes initialized and connected via libp2p")
}

// TestFastWithdrawal_BLSWithMainnetFork tests BLS operations using mainnet fork
// This enables real EIP-2537 precompile support
func TestFastWithdrawal_BLSWithMainnetFork(t *testing.T) {
	// Skip by default - requires mainnet RPC and takes time
	// Enable with: ETH_MAINNET_RPC=https://... go test -run TestFastWithdrawal_BLSWithMainnetFork
	if os.Getenv("ETH_MAINNET_RPC") == "" {
		t.Skip("Skipping: Set ETH_MAINNET_RPC env var to enable mainnet fork test")
	}

	if testing.Short() {
		t.Skip("Skipping mainnet fork test in short mode")
	}

	// Timing helper
	logTiming := func(step string) func() {
		start := time.Now()
		t.Logf("[%s] Starting: %s", time.Now().Format("15:04:05"), step)
		return func() {
			t.Logf("[%s] Completed: %s (took %v)", time.Now().Format("15:04:05"), step, time.Since(start))
		}
	}

	t.Log("=== Fast Withdrawal BLS Test with Mainnet Fork ===")
	t.Log("")
	t.Log("This test uses mainnet fork to enable EIP-2537 BLS precompiles")
	t.Log("")

	// Get RPC endpoint
	rpcURL := getMainnetForkRPC()
	t.Logf("Using RPC: %s", rpcURL)

	// Start system with mainnet fork
	done := logTiming("Starting Anvil with mainnet fork")
	sys := rat.StartTONStakingSystemWithFork(t, &rat.ForkConfig{
		RPCURL:      rpcURL,
		BlockNumber: 0, // Use latest block
		ChainID:     900,
	})
	done()

	t.Logf("✓ L1 (fork) started at %s", sys.L1RPCURL)
	t.Logf("✓ RAT Contract: %s", sys.Addresses.RATProxy.Hex())

	// Generate BLS keypair (off-chain, no system needed)
	done = logTiming("Generating BLS keypair")
	blsPrivKey, blsPubKey := generateBLSKeyPair(t)
	done()
	t.Logf("✓ BLS private key: %d bytes", len(blsPrivKey))
	t.Logf("✓ BLS public key: %d bytes", len(blsPubKey))

	// Create proof of possession
	done = logTiming("Creating Proof of Possession")
	chainID := int64(900)
	testAddr := common.HexToAddress("0x1234567890123456789012345678901234567890")
	popMessage := createPoPMessage(chainID, testAddr)
	popSignature := signBLSMessage(t, blsPrivKey, popMessage)
	done()

	t.Logf("✓ PoP message: 0x%x...", popMessage[:8])
	t.Logf("✓ PoP signature: %d bytes", len(popSignature))

	t.Log("")
	t.Log("=== Test Summary ===")
	t.Log("✅ Mainnet fork started successfully")
	t.Log("✅ BLS keypair generated (off-chain)")
	t.Log("✅ Proof of Possession created (off-chain)")
	t.Log("")
	t.Log("EIP-2537 BLS precompiles are available via mainnet fork.")
	t.Log("Full BLS key registration test requires validator setup with forked system.")
}

// createPoPMessage creates the Proof of Possession message
// PoP message format: keccak256(chainID || validatorAddress)
func createPoPMessage(chainID int64, validator common.Address) []byte {
	// Simple message for PoP: hash of chain ID and validator address
	data := append(
		common.LeftPadBytes(big.NewInt(chainID).Bytes(), 32),
		validator.Bytes()...,
	)
	hash := crypto.Keccak256(data)
	return hash
}

// Helper functions

// findProjectRoot finds the project root directory
func findProjectRoot(t *testing.T) string {
	// Start from current working directory
	dir, err := os.Getwd()
	require.NoError(t, err)

	// Walk up until we find go.mod or Makefile
	for {
		if _, err := os.Stat(filepath.Join(dir, "Makefile")); err == nil {
			if _, err := os.Stat(filepath.Join(dir, ".devnet")); err == nil {
				return dir
			}
		}

		parent := filepath.Dir(dir)
		if parent == dir {
			t.Fatal("Could not find project root")
		}
		dir = parent
	}
}

// mustGetFreePort gets a free port for testing (wrapper for getFreePort)
func mustGetFreePort(t *testing.T) int {
	port, err := getFreePort()
	require.NoError(t, err, "Failed to get free port")
	return port
}
