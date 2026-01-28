---
id: 05-actors
sidebar_position: 5
---
# TON Staking V3 액터 정의

## 1. 액터 개요

TON Staking V3 시스템에서 상호작용하는 주요 액터들을 정의합니다.

| 액터 | 역할 | 보상 | 리스크 |
|------|------|------|--------|
| **스테이커** | TON 스테이킹 | V3에서 없음 | 없음 |
| **시퀀서** | L2 운영, 배치 제출 | (1-α)·S_i | 담보금 슬래싱 |
| **검증자** | L2 배치 검증, RAT 응답 | α·S_i/\|V_i\| | C_off 슬래싱 |
| **챌린저** | Fraud Proof 제출 | C_max + Δ/n | 가스비 손실 |
| **DAO** | 거버넌스, 파라미터 설정 | d·A + 미분배분 | 없음 |
| **L2 프로포저** | Output Root 제출 | - | - |

---

## 2. 스테이커 (Staker)

### 2.1 정의

TON을 L2에 스테이킹하는 사용자입니다.

### 2.2 역할

- TON/WTON을 DepositManager를 통해 L2에 스테이킹
- 출금 요청 및 처리

### 2.3 V3 변경사항

**중요**: V3에서는 스테이커에게 시뇨리지가 제공되지 않습니다.

| 항목 | V2 | V3 |
|------|-----|-----|
| 시뇨리지 수령 | O | **X** |
| 스테이킹 목적 | 시뇨리지 수령 | 시퀀서/검증자 담보금 조건 |
| 출금 제한 | 없음 | 시퀀서/검증자는 최소 담보금 유지 필요 |

### 2.4 상호작용

```
┌────────────────────────────────────────────────────────────┐
│                        스테이커                             │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 스테이킹:                                            │   │
│  │   TON.approve(DepositManager, amount)                │   │
│  │   DepositManager.deposit(layer2, amount)             │   │
│  │                                                      │   │
│  │ 또는:                                                │   │
│  │   TON.approveAndCall(wton, amount, layer2)           │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 출금:                                                │   │
│  │   DepositManager.requestWithdrawal(layer2, amount)   │   │
│  │   (2주 대기)                                         │   │
│  │   DepositManager.processRequest(layer2)              │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

---

## 3. 시퀀서 (Sequencer)

### 3.1 정의

L2 롤업의 트랜잭션 순서를 결정하고 배치를 제출하는 운영자입니다.

### 3.2 역할

- L2 트랜잭션 순서 결정
- 배치 데이터를 L1에 제출
- Output Root 제출 (DisputeGame 생성)
- 기존 스테이킹 시스템(coinage)에 담보금 예치

### 3.3 보상

```
시퀀서 보상 = o_i = (1 - α) · S_i

여기서:
- S_i = L2 i의 시뇨리지 = y(x) · (B̃_i / x)
- α = 검증자 분배 비율 (예: 20%)
```

### 3.4 리스크

**Fraud 발생 시 담보금 전액 슬래싱**

```
시퀀서 담보금 = D_sequencer = H_max · C_max + Δ_sequencer

슬래싱 시:
- 챌린저 보상: C_max + Δ/n (각 챌린저에게)
- 나머지: DAO Treasury
```

### 3.5 자격 조건

```
T_i ≥ max(θ · B_i, H_max · C_max + Δ_sequencer)

여기서:
- T_i = 시퀀서 스테이킹 금액 (SeigManager.getSequencerStaked(layer2))
- θ · B_i = 시뇨리지 자격 조건 (백서 Rule 4)
- H_max · C_max + Δ_sequencer = Fraud Proof 비용 커버 (백서 Formula 1)

