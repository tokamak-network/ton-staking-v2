# 검증자 슬래싱

## 1. 개요

검증자가 RAT(Randomized Attention Test)에 응답하지 않으면 슬래싱됩니다. 이 문서는 검증자 슬래싱의 조건, 절차, 구현을 다룹니다.

> **참고**: 검증자 등록, 보상, RAT 시스템에 대한 상세 내용은 [04_validator.md](./04_validator.md)를 참조하세요.

### 백서 V2 명시 내용

백서 V2 **섹션 2.1.2. 검증자를 위한 경제적 보안** (PDF Page 11):

| 항목 | 백서 V2 내용 |
|------|----------|
| **슬래싱 조건** | RAT 미응답 |
| **슬래싱 금액** | **C_off** (슬래싱 페널티, 전체 담보금이 아님) |
| **슬래싱 후** | 잔액이 D_min 미만이면 **즉시 활성 검증자 세트에서 제거** |

**백서 V2 원문:**
> "Slashing for validators is applied solely in the context of RAT. When an attention test is triggered with probability π_a, the selected validator must respond within the required time window. Failure to do so triggers a slashing event in which a penalty C_off is deducted from the validator's deposit. If the remaining deposit falls below the minimum threshold D_min, the validator must replenish it within a specified period; otherwise, the validator is removed from the active validator set."

**구현 해석:**
백서의 "within a specified period"는 증거 제출 기간을 의미하며, 별도의 담보금 보충 기간을 두지 않습니다. D_min 미만 시 **즉시 활성 검증자 세트에서 제거**하여 관리 복잡도를 낮추고, 재등록을 원하면 D_min 이상 되도록 추가 예치하여 `registerValidator()`를 호출하도록 합니다.

### 백서 V2 핵심 공식

```
c_m ≤ (π_a / N) · C_off               ... (3) RAT 균형 조건
C_off ≥ (c_m · N) / π_a               ... (4) 최소 슬래싱 페널티
D_validator = C_off + Δ_validator      ... (5) 실제 담보금
```

### 구현 방식: C_off 기반 선차감-복구 메커니즘

**선차감-복구 메커니즘**을 사용하며, 차감 금액은 **C_off (슬래싱 페널티)**입니다.

| 항목 | TON V3 RAT |
|------|-----------|
| **트리거 시 차감** | C_off |
| **증거 제출 시** | C_off 복구 |
| **미응답 시** | C_off 몰수 + D_min 확인 |
| **잔액 < D_min 시** | 즉시 활성 검증자 세트에서 제거 |

**장점:**
- 단일 미응답에 전체 담보금을 잃지 않음 (점진적 페널티)
- 관리 복잡도 최소화 (별도 보충 트랜잭션 불필요)
- 백서 V2의 C_off/D_min 설계 준수
- 제거된 검증자는 잔액을 클레임하여 출금 가능 (재등록 시 D_min 이상 되도록 추가 예치 필요)

---

## 2. 슬래싱 메커니즘: C_off 기반 선차감-복구 방식

### 2.1 핵심 원리

RAT 트리거 시점에 **C_off만 선차감**합니다. 증거 제출 성공 시 C_off를 복구하고, 미응답 시에는 별도 트랜잭션 없이 이미 차감된 상태로 유지됩니다. 잔액이 D_min 미만이면 **즉시 활성 검증자 세트에서 제거**됩니다.

