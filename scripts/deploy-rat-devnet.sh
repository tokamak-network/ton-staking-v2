#!/bin/bash
set -e

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

echo -e "${BLUE}=== Deploy RAT to Optimism Devnet ===${NC}"
echo ""

# Check dependencies
command -v forge >/dev/null 2>&1 || { echo -e "${RED}Error: forge not found. Install Foundry first.${NC}"; exit 1; }
command -v cast >/dev/null 2>&1 || { echo -e "${RED}Error: cast not found. Install Foundry first.${NC}"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo -e "${RED}Error: jq not found. Install jq first.${NC}"; exit 1; }

# Check L1 is running
echo -e "${YELLOW}Checking L1 devnet...${NC}"
if ! curl -s http://localhost:8545 > /dev/null 2>&1; then
    echo -e "${RED}Error: L1 devnet not running on localhost:8545${NC}"
    echo ""
    echo "Start L1 devnet first:"
    echo "  cd lib/optimism"
    echo "  just forge-build   # first time only"
    echo "  just devnet-allocs"
    echo "  just devnet-l1"
    exit 1
fi

# Verify chain ID is 900 (Optimism devnet)
CHAIN_ID=$(cast chain-id --rpc-url http://localhost:8545 2>/dev/null || echo "0")
if [ "$CHAIN_ID" != "900" ]; then
    echo -e "${RED}Error: Expected chain ID 900, got $CHAIN_ID${NC}"
    echo "Make sure lib/optimism L1 devnet is running (not standalone Anvil)"
    exit 1
fi
echo -e "${GREEN}L1 devnet running (Chain ID: $CHAIN_ID)${NC}"

# Check lib/optimism addresses exist
if [ ! -f "$OPTIMISM_DEVNET_DIR/addresses.json" ]; then
    echo -e "${RED}Error: lib/optimism addresses not found${NC}"
    echo "Run 'just devnet-allocs' in lib/optimism first"
    exit 1
fi

# Read Optimism addresses
echo -e "${YELLOW}Reading Optimism contract addresses...${NC}"
DISPUTE_GAME_FACTORY=$(jq -r '.DisputeGameFactoryProxy' "$OPTIMISM_DEVNET_DIR/addresses.json")
SYSTEM_CONFIG=$(jq -r '.SystemConfigProxy' "$OPTIMISM_DEVNET_DIR/addresses.json")

if [ -z "$DISPUTE_GAME_FACTORY" ] || [ "$DISPUTE_GAME_FACTORY" == "null" ]; then
    echo -e "${RED}Error: DisputeGameFactoryProxy not found in addresses.json${NC}"
    exit 1
fi

echo "  DisputeGameFactory: $DISPUTE_GAME_FACTORY"
echo "  SystemConfig: $SYSTEM_CONFIG"

# Create devnet directory
mkdir -p "$DEVNET_DIR"

# Deploy RAT contracts
echo ""
echo -e "${YELLOW}Deploying RAT contracts...${NC}"
cd "$PROJECT_ROOT"

# Run forge script and capture output
DEPLOY_OUTPUT=$(forge script script/DeployRATForDevnet.s.sol:DeployRATForDevnet \
    --rpc-url http://localhost:8545 \
    --broadcast \
    --private-key "$DEPLOYER_PRIVATE_KEY" \
    -vvv 2>&1) || {
    echo -e "${RED}Error: Forge script failed${NC}"
    echo "$DEPLOY_OUTPUT"
    exit 1
}

echo "$DEPLOY_OUTPUT"

# Extract RAT address from deployment output
RAT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -E "RAT Proxy deployed:" | grep -oE "0x[a-fA-F0-9]{40}" | tail -1)
TON_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -E "^\s*TON deployed:" | grep -oE "0x[a-fA-F0-9]{40}" | tail -1)
WTON_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -E "WTON deployed:" | grep -oE "0x[a-fA-F0-9]{40}" | tail -1)

if [ -z "$RAT_ADDRESS" ]; then
    echo -e "${RED}Error: Failed to extract RAT address from deployment output${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}RAT deployed: $RAT_ADDRESS${NC}"

# Connect RAT to DisputeGameFactory
echo ""
echo -e "${YELLOW}Connecting RAT to DisputeGameFactory...${NC}"

# Call setRAT on DisputeGameFactory
echo "Calling DisputeGameFactory.setRAT($RAT_ADDRESS)..."
cast send "$DISPUTE_GAME_FACTORY" "setRAT(address)" "$RAT_ADDRESS" \
    --rpc-url http://localhost:8545 \
    --private-key "$DEPLOYER_PRIVATE_KEY" \
    > /dev/null 2>&1 || {
    echo -e "${RED}Warning: setRAT failed (might already be set or owner mismatch)${NC}"
}

# Call setSystemConfig on DisputeGameFactory
echo "Calling DisputeGameFactory.setSystemConfig($SYSTEM_CONFIG)..."
cast send "$DISPUTE_GAME_FACTORY" "setSystemConfig(address)" "$SYSTEM_CONFIG" \
    --rpc-url http://localhost:8545 \
    --private-key "$DEPLOYER_PRIVATE_KEY" \
    > /dev/null 2>&1 || {
    echo -e "${RED}Warning: setSystemConfig failed (might already be set or owner mismatch)${NC}"
}

# Verify RAT is set
RAT_ON_FACTORY=$(cast call "$DISPUTE_GAME_FACTORY" "rat()(address)" --rpc-url http://localhost:8545 2>/dev/null || echo "0x0")
if [ "$RAT_ON_FACTORY" == "$RAT_ADDRESS" ]; then
    echo -e "${GREEN}RAT connected to DisputeGameFactory${NC}"
else
    echo -e "${YELLOW}Warning: RAT address on factory ($RAT_ON_FACTORY) doesn't match deployed RAT ($RAT_ADDRESS)${NC}"
fi

# Create addresses.json
echo ""
echo -e "${YELLOW}Saving addresses to .devnet/addresses.json...${NC}"
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

echo ""
echo -e "${GREEN}=== Deployment Complete ===${NC}"
echo ""
echo -e "Addresses saved to: ${YELLOW}$DEVNET_DIR/addresses.json${NC}"
echo -e "Environment file: ${YELLOW}$DEVNET_DIR/.env${NC}"
echo ""
echo -e "Key addresses:"
echo -e "  RAT:                  ${YELLOW}$RAT_ADDRESS${NC}"
echo -e "  DisputeGameFactory:   ${YELLOW}$DISPUTE_GAME_FACTORY${NC}"
echo -e "  SystemConfig:         ${YELLOW}$SYSTEM_CONFIG${NC}"
echo ""
echo -e "To run E2E tests:"
echo -e "  ${GREEN}make test-e2e${NC}"
echo ""
echo -e "To source environment variables:"
echo -e "  ${GREEN}source .devnet/.env${NC}"
