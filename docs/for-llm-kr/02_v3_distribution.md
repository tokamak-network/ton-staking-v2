# V3 시뇨리지 분배 공식

## 1. V3 시뇨리지 분배 흐름 (전환 메커니즘 포함)

```
updateSeigniorage() 호출 시 - 통합 분배 공식:

═══════════════════════════════════════════════════════════════
전체 시뇨리지 A에서 순차적 분배
═══════════════════════════════════════════════════════════════

A (전체 시뇨리지)
│
├─► Step 1: 스테이커 지분 시뇨리지 (λ 적용)
│   S_staked = λ · A · (S / T)
│   - S: 총 스테이킹 금액
│   - T: TON 총 발행량
│   - S/T: 스테이킹 비율
│   - λ: 지분 시뇨리지 비율 (1→0으로 나중에 감소)
│
│   A₁ = A - S_staked (1차 잔여)
│
├─► Step 2: 스테이커 추가 시뇨리지 (r 적용)
│   S_relative = A₁ · r
│   - r: relativeSeigRate (기존 V2 파라미터, 1→0으로 먼저 감소)
│
│   A₂ = A₁ - S_relative (2차 잔여 = V3 분배 재원)
│
└─► Step 3: V3 분배 (백서 공식 적용)
    │
    ├─► DAO 고정 분배 (백서 공식 7):
    │   S_DAO = d · A₂
    │
    ├─► L2 분배 가능량:
    │   L = (1 - d) · A₂
    │
    ├─► 자격 조건 확인 (백서 공식 8):
    │   각 L2_i: S_i ≥ θ · B_i ?
    │
    ├─► 유효 Bridged TON (백서 공식 9, 10):
    │   B̃_i = 1_i · B_i
    │   x = Σ B̃_i
    │
    ├─► 쌍곡선 포화 함수 (백서 공식 11):
    │   y(x) = L · (x / (k + x))
    │
    ├─► L2별 시뇨리지 (백서 공식 12):
    │   Seig_i = y(x) · (B̃_i / x)
    │
    ├─► 시퀀서/검증자 분배 (백서 V3 공식 13, 14):
    │   o_i = (1 - α) · S_i                    // (14) 시퀀서 보상
    │   v_j = Σ_{i: j∈V_i} (α · S_i) / |V_i|  // (13) 검증자 보상
    │
    │   V_i = L2 i에 할당된 검증자 집합
    │   |V_i| = 0 이면 α · S_i → DAO Treasury
    │
    └─► 미분배분 DAO Treasury 귀속:
        미분배 = L - y(x)
        totalDAO = S_DAO + 미분배 + Σ(검증자 없는 L2의 α·S_i)
        → DAO Treasury로 전송
```

---

## 2. 변수 설명

| 변수 | 설명 |
|------|------|
| **A** | 전체 기간 시뇨리지 (발행될 총량) |
| **A₁** | 스테이커 지분 시뇨리지(S_staked)를 분배한 후 남은 양 |
| **A₂** | 스테이커 추가 시뇨리지(S_relative)까지 분배한 후 남은 양 → V3 분배 재원 (DAO + L2 시퀀서 + 검증자) |
| **S** | 총 스테이킹 금액 (WTON 총 공급량) |
| **T** | TON 총 발행량 |
| **λ** | 지분 시뇨리지 비율 (stakedSeigFactor, 1→0으로 감소) |
| **r** | 추가 시뇨리지 비율 (relativeSeigRate, 1→0으로 먼저 감소) |
| **d** | DAO 분배 비율 (daoDistributionRatio) |
| **θ** | 최소 스테이킹 비율 (minStakingRatio) |
| **α** | 검증자 분배 비율 (validatorDistributionRatio) |
| **k** | 반포화점 (halfSaturationPoint) |
| **L** | L2 분배 가능량 = (1-d)·A₂ |
| **x** | 전체 유효 Bridged TON = Σ B̃_i |
| **y(x)** | 쌍곡선 포화 함수 결과 |

---

## 3. 수학적 표현

```
S_staked   = λ · A · (S / T)
A₁         = A - S_staked
           = A · (1 - λ · S/T)

S_relative = A₁ · r
A₂         = A₁ - S_relative
           = A₁ · (1 - r)
           = A · (1 - λ · S/T) · (1 - r)
```

---

## 4. V3 완전 전환 시 (λ = 0, r = 0)

