#!/bin/bash
# =============================================================================
# Stop TON Staking V3 Local Devnet (Sepolia Fork)
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.l2-only.yml"

echo "Stopping TON Staking V3 Local Devnet (Sepolia Fork)..."

# Stop L2 containers
if [ -f "$COMPOSE_FILE" ]; then
    docker compose -f "$COMPOSE_FILE" down 2>/dev/null || true
fi

# Stop Anvil
if pgrep -f "anvil" > /dev/null; then
    echo "Stopping Anvil..."
    pkill -f "anvil" || true
fi

echo ""
echo "Devnet stopped."
echo ""
echo "To clean up data:"
echo "  docker volume rm ton-staking-v2_l2-execution-data 2>/dev/null || true"
echo "  rm -rf .devnet-sepolia-fork/"
