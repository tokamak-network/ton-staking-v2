#!/bin/bash
# =============================================================================
# TON Staking V3 - Complete Registration and Staking Setup
# 
# This script performs the following steps:
# 1. Register Rollup Config to L1BridgeRegistry
# 2. Register CandidateAddOn (L2 Operator staking)
# 3. Register Validators
# 4. Verify system health
#
# IMPORTANT: This assumes genesis has been deployed via DeployV3FullForDevnet.s.sol
# and L1 is running on Anvil (not Geth due to PoS/beacon client issues)
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ADDRESSES_FILE="$PROJECT_ROOT/.devnet/addresses.json"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  TON Staking V3 - Registration & Staking Setup            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# =============================================================================
# Load Configuration
# =============================================================================

if [ ! -f "$ADDRESSES_FILE" ]; then
    echo -e "${RED}✗ Addresses file not found: $ADDRESSES_FILE${NC}"
    echo "  Please run genesis deployment first."
    exit 1
fi

# Load contract addresses
TON=$(jq -r '.ton' "$ADDRESSES_FILE")
WTON=$(jq -r '.wton' "$ADDRESSES_FILE")
LAYER2_MANAGER=$(jq -r '.layer2ManagerProxy' "$ADDRESSES_FILE")
L1_BRIDGE_REGISTRY=$(jq -r '.l1BridgeRegistryProxy' "$ADDRESSES_FILE")
SYSTEM_CONFIG=$(jq -r '.systemConfig' "$ADDRESSES_FILE")
SEIG_MANAGER=$(jq -r '.seigManagerProxy' "$ADDRESSES_FILE")

# RPC endpoints
L1_RPC="http://localhost:8545"
L2_RPC="http://localhost:9545"

# Test accounts (Anvil default accounts)
DEPLOYER_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
DEPLOYER_ADDR="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

TON_STAKING_DEPLOYER_KEY="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
TON_STAKING_DEPLOYER_ADDR="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"

VALIDATOR_KEY="0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"
VALIDATOR_ADDR="0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"

# Staking parameters
MIN_STAKING_AMOUNT="1001000000000000000000000000000" # 1001 WTON (minimum is 1000.1 WTON)
VALIDATOR_STAKE_AMOUNT="100000000000000000000000000000" # 100 WTON

echo -e "${BLUE}Configuration:${NC}"
echo "  L1 RPC:          $L1_RPC"
echo "  TON:             $TON"
echo "  WTON:            $WTON"
echo "  Layer2Manager:   $LAYER2_MANAGER"
echo "  L1BridgeRegistry: $L1_BRIDGE_REGISTRY"
echo "  SystemConfig:    $SYSTEM_CONFIG"
echo ""

# =============================================================================
# Step 1: Verify L1 Node
# =============================================================================

echo -e "${BLUE}[1/6] Verifying L1 node...${NC}"
if ! curl -s -X POST $L1_RPC -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' > /dev/null; then
    echo -e "${RED}✗ L1 node is not running at $L1_RPC${NC}"
    echo ""
    echo -e "${YELLOW}IMPORTANT: Use Anvil instead of Geth for L1${NC}"
    echo "  Geth in PoS mode requires beacon client and doesn't auto-mine blocks."
    echo ""
    echo "  To start Anvil L1:"
    echo "    anvil --port 8545 --chain-id 900 --block-time 1 \\"
    echo "      --init .devnet/genesis-l1-staking-v3.json"
    exit 1
fi
echo -e "${GREEN}✅ L1 node is running${NC}"

# Check if blocks are being produced
BLOCK_NUM=$(cast block-number --rpc-url $L1_RPC)
sleep 2
BLOCK_NUM_AFTER=$(cast block-number --rpc-url $L1_RPC)
if [ "$BLOCK_NUM" -eq "$BLOCK_NUM_AFTER" ]; then
    echo -e "${RED}✗ L1 node is not producing blocks!${NC}"
    echo "  Current block: $BLOCK_NUM"
    echo ""
    echo -e "${YELLOW}If using Geth, you need to configure Clique or use Anvil instead.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ L1 node is producing blocks (block: $BLOCK_NUM_AFTER)${NC}"
