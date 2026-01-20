# 슬래싱 E2E 테스트 작업 계획

## 📋 현재 상황

### ✅ 완료된 작업
1. **Forge 단위 테스트 (Solidity)** - `test/Slashing/SlashingTest.t.sol`
   - 20개 테스트 시나리오 완료 (100% 통과)
   - 일반 스테이커 보호 테스트 포함
   - 문서화 완료 (한국어/영어)

### 🎯 다음 단계: E2E 테스트 (Go)
슬래싱 메커니즘을 실제 네트워크 환경에서 검증하는 E2E 테스트 추가 필요

---

## 🔧 E2E 테스트 작업 항목

### 1. 테스트 파일 생성 ⭐ **우선순위: 높음**

#### 파일 위치
```
op-e2e/slashing/
├── rat_challenge_helpers.go    (신규 - 헬퍼 함수)
├── slashing_helpers.go         (신규 - 슬래싱 시나리오 헬퍼 함수)
└── slashing_test.go            (신규 - 슬래싱 시나리오) ⭐
```

#### 추가할 테스트 함수
```go
// op-e2e/faultproofs/slashing_test.go

// 기본 슬래싱 테스트
func TestSlashing_BasicOperatorSlashing(t *testing.T)

// 일반 스테이커 보호 테스트
func TestSlashing_DelegatorProtection(t *testing.T)

// 슬래싱 후 재등록 테스트
func TestSlashing_ReRegistrationAfterSlashing(t *testing.T)

// 보상 분배 테스트
func TestSlashing_RewardDistribution(t *testing.T)

// 종합 시나리오 테스트
func TestSlashing_ComprehensiveScenario(t *testing.T)
```

---

### 2. 헬퍼 함수 추가 ⭐ **우선순위: 중간**

#### 파일: `op-e2e/slashing/slashing_helpers.go` (신규)

필요한 헬퍼 함수들:

```go
// 슬래싱 관련 컨트랙트 연결
func connectSlashingContracts(t *testing.T, sys *rat.TONStakingSystem) *SlashingContracts

// Operator 등록 (CandidateAddOn)
func registerOperatorWithCandidateAddOn(
    t *testing.T,
    sys *rat.TONStakingSystem,
    operatorAuth *bind.TransactOpts,
    stakeAmount *big.Int,
) (candidateAddOn common.Address, operatorManager common.Address)

// 일반 스테이커 예치
func delegatorDeposit(
    t *testing.T,
    sys *rat.TONStakingSystem,
    delegatorAuth *bind.TransactOpts,
    candidateAddOn common.Address,
    amount *big.Int,
)

// 슬래싱 실행
func executeSlashing(
    t *testing.T,
    sys *rat.TONStakingSystem,
    challengerAuth *bind.TransactOpts,
    operatorManager common.Address,
    gameAddress common.Address,
) (receipt *types.Receipt)

// 슬래싱 이벤트 파싱
func parseSlashingEvent(
    t *testing.T,
    receipt *types.Receipt,
) (slashedAmount *big.Int, rewardAmount *big.Int)

// 스테이크 잔액 확인
func getStakeBalance(
    t *testing.T,
    sys *rat.TONStakingSystem,
    candidateAddOn common.Address,
    account common.Address,
) *big.Int

// 시뇨리지 업데이트
func updateSeigniorage(
    t *testing.T,
    sys *rat.TONStakingSystem,
    candidateAddOn common.Address,
)
```

---

### 3. Go Bindings 생성 ⭐ **우선순위: 높음**

슬래싱 관련 컨트랙트의 Go bindings 필요

#### 필요한 Bindings

```bash
# 1. Layer2Manager_Slashing
abigen --abi=out/Layer2Manager_Slashing.sol/Layer2Manager_Slashing.json \
       --pkg=bindings \
       --type=Layer2ManagerSlashing \
       --out=op-e2e/bindings/layer2manager_slashing.go

# 2. DepositManager_Slashing
abigen --abi=out/DepositManager_Slashing.sol/DepositManager_Slashing.json \
       --pkg=bindings \
       --type=DepositManagerSlashing \
       --out=op-e2e/bindings/depositmanager_slashing.go

# 3. SeigManager_Slashing
abigen --abi=out/SeigManager_Slashing.sol/SeigManager_Slashing.json \
       --pkg=bindings \
       --type=SeigManagerSlashing \
       --out=op-e2e/bindings/seigmanager_slashing.go

# 4. DepositManager (일반 deposit 함수용)
abigen --abi=out/DepositManager.sol/DepositManager.json \
       --pkg=bindings \
       --type=DepositManager \
       --out=op-e2e/bindings/depositmanager.go

# 5. Layer2ManagerV1_1 (registerCandidateAddOn용)
abigen --abi=out/Layer2ManagerV1_1.sol/Layer2ManagerV1_1.json \
       --pkg=bindings \
       --type=Layer2ManagerV1_1 \
       --out=op-e2e/bindings/layer2managerv1_1.go
```

