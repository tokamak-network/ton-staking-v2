#!/bin/bash
# Automated E2E Test with Local Geth
# This script starts geth, runs tests, and cleans up

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Automated E2E Test with Geth ===${NC}"

# Configuration
GETH_DATADIR="/tmp/geth-test-$$"  # Use PID for unique dir
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

    # Remove data directory (including test snapshot)
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

# Wait for state database to be ready
echo -e "${YELLOW}Waiting for state database to initialize...${NC}"
sleep 5

# Check if chaindata exists
CHAINDATA_PATH="$GETH_DATADIR/geth/chaindata"
if [ ! -d "$CHAINDATA_PATH" ]; then
    echo -e "${RED}ERROR: Chaindata directory not found at $CHAINDATA_PATH${NC}"
    exit 1
fi

# Wait for database files to be created (check for CURRENT file which indicates DB is initialized)
RETRY_DB=0
MAX_DB_RETRIES=10
while [ $RETRY_DB -lt $MAX_DB_RETRIES ]; do
    if [ -f "$CHAINDATA_PATH/CURRENT" ]; then
        break
    fi
    echo "Waiting for database files... ($((RETRY_DB + 1))/$MAX_DB_RETRIES)"
    sleep 1
    RETRY_DB=$((RETRY_DB + 1))
done

if [ ! -f "$CHAINDATA_PATH/CURRENT" ]; then
    echo -e "${RED}ERROR: Database not properly initialized${NC}"
    exit 1
fi

echo -e "${GREEN}✓ State database found at $CHAINDATA_PATH${NC}"

