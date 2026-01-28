---
id: 04-contract-roles
sidebar_position: 4
---
# TON Staking V3 컨트랙트별 역할

## 1. 컨트랙트 역할 개요

| 컨트랙트 | 주요 역할 | 핵심 책임 |
|---------|----------|----------|
| **SeigManager** | 시뇨리지 분배 | 시뇨리지 계산, 분배, 자격 관리, 시퀀서 슬래싱 |
| **DepositManager** | 스테이킹 관리 | TON/WTON 예치, 출금 처리 |
| **Layer2Manager** | L2 관리 | L2 등록, Bridged TON 조회 |
| **L1BridgeRegistry** | 브릿지 등록 | 브릿지/포탈 등록, TVL 조회 |
| **RAT** | 검증자 관리 | 검증자 등록, RAT 테스트, C_off 페널티 |
| **ValidatorReward** | 검증자 보상 | 보상 분배, 청구 처리 |

---

## 2. SeigManager

### 2.1 역할

TON Staking 시스템의 **핵심 컨트랙트**로, 시뇨리지(새로 발행되는 TON)의 계산과 분배를 담당합니다.

### 2.2 책임

| 책임 | 설명 |
|------|------|
| **시뇨리지 계산** | 블록당 시뇨리지 계산 |
| **V3 분배 로직** | 쌍곡선 함수, 자격 조건 적용 |
| **자격 관리** | L2별 자격(T_i ≥ θ·B_i) 확인/갱신 |
| **검증자 보상 분배** | ValidatorReward로 α·S_i 전송 |
| **DAO 분배** | d·A를 DAO Treasury로 전송 |
| **Coinage 관리** | 스테이킹 영수증 토큰 관리 |

### 2.3 상호작용

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          SeigManager 상호작용                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  입력:                                                                   │
│  ┌─────────────────┐                                                    │
│  │ DepositManager  │──► onDeposit(), onWithdraw(), onStakingChange()   │
│  │ OptimismPortal  │──► onBridgedTonChange() (Type 3)                  │
│  │ Anyone          │──► updateSeigniorage()                             │
│  └─────────────────┘                                                    │
│                                                                          │
│  조회:                                                                   │
│  ┌─────────────────┐                                                    │
│  │ L1BridgeRegistry│◄── layer2TVL()                                    │
│  │ Coinage        │◄── balanceOf(operator) (시퀀서/검증자 담보금)       │
│  │ Layer2Manager   │◄── getLayer2BySystemConfig()                      │
│  └─────────────────┘                                                    │
│                                                                          │
│  출력:                                                                   │
│  ┌─────────────────┐                                                    │
│  │ ValidatorReward │──► distributeL2Rewards()                          │
│  │ Layer2Manager   │──► transferL2Seigniorage()                        │
│  │ WTON            │──► mint() (시뇨리지 발행)                          │
│  └─────────────────┘                                                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.4 핵심 상태

- `v3Migrated`: V3 모드 활성화 여부
- `daoDistributionRatio` (d): DAO 분배 비율
- `minStakingRatio` (θ): 최소 스테이킹 비율
- `validatorDistributionRatio` (α): 검증자 분배 비율
- `halfSaturationPoint` (k): 반포화점
- `totalEffectiveBridgedTON` (x): 전체 유효 Bridged TON
- `bridgedTONInfo[layer2]`: L2별 Bridged TON 정보

---

## 3. DepositManager

### 3.1 역할

TON/WTON 스테이킹의 **입출금 게이트웨이** 역할을 합니다.

### 3.2 책임

| 책임 | 설명 |
|------|------|
| **WTON 스테이킹** | `deposit()` 함수 |
| **TON 스테이킹** | `onApprove()` 콜백 (approveAndCall) |
| **출금 요청** | `requestWithdrawal()` |
| **출금 처리** | `processRequest()` (2주 대기 후) |
| **스테이킹 알림** | SeigManager에 자격 재평가 요청 |

