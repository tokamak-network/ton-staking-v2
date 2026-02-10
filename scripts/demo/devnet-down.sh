#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PID_FILE="$ROOT_DIR/.devnet/devnet.pid"

if [ -f "$PID_FILE" ]; then
  PID="$(cat "$PID_FILE")"
  echo "[devnet-down] stopping devnet pid=$PID"
  kill -TERM "$PID" || true
  rm -f "$PID_FILE"
  exit 0
fi

echo "[devnet-down] pid file not found. searching devnet process..."

PIDS=$(ps aux | grep TestDevnetKeepAlive | grep -v grep | awk '{print $2}')
if [ -n "$PIDS" ]; then
  echo "[devnet-down] found TestDevnetKeepAlive pids: $PIDS"
  for pid in $PIDS; do
    kill -TERM "$pid" || true
  done
  exit 0
fi

PIDS=$(lsof -iTCP -sTCP:LISTEN | grep devnet.te | awk '{print $2}' | sort -u)
if [ -n "$PIDS" ]; then
  echo "[devnet-down] found devnet.te pids: $PIDS"
  for pid in $PIDS; do
    kill -TERM "$pid" || true
  done
  exit 0
fi

echo "[devnet-down] no devnet process found."
