.PHONY: all build test clean devnet-allocs devnet-clean devnet-up devnet-down test-e2e test-e2e-unit test-e2e-integration help

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

# Create devnet allocations (deploy contracts to local Anvil)
devnet-allocs: devnet-clean
	@echo "=== Setting up devnet for E2E tests ==="
	@mkdir -p .devnet
	@./scripts/devnet-allocs.sh
	@echo "=== Devnet setup complete ==="
	@echo "Run 'make test-e2e' to execute E2E tests"

# Clean devnet state
devnet-clean:
	@echo "Cleaning devnet state..."
	@rm -rf .devnet
	@-pkill -f "anvil.*31337" 2>/dev/null || true
	@echo "Devnet cleaned"

# Start devnet (Anvil in background)
devnet-up:
	@if [ -f .devnet/anvil.pid ]; then \
		echo "Devnet already running (PID: $$(cat .devnet/anvil.pid))"; \
	else \
		mkdir -p .devnet; \
		anvil --chain-id 31337 --port 8545 --block-time 1 > .devnet/anvil.log 2>&1 & \
		echo $$! > .devnet/anvil.pid; \
		sleep 2; \
		echo "Devnet started (PID: $$(cat .devnet/anvil.pid))"; \
	fi

# Stop devnet
devnet-down:
	@if [ -f .devnet/anvil.pid ]; then \
		kill $$(cat .devnet/anvil.pid) 2>/dev/null || true; \
		rm -f .devnet/anvil.pid; \
		echo "Devnet stopped"; \
	else \
		echo "Devnet not running"; \
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
	@echo "Running E2E tests..."
	cd op-e2e && go test -v ./faultproofs/... -timeout 300s

# Run E2E unit tests only (no devnet required)
test-e2e-unit:
	cd op-e2e && go test -v -run "TestRATHelper|TestRATConstants" ./faultproofs/...

# Run E2E integration tests (requires devnet-allocs)
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
	@echo "E2E Testing:"
	@echo "  make devnet-allocs      Set up devnet and deploy contracts"
	@echo "  make devnet-clean       Clean devnet state and stop Anvil"
	@echo "  make devnet-up          Start Anvil devnet"
	@echo "  make devnet-down        Stop Anvil devnet"
	@echo "  make test-e2e           Run all E2E tests"
	@echo "  make test-e2e-unit      Run E2E unit tests (no devnet)"
	@echo "  make test-e2e-integration  Run E2E integration tests"
	@echo ""
	@echo "Quick Start for E2E:"
	@echo "  make devnet-allocs && make test-e2e"
