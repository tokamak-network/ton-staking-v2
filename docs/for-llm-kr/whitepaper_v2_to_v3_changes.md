# 백서 V2 → V3 변경사항

> **문서 작성일**: 2025-12-18
> **비교 대상**:
> - V2: Tokamak Economics Whitepaper V2 (December 9, 2025)
> - V3: Tokamak Economics Whitepaper V2 (December 16, 2025)

---

## 1. 개요

이 문서는 백서 V2 (2025-12-09)와 V3 (2025-12-16) 간의 변경사항을 정리합니다. V3는 V2의 수정본으로, 검증자 보상 분배 방식과 측정 방식에 대한 중요한 변경이 포함되어 있습니다.

---

## 2. 핵심 변경사항

### 2.1 검증자 보상 공식 변경 (공식 13)

**V2 (Page 16):**
```
v_i = (α/n) · y(x),    o_i = (1 − α) · S_i
```

| 변수 | 설명 |
|------|------|
| `v_i` | 각 검증자가 받는 보상 |
| `α` | 검증자 분배 비율 |
| `n` | 전체 검증자 수 |
| `y(x)` | 전체 L2 시뇨리지 |
| `o_i` | 시퀀서가 받는 보상 |
| `S_i` | L2 i의 시뇨리지 |

**V3 (Page 16-17):**
```
v_j = Σ_{i: j∈V_i} (α · S_i) / |V_i|    ... (13) 검증자 보상
o_i = (1 − α) · S_i                      ... (14) 시퀀서 보상
```

| 변수 | 설명 |
|------|------|
| `v_j` | 검증자 j가 받는 보상 |
| `V_i` | L2 i에 할당된 검증자 집합 |
| `|V_i|` | L2 i의 검증자 수 |
| `S_i` | L2 i의 시뇨리지 |
| `o_i` | L2 i의 시퀀서가 받는 보상 |

**변경 내용:**

| 구분 | V2 | V3 |
|------|-----|-----|
| **분배 기준** | 전체 y(x)에서 균등 분배 | L2별 시뇨리지(S_i)에서 분배 |
| **검증자 수** | n = 전체 검증자 수 | \|V_i\| = 해당 L2에 할당된 검증자 수 |
| **보상 구조** | 모든 검증자 동일 보상 | 할당된 L2의 성과에 비례 |

**V3 추가 규칙:**
> "If no validators are assigned to L2 i (|V_i| = 0), the validator portion α · S_i is allocated to the DAO treasury."

- 검증자가 할당되지 않은 L2의 검증자 몫(α · S_i)은 **DAO Treasury로 귀속**

---

### 2.2 Bridged TON / Staked TON 측정 방식 변경

**V2 (Page 15):**
> "Note that Bridged TON and Staked TON should be measured as **averaged values over the period** rather than a single snapshot. Additionally, annual seigniorage is divided into multiple periods for evaluating L2 performance and distributing rewards."

**V3 (Page 15):**
> "Bridged TON and Staked TON are **not sampled at strictly fixed intervals**. Instead, the protocol uses the **latest observed values captured through on-chain calls**, and the evaluation mechanism is structured to closely track periodic measurements over time."

| 구분 | V2 | V3 |
|------|-----|-----|
| **측정 방식** | 기간 평균값 (averaged values over the period) | 온체인 호출 시점의 최신 관측값 (latest observed values) |
| **샘플링** | 주기적 스냅샷 기반 | 고정 간격 아님, 온체인 호출 기반 |

**구현 영향:**
- V2: 기간 내 여러 시점의 평균을 계산해야 함
- V3: 호출 시점의 최신값 사용 (구현 단순화)

---

## 3. 표현 및 톤 변경

V3에서는 단정적 표현이 조건부/의도 표현으로 완화되었습니다.

### 3.1 보안 관련 표현

| 위치 | V2 | V3 |
|------|-----|-----|
| **2.1.1 Sequencer Slashing** | "This **guarantees** that challengers receive additional profit beyond their verification costs." | "This **is intended to** provide rewards that can exceed verification costs." |
| **2.1.1 Sequencer Slashing** | "A slashed sequencer is **immediately suspended** from sequencing." | "A slashed sequencer is suspended from sequencing **according to protocol rules**." |
| **2.1.1 Validator Slashing** | "This **ensures** that attentiveness is always the rational strategy for each validator." | "The mechanism **is designed so that**, under the chosen parameters, attentiveness is each validator's rational strategy." |

### 3.2 경제 모델 관련 표현

| 위치 | V2 | V3 |
|------|-----|-----|
| **3.1 Sustainable Growth** | "TON demand generated within the L2 ecosystem (such as utility fees) **can offset** this and reduce net selling pressure." | "TON demand generated within the L2 ecosystem (such as utility fees) **may offset** this and help reduce net selling pressure **under certain conditions**." |
| **3.3.1 TON Staking V3** | "This approach **prevents** artificial TVL inflation using external assets and **more accurately reflects** the genuine economic activity" | "This approach **is intended to discourage** artificial TVL inflation using external assets and **provides a closer proxy for** TON-native economic activity" |

### 3.3 검증자 역할 표현

