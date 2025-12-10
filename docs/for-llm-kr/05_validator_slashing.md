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
| **반복 페널티** | 없음 (시퀀서와 달리 증가하는 페널티 미적용) |

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

Optimism RAT.sol의 **선차감-복구 메커니즘**을 채택하며, 차감 금액은 **C_off (슬래싱 페널티)**입니다.

| 항목 | Optimism RAT | TON V3 RAT (백서 V2) |
|------|-------------|----------------------|
| **트리거 시 차감** | perTestBondAmount | **C_off** |
| **증거 제출 시** | bondAmount 복구 | **C_off 복구** |
| **미응답 시** | bondAmount 손실 | **C_off 몰수 + D_min 확인** |
| **잔액 < D_min 시** | - | **즉시 활성 검증자 세트에서 제거** |

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
│     - attentionTest.bondAmount = C_off                      │
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
    │  depositedAmount│             │  이미 차감되어 있음      │
    │  += C_off       │             └─────────────────────────┘
    │  totalBondForRAT│                       │
    │  -= C_off       │                       ▼
    └─────────────────┘             ┌─────────────────────────┐
                                    │  잔액 확인               │
                                    │  depositedAmount vs D_min│
                                    └─────────────────────────┘
                                              │
                              ┌───────────────┴───────────────┐
                              ▼                               ▼
                    ┌─────────────────┐             ┌─────────────────┐
                    │ >= D_min        │             │ < D_min         │
                    │ 활성 상태 유지   │             │ 즉시 검증자 제거 │
                    └─────────────────┘             │ (잔액 클레임 가능)│
                                                    └─────────────────┘
