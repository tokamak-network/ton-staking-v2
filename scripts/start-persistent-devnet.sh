#!/bin/bash
# =============================================================================
# Start Persistent Devnet with TON Staking V3 + RAT
# =============================================================================
# This script starts a persistent Kurtosis devnet with all contracts
# pre-deployed via genesis allocation.
#
# Prerequisites:
#   - make devnet-allocs-offline (Genesis must be generated first)
#   - Kurtosis installed
#   - Docker running
#
# Usage:
#   ./scripts/start-persistent-devnet.sh
#   OR
#   make devnet-start
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
DEVNET_DIR="$PROJECT_ROOT/.devnet"
OPTIMISM_DIR="$PROJECT_ROOT/lib/optimism"
OPTIMISM_DEVNET_DIR="$OPTIMISM_DIR/.devnet"

echo -e "${BLUE}=== Starting Persistent Devnet with TON Staking V3 ===${NC}"
echo ""

# =============================================================================
# Check Prerequisites
# =============================================================================

echo -e "${YELLOW}[1/5] Checking prerequisites...${NC}"

# Check if genesis exists
if [ ! -f "$DEVNET_DIR/allocs-l1-staking-v3.json" ]; then
    echo -e "${RED}Error: Genesis file not found${NC}"
    echo "Run 'make devnet-allocs-offline' first to generate genesis"
    exit 1
fi

echo -e "${GREEN}  ✓ Genesis file found${NC}"

# Check if Kurtosis is installed
if ! command -v kurtosis &> /dev/null; then
    echo -e "${RED}Error: Kurtosis not installed${NC}"
    echo "Run 'cd lib/optimism/op-challenger/scripts && ./install-tools.sh'"
    exit 1
fi

echo -e "${GREEN}  ✓ Kurtosis installed${NC}"

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}Error: Docker is not running${NC}"
    echo "Please start Docker first"
    exit 1
fi

echo -e "${GREEN}  ✓ Docker running${NC}"

# =============================================================================
# Copy Genesis to Optimism Devnet Directory
# =============================================================================

echo ""
echo -e "${YELLOW}[2/5] Preparing genesis for Kurtosis...${NC}"

# Create Optimism devnet directory if it doesn't exist
mkdir -p "$OPTIMISM_DEVNET_DIR"

# Copy allocs file
cp "$DEVNET_DIR/allocs-l1-staking-v3.json" "$OPTIMISM_DEVNET_DIR/allocs-l1.json"
echo -e "${GREEN}  ✓ Copied genesis to lib/optimism/.devnet/allocs-l1.json${NC}"

# Copy addresses if exists
if [ -f "$DEVNET_DIR/addresses.json" ]; then
    cp "$DEVNET_DIR/addresses.json" "$OPTIMISM_DEVNET_DIR/ton-staking-addresses.json"
    echo -e "${GREEN}  ✓ Copied addresses to lib/optimism/.devnet/ton-staking-addresses.json${NC}"
fi

# =============================================================================
# Check if enclave already exists
# =============================================================================

echo ""
echo -e "${YELLOW}[3/5] Checking for existing devnet...${NC}"

if kurtosis enclave inspect simple-devnet &> /dev/null; then
    echo -e "${YELLOW}  ⚠ Enclave 'simple-devnet' already exists${NC}"
    read -p "Remove and restart? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}  Removing existing enclave...${NC}"
        kurtosis enclave rm simple-devnet --force
        echo -e "${GREEN}  ✓ Removed${NC}"
    else
        echo -e "${YELLOW}  Keeping existing enclave. Use 'make devnet-stop' to stop it.${NC}"
        exit 0
    fi
else
    echo -e "${GREEN}  ✓ No existing enclave${NC}"
fi

# =============================================================================
# Start Devnet
# =============================================================================

echo ""
echo -e "${YELLOW}[4/5] Starting Kurtosis devnet (GameType 0 - CANNON)...${NC}"
echo -e "${BLUE}  This may take 5-10 minutes...${NC}"
echo ""

cd "$OPTIMISM_DIR/op-challenger/scripts"

# Run build-devnet.sh with --game-type=0
if ./build-devnet.sh --game-type=0; then
    echo ""
    echo -e "${GREEN}  ✓ Devnet started successfully${NC}"
else
    echo ""
    echo -e "${RED}  ✗ Devnet start failed${NC}"
    exit 1
fi

# =============================================================================
# Verify Deployment
# =============================================================================

echo ""
echo -e "${YELLOW}[5/5] Verifying deployment...${NC}"

# Wait a bit for services to stabilize
sleep 5

# Check if enclave is running
if kurtosis enclave inspect simple-devnet &> /dev/null; then
    echo -e "${GREEN}  ✓ Enclave 'simple-devnet' is running${NC}"
else
    echo -e "${RED}  ✗ Enclave not found${NC}"
    exit 1
fi

# =============================================================================
# Summary
# =============================================================================

echo ""
echo -e "${GREEN}=== Devnet Started Successfully ===${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Get RPC endpoints and contract addresses:"
echo -e "     ${YELLOW}./scripts/get-devnet-info.sh${NC}"
echo ""
echo "  2. Verify RAT integration:"
echo -e "     ${YELLOW}export L1_RPC=<from above>${NC}"
echo -e "     ${YELLOW}cast call <DISPUTE_GAME_FACTORY> \"rat()(address)\" --rpc-url \$L1_RPC${NC}"
echo ""
echo "  3. Start RAT Client:"
echo -e "     ${YELLOW}make rat-client-run${NC}"
echo ""
echo "  4. Monitor logs:"
echo -e "     ${YELLOW}kurtosis service logs simple-devnet <service-name> -f${NC}"
echo ""
echo "  5. Stop devnet when done:"
echo -e "     ${YELLOW}make devnet-stop${NC}"
echo ""
echo -e "${BLUE}Services:${NC}"
echo "  - L1 EL: el-1-geth-teku"
echo "  - L1 CL: cl-1-teku-geth"
echo "  - L2 EL: op-el-2151908-node0-op-geth"
echo "  - L2 CL: op-cl-2151908-node0-op-node"
echo "  - Batcher: op-batcher-2151908-op-kurtosis"
echo "  - Proposer: op-proposer-2151908-op-kurtosis"
echo ""
