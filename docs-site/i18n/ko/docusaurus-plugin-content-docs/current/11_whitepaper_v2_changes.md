---
id: 11_whitepaper_v2_changes
slug: /11_whitepaper_v2_changes
---
# 백서 V2 업데이트에 따른 수정 필요 사항

> **문서 작성일**: 2025-12-10
> **참고 백서**: Tokamak Economics Whitepaper V2 (December 9, 2025)
> **미팅 회의록**: ECO Whitepaper writing (Suhyeon, Bernard) - 2025_12_08 22:30 KST

---

## 1. 개요

기존 for-llm-kr 문서들은 2025년 12월 3일자 백서를 기반으로 작성되었습니다. 2025년 12월 9일자 백서 V2로 업데이트되면서 일부 변경 사항이 발생했습니다. 이 문서는 백서 V2와 기존 구현 명세서를 비교하여 **수정이 필요한 사항**을 정리합니다.

### 1.1 회의록 핵심 요약 (2025-12-08)

| 항목 | 결정 사항 |
|------|----------|
| **"Time Weighted" 표현** | 삭제 - 구현 자율성 확보를 위해 |
| **V2→V3 점진적 전환** | 백서에 "점진적 전환" 문구 추가 |
| **C_max 정의** | "maximum cost" → "estimated" 또는 "sufficient cost"로 완화 |
| **멀티시퀀서 환경** | 슬래싱된 시퀀서가 복구 실패해도 롤업 기능 지속 가능 언급 추가 |
| **미분배분 처리** | "goes to DAO Treasury" 표현 명시 |
| **gamma squared 공식** | 제거 권고 |
| **Verifier's Dilemma 인용** | 섹션 1.3에서 유기적으로 연결되도록 수정 |

---

## 2. 백서 V2의 주요 변경/명확화 사항

### 2.1 검증자 보상 공식 명확화 (공식 13)

**백서 V2 원문 (Page 16):**
```
v_i = (α/n) · y(x),    o_i = (1 − α) · S_i
```

**해석:**
- `v_i`: 각 검증자가 받는 보상
- `α`: 검증자 분배 비율 (validatorDistributionRatio)
- `n`: 총 검증자 수
- `y(x)`: 전체 L2 시뇨리지 (쌍곡선 함수 결과)
- `o_i`: 시퀀서가 받는 보상 = `(1-α) · S_i`
- `S_i`: 해당 L2의 시뇨리지

**핵심 변경:**
- 기존 문서에서 `v_i = (α_v/n) · Seig_i`로 해석했으나
- 백서 V2에서는 `v_i = (α/n) · y(x)`로 명확화
- **검증자 보상은 전체 y(x)에서 균등 분배** (개별 L2의 Seig_i가 아님)

### 2.2 검증자 담보금 공식 명확화 (공식 4, 5)

**백서 V2 원문 (Page 11):**
```
(3) c_m ≤ (π_a/N) · C_off

(4) C_off ≥ (c_m · N) / π_a

(5) D_validator = C_off + Δ_validator
```

**변수 명칭 변경:**
- 기존 문서: `D_validator ≥ (c_m · N) / π_a`
- 백서 V2: `C_off` (슬래싱 페널티)와 `D_validator` (실제 담보금) 구분
- `D_validator = C_off + Δ_validator` (담보금 = 최소 페널티 + 추가 버퍼)

### 2.3 시퀀서 담보금 공식 일관성

**기존 문서 (03_sequencer_slashing.md):**
- `D_sequencer = H_max · C_max + Δ_sequencer` (공식 1)
- `R_challenger = C_max + (Δ_sequencer / n)` (공식 2)

**백서 V2 확인:**
- 동일한 공식 유지 (변경 없음)

### 2.4 RAT 게임이론 조건 신규 추가

**백서 V2 (Page 11)에서 명시된 게임이론 조건:**
```
(3) c_m ≤ (π_a/N) · C_off

조건 설명:
- c_m: 에폭당 attentiveness 유지 비용
- π_a: RAT 트리거 확률
- N: 검증자 수
- C_off: 오프라인 시 슬래싱 페널티
```

