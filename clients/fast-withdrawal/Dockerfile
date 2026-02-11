# Combined Fast Withdrawal Node: Validator + Aggregator
# Each node runs both binaries - any validator can aggregate and submit.

# Stage 1: Build validator
FROM golang:1.22-alpine AS validator-builder

WORKDIR /app

RUN apk add --no-cache git make gcc g++ musl-dev

COPY validator/go.mod validator/go.sum ./
RUN go mod download

COPY validator/ .

RUN CGO_ENABLED=1 go build -o /fw-validator ./cmd

# Stage 2: Build aggregator
FROM golang:1.24-alpine AS aggregator-builder

WORKDIR /app

RUN apk add --no-cache git make gcc g++ musl-dev

COPY aggregator/go.mod aggregator/go.sum ./
RUN go mod download

COPY aggregator/ .

RUN CGO_ENABLED=1 go build -o /fw-aggregator ./cmd

# Runtime stage
FROM alpine:latest

WORKDIR /app

RUN apk add --no-cache ca-certificates

COPY --from=validator-builder /fw-validator /app/fw-validator
COPY --from=aggregator-builder /fw-aggregator /app/fw-aggregator
COPY entrypoint.sh /app/entrypoint.sh

RUN chmod +x /app/fw-validator /app/fw-aggregator /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
