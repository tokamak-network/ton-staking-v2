---
id: upgrade-validator-guide
sidebar_position: 4
---

# 검증자 관점 (신규)

## V2 vs V3: 검증자 역할

### V2 (현재 메인넷 서비스)
검증자 역할: 없음

### V3 (업그레이드)
검증자 역할:
  - RAT(Randomized Attention Test) 참여
  - 시뇨리지 수령 (α · S_i / |V_i|)
  - L2 네트워크 모니터링
  - DisputeGame 증거 제출

## 검증자 등록 프로세스

```
1. DepositManager에 TON 스테이킹
   - 단일 스테이킹으로 시뇨리지 수령 자격 + RAT 담보금 겸용
   - 별도 담보금 예치 불필요
2. RAT.registerValidator(systemConfig) 호출
3. 검증자 등록 완료
```

**담보금 조회**:
- `RAT._getValidatorCollateral()`: SeigManager를 통해 L2 Coinage의 검증자 잔액 조회
  - `(collateral, layer2)` 튜플을 반환하여 중복 조회 방지

## 담보금 시스템

### 담보금의 목적

검증자는 L2 네트워크를 상시 모니터링하고 RAT에 응답할 책임이 있습니다. 담보금은 이 책임을 보장하기 위한 안전장치입니다.

```
담보금의 역할:
1. RAT 테스트 응답 보장 → 응답하지 않으면 담보금 일부 슬래싱 (C_off)
2. 지속적인 네트워크 모니터링 유도 → 경제적 인센티브 제공
3. 악의적 행위 방지 → 담보금 손실 리스크로 억제
```

### 담보금 작동 방식

**V3에서는 별도 예치 대신 기존 스테이킹을 담보금으로 사용**. 핵심: 검증자의 L2 Coinage 잔액 = 담보금 (별도 예치 불필요)

### 시뇨리지 수령 조건 및 담보금 체크 기준

**조건 1: 소속 L2의 시뇨리지 자격**
```solidity
T_i ≥ max(D_sequencer, θ · B_i)
- 시퀀서가 충족해야 L2가 시뇨리지를 받음
- 검증자는 이 시뇨리지를 나눠 받음
```

**조건 2: 검증자 개인 담보금 - 3가지 체크 기준**

> **중요**: `relaxedValidatorCheck` 플래그가 적용되는 시점과 적용되지 않는 시점이 다릅니다.

```solidity
1️⃣ 검증자 등록 시 (Registration)
   - 항상 D_validator 이상 필요 (relaxedValidatorCheck 무관)
   - 최소 요구: D_validator = C_off + Δ_validator

2️⃣ 스테이킹 출금 제한 (Withdrawal Restriction)
   - 항상 D_validator 이상 유지 필요 (relaxedValidatorCheck 무관)
   - 검증자가 등록된 상태에서는 담보금을 D_validator 아래로 인출 불가
   - 검증자 해제 후에만 자유롭게 인출 가능

3️⃣ RAT 게임 중 담보금 검증 (During RAT Test)
   - relaxedValidatorCheck에 따라 다름 (운영 정책)

   // 초기 운영 (relaxedValidatorCheck = true)
   최소 담보금 = C_off  (낮은 진입 장벽)
   - RAT 테스트 시 C_off만 있으면 유효
   - 예: 100 WTON만 있어도 시뇨리지 수령 가능

   // 성장 후 (relaxedValidatorCheck = false)
   최소 담보금 = D_validator  (엄격한 기준)
   - RAT 테스트 시 D_validator 필요
   - 예: 1,000 WTON 필요 (보안 강화)

여기서:
- C_off: 슬래싱 페널티 (예: 100 WTON)
- D_validator: C_off + Δ_validator (예: 1,000 WTON)
- Δ_validator: 추가 안전 버퍼 (예: 900 WTON)
```

**정리:**
| 시나리오 | relaxedValidatorCheck | 최소 담보금 요구 |
|---------|----------------------|---------------|
| 검증자 등록 시 | 무관 (항상 체크) | D_validator |
| 스테이킹 출금 제한 | 무관 (항상 체크) | D_validator |
| RAT 게임 중 검증 | 적용됨 | C_off (true) / D_validator (false) |

### 운영 계획

