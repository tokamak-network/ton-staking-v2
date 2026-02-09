# DisputeGame Depth & Bond 비용 분석

> **작성일**: 2026-02-09
> **테스트 환경**: lib/optimism faultproofs E2E 테스트
> **관련 문서**: [task6-real-op-challenger-implementation.md](./task6-real-op-challenger-implementation.md)

---

## 개요

FaultDisputeGame의 Depth 구조와 각 Depth별 Bond 비용을 분석합니다. 이 정보는 Challenger 운영 비용 산정 및 슬래싱 보상 계산에 중요합니다.

---

## Game Configuration

| 파라미터 | 값 | 설명 |
|----------|-----|------|
| **Split Depth** | 14 | Output Bisection 영역 (L2 블록 검증) |
| **Max Depth** | 18 | Execution Trace 영역 포함 (VM 실행 검증) |
| **Max Clock Duration** | 3.5일 | 게임 최대 지속 시간 |
| **Credit Unlock Duration** | 7일 | Bond 회수 대기 시간 |

### Depth 영역 구분

```
Depth 0-14: Output Bisection Game
├── L2 블록의 Output Root 검증
├── 이진 탐색으로 문제 블록 특정
└── Split Depth (14)에서 Execution Trace로 전환

Depth 15-18: Execution Trace Game
├── 특정 블록의 VM 실행 검증
├── MIPS/RISC-V 명령어 단위 검증
└── Max Depth (18)에서 최종 step() 호출
```

---

## Depth별 Bond 비용

### Bond 스케일링

Bond는 **약 1.44배 (Fibonacci 스케일)** 씩 증가합니다.

| Depth | Bond (wei) | Bond (ETH) | 증가율 | 영역 |
|-------|------------|------------|--------|------|
| 0 | 0 | 0.0000 | - | Root Claim |
| 1 | 115,562,000,000,000,000 | 0.1156 | - | Output |
| 2 | 166,932,600,000,000,000 | 0.1669 | 1.44x | Output |
| 3 | 241,138,600,000,000,000 | 0.2411 | 1.44x | Output |
| 4 | 348,331,200,000,000,000 | 0.3483 | 1.44x | Output |
| 5 | 503,173,800,000,000,000 | 0.5032 | 1.44x | Output |
| 6 | 726,848,200,000,000,000 | 0.7268 | 1.44x | Output |
| 7 | 1,049,951,800,000,000,000 | 1.0500 | 1.44x | Output |
| 8 | 1,516,683,600,000,000,000 | 1.5167 | 1.44x | Output |
| 9 | 2,190,890,200,000,000,000 | 2.1909 | 1.44x | Output |
| 10 | 3,164,799,800,000,000,000 | 3.1648 | 1.44x | Output |
| 11 | 4,571,638,200,000,000,000 | 4.5716 | 1.44x | Output |
| 12 | 6,603,854,400,000,000,000 | 6.6039 | 1.44x | Output |
| 13 | 9,539,445,200,000,000,000 | 9.5394 | 1.44x | Output |
| **14** | **13,779,985,000,000,000,000** | **13.7800** | 1.44x | **Split Depth** |
| 15 | 19,905,558,600,000,000,000 | 19.9056 | 1.44x | Execution |
| 16 | 28,754,114,400,000,000,000 | 28.7541 | 1.44x | Execution |
| 17 | 41,536,091,200,000,000,000 | 41.5361 | 1.44x | Execution |
| **18** | **59,999,999,800,000,000,000** | **~60.0000** | 1.44x | **Max Depth** |

### 시각화

```
Bond (ETH)
60 ┤                                                    ████ Max Bond
   │                                               ████
   │                                          ████
40 ┤                                     ████
   │                                ████
   │                           ████
20 ┤                      ████
   │                 ████  ← Split Depth (14)
   │            ████
10 ┤       ████
   │   ████
   │████
 0 ┼────────────────────────────────────────────────────────
   0  2  4  6  8  10  12  14  16  18  Depth
```

---

## 비용 시나리오 분석

### 시나리오 1: 빠른 해결 (Split Depth 이전)

Challenger가 Output Bisection 단계에서 승리하는 경우:

| 항목 | 비용 |
|------|------|
| 평균 Depth | ~7 |
| 필요 Bond | ~1-2 ETH |
| 상대방 Bond 획득 | ~1-2 ETH |
| Gas 비용 | ~0.1 ETH |
| **순이익** | **~1-2 ETH** |

### 시나리오 2: Split Depth 도달

Output Bisection이 완료되고 Execution Trace로 진입:

| 항목 | 비용 |
|------|------|
| 도달 Depth | 14 (Split Depth) |
| 누적 Bond | ~13.78 ETH |
| 상대방 누적 Bond | ~13.78 ETH |
| Gas 비용 | ~0.5 ETH |
| **순이익 (승리 시)** | **~13 ETH** |

### 시나리오 3: Max Depth 도달 (Exhaustive)

전체 게임이 Max Depth까지 진행:

