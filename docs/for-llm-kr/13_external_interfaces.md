# 외부 인터페이스

## 1. 개요

이 문서는 TON Staking V3 시스템에서 **외부 컨트랙트가 호출해야 하는 인터페이스**를 정리합니다. 각 인터페이스는 호출 주체, 호출 시점, 파라미터를 명시합니다.

---

## 2. SeigManager 외부 인터페이스

### 2.1 Bridged TON 변경 알림

```solidity
/// @notice L2의 Bridged TON(TVL) 변경 시 호출
/// @dev L1Bridge에서 TON 입금/출금 시 호출해야 함
/// @param layer2 L2 주소 (candidate)
/// @param newBridgedTON 새로운 Bridged TON 양
function onBridgedTONChange(address layer2, uint256 newBridgedTON) external;
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | L1Bridge, L1BridgeRegistry |
| **호출 시점** | TON 입금/출금 완료 후 |
| **접근 제어** | `onlyL1BridgeOrRegistry` |
| **영향** | `totalEffectiveBridgedTON` 갱신, L2 자격 재평가 |

### 2.2 스테이킹 변경 알림

```solidity
/// @notice L2의 스테이킹 금액 변경 시 호출
/// @dev DepositManager에서 deposit/withdraw 시 호출해야 함
/// @param layer2 L2 주소 (candidate)
function onStakingChange(address layer2) external;
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | DepositManager, SeigManager (슬래싱 시) |
| **호출 시점** | deposit/withdraw/slashSequencer/transferStake 완료 후 |
| **접근 제어** | `onlyDepositManager` 또는 내부 호출 |
| **영향** | L2 자격 조건 `S_i ≥ θ·B_i` 재평가 |

---

## 3. DepositManager 외부 인터페이스

### 3.1 스테이킹 (기존 V2 유지)

```solidity
/// @notice WTON 스테이킹
/// @param layer2 스테이킹할 L2 주소
/// @param amount 스테이킹 금액 (WTON)
function deposit(address layer2, uint256 amount) external;

/// @notice TON 스테이킹 (approveAndCall)
/// @param layer2 스테이킹할 L2 주소
/// @param amount 스테이킹 금액 (TON)
function onApprove(address owner, address spender, uint256 amount, bytes calldata data) external;
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | 스테이커 (EOA 또는 컨트랙트) |
| **호출 시점** | 스테이킹 시 |
| **V3 변경** | 완료 후 `SeigManager.onStakingChange(layer2)` 호출 추가 |

### 3.2 출금 요청 (기존 V2 유지)

```solidity
/// @notice 출금 요청
/// @param layer2 출금할 L2 주소
/// @param amount 출금 금액 (WTON)
function requestWithdrawal(address layer2, uint256 amount) external;

/// @notice 출금 처리 (대기 기간 후)
/// @param layer2 출금할 L2 주소
function processRequest(address layer2) external;
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | 스테이커 |
| **V3 변경** | 완료 후 `SeigManager.onStakingChange(layer2)` 호출 추가 |

---

## 4. RAT 외부 인터페이스

### 4.1 검증자 등록/탈퇴

```solidity
/// @notice 검증자 등록
/// @param systemConfig L2의 SystemConfig 주소
/// @param depositAmount 담보금 (WTON)
function registerValidator(address systemConfig, uint256 depositAmount) external;

/// @notice 검증자 탈퇴
/// @param systemConfig L2의 SystemConfig 주소
function deactivateValidator(address systemConfig) external;

/// @notice 담보금 추가 예치
/// @param systemConfig L2의 SystemConfig 주소
/// @param amount 추가 금액 (WTON)
function addDeposit(address systemConfig, uint256 amount) external;
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | 검증자 |
| **최소 담보금** | `D_validator = C_off + Δ_validator` (백서 공식 5) |

### 4.2 RAT 응답

```solidity
/// @notice RAT 증거 제출 (응답)
/// @param systemConfig L2의 SystemConfig 주소
/// @param batchIndex 배치 인덱스
/// @param evidence 증거 데이터
function submitEvidence(
    address systemConfig,
    uint32 batchIndex,
    bytes calldata evidence
) external;
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | 선택된 검증자 |
| **호출 시점** | RAT 트리거 후 `evidenceSubmissionPeriod` 내 |
| **결과** | 성공 시 `C_off` 복구, 미응답 시 슬래싱 |

### 4.3 보상 청구

