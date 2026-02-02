#!/bin/bash
#
# Optimism L1 Deployment Verification Script
# Verifies that all Optimism contracts from addresses.json are properly deployed in allocs-l1.json
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

OPTIMISM_DEVNET_DIR="lib/optimism/.devnet"
ADDRESSES_FILE="$OPTIMISM_DEVNET_DIR/addresses.json"
ALLOCS_FILE="$OPTIMISM_DEVNET_DIR/allocs-l1.json"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Optimism L1 Deployment Verification                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check files exist
if [ ! -f "$ADDRESSES_FILE" ]; then
    echo -e "${RED}✗ Error: $ADDRESSES_FILE not found${NC}"
    echo "Run 'make devnet-allocs-optimism' first"
    exit 1
fi

if [ ! -f "$ALLOCS_FILE" ]; then
    echo -e "${RED}✗ Error: $ALLOCS_FILE not found${NC}"
    echo "Run 'make devnet-allocs-optimism' first"
    exit 1
fi

echo -e "${BLUE}Checking Optimism L1 contracts...${NC}"
echo ""

# Critical contracts that MUST be in allocs
CRITICAL_CONTRACTS=(
    "DisputeGameFactory"
    "DisputeGameFactoryProxy"
    "OptimismPortal"
    "OptimismPortalProxy"
    "SystemConfig"
    "SystemConfigProxy"
    "L1CrossDomainMessenger"
    "L1CrossDomainMessengerProxy"
    "L1StandardBridge"
    "L1StandardBridgeProxy"
)

TOTAL=0
FOUND=0
MISSING=0

for contract in "${CRITICAL_CONTRACTS[@]}"; do
    TOTAL=$((TOTAL + 1))

    # Get address from addresses.json (lowercase, keep 0x prefix)
    ADDR=$(jq -r ".$contract" "$ADDRESSES_FILE" | tr '[:upper:]' '[:lower:]')

    # Check if it's a valid address
    if [ "$ADDR" == "null" ] || [ -z "$ADDR" ] || [ "$ADDR" == "0x0000000000000000000000000000000000000000" ]; then
        echo -e "  ${YELLOW}⊘ $contract: Not in addresses.json${NC}"
        continue
    fi

    # Check if address exists in allocs-l1.json
    if jq -e ".\"$ADDR\"" "$ALLOCS_FILE" > /dev/null 2>&1; then
        # Get code length to verify it's not empty
        CODE=$(jq -r ".\"$ADDR\".code // empty" "$ALLOCS_FILE")
        if [ -n "$CODE" ] && [ "$CODE" != "0x" ]; then
            echo -e "  ${GREEN}✓ $contract${NC}"
            echo -e "    Address: ${BLUE}$ADDR${NC}"
            FOUND=$((FOUND + 1))
        else
            echo -e "  ${YELLOW}⚠ $contract: Address in allocs but no code${NC}"
            echo -e "    Address: ${BLUE}$ADDR${NC}"
            MISSING=$((MISSING + 1))
        fi
    else
        echo -e "  ${RED}✗ $contract: Not in allocs-l1.json${NC}"
        echo -e "    Address: ${BLUE}$ADDR${NC}"
        MISSING=$((MISSING + 1))
    fi
done

echo ""
echo "════════════════════════════════════════════════════════════"
echo -e "Summary: ${GREEN}$FOUND found${NC}, ${RED}$MISSING missing${NC} out of $TOTAL critical contracts"
echo "════════════════════════════════════════════════════════════"

if [ $MISSING -gt 0 ]; then
    echo ""
    echo -e "${RED}⚠ WARNING: Some critical Optimism contracts are missing!${NC}"
    echo -e "${YELLOW}This will cause deployment failures when trying to integrate with Optimism.${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check if lib/optimism devnet-allocs completed successfully"
    echo "  2. Try: make devnet-clean && make devnet-allocs-optimism"
    echo "  3. Check lib/optimism submodule is on correct branch/commit"
    exit 1
else
    echo ""
    echo -e "${GREEN}✓ All critical Optimism L1 contracts are properly deployed in allocs!${NC}"
    exit 0
fi