```
┌─────────────────────────────────────────────────────────────┐
│  1. RAT 트리거 (triggerAttentionTest)                        │
│     - depositedAmount -= C_off (선차감)                      │
│     - totalBondForRAT += C_off                              │
│     - latestTestDeadline 업데이트                            │
│     - D_min 확인 → 미만이면 즉시 제거 + ValidatorSlashed     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  2. 응답 윈도우 (evidenceSubmissionPeriod)                   │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
    ┌─────────────────┐             ┌─────────────────┐
    │  증거 제출 성공  │             │  미응답         │
    │  submitEvidence │             │  deadline 경과  │
    └─────────────────┘             └─────────────────┘
              │                               │
              ▼                               ▼
    ┌─────────────────┐             ┌─────────────────────────┐
    │  C_off 복구      │             │  (아무것도 안 함)        │
    │  + D_min 이상이면│             │  이미 차감되어 있음      │
    │  ValidatorRestored│            │  Lazy Evaluation        │
    └─────────────────┘             └─────────────────────────┘
                                              │
                                              ▼
                                    ┌─────────────────────────┐
                                    │  출금 시 (deactivate)    │
                                    │  latestTestDeadline 경과 │
                                    │  확인 후 totalBondForRAT │
                                    │  손실 확정               │
                                    └─────────────────────────┘
```

### 2.2 각 단계별 상태 변화

| 단계 | depositedAmount | totalBondForRAT | isActive |
|------|-----------------|-----------------|----------|
| **등록 후** | D_validator | 0 | true |
| **RAT 트리거 (D_min 이상)** | D_validator - C_off | C_off | true |
| **RAT 트리거 (D_min 미만)** | D_validator - C_off | C_off | **false** (즉시 제거) |
| **증거 제출 성공** | D_validator | 0 | true (복구 가능) |
| **미응답 후 출금** | D_validator - C_off | 0 (손실 확정) | false |

### 2.3 장점

1. **점진적 페널티**: 단일 미응답에 전체 담보금을 잃지 않음
2. **간단한 관리**: D_min 미만 시 즉시 제거 (별도 트랜잭션 불필요)
3. **공정한 처리**: 제거 시 잔액은 검증자가 클레임하여 출금 가능
4. **백서 V2 준수**: C_off/D_min 설계 정확히 구현

### 2.4 출금 조건 및 금액 계산

**출금 조건:**
```solidity
// deactivateValidator() 호출 시
require(block.timestamp >= reg.latestTestDeadline, "pending RAT tests");
```

- `latestTestDeadline`: 가장 최근 RAT 테스트의 마감 시간
- deadline 경과 전에는 출금 불가 (증거 제출 기회 보장)
- deadline 경과 후 `totalBondForRAT > 0`이면 손실 확정 → `accumulatedSlashings`로 이동

**출금 금액 계산:**
```
출금 가능 금액 = depositedAmount × (currentFactor / coinageFactorAtDeposit)
```

- `depositedAmount`: 현재 유효 담보금 (슬래싱으로 차감된 후 금액)
- `totalBondForRAT`: 미응답한 테스트의 담보금 (출금 시 손실 확정)

**몰수된 담보금 처리**: `accumulatedSlashings`에 누적 → Treasury로 전송

---

## 3. 구현: C_off 기반 선차감-복구 방식

### 3.1 RAT 트리거 시 (C_off만 선차감)

```solidity
/// @notice RAT 테스트 트리거 - C_off만 선차감
function triggerAttentionTest(
    address gameAddress,
    address systemConfig,
    uint32 batchIndex,
    bytes32 batchHash,
    bytes32 blockHash
) external onlyValidFactory whenNotPaused {
    // ... 검증자 랜덤 선택 로직 ...

    ValidatorRegistration storage reg = validatorRegistrations[systemConfig][selectedValidator];

    // ★ C_off만 선차감 (백서 V2: C_off 슬래싱)
    uint256 bondAmount = slashingPenalty;
    if (reg.depositedAmount < bondAmount) {
        bondAmount = reg.depositedAmount;  // 잔액이 C_off 미만이면 전액
    }
    reg.depositedAmount -= bondAmount;
    reg.totalBondForRAT += bondAmount;

    // 테스트 정보 저장
    bytes32 testId = keccak256(abi.encodePacked(systemConfig, batchIndex, selectedValidator, block.timestamp));
    uint256 deadline = block.timestamp + evidenceSubmissionPeriod;

    // ★ 최신 테스트 마감 시간 업데이트 (출금 조건 체크용)
    if (uint64(deadline) > reg.latestTestDeadline) {
        reg.latestTestDeadline = uint64(deadline);
    }

    // ★ D_min 확인 - 잔액이 D_min 미만이면 즉시 검증자 세트에서 제거
    bool removedFromSet = false;
    if (reg.depositedAmount < minimumThreshold) {
        _removeValidator(systemConfig, selectedValidator, reg);
        removedFromSet = true;
    }

    // ... AttentionTest 저장 ...

    emit AttentionTestTriggered(testId, selectedValidator, systemConfig, gameAddress, batchIndex, deadline);

    // D_min 미만으로 제거된 경우 슬래싱 이벤트 발생
    if (removedFromSet) {
        emit ValidatorSlashed(testId, selectedValidator, systemConfig, bondAmount, true);
    }
}
```

