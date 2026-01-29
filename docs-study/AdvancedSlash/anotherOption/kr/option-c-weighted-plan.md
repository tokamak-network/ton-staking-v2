# Option C: 가중치 기반 분배 방식

## 개요

첫 번째 승자에게 높은 가중치를 부여하고, 전체 가중치 합계를 기준으로 비례 분배하는 방식입니다.

---

## 핵심 컨셉

```
첫 번째 승자: 가중치 = firstWinnerWeight (예: 2)
나머지 승자들: 가중치 = 1
총 가중치 = firstWinnerWeight + (challengers.length - 1)
각자의 보상 = totalReward × (본인 가중치 / 총 가중치)
```

### 예시 (firstWinnerWeight = 2)

| Challenger 수 | 총 가중치 | 첫 번째 | 두 번째 | 세 번째 |
|---------------|-----------|---------|---------|---------|
| 1명 | 2 | 100% | - | - |
| 2명 | 3 (2+1) | 66.7% | 33.3% | - |
| 3명 | 4 (2+1+1) | 50% | 25% | 25% |
| 5명 | 6 (2+1+1+1+1) | 33.3% | 16.7% | 16.7% (×3) |

---

## 장점

1. **유연성**: 가중치 조정으로 다양한 분배 비율 가능
2. **공정성**: 참여자가 많아져도 첫 번째의 비중이 급격히 떨어지지 않음
3. **확장성**: 향후 역할별 가중치 (예: step 실행자 추가 가중치) 도입 가능
4. **자연스러운 감소**: challenger 증가에 따른 자연스러운 비율 조정

## 단점

1. **계산 복잡성**: 나눗셈과 가중치 계산 필요
2. **예측 어려움**: challenger 수에 따라 첫 번째 보상이 변동
3. **단일 challenger 시**: 가중치가 의미 없음 (어차피 100%)

---

## 수식

```
totalWeight = firstWinnerWeight + (challengers.length - 1)

firstWinnerReward = totalReward × firstWinnerWeight / totalWeight
otherReward = totalReward × 1 / totalWeight
```

### 가중치별 첫 번째 승자 비율

| 가중치 | 2명 | 3명 | 5명 | 10명 |
|--------|-----|-----|-----|------|
| 1.5 | 60% | 50% | 37.5% | 25% |
| 2 | 66.7% | 50% | 33.3% | 20% |
| 3 | 75% | 60% | 42.9% | 27.3% |
| 5 | 83.3% | 71.4% | 55.6% | 38.5% |

---

## 구현 코드

### DepositManager_Slashing.sol

```solidity
/// @notice First winner weight multiplier (in basis points, 10000 = 1x)
/// @dev 20000 = 2x weight, 15000 = 1.5x weight
uint256 public firstWinnerWeight = 20000; // 기본값 2배

/// @notice Set the first winner weight
/// @param newWeight The new weight in basis points (10000 = 1x, 20000 = 2x)
function setFirstWinnerWeight(uint256 newWeight) external onlyOwner {
    require(newWeight >= 10000, "weight must be at least 1x");
    require(newWeight <= 100000, "weight exceeds 10x");
    firstWinnerWeight = newWeight;
    emit FirstWinnerWeightSet(newWeight);
}

/// @notice Distribute rewards based on weight
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
    
    // 총 가중치 계산 (basis points 기준)
    // firstWinnerWeight + (challengers.length - 1) * 10000
    uint256 otherWeight = 10000; // 1x for others
    uint256 totalWeight = firstWinnerWeight + (challengers.length - 1) * otherWeight;
    
    // 첫 번째 승자 보상
    uint256 firstWinnerReward = (totalReward * firstWinnerWeight) / totalWeight;
    IERC20(_wton).safeTransfer(challengers[0], firstWinnerReward);
    emit ChallengerRewarded(layer2, challengers[0], firstWinnerReward);
    
    // 나머지 승자들 보상
    uint256 rewardPerOther = (totalReward * otherWeight) / totalWeight;
    uint256 distributed = firstWinnerReward;
    
    for (uint256 i = 1; i < challengers.length; i++) {
        uint256 amount = rewardPerOther;
        distributed += amount;
        
        // 마지막 사람에게 나머지 지급 (반올림 오차 보정)
        if (i == challengers.length - 1) {
            amount = totalReward - distributed + amount;
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
firstWinnerWeight: 2x

총 가중치: 2
결과:
- Alice: 1000 × (2/2) = 1000 WTON (100%)
```

