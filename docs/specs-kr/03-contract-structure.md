# TON Staking V3 컨트랙트 구조

## 1. 디렉토리 구조

```
src/
├── stake/                          # 스테이킹 관련
│   ├── managers/
│   │   ├── SeigManagerV1_4.sol            # 시뇨리지 분배 (V3 핵심)
│   │   ├── SeigManagerV1_4Storage.sol     # V3 스토리지
│   │   ├── SeigManagerV1_3Storage.sol     # V1.3 스토리지
│   │   ├── SeigManagerStorage.sol         # 기본 스토리지
│   │   ├── DepositManagerV1_2.sol         # 스테이킹 관리
│   │   └── DepositManagerStorage.sol      # 스토리지
│   │
│   └── interfaces/
│       ├── ISeigManager.sol               # 기본 인터페이스
│       ├── ISeigManagerV3.sol             # V3 인터페이스
│       └── ITON.sol                       # TON 인터페이스
│
├── layer2/                         # L2 관리
│   ├── Layer2ManagerV1_2.sol              # L2 관리 (V3)
│   ├── Layer2ManagerStorage.sol
│   ├── L1BridgeRegistryV1_2.sol           # 브릿지 레지스트리
│   └── interfaces/
│       ├── ILayer2Manager.sol
│       ├── IL1BridgeRegistry.sol
│       └── IOptimismSystemConfig.sol
│
├── validator/                      # 검증자 시스템 (V3 신규)
│   ├── RAT.sol                            # 검증자 등록/RAT/슬래싱
│   ├── RATStorage.sol
│   ├── ValidatorRewardV1.sol              # 검증자 보상 분배
│   ├── ValidatorRewardStorage.sol
│   ├── IRAT.sol                           # 인터페이스
│   └── IValidatorReward.sol
│
├── sequencer/                      # 시퀀서 시스템 (V3 신규)
│   ├── SequencerVault.sol                 # 시퀀서 담보금/슬래싱
│   ├── SequencerVaultStorage.sol
│   └── ISequencerVault.sol
│
├── dao/                            # DAO/거버넌스
│   └── interfaces/
│       ├── IWTON.sol
│       └── IIDAOCommittee.sol
│
├── proxy/                          # 프록시 관련
│   └── ProxyStorage.sol
│
├── common/                         # 공통 유틸리티
│   ├── AccessibleCommon.sol
│   └── AuthControlSeigManager.sol
│
└── libraries/                      # 라이브러리
    ├── DSMath.sol                         # RAY 수학
    └── SafeERC20.sol
```

---

## 2. 핵심 컨트랙트 상세

### 2.1 SeigManagerV1_4

시뇨리지 계산 및 분배의 핵심 컨트랙트입니다.

```solidity
contract SeigManagerV1_4 is
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

### 2.2 DepositManagerV1_2

TON/WTON 스테이킹을 관리합니다.

```solidity
contract DepositManagerV1_2 is
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

### 2.3 Layer2ManagerV1_2

L2 등록 및 관리를 담당합니다.

```solidity
contract Layer2ManagerV1_2 is
    ProxyStorage,
    AccessibleCommon,
    Layer2ManagerStorage,
    Layer2ManagerV1_2Storage
{
    // ...
}
```

**핵심 기능**:
- `getBridgedTON()`: Bridged TON 조회
- `getLayer2BySystemConfig()`: SystemConfig → Layer2 조회
- `transferL2Seigniorage()`: 시뇨리지 전송

### 2.4 L1BridgeRegistryV1_2

브릿지/포탈 등록 및 TVL 조회를 담당합니다.

```solidity
contract L1BridgeRegistryV1_2 is
    ProxyStorage,
    AccessibleCommon,
    L1BridgeRegistryStorage
{
    // ...
}
```

**핵심 기능**:
- `layer2TVL()`: L2별 TVL 조회
- `rollupType()`: 롤업 타입 조회
- `rollupConfigWithPortal()`: 포탈 → rollupConfig 역조회

### 2.5 RAT (Randomized Attention Test)

검증자 등록, RAT 테스트, 슬래싱을 관리합니다.

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

검증자 보상 분배를 담당합니다.

```solidity
contract ValidatorRewardV1 is
    ProxyStorage,
    ValidatorRewardStorage,
    IValidatorReward
{
    // ...
}
```

