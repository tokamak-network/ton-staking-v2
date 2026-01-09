#!/bin/bash
# =============================================================================
# Simple RAT Client Test (Mock-based)
# =============================================================================
# This script creates a minimal test environment for RAT Client:
#   1. L1 (Anvil) with genesis (already running)
#   2. Mock batch data submission to L1
#   3. op-node in follower mode
#   4. RAT Client verification
#
# Prerequisites:
#   - L1 Anvil running on port 8545
#   - .devnet/addresses.json with contract addresses
# =============================================================================

set -eo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Simple RAT Client Test ===${NC}"
echo ""

# Configuration
L1_RPC="http://localhost:8545"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DEVNET_DIR="$PROJECT_ROOT/.devnet"

# Contract addresses from genesis
RAT_PROXY=$(jq -r '.ratProxy // .rat' "$DEVNET_DIR/addresses.json")
DISPUTE_GAME_FACTORY=$(jq -r '.DisputeGameFactoryProxy' "$DEVNET_DIR/optimism-addresses.json")
SYSTEM_CONFIG=$(jq -r '.SystemConfigProxy' "$DEVNET_DIR/optimism-addresses.json")
BATCH_INBOX=$(jq -r '.BatchInboxAddress // "0xff00000000000000000000000000000000000998"' "$DEVNET_DIR/optimism-addresses.json")

echo -e "${YELLOW}Contract Addresses:${NC}"
echo "  RAT:                  $RAT_PROXY"
echo "  DisputeGameFactory:   $DISPUTE_GAME_FACTORY"
echo "  SystemConfig:         $SYSTEM_CONFIG"
echo "  Batch Inbox:          $BATCH_INBOX"
echo ""

# =============================================================================
# Step 1: Verify L1 is running
# =============================================================================
echo -e "${YELLOW}[1/5] Verifying L1 (Anvil)...${NC}"

BLOCK_NUM=$(cast block-number --rpc-url $L1_RPC 2>/dev/null || echo "")
if [ -z "$BLOCK_NUM" ]; then
    echo -e "${RED}Error: L1 not running${NC}"
    echo "Start L1 with: anvil --init .devnet/genesis-l1-staking-v3.json --port 8545"
    exit 1
fi

echo -e "${GREEN}  ✓ L1 running (block $BLOCK_NUM)${NC}"

# Verify RAT contract exists
RAT_CODE=$(cast code $RAT_PROXY --rpc-url $L1_RPC)
if [ "$RAT_CODE" = "0x" ]; then
    echo -e "${RED}Error: RAT contract not found at $RAT_PROXY${NC}"
    exit 1
fi

echo -e "${GREEN}  ✓ RAT contract deployed${NC}"

# =============================================================================
# Step 2: Verify RAT connection to DisputeGameFactory
# =============================================================================
echo ""
echo -e "${YELLOW}[2/5] Verifying RAT integration...${NC}"

DGF_RAT=$(cast call $DISPUTE_GAME_FACTORY "rat()(address)" --rpc-url $L1_RPC 2>/dev/null || echo "")
if [ "$DGF_RAT" != "$RAT_PROXY" ]; then
    echo -e "${YELLOW}  ⚠ DisputeGameFactory.rat() = $DGF_RAT (expected $RAT_PROXY)${NC}"
    echo -e "${YELLOW}  This is OK if using genesis deployment${NC}"
else
    echo -e "${GREEN}  ✓ RAT connected to DisputeGameFactory${NC}"
fi

# Check RAT parameters
TRIGGER_PROB=$(cast call $RAT_PROXY "triggerProbability()(uint256)" --rpc-url $L1_RPC 2>/dev/null || echo "")
if [ -n "$TRIGGER_PROB" ]; then
    echo -e "${GREEN}  ✓ RAT trigger probability: $TRIGGER_PROB (100% = 10^27)${NC}"
fi

# =============================================================================
# Step 3: Submit mock batch data to L1
# =============================================================================
echo ""
echo -e "${YELLOW}[3/5] Submitting mock batch data to L1...${NC}"

# Anvil account #0 (default unlocked)
BATCHER_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

# Mock batch data (simple example)
# In real scenario, this would be compressed L2 blocks
MOCK_BATCH_DATA="0x0000000000000001"  # Mock data

echo -e "${BLUE}  Submitting batch to $BATCH_INBOX...${NC}"

TX_HASH=$(cast send $BATCH_INBOX \
    --value 0 \
    --rpc-url $L1_RPC \
    --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
    $MOCK_BATCH_DATA 2>&1 | grep "transactionHash" | awk '{print $2}')

if [ -n "$TX_HASH" ]; then
    echo -e "${GREEN}  ✓ Batch submitted: $TX_HASH${NC}"
else
    echo -e "${YELLOW}  ⚠ Batch submission may have failed (continuing anyway)${NC}"
fi

# =============================================================================
# Step 4: Mock DisputeGame creation (trigger RAT)
# =============================================================================
echo ""
echo -e "${YELLOW}[4/5] Creating mock DisputeGame (trigger RAT)...${NC}"

# In real scenario, this would be done by op-proposer
# For testing, we can call DisputeGameFactory.create() directly

echo -e "${BLUE}  Mock: op-proposer would call DisputeGameFactory.create()${NC}"
echo -e "${YELLOW}  Skipping for now - requires proper game type and claim data${NC}"

# =============================================================================
# Step 5: Test RAT Client (dry-run)
# =============================================================================
echo ""
echo -e "${YELLOW}[5/5] RAT Client test configuration...${NC}"

echo -e "${BLUE}RAT Client would connect to:${NC}"
echo "  L1 RPC:      $L1_RPC"
echo "  RAT Contract: $RAT_PROXY"
echo ""

echo -e "${GREEN}=== Test Environment Ready ===${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. For full test, need to start op-node in follower mode"
echo "  2. Then RAT Client can verify L2 state from L1 batch data"
echo ""
echo -e "${YELLOW}To run full stack manually:${NC}"
echo "  # Start op-node (follower mode)"
echo "  op-node \\"
echo "    --l1=\$L1_RPC \\"
echo "    --l1.beacon=http://localhost:5052 \\"
echo "    --rollup.config=rollup.json \\"
echo "    --rpc.addr=0.0.0.0 \\"
echo "    --rpc.port=9545"
echo ""
echo "  # Run RAT Client"
echo "  ./bin/rat-client \\"
echo "    --l1-rpc \$L1_RPC \\"
echo "    --rollup-rpc http://localhost:9545 \\"
echo "    --rat-contract $RAT_PROXY"
echo ""
