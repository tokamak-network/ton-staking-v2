# 검증자 슬래싱

## 1. 개요

검증자가 RAT(Randomized Attention Test)에 응답하지 않으면 슬래싱됩니다. 이 문서는 검증자 슬래싱의 조건, 절차, 구현을 다룹니다.

> **참고**: 검증자 등록, 보상, RAT 시스템에 대한 상세 내용은 [04_validator.md](./04_validator.md)를 참조하세요.

### 백서 명시 내용

백서 **섹션 2.1.2. 검증자를 위한 경제적 보안** (PDF Page 10):

| 항목 | 백서 내용 |
|------|----------|
| **슬래싱 조건** | RAT 미응답 |
| **슬래싱 금액** | "full collateral slashing" (전체 담보금) |
| **슬래싱 후** | 즉시 예치금 보충 필요, 미충족 시 활성 검증자 세트에서 제거 |
| **반복 페널티** | 없음 (시퀀서와 달리 증가하는 페널티 미적용) |

**백서 원문:**
> "Slashing for validators is applied solely in the context of RAT. In alignment with the sequencer's collateral model, the protocol adopts full collateral slashing. When an attention test is issued with probability π_a, the selected validator must respond within the required time window. Failure to do so triggers a slashing event in which the full deposit is forfeited."

### 구현 방식: 선차감-복구 메커니즘

Optimism RAT.sol의 **선차감-복구 메커니즘**을 채택하되, 차감 금액은 백서대로 **전체 담보금**으로 합니다.

| 항목 | Optimism RAT | TON V3 RAT |
|------|-------------|------------|
| **트리거 시 차감** | perTestBondAmount | **전체 담보금 (depositedAmount)** |
| **증거 제출 시** | bondAmount 복구 | **전체 담보금 복구** |
| **미응답 시** | bondAmount 손실 | **전체 담보금 RAT 컨트랙트 귀속** |
| **별도 슬래싱 tx** | 불필요 | **완전히 불필요** |

**장점:**
- RAT 트리거 시 이미 담보금이 RAT 컨트랙트로 이전되어 있으므로, 미응답 시 **별도의 슬래싱 트랜잭션이 완전히 불필요**
- 가스비 절감 및 프로세스 간소화
- 백서의 "full collateral slashing" 원칙 준수

---

## 2. 슬래싱 메커니즘: 선이전-복구 방식

### 2.1 핵심 원리

RAT 트리거 시점에 **전체 담보금을 RAT 컨트랙트로 이전**합니다. 증거 제출 성공 시에만 복구하고, 미응답 시에는 **아무 조치도 필요 없습니다** (이미 RAT 컨트랙트에 귀속).

```
┌─────────────────────────────────────────────────────────────┐
│  1. RAT 트리거 (triggerAttentionTest)                        │
│     - 내부 기록: depositedAmount = 0 (선차감)                  │
│     - attentionTest.bondAmount = 전체 담보금                 │
│     - 검증자 비활성화 (isActive = false)                     │
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
    ┌─────────────────┐             ┌─────────────────┐
    │  담보금 복구     │             │  아무것도 안함  │
    │  RAT → 검증자   │             │  (이미 몰수됨)  │
    │  isActive = true│             │  RAT에 귀속     │
    └─────────────────┘             └─────────────────┘
```

### 2.2 각 단계별 상태 변화

| 단계 | 검증자 잔액 | RAT 컨트랙트 | isActive |
|------|------------|-------------|----------|
| **등록 후** | D_validator | - | true |
| **RAT 트리거** | 0 | +D_validator (bondAmount) | false |
| **증거 제출 성공** | D_validator (복구) | -D_validator | true |
| **미응답** | 0 | D_validator (귀속) | false |

### 2.3 장점

1. **미응답 시 별도 트랜잭션 완전 불필요**: 담보금이 이미 RAT 컨트랙트에 있으므로 슬래싱 완료
2. **가스비 대폭 절감**: `finalizeSlash()` 함수 자체가 불필요
3. **단순한 로직**: 증거 제출 성공 시에만 복구 처리

### 2.4 슬래싱된 담보금 활용

RAT 컨트랙트에 귀속된 담보금은 프로토콜 재무로 활용됩니다:
- 검증자 보상 풀로 재분배
- DAO 거버넌스 결정에 따라 활용
- 또는 컨트랙트에 누적 보관

> **참고**: 백서에서는 "the full deposit is forfeited"(전체 담보금 몰수)라고만 명시하고, 귀속처는 지정하지 않았습니다.

---

## 3. 구현: 선이전-복구 방식

