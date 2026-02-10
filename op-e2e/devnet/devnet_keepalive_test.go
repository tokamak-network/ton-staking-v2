package devnet

import (
	"os"
	"os/signal"
	"path/filepath"
	"syscall"
	"testing"
	"time"

	"github.com/ethereum-optimism/optimism/op-e2e/faultproofs"
)

func findProjectRoot() (string, error) {
	wd, err := os.Getwd()
	if err != nil {
		return "", err
	}

	dir := wd
	for {
		devnetPath := filepath.Join(dir, ".devnet", "genesis-l1-staking-v3.json")
		if _, err := os.Stat(devnetPath); err == nil {
			return dir, nil
	}

		parent := filepath.Dir(dir)
		if parent == dir {
			break
	}
		dir = parent
	}

	return "", os.ErrNotExist
}

func TestDevnetKeepAlive(t *testing.T) {
	root, err := findProjectRoot()
	if err != nil {
		t.Fatalf("Genesis file not found. Run from project root: make devnet-allocs-offline")
	}

	genesisPath := filepath.Join(root, ".devnet", "genesis-l1-staking-v3.json")
	if _, err := os.Stat(genesisPath); err != nil {
		t.Fatalf("Genesis file not found. Run from project root: make devnet-allocs-offline")
	}

	t.Log("=== Starting Full Optimism devnet (keep-alive) ===")
	sys, _ := faultproofs.StartFaultDisputeSystem(t)
	t.Cleanup(sys.Close)

	t.Log("Devnet running.")
	t.Log("L1 RPC: http://127.0.0.1:8545")
	t.Log("L2 RPC: http://127.0.0.1:9545")
	t.Log("Press Ctrl+C or send SIGTERM to stop.")

	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, os.Interrupt, syscall.SIGTERM)

	select {
	case <-sigCh:
		t.Log("Shutdown signal received. Stopping devnet...")
	case <-time.After(24 * time.Hour):
		t.Log("Timeout reached. Stopping devnet...")
	}
}

