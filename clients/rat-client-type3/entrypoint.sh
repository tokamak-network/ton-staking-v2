#!/bin/sh
set -e

# Get contract addresses from genesis
RAT_CONTRACT=$(cat /genesis/addresses.json | grep ratProxy | cut -d'"' -f4)
SYSTEM_CONFIG=$(cat /genesis/addresses.json | grep systemConfig | cut -d'"' -f4)

# Get start block from:
# 1. Environment variable START_BLOCK
# 2. Or from rollup.json L1 genesis block number
# 3. Default to 0
if [ -z "$START_BLOCK" ] || [ "$START_BLOCK" = "0" ]; then
  if [ -f /genesis/rollup.json ]; then
    # Extract L1 genesis block number from rollup.json
    START_BLOCK=$(cat /genesis/rollup.json | grep -A2 '"l1"' | grep '"number"' | grep -o '[0-9]*')
  fi
fi
START_BLOCK=${START_BLOCK:-0}

echo "Starting RAT Client..."
echo "  L1 RPC: $L1_RPC_URL"
echo "  L2 RPC: $L2_RPC_URL"
echo "  RAT Contract: $RAT_CONTRACT"
echo "  SystemConfig: $SYSTEM_CONFIG"
echo "  Start Block: $START_BLOCK"

exec /app/rat-client \
  --l1-rpc "$L1_RPC_URL" \
  --l2-rpc "$L2_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --rat-contract "$RAT_CONTRACT" \
  --system-config "$SYSTEM_CONFIG" \
  --start-block "$START_BLOCK"
