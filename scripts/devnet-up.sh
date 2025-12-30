#!/bin/bash
# =============================================================================
# Start L1 devnet from existing allocs
# =============================================================================
# Use this to restart L1 after `make devnet-down` without full rebuild.
# Requires .devnet/allocs-l1.json to exist (from previous devnet-allocs).
# =============================================================================

set -eo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DEVNET_DIR="$PROJECT_ROOT/.devnet"

# Check allocs exist
if [ ! -f "$DEVNET_DIR/allocs-l1.json" ]; then
    echo -e "${RED}Error: .devnet/allocs-l1.json not found${NC}"
    echo "Run 'make devnet-allocs' first"
    exit 1
fi

# Kill any existing Anvil
pkill -f "anvil.*8545" 2>/dev/null || true
sleep 1

# Start Anvil
echo -e "${YELLOW}Starting L1 devnet...${NC}"
anvil \
    --port 8545 \
    --chain-id 900 \
    --block-time 2 \
    --init "$DEVNET_DIR/allocs-l1.json" \
    > "$DEVNET_DIR/anvil.log" 2>&1 &

ANVIL_PID=$!
echo $ANVIL_PID > "$DEVNET_DIR/anvil.pid"

# Wait for ready
for i in {1..30}; do
    if curl -s http://localhost:8545 > /dev/null 2>&1; then
        echo -e "${GREEN}L1 devnet started (PID: $ANVIL_PID, Chain ID: 900)${NC}"
        exit 0
    fi
    sleep 1
done

echo -e "${RED}Error: Anvil failed to start${NC}"
exit 1
