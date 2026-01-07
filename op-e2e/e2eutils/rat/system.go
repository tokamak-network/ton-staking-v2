package rat

import (
	"context"
	"encoding/json"
	"fmt"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/stretchr/testify/require"
)

// TONStakingSystem represents a running TON Staking V3 devnet
type TONStakingSystem struct {
	T             *testing.T
	Ctx           context.Context
	L1Client      *ethclient.Client
	AnvilCmd      *exec.Cmd
	AllocsPath    string
	AddressesPath string
	Addresses     *DeploymentAddresses
	TempDir       string
}

// DeploymentAddresses contains all deployed contract addresses
type DeploymentAddresses struct {
	ChainID               int64                  `json:"chainId"`
	RPCURL                string                 `json:"rpcUrl"`
	TON                   common.Address         `json:"ton"`
	WTON                  common.Address         `json:"wton"`
	CoinageFactory        common.Address         `json:"coinageFactory"`
	Layer2RegistryProxy   common.Address         `json:"layer2RegistryProxy"`
	SeigManagerProxy      common.Address         `json:"seigManagerProxy"`
	DepositManagerProxy   common.Address         `json:"depositManagerProxy"`
	Layer2ManagerProxy    common.Address         `json:"layer2ManagerProxy"`
	L1BridgeRegistryProxy common.Address         `json:"l1BridgeRegistryProxy"`
	OperatorManagerFactory common.Address        `json:"operatorManagerFactory"`
	RATProxy              common.Address         `json:"ratProxy"`
	ValidatorRewardProxy  common.Address         `json:"validatorRewardProxy"`
	SequencerVaultProxy   common.Address         `json:"sequencerVaultProxy"`
	DisputeGameFactory    common.Address         `json:"disputeGameFactory"`
	SystemConfig          common.Address         `json:"systemConfig"`
	Accounts              map[string]common.Address `json:"accounts"`
}

// StartTONStakingSystem starts a local TON Staking V3 system using allocs-l1-staking-v3.json
// Similar to Asterisc's StartFaultDisputeSystem
func StartTONStakingSystem(t *testing.T) *TONStakingSystem {
	ctx := context.Background()

	// Find project root
	projectRoot, err := findProjectRoot()
	require.NoError(t, err, "Failed to find project root")

	// Paths to generated files
	genesisPath := filepath.Join(projectRoot, ".devnet", "genesis-l1-staking-v3.json")
	addressesPath := filepath.Join(projectRoot, ".devnet", "addresses.json")

	// Check if genesis file exists
	if _, err := os.Stat(genesisPath); os.IsNotExist(err) {
		t.Fatalf("Genesis file not found at %s. Run 'make devnet-allocs-offline' first", genesisPath)
	}

	// Check if addresses file exists
	if _, err := os.Stat(addressesPath); os.IsNotExist(err) {
		t.Fatalf("Addresses file not found at %s. Run 'make devnet-allocs-offline' first", addressesPath)
	}

	// Read deployment addresses
	addressesData, err := os.ReadFile(addressesPath)
	require.NoError(t, err, "Failed to read addresses file")

	var addresses DeploymentAddresses
	err = json.Unmarshal(addressesData, &addresses)
	require.NoError(t, err, "Failed to parse addresses file")

	t.Logf("=== Starting TON Staking V3 System ===")
	t.Logf("Genesis: %s", genesisPath)
	t.Logf("Addresses: %s", addressesPath)

	// Create temp directory for this test
	tempDir := t.TempDir()

	// Start Anvil with genesis file
	// Use dynamic port allocation for parallel test execution
	port, err := getFreePort()
	require.NoError(t, err, "Failed to get free port")

	anvilCmd := exec.Command("anvil",
		"--host", "0.0.0.0",
		"--port", fmt.Sprintf("%d", port),
		"--chain-id", "900",
		"--block-time", "2",
		"--code-size-limit", "100000",
		"--init", genesisPath,
		"--accounts", "10",
		"--balance", "10000",
		"--mnemonic", "test test test test test test test test test test test junk",
	)

	// Redirect anvil output to test logs
	anvilCmd.Stdout = &testWriter{t: t, prefix: "[anvil] "}
	anvilCmd.Stderr = &testWriter{t: t, prefix: "[anvil] "}

	err = anvilCmd.Start()
	require.NoError(t, err, "Failed to start Anvil")

	t.Logf("Anvil started (PID: %d) on port %d", anvilCmd.Process.Pid, port)

	// Wait for Anvil to be ready
	rpcURL := fmt.Sprintf("http://localhost:%d", port)
	var l1Client *ethclient.Client
	for i := 0; i < 30; i++ {
		client, err := ethclient.Dial(rpcURL)
		if err == nil {
			// Verify connection
			_, err := client.ChainID(ctx)
			if err == nil {
				l1Client = client
				break
			}
			client.Close()
		}
		time.Sleep(1 * time.Second)
	}
	require.NotNil(t, l1Client, "Failed to connect to Anvil after 30 seconds")

	t.Logf("L1 client connected to %s", rpcURL)

	sys := &TONStakingSystem{
		T:             t,
		Ctx:           ctx,
		L1Client:      l1Client,
		AnvilCmd:      anvilCmd,
		AllocsPath:    genesisPath,
		AddressesPath: addressesPath,
		Addresses:     &addresses,
		TempDir:       tempDir,
	}

	// Register cleanup
	t.Cleanup(func() {
		sys.Close()
	})

	t.Logf("=== TON Staking V3 System Ready ===")
	t.Logf("RAT: %s", addresses.RATProxy.Hex())
	t.Logf("SeigManager: %s", addresses.SeigManagerProxy.Hex())
	t.Logf("DisputeGameFactory: %s", addresses.DisputeGameFactory.Hex())

	return sys
}

// Close stops the system and cleans up resources
func (s *TONStakingSystem) Close() {
	if s.L1Client != nil {
		s.L1Client.Close()
	}
	if s.AnvilCmd != nil && s.AnvilCmd.Process != nil {
		s.T.Logf("Stopping Anvil (PID: %d)", s.AnvilCmd.Process.Pid)
		_ = s.AnvilCmd.Process.Kill()
		_ = s.AnvilCmd.Wait()
	}
}

// findProjectRoot finds the project root directory by looking for Makefile with devnet-allocs target
// This ensures we find ton-staking-v2 root, not op-e2e root
func findProjectRoot() (string, error) {
	dir, err := os.Getwd()
	if err != nil {
		return "", err
	}

	// Look for directory containing both Makefile and .devnet/
	for {
		makefilePath := filepath.Join(dir, "Makefile")
		devnetPath := filepath.Join(dir, ".devnet")

		// Check if both Makefile and .devnet exist
		if _, err := os.Stat(makefilePath); err == nil {
			if _, err := os.Stat(devnetPath); err == nil {
				return dir, nil
			}
		}

		parent := filepath.Dir(dir)
		if parent == dir {
			return "", fmt.Errorf("project root not found (looking for Makefile + .devnet)")
		}
		dir = parent
	}
}

// testWriter writes to testing.T.Log
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
