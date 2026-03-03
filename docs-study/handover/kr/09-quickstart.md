# 9. 빠른 시작 가이드 (새로운 담당자용)

## Step 1: 환경 확인

```bash
cd /path/to/ton-staking-v2

# Foundry 설치 확인
forge --version    # 필요: Foundry

# Go 설치 확인
go version         # 필요: Go 1.23+

# Docker 확인 (Full Optimism 테스트 시)
docker --version

# submodule 초기화
git submodule update --init --recursive
```

---

## Step 2: 컨트랙트 빌드

```bash
# TON Staking V2 빌드
forge build

# Optimism 컨트랙트 빌드
cd lib/optimism/packages/contracts-bedrock
forge build --skip test
```

---

## Step 3: Foundry 단위 테스트 실행

```bash
# 프로젝트 루트에서

# AdvancedSlashing 테스트 (24개) - 다중 Challenger 보상 분배
forge test --match-path "test/v3/v3mode/AdvancedSlashing/*.t.sol" -v

# BasicSlashing 테스트 (38개) - 기본 슬래싱 로직
forge test --match-path "test/v3/v3mode/BasicSlashing/*.t.sol" -v
```

---

## Step 4: E2E 테스트 실행

```bash
# Genesis 생성 (최초 1회)
make devnet-allocs-offline

# 슬래싱 E2E 테스트 (41개, ~2분)
cd op-e2e && make test-slashing-all
```

---

## Step 5: 코드 이해 순서 (권장)

처음 코드를 파악할 때 아래 순서를 권장합니다:

### 1단계: 전체 그림 파악

`docs-study/AdvancedSlash/advanced-slash-architecture.md` 읽기
- 시스템 아키텍처 구조도
- 데이터 흐름 (게임 생성 → Challenge → 슬래싱 → 보상 분배)

### 2단계: 승자 판정 로직 이해

`docs-study/AdvancedSlash/distributeBond-winner-analysis.md` 읽기
- `_distributeBond` 수령자가 왜 승자인지
- gameCreator 필터링 이유
- 3가지 케이스 분석

### 3단계: 핵심 신규 컨트랙트

`lib/optimism/packages/contracts-bedrock/src/dispute/WinningChallengerTracker.sol` 읽기
- `recordWinner()`: 승자 기록 로직
- Access Control: `msg.sender == game`
- 중복 방지 메커니즘

### 4단계: FaultDisputeGame 수정 부분

`lib/optimism/packages/contracts-bedrock/src/dispute/FaultDisputeGame.sol` 에서 `_recordWinningChallenger` 검색
- `resolveClaim()` 내 3곳에서 호출되는 위치 확인
- `initialize(address, address)` 오버로드 확인

### 5단계: TON 슬래싱 로직

`src/layer2/Layer2Manager_Slashing.sol` 의 `slashingCandidate()` 함수
- 게임 상태 검증 (CHALLENGER_WINS)
- `_getWinningChallengers()` → 승자 배열 조회
- `DepositManager.slash()` 호출

### 6단계: 보상 분배

`src/stake/managers/DepositManager_Slashing.sol` 의 `slash()`, `_distributeRewards()` 함수
- 균등 분배 로직
- 나머지(remainder) 처리
- WTON safeTransfer

---

## 자주 쓰는 명령어

```bash
# Foundry 테스트 (특정)
forge test --match-test test_TwoChallengers_50_50_Split -vvv

# E2E 전체
cd op-e2e && make test-slashing-all

# E2E 카테고리별
cd op-e2e && make test-reward-distribution

# Optimism faultproofs 테스트 (Full devnet)
cd lib/optimism && go test -v -timeout 15m -run "TestOutputAlphabetGame_" ./op-e2e/faultproofs/...

# Genesis 재생성
make devnet-allocs-offline

# Solidity 빌드
forge build
cd lib/optimism/packages/contracts-bedrock && forge build --skip test
```

---

## 도움이 되는 문서

| 우선순위 | 문서 | 이유 |
|----------|------|------|
| 높음 | `docs-study/AdvancedSlash/advanced-slash-architecture.md` | 전체 아키텍처 |
| 높음 | `docs-study/AdvancedSlash/implementation-summary.md` | 변경 파일 전체 목록 |
| 중간 | `docs-study/AdvancedSlash/distributeBond-winner-analysis.md` | 승자 판정 로직 상세 |
| 중간 | `docs-study/AdvancedSlash/e2e-test/real-faultdisputegame-migration-complete.md` | E2E 테스트 최신 상태 |
| 낮음 | `docs-study/AdvancedSlash/e2e-test/dispute-game-depth-bond-analysis.md` | Bond 비용 분석 |
| 낮음 | `docs-study/AdvancedSlash/anotherOption/` | 보상 분배 대안 옵션 |
