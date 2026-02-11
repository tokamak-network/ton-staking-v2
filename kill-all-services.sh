#!/bin/bash

echo "🛑 Killing all backend and frontend processes..."

# Kill Foundry devnet
if [ -f .devnet/devnet.pid ]; then
  kill $(cat .devnet/devnet.pid) 2>/dev/null && rm -f .devnet/devnet.pid
  echo "  ✅ Foundry devnet killed"
fi

# Kill Hardhat node
pgrep -f "hardhat node" | xargs kill -9 2>/dev/null
echo "  ✅ Hardhat node killed"

# Kill Foundry-related processes
pgrep -f "forge" | xargs kill -9 2>/dev/null
echo "  ✅ Foundry-related processes killed"

# Kill RPC port 8545
lsof -i :8545 | grep LISTEN | awk '{print $2}' | xargs kill -9 2>/dev/null
echo "  ✅ Port 8545 (RPC) killed"

# Kill Next.js frontend (port 30)
lsof -i :3000 | grep LISTEN | awk '{print $2}' | xargs kill -9 2>/dev/null
pgrep -f "npm run dev" | xargs kill -9 2>/dev/null
pgrep -f "yarn dev" | xargs kill -9 2>/dev/null
echo "  ✅ Next.js frontend killed"

echo "✅ All services have been terminated successfully."
