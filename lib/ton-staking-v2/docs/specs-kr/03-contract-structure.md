# TON Staking V3 컨트랙트 구조

## 1. 디렉토리 구조

```
src/
├── stake/                              # 스테이킹 관련
│   ├── managers/
│   │   ├── SeigManagerV1_2.sol                # V1.2 구현체 (기본 프록시 구현체)
│   │   ├── SeigManagerV3_1.sol                # V3.1 구현체 (V3 핵심) 🆕
│   │   ├── SeigManagerV3_2.sol                # V3.2 구현체 (V2 호환 레이어) 🆕
│   │   ├── SeigManagerStorage.sol             # 기본 스토리지
│   │   ├── SeigManagerV1_1Storage.sol         # V1.1 스토리지
│   │   ├── SeigManagerV1_3Storage.sol         # V1.3 스토리지
│   │   ├── SeigManagerV1_4Storage.sol         # V1.4 스토리지 (V3) 🆕
│   │   ├── SeigManagerProxy.sol               # 프록시
│   │   │
│   │   ├── DepositManagerV3.sol               # V3 구현체 (V3 콜백) 🆕
│   │   ├── DepositManagerStorage.sol          # 기본 스토리지
│   │   ├── DepositManagerV1_1Storage.sol      # V1.1 스토리지
│   │   └── DepositManagerProxy.sol            # 프록시
│   │
│   ├── tokens/                            # 코이니지 토큰
│   │   ├── RefactorCoinageSnapshot.sol        # 코이니지 구현체
│   │   ├── RefactorCoinageSnapshotProxy.sol   # 프록시
│   │   ├── RefactorCoinageSnapshotStorage.sol # 스토리지
│   │   ├── AutoRefactorCoinage.sol            # 자동 리팩터 코이니지
│   │   ├── AutoRefactorCoinageProxy.sol       # 프록시
│   │   └── AutoRefactorCoinageStorage.sol     # 스토리지
│   │
│   ├── factory/                           # 팩토리
│   │   ├── CoinageFactory.sol                 # 코이니지 생성 팩토리
│   │   └── AutoRefactorCoinageFactory.sol     # 자동 리팩터 코이니지 팩토리
│   │
│   ├── Layer2Registry.sol                 # L2 레지스트리 (레거시)
│   ├── Layer2RegistryProxy.sol            # 프록시
│   ├── Layer2RegistryStorage.sol          # 스토리지
│   │
│   └── interfaces/
│       ├── ISeigManager.sol                   # 기본 인터페이스
│       ├── ISeigManagerV3.sol                 # V3 인터페이스 🆕
│       ├── IDepositManager.sol                # DepositManager 인터페이스
│       ├── ITON.sol                           # TON 인터페이스
│       ├── IWTON.sol                          # WTON 인터페이스
│       ├── IOnApprove.sol                     # approveAndCall 콜백
│       └── IAutoCoinageSnapshot.sol           # 코이니지 스냅샷
│
├── layer2/                             # L2 관리
│   ├── Layer2ManagerV3.sol                    # L2 관리 (V3) 🆕
│   ├── Layer2ManagerStorage.sol               # 기본 스토리지
│   ├── Layer2ManagerV1_2Storage.sol           # V1.2 스토리지 (V3에서 사용) 🆕
│   ├── Layer2ManagerProxy.sol                 # 프록시
│   │
│   ├── L1BridgeRegistryV1_2.sol               # 브릿지 레지스트리 (TYPE 3) 🆕
│   ├── L1BridgeRegistryStorage.sol            # 기본 스토리지
│   ├── L1BridgeRegistryV1_2Storage.sol        # V1.2 스토리지 🆕
│   ├── L1BridgeRegistryProxy.sol              # 프록시
│   │
│   ├── OperatorManagerV1_2.sol                # 오퍼레이터 매니저 (TYPE 3) 🆕
│   ├── OperatorManagerStorage.sol             # 스토리지
│   ├── OperatorManagerProxy.sol               # 프록시 (ERC1967 기반)
│   │
│   ├── LegacySystemConfig.sol                 # 레거시 SystemConfig 래퍼
│   ├── LegacySystemConfigProxy.sol            # 프록시
│   ├── LegacySystemConfigStorage.sol          # 스토리지
│   │
│   ├── factory/
│   │   └── OperatorManagerFactory.sol         # 오퍼레이터 팩토리
│   │
│   └── interfaces/
│       ├── ILayer2Manager.sol                 # Layer2Manager 인터페이스
│       ├── IL1BridgeRegistry.sol              # L1BridgeRegistry 인터페이스
│       ├── IOperatorManagerFactory.sol        # 팩토리 인터페이스
│       ├── IOperator.sol                      # 오퍼레이터 인터페이스
│       ├── IOptimismPortal.sol                # OptimismPortal 인터페이스
│       ├── IOptimismSystemConfig.sol          # SystemConfig 인터페이스
│       ├── IRollupConfig.sol                  # RollupConfig 인터페이스
│       ├── IL1Bridge.sol                      # L1Bridge 인터페이스
│       └── IStandardBridge.sol                # StandardBridge 인터페이스
│
├── validator/                          # 검증자 시스템 (V3 신규) 🆕
│   ├── RAT.sol                                # 검증자 등록/RAT/슬래싱
│   ├── RATStorage.sol                         # 스토리지
│   ├── RATProxy.sol                           # 프록시 (TransparentUpgradeableProxy)
│   ├── RATTypes.sol                           # 타입 정의 🆕
│   ├── IRAT.sol                               # 인터페이스
│   │
│   ├── ValidatorRewardV1.sol                  # 검증자 보상 분배
│   ├── ValidatorRewardStorage.sol             # 스토리지
│   ├── ValidatorRewardProxy.sol               # 프록시 (TransparentUpgradeableProxy)
│   └── IValidatorReward.sol                   # 인터페이스
│
│
├── dao/                                # DAO/거버넌스
│   ├── DAOCommittee_V1.sol                    # DAO 커미티 구현체
│   ├── DAOCommitteeOwner.sol                  # Owner 권한 관리
│   ├── StorageStateCommittee.sol              # 스토리지
│   ├── StorageStateCommitteeV2.sol            # V2 스토리지
│   │
│   ├── Candidate.sol                          # 후보자 컨트랙트
│   ├── CandidateProxy.sol                     # 프록시
│   ├── CandidateStorage.sol                   # 스토리지
│   │
│   ├── CandidateAddOnV1_1.sol                 # 후보자 애드온 (V1.1)
│   ├── CandidateAddOnProxy.sol                # 프록시
│   ├── CandidateAddOnStorage.sol              # 스토리지
│   ├── CandidateAddOnStorage1.sol             # 추가 스토리지
│   │
│   ├── factory/
│   │   ├── CandidateFactory.sol               # 후보자 팩토리
│   │   ├── CandidateFactoryProxy.sol          # 프록시
│   │   ├── CandidateFactoryStorage.sol        # 스토리지
│   │   ├── CandidateAddOnFactory.sol          # 애드온 팩토리
│   │   ├── CandidateAddOnFactoryProxy.sol     # 프록시
│   │   └── CandidateAddOnFactoryStorage.sol   # 스토리지
│   │
│   ├── lib/
│   │   ├── Agenda.sol                         # 의제 라이브러리
│   │   └── BytesLib.sol                       # 바이트 유틸리티
│   │
│   └── interfaces/
│       ├── ICoinage.sol                       # 코이니지 인터페이스
│       └── ICandidateAddOn.sol                # 애드온 인터페이스
│
├── proxy/                              # 프록시 관련
│   ├── Proxy.sol                              # 기본 프록시 (Selector Routing)
│   ├── ProxyStorage.sol                       # 프록시 스토리지
│   ├── ProxyStorage2.sol                      # 프록시 스토리지 V2
│   ├── ProxySeigManager.sol                   # SeigManager 전용 프록시
│   ├── ProxyLayer2Manager.sol                 # Layer2Manager 전용 프록시
│   ├── ProxyL1BridgeRegistry.sol              # L1BridgeRegistry 전용 프록시
│   ├── ProxyCoinage.sol                       # 코이니지 전용 프록시
│   └── DAOCommitteeProxy2.sol                 # DAO 커미티 프록시
│
├── common/                             # 공통 유틸리티
│   ├── AccessibleCommon.sol                   # 기본 접근 제어
│   ├── AuthRole.sol                           # 역할 정의
│   ├── AuthControlSeigManager.sol             # SeigManager 권한 관리
│   ├── AuthControlCoinage.sol                 # 코이니지 권한 관리
│   ├── AuthControlLayer2Manager.sol           # Layer2Manager 권한 관리
│   └── AuthControlL1BridgeRegistry.sol        # L1BridgeRegistry 권한 관리
│
├── accessControl/                      # OpenZeppelin 접근 제어 (로컬 복사본)
│   ├── AccessControl.sol                      # 접근 제어
│   ├── Context.sol                            # 컨텍스트
│   ├── Address.sol                            # 주소 유틸리티
│   ├── EnumerableSet.sol                      # 열거 가능 집합
│   ├── ERC165A.sol                            # ERC165 인터페이스 감지
│   └── IERC165.sol                            # 인터페이스
│
└── mocks/                              # 테스트용 목업
    ├── MockSystemConfig.sol                   # SystemConfig 목업
    ├── MockSystemConfigFactory.sol            # 팩토리 목업
    └── InvalidCandidateAddOn.sol              # 잘못된 애드온 (테스트용)
```

