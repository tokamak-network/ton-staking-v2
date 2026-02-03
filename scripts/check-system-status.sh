#!/bin/bash
# =============================================================================
# TON Staking V3 - System Status Dashboard
# 전체 시스템 상태를 한눈에 확인
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ADDRESSES_FILE="$PROJECT_ROOT/.devnet/addresses.json"

# RPC endpoints
L1_RPC="http://localhost:8545"
L2_RPC="http://localhost:9545"

# Load contract addresses
if [ ! -f "$ADDRESSES_FILE" ]; then
    echo -e "${RED}✗ Addresses file not found: $ADDRESSES_FILE${NC}"
    exit 1
fi

TON=$(jq -r '.ton' "$ADDRESSES_FILE")
WTON=$(jq -r '.wton' "$ADDRESSES_FILE")
SEIG_MANAGER=$(jq -r '.seigManagerProxy' "$ADDRESSES_FILE")
DEPOSIT_MANAGER=$(jq -r '.depositManagerProxy' "$ADDRESSES_FILE")
LAYER2_MANAGER=$(jq -r '.layer2ManagerProxy' "$ADDRESSES_FILE")
L1_BRIDGE_REGISTRY=$(jq -r '.l1BridgeRegistryProxy' "$ADDRESSES_FILE")
LAYER2_REGISTRY=$(jq -r '.layer2RegistryProxy' "$ADDRESSES_FILE")
RAT=$(jq -r '.ratProxy' "$ADDRESSES_FILE")
VALIDATOR_REWARD=$(jq -r '.validatorRewardProxy' "$ADDRESSES_FILE")
SYSTEM_CONFIG=$(jq -r '.systemConfig' "$ADDRESSES_FILE")
DISPUTE_GAME_FACTORY=$(jq -r '.disputeGameFactory' "$ADDRESSES_FILE")

# Known accounts
DEPLOYER_ADDR="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
TON_STAKING_DEPLOYER="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
VALIDATOR1_ADDR="0x90F79bf6EB2c4f870365E785982E1f101E93b906"
VALIDATOR2_ADDR="0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65"
VALIDATOR3_ADDR="0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc"
VALIDATOR4_ADDR="0x976EA74026E726554dB657fA54763abd0C3a0aa9"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         TON Staking V3 - System Status Dashboard          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# =============================================================================
# 1. Node Status
# =============================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}1. NODE STATUS${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# L1 Node
if curl -s -X POST $L1_RPC -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' > /dev/null 2>&1; then
    L1_BLOCK=$(cast block-number --rpc-url $L1_RPC 2>/dev/null || echo "N/A")
    CHAIN_ID=$(cast chain-id --rpc-url $L1_RPC 2>/dev/null || echo "N/A")
    echo -e "L1 Node (Anvil):    ${GREEN}✅ Running${NC}"
    echo -e "  RPC:              $L1_RPC"
    echo -e "  Chain ID:         $CHAIN_ID"
    echo -e "  Current Block:    $L1_BLOCK"
    
    # Check if blocks are being produced
    sleep 2
    L1_BLOCK_AFTER=$(cast block-number --rpc-url $L1_RPC 2>/dev/null || echo "N/A")
    if [ "$L1_BLOCK" != "$L1_BLOCK_AFTER" ]; then
        echo -e "  Block Production: ${GREEN}✅ Active${NC}"
    else
        echo -e "  Block Production: ${RED}❌ Stalled${NC}"
    fi
else
    echo -e "L1 Node (Anvil):    ${RED}❌ Not Running${NC}"
fi

echo ""

# L2 Node
if curl -s -X POST $L2_RPC -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' > /dev/null 2>&1; then
    L2_BLOCK=$(cast block-number --rpc-url $L2_RPC 2>/dev/null || echo "N/A")
    L2_CHAIN_ID=$(cast chain-id --rpc-url $L2_RPC 2>/dev/null || echo "N/A")
    echo -e "L2 Node (op-geth):  ${GREEN}✅ Running${NC}"
    echo -e "  RPC:              $L2_RPC"
    echo -e "  Chain ID:         $L2_CHAIN_ID"
    echo -e "  Current Block:    $L2_BLOCK"
else
    echo -e "L2 Node (op-geth):  ${YELLOW}⚠️  Not Running${NC}"
fi

echo ""

# Docker containers
echo -e "${BLUE}Docker Containers:${NC}"
CONTAINERS=$(docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null | grep "ton-staking" || echo "")
if [ -z "$CONTAINERS" ]; then
    echo -e "  ${YELLOW}⚠️  No containers running${NC}"
else
    echo "$CONTAINERS" | while IFS= read -r line; do
        if [[ $line == *"Up"* ]]; then
            echo -e "  ${GREEN}✅${NC} $line"
        else
            echo -e "  ${RED}❌${NC} $line"
        fi
    done
fi

echo ""

# =============================================================================
# 2. Contract Addresses
# =============================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}2. CONTRACT ADDRESSES${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${BLUE}Tokens:${NC}"
echo "  TON:                   $TON"
echo "  WTON:                  $WTON"
echo ""

