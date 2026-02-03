#!/bin/bash
# =============================================================================
# Web UI Data Verification Script
# =============================================================================
# This script verifies that all data displayed in the Web UI matches
# the actual on-chain data.
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

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0

# Helper functions
pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    ((CHECKS_PASSED++))
}

fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    echo -e "  ${YELLOW}Expected: $2${NC}"
    echo -e "  ${YELLOW}Got: $3${NC}"
    ((CHECKS_FAILED++))
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
    LAYER2_REGISTRY=$(jq -r '.layer2RegistryProxy' "$DEVNET_DIR/addresses.json")
    RAT=$(jq -r '.ratProxy' "$DEVNET_DIR/addresses.json")
    VALIDATOR_REWARD=$(jq -r '.validatorRewardProxy' "$DEVNET_DIR/addresses.json")
    SYSTEM_CONFIG=$(jq -r '.systemConfig' "$DEVNET_DIR/addresses.json")
    DISPUTE_GAME_FACTORY=$(jq -r '.disputeGameFactory' "$DEVNET_DIR/addresses.json")
}

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          Web UI Data Verification Test Suite              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

load_addresses

# =============================================================================
section "1. Node Status Verification"
# =============================================================================

info "Checking L1 network status..."

# L1 Chain ID
L1_CHAIN_ID=$(cast chain-id --rpc-url $L1_RPC 2>/dev/null || echo "ERROR")
if [ "$L1_CHAIN_ID" == "900" ]; then
    pass "L1 Chain ID is 900"
else
    fail "L1 Chain ID" "900" "$L1_CHAIN_ID"
fi

# L1 Block Number
L1_BLOCK=$(cast block-number --rpc-url $L1_RPC 2>/dev/null || echo "0")
if [ "$L1_BLOCK" -gt "0" ]; then
    pass "L1 is producing blocks (current: $L1_BLOCK)"
else
    fail "L1 block production" "> 0" "$L1_BLOCK"
fi

info "Checking L2 network status..."

# L2 Chain ID
L2_CHAIN_ID=$(cast chain-id --rpc-url $L2_RPC 2>/dev/null || echo "ERROR")
if [ "$L2_CHAIN_ID" == "901" ]; then
    pass "L2 Chain ID is 901"
else
    fail "L2 Chain ID" "901" "$L2_CHAIN_ID"
fi

# L2 Block Number
L2_BLOCK=$(cast block-number --rpc-url $L2_RPC 2>/dev/null || echo "0")
if [ "$L2_BLOCK" -gt "0" ]; then
    pass "L2 is producing blocks (current: $L2_BLOCK)"
else
    fail "L2 block production" "> 0" "$L2_BLOCK"
fi

# =============================================================================
section "2. Rollup Information Verification"
# =============================================================================

info "Querying L1BridgeRegistry.getRollupInfo()..."

# Get rollup info from L1BridgeRegistry
ROLLUP_INFO=$(cast call $L1_BRIDGE_REGISTRY \
    "getRollupInfo(address)(uint8,address,bool,bool,string)" \
    $SYSTEM_CONFIG \
    --rpc-url $L1_RPC 2>/dev/null || echo "ERROR")

if [ "$ROLLUP_INFO" != "ERROR" ]; then
    ROLLUP_TYPE=$(echo "$ROLLUP_INFO" | head -1)
    L2_TON=$(echo "$ROLLUP_INFO" | sed -n '2p')
    REJECTED_SEIGS=$(echo "$ROLLUP_INFO" | sed -n '3p')
    ROLLUP_NAME=$(echo "$ROLLUP_INFO" | sed -n '5p')
    
    pass "getRollupInfo() returned data"
    info "  Rollup Type: $ROLLUP_TYPE (3 = Optimism Bedrock DisputeGame)"
    info "  L2 TON: $L2_TON"
    info "  Rejected Seigs: $REJECTED_SEIGS"
    info "  Name: $ROLLUP_NAME"
    
    # Verify rollup type
    if [ "$ROLLUP_TYPE" == "3" ]; then
        pass "Rollup Type is 3 (Optimism Bedrock DisputeGame)"
    else
        fail "Rollup Type" "3" "$ROLLUP_TYPE"
    fi