```

### 2.2 각 단계별 상태 변화

| 단계 | depositedAmount | totalBondForRAT | isActive |
|------|-----------------|-----------------|----------|
| **등록 후** | D_validator | 0 | true |
| **RAT 트리거** | D_validator - C_off | C_off | true |
| **증거 제출 성공** | D_validator | 0 | true |
| **미응답 (잔액 >= D_min)** | D_validator - C_off | 0 (테스트 종료 후) | true |
| **미응답 (잔액 < D_min)** | (클레임 대기) | 0 | **false** (즉시 제거) |

### 2.3 장점

1. **점진적 페널티**: 단일 미응답에 전체 담보금을 잃지 않음
2. **간단한 관리**: D_min 미만 시 즉시 제거 (별도 트랜잭션 불필요)
3. **공정한 처리**: 제거 시 잔액은 검증자가 클레임하여 출금 가능
4. **백서 V2 준수**: C_off/D_min 설계 정확히 구현

### 2.4 출금 금액 계산

```
출금 가능 금액 = depositedAmount × (currentFactor / coinageFactorAtDeposit)
```

- `depositedAmount`: 현재 유효 담보금 (슬래싱으로 차감된 후 금액)
- `coinageFactorAtDeposit`: 예치 시점의 coinage factor
- `currentFactor`: 출금 시점의 coinage factor
- `totalBondForRAT`: 출금 시점에 0이 아니면 latestTestEndBlock 블록이 지나야 출금가능

**몰수된 담보금 처리**: 몰수된 원금 + 시뇨리지의 사용처는 **TBD** (미정)

---

## 3. 구현: C_off 기반 선차감-복구 방식

### 3.1 RAT 트리거 시 (C_off만 선차감)

```solidity
/// @notice RAT 테스트 트리거 - C_off만 선차감
function triggerAttentionTest(
    address systemConfig,
    uint32 batchIndex,
    bytes32 batchHash,
    bytes32 blockHash
) external onlyAuthorizedTrigger {
    // ... 검증자 랜덤 선택 로직 ...

    address selectedValidator = validators[selectedIndex];
    bytes32 regId = _getRegistrationId(selectedValidator, systemConfig);
    ValidatorRegistration storage reg = registrations[regId];

    // ★ C_off만 선차감 (백서 V2: C_off 슬래싱)
    uint256 slashAmount = slashingPenalty;
    if (reg.depositedAmount < slashAmount) {
        slashAmount = reg.depositedAmount;  // 잔액이 C_off 미만이면 전액
    }
    reg.depositedAmount -= slashAmount;
    reg.totalBondForRAT += slashAmount;

    // ★ 최신 테스트 종료 블록 업데이트 (출금 조건 체크용)
    uint64 testEndBlock = uint64(block.number + evidenceSubmissionPeriod);
    if (testEndBlock > reg.latestTestEndBlock) {
        reg.latestTestEndBlock = testEndBlock;
    }

    // ★ D_min 확인 - 잔액이 D_min 미만이면 즉시 검증자 세트에서 제거
    if (reg.depositedAmount < minimumThreshold) {
        reg.isActive = false;
        validatorPools[systemConfig].activeValidatorCount--;
        _removeFromActiveValidators(systemConfig, selectedValidator, reg.validatorIndex);
    }

    // 테스트 정보 저장
    bytes32 testId = _getTestId(systemConfig, batchIndex);
    attentionTests[testId] = AttentionTest({
        expectedHash: batchHash,
        bondAmount: uint96(slashAmount),  // 복구용 금액 기록 (C_off)
        validatorAddress: selectedValidator,
        systemConfig: systemConfig,
        blockNumber: uint64(block.number),
        evidenceSubmitted: false
    });

    address layer2 = _getLayer2FromSystemConfig(systemConfig);
    emit AttentionTriggered(testId, systemConfig, layer2, selectedValidator, batchIndex);
}
```

### 3.2 증거 제출 성공 시 (C_off 복구)

```solidity
/// @notice 증거 제출 - C_off 복구
function submitEvidence(
    address systemConfig,
    uint32 batchIndex,
    bytes calldata proofData
) external {
    bytes32 testId = _getTestId(systemConfig, batchIndex);
    AttentionTest storage test = attentionTests[testId];

    // 검증
    if (test.validatorAddress != msg.sender) revert NotSelectedValidator();
    if (test.evidenceSubmitted) revert EvidenceAlreadySubmitted();

    uint256 deadline = test.blockNumber + evidenceSubmissionPeriod;
    if (block.number > deadline) revert EvidenceSubmissionExpired();

    // 증거 검증
    if (keccak256(proofData) != test.expectedHash) revert ProofVerificationFailed();

    // ★ C_off 복구
    test.evidenceSubmitted = true;
    uint256 restoredAmount = uint256(test.bondAmount);

    bytes32 regId = _getRegistrationId(msg.sender, systemConfig);
    ValidatorRegistration storage reg = registrations[regId];

    // 잔액 복구
    reg.depositedAmount += restoredAmount;
    reg.totalBondForRAT -= restoredAmount;

    // ★ 검증자 세트 복구 - 비활성 상태였고 D_min 이상이면 다시 추가
    if (!reg.isActive && reg.depositedAmount >= minimumThreshold) {
        reg.isActive = true;
        reg.validatorIndex = uint32(activeValidators[systemConfig].length);
        activeValidators[systemConfig].push(msg.sender);
        validatorPools[systemConfig].activeValidatorCount++;
    }

    address layer2 = _getLayer2FromSystemConfig(systemConfig);
    emit EvidenceSubmitted(testId, systemConfig, layer2, msg.sender, restoredAmount);
}
```

### 3.3 미응답 시 (Lazy Evaluation)

**선차감-복구 방식**이므로 미응답 시 별도의 `finalizeSlash` 함수가 필요 없습니다.

```
미응답 시 상태:
- depositedAmount: 변경 없음 (RAT 트리거 시점에 이미 C_off 차감됨)
- totalBondForRAT: 변경 없음 (출금 시점에 자동 처리)
- 별도 트랜잭션: 불필요 (lazy evaluation)

