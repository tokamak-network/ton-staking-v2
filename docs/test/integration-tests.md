# Integration Tests Guide

## Overview

Integration tests verify that multiple contracts work together correctly in complete scenarios. These tests deploy all contracts and simulate real-world workflows.

**Framework:** Foundry (Forge)
**Location:** `test/v3/V3ScenarioReal.t.sol`
**Total Tests:** 8
**Run Time:** ~5 seconds

## Running Integration Tests

### Run All Integration Tests

```bash
forge test --match-path test/v3/V3ScenarioReal.t.sol -vv
```

### Run Specific Scenario

```bash
# Complete V3 upgrade
forge test --match-test test_completeV3Scenario -vvv

# Multi-validator scenario
forge test --match-test test_multiValidatorScenario -vv
```

## Test Scenarios

### 1. Complete V3 Scenario

Full end-to-end V3 upgrade flow with all contracts.

```bash
forge test --match-test test_completeV3Scenario -vv
```

**Flow:**
```
1. Deploy all V3 contracts
   ├─ TON, WTON tokens
   ├─ SeigManagerV1_4
   ├─ DepositManager
   ├─ Layer2Manager
   ├─ RAT
   └─ ValidatorReward

2. Register Layer2
   ├─ Deploy Coinage
   └─ Register in Layer2Manager

3. Validator Registration
   ├─ Approve WTON for RAT
   └─ Register with collateral

4. Deposit & Seigniorage
   ├─ Deposit WTON
   ├─ Update seigniorage
   └─ Verify distribution

5. Withdrawal
   ├─ Request withdrawal
   ├─ Wait delay period
   └─ Process withdrawal

6. RAT Trigger
   ├─ Create dispute game
   ├─ Trigger RAT
   └─ Submit evidence
```

### 2. Multi-Validator Scenario

Multiple validators with concurrent operations.

```bash
forge test --match-test test_multiValidatorScenario -vv
```

**Tests:**
- Multiple validator registrations
- Concurrent deposits
- Seigniorage distribution among validators
- Different collateral amounts
- Validator slashing interactions

### 3. SequencerVault Integration

SequencerVault reward distribution.

```bash
forge test --match-test test_sequencerVaultIntegration -vv
```

**Tests:**
- SequencerVault deployment
- Reward accumulation
- Distribution to validators
- Integration with ValidatorReward

### 4. V2 to V3 Transition

Transition from V2 parameters to V3 parameters.

```bash
forge test --match-test test_v2ToV3Transition -vv
```

**Tests:**
- Initial state: V2 mode (λ=1, r=0.4)
- Parameter updates
- Seigniorage calculation differences
- Final state: V3 mode (λ=0, r=0)

### 5. Withdrawal Delay Enforcement

Withdrawal delay with multiple validators.

```bash
forge test --match-test test_withdrawalDelayEnforcement -vv
```

**Tests:**
- Request withdrawal
- Attempt early withdrawal (should fail)
- Wait for delay period
- Successful withdrawal after delay

### 6. Bridge Registry Integration

L1BridgeRegistry with DisputeGameFactory.

```bash
forge test --match-test test_bridgeRegistryIntegration -vv
```

**Tests:**
- Register L1 bridge
- Query bridge addresses
- DisputeGameFactory integration
- SystemConfig interactions

## Test Structure

### Setup Phase

```solidity
function setUp() public {
    // 1. Deploy tokens
    deployTokens();

    // 2. Deploy core contracts
    deployCoreContracts();

    // 3. Deploy RAT & bridges
    deployRATAndBridges();

    // 4. Initialize contracts
    initializeContracts();

    // 5. Setup test accounts
    setupTestAccounts();
}
```

### Test Pattern

```solidity
function test_completeV3Scenario() public {
    // === Phase 1: Setup ===
    registerLayer2();
    registerValidators();

    // === Phase 2: Operations ===
    depositStakes();
    updateSeigniorage();

    // === Phase 3: Verify ===
    verifyBalances();
    verifyRewards();

    // === Phase 4: Withdrawal ===
    requestWithdrawals();
    processWithdrawals();

    // === Phase 5: Final Verify ===
    verifyFinalState();
}
```

