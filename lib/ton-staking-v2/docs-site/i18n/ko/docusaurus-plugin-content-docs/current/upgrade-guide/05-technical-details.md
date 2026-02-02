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
        // V2 로직 사용 (delegatecall로 SeigManagerV3_2 호출)
        return _updateSeigniorageV2Delegatecall();
    }

    // V3 로직 호출
    return _updateSeigniorageV3();
}

// V3 시뇨리지 분배 구현
function _distributeV3Seigniorage(uint256 A) internal returns (uint256 l2TotalSeigs, uint256 layer2Seigs) {
    // 1. DAO 고정 분배
    uint256 sDao = (A * daoDistributionRatio) / RAY_UNIT;
    
    // 2. L2 분배 가능량
    uint256 L = A - sDao;

    // 3. 전체 유효 Bridged TON 합계 (캐시)
    uint256 _totalEffective = totalEffectiveBridgedTON;

    if (_totalEffective > 0) {
        // 4. 쌍곡선 포화 함수: y(x) = L · (x / (k + x))
        uint256 y = (L * _totalEffective) / (halfSaturationPoint + _totalEffective);
        l2TotalSeigs = y;

        // 5. Sequencer/Validator 분리
        uint256 totalValReward = (y * validatorDistributionRatio) / RAY_UNIT;
        uint256 totalSeqReward = y - totalValReward;

        // 6. 전체 보상을 한 번에 mint (가스 최적화)
        // Sequencer 보상: layer2Manager로 mint (전체 L2 합계)
        if (totalSeqReward > 0) {
            IWTON(_wton).mint(layer2Manager, totalSeqReward);
        }

        // Validator 보상: validatorReward로 mint (전체 L2 합계)
        if (totalValReward > 0 && validatorReward != address(0)) {
            IWTON(_wton).mint(validatorReward, totalValReward);
        }

        // 7. rewardPerUnit 업데이트 (debt 방식으로 L2별 분배 관리)
        bridgedTONRewardPerUint += (totalSeqReward * WEI_UNIT) / _totalEffective;
        validatorRewardPerUint += (totalValReward * WEI_UNIT) / _totalEffective;

        // 8. 호출한 L2의 보상 claim
        layer2Seigs = _claimL2Rewards();

        // 9. DAO 보상 mint (고정분 + 미분배분)
        _mintDaoReward(sDao, L, y);
    } else {
        // 유효 L2 없음: DAO가 전액 수령
        _mintDaoReward(sDao, L, 0);
    }
}

// L2별 보상 청구 (debt 공식)
function _claimL2Rewards() internal returns (uint256 layer2Seigs) {
    address rollupConfig;
    bool allowed;
    (rollupConfig, allowed) = _allowIssuanceLayer2Seigs(msg.sender);
    if (!allowed || _isExcludedFromSeigniorage(msg.sender)) return 0;

    _syncEffectiveBridgedTon(msg.sender);

    BridgedTONInfo storage info = bridgedTONInfo[msg.sender];
    if (!info.isEligible || info.effectiveBridgedTON == 0) return 0;

    // Sequencer 보상: rewardPerUnit * effectiveBridged - initialDebt
    uint256 seqAccumulated = (bridgedTONRewardPerUint * info.effectiveBridgedTON) / WEI_UNIT;
    layer2Seigs = seqAccumulated - info.initialDebt;

    // Validator 보상: rewardPerUnit * effectiveBridged - validatorInitialDebt
    uint256 valAccumulated = (validatorRewardPerUint * info.effectiveBridgedTON) / WEI_UNIT;
    uint256 valReward = valAccumulated - info.validatorInitialDebt;

    // Sequencer 보상 transfer (이미 layer2Manager에 mint됨)
    if (layer2Seigs > 0) {
        ILayer2Manager(layer2Manager).transferL2Seigniorage(msg.sender, layer2Seigs);
    }

    // Validator 보상 분배 (이미 validatorReward에 mint됨)
    if (valReward > 0 && validatorReward != address(0)) {
        IValidatorReward(validatorReward).distributeL2Rewards(rollupConfig, valReward);
    }

    // initialDebt 업데이트 (다음 claim 시 중복 방지)
    info.initialDebt = seqAccumulated;
    info.validatorInitialDebt = valAccumulated;
}
```

**핵심 차이점:**
1. **V2 로직 분리**: SeigManagerV3_2로 delegatecall하여 V2 로직 실행
2. **가스 최적화**: L2별 개별 mint 대신 전체 합계를 한 번에 mint
3. **Debt 방식**: `rewardPerUnit` 변수로 각 L2의 보상을 추적, claim 시점에 개별 정산
4. **함수명 정확**: `distributeL2Rewards(rollupConfig, valReward)` (systemConfig 사용)

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

**주요 개념:**
- **레거시 Layer2 (Candidate)**: `operator()` → `candidate()` 반환
  - 시퀀서 개인 주소에 담보금 스테이킹
- **OP Stack Layer2 (OperatorManager)**: `operator()` → `manager()` 반환
  - OperatorManager 컨트랙트 주소에 담보금 스테이킹
  - 실제 시퀀서는 OperatorManager의 `candidate()` 함수로 조회

**OP Stack Layer2의 경우:**
```solidity
// OperatorManager 구조
address operatorManagerAddress = Layer2I(layer2).operator();  // OperatorManager 주소
address actualSequencer = ICandidate(operatorManagerAddress).candidate();  // 실제 시퀀서 주소