**핵심 의미:**
- 오프라인 상태의 예상 페널티 `(π_a/N) · C_off`가 유지 비용 `c_m`보다 커야 함
- 이 조건이 충족되면 attentive 상태 유지가 dominant strategy

### 2.5 검증자 슬래싱 조건 명확화

**백서 V2 (Page 11):**
> "Slashing for validators is applied solely in the context of RAT. When an attention test is triggered with probability π_a, the selected validator must respond within the required time window. Failure to do so triggers a slashing event in which a penalty C_off is deducted from the validator's deposit."

**명확화된 사항:**
- 슬래싱 금액은 `C_off` (전체 담보금이 아닌 최소 페널티)
- 슬래싱 후 잔액이 최소 임계값(`D_min`) 미만이면 보충 필요
- 보충 실패 시 활성 검증자 세트에서 제거

---

## 3. 기존 문서 수정 필요 사항

### 3.1 04_validator.md 수정

#### 3.1.1 검증자 보상 공식 수정

**기존 (Line 354-369):**
```
v_i = (α_v / n) · y(x)    ... (13) 검증자 보상

- α_v: 검증자 분배 비율 (예: 20%)
- n: 활성 검증자 수 (해당 SystemConfig 내)
- y(x): 쌍곡선 포화 함수 결과
```

**수정 필요:**
- 백서 V2와 일치 ✅ (수정 불필요)
- 단, 명확화 필요: 검증자 보상은 **전체 y(x)**에서 분배되며, 개별 L2의 Seig_i가 아님

#### 3.1.2 검증자 담보금 공식 수정

**기존 (Line 127-142):**
```
π_a · D_validator > c_m · N             ... (4) 게임 이론적 균형 조건
D_validator ≥ (c_m · N) / π_a           ... (5) 최소 조건
D_validator = (c_m · N) / π_a + Δ_validator  ... (6) 실제 담보금
```

**수정 필요:**
백서 V2 공식으로 갱신:
```
c_m ≤ (π_a/N) · C_off                  ... (3) RAT 균형 조건
C_off ≥ (c_m · N) / π_a                ... (4) 최소 슬래싱 페널티
D_validator = C_off + Δ_validator       ... (5) 실제 담보금
```

### 3.2 05_validator_slashing.md 수정

#### 3.2.1 슬래싱 금액 수정

**기존 설계:**
- "full collateral slashing" (전체 담보금 슬래싱)

**백서 V2 명시:**
- 슬래싱 금액은 `C_off` (페널티 금액)
- 슬래싱 후 `D_min` 미만이면 보충 기간 제공
- 보충 실패 시 활성 세트에서 제거

**수정 필요:**
1. 슬래싱 금액을 `C_off`로 변경 (전체 담보금 → 페널티 금액)
2. 슬래싱 후 잔액 확인 및 보충 메커니즘 추가
3. `D_min` (최소 임계값) 파라미터 추가

#### 3.2.2 선차감-복구 메커니즘 재검토

**기존 설계:**
- RAT 트리거 시 전체 담보금 선차감
- 증거 제출 시 전체 금액 복구
- 미응답 시 전체 담보금 몰수

**백서 V2 기준 수정:**
- RAT 트리거 시 `C_off` 만큼 선차감
- 증거 제출 시 `C_off` 복구
- 미응답 시 `C_off` 몰수 + 잔액이 `D_min` 미만이면 보충 필요

### 3.3 03_sequencer_slashing.md 수정

#### 3.3.1 C_max 정의 완화 (회의록 결정)

**기존 표현:**
- `C_max`: "단일 fraud proof 최대 온체인 비용"

**수정 필요 (회의록 결정):**
- `C_max`: "단일 fraud proof 예상(estimated) 또는 충분한(sufficient) 비용"으로 완화
- "maximum cost"라는 표현이 너무 엄격하여 실제 구현에서 문제가 될 수 있음

#### 3.3.2 멀티시퀀서 환경 언급 추가 (회의록 결정)

**추가 필요:**
> "슬래싱된 시퀀서가 담보금 보충에 실패하더라도 멀티시퀀서 환경에서는 다른 시퀀서가 롤업 기능을 지속할 수 있습니다."

