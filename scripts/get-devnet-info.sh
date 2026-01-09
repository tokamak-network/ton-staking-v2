#!/bin/bash
# =============================================================================
# Get Devnet Information
# =============================================================================
# This script extracts RPC endpoints and contract addresses from running devnet
#
# Usage:
#   ./scripts/get-devnet-info.sh
#   OR
#   make devnet-info
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

echo -e "${BLUE}=== Devnet Information ===${NC}"
echo ""

# =============================================================================
# Check if devnet is running
# =============================================================================

if ! kurtosis enclave inspect simple-devnet &> /dev/null; then
    echo -e "${RED}Error: Devnet is not running${NC}"
    echo "Start it with: make devnet-start"
    exit 1
fi

# =============================================================================
# Extract RPC Endpoints
# =============================================================================

echo -e "${YELLOW}RPC Endpoints:${NC}"
echo ""

# Get enclave inspection output
INSPECT_OUTPUT=$(kurtosis enclave inspect simple-devnet 2>/dev/null)

# Extract L1 RPC (el-1-geth-teku)
L1_RPC_PORT=$(echo "$INSPECT_OUTPUT" | grep "el-1-geth-teku" | grep "8545/tcp" | awk '{print $3}' | cut -d':' -f2 | head -1)
if [ -n "$L1_RPC_PORT" ]; then
    L1_RPC="http://localhost:$L1_RPC_PORT"
    echo -e "  ${GREEN}L1 RPC:${NC}      $L1_RPC"
else
    echo -e "  ${RED}L1 RPC:${NC}      Not found"
fi

# Extract L2 RPC (op-geth)
L2_RPC_PORT=$(echo "$INSPECT_OUTPUT" | grep "op-el-.*-op-geth" | grep "8545/tcp" | awk '{print $3}' | cut -d':' -f2 | head -1)
if [ -n "$L2_RPC_PORT" ]; then
    L2_RPC="http://localhost:$L2_RPC_PORT"
    echo -e "  ${GREEN}L2 RPC:${NC}      $L2_RPC"
else
    echo -e "  ${RED}L2 RPC:${NC}      Not found"
fi

# Extract Rollup RPC (op-node)
ROLLUP_RPC_PORT=$(echo "$INSPECT_OUTPUT" | grep "op-cl-.*-op-node" | grep "9545/tcp" | awk '{print $3}' | cut -d':' -f2 | head -1)
if [ -n "$ROLLUP_RPC_PORT" ]; then
    ROLLUP_RPC="http://localhost:$ROLLUP_RPC_PORT"
    echo -e "  ${GREEN}Rollup RPC:${NC}  $ROLLUP_RPC"
else
    echo -e "  ${RED}Rollup RPC:${NC}  Not found"
fi

echo ""

# =============================================================================
# Extract Contract Addresses
# =============================================================================

echo -e "${YELLOW}Contract Addresses (from genesis):${NC}"
echo ""

if [ -f "$DEVNET_DIR/addresses.json" ]; then
    # Check if jq is available
    if command -v jq &> /dev/null; then
        # Optimism contracts
        DISPUTE_GAME_FACTORY=$(jq -r '.disputeGameFactoryProxy // .DisputeGameFactoryProxy // "N/A"' "$DEVNET_DIR/optimism-addresses.json" 2>/dev/null || echo "N/A")
        SYSTEM_CONFIG=$(jq -r '.systemConfigProxy // .SystemConfigProxy // "N/A"' "$DEVNET_DIR/optimism-addresses.json" 2>/dev/null || echo "N/A")

        # TON Staking contracts
        RAT_PROXY=$(jq -r '.ratProxy // .rat // "N/A"' "$DEVNET_DIR/addresses.json" 2>/dev/null || echo "N/A")
        SEIG_MANAGER=$(jq -r '.seigManagerProxy // "N/A"' "$DEVNET_DIR/addresses.json" 2>/dev/null || echo "N/A")
        DEPOSIT_MANAGER=$(jq -r '.depositManagerProxy // "N/A"' "$DEVNET_DIR/addresses.json" 2>/dev/null || echo "N/A")

        echo -e "  ${BLUE}Optimism:${NC}"
        echo -e "    DisputeGameFactory: ${GREEN}$DISPUTE_GAME_FACTORY${NC}"
        echo -e "    SystemConfig:       ${GREEN}$SYSTEM_CONFIG${NC}"
        echo ""
        echo -e "  ${BLUE}TON Staking V3:${NC}"
        echo -e "    RAT Proxy:          ${GREEN}$RAT_PROXY${NC}"
        echo -e "    SeigManager:        ${GREEN}$SEIG_MANAGER${NC}"
        echo -e "    DepositManager:     ${GREEN}$DEPOSIT_MANAGER${NC}"
    else
        echo -e "  ${YELLOW}Install 'jq' to parse contract addresses${NC}"
        echo -e "  Raw file: $DEVNET_DIR/addresses.json"
    fi
