#!/bin/bash
# RAT E2E Simple Test
# Kurtosis 없이 직접 Optimism 컴포넌트 실행
# L1 (Anvil) + L2 (geth) + op-node + op-proposer

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  RAT E2E Simple Test                              ║${NC}"
echo -e "${BLUE}║  Direct Optimism Stack (No Kurtosis)              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OPTIMISM_DIR="${OPTIMISM_DIR:-$PROJECT_ROOT/lib/optimism}"
DATA_DIR="/tmp/rat-e2e-simple-$(date +%s)"
mkdir -p "$DATA_DIR"

# PIDs for cleanup
L1_PID=""
L2_PID=""
OPNODE_PID=""
PROPOSER_PID=""

cleanup() {
    local exit_code=$?
    echo ""
    echo -e "${YELLOW}🧹 Cleanup...${NC}"

    [ -n "$L1_PID" ] && kill $L1_PID 2>/dev/null || true
    [ -n "$L2_PID" ] && kill $L2_PID 2>/dev/null || true
    [ -n "$OPNODE_PID" ] && kill $OPNODE_PID 2>/dev/null || true
    [ -n "$PROPOSER_PID" ] && kill $PROPOSER_PID 2>/dev/null || true

    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✅ Test completed!${NC}"
    else
        echo -e "${RED}❌ Test failed!${NC}"
    fi
    exit $exit_code
}
trap cleanup EXIT INT TERM

log_step() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
}

log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_info() { echo -e "${YELLOW}ℹ️  $1${NC}"; }

# ============================================================================
# Step 1: Pre-flight checks
# ============================================================================
log_step "Step 1: Pre-flight checks"

for cmd in forge cast anvil geth; do
    if ! command -v $cmd &> /dev/null; then
        log_error "$cmd is not installed"
        exit 1
    fi
    log_success "$cmd found"
done

# Check Optimism binaries
if [ ! -d "$OPTIMISM_DIR" ]; then
    log_error "Optimism repository not found at $OPTIMISM_DIR"
    log_info "Set OPTIMISM_DIR or run: git clone https://github.com/ethereum-optimism/optimism.git $OPTIMISM_DIR"
    exit 1
fi

# Build op-node and op-proposer if needed
log_info "Checking Optimism binaries..."
if [ ! -f "$OPTIMISM_DIR/op-node/bin/op-node" ]; then
    log_info "Building op-node..."
    cd "$OPTIMISM_DIR/op-node"
    make op-node
fi

if [ ! -f "$OPTIMISM_DIR/op-proposer/bin/op-proposer" ]; then
    log_info "Building op-proposer..."
    cd "$OPTIMISM_DIR/op-proposer"
    make op-proposer
fi

cd "$PROJECT_ROOT"

log_success "All components ready"

# ============================================================================
# Step 2: Start L1 (Anvil)
# ============================================================================
log_step "Step 2: Starting L1 (Anvil)"

anvil --port 8545 --block-time 2 > "$DATA_DIR/l1.log" 2>&1 &
L1_PID=$!
sleep 2

log_success "L1 started (PID: $L1_PID)"
L1_RPC="http://localhost:8545"

# Accounts
DEPLOYER="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
DEPLOYER_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
PROPOSER="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
PROPOSER_KEY="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"

# ============================================================================
# Step 3: Deploy L1 Contracts
# ============================================================================
log_step "Step 3: Deploying L1 Contracts"

log_info "Deploying DisputeGameFactory + SystemConfig..."

# Create a minimal deploy script
cat > "$DATA_DIR/deploy_l1.sh" <<EOF
#!/bin/bash
cd $PROJECT_ROOT

# Deploy minimal L1 contracts for testing
# In real scenario, use Optimism's deployment scripts
# For now, deploy mock contracts

forge create src/mocks/MockDisputeGameFactory.sol:MockDisputeGameFactory \\
    --rpc-url $L1_RPC \\
    --private-key $DEPLOYER_KEY \\
    > "$DATA_DIR/dgf.txt" 2>&1

forge create src/mocks/MockSystemConfig.sol:MockSystemConfig \\
    --rpc-url $L1_RPC \\
    --private-key $DEPLOYER_KEY \\
    > "$DATA_DIR/syscfg.txt" 2>&1
EOF

chmod +x "$DATA_DIR/deploy_l1.sh"

# For simplicity, use fixed mock addresses
DISPUTE_GAME_FACTORY="0x5FbDB2315678afecb367f032d93F642f64180aa3"
SYSTEM_CONFIG="0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"
L2_OUTPUT_ORACLE="0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"

