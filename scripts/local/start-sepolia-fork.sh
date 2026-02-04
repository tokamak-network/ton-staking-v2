#!/bin/bash
# =============================================================================
# Start TON Staking V3 Local Devnet (Sepolia Fork)
# =============================================================================
# This script starts a complete local development environment with:
#   - L1: Anvil forking Sepolia testnet
#   - TON Staking V3 contracts deployed via allocs
#   - L2: op-geth + op-node (Docker)
# =============================================================================

set -eo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEVNET_DIR="$PROJECT_ROOT/.devnet"
DEVNET_SEPOLIA_DIR="$PROJECT_ROOT/.devnet-sepolia-fork"
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.l2-only.yml"

# Default configuration
SEPOLIA_RPC="${SEPOLIA_RPC:-https://ethereum-sepolia-rpc.publicnode.com}"
L1_BLOCK_TIME="${L1_BLOCK_TIME:-12}"
L1_PORT="${L1_PORT:-8546}"
ANVIL_LOG="${ANVIL_LOG:-/tmp/anvil.log}"

echo -e "${BLUE}=== Starting TON Staking V3 Local Devnet (Sepolia Fork) ===${NC}"
echo ""

# =============================================================================
# Step 1: Check prerequisites
# =============================================================================
echo -e "${YELLOW}Step 1: Checking prerequisites...${NC}"

for cmd in docker jq cast anvil; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}Error: $cmd not found${NC}"
        exit 1
    fi
done

if ! docker info &> /dev/null; then
    echo -e "${RED}Error: Docker is not running${NC}"
    exit 1
fi

# Check required files
if [ ! -f "$DEVNET_DIR/allocs-l1-staking-v3.json" ]; then
    echo -e "${RED}Error: allocs-l1-staking-v3.json not found${NC}"
    echo "Generate it with: ./scripts/generate-allocs-offline.sh"
    exit 1
fi

if [ ! -f "$DEVNET_DIR/addresses.json" ]; then
    echo -e "${RED}Error: addresses.json not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All prerequisites met${NC}"
echo ""

# =============================================================================
# Step 2: Start Anvil (Sepolia Fork)
# =============================================================================
echo -e "${YELLOW}Step 2: Starting Anvil (Sepolia Fork)...${NC}"

# Stop existing Anvil
if pgrep -f "anvil.*$L1_PORT" > /dev/null; then
    echo "Stopping existing Anvil..."
    pkill -f "anvil.*$L1_PORT" || true
    sleep 2
fi

# Start Anvil
echo "Forking from: $SEPOLIA_RPC"
nohup anvil \
    --host 0.0.0.0 \
    --port $L1_PORT \
    --fork-url "$SEPOLIA_RPC" \
    --chain-id 900 \
    --no-rate-limit \
    --gas-limit 30000000 \
    --code-size-limit 1000000 \
    > "$ANVIL_LOG" 2>&1 &

ANVIL_PID=$!
echo "Anvil PID: $ANVIL_PID"

# Wait for Anvil
echo "Waiting for Anvil to be ready..."
for i in {1..30}; do
    if cast block-number --rpc-url http://localhost:$L1_PORT &> /dev/null; then
        echo -e "${GREEN}✓ Anvil is ready${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}Error: Anvil failed to start${NC}"
        cat "$ANVIL_LOG"
        exit 1
    fi
    sleep 1
done

