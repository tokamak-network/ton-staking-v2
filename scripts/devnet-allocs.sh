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
#
# Usage:
#   make devnet-allocs                    # Normal mode
#   VERBOSE=1 make devnet-allocs          # Verbose mode (shows all commands)
#   make devnet-allocs 2>&1 | tee log.txt # Save log to file

#   4. Connects RAT to DisputeGameFactory
#   5. Creates .devnet/addresses.json
# =============================================================================

# Enable verbose mode if VERBOSE=1
if [ "$VERBOSE" = "1" ]; then
    set -x  # Print each command before executing
fi

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

# Verify Optimism allocs
echo ""
echo -e "${BLUE}  Verifying Optimism L1 contracts in allocs...${NC}"
if ! bash scripts/verify-optimism-deployment.sh; then
    echo -e "${RED}Error: Optimism deployment verification failed${NC}"
    exit 1
fi

# Generate Solidity allocs setup contract
echo ""
echo -e "${BLUE}  Generating SetupL1Allocs.sol from allocs...${NC}"
bash scripts/generate-allocs-setup.sh "$DEVNET_DIR/allocs-l1.json" "$PROJECT_ROOT/script/SetupL1Allocs.sol"

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

# Start Anvil (Optimism contracts will be set up via vm.etch in Forge script)
# Note: --code-size-limit increased to allow large SeigManager contracts
anvil \
    --host 0.0.0.0 \
    --port 8545 \
    --chain-id 900 \
    --block-time 2 \
    --code-size-limit 100000 \
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

# Note: Optimism contracts will be deployed via vm.etch() in the Forge script
# Runtime verification will happen after TON Staking V3 deployment

# =============================================================================
# Step 3: Setup L1 Optimism Contracts via vm.etch (SetupL1Allocs)
# =============================================================================
echo ""
echo -e "${YELLOW}[3/5] Setting up L1 Optimism contracts via vm.etch...${NC}"
cd "$PROJECT_ROOT"

# Run SetupL1Allocs separately to avoid contract size issues
# Note: This may take a while due to via_ir compilation
echo "  Compiling SetupL1Allocs (this may take a few minutes)..."
SETUP_OUTPUT=$(forge script script/SetupL1Allocs.sol:SetupL1Allocs \
    --rpc-url http://localhost:8545 \
    --broadcast \
    --via-ir \
    --private-key "$DEPLOYER_PRIVATE_KEY" \
    2>&1) || {
    echo -e "${RED}Error: L1 allocs setup failed${NC}"
    echo "$SETUP_OUTPUT"
    exit 1
}

echo -e "${GREEN}  L1 Optimism contracts deployed via vm.etch${NC}"

# =============================================================================
# Step 4: Deploy TON Staking V3 Full System
# =============================================================================
echo ""
echo -e "${YELLOW}[4/5] Deploying TON Staking V3 Full System...${NC}"

# Set environment variables for Optimism addresses
export DISPUTE_GAME_FACTORY_PROXY="$DISPUTE_GAME_FACTORY"
export SYSTEM_CONFIG_PROXY="$SYSTEM_CONFIG"

# Run forge script for full V3 deployment
DEPLOY_OUTPUT=$(forge script script/DeployV3FullForDevnet.s.sol:DeployV3FullForDevnet \
    --rpc-url http://localhost:8545 \
    --broadcast \
    --via-ir \
    --ffi \
    --private-key "$DEPLOYER_PRIVATE_KEY" \
    2>&1) || {
    echo -e "${RED}Error: V3 Full deployment failed${NC}"
    echo "$DEPLOY_OUTPUT"
    exit 1
}

# Extract and save JSON addresses from deployment output
JSON_CONTENT=$(echo "$DEPLOY_OUTPUT" | sed -n '/=== DEPLOYMENT_JSON_START ===/,/=== DEPLOYMENT_JSON_END ===/p' | grep -v "===")
if [ -n "$JSON_CONTENT" ]; then
    echo "$JSON_CONTENT" > "$DEVNET_DIR/addresses.json"
    echo -e "${GREEN}  TON Staking V3 Full System deployed${NC}"
    echo -e "${GREEN}  Addresses saved to $DEVNET_DIR/addresses.json${NC}"
    echo "$DEPLOY_OUTPUT" | grep -A 100 "=== Deployment Summary ==="
