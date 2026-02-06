#!/bin/bash
# =============================================================================
# Generate All L1 Allocs (Optimism + TON Staking V3)
# =============================================================================
# This script generates everything needed for the local devnet:
#   1. Optimism L1 allocs via `just devnet-allocs` (OptimismPortal, SystemConfig, etc.)
#   2. rollup.json and L2 genesis
#   3. TON Staking V3 allocs on top of Optimism allocs
#   4. Full L1 genesis file for Anvil
#
# Prerequisites:
#   - Optimism monorepo at OPTIMISM_MONOREPO_DIR (default: ~/tokamak-projects/optimism)
#   - forge, just, go, jq installed
#
# Usage:
#   ./scripts/generate-optimism-allocs-sepolia.sh
#   OPTIMISM_MONOREPO_DIR=/path/to/optimism ./scripts/generate-optimism-allocs-sepolia.sh
# =============================================================================

set -eo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$PROJECT_ROOT/scripts/config"
DEVNET_DIR="$PROJECT_ROOT/.devnet"

# Optimism monorepo path (can be overridden via environment variable)
OPTIMISM_MONOREPO_DIR="${OPTIMISM_MONOREPO_DIR:-/Users/zena/tokamak-projects/optimism}"

# Anvil account #1 for TON Staking deployer (different from Optimism's account #0)
DEPLOYER_PRIVATE_KEY="${PRIVATE_KEY:-0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d}"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Generate All L1 Allocs (Optimism + TON Staking V3)      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# =============================================================================
# Step 1: Check Prerequisites
# =============================================================================
echo -e "${YELLOW}[1/7] Checking prerequisites...${NC}"

if ! command -v forge &> /dev/null; then
    echo -e "${RED}Error: forge not found${NC}"
    exit 1
fi

if ! command -v just &> /dev/null; then
    echo -e "${RED}Error: just not found. Install: https://github.com/casey/just${NC}"
    exit 1
fi

if ! command -v go &> /dev/null; then
    echo -e "${RED}Error: go not found${NC}"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq not found${NC}"
    exit 1
fi

if [ ! -d "$OPTIMISM_MONOREPO_DIR" ]; then
    echo -e "${RED}Error: Optimism monorepo not found at: $OPTIMISM_MONOREPO_DIR${NC}"
    echo "Set OPTIMISM_MONOREPO_DIR environment variable to the correct path"
    exit 1
fi

if [ ! -f "$OPTIMISM_MONOREPO_DIR/justfile" ]; then
    echo -e "${RED}Error: justfile not found in $OPTIMISM_MONOREPO_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}  ✓ All prerequisites met${NC}"
echo "  Optimism monorepo: $OPTIMISM_MONOREPO_DIR"
echo ""

# =============================================================================
# Step 2: Run just devnet-allocs
# =============================================================================
echo -e "${YELLOW}[2/7] Running 'just devnet-allocs' (builds contracts + generates allocs)...${NC}"
echo "This may take 1-5 minutes on first run..."
echo ""

DEVNET_ALLOCS_DIR="$OPTIMISM_MONOREPO_DIR/.devnet"

just --justfile "$OPTIMISM_MONOREPO_DIR/justfile" \
     --working-directory "$OPTIMISM_MONOREPO_DIR" \
     devnet-allocs

# Verify output files exist
if [ ! -f "$DEVNET_ALLOCS_DIR/allocs-l1.json" ]; then
    echo -e "${RED}Error: allocs-l1.json was not generated${NC}"
    exit 1
fi

if [ ! -f "$DEVNET_ALLOCS_DIR/addresses.json" ]; then
    echo -e "${RED}Error: addresses.json was not generated${NC}"
    exit 1
fi

if [ ! -f "$DEVNET_ALLOCS_DIR/devnetL1.json" ]; then
    echo -e "${RED}Error: devnetL1.json was not generated${NC}"
    exit 1
fi

