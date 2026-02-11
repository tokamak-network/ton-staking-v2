#!/bin/bash
# =============================================================================
# Start TON Staking V3 Local Devnet with Fast Withdrawal (Prague Hardfork)
# =============================================================================
# This script starts a complete local development environment with:
#   - L1: Anvil with Prague hardfork (BLS precompiles enabled)
#   - TON Staking V3 contracts deployed via allocs
#   - L2: op-geth + op-node (Docker)
#   - Fast Withdrawal: 3 Validators + 1 Aggregator
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

# Load .env file if exists
if [ -f "$PROJECT_ROOT/.env" ]; then
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
fi

# Default configuration
L1_BLOCK_TIME="${L1_BLOCK_TIME:-12}"
L1_PORT="${L1_PORT:-8546}"
ANVIL_LOG="${ANVIL_LOG:-/tmp/anvil.log}"

echo -e "${BLUE}=== Starting TON Staking V3 Local Devnet with Fast Withdrawal (Prague Hardfork) ===${NC}"
echo ""

# =============================================================================
# Step 1: Check prerequisites
# =============================================================================
echo -e "${YELLOW}Step 1: Checking prerequisites...${NC}"

for cmd in docker jq cast anvil go python3; do
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

# Build BLS keygen tool if needed
BLS_KEYGEN="$PROJECT_ROOT/clients/fast-withdrawal/validator/bls-keygen"
if [ ! -f "$BLS_KEYGEN" ]; then
    echo "BLS keygen not found, building..."
    (cd "$PROJECT_ROOT/clients/fast-withdrawal/validator" && go build -o bls-keygen ./cmd/keygen)
    echo -e "${GREEN}  BLS keygen built${NC}"
fi

echo -e "${GREEN}All prerequisites met${NC}"
echo ""

# Check that Docker images are pre-built
# Run ./scripts/local/build-docker-images.sh first if images don't exist
if ! docker image inspect ton-staking-v2-fw-node-1 &>/dev/null; then
    echo -e "${RED}Error: Docker images not built. Run first:${NC}"
    echo "  ./scripts/local/build-docker-images.sh"
    exit 1
fi
echo -e "${GREEN}Docker images found (pre-built)${NC}"
echo ""

# =============================================================================
# Step 2: Start Anvil (Prague Hardfork - BLS precompiles enabled)
# =============================================================================
echo -e "${YELLOW}Step 2: Starting Anvil (Prague Hardfork)...${NC}"

# Stop existing Anvil
if pgrep -f "anvil.*$L1_PORT" > /dev/null; then
    echo "Stopping existing Anvil..."
    pkill -f "anvil.*$L1_PORT" || true
    sleep 2
fi

# Start Anvil with Prague hardfork (enables BLS precompiles at 0x0b-0x13)
# No Sepolia fork = no re-org issues, independent chain
echo "Starting independent chain with Prague hardfork (BLS precompiles enabled)"

nohup anvil \
    --host 0.0.0.0 \
    --port $L1_PORT \
    --hardfork prague \
    --chain-id 900 \
    --gas-limit 30000000 \
    --code-size-limit 1000000 \
    > "$ANVIL_LOG" 2>&1 &

ANVIL_PID=$!
echo "Anvil PID: $ANVIL_PID"

# Wait for Anvil
echo "Waiting for Anvil to be ready..."
for i in {1..30}; do
    if cast block-number --rpc-url http://localhost:$L1_PORT &> /dev/null; then
        echo -e "${GREEN}Anvil is ready${NC}"
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
# Step 3: Deploy Optimism Contracts (via allocs)
# =============================================================================
echo -e "${YELLOW}Step 3: Deploying Optimism contracts...${NC}"

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

    echo -e "${GREEN}All $TOTAL Optimism contracts deployed${NC}"
else
    echo -e "${YELLOW}Optimism allocs not found, skipping${NC}"
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

echo -e "${GREEN}All $TOTAL contracts deployed${NC}"
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
    echo -e "${GREEN}TON contracts verified${NC}"
else
    echo -e "${RED}Warning: Contract verification failed${NC}"
    echo "  TON name: $TON_NAME"
    echo "  WTON name: $WTON_NAME"
fi
echo ""

# =============================================================================
# Step 5.5: Configure L1 SystemConfig Gas Scalars
# =============================================================================
echo -e "${YELLOW}Step 5.5: Configuring L1 SystemConfig gas scalars...${NC}"

SYSTEM_CONFIG=$(jq -r '.SystemConfigProxy // "0x0"' "$DEVNET_DIR/optimism-addresses.json" 2>/dev/null)

if [ "$SYSTEM_CONFIG" != "0x0" ] && [ -n "$SYSTEM_CONFIG" ]; then
    echo "  SystemConfig: $SYSTEM_CONFIG"
    echo "  Setting baseFeeScalar=1000 (0.1%), blobBaseFeeScalar=1000 (0.1%)..."

    # Set gas config using Ecotone format
    cast send "$SYSTEM_CONFIG" "setGasConfigEcotone(uint32,uint32)" 1000 1000 \
      --rpc-url "$RPC" \
      --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
      > /dev/null 2>&1

    # Verify update
    SCALAR=$(cast call "$SYSTEM_CONFIG" "scalar()(bytes32)" --rpc-url "$RPC" 2>/dev/null || echo "0x0")
    if [[ "$SCALAR" == *"03e8000003e8"* ]]; then
        echo -e "${GREEN}  L1 SystemConfig gas scalars updated${NC}"
    else
        echo -e "${YELLOW}  Warning: SystemConfig update may have failed${NC}"
        echo "    Expected: ...03e8000003e8"
        echo "    Got:      $SCALAR"
    fi
else
    echo -e "${YELLOW}  Warning: SystemConfig address not found, skipping${NC}"
fi
echo ""

# =============================================================================
# Step 5.6: Initialize Optimism Contracts for TON Staking V3
# (Must run BEFORE L2 services start, so proposer uses correct initBond)
# =============================================================================
echo -e "${YELLOW}Step 5.6: Initializing Optimism contracts for TON Staking V3...${NC}"

SEIG_MANAGER_PROXY=$(jq -r '.seigManagerProxy' "$DEVNET_DIR/addresses.json")
RAT_PROXY=$(jq -r '.ratProxy' "$DEVNET_DIR/addresses.json")
OPTIMISM_PORTAL=$(jq -r '.OptimismPortalProxy' "$DEVNET_DIR/optimism-addresses.json")
DISPUTE_GAME_FACTORY=$(jq -r '.DisputeGameFactoryProxy' "$DEVNET_DIR/optimism-addresses.json")
SYSTEM_CONFIG_ADDR=$(jq -r '.systemConfig' "$DEVNET_DIR/addresses.json")

# --- 5.6.1: OptimismPortal2.setSeigManager() ---
PORTAL_ADMIN_OWNER=$(cast call "$OPTIMISM_PORTAL" "proxyAdminOwner()(address)" --rpc-url "$RPC" 2>/dev/null | awk '{print $1}')
echo "  OptimismPortal proxyAdminOwner: $PORTAL_ADMIN_OWNER"

CURRENT_SEIG=$(cast call "$OPTIMISM_PORTAL" "seigManager()(address)" --rpc-url "$RPC" 2>/dev/null | awk '{print $1}')
if [ "$(echo "$CURRENT_SEIG" | tr '[:upper:]' '[:lower:]')" != "$(echo "$SEIG_MANAGER_PROXY" | tr '[:upper:]' '[:lower:]')" ]; then
    cast rpc anvil_impersonateAccount "$PORTAL_ADMIN_OWNER" --rpc-url "$RPC" > /dev/null 2>&1
    cast send "$OPTIMISM_PORTAL" "setSeigManager(address)" "$SEIG_MANAGER_PROXY" \
        --from "$PORTAL_ADMIN_OWNER" --rpc-url "$RPC" --unlocked > /dev/null 2>&1
    cast rpc anvil_stopImpersonatingAccount "$PORTAL_ADMIN_OWNER" --rpc-url "$RPC" > /dev/null 2>&1

    VERIFY_SEIG=$(cast call "$OPTIMISM_PORTAL" "seigManager()(address)" --rpc-url "$RPC" 2>/dev/null | awk '{print $1}')
    if [ "$(echo "$VERIFY_SEIG" | tr '[:upper:]' '[:lower:]')" = "$(echo "$SEIG_MANAGER_PROXY" | tr '[:upper:]' '[:lower:]')" ]; then
        echo -e "${GREEN}  OptimismPortal2.setSeigManager verified: $SEIG_MANAGER_PROXY${NC}"
    else
        echo -e "${RED}  OptimismPortal2.setSeigManager FAILED! Got: $VERIFY_SEIG${NC}"
    fi
else
    echo -e "${GREEN}  OptimismPortal2.setSeigManager already set, skipping${NC}"
fi

# --- 5.6.1b: OptimismPortal2.setRatContract() ---
CURRENT_RAT_PORTAL=$(cast call "$OPTIMISM_PORTAL" "ratContract()(address)" --rpc-url "$RPC" 2>/dev/null | awk '{print $1}')
if [ "$(echo "$CURRENT_RAT_PORTAL" | tr '[:upper:]' '[:lower:]')" != "$(echo "$RAT_PROXY" | tr '[:upper:]' '[:lower:]')" ]; then
    cast rpc anvil_impersonateAccount "$PORTAL_ADMIN_OWNER" --rpc-url "$RPC" > /dev/null 2>&1
    cast send "$OPTIMISM_PORTAL" "setRatContract(address)" "$RAT_PROXY" \
        --from "$PORTAL_ADMIN_OWNER" --rpc-url "$RPC" --unlocked > /dev/null 2>&1
    cast rpc anvil_stopImpersonatingAccount "$PORTAL_ADMIN_OWNER" --rpc-url "$RPC" > /dev/null 2>&1

    VERIFY_RAT_PORTAL=$(cast call "$OPTIMISM_PORTAL" "ratContract()(address)" --rpc-url "$RPC" 2>/dev/null | awk '{print $1}')
    if [ "$(echo "$VERIFY_RAT_PORTAL" | tr '[:upper:]' '[:lower:]')" = "$(echo "$RAT_PROXY" | tr '[:upper:]' '[:lower:]')" ]; then
        echo -e "${GREEN}  OptimismPortal2.setRatContract verified: $RAT_PROXY${NC}"
    else
        echo -e "${RED}  OptimismPortal2.setRatContract FAILED! Got: $VERIFY_RAT_PORTAL${NC}"
    fi
