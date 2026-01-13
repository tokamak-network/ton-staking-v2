# 슬래싱 E2E 테스트 - Phase 2 작업 진행 상황

## ✅ Phase 1 완료 (2026-01-13 22:00)

### 완료된 작업
1. ✅ Genesis 스크립트 수정 (`DeployV3SlashForDevnet.s.sol`)
2. ✅ ABI 경로 수정 (`abis/` 통일)
3. ✅ Genesis 파일 생성 (119개 컨트랙트, 2.1MB)
4. ✅ DAOCommitteeProxy 주소 추가
5. ✅ 첫 번째 테스트 파일 생성 (`slashing_test.go`)

### Genesis 주요 주소
```json
{
  "chainId": 900,
  "ton": "0x0C22C771Dc111c509c869240Fc87B910ED58Cc53",
  "wton": "0xA0B209787fa40200805c2fBeDCA8192969A6C3Ef",
  "daoCommitteeProxy": "0xf23B8c9debCdCEa2a40E81c3f6d786987069D40d",
  "ratProxy": "0x49FcbCC4E425add3a45AFC82F4dD0E5c227A0Ff8",
  "seigManagerProxy": "0x0f5D1ef48f12b6f691401bfe88c2037c690a6afe",
  "depositManagerProxy": "0x90118d110B07ABB82Ba8980D1c5cC96EeA810d2C",
  "layer2ManagerProxy": "0xcA03Dc4665A8C3603cb4Fd5Ce71Af9649dC00d44"
}
```

---

## 🚧 Phase 2: Go Bindings 및 헬퍼 함수 (진행 중)

### Step 1: Go Bindings 생성

#### 필요한 Bindings
1. **Layer2Manager_Slashing** - `slashingCandidate()` 함수
2. **DepositManager_Slashing** - `slash()`, `setSlashingRewardRate()` 함수
3. **SeigManager_Slashing** - `onSlash()` 함수
4. **DepositManager** - `deposit()`, `accStaked()` 함수
5. **Layer2ManagerV1_1** - `registerCandidateAddOn()` 함수
6. **DAOCommittee_V1** - DAO 관련 함수

#### 생성 명령어
```bash
# 1. Forge build
forge build --force

# 2. abigen으로 Go bindings 생성
abigen --abi=out/Layer2Manager_Slashing.sol/Layer2Manager_Slashing.json \
       --pkg=bindings \
       --type=Layer2ManagerSlashing \
       --out=op-bindings/bindings/layer2manager_slashing.go

abigen --abi=out/DepositManager_Slashing.sol/DepositManager_Slashing.json \
       --pkg=bindings \
       --type=DepositManagerSlashing \
       --out=op-bindings/bindings/depositmanager_slashing.go

abigen --abi=out/SeigManager_Slashing.sol/SeigManager_Slashing.json \
       --pkg=bindings \
       --type=SeigManagerSlashing \
       --out=op-bindings/bindings/seigmanager_slashing.go

abigen --abi=out/DepositManager.sol/DepositManager.json \
       --pkg=bindings \
       --type=DepositManager \
       --out=op-bindings/bindings/depositmanager.go

abigen --abi=out/Layer2ManagerV1_1.sol/Layer2ManagerV1_1.json \
       --pkg=bindings \
       --type=Layer2ManagerV1_1 \
       --out=op-bindings/bindings/layer2managerv1_1.go
```

---

### Step 2: 헬퍼 함수 작성 (`slashing_helpers.go`)

#### 파일 위치
`op-e2e/faultproofs/slashing_helpers.go`

#### 필요한 헬퍼 함수

```go
// 1. 슬래싱 컨트랙트 연결
func connectSlashingContracts(t *testing.T, sys *rat.TONStakingSystem) *SlashingContracts

// 2. Operator 등록 (CandidateAddOn)
func registerOperatorWithCandidateAddOn(
    t *testing.T,
    sys *rat.TONStakingSystem,
    operatorAuth *bind.TransactOpts,
    stakeAmount *big.Int,
) (candidateAddOn common.Address, operatorManager common.Address)

// 3. 슬래싱 실행
func executeSlashing(
    t *testing.T,
    sys *rat.TONStakingSystem,
    operatorManager common.Address,
    gameAddress common.Address,
) *types.Receipt

// 4. 스테이크 잔액 확인
func getStakeBalance(
    t *testing.T,
    sys *rat.TONStakingSystem,
    candidateAddOn common.Address,
    account common.Address,
) *big.Int

// 5. WTON 잔액 확인
func getWTONBalance(
    t *testing.T,
    sys *rat.TONStakingSystem,
    account common.Address,
) *big.Int
```

---

### Step 3: 첫 번째 테스트 구현

#### 테스트: `TestSlashing_BasicOperatorSlashing`

**시나리오**:
```
1. Operator 등록 (10,000 TON)
2. DisputeGame 생성 (잘못된 root claim)
3. Challenger가 step 호출
4. Game resolve (CHALLENGER_WINS)
5. 슬래싱 실행
6. 검증:
   - Operator 스테이크 = 0
   - Challenger 보상 = 1,000 WTON (10%)
```

**구현 단계**:
1. ✅ 테스트 환경 설정
2. ⏳ Operator 등록
3. ⏳ DisputeGame 생성 및 해결
4. ⏳ 슬래싱 실행
5. ⏳ 결과 검증

---

## 📝 다음 작업

### 즉시 수행
1. ⏳ Forge build 완료 대기
2. ⏳ Go bindings 생성
3. ⏳ `slashing_helpers.go` 작성
4. ⏳ `TestSlashing_BasicOperatorSlashing` 구현

### 이후 작업 (Phase 3)
1. 일반 스테이커 보호 테스트
2. 슬래싱 후 재등록 테스트
3. 보상 분배 테스트
4. 종합 시나리오 테스트

---

## 🔍 참고 자료

### 기존 E2E 테스트
- `op-e2e/faultproofs/rat_challenge_test.go:TestSimpleRAT_ChallengerWins`
- `op-e2e/faultproofs/rat_challenge_helpers.go`

### Forge 테스트
- `test/Slashing/SlashingTest.t.sol:test_SlashingAndReward`
- `test/Slashing/SlashingTest.t.sol:test_Slashing_DelegatorSeigniorageProtection`

### 슬래싱 컨트랙트
- `src/layer2/Layer2Manager_Slashing.sol`
- `src/stake/managers/DepositManager_Slashing.sol`
- `src/stake/managers/SeigManager_Slashing.sol`

---