#### 3.3.3 γ(gamma) squared 공식 제거 (회의록 결정)

**기존 (반복 위반 페널티):**
```
D^(n) = γ^(n-1) · D^(1)
```

**수정 필요:**
- gamma squared 공식 제거 권고됨
- 반복 위반 페널티 메커니즘 단순화 또는 다른 방식 검토

### 3.4 07_rat_implementation.md 수정 ✅ 완료

#### 3.4.1 ValidatorRegistration 구조체 수정 ✅

**기존 (Line 146-167):**
```solidity
struct ValidatorRegistration {
    uint256 depositedAmount;        // 전체 금액
    uint256 slashingPenalties;      // 전체 금액 선차감
    ...
}
```

**수정 완료:**
```solidity
struct ValidatorRegistration {
    uint256 depositedAmount;        // 현재 유효 담보금 (선차감 후 금액)
    uint256 totalBondForRAT;        // 진행 중인 RAT 테스트들에 묶인 총 금액
    uint256 pendingRewards;         // 미청구 검증자 보상
    uint256 coinageFactorAtDeposit; // 예치 시점의 coinage factor
    uint32 validatorIndex;
    bool isActive;
}
```

#### 3.4.2 triggerAttentionTest 함수 수정 ✅

**기존 설계:**
```solidity
// 전체 담보금 선차감
uint256 slashAmount = reg.depositedAmount;
reg.slashingPenalties = slashAmount;
```

**수정 완료:**
```solidity
// C_off (slashingPenalty) 만큼만 선차감
uint256 slashAmount = slashingPenalty;
if (reg.depositedAmount < slashAmount) {
    slashAmount = reg.depositedAmount;
}
reg.depositedAmount -= slashAmount;
reg.totalBondForRAT += slashAmount;
```

#### 3.4.3 D_min 미만 시 처리 ✅

**결정사항:** 별도의 보충 기간을 두지 않고, D_min 미만 시 **즉시 활성 검증자 세트에서 제거**

```solidity
// finalizeSlash 함수 내
if (reg.depositedAmount < minimumThreshold) {
    _removeValidator(test.systemConfig, test.validatorAddress, regId, reg);
}

// 재등록 시: D_min 이상 되도록 추가 예치 후 registerValidator() 호출
```

#### 3.4.4 RATStorage 파라미터 수정 ✅

**백서 공식 (3), (4), (5) 기반 파라미터 구조로 변경:**
```solidity
/// @notice 백서 공식 (3), (4), (5) 파라미터
/// @dev (3) c_m ≤ (π_a / n) · C_off  - RAT 균형 조건
/// @dev (4) C_off ≥ (c_m · n) / π_a  - 슬래싱 페널티 최소 조건
/// @dev (5) D_validator = C_off + Δ_validator  - 검증자 담보금
uint256 public attentionCost;            // c_m: 에포크당 주의력 유지 비용
uint256 public slashingPenalty;          // C_off: 슬래싱 페널티
uint256 public validatorBuffer;          // Δ_validator: 추가 버퍼
uint256 public ratTriggerProbability;    // π_a: RAT 트리거 확률
uint256 public minimumThreshold;         // D_min: 최소 담보금 임계값
```

- 기존 `batchCount` 파라미터 제거 (N을 배치 수로 잘못 해석했던 오류 수정)
- `ratResponseCost` → `attentionCost` (c_m)로 변경
- `cOff` → `slashingPenalty` (C_off)로 변경

#### 3.4.5 IRAT 인터페이스 함수 수정 ✅

**변경된 파라미터 설정 함수:**
```solidity
function setAttentionCost(uint256 cost) external;
function setSlashingPenalty(uint256 penalty) external;
function setValidatorBuffer(uint256 buffer) external;
function getMinimumCollateral() external view returns (uint256);
function validateSlashingPenalty(uint256 n) external view returns (bool);
```