```solidity
/// @notice 특정 L2의 보상 청구
/// @param systemConfig L2의 SystemConfig 주소
function claimRewards(address systemConfig) external;

/// @notice 여러 L2의 보상 일괄 청구
/// @param systemConfigs L2의 SystemConfig 주소 배열
function claimRewardsBatch(address[] calldata systemConfigs) external;

/// @notice 대기 중인 총 보상 조회
/// @param validator 검증자 주소
/// @return total 총 대기 보상
function getTotalPendingRewards(address validator) external view returns (uint256 total);
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | 검증자 |
| **보상 원천** | `α · y(x) / n` (백서 공식 13) |

### 4.4 RAT 트리거 (프로토콜 전용)

```solidity
/// @notice RAT 테스트 트리거
/// @dev DisputeGameFactory에서만 호출 가능
/// @param systemConfig L2의 SystemConfig 주소
/// @param batchIndex 배치 인덱스
/// @param batchHash 배치 해시
/// @param blockHash 블록 해시 (랜덤 시드)
function triggerAttentionTest(
    address systemConfig,
    uint32 batchIndex,
    bytes32 batchHash,
    bytes32 blockHash
) external;
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | DisputeGameFactory (Optimism L2) |
| **접근 제어** | `onlyAuthorizedTrigger` |
| **트리거 확률** | `π_a` (ratTriggerProbability) |

---

## 5. 슬래싱 외부 인터페이스

### 5.1 시퀀서 슬래싱

```solidity
/// @notice 시퀀서 슬래싱 (fraud proof 성공 시)
/// @param layer2 슬래싱 대상 L2 주소
/// @param challengers 성공한 챌린저 목록
function slashSequencer(address layer2, address[] calldata challengers) external;
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | Dispute Contract |
| **접근 제어** | `onlyDisputeContract` |
| **결과** | 담보금 슬래싱, 챌린저 보상 분배, L2 자격 재평가 |

---

## 6. 거버넌스 인터페이스

### 6.1 V3 파라미터 설정

```solidity
// SeigManager
function setDaoDistributionRatio(uint256 ratio) external onlyOwner;      // d
function setMinStakingRatio(uint256 ratio) external onlyOwner;           // θ
function setValidatorDistributionRatio(uint256 ratio) external onlyOwner; // α
function setHalfSaturationPoint(uint256 k) external onlyOwner;           // k
function setStakedSeigFactor(uint256 lambda) external onlyOwner;         // λ
function setRelativeSeigRate(uint256 rate) external onlyOwner;           // r
function setValidatorPool(address pool) external onlyOwner;
```

### 6.2 슬래싱 파라미터 설정

```solidity
// 시퀀서 슬래싱
function setMaxChallengers(uint256 hMax) external onlyOwner;              // H_max
function setMaxFraudProofCost(uint256 cMax) external onlyOwner;           // C_max
function setMinimumInitialDepositAmount(uint256 amount) external onlyOwner;

// 검증자 슬래싱 (RAT)
function setAttentionCost(uint256 cost) external onlyOwner;               // c_m
function setSlashingPenalty(uint256 penalty) external onlyOwner;          // C_off
function setValidatorBuffer(uint256 buffer) external onlyOwner;           // Δ_validator
function setMinimumThreshold(uint256 threshold) external onlyOwner;       // D_min
function setRatTriggerProbability(uint256 probability) external onlyOwner; // π_a
function setEvidenceSubmissionPeriod(uint256 period) external onlyOwner;
```

---

## 7. 조회 인터페이스

### 7.1 L2 자격 조회

```solidity
/// @notice L2 자격 확인
/// @param layer2 L2 주소
/// @return eligible 자격 여부
/// @return requiredStake 필요 스테이킹 (θ·B_i)
/// @return currentStake 현재 스테이킹 (S_i)
function checkEligibility(address layer2)
    external view
    returns (bool eligible, uint256 requiredStake, uint256 currentStake);

/// @notice 유효 Bridged TON 조회
/// @param layer2 L2 주소
function getEffectiveBridgedTON(address layer2) external view returns (uint256);

/// @notice 전체 유효 Bridged TON 조회
function getTotalEffectiveBridgedTON() external view returns (uint256);
```

### 7.2 시뇨리지 예측

```solidity
/// @notice L2별 시뇨리지 예측
/// @param layer2 L2 주소
/// @return seigniorage 예상 시뇨리지
function estimateL2Seigniorage(address layer2) external view returns (uint256 seigniorage);