echo ""

# =============================================================================
# Step 2: Register Rollup Config to L1BridgeRegistry
# =============================================================================

echo -e "${BLUE}[2/6] Registering Rollup Config...${NC}"

# Check if already registered
ROLLUP_INFO=$(cast call $L1_BRIDGE_REGISTRY \
    "getRollupInfo(address)(uint8,address,bool,bool,string)" \
    $SYSTEM_CONFIG --rpc-url $L1_RPC)
ROLLUP_TYPE=$(echo "$ROLLUP_INFO" | head -1)

if [ "$ROLLUP_TYPE" != "0" ]; then
    echo -e "${YELLOW}⚠️  Rollup already registered (Type: $ROLLUP_TYPE)${NC}"
else
    echo "  Registering SystemConfig as Type 3 rollup..."
    cast send $L1_BRIDGE_REGISTRY \
        "registerRollupConfigByManager(address,uint8,address,string)" \
        $SYSTEM_CONFIG 3 $TON "Devnet L2" \
        --private-key $TON_STAKING_DEPLOYER_KEY \
        --rpc-url $L1_RPC > /dev/null
    
    echo -e "${GREEN}✅ Rollup Config registered${NC}"
fi
echo ""

# =============================================================================
# Step 3: Fund Accounts
# =============================================================================

echo -e "${BLUE}[3/6] Funding accounts...${NC}"

# Check balances
DEPLOYER_WTON=$(cast call $WTON "balanceOf(address)(uint256)" $DEPLOYER_ADDR --rpc-url $L1_RPC)
VALIDATOR_WTON=$(cast call $WTON "balanceOf(address)(uint256)" $VALIDATOR_ADDR --rpc-url $L1_RPC)

echo "  Deployer WTON:  $(cast --from-wei $DEPLOYER_WTON) WTON"
echo "  Validator WTON: $(cast --from-wei $VALIDATOR_WTON ether) wei"

# Transfer WTON to Validator if needed
MIN_VALIDATOR_WTON="200000000000000000000000000000" # 200 WTON
if [ "$(echo "$VALIDATOR_WTON < $MIN_VALIDATOR_WTON" | bc -l)" -eq 1 ]; then
    echo "  Transferring 2000 WTON to Validator..."
    cast send $WTON "transfer(address,uint256)" \
        $VALIDATOR_ADDR 2000000000000000000000000000000 \
        --private-key $DEPLOYER_KEY --rpc-url $L1_RPC > /dev/null
    echo -e "${GREEN}✅ Validator funded${NC}"
else
    echo -e "${GREEN}✅ Validator already has sufficient funds${NC}"
fi
echo ""

# =============================================================================
# Step 4: Register CandidateAddOn (L2 Operator Staking)
# =============================================================================

echo -e "${BLUE}[4/6] Registering CandidateAddOn (L2 Operator)...${NC}"

# Check if already registered
ROLLUP_CONFIG_INFO=$(cast call $LAYER2_MANAGER \
    "rollupConfigInfo(address)(uint8,address)" \
    $SYSTEM_CONFIG --rpc-url $L1_RPC 2>/dev/null || echo "0 0x0000000000000000000000000000000000000000")
ROLLUP_CONFIG_TYPE=$(echo "$ROLLUP_CONFIG_INFO" | head -1)

if [ "$ROLLUP_CONFIG_TYPE" != "0" ]; then
    echo -e "${YELLOW}⚠️  CandidateAddOn already registered${NC}"
