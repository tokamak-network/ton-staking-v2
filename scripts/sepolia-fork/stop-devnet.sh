#!/bin/bash
# =============================================================================
# Stop TON Staking V3 Sepolia Fork Devnet
# =============================================================================

set -eo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEPLOYMENT_DIR="$PROJECT_ROOT/deployments/sepolia-fork"
COMPOSE_FILE="$DEPLOYMENT_DIR/docker-compose.yml"
DEVNET_DIR="$PROJECT_ROOT/.devnet-sepolia-fork"

echo -e "${BLUE}=== Stopping TON Staking V3 Sepolia Fork Devnet ===${NC}"
echo ""

# Check if running
if ! docker ps | grep -q "ton-staking.*sepolia-fork"; then
    echo -e "${YELLOW}Sepolia fork devnet is not running${NC}"
    exit 0
fi

# Stop all services
echo "Stopping all services..."
docker-compose -f "$COMPOSE_FILE" down

# Optionally remove volumes
if [ "$1" = "--clean" ] || [ "$1" = "-c" ]; then
    echo ""
    echo -e "${YELLOW}Cleaning up volumes and data...${NC}"
    docker-compose -f "$COMPOSE_FILE" down -v

    # Remove devnet directory
    if [ -d "$DEVNET_DIR" ]; then
        rm -rf "$DEVNET_DIR"
        echo -e "${GREEN}✓ Removed .devnet-sepolia-fork directory${NC}"
    fi
fi

echo ""
echo -e "${GREEN}✓ Sepolia fork devnet stopped${NC}"
echo ""
echo "To start again: make devnet-sepolia-fork-start"
echo "To clean and stop: ./scripts/sepolia-fork/stop-devnet.sh --clean"
