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
│  │ 1. 먼저 DepositManager를 통해 충분한 TON 스테이킹   │   │
│  │    DepositManager.deposit(layer2, amount)            │   │
│  │    → D_min 이상 예치 필요                           │   │
│  │                                                      │   │
│  │ 2. 검증자로 등록                                     │   │
│  │    RAT.registerValidator(systemConfig)               │   │
│  │    → stakeOf(layer2, validator) >= D_min 확인       │   │
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

### 5.3 담보금 (Bond)

Optimism Fault Dispute Game에서 챌린저는 챌린지를 시작할 때 담보금(bond)을 제출해야 합니다:

```
챌린지 참여 시:
- Bond 예치 (FaultDisputeGame에 ETH/TON)
- 가스비 지불

챌린지 성공 시:
- 자신의 Bond 반환
- 프로포저(시퀀서)의 Bond 획득
- 챌린저 보상 수령 (C_max + Δ/n from SeigManager)

챌린지 실패 시:
- Bond 몰수 (프로포저에게 전달)
- 가스비 손실
```

### 5.4 보상

```
챌린저 총 보상 = 자신의 Bond 반환 + 프로포저 Bond + (C_max + Δ_sequencer / n)

여기서:
- 자신의 Bond: DisputeGame에서 반환
- 프로포저 Bond: DisputeGame에서 획득
- C_max + Δ/n: SeigManager에서 지급 (시퀀서 담보금에서 차감)
- n = 챌린지 참여 챌린저 수
```

### 5.5 검증자 겸 챌린저

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

### 5.6 상호작용

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
- **RAT 몰수 담보금 회수 및 DAO 이름으로 스테이킹** (V3 신규)

### 6.3 보상

```
DAO 보상 = d · A + (L - y(x)) + Σ(검증자 없는 L2의 α·S_i) + RAT 몰수 담보금
           ───────────────────────────────────────────────────────   ─────────────────
           시뇨리지 기반 보상                                         페널티 기반 수입

여기서:
- d · A = 고정 분배 (SeigManagerV3_1에서 처리)
- L - y(x) = 미분배분 (SeigManagerV3_1에서 처리)
- α·S_i (|V_i|=0) = 검증자 없는 L2의 검증자 몫 (ValidatorRewardV1에서 처리)
- RAT 몰수 담보금 = 검증자 미응답 시 몰수된 C_off (RAT에서 회수)
  * 출처: 검증자의 스테이킹 담보금 (시뇨리지와 무관한 페널티)
  * 상세 프로세스는 섹션 6.4 참조
```

#### 구현 세부사항

| 보상 출처 | 처리 컨트랙트 | 대상 주소 | 청구 방법 | 출처 유형 |
|-----------|---------------|-----------|----------|----------|
| 고정 분배 (d · A) | `SeigManagerV3_1._distributeV3Seigniorage()` | `SeigManager.dao` (daoVault) | 자동 전송 | 시뇨리지 (신규 발행) |
| 미분배분 (L - y(x)) | `SeigManagerV3_1._distributeV3Seigniorage()` | `SeigManager.dao` (daoVault) | 자동 전송 | 시뇨리지 (신규 발행) |
| 검증자 없는 L2 (α·S_i) | `ValidatorRewardV1.distributeL2Rewards()` | `SeigManager.dao` (daoVault) | 자동 전송 | 시뇨리지 (신규 발행) |
| RAT 몰수 담보금 | `RAT.withdrawSlashingsToTreasury()` | RAT.treasury | 수동 호출 필요 | **검증자 스테이킹 (페널티)** |

> **참고**: 
> - `SeigManager.dao`는 daoVault 주소를 저장합니다.
> - **RAT 몰수 담보금은 시뇨리지가 아닌 검증자의 기존 스테이킹 담보금(coinage)에서 차감된 페널티입니다.** 상세 프로세스는 섹션 6.4 참조.

### 6.4 RAT 몰수 담보금 회수 (V3 신규)

검증자가 RAT에 응답하지 않으면 담보금(C_off)이 먼저 RAT 컨트랙트 명의로 스테이킹 이전됩니다. 챌린지 기간이 경과하여 완전 몰수가 확정되면, DAO가 이를 Treasury 명의로 회수할 수 있습니다.

**중요**: RAT 몰수 담보금은 **시뇨리지(신규 발행)가 아니라 검증자의 기존 스테이킹 담보금에서 차감된 페널티**입니다.

#### 3단계 프로세스

**1단계: 선차감 (RAT 트리거 시)**
```
triggerAttentionTest() 호출 시 자동 처리:
- 검증자 명의 coinage에서 C_off 차감
- RAT 컨트랙트 명의 coinage로 이전
```

**2단계: 복구 또는 유지 (챌린지 기간)**
```
검증자 응답 시:
- submitEvidence() 성공 → RAT 명의 → 검증자 명의로 반환
- 미응답 → RAT 명의로 유지 (챌린지 기간 동안)
```

