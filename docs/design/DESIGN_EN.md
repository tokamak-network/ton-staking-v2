# Sequencer Delegate Staking Design Document

> **Version**: 1.0  
> **Date**: 2026-01-21  
> **Status**: Draft

---

## 1. Overview

### 1.1 Background

In Tokamak Network V3, the seigniorage distribution criterion changes to **Bridged TON**. In the previous V2, general users could directly stake on L1 and receive rewards. However, in V3, only Sequencers and Validators are eligible to receive rewards directly.

This eliminates the pathway for general users to participate in staking. To address this, we propose a **Delegate Staking** mechanism.

### 1.2 Objectives

- Provide a structure where general users can delegate TON to Sequencers and indirectly receive seigniorage rewards
- Seamlessly integrate with V3's Bridged TON-based seigniorage distribution structure
- Implement Permissionless reward distribution to minimize trust in Sequencers

### 1.3 V2 vs V3 Comparison

| Item | V2 | V3 |
|------|-----|-----|
| Staking Entity | General users stake directly | Only Sequencers stake |
| Reward Criterion | Proportional to L1 staking amount | Bridged TON (TON bridged to L2) |
| User Participation | Direct participation as Staker | No direct participation |
| Seigniorage Distribution | Staker ↔ Sequencer ↔ DAO | Sequencer ↔ Validator ↔ DAO |

---

## 2. System Architecture

### 2.1 Overall Structure

```
                                    L1 (Ethereum)
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│                         ┌─────────────────────────┐                         │
│                         │    V3 Seigniorage       │                         │
│                         │    Distribution         │                         │
│                         └───────────┬─────────────┘                         │
│                                     │ Seigniorage                            │
│                                     ▼                                        │
│   ┌─────────┐         ┌─────────────────────────────┐                       │
│   │  User   │──TON───►│   SequencerDelegateStaking  │◄──── Receive Rewards  │
│   │(Delegator)        │         Contract            │                       │
│   └─────────┘         └─────────────┬───────────────┘                       │
│        ▲                            │                                        │
│        │                            │ Bridge                                 │
│        │ rewards                    ▼                                        │
│        │              ┌─────────────────────────────┐                       │
│        │              │        L2 Bridge            │                       │
│        │              │       (Canonical)           │                       │
│        │              └─────────────┬───────────────┘                       │
│        │                            │                                        │
└────────┼────────────────────────────┼────────────────────────────────────────┘
         │                            │
         │                            │
─────────┼────────────────────────────┼─────────────────────────────────────────
         │                            │
         │                    L2 (Tokamak L2)                                   
         │                            │                                        
         │              ┌─────────────▼───────────────┐                       
         │              │     Sequencer Vault         │                       
         │              │   (Bridged TON Storage)     │                       
         │              │                             │                       
         │              │  • Withdrawal: L1 Contract  │                       
         │              │    only                     │                       
         │              │  • Sequencer cannot use     │                       
         │              └─────────────────────────────┘                       
         │                            │                                        
         │                            ▼                                        
         │                   Bridged TON (B_i) Increase                        
         │                            │                                        
         │                            ▼                                        
         └─────────────── Seigniorage S_i Increase ───┘                        
```

### 2.2 Core Components

| Component | Location | Role |
|----------|------|------|
| SequencerDelegateStaking | L1 | Delegation management, reward distribution, withdrawal processing |
| L2 Bridge | L1 ↔ L2 | TON bridging |
| Sequencer Vault | L2 | Store delegated TON (locked) |

---

## 3. V3 Seigniorage Integration

### 3.1 V3 Seigniorage Formula

```
S_i = y(x) · B̃_i / x

Where:
- y(x) = L · x / (k + x)     // Hyperbolic Saturation Function
- x = Σ B̃_i                  // Total Bridged TON of all eligible L2s
- B̃_i = 1_i · B_i            // Bridged TON of eligible L2
- 1_i = 1 if T_i ≥ θ · B_i   // When minimum staking requirement is met

Sequencer Reward: o_i = (1 - α) · S_i
Validator Reward: v_j = Σ (α · S_i / |V_i|)
```

### 3.2 Effect of Delegation

```
Delegation Increase → Bridge to L2 → B_i (Bridged TON) Increase → S_i (Seigniorage) Increase
```

**Note**: Sequencer must meet minimum staking requirement `T_i ≥ θ · B_i` to receive seigniorage

---

## 4. Detailed Design

### 4.1 Sequencer Management

#### 4.1.1 Registration

| Item | Description |
|------|------|
| Registration Authority | Sequencer only |
| Required Information | L2 Vault address, Commission rate |
| Commission Range | No limit (0-100%) |

```solidity
function registerSequencer(address l2Vault, uint256 commission) external;
```

