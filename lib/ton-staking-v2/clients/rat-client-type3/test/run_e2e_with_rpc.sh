#!/bin/bash
# E2E Test with RPC-based Adjacent Leaves Finder
# This script keeps geth running and uses RPC to find adjacent leaves

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== E2E Test with RPC-based Approach ===${NC}"

# Configuration
GETH_DATADIR="/tmp/geth-test-$$"
GETH_PORT=9545
GETH_LOGFILE="/tmp/geth-test-$$.log"
GETH_PID=""

# Cleanup function
cleanup() {
    echo -e "\n${YELLOW}Cleaning up...${NC}"

    if [ ! -z "$GETH_PID" ]; then
        echo "Stopping geth (PID: $GETH_PID)"
        kill $GETH_PID 2>/dev/null || true
        wait $GETH_PID 2>/dev/null || true
    fi

    # Clean up any remaining geth processes
    pkill -f "geth.*$GETH_DATADIR" 2>/dev/null || true

    # Remove data directory
    if [ -d "$GETH_DATADIR" ]; then
        echo "Removing data directory: $GETH_DATADIR"
        rm -rf "$GETH_DATADIR"
    fi

    # Remove log file
    if [ -f "$GETH_LOGFILE" ]; then
        echo "Removing log file: $GETH_LOGFILE"
        rm -f "$GETH_LOGFILE"
    fi

    echo -e "${GREEN}Cleanup complete${NC}"
}

# Set trap to cleanup on exit
trap cleanup EXIT INT TERM

# Check if geth is available
if ! command -v geth &> /dev/null; then
    echo -e "${RED}ERROR: geth not found${NC}"
    echo "Please install geth:"
    echo "  macOS: brew install ethereum"
    echo "  Linux: https://geth.ethereum.org/downloads"
    exit 1
fi

# Start geth in background
echo -e "${YELLOW}Starting geth...${NC}"
echo "Data directory: $GETH_DATADIR"
echo "Log file: $GETH_LOGFILE"

geth --dev \
  --http \
  --http.addr "0.0.0.0" \
  --http.port $GETH_PORT \
  --http.api "eth,net,web3,debug,personal" \
  --datadir "$GETH_DATADIR" \
  --dev.period 0 \
  --gcmode archive \
  --state.scheme hash \
  --verbosity 3 \
  > "$GETH_LOGFILE" 2>&1 &

GETH_PID=$!
echo "Geth started with PID: $GETH_PID"

# Wait for geth to be ready
echo -e "${YELLOW}Waiting for geth to be ready...${NC}"
MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
        http://localhost:$GETH_PORT > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Geth is ready!${NC}"
        break
    fi

    # Check if geth is still running
    if ! kill -0 $GETH_PID 2>/dev/null; then
        echo -e "${RED}ERROR: Geth process died${NC}"
        echo "Last 20 lines of log:"
        tail -20 "$GETH_LOGFILE"
        exit 1
    fi

    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "Waiting... ($RETRY_COUNT/$MAX_RETRIES)"
    sleep 1
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo -e "${RED}ERROR: Geth did not start within 30 seconds${NC}"
    echo "Last 20 lines of log:"
    tail -20 "$GETH_LOGFILE"
    exit 1
fi

# Test RPC connection
echo -e "${YELLOW}Testing RPC connection...${NC}"
CHAIN_ID=$(curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
    http://localhost:$GETH_PORT | grep -o '"result":"[^"]*"' | cut -d'"' -f4)

if [ -z "$CHAIN_ID" ]; then
    echo -e "${RED}ERROR: Could not get chain ID${NC}"
    exit 1
fi

echo -e "${GREEN}✓ RPC connection successful (Chain ID: $CHAIN_ID)${NC}"

# Get dev account (coinbase)
DEV_ACCOUNT=$(curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_coinbase","params":[],"id":1}' \
    http://localhost:$GETH_PORT | grep -o '"result":"[^"]*"' | cut -d'"' -f4)

echo -e "${GREEN}✓ Dev account: $DEV_ACCOUNT${NC}"

# Send transactions to create accounts in state
echo -e "${YELLOW}Sending transactions to populate state...${NC}"

# Send 20 transactions to create new accounts
TX_HASHES=()
for i in {1..20}; do
    TO_ADDR=$(printf "0x%040x" $i)
    TX_HASH=$(curl -s -X POST -H "Content-Type: application/json" \
        --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_sendTransaction\",\"params\":[{\"from\":\"$DEV_ACCOUNT\",\"to\":\"$TO_ADDR\",\"value\":\"0xde0b6b3a7640000\",\"gas\":\"0x5208\"}],\"id\":$i}" \
        http://localhost:$GETH_PORT | grep -o '"result":"[^"]*"' | cut -d'"' -f4)

    if [ ! -z "$TX_HASH" ] && [ "$TX_HASH" != "null" ]; then
        TX_HASHES+=("$TX_HASH")
        echo "  TX $i: $TX_HASH"
    fi
    sleep 0.1
done

echo -e "${GREEN}✓ Sent ${#TX_HASHES[@]} transactions${NC}"

# Wait for transactions to be mined
echo -e "${YELLOW}Waiting for transactions to be mined...${NC}"
sleep 3

# Get current block number
BLOCK_NUM=$(curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
    http://localhost:$GETH_PORT | grep -o '"result":"[^"]*"' | cut -d'"' -f4)

echo -e "${GREEN}✓ Current block: $BLOCK_NUM${NC}"

# Verify accounts exist using debug_accountRange
echo -e "${YELLOW}Verifying accounts via debug_accountRange...${NC}"
ACCOUNT_COUNT=$(curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"debug_accountRange","params":["latest","",1000,false,false,false],"id":1}' \
    http://localhost:$GETH_PORT | grep -o '"accounts":{' | wc -l | tr -d ' ')

if [ "$ACCOUNT_COUNT" -eq "0" ]; then
    echo -e "${RED}ERROR: No accounts found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Accounts verified via debug_accountRange${NC}"

# Run E2E tests while geth is running
echo -e "${YELLOW}Running E2E tests with RPC...${NC}"
echo ""

cd "$(dirname "$0")/.."

# Update go.mod if needed
echo -e "${YELLOW}Updating go dependencies...${NC}"
go mod tidy 2>/dev/null || true

# Run RPC-based tests
E2E_TEST=1 \
L2_RPC_URL="http://localhost:$GETH_PORT" \
go test -v ./test -run TestStateLeafRPC -timeout 10m

TEST_EXIT_CODE=$?

echo ""
if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}=== E2E Tests PASSED ===${NC}"
else
    echo -e "${RED}=== E2E Tests FAILED ===${NC}"
    echo "Geth log file: $GETH_LOGFILE"
    echo "Last 50 lines of geth log:"
    tail -50 "$GETH_LOGFILE"
fi

# Cleanup will happen via trap
exit $TEST_EXIT_CODE
