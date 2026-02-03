# TON Staking V3 테스트 코드 분석

이 문서는 ton-staking-v2 프로젝트의 V3 테스트 코드 구조와 패턴을 분석합니다.
Delegate Staking 서비스 개발 시 참고할 수 있는 테스트 작성 가이드입니다.

---

## 1. 테스트 디렉토리 구조

```
test/v3/
├── helpers/                    # 테스트 헬퍼 및 Mock 컨트랙트
│   └── V3TestMocks.sol        # MockDAOCommitteeProxy 등 공유 Mock
│
├── invariants/                 # 불변 속성(Invariant) 테스트
│   ├── CoinageInvariants.t.sol      # 코이니지 불변 속성
│   ├── EligibilityInvariants.t.sol  # 자격 불변 속성
│   └── SeigniorageInvariants.t.sol  # 시뇨리지 보존 법칙
│
├── scenarios/                  # 시나리오(E2E) 테스트
│   ├── MigrationScenarios.t.sol     # V2→V3 마이그레이션
│   ├── SequencerJourney.t.sol       # 시퀀서 전체 여정
│   ├── V3ScenarioReal.t.sol         # V3 실제 시나리오
│   └── ValidatorJourney.t.sol       # 검증자 전체 여정
│
├── v2mode/                     # V2 모드 호환성 테스트
│   ├── V2Functions.t.sol            # V2 함수 동작 테스트
│   ├── V2ModeTestBase.sol           # V2 테스트 베이스 클래스
│   └── V2V3ModeSwitching.t.sol      # V2/V3 모드 전환
│
└── v3mode/                     # V3 모드 단위 테스트
    ├── DepositManagerV1_2Real.t.sol     # 예치 관리자
    ├── L1BridgeRegistryV1_2Real.t.sol   # 브릿지 레지스트리
    ├── Layer2ManagerV1_2Real.t.sol      # Layer2 관리자
    ├── MultiL2SeigniorageDistribution.t.sol  # 다중 L2 시뇨리지
    ├── RAT.t.sol                        # RAT 테스트
    ├── RATSeigManagerIntegration.t.sol  # RAT-SeigManager 통합
    ├── SecurityPermissions.t.sol        # 보안 권한
    ├── SeigManagerV1_4Real.t.sol        # SeigManager 핵심
    ├── SeigniorageAccuracy.t.sol        # 시뇨리지 정확도
    ├── SeigniorageFormulaValidation.t.sol  # 공식 검증
    ├── ValidatorRewardV1.t.sol          # 검증자 보상
    └── ValidatorWithdrawalRestriction.t.sol  # 출금 제한
```

---

## 2. 테스트 베이스 클래스 계층

### 2.1 DeployV3Full (script/DeployV3Full.s.sol)

**역할**: 전체 시스템 배포 스크립트이자 테스트 베이스

```solidity
contract DeployV3Full is Script {
    // 배포된 컨트랙트 주소들
    address public ton;
    address public wton;
    address public seigManagerProxy;
    address public depositManagerProxy;
    address public layer2ManagerProxy;
    address public ratProxy;
    address public validatorPoolProxy;

    // 배포 단계별 함수
    function _deployTokens() internal { ... }
    function _deployCoinageInfrastructure(address deployer) internal { ... }
    function _deployLayer2Registry(address deployer) internal { ... }
    function _deployManagerProxies() internal { ... }
    function _deployManagerImplementations() internal { ... }
    function _initializeManagers(address deployer) internal { ... }
    function _setupMinterPermissions() internal { ... }
    function _deployOperatorManagerFactory(address deployer) internal { ... }
    function _deployV3Contracts(address deployer) internal { ... }
    function _setupCrossReferences(address deployer) internal { ... }

    // 테스트용 헬퍼 함수
    function _getStake(address layer2, address account) internal view returns (uint256);
    function _setV3ParametersForTest() internal;
}
```

