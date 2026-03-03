# 4. 보상 분배 로직 & 보안 설계

## 승자 판정 기준

### _distributeBond 수령자 = 승자

`resolveClaim` 함수에서 `_distributeBond(recipient, claim)`가 호출되는 3가지 케이스 모두에서, bond 수령자가 해당 subgame의 **승자**이다.

| 케이스 | 상황 | recipient | 승자 유형 |
|--------|------|-----------|----------|
| Case 1 | 자식 없는 claim: `counteredBy != address(0)` | counteredBy (step 실행자) | 공격적 승리 |
| Case 1 | 자식 없는 claim: `counteredBy == address(0)` | claimant (본인) | 방어적 승리 (bond 회수) |
| Case 2 | L2 block number challenge 성공 | l2BlockNumberChallenger | 공격적 승리 |
| Case 3 | 일반 subgame: `countered != address(0)` | countered (자식 claim 주장자) | subgame 승리 |
| Case 3 | 일반 subgame: `countered == address(0)` | claimant (부모 claim 주장자) | 방어적 승리 (bond 회수) |

### gameCreator 필터링

CHALLENGER_WINS 시나리오에서:
- `gameCreator` = Proposer (패배자)
- `gameCreator`가 아닌 모든 bond 수령자 = Challenger 측 승자

```solidity
function _recordWinningChallenger(address recipient) internal {
    if (recipient == gameCreator()) return;       // Proposer 제외
    if (isWinningChallenger[recipient]) return;   // 중복 방지
    isWinningChallenger[recipient] = true;
    _winningChallengers.push(recipient);
}
```

### 엣지 케이스: Proposer 편 Defender

Proposer를 defend하는 사람이 특정 subgame에서 승리하여 bond를 받을 수 있음. 이 경우 해당 Defender도 `gameCreator`가 아니므로 winning challenger로 기록됨. 현재 설계에서는 단순성을 위해 이를 허용하며, 복잡한 기여도 판정은 향후 가중치 기반 시스템에서 해결 가능.

---

## 분배 공식

```
총 보상금 = 슬래싱된 금액 x slashingRewardRate / 10000
개인 보상 = 총 보상금 / 챌린저 수
나머지(remainder) = 총 보상금 % 챌린저 수 → 첫 번째 챌린저에게 지급
```

### 분배 예시

| 챌린저 수 | 총 보상금 | 개인 보상 | 첫 번째 보상 |
|-----------|-----------|-----------|-------------|
| 1명 | 1000 WTON | 1000 | 1000 |
| 2명 | 1000 WTON | 500 | 500 |
| 3명 | 1000 WTON | 333 | 334 (나머지 1) |
| 5명 | 1000 WTON | 200 | 200 |

### 하위 호환성

단일 challenger인 경우 (`challengers.length == 1`) 기존과 동일하게 동작.

---

## 보안 설계

| 항목 | 구현 방식 |
|------|-----------|
| **Access Control** | `recordWinner()`: `msg.sender == game`만 허용 |
| | `setWinningChallengerTracker()`: `onlyOwner` |
| | `slash()`: `onlyLayer2Manager` |
| **중복 방지** | `isWinner[game][winner]` mapping으로 중복 체크 |
| **DoS 방지** | 최대 Challenger 수 제한 가능 (`MAX_WINNING_CHALLENGERS = 100`) |
| **Reentrancy 방지** | `SafeERC20.safeTransfer` 사용, 외부 호출 전 상태 변경 완료 |
| **Proposer 제외** | `recipient != gameCreator()` 필터링 |
| **외부 호출 안전** | `_recordWinningChallenger`에서 `try-catch` 사용, tracker 호출 실패 시에도 게임 로직 영향 없음 |

---

## Gas 비용

| 항목 | 추가 Gas |
|------|----------|
| 새 승자 기록 (외부 호출 + storage write) | ~25,000 gas |
| 다중 WTON transfer | 챌린저 수 x ~21,000 gas |

---

다음: [05-build-deploy.md](./05-build-deploy.md)
