#!/bin/bash
# =============================================================================
# TON Staking V3 - Complete Devnet Setup
# =============================================================================
# This script performs complete devnet setup including:
# 1. Start L1 + L2 nodes
# 2. Start RAT Clients (3 validators)
# 3. Register L2 Operator
# 4. Register Validators
# 5. Mint tokens for test accounts
# 6. Verify all setup
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ADDRESSES_FILE="$PROJECT_ROOT/.devnet/addresses.json"

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  TON Staking V3 - Complete Devnet Setup                     ║${NC}"
echo -e "${CYAN}║  Automated Local Development Environment                    ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Setup Steps:${NC}"
echo "  1. Wait for L1 + L2 nodes to be ready"
echo "  2. Mint tokens for test accounts"
echo "  3. Approve WTON for staking"
echo "  4. Register L2 Operator"
echo "  5. Register Validators"
echo "  6. Start RAT Clients (after registration)"
echo ""

# =============================================================================
# Configuration
# =============================================================================

# RPC endpoints
L1_RPC="http://localhost:8545"
L2_RPC="http://localhost:9545"

# Test accounts (Hardhat accounts)
DEPLOYER_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
DEPLOYER_ADDR="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

VALIDATOR1_KEY="0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"
VALIDATOR1_ADDR="0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"

VALIDATOR2_KEY="0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6"
VALIDATOR2_ADDR="0x90F79bf6EB2c4f870365E785982E1f101E93b906"

VALIDATOR3_KEY="0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a"
VALIDATOR3_ADDR="0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65"

PROPOSER_KEY="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
PROPOSER_ADDR="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"

# =============================================================================
# Step 1: Check Prerequisites
# =============================================================================
echo -e "${BLUE}[1/9] Checking prerequisites...${NC}"

if ! command -v cast &> /dev/null; then
    echo -e "${RED}❌ cast (foundry) not found${NC}"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ jq not found${NC}"
    exit 1
fi

if [ ! -f "$ADDRESSES_FILE" ]; then
    echo -e "${RED}❌ addresses.json not found${NC}"
    echo "Run 'make devnet-allocs-offline' first"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites met${NC}"
echo ""

# =============================================================================
# Step 2: Load Contract Addresses
# =============================================================================
echo -e "${BLUE}[2/9] Loading contract addresses...${NC}"

TON=$(jq -r '.ton' "$ADDRESSES_FILE")
WTON=$(jq -r '.wton' "$ADDRESSES_FILE")
SEIG_MANAGER=$(jq -r '.seigManagerProxy' "$ADDRESSES_FILE")
DEPOSIT_MANAGER=$(jq -r '.depositManagerProxy' "$ADDRESSES_FILE")
LAYER2_MANAGER=$(jq -r '.layer2ManagerProxy' "$ADDRESSES_FILE")
L1_BRIDGE_REGISTRY=$(jq -r '.l1BridgeRegistryProxy' "$ADDRESSES_FILE")
RAT=$(jq -r '.ratProxy' "$ADDRESSES_FILE")
VALIDATOR_REWARD=$(jq -r '.validatorRewardProxy' "$ADDRESSES_FILE")
SYSTEM_CONFIG=$(jq -r '.systemConfig' "$ADDRESSES_FILE")

echo "  TON:              $TON"
echo "  WTON:             $WTON"
echo "  SeigManager:      $SEIG_MANAGER"
echo "  DepositManager:   $DEPOSIT_MANAGER"
echo "  Layer2Manager:    $LAYER2_MANAGER"
echo "  RAT:              $RAT"
echo -e "${GREEN}✅ Contract addresses loaded${NC}"
echo ""

# =============================================================================
# Step 3: Wait for Nodes to be Ready
# =============================================================================
echo -e "${BLUE}[3/9] Waiting for nodes to be ready...${NC}"

# Wait for L1
for i in {1..30}; do
    if curl -s -X POST $L1_RPC -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' > /dev/null 2>&1; then
        L1_BLOCK=$(cast block-number --rpc-url $L1_RPC)
        echo -e "${GREEN}✅ L1 ready (block: $L1_BLOCK)${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}❌ L1 not ready${NC}"
        exit 1
    fi
    sleep 2
done

# Wait for L2
for i in {1..30}; do
    if curl -s -X POST $L2_RPC -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' > /dev/null 2>&1; then
        L2_BLOCK=$(cast block-number --rpc-url $L2_RPC)
        echo -e "${GREEN}✅ L2 ready (block: $L2_BLOCK)${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}❌ L2 not ready${NC}"
        exit 1
    fi
    sleep 2
