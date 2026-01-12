.PHONY: all test test-rat help clean coverage deps fmt lint info build

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
	@echo "  make build              Build all packages"
	@echo "  make test               Run all E2E tests"
	@echo "  make test-rat           Run all RAT tests"
	@echo "  make clean              Clean build artifacts"
	@echo "  make coverage           Run tests with coverage"
	@echo "  make deps               Verify Go module dependencies"
	@echo "  make fmt                Format Go code"
	@echo "  make lint               Lint Go code"
	@echo "  make info               Show environment info"
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
	@echo "Running E2E tests..."
	@GOWORK=off go test -v ./faultproofs/... 2>&1 | tee /tmp/e2e_test_output.log; \
	TEST_EXIT_CODE=$${PIPESTATUS[0]}; \
	chmod +x ../scripts/parse_test_summary.sh && ../scripts/parse_test_summary.sh /tmp/e2e_test_output.log; \
	exit $$TEST_EXIT_CODE

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