출금 시점에 처리:
- latestTestEndBlock 이후에만 출금 가능
- 출금 금액 = depositedAmount × (currentFactor / coinageFactorAtDeposit)
```

**D_min 확인 시점:**
- 출금 요청 시 `depositedAmount < D_min`이면 검증자는 이미 비활성화 상태
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
    // msg.sender = 게임 주소로 테스트 조회
    bytes32 testId = gameToTestId[msg.sender];
    if (testId == bytes32(0)) return;  // 해당 게임의 RAT 테스트가 없음

    AttentionTest storage test = attentionTests[testId];

    // 선택된 검증자가 게임 승자와 같은지 확인
    if (test.validatorAddress != _claimant) return;
    if (test.evidenceSubmitted) return;  // 이미 처리됨

    // ★ C_off 복구
    test.evidenceSubmitted = true;
    uint256 restoredAmount = uint256(test.bondAmount);

    bytes32 regId = _getRegistrationId(_claimant, test.systemConfig);
    ValidatorRegistration storage reg = registrations[regId];

    // 잔액 복구
    reg.depositedAmount += restoredAmount;
    reg.totalBondForRAT -= restoredAmount;

    // ★ 검증자 세트 복구 - 비활성 상태였고 D_min 이상이면 다시 추가
    if (!reg.isActive && reg.depositedAmount >= minimumThreshold) {
        reg.isActive = true;
        reg.validatorIndex = uint32(activeValidators[test.systemConfig].length);
        activeValidators[test.systemConfig].push(_claimant);
        validatorPools[test.systemConfig].activeValidatorCount++;
    }

    address layer2 = _getLayer2FromSystemConfig(test.systemConfig);
    emit BondRefunded(testId, test.systemConfig, layer2, _claimant, restoredAmount);
}
```

**핵심 포인트:**
- `msg.sender`는 FaultDisputeGame 주소 (게임 컨트랙트가 직접 호출)
- `_claimant`는 게임에서 이긴 챌린저 주소
- RAT에서 선택된 검증자와 게임 승자가 같아야 C_off 복구
- `submitEvidence`와 동일한 효과: C_off 복구 + 검증자 세트 복구

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
응답 윈도우 경과 후 (별도 트랜잭션 불필요 - lazy evaluation)

상태:
- A.depositedAmount: 8,000 (변경 없음, RAT 트리거 시 이미 차감됨)
- A.totalBondForRAT: 2,000 (변경 없음)
- A.isActive: true (8,000 >= D_min 이므로 활성 유지)
- A.latestTestEndBlock: block.number + evidenceSubmissionPeriod

출금 시:
- latestTestEndBlock 이후에만 출금 가능
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
  - 활성 검증자 목록에서 제거
- 잔액 2,000 WTON: latestTestEndBlock 이후 출금 가능

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
- latestTestEndBlock 이후에만 재등록 가능 (진행 중인 RAT 테스트 종료 후)
- **기존 잔액에 대한 시뇨리지는 포기됨** (factor 현행화)
- 미청구 보상은 별도 청구 필요 (claimRewards)

---

## 6. 이벤트

C_off 기반 선차감-복구 메커니즘의 이벤트:

```solidity
/// @notice RAT 테스트 트리거 (C_off 선차감)
/// @dev D_min 미만 시 검증자 세트에서 제거됨
event AttentionTriggered(
    bytes32 indexed testId,
    address indexed systemConfig,
    address indexed layer2,
    address validator,
    uint32 batchIndex,
    uint256 bondAmount,       // 차감된 본드 금액 (C_off 또는 잔액 전액)
    bool removedFromSet       // D_min 미만으로 제거되었는지 여부
);

/// @notice 증거 제출 성공 (C_off 복구)
/// @dev 비활성 상태였고 D_min 이상이면 검증자 세트에 복구됨
event EvidenceSubmitted(
    bytes32 indexed testId,
    address indexed systemConfig,
    address indexed layer2,
    address validator,
    uint256 restoredAmount,
    bool restoredToSet        // 검증자 세트에 복구되었는지 여부
);

/// @notice 챌린지 승리로 C_off 복구
event BondRefunded(
    bytes32 indexed testId,
    address indexed systemConfig,
    address indexed layer2,
    address validator,
    uint256 restoredAmount,
    bool restoredToSet        // 검증자 세트에 복구되었는지 여부
);
```

**자금 추적 (Lazy Evaluation):**
- `AttentionTriggered` 발생 → C_off 선차감 완료
- `EvidenceSubmitted` 또는 `BondRefunded` 발생 → C_off 복구
- 위 이벤트 없이 `latestTestEndBlock` 경과 → C_off 몰수 (별도 이벤트 없음)

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
| **시뇨리지** | 스테이커에게 지급 | 유지된 담보금만 검증자에게 지급, 몰수분은 TBD |
| **잔액 처리** | 없음 | D_min 미만 제거 시 잔액 클레임 가능 |
