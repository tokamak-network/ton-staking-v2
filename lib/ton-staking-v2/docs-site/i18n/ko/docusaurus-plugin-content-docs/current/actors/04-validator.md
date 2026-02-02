---
id: actors-validator
sidebar_position: 4
---

# 검증자

## 정의

L2 배치의 유효성을 검증하고 RAT에 응답하는 참여자입니다.

## 역할

- L2 배치 모니터링
- RAT (Randomized Attention Test) 응답
- Fraud 발견 시 챌린지 제기 (챌린저 역할 겸함)

## 보상

```
검증자 보상 = v_j = Σ_{i: j∈V_i} (α · S_i) / |V_i|

여기서:
- V_i = L2 i에 할당된 검증자 집합
- |V_i| = L2 i의 검증자 수
- α = 검증자 분배 비율 (예: 20%)
- S_i = L2 i의 시뇨리지
```

## 리스크

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

## 담보금 및 등록 조건

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

## 유효한 검증자 (Active Validator)

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

## 인프라 요구사항

검증자는 다음 인프라를 **반드시** 운영해야 합니다:

| 컴포넌트 | 요구사항 | 이유 |
|---------|---------|------|
| **L2 Full Archive Node** | op-geth with archive mode | 전체 L2 state history 보유 필요 |
| **Debug API 활성화** | `--http.api=debug` | Adjacent leaves 탐색용 `debug_accountRange` |
| **L1 RPC** | 안정적인 L1 연결 | RAT 이벤트 모니터링 및 증거 제출 |
| **검증자 소프트웨어** | 실행 중인 검증자 프로그램 | 자동 증거 생성 및 제출 |

**중요**: Public RPC로는 RAT 응답 불가능합니다. Debug API는 보안상 public RPC에서 제공되지 않으므로, 검증자는 **자체 L2 노드를 운영**해야 합니다.

## 검증자 소프트웨어

검증자는 **검증자 소프트웨어** (RAT Client)를 실행하여 RAT 테스트에 자동으로 응답해야 합니다.

### 검증자 소프트웨어란?

검증자 소프트웨어는 검증자가 L2 full node를 운영하고 있음을 증명하기 위한 오프체인 프로그램입니다.

**핵심 기능**:
- L1 RAT 컨트랙트 이벤트 모니터링
- L2 노드에서 증거 생성 (Adjacent Leaves 탐색)
- L1에 증거 자동 제출

**증명 방식**: State Root as Target
- L2 state root를 랜덤값으로 사용
- State trie에서 `leafA.key < stateRoot < leafB.key`인 인접한 두 account 찾기
- 두 리프 사이에 다른 리프가 없음을 Divergence Witness로 증명
- Public RPC 불가: `debug_accountRange`로 전체 trie 순회 필요

### 검증자 소프트웨어 동작 흐름

```
┌─────────────────────────────────────────────────────────────────┐
│                  검증자 소프트웨어 (RAT Client)                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. L1 이벤트 모니터링                                            │
│     RAT.AttentionTestTriggered(testId, validator, systemConfig) │
│     │                                                            │
│     ▼                                                            │
│  2. 검증자 확인                                                   │
│     if (validator == myAddress) → 증거 생성 시작                 │
│     │                                                            │
│     ▼                                                            │
│  3. L2 노드에서 OutputRootProof 조회                             │
│     - stateRoot = L2 block header의 state root                  │
│     - messagePasserStorageRoot = L2ToL1MessagePasser storage     │
│     - latestBlockHash = L2 block hash                           │
│     │                                                            │
│     ▼                                                            │
│  4. Adjacent Leaves 탐색 (Debug API 사용)                        │
│     debug_accountRange(blockHash, start, maxResults)            │
│     → stateRoot를 bracket하는 leafA, leafB 찾기                 │
│     → Binary search로 효율적 탐색                                │
│     │                                                            │
│     ▼                                                            │
│  5. Merkle Proof 생성                                            │
│     eth_getProof(addressA, [], blockNumber)                     │
│     eth_getProof(addressB, [], blockNumber)                     │
│     │                                                            │
│     ▼                                                            │
│  6. Divergence Witness 생성                                      │
│     - divergenceNode: 분기점 브랜치 노드                         │
│     - indexA, indexB: 두 리프의 슬롯 인덱스                       │
│     - Gap 검증: indexA와 indexB 사이 빈 슬롯 확인                │
│     │                                                            │
│     ▼                                                            │
│  7. 증거 제출                                                     │
│     RAT.submitEvidence(                                          │
│       systemConfig,                                              │
│       batchIndex,                                                │
│       abi.encode(StateLeafEvidence)                             │
│     )                                                            │
│     │                                                            │
│     ▼                                                            │
│  8. C_off 반환                                                   │
│     RAT → Coinage: C_off 복구                                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### StateLeafEvidence 구조

```solidity
struct StateLeafEvidence {
    bytes32 leafAKey;          // keccak256(addressA)
    bytes leafAValue;          // RLP(accountA)
    bytes[] leafAProof;        // Merkle proof for leafA
    bytes32 leafBKey;          // keccak256(addressB)
    bytes leafBValue;          // RLP(accountB)
    bytes[] leafBProof;        // Merkle proof for leafB
    bytes32 stateRoot;         // L2 state root (deprecated)
    uint256 blockNumber;       // L2 block number
    OutputRootProof outputRootProof;  // Proves stateRoot authenticity
}

struct OutputRootProof {
    bytes32 version;                      // Always 0x0
    bytes32 stateRoot;                    // L2 state root
    bytes32 messagePasserStorageRoot;     // L2ToL1MessagePasser storage root
    bytes32 latestBlockhash;              // L2 block hash
}
```

**검증 로직 (온체인)**:
1. OutputRootProof 검증: `hash(outputRootProof) == rootClaim`
2. Adjacency 검증: `leafAKey < stateRoot < leafBKey`
3. Merkle Proof 검증: 두 리프가 모두 stateRoot에서 검증됨
4. Divergence Witness 검증: 두 리프 사이에 다른 리프 없음

**Gas 비용**: ~277k (실제 측정값)

## 상호작용

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
│  │ 인프라 준비:                                         │   │
│  │   1. L2 Full Archive Node 운영 (op-geth)            │   │
│  │      - Sync mode: archive                            │   │
│  │      - Debug API 활성화: --http.api=debug           │   │
│  │   2. 검증자 소프트웨어 실행                           │   │
│  │      - L1 RPC 연결                                   │   │
│  │      - L2 RPC 연결 (debug API 포함)                  │   │
│  │      - 자동 모니터링 및 증거 제출                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ RAT 응답 (검증자 소프트웨어 자동 처리):               │   │
│  │   1. AttentionTestTriggered 이벤트 감지               │   │
│  │   2. L2 노드에서 Adjacent Leaves 탐색                │   │
│  │   3. OutputRootProof 및 Merkle Proof 생성            │   │
│  │   4. RAT.submitEvidence() 자동 제출                  │   │
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

## 검증자 여정 가이드

검증자가 V3 시스템에 참여하는 전체 프로세스입니다.

### 신규 검증자 참여 플로우

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

### RAT 응답

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

### 검증자 탈퇴 및 재등록

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