### 3.3 상호작용

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        DepositManager 상호작용                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  입력:                                                                   │
│  ┌─────────────────┐                                                    │
│  │ 스테이커        │──► deposit(), requestWithdrawal(), processRequest()│
│  │ WTON           │──► onApprove() (TON.approveAndCall 경유)           │
│  └─────────────────┘                                                    │
│                                                                          │
│  출력:                                                                   │
│  ┌─────────────────┐                                                    │
│  │ SeigManager    │──► onDeposit(), onWithdraw(), onStakingChange()    │
│  │ Coinage        │──► 스테이킹 영수증 토큰 관리                         │
│  └─────────────────┘                                                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.4 핵심 상태

- `_withdrawalRequests[layer2][account]`: 출금 요청 목록
- `globalWithdrawalDelay`: 전역 출금 지연 (블록 수)

> **스테이킹 금액 조회**: `SeigManager.stakeOf(layer2, account)` 사용

---

## 4. Layer2Manager

### 4.1 역할

L2 롤업의 **등록 및 관리**를 담당합니다.

### 4.2 책임

| 책임 | 설명 |
|------|------|
| **L2 등록** | Layer2/Operator/OperatorManager 등록 |
| **Bridged TON 조회** | L1BridgeRegistry를 통해 조회 |
| **SystemConfig 매핑** | SystemConfig ↔ Layer2 매핑 관리 |
| **시뇨리지 전송** | 시퀀서에게 시뇨리지 전달 |

### 4.3 상호작용

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Layer2Manager 상호작용                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  입력:                                                                   │
│  ┌─────────────────┐                                                    │
│  │ DAO/Admin      │──► registerLayer2(), setOperator()                 │
│  │ SeigManager    │──► transferL2Seigniorage()                         │
│  └─────────────────┘                                                    │
│                                                                          │
│  조회:                                                                   │
│  ┌─────────────────┐                                                    │
│  │ L1BridgeRegistry│◄── layer2TVL()                                    │
│  └─────────────────┘                                                    │
│                                                                          │
│  출력:                                                                   │
│  ┌─────────────────┐                                                    │
│  │ OperatorManager│──► 시뇨리지 WTON 전송                               │
│  └─────────────────┘                                                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.4 핵심 상태

- `layerInfo[layer2]`: L2별 정보 (operator, 상태 등)
- `operatorInfo[operator]`: 오퍼레이터 정보
- `rollupConfigInfo[systemConfig]`: SystemConfig별 정보

---

## 5. L1BridgeRegistry

### 5.1 역할

L1 브릿지/포탈의 **등록 및 TVL 조회**를 담당합니다. V1_2는 V1_1의 모든 함수를 포함합니다.

### 5.2 책임

| 책임 | 설명 |
|------|------|
| **브릿지 등록** | L1StandardBridge, OptimismPortal, DisputeGameFactory 등록 |
| **롤업 타입 관리** | Type 1/2/3 구분, TYPE 1/2 → 3 업그레이드 |
| **TVL 조회** | L2별 Bridged TON 잔액 조회 |
| **포탈 역조회** | Portal → rollupConfig 매핑 |
| **시뇨리지 관리** | 롤업별 시뇨리지 발행 중지/복원 |
| **타입별 권한 관리** | typeRegistrant[n]으로 위임 등록 |