#### Makefile 타겟 추가

```makefile
# Makefile에 추가
.PHONY: bindings-slashing
bindings-slashing:
	@echo "Generating slashing contract bindings..."
	abigen --abi=out/Layer2Manager_Slashing.sol/Layer2Manager_Slashing.json \
	       --pkg=bindings --type=Layer2ManagerSlashing \
	       --out=op-e2e/bindings/layer2manager_slashing.go
	abigen --abi=out/DepositManager_Slashing.sol/DepositManager_Slashing.json \
	       --pkg=bindings --type=DepositManagerSlashing \
	       --out=op-e2e/bindings/depositmanager_slashing.go
	abigen --abi=out/SeigManager_Slashing.sol/SeigManager_Slashing.json \
	       --pkg=bindings --type=SeigManagerSlashing \
	       --out=op-e2e/bindings/seigmanager_slashing.go
	@echo "✓ Slashing bindings generated"
```

---

### 4. Genesis 파일 업데이트 ⭐ **우선순위: 높음**

슬래싱 컨트랙트가 genesis에 포함되어 있는지 확인 필요

#### 확인 사항
```bash
# 현재 genesis 확인
cat .devnet/addresses.json | jq .

# 필요한 주소들:
# - layer2ManagerProxy (슬래싱 버전)
# - depositManagerProxy (슬래싱 버전)
# - seigManagerProxy (슬래싱 버전)
```

#### Genesis 재생성 (필요시)
```bash
# 1. 기존 genesis 삭제
make devnet-clean

# 2. 슬래싱 컨트랙트 포함하여 재생성
# script/DeployV3FullSlash.s.sol 사용
make devnet-allocs-offline
```

---

### 5. 테스트 시나리오 상세 설계

#### 시나리오 1: 기본 Operator 슬래싱
```go
func TestSlashing_BasicOperatorSlashing(t *testing.T) {
    // 1. Operator 등록 (10,000 TON)
    // 2. Dispute Game 생성 (잘못된 root claim)
    // 3. Challenger가 step 호출
    // 4. Game resolve (CHALLENGER_WINS)
    // 5. 슬래싱 실행
    // 6. 검증:
    //    - Operator 스테이크 = 0
    //    - Challenger 보상 = 10% (1,000 TON)
    //    - 나머지 90% 소각
}
```

#### 시나리오 2: 일반 스테이커 보호
```go
func TestSlashing_DelegatorProtection(t *testing.T) {
    // 1. Operator 등록 (10,000 TON)
    // 2. Delegator1 예치 (5,000 TON)
    // 3. Delegator2 예치 (3,000 TON)
    // 4. 시간 경과 (시뇨리지 발생)
    // 5. Operator 슬래싱
    // 6. 검증:
    //    - Operator 스테이크 = 0
    //    - Delegator1 스테이크 = 5,000 + 시뇨리지
    //    - Delegator2 스테이크 = 3,000 + 시뇨리지
    //    - Delegator들 출금 가능
}
```

#### 시나리오 3: 슬래싱 후 해당 OperatorManager로 다시 스테이킹
```go
func TestSlashing_ReRegistrationAfterSlashing(t *testing.T) {
    // 1. Operator 등록 및 슬래싱
    // 2. 슬래싱 후 시간이 지나도 시뇨리지가 올라가지 않음
    // 3. 해당 OperatorManager로 다시 스테이킹
    // 4. 검증:
    //    - 슬래싱 후 시간이 지나도 해당 Layer2에 시뇨리지가 쌓이지 않음
    //    - 다시 스테이킹 후 시뇨리지 정상 작동
}
```

#### 시나리오 4: 보상 분배 (50% 보상 비율)
```go
func TestSlashing_RewardDistribution(t *testing.T) {
    // 1. 보상 비율 50%로 설정
    // 2. Operator 등록 및 슬래싱
    // 3. 검증:
    //    - Challenger 보상 = 50%
    //    - 소각 = 50%
}
```

#### 시나리오 5: 종합 시나리오
```go
func TestSlashing_ComprehensiveScenario(t *testing.T) {
    // 1. Operator + 2명의 Delegator
    // 2. 시간 경과 (시뇨리지 발생)
    // 3. Operator 슬래싱
    // 4. Delegator 출금
    // 5. 새로운 Delegator 참여 시도 (실패)
    // 6. Operator 재등록
    // 7. 새로운 Delegator 참여 (성공)
}
```

---

### 6. 문서 업데이트 ⭐ **우선순위: 낮음**

