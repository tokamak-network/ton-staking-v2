#!/bin/bash
# =============================================================================
# Web UI Config 검증 스크립트
# config.ts의 모든 컨트랙트 주소가 .devnet/addresses.json과 일치하는지 확인
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ADDRESSES_FILE="$PROJECT_ROOT/.devnet/addresses.json"
CONFIG_FILE="$PROJECT_ROOT/web-ui/src/config.ts"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Web UI Config Verification Script                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if files exist
if [ ! -f "$ADDRESSES_FILE" ]; then
    echo -e "${RED}✗ Addresses file not found: $ADDRESSES_FILE${NC}"
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}✗ Config file not found: $CONFIG_FILE${NC}"
    exit 1
fi

echo -e "${CYAN}Addresses File: ${NC}$ADDRESSES_FILE"
echo -e "${CYAN}Config File:    ${NC}$CONFIG_FILE"
echo ""

# Contract mapping: config_key:devnet_key:display_name
CONTRACTS=(
    "ton:ton:TON Token"
    "wton:wton:WTON Token"
    "seigManager:seigManagerProxy:SeigManager V3"
    "depositManager:depositManagerProxy:DepositManager V3"
    "layer2Manager:layer2ManagerProxy:Layer2Manager V3"
    "l1BridgeRegistry:l1BridgeRegistryProxy:L1BridgeRegistry V1_2"
    "layer2Registry:layer2RegistryProxy:Layer2Registry"
    "rat:ratProxy:RAT Contract"
    "validatorReward:validatorRewardProxy:ValidatorReward V1"
    "systemConfig:systemConfig:SystemConfig"
    "disputeGameFactory:disputeGameFactory:DisputeGameFactory"
)

