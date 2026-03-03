# 4. 핵심 비즈니스 로직 설명

[← 목차로 돌아가기](./README.md) | [← 이전: 디렉토리 구조](./03-directory-structure.md)

---

## 4.1 주요 모듈

### 4.1.1 LotteryCandidate (핵심 컨트랙트)

**파일:** `src/dao/LotteryCandidate.sol`
**상속 체인:** `ProxyStorage` → `AccessibleCommon` → `LotteryCandidateStorage` → `ILayer2`

LotteryCandidate는 **ILayer2 인터페이스를 구현하여 자기 자신을 Layer2로 위장**한다. 이를 통해 Tokamak의 기존 스테이킹 인프라(`DepositManager`, `SeigManager`)와 호환되면서도, 내부적으로 사용자별 잔액을 별도 추적하고 복권 시스템을 운영한다.

**기존 Candidate와의 핵심 차이:**

| 항목 | Candidate | LotteryCandidate |
|------|-----------|------------------|
| 예치 방식 | 사용자가 직접 `DepositManager`에 스테이킹 | 사용자가 LotteryCandidate에 예치 → LotteryCandidate가 `DepositManager`에 통합 스테이킹 |
| 잔액 추적 | `SeigManager`의 Coinage 토큰으로 직접 추적 | 내부 `_balances` 매핑으로 별도 추적 |
| 복권 기능 | 없음 | 라운드 기반 복권 시스템 |
| 시뇨리지 | `SeigManager`가 직접 Coinage에 반영 | LotteryCandidate가 Coinage 증가분을 수동 분배 |

### 4.1.2 LotteryCandidateFactory (팩토리)

**파일:** `src/dao/factory/LotteryCandidateFactory.sol`

DAOCommittee에서만 호출 가능(`onlyDAOCommittee`). 새로운 LotteryCandidateProxy를 배포하고 초기화한다. `defaultEntryFee`(기본 참가비)를 관리하며, 배포 시 이 값으로 초기화한다.

### 4.1.3 DAOCommittee_V1 (거버넌스 허브)

**파일:** `src/dao/DAOCommittee_V1.sol`

`createLotteryCandidate()` 함수를 통해 LotteryCandidateFactory 호출. 후보 등록, 위원회 멤버십 관리, 안건 투표, 활동 보상 관리를 총괄한다.

---

## 4.2 데이터 흐름

### 4.2.1 예치(Deposit) 흐름

```
사용자: depositTON(100 TON)
    │
    ├── 1. TON.transferFrom(user → LotteryCandidate, 100e18)
    ├── 2. WTON.swapFromTON(100e18)   // 100 TON → 100e27 WTON
    ├── 3. WTON.approve(DepositManager, 100e27)
    ├── 4. DepositManager.deposit(
    │         layer2 = address(this),     // LotteryCandidate = layer2
    │         account = address(this),    // LotteryCandidate = 예치자
    │         amount = 100e27
    │      )
    ├── 5. _balances[user] += 100e27     // 내부 잔액 갱신
    ├── 6. totalDeposited += 100e27
    └── 7. emit Deposited(user, 100e27)
```

**핵심 포인트:**
- 모든 자산은 LotteryCandidate 명의로 `DepositManager`에 통합 보관됨
- 개별 사용자 지분은 `_balances` 매핑으로만 추적
- TON → WTON 변환 비율: 1 TON = 1e9 WTON (decimals 차이: 18 → 27)

### 4.2.2 복권 참여 및 추첨 흐름

```
사용자: enterLottery()
    │
    ├── 1. require(_balances[user] >= entryFee)
    ├── 2. _balances[user] -= entryFee
    ├── 3. _roundPrizePool[currentRound] += entryFee
    ├── 4. _roundParticipants[round].push(user)
    ├── 5. _roundEntered[round][user] = true
    └── 6. emit LotteryEntered(round, user, entryFee)
```

