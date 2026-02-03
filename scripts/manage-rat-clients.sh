#!/bin/bash
# =============================================================================
# Manage RAT Clients
# =============================================================================
# Usage:
#   ./scripts/manage-rat-clients.sh start [1|2|3|all]
#   ./scripts/manage-rat-clients.sh stop [1|2|3|all]
#   ./scripts/manage-rat-clients.sh status
#   ./scripts/manage-rat-clients.sh logs [1|2|3]
# =============================================================================

set -eo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Function to show usage
show_usage() {
    echo "Usage:"
    echo "  $0 start [1|2|3|all]    Start RAT client(s)"
    echo "  $0 stop [1|2|3|all]     Stop RAT client(s)"
    echo "  $0 restart [1|2|3|all]  Restart RAT client(s)"
    echo "  $0 status               Show status of all RAT clients"
    echo "  $0 logs [1|2|3]         Show logs for specific RAT client"
    echo ""
    echo "Examples:"
    echo "  $0 start all            Start all 3 RAT clients"
    echo "  $0 start 1              Start only RAT client #1"
    echo "  $0 stop 2               Stop only RAT client #2"
    echo "  $0 logs 1               Show logs for RAT client #1"
    exit 1
}

# Function to get service name
get_service_name() {
    local num=$1
    if [ "$num" == "all" ]; then
        echo "rat-client-1 rat-client-2 rat-client-3"
    else
        echo "rat-client-$num"
    fi
}

# Function to start RAT clients
start_clients() {
    local target=${1:-all}
    local services=$(get_service_name "$target")
    
    echo -e "${BLUE}=== Starting RAT Client(s) ===${NC}"
    echo ""
    
    # Check if devnet is running
    if ! docker ps | grep -q "ton-staking-l1"; then
        echo -e "${RED}Error: Devnet is not running${NC}"
        echo "Start devnet first with: make devnet-start"
        exit 1
    fi
    
    echo -e "${YELLOW}Building and starting: $services${NC}"
    docker-compose up -d --build $services
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓ RAT client(s) started${NC}"
        echo ""
        sleep 2
        show_status
    else
        echo -e "${RED}Failed to start RAT client(s)${NC}"
        exit 1
    fi
}

# Function to stop RAT clients
stop_clients() {
    local target=${1:-all}
    local services=$(get_service_name "$target")
    
    echo -e "${BLUE}=== Stopping RAT Client(s) ===${NC}"
    echo ""
    
    echo -e "${YELLOW}Stopping: $services${NC}"
    docker-compose stop $services
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓ RAT client(s) stopped${NC}"
    else
        echo -e "${RED}Failed to stop RAT client(s)${NC}"
        exit 1
    fi
}

# Function to restart RAT clients
restart_clients() {
    local target=${1:-all}
    stop_clients "$target"
    sleep 2
    start_clients "$target"
}

# Function to show status
show_status() {
    echo -e "${BLUE}=== RAT Client Status ===${NC}"
    echo ""
    
    docker-compose ps rat-client-1 rat-client-2 rat-client-3
    
    echo ""
    echo -e "${BLUE}Validator Accounts:${NC}"
    echo "  RAT Client #1: 0x90F79bf6EB2c4f870365E785982E1f101E93b906 (Account #2)"
    echo "  RAT Client #2: 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65 (Account #3)"
    echo "  RAT Client #3: 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc (Account #4)"
}

# Function to show logs
show_logs() {
    local num=${1:-1}
    
    if [ -z "$num" ] || [ "$num" -lt 1 ] || [ "$num" -gt 3 ]; then
        echo -e "${RED}Invalid client number. Use 1, 2, or 3${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}=== RAT Client #$num Logs ===${NC}"
    echo ""
    docker-compose logs -f rat-client-$num
}

# Main command handling
case "${1:-}" in
    start)
        start_clients "${2:-all}"
        ;;
    stop)
        stop_clients "${2:-all}"
        ;;
    restart)
        restart_clients "${2:-all}"
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "${2:-1}"
        ;;
    *)
        show_usage
        ;;
esac