### 3.2 증거 제출 성공 시 (C_off 복구)

```solidity
/// @notice 증거 제출 - C_off 복구
function submitEvidence(
    address systemConfig,
    uint32 batchIndex,
    bytes calldata evidence
) external ifFree whenNotPaused {
    bytes32 testId = batchToTestId[systemConfig][batchIndex];
    AttentionTest storage test = attentionTests[testId];

    // 검증
    if (test.validatorAddress != msg.sender) revert NotSelectedValidatorError();
    if (test.status != AttentionTestStatus.Pending) revert TestAlreadyRespondedError();
    if (block.timestamp > test.deadline) revert DeadlinePassedError();

    // 증거 검증 (TODO: 실제 증거 검증 로직)
    _verifyEvidence(test.batchHash, evidence);

    // ★ C_off 복구
    ValidatorRegistration storage reg = validatorRegistrations[systemConfig][msg.sender];
    reg.depositedAmount += test.bondAmount;
    reg.totalBondForRAT -= test.bondAmount;

    test.status = AttentionTestStatus.Responded;
    activeTestCount[systemConfig]--;

    // ★ 검증자 세트 복구 - 비활성 상태였고 D_min 이상이면 다시 추가
    if (!reg.isActive && reg.depositedAmount >= minimumThreshold) {
        _restoreValidator(systemConfig, msg.sender, reg);
        emit ValidatorRestored(msg.sender, systemConfig);
    }

    emit EvidenceSubmitted(testId, msg.sender, systemConfig, batchIndex);
}
```

### 3.3 미응답 시 (Lazy Evaluation)

**선차감-복구 방식**이므로 미응답 시 별도의 슬래싱 함수가 필요 없습니다.

```
미응답 시 상태:
- depositedAmount: 변경 없음 (RAT 트리거 시점에 이미 C_off 차감됨)
- totalBondForRAT: 그대로 유지 (출금 시점에 손실 확정)
- 별도 트랜잭션: 불필요 (Lazy Evaluation)
- deadline 경과 후 submitEvidence 호출 시 → DeadlinePassedError
```

**출금 시점에 손실 확정 (deactivateValidator):**
```solidity
function deactivateValidator(address systemConfig) external ifFree {
    ValidatorRegistration storage reg = validatorRegistrations[systemConfig][msg.sender];

    // ★ 진행 중인 RAT 테스트가 있으면 대기 (deadline 경과 후에만 출금 가능)
    require(block.timestamp >= reg.latestTestDeadline, "pending RAT tests");

    // ★ 미응답한 RAT 테스트의 totalBondForRAT는 손실 확정 (Lazy Evaluation)
    if (reg.totalBondForRAT > 0) {
        accumulatedSlashings += reg.totalBondForRAT;
        reg.totalBondForRAT = 0;
    }

    // ... 출금 처리 ...
}
```

**D_min 확인 시점:**
- RAT 트리거 시점에 D_min 미만이면 즉시 검증자 세트에서 제거 + `ValidatorSlashed` 이벤트
- 출금 시점에는 이미 비활성화 상태
- 재등록 원할 시: D_min 이상 되도록 추가 예치 후 `registerValidator()` 호출

### 3.4 챌린지 승리 시 담보금 복구 (resolveClaim)

