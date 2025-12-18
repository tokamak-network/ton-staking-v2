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
    // 검증자 풀 관련
    // ==========================================

    /// @notice ValidatorPool 컨트랙트 주소
    address public validatorPool;

    /// @notice 기간(Period) 정보
    struct PeriodInfo {
        uint256 startBlock;
        uint256 endBlock;
        uint256 totalSeigniorage;
        uint256 totalDistributed;       // y(x)
        uint256 validatorPoolAmount;    // α · y(x)
        bool finalized;
    }

    /// @notice 현재 기간 ID
    uint256 public currentPeriodId;

    /// @notice 기간 정보 매핑
    mapping(uint256 => PeriodInfo) public periods;

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
    uint256 validatorPoolAmount = 0;

    if (x > 0) {
        // y(x) = L · (x / (k + x))
        y = FullMath.rmul(L, FullMath.rdiv(x, halfSaturationPoint + x));

        // 검증자 풀: α · y(x) → 각 L2별로 α · S_i 분배 (백서 V3 공식 13)
        validatorPoolAmount = FullMath.rmul(y, validatorDistributionRatio);

        // 단위당 보상 누적 (시퀀서용)
        uint256 sequencerTotal = y - validatorPoolAmount;
        bridgedTONRewardPerUint += (sequencerTotal * WEI_UNIT) / x;

        // L2Manager로 민트 (시퀀서 보상용)
        if (sequencerTotal > 0) {
            IWTON(_wton).mint(layer2Manager, sequencerTotal);
        }
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

    // 검증자 풀 분배
    if (validatorPoolAmount > 0 && validatorPool != address(0)) {
        IWTON(_wton).mint(validatorPool, validatorPoolAmount);
    }

    emit V3SeigniorageDistributed(A2, L, y, totalDAO, validatorPoolAmount);
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
    uint256 totalDAO,               // DAO 총 분배량 (S_DAO + 미분배분)
    uint256 validatorPoolAmount     // α·y(x): 검증자 풀
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

## 4. ValidatorPoolV1 (신규 컨트랙트)

### 4.1 개요

검증자(Validator)에게 RAT 기반 보상을 분배하는 신규 컨트랙트입니다.

### 4.2 스토리지

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ValidatorPoolStorage {
    // ==========================================
    // 검증자 정보
    // ==========================================

    struct ValidatorInfo {
        bool isActive;
        uint256 depositAmount;      // D_validator
        uint256 pendingRewards;
        uint256 lastClaimPeriod;
        uint256 lastRATResponse;
    }

    /// @notice 검증자 목록
    address[] public validators;

    /// @notice 검증자 정보 매핑
    mapping(address => ValidatorInfo) public validatorInfo;

    /// @notice 검증자 인덱스 매핑
    mapping(address => uint256) public validatorIndex;

    /// @notice 활성 검증자 수 (n)
    uint256 public activeValidatorCount;

    // ==========================================
    // RAT 관련
    // ==========================================

    struct RATChallenge {
        address validator;
        uint256 batchId;
        uint256 deadline;
        bool responded;
        bool slashed;
    }

    /// @notice RAT 챌린지 매핑
    mapping(bytes32 => RATChallenge) public ratChallenges;

    /// @notice RAT 발생 확률 (π_a)
    uint256 public ratProbability;

    /// @notice RAT 응답 윈도우
    uint256 public ratResponseWindow;

    // ==========================================
    // 보상 관련
    // ==========================================

    /// @notice 기간별 검증자 풀 총액
    mapping(uint256 => uint256) public periodValidatorPool;

    /// @notice 기간별 검증자당 보상
    mapping(uint256 => uint256) public periodPerValidatorReward;

    // ==========================================
    // 참조
    // ==========================================

    address public seigManager;
    address public wton;
    address public ton;

    /// @notice DAO Treasury 주소 (V3: |V_i| = 0 시 귀속처)
    address public treasury;

    /// @notice 최소 검증자 담보금 (D_validator)
    /// @dev 백서 공식 (5): D_validator = C_off + Δ_validator
    uint256 public minimumValidatorDeposit;

    // ==========================================
    // 백서 V2 신규 파라미터
    // ==========================================

    /// @notice C_off: 슬래싱 페널티 (백서 공식 4)
    /// @dev 백서 공식 (4): C_off ≥ (c_m · N) / π_a
    uint256 public slashingPenalty;

    /// @notice D_min: 최소 담보금 임계값
    /// @dev 잔액이 D_min 미만이면 활성 검증자 세트에서 제거
    uint256 public minimumThreshold;
}
```

### 4.3 핵심 함수

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ValidatorPoolStorage.sol";

contract ValidatorPoolV1 is ValidatorPoolStorage {

    // ==========================================
    // 검증자 관리
    // ==========================================

    /// @notice 검증자 등록
    /// @dev 백서 공식 (5): D_validator = C_off + Δ_validator
    function registerValidator(uint256 depositAmount) external {
        require(!validatorInfo[msg.sender].isActive, "already registered");
        require(depositAmount >= getMinimumDeposit(), "insufficient deposit");

        // WTON 전송
        IERC20(wton).transferFrom(msg.sender, address(this), depositAmount);

        validators.push(msg.sender);
        validatorIndex[msg.sender] = validators.length - 1;

        validatorInfo[msg.sender] = ValidatorInfo({
            isActive: true,
            depositAmount: depositAmount,
            pendingRewards: 0,
            lastClaimPeriod: 0,
            lastRATResponse: block.timestamp
        });

        activeValidatorCount++;

        emit ValidatorRegistered(msg.sender, depositAmount);
    }

    /// @notice 검증자 비활성화
    function deactivateValidator() external {
        ValidatorInfo storage info = validatorInfo[msg.sender];
        require(info.isActive, "not active");

        info.isActive = false;
        activeValidatorCount--;

        // 담보금 반환
        IERC20(wton).transfer(msg.sender, info.depositAmount);
        info.depositAmount = 0;

        emit ValidatorDeactivated(msg.sender);
    }

    /// @notice 최소 담보금 계산
    /// @dev 백서 V2 공식 (5): D_validator = C_off + Δ_validator
    /// @dev 07_rat_implementation.md의 getMinimumCollateral()과 동일
    function getMinimumDeposit() public view returns (uint256) {
        // 백서 V2 공식: D_validator = C_off + Δ_validator
        // minimumValidatorDeposit = slashingPenalty + validatorBuffer로 설정됨
        return minimumValidatorDeposit;
    }

    // ==========================================
    // RAT (Randomized Attention Test)
    // ==========================================

    /// @notice RAT 발행 (프로토콜 전용)
    function issueRAT(address validator, uint256 batchId)
        external
        onlyRATIssuer
    {
        require(validatorInfo[validator].isActive, "not active validator");

        bytes32 challengeId = keccak256(abi.encodePacked(validator, batchId));
        require(!ratChallenges[challengeId].responded, "already exists");

        ratChallenges[challengeId] = RATChallenge({
            validator: validator,
            batchId: batchId,
            deadline: block.timestamp + ratResponseWindow,
            responded: false,
            slashed: false
        });

        emit RATIssued(validator, batchId, block.timestamp + ratResponseWindow);
    }

    /// @notice RAT 응답
    function respondToRAT(uint256 batchId, bool attestation) external {
        bytes32 challengeId = keccak256(abi.encodePacked(msg.sender, batchId));
        RATChallenge storage challenge = ratChallenges[challengeId];

        require(challenge.validator == msg.sender, "not your challenge");
        require(!challenge.responded, "already responded");
        require(block.timestamp <= challenge.deadline, "deadline passed");

        challenge.responded = true;
        validatorInfo[msg.sender].lastRATResponse = block.timestamp;

        emit RATResponded(msg.sender, batchId, attestation);
    }

    /// @notice RAT 미응답 슬래싱
    /// @dev 백서 V2: C_off 기반 슬래싱 (전체 담보금이 아닌 페널티 금액만)
    /// @dev 실제 구현은 RAT.sol의 선차감-복구 메커니즘 사용
    /// @dev 이 함수는 07_rat_implementation.md의 triggerAttentionTest와 연동
    function slashUnresponsiveValidator(address validator, uint256 batchId)
        external
    {
        bytes32 challengeId = keccak256(abi.encodePacked(validator, batchId));
        RATChallenge storage challenge = ratChallenges[challengeId];

        require(challenge.validator == validator, "invalid challenge");
        require(!challenge.responded, "already responded");
        require(block.timestamp > challenge.deadline, "deadline not passed");
        require(!challenge.slashed, "already slashed");

        challenge.slashed = true;

        ValidatorInfo storage info = validatorInfo[validator];

        // ★ 백서 V2: C_off만 슬래싱 (전체 담보금이 아님)
        uint256 slashedAmount = slashingPenalty;
        if (info.depositAmount < slashedAmount) {
            slashedAmount = info.depositAmount;  // 잔액이 C_off 미만이면 전액
        }
        info.depositAmount -= slashedAmount;

        // ★ 백서 V2: D_min 미만이면 즉시 활성 검증자 세트에서 제거
        if (info.depositAmount < minimumThreshold) {
            info.isActive = false;
            activeValidatorCount--;
            // 잔액은 검증자가 클레임하여 출금 가능
        }

        // 슬래싱된 금액 처리 (TBD: DAO 또는 프로토콜 재무)

        emit ValidatorSlashed(validator, slashedAmount, info.depositAmount < minimumThreshold);
    }

    // ==========================================
    // 보상 분배
    // ==========================================

    /// @notice 기간 보상 분배 (SeigManager에서 호출)
    /// @dev 백서 V3 공식 (13): v_j = Σ_{i: j∈V_i} (α · S_i) / |V_i|
    /// @dev V3 백서: |V_i| = 0이면 α·S_i → DAO Treasury
    function distributePeriodRewards(uint256 periodId, uint256 totalAmount)
        external
        onlySeigManager
    {
        // V3 백서: |V_i| = 0이면 α·S_i → DAO Treasury
        if (activeValidatorCount == 0) {
            if (treasury != address(0) && totalAmount > 0) {
                IERC20(wton).transfer(treasury, totalAmount);
                emit ValidatorRewardToTreasury(periodId, totalAmount);
            }
            return;
        }

        periodValidatorPool[periodId] = totalAmount;

        // v_j = totalAmount / |V_i| (V3 공식 13)
        uint256 perValidator = totalAmount / activeValidatorCount;
        periodPerValidatorReward[periodId] = perValidator;

        // 각 활성 검증자에게 보상 누적
        for (uint256 i = 0; i < validators.length; i++) {
            address validator = validators[i];
            if (validatorInfo[validator].isActive) {
                validatorInfo[validator].pendingRewards += perValidator;
            }
        }

        emit ValidatorRewardDistributed(periodId, totalAmount, perValidator);
    }

    /// @notice 검증자 보상 청구
    function claimRewards() external {
        ValidatorInfo storage info = validatorInfo[msg.sender];
        require(info.pendingRewards > 0, "no rewards");

        uint256 rewards = info.pendingRewards;
        info.pendingRewards = 0;

        IERC20(wton).transfer(msg.sender, rewards);

        emit ValidatorRewardClaimed(msg.sender, rewards);
    }

    // ==========================================
    // 이벤트
    // ==========================================

    event ValidatorRegistered(address indexed validator, uint256 depositAmount);
    event ValidatorDeactivated(address indexed validator);
    /// @notice 백서 V2: C_off 기반 슬래싱 이벤트
    /// @param validator 슬래싱된 검증자
    /// @param slashedAmount 슬래싱된 금액 (C_off 또는 잔액 전액)
    /// @param removedFromSet D_min 미만으로 활성 세트에서 제거되었는지
    event ValidatorSlashed(address indexed validator, uint256 slashedAmount, bool removedFromSet);
    event RATIssued(address indexed validator, uint256 indexed batchId, uint256 deadline);
    event RATResponded(address indexed validator, uint256 indexed batchId, bool attestation);
    event ValidatorRewardDistributed(uint256 indexed periodId, uint256 totalAmount, uint256 perValidator);
    event ValidatorRewardClaimed(address indexed validator, uint256 amount);

    /// @notice V3 백서: 검증자 미할당 시 Treasury 귀속 이벤트
    /// @dev |V_i| = 0이면 α·S_i → DAO Treasury
    event ValidatorRewardToTreasury(uint256 indexed periodId, uint256 amount);
}
```

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

| 파일 | 설명 | 핵심 함수/변수 |
|------|------|---------------|
| `src/stake/managers/SeigManagerV1_4Storage.sol` | V3 스토리지 | `validatorDistributionRatio` (α) |
| `src/stake/managers/SeigManagerV1_4.sol` | 시뇨리지 분배 | `_distributeV3Seigniorage()`, `hyperbolicSaturation()` |
| `src/validator/RAT.sol` | RAT 검증자 관리 | `distributeValidatorReward()` - V3 공식 13 구현 |
| `src/validator/IRAT.sol` | RAT 인터페이스 | `ValidatorRewardToTreasury` 이벤트 |
| `src/layer2/Layer2ManagerV1_2.sol` | L2 관리 | `getLayer2BySystemConfig()` |

### 6.1 실제 구현 코드 참조

**RAT.sol - distributeValidatorReward() (V3 백서 반영):**

```solidity
// src/validator/RAT.sol

/// @dev V3 백서 공식 13: (α · S_i) / |V_i|
/// @dev V3 백서: 검증자가 없는 L2(|V_i| = 0)의 경우 α·S_i → DAO Treasury
function distributeValidatorReward(address systemConfig, uint256 amount)
    external
    onlySeigManager
{
    ValidatorPoolInfo storage pool = validatorPools[systemConfig];

    // V3 백서: |V_i| = 0이면 α·S_i → DAO Treasury
    if (pool.activeCount == 0) {
        if (treasury != address(0) && amount > 0) {
            IERC20(wton).safeTransfer(treasury, amount);
            emit ValidatorRewardToTreasury(systemConfig, amount);
        }
        return;
    }

    // V3 공식 13: (α · S_i) / |V_i|
    uint256 perValidator = amount / pool.activeCount;

    // 각 활성 검증자에게 보상 누적
    address[] storage validators = pool.validators;
    uint256 len = validators.length;
    for (uint256 i = 0; i < len; i++) {
        ValidatorRegistration storage reg = validatorRegistrations[systemConfig][validators[i]];
        if (reg.isActive) {
            reg.pendingRewards += perValidator;
        }
    }
}
```

---

## 7. V3 백서 준수 확인

| 항목 | V3 백서 요구사항 | 구현 상태 |
|------|-----------------|----------|
| 공식 (11) | y(x) = L · (x / (k + x)) | ✅ hyperbolicSaturation() |
| 공식 (12) | S_i = y(x) · (B̃_i / x) | ✅ calculateL2Seigniorage() |
| 공식 (13) | v_j = Σ_{i: j∈V_i} (α · S_i) / \|V_i\| | ✅ RAT.distributeValidatorReward() |
| 공식 (14) | o_i = (1 − α) · S_i | ✅ calculateSequencerReward() |
| \|V_i\| = 0 처리 | α·S_i → DAO Treasury | ✅ ValidatorRewardToTreasury 이벤트 |
| **측정 방식** | 온체인 호출 시점 최신값 | ✅ getBridgedTON(), checkCurrentEligibility() |

### 7.1 V3 측정 방식 준수 확인

코드에서 V3 측정 방식이 적용되어 있습니다:

```solidity
// SeigManagerV1_4.sol:345 - Bridged TON 실시간 조회
uint256 bridgedTON = ILayer2Manager(layer2Manager).getBridgedTONByLayer(layer2);

// SeigManagerV1_4.sol:351 - Staked TON 실시간 조회
currentStake = _getSequencerStake(layer2);

// SeigManagerV1_4.sol:913 - L2 TVL 현재값 조회
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
- `docs/for-llm-kr/whitepaper_v2_to_v3_changes.md` - V2 → V3 변경사항
- `docs/for-llm-kr/02_v3_distribution.md` - V3 분배 공식 상세
- `docs/for-llm-kr/04_validator.md` - 검증자 보상 상세
- `docs/for-llm-kr/07_rat_implementation.md` - RAT 구현 상세

---

## 9. 변경 이력

| 날짜 | 내용 |
|------|------|
| 2025-12-18 | V3 백서 반영: 공식 (13), (14) 업데이트, \|V_i\|=0 Treasury 처리 추가 |