#### 4.1.2 Deregistration

| Item | Description |
|------|------|
| Deregistration Condition | After all delegators have withdrawn |
| Verification | `totalDelegated == 0` |

```solidity
function deregisterSequencer() external;
// requires: sequencers[msg.sender].totalDelegated == 0
```

#### 4.1.3 Commission Change

| Item | Description |
|------|------|
| Change Authority | Sequencer only |
| Effective Time | On next distribute() call |

### 4.2 Delegation

#### 4.2.1 Delegation Flow

```
1. User calls delegate(sequencer, amount)
2. Contract receives TON
3. Contract bridges to Sequencer Vault via L2 Bridge
4. Record delegation info (delegator, sequencer, amount)
5. Increase Sequencer's totalDelegated
```

#### 4.2.2 Delegation Conditions

| Item | Value |
|------|-----|
| Minimum Delegation Amount | 1,000 TON |
| Maximum Delegation Limit | None |

#### 4.2.3 Redelegation

| Item | Description |
|------|------|
| Condition | Only between Sequencers with existing delegation |
| DTD Wait | None (immediate transfer) |
| Purpose | Adjust delegation ratio between Sequencers |

```solidity
function redelegate(address fromSequencer, address toSequencer, uint256 amount) external;
// requires: delegations[msg.sender][fromSequencer].amount > 0
// requires: delegations[msg.sender][toSequencer].amount > 0
```

### 4.3 Withdrawal (Undelegation)

#### 4.3.1 Withdrawal Flow

```
Day 0:  requestUndelegate() called
        └─► Withdrawal request initiated from L2 Vault
        └─► pendingWithdrawal recorded

Day 1-14: DTD (Dispute Time Delay) waiting period
          └─► Challenge possible during this period

Day 14+: withdraw() callable
         └─► Receive TON on L1
```

#### 4.3.2 Withdrawal Conditions

| Item | Value |
|------|-----|
| DTD Period | 14 days |
| Fast Withdrawal | Not supported |
| Partial Withdrawal | Supported |

### 4.4 Reward Distribution

#### 4.4.1 Reward Reception

```
V3 Protocol ──Seigniorage──► SequencerDelegateStaking Contract
                                    │
                                    ▼
                         pendingRewards[sequencer] += amount
```

- V3 sets DelegateContract as Sequencer's reward receiving address
- Rewards automatically accumulate in `pendingRewards`

#### 4.4.2 Distribution Mechanism (MasterChef Pattern)

```solidity
// State Variables
mapping(address => uint256) public pendingRewards;      // Undistributed rewards
mapping(address => uint256) public accRewardPerShare;   // Accumulated reward per share

// Distribution function (callable by anyone)
function distribute(address sequencer) external {
    uint256 amount = pendingRewards[sequencer];
    pendingRewards[sequencer] = 0;
    
    uint256 commission = amount * sequencers[sequencer].commission / 10000;
    uint256 delegatorRewards = amount - commission;
    
    // Commission → Sequencer
    ton.transfer(sequencer, commission);
    
    // Delegator rewards → Update ledger
    accRewardPerShare[sequencer] += delegatorRewards * PRECISION / totalDelegated;
}

// Claim function
function claimRewards(address sequencer) external {
    // Distribute first if there are undistributed rewards
    if (pendingRewards[sequencer] > 0) {
        _distribute(sequencer);
    }
    
    // Calculate and transfer my share
    uint256 reward = _calculateReward(msg.sender, sequencer);
    ton.transfer(msg.sender, reward);
}
```

#### 4.4.3 Reward Calculation

```
My Reward = (My Delegation Amount × accRewardPerShare / PRECISION) - rewardDebt
```

### 4.5 Slashing

#### 4.5.1 Slashing Policy

| Item | Description |
|------|------|
| Slashing Target | Sequencer collateral (D_sequencer) only |
| Delegator Impact | None (delegated TON protected) |

#### 4.5.2 Slashing Scenario

```
Sequencer loses Fraud Proof
        │
        ▼
D_sequencer slashed (handled by V3 protocol)
        │
        ▼
Delegated TON (L2 Vault) → No impact
        │
        ▼
Delegators can withdraw normally
```

---

## 5. Sequencer Vault (L2)

### 5.1 Role

- Store delegated TON
- Contribute to Bridged TON (B_i)
- Process withdrawal requests

### 5.2 Permission Structure

| Operation | Permission |
|------|------|
| Deposit | L2 Bridge (on bridge completion) |
| Withdrawal | DelegateContract only (L1 → L2 message) |
| Other Usage | Not allowed (DeFi, transfers, etc.) |

### 5.3 Design Principles

