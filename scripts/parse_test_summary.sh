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

    # Process skip messages
    grep -n "^--- SKIP:" "$LOG_FILE" | while IFS=: read -r line_num skip_line; do
        # Print the skip line
        echo "$skip_line" | sed 's/^--- SKIP: /  ⏭️  /'

        # Get the next line (reason)
        next_line=$((line_num + 1))
        reason=$(sed -n "${next_line}p" "$LOG_FILE")

        # Only print if it's not another test marker and not empty
        if [[ ! "$reason" =~ ^--- ]] && [[ -n "$reason" ]]; then
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
