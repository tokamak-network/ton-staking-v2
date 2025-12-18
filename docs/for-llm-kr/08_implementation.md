# V3 구현 코드

## 1. SeigManagerV1_4Storage (신규 스토리지)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract SeigManagerV1_4Storage {
    // ==========================================
    // V3 핵심 파라미터 (백서 기준)
    // ==========================================

    /// @notice d: DAO 분배 비율 (0 < d < 1), RAY 단위
    /// @dev 백서 공식 (7): S_DAO = d · A₂
    uint256 public daoDistributionRatio;

    /// @notice θ: 최소 스테이킹 비율 (0 < θ ≤ 1), RAY 단위
    /// @dev 백서 공식 (8): S_i ≥ θ · B_i
    uint256 public minStakingRatio;

    /// @notice α: 검증자 분배 비율 (0 < α < 1), RAY 단위
    /// @dev 백서 V3 공식 (13): v_j = Σ_{i: j∈V_i} (α · S_i) / |V_i|
    uint256 public validatorDistributionRatio;

    /// @notice k: 반포화점 (half-saturation point), RAY 단위
    /// @dev 백서 공식 (11): y(k) = L/2
    uint256 public halfSaturationPoint;

    /// @notice λ: 지분 시뇨리지 비율 (미사용, 레거시)
    /// @dev 현재 구현에서 사용하지 않음
    ///      - V2 모드: V1_3 공식 사용 (stakedSeig = A × prevTotalSupply / tos)
    ///      - V3 모드: 스테이커 시뇨리지 없음 (A₂ = A)
    uint256 public stakedSeigFactor;

    // ==========================================
    // Bridged TON 관련 스토리지
    // ==========================================

    /// @notice 전체 유효 Bridged TON 합계: x = Σ B̃_i
    uint256 public totalEffectiveBridgedTON;

    /// @notice Bridged TON 1단위당 누적 보상 (V2의 l2RewardPerUint 대응)
    /// @dev bridgedTONRewardPerUint = Σ(y(x) / x) 누적값
    uint256 public bridgedTONRewardPerUint;

    /// @notice L2별 Bridged TON 정보
    /// @dev V3 측정 방식: 온체인 호출 시점의 최신값 사용 (기간 평균 아님)
    struct BridgedTONInfo {
        uint256 currentBridgedTON;      // B_i: 현재 Bridged TON (호출 시점 최신값)
        uint256 effectiveBridgedTON;    // B̃_i: 유효 Bridged TON (자격 없으면 0)
        uint256 initialDebt;            // 초기부채 (V2 패턴 동일)
        uint256 startBlock;             // 참여 시작 블록
        uint256 lastUpdateTime;         // 마지막 업데이트 타임스탬프
        bool isEligible;                // 자격 여부 (S_i ≥ θ·B_i, 호출 시점 검증)
    }

    /// @notice layer2 => BridgedTONInfo
    mapping(address => BridgedTONInfo) public bridgedTONInfo;

    // ==========================================
    // 검증자 보상 관련
    // ==========================================

    /// @notice ValidatorReward 컨트랙트 주소
    /// @dev Per-L2 검증자 보상 분배용
    address public validatorReward;

    /// @notice 기간(Period) 정보
    struct PeriodInfo {
        uint256 startBlock;
        uint256 endBlock;
        uint256 totalSeigniorage;
        uint256 totalDistributed;       // y(x)
        uint256 validatorRewardAmount;  // α · y(x)
        bool finalized;
    }

    // ==========================================
    // RAT 컨트랙트 주소
    // ==========================================

    /// @notice RAT (Randomized Attention Test) 컨트랙트 주소
    address public ratContract;

    /// @notice 현재 기간 ID
    uint256 public currentPeriodId;

    /// @notice 기간 정보 매핑
    mapping(uint256 => PeriodInfo) public periods;

    // ==========================================
    // 시퀀서 슬래싱 관련 파라미터 (백서 공식 1, 2)
    // ==========================================

    /// @notice H_max: 최대 동시 챌린저 수
    /// @dev 백서 공식 (1): D_sequencer = H_max · C_max + Δ_sequencer
    uint256 public maxChallengers;

    /// @notice C_max: 단일 fraud proof 예상 온체인 비용
    /// @dev 백서 공식 (2): R_challenger = C_max + (Δ_sequencer / n)
    uint256 public maxFraudProofCost;

    // ==========================================
    // RAT 컨트랙트 주소
    // ==========================================

    /// @notice RAT (Randomized Attention Test) 컨트랙트 주소
    address public ratContract;

    // ==========================================
    // V3 마이그레이션 상태
    // ==========================================

    /// @notice V3 마이그레이션 완료 여부
    bool public v3Migrated;

    /// @notice V3 마이그레이션 블록
    uint256 public v3MigrationBlock;

    // ==========================================
    // SequencerVault 참조
    // ==========================================

    /// @notice SequencerVault 컨트랙트 주소
    /// @dev V3: 시퀀서 자격 조건(S_i ≥ θ·B_i)을 SequencerVault 담보금으로 확인
    address public sequencerVault;
}
```

---

## 2. SeigManagerV1_4 핵심 함수

### 2.1 파라미터 설정 함수 (레거시)

> **참고**:
> - `stakedSeigFactor` (λ): 미사용 (V2 모드는 V1_3 공식 사용, V3 모드는 스테이커 시뇨리지 없음)
> - `relativeSeigRate` (r): V2 모드에서 사용됨 (V1_3과 동일), V3 모드에서 미사용

```solidity
/// @notice 지분 시뇨리지 비율 설정 (레거시, 미사용)
function setStakedSeigFactor(uint256 newLambda) external onlyOwner {
    require(newLambda <= RAY, "lambda > 1");
    stakedSeigFactor = newLambda;
    emit StakedSeigFactorUpdated(newLambda);
}