**3단계: DAO 회수 (완전 몰수 확정 후)**
```solidity
// DAO가 수동 호출
RAT.withdrawSlashingsToTreasury(systemConfig);

// 호출 조건:
// - latestDeadlineTest + challengeGameDuration + safetyBuffer 경과
// - RAT 컨트랙트 명의로 스테이킹된 해당 L2 coinage 잔액 > 0

// 처리 결과:
// - RAT 명의 coinage → Treasury 명의 coinage로 이전
// - Treasury는 해당 L2의 스테이킹 지분 획득
// - 향후 시뇨리지 분배 시 Treasury도 보상 수령 가능
// - DAO는 DepositManager.requestWithdrawal()로 언스테이킹 가능
```

#### 타이밍 및 효과

| 단계 | 시점 | 상태 | 복구 가능 여부 |
|------|------|------|---------------|
| 선차감 | RAT 트리거 시 즉시 | 검증자 → RAT 명의 | ✅ 가능 (증거 제출 또는 Fraud Proof) |
| 챌린지 기간 | `latestDeadlineTest` ~ `+ challengeGameDuration` | RAT 명의로 유지 | ✅ 가능 |
| DAO 회수 가능 | `+ challengeGameDuration + safetyBuffer` 경과 후 | RAT → Treasury 명의 | ❌ 불가능 (완전 몰수) |

**최종 효과**:
- Treasury는 해당 L2의 스테이킹 지분 보유 → 시뇨리지 수령 가능
- DAO는 추가적인 수입원 확보
- 원하는 시점에 `DepositManager.requestWithdrawal()` 및 `processRequest()`로 TON/WTON 인출 가능

### 6.5 권한

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
| `withdrawSlashingsToTreasury(systemConfig)` | RAT 몰수 담보금 회수 |

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
| 챌린저 | Bond (DisputeGame) + 가스비 | 자신의 Bond + 프로포저 Bond + C_max + Δ/n | 변동 |

---

## 10. 시퀀서 여정 가이드 (Sequencer Journey)

신규 시퀀서가 V3 시스템에 참여하는 전체 프로세스입니다.

### 10.1 신규 시퀀서 참여 플로우

**1단계: L2 및 시퀀서 등록**

```solidity
// 1. L1BridgeRegistry를 통해 L2 등록
L1BridgeRegistry.registerRollupConfig(
    systemConfig,  // rollupConfig 주소
    type,          // 1=TOKAMAK, 2=BEDROCK, 3=BEDROCK_WITH_DISPUTE_GAME
    l2TON,         // L2 TON 주소
    "L2 Name"
);

// 2. Layer2Manager를 통해 CandidateAddOn(시퀀서) 등록 및 초기 담보금 예치
// 방법 A: TON으로 예치
Layer2Manager.registerCandidateAddOn(
    systemConfig,
    initialAmount,  // TON 단위 (minimumInitialDepositAmount 이상)
    true,           // flagTon = true
    "memo"
);

// 방법 B: WTON으로 예치
Layer2Manager.registerCandidateAddOn(
    systemConfig,
    initialAmount,  // WTON 단위 (RAY)
    false,          // flagTon = false
    "memo"
);

// 또는 TON.approveAndCall 사용
TON.approveAndCall(
    Layer2Manager,
    initialAmount,
    abi.encode(systemConfig, "memo")
);
```

**2단계: V3 자격 확인**

자격 확인은 두 가지 방법으로 가능합니다:

**방법 A: 함수 직접 호출 (view 함수)**
```solidity
// 현재 자격 상태 조회
(bool eligible, uint256 required, uint256 current) = 
    SeigManager.checkCurrentEligibility(layer2);

// eligible: 현재 자격 여부
// required: 필요한 담보금 = max(θ × B_i, D_sequencer)
// current: 현재 스테이킹 금액
```

**방법 B: 이벤트 모니터링 (권장)**
```solidity
// EligibilityChanged 이벤트 구독
event EligibilityChanged(
    address indexed layer2,
    bool eligible,
    uint256 bridgedTON,
    uint256 effectiveBridgedTON
);

// 발생 시점:
// - onBridgedTonChange() 시 (TYPE 3)
// - onDeposit() / onWithdraw() 시
// - updateSeigniorage() 시
```

**3단계: 시뇨리지 자격 미달 시 추가 예치 (선택)**

V3에서는 자격 조건을 만족해야 시뇨리지를 받습니다:
- `T_i ≥ max(θ·B_i, D_sequencer)`
- 초기 등록 시 `minimumInitialDepositAmount`만으로는 자격 부족 가능
- 특히 Bridged TON(B_i)이 증가하면 필요 담보금도 증가

