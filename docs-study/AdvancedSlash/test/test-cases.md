# AdvancedSlashing 테스트 케이스 상세

## 목차
- [시나리오 1-4: 단일 챌린저](#시나리오-1-단일-챌린저-singlechallengertest)
- [시나리오 5-9: 균등 분배](#시나리오-2-5-균등-분배-multichallengerequaldistributiontest)
- [시나리오 10-14: 승자 추적](#시나리오-6-10-승자-추적-winnertrackingtest)
- [시나리오 15-19: 나머지 분배](#시나리오-11-15-나머지-분배-remainderdistributiontest)
- [시나리오 20-24: 실제 게임 흐름](#시나리오-16-20-실제-게임-흐름-realisticgameflowtest-) 🆕

---

## 시나리오 1: 단일 챌린저 (SingleChallengerTest)

### test_SingleChallenger_ReceivesFullReward

**목적:** 단일 챌린저가 전체 보상금을 수령하는지 검증

**시나리오:**
1. Operator가 10,000 TON 스테이크
2. 1명의 Challenger가 DisputeGame에서 승리
3. 슬래싱 실행

**검증:**
- `getWinningChallengersCount() == 1`
- Challenger 보상 = 총 보상금 × 100%

**예상 결과:**
```
Total Reward: 1,000,000,000,000,000,000,000,000,000,000 (1000 * 1e27 WTON)
Challenger Reward: 1,000,000,000,000,000,000,000,000,000,000 (100%)
```

---

### test_SingleChallenger_CompatibilityWithOldSystem

**목적:** 기존 시스템과의 하위 호환성 검증

**시나리오:**
1. 기존 `_makeChallengerWin()` 플로우 사용
2. 슬래싱 실행

**검증:**
- 단일 챌린저 시 기존 로직과 동일한 결과

---

## 시나리오 2-5: 균등 분배 (MultiChallengerEqualDistributionTest)

### test_TwoChallengers_50_50_Split

**목적:** 2명 챌린저의 50:50 분배 검증

**시나리오:**
1. Operator가 10,000 TON 스테이크
2. 2명의 Challenger가 승리
3. 슬래싱 실행

**검증:**
- `getWinningChallengersCount() == 2`
- Challenger 1 보상 = 50%
- Challenger 2 보상 = 50%
- 총 분배금 = 총 보상금

**예상 결과:**
```
Total Reward: 1,000 * 1e27 WTON
Challenger 1: 500 * 1e27 WTON (50%)
Challenger 2: 500 * 1e27 WTON (50%)
```

---

### test_ThreeChallengers_EqualSplit

**목적:** 3명 챌린저의 균등 분배 + 나머지 처리 검증

**시나리오:**
1. 3명의 Challenger가 승리
2. 슬래싱 실행

**검증:**
- Challenger 1 = baseShare + remainder
- Challenger 2, 3 = baseShare

**예상 결과:**
```
Total: 1,000 * 1e27 WTON
Base: 333.33... * 1e27 WTON
Remainder: 1 wei

Challenger 1: 333,333,333,333,333,333,333,333,333,334 (base + 1)
Challenger 2: 333,333,333,333,333,333,333,333,333,333 (base)
Challenger 3: 333,333,333,333,333,333,333,333,333,333 (base)
```

---

### test_FiveChallengers_EqualSplit

**목적:** 5명 챌린저의 20% 균등 분배 검증

**시나리오:**
1. 5명의 Challenger가 승리
2. 슬래싱 실행

**검증:**
- 각 Challenger ≈ 20%
- 첫 번째에게 나머지 지급

---

## 시나리오 6-10: 승자 추적 (WinnerTrackingTest)

### test_WinnerTracking_BasicFunctionality

**목적:** 승자 추적 기본 API 동작 검증

**검증 항목:**
1. `getWinningChallengers()` 반환 배열 정확성
2. `getWinningChallengersCount()` 정확성
3. `isWinningChallenger(addr)` 반환값 정확성

---

### test_WinnerTracking_NoDuplicates

**목적:** 동일 주소 중복 등록 방지 검증

**시나리오:**
1. Challenger A가 step() 호출
2. `addWinningChallenger(A)` 3번 호출
3. `addWinningChallenger(B)` 2번 호출

**검증:**
- `getWinningChallengersCount() == 2` (A, B 각 1번씩만)

---

### test_WinnerTracking_GameCreatorExcluded

**목적:** gameCreator(Proposer)가 승자 목록에서 제외되는지 검증

**검증:**
- `isWinningChallenger(gameCreator()) == false`

---

### test_WinnerTracking_EmptyBeforeStep

**목적:** 게임 시작 전 승자 목록 초기 상태 검증

**검증:**
- `getWinningChallengersCount() == 0`
- `getWinningChallengers().length == 0`

---

### test_WinnerTracking_DataConsistency

**목적:** 승자 데이터 일관성 검증

**검증:**
- count == array.length
- array의 모든 요소가 mapping에서 true
- 비승자는 mapping에서 false

---

## 시나리오 11-15: 나머지 분배 (RemainderDistributionTest)

### test_Remainder_ThreeChallengers

**목적:** 3으로 나눌 때 나머지 1 처리 검증

**검증:**
- 첫 번째 = baseShare + 1
- 나머지 = baseShare

---

### test_Remainder_FourChallengers

**목적:** 4명 분배 시 나머지 처리 검증

---

### test_Remainder_SmallReward

**목적:** 작은 보상금에서도 정확한 분배 검증

**시나리오:**
1. 최소 스테이크 (1001 TON)
2. 3명 분배

**검증:**
- 총 분배금 = 총 보상금 (손실 없음)

---

### test_Remainder_LargeRemainder

**목적:** 5명 분배 시 큰 나머지(최대 4) 처리 검증

**시나리오:**
1. 10,001 TON 스테이크 (나머지 발생하도록)
2. 5명 분배

**검증:**
- 첫 번째 = baseShare + remainder
- 나머지 4명 = baseShare

---

### test_Remainder_ExactDivision

**목적:** 나머지 없이 정확히 나누어 떨어지는 경우 검증

**시나리오:**
1. 10,000 TON 스테이크
2. 2명 분배 (1000 / 2 = 500, 나머지 0)

**검증:**
- Challenger 1 == Challenger 2

---

## 시나리오 16-20: 실제 게임 흐름 (RealisticGameFlowTest) 🆕

> **MockFaultDisputeGame3**를 사용하여 실제 FaultDisputeGame의 게임 흐름을 시뮬레이션합니다.

### 사용되는 Mock 컨트랙트

| 컨트랙트 | 설명 |
|---------|------|
| `MockFaultDisputeGame3.sol` | 실제 게임 흐름 시뮬레이션 (move, step, resolveClaim) |
| `MockDisputeGameFactory3.sol` | MockFaultDisputeGame3 생성 팩토리 |

### MockFaultDisputeGame3 주요 함수

```solidity
// Claim 추가 (공격 또는 방어)
function move(uint256 _challengeIndex, Claim _claim, bool _isAttack) external payable;

// 최대 깊이에서 claim 반박 (step)
function step(uint256 _claimIndex) external;

// Subgame 해결 (bottom-up으로 호출해야 함)
function resolveClaim(uint256 _claimIndex) external;

// 전체 게임 해결
function resolve() external returns (GameStatus);
```

---

### test_SimpleGame_SingleChallenger

**목적:** 단순 게임 흐름 - 1명의 챌린저가 루트 claim 반박

**게임 트리:**
```
[0] Root (Proposer) - Invalid claim
 └── [1] Attack by Challenger1 (uncountered)
```

**시나리오:**
1. Proposer가 게임 생성 (잘못된 root claim)
2. Challenger1이 root claim 공격 (`move(0, claim, true)`)
3. Proposer가 응답하지 않음 (timeout)
4. Bottom-up 해결: `resolveClaim(1)` → `resolveClaim(0)`
5. 게임 해결: `resolve()`

**검증:**
- `status == CHALLENGER_WINS`
- `getWinningChallengersCount() == 1`
- `isWinningChallenger(challenger1) == true`
- `isWinningChallenger(proposer) == false`

---

### test_MultiLayerGame_MultipleChallengers

**목적:** 다층 게임 - 여러 챌린저가 계층적으로 참여

**게임 트리:**
```
[0] Root (Proposer)
 └── [1] Attack by Challenger1
      └── [2] Attack by Challenger2 (counters Challenger1)
           └── [3] Attack by Challenger3 (counters Challenger2)
```

**시나리오:**
1. Proposer가 게임 생성
2. Challenger1이 root 공격 [index 1]
3. Challenger2가 Challenger1의 claim 공격 [index 2]
4. Challenger3가 Challenger2의 claim 공격 [index 3]
5. Bottom-up 해결: 3 → 2 → 1 → 0

**검증:**
- 최종 승자는 게임 해결 로직에 따라 결정됨
- 승리한 챌린저들이 `_winningChallengers`에 기록됨

**예상 결과:**
```
Winning challengers: 2
Winner 0: Challenger3 (won subgame at index 3)
Winner 1: Challenger1 (won subgame at index 1)
```

---

### test_GameWithStep_ProveWrongClaim

**목적:** Step을 사용한 게임 - 잘못된 claim 증명

**게임 트리:**
```
[0] Root (Proposer)
 └── [1] Attack by Challenger1 (stepped by Proposer)
```

**시나리오:**
1. Proposer가 게임 생성
2. Challenger1이 root 공격
3. **Proposer가 step()으로 Challenger1의 claim 반박** (잘못된 claim 증명)
4. 해결: `resolveClaim(1)` → `resolveClaim(0)`

**검증:**
- `status == DEFENDER_WINS` (Proposer 승리)
- `getWinningChallengersCount() == 0` (Proposer는 game creator이므로 제외)

---

### test_MultipleBranches_TwoWinningChallengers

**목적:** 다중 분기 - 2명의 챌린저가 독립적으로 루트 공격

**게임 트리:**
```
[0] Root (Proposer)
 ├── [1] Attack by Challenger1 (uncountered)
 └── [2] Attack by Challenger2 (uncountered)
```

**시나리오:**
1. Proposer가 게임 생성
2. Challenger1이 root 공격 [index 1]
3. Challenger2가 root 공격 [index 2]
4. 해결: `resolveClaim(1)` → `resolveClaim(2)` → `resolveClaim(0)`

**검증:**
- `status == CHALLENGER_WINS`
- `getWinningChallengersCount() == 2`
- 두 챌린저 모두 승자로 기록됨

**예상 결과:**
```
Winning challengers: 2
Winner 0: Challenger1
Winner 1: Challenger2
```

---

### test_ComplexGame_ManyChallengers

**목적:** 복잡한 게임 트리 - 다수의 챌린저가 다양한 경로로 참여

**게임 트리:**
```
[0] Root (Proposer)
 ├── [1] C1 attacks root
 │    └── [3] C2 attacks C1
 └── [2] C3 attacks root
      └── [4] C1 attacks C3
```

**시나리오:**
1. Proposer가 게임 생성
2. Challenger1이 root 공격 [1]
3. Challenger3가 root 공격 [2]
4. Challenger2가 C1의 claim 공격 [3]
5. Challenger1이 C3의 claim 공격 [4]
6. Bottom-up 해결: 3 → 4 → 1 → 2 → 0

**검증:**
- 복잡한 게임 트리에서도 승자 추적이 정확히 동작
- 중복 없이 승자 기록

---

## 실제 FaultDisputeGame vs MockFaultDisputeGame3 비교

| 기능 | 실제 FaultDisputeGame | MockFaultDisputeGame3 |
|------|----------------------|----------------------|
| `move()` | Claim 추가, position 계산, bond 처리 | Claim 추가, position 계산 |
| `step()` | VM 실행, prestate/poststate 검증 | 단순 counteredBy 설정 |
| `resolveClaim()` | Bottom-up 해결, bond 분배 | Bottom-up 해결, credit 기록 |
| `_recordWinningChallenger()` | 승자 추적 | 승자 추적 |
| Clock 관리 | MAX_CLOCK_DURATION 체크 | 없음 (테스트 단순화) |
| Bond 관리 | DelayedWETH 사용 | 단순 credit mapping |

### Mock의 단순화된 부분

1. **Clock 검증 생략**: 테스트에서 시간 관련 검증 불필요
2. **Bond 전송 단순화**: DelayedWETH 대신 내부 credit mapping 사용
3. **VM 실행 생략**: step()에서 VM 실행 없이 단순히 counteredBy 설정
4. **Position 검증 단순화**: MAX_GAME_DEPTH 등 깊이 검증 생략