L1_BLOCK=$(cast block-number --rpc-url http://localhost:$L1_PORT)
echo "L1 Block: $L1_BLOCK"
echo ""

# =============================================================================
# Step 3: Deploy Optimism Contracts (via allocs) - to avoid historical state issues
# =============================================================================
echo -e "${YELLOW}Step 3: Deploying Optimism contracts (overriding fork state)...${NC}"

OPTIMISM_ALLOCS_FILE="$SCRIPT_DIR/../config/optimism-allocs-l1.json"
RPC="http://localhost:$L1_PORT"

if [ -f "$OPTIMISM_ALLOCS_FILE" ]; then
    ADDRESSES=$(jq -r 'keys[]' "$OPTIMISM_ALLOCS_FILE")
    TOTAL=$(echo "$ADDRESSES" | wc -l | tr -d ' ')
    COUNT=0

    for addr in $ADDRESSES; do
        COUNT=$((COUNT + 1))

        # Get code
        CODE=$(jq -r --arg addr "$addr" '.[$addr].code // empty' "$OPTIMISM_ALLOCS_FILE")
        if [ -n "$CODE" ] && [ "$CODE" != "null" ] && [ "$CODE" != "0x" ]; then
            cast rpc anvil_setCode "$addr" "$CODE" --rpc-url "$RPC" > /dev/null 2>&1
        fi

        # Get nonce
        NONCE=$(jq -r --arg addr "$addr" '.[$addr].nonce // "0x0"' "$OPTIMISM_ALLOCS_FILE")
        if [ -n "$NONCE" ] && [ "$NONCE" != "null" ] && [ "$NONCE" != "0x0" ]; then
            NONCE_DEC=$((NONCE))
            cast rpc anvil_setNonce "$addr" "$(printf '0x%x' $NONCE_DEC)" --rpc-url "$RPC" > /dev/null 2>&1
        fi

        # Get balance
        BALANCE=$(jq -r --arg addr "$addr" '.[$addr].balance // "0x0"' "$OPTIMISM_ALLOCS_FILE")
        if [ -n "$BALANCE" ] && [ "$BALANCE" != "null" ] && [ "$BALANCE" != "0x0" ]; then
            cast rpc anvil_setBalance "$addr" "$BALANCE" --rpc-url "$RPC" > /dev/null 2>&1
        fi

        # Get storage
        STORAGE_KEYS=$(jq -r --arg addr "$addr" '.[$addr].storage // {} | keys[]' "$OPTIMISM_ALLOCS_FILE" 2>/dev/null)
        if [ -n "$STORAGE_KEYS" ]; then
            for slot in $STORAGE_KEYS; do
                VALUE=$(jq -r --arg addr "$addr" --arg slot "$slot" '.[$addr].storage[$slot]' "$OPTIMISM_ALLOCS_FILE")
                if [ -n "$VALUE" ] && [ "$VALUE" != "null" ]; then
                    cast rpc anvil_setStorageAt "$addr" "$slot" "$VALUE" --rpc-url "$RPC" > /dev/null 2>&1
                fi
            done
        fi

        # Progress
        if [ $((COUNT % 20)) -eq 0 ] || [ $COUNT -eq $TOTAL ]; then
            echo "[$COUNT/$TOTAL] Deployed Optimism contracts..."
        fi
    done

    echo -e "${GREEN}✓ All $TOTAL Optimism contracts deployed${NC}"
else
    echo -e "${YELLOW}⚠ Optimism allocs not found, using fork state${NC}"
fi
echo ""

# =============================================================================
# Step 4: Deploy TON Staking V3 Contracts (via allocs)
# =============================================================================
echo -e "${YELLOW}Step 4: Deploying TON Staking V3 contracts...${NC}"

ALLOCS_FILE="$DEVNET_DIR/allocs-l1-staking-v3.json"

# Get all addresses
ADDRESSES=$(jq -r 'keys[]' "$ALLOCS_FILE")
TOTAL=$(echo "$ADDRESSES" | wc -l | tr -d ' ')
COUNT=0

for addr in $ADDRESSES; do
    COUNT=$((COUNT + 1))

    # Get code
    CODE=$(jq -r --arg addr "$addr" '.[$addr].code // empty' "$ALLOCS_FILE")
    if [ -n "$CODE" ] && [ "$CODE" != "null" ] && [ "$CODE" != "0x" ]; then
        cast rpc anvil_setCode "$addr" "$CODE" --rpc-url "$RPC" > /dev/null 2>&1
    fi

    # Get nonce
    NONCE=$(jq -r --arg addr "$addr" '.[$addr].nonce // "0x0"' "$ALLOCS_FILE")
    if [ -n "$NONCE" ] && [ "$NONCE" != "null" ] && [ "$NONCE" != "0x0" ]; then
        NONCE_DEC=$((NONCE))
        cast rpc anvil_setNonce "$addr" "$(printf '0x%x' $NONCE_DEC)" --rpc-url "$RPC" > /dev/null 2>&1
    fi

    # Get balance
    BALANCE=$(jq -r --arg addr "$addr" '.[$addr].balance // "0x0"' "$ALLOCS_FILE")
    if [ -n "$BALANCE" ] && [ "$BALANCE" != "null" ] && [ "$BALANCE" != "0x0" ]; then
        cast rpc anvil_setBalance "$addr" "$BALANCE" --rpc-url "$RPC" > /dev/null 2>&1
    fi

    # Get storage
    STORAGE_KEYS=$(jq -r --arg addr "$addr" '.[$addr].storage // {} | keys[]' "$ALLOCS_FILE" 2>/dev/null)
    if [ -n "$STORAGE_KEYS" ]; then
        for slot in $STORAGE_KEYS; do
            VALUE=$(jq -r --arg addr "$addr" --arg slot "$slot" '.[$addr].storage[$slot]' "$ALLOCS_FILE")
            if [ -n "$VALUE" ] && [ "$VALUE" != "null" ]; then
                cast rpc anvil_setStorageAt "$addr" "$slot" "$VALUE" --rpc-url "$RPC" > /dev/null 2>&1
            fi
        done
    fi

    # Progress
    if [ $((COUNT % 20)) -eq 0 ] || [ $COUNT -eq $TOTAL ]; then
        echo "[$COUNT/$TOTAL] Deployed contracts..."
    fi
done

echo -e "${GREEN}✓ All $TOTAL contracts deployed${NC}"
echo ""

# =============================================================================
# Step 5: Verify key contracts
# =============================================================================
echo -e "${YELLOW}Step 5: Verifying contracts...${NC}"

TON_ADDR=$(jq -r '.ton' "$DEVNET_DIR/addresses.json")
WTON_ADDR=$(jq -r '.wton' "$DEVNET_DIR/addresses.json")
SEIG_ADDR=$(jq -r '.seigManagerProxy' "$DEVNET_DIR/addresses.json")

TON_NAME=$(cast call "$TON_ADDR" "name()(string)" --rpc-url "$RPC" 2>/dev/null || echo "FAIL")
WTON_NAME=$(cast call "$WTON_ADDR" "name()(string)" --rpc-url "$RPC" 2>/dev/null || echo "FAIL")
SEIG_TON=$(cast call "$SEIG_ADDR" "ton()(address)" --rpc-url "$RPC" 2>/dev/null || echo "FAIL")

if [ "$TON_NAME" = "\"TON\"" ] && [ "$WTON_NAME" = "\"Wrapped TON\"" ]; then
    echo -e "${GREEN}✓ TON contracts verified${NC}"
else
    echo -e "${RED}Warning: Contract verification failed${NC}"
    echo "  TON name: $TON_NAME"
    echo "  WTON name: $WTON_NAME"
fi
echo ""

# =============================================================================
# Step 6: Setup L2 configuration
# =============================================================================
echo -e "${YELLOW}Step 6: Setting up L2 configuration...${NC}"

mkdir -p "$DEVNET_SEPOLIA_DIR"

# Copy files
cp "$DEVNET_DIR/jwt-secret.txt" "$DEVNET_SEPOLIA_DIR/" 2>/dev/null || openssl rand -hex 32 > "$DEVNET_SEPOLIA_DIR/jwt-secret.txt"
cp "$DEVNET_DIR/addresses.json" "$DEVNET_SEPOLIA_DIR/"
cp "$DEVNET_DIR/optimism-addresses.json" "$DEVNET_SEPOLIA_DIR/" 2>/dev/null || true
cp "$DEVNET_DIR/devnetL1.json" "$DEVNET_SEPOLIA_DIR/" 2>/dev/null || true

# Get current L1 block info
L1_BLOCK_INFO=$(cast block latest --rpc-url "$RPC" --json)
L1_BLOCK_NUM=$(($(echo "$L1_BLOCK_INFO" | jq -r '.number')))
L1_BLOCK_HASH=$(echo "$L1_BLOCK_INFO" | jq -r '.hash')
L1_TIME=$(($(echo "$L1_BLOCK_INFO" | jq -r '.timestamp')))
L2_TIME=$((L1_TIME + 1))

echo "L1 Block: $L1_BLOCK_NUM"
echo "L1 Hash: $L1_BLOCK_HASH"

# Get Optimism addresses
OPTIMISM_PORTAL=$(jq -r '.OptimismPortalProxy // "0xbF6531954Aa355f478e54fEDff94D9D9E7008D79"' "$DEVNET_DIR/optimism-addresses.json" 2>/dev/null)
SYSTEM_CONFIG=$(jq -r '.SystemConfigProxy // "0x577AcB7fA48878245a854ba51eD051a5B47cF83f"' "$DEVNET_DIR/optimism-addresses.json" 2>/dev/null)

# Create genesis-l2.json
L2_TIME_HEX=$(printf "0x%x" $L2_TIME)
cat > "$DEVNET_SEPOLIA_DIR/genesis-l2.json" <<EOF
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
  "timestamp": "$L2_TIME_HEX",
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

# Create initial rollup.json (L2 hash will be updated after op-geth starts)
cat > "$DEVNET_SEPOLIA_DIR/rollup.json" <<EOF
{
  "genesis": {
    "l1": {
      "hash": "$L1_BLOCK_HASH",
      "number": $L1_BLOCK_NUM
    },
    "l2": {
      "hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
      "number": 0
    },
    "l2_time": $L2_TIME,
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
  "deposit_contract_address": "${OPTIMISM_PORTAL:-0xbF6531954Aa355f478e54fEDff94D9D9E7008D79}",
  "l1_system_config_address": "${SYSTEM_CONFIG:-0x577AcB7fA48878245a854ba51eD051a5B47cF83f}"
}
EOF

echo -e "${GREEN}✓ L2 configuration created${NC}"
echo ""

# =============================================================================
# Step 7: Start L2 services
# =============================================================================
echo -e "${YELLOW}Step 7: Starting L2 services (Docker)...${NC}"

# Stop existing L2 containers
docker compose -f "$COMPOSE_FILE" down 2>/dev/null || true

# Start op-geth first
docker compose -f "$COMPOSE_FILE" up -d l2-execution

echo "Waiting for op-geth..."
for i in {1..30}; do
    if cast block-number --rpc-url http://localhost:9545 &> /dev/null; then
        echo -e "${GREEN}✓ op-geth is ready${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}Error: op-geth failed to start${NC}"
        docker logs ton-staking-l2-execution
        exit 1
    fi
    sleep 2
done

# Get L2 genesis hash
L2_GENESIS_HASH=$(cast block 0 --rpc-url http://localhost:9545 --json | jq -r '.hash')
echo "L2 Genesis Hash: $L2_GENESIS_HASH"

# Update rollup.json with L2 hash
jq --arg hash "$L2_GENESIS_HASH" '.genesis.l2.hash = $hash' "$DEVNET_SEPOLIA_DIR/rollup.json" > /tmp/rollup.json.tmp
mv /tmp/rollup.json.tmp "$DEVNET_SEPOLIA_DIR/rollup.json"

# Start op-node
docker compose -f "$COMPOSE_FILE" up -d l2-node

echo "Waiting for op-node..."
for i in {1..30}; do
    if docker ps --filter "name=ton-staking-l2-node" --format "{{.Status}}" | grep -q "healthy"; then
        echo -e "${GREEN}✓ op-node is ready${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${YELLOW}Warning: op-node healthcheck timeout, continuing...${NC}"
    fi
    sleep 2
done

# Start batcher and proposer
echo "Starting batcher and proposer..."
docker compose -f "$COMPOSE_FILE" up -d l2-batcher l2-proposer
echo -e "${GREEN}✓ Batcher and proposer started${NC}"

# Start RAT clients
echo "Starting RAT clients..."
docker compose -f "$COMPOSE_FILE" up -d rat-client-1 rat-client-2 rat-client-3
echo -e "${GREEN}✓ RAT clients started (3 validators)${NC}"
echo ""

# =============================================================================
# Step 8: Enable auto-mining on L1
# =============================================================================
echo -e "${YELLOW}Step 8: Enabling auto-mining on L1...${NC}"
cast rpc anvil_setIntervalMining $L1_BLOCK_TIME --rpc-url "$RPC" > /dev/null
echo -e "${GREEN}✓ L1 auto-mining enabled (${L1_BLOCK_TIME}s interval)${NC}"
echo ""

# =============================================================================
# Step 9: Register L2 in TON Staking System
# =============================================================================
echo -e "${YELLOW}Step 9: Registering L2 in TON Staking system...${NC}"

# Load contract addresses
L1_BRIDGE_REGISTRY=$(jq -r '.l1BridgeRegistryProxy' "$DEVNET_DIR/addresses.json")
LAYER2_MANAGER=$(jq -r '.layer2ManagerProxy' "$DEVNET_DIR/addresses.json")
SYSTEM_CONFIG_ADDR=$(jq -r '.systemConfig' "$DEVNET_DIR/addresses.json")
TON_ADDR=$(jq -r '.ton' "$DEVNET_DIR/addresses.json")
WTON_ADDR=$(jq -r '.wton' "$DEVNET_DIR/addresses.json")
DEPOSIT_MANAGER=$(jq -r '.depositManagerProxy' "$DEVNET_DIR/addresses.json")

# Test accounts (Anvil default accounts)
# Account #1: TON Staking deployer (manager role)
MANAGER_KEY="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
MANAGER_ADDR="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
# Account #0: Operator
OPERATOR_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
OPERATOR_ADDR="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

# Minimum staking amount (1001 WTON in RAY = 1001 * 1e27)
MIN_STAKE="1001000000000000000000000000000"

# --- Step 8.1: Check if rollup types are registered ---
echo "  Checking rollup type registration..."
TYPE3_SUPPORT=$(cast call "$L1_BRIDGE_REGISTRY" "rollupTypeInfo(uint8)(string,bytes4,bytes4,bytes4,uint8,bool)" 3 --rpc-url "$RPC" 2>/dev/null | head -1 || echo "")

if [ -z "$TYPE3_SUPPORT" ] || [ "$TYPE3_SUPPORT" = '""' ]; then
    echo "  Registering rollup types..."

    # Add manager if not already
    cast send "$L1_BRIDGE_REGISTRY" "addManager(address)" "$MANAGER_ADDR" \
        --private-key "$MANAGER_KEY" --rpc-url "$RPC" > /dev/null 2>&1 || true

    # Type 1: Optimism Legacy
    cast send "$L1_BRIDGE_REGISTRY" \
        "addRollupType(uint8,string,bytes4,bytes4,bytes4,uint8,bool)" \
        1 "Optimism Legacy" 0x078f29cf 0x078f29cf 0x00000000 0 false \
        --private-key "$MANAGER_KEY" --rpc-url "$RPC" > /dev/null 2>&1 || true

    # Type 2: Optimism Bedrock
    cast send "$L1_BRIDGE_REGISTRY" \
        "addRollupType(uint8,string,bytes4,bytes4,bytes4,uint8,bool)" \
        2 "Optimism Bedrock" 0x078f29cf 0x0a49cb03 0x00000000 1 false \
        --private-key "$MANAGER_KEY" --rpc-url "$RPC" > /dev/null 2>&1 || true

    # Type 3: Optimism Bedrock DisputeGame (V3 eligible)
    cast send "$L1_BRIDGE_REGISTRY" \
        "addRollupType(uint8,string,bytes4,bytes4,bytes4,uint8,bool)" \
        3 "Optimism Bedrock DisputeGame" 0x078f29cf 0x0a49cb03 0x0a1e5c7d 1 true \
        --private-key "$MANAGER_KEY" --rpc-url "$RPC" > /dev/null 2>&1 || true

    echo -e "${GREEN}  ✓ Rollup types registered${NC}"
else
    echo -e "${GREEN}  ✓ Rollup types already registered${NC}"
fi

# --- Step 8.2: Register Rollup Config to L1BridgeRegistry ---
echo "  Checking rollup config registration..."
ROLLUP_INFO=$(cast call "$L1_BRIDGE_REGISTRY" "getRollupInfo(address)(uint8,address,bool,bool,string)" "$SYSTEM_CONFIG_ADDR" --rpc-url "$RPC" 2>/dev/null || echo "0")
ROLLUP_TYPE=$(echo "$ROLLUP_INFO" | head -1)

if [ "$ROLLUP_TYPE" = "0" ]; then
    echo "  Registering rollup config (Type 3)..."
    cast send "$L1_BRIDGE_REGISTRY" \
        "registerRollupConfigByManager(address,uint8,address,string)" \
        "$SYSTEM_CONFIG_ADDR" 3 "$TON_ADDR" "Devnet L2" \
        --private-key "$MANAGER_KEY" --rpc-url "$RPC" > /dev/null
    echo -e "${GREEN}  ✓ Rollup config registered${NC}"
else
    echo -e "${GREEN}  ✓ Rollup config already registered (Type: $ROLLUP_TYPE)${NC}"
fi

# --- Step 8.3: Register CandidateAddOn (L2 Operator Staking) ---
echo "  Checking CandidateAddOn registration..."
ROLLUP_CONFIG_INFO=$(cast call "$LAYER2_MANAGER" "rollupConfigInfo(address)(uint8,address)" "$SYSTEM_CONFIG_ADDR" --rpc-url "$RPC" 2>/dev/null || echo "0 0x0000000000000000000000000000000000000000")
ROLLUP_STATUS=$(echo "$ROLLUP_CONFIG_INFO" | head -1)

if [ "$ROLLUP_STATUS" = "0" ]; then
    echo "  Approving WTON to Layer2Manager..."
    cast send "$WTON_ADDR" "approve(address,uint256)" "$LAYER2_MANAGER" \
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff \
        --private-key "$OPERATOR_KEY" --rpc-url "$RPC" > /dev/null

    echo "  Registering CandidateAddOn with 1001 WTON stake..."
    cast send "$LAYER2_MANAGER" \
        "registerCandidateAddOn(address,uint256,bool,string)" \
        "$SYSTEM_CONFIG_ADDR" "$MIN_STAKE" false "Devnet L2 Operator" \
        --private-key "$OPERATOR_KEY" --rpc-url "$RPC" > /dev/null

    echo -e "${GREEN}  ✓ CandidateAddOn registered${NC}"
else
    echo -e "${GREEN}  ✓ CandidateAddOn already registered (Status: $ROLLUP_STATUS)${NC}"
fi

# --- Step 8.4: Verify registration ---
echo "  Verifying registration..."
FINAL_ROLLUP_INFO=$(cast call "$L1_BRIDGE_REGISTRY" "getRollupInfo(address)(uint8,address,bool,bool,string)" "$SYSTEM_CONFIG_ADDR" --rpc-url "$RPC" 2>/dev/null)
FINAL_CONFIG_INFO=$(cast call "$LAYER2_MANAGER" "rollupConfigInfo(address)(uint8,address)" "$SYSTEM_CONFIG_ADDR" --rpc-url "$RPC" 2>/dev/null)

FINAL_TYPE=$(echo "$FINAL_ROLLUP_INFO" | head -1)
FINAL_STATUS=$(echo "$FINAL_CONFIG_INFO" | head -1)
OPERATOR_MANAGER=$(echo "$FINAL_CONFIG_INFO" | tail -1)

echo ""
echo -e "${GREEN}  L2 Registration Complete:${NC}"
echo "    Rollup Type: $FINAL_TYPE"
echo "    Status: $FINAL_STATUS"
echo "    OperatorManager: $OPERATOR_MANAGER"
echo ""

# =============================================================================
# Step 10: Register Validators
# =============================================================================
echo -e "${YELLOW}Step 10: Registering validators...${NC}"

# Validator accounts (Anvil default accounts)
VALIDATOR1_KEY="0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6"
VALIDATOR1_ADDR="0x90F79bf6EB2c4f870365E785982E1f101E93b906"
VALIDATOR2_KEY="0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a"
VALIDATOR2_ADDR="0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65"
VALIDATOR3_KEY="0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba"
VALIDATOR3_ADDR="0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc"

# Get contract addresses
DEPOSIT_MANAGER=$(jq -r '.depositManagerProxy' "$DEVNET_DIR/addresses.json")
RAT=$(jq -r '.ratProxy' "$DEVNET_DIR/addresses.json")
# Get CandidateAddOn address (layer2 for deposits)
CANDIDATE_ADDON=$(cast call "$LAYER2_MANAGER" "getLayer2BySystemConfig(address)(address)" "$SYSTEM_CONFIG_ADDR" --rpc-url "$RPC")

# Deposit amount: 100 WTON (100 * 1e27 = 1e29 ray)
VALIDATOR_DEPOSIT="100000000000000000000000000000"

register_validator() {
    local KEY=$1
    local ADDR=$2
    local NAME=$3

    echo "  Registering $NAME ($ADDR)..."

    # Step 1: Approve WTON
    cast send "$WTON_ADDR" "approve(address,uint256)" "$DEPOSIT_MANAGER" \
        "115792089237316195423570985008687907853269984665640564039457584007913129639935" \
        --private-key "$KEY" --rpc-url "$RPC" --gas-limit 100000 > /dev/null 2>&1

    # Step 2: Deposit to CandidateAddOn
    cast send "$DEPOSIT_MANAGER" "deposit(address,uint256)" "$CANDIDATE_ADDON" "$VALIDATOR_DEPOSIT" \
        --private-key "$KEY" --rpc-url "$RPC" --gas-limit 500000 > /dev/null 2>&1

    # Step 3: Register with RAT
    cast send "$RAT" "registerValidator(address)" "$SYSTEM_CONFIG_ADDR" \
        --private-key "$KEY" --rpc-url "$RPC" --gas-limit 500000 > /dev/null 2>&1

    echo -e "${GREEN}  ✓ $NAME registered${NC}"
}

# Register all 3 validators
register_validator "$VALIDATOR1_KEY" "$VALIDATOR1_ADDR" "Validator1"
register_validator "$VALIDATOR2_KEY" "$VALIDATOR2_ADDR" "Validator2"
register_validator "$VALIDATOR3_KEY" "$VALIDATOR3_ADDR" "Validator3"

# Verify registration
VALIDATOR_COUNT=$(cast call "$RAT" "getValidatorCount(address)(uint256)" "$SYSTEM_CONFIG_ADDR" --rpc-url "$RPC")
echo ""
echo -e "${GREEN}  Total validators registered: $VALIDATOR_COUNT${NC}"
echo ""

# =============================================================================
# Step 11: Configure RAT Parameters
# =============================================================================
echo -e "${YELLOW}Step 11: Configuring RAT parameters...${NC}"

# RAT configuration values (matching DeployV3FullForDevnet.s.sol)
# All WTON values in RAY format (1e27)
RAT_TRIGGER_PROBABILITY="1000000000000000000000000000"     # 1e27 = 100% (for testing)
RAT_EVIDENCE_PERIOD="600"                                  # 600 seconds = 10 minutes
RAT_SLASHING_PENALTY="10000000000000000000000000000"      # 10 WTON = 10e27
RAT_VALIDATOR_BUFFER="50000000000000000000000000000"      # 50 WTON = 50e27
RAT_MINIMUM_THRESHOLD="60000000000000000000000000000"     # 60 WTON = 60e27 (>= slashing + buffer)
RAT_MAX_VALIDATORS_PER_L2="100"
RAT_CHALLENGE_GAME_DURATION="604800"                       # 7 days in seconds
RAT_SAFETY_BUFFER="86400"                                  # 1 day in seconds
RAT_TREASURY="$OPERATOR_ADDR"                              # Treasury = operator for devnet
RAT_ATTENTION_COST="1000000000000000000000000000"         # 1 WTON = 1e27
RAT_RELAXED_CHECK="true"                                   # Relaxed validator check enabled

# Encode the tuple for setConfig
# struct RATConfigParams {
#     uint256 ratTriggerProbability;
#     uint256 evidenceSubmissionPeriod;
#     uint256 slashingPenalty;
#     uint256 validatorBuffer;
#     uint256 minimumThreshold;
#     uint256 maxValidatorsPerL2;
#     uint256 challengeGameDuration;
#     uint256 safetyBuffer;
#     address treasury;
#     uint256 attentionCost;
#     bool relaxedValidatorCheck;
# }

echo "  Setting RAT configuration..."
cast send "$RAT" \
    "setConfig((uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,address,uint256,bool))" \
    "($RAT_TRIGGER_PROBABILITY,$RAT_EVIDENCE_PERIOD,$RAT_SLASHING_PENALTY,$RAT_VALIDATOR_BUFFER,$RAT_MINIMUM_THRESHOLD,$RAT_MAX_VALIDATORS_PER_L2,$RAT_CHALLENGE_GAME_DURATION,$RAT_SAFETY_BUFFER,$RAT_TREASURY,$RAT_ATTENTION_COST,$RAT_RELAXED_CHECK)" \
    --private-key "$MANAGER_KEY" --rpc-url "$RPC" > /dev/null 2>&1

# Verify configuration
VERIFY_PENALTY=$(cast call "$RAT" "slashingPenalty()(uint256)" --rpc-url "$RPC")
VERIFY_EVIDENCE=$(cast call "$RAT" "evidenceSubmissionPeriod()(uint256)" --rpc-url "$RPC")
VERIFY_RELAXED=$(cast call "$RAT" "relaxedValidatorCheck()(bool)" --rpc-url "$RPC")

echo -e "${GREEN}  ✓ RAT configured:${NC}"
# Clean values and convert (WTON uses 27 decimals = RAY)
PENALTY_CLEAN=$(echo "$VERIFY_PENALTY" | tr -d '[:space:]')
EVIDENCE_CLEAN=$(echo "$VERIFY_EVIDENCE" | tr -d '[:space:]')
echo "    Slashing Penalty: $(echo "$PENALTY_CLEAN" | awk '{printf "%.0f", $1/1e27}') WTON"
echo "    Evidence Period: $EVIDENCE_CLEAN seconds ($(echo "$EVIDENCE_CLEAN" | awk '{printf "%.0f", $1/60}') minutes)"
echo "    Relaxed Check: $VERIFY_RELAXED"
echo ""

# =============================================================================
# Step 12: Setup Personal Test Account
# =============================================================================
echo -e "${YELLOW}Step 12: Setting up Personal Test account...${NC}"

PERSONAL_ADDR="0x976EA74026E726554dB657fA54763abd0C3a0aa9"
PERSONAL_ETH="100000000000000000000000"  # 100000 ETH in wei
PERSONAL_TON="100000000000000000000000"  # 100000 TON (18 decimals)
PERSONAL_WTON="100000000000000000000000000000000"  # 100000 WTON (27 decimals = ray)

# Set ETH balance
cast rpc anvil_setBalance "$PERSONAL_ADDR" "$(printf '0x%x' $PERSONAL_ETH)" --rpc-url "$RPC" > /dev/null 2>&1

# Mint TON
cast send "$TON_ADDR" "mint(address,uint256)" "$PERSONAL_ADDR" "$PERSONAL_TON" \
    --private-key "$OPERATOR_KEY" --rpc-url "$RPC" > /dev/null 2>&1

# Mint WTON
cast send "$WTON_ADDR" "mint(address,uint256)" "$PERSONAL_ADDR" "$PERSONAL_WTON" \
    --private-key "$OPERATOR_KEY" --rpc-url "$RPC" > /dev/null 2>&1

echo -e "${GREEN}  ✓ Personal Test account ready (100k ETH + 100k TON + 100k WTON)${NC}"
echo ""

# =============================================================================
# Summary
# =============================================================================
echo -e "${GREEN}=== Devnet Started Successfully ===${NC}"
echo ""
echo -e "${BLUE}=== RPC Endpoints ===${NC}"
echo "L1 (Anvil Sepolia Fork): http://localhost:$L1_PORT"
echo "L2 (op-geth):            http://localhost:9545"
echo "L2 Rollup (op-node):     http://localhost:7545"
echo ""
echo -e "${BLUE}=== Key Addresses ===${NC}"
echo "TON:            $(jq -r '.ton' "$DEVNET_DIR/addresses.json")"
echo "WTON:           $(jq -r '.wton' "$DEVNET_DIR/addresses.json")"
echo "SeigManager:    $(jq -r '.seigManagerProxy' "$DEVNET_DIR/addresses.json")"
echo "RAT:            $(jq -r '.ratProxy' "$DEVNET_DIR/addresses.json")"
echo "Layer2Manager:  $(jq -r '.layer2ManagerProxy' "$DEVNET_DIR/addresses.json")"
echo "SystemConfig:   $(jq -r '.systemConfig' "$DEVNET_DIR/addresses.json")"
echo ""
echo -e "${BLUE}=== L2 Registration ===${NC}"
echo "Rollup Type:    3 (Optimism Bedrock DisputeGame)"
echo "Operator:       $OPERATOR_ADDR"
echo "OperatorManager: $OPERATOR_MANAGER"
echo ""
echo -e "${BLUE}=== Test Accounts (100k TON + 100k WTON each) ===${NC}"
echo "Operator:   0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 (Anvil #0)"
echo "Manager:    0x70997970C51812dc3A010C7d01b50e0d17dc79C8 (Anvil #1)"
echo "Validator1: 0x90F79bf6EB2c4f870365E785982E1f101E93b906 (Anvil #3)"
echo "Validator2: 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65 (Anvil #4)"
echo "Validator3: 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc (Anvil #5)"
echo "Personal:   0x976EA74026E726554dB657fA54763abd0C3a0aa9 (Anvil #6)"
echo ""
echo -e "${BLUE}=== Current Block Numbers ===${NC}"
echo "L1: $(cast block-number --rpc-url http://localhost:$L1_PORT 2>/dev/null || echo 'N/A')"
echo "L2: $(cast block-number --rpc-url http://localhost:9545 2>/dev/null || echo 'N/A')"
echo ""
echo -e "${YELLOW}Logs:${NC}"
echo "  Anvil: tail -f $ANVIL_LOG"
echo "  L2:    docker logs -f ton-staking-l2-node"
echo "  RAT:   docker logs -f ton-staking-rat-client-1"
echo ""
echo -e "${YELLOW}Stop:${NC}"
echo "  ./scripts/local/stop-sepolia-fork.sh"
echo ""
echo -e "${YELLOW}Web UI:${NC}"
echo "  cd web-ui && npm run dev"
echo "  Open http://localhost:5173"