**보상 청구 함수 (가스비 예측 가능하도록 변경):**
```solidity
// 기존: claimAllRewards() - 가스비 예측 불가
// 변경: claimRewardsBatch(address[] calldata systemConfigs) - 가스비 예측 가능
function claimRewardsBatch(address[] calldata systemConfigs) external;
function getTotalPendingRewards(address validator) external view returns (uint256 total);
```

#### 3.4.6 getMinimumCollateral 함수 수정 ✅

**기존 (잘못된 공식):**
```solidity
function getMinimumCollateral() public view returns (uint256) {
    return (ratResponseCost * batchCount * MAX_PROBABILITY) / ratTriggerProbability;
}
```

**수정 완료 (백서 공식 5):**
```solidity
/// @notice 최소 담보금 계산 (백서 공식 5)
/// @dev D_validator = C_off + Δ_validator
function getMinimumCollateral() public view returns (uint256) {
    return slashingPenalty + validatorBuffer;
}
```

#### 3.4.7 validateSlashingPenalty 함수 추가 ✅

**백서 공식 (4) 검증 함수 신규 추가:**
```solidity
/// @notice C_off가 백서 공식 (4)를 만족하는지 검증
/// @dev C_off ≥ (c_m · n) / π_a
/// @param n 검증자 수
function validateSlashingPenalty(uint256 n) public view returns (bool) {
    // C_off ≥ (c_m · n) / π_a
    // → C_off · π_a ≥ c_m · n
    return slashingPenalty * ratTriggerProbability >= attentionCost * n * RAY;
}
```

#### 3.4.8 α_v → α 표기 통일 ✅

백서 V2에서 검증자 분배 비율을 `α`로 표기하므로 문서 전체에서 `α_v` → `α`로 변경 완료

### 3.5 08_implementation.md 수정

#### 3.5.1 ValidatorPoolV1 수정

**기존 RAT 슬래싱:**
```solidity
function slashUnresponsiveValidator(...) {
    uint256 slashedAmount = info.depositAmount;  // 전체 담보금
    info.depositAmount = 0;
    info.isActive = false;
    ...
}
```

**수정 필요:**
```solidity
function slashUnresponsiveValidator(...) {
    uint256 slashedAmount = cOff;  // C_off만 슬래싱
    info.depositAmount -= slashedAmount;

    // D_min 미만이면 보충 기간 시작
    if (info.depositAmount < minimumThreshold) {
        info.replenishDeadline = block.timestamp + replenishPeriod;
    }
    ...
}
```

### 3.6 10_governance_parameters.md 수정

#### 3.6.1 신규 파라미터 추가

**추가 필요:**
| 파라미터 | 기호 | 설명 | 권장값 |
|---------|------|------|--------|
| **cOff** | C_off | 검증자 슬래싱 페널티 | TBD |
| **minimumThreshold** | D_min | 검증자 최소 담보금 임계값 | TBD |
| **replenishPeriod** | - | 담보금 보충 기간 | TBD |

#### 3.6.2 γ(gamma) 관련 파라미터 재검토 (회의록 결정)

**기존:**
- `penaltyFactor (γ)`: 반복 위반 페널티 팩터
- 공식: `D^(n) = γ^(n-1) · D^(1)`

**수정 필요:**
- gamma squared 공식 제거 권고에 따라 해당 파라미터 역할 재정의 또는 제거

### 3.7 전체 문서 공통 수정 (회의록 결정)

#### 3.7.1 "Time Weighted" 표현 삭제

**영향 범위 확인 필요:**
- 구현 자율성 확보를 위해 "Time Weighted" 표현 삭제
- Bridged TON 가중치 계산 방식은 구현 단계에서 자율적으로 결정

#### 3.7.2 "미분배분은 DAO Treasury로" 명시

**영향 범위:**
- 02_v3_distribution.md
- 08_implementation.md

**추가 필요:**
> "분배되지 않은 시뇨리지는 DAO Treasury로 귀속됩니다."

---

## 4. 수정 우선순위

### 4.1 높은 우선순위 (핵심 로직 변경)