---

## 2. 핵심 컨트랙트 상세

### 2.1 SeigManagerV3_1

시뇨리지 계산 및 분배의 핵심 컨트랙트입니다.

```solidity
contract SeigManagerV3_1 is
    ProxyStorage,              // 프록시 기본 스토리지
    AuthControlSeigManager,    // 권한 관리
    SeigManagerStorage,        // V1 스토리지
    SeigManagerV1_1Storage,    // V1.1 스토리지
    DSMath,                    // RAY 수학 라이브러리
    SeigManagerV1_3Storage,    // V1.3 스토리지
    SeigManagerV1_4Storage,    // V3 스토리지
    ISeigManagerV3             // V3 인터페이스
{
    // ...
}
```

**V3 핵심 기능**:
- 쌍곡선 포화 함수 (`hyperbolicSaturation`)
- Bridged TON 기반 시뇨리지 계산
- 자격 조건 확인 (`checkCurrentEligibility`)
- 검증자 보상 분배

### 2.2 DepositManagerV3

TON/WTON 스테이킹을 관리합니다.

```solidity
contract DepositManagerV3 is
    ProxyStorage,
    AccessibleCommon,
    DepositManagerStorage,
    DepositManagerV1_1Storage
{
    // ...
}
```

**핵심 기능**:
- `deposit()`: WTON 스테이킹
- `requestWithdrawal()`: 출금 요청
- `processRequest()`: 출금 처리
- `onApprove()`: TON.approveAndCall 콜백