```solidity
contract SequencerVault {
    address public immutable delegateContract;  // L1 DelegateContract address
    address public immutable sequencer;
    
    // Withdrawal only allowed from DelegateContract's L2 message
    function withdraw(address to, uint256 amount) external onlyDelegateContract {
        ton.transfer(to, amount);
    }
    
    // Sequencer cannot withdraw arbitrarily
    // External usage like DeFi not allowed
}
```

---

## 6. Data Structures

### 6.1 Sequencer Information

```solidity
struct SequencerInfo {
    bool isRegistered;           // Registration status
    address l2Vault;             // L2 Vault address
    uint256 commission;          // Fee (basis points, 10000 = 100%)
    uint256 totalDelegated;      // Total delegated amount
    uint256 accRewardPerShare;   // Accumulated reward per share
}
```

### 6.2 Delegation Information

```solidity
struct DelegationInfo {
    uint256 amount;                  // Delegation amount
    uint256 rewardDebt;              // For reward calculation
    uint256 pendingWithdrawal;       // Pending withdrawal amount
    uint256 withdrawalRequestTime;   // Withdrawal request time
}
```

---

## 7. Function Specifications

### 7.1 Sequencer Functions

| Function | Description | Permission |
|------|------|------|
| `registerSequencer(l2Vault, commission)` | Register Sequencer | Sequencer |
| `deregisterSequencer()` | Deregister Sequencer | Sequencer |
| `updateCommission(commission)` | Update Commission | Sequencer |

### 7.2 Delegator Functions

| Function | Description | Permission |
|------|------|------|
| `delegate(sequencer, amount)` | Delegate TON | Anyone |
| `requestUndelegate(sequencer, amount)` | Request withdrawal | Delegator |
| `withdraw()` | Complete withdrawal | Delegator |
| `redelegate(from, to, amount)` | Redelegate | Delegator |
| `claimRewards(sequencer)` | Claim rewards | Delegator |

### 7.3 Public Functions

| Function | Description | Permission |
|------|------|------|
| `distribute(sequencer)` | Distribute rewards | Anyone |

---

## 8. Events

```solidity
event SequencerRegistered(address indexed sequencer, address l2Vault, uint256 commission);
event SequencerDeregistered(address indexed sequencer);
event CommissionUpdated(address indexed sequencer, uint256 oldCommission, uint256 newCommission);

event Delegated(address indexed delegator, address indexed sequencer, uint256 amount);
event UndelegationRequested(address indexed delegator, address indexed sequencer, uint256 amount);
event Withdrawn(address indexed delegator, uint256 amount);
event Redelegated(address indexed delegator, address indexed from, address indexed to, uint256 amount);

event RewardsDistributed(address indexed sequencer, uint256 totalAmount, uint256 commission);
event RewardsClaimed(address indexed delegator, address indexed sequencer, uint256 amount);
```

---

## 9. Security Considerations

### 9.1 Reentrancy

- State changes before all external calls (Checks-Effects-Interactions)
- Apply ReentrancyGuard

### 9.2 Sequencer Vault Security

- Restrict withdrawal authority to DelegateContract
- Prevent arbitrary usage by Sequencer

### 9.3 Reward Distribution Accuracy

- Minimize precision loss in MasterChef pattern (PRECISION = 1e18)
- Overflow prevention (Solidity 0.8+)

### 9.4 Bridge Risk

- Use Canonical Bridge (verified bridge)
- Recommend gradual delegation

---

## 10. Undecided Items

| Item | Status | Notes |
|------|------|------|
| L2 Bridge Interface | Needs Confirmation | Verify Tokamak L2 bridge specs |
| V3 Reward Receiving Address Setting | Assumed | Assumed contract address can be set |
| Sequencer Vault Deployer | Undecided | Sequencer vs Protocol |

---

## 11. Future Considerations

### 11.1 Fast Withdrawal

- Current: Not supported
- Future: Can add liquidity pool-based Fast Withdrawal

### 11.2 Liquid Staking

- Current: Not supported
- Future: Can issue stTON token for DeFi integration

### 11.3 Multi-Sequencer Delegation

- Current: Supported (distributed delegation to multiple Sequencers)
- Consideration: Auto-rebalancing feature

---

## Appendix A: Glossary

| Term | Definition |
|------|------|
| Bridged TON (B_i) | Total amount of TON bridged to L2 |
| DTD | Dispute Time Delay, withdrawal waiting period |
| Commission | Fee rate taken by Sequencer from rewards |
| accRewardPerShare | Accumulated reward per delegation unit (MasterChef pattern) |
| rewardDebt | Already reflected rewards (prevents duplicate claims) |

## Appendix B: References

- [Tokamak Economics Whitepaper V3](./Tokamak_Economics_Whitepaper_V3.pdf)
- [Staking V2 Documentation](./StakingV2.md)