**핵심 포인트**:
- `_getProxyAdmin()` 오버라이드로 TransparentUpgradeableProxy admin 분리
- `_setupSeigManagerV3AllTestSelectors()`로 V3 함수 selector 등록

### 2.2 V2ModeTestBase (test/v3/v2mode/V2ModeTestBase.sol)

**역할**: V2 모드 테스트를 위한 확장 베이스 클래스

```solidity
abstract contract V2ModeTestBase is Test, DeployV3Full {
    // 컨트랙트 참조 (캐스팅된 버전)
    SeigManagerV3_1 public seigManager;
    DepositManagerV3 public depositManager;
    Layer2Registry public layer2Registry;

    // Mock 인프라
    SimpleMockSystemConfig public mockSystemConfig;
    address public mockLayer2;
    address public mockPortal;
    address public operatorManager;

    // 테스트 계정
    address public operator1 = address(0x1001);
    address public validator1 = address(0x3001);

    // 상수
    uint256 constant RAY = 1e27;
    uint256 constant INITIAL_WTON = 10000 * RAY;
    uint256 constant BRIDGED_TON_AMOUNT = 10000 * 1e18;

    // 셋업 함수
    function _baseSetUp() internal;
    function _setupMockSystemConfig() internal;
    function _deployDAO() internal;

    // Layer2 등록 헬퍼
    function _registerMockLayer2() internal;
    function _registerMockLayer2WithOperatorStake() internal;
    function _registerMockLayer2WithOperatorStakeAndInit() internal;
    function _registerMockLayer2Type2() internal;

    // 시뇨리지 헬퍼
    function _initializeLayer2Seigniorage() internal;
    function _updateSeigniorage() internal returns (bool);
}
```

**핵심 포인트**:
- `_setupCrossReferences()` 오버라이드로 DAO 설정 추가
- Mock Optimism 인프라 (SystemConfig, Portal, Bridge) 설정
- Layer2 등록 시 TYPE 2/3 구분

---

## 3. 테스트 패턴 및 명명 규칙

### 3.1 테스트 함수 명명 규칙

```solidity
// 형식: test_<카테고리>_<설명>()
// 또는: testFuzz_<카테고리>_<설명>()

// 예시:
function test_SM001_hyperbolicSaturation_zero() public view { ... }
function test_SM002_hyperbolicSaturation_halfPoint() public { ... }
function testFuzz_SM005_hyperbolicSaturation_bounded(uint256 x, uint256 L) public { ... }
function test_INT012_requiredStake_DSequencerDominant() public { ... }
function test_RAT001_registerValidator_success() public { ... }
function test_SCENSEQ001_newSequencer_fullJourney() public { ... }
function test_INV001_v3_seigniorageConservation() public { ... }
```

**카테고리 접두사**:
| 접두사 | 의미 | 예시 |
|--------|------|------|
| SM | SeigManager | SM001, SM020 |
| INT | Integration | INT012, INT030 |
| RAT | RAT 컨트랙트 | RAT001, RAT020 |
| SCENSEQ | Sequencer Scenario | SCENSEQ001 |
| SCENVAL | Validator Scenario | SCENVAL001 |
| INV | Invariant | INV001 |
| EDGE | Edge Case | EDGE010 |
| E2E | End-to-End | E2E014 |

### 3.2 테스트 구조 패턴

```solidity
/// @notice 테스트 설명
/// @dev 상세 설명 및 검증 항목
function test_XXX_description() public {
    // ============================================
    // 1. 준비 단계 (Arrange)
    // ============================================
    _setupLayer2AndMigrateV3();

    // ============================================
    // 2. 실행 단계 (Act)
    // ============================================
    uint256 result = seigManager.someFunction();

    // ============================================
    // 3. 검증 단계 (Assert)
    // ============================================
    assertEq(result, expected, "Should be equal");

    // 4. 로그 출력 (선택적)
    emit log_named_decimal_uint("Result", result / 1e27, 27);
}
```

---

## 4. Mock 컨트랙트 패턴

### 4.1 MockDAOCommitteeProxy

