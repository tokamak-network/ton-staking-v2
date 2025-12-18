# RAT 구현체 설계

## 1. 개요

이 문서는 TON Staking V3용 RAT(Randomized Attention Test) 시스템의 구현을 설명합니다.

### 1.1 TON V3 RAT 핵심 사항

| 항목 | TON V3 RAT |
|------|-----------|
| **스테이킹 자산** | TON (ERC20) |
| **담보금 관리** | RAT 컨트랙트에서 TON 직접 보관 |
| **트리거 시점** | Dispute Game 생성 시 |
| **트리거 주체** | DisputeGameFactory |
| **검증자 범위** | L2별 등록 |
| **슬래싱 방식** | C_off 선차감 (백서 V2: 슬래싱 페널티) |
| **슬래싱 귀속** | DAO Treasury (`accumulatedSlashings` → `withdrawSlashingsToTreasury()`) |
| **D_min 확인** | D_min 미만 시 즉시 검증자 세트에서 제거 |
| **보상 시스템** | 시뇨리지 분배 V3: (α · S_i) / \|V_i\| |
| **담보금 시뇨리지** | 없음 (V3: 스테이킹 시뇨리지 폐지) |
| **출금** | 즉시 출금 (2주 대기 없음) |

### 1.2 L2별 검증자 등록 방식

TON V3에서는 여러 L2가 존재하므로, 검증자가 **특정 L2에만 등록**할 수 있습니다.

```
검증자 A ──┬──→ Titan SystemConfig 등록 (담보금 5,000 TON)
           └──→ Thanos SystemConfig 등록 (담보금 3,000 TON)

검증자 B ──────→ Titan SystemConfig만 등록 (담보금 10,000 TON)

검증자 C ──────→ Thanos SystemConfig만 등록 (담보금 2,000 TON)
```

**장점:**
- 검증자가 관심있는 L2만 선택 가능
- L2별로 다른 담보금 설정 가능
- L2별 보상 분배 가능

### 1.3 키 구조: SystemConfig 사용

L2를 식별하는 키로 **SystemConfig 컨트랙트 주소**를 사용합니다.

```solidity
// Optimism SystemConfig: L2 네트워크 설정 관리 컨트랙트
// - batcher, gas limit, fee scalars 등 관리
// - 각 L2마다 고유한 SystemConfig 주소 보유

// 키 구조
(validator, systemConfig) → ValidatorRegistration
(systemConfig, batchIndex) → AttentionTest
// 주의: AttentionTest는 Optimism L2에서 DisputeGame 생성 시 발생
```

**SystemConfig 사용 이유:**
1. **고유성**: 각 L2는 고유한 SystemConfig 주소를 가짐
2. **검증 가능**: Layer2Manager에서 유효한 SystemConfig인지 검증 가능
3. **확장성**: 향후 SystemConfig의 다른 정보(batcher 등) 활용 가능

---

## 2. 아키텍처

### 2.1 컨트랙트 구조

```
contracts/
└── validator/
    ├── RAT.sol                    # 메인 RAT 컨트랙트
    ├── RATStorage.sol             # 스토리지 레이아웃
    └── interfaces/
        └── IRAT.sol               # 인터페이스
```

### 2.2 시스템 통합

```
┌─────────────────────────────────────────────────────────────────────┐
│                    DisputeGameFactory (Optimism L2)                   │
│  (DisputeGame 생성 시 RAT 트리거)                                     │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ triggerAttentionTest()
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                              RAT.sol                                 │
│                                                                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                  │
│  │ Validator   │  │ Attention   │  │ Slashing    │                  │
│  │ Registry    │  │ Tests       │  │ Logic       │                  │
│  └─────────────┘  └─────────────┘  └─────────────┘                  │
└─────────────────────────────────────────────────────────────────────┘
        │                   │
        │                   │ (보상 분배)
        │                   │
        ▼                   ▼
┌───────────────┐  ┌──────────────────────────────────────────────┐
│  RAT 컨트랙트  │  │  SeigManager → ValidatorReward                 │
│  (TON 보관)   │  │  → ValidatorReward.distributeL2Rewards()       │
└───────────────┘  └──────────────────────────────────────────────┘
```

### 2.3 RAT 담보금 관리 (V3: TON 직접 보관)

V3에서는 DepositManager 대리 스테이킹을 사용하지 않고, **RAT 컨트랙트에서 TON을 직접 보관**합니다.

```
검증자 등록:
┌──────────┐  TON.approveAndCall()  ┌──────────┐
│ 검증자    │ ───────────────────► │   RAT    │
└──────────┘   또는 transferFrom    │ (TON 보관)│
                                    └──────────┘

검증자 탈퇴:
┌──────────┐  deactivateValidator() ┌──────────┐    TON 전송    ┌──────────┐
│ 검증자    │ ───────────────────► │   RAT    │ ─────────────► │ 검증자    │
└──────────┘                        └──────────┘   (즉시 출금)   └──────────┘
```

**V3 핵심 설계:**
- **담보금**: RAT 컨트랙트에서 TON 직접 보관
- **등록**: `TON.approveAndCall(RAT, amount, systemConfig)` 권장
- **출금**: 즉시 출금 (2주 대기 없음)
- **슬래싱**: 내부 기록(`depositedAmount`)만 변경, TON은 RAT에 보관 유지