검증자가 프로포저의 잘못된 증거를 발견하고 **챌린저로서 FaultDisputeGame에서 승리**하면, 게임 컨트랙트가 `resolveClaim`을 호출하여 담보금을 복구합니다.

```
┌─────────────────────────────────────────────────────────────┐
│  RAT 트리거 → 검증자 C_off 선차감                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  검증자가 프로포저의 잘못된 Output Root 발견                  │
│  → FaultDisputeGame에서 챌린지 제기 (챌린저 역할)             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  게임 해결 - 검증자(챌린저) 승리                              │
│  FaultDisputeGame.resolveClaim() → RAT.resolveClaim(winner) │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  C_off 복구                                                  │
│  - depositedAmount += C_off                                 │
│  - totalBondForRAT -= C_off                                 │
└─────────────────────────────────────────────────────────────┘
```

```solidity
/// @notice FaultDisputeGame에서 게임 해결 시 호출 (챌린저 승리 시 C_off 복구)
/// @param _claimant 게임에서 이긴 주소 (챌린저)
/// @dev msg.sender = FaultDisputeGame 주소
function resolveClaim(address _claimant) external {
    // msg.sender = 게임 주소, 유효한 게임인지 확인
    if (factoryByGame[msg.sender] == address(0)) return;

    // msg.sender = 게임 주소로 테스트 조회
    bytes32 testId = gameToTestId[msg.sender];
    if (testId == bytes32(0)) return;  // 해당 게임의 RAT 테스트가 없음

    AttentionTest storage test = attentionTests[testId];

    // 선택된 검증자가 게임 승자와 같은지 확인
    if (test.validatorAddress != _claimant) return;
    if (test.status != AttentionTestStatus.Pending) return;  // 이미 처리됨

    // ★ C_off 복구
    test.status = AttentionTestStatus.Responded;
    activeTestCount[test.systemConfig]--;

    ValidatorRegistration storage reg = validatorRegistrations[test.systemConfig][_claimant];

    // 잔액 복구
    uint256 restoredAmount = test.bondAmount;
    reg.depositedAmount += restoredAmount;
    reg.totalBondForRAT -= restoredAmount;

    // ★ 검증자 세트 복구 - 비활성 상태였고 D_min 이상이면 다시 추가
    if (!reg.isActive && reg.depositedAmount >= minimumThreshold) {
        _restoreValidator(test.systemConfig, _claimant, reg);
        emit ValidatorRestored(_claimant, test.systemConfig);
    }

    emit BondRestored(testId, _claimant, test.systemConfig, restoredAmount);
}
```

**핵심 포인트:**
- `msg.sender`는 FaultDisputeGame 주소 (게임 컨트랙트가 직접 호출)
- `factoryByGame` 검증으로 유효한 게임인지 확인
- `_claimant`는 게임에서 이긴 챌린저 주소
- RAT에서 선택된 검증자와 게임 승자가 같아야 C_off 복구
- `submitEvidence`와 동일한 효과: C_off 복구 + 검증자 세트 복구 + `ValidatorRestored` 이벤트

---

## 4. 슬래싱 예시

### 4.1 시나리오

```
검증자 A (Titan L2에 등록):
- depositedAmount = 10,000 WTON
- pendingRewards = 500 WTON
- C_off = 2,000 WTON (슬래싱 페널티)
- D_min = 3,000 WTON (최소 임계값)
- RAT 트리거됨 (batchIndex = 12345)
- evidenceSubmissionPeriod = 7200 블록 (~24시간)
```

### 4.2 RAT 트리거 (블록 1000)

```
triggerAttentionTest(titanSystemConfig, 12345, ...) 호출

상태 변화:
- A.depositedAmount: 10,000 → 8,000 (C_off 선차감)
- A.totalBondForRAT: 0 → 2,000
- attentionTest.bondAmount: 0 → 2,000
- A.isActive: true (유지)
```

### 4.3 증거 제출 성공 시