### 3.1 RAT 트리거 시 (전체 스테이킹 금액 RAT 컨트랙트로 이전)

```solidity
/// @notice RAT 테스트 트리거 - 전체 스테이킹 금액 RAT 컨트랙트로 이전
function triggerAttentionTest(
    address systemConfig,
    uint32 batchIndex,
    bytes32 batchHash,
    bytes32 blockHash
) external onlyLayer2Manager {
    // ... 검증자 랜덤 선택 로직 ...

    address selectedValidator = validators[selectedIndex];
    bytes32 regId = _getRegistrationId(selectedValidator, systemConfig);
    ValidatorRegistration storage reg = registrations[regId];

    // ★ 전체 담보금 선차감 (백서: full collateral)
    // DepositManager의 실제 스테이킹은 RAT 명의로 유지, 내부 기록만 변경
    uint256 bondAmount = reg.depositedAmount;  // 전액
    reg.depositedAmount = 0;  // 내부 기록에서 차감

    // 검증자 비활성화
    reg.isActive = false;
    validatorPools[systemConfig].activeValidatorCount--;
    _removeFromActiveValidators(systemConfig, selectedValidator, reg.validatorIndex);

    // 테스트 정보 저장
    bytes32 testId = _getTestId(systemConfig, batchIndex);
    attentionTests[testId] = AttentionTest({
        expectedHash: batchHash,
        bondAmount: uint96(bondAmount),  // 복구용 금액 기록
        validatorAddress: selectedValidator,
        systemConfig: systemConfig,
        blockNumber: uint64(block.number),
        evidenceSubmitted: false
    });

    address layer2 = _getLayer2FromSystemConfig(systemConfig);
    emit AttentionTriggered(testId, systemConfig, layer2, selectedValidator, batchIndex);
}
```

### 3.2 증거 제출 성공 시 (담보금 복구)

```solidity
/// @notice 증거 제출 - 담보금 복구
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

    // ★ 전체 담보금 복구
    test.evidenceSubmitted = true;
    uint256 restoredAmount = uint256(test.bondAmount);

    bytes32 regId = _getRegistrationId(msg.sender, systemConfig);
    ValidatorRegistration storage reg = registrations[regId];
    reg.depositedAmount = restoredAmount;  // 내부 기록 복구

    // 검증자 재활성화
    reg.isActive = true;
    reg.validatorIndex = uint32(activeValidators[systemConfig].length);
    activeValidators[systemConfig].push(msg.sender);
    validatorPools[systemConfig].activeValidatorCount++;

    address layer2 = _getLayer2FromSystemConfig(systemConfig);
    emit EvidenceSubmitted(testId, systemConfig, layer2, msg.sender, restoredAmount);
}
```

### 3.3 미응답 시

**별도 함수 불필요** - RAT 트리거 시점에 이미 담보금이 RAT 컨트랙트로 이전되어 있으므로, 미응답 시 슬래싱이 자동 완료됩니다.

```
미응답 시 상태:
- 검증자.depositedAmount = 0 (이미 차감됨)
- 검증자.isActive = false (이미 비활성화됨)
- 담보금 = RAT 컨트랙트에 귀속 (프로토콜 재무)
- 추가 트랜잭션 = 없음
```

### 3.4 챌린지 승리 시 담보금 복구 (resolveClaim)

검증자가 프로포저의 잘못된 증거를 발견하고 **챌린저로서 FaultDisputeGame에서 승리**하면, 게임 컨트랙트가 `resolveClaim`을 호출하여 담보금을 복구합니다.

```
┌─────────────────────────────────────────────────────────────┐
│  RAT 트리거 → 검증자 담보금 선차감 → 비활성화                  │
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
│  담보금 복구 + 검증자 재활성화                                │
│  - depositedAmount 복구 (내부 기록)                         │
│  - isActive = true                                          │
└─────────────────────────────────────────────────────────────┘
```

```solidity
/// @notice FaultDisputeGame에서 게임 해결 시 호출 (챌린저 승리 시 담보금 복구)
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

    // ★ 담보금 복구
    test.evidenceSubmitted = true;
    uint256 restoredAmount = uint256(test.bondAmount);

    bytes32 regId = _getRegistrationId(_claimant, test.systemConfig);
    ValidatorRegistration storage reg = registrations[regId];
    reg.depositedAmount = restoredAmount;  // 내부 기록 복구

    // 검증자 재활성화
    reg.isActive = true;
    reg.validatorIndex = uint32(activeValidators[test.systemConfig].length);
    activeValidators[test.systemConfig].push(_claimant);
    validatorPools[test.systemConfig].activeValidatorCount++;

    address layer2 = _getLayer2FromSystemConfig(test.systemConfig);
    emit BondRefunded(testId, test.systemConfig, layer2, _claimant, restoredAmount);
}
```

