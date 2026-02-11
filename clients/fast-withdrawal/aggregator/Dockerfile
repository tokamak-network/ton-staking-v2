# Build stage
FROM golang:1.24-alpine AS builder

WORKDIR /app

# Install build dependencies (CGO required for herumi/bls-eth-go-binary)
RUN apk add --no-cache git make gcc g++ musl-dev

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the binary
RUN CGO_ENABLED=1 go build -o /aggregator ./cmd

# Runtime stage
FROM alpine:latest

WORKDIR /app

# Install runtime dependencies
RUN apk add --no-cache ca-certificates

# Copy binary from builder
COPY --from=builder /aggregator /app/aggregator

# Set executable permissions
RUN chmod +x /app/aggregator

ENTRYPOINT ["/app/aggregator"]