/// @notice 추가 시뇨리지 비율 설정 (V2 모드에서 사용)
/// @dev relativeSeigRate는 V2 모드에서 V1_3과 동일하게 적용됨
function setRelativeSeigRate(uint256 newRate) external onlyOwner {
    require(newRate <= RAY, "rate > 1");
    relativeSeigRate = newRate;
    emit RelativeSeigRateUpdated(newRate);
}
```

### 2.2 쌍곡선 포화 함수

```solidity
/// @notice 쌍곡선 포화 함수
/// @dev 백서 공식 (11): y(x) = L · (x / (k + x))
/// @param x 전체 유효 Bridged TON
/// @return y 분배 가능 시뇨리지
function hyperbolicSaturation(uint256 x, uint256 maxL2Allocation)
    public view
    returns (uint256 y)
{
    if (x == 0) return 0;

    // L = (1 - d) · A₂ (기간 시뇨리지 기준)
    // k = halfSaturationPoint

    // y(x) = L · (x / (k + x))
    // = (L * x) / (k + x)
    y = rdiv(rmul(maxL2Allocation, x), halfSaturationPoint + x);
}
```

### 2.3 개별 L2 시뇨리지 계산

```solidity
/// @notice 개별 L2 시뇨리지 계산
/// @dev 백서 공식 (12): Seig_i = y(x) · (B̃_i / x)
function calculateL2Seigniorage(
    address layer2,
    uint256 totalY,
    uint256 totalX
) public view returns (uint256 seigniorage) {
    if (totalX == 0) return 0;

    uint256 effectiveBridgedTON = getEffectiveBridgedTON(layer2);
    if (effectiveBridgedTON == 0) return 0;

    // Seig_i = y(x) · (B̃_i / x)
    seigniorage = rmul(totalY, rdiv(effectiveBridgedTON, totalX));
}

/// @notice 시퀀서 보상 계산
/// @dev 백서 V3 공식 (14): o_i = (1 - α) · S_i
function calculateSequencerReward(uint256 l2Seigniorage)
    public view
    returns (uint256)
{
    return rmul(l2Seigniorage, RAY - validatorDistributionRatio);
}
```

### 2.4 _increaseTotV3 로직 (V3/V2 분기)

```solidity
/// @notice V3 증가 로직 (백서 공식 적용)
function _increaseTotV3() internal returns (bool result) {
    if (RefactorCoinageSnapshotI(_tot).totalSupply() == 0) {
        _lastSeigBlock = block.number;
        return false;
    }

    uint256 prevTotalSupply = _tot.totalSupply();
    uint256 span = block.number - _lastSeigBlock;
    uint256 A = span * _seigPerBlock;
    uint256 tos = _totalSupplyOfTon(block.number);

    _lastSeigBlock = block.number;

    if (v3Migrated) {
        // ========================================
        // V3: 스테이커 시뇨리지 없음 (V3 백서)
        // A₂ = A (전체 시뇨리지가 V3 분배 재원)
        // ========================================
        emit CommitLog1(_tot.totalSupply(), tos, prevTotalSupply, prevTotalSupply);

        if (A > 0) {
            (l2TotalSeigs, layer2Seigs) = _distributeV3Seigniorage(A);
        }
    } else {
        // ========================================
        // V2: V1_3 _increaseTot() 로직과 동일
        // ========================================

        // 1. stakedSeig 계산 (V1_3과 동일)
        uint256 stakedSeig = rdiv(rmul(A, prevTotalSupply), tos);

        // 2. Layer2 TVL 시뇨리지 계산
        // ... (V1_3과 동일한 layer2 TVL 분배 로직)

        // 3. unstakedSeig, totalPseig 계산 (V1_3과 동일)
        uint256 unstakedSeig = A - stakedSeig - l2TotalSeigs;
        uint256 totalPseig = rmul(unstakedSeig, relativeSeigRate);
        uint256 nextTotalSupply = prevTotalSupply + stakedSeig + totalPseig;

        // 4. Coinage factor 업데이트
        _tot.setFactor(_calcNewFactor(prevTotalSupply, nextTotalSupply, _tot.factor()));

        // 5. PowerTON, DAO 분배 (V1_3과 동일)
        // ...
    }

    return true;
}

