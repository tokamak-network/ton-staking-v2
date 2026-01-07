#!/bin/bash
# =============================================================================
# Offline Genesis Allocs Generator for TON Staking V3
# =============================================================================
# This script generates allocs-l1-staking-v3.json WITHOUT starting any nodes
# (Asterisc-style offline genesis generation)
#
# Process:
#   1. Copy Optimism allocs-l1.json
#   2. Run forge script in simulation mode (vm.loadAllocs + vm.dumpState)
#   3. Generate allocs-l1-staking-v3.json with all contracts included
#
# Usage:
#   make devnet-allocs-offline
#   OR
#   ./scripts/generate-allocs-offline.sh
# =============================================================================

set -eo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DEVNET_DIR="$PROJECT_ROOT/.devnet"
OPTIMISM_DEVNET_DIR="$PROJECT_ROOT/lib/optimism/.devnet"

# Anvil account #1 for TON Staking (different from Optimism's account #0)
# This separation avoids nonce collision and clarifies ownership
DEPLOYER_PRIVATE_KEY="${PRIVATE_KEY:-0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d}"
DEPLOYER_ADDRESS="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"

echo -e "${BLUE}=== Generating TON Staking V3 Genesis Allocs (Offline) ===${NC}"
echo ""

# Check dependencies
command -v forge >/dev/null 2>&1 || { echo -e "${RED}Error: forge not found. Install Foundry first.${NC}"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo -e "${RED}Error: jq not found. Install jq first.${NC}"; exit 1; }

# =============================================================================
# Step 1: Verify Optimism devnet allocs exist
# =============================================================================
echo -e "${YELLOW}[1/4] Checking Optimism devnet allocs...${NC}"

if [ ! -f "$OPTIMISM_DEVNET_DIR/addresses.json" ]; then
    echo -e "${RED}Error: lib/optimism devnet allocs not found${NC}"
    echo "Run 'make devnet-allocs-optimism' first"
    exit 1
fi

if [ ! -f "$OPTIMISM_DEVNET_DIR/allocs-l1.json" ]; then
    echo -e "${RED}Error: lib/optimism allocs-l1.json not found${NC}"
    exit 1
fi

echo -e "${GREEN}  ✓ Optimism allocs found${NC}"

# =============================================================================
# Step 2: Copy Optimism allocs to working directory
# =============================================================================
echo ""
echo -e "${YELLOW}[2/4] Copying Optimism allocs...${NC}"

rm -rf "$DEVNET_DIR"
mkdir -p "$DEVNET_DIR"

# Copy essential files
cp "$OPTIMISM_DEVNET_DIR/addresses.json" "$DEVNET_DIR/optimism-addresses.json"
cp "$OPTIMISM_DEVNET_DIR/allocs-l1.json" "$DEVNET_DIR/allocs-l1.json"

# Copy deploy config if exists
if [ -f "$OPTIMISM_DEVNET_DIR/devnetL1.json" ]; then
    cp "$OPTIMISM_DEVNET_DIR/devnetL1.json" "$DEVNET_DIR/"
fi

echo -e "${GREEN}  ✓ Copied to .devnet/allocs-l1.json${NC}"

# Read Optimism addresses for reference
DISPUTE_GAME_FACTORY=$(jq -r '.DisputeGameFactoryProxy' "$DEVNET_DIR/optimism-addresses.json")
SYSTEM_CONFIG=$(jq -r '.SystemConfigProxy' "$DEVNET_DIR/optimism-addresses.json")

echo "  DisputeGameFactory: $DISPUTE_GAME_FACTORY"
echo "  SystemConfig: $SYSTEM_CONFIG"

# =============================================================================
# Step 3: Generate TON Staking V3 Allocs (Offline)
# =============================================================================
echo ""
echo -e "${YELLOW}[3/4] Generating TON Staking V3 allocs (offline simulation)...${NC}"

# Set environment variables
export DISPUTE_GAME_FACTORY_PROXY="$DISPUTE_GAME_FACTORY"
export SYSTEM_CONFIG_PROXY="$SYSTEM_CONFIG"
export TARGET_L1_ALLOC="$DEVNET_DIR/allocs-l1.json"
export STATE_DUMP_PATH="$DEVNET_DIR/allocs-l1-staking-v3.json"

# Run forge script in simulation mode (NO --broadcast, NO --rpc-url)
echo -e "${BLUE}  Running forge script (offline mode)...${NC}"
echo -e "${BLUE}  Input:  $TARGET_L1_ALLOC${NC}"
echo -e "${BLUE}  Output: $STATE_DUMP_PATH${NC}"
echo ""

