#!/usr/bin/env bash
set -euo pipefail

export TEST_NAME="TestMultiChallenger_TwoChallengersCompeting"
export SCENARIO_LABEL="two-challengers"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$SCRIPT_DIR/run-multi-challenger.sh"