/// @notice V3 시뇨리지 분배 (백서 공식 적용)
/// @param A2 V3 분배 재원 (스테이커 분배 후 잔여)
function _distributeV3Seigniorage(uint256 A2) internal {
    // ========================================
    // DAO 고정 분배 (백서 공식 7)
    // S_DAO = d · A₂
    // ========================================
    uint256 S_DAO = FullMath.rmul(A2, daoDistributionRatio);

    // ========================================
    // L2 분배 가능량
    // L = (1 - d) · A₂
    // ========================================
    uint256 L = A2 - S_DAO;

    // ========================================
    // 쌍곡선 포화 함수 (백서 공식 11)
    // y(x) = L · (x / (k + x))
    // ========================================
    uint256 x = totalEffectiveBridgedTON;  // 캐시된 값
    uint256 y = 0;
    uint256 totalValidatorReward = 0;

    if (x > 0) {
        // y(x) = L · (x / (k + x))
        y = FullMath.rmul(L, FullMath.rdiv(x, halfSaturationPoint + x));
    }

    // ========================================
    // 미분배분 DAO 귀속
    // totalDAO = S_DAO + (L - y(x))
    // ========================================
    uint256 undistributed = L - y;
    uint256 totalDAO = S_DAO + undistributed;

    if (totalDAO > 0) {
        IWTON(_wton).mint(dao, totalDAO);
    }

    // ========================================
    // Per-L2 분배 (백서 V3 공식 12, 13)
    // S_i = y(x) · (B̃_i / x)
    // 시퀀서: (1-α) · S_i, 검증자: α · S_i
    // ========================================
    // 각 L2를 순회하며 분배 (updateSeigniorageLayer에서 처리)

    emit V3SeigniorageDistributed(A2, L, y, totalDAO, totalValidatorReward);
}

// Per-L2 시뇨리지 분배 (백서 V3 공식)
function _distributeL2Seigniorage(
    address layer2,
    uint256 y,      // 전체 y(x)
    uint256 x       // 전체 x
) internal {
    BridgedTONInfo storage info = bridgedTONInfo[layer2];
    if (!info.isEligible || info.effectiveBridgedTON == 0) return;

    // S_i = y(x) · (B̃_i / x) - 백서 공식 (12)
    uint256 l2Seigniorage = FullMath.rmul(y, FullMath.rdiv(info.effectiveBridgedTON, x));

    // 검증자 몫: α · S_i - 백서 공식 (13)
    uint256 l2ValidatorReward = FullMath.rmul(l2Seigniorage, validatorDistributionRatio);

    // 시퀀서 몫: (1 - α) · S_i
    uint256 l2SequencerReward = l2Seigniorage - l2ValidatorReward;

    // 시퀀서 보상 분배 (기존 로직)
    if (l2SequencerReward > 0) {
        // ... 시퀀서에게 분배
    }

    // 검증자 보상 분배 (Per-L2)
    if (l2ValidatorReward > 0 && validatorReward != address(0)) {
        address rollupConfig = _getRollupConfig(layer2);
        IWTON(_wton).mint(validatorReward, l2ValidatorReward);
        IValidatorReward(validatorReward).distributeL2Rewards(rollupConfig, l2ValidatorReward);
    }
}
```

### 2.5 V2 → V3 핵심 변경

```solidity
// V2
l2RewardPerUint += (l2TotalSeigs * WEI_UNIT) / totalLayer2TVL;
layer2Seigs = (l2RewardPerUint * layer2Tvl) / WEI_UNIT - initialDebt;

