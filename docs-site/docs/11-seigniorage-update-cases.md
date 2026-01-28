---
id: 11-seigniorage-update-cases
sidebar_position: 11
---
# Complete Seigniorage Update Cases

> **Last Updated**: 2026-01-27

---

## Seigniorage Minting Timing

### Minting Triggers

| Trigger | Minting Occurs? |
|---------|----------------|
| `updateSeigniorage()` call | ✅ |
| Eligibility change (eligible↔ineligible) | ✅ |
| Eligibility maintained (no change) | ❌ |

### Eligibility Change Cases

| Situation | Eligibility Change | Minting |
|-----------|-------------------|---------|
| Portal TON withdrawal → eligibility loss | eligible→ineligible | ✅ |
| Staking withdrawal → eligibility loss | eligible→ineligible | ✅ |
| Staking deposit → eligibility gain | ineligible→eligible | ✅ |
| Portal TON deposit → eligibility gain | ineligible→eligible | ✅ |

**Key**: When eligibility changes, seigniorage settlement must occur first

---

## 5. Function Call Paths

### 5.1 Seigniorage Distribution Path

```
updateSeigniorage() [external]
  └→ _updateSeigniorageV3() [internal]
       ├→ if (paused) return true;  ← 전역 일시정지 체크
       ├→ _checkCoinage()  ← coinage 없으면 revert
       ├→ 같은 블록: _claimL2RewardsOnly()
       │              └→ if (!allowed || _isPauseL2Seigniorage) return;
       └→ 다른 블록: _increaseTotV3()
                      └→ _distributeV3Seigniorage()
                           ├→ 전역 시뇨리지 mint (layer2Manager, validatorReward)
                           ├→ rewardPerUnit 업데이트
                           └→ _claimL2Rewards()
                                └→ if (!allowed || _isPauseL2Seigniorage) return 0;
```

### 5.2 Eligibility Change Path

```
onBridgedTonChange() [external, Portal 호출]
  └→ if (!v3Migrated) return;
  └→ _updateEligibilityInternal(layer2)

onStakingChange() [external, DepositManager 호출]
  └→ if (!v3Migrated) return;
  └→ _updateEligibilityInternal(layer2)

_updateEligibilityInternal(layer2) [internal]
  ├→ TYPE 3 롤업 체크 (early return if not TYPE 3)
  ├→ oldEligible = info.isEligible
  ├→ bridgedTon = Layer2Manager.getBridgedTonByLayer(layer2)
  ├→ currentBridgedTON = bridgedTon * GWEI_UNIT
  ├→ newEligible = _checkEligibilityInternal(layer2, bridgedTon)
  │    └→ bridgedTon = 0이면 eligible = false
  ├→ Case 1: 자격 유지 (oldEligible == newEligible)
  │    └→ 아무것도 안 함 (return)
  └→ Case 2: 자격 변경
       ├→ _triggerSeigniorageDistribution() ← 먼저 시뇨리지 정산!
       ├→ 자격 상실 (true → false): _handleEligibilityLoss(layer2)
       └→ 자격 획득 (false → true): effectiveBridgedTON 설정 + initialDebt 설정
```

### 5.3 Eligibility Loss Handling

```
_handleEligibilityLoss(layer2) [internal]
  └→ if (effectiveBridgedTON > 0)
       │  (effectiveBridgedTON > 0이면 allowed=true 보장됨)
       │
       ├→ rollupConfig 조회 (distributeL2Rewards에 필요)
       ├→ layer2Seigs 계산 (sequencer 보상)
       ├→ valReward 계산 (validator 보상)
       ├→ transferL2Seigniorage() (sequencer)
       ├→ distributeL2Rewards() (validator)
       ├→ totalEffectiveBridgedTON -= effectiveBridgedTON
       └→ info.effectiveBridgedTON = 0
```

**Note**: `allowed` check unnecessary - if `effectiveBridgedTON > 0`, then `allowed=true` is guaranteed (see Case D)

### 5.4 Claim During Pause (claimL2Seigniorage)

