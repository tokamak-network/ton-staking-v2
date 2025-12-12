---
id: 07_rat_implementation
slug: /07_rat_implementation
---
# RAT 구현체 설계

## 1. 개요

이 문서는 Optimism의 RAT(Randomized Attention Test) 구현체를 참고하여 TON Staking V3용 RAT 시스템을 설계합니다.

> **참고**: Optimism RAT 원본 코드는 `tokamak-network/optimism/packages/contracts-bedrock/src/L1/RAT.sol`에 있습니다.

### 1.1 Optimism RAT vs TON V3 RAT 비교

| 항목 | Optimism RAT | TON V3 RAT (백서 V2) |
|------|-------------|----------------------|
| **스테이킹 자산** | ETH (native) | WTON (ERC20) |
| **담보금 관리** | RAT 컨트랙트에 직접 보관 | **DepositManager에 대리 스테이킹** |
| **트리거 시점** | Dispute Game 생성 시 | Dispute Game 생성 시 |
| **트리거 주체** | DisputeGameFactory | DisputeGameFactory |
| **검증자 범위** | 글로벌 (모든 게임) | **L2별 등록** |
| **증거 형식** | stateRoot의 left/right 자식 해시 | TBD (확인 필요) |
| **슬래싱 방식** | perTestBondAmount 선차감 | **C_off 선차감** (백서 V2: 슬래싱 페널티) |
| **슬래싱 귀속** | 컨트랙트에 잔류 | **TBD** (귀속처 미정) |
| **D_min 확인** | 없음 | D_min 미만 시 즉시 검증자 세트에서 제거 |
| **보상 시스템** | 없음 (본드 반환만) | 시뇨리지 분배 (α/n) · y(x) |
| **담보금 시뇨리지** | 없음 | 유지 담보금 시뇨리지 → 검증자, 몰수분 → TBD |

### 1.2 L2별 검증자 등록 방식

TON V3에서는 여러 L2가 존재하므로, 검증자가 **특정 L2에만 등록**할 수 있습니다.

```
검증자 A ──┬──→ Titan SystemConfig 등록 (담보금 5,000 WTON)
           └──→ Thanos SystemConfig 등록 (담보금 3,000 WTON)

검증자 B ──────→ Titan SystemConfig만 등록 (담보금 10,000 WTON)

검증자 C ──────→ Thanos SystemConfig만 등록 (담보금 2,000 WTON)
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
3. **Optimism 호환**: Optimism 아키텍처와 일관성 유지
4. **확장성**: 향후 SystemConfig의 다른 정보(batcher 등) 활용 가능

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
│ DepositManager│  │  SeigManager → Layer2Manager → OperatorManager │
│ (대리스테이킹) │  │  → RAT.distributeValidatorReward()             │
└───────────────┘  └──────────────────────────────────────────────┘
```

### 2.3 RAT 대리 스테이킹 흐름

```
검증자 등록:
┌──────────┐     WTON      ┌──────────┐    deposit()    ┌────────────────┐
│ 검증자    │ ──────────► │   RAT    │ ──────────────► │ DepositManager │
└──────────┘               └──────────┘                 │ (RAT 명의 예치) │
                                                        └────────────────┘
                                                               │
                                                               │ RAT 명의 스테이킹
                                                               │ (검증자 담보금 보호용)
                                                               ▼
RAT 트리거/복구/슬래싱 (내부 기록만):
┌──────────────────────────────────────────────────────────────────────┐
│  RAT 트리거 시:                                                       │
│    - 내부 기록: depositedAmount = 0                                  │
│    - DepositManager: 변경 없음 (RAT 명의 스테이킹 유지)               │
│                                                                      │
│  증거 제출/챌린지 승리 시:                                             │
│    - 내부 기록: depositedAmount 복구                                 │
│    - DepositManager: 변경 없음                                       │
│                                                                      │
│  미응답 시 (슬래싱):                                                   │
│    - 내부 기록: depositedAmount = 0 유지                             │
│    - DepositManager: 변경 없음 (RAT 명의로 계속 스테이킹)             │
│    - 검증자 출금 불가 → RAT 컨트랙트에 자동 귀속                      │
└──────────────────────────────────────────────────────────────────────┘
```

**핵심 설계:**
- 모든 RAT 동작은 내부 기록(`depositedAmount`)만 변경
- DepositManager 상호작용 없음 (등록/탈퇴 시에만)
- 미응답 시: 별도 함수 불필요, 검증자가 출금할 수 없으므로 자동 슬래싱

---

## 3. 데이터 구조

### 3.1 SystemConfig별 검증자 등록 (ValidatorRegistration)

```solidity
/// @notice SystemConfig별 검증자 등록 정보
/// @dev 키: keccak256(abi.encodePacked(validator, systemConfig))
/// @dev depositedAmount: RAT이 DepositManager에 대리 스테이킹한 금액
struct ValidatorRegistration {
    // Slot 1: 32 bytes
    uint256 depositedAmount;        // 현재 유효 담보금 (RAT이 대신 예치, 선차감 후 금액)

    // Slot 2: 32 bytes
    uint256 totalBondForRAT;        // 진행 중인 RAT 테스트들에 묶인 총 금액 (증거 제출 시 복구)

    // Slot 3: 32 bytes
    uint256 pendingRewards;         // 해당 SystemConfig(L2)에서 받은 검증자 보상 중 미청구 금액 (백서 공식 13: (α/n)·y(x))

    // Slot 4: 32 bytes
    uint256 coinageFactorAtDeposit; // 예치 시점의 coinage factor (시뇨리지 계산용, 재예치 시 현행화)

    // Slot 5: 13 bytes (packed)
    uint64 latestTestEndBlock;      // 가장 최근 RAT 테스트의 증거 제출 마감 블록 (출금 조건 체크용)
    uint32 validatorIndex;          // activeValidators 배열 내 인덱스
    bool isActive;                  // 활성 상태 여부
}
```

**대리 스테이킹 설계 이유:**
- 검증자가 직접 스테이킹하면 임의로 언스테이킹 가능 → 담보금 역할 상실
- RAT이 대리 스테이킹하면 검증자는 출금 불가 → 담보금 보호

**RAT 테스트 흐름:**
```
RAT 트리거 시:
  depositedAmount -= C_off
  totalBondForRAT += C_off
  latestTestEndBlock = max(latestTestEndBlock, block.number + evidenceSubmissionPeriod)

증거 제출 성공 시:
  depositedAmount += C_off
  totalBondForRAT -= C_off

미응답 시:
  (아무것도 안 함 - 이미 차감됨, lazy evaluation)

출금 시:
  require(block.number > latestTestEndBlock)  // 테스트 종료일이 지나야 출금 가능
  출금 가능 금액 = depositedAmount × (currentFactor / coinageFactorAtDeposit)
```

**시뇨리지 처리:**
- 유지한 담보금에 대한 시뇨리지 → 검증자에게 지급
- 몰수된 원금 + 시뇨리지 → **TBD** (귀속처 미정)

