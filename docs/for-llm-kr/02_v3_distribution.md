# V3 시뇨리지 분배 공식

## 1. V3/V2 시뇨리지 분배 흐름

```
updateSeigniorage() 호출 시 - v3Migrated 플래그에 따라 분기:

═══════════════════════════════════════════════════════════════
V3 모드 (v3Migrated = true): 전체 시뇨리지 → V3 분배
═══════════════════════════════════════════════════════════════

A (전체 시뇨리지) = A₂ (V3 분배 재원, 스테이커 분배 없음)
│
└─► V3 분배 (백서 공식 적용)
    │
    ├─► DAO 고정 분배 (백서 공식 7):
    │   S_DAO = d · A
    │
    ├─► L2 분배 가능량:
    │   L = (1 - d) · A
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

═══════════════════════════════════════════════════════════════
V2 모드 (v3Migrated = false): V1_3 로직과 동일
═══════════════════════════════════════════════════════════════

A (전체 시뇨리지)
│
├─► Step 1: 스테이커 지분 시뇨리지 (V1_3 공식)
│   stakedSeig = A × prevTotalSupply / tos
│
├─► Step 2: Layer2 TVL 시뇨리지
│   l2TotalSeigs = A × tempTotalLayer2TVL / tos
│
├─► Step 3: 스테이커 추가 시뇨리지 (r 적용)
│   unstakedSeig = A - stakedSeig - l2TotalSeigs
│   totalPseig = unstakedSeig × r
│   - r: relativeSeigRate (V1_3 기존 파라미터)
│
├─► Step 4: Coinage factor 업데이트
│   nextTotalSupply = prevTotalSupply + stakedSeig + totalPseig
│
└─► Step 5: PowerTON, DAO 분배
    powertonSeig = unstakedSeig × powerTONSeigRate
    daoSeig = unstakedSeig × daoSeigRate
```

---

## 2. 변수 설명

| 변수 | 설명 |
|------|------|
| **A** | 전체 기간 시뇨리지 (발행될 총량) |
| **stakedSeig** | V2 모드: 스테이커 지분 시뇨리지 (V1_3 공식) |
| **l2TotalSeigs** | V2 모드: Layer2 TVL 기반 시뇨리지 |
| **totalPseig** | V2 모드: 스테이커 추가 시뇨리지 (unstakedSeig × r) |
| **r** | 추가 시뇨리지 비율 (relativeSeigRate, V1_3 기존 파라미터) |
| **d** | DAO 분배 비율 (daoDistributionRatio) |
| **θ** | 최소 스테이킹 비율 (minStakingRatio) |
| **α** | 검증자 분배 비율 (validatorDistributionRatio) |
| **k** | 반포화점 (halfSaturationPoint) |
| **L** | L2 분배 가능량 = (1-d)·A (V3 모드) |
| **x** | 전체 유효 Bridged TON = Σ B̃_i |
| **y(x)** | 쌍곡선 포화 함수 결과 |

---

## 3. 수학적 표현

### V3 모드 (v3Migrated = true)

```
A₂ = A (전체 시뇨리지가 V3 분배 재원)

S_DAO = d · A
L = (1 - d) · A
y(x) = L · (x / (k + x))
Seig_i = y(x) · (B̃_i / x)
```

### V2 모드 (v3Migrated = false, V1_3과 동일)

```
stakedSeig = A × prevTotalSupply / tos
l2TotalSeigs = A × tempTotalLayer2TVL / tos
unstakedSeig = A - stakedSeig - l2TotalSeigs
totalPseig = unstakedSeig × r
nextTotalSupply = prevTotalSupply + stakedSeig + totalPseig
```

---

## 4. V3 전환

V3 전환은 `migrateToV3()` 함수 호출로 이루어집니다:

```solidity
function migrateToV3() external onlyOwner {
    v3Migrated = true;  // 이 플래그가 V3 모드 활성화
}
```

**전환 효과:**
- 스테이커 시뇨리지 = 0 (stakedSeig, totalPseig 계산 생략)
- 전체 시뇨리지 A가 V3 분배 재원 (A₂ = A)
- Layer2 TVL 기반 분배 → Bridged TON 기반 분배로 변경
- 검증자 보상 활성화

---

## 5. V2/V3 분배 비교

| 항목 | V2 모드 (V1_3) | V3 모드 |
|------|---------------|---------|
| 스테이커 시뇨리지 | stakedSeig + totalPseig | **없음** |
| L2 분배 기준 | Layer2 TVL | Bridged TON |
| 검증자 보상 | 없음 | α 비율 분배 |
| DAO 분배 | unstakedSeig × daoSeigRate | d × A |
| PowerTON | unstakedSeig × powerTONSeigRate | **없음** |
| 분배 함수 | 선형 | 쌍곡선 포화 |

