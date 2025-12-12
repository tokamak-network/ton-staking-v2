---
id: 08_implementation
slug: /08_implementation
---
# V3 Implementation Code

## 1. SeigManagerV1_4Storage (New Storage)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract SeigManagerV1_4Storage {
    // ==========================================
    // V3 Core Parameters (Based on Whitepaper)
    // ==========================================

    /// @notice d: DAO distribution ratio (0 < d < 1), RAY unit
    /// @dev Whitepaper formula (7): S_DAO = d · A₂
    uint256 public daoDistributionRatio;

    /// @notice θ: Minimum staking ratio (0 < θ ≤ 1), RAY unit
    /// @dev Whitepaper formula (8): S_i ≥ θ · B_i
    uint256 public minStakingRatio;

    /// @notice α_v: Validator distribution ratio (0 < α_v < 1), RAY unit
    /// @dev Whitepaper formula (13): v_i = (α_v/n) · y(x)
    uint256 public validatorDistributionRatio;

    /// @notice k: Half-saturation point, RAY unit
    /// @dev Whitepaper formula (11): y(k) = L/2
    uint256 public halfSaturationPoint;

    /// @notice λ: Share seigniorage ratio (for transition), RAY unit
    /// @dev λ = 1.0: Same as V2, λ = 0: No share seigniorage
    uint256 public stakedSeigFactor;

    // ==========================================
    // Bridged TON Related Storage
    // ==========================================

    /// @notice Total effective Bridged TON sum: x = Σ B̃_i
    uint256 public totalEffectiveBridgedTON;

    /// @notice Accumulated reward per Bridged TON unit (corresponds to V2's l2RewardPerUint)
    /// @dev bridgedTONRewardPerUint = Accumulated value of Σ(y(x) / x)
    uint256 public bridgedTONRewardPerUint;

    /// @notice Per-L2 Bridged TON information
    struct BridgedTONInfo {
        uint256 currentBridgedTON;      // B_i: Current Bridged TON
        uint256 effectiveBridgedTON;    // B̃_i: Effective Bridged TON (0 if ineligible)
        uint256 initialDebt;            // Initial debt (same pattern as V2)
        uint256 startBlock;             // Participation start block
        uint256 lastUpdateTime;         // Last update timestamp
        bool isEligible;                // Eligibility status (S_i ≥ θ·B_i)
    }

    /// @notice layer2 => BridgedTONInfo
    mapping(address => BridgedTONInfo) public bridgedTONInfo;

    // ==========================================
    // Validator Pool Related
    // ==========================================

    /// @notice ValidatorPool contract address
    address public validatorPool;

    /// @notice Period information
    struct PeriodInfo {
        uint256 startBlock;
        uint256 endBlock;
        uint256 totalSeigniorage;
        uint256 totalDistributed;       // y(x)
        uint256 validatorPoolAmount;    // α_v · y(x)
        bool finalized;
    }

    /// @notice Current period ID
    uint256 public currentPeriodId;

    /// @notice Period information mapping
    mapping(uint256 => PeriodInfo) public periods;

}
```

---

## 2. SeigManagerV1_4 Core Functions

### 2.1 Transition Parameter Setting Functions

```solidity
/// @notice Set share seigniorage ratio (governance)
function setStakedSeigFactor(uint256 newLambda) external onlyOwner {
    require(newLambda <= RAY, "lambda > 1");
    stakedSeigFactor = newLambda;
    emit StakedSeigFactorUpdated(newLambda);
}

/// @notice Set additional seigniorage ratio (governance) - Use existing function
/// @dev relativeSeigRate exists in existing SeigManagerStorage
function setRelativeSeigRate(uint256 newRate) external onlyOwner {
    require(newRate <= RAY, "rate > 1");
    relativeSeigRate = newRate;
    emit RelativeSeigRateUpdated(newRate);
}
```

### 2.2 Hyperbolic Saturation Function

```solidity
/// @notice Hyperbolic saturation function
/// @dev Whitepaper formula (11): y(x) = L · (x / (k + x))
/// @param x Total effective Bridged TON
/// @return y Distributable seigniorage
function hyperbolicSaturation(uint256 x, uint256 maxL2Allocation)
    public view
    returns (uint256 y)
{
    if (x == 0) return 0;

    // L = (1 - d) · A₂ (based on period seigniorage)
    // k = halfSaturationPoint

    // y(x) = L · (x / (k + x))
    // = (L * x) / (k + x)
    y = rdiv(rmul(maxL2Allocation, x), halfSaturationPoint + x);
}
```

### 2.3 Individual L2 Seigniorage Calculation

```solidity
/// @notice Individual L2 seigniorage calculation
/// @dev Whitepaper formula (12): Seig_i = y(x) · (B̃_i / x)
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