RAT 트리거/복구/슬래싱 (내부 기록만):
```
┌──────────────────────────────────────────────────────────────────────┐
│  RAT 트리거 시:                                                       │
│    - 내부 기록: depositedAmount에서 C_off 차감                        │
│    - TON: RAT 컨트랙트에 보관 유지                                    │
│                                                                      │
│  증거 제출/챌린지 승리 시:                                             │
│    - 내부 기록: depositedAmount 복구                                 │
│    - TON: 변경 없음                                                   │
│                                                                      │
│  미응답 시 (슬래싱):                                                   │
│    - 내부 기록: depositedAmount 유지 (이미 차감됨)                    │
│    - TON: accumulatedSlashings에 누적 → Treasury로 출금 가능          │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 3. 데이터 구조

### 3.1 SystemConfig별 검증자 등록 (ValidatorRegistration)

```solidity
/// @notice 검증자 등록 정보
/// @dev 백서 V2 공식 (5) 기반: D_validator = C_off + Δ_validator
/// @dev V3 정책: 담보금 시뇨리지 없음, depositedAmount = 원금 - 슬래싱
/// @dev V3 변경: pendingRewards 제거 → ValidatorReward 컨트랙트에서 관리
struct ValidatorRegistration {
    uint256 depositedAmount;        // 현재 유효 담보금 (원금 - 슬래싱 손실)
    uint256 totalBondForRAT;        // 진행 중인 RAT 테스트들에 묶인 총 금액
    uint64 latestTestDeadline;      // 가장 최근 RAT 테스트 마감 시간 (출금 조건)
    uint32 validatorIndex;          // 검증자 인덱스
    bool isActive;                  // 활성 상태
    // pendingRewards 제거: ValidatorReward 컨트랙트에서 관리
}
```

**V3 TON 직접 보관 설계:**
- 검증자가 RAT 컨트랙트에 TON 직접 예치
- DepositManager 미사용 → 간단한 구조, 즉시 출금 가능
- 담보금 시뇨리지 없음 → depositedAmount = 원금 - 슬래싱 손실
- 진행 중인 RAT 테스트가 있으면 출금 불가 (latestTestDeadline 체크)

**RAT 테스트 흐름:**
```
RAT 트리거 시:
  depositedAmount -= C_off
  totalBondForRAT += C_off
  latestTestDeadline = max(latestTestDeadline, block.timestamp + evidenceSubmissionPeriod)

증거 제출 성공 시:
  depositedAmount += C_off
  totalBondForRAT -= C_off

미응답 시:
  (아무것도 안 함 - 이미 차감됨, lazy evaluation)

출금 시 (deactivateValidator):
  require(block.timestamp >= latestTestDeadline)  // 테스트 마감 후에만 출금 가능
  출금 금액 = depositedAmount (전액 반환)
```

**V3 시뇨리지 정책:**
- **담보금 시뇨리지: 없음** - V3에서는 검증자 담보금에 시뇨리지 없음
- 출금 시 depositedAmount 전액 반환
- 슬래싱된 금액 → accumulatedSlashings → Treasury

### 3.2 SystemConfig별 검증자 풀 (ValidatorPoolInfo)

```solidity
/// @notice SystemConfig별 검증자 풀 정보
struct ValidatorPoolInfo {
    address[] validators;           // 검증자 목록
    uint256 activeCount;            // 활성 검증자 수
    uint256 totalDeposited;         // 총 예치 금액
}
```

### 3.3 AttentionTest (RAT 테스트 정보)

**트리거 시점**: Optimism L2에서 DisputeGame 생성 시 발생합니다. DisputeGameFactory가 게임을 생성할 때 RAT.triggerAttentionTest()가 호출되어 AttentionTest가 생성됩니다.

```solidity
/// @notice RAT 챌린지 정보 구조체
/// @dev 키: keccak256(abi.encodePacked(systemConfig, batchIndex))
/// @dev DisputeGame 생성 시 발생 (DisputeGameFactory.create() 호출 시)
/// @dev 선차감-복구 메커니즘: slashed 필드 불필요 (트리거 시 이미 차감됨)
struct AttentionTest {
    // Slot 1: 32 bytes
    bytes32 expectedHash;           // 검증해야 할 배치 해시 (TBD: 구체적인 형식 확인 필요)

    // Slot 2: 32 bytes (packed)
    uint96 bondAmount;              // 복구용 금액 기록 (전체 담보금)
    address validatorAddress;       // 선택된 검증자 주소 (20 bytes)

    // Slot 3: 32 bytes (packed)
    address systemConfig;           // L2 SystemConfig 주소 (20 bytes)
    uint64 blockNumber;             // RAT 발행 블록 (8 bytes)
    bool evidenceSubmitted;         // 증거 제출 여부 (1 byte)
    // slashed 필드 제거됨: 선차감 메커니즘으로 별도 슬래싱 불필요
}
```

### 3.4 스토리지 레이아웃

```solidity
// ============================================
// SystemConfig별 검증자 등록
// ============================================

/// @notice (validator, systemConfig) → 등록 정보
/// @dev registrationId = keccak256(abi.encodePacked(validator, systemConfig))
mapping(bytes32 => ValidatorRegistration) public registrations;

/// @notice systemConfig → 검증자 풀 정보
mapping(address => ValidatorPoolInfo) public validatorPools;

/// @notice systemConfig → 활성 검증자 배열 (인덱스 0은 더미)
mapping(address => address[]) public activeValidators;

/// @notice 검증자 → 등록한 SystemConfig 목록
mapping(address => address[]) public validatorSystemConfigs;

/// @notice (validator, systemConfig) → 등록 여부 (중복 방지)
mapping(address => mapping(address => bool)) public isRegistered;


// ============================================
// RAT 테스트
// ============================================

/// @notice testId → RAT 테스트 정보
/// @dev testId = keccak256(abi.encodePacked(systemConfig, batchIndex))
mapping(bytes32 => AttentionTest) public attentionTests;