| 단계 | `relaxedValidatorCheck` | 검증자 최소 담보금 | 목적 |
|------|------------------------|-----------------|------|
| 1단계 (초기) | `true` | C_off | 검증자 유치 (낮은 진입 장벽) |
| 2단계 (성장) | `false` | D_validator | 보안 강화 (높은 안전성) |

**예시:**
- C_off = 100 WTON
- Δ_validator = 900 WTON
- D_validator = 1,000 WTON

초기: 100 WTON만 있어도 검증자 유지 가능
성장 후: 1,000 WTON 필요 (DAO 거버넌스 결정)

## RAT 메커니즘 (신규)

### 랜덤 선택 알고리즘

**확률적 트리거:**
```solidity
// 1. 랜덤 값 생성 (L1 blockHash + timestamp 조합)
uint256 randomValue = uint256(
    keccak256(abi.encodePacked(blockHash, block.timestamp))
) % RAY;

// 2. 트리거 확률 체크
if (randomValue >= ratTriggerProbability) return;  // π_a 확률로만 트리거
```

**검증자 랜덤 선택:**
```solidity
// 1. 랜덤 인덱스 생성 (blockHash를 seed로 사용)
uint256 randomIndex = uint256(
    keccak256(abi.encodePacked(blockHash, block.timestamp))
) % validatorCount;

// 2. 활성 검증자 배열에서 O(1) 접근
address selectedValidator = pool.validators[randomIndex];
```

**랜덤 소스:**
- `blockHash`: DisputeGameFactory가 전달하는 L1 이전 블록 해시 (`blockhash(block.number - 1)`)
  - L1 컨센서스로 보장된 값
  - L2 시퀀서가 조작 불가능
  - 충분히 예측 불가능한 엔트로피
- `block.timestamp`: L1 타임스탬프 (추가 엔트로피)

**보안 고려사항:**
- L1 블록 해시 사용으로 L2 시퀀서 조작 불가능
- DisputeGame 생성 시점마다 고유한 랜덤 값

### RAT 프로세스

```
DisputeGame 생성 시
  │
  ├─ 확률 π_a로 RAT 트리거 (랜덤 값 생성 및 확률 체크)
  │
  ├─ 해당 L2의 검증자 중 랜덤 선택
  │
  ├─ 선차감: 검증자 coinage → RAT coinage 전송 (C_off)
  │   ├─ SeigManager.transferCoinageToRat() 호출
  │   └─ lockedForRAT += C_off
  │
  ├─ 증거 제출 기간: evidenceSubmissionPeriod (예: 1 hour)
  │
  ├─ ✅ 증거 제출 성공 시 (Evidence Period 내)
  │   ├─ submitEvidence() 호출
  │   ├─ RAT coinage → 검증자 coinage 복구
  │   ├─ SeigManager.transferCoinageFromRat() 호출
  │   └─ lockedForRAT -= C_off
  │
  ├─ ⏳ 증거 제출 기간 초과 시 (Challenge Period)
  │   ├─ 챌린지 게임 기간: challengeGameDuration
  │   ├─ 챌린지 게임 승리 시 복구 가능 (resolveClaim())
  │   └─ RAT coinage → 검증자 coinage 복구
  │
  └─ ❌ 챌린지 기간 종료 시
      ├─ C_off 영구 몰수 확정
      ├─ RAT이 coinage 보유
      ├─ lockedForRAT -= C_off
      └─ withdrawSlashingsToTreasury()로 Treasury 전송 가능
```

상세 구현은 [기술 구현 상세](./05-technical-details.md) 참고.

## 검증자 보상 계산

```
검증자 개별 보상 = (α · S_i) / |V_i|

여기서:
- S_i = 해당 L2의 시뇨리지
- α = 검증자 분배 비율 (예: 20%)
- |V_i| = 해당 L2의 검증자 수

예시:
- L2의 시뇨리지 S_i = 100 TON
- 검증자 분배 비율 α = 20%
- 검증자 풀 = 20 TON
- 검증자 수 |V_i| = 4명
- 검증자 1인당 = 5 TON

💡 검증자가 없으면: DAO가 α · S_i 전액 수령
```

자세한 계산 로직은 [기술 구현 상세](./05-technical-details.md) 참고.