DEPLOY_OUTPUT=$(forge script script/DeployV3FullForDevnet.s.sol:DeployV3FullForDevnet \
    --sig "runForDevnetAlloc()" \
    --chain-id 900 \
    --ffi \
    --private-key "$DEPLOYER_PRIVATE_KEY" \
    -vv \
    2>&1) || {
    echo -e "${RED}Error: Forge script failed${NC}"
    echo "$DEPLOY_OUTPUT"
    exit 1
}

# Check if allocs file was created
if [ ! -f "$STATE_DUMP_PATH" ]; then
    echo -e "${RED}Error: allocs-l1-staking-v3.json was not created${NC}"
    echo "$DEPLOY_OUTPUT"
    exit 1
fi

echo -e "${GREEN}  ✓ Genesis allocs generated${NC}"

# Extract and save deployment addresses
JSON_CONTENT=$(echo "$DEPLOY_OUTPUT" | sed -n '/=== DEPLOYMENT_JSON_START ===/,/=== DEPLOYMENT_JSON_END ===/p' | grep -v "===")
if [ -n "$JSON_CONTENT" ]; then
    echo "$JSON_CONTENT" > "$DEVNET_DIR/addresses.json"
    echo -e "${GREEN}  ✓ Addresses saved to .devnet/addresses.json${NC}"
else
    echo -e "${YELLOW}  ⚠ Could not extract deployment addresses${NC}"
    echo -e "${YELLOW}  Deployment summary may not be available in forge output${NC}"
fi

# =============================================================================
# Step 4: Convert allocs to proper genesis format for Anvil
# =============================================================================
echo ""
echo -e "${YELLOW}[4/4] Converting to genesis format for Anvil...${NC}"

GENESIS_OUTPUT="$DEVNET_DIR/genesis-l1-staking-v3.json"

"$SCRIPT_DIR/convert-allocs-to-genesis.sh" "$STATE_DUMP_PATH" "$GENESIS_OUTPUT"

if [ ! -f "$GENESIS_OUTPUT" ]; then
    echo -e "${RED}Error: Genesis conversion failed${NC}"
    exit 1
fi

echo -e "${GREEN}  ✓ Genesis file created: $GENESIS_OUTPUT${NC}"

# =============================================================================
# Verify allocs file structure
# =============================================================================
echo ""
echo -e "${BLUE}Verifying allocs file...${NC}"

# Count contracts in allocs
TOTAL_CONTRACTS=$(jq 'length' "$STATE_DUMP_PATH")
CONTRACTS_WITH_CODE=$(jq '[.[] | select(.code != null and .code != "0x")] | length' "$STATE_DUMP_PATH")

echo "  Total accounts: $TOTAL_CONTRACTS"
echo "  Contracts with code: $CONTRACTS_WITH_CODE"

# Check for key TON Staking contracts
if [ -f "$DEVNET_DIR/addresses.json" ]; then
    RAT_ADDRESS=$(jq -r '.ratProxy // .rat // "null"' "$DEVNET_DIR/addresses.json")
    if [ "$RAT_ADDRESS" != "null" ]; then
        echo "  RAT address: $RAT_ADDRESS"

        # Verify RAT exists in allocs (convert to lowercase for comparison)
        RAT_ADDRESS_LOWER=$(echo "$RAT_ADDRESS" | tr '[:upper:]' '[:lower:]')
        RAT_IN_ALLOCS=$(jq --arg addr "$RAT_ADDRESS_LOWER" 'has($addr)' "$STATE_DUMP_PATH")
        if [ "$RAT_IN_ALLOCS" == "true" ]; then
            echo -e "${GREEN}  ✓ RAT found in allocs${NC}"
        else
            echo -e "${RED}  ✗ RAT not found in allocs${NC}"
        fi
    fi
fi

# =============================================================================
# Summary
# =============================================================================
echo ""
echo -e "${GREEN}=== Genesis Allocs Generation Complete ===${NC}"
echo ""
echo "Generated files:"
echo "  Allocs (raw):   ${YELLOW}$STATE_DUMP_PATH${NC}"
echo "  Genesis (full): ${YELLOW}$GENESIS_OUTPUT${NC}"
echo "  Addresses:      ${YELLOW}$DEVNET_DIR/addresses.json${NC}"
echo ""
echo "File stats:"
echo "  Size: $(du -h "$GENESIS_OUTPUT" | awk '{print $1}')"
echo "  Contracts: $CONTRACTS_WITH_CODE"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. This genesis file can be used to start L1 nodes with all contracts pre-deployed"
echo "  2. Use 'anvil --init $GENESIS_OUTPUT' to start a node"
echo "  3. Or use in E2E tests: StartTONStakingSystem() will automatically use it"
echo ""
echo -e "${YELLOW}Note: No nodes were started. This is an offline genesis generation.${NC}"
echo ""
