.PHONY: all build test clean help
.PHONY: devnet-allocs devnet-allocs-optimism devnet-up devnet-down devnet-clean devnet-status
.PHONY: test-e2e test-e2e-unit test-e2e-integration

# Default target
all: build

# Build contracts
build:
	forge build

# Run all Solidity tests
test:
	forge test

# Run V3 tests only
test-v3:
	forge test --match-path "test/v3/*.sol"

# Clean build artifacts
clean:
	forge clean
	rm -rf cache out

# ==========================================
# Devnet Commands (for E2E testing)
# ==========================================
# Single-terminal setup (like Asterisc):
#   make devnet-allocs   # Generate allocs + start L1 + deploy RAT
#   make test-e2e        # Run E2E tests
#   make devnet-down     # Stop L1
# ==========================================

OPTIMISM_DIR := lib/optimism

# Generate lib/optimism devnet allocs (prerequisite)
devnet-allocs-optimism:
	@echo "=== Building lib/optimism devnet allocs ==="
	@if [ ! -f $(OPTIMISM_DIR)/packages/contracts-bedrock/forge-artifacts/DisputeGameFactory.sol/DisputeGameFactory.json ]; then \
		echo "Building Optimism contracts (first time)..."; \
		cd $(OPTIMISM_DIR) && just forge-build; \
	fi
	@echo "Generating devnet allocs..."
	cd $(OPTIMISM_DIR) && just devnet-allocs

# Full devnet setup: generate allocs + start L1 + deploy RAT
devnet-allocs: devnet-allocs-optimism
	@echo ""
	@echo "=== Setting up TON Staking V3 Devnet ==="
	./scripts/devnet-allocs.sh

# Start L1 devnet (if not running)
devnet-up:
	@if curl -s http://localhost:8545 > /dev/null 2>&1; then \
		echo "L1 devnet already running on localhost:8545"; \
	else \
		echo "Starting L1 devnet..."; \
		./scripts/devnet-up.sh; \
	fi

# Stop L1 devnet
devnet-down:
	@echo "Stopping L1 devnet..."
	@-pkill -f "anvil.*8545" 2>/dev/null || true
	@rm -f .devnet/anvil.pid
	@echo "L1 devnet stopped"

# Clean all devnet state
devnet-clean: devnet-down
	@echo "Cleaning devnet state..."
	@rm -rf .devnet
	@echo "Cleaning lib/optimism devnet state..."
	@rm -rf $(OPTIMISM_DIR)/.devnet
	@echo "Devnet cleaned"

# Show devnet status
devnet-status:
	@echo "=== Devnet Status ==="
	@echo ""
	@echo "L1 RPC (localhost:8545):"
	@if curl -s -X POST -H "Content-Type: application/json" \
		--data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
		http://localhost:8545 2>/dev/null | grep -q "0x384"; then \
		echo "  ✓ Running (Chain ID: 900)"; \
	else \
		echo "  ✗ Not running"; \
	fi
	@echo ""
	@echo "RAT Deployment:"
	@if [ -f .devnet/addresses.json ]; then \
		echo "  ✓ Deployed"; \
		echo "  RAT: $$(jq -r '.rat' .devnet/addresses.json 2>/dev/null || echo 'N/A')"; \
		echo "  DisputeGameFactory: $$(jq -r '.disputeGameFactory' .devnet/addresses.json 2>/dev/null || echo 'N/A')"; \
	else \
		echo "  ✗ Not deployed"; \
	fi

# ==========================================
# E2E Test Commands
# ==========================================

# Run all E2E tests (requires devnet-allocs first)
test-e2e:
	@if [ ! -f .devnet/addresses.json ]; then \
		echo "Error: Devnet not set up. Run 'make devnet-allocs' first."; \
		exit 1; \
	fi
	@if ! curl -s http://localhost:8545 > /dev/null 2>&1; then \
		echo "Error: L1 devnet not running. Run 'make devnet-up' first."; \
		exit 1; \
	fi
	@echo "Running E2E tests..."
	cd op-e2e && go test -v ./faultproofs/... -timeout 300s

# Run E2E unit tests only (no devnet required)
test-e2e-unit:
	cd op-e2e && go test -v -run "TestRATHelper|TestRATConstants" ./faultproofs/...

# Run E2E integration tests (requires devnet-allocs first)
test-e2e-integration:
	@if [ ! -f .devnet/addresses.json ]; then \
		echo "Error: Devnet not set up. Run 'make devnet-allocs' first."; \
		exit 1; \
	fi
	cd op-e2e && go test -v -run "TestRATIntegration" ./faultproofs/... -timeout 300s

# ==========================================
# Help
# ==========================================

help:
	@echo "TON Staking V3 Build Commands"
	@echo ""
	@echo "Build & Test:"
	@echo "  make build              Build Solidity contracts"
	@echo "  make test               Run all Solidity tests"
	@echo "  make test-v3            Run V3 tests only"
	@echo "  make clean              Clean build artifacts"
	@echo ""
	@echo "E2E Testing (Single Terminal - like Asterisc):"
	@echo ""
	@echo "  Quick Start:"
	@echo "    make devnet-allocs    # Set up devnet (build + start L1 + deploy RAT)"
	@echo "    make test-e2e         # Run E2E tests"
	@echo "    make devnet-down      # Stop L1 when done"
	@echo ""
	@echo "  Full Cleanup:"
	@echo "    make devnet-clean     # Stop L1 + clean all state"
	@echo ""
	@echo "Devnet Management:"
	@echo "  make devnet-allocs      Set up complete devnet environment"
	@echo "  make devnet-up          Start L1 devnet (if stopped)"
	@echo "  make devnet-down        Stop L1 devnet"
	@echo "  make devnet-clean       Stop L1 + clean all devnet state"
	@echo "  make devnet-status      Show devnet status"
	@echo ""
	@echo "Test Commands:"
	@echo "  make test-e2e           Run all E2E tests"
	@echo "  make test-e2e-unit      Run E2E unit tests (no devnet)"
	@echo "  make test-e2e-integration  Run E2E integration tests"
