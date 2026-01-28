---
id: functions-events
sidebar_position: 11
---

# 이벤트 목록

TON Staking V3 컨트랙트에서 발생하는 모든 이벤트 목록입니다.

## SeigManager 이벤트

```solidity
// V3 시뇨리지 분배 이벤트
event V3SeigniorageDistributed(
    uint256 totalSeigniorage,
    uint256 l2MaxAllocation,
    uint256 totalDistributed,
    uint256 daoAmount,
    uint256 validatorPoolAmount
);

// 자격 상태 변경 이벤트
event EligibilityChanged(
    address indexed layer2,
    bool eligible,
    uint256 bridgedTON,
    uint256 effectiveBridgedTON
);

// V3 마이그레이션 완료 이벤트
event V3MigrationCompleted(
    uint256 blockNumber,
    uint256 totalMigratedL2s
);

// 시뇨리지 분배 상세 이벤트 (V2 호환)
event SeigGiven2(
    address indexed layer2,
    uint256 totalSeig,
    uint256 stakedSeig,
    uint256 unstakedSeig,
    uint256 powertonSeig,
    uint256 daoSeig,
    uint256 pseig,
    uint256 l2TotalSeigs,
    uint256 layer2Seigs
);

// 자격 상실 시 자동 청구
event AutoClaimBeforeEligibilityLoss(
    address indexed layer2,
    uint256 claimedAmount
);
```

---

## RAT 이벤트

```solidity
// 검증자 등록 이벤트
event ValidatorRegistered(
    address indexed validator,
    address indexed systemConfig,
    uint256 depositAmount,
    uint256 registrationId
);

// 검증자 비활성화 이벤트
event ValidatorDeactivated(
    address indexed validator,
    address indexed systemConfig,
    uint256 returnedAmount
);

// RAT 테스트 트리거 이벤트
event AttentionTestTriggered(
    bytes32 indexed testId,
    address indexed validator,
    address indexed systemConfig,
    address gameAddress,
    uint32 batchIndex,
    uint256 deadline
);

// 증거 제출 이벤트
event EvidenceSubmitted(
    bytes32 indexed testId,
    address indexed validator,
    address indexed systemConfig,
    uint32 batchIndex
);

// 검증자 슬래싱 이벤트
event ValidatorSlashed(
    bytes32 indexed testId,
    address indexed validator,
    address indexed systemConfig,
    uint256 slashedAmount,
    bool removedFromSet
);

// 담보금 복구 이벤트 (챌린지 승리 시)
event BondRestored(
    bytes32 indexed testId,
    address indexed validator,
    address indexed systemConfig,
    uint256 restoredAmount
);

// 검증자 재활성화 이벤트
event ValidatorReactivated(
    address indexed validator,
    address indexed systemConfig,
    uint256 currentCollateral
);
```

---

## ValidatorReward 이벤트

```solidity
// L2별 검증자 보상 분배 이벤트 (요약)
event L2RewardDistributed(
    address indexed systemConfig,
    uint256 totalAmount,           // 총 분배 금액
    uint256 activeValidatorCount,  // 활성 검증자 수
    uint256 perValidator           // 검증자당 분배 금액
);

// 검증자별 보상 분배 이벤트 (청구 시점에 발생)
event ValidatorRewardReceived(
    address indexed validator,
    address indexed systemConfig,
    uint256 amount
);

// 검증자 없을 때 DAO 귀속 이벤트
event RewardToDAO(
    address indexed systemConfig,
    uint256 amount
);

// 검증자 보상 청구 이벤트
event RewardsClaimed(
    address indexed validator,
    uint256 amount
);

// 검증자 L2 등록 이벤트
event ValidatorRegisteredToL2(
    address indexed validator,
    address indexed systemConfig,
    uint256 initialDebt
);
```

---

## 시퀀서 슬래싱 이벤트

```solidity
// 시퀀서 슬래싱 이벤트
event SequencerSlashed(
    address indexed layer2,
    address indexed gameAddress,
    uint256 slashedAmount,
    address challenger,
    uint256 challengerReward
);
```

---

## L1BridgeRegistry 이벤트

```solidity
// 롤업 등록 이벤트
event RollupRegistered(
    address indexed rollupConfig,
    uint8 rollupType,
    address l2TON,
    string name
);

// 롤업 타입 업그레이드 이벤트
event RollupTypeUpgraded(
    address indexed rollupConfig,
    uint8 oldType,
    uint8 newType
);

// 시뇨리지 중지 이벤트
event RejectedCandidateAddOn(
    address indexed rollupConfig
);

// 시뇨리지 복원 이벤트
event RestoredCandidateAddOn(
    address indexed rollupConfig,
    bool rejectedL2Deposit
);
```

---

## 이벤트 사용 패턴

### L2별 검증자 보상 추적

L2별 검증자 보상을 추적하려면 `ValidatorRewardReceived` 이벤트를 구독합니다:

```javascript
// L2별 검증자 보상 리스닝
validatorReward.on("ValidatorRewardReceived", (validator, systemConfig, amount) => {
    console.log(`검증자 ${validator}가 L2 ${systemConfig}에서 ${amount} 받음`);
});
```

### 자격 변경 모니터링

```javascript
// L2 자격 상태 모니터링
seigManager.on("EligibilityChanged", (layer2, eligible, bridgedTON, effectiveBridgedTON) => {
    console.log(`L2 ${layer2} 자격: ${eligible}`);
    console.log(`Bridged TON: ${bridgedTON}, Effective: ${effectiveBridgedTON}`);
});
```

### RAT 테스트 라이프사이클 추적

```javascript
// RAT 테스트 라이프사이클 모니터링
rat.on("AttentionTestTriggered", (testId, validator, systemConfig, gameAddress, batchIndex, deadline) => {
    console.log(`RAT 테스트 ${testId}가 검증자 ${validator}에게 트리거됨`);
});

rat.on("EvidenceSubmitted", (testId, validator, systemConfig, batchIndex) => {
    console.log(`테스트 ${testId}에 증거 제출됨`);
});

rat.on("BondRestored", (testId, validator, systemConfig, restoredAmount) => {
    console.log(`검증자 ${validator}의 담보금 복구: ${restoredAmount}`);
});
```
