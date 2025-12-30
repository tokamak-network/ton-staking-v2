#!/bin/bash
# =============================================================================
# TON Staking V3 Devnet Setup Script
# =============================================================================
# Single-terminal E2E test setup (like Asterisc)
#
# This script:
#   1. Copies .devnet from lib/optimism (after `just devnet-allocs`)
#   2. Starts L1 devnet in background
#   3. Deploys RAT contracts
#   4. Connects RAT to DisputeGameFactory
#   5. Creates .devnet/addresses.json
#
# Usage:
#   make devnet-allocs   # Runs lib/optimism devnet-allocs first, then this script
#   make test-e2e        # Run E2E tests
#   make devnet-down     # Stop L1 when done
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

# Anvil default deployer account
DEPLOYER_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
DEPLOYER_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

echo -e "${BLUE}=== TON Staking V3 Devnet Setup ===${NC}"
echo ""

# Check dependencies
command -v anvil >/dev/null 2>&1 || { echo -e "${RED}Error: anvil not found. Install Foundry first.${NC}"; exit 1; }
command -v forge >/dev/null 2>&1 || { echo -e "${RED}Error: forge not found. Install Foundry first.${NC}"; exit 1; }
command -v cast >/dev/null 2>&1 || { echo -e "${RED}Error: cast not found. Install Foundry first.${NC}"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo -e "${RED}Error: jq not found. Install jq first.${NC}"; exit 1; }

# Check lib/optimism devnet allocs exist
if [ ! -f "$OPTIMISM_DEVNET_DIR/addresses.json" ]; then
    echo -e "${RED}Error: lib/optimism devnet allocs not found${NC}"
    echo "Run 'make devnet-allocs-optimism' first"
    exit 1
fi

if [ ! -f "$OPTIMISM_DEVNET_DIR/allocs-l1.json" ]; then
    echo -e "${RED}Error: lib/optimism allocs-l1.json not found${NC}"
    exit 1
fi

# =============================================================================
# Step 1: Copy .devnet from lib/optimism
# =============================================================================
echo -e "${YELLOW}[1/4] Copying devnet state from lib/optimism...${NC}"
rm -rf "$DEVNET_DIR"
mkdir -p "$DEVNET_DIR"

# Copy essential files
cp "$OPTIMISM_DEVNET_DIR/addresses.json" "$DEVNET_DIR/optimism-addresses.json"
cp "$OPTIMISM_DEVNET_DIR/allocs-l1.json" "$DEVNET_DIR/allocs-l1.json"

# Copy deploy config if exists
if [ -f "$OPTIMISM_DEVNET_DIR/devnetL1.json" ]; then
    cp "$OPTIMISM_DEVNET_DIR/devnetL1.json" "$DEVNET_DIR/"
fi

echo -e "${GREEN}  Copied devnet state${NC}"

# Read Optimism addresses
DISPUTE_GAME_FACTORY=$(jq -r '.DisputeGameFactoryProxy' "$DEVNET_DIR/optimism-addresses.json")
SYSTEM_CONFIG=$(jq -r '.SystemConfigProxy' "$DEVNET_DIR/optimism-addresses.json")

echo "  DisputeGameFactory: $DISPUTE_GAME_FACTORY"
echo "  SystemConfig: $SYSTEM_CONFIG"

# =============================================================================
# Step 2: Start L1 devnet in background
# =============================================================================
echo ""
echo -e "${YELLOW}[2/4] Starting L1 devnet...${NC}"

# Kill any existing Anvil on port 8545
pkill -f "anvil.*8545" 2>/dev/null || true
sleep 1

# Start Anvil with allocs
anvil \
    --port 8545 \
    --chain-id 900 \
    --block-time 2 \
    --init "$DEVNET_DIR/allocs-l1.json" \
    > "$DEVNET_DIR/anvil.log" 2>&1 &

ANVIL_PID=$!
echo $ANVIL_PID > "$DEVNET_DIR/anvil.pid"
echo -e "${GREEN}  Anvil started (PID: $ANVIL_PID)${NC}"

# Wait for Anvil to be ready
echo "  Waiting for Anvil to be ready..."
for i in {1..30}; do
    if curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
        http://localhost:8545 2>/dev/null | grep -q "0x384"; then
        echo -e "${GREEN}  L1 devnet ready (Chain ID: 900)${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}Error: Anvil failed to start${NC}"
        cat "$DEVNET_DIR/anvil.log"
        exit 1
    fi
    sleep 1
done

# =============================================================================
# Step 3: Deploy RAT contracts
# =============================================================================
echo ""
echo -e "${YELLOW}[3/4] Deploying RAT contracts...${NC}"
cd "$PROJECT_ROOT"