/// @notice 게임 주소 → testId 매핑 (resolveClaim에서 사용)
mapping(address => bytes32) public gameToTestId;
```

---

## 4. RATStorage.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title RATStorage
/// @notice RAT 스토리지 - V3: 검증자가 TON을 RAT에 직접 예치
/// @dev DepositManager 미사용, 즉시 출금 가능
contract RATStorage {
    // ============================================
    // Constants
    // ============================================

    uint256 internal constant RAY = 1e27;
    uint256 internal constant MAX_PROBABILITY = 1e27; // 100% in RAY

    // ============================================
    // Enums
    // ============================================

    enum AttentionTestStatus {
        Pending,        // 대기 중 (증거 제출 기간)
        Responded,      // 증거 제출됨
        Slashed,        // 슬래싱됨 (미응답)
        Expired         // 만료됨 (처리 완료)
    }

    // ============================================
    // Structs
    // ============================================

    /// @notice 검증자 등록 정보
    /// @dev V3 정책: 담보금 시뇨리지 없음, depositedAmount = 원금 - 슬래싱
    /// @dev V3 변경: pendingRewards 제거 → ValidatorReward 컨트랙트에서 관리
    struct ValidatorRegistration {
        uint256 depositedAmount;        // 현재 유효 담보금 (원금 - 슬래싱 손실)
        uint256 totalBondForRAT;        // 진행 중인 RAT 테스트들에 묶인 총 금액
        uint64 latestTestDeadline;      // 가장 최근 RAT 테스트 마감 시간 (출금 조건)
        uint32 validatorIndex;          // 검증자 인덱스
        bool isActive;                  // 활성 상태
        // pendingRewards 제거: ValidatorReward 컨트랙트에서 관리
    }

    /// @notice Attention Test 정보
    struct AttentionTest {
        address validatorAddress;       // 선택된 검증자
        address systemConfig;           // L2 SystemConfig 주소
        uint32 batchIndex;              // 배치 인덱스
        bytes32 batchHash;              // 배치 해시
        uint256 bondAmount;             // 선차감된 담보금 (C_off)
        uint256 createdAt;              // 생성 시간
        uint256 deadline;               // 응답 마감 시간
        AttentionTestStatus status;     // 상태
    }

    /// @notice SystemConfig별 검증자 풀 정보
    struct ValidatorPoolInfo {
        address[] validators;           // 검증자 목록
        uint256 activeCount;            // 활성 검증자 수
        uint256 totalDeposited;         // 총 예치 금액
    }

    // ============================================
    // 검증자 관련 스토리지
    // ============================================

    /// @notice systemConfig => validator => ValidatorRegistration
    mapping(address => mapping(address => ValidatorRegistration)) public validatorRegistrations;

    /// @notice systemConfig => ValidatorPoolInfo
    mapping(address => ValidatorPoolInfo) internal validatorPools;

    /// @notice systemConfig => validator => 검증자 인덱스
    mapping(address => mapping(address => uint256)) public validatorIndexes;

    /// @notice validator => 등록된 systemConfig 목록
    mapping(address => address[]) public validatorSystemConfigs;

    // ============================================
    // Attention Test 관련 스토리지
    // ============================================

    /// @notice testId => AttentionTest
    mapping(bytes32 => AttentionTest) public attentionTests;

    /// @notice systemConfig => batchIndex => testId
    mapping(address => mapping(uint32 => bytes32)) public batchToTestId;

    /// @notice game address => testId 매핑 (resolveClaim에서 사용)
    mapping(address => bytes32) public gameToTestId;

    // ============================================
    // 백서 V2 파라미터
    // ============================================

    /// @notice C_off: 슬래싱 페널티 (백서 공식 4)
    uint256 public slashingPenalty;

    /// @notice Δ_validator: 검증자 추가 버퍼
    uint256 public validatorBuffer;

    /// @notice π_a: RAT 트리거 확률 (RAY 단위)
    uint256 public ratTriggerProbability;

    /// @notice D_min: 최소 담보금 임계값
    uint256 public minimumThreshold;

    /// @notice 증거 제출 기간 (초)
    uint256 public evidenceSubmissionPeriod;

    // ============================================
    // 참조 주소
    // ============================================

    address public seigManager;
    address public wton;
    address public ton;
    address public layer2Manager;
    address public l1BridgeRegistry;
    address public owner;
    address public treasury;

    // V3: depositManager 제거 - RAT에서 TON 직접 보관
    // address public depositManager;  // DEPRECATED

    // ============================================
    // 슬래싱 금액
    // ============================================

    /// @notice 누적 슬래싱 금액 (Treasury 귀속 대기)
    uint256 public accumulatedSlashings;

    // ============================================
    // 상태
    // ============================================

    bool internal _lock;
    bool public paused;

    // ============================================
    // Modifiers
    // ============================================

    modifier ifFree() {
        require(!_lock, "locked");
        _lock = true;
        _;
        _lock = false;
    }

    modifier whenNotPaused() {
        require(!paused, "paused");
        _;
    }
}
```

---

## 5. IRAT.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title IRAT
/// @notice RAT (Randomized Attention Test) 인터페이스
/// @dev V3: 검증자가 TON을 RAT에 직접 예치, 즉시 출금 가능
interface IRAT {
    // ==========================================
    // Events
    // ==========================================

    /// @notice 검증자 등록 이벤트
    event ValidatorRegistered(
        address indexed validator,
        address indexed systemConfig,
        uint256 depositAmount,
        uint256 registrationId
    );

    /// @notice 검증자 탈퇴 이벤트
    event ValidatorDeactivated(
        address indexed validator,
        address indexed systemConfig,
        uint256 returnedAmount
    );

    /// @notice Attention Test 트리거 이벤트
    event AttentionTestTriggered(
        bytes32 indexed testId,
        address indexed validator,
        address indexed systemConfig,
        address gameAddress,
        uint32 batchIndex,
        uint256 deadline
    );

    /// @notice 증거 제출 이벤트
    event EvidenceSubmitted(
        bytes32 indexed testId,
        address indexed validator,
        address indexed systemConfig,
        uint32 batchIndex
    );

    /// @notice 슬래싱 이벤트
    event ValidatorSlashed(
        bytes32 indexed testId,
        address indexed validator,
        address indexed systemConfig,
        uint256 slashedAmount,
        bool removedFromSet
    );

    /// @notice 챌린지 승리로 담보금 복구 이벤트 (resolveClaim)
    event BondRestored(
        bytes32 indexed testId,
        address indexed validator,
        address indexed systemConfig,
        uint256 restoredAmount
    );

    /// @notice 검증자 미할당 시 Treasury 귀속 이벤트
    event ValidatorRewardToTreasury(
        address indexed systemConfig,
        uint256 amount
    );

    // ==========================================
    // View Functions
    // ==========================================

    /// @notice 최소 담보금 계산 (백서 공식 5: D_validator = C_off + Δ_validator)
    function getMinimumCollateral() external view returns (uint256);

    /// @notice 특정 L2의 활성 검증자 수 조회
    function getActiveValidatorCount(address systemConfig) external view returns (uint256);

