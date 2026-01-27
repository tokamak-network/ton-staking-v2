# Option A: 고정 비율 분배 방식

## 개요

첫 번째 승자(root claim을 counter한 사람)에게 전체 보상의 고정 비율을 지급하고, 나머지를 다른 승자들에게 균등 분배하는 방식입니다.

---

## 핵심 컨셉

```
첫 번째 승자: 전체 보상의 firstWinnerRate% 
나머지 승자들: (100 - firstWinnerRate)%를 균등 분배
```

### 예시 (firstWinnerRate = 50%)

| Challenger 수 | 총 보상 | 첫 번째 | 두 번째 | 세 번째 |
|---------------|---------|---------|---------|---------|
| 1명 | 1000 WTON | 1000 | - | - |
| 2명 | 1000 WTON | 500 | 500 | - |
| 3명 | 1000 WTON | 500 | 250 | 250 |
| 5명 | 1000 WTON | 500 | 125 | 125 (×3) |

---

## 장점

1. **단순함**: 계산 로직이 명확하고 이해하기 쉬움
2. **예측 가능**: 첫 번째 승자는 항상 고정된 비율을 받음
3. **강력한 인센티브**: 첫 번째로 도전하려는 동기 부여가 명확
4. **설정 용이**: `firstWinnerRate` 하나만 조정하면 됨

## 단점

1. **불균형 가능성**: challenger가 많아지면 나머지 참여자의 보상이 급격히 감소
2. **참여 저하 우려**: 첫 번째가 아니면 보상이 적어 후속 참여 의욕 저하
3. **단일 challenger 시**: 첫 번째 승자가 전체를 가져감 (기존과 동일)

---

## 수식

```
totalReward = slashedAmount × slashingRewardRate / 10000

if (challengers.length == 1):
    firstWinnerReward = totalReward
else:
    firstWinnerReward = totalReward × firstWinnerRate / 10000
    remainingReward = totalReward - firstWinnerReward
    otherReward = remainingReward / (challengers.length - 1)
```

---

## 구현 코드

### DepositManager_Slashing.sol

```solidity
/// @notice First winner reward rate in basis points (e.g., 5000 = 50%)
uint256 public firstWinnerRate = 5000; // 기본값 50%

/// @notice Set the first winner reward rate
/// @param newRate The new rate in basis points (0-10000)
function setFirstWinnerRate(uint256 newRate) external onlyOwner {
    require(newRate <= 10000, "rate exceeds 100%");
    firstWinnerRate = newRate;
    emit FirstWinnerRateSet(newRate);
}

/// @notice Distribute rewards with fixed ratio for first winner
function _distributeRewards(
    address layer2,
    address[] calldata challengers,
    uint256 totalReward
) internal {
    if (challengers.length == 0) return;
    
    // 단일 challenger인 경우
    if (challengers.length == 1) {
        IERC20(_wton).safeTransfer(challengers[0], totalReward);
        emit ChallengerRewarded(layer2, challengers[0], totalReward);
        return;
    }
    
    // 첫 번째 승자 보상 계산
    uint256 firstWinnerReward = (totalReward * firstWinnerRate) / 10000;
    
    // 나머지 보상 균등 분배
    uint256 remainingReward = totalReward - firstWinnerReward;
    uint256 otherCount = challengers.length - 1;
    uint256 rewardPerOther = remainingReward / otherCount;
    uint256 remainder = remainingReward % otherCount;
    
    // 첫 번째 승자에게 지급
    IERC20(_wton).safeTransfer(challengers[0], firstWinnerReward);
    emit ChallengerRewarded(layer2, challengers[0], firstWinnerReward);
    
    // 나머지 승자들에게 지급
    for (uint256 i = 1; i < challengers.length; i++) {
        uint256 amount = rewardPerOther;
        // 나머지는 두 번째 challenger에게
        if (i == 1) {
            amount += remainder;
        }
        IERC20(_wton).safeTransfer(challengers[i], amount);
        emit ChallengerRewarded(layer2, challengers[i], amount);
    }
}
```

---

## 시나리오별 분석

### 시나리오 1: 단일 Challenger

```
Challenger: Alice
총 보상: 1000 WTON
firstWinnerRate: 50%

결과:
- Alice: 1000 WTON (100%)
```

→ 기존 동작과 동일

### 시나리오 2: 2명 Challenger

```
Challengers: [Alice (first), Bob]
총 보상: 1000 WTON
firstWinnerRate: 50%

결과:
- Alice: 500 WTON (50%)
- Bob: 500 WTON (50%)
```

→ 동등한 분배 (first winner와 나머지가 같은 비율)

### 시나리오 3: 3명 Challenger

```
Challengers: [Alice (first), Bob, Charlie]
총 보상: 1000 WTON
firstWinnerRate: 50%

결과:
- Alice: 500 WTON (50%)
- Bob: 250 WTON (25%)
- Charlie: 250 WTON (25%)
```

→ 첫 번째 승자가 나머지 두 명 합보다 같음

### 시나리오 4: 10명 Challenger

```
Challengers: [Alice (first), + 9명]
총 보상: 1000 WTON
firstWinnerRate: 50%

결과:
- Alice: 500 WTON (50%)
- 나머지 9명: 55.5 WTON씩 (5.5%씩)
```

→ 나머지 참여자의 보상이 매우 적어짐

---

## 설정 가능한 파라미터

| 파라미터 | 설명 | 기본값 | 범위 |
|----------|------|--------|------|
| `firstWinnerRate` | 첫 번째 승자 비율 | 5000 (50%) | 0-10000 |
| `slashingRewardRate` | 전체 슬래싱 보상 비율 | 1000 (10%) | 0-10000 |

---

## 고려 사항

### 1. firstWinnerRate 설정 가이드

| 비율 | 효과 |
|------|------|
| 30% | 첫 번째 우대하되 나머지도 충분한 보상 |
| 50% | 균형잡힌 분배 (기본 권장) |
| 70% | 첫 번째 강력 우대 |

### 2. 엣지 케이스

- **challenger가 1명**: 전체 보상 수령 (기존과 동일)
- **challenger가 2명**: 각각 50%씩 (firstWinnerRate=50% 시)
- **firstWinnerRate=0**: 모두 균등 분배 (기존 winning-challenger-tracking-plan과 동일)
- **firstWinnerRate=10000 (100%)**: 첫 번째만 보상 (기존 단일 challenger 방식과 동일)

---

## 기존 방식과의 비교

| 항목 | 기존 (단일) | winning-tracking (균등) | Option A (고정 비율) |
|------|-------------|-------------------------|---------------------|
| 첫 번째 보상 | 100% | 1/N | firstWinnerRate% |
| 나머지 보상 | 0% | 1/N | (100-firstWinnerRate)/(N-1)% |
| 구현 복잡도 | 낮음 | 중간 | 중간 |
| 인센티브 | 첫 번째만 | 동등 | 첫 번째 우대 |
