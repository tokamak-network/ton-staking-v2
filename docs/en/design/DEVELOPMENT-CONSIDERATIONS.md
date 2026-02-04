# Delegate Staking Development Considerations

> **Version**: 1.0
> **Date**: 2026-01-26
> **Status**: Development Guide

This document summarizes the technical and architectural considerations that must be addressed when developing the Delegate Staking service.

---

## Table of Contents

1. [V3 Protocol Integration](#1-v3-protocol-integration)
2. [Core Technical Challenges](#2-core-technical-challenges)
3. [Contract Architecture](#3-contract-architecture)
4. [Reward Collection Mechanism](#4-reward-collection-mechanism)
5. [Unit Conversion and Precision](#5-unit-conversion-and-precision)
6. [Security Considerations](#6-security-considerations)
7. [Gas Optimization](#7-gas-optimization)
8. [Testing Strategy](#8-testing-strategy)
9. [Deployment and Upgrades](#9-deployment-and-upgrades)
10. [Undecided Items and Risk Factors](#10-undecided-items-and-risk-factors)

---

## 1. V3 Protocol Integration

### 1.1 Understanding Seigniorage Distribution Flow

It is essential to understand exactly how seigniorage is distributed in V3.

```
SeigManager.updateSeigniorage()
        |
        v
_distributeV3Seigniorage()
        |
        +---> DAO Rewards: d x A (fixed ratio)
        |
        +---> L2 Pool: L = (1-d) x A
                |
                v
        _distributeL2Rewards()
                |
                +---> Only eligible L2s are distribution targets
                |
                +---> Each L2's seigniorage: S_i = y(B~_i) x B~_i / Sum B~_j
                        |
                        +---> Sequencer Rewards: (1-alpha) x S_i
                        |       |
                        |       v
                        |   Layer2Manager.transferL2Seigniorage()
                        |       |
                        |       v
                        |   operatorOfLayer[layer2] <-- WTON transfer
                        |
                        +---> Validator Rewards: alpha x S_i
                                |
                                v
                            ValidatorReward Contract
```

### 1.2 Key Integration Points

| Component | Function/Variable | File Location | Description |
|-----------|-------------------|---------------|-------------|
| Layer2Manager | `operatorOfLayer[layer2]` | Layer2ManagerV3.sol:50 | **Reward recipient address** |
| Layer2Manager | `transferL2Seigniorage()` | Layer2ManagerV3.sol:237-245 | Seigniorage transfer |
| SeigManager | `checkCurrentEligibility()` | SeigManagerV3_1.sol | Eligibility verification |
| SeigManager | `getSequencerStaked()` | SeigManagerV3_1.sol | Staking balance query |
| L1BridgeRegistry | `layer2TVL()` | L1BridgeRegistryV1_2.sol | Bridged TON query |

### 1.3 Important Finding: Reward Recipient Issue

**Current V3 Structure Limitations**:

```solidity
// Layer2ManagerV3.sol:237-245
function transferL2Seigniorage(address layer2, uint256 amount) external onlySeigManager {
    address operator = operatorOfLayer[layer2];  // <-- Rewards are sent here
    require(operator != address(0), "No operator");
    IWTON(wton).safeTransfer(operator, amount);
    emit L2SeigniorageTransferred(layer2, operator, amount);
}
```

**Problems**:
- `operatorOfLayer[layer2]` is the OperatorManager contract address
- OperatorManager is directly controlled by the Sequencer
- For DelegateStaking contract to receive rewards directly, **protocol modification** is required

**Solution Options**:

| Option | Description | Pros/Cons |
|--------|-------------|-----------|
| A. Protocol Modification | Set `operatorOfLayer` to DelegateStaking | Requires protocol change |
| B. OperatorManager Extension | Add automatic reward forwarding logic | Maintains existing structure, extra gas |
| C. Sequencer Trust | Sequencer manually forwards rewards | Centralized, requires trust |
| D. Wrapper Contract | DelegateStaking acts as OperatorManager | Increased complexity |

**Recommended Approach**: Option A (Protocol Modification) or Option B (OperatorManager Extension)

---

## 2. Core Technical Challenges

### 2.1 Bridged TON Increase Mechanism

**Delegation -> Bridged TON Increase Flow**:

```
User delegates TON
        |
        v
DelegateStaking Contract
        |
        v
Bridge TON to L2 Bridge
        |
        v
Arrives at L2's Sequencer Vault
        |
        v
L1BridgeRegistry.layer2TVL() increases
        |
        v
SeigManager's Bridged TON (B_i) increases
        |
        v
Seigniorage distribution increases
```

**Implementation Verification Items**:

1. **Bridge Interface**: Verify exact interface of Tokamak L2 Bridge
2. **TVL Reflection Timing**: When is TVL reflected after bridging
3. **Vault Address**: How to manage Vault addresses per Sequencer

### 2.2 Eligibility Requirement Integration

In V3, a Sequencer must meet **eligibility requirements** to receive seigniorage:

```
T_i >= max(theta x B_i, D_sequencer)

Where:
- T_i: Sequencer's total staking (OperatorManager balance)
- theta: Minimum staking ratio (minStakingRatio)
- B_i: Bridged TON
- D_sequencer = H_max x C_max + Delta_seq: Sequencer minimum collateral
```

**Note**: As delegation increases, B_i increases, and therefore the required T_i also increases.

```solidity
// Example: theta = 10%, current B_i = 1000 TON
// Required staking: 0.1 x 1000 = 100 WTON

// After delegation: B_i = 5000 TON
// Required staking: 0.1 x 5000 = 500 WTON

// If Sequencer doesn't add more staking, eligibility is lost!
```

**Considerations for DelegateStaking**:
- Check Sequencer eligibility status before delegation
- Warn about potential eligibility loss due to delegation
- Display Sequencer's staking headroom

### 2.3 DTD (Dispute Time Delay) Handling

There is a 14-day waiting period for withdrawals:

```
requestUndelegate() call
        |
        +---> Withdrawal request from L2 Vault
        |
        v
14-day DTD waiting period (L2 -> L1 bridge time)
        |
        v
withdraw() becomes callable
```

**Implementation Considerations**:
- L2 -> L1 message passing mechanism
- Method to verify actual bridge completion
- Relationship with Optimism's withdrawal verification period

---

## 3. Contract Architecture

### 3.1 Contract Structure Proposal

```
+-------------------------------------------------------------+
|                    L1 (Ethereum)                            |
+-------------------------------------------------------------+
|                                                             |
|  +------------------+     +------------------------------+  |
|  | DelegateStaking  |<----| Proxy (TransparentUpgradeable)|  |
|  |   (Logic)        |     +------------------------------+  |
|  +--------+---------+                                       |
|           |                                                 |
|           +---> SequencerRegistry: Sequencer registration/management
|           +---> DelegationManager: Delegation/withdrawal logic
|           +---> RewardDistributor: Reward distribution logic
|           +---> BridgeConnector: L2 bridge integration
|                                                             |
+-------------------------------------------------------------+
                              |
                              | L1 -> L2 message
                              v
+-------------------------------------------------------------+
|                    L2 (Tokamak L2)                          |
+-------------------------------------------------------------+
|                                                             |
|  +-----------------------------------------+                |
|  |           SequencerVault                |                |
|  |  - owner: L1 DelegateStaking only       |                |
|  |  - withdrawal: Only via L1 message      |                |
|  |  - Sequencer cannot use arbitrarily     |                |
|  +-----------------------------------------+                |
|                                                             |
+-------------------------------------------------------------+
```

### 3.2 Storage Design

```solidity
// SequencerInfo: Per-Sequencer information
struct SequencerInfo {
    bool isRegistered;              // Registration status
    address l2Vault;                // L2 Vault address
    address layer2;                 // V3 Layer2 (CandidateAddOn) address
    address systemConfig;           // Optimism SystemConfig address
    uint256 commission;             // Fee (basis points)
    uint256 totalDelegated;         // Total delegated amount
    uint256 accRewardPerShare;      // Accumulated reward per share
    uint256 lastRewardBlock;        // Last reward block
}

// DelegationInfo: Per-user delegation information
struct DelegationInfo {
    uint256 amount;                 // Delegation amount
    uint256 rewardDebt;             // For reward calculation
    uint256 pendingWithdrawal;      // Pending withdrawal amount
    uint256 withdrawalRequestTime;  // Withdrawal request time
    uint256 withdrawalUnlockTime;   // Withdrawal available time
}

// Storage Layout (considering upgrades)
mapping(address => SequencerInfo) public sequencers;
mapping(address => mapping(address => DelegationInfo)) public delegations;
mapping(address => uint256) public pendingRewards;  // Undistributed rewards
address[] public sequencerList;
```

### 3.3 V3 Contract Integration Interface

```solidity
// ISeigManagerV3 (required functions only)
interface ISeigManagerV3 {
    function checkCurrentEligibility(address layer2)
        external view returns (bool eligible, uint256 required, uint256 actual);
    function getSequencerStaked(address layer2)
        external view returns (uint256);
    function getEffectiveBridgedTon(address layer2)
        external view returns (uint256);
    function minStakingRatio() external view returns (uint256);
}

// ILayer2Manager (required functions only)
interface ILayer2Manager {
    function operatorOfLayer(address layer2) external view returns (address);
    function getLayer2BySystemConfig(address systemConfig) external view returns (address);
    function getBridgedTonByLayer(address layer2) external view returns (uint256);
}

// IL1BridgeRegistry
interface IL1BridgeRegistry {
    function layer2TVL(address systemConfig) external view returns (uint256);
    function rollupConfigWithPortal(address portal) external view returns (address);
}
```

---

## 4. Reward Collection Mechanism

### 4.1 MasterChef Pattern Implementation

```solidity
uint256 private constant PRECISION = 1e27;  // Same precision as WTON

function _distributeRewards(address sequencer, uint256 amount) internal {
    SequencerInfo storage seq = sequencers[sequencer];
    if (seq.totalDelegated == 0) {
        // If no delegators, full amount to Sequencer
        IWTON(wton).safeTransfer(sequencer, amount);
        return;
    }

    // Commission calculation
    uint256 commission = (amount * seq.commission) / 10000;
    uint256 delegatorRewards = amount - commission;

    // Transfer Commission to Sequencer
    if (commission > 0) {
        IWTON(wton).safeTransfer(sequencer, commission);
    }

    // Update accRewardPerShare
    seq.accRewardPerShare += (delegatorRewards * PRECISION) / seq.totalDelegated;

    emit RewardsDistributed(sequencer, amount, commission);
}

function _updateRewardDebt(address user, address sequencer) internal {
    DelegationInfo storage del = delegations[user][sequencer];
    del.rewardDebt = (del.amount * sequencers[sequencer].accRewardPerShare) / PRECISION;
}

function _pendingReward(address user, address sequencer) internal view returns (uint256) {
    DelegationInfo storage del = delegations[user][sequencer];
    SequencerInfo storage seq = sequencers[sequencer];

    uint256 accReward = (del.amount * seq.accRewardPerShare) / PRECISION;
    return accReward > del.rewardDebt ? accReward - del.rewardDebt : 0;
}
```

### 4.2 Reward Collection Trigger

**Option A: Push Method (Recommended)**

```solidity
// Direct call from V3 protocol (requires protocol modification)
function receiveReward(address sequencer, uint256 amount) external onlyLayer2Manager {
    IWTON(wton).safeTransferFrom(msg.sender, address(this), amount);
    pendingRewards[sequencer] += amount;
    emit RewardReceived(sequencer, amount);
}

// Or use ERC20 receive hook
function onWTONReceived(address from, uint256 amount, bytes calldata data) external returns (bytes4) {
    address sequencer = abi.decode(data, (address));
    pendingRewards[sequencer] += amount;
    return this.onWTONReceived.selector;
}
```

**Option B: Pull Method**

```solidity
// Collect Sequencer's rewards externally
function collectRewards(address sequencer) external {
    address operatorManager = sequencers[sequencer].operatorManager;
    uint256 balance = IWTON(wton).balanceOf(operatorManager);

    // Withdraw rewards from OperatorManager (requires OperatorManager modification)
    IOperatorManager(operatorManager).withdrawRewards(address(this), balance);

    pendingRewards[sequencer] += balance;
}
```

### 4.3 Distribution Function (Permissionless)

```solidity
/// @notice Reward distribution function callable by anyone
function distribute(address sequencer) external nonReentrant {
    uint256 amount = pendingRewards[sequencer];
    if (amount == 0) return;

    pendingRewards[sequencer] = 0;
    _distributeRewards(sequencer, amount);
}

/// @notice Claim rewards
function claimRewards(address sequencer) external nonReentrant {
    // Distribute undistributed rewards first if any
    if (pendingRewards[sequencer] > 0) {
        _distribute(sequencer);
    }

    uint256 reward = _pendingReward(msg.sender, sequencer);
    if (reward == 0) return;

    _updateRewardDebt(msg.sender, sequencer);
    IWTON(wton).safeTransfer(msg.sender, reward);

    emit RewardsClaimed(msg.sender, sequencer, reward);
}
```

---

## 5. Unit Conversion and Precision

### 5.1 Token Unit Summary

| Token | Unit | Decimals | Example |
|-------|------|----------|---------|
| TON | Base | 18 | 1 TON = 1e18 |
| WTON | RAY | 27 | 1 WTON = 1e27 |
| RAY | Ratio | 27 | 100% = 1e27 |

### 5.2 Unit Conversion Functions

```solidity
uint256 constant RAY = 1e27;
uint256 constant WAD = 1e18;
uint256 constant GWEI_UNIT = 1e9;

/// @notice TON -> WTON conversion
function toWTON(uint256 tonAmount) internal pure returns (uint256) {
    return tonAmount * GWEI_UNIT;  // 18 + 9 = 27 decimals
}

/// @notice WTON -> TON conversion
function toTON(uint256 wtonAmount) internal pure returns (uint256) {
    return wtonAmount / GWEI_UNIT;
}

/// @notice Apply RAY ratio
function applyRatio(uint256 amount, uint256 ratioRay) internal pure returns (uint256) {
    return (amount * ratioRay) / RAY;
}
```

### 5.3 Precision Loss Warning

```solidity
// Wrong example: Division first
uint256 wrong = (amount / totalSupply) * rewardPerShare;  // Precision loss!

// Correct example: Multiplication first
uint256 correct = (amount * rewardPerShare) / totalSupply;

// In MasterChef pattern
uint256 accRewardPerShare = (rewards * PRECISION) / totalStaked;
uint256 pending = (userAmount * accRewardPerShare) / PRECISION - rewardDebt;
```

---

## 6. Security Considerations

### 6.1 Reentrancy Prevention

```solidity
// Using ReentrancyGuard
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract DelegateStaking is ReentrancyGuard {
    function stake(...) external nonReentrant { ... }
    function unstake(...) external nonReentrant { ... }
    function claimRewards(...) external nonReentrant { ... }
}

// Checks-Effects-Interactions pattern
function withdraw() external nonReentrant {
    // 1. Checks
    require(withdrawable > 0, "Nothing to withdraw");

    // 2. Effects (state changes)
    stakes[msg.sender].pendingWithdrawal = 0;

    // 3. Interactions (external calls)
    stakingToken.safeTransfer(msg.sender, withdrawable);
}
```

### 6.2 Access Control

```solidity
// Role-based access control
bytes32 public constant SEQUENCER_ROLE = keccak256("SEQUENCER_ROLE");
bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");

modifier onlySequencer(address sequencer) {
    require(msg.sender == sequencer, "Not sequencer");
    _;
}

modifier onlyBridge() {
    require(hasRole(BRIDGE_ROLE, msg.sender), "Not bridge");
    _;
}
```

### 6.3 Input Validation

```solidity
function delegate(address sequencer, uint256 amount) external {
    // Zero address validation
    require(sequencer != address(0), "Zero address");

    // Zero amount validation
    require(amount > 0, "Zero amount");

    // Sequencer registration check
    require(sequencers[sequencer].isRegistered, "Not registered");

    // Minimum delegation amount check
    require(amount >= MIN_DELEGATION, "Below minimum");

    // Overflow check (automatic in Solidity 0.8+)
    // amount + currentDelegation is automatically validated
}
```

### 6.4 Sequencer Vault Security

```solidity
// L2 SequencerVault Contract
contract SequencerVault {
    address public immutable l1DelegateStaking;
    address public immutable l2Bridge;

    modifier onlyL1Contract() {
        // Only allow L1 messages through L2 Bridge
        require(
            msg.sender == l2Bridge &&
            ICrossDomainMessenger(l2Bridge).xDomainMessageSender() == l1DelegateStaking,
            "Unauthorized"
        );
        _;
    }

    function withdraw(address to, uint256 amount) external onlyL1Contract {
        IERC20(ton).safeTransfer(to, amount);
    }

    // Sequencer cannot withdraw arbitrarily
    // Remove receive() to prevent ETH transfers
}
```

### 6.5 Flash Loan Attack Prevention

```solidity
// Snapshot-based reward calculation
mapping(address => mapping(address => uint256)) public snapshotStake;
uint256 public snapshotBlock;

function takeSnapshot() external {
    require(block.number > snapshotBlock + SNAPSHOT_INTERVAL, "Too soon");
    snapshotBlock = block.number;
    // Snapshot logic
}

// Or use time-weighted average
function getTimeWeightedStake(address user, address sequencer) public view returns (uint256) {
    // Calculate average staking over a period
}
```

---

## 7. Gas Optimization

### 7.1 Storage Optimization

```solidity
// Wrong example: Multiple storage reads
function calculate() {
    uint256 a = data.value1;  // SLOAD
    uint256 b = data.value2;  // SLOAD
    uint256 c = data.value1;  // SLOAD again
}

// Correct example: Caching
function calculate() {
    DataStruct memory cached = data;  // Only one SLOAD
    uint256 a = cached.value1;
    uint256 b = cached.value2;
    uint256 c = cached.value1;
}
```

### 7.2 Loop Optimization

```solidity
// Wrong example: Calculate length every iteration
for (uint i = 0; i < array.length; i++) { ... }

// Correct example: Cache length
uint256 len = array.length;
for (uint i = 0; i < len; ) {
    // ...
    unchecked { ++i; }
}
```

### 7.3 Batch Processing

```solidity
// Claim rewards from multiple Sequencers at once
function claimAllRewards(address[] calldata sequencers) external nonReentrant {
    uint256 totalReward = 0;

    for (uint256 i = 0; i < sequencers.length; ) {
        totalReward += _claimReward(msg.sender, sequencers[i]);
        unchecked { ++i; }
    }

    if (totalReward > 0) {
        IWTON(wton).safeTransfer(msg.sender, totalReward);
    }
}
```

---

## 8. Testing Strategy

### 8.1 Test Layers

```
+-------------------------------------+
|       E2E Tests (Scenarios)         |  <-- Full flow verification
+-------------------------------------+
|      Integration Tests              |  <-- V3 integration verification
+-------------------------------------+
|        Unit Tests                   |  <-- Individual function verification
+-------------------------------------+
```

### 8.2 Core Test Cases

#### Unit Tests

```solidity
// Delegation
test_stake_success()
test_stake_zeroAmount_reverts()
test_stake_unregisteredSequencer_reverts()
test_stake_belowMinimum_reverts()

// Withdrawal
test_unstake_success()
test_unstake_exceedsBalance_reverts()
test_withdraw_beforeUnbonding_reverts()
test_withdraw_afterUnbonding_success()

// Rewards
test_distribute_success()
test_distribute_noRewards_noOp()
test_claimRewards_success()
test_claimRewards_noRewards_noOp()
test_accRewardPerShare_calculation()
test_rewardDebt_update()
```

#### Integration Tests

```solidity
// V3 Integration
test_eligibility_checkBeforeDelegate()
test_bridgedTON_increaseAfterDelegate()
test_seigniorage_distributionFlow()
test_rewardReceipt_fromLayer2Manager()

// Eligibility status changes
test_eligibilityLoss_afterMassiveDelegation()
test_eligibilityRegain_afterSequencerTopUp()
```

#### E2E Scenarios

```solidity
// User journey
test_userJourney_delegateAndEarnRewards()
test_userJourney_partialUnstake()
test_userJourney_redelegate()

// Multiple users
test_multiUser_proportionalRewards()
test_multiUser_sequentialClaims()

// Edge Cases
test_lastUserUnstake_handlesRemainder()
test_firstUser_receivesAllRewards()
```

### 8.3 Mock Strategy

```solidity
// V3 Contract Mock
contract MockSeigManager {
    mapping(address => bool) public eligibility;
    mapping(address => uint256) public bridgedTon;

    function checkCurrentEligibility(address layer2)
        external view returns (bool, uint256, uint256)
    {
        return (eligibility[layer2], 100e27, 150e27);
    }

    function setEligibility(address layer2, bool _eligible) external {
        eligibility[layer2] = _eligible;
    }
}

// Bridge Mock
contract MockL2Bridge {
    event BridgeInitiated(address to, uint256 amount);

    function bridgeToL2(address to, uint256 amount) external {
        emit BridgeInitiated(to, amount);
    }
}
```

### 8.4 Fuzz Testing

```solidity
function testFuzz_stake_anyAmount(uint256 amount) public {
    amount = bound(amount, MIN_DELEGATION, type(uint128).max);

    deal(address(wton), user, amount);

    vm.startPrank(user);
    wton.approve(address(delegateStaking), amount);
    delegateStaking.stake(sequencer, amount);
    vm.stopPrank();

    assertEq(delegateStaking.stakes(user, sequencer).amount, amount);
}

function testFuzz_rewardDistribution(uint256 reward, uint256 stake1, uint256 stake2) public {
    reward = bound(reward, 1e18, 1e30);
    stake1 = bound(stake1, MIN_DELEGATION, 1e30);
    stake2 = bound(stake2, MIN_DELEGATION, 1e30);

    // Two users staking
    _stake(user1, stake1);
    _stake(user2, stake2);

    // Distribute rewards
    _distributeRewards(reward);

    // Verify proportional distribution
    uint256 expected1 = (reward * stake1) / (stake1 + stake2);
    uint256 expected2 = reward - expected1;

    assertApproxEqRel(delegateStaking.pendingRewards(user1, sequencer), expected1, 0.001e18);
    assertApproxEqRel(delegateStaking.pendingRewards(user2, sequencer), expected2, 0.001e18);
}
```

---

## 9. Deployment and Upgrades

### 9.1 Proxy Pattern Selection

**TransparentUpgradeableProxy Recommended**:

```solidity
// Deployment order
1. Deploy Implementation
2. Deploy ProxyAdmin (or use existing)
3. Deploy Proxy (implementation, admin, initData)
4. initialize() called automatically
```

```solidity
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

// Deployment script
address implementation = address(new DelegateStakingV1());
bytes memory initData = abi.encodeCall(
    DelegateStakingV1.initialize,
    (wton, seigManager, layer2Manager, owner)
);

address proxy = address(new TransparentUpgradeableProxy(
    implementation,
    proxyAdmin,
    initData
));
```

### 9.2 Storage Layout Management

```solidity
// Prevent storage collision during upgrades
contract DelegateStakingV1 {
    // Slot 0
    mapping(address => SequencerInfo) public sequencers;
    // Slot 1
    mapping(address => mapping(address => DelegationInfo)) public delegations;
    // ...

    // Gap for upgrades
    uint256[50] private __gap;
}

contract DelegateStakingV2 is DelegateStakingV1 {
    // New variables added after __gap
    uint256 public newVariable;  // Subtract one from existing __gap

    uint256[49] private __gap;  // Reduced to 49
}
```

### 9.3 Deployment Checklist

```
[ ] Compiler optimization settings (optimizer: 200 runs)
[ ] Review Hardhat/Foundry configuration
[ ] Testnet deployment and verification
[ ] Contract Verification (Etherscan)
[ ] Multisig setup (ProxyAdmin, Owner)
[ ] Initial parameter settings
[ ] Permission transfer (deployer -> multisig)
[ ] Documentation update
```

---

## 10. Undecided Items and Risk Factors

### 10.1 Undecided Items

| Item | Status | Description | Decision Required |
|------|--------|-------------|-------------------|
| Reward collection method | Undecided | Push vs Pull | Consult with protocol team |
| L2 bridge interface | Needs verification | Tokamak L2 bridge spec | Check technical docs |
| Sequencer Vault deployment | Undecided | Who deploys | Policy decision |
| Minimum delegation amount | Undecided | Assuming 1,000 TON | Economic analysis |
| Commission cap | Undecided | Assuming 30% | Governance decision |
| DTD period | Needs verification | Assuming 14 days | Protocol confirmation |

### 10.2 Risk Factors

| Risk | Impact | Mitigation |
|------|--------|------------|
| Bridge hack | High | Gradual delegation, insurance review |
| Sequencer exit | Medium | Clear undelegation process |
| Eligibility loss | Medium | Eligibility monitoring, warning system |
| Gas price surge | Low | Batch processing, L2 transition review |
| Smart contract bug | High | Audit, testing, phased deployment |

### 10.3 Dependencies

```
DelegateStaking
    |
    +---> TON Staking V3 Protocol
    |       +---> SeigManagerV3_1
    |       +---> Layer2ManagerV3
    |       +---> L1BridgeRegistryV1_2
    |
    +---> Tokamak L2 Bridge
    |       +---> (Interface verification needed)
    |
    +---> OpenZeppelin Contracts
            +---> ReentrancyGuard
            +---> SafeERC20
            +---> TransparentUpgradeableProxy
```

---

## Appendix: Quick Reference

### A. Key V3 Function Signatures

```solidity
// SeigManagerV3_1
function checkCurrentEligibility(address layer2) external view returns (bool, uint256, uint256);
function getSequencerStaked(address layer2) external view returns (uint256);
function getEffectiveBridgedTon(address layer2) external view returns (uint256);
function minStakingRatio() external view returns (uint256);
function validatorDistributionRatio() external view returns (uint256);

// Layer2ManagerV3
function operatorOfLayer(address layer2) external view returns (address);
function getLayer2BySystemConfig(address systemConfig) external view returns (address);
function getBridgedTonByLayer(address layer2) external view returns (uint256);
function transferL2Seigniorage(address layer2, uint256 amount) external;

// L1BridgeRegistryV1_2
function layer2TVL(address systemConfig) external view returns (uint256);
```

### B. Test Commands

```bash
# Unit tests
forge test --match-path "test/unit/**"

# Integration tests
forge test --match-path "test/integration/**"

# Specific test
forge test --match-test "test_stake"

# Gas report
forge test --gas-report

# Coverage
forge coverage --report lcov
```

### C. Development Checklist

```
Phase 1: Basic Implementation
[ ] SequencerInfo, DelegationInfo structs
[ ] registerSequencer, deregisterSequencer
[ ] delegate, unstake, withdraw
[ ] Basic unit tests

Phase 2: Reward System
[ ] MasterChef pattern implementation
[ ] distribute, claimRewards
[ ] V3 reward collection integration
[ ] Reward calculation tests

Phase 3: L2 Integration
[ ] L2 bridge interface implementation
[ ] SequencerVault contract
[ ] Withdrawal flow (L2 -> L1)
[ ] Integration tests

Phase 4: Security and Optimization
[ ] Security audit
[ ] Gas optimization
[ ] Proxy pattern application
[ ] E2E tests

Phase 5: Deployment
[ ] Testnet deployment
[ ] Mainnet deployment
[ ] Documentation
```