echo -e "${BLUE}Core Managers:${NC}"
echo "  SeigManager:           $SEIG_MANAGER"
echo "  DepositManager:        $DEPOSIT_MANAGER"
echo "  Layer2Manager:         $LAYER2_MANAGER"
echo "  L1BridgeRegistry:      $L1_BRIDGE_REGISTRY"
echo "  Layer2Registry:        $LAYER2_REGISTRY"
echo ""

echo -e "${BLUE}V3 Components:${NC}"
echo "  RAT:                   $RAT"
echo "  ValidatorReward:       $VALIDATOR_REWARD"
echo ""

echo -e "${BLUE}Optimism Stack:${NC}"
echo "  SystemConfig:          $SYSTEM_CONFIG"
echo "  DisputeGameFactory:    $DISPUTE_GAME_FACTORY"
echo ""

# =============================================================================
# 3. Rollup Registration
# =============================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}3. ROLLUP REGISTRATION${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

ROLLUP_INFO=$(cast call $L1_BRIDGE_REGISTRY \
    "getRollupInfo(address)(uint8,address,bool,bool,string)" \
    $SYSTEM_CONFIG --rpc-url $L1_RPC 2>/dev/null)

ROLLUP_TYPE=$(echo "$ROLLUP_INFO" | head -1 | tr -d ' ')
L2_TON=$(echo "$ROLLUP_INFO" | sed -n '2p' | tr -d ' ')

if [ "$ROLLUP_TYPE" != "0" ]; then
    echo -e "Status:                ${GREEN}✅ Registered${NC}"
    echo "  SystemConfig:        $SYSTEM_CONFIG"
    echo "  Rollup Type:         $ROLLUP_TYPE (Optimism Bedrock DisputeGame)"
    echo "  L2 TON:              $L2_TON"
else
    echo -e "Status:                ${RED}❌ Not Registered${NC}"
fi

echo ""

# =============================================================================
# 4. L2 Operator (CandidateAddOn)
# =============================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}4. L2 OPERATOR (CANDIDATEADDON)${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

ROLLUP_CONFIG_INFO=$(cast call $LAYER2_MANAGER \
    "rollupConfigInfo(address)(uint8,address)" \
    $SYSTEM_CONFIG --rpc-url $L1_RPC 2>/dev/null)

CONFIG_STATUS=$(echo "$ROLLUP_CONFIG_INFO" | head -1 | tr -d ' ')
OPERATOR_MANAGER=$(echo "$ROLLUP_CONFIG_INFO" | sed -n '2p' | tr -d ' ')

if [ "$CONFIG_STATUS" != "0" ]; then
    echo -e "Status:                ${GREEN}✅ Registered${NC}"
    echo "  Operator:            $DEPLOYER_ADDR"
    echo "  OperatorManager:     $OPERATOR_MANAGER"
    
    # Get CandidateAddOn
    CANDIDATE_ADDON=$(cast call $LAYER2_MANAGER \
        "candidateAddOnOfOperator(address)(address)" \
        $OPERATOR_MANAGER --rpc-url $L1_RPC 2>/dev/null | tr -d ' ')
    echo "  CandidateAddOn:      $CANDIDATE_ADDON"
    
    # Get operator stake
    OPERATOR_STAKE=$(cast call $SEIG_MANAGER \
        "stakeOf(address,address)(uint256)" \
        $CANDIDATE_ADDON $OPERATOR_MANAGER --rpc-url $L1_RPC 2>/dev/null | tr -d ' ')
    echo "  Stake:               $OPERATOR_STAKE (~1001 WTON)"
    
    # Check Layer2Registry
    IS_LAYER2=$(cast call $LAYER2_REGISTRY \
        "layer2s(address)(bool)" \
        $CANDIDATE_ADDON --rpc-url $L1_RPC 2>/dev/null | tr -d ' ')
    
    if [ "$IS_LAYER2" = "true" ]; then
        echo -e "  Layer2Registry:      ${GREEN}✅ Registered${NC}"
    else
        echo -e "  Layer2Registry:      ${RED}❌ Not Registered${NC}"
    fi
else
    echo -e "Status:                ${RED}❌ Not Registered${NC}"
    CANDIDATE_ADDON=""
fi

echo ""