→ 기존 동작과 동일

### 시나리오 2: 2명 Challenger

```
Challengers: [Alice (first), Bob]
총 보상: 1000 WTON
firstWinnerWeight: 2x

총 가중치: 2 + 1 = 3
결과:
- Alice: 1000 × (2/3) = 666.67 WTON (66.7%)
- Bob: 1000 × (1/3) = 333.33 WTON (33.3%)
```

→ 첫 번째가 2배 보상

### 시나리오 3: 3명 Challenger

```
Challengers: [Alice (first), Bob, Charlie]
총 보상: 1000 WTON
firstWinnerWeight: 2x

총 가중치: 2 + 1 + 1 = 4
결과:
- Alice: 1000 × (2/4) = 500 WTON (50%)
- Bob: 1000 × (1/4) = 250 WTON (25%)
- Charlie: 1000 × (1/4) = 250 WTON (25%)
```

→ Option A (50% 고정)와 동일한 결과!

### 시나리오 4: 10명 Challenger

```
Challengers: [Alice (first), + 9명]
총 보상: 1000 WTON
firstWinnerWeight: 2x

총 가중치: 2 + 9 = 11
결과:
- Alice: 1000 × (2/11) = 181.8 WTON (18.2%)
- 나머지 9명: 1000 × (1/11) = 90.9 WTON씩 (9.1%씩)
```

→ Option A (50% 고정)보다 첫 번째 비율이 낮지만, 나머지도 더 많이 받음

---

## Option A vs Option C 비교 (5명 challenger, 1000 WTON)

| 방식 | 첫 번째 | 나머지 4명 각각 |
|------|---------|-----------------|
| Option A (50%) | 500 WTON | 125 WTON |
| Option C (2x) | 333 WTON | 166 WTON |

**Option A**: 첫 번째 강력 우대
**Option C**: 더 균형잡힌 분배

---

## 설정 가능한 파라미터

| 파라미터 | 설명 | 기본값 | 범위 |
|----------|------|--------|------|
| `firstWinnerWeight` | 첫 번째 승자 가중치 | 20000 (2x) | 10000-100000 |
| `slashingRewardRate` | 전체 슬래싱 보상 비율 | 1000 (10%) | 0-10000 |

---

## 고려 사항

### 1. 가중치 설정 가이드

| 가중치 | 효과 |
|--------|------|
| 1.5x (15000) | 약간의 우대 |
| 2x (20000) | 표준 우대 (권장) |
| 3x (30000) | 강한 우대 |
| 5x (50000) | 매우 강한 우대 |

### 2. 엣지 케이스

- **challenger가 1명**: 전체 보상 수령 (기존과 동일)
- **firstWinnerWeight=10000 (1x)**: 모두 균등 분배 (winning-tracking-plan과 동일)
- **challenger 매우 많음**: 첫 번째 비율이 자연스럽게 감소하되, 여전히 다른 개인보다 높음

### 3. 정밀도 이슈

```solidity
// basis points (10000 = 1x)를 사용하여 정밀도 유지
// 나눗셈 후 나머지는 마지막 참여자에게 지급
```

---

## 확장 가능성

### 향후 역할별 가중치 도입

```solidity
// 예: step 실행자에게 추가 가중치
mapping(address => uint256) public challengerWeight;

function _calculateWeight(address challenger) internal view returns (uint256) {
    if (challenger == firstWinner) return firstWinnerWeight;
    if (stepExecutors[challenger]) return stepperWeight; // 예: 1.5x
    return 10000; // 기본 1x
}
```

---

## 기존 방식과의 비교

| 항목 | 기존 (단일) | winning-tracking (균등) | Option C (가중치) |
|------|-------------|-------------------------|-------------------|
| 첫 번째 보상 | 100% | 1/N | W/(W+N-1) |
| 나머지 보상 | 0% | 1/N | 1/(W+N-1) |
| 구현 복잡도 | 낮음 | 중간 | 중간 |
| 인센티브 | 첫 번째만 | 동등 | 첫 번째 우대 (유연) |
| 확장성 | 낮음 | 중간 | 높음 |

(W = firstWinnerWeight, N = challenger 수)