```
claimL2Seigniorage(layer2) [external]
  ├→ if (!v3Migrated) revert;
  ├→ if (!allowed || excluded) return (0, 0);
  ├→ if (!isEligible || effectiveBridgedTON == 0) return (0, 0);
  │
  ├→ layer2Seigs 계산 (sequencer 보상)
  ├→ valReward 계산 (validator 보상)
  ├→ transferL2Seigniorage() (sequencer)
  ├→ distributeL2Rewards() (validator)
  │
  └→ initialDebt, validatorInitialDebt 업데이트 (중복 claim 방지)
```

**claimL2Seigniorage vs _handleEligibilityLoss Comparison**:

| | `claimL2Seigniorage` | `_handleEligibilityLoss` |
|---|---|---|
| **Purpose** | Simple claim | Eligibility loss handling |
| **Pause check** | ❌ None | ❌ None |
| **Claim** | ✅ | ✅ |
| **effectiveBridgedTON** | Maintained | Reset to 0 |
| **totalEffectiveBridgedTON** | Maintained | Deducted |
| **Call timing** | Anytime (external) | On eligibility loss (internal) |

### 5.5 Seigniorage Settlement Before Eligibility Change

```
_triggerSeigniorageDistribution() [internal]
  ├→ if (paused) return;  ← 일시정지 시 스킵
  ├→ if (block.number <= _lastSeigBlock) return;  ← 같은 블록이면 스킵
  ├→ if (address(_tot) == address(0)) return;  ← tot 없으면 스킵
  ├→ if (_tot.totalSupply() == 0) → _lastSeigBlock 업데이트 후 return
  └→ 시뇨리지 분배 (claim 없이 rewardPerUnit만 업데이트)
       ├→ A = span * _seigPerBlock
       ├→ rewardPerUnit 업데이트
       ├→ WTON mint (Layer2Manager, ValidatorReward)
       └→ DAO 보상 mint
```

---

## 6. Eligibility Change Handling Principles

| State Change | Action |
|--------------|--------|
| Eligibility maintained (eligible → eligible) | Do nothing |
| Eligibility maintained (ineligible → ineligible) | Do nothing |
| Eligibility loss (eligible → ineligible) | **Seigniorage settlement** + auto claim unclaimed rewards + effectiveBridgedTON = 0 |
| Eligibility gain (ineligible → eligible) | **Seigniorage settlement** + effectiveBridgedTON setup + initialDebt setup |

**Eligibility Conditions** (checkCurrentEligibility):
- Must be TYPE 3 rollup (Dispute Game support)
- `bridgedTon > 0` (required)
- `currentStake >= requiredStake`

**If bridgedTon = 0, always ineligible**:
- On initial registration: Ineligible until TON bridge → Eligible when TON bridged
- On withdrawal: Eligibility loss → `_handleEligibilityLoss` triggered → auto claim unclaimed rewards

**Design Rationale**:
- Seigniorage claims only occur at `updateSeigniorage` timing
- `_updateEligibilityInternal` only handles state tracking
- If eligibility maintained, `effectiveBridgedTON` update unnecessary (handled in next `updateSeigniorage`)
- bridgedTON changes not immediately reflected, reflected on `updateSeigniorage` call
- **Seigniorage settlement on eligibility gain**: Fairly distribute to existing L2s before new L2 participates

---

## 7. Case-by-Case Behavior

### Case A: Normal State (paused=false, allowed=true)

| Function | Action |
|----------|--------|
| `updateSeigniorage()` | Seigniorage distribution + claim ✓ |
| `onStakingChange()` | Eligibility update ✓ |
| `onBridgedTonChange()` | Eligibility update ✓ |
| On eligibility loss | `_handleEligibilityLoss()` → claim unclaimed rewards ✓ |

### Case B: Global Pause (paused=true)

