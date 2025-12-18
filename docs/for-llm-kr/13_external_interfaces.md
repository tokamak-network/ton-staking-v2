# 외부 인터페이스

## 1. 개요

이 문서는 TON Staking V3 시스템에서 **외부 컨트랙트가 호출해야 하는 인터페이스**를 정리합니다. 각 인터페이스는 호출 주체, 호출 시점, 파라미터를 명시합니다.

---

## 2. SeigManager 외부 인터페이스

### 2.1 Bridged TON 변경 알림 (타입 3 전용)

```solidity
/// @notice L2의 Bridged TON(TVL) 변경 시 호출 (타입 3 전용)
/// @dev OptimismPortal에서 TON 입금/출금 시 SeigManager를 직접 호출해야 함
///      msg.sender(OptimismPortal)로부터 rollupConfig를 자동 조회
///      트리거 함수이므로 revert 대신 early return 사용 - 호출자의 트랜잭션 실패 방지
function onBridgedTONChange() external;
```

| 항목 | 내용 |
|------|------|
| **지원 타입** | **타입 3 (OPTIMISM_BEDROCK_WITH_DISPUTE_GAME) 전용** |
| **호출 주체** | OptimismPortal (SeigManager를 직접 호출) |
| **호출 시점** | TON 입금/출금 완료 후 |
| **접근 제어** | early return 패턴 사용 (revert 하지 않음) |
| **영향** | L2 자격 재평가, `totalEffectiveBridgedTON` 갱신 |

**함수 동작 흐름:**
```solidity
function onBridgedTONChange() external onlyMigrated {
    // 1. msg.sender(OptimismPortal)로 rollupConfig 조회
    address rollupConfig = IL1BridgeRegistry(l1BridgeRegistry).rollupConfigWithPortal(msg.sender);
    if (rollupConfig == address(0)) return;  // 등록되지 않은 포탈 → early return

    // 2. 타입 3만 지원
    uint8 rollupType = IL1BridgeRegistry(l1BridgeRegistry).rollupType(rollupConfig);
    if (rollupType != 3) return;  // 타입 3 아님 → early return

    // 3. layer2 주소 조회
    address layer2 = ILayer2Manager(layer2Manager).getLayer2BySystemConfig(rollupConfig);
    if (layer2 == address(0)) return;  // 등록되지 않은 L2 → early return

    // 4. 자격 재평가
    _updateEligibilityInternal(layer2);
}
```

> **중요 - 타입 3 전용**:
> - 타입 1/2 롤업은 이 함수를 사용하지 않습니다
> - 타입 3 (OPTIMISM_BEDROCK_WITH_DISPUTE_GAME) 롤업만 OptimismPortal에서 직접 SeigManager를 호출합니다
> - 트리거 함수이므로 모든 오류 상황에서 revert 대신 early return하여 호출자(OptimismPortal)의 트랜잭션이 실패하지 않도록 합니다

### 2.2 TON 스테이킹 변경 시 자격 재평가

```solidity
/// @notice TON 스테이킹 변경 시 호출 (자격 재평가용)
/// @dev DepositManager에서 deposit/withdraw 후 호출
/// @param layer2 L2 주소
function onStakingChange(address layer2) external;
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | DepositManager |
| **호출 시점** | deposit/withdraw 완료 후 |
| **영향** | L2 자격(S_i ≥ θ·B_i) 재평가, totalEffectiveBridgedTON 갱신 |

> **참고**: 온체인에서 모든 L2를 순회하여 자격을 재평가하는 것은 가스 비용이 너무 높아 불가능합니다. 따라서 스테이킹 변경 시 해당 L2의 자격만 실시간으로 재평가합니다.

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
| **호출 시점** | TON 스테이킹 시 |
| **V3 변경** | deposit/withdraw 후 `SeigManager.onStakingChange(layer2)` 호출 추가 |

### 3.2 출금 요청

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
| **V3 변경** | requestWithdrawal 후 `SeigManager.onStakingChange(layer2)` 호출 추가 |

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

## 5. SequencerVault 외부 인터페이스

### 5.1 시퀀서 담보금 관리

```solidity
/// @notice 시퀀서 등록 (TON 직접 예치)
/// @dev 누구나 호출 가능, Layer2Manager에서 operator/layer2 자동 조회
/// @param systemConfig L2의 SystemConfig 주소
/// @param depositAmount 예치할 TON 양
function registerSequencer(address systemConfig, uint256 depositAmount) external;

/// @notice 시퀀서 탈퇴 및 즉시 출금
/// @dev 오퍼레이터(OperatorManager)만 호출 가능
/// @param systemConfig L2의 SystemConfig 주소
function deactivateSequencer(address systemConfig) external;

