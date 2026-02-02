#!/bin/bash

LOG_FILE=$1

echo ""
echo "========================================"
echo "📊 E2E Test Summary"
echo "========================================"
echo ""

# Passed tests
if grep -q "^--- PASS:" "$LOG_FILE"; then
    echo "✅ Passed Tests:"
    grep "^--- PASS:" "$LOG_FILE" | sed 's/^--- PASS: /  ✅ /'
    echo ""
fi

# Failed tests
if grep -q "^--- FAIL:" "$LOG_FILE"; then
    echo "❌ Failed Tests:"
    grep "^--- FAIL:" "$LOG_FILE" | sed 's/^--- FAIL: /  ❌ /'
    echo ""
fi

# Skipped tests with reasons
if grep -q "^--- SKIP:" "$LOG_FILE"; then
    echo "⏭️  Skipped Tests:"

    # Get test names that were skipped
    skipped_tests=$(grep "^--- SKIP:" "$LOG_FILE" | sed 's/^--- SKIP: //' | sed 's/ (.*//')

    # For each skipped test, find the reason
    echo "$skipped_tests" | while read -r test_name; do
        # Find the test and extract skip info (with time)
        skip_info=$(grep "^--- SKIP:" "$LOG_FILE" | grep "$test_name" | sed 's/^--- SKIP: //')
        echo "  ⏭️  $skip_info"

        # Look for the reason in the test output (usually between === RUN and --- SKIP)
        reason=$(awk "/^=== RUN   $test_name$/,/^--- SKIP: $test_name/" "$LOG_FILE" | \
                 grep -E "^\s+.*\.go:[0-9]+:" | tail -1 | sed 's/^[[:space:]]*//' | sed 's/^[^:]*:[^:]*: //')

        if [[ -n "$reason" ]]; then
            echo "      Reason: $reason"
        fi
    done
    echo ""
fi

# Count totals
GO_PASSED=$(grep -c "^--- PASS:" "$LOG_FILE" 2>/dev/null || echo 0)
GO_FAILED=$(grep -c "^--- FAIL:" "$LOG_FILE" 2>/dev/null || echo 0)
GO_SKIPPED=$(grep -c "^--- SKIP:" "$LOG_FILE" 2>/dev/null || echo 0)

echo "Total: $GO_PASSED passed, $GO_FAILED failed, $GO_SKIPPED skipped"
echo "========================================"
