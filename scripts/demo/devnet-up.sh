#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PID_FILE="$ROOT_DIR/.devnet/devnet.pid"
LOG_FILE="$ROOT_DIR/.devnet/devnet.log"

mkdir -p "$ROOT_DIR/.devnet"

if [ -f "$PID_FILE" ]; then
  echo "[devnet-up] devnet already running (pid: $(cat "$PID_FILE"))"
  exit 0
fi

if [ ! -f "$ROOT_DIR/.devnet/genesis-l1-staking-v3.json" ]; then
  echo "[devnet-up] genesis not found. run: make devnet-allocs-offline"
  exit 1
fi

echo "[devnet-up] starting devnet..."
(
  cd "$ROOT_DIR/op-e2e"
  go test -v -timeout 24h -run TestDevnetKeepAlive ./devnet > "$LOG_FILE" 2>&1
) &
PID=$!

echo "$PID" > "$PID_FILE"
echo "[devnet-up] pid=$PID"
echo "[devnet-up] logs=$LOG_FILE"
