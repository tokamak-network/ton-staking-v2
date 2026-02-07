#!/bin/bash
# =============================================================================
# Generate L2 Genesis with Predeploy Contracts
# =============================================================================
# This script generates a proper L2 genesis file that includes all Optimism
# predeploy contracts at 0x4200... addresses.
#
# The predeploys are generated using Optimism's L2Genesis.s.sol script which
# deploys all required system contracts.
# =============================================================================

set -eo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DEVNET_DIR="$PROJECT_ROOT/.devnet"
OPTIMISM_DIR="$PROJECT_ROOT/lib/optimism"
CONTRACTS_DIR="$OPTIMISM_DIR/packages/contracts-bedrock"

echo -e "${BLUE}=== Generating L2 Genesis with Predeploys ===${NC}"
echo ""

# Check required files
if [ ! -f "$DEVNET_DIR/optimism-addresses.json" ]; then
    echo -e "${RED}Error: optimism-addresses.json not found${NC}"
    echo "Run 'make devnet-allocs-offline' first"
    exit 1
fi

# Get addresses from optimism-addresses.json
L1_CROSS_DOMAIN_MESSENGER=$(jq -r '.L1CrossDomainMessengerProxy // "0x0000000000000000000000000000000000000000"' "$DEVNET_DIR/optimism-addresses.json")
L1_STANDARD_BRIDGE=$(jq -r '.L1StandardBridgeProxy // "0x0000000000000000000000000000000000000000"' "$DEVNET_DIR/optimism-addresses.json")
L1_ERC721_BRIDGE=$(jq -r '.L1ERC721BridgeProxy // "0x0000000000000000000000000000000000000000"' "$DEVNET_DIR/optimism-addresses.json")

echo "L1 Contract Addresses:"
echo "  L1CrossDomainMessenger: $L1_CROSS_DOMAIN_MESSENGER"
echo "  L1StandardBridge: $L1_STANDARD_BRIDGE"
echo "  L1ERC721Bridge: $L1_ERC721_BRIDGE"
echo ""

# =============================================================================
# Generate L2 Genesis using forge script
# =============================================================================
echo -e "${YELLOW}Generating L2 predeploys using L2Genesis.s.sol...${NC}"

cd "$CONTRACTS_DIR"

# Create a temporary input file for L2Genesis
INPUT_JSON=$(cat <<EOF
{
  "l1ChainID": 900,
  "l2ChainID": 901,
  "l1CrossDomainMessengerProxy": "$L1_CROSS_DOMAIN_MESSENGER",
  "l1StandardBridgeProxy": "$L1_STANDARD_BRIDGE",
  "l1ERC721BridgeProxy": "$L1_ERC721_BRIDGE",
  "opChainProxyAdminOwner": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
  "sequencerFeeVaultRecipient": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
  "sequencerFeeVaultMinimumWithdrawalAmount": 0,
  "sequencerFeeVaultWithdrawalNetwork": 0,
  "baseFeeVaultRecipient": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
  "baseFeeVaultMinimumWithdrawalAmount": 0,
  "baseFeeVaultWithdrawalNetwork": 0,
  "l1FeeVaultRecipient": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
  "l1FeeVaultMinimumWithdrawalAmount": 0,
  "l1FeeVaultWithdrawalNetwork": 0,
  "governanceTokenOwner": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
  "fork": 2,
  "deployCrossL2Inbox": false,
  "enableGovernance": false,
  "fundDevAccounts": true
}
EOF
)

# Run the L2Genesis script
L2_ALLOCS_PATH="$DEVNET_DIR/l2-allocs.json"

echo "Running L2Genesis.s.sol..."
forge script scripts/L2Genesis.s.sol:L2Genesis \
    --sig "run((uint256,uint256,address,address,address,address,address,uint256,uint256,address,uint256,uint256,address,uint256,uint256,address,uint256,bool,bool,bool))" \
    "$INPUT_JSON" \
    --chain-id 901 \
    --ffi \
    -vv 2>&1 || {
    echo -e "${YELLOW}Warning: L2Genesis script failed, using pre-generated allocs...${NC}"
}

# If script failed, use pre-generated allocs
if [ ! -f "$L2_ALLOCS_PATH" ]; then
    echo -e "${YELLOW}Using pre-generated L2 allocs from optimism repo...${NC}"

    # Check for pre-generated allocs
    PREGENED_ALLOCS="$OPTIMISM_DIR/op-deployer/pkg/deployer/integration_test/testdata/allocs-l2-v160-1.json.gz"

    if [ -f "$PREGENED_ALLOCS" ]; then
        gunzip -c "$PREGENED_ALLOCS" > "$L2_ALLOCS_PATH"
        echo -e "${GREEN}  ✓ Extracted pre-generated L2 allocs${NC}"
    else
        echo -e "${RED}Error: No L2 allocs available${NC}"
        exit 1
    fi
