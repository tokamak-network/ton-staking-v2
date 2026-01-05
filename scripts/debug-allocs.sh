#!/bin/bash

echo "=== Debugging Allocs Loading Issue ==="
echo ""

ADDR=$(jq -r '.DisputeGameFactoryProxy' .devnet/optimism-addresses.json | tr '[:upper:]' '[:lower:]')
echo "DisputeGameFactoryProxy address (lowercase): $ADDR"
echo ""

echo "1. Checking if address is in allocs-l1.json:"
if jq -e ".\"$ADDR\"" .devnet/allocs-l1.json > /dev/null 2>&1; then
    echo "   ✓ Found in allocs"
    CODE_LEN=$(jq -r ".\"$ADDR\".code" .devnet/allocs-l1.json | wc -c)
    echo "   Code length in allocs: $CODE_LEN bytes"
else
    echo "   ✗ NOT found in allocs"
fi

echo ""
echo "2. Checking Anvil command:"
grep -A 5 "anvil" .devnet/anvil.log | head -n 1 || echo "   (No anvil command found in log)"

echo ""
echo "3. Checking first 5 addresses in allocs-l1.json:"
jq 'keys | .[0:5]' .devnet/allocs-l1.json

echo ""
echo "4. Checking what code Anvil has at the proxy address:"
CODE=$(cast code $ADDR --rpc-url http://localhost:8545 2>/dev/null)
echo "   Code: ${CODE:0:50}..."
if [ "$CODE" == "0x" ]; then
    echo "   ✗ No code deployed"
else
    echo "   ✓ Code exists (${#CODE} chars)"
fi

echo ""
echo "5. Checking Anvil state dump:"
echo "   Total accounts in Anvil state:"
cast rpc debug_traceBlockByNumber "latest" --rpc-url http://localhost:8545 2>/dev/null | jq 'length' || echo "   (Can't get state)"
