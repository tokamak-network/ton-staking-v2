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

### 3. MetaMask Browser Extension

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
3. ✅ Initializes seigniorage (Auto-call to handle the First-call trap)
4. ✅ Installs frontend dependencies
5. ✅ Starts dev server (localhost:5173)

### Execution Output

When successfully running, you will see output like this:

```
============================
🎉 Demo is ready!
============================

Step 2.5: Initializing seigniorage...
Seigniorage initialized (startBlock set)

Frontend: http://localhost:5173
Anvil RPC: http://localhost:8545

Test Accounts (import to MetaMask):
  Operator: 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
  User1:    0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
...
```

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

MetaMask → Account Icon → "Import Account" → Enter the private keys shown in your terminal.

---

## UI Component Guide

### 🎰 Lottery Info (Top Left)
- **Prize Pool**: Current accumulated prizes for this round.
- **Participants**: Number of users who joined the current round.

### 💰 Your Balance (Top Right)
- **Deposited in Lottery**: User balance within the LotteryCandidate contract (available for lottery entry and withdrawal).

### 📈 Seigniorage Distribution (Bottom Right)
Displays seigniorage info and provides a claim function.

- **Total Deposited (Pool)**: Global pool size (WTON and Raw BigInt values).
- **Your Share**: User's percentage of the pool.
- **Claim Seigniorage**: Calls `updateSeigniorage()`.
  - On success, it displays the reward in scientific notation (e.g., `+1.9405e-7 WTON`).
  - Supports automatic data refetching.

### ⚡ Dev Tools: Advance Blocks
Tool for generating seigniorage quickly in the local environment.

- **Mine Button**: Instantly mines the specified number of blocks.
- Since seigniorage grows per block, it is recommended to mine at least 100 blocks before clicking "Claim Seigniorage".

---

## Demo Scenario (Summary)

### Scenario: Integrated Experience
1. Deposit 100 TON as **User1**.
2. Click **Enter Lottery** to join the round.
3. Click the **Mine** button to generate 100 blocks.
4. Click **Claim Seigniorage** to verify network rewards.
5. Switch to the **Operator** account and click **Draw Winner**.
6. Switch back to the winning account to check the increased balance.
