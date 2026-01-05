# Optimism L1 Deployment Verification System

## Overview

This document describes the verification system that ensures Optimism L1 contracts are properly deployed before attempting to integrate TON Staking V3 system.

## Problem Statement

Previously, the deployment workflow could fail silently when:
1. DisputeGameFactory address was in addresses.json but not in allocs-l1.json
2. Optimism contracts weren't properly deployed when Anvil started
3. Integration failures only appeared during V3 deployment, after significant setup time

## Solution

A two-stage verification system that validates Optimism L1 deployment:

### 1. Allocs Verification (`verify-optimism-deployment.sh`)

**When**: After copying devnet state from lib/optimism, before starting Anvil

**What it checks**:
- All critical Optimism contracts exist in addresses.json
- All critical contract addresses are in allocs-l1.json
- Each contract has actual bytecode (not empty)

**Critical contracts verified**:
- DisputeGameFactory & DisputeGameFactoryProxy
- OptimismPortal & OptimismPortalProxy
- SystemConfig & SystemConfigProxy
- L1CrossDomainMessenger & L1CrossDomainMessengerProxy
- L1StandardBridge & L1StandardBridgeProxy

**Output**:
```
✓ DisputeGameFactory
  Address: 0x0298dd8babce73e3211da1a3582fbf0d400b97ab
✓ DisputeGameFactoryProxy
  Address: 0x71740f4dca6a4d034758f71505e89d9d079552cf
...
Summary: 10 found, 0 missing out of 10 critical contracts
```

### 2. Runtime Verification (`verify-runtime-deployment.sh`)

**When**: After Anvil starts, before deploying V3 system

**What it checks**:
- Anvil is running and responding to RPC calls
- Each critical contract address has bytecode on the running chain
- Contract code length is non-zero

**Output**:
```
✓ Anvil is running
  RPC: http://localhost:8545
  Chain ID: 900

✓ DisputeGameFactoryProxy
  Address: 0x71740f4dca6a4d034758f71505e89d9d079552cf
  Code length: 1234 bytes
...
Summary: 5 deployed, 0 missing out of 5 critical contracts
```

## Integration with devnet-allocs.sh

The verification scripts are automatically called during `make devnet-allocs`:

```
[1/4] Copying devnet state from lib/optimism...
  Copied devnet state
  Verifying Optimism L1 contracts in allocs...     # <- Allocs verification
  ✓ All critical contracts found

[2/4] Starting L1 devnet...
  Anvil started (PID: 12345)
  L1 devnet ready (Chain ID: 900)
  Verifying Optimism contracts on running Anvil... # <- Runtime verification
  ✓ All critical contracts deployed

[3/4] Deploying TON Staking V3 Full System...
  ...
```

If verification fails at any stage, the script exits immediately with a helpful error message.

## Manual Verification Commands

### Verify allocs before starting Anvil
```bash
make devnet-verify-allocs
```

### Verify contracts on running Anvil
```bash
make devnet-verify-runtime
```

## Error Scenarios

### Missing contracts in allocs
```
✗ DisputeGameFactoryProxy: Not in allocs-l1.json
  Address: 0x71740f4dca6a4d034758f71505e89d9d079552cf

⚠ WARNING: Some critical Optimism contracts are missing!

Troubleshooting:
  1. Check if lib/optimism devnet-allocs completed successfully
  2. Try: make devnet-clean && make devnet-allocs-optimism
  3. Check lib/optimism submodule is on correct branch/commit
```

**Fix**: Run `make devnet-clean && make devnet-allocs-optimism`

### Missing contracts at runtime
```
✗ DisputeGameFactoryProxy: No code at address
  Address: 0x71740f4dca6a4d034758f71505e89d9d079552cf

⚠ WARNING: Some contracts are not deployed on Anvil!
This indicates allocs-l1.json may not have loaded correctly.

Troubleshooting:
  1. Stop anvil: make devnet-down
  2. Clean and restart: make devnet-clean && make devnet-allocs
  3. Check anvil logs: tail -f .devnet/anvil.log
```

**Fix**: Full reset with `make devnet-clean && make devnet-allocs`

## Benefits

1. **Fast Failure**: Catches deployment issues in seconds, not minutes
2. **Clear Errors**: Pinpoints exact contract and address that's missing
3. **Actionable Guidance**: Provides specific troubleshooting steps
4. **Confidence**: Guarantees Optimism contracts are ready before V3 deployment
5. **Debugging**: Standalone commands help diagnose issues at any time

## Files

- `scripts/verify-optimism-deployment.sh` - Allocs verification script
- `scripts/verify-runtime-deployment.sh` - Runtime verification script
- `scripts/devnet-allocs.sh` - Main deployment script (calls both verifications)
- `Makefile` - Targets for `devnet-verify-allocs` and `devnet-verify-runtime`
- `TESTING_GUIDE.md` - User documentation with examples