else
    echo -e "${GREEN}  OptimismPortal2.setRatContract already set, skipping${NC}"
fi

# --- 5.6.1c: OptimismPortal2.setFastWithdrawalResponsePeriod() ---
FW_RESPONSE_PERIOD=600  # 10 minutes
CURRENT_FW_PERIOD=$(cast call "$OPTIMISM_PORTAL" "fastWithdrawalResponsePeriod()(uint256)" --rpc-url "$RPC" 2>/dev/null | tr -d '[:space:]')
if [ "$CURRENT_FW_PERIOD" != "$FW_RESPONSE_PERIOD" ]; then
    cast rpc anvil_impersonateAccount "$PORTAL_ADMIN_OWNER" --rpc-url "$RPC" > /dev/null 2>&1
    cast send "$OPTIMISM_PORTAL" "setFastWithdrawalResponsePeriod(uint256)" "$FW_RESPONSE_PERIOD" \
        --from "$PORTAL_ADMIN_OWNER" --rpc-url "$RPC" --unlocked > /dev/null 2>&1
    cast rpc anvil_stopImpersonatingAccount "$PORTAL_ADMIN_OWNER" --rpc-url "$RPC" > /dev/null 2>&1

    VERIFY_FW_PERIOD=$(cast call "$OPTIMISM_PORTAL" "fastWithdrawalResponsePeriod()(uint256)" --rpc-url "$RPC" 2>/dev/null)
    echo -e "${GREEN}  OptimismPortal2.fastWithdrawalResponsePeriod set to ${VERIFY_FW_PERIOD}s${NC}"
else
    echo -e "${GREEN}  OptimismPortal2.fastWithdrawalResponsePeriod already set to ${FW_RESPONSE_PERIOD}s, skipping${NC}"
fi

# --- 5.6.1d: Verify Challenge Period Settings ---
echo ""
echo -e "${BLUE}  === Challenge Period Settings ===${NC}"
PROOF_MATURITY=$(cast call "$OPTIMISM_PORTAL" "proofMaturityDelaySeconds()(uint256)" --rpc-url "$RPC" 2>/dev/null | awk '{print $1}')
GAME_FINALITY=$(cast call "$OPTIMISM_PORTAL" "disputeGameFinalityDelaySeconds()(uint256)" --rpc-url "$RPC" 2>/dev/null | awk '{print $1}')
TOTAL_CHALLENGE=$((PROOF_MATURITY + GAME_FINALITY))
echo "  Proof Maturity Delay:        ${PROOF_MATURITY}s ($(echo "$PROOF_MATURITY / 60" | bc)m)"
echo "  Game Finality Delay:         ${GAME_FINALITY}s ($(echo "$GAME_FINALITY / 60" | bc)m)"
echo "  Total Challenge Period:      ${TOTAL_CHALLENGE}s ($(echo "$TOTAL_CHALLENGE / 60" | bc)m)"
echo "  FW Response Period:          ${FW_RESPONSE_PERIOD}s ($(echo "$FW_RESPONSE_PERIOD / 60" | bc)m)"
echo "  Evidence Submission Period:  600s (10m) [set in Step 13]"

# Validate constraints
if [ "$PROOF_MATURITY" -lt 600 ]; then
    echo -e "${RED}  WARNING: Proof Maturity Delay (${PROOF_MATURITY}s) < Evidence Submission Period (600s)${NC}"
    echo -e "${RED}  Withdrawals may finalize before evidence can be submitted!${NC}"
fi
if [ "$GAME_FINALITY" -lt 600 ]; then
    echo -e "${YELLOW}  NOTE: Game Finality Delay (${GAME_FINALITY}s) < Evidence Submission Period (600s)${NC}"
fi
echo ""

# --- 5.6.2: DisputeGameFactory.setRAT() ---
DGF_OWNER=$(cast call "$DISPUTE_GAME_FACTORY" "owner()(address)" --rpc-url "$RPC" 2>/dev/null | awk '{print $1}')
echo "  DisputeGameFactory owner: $DGF_OWNER"

CURRENT_DGF_RAT=$(cast call "$DISPUTE_GAME_FACTORY" "rat()(address)" --rpc-url "$RPC" 2>/dev/null | awk '{print $1}')
if [ "$(echo "$CURRENT_DGF_RAT" | tr '[:upper:]' '[:lower:]')" != "$(echo "$RAT_PROXY" | tr '[:upper:]' '[:lower:]')" ]; then
    cast rpc anvil_impersonateAccount "$DGF_OWNER" --rpc-url "$RPC" > /dev/null 2>&1
    cast send "$DISPUTE_GAME_FACTORY" "setRAT(address)" "$RAT_PROXY" \
        --from "$DGF_OWNER" --rpc-url "$RPC" --unlocked > /dev/null 2>&1
    cast rpc anvil_stopImpersonatingAccount "$DGF_OWNER" --rpc-url "$RPC" > /dev/null 2>&1

    VERIFY_RAT=$(cast call "$DISPUTE_GAME_FACTORY" "rat()(address)" --rpc-url "$RPC" 2>/dev/null | awk '{print $1}')
    if [ "$(echo "$VERIFY_RAT" | tr '[:upper:]' '[:lower:]')" = "$(echo "$RAT_PROXY" | tr '[:upper:]' '[:lower:]')" ]; then
        echo -e "${GREEN}  DisputeGameFactory.setRAT verified: $RAT_PROXY${NC}"
    else
        echo -e "${RED}  DisputeGameFactory.setRAT FAILED! Got: $VERIFY_RAT${NC}"
    fi
else
    echo -e "${GREEN}  DisputeGameFactory.setRAT already set, skipping${NC}"
fi

# --- 5.6.3: DisputeGameFactory.setSystemConfig() ---
CURRENT_DGF_SYSCONFIG=$(cast call "$DISPUTE_GAME_FACTORY" "systemConfig()(address)" --rpc-url "$RPC" 2>/dev/null | awk '{print $1}')
if [ "$(echo "$CURRENT_DGF_SYSCONFIG" | tr '[:upper:]' '[:lower:]')" != "$(echo "$SYSTEM_CONFIG_ADDR" | tr '[:upper:]' '[:lower:]')" ]; then
    cast rpc anvil_impersonateAccount "$DGF_OWNER" --rpc-url "$RPC" > /dev/null 2>&1
    cast send "$DISPUTE_GAME_FACTORY" "setSystemConfig(address)" "$SYSTEM_CONFIG_ADDR" \
        --from "$DGF_OWNER" --rpc-url "$RPC" --unlocked > /dev/null 2>&1
    cast rpc anvil_stopImpersonatingAccount "$DGF_OWNER" --rpc-url "$RPC" > /dev/null 2>&1

    VERIFY_SYSCONFIG=$(cast call "$DISPUTE_GAME_FACTORY" "systemConfig()(address)" --rpc-url "$RPC" 2>/dev/null | awk '{print $1}')
    if [ "$(echo "$VERIFY_SYSCONFIG" | tr '[:upper:]' '[:lower:]')" = "$(echo "$SYSTEM_CONFIG_ADDR" | tr '[:upper:]' '[:lower:]')" ]; then
        echo -e "${GREEN}  DisputeGameFactory.setSystemConfig verified: $SYSTEM_CONFIG_ADDR${NC}"
    else
        echo -e "${RED}  DisputeGameFactory.setSystemConfig FAILED! Got: $VERIFY_SYSCONFIG${NC}"
    fi
else
    echo -e "${GREEN}  DisputeGameFactory.setSystemConfig already set, skipping${NC}"
fi

# --- 5.6.4: DisputeGameFactory.setInitBond() ---
# 0.0025 ETH (~10,000 KRW @ 1 ETH = 4,000,000 KRW)
INIT_BOND_WEI="2500000000000000"
CURRENT_INIT_BOND=$(cast call "$DISPUTE_GAME_FACTORY" "initBonds(uint32)(uint256)" 0 --rpc-url "$RPC" 2>/dev/null | tr -d '[:space:]')
if [ "$CURRENT_INIT_BOND" != "$INIT_BOND_WEI" ] && ! echo "$CURRENT_INIT_BOND" | grep -q "2500000000000000"; then
    cast rpc anvil_impersonateAccount "$DGF_OWNER" --rpc-url "$RPC" > /dev/null 2>&1
    cast send "$DISPUTE_GAME_FACTORY" "setInitBond(uint32,uint256)" 0 "$INIT_BOND_WEI" \
        --from "$DGF_OWNER" --rpc-url "$RPC" --unlocked > /dev/null 2>&1
    cast rpc anvil_stopImpersonatingAccount "$DGF_OWNER" --rpc-url "$RPC" > /dev/null 2>&1

    VERIFY_INIT_BOND=$(cast call "$DISPUTE_GAME_FACTORY" "initBonds(uint32)(uint256)" 0 --rpc-url "$RPC" 2>/dev/null)
    if [ "$VERIFY_INIT_BOND" = "$INIT_BOND_WEI" ] || echo "$VERIFY_INIT_BOND" | grep -q "2500000000000000"; then
        echo -e "${GREEN}  DisputeGameFactory.setInitBond verified: 0.0025 ETH (gameType 0)${NC}"
    else
        echo -e "${RED}  DisputeGameFactory.setInitBond FAILED! Got: $VERIFY_INIT_BOND (expected: $INIT_BOND_WEI)${NC}"
    fi