파라미터:
- θ = 최소 스테이킹 비율 (예: 10%)
- B_i = Bridged TON
- H_max = 최대 동시 챌린저 수
- C_max = 단일 Fraud Proof 최대 비용
- Δ_sequencer = 시퀀서 추가 보상
```

### 3.6 상호작용

```
┌────────────────────────────────────────────────────────────┐
│                         시퀀서                              │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 담보금 예치 (기존 스테이킹 사용):                     │   │
│  │   DepositManager.deposit(layer2, amount)             │   │
│  │   → SeigManager.getSequencerStaked(layer2)로 담보금 조회│   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 운영:                                                │   │
│  │   1. L2 트랜잭션 수집 및 순서 결정                    │   │
│  │   2. 배치 데이터 L1 제출                              │   │
│  │   3. Output Root 제출 (DisputeGameFactory.create)    │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 시뇨리지 분배 (V3):                                   │   │
│  │   SeigManager.updateSeigniorage() 호출 시            │   │
│  │   → 자격 조건 충족 시 (T_i ≥ max(θ·B_i, D_seq))      │   │
│  │   → 시퀀서 보상: o_i = (1-α) · S_i                   │   │
│  │   → WTON 민팅 → Layer2Manager → OperatorManager     │   │
│  │   ※ V3: 일반 스테이커 시뇨리지 없음                  │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 보상 수령:                                           │   │
│  │   OperatorManager.claimERC20(wton, amount)           │   │
│  │   → OperatorManager에 누적된 WTON 수령               │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 스테이킹 금액 출금:                                   │   │
│  │   DepositManager.requestWithdrawal(layer2, amount)   │   │
│  │   (2주 대기 후 processRequest)                       │   │
│  │   ※ 담보금(max(θ·B_i, D_seq)) 이하로 출금 불가       │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

---

## 4. 검증자 (Validator)

### 4.1 정의

L2 배치의 유효성을 검증하고 RAT에 응답하는 참여자입니다.

### 4.2 역할

- L2 배치 모니터링
- RAT (Randomized Attention Test) 응답
- Fraud 발견 시 챌린지 제기 (챌린저 역할 겸함)

### 4.3 보상

```
검증자 보상 = v_j = Σ_{i: j∈V_i} (α · S_i) / |V_i|

여기서:
- V_i = L2 i에 할당된 검증자 집합
- |V_i| = L2 i의 검증자 수
- α = 검증자 분배 비율 (예: 20%)
- S_i = L2 i의 시뇨리지
```

### 4.4 리스크

**RAT 미응답 시 C_off 페널티**

```
담보금 = D_validator = C_off + Δ_validator (coinage 기준)

페널티 조건:
- RAT 트리거 후 evidenceSubmissionPeriod 내 미응답
- 페널티 금액: C_off (coinage에서 RAT로 전송)

비활성화 조건 (relaxedValidatorCheck 플래그에 따라):
- relaxedValidatorCheck = true: 담보금 < C_off 시 즉시 비활성화 (완화)
- relaxedValidatorCheck = false: 담보금 < D_min 시 즉시 비활성화 (엄격)

페널티 처리:
- 선차감: coinage에서 C_off를 RAT 컨트랙트로 전송 (스테이킹 금액 감소)
- 복구: 증거 제출 시 RAT에서 검증자에게 C_off 반환 (스테이킹 금액 복구)
- 몰수: 미응답 시 RAT 컨트랙트의 C_off 몰수
```

### 4.5 담보금 및 등록 조건

```
최소 담보금 = D_min = C_off + Δ_validator

등록 요구사항:
- stakeOf(layer2, validator) >= D_min (등록 시 필수)

relaxedValidatorCheck 플래그:
- 등록 후 유효성 검사 및 비활성화 조건에만 적용
- true: C_off 기준으로 유효성 판단 (초기 단계, 완화)
- false: D_min 기준으로 유효성 판단 (엄격)

파라미터:
- C_off = 페널티 금액
- Δ_validator = 추가 버퍼
- relaxedValidatorCheck = 검증자 유효성 검사 완화 여부 (DAO 설정)
```

### 4.6 유효한 검증자 (Active Validator)

```
유효한 검증자 조건 (relaxedValidatorCheck 플래그에 따라):
- RAT에 등록됨 (isActive = true)
- relaxedValidatorCheck = true: stakeOf(layer2, validator) >= C_off (완화)
- relaxedValidatorCheck = false: stakeOf(layer2, validator) >= D_min (엄격)

상태 변경:
- 활성 → 비활성:
  · relaxedValidatorCheck = true: 담보금 < C_off 시 비활성화
  · relaxedValidatorCheck = false: 담보금 < D_min 시 비활성화
- 비활성 → 활성: 담보금 복구 후 조건 충족 시 자동 재활성화

검증자 수 제한:
- N_max = L2별 최대 검증자 수
- 검증자 보상: v_j = (α · S_i) / |V_i| (활성 검증자만 분배)
```

### 4.7 상호작용

