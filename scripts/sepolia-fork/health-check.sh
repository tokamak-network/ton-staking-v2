#!/bin/bash
# =============================================================================
# TON Staking V3 Sepolia Fork Devnet Health Check
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEVNET_DIR="$PROJECT_ROOT/.devnet-sepolia-fork"
DEPLOYMENT_DIR="$PROJECT_ROOT/deployments/sepolia-fork"
COMPOSE_FILE="$DEPLOYMENT_DIR/docker-compose.yml"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     TON Staking V3 Sepolia Fork - Health Check             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Helper functions
check_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

check_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

# Counter for issues
ERRORS=0
WARNINGS=0

# =============================================================================
# 1. Docker Containers Check
# =============================================================================
echo -e "${BLUE}[1/7] Checking Docker Containers...${NC}"

CONTAINERS=(
    "ton-staking-l1-sepolia-fork"
    "ton-staking-l2-execution-sepolia-fork"
    "ton-staking-l2-node-sepolia-fork"
    "ton-staking-l2-batcher-sepolia-fork"
)

for container in "${CONTAINERS[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        STATUS=$(docker inspect --format='{{.State.Status}}' "$container")
        if [ "$STATUS" = "running" ]; then
            # Check health if available
            HEALTH=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "none")
            if [ "$HEALTH" = "healthy" ]; then
                check_pass "$container: running (healthy)"
            elif [ "$HEALTH" = "none" ]; then
                check_pass "$container: running"
            else
                check_warn "$container: running (health: $HEALTH)"
                WARNINGS=$((WARNINGS + 1))
            fi
        else
            check_fail "$container: $STATUS"
            ERRORS=$((ERRORS + 1))
        fi
    else
        check_fail "$container: not found"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check RAT clients (optional)
for i in 1 2 3; do
    container="ton-staking-rat-client-$i-sepolia-fork"
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        check_pass "$container: running"
    else
        check_info "$container: not started (optional)"
    fi
done
echo ""

# =============================================================================
# 2. L1 RPC Check (Sepolia Fork)
# =============================================================================
echo -e "${BLUE}[2/7] Checking L1 RPC (Sepolia Fork)...${NC}"

