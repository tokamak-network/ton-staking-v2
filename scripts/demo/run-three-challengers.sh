#!/usr/bin/env bash
set -euo pipefail

export TEST_NAME="TestMultiChallenger_ThreeChallengersRewardDistribution"
export SCENARIO_LABEL="three-challengers"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/run-multi-challenger.sh"