```
┌────────────────────────────────────────────────────────────┐
│                         검증자                              │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 등록 (V3: 기존 스테이킹 사용):                        │   │
│  │                                                      │   │
│  │ 방법 1: 스테이킹 금액이 D_min 이상인 경우            │   │
│  │   RAT.registerValidator(systemConfig)                │   │
│  │   → stakeOf(layer2, validator) >= D_min 확인       │   │
│  │                                                      │   │
│  │ 방법 2: 스테이킹 금액이 부족한 경우                   │   │
│  │   TON.approveAndCall(RAT, amount, systemConfig)      │   │
│  │   → RAT가 DepositManager를 통해 스테이킹 예치        │   │
│  │   → RAT.registerValidator(systemConfig) 자동 실행   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ RAT 응답:                                            │   │
│  │   1. AttentionTestTriggered 이벤트 구독               │   │
│  │   2. 선택된 경우 배치 검증                            │   │
│  │   3. RAT.submitEvidence(systemConfig, batchIndex, .) │   │
│  │   (기간: evidenceSubmissionPeriod 내)                │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 보상 수령:                                           │   │
│  │   ValidatorReward.claimAllRewards()                  │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 탈퇴:                                                │   │
│  │   RAT.deactivateValidator(systemConfig)              │   │
│  │   (RAT 테스트 대기 중이면 마감 후)                   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

---

## 5. 챌린저 (Challenger)

### 5.1 정의

시퀀서의 잘못된 상태 루트에 대해 Fraud Proof를 제출하는 참여자입니다.

### 5.2 역할

- L2 상태 모니터링
- 잘못된 Output Root 발견 시 FaultDisputeGame에서 챌린지
- Fraud Proof 제출

### 5.3 보상

```
챌린저 보상 = C_max + Δ_sequencer / n

여기서:
- C_max = 최대 Fraud Proof 비용
- Δ_sequencer = 시퀀서 추가 담보금
- n = 챌린지 참여 챌린저 수
```

### 5.4 검증자 겸 챌린저

V3에서는 검증자가 챌린저 역할을 겸할 수 있습니다.

```
┌────────────────────────────────────────────────────────────┐
│                    검증자 겸 챌린저                          │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  Fraud 발견 시:                                             │
│  1. FaultDisputeGame에서 챌린지 제기                        │
│  2. 게임 승리 시:                                           │
│     - 챌린저 보상: C_max + Δ/n                              │
│     - RAT 담보금 복구: RAT.resolveClaim()                   │
│                                                             │
│  RAT 응답 방법 (둘 중 하나):                                 │
│  - submitEvidence: 직접 증거 제출                           │
│  - resolveClaim: 챌린지 승리 (fraud proof 성공)            │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

### 5.5 상호작용

```
┌────────────────────────────────────────────────────────────┐
│                         챌린저                              │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 챌린지:                                              │   │
│  │   1. 잘못된 Output Root 발견                          │   │
│  │   2. FaultDisputeGame.attack() 또는 defend()         │   │
│  │   3. Fraud Proof 제출                                 │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 승리 후:                                             │   │
│  │   누구나: SeigManager.slashSequencerByGame(game)     │   │
│  │   → 챌린저 보상 지급                                 │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

---

## 6. DAO

### 6.1 정의

Tokamak Network의 거버넌스 주체입니다 (DAOCommittee).

### 6.2 역할

- 시스템 파라미터 설정
- 컨트랙트 업그레이드
- V3 마이그레이션 실행
- 비상 조치 (일시정지 등)

### 6.3 보상

```
DAO 보상 = d · A + (L - y(x)) + Σ(검증자 없는 L2의 α·S_i)

