# _distributeBond 수령자 = 승자 검증 분석

## 개요

`resolveClaim` 함수에서 `_distributeBond`가 호출되는 모든 케이스를 분석하여, bond 수령자가 실제 "승자"인지 검증합니다.

---

## _distributeBond 호출 케이스 분석

### 케이스 1: 자식이 없는 claim 해결 (Line 786-796)

```solidity
if (challengeIndicesLen == 0 && _claimIndex != 0) {
    address counteredBy = subgameRootClaim.counteredBy;
    address recipient = counteredBy == address(0) ? subgameRootClaim.claimant : counteredBy;
    _distributeBond(recipient, subgameRootClaim);
}
```

**두 가지 상황:**

| counteredBy 값 | recipient | 의미 |
|----------------|-----------|------|
| `address(0)` | `claimant` (원래 주장자) | claim이 counter되지 않음 → 본인 bond 회수 |
| `!= address(0)` | `counteredBy` (step 실행자) | `step()` 함수로 counter됨 → 상대 bond 획득 |

**step() 함수 분석 (Line 468-470):**
```solidity
// INVARIANT: A step cannot be made against a claim for a second time.
if (parent.counteredBy != address(0)) revert DuplicateStep();

// Set the parent claim as countered.
parent.counteredBy = msg.sender;  // step 성공한 사람이 counteredBy가 됨
```

✅ **결론**: `counteredBy != address(0)`인 경우, step을 성공적으로 실행한 사람이 bond를 받음 = **승자**

---

### 케이스 2: L2 Block Number Challenge (Line 850-856)

```solidity
if (_claimIndex == 0 && l2BlockNumberChallenged) {
    address challenger = l2BlockNumberChallenger;
    _distributeBond(challenger, subgameRootClaim);
    subgameRootClaim.counteredBy = challenger;
}
```

✅ **결론**: L2 block number를 성공적으로 challenge한 사람이 bond를 받음 = **승자**

---

### 케이스 3: 일반 Subgame 해결 (Line 857-867)

```solidity
address bondRecipient = countered == address(0) ? subgameRootClaim.claimant : countered;
_distributeBond(bondRecipient, subgameRootClaim);
```

**`countered` 값 결정 로직 (Line 828-831):**
```solidity
// 자식 claim들을 순회하면서
if (claim.counteredBy == address(0) && checkpoint.leftmostPosition.raw() > claim.position.raw()) {
    checkpoint.counteredBy = claim.claimant;  // 가장 왼쪽의 uncountered claim의 claimant
    checkpoint.leftmostPosition = claim.position;
}
```

**분석:**

| countered 값 | bondRecipient | 의미 |
|--------------|---------------|------|
| `address(0)` | `claimant` (부모 claim 주장자) | 모든 자식 claim이 counter됨 → 부모 claim 생존 → 본인 bond 회수 |
| `!= address(0)` | `countered` (자식 claim 주장자) | 자식 claim이 생존함 → 부모 claim 패배 → 자식 주장자가 bond 획득 |

✅ **결론**: counter되지 않은 claim의 주장자가 상대 bond를 받음 = **승자**

---

## 승자 판별 핵심 로직

```
Claim Tree 예시 (CHALLENGER_WINS 시나리오):

[Root Claim] - claimant: Proposer (gameCreator)
     ↓ attack
[Claim 1] - claimant: Challenger A, counteredBy: address(0) ← 생존!
     ↓ attack  
[Claim 2] - claimant: Defender B, counteredBy: Challenger C ← step으로 패배!
```

**Resolution 순서 (bottom-up):**

1. `resolveClaim(2)`: Claim 2가 step으로 counter됨 → Challenger C가 Defender B의 bond 획득
2. `resolveClaim(1)`: Claim 1이 counter되지 않음 (Claim 2가 패배했으므로) → Challenger A가 본인 bond 회수
3. `resolveClaim(0)`: Root가 Claim 1에 의해 counter됨 → Challenger A가 Proposer의 bond 획득

---

## 승자 기록 전략

### 문제점: 모든 bond 수령자가 "공격적 승자"는 아님

| 상황 | recipient | 승리 유형 |
|------|-----------|----------|
| 본인 claim 생존 | 본인 (claimant) | 방어적 승리 (본인 bond 회수) |
| 상대 claim counter | 본인 (counteredBy) | 공격적 승리 (상대 bond 획득) |

### 해결책: gameCreator 제외

**CHALLENGER_WINS 시나리오에서:**
- `gameCreator`는 Proposer (패배자)
- `gameCreator`가 아닌 모든 bond 수령자 = Challenger 측 승자

```solidity
function _recordWinningChallenger(address recipient) internal {
    // gameCreator(Proposer)는 제외
    // - 본인 bond 회수하는 경우도 Proposer이면 제외
    // - 상대 bond 받는 경우는 Proposer가 될 수 없음 (Proposer는 defend 측)
    if (recipient != gameCreator() && !isWinningChallenger[recipient]) {
        isWinningChallenger[recipient] = true;
        winningChallengers.push(recipient);
    }
}
```

---

## 엣지 케이스 분석

### Case A: Proposer 편에서 defend한 사람

```
[Root] - Proposer
   ↓ attack
[Claim 1] - Challenger A
   ↓ attack (defend 목적으로 공격)
[Claim 2] - Defender B (Proposer 편)
```

만약 Claim 2가 생존하면:
- Defender B가 Challenger A의 bond를 받음
- 하지만 최종적으로 CHALLENGER_WINS면, Root가 counter된 것
- Defender B는 gameCreator가 아니므로 winningChallenger로 기록됨

**문제**: Defender B는 Proposer 편인데 reward를 받게 됨

**해결 방안**: 
1. 게임 최종 결과가 CHALLENGER_WINS일 때만 기록
2. 또는 resolve 시점에 누가 "진짜" 승리에 기여했는지는 복잡하므로, 단순히 bond 수령자로 처리

---

### Case B: 같은 사람이 여러 번 bond 수령

- mapping으로 중복 체크하여 한 번만 기록
- 보상은 참여 횟수와 무관하게 균등 분배

---

## 결론

### _distributeBond 수령자 = 승자인가?

| 조건 | 결과 |
|------|------|
| `recipient == claimant` (본인 bond 회수) | 방어적 승자 ✅ |
| `recipient == counteredBy` (상대 bond 획득) | 공격적 승자 ✅ |
| `recipient != gameCreator` | Challenger 측 승자 ✅ |

### 로직이 문제없는 이유

1. **bond 수령 = 해당 subgame에서 승리**: `_distributeBond`는 오직 승자에게만 호출됨
2. **gameCreator 필터링**: Proposer는 제외되므로 Challenger만 남음
3. **중복 방지**: mapping으로 동일 주소 중복 기록 방지
4. **Bottom-up resolution**: 하위 claim부터 resolve되므로 모든 승자가 순차적으로 기록됨

### 최종 구현 권장사항

```solidity
// FaultDisputeGame에 추가
mapping(address => bool) public isWinningChallenger;
address[] internal _winningChallengers;

function _recordWinningChallenger(address recipient) internal {
    if (recipient != gameCreator() && !isWinningChallenger[recipient]) {
        isWinningChallenger[recipient] = true;
        _winningChallengers.push(recipient);
    }
}

function getWinningChallengers() external view returns (address[] memory) {
    return _winningChallengers;
}
```

**호출 위치**: 각 `_distributeBond` 호출 직후
- Line 793 다음
- Line 854 다음  
- Line 861 다음