/// @notice 담보금 추가 예치
/// @dev 누구나 호출 가능 (제3자 펀딩 가능)
/// @param systemConfig L2의 SystemConfig 주소
/// @param amount 추가 예치할 TON 양
function addDeposit(address systemConfig, uint256 amount) external;
```

| 함수 | 호출 주체 | 설명 |
|------|----------|------|
| `registerSequencer` | **누구나** | 담보금 예치 (제3자 펀딩 가능) |
| `deactivateSequencer` | **OperatorManager만** | 탈퇴 및 즉시 출금 |
| `addDeposit` | **누구나** | 담보금 추가 (제3자 펀딩 가능) |

**담보금 예치 흐름 (registerSequencer):**
```
누구나 (EOA/컨트랙트)
    │
    │ SequencerVault.registerSequencer(systemConfig, amount)
    ▼
SequencerVault
    │ Layer2Manager.getLayer2BySystemConfig(systemConfig) → layer2 조회
    │ Layer2Manager.layerInfo(layer2) → operator 조회
    │ TON.transferFrom(msg.sender, vault, amount)
    │ sequencerDeposits[systemConfig] = {operator, layer2, amount, ...}
    │ layer2ToSystemConfig[layer2] = systemConfig  (역방향 매핑)
    ▼
등록 완료
```

**담보금 출금 흐름 (deactivateSequencer):**
```
Manager(EOA)
    │
    │ OperatorManager.deactivateSequencer()
    ▼
OperatorManager (onlyOwnerOrManager)
    │
    │ SequencerVault.deactivateSequencer(rollupConfig)
    ▼
SequencerVault
    │ deposit.operator == msg.sender(OperatorManager) 확인
    │ TON.transfer(OperatorManager, depositAmount)
    ▼
OperatorManager가 TON 보유
    │
    │ Manager가 claimERC20(ton, amount) 호출
    ▼
Manager(EOA)가 TON 수령
```

> **중요**: 누가 예치했든 상관없이 출금은 항상 해당 L2의 **OperatorManager**만 가능합니다.

### 5.2 담보금 조회

```solidity
/// @notice 시퀀서 담보금 조회 (systemConfig 기준)
function getSequencerDeposit(address systemConfig) external view returns (uint256);

/// @notice 시퀀서 담보금 조회 (layer2 기준)
/// @dev SeigManager에서 layer2 기준 조회 시 사용
function getSequencerDepositByLayer2(address layer2) external view returns (uint256);

/// @notice 시퀀서 활성 상태 확인 (systemConfig 기준)
function isSequencerActive(address systemConfig) external view returns (bool);

/// @notice 시퀀서 활성 상태 확인 (layer2 기준)
function isSequencerActiveByLayer2(address layer2) external view returns (bool);

/// @notice 시퀀서 등록 정보 조회
function getSequencerInfo(address systemConfig)
    external view returns (
        address operator,
        address layer2,
        uint256 depositedAmount,
        uint256 slashedAmount,
        bool isActive
    );

/// @notice 오퍼레이터가 등록한 systemConfig 목록 조회
function getOperatorSystemConfigs(address operator) external view returns (address[] memory);

/// @notice 최소 담보금 계산 (Bridged TON 기반)
function getMinimumCollateral(uint256 bridgedTON) external view returns (uint256);
```

**SeigManager에서 담보금 조회 흐름:**
```
SeigManager._getSequencerStake(layer2)
    │
    │ SequencerVault.getSequencerDepositByLayer2(layer2)
    ▼
SequencerVault
    │ layer2ToSystemConfig[layer2] → systemConfig
    │ sequencerDeposits[systemConfig].depositedAmount
    ▼
담보금 반환
```

### 5.3 시퀀서 슬래싱 (Permissionless)

```solidity
/// @notice 시퀀서 슬래싱 - Permissionless 방식
/// @dev 누구나 호출 가능, 게임 상태를 온체인에서 검증
///      DisputeGameFactory 검증을 통해 가짜 게임 컨트랙트 방지
/// @param gameAddress 종료된 FaultDisputeGame 주소
function slashSequencerByGame(address gameAddress) external;

/// @notice 누적 슬래싱 금액을 Treasury로 전송
function withdrawSlashingsToTreasury() external;

/// @notice 챌린저 보상 청구
function claimChallengerReward() external;

/// @notice 챌린저 미청구 보상 조회
function getPendingChallengerReward(address challenger) external view returns (uint256);
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | 누구나 (Permissionless) |
| **접근 제어** | 없음 (온체인 게임 상태 검증) |
| **결과** | 담보금 전액 슬래싱, 챌린저 보상 누적, 시퀀서 비활성화 |

### 5.4 거버넌스 함수

```solidity
function setMinimumStakingRatio(uint256 ratio) external;
function setMaxFraudProofCost(uint256 cost) external;
function setSequencerAdditionalReward(uint256 reward) external;
function setMaxChallengers(uint256 max) external;
function setTreasury(address _treasury) external;
function setL1BridgeRegistry(address _registry) external;
function pause() external;
function unpause() external;
```

---

## 6. 거버넌스 인터페이스

### 6.1 V3 파라미터 설정

