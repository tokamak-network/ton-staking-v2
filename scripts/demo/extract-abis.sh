#!/usr/bin/env bash
set -euo pipefail

node scripts/demo/extract-abi.js DisputeGameFactory demo-config/abis/DisputeGameFactory.json
node scripts/demo/extract-abi.js FaultDisputeGame demo-config/abis/FaultDisputeGame.json
node scripts/demo/extract-abi.js SeigManager_Slashing demo-config/abis/SeigManager.json