/// @notice Sequencer reward calculation
/// @dev Whitepaper formula (13): o_i = (1 - α_v) · Seig_i
function calculateSequencerReward(uint256 l2Seigniorage)
    public view
    returns (uint256)
{
    return rmul(l2Seigniorage, RAY - validatorDistributionRatio);
}
```

### 2.4 Modified _updateSeigniorage Logic (Sequential Distribution)

```solidity
function _updateSeigniorage() internal ifFree returns (bool) {
    if (paused) return true;

    uint256 prevTotalSupply = _tot.totalSupply();
    uint256 blockDelta = block.number - _lastSeigBlock;
    if (blockDelta == 0) return false;

    // ========================================
    // A = Total period seigniorage
    // ========================================
    uint256 A = blockDelta * _seigPerBlock;

    // ========================================
    // Step 1: Staker share seigniorage (λ applied)
    // S_staked = λ · A · (S / T)
    // S = Total staking amount (WTON total supply)
    // T = TON total supply
    // ========================================
    uint256 T = ITON(_ton).totalSupply();
    uint256 S = IWTON(_wton).totalSupply();  // Staking amount

    uint256 S_staked = FullMath.rmul(
        FullMath.rmul(A, stakedSeigFactor),  // λ · A
        FullMath.rdiv(S, T)                  // × (S / T)
    );

    // A₁ = A - S_staked (1st remainder)
    uint256 A1 = A - S_staked;

    // ========================================
    // Step 2: Staker additional seigniorage (r applied)
    // S_relative = A₁ · r
    // ========================================
    uint256 S_relative = FullMath.rmul(A1, relativeSeigRate);  // A₁ · r

    // A₂ = A₁ - S_relative (2nd remainder = V3 distribution source)
    uint256 A2 = A1 - S_relative;

    // ========================================
    // Staker distribution (Coinage factor update)
    // ========================================
    uint256 totalStakerSeig = S_staked + S_relative;
    uint256 nextTotalSupply = prevTotalSupply + totalStakerSeig;
    _tot.setFactor(_calcNewFactor(prevTotalSupply, nextTotalSupply, _tot.factor()));

    _lastSeigBlock = block.number;

    // ========================================
    // Step 3: V3 Distribution (A₂ basis, whitepaper formula applied)
    // ========================================
    if (A2 > 0) {
        _distributeV3Seigniorage(A2);
    }

    emit SeigGivenV3(A, S_staked, S_relative, A2);
    return true;
}

/// @notice V3 seigniorage distribution (whitepaper formula applied)
/// @param A2 V3 distribution source (remainder after staker distribution)
function _distributeV3Seigniorage(uint256 A2) internal {
    // ========================================
    // DAO fixed distribution (Whitepaper formula 7)
    // S_DAO = d · A₂
    // ========================================
    uint256 S_DAO = FullMath.rmul(A2, daoDistributionRatio);

    // ========================================
    // L2 distribution capacity
    // L = (1 - d) · A₂
    // ========================================
    uint256 L = A2 - S_DAO;

    // ========================================
    // Hyperbolic saturation function (Whitepaper formula 11)
    // y(x) = L · (x / (k + x))
    // ========================================
    uint256 x = totalEffectiveBridgedTON;  // Cached value
    uint256 y = 0;
    uint256 validatorPoolAmount = 0;

    if (x > 0) {
        // y(x) = L · (x / (k + x))
        y = FullMath.rmul(L, FullMath.rdiv(x, halfSaturationPoint + x));

        // Validator pool: α_v · y(x) (Whitepaper formula 13)
        validatorPoolAmount = FullMath.rmul(y, validatorDistributionRatio);

        // Accumulate reward per unit (for sequencer)
        uint256 sequencerTotal = y - validatorPoolAmount;
        bridgedTONRewardPerUint += (sequencerTotal * WEI_UNIT) / x;

        // Mint to L2Manager (for sequencer reward)
        if (sequencerTotal > 0) {
            IWTON(_wton).mint(layer2Manager, sequencerTotal);
        }
    }

    // ========================================
    // Undistributed portion to DAO
    // totalDAO = S_DAO + (L - y(x))
    // ========================================
    uint256 undistributed = L - y;
    uint256 totalDAO = S_DAO + undistributed;

    if (totalDAO > 0) {
        IWTON(_wton).mint(dao, totalDAO);
    }

    // Validator pool distribution
    if (validatorPoolAmount > 0 && validatorPool != address(0)) {
        IWTON(_wton).mint(validatorPool, validatorPoolAmount);
    }

    emit V3SeigniorageDistributed(A2, L, y, totalDAO, validatorPoolAmount);
}
```

### 2.5 V2 → V3 Key Changes

```solidity
// V2
l2RewardPerUint += (l2TotalSeigs * WEI_UNIT) / totalLayer2TVL;
layer2Seigs = (l2RewardPerUint * layer2Tvl) / WEI_UNIT - initialDebt;

