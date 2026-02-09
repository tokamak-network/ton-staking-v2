# MockFaultDisputeGame3 → 실제 FaultDisputeGame 전환 완료 보고서

> **작성일**: 2026-02-09
> **관련 계획**: [task6-real-op-challenger-implementation.md](./task6-real-op-challenger-implementation.md)

## 개요

`op-e2e/slashing/` 폴더의 테스트를 **MockFaultDisputeGame3**에서 **실제 FaultDisputeGame.sol**로 전환 완료했습니다.

---

## Before/After 비교

| 구분 | Before (Mock) | After (실제) |
|------|--------------|-------------|
| **인프라** | Anvil (L1만) | Full Optimism devnet (L1+L2+op-node+batcher) |
| **컨트랙트** | MockFaultDisputeGame3 | FaultDisputeGame.sol |
| **게임 생성** | `deployMockDisputeGameFactory3()` | `disputegame.NewFactoryHelper()` |
| **Challenger** | 수동 `Attack()`, `Resolve()` | `game.StartChallenger()` (자동) |
| **Go Workspace** | 불필요 | 필요 (go.work 사용) |
| **테스트 시간** | ~15초 | ~90초 |

### Go Workspace 설명

실제 FaultDisputeGame 테스트는 `lib/optimism` 패키지를 사용하므로 Go workspace가 필요합니다.
`op-e2e/go.work` 파일이 자동으로 workspace를 설정합니다.

Mock 기반 테스트는 `GOWORK=off`로 실행하여 lib/optimism 의존성 없이 동작합니다.

---

## 변경된 파일

### 신규 생성

| 파일 | 설명 |
|------|------|
| `op-e2e/slashing/real_game_helpers.go` | Full Optimism devnet + TON 슬래싱 통합 헬퍼 |

### 전면 재작성

| 파일 | 설명 |
|------|------|
| `op-e2e/slashing/slashing_challenger_test.go` | 실제 FaultDisputeGame 사용 테스트 (5개) |
| `op-e2e/slashing/multi_challenger_test.go` | 실제 op-challenger 다중 실행 테스트 (6개) |

### 삭제됨

| 파일 | 이유 |
|------|------|
| `op-e2e/slashing/standalone_helpers.go` | Mock 기반 헬퍼 |
| `op-e2e/slashing/real_challenger_helpers.go` | Mock 참조 코드 |
| `op-e2e/slashing/real_challenger_integration_test.go` | Mock 참조 테스트 |
| `op-e2e/slashing/real_challenger_slashing_test.go` | Mock 참조 테스트 |
| `op-e2e/e2eutils/challenger/ton_challenger.go` | Mock 기반 Challenger 헬퍼 |
| `op-e2e/bindings/mock_fault_dispute_game3.go` | Mock 바인딩 |
| `op-e2e/bindings/mock_dispute_game_factory3.go` | Mock 바인딩 |

### 수정됨

| 파일 | 변경 내용 |
|------|----------|
| `op-e2e/system/ton_system.go` | Mock 참조 함수 제거 |
| `op-e2e/Makefile` | `DISABLE_OP_E2E_LEGACY=true` 추가, 타겟 정리 |

---

## 최종 파일 구조

```
op-e2e/
├── slashing/
│   ├── real_game_helpers.go              # Full Optimism + TON 헬퍼
│   ├── slashing_challenger_test.go       # 실제 FaultDisputeGame 테스트
│   ├── multi_challenger_test.go          # 실제 op-challenger 다중 테스트
│   ├── slashing_helpers.go               # TON 슬래싱 헬퍼 (유지)
│   ├── slashing_test.go                  # 기본 슬래싱 테스트 (유지)
│   ├── slashing_integration_test.go      # 슬래싱 연동 테스트 (유지)
│   ├── reward_distribution_test.go       # 보상 분배 테스트 (유지)
│   ├── edge_cases_test.go                # Edge Cases 테스트 (유지)
│   ├── delegator_protection_test.go      # Delegator 보호 테스트 (유지)
│   ├── complex_scenarios_test.go         # 복잡 시나리오 테스트 (유지)
│   └── permission_security_test.go       # 권한/보안 테스트 (유지)
├── system/
│   └── ton_system.go                     # Mock 참조 제거됨
├── bindings/
│   └── (mock_*.go 파일들 삭제됨)
└── Makefile                              # DISABLE_OP_E2E_LEGACY 추가
```

