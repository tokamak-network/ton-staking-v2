.PHONY: all build test clean help
.PHONY: devnet-allocs-optimism devnet-allocs-offline devnet-clean devnet-status
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
# Asterisc-style workflow:
#   make devnet-allocs-offline  # Generate genesis with all contracts
#   make test-e2e               # E2E tests start their own isolated nodes
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

# Generate genesis file with all contracts (Asterisc-style offline generation)
devnet-allocs-offline: devnet-allocs-optimism
	@echo ""
	@echo "=== Generating genesis-l1-staking-v3.json (offline) ==="
	@chmod +x ./scripts/generate-allocs-offline.sh
	./scripts/generate-allocs-offline.sh
	@echo ""
	@echo "Genesis file generated: .devnet/genesis-l1-staking-v3.json"
	@echo "E2E tests will use this to start isolated L1 nodes"

# Clean all devnet state
devnet-clean:
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
# Devnet Verification Commands
# ==========================================

# Verify Optimism L1 contracts in genesis file
devnet-verify:
	@bash scripts/verify-optimism-deployment.sh

# ==========================================
# E2E Test Commands
# ==========================================

# Run all E2E tests (requires devnet-allocs-offline first)
test-e2e:
	@if [ ! -f .devnet/genesis-l1-staking-v3.json ]; then \
		echo "Error: Genesis file not found. Run 'make devnet-allocs-offline' first."; \
		exit 1; \
	fi
	@echo "Running E2E tests (each test starts its own isolated node)..."
	cd op-e2e && GOWORK=off go test -v ./faultproofs/... ./slashing/... -timeout 300s

# Run E2E unit tests only (no devnet required)
test-e2e-unit:
	cd op-e2e && go test -v -run "TestRATHelper|TestRATConstants" ./faultproofs/...

# Run E2E integration tests (requires devnet-allocs-offline first)
test-e2e-integration:
	@if [ ! -f .devnet/genesis-l1-staking-v3.json ]; then \
		echo "Error: Genesis file not found. Run 'make devnet-allocs-offline' first."; \
		exit 1; \
	fi
	cd op-e2e && GOWORK=off go test -v -run "TestRATIntegration" ./faultproofs/... -timeout 300s

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
	@echo "E2E Testing (Asterisc-style):"
	@echo "  make devnet-allocs-offline  Generate genesis with all contracts"
	@echo "  make test-e2e               Run E2E tests (starts isolated nodes)"
	@echo "  make test-e2e-unit          Run E2E unit tests (no genesis needed)"
	@echo "  make test-e2e-integration   Run E2E integration tests"
	@echo ""
	@echo "Devnet Management:"
	@echo "  make devnet-clean           Clean all devnet state"
	@echo "  make devnet-status          Show devnet status"
	@echo "  make devnet-verify          Verify Optimism contracts in genesis"
