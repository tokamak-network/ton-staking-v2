.PHONY: all build test clean help
.PHONY: devnet-allocs-optimism devnet-allocs-offline devnet-clean devnet-status
.PHONY: test-e2e test-e2e-unit test-e2e-integration
.PHONY: devnet-start devnet-stop devnet-info devnet-logs
.PHONY: test-bls-fork test-bls-library-fork test-fast-withdrawal-fork test-bls-fork-public

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

# Generate lib/optimism devnet allocs (OPTIONAL - for updating config files)
# NOTE: This is only needed when regenerating files in scripts/config/
# Normal devnet setup does NOT require this step
devnet-allocs-optimism:
	@command -v just >/dev/null 2>&1 || { echo "Error: 'just' command not found. Install it from: https://github.com/casey/just"; exit 1; }
	@echo "=== Building lib/optimism devnet allocs ==="
	@if [ ! -f $(OPTIMISM_DIR)/packages/contracts-bedrock/forge-artifacts/DisputeGameFactory.sol/DisputeGameFactory.json ]; then \
		echo "Building Optimism contracts (first time)..."; \
		cd $(OPTIMISM_DIR) && just forge-build; \
	fi
	@echo "Generating devnet allocs..."
	cd $(OPTIMISM_DIR) && just devnet-allocs

# Generate genesis file with all contracts (Fully offline - no lib/optimism needed)
# All required files are pre-configured in scripts/config/
devnet-allocs-offline:
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

# Verify complete genesis setup (TON Staking V3 + Optimism)
verify-genesis-setup:
	@echo "=== Verifying Genesis Setup ==="
	@if [ ! -f .devnet/genesis-l1-staking-v3.json ]; then \
		echo "Error: Genesis file not found. Run 'make devnet-allocs-offline' first."; \
		exit 1; \
	fi
	@bash scripts/verify-genesis-setup.sh

# ==========================================
# Persistent Devnet Commands (Kurtosis)
# ==========================================
# These commands manage a persistent Kurtosis devnet for manual testing
# and RAT Client development. They use the same genesis as E2E tests.
#
# Workflow:
#   1. make devnet-allocs-offline  # Generate genesis (same as E2E)
#   2. make devnet-start           # Start persistent devnet
#   3. make devnet-info            # Get RPC endpoints and addresses
#   4. make rat-client-run         # Run RAT Client
#   5. make devnet-stop            # Stop devnet when done
# ==========================================

# Start persistent Kurtosis devnet with TON Staking V3
devnet-start:
	@if [ ! -f .devnet/allocs-l1-staking-v3.json ]; then \
		echo "Error: Genesis not found. Run 'make devnet-allocs-offline' first."; \
		exit 1; \
	fi
	@chmod +x ./scripts/start-persistent-devnet.sh
	@./scripts/start-persistent-devnet.sh

# Stop persistent devnet
devnet-stop:
	@chmod +x ./scripts/stop-devnet.sh
	@./scripts/stop-devnet.sh

# Get devnet information (RPC endpoints, contract addresses)
devnet-info:
	@chmod +x ./scripts/get-devnet-info.sh
	@./scripts/get-devnet-info.sh

# Show devnet logs (specify service name)
# Usage: make devnet-logs SERVICE=op-node
devnet-logs:
	@if [ -z "$(SERVICE)" ]; then \
		echo "Usage: make devnet-logs SERVICE=<service-name>"; \
		echo ""; \
		echo "Available services:"; \
		echo "  - el-1-geth-teku (L1 execution)"; \
		echo "  - cl-1-teku-geth (L1 consensus)"; \
		echo "  - op-el-2151908-node0-op-geth (L2 execution)"; \
		echo "  - op-cl-2151908-node0-op-node (L2 consensus / Rollup RPC)"; \
		echo "  - op-batcher-2151908-op-kurtosis (Batcher)"; \
		echo "  - op-proposer-2151908-op-kurtosis (Proposer)"; \
		exit 1; \
	fi
	@kurtosis service logs simple-devnet $(SERVICE) -f

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
	@cd op-e2e && GOWORK=off go test -count=1 -v ./faultproofs/... -timeout 300s 2>&1 | tee /tmp/go_test_output.log; \
	GO_EXIT_CODE=$${PIPESTATUS[0]}; \
	cd .. && chmod +x scripts/parse_test_summary.sh && ./scripts/parse_test_summary.sh /tmp/go_test_output.log; \
	exit $$GO_EXIT_CODE