| 문서 | 수정 내용 | 영향도 | 상태 |
|------|----------|--------|------|
| **05_validator_slashing.md** | 슬래싱 금액 C_off로 변경, 보충 메커니즘 추가 | 높음 | ✅ 완료 |
| **07_rat_implementation.md** | triggerAttentionTest, 슬래싱 로직 변경 | 높음 | ✅ 완료 |
| **08_implementation.md** | ValidatorPoolV1 슬래싱 로직 변경 | 높음 | ✅ 완료 |
| **03_sequencer_slashing.md** | γ squared 공식 제거, C_max 정의 완화 (회의록) | 높음 | ✅ 완료 |

### 4.2 중간 우선순위 (공식/파라미터 업데이트)

| 문서 | 수정 내용 | 영향도 | 상태 |
|------|----------|--------|------|
| **04_validator.md** | α_v → α 표기 통일, 파라미터명 변경 | 중간 | ✅ 완료 |
| **10_governance_parameters.md** | 백서 V2 파라미터 반영, γ 제거 | 중간 | ✅ 완료 |
| **02_v3_distribution.md** | DAO 귀속 명시 (백서 V2 Page 15 인용) | 중간 | ✅ 완료 |

### 4.3 낮은 우선순위 (문서 정합성)

| 문서 | 수정 내용 | 영향도 | 상태 |
|------|----------|--------|------|
| **README.md** | 백서 버전 업데이트, α_v → α 수정 | 낮음 | ✅ 완료 |
| **전체 문서** | "Time Weighted" 표현 삭제 여부 확인 | 낮음 | ✅ 완료 (없음 확인) |
| **06_bridged_ton_tracking.md** | 가중치 계산 방식 구현 자율성 명시 | 낮음 | ✅ 완료 |

---

## 5. 변경 없음 확인된 사항

다음 항목들은 백서 V2에서도 동일하게 유지됨:

### 5.1 V3 시뇨리지 분배 공식 (변경 없음)
- 공식 (7): `S_DAO = d · A` → DAO 고정 분배
- 공식 (8): `T_i ≥ θ · B_i` → 최소 스테이킹 조건
- 공식 (9): `1_i` 지시 함수
- 공식 (10): `x = Σ B̃_i` → 전체 유효 Bridged TON
- 공식 (11): `y(x) = L · (x/(k+x))` → 쌍곡선 포화 함수
- 공식 (12): `S_i = y(x) · (B̃_i/x)` → L2별 시뇨리지

### 5.2 시퀀서 슬래싱 공식 (변경 없음)
- 공식 (1): `D_sequencer = H_max · C_max + Δ_sequencer`
- 공식 (2): `R_challenger = C_max + (Δ_sequencer/n)`

### 5.3 RAT 기본 개념 (변경 없음)
- 무작위 검증자 선택
- 증거 제출 기간
- 슬래싱 트리거 조건

---

## 6. 백서 V2 인용 (주요 변경 부분)

### 6.1 검증자 담보금 (Page 11)

> "Let cm denote the per-epoch cost of maintaining attentiveness. Staying attentive incurs cm but avoids penalties. Going offline saves this cost but risks being selected by RAT and penalized. Let πa denote the system-wide probability that RAT triggers an attention test in a given epoch, and let N be the number of validators."

> "For attentiveness to be the dominant strategy, the expected penalty from being offline must exceed the cost savings. Let Coff denote the slashing penalty for failing an attention test. The RAT equilibrium condition ensuring that online behavior strictly dominates offline behavior is given by:
> (3) cm ≤ (πa/N) · Coff"

### 6.2 검증자 슬래싱 (Page 11)

> "Slashing for validators is applied solely in the context of RAT. When an attention test is triggered with probability πa, the selected validator must respond within the required time window. Failure to do so triggers a slashing event in which a penalty Coff is deducted from the validator's deposit. If the remaining deposit falls below the minimum threshold Dmin, the validator must replenish it within a specified period; otherwise, the validator is removed from the active validator set."

### 6.3 검증자/시퀀서 보상 분배 (Page 16-17)

> "Rewards are divided between sequencers and validators according to a predefined ratio. Let α denote the validator distribution ratio and n denote the total number of validators:
> (13) vi = (α/n) · y(x),    oi = (1 − α) · Si"

---

## 7. 다음 단계

