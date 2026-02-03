#!/bin/bash
# =============================================================================
# Test TON Staking V3 Local Devnet
# =============================================================================
# This script tests the local development environment to ensure
# all components are working correctly.
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
DEVNET_DIR="$PROJECT_ROOT/.devnet"

# RPC URLs
L1_RPC="http://localhost:8545"
L2_RPC="http://localhost:9545"

# Test accounts (Anvil default accounts)
DEPLOYER_ADDRESS="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
DEPLOYER_KEY="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"

VALIDATOR_ADDRESS="0x90F79bf6EB2c4f870365E785982E1f101E93b906"
VALIDATOR_KEY="0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"

# Counters
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    ((TESTS_PASSED++))
}

fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    ((TESTS_FAILED++))
}

info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

section() {
    echo ""
    echo -e "${YELLOW}=== $1 ===${NC}"
    echo ""
}

# Load contract addresses
load_addresses() {
    if [ ! -f "$DEVNET_DIR/addresses.json" ]; then
        echo -e "${RED}Error: addresses.json not found${NC}"
        exit 1
    fi

    TON=$(jq -r '.ton' "$DEVNET_DIR/addresses.json")
    WTON=$(jq -r '.wton' "$DEVNET_DIR/addresses.json")
    SEIG_MANAGER=$(jq -r '.seigManagerProxy' "$DEVNET_DIR/addresses.json")
    DEPOSIT_MANAGER=$(jq -r '.depositManagerProxy' "$DEVNET_DIR/addresses.json")
    LAYER2_MANAGER=$(jq -r '.layer2ManagerProxy' "$DEVNET_DIR/addresses.json")
    L1_BRIDGE_REGISTRY=$(jq -r '.l1BridgeRegistryProxy' "$DEVNET_DIR/addresses.json")
    RAT=$(jq -r '.ratProxy' "$DEVNET_DIR/addresses.json")
    VALIDATOR_REWARD=$(jq -r '.validatorRewardProxy' "$DEVNET_DIR/addresses.json")
    SYSTEM_CONFIG=$(jq -r '.systemConfig' "$DEVNET_DIR/addresses.json")
}

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     TON Staking V3 Local Devnet Test Suite                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Load addresses
load_addresses

# =============================================================================
section "1. Network Connectivity Tests"
# =============================================================================

# Test L1 RPC
if cast chain-id --rpc-url $L1_RPC &> /dev/null; then
    L1_CHAIN_ID=$(cast chain-id --rpc-url $L1_RPC)
    if [ "$L1_CHAIN_ID" == "900" ]; then
        pass "L1 RPC is accessible (Chain ID: $L1_CHAIN_ID)"
    else
        fail "L1 Chain ID mismatch (expected: 900, got: $L1_CHAIN_ID)"
    fi
else
    fail "L1 RPC is not accessible at $L1_RPC"
fi

# Test L2 RPC
if cast chain-id --rpc-url $L2_RPC &> /dev/null; then
    L2_CHAIN_ID=$(cast chain-id --rpc-url $L2_RPC)
    if [ "$L2_CHAIN_ID" == "901" ]; then
        pass "L2 RPC is accessible (Chain ID: $L2_CHAIN_ID)"
    else
        fail "L2 Chain ID mismatch (expected: 901, got: $L2_CHAIN_ID)"
    fi
else
    fail "L2 RPC is not accessible at $L2_RPC"
fi

# Test L1 block production
L1_BLOCK=$(cast block-number --rpc-url $L1_RPC 2>/dev/null || echo "0")
if [ "$L1_BLOCK" -gt "0" ]; then
    pass "L1 is producing blocks (current: $L1_BLOCK)"
else
    fail "L1 is not producing blocks"
fi

# =============================================================================
section "2. Contract Deployment Tests"
# =============================================================================

