#!/bin/bash
# =============================================================================
# Get TON Staking V3 Devnet Information
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

echo -e "${BLUE}=== TON Staking V3 Devnet Information ===${NC}"
echo ""

# Check if devnet is running
if ! docker ps | grep -q "ton-staking-l1"; then
    echo -e "${YELLOW}Devnet is not running${NC}"
    echo "Start it with: make devnet-start"
    exit 0
fi

# Container status
echo -e "${BLUE}Container Status:${NC}"
docker-compose ps
echo ""

# RPC Endpoints
echo -e "${BLUE}RPC Endpoints:${NC}"
echo "  L1 (Anvil):          http://localhost:8545"
echo "  L2 (op-geth):        http://localhost:9545"
echo "  L2 Rollup (op-node): http://localhost:7545"
echo ""

# Block numbers
echo -e "${BLUE}Block Numbers:${NC}"
L1_BLOCK=$(cast block-number --rpc-url http://localhost:8545 2>/dev/null || echo "Not available")
L2_BLOCK=$(cast block-number --rpc-url http://localhost:9545 2>/dev/null || echo "Not available")
echo "  L1: $L1_BLOCK"
echo "  L2: $L2_BLOCK"
echo ""

# Contract addresses
if [ -f "$DEVNET_DIR/addresses.json" ]; then
    echo -e "${BLUE}Contract Addresses:${NC}"
    echo "  TON:            $(jq -r '.ton' $DEVNET_DIR/addresses.json)"
    echo "  WTON:           $(jq -r '.wton' $DEVNET_DIR/addresses.json)"
    echo "  SeigManager:    $(jq -r '.seigManagerProxy' $DEVNET_DIR/addresses.json)"
    echo "  DepositManager: $(jq -r '.depositManagerProxy' $DEVNET_DIR/addresses.json)"
    echo "  Layer2Manager:  $(jq -r '.layer2ManagerProxy' $DEVNET_DIR/addresses.json)"
    echo "  RAT:            $(jq -r '.ratProxy' $DEVNET_DIR/addresses.json)"
    echo "  SystemConfig:   $(jq -r '.systemConfig' $DEVNET_DIR/addresses.json)"
    echo ""
fi

# Test accounts
echo -e "${BLUE}Test Accounts:${NC}"
echo "  Account #0 (Optimism Deployer / Batcher):"
echo "    Address:     0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
echo "    Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
echo ""
echo "  Account #1 (TON Staking Deployer / Proposer):"
echo "    Address:     0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
echo "    Private Key: 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
echo ""
echo "  Account #2 (Validator):"
echo "    Address:     0x90F79bf6EB2c4f870365E785982E1f101E93b906"
echo "    Private Key: 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"
echo ""

# Docker logs info
echo -e "${BLUE}View Logs:${NC}"
echo "  All services:   docker-compose logs -f"
echo "  L1 only:        docker-compose logs -f l1"
echo "  L2 execution:   docker-compose logs -f l2-execution"
echo "  L2 node:        docker-compose logs -f l2-node"
echo "  Batcher:        docker-compose logs -f l2-batcher"
echo "  Proposer:       docker-compose logs -f l2-proposer"
echo ""
