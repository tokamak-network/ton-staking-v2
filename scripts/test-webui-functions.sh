#!/bin/bash
# =============================================================================
# Web UI 전체 기능 테스트 스크립트
# Web UI의 모든 버튼/인터페이스 기능을 CLI로 재현하여 테스트
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ADDRESSES_FILE="$PROJECT_ROOT/.devnet/addresses.json"
RPC_URL="http://localhost:8545"
L2_RPC_URL="http://localhost:9545"

# Load addresses
TON=$(jq -r '.ton' $ADDRESSES_FILE)
WTON=$(jq -r '.wton' $ADDRESSES_FILE)
SEIG_MANAGER=$(jq -r '.seigManagerProxy' $ADDRESSES_FILE)
DEPOSIT_MANAGER=$(jq -r '.depositManagerProxy' $ADDRESSES_FILE)
LAYER2_MANAGER=$(jq -r '.layer2ManagerProxy' $ADDRESSES_FILE)
L1_BRIDGE_REGISTRY=$(jq -r '.l1BridgeRegistryProxy' $ADDRESSES_FILE)
LAYER2_REGISTRY=$(jq -r '.layer2RegistryProxy' $ADDRESSES_FILE)
RAT=$(jq -r '.ratProxy' $ADDRESSES_FILE)
SYSTEM_CONFIG=$(jq -r '.systemConfig' $ADDRESSES_FILE)

# Test account (Validator #1)
TEST_ACCOUNT="0x90F79bf6EB2c4f870365E785982E1f101E93b906"
TEST_KEY="0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Web UI 전체 기능 테스트 (CLI 시뮬레이션)              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}테스트 계정: ${NC}$TEST_ACCOUNT"
echo ""

# Helper function
test_function() {
    local test_name="$1"
    local command="$2"
    
    ((TOTAL_TESTS++))
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}테스트 $TOTAL_TESTS: $test_name${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if eval "$command"; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((PASSED_TESTS++))
    else
        echo -e "${RED}❌ FAIL${NC}"
        ((FAILED_TESTS++))
    fi
    echo ""
}

# ============================================================================
# 1. BALANCES 탭 - Faucet 기능 테스트
# ============================================================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   1. BALANCES 탭 - Faucet 기능 테스트${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Test 1-1: Get 100 ETH
test_function "Faucet - Get 100 ETH" '
    DEPLOYER="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    DEPLOYER_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
    
    echo "송금 전 잔액:"
    BEFORE=$(cast balance $TEST_ACCOUNT --rpc-url $RPC_URL)
    echo "  Before: $(cast from-wei $BEFORE) ETH"
    
    # Send 100 ETH
    cast send $TEST_ACCOUNT \
        --value 100ether \
        --private-key $DEPLOYER_KEY \
        --rpc-url $RPC_URL \
        --legacy > /dev/null 2>&1
    
    sleep 2
    
    AFTER=$(cast balance $TEST_ACCOUNT --rpc-url $RPC_URL)
    echo "  After: $(cast from-wei $AFTER) ETH"
    
    # Check if balance increased
    python3 -c "
