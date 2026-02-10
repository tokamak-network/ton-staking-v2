#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

echo "[setup] compiling contracts..."
npx hardhat compile

echo "[setup] extracting abis..."
bash scripts/demo/extract-abis.sh

echo "[setup] done."