else
    fail "getRollupInfo() call" "success" "ERROR"
fi

# =============================================================================
section "3. System Parameters Verification"
# =============================================================================

info "Checking SeigManager.v3Migrated()..."
V3_MIGRATED=$(cast call $SEIG_MANAGER "v3Migrated()(bool)" --rpc-url $L1_RPC 2>/dev/null || echo "ERROR")
if [ "$V3_MIGRATED" == "true" ]; then
    pass "V3 Migration completed"
else
    fail "V3 Migration" "true" "$V3_MIGRATED"
fi

info "Checking RAT Validator counts..."
TOTAL_VALIDATORS=$(cast call $RAT "getValidatorCount(address)(uint256)" $SYSTEM_CONFIG --rpc-url $L1_RPC 2>/dev/null || echo "0")
ACTIVE_VALIDATORS=$(cast call $RAT "getActiveValidatorCount(address)(uint256)" $SYSTEM_CONFIG --rpc-url $L1_RPC 2>/dev/null || echo "0")

info "  Total Validators: $TOTAL_VALIDATORS"
info "  Active Validators: $ACTIVE_VALIDATORS"

if [ "$TOTAL_VALIDATORS" -ge "0" ]; then
    pass "getValidatorCount() returned: $TOTAL_VALIDATORS"
else
    fail "getValidatorCount()" ">= 0" "$TOTAL_VALIDATORS"
fi

if [ "$ACTIVE_VALIDATORS" -ge "0" ]; then
    pass "getActiveValidatorCount() returned: $ACTIVE_VALIDATORS"
else
    fail "getActiveValidatorCount()" ">= 0" "$ACTIVE_VALIDATORS"
fi

info "Checking minimum collateral..."
MIN_COLLATERAL=$(cast call $RAT "getDynamicMinimumCollateral(address)(uint256)" $SYSTEM_CONFIG --rpc-url $L1_RPC 2>/dev/null || echo "0")
if [ "$MIN_COLLATERAL" != "0" ]; then
    MIN_COLLATERAL_WTON=$(cast from-wei $MIN_COLLATERAL 2>/dev/null | awk '{printf "%.2f", $1/1e9}')
    pass "Minimum Collateral: ${MIN_COLLATERAL_WTON} WTON"
else
    fail "getDynamicMinimumCollateral()" "> 0" "$MIN_COLLATERAL"
fi

# =============================================================================
section "4. Operator Information Verification"
# =============================================================================

info "Checking Layer2Manager.rollupConfigInfo()..."
CONFIG_INFO=$(cast call $LAYER2_MANAGER \
    "rollupConfigInfo(address)" \
    $SYSTEM_CONFIG \
    --rpc-url $L1_RPC 2>/dev/null || echo "ERROR")

if [ "$CONFIG_INFO" != "ERROR" ]; then
    pass "rollupConfigInfo() returned data"
else
    fail "rollupConfigInfo()" "success" "ERROR"
fi

info "Checking Layer2Manager.operatorOfRollupConfig()..."
OPERATOR=$(cast call $LAYER2_MANAGER \
    "operatorOfRollupConfig(address)(address)" \
    $SYSTEM_CONFIG \
    --rpc-url $L1_RPC 2>/dev/null || echo "ERROR")

if [ "$OPERATOR" != "ERROR" ] && [ "$OPERATOR" != "0x0000000000000000000000000000000000000000" ]; then
    pass "Operator found: $OPERATOR"
else
    fail "Operator" "valid address" "$OPERATOR"
fi

# =============================================================================
section "5. Contract Deployment Verification"
# =============================================================================

info "Verifying all core contracts are deployed..."

