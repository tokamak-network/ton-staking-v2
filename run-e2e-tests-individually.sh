#!/bin/bash
# Individual E2E Test Runner with Logging
# Usage:
#   ./run-e2e-tests-individually.sh          # Run all tests
#   ./run-e2e-tests-individually.sh 7        # Run test at index 7
#   ./run-e2e-tests-individually.sh 3 5      # Run tests at indices 3 and 5

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Create log directory
LOG_DIR="test-logs"
mkdir -p "$LOG_DIR"

# Timestamp for log files
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Check genesis file
if [ ! -f ".devnet/genesis-l1-staking-v3.json" ]; then
    echo -e "${RED}Error: Genesis file not found${NC}"
    echo "Run: make devnet-allocs-offline"
    exit 1
fi

# Test definitions (1-indexed for user convenience)
# Format: "TestName|Description"
TESTS=(
    "TestTONStakingSystemStartup|System Startup Verification"
    "TestAccountBalances|Account Balance Verification"
    "TestRATContractCall|RAT Contract Call Test"
    "TestSimpleRAT_ValidatorRegistration|Validator Registration Flow"
    "TestSimpleRAT_GameCreation|DisputeGame Creation & RAT Trigger"
    "TestSimpleRAT_EvidenceSubmission|Evidence Submission Flow"
    "TestSimpleRAT_ChallengerWins|Full Challenger Wins Scenario"
)

TOTAL=${#TESTS[@]}

# Parse command line arguments
if [ $# -eq 0 ]; then
    # No arguments - run all tests
    TEST_INDICES=($(seq 1 $TOTAL))
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}TON Staking V3 E2E Tests (All)${NC}"
    echo -e "${BLUE}========================================${NC}"
else
    # Arguments provided - validate and use them
    TEST_INDICES=()
    for arg in "$@"; do
        if ! [[ "$arg" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}Error: Invalid index '$arg' (must be a number)${NC}"
            exit 1
        fi
        if [ "$arg" -lt 1 ] || [ "$arg" -gt $TOTAL ]; then
            echo -e "${RED}Error: Index $arg out of range (valid: 1-$TOTAL)${NC}"
            exit 1
        fi
        TEST_INDICES+=("$arg")
    done
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}TON Staking V3 E2E Tests (Selected)${NC}"
    echo -e "${BLUE}========================================${NC}"
fi

echo ""
echo -e "Log directory: ${YELLOW}$LOG_DIR${NC}"
echo -e "Timestamp: ${YELLOW}$TIMESTAMP${NC}"
echo -e "Tests to run: ${YELLOW}${TEST_INDICES[@]}${NC}"
echo ""

# List available tests
echo -e "${BLUE}Available tests:${NC}"
for i in "${!TESTS[@]}"; do
    idx=$((i + 1))
    IFS='|' read -r TEST_NAME TEST_DESC <<< "${TESTS[$i]}"
    if [[ " ${TEST_INDICES[@]} " =~ " ${idx} " ]]; then
        echo -e "  ${GREEN}[$idx]${NC} $TEST_NAME - $TEST_DESC"
    else
        echo -e "  [$idx] $TEST_NAME - $TEST_DESC"
    fi
done
echo ""

# Counter for passed/failed tests
PASSED=0
FAILED=0

# Run selected tests
for test_idx in "${TEST_INDICES[@]}"; do
    array_idx=$((test_idx - 1))
    test_entry="${TESTS[$array_idx]}"
    IFS='|' read -r TEST_NAME TEST_DESC <<< "$test_entry"

    LOG_FILE="$LOG_DIR/${TEST_NAME}_${TIMESTAMP}.log"

    echo -e "${BLUE}========================================${NC}"
    echo -e "${YELLOW}Running:${NC} $TEST_NAME"
    echo -e "${YELLOW}Description:${NC} $TEST_DESC"
    echo -e "${YELLOW}Log file:${NC} $LOG_FILE"
    echo ""

    # Run test and capture output
    # Use PIPESTATUS to check go test exit code, not tee exit code
    # -count=1 disables test caching
    cd op-e2e
    GOWORK=off go test -v -count=1 -run "^${TEST_NAME}$" ./faultproofs -timeout 60s 2>&1 | tee "../$LOG_FILE"
    TEST_EXIT_CODE=${PIPESTATUS[0]}
    cd ..

    if [ $TEST_EXIT_CODE -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓ PASSED:${NC} $TEST_NAME"
        ((PASSED++))
    else
        echo ""
        echo -e "${RED}✗ FAILED:${NC} $TEST_NAME (exit code: $TEST_EXIT_CODE)"
        ((FAILED++))
    fi

    echo ""
    sleep 1
done

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Total tests run: ${#TEST_INDICES[@]}"
echo -e "${GREEN}Passed: ${PASSED}${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed: ${FAILED}${NC}"
else
    echo -e "Failed: ${FAILED}"
fi
echo ""
echo -e "Log files saved in: ${YELLOW}$LOG_DIR${NC}"
echo ""

echo -e "${BLUE}Generated log files:${NC}"
ls -lh "$LOG_DIR"/*_${TIMESTAMP}.log 2>/dev/null || echo "No log files found"
echo ""

if [ $FAILED -gt 0 ]; then
    exit 1
fi

exit 0
