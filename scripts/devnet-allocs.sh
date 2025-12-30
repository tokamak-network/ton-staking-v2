#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DEVNET_DIR="$PROJECT_ROOT/.devnet"

echo -e "${GREEN}=== TON Staking V3 Devnet Setup ===${NC}"

# Check dependencies
command -v anvil >/dev/null 2>&1 || { echo -e "${RED}Error: anvil not found. Install Foundry first.${NC}"; exit 1; }
command -v forge >/dev/null 2>&1 || { echo -e "${RED}Error: forge not found. Install Foundry first.${NC}"; exit 1; }

# Create devnet directory
mkdir -p "$DEVNET_DIR"

# Kill any existing Anvil on port 8545
echo -e "${YELLOW}Stopping any existing Anvil instances...${NC}"
pkill -f "anvil.*8545" 2>/dev/null || true
sleep 1

# Start Anvil
echo -e "${YELLOW}Starting Anvil...${NC}"
anvil --chain-id 31337 --port 8545 --block-time 1 > "$DEVNET_DIR/anvil.log" 2>&1 &
ANVIL_PID=$!
echo $ANVIL_PID > "$DEVNET_DIR/anvil.pid"
echo -e "${GREEN}Anvil started (PID: $ANVIL_PID)${NC}"

# Wait for Anvil to be ready
echo -e "${YELLOW}Waiting for Anvil to be ready...${NC}"
for i in {1..30}; do
    if curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
        http://localhost:8545 > /dev/null 2>&1; then
        echo -e "${GREEN}Anvil is ready${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}Error: Anvil failed to start${NC}"
        exit 1
    fi
    sleep 1
done

# Deploy contracts
echo -e "${YELLOW}Deploying contracts...${NC}"
cd "$PROJECT_ROOT"

# Run forge script and capture output
DEPLOY_OUTPUT=$(forge script script/DeployRATForE2E.s.sol:DeployRATForE2E \
    --rpc-url http://localhost:8545 \
    --broadcast \
    --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
    2>&1)

echo "$DEPLOY_OUTPUT"

# Extract addresses from deployment output
# Parse addresses from forge output
# Note: Use exact match to avoid "TON deployed" matching "WTON deployed"
extract_address() {
    echo "$DEPLOY_OUTPUT" | grep -E "^\s*$1:" | grep -oE "0x[a-fA-F0-9]{40}" | tail -1
}

RAT_ADDRESS=$(extract_address "RAT Proxy deployed")
# Use exact pattern to distinguish TON from WTON
TON_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -E "^\s*TON deployed:" | grep -oE "0x[a-fA-F0-9]{40}" | tail -1)
WTON_ADDRESS=$(extract_address "WTON deployed")
SEIG_MANAGER=$(extract_address "SeigManager deployed")
LAYER2_MANAGER=$(extract_address "Layer2Manager deployed")
L1_BRIDGE_REGISTRY=$(extract_address "L1BridgeRegistry deployed")
SYSTEM_CONFIG=$(extract_address "SystemConfig deployed")
RAT_IMPL=$(extract_address "RAT Implementation deployed")
PROXY_ADMIN=$(extract_address "ProxyAdmin deployed")

# Validate addresses were extracted
if [ -z "$RAT_ADDRESS" ]; then
    echo -e "${RED}Error: Failed to extract RAT address from deployment output${NC}"
    echo -e "${YELLOW}Trying alternative extraction...${NC}"
    # Try getting from broadcast file
    BROADCAST_FILE="$PROJECT_ROOT/broadcast/DeployRATForE2E.s.sol/31337/run-latest.json"
    if [ -f "$BROADCAST_FILE" ]; then
        echo -e "${GREEN}Found broadcast file: $BROADCAST_FILE${NC}"
    fi
    exit 1
fi

# Create addresses.json
echo -e "${YELLOW}Creating addresses.json...${NC}"
cat > "$DEVNET_DIR/addresses.json" << EOF
{
  "chainId": 31337,
  "rpcUrl": "http://localhost:8545",
  "rat": "$RAT_ADDRESS",
  "ratImpl": "$RAT_IMPL",
  "proxyAdmin": "$PROXY_ADMIN",
  "ton": "$TON_ADDRESS",
  "wton": "$WTON_ADDRESS",
  "seigManager": "$SEIG_MANAGER",
  "layer2Manager": "$LAYER2_MANAGER",
  "l1BridgeRegistry": "$L1_BRIDGE_REGISTRY",
  "systemConfig": "$SYSTEM_CONFIG",
  "accounts": {
    "deployer": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
    "validator": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
  },
  "privateKeys": {
    "deployer": "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
    "validator": "59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
  }
}
EOF

# Create .env file for easy sourcing
cat > "$DEVNET_DIR/.env" << EOF
# TON Staking V3 Devnet Environment
export RAT_ADDRESS=$RAT_ADDRESS
export TON_ADDRESS=$TON_ADDRESS
export WTON_ADDRESS=$WTON_ADDRESS
export SEIG_MANAGER_ADDRESS=$SEIG_MANAGER
export LAYER2_MANAGER_ADDRESS=$LAYER2_MANAGER
export L1_BRIDGE_REGISTRY_ADDRESS=$L1_BRIDGE_REGISTRY
export SYSTEM_CONFIG_ADDRESS=$SYSTEM_CONFIG
export E2E_RPC_URL=http://localhost:8545
export E2E_PRIVATE_KEY=59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
EOF

echo -e "${GREEN}=== Devnet Setup Complete ===${NC}"
echo ""
echo -e "Addresses saved to: ${YELLOW}$DEVNET_DIR/addresses.json${NC}"
echo -e "Environment file: ${YELLOW}$DEVNET_DIR/.env${NC}"
echo ""
echo -e "To run E2E tests:"
echo -e "  ${GREEN}make test-e2e${NC}"
echo ""
echo -e "To source environment variables:"
echo -e "  ${GREEN}source .devnet/.env${NC}"
echo ""
echo -e "Key addresses:"
echo -e "  RAT:          ${YELLOW}$RAT_ADDRESS${NC}"
echo -e "  TON:          ${YELLOW}$TON_ADDRESS${NC}"
echo -e "  WTON:         ${YELLOW}$WTON_ADDRESS${NC}"
echo -e "  SystemConfig: ${YELLOW}$SYSTEM_CONFIG${NC}"
