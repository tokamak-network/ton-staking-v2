# Option B: 보너스 + 균등 분배 방식

## 개요

첫 번째 승자(root claim을 counter한 사람)에게 전체 보상의 고정 비율을 **보너스로** 지급하고, 나머지 금액은 **첫 번째 포함 모든 승자들에게** 균등 분배하는 방식입니다.

---

## 핵심 컨셉

```
첫 번째 승자: (전체 보상 × firstWinnerRate%) + (나머지 / 전체 인원)
나머지 승자들: 나머지 / 전체 인원
```

### 수식

```
firstWinnerBonus = totalReward × firstWinnerRate / 10000
remainingReward = totalReward - firstWinnerBonus
equalShare = remainingReward / challengers.length

첫 번째 승자 = firstWinnerBonus + equalShare
나머지 승자 = equalShare
```

---

## 분배 예시 (firstWinnerRate = 50%)

| Challenger 수 | 총 보상 | 보너스 (50%) | 나머지 | 균등 몫 | 첫 번째 | 나머지 각각 |
|---------------|---------|--------------|--------|---------|---------|-------------|
| 1명 | 1000 | 500 | 500 | 500 | **1000** | - |
| 2명 | 1000 | 500 | 500 | 250 | **750** | 250 |
| 3명 | 1000 | 500 | 500 | 166.7 | **666.7** | 166.7 |
| 4명 | 1000 | 500 | 500 | 125 | **625** | 125 |
| 5명 | 1000 | 500 | 500 | 100 | **600** | 100 |
| 10명 | 1000 | 500 | 500 | 50 | **550** | 50 |

---

## 장점

1. **첫 번째 강력 인센티브**: 보너스 + 균등 몫을 모두 받음
2. **후속 참여자 공정성**: 첫 번째도 균등 분배에 참여하므로 공정
3. **참여 촉진**: 첫 번째가 아니어도 일정 보상 보장
4. **최소 보장**: 첫 번째는 항상 firstWinnerRate% 이상 보장
5. **예측 가능**: 보너스 비율이 고정되어 있음

## 단점

1. **첫 번째 비중 큼**: 50% 설정 시 항상 절반 이상 가져감 (실제로는 10~20%사이 값으로 설정하면 좋을 것 같습니다.)
2. **challenger 많으면**: 나머지 개인별 보상이 매우 작아짐
3. **Option A보다 복잡**: 첫 번째도 균등 분배에 포함

---

## 구현 코드

### DepositManager_Slashing.sol

```solidity
/// @notice First winner bonus rate in basis points (e.g., 5000 = 50%)
uint256 public firstWinnerRate = 5000; // 기본값 50%

/// @notice Set the first winner bonus rate
/// @param newRate The new rate in basis points (0-10000)
function setFirstWinnerRate(uint256 newRate) external onlyOwner {
    require(newRate <= 10000, "rate exceeds 100%");
    firstWinnerRate = newRate;
    emit FirstWinnerRateSet(newRate);
}

/// @notice Distribute rewards: first winner gets bonus + equal share
function _distributeRewards(
    address layer2,
    address[] calldata challengers,
    uint256 totalReward
) internal {
    if (challengers.length == 0) return;
    
    // 단일 challenger인 경우 - 전체 보상
    if (challengers.length == 1) {
        IERC20(_wton).safeTransfer(challengers[0], totalReward);
        emit ChallengerRewarded(layer2, challengers[0], totalReward);
        return;
    }
    
    // 첫 번째 승자 보너스 계산
    uint256 firstWinnerBonus = (totalReward * firstWinnerRate) / 10000;
    
    // 나머지 금액을 모든 참여자(첫 번째 포함)에게 균등 분배
    uint256 remainingReward = totalReward - firstWinnerBonus;
    uint256 equalShare = remainingReward / challengers.length;
    uint256 remainder = remainingReward % challengers.length;
    
    // 첫 번째 승자: 보너스 + 균등 몫 + 나머지
    uint256 firstWinnerTotal = firstWinnerBonus + equalShare + remainder;
    IERC20(_wton).safeTransfer(challengers[0], firstWinnerTotal);
    emit ChallengerRewarded(layer2, challengers[0], firstWinnerTotal);
    
    // 나머지 승자들: 균등 몫만
    for (uint256 i = 1; i < challengers.length; i++) {
        IERC20(_wton).safeTransfer(challengers[i], equalShare);
        emit ChallengerRewarded(layer2, challengers[i], equalShare);
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

계산:
- 보너스: 500 WTON
- 나머지: 500 WTON
- 균등 몫: 500 / 1 = 500 WTON

결과:
- Alice: 500 + 500 = 1000 WTON (100%)
```