# Run E2E unit tests only (no devnet required)
test-e2e-unit:
	cd op-e2e && go test -count=1 -v -run "TestRATHelper|TestRATConstants" ./faultproofs/...

# Run E2E integration tests (requires devnet-allocs-offline first)
test-e2e-integration:
	@if [ ! -f .devnet/genesis-l1-staking-v3.json ]; then \
		echo "Error: Genesis file not found. Run 'make devnet-allocs-offline' first."; \
		exit 1; \
	fi
	cd op-e2e && GOWORK=off go test -count=1 -v -run "TestRATIntegration" ./faultproofs/... -timeout 300s

# ==========================================
# BLS Signature Tests (Mainnet Fork)
# ==========================================
# These tests require EIP-2537 BLS precompiles (available after Ethereum Pectra upgrade, May 2025)
# You need a mainnet RPC URL to fork from

# Run all BLS-related tests with Mainnet fork
# Usage: make test-bls-fork RPC_URL=https://your-mainnet-rpc-url
test-bls-fork:
	@echo ""
	@echo "=== BLS Signature Tests (Mainnet Fork) ==="
	@echo ""
	@echo "⚠️  IMPORTANT: This test requires EIP-2537 support"
	@echo "   - EIP-2537 is available after Ethereum Pectra upgrade (May 2025)"
	@echo "   - Requires RPC_URL parameter or MAINNET_RPC_URL environment variable"
	@echo ""
	@if [ -z "$(RPC_URL)" ] && [ -z "$$MAINNET_RPC_URL" ]; then \
		echo "❌ Error: No RPC URL provided"; \
		echo "   Usage: make test-bls-fork RPC_URL=https://your-mainnet-rpc-url"; \
		echo "   Or set: export MAINNET_RPC_URL=https://your-mainnet-rpc-url"; \
		exit 1; \
	fi
	@FORK_URL=$${RPC_URL:-$$MAINNET_RPC_URL}; \
	echo "Using RPC URL: $$FORK_URL"; \
	echo ""; \
	echo "Running BLS library tests..."; \
	forge test --match-path "test/v3/BLS12381Fork.t.sol" --fork-url $$FORK_URL -vv; \
	echo ""; \
	echo "Running Fast Withdrawal E2E fork tests..."; \
	forge test --match-path "test/v3/scenarios/FastWithdrawalE2EFork.t.sol" --fork-url $$FORK_URL -vv

# Run only BLS library tests with Mainnet fork
test-bls-library-fork:
	@echo ""
	@echo "=== BLS12381 Library Tests (Mainnet Fork) ==="
	@echo ""
	@if [ -z "$(RPC_URL)" ] && [ -z "$$MAINNET_RPC_URL" ]; then \
		echo "❌ Error: No RPC URL provided"; \
		echo "   Usage: make test-bls-library-fork RPC_URL=https://your-mainnet-rpc-url"; \
		exit 1; \
	fi
	@FORK_URL=$${RPC_URL:-$$MAINNET_RPC_URL}; \
	forge test --match-path "test/v3/BLS12381Fork.t.sol" --fork-url $$FORK_URL -vv

# Run only Fast Withdrawal E2E tests with Mainnet fork
test-fast-withdrawal-fork:
	@echo ""
	@echo "=== Fast Withdrawal E2E Tests (Mainnet Fork) ==="
	@echo ""
	@if [ -z "$(RPC_URL)" ] && [ -z "$$MAINNET_RPC_URL" ]; then \
		echo "❌ Error: No RPC URL provided"; \
		echo "   Usage: make test-fast-withdrawal-fork RPC_URL=https://your-mainnet-rpc-url"; \
		exit 1; \
	fi
	@FORK_URL=$${RPC_URL:-$$MAINNET_RPC_URL}; \
	forge test --match-path "test/v3/scenarios/FastWithdrawalE2EFork.t.sol" --fork-url $$FORK_URL -vv

