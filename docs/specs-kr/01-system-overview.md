# TON Staking V3 시스템 개요

## 1. 시스템 소개

TON Staking V3는 Tokamak Network의 스테이킹 및 시뇨리지 분배 시스템입니다. 이더리움 L1에서 운영되며, 여러 L2 롤업(Titan, Thanos 등)과 상호작용하여 네트워크 보안과 경제적 인센티브를 제공합니다.

### 1.1 V3의 주요 변경사항

| 구분 | V2 | V3 |
|------|-----|-----|
| **시뇨리지 분배 기준** | L2 TVL (단순 비례) | Bridged TON (성과 기반) |
| **분배 함수** | 선형 분배 | 쌍곡선 포화 함수 `y(x) = L·(x/(k+x))` |
| **자격 조건** | 최소 예치금만 | S_i ≥ θ·B_i (스테이킹 비율 조건) |
| **검증자 보상** | 없음 | α·y(x) / n (검증자 풀 분배) |
| **DAO 할당** | 고정 비율 | 고정 비율 + 미분배분 |
| **스테이커 시뇨리지** | 제공 | **미제공** (V3에서 폐지) |

---

## 2. 시스템 목적

### 2.1 핵심 목표

1. **L2 네트워크 보안**: 시뇨리지 인센티브를 통해 L2 운영자(시퀀서)가 정직하게 행동하도록 유도
2. **검증자 참여 유도**: RAT(Randomized Attention Test)를 통해 검증자가 네트워크를 상시 감시하도록 동기 부여
3. **공정한 보상 분배**: Bridged TON 기반으로 실제 네트워크 기여도에 따른 보상 분배
4. **DAO 거버넌스**: 시스템 파라미터 조정 및 업그레이드를 DAO를 통해 관리

### 2.2 경제적 메커니즘

```
전체 시뇨리지 A
    │
    ├─► DAO 고정 분배: S_DAO = d · A
    │
    └─► L2 분배 가능량: L = (1-d) · A
        │
        ├─► 쌍곡선 함수: y(x) = L · (x / (k + x))
        │   │
        │   ├─► 시퀀서 보상: o_i = (1-α) · S_i
        │   │
        │   └─► 검증자 보상: v_j = (α · S_i) / |V_i|
        │
        └─► 미분배분: L - y(x) → DAO Treasury
```

---

## 3. 핵심 개념

### 3.1 Bridged TON (B_i)

각 L2에 브릿지된 TON의 총량입니다. L2의 성과를 측정하는 핵심 지표로, 시뇨리지 분배량을 결정합니다.

- **측정 방법**: L1BridgeRegistry에서 각 L2의 OptimismPortal 또는 L1StandardBridge 잔액 조회
- **역할**: 시뇨리지 분배 비율 결정

### 3.2 유효 Bridged TON (B̃_i)

자격 조건을 충족한 L2의 Bridged TON입니다.

```
B̃_i = 1_i · B_i

여기서:
1_i = 1 (자격 충족 시)
1_i = 0 (자격 미충족 시)
```

### 3.3 자격 조건

L2가 시뇨리지를 받으려면 최소 담보금 요건을 충족해야 합니다:

```
S_i ≥ max(θ · B_i, H_max · C_max + Δ_sequencer)

여기서:
S_i = L2의 시퀀서 담보금 (SequencerVault)
θ · B_i = 시뇨리지 자격 조건 (백서 Rule 4)
H_max · C_max + Δ_sequencer = Fraud Proof 비용 커버 (백서 Formula 1)

파라미터:
θ = 최소 스테이킹 비율 (예: 10%)
B_i = L2의 Bridged TON
H_max = 최대 동시 챌린저 수
C_max = 단일 Fraud Proof 최대 비용
Δ_sequencer = 시퀀서 추가 보상
```

### 3.4 쌍곡선 포화 함수

시뇨리지 분배에 수확체감 효과를 적용하여 소수 L2의 독점을 방지합니다:

```
y(x) = L · (x / (k + x))

여기서:
L = (1-d) · A (L2 분배 가능량)
x = Σ B̃_i (전체 유효 Bridged TON)
k = 반포화점 (halfSaturationPoint)
```

### 3.5 RAT (Randomized Attention Test)

검증자가 네트워크를 실제로 모니터링하고 있는지 확인하는 무작위 테스트입니다.

- **트리거 시점**: DisputeGame 생성 시 확률적으로 발생 (π_a)
- **응답 기간**: `evidenceSubmissionPeriod` (기본값: 1시간)
- **미응답 시**: C_off 슬래싱 (담보금 일부 몰수)

---

## 4. 시스템 구성 요소

### 4.1 핵심 컨트랙트

| 컨트랙트 | 역할 |
|---------|------|
| **SeigManager** | 시뇨리지 계산 및 분배의 핵심 |
| **DepositManager** | TON/WTON 스테이킹 관리 |
| **Layer2Manager** | L2 등록 및 관리 |
| **L1BridgeRegistry** | 브릿지/포탈 등록 및 TVL 조회 |
| **RAT** | 검증자 등록, RAT 테스트, 슬래싱 |
| **ValidatorReward** | 검증자 보상 분배 |
| **SequencerVault** | 시퀀서 담보금 관리 |

### 4.2 토큰