### 시나리오 2: 2명 Challenger

```
Challengers: [Alice (first), Bob]
총 보상: 1000 WTON
firstWinnerRate: 50%

계산:
- 보너스: 500 WTON
- 나머지: 500 WTON
- 균등 몫: 500 / 2 = 250 WTON

결과:
- Alice: 500 + 250 = 750 WTON (75%)
- Bob: 250 WTON (25%)
```

### 시나리오 3: 4명 Challenger

```
Challengers: [Alice (first), Bob, Charlie, David]
총 보상: 1000 WTON
firstWinnerRate: 50%

계산:
- 보너스: 500 WTON
- 나머지: 500 WTON
- 균등 몫: 500 / 4 = 125 WTON

결과:
- Alice: 500 + 125 = 625 WTON (62.5%)
- Bob: 125 WTON (12.5%)
- Charlie: 125 WTON (12.5%)
- David: 125 WTON (12.5%)
```

### 시나리오 4: 10명 Challenger

```
Challengers: [Alice (first), + 9명]
총 보상: 1000 WTON
firstWinnerRate: 50%

계산:
- 보너스: 500 WTON
- 나머지: 500 WTON
- 균등 몫: 500 / 10 = 50 WTON

결과:
- Alice: 500 + 50 = 550 WTON (55%)
- 나머지 9명: 50 WTON씩 (5%씩)
```

---

## 첫 번째 승자 비율 변화

| Challenger 수 | 첫 번째 비율 (50% 보너스) |
|---------------|--------------------------|
| 1명 | 100% |
| 2명 | 75% |
| 3명 | 66.7% |
| 4명 | 62.5% |
| 5명 | 60% |
| 10명 | 55% |
| 100명 | 50.5% |

→ **challenger가 아무리 많아도 첫 번째는 항상 50% 이상 보장**

---

## 설정 가능한 파라미터

| 파라미터 | 설명 | 기본값 | 범위 |
|----------|------|--------|------|
| `firstWinnerRate` | 첫 번째 승자 보너스 비율 | 5000 (50%) | 0-10000 |
| `slashingRewardRate` | 전체 슬래싱 보상 비율 | 1000 (10%) | 0-10000 |

---

## firstWinnerRate 설정 가이드

| 비율 | 2명 시 첫 번째 | 4명 시 첫 번째 | 특징 |
|------|---------------|---------------|------|
| 30% | 65% | 47.5% | 약한 우대 |
| 50% | 75% | 62.5% | 중간 우대 (권장) |
| 70% | 85% | 77.5% | 강한 우대 |

---

## 엣지 케이스

| 케이스 | 결과 |
|--------|------|
| challenger 1명 | 전체 보상 (기존과 동일) |
| firstWinnerRate = 0 | 완전 균등 분배 |
| firstWinnerRate = 10000 (100%) | 첫 번째만 보상 (나머지 0) |

---

## Option A vs Option B 비교 (1000 WTON, 50% 설정)

| Challenger 수 | Option A 첫 번째 | Option A 나머지 | Option B 첫 번째 | Option B 나머지 |
|---------------|-----------------|-----------------|-----------------|-----------------|
| 2명 | 500 | 500 | **750** | 250 |
| 3명 | 500 | 250 | **666.7** | 166.7 |
| 4명 | 500 | 166.7 | **625** | 125 |
| 5명 | 500 | 125 | **600** | 100 |

**차이점:**
- **Option A**: 첫 번째 고정 500, 나머지 균등 분배
- **Option B**: 첫 번째 500 + 균등 몫, 나머지 균등 몫만