## Key Test Functions

### Layer2 Registration

```solidity
function registerLayer2() internal returns (address layer2) {
    layer2 = address(new MockLayer2());

    vm.prank(layer2Manager);
    layer2Manager.registerLayer2(
        layer2,
        operator,
        coinageFactory
    );

    return layer2;
}
```

### Validator Registration

```solidity
function registerValidator(address validator, uint256 collateral) internal {
    // Approve WTON for RAT
    vm.prank(validator);
    wton.approve(address(rat), collateral);

    // Register with collateral
    vm.prank(validator);
    rat.registerValidator(systemConfig, collateral);
}
```

### Deposit Stakes

```solidity
function depositStake(address validator, uint256 amount) internal {
    vm.prank(validator);
    wton.swapFromTONAndTransfer(validator, amount);

    vm.prank(validator);
    wton.approve(address(depositManager), amount);

    vm.prank(validator);
    depositManager.deposit(layer2, amount);
}
```

### Update Seigniorage

```solidity
function updateSeigniorage() internal {
    vm.warp(block.timestamp + seigPerBlock);

    vm.prank(address(this));
    seigManager.updateSeigniorage();
}
```

## Running Multiple Scenarios

### Run All Scenarios Sequentially

```bash
forge test --match-path test/v3/V3ScenarioReal.t.sol -vv
```

### Run Specific Scenarios

```bash
# Pattern matching
forge test --match-test "test_multi" -vv

# Multiple tests
forge test --match-test "test_complete|test_multi" -vv
```

## Debugging Integration Tests

### 1. Enable Detailed Logs

```bash
forge test --match-test test_completeV3Scenario -vvv
```

### 2. Add State Snapshots

```solidity
function test_scenario() public {
    logState("Initial");

    // ... operations ...

    logState("After Deposit");

    // ... more operations ...

    logState("Final");
}

function logState(string memory label) internal view {
    console.log("=== State:", label);
    console.log("TON Balance:", ton.balanceOf(address(this)));
    console.log("Validator Count:", rat.validatorCount());
}
```

### 3. Use Breakpoints

```solidity
// Add conditional logging
if (someCondition) {
    console.log("DEBUG: Unexpected state");
    console.log("Value:", value);
}
```

## Common Issues

### 1. Insufficient Approvals

**Error:** `ERC20: insufficient allowance`

**Fix:**
```solidity
// Approve before transfers
vm.prank(user);
token.approve(spender, amount);
```

### 2. Time-Based Failures

**Error:** Withdrawal delay not passed

**Fix:**
```solidity
// Advance time
skip(withdrawalDelay);
```

### 3. Access Control

**Error:** `Ownable: caller is not the owner`

**Fix:**
```solidity
// Use correct caller
vm.prank(owner);
contract.adminFunction();
```

## Verification Helpers

### Balance Verification

```solidity
function verifyBalances() internal view {
    assertEq(
        wton.balanceOf(validator),
        expectedBalance,
        "Validator balance mismatch"
    );
}
```

### State Verification

```solidity
function verifyState() internal view {
    assertTrue(
        rat.isRegistered(validator),
        "Validator should be registered"
    );

    assertGt(
        rat.collateral(validator),
        minCollateral,
        "Collateral too low"
    );
}
```

## Performance Tips

1. **Reuse Setup**: Use `setUp()` for common initialization
2. **Skip Time Efficiently**: Use `skip()` instead of multiple `warp()` calls
3. **Batch Operations**: Group related operations together
4. **Minimize Logging**: Remove `console.log()` in production tests

## Next Steps

- [Unit Tests Guide](./unit-tests.md) - Individual contract testing
- [E2E Tests Guide](./e2e-tests.md) - Go E2E testing
- [Coverage Matrix](./coverage-matrix.md) - Coverage details