> **참고:** RAT 명의의 스테이킹은 L2 자격조건(S_i ≥ θ·B_i)에 기여하지 않습니다. S_i는 시퀀서(오퍼레이터) 명의의 스테이킹만 포함합니다.

### 3.2 SystemConfig별 검증자 풀 (ValidatorPool)

```solidity
/// @notice SystemConfig별 검증자 풀 정보
/// @dev 키: systemConfig 주소
struct ValidatorPool {
    // Slot 1: 32 bytes
    uint256 totalPrincipal;         // 해당 L2에 총 스테이킹 원금

    // Slot 2: 4 bytes
    uint32 activeValidatorCount;    // 해당 L2의 활성 검증자 수
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
mapping(address => ValidatorPool) public validatorPools;

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

### 3.5 Optimism vs TON V3 스토리지 비교

| Optimism | TON V3 | 설명 |
|----------|--------|------|
| `challengers[addr]` | `registrations[hash]` | (validator, systemConfig) 복합 키 |
| `attentionTests[game]` | `attentionTests[testId]` | (systemConfig, batchIndex) 복합 키 |
| - | `gameToTestId[game]` | 게임 주소 → testId 매핑 (resolveClaim용) |
| `validChallengers[]` | `activeValidators[systemConfig][]` | SystemConfig별 활성 검증자 배열 |
| - | `validatorPools[systemConfig]` | SystemConfig별 풀 정보 |
| - | `validatorSystemConfigs[addr]` | 검증자가 등록한 SystemConfig 목록 |

---

## 4. RATStorage.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// @title RATStorage
/// @notice RAT 컨트랙트의 스토리지 레이아웃 (SystemConfig별 검증자 등록 방식)
/// @dev Layer2Manager에서 SystemConfig(롤업 컨피그)로 L2를 식별
/// @dev 담보금은 DepositManager에 대리 스테이킹
abstract contract RATStorage {
    // ============================================
    // 구조체 정의
    // ============================================

    /// @notice SystemConfig별 검증자 등록 정보
    /// @dev depositedAmount: RAT이 DepositManager에 대리 스테이킹한 금액 (선차감 후 금액)
    struct ValidatorRegistration {
        uint256 depositedAmount;        // 현재 유효 담보금 (RAT이 대신 예치, 선차감 후 금액)
        uint256 totalBondForRAT;        // 진행 중인 RAT 테스트들에 묶인 총 금액 (증거 제출 시 복구)
        uint256 pendingRewards;         // 해당 SystemConfig(L2)에서 받은 검증자 보상 중 미청구 금액
        uint256 coinageFactorAtDeposit; // 예치 시점의 coinage factor (시뇨리지 계산용, 재예치 시 현행화)
        uint64 latestTestEndBlock;      // 가장 최근 RAT 테스트의 증거 제출 마감 블록 (출금 조건 체크용)
        uint32 validatorIndex;          // activeValidators 배열 내 인덱스
        bool isActive;                  // 활성 상태 여부
    }

    /// @notice SystemConfig별 검증자 풀 정보
    struct ValidatorPool {
        uint256 totalPrincipal;         // 해당 L2에 총 스테이킹 원금
        uint32 activeValidatorCount;    // 해당 L2의 활성 검증자 수
    }

    /// @notice RAT 테스트 정보
    /// @dev 선차감-복구 메커니즘: slashed 필드 불필요 (트리거 시 이미 차감됨)
    struct AttentionTest {
        bytes32 expectedHash;           // 검증해야 할 배치 해시
        uint96 bondAmount;              // 복구용 금액 기록 (전체 담보금)
        address validatorAddress;       // 선택된 검증자 주소
        address systemConfig;           // L2 SystemConfig 주소
        uint64 blockNumber;             // RAT 발행 블록
        bool evidenceSubmitted;         // 증거 제출 여부
        // slashed 필드 제거됨
    }


    // ============================================
    // SystemConfig별 검증자 등록
    // ============================================

    /// @notice (validator, systemConfig) → 등록 정보
    /// @dev registrationId = keccak256(abi.encodePacked(validator, systemConfig))
    mapping(bytes32 => ValidatorRegistration) public registrations;

    /// @notice systemConfig → 검증자 풀 정보
    mapping(address => ValidatorPool) public validatorPools;

    /// @notice systemConfig → 활성 검증자 배열 (인덱스 0은 더미)
    mapping(address => address[]) public activeValidators;

    /// @notice 검증자 → 등록한 SystemConfig 목록
    mapping(address => address[]) public validatorSystemConfigs;

    /// @notice (validator, systemConfig) → 등록 여부 (중복 등록 방지)
    mapping(address => mapping(address => bool)) public isRegistered;

    /// @notice L1BridgeRegistry 주소 (SystemConfig 유효성 검증용)
    address public l1BridgeRegistry;

    // ============================================
    // RAT 테스트
    // ============================================

    /// @notice testId → RAT 테스트 정보
    /// @dev testId = keccak256(abi.encodePacked(systemConfig, batchIndex))
    mapping(bytes32 => AttentionTest) public attentionTests;

    /// @notice 게임 주소 → testId 매핑 (resolveClaim에서 사용)
    /// @dev FaultDisputeGame 주소로 해당 게임의 RAT 테스트를 조회
    mapping(address => bytes32) public gameToTestId;

    // ============================================
    // 출금 큐
    // ============================================

    /// @notice 출금 요청 정보 (큐 방식)
    struct UnstakeRequest {
        address validator;          // 검증자 주소
        address systemConfig;       // SystemConfig 주소
        uint256 amount;             // 출금 요청 금액 (원금 + 시뇨리지)
        uint256 principal;          // 원금 (시뇨리지 계산용)
        bool completed;             // 출금 완료 여부
    }

    /// @notice 출금 요청 큐
    UnstakeRequest[] public unstakeQueue;

    /// @notice 다음 처리할 큐 인덱스 (0부터 시작)
    uint256 public nextUnstakeIndex;

    /// @notice (validator, systemConfig) → 출금 요청 큐 인덱스 (본인 출금 인덱스 조회용)
    /// @dev registrationId = keccak256(abi.encodePacked(validator, systemConfig))
    mapping(bytes32 => uint256) public unstakeQueueIndex;

    // ============================================
    // 파라미터
    // ============================================

    /// @notice 증거 제출 기간 (블록 수)
    uint256 public evidenceSubmissionPeriod;

    /// @notice 백서 공식 (3), (4), (5) 파라미터
    /// @dev (3) c_m ≤ (π_a / n) · C_off  - RAT 균형 조건
    /// @dev (4) C_off ≥ (c_m · n) / π_a  - 슬래싱 페널티 최소 조건
    /// @dev (5) D_validator = C_off + Δ_validator  - 검증자 담보금
    uint256 public attentionCost;            // c_m: 에포크당 주의력 유지 비용
    uint256 public slashingPenalty;          // C_off: 슬래싱 페널티 (RAT 미응답 시 차감)
    uint256 public validatorBuffer;          // Δ_validator: 추가 버퍼

    /// @notice RAT 트리거 확률 (0-1e27, RAY 단위)
    /// @dev π_a: 시스템 전체 RAT 트리거 확률
    uint256 public ratTriggerProbability;

    /// @notice 최소 담보금 임계값 (D_min)
    /// @dev 담보금이 이 값 미만이면 검증자 세트에서 제거
    uint256 public minimumThreshold;

    // 참고: perTestBondAmount 제거됨 - 선차감 메커니즘에서 C_off 사용 (백서 공식 4)

    // ============================================
    // 외부 컨트랙트 참조
    // ============================================

    /// @notice Layer2Manager 주소 (SystemConfig 검증 및 트리거 권한)
    address public layer2Manager;

    /// @notice WTON 토큰 주소
    address public wton;

    /// @notice DAO 재무 주소 (슬래싱 귀속)
    address public dao;

    /// @notice SeigManager 주소 (보상 분배)
    address public seigManager;

    /// @notice RAT 매니저 주소 (파라미터 조정 권한)
    address public ratManager;

    // ============================================
    // 유틸리티 함수
    // ============================================

    /// @notice registrationId 계산
    function _getRegistrationId(address validator, address systemConfig) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(validator, systemConfig));
    }

    /// @notice testId 계산
    function _getTestId(address systemConfig, uint32 batchIndex) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(systemConfig, batchIndex));
    }

    /// @notice SystemConfig → Layer2 주소 조회 (이벤트 발생 시 사용)
    /// @dev Layer2Manager에서 매핑 정보 조회
    function _getLayer2FromSystemConfig(address systemConfig) internal view returns (address) {
        return ILayer2Manager(layer2Manager).getLayer2BySystemConfig(systemConfig);
    }

    /// @notice 스토리지 갭 (업그레이드 대비)
    uint256[40] private __gap;
}

/// @notice Layer2Manager 인터페이스 (SystemConfig → Layer2 조회용)
interface ILayer2Manager {
    function getLayer2BySystemConfig(address systemConfig) external view returns (address);
}

/// @notice L1BridgeRegistry 인터페이스 (SystemConfig 유효성 검증용)
interface IL1BridgeRegistry {
    function checkL1Bridge(address rollupConfig) external view returns (bool valid, address l1Bridge, address portal, address l2Ton);
}

/// @notice SeigManager 인터페이스 (coinage factor 조회용)
interface ISeigManager {
    function getCoinage(address layer2) external view returns (RefactorCoinageSnapshotI);
}

/// @notice Coinage 인터페이스 (factor 조회용)
interface RefactorCoinageSnapshotI {
    function factor() external view returns (uint256);
}
```

