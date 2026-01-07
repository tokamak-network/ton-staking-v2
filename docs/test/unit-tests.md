# Unit Tests Guide

## Overview

Unit tests verify individual contract functions using Foundry. These tests are fast, isolated, and require no external dependencies.

**Framework:** Foundry (Forge)
**Location:** `test/v3/*.sol`
**Total Tests:** 150+
**Run Time:** ~10 seconds

## Running Unit Tests

### Run All Unit Tests

```bash
forge test --match-path "test/v3/*.sol"
```

### Run Specific Test File

```bash
# RAT tests only
forge test --match-path test/v3/RAT.t.sol

# Seigniorage tests only
forge test --match-path test/v3/SeigniorageDistribution.t.sol

# Basic functions
forge test --match-path test/v3/BasicFunctions.t.sol
```

### Run Specific Test Function

```bash
# Single test with verbose output
forge test --match-test test_registerValidator -vvv

# Test with specific pattern
forge test --match-test "test_deposit" -vv
```

### Run with Different Verbosity

```bash
# -v: Show test results
forge test --match-path "test/v3/*.sol" -v

# -vv: Show console.log output
forge test --match-path "test/v3/*.sol" -vv

# -vvv: Show execution traces
forge test --match-test test_slashValidator -vvv

# -vvvv: Show execution traces with stack
forge test --match-test test_slashValidator -vvvv
```

## Test Files

### 1. BasicFunctions.t.sol (12 tests)

Core staking mechanics: deposit, withdrawal, seigniorage.

```bash
forge test --match-path test/v3/BasicFunctions.t.sol -vv
```

**Tests:**
- Layer2 registration
- TON/WTON deposits
- Seigniorage updates
- Withdrawal requests
- Withdrawal processing
- V2/V3 mode transitions

### 2. RAT.t.sol (40+ tests)

Validator collateral and RAT (Randomized Attention Test) logic.

```bash
forge test --match-path test/v3/RAT.t.sol -vv
```

**Tests:**
- Validator registration with collateral
- RAT trigger on game creation
- Evidence submission
- Slashing mechanisms
- Bond calculations
- Multi-game scenarios
- Validator recovery

**Key Test Examples:**
```bash
# Validator registration
forge test --match-test test_registerValidator -vvv

# Slashing logic
forge test --match-test test_slashValidator -vvv

# Evidence submission
forge test --match-test test_submitEvidence -vvv
```

### 3. SeigniorageDistribution.t.sol (50+ tests)

Seigniorage formula validation and distribution logic.

```bash
forge test --match-path test/v3/SeigniorageDistribution.t.sol -vv
```

**Tests:**
- Hyperbolic saturation formula
- Distribution calculations
- V2 vs V3 mode differences
- Parameter transitions (λ, r)
- Edge cases and boundaries

### 4. SeigManagerV1_4Real.t.sol (24 tests)

SeigManager V1.4 specific functions.

```bash
forge test --match-path test/v3/SeigManagerV1_4Real.t.sol -vv
```

**Tests:**
- Seigniorage calculation
- Operator management
- Parameter updates
- Commission rates

### 5. DepositManagerV1_2Real.t.sol (14 tests)

Deposit and withdrawal mechanics.

```bash
forge test --match-path test/v3/DepositManagerV1_2Real.t.sol -vv
```

**Tests:**
- Deposit flows
- Withdrawal delays
- Request processing
- Balance tracking

### 6. ValidatorRewardV1.t.sol

Validator reward distribution.

```bash
forge test --match-path test/v3/ValidatorRewardV1.t.sol -vv
```

**Tests:**
- Reward calculations
- Distribution logic
- Claim mechanisms

### 7. L1BridgeRegistryV1_2Real.t.sol

L1 bridge integration with DisputeGameFactory.

```bash
forge test --match-path test/v3/L1BridgeRegistryV1_2Real.t.sol -vv
```

**Tests:**
- Bridge registration
- DisputeGameFactory integration
- Query mechanisms

## Test Patterns

### Setup Pattern

Most tests follow this pattern:

```solidity
function setUp() public {
    // 1. Deploy mocks
    ton = new MockTON();
    wton = new MockWTON();

    // 2. Deploy contracts
    seigManager = new SeigManagerV1_4();
    rat = new RAT();

    // 3. Initialize
    seigManager.initialize(...);

    // 4. Setup test accounts
    vm.deal(validator, 100 ether);
}
```

### Test Pattern

```solidity
function test_featureName() public {
    // 1. Arrange: Setup test conditions
    uint256 amount = 1000 * 1e18;

    // 2. Act: Execute function
    vm.prank(validator);
    rat.registerValidator(amount);

    // 3. Assert: Verify results
    assertTrue(rat.isRegistered(validator));
    assertEq(rat.collateral(validator), amount);
}
```

## Common Test Utilities

### Foundry Cheatcodes

```solidity
// Impersonate account
vm.prank(address);        // Next call only
vm.startPrank(address);   // All subsequent calls
vm.stopPrank();

// Time manipulation
vm.warp(timestamp);       // Set block.timestamp
skip(seconds);            // Advance time

// Expectations
vm.expectRevert("Error");
vm.expectEmit(true, true, false, true);

// Balance
vm.deal(address, amount);

// Logging
console.log("Message");
console.log("Value:", value);
```

### Custom Assertions

```solidity
// Standard assertions
assertEq(actual, expected);
assertTrue(condition);
assertFalse(condition);
assertGt(a, b);   // a > b
assertLt(a, b);   // a < b

// With custom error messages
assertEq(actual, expected, "Should be equal");
```

## Running Tests with Gas Reports

```bash
# Generate gas report
forge test --match-path "test/v3/*.sol" --gas-report

# Save to file
forge test --match-path "test/v3/*.sol" --gas-report > gas-report.txt
```

## Running Tests with Coverage

```bash
# Generate coverage report
forge coverage --match-path "test/v3/*.sol"

# Generate detailed report
forge coverage --match-path "test/v3/*.sol" --report summary
```

## Debugging Failed Tests

### 1. Increase Verbosity

```bash
# Show traces
forge test --match-test test_failingTest -vvvv
```

### 2. Use console.log

```solidity
import "forge-std/console.sol";

function test_debug() public {
    console.log("Before:", balance);
    // ... code ...
    console.log("After:", balance);
}
```

### 3. Isolate the Test

```bash
# Run only the failing test
forge test --match-test test_specificFailingTest -vvv
```

## Tips

1. **Start Small**: Run single test first, then expand
2. **Use Verbosity**: `-vv` for logs, `-vvv` for traces
3. **Check Reverts**: Use `vm.expectRevert()` for expected failures
4. **Gas Optimization**: Use `--gas-report` to identify expensive operations
5. **Parallel Testing**: Forge runs tests in parallel by default

## Next Steps

- [Integration Tests Guide](./integration-tests.md) - Full scenario testing
- [E2E Tests Guide](./e2e-tests.md) - Go E2E testing
- [Coverage Matrix](./coverage-matrix.md) - Coverage details
