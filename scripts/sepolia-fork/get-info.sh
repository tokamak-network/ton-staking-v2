#!/bin/bash
# =============================================================================
# Get TON Staking V3 Sepolia Fork Devnet Information
# =============================================================================

set -eo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEVNET_DIR="$PROJECT_ROOT/.devnet-sepolia-fork"
DEPLOYMENT_DIR="$PROJECT_ROOT/deployments/sepolia-fork"
COMPOSE_FILE="$DEPLOYMENT_DIR/docker-compose.yml"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     TON Staking V3 Sepolia Fork - Devnet Info              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if devnet is running
if ! docker ps | grep -q "ton-staking-l1-sepolia-fork"; then
    echo -e "${YELLOW}Sepolia fork devnet is not running${NC}"
    echo "Start it with: make devnet-sepolia-fork-start"
    exit 0
fi

# =============================================================================
# Network Information
# =============================================================================
echo -e "${CYAN}Network Configuration:${NC}"
echo "  L1: Sepolia Fork (Chain ID: 11155111)"
echo "  L2: Local op-geth (Chain ID: 901)"
echo ""

# =============================================================================
# Container Status
# =============================================================================
echo -e "${CYAN}Container Status:${NC}"
cd "$DEPLOYMENT_DIR"
docker-compose ps 2>/dev/null || docker compose ps 2>/dev/null
echo ""

# =============================================================================
# RPC Endpoints
# =============================================================================
echo -e "${CYAN}RPC Endpoints:${NC}"
echo "  L1 (Sepolia Fork):   http://localhost:8545"
echo "  L2 (op-geth):        http://localhost:9545"
echo "  L2 (op-geth WS):     ws://localhost:9546"
echo "  L2 Rollup (op-node): http://localhost:7545"
echo ""

# =============================================================================
# Block Numbers
# =============================================================================
echo -e "${CYAN}Block Numbers:${NC}"
L1_BLOCK=$(cast block-number --rpc-url http://localhost:8545 2>/dev/null || echo "N/A")
L2_BLOCK=$(cast block-number --rpc-url http://localhost:9545 2>/dev/null || echo "N/A")
echo "  L1: $L1_BLOCK"
echo "  L2: $L2_BLOCK"
echo ""

# =============================================================================
# TON Staking Contract Addresses
# =============================================================================
if [ -f "$DEVNET_DIR/addresses.json" ]; then
    echo -e "${CYAN}TON Staking V3 Contract Addresses:${NC}"

    # Core tokens
    TON=$(jq -r '.ton // "N/A"' "$DEVNET_DIR/addresses.json")
    WTON=$(jq -r '.wton // "N/A"' "$DEVNET_DIR/addresses.json")
    echo "  TON:              $TON"
    echo "  WTON:             $WTON"
    echo ""

    # Manager contracts
    SEIG=$(jq -r '.seigManagerProxy // "N/A"' "$DEVNET_DIR/addresses.json")
    DEPOSIT=$(jq -r '.depositManagerProxy // "N/A"' "$DEVNET_DIR/addresses.json")
    LAYER2=$(jq -r '.layer2ManagerProxy // "N/A"' "$DEVNET_DIR/addresses.json")
    BRIDGE=$(jq -r '.l1BridgeRegistryProxy // "N/A"' "$DEVNET_DIR/addresses.json")
    echo "  SeigManager:      $SEIG"
    echo "  DepositManager:   $DEPOSIT"
    echo "  Layer2Manager:    $LAYER2"
    echo "  L1BridgeRegistry: $BRIDGE"
    echo ""

    # V3 contracts
    RAT=$(jq -r '.ratProxy // "N/A"' "$DEVNET_DIR/addresses.json")
    VALIDATOR=$(jq -r '.validatorRewardProxy // "N/A"' "$DEVNET_DIR/addresses.json")
    echo "  RAT:              $RAT"
    echo "  ValidatorReward:  $VALIDATOR"
    echo ""

    # DAO
    DAO=$(jq -r '.daoCommitteeProxy // "N/A"' "$DEVNET_DIR/addresses.json")
    echo "  DAOCommittee:     $DAO"
    echo ""
fi

# =============================================================================
# Optimism Contract Addresses
# =============================================================================
if [ -f "$DEVNET_DIR/optimism-addresses.json" ]; then
    echo -e "${CYAN}Optimism Contract Addresses:${NC}"
    DGF=$(jq -r '.DisputeGameFactoryProxy // "N/A"' "$DEVNET_DIR/optimism-addresses.json")
    SC=$(jq -r '.SystemConfigProxy // "N/A"' "$DEVNET_DIR/optimism-addresses.json")
    OP=$(jq -r '.OptimismPortalProxy // "N/A"' "$DEVNET_DIR/optimism-addresses.json")
    BRIDGE=$(jq -r '.L1StandardBridgeProxy // "N/A"' "$DEVNET_DIR/optimism-addresses.json")

    echo "  DisputeGameFactory: $DGF"
    echo "  SystemConfig:       $SC"
    echo "  OptimismPortal:     $OP"
    echo "  L1StandardBridge:   $BRIDGE"
    echo ""
fi

# =============================================================================
# Test Accounts
# =============================================================================
echo -e "${CYAN}Test Accounts (Anvil Defaults):${NC}"
echo ""
echo "  Account #0 (Deployer/Batcher):"
echo "    Address:     0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
echo "    Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
BALANCE0=$(cast balance 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url http://localhost:8545 --ether 2>/dev/null || echo "N/A")
echo "    Balance:     $BALANCE0 ETH"
echo ""
echo "  Account #1 (Proposer):"
echo "    Address:     0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
echo "    Private Key: 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
echo ""
echo "  Account #2 (Validator 1):"
echo "    Address:     0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"
echo "    Private Key: 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"
echo ""
echo "  Account #3 (Validator 2):"
echo "    Address:     0x90F79bf6EB2c4f870365E785982E1f101E93b906"
echo "    Private Key: 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6"
echo ""
echo "  Account #4 (Validator 3):"
echo "    Address:     0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65"
echo "    Private Key: 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a"
echo ""

# =============================================================================
# Useful Commands
# =============================================================================
echo -e "${CYAN}Useful Commands:${NC}"
echo "  View logs:      make devnet-sepolia-fork-logs"
echo "  Health check:   make devnet-sepolia-fork-health"
echo "  Mint ETH:       ./scripts/sepolia-fork/faucet.sh <address> <amount>"
echo "  Stop:           make devnet-sepolia-fork-stop"
echo ""

# =============================================================================
# Log Viewing Commands
# =============================================================================
echo -e "${CYAN}View Specific Logs:${NC}"
echo "  L1 (Anvil):     docker logs -f ton-staking-l1-sepolia-fork"
echo "  L2 (op-geth):   docker logs -f ton-staking-l2-execution-sepolia-fork"
echo "  L2 (op-node):   docker logs -f ton-staking-l2-node-sepolia-fork"
echo "  Batcher:        docker logs -f ton-staking-l2-batcher-sepolia-fork"
echo "  Proposer:       docker logs -f ton-staking-l2-proposer-sepolia-fork"
echo ""