| 항목 | 비용 |
|------|------|
| 도달 Depth | 18 (Max Depth) |
| Max Bond | 60 ETH |
| Total Claims | ~48개 |
| Gas 비용 | ~2-5 ETH |
| **최대 Bond 노출** | **~60 ETH** |

---

## 테스트 실행 방법

### 1. 사전 준비

```bash
# Genesis 파일 생성
cd /path/to/ton-staking-v2
make devnet-allocs-offline

# Kona prestate 생성
mkdir -p lib/optimism/kona/bin
echo '{"pre": "0x0", "post": "0x0"}' > lib/optimism/kona/bin/prestate.json
```

### 2. Depth/Bond 분석 테스트

```bash
cd /path/to/ton-staking-v2/lib/optimism

# Exhaustive 테스트 (Max Depth까지 모든 Claim 생성)
go test -v -timeout 30m -run "TestChallengerCompleteExhaustiveDisputeGame" ./op-e2e/faultproofs/...

# 기본 Challenger 승리 테스트
go test -v -timeout 15m -run "TestOutputAlphabetGame_ChallengerWins" ./op-e2e/faultproofs/...

# Bond 회수 테스트
go test -v -timeout 15m -run "TestOutputAlphabetGame_ReclaimBond" ./op-e2e/faultproofs/...
```

### 3. 전체 테스트 목록

| 테스트 | 설명 | 예상 시간 |
|--------|------|-----------|
| `TestOutputAlphabetGame_ChallengerWins` | Challenger 승리 기본 플로우 | ~95초 |
| `TestOutputAlphabetGame_ReclaimBond` | Bond 회수 검증 | ~41초 |
| `TestOutputAlphabetGame_ValidOutputRoot` | Defender 승리 (올바른 Root) | ~89초 |
| `TestOutputAlphabetGame_FreeloaderEarnsNothing` | Freeloader 보상 없음 검증 | ~105초 |
| `TestChallengerCompleteExhaustiveDisputeGame` | Max Depth까지 전체 테스트 | ~180초 |
| `TestHighestActedL1BlockMetric` | L1 Block Metric 테스트 | ~60초 |

---

## 테스트 결과 (2026-02-07)

### Exhaustive Dispute Game 테스트

```
=== RUN   TestChallengerCompleteExhaustiveDisputeGame
=== RUN   TestChallengerCompleteExhaustiveDisputeGame/RootCorrect
=== RUN   TestChallengerCompleteExhaustiveDisputeGame/RootIncorrect

Game Configuration:
- Split Depth: 14
- Max Depth: 18
- Claim count: 48

--- PASS: TestChallengerCompleteExhaustiveDisputeGame/RootCorrect (173.62s)
--- PASS: TestChallengerCompleteExhaustiveDisputeGame/RootIncorrect (181.67s)
PASS
ok      github.com/ethereum-optimism/optimism/op-e2e/faultproofs    194.074s
```

### Claim 상세 로그 (발췌)

```
Claim #0  - Depth: 0,  Bond: 0 ETH (Root Claim)
Claim #1  - Depth: 1,  Bond: 0.1156 ETH
Claim #2  - Depth: 2,  Bond: 0.1669 ETH
...
Claim #14 - Depth: 14, Bond: 13.7800 ETH (Split Depth)
Claim #15 - Depth: 15, Bond: 19.9056 ETH
...
Claim #20 - Depth: 18, Bond: 60.0000 ETH (Max Depth)
```

---

## 핵심 인사이트

### 1. Bond 스케일링 목적

- **Sybil 공격 방지**: Depth가 깊어질수록 비용 증가
- **조기 해결 유도**: 높은 Bond로 인해 빠른 타협 촉진
- **정직한 참여자 보호**: 승리 시 상대방 Bond 획득

### 2. Challenger 운영 고려사항

| 항목 | 권장 사항 |
|------|-----------|
| 최소 자본 | ~15 ETH (Split Depth 대응) |
| 권장 자본 | ~65 ETH (Max Depth 대응) |
| Gas 예비금 | ~5 ETH |
| 동시 게임 수 | 자본에 따라 제한 필요 |

### 3. TON Slashing 연동 시 고려사항

- Challenger가 승리하면 상대방 Bond + 자신의 Bond 회수
- 슬래싱 보상은 Bond와 별도로 TON 시스템에서 지급
- `isWinningChallenger()` 호출로 보상 수령 자격 확인

---

## 관련 컨트랙트

| 컨트랙트 | 역할 |
|----------|------|
| `FaultDisputeGame.sol` | 게임 로직, Bond 관리 |
| `DisputeGameFactory.sol` | 게임 생성 |
| `DelayedWETH.sol` | Bond 에스크로 |
| `AnchorStateRegistry.sol` | 검증된 상태 저장 |

---

## 참고 자료

- [Optimism Fault Proof Specs](https://specs.optimism.io/fault-proof/)
- [Bond Incentives Design](https://specs.optimism.io/fault-proof/bond-incentives.html)
- [lib/optimism/op-e2e/faultproofs/](../../lib/optimism/op-e2e/faultproofs/)