---

## 5. IRAT.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// @title IRAT
/// @notice RAT (Randomized Attention Test) 인터페이스 - L2별 검증자 등록 방식
interface IRAT {
    // ============================================
    // 구조체
    // ============================================

    /// @notice SystemConfig별 검증자 등록 정보
    struct ValidatorRegistration {
        uint256 depositedAmount;        // 현재 유효 담보금 (선차감 후 금액)
        uint256 totalBondForRAT;        // 진행 중인 RAT 테스트들에 묶인 총 금액
        uint256 pendingRewards;         // 미청구 검증자 보상
        uint256 coinageFactorAtDeposit; // 예치 시점의 coinage factor
        uint64 latestTestEndBlock;      // 가장 최근 RAT 테스트의 증거 제출 마감 블록
        uint32 validatorIndex;          // activeValidators 배열 내 인덱스
        bool isActive;                  // 활성 상태 여부
    }

    /// @notice SystemConfig별 검증자 풀 정보
    struct ValidatorPool {
        uint256 totalPrincipal;
        uint32 activeValidatorCount;
    }

    /// @notice RAT 테스트 정보
    /// @dev 선차감-복구 메커니즘: slashed 필드 불필요
    struct AttentionTest {
        bytes32 expectedHash;
        uint96 bondAmount;          // 복구용 금액 기록 (전체 담보금)
        address validatorAddress;
        address systemConfig;
        uint64 blockNumber;
        bool evidenceSubmitted;
        // slashed 필드 제거됨
    }

    // ============================================
    // 이벤트
    // ============================================
    // 참고: 모든 이벤트에 layer2 주소 포함 (Layer2Manager에서 systemConfig로 조회)

    /// @notice SystemConfig(L2)에 검증자 등록 이벤트
    event ValidatorRegistered(
        address indexed validator,
        address indexed systemConfig,
        address indexed layer2,        // Layer2 Candidate 주소
        uint256 amount
    );

    /// @notice SystemConfig(L2)에서 검증자 해제 이벤트
    event ValidatorUnregistered(
        address indexed validator,
        address indexed systemConfig,
        address layer2,                // Layer2 Candidate 주소
        uint256 returnedAmount
    );

    /// @notice SystemConfig(L2)에 추가 스테이킹 이벤트
    event StakeAdded(
        address indexed validator,
        address indexed systemConfig,
        address layer2,                // Layer2 Candidate 주소
        uint256 amount
    );

    /// @notice RAT 테스트 트리거 이벤트
    event AttentionTestTriggered(
        bytes32 indexed testId,
        address indexed validator,
        address indexed systemConfig,
        address gameAddress,           // DisputeGame 주소 (resolveClaim용)
        uint32 batchIndex,
        uint256 deadline
    );

    /// @notice 증거 제출 성공 이벤트
    event EvidenceSubmitted(
        bytes32 indexed testId,
        address indexed systemConfig,
        address indexed layer2,        // Layer2 Candidate 주소
        address validator,
        uint256 restoredAmount
    );

    /// @notice 챌린지 승리로 담보금 복구 이벤트 (resolveClaim)
    event BondRestored(
        bytes32 indexed testId,
        address indexed validator,
        address indexed systemConfig,
        uint256 restoredAmount
    );

    /// @notice 검증자 슬래싱 이벤트
    event ValidatorSlashed(
        bytes32 indexed testId,
        address indexed systemConfig,
        address indexed layer2,        // Layer2 Candidate 주소
        address validator,
        uint256 slashedAmount
    );

    /// @notice SystemConfig별 보상 분배 이벤트
    event RewardDistributed(
        address indexed systemConfig,
        address indexed layer2,        // Layer2 Candidate 주소
        uint256 totalAmount
    );

    /// @notice 보상 청구 이벤트
    event RewardClaimed(
        address indexed validator,
        address indexed systemConfig,
        address layer2,                // Layer2 Candidate 주소
        uint256 amount
    );

    /// @notice 출금 요청 이벤트
    event UnstakeRequested(
        address indexed validator,
        address indexed systemConfig,
        uint256 amount,
        uint256 queueIndex             // 큐 인덱스
    );