### 5.3 상호작용

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      L1BridgeRegistry 상호작용                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  입력:                                                                   │
│  ┌─────────────────┐                                                    │
│  │ Owner          │──► setAddresses(), setSeigniorageCommittee()       │
│  │ Manager        │──► registerRollupConfigByManager(), upgradeToType3()│
│  │ SeigniorageCmt │──► rejectCandidateAddOn(), restoreCandidateAddOn()  │
│  │ Registrant     │──► registerRollupConfig()                           │
│  │ typeRegistrant │──► registerRollupConfigByType()                     │
│  └─────────────────┘                                                    │
│                                                                          │
│  조회 제공:                                                              │
│  ┌─────────────────┐                                                    │
│  │ SeigManager    │◄── layer2TVL(), rollupType()                       │
│  │ Layer2Manager  │◄── layer2TVL()                                     │
│  │ RAT            │◄── rollupConfigWithDisputeGameFactory()            │
│  └─────────────────┘                                                    │
│                                                                          │
│  TVL 조회 방식: TON.balanceOf(address)                                  │
│  ┌─────────────────┐                                                    │
│  │ L1StandardBridge│◄── TON.balanceOf(bridge) (Type 1)                 │
│  │ OptimismPortal │◄── TON.balanceOf(portal) (Type 2, 3)               │
│  └─────────────────┘                                                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 5.4 핵심 상태

**V1 스토리지**:
- `rollupInfo[rollupConfig]`: 롤업 정보 (type, l2TON, rejectedSeigs 등)
- `l1Bridge[bridge]`: L1StandardBridge 등록 여부
- `portal[portal]`: OptimismPortal 등록 여부

**V1_2 스토리지**:
- `disputeGameFactory[rollupConfig]`: DisputeGameFactory 등록 여부
- `rollupConfigWithDisputeGameFactory[factory]`: Factory → rollupConfig 역매핑
- `rollupConfigWithPortal[portal]`: Portal → rollupConfig 역매핑
- `typeRegistrant[type]`: 타입별 등록 권한자

---

## 6. RAT (Randomized Attention Test)

### 6.1 역할

검증자의 **등록, RAT 테스트, C_off 페널티**를 관리합니다.

### 6.2 책임

| 책임 | 설명 |
|------|------|
| **검증자 등록** | L2별 검증자 등록 및 담보금 관리 |
| **RAT 트리거** | DisputeGame 생성 시 확률적 트리거 |
| **증거 검증** | 검증자 증거 제출 처리 |
| **담보금 복구** | 증거 제출/챌린지 승리 시 복구 |
| **C_off 페널티** | 미응답 시 C_off 몰수 |
| **검증자 조회** | ValidatorReward에 검증자 정보 제공 |

### 6.3 상호작용

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            RAT 상호작용                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  입력:                                                                   │
│  ┌───────────────────────┐                                              │
│  │ 검증자               │──► registerValidator(), submitEvidence()     │
│  │                      │──► deactivateValidator(), addDeposit()       │
│  │ DisputeGameFactory   │──► triggerAttentionTest()                    │
│  │ FaultDisputeGame     │──► resolveClaim() (챌린지 승리 시)           │
│  │ WTON                 │──► onApprove() (approveAndCall 등록)         │
│  └───────────────────────┘                                              │
│                                                                          │
│  조회 제공:                                                              │
│  ┌─────────────────┐                                                    │
│  │ ValidatorReward│◄── getL2Validators(), isValidatorActive()         │
│  │               │◄── getActiveValidatorCount()                        │
│  └─────────────────┘                                                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 6.4 핵심 상태

- `validatorRegistrations[systemConfig][validator]`: 검증자 등록 정보
- `validatorPools[systemConfig]`: L2별 검증자 풀
- `attentionTests[testId]`: RAT 테스트 정보
- `slashingPenalty` (C_off): 슬래싱 페널티
- `minimumThreshold` (D_min): 최소 담보금 임계값
- `ratTriggerProbability` (π_a): RAT 트리거 확률
- `evidenceSubmissionPeriod`: 증거 제출 기간

---

## 7. ValidatorReward

### 7.1 역할

검증자 **보상 분배 및 청구**를 전담합니다.

### 7.2 책임

| 책임 | 설명 |
|------|------|
| **L2별 보상 분배** | SeigManager로부터 α·S_i 수령 후 분배 |
| **균등 분배** | 활성 검증자에게 균등 분배 |
| **Treasury 귀속** | 검증자 없을 때 DAO Treasury로 전송 |
| **보상 청구** | 검증자의 보상 청구 처리 |
| **Per-L2 추적** | L2별 보상 내역 추적 |

