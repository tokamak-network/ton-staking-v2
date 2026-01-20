# Slashing 테스트 vs RAT 테스트 비교 분석

> **분석 모델**: Claude Sonnet 4 (Anthropic)  
> **분석 일자**: 2026-01-20  
> **분석 대상**: `/op-e2e/slashing/` 및 `/op-e2e/faultproofs/` 디렉토리

---

## 1. 개요

이 문서는 TON Staking V2 프로젝트의 E2E 테스트 중 **Slashing 테스트**와 **RAT(Random Attention Test) 테스트**의 차이점을 분석합니다.

### 분석 대상 파일

| 카테고리 | 파일 경로 |
|----------|-----------|
| **Slashing 테스트** | `op-e2e/slashing/slashing_test.go` |
| **Slashing 헬퍼** | `op-e2e/slashing/slashing_helpers.go` |
| **Slashing용 RAT 헬퍼** | `op-e2e/slashing/rat_challenge_helpers.go` |
| **RAT 테스트** | `op-e2e/faultproofs/rat_challenge_test.go` |
| **RAT 시스템 테스트** | `op-e2e/faultproofs/rat_system_test.go` |
| **RAT 헬퍼** | `op-e2e/faultproofs/rat_challenge_helpers.go` |
| **공용 RAT 헬퍼** | `op-e2e/e2eutils/rat/helpers.go` |
| **공용 RAT 시스템** | `op-e2e/e2eutils/rat/system.go` |

---

## 2. 아키텍처 비교

### 2.1 Slashing 테스트 아키텍처

```
┌─────────────────────────────────────────────────────────────────┐
│                     Slashing Test Flow                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    ┌─────────────────┐    ┌───────────────┐  │
│  │ TON Staking  │───>│ Layer2Manager   │───>│ CandidateAddOn│  │
│  │   System     │    │ (Slashing)      │    │ Registration  │  │
│  └──────────────┘    └─────────────────┘    └───────────────┘  │
│         │                    │                      │          │
│         v                    v                      v          │
│  ┌──────────────┐    ┌─────────────────┐    ┌───────────────┐  │
│  │ RAT Contract │───>│ DisputeGame     │───>│ Slashing      │  │
│  │ Integration  │    │ (Wrong Claim)   │    │ Execution     │  │
│  └──────────────┘    └─────────────────┘    └───────────────┘  │
│                                                     │          │
│                              ┌───────────────────────┘          │
│                              v                                  │
│                     ┌─────────────────┐                        │
│                     │ Reward (10%)    │                        │
│                     │ + Burn (90%)    │                        │
│                     └─────────────────┘                        │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 RAT 테스트 아키텍처

```
┌─────────────────────────────────────────────────────────────────┐
│                        RAT Test Flow                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    ┌─────────────────┐    ┌───────────────┐  │
│  │ TON Staking  │───>│ RAT Contract    │───>│ Validator     │  │
│  │   System     │    │                 │    │ Registration  │  │
│  └──────────────┘    └─────────────────┘    └───────────────┘  │
│         │                    │                      │          │
│         v                    v                      v          │
│  ┌──────────────┐    ┌─────────────────┐    ┌───────────────┐  │
│  │ DisputeGame  │───>│ RAT Trigger     │───>│ Evidence      │  │
│  │ Factory      │    │ (Probabilistic) │    │ Submission    │  │
│  └──────────────┘    └─────────────────┘    └───────────────┘  │
│                              │                      │          │
│         ┌────────────────────┴──────────────────────┘          │
│         v                                                       │
│  ┌──────────────┐    ┌─────────────────┐    ┌───────────────┐  │
│  │ Game Clock   │───>│ Claim Resolution│───>│ Bond Credit   │  │
│  │ Expiration   │    │                 │    │ Claim         │  │
│  └──────────────┘    └─────────────────┘    └───────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. 핵심 차이점

### 3.1 테스트 목적

| 구분 | Slashing 테스트 | RAT 테스트 |
|------|-----------------|------------|
| **주요 목적** | 악의적 오퍼레이터의 스테이크 몰수 | Validator의 주의력 검증 및 게임 이론 검증 |
| **검증 대상** | Slashing 메커니즘 전체 흐름 | RAT 트리거, Evidence 제출, 게임 해결 |
| **경제적 결과** | 10% 보상 + 90% 소각 | Bond 반환/몰수 및 Credit 시스템 |

### 3.2 사용 컨트랙트

#### Slashing 테스트에서 사용하는 컨트랙트

