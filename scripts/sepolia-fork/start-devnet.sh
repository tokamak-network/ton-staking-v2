#!/bin/bash
# =============================================================================
# Start TON Staking V3 Sepolia Fork Devnet
# =============================================================================
# This script starts a Sepolia fork based development environment with:
#   - L1 (Anvil fork from Sepolia testnet)
#   - L2 (op-geth with Debug Mode)
#   - All services (op-node, batcher, proposer, RAT clients)
#
# Features:
#   - Uses existing Sepolia Optimism contracts (no need to deploy)
#   - Supports DEPLOY_OPTIMISM=true to deploy custom Optimism contracts
#   - ETH minting via anvil_setBalance
#
# Usage:
#   ./start-devnet.sh                    # Use existing Sepolia Optimism
#   DEPLOY_OPTIMISM=true ./start-devnet.sh  # Deploy custom Optimism
# =============================================================================

set -eo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEVNET_DIR="$PROJECT_ROOT/.devnet-sepolia-fork"
DEPLOYMENT_DIR="$PROJECT_ROOT/deployments/sepolia-fork"
COMPOSE_FILE="$DEPLOYMENT_DIR/docker-compose.yml"
ENV_FILE="$DEPLOYMENT_DIR/.env"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     TON Staking V3 - Sepolia Fork Devnet                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# =============================================================================
# Load Environment Variables
# =============================================================================
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
    echo -e "${GREEN}✓ Loaded environment from $ENV_FILE${NC}"
else
    echo -e "${YELLOW}⚠ .env not found, using defaults${NC}"
fi

# Configuration with defaults
SEPOLIA_RPC="${SEPOLIA_RPC:-https://rpc.sepolia.org}"
FORK_BLOCK="${FORK_BLOCK:-latest}"
DEPLOY_OPTIMISM="${DEPLOY_OPTIMISM:-false}"
DEPLOYER_PRIVATE_KEY="${DEPLOYER_PRIVATE_KEY:-0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80}"

# Existing Sepolia Optimism Contracts (used when DEPLOY_OPTIMISM=false)
EXISTING_OPTIMISM_PORTAL="${OPTIMISM_PORTAL:-0x16Fc5058F25648194471939df75CF27A2fdC48BC}"
EXISTING_SYSTEM_CONFIG="${SYSTEM_CONFIG:-0x034edD2A225f7f429A63E0f1D2084B9E0A93b538}"
EXISTING_L1_STANDARD_BRIDGE="${L1_STANDARD_BRIDGE:-0xFBb0621E0B23b5478B630BD55a5f21f67730B0F1}"

echo ""
echo -e "${CYAN}Configuration:${NC}"
echo "  Sepolia RPC:      $SEPOLIA_RPC"
echo "  Fork Block:       $FORK_BLOCK"
echo "  Deploy Optimism:  $DEPLOY_OPTIMISM"
echo ""

# =============================================================================
# Check Prerequisites
# =============================================================================
echo -e "${YELLOW}[1/8] Checking prerequisites...${NC}"

check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}Error: $1 not found${NC}"
        echo "$2"
        exit 1
    fi
}

check_command "docker" "Install Docker Desktop: https://www.docker.com/products/docker-desktop"
check_command "jq" "Install: brew install jq"
check_command "cast" "Install: curl -L https://foundry.paradigm.xyz | bash && foundryup"
check_command "forge" "Install: curl -L https://foundry.paradigm.xyz | bash && foundryup"

# Check docker-compose (either standalone or plugin)
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}Error: docker-compose not found${NC}"
    exit 1
fi

# Check Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}Error: Docker is not running${NC}"
    echo "Please start Docker Desktop"
    exit 1
fi

echo -e "${GREEN}✓ All prerequisites met${NC}"

# =============================================================================
# Check if already running
# =============================================================================
if docker ps | grep -q "ton-staking-l1-sepolia-fork"; then
    echo -e "${YELLOW}Sepolia fork devnet is already running${NC}"
    echo "Stop it first with: make devnet-sepolia-fork-stop"
    exit 1
fi

# =============================================================================
# Create Directories
# =============================================================================
mkdir -p "$DEVNET_DIR"

# =============================================================================
# Generate JWT Secret
# =============================================================================
echo ""
echo -e "${YELLOW}[2/8] Setting up JWT authentication...${NC}"