```
λ = 0 → S_staked = 0 (지분 시뇨리지 없음)
r = 0 → S_relative = 0 (추가 시뇨리지 없음)

∴ 스테이커에게 아무것도 분배하지 않음

A₂ = A · (1 - 0) · (1 - 0) = A
→ 전체 시뇨리지가 백서 V3 공식대로 분배됨
```

---

## 5. 전환 단계별 분배 예시

**전환 원칙**: r(추가 시뇨리지) 먼저 감소 → λ(지분 시뇨리지) 나중에 감소

**가정**: S/T = 0.5

| 단계 | λ | r | S_staked | S_relative | A₂ (V3) |
|------|---|---|----------|------------|---------|
| V2   | 1.0 | 0.4 | 0.5A   | 0.2A       | 0.3A    |
| 전환1 | 1.0 | 0.2 | 0.5A   | 0.1A       | 0.4A    |
| 전환2 | 1.0 | 0.0 | 0.5A   | 0          | 0.5A    |
| 전환3 | 0.5 | 0.0 | 0.25A  | 0          | 0.75A   |
| V3   | 0.0 | 0.0 | 0      | 0          | A (100%)|

---

## 6. 핵심 변경점

- ❌ V2: 스테이킹 지분 비례 분배 → ✅ V3: Bridged TON 비례 분배
- ✅ **점진적 전환**: λ, r 파라미터로 스테이커 시뇨리지를 서서히 V3 분배로 이동
- ❌ V2: TVL 기반 L2 보상 → ✅ V3: 성과(Bridged TON) 기반 + 자격 조건
- ❌ V2: 검증자 보상 없음 → ✅ V3: 검증자에게 α 비율 분배
- ❌ V2: 선형 분배 → ✅ V3: 쌍곡선 포화 함수 (수확체감)
- ❌ V2: 기간 평균값 측정 → ✅ V3: 온체인 호출 시점 최신값 측정

### 6.1 측정 방식 변경 (V3 백서)

V3 백서에서 Bridged TON, Staked TON 측정 방식이 변경되었습니다.

| 구분 | V2 | V3 |
|------|-----|-----|
| **측정 방식** | 기간 평균값 (averaged values over the period) | 온체인 호출 시점 최신값 (latest observed values) |
| **샘플링** | 주기적 스냅샷 기반 | 고정 간격 아님, 온체인 호출 기반 |
| **데이터 소스** | 과거 블록 범위의 평균 | 호출 시점의 현재 상태 |

**V3 측정 방식 장점:**
- **단순성**: 별도의 스냅샷/평균 계산 불필요
- **실시간성**: 현재 상태를 즉시 반영
- **가스 효율성**: 추가적인 스토리지/계산 불필요

**구현 차이:**
```solidity
// V2 (기간 평균) - 복잡한 스냅샷 로직
uint256 averageBridgedTON = calculatePeriodAverage(l2, startBlock, endBlock);
uint256 averageStakedTON = getAverageStaked(l2, startBlock, endBlock);

// V3 (최신값) - 단순한 현재값 조회
uint256 currentBridgedTON = getBridgedTON(l2);  // L1BridgeRegistry.layer2TVL()
uint256 currentStakedTON = getStakedAmount(l2);  // Layer2Manager.stakedAmount()
```

**관련 코드:**
- `src/layer2/Layer2ManagerV1_2.sol`: `getBridgedTON()`, `getBridgedTONByLayer()`
- `src/stake/managers/SeigManagerV1_4.sol`: `updateBridgedTON()`, `checkCurrentEligibility()`

---

## 7. V2 → V3 점진적 전환 메커니즘

### 7.1 전환 필요성

V2에서 V3로의 급격한 전환은 시장에 가격 충격을 줄 수 있습니다. 이를 방지하기 위해 **스테이커 시뇨리지를 점진적으로 감소**시키는 전환 메커니즘을 도입합니다.

### 7.2 전환 파라미터

V2의 스테이커 시뇨리지는 두 가지 요소로 구성됩니다:

| 구분 | V2 공식 | 설명 |
|------|---------|------|
| **지분 시뇨리지** | `stakedSeig` | 스테이킹 지분 비율에 따른 시뇨리지 |
| **추가 시뇨리지** | `relativeSeig` | `unstakedSeig × relativeSeigRate`로 계산되는 추가 보상 |

**전환 파라미터:**

```solidity
/// @notice 지분 시뇨리지 비율 (0 ~ RAY)
/// @dev λ = 1.0: V2와 동일, λ = 0: 지분 시뇨리지 없음
uint256 public stakedSeigFactor;  // λ (신규 파라미터)

/// @notice 추가 시뇨리지 비율 - 기존 V2 파라미터 재사용
/// @dev r = 기존값: V2와 동일, r = 0: 추가 시뇨리지 없음
uint256 public relativeSeigRate;  // r (기존 파라미터, 1→0으로 조정)
```

