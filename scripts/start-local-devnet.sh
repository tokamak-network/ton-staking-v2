#!/bin/bash
# =============================================================================
# TON Staking V3 Local Devnet Startup Script
# =============================================================================
# This script provides an easy way to start a local development environment
# with all TON Staking V3 contracts pre-deployed.
#
# Usage:
#   ./scripts/start-local-devnet.sh [OPTIONS]
#
# Options:
#   --port PORT        RPC port (default: 8545)
#   --host HOST        Host to bind (default: 0.0.0.0)
#   --block-time SEC   Block time in seconds (default: auto-mining)
#   --help             Show this help message
# =============================================================================

set -eo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
PORT=8545
HOST="0.0.0.0"
BLOCK_TIME=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --port)
            PORT="$2"
            shift 2
            ;;
        --host)
            HOST="$2"
            shift 2
            ;;
        --block-time)
            BLOCK_TIME="--block-time $2"
            shift 2
            ;;
        --help)
            head -n 20 "$0" | tail -n 15
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
GENESIS_FILE="$PROJECT_ROOT/.devnet/genesis-l1-staking-v3.json"

echo -e "${BLUE}=== TON Staking V3 Local Devnet ===${NC}"
echo ""

# Check if genesis file exists
if [ ! -f "$GENESIS_FILE" ]; then
    echo -e "${YELLOW}Genesis file not found. Generating...${NC}"
    cd "$PROJECT_ROOT"
    make devnet-allocs-offline
    echo ""
fi

# Check if port is already in use
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo -e "${RED}Error: Port $PORT is already in use${NC}"
    echo "Please stop the existing process or use a different port with --port"
    exit 1
fi

echo -e "${GREEN}Starting Anvil with TON Staking V3 genesis...${NC}"
echo ""
echo -e "${BLUE}Configuration:${NC}"
echo "  RPC URL:    http://$HOST:$PORT"
echo "  Chain ID:   900"
echo "  Genesis:    $GENESIS_FILE"
if [ -n "$BLOCK_TIME" ]; then
    echo "  Block Time: $(echo $BLOCK_TIME | cut -d' ' -f2)s"
else
    echo "  Block Time: Auto-mining (instant)"
fi
echo ""

# Display contract addresses
if [ -f "$PROJECT_ROOT/.devnet/addresses.json" ]; then
    echo -e "${BLUE}Deployed Contracts:${NC}"
    echo "  TON:            $(jq -r '.ton' $PROJECT_ROOT/.devnet/addresses.json)"
    echo "  WTON:           $(jq -r '.wton' $PROJECT_ROOT/.devnet/addresses.json)"
    echo "  SeigManager:    $(jq -r '.seigManagerProxy' $PROJECT_ROOT/.devnet/addresses.json)"
    echo "  DepositManager: $(jq -r '.depositManagerProxy' $PROJECT_ROOT/.devnet/addresses.json)"
    echo "  Layer2Manager:  $(jq -r '.layer2ManagerProxy' $PROJECT_ROOT/.devnet/addresses.json)"
    echo "  RAT:            $(jq -r '.ratProxy' $PROJECT_ROOT/.devnet/addresses.json)"
    echo ""
fi

echo -e "${BLUE}Test Accounts:${NC}"
echo "  Account #0 (Optimism Deployer):"
echo "    Address:     0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
echo "    Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
echo ""
echo "  Account #1 (TON Staking Deployer):"
echo "    Address:     0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
echo "    Private Key: 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
echo "    TON Balance: 1,000,000 TON"
echo ""
echo "  Account #2 (Validator):"
echo "    Address:     0x90F79bf6EB2c4f870365E785982E1f101E93b906"
echo "    Private Key: 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"
echo ""

echo -e "${YELLOW}Press Ctrl+C to stop the devnet${NC}"
echo ""
echo "================================================================"
echo ""

# Start Anvil
anvil \
    --host "$HOST" \
    --port "$PORT" \
    --init "$GENESIS_FILE" \
    $BLOCK_TIME