    /// @notice 검증자 등록 정보 조회
    /// @dev V3 변경: pendingRewards 제거 (ValidatorReward에서 관리)
    function getValidatorRegistration(address validator, address systemConfig)
        external
        view
        returns (
            uint256 depositedAmount,
            uint256 totalBondForRAT,
            uint32 validatorIndex,
            bool isActive
        );

    /// @notice 검증자 담보금 조회
    function getValidatorDeposit(address validator, address systemConfig) external view returns (uint256);

    /// @notice 검증자 활성 상태 확인
    function isValidatorActive(address validator, address systemConfig) external view returns (bool);

    // ==========================================
    // External Functions - Validator Management
    // ==========================================

    /// @notice 검증자 등록 (TON 직접 예치)
    /// @dev TON.approveAndCall(RAT, amount, systemConfig) 사용 권장
    function registerValidator(address systemConfig, uint256 depositAmount) external;

    /// @notice 검증자 탈퇴 및 즉시 출금
    /// @dev V3: DepositManager 미사용으로 즉시 출금 가능
    function deactivateValidator(address systemConfig) external;

    /// @notice 담보금 추가 예치
    function addDeposit(address systemConfig, uint256 amount) external;

    // ==========================================
    // External Functions - RAT Operations
    // ==========================================

    /// @notice RAT 테스트 트리거 (DisputeGameFactory에서 호출)
    function triggerAttentionTest(
        address gameAddress,
        address systemConfig,
        uint32 batchIndex,
        bytes32 batchHash,
        bytes32 blockHash
    ) external;

    /// @notice RAT 증거 제출
    function submitEvidence(
        address systemConfig,
        uint32 batchIndex,
        bytes calldata evidence
    ) external;

    /// @notice 게임 해결 시 담보금 복구 (FaultDisputeGame에서 호출)
    function resolveClaim(address _claimant) external;

    // ==========================================
    // View Functions - ValidatorReward용
    // ==========================================

    /// @notice L2별 검증자 목록 조회 (ValidatorReward에서 호출)
    function getL2Validators(address systemConfig) external view returns (address[] memory);

    // isValidatorActive는 위에서 이미 정의됨

    // ==========================================
    // V3 변경: 보상 관련 함수 제거
    // ==========================================
    // claimRewards, claimRewardsBatch, distributeValidatorReward는
    // ValidatorReward 컨트랙트로 이동됨
    // → IValidatorReward.claimAllRewards()
    // → IValidatorReward.distributeL2Rewards()

    // ==========================================
    // External Functions - Governance
    // ==========================================

    function setSlashingPenalty(uint256 penalty) external;
    function setValidatorBuffer(uint256 buffer) external;
    function setMinimumThreshold(uint256 threshold) external;
    function setRatTriggerProbability(uint256 probability) external;
    function setEvidenceSubmissionPeriod(uint256 period) external;
}
```

---

## 6. RAT.sol (핵심 함수)

> **참고**: 전체 구현 코드는 별도 파일로 작성됩니다. 여기서는 SystemConfig 기반 핵심 함수만 설명합니다.

### 6.1 검증자 등록 (V3: TON 직접 예치)

```solidity
/// @notice 검증자 등록
/// @dev V3: 검증자가 TON을 RAT에 직접 예치
/// @param systemConfig L2의 SystemConfig 주소
/// @param depositAmount 담보금 (TON)
function registerValidator(address systemConfig, uint256 depositAmount) external ifFree whenNotPaused {
    // TON 직접 전송 받기
    IERC20(ton).safeTransferFrom(msg.sender, address(this), depositAmount);
    _registerValidatorInternal(msg.sender, systemConfig, depositAmount);
}