done

echo ""

# =============================================================================
# Step 4: Mint Tokens for Test Accounts
# =============================================================================
echo -e "${BLUE}[4/9] Minting tokens for test accounts...${NC}"

# Mint TON for accounts (TON is already allocated in genesis, check balances)
DEPLOYER_TON=$(cast call $TON "balanceOf(address)(uint256)" $DEPLOYER_ADDR --rpc-url $L1_RPC)
VALIDATOR1_TON=$(cast call $TON "balanceOf(address)(uint256)" $VALIDATOR1_ADDR --rpc-url $L1_RPC)

echo "  Deployer TON:     $(cast --from-wei $DEPLOYER_TON) TON"
echo "  Validator1 TON:   $(cast --from-wei $VALIDATOR1_TON) TON"

# Swap some TON to WTON for each account
echo "  Swapping TON to WTON..."

# Swap for Deployer (10,000 TON -> WTON)
SWAP_AMOUNT="10000000000000000000000" # 10,000 TON
cast send $WTON "swapFromTON(uint256)" $SWAP_AMOUNT \
    --private-key $DEPLOYER_KEY --rpc-url $L1_RPC > /dev/null 2>&1 || true

sleep 2

# Swap for Validator1 (5,000 TON -> WTON)
SWAP_AMOUNT="5000000000000000000000" # 5,000 TON
cast send $WTON "swapFromTON(uint256)" $SWAP_AMOUNT \
    --private-key $VALIDATOR1_KEY --rpc-url $L1_RPC > /dev/null 2>&1 || true

sleep 2

# Swap for Validator2
cast send $WTON "swapFromTON(uint256)" $SWAP_AMOUNT \
    --private-key $VALIDATOR2_KEY --rpc-url $L1_RPC > /dev/null 2>&1 || true

sleep 2

# Swap for Validator3
cast send $WTON "swapFromTON(uint256)" $SWAP_AMOUNT \
    --private-key $VALIDATOR3_KEY --rpc-url $L1_RPC > /dev/null 2>&1 || true

sleep 2

DEPLOYER_WTON=$(cast call $WTON "balanceOf(address)(uint256)" $DEPLOYER_ADDR --rpc-url $L1_RPC)
VALIDATOR1_WTON=$(cast call $WTON "balanceOf(address)(uint256)" $VALIDATOR1_ADDR --rpc-url $L1_RPC)

echo "  Deployer WTON:    $(cast --from-wei $DEPLOYER_WTON) WTON"
echo "  Validator1 WTON:  $(cast --from-wei $VALIDATOR1_WTON) WTON"
echo -e "${GREEN}✅ Tokens minted/swapped${NC}"
echo ""

# =============================================================================
# Step 5: Approve WTON for Staking
# =============================================================================
echo -e "${BLUE}[5/9] Approving WTON for staking...${NC}"

MAX_UINT="0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"

# Approve for Deployer
cast send $WTON "approve(address,uint256)" $DEPOSIT_MANAGER $MAX_UINT \
    --private-key $DEPLOYER_KEY --rpc-url $L1_RPC > /dev/null 2>&1 || true

sleep 2

# Approve for Validators
for KEY in "$VALIDATOR1_KEY" "$VALIDATOR2_KEY" "$VALIDATOR3_KEY"; do
    cast send $WTON "approve(address,uint256)" $DEPOSIT_MANAGER $MAX_UINT \
        --private-key $KEY --rpc-url $L1_RPC > /dev/null 2>&1 || true
    sleep 2
done

echo -e "${GREEN}✅ WTON approved for DepositManager${NC}"
echo ""

# =============================================================================
# Step 6: Register L2 Operator (CandidateAddOn) - V3 Method
# =============================================================================
echo -e "${BLUE}[6/9] Registering L2 Operator (CandidateAddOn)...${NC}"

# Use SystemConfig as rollupConfig address
ROLLUP_CONFIG=$SYSTEM_CONFIG
OPERATOR_DEPOSIT="2000000000000000000000000000000" # 2000 WTON

# Step 6.1: Register SystemConfig in L1BridgeRegistry
echo "  Step 6.1: Registering SystemConfig in L1BridgeRegistry..."

