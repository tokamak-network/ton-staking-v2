#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: ./run-single-test.sh <test-number>"
    echo ""
    echo "Available tests:"
    echo "  1. TestTONStakingSystemStartup - System Startup (~1s)"
    echo "  2. TestAccountBalances - Account Balances (~1s)"
    echo "  3. TestRATContractCall - RAT Contract Call (~1s)"
    echo "  4. TestSimpleRAT_ValidatorRegistration - Validator Registration (~4s)"
    echo "  5. TestSimpleRAT_GameCreation - Game Creation & RAT Trigger (~6s)"
    echo "  6. TestSimpleRAT_EvidenceSubmission - Evidence Submission (~8s)"
    echo "  7. TestSimpleRAT_ChallengerWins - Full Challenger Wins (~20s)"
    echo ""
    exit 1
fi

mkdir -p test-logs
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

case $1 in
    1) TEST_NAME="TestTONStakingSystemStartup" ;;
    2) TEST_NAME="TestAccountBalances" ;;
    3) TEST_NAME="TestRATContractCall" ;;
    4) TEST_NAME="TestSimpleRAT_ValidatorRegistration" ;;
    5) TEST_NAME="TestSimpleRAT_GameCreation" ;;
    6) TEST_NAME="TestSimpleRAT_EvidenceSubmission" ;;
    7) TEST_NAME="TestSimpleRAT_ChallengerWins" ;;
    *) echo "Invalid test number. Use 1-7."; exit 1 ;;
esac

LOG_FILE="test-logs/${TEST_NAME}_${TIMESTAMP}.log"

echo "========================================="
echo "Running: $TEST_NAME"
echo "Log: $LOG_FILE"
echo "========================================="
echo ""

cd op-e2e && GOWORK=off go test -v -run "^${TEST_NAME}$" ./faultproofs -timeout 60s 2>&1 | tee "../$LOG_FILE"
