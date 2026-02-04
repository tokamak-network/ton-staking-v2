# Delegate Staking MVP - V3 Development Team Discussion Points

**Date**: 2026-01-28
**Purpose**: MVP integration discussion with ton-staking-v3 development team

---

## 1. Development Completion Status

### 1.1 MVP Implementation Summary

| Item | Status | Note |
|------|--------|------|
| DelegateStakingMVP.sol | ✅ Complete | 433 LOC |
| Test Suite | ✅ Complete | 38 tests passing |
| Interface | ✅ Complete | IDelegateStakingMVP.sol |

### 1.2 MVP Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                 Sequencer Trust Model (MVP)                  │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  SeigManager ──WTON──► OperatorManager                       │
│                              │                               │
│                              ▼                               │
│                    Sequencer calls claimERC20()              │
│                              │                               │
│                              ▼                               │
│  DelegateStakingMVP ◄──────WTON────── Sequencer manual transfer │
│       │                                                      │
│       ├─► accRewardPerShare update (MasterChef pattern)      │
│       │                                                      │
│       └─► Delegators claimRewards() → Receive WTON rewards   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 1.3 Key Functions

**Sequencer Functions:**
- `registerSequencer(layer2, commission)` - Register Sequencer
- `receiveReward(amount)` - Deposit rewards (WTON)
- `claimCommission()` - Claim commission

**Delegator Functions:**
- `stake(sequencer, amount)` - Stake TON
- `unstake(sequencer, amount)` - Request unstake
- `withdraw(sequencer)` - Withdraw (after unbonding)
- `claimRewards(sequencer)` - Claim WTON rewards

---

## 2. Discussion Points with V3 Team

### 2.1 Reward Receipt Mechanism (Most Important)

**Current MVP Approach (Sequencer Trust Model):**
```
V3 Protocol → OperatorManager → Sequencer Wallet → DelegateStakingMVP
```

**Questions:**
1. **Protocol Modification Feasibility**: Can `operatorOfLayer[layer2]` be set to the DelegateStaking contract?
2. **OperatorManager Extension**: Is it possible to add logic that automatically forwards rewards to DelegateStaking upon receiveReward?
3. **Alternative**: Is there another safe way to receive rewards without protocol modification?

**Proposed Options:**

| Option | Description | V3 Modification Required |
|--------|-------------|--------------------------|
| A. Direct Receipt | DelegateStaking acts as operator | Layer2Manager modification |
| B. OperatorManager Extension | Automatic reward forwarding | OperatorManager modification |
| C. Current MVP Approach | Sequencer manual transfer | None |
| D. Approve Model | Sequencer approves, anyone can transfer | None |

### 2.2 Bridged TON Increase Mechanism

**Current MVP Approach:**
- TON is held in L1 DelegateStakingMVP contract
- Sequencer separately bridges to L2 to increase B_i

**Questions:**
1. **Automatic Bridge Support**: Can an automatic bridge interface from DelegateStaking → L2 Vault be provided?
2. **TVL Reflection Timing**: When is it reflected in `layer2TVL()` after bridging?
3. **Vault Structure**: Is there a standard L2 Vault structure per Sequencer?

### 2.3 Eligibility Integration

**Current Understanding:**
```
T_i ≥ max(θ × B_i, D_sequencer)
```

**Questions:**
1. **Eligibility Query API**: What are the exact return values and meanings of `checkCurrentEligibility(layer2)`?
2. **Caution When Delegation Increases**: When B_i increases, T_i requirements also increase. Is there a warning mechanism for Sequencers?
3. **When Eligibility is Lost**: How are existing rewards handled when eligibility is lost?

### 2.4 Withdrawal Waiting Period (DTD)

**Current MVP Approach:**
- Simple unbondingPeriod (default 7 days) then withdrawal

**Questions:**
1. **Actual DTD**: What is the actual waiting period for L2 → L1 bridge?
2. **Verification Mechanism**: Is integration with withdrawal verification (Optimism fraud proof, etc.) required?
3. **Emergency Withdrawal**: Any plans for emergency withdrawal mechanism in Full Version?

---

## 3. Technical Verification Items

### 3.1 Contract Addresses (Mainnet)

