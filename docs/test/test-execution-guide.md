# Test Execution Guide

## Prerequisites

```bash
# Install Foundry (if not installed)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Install dependencies
forge install
```

## Running Tests

### All V3 Tests

```bash
# Run all tests in test/v3 directory
forge test --match-path "test/v3/*.sol"

# With verbose output (shows test names)
forge test --match-path "test/v3/*.sol" -v

# With very verbose output (shows traces on failure)
forge test --match-path "test/v3/*.sol" -vv

# With maximum verbosity (shows all traces)
forge test --match-path "test/v3/*.sol" -vvvv
```

### By Test File

```bash
# Basic staking functions
forge test --match-path test/v3/BasicFunctions.t.sol -vvv

# RAT (Validator collateral)
forge test --match-path test/v3/RAT.t.sol -vvv

# Seigniorage distribution
forge test --match-path test/v3/EndToEndSeigniorage.t.sol -vvv

# SeigManager V1.4 functions
forge test --match-path test/v3/SeigManagerV1_4Real.t.sol -vvv

# V3 complete scenario
forge test --match-path test/v3/V3ScenarioReal.t.sol -vvv

# Mainnet fork deployment
forge test --match-path test/v3/DeployV3Fork.t.sol -vvv
```

### By Test Function

```bash
# Single test
forge test --match-test test_updateSeigniorage -vvv

# Tests matching pattern
forge test --match-test "test_deposit" -vvv

# Exclude tests
forge test --match-path "test/v3/*.sol" --no-match-test "Fork"
```

### By Contract

```bash
# Tests in BasicFunctionsTest contract
forge test --match-contract BasicFunctionsTest -vvv

# Tests in RATTest contract
forge test --match-contract RATTest -vvv
```

## Test Categories

### 1. Core Staking Tests (BasicFunctions.t.sol)

| Test | Description |
|------|-------------|
| `test_registerLayer2` | Layer2 registration via operator |
| `test_registerLayer2_notOperator_reverts` | Non-operator cannot register |
| `test_deposit_wton` | Basic WTON deposit |
| `test_deposit_wton_multiple` | Multiple deposits accumulate |
| `test_deposit_ton_approveAndCall` | TON → WTON → Deposit in one tx |
| `test_requestWithdrawal` | Partial withdrawal request |
| `test_requestWithdrawal_full` | Full amount withdrawal |
| `test_processRequest` | Process withdrawal after delay |
| `test_processRequest_beforeDelay_reverts` | Cannot withdraw early |
| `test_updateSeigniorage` | Seigniorage via Layer2 callback |
| `test_updateSeigniorageLayer` | SeigManager initiates update |
| `test_fullScenario` | Complete: register→deposit→seigniorage→withdraw |

```bash
forge test --match-path test/v3/BasicFunctions.t.sol -vvv
```

### 2. RAT (Validator Collateral) Tests (RAT.t.sol)

| Test Category | Tests |
|---------------|-------|
| Validator Registration | `test_registerValidator_*` (5 tests) |
| Collateral Management | `test_addDeposit_*` (2 tests) |
| RAT Trigger | `test_triggerAttentionTest_*` (3 tests) |
| Evidence Submission | `test_submitEvidence_*` (3 tests) |
| Lazy Evaluation | `test_lazyEvaluation_*` (3 tests) |
| Game Resolution | `test_resolveClaim_*` (4 tests) |
| Multi-Game | `test_multipleGames*` (2 tests) |
| Governance | `test_set*` (6 tests) |

```bash
# All RAT tests
forge test --match-path test/v3/RAT.t.sol -vvv

# Only registration tests
forge test --match-path test/v3/RAT.t.sol --match-test "registerValidator" -vvv

# Only slashing tests
forge test --match-path test/v3/RAT.t.sol --match-test "lazyEvaluation" -vvv
```

### 3. Seigniorage Distribution Tests

```bash
# End-to-end seigniorage tests
forge test --match-path test/v3/EndToEndSeigniorage.t.sol -vvv

# Seigniorage formula tests
forge test --match-path test/v3/SeigniorageDistribution.t.sol -vvv
```

| Test | Description |
|------|-------------|
| `test_v2ModeDistribution` | V2 params (λ=1, r=0.4) |
| `test_v3FullModeDistribution` | V3 params (λ=0, r=0) |
| `test_transitionLambdaDecrease` | λ: 100%→75%→50%→25%→0% |
| `test_transitionRDecrease` | r: 40%→20%→10%→0% |
| `test_multipleL2Distribution` | Multi-L2 by bridged TON ratio |
| `test_ineligibleL2Excluded` | Below θ threshold excluded |
| `test_hyperbolicSaturationConvergence` | y(x) → L as x → ∞ |