---

## 6. 핵심 변경점

- ❌ V2: 스테이킹 지분 비례 분배 → ✅ V3: Bridged TON 비례 분배
- ✅ **즉시 전환**: `v3Migrated = true` 설정 시 V3 모드 활성화
- ❌ V2: TVL 기반 L2 보상 → ✅ V3: 성과(Bridged TON) 기반 + 자격 조건
- ❌ V2: 검증자 보상 없음 → ✅ V3: 검증자에게 α 비율 분배
- ❌ V2: 선형 분배 → ✅ V3: 쌍곡선 포화 함수 (수확체감)

---

## 7. V2 → V3 전환 메커니즘

### 7.1 전환 방식

V3 전환은 `v3Migrated` 플래그를 통해 **즉시 전환** 방식으로 이루어집니다.

```solidity
function migrateToV3() external onlyOwner {
    if (v3Migrated) revert AlreadyMigratedError();
    v3Migrated = true;
    emit V3MigrationCompleted(block.number);
}
```

### 7.2 전환 전후 비교

| 항목 | V2 모드 (v3Migrated=false) | V3 모드 (v3Migrated=true) |
|------|---------------------------|--------------------------|
| **스테이커 시뇨리지** | V1_3 공식으로 계산 | **없음** (계산 생략) |
| **relativeSeigRate** | V1_3 공식에서 사용 | **미사용** |
| **L2 분배 기준** | Layer2 TVL | Bridged TON |
| **검증자 보상** | 없음 | α 비율 분배 |
| **DAO 분배** | unstakedSeig × daoSeigRate | d × A |
| **PowerTON** | 분배됨 | **없음** |
| **Coinage Factor** | 업데이트됨 | **변경 없음** |

### 7.3 V2 모드 (V1_3과 동일)

V2 모드에서는 기존 V1_3의 `_increaseTot()` 로직이 그대로 사용됩니다:

```solidity
// V1_3 공식 그대로 사용
stakedSeig = rdiv(rmul(A, prevTotalSupply), tos);
l2TotalSeigs = rdiv(rmul(A, tempTotalLayer2TVL), tos);
unstakedSeig = A - stakedSeig - l2TotalSeigs;
totalPseig = rmul(unstakedSeig, relativeSeigRate);  // r 사용
nextTotalSupply = prevTotalSupply + stakedSeig + totalPseig;
```

### 7.4 V3 모드

V3 모드에서는 스테이커 시뇨리지 계산이 완전히 생략됩니다:

```solidity
// 스테이커 시뇨리지 없음 - Coinage factor 변경 없음
emit CommitLog1(_tot.totalSupply(), tos, prevTotalSupply, prevTotalSupply);

// 전체 시뇨리지가 V3 분배 재원
if (A > 0) {
    _distributeV3Seigniorage(A);  // A₂ = A
}
```

### 7.5 되돌릴 수 없음

`v3Migrated`가 true로 설정되면 다시 false로 변경할 수 없습니다. 이는 의도적인 설계입니다.

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

// ValidatorReward 컨트랙트에서 L2별로 검증자에게 분배:
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

### 8.2 구현 비교 요약

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
| **(13)** | `v_j = Σ_{i: j∈V_i} (α·S_i) / \|V_i\|` | `ValidatorRewardV1.distributeL2Rewards()` | `ValidatorRewardV1.sol` |
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

## 11. V3 스테이커 시뇨리지 제거

### 11.1 핵심 변경사항

**V3에서는 스테이커에게 시뇨리지를 제공하지 않습니다.**

| 구분 | V2 | V3 |
|------|-----|-----|
| **스테이커 시뇨리지** | ✅ 제공 (Coinage factor 기반) | ❌ 제공하지 않음 |
| **스테이킹 역할** | 시뇨리지 수령 자격 | **미사용** (자격 조건은 SequencerVault 담보금으로 확인) |
| **시뇨리지 수령자** | 스테이커 + L2 시퀀서 | L2 시퀀서 + 검증자 + DAO |

### 11.2 V2 스테이커 시뇨리지 구성

V2에서 스테이커 시뇨리지는 두 가지로 구성됩니다 (V1_3 공식):

