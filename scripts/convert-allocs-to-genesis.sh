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

# Add Anvil default test accounts with funds (10000 ETH each) for E2E testing
# These are the standard Anvil test accounts that tests expect to have funds
TEST_ACCOUNTS='[
  "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
  "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
  "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
  "0x90F79bf6EB2c4f870365E785982E1f101E93b906",
  "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65",
  "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc",
  "0x976EA74026E726554dB657fA54763abd0C3a0aa9",
  "0x14dC79964da2C08b23698B3D3cc7Ca32193d9955",
  "0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f",
  "0xa0Ee7A142d267C1f36714E4a8F75612F20a79720"
]'

# Create full genesis.json with allocs (Ethereum standard format)
# Using Clique PoA consensus for local development
# - extraData contains: 32 bytes vanity + 20 bytes signer address + 65 bytes signature
# - Signer is Account #0 (0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266)
CLIQUE_SIGNER="f39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
EXTRA_DATA="0x0000000000000000000000000000000000000000000000000000000000000000${CLIQUE_SIGNER}0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"

jq --argjson testAccounts "$TEST_ACCOUNTS" --arg extraData "$EXTRA_DATA" '{
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
    clique: {
      period: 1,
      epoch: 30000
    }
  },
  nonce: "0x0",
  timestamp: "0x0",
  extraData: $extraData,
  gasLimit: "0x1c9c380",
  difficulty: "0x1",
  mixHash: "0x0000000000000000000000000000000000000000000000000000000000000000",
  coinbase: "0x0000000000000000000000000000000000000000",
  alloc: (. + ($testAccounts | map({(.): {balance: "0x21e19e0c9bab2400000"}}) | add))
}' "$ALLOCS_FILE" > "$GENESIS_FILE"

echo "✓ Genesis file created: $GENESIS_FILE"
