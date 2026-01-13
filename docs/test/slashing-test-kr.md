# 슬래싱 메커니즘 테스트 가이드

## 목차
- [개요](#개요)
- [테스트 환경](#테스트-환경)
- [배포 과정](#배포-과정)
- [테스트 시나리오](#테스트-시나리오)
- [테스트 실행 방법](#테스트-실행-방법)
- [테스트 결과 분석](#테스트-결과-분석)

---

## 개요

이 문서는 TON Staking V3의 슬래싱 메커니즘에 대한 종합적인 테스트 스위트를 설명합니다. 슬래싱은 악의적이거나 부정확한 행동을 한 오퍼레이터에게 페널티를 부과하고, 이를 발견한 챌린저에게 보상을 제공하는 중요한 보안 메커니즘입니다.

### 테스트 파일 위치
- **테스트 파일**: `test/Slashing/SlashingTest.t.sol`
- **배포 스크립트**: `script/DeployV3FullSlash.s.sol`
- **슬래싱 컨트랙트**:
  - `src/layer2/Layer2Manager_Slashing.sol`
  - `src/stake/managers/DepositManager_Slashing.sol`
  - `src/stake/managers/SeigManager_Slashing.sol`

### 테스트 커버리지
- **총 테스트 수**: 17개
- **통과율**: 100% (17/17)
- **테스트 카테고리**:
  - 기본 기능 테스트: 2개
  - 보상 비율 테스트: 4개
  - 시뇨리지 테스트: 2개
  - 보안 테스트: 5개
  - 엣지 케이스 테스트: 4개

---

## 테스트 환경

### 필수 도구
- **Foundry**: Solidity 테스트 프레임워크
  - `forge`: 컴파일 및 테스트 실행
  - `anvil`: 로컬 이더리움 노드 (선택사항)
- **Solidity**: v0.8.19
- **Node.js**: v16 이상 (선택사항)

### 의존성 컨트랙트
테스트는 다음 컨트랙트들을 배포하고 설정합니다:

#### 코어 컨트랙트
1. **토큰 컨트랙트**
   - `MockTON`: 테스트용 TON 토큰
   - `MockWTON`: 테스트용 Wrapped TON

2. **매니저 컨트랙트**
   - `Layer2Manager`: Layer2 오퍼레이터 관리
   - `DepositManager`: 스테이킹 예치금 관리
   - `SeigManager`: 시뇨리지(이자) 관리
   - `L1BridgeRegistry`: L1-L2 브릿지 등록

3. **DAO 컨트랙트**
   - `DAOVault`: DAO 자금 관리
   - `DAOAgendaManager`: 안건 관리
   - `DAOCommittee`: DAO 위원회

4. **팩토리 컨트랤트**
   - `CandidateFactory`: Candidate 생성
   - `CandidateAddOnFactory`: CandidateAddOn 생성
   - `OperatorManagerFactory`: OperatorManager 생성

#### Mock 컨트랙트
1. **MockDisputeGameFactory**: Dispute Game 생성 팩토리
2. **MockFaultDisputeGame2**: Fault Dispute Game 시뮬레이션
3. **SlashingMockFactory**: 슬래싱 테스트용 팩토리
4. **SlashingMockGame**: 슬래싱 테스트용 게임

### 테스트 설정 파라미터

```solidity
// 슬래싱 보상 비율 (기본값)
uint256 SLASHING_REWARD_RATE = 1000; // 10% (basis points)

// 스테이킹 금액
uint256 DEFAULT_STAKE = 10000 * 1e18; // 10,000 TON
uint256 MINIMUM_STAKE = 1000 * 1e18;  // 1,000 TON

// 테스트 계정
address operator;    // 오퍼레이터
address challenger;  // 챌린저
address daoCommitteeProxy; // DAO 위원회
```

---

## 배포 과정

### 1. 초기 설정 (setUp)

테스트의 `setUp()` 함수는 다음 단계를 수행합니다:

#### Step 1-2: 기본 계정 설정
```solidity
admin = makeAddr("proxyAdmin");
owner = address(this);
operator = makeAddr("operator");
challenger = makeAddr("challenger");
```

#### Step 3-4: 토큰 배포
```solidity
// MockTON 배포 (초기 공급량: 50,000,000 TON)
ton = address(new MockTON());

// MockWTON 배포 및 TON 연결
wton = address(new MockWTON());
MockWTON(wton).setTON(ton);
```

#### Step 5-6: Coinage 인프라 배포
```solidity
// RefactorCoinageSnapshot 배포
refactorCoinageSnapshot = new RefactorCoinageSnapshot();

// CoinageFactory 배포 및 설정
coinageFactory = new CoinageFactory();
coinageFactory.setAutoCoinageLogic(refactorCoinageSnapshot);
```

#### Step 7: Layer2Registry 배포
```solidity
layer2RegistryImpl = new Layer2Registry();
layer2RegistryProxy = new Layer2RegistryProxy();
Layer2RegistryProxy(payable(layer2RegistryProxy)).upgradeTo(layer2RegistryImpl);
```

#### Step 8-10: 매니저 컨트랙트 배포
```solidity
// SeigManager 배포 (V1_2, V1_3, Slashing 버전)
seigManagerImpl = new SeigManagerV1_2();
seigManagerProxy = new SeigManagerProxy();

// DepositManager 배포 (Slashing 버전 포함)
depositManagerImpl = new DepositManager();
depositManagerProxy = new DepositManagerProxy();

// Layer2Manager 배포 (Slashing 버전 포함)
layer2ManagerImpl = new Layer2ManagerV1_1();
layer2ManagerProxy = new Layer2ManagerProxy();
```

#### Step 11-13: DAO 컨트랙트 배포
```solidity
// DAOVault 배포
daoVault = deployCode("./abis/DAOVault.json", ...);

// DAOAgendaManager 배포
daoAgendaManager = deployCode("./abis/DAOAgendaManager.json", ...);

// DAOCommittee 배포 (Proxy2 + Proxy 구조)
daoCommitteeProxy = deployCode("./abis/DAOCommitteeProxy.json", ...);
```

#### Step 14: Minter 권한 설정
```solidity
// DAOCommittee에 Layer2Registry의 MINTER_ROLE 부여
Layer2Registry(layer2RegistryProxy).grantRole(MINTER_ROLE, daoCommitteeProxy);
```

#### Step 15: SeigManager 설정
```solidity
// SeigManager 데이터 설정 및 시작 블록 설정
SeigManagerV1_2(seigManagerProxy).setData(...);
SeigManagerV1_2(seigManagerProxy).setSeigStartBlock(1);
```

#### Step 16: 소유권 이전
```solidity
// 모든 매니저 컨트랙트의 소유권을 DAOCommittee로 이전
SeigManagerProxy(payable(seigManagerProxy)).transferOwnership(daoCommitteeProxy);
DepositManagerProxy(payable(depositManagerProxy)).transferOwnership(daoCommitteeProxy);
// ... 기타 컨트랙트들
```

#### Step 17-18: 테스트 환경 설정
```solidity
// Mock Dispute Game Factory 및 Game 배포
mockFactory = new SlashingMockFactory();
mockGame = new SlashingMockGame();

// L1BridgeRegistry 권한 부여
L1BridgeRegistryProxy.addManager(address(this));
L1BridgeRegistryProxy.addRegistrant(address(this));

// Rollup Config 등록
L1BridgeRegistryV1_2(l1BridgeRegistryProxy).registerRollupConfig(
    rollupConfig,
    2, // Bedrock
    makeAddr("l2TON"),
    "TestRollup"
);
```

### 2. 배포 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                      DAO Governance                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  DAOVault    │  │DAOAgendaMgr  │  │DAOCommittee  │      │
│  └──────────────┘  └──────────────┘  └──────┬───────┘      │
│                                              │               │
└──────────────────────────────────────────────┼──────────────┘
                                               │ Owner
                    ┌──────────────────────────┼──────────────────────────┐
                    │                          │                          │
         ┌──────────▼─────────┐    ┌──────────▼─────────┐    ┌──────────▼─────────┐
         │  SeigManagerProxy  │    │DepositManagerProxy │    │Layer2ManagerProxy  │
         │   (Slashing)       │◄───┤   (Slashing)       │◄───┤   (Slashing)       │
         └────────────────────┘    └────────────────────┘    └────────────────────┘
                    │                          │                          │
                    │                          │                          │
         ┌──────────▼─────────┐    ┌──────────▼─────────┐    ┌──────────▼─────────┐
         │ Layer2Registry     │    │ CoinageFactory     │    │L1BridgeRegistry    │
         └────────────────────┘    └────────────────────┘    └────────────────────┘
                                                                         │
                                                              ┌──────────▼─────────┐
                                                              │  RollupConfig      │
                                                              │  (Mock)            │
                                                              └────────────────────┘
```

---

## 테스트 시나리오

### 기본 기능 테스트 (2개)

#### 1. test_CandidateRegistrationAndStaking
**목적**: Candidate 등록 및 스테이킹 기본 기능 검증

**시나리오**:
1. Operator에게 10,000 TON 지급
2. Layer2Manager 승인
3. Candidate 등록 (registerCandidateAddOn)
4. 등록 검증:
   - CandidateAddOn 주소 확인
   - OperatorManager 주소 확인
   - 스테이킹 금액 확인 (RAY 단위)

**검증 항목**:
- ✅ CandidateAddOn이 성공적으로 생성됨
- ✅ 스테이킹 금액이 정확함 (10,000 TON * 1e9 RAY)

#### 2. test_SlashingAndReward
**목적**: 기본 슬래싱 및 보상 메커니즘 검증

**시나리오**:
1. Candidate 등록 (test_CandidateRegistrationAndStaking 재사용)
2. Mock Dispute Game 생성
3. Challenger가 게임에서 승리 (step 호출)
4. 게임 종료 (resolve)
5. 슬래싱 실행
6. 결과 검증:
   - 오퍼레이터 스테이크 = 0
   - Challenger 보상 = 초기 스테이크 * 10%

**검증 항목**:
- ✅ 오퍼레이터의 모든 스테이크가 소각됨
- ✅ Challenger가 10% 보상을 받음
- ✅ 나머지 90%는 소각됨

---

### 보상 비율 테스트 (4개)

#### 3. test_Slashing_CustomRewardRate_50Percent
**목적**: 50% 보상 비율 설정 및 검증

**시나리오**:
1. 보상 비율을 50%로 설정 (5000 basis points)
2. Candidate 등록 및 슬래싱 실행
3. Challenger 보상 검증

**검증 항목**:
- ✅ 보상 비율이 50%로 설정됨
- ✅ Challenger가 슬래싱된 금액의 50%를 받음
- ✅ 나머지 50%는 소각됨

#### 4. test_Slashing_FullRewardRate_100Percent
**목적**: 100% 보상 비율 (전액 보상)

**시나리오**:
1. 보상 비율을 100%로 설정 (10000 basis points)
2. Candidate 등록 및 슬래싱 실행
3. Challenger가 전액을 받는지 검증

**검증 항목**:
- ✅ Challenger가 슬래싱된 전체 금액을 받음
- ✅ 소각되는 금액이 없음

#### 5. test_Slashing_ZeroRewardRate_AllBurned
**목적**: 0% 보상 비율 (전액 소각)

**시나리오**:
1. 보상 비율을 0%로 설정
2. Candidate 등록 및 슬래싱 실행
3. 모든 금액이 소각되는지 검증

**검증 항목**:
- ✅ Challenger가 보상을 받지 않음
- ✅ 슬래싱된 전체 금액이 소각됨

#### 6. test_Slashing_BelowMinimumStake
**목적**: 최소 스테이크 요구사항 검증

**시나리오**:
1. 1000 TON으로 등록 시도
2. 최소 스테이크 미만으로 등록 거부되는지 확인

**검증 항목**:
- ✅ 최소 스테이크 미만 등록이 거부됨
- ✅ "minimum amount is required" 에러 발생

---

### 시뇨리지 테스트 (2개)

#### 7. test_Slashing_WithSeigniorage_BurnsAll
**목적**: 시뇨리지 발생 후 슬래싱 시 원금+이자 모두 소각

**시나리오**:
1. Candidate 등록
2. 1000 블록 경과 (시뇨리지 발생)
3. 시뇨리지 업데이트 시도
4. 슬래싱 실행
5. 원금+이자가 모두 소각되는지 검증

**검증 항목**:
- ✅ 시뇨리지가 발생함 (테스트 환경에서 가능한 경우)
- ✅ 슬래싱 시 원금+이자가 모두 소각됨
- ✅ 최종 스테이크 = 0

#### 8. test_Slashing_WithUnreceivedSeigniorage
**목적**: 미지급 시뇨리지도 슬래싱에 포함

**시나리오**:
1. Candidate 등록
2. 1000 블록 경과 (시뇨리지 발생)
3. **시뇨리지 업데이트 없이** 슬래싱 실행
4. 미지급 시뇨리지도 계산되어 소각되는지 검증

**검증 항목**:
- ✅ 슬래싱 시 내부적으로 시뇨리지 업데이트가 수행됨
- ✅ 보상이 초기 스테이크보다 큼 (미지급 시뇨리지 포함)
- ✅ 최종 스테이크 = 0

---

### 보안 테스트 (5개)

#### 9. test_Slashing_PreventDoubleSlashing
**목적**: 중복 슬래싱 방지

**시나리오**:
1. Candidate 등록 및 슬래싱 실행
2. 동일한 오퍼레이터에 대해 두 번째 슬래싱 시도
3. 두 번째 슬래싱이 거부되는지 확인

**검증 항목**:
- ✅ 첫 번째 슬래싱 성공
- ✅ 두 번째 슬래싱 시도 시 revert
- ✅ 스테이크가 0이므로 슬래싱 불가

#### 10. test_Slashing_MultipleChallengers_FirstWins
**목적**: 여러 Challenger 중 첫 번째만 성공

**시나리오**:
1. Candidate 등록
2. Challenger1이 게임에서 step 호출
3. Challenger2가 step 호출 시도 → **거부됨**
4. 슬래싱 실행
5. Challenger1만 보상을 받는지 검증

**검증 항목**:
- ✅ Challenger1의 step 호출 성공
- ✅ Challenger2의 step 호출 거부 ("Already countered")
- ✅ Challenger1만 보상을 받음
- ✅ Challenger2는 보상을 받지 못함

#### 11. test_Slashing_InvalidGameStates
**목적**: 잘못된 Dispute Game 상태로 슬래싱 방지

**시나리오 A - Unresolved Game**:
1. Candidate 등록
2. 게임 생성 및 step 호출
3. **resolve 호출 없이** 슬래싱 시도
4. 슬래싱이 거부되는지 확인

**시나리오 B - DEFENDER_WINS**:
1. Candidate 등록
2. 게임 생성 (step 호출 없음)
3. resolve 호출 → DEFENDER_WINS 상태
4. 슬래싱 시도 → **거부됨**

**검증 항목**:
- ✅ Unresolved 게임으로 슬래싱 불가
- ✅ DEFENDER_WINS 게임으로 슬래싱 불가
- ✅ CHALLENGER_WINS 게임만 슬래싱 가능

#### 12. test_Slashing_UnauthorizedDepositManagerAccess
**목적**: 권한 없는 DepositManager.slash 호출 차단

**시나리오**:
1. Candidate 등록
2. 일반 사용자(attacker)가 직접 DepositManager.slash 호출 시도
3. 호출이 거부되는지 확인
4. 스테이크가 변경되지 않았는지 확인

**검증 항목**:
- ✅ 일반 사용자의 slash 호출 거부
- ✅ "not layer2Manager" 에러 발생
- ✅ 스테이크가 변경되지 않음

#### 13. test_Slashing_UnauthorizedSeigManagerAccess
**목적**: 권한 없는 SeigManager.onSlash 호출 차단

**시나리오**:
1. Candidate 등록
2. 일반 사용자(attacker)가 직접 SeigManager.onSlash 호출 시도
3. 호출이 거부되는지 확인
4. 스테이크가 변경되지 않았는지 확인

**검증 항목**:
- ✅ 일반 사용자의 onSlash 호출 거부
- ✅ "not onlyDepositManager" 에러 발생
- ✅ 스테이크가 변경되지 않음

---

### 엣지 케이스 테스트 (4개)

#### 14. test_Slashing_MultipleOperators_Independence
**목적**: 여러 Operator의 슬래싱 독립성

**시나리오**:
1. Operator1과 Operator2 각각 등록
2. Operator1만 슬래싱 실행
3. Operator2는 영향을 받지 않는지 확인

**검증 항목**:
- ✅ Operator1의 스테이크 = 0
- ✅ Operator2의 스테이크 = 초기값 유지
- ✅ 슬래싱이 독립적으로 작동함

#### 15. test_Slashing_ReRegistrationAfterSlashing
**목적**: 슬래싱 후 재등록 가능 여부 및 시뇨리지 획득

**시나리오**:
1. Candidate 등록 및 슬래싱
2. 새로운 Rollup Config로 재등록 (5000 TON)
3. 재등록 성공 확인
4. 시간 경과 후 시뇨리지 획득 확인

**검증 항목**:
- ✅ 슬래싱된 오퍼레이터가 재등록 가능
- ✅ 재등록 시 5000 TON 스테이킹 성공
- ✅ 재등록 후 시뇨리지 획득 가능 (환경에 따라)

#### 16. test_Slashing_AfterPartialWithdrawal
**목적**: 부분 출금 후 슬래싱

**시나리오**:
1. Candidate 등록
2. 부분 출금 시도 (구현 여부에 따라)
3. 슬래싱 실행
4. 남은 스테이크가 모두 슬래싱되는지 확인

**검증 항목**:
- ✅ 부분 출금 기능 확인 (구현된 경우)
- ✅ 남은 스테이크가 모두 슬래싱됨
- ✅ 최종 스테이크 = 0

#### 17. test_Slashing_EventEmission
**목적**: 슬래싱 이벤트 발생 검증

**시나리오**:
1. Candidate 등록
2. 슬래싱 실행
3. 이벤트가 올바르게 발생하는지 확인

**검증 항목**:
- ✅ 슬래싱 완료
- ✅ 이벤트 발생 (트랜잭션 로그 확인 필요)

---

## 테스트 실행 방법

### 1. 전체 테스트 실행

```bash
# 기본 실행
forge test --match-path test/Slashing/SlashingTest.t.sol

# 상세 로그 출력 (-vv)
forge test --match-path test/Slashing/SlashingTest.t.sol -vv

# 매우 상세한 로그 출력 (-vvvv)
forge test --match-path test/Slashing/SlashingTest.t.sol -vvvv
```

### 2. 특정 테스트만 실행

```bash
# 특정 테스트 함수 실행
forge test --match-path test/Slashing/SlashingTest.t.sol --match-test test_CandidateRegistrationAndStaking -vv

# 패턴 매칭으로 여러 테스트 실행
forge test --match-path test/Slashing/SlashingTest.t.sol --match-test "test_Slashing_Custom" -vv
```

### 3. 가스 리포트 포함

```bash
# 가스 사용량 리포트
forge test --match-path test/Slashing/SlashingTest.t.sol --gas-report

# 특정 컨트랙트의 가스 리포트
forge test --match-path test/Slashing/SlashingTest.t.sol --gas-report --match-contract SlashingTest
```

### 4. 커버리지 분석

```bash
# 코드 커버리지 생성
forge coverage --match-path test/Slashing/SlashingTest.t.sol

# 커버리지 리포트 (lcov 형식)
forge coverage --match-path test/Slashing/SlashingTest.t.sol --report lcov

# HTML 리포트 생성
genhtml lcov.info --branch-coverage --output-dir coverage
```

### 5. 디버깅

```bash
# 특정 테스트 디버깅
forge test --match-path test/Slashing/SlashingTest.t.sol --match-test test_SlashingAndReward --debug

# 트레이스 출력
forge test --match-path test/Slashing/SlashingTest.t.sol -vvvvv
```

### 6. 실패한 테스트만 재실행

```bash
# 실패한 테스트 재실행
forge test --rerun
```

---

## 테스트 결과 분석

### 성공적인 테스트 실행 예시

```
Ran 1 test suite in 298.53ms (18.64ms CPU time): 17 tests passed, 0 failed, 0 skipped (17 total tests)

[PASS] test_CandidateRegistrationAndStaking() (gas: 5221883)
[PASS] test_SlashingAndReward() (gas: 7468180)
[PASS] test_Slashing_AfterPartialWithdrawal() (gas: 7439371)
[PASS] test_Slashing_BelowMinimumStake() (gas: 7449124)
[PASS] test_Slashing_CustomRewardRate_50Percent() (gas: 7458371)
[PASS] test_Slashing_EventEmission() (gas: 7438471)
[PASS] test_Slashing_FullRewardRate_100Percent() (gas: 7437064)
[PASS] test_Slashing_InvalidGameStates() (gas: 8283603)
[PASS] test_Slashing_MultipleChallengers_FirstWins() (gas: 7432528)
[PASS] test_Slashing_MultipleOperators_Independence() (gas: 12411120)
[PASS] test_Slashing_PreventDoubleSlashing() (gas: 7436195)
[PASS] test_Slashing_ReRegistrationAfterSlashing() (gas: 12527524)
[PASS] test_Slashing_UnauthorizedDepositManagerAccess() (gas: 5231404)
[PASS] test_Slashing_UnauthorizedSeigManagerAccess() (gas: 5231261)
[PASS] test_Slashing_WithSeigniorage_BurnsAll() (gas: 7580187)
[PASS] test_Slashing_WithUnreceivedSeigniorage() (gas: 7453408)
[PASS] test_Slashing_ZeroRewardRate_AllBurned() (gas: 7405081)

Suite result: ok. 17 passed; 0 failed; 0 skipped
```

### 가스 사용량 분석

| 테스트 | 가스 사용량 | 카테고리 |
|--------|------------|----------|
| test_CandidateRegistrationAndStaking | 5,221,883 | 기본 |
| test_SlashingAndReward | 7,468,180 | 기본 |
| test_Slashing_CustomRewardRate_50Percent | 7,458,371 | 보상 비율 |
| test_Slashing_FullRewardRate_100Percent | 7,437,064 | 보상 비율 |
| test_Slashing_ZeroRewardRate_AllBurned | 7,405,081 | 보상 비율 |
| test_Slashing_WithSeigniorage_BurnsAll | 7,580,187 | 시뇨리지 |
| test_Slashing_WithUnreceivedSeigniorage | 7,453,408 | 시뇨리지 |
| test_Slashing_MultipleOperators_Independence | 12,411,120 | 엣지 케이스 |
| test_Slashing_ReRegistrationAfterSlashing | 12,527,524 | 엣지 케이스 |
| test_Slashing_InvalidGameStates | 8,283,603 | 보안 |

**평균 가스 사용량**: ~7.8M gas  
**최대 가스 사용량**: 12.5M gas (재등록 테스트)  
**최소 가스 사용량**: 5.2M gas (기본 등록)

### 테스트 커버리지

```
| File                                    | % Lines        | % Statements   | % Branches    | % Funcs       |
|-----------------------------------------|----------------|----------------|---------------|---------------|
| Layer2Manager_Slashing.sol              | 100.00% (25/25)| 100.00% (30/30)| 100.00% (8/8) | 100.00% (2/2) |
| DepositManager_Slashing.sol             | 100.00% (18/18)| 100.00% (22/22)| 100.00% (6/6) | 100.00% (2/2) |
| SeigManager_Slashing.sol                | 100.00% (15/15)| 100.00% (18/18)| 100.00% (4/4) | 100.00% (1/1) |
```

---

## 문제 해결

### 일반적인 문제

#### 1. 컴파일 에러: "Stack too deep"
**해결책**: `foundry.toml`에서 `via_ir = true` 설정 확인

```toml
[profile.default]
via_ir = true
optimizer = true
optimizer_runs = 100
```

#### 2. ABI 파일 접근 에러
**해결책**: `foundry.toml`에 파일 시스템 권한 추가

```toml
fs_permissions = [{ access = "read", path = "./abis" }]
```

### 디버깅 팁

1. **상세 로그 확인**: `-vvvv` 플래그 사용
2. **특정 함수 트레이스**: `forge test --debug` 사용
3. **가스 사용량 확인**: `--gas-report` 플래그 사용
4. **이벤트 확인**: 테스트 로그에서 `emit` 이벤트 검색

---

## 참고 자료

### 관련 문서
- [슬래싱 메커니즘 스펙](../specs-kr/09-slashing-mechanism.md)
- [Foundry 공식 문서](https://book.getfoundry.sh/)
- [Solidity 테스트 가이드](https://docs.soliditylang.org/en/latest/testing.html)

### 관련 컨트랙트
- `Layer2Manager_Slashing.sol`: 슬래싱 실행 로직
- `DepositManager_Slashing.sol`: 스테이크 소각 및 보상 분배
- `SeigManager_Slashing.sol`: 시뇨리지 소각 처리
- `MockFaultDisputeGame2.sol`: Dispute Game 시뮬레이션

