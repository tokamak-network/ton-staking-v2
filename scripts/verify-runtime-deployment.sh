#!/bin/bash
#
# Runtime Deployment Verification Script
# Verifies that Optimism contracts are actually deployed and have code on the running Anvil instance
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

RPC_URL="${1:-http://localhost:8545}"
ADDRESSES_FILE=".devnet/optimism-addresses.json"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Runtime Optimism L1 Deployment Verification           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if Anvil is running
if ! curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
    "$RPC_URL" > /dev/null 2>&1; then
    echo -e "${RED}✗ Error: Anvil is not running at $RPC_URL${NC}"
    exit 1
fi

CHAIN_ID=$(curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
    "$RPC_URL" | jq -r '.result' | xargs printf "%d")

echo -e "${GREEN}✓ Anvil is running${NC}"
echo -e "  RPC: $RPC_URL"
echo -e "  Chain ID: $CHAIN_ID"
echo ""

# Check addresses file exists
if [ ! -f "$ADDRESSES_FILE" ]; then
    echo -e "${RED}✗ Error: $ADDRESSES_FILE not found${NC}"
    echo "Run 'make devnet-allocs' first"
    exit 1
fi

echo -e "${BLUE}Verifying deployed contracts on Anvil...${NC}"
echo ""

# Critical contracts to verify
CRITICAL_CONTRACTS=(
    "DisputeGameFactoryProxy"
    "OptimismPortalProxy"
    "SystemConfigProxy"
    "L1CrossDomainMessengerProxy"
    "L1StandardBridgeProxy"
)

TOTAL=0
DEPLOYED=0
MISSING=0

for contract in "${CRITICAL_CONTRACTS[@]}"; do
    TOTAL=$((TOTAL + 1))

    # Get address from addresses.json
    ADDR=$(jq -r ".$contract" "$ADDRESSES_FILE")

    # Check if it's a valid address
    if [ "$ADDR" == "null" ] || [ -z "$ADDR" ] || [ "$ADDR" == "0x0000000000000000000000000000000000000000" ]; then
        echo -e "  ${YELLOW}⊘ $contract: Not in addresses.json${NC}"
        continue
    fi

    # Get code from Anvil
    CODE_RESULT=$(curl -s -X POST -H "Content-Type: application/json" \
        --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getCode\",\"params\":[\"$ADDR\",\"latest\"],\"id\":1}" \
        "$RPC_URL" | jq -r '.result')

    if [ -n "$CODE_RESULT" ] && [ "$CODE_RESULT" != "0x" ]; then
        CODE_LEN=${#CODE_RESULT}
        echo -e "  ${GREEN}✓ $contract${NC}"
        echo -e "    Address: ${BLUE}$ADDR${NC}"
        echo -e "    Code length: $CODE_LEN bytes"
        DEPLOYED=$((DEPLOYED + 1))
    else
        echo -e "  ${RED}✗ $contract: No code at address${NC}"
        echo -e "    Address: ${BLUE}$ADDR${NC}"
        MISSING=$((MISSING + 1))
    fi
done

echo ""
echo "════════════════════════════════════════════════════════════"
echo -e "Summary: ${GREEN}$DEPLOYED deployed${NC}, ${RED}$MISSING missing${NC} out of $TOTAL critical contracts"
echo "════════════════════════════════════════════════════════════"

if [ $MISSING -gt 0 ]; then
    echo ""
    echo -e "${RED}⚠ WARNING: Some contracts are not deployed on Anvil!${NC}"
    echo -e "${YELLOW}This indicates allocs-l1.json may not have loaded correctly.${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Stop anvil: make devnet-down"
    echo "  2. Clean and restart: make devnet-clean && make devnet-allocs"
    echo "  3. Check anvil logs: tail -f .devnet/anvil.log"
    exit 1
else
    echo ""
    echo -e "${GREEN}✓ All critical Optimism contracts are deployed and accessible!${NC}"
    exit 0
fi
