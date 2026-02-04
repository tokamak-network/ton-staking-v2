#!/bin/bash
# =============================================================================
# Deploy Optimism Contracts to Sepolia Fork
# =============================================================================
# This script deploys Optimism contracts from pre-configured allocs to L1.
# Uses Anvil's cheatcodes (anvil_setCode, anvil_setStorageAt) to inject
# contract bytecode and storage at specific addresses.
#
# This allows running Optimism contracts on a Sepolia fork without
# going through the full deployment process.
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
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_DIR="$PROJECT_ROOT/scripts/config"
DEVNET_DIR="$PROJECT_ROOT/.devnet-sepolia-fork"

L1_RPC="${L1_RPC:-http://localhost:8545}"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Deploy Optimism Contracts to Sepolia Fork              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# =============================================================================
# Check Prerequisites
# =============================================================================
echo -e "${YELLOW}[1/4] Checking prerequisites...${NC}"

# Check L1 is running
if ! cast chain-id --rpc-url "$L1_RPC" &> /dev/null; then
    echo -e "${RED}Error: L1 not running at $L1_RPC${NC}"
    echo "Start the Sepolia fork first: make devnet-sepolia-fork-start"
    exit 1
fi

# Check config files exist
if [ ! -f "$CONFIG_DIR/optimism-allocs-l1.json" ]; then
    echo -e "${RED}Error: optimism-allocs-l1.json not found${NC}"
    exit 1
fi

if [ ! -f "$CONFIG_DIR/optimism-addresses.json" ]; then
    echo -e "${RED}Error: optimism-addresses.json not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Prerequisites met${NC}"

# =============================================================================
# Load Optimism Addresses
# =============================================================================
echo ""
echo -e "${YELLOW}[2/4] Loading Optimism addresses...${NC}"

ALLOCS_FILE="$CONFIG_DIR/optimism-allocs-l1.json"
ADDRESSES_FILE="$CONFIG_DIR/optimism-addresses.json"

# Key Optimism contract addresses
DISPUTE_GAME_FACTORY=$(jq -r '.DisputeGameFactoryProxy' "$ADDRESSES_FILE")
SYSTEM_CONFIG=$(jq -r '.SystemConfigProxy' "$ADDRESSES_FILE")
OPTIMISM_PORTAL=$(jq -r '.OptimismPortalProxy' "$ADDRESSES_FILE")
ANCHOR_STATE_REGISTRY=$(jq -r '.AnchorStateRegistryProxy' "$ADDRESSES_FILE")
L1_STANDARD_BRIDGE=$(jq -r '.L1StandardBridgeProxy' "$ADDRESSES_FILE")
DELAYED_WETH=$(jq -r '.DelayedWETHProxy // "0x0000000000000000000000000000000000000000"' "$ADDRESSES_FILE")

echo "  DisputeGameFactory: $DISPUTE_GAME_FACTORY"
echo "  SystemConfig:       $SYSTEM_CONFIG"
echo "  OptimismPortal:     $OPTIMISM_PORTAL"
echo "  AnchorStateRegistry: $ANCHOR_STATE_REGISTRY"
echo "  L1StandardBridge:   $L1_STANDARD_BRIDGE"

# =============================================================================
# Deploy Contracts via anvil_setCode
# =============================================================================
echo ""
echo -e "${YELLOW}[3/4] Deploying contracts via anvil_setCode...${NC}"

