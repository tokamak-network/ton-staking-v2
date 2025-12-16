# Bridged TON 추적 시스템

## 1. 추적 필요성

온체인에서 모든 L2의 Bridged TON을 실시간으로 순회 조회하는 것은 가스 비용이 너무 높아 불가능합니다.
따라서 **유효성(eligibility)과 TVL(Bridged TON)이 변경되는 시점마다** 값을 추적하여 캐시해야 합니다.

---

## 2. 추적이 필요한 시점

| 변경 시점 | 트리거 | 영향 |
|-----------|--------|------|
| **오퍼레이팅 스테이킹 변경** | `deposit()`, `withdraw()` | S_i 변경 → 유효성(S_i ≥ θ·B_i) 재평가 필요 |
| **슬래싱** | `slashSequencerByGame()` | S_i 변경 → 유효성 재평가 필요 |
| **Bridged TON 변경** | L1 브리지에 TON 입금/출금 | B_i 변경 → 유효성 재평가 + totalEffectiveBridgedTON 갱신 |

---

## 3. 추적 인터페이스

### 3.1 SeigManager 인터페이스

```solidity
/// @title ISeigManagerV3
/// @notice OptimismPortal과 DepositManager가 호출하는 인터페이스
interface ISeigManagerV3 {
    /// @notice L2의 Bridged TON(TVL) 변경 시 호출 (타입 3 전용)
    /// @dev OptimismPortal에서 TON 입금/출금 시 SeigManager를 직접 호출
    ///      msg.sender(OptimismPortal)로부터 rollupConfig를 자동 조회
    ///      트리거 함수이므로 revert 대신 early return 사용
    function onBridgedTONChange() external;

    /// @notice TON 스테이킹 변경 시 호출 (자격 재평가용)
    /// @dev DepositManager에서 deposit/withdraw 후 호출
    /// @param layer2 L2 주소
    function onStakingChange(address layer2) external;
}
```

> **호출 흐름**:
> - Bridged TON 변경: OptimismPortal → `SeigManager.onBridgedTONChange()` (직접 호출, msg.sender로 rollupConfig 조회, 타입 3 전용)
> - 스테이킹 변경: DepositManager → `SeigManager.onStakingChange(layer2)`

---

## 4. 추적 함수 구현

### 4.1 SeigManager.onBridgedTONChange (OptimismPortal에서 직접 호출, 타입 3 전용)

```solidity
/// @notice L2의 Bridged TON 변경 시 호출 (타입 3 전용)
/// @dev OptimismPortal에서 TON 입금/출금 시 SeigManager를 직접 호출
///      트리거 함수이므로 조건 불충족 시 revert 대신 early return
function onBridgedTONChange()
    external
    onlyMigrated
{
    // 1. 호출자(포탈)로부터 rollupConfig 역방향 조회
    address rollupConfig = IL1BridgeRegistry(l1BridgeRegistry).rollupConfigWithPortal(msg.sender);
    if (rollupConfig == address(0)) return;

    // 2. 타입 3 (OPTIMISM_BEDROCK_WITH_DISPUTE_GAME) 검증
    uint8 rollupType = IL1BridgeRegistry(l1BridgeRegistry).rollupType(rollupConfig);
    if (rollupType != 3) return;

    // 3. rollupConfig → layer2 변환
    address layer2 = ILayer2Manager(layer2Manager).getLayer2BySystemConfig(rollupConfig);
    if (layer2 == address(0)) return;

    // 4. 자격평가 및 effectiveBridgedTON 동기화
    _updateEligibilityInternal(layer2);
}
```

> **참고**: `onBridgedTONChange`는 타입 3 (OPTIMISM_BEDROCK_WITH_DISPUTE_GAME) 롤업에서만 호출됩니다.
> **중요**: 트리거 함수이므로 조건 불충족 시 revert 대신 early return을 사용합니다. 이는 OptimismPortal의 입금/출금 트랜잭션이 실패하지 않도록 합니다.

### 4.2 SeigManager.onStakingChange (스테이킹 변경 콜백)