```go
type SlashingContracts struct {
    Layer2ManagerSlashing  *bindings.Layer2ManagerSlashing  // Slashing 전용
    DepositManagerSlashing *bindings.DepositManagerSlashing // Slashing 전용
    SeigManagerSlashing    *bindings.SeigManagerSlashing    // Slashing 전용
    DepositManager         *bindings.DepositManager
    Layer2ManagerV11       *bindings.Layer2ManagerV11
}
```

#### RAT 테스트에서 사용하는 컨트랙트

```go
type TestContracts struct {
    RAT *bindings.RAT
    TON *bindings.ERC20
}
// 추가로 FaultDisputeGame, DisputeGameFactory, DelayedWETH 사용
```

### 3.3 등록 방식 비교

#### Slashing: CandidateAddOn 등록

```go
// Layer2Manager를 통한 CandidateAddOn 등록
tx, err := contracts.Layer2ManagerV11.RegisterCandidateAddOn(
    operatorAuth,
    rollupConfig,      // SystemConfig 또는 MockSystemConfig
    stakeAmount,       // 스테이크 금액 (TON)
    flagTon,           // true = TON 사용, false = WTON 사용
    memo,              // 설명
)
// 결과: CandidateAddOn 주소, OperatorManager 주소 생성
```

- 예치금: **1,000,000 TON** (테스트 기준)
- 등록 경로: `TON Approve → Layer2Manager.RegisterCandidateAddOn → DepositManager.Deposit`

#### RAT: Validator 등록

```go
// RAT 컨트랙트에 직접 Validator 등록
registerTx, err := contracts.RAT.RegisterValidator(
    validatorAuth, 
    sys.Addresses.SystemConfig,  // 롤업 설정
    depositAmount,               // 담보금
)
```

- 예치금: **50,000 TON** (테스트 기준)
- 등록 경로: `TON Approve → RAT.RegisterValidator`

### 3.4 DisputeGame 생성 및 처리

#### 공통점

```go
// 두 테스트 모두 동일한 방식으로 DisputeGame 생성
rootClaim := [32]byte{0x01, 0x02, 0x03}  // 또는 잘못된 claim
gameReceipt, gameAddress := rat.CreateDisputeGame(t, sys, accounts.Proposer.Auth, rootClaim)
```

#### Slashing 테스트의 후속 처리

```go
// 1. RAT 트리거 확인
testID, ratTriggered := rat.ParseRATTriggerEvent(t, gameReceipt, accounts.Validator.Addr)

// 2. Challenger가 공격
rat.AttackClaim(t, sys, accounts.Challenger.Auth, gameAddress, correctRootClaim, rootClaim)

// 3. 시간 경과 후 게임 해결
rat.AdvanceTimeAndMine(t, sys, 1209600) // 14일
rat.ResolveGame(t, sys, accounts.Challenger.Auth, gameAddress)

// 4. Slashing 실행 (핵심 차이점!)
executeSlashing(t, sys, slashingContracts, accounts.Challenger.Auth, 
    operatorManager, gameAddress, rootClaim, extraData)
```

#### RAT 테스트의 후속 처리

```go
// 1. RAT 트리거 확인
testID, batchIndex, ratTriggered := parseRATTriggerEventWithBatchIndex(t, gameReceipt, accounts.Validator.Addr)

// 2. Evidence 제출 (RAT 특화)
evidenceTx, err := contracts.RAT.SubmitEvidence(
    accounts.Validator.Auth, 
    sys.Addresses.SystemConfig, 
    batchIndex, 
    evidence,
)

// 3. 게임 해결 후 Bond 복원
resolveRATTx, err := contracts.RAT.ResolveClaim(accounts.Validator.Auth, gameAddress)

// 4. Credit 청구 (2단계 프로세스)
game.ClaimCredit(...)  // 1차: 언락
// 시간 경과 (DelayedWETH delay)
game.ClaimCredit(...)  // 2차: 실제 전송
```

### 3.5 경제적 결과 비교

#### Slashing 결과

| 항목 | 값 | 설명 |
|------|-----|------|
| Challenger 보상 | 10% | `SlashingRewardRate` 기반 |
| 소각량 | 90% | 나머지 전량 소각 |
| 오퍼레이터 잔액 | 0 | 완전 슬래싱 |

