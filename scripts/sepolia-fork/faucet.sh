#!/bin/bash
# =============================================================================
# Sepolia Fork Faucet - Mint ETH to any address
# =============================================================================
# Usage: ./faucet.sh <address> [amount_in_eth]
# Example: ./faucet.sh 0x1234... 100
# =============================================================================

set -eo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 <address> [amount_in_eth]"
    echo "Example: $0 0x1234567890123456789012345678901234567890 100"
    exit 1
fi

ADDRESS="$1"
AMOUNT_ETH="${2:-100}"  # Default 100 ETH

# Validate address
if ! [[ "$ADDRESS" =~ ^0x[a-fA-F0-9]{40}$ ]]; then
    echo -e "${RED}Error: Invalid Ethereum address${NC}"
    exit 1
fi

# Convert ETH to Wei (hex)
AMOUNT_WEI=$(echo "$AMOUNT_ETH * 10^18" | bc)
AMOUNT_HEX=$(printf "0x%x" $AMOUNT_WEI)

echo -e "${YELLOW}Minting $AMOUNT_ETH ETH to $ADDRESS...${NC}"

# Check if L1 is running
if ! cast block-number --rpc-url http://localhost:8545 &> /dev/null; then
    echo -e "${RED}Error: Sepolia fork devnet is not running${NC}"
    echo "Start it with: make devnet-sepolia-fork-start"
    exit 1
fi

# Mint ETH using anvil_setBalance
cast rpc anvil_setBalance "$ADDRESS" "$AMOUNT_HEX" --rpc-url http://localhost:8545

# Verify balance
BALANCE=$(cast balance "$ADDRESS" --rpc-url http://localhost:8545 --ether)

echo -e "${GREEN}✓ Successfully minted $AMOUNT_ETH ETH${NC}"
echo "New balance: $BALANCE ETH"