// V3 (Same pattern, different input)
bridgedTONRewardPerUint += (totalY * WEI_UNIT) / totalEffectiveBridgedTON;
layer2Seigs = (bridgedTONRewardPerUint * effectiveBridgedTON) / WEI_UNIT - initialDebt;
//             └── y(x) / x = L / (k+x) hyperbolic ──┘   └── B̃_i ──┘
```

---

## 3. Events

```solidity
/// @notice V3 seigniorage distribution event (replaces V2's SeigGiven2)
event SeigGivenV3(
    address indexed layer2,
    uint256 totalSeigniorage,   // A: Period seigniorage
    uint256 daoAllocation,      // d·A₂: DAO fixed portion
    uint256 l2MaxAllocation,    // L = (1-d)·A₂: Distribution capacity
    uint256 totalEffectiveBridgedTON, // x: Total effective Bridged TON
    uint256 totalDistributed,   // y(x): Hyperbolic result
    uint256 l2Seigniorage,      // Seig_i: Per-L2 distribution
    uint256 sequencerReward,    // o_i: Sequencer reward
    uint256 validatorPoolAmount,// α_v·y(x): Validator pool
    uint256 undistributed       // L - y(x): DAO additional portion
);

/// @notice Transition parameter change event
event TransitionFactorsUpdated(
    uint256 stakedSeigFactor,   // λ
    uint256 relativeSeigRate    // r
);

/// @notice Seigniorage redistribution event due to transition
event SeigniorageRedirected(
    uint256 stakedSeigReduction,    // Share seigniorage reduction
    uint256 relativeSeigReduction,  // Additional seigniorage reduction
    uint256 totalToV3Pool           // Total moved to V3 pool
);
```

---

## 4. ValidatorPoolV1 (New Contract)

### 4.1 Overview

A new contract that distributes RAT-based rewards to validators.

### 4.2 Storage

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ValidatorPoolStorage {
    // ==========================================
    // Validator Information
    // ==========================================

    struct ValidatorInfo {
        bool isActive;
        uint256 depositAmount;      // D_validator
        uint256 pendingRewards;
        uint256 lastClaimPeriod;
        uint256 lastRATResponse;
    }

    /// @notice Validator list
    address[] public validators;

    /// @notice Validator information mapping
    mapping(address => ValidatorInfo) public validatorInfo;

    /// @notice Validator index mapping
    mapping(address => uint256) public validatorIndex;

    /// @notice Active validator count (n)
    uint256 public activeValidatorCount;

    // ==========================================
    // RAT Related
    // ==========================================

    struct RATChallenge {
        address validator;
        uint256 batchId;
        uint256 deadline;
        bool responded;
        bool slashed;
    }

    /// @notice RAT challenge mapping
    mapping(bytes32 => RATChallenge) public ratChallenges;

    /// @notice RAT occurrence probability (π_a)
    uint256 public ratProbability;

    /// @notice RAT response window
    uint256 public ratResponseWindow;

    // ==========================================
    // Reward Related
    // ==========================================

    /// @notice Per-period validator pool total
    mapping(uint256 => uint256) public periodValidatorPool;

    /// @notice Per-period per-validator reward
    mapping(uint256 => uint256) public periodPerValidatorReward;

    // ==========================================
    // References
    // ==========================================

    address public seigManager;
    address public wton;
    address public ton;

    /// @notice Minimum validator collateral
    uint256 public minimumValidatorDeposit;
}
```

### 4.3 Core Functions

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ValidatorPoolStorage.sol";

