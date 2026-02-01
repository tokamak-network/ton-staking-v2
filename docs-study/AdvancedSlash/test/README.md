# AdvancedSlashing 테스트 문서

## 테스트 위치

```
test/v3/v3mode/AdvancedSlashing/
├── BaseAdvancedSlashingTest.sol              # 베이스 테스트 컨트랙트
├── SingleChallengerTest.t.sol                # 단일 챌린저 시나리오
├── MultiChallengerEqualDistributionTest.t.sol # 균등 분배 시나리오
├── WinnerTrackingTest.t.sol                  # 승자 추적 시나리오
├── RemainderDistributionTest.t.sol           # 나머지 분배 시나리오
└── RealisticGameFlowTest.t.sol               # 🆕 실제 게임 흐름 시뮬레이션
```

---

## 테스트 실행 방법

```bash
# 전체 AdvancedSlashing 테스트 실행
forge test --match-path "test/v3/v3mode/AdvancedSlashing/*.t.sol" -v

# 특정 테스트 파일 실행
forge test --match-contract SingleChallengerTest -vvv

# 특정 테스트 함수 실행
forge test --match-test test_TwoChallengers_50_50_Split -vvv
```

---

## 테스트 시나리오 상세

### 1. SingleChallengerTest.t.sol

| 테스트 함수 | 설명 |
|------------|------|
| `test_SingleChallenger_ReceivesFullReward` | 단일 챌린저가 전체 보상금 100%를 수령하는지 검증 |
| `test_SingleChallenger_CompatibilityWithOldSystem` | 기존 시스템과의 하위 호환성 검증 |
| `test_SingleChallenger_SmallStake` | 최소 스테이크 금액에서 보상 분배 검증 |
| `test_SingleChallenger_LargeStake` | 대량 스테이크 금액에서 보상 분배 검증 |

---

### 2. MultiChallengerEqualDistributionTest.t.sol

| 테스트 함수 | 설명 |
|------------|------|
| `test_TwoChallengers_50_50_Split` | 2명 챌린저 50:50 균등 분배 검증 |
| `test_ThreeChallengers_EqualSplit` | 3명 챌린저 33.33% 균등 분배 검증 |
| `test_FiveChallengers_EqualSplit` | 5명 챌린저 20% 균등 분배 검증 |
| `test_TotalDistribution_Consistency_1to3` | 1-3명 총 분배금 일관성 검증 |
| `test_TotalDistribution_Consistency_4to5` | 4-5명 총 분배금 일관성 검증 |

---

### 3. WinnerTrackingTest.t.sol

| 테스트 함수 | 설명 |
|------------|------|
| `test_WinnerTracking_BasicFunctionality` | `getWinningChallengers`, `isWinningChallenger` 기본 동작 검증 |
| `test_WinnerTracking_NoDuplicates` | 동일 주소 중복 등록 방지 검증 |
| `test_WinnerTracking_GameCreatorExcluded` | gameCreator(Proposer)가 승자 목록에서 제외되는지 검증 |
| `test_WinnerTracking_EmptyBeforeStep` | step() 호출 전 승자 목록이 비어있는지 검증 |
| `test_WinnerTracking_DataConsistency` | count와 array 길이, mapping 일관성 검증 |

---

### 4. RemainderDistributionTest.t.sol

| 테스트 함수 | 설명 |
|------------|------|
| `test_Remainder_ThreeChallengers` | 3명 분배 시 나머지(1) 처리 검증 |
| `test_Remainder_FourChallengers` | 4명 분배 시 나머지 처리 검증 |
| `test_Remainder_SmallReward` | 작은 보상금에서 나머지 처리 검증 |
| `test_Remainder_LargeRemainder` | 5명 분배 시 큰 나머지(최대 4) 처리 검증 |
| `test_Remainder_ExactDivision` | 나머지 없이 정확히 나누어 떨어지는 경우 검증 |

---

### 5. RealisticGameFlowTest.t.sol 🆕

**실제 FaultDisputeGame 흐름을 시뮬레이션하는 테스트**

| 테스트 함수 | 설명 |
|------------|------|
| `test_SimpleGame_SingleChallenger` | 단순 게임: 1명의 챌린저가 루트 claim 공격 |
| `test_MultiLayerGame_MultipleChallengers` | 다층 게임: 여러 챌린저가 계층적으로 참여 |
| `test_GameWithStep_ProveWrongClaim` | Step을 사용한 게임: 잘못된 claim 증명 |
| `test_MultipleBranches_TwoWinningChallengers` | 다중 분기: 2명의 챌린저가 독립적으로 공격 |
| `test_ComplexGame_ManyChallengers` | 복잡한 게임: 다수의 챌린저가 다양한 경로로 참여 |

