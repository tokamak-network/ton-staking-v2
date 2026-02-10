#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PID_FILE="$ROOT_DIR/.devnet/devnet.pid"

if [ ! -f "$PID_FILE" ]; then
  echo "[devnet-down] no pid file found."
  exit 0
fi

PID="$(cat "$PID_FILE")"
echo "[devnet-down] stopping devnet pid=$PID"
kill -TERM "$PID" || true
rm -f "$PID_FILE"
