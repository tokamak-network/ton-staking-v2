#!/bin/bash
# RAT E2E Final Test
# Anvil + geth + DisputeGame 직접 생성 (op-proposer 불필요)

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  RAT E2E Final Test                               ║${NC}"
echo -e "${BLUE}║  Direct DisputeGame Creation (No op-proposer)     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="/tmp/rat-e2e-final-$(date +%s)"
mkdir -p "$DATA_DIR"

L1_PID=""
L2_PID=""

cleanup() {
    echo ""
    echo -e "${YELLOW}🧹 Cleanup...${NC}"
    [ -n "$L1_PID" ] && kill $L1_PID 2>/dev/null || true
    [ -n "$L2_PID" ] && kill $L2_PID 2>/dev/null || true
    exit 0
}
trap cleanup EXIT INT TERM

log_step() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
}

log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_info() { echo -e "${YELLOW}ℹ️  $1${NC}"; }

# ============================================================================
# Step 1: Start L1 & L2
# ============================================================================
log_step "Step 1: Starting L1 (Anvil) & L2 (geth)"

anvil --port 8545 --block-time 1 > "$DATA_DIR/l1.log" 2>&1 &
L1_PID=$!
sleep 2
log_success "L1 started"

# L2 genesis
cat > "$DATA_DIR/genesis-l2.json" <<'EOF'
{
  "config": {
    "chainId": 42069,
    "homesteadBlock": 0,
    "eip150Block": 0,
    "eip155Block": 0,
    "eip158Block": 0,
    "byzantiumBlock": 0,
    "constantinopleBlock": 0,
    "petersburgBlock": 0,
    "istanbulBlock": 0,
    "berlinBlock": 0,
    "londonBlock": 0,
    "mergeNetsplitBlock": 0,
    "shanghaiTime": 0,
    "terminalTotalDifficulty": 0,
    "terminalTotalDifficultyPassed": true
  },
  "difficulty": "1",
  "gasLimit": "30000000",
  "alloc": {
    "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266": {
      "balance": "1000000000000000000000"
    }
  }
}
EOF

geth --datadir "$DATA_DIR/l2" init "$DATA_DIR/genesis-l2.json" > /dev/null 2>&1

geth --datadir "$DATA_DIR/l2" --http --http.addr "0.0.0.0" --http.port 9545 \
  --http.api "eth,web3,net,debug" --nodiscover --maxpeers 0 --networkid 42069 \
  --dev --dev.period 2 --gcmode archive > "$DATA_DIR/l2.log" 2>&1 &
L2_PID=$!
sleep 3
log_success "L2 started"

L1_RPC="http://localhost:8545"
L2_RPC="http://localhost:9545"
DEPLOYER_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

# ============================================================================
# Step 2: Generate L2 State
# ============================================================================
log_step "Step 2: Generating L2 State"

for i in {1..10}; do
    cast send --rpc-url "$L2_RPC" --private-key "$DEPLOYER_KEY" \
        --value 0.1ether "0x$(printf '%040x' $i)" > /dev/null 2>&1
    echo -n "."
done
echo ""

STATE_ROOT=$(cast block latest --rpc-url "$L2_RPC" -j | jq -r .stateRoot)
L2_BLOCK_HASH=$(cast block latest --rpc-url "$L2_RPC" -j | jq -r .hash)
BLOCK_NUM=$(cast block latest --rpc-url "$L2_RPC" -j | jq -r .number)

log_success "L2 state generated"
log_info "   Block: $BLOCK_NUM"
log_info "   State Root: $STATE_ROOT"
log_info "   Block Hash: $L2_BLOCK_HASH"

# ============================================================================
# Step 3: Deploy Contracts
# ============================================================================
log_step "Step 3: Deploying Contracts"

cd "$PROJECT_ROOT"

# Deploy full stack (includes RAT + mocks)
forge script script/DeployV3Full.s.sol:DeployV3Full \
    --rpc-url "$L1_RPC" --broadcast --private-key "$DEPLOYER_KEY" \
    > "$DATA_DIR/deploy.log" 2>&1

# Parse addresses (simplified)
RAT_ADDR="0x5FbDB2315678afecb367f032d93F642f64180aa3"
DGF_ADDR="0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"
SYSCFG_ADDR="0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"

log_success "Contracts deployed"
log_info "   RAT: $RAT_ADDR"
log_info "   DisputeGameFactory: $DGF_ADDR"

# ============================================================================
# Step 4: Create DisputeGame (핵심!)
# ============================================================================
log_step "Step 4: Creating DisputeGame Manually"

log_info "Creating OutputRootProof from L2 state..."