PASSED=0
FAILED=0
TOTAL=${#CONTRACTS[@]}

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Verifying Contract Addresses${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

for contract in "${CONTRACTS[@]}"; do
    IFS=':' read -r config_key devnet_key display_name <<< "$contract"
    
    # Get address from devnet
    DEVNET_ADDR=$(jq -r ".$devnet_key" "$ADDRESSES_FILE" 2>/dev/null)
    
    if [ "$DEVNET_ADDR" == "null" ] || [ -z "$DEVNET_ADDR" ]; then
        echo -e "${YELLOW}⚠${NC}  $display_name: ${YELLOW}NOT FOUND in devnet addresses${NC}"
        ((FAILED++))
        continue
    fi
    
    # Get address from config.ts
    # Extract the line with the config key and get the address
    CONFIG_ADDR=$(grep -E "^\s*${config_key}:" "$CONFIG_FILE" | grep -oE '0x[a-fA-F0-9]{40}' | head -1)
    
    if [ -z "$CONFIG_ADDR" ]; then
        echo -e "${RED}✗${NC}  $display_name: ${RED}NOT FOUND in config.ts${NC}"
        ((FAILED++))
        continue
    fi
    
    # Compare addresses (case-insensitive)
    DEVNET_LOWER=$(echo "$DEVNET_ADDR" | tr '[:upper:]' '[:lower:]')
    CONFIG_LOWER=$(echo "$CONFIG_ADDR" | tr '[:upper:]' '[:lower:]')
    if [ "$DEVNET_LOWER" == "$CONFIG_LOWER" ]; then
        echo -e "${GREEN}✓${NC}  $display_name"
        echo -e "${CYAN}   Devnet:${NC} $DEVNET_ADDR"
        echo -e "${CYAN}   Config:${NC} $CONFIG_ADDR"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC}  $display_name: ${RED}MISMATCH${NC}"
        echo -e "${CYAN}   Devnet:${NC} $DEVNET_ADDR"
        echo -e "${CYAN}   Config:${NC} $CONFIG_ADDR"
        ((FAILED++))
    fi
    echo ""
done

# Network configuration verification
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Verifying Network Configuration${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# chainId
CHAIN_ID=$(grep -E "^\s*chainId:" "$CONFIG_FILE" | grep -oE '[0-9]+' | head -1)
if [ "$CHAIN_ID" == "900" ]; then
    echo -e "${GREEN}✓${NC}  chainId: $CHAIN_ID"
else
    echo -e "${RED}✗${NC}  chainId: $CHAIN_ID ${RED}(Expected: 900)${NC}"
    ((FAILED++))
fi

# rpcUrl
RPC_URL=$(grep -E "^\s*rpcUrl:" "$CONFIG_FILE" | grep -oE "'[^']+'" | tr -d "'")
if [ "$RPC_URL" == "http://localhost:8545" ]; then
    echo -e "${GREEN}✓${NC}  rpcUrl: $RPC_URL"
else
    echo -e "${RED}✗${NC}  rpcUrl: $RPC_URL ${RED}(Expected: http://localhost:8545)${NC}"
    ((FAILED++))
fi

# l2RpcUrl
L2_RPC_URL=$(grep -E "^\s*l2RpcUrl:" "$CONFIG_FILE" | grep -oE "'[^']+'" | tr -d "'")
if [ "$L2_RPC_URL" == "http://localhost:9545" ]; then
    echo -e "${GREEN}✓${NC}  l2RpcUrl: $L2_RPC_URL"
else
    echo -e "${RED}✗${NC}  l2RpcUrl: $L2_RPC_URL ${RED}(Expected: http://localhost:9545)${NC}"
    ((FAILED++))
fi

# chainName
CHAIN_NAME=$(grep -E "^\s*chainName:" "$CONFIG_FILE" | grep -oE "'[^']+'" | tr -d "'")
if [ -n "$CHAIN_NAME" ]; then
    echo -e "${GREEN}✓${NC}  chainName: '$CHAIN_NAME'"
else
    echo -e "${RED}✗${NC}  chainName: ${RED}NOT SET${NC}"
    ((FAILED++))
fi

echo ""

# Test Accounts verification
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Verifying Test Accounts${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Count test accounts in config.ts
TEST_ACCOUNTS_COUNT=$(grep -c "address:" "$CONFIG_FILE" | head -1 || echo "0")

if [ "$TEST_ACCOUNTS_COUNT" -ge 5 ]; then
    echo -e "${GREEN}✓${NC}  Test Accounts: $TEST_ACCOUNTS_COUNT accounts defined"
else
    echo -e "${YELLOW}⚠${NC}  Test Accounts: $TEST_ACCOUNTS_COUNT accounts (Expected: at least 5)"
fi

# Verify specific test accounts
EXPECTED_ACCOUNTS=(
    "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266:Deployer/Operator"
    "0x70997970C51812dc3A010C7d01b50e0d17dc79C8:TON Staking Deployer"
    "0x90F79bf6EB2c4f870365E785982E1f101E93b906:Validator #1"
)

for account in "${EXPECTED_ACCOUNTS[@]}"; do
    IFS=':' read -r addr name <<< "$account"
    if grep -q "$addr" "$CONFIG_FILE"; then
        echo -e "${GREEN}✓${NC}  $name: $addr"
    else
        echo -e "${YELLOW}⚠${NC}  $name: ${YELLOW}NOT FOUND${NC}"
    fi
done

echo ""

# Summary
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Verification Summary${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "Total Contract Addresses: $TOTAL"
echo -e "${GREEN}Passed:${NC} $PASSED"
echo -e "${RED}Failed:${NC} $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                          ║${NC}"
    echo -e "${GREEN}║          ✅  ALL VERIFICATIONS PASSED! ✅               ║${NC}"
    echo -e "${GREEN}║                                                          ║${NC}"
    echo -e "${GREEN}║     Web UI config.ts is correctly configured! ✓          ║${NC}"
    echo -e "${GREEN}║                                                          ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                                                          ║${NC}"
    echo -e "${RED}║          ❌  VERIFICATION FAILED! ❌                     ║${NC}"
    echo -e "${RED}║                                                          ║${NC}"
    echo -e "${RED}║     Please fix the mismatched addresses above.          ║${NC}"
    echo -e "${RED}║                                                          ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}To fix:${NC}"
    echo -e "1. Check .devnet/addresses.json for correct addresses"
    echo -e "2. Update web-ui/src/config.ts with matching addresses"
    echo -e "3. Re-run this script to verify"
    echo ""
    exit 1
fi
