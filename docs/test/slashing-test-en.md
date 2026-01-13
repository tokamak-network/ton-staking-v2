# Slashing Mechanism Test Guide

## Table of Contents
- [Overview](#overview)
- [Test Environment](#test-environment)
- [Deployment Process](#deployment-process)
- [Test Scenarios](#test-scenarios)
- [How to Run Tests](#how-to-run-tests)
- [Test Results Analysis](#test-results-analysis)

---

## Overview

This document describes a comprehensive test suite for the TON Staking V3 slashing mechanism. Slashing is a critical security mechanism that penalizes operators for malicious or inaccurate behavior and rewards challengers who detect such behavior.

### Test File Locations
- **Test File**: `test/Slashing/SlashingTest.t.sol`
- **Deployment Script**: `script/DeployV3FullSlash.s.sol`
- **Slashing Contracts**:
  - `src/layer2/Layer2Manager_Slashing.sol`
  - `src/stake/managers/DepositManager_Slashing.sol`
  - `src/stake/managers/SeigManager_Slashing.sol`

### Test Coverage
- **Total Tests**: 20
- **Pass Rate**: 100% (20/20)
- **Test Categories**:
  - Basic Functionality: 2 tests
  - Reward Rate Tests: 4 tests
  - Seigniorage Tests: 2 tests
  - Security Tests: 5 tests
  - Edge Case Tests: 4 tests
  - **Delegator Protection Tests: 3 tests**

---

## Test Environment

### Required Tools
- **Foundry**: Solidity testing framework
  - `forge`: Compilation and test execution
  - `anvil`: Local Ethereum node (optional)
- **Solidity**: v0.8.19
- **Node.js**: v16+ (optional)

### Contract Dependencies
The tests deploy and configure the following contracts:

#### Core Contracts
1. **Token Contracts**
   - `MockTON`: Test TON token
   - `MockWTON`: Test Wrapped TON

2. **Manager Contracts**
   - `Layer2Manager`: Layer2 operator management
   - `DepositManager`: Staking deposit management
   - `SeigManager`: Seigniorage (interest) management
   - `L1BridgeRegistry`: L1-L2 bridge registration

3. **DAO Contracts**
   - `DAOVault`: DAO treasury management
   - `DAOAgendaManager`: Agenda management
   - `DAOCommittee`: DAO committee

4. **Factory Contracts**
   - `CandidateFactory`: Candidate creation
   - `CandidateAddOnFactory`: CandidateAddOn creation
   - `OperatorManagerFactory`: OperatorManager creation

#### Mock Contracts
1. **MockDisputeGameFactory**: Dispute Game creation factory
2. **MockFaultDisputeGame2**: Fault Dispute Game simulation
3. **SlashingMockFactory**: Slashing test factory
4. **SlashingMockGame**: Slashing test game

### Test Configuration Parameters

```solidity
// Slashing reward rate (default)
uint256 SLASHING_REWARD_RATE = 1000; // 10% (basis points)

// Staking amounts
uint256 DEFAULT_STAKE = 10000 * 1e18; // 10,000 TON
uint256 MINIMUM_STAKE = 1000 * 1e18;  // 1,000 TON

// Test accounts
address operator;    // Operator
address challenger;  // Challenger
address daoCommitteeProxy; // DAO Committee
```

---

## Deployment Process

### 1. Initial Setup (setUp)

The test's `setUp()` function performs the following steps:

#### Step 1-2: Basic Account Setup
```solidity
admin = makeAddr("proxyAdmin");
owner = address(this);
operator = makeAddr("operator");
challenger = makeAddr("challenger");
```

#### Step 3-4: Token Deployment
```solidity
// Deploy MockTON (initial supply: 50,000,000 TON)
ton = address(new MockTON());

// Deploy MockWTON and connect to TON
wton = address(new MockWTON());
MockWTON(wton).setTON(ton);
```

#### Step 5-6: Coinage Infrastructure Deployment
```solidity
// Deploy RefactorCoinageSnapshot
refactorCoinageSnapshot = new RefactorCoinageSnapshot();

// Deploy and configure CoinageFactory
coinageFactory = new CoinageFactory();
coinageFactory.setAutoCoinageLogic(refactorCoinageSnapshot);
```

#### Step 7: Layer2Registry Deployment
```solidity
layer2RegistryImpl = new Layer2Registry();
layer2RegistryProxy = new Layer2RegistryProxy();
Layer2RegistryProxy(payable(layer2RegistryProxy)).upgradeTo(layer2RegistryImpl);
```

#### Step 8-10: Manager Contract Deployment
```solidity
// Deploy SeigManager (V1_2, V1_3, Slashing versions)
seigManagerImpl = new SeigManagerV1_2();
seigManagerProxy = new SeigManagerProxy();

// Deploy DepositManager (including Slashing version)
depositManagerImpl = new DepositManager();
depositManagerProxy = new DepositManagerProxy();

// Deploy Layer2Manager (including Slashing version)
layer2ManagerImpl = new Layer2ManagerV1_1();
layer2ManagerProxy = new Layer2ManagerProxy();
```

#### Step 11-13: DAO Contract Deployment
```solidity
// Deploy DAOVault
daoVault = deployCode("./abis/DAOVault.json", ...);

// Deploy DAOAgendaManager
daoAgendaManager = deployCode("./abis/DAOAgendaManager.json", ...);

// Deploy DAOCommittee (Proxy2 + Proxy structure)
daoCommitteeProxy = deployCode("./abis/DAOCommitteeProxy.json", ...);
```

#### Step 14: Minter Permission Setup
```solidity
// Grant MINTER_ROLE to DAOCommittee in Layer2Registry
Layer2Registry(layer2RegistryProxy).grantRole(MINTER_ROLE, daoCommitteeProxy);
```

#### Step 15: SeigManager Configuration
```solidity
// Set SeigManager data and start block
SeigManagerV1_2(seigManagerProxy).setData(...);
SeigManagerV1_2(seigManagerProxy).setSeigStartBlock(1);
```

#### Step 16: Ownership Transfer
```solidity
// Transfer ownership of all manager contracts to DAOCommittee
SeigManagerProxy(payable(seigManagerProxy)).transferOwnership(daoCommitteeProxy);
DepositManagerProxy(payable(depositManagerProxy)).transferOwnership(daoCommitteeProxy);
// ... other contracts
```

#### Step 17-18: Test Environment Setup
```solidity
// Deploy Mock Dispute Game Factory and Game
mockFactory = new SlashingMockFactory();
mockGame = new SlashingMockGame();

// Grant L1BridgeRegistry permissions
L1BridgeRegistryProxy.addManager(address(this));
L1BridgeRegistryProxy.addRegistrant(address(this));

// Register Rollup Config
L1BridgeRegistryV1_2(l1BridgeRegistryProxy).registerRollupConfig(
    rollupConfig,
    2, // Bedrock
    makeAddr("l2TON"),
    "TestRollup"
);
```

### 2. Deployment Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      DAO Governance                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  DAOVault    │  │DAOAgendaMgr  │  │DAOCommittee  │      │
│  └──────────────┘  └──────────────┘  └──────┬───────┘      │
│                                              │               │
└──────────────────────────────────────────────┼──────────────┘
                                               │ Owner
                    ┌──────────────────────────┼──────────────────────────┐
                    │                          │                          │
         ┌──────────▼─────────┐    ┌──────────▼─────────┐    ┌──────────▼─────────┐
         │  SeigManagerProxy  │    │DepositManagerProxy │    │Layer2ManagerProxy  │
         │   (Slashing)       │◄───┤   (Slashing)       │◄───┤   (Slashing)       │
         └────────────────────┘    └────────────────────┘    └────────────────────┘
                    │                          │                          │
                    │                          │                          │
         ┌──────────▼─────────┐    ┌──────────▼─────────┐    ┌──────────▼─────────┐
         │ Layer2Registry     │    │ CoinageFactory     │    │L1BridgeRegistry    │
         └────────────────────┘    └────────────────────┘    └────────────────────┘
                                                                         │
                                                              ┌──────────▼─────────┐
                                                              │  RollupConfig      │
                                                              │  (Mock)            │
                                                              └────────────────────┘
```

---

## Test Scenarios

### Basic Functionality Tests (2)

#### 1. test_CandidateRegistrationAndStaking
**Purpose**: Verify basic Candidate registration and staking functionality

**Scenario**:
1. Mint 10,000 TON to Operator
2. Approve Layer2Manager
3. Register Candidate (registerCandidateAddOn)
4. Verify registration:
   - Check CandidateAddOn address
   - Check OperatorManager address
   - Verify staking amount (in RAY units)

**Validation**:
- ✅ CandidateAddOn successfully created
- ✅ Staking amount is accurate (10,000 TON * 1e9 RAY)

#### 2. test_SlashingAndReward
**Purpose**: Verify basic slashing and reward mechanism

**Scenario**:
1. Register Candidate (reuse test_CandidateRegistrationAndStaking)
2. Create Mock Dispute Game
3. Challenger wins the game (call step)
4. Resolve the game
5. Execute slashing
6. Verify results:
   - Operator stake = 0
   - Challenger reward = initial stake * 10%

**Validation**:
- ✅ All operator stake is burned
- ✅ Challenger receives 10% reward
- ✅ Remaining 90% is burned

---

### Reward Rate Tests (4)

#### 3. test_Slashing_CustomRewardRate_50Percent
**Purpose**: Set and verify 50% reward rate

**Scenario**:
1. Set reward rate to 50% (5000 basis points)
2. Register Candidate and execute slashing
3. Verify Challenger reward

**Validation**:
- ✅ Reward rate set to 50%
- ✅ Challenger receives 50% of slashed amount
- ✅ Remaining 50% is burned

#### 4. test_Slashing_FullRewardRate_100Percent
**Purpose**: 100% reward rate (full reward)

**Scenario**:
1. Set reward rate to 100% (10000 basis points)
2. Register Candidate and execute slashing
3. Verify Challenger receives full amount

**Validation**:
- ✅ Challenger receives entire slashed amount
- ✅ No amount is burned

#### 5. test_Slashing_ZeroRewardRate_AllBurned
**Purpose**: 0% reward rate (full burn)

**Scenario**:
1. Set reward rate to 0%
2. Register Candidate and execute slashing
3. Verify all amount is burned

**Validation**:
- ✅ Challenger receives no reward
- ✅ Entire slashed amount is burned

#### 6. test_Slashing_BelowMinimumStake
**Purpose**: Verify minimum stake requirement

**Scenario**:
1. Attempt to register with 1000 TON
2. Verify registration is rejected for below minimum stake

**Validation**:
- ✅ Registration below minimum stake is rejected
- ✅ "minimum amount is required" error occurs

---

### Seigniorage Tests (2)

#### 7. test_Slashing_WithSeigniorage_BurnsAll
**Purpose**: Burn both principal and interest when slashing after seigniorage accrual

**Scenario**:
1. Register Candidate
2. Advance 1000 blocks (seigniorage accrual)
3. Attempt seigniorage update
4. Execute slashing
5. Verify both principal and interest are burned

**Validation**:
- ✅ Seigniorage accrues (if possible in test environment)
- ✅ Both principal and interest are burned during slashing
- ✅ Final stake = 0

#### 8. test_Slashing_WithUnreceivedSeigniorage
**Purpose**: Include unreceived seigniorage in slashing

**Scenario**:
1. Register Candidate
2. Advance 1000 blocks (seigniorage accrual)
3. Execute slashing **without** seigniorage update
4. Verify unreceived seigniorage is calculated and burned

**Validation**:
- ✅ Seigniorage update performed internally during slashing
- ✅ Reward is greater than initial stake (includes unreceived seigniorage)
- ✅ Final stake = 0

---

### Security Tests (5)

#### 9. test_Slashing_PreventDoubleSlashing
**Purpose**: Prevent double slashing

**Scenario**:
1. Register Candidate and execute slashing
2. Attempt second slashing on same operator
3. Verify second slashing is rejected

**Validation**:
- ✅ First slashing succeeds
- ✅ Second slashing attempt reverts
- ✅ Cannot slash when stake is 0

#### 10. test_Slashing_MultipleChallengers_FirstWins
**Purpose**: Only first challenger succeeds among multiple challengers

**Scenario**:
1. Register Candidate
2. Challenger1 calls step in game
3. Challenger2 attempts to call step → **Rejected**
4. Execute slashing
5. Verify only Challenger1 receives reward

**Validation**:
- ✅ Challenger1's step call succeeds
- ✅ Challenger2's step call rejected ("Already countered")
- ✅ Only Challenger1 receives reward
- ✅ Challenger2 receives no reward

#### 11. test_Slashing_InvalidGameStates
**Purpose**: Prevent slashing with invalid Dispute Game states

**Scenario A - Unresolved Game**:
1. Register Candidate
2. Create game and call step
3. Attempt slashing **without** calling resolve
4. Verify slashing is rejected

**Scenario B - DEFENDER_WINS**:
1. Register Candidate
2. Create game (no step call)
3. Call resolve → DEFENDER_WINS state
4. Attempt slashing → **Rejected**

**Validation**:
- ✅ Cannot slash with unresolved game
- ✅ Cannot slash with DEFENDER_WINS game
- ✅ Only CHALLENGER_WINS game allows slashing

#### 12. test_Slashing_UnauthorizedDepositManagerAccess
**Purpose**: Block unauthorized DepositManager.slash calls

**Scenario**:
1. Register Candidate
2. Regular user (attacker) attempts to call DepositManager.slash directly
3. Verify call is rejected
4. Verify stake is unchanged

**Validation**:
- ✅ Regular user's slash call rejected
- ✅ "not layer2Manager" error occurs
- ✅ Stake remains unchanged

#### 13. test_Slashing_UnauthorizedSeigManagerAccess
**Purpose**: Block unauthorized SeigManager.onSlash calls

**Scenario**:
1. Register Candidate
2. Regular user (attacker) attempts to call SeigManager.onSlash directly
3. Verify call is rejected
4. Verify stake is unchanged

**Validation**:
- ✅ Regular user's onSlash call rejected
- ✅ "not onlyDepositManager" error occurs
- ✅ Stake remains unchanged

---

### Edge Case Tests (4)

#### 14. test_Slashing_MultipleOperators_Independence
**Purpose**: Slashing independence for multiple operators

**Scenario**:
1. Register both Operator1 and Operator2
2. Execute slashing only on Operator1
3. Verify Operator2 is unaffected

**Validation**:
- ✅ Operator1's stake = 0
- ✅ Operator2's stake = initial value
- ✅ Slashing operates independently

#### 15. test_Slashing_ReRegistrationAfterSlashing
**Purpose**: Re-registration capability after slashing and seigniorage earning

**Scenario**:
1. Register Candidate and execute slashing
2. Re-register with new Rollup Config (5000 TON)
3. Verify successful re-registration
4. Verify seigniorage earning after time passage

**Validation**:
- ✅ Slashed operator can re-register
- ✅ Re-registration with 5000 TON succeeds
- ✅ Can earn seigniorage after re-registration (environment dependent)

#### 16. test_Slashing_AfterPartialWithdrawal
**Purpose**: Slashing after partial withdrawal

**Scenario**:
1. Register Candidate
2. Attempt partial withdrawal (if implemented)
3. Execute slashing
4. Verify all remaining stake is slashed

**Validation**:
- ✅ Partial withdrawal feature verified (if implemented)
- ✅ All remaining stake is slashed
- ✅ Final stake = 0

#### 17. test_Slashing_EventEmission
**Purpose**: Verify slashing event emission

**Scenario**:
1. Register Candidate
2. Execute slashing
3. Verify events are properly emitted

**Validation**:
- ✅ Slashing completed
- ✅ Events emitted (check transaction logs)

---

### Delegator Protection Tests (3)

#### 18. test_Slashing_DelegatorSeigniorageProtection
**Purpose**: Verify delegator seigniorage protection during operator slashing

**Scenario**:
1. Operator stakes 10,000 TON
2. Three delegators stake 5,000, 3,000, and 2,000 TON respectively
3. Advance 1000 blocks (seigniorage accrual)
4. Attempt seigniorage update
5. Execute operator slashing
6. Verify stakes after slashing
7. Verify delegator withdrawal capability

**Validation**:
- ✅ Operator stake = 0 (fully slashed)
- ✅ All delegator stakes preserved
- ✅ All delegator seigniorage preserved
- ✅ Delegators can withdraw after slashing
- ✅ Withdrawal includes full stake with seigniorage

**Core Validation Code**:
```solidity
assertEq(operatorStakeAfter, 0, "Operator stake should be fully slashed");
assertEq(delegator1StakeAfter, delegator1StakeWithSeig, "Delegator1 stake should be preserved");
assertEq(delegator2StakeAfter, delegator2StakeWithSeig, "Delegator2 stake should be preserved");
assertEq(delegator3StakeAfter, delegator3StakeWithSeig, "Delegator3 stake should be preserved");
```

#### 19. test_Slashing_NewDelegatorAfterSlashing
**Purpose**: Verify new delegator participation restriction after slashing

**Scenario**:
1. Operator registers (10,000 TON)
2. Execute slashing via Dispute Game
3. Verify operator stake = 0
4. New delegator attempts to stake 2,000 TON
5. Verify staking is rejected

**Validation**:
- ✅ Operator slashing successful
- ✅ Cannot stake to slashed operator
- ✅ "OperatorCollateral is insufficient" error occurs
- ✅ Operator must re-stake before accepting new delegators

**Core Validation Code**:
```solidity
vm.expectRevert("OperatorCollateral is insufficient.");
DepositManager(depositManagerProxy).deposit(candidateAddOn, newDelegatorStake * 1e9);
```

**Important Notes**:
- When operator's minimum collateral becomes 0, no new delegators can be accepted
- This is a safety mechanism to protect delegators

#### 20. test_Slashing_ComprehensiveDelegatorScenario
**Purpose**: Verify seigniorage distribution fairness in complex scenarios

**Scenario**:
1. **Phase 1**: Operator + Delegator1 stake
2. Advance 500 blocks (first seigniorage accrual)
3. **Phase 2**: Delegator2 joins mid-way
4. Advance 500 more blocks (second seigniorage accrual)
5. Verify stakes before slashing
6. Execute operator slashing
7. Verify stakes after slashing
8. Analyze seigniorage comparison

**Validation**:
- ✅ Operator slashed, delegators protected
- ✅ Delegator1 earned more seigniorage than Delegator2
- ✅ Seigniorage distribution proportional to staking duration
- ✅ Slashing doesn't affect seigniorage distribution fairness

**Core Validation Code**:
```solidity
uint256 delegator1Seigniorage = delegator1StakeBefore - (delegator1Stake * 1e9);
uint256 delegator2Seigniorage = delegator2StakeBefore - (delegator2Stake * 1e9);

assertTrue(
    delegator1Seigniorage > delegator2Seigniorage,
    "Delegator1 should have more seigniorage (staked longer)"
);
```

**Seigniorage Distribution Principles**:
- Longer staking duration earns more seigniorage
- Operator slashing doesn't affect delegator seigniorage
- Each delegator's seigniorage is calculated independently

---

## How to Run Tests

### 1. Run All Tests

```bash
# Basic execution
forge test --match-path test/Slashing/SlashingTest.t.sol

# Verbose output (-vv)
forge test --match-path test/Slashing/SlashingTest.t.sol -vv

# Very verbose output (-vvvv)
forge test --match-path test/Slashing/SlashingTest.t.sol -vvvv
```

### 2. Run Specific Tests

```bash
# Run specific test function
forge test --match-path test/Slashing/SlashingTest.t.sol --match-test test_CandidateRegistrationAndStaking -vv

# Run multiple tests with pattern matching
forge test --match-path test/Slashing/SlashingTest.t.sol --match-test "test_Slashing_Custom" -vv
```

### 3. Include Gas Report

```bash
# Gas usage report
forge test --match-path test/Slashing/SlashingTest.t.sol --gas-report

# Gas report for specific contract
forge test --match-path test/Slashing/SlashingTest.t.sol --gas-report --match-contract SlashingTest
```

### 4. Coverage Analysis

```bash
# Generate code coverage
forge coverage --match-path test/Slashing/SlashingTest.t.sol

# Coverage report (lcov format)
forge coverage --match-path test/Slashing/SlashingTest.t.sol --report lcov

# Generate HTML report
genhtml lcov.info --branch-coverage --output-dir coverage
```

### 5. Debugging

```bash
# Debug specific test
forge test --match-path test/Slashing/SlashingTest.t.sol --match-test test_SlashingAndReward --debug

# Output trace
forge test --match-path test/Slashing/SlashingTest.t.sol -vvvvv
```

### 6. Rerun Failed Tests Only

```bash
# Rerun failed tests
forge test --rerun
```

---

## Test Results Analysis

### Successful Test Execution Example

```
Ran 1 test suite in 283.64ms (9.28ms CPU time): 20 tests passed, 0 failed, 0 skipped (20 total tests)

[PASS] test_CandidateRegistrationAndStaking() (gas: 5221962)
[PASS] test_SlashingAndReward() (gas: 7468263)
[PASS] test_Slashing_AfterPartialWithdrawal() (gas: 7439409)
[PASS] test_Slashing_BelowMinimumStake() (gas: 7449206)
[PASS] test_Slashing_ComprehensiveDelegatorScenario() (gas: 7883942)
[PASS] test_Slashing_CustomRewardRate_50Percent() (gas: 7458387)
[PASS] test_Slashing_DelegatorSeigniorageProtection() (gas: 8496832)
[PASS] test_Slashing_EventEmission() (gas: 7438509)
[PASS] test_Slashing_FullRewardRate_100Percent() (gas: 7437102)
[PASS] test_Slashing_InvalidGameStates() (gas: 8283328)
[PASS] test_Slashing_MultipleChallengers_FirstWins() (gas: 7432610)
[PASS] test_Slashing_MultipleOperators_Independence() (gas: 12411203)
[PASS] test_Slashing_NewDelegatorAfterSlashing() (gas: 7601234)
[PASS] test_Slashing_PreventDoubleSlashing() (gas: 7436255)
[PASS] test_Slashing_ReRegistrationAfterSlashing() (gas: 12527606)
[PASS] test_Slashing_UnauthorizedDepositManagerAccess() (gas: 5231439)
[PASS] test_Slashing_UnauthorizedSeigManagerAccess() (gas: 5231340)
[PASS] test_Slashing_WithSeigniorage_BurnsAll() (gas: 7580296)
[PASS] test_Slashing_WithUnreceivedSeigniorage() (gas: 7453424)
[PASS] test_Slashing_ZeroRewardRate_AllBurned() (gas: 7405119)

Suite result: ok. 20 passed; 0 failed; 0 skipped
```

### Gas Usage Analysis

| Test | Gas Usage | Category |
|------|-----------|----------|
| test_CandidateRegistrationAndStaking | 5,221,962 | Basic |
| test_SlashingAndReward | 7,468,263 | Basic |
| test_Slashing_CustomRewardRate_50Percent | 7,458,387 | Reward Rate |
| test_Slashing_FullRewardRate_100Percent | 7,437,102 | Reward Rate |
| test_Slashing_ZeroRewardRate_AllBurned | 7,405,119 | Reward Rate |
| test_Slashing_WithSeigniorage_BurnsAll | 7,580,296 | Seigniorage |
| test_Slashing_WithUnreceivedSeigniorage | 7,453,424 | Seigniorage |
| test_Slashing_MultipleOperators_Independence | 12,411,203 | Edge Case |
| test_Slashing_ReRegistrationAfterSlashing | 12,527,606 | Edge Case |
| test_Slashing_InvalidGameStates | 8,283,328 | Security |
| **test_Slashing_DelegatorSeigniorageProtection** | **8,496,832** | **Delegator Protection** |
| **test_Slashing_NewDelegatorAfterSlashing** | **7,601,234** | **Delegator Protection** |
| **test_Slashing_ComprehensiveDelegatorScenario** | **7,883,942** | **Delegator Protection** |

**Average Gas Usage**: ~7.9M gas  
**Maximum Gas Usage**: 12.5M gas (re-registration test)  
**Minimum Gas Usage**: 5.2M gas (basic registration)  
**Delegator Protection Tests Average**: ~8.0M gas

### Test Coverage

```
| File                                    | % Lines        | % Statements   | % Branches    | % Funcs       |
|-----------------------------------------|----------------|----------------|---------------|---------------|
| Layer2Manager_Slashing.sol              | 100.00% (25/25)| 100.00% (30/30)| 100.00% (8/8) | 100.00% (2/2) |
| DepositManager_Slashing.sol             | 100.00% (18/18)| 100.00% (22/22)| 100.00% (6/6) | 100.00% (2/2) |
| SeigManager_Slashing.sol                | 100.00% (15/15)| 100.00% (18/18)| 100.00% (4/4) | 100.00% (1/1) |
```

---

## Troubleshooting

### Common Issues

#### 1. Compilation Error: "Stack too deep"
**Solution**: Verify `via_ir = true` setting in `foundry.toml`

```toml
[profile.default]
via_ir = true
optimizer = true
optimizer_runs = 100
```

#### 2. ABI File Access Error
**Solution**: Add file system permissions in `foundry.toml`

```toml
fs_permissions = [{ access = "read", path = "./abis" }]
```

### Debugging Tips

1. **Check Detailed Logs**: Use `-vvvv` flag
2. **Trace Specific Function**: Use `forge test --debug`
3. **Check Gas Usage**: Use `--gas-report` flag
4. **Check Events**: Search for `emit` events in test logs

---

## References

### Related Documentation
- [Slashing Mechanism Specification](../specs-kr/09-slashing-mechanism.md)
- [Foundry Official Documentation](https://book.getfoundry.sh/)
- [Solidity Testing Guide](https://docs.soliditylang.org/en/latest/testing.html)

### Related Contracts
- `Layer2Manager_Slashing.sol`: Slashing execution logic
- `DepositManager_Slashing.sol`: Stake burning and reward distribution
- `SeigManager_Slashing.sol`: Seigniorage burning handling
- `MockFaultDisputeGame2.sol`: Dispute Game simulation


