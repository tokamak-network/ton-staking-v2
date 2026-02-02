# E2E 슬래싱 테스트 진행 상황

**최종 업데이트**: 2026-02-03 00:45 KST

## 📋 테스트 현황 요약

| 테스트 | 상태 | 비고 |
|--------|------|------|
| `TestSlashing_BasicOperatorSlashing` | ✅ PASS | 기본 슬래싱 동작 검증 |
| `TestSlashing_DelegatorProtection` | ✅ PASS | 위임자 보호 검증 (30.15s) |
| `TestSlashing_ReRegistrationAfterSlashing` | ❌ FAIL | V2DelegatecallFailedError |
| `TestMultiChallenger_*` (6개) | ✅ PASS | 다중 챌린저 테스트 |
| `TestRealChallenger_*` (3개) | ✅ PASS | 실제 챌린저 테스트 |

**총 12개 테스트 중 11개 통과, 1개 실패**

---

## 🔄 현재 작업 상태

### 커밋되지 않은 변경 사항

```
modified:   deployments/v3-devnet-slashing.json
modified:   lib/optimism (new commits)
modified:   op-e2e/slashing/slashing_helpers.go
modified:   script/DeployV3WithSlashingForDevnet.s.sol
modified:   src/stake/managers/SeigManager_Slashing.sol
untracked:  docs-study/AdvancedSlash/e2e-test/issues/slashing-e2e-test-progress.md
```

### 브랜치 정보
- **현재 브랜치**: `ton-staking-v3/dev-slash`
- **최신 커밋**: `79fc22d5a` - "pass the make devnet-allocs-offline"

---

## ❌ 실패 테스트 분석

### `TestSlashing_ReRegistrationAfterSlashing`

#### 에러 메시지
```
Error: reverted with: custom error 0x1b53d9e5
```

#### 에러 셀렉터 분석
- `0x1b53d9e5` = `V2DelegatecallFailedError()`
- 위치: `SeigManagerV3_1.sol:482`

#### 호출 스택
```
CandidateAddOn.updateSeigniorage()
└─> SeigManager.updateSeigniorage()
    └─> SeigManagerV3_1._updateSeigniorageV2Delegatecall()
        └─> SeigManagerV3_2.updateSeigniorageV2() [delegatecall] ← FAIL
```

#### 근본 원인 분석

**핵심 발견: V3 마이그레이션이 수행되지 않음**

현재 **Genesis 파일**에서 `v3Migrated = false` 상태입니다. 배포 스크립트는 수정되었으나, Genesis 재생성이 아직 수행되지 않았습니다.

**문제 시나리오:**
1. 오퍼레이터 등록 → coinage 생성됨
2. 슬래싱 실행 → 스테이크 0으로 감소
3. 재스테이킹 → 동일한 CandidateAddOn에 deposit
4. `updateSeigniorage()` 호출 → V2 delegatecall 실패 (v3Migrated=false이므로)

---

## ✅ 완료된 수정 사항

### 1. 배포 스크립트 수정 (완료)

**파일**: `script/DeployV3WithSlashingForDevnet.s.sol`

V3 마이그레이션 로직이 `run()` 함수에 추가됨:

```solidity
function run() public override {
    // ... 기존 배포 로직 ...
    
    // V3 Migration (after all setup is complete)
    _setupV3ParameterSelectors();  // V3 setter 셀렉터 등록
    _setV3Parameters();            // V3 파라미터 설정
    _migrateToV3();                // V3 마이그레이션 실행
    
    vm.stopBroadcast();
    // ...
}
```

**추가된 함수들:**

| 함수 | 역할 |
|------|------|
| `_setupV3ParameterSelectors()` | SeigManagerProxy에 V3 파라미터 setter 셀렉터 등록 |
| `_setV3Parameters()` | V3 파라미터 설정 (k, θ, d, α, hMax, cMax, δ) |
| `_migrateToV3()` | `migrateToV3()` 호출하여 V3 로직 활성화 |

**설정되는 V3 파라미터:**

| 파라미터 | 값 | 설명 |
|----------|-----|------|
| `halfSaturationPoint` (k) | 10M TON | 쌍곡선 분배의 반포화점 |
| `minStakingRatio` (θ) | 10% | 최소 스테이킹 비율 |
| `daoDistributionRatio` (d) | 20% | DAO 분배 비율 |
| `validatorDistributionRatio` (α) | 20% | 밸리데이터 분배 비율 |
| `maxChallengers` (hMax) | 10 | 게임당 최대 챌린저 수 |
| `maxFraudProofCost` (cMax) | 1000 WTON | 최대 사기 증명 비용 |
| `sequencerAdditionalReward` (δ) | 100 WTON | 시퀀서 추가 보상 |

