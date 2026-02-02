# Configuration Files for Devnet

This directory contains pre-configured files for devnet deployment from **tokamak-network/optimism** repository.

All files are generated from: https://github.com/tokamak-network/optimism/tree/feature/ton-staking-v3

## Files

### devnetL1.json

L1/L2 configuration file for Optimism devnet with TON Staking V3 integration.

### Source
This file is generated from **tokamak-network/optimism** repository, `feature/ton-staking-v3` branch:
- Repository: https://github.com/tokamak-network/optimism/tree/feature/ton-staking-v3
- Generated using: `just devnet-allocs`

The TON Staking V3-specific Optimism fork includes RAT integration and custom devnet configurations.

### Key Settings
- **L1 Chain ID**: 900
- **L2 Chain ID**: 901
- **RAT Integration**: Enabled (`deployRAT: true`)
- **RAT Parameters**:
  - `ratTriggerProbability`: 100000
  - `evidenceSubmissionPeriod`: 600
  - `minimumStakingBalance`: 1000000000000000000

### Usage
This file is automatically copied to `.devnet/devnetL1.json` during `make devnet-allocs-offline`.

### Updating
If you need to regenerate this file:
1. Clone the Optimism fork: `git clone -b feature/ton-staking-v3 https://github.com/tokamak-network/optimism.git`
2. Run `cd optimism && just devnet-allocs`
3. Copy the generated `.devnet/devnetL1.json` to this directory (`scripts/config/`)
4. Commit the updated file to git

Alternatively, if `lib/optimism` is properly configured:
1. Run `cd lib/optimism && just devnet-allocs`
2. Copy `.devnet/devnetL1.json` to `scripts/config/`

### optimism-addresses.json

Contract addresses deployed by Optimism devnet (DisputeGameFactory, SystemConfig, etc.).

**Size**: ~1.7KB

### optimism-allocs-l1.json

L1 genesis allocations (account states) for Optimism contracts.

**Size**: ~1.3MB
**Note**: Large file, but necessary for offline genesis generation.

## Why are these files committed?

To eliminate external dependencies and enable **fully offline devnet setup**:
- No need for `just` command
- No need for Go toolchain
- No need for `lib/optimism` directory
- Faster and more reliable devnet generation
- Reproducible builds

## Complete Workflow

### Normal Usage (Offline)
```bash
make devnet-allocs-offline  # Uses pre-configured files from scripts/config/
```

### Regenerating Config Files (When Optimism Updates)
```bash
# Clone the TON Staking V3-specific Optimism fork
git clone -b feature/ton-staking-v3 https://github.com/tokamak-network/optimism.git

# Generate devnet allocs
cd optimism && just devnet-allocs

# Copy to ton-staking-v2 project
cp .devnet/devnetL1.json ../ton-staking-v2/scripts/config/
cp .devnet/addresses.json ../ton-staking-v2/scripts/config/optimism-addresses.json
cp .devnet/allocs-l1.json ../ton-staking-v2/scripts/config/optimism-allocs-l1.json

# Commit updated files
cd ../ton-staking-v2
git add scripts/config/*.json
git commit -m "chore: update Optimism devnet config files"
```
