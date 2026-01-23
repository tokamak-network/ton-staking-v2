# Slashing E2E Scenario 3 Walkthrough: Re-staking after Slashing

## Objective
Verify the complete lifecycle of a validator being slashed and then recovering by re-staking.
Key validation points:
1.  **Slashing Execution**: Operator stake reduced to 0.
2.  **Seigniorage Halt**: No rewards accrue on 0 stake.
3.  **Re-staking**: Operator can deposit WTON again to the *same* candidate.
4.  **Resumption**: Verification that seigniorage accrual resumes properly after re-staking.

## Implementation Details

### Test Case: `TestSlashing_ReRegistrationAfterSlashing`
Located in `op-e2e/slashing/slashing_test.go`.

#### Key Steps:
1.  **Register Operator**: Standard registration with 10,000 TON stake.
2.  **Execute Slashing**:
    *   Creates a Fault Dispute Game.
    *   Challenger wins efficiently.
    *   `Layer2Manager` executes slashing via `DepositManager`.
    *   **Assertion**: Operator stake becomes 0.
3.  **Verify No Accrual**:
    *   Advance time 14 days.
    *   **Assertion**: Stake remains 0.
4.  **Re-staking**:
    *   Operator (Validator) swaps TON for WTON.
    *   **Configuration**: Adjusted `reStakeAmount` to 10,000 WTON (27 decimals) to match `SeigManager` requirements (RAY).
    *   **Action**: Calls `DepositManager.Deposit1(candidateAddOn, operatorManager, amount)`.
    *   **Assertion**: Stake balance restored to >= 10,000 WTON.
5.  **Verify Resumption**:
    *   **Advance Blocks**: Mine 1000 blocks (`AdvanceBlocks`) to allow seigniorage generation.
    *   **Trigger Update**: Explicitly call `CandidateAddOn.updateSeigniorage()` to update the coinage state.
    *   **Assertion**: Verify that the operator's total stake (Principal + Seigniorage) is greater than the re-staked principal.
    *   *Note*: Used `getStakeWithSeigniorage` helper to query `SeigManager.stakeOf` which properly includes accrued rewards (unlike `DepositManager.accStaked`).

### Challenges & Solutions

#### 1. Deposit Amount Precision
*   **Issue**: `minimum amount is required` revert.
*   **Cause**: Test was sending `10,000 * 10^18` (TON decimals) as WTON amount. `SeigManager` expects WTON/RAY (27 decimals) for the check.
*   **Fix**: Updated `reStakeAmount` to use `10^27` scaling. Implemented proper conversion logic.

#### 2. Validator vs Operator Account
*   **Issue**: `OperatorCollateral is insufficient`.
*   **Cause**: Initial attempt used `Deposit` (msg.sender), but twisted logic required `Deposit1` to target `operatorManager`.
*   **Fix**: Used `Deposit1(layer2, operatorManager, amount)` to correctly credit the operator contract.

#### 3. Seigniorage Update Revert (Critical Fix)
*   **Issue**: `CandidateAddOn.updateSeigniorage()` transaction was reverting.
*   **Cause**: `SeigManager` was missing the `l1BridgeRegistry` address configuration. The `updateSeigniorage` logic attempts to fetch `layer2TVL` from `l1BridgeRegistry`, causing a revert when called on a zero address.
*   **Fix**: Updated `DeployV3SlashForDevnet.s.sol` (and `DeployV3FullSlash.s.sol`) to explicitly call `SeigManager.setL1BridgeRegistry(l1BridgeRegistryProxy)`. Regenerated genesis to include this configuration.

#### 4. Seigniorage Verification
*   **Issue**: Initial checks using `accStaked` showed no increase because it only tracks principal.
*   **Cause**: `accStaked` (DepositManager) does not reflect seigniorage. `SeigManager.stakeOf` must be used.
*   **Resolution**: Implemented `getStakeWithSeigniorage` helper function to query `SeigManager.stakeOf` via raw ABI binding (since `stakeOf(address,address)` wasn't exposed in generated bindings). Confirmed seigniorage increase.

## Verification Results

### Test Execution
```bash
go test -v ./slashing -run TestSlashing_ReRegistrationAfterSlashing
```

### Output Log (Summary)
```
slashing_test.go:356: ✓ Operator stake is 0
slashing_test.go:370: ✓ No seigniorage accrued (stake remains 0)
slashing_test.go:413: ✓ Re-staked 10000000000000000000000000000000 WTON to OperatorManager
slashing_test.go:515: ✓ Mined 1000 blocks
slashing_test.go:505: [OK] Seigniorage update called successfully
slashing_test.go:462: Operator Stake with Seigniorage (After 1000 Blocks): 10000000001991759693818378540000
slashing_test.go:470: ✓ Seigniorage increased: 1991759693818378540000
slashing_test.go:471: [OK] Re-registered operator can earn seigniorage
slashing_test.go:473: ✅ Test Passed: Re-staking and seigniorage verification complete
```

## Conclusion
Scenario 3 is **Complete**. The system correctly handles slashing, allows re-staking, and successfully resumes seigniorage distribution.