# Test TON contract
TON_CODE=$(cast code $TON --rpc-url $L1_RPC 2>/dev/null || echo "0x")
if [ "$TON_CODE" != "0x" ] && [ ${#TON_CODE} -gt 10 ]; then
    TON_NAME=$(cast call $TON "name()(string)" --rpc-url $L1_RPC 2>/dev/null || echo "")
    pass "TON contract deployed at $TON (name: $TON_NAME)"
else
    fail "TON contract not found at $TON"
fi

# Test WTON contract
WTON_CODE=$(cast code $WTON --rpc-url $L1_RPC 2>/dev/null || echo "0x")
if [ "$WTON_CODE" != "0x" ] && [ ${#WTON_CODE} -gt 10 ]; then
    WTON_NAME=$(cast call $WTON "name()(string)" --rpc-url $L1_RPC 2>/dev/null || echo "")
    pass "WTON contract deployed at $WTON (name: $WTON_NAME)"
else
    fail "WTON contract not found at $WTON"
fi

# Test SeigManager contract
SEIG_CODE=$(cast code $SEIG_MANAGER --rpc-url $L1_RPC 2>/dev/null || echo "0x")
if [ "$SEIG_CODE" != "0x" ] && [ ${#SEIG_CODE} -gt 10 ]; then
    pass "SeigManager contract deployed at $SEIG_MANAGER"
else
    fail "SeigManager contract not found at $SEIG_MANAGER"
fi

# Test DepositManager contract
DEPOSIT_CODE=$(cast code $DEPOSIT_MANAGER --rpc-url $L1_RPC 2>/dev/null || echo "0x")
if [ "$DEPOSIT_CODE" != "0x" ] && [ ${#DEPOSIT_CODE} -gt 10 ]; then
    pass "DepositManager contract deployed at $DEPOSIT_MANAGER"
else
    fail "DepositManager contract not found at $DEPOSIT_MANAGER"
fi

# Test Layer2Manager contract
L2M_CODE=$(cast code $LAYER2_MANAGER --rpc-url $L1_RPC 2>/dev/null || echo "0x")
if [ "$L2M_CODE" != "0x" ] && [ ${#L2M_CODE} -gt 10 ]; then
    pass "Layer2Manager contract deployed at $LAYER2_MANAGER"
else
    fail "Layer2Manager contract not found at $LAYER2_MANAGER"
fi

# Test RAT contract
RAT_CODE=$(cast code $RAT --rpc-url $L1_RPC 2>/dev/null || echo "0x")
if [ "$RAT_CODE" != "0x" ] && [ ${#RAT_CODE} -gt 10 ]; then
    pass "RAT contract deployed at $RAT"
else
    fail "RAT contract not found at $RAT"
fi

# Test SystemConfig contract
SC_CODE=$(cast code $SYSTEM_CONFIG --rpc-url $L1_RPC 2>/dev/null || echo "0x")
if [ "$SC_CODE" != "0x" ] && [ ${#SC_CODE} -gt 10 ]; then
    pass "SystemConfig contract deployed at $SYSTEM_CONFIG"
else
    fail "SystemConfig contract not found at $SYSTEM_CONFIG"
fi

# =============================================================================
section "3. Account Balance Tests"
# =============================================================================

# Check deployer ETH balance
DEPLOYER_ETH=$(cast balance $DEPLOYER_ADDRESS --rpc-url $L1_RPC 2>/dev/null || echo "0")
DEPLOYER_ETH_FORMATTED=$(cast from-wei $DEPLOYER_ETH 2>/dev/null || echo "0")
if [ "$DEPLOYER_ETH" != "0" ]; then
    pass "Deployer has ETH balance: $DEPLOYER_ETH_FORMATTED ETH"
else
    fail "Deployer has no ETH balance"
fi

# Check deployer TON balance
DEPLOYER_TON=$(cast call $TON "balanceOf(address)(uint256)" $DEPLOYER_ADDRESS --rpc-url $L1_RPC 2>/dev/null || echo "0")
DEPLOYER_TON_FORMATTED=$(cast from-wei $DEPLOYER_TON 2>/dev/null || echo "0")
if [ "$DEPLOYER_TON" != "0" ]; then
    pass "Deployer has TON balance: $DEPLOYER_TON_FORMATTED TON"
else
    fail "Deployer has no TON balance"
fi

# Check validator ETH balance
VALIDATOR_ETH=$(cast balance $VALIDATOR_ADDRESS --rpc-url $L1_RPC 2>/dev/null || echo "0")
VALIDATOR_ETH_FORMATTED=$(cast from-wei $VALIDATOR_ETH 2>/dev/null || echo "0")
if [ "$VALIDATOR_ETH" != "0" ]; then
    pass "Validator has ETH balance: $VALIDATOR_ETH_FORMATTED ETH"
else
    fail "Validator has no ETH balance"
fi

# =============================================================================
section "4. Contract Function Tests"
# =============================================================================

# Test TON totalSupply
TON_SUPPLY=$(cast call $TON "totalSupply()(uint256)" --rpc-url $L1_RPC 2>/dev/null || echo "0")
if [ "$TON_SUPPLY" != "0" ]; then
    TON_SUPPLY_FORMATTED=$(cast from-wei $TON_SUPPLY 2>/dev/null || echo "N/A")
    pass "TON totalSupply: $TON_SUPPLY_FORMATTED TON"
else
    fail "TON totalSupply is 0 or not accessible"
fi

# Test WTON totalSupply
WTON_SUPPLY=$(cast call $WTON "totalSupply()(uint256)" --rpc-url $L1_RPC 2>/dev/null || echo "0")
pass "WTON totalSupply: $WTON_SUPPLY (raw)"

# Test SeigManager TON getter
SEIG_TON=$(cast call $SEIG_MANAGER "ton()(address)" --rpc-url $L1_RPC 2>/dev/null || echo "")
if [ -n "$SEIG_TON" ] && [ "$SEIG_TON" != "0x" ]; then
    pass "SeigManager.ton() returns: $SEIG_TON"
else
    fail "SeigManager.ton() failed"
fi

# Test DepositManager TON getter
DEPOSIT_TON=$(cast call $DEPOSIT_MANAGER "ton()(address)" --rpc-url $L1_RPC 2>/dev/null || echo "")
if [ -n "$DEPOSIT_TON" ] && [ "$DEPOSIT_TON" != "0x" ]; then
    pass "DepositManager.ton() returns: $DEPOSIT_TON"
else
    fail "DepositManager.ton() failed"
fi

# =============================================================================
section "5. Transaction Tests"
# =============================================================================

# Test: Approve TON for DepositManager
info "Testing TON approve transaction..."
APPROVE_TX=$(cast send $TON \
    "approve(address,uint256)" \
    $DEPOSIT_MANAGER \
    1000000000000000000000 \
    --private-key $DEPLOYER_KEY \
    --rpc-url $L1_RPC \
    --json 2>/dev/null || echo "{}")

APPROVE_STATUS=$(echo $APPROVE_TX | jq -r '.status' 2>/dev/null || echo "")
if [ "$APPROVE_STATUS" == "0x1" ] || [ "$APPROVE_STATUS" == "1" ]; then
    pass "TON approve transaction successful"
else
    fail "TON approve transaction failed"
fi

# Check allowance
ALLOWANCE=$(cast call $TON "allowance(address,address)(uint256)" $DEPLOYER_ADDRESS $DEPOSIT_MANAGER --rpc-url $L1_RPC 2>/dev/null || echo "0")
if [ "$ALLOWANCE" != "0" ]; then
    ALLOWANCE_FORMATTED=$(cast from-wei $ALLOWANCE 2>/dev/null || echo "N/A")
    pass "TON allowance set: $ALLOWANCE_FORMATTED TON"
else
    fail "TON allowance not set"
fi

# =============================================================================
section "6. Docker Container Status"
# =============================================================================

# Check L1 container
if docker ps --format '{{.Names}}' | grep -q "ton-staking-l1"; then
    L1_STATUS=$(docker ps --filter "name=ton-staking-l1" --format "{{.Status}}")
    pass "L1 container running: $L1_STATUS"
else
    fail "L1 container not running"
fi

# Check L2 execution container
if docker ps --format '{{.Names}}' | grep -q "ton-staking-l2-execution"; then
    L2_STATUS=$(docker ps --filter "name=ton-staking-l2-execution" --format "{{.Status}}")
    pass "L2 execution container running: $L2_STATUS"
else
    fail "L2 execution container not running"
fi

# Check L2 node container
if docker ps --format '{{.Names}}' | grep -q "ton-staking-l2-node"; then
    L2_NODE_STATUS=$(docker ps --filter "name=ton-staking-l2-node" --format "{{.Status}}")
    pass "L2 node container running: $L2_NODE_STATUS"
else
    info "L2 node container not running (op-node needs additional configuration)"
fi

# =============================================================================
section "Test Summary"
# =============================================================================

echo ""
TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))
echo -e "Total Tests: $TOTAL_TESTS"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              All Tests Passed Successfully!                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    exit 0
else
    echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║              Some Tests Failed - Check Above               ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
    exit 1
fi