### 7.3 전환 시나리오

**전환 원칙**: r(추가 시뇨리지)를 먼저 줄이고, λ(지분 시뇨리지)는 나중에 감소

- **추가 시뇨리지 (S_relative)**: "보너스" 성격 → r을 먼저 감소
- **지분 시뇨리지 (S_staked)**: "원금 대비 보상" 성격 → λ를 나중에 감소

```
Phase 0: V2 상태 (전환 전)
─────────────────────────────────────
λ = 1.0 (100%), r = 0.4 (기존값)
→ 스테이커: 기존 V2와 동일한 시뇨리지 수령
→ V3 분배: 일부 (A₂ = 0.3A)

Phase 1: 추가 시뇨리지 감소 시작
─────────────────────────────────────
λ = 1.0 (100%), r = 0.2
→ 스테이커: 지분 시뇨리지 유지, 추가 시뇨리지 50% 감소
→ V3 분배 증가 (A₂ = 0.4A)

Phase 2: 추가 시뇨리지 완전 제거
─────────────────────────────────────
λ = 1.0 (100%), r = 0.0
→ 스테이커: 지분 시뇨리지만 유지, 추가 시뇨리지 없음
→ V3 분배 증가 (A₂ = 0.5A)

Phase 3: 지분 시뇨리지 감소 시작
─────────────────────────────────────
λ = 0.5 (50%), r = 0.0
→ 스테이커: 지분 시뇨리지 50% 감소
→ V3 분배 증가 (A₂ = 0.75A)

Phase 4: V3 완전 전환
─────────────────────────────────────
λ = 0.0 (0%), r = 0.0
→ 스테이커: 시뇨리지 없음 (자격 조건으로만 사용)
→ V3 전체 분배 (A₂ = A)
```

### 7.4 전환 조건 결정 가이드

거버넌스에서 λ, r 값을 조정할 때 고려해야 할 시장 지표:

| 지표 | 설명 | 전환 조건 예시 |
|------|------|----------------|
| **총 Bridged TON** | V3 분배 기준이 되는 값 | Bridged TON > 1억 TON 시 전환 가속 |
| **L2 활성도** | L2 트랜잭션 수, 사용자 수 | 활성 L2 수 > 10개 시 전환 가속 |
| **스테이킹 비율** | 전체 TON 중 스테이킹 비율 | 스테이킹 비율 안정화 시 전환 가속 |
| **스테이커 APY** | 스테이커의 연간 수익률 | APY가 목표 범위 내일 때 전환 진행 |
| **TON 가격 변동성** | 시장 안정성 지표 | 변동성 낮을 때 전환 가속 |

---

## 8. V3 분배 메커니즘 상세

### 8.1 V3: L2 시퀀서 + 검증자 시뇨리지 (RewardPerUint 방식)

```solidity
// V3: 쌍곡선 기반 누적 단위 보상 방식
// 대상: L2 시퀀서 + 검증자 (스테이커 제외)

// 1. 전체 L2 시뇨리지 계산 (쌍곡선 함수)
//    y(x) = L × (x / (k + x))
//    - L = (1-d)·A₂ : 분배 가능량
//    - x = Σ B̃_i  : 전체 유효 Bridged TON
//    - k = 반포화점
totalY = rmul(l2MaxAllocation, rdiv(totalX, halfSaturationPoint + totalX))

// 2. 단위당 보상 계산 (쌍곡선에 의해 결정)
//    rewardPerBridgedTON = y(x) / x = L / (k + x)
//    → x가 커질수록 단위당 보상 감소 (수확체감)
bridgedTONRewardPerUint += (totalY × WEI_UNIT) / totalEffectiveBridgedTON

// 3. L2별 시뇨리지 계산 (백서 공식 12)
//    S_i = y(x) · (B̃_i / x)
layer2Seigs = (bridgedTONRewardPerUint × B̃_i) / WEI_UNIT - initialDebt_i

// 4. 시퀀서/검증자 분리 (백서 V3 공식 13, 14)
//
//    (14) 시퀀서 보상: o_i = (1 - α) · S_i
sequencerReward = rmul(layer2Seigs, RAY - validatorDistributionRatio)

//    (13) 검증자 보상: v_j = Σ_{i: j∈V_i} (α · S_i) / |V_i|
//    - V_i = L2 i에 할당된 검증자 집합
//    - |V_i| = L2 i의 검증자 수
validatorAmount = rmul(layer2Seigs, validatorDistributionRatio)  // α · S_i

// RAT 컨트랙트에서 L2별로 검증자에게 분배:
if (validatorCount > 0) {
    perValidatorReward = validatorAmount / validatorCount  // (α · S_i) / |V_i|
} else {
    // |V_i| = 0 이면 DAO Treasury로 귀속
    transfer(treasury, validatorAmount)
}

// 5. 초기부채 갱신
initialDebt_i = (bridgedTONRewardPerUint × newB̃_i) / WEI_UNIT
```

