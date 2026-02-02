---
id: functions-governance-parameters
sidebar_position: 10
---

# 거버넌스 파라미터

모든 컨트랙트의 거버넌스 파라미터 전체 목록입니다.

## SeigManager 파라미터

| 파라미터 | 함수 | 범위 | 단위 |
|---------|------|------|------|
| `daoDistributionRatio` | `setDaoDistributionRatio(d)` | 0 < d < 1 | RAY |
| `minStakingRatio` | `setMinStakingRatio(θ)` | 0 < θ ≤ 1 | RAY |
| `validatorDistributionRatio` | `setValidatorDistributionRatio(α)` | 0 < α < 1 | RAY |
| `halfSaturationPoint` | `setHalfSaturationPoint(k)` | k > 0 | RAY (TON) |

### 슬래싱 파라미터

| 파라미터 | 함수 | 범위 | 단위 |
|---------|------|------|------|
| `maxFraudProofCost` | `setMaxFraudProofCost(C_max)` | C_max > 0 | WTON |
| `sequencerAdditionalReward` | `setSequencerAdditionalReward(Δ)` | Δ ≥ 0 | WTON |
| `maxChallengers` | `setMaxChallengers(H_max)` | H_max > 0 | count |

---

## RAT 파라미터

| 파라미터 | 함수 | 범위 | 단위 |
|---------|------|------|------|
| `slashingPenalty` | `setSlashingPenalty(C_off)` | C_off > 0 | TON |
| `validatorBuffer` | `setValidatorBuffer(Δ)` | Δ ≥ 0 | TON |
| `ratTriggerProbability` | `setRatTriggerProbability(π_a)` | 0 < π_a ≤ 1 | RAY |
| `minimumThreshold` | `setMinimumThreshold(D_min)` | D_min > 0 | TON |
| `evidenceSubmissionPeriod` | `setEvidenceSubmissionPeriod(t)` | t > 0 | 초 |
| `validatorReward` | `setValidatorReward(addr)` | addr != 0 | 주소 |

---

## ValidatorReward 파라미터

| 파라미터 | 함수 | 범위 | 단위 |
|---------|------|------|------|
| `seigManager` | `setSeigManager(addr)` | addr != 0 | 주소 |
| `ratContract` | `setRatContract(addr)` | addr != 0 | 주소 |

---

## 파라미터 관계

### D_sequencer 계산

```
D_sequencer = maxChallengers × maxFraudProofCost + sequencerAdditionalReward

예시:
maxChallengers = 3
maxFraudProofCost = 50e27 WTON
sequencerAdditionalReward = 100e27 WTON
→ D_sequencer = 3 × 50e27 + 100e27 = 250e27 WTON
```

### D_min (검증자) 계산

```
C_off = max(slashingPenalty, (c_m × N × RAY) / π_a)
D_min = C_off + validatorBuffer

예시:
slashingPenalty = 100e27 WTON
attentionCost = 150e27 WTON
N = 3 (검증자 3명)
π_a = 1e27 (100%)
validatorBuffer = 100e27 WTON

→ C_off = max(100e27, (150e27 × 3 × 1e27) / 1e27)
        = max(100e27, 450e27)
        = 450e27 WTON

→ D_min = 450e27 + 100e27 = 550e27 WTON
```

---

## 거버넌스 모드 설정

### 완화 모드 (초기 네트워크)

초기 네트워크 단계에서 검증자 유치를 위해:

```solidity
// 완화 모드
rat.setRelaxedValidatorCheck(true);
rat.setSlashingPenalty(100e27);  // 고정값만 사용
```

### 엄격 모드 (안정적 네트워크)

안정적 네트워크에서 보안 우선:

```solidity
// 엄격 모드
rat.setRelaxedValidatorCheck(false);
rat.setAttentionCost(150e27);     // 동적 공식 활성화
rat.setRatTriggerProbability(1e27);
```