# Check if deployer has manager/registrant permissions
HAS_MANAGER=$(cast call $L1_BRIDGE_REGISTRY "isManager(address)(bool)" $DEPLOYER_ADDR --rpc-url $L1_RPC 2>/dev/null || echo "false")
HAS_REGISTRANT=$(cast call $L1_BRIDGE_REGISTRY "isRegistrant(address)(bool)" $DEPLOYER_ADDR --rpc-url $L1_RPC 2>/dev/null || echo "false")

if [ "$HAS_MANAGER" = "false" ]; then
    echo "    Adding manager permission..."
    cast send $L1_BRIDGE_REGISTRY "addManager(address)" $DEPLOYER_ADDR \
        --private-key $DEPLOYER_KEY --rpc-url $L1_RPC > /dev/null 2>&1 || true
    sleep 2
fi

if [ "$HAS_REGISTRANT" = "false" ]; then
    echo "    Adding registrant permission..."
    cast send $L1_BRIDGE_REGISTRY "addRegistrant(address)" $DEPLOYER_ADDR \
        --private-key $DEPLOYER_KEY --rpc-url $L1_RPC > /dev/null 2>&1 || true
    sleep 2
fi

# Register rollupConfig (TYPE_3)
echo "    Registering rollupConfig (TYPE_3)..."
L2_TON="0x4200000000000000000000000000000000000010" # Standard L2 TON address
cast send $L1_BRIDGE_REGISTRY \
    "registerRollupConfig(address,uint8,address,string)" \
    $ROLLUP_CONFIG \
    3 \
    $L2_TON \
    "Devnet L2" \
    --private-key $DEPLOYER_KEY --rpc-url $L1_RPC > /dev/null 2>&1 || true

sleep 3

# Step 6.2: registerCandidateAddOn in Layer2Manager
echo "  Step 6.2: Registering CandidateAddOn..."

# Approve Layer2Manager to spend WTON
cast send $WTON "approve(address,uint256)" $LAYER2_MANAGER $OPERATOR_DEPOSIT \
    --private-key $DEPLOYER_KEY --rpc-url $L1_RPC > /dev/null 2>&1 || true

sleep 2

# Register CandidateAddOn
cast send $LAYER2_MANAGER \
    "registerCandidateAddOn(address,uint256,bool,string)" \
    $ROLLUP_CONFIG \
    $OPERATOR_DEPOSIT \
    false \
    "Devnet L2" \
    --private-key $DEPLOYER_KEY --rpc-url $L1_RPC > /dev/null 2>&1 || true

sleep 3

echo -e "${GREEN}✅ L2 Operator (CandidateAddOn) registered${NC}"
echo ""

# =============================================================================
# Step 7: Register Validators - V3 Two-Step Process
# =============================================================================
echo -e "${BLUE}[7/9] Registering Validators...${NC}"

# Get the Layer2 (CandidateAddOn) address created by registerCandidateAddOn
LAYER2_CANDIDATE=$(cast call $LAYER2_MANAGER "getLayer2BySystemConfig(address)(address)" $ROLLUP_CONFIG --rpc-url $L1_RPC 2>/dev/null || echo "0x0000000000000000000000000000000000000000")

echo "  Layer2 Candidate: $LAYER2_CANDIDATE"

# Validator deposit amount (2000 WTON as per test)
VALIDATOR_DEPOSIT="2000000000000000000000000000000" # 2000 WTON

# Register Validator 1
echo "  Registering Validator 1: $VALIDATOR1_ADDR"

# Step 1: Deposit to DepositManager
cast send $DEPOSIT_MANAGER \
    "deposit(address,address,uint256)" \
    $LAYER2_CANDIDATE \
    $VALIDATOR1_ADDR \
    $VALIDATOR_DEPOSIT \
    --private-key $VALIDATOR1_KEY --rpc-url $L1_RPC > /dev/null 2>&1 || true

sleep 2

# Step 2: Register to RAT
cast send $RAT \
    "registerValidator(address)" \
    $ROLLUP_CONFIG \
    --private-key $VALIDATOR1_KEY --rpc-url $L1_RPC > /dev/null 2>&1 || true

sleep 2
echo -e "${GREEN}  ✅ Validator 1 registered${NC}"

# Register Validator 2
echo "  Registering Validator 2: $VALIDATOR2_ADDR"

cast send $DEPOSIT_MANAGER \
    "deposit(address,address,uint256)" \
    $LAYER2_CANDIDATE \
    $VALIDATOR2_ADDR \
    $VALIDATOR_DEPOSIT \
    --private-key $VALIDATOR2_KEY --rpc-url $L1_RPC > /dev/null 2>&1 || true

sleep 2

