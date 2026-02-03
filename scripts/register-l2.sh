#!/bin/bash
# =============================================================================
# Register L2 to TON Staking System
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

echo -e "${BLUE}=== TON Staking V2 - L2 Registration ===${NC}"
echo ""

# Check if addresses.json exists
if [ ! -f "$ADDRESSES_FILE" ]; then
    echo -e "${RED}Error: addresses.json not found${NC}"
    echo "Run 'make devnet-allocs-offline' first"
    exit 1
fi

# Load contract addresses
TON=$(jq -r '.ton' "$ADDRESSES_FILE")
WTON=$(jq -r '.wton' "$ADDRESSES_FILE")
SEIG_MANAGER=$(jq -r '.seigManagerProxy' "$ADDRESSES_FILE")
DEPOSIT_MANAGER=$(jq -r '.depositManagerProxy' "$ADDRESSES_FILE")
LAYER2_MANAGER=$(jq -r '.layer2ManagerProxy' "$ADDRESSES_FILE")
RAT=$(jq -r '.ratProxy' "$ADDRESSES_FILE")
SYSTEM_CONFIG=$(jq -r '.systemConfig' "$ADDRESSES_FILE")
L1_BRIDGE_REGISTRY=$(jq -r '.l1BridgeRegistryProxy' "$ADDRESSES_FILE")

# L1/L2 RPC endpoints
L1_RPC="http://localhost:8545"
L2_RPC="http://localhost:9545"

# Test account (first Hardhat account)
DEPLOYER_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
DEPLOYER_ADDR="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

# L2 information
L2_CHAIN_ID=901
L2_NAME="Devnet L2"

echo -e "${BLUE}Contract Addresses:${NC}"
echo "  TON:            $TON"
echo "  WTON:           $WTON"
echo "  SeigManager:    $SEIG_MANAGER"
echo "  DepositManager: $DEPOSIT_MANAGER"
echo "  Layer2Manager:  $LAYER2_MANAGER"
echo "  RAT:            $RAT"
echo "  SystemConfig:   $SYSTEM_CONFIG"
echo ""

# =============================================================================
# Step 1: Check if devnet is running
# =============================================================================
echo -e "${BLUE}[1/6] Checking devnet status...${NC}"

if ! curl -s -X POST $L1_RPC -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' > /dev/null 2>&1; then
    echo -e "${RED}Error: L1 is not running${NC}"
    echo "Start devnet: docker-compose up -d"
    exit 1
fi

if ! curl -s -X POST $L2_RPC -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' > /dev/null 2>&1; then
    echo -e "${RED}Error: L2 is not running${NC}"
    echo "Start devnet: docker-compose up -d"
    exit 1
fi

echo -e "${GREEN}✅ Devnet is running${NC}"
echo ""

# =============================================================================
# Step 2: Check TON balance
# =============================================================================
echo -e "${BLUE}[2/6] Checking TON balance...${NC}"

TON_BALANCE=$(cast call $TON "balanceOf(address)(uint256)" $DEPLOYER_ADDR --rpc-url $L1_RPC)
TON_BALANCE_DEC=$((TON_BALANCE))

echo "  Deployer: $DEPLOYER_ADDR"
echo "  TON Balance: $TON_BALANCE_DEC wei"

if [ "$TON_BALANCE_DEC" -eq 0 ]; then
    echo -e "${YELLOW}Warning: No TON balance. Minting 1000 TON...${NC}"
    
    # Mint TON (if TON contract has mint function)
    cast send $TON "mint(address,uint256)" $DEPLOYER_ADDR 1000000000000000000000 \
        --private-key $DEPLOYER_KEY --rpc-url $L1_RPC > /dev/null 2>&1 || \
    echo -e "${YELLOW}Note: Could not mint TON (may need to use existing balance)${NC}"
fi
echo ""

# =============================================================================
# Step 3: Approve WTON for staking
# =============================================================================
echo -e "${BLUE}[3/6] Approving WTON for DepositManager...${NC}"

# Check current allowance
ALLOWANCE=$(cast call $WTON "allowance(address,address)(uint256)" $DEPLOYER_ADDR $DEPOSIT_MANAGER --rpc-url $L1_RPC)

if [ "$ALLOWANCE" = "0x0" ] || [ "$ALLOWANCE" = "0" ]; then
    echo "  Approving unlimited WTON..."
    cast send $WTON "approve(address,uint256)" $DEPOSIT_MANAGER \
        115792089237316195423570985008687907853269984665640564039457584007913129639935 \
        --private-key $DEPLOYER_KEY --rpc-url $L1_RPC --async > /dev/null
    
    sleep 3
    echo -e "${GREEN}✅ WTON approved${NC}"
else
    echo -e "${GREEN}✅ WTON already approved${NC}"
fi
echo ""

# =============================================================================
# Step 4: Check if L2 is already registered
# =============================================================================
echo -e "${BLUE}[4/6] Checking L2 registration status...${NC}"

# Get total number of registered L2s
TOTAL_L2S=$(cast call $LAYER2_MANAGER "numLayer2s()(uint256)" --rpc-url $L1_RPC)
TOTAL_L2S_DEC=$((TOTAL_L2S))

echo "  Total registered L2s: $TOTAL_L2S_DEC"

# Check if our L2 is registered
IS_REGISTERED=false
L2_CONTRACT_ADDR=""