| 위치 | V2 | V3 |
|------|-----|-----|
| **1.2 Validators** | "validators are **required to stake** TON as economic collateral" | "Validators **may optionally register as staked validators** by staking TON as economic collateral" |

---

## 4. 용어 변경

| 위치 | V2 | V3 |
|------|-----|-----|
| **Summary** | "architectural evolution" | "architectural progression" |
| **Summary** | "genuine economic activity" | "effective economic activity" |
| **Summary** | "the ultimate anchor" | "the security anchor" |
| **1.1** | "validity rollups (often called zk–rollups)" | "ZK rollups" |
| **1.1** | "the central design problem" | "the core design problem" |
| **1.3** | "introduces two complementary mechanisms" | "proposes two complementary mechanisms" |
| **2.2** | "structural and continuous source of demand" | "ongoing, utility-driven source of demand" |
| **Figure 1** | "Rollup Data" | "Rollup Transaction" |

---

## 5. 구조적 변경

### 5.1 공식 번호 추가

V3에서 시퀀서 보상 공식이 별도 번호로 분리됨:

**V2:**
- 공식 (13): `v_i = (α/n) · y(x), o_i = (1 − α) · S_i` (검증자 + 시퀀서 통합)

**V3:**
- 공식 (13): `v_j = Σ_{i: j∈V_i} (α · S_i) / |V_i|` (검증자 보상)
- 공식 (14): `o_i = (1 − α) · S_i` (시퀀서 보상)

---

## 6. 변경사항 요약 테이블

| 항목 | V2 | V3 | 영향도 |
|------|-----|-----|--------|
| **검증자 보상 분배** | 전체 균등 분배 `(α/n)·y(x)` | L2별 할당 `(α·S_i)/|V_i|` | **높음** |
| **검증자 미할당 시** | 명시 없음 | α·S_i → DAO Treasury | **높음** |
| **측정 방식** | 기간 평균값 | 온체인 호출 시점 최신값 | **중간** |
| **표현 톤** | 단정적 (guarantees, ensures) | 조건부 (intended to, designed so that) | 낮음 |
| **용어** | 일부 용어 차이 | 명확화/단순화 | 낮음 |

---

## 7. 구현 영향 분석

### 7.1 검증자 보상 분배 로직 변경

**기존 구현 (V2 기준):**
```solidity
// 전체 검증자에게 균등 분배
uint256 validatorReward = (alpha * totalY) / totalValidators;
for (uint256 i = 0; i < totalValidators; i++) {
    validators[i].reward += validatorReward;
}
```

**새로운 구현 (V3 기준):**
```solidity
// L2별로 할당된 검증자에게 분배
for (uint256 i = 0; i < l2Count; i++) {
    uint256 l2Seigniorage = getSeigniorage(l2[i]);
    uint256 validatorPortion = (alpha * l2Seigniorage);

    address[] memory assignedValidators = getAssignedValidators(l2[i]);

    if (assignedValidators.length == 0) {
        // 검증자 없으면 DAO Treasury로
        daoTreasury += validatorPortion;
    } else {
        uint256 perValidatorReward = validatorPortion / assignedValidators.length;
        for (uint256 j = 0; j < assignedValidators.length; j++) {
            validators[assignedValidators[j]].reward += perValidatorReward;
        }
    }
}
```

### 7.2 측정 방식 변경

**기존 구현 (V2 기준):**
```solidity
// 기간 평균 계산 필요
uint256 averageBridgedTON = calculatePeriodAverage(l2, startBlock, endBlock);
```

**새로운 구현 (V3 기준):**
```solidity
// 호출 시점 최신값 사용
uint256 currentBridgedTON = getBridgedTON(l2);
```

### 7.3 필요한 추가 데이터 구조

V3 구현을 위해 필요한 새로운 데이터:

```solidity
// L2별 할당된 검증자 집합
mapping(address => address[]) public l2ToValidators;

// 검증자가 할당된 L2 목록
mapping(address => address[]) public validatorToL2s;
```

---

## 8. 마이그레이션 고려사항

### 8.1 검증자 할당 메커니즘 필요

V3에서는 검증자가 특정 L2에 **할당**되어야 합니다. 이를 위한 메커니즘 결정 필요:

1. **자동 할당**: 프로토콜이 검증자를 L2에 자동 배정
2. **수동 할당**: 검증자가 모니터링할 L2를 선택
3. **하이브리드**: 기본 할당 + 선택적 추가 할당

### 8.2 기존 검증자 처리

- 기존 검증자들에게 L2 할당 필요
- 할당 없는 전환 기간 동안 보상 처리 방안 결정

### 8.3 DAO Treasury 귀속 로직

- 검증자 미할당 L2의 α · S_i 처리 로직 추가
- Treasury 주소 및 관리 방안 확정

---

## 9. 관련 문서

- `02_v3_distribution.md`: V3 시뇨리지 분배 공식
- `04_validator.md`: 검증자 역할 및 보상
- `07_rat_implementation.md`: RAT 구현 명세
- `11_whitepaper_v2_changes.md`: 이전 백서 변경사항 (V1 → V2)

---

## 10. 변경 이력

| 날짜 | 내용 |
|------|------|
| 2025-12-18 | 최초 작성 - 백서 V2 (Dec 9) → V3 (Dec 16) 변경사항 정리 |
