#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ABI_DIR="$ROOT_DIR/demo-config/abis"

REQUIRED_FILES=(
  "DisputeGameFactory.json"
  "FaultDisputeGame.json"
  "SeigManager.json"
  "DepositManager.json"
)

missing=()

for file in "${REQUIRED_FILES[@]}"; do
  if [ ! -s "$ABI_DIR/$file" ]; then
    missing+=("$file")
  fi
done

if [ ${#missing[@]} -eq 0 ]; then
  echo "[ensure-abis] all ABI files exist"
  exit 0
fi

echo "[ensure-abis] missing ABI files: ${missing[*]}"
echo "[ensure-abis] regenerating..."
bash "$ROOT_DIR/scripts/demo/extract-abis.sh"

missing_after=()
for file in "${REQUIRED_FILES[@]}"; do
  if [ ! -s "$ABI_DIR/$file" ]; then
    missing_after+=("$file")
  fi
done

if [ ${#missing_after[@]} -ne 0 ]; then
  echo "[ensure-abis] still missing: ${missing_after[*]}"
  exit 1
fi

echo "[ensure-abis] ABI files are ready"
