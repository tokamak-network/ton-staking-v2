# Bridged TON 추적 시스템

## 1. 추적 필요성

온체인에서 모든 L2의 Bridged TON을 실시간으로 순회 조회하는 것은 가스 비용이 너무 높아 불가능합니다.
따라서 **유효성(eligibility)과 TVL(Bridged TON)이 변경되는 시점마다** 값을 추적하여 캐시해야 합니다.

---

## 2. 추적이 필요한 시점

| 변경 시점 | 트리거 | 영향 |
|-----------|--------|------|
| **스테이킹 변경** | `deposit()`, `withdraw()` | S_i 변경 → 유효성(S_i ≥ θ·B_i) 재평가 필요 |
| **슬래싱** | `slashSequencer()`, `transferStake()` | S_i 변경 → 유효성 재평가 필요 |
| **Bridged TON 변경** | L1 브리지에 TON 입금/출금 | B_i 변경 → 유효성 재평가 + totalEffectiveBridgedTON 갱신 |

---

## 3. 추적 인터페이스

```solidity
/// @title ISeigManagerV3
/// @notice V3 시뇨리지 매니저의 Bridged TON 추적 인터페이스
interface ISeigManagerV3 {
    /// @notice L2의 Bridged TON(TVL) 변경 시 호출
    /// @dev L1Bridge에서 TON 입금/출금 시 호출해야 함
    /// @param layer2 L2 주소 (candidate)
    /// @param newBridgedTON 새로운 Bridged TON 양
    function onBridgedTONChange(address layer2, uint256 newBridgedTON) external;

    /// @notice L2의 스테이킹 금액 변경 시 호출
    /// @dev DepositManager에서 deposit/withdraw 시 호출해야 함
    /// @param layer2 L2 주소 (candidate)
    function onStakingChange(address layer2) external;
}
```

---

## 4. 추적 함수 구현

### 4.1 Bridged TON 변경 시

```solidity
/// @notice L2의 Bridged TON 변경 시 호출
/// @dev L1Bridge 또는 L1BridgeRegistry에서 호출
function onBridgedTONChange(address layer2, uint256 newBridgedTON)
    external
    onlyL1BridgeOrRegistry
{
    BridgedTONInfo storage info = bridgedTONInfo[layer2];
    uint256 oldEffective = info.effectiveBridgedTON;

    // Bridged TON 갱신
    info.currentBridgedTON = newBridgedTON;
    info.lastUpdateTime = block.timestamp;

    // 유효성 재평가: S_i ≥ θ · B_i
    (bool eligible,,) = checkEligibility(layer2);
    info.isEligible = eligible;

    // 유효 Bridged TON 계산
    uint256 newEffective = eligible ? newBridgedTON : 0;
    info.effectiveBridgedTON = newEffective;

    // 전역 합계 갱신
    totalEffectiveBridgedTON = totalEffectiveBridgedTON + newEffective - oldEffective;

    emit BridgedTONChanged(layer2, newBridgedTON, newEffective, eligible);
}
```

### 4.2 스테이킹 금액 변경 시

```solidity
/// @notice L2의 스테이킹 금액 변경 시 호출
/// @dev DepositManager에서 deposit/withdraw 후 호출
function onStakingChange(address layer2) external onlyDepositManager {
    BridgedTONInfo storage info = bridgedTONInfo[layer2];
    uint256 oldEffective = info.effectiveBridgedTON;

    // 유효성 재평가: S_i ≥ θ · B_i (Bridged TON은 그대로)
    (bool eligible,,) = checkEligibility(layer2);
    bool wasEligible = info.isEligible;
    info.isEligible = eligible;

    // 유효성 상태가 변경된 경우에만 전역 합계 갱신
    if (wasEligible != eligible) {
        uint256 newEffective = eligible ? info.currentBridgedTON : 0;
        info.effectiveBridgedTON = newEffective;
        totalEffectiveBridgedTON = totalEffectiveBridgedTON + newEffective - oldEffective;

        emit EligibilityChanged(layer2, eligible, info.currentBridgedTON, newEffective);
    }
}
```

---

## 5. 호출 책임

| 컨트랙트 | 호출할 함수 | 호출 시점 |
|----------|-------------|-----------|
| **L1Bridge** | `onBridgedTONChange(layer2, newAmount)` | TON 입금/출금 완료 후 |
| **L1BridgeRegistry** | `onBridgedTONChange(layer2, newAmount)` | 브리지 TVL 변경 감지 시 |
| **DepositManager** | `onStakingChange(layer2)` | deposit/withdraw 완료 후 |
| **SeigManager** | `onStakingChange(layer2)` | slashSequencer/transferStake 완료 후 |