/// @notice 쌍곡선 함수 계산
/// @param x 입력값 (전체 유효 Bridged TON)
/// @param l2MaxAllocation L2 분배 가능량 (L)
/// @return y 결과값 y(x)
function hyperbolicSaturation(uint256 x, uint256 l2MaxAllocation)
    external pure
    returns (uint256 y);
```

### 7.3 검증자 정보 조회

```solidity
/// @notice 검증자 정보 조회
/// @param validator 검증자 주소
/// @param systemConfig L2의 SystemConfig 주소
function getValidatorInfo(address validator, address systemConfig)
    external view
    returns (
        bool isActive,
        uint256 depositAmount,
        uint256 pendingRewards,
        uint256 lastRATResponse
    );

/// @notice 최소 담보금 조회
/// @return 최소 담보금 (C_off + Δ_validator)
function getMinimumDeposit() external view returns (uint256);

/// @notice 슬래싱 페널티 검증
/// @param n 검증자 수
/// @return 공식 (4) 만족 여부
function validateSlashingPenalty(uint256 n) external view returns (bool);
```

---

## 8. 호출 흐름 요약

### 8.1 TON 브리지 입금 시

```
L1Bridge.deposit(TON)
    │
    └─► SeigManager.onBridgedTONChange(layer2, newAmount)
            │
            ├─► bridgedTONInfo[layer2] 갱신
            ├─► checkEligibility(layer2) 재평가
            └─► totalEffectiveBridgedTON 갱신
```

### 8.2 스테이킹 변경 시

```
DepositManager.deposit(layer2, amount)
    │
    └─► SeigManager.onStakingChange(layer2)
            │
            └─► checkEligibility(layer2) 재평가
                    │
                    └─► (자격 변경 시) totalEffectiveBridgedTON 갱신
```

### 8.3 RAT 흐름

```
DisputeGameFactory.create()
    │
    └─► RAT.triggerAttentionTest(systemConfig, ...)
            │
            ├─► 검증자 랜덤 선택
            ├─► C_off 선차감
            └─► attentionTest 생성
                    │
        ┌───────────┴───────────┐
        ▼                       ▼
RAT.submitEvidence()      (타임아웃)
    │                           │
    └─► C_off 복구         (슬래싱 확정)
                                │
                                └─► D_min 미만 시 검증자 제거
```

---

## 9. 이벤트

### 9.1 SeigManager 이벤트

```solidity
event BridgedTONChanged(
    address indexed layer2,
    uint256 bridgedTON,
    uint256 effectiveBridgedTON,
    bool isEligible
);

event EligibilityChanged(
    address indexed layer2,
    bool eligible,
    uint256 bridgedTON,
    uint256 effectiveBridgedTON
);

event V3SeigniorageDistributed(
    uint256 totalSeigniorage,      // A₂
    uint256 l2MaxAllocation,       // L
    uint256 totalDistributed,      // y(x)
    uint256 daoAmount,             // S_DAO + undistributed
    uint256 validatorPoolAmount    // α · y(x)
);

event StakedSeigFactorUpdated(uint256 newLambda);
event RelativeSeigRateUpdated(uint256 newRate);
```

### 9.2 RAT 이벤트

```solidity
event ValidatorRegistered(address indexed validator, address indexed systemConfig, uint256 depositAmount);
event ValidatorDeactivated(address indexed validator, address indexed systemConfig);
event AttentionTestTriggered(address indexed validator, address indexed systemConfig, uint32 batchIndex);
event EvidenceSubmitted(address indexed validator, address indexed systemConfig, uint32 batchIndex);
event ValidatorSlashed(address indexed validator, address indexed systemConfig, uint256 amount, bool removed);
event RewardsClaimed(address indexed validator, address indexed systemConfig, uint256 amount);
```

### 9.3 슬래싱 이벤트

```solidity
event SequencerSlashed(
    address indexed layer2,
    address indexed sequencer,
    uint256 totalSlashed,
    uint256 challengerCount
);

event ChallengerRewarded(
    address indexed layer2,
    address indexed challenger,
    uint256 reward
);
```

---

## 10. 참고 자료

- [06_bridged_ton_tracking.md](./06_bridged_ton_tracking.md): Bridged TON 추적 시스템
- [07_rat_implementation.md](./07_rat_implementation.md): RAT 구현체 설계
- [08_implementation.md](./08_implementation.md): 구현 코드
- [10_governance_parameters.md](./10_governance_parameters.md): 거버넌스 파라미터