/// @notice 내부 검증자 등록 로직
function _registerValidatorInternal(address validator, address systemConfig, uint256 depositAmount) internal {
    ValidatorRegistration storage reg = validatorRegistrations[systemConfig][validator];
    if (reg.isActive) revert AlreadyRegisteredError();

    uint256 minDeposit = getMinimumCollateral();

    // 기존 담보금이 있는 경우 (슬래싱 후 재등록)
    uint256 totalDeposit = reg.depositedAmount + depositAmount;
    if (totalDeposit < minDeposit) revert InsufficientDepositError();

    ValidatorPoolInfo storage pool = validatorPools[systemConfig];

    // 신규 등록인지 재등록인지 확인
    bool isReregistration = reg.depositedAmount > 0;

    if (isReregistration) {
        // 재등록: 풀에 재활성화
        pool.activeCount++;
        pool.totalDeposited += totalDeposit;
        reg.depositedAmount = totalDeposit;
        reg.isActive = true;
    } else {
        // 신규 등록
        uint256 index = pool.validators.length;
        pool.validators.push(validator);
        pool.activeCount++;
        pool.totalDeposited += totalDeposit;

        reg.depositedAmount = totalDeposit;
        reg.totalBondForRAT = 0;
        reg.pendingRewards = 0;
        reg.validatorIndex = uint32(index);
        reg.isActive = true;

        validatorIndexes[systemConfig][validator] = index;
        validatorSystemConfigs[validator].push(systemConfig);
    }

    emit ValidatorRegistered(validator, systemConfig, totalDeposit, reg.validatorIndex);
}
```

### 6.2 RAT 테스트 트리거 (선차감 메커니즘)

```solidity
/// @notice RAT 테스트 트리거
/// @dev 선택된 검증자의 담보금에서 C_off 선차감
function triggerAttentionTest(
    address gameAddress,
    address systemConfig,
    uint32 batchIndex,
    bytes32 batchHash,
    bytes32 blockHash
) external ifFree {
    // 권한 검증: L1BridgeRegistry에서 factory 확인
    _verifyFactory(msg.sender, systemConfig);

    // 확률 체크
    if (!_shouldTriggerRAT(blockHash)) return;

    // 검증자 랜덤 선택
    address selectedValidator = _selectRandomValidator(systemConfig, blockHash);
    if (selectedValidator == address(0)) return;

    ValidatorRegistration storage reg = validatorRegistrations[systemConfig][selectedValidator];

    // C_off 선차감
    uint256 bondAmount = slashingPenalty;
    if (reg.depositedAmount < bondAmount) {
        bondAmount = reg.depositedAmount;
    }

    reg.depositedAmount -= bondAmount;
    reg.totalBondForRAT += bondAmount;

    // 마감 시간 업데이트
    uint256 deadline = block.timestamp + evidenceSubmissionPeriod;
    if (deadline > reg.latestTestDeadline) {
        reg.latestTestDeadline = uint64(deadline);
    }

    // D_min 미만 시 비활성화
    if (reg.depositedAmount < minimumThreshold) {
        reg.isActive = false;
        validatorPools[systemConfig].activeCount--;
    }

    // 테스트 저장
    bytes32 testId = keccak256(abi.encodePacked(systemConfig, batchIndex));
    attentionTests[testId] = AttentionTest({
        validatorAddress: selectedValidator,
        systemConfig: systemConfig,
        batchIndex: batchIndex,
        batchHash: batchHash,
        bondAmount: bondAmount,
        createdAt: block.timestamp,
        deadline: deadline,
        status: AttentionTestStatus.Pending
    });

    gameToTestId[gameAddress] = testId;
    factoryByGame[gameAddress] = msg.sender;

    emit AttentionTestTriggered(testId, selectedValidator, systemConfig, gameAddress, batchIndex, deadline);
}
```

### 6.3 증거 제출 (복구 메커니즘)

```solidity
/// @notice RAT 증거 제출
/// @dev 증거 제출 시 담보금 복구
function submitEvidence(
    address systemConfig,
    uint32 batchIndex,
    bytes calldata evidence
) external ifFree {
    bytes32 testId = keccak256(abi.encodePacked(systemConfig, batchIndex));
    AttentionTest storage test = attentionTests[testId];

    if (test.validatorAddress != msg.sender) revert NotSelectedValidatorError();
    if (test.status != AttentionTestStatus.Pending) revert TestNotPendingError();
    if (block.timestamp > test.deadline) revert EvidenceDeadlinePassedError();

    // 증거 검증 (TBD: 구체적인 검증 로직)
    _verifyEvidence(test.batchHash, evidence);

    // 상태 업데이트
    test.status = AttentionTestStatus.Responded;

    // 담보금 복구
    ValidatorRegistration storage reg = validatorRegistrations[systemConfig][msg.sender];
    uint256 restoredAmount = test.bondAmount;

    reg.depositedAmount += restoredAmount;
    reg.totalBondForRAT -= restoredAmount;

    // 비활성 상태였고 D_min 이상이면 재활성화
    if (!reg.isActive && reg.depositedAmount >= minimumThreshold) {
        reg.isActive = true;
        validatorPools[systemConfig].activeCount++;
        emit ValidatorRestored(msg.sender, systemConfig);
    }

    emit EvidenceSubmitted(testId, msg.sender, systemConfig, batchIndex);
}
```

### 6.4 미응답 시 처리

**별도 슬래싱 함수 불필요** - RAT 트리거 시점에 이미 스테이킹 금액이 선차감되어 있으므로, 미응답 시 슬래싱이 자동 완료됩니다.

```
미응답 시 상태:
- 검증자.depositedAmount = 0 (이미 차감됨)
- 검증자.isActive = false (이미 비활성화됨)
- 담보금 = RAT 컨트랙트에 귀속
- 추가 트랜잭션 = 없음
```

### 6.5 챌린지 승리 시 담보금 복구 (resolveClaim)

검증자가 프로포저의 잘못된 증거를 발견하고 **챌린저로서 FaultDisputeGame에서 승리**하면, 게임 컨트랙트가 `resolveClaim`을 호출하여 담보금을 복구합니다.

```solidity
/// @notice FaultDisputeGame에서 게임 해결 시 호출 (챌린저 승리 시 담보금 복구)
/// @dev msg.sender = FaultDisputeGame 주소
/// @dev 담보금은 RAT 명의로 이미 스테이킹되어 있으므로 내부 기록만 복구
/// @param _claimant 게임에서 이긴 주소 (챌린저)
function resolveClaim(address _claimant) external {
    // msg.sender = 게임 주소로 테스트 조회
    bytes32 testId = gameToTestId[msg.sender];
    if (testId == bytes32(0)) return;  // 해당 게임의 RAT 테스트가 없음

    AttentionTest storage test = attentionTests[testId];

    // 선택된 검증자가 게임 승자와 같은지 확인
    if (test.validatorAddress != _claimant) return;
    if (test.evidenceSubmitted) return;  // 이미 처리됨

    // ★ C_off 복구
    test.evidenceSubmitted = true;
    uint256 restoredAmount = uint256(test.bondAmount);

    bytes32 regId = _getRegistrationId(_claimant, test.systemConfig);
    ValidatorRegistration storage reg = registrations[regId];

    // 잔액 복구
    reg.depositedAmount += restoredAmount;
    reg.totalBondForRAT -= restoredAmount;

    // ★ 검증자 세트 복구 - 비활성 상태였고 D_min 이상이면 다시 추가
    if (!reg.isActive && reg.depositedAmount >= minimumThreshold) {
        reg.isActive = true;
        reg.validatorIndex = uint32(activeValidators[test.systemConfig].length);
        activeValidators[test.systemConfig].push(_claimant);
        validatorPools[test.systemConfig].activeValidatorCount++;
    }

    address layer2 = _getLayer2FromSystemConfig(test.systemConfig);
    emit BondRestored(testId, _claimant, test.systemConfig, restoredAmount);
}
```

**FaultDisputeGame에서 호출 (Optimism 패턴):**

```solidity
// FaultDisputeGame.sol (Optimism)
function resolveClaimRat(address claimant) internal {
    if (rat != address(0)) {
        try IRAT(rat).resolveClaim(claimant) { } catch { }
    }
}