```solidity
contract MockDAOCommitteeProxy is StorageStateCommittee, AccessControl {
    address internal _implementation;
    bool public pauseProxy;

    constructor(address _ton) {
        ton = _ton;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function upgradeTo(address impl) external onlyAdmin { ... }

    fallback() external payable {
        // delegatecall to implementation
    }
}
```

### 4.2 SimpleMockSystemConfig

Optimism SystemConfig Mock:

```solidity
contract SimpleMockSystemConfig {
    function setL1StandardBridge(address bridge) external;
    function setOptimismPortal(address portal) external;
    function setDisputeGameFactory(address factory) external;
    function setUnsafeBlockSigner(address sequencer) external;
}
```

### 4.3 MockFaultDisputeGame

RAT 테스트용 Mock:

```solidity
contract MockFaultDisputeGame {
    address public systemConfig;

    constructor(address _systemConfig) {
        systemConfig = _systemConfig;
    }
}
```

---

## 5. 주요 테스트 유형 분석

### 5.1 단위 테스트 (v3mode/)

**SeigManagerV1_4Real.t.sol 예시**:

```solidity
contract SeigManagerV3_1RealTest is Test, DeployV3Full {
    function setUp() public {
        admin = address(0x9999);  // Proxy admin
        owner = address(this);    // Business logic owner
        proxyAdmin = admin;

        vm.startPrank(owner);
        // 전체 시스템 배포
        _deployTokens();
        _deployCoinageInfrastructure(owner);
        // ... 나머지 배포

        // V3 함수 selector 등록
        _setupSeigManagerV3AllTestSelectors();

        // 컨트랙트 참조
        seigManager = SeigManagerV3_1(seigManagerProxy);
        vm.stopPrank();
    }

    // 쌍곡선 포화 함수 테스트
    function test_SM001_hyperbolicSaturation_zero() public view {
        uint256 y = seigManager.hyperbolicSaturation(0, 1000e27);
        assertEq(y, 0, "y(0) should be 0");
    }

    // Fuzz 테스트
    function testFuzz_SM005_hyperbolicSaturation_bounded(uint256 x, uint256 L) public {
        x = bound(x, 0, 1e32);
        L = bound(L, 1e18, 1e32);

        uint256 y = seigManager.hyperbolicSaturation(x, L);
        assertLe(y, L + 1e18, "y should not exceed L");
    }
}
```

**핵심 테스트 케이스**:
- `test_SM001~SM004`: 쌍곡선 포화 함수 (경계값, 단조성)
- `test_SM010~SM012`: 시퀀서 보상 계산
- `test_SM020~SM021`: 자격 검증 (eligible/ineligible)
- `test_SM022~SM023`: D_sequencer, θ×B_i 계산
- `test_INT012`: max(θ×B_i, D_sequencer) 공식

### 5.2 시나리오 테스트 (scenarios/)

**SequencerJourney.t.sol 예시**:

```solidity
contract SequencerJourneyTest is V2ModeTestBase {
    function setUp() public {
        _baseSetUp();

        // V3 파라미터 설정
        vm.startPrank(owner);
        seigManager.setDaoDistributionRatio(0.1e27);      // 10%
        seigManager.setMinStakingRatio(0.5e27);           // 50%
        seigManager.setValidatorDistributionRatio(0.2e27); // 20%
        seigManager.setHalfSaturationPoint(1000e27);
        seigManager.setMaxChallengers(3);
        seigManager.setMaxFraudProofCost(50e27);
        seigManager.setSequencerAdditionalReward(100e27);
        vm.stopPrank();
    }

    /// @notice 신규 시퀀서의 V3 참여 전체 플로우
    function test_SCENSEQ001_newSequencer_fullJourney() public {
        // 1. L2 등록 및 V3 마이그레이션
        _setupLayer2AndMigrateV3();

        // 2. 자격 조건 확인
        (bool eligible, uint256 required, uint256 actual) =
            seigManager.checkCurrentEligibility(mockLayer2);

        // 3. 자격 미달 시 추가 예치
        if (!eligible) {
            uint256 additionalStake = required - actual + 10e27;
            vm.startPrank(operator1);
            MockWTON(wton).approve(depositManagerProxy, additionalStake);
            DepositManagerV3(depositManagerProxy).deposit(mockLayer2, additionalStake);
            vm.stopPrank();
        }

        // 4. 시뇨리지 분배
        vm.roll(block.number + 100);
        _updateSeigniorage();

        // 5. V3 요소 검증
        uint256 effective = seigManager.getEffectiveBridgedTon(mockLayer2);
        assertGt(effective, 0, "effectiveBridgedTON should be set");
    }
}
```

