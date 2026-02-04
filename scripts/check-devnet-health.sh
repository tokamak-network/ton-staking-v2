#!/bin/bash
# =============================================================================
# TON Staking V2 Devnet Health Check Script
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}=== TON Staking V2 Devnet Health Check ===${NC}"
echo ""

# Helper functions
check_pass() {
    echo -e "${GREEN}✅ $1${NC}"
}

check_fail() {
    echo -e "${RED}❌ $1${NC}"
}

check_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

check_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Counter for issues
ERRORS=0
WARNINGS=0

# =============================================================================
# 1. Docker Containers Check
# =============================================================================
echo -e "${BLUE}[1/7] Checking Docker Containers...${NC}"

CONTAINERS=(
    "ton-staking-l1"
    "ton-staking-l2-execution"
    "ton-staking-l2-node"
    "ton-staking-l2-batcher"
    "ton-staking-rat-client-1"
    "ton-staking-rat-client-2"
    "ton-staking-rat-client-3"
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
echo ""

# =============================================================================
# 2. L1 RPC Check
# =============================================================================
echo -e "${BLUE}[2/7] Checking L1 RPC...${NC}"

if curl -s -X POST http://localhost:8545 \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' > /tmp/l1_response.json 2>/dev/null; then
    
    L1_CHAIN_ID=$(jq -r '.result' /tmp/l1_response.json 2>/dev/null)
    if [ "$L1_CHAIN_ID" = "0x384" ]; then
        check_pass "L1 RPC: responding (Chain ID: 900)"
    else
        check_warn "L1 RPC: responding (Chain ID: $L1_CHAIN_ID, expected: 900)"
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
        check_warn "L2 RPC: responding (Chain ID: $L2_CHAIN_ID, expected: 901)"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    # Check block number
    L2_BLOCK=$(curl -s -X POST http://localhost:9545 \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' | jq -r '.result')
    L2_BLOCK_DEC=$((L2_BLOCK))
    check_info "L2 Block Number: $L2_BLOCK_DEC"
    
    if [ "$L2_BLOCK_DEC" -gt 100 ]; then
        check_pass "L2 is producing blocks"
    else
        check_warn "L2 block count is low ($L2_BLOCK_DEC)"
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

CONTRACTS=(
    "DisputeGameFactory:0x52d01b38b78b559142b04cc19f5cc50d5c03dbac"
    "SystemConfig:0x577AcB7fA48878245a854ba51eD051a5B47cF83f"
    "RAT:0xE5BD5bDC03371fB239956dbbF40bD185D6c2ea28"
)

for contract_info in "${CONTRACTS[@]}"; do
    NAME="${contract_info%%:*}"
    ADDRESS="${contract_info##*:}"
    
    CODE=$(curl -s -X POST http://localhost:8545 \
        -H "Content-Type: application/json" \
        -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getCode\",\"params\":[\"$ADDRESS\",\"latest\"],\"id\":1}" | jq -r '.result')
    
    if [ "$CODE" != "0x" ] && [ "$CODE" != "null" ] && [ -n "$CODE" ]; then
        CODE_LENGTH=${#CODE}
        check_pass "$NAME deployed ($CODE_LENGTH bytes)"
    else
        check_fail "$NAME not deployed at $ADDRESS"
        ERRORS=$((ERRORS + 1))
    fi
done
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
    
    if [ "$UNSAFE_L2" != "null" ] && [ -n "$UNSAFE_L2" ]; then
        check_pass "op-node: synced (L2 block: $UNSAFE_L2)"
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
# 6. Proposer Status
# =============================================================================
echo -e "${BLUE}[6/9] Checking Proposer...${NC}"

if docker logs ton-staking-l2-proposer 2>&1 | tail -20 | grep -q "Proposer started"; then
    if docker logs ton-staking-l2-proposer 2>&1 | tail -10 | grep -q "Skipping proposal for genesis block"; then
        check_pass "Proposer: running (genesis skip is normal)"
    elif docker logs ton-staking-l2-proposer 2>&1 | tail -10 | grep -q "Proposed output"; then
        check_pass "Proposer: actively proposing outputs"
    else
        check_pass "Proposer: running"
    fi
else
    PROPOSER_RUNNING=$(docker ps --filter "name=ton-staking-l2-proposer" --format '{{.Names}}')
    if [ -n "$PROPOSER_RUNNING" ]; then
        check_warn "Proposer: running but no activity logs"
        WARNINGS=$((WARNINGS + 1))
    else
        check_fail "Proposer: not running"
        ERRORS=$((ERRORS + 1))
    fi
fi
echo ""

# =============================================================================
# 7. Batcher Status
# =============================================================================
echo -e "${BLUE}[7/9] Checking Batcher...${NC}"

if docker logs ton-staking-l2-batcher 2>&1 | tail -20 | grep -q "Publishing"; then
    check_pass "Batcher: publishing transactions"
elif docker logs ton-staking-l2-batcher 2>&1 | tail -20 | grep -q "Sequencer is out of sync"; then
    check_warn "Batcher: waiting for sequencer sync (initial sync)"
    WARNINGS=$((WARNINGS + 1))
else
    BATCHER_RUNNING=$(docker ps --filter "name=ton-staking-l2-batcher" --format '{{.Names}}')
    if [ -n "$BATCHER_RUNNING" ]; then
        check_pass "Batcher: running"
    else
        check_fail "Batcher: not running"
        ERRORS=$((ERRORS + 1))
    fi
fi
echo ""

# =============================================================================
# 8. Batcher Sync Details
# =============================================================================
echo -e "${BLUE}[8/9] Checking Batcher Sync Details...${NC}"

BATCHER_LOGS=$(docker logs ton-staking-l2-batcher 2>&1 | tail -5)
if echo "$BATCHER_LOGS" | grep -q "localSafeL2"; then
    UNSAFE_L2=$(echo "$BATCHER_LOGS" | grep "unsafeL2" | tail -1 | grep -oE "unsafeL2=[a-f0-9.]*:[0-9]+" | grep -oE "[0-9]+$" | head -1)
    SAFE_L2=$(echo "$BATCHER_LOGS" | grep "safeL2=" | tail -1 | grep -oE "safeL2=[a-f0-9.]*:[0-9]+" | grep -oE "[0-9]+$" | head -1)
    
    if [ -n "$UNSAFE_L2" ] && [ "$UNSAFE_L2" -gt 0 ] 2>/dev/null; then
        check_info "Unsafe L2 Block: $UNSAFE_L2"
    fi
    
    if [ -n "$SAFE_L2" ] && [ "$SAFE_L2" -gt 0 ] 2>/dev/null; then
        check_pass "Safe L2 Block: $SAFE_L2 (finalized)"
    else
        check_warn "Safe L2 Block: 0 (waiting for finalization)"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    check_info "No sync status available yet"
fi
echo ""

# =============================================================================
# 9. RAT Clients Status
# =============================================================================
echo -e "${BLUE}[9/9] Checking RAT Clients...${NC}"

for i in 1 2 3; do
    CLIENT="ton-staking-rat-client-$i"
    if docker logs "$CLIENT" 2>&1 | tail -5 | grep -q "Polled blocks\|Processing\|running in"; then
        check_pass "RAT Client $i: monitoring events"
    else
        LAST_LOG=$(docker logs "$CLIENT" 2>&1 | tail -1)
        if echo "$LAST_LOG" | grep -q "ERROR\|FATAL\|panic"; then
            check_fail "RAT Client $i: error ($LAST_LOG)"
            ERRORS=$((ERRORS + 1))
        else
            check_pass "RAT Client $i: running"
        fi
    fi
done
echo ""

# =============================================================================
# Summary
# =============================================================================
echo -e "${BLUE}=== Summary ===${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}🎉 All systems operational! Devnet is healthy.${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Devnet is running with $WARNINGS warning(s).${NC}"
    exit 0
else
    echo -e "${RED}❌ Devnet has $ERRORS error(s) and $WARNINGS warning(s).${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "  - Check logs: docker-compose logs -f"
    echo "  - Restart: docker-compose restart"
    echo "  - Full reset: docker-compose down -v && docker-compose up -d"
    exit 1
fi