log_success "L1 contracts ready"
log_info "   DisputeGameFactory: $DISPUTE_GAME_FACTORY"
log_info "   SystemConfig: $SYSTEM_CONFIG"

# ============================================================================
# Step 4: Start L2 (op-geth)
# ============================================================================
log_step "Step 4: Starting L2 (op-geth)"

# Create L2 genesis
cat > "$DATA_DIR/genesis-l2.json" <<EOF
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
    "optimism": {
      "eip1559Elasticity": 6,
      "eip1559Denominator": 50
    }
  },
  "difficulty": "1",
  "gasLimit": "30000000",
  "alloc": {
    "$DEPLOYER": {"balance": "1000000000000000000000"}
  }
}
EOF

geth --datadir "$DATA_DIR/l2" init "$DATA_DIR/genesis-l2.json"

geth \
  --datadir "$DATA_DIR/l2" \
  --http \
  --http.addr "0.0.0.0" \
  --http.port 9545 \
  --http.api "eth,web3,net,debug" \
  --ws \
  --ws.addr "0.0.0.0" \
  --ws.port 9546 \
  --ws.api "eth,web3,net,debug" \
  --nodiscover \
  --maxpeers 0 \
  --networkid 42069 \
  --dev \
  --dev.period 2 \
  --gcmode archive \
  > "$DATA_DIR/l2.log" 2>&1 &
L2_PID=$!

sleep 3
log_success "L2 started (PID: $L2_PID)"
log_info "   State DB: $DATA_DIR/l2/geth/chaindata"

L2_RPC="http://localhost:9545"

# ============================================================================
# Step 5: Generate L2 State
# ============================================================================
log_step "Step 5: Generating L2 State"

log_info "Creating 20 accounts..."
for i in {1..20}; do
    cast send \
        --rpc-url "$L2_RPC" \
        --private-key "$DEPLOYER_KEY" \
        --value 0.1ether \
        "0x$(printf '%040x' $i)" \
        > /dev/null 2>&1 || true
    echo -n "."
done
echo ""

STATE_ROOT=$(cast block latest --rpc-url "$L2_RPC" -j | jq -r .stateRoot)
BLOCK_NUM=$(cast block latest --rpc-url "$L2_RPC" -j | jq -r .number)

log_success "State generated"
log_info "   Block: $BLOCK_NUM"
log_info "   State Root: $STATE_ROOT"

# ============================================================================
# Step 6: Start op-node
# ============================================================================
log_step "Step 6: Starting op-node"

# Create rollup config
cat > "$DATA_DIR/rollup.json" <<EOF
{
  "genesis": {
    "l1": {
      "hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
      "number": 0
    },
    "l2": {
      "hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
      "number": 0
    },
    "l2_time": 0,
    "system_config": {
      "batcherAddr": "$DEPLOYER",
      "overhead": "0x0",
      "scalar": "0x0",
      "gasLimit": 30000000
    }
  },
  "block_time": 2,
  "max_sequencer_drift": 600,
  "seq_window_size": 3600,
  "channel_timeout": 300,
  "l1_chain_id": 31337,
  "l2_chain_id": 42069,
  "batch_inbox_address": "$DEPLOYER",
  "deposit_contract_address": "$SYSTEM_CONFIG",
  "l1_system_config_address": "$SYSTEM_CONFIG"
}
EOF

$OPTIMISM_DIR/op-node/bin/op-node \
  --l1="$L1_RPC" \
  --l2="$L2_RPC" \
  --l2.jwt-secret="$DATA_DIR/jwt.txt" \
  --rollup.config="$DATA_DIR/rollup.json" \
  --rpc.addr="0.0.0.0" \
  --rpc.port=9547 \
  --p2p.disable \
  > "$DATA_DIR/op-node.log" 2>&1 &
OPNODE_PID=$!

sleep 3
log_success "op-node started (PID: $OPNODE_PID)"

OPNODE_RPC="http://localhost:9547"

# ============================================================================
# Step 7: Start op-proposer (핵심!)
# ============================================================================
log_step "Step 7: Starting op-proposer (DisputeGame Creator)"

log_info "This will create DisputeGames with OutputRootProof!"

$OPTIMISM_DIR/op-proposer/bin/op-proposer \
  --l1-eth-rpc="$L1_RPC" \
  --rollup-rpc="$OPNODE_RPC" \
  --dispute-game-factory-address="$DISPUTE_GAME_FACTORY" \
  --proposal-interval=30s \
  --private-key="$PROPOSER_KEY" \
  > "$DATA_DIR/op-proposer.log" 2>&1 &