### 5.3 불변 속성 테스트 (invariants/)

**SeigniorageInvariants.t.sol 예시**:

```solidity
contract SeigniorageInvariantsTest is V2ModeTestBase {
    /// @notice INV-001: 시뇨리지 총량 보존
    /// @dev DAO + 시퀀서 + 검증자 = 총 시뇨리지
    function test_INV001_v3_seigniorageConservation() public {
        // 1. V3 모드 설정
        _registerMockLayer2WithOperatorStakeAndInit();
        vm.prank(owner);
        seigManager.migrateToV3();

        // 2. 분배 전 잔액 기록
        uint256 daoBalanceBefore = MockWTON(wton).balanceOf(dao);
        uint256 validatorRewardBefore = MockWTON(wton).balanceOf(validatorPoolProxy);
        uint256 operatorStakeBefore = _getStake(mockLayer2, operator1);

        // 3. 시뇨리지 분배
        uint256 span = 100;
        vm.roll(block.number + span);
        _updateSeigniorage();

        // 4. 분배 후 측정
        uint256 daoIncrease = MockWTON(wton).balanceOf(dao) - daoBalanceBefore;
        uint256 validatorIncrease = MockWTON(wton).balanceOf(validatorPoolProxy) - validatorRewardBefore;
        uint256 sequencerIncrease = _getStake(mockLayer2, operator1) - operatorStakeBefore;

        // 5. 불변 속성 검증: 총합 = 예상 시뇨리지
        uint256 seigPerBlock = SeigManagerV1_2(seigManagerProxy).seigPerBlock();
        uint256 expectedTotal = seigPerBlock * span;
        uint256 actualTotal = daoIncrease + validatorIncrease + sequencerIncrease;

        assertApproxEqRel(actualTotal, expectedTotal, 0.001e18,
            "INV-001: Total seigniorage should be conserved");
    }
}
```

### 5.4 RAT 테스트

**RAT.t.sol 주요 테스트 케이스**:

```solidity
contract RATTest is Test, DeployV3Full {
    // 검증자 등록
    function test_RAT001_registerValidator_success() public {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        (uint256 collateral, uint32 index, bool isActive) =
            rat.getValidatorRegistration(validator1, address(mockSystemConfig));

        assertTrue(isActive);
        assertGt(collateral, 0);
    }

    // 최소 담보금 미달 시 등록 실패
    function test_RAT002_registerValidator_insufficientDeposit() public {
        address poorValidator = address(0x7777);
        _stakeForValidator(poorValidator, mockLayer2, 100 * RAY); // < minimumThreshold

        vm.prank(poorValidator);
        vm.expectRevert();
        rat.registerValidator(address(mockSystemConfig));
    }

    // 증거 제출 기한 초과
    function test_RAT031_submitEvidence_afterDeadline_reverts() public {
        vm.prank(validator1);
        rat.registerValidator(address(mockSystemConfig));

        vm.prank(factory);
        rat.triggerAttentionTest(address(mockGame1), ...);

        // deadline 초과
        vm.warp(block.timestamp + evidencePeriod + 1);

        vm.prank(validator1);
        vm.expectRevert();
        rat.submitEvidence(address(mockSystemConfig), batchIndex, "late");
    }

    // 상태 전이 테스트
    function test_RAT040_getAttentionTestStatus_evidencePeriod() public { ... }
    function test_RAT041_getAttentionTestStatus_challengePeriod() public { ... }
    function test_RAT042_getAttentionTestStatus_slashed() public { ... }
    function test_RAT043_getAttentionTestStatus_restoredByEvidence() public { ... }
}
```