여기서:
- d · A = 고정 분배 (SeigManagerV3_1에서 처리)
- L - y(x) = 미분배분 (SeigManagerV3_1에서 처리)
- α·S_i (|V_i|=0) = 검증자 없는 L2의 검증자 몫 (ValidatorRewardV1에서 처리)
```

#### 구현 세부사항

| 보상 출처 | 처리 컨트랙트 | 대상 주소 |
|-----------|---------------|-----------|
| 고정 분배 (d · A) | `SeigManagerV3_1._distributeV3Seigniorage()` | `SeigManager.dao` (daoVault) |
| 미분배분 (L - y(x)) | `SeigManagerV3_1._distributeV3Seigniorage()` | `SeigManager.dao` (daoVault) |
| 검증자 없는 L2 (α·S_i) | `ValidatorRewardV1.distributeL2Rewards()` | `SeigManager.dao` (daoVault) |

> **참고**: `SeigManager.dao`는 daoVault 주소를 저장합니다. ValidatorRewardV1은 `seigManager.dao()`를 호출하여 동일한 주소로 보상을 전송합니다.

### 6.4 권한

| 함수 | 설명 |
|------|------|
| `setDaoDistributionRatio(d)` | DAO 분배 비율 설정 |
| `setMinStakingRatio(θ)` | 최소 스테이킹 비율 설정 |
| `setValidatorDistributionRatio(α)` | 검증자 분배 비율 설정 |
| `setHalfSaturationPoint(k)` | 반포화점 설정 |
| `setSlashingPenalty(C_off)` | 슬래싱 페널티 설정 |
| `setRatTriggerProbability(π_a)` | RAT 트리거 확률 설정 |
| `setEvidenceSubmissionPeriod(period)` | 증거 제출 기간 설정 |
| `migrateToV3()` | V3 모드 활성화 |
| `pause()` / `unpause()` | 시스템 일시정지/재개 |

---

## 7. L2 프로포저 (L2 Proposer)

### 7.1 정의

L2의 상태(Output Root)를 L1에 제출하는 운영 주체입니다. 보통 시퀀서가 운영합니다.

### 7.2 역할

- Output Root 계산
- DisputeGameFactory.create() 호출
- RAT 트리거 (간접적)

### 7.3 상호작용

```
┌────────────────────────────────────────────────────────────┐
│                       L2 프로포저                           │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Output Root 제출:                                    │   │
│  │   1. L2 상태에서 Output Root 계산                     │   │
│  │   2. DisputeGameFactory.create(gameType, claim, .)   │   │
│  │   3. 내부적으로 RAT.triggerAttentionTest() 호출       │   │
│  │      (확률: π_a)                                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

---

## 8. 액터 관계도

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              액터 관계도                                          │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│                                ┌─────────────┐                                  │
│                                │     DAO     │                                  │
│                                │ (거버넌스)   │                                  │
│                                └──────┬──────┘                                  │
│                                       │                                          │
│              ┌────────────────────────┼────────────────────────┐                │
│              │ 파라미터 설정           │ 보상 수령              │                │
│              ▼                        ▼                        ▼                │
│  ┌──────────────────┐      ┌──────────────────┐      ┌──────────────────┐      │
│  │     시퀀서       │      │     검증자        │      │    스테이커       │      │
│  │                  │      │                  │      │                  │      │
│  │ 담보금: T_i      │      │ 담보금: D_valid  │      │ 스테이킹: -      │      │
│  │ 보상: (1-α)·S_i │      │ 보상: α·S_i/|V|  │      │ 보상: 없음 (V3)  │      │
│  │ 리스크: 전액슬래싱 │      │ 리스크: C_off    │      │ 리스크: 없음     │      │
│  └────────┬─────────┘      └────────┬─────────┘      └──────────────────┘      │
│           │                         │                                           │
│           │ 잘못된 배치              │ 챌린지 역할                               │
│           ▼                         ▼                                           │
│  ┌────────────────────────────────────────────────────────┐                     │
│  │                       챌린저                            │                     │
│  │                                                        │                     │
│  │  보상: C_max + Δ/n (Fraud Proof 성공 시)               │                     │
│  │  리스크: 가스비 손실                                    │                     │
│  └────────────────────────────────────────────────────────┘                     │
│                                                                                  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 9. 액터별 요구사항

### 9.1 기술적 요구사항

| 액터 | 노드 운영 | 24/7 가용성 | 자본 | 기술 역량 |
|------|----------|------------|------|----------|
| 스테이커 | X | X | TON | 낮음 |
| 시퀀서 | O (L2) | O | 높음 | 높음 |
| 검증자 | O (L2 모니터링) | O | 중간 | 중간 |
| 챌린저 | O (L2 검증) | X | 가스비 | 높음 |

### 9.2 경제적 요구사항

| 액터 | 최소 담보금 | 보상 예상 | ROI |
|------|------------|----------|-----|
| 시퀀서 | max(θ·B_i, H_max·C_max + Δ) | (1-α)·S_i | 변동 |
| 검증자 | C_off + Δ_val | α·S_i/\|V_i\| | 변동 |
| 챌린저 | 가스비 | C_max + Δ/n | 변동 |

---

## 10. 시퀀서 여정 가이드 (Sequencer Journey)

신규 시퀀서가 V3 시스템에 참여하는 전체 프로세스입니다.

### 10.1 신규 시퀀서 참여 플로우

**1단계: L2 등록**

```solidity
// Layer2Manager를 통해 L2 등록
Layer2Manager.registerLayer2(
    layer2Address,
    operatorManager,
    "L2 Name"
);

// 초기 담보금 예치 (minimumAmount 이상)
DepositManager.deposit(layer2, operator, initialAmount);
```