```solidity
// SeigManager - V3 파라미터 설정
function setDaoDistributionRatio(uint256 ratio) external onlyOwner;      // d
function setMinStakingRatio(uint256 ratio) external onlyOwner;           // θ
function setValidatorDistributionRatio(uint256 ratio) external onlyOwner; // α
function setHalfSaturationPoint(uint256 k) external onlyOwner;           // k
function setRatContract(address rat) external onlyOwner;                 // RAT 컨트랙트
function setValidatorReward(address reward) external onlyOwner;          // ValidatorReward 컨트랙트
function migrateToV3() external onlyOwner;                               // V3 모드 전환

// 레거시 (V2 모드에서만 사용)
function setRelativeSeigRate(uint256 rate) external onlyOwner;           // r (V2 모드 전용)
function setStakedSeigFactor(uint256 lambda) external onlyOwner;         // 레거시, 미사용
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
/// @notice L2 자격 확인 (실시간)
/// @param layer2 L2 주소
/// @return eligible 자격 여부
/// @return requiredStake 필요 스테이킹 (θ·B_i)
/// @return currentStake 현재 스테이킹 (S_i)
function checkCurrentEligibility(address layer2)
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

### 8.1 TON 브리지 입금/출금 시 (타입 3 전용)

```
OptimismPortal.depositTransaction() 또는 finalizeWithdrawalTransaction()
    │
    └─► SeigManager.onBridgedTONChange()  [포탈이 직접 호출]
            │
            ├─► L1BridgeRegistry.rollupConfigWithPortal(msg.sender) → rollupConfig 조회
            │       (등록되지 않은 포탈이면 early return)
            │
            ├─► rollupType == 3 검증
            │       (타입 3 아니면 early return)
            │
            ├─► Layer2Manager.getLayer2BySystemConfig(rollupConfig) → layer2 조회
            │       (등록되지 않은 L2이면 early return)
            │
            └─► _updateEligibilityInternal(layer2)
                    │
                    ├─► checkCurrentEligibility(layer2) 재평가
                    └─► totalEffectiveBridgedTON 갱신
```

> **참고**: 타입 1/2 롤업은 `onBridgedTONChange`를 사용하지 않습니다. OptimismPortal이 SeigManager를 직접 호출하며, 트리거 함수이므로 모든 오류 상황에서 revert 대신 early return합니다.

### 8.2 TON 스테이킹 변경 시

```
DepositManager.deposit(layer2, amount)
    │
    ├─► SeigManager.onDeposit(layer2, account, amount)
    │       │
    │       └─► 스테이킹 기록 업데이트
    │
    └─► SeigManager.onStakingChange(layer2)
            │
            └─► _updateEligibilityInternal(layer2)
                    │
                    ├─► checkCurrentEligibility(layer2) 재평가
                    └─► totalEffectiveBridgedTON 갱신
```

> **참고**: 온체인에서 모든 L2를 순회하여 자격을 재평가하는 것은 가스 비용이 너무 높아 불가능합니다. 따라서 `onStakingChange` 콜백을 통해 해당 L2의 자격만 실시간으로 재평가합니다.

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

event V3MigrationCompleted(uint256 blockNumber, uint256 totalMigratedL2s);

// 레거시 이벤트
event StakedSeigFactorUpdated(uint256 newLambda);  // 미사용
event RelativeSeigRateUpdated(uint256 newRate);   // V2 모드 전용
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

### 9.3 SequencerVault 이벤트

```solidity
/// @notice 시퀀서 등록 이벤트
event SequencerRegistered(
    address indexed operator,
    address indexed systemConfig,
    address layer2,
    uint256 depositAmount
);

/// @notice 시퀀서 탈퇴 이벤트
event SequencerDeactivated(
    address indexed sequencer,
    address indexed systemConfig,
    uint256 returnedAmount
);

/// @notice 담보금 추가 이벤트
event DepositAdded(
    address indexed sequencer,
    address indexed systemConfig,
    uint256 amount
);

/// @notice 시퀀서 슬래싱 이벤트
event SequencerSlashed(
    address indexed sequencer,
    address indexed systemConfig,
    address indexed gameAddress,
    uint256 slashedAmount,
    address challenger,
    uint256 challengerReward
);

/// @notice 슬래싱 금액 Treasury 전송 이벤트
event SlashingsWithdrawnToTreasury(
    address indexed treasury,
    uint256 amount
);

/// @notice 챌린저 보상 청구 이벤트
event ChallengerRewardClaimed(
    address indexed challenger,
    uint256 amount
);
```

---

## 10. 참고 자료

- [06_bridged_ton_tracking.md](./06_bridged_ton_tracking.md): Bridged TON 추적 시스템
- [07_rat_implementation.md](./07_rat_implementation.md): RAT 구현체 설계
- [08_implementation.md](./08_implementation.md): 구현 코드
- [10_governance_parameters.md](./10_governance_parameters.md): 거버넌스 파라미터
