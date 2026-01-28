---
id: 08-v2-to-v3-upgrade-guide
sidebar_position: 8
---
# 톤스테이킹 서비스 V2 → V3 업그레이드 가이드

> **현재 메인넷에서 서비스 중인 톤스테이킹(V2)에서 V3로 업그레이드 시 실제로 무엇이 달라지는지를 한눈에 파악할 수 있도록 정리한 문서입니다.**

---

## 📋 빠른 목차

- [1. 한눈에 보는 V2 → V3 핵심 변경사항](#1-한눈에-보는-v2--v3-핵심-변경사항)
- [2. 일반 스테이커 관점](#2-일반-스테이커-관점)
- [3. 시퀀서 관점](#3-시퀀서-관점)
- [4. 검증자 관점 (신규)](#4-검증자-관점-신규)
- [5. 기술 구현 상세](#5-기술-구현-상세)
- [6. 마이그레이션 체크리스트](#6-마이그레이션-체크리스트)
- [7. FAQ](#7-faq)

---

## 1. 한눈에 보는 V2 → V3 핵심 변경사항

### 1.1 현재 서비스 vs 업그레이드 버전

| 구분 | V2 (현재 메인넷 서비스) | V3 (업그레이드) |
|------|---------------------|---------------|
| **컨트랙트 버전** | SeigManagerV1_3 | SeigManagerV3_1 + RAT + ValidatorReward |
| **시뇨리지 수령자** | **DAO + 시퀀서 + 일반 스테이커** | **DAO + 시퀀서 + 검증자** |
| **분배 기준** | D/T 비율로 시퀀서/스테이커 나눔 | Bridged TON 기반 (성과 중심) |
| **분배 함수** | 선형 분배 | 쌍곡선 포화 함수 `y(x) = L·(x/(k+x))` |
| **검증자 역할** | 없음 | RAT + 시뇨리지 분배 |
| **DAO 할당** | 고정 비율 (d·A) | 고정 비율 + 미분배분 |

### 1.2 핵심 변화: 시뇨리지 분배 대상 변경

**V3의 방향**: L2 네트워크를 직접 운영하고 검증하는 참여자에게 시뇨리지 집중

```
V2 (현재 메인넷 서비스):
  시뇨리지 A
    ├─► DAO: d · A (고정)
    │
    └─► 나머지 (1-d) · A를 D/T 비율로 분배
        ├─► (D/T) × (1-d) · A → L2 시퀀서들
        └─► (1 - D/T) × (1-d) · A → 일반 스테이커들

V3 (업그레이드):
  시뇨리지 A
    ├─► DAO: d · A (고정) + 미분배분
    └─► L2 운영자 및 검증자에게 성과 기반 분배:
        ├─► 시퀀서 (L2 운영자): (1-α) · S_i
        └─► 검증자 (L2 검증자): α · S_i / |V_i|
```

일반 스테이커도 검증자로 참여하면 시뇨리지를 받을 수 있습니다.

---

## 2. 일반 스테이커 관점

### 2.1 시뇨리지 분배 대상 변경

```
V2 (현재): TON 스테이킹 → 스테이킹 비율에 따라 시뇨리지 수령
V3 (업그레이드): TON 스테이킹 → L2 운영/검증 참여 시 시뇨리지 수령
```

**왜 변경되었나요?**
- V3는 **L2 네트워크 보안 강화**에 집중
- 시뇨리지를 **실제 네트워크 운영/검증 참여자**에게 집중 분배
- L2 생태계 활성화를 위한 인센티브 재설계

### 2.2 변하지 않는 것

- 기존 TON 스테이킹 방식 **그대로 유지**
- DepositManager를 통한 예치/인출 프로세스 **동일**
- 스테이킹 자체는 계속 가능

### 2.3 새로운 참여 방법

**검증자로 참여**: 시뇨리지를 받으면서 L2 네트워크 보안에 기여 ([4장 참고](#4-검증자-관점-신규))
- 기존 스테이킹을 유지하면서 검증자 등록 가능
- 추가 자금 없이도 시뇨리지 수령 가능

### 2.4 DAO 거버넌스

#### 기존 권한 유지
- DAO 고정 분배 비율 (d·A) 수령

#### 새로운 권한
- **V3 마이그레이션 실행** (`migrateToV3()`)
- **검증자 진입 정책 제어**
  - `relaxedValidatorCheck` 플래그 설정
  - `true`: 검증자 진입 장벽 낮춤 (초기 권장)
  - `false`: 검증자 보안 기준 강화 (성장 후)
- **V3 파라미터 설정**
  - `daoDistributionRatio` (d): DAO 분배 비율
  - `minStakingRatio` (θ): 시퀀서의 Bridged TON 대비 최소 스테이킹 비율 (예: 10%)
  - `validatorDistributionRatio` (α): 검증자 분배 비율
  - `halfSaturationPoint` (k): 쌍곡선 함수 반포화점

#### 추가 수익
- 미분배 시뇨리지 자동 DAO 귀속
  - 자격 미달 L2는 y(x) 계산에서 제외되어 미분배분(L - y)으로 처리

---

## 3. 시퀀서 관점

### 3.1 시뇨리지 분배 기준 변경

#### V2 (현재 메인넷 서비스)
```
분배 기준: L2 TVL (Total Value Locked)
분배 방식: 선형 비례
```

#### V3 (업그레이드)
```
분배 기준: Bridged TON (L2로 브릿지된 TON 양)
분배 방식: 쌍곡선 포화 함수 y(x) = L·(x/(k+x))
  - 성과 기반 분배
  - 수확체감 효과 (독점 방지)
  - 자격 조건 필수
```

### 3.2 자격 조건 신설

#### V3 (업그레이드)
```solidity
조건: T_i ≥ max(D_sequencer, θ · B_i)

여기서:
- T_i: 시퀀서의 스테이킹 금액
- D_sequencer = H_max · C_max + Δ_sequencer
  - H_max: 최대 동시 챌린저 수
  - C_max: 단일 Fraud Proof 최대 비용
  - Δ_sequencer: 시퀀서 추가 보상
- θ · B_i: Bridged TON의 10% (예시)

⚠️ 조건 미충족 시: B̃_i = 0, 해당 L2는 시뇨리지를 받지 못하고 미분배분으로 처리
```

### 3.3 담보금 시스템

**V3 구현**: 단일 스테이킹으로 시뇨리지 수령 자격 + 슬래싱 담보금 겸용 (별도 담보금 예치 불필요)

**담보금 조회**:
- `SeigManager.getSequencerStaked(layer2)`: L2 Coinage의 시퀀서 잔액 조회

### 3.4 슬래싱 정책 변경

| 항목 | V2 (현재) | V3 (업그레이드) |
|------|----------|---------------|
| **슬래싱 대상** | - | 스테이킹 전액 (`coinage.burnFrom()`) |
| **시뇨리지** | TVL 비례 분배 | 수령 불가 (자격 상실) |
| **L2 운영** | - | **정지되지 않음** |

V3에서는 슬래싱 시 L2가 물리적으로 정지되지 않고, 경제적 제재(시뇨리지 중단 + 담보금 몰수)만 적용됩니다.

### 3.5 시퀀서 보상 계산 방식

```
시퀀서 보상 = (1-α) · S_i

여기서:
- S_i = 해당 L2의 시뇨리지 = y(x) · (B̃_i / x)
- α = 검증자 분배 비율 (예: 20%)
- (1-α) = 시퀀서 몫 (예: 80%)
```

자세한 계산 로직은 [5.2절](#52-시뇨리지-분배-로직-변경) 참고

---

## 4. 검증자 관점 (신규)

### 4.1 V2 vs V3: 검증자 역할

#### V2 (현재 메인넷 서비스)
검증자 역할: 없음

#### V3 (업그레이드)
검증자 역할:
  - RAT(Randomized Attention Test) 참여
  - 시뇨리지 수령 (α · S_i / |V_i|)
  - L2 네트워크 모니터링
  - DisputeGame 증거 제출

### 4.2 검증자 등록 프로세스

```
1. DepositManager에 TON 스테이킹
   - 단일 스테이킹으로 시뇨리지 수령 자격 + RAT 담보금 겸용
   - 별도 담보금 예치 불필요
2. RAT.registerValidator(systemConfig) 호출
3. 검증자 등록 완료
```

**담보금 조회**:
- `RAT._getValidatorCollateral()`: SeigManager를 통해 L2 Coinage의 검증자 잔액 조회

### 4.3 담보금 시스템

#### 4.3.1 담보금의 목적

검증자는 L2 네트워크를 상시 모니터링하고 RAT에 응답할 책임이 있습니다. 담보금은 이 책임을 보장하기 위한 안전장치입니다.

```
담보금의 역할:
1. RAT 테스트 응답 보장 → 응답하지 않으면 담보금 일부 슬래싱 (C_off)
2. 지속적인 네트워크 모니터링 유도 → 경제적 인센티브 제공
3. 악의적 행위 방지 → 담보금 손실 리스크로 억제
```

#### 4.3.2 담보금 작동 방식

**V3에서는 별도 예치 대신 기존 스테이킹을 담보금으로 사용**. 핵심: 검증자의 L2 Coinage 잔액 = 담보금 (별도 예치 불필요)

#### 4.3.3 시뇨리지 수령 조건 및 담보금 체크 기준

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

#### 4.3.4 운영 계획

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

### 4.4 RAT 메커니즘 (신규)

#### 4.4.1 랜덤 선택 알고리즘

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

#### 4.4.2 RAT 프로세스

```
DisputeGame 생성 시
  │
  ├─ 확률 π_a로 RAT 트리거 (랜덤 값 생성 및 확률 체크)
  │
  ├─ 해당 L2의 검증자 중 랜덤 선택
  │
  ├─ 선차감: 검증자 coinage → RAT coinage 전송 (C_off)
  │   ├─ SeigManager.transferCoinageToRAT() 호출
  │   └─ lockedForRAT += C_off
  │
  ├─ 증거 제출 기간: evidenceSubmissionPeriod (예: 1 hour)
  │
  ├─ ✅ 증거 제출 성공 시 (Evidence Period 내)
  │   ├─ submitEvidence() 호출
  │   ├─ RAT coinage → 검증자 coinage 복구
  │   ├─ SeigManager.transferCoinageFromRAT() 호출
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

상세 구현은 [5.4절](#54-rat-coinage-전송-구현-신규) 참고

### 4.5 검증자 보상 계산

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

자세한 계산 로직은 [5.2절](#52-시뇨리지-분배-로직-변경) 참고

---

## 5. 기술 구현 상세

### 5.1 컨트랙트 버전 비교

| 컨트랙트 | V2 (현재 메인넷) | V3 (업그레이드) | 상태 |
|---------|----------------|---------------|------|
| **SeigManager** | V1_3 (0xce18...F628) | V1_4 (미배포) | ✅ 완료 |
| **DepositManager** | V1_1 | V1_2 | ✅ 완료 |
| **Layer2Manager** | V1_1 | V1_2 | ✅ 완료 |
| **L1BridgeRegistry** | V1_1 | V1_2 (단일 구현체) | ✅ 완료 |
| **RAT** | 없음 | 신규 배포 | ✅ 완료 |
| **ValidatorReward** | 없음 | 신규 배포 | ✅ 완료 |

### 5.2 시뇨리지 분배 로직 변경

#### V2 구현 (SeigManagerV1_3, 현재 메인넷)
```solidity
// DAO + 시퀀서 + 일반 스테이커에게 분배
function updateSeigniorage() {
    // 1. 전체 시뇨리지 계산
    uint256 A = (block.number - lastSeigBlock) * seigPerBlock;

    // 2. DAO 고정 분배
    uint256 daoAmount = A * daoCommissionRate / RAY;  // d · A

    // 3. 나머지 계산
    uint256 remaining = A - daoAmount;  // (1-d) · A

    // 4. D/T 비율로 시퀀서와 스테이커에게 분배
    // - (D/T) × remaining → L2 시퀀서들 (L2별 TVL 비례)
    // - (1 - D/T) × remaining → 일반 스테이커들 (스테이킹 비율)

    for (each L2) {
        uint256 l2Share = remaining * l2TVL / totalTVL;
        distributeToStakersInL2(layer2, l2Share);
        // 이 안에서 시퀀서와 스테이커가 스테이킹 비율대로 나눠 받음
    }
}
```

#### V3 구현 (SeigManagerV3_1, 업그레이드)
```solidity
// 시퀀서 + 검증자에게 Bridged TON 기반 쌍곡선 분배
function updateSeigniorage() {
    // v3Migrated 플래그 체크
    if (!v3Migrated) {
        // V2 로직 사용 (기존 V1_3 로직)
        return _updateSeigniorageV2();
    }

    // 1. 전체 시뇨리지 계산
    uint256 A = (block.number - lastSeigBlock) * seigPerBlock;

    // 2. DAO 고정 분배
    uint256 daoFixed = A * daoDistributionRatio / RAY;

    // 3. L2 분배 가능량
    uint256 L = A - daoFixed;

    // 4. 자격 확인 및 유효 Bridged TON 합계
    uint256 x = 0;  // Σ B̃_i
    for (each L2) {
        uint256 B_i = l1BridgeRegistry.getBridgedTON(layer2);
        uint256 T_i = getSequencerStaked(layer2);
        uint256 D_seq = calculateDSequencer();
        uint256 minRequired = max(D_seq, minStakingRatio * B_i / RAY);

        if (T_i >= minRequired) {
            x += B_i;  // 자격 충족 시만 포함
        }
    }

    // 5. 쌍곡선 포화 함수: y(x) = L · (x / (k + x))
    uint256 k = halfSaturationPoint;
    uint256 y = L * x / (k + x);

    // 6. L2별 분배
    for (each eligible L2) {
        // S_i = y(x) · (B̃_i / x)
        uint256 S_i = y * B_i / x;

        // 시퀀서 보상: (1-α) · S_i
        uint256 sequencerReward = S_i * (RAY - validatorDistributionRatio) / RAY;
        coinageOfL2.mint(operator, sequencerReward);

        // 검증자 보상: α · S_i
        uint256 validatorReward = S_i * validatorDistributionRatio / RAY;
        validatorRewardContract.distribute(layer2, validatorReward);
    }

    // 7. 미분배분 DAO 귀속
    uint256 unallocated = L - y;
    daoTreasury += daoFixed + unallocated;
}
```

### 5.3 담보금 조회 방식 (V3 신규)

#### 시퀀서 담보금

```solidity
// SeigManagerV3_1.sol
function getSequencerStaked(address layer2) public view returns (uint256) {
    RefactorCoinageSnapshotI coinage = _coinages[layer2];
    if (address(coinage) == address(0)) return 0;

    address operator = Layer2I(layer2).operator();
    if (operator == address(0)) return 0;

    return coinage.balanceOf(operator);  // Coinage에서 직접 조회
}
```

#### 검증자 담보금

```solidity
// RAT.sol
function _getValidatorCollateral(address validator, address systemConfig)
    internal view returns (uint256)
{
    address layer2 = ILayer2Manager(layer2Manager).getLayer2BySystemConfig(systemConfig);
    if (layer2 == address(0)) return 0;

    // SeigManager를 통해 coinage 조회
    return ISeigManagerForRAT(seigManager).stakeOf(layer2, validator);
}
```

### 5.4 RAT Coinage 전송 구현 (신규)

**SeigManagerV3_1.sol** - RAT 연동 함수
```solidity
// 검증자 → RAT으로 coinage 전송 (슬래싱 선차감)
function transferCoinageToRAT(address layer2, address validator, uint256 amount)
    external onlyRAT
{
    RefactorCoinageSnapshotI coinage = _coinages[layer2];
    coinage.burnFrom(validator, amount);  // 검증자에서 burn
    coinage.mint(ratContract, amount);    // RAT에 mint

    emit CoinageTransferredToRAT(layer2, validator, amount);
}

// RAT → 검증자로 coinage 전송 (복구)
function transferCoinageFromRAT(address layer2, address validator, uint256 amount)
    external onlyRAT
{
    RefactorCoinageSnapshotI coinage = _coinages[layer2];
    coinage.burnFrom(ratContract, amount);  // RAT에서 burn
    coinage.mint(validator, amount);        // 검증자에게 mint

    emit CoinageTransferredFromRAT(layer2, validator, amount);
}
```

> **⚠️ 중요**: RAT은 coinage를 직접 조작할 권한이 없으므로, 반드시 SeigManager를 경유해야 합니다.

**RAT.sol** - SeigManager 호출
```solidity
function _transferCoinageToRAT(address validator, address systemConfig, uint256 amount) internal {
    address layer2 = _getLayer2FromSystemConfig(systemConfig);
    ISeigManagerForRAT(seigManager).transferCoinageToRAT(layer2, validator, amount);
    lockedForRAT[testId] = amount;
}

function _transferCoinageFromRAT(address validator, address systemConfig, uint256 amount) internal {
    address layer2 = _getLayer2FromSystemConfig(systemConfig);
    ISeigManagerForRAT(seigManager).transferCoinageFromRAT(layer2, validator, amount);
    lockedForRAT[testId] = 0;
}
```

---

## 6. 마이그레이션 체크리스트

### 6.1 사용자 대응

#### 일반 스테이커
- [ ] V3 시뇨리지 분배 대상 변경 안내 (공지 필수)
- [ ] 검증자 참여 방법 및 혜택 안내
- [ ] FAQ 작성 및 배포

#### 시퀀서
- [ ] 새로운 자격 조건 안내
- [ ] Bridged TON 기반 분배 안내
- [ ] 담보금 통합에 따른 자본 효율성 개선 안내
- [ ] 시뇨리지 계산 방식 변경 안내
- [ ] 슬래싱 정책 변경 안내

#### 검증자 (신규)
- [ ] 검증자 등록 절차 안내
- [ ] RAT 메커니즘 설명
- [ ] 보상 계산 방식 안내
- [ ] `relaxedValidatorCheck` 정책 안내
- [ ] 검증자 가이드 문서 작성

### 6.2 배포 전 준비사항

#### 컨트랙트 배포
- [ ] SeigManagerV3_1 배포
- [ ] SeigManagerV3_2 배포 (V2 호환 레이어)
- [ ] RAT 배포
- [ ] ValidatorRewardV1 배포
- [ ] DepositManagerV3 배포
- [ ] Layer2ManagerV3 배포
- [ ] L1BridgeRegistryV1_2 배포

#### Selector Routing 설정 (SeigManagerProxy)
- [ ] SeigManagerV3_1 selector 등록
  - [ ] `setValidatorReward(address)`
  - [ ] `setDaoDistributionRatio(uint256)`
  - [ ] `setMinStakingRatio(uint256)`
  - [ ] `setValidatorDistributionRatio(uint256)`
  - [ ] `setHalfSaturationPoint(uint256)`
  - [ ] `migrateToV3()`
  - [ ] `onBridgedTonChange()`
  - [ ] `updateSeigniorage()` (오버라이드)
  - [ ] `updateSeigniorageLayer(address)` (오버라이드)

#### 주소 및 권한 설정
- [ ] SeigManager에 RAT 주소 설정 (`setRATContract`)
- [ ] SeigManager에 ValidatorReward 주소 설정 (`setValidatorReward`)
- [ ] SeigManager에 Layer2Manager 주소 설정
- [ ] SeigManager에 L1BridgeRegistry 주소 설정
- [ ] RAT 권한 설정 (`onlyRAT` modifier 동작 확인)
- [ ] ValidatorReward 권한 설정

#### 파라미터 설정
- [ ] `daoDistributionRatio` (d) 설정 (예: 0.2e27 = 20%)
- [ ] `minStakingRatio` (θ) 설정 (예: 0.1e27 = 10%)
- [ ] `validatorDistributionRatio` (α) 설정 (예: 0.2e27 = 20%)
- [ ] `halfSaturationPoint` (k) 설정 (예: 10,000,000e27 TON)
- [ ] `relaxedValidatorCheck = true` 설정 (초기값)
- [ ] RAT 파라미터 설정
  - [ ] `ratTriggerProbability` (π_a)
  - [ ] `slashingPenalty` (C_off)
  - [ ] `minimumThreshold` (D_min)
  - [ ] `evidenceSubmissionPeriod`

#### V3 마이그레이션 실행
- [ ] `migrateToV3()` 호출 (DAO 거버넌스)
- [ ] `v3Migrated = true` 확인

### 6.3 배포 후 검증사항

#### 기능 검증
- [ ] 시퀀서 스테이킹 조회 정상 동작 확인
- [ ] 검증자 담보금 조회 정상 동작 확인
- [ ] RAT coinage 전송 정상 동작 확인
- [ ] 시뇨리지 자격 체크 정상 동작 확인
- [ ] `relaxedValidatorCheck` flag 동작 확인
- [ ] **시뇨리지 분배 대상 변경** 확인 (L2 운영자/검증자에게만 분배)
- [ ] 시퀀서 시뇨리지 수령 확인
- [ ] 검증자 시뇨리지 분배 확인
- [ ] 미분배분(L - y) DAO 귀속 확인

#### 보안 검증
- [ ] RAT 권한 체크 동작 확인 (`onlyRAT`)
- [ ] Coinage burn/mint 권한 확인
- [ ] 슬래싱 로직 테스트 (testnet)
- [ ] DAO 거버넌스 권한 확인
- [ ] V3 마이그레이션 권한 확인
- [ ] Selector routing 정상 동작 확인

#### 시나리오 테스트
- [ ] V2 → V3 전환 시나리오
- [ ] 검증자 등록 시나리오
- [ ] RAT 트리거 및 응답 시나리오
- [ ] RAT 타임아웃 시나리오
- [ ] 시퀀서 슬래싱 시나리오
- [ ] 자격 미달 L2 시나리오
- [ ] 검증자 없는 L2 시나리오

### 6.4 운영 계획

#### 1단계: 초기 운영 (검증자 유치)
- `relaxedValidatorCheck = true` (완화된 기준)
- 최소 담보금: C_off (낮은 진입 장벽)
- 모니터링: 검증자 수, 네트워크 보안 지표, RAT 응답률

#### 2단계: 성장기 (보안 강화)
- DAO 거버넌스로 `relaxedValidatorCheck = false` 전환
- 최소 담보금: D_validator = C_off + Δ_validator

---

## 7. FAQ

### Q1. V3에서 일반 스테이커의 역할은 무엇인가요?
**A**: V3에서는 L2 네트워크를 직접 운영하거나 검증하는 참여자에게 시뇨리지가 분배됩니다. 일반 스테이커는 검증자로 등록하여 L2 네트워크 검증에 참여하면 시뇨리지를 받을 수 있습니다. 기존 스테이킹을 유지하면서 검증자로 등록할 수 있어, 추가 자금 없이도 시뇨리지 수령이 가능합니다.

### Q2. 기존 스테이커가 검증자로 전환할 수 있나요?
**A**: 네. 기존 스테이킹을 유지하면서 `RAT.registerValidator()`를 호출하면 검증자로 등록되어 시뇨리지를 받을 수 있습니다.

### Q3. V3 업그레이드 후 시퀀서가 추가로 해야 할 일이 있나요?
**A**: 담보금이 기존 스테이킹으로 통합되므로, 별도 작업 없이 기존 스테이킹만 유지하면 됩니다. 단, 자격 조건(`T_i ≥ max(D_seq, θ·B_i)`)을 충족해야 시뇨리지를 받을 수 있습니다.

### Q4. 슬래싱 시 L2가 정지되지 않으면 보안에 문제가 없나요?
**A**: 경제적 제재(시뇨리지 중단 + 담보금 몰수)가 충분한 억제력을 제공합니다. 오히려 사용자 서비스 연속성이 보장되어 더 안정적입니다.

### Q5. `relaxedValidatorCheck`는 누가 언제 변경하나요?
**A**: DAO 거버넌스를 통해 변경할 수 있습니다. 검증자 수가 충분히 확보되면 보안 강화를 위해 `false`로 전환할 수 있습니다.

### Q6. V2 → V3 전환은 언제 일어나나요?
**A**: DAO 거버넌스가 `migrateToV3()`를 호출하면 즉시 V3 모드로 전환됩니다. 이후 모든 시뇨리지 분배는 V3 로직을 따릅니다.

### Q7. V3 전환 후 V2로 되돌릴 수 있나요?
**A**: 불가능합니다. `migrateToV3()` 실행 후에는 V2로 롤백할 수 없습니다. 컨트랙트에 `v3Migrated = false`로 변경하는 함수가 없으며, 이는 의도된 설계입니다.

---

## 부록: 주요 변경사항 요약

### 네트워크 가치
1. **L2 보안 강화**: 시퀀서에게 명확한 경제적 인센티브, 검증자 네트워크를 통한 상시 모니터링, RAT을 통한 검증자 참여 보장
2. **성과 기반 보상**: Bridged TON 기반으로 실제 기여도 반영, 쌍곡선 함수로 독과점 방지, 공정한 경쟁 환경 조성
3. **서비스 안정성 향상**: 슬래싱 시에도 L2 서비스 연속성 보장, 사용자 경험 개선

### 경제적 가치
1. **자본 효율성 향상**: 담보금과 스테이킹 통합으로 중복 예치 불필요, 시퀀서/검증자 진입 장벽 낮춤
2. **유연한 정책 운영**: `relaxedValidatorCheck`로 단계적 보안 강화, DAO 거버넌스를 통한 파라미터 조정

### 기술적 가치
1. **구조 단순화**: 컨트랙트 복잡도 감소, RAT 직접 예치 제거로 관리 포인트 축소, Coinage 기반 통합 설계
2. **거버넌스 강화**: DAO 중심 의사결정 구조, 투명한 파라미터 관리, 단계적 업그레이드 지원
3. **확장성 향상**: Multi-Sequencer 지원 준비, 향후 기능 추가 용이, 모듈화된 아키텍처

### 주의사항
1. **시뇨리지 분배 대상 변경**: 명확한 커뮤니케이션 필수, 충분한 사전 공지 기간 확보, 검증자 참여 방법 및 혜택 안내 필요
2. **검증자 네트워크 구축**: 초기 검증자 유치 전략 필요, `relaxedValidatorCheck` 운영 정책 수립, RAT 응답률 모니터링 체계 구축
3. **시퀀서 자격 관리**: Bridged TON 기반 자격 조건 모니터링, 자격 미달 L2 대응 방안 수립, 시뇨리지 예측 도구 제공