    /// @notice 출금 처리 완료 이벤트 (요청자 본인에게 바로 전송)
    event UnstakeProcessed(
        address indexed validator,
        address indexed systemConfig,
        address layer2,                // Layer2 Candidate 주소
        uint256 totalWithdrawn,        // 원금 + 시뇨리지
        uint256 seigniorage            // 시뇨리지 금액
    );


    // ============================================
    // 에러
    // ============================================

    error NotLayer2Manager();
    error NotSeigManager();
    error NotRatManager();
    error InvalidSystemConfig();
    error AlreadyRegistered();
    error NotRegistered();
    error ValidatorNotActive();
    error InsufficientDepositedAmount();
    error NoActiveValidators();
    error TestNotExists();
    error NotSelectedValidator();
    error EvidenceAlreadySubmitted();
    error EvidenceSubmissionExpired();
    error ProofVerificationFailed();
    error AlreadySlashed();
    error DeadlineNotPassed();
    error NoRewardsToClaim();

    // ============================================
    // SystemConfig별 검증자 관리 함수
    // ============================================

    /// @notice SystemConfig(L2)에 검증자 등록
    /// @param systemConfig 등록할 L2의 SystemConfig 주소
    /// @param amount 스테이킹할 WTON 금액
    function registerValidator(address systemConfig, uint256 amount) external;

    /// @notice SystemConfig(L2)에서 검증자 해제 (담보금 + 보상 반환)
    /// @param systemConfig 해제할 L2의 SystemConfig 주소
    function unregisterValidator(address systemConfig) external;

    /// @notice SystemConfig별 검증자 등록 정보 조회
    /// @param validator 검증자 주소
    /// @param systemConfig L2의 SystemConfig 주소
    function getRegistration(address validator, address systemConfig)
        external view returns (ValidatorRegistration memory);

    /// @notice SystemConfig의 검증자 풀 정보 조회
    /// @param systemConfig L2의 SystemConfig 주소
    function getValidatorPool(address systemConfig)
        external view returns (ValidatorPool memory);

    /// @notice SystemConfig의 활성 검증자 수 조회
    /// @param systemConfig L2의 SystemConfig 주소
    function getActiveValidatorCount(address systemConfig) external view returns (uint256);

    /// @notice 검증자가 등록한 SystemConfig 목록 조회
    /// @param validator 검증자 주소
    function getValidatorSystemConfigs(address validator) external view returns (address[] memory);

    // ============================================
    // RAT 테스트 함수
    // ============================================

    /// @notice RAT 테스트 트리거 (Layer2Manager 전용)
    /// @dev 해당 SystemConfig에 등록된 검증자 중에서만 선택
    /// @param gameAddress 생성된 DisputeGame 주소 (resolveClaim에서 testId 조회용)
    /// @param systemConfig L2의 SystemConfig 주소
    /// @param batchIndex 배치 인덱스
    /// @param batchHash 배치 해시
    /// @param blockHash 블록 해시 (검증자 선택용)
    function triggerAttentionTest(
        address gameAddress,
        address systemConfig,
        uint32 batchIndex,
        bytes32 batchHash,
        bytes32 blockHash
    ) external;

    /// @notice 증거 제출 - 전체 담보금 복구
    /// @param systemConfig L2의 SystemConfig 주소
    /// @param batchIndex 배치 인덱스
    /// @param proofData 증거 데이터
    function submitEvidence(
        address systemConfig,
        uint32 batchIndex,
        bytes calldata proofData
    ) external;

    /// @notice FaultDisputeGame에서 게임 해결 시 호출 (챌린저 승리 시 담보금 복구)
    /// @param _claimant 게임에서 이긴 주소 (챌린저)
    /// @dev msg.sender = FaultDisputeGame 주소
    function resolveClaim(address _claimant) external;

    /// @notice RAT 테스트 정보 조회
    function getAttentionTest(bytes32 testId) external view returns (AttentionTest memory);

    // ============================================
    // 보상 함수
    // ============================================

    /// @notice 검증자 보상 분배 (SeigManager 전용)
    /// @dev SeigManager.updateSeigniorage()에서 검증자 몫(α · S_i)을 계산한 후 호출
    /// @param systemConfig L2의 SystemConfig 주소
    /// @param amount 검증자 몫 (α · S_i)
    function distributeValidatorReward(address systemConfig, uint256 amount) external;

    /// @notice SystemConfig별 보상 청구
    /// @param systemConfig L2의 SystemConfig 주소
    function claimRewards(address systemConfig) external;

    /// @notice SystemConfig별 미청구 보상 조회
    /// @param validator 검증자 주소
    /// @param systemConfig L2의 SystemConfig 주소
    function getPendingRewards(address validator, address systemConfig) external view returns (uint256);

    /// @notice 여러 SystemConfig에서 보상 일괄 청구 (배치)
    /// @dev 가스비 예측을 위해 호출자가 직접 SystemConfig 목록 지정
    /// @param systemConfigs 청구할 SystemConfig 주소 배열
    function claimRewardsBatch(address[] calldata systemConfigs) external;

    /// @notice 검증자가 등록한 모든 SystemConfig의 미청구 보상 총합 조회
    /// @param validator 검증자 주소
    function getTotalPendingRewards(address validator) external view returns (uint256 total);

    // ============================================
    // 출금 함수
    // ============================================

    /// @notice 담보금 출금 요청 (비활성 상태에서만 가능, 전액 출금만 가능)
    /// @param systemConfig L2의 SystemConfig 주소
    /// @return queueIndex 출금 요청이 추가된 큐 인덱스
    function requestUnstake(address systemConfig) external returns (uint256 queueIndex);

    /// @notice 출금 완료 처리
    /// @dev 본인 인덱스로 호출. 이미 완료 상태면 바로 전송, 아니면 일괄 처리 후 전송
    /// @param myIndex 본인의 출금 요청 큐 인덱스
    function processUnstakes(uint256 myIndex) external;

    /// @notice 출금 큐 길이 조회
    function getUnstakeQueueLength() external view returns (uint256);

    /// @notice 출금 요청 정보 조회
    /// @param index 큐 인덱스
    function getUnstakeRequest(uint256 index) external view returns (
        address validator,
        address systemConfig,
        uint256 amount,
        uint256 principal,
        bool completed
    );

    /// @notice 검증자의 출금 요청 큐 인덱스 조회
    /// @param validator 검증자 주소
    /// @param systemConfig L2의 SystemConfig 주소
    function getUnstakeQueueIndex(address validator, address systemConfig) external view returns (uint256);

    // ============================================
    // 파라미터 관리 함수
    // ============================================

    /// @notice 증거 제출 기간 설정
    function setEvidenceSubmissionPeriod(uint256 period) external;

    /// @notice 주의력 유지 비용 설정 (c_m)
    function setAttentionCost(uint256 cost) external;

    /// @notice 슬래싱 페널티 설정 (C_off)
    /// @dev 백서 공식 (4): C_off ≥ (c_m · n) / π_a
    function setSlashingPenalty(uint256 penalty) external;