```
1. 지분 시뇨리지 (stakedSeig)
   - 공식: stakedSeig = A × prevTotalSupply / tos
   - TON 총 공급량 대비 스테이킹 비율에 비례하여 분배
   - Coinage factor 방식으로 자동 누적

2. 추가 시뇨리지 (totalPseig)
   - 공식: totalPseig = unstakedSeig × r
   - unstakedSeig = A - stakedSeig - l2TotalSeigs
   - relativeSeigRate(r)에 따른 추가 보상
```

### 11.3 구현 방식

V3에서는 `v3Migrated` 플래그를 통해 스테이커 시뇨리지를 **완전히 비활성화**합니다. V2 모드에서는 V1_3의 `_increaseTot()` 로직을 그대로 사용합니다.

#### 핵심 로직 (SeigManagerV1_4.sol:748-828)

```solidity
if (v3Migrated) {
    // ========================================
    // V3: 스테이커 시뇨리지 없음 (V3 백서)
    // A₂ = A (전체 시뇨리지가 V3 분배 재원)
    // ========================================
    emit CommitLog1(_tot.totalSupply(), tos, prevTotalSupply, prevTotalSupply);

    if (A > 0) {
        (l2TotalSeigs, layer2Seigs) = _distributeV3Seigniorage(A);
    }
} else {
    // ========================================
    // V2: V1_3 _increaseTot() 로직과 동일
    // ========================================
    S_staked = rdiv(rmul(A, prevTotalSupply), tos);
    // ... layer2 TVL 시뇨리지 계산 ...
    unstakedSeig = A - S_staked - l2TotalSeigs;
    totalPseig = rmul(unstakedSeig, relativeSeigRate);
    nextTotalSupply = prevTotalSupply + S_staked + totalPseig;
    // ...
}
```

#### V3/V2 모드 비교

| 항목 | V2 (v3Migrated=false) | V3 (v3Migrated=true) |
|------|----------------------|----------------------|
| `stakedSeig` | A × prevTotalSupply / tos | **0** (계산 생략) |
| `l2TotalSeigs` | Layer2 TVL 기반 계산 | **0** (bridgedTON 사용) |
| `totalPseig` | (A - stakedSeig - l2TotalSeigs) × r | **0** (계산 생략) |
| `nextTotalSupply` | prevTotalSupply + stakedSeig + totalPseig | **prevTotalSupply** (변경 없음) |
| Coinage factor | V1_3과 동일하게 업데이트 | **변경 없음** |
| PowerTON | V1_3과 동일하게 분배 | **0** |
| L2 분배 기준 | Layer2 TVL | Bridged TON |

### 11.4 V3 활성화 방법

V3 마이그레이션 함수를 호출하면 자동으로 스테이커 시뇨리지가 비활성화됩니다:

```solidity
// SeigManagerV1_4.sol
function migrateToV3() external onlyOwner {
    require(!v3Migrated, "already migrated");
    v3Migrated = true;  // 이 플래그가 스테이커 시뇨리지를 비활성화
    v3MigrationBlock = block.number;
    emit V3MigrationCompleted(block.number, 0);
}
```

**V3 컨트랙트 주소 설정 (별도 호출):**
```solidity
SeigManagerV1_4.setValidatorReward(validatorRewardProxy);  // 검증자 보상 분배
SeigManagerV1_4.setRATContract(ratProxy);                   // RAT 검증자 관리
```

**추가 파라미터 설정 불필요**: `v3Migrated = true`가 되면 기존 V1_3 파라미터(r 등)와 관계없이 스테이커 시뇨리지가 0이 됩니다.

### 11.5 전환 효과

**v3Migrated = true 설정 시:**

```
전체 시뇨리지 A 분배:

V2 (v3Migrated=false, V1_3 동일):    V3 (v3Migrated=true):
─────────────────────────────────   ─────────────────────
A                                   A
├─► stakedSeig → 스테이커            │ (계산 생략)
│   └─► Coinage factor 증가          │
├─► l2TotalSeigs → Layer2 TVL 기반   │ (bridgedTON 기반으로 변경)
├─► totalPseig → 스테이커 (r 비율)   │ (계산 생략)
├─► PowerTON (unstakedSeig 기반)     │ (비활성)
├─► DAO (unstakedSeig 기반)          │
│                                    │
└─► 잔여                              └─► A = A₂ (100%) → V3 분배
                                          ├─► DAO (d·A)
                                          ├─► L2 시퀀서 ((1-α)·S_i)
                                          └─► 검증자 (α·S_i)
```

**V1_3 공식 (V2 모드):**
- `stakedSeig = A × prevTotalSupply / tos`
- `l2TotalSeigs = A × tempTotalLayer2TVL / tos`
- `unstakedSeig = A - stakedSeig - l2TotalSeigs`
- `totalPseig = unstakedSeig × relativeSeigRate`
- `nextTotalSupply = prevTotalSupply + stakedSeig + totalPseig`