// resolveClaim() 함수 내에서 본드 분배 후 호출
function resolveClaim(uint256 _claimIndex, uint256 _numToResolve) external {
    // ... 게임 해결 로직 ...
    _distributeBond(winner, subgameRootClaim);
    resolveClaimRat(winner);  // RAT 콜백
}
```

**담보금 복구 경로 비교:**

| 경로 | 트리거 | 결과 |
|------|--------|------|
| **submitEvidence** | 검증자가 직접 증거 제출 | 담보금 복구 + 재활성화 |
| **resolveClaim** | FaultDisputeGame에서 챌린지 승리 | 담보금 복구 + 재활성화 |
| **미응답** | 응답 윈도우 경과 | 담보금 영구 몰수 |

**필요한 스토리지 추가:**

```solidity
/// @notice 게임 주소 → testId 매핑 (resolveClaim에서 사용)
mapping(address => bytes32) public gameToTestId;
```

**triggerAttentionTest에서 매핑 설정:**

```solidity
function triggerAttentionTest(...) external onlyLayer2Manager {
    // ... 기존 로직 ...

    // 게임 주소 → testId 매핑 저장 (resolveClaim에서 조회용)
    gameToTestId[gameAddress] = testId;

    // ...
}
```

**몰수된 자금 추적:**
- `AttentionTestTriggered` 발생 후 `EvidenceSubmitted` 또는 `BondRestored` 이벤트가 없으면 → 영구 몰수
- `AttentionTestTriggered` 발생 후 위 이벤트 중 하나라도 있으면 → 복구됨

### 6.6 검증자 보상 분배 (SeigManager → ValidatorReward)

> **V3 아키텍처 변경**: 검증자 보상 분배는 **ValidatorReward 컨트랙트**에서 담당합니다.
> RAT는 검증자 등록/담보금/슬래싱만 관리합니다.

**분배 흐름:**
```
SeigManager.updateSeigniorage()
    │
    ├─► L2별 검증자 몫 계산: α · S_i
    │
    └─► ValidatorReward.distributeL2Rewards(systemConfig, amount)
            │
            ├─► RAT.getL2Validators(systemConfig) - 검증자 목록 조회
            ├─► RAT.isValidatorActive() - 활성 상태 확인
            │
            ├─► |V_i| > 0: 활성 검증자에게 균등 분배
            └─► |V_i| = 0: DAO Treasury로 귀속

검증자.claimAllRewards() → WTON 수령
```

**RAT이 제공하는 조회 함수 (ValidatorReward용):**
```solidity
/// @notice L2별 검증자 목록 조회
function getL2Validators(address systemConfig) external view returns (address[] memory);

/// @notice 검증자 활성 상태 확인
function isValidatorActive(address validator, address systemConfig) external view returns (bool);

/// @notice 활성 검증자 수 조회
function getActiveValidatorCount(address systemConfig) external view returns (uint256);
```

> **상세 구현**: ValidatorReward 코드는 [08_implementation.md](./08_implementation.md) 참조

### 6.7 담보금 출금 (V3: 즉시 출금)

V3에서는 RAT 컨트랙트에서 TON을 직접 보관하므로, **즉시 출금**이 가능합니다 (2주 대기 없음).

```
┌──────────┐  deactivateValidator()  ┌──────────┐   TON 전송    ┌──────────┐
│ 검증자    │ ─────────────────────► │   RAT    │ ────────────► │ 검증자    │
└──────────┘                         └──────────┘  (즉시 출금)   └──────────┘
```

**출금 조건:**
- 활성 상태에서만 `deactivateValidator()` 호출 가능
- 진행 중인 RAT 테스트가 있으면 대기 필요 (`latestTestDeadline` 경과 후)
- 미응답 RAT 테스트의 담보금은 슬래싱 처리 (accumulatedSlashings 누적)

```solidity
/// @notice 검증자 탈퇴 및 즉시 출금
/// @dev V3: RAT에서 TON 직접 보관하므로 즉시 출금 가능 (2주 대기 불필요)
function deactivateValidator(address systemConfig) external ifFree {
    ValidatorRegistration storage reg = validatorRegistrations[systemConfig][msg.sender];
    if (!reg.isActive) revert NotActiveValidatorError();

    // 진행 중인 RAT 테스트가 있으면 대기 (deadline 경과 후에만 출금 가능)
    require(block.timestamp >= reg.latestTestDeadline, "pending RAT tests");

    // 미응답한 RAT 테스트의 totalBondForRAT는 손실 확정 (Lazy Evaluation)
    if (reg.totalBondForRAT > 0) {
        accumulatedSlashings += reg.totalBondForRAT;
        reg.totalBondForRAT = 0;
    }

    reg.isActive = false;

    // V3: TON 직접 전송 (즉시 출금)
    uint256 withdrawAmount = reg.depositedAmount;
    reg.depositedAmount = 0;
    if (withdrawAmount > 0) {
        IERC20(ton).safeTransfer(msg.sender, withdrawAmount);
    }

    // V3: 미청구 보상은 ValidatorReward에서 별도 청구
    // IValidatorReward(validatorReward).claimAllRewards() 호출 필요

    emit ValidatorDeactivated(msg.sender, systemConfig, withdrawAmount);
}
```

### 6.8 내부 유틸리티 함수

```solidity
/// @notice SystemConfig별 activeValidators 배열에서 검증자 제거
function _removeFromActiveValidators(
    address systemConfig,
    address validator,
    uint256 index
) internal {
    address[] storage validators = activeValidators[systemConfig];
    if (index > 0 && index < validators.length && validators[index] == validator) {
        uint256 lastIndex = validators.length - 1;
        if (index != lastIndex) {
            address lastValidator = validators[lastIndex];
            validators[index] = lastValidator;
            bytes32 regId = _getRegistrationId(lastValidator, systemConfig);
            registrations[regId].validatorIndex = uint32(index);
        }
        validators.pop();
    }
}
```

---

## 7. 통합 가이드

### 7.1 RAT 트리거 시점 및 인터페이스

RAT는 L2 프로포저(시퀀서)가 **DisputeGame을 생성할 때** 트리거됩니다.

```
┌─────────────────────────────────────────────────────────────┐
│  L2 프로포저 (op-proposer)                                   │
│                                                              │
│  1. Output Root 계산                                         │
│  2. DisputeGameFactory.create() 호출                         │
│     └─→ RAT.triggerAttentionTest() 호출                      │
└─────────────────────────────────────────────────────────────┘
```

**L2 프로포저용 RAT 트리거 인터페이스:**

```solidity
/// @title IRATTrigger
/// @notice L2 프로포저가 RAT 트리거를 위해 호출해야 하는 인터페이스
interface IRATTrigger {
    /// @notice RAT 테스트 트리거
    /// @dev DisputeGame 생성 시 호출
    /// @param gameAddress 생성된 DisputeGame 주소 (resolveClaim에서 testId 조회용)
    /// @param systemConfig L2의 SystemConfig 주소 (L2 식별자)
    /// @param batchIndex 배치/게임 인덱스
    /// @param batchHash 배치 해시 또는 Output Root
    /// @param blockHash 블록 해시 (검증자 랜덤 선택용)
    function triggerAttentionTest(
        address gameAddress,
        address systemConfig,
        uint32 batchIndex,
        bytes32 batchHash,
        bytes32 blockHash
    ) external;
}
```

### 7.2 DisputeGameFactory 통합

```solidity
// DisputeGameFactory.sol 수정 예시
contract DisputeGameFactory {
    address public rat;  // RAT 컨트랙트 주소

    function create(
        GameType _gameType,
        Claim _rootClaim,
        bytes calldata _extraData
    ) external returns (IDisputeGame proxy_) {
        // 기존 Dispute Game 생성 로직...
        proxy_ = _createGame(_gameType, _rootClaim, _extraData);

        // RAT 트리거 (실패해도 게임 생성은 성공)
        if (rat != address(0)) {
            address systemConfig = _getSystemConfig(); // 해당 L2의 SystemConfig
            try IRAT(rat).triggerAttentionTest(
                address(proxy_),           // gameAddress (생성된 게임 주소)
                systemConfig,
                uint32(gameCount),         // batchIndex
                _rootClaim.raw(),          // batchHash (Output Root)
                blockhash(block.number - 1)  // blockHash
            ) {} catch {}
        }
    }
}
```

### 7.3 TRH (Tokamak Rollup Hub) 가이드라인

1. **DisputeGame 생성 시 RAT 트리거 필수화**
   - 모든 L2 프로포저는 DisputeGame 생성 시 RAT.triggerAttentionTest() 호출
   - SystemConfig 주소를 키로 사용하여 해당 L2의 검증자 풀에서 선택

2. **SystemConfig 등록 요구**
   - L2 온보딩 시 Layer2Manager에 SystemConfig 등록
   - 등록된 SystemConfig만 RAT에서 유효

3. **트리거 실패 처리**
   - RAT 트리거 실패해도 DisputeGame 생성은 성공해야 함 (try-catch)
   - 검증자가 없거나 확률 미충족 시 RAT는 발생하지 않음

### 7.4 Layer2Manager 수정

```solidity
// Layer2ManagerV1_2.sol