fi

# =============================================================================
# Create L2 Genesis JSON
# =============================================================================
echo ""
echo -e "${YELLOW}Creating L2 genesis JSON...${NC}"

L2_GENESIS_PATH="$DEVNET_DIR/genesis-l2.json"

# Create the genesis config
cat > /tmp/l2-genesis-config.json <<'GENESIS_CONFIG'
{
  "config": {
    "chainId": 901,
    "homesteadBlock": 0,
    "eip150Block": 0,
    "eip155Block": 0,
    "eip158Block": 0,
    "byzantiumBlock": 0,
    "constantinopleBlock": 0,
    "petersburgBlock": 0,
    "istanbulBlock": 0,
    "muirGlacierBlock": 0,
    "berlinBlock": 0,
    "londonBlock": 0,
    "arrowGlacierBlock": 0,
    "grayGlacierBlock": 0,
    "mergeNetsplitBlock": 0,
    "terminalTotalDifficulty": 0,
    "terminalTotalDifficultyPassed": true,
    "bedrockBlock": 0,
    "regolithTime": 0,
    "canyonTime": 0,
    "shanghaiTime": 0,
    "cancunTime": 0,
    "deltaTime": 0,
    "ecotoneTime": 0,
    "fjordTime": 0,
    "optimism": {
      "eip1559Elasticity": 6,
      "eip1559Denominator": 50,
      "eip1559DenominatorCanyon": 250
    }
  },
  "nonce": "0x0",
  "timestamp": "0x0",
  "extraData": "0x",
  "gasLimit": "0x1c9c380",
  "difficulty": "0x0",
  "mixHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "coinbase": "0x0000000000000000000000000000000000000000",
  "number": "0x0",
  "gasUsed": "0x0",
  "parentHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "baseFeePerGas": "0x3b9aca00"
}
GENESIS_CONFIG

# Transform allocs to add 0x prefix to addresses
echo "  Transforming allocs (adding 0x prefix to addresses)..."
jq 'to_entries | map({key: ("0x" + .key), value: .value}) | from_entries' "$L2_ALLOCS_PATH" > /tmp/l2-allocs-prefixed.json

# Merge config with allocs
echo "  Merging config with allocs..."
jq --slurpfile allocs /tmp/l2-allocs-prefixed.json '. + {alloc: $allocs[0]}' /tmp/l2-genesis-config.json > "$L2_GENESIS_PATH"

# =============================================================================
# Fix L2CrossDomainMessenger otherMessenger address
# =============================================================================
echo "  Fixing L2CrossDomainMessenger otherMessenger address..."

# IMPORTANT: otherMessenger should be the L1 address (NOT the L2 alias)
# The CrossDomainMessenger.sol checks: undoL1ToL2Alias(msg.sender) == otherMessenger
# Where msg.sender is the L2 alias, and otherMessenger is the L1 address
L1_MESSENGER_ADDR=$L1_CROSS_DOMAIN_MESSENGER
if [ "$L1_MESSENGER_ADDR" != "0x0000000000000000000000000000000000000000" ]; then
    echo "    L1CrossDomainMessenger (otherMessenger): $L1_MESSENGER_ADDR"
    
    # Update storage slot 0xcf in L2CrossDomainMessenger (0x4200...0007)
    # Storage slot 0xcf holds the otherMessenger address (L1 address, not L2 alias!)
    STORAGE_VALUE=$(printf "0x%064s" $(echo $L1_MESSENGER_ADDR | sed 's/0x//') | tr ' ' '0')
    
    jq --arg slot "0x00000000000000000000000000000000000000000000000000000000000000cf" \
       --arg value "$STORAGE_VALUE" \
       '.alloc["0x4200000000000000000000000000000000000007"].storage[$slot] = $value' \
       "$L2_GENESIS_PATH" > /tmp/genesis-l2-fixed.json
    
    mv /tmp/genesis-l2-fixed.json "$L2_GENESIS_PATH"
    echo -e "    ${GREEN}✓ L2CrossDomainMessenger otherMessenger set to L1 address${NC}"
else
    echo -e "    ${YELLOW}Warning: L1CrossDomainMessenger address not found, skipping fix${NC}"
fi

# =============================================================================
# Fix L2StandardBridge otherBridge address
# =============================================================================
echo "  Fixing L2StandardBridge otherBridge address..."

