#!/bin/bash
# =============================================================================
# TON Staking V3 - Complete System Verification Script
# =============================================================================
# This script performs a comprehensive verification of the entire local
# environment including infrastructure, contracts, and Web UI.
#
# Usage: ./scripts/verify-all.sh
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DEVNET_DIR="$PROJECT_ROOT/.devnet"

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Check results array
declare -a CHECK_RESULTS

# Helper functions
check_start() {
    ((TOTAL_CHECKS++))
    echo -ne "${CYAN}[$TOTAL_CHECKS]${NC} $1... "
}

check_pass() {
    ((PASSED_CHECKS++))
    echo -e "${GREEN}✓ PASS${NC}"
    CHECK_RESULTS+=("✓ $1")
}

check_fail() {
    ((FAILED_CHECKS++))
    echo -e "${RED}✗ FAIL${NC}"
    if [ -n "$2" ]; then
        echo -e "  ${YELLOW}$2${NC}"
    fi
    CHECK_RESULTS+=("✗ $1")
}

section() {
    echo ""
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE} $1${NC}"
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

# Print header
clear
echo -e "${BOLD}${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                                                               ║"
echo "║     TON Staking V3 - Complete System Verification            ║"
echo "║                                                               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${CYAN}Starting comprehensive system verification...${NC}"
echo ""

# =============================================================================
section "1️⃣  Prerequisites Verification"
# =============================================================================

check_start "Foundry (forge) installed"
if command -v forge &> /dev/null; then
    FORGE_VERSION=$(forge --version 2>&1 | head -1)
    check_pass "Foundry installed"
    info "  Version: $FORGE_VERSION"
else
    check_fail "Foundry not installed" "Install: curl -L https://foundry.paradigm.xyz | bash && foundryup"
fi

check_start "Docker daemon running"
if docker ps &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    check_pass "Docker running"
    info "  Version: $DOCKER_VERSION"
else
    check_fail "Docker not running" "Start Docker Desktop or run: sudo systemctl start docker"
fi

check_start "jq installed"
if command -v jq &> /dev/null; then
    JQ_VERSION=$(jq --version)
    check_pass "jq installed"
    info "  Version: $JQ_VERSION"
else
    check_fail "jq not installed" "Install: brew install jq (macOS) or sudo apt-get install jq (Linux)"
fi

# =============================================================================
section "2️⃣  Genesis Files Verification"
# =============================================================================

check_start "Genesis file exists"
if [ -f "$DEVNET_DIR/genesis-l1-staking-v3.json" ]; then
    FILE_SIZE=$(du -h "$DEVNET_DIR/genesis-l1-staking-v3.json" | cut -f1)
    check_pass "Genesis file exists"
    info "  Size: $FILE_SIZE"
else
    check_fail "Genesis file missing" "Run: make devnet-allocs-offline"
fi

check_start "Addresses file exists"
if [ -f "$DEVNET_DIR/addresses.json" ]; then
    check_pass "Addresses file exists"
else
    check_fail "Addresses file missing" "Run: make devnet-allocs-offline"
fi

if [ -f "$DEVNET_DIR/addresses.json" ]; then
    check_start "Contract addresses valid"
    TON=$(jq -r '.ton' "$DEVNET_DIR/addresses.json" 2>/dev/null)
    if [[ $TON =~ ^0x[a-fA-F0-9]{40}$ ]]; then
        check_pass "Contract addresses valid"
    else
        check_fail "Invalid contract addresses" "Regenerate genesis"
    fi
fi

# =============================================================================
section "3️⃣  Docker Containers Verification"
# =============================================================================

check_start "L1 container running"
if docker ps --format '{{.Names}}' | grep -q "ton-staking-l1"; then
    L1_STATUS=$(docker ps --filter "name=ton-staking-l1" --format "{{.Status}}")
    check_pass "L1 container running"
    info "  Status: $L1_STATUS"
else
    check_fail "L1 container not running" "Run: make devnet-start"
fi

check_start "L2 execution container running"
if docker ps --format '{{.Names}}' | grep -q "ton-staking-l2-execution"; then
    L2_STATUS=$(docker ps --filter "name=ton-staking-l2-execution" --format "{{.Status}}")
    check_pass "L2 execution running"
    info "  Status: $L2_STATUS"
else
    check_fail "L2 execution not running" "Run: make devnet-start"
fi

