# TON Staking V3 Devnet Setup Guide

This guide explains how to set up a complete TON Staking V3 devnet environment with Anvil as L1.

## Prerequisites

- Docker & Docker Compose
- Foundry (forge, cast, anvil)
- jq
- Node.js & npm (for RAT clients)

## Architecture Overview

```
┌─────────────────┐
│   Anvil (L1)    │  ← Genesis with all contracts pre-deployed
│   Port: 8545    │
└────────┬────────┘
         │
         ├─── L1BridgeRegistry (Rollup registration)
         ├─── Layer2Manager (Operator staking)
         ├─── DepositManager (Validator staking)
         ├─── SeigManager (Seigniorage distribution)
         └─── RAT (Random validator assignment)
```

## Quick Start

### 1. Generate Genesis File

```bash
# Generate genesis with all TON Staking V3 contracts
./scripts/generate-allocs-offline.sh
```

This creates:
- `.devnet/allocs-l1-staking-v3.json` - Contract state
- `.devnet/genesis-l1-staking-v3.json` - Full genesis
- `.devnet/addresses.json` - Contract addresses

### 2. Start L1 (Anvil)

**IMPORTANT**: Use Anvil instead of Geth for devnet L1.

**Why Anvil?**
- ✅ Auto-mines blocks every second
- ✅ No beacon client required
- ✅ Developer-friendly (fast, instant transactions)
- ✅ Perfect genesis file support

**Why NOT Geth?**
- ❌ Post-merge requires beacon client
- ❌ Blocks don't auto-generate without beacon
- ❌ Clique + Cancun fork = compatibility issues

```bash
# Start Anvil with genesis
anvil \
  --port 8545 \
  --chain-id 900 \
  --block-time 1 \
  --init .devnet/genesis-l1-staking-v3.json
```

Or run in background:
```bash
nohup anvil \
  --port 8545 \
  --chain-id 900 \
  --block-time 1 \
  --init .devnet/genesis-l1-staking-v3.json \
  > .devnet/anvil-l1.log 2>&1 &
echo $! > .devnet/anvil-l1.pid
```

### 3. Register Rollup and Stake

The genesis file contains all contracts but **does NOT** include:
- Rollup config registration
- CandidateAddOn registration (operator staking)
- Validator staking

These must be done at runtime:

```bash
./scripts/register-and-stake.sh
```

This script performs:
1. ✅ Registers SystemConfig to L1BridgeRegistry (Type 3)
2. ✅ Stakes 1001 WTON for L2 operator (CandidateAddOn)
3. ✅ Stakes 100 WTON for validator
4. ✅ Verifies system health

## Manual Setup Steps

If you prefer to do it manually:

### Step 1: Register Rollup Config

```bash
L1_BRIDGE_REGISTRY="0x2dE080e97B0caE9825375D31f5D0eD5751fDf16D"
SYSTEM_CONFIG="0x577AcB7fA48878245a854ba51eD051a5B47cF83f"
TON="0xd55b55304b5cf7607B6dEd6DA6EeB487918AaD2E"
TON_STAKING_DEPLOYER_KEY="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"

# Register as Type 3 (Optimism Bedrock DisputeGame)
cast send $L1_BRIDGE_REGISTRY \
  "registerRollupConfigByManager(address,uint8,address,string)" \
  $SYSTEM_CONFIG 3 $TON "Devnet L2" \
  --private-key $TON_STAKING_DEPLOYER_KEY \
  --rpc-url http://localhost:8545
```

**Important**: The `TON_STAKING_DEPLOYER_KEY` account has manager role in genesis.

### Step 2: Register CandidateAddOn (Operator Staking)

```bash
LAYER2_MANAGER="0xcA03Dc4665A8C3603cb4Fd5Ce71Af9649dC00d44"
WTON="0x2B2fE3204CcB8282ac6bC31d485cB6aa010d193a"
DEPLOYER_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

# Approve WTON
cast send $WTON "approve(address,uint256)" $LAYER2_MANAGER \
  0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff \
  --private-key $DEPLOYER_KEY --rpc-url http://localhost:8545

# Register with 1001 WTON (minimum is 1000.1 WTON)
cast send $LAYER2_MANAGER \
  "registerCandidateAddOn(address,uint256,bool,string)" \
  $SYSTEM_CONFIG 1001000000000000000000000000000 false "Devnet Operator" \
  --private-key $DEPLOYER_KEY --rpc-url http://localhost:8545
```

### Step 3: Register Validator

```bash
DEPOSIT_MANAGER="0x90118d110B07ABB82Ba8980D1c5cC96EeA810d2C"
VALIDATOR_KEY="0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"
VALIDATOR_ADDR="0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"

# Fund validator (if needed)
cast send $WTON "transfer(address,uint256)" \
  $VALIDATOR_ADDR 2000000000000000000000000000000 \
  --private-key $DEPLOYER_KEY --rpc-url http://localhost:8545

# Approve WTON
cast send $WTON "approve(address,uint256)" $DEPOSIT_MANAGER \
  0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff \
  --private-key $VALIDATOR_KEY --rpc-url http://localhost:8545

# Stake 100 WTON
cast send $DEPOSIT_MANAGER \
  "deposit(address,uint256)" \
  $SYSTEM_CONFIG 100000000000000000000000000000 \
  --private-key $VALIDATOR_KEY --rpc-url http://localhost:8545
```

