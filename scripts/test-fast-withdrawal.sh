#!/bin/bash
# Fast Withdrawal 테스트 실행 스크립트
# BLS 서명 도구 빌드 후 Foundry 테스트 실행

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== Fast Withdrawal Test Runner ===${NC}"

# 1. BLS 서명 도구 빌드
echo -e "${GREEN}[1/2] Building BLS signing tool...${NC}"
BLS_SIGN_DIR="$ROOT_DIR/clients/fast-withdrawal/validator/cmd/bls-sign"
BLS_SIGN_BIN="$ROOT_DIR/clients/fast-withdrawal/validator/bls-sign"

if [ -f "$BLS_SIGN_DIR/main.go" ]; then
    cd "$BLS_SIGN_DIR"
    go build -o "$BLS_SIGN_BIN" .
    echo "  Built: $BLS_SIGN_BIN"
else
    echo "  Error: BLS sign source not found at $BLS_SIGN_DIR"
    exit 1
fi

# 2. Foundry 테스트 실행
echo -e "${GREEN}[2/2] Running Fast Withdrawal E2E tests...${NC}"
cd "$ROOT_DIR"

# FFI 활성화하여 테스트 실행
forge test --match-contract FastWithdrawalE2ETest -vvv --ffi "$@"

echo -e "${GREEN}=== Tests completed ===${NC}"