### 2.3 Layer2ManagerV3

L2 등록 및 관리를 담당합니다.

```solidity
contract Layer2ManagerV3 is
    ProxyStorage,
    AccessibleCommon,
    Layer2ManagerStorage,
    Layer2ManagerV1_2Storage
{
    // ...
}
```

**핵심 기능**:
- `getBridgedTon()`: Bridged TON 조회
- `getLayer2BySystemConfig()`: SystemConfig → Layer2 조회
- `transferL2Seigniorage(layer2, amount)`: L2 시뇨리지를 Operator에게 전송
  - 호출자: SeigManager (`onlySeigManger`)
  - L2의 Operator(OperatorManager)에게 WTON 전송

### 2.4 L1BridgeRegistryV1_2

브릿지/포탈 등록 및 TVL 조회를 담당합니다. **V1_2는 V1_1의 모든 함수를 포함**하며, TYPE 3 (DisputeGame) 지원과 타입별 권한 관리 시스템을 제공합니다.

```solidity
contract L1BridgeRegistryV1_2 is
    ProxyStorage,
    AuthControlL1BridgeRegistry,
    L1BridgeRegistryStorage,
    L1BridgeRegistryV1_2Storage
{
    // V1_1 + V1_2 모든 함수 포함
}
```

**롤업 타입**:
- TYPE 1: Legacy (L1StandardBridge)
- TYPE 2: Optimism Bedrock (OptimismPortal)
- TYPE 3: Optimism Bedrock + DisputeGame (OptimismPortal + DisputeGameFactory) 🆕