else
    echo -e "${RED}Error: Could not extract deployment addresses${NC}"
    echo "$DEPLOY_OUTPUT"
    exit 1
fi

# Read addresses from the generated file
RAT_ADDRESS=$(jq -r '.ratProxy' "$DEVNET_DIR/addresses.json")
TON_ADDRESS=$(jq -r '.ton' "$DEVNET_DIR/addresses.json")
WTON_ADDRESS=$(jq -r '.wton' "$DEVNET_DIR/addresses.json")
SEIG_MANAGER_ADDRESS=$(jq -r '.seigManagerProxy' "$DEVNET_DIR/addresses.json")
DEPOSIT_MANAGER_ADDRESS=$(jq -r '.depositManagerProxy' "$DEVNET_DIR/addresses.json")
LAYER2_MANAGER_ADDRESS=$(jq -r '.layer2ManagerProxy' "$DEVNET_DIR/addresses.json")
L1_BRIDGE_REGISTRY_ADDRESS=$(jq -r '.l1BridgeRegistryProxy' "$DEVNET_DIR/addresses.json")
VALIDATOR_REWARD_ADDRESS=$(jq -r '.validatorRewardProxy' "$DEVNET_DIR/addresses.json")

if [ -z "$RAT_ADDRESS" ] || [ "$RAT_ADDRESS" == "null" ]; then
    echo -e "${RED}Error: Failed to extract RAT address${NC}"
    echo "$DEPLOY_OUTPUT"
    exit 1
fi

echo -e "${GREEN}  TON Staking V3 System Deployed:${NC}"
echo "  TON: $TON_ADDRESS"
echo "  WTON: $WTON_ADDRESS"
echo "  RAT: $RAT_ADDRESS"
echo "  SeigManager: $SEIG_MANAGER_ADDRESS"
echo "  DepositManager: $DEPOSIT_MANAGER_ADDRESS"
echo "  Layer2Manager: $LAYER2_MANAGER_ADDRESS"
echo "  L1BridgeRegistry: $L1_BRIDGE_REGISTRY_ADDRESS"
echo "  ValidatorReward: $VALIDATOR_REWARD_ADDRESS"

# Verify Optimism contracts were deployed via vm.etch()
echo ""
echo -e "${BLUE}  Verifying Optimism contracts on Anvil (after vm.etch)...${NC}"
if bash scripts/verify-runtime-deployment.sh http://localhost:8545; then
    echo -e "${GREEN}  ✓ Optimism L1 contracts successfully deployed via vm.etch()${NC}"
else
    echo -e "${YELLOW}  ⚠ Warning: Some Optimism contracts may not be deployed${NC}"
    echo "    Continuing with deployment..."
fi

# =============================================================================
# Step 5: Verify RAT Connection to DisputeGameFactory
# =============================================================================
echo ""
echo -e "${YELLOW}[5/5] Verifying RAT connection to DisputeGameFactory...${NC}"

# Note: DeployV3FullForDevnet already connects RAT to DisputeGameFactory
# This step just verifies the connection