if curl -s -X POST http://localhost:8545 \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' > /tmp/l1_response.json 2>/dev/null; then

    L1_CHAIN_ID=$(jq -r '.result' /tmp/l1_response.json 2>/dev/null)
    # Sepolia chain ID is 11155111 = 0xaa36a7
    if [ "$L1_CHAIN_ID" = "0xaa36a7" ]; then
        check_pass "L1 RPC: responding (Chain ID: 11155111 - Sepolia)"
    else
        L1_CHAIN_ID_DEC=$((L1_CHAIN_ID))
        check_warn "L1 RPC: responding (Chain ID: $L1_CHAIN_ID_DEC, expected: 11155111)"
        WARNINGS=$((WARNINGS + 1))
    fi

    # Check block number
    L1_BLOCK=$(curl -s -X POST http://localhost:8545 \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' | jq -r '.result')
    L1_BLOCK_DEC=$((L1_BLOCK))
    check_info "L1 Block Number: $L1_BLOCK_DEC"
else
    check_fail "L1 RPC: not responding"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# =============================================================================
# 3. L2 RPC Check
# =============================================================================
echo -e "${BLUE}[3/7] Checking L2 RPC...${NC}"

if curl -s -X POST http://localhost:9545 \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' > /tmp/l2_response.json 2>/dev/null; then

    L2_CHAIN_ID=$(jq -r '.result' /tmp/l2_response.json 2>/dev/null)
    if [ "$L2_CHAIN_ID" = "0x385" ]; then
        check_pass "L2 RPC: responding (Chain ID: 901)"
    else
        check_warn "L2 RPC: responding (Chain ID: $L2_CHAIN_ID, expected: 0x385)"
        WARNINGS=$((WARNINGS + 1))
    fi

    # Check block number
    L2_BLOCK=$(curl -s -X POST http://localhost:9545 \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' | jq -r '.result')
    L2_BLOCK_DEC=$((L2_BLOCK))
    check_info "L2 Block Number: $L2_BLOCK_DEC"

    if [ "$L2_BLOCK_DEC" -gt 10 ]; then
        check_pass "L2 is producing blocks"
    else
        check_warn "L2 block count is low ($L2_BLOCK_DEC) - may still be syncing"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    check_fail "L2 RPC: not responding"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# =============================================================================
# 4. Contract Deployment Check
# =============================================================================
echo -e "${BLUE}[4/7] Checking Contract Deployments...${NC}"

# Load addresses from devnet dir
if [ -f "$DEVNET_DIR/addresses.json" ]; then
    TON_ADDRESS=$(jq -r '.ton // "null"' "$DEVNET_DIR/addresses.json")
    WTON_ADDRESS=$(jq -r '.wton // "null"' "$DEVNET_DIR/addresses.json")
    RAT_ADDRESS=$(jq -r '.ratProxy // "null"' "$DEVNET_DIR/addresses.json")
    SEIG_MANAGER=$(jq -r '.seigManagerProxy // "null"' "$DEVNET_DIR/addresses.json")

    check_contract() {
        local name="$1"
        local address="$2"

        if [ "$address" = "null" ] || [ -z "$address" ]; then
            check_warn "$name: address not found"
            WARNINGS=$((WARNINGS + 1))
            return
        fi

        CODE=$(curl -s -X POST http://localhost:8545 \
            -H "Content-Type: application/json" \
            -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getCode\",\"params\":[\"$address\",\"latest\"],\"id\":1}" | jq -r '.result')

        if [ "$CODE" != "0x" ] && [ "$CODE" != "null" ] && [ -n "$CODE" ]; then
            CODE_LENGTH=${#CODE}
            check_pass "$name: deployed ($CODE_LENGTH bytes)"
        else
            check_fail "$name: not deployed at $address"
            ERRORS=$((ERRORS + 1))
        fi
    }

    check_contract "TON" "$TON_ADDRESS"
    check_contract "WTON" "$WTON_ADDRESS"
    check_contract "RAT" "$RAT_ADDRESS"
    check_contract "SeigManager" "$SEIG_MANAGER"
else
    check_warn "addresses.json not found - contracts may not be deployed"
    WARNINGS=$((WARNINGS + 1))
fi

# Check Optimism contracts
if [ -f "$DEVNET_DIR/optimism-addresses.json" ]; then
    DGF_ADDRESS=$(jq -r '.DisputeGameFactoryProxy // "null"' "$DEVNET_DIR/optimism-addresses.json")
    SC_ADDRESS=$(jq -r '.SystemConfigProxy // "null"' "$DEVNET_DIR/optimism-addresses.json")

    if [ "$DGF_ADDRESS" != "null" ] && [ "$DGF_ADDRESS" != "0x0000000000000000000000000000000000000000" ]; then
        check_contract "DisputeGameFactory" "$DGF_ADDRESS"
    else
        check_info "DisputeGameFactory: using existing Sepolia contract"
    fi

    if [ "$SC_ADDRESS" != "null" ]; then
        check_contract "SystemConfig" "$SC_ADDRESS"
    fi
fi
echo ""

# =============================================================================
# 5. op-node Sync Status
# =============================================================================
echo -e "${BLUE}[5/7] Checking op-node Sync Status...${NC}"

if curl -s -X POST http://localhost:7545 \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"optimism_syncStatus","params":[],"id":1}' > /tmp/sync_status.json 2>/dev/null; then

    UNSAFE_L2=$(jq -r '.result.unsafe_l2.number' /tmp/sync_status.json 2>/dev/null)
    SAFE_L2=$(jq -r '.result.safe_l2.number' /tmp/sync_status.json 2>/dev/null)
    CURRENT_L1=$(jq -r '.result.current_l1.number' /tmp/sync_status.json 2>/dev/null)

    if [ "$UNSAFE_L2" != "null" ] && [ -n "$UNSAFE_L2" ]; then
        check_pass "op-node: synced (L2 unsafe: $UNSAFE_L2, safe: $SAFE_L2)"
        check_info "Current L1: $CURRENT_L1"
    else
        check_warn "op-node: sync status unclear"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    check_fail "op-node RPC: not responding"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# =============================================================================
# 6. Batcher Status
# =============================================================================
echo -e "${BLUE}[6/7] Checking Batcher...${NC}"

BATCHER_CONTAINER="ton-staking-l2-batcher-sepolia-fork"
if docker ps --format '{{.Names}}' | grep -q "$BATCHER_CONTAINER"; then
    BATCHER_LOGS=$(docker logs "$BATCHER_CONTAINER" 2>&1 | tail -20)

    if echo "$BATCHER_LOGS" | grep -q "Publishing\|Submitted"; then
        check_pass "Batcher: publishing transactions"
    elif echo "$BATCHER_LOGS" | grep -q "Sequencer is out of sync"; then
        check_warn "Batcher: waiting for sequencer sync"
        WARNINGS=$((WARNINGS + 1))
    elif echo "$BATCHER_LOGS" | grep -q "ERROR\|error"; then
        check_fail "Batcher: errors in logs"
        ERRORS=$((ERRORS + 1))
    else
        check_pass "Batcher: running"
    fi
else
    check_fail "Batcher: not running"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# =============================================================================
# 7. Test Account Balances
# =============================================================================
echo -e "${BLUE}[7/7] Checking Test Account Balances...${NC}"

DEPLOYER="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
DEPLOYER_BALANCE=$(cast balance "$DEPLOYER" --rpc-url http://localhost:8545 --ether 2>/dev/null || echo "0")

if [ -n "$DEPLOYER_BALANCE" ] && [ "$(echo "$DEPLOYER_BALANCE > 0" | bc)" -eq 1 ]; then
    check_pass "Deployer balance: ${DEPLOYER_BALANCE} ETH"
else
    check_warn "Deployer balance: 0 ETH (may need funding)"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# =============================================================================
# Summary
# =============================================================================
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                        Summary                             ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}All systems operational! Devnet is healthy.${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}Devnet is running with $WARNINGS warning(s).${NC}"
    exit 0
else
    echo -e "${RED}Devnet has $ERRORS error(s) and $WARNINGS warning(s).${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "  - Check logs: make devnet-sepolia-fork-logs"
    echo "  - Restart:    make devnet-sepolia-fork-stop && make devnet-sepolia-fork-start"
    exit 1
fi