import sys
before = int(\"$BEFORE\")
after = int(\"$AFTER\")
if after > before:
    print(\"  ✓ 잔액 증가: +100 ETH\")
    sys.exit(0)
else:
    print(\"  ✗ 잔액 증가 없음\")
    sys.exit(1)
"
'

# Test 1-2: Get 10,000 TON (mint function)
test_function "Faucet - Get 10,000 TON" '
    echo "Mint 전 잔액:"
    BEFORE=$(cast call $TON "balanceOf(address)(uint256)" $TEST_ACCOUNT --rpc-url $RPC_URL | tr -d " ")
    echo "  Before: $BEFORE wei"
    
    # Check if TON has mint function
    HAS_MINT=$(cast interface $TON --rpc-url $RPC_URL 2>&1 | grep -c "function mint" || echo "0")
    
    if [ "$HAS_MINT" -eq "0" ]; then
        echo "  ⚠️  TON 컨트랙트에 mint 함수가 없습니다"
        echo "  → Web UI Faucet 버튼이 작동하지 않을 수 있습니다"
        exit 1
    fi
    
    # Try to mint
    AMOUNT="10000000000000000000000"  # 10,000 TON (18 decimals)
    
    cast send $TON \
        "mint(address,uint256)" \
        $TEST_ACCOUNT \
        $AMOUNT \
        --private-key $TEST_KEY \
        --rpc-url $RPC_URL \
        --legacy > /dev/null 2>&1 || {
        echo "  ⚠️  Mint 실패 - 권한이 없거나 함수가 다를 수 있습니다"
        exit 1
    }
    
    sleep 2
    
    AFTER=$(cast call $TON "balanceOf(address)(uint256)" $TEST_ACCOUNT --rpc-url $RPC_URL | tr -d " ")
    echo "  After: $AFTER wei"
    
    python3 -c "
import sys
before = int(\"$BEFORE\") if \"$BEFORE\" and \"$BEFORE\" != \"0x\" else 0
after = int(\"$AFTER\") if \"$AFTER\" and \"$AFTER\" != \"0x\" else 0
if after > before:
    print(\"  ✓ TON 발행 성공\")
    sys.exit(0)
else:
    print(\"  ✗ TON 발행 실패\")
    sys.exit(1)
"
'

# Test 1-3: Get 10,000 WTON (mint function)
test_function "Faucet - Get 10,000 WTON" '
    echo "Mint 전 잔액:"
    BEFORE=$(cast call $WTON "balanceOf(address)(uint256)" $TEST_ACCOUNT --rpc-url $RPC_URL | tr -d " ")
    echo "  Before: $BEFORE wei"
    
    # Check if WTON has mint function
    HAS_MINT=$(cast interface $WTON --rpc-url $RPC_URL 2>&1 | grep -c "function mint" || echo "0")
    
    if [ "$HAS_MINT" -eq "0" ]; then
        echo "  ⚠️  WTON 컨트랙트에 mint 함수가 없습니다"
        exit 1
    fi
    
    # Try to mint (27 decimals)
    AMOUNT="10000000000000000000000000000000"  # 10,000 WTON (27 decimals)
    
    cast send $WTON \
        "mint(address,uint256)" \
        $TEST_ACCOUNT \
        $AMOUNT \
        --private-key $TEST_KEY \
        --rpc-url $RPC_URL \
        --legacy > /dev/null 2>&1 || {
        echo "  ⚠️  Mint 실패"
        exit 1
    }
    
    sleep 2
    
    AFTER=$(cast call $WTON "balanceOf(address)(uint256)" $TEST_ACCOUNT --rpc-url $RPC_URL | tr -d " ")
    echo "  After: $AFTER wei"
    
    python3 -c "
import sys
before = int(\"$BEFORE\") if \"$BEFORE\" and \"$BEFORE\" != \"0x\" else 0
after = int(\"$AFTER\") if \"$AFTER\" and \"$AFTER\" != \"0x\" else 0
if after > before:
    print(\"  ✓ WTON 발행 성공\")
    sys.exit(0)
else:
    print(\"  ✗ WTON 발행 실패\")
    sys.exit(1)
"
'

# ============================================================================
# 2. BALANCES 탭 - Token Swap 테스트
# ============================================================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   2. BALANCES 탭 - Token Swap 테스트${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Test 2-1: TON to WTON swap
test_function "Token Swap - TON to WTON" '
    # Check current balances
    TON_BEFORE=$(cast call $TON "balanceOf(address)(uint256)" $TEST_ACCOUNT --rpc-url $RPC_URL | tr -d " ")
    WTON_BEFORE=$(cast call $WTON "balanceOf(address)(uint256)" $TEST_ACCOUNT --rpc-url $RPC_URL | tr -d " ")
    
    echo "  TON Before: $TON_BEFORE wei"
    echo "  WTON Before: $WTON_BEFORE wei"
    
    # Skip if no TON
    if [ "$TON_BEFORE" == "0" ] || [ -z "$TON_BEFORE" ]; then
        echo "  ⚠️  TON 잔액이 없어서 스왑 불가"
        exit 1
    fi
    
    SWAP_AMOUNT="1000000000000000000"  # 1 TON
    
    # Approve TON
    cast send $TON \
        "approve(address,uint256)" \
        $WTON \
        $SWAP_AMOUNT \
        --private-key $TEST_KEY \
        --rpc-url $RPC_URL \
        --legacy > /dev/null 2>&1
    
    sleep 1
    
    # Swap TON to WTON
    cast send $WTON \
        "swapFromTON(uint256)" \
        $SWAP_AMOUNT \
        --private-key $TEST_KEY \
        --rpc-url $RPC_URL \
        --legacy > /dev/null 2>&1 || {
        echo "  ⚠️  Swap 실패"
        exit 1
    }
    
    sleep 2
    
    TON_AFTER=$(cast call $TON "balanceOf(address)(uint256)" $TEST_ACCOUNT --rpc-url $RPC_URL | tr -d " ")
    WTON_AFTER=$(cast call $WTON "balanceOf(address)(uint256)" $TEST_ACCOUNT --rpc-url $RPC_URL | tr -d " ")
    
    echo "  TON After: $TON_AFTER wei"
    echo "  WTON After: $WTON_AFTER wei"
    
    python3 -c "
import sys
ton_before = int(\"$TON_BEFORE\")
ton_after = int(\"$TON_AFTER\")
wton_before = int(\"$WTON_BEFORE\") if \"$WTON_BEFORE\" else 0
wton_after = int(\"$WTON_AFTER\")
if ton_after < ton_before and wton_after > wton_before:
    print(\"  ✓ Swap 성공: TON 감소, WTON 증가\")
    sys.exit(0)
else:
    print(\"  ✗ Swap 실패\")
    sys.exit(1)
"
'

# ============================================================================
# 3. TON STAKING 탭 - Deposit 테스트
# ============================================================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   3. TON STAKING 탭 - Deposit 테스트${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Get CandidateAddOn
CONFIG_INFO=$(cast call $LAYER2_MANAGER "rollupConfigInfo(address)(uint8,address)" $SYSTEM_CONFIG --rpc-url $RPC_URL)
OPERATOR_MANAGER=$(echo "$CONFIG_INFO" | sed -n "2p" | tr -d " ")

if [ "$OPERATOR_MANAGER" != "0x0000000000000000000000000000000000000000" ]; then
    CANDIDATE_ADDON=$(cast call $LAYER2_MANAGER "candidateAddOnOfOperator(address)(address)" $OPERATOR_MANAGER --rpc-url $RPC_URL | tr -d " ")
    
    # Test 3-1: Deposit (Stake) WTON
    test_function "TON Staking - Deposit WTON" "
        echo \"  CandidateAddOn: $CANDIDATE_ADDON\"
        
        # Check WTON balance
        WTON_BAL=\$(cast call $WTON \"balanceOf(address)(uint256)\" $TEST_ACCOUNT --rpc-url $RPC_URL | tr -d \" \")
        echo \"  WTON Balance: \$WTON_BAL wei\"
        
        if [ \"\$WTON_BAL\" == \"0\" ] || [ -z \"\$WTON_BAL\" ]; then
            echo \"  ⚠️  WTON 잔액이 없어서 Stake 불가\"
            exit 1
        fi
        
        STAKE_AMOUNT=\"100000000000000000000000000000\"  # 100 WTON (27 decimals)
        
        # Check stake before
        STAKE_BEFORE=\$(cast call $SEIG_MANAGER \"stakeOf(address,address)(uint256)\" $CANDIDATE_ADDON $TEST_ACCOUNT --rpc-url $RPC_URL | tr -d \" \")
        echo \"  Stake Before: \$STAKE_BEFORE wei\"
        
        # Approve WTON
        cast send $WTON \
            \"approve(address,uint256)\" \
            $DEPOSIT_MANAGER \
            \$STAKE_AMOUNT \
            --private-key $TEST_KEY \
            --rpc-url $RPC_URL \
            --legacy > /dev/null 2>&1
        
        sleep 1
        
        # Deposit
        cast send $DEPOSIT_MANAGER \
            \"deposit(address,uint256)\" \
            $CANDIDATE_ADDON \
            \$STAKE_AMOUNT \
            --private-key $TEST_KEY \
            --rpc-url $RPC_URL \
            --legacy > /dev/null 2>&1 || {
            echo \"  ⚠️  Deposit 실패\"
            exit 1
        }
        
        sleep 2
        
        STAKE_AFTER=\$(cast call $SEIG_MANAGER \"stakeOf(address,address)(uint256)\" $CANDIDATE_ADDON $TEST_ACCOUNT --rpc-url $RPC_URL | tr -d \" \")
        echo \"  Stake After: \$STAKE_AFTER wei\"
        
        python3 -c \"
import sys
before = int('\$STAKE_BEFORE') if '\$STAKE_BEFORE' else 0
after = int('\$STAKE_AFTER')
if after > before:
    print('  ✓ Deposit 성공')
    sys.exit(0)
else:
    print('  ✗ Deposit 실패')
    sys.exit(1)
\"
    "
else
    echo -e "${YELLOW}⚠️  Operator가 등록되지 않아 Staking 테스트를 건너뜁니다${NC}"
    echo ""
fi

# ============================================================================
# Summary
# ============================================================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   테스트 결과 요약${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "총 테스트: $TOTAL_TESTS"
echo -e "${GREEN}통과: $PASSED_TESTS${NC}"
echo -e "${RED}실패: $FAILED_TESTS${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                          ║${NC}"
    echo -e "${GREEN}║          ✅  모든 테스트 통과! ✅                        ║${NC}"
    echo -e "${GREEN}║                                                          ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    exit 0
else
    echo -e "${RED}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                                                          ║${NC}"
    echo -e "${RED}║          ❌  일부 테스트 실패 ❌                         ║${NC}"
    echo -e "${RED}║                                                          ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "실패한 기능을 확인하고 수정이 필요합니다."
    exit 1
fi
