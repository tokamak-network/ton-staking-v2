# 2. 시스템 아키텍처

## 전체 흐름

```
1) 게임 생성
   DisputeGameFactory.create()
   └─> FaultDisputeGame.initialize(rat, winningChallengerTracker)

2) Challenge 수행
   Challenger들이 move/attack/defend/step 수행

3) 게임 해결 및 승자 기록
   FaultDisputeGame.resolveClaim()
   ├─> _distributeBond(recipient, claim)           ← bond 분배
   └─> _recordWinningChallenger(recipient)          ← 승자 기록
        └─> WinningChallengerTracker.recordWinner(game, winner, gameCreator)

4) 슬래싱 실행 및 보상 분배
   Layer2Manager_Slashing.slashingCandidate()
   ├─> Verify game status (CHALLENGER_WINS)
   ├─> _getWinningChallengers(disputeGame)
   │    └─> WinningChallengerTracker.getWinningChallengers(game)
   └─> DepositManager_Slashing.slash(layer2, operator, challengers[])
        ├─> SeigManager.onSlash() → totalSlashed
        ├─> rewardAmount = totalSlashed * slashingRewardRate / 10000
        └─> _distributeRewards() → 각 challenger에게 WTON 균등 분배
```

---

## 전체 구조도

```
┌───────────────────────────────────────────────────────────┐
│                         L1 (Ethereum)                      │
│                                                            │
│  ┌──────────────────────────────────────────────────────┐ │
│  │              Optimism Dispute System                   │ │
│  │                                                        │ │
│  │  DisputeGameFactory ──> FaultDisputeGame               │ │
│  │  - create()              - resolveClaim()              │ │
│  │  - setWCT()              - _distributeBond()           │ │
│  │       │                  - _recordWinningChallenger()  │ │
│  │       │                         │                      │ │
│  │       │     WinningChallengerTracker  <────────────┘   │ │
│  │       │     - recordWinner()                           │ │
│  │       │     - getWinningChallengers()                  │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                            │
│  ┌──────────────────────────────────────────────────────┐ │
│  │              TON Staking V3 System                     │ │
│  │                                                        │ │
│  │  Layer2Manager_Slashing ──> DepositManager_Slashing    │ │
│  │  - slashingCandidate()      - slash()                  │ │
│  │  - _getWinningChallengers() - _distributeRewards()     │ │
│  │       │                          │                     │ │
│  │       │ query                    │ transfer WTON       │ │
│  │       ▼                          ▼                     │ │
│  │  WinningChallenger           Challengers               │ │
│  │  Tracker                     (address[])               │ │
│  └──────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────┘
```

---

## 레이어 구조

```
┌─────────────────────────────────────────────────────┐
│ Layer 4: Application Layer                          │
│ - E2E Tests, Integration Tests, Monitoring          │
└─────────────────────────────────────────────────────┘
                        ▲
┌─────────────────────────────────────────────────────┐
│ Layer 3: Business Logic Layer                       │
│ - Layer2Manager_Slashing                            │
│ - DepositManager_Slashing                           │
│ - SeigManager_Slashing                              │
└─────────────────────────────────────────────────────┘
                        ▲
┌─────────────────────────────────────────────────────┐
│ Layer 2: Tracking Layer                             │
│ - WinningChallengerTracker                          │
│ - FaultDisputeGame (tracking logic)                 │
└─────────────────────────────────────────────────────┘
                        ▲
┌─────────────────────────────────────────────────────┐
│ Layer 1: Dispute Resolution Layer                   │
│ - DisputeGameFactory                                │
│ - FaultDisputeGame (core logic)                     │
│ - AnchorStateRegistry                               │
└─────────────────────────────────────────────────────┘
```

---

## Depth & Bond 비용 참고

DisputeGame의 Depth별 Bond 비용 (약 1.44배씩 증가):

| Depth | Bond (ETH) | 영역 |
|-------|------------|------|
| 0 | 0 | Root Claim |
| 1 | 0.1156 | Output Bisection |
| 7 | 1.05 | Output Bisection |
| 14 (Split Depth) | 13.78 | Split Point → Execution Trace 전환 |
| 18 (Max Depth) | ~60.0 | Execution Trace (최대) |

**Challenger 운영 권장 자본**: 최소 15 ETH (Split Depth 대응), 권장 65 ETH (Max Depth 대응)

---

다음: [03-contracts.md](./03-contracts.md)
