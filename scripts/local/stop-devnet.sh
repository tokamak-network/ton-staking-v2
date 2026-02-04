#!/bin/bash
# =============================================================================
# Stop TON Staking V3 Devnet
# =============================================================================

set -eo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}=== Stopping TON Staking V3 Devnet ===${NC}"
echo ""

cd "$PROJECT_ROOT"

# Check if devnet is running
if ! docker ps | grep -q "ton-staking"; then
    echo -e "${YELLOW}Devnet is not running${NC}"
    exit 0
fi

# Stop and remove containers
echo -e "${YELLOW}Stopping containers...${NC}"
docker-compose down

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Devnet stopped successfully${NC}"
    echo ""
    echo "To remove all data (volumes), run:"
    echo "  docker-compose down -v"
else
    echo -e "${RED}Failed to stop devnet${NC}"
    exit 1
fi
