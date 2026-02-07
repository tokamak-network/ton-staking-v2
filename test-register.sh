#!/bin/bash
set -e

L1_RPC="http://localhost:8545"
L1_BRIDGE_REGISTRY="0x2dE080e97B0caE9825375D31f5D0eD5751fDf16D"
SYSTEM_CONFIG="0x577AcB7fA48878245a854ba51eD051a5B47cF83f"
TON="0xd55b55304b5cf7607B6dEd6DA6EeB487918AaD2E"
DEPLOYER_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
TON_STAKING_DEPLOYER_KEY="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"

echo "=== Debugging RegisterError(2) ==="
echo ""

echo "1. Check rollupInfo for SystemConfig:"
cast call $L1_BRIDGE_REGISTRY "getRollupInfo(address)(uint8,address,bool,bool,string)" $SYSTEM_CONFIG --rpc-url $L1_RPC
echo ""

echo "2. Check if bridge is already registered:"
BRIDGE=$(cast call $SYSTEM_CONFIG "l1StandardBridge()(address)" --rpc-url $L1_RPC)
echo "   l1StandardBridge: $BRIDGE"
IS_BRIDGE_REGISTERED=$(cast call $L1_BRIDGE_REGISTRY "l1Bridge(address)(bool)" $BRIDGE --rpc-url $L1_RPC)
echo "   l1Bridge[$BRIDGE]: $IS_BRIDGE_REGISTERED"
echo ""

echo "3. Check if portal is already registered:"
PORTAL=$(cast call $SYSTEM_CONFIG "optimismPortal()(address)" --rpc-url $L1_RPC)
echo "   optimismPortal: $PORTAL"
IS_PORTAL_REGISTERED=$(cast call $L1_BRIDGE_REGISTRY "portal(address)(bool)" $PORTAL --rpc-url $L1_RPC)
echo "   portal[$PORTAL]: $IS_PORTAL_REGISTERED"
echo ""

echo "4. Check if DisputeGameFactory is already registered:"
FACTORY=$(cast call $SYSTEM_CONFIG "disputeGameFactory()(address)" --rpc-url $L1_RPC)
echo "   disputeGameFactory: $FACTORY"
EXISTING_ROLLUP=$(cast call $L1_BRIDGE_REGISTRY "rollupConfigWithDisputeGameFactory(address)(address)" $FACTORY --rpc-url $L1_RPC)
echo "   rollupConfigWithDisputeGameFactory[$FACTORY]: $EXISTING_ROLLUP"
echo ""

echo "5. Check availableForRegistration:"
AVAILABLE=$(cast call $L1_BRIDGE_REGISTRY "availableForRegistration(address,uint8)(bool)" $SYSTEM_CONFIG 3 --rpc-url $L1_RPC)
echo "   availableForRegistration: $AVAILABLE"
echo ""

echo "6. Try to register with cast send (this should fail with RegisterError(2)):"
cast send $L1_BRIDGE_REGISTRY "registerRollupConfigByManager(address,uint8,address,string)" \
  $SYSTEM_CONFIG 3 $TON "Devnet L2" \
  --private-key $TON_STAKING_DEPLOYER_KEY --rpc-url $L1_RPC 2>&1 || echo "Failed as expected"
