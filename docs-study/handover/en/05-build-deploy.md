# 5. Build & Deployment Pipeline

## Solidity Compilation

```bash
# TON Staking V2 Contracts
forge build

# Optimism Contracts
cd lib/optimism/packages/contracts-bedrock
forge build --skip test
```

### FaultDisputeGame Size Optimization

In `foundry.toml`, `optimizer_runs = 200` is set specifically for `FaultDisputeGame` (default 999,999).

| Contract | Size | Margin |
|----------|------|--------|
| FaultDisputeGame (Before) | ~24,907 bytes | -331 (Exceeded) |
| FaultDisputeGame (After Modification) | 24,102 bytes | **+474** |
| WinningChallengerTracker | 1,203 bytes | +23,373 |

> **Warning**: With only a +474 byte margin, be careful of size limits when inserting additional logic into `FaultDisputeGame`.

---

## Go Pipeline

Files modified to pass the `WinningChallengerTracker` address to the deployment pipeline:

### ChainProofParams (Intent)

```go
// op-deployer/pkg/deployer/state/chain_intent.go
type ChainProofParams struct {
    RatAddress                      common.Address
    WinningChallengerTrackerAddress common.Address  // Added
}
```

### DeployOPChainInput

```go
// op-deployer/pkg/deployer/opcm/opchain.go
type DeployOPChainInput struct {
    // ...
    RatAddress                      common.Address
    WinningChallengerTrackerAddress common.Address  // Added
}
```

### Pipeline Passing

```go
// op-deployer/pkg/deployer/pipeline/opchain.go
func makeDCI(...) opcm.DeployOPChainInput {
    return opcm.DeployOPChainInput{
        // ...
        WinningChallengerTrackerAddress: intent.WinningChallengerTrackerAddress,
    }
}
```

### Devnet Allocs

```go
// op-chain-ops/cmd/devnet-allocs/main.go
GlobalDeployOverrides: map[string]any{
    "deployWinningChallengerTracker": true,
}
```

### OPContractsManager

```solidity
// lib/optimism/.../src/L1/OPContractsManager.sol
// Added winningChallengerTrackerAddress to DeployInput
// Automatically sets in DisputeGameFactory within deploy() function
```

---

## Generating Devnet Allocs

```bash
cd lib/optimism
just devnet-allocs
```

> **Note**: `make devnet-allocs-offline` might not have a target in `lib/optimism`. The correct command is `just devnet-allocs`.

### Resolving Blueprint Issue

When generating devnet allocs, if `FaultDisputeGame` initcode size is smaller than the Blueprint split threshold (23,500 bytes), the second Blueprint address drops to `address(0)`, causing a `NotABlueprint()` error.

**Solution**: Added the `deployFromBlueprint()` helper function to `OPContractsManagerBase` to call the 1-address version if the second Blueprint address is `address(0)`.

Locations applied:
- `OPContractsManagerGameTypeAdder.addGameType()`
- `OPContractsManagerUpgrader.deployAndSetNewGameImpl()`
- `OPContractsManagerDeployer.deploy()`
- `OPContractsManagerInteropDeployer` (SuperPermissionedDisputeGame, SuperFaultDisputeGame)

---

## Deployment Script

**File**: `script/DeployV3WithSlashingForDevnet.s.sol`

Devnet deployment script including V3 migration logic:

```solidity
function run() public override {
    // ... Existing deployment logic ...

    // V3 Migration (after all setup is complete)
    _setupV3ParameterSelectors();  // Register V3 setter selectors
    _setV3Parameters();            // Set V3 parameters
    _migrateToV3();                // Execute V3 migration

    vm.stopBroadcast();
}
```

**Deployed Addresses File**: `deployments/v3-devnet-slashing.json`

---

Next: [06-testing.md](./06-testing.md)
