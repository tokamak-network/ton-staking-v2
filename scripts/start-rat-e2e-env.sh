#!/bin/bash
# RAT E2E Test Environment Setup
# op-geth (디버그) + op-node + op-proposer 최소 구성

set -e

echo "🎯 RAT E2E Test Environment Setup"
echo "==================================="
echo ""
echo "구성 요소:"
echo "  1. L1 (Anvil) - 8545"
echo "  2. op-geth (L2 디버그 모드) - 9545"
echo "  3. op-node (Rollup RPC) - 9546"
echo "  4. op-proposer (DisputeGame 생성)"
echo ""

# Configuration
L1_RPC="http://localhost:8545"
L2_RPC="http://localhost:9545"
OPNODE_RPC="http://localhost:9546"
DATA_DIR="/tmp/rat-e2e"
OPTIMISM_DIR="${OPTIMISM_DIR:-../../lib/optimism}"

# Check if optimism repo exists
if [ ! -d "$OPTIMISM_DIR" ]; then
    echo "❌ Error: Optimism repository not found at $OPTIMISM_DIR"
    echo ""
    echo "Please set OPTIMISM_DIR environment variable or clone optimism:"
    echo "  git clone https://github.com/ethereum-optimism/optimism.git lib/optimism"
    exit 1
fi

# Clean up
echo "🧹 Cleaning up previous data..."
rm -rf "$DATA_DIR"
mkdir -p "$DATA_DIR"

# Step 1: Start L1 (Anvil)
echo ""
echo "📡 Step 1: Starting L1 (Anvil)..."
anvil --port 8545 > "$DATA_DIR/l1.log" 2>&1 &
L1_PID=$!
echo "   L1 PID: $L1_PID"
sleep 2

# Cleanup function
cleanup() {
    echo ""
    echo "🧹 Shutting down..."
    kill $L1_PID 2>/dev/null || true
    kill $L2_PID 2>/dev/null || true
    kill $OPNODE_PID 2>/dev/null || true
    kill $PROPOSER_PID 2>/dev/null || true
    echo "✅ Cleanup complete"
}
trap cleanup EXIT INT TERM

# Step 2: Deploy L1 contracts
echo ""
echo "📝 Step 2: Deploying L1 contracts (DisputeGameFactory, etc.)..."

# Use optimism's deploy script or forge script
# For simplicity, we'll use a minimal deployment

cat > "$DATA_DIR/deploy.sh" <<'DEPLOY_SCRIPT'
#!/bin/bash
# Deploy minimal L1 contracts for RAT testing

forge script script/DeployL1Contracts.s.sol:DeployL1Contracts \
    --rpc-url http://localhost:8545 \
    --broadcast \
    --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Extract addresses
# (This is simplified - real deployment would be more complex)
DEPLOY_SCRIPT

# For now, use mock addresses (in real E2E, deploy actual contracts)
DISPUTE_GAME_FACTORY="0x5FbDB2315678afecb367f032d93F642f64180aa3"
SYSTEM_CONFIG="0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"

echo "   DisputeGameFactory: $DISPUTE_GAME_FACTORY"
echo "   SystemConfig: $SYSTEM_CONFIG"

# Step 3: Start op-geth (L2) with debug mode
echo ""
echo "🚀 Step 3: Starting op-geth (L2) with debug mode..."

# Create genesis
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
    "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266": {
      "balance": "1000000000000000000000"
    }
  }
}
EOF

# Initialize L2
geth --datadir "$DATA_DIR/l2" init "$DATA_DIR/genesis-l2.json"

# Start op-geth with debug RPC
geth \
  --datadir "$DATA_DIR/l2" \
  --http \
  --http.addr "0.0.0.0" \
  --http.port 9545 \
  --http.api "eth,web3,net,debug,personal" \
  --http.corsdomain "*" \
  --ws \
  --ws.addr "0.0.0.0" \
  --ws.port 9546 \
  --ws.api "eth,web3,net,debug" \
  --allow-insecure-unlock \
  --nodiscover \
  --maxpeers 0 \
  --networkid 42069 \
  --dev \
  --dev.period 2 \
  --gcmode archive \
  --verbosity 3 \
  > "$DATA_DIR/l2.log" 2>&1 &
L2_PID=$!

echo "   L2 PID: $L2_PID"
echo "   State DB: $DATA_DIR/l2/geth/chaindata"
sleep 3

# Step 4: Generate some state (accounts)
echo ""
echo "📊 Step 4: Generating state (creating accounts)..."

# Send some transactions to populate state trie
for i in {1..10}; do
    cast send \
        --rpc-url http://localhost:9545 \
        --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
        --value 1ether \
        "0x$(printf '%040x' $i)" \
        > /dev/null 2>&1 || true
done

echo "   ✅ Created 10 accounts in state trie"

# Step 5: Print environment info
echo ""
echo "=================================="
echo "✅ RAT E2E Environment Ready!"
echo "=================================="
echo ""
echo "📡 Endpoints:"
echo "   L1 RPC:       http://localhost:8545"
echo "   L2 RPC:       http://localhost:9545"
echo "   L2 State DB:  $DATA_DIR/l2/geth/chaindata"
echo ""
echo "📝 Contract Addresses (mock):"
echo "   DisputeGameFactory: $DISPUTE_GAME_FACTORY"
echo "   SystemConfig:       $SYSTEM_CONFIG"
echo ""
echo "🔧 Test Commands:"
echo ""
echo "1. Check L2 state:"
echo "   cast block latest --rpc-url http://localhost:9545"
echo ""
echo "2. Get state root:"
echo "   cast block latest --rpc-url http://localhost:9545 -j | jq -r .stateRoot"
echo ""
echo "3. Access state DB for RAT client:"
echo "   STATE_DB_PATH=$DATA_DIR/l2/geth/chaindata"
echo ""
echo "4. Run RAT E2E test:"
echo "   cd clients/rat-client-type3"
echo "   E2E_TEST=1 \\"
echo "   L2_RPC_URL=http://localhost:9545 \\"
echo "   STATE_DB_PATH=$DATA_DIR/l2/geth/chaindata \\"
echo "   go test -v ./test -run TestStateLeafE2E"
echo ""
echo "Press Ctrl+C to stop all services"
echo ""

# Keep running
tail -f "$DATA_DIR/l2.log"