# Run BLS tests with public mainnet RPC (no API key needed, but may be rate-limited)
test-bls-fork-public:
	@echo ""
	@echo "=== BLS Tests (Public Mainnet Fork) ==="
	@echo "⚠️  Using public RPC - may be slow or rate-limited"
	@echo ""
	@$(MAKE) test-bls-fork RPC_URL=https://ethereum-rpc.publicnode.com

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
	@echo "BLS Signature Tests (Mainnet Fork):"
	@echo "  make test-bls-fork RPC_URL=<url>        Run all BLS fork tests"
	@echo "  make test-bls-library-fork RPC_URL=<url> Run BLS library tests only"
	@echo "  make test-fast-withdrawal-fork RPC_URL=<url> Run Fast Withdrawal E2E fork tests"
	@echo "  make test-bls-fork-public               Run with public RPC (may be slow)"
	@echo ""
	@echo "E2E Testing (Automated):"
	@echo "  make devnet-allocs-offline  Generate genesis (fully offline, no lib/optimism needed)"
	@echo "  make test-e2e               Run E2E tests (starts isolated nodes)"
	@echo "  make test-e2e-unit          Run E2E unit tests (no genesis needed)"
	@echo "  make test-e2e-integration   Run E2E integration tests"
	@echo ""
	@echo "Persistent Devnet (Manual Testing):"
	@echo "  make devnet-start           Start Kurtosis devnet"
	@echo "  make devnet-stop            Stop devnet"
	@echo "  make devnet-info            Get RPC endpoints and addresses"
	@echo "  make devnet-logs SERVICE=X  Show service logs"
	@echo ""
	@echo "Devnet Management:"
	@echo "  make devnet-clean           Clean all devnet state"
	@echo "  make devnet-status          Show devnet status"
	@echo "  make devnet-verify          Verify Optimism contracts in genesis"
	@echo ""
	@echo "RAT Client:"
	@echo "  make rat-client-build       Build RAT client Type 3"
	@echo "  make rat-client-test        Test RAT client"
	@echo "  make rat-client-run         Run RAT client (requires config)"

# ==========================================
# RAT Client Commands
# ==========================================

RAT_CLIENT_DIR := clients/rat-client-type3

# Build RAT client Type 3
rat-client-build:
	@echo "Building RAT Client Type 3..."
	cd $(RAT_CLIENT_DIR) && go build -o bin/rat-client-type3 ./cmd
	@echo "Binary: $(RAT_CLIENT_DIR)/bin/rat-client-type3"

# Test RAT client
rat-client-test:
	@echo "Testing RAT Client Type 3..."
	cd $(RAT_CLIENT_DIR) && go test -count=1 -v ./pkg/...

# Run RAT client (development mode with example config)
rat-client-run:
	@if [ ! -f $(RAT_CLIENT_DIR)/config.yaml ]; then \
		echo "Error: config.yaml not found. Copy config.example.yaml to config.yaml first."; \
		exit 1; \
	fi
	cd $(RAT_CLIENT_DIR) && go run ./cmd \
		--l1-rpc $$(grep l1_rpc_url config.yaml | awk '{print $$2}' | tr -d '"') \
		--l2-rpc $$(grep l2_rpc_url config.yaml | awk '{print $$2}' | tr -d '"') \
		--private-key $$(grep private_key config.yaml | awk '{print $$2}' | tr -d '"') \
		--rat-contract $$(grep rat_contract config.yaml | awk '{print $$2}' | tr -d '"') \
		--system-config $$(grep system_config config.yaml | awk '{print $$2}' | tr -d '"') \
		--batch-inbox $$(grep batch_inbox config.yaml | awk '{print $$2}' | tr -d '"') \
		--batcher-address $$(grep batcher_address config.yaml | awk '{print $$2}' | tr -d '"') \
		--dispute-game-factory $$(grep dispute_game_factory config.yaml | awk '{print $$2}' | tr -d '"') \
		--l1-bridge-registry $$(grep l1_bridge_registry config.yaml | awk '{print $$2}' | tr -d '"')

# Clean RAT client build artifacts
rat-client-clean:
	@echo "Cleaning RAT client artifacts..."
	cd $(RAT_CLIENT_DIR) && rm -rf bin/
	@echo "Cleaned"

.PHONY: rat-client-build rat-client-test rat-client-run rat-client-clean

# Run specific RAT State Root test only
test-rat-state-root:
	@echo "Running RAT State Root test only..."
	cd op-e2e && GOWORK=off go test -v ./faultproofs -run TestRATStateRootAsTarget -timeout 2m