else
    echo -e "${GREEN}  DisputeGameFactory.setInitBond already set to 0.0025 ETH, skipping${NC}"
fi

# --- 5.6.5: AnchorStateRegistry.setRespectedGameType(0) ---
# Must be called by Guardian (Anvil Account #0) before any dispute game is created (op-proposer).
ANCHOR_STATE_REGISTRY=$(cast call "$OPTIMISM_PORTAL" "anchorStateRegistry()(address)" --rpc-url "$RPC" 2>/dev/null | awk '{print $1}')
GUARDIAN_ADDR="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
if [ -n "$ANCHOR_STATE_REGISTRY" ] && [ "$(echo "$ANCHOR_STATE_REGISTRY" | tr '[:upper:]' '[:lower:]')" != "0x0000000000000000000000000000000000000000" ]; then
    CURRENT_GAME_TYPE=$(cast call "$ANCHOR_STATE_REGISTRY" "respectedGameType()(uint32)" --rpc-url "$RPC" 2>/dev/null | tr -d '[:space:]')
    if [ "$CURRENT_GAME_TYPE" != "0" ]; then
        cast rpc anvil_impersonateAccount "$GUARDIAN_ADDR" --rpc-url "$RPC" > /dev/null 2>&1
        if cast send "$ANCHOR_STATE_REGISTRY" "setRespectedGameType(uint32)" 0 \
            --from "$GUARDIAN_ADDR" --rpc-url "$RPC" --unlocked > /dev/null 2>&1; then
            echo -e "${GREEN}  AnchorStateRegistry.setRespectedGameType(0) verified (Guardian = Anvil #0)${NC}"
        else
            echo -e "${RED}  AnchorStateRegistry.setRespectedGameType(0) FAILED! Ensure Guardian is 0xf39Fd6...${NC}"
        fi
        cast rpc anvil_stopImpersonatingAccount "$GUARDIAN_ADDR" --rpc-url "$RPC" > /dev/null 2>&1
    else
        echo -e "${GREEN}  AnchorStateRegistry.setRespectedGameType already set to 0, skipping${NC}"
    fi
else
    echo -e "${YELLOW}  Skipping AnchorStateRegistry.setRespectedGameType (OptimismPortal2.anchorStateRegistry not found)${NC}"
fi

echo ""

# =============================================================================
# Step 6: Setup L2 configuration
# =============================================================================
echo -e "${YELLOW}Step 6: Setting up L2 configuration...${NC}"

# Check for old L2 data and warn user
if [ -d "$DEVNET_SEPOLIA_DIR" ]; then
    echo -e "${YELLOW}Warning: Old L2 configuration detected${NC}"
    echo "  Previous run data exists at: $DEVNET_SEPOLIA_DIR"
    echo ""
    echo "  To ensure clean initialization with correct genesis:"
    echo "  - Old data will be removed"
    echo "  - L2 volumes will be deleted in Step 7"
    echo ""
    if [ -t 0 ]; then
        read -p "Continue with cleanup? [Y/n] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
            echo "Aborted. Please run ./scripts/local/stop-dev-fw.sh first."
            exit 1
        fi
    else
        echo "  Non-interactive mode: auto-cleaning old data"
    fi
    rm -rf "$DEVNET_SEPOLIA_DIR"
    echo -e "${GREEN}Old configuration removed${NC}"
    echo ""
fi

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

# Generate or use L2 genesis with predeploys
if [ -f "$DEVNET_DIR/genesis-l2.json" ]; then
    echo "Using existing L2 genesis with predeploys..."

    # Verify genesis file is valid
    echo "  Verifying genesis file..."
    FACTORY_CODE_IN_GENESIS=$(jq -r '.alloc["0x4200000000000000000000000000000000000012"].code // "0x"' "$DEVNET_DIR/genesis-l2.json")
    PREDEPLOY_COUNT=$(jq '[.alloc | keys[] | select(startswith("0x4200"))] | length' "$DEVNET_DIR/genesis-l2.json")

    if [ "$FACTORY_CODE_IN_GENESIS" = "0x" ] || [ ${#FACTORY_CODE_IN_GENESIS} -lt 100 ]; then
        echo -e "${RED}Error: Genesis file is invalid or corrupted${NC}"
        echo "  OptimismMintableERC20Factory code is missing"
        echo "  Please regenerate genesis with:"
        echo "    ./scripts/generate-optimism-allocs-new.sh"
        echo "    cp scripts/config/genesis-l2-optimism.json .devnet/genesis-l2.json"
        exit 1
    fi

    if [ $PREDEPLOY_COUNT -lt 2000 ]; then
        echo -e "${RED}Error: Genesis file has insufficient predeploys${NC}"
        echo "  Found: $PREDEPLOY_COUNT (expected: 2048)"
        echo "  Please regenerate genesis with:"
        echo "    ./scripts/generate-optimism-allocs-new.sh"
        echo "    cp scripts/config/genesis-l2-optimism.json .devnet/genesis-l2.json"
        exit 1
    fi

    echo -e "${GREEN}  Genesis file validated ($PREDEPLOY_COUNT predeploys)${NC}"

    cp "$DEVNET_DIR/genesis-l2.json" "$DEVNET_SEPOLIA_DIR/genesis-l2.json"

    # Update timestamp
    L2_TIME_HEX=$(printf "0x%x" $L2_TIME)
    jq --arg ts "$L2_TIME_HEX" '.timestamp = $ts' "$DEVNET_SEPOLIA_DIR/genesis-l2.json" > /tmp/genesis-l2-updated.json
    mv /tmp/genesis-l2-updated.json "$DEVNET_SEPOLIA_DIR/genesis-l2.json"

    # =============================================================================
    # Fix L2 Predeploy Bridge Addresses (CRITICAL for L1<->L2 bridging)
    # =============================================================================
    echo "  Fixing L2 predeploy bridge addresses..."

    # Get L1 addresses from optimism-addresses.json
    L1_CROSS_DOMAIN_MESSENGER=$(jq -r '.L1CrossDomainMessengerProxy // "0x0000000000000000000000000000000000000000"' "$DEVNET_DIR/optimism-addresses.json" 2>/dev/null)
    L1_STANDARD_BRIDGE=$(jq -r '.L1StandardBridgeProxy // "0x0000000000000000000000000000000000000000"' "$DEVNET_DIR/optimism-addresses.json" 2>/dev/null)

    # Fix L2CrossDomainMessenger otherMessenger (storage slot 0xcf)
    if [ "$L1_CROSS_DOMAIN_MESSENGER" != "0x0000000000000000000000000000000000000000" ]; then
        MESSENGER_VALUE=$(printf "0x%064s" $(echo $L1_CROSS_DOMAIN_MESSENGER | sed 's/0x//') | tr ' ' '0')
        jq --arg slot "0x00000000000000000000000000000000000000000000000000000000000000cf" \
           --arg value "$MESSENGER_VALUE" \
           '.alloc["0x4200000000000000000000000000000000000007"].storage[$slot] = $value' \
           "$DEVNET_SEPOLIA_DIR/genesis-l2.json" > /tmp/genesis-l2-fixed.json
        mv /tmp/genesis-l2-fixed.json "$DEVNET_SEPOLIA_DIR/genesis-l2.json"
        echo "    L2CrossDomainMessenger.otherMessenger = $L1_CROSS_DOMAIN_MESSENGER"
    fi

    # Fix L2StandardBridge otherBridge (storage slot 4)
    if [ "$L1_STANDARD_BRIDGE" != "0x0000000000000000000000000000000000000000" ]; then
        BRIDGE_VALUE=$(printf "0x%064s" $(echo $L1_STANDARD_BRIDGE | sed 's/0x//') | tr ' ' '0')
        jq --arg slot "0x0000000000000000000000000000000000000000000000000000000000000004" \
           --arg value "$BRIDGE_VALUE" \
           '.alloc["0x4200000000000000000000000000000000000010"].storage[$slot] = $value' \
           "$DEVNET_SEPOLIA_DIR/genesis-l2.json" > /tmp/genesis-l2-fixed.json
        mv /tmp/genesis-l2-fixed.json "$DEVNET_SEPOLIA_DIR/genesis-l2.json"
        echo "    L2StandardBridge.otherBridge = $L1_STANDARD_BRIDGE"
    fi

    echo -e "${GREEN}  L2 bridge addresses fixed${NC}"

    # =============================================================================
    # Fix L1Block Fee Scalars (prevent rollup cost overflow)
    # =============================================================================
    echo "  Fixing L1Block fee scalars..."

    # Set fee scalars for local devnet (low fees)
    # baseFeeScalar = 1000 (0.1%)
    # blobBaseFeeScalar = 1000 (0.1%)
    # l1FeeScalar = 1000 (0.1%)

    jq '.alloc["0x4200000000000000000000000000000000000015"].storage += {
      "0x0000000000000000000000000000000000000000000000000000000000000003": "0x00000000000000000000000000000000000000000000000000000000000003e8",
      "0x0000000000000000000000000000000000000000000000000000000000000005": "0x000000000000000000000000000000000000000000000000000003e8000003e8"
    }' "$DEVNET_SEPOLIA_DIR/genesis-l2.json" > /tmp/genesis-l2-l1block-fixed.json
    mv /tmp/genesis-l2-l1block-fixed.json "$DEVNET_SEPOLIA_DIR/genesis-l2.json"
    echo -e "${GREEN}    L1Block fee scalars set (baseFee: 0.1%, blobBaseFee: 0.1%)${NC}"

    # Verify predeploys exist
    PREDEPLOY_COUNT=$(jq '[.alloc | keys[] | select(startswith("0x4200"))] | length' "$DEVNET_SEPOLIA_DIR/genesis-l2.json")
    echo "  Predeploy contracts: $PREDEPLOY_COUNT"
else
    echo -e "${RED}Error: L2 genesis with predeploys not found${NC}"
    echo "Please run: ./scripts/generate-l2-genesis.sh"
    exit 1
fi

# Use pre-generated rollup.json or create new one if not exists
if [ -f "$DEVNET_DIR/rollup.json" ]; then
    echo "Using pre-generated rollup.json from generate-optimism-allocs.sh"
    cp "$DEVNET_DIR/rollup.json" "$DEVNET_SEPOLIA_DIR/rollup.json"

    # Update L1 genesis info with current Anvil block
    jq --arg hash "$L1_BLOCK_HASH" \
       --argjson num "$L1_BLOCK_NUM" \
       --argjson time "$L2_TIME" \
       '.genesis.l1.hash = $hash |
        .genesis.l1.number = $num |
        .genesis.l2_time = $time' \
       "$DEVNET_SEPOLIA_DIR/rollup.json" > /tmp/rollup.json.tmp
    mv /tmp/rollup.json.tmp "$DEVNET_SEPOLIA_DIR/rollup.json"

    echo -e "${GREEN}Rollup config updated with L1 genesis block${NC}"
else
    echo -e "${YELLOW}Warning: Pre-generated rollup.json not found${NC}"
    echo "Creating rollup.json from scratch..."

    # Fallback: Create rollup.json from scratch
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
  "deposit_contract_address": "${OPTIMISM_PORTAL:-0xbF6531954Aa355f478e54fEDff94D9D9E7008D79}",
  "l1_system_config_address": "${SYSTEM_CONFIG:-0x577AcB7fA48878245a854ba51eD051a5B47cF83f}"
}
EOF
    echo -e "${GREEN}L2 configuration created${NC}"
