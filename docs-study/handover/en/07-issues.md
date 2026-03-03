# 7. Resolved Issues & Limitations

## Key Resolved Issues

### Issue 1: Exceeding FaultDisputeGame EVM 24KB Limit

- **Symptom**: Exceeding the EIP-170 limit of 24KB, expanding to 24,907 bytes when adding the WinningChallenger tracking logic (mapping + array + view functions).
- **Cause**: Bytecode increase due to ratio-based RAT related logic + WinningChallengerTracker integration logic.
- **Resolution**:
  1. Separated the `WinningChallengerTracker` into an **external contract** (1,203 bytes).
  2. Reduced `optimizer_runs` exclusively for `FaultDisputeGame` from 999,999 → **200** in `foundry.toml`.
  3. Removed view functions inside the `FaultDisputeGame` (e.g., `getWinningChallengers`).
- **Result**: Reduced to 24,102 bytes (Margin +474 bytes).

---

### Issue 2: devnet-allocs NotABlueprint Panic

- **Symptom**: `NotABlueprint()` error during the `DeployImplementations` phase when running `just devnet-allocs`.
- **Cause**: The `FaultDisputeGame` initcode size (22,216 bytes) was smaller than the Blueprint split threshold (23,500 bytes), dropping the second Blueprint address to `address(0)`. Error occurred when trying to call `Blueprint.deployFrom(addr1, address(0))` on empty code.
- **Resolution**: Added the `deployFromBlueprint()` helper function to `OPContractsManagerBase`. Handled the 1-address version if the second Blueprint address is `address(0)`.
- **Locations Applied**:
  - `OPContractsManagerGameTypeAdder.addGameType()` - line 501
  - `OPContractsManagerUpgrader.deployAndSetNewGameImpl()` - line 936, 948
  - `OPContractsManagerDeployer.deploy()` - line 1078, 1103
  - `OPContractsManagerInteropDeployer` - SuperPermissionedDisputeGame, SuperFaultDisputeGame
- **Verification**: `just devnet-allocs` executed successfully, with allocs files correctly generated in the `.devnet/` directory.

---

### Issue 3: V3 Migration Not Executed

- **Symptom**: `TestSlashing_ReRegistrationAfterSlashing` test failed. Met with `V2DelegatecallFailedError (0x1b53d9e5)`.
- **Cause**: In the Genesis file, `v3Migrated = false`. Deployment script modifications were completed but before Genesis regenerations.
- **Call Stack**: `CandidateAddOn.updateSeigniorage()` → `SeigManager.updateSeigniorage()` → `SeigManagerV3_1._updateSeigniorageV2Delegatecall()` → `SeigManagerV3_2.updateSeigniorageV2()` [delegatecall] FAIL
- **Resolution**: Added V3 migration logic to `DeployV3WithSlashingForDevnet.s.sol`:
  - `_setupV3ParameterSelectors()`: Registered V3 setter selectors.
  - `_setV3Parameters()`: Set V3 parameters (k, θ, d, α, etc.).
  - `_migrateToV3()`: V3 Activation.
- **Status**: Deployment script modifications completed. Expected to operate normally after regenerating Genesis (`just devnet-allocs`).

---

### Issue 4: getStakeBalance Compatibility

- **Symptom**: `DepositManager.accStaked()` deprecated in V3.
- **Resolution**: Used `SeigManager.stakeOf()` in `op-e2e/slashing/slashing_helpers.go` instead.

---

## Known Limitations

| # | Limitation | Description |
|---|------------|-------------|
| 1 | **Size Margin** | `FaultDisputeGame` only has a +474 byte margin. Be cautious of exceeding limits when inserting additional logic. |
| 2 | **Go Workspace** | Tests using the `lib/optimism` package require `op-e2e/go.work`. Mock tests need to run with `GOWORK=off`. |
| 3 | **Kona prestate** | Kona prestate files are necessary when doing faultproof tests of lib/optimism (Dummy OK for Alphabet). |
| 4 | **Docker** | Docker Desktop needs to be running for Full Optimism devnet tests. |
| 5 | **Regenerate Genesis** | `just devnet-allocs` must be run again after modifying contracts. |
| 6 | **V3 Migration** | `updateSeigniorage()` functions properly only when `v3Migrated = true` state in Genesis. |
| 7 | **Multi-Challenger Resolution** | Potential for the second claim to conflict with the first during multiple Challenger attacks in `MockFaultDisputeGame3`. Functions fine in the actual `FaultDisputeGame`. |
| 8 | **Minimum Stake** | Stake greater than the `minimumAmount` set in Genesis is required for Operator registration. |

---

Next: [08-file-map.md](./08-file-map.md)
