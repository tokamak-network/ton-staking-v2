#!/bin/sh
# Fast Withdrawal Node Entrypoint
# Runs both validator and aggregator processes in a single container.
# All validators also act as aggregators - first to submit wins.

set -e

VALIDATOR_CONFIG="${VALIDATOR_CONFIG:-/app/validator-config.yaml}"
AGGREGATOR_CONFIG="${AGGREGATOR_CONFIG:-/app/aggregator-config.yaml}"

echo "=== Fast Withdrawal Node ==="
echo "  Validator config: $VALIDATOR_CONFIG"
echo "  Aggregator config: $AGGREGATOR_CONFIG"
echo ""

# Trap signals for graceful shutdown
cleanup() {
    echo "Shutting down..."
    kill $VALIDATOR_PID $AGGREGATOR_PID 2>/dev/null || true
    wait $VALIDATOR_PID $AGGREGATOR_PID 2>/dev/null || true
    echo "Stopped."
    exit 0
}
trap cleanup SIGTERM SIGINT

# Start validator
echo "Starting validator..."
/app/fw-validator --config "$VALIDATOR_CONFIG" &
VALIDATOR_PID=$!

# Start aggregator
echo "Starting aggregator..."
/app/fw-aggregator --config "$AGGREGATOR_CONFIG" &
AGGREGATOR_PID=$!

# Wait for either process to exit
wait -n $VALIDATOR_PID $AGGREGATOR_PID 2>/dev/null || true
EXIT_CODE=$?

echo "A process exited with code $EXIT_CODE, shutting down..."
cleanup
