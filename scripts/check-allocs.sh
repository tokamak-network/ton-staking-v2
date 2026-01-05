#!/bin/bash

IMPL=$(jq -r '.DisputeGameFactory' lib/optimism/.devnet/addresses.json | tr '[:upper:]' '[:lower:]')
PROXY=$(jq -r '.DisputeGameFactoryProxy' lib/optimism/.devnet/addresses.json | tr '[:upper:]' '[:lower:]')

echo "DisputeGameFactory implementation: $IMPL"
echo "DisputeGameFactoryProxy: $PROXY"
echo ""
echo "Checking allocs-l1.json:"

if jq -e ".\"$IMPL\"" lib/optimism/.devnet/allocs-l1.json > /dev/null 2>&1; then
    echo "✓ Implementation IS in allocs"
else
    echo "✗ Implementation NOT in allocs"
fi

if jq -e ".\"$PROXY\"" lib/optimism/.devnet/allocs-l1.json > /dev/null 2>&1; then
    echo "✓ Proxy IS in allocs"
else
    echo "✗ Proxy NOT in allocs"
fi
