# TON Staking V3 Genesis 생성 흐름 (간단 버전)

## 💡 Offline 모드란?

**"Offline 모드" = 실제 블록체인 없이 시뮬레이션으로 Genesis 생성**

```solidity
// 1단계: 기존 상태 로드
string memory allocsJson = vm.readFile(".devnet/allocs-l1.json");
vm.loadAllocs(allocsJson);  // Optimism 컨트랙트 로드

// 2단계: 시뮬레이션으로 TON Staking 컨트랙트 배포
MockTON ton = new MockTON();           // ← 실제로 배포됨!
RATProxy ratProxy = new RATProxy();    // ← 실제로 배포됨!
// ... 모든 컨트랙트 배포

// 3단계: 결과를 Genesis 파일로 저장
string memory newState = vm.dumpState();
vm.writeFile(".devnet/allocs-l1-staking-v3.json", newState);
```

**결과**: `genesis-l1-staking-v3.json` 파일에 모든 컨트랙트가 배포된 상태 저장
→ Anvil이 이 Genesis 파일을 로드하면 모든 컨트랙트가 이미 배포되어 있음!

**장점**:
- ✅ 실제 블록체인 없이 Genesis 생성 가능
- ✅ 배포 트랜잭션 없이 바로 테스트 시작
- ✅ 재현 가능한 테스트 환경

---

## 📋 전체 흐름도

```
1. Optimism 컨트랙트 로드
   ↓
2. TON Staking V2 컨트랙트 배포
   ↓
3. TON Staking V3 컨트랙트 배포 (RAT, ValidatorReward)
   ↓
4. DAO 컨트랙트 배포
   ↓
5. DisputeGameFactory 초기화 (vm.store)
   ↓
6. RAT 초기화 (vm.store)
   ↓
7. L1BridgeRegistry에 SystemConfig 등록 ⭐
   ↓
8. Layer2 (CandidateAddOn) 생성 ⭐
   ↓
9. 테스트 토큰 민팅
```

## ⭐ 핵심 단계 상세

### 7. L1BridgeRegistry에 SystemConfig 등록

**목적**: SystemConfig를 L1BridgeRegistry에 등록하여 RAT가 올바른 rollup config 인식

**방법**: 실제 함수 호출 (vm.store 사용 안함)

```solidity
// Step 1: Deployer에게 manager 권한 부여
L1BridgeRegistryV1_2(l1BridgeRegistryProxy).addManager(deployer);

// Step 2: SystemConfig 등록
L1BridgeRegistryV1_2(l1BridgeRegistryProxy).registerRollupConfigByManager(
    systemConfig,    // Optimism SystemConfig 주소
    3,               // TYPE 3: OPTIMISM_BEDROCK_WITH_DISPUTE_GAME
    ton,             // L2 TON 토큰 주소
    "DevnetOptimism" // 이름
);
```

**결과**:
- `rollupInfo[systemConfig]` 설정됨
- `disputeGameFactory[systemConfig]` = true
- `rollupConfigWithDisputeGameFactory[dgf]` = systemConfig

---

### 8. Layer2 (CandidateAddOn) 생성

**목적**: Validator가 deposit할 수 있는 실제 Layer2 컨트랙트 생성

**방법**: 실제 함수 호출 (vm.store 사용 안함)

```solidity
// Step 1: Operator deposit 계산
uint256 D_sequencer = MAX_CHALLENGERS * MAX_FRAUD_PROOF_COST + SEQUENCER_ADDITIONAL_REWARD;
uint256 operatorDeposit = max(D_sequencer, seigManagerMinimum) + 0.1e27;

// Step 2: WTON mint & approve
WTON.mint(deployer, operatorDeposit);
WTON.approve(layer2ManagerProxy, operatorDeposit);

// Step 3: Layer2 생성
Layer2Manager.registerCandidateAddOn(
    systemConfig,     // Optimism SystemConfig
    operatorDeposit,  // Operator 예치금
    false,            // flagTon (false = WTON 사용)
    "DevnetOptimism"  // Layer2 이름
);
```

**자동 생성**:
1. OperatorManager 컨트랙트 (via OperatorManagerFactory)
2. CandidateAddOn (Layer2) 컨트랙트 (via DAO)
3. Layer2Registry에 등록
4. Layer2Manager 매핑 설정:
   - `rollupConfigInfo[systemConfig]` → operatorManager
   - `operatorInfo[operatorManager]` → candidateAddOn
   - `operatorOfLayer[candidateAddOn]` → operatorManager
5. Operator의 초기 deposit 완료

**결과**:
- Layer2 주소를 `getLayer2BySystemConfig(systemConfig)`로 조회 가능
- Validator가 deposit 가능한 실제 Layer2 생성됨

---

## 🎯 왜 이 방법을 사용하나요?

### 이전 방식 (vm.store 사용)
```
❌ 문제점:
- Mock 주소만 생성
- 실제 컨트랙트 없음
- Validator deposit 불가
- RAT 작동 안됨
```

### 현재 방식 (실제 함수 호출)
```
✅ 장점:
- 실제 컨트랙트 생성
- 모든 매핑 자동 설정
- Validator deposit 가능
- RAT 정상 작동
```

---

## 📊 제네시스 파일 구조

```
.devnet/
├── genesis-l1-staking-v3.json    # Anvil용 Genesis 파일
├── allocs-l1-staking-v3.json     # Raw 계정 상태
└── addresses.json                 # 배포된 컨트랙트 주소들
```

---

## 🔍 테스트에서 확인 방법

```go
// 1. Genesis 로드
sys := rat.StartTONStakingSystem(t)

// 2. Layer2 주소 확인 (0x0이 아니어야 함)
layer2, _ := getLayer2BySystemConfig(t, sys)
require.NotEqual(t, common.Address{}, layer2)

// 3. Validator 등록
depositAmount := getTestDepositAmount()  // 50000 WTON
WTON.Approve(depositManager, depositAmount)
DepositManager.Deposit(layer2, depositAmount)
RAT.RegisterValidator(systemConfig)

// 4. DisputeGame 생성하면 RAT 자동 트리거
DisputeGameFactory.Create(...)
// → AttentionTestTriggered 이벤트 발생 확인
```

---

## ⚠️ 주의사항

### WTON Decimals
```go
// ❌ 잘못된 예 (18 decimals)
amount := new(big.Int).Mul(big.NewInt(50000), big.NewInt(1e18))

// ✅ 올바른 예 (27 decimals - RAY scale)
amount := new(big.Int).Mul(big.NewInt(50000), big.NewInt(1e27))
```

### Coinage Rounding
```go
// Deposit 시 coinage 계산으로 약간 감소
// 해결: 1% 버퍼 추가
adjustedAmount := new(big.Int).Mul(amount, big.NewInt(101))
adjustedAmount.Div(adjustedAmount, big.NewInt(100))
```

---

## 📚 참고 파일

- 배포 스크립트: `script/DeployV3FullForDevnet.s.sol`
- 테스트 시스템: `op-e2e/e2eutils/rat/system.go`
- 테스트 헬퍼: `op-e2e/faultproofs/rat_challenge_helpers.go`
- RAT 컨트랙트: `src/validator/RAT.sol`
