#!/bin/bash
# =============================================================================
# Build Docker Images for TON Staking V3 Local Devnet
# =============================================================================
# Run this script BEFORE start-dev-fw.sh to pre-build all Docker images.
# Docker image builds (especially Go compilation for FW nodes) are memory-intensive
# and can cause OOM kills if run concurrently with Anvil and L2 services.
#
# Usage:
#   ./scripts/local/build-docker-images.sh          # Build all images
#   ./scripts/local/build-docker-images.sh --force   # Rebuild all (no cache)
#   ./scripts/local/build-docker-images.sh fw        # Build FW nodes only
#   ./scripts/local/build-docker-images.sh rat       # Build RAT clients only
#   ./scripts/local/build-docker-images.sh l2        # Build L2 services only
# =============================================================================

set -eo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.l2-only.yml"

NO_CACHE=""
BUILD_TARGET="${1:-all}"

if [ "$1" = "--force" ]; then
    NO_CACHE="--no-cache"
    BUILD_TARGET="${2:-all}"
    echo -e "${YELLOW}Force rebuild mode (no cache)${NC}"
fi

if [ "$2" = "--force" ]; then
    NO_CACHE="--no-cache"
    echo -e "${YELLOW}Force rebuild mode (no cache)${NC}"
fi

echo -e "${BLUE}=== Building Docker Images for TON Staking V3 Devnet ===${NC}"
echo ""

build_l2() {
    echo -e "${YELLOW}Building L2 service images (l2-execution, l2-node, l2-batcher, l2-proposer)...${NC}"
    docker compose -f "$COMPOSE_FILE" build $NO_CACHE l2-execution l2-node l2-batcher l2-proposer
    echo -e "${GREEN}  L2 service images ready${NC}"
    echo ""
}

build_rat() {
    echo -e "${YELLOW}Building RAT client images (rat-client-1, rat-client-2, rat-client-3)...${NC}"
    docker compose -f "$COMPOSE_FILE" build $NO_CACHE rat-client-1 rat-client-2 rat-client-3
    echo -e "${GREEN}  RAT client images ready${NC}"
    echo ""
}

build_fw() {
    echo -e "${YELLOW}Building Fast Withdrawal node images (fw-node-1, fw-node-2, fw-node-3)...${NC}"
    echo "  This includes Go compilation and may take a few minutes."
    docker compose -f "$COMPOSE_FILE" build $NO_CACHE fw-node-1 fw-node-2 fw-node-3
    echo -e "${GREEN}  FW node images ready${NC}"
    echo ""
}

case "$BUILD_TARGET" in
    all)
        build_l2
        build_rat
        build_fw
        ;;
    l2)
        build_l2
        ;;
    rat)
        build_rat
        ;;
    fw)
        build_fw
        ;;
    *)
        echo -e "${RED}Unknown target: $BUILD_TARGET${NC}"
        echo "Usage: $0 [all|l2|rat|fw] [--force]"
        exit 1
        ;;
esac

echo -e "${GREEN}=== All requested Docker images built successfully ===${NC}"
echo ""
echo "You can now run: ./scripts/local/start-dev-fw.sh"