```
오퍼레이터: drawWinner()
    │
    ├── 1. require(_roundParticipants[round].length > 0)
    ├── 2. randomIndex = uint256(keccak256(
    │         block.prevrandao, block.timestamp, round, participants.length
    │      )) % participants.length
    ├── 3. winner = _roundParticipants[round][randomIndex]
    ├── 4. _balances[winner] += _roundPrizePool[round]   // 상금 지급
    ├── 5. _roundWinner[round] = winner
    ├── 6. _roundDrawn[round] = true
    ├── 7. currentRound++                                 // 다음 라운드
    ├── 8. pendingEntryFee 적용 (있는 경우)
    └── 9. emit LotteryWinnerDrawn(round, winner, prize)
```

**핵심 포인트:**
- 참가비는 내부 잔액에서만 이동 (실제 토큰 전송 없음)
- Winner-Takes-All: 당첨자가 상금 풀 전액 수령
- 참가비 변경은 `setEntryFee()` → `pendingEntryFee`에 저장 → `drawWinner()` 시 다음 라운드에 적용
- 난수: `block.prevrandao` 기반 (메인넷에서 조작 가능 → [보안 고려사항](./08-security.md) 참조)

### 4.2.3 시뇨리지 분배 흐름

```
누구나: updateSeigniorage()
    │
    ├── 1. coinage = SeigManager.coinages(address(this))
    ├── 2. prevTotal = coinage.totalSupply()          // 이전 총 공급량 기록
    ├── 3. SeigManager.updateSeigniorage(address(this))  // 시뇨리지 리베이스
    ├── 4. afterTotal = coinage.totalSupply()          // 이후 총 공급량
    ├── 5. increase = afterTotal - prevTotal           // 증가분 = 시뇨리지
    │
    └── _distributeSeigniorage(increase):
        ├── for each depositor in _depositors:
        │   ├── share = increase * _balances[depositor] / totalDeposited
        │   └── _balances[depositor] += share
        ├── totalDeposited += increase
        └── emit SeigniorageDistributed(increase, depositorCount)
```

**핵심 포인트:**
- 시뇨리지 = Coinage `totalSupply` 증가분
- 복권 참가 후 잔액이 줄어든 상태에서 분배되면, 줄어든 비율로 수령
- Dust(나눗셈 나머지)는 마지막 예치자에게 할당
- First-Call Trap: V2 모드에서 첫 호출은 `startBlock`만 설정하고 보상 미분배 → [Known Issues](./09-known-issues.md) 참조

### 4.2.4 출금(Withdrawal) 흐름

```
사용자: requestWithdrawal(amount)
    │
    ├── 1. require(_balances[user] >= amount)
    ├── 2. _balances[user] -= amount
    ├── 3. totalDeposited -= amount
    ├── 4. DepositManager.requestWithdrawal(address(this), amount)
    ├── 5. withdrawalRequests.push({user, amount, block.number, false})
    └── 6. emit WithdrawalRequested(user, amount, index)

[대기 기간: GLOBAL_WITHDRAWAL_DELAY 블록 경과]
  - 테스트: 10 블록 (데모용)
  - 프로덕션: 93,046 블록 (~약 2주)

누구나: processWithdrawal(n)
    │
    ├── for i in 0..n:
    │   ├── req = withdrawalRequests[lastProcessedRequestIndex]
    │   ├── require(block.number >= req.requestBlock + delay)
    │   ├── DepositManager.processRequest(address(this), false)
    │   ├── WTON.transfer(req.user, req.amount)
    │   ├── req.processed = true
    │   └── lastProcessedRequestIndex++
    └── emit WithdrawalProcessed(...)
```

**핵심 포인트:**
- FIFO(선입선출) 방식으로 출금 요청 처리
- 출금 요청 시 즉시 내부 잔액 차감 (복권 참가 불가)
- 대기 기간 경과 후 누구나 `processWithdrawal` 호출 가능
- 실제 WTON은 `DepositManager` → `LotteryCandidate` → `user`로 이동

---

[다음: 데이터 구조 →](./05-data-structure.md)
