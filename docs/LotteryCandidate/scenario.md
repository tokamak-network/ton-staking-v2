# 사용 시나리오

## 기본 흐름

1. **운영자 설정**: `createLotteryCandidate`로 후보 생성 및 `setEntryFee`로 라운드 참여 비용 설정.
2. **자금 예치**: 사용자가 `depositTON` 또는 `depositWTON`을 호출. 내부 잔액(`_balances`)에 기록되고 실제 자금은 `DepositManager`에 예치됨.
3. **로터리 참여**: 사용자가 `enterLottery()`를 호출. 예치 잔액에서 참여 비용이 즉시 차감되고 Prize Pool로 이동.
4. **추첨 및 지급**: 운영자가 `drawWinner()` 호출. 참여자 중 1명을 무작위로 뽑아 Prize Pool 전액을 당첨자의 내부 잔액에 가산.
5. **시뇨리지 분배**: 운영자가 `receiveSeigniorage()`를 통해 시뇨리지 입금. 모든 예치자에게 현재 잔액 비율대로 분배되어 내부 잔액에 가산.

## 출금 (언스테이킹)

출금은 `LotteryCandidate`를 통해 신청하고 처리합니다.

1. **출금 신청**: 사용자가 `requestWithdrawal(amount)` 호출. 내부 잔액에서 차감되고 `DepositManager`에 출금 요청 전달.
2. **출금 처리**: 출금 지연 시간 경과 후 `processWithdrawal()`을 호출하여 실제 TON/WTON 수령.


## 시뇨리지 분배 메커니즘 (올바른 방식)
┌─────────────────────────────────────────────────────────────┐
│                    updateSeigniorage() 호출                   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  1. coinage.balanceOf(this) 기록 (before)                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  2. SeigManager.updateSeigniorage() 호출                     │
│     → SeigManager가 coinage factor 증가                      │
│     → 모든 holder의 balanceOf() 자동 증가 (rebase)           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  3. coinage.balanceOf(this) 기록 (after)                     │
│     seigniorage = after - before                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  4. _distributeSeigniorage(seigniorage)                      │
│     → 내부 _balances에 비례 배분                              │
│     → totalDeposited += seigniorage                          │
└─────────────────────────────────────────────────────────────┘


### Test Command

forge test --match-contract LotteryCandidateScenarioTest