---

## 6. 이벤트

```solidity
/// @notice Bridged TON 변경 이벤트
event BridgedTONChanged(
    address indexed layer2,
    uint256 bridgedTON,           // B_i: 새로운 Bridged TON
    uint256 effectiveBridgedTON,  // B̃_i: 유효 Bridged TON (자격 없으면 0)
    bool isEligible               // 자격 여부
);

/// @notice 유효성 상태 변경 이벤트
event EligibilityChanged(
    address indexed layer2,
    bool eligible,
    uint256 bridgedTON,
    uint256 effectiveBridgedTON
);
```

---

## 7. 자격 조건 확인 함수

### 7.1 자격 확인 (Rule 4)

```solidity
/// @notice L2 자격 확인
/// @dev 백서 공식 (9): 1_i = {1 if S_i ≥ θ·B_i, 0 otherwise}
/// @param layer2 L2 주소
/// @return eligible 자격 여부
/// @return requiredStake 필요 스테이킹 (θ·B_i)
/// @return currentStake 현재 스테이킹 (S_i)
function checkEligibility(address layer2)
    public view
    returns (bool eligible, uint256 requiredStake, uint256 currentStake)
{
    BridgedTONInfo storage info = bridgedTONInfo[layer2];
    uint256 bridgedTON = info.currentBridgedTON;

    // θ · B_i (RAY 연산)
    requiredStake = rmul(bridgedTON, minStakingRatio);

    // S_i: 해당 L2의 시퀀서 스테이킹 양
    currentStake = _getSequencerStake(layer2);

    // S_i ≥ θ · B_i
    eligible = currentStake >= requiredStake;
}

/// @notice 자격 지시 함수 값 (1 또는 0)
function getIndicator(address layer2) public view returns (uint256) {
    (bool eligible,,) = checkEligibility(layer2);
    return eligible ? RAY : 0;
}
```

### 7.2 유효 Bridged TON 조회 (Rule 3)

```solidity
/// @notice 유효 Bridged TON 조회 (캐시된 값)
/// @dev B̃_i = 1_i · B_i (자격 있으면 Bridged TON, 없으면 0)
/// @dev 실시간 값은 onBridgedTONChange, onStakingChange에 의해 유지됨
function getEffectiveBridgedTON(address layer2) public view returns (uint256) {
    return bridgedTONInfo[layer2].effectiveBridgedTON;
}

/// @notice 전체 유효 Bridged TON 조회 (캐시된 값)
/// @dev x = Σ B̃_i (onBridgedTONChange, onStakingChange에 의해 유지됨)
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

V3의 `updateSeigniorage` 함수는 위의 추적 시스템에 의해 실시간으로 유지되는 `totalEffectiveBridgedTON`을 캐시된 값으로 그대로 사용합니다.

```solidity
function _updateSeigniorage() internal ifFree returns (bool) {
    // ... 스테이커 분배 로직 ...

    // ========================================
    // Step 4: 캐시된 전체 유효 Bridged TON 사용
    // (onBridgedTONChange, onStakingChange에 의해 실시간 유지됨)
    // ========================================
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
┌─────────────────┐    deposit/withdraw    ┌──────────────────┐
│  DepositManager │ ────────────────────► │   SeigManager    │
└─────────────────┘    onStakingChange()   │                  │
                                           │  ┌────────────┐  │
┌─────────────────┐    slashSequencer()    │  │ bridged    │  │
│  SeigManager    │ ────────────────────► │  │ TONInfo    │  │
│  (슬래싱)       │    onStakingChange()   │  │ [layer2]   │  │
└─────────────────┘                        │  └────────────┘  │
                                           │        │         │
┌─────────────────┐    TON 입금/출금       │        │         │
│    L1Bridge     │ ────────────────────► │  checkEligibility │
└─────────────────┘  onBridgedTONChange()  │  S_i ≥ θ·B_i ?   │
                                           │        │         │
                                           │        ▼         │
                                           │  totalEffective  │
                                           │  BridgedTON (x)  │
                                           │        │         │
                                           │        ▼         │
                                           │  updateSeig()    │
                                           │  → y(x) 계산     │
                                           └──────────────────┘
```