### 7.1 문서 수정 작업

1. **높은 우선순위 문서 수정**
   - 05_validator_slashing.md: C_off 기반 슬래싱, 보충 메커니즘 추가
   - 07_rat_implementation.md: 슬래싱 로직 변경
   - 08_implementation.md: ValidatorPoolV1 코드 수정
   - 03_sequencer_slashing.md: γ squared 공식 제거, C_max 정의 완화

2. **중간 우선순위 문서 수정**
   - 04_validator.md: 공식 번호 재정렬
   - 10_governance_parameters.md: 신규 파라미터 추가
   - 02_v3_distribution.md: DAO Treasury 표현 명시

### 7.2 구현 작업

1. **코드 리뷰**: 기존 구현 코드가 있다면 백서 V2 기준으로 검토
2. **테스트 케이스 업데이트**: 슬래싱 금액 C_off 기준 테스트 추가
3. **거버넌스 제안**: C_off, D_min, replenishPeriod 파라미터 결정

### 7.3 회의록 결정 사항 반영 확인

| 결정 사항 | 반영 대상 | 상태 |
|----------|----------|------|
| "Time Weighted" 표현 삭제 | 전체 문서 검토 | ✅ 완료 (없음 확인) |
| V2→V3 점진적 전환 문구 | 02_v3_distribution.md | ✅ 기존 반영됨 |
| C_max 정의 완화 | 03_sequencer_slashing.md | ✅ 완료 |
| 멀티시퀀서 환경 언급 | 03_sequencer_slashing.md | ⏸️ 보류 (검토 필요) |
| DAO 귀속 명시 | 02_v3_distribution.md | ✅ 완료 (백서 V2 Page 15 인용) |
| γ squared 공식 제거 | 03_sequencer_slashing.md | ✅ 완료 |

---

## 8. 수정 진행 상황 요약 (2025-12-10 업데이트)

### 8.1 완료된 수정 사항

| 문서 | 수정 내용 | 완료일 |
|------|----------|--------|
| **07_rat_implementation.md** | 백서 V2 공식 (3), (4), (5) 반영, 파라미터 구조 변경, claimRewardsBatch 도입 | 2025-12-10 |

**07_rat_implementation.md 상세 수정 내용:**
1. `batchCount` 파라미터 제거 (N을 배치 수로 오해한 오류 수정)
2. `ratResponseCost` → `attentionCost` (c_m)로 변경
3. `cOff` → `slashingPenalty` (C_off)로 변경
4. `validatorBuffer` (Δ_validator) 파라미터 추가
5. `minimumThreshold` (D_min) 파라미터 추가
6. `getMinimumCollateral()` 함수 수정: `C_off + Δ_validator`
7. `validateSlashingPenalty(n)` 함수 추가 (공식 4 검증)
8. `claimAllRewards()` → `claimRewardsBatch(address[] calldata)` 변경 (가스비 예측 가능)
9. `getTotalPendingRewards(address)` 함수 추가
10. `α_v` → `α` 표기 통일
11. `distributeReward` → `distributeValidatorReward` 함수명 통일

### 8.2 문서별 수정 완료 현황

**높은 우선순위:**
- [x] 05_validator_slashing.md: C_off 기반 슬래싱, 선차감-복구 메커니즘 ✅
- [x] 08_implementation.md: ValidatorPoolV1 코드, α_v → α 수정 ✅
- [x] 03_sequencer_slashing.md: γ squared 공식 제거, C_max 정의 완화 ✅

**중간 우선순위:**
- [x] 04_validator.md: α_v → α 표기 통일, 파라미터명 변경 ✅
- [x] 10_governance_parameters.md: 백서 V2 파라미터 반영, γ 제거 ✅
- [x] 02_v3_distribution.md: DAO 귀속 명시 (백서 V2 Page 15 인용) ✅

**낮은 우선순위:**
- [x] README.md: 백서 버전 업데이트, α_v → α 수정 ✅
- [x] 전체 문서: "Time Weighted" 표현 삭제 확인 ✅
- [x] 06_bridged_ton_tracking.md: 구현 자율성 노트 삭제 ✅
