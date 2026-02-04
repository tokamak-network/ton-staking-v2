# LotteryCandidate Frontend Demo Guide

## Overview

This demo provides an environment to deploy the LotteryCandidate smart contract on a local Anvil network and experience real-time lottery entry, winning, and seigniorage distribution through a React-based web interface.

**Tech Stack**:
- **Backend**: Solidity + Foundry (Forge, Anvil)
- **Frontend**: React + Vite + TypeScript + TailwindCSS
- **Web3 Library**: Viem + Wagmi
- **Network**: Anvil (Local Ethereum network)

## Prerequisites

### 1. Install Foundry

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### 2. Install Node.js (v18 or higher)

```bash
node --version
npm --version
```

### 3. MetaMask Browser Extension
Install [MetaMask](https://metamask.io/) in Chrome, Brave, Firefox, etc.

## Quick Start

### One-Click Execution

From the project root directory:

```bash
chmod +x run-lottery-demo.sh
./run-lottery-demo.sh
```

This script automatically performs:
1. ✅ Starts Anvil network (localhost:8545, block-time: 1s)
2. ✅ Deploys LotteryCandidate contracts
3. ✅ Initializes seigniorage (Auto-call to solve First-call trap)
4. ✅ Installs frontend dependencies
5. ✅ Starts dev server (localhost:5173)

## MetaMask Setup

### 1. Add Local Network
Open MetaMask → Select Network → "Add Network" → "Add a network manually"

| Field | Value |
| :--- | :--- |
| Network Name | `Anvil Local` |
| RPC URL | `http://localhost:8545` |
| Chain ID | `31337` |
| Currency Symbol | `ETH` |

### 2. Import Test Accounts
MetaMask → Account Icon → "Import Account" → Enter Private Key

| Role | Address | Private Key |
| :--- | :--- | :--- |
| **Operator** | `0x70997970C51812dc3A010C7d01b50e0d17dc79C8` | `0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d` |
| **User1** | `0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC` | `0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a` |

## UI Component Guide

### 🎰 Lottery Info
- **Prize Pool**: Current accumulated prizes.
- **Participants**: Number of users entered in the current round.

### 💰 Your Balance
- **Deposited in Lottery**: Balance available for lottery and withdrawal.

### 📈 Seigniorage Distribution
- **Claim Seigniorage**: Triggers `updateSeigniorage()`.
- **Amount Received**: Detailed display in scientific notation for small rewards (e.g., `+1.9405e-7 WTON`).

### ⚡ Dev Tools: Advance Blocks
- **Mine Button**: Instantly generates blocks.
- **Recommendation**: Mine at least 100 blocks before claiming seigniorage to see noticeable changes.