---

## 6. 테스트 유틸리티 함수

### 6.1 스테이킹 조회

```solidity
// DeployV3Full에서 제공
function _getStake(address layer2, address account) internal view returns (uint256) {
    return SeigManagerV1_2(seigManagerProxy).stakeOf(layer2, account);
}

// V2ModeTestBase에서 제공
function _getOperatorStake(address layer2) internal view returns (uint256) {
    address operatorAddr = ILayer2(layer2).operator();
    return _getStake(layer2, operatorAddr);
}
```

### 6.2 검증자 스테이킹 헬퍼

```solidity
function _stakeForValidator(address validator, address layer2, uint256 amount) internal {
    vm.startPrank(validator);
    MockWTON(wton).mint(validator, amount);
    MockWTON(wton).approve(depositManagerProxy, amount);
    depositManager.deposit(layer2, validator, amount);
    vm.stopPrank();
}
```

### 6.3 Layer2 등록 플로우

```solidity
function _registerMockLayer2WithOperatorStakeAndInit() internal {
    // 1. L1BridgeRegistry에 rollupConfig 등록
    l1BridgeRegistry.registerRollupConfig(
        address(mockSystemConfig),
        3, // TYPE_3
        mockL2TON,
        "TestL2"
    );

    // 2. Portal에 TON 전송 (브릿지된 TON 시뮬레이션)
    MockTON(ton).mint(mockPortal, BRIDGED_TON_AMOUNT);

    // 3. operator가 Layer2Manager에 등록
    vm.startPrank(operator1);
    MockWTON(wton).approve(layer2ManagerProxy, operatorDeposit);
    Layer2ManagerV3(layer2ManagerProxy).registerCandidateAddOn(
        address(mockSystemConfig),
        operatorDeposit,
        false, // WTON
        "TestL2"
    );
    vm.stopPrank();

    // 4. 생성된 Layer2 주소 저장
    mockLayer2 = layer2Manager.getLayer2BySystemConfig(address(mockSystemConfig));

    // 5. 첫 번째 updateSeigniorage (startBlock 설정)
    vm.roll(block.number + 1);
    ICandidate(mockLayer2).updateSeigniorage();
}
```

---

## 7. Foundry 테스트 기능 활용

### 7.1 vm cheatcodes

```solidity
// 계정 전환
vm.prank(operator1);
vm.startPrank(owner);
vm.stopPrank();

// 블록 조작
vm.roll(block.number + 100);  // 블록 번호 증가
vm.warp(block.timestamp + 1 hours);  // 타임스탬프 증가

// revert 예상
vm.expectRevert();
vm.expectRevert(CustomError.selector);
vm.expectRevert("error message");

// 테스트 스킵
vm.skip(true);

// 범위 제한 (fuzz 테스트)
x = bound(x, 0, 1e32);
```

### 7.2 Assertion 함수

```solidity
// 기본 assertion
assertEq(actual, expected, "message");
assertTrue(condition, "message");
assertFalse(condition, "message");
assertGt(a, b, "message");
assertLt(a, b, "message");
assertGe(a, b, "message");
assertLe(a, b, "message");

// 근사값 비교
assertApproxEqAbs(actual, expected, tolerance, "message");
assertApproxEqRel(actual, expected, 0.01e18, "message");  // 1% 허용
```

### 7.3 로그 출력

```solidity
emit log_string("Step 1: Setup");
emit log_named_uint("Value", value);
emit log_named_decimal_uint("WTON Amount", amount / 1e27, 27);
emit log_named_address("Contract", contractAddr);
```

---

## 8. Delegate Staking 테스트 작성 가이드

### 8.1 필요한 테스트 유형