#### 업데이트할 파일들

1. **`docs/test/e2e-tests.md`**
   - 슬래싱 테스트 섹션 추가
   - 실행 방법 추가

2. **`docs/test/README.md`**
   - E2E 테스트 수 업데이트 (7개 → 12개)

3. **`docs-study/slashing-e2e-guide.md`** (신규)
   - 슬래싱 E2E 테스트 상세 가이드

---

## 📝 작업 순서 (추천)

### Phase 1: 준비 작업 (1-2일)
1. ✅ **Go Bindings 생성**
   ```bash
   forge build
   make bindings-slashing
   ```

2. ✅ **Genesis 파일 확인/업데이트**
   ```bash
   # 슬래싱 컨트랙트 포함 여부 확인
   cat .devnet/addresses.json
   
   # 필요시 재생성
   make devnet-clean
   make devnet-allocs-offline
   ```

3. ✅ **헬퍼 함수 작성**
   - `op-e2e/slashing/slashing_helpers.go` 생성
   - 기본 헬퍼 함수 구현

### Phase 2: 기본 테스트 (2-3일)
4. ✅ **시나리오 1 구현**
   - `TestSlashing_BasicOperatorSlashing`
   - 가장 단순한 슬래싱 플로우

5. ✅ **시나리오 2 구현**
   - `TestSlashing_DelegatorProtection`
   - 일반 스테이커 보호 검증

### Phase 3: 고급 테스트 (2-3일)
6. ✅ **시나리오 3-4 구현**
   - 재등록, 보상 분배 테스트

7. ✅ **시나리오 5 구현**
   - 종합 시나리오

### Phase 4: 마무리 (1일)
8. ✅ **문서 업데이트**
   - E2E 테스트 가이드 작성
   - README 업데이트

9. ✅ **CI/CD 통합**
   - GitHub Actions 워크플로우 확인

---

## 🔍 참고 자료

### 기존 E2E 테스트 예시
- `op-e2e/faultproofs/rat_challenge_test.go:TestSimpleRAT_ChallengerWins`
  - 가장 복잡한 E2E 테스트
  - 슬래싱 테스트의 좋은 참고 자료

### 헬퍼 함수 예시
- `op-e2e/faultproofs/rat_challenge_helpers.go`
  - 재사용 가능한 헬퍼 함수 패턴

### Genesis 생성 스크립트
- `script/DeployV3SlashForDevnet.s.sol`
  - 슬래싱 컨트랙트 배포 스크립트

---

## ⚠️ 주의사항

### 1. 컨트랙트 주소 관리
- Genesis에 배포된 주소를 `.devnet/addresses.json`에서 관리
- 테스트에서 하드코딩하지 말고 addresses.json 사용

### 2. 시뇨리지 시뮬레이션
- Anvil에서 블록 진행 시뮬레이션 필요
- `advanceTimeAndMine()` 헬퍼 사용

### 3. 가스 비용
- E2E 테스트는 실제 가스 비용 발생
- 테스트 계정에 충분한 ETH 필요 (genesis에서 설정)

### 4. 병렬 실행
- `t.Parallel()` 사용으로 독립적인 Anvil 노드 필요
- 포트 충돌 방지

---

## 🎯 예상 결과

### 완료 후 테스트 구조
```
E2E Tests (Go)
├── System Tests (3개)
│   ├── TestTONStakingSystemStartup
│   ├── TestAccountBalances
│   └── TestRATContractCall
├── RAT Scenario Tests (4개)
│   ├── TestSimpleRAT_ValidatorRegistration
│   ├── TestSimpleRAT_GameCreation
│   ├── TestSimpleRAT_EvidenceSubmission
│   └── TestSimpleRAT_ChallengerWins
└── Slashing Tests (5개) ⭐ 신규
    ├── TestSlashing_BasicOperatorSlashing
    ├── TestSlashing_DelegatorProtection
    ├── TestSlashing_ReRegistrationAfterSlashing
    ├── TestSlashing_RewardDistribution
    └── TestSlashing_ComprehensiveScenario

Total: 12 E2E tests
```

### 실행 시간 예상
- 기존: ~21초 (7개 테스트)
- 추가 후: ~35-40초 (12개 테스트)

---

## 📞 다음 단계

1. **Phase 1부터 시작**
   ```bash
   # Go bindings 생성
   forge build
   make bindings-slashing
   ```

2. **Genesis 확인**
   ```bash
   cat .devnet/addresses.json | jq .
   ```

3. **첫 번째 테스트 작성**
   - `op-e2e/slashing/slashing_test.go` 생성
   - `TestSlashing_BasicOperatorSlashing` 구현

작업을 시작할 준비가 되면 알려주세요! 🚀
