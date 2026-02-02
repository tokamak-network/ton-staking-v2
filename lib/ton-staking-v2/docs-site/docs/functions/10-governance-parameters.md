---
id: functions-governance-parameters
sidebar_position: 10
---

# Governance Parameters

Complete list of governance parameters for all contracts.

## SeigManager Parameters

| Parameter | Function | Range | Unit |
|-----------|----------|-------|------|
| `daoDistributionRatio` | `setDaoDistributionRatio(d)` | 0 < d < 1 | RAY |
| `minStakingRatio` | `setMinStakingRatio(θ)` | 0 < θ ≤ 1 | RAY |
| `validatorDistributionRatio` | `setValidatorDistributionRatio(α)` | 0 < α < 1 | RAY |
| `halfSaturationPoint` | `setHalfSaturationPoint(k)` | k > 0 | RAY (TON) |

### Slashing Parameters

| Parameter | Function | Range | Unit |
|-----------|----------|-------|------|
| `maxFraudProofCost` | `setMaxFraudProofCost(C_max)` | C_max > 0 | WTON |
| `sequencerAdditionalReward` | `setSequencerAdditionalReward(Δ)` | Δ ≥ 0 | WTON |
| `maxChallengers` | `setMaxChallengers(H_max)` | H_max > 0 | count |

---

## RAT Parameters

| Parameter | Function | Range | Unit |
|-----------|----------|-------|------|
| `slashingPenalty` | `setSlashingPenalty(C_off)` | C_off > 0 | TON |
| `validatorBuffer` | `setValidatorBuffer(Δ)` | Δ ≥ 0 | TON |
| `ratTriggerProbability` | `setRatTriggerProbability(π_a)` | 0 < π_a ≤ 1 | RAY |
| `minimumThreshold` | `setMinimumThreshold(D_min)` | D_min > 0 | TON |
| `evidenceSubmissionPeriod` | `setEvidenceSubmissionPeriod(t)` | t > 0 | seconds |
| `validatorReward` | `setValidatorReward(addr)` | addr != 0 | address |

---

## ValidatorReward Parameters

| Parameter | Function | Range | Unit |
|-----------|----------|-------|------|
| `seigManager` | `setSeigManager(addr)` | addr != 0 | address |
| `ratContract` | `setRatContract(addr)` | addr != 0 | address |

---

## Parameter Relationships

### D_sequencer Calculation

```
D_sequencer = maxChallengers × maxFraudProofCost + sequencerAdditionalReward

Example:
maxChallengers = 3
maxFraudProofCost = 50e27 WTON
sequencerAdditionalReward = 100e27 WTON
→ D_sequencer = 3 × 50e27 + 100e27 = 250e27 WTON
```

### D_min (Validator) Calculation

```
C_off = max(slashingPenalty, (c_m × N × RAY) / π_a)
D_min = C_off + validatorBuffer

Example:
slashingPenalty = 100e27 WTON
attentionCost = 150e27 WTON
N = 3 (3 validators)
π_a = 1e27 (100%)
validatorBuffer = 100e27 WTON

→ C_off = max(100e27, (150e27 × 3 × 1e27) / 1e27) 
        = max(100e27, 450e27) 
        = 450e27 WTON

→ D_min = 450e27 + 100e27 = 550e27 WTON
```

---

## Governance Mode Settings

### Relaxed Mode (Early Network)

For validator attraction in early network stages:

```solidity
// Relaxed mode
rat.setRelaxedValidatorCheck(true);
rat.setSlashingPenalty(100e27);  // Use fixed value only
```

### Strict Mode (Stable Network)

For security-first in stable network:

```solidity
// Strict mode
rat.setRelaxedValidatorCheck(false);
rat.setAttentionCost(150e27);     // Activate dynamic formula
rat.setRatTriggerProbability(1e27);
```