**권한 계층**:
```
Owner (Admin, DEFAULT_ADMIN_ROLE)
├── setAddresses, setSeigniorageCommittee
├── addAdmin, removeAdmin
├── addManager, removeManager
└── 최고 권한 (시스템 초기 설정)

Manager (MANAGER_ROLE, Owner가 부여)
├── 모든 타입 등록/업그레이드 가능
├── setTypeRegistrant (타입별 등록자 설정)
├── upgradeToType3 (TYPE 1/2 → TYPE 3 업그레이드)
├── addRegistrant, removeRegistrant
└── L2 등록 관련 슈퍼 권한

SeigniorageCommittee (Owner가 지정)
├── rejectCandidateAddOn (시뇨리지 중지)
└── restoreCandidateAddOn (시뇨리지 복원)

Registrant (REGISTRANT_ROLE, Manager가 부여)
└── registerRollupConfig (TYPE 1, 2, 3 모두)

typeRegistrant[n] (Manager가 지정, 타입별 위임)
└── registerRollupConfigByType (TYPE n만)
```

**onlyOwner 함수**:
- `setAddresses(layer2Manager, seigManager, ton)`: 초기 설정
- `setSeigniorageCommittee(addr)`: SeigniorageCommittee 설정

**onlySeigniorageCommittee 함수**:
- `rejectCandidateAddOn(rollupConfig)`: 시뇨리지 발행 중지
- `restoreCandidateAddOn(rollupConfig, rejectedL2Deposit)`: 시뇨리지 발행 복원

**onlyRegistrant 함수**:
- `registerRollupConfig(rollupConfig, type, l2TON, name)`: 롤업 등록

**onlyManager 함수**:
- `setTypeRegistrant(type, addr)`: 타입별 등록 권한자 설정
- `upgradeToType3(rollupConfig)`: TYPE 1/2 → TYPE 3 업그레이드

**onlyTypeRegistrant 함수**:
- `registerRollupConfigByType(rollupConfig, type, l2TON, name)`: 타입별 권한 체크 등록

**View 함수**:
- `rollupType(rollupConfig)`: 롤업 타입 조회
- `l2TON(rollupConfig)`: L2 TON 주소 조회
- `getRollupInfo(rollupConfig)`: 롤업 정보 조회
- `isRejectedSeigs(rollupConfig)`: 시뇨리지 중지 여부
- `isRejectedL2Deposit(rollupConfig)`: L2 예치 중지 여부
- `layer2Tvl(rollupConfig)`: L2별 TVL 조회
- `availableForRegistration(rollupConfig, type)`: 등록 가능 여부

**스토리지 조회**:
- `disputeGameFactory(rollupConfig)`: DisputeGameFactory 등록 여부
- `rollupConfigWithDisputeGameFactory(factory)`: factory → rollupConfig 역조회
- `rollupConfigWithPortal(portal)`: portal → rollupConfig 역조회
- `typeRegistrant(type)`: 타입별 등록 권한자 조회

