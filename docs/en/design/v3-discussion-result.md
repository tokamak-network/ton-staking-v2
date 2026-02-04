# Delegate Staking V3 Integration Discussion Results

> **Date**: February 2, 2025
> **Participants**: Jason Hwang, YEONGJU BAK, Harvey Jo
> **Purpose**: Discussion on integrating Delegate Staking with Tokamak V3 staking

---

## 1. Key Conclusions

| Item | Decision |
|------|----------|
| **Development Approach** | **Develop as a separate feature** without modifying existing V3 contracts |
| **Seigniorage Distribution** | L2 contract **distributes directly** to stakers |
| **Feature Nature** | **Utility feature** not in whitepaper, **optional** for L2 sequencers |
| **Development Base** | **Branch separation** from ton-staking-v3 repository |

---

## 2. Detailed Discussion

### 2.1 Purpose of Delegate Staking

**Question**: Does Delegate Staking align with V3's original purpose of L2 activation and increasing Bridged TON?

**Conclusion**:
- Staking on L1 can be viewed as **representing L2 staking**
- **Aligns** with the goal of increasing L2 volume
- Enables seigniorage distribution to users by locking staking volume within L2

### 2.2 Relationship with Existing V2/V3 Staking

| Version | Status | Notes |
|---------|--------|-------|
| V2 | **Maintained** | Cannot forcibly move existing user assets |
| V3 | **Under development** | Pre-testnet deployment stage |
| Delegate Staking | **Separate feature** | Utility added to V3 |

**Migration Plan**:
- For existing V1/V2 staking users
- Consider providing an **easy migration interface** to L2 Delegate Staking

### 2.3 Seigniorage Distribution Structure

```
┌─────────────────────────────────────────────────────────────┐
│                        L1 (Ethereum)                         │
│                                                              │
│   ┌──────────────────┐      ┌─────────────────────────┐     │
│   │  SeigManager     │─────►│   OperatorManager       │     │
│   │  (Seigniorage    │      │   (Sequencer Reward     │     │
│   │   Calculation)   │      │    Management)          │     │
│   └──────────────────┘      └───────────┬─────────────┘     │
│                                         │                    │
│                              ┌──────────▼──────────┐        │
│                              │  Trigger Contract   │        │
│                              │  (Optional Feature) │        │
│                              └──────────┬──────────┘        │
└─────────────────────────────────────────┼───────────────────┘
                                          │ Bridge
┌─────────────────────────────────────────┼───────────────────┐
│                        L2               │                    │
│                              ┌──────────▼──────────┐        │
│                              │  L2 Staking Contract │        │
│                              │  (Direct Seigniorage │        │
│                              │   Distribution)      │        │
│                              └──────────┬──────────┘        │
│                                         │                    │
│                    ┌────────────────────┼────────────────┐  │
│                    ▼                    ▼                ▼  │
│              ┌─────────┐          ┌─────────┐      ┌─────────┐
│              │ Staker A│          │ Staker B│      │ Staker C│
│              └─────────┘          └─────────┘      └─────────┘
└─────────────────────────────────────────────────────────────┘
```

**Distribution Method Options**:
1. **Direct Sequencer Distribution**: Sequencer receives seigniorage and distributes directly to stakers
2. **Automatic Trigger**: Automatically transfers OperatorManager's seigniorage to L2 staking contract
   - Warning: Not all L2s may want this, requiring a **separate Trigger Contract**

### 2.4 Trust Issues and Risks

**Problem**: Handling staking assets if L2 sequencer ceases operations

**Reality**:
- Delegate Staking is based on **trust in the sequencer**
- Difficult to withdraw assets if L2 operation stops

**Solutions (Discussed)**:

| Solution | Status | Description |
|----------|--------|-------------|
| Emergency Exit | Under development | Emergency escape route when L2 issues occur |
| Challenger/Validator | Not in whitepaper | Replacing L2 Proposer role |
| EOA Escape Hatch | Under development | Escape for non-contract addresses |

**Recommendations**:
- Additional measures needed for unspecified L2s
- Emergency Exit mechanism implementation required before production

---

## 3. Development Guidelines

### 3.1 Development Environment

```bash
# Based on ton-staking-v3 repository
git clone https://github.com/tokamak-network/ton-staking-v2.git
git checkout ton-staking-v3/dev

# Create delegate-staking branch
git checkout -b feature/delegate-staking
```

### 3.2 Code Structure Principles

**Core Principle**: **Separate logic** without touching existing code

```
ton-staking-v2/
├── src/
│   ├── stake/
│   │   ├── managers/
│   │   │   ├── SeigManagerV3_1.sol      # Existing - Do not modify
│   │   │   └── ...
│   │   └── interfaces/
│   │       └── ISeigManagerV3.sol       # Existing - Do not modify
│   │
│   └── delegate/                         # Create new folder
│       ├── DelegateStaking.sol          # Delegate Staking main
│       ├── DelegateTrigger.sol          # Seigniorage trigger
│       └── interfaces/
│           └── IDelegateStaking.sol
```

### 3.3 Required Additional Development Items

| Item | Description | Priority |
|------|-------------|----------|
| **L2 Deposit Function** | L1→L2 staking interface | High |
| **Seigniorage Trigger** | OperatorManager integration | High |
| **Emergency Exit** | Emergency escape mechanism | High |
| **V1→Delegate Migration** | Support for existing user migration | Medium |

### 3.4 Testing Approach

```bash
# Focus on E2E testing in local environment
forge test --match-path "test/delegate/*.t.sol" -vvv

# Frontend verification also performed locally
anvil --fork-url $MAINNET_RPC_URL
```

---

## 4. Next Steps (Action Items)

### Immediate

- [ ] Create delegate-staking branch from ton-staking-v3/dev branch
- [ ] Create `src/delegate/` folder structure
- [ ] Analyze existing interfaces and design additional functions

### Short-term (1-2 weeks)

- [ ] Draft DelegateStaking contract
- [ ] Design seigniorage trigger mechanism
- [ ] Set up local E2E test environment

### Mid-term (3-4 weeks)

- [ ] Design and implement Emergency Exit mechanism
- [ ] Request review from V3 team (LRM)
- [ ] Prepare for testnet deployment

---

## 5. Reference Information

### Contact
- V3 Contract related: YEONGJU BAK
- Feel free to inquire anytime during development

### Related Documents
- [ton-staking-v3 Analysis](./ton-staking-v3-analysis.md)
- [Development Considerations](./DEVELOPMENT-CONSIDERATIONS.md)
- [V3 Discussion Points](./V3-DISCUSSION-POINTS.md)

### Notes
> Warning: **AI Era Development Direction**: It is more efficient to focus on **contract development** rather than frontend
>
> Frontend can be quickly generated with AI tools, but understanding contract logic is key
