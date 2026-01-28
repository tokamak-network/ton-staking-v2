---
id: upgrade-technical-details
sidebar_position: 5
---

# 기술 구현 상세

## 컨트랙트 버전 비교

| 컨트랙트 | V2 (현재 메인넷) | V3 (업그레이드) | 상태 |
|---------|----------------|---------------|------|
| **SeigManager** | V1_3 (0xce18...F628) | V1_4 (미배포) | ✅ 완료 |
| **DepositManager** | V1_1 | V1_2 | ✅ 완료 |
| **Layer2Manager** | V1_1 | V1_2 | ✅ 완료 |
| **L1BridgeRegistry** | V1_1 | V1_2 (단일 구현체) | ✅ 완료 |
| **RAT** | 없음 | 신규 배포 | ✅ 완료 |
| **ValidatorReward** | 없음 | 신규 배포 | ✅ 완료 |

## 시뇨리지 분배 로직 변경

### V2 구현 (SeigManagerV1_3, 현재 메인넷)
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

### V3 구현 (SeigManagerV3_1, 업그레이드)
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

## 담보금 조회 방식 (V3 신규)

### 시퀀서 담보금

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

### 검증자 담보금

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

## RAT Coinage 전송 구현 (신규)

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