ALLOC_COUNT=$(jq 'keys | length' "$DEVNET_ALLOCS_DIR/allocs-l1.json")
echo ""
echo -e "${GREEN}  ✓ Allocs generated successfully ($ALLOC_COUNT accounts)${NC}"

# Verify key contracts have bytecode
PORTAL_ADDR=$(jq -r '.OptimismPortalProxy' "$DEVNET_ALLOCS_DIR/addresses.json")
PORTAL_CODE_LEN=$(jq --arg addr "$PORTAL_ADDR" '.[$addr].code // "" | length' "$DEVNET_ALLOCS_DIR/allocs-l1.json")

if [ "$PORTAL_CODE_LEN" -lt 10 ]; then
    echo -e "${RED}Error: OptimismPortalProxy ($PORTAL_ADDR) has no bytecode in allocs${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓ OptimismPortalProxy bytecode verified (${PORTAL_CODE_LEN} chars)${NC}"
echo ""

# =============================================================================
# Step 3: Copy files to project
# =============================================================================
echo -e "${YELLOW}[3/7] Copying generated files...${NC}"

# Create backup
BACKUP_DIR="$OUTPUT_DIR/backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
BACKED_UP=false

for f in optimism-allocs-l1.json optimism-addresses.json devnetL1.json; do
    if [ -f "$OUTPUT_DIR/$f" ]; then
        cp "$OUTPUT_DIR/$f" "$BACKUP_DIR/"
        BACKED_UP=true
    fi
done
for f in rollup.json devnetL1.json allocs-l1.json allocs-l1-staking-v3.json; do
    if [ -f "$DEVNET_DIR/$f" ]; then
        cp "$DEVNET_DIR/$f" "$BACKUP_DIR/"
        BACKED_UP=true
    fi
done

if [ "$BACKED_UP" = true ]; then
    echo -e "${GREEN}  ✓ Backup saved to: $BACKUP_DIR${NC}"
fi

# Create output directories
mkdir -p "$OUTPUT_DIR"
mkdir -p "$DEVNET_DIR"

# Copy allocs
cp "$DEVNET_ALLOCS_DIR/allocs-l1.json" "$OUTPUT_DIR/optimism-allocs-l1.json"
cp "$DEVNET_ALLOCS_DIR/allocs-l1.json" "$DEVNET_DIR/allocs-l1.json"
echo -e "${GREEN}  ✓ Copied allocs-l1.json${NC}"

# Copy devnetL1 to both .devnet/ and scripts/config/
cp "$DEVNET_ALLOCS_DIR/devnetL1.json" "$DEVNET_DIR/devnetL1.json"
cp "$DEVNET_ALLOCS_DIR/devnetL1.json" "$OUTPUT_DIR/devnetL1.json"
echo -e "${GREEN}  ✓ Copied devnetL1.json${NC}"

# Generate optimism-addresses.json (extract proxy addresses)
jq '{
  SystemConfigProxy: .SystemConfigProxy,
  OptimismPortalProxy: .OptimismPortalProxy,
  L1StandardBridgeProxy: .L1StandardBridgeProxy,
  L1CrossDomainMessengerProxy: .L1CrossDomainMessengerProxy,
  L1ERC721BridgeProxy: .L1ERC721BridgeProxy,
  OptimismMintableERC20FactoryProxy: .OptimismMintableERC20FactoryProxy,
  DisputeGameFactoryProxy: .DisputeGameFactoryProxy
}' "$DEVNET_ALLOCS_DIR/addresses.json" > "$OUTPUT_DIR/optimism-addresses.json"

cp "$OUTPUT_DIR/optimism-addresses.json" "$OUTPUT_DIR/optimism-addresses-sepolia.json"
cp "$OUTPUT_DIR/optimism-addresses.json" "$DEVNET_DIR/optimism-addresses.json"
echo -e "${GREEN}  ✓ Generated optimism-addresses.json${NC}"
echo ""

# =============================================================================
# Step 4: Generate rollup.json
# =============================================================================
echo -e "${YELLOW}[4/7] Generating rollup.json...${NC}"

