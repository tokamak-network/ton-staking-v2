#!/bin/bash
# Test debug_accountRange API

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Testing debug_accountRange API ===${NC}"

# Configuration
GETH_DATADIR="/tmp/geth-test-$$"
GETH_PORT=9545
GETH_PID=""

# Cleanup function
cleanup() {
    echo -e "\n${YELLOW}Cleaning up...${NC}"
    if [ ! -z "$GETH_PID" ]; then
        echo "Stopping geth (PID: $GETH_PID)"
        kill $GETH_PID 2>/dev/null || true
        wait $GETH_PID 2>/dev/null || true
    fi
    pkill -f "geth.*$GETH_DATADIR" 2>/dev/null || true
    if [ -d "$GETH_DATADIR" ]; then
        rm -rf "$GETH_DATADIR"
    fi
    echo -e "${GREEN}Cleanup complete${NC}"
}

trap cleanup EXIT INT TERM

# Start geth with hash state scheme
echo -e "${YELLOW}Starting geth...${NC}"
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
  > /tmp/geth-test-$$.log 2>&1 &

GETH_PID=$!
echo "Geth started with PID: $GETH_PID"

# Wait for geth
echo -e "${YELLOW}Waiting for geth...${NC}"
sleep 3

for i in {1..30}; do
    if curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
        http://localhost:$GETH_PORT > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Geth is ready!${NC}"
        break
    fi
    sleep 1
done

# Get dev account
DEV_ACCOUNT=$(curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_coinbase","params":[],"id":1}' \
    http://localhost:$GETH_PORT | grep -o '"result":"[^"]*"' | cut -d'"' -f4)

echo -e "${GREEN}✓ Dev account: $DEV_ACCOUNT${NC}"

# Send 20 transactions to create accounts
echo -e "${YELLOW}Sending 20 transactions...${NC}"
for i in {1..20}; do
    TO_ADDR=$(printf "0x%040x" $i)
    curl -s -X POST -H "Content-Type: application/json" \
        --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_sendTransaction\",\"params\":[{\"from\":\"$DEV_ACCOUNT\",\"to\":\"$TO_ADDR\",\"value\":\"0xde0b6b3a7640000\",\"gas\":\"0x5208\"}],\"id\":$i}" \
        http://localhost:$GETH_PORT > /dev/null
    sleep 0.1
done

echo -e "${GREEN}✓ Sent 20 transactions${NC}"
sleep 3

# Get current block
BLOCK_NUM=$(curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
    http://localhost:$GETH_PORT | grep -o '"result":"[^"]*"' | cut -d'"' -f4)

echo -e "${GREEN}✓ Current block: $BLOCK_NUM${NC}"

# Test debug_accountRange
echo -e "${YELLOW}Testing debug_accountRange...${NC}"
ACCOUNT_RANGE=$(curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"debug_accountRange","params":["latest","",1000,false,false,false],"id":1}' \
    http://localhost:$GETH_PORT)

echo -e "${GREEN}Account Range Result:${NC}"
echo "$ACCOUNT_RANGE" | jq '.'

# Extract account count
ACCOUNT_COUNT=$(echo "$ACCOUNT_RANGE" | jq '.result.accounts | length')
echo -e "${GREEN}✓ Found $ACCOUNT_COUNT accounts${NC}"

# Show first few accounts
echo -e "${YELLOW}First 5 accounts (address hash):${NC}"
echo "$ACCOUNT_RANGE" | jq -r '.result.accounts | to_entries | .[:5] | .[] | .key' 

echo -e "${GREEN}=== Test Complete ===${NC}"
echo "Geth will be stopped in 5 seconds..."
sleep 5
