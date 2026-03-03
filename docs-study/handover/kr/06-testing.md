# 6. 테스트 가이드

## 테스트 요약

| 카테고리 | 프레임워크 | 테스트 수 | 실행 시간 | 환경 |
|----------|-----------|----------|-----------|------|
| Foundry AdvancedSlashing | Solidity (forge) | 24개 | 수 초 | 로컬 |
| Foundry BasicSlashing | Solidity (forge) | 38개 | 수 초 | 로컬 |
| E2E 슬래싱 (Mock) | Go test | 41개 | ~2분 | Anvil (L1만) |
| E2E Real Challenger | Go test | 11개 | ~90초/개 | Full Optimism devnet |

---

## 1. Foundry 단위 테스트 (Solidity)

### 실행 방법

```bash
# 프로젝트 루트에서

# AdvancedSlashing 테스트 (24개)
forge test --match-path "test/v3/v3mode/AdvancedSlashing/*.t.sol" -v

# BasicSlashing 테스트 (38개)
forge test --match-path "test/v3/v3mode/BasicSlashing/*.t.sol" -v

# 특정 테스트 파일
forge test --match-contract SingleChallengerTest -vvv

# 특정 테스트 함수
forge test --match-test test_TwoChallengers_50_50_Split -vvv
```

### AdvancedSlashing 테스트 구조

```
test/v3/v3mode/AdvancedSlashing/
├── BaseAdvancedSlashingTest.sol              # 베이스 테스트 (공통 헬퍼)
├── SingleChallengerTest.t.sol                # 단일 챌린저 (4개)
├── MultiChallengerEqualDistributionTest.t.sol # 균등 분배 (5개)
├── WinnerTrackingTest.t.sol                  # 승자 추적 (5개)
├── RemainderDistributionTest.t.sol           # 나머지 분배 (5개)
└── RealisticGameFlowTest.t.sol               # 실제 게임 흐름 (5개)
```

### 주요 테스트 케이스

| 파일 | 테스트 | 검증 내용 |
|------|--------|-----------|
| SingleChallenger | `test_SingleChallenger_ReceivesFullReward` | 단일 챌린저 100% 수령 |
| MultiChallenger | `test_TwoChallengers_50_50_Split` | 2명 50:50 분배 |
| MultiChallenger | `test_ThreeChallengers_EqualSplit` | 3명 균등 분배 + 나머지 |
| WinnerTracking | `test_WinnerTracking_GameCreatorExcluded` | Proposer 승자 목록 제외 |
| WinnerTracking | `test_WinnerTracking_NoDuplicates` | 중복 등록 방지 |
| Remainder | `test_Remainder_ExactDivision` | 나머지 0인 경우 |
| RealisticGame | `test_MultipleBranches_TwoWinningChallengers` | 독립 공격 2명 승자 |
| RealisticGame | `test_GameWithStep_ProveWrongClaim` | step 증명 Defender 승리 |

### BasicSlashing 테스트 (38개)

| 파일 | 테스트 수 |
|------|----------|
| SlashingBasicTest.t.sol | 3 |
| SlashingSecurityTest.t.sol | 4 |
| SlashingDelegatorTest.t.sol | 4 |
| SlashingEdgeCaseTest.t.sol | 5 |
| SlashingAttackVectorTest.t.sol | 11 |
| SlashingRewardRateTest.t.sol | 4 |
| SlashingSeigniorageTest.t.sol | 3 |
| SlashingMultiOperatorTest.t.sol | 4 |

---

## 2. E2E 슬래싱 테스트 (Go, Anvil 기반, 41개)

### 사전 준비

```bash
cd /path/to/ton-staking-v2
make devnet-allocs-offline   # Genesis 파일 생성 (최초 1회)
```

### 실행 방법

```bash
cd op-e2e

# 전체 실행 (권장)
make test-slashing-all

# 카테고리별 실행
make test-slashing-integration   # 슬래싱 연동 (4개)
make test-reward-distribution    # 보상 분배 (6개)
make test-edge-cases             # Edge Cases (6개)
make test-delegator-protection   # Delegator 보호 (4개)
make test-complex-scenarios      # 복합 시나리오 (5개)
make test-permission-security    # 권한/보안 (7개)
make test-real-challenger        # Real Challenger (3개)
make test-multi-challenger       # Multi-Challenger (6개)
```

### 테스트 파일 구조