L1_BLOCK_HASH=$(jq -r '.l1StartingBlockTag' "$DEVNET_DIR/devnetL1.json")
L2_TIME=$(date +%s)
OPTIMISM_PORTAL=$(jq -r '.OptimismPortalProxy' "$OUTPUT_DIR/optimism-addresses.json")
SYSTEM_CONFIG=$(jq -r '.SystemConfigProxy' "$OUTPUT_DIR/optimism-addresses.json")

cat > "$DEVNET_DIR/rollup.json" <<EOF
{
  "genesis": {
    "l1": {
      "hash": "$L1_BLOCK_HASH",
      "number": 0
    },
    "l2": {
      "hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
      "number": 0
    },
    "l2_time": $L2_TIME,
    "system_config": {
      "batcherAddr": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
      "overhead": "0x0000000000000000000000000000000000000000000000000000000000000834",
      "scalar": "0x010000000000000000000000000000000000000000000000000003e8000003e8",
      "gasLimit": 30000000
    }
  },
  "block_time": 2,
  "max_sequencer_drift": 600,
  "seq_window_size": 3600,
  "channel_timeout": 300,
  "l1_chain_id": 900,
  "l2_chain_id": 901,
  "regolith_time": 0,
  "canyon_time": 0,
  "delta_time": 0,
  "ecotone_time": 0,
  "fjord_time": 0,
  "batch_inbox_address": "0xff00000000000000000000000000000000000901",
  "deposit_contract_address": "$OPTIMISM_PORTAL",
  "l1_system_config_address": "$SYSTEM_CONFIG"
}
EOF

cp "$DEVNET_DIR/rollup.json" "$OUTPUT_DIR/rollup-sepolia.json"

echo -e "${GREEN}  ✓ rollup.json generated${NC}"
echo "  deposit_contract_address: $OPTIMISM_PORTAL"
echo "  l1_system_config_address: $SYSTEM_CONFIG"
echo ""

# =============================================================================
# Step 5: Generate L2 Genesis
# =============================================================================
echo -e "${YELLOW}[5/7] Generating L2 genesis...${NC}"

if [ -f "$SCRIPT_DIR/generate-l2-genesis.sh" ]; then
    if bash "$SCRIPT_DIR/generate-l2-genesis.sh" > /tmp/generate-l2-genesis-sepolia.log 2>&1; then
        echo -e "${GREEN}  ✓ L2 genesis generated${NC}"

        if [ -f "$DEVNET_DIR/genesis-l2.json" ]; then
            cp "$DEVNET_DIR/genesis-l2.json" "$OUTPUT_DIR/genesis-l2-sepolia.json"
            PREDEPLOY_COUNT=$(jq '[.alloc | keys[] | select(startswith("0x4200"))] | length' "$DEVNET_DIR/genesis-l2.json")
            echo "  Predeploy contracts: $PREDEPLOY_COUNT"
        fi
    else
        echo -e "${RED}Error: L2 genesis generation failed${NC}"
        echo "Check log: /tmp/generate-l2-genesis-sepolia.log"
        exit 1
    fi
else
    echo -e "${YELLOW}  Skipped: generate-l2-genesis.sh not found${NC}"
fi

echo ""

# =============================================================================
# Step 6: Generate TON Staking V3 Allocs
# =============================================================================
echo -e "${YELLOW}[6/7] Generating TON Staking V3 allocs (offline simulation)...${NC}"

DISPUTE_GAME_FACTORY=$(jq -r '.DisputeGameFactoryProxy' "$DEVNET_DIR/optimism-addresses.json")

export DISPUTE_GAME_FACTORY_PROXY="$DISPUTE_GAME_FACTORY"
export SYSTEM_CONFIG_PROXY="$SYSTEM_CONFIG"
export TARGET_L1_ALLOC="$DEVNET_DIR/allocs-l1.json"
export STATE_DUMP_PATH="$DEVNET_DIR/allocs-l1-staking-v3.json"