// V3 (동일 패턴, 다른 입력)
bridgedTONRewardPerUint += (totalY * WEI_UNIT) / totalEffectiveBridgedTON;
layer2Seigs = (bridgedTONRewardPerUint * effectiveBridgedTON) / WEI_UNIT - initialDebt;
//             └── y(x) / x = L / (k+x) 쌍곡선 ──┘   └── B̃_i ──┘
```

---

## 3. 이벤트

```solidity
/// @notice V3 시뇨리지 분배 이벤트 (ISeigManagerV3.sol:27-35)
event V3SeigniorageDistributed(
    uint256 totalSeigniorage,       // A₂: 전체 시뇨리지
    uint256 l2MaxAllocation,        // L: (1-d)·A₂ 분배 가능량
    uint256 totalDistributed,       // y(x): 쌍곡선 결과
    uint256 daoAmount,              // DAO 총 분배량 (S_DAO + 미분배분)
    uint256 validatorPoolAmount     // α·y(x): 검증자 보상 총액
);

/// @notice V3 마이그레이션 완료 이벤트
event V3MigrationCompleted(uint256 blockNumber, uint256 totalMigratedL2s);

/// @notice V2 시뇨리지 분배 이벤트 (V1_3과 동일)
event SeigGiven2(
    address indexed layer2,
    uint256 maxSeig,        // A: 전체 시뇨리지
    uint256 stakedSeig,     // 스테이커 지분 시뇨리지
    uint256 unstakedSeig,   // 미스테이킹 시뇨리지
    uint256 powertonSeig,   // PowerTON 분배량
    uint256 daoSeig,        // DAO 분배량
    uint256 l2TotalSeigs,   // Layer2 TVL 시뇨리지
    uint256 layer2Seigs,    // 개별 L2 시뇨리지
    uint256 relativeSeig    // 추가 시뇨리지 (r 비율)
);
```

---

## 4. 검증자 관련 컨트랙트 (V3 아키텍처)

### 4.1 개요

V3에서는 검증자 관련 기능이 두 컨트랙트로 분리되었습니다:

| 컨트랙트 | 역할 |
|---------|------|
| **RAT.sol** | 검증자 등록/담보금/슬래싱 관리, RAT 테스트 |
| **ValidatorRewardV1.sol** | 검증자 보상 분배 |

> **상세 구현**: RAT 구현체는 [07_rat_implementation.md](./07_rat_implementation.md) 참조

### 4.2 ValidatorRewardStorage

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title ValidatorRewardStorage
/// @notice 검증자 보상 분배 스토리지
contract ValidatorRewardStorage {
    // ==========================================
    // 보상 관련 스토리지
    // ==========================================

    /// @notice 검증자별 총 미청구 보상
    /// @dev validator => pending amount
    mapping(address => uint256) public validatorPendingRewards;

    /// @notice 검증자별 L2별 미청구 보상 (Per-L2 추적용)
    /// @dev validator => systemConfig => pending amount
    mapping(address => mapping(address => uint256)) public validatorL2PendingRewards;

    // ==========================================
    // 참조 주소
    // ==========================================

    address public seigManager;
    address public wton;
    address public ratContract;
    address public treasury;
    address public owner;

    // ==========================================
    // 상태
    // ==========================================

    bool internal _lock;
}
```

> **RAT 스토리지**: 검증자 등록/담보금 스토리지는 RATStorage.sol에 정의됨 - [07_rat_implementation.md](./07_rat_implementation.md) 참조

### 4.3 ValidatorRewardV1 핵심 함수

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ValidatorRewardStorage.sol";
import "./interfaces/IValidatorReward.sol";
import "./interfaces/IRAT.sol";