**V3 특징:**
- `bridgedTONRewardPerUint`: Bridged TON 1단위당 누적 보상
- 동일한 `initialDebt` 패턴 사용 (V2 호환)
- **수확체감**: 전체 x가 커지면 단위당 보상 `L/(k+x)` 감소
- **L2별 검증자 분배**: 각 L2의 시뇨리지에서 검증자 몫 분리
- **검증자 미할당 시 DAO 귀속**: |V_i| = 0 이면 α · S_i → Treasury

### 8.2 비교 다이어그램

```
V2: 선형 분배
═══════════════════════════════════════
단위당 보상 = 상수 (TVL 무관)

보상
 │        ┌────────────────────
 │       /
 │      /
 │     /
 │    /
 │   /
 │──/──────────────────────────► TVL
   0

V3: 쌍곡선 분배 (수확체감)
═══════════════════════════════════════
단위당 보상 = L / (k + x) → x↑ 일수록 감소

y(x)
 │                    ┌─────── L (상한)
 │                 ╱
 │              ╱
 │           ╱
 │        ╱
 │     ╱
 │──╱──────────────────────────► x (Bridged TON)
   0   k
       └─ y(k) = L/2 (반포화점)
```

### 8.3 구현 비교 요약

| 구분 | V2 | V3 |
|------|-----|-----|
| **분배 기준** | TVL (layer2Tvl) | Bridged TON (B̃_i) |
| **단위당 보상** | `l2RewardPerUint` (고정 비례) | `bridgedTONRewardPerUint` (쌍곡선) |
| **누적 패턴** | ✅ initialDebt 사용 | ✅ initialDebt 사용 (동일) |
| **총 분배량** | `l2TotalSeigs = 상수×TVL` | `y(x) = L×(x/(k+x))` |
| **단위당 공식** | `l2TotalSeigs / totalTVL` | `y(x) / x = L / (k+x)` |
| **특성** | 선형 (2배 TVL = 2배 보상) | 수확체감 (한계효용 감소) |
| **측정 방식** | 기간 평균값 | 온체인 호출 시점 최신값 |

---

## 9. 백서 수식 vs 구현 함수 매핑

| 백서 공식 | 수식 | V3 구현 함수 | 파일 |
|----------|------|-------------|------|
| (7) | `S_DAO = d · A₂` | `rmul(A2, daoDistributionRatio)` | `SeigManagerV1_4.sol` |
| (8) | `S_i ≥ θ · B_i` | `checkCurrentEligibility()` | `SeigManagerV1_4.sol:339` |
| (9) | `1_i = {1 if eligible, 0 otherwise}` | `bridgedTONInfo[layer2].isEligible` | `SeigManagerV1_4.sol` |
| (10) | `x = Σ B̃_i` | `totalEffectiveBridgedTON` | `SeigManagerV1_4Storage.sol` |
| (11) | `y(x) = L · (x/(k+x))` | `hyperbolicSaturation()` | `SeigManagerV1_4.sol:392` |
| (12) | `S_i = y(x) · (B̃_i/x)` | `calculateL2Seigniorage()` | `SeigManagerV1_4.sol:405` |
| **(13)** | `v_j = Σ_{i: j∈V_i} (α·S_i) / \|V_i\|` | `RAT.distributeValidatorReward()` | `RAT.sol:585` |
| **(14)** | `o_i = (1 - α) · S_i` | `calculateSequencerReward()` | `SeigManagerV1_4.sol:420` |

### 9.1 V3 백서 공식 (13), (14) 상세

**공식 (13) - 검증자 보상:**
```
v_j = Σ_{i: j∈V_i} (α · S_i) / |V_i|
```
- `v_j`: 검증자 j가 받는 총 보상
- `V_i`: L2 i에 할당된 검증자 집합
- `|V_i|`: L2 i에 할당된 검증자 수
- `|V_i| = 0`이면 `α · S_i` → DAO Treasury

