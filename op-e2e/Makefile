.PHONY: all test test-rat test-rat-simple test-slashing test-real-challenger test-multi-challenger test-slashing-integration test-reward-distribution test-edge-cases test-delegator-protection test-complex-scenarios test-permission-security test-slashing-all help clean coverage deps fmt lint info build

# Default target
all: build test

# Build all packages
build:
	go build ./...

# Help target
help:
	@echo "TON Staking V3 E2E Test Commands"
	@echo ""
	@echo "Prerequisites:"
	@echo ""
	@echo "  cd .."
	@echo "  make devnet-allocs-offline  # Generate genesis file (once)"
	@echo "  cd op-e2e"
	@echo "  make test                   # Run E2E tests (starts isolated nodes)"
	@echo ""
	@echo "Usage:"
	@echo "  make build                      Build all packages"
	@echo "  make test                       Run all E2E tests"
	@echo "  make test-rat                   Run all RAT tests"
	@echo "  make test-slashing              Run slashing tests"
	@echo "  make test-slashing-all          Run ALL slashing tests (all categories)"
	@echo ""
	@echo "Slashing Test Categories:"
	@echo "  make test-slashing-integration  Run slashing integration tests (Task 4)"
	@echo "  make test-reward-distribution   Run reward distribution tests (Task 5)"
	@echo "  make test-edge-cases            Run edge case tests (Category 1)"
	@echo "  make test-delegator-protection  Run delegator protection tests (Category 2)"
	@echo "  make test-complex-scenarios     Run complex scenario tests (Category 3)"
	@echo "  make test-permission-security   Run permission/security tests (Category 4)"
	@echo ""
	@echo "Real FaultDisputeGame Tests (Full Optimism Devnet):"
	@echo "  make test-real-challenger       Run real FaultDisputeGame E2E tests"
	@echo "  make test-multi-challenger      Run multi-challenger E2E tests"
	@echo ""
	@echo "Other:"
	@echo "  make clean                  Clean build artifacts"
	@echo "  make coverage               Run tests with coverage"
	@echo "  make deps                   Verify Go module dependencies"
	@echo "  make fmt                    Format Go code"
	@echo "  make lint                   Lint Go code"
	@echo "  make info                   Show environment info"
	@echo ""

# Run all E2E tests (requires genesis file)
test:
	@if [ ! -f "../.devnet/genesis-l1-staking-v3.json" ]; then \
		echo "Error: Genesis file not found"; \
		echo ""; \
		echo "Run from project root:"; \
		echo "  make devnet-allocs-offline"; \
		exit 1; \
	fi
	GOWORK=off go test -v ./faultproofs/...

# Run all RAT tests (requires genesis file)
test-rat:
	@if [ ! -f "../.devnet/genesis-l1-staking-v3.json" ]; then \
		echo "Error: Genesis file not found"; \
		echo ""; \
		echo "Run from project root:"; \
		echo "  make devnet-allocs-offline"; \
		exit 1; \
	fi
	GOWORK=off go test -v -run "TestRAT|TestTONStaking|TestAccount" ./faultproofs/...

# Run SimpleRAT tests (game creation, evidence submission, etc.)
test-rat-simple:
	@if [ ! -f "../.devnet/genesis-l1-staking-v3.json" ]; then \
		echo "Error: Genesis file not found"; \
		echo ""; \
		echo "Run from project root:"; \
		echo "  make devnet-allocs-offline"; \
		exit 1; \
	fi
	GOWORK=off go test -v -run "TestSimpleRAT" ./faultproofs/...

# Run slashing tests
test-slashing:
	@if [ ! -f "../.devnet/genesis-l1-staking-v3.json" ]; then \
		echo "Error: Genesis file not found"; \
		echo ""; \
		echo "Run from project root:"; \
		echo "  make devnet-allocs-offline"; \
		exit 1; \
	fi
	GOWORK=off go test -v -run "TestSlashing" ./slashing/...

# Run real FaultDisputeGame E2E tests
# Uses Full Optimism devnet with Alphabet trace type (no Cannon build required)
# Tests: TestRealChallenger_* (single/multi challenger, game flows)
# Note: Requires Go workspace (uses lib/optimism packages)
test-real-challenger:
	@if [ ! -f "../.devnet/genesis-l1-staking-v3.json" ]; then \
		echo "Error: Genesis file not found"; \
		echo ""; \
		echo "Run from project root:"; \
		echo "  make devnet-allocs-offline"; \
		exit 1; \
	fi
	@echo "=== Running Real FaultDisputeGame Tests ==="
	@echo "Using Alphabet trace type (Cannon build not required)"
	@echo "Expected runtime: ~90 seconds per test"
	@echo ""
	go test -v -timeout 30m -run "TestRealChallenger" ./slashing/...