---

## 테스트 목록

### `slashing_challenger_test.go` (5개)

| 테스트 | 설명 |
|--------|------|
| `TestRealChallenger_SingleChallengerSlashing` | 단일 challenger 승리 |
| `TestRealChallenger_MultiChallengerGame` | 다중 challenger 게임 |
| `TestRealChallenger_GameFlowIntegration` | 전체 게임 흐름 |
| `TestRealChallenger_ChallengerWinsWithInvalidRoot` | Invalid root로 challenger 승리 |
| `TestRealChallenger_BondReclaim` | Bond 회수 테스트 |

### `multi_challenger_test.go` (6개)

| 테스트 | 설명 |
|--------|------|
| `TestMultiChallenger_TwoChallengersCompeting` | 2명 challenger 경쟁 |
| `TestMultiChallenger_ThreeChallengersRewardDistribution` | 3명 challenger 보상 분배 |
| `TestMultiChallenger_GameCreatorNotRewarded` | 게임 생성자 보상 제외 |
| `TestMultiChallenger_FreeloaderEarnsNothing` | Freeloader 보상 없음 |
| `TestMultiChallenger_HighestActedL1BlockMetric` | L1 블록 추적 메트릭 |
| `TestMultiChallenger_WinningChallengersTracking` | 승리 challenger 추적 |

---

## 테스트 실행 방법

### 사전 요구사항

```bash
# 프로젝트 루트에서 Genesis 파일 생성 (최초 1회)
cd /path/to/ton-staking-v2
make devnet-allocs-offline
```

### 테스트 실행

```bash
cd op-e2e

# Real FaultDisputeGame 테스트 (권장)
make test-real-challenger

# Multi-Challenger 테스트
make test-multi-challenger

# 전체 슬래싱 테스트 (Full Optimism devnet)
make test-slashing-devnet

# 또는 직접 실행 (Go workspace 자동 사용)
go test -v -timeout 30m -run "TestRealChallenger" ./slashing/...
```

### 테스트 특징

이 테스트 스위트는 **실제 FaultDisputeGame.sol**과 **실제 op-challenger 서비스**를 사용하여 가장 현실적인 환경에서 테스트합니다.

| 특징 | 설명 |
|------|------|
| **컨트랙트** | ✅ 실제 FaultDisputeGame.sol 사용 (Mock 아님) |
| **인프라** | Full Optimism devnet (L1+L2+op-node+batcher) - 완전한 롤업 환경 |
| **Challenger** | 실제 op-challenger 서비스 자동 실행 (`game.StartChallenger()`) |
| **게임 생성** | `disputegame.NewFactoryHelper()` - Optimism 시스템 통합 |
| **테스트 수** | 11개 (TestRealChallenger_* 5개 + TestMultiChallenger_* 6개) |
| **실행 시간** | ~90초 per test |
| **목적** | 실제 op-challenger 통합 검증, 실제 운영 환경과 유사한 테스트 |
| **Go Workspace** | 필요 (lib/optimism 패키지 사용) |

**사용 시나리오:**
- 실제 op-challenger 서비스 통합 검증이 필요할 때
- 실제 운영 환경과 유사한 조건에서 테스트하고 싶을 때
- Full Optimism devnet 환경에서 end-to-end 테스트가 필요할 때

**다른 테스트와의 차이:**

| 구분 | `test-slashing-all` | `test-real-challenger` (이 문서) |
|------|---------------------|----------------------------------|
| **컨트랙트** | 실제 FaultDisputeGame.sol | 실제 FaultDisputeGame.sol |
| **인프라** | Anvil (L1만) | Full Optimism devnet (L1+L2+op-node+batcher) |
| **Challenger** | 수동 호출 (`rat.AttackClaim`) | 실제 op-challenger 서비스 |
| **게임 생성** | `rat.CreateDisputeGame()` | `disputegame.NewFactoryHelper()` |
| **테스트 수** | 41개 (모든 카테고리) | 11개 (op-challenger 통합만) |
| **실행 시간** | ~2분 (전체) | ~90초 per test |
| **목적** | 빠른 슬래싱 로직 검증 | 실제 op-challenger 통합 검증 |
| **권장 사용** | CI/CD, 빠른 피드백 | 실제 운영 환경 검증 |

