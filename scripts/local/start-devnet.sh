#!/bin/bash
# =============================================================================
# Start TON Staking V3 Local Devnet (Custom Genesis)
# =============================================================================
# This script starts a complete local development environment with:
#   - L1 (Geth with Clique PoA) with TON Staking V3 contracts
#   - L2 (op-geth with Debug Mode) for RAT Client support
#   - All services (op-node, batcher, proposer, RAT clients)
# =============================================================================

set -eo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEVNET_DIR="$PROJECT_ROOT/.devnet"
DEPLOYMENT_DIR="$PROJECT_ROOT/deployments/local"
COMPOSE_FILE="$DEPLOYMENT_DIR/docker-compose.yml"

echo -e "${BLUE}=== Starting TON Staking V3 Local Devnet ===${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: docker not found${NC}"
    echo "Install Docker Desktop: https://www.docker.com/products/docker-desktop"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}Error: docker-compose not found${NC}"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${RED}Error: Docker is not running${NC}"
    echo "Please start Docker Desktop"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq not found${NC}"
    echo "Install: brew install jq"
    exit 1
fi

if ! command -v cast &> /dev/null; then
    echo -e "${RED}Error: cast (foundry) not found${NC}"
    echo "Install: curl -L https://foundry.paradigm.xyz | bash && foundryup"
    exit 1
fi

echo -e "${GREEN}✓ All prerequisites met${NC}"
echo ""

# Check genesis file
if [ ! -f "$DEVNET_DIR/genesis-l1-staking-v3.json" ]; then
    echo -e "${RED}Error: Genesis file not found${NC}"
    echo "Run 'make devnet-allocs-offline' first"
    exit 1
fi

if [ ! -f "$DEVNET_DIR/optimism-addresses.json" ]; then
    echo -e "${RED}Error: optimism-addresses.json not found${NC}"
    echo "Run 'make devnet-allocs-offline' first"
    exit 1
fi

if [ ! -f "$DEVNET_DIR/addresses.json" ]; then
    echo -e "${RED}Error: addresses.json not found${NC}"
    echo "Run 'make devnet-allocs-offline' first"
    exit 1
fi

echo -e "${GREEN}✓ Genesis files found${NC}"
echo ""

# Generate JWT secret
if [ ! -f "$DEVNET_DIR/jwt-secret.txt" ]; then
    echo -e "${YELLOW}Generating JWT secret...${NC}"
    openssl rand -hex 32 > "$DEVNET_DIR/jwt-secret.txt"
    echo -e "${GREEN}✓ JWT secret generated${NC}"
fi

# Check if devnet is already running
if docker ps | grep -q "ton-staking-l1"; then
    echo -e "${YELLOW}Devnet is already running${NC}"
    echo "Stop it first with: make devnet-local-stop"
    exit 1
fi

# Step 1: Start L1
echo ""
echo -e "${YELLOW}Step 1: Starting L1 (Geth with Clique PoA)...${NC}"
docker-compose -f "$COMPOSE_FILE" up -d l1

# Wait for L1
echo -e "${YELLOW}Waiting for L1 to be ready...${NC}"
for i in {1..30}; do
    if cast block-number --rpc-url http://localhost:8545 &> /dev/null; then
        echo -e "${GREEN}✓ L1 is ready${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}Error: L1 failed to start${NC}"
        docker-compose -f "$COMPOSE_FILE" logs l1
        exit 1
    fi
    sleep 2
done

# Step 2: Get L1 genesis hash and create rollup.json
echo ""
echo -e "${YELLOW}Step 2: Configuring rollup with L1 genesis...${NC}"

L1_BLOCK_0=$(curl -s -X POST -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["0x0", false],"id":1}' \
    http://localhost:8545)
L1_GENESIS_HASH=$(echo "$L1_BLOCK_0" | jq -r '.result.hash')
L1_GENESIS_TIME_HEX=$(echo "$L1_BLOCK_0" | jq -r '.result.timestamp')