    /// @notice 검증자 버퍼 설정 (Δ_validator)
    function setValidatorBuffer(uint256 buffer) external;

    /// @notice RAT 트리거 확률 설정 (π_a)
    function setRatTriggerProbability(uint256 probability) external;

    /// @notice 최소 담보금 임계값 설정 (D_min)
    function setMinimumThreshold(uint256 threshold) external;

    /// @notice 최소 담보금 조회 (백서 공식 5)
    /// @dev D_validator = C_off + Δ_validator
    function getMinimumCollateral() external view returns (uint256);

    /// @notice C_off 최소 요구값 검증 (백서 공식 4)
    /// @dev C_off ≥ (c_m · n) / π_a
    /// @param n 검증자 수
    function validateSlashingPenalty(uint256 n) external view returns (bool);
}
```

---

## 6. RAT.sol (핵심 함수)

> **참고**: 전체 구현 코드는 별도 파일로 작성됩니다. 여기서는 SystemConfig 기반 핵심 함수만 설명합니다.

### 6.1 SystemConfig별 검증자 등록

```solidity
/// @notice SystemConfig(L2)에 검증자 등록
/// @dev RAT이 DepositManager에 대리 스테이킹
/// @param systemConfig 등록할 L2의 SystemConfig 주소
/// @param amount 스테이킹할 WTON 금액
function registerValidator(address systemConfig, uint256 amount) external nonReentrant {
    // L1BridgeRegistry를 통해 SystemConfig 유효성 확인
    (bool valid,,) = IL1BridgeRegistry(l1BridgeRegistry).checkL1Bridge(systemConfig);
    if (!valid) revert InvalidSystemConfig();

    // 해당 SystemConfig에 이미 등록되어 있는지 확인
    if (isRegistered[msg.sender][systemConfig]) {
        bytes32 regId = _getRegistrationId(msg.sender, systemConfig);
        ValidatorRegistration storage existingReg = registrations[regId];

        // 활성 상태가 아니고, 진행 중인 RAT 테스트가 없으면 재등록 허용
        if (existingReg.isActive || existingReg.totalBondForRAT > 0) {
            revert AlreadyRegistered();
        }

        // 비활성화되고 RAT 테스트도 없으면 재등록 허용
        isRegistered[msg.sender][systemConfig] = false;
    }

    // 최소 스테이킹 금액 확인
    require(amount >= getMinimumCollateral(), "Below minimum");

    // WTON 전송 (사전에 approve 필요)
    IERC20(wton).transferFrom(msg.sender, address(this), amount);

    // ★ RAT이 DepositManager에 대리 스테이킹
    address layer2 = _getLayer2FromSystemConfig(systemConfig);
    IERC20(wton).approve(depositManager, amount);
    IDepositManager(depositManager).deposit(layer2, address(this), amount);

    // 예치 시점의 coinage factor 저장 (시뇨리지 계산용)
    RefactorCoinageSnapshotI coinage = ISeigManager(seigManager).getCoinage(layer2);
    uint256 currentFactor = coinage.factor();

    // registrationId 생성
    bytes32 regId = _getRegistrationId(msg.sender, systemConfig);

    // 등록 정보 저장
    registrations[regId] = ValidatorRegistration({
        depositedAmount: amount,        // RAT이 대신 예치한 금액
        totalBondForRAT: 0,             // 진행 중인 RAT 테스트 없음
        pendingRewards: 0,
        coinageFactorAtDeposit: currentFactor,  // 예치 시점의 factor 저장
        validatorIndex: uint32(activeValidators[systemConfig].length),
        isActive: true
    });

    // 매핑 업데이트
    isRegistered[msg.sender][systemConfig] = true;
    validatorSystemConfigs[msg.sender].push(systemConfig);

    // 풀에 추가
    if (activeValidators[systemConfig].length == 0) {
        activeValidators[systemConfig].push(address(0)); // 더미
    }
    activeValidators[systemConfig].push(msg.sender);

    // 풀 정보 업데이트
    validatorPools[systemConfig].totalPrincipal += amount;
    validatorPools[systemConfig].activeValidatorCount++;

    emit ValidatorRegistered(msg.sender, systemConfig, layer2, amount);
}
```

### 6.2 RAT 테스트 트리거 (선차감 메커니즘)

```solidity
/// @notice RAT 테스트 트리거 - 내부 기록만 변경 (담보금은 RAT 명의로 스테이킹 유지)
/// @dev 해당 SystemConfig에 등록된 검증자 중에서만 선택
/// @dev 담보금은 DepositManager에 RAT 명의로 계속 스테이킹되어 있음
/// @param gameAddress 생성된 DisputeGame 주소 (resolveClaim에서 testId 조회용)
function triggerAttentionTest(
    address gameAddress,
    address systemConfig,
    uint32 batchIndex,
    bytes32 batchHash,
    bytes32 blockHash
) external onlyAuthorizedTrigger {
    // L1BridgeRegistry를 통해 SystemConfig 유효성 확인
    (bool valid,,) = IL1BridgeRegistry(l1BridgeRegistry).checkL1Bridge(systemConfig);
    if (!valid) revert InvalidSystemConfig();

    // 확률 체크
    if (!_shouldTriggerRAT()) return;

    // 해당 SystemConfig의 활성 검증자 체크
    address[] storage validators = activeValidators[systemConfig];
    uint256 validatorCount = validators.length;
    if (validatorCount <= 1) return; // 더미 제외하고 0명이면 리턴

    // 검증자 랜덤 선택 (해당 SystemConfig 풀에서만)
    uint256 selectedIndex = validatorCount == 2
        ? 1
        : ((uint256(keccak256(abi.encodePacked(blockHash, block.timestamp))) & 0xFFFF)
            % (validatorCount - 1)) + 1;

    address selectedValidator = validators[selectedIndex];
    bytes32 regId = _getRegistrationId(selectedValidator, systemConfig);
    ValidatorRegistration storage reg = registrations[regId];
    address layer2 = _getLayer2FromSystemConfig(systemConfig);

    // ★ C_off 선차감 (백서 공식 4: 슬래싱 페널티)
    uint256 slashAmount = slashingPenalty;
    if (reg.depositedAmount < slashAmount) {
        slashAmount = reg.depositedAmount;  // 잔액이 C_off 미만이면 전액
    }

    // ★ 내부 기록 변경 (선차감-복구 메커니즘)
    reg.depositedAmount -= slashAmount;
    reg.totalBondForRAT += slashAmount;

    // ★ 최신 테스트 종료 블록 업데이트 (출금 조건 체크용)
    uint64 testEndBlock = uint64(block.number + evidenceSubmissionPeriod);
    if (testEndBlock > reg.latestTestEndBlock) {
        reg.latestTestEndBlock = testEndBlock;
    }

    // ★ D_min 확인 - 잔액이 D_min 미만이면 즉시 검증자 세트에서 제거
    if (reg.depositedAmount < minimumThreshold) {
        reg.isActive = false;
        validatorPools[systemConfig].activeValidatorCount--;
        _removeFromActiveValidators(systemConfig, selectedValidator, reg.validatorIndex);
    }

    // 테스트 ID 생성 (systemConfig + batchIndex)
    bytes32 testId = _getTestId(systemConfig, batchIndex);

    // RAT 테스트 저장
    attentionTests[testId] = AttentionTest({
        expectedHash: batchHash,
        bondAmount: uint96(slashAmount),  // 복구용 금액 기록 (C_off)
        validatorAddress: selectedValidator,
        systemConfig: systemConfig,
        blockNumber: uint64(block.number),
        evidenceSubmitted: false
    });

    // ★ 게임 주소 → testId 매핑 저장 (resolveClaim에서 조회용)
    gameToTestId[gameAddress] = testId;

    emit AttentionTestTriggered(testId, selectedValidator, systemConfig, gameAddress, batchIndex, testEndBlock);
}
```

### 6.3 증거 제출 (복구 메커니즘)

```solidity
/// @notice 증거 제출 - 내부 기록 복구 (DepositManager 상호작용 없음)
/// @dev 담보금은 RAT 명의로 이미 스테이킹되어 있으므로 내부 기록만 복구
function submitEvidence(
    address systemConfig,
    uint32 batchIndex,
    bytes calldata proofData
) external {
    bytes32 testId = _getTestId(systemConfig, batchIndex);
    AttentionTest storage test = attentionTests[testId];

    // 검증
    if (test.validatorAddress == address(0)) revert TestNotExists();
    if (test.validatorAddress != msg.sender) revert NotSelectedValidator();
    if (test.evidenceSubmitted) revert EvidenceAlreadySubmitted();

    uint256 deadline = test.blockNumber + evidenceSubmissionPeriod;
    if (block.number > deadline) revert EvidenceSubmissionExpired();

    // 증거 검증 (TBD: 구체적인 검증 로직 확인 필요)
    // 현재는 proofData의 해시와 expectedHash를 비교하지만, 실제 구현 시 더 정교한 검증이 필요할 수 있음
    if (keccak256(proofData) != test.expectedHash) revert ProofVerificationFailed();

    // ★ C_off 복구
    test.evidenceSubmitted = true;
    uint256 restoredAmount = uint256(test.bondAmount);

    bytes32 regId = _getRegistrationId(msg.sender, systemConfig);
    ValidatorRegistration storage reg = registrations[regId];

    // 잔액 복구
    reg.depositedAmount += restoredAmount;
    reg.totalBondForRAT -= restoredAmount;

    // ★ 검증자 세트 복구 - 비활성 상태였고 D_min 이상이면 다시 추가
    if (!reg.isActive && reg.depositedAmount >= minimumThreshold) {
        reg.isActive = true;
        reg.validatorIndex = uint32(activeValidators[systemConfig].length);
        activeValidators[systemConfig].push(msg.sender);
        validatorPools[systemConfig].activeValidatorCount++;
    }

    address layer2 = _getLayer2FromSystemConfig(systemConfig);
    emit EvidenceSubmitted(testId, systemConfig, layer2, msg.sender, restoredAmount);
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

> **참고**: Optimism RAT.sol의 `resolveClaim` 함수를 참고하여 구현 (Lines 322-354)

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

### 6.6 검증자 보상 분배 (SeigManager → RAT)

**백서 공식 (13):**
```
v_i = (α/n) · y(x),    o_i = (1 - α) · S_i
```

> **TBD: 검증자 보상 분배 방식**
>
> 백서 공식 (13)의 `v_i = (α/n) · y(x)` 해석이 모호합니다:
> - 해석 1: 전체 y(x)에서 균등 분배 (모든 검증자 동일 보상)
> - 해석 2: L2별 S_i에서 분배 (L2 성과에 따라 다른 보상)
>
> **현재 구현:** L2별 성과(S_i)에 따라 분배 (해석 2)
> 백서 Figure 3에서 Validator가 L2별 TVL 구간에서 분배받는 것으로 표시되어 있어 이 해석을 채택합니다.
> 추후 백서 확정 시 재검토 필요.

**분배 흐름 (L2별 분배):**
```
┌─────────────────────────────────────────────────────────────────────┐
│  1. SeigManager.updateSeigniorage()                                 │
│     - 각 L2별 시뇨리지 계산: S_i = y(x) · (B̃_i / x)                 │
│     - L2별 검증자 몫: α · S_i                                       │
│     - RAT.distributeValidatorReward(systemConfig, α · S_i) 호출     │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│  2. RAT.distributeValidatorReward(systemConfig, amount)             │
│     - amount = α · S_i                                              │
│     - n = 해당 L2의 활성 검증자 수                                   │
│     - n > 0: 각 검증자당 amount / n                                 │
│     - n = 0: 미분배 (TBD: 귀속처 정책 결정 필요)                    │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│  3. 검증자가 claimRewards(systemConfig) 호출                        │
│     - pendingRewards를 WTON으로 전송                                 │
└─────────────────────────────────────────────────────────────────────┘
```

```solidity
/// @notice L2별 검증자 보상 분배 (SeigManager에서 호출)
/// @param systemConfig L2의 SystemConfig 주소
/// @param amount 해당 L2의 검증자 몫 (α · S_i)
function distributeValidatorReward(address systemConfig, uint256 amount) external {
    // SeigManager에서만 호출 가능
    require(msg.sender == seigManager, "not seig manager");

    ValidatorPool storage pool = validatorPools[systemConfig];

    // 검증자가 없으면 미분배 (TBD: 귀속처 정책 결정 필요)
    if (pool.activeValidatorCount == 0) {
        // 현재는 컨트랙트에 보관 (추후 정책에 따라 DAO 귀속 등 결정)
        undistributedRewards += amount;
        emit ValidatorRewardUndistributed(systemConfig, amount);
        return;
    }

    // 각 검증자에게 균등 분배: amount / n
    uint256 perValidator = amount / pool.activeValidatorCount;

    // 해당 SystemConfig의 각 활성 검증자에게 보상 누적
    address[] storage validators = activeValidators[systemConfig];
    for (uint256 i = 1; i < validators.length; i++) {
        address validator = validators[i];
        bytes32 regId = _getRegistrationId(validator, systemConfig);
        if (registrations[regId].isActive) {
            registrations[regId].pendingRewards += perValidator;
        }
    }

    address layer2 = _getLayer2FromSystemConfig(systemConfig);
    emit ValidatorRewardDistributed(systemConfig, layer2, amount, pool.activeValidatorCount);
}
```

**분배 예시:**
```
L2 시뇨리지: S_i = 1,000 WTON
검증자 분배 비율: α = 20%
해당 L2의 활성 검증자 수: n = 5명

1. SeigManager.updateSeigniorage():
   - L2별 검증자 몫 = 1,000 × 20% = 200 WTON
   - RAT.distributeValidatorReward(systemConfig, 200) 호출

2. RAT.distributeValidatorReward(systemConfig, 200):
   - n = 5 (검증자 있음)
   - 각 검증자당 = 200 / 5 = 40 WTON
   - 각 검증자의 pendingRewards에 40 WTON 누적

검증자가 없는 경우 (n = 0):
   - undistributedRewards에 200 WTON 누적
   - TBD: 추후 정책에 따라 DAO 귀속 또는 다른 처리
```

### 6.7 담보금 출금 (coinage factor 기반 시뇨리지 계산)

#### 출금 큐 구조

RAT은 DepositManager에 대리 스테이킹하므로, 출금 시 DepositManager의 출금 큐를 사용합니다.
DepositManager는 FIFO(선입선출) 큐 방식이므로, 앞선 출금 요청이 처리되어야 뒤의 요청을 처리할 수 있습니다.

```
DepositManager 출금 큐 (RAT 명의):
┌─────────────────────────────────────────────────────────────┐
│  [0] 검증자 A - 1,000 WTON (2주 대기 완료, 미처리)           │
│  [1] 검증자 B - 2,000 WTON (2주 대기 완료, 미처리)           │
│  [2] 검증자 C - 3,000 WTON (출금 요청 중)                    │
│  [3] 검증자 D - 4,000 WTON (출금 요청)  ← 새로운 요청        │
└─────────────────────────────────────────────────────────────┘

검증자 D가 processUnstakes(3) 호출 시:
→ DepositManager에서 [0]~[3] 모두 처리 (WTON이 RAT로 돌아옴)
→ [0], [1], [2], [3] 모두 "출금 완료" 표시
→ [3] 검증자 D만 바로 WTON 수령

이후 검증자 A가 processUnstakes(0) 호출 시:
→ [0]은 이미 "출금 완료" 상태
→ DepositManager 호출 없이 바로 A에게 WTON 전송
```

#### 출금 완료 규칙

**단일 함수 `processUnstakes(myIndex)`로 통합:**

```
┌─────────────────────────────────────────────────────────────┐
│ (A) 본인 인덱스가 이미 "출금 완료" 상태인 경우              │
│     → 바로 WTON 전송                                        │
├─────────────────────────────────────────────────────────────┤
│ (B) 아직 미완료인 경우                                      │
│     → nextUnstakeIndex ~ myIndex까지 DepositManager 일괄 처리│
│     → 모든 건 "출금 완료" 상태로 표시                       │
│     → 본인에게만 WTON 전송                                  │
└─────────────────────────────────────────────────────────────┘
```

**조회 함수:**
- `getUnstakeQueueIndex(validator, systemConfig)` → 본인 큐 인덱스
- `getUnstakeRequest(index)` → 출금 요청 상세 정보

**수수료 처리: TBD** (시뇨리지에서 출금 완료를 대신해준 수수료를 차감해서 호출자에게 보상할지는 추가 검토 필요)

```solidity
/// @notice 출금 요청 정보 (큐 방식)
struct UnstakeRequest {
    address validator;          // 검증자 주소
    address systemConfig;       // SystemConfig 주소
    uint256 amount;             // 출금 요청 금액 (원금 + 시뇨리지)
    uint256 principal;          // 원금 (시뇨리지 계산용)
    bool completed;             // 출금 완료 여부
}

/// @notice 출금 요청 큐
UnstakeRequest[] public unstakeQueue;

/// @notice 다음 처리할 큐 인덱스 (0부터 시작)
uint256 public nextUnstakeIndex;

/// @notice (validator, systemConfig) → 출금 요청 큐 인덱스 (본인 출금 인덱스 조회용)
/// @dev 검증자가 본인의 출금을 처리할 때 이 인덱스 사용
mapping(bytes32 => uint256) public unstakeQueueIndex;

/// @notice 담보금 출금 요청 (비활성 상태에서만 가능, 전액 출금만 가능)
/// @dev RAT이 DepositManager에 출금 요청, 큐에 추가
/// @dev 부분 출금 불가: 항상 depositedAmount 전체를 출금
/// @param systemConfig L2의 SystemConfig 주소
/// @return queueIndex 출금 요청이 추가된 큐 인덱스
function requestUnstake(address systemConfig) external nonReentrant returns (uint256 queueIndex) {
    bytes32 regId = _getRegistrationId(msg.sender, systemConfig);
    ValidatorRegistration storage reg = registrations[regId];

    require(!reg.isActive, "still active");
    require(reg.depositedAmount > 0, "no balance to withdraw");

    // 테스트 종료일이 지나야 출금 가능
    require(block.number > reg.latestTestEndBlock, "evidence period not ended");

    address layer2 = _getLayer2FromSystemConfig(systemConfig);

    // factor 비교로 출금 금액 계산 (원금 + 시뇨리지)
    // coinage는 factor 증가로 시뇨리지를 자동 계산
    // 출금 금액 = 원금 * (currentFactor / depositFactor)
    RefactorCoinageSnapshotI coinage = ISeigManager(seigManager).getCoinage(layer2);
    uint256 currentFactor = coinage.factor();
    uint256 depositFactor = reg.coinageFactorAtDeposit;

    uint256 principal = reg.depositedAmount;
    uint256 withdrawAmount = principal;
    if (currentFactor > depositFactor && depositFactor > 0) {
        withdrawAmount = (principal * currentFactor) / depositFactor;
    }

    // 내부 기록 차감
    reg.depositedAmount = 0;
    reg.coinageFactorAtDeposit = 0;

    // RAT이 DepositManager에 출금 요청 (원금 + 시뇨리지 포함)
    IDepositManager(depositManager).requestWithdrawal(layer2, withdrawAmount);

    // 출금 요청 큐에 추가
    queueIndex = unstakeQueue.length;
    unstakeQueue.push(UnstakeRequest({
        validator: msg.sender,
        systemConfig: systemConfig,
        amount: withdrawAmount,
        principal: principal,
        completed: false
    }));

    // 검증자별 큐 인덱스 저장 (본인 출금 시 조회용)
    bytes32 regId = _getRegistrationId(msg.sender, systemConfig);
    unstakeQueueIndex[regId] = queueIndex;

    emit UnstakeRequested(msg.sender, systemConfig, withdrawAmount, queueIndex);
}

/// @notice 출금 완료 처리
/// @dev 본인 인덱스로 호출. 이미 완료 상태면 바로 전송, 아니면 일괄 처리 후 전송
/// @param myIndex 본인의 출금 요청 큐 인덱스
function processUnstakes(uint256 myIndex) external nonReentrant {
    require(myIndex < unstakeQueue.length, "invalid index");

    UnstakeRequest storage myReq = unstakeQueue[myIndex];
    require(myReq.validator == msg.sender, "not your request");
    require(myReq.amount > 0, "already claimed");

    // 이미 출금 완료 상태인 경우: 바로 전송만
    if (myReq.completed) {
        uint256 amount = myReq.amount;
        uint256 principal = myReq.principal;
        myReq.amount = 0;  // 중복 수령 방지

        IERC20(wton).transfer(msg.sender, amount);

        address layer2 = _getLayer2FromSystemConfig(myReq.systemConfig);
        emit UnstakeProcessed(msg.sender, myReq.systemConfig, layer2, amount, amount - principal);
        return;
    }

    // 아직 미완료인 경우: nextUnstakeIndex부터 myIndex까지 일괄 처리
    require(myIndex >= nextUnstakeIndex, "invalid state");

    uint256 processCount = myIndex - nextUnstakeIndex + 1;

    // 처리 전 잔액 기록
    uint256 beforeBalance = IERC20(wton).balanceOf(address(this));

    // DepositManager에서 일괄 출금 처리
    address layer2 = _getLayer2FromSystemConfig(myReq.systemConfig);
    IDepositManager(depositManager).processRequests(layer2, processCount, false);

    uint256 afterBalance = IERC20(wton).balanceOf(address(this));
    uint256 totalWithdrawn = afterBalance - beforeBalance;

    // 각 출금 건 처리 - 출금 완료 상태로 표시
    uint256 totalExpected = 0;
    for (uint256 i = nextUnstakeIndex; i <= myIndex; i++) {
        UnstakeRequest storage req = unstakeQueue[i];
        if (req.completed) continue;

        totalExpected += req.amount;
        req.completed = true;
    }

    require(totalWithdrawn >= totalExpected, "insufficient withdrawal");

    // 다음 처리 인덱스 업데이트
    nextUnstakeIndex = myIndex + 1;

    // 요청자에게만 바로 전송
    uint256 myAmount = myReq.amount;
    uint256 myPrincipal = myReq.principal;
    myReq.amount = 0;  // 중복 수령 방지

    IERC20(wton).transfer(msg.sender, myAmount);

    emit UnstakeProcessed(msg.sender, myReq.systemConfig, layer2, myAmount, myAmount - myPrincipal);

    // TBD: 수수료 처리
    // 앞선 출금 건들의 시뇨리지에서 가스비 수수료를 차감해서 msg.sender에게 보상?
}

```

**시뇨리지 계산 예시:**
```
예치 시점: factor = 1.0e27, amount = 10,000 WTON
출금 시점: factor = 1.1e27 (10% 증가)

시뇨리지 = 10,000 × (1.1e27 - 1.0e27) / 1.0e27
         = 10,000 × 0.1
         = 1,000 WTON

총 출금 가능 금액 = 10,000 + 1,000 = 11,000 WTON
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

## 7. Optimism RAT와의 주요 차이점

### 7.1 검증자 범위

| Optimism | TON V3 |
|----------|--------|
| 글로벌 검증자 풀 | **SystemConfig별 검증자 풀** |
| `challengers[addr]` | `registrations[hash(validator, systemConfig)]` |

```solidity
// Optimism: 글로벌 검증자
validChallengers[]  // 모든 게임에 동일한 풀

// TON V3: SystemConfig별 검증자
activeValidators[systemConfig][]  // L2마다 별도 풀
```

### 7.2 자산 타입

| Optimism | TON V3 |
|----------|--------|
| ETH (msg.value) | WTON (ERC20 transferFrom) |

### 7.3 슬래싱 처리

| Optimism | TON V3 (백서 V2) |
|----------|------------------|
| perTestBondAmount 선차감 | **C_off (슬래싱 페널티)** 선차감 |
| 본드가 컨트랙트에 잔류 | 몰수된 C_off 귀속처 TBD |
| implicit slashing | **Lazy Evaluation** (별도 함수 불필요) |
| - | D_min 미만 시 즉시 검증자 세트에서 제거 |

### 7.4 보상 시스템

| Optimism | TON V3 |
|----------|--------|
| 보상 없음 | SystemConfig별 시뇨리지 분배 (α/n)·y(x) |

### 7.5 트리거 시점

| Optimism | TON V3 |
|----------|--------|
| Dispute Game 생성 | Dispute Game 생성 |

---

## 8. 통합 가이드

### 8.1 RAT 트리거 시점 및 인터페이스

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

### 8.2 DisputeGameFactory 통합

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

### 8.3 TRH (Tokamak Rollup Hub) 가이드라인

1. **DisputeGame 생성 시 RAT 트리거 필수화**
   - 모든 L2 프로포저는 DisputeGame 생성 시 RAT.triggerAttentionTest() 호출
   - SystemConfig 주소를 키로 사용하여 해당 L2의 검증자 풀에서 선택

2. **SystemConfig 등록 요구**
   - L2 온보딩 시 Layer2Manager에 SystemConfig 등록
   - 등록된 SystemConfig만 RAT에서 유효

3. **트리거 실패 처리**
   - RAT 트리거 실패해도 DisputeGame 생성은 성공해야 함 (try-catch)
   - 검증자가 없거나 확률 미충족 시 RAT는 발생하지 않음

### 8.4 Layer2Manager 수정

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

### 8.5 SeigManagerV1_4 수정

검증자 보상은 각 L2의 시뇨리지 계산 시 함께 처리됩니다.

**백서 공식 (13):**
```
v_i = (α/n) · y(x),    o_i = (1 - α) · S_i
```

> **TBD: 검증자 보상 분배 방식**
>
> 백서 공식 해석이 모호하여, 현재는 **L2별 성과(S_i)에 따라 분배**하는 방식으로 구현합니다.
> 검증자가 없는 L2의 경우 해당 검증자 몫(α · S_i)은 **미분배** 처리됩니다.
> 추후 백서 확정 시 재검토 필요.

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
        // 검증자가 없으면 RAT에서 미분배 처리
        if (validatorAmount > 0 && rat != address(0)) {
            IWTON(wton).mint(address(this), validatorAmount);
            IERC20(wton).approve(rat, validatorAmount);
            IRAT(rat).distributeValidatorReward(systemConfig, validatorAmount);
        }
    }
}
```

> **TBD: 검증자 없을 때 미분배분 처리**
>
> L2에 검증자가 없으면 해당 L2의 검증자 몫(α · S_i)은 RAT 컨트랙트의 `undistributedRewards`에 누적됩니다.
> 이 미분배분의 처리 방안은 추후 정책 결정이 필요합니다:
> - 옵션 1: DAO로 귀속
> - 옵션 2: 시퀀서에게 추가 분배
> - 옵션 3: 컨트랙트에 보관 (현재 구현)

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

### 10.4 보상 분배
- [ ] 검증자 보상 분배 (α/n)·y(x)
- [ ] 검증자 없는 L2의 미분배 처리
- [ ] 보상 청구 (claimRewards, claimRewardsBatch)

### 10.5 기타
- [ ] 파라미터 변경 권한 (ratManager)
- [ ] 업그레이드 호환성
- [ ] 이벤트 기반 자금 추적 (AttentionTestTriggered/EvidenceSubmitted/BondRestored)
