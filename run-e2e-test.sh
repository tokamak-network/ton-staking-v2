#!/bin/bash
set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║       TON Staking V3 E2E Test Setup & Execution          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Clean
echo "[1/4] Cleaning previous state..."
make devnet-clean
echo "✓ Clean complete"
echo ""

# Step 2: Setup devnet
echo "[2/4] Setting up devnet (this will take 3-5 minutes)..."
echo "  - Building Optimism contracts"
echo "  - Generating devnet allocs"
echo "  - Starting L1 Anvil"
echo "  - Deploying TON Staking V3 system"
echo ""
make devnet-allocs
echo ""

# Step 3: Verify
echo "[3/4] Verifying deployment..."
make devnet-status
echo ""

# Step 4: Test
echo "[4/4] Running E2E tests..."
make test-e2e
echo ""

echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    Tests Complete!                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "To stop the devnet:"
echo "  make devnet-down"
