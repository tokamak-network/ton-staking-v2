#!/bin/bash
# Minimal E2E Test Environment for RAT Client
# 최소한의 geth만 띄워서 state trie 접근 테스트

set -e

echo "🚀 Starting Minimal E2E Environment for RAT Client"
echo ""

# Configuration
DATA_DIR="/tmp/rat-e2e-geth"
HTTP_PORT=8545
CHAIN_ID=1337

# Clean up previous data
echo "🧹 Cleaning up previous data..."
rm -rf "$DATA_DIR"
mkdir -p "$DATA_DIR"

# Create genesis file
echo "📝 Creating genesis.json..."
cat > "$DATA_DIR/genesis.json" <<EOF
{
  "config": {
    "chainId": $CHAIN_ID,
    "homesteadBlock": 0,
    "eip150Block": 0,
    "eip155Block": 0,
    "eip158Block": 0,
    "byzantiumBlock": 0,
    "constantinopleBlock": 0,
    "petersburgBlock": 0,
    "istanbulBlock": 0,
    "berlinBlock": 0,
    "londonBlock": 0
  },
  "difficulty": "1",
  "gasLimit": "8000000",
  "alloc": {
    "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266": {
      "balance": "1000000000000000000000"
    },
    "0x70997970C51812dc3A010C7d01b50e0d17dc79C8": {
      "balance": "1000000000000000000000"
    },
    "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC": {
      "balance": "1000000000000000000000"
    },
    "0x90F79bf6EB2c4f870365E785982E1f101E93b906": {
      "balance": "1000000000000000000000"
    },
    "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65": {
      "balance": "1000000000000000000000"
    }
  }
}
EOF

# Initialize geth
echo "⚙️  Initializing geth..."
geth --datadir "$DATA_DIR" init "$DATA_DIR/genesis.json"

# Start geth in dev mode
echo "🚀 Starting geth..."
echo ""
echo "Configuration:"
echo "  - Data Dir: $DATA_DIR"
echo "  - HTTP Port: $HTTP_PORT"
echo "  - Chain ID: $CHAIN_ID"
echo "  - State DB: $DATA_DIR/geth/chaindata"
echo ""

# Start geth with debug RPC and allow state access
geth \
  --datadir "$DATA_DIR" \
  --http \
  --http.addr "0.0.0.0" \
  --http.port $HTTP_PORT \
  --http.api "eth,web3,net,debug,personal" \
  --http.corsdomain "*" \
  --ws \
  --ws.addr "0.0.0.0" \
  --ws.port 8546 \
  --ws.api "eth,web3,net,debug" \
  --allow-insecure-unlock \
  --nodiscover \
  --maxpeers 0 \
  --networkid $CHAIN_ID \
  --dev \
  --dev.period 2 \
  --verbosity 3 \
  2>&1 | tee "$DATA_DIR/geth.log"
