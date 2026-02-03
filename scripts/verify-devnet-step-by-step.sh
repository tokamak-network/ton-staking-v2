#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Wait for RPC to be ready
wait_for_rpc() {
    local rpc_url=$1
    local max_attempts=${2:-30}
    local attempt=0
    
    log_info "Waiting for RPC at $rpc_url..."
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s -X POST "$rpc_url" \
            -H "Content-Type: application/json" \
            --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
            --max-time 2 >/dev/null 2>&1; then
            log_success "RPC is ready!"
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 1
    done
    
    log_error "RPC not ready after $max_attempts seconds"
    return 1
}

# Verify chain ID
verify_chain_id() {
    local rpc_url=$1
    local expected_chain_id=$2
    local name=$3
    
    log_info "Verifying $name chain ID..."
    
    local result=$(curl -s -X POST "$rpc_url" \
        -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' | jq -r '.result')
    
    local chain_id_dec=$((result))
    
    if [ "$chain_id_dec" -eq "$expected_chain_id" ]; then
        log_success "$name Chain ID: $chain_id_dec (Expected: $expected_chain_id) ✓"
        return 0
    else
        log_error "$name Chain ID: $chain_id_dec (Expected: $expected_chain_id) ✗"
        return 1
    fi
}

# Verify block production
verify_blocks() {
    local rpc_url=$1
    local name=$2
    
    log_info "Verifying $name block production..."
    
    local block1=$(curl -s -X POST "$rpc_url" \
        -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' | jq -r '.result')
    
    local block1_dec=$((block1))
    log_info "$name current block: $block1_dec"
    
    sleep 3
    
    local block2=$(curl -s -X POST "$rpc_url" \
        -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' | jq -r '.result')
    
    local block2_dec=$((block2))
    log_info "$name current block after 3s: $block2_dec"
    
    if [ "$block2_dec" -gt "$block1_dec" ]; then
        log_success "$name is producing blocks ✓"
        return 0
    else
        log_warning "$name blocks not increasing (might be ok if just started)"
        return 0
    fi
}

# Verify contract
verify_contract() {
    local rpc_url=$1
    local address=$2
    local name=$3
    
    log_info "Verifying contract: $name at $address..."
    
    local code=$(curl -s -X POST "$rpc_url" \
        -H "Content-Type: application/json" \
        --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getCode\",\"params\":[\"$address\",\"latest\"],\"id\":1}" | jq -r '.result')
    
    if [ "$code" != "0x" ] && [ ${#code} -gt 10 ]; then
        log_success "$name deployed ✓ (code length: ${#code})"
        return 0
    else
        log_error "$name not deployed or no code at $address ✗"
        return 1
    fi
}

# Verify docker container
verify_container() {
    local container_name=$1
    
    log_info "Checking container: $container_name..."
    
    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        local status=$(docker inspect -f '{{.State.Status}}' "$container_name")
        if [ "$status" = "running" ]; then
            log_success "Container $container_name is running ✓"
            return 0
        else
            log_error "Container $container_name exists but status: $status ✗"
            return 1
        fi
    else
        log_error "Container $container_name not found ✗"
        return 1
    fi
}

# Main verification script
main() {
    echo ""
    echo "=========================================="
    echo "  TON Staking V3 Devnet Verification"
    echo "=========================================="
    echo ""
    
    # Check prerequisites
    log_info "Step 1: Checking prerequisites..."
    
    local prereq_failed=0
    
    if ! command_exists docker; then
        log_error "docker not found"
        prereq_failed=1
    else
        log_success "docker found"
    fi
    
    if ! command_exists docker-compose; then
        log_error "docker-compose not found"
        prereq_failed=1
    else
        log_success "docker-compose found"
    fi
    
    if ! command_exists curl; then
        log_error "curl not found"
        prereq_failed=1
    else
        log_success "curl found"
    fi
    
    if ! command_exists jq; then
        log_error "jq not found (install with: brew install jq)"
        prereq_failed=1
    else
        log_success "jq found"
    fi
    
    if [ $prereq_failed -eq 1 ]; then
        log_error "Prerequisites check failed"
        exit 1
    fi
    
    echo ""
    log_info "Step 2: Verifying L1 (Ethereum)..."
    
    if ! verify_container "ton-staking-l1"; then
        log_error "L1 container verification failed"
        exit 1
    fi
    
    if ! wait_for_rpc "http://localhost:8545" 30; then
        log_error "L1 RPC not responding"
        exit 1
    fi
    
    if ! verify_chain_id "http://localhost:8545" 900 "L1"; then
        log_error "L1 chain ID verification failed"
        exit 1
    fi
    
    verify_blocks "http://localhost:8545" "L1"
    
    echo ""
    log_info "Step 3: Verifying L1 contracts..."
    
    # Read contract addresses
    if [ ! -f ".devnet/addresses.json" ]; then
        log_error "Contract addresses file not found: .devnet/addresses.json"
        exit 1
    fi
    
    TON_ADDRESS=$(jq -r '.ton' .devnet/addresses.json)
    WTON_ADDRESS=$(jq -r '.wton' .devnet/addresses.json)
    SEIG_MANAGER=$(jq -r '.seigManagerProxy' .devnet/addresses.json)
    LAYER2_MANAGER=$(jq -r '.layer2ManagerProxy' .devnet/addresses.json)
    SYSTEM_CONFIG=$(jq -r '.systemConfig' .devnet/addresses.json)
    
    verify_contract "http://localhost:8545" "$TON_ADDRESS" "TON"
    verify_contract "http://localhost:8545" "$WTON_ADDRESS" "WTON"
    verify_contract "http://localhost:8545" "$SEIG_MANAGER" "SeigManager"
    verify_contract "http://localhost:8545" "$LAYER2_MANAGER" "Layer2Manager"
    verify_contract "http://localhost:8545" "$SYSTEM_CONFIG" "SystemConfig"
    
    echo ""
    log_info "Step 4: Verifying L2 Execution Layer..."
    
    if ! verify_container "ton-staking-l2-execution"; then
        log_warning "L2 execution container not running"
    else
        if ! wait_for_rpc "http://localhost:9545" 30; then
            log_warning "L2 execution RPC not responding (this might be ok if L2 is starting)"
        else
            if ! verify_chain_id "http://localhost:9545" 901 "L2"; then
                log_warning "L2 chain ID incorrect (expected 901)"
            fi
            
            verify_blocks "http://localhost:9545" "L2"
        fi
    fi
    
    echo ""
    log_info "Step 5: Verifying L2 Node (op-node)..."
    
    if ! verify_container "ton-staking-l2-node"; then
        log_warning "L2 node container not running"
    else
        if ! wait_for_rpc "http://localhost:7545" 10; then
            log_warning "L2 node RPC not responding"
        else
            log_success "L2 node RPC is responding ✓"
        fi
    fi
    
    echo ""
    log_info "Step 6: Verifying L2 Batcher..."
    
    if verify_container "ton-staking-l2-batcher"; then
        log_success "Batcher is running ✓"
    else
        log_warning "Batcher not running"
    fi
    
    echo ""
    log_info "Step 7: Verifying L2 Proposer..."
    
    if verify_container "ton-staking-l2-proposer"; then
        log_success "Proposer is running ✓"
    else
        log_warning "Proposer not running"
    fi
    
    echo ""
    log_info "Step 8: Verifying RAT Clients..."
    
    local rat_count=0
    for i in 1 2 3; do
        if verify_container "ton-staking-rat-client-$i"; then
            rat_count=$((rat_count + 1))
        fi
    done
    
    log_info "RAT clients running: $rat_count/3"
    
    echo ""
    echo "=========================================="
    echo "  Verification Summary"
    echo "=========================================="
    
    local l1_ok=0
    local l2_ok=0
    
    if docker ps | grep -q "ton-staking-l1"; then
        l1_ok=1
        log_success "✓ L1 is running (Chain ID: 900)"
    else
        log_error "✗ L1 is not running"
    fi
    
    if docker ps | grep -q "ton-staking-l2-execution"; then
        local l2_chain_id=$(curl -s -X POST "http://localhost:9545" \
            -H "Content-Type: application/json" \
            --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' 2>/dev/null | jq -r '.result' || echo "0x0")
        local l2_chain_id_dec=$((l2_chain_id))
        
        if [ "$l2_chain_id_dec" -eq 901 ]; then
            l2_ok=1
            log_success "✓ L2 is running (Chain ID: 901)"
        else
            log_warning "⚠ L2 is running but Chain ID: $l2_chain_id_dec (Expected: 901)"
        fi
    else
        log_warning "⚠ L2 is not running"
    fi
    
    echo ""
    
    if [ $l1_ok -eq 1 ]; then
        log_success "✓ L1 verification: PASSED"
    else
        log_error "✗ L1 verification: FAILED"
    fi
    
    if [ $l2_ok -eq 1 ]; then
        log_success "✓ L2 verification: PASSED"
    else
        log_warning "⚠ L2 verification: INCOMPLETE (Chain ID issue)"
    fi
    
    echo ""
    echo "Next steps:"
    echo "  - Web UI: http://localhost:5173"
    echo "  - L1 RPC: http://localhost:8545"
    echo "  - L2 RPC: http://localhost:9545"
    echo ""
    
    if [ $l1_ok -eq 1 ] && [ $l2_ok -eq 1 ]; then
        log_success "Devnet is ready! 🎉"
        exit 0
    elif [ $l1_ok -eq 1 ]; then
        log_warning "L1 is ready, but L2 has issues. You can still use L1 features."
        exit 0
    else
        log_error "Devnet has critical issues"
        exit 1
    fi
}

main "$@"
