#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OP_E2E_DIR="${OP_E2E_DIR:-"$ROOT_DIR/op-e2e"}"
TEST_NAME="${TEST_NAME:-"TestMultiChallenger_ThreeChallengersRewardDistribution"}"
TIMEOUT="${TIMEOUT:-"40m"}"

echo "[DEMO_STEP] PREPARE"
echo "[DEMO_INFO] ROOT_DIR=$ROOT_DIR"
echo "[DEMO_INFO] OP_E2E_DIR=$OP_E2E_DIR"
echo "[DEMO_INFO] TEST_NAME=$TEST_NAME"
echo "[DEMO_INFO] TIMEOUT=$TIMEOUT"
echo "[DEMO_INFO] PWD=$(pwd)"

if [ ! -d "$OP_E2E_DIR" ]; then
  echo "[DEMO_ERROR] op-e2e directory not found: $OP_E2E_DIR"
  exit 1
fi

if ! command -v go >/dev/null 2>&1; then
  echo "[DEMO_ERROR] go not found in PATH"
  exit 1
fi

GO_BIN="$(command -v go)"
if [ ! -x "$GO_BIN" ]; then
  echo "[DEMO_ERROR] go exists but is not executable: $GO_BIN"
  exit 1
fi

echo "[DEMO_INFO] go version: $($GO_BIN version)"

echo "[DEMO_STEP] GAME_CREATED"
echo "[DEMO_STEP] CHALLENGERS_STARTED"
echo "[DEMO_STEP] RUN_TEST $TEST_NAME"

set -x
(
  cd "$OP_E2E_DIR"
  go test -v -timeout "$TIMEOUT" -run "$TEST_NAME" ./slashing/...
)