# Get dev account (coinbase)
DEV_ACCOUNT=$(curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_coinbase","params":[],"id":1}' \
    http://localhost:$GETH_PORT | grep -o '"result":"[^"]*"' | cut -d'"' -f4)

echo -e "${GREEN}✓ Dev account: $DEV_ACCOUNT${NC}"

# Send transactions to create accounts in state
echo -e "${YELLOW}Sending transactions to populate state...${NC}"

# Send transactions to create new accounts
TX_HASHES=()
for i in {1..10}; do
    TO_ADDR=$(printf "0x%040x" $i)
    TX_HASH=$(curl -s -X POST -H "Content-Type: application/json" \
        --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_sendTransaction\",\"params\":[{\"from\":\"$DEV_ACCOUNT\",\"to\":\"$TO_ADDR\",\"value\":\"0xde0b6b3a7640000\",\"gas\":\"0x5208\"}],\"id\":$i}" \
        http://localhost:$GETH_PORT | grep -o '"result":"[^"]*"' | cut -d'"' -f4)

    if [ ! -z "$TX_HASH" ] && [ "$TX_HASH" != "null" ]; then
        TX_HASHES+=("$TX_HASH")
        echo "  TX $i: $TX_HASH"
    fi
    sleep 0.2
done

echo -e "${GREEN}✓ Sent ${#TX_HASHES[@]} transactions${NC}"

# Wait for transactions to be mined
echo -e "${YELLOW}Waiting for transactions to be mined...${NC}"
sleep 3

# Verify transactions were mined
MINED_COUNT=0
for tx_hash in "${TX_HASHES[@]}"; do
    RECEIPT=$(curl -s -X POST -H "Content-Type: application/json" \
        --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getTransactionReceipt\",\"params\":[\"$tx_hash\"],\"id\":1}" \
        http://localhost:$GETH_PORT | grep -o '"blockNumber":"[^"]*"' | cut -d'"' -f4)

    if [ ! -z "$RECEIPT" ] && [ "$RECEIPT" != "null" ]; then
        MINED_COUNT=$((MINED_COUNT + 1))
    fi
done

echo -e "${GREEN}✓ Mined $MINED_COUNT transactions${NC}"

# Check dev account balance to verify state is working
BALANCE=$(curl -s -X POST -H "Content-Type: application/json" \
    --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getBalance\",\"params\":[\"$DEV_ACCOUNT\",\"latest\"],\"id\":1}" \
    http://localhost:$GETH_PORT | grep -o '"result":"[^"]*"' | cut -d'"' -f4)

echo -e "${GREEN}✓ Dev account balance: $BALANCE${NC}"

# Force geth to commit state to disk by generating more blocks
echo -e "${YELLOW}Forcing state commit by generating more blocks...${NC}"
# Send a few more transactions to trigger block production and state commits
for i in {11..20}; do
    TO_ADDR=$(printf "0x%040x" $i)
    curl -s -X POST -H "Content-Type: application/json" \
        --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_sendTransaction\",\"params\":[{\"from\":\"$DEV_ACCOUNT\",\"to\":\"$TO_ADDR\",\"value\":\"0xde0b6b3a7640000\",\"gas\":\"0x5208\"}],\"id\":$i}" \
        http://localhost:$GETH_PORT > /dev/null
    sleep 0.2
done

echo -e "${GREEN}✓ Sent 10 more transactions${NC}"

# Wait for blocks to be mined and state to be committed
sleep 5

# NOW get the final block number and state root AFTER all transactions
echo -e "${YELLOW}Getting final block number and state root...${NC}"
BLOCK_NUM=$(curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
    http://localhost:$GETH_PORT | grep -o '"result":"[^"]*"' | cut -d'"' -f4)

echo -e "${GREEN}✓ Final block: $BLOCK_NUM${NC}"

# Get state root for the final block
BLOCK_DATA=$(curl -s -X POST -H "Content-Type: application/json" \
    --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getBlockByNumber\",\"params\":[\"$BLOCK_NUM\",false],\"id\":1}" \
    http://localhost:$GETH_PORT)

STATE_ROOT=$(echo "$BLOCK_DATA" | grep -o '"stateRoot":"[^"]*"' | cut -d'"' -f4)
echo -e "${GREEN}✓ Final state root: $STATE_ROOT${NC}"

# Trigger debug API to commit trie (if available)
curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"debug_setHead","params":["latest"],\"id":99}' \
    http://localhost:$GETH_PORT > /dev/null 2>&1 || true

# Verify state has accounts using eth_getProof
echo -e "${YELLOW}Verifying state contains accounts...${NC}"
TEST_ADDR="0x0000000000000000000000000000000000000001"
PROOF_RESULT=$(curl -s -X POST -H "Content-Type: application/json" \
    --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getProof\",\"params\":[\"$TEST_ADDR\",[],\"latest\"],\"id\":1}" \
    http://localhost:$GETH_PORT)

echo "Proof result for $TEST_ADDR:"
echo "$PROOF_RESULT" | head -c 500
echo ""

# Stop geth cleanly so we can access the database
echo -e "${YELLOW}Stopping geth to access database...${NC}"
kill $GETH_PID 2>/dev/null || true
wait $GETH_PID 2>/dev/null || true
sleep 2
echo -e "${GREEN}✓ Geth stopped cleanly${NC}"

# Verify database files exist
if [ ! -f "$CHAINDATA_PATH/CURRENT" ]; then
    echo -e "${RED}ERROR: Database CURRENT file not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Database ready at $CHAINDATA_PATH${NC}"

# Run E2E tests (no RPC, only database access)
echo -e "${YELLOW}Running E2E tests with database access...${NC}"
echo ""

cd "$(dirname "$0")/.."

# Update go.mod if needed
echo -e "${YELLOW}Updating go dependencies...${NC}"
go mod tidy 2>/dev/null || true

# Tests use database only (no RPC)
# We'll modify the test to work without RPC by providing state root via env var
E2E_TEST=1 \
STATE_DB_PATH="$CHAINDATA_PATH" \
TEST_STATE_ROOT="$STATE_ROOT" \
TEST_BLOCK_NUMBER="$BLOCK_NUM" \
go test -v ./test -run TestStateLeaf -timeout 10m

TEST_EXIT_CODE=$?

echo ""
if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}=== E2E Tests PASSED ===${NC}"
else
    echo -e "${RED}=== E2E Tests FAILED ===${NC}"
    echo "Geth log file: $GETH_LOGFILE"
fi

# Cleanup will happen via trap
exit $TEST_EXIT_CODE
