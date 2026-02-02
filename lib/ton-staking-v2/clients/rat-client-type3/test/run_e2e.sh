#!/bin/bash
# RAT Client E2E Test Runner
# Tests StateLeaf evidence generation with real op-geth state

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== RAT Client E2E Test Runner ===${NC}"

# Configuration
L2_RPC_URL="${L2_RPC_URL:-http://localhost:9545}"
STATE_DB_PATH="${STATE_DB_PATH:-/tmp/op-geth/chaindata}"

# Check if L2 RPC is accessible
echo -e "${YELLOW}Checking L2 RPC connection...${NC}"
if ! curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
    "$L2_RPC_URL" > /dev/null 2>&1; then
    echo -e "${RED}ERROR: L2 RPC not accessible at $L2_RPC_URL${NC}"
    echo "Please ensure op-geth is running"
    echo "You can start it with: docker-compose -f docker-compose.test.yml up -d l2"
    exit 1
fi

echo -e "${GREEN}✓ L2 RPC is accessible${NC}"

# Check if state database exists
echo -e "${YELLOW}Checking state database...${NC}"
if [ ! -d "$STATE_DB_PATH" ]; then
    echo -e "${RED}ERROR: State database not found at $STATE_DB_PATH${NC}"
    echo "Please ensure op-geth is running and STATE_DB_PATH is correct"
    echo "For Docker: STATE_DB_PATH should point to the mounted volume"
    exit 1
fi

echo -e "${GREEN}✓ State database found${NC}"

# Run go mod tidy
echo -e "${YELLOW}Running go mod tidy...${NC}"
cd "$(dirname "$0")/.."
go mod tidy

# Run E2E tests
echo -e "${YELLOW}Running E2E tests...${NC}"
echo "L2_RPC_URL: $L2_RPC_URL"
echo "STATE_DB_PATH: $STATE_DB_PATH"
echo ""

E2E_TEST=1 \
L2_RPC_URL="$L2_RPC_URL" \
STATE_DB_PATH="$STATE_DB_PATH" \
go test -v ./test -run TestStateLeaf -timeout 10m

echo -e "${GREEN}=== E2E Tests Completed ===${NC}"