| Function | Action |
|----------|--------|
| `pause()` | V3: Call `_triggerSeigniorageDistribution()` (auto issue up to pause block) |
|           | V2: `require(_pausedBlock < _lastSeigBlock)` (manual updateSeigniorage required) |
| `updateSeigniorage()` | Early return (no seigniorage distribution) |
| `claimL2Seigniorage()` | **Claim possible** ✓ (no pause check) |
| `onStakingChange()` | Eligibility update ✓ (ignores pause!) |
| `onBridgedTonChange()` | Eligibility update ✓ (ignores pause!) |
| On eligibility loss | `_handleEligibilityLoss()` → claim unclaimed rewards ✓ |

**V3 pause() Behavior**:
- Auto issue seigniorage up to pause block (`_triggerSeigniorageDistribution`)
- `_lastSeigBlock = block.number`, `_pausedBlock = block.number + 1`
- Pause period starts from next block (current block has seigniorage issued)
- Prevent seigniorage loss on eligibility change during pause

**V3 claimL2Seigniorage() Behavior**:
- Can claim existing issued amounts even in pause state
- No seigniorage issuance (no rewardPerUnit update)
- Eligibility maintained (no effectiveBridgedTON change)

**Note**: Eligibility changes are processed even in global pause state

### Case C: L2-Specific Pause (`_isPauseL2Seigniorage=true`)

| Function | Action |
|----------|--------|
| `updateSeigniorage()` | Global distribution ✓, this L2 claim ✗ |
| `onStakingChange()` | Eligibility update ✓ (ignores pause!) |
| `onBridgedTonChange()` | Eligibility update ✓ (ignores pause!) |
| On eligibility loss | effectiveBridgedTON=0 (already set in `excludeFromL2Seigniorage`) |
|             | `_handleEligibilityLoss()` does nothing |

**Safety**: On L2-specific pause, `excludeFromL2Seigniorage` already sets `effectiveBridgedTON=0`

### Case D: allowed State Analysis

**Meaning of `allowed`**: `Layer2Manager.statusLayer2(rollupConfig) == 1` (L2 active state)

| status | Meaning | allowed |
|--------|---------|---------|
| 0 | Unregistered | ❌ false |
| 1 | Registered (active) | ✅ true |
| 2 | Paused | ❌ false |

**`allowed=false + effectiveBridgedTON>0` is impossible:**
- Only path to `status=2`: `pauseCandidateAddOn()`
- This function calls `excludeFromL2Seigniorage()` first → sets `effectiveBridgedTON=0`
- Therefore `allowed` check unnecessary in `_handleEligibilityLoss`

---

## 8. Design Decisions

| Case | Phenomenon | Current Behavior | Note |
|------|------------|------------------|------|
| Global paused + eligibility change | Eligibility changed | `_handleEligibilityLoss` called, claimed | ✅ Intended |
| L2 paused + eligibility change | effectiveBridgedTON already 0 | Does nothing | ✅ Safe |
| allowed=false + eligibility loss | - | Impossible | ✅ Design guarantee |

---

## 9. Current `_handleEligibilityLoss` Logic