# =============================================================================
# 5. Validators
# =============================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}5. VALIDATORS${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ -n "$CANDIDATE_ADDON" ]; then
    VALIDATORS=("$VALIDATOR1_ADDR" "$VALIDATOR2_ADDR" "$VALIDATOR3_ADDR" "$VALIDATOR4_ADDR")
    VALIDATOR_NAMES=("Validator #1" "Validator #2" "Validator #3" "Validator #4")
    
    TOTAL_DEPOSITED=0
    ACTIVE_COUNT=0
    
    for i in "${!VALIDATORS[@]}"; do
        ADDR="${VALIDATORS[$i]}"
        NAME="${VALIDATOR_NAMES[$i]}"
        
        # Get stake
        STAKE=$(cast call $SEIG_MANAGER \
            "stakeOf(address,address)(uint256)" \
            $CANDIDATE_ADDON $ADDR --rpc-url $L1_RPC 2>/dev/null | tr -d ' ' | sed 's/\[.*\]//')
        
        # Get RAT registration
        RAT_INFO=$(cast call $RAT \
            "getValidatorRegistration(address,address)(uint256,uint256,bool)" \
            $ADDR $SYSTEM_CONFIG --rpc-url $L1_RPC 2>/dev/null || echo "0 0 false")
        
        IS_ACTIVE=$(echo "$RAT_INFO" | tail -1 | tr -d ' ')
        
        echo -e "${BLUE}$NAME:${NC} $ADDR"
        
        if [ "$STAKE" != "0" ] && [ -n "$STAKE" ]; then
            echo -e "  Deposited:           ${GREEN}✅ $STAKE wei (~100 WTON)${NC}"
            TOTAL_DEPOSITED=$((TOTAL_DEPOSITED + 1))
        else
            echo -e "  Deposited:           ${RED}❌ 0${NC}"
        fi
        
        if [ "$IS_ACTIVE" = "true" ]; then
            echo -e "  RAT Registration:    ${GREEN}✅ Active${NC}"
            ACTIVE_COUNT=$((ACTIVE_COUNT + 1))
        else
            echo -e "  RAT Registration:    ${YELLOW}⚠️  Not Registered${NC}"
        fi
        echo ""
    done
    
    echo -e "${BLUE}Summary:${NC}"
    echo "  Total Deposited:     $TOTAL_DEPOSITED / 4"
    echo "  RAT Active:          $ACTIVE_COUNT / 4"
else
    echo -e "${YELLOW}⚠️  CandidateAddOn not found. Register L2 Operator first.${NC}"
fi

echo ""

# =============================================================================
# 6. System Configuration
# =============================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}6. SYSTEM CONFIGURATION${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# V3 Migration
V3_MIGRATED=$(cast call $SEIG_MANAGER "v3Migrated()(bool)" --rpc-url $L1_RPC 2>/dev/null | tr -d ' ')
if [ "$V3_MIGRATED" = "true" ]; then
    echo -e "V3 Migration:          ${GREEN}✅ Complete${NC}"
else
    echo -e "V3 Migration:          ${RED}❌ Not Migrated${NC}"
fi

# Minimum Amount
MIN_AMOUNT=$(cast call $SEIG_MANAGER "minimumAmount()(uint256)" --rpc-url $L1_RPC 2>/dev/null | tr -d ' ' | sed 's/\[.*\]//')
echo "Minimum Stake:         $MIN_AMOUNT (~1000.1 WTON)"

# RAT Parameters
if [ -n "$CANDIDATE_ADDON" ]; then
    RAT_MIN=$(cast call $RAT "getDynamicMinimumCollateral(address)(uint256)" \
        $SYSTEM_CONFIG --rpc-url $L1_RPC 2>/dev/null | tr -d ' ' | sed 's/\[.*\]//')
    echo "RAT Min Collateral:    $RAT_MIN (~60 WTON)"
fi

# Active L2 Count
ACTIVE_L2_COUNT=$(cast call $RAT "getActiveValidatorCount(address)(uint256)" \
    $SYSTEM_CONFIG --rpc-url $L1_RPC 2>/dev/null | tr -d ' ' | sed 's/\[.*\]//' || echo "0")
echo "Active Validators:     $ACTIVE_L2_COUNT"

echo ""

# =============================================================================
# 7. Account Balances
# =============================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}7. KEY ACCOUNT BALANCES${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

ACCOUNTS=("$DEPLOYER_ADDR" "$TON_STAKING_DEPLOYER")
ACCOUNT_NAMES=("Deployer" "TON Staking Deployer")

for i in "${!ACCOUNTS[@]}"; do
    ADDR="${ACCOUNTS[$i]}"
    NAME="${ACCOUNT_NAMES[$i]}"
    
    WTON_BAL=$(cast call $WTON "balanceOf(address)(uint256)" $ADDR --rpc-url $L1_RPC 2>/dev/null | tr -d ' ' | sed 's/\[.*\]//')
    
    echo -e "${BLUE}$NAME:${NC}"
    echo "  Address:             $ADDR"
    echo "  WTON Balance:        $WTON_BAL"
done

echo ""

# =============================================================================
# 8. Quick Actions
# =============================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}8. QUICK ACTIONS${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo "Start/Stop Services:"
echo "  docker-compose up -d          # Start all services"
echo "  docker-compose down           # Stop all services"
echo ""

echo "Check Logs:"
echo "  docker logs ton-staking-l1 --tail 50"
echo "  docker logs ton-staking-l2-node --tail 50"
echo ""

echo "Register Validator to RAT:"
if [ -n "$CANDIDATE_ADDON" ]; then
    echo "  cast send $RAT \\"
    echo "    'registerValidator(address)' $SYSTEM_CONFIG \\"
    echo "    --private-key YOUR_VALIDATOR_KEY --rpc-url $L1_RPC"
fi
echo ""

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}System Status Check Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