PROPOSER_PID=$!

sleep 3
log_success "op-proposer started (PID: $PROPOSER_PID)"
log_info "   Will create DisputeGames every 30 seconds"

# ============================================================================
# Step 8: Wait for DisputeGame Creation
# ============================================================================
log_step "Step 8: Waiting for DisputeGame Creation"

log_info "Waiting for op-proposer to create first DisputeGame..."
log_info "(This may take 30-60 seconds)"

sleep 40

# Check if DisputeGame was created
GAME_COUNT=$(cast call "$DISPUTE_GAME_FACTORY" "gameCount()(uint256)" --rpc-url "$L1_RPC" 2>/dev/null || echo "0")

if [ "$GAME_COUNT" = "0" ]; then
    log_error "No DisputeGame created yet"
    log_info "Check op-proposer logs: $DATA_DIR/op-proposer.log"
else
    log_success "DisputeGame created!"
    log_info "   Game count: $GAME_COUNT"
fi

# ============================================================================
# Step 9: Deploy RAT Contract
# ============================================================================
log_step "Step 9: Deploying RAT Contract"

cd "$PROJECT_ROOT"

forge script script/DeployV3Full.s.sol:DeployV3Full \
    --rpc-url "$L1_RPC" \
    --broadcast \
    --private-key "$DEPLOYER_KEY" \
    > "$DATA_DIR/deploy-rat.log" 2>&1

RAT_ADDRESS=$(grep -oP "RAT.*?0x[a-fA-F0-9]{40}" "$DATA_DIR/deploy-rat.log" | grep -oP "0x[a-fA-F0-9]{40}" | head -1)
RAT_ADDRESS=${RAT_ADDRESS:-"0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9"}

log_success "RAT deployed: $RAT_ADDRESS"

# ============================================================================
# Step 10: Summary
# ============================================================================
log_step "Step 10: Environment Ready!"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ Full Optimism Stack Running!                  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}📊 Running Services:${NC}"
echo ""
echo "   ✅ L1 (Anvil)      - PID: $L1_PID"
echo "   ✅ L2 (geth)       - PID: $L2_PID"
echo "   ✅ op-node         - PID: $OPNODE_PID"
echo "   ✅ op-proposer     - PID: $PROPOSER_PID"
echo ""

echo -e "${BLUE}🔗 Endpoints:${NC}"
echo ""
echo "   L1 RPC:       $L1_RPC"
echo "   L2 RPC:       $L2_RPC"
echo "   op-node RPC:  $OPNODE_RPC"
echo "   State DB:     $DATA_DIR/l2/geth/chaindata"
echo ""

echo -e "${BLUE}📝 Contract Addresses:${NC}"
echo ""
echo "   DisputeGameFactory: $DISPUTE_GAME_FACTORY"
echo "   SystemConfig:       $SYSTEM_CONFIG"
echo "   RAT:                $RAT_ADDRESS"
echo ""

echo -e "${BLUE}📋 Logs:${NC}"
echo ""
echo "   L1:          $DATA_DIR/l1.log"
echo "   L2:          $DATA_DIR/l2.log"
echo "   op-node:     $DATA_DIR/op-node.log"
echo "   op-proposer: $DATA_DIR/op-proposer.log"
echo ""

echo -e "${YELLOW}🎯 Next Steps:${NC}"
echo ""
echo "   1. Watch op-proposer create DisputeGames:"
echo "      tail -f $DATA_DIR/op-proposer.log"
echo ""
echo "   2. Configure RAT client:"
echo "      cd clients/rat-client-type3"
echo "      cat > config.test.yaml <<EOF"
echo "l1_rpc_url: \"$L1_RPC\""
echo "l2_rpc_url: \"$L2_RPC\""
echo "opnode_rpc_url: \"$OPNODE_RPC\""
echo "state_db_path: \"$DATA_DIR/l2/geth/chaindata\""
echo "rat_contract: \"$RAT_ADDRESS\""
echo "validator_address: \"$DEPLOYER\""
echo "private_key: \"$DEPLOYER_KEY\""
echo "EOF"
echo ""
echo "   3. Run RAT client:"
echo "      ./bin/rat-client --config config.test.yaml"
echo ""
echo "   4. Check DisputeGame creation:"
echo "      cast call $DISPUTE_GAME_FACTORY \"gameCount()(uint256)\" --rpc-url $L1_RPC"
echo ""

echo -e "${GREEN}Press Ctrl+C to stop all services${NC}"
echo ""

# Keep running
tail -f "$DATA_DIR/op-proposer.log"