if [ ! -f "$DEVNET_DIR/jwt-secret.txt" ]; then
    openssl rand -hex 32 > "$DEVNET_DIR/jwt-secret.txt"
    echo -e "${GREEN}✓ JWT secret generated${NC}"
else
    echo -e "${GREEN}✓ JWT secret exists${NC}"
fi

# =============================================================================
# Start L1 Sepolia Fork
# =============================================================================
echo ""
echo -e "${YELLOW}[3/8] Starting L1 (Anvil Sepolia Fork)...${NC}"

export SEPOLIA_RPC FORK_BLOCK
docker-compose -f "$COMPOSE_FILE" up -d l1-sepolia-fork

# Wait for L1 to be ready
echo "Waiting for L1 fork to be ready..."
for i in {1..60}; do
    if cast block-number --rpc-url http://localhost:8545 &> /dev/null; then
        echo -e "${GREEN}✓ L1 fork ready${NC}"
        break
    fi
    if [ $i -eq 60 ]; then
        echo -e "${RED}Error: L1 fork failed to start${NC}"
        docker-compose -f "$COMPOSE_FILE" logs l1-sepolia-fork | tail -50
        exit 1
    fi
    sleep 2
done

# Get fork info
CURRENT_BLOCK=$(cast block-number --rpc-url http://localhost:8545)
CHAIN_ID=$(cast chain-id --rpc-url http://localhost:8545)
echo "  Forked at block: $CURRENT_BLOCK"
echo "  Chain ID: $CHAIN_ID (Sepolia)"

# =============================================================================
# Mint ETH for Test Accounts
# =============================================================================
echo ""
echo -e "${YELLOW}[4/8] Minting ETH for test accounts...${NC}"

# 1000 ETH in hex
AMOUNT="0x3635C9ADC5DEA00000"

# Test accounts (Anvil defaults)
ACCOUNTS=(
    "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266:Deployer/Batcher"
    "0x70997970C51812dc3A010C7d01b50e0d17dc79C8:Proposer"
    "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC:Validator 1"
    "0x90F79bf6EB2c4f870365E785982E1f101E93b906:Validator 2"
    "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65:Validator 3"
    "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc:Challenger"
)

for account_info in "${ACCOUNTS[@]}"; do
    ADDR="${account_info%%:*}"
    NAME="${account_info##*:}"
    cast rpc anvil_setBalance "$ADDR" "$AMOUNT" --rpc-url http://localhost:8545 > /dev/null 2>&1
    echo -e "  ${GREEN}✓${NC} 1000 ETH → $NAME ($ADDR)"
done

# =============================================================================
# Setup Optimism Contracts
# =============================================================================
echo ""
echo -e "${YELLOW}[5/8] Setting up Optimism contracts...${NC}"

if [ "$DEPLOY_OPTIMISM" = "true" ]; then
    echo "  Mode: Deploy custom Optimism contracts from allocs"

    # Deploy Optimism contracts using anvil cheatcodes
    "$SCRIPT_DIR/deploy-optimism-contracts.sh" || {
        echo -e "${YELLOW}⚠ Optimism deployment failed, using existing Sepolia contracts${NC}"
        DEPLOY_OPTIMISM="false"
    }
fi

if [ "$DEPLOY_OPTIMISM" = "false" ]; then
    echo "  Mode: Use existing Sepolia Optimism contracts"

    # Create optimism-addresses.json with existing Sepolia contracts
    cat > "$DEVNET_DIR/optimism-addresses.json" <<EOF
{
  "OptimismPortalProxy": "$EXISTING_OPTIMISM_PORTAL",
  "SystemConfigProxy": "$EXISTING_SYSTEM_CONFIG",
  "L1StandardBridgeProxy": "$EXISTING_L1_STANDARD_BRIDGE",
  "DisputeGameFactoryProxy": "0x0000000000000000000000000000000000000000",
  "AnchorStateRegistryProxy": "0x0000000000000000000000000000000000000000"
}
EOF

    # Create devnetL1.json for compatibility
    cat > "$DEVNET_DIR/devnetL1.json" <<EOF
{
  "systemConfigProxy": "$EXISTING_SYSTEM_CONFIG"
}
EOF

    echo -e "  ${GREEN}✓${NC} OptimismPortal: $EXISTING_OPTIMISM_PORTAL"
    echo -e "  ${GREEN}✓${NC} SystemConfig: $EXISTING_SYSTEM_CONFIG"
fi

# =============================================================================
# Deploy TON Staking V3 Contracts
# =============================================================================
echo ""
echo -e "${YELLOW}[6/8] Deploying TON Staking V3 contracts...${NC}"

cd "$PROJECT_ROOT"

# Run deployment script
DEPLOY_OUTPUT=$(forge script script/DeployV3FullForDevnet.s.sol:DeployV3FullForDevnet \
    --rpc-url http://localhost:8545 \
    --private-key "$DEPLOYER_PRIVATE_KEY" \
    --broadcast \
    --ffi \
    2>&1) || {
    echo -e "${RED}Error: Contract deployment failed${NC}"
    echo "$DEPLOY_OUTPUT"
    exit 1
}

# Extract JSON from deployment output
if echo "$DEPLOY_OUTPUT" | grep -q "DEPLOYMENT_JSON_START"; then
    DEPLOYMENT_JSON=$(echo "$DEPLOY_OUTPUT" | sed -n '/DEPLOYMENT_JSON_START/,/DEPLOYMENT_JSON_END/p' | grep -v "DEPLOYMENT_JSON")
    echo "$DEPLOYMENT_JSON" > "$DEVNET_DIR/addresses.json"
    echo -e "${GREEN}✓ Contracts deployed and addresses saved${NC}"
else
    echo -e "${YELLOW}⚠ Could not extract deployment addresses${NC}"
    # Create minimal addresses.json
    cat > "$DEVNET_DIR/addresses.json" <<EOF
{
  "note": "Deployment addresses not captured. Check forge output manually.",
  "chainId": 11155111,
  "rpcUrl": "http://localhost:8545"
}
EOF
fi

# Show key addresses
if [ -f "$DEVNET_DIR/addresses.json" ]; then
    echo ""
    echo -e "${CYAN}Key Contract Addresses:${NC}"
    TON=$(jq -r '.ton // "N/A"' "$DEVNET_DIR/addresses.json")
    WTON=$(jq -r '.wton // "N/A"' "$DEVNET_DIR/addresses.json")
    RAT=$(jq -r '.ratProxy // "N/A"' "$DEVNET_DIR/addresses.json")
    SEIG=$(jq -r '.seigManagerProxy // "N/A"' "$DEVNET_DIR/addresses.json")
    echo "  TON:         $TON"
    echo "  WTON:        $WTON"
    echo "  RAT:         $RAT"
    echo "  SeigManager: $SEIG"
fi

# =============================================================================
# Create L2 Configuration Files
# =============================================================================
echo ""
echo -e "${YELLOW}[7/8] Creating L2 configuration...${NC}"

# Get L1 genesis info
L1_BLOCK_0=$(curl -s -X POST -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["0x0", false],"id":1}' \
    http://localhost:8545)
L1_GENESIS_HASH=$(echo "$L1_BLOCK_0" | jq -r '.result.hash')

# Create rollup.json
OPTIMISM_PORTAL=$(jq -r '.OptimismPortalProxy' "$DEVNET_DIR/optimism-addresses.json")
SYSTEM_CONFIG=$(jq -r '.SystemConfigProxy' "$DEVNET_DIR/optimism-addresses.json")

cat > "$DEVNET_DIR/rollup.json" <<EOF
{
  "genesis": {
    "l1": {
      "hash": "$L1_GENESIS_HASH",
      "number": 0
    },
    "l2": {
      "hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
      "number": 0
    },
    "l2_time": $(date +%s),
    "system_config": {
      "batcherAddr": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
      "overhead": "0x0000000000000000000000000000000000000000000000000000000000000834",
      "scalar": "0x01000000000000000000000000000000000000000000000000000fa000000000",
      "gasLimit": 30000000
    }
  },
  "block_time": 2,
  "max_sequencer_drift": 600,
  "seq_window_size": 3600,
  "channel_timeout": 300,
  "l1_chain_id": 11155111,
  "l2_chain_id": 901,
  "regolith_time": 0,
  "canyon_time": 0,
  "delta_time": 0,
  "ecotone_time": null,
  "fjord_time": null,
  "batch_inbox_address": "0xff00000000000000000000000000000000000901",
  "deposit_contract_address": "$OPTIMISM_PORTAL",
  "l1_system_config_address": "$SYSTEM_CONFIG"
}
EOF

# Create L2 genesis
cat > "$DEVNET_DIR/genesis-l2.json" <<'EOF'
{
  "config": {
    "chainId": 901,
    "homesteadBlock": 0,
    "eip150Block": 0,
    "eip155Block": 0,
    "eip158Block": 0,
    "byzantiumBlock": 0,
    "constantinopleBlock": 0,
    "petersburgBlock": 0,
    "istanbulBlock": 0,
    "muirGlacierBlock": 0,
    "berlinBlock": 0,
    "londonBlock": 0,
    "arrowGlacierBlock": 0,
    "grayGlacierBlock": 0,
    "mergeNetsplitBlock": 0,
    "terminalTotalDifficulty": 0,
    "terminalTotalDifficultyPassed": true,
    "bedrockBlock": 0,
    "regolithTime": 0,
    "canyonTime": 0,
    "shanghaiTime": 0,
    "deltaTime": 0,
    "optimism": {
      "eip1559Elasticity": 6,
      "eip1559Denominator": 50,
      "eip1559DenominatorCanyon": 250
    }
  },
  "nonce": "0x0",
  "timestamp": "0x0",
  "extraData": "0x",
  "gasLimit": "0x1c9c380",
  "difficulty": "0x0",
  "mixHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "coinbase": "0x0000000000000000000000000000000000000000",
  "alloc": {
    "0x4200000000000000000000000000000000000015": {
      "code": "0x",
      "storage": {},
      "balance": "0x0"
    }
  },
  "number": "0x0",
  "gasUsed": "0x0",
  "parentHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "baseFeePerGas": "0x3b9aca00"
}
EOF

echo -e "${GREEN}✓ L2 configuration created${NC}"

# =============================================================================
# Start L2 Services
# =============================================================================
echo ""
echo -e "${YELLOW}[8/8] Starting L2 services...${NC}"

# Start L2 execution
echo "  Starting L2 execution layer (op-geth)..."
docker-compose -f "$COMPOSE_FILE" up -d l2-execution

# Wait for L2 execution to be healthy
echo "  Waiting for L2 execution to be ready..."
for i in {1..30}; do
    if curl -s http://localhost:9545 -X POST -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' | grep -q "0x385"; then
        break
    fi
    sleep 2
done

# Update rollup.json with actual L2 genesis hash
L2_GENESIS_HASH=$(curl -s -X POST -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["0x0", false],"id":1}' \
    http://localhost:9545 | jq -r '.result.hash')

if [ "$L2_GENESIS_HASH" != "null" ] && [ -n "$L2_GENESIS_HASH" ]; then
    jq --arg hash "$L2_GENESIS_HASH" '.genesis.l2.hash = $hash' \
        "$DEVNET_DIR/rollup.json" > "$DEVNET_DIR/rollup.json.tmp"
    mv "$DEVNET_DIR/rollup.json.tmp" "$DEVNET_DIR/rollup.json"
fi

echo -e "  ${GREEN}✓${NC} L2 execution started"

# Start remaining services
echo "  Starting op-node, batcher, proposer..."
docker-compose -f "$COMPOSE_FILE" up -d l2-node l2-batcher l2-proposer

sleep 5
echo -e "  ${GREEN}✓${NC} All L2 services started"

# =============================================================================
# Summary
# =============================================================================
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Sepolia Fork Devnet Started Successfully!              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Network Configuration:${NC}"
echo "  L1: Sepolia Fork (Chain ID: 11155111)"
echo "  L2: Local op-geth (Chain ID: 901)"
echo "  Fork Block: $CURRENT_BLOCK"
echo ""
echo -e "${CYAN}RPC Endpoints:${NC}"
echo "  L1 (Sepolia Fork):  http://localhost:8545"
echo "  L2 (op-geth):       http://localhost:9545"
echo "  L2 Rollup (op-node): http://localhost:7545"
echo ""
echo -e "${CYAN}Commands:${NC}"
echo "  View info:     make devnet-sepolia-fork-info"
echo "  Health check:  make devnet-sepolia-fork-health"
echo "  View logs:     make devnet-sepolia-fork-logs"
echo "  Mint ETH:      ./scripts/sepolia-fork/faucet.sh <address> <amount>"
echo "  Stop:          make devnet-sepolia-fork-stop"
echo ""
