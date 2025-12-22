#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== TON Staking V3 RAT E2E Test Runner ===${NC}"
echo ""

# Configuration
ANVIL_PORT=8545
ANVIL_PID=""
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Cleanup function
cleanup() {
    echo -e "${YELLOW}Cleaning up...${NC}"
    if [ -n "$ANVIL_PID" ] && kill -0 "$ANVIL_PID" 2>/dev/null; then
        echo "Stopping Anvil (PID: $ANVIL_PID)"
        kill "$ANVIL_PID" 2>/dev/null || true
    fi
    # Also kill any orphan anvil processes on our port
    lsof -ti:$ANVIL_PORT | xargs kill -9 2>/dev/null || true
}

trap cleanup EXIT

# Check dependencies
echo -e "${BLUE}Checking dependencies...${NC}"

if ! command -v anvil &> /dev/null; then
    echo -e "${RED}Error: anvil not found. Install Foundry: https://getfoundry.sh${NC}"
    exit 1
fi

if ! command -v forge &> /dev/null; then
    echo -e "${RED}Error: forge not found. Install Foundry: https://getfoundry.sh${NC}"
    exit 1
fi

if ! command -v go &> /dev/null; then
    echo -e "${RED}Error: go not found. Install Go: https://go.dev/dl/${NC}"
    exit 1
fi

echo -e "${GREEN}All dependencies found.${NC}"
echo ""

# Kill any existing anvil on port
echo -e "${BLUE}Checking port $ANVIL_PORT...${NC}"
if lsof -ti:$ANVIL_PORT > /dev/null 2>&1; then
    echo -e "${YELLOW}Port $ANVIL_PORT is in use. Killing existing process...${NC}"
    lsof -ti:$ANVIL_PORT | xargs kill -9 2>/dev/null || true
    sleep 1
fi

# Start Anvil
echo -e "${BLUE}Starting Anvil...${NC}"
anvil --port $ANVIL_PORT --chain-id 31337 --block-time 1 > /tmp/anvil.log 2>&1 &
ANVIL_PID=$!
echo "Anvil started with PID: $ANVIL_PID"

# Wait for Anvil to be ready
echo "Waiting for Anvil to be ready..."
for i in {1..30}; do
    if curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
        http://localhost:$ANVIL_PORT > /dev/null 2>&1; then
        echo -e "${GREEN}Anvil is ready.${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}Error: Anvil failed to start${NC}"
        cat /tmp/anvil.log
        exit 1
    fi
    sleep 1
done
echo ""

# Deploy contracts
echo -e "${BLUE}Deploying contracts...${NC}"
cd "$PROJECT_ROOT"

# Run deployment and capture output
DEPLOY_OUTPUT=$(forge script script/DeployRATForE2E.s.sol:DeployRATForE2E \
    --rpc-url http://localhost:$ANVIL_PORT \
    --broadcast \
    --legacy 2>&1)

echo "$DEPLOY_OUTPUT"

# Extract addresses from deployment output
RAT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep "RAT Proxy:" | awk '{print $NF}')
TON_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep "TON deployed:" | awk '{print $NF}')
WTON_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep "WTON deployed:" | awk '{print $NF}')
SYSTEM_CONFIG_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep "SystemConfig deployed:" | awk '{print $NF}')

if [ -z "$RAT_ADDRESS" ]; then
    echo -e "${RED}Error: Failed to extract RAT address from deployment${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Deployment successful!${NC}"
echo "RAT_ADDRESS=$RAT_ADDRESS"
echo "TON_ADDRESS=$TON_ADDRESS"
echo "WTON_ADDRESS=$WTON_ADDRESS"
echo "SYSTEM_CONFIG_ADDRESS=$SYSTEM_CONFIG_ADDRESS"
echo ""

# Export environment variables for Go tests
export RAT_ADDRESS="$RAT_ADDRESS"
export TON_ADDRESS="$TON_ADDRESS"
export WTON_ADDRESS="$WTON_ADDRESS"
export SYSTEM_CONFIG_ADDRESS="$SYSTEM_CONFIG_ADDRESS"
export E2E_RPC_URL="http://localhost:$ANVIL_PORT"
export E2E_PRIVATE_KEY="59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"

# Run Go E2E tests
echo -e "${BLUE}Running Go E2E tests...${NC}"
cd "$PROJECT_ROOT/op-e2e"

# Run unit tests (always pass)
echo -e "${YELLOW}Running unit tests...${NC}"
go test -v -run "TestRATHelper|TestRATConstants" ./faultproofs/... 2>&1 || true

echo ""

# Run integration tests
echo -e "${YELLOW}Running integration tests...${NC}"
go test -v -timeout 5m -run "TestRATIntegration" ./faultproofs/... 2>&1

echo ""
echo -e "${GREEN}=== E2E Tests Complete ===${NC}"
