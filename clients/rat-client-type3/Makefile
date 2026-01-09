# RAT Client Makefile

.PHONY: help build test clean devnet-up devnet-down deploy-rat run

# Paths
OPTIMISM_ROOT := ../../lib/optimism
CHALLENGER_SCRIPTS := $(OPTIMISM_ROOT)/op-challenger/scripts

help:
	@echo "RAT Client - Available Commands:"
	@echo ""
	@echo "  make devnet-up        - Start full Optimism devnet (L1 + L2 + op-node + op-batcher)"
	@echo "  make devnet-down      - Stop devnet"
	@echo "  make devnet-check     - Check devnet status"
	@echo "  make deploy-rat       - Deploy RAT contract to devnet L1"
	@echo "  make run              - Run RAT client"
	@echo "  make test             - Run unit tests"
	@echo "  make test-e2e         - Run E2E tests (requires devnet)"
	@echo "  make build            - Build RAT client binary"
	@echo "  make clean            - Clean build artifacts"

# ==========================================
# Devnet Management (using op-challenger scripts)
# ==========================================

devnet-up:
	@echo "🚀 Starting Optimism devnet..."
	@echo "This will start:"
	@echo "  - L1 geth"
	@echo "  - L2 geth"
	@echo "  - op-node (Rollup RPC)"
	@echo "  - op-batcher"
	@echo "  - op-proposer"
	@echo ""
	cd $(CHALLENGER_SCRIPTS) && ./build-devnet.sh

devnet-down:
	@echo "🛑 Stopping devnet..."
	cd $(CHALLENGER_SCRIPTS) && kurtosis enclave rm -f simple-devnet || true

devnet-check:
	@echo "🔍 Checking devnet status..."
	cd $(CHALLENGER_SCRIPTS) && ./check-system.sh

devnet-logs:
	@echo "📋 Showing devnet logs..."
	kurtosis service logs simple-devnet op-node

# ==========================================
# RAT Contract Deployment
# ==========================================

deploy-rat:
	@echo "📝 Deploying RAT contract to devnet L1..."
	@echo ""
	@echo "Step 1: Get Optimism contract addresses from devnet..."
	@$(MAKE) -s get-devnet-addresses
	@echo ""
	@echo "Step 2: Deploy full TON Staking V3 + RAT..."
	cd ../.. && \
	DISPUTE_GAME_FACTORY_PROXY=$$(cat .devnet/addresses.json | grep DisputeGameFactoryProxy | cut -d'"' -f4) \
	SYSTEM_CONFIG_PROXY=$$(cat .devnet/addresses.json | grep SystemConfigProxy | cut -d'"' -f4) \
	forge script script/DeployV3FullForDevnet.s.sol:DeployV3FullForDevnet \
		--rpc-url http://localhost:8545 \
		--broadcast \
		--private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d \
		-vvv
	@echo ""
	@echo "Step 3: Extract deployed addresses..."
	@$(MAKE) -s update-config-addresses
	@echo ""
	@echo "✅ RAT contract deployed successfully!"
	@echo "Check deployments/devnet.json for all addresses"

# ==========================================
# Build
# ==========================================

build:
	@echo "🔨 Building RAT client..."
	go build -o bin/rat-client ./cmd/main.go

# ==========================================
# Run
# ==========================================

run: build
	@echo "🏃 Running RAT client..."
	@echo "Make sure devnet is running (make devnet-up)"
	./bin/rat-client --config config.devnet.yaml

# ==========================================
# Tests
# ==========================================

test:
	@echo "🧪 Running unit tests..."
	go test -v ./pkg/...

test-e2e:
	@echo "🧪 Running E2E tests..."
	@echo "This requires devnet to be running"
	go test -v ./test -run TestRATClient

test-full: devnet-up test-e2e devnet-down
	@echo "✅ Full test cycle completed"

# ==========================================
# Development
# ==========================================

clean:
	@echo "🧹 Cleaning..."
	rm -rf bin/
	rm -f rat-client.log

# ==========================================
# Quick Start
# ==========================================

quickstart: devnet-up deploy-rat run
	@echo "✅ RAT Client is running against devnet!"

# ==========================================
# Helper - Show devnet endpoints
# ==========================================

endpoints:
	@echo "📡 Devnet Endpoints:"
	@echo ""
	@echo "L1 RPC:       http://localhost:8545"
	@echo "L2 RPC:       http://localhost:9545"
	@echo "op-node RPC:  http://localhost:9545"
	@echo "Beacon API:   http://localhost:5052"
	@echo ""
	@echo "Useful commands:"
	@echo "  cast block latest --rpc-url http://localhost:8545  # L1 latest block"
	@echo "  cast block latest --rpc-url http://localhost:9545  # L2 latest block"
	@echo "  curl http://localhost:9545 -X POST -H 'Content-Type: application/json' \\"
	@echo "    -d '{\"jsonrpc\":\"2.0\",\"method\":\"optimism_syncStatus\",\"params\":[],\"id\":1}'"

# ==========================================
# Helper - Get Devnet Addresses
# ==========================================

get-devnet-addresses:
	@echo "Reading Optimism contract addresses from devnet..."
	@if [ -f "$(OPTIMISM_ROOT)/.devnet/addresses.json" ]; then \
		cat $(OPTIMISM_ROOT)/.devnet/addresses.json | jq .; \
	else \
		echo "Error: addresses.json not found. Run 'make devnet-up' first."; \
		exit 1; \
	fi

update-config-addresses:
	@echo "Updating config.devnet.yaml with deployed addresses..."
	@mkdir -p deployments
	@# Extract addresses from forge script output
	@# This is a placeholder - actual implementation will parse forge output
	@echo "TODO: Parse deployment output and update config"
	@echo "For now, manually update config.devnet.yaml with addresses from deployment log"