```solidity
/// @notice TON 스테이킹 변경 시 호출 (자격 재평가용)
/// @dev DepositManager에서 deposit/withdraw 후 호출
/// @param layer2 L2 주소
function onStakingChange(address layer2)
    external
    onlyDepositManager
    onlyMigrated
{
    _updateEligibilityInternal(layer2);
}
```

> **참고**: 온체인에서 모든 L2를 순회하여 자격을 재평가하는 것은 가스 비용이 너무 높아 불가능합니다. 따라서 스테이킹 변경 시 해당 L2의 자격만 실시간으로 재평가합니다.

---

## 5. 호출 책임

| 컨트랙트 | 호출할 함수 | 호출 시점 |
|----------|-------------|-----------|
| **OptimismPortal** | `SeigManager.onBridgedTONChange()` | TON 입금/출금 완료 후 (타입 3 전용) |
| **DepositManager** | `SeigManager.onStakingChange(layer2)` | deposit/withdraw 완료 후 |

> **참고**: OptimismPortal에서 SeigManager를 직접 호출합니다. SeigManager는 `msg.sender`로부터 `L1BridgeRegistry.rollupConfigWithPortal`을 통해 rollupConfig를 조회합니다.

---

## 6. 이벤트

```solidity
/// @notice 유효성 상태 변경 이벤트
event EligibilityChanged(
    address indexed layer2,
    bool eligible,
    uint256 bridgedTON,
    uint256 effectiveBridgedTON
);
```

> **참고**: BridgedTONChanged 이벤트는 가스비 절감을 위해 제거되었습니다. 자격 변경은 EligibilityChanged 이벤트로 추적합니다.

---

## 7. 자격 조건 확인 함수

### 7.1 자격 확인 (Rule 4)

```solidity
/// @notice L2 시퀀서의 시뇨리지 수령 자격 실시간 확인
/// @dev 백서 공식 (9): 1_i = {1 if S_i ≥ θ·B_i, 0 otherwise}
/// @dev S_i는 시퀀서(오퍼레이터)의 스테이킹량만 포함 (RAT 등 다른 스테이킹 제외)
/// @dev B_i는 L1 브리지에서 직접 조회 (가스비 높지만 정확함)
/// @param layer2 L2 주소
/// @return eligible 시뇨리지 수령 자격 여부
/// @return requiredStake 필요 스테이킹량 (θ·B_i)
/// @return currentStake 현재 시퀀서 스테이킹량 (S_i)
function checkCurrentEligibility(address layer2)
    public view
    returns (bool eligible, uint256 requiredStake, uint256 currentStake)
{
    // B_i: L1 브리지에서 직접 조회 (실시간)
    uint256 bridgedTON = ILayer2Manager(layer2Manager).getBridgedTONByLayer(layer2);

    // θ · B_i (RAY 연산)
    requiredStake = rmul(bridgedTON, minStakingRatio);

    // S_i: 시퀀서(오퍼레이터)의 현재 스테이킹량 (실시간 조회)
    currentStake = _getSequencerStake(layer2);

    // S_i ≥ θ · B_i
    eligible = currentStake >= requiredStake;
}

/// @notice 시퀀서(오퍼레이터)의 스테이킹량 조회
/// @dev RAT 등 다른 계정의 스테이킹은 제외
function _getSequencerStake(address layer2) internal view returns (uint256) {
    address sequencer = Layer2I(layer2).operator();
    if (sequencer == address(0)) return 0;

    RefactorCoinageSnapshotI coinage = _coinages[layer2];
    return address(coinage) != address(0) ? coinage.balanceOf(sequencer) : 0;
}
```

### 7.2 유효 Bridged TON 조회 (Rule 3)

