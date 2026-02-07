# TON Staking V3 - Local Devnet

## Prerequisites

- [Foundry](https://book.getfoundry.sh/) (forge, cast, anvil)
- [Node.js](https://nodejs.org/) >= 18
- [Docker](https://www.docker.com/)
- [jq](https://jqlang.github.io/jq/)
- [Go](https://go.dev/) (for Optimism toolchain)

## Quick Start

### 1. Install submodule

```bash
git submodule update --init --recursive
```

### 2. Generate L1/L2 genesis

```bash
./scripts/generate-optimism-allocs.sh
```

This generates all L1 allocs (Optimism + TON Staking V3), L2 genesis, and rollup config into `.devnet/`.

### 3. Start devnet

```bash
./scripts/local/start-dev.sh
```

Starts Anvil L1 (port 8546), L2 services (Docker), registers rollup types, validators, and bridges TON.

### 4. Start web UI

```bash
cd web-ui
npm install
npm run dev:local
```

Open [http://localhost:5173](http://localhost:5173) in your browser.

### 5. Stop devnet

```bash
./scripts/local/stop-dev.sh
```

Stops Anvil, Docker containers, and cleans up resources.

## Network Info

| Chain | RPC URL | Chain ID |
|-------|---------|----------|
| L1    | http://localhost:8546 | 900 |
| L2    | http://localhost:9545 | 901 |