### 2.5 RAT (Randomized Attention Test)

검증자 등록, RAT 테스트, C_off 페널티를 관리합니다.

```solidity
contract RAT is
    ProxyStorage,
    RATStorage,
    IRAT
{
    // ...
}
```

**핵심 기능**:
- `registerValidator()`: 검증자 등록
- `triggerAttentionTest()`: RAT 트리거
- `submitEvidence()`: 증거 제출
- `resolveClaim()`: 챌린지 승리 시 담보금 복구
- `deactivateValidator()`: 검증자 탈퇴

### 2.6 ValidatorRewardV1

검증자 보상 분배를 담당합니다. O(1) 복잡도의 RewardPerValidator 패턴을 사용합니다.

```solidity
contract ValidatorRewardV1 is
    ValidatorRewardStorage,
    IValidatorReward
{
    // ...
}
```

**핵심 기능**:
- `distributeL2Rewards(systemConfig, amount)`: L2별 검증자 보상 분배 (O(1))
  - 호출자: SeigManager (`onlySeigManager`)
  - 호출 시점: `updateSeigniorage()` 실행 시 검증자 분배 비율(α · S_i) 만큼
  - 역할: `rewardPerValidator[systemConfig]`에 검증자당 보상 누적
  - 분배 공식: `v_j = (α · S_i) / |V_i|` (검증자당 보상)
  - 검증자 없음: 보상을 `seigManager.dao()`로 전송
- `claimAllRewards()`: 모든 L2 보상 동기화 후 청구
- `claimRewardsByL2s(address[])`: 특정 L2들만 동기화 후 청구 (가스 최적화)
- `registerValidatorToL2()`: 검증자 L2 등록 (RAT에서 호출)
- `syncValidatorReward()`: 검증자 비활성화 전 보상 동기화
- `resetValidatorDebt()`: 검증자 재활성화 시 debt 리셋
- `getClaimableRewards()`: 총 청구 가능 보상 조회 (미동기화 포함)

---

## 3. 스토리지 구조

### 3.1 SeigManagerV1_4Storage

```solidity
contract SeigManagerV1_4Storage {
    // V3 핵심 파라미터
    uint256 public daoDistributionRatio;      // d: DAO 분배 비율 (RAY)
    uint256 public minStakingRatio;           // θ: 최소 스테이킹 비율 (RAY)
    uint256 public validatorDistributionRatio; // α: 검증자 분배 비율 (RAY)
    uint256 public halfSaturationPoint;       // k: 반포화점 (RAY)

    // V3 상태
    bool public v3Migrated;                   // V3 모드 활성화 플래그
    uint256 public v3MigrationBlock;          // 마이그레이션 블록

    // V3 참조 주소
    address public validatorReward;           // ValidatorReward 컨트랙트
    address public ratContract;               // RAT 컨트랙트

    // Bridged TON 추적
    mapping(address => BridgedTONInfo) public bridgedTONInfo;
    uint256 public totalEffectiveBridgedTON;  // x: 전체 유효 Bridged TON

    struct BridgedTONInfo {
        uint256 currentBridgedTON;    // B_i: 현재 Bridged TON
        uint256 effectiveBridgedTON;  // B̃_i: 유효 Bridged TON (자격 없으면 0)
        uint256 initialDebt;          // 초기부채 (V2 패턴 동일)
        uint256 startBlock;           // 참여 시작 블록
        uint256 lastUpdateTime;       // 마지막 업데이트 타임스탬프
        bool isEligible;              // 자격 여부 (T_i ≥ θ·B_i)
    }
}
```

### 3.2 RATStorage