```solidity
/// @dev Eligibility loss handling: auto claim unclaimed rewards + effectiveBridgedTON reset
/// @param layer2 L2 address losing eligibility
/// @notice If effectiveBridgedTON > 0, allowed=true is guaranteed (exclude called first in pauseCandidateAddOn)
function _handleEligibilityLoss(address layer2) internal {
    BridgedTONInfo storage info = bridgedTONInfo[layer2];

    uint256 layer2Seigs = 0;
    uint256 valReward = 0;

    // Cache: effectiveBridgedTON (multiple SLOAD → single)
    uint256 _effectiveBridged = info.effectiveBridgedTON;

    // Only process if effectiveBridgedTON > 0 (skip if already 0 due to pause)
    // allowed check unnecessary:
    // - For allowed=false, Layer2Manager.statusLayer2() != 1 required
    // - Only path to status=2: Layer2Manager.pauseCandidateAddOn()
    // - pauseCandidateAddOn() calls excludeFromL2Seigniorage() first → effectiveBridgedTON=0
    // - Therefore if effectiveBridgedTON > 0, status=1 (allowed=true) guaranteed
    if (_effectiveBridged > 0) {
        // Query rollupConfig (needed for distributeL2Rewards)
        (address rollupConfig, ) = _allowIssuanceLayer2Seigs(layer2);

        // Sequencer reward: based on bridgedTONRewardPerUint
        layer2Seigs = (bridgedTONRewardPerUint * _effectiveBridged) / WEI_UNIT - info.initialDebt;

        // Validator reward: based on validatorRewardPerUint
        valReward = (validatorRewardPerUint * _effectiveBridged) / WEI_UNIT - info.validatorInitialDebt;

        // Sequencer reward transfer
        if (layer2Seigs > 0) {
            ILayer2Manager(layer2Manager).transferL2Seigniorage(layer2, layer2Seigs);
        }

        // Validator reward distribution
        if (valReward > 0 && validatorReward != address(0)) {
            IValidatorReward(validatorReward).distributeL2Rewards(rollupConfig, valReward);
        }

        // Reset effectiveBridgedTON
        totalEffectiveBridgedTON -= _effectiveBridged;
        info.effectiveBridgedTON = 0;
    }

    emit AutoClaimBeforeEligibilityLoss(layer2, layer2Seigs, valReward);
}
```

---

## 10. Design Rationale

### 10.1 Why Allow Eligibility Changes During Pause

- Pause means **stopping new seigniorage distribution**
- Does not block claiming existing unclaimed rewards
- Eligibility changes are state management, independent of pause

### 10.2 Why L2-Specific Pause is Safe

- On `excludeFromL2Seigniorage` call, `effectiveBridgedTON = 0` is set
- Therefore `if (info.effectiveBridgedTON > 0)` condition in `_handleEligibilityLoss` is false
- No additional processing needed

### 10.3 allowed=false + effectiveBridgedTON>0 Case

**This case is impossible:**
- For `allowed=false`, `Layer2Manager.statusLayer2() != 1` required
- Only path to `status=2`: `pauseCandidateAddOn()`
- `pauseCandidateAddOn()` calls `excludeFromL2Seigniorage()` first → `effectiveBridgedTON=0`
- Therefore if `effectiveBridgedTON > 0`, `allowed=true` guaranteed
- `allowed` check unnecessary in `_handleEligibilityLoss` (code optimized)

### 10.4 Why Settle Seigniorage on Eligibility Change

Why `_triggerSeigniorageDistribution()` is called **first** when eligibility changes (in `_updateEligibilityInternal`):

#### On Eligibility Loss:
1. **Update rewardPerUnit**: Distribute seigniorage from `lastSeigBlock` to current block
2. **Accurate unclaimed reward calculation**: Claim in `_handleEligibilityLoss` based on latest rewardPerUnit
3. **Prevent seigniorage loss**: No reward loss even if `onStakingChange` called immediately without `updateSeigniorage`

#### On Eligibility Gain:
1. **Fairness guarantee**: Settle seigniorage accumulated by existing L2s first
2. **Update rewardPerUnit**: Set new L2's initialDebt based on latest rewardPerUnit
3. **Prevent duplicate distribution**: Even if multiple L2s gain eligibility in same block, seigniorage distributed only once

---

## 11. V3 Seigniorage Flow Diagram