if [ "$L1_GENESIS_TIME_HEX" = "0x0" ] || [ "$L1_GENESIS_TIME_HEX" = "0" ]; then
    L1_GENESIS_TIME_DEC=$(date +%s)
else
    L1_GENESIS_TIME_DEC=$((L1_GENESIS_TIME_HEX))
fi

echo "L1 Genesis Hash: $L1_GENESIS_HASH"
echo "L1 Genesis Time: $L1_GENESIS_TIME_DEC"

OPTIMISM_PORTAL=$(jq -r '.OptimismPortalProxy' "$DEVNET_DIR/optimism-addresses.json")
SYSTEM_CONFIG=$(jq -r '.systemConfig' "$DEVNET_DIR/addresses.json")

# Create rollup.json
cat > "$DEVNET_DIR/rollup.json" <<EOF
{
  "genesis": {
    "l1": {
      "hash": "$L1_GENESIS_HASH",
      "number": 0
    },
    "l2": {
      "hash": "0xd4e56740f876aef8c010b86a40d5f56745a118d0906a34e69aec8c0db1cb8fa3",
      "number": 0
    },
    "l2_time": $L1_GENESIS_TIME_DEC,
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
  "l1_chain_id": 900,
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

echo -e "${GREEN}✓ Rollup configuration created${NC}"

# Step 3: Create L2 genesis
echo ""
echo -e "${YELLOW}Step 3: Creating L2 genesis...${NC}"

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

echo -e "${GREEN}✓ L2 genesis created${NC}"

# Step 4: Start L2 execution
echo ""
echo -e "${YELLOW}Step 4: Starting L2 execution layer...${NC}"
docker-compose -f "$COMPOSE_FILE" up -d l2-execution

sleep 10
echo -e "${GREEN}✓ L2 execution started${NC}"

# Step 5: Get L2 genesis hash and update rollup.json
echo ""
echo -e "${YELLOW}Step 5: Updating rollup config with L2 genesis hash...${NC}"

L2_GENESIS_HASH=$(curl -s -X POST -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["0x0", false],"id":1}' \
    http://localhost:9545 | jq -r '.result.hash')

echo "L2 Genesis Hash: $L2_GENESIS_HASH"

jq --arg hash "$L2_GENESIS_HASH" '.genesis.l2.hash = $hash' "$DEVNET_DIR/rollup.json" > "$DEVNET_DIR/rollup.json.tmp"
mv "$DEVNET_DIR/rollup.json.tmp" "$DEVNET_DIR/rollup.json"

echo -e "${GREEN}✓ Rollup config updated${NC}"

# Step 6: Start op-node, batcher, proposer
echo ""
echo -e "${YELLOW}Step 6: Starting op-node, batcher, proposer...${NC}"
docker-compose -f "$COMPOSE_FILE" up -d l2-node l2-batcher l2-proposer

sleep 10
echo -e "${GREEN}✓ All services started${NC}"

# Summary
echo ""
echo -e "${GREEN}=== Local Devnet Started Successfully ===${NC}"
echo ""
echo -e "${BLUE}=== Service Status ===${NC}"
docker-compose -f "$COMPOSE_FILE" ps

echo ""
echo -e "${BLUE}=== RPC Endpoints ===${NC}"
echo "L1 (Geth):           http://localhost:8545"
echo "L2 (op-geth):        http://localhost:9545"
echo "L2 Rollup (op-node): http://localhost:7545"

# Test connectivity
echo ""
echo -e "${YELLOW}Testing connectivity...${NC}"
L1_BLOCK=$(cast block-number --rpc-url http://localhost:8545 2>/dev/null || echo "Not ready")
echo "L1 Block Number: $L1_BLOCK"

L2_BLOCK=$(cast block-number --rpc-url http://localhost:9545 2>/dev/null || echo "Not ready")
echo "L2 Block Number: $L2_BLOCK"

echo ""
echo -e "${GREEN}=== Setup Complete ===${NC}"
echo ""
echo "Next steps:"
echo "  1. View status:   make devnet-local-info"
echo "  2. View logs:     make devnet-local-logs"
echo "  3. Stop devnet:   make devnet-local-stop"
echo ""