# Run multi-challenger E2E tests
# Uses Full Optimism devnet with multiple op-challenger services
# Tests: TestMultiChallenger_* (competing challengers, reward distribution)
# Note: Requires Go workspace (uses lib/optimism packages)
test-multi-challenger:
	@if [ ! -f "../.devnet/genesis-l1-staking-v3.json" ]; then \
		echo "Error: Genesis file not found"; \
		echo ""; \
		echo "Run from project root:"; \
		echo "  make devnet-allocs-offline"; \
		exit 1; \
	fi
	@echo "=== Running Multi-Challenger Tests ==="
	@echo "Using Full Optimism devnet with multiple op-challenger services"
	@echo "Expected runtime: ~90 seconds per test"
	@echo ""
	go test -v -timeout 30m -run "TestMultiChallenger" ./slashing/...

# Run slashing integration tests (Task 4: Real Slashing Integration)
test-slashing-integration:
	@if [ ! -f "../.devnet/genesis-l1-staking-v3.json" ]; then \
		echo "Error: Genesis file not found"; \
		echo ""; \
		echo "Run from project root:"; \
		echo "  make devnet-allocs-offline"; \
		exit 1; \
	fi
	GOWORK=off go test -v -timeout 10m -run "TestSlashingIntegration" ./slashing/...

# Run reward distribution tests (Task 5: Reward Distribution Verification)
test-reward-distribution:
	@if [ ! -f "../.devnet/genesis-l1-staking-v3.json" ]; then \
		echo "Error: Genesis file not found"; \
		echo ""; \
		echo "Run from project root:"; \
		echo "  make devnet-allocs-offline"; \
		exit 1; \
	fi
	GOWORK=off go test -v -timeout 10m -run "TestRewardDistribution" ./slashing/...

# Run edge case tests (Category 1)
test-edge-cases:
	@if [ ! -f "../.devnet/genesis-l1-staking-v3.json" ]; then \
		echo "Error: Genesis file not found"; \
		echo ""; \
		echo "Run from project root:"; \
		echo "  make devnet-allocs-offline"; \
		exit 1; \
	fi
	GOWORK=off go test -v -timeout 10m -run "TestEdgeCase" ./slashing/...

# Run delegator protection tests (Category 2)
test-delegator-protection:
	@if [ ! -f "../.devnet/genesis-l1-staking-v3.json" ]; then \
		echo "Error: Genesis file not found"; \
		echo ""; \
		echo "Run from project root:"; \
		echo "  make devnet-allocs-offline"; \
		exit 1; \
	fi
	GOWORK=off go test -v -timeout 10m -run "TestDelegatorProtection" ./slashing/...

# Run complex scenario tests (Category 3)
test-complex-scenarios:
	@if [ ! -f "../.devnet/genesis-l1-staking-v3.json" ]; then \
		echo "Error: Genesis file not found"; \
		echo ""; \
		echo "Run from project root:"; \
		echo "  make devnet-allocs-offline"; \
		exit 1; \
	fi
	GOWORK=off go test -v -timeout 10m -run "TestComplexScenario" ./slashing/...

# Run permission and security tests (Category 4)
test-permission-security:
	@if [ ! -f "../.devnet/genesis-l1-staking-v3.json" ]; then \
		echo "Error: Genesis file not found"; \
		echo ""; \
		echo "Run from project root:"; \
		echo "  make devnet-allocs-offline"; \
		exit 1; \
	fi
	GOWORK=off go test -v -timeout 10m -run "TestPermission|TestSecurity" ./slashing/...

# Run all slashing tests (all categories)
# Note: Requires Go workspace (uses lib/optimism packages)
test-slashing-all:
	@if [ ! -f "../.devnet/genesis-l1-staking-v3.json" ]; then \
		echo "Error: Genesis file not found"; \
		echo ""; \
		echo "Run from project root:"; \
		echo "  make devnet-allocs-offline"; \
		exit 1; \
	fi
	go test -v -timeout 60m ./slashing/...

# ============================================================================
# Real FaultDisputeGame Integration Tests
# Uses Full Optimism devnet with Alphabet trace type (no Cannon build required)
# ============================================================================

# Run all slashing tests with Full Optimism devnet
# This is the comprehensive test suite for TON slashing with real dispute games
# Note: Requires Go workspace (uses lib/optimism packages)
test-slashing-devnet:
	@if [ ! -f "../.devnet/genesis-l1-staking-v3.json" ]; then \
		echo "Error: Genesis file not found. Run 'make devnet-allocs-offline' first."; \
		exit 1; \
	fi
	@echo "=== Running Slashing Tests with Full Optimism Devnet ==="
	@echo "Using real FaultDisputeGame.sol and op-challenger service"
	@echo "Expected runtime: ~90 seconds per test"
	@echo ""
	go test -v -timeout 60m ./slashing/...

# Clean build artifacts
clean:
	go clean -testcache
	rm -rf ./coverage

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
	@echo "=== Genesis File ==="
	@if [ -f "../.devnet/genesis-l1-staking-v3.json" ]; then \
		echo "✓ Genesis file exists"; \
		echo "  Size: $$(du -h ../.devnet/genesis-l1-staking-v3.json | cut -f1)"; \
	else \
		echo "✗ Genesis file not found"; \
		echo "  Run: make devnet-allocs-offline"; \
	fi