## Verification

### Check Rollup Registration

```bash
cast call 0x2dE080e97B0caE9825375D31f5D0eD5751fDf16D \
  "getRollupInfo(address)(uint8,address,bool,bool,string)" \
  0x577AcB7fA48878245a854ba51eD051a5B47cF83f \
  --rpc-url http://localhost:8545
```

Expected output:
```
3  # Type 3 = Optimism Bedrock DisputeGame
0xd55b55304b5cf7607B6dEd6DA6EeB487918AaD2E  # L2 TON
false  # rejectedSeigs
false  # rejectedL2Deposit
"Devnet L2"  # name
```

### Check Operator Staking

```bash
cast call 0xcA03Dc4665A8C3603cb4Fd5Ce71Af9649dC00d44 \
  "rollupConfigInfo(address)(uint8,address)" \
  0x577AcB7fA48878245a854ba51eD051a5B47cF83f \
  --rpc-url http://localhost:8545
```

### Check Validator Staking

```bash
cast call 0x90118d110B07ABB82Ba8980D1c5cC96EeA810d2C \
  "stakeOf(address,address)(uint256)" \
  0x577AcB7fA48878245a854ba51eD051a5B47cF83f \
  0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC \
  --rpc-url http://localhost:8545
```

## Test Accounts

All accounts are Anvil's default test accounts:

| Account | Address | Private Key | Role |
|---------|---------|-------------|------|
| #0 | 0xf39Fd...2266 | 0xac0974... | Deployer (Operator) |
| #1 | 0x70997...79C8 | 0x59c699... | TON Staking Deployer (Admin) |
| #2 | 0x3C44C...93BC | 0x5de411... | Validator |
| #3 | 0x90F79...3b906 | 0x47e179... | Validator 2 |
| #4 | 0x15d34...0A4dc | 0x8b3a35... | Proposer |

## Troubleshooting

### Blocks not being produced

**Symptom**: Transactions stuck as "pending", block number doesn't increase

**Cause**: Using Geth in Post-merge (PoS) mode without beacon client

**Solution**: Use Anvil instead of Geth
```bash
# Stop Geth
docker-compose down l1

# Start Anvil
anvil --port 8545 --chain-id 900 --block-time 1 \
  --init .devnet/genesis-l1-staking-v3.json
```

### RegisterError(2) when registering rollup

**Symptom**: `execution reverted: RegisterError(2)` (already registered)

**Possible causes**:
1. Rollup already registered - check with `getRollupInfo()`
2. Bridge/Portal/DisputeGameFactory already used by another rollup
3. Pending transactions in mempool

**Solution**: Wait for pending transactions to clear, or restart L1

### Gas limit exceeded

**Symptom**: `exceeds block gas limit`

**Cause**: Default gas limit too low for CandidateAddOn registration

**Solution**: Use Anvil (30M gas limit by default) instead of Geth (4.7M default)

### "minimum amount is required"

**Symptom**: Transaction reverts with "minimum amount is required"

**Cause**: Staking less than `minimumAmount` (1000.1 WTON)

**Solution**: Stake at least 1001 WTON:
```bash
# For operator
1001000000000000000000000000000  # 1001 WTON in wei (27 decimals)

# Check current minimum
cast call 0x0f5D1ef48f12b6f691401bfe88c2037c690a6afe \
  "minimumAmount()(uint256)" --rpc-url http://localhost:8545
```

## Advanced: Rollup Type Configuration

Rollup types are pre-configured in genesis:

| Type | Name | V3 Eligible | Bridge Pattern |
|------|------|-------------|----------------|
| 1 | Optimism Legacy | ❌ | ERC20 |
| 2 | Optimism Bedrock | ❌ | Native |
| 3 | Optimism Bedrock DisputeGame | ✅ | Native |

Type 3 is required for V3 features (RAT, fraud proofs, etc.)

## Next Steps

After setup is complete:

1. **Start RAT Clients**: Monitor and challenge invalid state proposals
   ```bash
   ./scripts/manage-rat-clients.sh start
   ```

2. **Start L2 Components**: op-node, op-batcher, op-proposer
   ```bash
   docker-compose up -d l2-execution l2-node l2-batcher l2-proposer
   ```

3. **Monitor System Health**:
   ```bash
   ./scripts/check-devnet-health.sh
   ```

## References

- [DeployV3FullForDevnet.s.sol](./script/DeployV3FullForDevnet.s.sol) - Genesis deployment script
- [L1BridgeRegistry](./src/layer2/L1BridgeRegistryV1_2.sol) - Rollup registration logic
- [Layer2Manager](./src/layer2/Layer2ManagerV3.sol) - Operator staking logic
- [RAT](./src/validator/RAT.sol) - Random assignment table
