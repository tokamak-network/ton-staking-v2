.PHONY: all test test-rat test-rat-unit test-rat-integration test-rat-e2e help bindings clean coverage deps fmt lint info build

# Default target
all: build test-rat-unit

# Build all packages
build:
	go build ./...

# Help target
help:
	@echo "TON Staking V3 E2E Test Commands"
	@echo ""
	@echo "Prerequisites (Single Terminal - like Asterisc):"
	@echo ""
	@echo "  cd .."
	@echo "  make devnet-allocs    # Build + start L1 + deploy RAT"
	@echo "  make test-e2e         # Run E2E tests"
	@echo "  make devnet-down      # Stop L1 when done"
	@echo ""
	@echo "Usage:"
	@echo "  make build              Build all packages"
	@echo "  make test               Run all E2E tests"
	@echo "  make test-rat           Run all RAT tests"
	@echo "  make test-rat-unit      Run RAT unit tests only (no devnet required)"
	@echo "  make test-rat-integration  Run integration tests (requires devnet)"
	@echo "  make test-rat-e2e       Run full E2E tests (requires Optimism devnet)"
	@echo "  make bindings           Generate Go bindings from Solidity contracts"
	@echo "  make clean              Clean build artifacts"
	@echo "  make coverage           Run tests with coverage"
	@echo "  make deps               Verify Go module dependencies"
	@echo "  make fmt                Format Go code"
	@echo "  make lint               Lint Go code"
	@echo "  make info               Show environment info"
	@echo ""
	@echo "Environment variables (set automatically by make deploy-rat-devnet):"
	@echo "  RAT_ADDRESS             Deployed RAT contract address"
	@echo "  DISPUTE_GAME_FACTORY    DisputeGameFactory address"
	@echo "  SYSTEM_CONFIG_ADDRESS   SystemConfig address"
	@echo "  E2E_PRIVATE_KEY         Test account private key"
	@echo "  E2E_RPC_URL             RPC endpoint (default: http://localhost:8545)"
	@echo "  E2E_CHAIN_ID            Chain ID (900 for Optimism devnet)"
	@echo ""

# Run all E2E tests
test:
	go test -v ./...

# Run all RAT tests
test-rat:
	go test -v -run "TestRAT" ./faultproofs/...

# Run RAT unit tests only (no devnet required)
test-rat-unit:
	go test -v -run "TestRATHelper|TestRATConstants" ./faultproofs/...

# Run integration tests (requires devnet-allocs first)
test-rat-integration:
	@if [ ! -f "../.devnet/addresses.json" ]; then \
		echo "Error: Devnet not set up"; \
		echo ""; \
		echo "Run from project root:"; \
		echo "  make devnet-allocs"; \
		echo "  make test-e2e-integration"; \
		exit 1; \
	fi
	go test -v -run "TestRATIntegration" ./faultproofs/...

# Run full E2E tests (requires Optimism devnet)
test-rat-e2e:
	@echo "Running full E2E tests (skipped tests will show if devnet not available)..."
	go test -v -run "TestRATTrigger|TestRATEvidence|TestRATResolve|TestRATValidOutput|TestRATUnsafe|TestRATFuture|TestRATMultiL2|TestRATValidatorStaking" ./faultproofs/...

# Generate Go bindings from Solidity contracts
bindings:
	@echo "Generating Go bindings from RAT contract..."
	@if [ ! -f "../out/RAT.sol/RAT.json" ]; then \
		echo "Error: Contract not compiled. Run 'forge build' first."; \
		exit 1; \
	fi
	@python3 -c "\
import json; \
d = json.load(open('../out/RAT.sol/RAT.json')); \
abi = [item for item in d['abi'] if item.get('type') != 'error']; \
json.dump(abi, open('/tmp/rat_abi.json', 'w'))"
	abigen --abi=/tmp/rat_abi.json --pkg=bindings --type=RAT --out=bindings/rat_generated.go
	@echo "Bindings generated: bindings/rat_generated.go"

# Clean build artifacts
clean:
	go clean -testcache
	rm -rf ./coverage
	rm -f bindings/rat_generated.go

# Run tests with coverage
coverage:
	@mkdir -p coverage
	go test -v -coverprofile=coverage/cover.out ./...
	go tool cover -html=coverage/cover.out -o coverage/cover.html
	@echo "Coverage report: coverage/cover.html"

# Verify Go module dependencies
deps:
	go mod tidy
	go mod verify

# Format Go code
fmt:
	gofmt -s -w .

# Lint Go code
lint:
	@if command -v golangci-lint &> /dev/null; then \
		golangci-lint run ./...; \
	else \
		echo "golangci-lint not installed. Install with:"; \
		echo "  go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest"; \
	fi

# Environment info
info:
	@echo "=== Environment Info ==="
	@echo "Go version: $$(go version)"
	@echo "Working directory: $$(pwd)"
	@echo ""
	@echo "=== Test Files ==="
	@find . -name "*_test.go" -type f
	@echo ""
	@echo "=== Environment Variables ==="
	@echo "RAT_ADDRESS: $${RAT_ADDRESS:-<not set>}"
	@echo "SYSTEM_CONFIG_ADDRESS: $${SYSTEM_CONFIG_ADDRESS:-<not set>}"
	@echo "E2E_RPC_URL: $${E2E_RPC_URL:-http://localhost:8545 (default)}"
	@echo "E2E_PRIVATE_KEY: $${E2E_PRIVATE_KEY:+<set>}$${E2E_PRIVATE_KEY:-<not set>}"