# L2StandardBridge storage layout:
# - Slot 3: messenger (L2CrossDomainMessenger)
# - Slot 4: otherBridge (should be L1StandardBridgeProxy)
L1_BRIDGE_ADDR=$L1_STANDARD_BRIDGE
if [ "$L1_BRIDGE_ADDR" != "0x0000000000000000000000000000000000000000" ]; then
    echo "    L1StandardBridge (otherBridge): $L1_BRIDGE_ADDR"

    # Update storage slot 4 in L2StandardBridge (0x4200...0010)
    STORAGE_VALUE=$(printf "0x%064s" $(echo $L1_BRIDGE_ADDR | sed 's/0x//') | tr ' ' '0')

    jq --arg slot "0x0000000000000000000000000000000000000000000000000000000000000004" \
       --arg value "$STORAGE_VALUE" \
       '.alloc["0x4200000000000000000000000000000000000010"].storage[$slot] = $value' \
       "$L2_GENESIS_PATH" > /tmp/genesis-l2-fixed.json

    mv /tmp/genesis-l2-fixed.json "$L2_GENESIS_PATH"
    echo -e "    ${GREEN}✓ L2StandardBridge otherBridge set to L1 address${NC}"
else
    echo -e "    ${YELLOW}Warning: L1StandardBridge address not found, skipping fix${NC}"
fi

# =============================================================================
# Fix L1Block fee scalars (prevent rollup cost overflow)
# =============================================================================
echo "  Fixing L1Block fee scalars..."

# Set fee scalars for local devnet (low fees)
# baseFeeScalar = 1000 (0.1%)
# blobBaseFeeScalar = 1000 (0.1%)
# l1FeeScalar = 1000 (0.1%)

# Create jq script to update L1Block storage
cat > /tmp/fix-l1block-genesis.jq <<'EOF'
# Update L1Block (0x4200...0015) storage with proper fee scalars
.alloc["0x4200000000000000000000000000000000000015"].storage += {
  # Slot 3: l1FeeScalar (deprecated, but needed for backwards compatibility)
  # 1000 = 0.001 = 0.1%
  "0x0000000000000000000000000000000000000000000000000000000000000003": "0x00000000000000000000000000000000000000000000000000000000000003e8",

  # Slot 5: Ecotone scalars (baseFeeScalar + blobBaseFeeScalar packed)
  # Lower 32 bits: baseFeeScalar = 1000 (0x3e8)
  # Upper 32 bits: blobBaseFeeScalar = 1000 (0x3e8)
  # Combined: 64 hex chars (32 bytes) = 48 padding + 8 blob + 8 base
  "0x0000000000000000000000000000000000000000000000000000000000000005": "0x000000000000000000000000000000000000000000000000000003e8000003e8"
}
EOF

jq -f /tmp/fix-l1block-genesis.jq "$L2_GENESIS_PATH" > /tmp/genesis-l2-l1block.json
mv /tmp/genesis-l2-l1block.json "$L2_GENESIS_PATH"
echo -e "    ${GREEN}✓ L1Block fee scalars set (baseFee: 0.1%, blobBaseFee: 0.1%)${NC}"

# Cleanup temp files
rm -f /tmp/l2-genesis-config.json /tmp/l2-allocs-prefixed.json /tmp/fix-l1block-genesis.jq /tmp/genesis-l2-l1block.json

# Count predeploys
PREDEPLOY_COUNT=$(jq '[.alloc | keys[] | select(startswith("0x4200"))] | length' "$L2_GENESIS_PATH")
TOTAL_ACCOUNTS=$(jq '.alloc | length' "$L2_GENESIS_PATH")

echo ""
echo -e "${GREEN}=== L2 Genesis Generated ===${NC}"
echo "  Output: $L2_GENESIS_PATH"
echo "  Total accounts: $TOTAL_ACCOUNTS"
echo "  Predeploy contracts (0x4200...): $PREDEPLOY_COUNT"
echo ""

# Verify key predeploys exist
echo -e "${BLUE}Verifying key predeploys...${NC}"

check_predeploy() {
    local name=$1
    local addr=$2
    local has_code=$(jq --arg addr "$addr" '.alloc[$addr].code != null and .alloc[$addr].code != "0x"' "$L2_GENESIS_PATH")
    if [ "$has_code" == "true" ]; then
        echo -e "  ${GREEN}✓${NC} $name ($addr)"
    else
        echo -e "  ${RED}✗${NC} $name ($addr)"
    fi
}

check_predeploy "LegacyMessagePasser" "0x4200000000000000000000000000000000000000"
check_predeploy "L2CrossDomainMessenger" "0x4200000000000000000000000000000000000007"
check_predeploy "GasPriceOracle" "0x420000000000000000000000000000000000000f"
check_predeploy "L2StandardBridge" "0x4200000000000000000000000000000000000010"
check_predeploy "L1Block" "0x4200000000000000000000000000000000000015"
check_predeploy "L2ToL1MessagePasser" "0x4200000000000000000000000000000000000016"

echo ""
echo -e "${GREEN}L2 genesis with predeploys generated successfully!${NC}"