### 4. V3 Scenario Tests (V3ScenarioReal.t.sol)

| Test | Description |
|------|-------------|
| `test_deployV3Full` | Full V3 deployment |
| `test_migrateToV3` | V3 migration execution |
| `test_registerType3Rollup` | TYPE 3 (DisputeGame) rollup |
| `test_sequencerCollateralDeposit` | Sequencer deposits to vault |
| `test_validatorDepositToRAT` | Validator registers collateral |
| `test_updateSeigniorageV3` | V3 seigniorage distribution |
| `test_validatorSlashing` | RAT slashing scenario |
| `test_fullV3Scenario` | Complete E2E scenario |

```bash
forge test --match-path test/v3/V3ScenarioReal.t.sol -vvv
```

### 5. Mainnet Fork Tests

```bash
# Requires RPC_MAINNET environment variable
export RPC_MAINNET="https://mainnet.infura.io/v3/YOUR_KEY"

forge test --match-path test/v3/DeployV3Fork.t.sol -vvv --fork-url $RPC_MAINNET
```

## Fuzz Testing

Some tests use fuzz testing for comprehensive coverage:

```bash
# Run fuzz tests with specific runs
forge test --match-test "testFuzz" -vvv

# Increase fuzz runs for more coverage
forge test --match-test "testFuzz" --fuzz-runs 1000 -vvv
```

| Fuzz Test | Description |
|-----------|-------------|
| `testFuzz_hyperbolicSaturation_bounded` | Saturation always ≤ L |
| `testFuzz_calculateSequencerReward` | Reward calculation bounds |
| `testFuzz_setGlobalWithdrawalDelay` | Delay parameter bounds |

## Gas Reporting

```bash
# Generate gas report
forge test --match-path "test/v3/*.sol" --gas-report

# Gas report for specific file
forge test --match-path test/v3/BasicFunctions.t.sol --gas-report
```

## Coverage Report

```bash
# Generate coverage report
forge coverage --match-path "test/v3/*.sol"

# Generate LCOV report for tools
forge coverage --match-path "test/v3/*.sol" --report lcov
```

## Troubleshooting

### Common Issues

**1. "same" error in setUp**
```
[FAIL: same] setUp()
```
Solution: Ensure parameters aren't already set to the same value. Check if `seigStartBlock`, `initialTotalSupply` are being set correctly.

**2. Arithmetic underflow/overflow**
```
panic: arithmetic underflow or overflow (0x11)
```
Solution: Ensure `seigStartBlock` is set to a value less than `block.number`. In tests, call `vm.roll(10)` before setting seigniorage parameters.

**3. InvalidCoinageError**
```
InvalidCoinageError()
```
Solution: Ensure Layer2 is registered with coinage before calling seigniorage functions. Use `layer2Registry.registerAndDeployCoinage()`.

**4. OperatorCollateral is insufficient**
```
OperatorCollateral is insufficient
```
Solution: Set `minimumAmount` to 0 in tests: `SeigManagerV1_2(seigManagerProxy).setMinimumAmount(0)`.

### Debug Tips

```bash
# Maximum trace verbosity
forge test --match-test test_failing -vvvvv

# Debug specific transaction
forge test --match-test test_failing -vvvv --debug

# Show storage changes
forge test --match-test test_failing -vvvv --show-storage
```

## Test Environment

Tests use DeployV3Full.s.sol for consistent deployment:

```solidity
contract MyTest is Test, DeployV3Full {
    function setUp() public {
        // Deploy all contracts
        _deployTokens();
        _deployCoinageInfrastructure(owner);
        _deployLayer2Registry(owner);
        _deployManagerProxies();
        _deployManagerImplementations();
        _initializeManagers(owner);
        _setupMinterPermissions();
        _deployOperatorManagerFactory(owner);
        _deployV3Contracts(owner);
        _configureV3Contracts(owner);
        _setupCrossReferences(owner);

        // Configure for testing
        vm.roll(10);
        SeigManagerV1_2(seigManagerProxy).setSeigStartBlock(1);
        SeigManagerV1_2(seigManagerProxy).setInitialTotalSupply(50_000_000 * 1e27);
        SeigManagerV1_2(seigManagerProxy).setBurntAmountAtDAO(1);
    }
}
```

## CI/CD Integration

```yaml
# GitHub Actions example
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: foundry-rs/foundry-toolchain@v1
      - run: forge test --match-path "test/v3/*.sol" -vvv
```

---

## Go E2E Tests

For Go E2E tests (RAT integration with Optimism), see [Go E2E Test Guide](./go-e2e-test-guide.md).