**언제 사용하나요?**
- `test-slashing-all`: 슬래싱 로직의 빠른 검증, 다양한 엣지 케이스 테스트
- `test-real-challenger`: 실제 op-challenger 서비스와의 통합 검증, 실제 운영 환경 시뮬레이션

### 테스트 목록 확인

```bash
go test -list "TestRealChallenger|TestMultiChallenger" ./slashing/...
```

예상 출력:
```
TestMultiChallenger_TwoChallengersCompeting
TestMultiChallenger_ThreeChallengersRewardDistribution
TestMultiChallenger_GameCreatorNotRewarded
TestMultiChallenger_FreeloaderEarnsNothing
TestMultiChallenger_HighestActedL1BlockMetric
TestMultiChallenger_WinningChallengersTracking
TestRealChallenger_SingleChallengerSlashing
TestRealChallenger_MultiChallengerGame
TestRealChallenger_GameFlowIntegration
TestRealChallenger_ChallengerWinsWithInvalidRoot
TestRealChallenger_BondReclaim
```

---

## 코드 예시

### Before (Mock 기반)

```go
func TestRealChallenger_SingleChallengerSlashing(t *testing.T) {
    ratSys := rat.StartTONStakingSystem(t)
    tonSys := system.StartTONFaultDisputeSystem(t, ratSys.L1Client)
    factoryAddr := deployMockDisputeGameFactory3(t, ratSys)
    chl := challenger.NewTONChallenger(t, ctx, tonSys)
    gameAddr := createAndInitializeGame(t, ratSys, factoryAddr, rootClaim, extraData)
    err := chl.Attack(gameAddr, big.NewInt(0), counterClaim)
    status, err := chl.Resolve(gameAddr)
}
```

### After (실제 FaultDisputeGame)

```go
func TestRealChallenger_SingleChallengerSlashing(t *testing.T) {
    op_e2e.InitParallel(t)
    ctx := context.Background()

    // Full Optimism devnet 시작
    sys, l1Client := faultproofs.StartFaultDisputeSystem(t)
    t.Cleanup(sys.Close)

    // 실제 FaultDisputeGame 생성 (Alphabet trace)
    disputeGameFactory := disputegame.NewFactoryHelper(t, ctx, sys)
    game := disputeGameFactory.StartOutputAlphabetGame(ctx, "sequencer", 3, common.Hash{0xff})

    // op-challenger 서비스 시작 (자동으로 게임 참여)
    game.StartChallenger(ctx, "sequencer", "Challenger",
        challenger.WithPrivKey(sys.Cfg.Secrets.Alice))

    // 게임 진행 및 해결
    claim := game.RootClaim(ctx)
    // ... (게임 로직)

    // 시간 이동 및 게임 해결 대기
    sys.TimeTravelClock.AdvanceTime(game.MaxClockDuration(ctx))
    game.WaitForGameStatus(ctx, types.GameStatusChallengerWon)
}
```

---

## 주의사항

1. **테스트 시간 증가**: Mock 대비 약 6배 증가 (~15초 → ~90초)
2. **메모리 사용량**: Full devnet은 더 많은 리소스 필요 (4GB 이상 권장)
3. **Go Workspace 필수**: `op-e2e/go.work` 파일이 있어야 lib/optimism 패키지 사용 가능
4. **Kona prestate 경고**: Kona prestate 파일이 없으면 경고가 출력되지만 Alphabet 테스트는 정상 동작

---

## 관련 문서

- [real-challenger-e2e-plan.md](./real-challenger-e2e-plan.md) - Mock 기반 원래 계획 (역사 기록)
- [real-challenger-implementation-report.md](./real-challenger-implementation-report.md) - Mock 기반 구현 보고서 (역사 기록)
- [task6-real-op-challenger-implementation.md](./task6-real-op-challenger-implementation.md) - 전환 계획

---

## 참조 코드 (lib/optimism)

| 파일 | 용도 |
|------|------|
| `lib/optimism/op-e2e/faultproofs/util.go` | `StartFaultDisputeSystem()` |
| `lib/optimism/op-e2e/e2eutils/disputegame/helper.go` | `FactoryHelper`, `OutputAlphabetGameHelper` |
| `lib/optimism/op-e2e/e2eutils/challenger/helper.go` | op-challenger 서비스 헬퍼 |
| `lib/optimism/op-e2e/faultproofs/output_alphabet_test.go` | 참고 테스트 예시 |
