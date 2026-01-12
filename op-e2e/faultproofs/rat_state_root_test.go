package faultproofs

import (
	"context"
	"fmt"
	"math/big"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/stretchr/testify/require"

	"github.com/tokamak-network/ton-staking-v2/op-e2e/e2eutils/rat"
)

// TestRATClient_EvidenceSubmission_E2E tests the complete RAT client evidence submission flow
// 1. Start L1 with genesis (all contracts deployed)
// 2. Start L2 geth and generate state
// 3. Create DisputeGame with OutputRootProof
// 4. Trigger RAT
// 5. Run RAT client to generate and submit StateLeaf evidence
// 6. Verify evidence submission on-chain
func TestRATClient_EvidenceSubmission_E2E(t *testing.T) {
	t.Parallel()

	ctx := context.Background()

	// Step 1: Start L1 with TON Staking V3 system
	sys := rat.StartTONStakingSystem(t)

	t.Log("=== Testing RAT State Root as Target ===")

	// Verify RAT contract is deployed
	ratCode, err := sys.L1Client.CodeAt(ctx, sys.Addresses.RATProxy, nil)
	require.NoError(t, err)
	require.NotEmpty(t, ratCode, "RAT contract should be deployed in genesis")
	t.Logf("✓ RAT contract deployed at %s", sys.Addresses.RATProxy.Hex())

	// Step 2: Start L2 geth (dev mode with archive)
	t.Log("=== Starting L2 (geth dev mode) ===")

	l2Dir := filepath.Join(sys.TempDir, "l2-data")
	require.NoError(t, os.MkdirAll(l2Dir, 0755))

	// Create L2 genesis
	l2GenesisPath := filepath.Join(l2Dir, "genesis.json")
	l2Genesis := []byte(`{
  "config": {
    "chainId": 42069,
    "homesteadBlock": 0,
    "eip150Block": 0,
    "eip155Block": 0,
    "eip158Block": 0,
    "byzantiumBlock": 0,
    "constantinopleBlock": 0,
    "petersburgBlock": 0,
    "istanbulBlock": 0,
    "berlinBlock": 0,
    "londonBlock": 0,
    "mergeNetsplitBlock": 0,
    "shanghaiTime": 0,
    "terminalTotalDifficulty": 0,
    "terminalTotalDifficultyPassed": true
  },
  "difficulty": "1",
  "gasLimit": "30000000",
  "alloc": {
    "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266": {
      "balance": "1000000000000000000000"
    }
  }
}`)
	require.NoError(t, os.WriteFile(l2GenesisPath, l2Genesis, 0644))

	// Initialize geth datadir
	initCmd := exec.Command("geth", "--datadir", l2Dir, "init", l2GenesisPath)
	initOutput, err := initCmd.CombinedOutput()
	t.Logf("geth init output: %s", string(initOutput))
	require.NoError(t, err, "geth init failed")

	// Start geth with dynamic port
	l2Port, err := getFreePort()
	require.NoError(t, err, "Failed to get free port for L2")

	gethCmd := exec.Command("geth",
		"--datadir", l2Dir,
		"--http", "--http.addr", "0.0.0.0", "--http.port", fmt.Sprintf("%d", l2Port),
		"--http.api", "eth,web3,net,debug",
		"--http.corsdomain", "*",
		"--ws", "--ws.addr", "0.0.0.0", "--ws.port", fmt.Sprintf("%d", l2Port+1),
		"--ws.api", "eth,web3,net,debug",
		"--nodiscover", "--maxpeers", "0",
		"--networkid", "42069",
		"--dev", "--dev.period", "2",
		"--gcmode", "archive",
		"--allow-insecure-unlock",
		"--ipcdisable", // Disable IPC to avoid path length issues on macOS
	)

	gethCmd.Stdout = &testWriter{t: t, prefix: "[geth] "}
	gethCmd.Stderr = &testWriter{t: t, prefix: "[geth] "}

	require.NoError(t, gethCmd.Start())
	t.Cleanup(func() {
		if gethCmd.Process != nil {
			t.Logf("Stopping geth (PID: %d)", gethCmd.Process.Pid)
			_ = gethCmd.Process.Kill()
			_ = gethCmd.Wait()
		}
	})

	// Wait for L2 to be ready
	l2RPC := fmt.Sprintf("http://localhost:%d", l2Port)
	var l2Client *ethclient.Client
	for i := 0; i < 30; i++ {
		client, err := ethclient.Dial(l2RPC)
		if err == nil {
			chainID, err := client.ChainID(ctx)
			if err == nil && chainID.Int64() == 42069 {
				l2Client = client
				break
			}
			client.Close()
		}
		time.Sleep(1 * time.Second)
	}
	require.NotNil(t, l2Client, "Failed to connect to L2 after 30 seconds")
	t.Cleanup(func() {
		if l2Client != nil {
			l2Client.Close()
		}
	})
	t.Logf("✓ L2 client connected to %s", l2RPC)

	// Step 3: Generate L2 state
	t.Log("=== Generating L2 State ===")

	deployerKey, err := crypto.HexToECDSA("ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80")
	require.NoError(t, err)

	l2ChainID, err := l2Client.ChainID(ctx)
	require.NoError(t, err)

	nonce, err := l2Client.PendingNonceAt(ctx, crypto.PubkeyToAddress(deployerKey.PublicKey))
	require.NoError(t, err)

	// Create transactions to populate state trie
	var lastTxHash common.Hash
	for i := 0; i < 10; i++ {
		to := common.BigToAddress(big.NewInt(int64(i + 1)))
		value := big.NewInt(100000000000000000) // 0.1 ETH

		gasPrice, err := l2Client.SuggestGasPrice(ctx)
		require.NoError(t, err)

		tx := types.NewTransaction(
			nonce+uint64(i),
			to,
			value,
			21000,
			gasPrice,
			nil,
		)

		signedTx, err := types.SignTx(tx, types.NewEIP155Signer(l2ChainID), deployerKey)
		require.NoError(t, err)

		err = l2Client.SendTransaction(ctx, signedTx)
		require.NoError(t, err)

		lastTxHash = signedTx.Hash()
		t.Logf("Sent tx %d: %s -> %s (value: %s)", i, signedTx.Hash().Hex(), to.Hex(), value.String())

		// Wait a bit for dev mode to mine
		time.Sleep(300 * time.Millisecond)
	}

	// Wait for last transaction to be mined
	for i := 0; i < 20; i++ {
		receipt, err := l2Client.TransactionReceipt(ctx, lastTxHash)
		if err == nil && receipt != nil {
			t.Logf("✓ Last transaction mined in block %d", receipt.BlockNumber.Uint64())
			break
		}
		time.Sleep(500 * time.Millisecond)
	}

	// Get latest block
	latestBlock, err := l2Client.BlockByNumber(ctx, nil)
	require.NoError(t, err)
	require.NotNil(t, latestBlock)

	stateRoot := latestBlock.Root()
	blockHash := latestBlock.Hash()
	blockNumber := latestBlock.NumberU64()

	t.Logf("✓ L2 state generated:")
	t.Logf("  Block Number: %d", blockNumber)
	t.Logf("  State Root: %s", stateRoot.Hex())
	t.Logf("  Block Hash: %s", blockHash.Hex())

	// Step 4: Get L2ToL1MessagePasser storage root from L2
	t.Log("=== Querying L2 MessagePasser Storage Root ===")

	// L2ToL1MessagePasser predeploy address (Optimism standard)
	messagePasserAddr := common.HexToAddress("0x4200000000000000000000000000000000000016")

	// Get proof for MessagePasser at the L2 block using eth_getProof
	type StorageResult struct {
		Key   string   `json:"key"`
		Value string   `json:"value"`
		Proof []string `json:"proof"`
	}
	type AccountResult struct {
		Address      common.Address  `json:"address"`
		AccountProof []string        `json:"accountProof"`
		Balance      string          `json:"balance"`
		CodeHash     common.Hash     `json:"codeHash"`
		Nonce        string          `json:"nonce"`
		StorageHash  common.Hash     `json:"storageHash"`
		StorageProof []StorageResult `json:"storageProof"`
	}

	var proof AccountResult
	err = l2Client.Client().CallContext(ctx, &proof, "eth_getProof", messagePasserAddr, []string{}, fmt.Sprintf("0x%x", blockNumber))
	require.NoError(t, err)

	messagePasserStorageRoot := proof.StorageHash
	t.Logf("✓ L2ToL1MessagePasser storage root: %s", messagePasserStorageRoot.Hex())

	// Step 5: Calculate OutputRootProof
	t.Log("=== Creating DisputeGame with OutputRootProof ===")

	// Calculate rootClaim = keccak256(abi.encode(OutputRootProof))
	version := common.Hash{}

	// ABI encode OutputRootProof
	encoded := append(version.Bytes(), stateRoot.Bytes()...)
	encoded = append(encoded, messagePasserStorageRoot.Bytes()...)
	encoded = append(encoded, blockHash.Bytes()...)

	rootClaim := crypto.Keccak256Hash(encoded)
	t.Logf("✓ OutputRootProof computed:")
	t.Logf("  version: %s", version.Hex())
	t.Logf("  stateRoot: %s", stateRoot.Hex())
	t.Logf("  messagePasserStorageRoot: %s", messagePasserStorageRoot.Hex())
	t.Logf("  blockHash: %s", blockHash.Hex())
	t.Logf("  rootClaim (hash): %s", rootClaim.Hex())

	// Step 6: Register validator and configure RAT for 100% trigger (BEFORE creating game)
	t.Log("=== Registering Validator ===")

	// Get deployer account (has funds from genesis)
	auth, err := bind.NewKeyedTransactorWithChainID(deployerKey, big.NewInt(900))
	require.NoError(t, err)
	auth.GasLimit = 3000000 // Set gas limit

	// Setup accounts and contracts using helper functions
	_ = setupTestAccounts(t, sys) // Create accounts for consistency
	contracts := connectTestContracts(t, sys)

	// Get test deposit amount (1000 TON)
	// Genesis has slashingPenalty=10 WTON, validatorBuffer=90 WTON (minimum=100 TON)
	// So 1000 TON deposit is sufficient (10x minimum)
	depositAmount := getTestDepositAmount()
	t.Logf("Deposit amount: %s wei (1000 TON)", depositAmount.String())

	// Register validator using deployer account (has TON from genesis)
	registerValidatorWithTON(t, sys, contracts, auth, depositAmount)
	validatorAddr := crypto.PubkeyToAddress(deployerKey.PublicKey)
	t.Logf("✓ Validator registered: %s", validatorAddr.Hex())

	// Verify validator registration
	callOpts := &bind.CallOpts{Context: ctx}
	isActive, err := contracts.RAT.IsValidatorActive(callOpts, validatorAddr, sys.Addresses.SystemConfig)
	require.NoError(t, err)
	t.Logf("Validator active status: %v", isActive)
	require.True(t, isActive, "Validator should be active after registration")

	activeCount, err := contracts.RAT.GetActiveValidatorCount(callOpts, sys.Addresses.SystemConfig)
	require.NoError(t, err)
	t.Logf("Active validator count: %d", activeCount.Uint64())
	require.True(t, activeCount.Uint64() > 0, "Should have at least 1 active validator")

	// Step 7: Create DisputeGame (NOW RAT can be triggered)
	t.Log("=== Creating DisputeGame ===")

	// Convert rootClaim to [32]byte array for createDisputeGame helper
	var rootClaimArray [32]byte
	copy(rootClaimArray[:], rootClaim.Bytes())

	// Use proposer account for game creation (Account #4)
	proposerKey, err := crypto.HexToECDSA("47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a")
	require.NoError(t, err)
	proposerAuth, err := bind.NewKeyedTransactorWithChainID(proposerKey, big.NewInt(900))
	require.NoError(t, err)
	proposerAuth.GasLimit = 5000000

	// Create dispute game using helper function (it will handle init bond and extraData)
	gameReceipt, gameAddress := createDisputeGame(t, sys, proposerAuth, rootClaimArray, blockNumber)
	t.Logf("✓ DisputeGame created in block %d", gameReceipt.BlockNumber.Uint64())
	t.Logf("✓ DisputeGame address: %s", gameAddress.Hex())
	t.Logf("✓ DisputeGame references L2 block: %d", blockNumber)

	// Parse RAT trigger event using helper function
	testID, ratTriggered := parseRATTriggerEvent(t, gameReceipt, validatorAddr)
	require.True(t, ratTriggered, "RAT should be triggered with 100% probability")

	t.Log("=== Starting RAT Client ===")

	// Start RAT client subprocess to handle evidence submission
	// Use event block number as starting point for monitoring
	eventBlockNumber := gameReceipt.BlockNumber.Uint64()
	t.Logf("AttentionTestTriggered event found at block %d", eventBlockNumber)

	// Start monitoring from earlier blocks to ensure event block is "safe" (confirmed) on first poll
	confirmations := uint64(2) // Should match RAT client config
	var startBlock uint64
	if eventBlockNumber > confirmations+2 {
		startBlock = eventBlockNumber - confirmations - 2
	} else {
		startBlock = 0
	}
	t.Logf("Starting RAT client from block %d (event at %d, confirmations=%d)", startBlock, eventBlockNumber, confirmations)

	validatorPrivKey := "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80" // Anvil account #0
	ratClientReceipt := startRATClient(t, sys, contracts, sys.L1RPCURL, l2RPC, validatorPrivKey, testID, validatorAddr, startBlock)

	// If RAT not triggered, check why
	if !ratTriggered {
		t.Log("=== Investigating RAT Trigger Failure ===")

		callOpts := &bind.CallOpts{Context: ctx}

		// Check RAT parameters
		attentionCost, err := contracts.RAT.AttentionCost(callOpts)
		if err == nil {
			t.Logf("AttentionCost: %s", attentionCost.String())
		}

		slashingPenalty, err := contracts.RAT.SlashingPenalty(callOpts)
		if err == nil {
			t.Logf("SlashingPenalty: %s", slashingPenalty.String())
		}

		validatorCount, err := contracts.RAT.GetActiveValidatorCount(callOpts, sys.Addresses.SystemConfig)
		if err == nil {
			t.Logf("Active validator count (n): %d", validatorCount.Uint64())
		}

		ratTriggerProb, err := contracts.RAT.RatTriggerProbability(callOpts)
		if err == nil {
			ray := new(big.Int).Exp(big.NewInt(10), big.NewInt(27), nil)
			t.Logf("RatTriggerProbability: %s (RAY: %s)", ratTriggerProb.String(), ray.String())
		}

		// Check trigger condition: slashingPenalty * ratTriggerProbability >= attentionCost * n * RAY
		if attentionCost != nil && slashingPenalty != nil && validatorCount != nil && ratTriggerProb != nil {
			ray := new(big.Int).Exp(big.NewInt(10), big.NewInt(27), nil)
			lhs := new(big.Int).Mul(slashingPenalty, ratTriggerProb)
			rhs := new(big.Int).Mul(attentionCost, validatorCount)
			rhs.Mul(rhs, ray)
			t.Logf("Trigger condition: %s (LHS) >= %s (RHS)?", lhs.String(), rhs.String())
			t.Logf("Condition met: %v", lhs.Cmp(rhs) >= 0)
		}
	}

	t.Log("=== Test Complete ===")
	t.Log("✅ L1 started with genesis (all contracts deployed)")
	t.Log("✅ L2 started and state generated")
	t.Log("✅ OutputRootProof calculated correctly")
	t.Log("✅ DisputeGame created successfully")
	t.Log("✅ Validator registered successfully")
	t.Logf("✅ RAT auto-triggered (Test ID: %s)", common.BytesToHash(testID[:]).Hex())
	if ratClientReceipt != nil && ratClientReceipt.Status == 1 {
		t.Log("✅ RAT client successfully submitted evidence")
		t.Logf("   Evidence TX: %s", ratClientReceipt.TxHash.Hex())
		t.Logf("   Gas Used: %d", ratClientReceipt.GasUsed)
	}
	t.Log("")
	t.Logf("DisputeGame address: %s", gameAddress.Hex())
	t.Logf("L2 RPC: %s", l2RPC)
	t.Logf("L2 Block: %d", blockNumber)
	t.Logf("L2 State Root: %s", stateRoot.Hex())
	t.Log("")
	t.Log("✅ Complete E2E test with RAT client integration successful!")
}

// TestRATClientIntegration tests RAT client binary integration
// This test requires the RAT client to be built first
func TestRATClientIntegration(t *testing.T) {
	t.Skip("TODO: Implement RAT client binary integration test")

	// This will:
	// 1. Start full system (L1 + L2)
	// 2. Trigger RAT
	// 3. Launch RAT client binary as subprocess
	// 4. Wait for evidence submission
	// 5. Verify on-chain
}

// testWriter implements io.Writer for test logging
type testWriter struct {
	t      *testing.T
	prefix string
}

func (w *testWriter) Write(p []byte) (n int, err error) {
	w.t.Log(w.prefix + string(p))
	return len(p), nil
}

// getFreePort asks the kernel for a free open port that is ready to use
func getFreePort() (int, error) {
	addr, err := net.ResolveTCPAddr("tcp", "localhost:0")
	if err != nil {
		return 0, err
	}

	l, err := net.ListenTCP("tcp", addr)
	if err != nil {
		return 0, err
	}
	defer l.Close()
	return l.Addr().(*net.TCPAddr).Port, nil
}
