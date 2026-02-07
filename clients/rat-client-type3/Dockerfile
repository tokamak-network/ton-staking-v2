# Build stage
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache git make

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the binary
RUN go build -o /rat-client ./cmd

# Runtime stage
FROM alpine:latest

WORKDIR /app

# Install runtime dependencies
RUN apk add --no-cache ca-certificates

# Copy binary from builder
COPY --from=builder /rat-client /app/rat-client

# Copy ABI files
COPY abi /app/abi

# Copy entrypoint script
COPY entrypoint.sh /app/entrypoint.sh

# Set executable permissions
RUN chmod +x /app/rat-client /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