### 7.3 상호작용

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       ValidatorReward 상호작용                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  입력:                                                                   │
│  ┌─────────────────┐                                                    │
│  │ SeigManager    │──► distributeL2Rewards(systemConfig, amount)       │
│  │ 검증자          │──► claimAllRewards()                               │
│  └─────────────────┘                                                    │
│                                                                          │
│  조회:                                                                   │
│  ┌─────────────────┐                                                    │
│  │ RAT            │◄── getL2Validators(), isValidatorActive()         │
│  └─────────────────┘                                                    │
│                                                                          │
│  출력:                                                                   │
│  ┌─────────────────┐                                                    │
│  │ 검증자          │──► WTON 보상 전송                                  │
│  │ DAO Treasury   │──► 검증자 없을 때 WTON 전송                         │
│  └─────────────────┘                                                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 7.4 핵심 상태

- `validatorPendingRewards[validator]`: 총 미청구 보상
- `validatorL2PendingRewards[validator][systemConfig]`: L2별 미청구 보상

---

## 8. 역할 요약 다이어그램

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              역할 분담 요약                                       │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│  시뇨리지 흐름:                                                                   │
│  ┌──────────┐    계산/분배    ┌──────────────┐    시퀀서 몫    ┌──────────────┐ │
│  │ WTON.mint│──────────────►│ SeigManager  │──────────────►│ Layer2Manager │ │
│  └──────────┘               │              │               └──────────────┘ │
│                             │              │                                  │
│                             │              │    검증자 몫   ┌───────────────┐ │
│                             │              │──────────────►│ValidatorReward│ │
│                             └──────────────┘               └───────────────┘ │
│                                                                                  │
│  스테이킹 흐름:                                                                   │
│  ┌──────────┐     예치      ┌───────────────┐    알림     ┌──────────────┐    │
│  │ 스테이커  │─────────────►│DepositManager │────────────►│ SeigManager  │    │
│  └──────────┘              └───────────────┘             └──────────────┘    │
│                                                                                  │
│  검증자 흐름 (V3: 기존 스테이킹 사용):                                             │
│  ┌──────────┐    스테이킹   ┌───────────────┐                                    │
│  │ 검증자    │─────────────►│DepositManager │                                    │
│  └─────┬────┘              └───────────────┘                                    │
│        │ 등록                    (담보금)                                         │
│        ▼                                                                         │
│  ┌───────────────┐   정보제공   ┌───────────────┐                               │
│  │     RAT       │────────────►│ValidatorReward│                               │
│  └───────────────┘             └───────────────┘                               │
│                                                                                  │
│  시퀀서 흐름 (V3: 기존 스테이킹 사용):                                             │
│  ┌──────────┐    스테이킹   ┌───────────────┐   담보금조회  ┌──────────────┐  │
│  │ 시퀀서    │─────────────►│DepositManager │────────────►│ SeigManager  │  │
│  └──────────┘              └───────────────┘  (coinage)   └──────────────┘  │
│                                                                                  │
│  Bridged TON 흐름:                                                              │
│  ┌──────────────┐   알림    ┌──────────────┐    조회     ┌─────────────────┐ │
│  │OptimismPortal│─────────►│ SeigManager  │◄───────────│ L1BridgeRegistry│ │
│  └──────────────┘          └──────────────┘            └─────────────────┘ │
│                                                                                  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 9. 관련 문서

- [01-system-overview.md](./01-system-overview.md): 시스템 개요
- [02-system-architecture.md](./02-system-architecture.md): 시스템 아키텍처
- [03-contract-structure.md](./03-contract-structure.md): 컨트랙트 구조
- [05-actors.md](./05-actors.md): 액터 정의
- [06-function-specs.md](./06-function-specs.md): 함수별 상세 설명