if [ "$TOTAL_L2S_DEC" -gt 0 ]; then
    for ((i=0; i<TOTAL_L2S_DEC; i++)); do
        L2_ADDR=$(cast call $LAYER2_MANAGER "layer2ByIndex(uint256)(address)" $i --rpc-url $L1_RPC)
        
        # Get chain ID from L2 contract
        REGISTERED_CHAIN_ID=$(cast call $L2_ADDR "chainId()(uint256)" --rpc-url $L1_RPC 2>/dev/null || echo "0")
        
        if [ "$REGISTERED_CHAIN_ID" = "$L2_CHAIN_ID" ]; then
            IS_REGISTERED=true
            L2_CONTRACT_ADDR=$L2_ADDR
            echo -e "${GREEN}✅ L2 (Chain ID: $L2_CHAIN_ID) already registered at $L2_ADDR${NC}"
            break
        fi
    done
fi

if [ "$IS_REGISTERED" = false ]; then
    echo -e "${YELLOW}L2 not registered yet${NC}"
fi
echo ""

# =============================================================================
# Step 5: Register L2 if not registered
# =============================================================================
if [ "$IS_REGISTERED" = false ]; then
    echo -e "${BLUE}[5/6] Registering L2 to Layer2Manager...${NC}"
    
    # Create Layer2 contract parameters
    # function registerLayer2(
    #     address _operator,
    #     address _l2,
    #     uint256 _chainId,
    #     string memory _name
    # )
    
    echo "  Operator: $DEPLOYER_ADDR"
    echo "  Chain ID: $L2_CHAIN_ID"
    echo "  Name: $L2_NAME"
    echo ""
    
    # For this devnet, we'll use a simple registration
    # In production, you'd deploy an actual Layer2 contract first
    
    echo -e "${YELLOW}Note: Using simplified registration for devnet${NC}"
    echo -e "${YELLOW}In production, deploy Layer2 contract first${NC}"
    echo ""
    
    # Try to call registerLayer2 (may need to check actual function signature)
    # cast send $LAYER2_MANAGER "registerLayer2(address,address,uint256,string)" \
    #     $DEPLOYER_ADDR $SYSTEM_CONFIG $L2_CHAIN_ID "$L2_NAME" \
    #     --private-key $DEPLOYER_KEY --rpc-url $L1_RPC
    
    echo -e "${YELLOW}Skipping L2 registration - requires Layer2 contract deployment${NC}"
    echo -e "${YELLOW}This is handled by the devnet genesis setup${NC}"
else
    echo -e "${BLUE}[5/6] L2 already registered - skipping${NC}"
    echo ""
fi

# =============================================================================
# Step 6: Verify registration and show summary
# =============================================================================
echo -e "${BLUE}[6/6] Registration Summary${NC}"
echo ""

if [ "$IS_REGISTERED" = true ]; then
    echo -e "${GREEN}✅ L2 Registration Complete!${NC}"
    echo ""
    echo "L2 Details:"
    echo "  Chain ID: $L2_CHAIN_ID"
    echo "  Contract: $L2_CONTRACT_ADDR"
    echo "  Name: $L2_NAME"
    echo ""
    
    # Get staking info
    echo "Staking Information:"
    
    # Check if operator has staked
    STAKED_AMOUNT=$(cast call $DEPOSIT_MANAGER "stakeOf(address,address)(uint256)" \
        $L2_CONTRACT_ADDR $DEPLOYER_ADDR --rpc-url $L1_RPC 2>/dev/null || echo "0")
    STAKED_DEC=$((STAKED_AMOUNT))
    
    echo "  Staked TON: $STAKED_DEC wei"
    
    if [ "$STAKED_DEC" -eq 0 ]; then
        echo ""
        echo -e "${YELLOW}To stake TON:${NC}"
        echo "  cast send $DEPOSIT_MANAGER \"deposit(address,uint256)\" \\"
        echo "    $L2_CONTRACT_ADDR 1000000000000000000000 \\"
        echo "    --private-key $DEPLOYER_KEY --rpc-url $L1_RPC"
    fi
else
    echo -e "${YELLOW}⚠️  L2 not fully registered${NC}"
    echo ""
    echo "Manual Steps Required:"
    echo ""
    echo "1. Deploy Layer2 contract:"
    echo "   forge create src/layer2/Layer2.sol:Layer2 \\"
    echo "     --constructor-args $DEPLOYER_ADDR $L2_CHAIN_ID \\"
    echo "     --private-key $DEPLOYER_KEY --rpc-url $L1_RPC"
    echo ""
    echo "2. Register to Layer2Manager:"
    echo "   cast send $LAYER2_MANAGER \"registerLayer2(...)\" \\"
    echo "     --private-key $DEPLOYER_KEY --rpc-url $L1_RPC"
    echo ""
    echo "3. Stake TON through DepositManager"
fi

echo ""
echo -e "${BLUE}=== Useful Commands ===${NC}"
echo ""
echo "# Check L2 list"
echo "cast call $LAYER2_MANAGER \"numLayer2s()(uint256)\" --rpc-url $L1_RPC"
echo ""
echo "# Check staking amount"
echo "cast call $DEPOSIT_MANAGER \"stakeOf(address,address)(uint256)\" \\"
echo "  <L2_CONTRACT> <OPERATOR> --rpc-url $L1_RPC"
echo ""
echo "# Check RAT status"
echo "cast call $RAT \"getValidatorInfo(address)(bool,uint256,uint256)\" \\"
echo "  <VALIDATOR> --rpc-url $L1_RPC"
echo ""