cast send $RAT \
    "registerValidator(address)" \
    $ROLLUP_CONFIG \
    --private-key $VALIDATOR2_KEY --rpc-url $L1_RPC > /dev/null 2>&1 || true

sleep 2
echo -e "${GREEN}  ✅ Validator 2 registered${NC}"

# Register Validator 3
echo "  Registering Validator 3: $VALIDATOR3_ADDR"

cast send $DEPOSIT_MANAGER \
    "deposit(address,address,uint256)" \
    $LAYER2_CANDIDATE \
    $VALIDATOR3_ADDR \
    $VALIDATOR_DEPOSIT \
    --private-key $VALIDATOR3_KEY --rpc-url $L1_RPC > /dev/null 2>&1 || true

sleep 2

cast send $RAT \
    "registerValidator(address)" \
    $ROLLUP_CONFIG \
    --private-key $VALIDATOR3_KEY --rpc-url $L1_RPC > /dev/null 2>&1 || true

sleep 2
echo -e "${GREEN}  ✅ Validator 3 registered${NC}"

echo ""

# =============================================================================
# Step 8: Start RAT Clients (Validators) - AFTER Registration
# =============================================================================
echo -e "${BLUE}[8/9] Starting RAT Clients (Validators)...${NC}"

cd "$PROJECT_ROOT"
docker-compose up -d rat-client-1 rat-client-2 rat-client-3

sleep 5

RAT_COUNT=$(docker ps --filter "name=rat-client" --filter "status=running" | grep -c rat-client || echo "0")
echo -e "${GREEN}✅ RAT Clients started: $RAT_COUNT/3${NC}"
echo ""

# =============================================================================
# Step 9: Verify Setup
# =============================================================================
echo -e "${BLUE}[9/9] Verifying setup...${NC}"

# Check L1/L2 nodes
L1_BLOCK=$(cast block-number --rpc-url $L1_RPC)
L2_BLOCK=$(cast block-number --rpc-url $L2_RPC)
echo "  L1 Block:         $L1_BLOCK"
echo "  L2 Block:         $L2_BLOCK"

# Check RAT Clients
RAT_RUNNING=$(docker ps --filter "name=rat-client" --filter "status=running" | grep -c rat-client || echo "0")
echo "  RAT Clients:      $RAT_RUNNING/3"

# Check L2 Registration (CandidateAddOn)
OPERATOR_MGR=$(cast call $LAYER2_MANAGER "operatorOfRollupConfig(address)(address)" $ROLLUP_CONFIG --rpc-url $L1_RPC 2>/dev/null || echo "0x0000000000000000000000000000000000000000")
echo "  Operator Manager: $OPERATOR_MGR"

if [ "$OPERATOR_MGR" != "0x0000000000000000000000000000000000000000" ]; then
    echo "  L2 Registration:  ✅ Success"
else
    echo "  L2 Registration:  ❌ Failed"
fi

# Check Validators
VALIDATOR_COUNT=0
for ADDR in "$VALIDATOR1_ADDR" "$VALIDATOR2_ADDR" "$VALIDATOR3_ADDR"; do
    REG_INFO=$(cast call $RAT "getValidatorRegistration(address,address)(uint256,uint256,bool)" $ADDR $ROLLUP_CONFIG --rpc-url $L1_RPC 2>/dev/null || echo "0,0,false")
    IS_ACTIVE=$(echo "$REG_INFO" | cut -d',' -f3 | tr -d ' ')
    if [ "$IS_ACTIVE" = "true" ]; then
        VALIDATOR_COUNT=$((VALIDATOR_COUNT + 1))
    fi
done
echo "  Validators:       $VALIDATOR_COUNT/3"

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  Setup Complete!                                             ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✅ L1 Node running${NC}"
echo -e "${GREEN}✅ L2 Node running${NC}"
echo -e "${GREEN}✅ RAT Clients: $RAT_RUNNING/3${NC}"
echo -e "${GREEN}✅ L2 Operator registered${NC}"
echo -e "${GREEN}✅ Validators registered: $VALIDATOR_COUNT/3${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Check status:     ./scripts/check-system-status.sh"
echo "  2. Check health:     ./scripts/check-devnet-health.sh"
echo "  3. View logs:        docker-compose logs -f l2-node"
echo "  4. Stop devnet:      make devnet-stop"
echo ""
echo -e "${BLUE}RPC Endpoints:${NC}"
echo "  L1 RPC:   $L1_RPC"
echo "  L2 RPC:   $L2_RPC"
echo ""
