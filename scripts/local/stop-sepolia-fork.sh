#!/bin/bash
# =============================================================================
# Stop TON Staking V3 Local Devnet (Sepolia Fork)
# =============================================================================
# This script stops all services and optionally performs complete cleanup
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEVNET_SEPOLIA_DIR="$PROJECT_ROOT/.devnet-sepolia-fork"

echo -e "${BLUE}=== Stopping TON Staking V3 Local Devnet (Sepolia Fork) ===${NC}"
echo ""

# =============================================================================
# Step 1: Stop L2 Containers
# =============================================================================
echo -e "${YELLOW}Step 1: Stopping L2 containers...${NC}"

# First, forcefully stop and remove all ton-staking containers
# This ensures cleanup even if docker-compose fails due to depends_on
if docker ps -a --filter "name=ton-staking" --format "{{.Names}}" | grep -q .; then
    echo "  Forcefully removing all ton-staking containers..."
    docker ps -a --filter "name=ton-staking" --format "{{.Names}}" | xargs docker rm -f 2>/dev/null || true
    echo -e "${GREEN}  ✓ Containers forcefully removed${NC}"
else
    echo "  No ton-staking containers found"
fi

# Also try docker-compose down for cleanup
for compose_file in "docker-compose.yml" "docker-compose.l2-only.yml"; do
    if [ -f "$PROJECT_ROOT/$compose_file" ]; then
        docker compose -f "$PROJECT_ROOT/$compose_file" down 2>/dev/null || true
    fi
done

echo -e "${GREEN}✓ L2 containers stopped${NC}"
echo ""

# =============================================================================
# Step 2: Stop Anvil
# =============================================================================
echo -e "${YELLOW}Step 2: Stopping Anvil and L1 miner...${NC}"

# Stop L1 manual miner loop
if [ -f /tmp/l1-miner.pid ]; then
    L1_MINER_PID=$(cat /tmp/l1-miner.pid)
    if kill -0 "$L1_MINER_PID" 2>/dev/null; then
        echo "  Killing L1 miner loop (PID: $L1_MINER_PID)..."
        kill "$L1_MINER_PID" || true
    fi
    rm -f /tmp/l1-miner.pid
    echo -e "${GREEN}✓ L1 miner stopped${NC}"
fi

if pgrep -f "anvil" > /dev/null; then
    echo "  Killing Anvil processes..."
    pkill -f "anvil" || true
    sleep 1
    echo -e "${GREEN}✓ Anvil stopped${NC}"
else
    echo "  No Anvil processes found"
fi
echo ""

# =============================================================================
# Step 3: Cleanup Options
# =============================================================================
echo -e "${YELLOW}Step 3: Cleanup options${NC}"
echo ""
echo "What would you like to clean up?"
echo "  1) Stop only (keep data)"
echo "  2) Full cleanup (remove volumes, networks, temp files) [RECOMMENDED]"
echo "  3) Full cleanup + Docker prune (reclaim space)"
echo ""
read -p "Select option [1-3] (default: 2): " CLEANUP_OPTION
CLEANUP_OPTION=${CLEANUP_OPTION:-2}

case $CLEANUP_OPTION in
    1)
        echo ""
        echo -e "${GREEN}Services stopped. Data preserved.${NC}"
        echo ""
        echo "To manually clean up data later:"
        echo "  docker volume rm ton-staking-v2_l2-execution-data local_l2-execution-data"
        echo "  docker network rm local_ton-staking-network sepolia-fork_ton-staking-network"
        echo "  rm -rf .devnet-sepolia-fork/"
        ;;
    2|3)
        echo ""
        echo -e "${YELLOW}Performing full cleanup...${NC}"

        # Remove L2 volumes
        echo "  Removing L2 volumes..."
        docker volume rm ton-staking-v2_l2-execution-data 2>/dev/null && echo "    ✓ ton-staking-v2_l2-execution-data removed" || true
        docker volume rm local_l2-execution-data 2>/dev/null && echo "    ✓ local_l2-execution-data removed" || true

        # Remove networks
        echo "  Removing networks..."
        docker network rm local_ton-staking-network 2>/dev/null && echo "    ✓ local_ton-staking-network removed" || true
        docker network rm sepolia-fork_ton-staking-network 2>/dev/null && echo "    ✓ sepolia-fork_ton-staking-network removed" || true
        docker network rm ton-staking-v2_ton-staking-network 2>/dev/null && echo "    ✓ ton-staking-v2_ton-staking-network removed" || true

        # Remove temporary directories
        echo "  Removing temporary directories..."
        if [ -d "$DEVNET_SEPOLIA_DIR" ]; then
            rm -rf "$DEVNET_SEPOLIA_DIR"
            echo "    ✓ .devnet-sepolia-fork removed"
        fi

        # Remove Anvil logs
        if [ -f "/tmp/anvil.log" ]; then
            rm -f /tmp/anvil.log
            echo "    ✓ Anvil logs removed"
        fi

        # Remove L1 miner logs
        if [ -f "/tmp/l1-miner.log" ]; then
            rm -f /tmp/l1-miner.log
            echo "    ✓ L1 miner logs removed"
        fi

        echo -e "${GREEN}✓ Full cleanup completed${NC}"

        # Docker system prune (option 3)
        if [ "$CLEANUP_OPTION" = "3" ]; then
            echo ""
            echo -e "${YELLOW}Running docker system prune...${NC}"
            RECLAIMED=$(docker system prune -f 2>&1 | grep "Total reclaimed space" || echo "Total reclaimed space: 0B")
            echo "  $RECLAIMED"
            echo -e "${GREEN}✓ Docker cleanup completed${NC}"
        fi
        ;;
    *)
        echo -e "${RED}Invalid option. Services stopped, no cleanup performed.${NC}"
        ;;
esac

# =============================================================================
# Step 4: Verification
# =============================================================================
echo ""
echo -e "${YELLOW}Step 4: Verification${NC}"

# Check containers
RUNNING_CONTAINERS=$(docker ps --filter name=ton-staking-l2 --format "{{.Names}}" | wc -l | tr -d ' ')
if [ "$RUNNING_CONTAINERS" -eq 0 ]; then
    echo -e "  ${GREEN}✓ No L2 containers running${NC}"
else
    echo -e "  ${YELLOW}⚠ Warning: $RUNNING_CONTAINERS L2 containers still running${NC}"
fi

# Check Anvil
if pgrep -f "anvil" > /dev/null; then
    echo -e "  ${YELLOW}⚠ Warning: Anvil processes still running${NC}"
else
    echo -e "  ${GREEN}✓ No Anvil processes running${NC}"
fi

# Check volumes (if cleanup was done)
if [ "$CLEANUP_OPTION" != "1" ]; then
    L2_VOLUMES=$(docker volume ls | grep -c "l2.*data" 2>/dev/null || echo "0")
    if [ "$L2_VOLUMES" -eq 0 ]; then
        echo -e "  ${GREEN}✓ All L2 volumes removed${NC}"
    else
        echo -e "  ${YELLOW}⚠ Warning: $L2_VOLUMES L2 volumes still exist${NC}"
    fi
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  TON Staking V3 Local Devnet Stopped Successfully!         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ "$CLEANUP_OPTION" = "1" ]; then
    echo -e "${BLUE}Note: Data preserved. Next start will resume from current state.${NC}"
else
    echo -e "${BLUE}Note: Full cleanup done. Next start will be fresh initialization.${NC}"
fi
echo ""