# Verify RAT is set on DisputeGameFactory
RAT_ON_FACTORY=$(cast call "$DISPUTE_GAME_FACTORY" "rat()(address)" --rpc-url http://localhost:8545 2>/dev/null || echo "0x0")

# Convert addresses to lowercase for comparison
RAT_ADDRESS_LOWER=$(echo "$RAT_ADDRESS" | tr '[:upper:]' '[:lower:]')
RAT_ON_FACTORY_LOWER=$(echo "$RAT_ON_FACTORY" | tr '[:upper:]' '[:lower:]')

if [ "$RAT_ON_FACTORY_LOWER" == "$RAT_ADDRESS_LOWER" ]; then
    echo -e "${GREEN}  ✓ RAT connected to DisputeGameFactory${NC}"
    echo "    RAT address: $RAT_ADDRESS"
    echo "    Factory RAT: $RAT_ON_FACTORY"
else
    echo -e "${RED}  ✗ RAT connection failed${NC}"
    echo "    Expected RAT: $RAT_ADDRESS"
    echo "    Factory RAT:  $RAT_ON_FACTORY"
    echo ""
    echo -e "${YELLOW}  Attempting manual connection...${NC}"

    # Manual fallback connection
    cast send "$DISPUTE_GAME_FACTORY" "setRAT(address)" "$RAT_ADDRESS" \
        --rpc-url http://localhost:8545 \
        --private-key "$DEPLOYER_PRIVATE_KEY" \
        > /dev/null 2>&1 && echo "  setRAT() called" || echo -e "${RED}  Error: setRAT() failed${NC}"

    # Verify again
    RAT_ON_FACTORY=$(cast call "$DISPUTE_GAME_FACTORY" "rat()(address)" --rpc-url http://localhost:8545 2>/dev/null || echo "0x0")
    RAT_ON_FACTORY_LOWER=$(echo "$RAT_ON_FACTORY" | tr '[:upper:]' '[:lower:]')

    if [ "$RAT_ON_FACTORY_LOWER" == "$RAT_ADDRESS_LOWER" ]; then
        echo -e "${GREEN}  ✓ Manual connection successful${NC}"
    else
        echo -e "${RED}  ✗ Manual connection also failed${NC}"
    fi
fi

# =============================================================================
# Create .env file
# =============================================================================
# Note: addresses.json is already created by DeployV3FullForDevnet.s.sol

cat > "$DEVNET_DIR/.env" << EOF
# TON Staking V3 Devnet Environment
export RAT_ADDRESS=$RAT_ADDRESS
export TON_ADDRESS=$TON_ADDRESS
export WTON_ADDRESS=$WTON_ADDRESS
export SEIG_MANAGER_ADDRESS=$SEIG_MANAGER_ADDRESS
export DEPOSIT_MANAGER_ADDRESS=$DEPOSIT_MANAGER_ADDRESS
export LAYER2_MANAGER_ADDRESS=$LAYER2_MANAGER_ADDRESS
export L1_BRIDGE_REGISTRY_ADDRESS=$L1_BRIDGE_REGISTRY_ADDRESS
export VALIDATOR_REWARD_ADDRESS=$VALIDATOR_REWARD_ADDRESS
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
echo "Configuration files:"
echo "  Addresses:  .devnet/addresses.json"
echo "  Env vars:   .devnet/.env"
echo "  L1 logs:    .devnet/anvil.log"
echo ""
echo -e "${BLUE}Deployed System:${NC}"
echo -e "  TON Staking V3 Infrastructure:"
echo -e "    - TON:               ${YELLOW}$TON_ADDRESS${NC}"
echo -e "    - WTON:              ${YELLOW}$WTON_ADDRESS${NC}"
echo -e "    - SeigManager:       ${YELLOW}$SEIG_MANAGER_ADDRESS${NC}"
echo -e "    - DepositManager:    ${YELLOW}$DEPOSIT_MANAGER_ADDRESS${NC}"
echo -e "    - Layer2Manager:     ${YELLOW}$LAYER2_MANAGER_ADDRESS${NC}"
echo -e "    - L1BridgeRegistry:  ${YELLOW}$L1_BRIDGE_REGISTRY_ADDRESS${NC}"
echo ""
echo -e "  V3 Contracts:"
echo -e "    - RAT:               ${YELLOW}$RAT_ADDRESS${NC}"
echo -e "    - ValidatorReward:   ${YELLOW}$VALIDATOR_REWARD_ADDRESS${NC}"
echo ""
echo -e "  Optimism Integration:"
echo -e "    - DisputeGameFactory: ${YELLOW}$DISPUTE_GAME_FACTORY${NC}"
echo -e "    - SystemConfig:       ${YELLOW}$SYSTEM_CONFIG${NC}"
echo ""
echo -e "Test accounts (each has 100k TON + 100k WTON):"
echo -e "  - Deployer:   $DEPLOYER_ADDRESS"
echo -e "  - Validator:  0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
echo -e "  - Proposer:   0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"
echo -e "  - Challenger: 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65"
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo -e "  ${GREEN}make test-e2e${NC}      # Run E2E tests"
echo -e "  ${GREEN}make devnet-down${NC}   # Stop L1 when done"
echo ""