**핵심 기능**:
- `distributeL2Rewards()`: L2별 검증자 보상 분배
- `claimAllRewards()`: 보상 청구
- `getPendingRewardsByL2()`: L2별 미청구 보상 조회

### 2.7 SequencerVault

시퀀서 담보금 및 슬래싱을 관리합니다.

```solidity
contract SequencerVault is
    ProxyStorage,
    SequencerVaultStorage,
    ISequencerVault
{
    // ...
}
```

**핵심 기능**:
- `registerSequencer()`: 시퀀서 등록 (담보금 예치)
- `slashSequencerByGame()`: 시퀀서 슬래싱 (Permissionless)
- `deactivateSequencer()`: 시퀀서 탈퇴
- `getSequencerDepositByLayer2()`: 담보금 조회

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
    address public ratContract;               // RAT 컨트랙트 (미사용, ValidatorReward 내부)
    address public sequencerVault;            // SequencerVault 컨트랙트

    // Bridged TON 추적
    mapping(address => BridgedTONInfo) public bridgedTONInfo;
    uint256 public totalEffectiveBridgedTON;  // x: 전체 유효 Bridged TON

    struct BridgedTONInfo {
        uint256 bridgedTON;         // B_i
        uint256 effectiveBridgedTON; // B̃_i
        bool isEligible;            // 자격 여부
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
    address public seigManager;
    address public ratContract;
    address public wton;
    address public treasury;

    // 검증자별 보상
    mapping(address => uint256) public validatorPendingRewards;

    // L2별 검증자 보상 (Per-L2 추적)
    mapping(address => mapping(address => uint256))
        public validatorL2PendingRewards;  // validator => systemConfig => 보상
}
```

### 3.4 SequencerVaultStorage

```solidity
contract SequencerVaultStorage {
    // 시퀀서 담보금
    mapping(address => SequencerDeposit) public sequencerDeposits;
    mapping(address => address) public layer2ToSystemConfig;

    // 파라미터
    uint256 public minimumStakingRatio;       // θ: 최소 스테이킹 비율
    uint256 public maxFraudProofCost;         // C_max
    uint256 public sequencerAdditionalReward; // Δ_sequencer
    uint256 public maxChallengers;            // H_max

    // 슬래싱
    uint256 public accumulatedSlashings;
    mapping(address => uint256) public challengerPendingRewards;

    struct SequencerDeposit {
        address operator;             // OperatorManager 주소
        address layer2;               // Layer2 주소
        uint256 depositedAmount;      // 담보금
        uint256 slashedAmount;        // 슬래싱된 금액
        bool isActive;                // 활성 상태
    }
}
```

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
    function onBridgedTONChange() external;
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
    function distributeL2Rewards(address systemConfig, uint256 amount) external;
    function claimAllRewards() external;
    function getPendingRewardsByL2(address validator, address systemConfig) external view returns (uint256);
    function getTotalPendingRewards(address validator) external view returns (uint256);

    // 이벤트
    event L2RewardDistributed(address indexed systemConfig, uint256 distributed, uint256 validatorCount);
    event ValidatorRewardReceived(address indexed validator, address indexed systemConfig, uint256 amount);
    event RewardToTreasury(address indexed systemConfig, uint256 amount);
    event RewardsClaimed(address indexed validator, uint256 amount);
}
```

### 4.4 ISequencerVault

```solidity
interface ISequencerVault {
    function registerSequencer(address systemConfig, uint256 depositAmount) external;
    function deactivateSequencer(address systemConfig) external;
    function addDeposit(address systemConfig, uint256 amount) external;
    function slashSequencerByGame(address gameAddress) external;

    function getSequencerDeposit(address systemConfig) external view returns (uint256);
    function getSequencerDepositByLayer2(address layer2) external view returns (uint256);
    function isSequencerActive(address systemConfig) external view returns (bool);
    function getMinimumCollateral(uint256 bridgedTON) external view returns (uint256);

    // 이벤트
    event SequencerRegistered(address indexed operator, address indexed systemConfig, address layer2, uint256 depositAmount);
    event SequencerSlashed(address indexed sequencer, address indexed systemConfig, address indexed gameAddress, uint256 slashedAmount, address challenger, uint256 challengerReward);
}
```

---

## 5. 상속 관계

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                            Inheritance Hierarchy                                 │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│  SeigManagerV1_4:                                                               │
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
