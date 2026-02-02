#!/bin/bash

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

DEVNET_DIR=".devnet"
ADDRESSES_JSON="$DEVNET_DIR/addresses.json"
GENESIS_FILE="$DEVNET_DIR/genesis-l1-staking-v3.json"

# Check if addresses.json exists
if [ ! -f "$ADDRESSES_JSON" ]; then
    echo -e "${RED}Error: addresses.json not found${NC}"
    exit 1
fi

echo -e "${BLUE}Loading addresses from $ADDRESSES_JSON...${NC}"

# Export all addresses as environment variables
export TON=$(jq -r '.ton' "$ADDRESSES_JSON")
export WTON=$(jq -r '.wton' "$ADDRESSES_JSON")
export RAT_PROXY=$(jq -r '.ratProxy' "$ADDRESSES_JSON")
export L1_BRIDGE_REGISTRY_PROXY=$(jq -r '.l1BridgeRegistryProxy' "$ADDRESSES_JSON")
export LAYER2_MANAGER_PROXY=$(jq -r '.layer2ManagerProxy' "$ADDRESSES_JSON")
export SEIG_MANAGER_PROXY=$(jq -r '.seigManagerProxy' "$ADDRESSES_JSON")
export DEPOSIT_MANAGER_PROXY=$(jq -r '.depositManagerProxy' "$ADDRESSES_JSON")
export VALIDATOR_REWARD_PROXY=$(jq -r '.validatorRewardProxy' "$ADDRESSES_JSON")
export DISPUTE_GAME_FACTORY=$(jq -r '.disputeGameFactory' "$ADDRESSES_JSON")
export SYSTEM_CONFIG=$(jq -r '.systemConfig' "$ADDRESSES_JSON")
export DAO_COMMITTEE_PROXY=$(jq -r '.daoCommitteeProxy' "$ADDRESSES_JSON")
export MOCK_LAYER2=$(jq -r '.mockLayer2' "$ADDRESSES_JSON")
export OPERATOR_MANAGER=$(jq -r '.operatorManager' "$ADDRESSES_JSON")

echo -e "${GREEN}Addresses loaded${NC}"
echo ""

# Start Anvil with genesis file
echo -e "${BLUE}Starting temporary Anvil instance...${NC}"
anvil --init "$GENESIS_FILE" --port 18545 > /dev/null 2>&1 &
ANVIL_PID=$!
sleep 3

# Run verification script
echo -e "${BLUE}Running verification...${NC}"
forge script script/VerifyGenesisSetup.s.sol --via-ir --fork-url http://localhost:18545
RESULT=$?

# Kill Anvil
kill $ANVIL_PID 2>/dev/null || true

exit $RESULT
