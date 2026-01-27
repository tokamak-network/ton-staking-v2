# Multi-Challenger Reward Distribution 구현 계획

## 현재 구조 분석

**현재 흐름:**

1. `Layer2Manager_Slashing.slashingCandidate()` → `_getWinningChallenger()` → `claimData(0).counteredBy` (단일 주소)
2. `DepositManager_Slashing.slash(challenger)` → 단일 challenger에게 전체 reward 전송

**문제점:**

- FaultDisputeGame에서 여러 challenger가 참여할 수 있지만, 현재는 root claim을 counter한 첫 번째 challenger만 reward를 받음

---

## 변경 전략

FaultDisputeGame의 `claimData`를 순회하여 모든 참여 challenger를 추출하고, reward를 균등 분배합니다.

### 핵심 로직

- `claimDataLen()`으로 전체 claim 수를 조회
- 각 `claimData(i)`에서 `claimant` 주소 수집
- `gameCreator()` (proposer/defender) 제외
- 중복 제거 후 unique challenger 목록 생성
- reward를 `totalReward / challengers.length`로 균등 분배

---

## 파일별 수정 사항

### 1. IFaultDisputeGame 인터페이스 확장

**파일:** `src/layer2/interfaces/IFaultDisputeGame.sol`

```solidity
// 추가할 함수
function claimDataLen() external view returns (uint256 len_);
function gameCreator() external pure returns (address creator_);
```

### 2. Layer2Manager_Slashing 수정

**파일:** `src/layer2/Layer2Manager_Slashing.sol`

**변경 사항:**

- `_getWinningChallenger()` → `_getAllWinningChallengers()` 로 변경
- 반환 타입: `address` → `address[]`
- `claimData`를 순회하여 모든 unique claimant 수집 (gameCreator 제외)

```solidity
function _getAllWinningChallengers(address disputeGame) 
    internal view returns (address[] memory challengers) 
{
    uint256 len = IFaultDisputeGame(disputeGame).claimDataLen();
    address creator = IFaultDisputeGame(disputeGame).gameCreator();
    
    // 임시 배열로 수집 후 unique 주소만 반환
    // ...
}
```

### 3. IIDepositManager 인터페이스 수정

**파일:** `src/stake/interfaces/IIDepositManager.sol`

```solidity
// 기존
function slash(address layer2, address operator, address challenger) external returns (bool);

// 변경
function slash(address layer2, address operator, address[] calldata challengers) external returns (bool);
```

### 4. DepositManager_Slashing 수정

**파일:** `src/stake/managers/DepositManager_Slashing.sol`

**변경 사항:**

- `slash()` 함수 시그니처 변경: `address challenger` → `address[] calldata challengers`
- reward 균등 분배 로직 추가

```solidity
function slash(
    address layer2,
    address operator,
    address[] calldata challengers
) external onlyLayer2Manager returns (bool) {
    // ...
    uint256 rewardPerChallenger = rewardAmount / challengers.length;
    uint256 remainder = rewardAmount % challengers.length;
    
    for (uint256 i = 0; i < challengers.length; i++) {
        uint256 amount = rewardPerChallenger;
        if (i == 0) amount += remainder; // 나머지는 첫 번째에게
        IERC20(_wton).safeTransfer(challengers[i], amount);
        emit ChallengerRewarded(layer2, challengers[i], amount);
    }
    // ...
}
```

### 5. 이벤트 수정

**DepositManager_Slashing.sol:**

```solidity
// 기존 이벤트 유지하면서 새 이벤트 추가 (선택적)
event ChallengersRewarded(address indexed layer2, address[] challengers, uint256[] amounts);
```

---

## 테스트 업데이트

**파일:** `test/v3/v3mode/BasicSlashing/SlashingMultiOperatorTest.t.sol`

기존 `test_Slashing_MultipleChallengers_FirstWins` 테스트를 다음으로 변경:

- `test_Slashing_MultipleChallengers_EqualDistribution`
- 여러 challenger가 move를 수행하고 모두 동일한 reward를 받는지 검증

---

## TODO 체크리스트

- [ ] IFaultDisputeGame 인터페이스에 claimDataLen(), gameCreator() 추가
- [ ] Layer2Manager_Slashing에서 _getAllWinningChallengers() 구현
- [ ] IIDepositManager 인터페이스 slash() 시그니처 변경
- [ ] DepositManager_Slashing에서 다중 challenger reward 분배 로직 구현
- [ ] 테스트 케이스 업데이트 (다중 challenger 균등 분배 검증)

---

## 고려 사항

1. **Gas 비용**: challenger가 많을수록 transfer 횟수 증가 → gas 비용 증가
2. **최대 challenger 수 제한**: DoS 방지를 위해 최대 수 제한 고려 (예: 100명)
3. **나머지 처리**: `rewardAmount % challengers.length`의 나머지 wei 처리 (첫 번째 challenger에게 추가)
4. **중복 제거**: 동일 주소가 여러 claim을 만든 경우 한 번만 카운트

---

## 논의 필요 사항

### 질문 1: Challenger 추출 방식

현재 제안은 게임에 참여한 모든 claimant를 challenger로 간주합니다. 하지만:
- 일부 claimant가 proposer를 "defend"하는 경우도 있을 수 있음
- 단순히 참여만 했지만 실제로 승리에 기여하지 않은 경우도 있음

**대안적 접근법들:**
1. **모든 참여자 균등 분배** (현재 제안) - 가장 단순
2. **성공적으로 counter한 사람만** - `counteredBy`가 본인인 claim이 있는 사람만
3. **가중치 기반 분배** - 참여 횟수나 bond 크기에 따라

### 질문 2: 중복 제거 처리

- On-chain에서 중복 제거를 처리할지
- Off-chain에서 미리 challenger 목록을 계산해서 전달할지

### 질문 3: 최대 Challenger 수 제한

DoS 방지를 위해 최대 수 제한이 필요한지?

```solidity
require(challengers.length <= MAX_CHALLENGERS, "too many challengers");
```