```
submitEvidence(titanSystemConfig, 12345, proofData) 호출

상태 변화:
- A.depositedAmount: 8,000 → 10,000 (C_off 복구)
- A.totalBondForRAT: 2,000 → 0
```

### 4.4 미응답 시 (잔액 >= D_min)

```
응답 윈도우 경과 후 (별도 트랜잭션 불필요 - Lazy Evaluation)

상태:
- A.depositedAmount: 8,000 (변경 없음, RAT 트리거 시 이미 차감됨)
- A.totalBondForRAT: 2,000 (변경 없음, 출금 시 손실 확정)
- A.isActive: true (8,000 >= D_min 이므로 활성 유지)
- A.latestTestDeadline: block.timestamp + evidenceSubmissionPeriod

출금 시 (deactivateValidator 호출):
- latestTestDeadline 이후에만 출금 가능
- totalBondForRAT 2,000은 accumulatedSlashings로 이동 (손실 확정)
```

### 4.5 연속 미응답 시 (잔액 < D_min → 즉시 제거)

```
4번 연속 RAT 트리거 후:
- 초기: 10,000 WTON
- 1차 트리거: 10,000 - 2,000 = 8,000 (>= D_min, 활성 유지)
- 2차 트리거: 8,000 - 2,000 = 6,000 (>= D_min, 활성 유지)
- 3차 트리거: 6,000 - 2,000 = 4,000 (>= D_min, 활성 유지)
- 4차 트리거: 4,000 - 2,000 = 2,000 (< D_min, 즉시 제거!)

triggerAttentionTest 호출 시 (4차):
- A.depositedAmount: 4,000 → 2,000 (C_off 선차감)
- A.depositedAmount < D_min 확인
- ★ 즉시 검증자 세트에서 제거
  - A.isActive: false
  - _removeValidator() 호출
  - ValidatorSlashed 이벤트 발생
- 잔액 2,000 WTON: latestTestDeadline 이후 출금 가능

재등록 희망 시:
- D_min 이상 되도록 추가 예치 후 registerValidator() 호출
```

### 4.6 결과 비교

| 시나리오 | depositedAmount | 슬래싱 금액 | 활성 상태 |
|---------|----------------|------------|----------|
| **증거 제출 성공** | 10,000 (복구) | 0 | 활성 유지 |
| **미응답 (1회)** | 8,000 | 2,000 | 활성 유지 |
| **미응답 (4회, D_min 미만)** | 2,000 (반환) | 8,000 | 즉시 비활성화 |

---

## 5. 재등록

### 5.1 슬래싱 후 재등록 가능 여부

D_min 미만으로 제거된 검증자도 추가 예치하여 다시 등록할 수 있습니다:

```solidity
// D_min 미만으로 제거된 후 상태
reg.isActive = false;
reg.depositedAmount = 2,000;  // 잔액 유지

// 재등록 시: 추가 예치하여 D_min 이상이 되면 등록 가능
function registerValidator(address systemConfig, uint256 amount) external {
    // 비활성 상태이고 latestTestEndBlock 이후면 재등록 허용
    // 기존 depositedAmount + 신규 amount >= D_min 이면 등록 성공

    reg.depositedAmount += amount;
    reg.coinageFactorAtDeposit = currentFactor;  // factor 현행화
    reg.isActive = true;
    ...
}
```

### 5.2 재등록 시 시뇨리지 처리

재등록 시 `coinageFactorAtDeposit`을 현재 factor로 갱신합니다. **기존 잔액에 대한 시뇨리지는 포기**됩니다.

```
예시:
- 기존 예치: 2,000 WTON, factor = 1.0
- 현재 factor = 1.1 (10% 시뇨리지 발생)
- 원래 받을 수 있는 금액: 2,000 × 1.1 = 2,200 WTON

재등록 시:
- 추가 예치: 1,500 WTON
- 새 depositedAmount = 2,000 + 1,500 = 3,500 WTON
- coinageFactorAtDeposit = 1.1 (현재 factor로 갱신)

출금 시 (factor = 1.2):
- 출금 금액 = 3,500 × (1.2 / 1.1) = 3,818 WTON
- 기존 2,000에 대한 시뇨리지 200 WTON은 받지 못함
```