```solidity
contract RATStorage {
    // 백서 V2 파라미터
    uint256 public slashingPenalty;           // C_off: 슬래싱 페널티
    uint256 public validatorBuffer;           // Δ_validator: 추가 버퍼
    uint256 public ratTriggerProbability;     // π_a: RAT 트리거 확률 (RAY)
    uint256 public minimumThreshold;          // D_min: 최소 담보금 임계값
    uint256 public evidenceSubmissionPeriod;  // 증거 제출 기간 (초)

    // V3 검증자 담보금 체크 유연화
    bool public relaxedValidatorCheck;        // 검증자 유효성 검사 완화 여부
                                              // true: C_off 기준 (완화), false: D_min 기준 (엄격)
                                              // 등록 시에는 항상 D_min 이상 필요

    // ValidatorReward 컨트랙트 주소 (O(1) 보상 분배용)
    address public validatorReward;

    // 검증자 등록
    mapping(address => mapping(address => ValidatorRegistration))
        public validatorRegistrations;        // systemConfig => validator => 등록정보
    mapping(address => ValidatorPoolInfo) internal validatorPools;

    // RAT 테스트
    mapping(bytes32 => AttentionTest) public attentionTests;
    mapping(address => bytes32) public gameToTestId;

    struct ValidatorRegistration {
        uint256 depositedAmount;      // 현재 유효 담보금
        uint256 totalBondForRAT;      // RAT에 묶인 금액
        uint64 latestTestDeadline;    // 최근 테스트 마감
        uint32 validatorIndex;        // 인덱스
        bool isActive;                // 활성 상태
    }

    struct ValidatorPoolInfo {
        address[] validators;
        uint256 activeCount;
        uint256 totalDeposited;
    }

    struct AttentionTest {
        address validatorAddress;
        address systemConfig;
        uint32 batchIndex;
        bytes32 batchHash;
        uint256 bondAmount;           // C_off
        uint256 createdAt;
        uint256 deadline;
        AttentionTestStatus status;
    }

    enum AttentionTestStatus {
        Pending,
        Responded,
        Slashed,
        Expired
    }
}
```

### 3.3 ValidatorRewardStorage

```solidity
contract ValidatorRewardStorage {
    // ==========================================
    // 보상 관련
    // ==========================================

    /// @notice 검증자별 총 미청구 보상 (claimAllRewards에서 사용)
    mapping(address => uint256) public validatorPendingRewards;

    /// @notice L2별 보상은 ValidatorRewardReceived 이벤트로 추적
    mapping(address => mapping(address => uint256)) public validatorL2PendingRewards;

    mapping(address => uint256) public l2TotalDistributed;

    // ==========================================
    // RewardPerValidator 패턴 (O(1) 분배)
    // ==========================================

    /// @notice L2별 검증자당 누적 보상 (systemConfig => accumulated)
    /// @dev distributeL2Rewards에서 O(1)로 업데이트
    mapping(address => uint256) public rewardPerValidator;

    /// @notice 검증자별 L2별 보상 debt (validator => systemConfig => debt)
    /// @dev 검증자 등록 시 현재 rewardPerValidator로 설정
    mapping(address => mapping(address => uint256)) public validatorRewardDebt;

    /// @notice 검증자가 등록된 L2 목록 (validator => systemConfig[])
    /// @dev claimAllRewards에서 모든 L2 순회용
    mapping(address => address[]) public validatorL2List;

    /// @notice 검증자의 L2 등록 여부 (validator => systemConfig => bool)
    /// @dev 중복 등록 방지
    mapping(address => mapping(address => bool)) public isValidatorInL2;

    // ==========================================
    // 참조 주소
    // ==========================================

    address public seigManager;
    address public wton;
    address public ratContract;
    address public treasury;  // seigManager.dao() 사용
    address public owner;
}
```

**RewardPerValidator 패턴**:

```
분배 시점 (distributeL2Rewards):
┌─────────────────────────────────────────────────────────────────┐
│ perValidator = amount / activeCount                              │
│ rewardPerValidator[systemConfig] += perValidator   ← O(1) 연산 │
└─────────────────────────────────────────────────────────────────┘

청구 시점 (claimAllRewards):
┌─────────────────────────────────────────────────────────────────┐
│ 각 L2에 대해:                                                    │
│   earned = rewardPerValidator[systemConfig]                     │
│          - validatorRewardDebt[validator][systemConfig]         │
│   if (활성 검증자):                                              │
│       validatorPendingRewards[validator] += earned              │
│   validatorRewardDebt[validator][systemConfig] = current        │
└─────────────────────────────────────────────────────────────────┘
```

**가스 비용**:
- `updateSeigniorage`: O(1) 복잡도 (검증자 수와 무관)
- `claimAllRewards`: O(L) 복잡도 (검증자가 등록된 L2 수에 비례)

---

## 4. 인터페이스 정의

### 4.1 ISeigManagerV3

```solidity
interface ISeigManagerV3 {
    // V3 조회 함수
    function checkCurrentEligibility(address layer2)
        external view returns (bool eligible, uint256 requiredStake, uint256 currentStake);
    function getEffectiveBridgedTON(address layer2) external view returns (uint256);
    function getTotalEffectiveBridgedTON() external view returns (uint256);

    // V3 콜백
    function onBridgedTonChange() external;
    function onStakingChange(address layer2) external;

    // V3 거버넌스
    function migrateToV3() external;

    // 이벤트
    event V3SeigniorageDistributed(
        uint256 totalSeigniorage,
        uint256 l2MaxAllocation,
        uint256 totalDistributed,
        uint256 daoAmount,
        uint256 validatorPoolAmount
    );
    event EligibilityChanged(address indexed layer2, bool eligible, uint256 bridgedTON, uint256 effectiveBridgedTON);
    event V3MigrationCompleted(uint256 blockNumber, uint256 totalMigratedL2s);
}
```

### 4.2 IRAT

```solidity
interface IRAT {
    // 검증자 관리
    function registerValidator(address systemConfig, uint256 depositAmount) external;
    function deactivateValidator(address systemConfig) external;
    function addDeposit(address systemConfig, uint256 amount) external;

    // RAT 작업
    function triggerAttentionTest(
        address gameAddress,
        address systemConfig,
        uint32 batchIndex,
        bytes32 batchHash,
        bytes32 blockHash
    ) external;
    function submitEvidence(address systemConfig, uint32 batchIndex, bytes calldata evidence) external;
    function resolveClaim(address _claimant) external;

    // 조회
    function getL2Validators(address systemConfig) external view returns (address[] memory);
    function isValidatorActive(address validator, address systemConfig) external view returns (bool);
    function getActiveValidatorCount(address systemConfig) external view returns (uint256);
    function getMinimumCollateral() external view returns (uint256);
    function getValidatorMinCollateralForLayer2(address layer2, address validator) external view returns (uint256);

    // 이벤트
    event ValidatorRegistered(address indexed validator, address indexed systemConfig, uint256 depositAmount, uint256 registrationId);
    event AttentionTestTriggered(bytes32 indexed testId, address indexed validator, address indexed systemConfig, address gameAddress, uint32 batchIndex, uint256 deadline);
    event EvidenceSubmitted(bytes32 indexed testId, address indexed validator, address indexed systemConfig, uint32 batchIndex);
    event ValidatorSlashed(bytes32 indexed testId, address indexed validator, address indexed systemConfig, uint256 slashedAmount, bool removedFromSet);
}
```

### 4.3 IValidatorReward