deploy_contract() {
    local name="$1"
    local address="$2"

    if [ "$address" = "null" ] || [ "$address" = "0x0000000000000000000000000000000000000000" ]; then
        echo -e "  ${YELLOW}⚠${NC} $name: skipped (no address)"
        return
    fi

    # Convert address to lowercase for JSON lookup
    local addr_lower=$(echo "$address" | tr '[:upper:]' '[:lower:]')

    # Get contract data from allocs
    local code=$(jq -r --arg addr "$addr_lower" '.[$addr].code // empty' "$ALLOCS_FILE")

    if [ -z "$code" ] || [ "$code" = "null" ]; then
        echo -e "  ${YELLOW}⚠${NC} $name: not found in allocs"
        return
    fi

    # Set code
    cast rpc anvil_setCode "$address" "$code" --rpc-url "$L1_RPC" > /dev/null 2>&1 || {
        echo -e "  ${RED}✗${NC} $name: failed to set code"
        return
    }

    # Set storage slots if available
    local storage=$(jq -r --arg addr "$addr_lower" '.[$addr].storage // empty' "$ALLOCS_FILE")
    if [ -n "$storage" ] && [ "$storage" != "null" ] && [ "$storage" != "{}" ]; then
        # Iterate through storage slots
        echo "$storage" | jq -r 'to_entries[] | "\(.key) \(.value)"' | while read -r slot value; do
            cast rpc anvil_setStorageAt "$address" "$slot" "$value" --rpc-url "$L1_RPC" > /dev/null 2>&1
        done
    fi

    echo -e "  ${GREEN}✓${NC} $name deployed at $address"
}

# Deploy key contracts
deploy_contract "DisputeGameFactory" "$DISPUTE_GAME_FACTORY"
deploy_contract "SystemConfig" "$SYSTEM_CONFIG"
deploy_contract "OptimismPortal" "$OPTIMISM_PORTAL"
deploy_contract "AnchorStateRegistry" "$ANCHOR_STATE_REGISTRY"
deploy_contract "L1StandardBridge" "$L1_STANDARD_BRIDGE"
deploy_contract "DelayedWETH" "$DELAYED_WETH"

# Deploy implementation contracts (proxies point to these)
echo ""
echo "  Deploying implementation contracts..."

# Get all addresses from optimism-addresses.json and deploy non-proxy implementations
jq -r 'to_entries[] | select(.key | endswith("Impl") or (endswith("Proxy") | not)) | "\(.key) \(.value)"' "$ADDRESSES_FILE" | \
    head -20 | while read -r name address; do
    if [ "$address" != "null" ] && [ "$address" != "0x0000000000000000000000000000000000000000" ]; then
        deploy_contract "$name" "$address"
    fi
done

# =============================================================================
# Save Addresses to Devnet Directory
# =============================================================================
echo ""
echo -e "${YELLOW}[4/4] Saving configuration...${NC}"

mkdir -p "$DEVNET_DIR"
cp "$ADDRESSES_FILE" "$DEVNET_DIR/optimism-addresses.json"
cp "$CONFIG_DIR/devnetL1.json" "$DEVNET_DIR/devnetL1.json"

echo -e "${GREEN}✓ Configuration saved to $DEVNET_DIR${NC}"

# =============================================================================
# Verify Deployment
# =============================================================================
echo ""
echo -e "${CYAN}Verifying deployment...${NC}"

verify_contract() {
    local name="$1"
    local address="$2"

    if [ "$address" = "null" ] || [ "$address" = "0x0000000000000000000000000000000000000000" ]; then
        return
    fi

    local code=$(cast code "$address" --rpc-url "$L1_RPC" 2>/dev/null)
    if [ -n "$code" ] && [ "$code" != "0x" ]; then
        local code_len=${#code}
        echo -e "  ${GREEN}✓${NC} $name: $code_len bytes"
    else
        echo -e "  ${RED}✗${NC} $name: no code at $address"
    fi
}

verify_contract "DisputeGameFactory" "$DISPUTE_GAME_FACTORY"
verify_contract "SystemConfig" "$SYSTEM_CONFIG"
verify_contract "OptimismPortal" "$OPTIMISM_PORTAL"

# =============================================================================
# Summary
# =============================================================================
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Optimism Contracts Deployed Successfully!              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Key Addresses:${NC}"
echo "  DisputeGameFactory: $DISPUTE_GAME_FACTORY"
echo "  SystemConfig:       $SYSTEM_CONFIG"
echo "  OptimismPortal:     $OPTIMISM_PORTAL"
echo ""
echo -e "${CYAN}Next Steps:${NC}"
echo "  1. Deploy TON Staking V3 contracts"
echo "  2. Connect RAT to DisputeGameFactory"
echo ""