else
    # Approve WTON
    echo "  Approving WTON to Layer2Manager..."
    cast send $WTON "approve(address,uint256)" $LAYER2_MANAGER \
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff \
        --private-key $DEPLOYER_KEY --rpc-url $L1_RPC > /dev/null
    
    # Register CandidateAddOn with minimum staking amount
    echo "  Registering with 1001 WTON stake..."
    cast send $LAYER2_MANAGER \
        "registerCandidateAddOn(address,uint256,bool,string)" \
        $SYSTEM_CONFIG $MIN_STAKING_AMOUNT false "Devnet L2 Operator" \
        --private-key $DEPLOYER_KEY --rpc-url $L1_RPC > /dev/null
    
    echo -e "${GREEN}✅ CandidateAddOn registered (L2 Operator staking complete)${NC}"
fi
echo ""

# =============================================================================
# Step 5: Register Validators
# =============================================================================

echo -e "${BLUE}[5/6] Registering Validators...${NC}"

# Check minimum staking amount
MIN_AMOUNT=$(cast call $SEIG_MANAGER "minimumAmount()(uint256)" --rpc-url $L1_RPC)
echo "  Minimum staking amount: $(cast --to-unit $MIN_AMOUNT ether) WTON"

# Validator registration would typically involve:
# 1. Approve WTON to DepositManager
# 2. Stake via DepositManager.deposit()
# 3. RAT will assign validators automatically based on stake

echo "  Approving WTON for Validator..."
cast send $WTON "approve(address,uint256)" \
    $(jq -r '.depositManagerProxy' "$ADDRESSES_FILE") \
    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff \
    --private-key $VALIDATOR_KEY --rpc-url $L1_RPC > /dev/null

echo "  Staking 100 WTON for Validator..."
DEPOSIT_MANAGER=$(jq -r '.depositManagerProxy' "$ADDRESSES_FILE")
cast send $DEPOSIT_MANAGER \
    "deposit(address,uint256)" \
    $SYSTEM_CONFIG $VALIDATOR_STAKE_AMOUNT \
    --private-key $VALIDATOR_KEY --rpc-url $L1_RPC > /dev/null

echo -e "${GREEN}✅ Validator registered and staked${NC}"
echo ""

# =============================================================================
# Step 6: Verify System Health
# =============================================================================

echo -e "${BLUE}[6/6] Verifying system health...${NC}"

# Check rollup registration
ROLLUP_INFO=$(cast call $L1_BRIDGE_REGISTRY \
    "getRollupInfo(address)(uint8,address,bool,bool,string)" \
    $SYSTEM_CONFIG --rpc-url $L1_RPC)
echo "  Rollup Type: $(echo "$ROLLUP_INFO" | head -1)"

# Check operator staking
ROLLUP_CONFIG_INFO=$(cast call $LAYER2_MANAGER \
    "rollupConfigInfo(address)(uint8,address)" \
    $SYSTEM_CONFIG --rpc-url $L1_RPC)
echo "  Operator Staking: Registered (Type: $(echo "$ROLLUP_CONFIG_INFO" | head -1))"

# Check validator staking
VALIDATOR_STAKE=$(cast call $DEPOSIT_MANAGER \
    "stakeOf(address,address)(uint256)" \
    $SYSTEM_CONFIG $VALIDATOR_ADDR --rpc-url $L1_RPC)
echo "  Validator Stake: $(cast --to-unit $VALIDATOR_STAKE ether) WTON"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ TON Staking V3 Setup Complete!                        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Monitor RAT events for validator assignments"
echo "  2. Start RAT clients (./scripts/manage-rat-clients.sh start)"
echo "  3. Monitor system health (./scripts/check-devnet-health.sh)"
echo ""
echo -e "${BLUE}Useful Commands:${NC}"
echo "  # Check L2 operator stake"
echo "  cast call $LAYER2_MANAGER 'rollupConfigInfo(address)(uint8,address)' $SYSTEM_CONFIG --rpc-url $L1_RPC"
echo ""
echo "  # Check validator stake"
echo "  cast call $DEPOSIT_MANAGER 'stakeOf(address,address)(uint256)' $SYSTEM_CONFIG $VALIDATOR_ADDR --rpc-url $L1_RPC"
echo ""