```
updateSeigniorage() call
│
├─ block.number > _lastSeigBlock? NO → _claimL2RewardsOnly() (same block redistribution)
│
└─ YES → _increaseTotV3()
   │
   ├─ span = block.number - _lastSeigBlock (excluding pause period)
   ├─ A = span * _seigPerBlock (total seigniorage)
   ├─ _lastSeigBlock = block.number (update)
   │
   └─ _distributeV3Seigniorage(A)
      │
      ├─ sDao = A * daoDistributionRatio / RAY_UNIT
      ├─ L = A - sDao
      │
      ├─ IF totalEffectiveBridgedTON > 0:
      │  │
      │  ├─ y = L * x / (k + x)  // Hyperbolic saturation
      │  │
      │  ├─ totalSeqReward = y * (RAY_UNIT - α) / RAY_UNIT
      │  ├─ totalValReward = y * α / RAY_UNIT
      │  │
      │  ├─ MINT: Sequencer → layer2Manager (totalSeqReward)
      │  ├─ MINT: Validator → validatorReward (totalValReward)
      │  │
      │  ├─ UPDATE: bridgedTONRewardPerUint += totalSeqReward * WEI_UNIT / x
      │  ├─ UPDATE: validatorRewardPerUint += totalValReward * WEI_UNIT / x
      │  │
      │  └─ _claimL2Rewards() (claim rewards for calling L2)
      │     │
      │     ├─ _syncEffectiveBridgedTon(layer2)
      │     ├─ layer2Seigs = bridgedTONRewardPerUint * effectiveBridgedTON / WEI_UNIT - initialDebt
      │     ├─ valReward = validatorRewardPerUint * effectiveBridgedTON / WEI_UNIT - validatorInitialDebt
      │     │
      │     ├─ TRANSFER: layer2Manager → layer2 (layer2Seigs)
      │     ├─ DISTRIBUTE: validatorReward.distributeL2Rewards (valReward)
      │     │
      │     └─ UPDATE: initialDebt, validatorInitialDebt (prevent next claim)
      │
      └─ _mintDaoReward (sDao + (L - y))

On eligibility change
│
└─ _updateEligibilityInternal(layer2)
   │
   ├─ currentBridgedTON = bridgedTon * GWEI_UNIT (query from L1 bridge)
   ├─ newEligible = checkCurrentEligibility(layer2)
   │
   ├─ IF oldEligible == newEligible → RETURN (do nothing)
   │
   └─ ELSE (eligibility change)
      │
      ├─ _triggerSeigniorageDistribution() (distribute first)
      │  │
      │  └─ Update rewardPerUnit + WTON mint (no claim)
      │
      ├─ IF oldEligible && !newEligible (eligibility loss)
      │  │
      │  └─ _handleEligibilityLoss(layer2)
      │     │
      │     ├─ Auto claim unclaimed rewards
      │     ├─ effectiveBridgedTON = 0
      │     └─ totalEffectiveBridgedTON -= old
      │
      └─ ELSE (eligibility gain)
         │
         ├─ effectiveBridgedTON = currentBridgedTON
         ├─ totalEffectiveBridgedTON += new
         ├─ initialDebt = bridgedTONRewardPerUint * effectiveBridgedTON / WEI_UNIT
         └─ validatorInitialDebt = validatorRewardPerUint * effectiveBridgedTON / WEI_UNIT
```

---

## 12. Key Formulas

### 12.1 Seigniorage Distribution (V3)

```
A₂ = span × seigPerBlock                    // Period seigniorage

S_DAO = d × A₂                              // DAO fixed portion
L = (1 - d) × A₂                            // L2 distributable amount

y(x) = L × x / (k + x)                      // Hyperbolic saturation (x = totalEffectiveBridgedTON)

Seig_i = y(x) × (B̃_i / x)                  // Individual L2 seigniorage

o_i = (1 - α) × Seig_i                      // Sequencer reward
v_i = α × Seig_i                            // Validator reward
```

### 12.2 Eligibility Conditions (V3)

```
currentStake = coinage.balanceOf(operator)  // Sequencer collateral

minForSeigniorage = bridgedTON × GWEI_UNIT × θ / RAY_UNIT
minForFraudProof = hMax × cMax + Δ_sequencer

requiredStake = max(minForSeigniorage, minForFraudProof)

eligible = (rollupType == TYPE_3) && (bridgedTON > 0) && (currentStake ≥ requiredStake)
```

### 12.3 Claim Calculation (Debt Formula)

```
accSeq = bridgedTONRewardPerUint × B̃_i / WEI_UNIT - initialDebt
accVal = validatorRewardPerUint × B̃_i / WEI_UNIT - validatorInitialDebt
```

---