### 5.3 재등록 시 주의사항

- 기존 잔액 + 추가 예치 >= D_min 이어야 함
- latestTestDeadline 이후에만 재등록 가능 (진행 중인 RAT 테스트 종료 후)
- **기존 잔액에 대한 시뇨리지는 포기됨** (factor 현행화)
- 미청구 보상은 별도 청구 필요 (claimRewards)

---

## 6. 이벤트

C_off 기반 선차감-복구 메커니즘의 이벤트:

```solidity
/// @notice RAT 테스트 트리거 (C_off 선차감)
event AttentionTestTriggered(
    bytes32 indexed testId,
    address indexed validator,
    address indexed systemConfig,
    address gameAddress,
    uint32 batchIndex,
    uint256 deadline
);

/// @notice D_min 미만으로 검증자 세트에서 제거됨
event ValidatorSlashed(
    bytes32 indexed testId,
    address indexed validator,
    address indexed systemConfig,
    uint256 slashedAmount,
    bool removedFromSet
);

/// @notice 증거 제출 성공 (C_off 복구)
event EvidenceSubmitted(
    bytes32 indexed testId,
    address indexed validator,
    address indexed systemConfig,
    uint32 batchIndex
);

/// @notice 챌린지 승리로 C_off 복구
event BondRestored(
    bytes32 indexed testId,
    address indexed validator,
    address indexed systemConfig,
    uint256 restoredAmount
);

/// @notice 검증자 세트 복구 (D_min 미만 제거 후 복구)
event ValidatorRestored(
    address indexed validator,
    address indexed systemConfig
);
```

**이벤트 흐름:**

| 상황 | 이벤트 |
|------|--------|
| 검증자 등록 | `ValidatorRegistered` |
| RAT 트리거 | `AttentionTestTriggered` |
| D_min 미만 제거 | `ValidatorSlashed` |
| 증거 제출 성공 | `EvidenceSubmitted` |
| 챌린지 승리 | `BondRestored` |
| 검증자 세트 복구 | `ValidatorRestored` |
| 검증자 탈퇴 | `ValidatorDeactivated` |

**자금 추적 (Lazy Evaluation):**
- `AttentionTestTriggered` 발생 → C_off 선차감 완료
- `ValidatorSlashed` 발생 → D_min 미만으로 검증자 제거 (C_off 손실 예정)
- `EvidenceSubmitted` 또는 `BondRestored` 발생 → C_off 복구
- `ValidatorRestored` 발생 → 검증자 세트에 다시 추가됨
- 복구 이벤트 없이 `latestTestDeadline` 경과 → 출금 시 C_off 몰수 확정

---

## 7. 시퀀서 슬래싱과 비교

| 항목 | 시퀀서 슬래싱 | 검증자 슬래싱 (백서 V2) |
|------|-------------|------------------------|
| **슬래싱 조건** | Fraud proof 성공 | RAT 미응답 |
| **슬래싱 금액** | 전체 담보금 | **C_off** (페널티 금액) |
| **슬래싱 방식** | 후처리 (별도 tx) | C_off 선차감-복구 |
| **임계값 확인** | 없음 | **D_min 확인** |
| **D_min 미만 시** | 해당 없음 | **즉시 활성 검증자 세트에서 제거** |
| **챌린저 보상** | C_max + Δ/n | 없음 |
| **귀속처** | DAO | TBD (미정) |
| **담보금 형태** | 스테이킹 잔액 | RAT 대리 스테이킹 잔액 |
| **담보금 시뇨리지** | V3: 없음 (스테이커 시뇨리지 폐지) | V3: 없음 (담보금 시뇨리지 없음) |
| **잔액 처리** | 없음 | D_min 미만 제거 시 잔액(원금) 클레임 가능 |