**2단계: V3 자격 확인**

```solidity
// 자격 조건 확인
(bool eligible, uint256 required, uint256 current) = 
    SeigManager.checkCurrentEligibility(layer2);

// required = max(θ × B_i, D_sequencer)
// θ = minStakingRatio
// B_i = getBridgedTonByLayer(layer2)
// D_sequencer = maxChallengers × maxFraudProofCost + sequencerAdditionalReward
```

**3단계: 자격 미달 시 추가 예치**

```
if (!eligible) {
    // 부족 금액 계산
    uint256 shortage = required - current;
    
    // 추가 예치
    DepositManager.deposit(layer2, operator, shortage);
    
    // onStakingChange() 자동 호출 → 자격 재평가
}
```

**4단계: 시뇨리지 받기**

```
// updateSeigniorage() 호출 (누구나)
SeigManager.updateSeigniorage();

// 자격 충족 시:
// - effectiveBridgedTON에 포함
// - 시뇨리지 자동 계산 및 분배
// - OperatorManager로 WTON 전송
```

### 10.2 자격 유지 및 모니터링

**모니터링 대상**:

1. **EligibilityChanged 이벤트**
   ```solidity
   event EligibilityChanged(
       address indexed layer2,
       bool eligible,
       uint256 requiredStake,
       uint256 currentStake
   );
   ```

2. **Bridged TON 증가 감지**
   - L2 사용자가 TON 브릿지 → B_i 증가
   - θ × B_i 증가 → 필요 담보금 증가
   - 자격 상실 가능

3. **파라미터 변경 감지**
   - DAO가 θ 증가 → 필요 담보금 증가
   - DAO가 D_sequencer 파라미터 변경

**자격 유지 전략**:

```
추천: T_i ≥ 1.2 × max(θ × B_i, D_sequencer)
     (20% 버퍼 유지)

이유:
- Bridged TON 급증에 대비
- 파라미터 변경에 대비
- 자격 상실 → 자동 청구 방지
```

### 10.3 자격 상실 및 복구

**자격 상실 원인**:

1. Bridged TON 증가 → θ × B_i 증가
2. 담보금 출금 → T_i 감소
3. 파라미터 변경 (θ 또는 D_sequencer 증가)

**자격 상실 시 자동 처리**:

```
1. onStakingChange() 호출
   ↓
2. checkAndUpdateEligibility() 감지
   ↓
3. 미청구 보상 자동 청구
   → _claimL2Seigniorage(layer2)
   → OperatorManager로 WTON 전송
   ↓
4. effectiveBridgedTON = 0
   ↓
5. 이벤트: AutoClaimBeforeEligibilityLoss
```

**복구 프로세스**:

```solidity
// 1. 담보금 추가 예치
DepositManager.deposit(layer2, operator, additionalAmount);

// 2. onStakingChange() 자동 호출됨

// 3. 자격 재획득 확인
(bool eligible, , ) = SeigManager.checkCurrentEligibility(layer2);
// eligible = true면 복구 완료

// 4. effectiveBridgedTON 복원
// 5. 새 보상부터 다시 받음
```

**중요**: 자격 상실 기간의 보상은 받지 못함 (미분배분으로 DAO에 귀속)

### 10.4 슬래싱 및 복구

**슬래싱 발생**:

```
1. 잘못된 Output Root 제출
   ↓
2. 챌린저가 Fraud Proof 제출
   ↓
3. DisputeGame 해결 (DEFENDER_WINS 아닌 상태)
   ↓
4. 누구나 slashSequencerByGame(gameAddress) 호출
   ↓
5. 전체 담보금 몰수 (coinage.burnFrom)
   - 챌린저 보상: C_max + Δ/n
   - 나머지: DAO Treasury
   ↓
6. 이벤트: SequencerSlashed
```

**복구 불가능**:
- 슬래싱 시 전체 담보금 손실
- L2 재등록 필요
- 신규 시퀀서로 처음부터 시작

---

## 11. 검증자 여정 가이드 (Validator Journey)

검증자가 V3 시스템에 참여하는 전체 프로세스입니다.

### 11.1 신규 검증자 참여 플로우

**1단계: 담보금 준비**

```solidity
// 필요 담보금 확인
uint256 dMin = RAT.getDynamicMinimumCollateral(systemConfig);

// 방법 1: 기존 스테이킹 사용 (충분한 경우)
uint256 currentStake = SeigManager.stakeOf(layer2, validator);
require(currentStake >= dMin, "Insufficient collateral");

// 방법 2: 추가 스테이킹 (부족한 경우)
DepositManager.deposit(layer2, validator, additionalAmount);
```