// 담보금은 OperatorManager 주소에 스테이킹됨
uint256 collateral = coinage.balanceOf(operatorManagerAddress);
```

### 검증자 담보금

```solidity
// RAT.sol
function _getValidatorCollateral(address validator, address systemConfig)
    internal view returns (uint256 collateral, address layer2)
{
    layer2 = ILayer2Manager(layer2Manager).getLayer2BySystemConfig(systemConfig);
    if (layer2 == address(0)) return (0, address(0));

    // SeigManager를 통해 coinage 조회
    collateral = ISeigManagerForRAT(seigManager).stakeOf(layer2, validator);
}
```

**참고**: 실제 구현은 `(collateral, layer2)` 튜플을 반환하여 중복 조회를 방지합니다.

## RAT Coinage 전송 구현 (신규)

**SeigManagerV3_1.sol** - RAT 연동 함수
```solidity
// 검증자 → RAT으로 coinage 전송 (슬래싱 선차감)
function transferCoinageToRat(address layer2, address validator, uint256 amount)
    external onlyRat whenV3Active
{
    RefactorCoinageSnapshotI coinage = _coinages[layer2];
    _checkCoinage(address(coinage));
    coinage.burnFrom(validator, amount);  // 검증자에서 burn
    coinage.mint(ratContract, amount);    // RAT에 mint

    emit CoinageTransferredForRAT(layer2, validator, ratContract, amount);
}

// RAT → 검증자로 coinage 전송 (복구)
function transferCoinageFromRat(address layer2, address validator, uint256 amount)
    external onlyRat whenV3Active
{
    RefactorCoinageSnapshotI coinage = _coinages[layer2];
    _checkCoinage(address(coinage));
    coinage.burnFrom(ratContract, amount);  // RAT에서 burn
    coinage.mint(validator, amount);        // 검증자에게 mint

    emit CoinageTransferredForRAT(layer2, ratContract, validator, amount);
}

// RAT → 임의 주소로 coinage 전송 (Treasury 인출용)
function transferCoinageFromRatTo(address layer2, address recipient, uint256 amount)
    external onlyRat
{
    RefactorCoinageSnapshotI coinage = _coinages[layer2];
    _checkCoinage(address(coinage));
    coinage.burnFrom(ratContract, amount);  // RAT에서 burn
    coinage.mint(recipient, amount);        // recipient에 mint

    emit CoinageTransferredForRAT(layer2, ratContract, recipient, amount);
}
```

> **⚠️ 중요**: 
> - RAT은 coinage를 직접 조작할 권한이 없으므로, 반드시 SeigManager를 경유해야 합니다.
> - 함수명은 `transferCoinageToRat` (대문자 RAT 아님)
> - modifier는 `onlyRat whenV3Active` (V3 마이그레이션 후에만 사용)
> - 이벤트는 `CoinageTransferredForRAT` (3개 파라미터: from, to, amount 포함)

**RAT.sol** - SeigManager 호출
```solidity
// 검증자 → RAT로 coinage 전송
function _transferCoinageToRAT(address layer2, address validator, uint256 amount) internal {
    ISeigManagerForRAT(seigManager).transferCoinageToRat(layer2, validator, amount);
}

// RAT → 검증자로 coinage 전송 (복구)
function _transferCoinageFromRAT(address layer2, address validator, uint256 amount) internal {
    ISeigManagerForRAT(seigManager).transferCoinageFromRat(layer2, validator, amount);
}
```
