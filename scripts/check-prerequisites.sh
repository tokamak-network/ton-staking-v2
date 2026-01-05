#!/bin/bash
echo "=== Checking Prerequisites ==="
echo ""

# Check Go
if command -v go &> /dev/null; then
    echo "✓ Go: $(go version)"
else
    echo "✗ Go not found - install from https://go.dev/dl/"
fi

# Check Forge
if command -v forge &> /dev/null; then
    echo "✓ Forge: $(forge --version | head -1)"
else
    echo "✗ Forge not found - install Foundry from https://getfoundry.sh/"
fi

# Check Anvil
if command -v anvil &> /dev/null; then
    echo "✓ Anvil: $(anvil --version | head -1)"
else
    echo "✗ Anvil not found - install Foundry from https://getfoundry.sh/"
fi

# Check Cast
if command -v cast &> /dev/null; then
    echo "✓ Cast: $(cast --version | head -1)"
else
    echo "✗ Cast not found - install Foundry from https://getfoundry.sh/"
fi

# Check Just
if command -v just &> /dev/null; then
    echo "✓ Just: $(just --version)"
else
    echo "✗ Just not found - install with 'brew install just' (macOS) or from https://github.com/casey/just"
fi

# Check jq
if command -v jq &> /dev/null; then
    echo "✓ jq: $(jq --version)"
else
    echo "✗ jq not found - install with 'brew install jq' (macOS)"
fi

echo ""
echo "All checks complete!"