fi
echo ""

# Note: L1 (Anvil) uses automine by default - blocks are mined instantly
# when transactions are submitted. Do NOT use anvil_setIntervalMining as it
# re-seals existing blocks, changing hashes, which op-node detects as L1 re-orgs.

# =============================================================================
# Step 7: Start L2 services
# =============================================================================
echo -e "${YELLOW}Step 7: Starting L2 services (Docker)...${NC}"

# Stop existing L2 containers and remove volumes (clean start)
echo "Cleaning up existing L2 data..."
docker compose -f "$COMPOSE_FILE" down -v 2>/dev/null || true
sleep 2

# Start op-geth first
docker compose -f "$COMPOSE_FILE" up -d l2-execution

echo "Waiting for op-geth..."
for i in {1..30}; do
    if cast block-number --rpc-url http://localhost:9545 &> /dev/null; then
        echo -e "${GREEN}op-geth is ready${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}Error: op-geth failed to start${NC}"
        docker logs ton-staking-l2-execution
        exit 1
    fi
    sleep 2
done

# Verify predeploy contracts are loaded
echo "Verifying predeploy contracts..."
L2_FACTORY="0x4200000000000000000000000000000000000012"
FACTORY_CODE=$(cast code "$L2_FACTORY" --rpc-url http://localhost:9545 2>/dev/null || echo "0x")
if [ "$FACTORY_CODE" = "0x" ] || [ ${#FACTORY_CODE} -lt 10 ]; then
    echo -e "${RED}Error: Predeploy contracts not loaded properly${NC}"
    echo "Factory code length: ${#FACTORY_CODE}"
    echo "This indicates genesis was not loaded correctly."
    docker logs ton-staking-l2-execution | tail -50
    exit 1
fi
echo -e "${GREEN}Predeploy contracts verified${NC}"

# CRITICAL: Verify L1Block fee scalars to prevent rollup cost overflow
echo "Verifying L1Block fee scalars..."
L1_BLOCK_ADDR="0x4200000000000000000000000000000000000015"
SLOT3_VALUE=$(cast storage "$L1_BLOCK_ADDR" 3 --rpc-url http://localhost:9545 2>/dev/null || echo "0x0")
SLOT5_VALUE=$(cast storage "$L1_BLOCK_ADDR" 5 --rpc-url http://localhost:9545 2>/dev/null || echo "0x0")

# Expected values (1000 = 0x3e8)
EXPECTED_SLOT3="0x00000000000000000000000000000000000000000000000000000000000003e8"
EXPECTED_SLOT5="0x000000000000000000000000000000000000000000000000000003e8000003e8"

if [ "$SLOT3_VALUE" != "$EXPECTED_SLOT3" ]; then
    echo -e "${RED}ERROR: L1Block slot 3 (l1FeeScalar) has wrong value!${NC}"
    echo "  Expected: $EXPECTED_SLOT3"
    echo "  Got:      $SLOT3_VALUE"
    echo ""
    echo "This will cause 'overflow in total rollup cost' errors!"
    echo "Genesis was not loaded correctly. Stopping L2..."
    docker compose -f "$COMPOSE_FILE" down
    exit 1
fi

if [ "$SLOT5_VALUE" != "$EXPECTED_SLOT5" ]; then
    echo -e "${RED}ERROR: L1Block slot 5 (Ecotone scalars) has wrong value!${NC}"
    echo "  Expected: $EXPECTED_SLOT5"
    echo "  Got:      $SLOT5_VALUE"
    echo ""
    echo "This will cause 'overflow in total rollup cost' errors!"
    echo "Genesis was not loaded correctly. Stopping L2..."
    docker compose -f "$COMPOSE_FILE" down
    exit 1
fi

echo -e "${GREEN}L1Block fee scalars verified (baseFee: 0.1%, blobBaseFee: 0.1%)${NC}"

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
        echo -e "${GREEN}op-node is ready${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${YELLOW}Warning: op-node healthcheck timeout, continuing...${NC}"
    fi
    sleep 2
done

# Start batcher and proposer
echo "Starting batcher and proposer..."
# Export DisputeGameFactory address for docker-compose env substitution
export DISPUTE_GAME_FACTORY_ADDRESS=$(jq -r '.DisputeGameFactoryProxy' "$DEVNET_DIR/optimism-addresses.json" 2>/dev/null)
echo "  DisputeGameFactory: $DISPUTE_GAME_FACTORY_ADDRESS"
docker compose -f "$COMPOSE_FILE" up -d l2-batcher l2-proposer
echo -e "${GREEN}Batcher and proposer started${NC}"

# =============================================================================
# Step 8: Build and start RAT clients + FW services
# =============================================================================
echo -e "${YELLOW}Step 8: Building and starting RAT clients + FW services...${NC}"

# Images already pre-built in Step 1.5 (before Anvil started)
# Start RAT clients (FW services start later after config is generated)
echo "Starting RAT clients..."
docker compose -f "$COMPOSE_FILE" up -d rat-client-1 rat-client-2 rat-client-3
echo -e "${GREEN}RAT clients started (3 validators)${NC}"
echo ""

# Wait for L2 transaction indexing to complete
echo ""
echo -e "${YELLOW}Waiting for L2 transaction indexing to complete...${NC}"
echo "  This may take up to 2 minutes on first startup."
echo "  L2 needs to index transactions before accepting new ones."
L2_RPC_CHECK="http://localhost:9545"
for i in {1..60}; do
    # Try a simple eth_call to check if indexing is ready
    if cast call "0x4200000000000000000000000000000000000012" "deployments(address)(address)" "0x0000000000000000000000000000000000000001" --rpc-url "$L2_RPC_CHECK" &> /dev/null; then
        echo ""
        echo -e "${GREEN}L2 transaction indexing complete${NC}"
        break
    fi
    if [ $i -eq 60 ]; then
        echo ""
        echo -e "${YELLOW}Warning: L2 indexing check timeout (2 min), continuing anyway...${NC}"
    fi
    if [ $((i % 10)) -eq 0 ]; then
        echo "  Still waiting for indexing... ($((i*2))s elapsed)"
    fi
    sleep 2
done
echo ""

# =============================================================================
# Step 9: Bridge ETH from L1 to L2 (for gas fees)
# =============================================================================
echo -e "${YELLOW}Step 9: Bridging ETH from L1 to L2...${NC}"

# Get OptimismPortal address (this is what op-node monitors for deposits)
OPTIMISM_PORTAL=$(jq -r '.OptimismPortalProxy // "0x0000000000000000000000000000000000000000"' "$DEVNET_DIR/optimism-addresses.json" 2>/dev/null)
L2_RPC="http://localhost:9545"

if [ "$OPTIMISM_PORTAL" = "0x0000000000000000000000000000000000000000" ]; then
    echo -e "${RED}Error: OptimismPortal address not found${NC}"
    exit 1
fi

# Deployer account (needs L2 ETH for gas)
DEPLOYER_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
DEPLOYER_ADDR="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

echo "  Depositing 10 ETH from L1 to L2 for deployer account..."
echo "  OptimismPortal: $OPTIMISM_PORTAL"
echo "  Target L2 address: $DEPLOYER_ADDR"

# Deposit ETH via OptimismPortal (directly)
# function depositTransaction(address _to, uint256 _value, uint64 _gasLimit, bool _isCreation, bytes memory _data)
DEPOSIT_VALUE="10000000000000000000"  # 10 ETH in wei
if cast send "$OPTIMISM_PORTAL" \
    "depositTransaction(address,uint256,uint64,bool,bytes)" \
    "$DEPLOYER_ADDR" \
    "$DEPOSIT_VALUE" \
    200000 \
    false \
    "0x" \
    --value "10ether" \
    --private-key "$DEPLOYER_KEY" \
    --rpc-url "$RPC" \
    --gas-limit 300000 > /dev/null 2>&1; then
    echo -e "${GREEN}  ETH deposit transaction sent via OptimismPortal${NC}"
else
    echo -e "${YELLOW}  ETH deposit may have failed, continuing...${NC}"
fi

# Wait for L1 to mine the deposit transaction
echo "  Waiting for L1 to mine deposit transaction..."
sleep $((L1_BLOCK_TIME + 2))

# Wait for L2 to process the deposit (op-node needs to relay it)
echo "  Waiting for L2 to process deposit..."
echo "  This may take 30-60 seconds for op-node to relay the deposit to L2"
for i in {1..30}; do
    L2_BALANCE=$(cast balance "$DEPLOYER_ADDR" --rpc-url "$L2_RPC" 2>/dev/null || echo "0")

    # Use bc for comparison to avoid bash integer overflow (ETH wei values exceed int64)
    if [ "$L2_BALANCE" != "0" ] && [ "$(echo "$L2_BALANCE > 1000000000000000000" | bc)" -eq 1 ]; then
        L2_BALANCE_ETH=$(echo "scale=4; $L2_BALANCE / 1000000000000000000" | bc)
        echo -e "${GREEN}  L2 ETH received: ${L2_BALANCE_ETH} ETH${NC}"
        break
    fi

    if [ $i -eq 30 ]; then
        # Still show balance for debugging (may overflow in bash but bc handles it)
        L2_BALANCE_ETH=$(echo "scale=4; $L2_BALANCE / 1000000000000000000" | bc 2>/dev/null || echo "0")
        echo -e "${YELLOW}  Warning: L2 ETH not detected after 60s${NC}"
        echo "  L2 balance: ${L2_BALANCE_ETH} ETH (${L2_BALANCE} wei)"
        echo "  Continuing anyway - deposit may still be processing..."
    fi

    if [ $((i % 5)) -eq 0 ]; then
        echo "  Still waiting for deposit... (${i}0s elapsed)"
    fi
    sleep 2
done
echo ""

# =============================================================================
# Step 10: Deploy L2 TON Token (OptimismMintableERC20)
# =============================================================================
echo -e "${YELLOW}Step 10: Deploying L2 TON token...${NC}"

L1_TON_ADDR=$(jq -r '.ton' "$DEVNET_DIR/addresses.json")
L2_TOKEN_FACTORY="0x4200000000000000000000000000000000000012"
DEPLOYER_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

# Wait for L2 to be fully ready (including tx indexing)
echo "  Waiting for L2 RPC to be fully ready..."
L2_READY=false
for i in {1..30}; do
    if cast block-number --rpc-url "$L2_RPC" &> /dev/null; then
        # Verify factory has code
        FACTORY_CODE=$(cast code "$L2_TOKEN_FACTORY" --rpc-url "$L2_RPC" 2>/dev/null || echo "0x")
        if [ "$FACTORY_CODE" != "0x" ] && [ ${#FACTORY_CODE} -gt 10 ]; then
            # Also check if tx indexing is complete by trying a simple call
            if cast call "$L2_TOKEN_FACTORY" "deployments(address)(address)" "0x0000000000000000000000000000000000000001" --rpc-url "$L2_RPC" &> /dev/null; then
                echo "  L2 RPC ready (factory verified)"
                L2_READY=true
                break
            fi
        fi
    fi
    if [ $i -eq 30 ]; then
        echo -e "${YELLOW}  Warning: L2 may not be fully ready${NC}"
    fi
    sleep 2
done

if [ "$L2_READY" = false ]; then
    echo -e "${RED}Error: L2 is not ready for transactions${NC}"
    echo "Factory code check failed or RPC not responding"
    exit 1
fi

# Check if L2 TON already exists by looking for past deployment events
echo "  Checking for existing L2 TON token..."
# Convert L1 TON address to lowercase and pad to 32 bytes (64 hex chars)
L1_TON_LOWER=$(echo "$L1_TON_ADDR" | tr '[:upper:]' '[:lower:]')
L1_TON_PADDED=$(printf "0x%064s" "${L1_TON_LOWER#0x}" | tr ' ' '0')

EXISTING_L2_TON=$(cast logs \
    --from-block 0 \
    --address "$L2_TOKEN_FACTORY" \
    "OptimismMintableERC20Created(address indexed,address indexed,address)" \
    --rpc-url "$L2_RPC" \
    --json 2>/dev/null | jq -r --arg l1ton "$L1_TON_PADDED" \
    '.[] | select(.topics[2] == $l1ton) | .topics[1]' | head -1)

if [ -n "$EXISTING_L2_TON" ] && [ "$EXISTING_L2_TON" != "null" ]; then
    L2_TON_ADDR="0x${EXISTING_L2_TON:26}"
    echo -e "${GREEN}  L2 TON already exists: $L2_TON_ADDR${NC}"
else
    echo "  Creating L2 TON token via OptimismMintableERC20Factory..."

    # Retry up to 5 times with longer delays
    DEPLOY_SUCCESS=false
    for attempt in {1..5}; do
        echo "    Attempt $attempt/5..."

        # Try to deploy with explicit gas limit
        DEPLOY_OUTPUT=$(cast send "$L2_TOKEN_FACTORY" \
            "createOptimismMintableERC20(address,string,string)" \
            "$L1_TON_ADDR" "Tokamak Network" "TON" \
            --rpc-url "$L2_RPC" \
            --private-key "$DEPLOYER_KEY" \
            --gas-limit 2000000 2>&1)

        if [ $? -eq 0 ]; then
            # Wait for transaction to be mined
            sleep 5

            # Check for deployment event directly (no need to parse TX hash)
            # Query recent blocks for OptimismMintableERC20Created event
            CURRENT_BLOCK=$(cast block-number --rpc-url "$L2_RPC" 2>/dev/null)
            START_BLOCK=$((CURRENT_BLOCK - 10))

            L2_TON_FROM_EVENT=$(timeout 10 cast logs \
                --from-block "$START_BLOCK" \
                --address "$L2_TOKEN_FACTORY" \
                "OptimismMintableERC20Created(address indexed,address indexed,address)" \
                --rpc-url "$L2_RPC" \
                --json 2>/dev/null | jq -r --arg l1ton "$L1_TON_PADDED" \
                '.[] | select(.topics[2] == $l1ton) | .topics[1]' | tail -1)

            if [ -n "$L2_TON_FROM_EVENT" ] && [ "$L2_TON_FROM_EVENT" != "null" ]; then
                L2_TON_ADDR="0x${L2_TON_FROM_EVENT:26}"
                echo -e "${GREEN}  L2 TON deployed: $L2_TON_ADDR (from event)${NC}"
                DEPLOY_SUCCESS=true
                break
            else
                echo "    Event not found yet, will retry..."
            fi

        else
            echo "    Deploy failed: $(echo "$DEPLOY_OUTPUT" | tail -1)"
        fi

        if [ $attempt -lt 5 ]; then
            echo "    Waiting 10 seconds before retry..."
            sleep 10
        fi
    done

    if [ "$DEPLOY_SUCCESS" = false ]; then
        echo -e "${RED}  Failed to deploy L2 TON after 5 attempts${NC}"
        echo "  Check L2 logs: docker logs ton-staking-l2-execution"
        L2_TON_ADDR="0x0000000000000000000000000000000000000000"
    fi
fi

# Save L2 TON address
jq --arg l2ton "$L2_TON_ADDR" '. + {l2Ton: $l2ton}' "$DEVNET_DIR/addresses.json" > /tmp/addresses-updated.json
mv /tmp/addresses-updated.json "$DEVNET_DIR/addresses.json"
echo ""

# =============================================================================
# Step 11: Register L2 in TON Staking System
# =============================================================================
echo -e "${YELLOW}Step 11: Registering L2 in TON Staking system...${NC}"

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

# Minimum staking amount (1001 TON in 18 decimals)
MIN_STAKE="1001000000000000000000"

# --- Step 11.1: Check if rollup types are registered ---
echo "  Checking rollup type registration..."
TYPE3_BRIDGE_GETTER=$(cast call "$L1_BRIDGE_REGISTRY" "rollupTypeConfig(uint8)(bytes4,bytes4,bytes4,bytes4,uint8,string,bool)" 3 --rpc-url "$RPC" 2>/dev/null | head -1 || echo "")

# Desired configuration for Type 3
DESIRED_BRIDGE_GETTER="0x078f29cf"     # l1StandardBridge()
DESIRED_TVL_GETTER="0x078f29cf"        # l1StandardBridge() - TON is ERC20 so locked in bridge
DESIRED_DISPUTE_GETTER="0xf2b4e617"    # disputeGameFactory()
DESIRED_SEIGNOTIFIER_GETTER="0x0a49cb03"        # optimismPortal()
DESIRED_BRIDGE_PATTERN="0"                        # BRIDGE_PATTERN_ERC20

if [ -z "$TYPE3_BRIDGE_GETTER" ] || [ "$TYPE3_BRIDGE_GETTER" = "0x00000000" ]; then
    echo "  Registering rollup types..."

    # Add manager if not already
    cast send "$L1_BRIDGE_REGISTRY" "addManager(address)" "$MANAGER_ADDR" \
        --private-key "$MANAGER_KEY" --rpc-url "$RPC" > /dev/null 2>&1 || true

    # Type 1: Optimism Legacy
    cast send "$L1_BRIDGE_REGISTRY" \
        "addRollupType(uint8,string,bytes4,bytes4,bytes4,bytes4,uint8,bool)" \
        1 "Optimism Legacy" 0x078f29cf 0x078f29cf 0x00000000 0x00000000 0 false \
        --private-key "$MANAGER_KEY" --rpc-url "$RPC" > /dev/null 2>&1 || true

    # Type 2: Optimism Bedrock
    cast send "$L1_BRIDGE_REGISTRY" \
        "addRollupType(uint8,string,bytes4,bytes4,bytes4,bytes4,uint8,bool)" \
        2 "Optimism Bedrock" 0x078f29cf 0x0a49cb03 0x00000000 0x00000000 0 false \
        --private-key "$MANAGER_KEY" --rpc-url "$RPC" > /dev/null 2>&1 || true

    # Type 3: Optimism Bedrock DisputeGame (V3 eligible)
    cast send "$L1_BRIDGE_REGISTRY" \
        "addRollupType(uint8,string,bytes4,bytes4,bytes4,bytes4,uint8,bool)" \
        3 "Optimism Bedrock DisputeGame" "$DESIRED_BRIDGE_GETTER" "$DESIRED_TVL_GETTER" "$DESIRED_DISPUTE_GETTER" "$DESIRED_SEIGNOTIFIER_GETTER" "$DESIRED_BRIDGE_PATTERN" true \
        --private-key "$MANAGER_KEY" --rpc-url "$RPC" > /dev/null 2>&1 || true

    echo -e "${GREEN}  Rollup types registered${NC}"
else
    echo -e "${GREEN}  Rollup types already registered${NC}"

    # Check if Type 3 configuration matches desired values
    echo "  Verifying Type 3 configuration..."
    CURRENT_CONFIG=$(cast call "$L1_BRIDGE_REGISTRY" "rollupTypeConfig(uint8)(bytes4,bytes4,bytes4,bytes4,uint8,string,bool)" 3 --rpc-url "$RPC" 2>/dev/null)
    CURRENT_BRIDGE_GETTER=$(echo "$CURRENT_CONFIG" | sed -n '1p' | tr -d '[:space:]')
    CURRENT_TVL_GETTER=$(echo "$CURRENT_CONFIG" | sed -n '2p' | tr -d '[:space:]')
    CURRENT_DISPUTE_GETTER=$(echo "$CURRENT_CONFIG" | sed -n '3p' | tr -d '[:space:]')
    CURRENT_SEIGNOTIFIER_GETTER=$(echo "$CURRENT_CONFIG" | sed -n '4p' | tr -d '[:space:]')
    CURRENT_BRIDGE_PATTERN=$(echo "$CURRENT_CONFIG" | sed -n '5p' | tr -d '[:space:]')

    if [ "$CURRENT_BRIDGE_GETTER" != "$DESIRED_BRIDGE_GETTER" ] || \
       [ "$CURRENT_TVL_GETTER" != "$DESIRED_TVL_GETTER" ] || \
       [ "$CURRENT_DISPUTE_GETTER" != "$DESIRED_DISPUTE_GETTER" ] || \
       [ "$CURRENT_SEIGNOTIFIER_GETTER" != "$DESIRED_SEIGNOTIFIER_GETTER" ] || \
       [ "$CURRENT_BRIDGE_PATTERN" != "$DESIRED_BRIDGE_PATTERN" ]; then
        echo -e "${YELLOW}  Type 3 configuration mismatch detected${NC}"
        echo "    Current: bridge=$CURRENT_BRIDGE_GETTER, tvl=$CURRENT_TVL_GETTER, dispute=$CURRENT_DISPUTE_GETTER, seigNotifier=$CURRENT_SEIGNOTIFIER_GETTER, pattern=$CURRENT_BRIDGE_PATTERN"
        echo "    Desired: bridge=$DESIRED_BRIDGE_GETTER, tvl=$DESIRED_TVL_GETTER, dispute=$DESIRED_DISPUTE_GETTER, seigNotifier=$DESIRED_SEIGNOTIFIER_GETTER, pattern=$DESIRED_BRIDGE_PATTERN"
        echo "  Updating Type 3 configuration..."

        # Update rollup type configuration
        cast send "$L1_BRIDGE_REGISTRY" \
            "updateRollupType(uint8,string,bytes4,bytes4,bytes4,bytes4,uint8,bool)" \
            3 "Optimism Bedrock DisputeGame" "$DESIRED_BRIDGE_GETTER" "$DESIRED_TVL_GETTER" "$DESIRED_DISPUTE_GETTER" "$DESIRED_SEIGNOTIFIER_GETTER" "$DESIRED_BRIDGE_PATTERN" true \
            --private-key "$MANAGER_KEY" --rpc-url "$RPC" > /dev/null 2>&1

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}  Type 3 configuration updated${NC}"
        else
            echo -e "${YELLOW}  Failed to update Type 3 configuration (may not have updateRollupType function)${NC}"
        fi
    else
        echo -e "${GREEN}  Type 3 configuration is correct${NC}"
    fi
fi

# --- Step 11.2: Register Rollup Config to L1BridgeRegistry ---
echo "  Checking rollup config registration..."
ROLLUP_INFO=$(cast call "$L1_BRIDGE_REGISTRY" "getRollupInfo(address)(uint8,address,bool,bool,string)" "$SYSTEM_CONFIG_ADDR" --rpc-url "$RPC" 2>/dev/null || echo "0")
ROLLUP_TYPE=$(echo "$ROLLUP_INFO" | head -1)

if [ "$ROLLUP_TYPE" = "0" ]; then
    echo "  Registering rollup config (Type 3)..."
    # Get L2 TON address from Step 10
    L2_TON_FOR_REGISTRY=$(jq -r '.l2Ton // "0x0000000000000000000000000000000000000000"' "$DEVNET_DIR/addresses.json")
    echo "    L2 TON: $L2_TON_FOR_REGISTRY"
    cast send "$L1_BRIDGE_REGISTRY" \
        "registerRollupConfigByManager(address,uint8,address,string)" \
        "$SYSTEM_CONFIG_ADDR" 3 "$L2_TON_FOR_REGISTRY" "Devnet L2" \
        --private-key "$MANAGER_KEY" --rpc-url "$RPC" > /dev/null
    echo -e "${GREEN}  Rollup config registered${NC}"
else
    echo -e "${GREEN}  Rollup config already registered (Type: $ROLLUP_TYPE)${NC}"
fi

# --- Step 11.3: Register CandidateAddOn (L2 Operator Staking) ---
echo "  Checking CandidateAddOn registration..."
ROLLUP_CONFIG_INFO=$(cast call "$LAYER2_MANAGER" "rollupConfigInfo(address)(uint8,address)" "$SYSTEM_CONFIG_ADDR" --rpc-url "$RPC" 2>/dev/null || echo "0 0x0000000000000000000000000000000000000000")
ROLLUP_STATUS=$(echo "$ROLLUP_CONFIG_INFO" | head -1)

if [ "$ROLLUP_STATUS" = "0" ]; then
    echo "  Approving TON to Layer2Manager..."
    cast send "$TON_ADDR" "approve(address,uint256)" "$LAYER2_MANAGER" \
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff \
        --private-key "$OPERATOR_KEY" --rpc-url "$RPC" > /dev/null

    echo "  Registering CandidateAddOn with 1001 TON stake..."
    cast send "$LAYER2_MANAGER" \
        "registerCandidateAddOn(address,uint256,bool,string)" \
        "$SYSTEM_CONFIG_ADDR" "$MIN_STAKE" true "Devnet L2 Operator" \
        --private-key "$OPERATOR_KEY" --rpc-url "$RPC" > /dev/null

    echo -e "${GREEN}  CandidateAddOn registered${NC}"
else
    echo -e "${GREEN}  CandidateAddOn already registered (Status: $ROLLUP_STATUS)${NC}"
fi

# --- Step 11.4: Verify registration ---
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
# Step 12: Register Validators with BLS Keys
# =============================================================================
echo -e "${YELLOW}Step 12: Registering validators with BLS keys...${NC}"

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

# Deposit amount: 100 TON (100 * 1e18)
VALIDATOR_DEPOSIT="100000000000000000000"

register_validator_with_bls() {
    local KEY=$1
    local ADDR=$2
    local NAME=$3
    local NAME_LOWER=$(echo "$NAME" | tr '[:upper:]' '[:lower:]')
    local BLS_KEY_FILE="$DEVNET_SEPOLIA_DIR/bls-keys-${NAME_LOWER}.env"

    echo "  Registering $NAME ($ADDR) with BLS key..."

    # Step 1: Generate BLS key
    BLS_OUTPUT=$("$BLS_KEYGEN" --validator "$ADDR" --chain-id 900)
    BLS_PRIVATE_KEY=$(echo "$BLS_OUTPUT" | grep "BLS_PRIVATE_KEY=" | cut -d= -f2)
    BLS_PUBLIC_KEY=$(echo "$BLS_OUTPUT" | grep "BLS_PUBLIC_KEY=" | cut -d= -f2)
    BLS_POP=$(echo "$BLS_OUTPUT" | grep "BLS_POP=" | cut -d= -f2)

    # Save BLS private key for FW validator config
    echo "BLS_PRIVATE_KEY=$BLS_PRIVATE_KEY" > "$BLS_KEY_FILE"

    # Step 2: Approve TON to WTON (for TON -> WTON -> Deposit flow)
    cast send "$TON_ADDR" "approve(address,uint256)" "$WTON_ADDR" \
        "115792089237316195423570985008687907853269984665640564039457584007913129639935" \
        --private-key "$KEY" --rpc-url "$RPC" --gas-limit 100000 > /dev/null 2>&1

    # Step 3: Deposit TON via approveAndCall(WTON, amount, abi.encode(depositManager, layer2))
    # TON.approveAndCall -> WTON.onApprove (TON->WTON) -> DepositManager.deposit
    CALLBACK_DATA=$(cast abi-encode "f(address,address)" "$DEPOSIT_MANAGER" "$CANDIDATE_ADDON")
    cast send "$TON_ADDR" "approveAndCall(address,uint256,bytes)" "$WTON_ADDR" "$VALIDATOR_DEPOSIT" "$CALLBACK_DATA" \
        --private-key "$KEY" --rpc-url "$RPC" --gas-limit 1000000 > /dev/null 2>&1

    # Step 4: Register with RAT using BLS key
    cast send "$RAT" "registerValidatorWithBLS(address,bytes,bytes)" \
        "$SYSTEM_CONFIG_ADDR" "$BLS_PUBLIC_KEY" "$BLS_POP" \
        --private-key "$KEY" --rpc-url "$RPC" --gas-limit 1000000 > /dev/null 2>&1

    echo -e "${GREEN}  $NAME registered with BLS key${NC}"
}

# Register all 3 validators with BLS keys
register_validator_with_bls "$VALIDATOR1_KEY" "$VALIDATOR1_ADDR" "Validator1"
register_validator_with_bls "$VALIDATOR2_KEY" "$VALIDATOR2_ADDR" "Validator2"
register_validator_with_bls "$VALIDATOR3_KEY" "$VALIDATOR3_ADDR" "Validator3"

# Verify registration
VALIDATOR_COUNT=$(cast call "$RAT" "getValidatorCount(address)(uint256)" "$SYSTEM_CONFIG_ADDR" --rpc-url "$RPC")
echo ""
echo -e "${GREEN}  Total validators registered: $VALIDATOR_COUNT${NC}"
echo ""

# =============================================================================
# Step 13: Configure RAT Parameters + Fast Withdrawal Parameters
# =============================================================================
echo -e "${YELLOW}Step 13: Configuring RAT parameters + Fast Withdrawal...${NC}"

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

echo "  Checking RAT configuration..."
CURRENT_EVIDENCE=$(cast call "$RAT" "evidenceSubmissionPeriod()(uint256)" --rpc-url "$RPC" 2>/dev/null | tr -d '[:space:]')
CURRENT_PENALTY=$(cast call "$RAT" "slashingPenalty()(uint256)" --rpc-url "$RPC" 2>/dev/null | tr -d '[:space:]')
if [ "$CURRENT_EVIDENCE" != "$RAT_EVIDENCE_PERIOD" ] || [ "$CURRENT_PENALTY" != "$RAT_SLASHING_PENALTY" ]; then
    echo "  Setting RAT configuration..."
    cast send "$RAT" \
        "setConfig((uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,address,uint256,bool))" \
        "($RAT_TRIGGER_PROBABILITY,$RAT_EVIDENCE_PERIOD,$RAT_SLASHING_PENALTY,$RAT_VALIDATOR_BUFFER,$RAT_MINIMUM_THRESHOLD,$RAT_MAX_VALIDATORS_PER_L2,$RAT_CHALLENGE_GAME_DURATION,$RAT_SAFETY_BUFFER,$RAT_TREASURY,$RAT_ATTENTION_COST,$RAT_RELAXED_CHECK)" \
        --private-key "$MANAGER_KEY" --rpc-url "$RPC" > /dev/null 2>&1

    # Verify configuration
    VERIFY_PENALTY=$(cast call "$RAT" "slashingPenalty()(uint256)" --rpc-url "$RPC")
    VERIFY_EVIDENCE=$(cast call "$RAT" "evidenceSubmissionPeriod()(uint256)" --rpc-url "$RPC")
    VERIFY_RELAXED=$(cast call "$RAT" "relaxedValidatorCheck()(bool)" --rpc-url "$RPC")

    echo -e "${GREEN}  RAT configured:${NC}"
    # Clean values and convert (WTON uses 27 decimals = RAY)
    PENALTY_CLEAN=$(echo "$VERIFY_PENALTY" | tr -d '[:space:]')
    EVIDENCE_CLEAN=$(echo "$VERIFY_EVIDENCE" | tr -d '[:space:]')
    echo "    Slashing Penalty: $(echo "$PENALTY_CLEAN" | awk '{printf "%.0f", $1/1e27}') WTON"
    echo "    Evidence Period: $EVIDENCE_CLEAN seconds ($(echo "$EVIDENCE_CLEAN" | awk '{printf "%.0f", $1/60}') minutes)"
    echo "    Relaxed Check: $VERIFY_RELAXED"
else
    VERIFY_RELAXED=$(cast call "$RAT" "relaxedValidatorCheck()(bool)" --rpc-url "$RPC")
    echo -e "${GREEN}  RAT configuration already set, skipping${NC}"
    echo "    Slashing Penalty: $(echo "$CURRENT_PENALTY" | awk '{printf "%.0f", $1/1e27}') WTON"
    echo "    Evidence Period: $CURRENT_EVIDENCE seconds ($(echo "$CURRENT_EVIDENCE" | awk '{printf "%.0f", $1/60}') minutes)"
    echo "    Relaxed Check: $VERIFY_RELAXED"
fi

# --- Fast Withdrawal Parameters ---
echo ""
echo "  Checking Fast Withdrawal parameters..."

# Aggregator fee rate: 10% (1e26 in RAY = 0.1 * 1e27)
AGG_FEE_RATE_DESIRED="100000000000000000000000000"
CURRENT_AGG_FEE=$(cast call "$RAT" "aggregatorFeeRate()(uint256)" --rpc-url "$RPC" 2>/dev/null | tr -d '[:space:]')
if [ "$CURRENT_AGG_FEE" != "$AGG_FEE_RATE_DESIRED" ]; then
    cast send "$RAT" "setAggregatorFeeRate(uint256)" "$AGG_FEE_RATE_DESIRED" \
        --private-key "$MANAGER_KEY" --rpc-url "$RPC" > /dev/null 2>&1
    echo -e "${GREEN}  Aggregator Fee Rate set to 10%${NC}"
else
    echo -e "${GREEN}  Aggregator Fee Rate already set to 10%, skipping${NC}"
fi

# Minimum validators for fast withdrawal: 3
MIN_VALIDATORS_DESIRED="3"
CURRENT_MIN_VALIDATORS=$(cast call "$RAT" "minValidatorsForFastWithdrawal()(uint256)" --rpc-url "$RPC" 2>/dev/null | tr -d '[:space:]')
if [ "$CURRENT_MIN_VALIDATORS" != "$MIN_VALIDATORS_DESIRED" ]; then
    cast send "$RAT" "setMinValidatorsForFastWithdrawal(uint256)" "$MIN_VALIDATORS_DESIRED" \
        --private-key "$MANAGER_KEY" --rpc-url "$RPC" > /dev/null 2>&1
    echo -e "${GREEN}  Min Validators set to $MIN_VALIDATORS_DESIRED${NC}"
else
    echo -e "${GREEN}  Min Validators already set to $MIN_VALIDATORS_DESIRED, skipping${NC}"
fi

# Fast Withdrawal fee: 10 TON (10e18)
FW_FEE_DESIRED="10000000000000000000"
CURRENT_FW_FEE=$(cast call "$RAT" "fastWithdrawalFee()(uint256)" --rpc-url "$RPC" 2>/dev/null | tr -d '[:space:]')
if [ "$CURRENT_FW_FEE" != "$FW_FEE_DESIRED" ]; then
    cast send "$RAT" "setFastWithdrawalFee(uint256)" "$FW_FEE_DESIRED" \
        --private-key "$MANAGER_KEY" --rpc-url "$RPC" > /dev/null 2>&1
    echo -e "${GREEN}  Fast Withdrawal Fee set to 10 TON${NC}"
else
    echo -e "${GREEN}  Fast Withdrawal Fee already set to 10 TON, skipping${NC}"
fi

echo ""

# =============================================================================
# Step 14: Setup Personal Test Account
# =============================================================================
echo -e "${YELLOW}Step 14: Setting up Personal Test account...${NC}"

PERSONAL_ADDR="0x976EA74026E726554dB657fA54763abd0C3a0aa9"
PERSONAL_ETH="100000000000000000000000"  # 100000 ETH in wei
PERSONAL_TON="100000000000000000000000"  # 100000 TON (18 decimals)

# Set ETH balance (use python3 for hex conversion to avoid printf overflow on large numbers)
PERSONAL_ETH_HEX=$(python3 -c "print(hex(int('$PERSONAL_ETH')))")
cast rpc anvil_setBalance "$PERSONAL_ADDR" "$PERSONAL_ETH_HEX" --rpc-url "$RPC" > /dev/null 2>&1

# Mint TON
cast send "$TON_ADDR" "mint(address,uint256)" "$PERSONAL_ADDR" "$PERSONAL_TON" \
    --private-key "$OPERATOR_KEY" --rpc-url "$RPC" > /dev/null 2>&1

# Mint WTON for Personal account
PERSONAL_WTON="100000000000000000000000000000000"  # 100000 WTON (27 decimals)
cast send "$WTON_ADDR" "mint(address,uint256)" "$PERSONAL_ADDR" "$PERSONAL_WTON" \
    --private-key "$OPERATOR_KEY" --rpc-url "$RPC" > /dev/null 2>&1

echo -e "${GREEN}  Personal Test account ready (100k ETH + 100k TON + 100k WTON)${NC}"
echo ""

# =============================================================================
# Step 15: Set SeigManager devnet parameters (seigStartBlock, initialTotalSupply)
# =============================================================================
echo -e "${YELLOW}Step 15: Setting SeigManager seigniorage start parameters...${NC}"
# SeigManager admin is Account #1 (TON Staking Deployer), not Account #0
SEIG_ADMIN_KEY="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
SEIG_ADDR=$(jq -r '.seigManagerProxy' "$DEVNET_DIR/addresses.json")

# Read actual TON totalSupply and convert to WTON (27 decimals) = TON * 1e9
TON_TOTAL_SUPPLY=$(cast call "$TON_ADDR" "totalSupply()(uint256)" --rpc-url "$RPC" 2>/dev/null | awk '{print $1}')
# Convert TON (18 decimals) to WTON (27 decimals): multiply by 1e9
INITIAL_TOTAL_SUPPLY=$(python3 -c "print(int('$TON_TOTAL_SUPPLY') * 10**9)")
echo "  TON totalSupply: $TON_TOTAL_SUPPLY ($(python3 -c "print(int('$TON_TOTAL_SUPPLY') / 10**18)") TON)"
echo "  initialTotalSupply (WTON): $INITIAL_TOTAL_SUPPLY"

# Set seigStartBlock to current block (skip if already set to avoid "same" revert)
CURRENT_BLOCK=$(cast block-number --rpc-url "$RPC")
CURRENT_SEIG_START=$(cast call "$SEIG_ADDR" "seigStartBlock()(uint256)" --rpc-url "$RPC" 2>/dev/null | awk '{print $1}')
if [ "$CURRENT_SEIG_START" != "$CURRENT_BLOCK" ]; then
    cast send "$SEIG_ADDR" "setSeigStartBlock(uint256)" "$CURRENT_BLOCK" \
        --private-key "$SEIG_ADMIN_KEY" --rpc-url "$RPC" > /dev/null 2>&1
    echo -e "${GREEN}  seigStartBlock set to $CURRENT_BLOCK${NC}"
else
    echo -e "${GREEN}  seigStartBlock already $CURRENT_BLOCK${NC}"
fi

# Set initialTotalSupply from actual TON totalSupply (skip if already set)
CURRENT_ITS=$(cast call "$SEIG_ADDR" "initialTotalSupply()(uint256)" --rpc-url "$RPC" 2>/dev/null | awk '{print $1}')
if [ "$CURRENT_ITS" != "$INITIAL_TOTAL_SUPPLY" ]; then
    cast send "$SEIG_ADDR" "setInitialTotalSupply(uint256)" "$INITIAL_TOTAL_SUPPLY" \
        --private-key "$SEIG_ADMIN_KEY" --rpc-url "$RPC" > /dev/null 2>&1
    echo -e "${GREEN}  initialTotalSupply set from actual TON totalSupply${NC}"
else
    echo -e "${GREEN}  initialTotalSupply already correct${NC}"
fi

# Set burntAmountAtDAO to 1 (non-zero to avoid mainnet fallback on chainId==1; skip if already set)
CURRENT_BURNT=$(cast call "$SEIG_ADDR" "burntAmountAtDAO()(uint256)" --rpc-url "$RPC" 2>/dev/null | awk '{print $1}')
if [ "$CURRENT_BURNT" != "1" ]; then
    cast send "$SEIG_ADDR" "setBurntAmountAtDAO(uint256)" "1" \
        --private-key "$SEIG_ADMIN_KEY" --rpc-url "$RPC" > /dev/null 2>&1
    echo -e "${GREEN}  burntAmountAtDAO set to 1${NC}"
else
    echo -e "${GREEN}  burntAmountAtDAO already 1${NC}"
fi
echo ""

# =============================================================================
# Step 16: Generate FW config files and start FW nodes
# =============================================================================
echo -e "${YELLOW}Step 16: Starting Fast Withdrawal nodes...${NC}"

RAT_ADDR=$(jq -r '.ratProxy' "$DEVNET_DIR/addresses.json")

# Each FW node runs both validator + aggregator.
# All nodes detect L1 events and can aggregate; first to submit wins.
# Each validator uses its own Ethereum key for aggregator L1 submission.

VALIDATOR_KEYS=("$VALIDATOR1_KEY" "$VALIDATOR2_KEY" "$VALIDATOR3_KEY")
VALIDATOR_ADDRS=("$VALIDATOR1_ADDR" "$VALIDATOR2_ADDR" "$VALIDATOR3_ADDR")

generate_fw_node_config() {
    local NUM=$1
    local ADDR=$2
    local ETH_KEY=$3
    local VALIDATOR_PORT=$4
    local AGGREGATOR_PORT=$5
    local NAME="validator${NUM}"

    BLS_PRIV=$(grep "BLS_PRIVATE_KEY=" "$DEVNET_SEPOLIA_DIR/bls-keys-${NAME}.env" | cut -d= -f2)

    # Validator config
    cat > "$DEVNET_SEPOLIA_DIR/fw-node-${NUM}-validator.yaml" <<FWEOF
validator:
  address: "${ADDR}"
  bls_private_key: "${BLS_PRIV}"

l1:
  rpc: "http://host.docker.internal:${L1_PORT}"
  rat_contract: "${RAT_ADDR}"

l2:
  rpc: "http://l2-execution:8545"
  opnode_rpc: "http://l2-node:8545"

p2p:
  listen_addr: "/ip4/0.0.0.0/tcp/${VALIDATOR_PORT}"
  bootstrap_peers: []
  dht_namespace: "/tokamak-rat-validators"
  withdrawal_topic: "/tokamak/rat/withdrawal/1.0.0"

log:
  level: "info"
  format: "text"
FWEOF

    # Aggregator config (uses same account's Ethereum key for L1 submission)
    local SYSTEM_CONFIG_ADDR=$(jq -r '.systemConfig' "$DEVNET_DIR/addresses.json")
    cat > "$DEVNET_SEPOLIA_DIR/fw-node-${NUM}-aggregator.yaml" <<FWEOF
aggregator:
  address: "${ADDR}"
  private_key: "${ETH_KEY#0x}"

l1:
  rpc: "http://host.docker.internal:${L1_PORT}"
  rat_contract: "${RAT_ADDR}"
  fast_withdrawal_contract: "${RAT_ADDR}"
  system_config: "${SYSTEM_CONFIG_ADDR}"

l2:
  rpc: "http://l2-execution:8545"

p2p:
  listen_addr: "/ip4/0.0.0.0/tcp/${AGGREGATOR_PORT}"
  bootstrap_peers: []
  dht_namespace: "/tokamak-rat-validators"
  withdrawal_topic: "/tokamak/rat/withdrawal/1.0.0"

fast_withdrawal:
  response_timeout: 300
  min_validators: 3
  max_gas_price: 100
  submission_gas_limit: 500000

log:
  level: "info"
  format: "text"
FWEOF

    echo "  Generated fw-node-${NUM} configs (validator + aggregator)"
}

generate_fw_node_config 1 "$VALIDATOR1_ADDR" "$VALIDATOR1_KEY" 9000 9100
generate_fw_node_config 2 "$VALIDATOR2_ADDR" "$VALIDATOR2_KEY" 9001 9101
generate_fw_node_config 3 "$VALIDATOR3_ADDR" "$VALIDATOR3_KEY" 9002 9102

# Start FW nodes
echo "  Starting FW nodes..."
docker compose -f "$COMPOSE_FILE" up -d fw-node-1 fw-node-2 fw-node-3
echo -e "${GREEN}  Fast Withdrawal nodes started (each runs validator + aggregator)${NC}"
echo ""

# =============================================================================
# Summary
# =============================================================================
echo -e "${GREEN}=== Devnet with Fast Withdrawal Started Successfully ===${NC}"
echo ""
echo -e "${BLUE}=== RPC Endpoints ===${NC}"
echo "L1 (Anvil Prague):       http://localhost:$L1_PORT"
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
echo -e "${BLUE}=== Challenge Period ===${NC}"
PROOF_MATURITY=$(cast call "$OPTIMISM_PORTAL" "proofMaturityDelaySeconds()(uint256)" --rpc-url "$RPC" 2>/dev/null | awk '{print $1}')
GAME_FINALITY=$(cast call "$OPTIMISM_PORTAL" "disputeGameFinalityDelaySeconds()(uint256)" --rpc-url "$RPC" 2>/dev/null | awk '{print $1}')
echo "Proof Maturity Delay:   ${PROOF_MATURITY}s ($(echo "$PROOF_MATURITY / 60" | bc)m) - Prove 후 대기"
echo "Game Finality Delay:    ${GAME_FINALITY}s ($(echo "$GAME_FINALITY / 60" | bc)m) - Game 종료 후 Airgap"
echo "Total Challenge Period: $((PROOF_MATURITY + GAME_FINALITY))s ($(echo "(${PROOF_MATURITY} + ${GAME_FINALITY}) / 60" | bc)m)"
echo "Evidence Period:        600s (10m) - RAT 증거 제출 기간"
echo ""
echo -e "${BLUE}=== Fast Withdrawal ===${NC}"
echo "FW Nodes:       3 (each runs validator + aggregator)"
echo "Min Validators: 3"
echo "Aggregator Fee: 10%"
echo "  Node1: $VALIDATOR1_ADDR (Anvil #3)"
echo "  Node2: $VALIDATOR2_ADDR (Anvil #4)"
echo "  Node3: $VALIDATOR3_ADDR (Anvil #5)"
echo ""
echo -e "${BLUE}=== Test Accounts (100k TON each) ===${NC}"
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
echo "  Anvil:    tail -f $ANVIL_LOG"
echo "  L2:       docker logs -f ton-staking-l2-node"
echo "  RAT:      docker logs -f ton-staking-rat-client-1"
echo "  FW Node1: docker logs -f ton-staking-fw-node-1"
echo "  FW Node2: docker logs -f ton-staking-fw-node-2"
echo "  FW Node3: docker logs -f ton-staking-fw-node-3"
echo ""
echo -e "${YELLOW}Stop:${NC}"
echo "  ./scripts/local/stop-dev-fw.sh"
echo ""
echo -e "${YELLOW}Web UI:${NC}"
echo "  cd web-ui && npm run dev"
echo "  Open http://localhost:5173"