```
op-e2e/slashing/
├── slashing_helpers.go              # 공통 헬퍼
├── real_game_helpers.go             # Full Optimism + TON 헬퍼
├── slashing_test.go                 # 기본 슬래싱 (3개)
├── slashing_challenger_test.go      # Real Challenger (5개)
├── multi_challenger_test.go         # Multi-Challenger (6개)
├── slashing_integration_test.go     # 슬래싱 연동 (4개)
├── reward_distribution_test.go      # 보상 분배 (6개)
├── edge_cases_test.go               # Edge Cases (6개)
├── delegator_protection_test.go     # Delegator 보호 (4개)
├── complex_scenarios_test.go        # 복합 시나리오 (5개)
└── permission_security_test.go      # 권한/보안 (7개)
```

### 주요 테스트 (카테고리별)

**슬래싱 연동**:
- `TestSlashingIntegration_MultiChallengerWithRealSlashing` - 다중 챌린저 전체 연동
- `TestSlashingIntegration_CannotSlashTwice` - 중복 슬래싱 방지

**보상 분배**:
- `TestRewardDistribution_ThreeChallengersEqualSplit` - 3명 균등 분배 + 나머지
- `TestRewardDistribution_RemainderHandling` - 나머지 첫 번째 지급

**Edge Cases**:
- `TestEdgeCase_DefenderWinsCannotSlash` - DEFENDER_WINS면 슬래싱 불가
- `TestEdgeCase_InvalidGameAddress` - 존재하지 않는 게임 주소

**Delegator 보호**:
- `TestDelegatorProtection_StakeNotSlashed` - Operator 슬래싱 시 Delegator 보호

**권한/보안**:
- `TestSecurity_DoubleSlashingSameGame` - 동일 게임 중복 슬래싱 방지
- `TestSecurity_GameAddressManipulation` - rootClaim/gameAddress 불일치 조작 방지

---

## 3. 실제 op-challenger 통합 테스트 (Go, Full Devnet, 11개)

### 사전 준비

```bash
cd /path/to/ton-staking-v2
make devnet-allocs-offline

# Kona prestate (Alphabet 테스트는 dummy 파일로 동작)
mkdir -p lib/optimism/kona/bin
echo '{"pre": "0x0", "post": "0x0"}' > lib/optimism/kona/bin/prestate.json

# Docker Desktop 실행 필요
docker ps
```

### 실행 방법

```bash
cd lib/optimism

# Alphabet 테스트 전체
go test -v -timeout 15m -run "TestOutputAlphabetGame_" ./op-e2e/faultproofs/...

# 특정 테스트
go test -v -timeout 10m -run "TestOutputAlphabetGame_ChallengerWins" ./op-e2e/faultproofs/...

# Exhaustive 테스트 (Max Depth까지)
go test -v -timeout 30m -run "TestChallengerCompleteExhaustiveDisputeGame" ./op-e2e/faultproofs/...
```

### 테스트 목록

| 테스트 | 설명 | 시간 |
|--------|------|------|
| `TestOutputAlphabetGame_ChallengerWins` | Challenger 승리 | ~95초 |
| `TestOutputAlphabetGame_ReclaimBond` | Bond 회수 | ~41초 |
| `TestOutputAlphabetGame_ValidOutputRoot` | Defender 승리 | ~89초 |
| `TestOutputAlphabetGame_FreeloaderEarnsNothing` | Freeloader 보상 없음 | ~105초 |
| `TestChallengerCompleteExhaustiveDisputeGame` | Max Depth 전체 | ~180초 |

### Mock vs Real 비교

| 구분 | test-slashing-all (Mock) | test-real-challenger (Real) |
|------|--------------------------|----------------------------|
| 컨트랙트 | 실제 FaultDisputeGame.sol | 실제 FaultDisputeGame.sol |
| 인프라 | Anvil (L1만) | Full Optimism devnet |
| Challenger | 수동 호출 | 실제 op-challenger 서비스 |
| 테스트 수 | 41개 | 11개 |
| 실행 시간 | ~2분 전체 | ~90초/개 |
| 용도 | CI/CD, 빠른 피드백 | 운영 환경 검증 |

---

## Go Workspace 관련

- E2E 테스트에서 `lib/optimism` 패키지를 사용하는 테스트는 `op-e2e/go.work` 필요
- Mock 기반 테스트는 `GOWORK=off`로 실행
- `DISABLE_OP_E2E_LEGACY=true` 환경변수로 prestate 빌드 건너뛰기

---

다음: [07-issues.md](./07-issues.md)
