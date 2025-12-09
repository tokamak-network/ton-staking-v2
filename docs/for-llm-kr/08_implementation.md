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

    /// @notice α_v: 검증자 분배 비율 (0 < α_v < 1), RAY 단위
    /// @dev 백서 공식 (13): v_i = (α_v/n) · y(x)
    uint256 public validatorDistributionRatio;

    /// @notice k: 반포화점 (half-saturation point), RAY 단위
    /// @dev 백서 공식 (11): y(k) = L/2
    uint256 public halfSaturationPoint;

    /// @notice λ: 지분 시뇨리지 비율 (전환용), RAY 단위
    /// @dev λ = 1.0: V2와 동일, λ = 0: 지분 시뇨리지 없음
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
    struct BridgedTONInfo {
        uint256 currentBridgedTON;      // B_i: 현재 Bridged TON
        uint256 effectiveBridgedTON;    // B̃_i: 유효 Bridged TON (자격 없으면 0)
        uint256 initialDebt;            // 초기부채 (V2 패턴 동일)
        uint256 startBlock;             // 참여 시작 블록
        uint256 lastUpdateTime;         // 마지막 업데이트 타임스탬프
        bool isEligible;                // 자격 여부 (S_i ≥ θ·B_i)
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
        uint256 validatorPoolAmount;    // α_v · y(x)
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

### 2.1 전환 파라미터 설정 함수

```solidity
/// @notice 지분 시뇨리지 비율 설정 (거버넌스)
function setStakedSeigFactor(uint256 newLambda) external onlyOwner {
    require(newLambda <= RAY, "lambda > 1");
    stakedSeigFactor = newLambda;
    emit StakedSeigFactorUpdated(newLambda);
}

/// @notice 추가 시뇨리지 비율 설정 (거버넌스) - 기존 함수 사용
/// @dev relativeSeigRate는 기존 SeigManagerStorage에 존재
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
/// @dev 백서 공식 (13): o_i = (1 - α_v) · Seig_i
function calculateSequencerReward(uint256 l2Seigniorage)
    public view
    returns (uint256)
{
    return rmul(l2Seigniorage, RAY - validatorDistributionRatio);
}
```

### 2.4 수정된 _updateSeigniorage 로직 (순차적 분배)

```solidity
function _updateSeigniorage() internal ifFree returns (bool) {
    if (paused) return true;

    uint256 prevTotalSupply = _tot.totalSupply();
    uint256 blockDelta = block.number - _lastSeigBlock;
    if (blockDelta == 0) return false;

    // ========================================
    // A = 전체 기간 시뇨리지
    // ========================================
    uint256 A = blockDelta * _seigPerBlock;

    // ========================================
    // Step 1: 스테이커 지분 시뇨리지 (λ 적용)
    // S_staked = λ · A · (S / T)
    // S = 총 스테이킹 금액 (WTON 총 공급량)
    // T = TON 총 발행량
    // ========================================
    uint256 T = ITON(_ton).totalSupply();
    uint256 S = IWTON(_wton).totalSupply();  // 스테이킹 금액

    uint256 S_staked = FullMath.rmul(
        FullMath.rmul(A, stakedSeigFactor),  // λ · A
        FullMath.rdiv(S, T)                  // × (S / T)
    );

    // A₁ = A - S_staked (1차 잔여)
    uint256 A1 = A - S_staked;

    // ========================================
    // Step 2: 스테이커 추가 시뇨리지 (r 적용)
    // S_relative = A₁ · r
    // ========================================
    uint256 S_relative = FullMath.rmul(A1, relativeSeigRate);  // A₁ · r

    // A₂ = A₁ - S_relative (2차 잔여 = V3 분배 재원)
    uint256 A2 = A1 - S_relative;

    // ========================================
    // 스테이커 분배 (Coinage factor 업데이트)
    // ========================================
    uint256 totalStakerSeig = S_staked + S_relative;
    uint256 nextTotalSupply = prevTotalSupply + totalStakerSeig;
    _tot.setFactor(_calcNewFactor(prevTotalSupply, nextTotalSupply, _tot.factor()));

    _lastSeigBlock = block.number;

    // ========================================
    // Step 3: V3 분배 (A₂ 기준, 백서 공식 적용)
    // ========================================
    if (A2 > 0) {
        _distributeV3Seigniorage(A2);
    }

    emit SeigGivenV3(A, S_staked, S_relative, A2);
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

        // 검증자 풀: α_v · y(x) (백서 공식 13)
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
/// @notice V3 시뇨리지 분배 이벤트 (V2의 SeigGiven2 대체)
event SeigGivenV3(
    address indexed layer2,
    uint256 totalSeigniorage,   // A: 기간 시뇨리지
    uint256 daoAllocation,      // d·A₂: DAO 고정분
    uint256 l2MaxAllocation,    // L = (1-d)·A₂: 분배 가능량
    uint256 totalEffectiveBridgedTON, // x: 전체 유효 Bridged TON
    uint256 totalDistributed,   // y(x): 쌍곡선 결과
    uint256 l2Seigniorage,      // Seig_i: 해당 L2 분배량
    uint256 sequencerReward,    // o_i: 시퀀서 보상
    uint256 validatorPoolAmount,// α_v·y(x): 검증자 풀
    uint256 undistributed       // L - y(x): DAO 추가분
);

/// @notice 전환 파라미터 변경 이벤트
event TransitionFactorsUpdated(
    uint256 stakedSeigFactor,   // λ
    uint256 relativeSeigRate    // r
);

/// @notice 전환으로 인한 시뇨리지 재분배 이벤트
event SeigniorageRedirected(
    uint256 stakedSeigReduction,    // 지분 시뇨리지 감소분
    uint256 relativeSeigReduction,  // 추가 시뇨리지 감소분
    uint256 totalToV3Pool           // V3 풀로 이동된 총량
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

    /// @notice 최소 검증자 담보금
    uint256 public minimumValidatorDeposit;
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
    /// @dev 백서 공식 (6): D_validator = (c_m·N)/π_a + Δ_validator
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
    /// @dev 백서 공식 (5): D_validator ≥ (c_m·N)/π_a
    function getMinimumDeposit() public view returns (uint256) {
        // 구현: 프로토콜 파라미터 기반 계산
        // 간소화: 고정값 사용 가능
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
    /// @dev 백서: "full collateral slashing"
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
        uint256 slashedAmount = info.depositAmount;

        info.depositAmount = 0;
        info.isActive = false;
        activeValidatorCount--;

        // 슬래싱된 금액은 프로토콜 재무로
        // (또는 DAO로 전송)

        emit ValidatorSlashed(validator, slashedAmount);
    }

    // ==========================================
    // 보상 분배
    // ==========================================

    /// @notice 기간 보상 분배 (SeigManager에서 호출)
    /// @dev 백서 공식 (13): v_i = (α_v/n) · y(x)
    function distributePeriodRewards(uint256 periodId, uint256 totalAmount)
        external
        onlySeigManager
    {
        require(activeValidatorCount > 0, "no active validators");

        periodValidatorPool[periodId] = totalAmount;

        // v_i = totalAmount / n
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
    event ValidatorSlashed(address indexed validator, uint256 amount);
    event RATIssued(address indexed validator, uint256 indexed batchId, uint256 deadline);
    event RATResponded(address indexed validator, uint256 indexed batchId, bool attestation);
    event ValidatorRewardDistributed(uint256 indexed periodId, uint256 totalAmount, uint256 perValidator);
    event ValidatorRewardClaimed(address indexed validator, uint256 amount);
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

```solidity
/// @notice Bridged TON 조회 (L1 브리지에서 직접)
/// @param rollupConfig RollupConfig 주소
function getBridgedTON(address rollupConfig) public view returns (uint256) {
    // L1BridgeRegistry를 통해 브리지 주소 조회
    (bool valid, address l1Bridge,,) = IL1BridgeRegistry(l1BridgeRegistry)
        .checkL1Bridge(rollupConfig);

    if (!valid) return 0;

    // 브리지 컨트랙트에서 잠긴 TON 양 조회
    return IERC20(ton).balanceOf(l1Bridge);
}

/// @notice CandidateAddOn 등록 시 초기 Bridged TON 설정
function registerCandidateAddOnV3(
    address rollupConfig,
    uint256 amount,
    bool flagTon,
    string calldata memo
) external {
    // 기존 V2 등록 로직...
    _registerCandidateAddOn(rollupConfig, amount, flagTon, memo);

    // V3 신규: 초기 Bridged TON 설정
    uint256 initialBridgedTON = getBridgedTON(rollupConfig);
    cachedBridgedTON[rollupConfig] = initialBridgedTON;

    // SeigManager에 알림
    ISeigManagerV3(seigManager).initializeBridgedTON(
        operatorInfo[rollupConfigInfo[rollupConfig].operatorManager].candidateAddOn,
        initialBridgedTON
    );
}
```