1. **단위 테스트**: 개별 함수 동작
   - stake(), unstake(), claimRewards()
   - accRewardPerShare 계산
   - rewardDebt 업데이트

2. **통합 테스트**: SeigManager와 연동
   - 시뇨리지 수령 후 분배
   - operatorOfLayer[layer2] 보상 처리

3. **시나리오 테스트**: 사용자 여정
   - 신규 사용자 스테이킹 → 보상 누적 → 클레임
   - 추가 스테이킹 시 보상 계산
   - 언스테이킹 시 보상 정산

4. **불변 속성 테스트**:
   - 총 스테이킹 = 개별 스테이킹 합
   - 분배된 보상 = 받은 시뇨리지

### 8.2 테스트 베이스 클래스 예시

```solidity
// test/DelegateStakingTestBase.sol
abstract contract DelegateStakingTestBase is Test, DeployV3Full {
    DelegateStaking public delegateStaking;

    address public user1 = address(0x1001);
    address public user2 = address(0x1002);

    function _baseSetUp() internal {
        // DeployV3Full 배포
        vm.startPrank(owner);
        _deployTokens();
        // ... 전체 시스템 배포

        // DelegateStaking 배포
        delegateStaking = new DelegateStaking();
        delegateStaking.initialize(
            seigManagerProxy,
            layer2ManagerProxy,
            wton
        );

        // 사용자에게 WTON 지급
        MockWTON(wton).mint(user1, 10000e27);
        MockWTON(wton).mint(user2, 10000e27);
        vm.stopPrank();
    }

    function _stake(address user, address layer2, uint256 amount) internal {
        vm.startPrank(user);
        MockWTON(wton).approve(address(delegateStaking), amount);
        delegateStaking.stake(layer2, amount);
        vm.stopPrank();
    }

    function _simulateReward(uint256 amount) internal {
        // operatorOfLayer[layer2]로 보상 전송 시뮬레이션
        // 실제로는 SeigManager에서 transferL2Seigniorage() 호출됨
    }
}
```

### 8.3 테스트 케이스 체크리스트

```
□ DS-001: stake() 기본 동작
□ DS-002: stake() 최소 금액 미달 시 revert
□ DS-003: unstake() 기본 동작
□ DS-004: unstake() 잔액 초과 시 revert
□ DS-005: claimRewards() 보상 수령
□ DS-006: claimRewards() 보상 없을 때 처리
□ DS-010: accRewardPerShare 업데이트
□ DS-011: rewardDebt 계산 정확성
□ DS-020: 다수 사용자 스테이킹 시 비율 분배
□ DS-021: 사용자 추가 스테이킹 시 기존 보상 처리
□ INV-DS-001: 총 스테이킹 보존
□ INV-DS-002: 보상 분배 총합 보존
□ SCEN-DS-001: 신규 사용자 전체 플로우
□ SCEN-DS-002: 다중 사용자 경쟁 시나리오
```

---

## 9. 테스트 실행 명령어

```bash
# 전체 테스트 실행
forge test

# V3 테스트만 실행
forge test --match-path "test/v3/**"

# 특정 테스트 파일 실행
forge test --match-path "test/v3/v3mode/SeigManagerV1_4Real.t.sol"

# 특정 테스트 함수 실행
forge test --match-test "test_SM001"

# Fuzz 테스트 실행 (더 많은 실행)
forge test --match-test "testFuzz" --fuzz-runs 1000

# 상세 로그 출력
forge test -vvv

# 가스 리포트
forge test --gas-report

# 커버리지
forge coverage
```

---

## 10. 참고 자료

- **Foundry Book**: https://book.getfoundry.sh/
- **forge-std**: https://github.com/foundry-rs/forge-std
- **테스트 패턴**: https://book.getfoundry.sh/forge/tests
- **Fuzz 테스트**: https://book.getfoundry.sh/forge/fuzz-testing
- **불변 테스트**: https://book.getfoundry.sh/forge/invariant-testing
