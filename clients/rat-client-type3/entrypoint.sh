#!/bin/sh
set -e

# Get contract addresses from genesis
RAT_CONTRACT=$(cat /genesis/addresses.json | grep ratProxy | cut -d'"' -f4)
SYSTEM_CONFIG=$(cat /genesis/addresses.json | grep systemConfig | cut -d'"' -f4)

echo "Starting RAT Client..."
echo "  L1 RPC: $L1_RPC_URL"
echo "  L2 RPC: $L2_RPC_URL"
echo "  RAT Contract: $RAT_CONTRACT"
echo "  SystemConfig: $SYSTEM_CONFIG"

exec /app/rat-client \
  --l1-rpc "$L1_RPC_URL" \
  --l2-rpc "$L2_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --rat-contract "$RAT_CONTRACT" \
  --system-config "$SYSTEM_CONFIG" \
  --start-block 0