**2단계: 검증자 등록**

```solidity
// 등록
RAT.registerValidator(systemConfig);

// 자동 처리:
// - RAT에 등록
// - ValidatorReward에 등록 (registerValidatorToL2)
// - debt[validator][systemConfig] = rewardPerValidator[systemConfig]
// - isActive = true
```

**3단계: 보상 받기**

```
// 시뇨리지 분배 시 (updateSeigniorage 호출 시):
// - ValidatorReward.distributeL2Rewards(systemConfig, amount)
// - rewardPerValidator[systemConfig] 증가
// - earned = rewardPerValidator - debt

// 보상 청구:
ValidatorReward.claimAllRewards()
또는
ValidatorReward.claimRewardsByL2s([systemConfig1, systemConfig2, ...])
```

### 11.2 RAT 응답

**RAT 트리거**:

```
1. L2 프로포저가 DisputeGame 생성
   ↓
2. DisputeGameFactory → RAT.triggerAttentionTest()
   ↓
3. π_a 확률 체크 (랜덤)
   ↓
4. 검증자 랜덤 선택
   ↓
5. C_off 선차감 (coinage에서 RAT 컨트랙트로)
   - 담보금 < threshold → 검증자 자동 제거
```

**응답**:

```solidity
// evidenceSubmissionPeriod 내에 응답
RAT.submitEvidence(gameAddress);

// 성공 시:
// - C_off 반환 (RAT → validator coinage)
// - 담보금 복구
```

**미응답**:

```
// evidenceSubmissionPeriod 초과
// → C_off 몰수 (RAT 컨트랙트 보유)
// → 담보금 손실
```

### 11.3 검증자 탈퇴 및 재등록

**자발적 탈퇴**:

```solidity
// 탈퇴
RAT.deactivateValidator(systemConfig);

// 자동 처리:
// - ValidatorReward.syncValidatorReward() 호출
// - validatorPendingRewards[validator] += earned
// - isActive = false
// - validators 배열에서 제거
```

**자동 제거** (담보금 부족):

```
triggerAttentionTest() 시점:
- C_off 차감 후 remaining < threshold
  - threshold = relaxedValidatorCheck ? C_off : D_min
  
→ validators 배열에서 제거
→ isActive = false
```

**재등록**:

```solidity
// 1. 담보금 보충
DepositManager.deposit(layer2, validator, amount);

// 2. 재등록
RAT.registerValidator(systemConfig);

// 자동 처리:
// - ValidatorReward.resetValidatorDebt() 호출
// - debt = 현재 rewardPerValidator로 리셋
// - 기존 동기화된 보상만 청구 가능
// - 비활성화 기간 보상은 손실
```

**재등록 후 보상**:

```
기존 보상(동기화분): claimable
비활성화 기간 보상: 분배 대상 제외 (활성 검증자들이 나눠 받음)
재등록 후 새 보상: 다시 받음
```

### 11.4 최적화 팁

**1. 담보금 버퍼 유지**

```
추천: 실제 담보금 ≥ 1.5 × D_min

이유:
- RAT 선차감 대비 (C_off 차감)
- 검증자 수 증가 → D_min 증가 대비
- 자동 제거 방지
```

**2. 다중 L2 분산 전략**

```
// 여러 L2에 분산 등록 → 리스크 분산
RAT.registerValidator(systemConfig1);
RAT.registerValidator(systemConfig2);
RAT.registerValidator(systemConfig3);

// 보상 청구도 배치로
ValidatorReward.claimRewardsByL2s([config1, config2, config3]);
```

**3. RAT 모니터링**

```
// AttentionTestTriggered 이벤트 구독
event AttentionTestTriggered(
    address indexed gameAddress,
    address indexed validator,
    uint256 deadline
);

// 즉시 submitEvidence() 호출
// → C_off 반환 받음
```

---

## 12. 관련 문서

- [01-system-overview.md](./01-system-overview.md): 시스템 개요
- [02-system-architecture.md](./02-system-architecture.md): 시스템 아키텍처
- [03-contract-structure.md](./03-contract-structure.md): 컨트랙트 구조
- [04-contract-roles.md](./04-contract-roles.md): 컨트랙트별 역할
- [06-function-specs.md](./06-function-specs.md): 함수별 상세 설명
