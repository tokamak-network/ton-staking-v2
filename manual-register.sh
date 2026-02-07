#!/bin/bash
set -e

L1_RPC="http://localhost:8545"
DEPLOYER_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
TON_STAKING_DEPLOYER_KEY="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"

L1_BRIDGE_REGISTRY="0x2dE080e97B0caE9825375D31f5D0eD5751fDf16D"
LAYER2_MANAGER="0xcA03Dc4665A8C3603cb4Fd5Ce71Af9649dC00d44"
TON="0xd55b55304b5cf7607B6dEd6DA6EeB487918AaD2E"
WTON="0x2B2fE3204CcB8282ac6bC31d485cB6aa010d193a"
SYSTEM_CONFIG="0x577AcB7fA48878245a854ba51eD051a5B47cF83f"

echo "=== Step 1: Register Rollup to L1BridgeRegistry ==="
cast send $L1_BRIDGE_REGISTRY "registerRollupConfigByManager(address,uint8,address,string)" \
  $SYSTEM_CONFIG 3 $TON "Devnet L2" \
  --private-key $DEPLOYER_KEY --rpc-url $L1_RPC

echo ""
echo "=== Step 2: Approve WTON to Layer2Manager ==="
cast send $WTON "approve(address,uint256)" $LAYER2_MANAGER \
  0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff \
  --private-key $DEPLOYER_KEY --rpc-url $L1_RPC

echo ""
echo "=== Step 3: Register CandidateAddOn (1001 WTON) ==="
cast send $LAYER2_MANAGER "registerCandidateAddOn(address,uint256,bool,string)" \
  $SYSTEM_CONFIG 1001000000000000000000000000000 false "Devnet Operator" \
  --private-key $DEPLOYER_KEY --rpc-url $L1_RPC

echo ""
echo "=== Registration Complete ==="