**핵심 포인트:**
- `msg.sender`는 FaultDisputeGame 주소 (게임 컨트랙트가 직접 호출)
- `_claimant`는 게임에서 이긴 챌린저 주소
- RAT에서 선택된 검증자와 게임 승자가 같아야 담보금 복구
- `submitEvidence`와 동일한 효과: 담보금 복구 + 검증자 재활성화

---

## 4. 슬래싱 예시

### 4.1 시나리오

```
검증자 A (Titan L2에 등록):
- depositedAmount = 10,000 WTON
- pendingRewards = 500 WTON
- RAT 트리거됨 (batchIndex = 12345)
- evidenceSubmissionPeriod = 7200 블록 (~24시간)
```

### 4.2 RAT 트리거 (블록 1000)

```
triggerAttentionTest(titanSystemConfig, 12345, ...) 호출

상태 변화:
- A.depositedAmount: 10,000 → 0 (내부 기록에서 차감)
- attentionTest.bondAmount: 0 → 10,000 (컨트랙트 보관)
- A.isActive: true → false
- activeValidatorCount: n → n-1
```

### 4.3 증거 제출 성공 시

```
submitEvidence(titanSystemConfig, 12345, proofData) 호출

상태 변화:
- A.depositedAmount: 0 → 10,000 (내부 기록 복구)
- A.isActive: false → true
- activeValidatorCount: n-1 → n
```

### 4.4 미응답 시

```
응답 윈도우(7200 블록) 경과 후:

상태:
- A.depositedAmount: 0 (변경 없음, 이미 차감됨)
- A.isActive: false (변경 없음)
- 담보금 10,000 WTON: RAT 컨트랙트에 귀속
- 추가 트랜잭션: 없음
```

### 4.5 결과 비교

| 시나리오 | 검증자 A | RAT 컨트랙트 | 활성 검증자 수 |
|---------|---------|-------------|--------------|
| **증거 제출 성공** | 담보금 10,000 복구, 활성화 | 변동 없음 | 유지 |
| **미응답** | 담보금 10,000 손실, 비활성화 | +10,000 귀속 | -1 감소 |

---

## 5. 재등록

### 5.1 슬래싱 후 재등록 가능 여부

슬래싱된 검증자도 다시 등록할 수 있습니다:

```solidity
// 슬래싱 후 상태
validatorInfo[validator].isActive = false;
validatorInfo[validator].depositAmount = 0;

// 재등록 시
function registerValidator(uint256 depositAmount) external {
    require(!validatorInfo[msg.sender].isActive, "already registered");
    // isActive가 false이므로 재등록 가능
    ...
}
```

### 5.2 재등록 시 주의사항

- 새로운 담보금 필요 (최소 담보금 이상)
- 이전 슬래싱 기록은 남아있음 (추후 참고용)
- 미청구 보상은 복구되지 않음

---

## 6. 이벤트

선차감-복구 메커니즘에서 슬래싱은 별도 이벤트 없이 RAT 트리거 및 증거 제출 이벤트로 추적됩니다.

```solidity
/// @notice RAT 테스트 트리거 (스테이킹 금액 선차감)
event AttentionTriggered(
    bytes32 indexed testId,
    address indexed systemConfig,
    address indexed layer2,
    address validator,
    uint32 batchIndex
);

/// @notice 증거 제출 성공 (스테이킹 금액 복구)
event EvidenceSubmitted(
    bytes32 indexed testId,
    address indexed systemConfig,
    address indexed layer2,
    address validator,
    uint256 restoredAmount
);
```

**몰수된 자금 추적:**
- `AttentionTriggered` 발생 후 `EvidenceSubmitted`가 없으면 → 영구 몰수
- `AttentionTriggered` 발생 후 `EvidenceSubmitted`가 있으면 → 복구됨

---

## 7. 시퀀서 슬래싱과 비교

| 항목 | 시퀀서 슬래싱 | 검증자 슬래싱 |
|------|-------------|-------------|
| **슬래싱 조건** | Fraud proof 성공 | RAT 미응답 |
| **슬래싱 금액** | 전체 담보금 | 전체 담보금 |
| **슬래싱 방식** | 후처리 (별도 tx) | 선차감-복구 (별도 tx 불필요) |
| **챌린저 보상** | C_max + Δ/n | 없음 |
| **귀속처** | DAO | RAT 컨트랙트 |
| **담보금 형태** | 스테이킹 잔액 | 스테이킹 잔액 |