check_start "L2 node container running"
if docker ps --format '{{.Names}}' | grep -q "ton-staking-l2-node"; then
    L2_NODE_STATUS=$(docker ps --filter "name=ton-staking-l2-node" --format "{{.Status}}")
    check_pass "L2 node running"
    info "  Status: $L2_NODE_STATUS"
else
    check_fail "L2 node not running" "Run: make devnet-start"
fi

# =============================================================================
section "4️⃣  Network Connectivity Verification"
# =============================================================================

check_start "L1 RPC accessible (Chain ID)"
L1_CHAIN_ID=$(cast chain-id --rpc-url http://localhost:8545 2>/dev/null || echo "ERROR")
if [ "$L1_CHAIN_ID" == "900" ]; then
    check_pass "L1 RPC accessible"
    info "  Chain ID: $L1_CHAIN_ID"
else
    check_fail "L1 RPC not accessible" "Check if L1 is running: docker-compose logs l1"
fi

check_start "L1 block production"
L1_BLOCK=$(cast block-number --rpc-url http://localhost:8545 2>/dev/null || echo "0")
if [ "$L1_BLOCK" -gt "0" ]; then
    check_pass "L1 producing blocks"
    info "  Current block: $L1_BLOCK"
else
    check_fail "L1 not producing blocks" "Check L1 logs"
fi

check_start "L2 RPC accessible (Chain ID)"
L2_CHAIN_ID=$(cast chain-id --rpc-url http://localhost:9545 2>/dev/null || echo "ERROR")
if [ "$L2_CHAIN_ID" == "901" ]; then
    check_pass "L2 RPC accessible"
    info "  Chain ID: $L2_CHAIN_ID"
else
    check_fail "L2 RPC not accessible" "Check if L2 is running: docker-compose logs l2-execution"
fi

check_start "L2 block production"
L2_BLOCK=$(cast block-number --rpc-url http://localhost:9545 2>/dev/null || echo "0")
if [ "$L2_BLOCK" -gt "0" ]; then
    check_pass "L2 producing blocks"
    info "  Current block: $L2_BLOCK"
else
    check_fail "L2 not producing blocks" "Check L2 logs"
fi

# =============================================================================
section "5️⃣  Token Contracts Verification"
# =============================================================================

if [ -f "$DEVNET_DIR/addresses.json" ]; then
    TON=$(jq -r '.ton' "$DEVNET_DIR/addresses.json")
    WTON=$(jq -r '.wton' "$DEVNET_DIR/addresses.json")
    
    check_start "TON contract deployed"
    TON_NAME=$(cast call $TON "name()(string)" --rpc-url http://localhost:8545 2>/dev/null || echo "ERROR")
    if [ "$TON_NAME" == '"TON"' ]; then
        check_pass "TON contract deployed"
        info "  Address: $TON"
    else
        check_fail "TON contract not deployed"
    fi
    
    check_start "TON symbol correct"
    TON_SYMBOL=$(cast call $TON "symbol()(string)" --rpc-url http://localhost:8545 2>/dev/null || echo "ERROR")
    if [ "$TON_SYMBOL" == '"TON"' ]; then
        check_pass "TON symbol correct"
    else
        check_fail "TON symbol incorrect"
    fi
    
    check_start "WTON contract deployed"
    WTON_NAME=$(cast call $WTON "name()(string)" --rpc-url http://localhost:8545 2>/dev/null || echo "ERROR")
    if [ "$WTON_NAME" == '"Wrapped TON"' ]; then
        check_pass "WTON contract deployed"
        info "  Address: $WTON"
    else
        check_fail "WTON contract not deployed"
    fi
fi

# =============================================================================
section "6️⃣  V3 Manager Contracts Verification"
# =============================================================================

if [ -f "$DEVNET_DIR/addresses.json" ]; then
    SEIG=$(jq -r '.seigManagerProxy' "$DEVNET_DIR/addresses.json")
    DEPOSIT=$(jq -r '.depositManagerProxy' "$DEVNET_DIR/addresses.json")
    LAYER2=$(jq -r '.layer2ManagerProxy' "$DEVNET_DIR/addresses.json")
    
    check_start "SeigManager V3 migrated"
    V3_MIGRATED=$(cast call $SEIG "v3Migrated()(bool)" --rpc-url http://localhost:8545 2>/dev/null || echo "ERROR")
    if [ "$V3_MIGRATED" == "true" ]; then
        check_pass "V3 migration completed"
        info "  SeigManager: $SEIG"
    else
        check_fail "V3 migration not completed" "Expected: true, Got: $V3_MIGRATED"
    fi
    
    check_start "DepositManager deployed"
    DEPOSIT_CODE=$(cast code $DEPOSIT --rpc-url http://localhost:8545 2>/dev/null || echo "0x")
    if [ "$DEPOSIT_CODE" != "0x" ] && [ ${#DEPOSIT_CODE} -gt 10 ]; then
        check_pass "DepositManager deployed"
        info "  Address: $DEPOSIT"
    else
        check_fail "DepositManager not deployed"
    fi
    
    check_start "Layer2Manager deployed"
    LAYER2_CODE=$(cast code $LAYER2 --rpc-url http://localhost:8545 2>/dev/null || echo "0x")
    if [ "$LAYER2_CODE" != "0x" ] && [ ${#LAYER2_CODE} -gt 10 ]; then
        check_pass "Layer2Manager deployed"
        info "  Address: $LAYER2"
    else
        check_fail "Layer2Manager not deployed"
    fi
fi

# =============================================================================
section "7️⃣  RAT Contract Verification"
# =============================================================================

if [ -f "$DEVNET_DIR/addresses.json" ]; then
    RAT=$(jq -r '.ratProxy' "$DEVNET_DIR/addresses.json")
    SYSTEM_CONFIG=$(jq -r '.systemConfig' "$DEVNET_DIR/addresses.json")
    
    check_start "RAT contract deployed"
    RAT_CODE=$(cast code $RAT --rpc-url http://localhost:8545 2>/dev/null || echo "0x")
    if [ "$RAT_CODE" != "0x" ] && [ ${#RAT_CODE} -gt 10 ]; then
        check_pass "RAT deployed"
        info "  Address: $RAT"
    else
        check_fail "RAT not deployed"
    fi
    
    check_start "RAT validator count query"
    VALIDATOR_COUNT=$(cast call $RAT "getValidatorCount(address)(uint256)" $SYSTEM_CONFIG --rpc-url http://localhost:8545 2>/dev/null || echo "ERROR")
    if [ "$VALIDATOR_COUNT" != "ERROR" ]; then
        check_pass "RAT functions working"
        info "  Validator count: $VALIDATOR_COUNT"
    else
        check_fail "RAT function calls failing"
    fi
fi

# =============================================================================
section "8️⃣  Optimism Contracts Verification"
# =============================================================================

if [ -f "$DEVNET_DIR/addresses.json" ]; then
    SYSTEM_CONFIG=$(jq -r '.systemConfig' "$DEVNET_DIR/addresses.json")
    
    check_start "SystemConfig deployed"
    SC_CODE=$(cast code $SYSTEM_CONFIG --rpc-url http://localhost:8545 2>/dev/null || echo "0x")
    if [ "$SC_CODE" != "0x" ] && [ ${#SC_CODE} -gt 10 ]; then
        check_pass "SystemConfig deployed"
        info "  Address: $SYSTEM_CONFIG"
    else
        check_fail "SystemConfig not deployed"
    fi
    
    check_start "Batcher Hash configured"
    BATCHER=$(cast call $SYSTEM_CONFIG "batcherHash()(bytes32)" --rpc-url http://localhost:8545 2>/dev/null || echo "ERROR")
    if [ "$BATCHER" != "ERROR" ] && [ "$BATCHER" != "0x0000000000000000000000000000000000000000000000000000000000000000" ]; then
        check_pass "Batcher Hash configured"
        info "  Hash: ${BATCHER:0:20}..."
    else
        check_fail "Batcher Hash not configured"
    fi
    
    check_start "Unsafe Block Signer configured"
    UNSAFE_SIGNER=$(cast call $SYSTEM_CONFIG "unsafeBlockSigner()(address)" --rpc-url http://localhost:8545 2>/dev/null || echo "ERROR")
    if [ "$UNSAFE_SIGNER" != "ERROR" ] && [ "$UNSAFE_SIGNER" != "0x0000000000000000000000000000000000000000" ]; then
        check_pass "Unsafe Block Signer configured"
        info "  Address: $UNSAFE_SIGNER"
    else
        check_fail "Unsafe Block Signer not configured"
    fi
    
    check_start "Optimism Portal configured"
    PORTAL=$(cast call $SYSTEM_CONFIG "optimismPortal()(address)" --rpc-url http://localhost:8545 2>/dev/null || echo "ERROR")
    if [ "$PORTAL" != "ERROR" ] && [ "$PORTAL" != "0x0000000000000000000000000000000000000000" ]; then
        check_pass "Portal configured"
        
        # Check Portal status
        PORTAL_PAUSED=$(cast call $PORTAL "paused()(bool)" --rpc-url http://localhost:8545 2>/dev/null || echo "ERROR")
        if [ "$PORTAL_PAUSED" == "false" ]; then
            info "  Portal is active (not paused)"
        else
            info "  Portal status: $PORTAL_PAUSED"
        fi
    else
        check_fail "Portal not configured"
    fi
fi

# =============================================================================
section "9️⃣  L2 Predeploy Contracts Verification"
# =============================================================================

L2_RPC="http://localhost:9545"

check_predeploy() {
    local name=$1
    local addr=$2
    local code=$(cast code $addr --rpc-url $L2_RPC 2>/dev/null || echo "0x")
    if [ "$code" != "0x" ] && [ ${#code} -gt 10 ]; then
        return 0
    else
        return 1
    fi
}

check_start "L2 WETH predeploy"
if check_predeploy "WETH" "0x4200000000000000000000000000000000000006"; then
    check_pass "WETH deployed"
    info "  Address: 0x4200000000000000000000000000000000000006"
else
    check_fail "WETH not deployed"
fi

check_start "L2 CrossDomainMessenger predeploy"
if check_predeploy "L2CrossDomainMessenger" "0x4200000000000000000000000000000000000007"; then
    check_pass "L2CrossDomainMessenger deployed"
    info "  Address: 0x4200000000000000000000000000000000000007"
else
    check_fail "L2CrossDomainMessenger not deployed"
fi

check_start "L2 StandardBridge predeploy"
if check_predeploy "L2StandardBridge" "0x4200000000000000000000000000000000000010"; then
    check_pass "L2StandardBridge deployed"
    info "  Address: 0x4200000000000000000000000000000000000010"
else
    check_fail "L2StandardBridge not deployed"
fi

check_start "L1Block predeploy"
if check_predeploy "L1Block" "0x4200000000000000000000000000000000000015"; then
    check_pass "L1Block deployed"
    info "  Address: 0x4200000000000000000000000000000000000015"
else
    check_fail "L1Block not deployed"
fi

check_start "L2ToL1MessagePasser predeploy"
if check_predeploy "L2ToL1MessagePasser" "0x4200000000000000000000000000000000000016"; then
    check_pass "L2ToL1MessagePasser deployed"
    info "  Address: 0x4200000000000000000000000000000000000016"
else
    check_fail "L2ToL1MessagePasser not deployed"
fi

check_start "GasPriceOracle predeploy"
if check_predeploy "GasPriceOracle" "0x420000000000000000000000000000000000000F"; then
    check_pass "GasPriceOracle deployed"
    info "  Address: 0x420000000000000000000000000000000000000F"
else
    check_fail "GasPriceOracle not deployed"
fi

# =============================================================================
section "🔟 Test Account Balances Verification"
# =============================================================================

if [ -f "$DEVNET_DIR/addresses.json" ]; then
    TON=$(jq -r '.ton' "$DEVNET_DIR/addresses.json")
    DEPLOYER="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"

    check_start "Deployer ETH balance"
    ETH_BAL=$(cast balance $DEPLOYER --rpc-url http://localhost:8545 2>/dev/null || echo "0")
    ETH_FORMATTED=$(cast from-wei $ETH_BAL 2>/dev/null || echo "0")
    if (( $(echo "$ETH_FORMATTED > 9000" | bc -l) )); then
        check_pass "Deployer has ETH"
        info "  Balance: $ETH_FORMATTED ETH"
    else
        check_fail "Deployer ETH balance too low" "Expected: ~10000 ETH, Got: $ETH_FORMATTED ETH"
    fi
    
    check_start "Deployer TON balance"
    TON_BAL_RAW=$(cast call $TON "balanceOf(address)(uint256)" $DEPLOYER --rpc-url http://localhost:8545 2>/dev/null || echo "0")
    # Extract numeric value from possible scientific notation like "100000000000000000000000 [1e23]"
    TON_BAL=$(echo "$TON_BAL_RAW" | awk '{print $1}')
    # Convert using Python to handle large numbers
    TON_FORMATTED=$(python3 -c "print(int('$TON_BAL') / 10**18)" 2>/dev/null || echo "0")
    if (( $(echo "$TON_FORMATTED > 90000" | bc -l 2>/dev/null || echo "0") )); then
        check_pass "Deployer has TON"
        info "  Balance: $TON_FORMATTED TON"
    else
        check_fail "Deployer TON balance too low" "Expected: ~100000 TON, Got: $TON_FORMATTED TON"
    fi
fi

# =============================================================================
section "1️⃣1️⃣  Web UI Verification"
# =============================================================================

check_start "Web UI directory exists"
if [ -d "$PROJECT_ROOT/web-ui" ]; then
    check_pass "Web UI directory exists"
else
    check_fail "Web UI directory not found"
fi

check_start "Web UI package.json exists"
if [ -f "$PROJECT_ROOT/web-ui/package.json" ]; then
    check_pass "package.json exists"
else
    check_fail "package.json not found"
fi

check_start "Web UI node_modules installed"
if [ -d "$PROJECT_ROOT/web-ui/node_modules" ]; then
    check_pass "node_modules exists"
else
    check_fail "node_modules not found" "Run: cd web-ui && npm install"
fi

check_start "Web UI config.ts addresses match"
if [ -f "$PROJECT_ROOT/web-ui/src/config.ts" ] && [ -f "$DEVNET_DIR/addresses.json" ]; then
    DEVNET_TON=$(jq -r '.ton' "$DEVNET_DIR/addresses.json")
    CONFIG_TON=$(grep "ton:" "$PROJECT_ROOT/web-ui/src/config.ts" | grep -o '0x[a-fA-F0-9]\{40\}' | head -1)
    
    if [ "$DEVNET_TON" == "$CONFIG_TON" ]; then
        check_pass "config.ts addresses match"
        info "  TON: $CONFIG_TON"
    else
        check_fail "config.ts addresses mismatch" "devnet: $DEVNET_TON, config: $CONFIG_TON"
    fi
else
    check_fail "config.ts or addresses.json not found"
fi

# =============================================================================
section "📊 Verification Summary"
# =============================================================================

echo ""
echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}Total Checks:${NC} $TOTAL_CHECKS"
echo -e "${GREEN}${BOLD}✓ Passed:${NC} ${GREEN}$PASSED_CHECKS${NC}"
echo -e "${RED}${BOLD}✗ Failed:${NC} ${RED}$FAILED_CHECKS${NC}"
echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Calculate success rate
SUCCESS_RATE=$(echo "scale=1; $PASSED_CHECKS * 100 / $TOTAL_CHECKS" | bc)

if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "${GREEN}${BOLD}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                                                           ║"
    echo "║          🎉  ALL VERIFICATION CHECKS PASSED! 🎉          ║"
    echo "║                                                           ║"
    echo "║     TON Staking V3 Local Environment is READY! ✓         ║"
    echo "║                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${CYAN}✓ L1 Network: Running${NC}"
    echo -e "${CYAN}✓ L2 Network: Running${NC}"
    echo -e "${CYAN}✓ All Contracts: Deployed${NC}"
    echo -e "${CYAN}✓ Web UI: Ready${NC}"
    echo ""
    echo -e "${BOLD}Next Steps:${NC}"
    echo "  1. Start Web UI: cd web-ui && npm run dev"
    echo "  2. Open browser: http://localhost:5173"
    echo "  3. Connect MetaMask with test account"
    echo ""
    exit 0
else
    echo -e "${YELLOW}${BOLD}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                                                           ║"
    echo "║          ⚠️  SOME VERIFICATION CHECKS FAILED ⚠️          ║"
    echo "║                                                           ║"
    echo "║        Success Rate: ${SUCCESS_RATE}%                          ║"
    echo "║                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${BOLD}Failed Checks:${NC}"
    for result in "${CHECK_RESULTS[@]}"; do
        if [[ $result == ✗* ]]; then
            echo -e "  ${RED}$result${NC}"
        fi
    done
    echo ""
    echo -e "${BOLD}Recommended Actions:${NC}"
    echo "  1. Review failed checks above"
    echo "  2. Check container logs: docker-compose logs"
    echo "  3. Try full restart: make devnet-stop && make devnet-start"
    echo "  4. If issues persist, see: docs/deployment/local/QUICKSTART.md#문제-해결"
    echo ""
    exit 1
fi