import { IRAT } from "../validator/interfaces/IRAT.sol";

contract Layer2ManagerV1_2 {
    address public rat;

    function setRAT(address _rat) external onlyOwner {
        rat = _rat;
    }

    /// @notice 검증자 보상 분배 (시뇨리지 업데이트 시 호출)
    /// @param systemConfig L2의 SystemConfig 주소
    /// @param amount 검증자 몫 (α · S_i)
    function distributeValidatorReward(address systemConfig, uint256 amount) internal {
        if (rat != address(0) && amount > 0) {
            IERC20(wton).approve(rat, amount);
            IRAT(rat).distributeValidatorReward(systemConfig, amount);
        }
    }
}
```

### 7.5 SeigManagerV1_4 수정

검증자 보상은 각 L2의 시뇨리지 계산 시 함께 처리됩니다.

**백서 V3 공식 (13), (14):**
```
v_j = Σ_{i: j∈V_i} (α · S_i) / |V_i|    ... (13) 검증자 보상
o_i = (1 − α) · S_i                      ... (14) 시퀀서 보상

|V_i| = 0 이면 α · S_i → DAO Treasury
```

> **✅ V3 백서에서 해결됨**
>
> V3 백서(2025-12-16)에서 검증자 보상 분배 방식이 명확화되었습니다:
> - L2별 V_i (검증자 집합) 기반 분배
> - 검증자가 없는 L2(|V_i| = 0)의 경우 α·S_i → **DAO Treasury**

```solidity
// SeigManagerV1_4.sol

function updateSeigniorage() external {
    // ... 기존 시뇨리지 계산 로직 ...

    // 각 L2별 시뇨리지 분배
    for (uint256 i = 0; i < eligibleL2s.length; i++) {
        address systemConfig = eligibleL2s[i];

        // L2별 시뇨리지 계산: S_i = y(x) · (B̃_i / x)
        uint256 seigI = calculateL2Seigniorage(systemConfig);

        // 검증자 몫: α · S_i
        uint256 validatorAmount = rmul(seigI, validatorDistributionRatio);

        // 시퀀서 몫: (1 - α) · S_i
        uint256 sequencerAmount = seigI - validatorAmount;

        // 시퀀서에게 분배 (기존 로직)
        _distributeToSequencer(systemConfig, sequencerAmount);

        // 검증자에게 분배 (RAT 통해)
        // V3 백서: 검증자가 없으면 RAT에서 DAO Treasury로 전송
        if (validatorAmount > 0 && rat != address(0)) {
            IWTON(wton).mint(address(this), validatorAmount);
            IERC20(wton).approve(rat, validatorAmount);
            IRAT(rat).distributeValidatorReward(systemConfig, validatorAmount);
        }
    }
}
```

> **✅ V3 백서에서 해결됨: 검증자 없을 때 처리**
>
> V3 백서(2025-12-16)에서 명확화:
> L2에 검증자가 없으면(|V_i| = 0) 해당 L2의 검증자 몫(α · S_i)은 **DAO Treasury**로 전송됩니다.
> RAT.distributeValidatorReward()에서 자동 처리됨.

---

## 9. 배포 파라미터

### 9.1 백서 공식 기반 파라미터

**백서 공식 정리:**
```
(3) c_m ≤ (π_a / n) · C_off    - RAT 균형 조건
(4) C_off ≥ (c_m · n) / π_a    - 슬래싱 페널티 최소 조건
(5) D_validator = C_off + Δ_validator  - 검증자 담보금
```

| 파라미터 | 백서 기호 | 설명 |
|---------|----------|------|
| `attentionCost` | c_m | 에포크당 주의력 유지 비용 |
| `slashingPenalty` | C_off | RAT 미응답 시 슬래싱 페널티 |
| `validatorBuffer` | Δ_validator | 검증자 추가 버퍼 |
| `ratTriggerProbability` | π_a | RAT 트리거 확률 |
| `minimumThreshold` | D_min | 최소 담보금 임계값 (이 미만 시 검증자 세트에서 제거) |
| `evidenceSubmissionPeriod` | - | 증거 제출 기간 (블록 수, 백서 미명시) |

### 9.2 최소 담보금 계산

**백서 공식 (5):**
```solidity
/// @notice 최소 담보금 계산 (백서 공식 5)
/// @dev D_validator = C_off + Δ_validator
function getMinimumCollateral() public view returns (uint256) {
    return slashingPenalty + validatorBuffer;
}
```

### 9.3 C_off 유효성 검증

**백서 공식 (4):**
```solidity
/// @notice C_off가 백서 공식 (4)를 만족하는지 검증
/// @dev C_off ≥ (c_m · n) / π_a
/// @param n 검증자 수
function validateSlashingPenalty(uint256 n) public view returns (bool) {
    // C_off ≥ (c_m · n) / π_a
    // → C_off · π_a ≥ c_m · n
    return slashingPenalty * ratTriggerProbability >= attentionCost * n * RAY;
}
```

**검증자 수에 따른 C_off 최소값 예시:**
```
c_m = 0.01 TON (주의력 유지 비용)
π_a = 0.1 (10% 트리거 확률)
n = 10명 (검증자 수)