echo "  Input:  $TARGET_L1_ALLOC"
echo "  Output: $STATE_DUMP_PATH"
echo ""

DEPLOY_OUTPUT=$(cd "$PROJECT_ROOT" && forge script script/DeployV3FullForDevnet.s.sol:DeployV3FullForDevnet \
    --sig "runForDevnetAlloc()" \
    --chain-id 900 \
    --ffi \
    --private-key "$DEPLOYER_PRIVATE_KEY" \
    -vv \
    2>&1) || {
    echo -e "${RED}Error: TON Staking V3 forge script failed${NC}"
    echo "$DEPLOY_OUTPUT"
    exit 1
}

if [ ! -f "$STATE_DUMP_PATH" ]; then
    echo -e "${RED}Error: allocs-l1-staking-v3.json was not created${NC}"
    echo "$DEPLOY_OUTPUT"
    exit 1
fi

# Extract and save deployment addresses
JSON_CONTENT=$(echo "$DEPLOY_OUTPUT" | sed -n '/=== DEPLOYMENT_JSON_START ===/,/=== DEPLOYMENT_JSON_END ===/p' | grep -v "===")
if [ -n "$JSON_CONTENT" ]; then
    echo "$JSON_CONTENT" > "$DEVNET_DIR/addresses.json"
    echo -e "${GREEN}  ✓ TON Staking V3 addresses saved${NC}"
else
    echo -e "${YELLOW}  ⚠ Could not extract deployment addresses from forge output${NC}"
fi

STAKING_ALLOC_COUNT=$(jq 'length' "$STATE_DUMP_PATH")
echo -e "${GREEN}  ✓ TON Staking V3 allocs generated ($STAKING_ALLOC_COUNT accounts)${NC}"
echo ""

# =============================================================================
# Step 7: Convert allocs to genesis format
# =============================================================================
echo -e "${YELLOW}[7/7] Converting to genesis format for Anvil...${NC}"

GENESIS_OUTPUT="$DEVNET_DIR/genesis-l1-staking-v3.json"

if [ -f "$SCRIPT_DIR/convert-allocs-to-genesis.sh" ]; then
    "$SCRIPT_DIR/convert-allocs-to-genesis.sh" "$STATE_DUMP_PATH" "$GENESIS_OUTPUT"

    if [ ! -f "$GENESIS_OUTPUT" ]; then
        echo -e "${RED}Error: Genesis conversion failed${NC}"
        exit 1
    fi
    echo -e "${GREEN}  ✓ Genesis file created: $GENESIS_OUTPUT${NC}"
else
    echo -e "${YELLOW}  Skipped: convert-allocs-to-genesis.sh not found${NC}"
fi

echo ""

# =============================================================================
# Summary
# =============================================================================
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  All Allocs Generation Complete!                          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Generated Files:${NC}"
echo "  Optimism Allocs:   $OUTPUT_DIR/optimism-allocs-l1.json"
echo "  Optimism Addresses:$OUTPUT_DIR/optimism-addresses.json"
echo "  Staking V3 Allocs: $DEVNET_DIR/allocs-l1-staking-v3.json"
echo "  Staking V3 Genesis:$DEVNET_DIR/genesis-l1-staking-v3.json"
echo "  Rollup Config:     $DEVNET_DIR/rollup.json"
echo "  DevnetL1:          $DEVNET_DIR/devnetL1.json"
echo ""
echo -e "${CYAN}Optimism Addresses:${NC}"
jq -r 'to_entries[] | "  \(.key): \(.value)"' "$OUTPUT_DIR/optimism-addresses.json"
echo ""
if [ -f "$DEVNET_DIR/addresses.json" ]; then
    echo -e "${CYAN}TON Staking V3 Addresses:${NC}"
    jq -r 'to_entries[] | "  \(.key): \(.value)"' "$DEVNET_DIR/addresses.json" 2>/dev/null || true
    echo ""
fi
echo -e "${CYAN}Next Steps:${NC}"
echo "  Start devnet: ./scripts/local/start-sepolia-fork.sh"
echo ""