/// @title ValidatorRewardV1
/// @notice 검증자 보상 분배 컨트랙트
/// @dev V3 백서 공식 13: v_j = (α · S_i) / |V_i|
contract ValidatorRewardV1 is ValidatorRewardStorage, IValidatorReward {

    // ==========================================
    // 보상 분배 (SeigManager에서 호출)
    // ==========================================

    /// @notice L2별 검증자 보상 분배
    /// @dev V3 백서: |V_i| = 0이면 α·S_i → DAO Treasury
    function distributeL2Rewards(address systemConfig, uint256 amount)
        external
        onlySeigManager
        ifFree
    {
        if (amount == 0) return;
        if (ratContract == address(0)) revert ZeroAddressError();

        // RAT에서 해당 L2의 검증자 목록 조회
        address[] memory validators = IRAT(ratContract).getL2Validators(systemConfig);
        uint256 len = validators.length;

        // |V_i| = 0이면 Treasury로 귀속
        if (len == 0) {
            if (treasury != address(0)) {
                IERC20(wton).safeTransfer(treasury, amount);
                emit RewardToTreasury(systemConfig, amount);
            }
            return;
        }

        // 활성 검증자 수 계산
        uint256 activeCount = 0;
        for (uint256 i = 0; i < len; i++) {
            if (IRAT(ratContract).isValidatorActive(validators[i], systemConfig)) {
                activeCount++;
            }
        }

        if (activeCount == 0) {
            if (treasury != address(0)) {
                IERC20(wton).safeTransfer(treasury, amount);
                emit RewardToTreasury(systemConfig, amount);
            }
            return;
        }

        // v_j = amount / |V_i| (V3 공식 13)
        uint256 perValidator = amount / activeCount;
        uint256 distributed = 0;

        // 각 활성 검증자에게 보상 누적
        for (uint256 i = 0; i < len; i++) {
            address validator = validators[i];
            if (IRAT(ratContract).isValidatorActive(validator, systemConfig)) {
                // 총 보상 누적 (claimAllRewards용)
                validatorPendingRewards[validator] += perValidator;
                // Per-L2 보상 누적 (조회/통계용)
                validatorL2PendingRewards[validator][systemConfig] += perValidator;
                distributed += perValidator;

                // 개별 검증자 이벤트 (추적용)
                emit ValidatorRewardReceived(validator, systemConfig, perValidator);
            }
        }

        emit L2RewardDistributed(systemConfig, distributed, activeCount);
    }

    // ==========================================
    // 보상 청구
    // ==========================================

    /// @notice 모든 L2에서 받은 보상 한 번에 청구
    function claimAllRewards() external ifFree {
        uint256 rewards = validatorPendingRewards[msg.sender];
        if (rewards == 0) revert NoRewardsError();

        validatorPendingRewards[msg.sender] = 0;
        IERC20(wton).safeTransfer(msg.sender, rewards);

        emit RewardsClaimed(msg.sender, rewards);
    }

    // ==========================================
    // 조회 함수
    // ==========================================

    /// @notice 검증자의 특정 L2별 미청구 보상 조회
    function getPendingRewardsByL2(address validator, address systemConfig)
        external view returns (uint256)
    {
        return validatorL2PendingRewards[validator][systemConfig];
    }

    /// @notice 검증자의 총 미청구 보상 조회
    function getTotalPendingRewards(address validator)
        external view returns (uint256)
    {
        return validatorPendingRewards[validator];
    }
}
```

> **RAT 함수**: 검증자 등록/담보금/슬래싱 함수는 RAT.sol에 구현됨 - [07_rat_implementation.md](./07_rat_implementation.md) 참조

---

## 5. Layer2ManagerV1_2 (업그레이드)

### 5.1 신규 스토리지

```solidity
contract Layer2ManagerV1_2Storage {
    // V1_1 스토리지 상속...

    // ==========================================
    // V3 신규: Bridged TON 조회 관련
    // ==========================================

    /// @notice L2별 최신 Bridged TON (캐시, 선택적)
    mapping(address => uint256) public cachedBridgedTON;
}
```

### 5.2 신규 함수

### 5.3 V3 측정 방식: 온체인 호출 시점 최신값

V3 백서에서 측정 방식이 변경되었습니다:

| 구분 | V2 | V3 |
|------|-----|-----|
| **측정 방식** | 기간 평균값 | 온체인 호출 시점 최신값 |
| **샘플링** | 주기적 스냅샷 | 호출 기반 |
| **구현** | `calculatePeriodAverage()` | `getBridgedTON()` |

```solidity
/// @notice Bridged TON 조회 (L1BridgeRegistry.layer2TVL 사용)
/// @dev V3 측정 방식: 온체인 호출 시점의 최신값 사용 (기간 평균 아님)
/// @param rollupConfig RollupConfig 주소
/// @dev L1BridgeRegistry.layer2TVL은 타입별 bridge/portal 조회 로직 포함
function getBridgedTON(address rollupConfig) public view returns (uint256) {
    return IL1BridgeRegistry(l1BridgeRegistry).layer2TVL(rollupConfig);
}