```solidity
/// @notice 유효 Bridged TON 조회 (캐시된 값)
/// @dev B̃_i = 1_i · B_i (자격 있으면 Bridged TON, 없으면 0)
/// @dev updateSeigniorage 시점에 _syncEffectiveBridgedTON에 의해 동기화됨
function getEffectiveBridgedTON(address layer2) public view returns (uint256) {
    return bridgedTONInfo[layer2].effectiveBridgedTON;
}

/// @notice 전체 유효 Bridged TON 조회 (캐시된 값)
/// @dev x = Σ B̃_i (updateSeigniorage 시점에 동기화됨)
function getTotalEffectiveBridgedTON() public view returns (uint256) {
    return totalEffectiveBridgedTON;
}

/// @notice L2의 Bridged TON 정보 전체 조회
function getBridgedTONInfo(address layer2) public view returns (
    uint256 currentBridgedTON,
    uint256 effectiveBridgedTON,
    bool isEligible,
    uint256 lastUpdateTime
) {
    BridgedTONInfo storage info = bridgedTONInfo[layer2];
    return (
        info.currentBridgedTON,
        info.effectiveBridgedTON,
        info.isEligible,
        info.lastUpdateTime
    );
}
```

### 7.3 Bridged TON 직접 조회 (L1 브리지에서)

```solidity
/// @notice Bridged TON 직접 조회 (L1 브리지에서) - 내부 헬퍼
/// @dev onBridgedTONChange 호출 시 검증용으로 사용 가능
function _getBridgedTONFromBridge(address layer2) internal view returns (uint256) {
    // Layer2Manager를 통해 해당 L2의 rollupConfig 조회
    address rollupConfig = ILayer2Manager(layer2Manager).getRollupConfig(layer2);

    // L1BridgeRegistry를 통해 브리지 주소 조회
    (bool valid, address l1Bridge,,) = IL1BridgeRegistry(l1BridgeRegistry)
        .checkL1Bridge(rollupConfig);

    if (!valid) return 0;

    // 브리지에 잠긴 TON 잔액 = Bridged TON
    return IERC20(_ton).balanceOf(l1Bridge);
}
```

---

## 8. updateSeigniorage에서 캐시된 값 사용

V3의 `updateSeigniorage` 함수는 `_syncEffectiveBridgedTON`을 통해 자격 재평가 후 `totalEffectiveBridgedTON`을 사용합니다.

```solidity
function _updateSeigniorage() internal ifFree returns (bool) {
    // ... 스테이커 분배 로직 ...

    // ========================================
    // Step 4: 모든 L2의 자격 재평가 및 유효 Bridged TON 동기화
    // ========================================
    _syncAllEffectiveBridgedTON();  // 스테이킹 변경에 따른 자격 재평가 포함

    uint256 totalX = totalEffectiveBridgedTON;  // x = Σ B̃_i

    if (totalX > 0) {
        // y(x) = L · (x / (k + x))
        uint256 totalY = hyperbolicSaturation(totalX, l2MaxAllocation);

        // ... 분배 로직 ...
    }
}
```

---

## 9. 데이터 흐름 다이어그램

```
┌──────────────────────┐  onBridgedTONChange()    ┌──────────────────────┐
│   OptimismPortal     │ ──────────────────────► │     SeigManager      │
│  (TON 입금/출금)      │  (newBalance)            │  ┌────────────────┐  │
│                      │                          │  │ bridgedTONInfo │  │
└──────────────────────┘  msg.sender로            │  │ [layer2]       │  │
         │                rollupConfig 조회       │  └────────────────┘  │
         │                      │                 │         │            │
         ▼                      ▼                 │         │            │
┌──────────────────────┐  rollupConfigWithPortal  │         │            │
│  L1BridgeRegistry    │ ◄────────────────────── │         │            │
│  (역방향 매핑)        │                          │         │            │
└──────────────────────┘                          │         │            │
                                                  │         │            │
┌─────────────────┐                               │         │            │
│  DepositManager │  deposit/                     │         │            │
│                 │  withdraw                     │         │            │
│                 │ ───────────────────────────► │  _updateEligibility  │
│                 │  onStakingChange()            │  (자격 재평가)        │
└─────────────────┘                               │         │            │
                                                  │         ▼            │
                                                  │  totalEffective      │
                                                  │  BridgedTON (x)      │
                                                  │         │            │
                                                  │         ▼            │
                                                  │  y(x) 계산           │
                                                  └──────────────────────┘
```

> **핵심**: OptimismPortal에서 SeigManager를 직접 호출합니다. SeigManager는 `msg.sender`로부터 `L1BridgeRegistry.rollupConfigWithPortal`을 통해 rollupConfig를 조회하고, 이를 layer2 주소로 변환합니다.