# Run forge script
DEPLOY_OUTPUT=$(forge script script/DeployRATForDevnet.s.sol:DeployRATForDevnet \
    --rpc-url http://localhost:8545 \
    --broadcast \
    --private-key "$DEPLOYER_PRIVATE_KEY" \
    2>&1) || {
    echo -e "${RED}Error: RAT deployment failed${NC}"
    echo "$DEPLOY_OUTPUT"
    exit 1
}

# Extract addresses from deployment output
RAT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -E "RAT Proxy deployed:" | grep -oE "0x[a-fA-F0-9]{40}" | tail -1)
TON_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -E "^\s*TON deployed:" | grep -oE "0x[a-fA-F0-9]{40}" | tail -1)
WTON_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -E "WTON deployed:" | grep -oE "0x[a-fA-F0-9]{40}" | tail -1)

if [ -z "$RAT_ADDRESS" ]; then
    echo -e "${RED}Error: Failed to extract RAT address${NC}"
    echo "$DEPLOY_OUTPUT"
    exit 1
fi

echo -e "${GREEN}  RAT deployed: $RAT_ADDRESS${NC}"
echo "  TON: $TON_ADDRESS"
echo "  WTON: $WTON_ADDRESS"

# =============================================================================
# Step 4: Connect RAT to DisputeGameFactory
# =============================================================================
echo ""
echo -e "${YELLOW}[4/4] Connecting RAT to DisputeGameFactory...${NC}"

# Call setRAT on DisputeGameFactory
cast send "$DISPUTE_GAME_FACTORY" "setRAT(address)" "$RAT_ADDRESS" \
    --rpc-url http://localhost:8545 \
    --private-key "$DEPLOYER_PRIVATE_KEY" \
    > /dev/null 2>&1 && echo "  setRAT() called" || echo -e "${YELLOW}  Warning: setRAT() may have failed${NC}"

# Call setSystemConfig on DisputeGameFactory
cast send "$DISPUTE_GAME_FACTORY" "setSystemConfig(address)" "$SYSTEM_CONFIG" \
    --rpc-url http://localhost:8545 \
    --private-key "$DEPLOYER_PRIVATE_KEY" \
    > /dev/null 2>&1 && echo "  setSystemConfig() called" || echo -e "${YELLOW}  Warning: setSystemConfig() may have failed${NC}"

# Verify RAT is set
RAT_ON_FACTORY=$(cast call "$DISPUTE_GAME_FACTORY" "rat()(address)" --rpc-url http://localhost:8545 2>/dev/null || echo "0x0")
if [ "$RAT_ON_FACTORY" == "$RAT_ADDRESS" ]; then
    echo -e "${GREEN}  RAT connected to DisputeGameFactory${NC}"
else
    echo -e "${YELLOW}  Warning: RAT address mismatch (factory: $RAT_ON_FACTORY)${NC}"
fi

# =============================================================================
# Create addresses.json
# =============================================================================
cat > "$DEVNET_DIR/addresses.json" << EOF
{
  "chainId": 900,
  "rpcUrl": "http://localhost:8545",
  "rat": "$RAT_ADDRESS",
  "ton": "$TON_ADDRESS",
  "wton": "$WTON_ADDRESS",
  "disputeGameFactory": "$DISPUTE_GAME_FACTORY",
  "systemConfig": "$SYSTEM_CONFIG",
  "accounts": {
    "deployer": "$DEPLOYER_ADDRESS",
    "validator": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
    "proposer": "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
    "challenger": "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65"
  }
}
EOF

# Create .env file
cat > "$DEVNET_DIR/.env" << EOF
# TON Staking V3 Devnet Environment
export RAT_ADDRESS=$RAT_ADDRESS
export TON_ADDRESS=$TON_ADDRESS
export WTON_ADDRESS=$WTON_ADDRESS
export DISPUTE_GAME_FACTORY=$DISPUTE_GAME_FACTORY
export SYSTEM_CONFIG_ADDRESS=$SYSTEM_CONFIG
export E2E_RPC_URL=http://localhost:8545
export E2E_CHAIN_ID=900
export E2E_PRIVATE_KEY=59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
EOF

# =============================================================================
# Done
# =============================================================================
echo ""
echo -e "${GREEN}=== Devnet Setup Complete ===${NC}"
echo ""
echo "Addresses: .devnet/addresses.json"
echo "L1 logs:   .devnet/anvil.log"
echo ""
echo -e "Key addresses:"
echo -e "  RAT:                ${YELLOW}$RAT_ADDRESS${NC}"
echo -e "  DisputeGameFactory: ${YELLOW}$DISPUTE_GAME_FACTORY${NC}"
echo -e "  SystemConfig:       ${YELLOW}$SYSTEM_CONFIG${NC}"
echo ""
echo -e "Next steps:"
echo -e "  ${GREEN}make test-e2e${NC}      # Run E2E tests"
echo -e "  ${GREEN}make devnet-down${NC}   # Stop L1 when done"