/// @notice L2 주소로 Bridged TON 조회
/// @param layer2 L2 주소
function getBridgedTONByLayer(address layer2) public view returns (uint256) {
    address operator = operatorOfLayer[layer2];
    if (operator == address(0)) return 0;
    address rollupConfig = operatorInfo[operator].rollupConfig;
    if (rollupConfig == address(0)) return 0;
    return getBridgedTON(rollupConfig);
}

/// @notice SystemConfig(rollupConfig) 주소로 Layer2 주소 조회
/// @param systemConfig SystemConfig 컨트랙트 주소
/// @return layer2 해당 Layer2 주소 (없으면 address(0))
function getLayer2BySystemConfig(address systemConfig) external view returns (address layer2) {
    address operatorManager = rollupConfigInfo[systemConfig].operatorManager;
    if (operatorManager == address(0)) return address(0);
    return operatorInfo[operatorManager].candidateAddOn;
}
```

---

## 6. 관련 코드 파일

| 파일 | 설명 |
|------|------|
| `src/stake/managers/SeigManagerV1_4.sol` | V3 시뇨리지 분배 |
| `src/validator/RAT.sol` | 검증자 등록/담보금/슬래싱 |
| `src/validator/ValidatorRewardV1.sol` | 검증자 보상 분배 |
| `src/validator/IValidatorReward.sol` | ValidatorReward 인터페이스 |
| `src/validator/IRAT.sol` | RAT 인터페이스 |
| `src/layer2/Layer2ManagerV1_2.sol` | L2 관리 |

### 6.1 아키텍처 분리

```
SeigManager                    RAT                     ValidatorReward
───────────────               ─────────────            ──────────────────
V3 시뇨리지 계산               검증자 등록/탈퇴         검증자 보상 분배
L2별 α·S_i 계산               담보금 관리              Per-L2 보상 추적
ValidatorReward 호출 ─────────► 검증자 목록 조회 ◄───── claimAllRewards()
                              RAT 테스트               Treasury 귀속 처리
                              C_off 슬래싱
```

---

## 7. V3 백서 준수 확인

| 항목 | V3 백서 요구사항 | 구현 상태 |
|------|-----------------|----------|
| 공식 (11) | y(x) = L · (x / (k + x)) | ✅ hyperbolicSaturation() |
| 공식 (12) | S_i = y(x) · (B̃_i / x) | ✅ calculateL2Seigniorage() |
| 공식 (13) | v_j = Σ_{i: j∈V_i} (α · S_i) / \|V_i\| | ✅ ValidatorRewardV1.distributeL2Rewards() |
| 공식 (14) | o_i = (1 − α) · S_i | ✅ calculateSequencerReward() |
| \|V_i\| = 0 처리 | α·S_i → DAO Treasury | ✅ ValidatorRewardToTreasury 이벤트 |
| **측정 방식** | 온체인 호출 시점 최신값 | ✅ getBridgedTON(), checkCurrentEligibility() |

### 7.1 V3 측정 방식 준수 확인

코드에서 V3 측정 방식이 적용되어 있습니다:

```solidity
// SeigManagerV1_4.sol:330 - Bridged TON 실시간 조회
uint256 bridgedTON = ILayer2Manager(layer2Manager).getBridgedTONByLayer(layer2);

// SeigManagerV1_4.sol:337 - Staked TON 실시간 조회
currentStake = _getSequencerStake(layer2);

// SeigManagerV1_4.sol:638 - L2 TVL 현재값 조회
uint256 curLayer2Tvl = IL1BridgeRegistry(l1BridgeRegistry).layer2TVL(rollupConfig);
```

**측정 방식 비교:**
| 항목 | V2 | V3 (현재 구현) |
|------|-----|---------------|
| Bridged TON | 기간 평균 | ✅ 호출 시점 최신값 |
| Staked TON | 기간 평균 | ✅ 호출 시점 최신값 |
| 자격 조건 | 기간 평균 비교 | ✅ 호출 시점 비교 |

---

## 8. 참고 문서

- `Tokamak_Economics_Whitepaper_V3.pdf` (December 16, 2025)
- `docs/for-llm-kr/02_v3_distribution.md` - V3 분배 공식 상세
- `docs/for-llm-kr/04_validator.md` - 검증자 보상 상세
- `docs/for-llm-kr/07_rat_implementation.md` - RAT 구현 상세

---

## 9. 변경 이력

| 날짜 | 내용 |
|------|------|
| 2025-12-18 | V3 백서 반영: 공식 (13), (14) 업데이트, \|V_i\|=0 Treasury 처리 추가 |