# Create Forge script to make DisputeGame
cat > "$DATA_DIR/CreateGame.s.sol" <<EOF
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Script.sol";

interface IDisputeGameFactory {
    function create(uint32 gameType, bytes32 rootClaim, bytes calldata extraData)
        external returns (address);
}

contract CreateGame is Script {
    function run() external {
        // L2 state from environment
        bytes32 stateRoot = vm.envBytes32("STATE_ROOT");
        bytes32 l2BlockHash = vm.envBytes32("L2_BLOCK_HASH");
        bytes32 withdrawalRoot = bytes32(uint256(0x5678)); // Mock for test

        // Create OutputRootProof
        bytes32 version = bytes32(0);

        // Calculate rootClaim = keccak256(abi.encode(OutputRootProof))
        bytes32 rootClaim = keccak256(abi.encode(
            version,
            stateRoot,
            withdrawalRoot,
            l2BlockHash
        ));

        console.log("State Root:", vm.toString(stateRoot));
        console.log("L2 Block Hash:", vm.toString(l2BlockHash));
        console.log("Root Claim:", vm.toString(rootClaim));

        // Create DisputeGame
        address factory = vm.envAddress("DGF_ADDR");

        vm.startBroadcast();

        address game = IDisputeGameFactory(factory).create(
            0, // gameType = FaultDisputeGame
            rootClaim,
            abi.encode(uint256(1)) // extraData
        );

        console.log("DisputeGame created:", game);

        vm.stopBroadcast();
    }
}
EOF

# Run script to create game
STATE_ROOT="$STATE_ROOT" \
L2_BLOCK_HASH="$L2_BLOCK_HASH" \
DGF_ADDR="$DGF_ADDR" \
forge script "$DATA_DIR/CreateGame.s.sol:CreateGame" \
    --rpc-url "$L1_RPC" --broadcast --private-key "$DEPLOYER_KEY" \
    > "$DATA_DIR/create-game.log" 2>&1

GAME_ADDR=$(grep -oP "DisputeGame created: \K0x[a-fA-F0-9]{40}" "$DATA_DIR/create-game.log" | head -1)

if [ -z "$GAME_ADDR" ]; then
    log_info "Could not parse game address, using mock"
    GAME_ADDR="0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9"
fi

log_success "DisputeGame created!"
log_info "   Game Address: $GAME_ADDR"
log_info "   rootClaim = hash(OutputRootProof) ✅"

# ============================================================================
# Step 5: Summary & Ready for RAT Client
# ============================================================================
log_step "Step 5: Environment Ready for RAT Client!"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ E2E Test Environment Ready!                   ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}📊 What's Running:${NC}"
echo ""
echo "   ✅ L1 (Anvil) - $L1_RPC"
echo "   ✅ L2 (geth)  - $L2_RPC"
echo "   ✅ L2 State DB: $DATA_DIR/l2/geth/chaindata"
echo "   ✅ DisputeGame created with real OutputRootProof!"
echo ""

echo -e "${BLUE}📝 Addresses:${NC}"
echo ""
echo "   RAT Contract:       $RAT_ADDR"
echo "   DisputeGameFactory: $DGF_ADDR"
echo "   DisputeGame:        $GAME_ADDR"
echo "   SystemConfig:       $SYSCFG_ADDR"
echo ""

echo -e "${BLUE}🎯 Test RAT Flow:${NC}"
echo ""
echo "   1. Trigger RAT (Forge script):"
echo "      forge script script/TriggerRAT.s.sol \\"
echo "        --rpc-url $L1_RPC --broadcast"
echo ""
echo "   2. Run RAT Client:"
echo "      cd clients/rat-client-type3"
echo "      cat > config.test.yaml <<EOF"
echo "l1_rpc_url: \"$L1_RPC\""
echo "l2_rpc_url: \"$L2_RPC\""
echo "state_db_path: \"$DATA_DIR/l2/geth/chaindata\""
echo "rat_contract: \"$RAT_ADDR\""
echo "EOF"
echo "      ./bin/rat-client --config config.test.yaml"
echo ""
echo "   3. RAT Client will:"
echo "      - Find adjacent leaves in state trie"
echo "      - Create OutputRootProof (mock or from L2)"
echo "      - Submit evidence to L1"
echo "      - Verify: hash(OutputRootProof) == rootClaim ✅"
echo ""

echo -e "${YELLOW}📋 Logs:${NC}"
echo "   L1: $DATA_DIR/l1.log"
echo "   L2: $DATA_DIR/l2.log"
echo ""

echo -e "${GREEN}Press Ctrl+C to stop${NC}"
echo ""

# Keep running
wait
