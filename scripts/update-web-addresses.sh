#!/bin/bash
# =============================================================================
# Update Web UI Addresses
# =============================================================================
# This script copies the latest deployed addresses to web-ui/public folder
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEVNET_DIR="$PROJECT_ROOT/.devnet"
WEB_PUBLIC_DIR="$PROJECT_ROOT/web-ui/public"

echo "🔄 Updating Web UI addresses..."
echo ""

# Check if source files exist
if [ ! -f "$DEVNET_DIR/addresses.json" ]; then
    echo "❌ Error: $DEVNET_DIR/addresses.json not found"
    echo "Please deploy the contracts first with:"
    echo "  ./scripts/generate-allocs-offline.sh"
    exit 1
fi

# Create web-ui/public directory if it doesn't exist
mkdir -p "$WEB_PUBLIC_DIR"

# Copy addresses
echo "📦 Copying TON Staking addresses..."
cp "$DEVNET_DIR/addresses.json" "$WEB_PUBLIC_DIR/addresses.json"
echo "   ✓ $WEB_PUBLIC_DIR/addresses.json"

# Copy Optimism addresses if exists
if [ -f "$DEVNET_DIR/optimism-addresses.json" ]; then
    echo "📦 Copying Optimism addresses..."
    cp "$DEVNET_DIR/optimism-addresses.json" "$WEB_PUBLIC_DIR/optimism-addresses.json"
    echo "   ✓ $WEB_PUBLIC_DIR/optimism-addresses.json"
fi

echo ""
echo "✅ Web UI addresses updated successfully!"
echo ""
echo "📋 Current addresses:"
echo "   TON:         $(jq -r '.ton' "$WEB_PUBLIC_DIR/addresses.json")"
echo "   WTON:        $(jq -r '.wton' "$WEB_PUBLIC_DIR/addresses.json")"
echo "   SeigManager: $(jq -r '.seigManagerProxy' "$WEB_PUBLIC_DIR/addresses.json")"
echo "   RAT:         $(jq -r '.ratProxy' "$WEB_PUBLIC_DIR/addresses.json")"
echo "   SystemConfig: $(jq -r '.systemConfig' "$WEB_PUBLIC_DIR/addresses.json")"
echo ""
echo "💡 Reload the web page or click 'Reload Config' button to apply changes"