### 2. `getStakeBalance` 함수 수정 (완료)

**파일**: `op-e2e/slashing/slashing_helpers.go`

V3에서 deprecated된 `DepositManager.accStaked()` 대신 `SeigManager.stakeOf()` 사용:

```go
// 변경 전
balance, err := contracts.DepositManager.AccStaked(...)  // V3에서 없음

// 변경 후 (SeigManager.stakeOf() 사용)
callData, err := stakeOfABI.Pack("stakeOf", candidateAddOn, account)
result, err := sys.L1Client.CallContract(sys.Ctx, ethereum.CallMsg{
    To:   &sys.Addresses.SeigManagerProxy,
    Data: callData,
}, nil)
```

### 3. SystemConfig 등록 로직 추가 (완료)

**파일**: `script/DeployV3WithSlashingForDevnet.s.sol`

E2E 테스트에서 `registerCandidateAddOn()` 호출을 위해 필요:

```solidity
function _registerSystemConfigInBridgeRegistry() internal {
    L1BridgeRegistryV1_2(l1BridgeRegistryProxy).addManager(msg.sender);
    L1BridgeRegistryV1_2(l1BridgeRegistryProxy).registerRollupConfigByManager(
        systemConfig,
        3, // TYPE 3: OPTIMISM_BEDROCK_WITH_DISPUTE_GAME
        ton
    );
}
```

---

## 🎯 남은 작업

### 즉시 해결 방안

**1단계: Genesis 재생성**
```bash
make devnet-allocs-offline
```

**2단계: 주소 파일 복사**
```bash
cp deployments/v3-devnet-slashing.json .devnet/addresses.json
```

**3단계: 테스트 재실행**
```bash
cd op-e2e && GOWORK=off go test -v -run TestSlashing_ReRegistrationAfterSlashing ./slashing/... -timeout 180s
```

### 예상 결과

Genesis 재생성 후 `v3Migrated = true` 상태가 되어:
- `updateSeigniorage()` 호출 시 V3 로직 사용
- 슬래싱 후 재등록 시나리오 정상 동작

---

## 📁 관련 파일

| 파일 | 역할 | 상태 |
|------|------|------|
| `script/DeployV3WithSlashingForDevnet.s.sol` | Devnet 배포 스크립트 | ✅ 수정됨 (커밋 대기) |
| `op-e2e/slashing/slashing_helpers.go` | 테스트 헬퍼 함수 | ✅ 수정됨 (커밋 대기) |
| `op-e2e/slashing/slashing_test.go` | 슬래싱 E2E 테스트 | 변경 없음 |
| `src/stake/managers/SeigManagerV3_1.sol` | V3 SeigManager (주 로직) | 변경 없음 |
| `src/stake/managers/SeigManagerV3_2.sol` | V2 시뇨리지 분배 로직 | 변경 없음 |
| `src/stake/managers/SeigManager_Slashing.sol` | 슬래싱 로직 | ✅ 수정됨 (커밋 대기) |
| `.devnet/addresses.json` | 배포된 컨트랙트 주소 | Genesis 후 업데이트 필요 |

---

## 📝 명령어 참조

```bash
# 전체 빌드 & Genesis 재생성
make devnet-allocs-offline

# 슬래싱 테스트 실행 (전체)
cd op-e2e && GOWORK=off go test -v ./slashing/... -timeout 180s

# 특정 테스트만 실행
cd op-e2e && GOWORK=off go test -v -run TestSlashing_ReRegistrationAfterSlashing ./slashing/...

# devnet 주소 설정
cp deployments/v3-devnet-slashing.json .devnet/addresses.json

# 변경 사항 확인
git status
git diff --stat
```

---

## 🔗 관련 문서

- [WinningChallengerTracker 통합 이슈](./integration-issues-log.md)
- [DevNet Allocs 이슈](./devnet-allocs-issues.md)
- [Real Challenger E2E 계획](../real-challenger-e2e-plan.md)
- [Real Challenger 구현 보고서](../real-challenger-implementation-report.md)

---

## 📊 히스토리

| 날짜 | 작업 | 결과 |
|------|------|------|
| 2026-02-02 | 기본 슬래싱 테스트 통과 | 11/12 PASS |
| 2026-02-02 | V3 마이그레이션 로직 배포 스크립트에 추가 | 코드 완료 |
| 2026-02-02 | `getStakeBalance` 함수 V3 호환으로 수정 | 코드 완료 |
| 2026-02-03 | Genesis 재생성 대기 | **현재 단계** |
