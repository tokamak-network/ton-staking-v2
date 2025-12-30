#!/bin/bash
# =============================================================================
# TON Staking V3 E2E Test Runner
# =============================================================================
# Single-terminal E2E test execution (like Asterisc)
#
# Usage:
#   make devnet-allocs   # Set up devnet first
#   make test-e2e        # Run E2E tests
#
# Or run this script directly:
#   ./scripts/run-e2e-tests.sh
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}=== TON Staking V3 E2E Test Runner ===${NC}"
echo ""

# Check devnet is set up
if [ ! -f "$PROJECT_ROOT/.devnet/addresses.json" ]; then
    echo -e "${RED}Error: Devnet not set up${NC}"
    echo ""
    echo "Run 'make devnet-allocs' first to set up the devnet."
    exit 1
fi

# Check L1 is running
if ! curl -s http://localhost:8545 > /dev/null 2>&1; then
    echo -e "${YELLOW}L1 devnet not running. Starting...${NC}"
    "$SCRIPT_DIR/devnet-up.sh"
fi

# Source environment
source "$PROJECT_ROOT/.devnet/.env"

# Run tests
echo -e "${YELLOW}Running E2E tests...${NC}"
echo ""

cd "$PROJECT_ROOT/op-e2e"
go test -v ./faultproofs/... -timeout 300s

echo ""
echo -e "${GREEN}=== E2E Tests Complete ===${NC}"
