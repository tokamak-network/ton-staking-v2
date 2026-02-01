# Real Challenger E2E 테스트 구현 계획

> **개요**: 실제 op-challenger 서비스를 실행하여 Slashing 통합 테스트를 구현합니다. 현재 수동 호출 방식에서 자동 challenge 감지 방식으로 전환합니다.

## 진행 상태

| Phase | 내용 | 상태 |
|-------|------|------|
| Phase 1 | Optimism 시스템 통합 기반 구축 (`ton_system.go`) | ✅ Complete |
| Phase 2 | TON Challenger Helper 구현 (`ton_challenger.go`) | ✅ Complete |
| Phase 3 | Multi-Challenger Slashing 테스트 작성 | ✅ Complete |
| Phase 4 | Makefile 및 빌드 환경 설정 | ✅ Complete |
| Phase 5 | Contract Bindings 업데이트 (getWinningChallengers 등) | ✅ Complete |

---

## 현재 상태 분석

### 현재 op-e2e 구조
```
op-e2e/
├── e2eutils/rat/
│   ├── system.go      # Anvil 단일 노드만 실행
│   └── helpers.go     # 수동 AttackClaim(), ResolveGame()
├── slashing/          # 수동 호출 방식의 슬래싱 테스트
└── faultproofs/       # RAT 테스트
```

### Optimism e2e 구조 (목표)
```
lib/optimism/op-e2e/
├── system/e2esys/     # 전체 L1/L2/Rollup 시스템
├── e2eutils/challenger/ # 실제 challenger 서비스
└── slashing/          # 슬래싱 테스트 (faultproofs가 아닌 slashing 폴더에서 관리)
```

---

## 구현 방향

### Option A: Optimism 시스템 통합 (권장)
- Optimism의 `e2esys.System` 사용
- TON Staking V3 컨트랙트를 Optimism 시스템 위에 배포
- 실제 `op-challenger` 서비스 실행

### Option B: 현재 시스템 확장
- 현재 Anvil 기반 시스템 유지
- `op-challenger`를 별도 프로세스로 실행
- 설정 복잡도 증가

**권장: Option A** - Optimism 시스템을 활용하는 것이 더 현실적인 테스트 환경 제공

---

## 구현 단계

### Phase 1: Optimism 시스템 통합 기반 구축

**파일:** `op-e2e/system/ton_system.go` (신규)

주요 작업:
- Optimism `e2esys.System` 래핑
- TON Staking V3 컨트랙트 배포 로직 추가
- `StartTONFaultDisputeSystem()` 함수 구현

참고 코드:

```go
// lib/optimism/op-e2e/faultproofs/util.go:95-116
func StartFaultDisputeSystem(t *testing.T, opts ...faultDisputeConfigOpts) (*e2esys.System, *ethclient.Client) {
    cfg := e2esys.DefaultSystemConfig(t, fdc.sysOpts...)
    cfg.SupportL1TimeTravel = true
    cfg.DisableProposer = true
    sys, err := cfg.Start(t)
    return sys, sys.NodeClient("l1")
}
```

### Phase 2: Challenger Helper 구현

**파일:** `op-e2e/e2eutils/challenger/ton_challenger.go` (신규)

주요 작업:
- `NewTONChallenger()` - TON 시스템용 challenger 생성
- Slashing 컨트랙트와 연동 설정
- 다중 challenger 실행 지원

```go
func NewTONChallenger(t *testing.T, ctx context.Context, sys *TONSystem, name string, opts ...Option) *Helper {
    cfg := NewChallengerConfig(t, sys, "sequencer", opts...)
    cfg.GameFactoryAddress = sys.TONAddresses.DisputeGameFactory
    // ...
}
```

### Phase 3: Multi-Challenger Slashing 테스트

**파일:** `op-e2e/slashing/slashing_challenger_test.go` (신규)

테스트 시나리오:
1. `TestRealChallenger_SingleChallengerSlashing` - 단일 challenger 승리 → 슬래싱
2. `TestRealChallenger_MultiChallengerRewardDistribution` - 다중 challenger 균등 분배
3. `TestRealChallenger_GameFlowIntegration` - 전체 게임 흐름