```go
// Slashing 검증 코드
operatorStake, _ := slashingContracts.DepositManager.AccStaked(nil, candidateAddOn, operatorManager)
require.Equal(t, 0, operatorStake.Cmp(big.NewInt(0)), "Operator stake should be fully slashed")

// 보상 계산
slashingRewardRate := getSlashingRewardRate(t, sys, slashingContracts)
expectedReward := initialStake * slashingRewardRate / 10000  // basis points
```

#### RAT 결과

| 항목 | 조건 | 결과 |
|------|------|------|
| Challenger 승리 시 | Bond 복원 | `TotalBondForRAT = 0`, `DepositedAmount` 원복 |
| Game Bond Credit | 승자에게 | Root Bond + Attack Bond 전액 |
| Defender 승리 시 | Bond 몰수 | Validator의 담보 손실 |

```go
// RAT Bond 복원 검증
require.True(t, regAfterResolve.TotalBondForRAT.Cmp(big.NewInt(0)) == 0,
    "Bond should be restored after challenger wins")
require.True(t, regAfterResolve.DepositedAmount.Cmp(depositAmount) == 0,
    "Deposit should be restored to original")

// Credit 검증
creditBalance, _ := game.Credit(callOpts, accounts.Validator.Addr)
require.True(t, creditBalance.Cmp(totalGameBonds) == 0)  // Root + Attack bonds
```

---

## 4. 테스트 케이스 비교

### 4.1 Slashing 테스트 케이스

| 테스트명 | 설명 |
|----------|------|
| `TestSlashing_BasicOperatorSlashing` | 기본 오퍼레이터 슬래싱 전체 흐름 |

**테스트 단계:**
1. TON Staking 시스템 시작
2. CandidateAddOn으로 오퍼레이터 등록
3. RAT 및 Registry 설정
4. DisputeGame 생성 (잘못된 claim)
5. Challenger 공격
6. 게임 해결 (CHALLENGER_WINS)
7. Slashing 실행
8. 결과 검증 (스테이크 몰수, 보상 지급, 소각)

### 4.2 RAT 테스트 케이스

| 테스트명 | 설명 |
|----------|------|
| `TestSimpleRAT_ValidatorRegistration` | Validator RAT 등록 검증 |
| `TestSimpleRAT_GameCreation` | DisputeGame 생성 및 RAT 트리거 검증 |
| `TestSimpleRAT_EvidenceSubmission` | Evidence 제출 전체 흐름 |
| `TestSimpleRAT_ChallengerWins` | Challenger 승리 시 Bond 복원 및 Credit 청구 |
| `TestTONStakingSystemStartup` | 시스템 시작 검증 |
| `TestAccountBalances` | 계정 잔액 검증 |
| `TestRATContractCall` | RAT 컨트랙트 호출 검증 |

---

## 5. 헬퍼 함수 비교

### 5.1 Slashing 전용 헬퍼

| 함수명 | 위치 | 용도 |
|--------|------|------|
| `connectSlashingContracts` | `slashing_helpers.go` | Slashing 컨트랙트 연결 |
| `registerOperatorWithCandidateAddOn` | `slashing_helpers.go` | CandidateAddOn 등록 |
| `executeSlashing` | `slashing_helpers.go` | Slashing 실행 |
| `getStakeBalance` | `slashing_helpers.go` | 스테이크 잔액 조회 |
| `getWTONBalance` | `slashing_helpers.go` | WTON 잔액 조회 |
| `getSlashingRewardRate` | `slashing_helpers.go` | 보상률 조회 |
| `setSlashingRewardRate` | `slashing_helpers.go` | 보상률 설정 |

### 5.2 RAT 전용 헬퍼

| 함수명 | 위치 | 용도 |
|--------|------|------|
| `SetupTestAccounts` | `e2eutils/rat/helpers.go` | 테스트 계정 설정 |
| `ConnectTestContracts` | `e2eutils/rat/helpers.go` | RAT/TON 컨트랙트 연결 |
| `AdjustMinimumCollateral` | `e2eutils/rat/helpers.go` | 최소 담보 조정 |
| `RegisterValidatorWithTON` | `e2eutils/rat/helpers.go` | Validator 등록 |
| `CreateDisputeGame` | `e2eutils/rat/helpers.go` | DisputeGame 생성 |
| `CreateDisputeGameWithWrongClaim` | `e2eutils/rat/helpers.go` | 잘못된 claim으로 게임 생성 |
| `ParseRATTriggerEvent` | `e2eutils/rat/helpers.go` | RAT 트리거 이벤트 파싱 |
| `ParseRATTriggerEventWithBatchIndex` | `e2eutils/rat/helpers.go` | BatchIndex 포함 이벤트 파싱 |
| `AttackClaim` | `e2eutils/rat/helpers.go` | Claim 공격 |
| `ResolveGame` | `e2eutils/rat/helpers.go` | 게임 해결 |
| `AdvanceTimeAndMine` | `e2eutils/rat/helpers.go` | 시간 경과 및 블록 마이닝 |
| `GetGameStatus` | `e2eutils/rat/helpers.go` | 게임 상태 조회 |