```solidity
if (!eligible) {
    // 부족 금액 계산
    uint256 shortage = required - current;
    
    // 추가 예치하여 자격 회복
    DepositManager.deposit(layer2, shortage);
    
    // onDeposit() 자동 호출 → 자격 재평가
    // 또는 다음 updateSeigniorage() 시 자격 체크
}
```

**참고**: 자격 미달 상태에서도:
- L2는 정상 운영됨 (블록 생산 가능)
- 시뇨리지만 받지 못함 (`effectiveBridgedTON = 0`)

**4단계: 시뇨리지 받기**

시뇨리지는 두 단계로 분배됩니다:

```solidity
// 1단계: SeigManager에서 OperatorManager로 자동 전송
//        (누구나 updateSeigniorage() 호출 가능)
SeigManager.updateSeigniorage();
// ↓
// Layer2Manager.transferL2Seigniorage() 호출
// ↓
// OperatorManager에 WTON 전송

// 2단계: OperatorManager에서 시퀀서로 클레임
//        (owner 또는 manager만 호출 가능)
OperatorManager.claimERC20(WTON_ADDRESS, amount);
// ↓
// manager 주소로 WTON 전송
```

**참고**:
- `updateSeigniorage()`는 누구나 호출 가능 (permissionless)
- `claimERC20()`는 OperatorManager의 owner 또는 manager만 호출 가능
- 시뇨리지는 OperatorManager에 누적되므로 원하는 시점에 인출 가능
- 자격 미달 시 시뇨리지 미지급 (`effectiveBridgedTON = 0`)

---

### 10.2 슬래싱 및 복구

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
// 1. 탈퇴 호출
RAT.deactivateValidator(systemConfig);

// 2. 자동 처리:
//    - ValidatorReward.syncValidatorReward() 호출
//    - 미청구 보상을 validatorPendingRewards에 동기화
//    - isActive = false 설정
//    - validators 배열에서 제거

// 3. 탈퇴 후에도 보상 클레임 가능
ValidatorReward.claimAllRewards();
// 또는
ValidatorReward.claimRewardsByL2s([systemConfig]);
```

**자동 제거** (담보금 부족):

```
triggerAttentionTest() 시점에서 자동 제거:
- C_off 차감 후 remaining < threshold
  - threshold = relaxedValidatorCheck ? C_off : D_min
  
→ validators 배열에서 제거
→ isActive = false
→ 탈퇴 전까지의 보상은 동기화되어 청구 가능
```

**재등록 및 보상 로직**:

```solidity
// 1. 담보금 보충 (D_min 이상)
DepositManager.deposit(layer2, amount);

// 2. 재등록
RAT.registerValidator(systemConfig);

// 3. 자동 처리:
//    - ValidatorReward.resetValidatorDebt() 호출
//    - 새로운 debt 설정 (현재 rewardPerValidator)
//    - 재등록 전 동기화된 보상은 여전히 청구 가능

// 4. 보상 청구
ValidatorReward.claimAllRewards();
//    → 모든 L2의 보상 동기화 후 한번에 청구
//    → validatorPendingRewards에 누적된 모든 보상 전송
```

**보상 타이밍 정리**:

| 기간 | 보상 수령 여부 | 청구 방법 |
|------|---------------|----------|
| 활성화 기간 | ✅ 수령 | 탈퇴/재등록 시 자동 동기화 |
| 비활성화 기간 | ❌ 손실 | 다른 활성 검증자들이 나눠 받음 |
| 재등록 후 | ✅ 수령 | 새 보상 누적 시작 |

**보상 청구 방법**:

```solidity
// 방법 1: 모든 L2 보상 한번에 청구
ValidatorReward.claimAllRewards();
// → 모든 등록된 L2의 보상 자동 동기화
// → validatorPendingRewards에 누적된 모든 보상 일괄 전송
// ⚠️ 주의: 등록된 L2가 많으면 가스비 높을 수 있음

// 방법 2: 특정 L2들만 선택해서 청구 (가스비 절약)
ValidatorReward.claimRewardsByL2s([systemConfig1, systemConfig2, systemConfig3]);
// → 지정된 L2들의 보상만 동기화
// → validatorPendingRewards에 누적된 보상 전송
// ✅ 권장: L2가 많을 경우 배치로 나눠서 청구
```

**가스비 최적화 전략**:
```solidity
// 예시: 20개 L2 중 10개씩 나눠서 청구
ValidatorReward.claimRewardsByL2s(l2Array.slice(0, 10));
// ... 이후
ValidatorReward.claimRewardsByL2s(l2Array.slice(10, 20));
```

---

## 12. 관련 문서

- [01-system-overview.md](./01-system-overview.md): 시스템 개요
- [02-system-architecture.md](./02-system-architecture.md): 시스템 아키텍처
- [03-contract-structure.md](./03-contract-structure.md): 컨트랙트 구조
- [04-contract-roles.md](./04-contract-roles.md): 컨트랙트별 역할
- [06-function-specs.md](./06-function-specs.md): 함수별 상세 설명