else
    echo -e "  ${RED}addresses.json not found${NC}"
    echo -e "  Re-run: make devnet-allocs-offline"
fi

echo ""

# =============================================================================
# Save to environment file
# =============================================================================

if [ -n "$L1_RPC" ] && [ -n "$L2_RPC" ] && [ -n "$ROLLUP_RPC" ]; then
    ENV_FILE="$PROJECT_ROOT/.devnet.env"

    cat > "$ENV_FILE" << EOF
# Devnet RPC Endpoints
export L1_RPC="$L1_RPC"
export L2_RPC="$L2_RPC"
export ROLLUP_RPC="$ROLLUP_RPC"

# Contract Addresses
export DISPUTE_GAME_FACTORY="$DISPUTE_GAME_FACTORY"
export SYSTEM_CONFIG="$SYSTEM_CONFIG"
export RAT_PROXY="$RAT_PROXY"
export SEIG_MANAGER="$SEIG_MANAGER"
export DEPOSIT_MANAGER="$DEPOSIT_MANAGER"
EOF

    echo -e "${GREEN}✓ Environment variables saved to: ${YELLOW}.devnet.env${NC}"
    echo ""
    echo -e "${BLUE}To use in shell:${NC}"
    echo -e "  ${YELLOW}source .devnet.env${NC}"
    echo ""
fi

# =============================================================================
# Quick Tests
# =============================================================================

if [ -n "$L1_RPC" ] && command -v cast &> /dev/null; then
    echo -e "${YELLOW}Quick verification:${NC}"
    echo ""

    # Test L1 connection
    CHAIN_ID=$(cast chain-id --rpc-url "$L1_RPC" 2>/dev/null || echo "")
    if [ -n "$CHAIN_ID" ]; then
        echo -e "  ${GREEN}✓ L1 RPC connected (Chain ID: $CHAIN_ID)${NC}"
    else
        echo -e "  ${RED}✗ L1 RPC connection failed${NC}"
    fi

    # Test RAT connection if address is known
    if [ "$RAT_PROXY" != "N/A" ] && [ -n "$RAT_PROXY" ]; then
        # Check if RAT has code
        CODE=$(cast code "$RAT_PROXY" --rpc-url "$L1_RPC" 2>/dev/null || echo "")
        if [ -n "$CODE" ] && [ "$CODE" != "0x" ]; then
            echo -e "  ${GREEN}✓ RAT contract deployed at $RAT_PROXY${NC}"

            # Try to read RAT address from DisputeGameFactory
            if [ "$DISPUTE_GAME_FACTORY" != "N/A" ] && [ -n "$DISPUTE_GAME_FACTORY" ]; then
                DGF_RAT=$(cast call "$DISPUTE_GAME_FACTORY" "rat()(address)" --rpc-url "$L1_RPC" 2>/dev/null || echo "")
                if [ "$DGF_RAT" = "$RAT_PROXY" ]; then
                    echo -e "  ${GREEN}✓ RAT connected to DisputeGameFactory${NC}"
                else
                    echo -e "  ${YELLOW}⚠ DisputeGameFactory.rat() = $DGF_RAT (expected $RAT_PROXY)${NC}"
                fi
            fi
        else
            echo -e "  ${RED}✗ RAT contract not found at $RAT_PROXY${NC}"
        fi
    fi

    echo ""
fi

# =============================================================================
# Usage Examples
# =============================================================================

echo -e "${BLUE}Usage examples:${NC}"
echo ""
echo -e "  ${YELLOW}# Query L1 chain${NC}"
echo -e "  cast block latest --rpc-url $L1_RPC"
echo ""
echo -e "  ${YELLOW}# Query RAT contract${NC}"
echo -e "  cast call $RAT_PROXY \"triggerProbability()(uint256)\" --rpc-url $L1_RPC"
echo ""
echo -e "  ${YELLOW}# Monitor RAT events${NC}"
echo -e "  cast logs --from-block 0 --address $RAT_PROXY --rpc-url $L1_RPC"
echo ""
echo -e "  ${YELLOW}# Start RAT Client${NC}"
echo -e "  source .devnet.env"
echo -e "  make rat-client-run"
echo ""