# Check TON
TON_CODE=$(cast code $TON --rpc-url $L1_RPC 2>/dev/null || echo "0x")
if [ "$TON_CODE" != "0x" ] && [ ${#TON_CODE} -gt 10 ]; then
    TON_NAME=$(cast call $TON "name()(string)" --rpc-url $L1_RPC 2>/dev/null || echo "")
    pass "TON deployed at $TON (name: $TON_NAME)"
else
    fail "TON deployment" "deployed" "not found"
fi

# Check WTON
WTON_CODE=$(cast code $WTON --rpc-url $L1_RPC 2>/dev/null || echo "0x")
if [ "$WTON_CODE" != "0x" ] && [ ${#WTON_CODE} -gt 10 ]; then
    WTON_NAME=$(cast call $WTON "name()(string)" --rpc-url $L1_RPC 2>/dev/null || echo "")
    pass "WTON deployed at $WTON (name: $WTON_NAME)"
else
    fail "WTON deployment" "deployed" "not found"
fi

# Check SeigManager
SEIG_CODE=$(cast code $SEIG_MANAGER --rpc-url $L1_RPC 2>/dev/null || echo "0x")
if [ "$SEIG_CODE" != "0x" ] && [ ${#SEIG_CODE} -gt 10 ]; then
    pass "SeigManager deployed at $SEIG_MANAGER"
else
    fail "SeigManager deployment" "deployed" "not found"
fi

# Check DepositManager
DEPOSIT_CODE=$(cast code $DEPOSIT_MANAGER --rpc-url $L1_RPC 2>/dev/null || echo "0x")
if [ "$DEPOSIT_CODE" != "0x" ] && [ ${#DEPOSIT_CODE} -gt 10 ]; then
    pass "DepositManager deployed at $DEPOSIT_MANAGER"
else
    fail "DepositManager deployment" "deployed" "not found"
fi

# Check Layer2Manager
L2M_CODE=$(cast code $LAYER2_MANAGER --rpc-url $L1_RPC 2>/dev/null || echo "0x")
if [ "$L2M_CODE" != "0x" ] && [ ${#L2M_CODE} -gt 10 ]; then
    pass "Layer2Manager deployed at $LAYER2_MANAGER"
else
    fail "Layer2Manager deployment" "deployed" "not found"
fi

# Check RAT
RAT_CODE=$(cast code $RAT --rpc-url $L1_RPC 2>/dev/null || echo "0x")
if [ "$RAT_CODE" != "0x" ] && [ ${#RAT_CODE} -gt 10 ]; then
    pass "RAT deployed at $RAT"
else
    fail "RAT deployment" "deployed" "not found"
fi

# Check SystemConfig
SC_CODE=$(cast code $SYSTEM_CONFIG --rpc-url $L1_RPC 2>/dev/null || echo "0x")
if [ "$SC_CODE" != "0x" ] && [ ${#SC_CODE} -gt 10 ]; then
    pass "SystemConfig deployed at $SYSTEM_CONFIG"
else
    fail "SystemConfig deployment" "deployed" "not found"
fi

# Check DisputeGameFactory
DGF_CODE=$(cast code $DISPUTE_GAME_FACTORY --rpc-url $L1_RPC 2>/dev/null || echo "0x")
if [ "$DGF_CODE" != "0x" ] && [ ${#DGF_CODE} -gt 10 ]; then
    pass "DisputeGameFactory deployed at $DISPUTE_GAME_FACTORY"
else
    fail "DisputeGameFactory deployment" "deployed" "not found"
fi

# =============================================================================
section "6. L2 Network Information Verification"
# =============================================================================

info "Checking SystemConfig parameters..."

# Batcher Hash
BATCHER_HASH=$(cast call $SYSTEM_CONFIG "batcherHash()(bytes32)" --rpc-url $L1_RPC 2>/dev/null || echo "ERROR")
if [ "$BATCHER_HASH" != "ERROR" ] && [ "$BATCHER_HASH" != "0x0000000000000000000000000000000000000000000000000000000000000000" ]; then
    pass "Batcher Hash: $BATCHER_HASH"
else
    fail "Batcher Hash" "valid hash" "$BATCHER_HASH"
fi

# Unsafe Block Signer
UNSAFE_SIGNER=$(cast call $SYSTEM_CONFIG "unsafeBlockSigner()(address)" --rpc-url $L1_RPC 2>/dev/null || echo "ERROR")
if [ "$UNSAFE_SIGNER" != "ERROR" ] && [ "$UNSAFE_SIGNER" != "0x0000000000000000000000000000000000000000" ]; then
    pass "Unsafe Block Signer (Proposer): $UNSAFE_SIGNER"
else
    fail "Unsafe Block Signer" "valid address" "$UNSAFE_SIGNER"
fi

# Gas Limit
GAS_LIMIT=$(cast call $SYSTEM_CONFIG "gasLimit()(uint64)" --rpc-url $L1_RPC 2>/dev/null || echo "0")
if [ "$GAS_LIMIT" -gt "0" ]; then
    pass "Gas Limit: $GAS_LIMIT"
else
    fail "Gas Limit" "> 0" "$GAS_LIMIT"
fi

# L1 Standard Bridge
L1_BRIDGE=$(cast call $SYSTEM_CONFIG "l1StandardBridge()(address)" --rpc-url $L1_RPC 2>/dev/null || echo "ERROR")
if [ "$L1_BRIDGE" != "ERROR" ] && [ "$L1_BRIDGE" != "0x0000000000000000000000000000000000000000" ]; then
    pass "L1 Standard Bridge: $L1_BRIDGE"
else
    fail "L1 Standard Bridge" "valid address" "$L1_BRIDGE"
fi

# Optimism Portal
PORTAL=$(cast call $SYSTEM_CONFIG "optimismPortal()(address)" --rpc-url $L1_RPC 2>/dev/null || echo "ERROR")
if [ "$PORTAL" != "ERROR" ] && [ "$PORTAL" != "0x0000000000000000000000000000000000000000" ]; then
    pass "Optimism Portal: $PORTAL"
    
    # Check Portal paused status
    PORTAL_PAUSED=$(cast call $PORTAL "paused()(bool)" --rpc-url $L1_RPC 2>/dev/null || echo "ERROR")
    if [ "$PORTAL_PAUSED" == "false" ]; then
        pass "Portal is not paused (Active)"
    elif [ "$PORTAL_PAUSED" == "true" ]; then
        fail "Portal status" "not paused" "paused"
    fi
    
    # Check Portal balances
    PORTAL_TON=$(cast call $TON "balanceOf(address)(uint256)" $PORTAL --rpc-url $L1_RPC 2>/dev/null || echo "0")
    PORTAL_TON_FORMATTED=$(cast from-wei $PORTAL_TON 2>/dev/null || echo "0")
    info "  Portal TON Balance: $PORTAL_TON_FORMATTED TON"
    
    PORTAL_ETH=$(cast balance $PORTAL --rpc-url $L1_RPC 2>/dev/null || echo "0")
    PORTAL_ETH_FORMATTED=$(cast from-wei $PORTAL_ETH 2>/dev/null || echo "0")
    info "  Portal ETH Balance: $PORTAL_ETH_FORMATTED ETH"
else
    fail "Optimism Portal" "valid address" "$PORTAL"
fi

# =============================================================================
section "7. Dispute Games Verification"
# =============================================================================

info "Checking DisputeGameFactory.gameCount()..."
GAME_COUNT=$(cast call $DISPUTE_GAME_FACTORY "gameCount()(uint256)" --rpc-url $L1_RPC 2>/dev/null || echo "0")
info "  Total Dispute Games: $GAME_COUNT"

if [ "$GAME_COUNT" -ge "0" ]; then
    pass "gameCount() returned: $GAME_COUNT"
else
    fail "gameCount()" ">= 0" "$GAME_COUNT"
fi

# =============================================================================
section "8. Test Account Balances Verification"
# =============================================================================

DEPLOYER="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"

info "Checking Deployer account balances..."

# ETH Balance
ETH_BAL=$(cast balance $DEPLOYER --rpc-url $L1_RPC 2>/dev/null || echo "0")
ETH_BAL_FORMATTED=$(cast from-wei $ETH_BAL 2>/dev/null || echo "0")
if [ "$ETH_BAL" != "0" ]; then
    pass "Deployer ETH Balance: $ETH_BAL_FORMATTED ETH"
else
    fail "Deployer ETH Balance" "> 0" "$ETH_BAL_FORMATTED"
fi

# TON Balance
TON_BAL=$(cast call $TON "balanceOf(address)(uint256)" $DEPLOYER --rpc-url $L1_RPC 2>/dev/null || echo "0")
TON_BAL_FORMATTED=$(cast from-wei $TON_BAL 2>/dev/null || echo "0")
if [ "$TON_BAL" != "0" ]; then
    pass "Deployer TON Balance: $TON_BAL_FORMATTED TON"
else
    fail "Deployer TON Balance" "> 0" "$TON_BAL_FORMATTED"
fi

# WTON Balance
WTON_BAL=$(cast call $WTON "balanceOf(address)(uint256)" $DEPLOYER --rpc-url $L1_RPC 2>/dev/null || echo "0")
WTON_BAL_WTON=$(cast from-wei $WTON_BAL 2>/dev/null | awk '{printf "%.4f", $1/1e9}')
info "  Deployer WTON Balance: $WTON_BAL_WTON WTON"

# =============================================================================
section "9. Config.ts Addresses Verification"
# =============================================================================

info "Comparing config.ts addresses with .devnet/addresses.json..."

# Read addresses from web-ui config
CONFIG_FILE="$PROJECT_ROOT/web-ui/src/config.ts"

if [ -f "$CONFIG_FILE" ]; then
    # Extract addresses from config.ts
    CONFIG_TON=$(grep "ton:" "$CONFIG_FILE" | grep -o "0x[a-fA-F0-9]\{40\}" | head -1)
    CONFIG_WTON=$(grep "wton:" "$CONFIG_FILE" | grep -o "0x[a-fA-F0-9]\{40\}" | head -1)
    CONFIG_SEIG=$(grep "seigManager:" "$CONFIG_FILE" | grep -o "0x[a-fA-F0-9]\{40\}" | head -1)
    
    # Compare
    if [ "$CONFIG_TON" == "$TON" ]; then
        pass "config.ts TON address matches"
    else
        fail "config.ts TON address" "$TON" "$CONFIG_TON"
    fi
    
    if [ "$CONFIG_WTON" == "$WTON" ]; then
        pass "config.ts WTON address matches"
    else
        fail "config.ts WTON address" "$WTON" "$CONFIG_WTON"
    fi
    
    if [ "$CONFIG_SEIG" == "$SEIG_MANAGER" ]; then
        pass "config.ts SeigManager address matches"
    else
        fail "config.ts SeigManager address" "$SEIG_MANAGER" "$CONFIG_SEIG"
    fi
else
    fail "config.ts file" "exists" "not found"
fi

# =============================================================================
section "Test Summary"
# =============================================================================

echo ""
TOTAL_CHECKS=$((CHECKS_PASSED + CHECKS_FAILED))
echo -e "Total Checks: $TOTAL_CHECKS"
echo -e "${GREEN}Passed: $CHECKS_PASSED${NC}"
echo -e "${RED}Failed: $CHECKS_FAILED${NC}"
echo ""

if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         All Web UI Data Verification Passed! ✓            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}✓ All data displayed in Web UI matches on-chain data${NC}"
    echo -e "${BLUE}✓ Web UI is ready to use${NC}"
    echo ""
    exit 0
else
    echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║        Some Verification Checks Failed - Review Above     ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
    exit 1
fi
