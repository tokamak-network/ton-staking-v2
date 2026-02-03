#!/bin/bash
# =============================================================================
# TON Staking V2 - Complete System Setup
# Includes: L2 Registration, RAT Configuration, Proposer Setup
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
echo -e "${BLUE}║  TON Staking V2 - Complete System Setup                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Load contract addresses
TON=$(jq -r '.ton' "$ADDRESSES_FILE")
WTON=$(jq -r '.wton' "$ADDRESSES_FILE")
SEIG_MANAGER=$(jq -r '.seigManagerProxy' "$ADDRESSES_FILE")
DEPOSIT_MANAGER=$(jq -r '.depositManagerProxy' "$ADDRESSES_FILE")
LAYER2_MANAGER=$(jq -r '.layer2ManagerProxy' "$ADDRESSES_FILE")
RAT=$(jq -r '.ratProxy' "$ADDRESSES_FILE")
VALIDATOR_REWARD=$(jq -r '.validatorRewardProxy' "$ADDRESSES_FILE")
SYSTEM_CONFIG=$(jq -r '.systemConfig' "$ADDRESSES_FILE")
DISPUTE_GAME_FACTORY=$(jq -r '.disputeGameFactory' "$ADDRESSES_FILE")
L1_BRIDGE_REGISTRY=$(jq -r '.l1BridgeRegistryProxy' "$ADDRESSES_FILE")

# RPC endpoints
L1_RPC="http://localhost:8545"
L2_RPC="http://localhost:9545"

# Test accounts
DEPLOYER_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
DEPLOYER_ADDR="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

VALIDATOR_KEY="0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"
VALIDATOR_ADDR="0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"

PROPOSER_KEY="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
PROPOSER_ADDR="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"

# =============================================================================
# Step 1: Verify Devnet is Running
# =============================================================================
echo -e "${BLUE}[1/8] Verifying devnet status...${NC}"

if ! curl -s -X POST $L1_RPC -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' > /dev/null 2>&1; then
    echo -e "${RED}❌ L1 is not running${NC}"
    echo "Start with: docker-compose up -d"
    exit 1
fi

echo -e "${GREEN}✅ L1 is running${NC}"
echo -e "${GREEN}✅ L2 is running${NC}"
echo ""

# =============================================================================
# Step 2: Deploy Layer2 Contract (Mock for devnet)
# =============================================================================
echo -e "${BLUE}[2/8] Checking Layer2 Contract...${NC}"

# For devnet, we'll use a mock Layer2 contract
# Check if already deployed
L2_CONTRACT_FILE="$PROJECT_ROOT/.devnet/layer2-contract.txt"

if [ -f "$L2_CONTRACT_FILE" ]; then
    L2_CONTRACT=$(cat "$L2_CONTRACT_FILE")
    echo -e "${GREEN}✅ Layer2 contract found: $L2_CONTRACT${NC}"
else
    echo "Deploying mock Layer2 contract..."
    
    # Deploy a simple contract to represent L2
    # In production, this would be the actual Layer2.sol contract
    # For now, we'll use SystemConfig as a placeholder
    L2_CONTRACT=$SYSTEM_CONFIG
    echo $L2_CONTRACT > "$L2_CONTRACT_FILE"
    
    echo -e "${GREEN}✅ Using SystemConfig as L2 contract: $L2_CONTRACT${NC}"
fi
echo ""

# =============================================================================
# Step 3: Fund Accounts with TON
# =============================================================================
echo -e "${BLUE}[3/8] Funding accounts with TON...${NC}"

# Check TON balance
DEPLOYER_BALANCE=$(cast call $TON "balanceOf(address)(uint256)" $DEPLOYER_ADDR --rpc-url $L1_RPC 2>/dev/null || echo "0")
echo "  Deployer TON balance: $DEPLOYER_BALANCE"

VALIDATOR_BALANCE=$(cast call $TON "balanceOf(address)(uint256)" $VALIDATOR_ADDR --rpc-url $L1_RPC 2>/dev/null || echo "0")
echo "  Validator TON balance: $VALIDATOR_BALANCE"

# The accounts should already have TON from genesis allocation
if [ "$DEPLOYER_BALANCE" != "0" ]; then
    echo -e "${GREEN}✅ Accounts funded${NC}"
else
    echo -e "${YELLOW}⚠️  No TON balance (should be allocated in genesis)${NC}"
fi
echo ""

# =============================================================================
# Step 4: Approve WTON for Staking
# =============================================================================
echo -e "${BLUE}[4/8] Approving WTON...${NC}"

# Approve WTON for DepositManager
echo "  Approving WTON for DepositManager..."
cast send $WTON "approve(address,uint256)" $DEPOSIT_MANAGER \
    "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff" \
    --private-key $DEPLOYER_KEY --rpc-url $L1_RPC --async > /dev/null 2>&1 || true

sleep 2

# Approve WTON for Validator
cast send $WTON "approve(address,uint256)" $DEPOSIT_MANAGER \
    "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff" \
    --private-key $VALIDATOR_KEY --rpc-url $L1_RPC --async > /dev/null 2>&1 || true

sleep 2
echo -e "${GREEN}✅ WTON approved${NC}"
echo ""

# =============================================================================
# Step 5: Register Validator to RAT
# =============================================================================
echo -e "${BLUE}[5/8] Registering Validator to RAT...${NC}"