| Contract | Address | Needs Confirmation |
|----------|---------|-------------------|
| TON | ? | ✓ |
| WTON | ? | ✓ |
| SeigManager | ? | ✓ |
| Layer2Manager | ? | ✓ |
| L1BridgeRegistry | ? | ✓ |

### 3.2 Token Unit Verification

**Current Understanding:**
```
TON:  18 decimals
WTON: 27 decimals (RAY)
```

**Questions:**
1. Are the above units correct?
2. Is using `* 1e9` / `/ 1e9` for TON ↔ WTON conversion correct?

### 3.3 V3 Function Signature Verification

```solidity
// Functions to be used
SeigManager.checkCurrentEligibility(layer2) → (bool, uint256, uint256)
SeigManager.getSequencerStaked(layer2) → uint256
Layer2Manager.operatorOfLayer(layer2) → address
L1BridgeRegistry.layer2TVL(systemConfig) → uint256
```

**Question:** Do the above signatures match the current V3?

---

## 4. Future Roadmap Discussion

### 4.1 Full Version Considerations

| Feature | MVP | Full Version | V3 Support Needed? |
|---------|-----|--------------|-------------------|
| TON Storage | L1 Contract | L2 Vault | ✓ |
| Reward Receipt | Sequencer Manual | Protocol Direct | ✓ |
| Bridge | Sequencer Separate | Automatic Bridge | ✓ |
| Withdrawal | Simple Unbonding | DTD 14 days + Verification | ✓ |

### 4.2 Protocol Modification Requests (If Any)

**Modifications needed if Option A is selected:**
```solidity
// Layer2ManagerV3.sol
function setDelegateStaking(address layer2, address delegateStaking) external;

// Or extend existing operatorOfLayer setting permissions
```

**Modifications needed if Option B is selected:**
```solidity
// OperatorManagerV1_2.sol
function setRewardReceiver(address receiver) external;
function claimAndForward() external;
```

---

## 5. Testing and Verification Plan

### 5.1 Fork Test Plan

```bash
# Mainnet fork test
forge test --fork-url $MAINNET_RPC --match-contract IntegrationTest
```

**Test Scenarios:**
1. Integration with actual V3 contracts
2. Eligibility query and verification
3. Reward distribution simulation

### 5.2 Testnet Deployment Plan

- Sepolia or Titan Sepolia
- V3 testnet contract integration

**Question:** Can V3 testnet contract addresses be provided?

---

## 6. Schedule and Collaboration

### 6.1 Proposed Schedule

| Phase | Expected Duration | Dependencies |
|-------|-------------------|--------------|
| V3 Team Discussion | 1 week | - |
| Integration Approach Decision | - | Discussion results |
| Fork Test | 1 week | Contract addresses |
| Testnet Deployment | 1 week | Testnet addresses |

### 6.2 Requested Materials

1. V3 contract addresses (Mainnet, Testnet)
2. L2 bridge interface documentation
3. OperatorManager extension guide (if Option B is selected)

---

## 7. Appendix: Code Reference

### 7.1 MVP Key Files

```
delegate-staking/
├── src/
│   ├── DelegateStakingMVP.sol       # MVP implementation
│   └── interfaces/
│       └── IDelegateStakingMVP.sol  # Interface
├── test/
│   ├── DelegateStakingMVP.t.sol     # Tests (38)
│   └── mocks/
│       └── WTONMock.sol             # WTON mock (27 decimals)
└── docs/
    ├── DEVELOPMENT-CONSIDERATIONS.md
    └── ton-staking-v3-analysis.md   # V3 analysis document
```

### 7.2 Core Logic (Reward Distribution)

```solidity
// DelegateStakingMVP.sol:152-179
function receiveReward(uint256 amount) external override nonReentrant {
    // Sequencer deposits WTON rewards
    wton.safeTransferFrom(msg.sender, address(this), amount);

    // Calculate commission
    uint256 commission = (amount * info.commission) / 10000;
    uint256 distributed = amount - commission;

    // Distribute using MasterChef pattern
    if (info.totalStaked > 0) {
        info.accRewardPerShare += (distributed * RAY) / info.totalStaked;
    }
}
```

---

*This document was written for technical discussion with the V3 development team.*