### 11.6 주의사항

1. **Coinage Factor**: V3에서는 `_tot.setFactor()` 호출이 생략됨 (prevTotalSupply = nextTotalSupply)
2. **기존 스테이커**: 전환 전 누적된 시뇨리지는 유지됨 (Coinage에 이미 반영)
3. **스테이킹 동기**: V3에서 DepositManager를 통한 L1 스테이킹은 계속 지원되지만 시뇨리지 미지급. 시퀀서 자격 조건(S_i ≥ θ·B_i)은 SequencerVault 담보금으로 확인
4. **되돌릴 수 없음**: `v3Migrated`는 한번 true가 되면 false로 변경 불가

### 11.7 검증 방법

전환 후 다음을 확인:

```solidity
// 1. 마이그레이션 상태 확인
assert(seigManager.v3Migrated() == true);

// 2. updateSeigniorage() 호출 후 이벤트 확인
// SeigGiven2 이벤트에서:
// - S_staked = 0
// - S_relative = 0
// - unstakedSeig = 0
// - powertonSeig = 0

// 3. CommitLog1 이벤트에서:
// - prevTotalSupply == nextTotalSupply (coinage 변화 없음)
```

---

## 12. 관련 코드 파일

### 12.1 핵심 구현 파일

| 파일 | 경로 | 역할 |
|------|------|------|
| **SeigManagerV1_4.sol** | `src/stake/managers/SeigManagerV1_4.sol` | V3 시뇨리지 분배 메인 로직 |
| **ValidatorRewardV1.sol** | `src/validator/ValidatorRewardV1.sol` | 검증자 보상 분배 |
| **RAT.sol** | `src/validator/RAT.sol` | 검증자 등록/담보금/슬래싱 |
| **IValidatorReward.sol** | `src/validator/IValidatorReward.sol` | ValidatorReward 인터페이스 |
| **IRAT.sol** | `src/validator/IRAT.sol` | RAT 인터페이스 |

### 12.2 주요 함수 매핑

| 백서 공식 | 함수 | 파일:라인 |
|----------|------|----------|
| `y(x) = L·(x/(k+x))` | `hyperbolicSaturation()` | `SeigManagerV1_4.sol:392-402` |
| `S_i = y(x)·(B̃_i/x)` | `calculateL2Seigniorage()` | `SeigManagerV1_4.sol:405-417` |
| `o_i = (1-α)·S_i` | `calculateSequencerReward()` | `SeigManagerV1_4.sol:420-427` |
| `v_j = Σ(α·S_i)/\|V_i\|` | `distributeL2Rewards()` | `ValidatorRewardV1.sol` |

---

## 13. V3 백서 일치 여부 점검

### 13.1 점검 결과 요약

| 항목 | V3 백서 요구사항 | 현재 코드 | 일치 여부 |
|------|-----------------|----------|----------|
| **쌍곡선 포화 함수** | `y(x) = L·(x/(k+x))` | `hyperbolicSaturation()` | ✅ 일치 |
| **L2별 시뇨리지** | `S_i = y(x)·(B̃_i/x)` | `calculateL2Seigniorage()` | ✅ 일치 |
| **시퀀서 보상 (14)** | `o_i = (1-α)·S_i` | `calculateSequencerReward()` | ✅ 일치 |
| **검증자 보상 (13)** | `v_j = Σ(α·S_i)/\|V_i\|` | `distributeL2Rewards()` | ✅ 일치 |
| **검증자 미할당 시** | `\|V_i\|=0` → DAO Treasury | `treasury`로 전송 | ✅ 일치 |

### 13.2 구현 완료 항목 (2025-12-19)

| 항목 | 파일 | 상태 |
|------|------|------|
| 검증자 미할당 시 DAO Treasury 귀속 | `ValidatorRewardV1.sol` | ✅ 완료 |
| `ValidatorRewardToTreasury` 이벤트 | `IValidatorReward.sol` | ✅ 완료 |
| Per-L2 보상 추적 | `ValidatorRewardStorage.sol` | ✅ 완료 |
| `ValidatorRewardReceived` 이벤트 | `IValidatorReward.sol` | ✅ 완료 |

---

## 14. 참조 문서

- **검증자 문서**: [04_validator.md](./04_validator.md)
- **RAT 구현**: [07_rat_implementation.md](./07_rat_implementation.md)
- **구현 코드**: [08_implementation.md](./08_implementation.md)