```go
func TestRealChallenger_MultiChallengerRewardDistribution(t *testing.T) {
    ctx := context.Background()
    sys := StartTONFaultDisputeSystem(t)
    
    // 1. Operator 등록 및 스테이크
    registerOperator(t, sys)
    
    // 2. Invalid claim으로 DisputeGame 생성
    game := createDisputeGameWithInvalidClaim(t, sys)
    
    // 3. 다중 Challenger 서비스 실행
    challenger1 := NewTONChallenger(t, ctx, sys, "Challenger1", WithPrivKey(key1))
    challenger2 := NewTONChallenger(t, ctx, sys, "Challenger2", WithPrivKey(key2))
    
    // 4. Challenger가 자동으로 invalid claim 탐지 및 challenge
    game.WaitForCounterClaim(ctx)
    
    // 5. 게임 해결
    sys.AdvanceTime(game.MaxClockDuration(ctx))
    game.WaitForGameStatus(ctx, gameTypes.GameStatusChallengerWon)
    
    // 6. Slashing 실행
    executeSlashing(t, sys, game)
    
    // 7. 균등 분배 검증
    verifyEqualRewardDistribution(t, sys, challenger1, challenger2)
}
```

### Phase 4: 설정 및 빌드 환경

**파일:** `op-e2e/Makefile` 업데이트

```makefile
# Optimism binaries 빌드 (cannon, op-program 등)
.PHONY: build-challenger-deps
build-challenger-deps:
	cd ../lib/optimism && make cannon-prestate
	cd ../lib/optimism && make op-program

# Real challenger 테스트 실행
.PHONY: test-real-challenger
test-real-challenger: build-challenger-deps
	go test -v ./slashing/... -run TestRealChallenger
```

### Phase 5: Contract Bindings 업데이트

다중 challenger 기능을 위한 새 인터페이스 반영:
- `getWinningChallengers()` 
- `getWinningChallengersCount()`
- `isWinningChallenger(address)`

---

## 필요한 작업 상세

### 1. Go Module 의존성 추가

```go
// op-e2e/go.mod에 추가
require (
    github.com/ethereum-optimism/optimism/op-challenger v0.0.0
    github.com/ethereum-optimism/optimism/op-e2e v0.0.0
)

replace github.com/ethereum-optimism/optimism => ../lib/optimism
```

### 2. Contract Bindings 생성

다중 challenger 기능을 위한 새 인터페이스 반영:
- `getWinningChallengers()` 
- `getWinningChallengersCount()`
- `isWinningChallenger(address)`

### 3. 테스트 데이터/설정

- Multi-challenger 시나리오별 private keys
- Game 설정 (maxClockDuration, splitDepth 등)
- Slashing reward rate 설정

---

## 예상 파일 구조

```
op-e2e/
├── system/
│   └── ton_system.go              # 🆕 TON 시스템 래퍼
├── e2eutils/
│   ├── rat/                       # 기존 유지
│   └── challenger/
│       └── ton_challenger.go      # 🆕 TON challenger helper
├── slashing/
│   ├── slashing_test.go            # 기존 슬래싱 테스트
│   ├── slashing_helpers.go         # 기존 헬퍼
│   ├── slashing_challenger_test.go # 🆕 Real challenger 슬래싱 테스트
│   └── multi_challenger_test.go    # 🆕 다중 challenger 테스트
├── bindings/
│   ├── mock_fault_dispute_game3.go      # 🆕 MockFaultDisputeGame3 바인딩
│   └── mock_dispute_game_factory3.go    # 🆕 MockDisputeGameFactory3 바인딩
└── Makefile                        # 업데이트
```

---

## 주의사항

1. **Cannon/op-program 빌드 필요**: 실제 challenger는 Cannon VM이 필요
2. **시간 소요**: 전체 시스템 시작에 수십 초 소요
3. **리소스**: L1, L2, Rollup 노드 동시 실행으로 메모리 사용량 증가
4. **디버깅**: challenger 로그 레벨 설정 중요

---

## 대안: 단순화된 접근법

만약 전체 Optimism 시스템 통합이 너무 복잡하다면:

1. **Mock Challenger 서비스 구현**
   - 실제 op-challenger 코드를 참고하여 단순화된 버전 구현
   - Anvil 기반 현재 시스템에서 실행

2. **단계적 통합**
   - Phase 1: 현재 시스템에서 challenger 프로세스만 추가
   - Phase 2: 점진적으로 Optimism 시스템으로 마이그레이션

---

## 권장 진행 순서

토큰 제한으로 나누어서 진행할 경우:

1. **세션 1**: Phase 5 (Contract Bindings) - 독립적으로 먼저 진행 가능
2. **세션 2**: Phase 4 (Makefile) - 빌드 환경 설정
3. **세션 3**: Phase 1 (ton_system.go) - 시스템 기반 구축
4. **세션 4**: Phase 2 (ton_challenger.go) - Challenger Helper
5. **세션 5**: Phase 3 (테스트 작성) - 최종 테스트 구현

각 세션에서 이 문서를 참조하면서 진행하면 됩니다.