## 13. Related Tests

### EligibilityTransition.t.sol

| Test ID | Test Name | Verification Content |
|---------|-----------|---------------------|
| INT-040 | `test_INT040_autoClaimBeforeEligibilityLoss` | Auto claim unclaimed rewards on eligibility loss |
| INT-041 | `test_INT041_separatedRewardPerUnitTracking` | Separate tracking of sequencer/validator rewardPerUnit |
| INT-042 | `test_INT042_initialDebtResetOnReeligibility` | Reset initialDebt on re-eligibility |
| INT-043 | `test_INT043_fullEligibilityTransitionFlow` | Full flow: eligibility gain→reward→loss→re-gain |
| INT-044 | `test_INT044_autoClaimEventEmitted` | AutoClaimBeforeEligibilityLoss event emission |
| INT-045 | `test_INT045_pausedState_eligibilityLoss_claimUnclaimedRewards` | Claim unclaimed rewards on eligibility loss in paused state |
| INT-046 | `test_INT046_pausedState_eligibilityGain_setsEffectiveBridgedTON` | Set effectiveBridgedTON on eligibility gain in paused state |
| INT-047 | `test_INT047_eligibilityLoss_triggersSeigDistribution` | Auto seigniorage settlement on eligibility loss (without updateSeigniorage) |
| INT-048 | `test_INT048_eligibilityGain_triggersSeigDistribution` | Settle seigniorage to existing L2s first on eligibility gain |

---

## 14. Related Code Locations

| Function | File | Line |
|----------|------|------|
| `pause()` | SeigManagerV3_1.sol | 212 |
| `unpause()` | SeigManagerV3_1.sol | 229 |
| `excludeFromL2Seigniorage()` | SeigManagerV3_1.sol | 239 |
| `includeFromL2Seigniorage()` | SeigManagerV3_1.sol | 246 |
| `claimL2Seigniorage()` | SeigManagerV3_1.sol | 259 |
| `onBridgedTonChange()` | SeigManagerV3_1.sol | 306 |
| `onStakingChange()` | SeigManagerV3_1.sol | 320 |
| `_updateEligibilityInternal()` | SeigManagerV3_1.sol | 325 |
| `checkCurrentEligibility()` | SeigManagerV3_1.sol | 385 |
| `updateSeigniorage()` | SeigManagerV3_1.sol | 591 |
| `_updateSeigniorageV3()` | SeigManagerV3_1.sol | 644 |
| `_claimL2RewardsOnly()` | SeigManagerV3_1.sol | 665 |
| `_increaseTotV3()` | SeigManagerV3_1.sol | 671 |
| `_distributeV3Seigniorage()` | SeigManagerV3_1.sol | 698 |
| `_claimL2Rewards()` | SeigManagerV3_1.sol | 740 |
| `_handleEligibilityLoss()` | SeigManagerV3_1.sol | 782 |
| `_triggerSeigniorageDistribution()` | SeigManagerV3_1.sol | 827 |
| `_mintDaoReward()` | SeigManagerV3_1.sol | 880 |
| `_syncEffectiveBridgedTon()` | SeigManagerV3_1.sol | 887 |
| `updateSeigniorageV2()` (V2) | SeigManagerV3_2.sol | 85 |
| `_increaseTot()` (V2) | SeigManagerV3_2.sol | 153 |

---

## 15. V2 vs V3 Comparison

| Item | V2 | V3 |
|------|----|----|
| Distribution basis | `layer2Tvl` (L1BridgeRegistry) | `effectiveBridgedTON` (eligibility-based) |
| Reward separation | None (single `l2RewardPerUint`) | Sequencer/Validator separated |
| Eligibility conditions | None | `currentStake >= requiredStake` && `bridgedTON > 0` |
| Staker seigniorage | Yes (coinage factor increase) | No |
| DAO distribution | `daoSeigRate` (based on unstakedSeig) | `daoDistributionRatio` (based on total A₂) |
| Hyperbolic saturation | None | `y(x) = L × x / (k + x)` |