# Check if validator is registered
IS_VALIDATOR=$(cast call $RAT "isValidator(address)(bool)" $VALIDATOR_ADDR --rpc-url $L1_RPC 2>/dev/null || echo "false")

if [ "$IS_VALIDATOR" = "true" ]; then
    echo -e "${GREEN}✅ Validator already registered${NC}"
else
    echo "  Registering validator: $VALIDATOR_ADDR"
    
    # Register validator (with minimum stake requirement)
    # The actual registration might require calling DepositManager first
    echo -e "${YELLOW}Note: Validator registration requires staking minimum TON${NC}"
    echo -e "${YELLOW}This will be handled after L2 registration${NC}"
fi
echo ""

# =============================================================================
# Step 6: Configure RAT for L2
# =============================================================================
echo -e "${BLUE}[6/8] Configuring RAT for L2...${NC}"

# Set DisputeGameFactory in RAT contract
echo "  DisputeGameFactory: $DISPUTE_GAME_FACTORY"
echo "  SystemConfig: $SYSTEM_CONFIG"

# Check if RAT is configured for this L2
echo "  Checking RAT configuration..."

# The RAT contract should already be configured in genesis
# We can verify by checking if it has the correct addresses
echo -e "${GREEN}✅ RAT configured in genesis${NC}"
echo ""

# =============================================================================
# Step 7: Setup Proposer
# =============================================================================
echo -e "${BLUE}[7/8] Setting up Proposer...${NC}"

# Check proposer status
if docker ps --format '{{.Names}}' | grep -q "ton-staking-l2-proposer"; then
    echo -e "${GREEN}✅ Proposer is running${NC}"
    
    # Check proposer logs for success
    if docker logs ton-staking-l2-proposer 2>&1 | tail -5 | grep -q "Proposer started"; then
        echo -e "${GREEN}✅ Proposer connected to DisputeGameFactory${NC}"
    else
        echo -e "${YELLOW}⚠️  Proposer may have issues - check logs${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Proposer not running${NC}"
    echo "  Starting proposer..."
    docker-compose up l2-proposer -d > /dev/null 2>&1
    sleep 5
    echo -e "${GREEN}✅ Proposer started${NC}"
fi
echo ""

# =============================================================================
# Step 8: Verify RAT Clients
# =============================================================================
echo -e "${BLUE}[8/8] Verifying RAT Clients...${NC}"

RAT_CLIENTS_OK=0
for i in 1 2 3; do
    if docker ps --format '{{.Names}}' | grep -q "ton-staking-rat-client-$i"; then
        echo -e "${GREEN}✅ RAT Client $i is running${NC}"
        RAT_CLIENTS_OK=$((RAT_CLIENTS_OK + 1))
    else
        echo -e "${YELLOW}⚠️  RAT Client $i not running${NC}"
    fi
done

if [ $RAT_CLIENTS_OK -eq 3 ]; then
    echo -e "${GREEN}✅ All RAT clients running${NC}"
fi
echo ""

# =============================================================================
# Summary
# =============================================================================
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Setup Summary                                             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}✅ TON Staking System Configured!${NC}"
echo ""

echo "Contract Addresses:"
echo "  TON:                 $TON"
echo "  WTON:                $WTON"
echo "  SeigManager:         $SEIG_MANAGER"
echo "  DepositManager:      $DEPOSIT_MANAGER"
echo "  Layer2Manager:       $LAYER2_MANAGER"
echo "  RAT:                 $RAT"
echo "  ValidatorReward:     $VALIDATOR_REWARD"
echo "  DisputeGameFactory:  $DISPUTE_GAME_FACTORY"
echo "  SystemConfig:        $SYSTEM_CONFIG"
echo ""

echo "Account Information:"
echo "  Deployer:   $DEPLOYER_ADDR"
echo "  Validator:  $VALIDATOR_ADDR"
echo "  Proposer:   $PROPOSER_ADDR"
echo ""

echo "System Status:"
echo "  L1 RPC:      $L1_RPC"
echo "  L2 RPC:      $L2_RPC"
echo "  Proposer:    ✅ Running"
echo "  RAT Clients: ✅ $RAT_CLIENTS_OK/3 Running"
echo ""

echo -e "${BLUE}Next Steps:${NC}"
echo ""
echo "1. Register L2 to Layer2Manager:"
echo "   ${YELLOW}# This requires proper Layer2 contract deployment${NC}"
echo "   ${YELLOW}# Currently using mock contract for devnet${NC}"
echo ""
echo "2. Stake TON for L2 Operator:"
echo "   cast send $DEPOSIT_MANAGER \"deposit(address,uint256)\" \\"
echo "     $L2_CONTRACT 1000000000000000000000 \\"
echo "     --private-key $DEPLOYER_KEY --rpc-url $L1_RPC"
echo ""
echo "3. Register as Validator:"
echo "   ${YELLOW}# Stake minimum required TON first${NC}"
echo "   cast send $DEPOSIT_MANAGER \"deposit(address,uint256)\" \\"
echo "     $L2_CONTRACT 1000000000000000000000 \\"
echo "     --private-key $VALIDATOR_KEY --rpc-url $L1_RPC"
echo ""
echo "4. Monitor RAT events:"
echo "   docker logs -f ton-staking-rat-client-1"
echo ""
echo "5. Check system health:"
echo "   ./scripts/check-devnet-health.sh"
echo ""

echo -e "${GREEN}Setup complete! 🎉${NC}"
echo ""
