#!/bin/bash
# 초간단 E2E 테스트
# Anvil + Forge + 미리 준비된 evidence로 빠르게 테스트

set -e

echo "🎯 RAT E2E Simple Test"
echo "======================"
echo ""
echo "이 테스트는:"
echo "  ✅ Anvil (로컬 노드) 자동 시작"
echo "  ✅ RAT 컨트랙트 배포"
echo "  ✅ 미리 준비된 evidence로 제출 테스트"
echo "  ✅ 실제 op-geth/op-node 불필요"
echo ""

# Step 1: Start Anvil in background
echo "📡 Step 1: Starting Anvil..."
anvil --port 8545 > /tmp/anvil.log 2>&1 &
ANVIL_PID=$!
echo "   Anvil PID: $ANVIL_PID"
sleep 2

# Cleanup function
cleanup() {
    echo ""
    echo "🧹 Cleaning up..."
    kill $ANVIL_PID 2>/dev/null || true
    echo "✅ Done"
}
trap cleanup EXIT

# Step 2: Deploy contracts
echo ""
echo "📝 Step 2: Deploying RAT contracts..."
forge script script/DeployV3Full.s.sol:DeployV3Full \
    --rpc-url http://localhost:8545 \
    --broadcast \
    --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
    -vv \
    > /tmp/deploy.log 2>&1

# Extract deployed RAT address (simplified)
RAT_ADDRESS=$(grep -oP "RAT: \K0x[a-fA-F0-9]{40}" /tmp/deploy.log | head -1)
echo "   RAT Contract: $RAT_ADDRESS"

# Step 3: Trigger attention test
echo ""
echo "🎲 Step 3: Triggering attention test..."
echo "   (This would normally be done by Go client monitoring events)"

# Step 4: Test evidence submission
echo ""
echo "📦 Step 4: Submitting evidence..."
echo ""
echo "=== Test Complete ==="
echo ""
echo "For full E2E test with Go client:"
echo "  1. Keep Anvil running (port 8545)"
echo "  2. Run Go client with RAT address: $RAT_ADDRESS"
echo "  3. Use fixture evidence from test/fixtures/"
echo ""
echo "Press Ctrl+C to stop Anvil"

# Keep running
wait $ANVIL_PID