### 5.3 공용 시스템 헬퍼

| 함수명 | 위치 | 용도 |
|--------|------|------|
| `StartTONStakingSystem` | `e2eutils/rat/system.go` | TON Staking 시스템 시작 |
| `Close` | `e2eutils/rat/system.go` | 시스템 종료 및 정리 |
| `findProjectRoot` | `e2eutils/rat/system.go` | 프로젝트 루트 탐색 |
| `getFreePort` | `e2eutils/rat/system.go` | 동적 포트 할당 |

---

## 6. 이벤트 시그니처

### 공통 이벤트

```go
const (
    EventDisputeGameCreated     = "0x5b565efe82411da98814f356d0e7bcb8f0219b8d970307c5afb4a6903a8b2e35"
    EventAttentionTestTriggered = "0xcf68a8dafa7b2329d7d7fcde3af620c2a51f64345d1eb2d66ffe7c7f1e9b0c38"
)
```

---

## 7. 테스트 계정 설정

| 계정 | Private Key | 용도 |
|------|-------------|------|
| Validator | Account #3 | Validator/Operator 역할 |
| Deployer | Account #1 | 컨트랙트 배포자 |
| Proposer | Account #4 | DisputeGame 생성자 |
| Challenger | Account #5 | Slashing 요청자 (Slashing만) |

---

## 8. 시간 관련 파라미터

| 파라미터 | 값 | 용도 |
|----------|-----|------|
| Game Clock Duration | 컨트랙트에서 조회 | 게임 타임아웃 |
| Slashing 대기 시간 | 14일 (1,209,600초) | 게임 해결 전 대기 |
| DelayedWETH Delay | 컨트랙트에서 조회 | Credit 청구 지연 |

---

## 9. 결론

### Slashing 테스트의 특징

1. **TON Staking 생태계 통합**: Layer2Manager, DepositManager, SeigManager 등 기존 스테이킹 인프라와 긴밀히 통합
2. **경제적 처벌 중심**: 악의적 행위에 대한 강력한 경제적 제재 (90% 소각)
3. **CandidateAddOn 기반**: 레이어2 오퍼레이터로서의 역할 등록 필요
4. **Challenger 인센티브**: 10% 보상으로 감시자 역할 장려

### RAT 테스트의 특징

1. **RAT 프로토콜 중심**: Validator의 주의력(Attention) 검증에 초점
2. **게임 이론 검증**: FaultDisputeGame의 전체 라이프사이클 테스트
3. **Bond 시스템**: 담보 잠금/해제 메커니즘 검증
4. **Credit 시스템**: DelayedWETH를 통한 2단계 청구 프로세스
5. **Evidence 제출**: Validator가 적극적으로 증거 제출

### 상호 의존성

- **Slashing 테스트**는 RAT 헬퍼(`e2eutils/rat`)를 활용하여 DisputeGame 생성 및 해결
- 두 테스트 모두 `StartTONStakingSystem`을 통해 동일한 devnet 환경 사용
- RAT 트리거 이벤트 파싱 로직 공유

---

## 부록: 디렉토리 구조

```
op-e2e/
├── bindings/                    # 컨트랙트 바인딩
│   ├── layer2manager_slashing.go
│   ├── depositmanager_slashing.go
│   ├── seigmanager_slashing.go
│   ├── rat.go
│   ├── fault_dispute_game.go
│   └── ...
├── e2eutils/
│   └── rat/
│       ├── helpers.go           # 공용 RAT 헬퍼
│       └── system.go            # TON Staking 시스템 시작
├── faultproofs/
│   ├── rat_challenge_test.go    # RAT 테스트
│   ├── rat_system_test.go       # 시스템 테스트
│   └── rat_challenge_helpers.go # RAT 테스트 헬퍼
├── slashing/
│   ├── slashing_test.go         # Slashing 테스트
│   ├── slashing_helpers.go      # Slashing 헬퍼
│   └── rat_challenge_helpers.go # Slashing용 RAT 헬퍼
├── go.mod
├── go.sum
├── Makefile
└── README.md
```