**사용되는 Mock:**
- `MockFaultDisputeGame3.sol` - 실제 게임 흐름 시뮬레이션
- `MockDisputeGameFactory3.sol` - 게임 생성 팩토리

---

## BaseAdvancedSlashingTest.sol

테스트용 공통 헬퍼 함수 제공:

```solidity
// 추가 챌린저 주소
address public challenger2;
address public challenger3;
address public challenger4;
address public challenger5;

// 다중 챌린저 게임 설정 헬퍼
function _setupMultiChallengerGame(uint256 numChallengers) internal returns (
    address operatorManager,
    MockFaultDisputeGame2 game,
    GameType gameType,
    Claim rootClaim,
    bytes memory extraData
);

// 챌린저 배열 생성 헬퍼
function _getChallengersByCount(uint256 count) internal view returns (address[] memory);

// 예상 보상금 계산 헬퍼 (WTON 단위)
function _calculateExpectedReward(uint256 stakeAmountTon) internal view returns (uint256 totalRewardWton);
```

---

## 테스트 결과

```
Running 24 tests in AdvancedSlashing...

SingleChallengerTest (4 tests)
  ✓ test_SingleChallenger_ReceivesFullReward
  ✓ test_SingleChallenger_CompatibilityWithOldSystem
  ✓ test_SingleChallenger_SmallStake
  ✓ test_SingleChallenger_LargeStake

MultiChallengerEqualDistributionTest (5 tests)
  ✓ test_TwoChallengers_50_50_Split
  ✓ test_ThreeChallengers_EqualSplit
  ✓ test_FiveChallengers_EqualSplit
  ✓ test_TotalDistribution_Consistency_1to3
  ✓ test_TotalDistribution_Consistency_4to5

WinnerTrackingTest (5 tests)
  ✓ test_WinnerTracking_BasicFunctionality
  ✓ test_WinnerTracking_NoDuplicates
  ✓ test_WinnerTracking_GameCreatorExcluded
  ✓ test_WinnerTracking_EmptyBeforeStep
  ✓ test_WinnerTracking_DataConsistency

RemainderDistributionTest (5 tests)
  ✓ test_Remainder_ThreeChallengers
  ✓ test_Remainder_FourChallengers
  ✓ test_Remainder_SmallReward
  ✓ test_Remainder_LargeRemainder
  ✓ test_Remainder_ExactDivision

RealisticGameFlowTest (5 tests) 🆕
  ✓ test_SimpleGame_SingleChallenger
  ✓ test_MultiLayerGame_MultipleChallengers
  ✓ test_GameWithStep_ProveWrongClaim
  ✓ test_MultipleBranches_TwoWinningChallengers
  ✓ test_ComplexGame_ManyChallengers

24 tests passed, 0 failed
```

---

## 기존 테스트와의 관계

기존 `BasicSlashing/` 폴더의 테스트들도 모두 통과:

| 테스트 파일 | 통과 수 |
|------------|--------|
| SlashingBasicTest.t.sol | 3/3 |
| SlashingSecurityTest.t.sol | 4/4 |
| SlashingDelegatorTest.t.sol | 4/4 |
| SlashingEdgeCaseTest.t.sol | 5/5 |
| SlashingAttackVectorTest.t.sol | 11/11 |
| SlashingRewardRateTest.t.sol | 4/4 |
| SlashingSeigniorageTest.t.sol | 3/3 |
| SlashingMultiOperatorTest.t.sol | 4/4 |
| **총합** | **38/38** |

---

## Mock 컨트랙트

### MockFaultDisputeGame2 (기존)
- 단순화된 게임 Mock
- `step()` 호출 시 즉시 counteredBy 설정
- `addWinningChallenger()` 테스트 헬퍼 함수

### MockFaultDisputeGame3 (신규) 🆕
- 실제 FaultDisputeGame과 유사한 게임 흐름 시뮬레이션
- `move()`: Claim 추가 (공격/방어)
- `step()`: 최대 깊이에서 claim 반박
- `resolveClaim()`: Bottom-up으로 subgame 해결
- `resolve()`: 전체 게임 해결

```solidity
// MockFaultDisputeGame3 사용 예시
MockFaultDisputeGame3 game = new MockFaultDisputeGame3(gameType, rootClaim, extraData, creator);
game.initialize();

// Challenger가 root claim 공격
vm.prank(challenger1);
game.move(0, attackClaim, true);

// Bottom-up 해결
game.resolveClaim(1);
game.resolveClaim(0);
game.resolve();
```

---

## 주의사항

1. **최소 스테이크 금액**: 1000 TON 이상 필요
2. **WTON 단위**: 보상금은 WTON 단위 (TON × 1e9)
3. **Bottom-up 해결**: `resolveClaim()`은 자식부터 부모 순으로 호출해야 함
4. **Game Creator 제외**: Proposer(game creator)는 winning challengers에 포함되지 않음