```solidity
interface IValidatorReward {
    // ==========================================
    // View Functions
    // ==========================================

    /// @notice 총 미청구 보상 조회 (동기화된 것만)
    function getPendingRewards(address validator) external view returns (uint256);

    /// @notice L2별 미청구 보상 조회 (이벤트 사용 권장)
    function getPendingRewardsByL2(address validator, address systemConfig) external view returns (uint256);

    /// @notice 총 청구 가능 보상 계산 (미동기화 보상 포함)
    function getClaimableRewards(address validator) external view returns (uint256 total);

    // ==========================================
    // External Functions - Rewards
    // ==========================================

    /// @notice L2별 검증자 보상 분배 (SeigManager에서 호출)
    function distributeL2Rewards(address systemConfig, uint256 amount) external;

    /// @notice 모든 L2에서 받은 보상 한 번에 청구
    /// @dev 등록된 L2가 많으면 가스 한도 초과 가능 - claimRewardsByL2s 사용 권장
    function claimAllRewards() external;

    /// @notice 특정 L2들에서 받은 보상 청구 (가스 최적화)
    /// @dev 등록된 L2가 많을 때 배치로 청구할 때 사용
    function claimRewardsByL2s(address[] calldata systemConfigs) external;

    /// @notice 검증자 L2 등록 (RAT에서 호출)
    function registerValidatorToL2(address validator, address systemConfig) external;

    /// @notice 검증자 보상 동기화 (비활성화 전 호출)
    function syncValidatorReward(address validator, address systemConfig) external;

    /// @notice 검증자 재활성화 시 debt 리셋 (RAT에서 호출)
    function resetValidatorDebt(address validator, address systemConfig) external;

    // ==========================================
    // Events
    // ==========================================

    event L2RewardDistributed(
        address indexed systemConfig,
        uint256 totalAmount,
        uint256 activeValidatorCount,
        uint256 perValidator
    );
    event ValidatorRewardReceived(address indexed validator, address indexed systemConfig, uint256 amount);
    event RewardToDAO(address indexed systemConfig, uint256 amount);
    event RewardsClaimed(address indexed validator, uint256 amount);
    event ValidatorRegisteredToL2(address indexed validator, address indexed systemConfig, uint256 initialDebt);
}
```

---

## 5. 상속 관계

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                            Inheritance Hierarchy                                 │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│  SeigManagerV3_1:                                                               │
│  ┌────────────────┐                                                             │
│  │  ProxyStorage  │                                                             │
│  └───────┬────────┘                                                             │
│          │                                                                       │
│  ┌───────┴─────────────────┐                                                    │
│  │ AuthControlSeigManager  │                                                    │
│  └───────┬─────────────────┘                                                    │
│          │                                                                       │
│  ┌───────┴────────────────┐                                                     │
│  │  SeigManagerStorage    │  (V1 fields)                                        │
│  └───────┬────────────────┘                                                     │
│          │                                                                       │
│  ┌───────┴─────────────────┐                                                    │
│  │ SeigManagerV1_1Storage  │  (V1.1 fields)                                     │
│  └───────┬─────────────────┘                                                    │
│          │                                                                       │
│  ┌───────┴────────┐                                                             │
│  │    DSMath      │  (RAY math)                                                 │
│  └───────┬────────┘                                                             │
│          │                                                                       │
│  ┌───────┴─────────────────┐                                                    │
│  │ SeigManagerV1_3Storage  │  (V1.3 fields)                                     │
│  └───────┬─────────────────┘                                                    │
│          │                                                                       │
│  ┌───────┴─────────────────┐                                                    │
│  │ SeigManagerV1_4Storage  │  (V3 fields: d, θ, α, k, ...)                      │
│  └───────┬─────────────────┘                                                    │
│          │                                                                       │
│  ┌───────┴───────────┐                                                          │
│  │  ISeigManagerV3   │  (V3 interface)                                          │
│  └───────────────────┘                                                          │
│                                                                                  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 6. 관련 문서

- [01-system-overview.md](./01-system-overview.md): 시스템 개요
- [02-system-architecture.md](./02-system-architecture.md): 시스템 아키텍처
- [04-contract-roles.md](./04-contract-roles.md): 컨트랙트별 역할
- [05-actors.md](./05-actors.md): 액터 정의
- [06-function-specs.md](./06-function-specs.md): 함수별 상세 설명