contract ValidatorPoolV1 is ValidatorPoolStorage {

    // ==========================================
    // Validator Management
    // ==========================================

    /// @notice Validator registration
    /// @dev Whitepaper formula (6): D_validator = (c_m·N)/π_a + Δ_validator
    function registerValidator(uint256 depositAmount) external {
        require(!validatorInfo[msg.sender].isActive, "already registered");
        require(depositAmount >= getMinimumDeposit(), "insufficient deposit");

        // WTON transfer
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

    /// @notice Validator deactivation
    function deactivateValidator() external {
        ValidatorInfo storage info = validatorInfo[msg.sender];
        require(info.isActive, "not active");

        info.isActive = false;
        activeValidatorCount--;

        // Return collateral
        IERC20(wton).transfer(msg.sender, info.depositAmount);
        info.depositAmount = 0;

        emit ValidatorDeactivated(msg.sender);
    }

    /// @notice Minimum collateral calculation
    /// @dev Whitepaper formula (5): D_validator ≥ (c_m·N)/π_a
    function getMinimumDeposit() public view returns (uint256) {
        // Implementation: Calculate based on protocol parameters
        // Simplified: Can use fixed value
        return minimumValidatorDeposit;
    }

    // ==========================================
    // RAT (Randomized Attention Test)
    // ==========================================

    /// @notice RAT issuance (protocol only)
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

    /// @notice RAT response
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

    /// @notice RAT non-response slashing
    /// @dev Whitepaper: "full collateral slashing"
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

        // Slashed amount goes to protocol treasury
        // (or transfer to DAO)

        emit ValidatorSlashed(validator, slashedAmount);
    }

    // ==========================================
    // Reward Distribution
    // ==========================================

    /// @notice Period reward distribution (called from SeigManager)
    /// @dev Whitepaper formula (13): v_i = (α_v/n) · y(x)
    function distributePeriodRewards(uint256 periodId, uint256 totalAmount)
        external
        onlySeigManager
    {
        require(activeValidatorCount > 0, "no active validators");

        periodValidatorPool[periodId] = totalAmount;

        // v_i = totalAmount / n
        uint256 perValidator = totalAmount / activeValidatorCount;
        periodPerValidatorReward[periodId] = perValidator;

        // Accumulate rewards for each active validator
        for (uint256 i = 0; i < validators.length; i++) {
            address validator = validators[i];
            if (validatorInfo[validator].isActive) {
                validatorInfo[validator].pendingRewards += perValidator;
            }
        }

        emit ValidatorRewardDistributed(periodId, totalAmount, perValidator);
    }

    /// @notice Validator reward claim
    function claimRewards() external {
        ValidatorInfo storage info = validatorInfo[msg.sender];
        require(info.pendingRewards > 0, "no rewards");

        uint256 rewards = info.pendingRewards;
        info.pendingRewards = 0;

        IERC20(wton).transfer(msg.sender, rewards);

        emit ValidatorRewardClaimed(msg.sender, rewards);
    }

    // ==========================================
    // Events
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

## 5. Layer2ManagerV1_2 (Upgrade)

### 5.1 New Storage

```solidity
contract Layer2ManagerV1_2Storage {
    // V1_1 storage inheritance...

    // ==========================================
    // V3 New: Bridged TON Query Related
    // ==========================================

    /// @notice Per-L2 latest Bridged TON (cached, optional)
    mapping(address => uint256) public cachedBridgedTON;
}
```

### 5.2 New Functions

```solidity
/// @notice Bridged TON query (directly from L1 bridge)
/// @param rollupConfig RollupConfig address
function getBridgedTON(address rollupConfig) public view returns (uint256) {
    // Query bridge address via L1BridgeRegistry
    (bool valid, address l1Bridge,,) = IL1BridgeRegistry(l1BridgeRegistry)
        .checkL1Bridge(rollupConfig);

    if (!valid) return 0;

    // Query locked TON amount from bridge contract
    return IERC20(ton).balanceOf(l1Bridge);
}

/// @notice Set initial Bridged TON when registering CandidateAddOn
function registerCandidateAddOnV3(
    address rollupConfig,
    uint256 amount,
    bool flagTon,
    string calldata memo
) external {
    // Existing V2 registration logic...
    _registerCandidateAddOn(rollupConfig, amount, flagTon, memo);

    // V3 New: Set initial Bridged TON
    uint256 initialBridgedTON = getBridgedTON(rollupConfig);
    cachedBridgedTON[rollupConfig] = initialBridgedTON;

    // Notify SeigManager
    ISeigManagerV3(seigManager).initializeBridgedTON(
        operatorInfo[rollupConfigInfo[rollupConfig].operatorManager].candidateAddOn,
        initialBridgedTON
    );
}
```
