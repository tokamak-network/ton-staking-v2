#!/bin/bash

set -e

echo "🎰 LotteryCandidate Demo Setup"
echo "=============================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check for anvil
if ! command -v anvil &> /dev/null; then
    echo -e "${RED}Error: anvil not found. Please install foundry first.${NC}"
    echo "Run: curl -L https://foundry.paradigm.xyz | bash && foundryup"
    exit 1
fi

# Check for node
if ! command -v node &> /dev/null; then
    echo -e "${RED}Error: node not found. Please install Node.js first.${NC}"
    exit 1
fi

# Step 1: Start Anvil in background
echo -e "${YELLOW}Step 1: Starting Anvil...${NC}"
pkill -f "anvil" 2>/dev/null || true
sleep 1

anvil --host 0.0.0.0 --port 8545 --chain-id 31337 &
ANVIL_PID=$!
sleep 2

if ! ps -p $ANVIL_PID > /dev/null; then
    echo -e "${RED}Failed to start Anvil${NC}"
    exit 1
fi
echo -e "${GREEN}Anvil running on http://localhost:8545 (PID: $ANVIL_PID)${NC}"
echo ""

# Step 2: Deploy contracts
echo -e "${YELLOW}Step 2: Deploying LotteryCandidate contracts...${NC}"
DEPLOY_OUTPUT=$(forge script script/DeployLotteryDemo.s.sol:DeployLotteryDemo \
    --rpc-url http://localhost:8545 \
    --broadcast \
    --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
    2>&1)

# Extract JSON from deployment output
DEPLOYMENT_JSON=$(echo "$DEPLOY_OUTPUT" | sed -n '/DEPLOYMENT_JSON_START/,/DEPLOYMENT_JSON_END/p' | grep -v "DEPLOYMENT_JSON")

if [ -z "$DEPLOYMENT_JSON" ]; then
    echo -e "${RED}Failed to extract deployment addresses${NC}"
    echo "$DEPLOY_OUTPUT"
    kill $ANVIL_PID 2>/dev/null
    exit 1
fi

# Save deployment JSON
echo "$DEPLOYMENT_JSON" > demo-frontend/src/deployment.json
echo -e "${GREEN}Contracts deployed successfully!${NC}"
echo ""

# Print deployment info
echo -e "${YELLOW}Deployment Addresses:${NC}"
echo "$DEPLOYMENT_JSON" | grep -E "(ton|wton|lotteryCandidate|operator)" | head -6
echo ""

# Step 3: Install frontend dependencies
echo -e "${YELLOW}Step 3: Installing frontend dependencies...${NC}"
cd demo-frontend
if [ ! -d "node_modules" ]; then
    npm install
fi
echo -e "${GREEN}Dependencies installed!${NC}"
echo ""

# Step 4: Start frontend
echo -e "${YELLOW}Step 4: Starting frontend dev server...${NC}"
echo ""
echo "=============================="
echo -e "${GREEN}🎉 Demo is ready!${NC}"
echo "=============================="
echo ""
echo "Frontend: http://localhost:5173"
echo "Anvil RPC: http://localhost:8545"
echo ""
echo "Test Accounts (import to MetaMask):"
echo "  Operator: 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
echo "  User1:    0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"
echo "  User2:    0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6"
echo ""
echo "Configuration JSON for frontend:"
echo "$DEPLOYMENT_JSON"
echo ""
echo "Press Ctrl+C to stop the demo"
echo ""

# Trap to cleanup on exit
cleanup() {
    echo ""
    echo "Stopping demo..."
    kill $ANVIL_PID 2>/dev/null || true
    exit 0
}
trap cleanup SIGINT SIGTERM

npm run dev
