#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PID_FILE="$ROOT_DIR/.devnet/devnet.pid"
LOG_FILE="$ROOT_DIR/.devnet/devnet.log"

mkdir -p "$ROOT_DIR/.devnet"

if [ -f "$PID_FILE" ]; then
  OLD_PID="$(cat "$PID_FILE")"
  if ps -p "$OLD_PID" >/dev/null 2>&1; then
    echo "[devnet-up] devnet already running (pid: $OLD_PID)"
    exit 0
  else
    echo "[devnet-up] stale pid file found. removing."
    rm -f "$PID_FILE"
  fi
fi

: > "$LOG_FILE"

if [ ! -f "$ROOT_DIR/.devnet/genesis-l1-staking-v3.json" ]; then
  echo "[devnet-up] genesis not found. run: make devnet-allocs-offline"
  exit 1
fi

echo "[devnet-up] starting devnet..."
(
  cd "$ROOT_DIR/op-e2e"
  go test -v -count=1 -timeout 24h -run TestDevnetKeepAlive ./devnet > "$LOG_FILE" 2>&1
) &
PID=$!

echo "$PID" > "$PID_FILE"
echo "[devnet-up] pid=$PID"
echo "[devnet-up] logs=$LOG_FILE"

sleep 2

if ! ps -p "$PID" >/dev/null 2>&1; then
  echo "[devnet-up] devnet process exited early. showing log:"
  tail -n 50 "$LOG_FILE"
  rm -f "$PID_FILE"
  exit 1
fi

for i in {1..10}; do
  if bash "$ROOT_DIR/scripts/demo/update-networks-from-log.sh"; then
    break
  fi
  sleep 2
done