**공식 (14) - 시퀀서 보상:**
```
o_i = (1 - α) · S_i
```
- `o_i`: L2 i의 시퀀서가 받는 보상
- `S_i`: L2 i의 시뇨리지

---

## 10. DAO 귀속 명시

**백서 V2 (Page 15)**: "Additionally, any undistributed seigniorage to L2s is also allocated to the DAO, which may use the funds for ecosystem reinvestment and public infrastructure development."

미분배분은 DAO로 귀속됩니다.

```
미분배분 = L - y(x)

발생 조건:
- y(x) < L 일 때 (쌍곡선 함수 특성상 항상 y(x) < L)
- L2의 Bridged TON이 낮을수록 미분배분 증가

귀속처:
- DAO로 귀속
- 생태계 재투자, 공공 인프라 개발 등에 사용 가능 (백서 명시)
```

**분배 흐름 (V3):**
```
A₂ (V3 분배 재원)
├─► S_DAO = d · A₂        → DAO Treasury (고정 분배)
└─► L = (1-d) · A₂        → L2 분배 가능량
    ├─► y(x)              → L2별 분배
    │   ├─► (1-α)·S_i     → 시퀀서 (공식 14)
    │   └─► α·S_i         → 검증자 (공식 13)
    │       ├─► |V_i| > 0  → V_i 검증자들에게 균등 분배
    │       └─► |V_i| = 0  → DAO Treasury 귀속 ✅
    └─► L - y(x)          → DAO Treasury (미분배분)

∴ totalDAO = S_DAO + (L - y(x)) + Σ(검증자 없는 L2의 α·S_i)
```

---

## 11. 관련 코드 파일

### 11.1 핵심 구현 파일

| 파일 | 경로 | 역할 |
|------|------|------|
| **SeigManagerV1_4.sol** | `src/stake/managers/SeigManagerV1_4.sol` | V3 시뇨리지 분배 메인 로직 |
| **RAT.sol** | `src/validator/RAT.sol` | 검증자 보상 분배 |
| **IRAT.sol** | `src/validator/IRAT.sol` | RAT 인터페이스 |

### 11.2 주요 함수 매핑

| 백서 공식 | 함수 | 파일:라인 |
|----------|------|----------|
| `y(x) = L·(x/(k+x))` | `hyperbolicSaturation()` | `SeigManagerV1_4.sol:392-402` |
| `S_i = y(x)·(B̃_i/x)` | `calculateL2Seigniorage()` | `SeigManagerV1_4.sol:405-417` |
| `o_i = (1-α)·S_i` | `calculateSequencerReward()` | `SeigManagerV1_4.sol:420-427` |
| `v_j = Σ(α·S_i)/\|V_i\|` | `distributeValidatorReward()` | `RAT.sol:585-614` |

---

## 12. V3 백서 일치 여부 점검

### 12.1 점검 결과 요약

| 항목 | V3 백서 요구사항 | 현재 코드 | 일치 여부 |
|------|-----------------|----------|----------|
| **쌍곡선 포화 함수** | `y(x) = L·(x/(k+x))` | `hyperbolicSaturation()` | ✅ 일치 |
| **L2별 시뇨리지** | `S_i = y(x)·(B̃_i/x)` | `calculateL2Seigniorage()` | ✅ 일치 |
| **시퀀서 보상 (14)** | `o_i = (1-α)·S_i` | `calculateSequencerReward()` | ✅ 일치 |
| **검증자 보상 (13)** | `v_j = Σ(α·S_i)/\|V_i\|` | `distributeValidatorReward()` | ✅ 일치 |
| **검증자 미할당 시** | `\|V_i\|=0` → DAO Treasury | `treasury`로 전송 | ✅ 일치 |

### 12.2 구현 완료 항목 (2025-12-18)

| 항목 | 파일 | 상태 |
|------|------|------|
| 검증자 미할당 시 DAO Treasury 귀속 | `RAT.sol:592-598` | ✅ 완료 |
| `ValidatorRewardToTreasury` 이벤트 | `IRAT.sol:101-106` | ✅ 완료 |

---

## 13. 참조 문서

- **검증자 문서**: [04_validator.md](./04_validator.md)
- **V3 백서 변경사항**: [whitepaper_v2_to_v3_changes.md](./whitepaper_v2_to_v3_changes.md)
- **V3 문서 갭 분석**: [v3_docs_gap_analysis.md](./v3_docs_gap_analysis.md)
