---
id: functions-sequencer-slashing
sidebar_position: 8
---

# Sequencer Slashing Functions

Sequencer slashing functions handled in SeigManager V3.

## slashSequencerByGame

Slashes sequencer (Permissionless). Handled in SeigManager in V3.

```solidity
function slashSequencerByGame(address gameAddress) external whenV3Active whenNotPaused
```

| Item | Content |
|------|---------|
| **Caller** | Anyone |
| **Condition** | Game ended with status != DEFENDER_WINS |

**Operation Flow**:
```
1. Verify DisputeGameFactory (prevent fake games)
2. Check game status: status != DEFENDER_WINS
3. Confiscate sequencer's entire staking amount (coinage.burnFrom)
4. Calculate challenger reward: C_max + Δ/n
5. Pay challenger reward (WTON.mint)
6. Remainder: DAO Treasury
7. Event: SequencerSlashed
```

> **V3 Change**: Sequencer collateral uses existing staking system (coinage).

---

## Related Events

```solidity
event SequencerSlashed(
    address indexed layer2,
    address indexed gameAddress,
    uint256 slashedAmount,
    address challenger,
    uint256 challengerReward
);
```

---

## Governance Parameters

| Parameter | Function | Range | Unit |
|-----------|----------|-------|------|
| `maxFraudProofCost` | `setMaxFraudProofCost(C_max)` | C_max > 0 | WTON |
| `sequencerAdditionalReward` | `setSequencerAdditionalReward(Δ)` | Δ ≥ 0 | WTON |
| `maxChallengers` | `setMaxChallengers(H_max)` | H_max > 0 | count |

**Slashing Parameter Usage**:

Used in D_sequencer calculation:
```
D_sequencer = maxChallengers × maxFraudProofCost + sequencerAdditionalReward

Example:
maxChallengers = 3
maxFraudProofCost = 50e27 WTON
sequencerAdditionalReward = 100e27 WTON
→ D_sequencer = 3 × 50e27 + 100e27 = 250e27 WTON
```
