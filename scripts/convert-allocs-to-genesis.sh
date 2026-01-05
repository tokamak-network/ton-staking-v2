#!/bin/bash
#
# Convert allocs-l1.json to full genesis.json format for Anvil --init
#

set -e

ALLOCS_FILE="${1:-.devnet/allocs-l1.json}"
GENESIS_FILE="${2:-.devnet/genesis-l1.json}"

if [ ! -f "$ALLOCS_FILE" ]; then
    echo "Error: Allocs file not found: $ALLOCS_FILE"
    exit 1
fi

echo "Converting allocs to genesis format..."
echo "  Input: $ALLOCS_FILE"
echo "  Output: $GENESIS_FILE"

# Create full genesis.json with allocs (Ethereum standard format)
jq '{
  config: {
    chainId: 900,
    homesteadBlock: 0,
    eip150Block: 0,
    eip155Block: 0,
    eip158Block: 0,
    byzantiumBlock: 0,
    constantinopleBlock: 0,
    petersburgBlock: 0,
    istanbulBlock: 0,
    berlinBlock: 0,
    londonBlock: 0,
    arrowGlacierBlock: 0,
    grayGlacierBlock: 0,
    mergeNetsplitBlock: 0,
    shanghaiTime: 0,
    cancunTime: 0,
    terminalTotalDifficulty: 0,
    terminalTotalDifficultyPassed: true
  },
  nonce: "0x0",
  timestamp: "0x0",
  extraData: "0x",
  gasLimit: "0x1c9c380",
  difficulty: "0x0",
  mixHash: "0x0000000000000000000000000000000000000000000000000000000000000000",
  coinbase: "0x0000000000000000000000000000000000000000",
  baseFeePerGas: "0x3b9aca00",
  alloc: .
}' "$ALLOCS_FILE" > "$GENESIS_FILE"

echo "✓ Genesis file created: $GENESIS_FILE"
