#!/bin/bash
# =============================================================================
# Setup 3 Validators for TON Staking V3 Local Devnet
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
DEVNET_DIR="$PROJECT_ROOT/.devnet"

# RPC URL
RPC_URL="http://localhost:8545"

# Load contract addresses
TON=$(jq -r '.ton' "$DEVNET_DIR/addresses.json")
WTON=$(jq -r '.wton' "$DEVNET_DIR/addresses.json")
DEPOSIT_MANAGER=$(jq -r '.depositManagerProxy' "$DEVNET_DIR/addresses.json")
LAYER2_MANAGER=$(jq -r '.layer2ManagerProxy' "$DEVNET_DIR/addresses.json")
RAT=$(jq -r '.ratProxy' "$DEVNET_DIR/addresses.json")
SYSTEM_CONFIG=$(jq -r '.systemConfig' "$DEVNET_DIR/addresses.json")

# Deployer (has 100,000 TON)
DEPLOYER="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
DEPLOYER_KEY="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"

# Validators
declare -A VALIDATORS
VALIDATORS[1_addr]="0x90F79bf6EB2c4f870365E785982E1f101E93b906"
VALIDATORS[1_key]="0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"

VALIDATORS[2_addr]="0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65"
VALIDATORS[2_key]="0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6"

VALIDATORS[3_addr]="0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc"
VALIDATORS[3_key]="0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a"

STAKE_AMOUNT="20000000000000000000000"  # 20,000 TON

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     TON Staking V3 - Setup 3 Validators                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}=== Step 1: Check Prerequisites ===${NC}"
echo ""

# Check if L1 is running
if ! cast block-number --rpc-url $RPC_URL &>/dev/null; then
    echo -e "${RED}✗ L1 (Anvil) is not running${NC}"
    echo "Please start the devnet first: make devnet-start"
    exit 1
fi
echo -e "${GREEN}✓ L1 is running${NC}"

# Check deployer TON balance
DEPLOYER_BAL=$(cast call $TON "balanceOf(address)(uint256)" $DEPLOYER --rpc-url $RPC_URL 2>/dev/null || echo "0")
DEPLOYER_BAL_ETH=$(cast from-wei $DEPLOYER_BAL 2>/dev/null || echo "0")
echo -e "${GREEN}✓ Deployer has $DEPLOYER_BAL_ETH TON${NC}"

if (( $(echo "$DEPLOYER_BAL < 60000000000000000000000" | bc -l) )); then
    echo -e "${RED}✗ Insufficient TON balance (need at least 60,000 TON)${NC}"
    exit 1
fi
echo ""

echo -e "${YELLOW}=== Step 2: Transfer TON to Validators ===${NC}"
echo ""

for i in 1 2 3; do
    addr_key="${i}_addr"
    validator_addr="${VALIDATORS[$addr_key]}"
    
    echo "Validator #$i: $validator_addr"
    
    # Check current balance
    bal=$(cast call $TON "balanceOf(address)(uint256)" $validator_addr --rpc-url $RPC_URL 2>/dev/null || echo "0")
    bal_eth=$(cast from-wei $bal 2>/dev/null || echo "0")
    echo "  Current TON balance: $bal_eth TON"
    
    # Transfer 20,000 TON
    echo "  Transferring 20,000 TON..."
    cast send $TON \
        "transfer(address,uint256)" \
        $validator_addr \
        $STAKE_AMOUNT \
        --private-key $DEPLOYER_KEY \
        --rpc-url $RPC_URL \
        --json &>/dev/null
    
    echo -e "  ${GREEN}✓ Transfer complete${NC}"
    echo ""
done

echo -e "${YELLOW}=== Step 3: Approve and Stake TON ===${NC}"
echo ""

for i in 1 2 3; do
    addr_key="${i}_addr"
    key_key="${i}_key"
    validator_addr="${VALIDATORS[$addr_key]}"
    validator_key="${VALIDATORS[$key_key]}"
    
    echo "Validator #$i: $validator_addr"
    
    # Approve
    echo "  Approving TON to DepositManager..."
    cast send $TON \
        "approve(address,uint256)" \
        $DEPOSIT_MANAGER \
        $STAKE_AMOUNT \
        --private-key $validator_key \
        --rpc-url $RPC_URL \
        --json &>/dev/null
    
    # Deposit
    echo "  Staking 20,000 TON..."
    cast send $DEPOSIT_MANAGER \
        "deposit(address,uint256)" \
        $SYSTEM_CONFIG \
        $STAKE_AMOUNT \
        --private-key $validator_key \
        --rpc-url $RPC_URL \
        --json &>/dev/null
    
    echo -e "  ${GREEN}✓ Staking complete${NC}"
    echo ""
done

echo -e "${YELLOW}=== Step 4: Register Validators in RAT ===${NC}"
echo ""

for i in 1 2 3; do
    addr_key="${i}_addr"
    key_key="${i}_key"
    validator_addr="${VALIDATORS[$addr_key]}"
    validator_key="${VALIDATORS[$key_key]}"
    
    echo "Validator #$i: $validator_addr"
    
    # Check if already registered
    is_registered=$(cast call $RAT \
        "isRegisteredValidator(address,address)(bool)" \
        $SYSTEM_CONFIG \
        $validator_addr \
        --rpc-url $RPC_URL 2>/dev/null || echo "false")
    
    if [ "$is_registered" == "true" ]; then
        echo -e "  ${YELLOW}Already registered${NC}"
    else
        echo "  Registering as validator..."
        result=$(cast send $RAT \
            "registerValidator(address)" \
            $SYSTEM_CONFIG \
            --private-key $validator_key \
            --rpc-url $RPC_URL \
            --json 2>&1 || echo "{\"status\":\"0x0\"}")
        
        status=$(echo $result | jq -r '.status' 2>/dev/null || echo "0x0")
        if [ "$status" == "0x1" ] || [ "$status" == "1" ]; then
            echo -e "  ${GREEN}✓ Registration successful${NC}"
        else
            echo -e "  ${RED}✗ Registration failed${NC}"
            echo "  Error: $result"
        fi
    fi
    echo ""
done

echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Validator Setup Complete!                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Next steps:"
echo "1. Build RAT client: cd clients/rat-client-type3 && go build -o bin/rat-client cmd/main.go"
echo "2. Create config files for each validator"
echo "3. Run RAT clients in separate terminals"
echo ""
echo "See docs/deployment/local/VALIDATOR-SETUP.md for details"