| 토큰 | 역할 |
|------|------|
| **TON** | 네이티브 토큰 (18 decimals) |
| **WTON** | Wrapped TON (27 decimals, 1 TON(wei) = 1e9 WTON(ray)) |
| **Coinage** | 스테이킹 영수증 토큰 (L2별 생성) |

### 4.3 외부 시스템

| 시스템 | 역할 |
|--------|------|
| **Optimism L2** | L2 롤업 (Titan, Thanos 등) |
| **DisputeGameFactory** | Dispute Game 생성 (RAT 트리거) |
| **OptimismPortal** | L1↔L2 브릿지 |
| **DAO** | 거버넌스 (DAOCommittee) |

---

## 5. 주요 흐름

### 5.1 시뇨리지 분배 흐름

```
1. updateSeigniorage() 호출
   │
2. 전체 시뇨리지 A 계산
   │ A = (currentBlock - lastSeigBlock) × seigPerBlock
   │
3. v3Migrated 플래그 확인
   │
   ├─ V2 모드: 기존 V1_3 로직
   │
   └─ V3 모드:
      │
      ├─ DAO 분배: d · A
      │
      ├─ L2 분배 가능량: L = (1-d) · A
      │
      ├─ 각 L2의 자격 확인 (S_i ≥ θ · B_i)
      │
      ├─ 유효 Bridged TON 합계: x = Σ B̃_i
      │
      ├─ 쌍곡선 함수: y(x) = L · (x/(k+x))
      │
      ├─ L2별 시뇨리지: S_i = y(x) · (B̃_i / x)
      │
      ├─ 시퀀서 보상: o_i = (1-α) · S_i
      │
      └─ 검증자 보상: α · S_i → ValidatorReward
```

### 5.2 검증자 RAT 흐름

```
1. L2 프로포저가 DisputeGame 생성
   │
2. RAT.triggerAttentionTest() 호출
   │
3. 확률 체크 (π_a)
   │
4. 검증자 랜덤 선택
   │
5. C_off 선차감 (D_min 미만 시 검증자 제거)
   │
6. 검증자 응답 대기 (evidenceSubmissionPeriod)
   │
   ├─ 증거 제출: C_off 복구 (D_min 체크여 검증자 상태 갱신)
   │
   └─ 미응답: C_off 몰수
```

### 5.3 시퀀서 슬래싱 흐름

```
1. 시퀀서가 잘못된 Output Root 제출
   │
2. 챌린저가 Fraud Proof 제출
   │
3. DisputeGame 해결
   │
4. slashSequencerByGame() 호출 (Permissionless)
   │
5. 시퀀서 담보금 슬래싱
   │
   ├─ 챌린저 보상: C_max + Δ/n
   │
   └─ 나머지: DAO Treasury
```

---

## 6. V3 핵심 파라미터

| 파라미터 | 기호 | 설명 | 권장값 |
|---------|------|------|--------|
| `seigPerBlock` | A/블록 | 블록당 시뇨리지 발행량 | 3.92e18 (3.92 TON) |
| `daoDistributionRatio` | d | DAO 고정 분배 비율 | 0.2e27 (20%) |
| `minStakingRatio` | θ | 최소 스테이킹 비율 | 0.1e27 (10%) |
| `validatorDistributionRatio` | α | 검증자 분배 비율 | 0.2e27 (20%) |
| `halfSaturationPoint` | k | 반포화점 | 10,000,000e27 TON |
| `ratTriggerProbability` | π_a | RAT 트리거 확률 | 게임 이론 기반 결정 * |
| `slashingPenalty` | C_off | 슬래싱 페널티 | 100e27 WTON |
| `minimumThreshold` | D_min | 최소 담보금 임계값 | 1,000e27 WTON |
| `maxValidatorsPerL2` | N_max | L2별 최대 검증자 수 | 100 |
| `evidenceSubmissionPeriod` | T_response | RAT 응답 제출 기간 | 1 hours |

> **RAY 단위**: 모든 비율 파라미터는 RAY(10^27) 단위로 표현됩니다.
>
> **\* 게임 이론 기반 결정**: π_a, C_off, c_m(모니터링 비용), N(검증자 수)은 백서 공식 `C_off ≥ (c_m · N) / π_a`를 만족하도록 함께 결정되어야 합니다.
>
> **백서 작성자(Bernard) 확인사항**:
> - N = L2별 검증자 수 (|V_i|), 시스템 전체가 아님
> - 공식은 **이론적 근거**이며, 실시간 동적 업데이트 규칙이 아님
> - `Δ_validator`에 충분한 마진을 설정 + **실질적인 N_max 고려 필요**
> - 검증자는 `ValidatorRegistered` 이벤트를 모니터링하여 자격 상태 확인
> - 담보금 부족 시: 유예 기간 제공 또는 소급 적용 안함
>
> **구현 결정사항** (버나드 지침 외):
> - N_max 기본값: 정해야함 (시뇨리지 분배 시 가스 한도 고려, 각 검증자당 ~25K gas)

---

## 7. 관련 문서

- [02-system-architecture.md](./02-system-architecture.md): 시스템 아키텍처
- [03-contract-structure.md](./03-contract-structure.md): 컨트랙트 구조
- [04-contract-roles.md](./04-contract-roles.md): 컨트랙트별 역할
- [05-actors.md](./05-actors.md): 액터 정의
- [06-function-specs.md](./06-function-specs.md): 함수별 상세 설명