C_off ≥ (0.01 × 10) / 0.1 = 1 TON

n = 100명인 경우:
C_off ≥ (0.01 × 100) / 0.1 = 10 TON
```

> **주의**: 검증자 수(n)가 증가하면 C_off 최소 요구값도 증가합니다. 거버넌스는 검증자 수 변화에 따라 C_off를 조정해야 합니다.

---

## 10. 테스트 체크리스트

### 10.1 검증자 관리
- [ ] 검증자 등록 (최소 담보금 = C_off + Δ_validator 이상)
- [ ] 검증자 해제 및 출금
- [ ] D_min 미만 시 검증자 세트에서 자동 제거

### 10.2 RAT 테스트
- [ ] RAT 트리거 확률 (π_a) 검증
- [ ] 검증자 랜덤 선택 분포
- [ ] RAT 트리거 시 C_off 선차감 검증
- [ ] 증거 제출 성공 시 담보금 복구 검증
- [ ] 증거 제출 실패 (기간 초과) - 별도 트랜잭션 없이 슬래싱 완료 확인
- [ ] 챌린지 승리 시 resolveClaim으로 담보금 복구 확인

### 10.3 경제 파라미터
- [ ] validateSlashingPenalty(n): C_off ≥ (c_m · n) / π_a 검증
- [ ] getMinimumCollateral(): D_validator = C_off + Δ_validator 검증
- [ ] 검증자 수 변화에 따른 C_off 최소값 검증

### 10.4 보상 분배 (ValidatorReward)
- [ ] 검증자 보상 분배 V3: (α·S_i) / |V_i| - ValidatorReward.distributeL2Rewards()
- [ ] 검증자 없는 L2(|V_i| = 0): α·S_i → DAO Treasury
- [ ] 보상 청구 - ValidatorReward.claimAllRewards()
- [ ] Per-L2 보상 조회 - ValidatorReward.getPendingRewardsByL2()

### 10.5 기타
- [ ] 파라미터 변경 권한 (ratManager)
- [ ] 업그레이드 호환성
- [ ] 이벤트 기반 자금 추적 (AttentionTestTriggered/EvidenceSubmitted/BondRestored)

---

## 11. 관련 코드 파일

| 파일 | 설명 |
|------|------|
| `src/validator/RAT.sol` | RAT 메인 컨트랙트 - 검증자 등록/담보금/슬래싱 |
| `src/validator/ValidatorRewardV1.sol` | 검증자 보상 분배 |
| `src/validator/IRAT.sol` | RAT 인터페이스 |
| `src/validator/IValidatorReward.sol` | ValidatorReward 인터페이스 |
| `src/stake/managers/SeigManagerV1_4.sol` | V3 시뇨리지 분배 |

### 11.1 아키텍처 분리

```
RAT.sol                     ValidatorReward.sol
─────────────               ──────────────────
검증자 등록/탈퇴             검증자 보상 분배
담보금 관리                  Per-L2 보상 추적
RAT 테스트                   통합 보상 청구
C_off 슬래싱                 Treasury 귀속 처리
getL2Validators()  ────────► (조회용)
isValidatorActive() ────────► (조회용)
```

---

## 12. V3 백서 준수 확인

| 항목 | V3 백서 요구사항 | 구현 상태 |
|------|-----------------|----------|
| 공식 (13) | v_j = Σ_{i: j∈V_i} (α · S_i) / \|V_i\| | ✅ ValidatorRewardV1.distributeL2Rewards() |
| 공식 (14) | o_i = (1 − α) · S_i | ✅ SeigManagerV1_4 |
| V_i 개념 | L2별 검증자 집합 | ✅ RAT.validatorPools[systemConfig] |
| \|V_i\| = 0 처리 | α·S_i → DAO Treasury | ✅ ValidatorRewardV1 → treasury |
| 검증자 할당 | L2별 등록 | ✅ RAT.registerValidator(systemConfig, amount) |
| 보상 청구 | 통합 청구 | ✅ ValidatorRewardV1.claimAllRewards() |

---

## 13. 참고 문서

- `Tokamak_Economics_Whitepaper_V3.pdf` (December 16, 2025)
- [02_v3_distribution.md](./02_v3_distribution.md) - V3 분배 공식 상세
- [04_validator.md](./04_validator.md) - 검증자 보상 상세
- [08_implementation.md](./08_implementation.md) - 구현 코드

---

## 14. 변경 이력

| 날짜 | 내용 |
|------|------|
| 2025-12-18 | V3 백서 반영: 공식 (13), (14) 업데이트, \|V_i\|=0 처리 추가 |
