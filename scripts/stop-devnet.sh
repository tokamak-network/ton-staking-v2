#!/bin/bash
# =============================================================================
# Stop Persistent Devnet
# =============================================================================
# This script stops the Kurtosis devnet enclave
#
# Usage:
#   ./scripts/stop-devnet.sh
#   OR
#   make devnet-stop
# =============================================================================

set -eo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Stopping Devnet ===${NC}"
echo ""

# Check if Kurtosis is installed
if ! command -v kurtosis &> /dev/null; then
    echo -e "${RED}Error: Kurtosis not installed${NC}"
    exit 1
fi

# Check if enclave exists
if kurtosis enclave inspect simple-devnet &> /dev/null; then
    echo -e "${YELLOW}Removing enclave 'simple-devnet'...${NC}"
    kurtosis enclave rm simple-devnet --force
    echo -e "${GREEN}✓ Devnet stopped${NC}"
else
    echo -e "${YELLOW}Enclave 'simple-devnet' not found (already stopped)${NC}"
fi

echo ""
echo -e "${BLUE}To start again:${NC}"
echo -e "  ${YELLOW}make devnet-start${NC}"
echo ""
