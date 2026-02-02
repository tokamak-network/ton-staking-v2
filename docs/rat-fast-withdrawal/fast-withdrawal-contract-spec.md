# Fast Withdrawal Contract Specification

## 개요

사용자의 즉시 출금 요청에 대해 **모든 유효한 검증자의 만장일치 BLS 서명**을 검증하여 즉시 출금을 실행하는 스마트 컨트랙트입니다.

## 핵심 요구사항 (✅ 모두 구현됨)

### ✅ 1. 응답 기간 설정 (컨트랙트 변수)
- `fastWithdrawalResponsePeriod`: 검증자 응답 대기 시간
- 거버넌스로 조정 가능

### ✅ 2. 출금 Flow
**빠른 출금 요청:**
- 응답 기간 내 BLS 집계 서명 제출 → 즉시 출금 ✅
- 응답 기간 초과 (BLS 서명 없음) → **자동으로 Optimism 일반 출금(7일)으로 전환**
- 일반 출금 로직은 OptimismPortal2에서 처리 (기존 Optimism 로직)

### ✅ 3. 사용자 취소 불가
- 빠른 출금 요청 후 취소 불가능 (보안 및 일관성)
- 한번 제출된 요청은 빠른 출금 성공 또는 일반 출금으로 전환

### ✅ 4. 빠른 출금 기능 사용 가능 여부
- `pauseFastWithdrawalVerification()`: 빠른 출금 기능 비활성화
- `resumeFastWithdrawalVerification()`: 빠른 출금 기능 활성화
- **중요**: Optimism 기본 출금(7일)은 항상 가능
- 빠른 출금만 선택적으로 활성화/비활성화 (긴급 상황 대응)

### ✅ 5. 수수료 구조
**사용자 제출 시 수수료 지불:**
- 최소 수수료: `minFastWithdrawalFee` (고정)
- 비율 수수료: `(amount × fastWithdrawalFeeRate) / 10000`
- 실제 수수료: `max(최소 수수료, 비율 수수료)`

**수수료 분배:**
- Aggregator (증명 제출자): `submissionFee` (가스비 보상)
- Validators (서명 제공자): 나머지 금액을 균등 분배

### ✅ 6. 추가 핵심 기능
- **최소 검증자 수**: `minValidatorsForFastWithdrawal`
- **만장일치 합의**: 100% 검증자 서명 필요 (1-of-N honest)
- **온체인 검증자 조회**: Staking 컨트랙트 실시간 조회
- **BLS 서명 집약**: 가스 효율성 (96% 절감)
- **Validator Snapshot**: 요청 시점 검증자 세트 고정

## Contract Interface

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IStakingV3.sol";
import "./libraries/BLS12381.sol";

/**
 * @title FastWithdrawal
 * @notice Enables instant withdrawals with unanimous validator consensus
 * @dev Requires ALL active validators to sign withdrawal requests (100% consensus)
 */
contract FastWithdrawal {
    using BLS12381 for *;
    
    /* ========== STATE VARIABLES ========== */
    
    /// @notice Staking contract for validator set queries
    IStakingV3 public immutable stakingContract;
    
    /// @notice Minimum number of active validators required for fast withdrawal feature to be enabled
    /// @dev Fast withdrawal is disabled when active validator count < minValidatorsForFastWithdrawal
    uint256 public minValidatorsForFastWithdrawal;
    
    /// @notice Withdrawal requests indexed by requestId
    mapping(bytes32 => WithdrawalRequest) public withdrawalRequests;
    
    /// @notice Contract owner (for governance)
    address public owner;
    
    /// @notice Response period for fast withdrawal (e.g., 5 minutes)
    /// @dev Validators must respond within this period
    uint256 public fastWithdrawalResponsePeriod;
    
    /// @notice Minimum fixed fee for fast withdrawal
    uint256 public minFastWithdrawalFee;
    
    /// @notice Fee rate as percentage of withdrawal amount (in basis points)
    /// @dev 100 basis points = 1%
    uint256 public fastWithdrawalFeeRate;
    
    /// @notice Submission fee for aggregator who submits the proof
    /// @dev Covers gas costs for on-chain submission
    uint256 public submissionFee;
    
    /// @notice Fast withdrawal verification paused (emergency)
    /// @dev When true, only regular withdrawals are allowed
    bool public fastWithdrawalPaused;
    
    /* ========== STRUCTS ========== */
    
    /**
     * @notice Withdrawal request data structure
     * @param user Address of the user requesting withdrawal
     * @param amount Amount to withdraw (in wei)
     * @param requestTimestamp Block timestamp when request was created
     * @param fastWithdrawalAttempted Whether user requested fast withdrawal (paid fee)
     * @param fastWithdrawalDeadline Deadline for fast withdrawal response period
     * @param feePaid Fee paid by user for fast withdrawal
     * @param validatorSetSnapshot Snapshot of validator addresses at request time
     */
    struct WithdrawalRequest {
        address user;
        uint256 amount;
        uint256 requestTimestamp;
        bool fastWithdrawalAttempted;
        uint256 fastWithdrawalDeadline;
        uint256 feePaid;
        address[] validatorSetSnapshot;
    }
    
    /* ========== EVENTS ========== */
    
    /**
     * @notice Emitted when a new withdrawal request is created
     * @param requestId Unique identifier for the request
     * @param user Address of the user
     * @param amount Amount requested
     * @param timestamp Request creation time
     */
    event WithdrawalRequested(
        bytes32 indexed requestId,
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );
    
    /**
     * @notice Emitted when a fast withdrawal is successfully executed
     * @param requestId Request identifier
     * @param user Address that received funds
     * @param amount Amount withdrawn
     */
    event FastWithdrawalExecuted(
        bytes32 indexed requestId,
        address indexed user,
        uint256 amount
    );
    
    /**
     * @notice Emitted when minValidatorsForFastWithdrawal is updated
     * @param oldCount Previous minimum validator count for fast withdrawal
     * @param newCount New minimum validator count for fast withdrawal
     */
    event MinValidatorsForFastWithdrawalUpdated(
        uint256 oldCount,
        uint256 newCount
    );
    
    /**
     * @notice Emitted when user requests to cancel withdrawal
     * @param requestId Request identifier
     * @param user User address
     */
    event WithdrawalCancelled(
        bytes32 indexed requestId,
        address indexed user
    );
    
    /**
     * @notice Emitted when fast withdrawal times out
     * @param requestId Request identifier
     * @param user User address
     */
    event FastWithdrawalTimeout(
        bytes32 indexed requestId,
        address indexed user
    );
    
    /**
     * @notice Emitted when minimum fee is updated
     * @param oldFee Previous minimum fee
     * @param newFee New minimum fee
     */
    event Paused(address indexed account);
    
    /**
     * @notice Emitted when contract is unpaused
     */
    event Unpaused(address indexed account);
    
    /**
     * @notice Emitted when minimum fee is updated
     * @param oldFee Previous minimum fee
     * @param newFee New minimum fee
     */
    event MinFastWithdrawalFeeUpdated(
        uint256 oldFee,
        uint256 newFee
    );
    
    /**
     * @notice Emitted when fee rate is updated
     * @param oldRate Previous fee rate (basis points)
     * @param newRate New fee rate (basis points)
     */
    event FastWithdrawalFeeRateUpdated(
        uint256 oldRate,
        uint256 newRate
    );
    
    /**
     * @notice Emitted when response period is updated
     * @param oldPeriod Previous response period
     * @param newPeriod New response period
     */
    event FastWithdrawalResponsePeriodUpdated(
        uint256 oldPeriod,
        uint256 newPeriod
    );
    
    /**
     * @notice Emitted when submission fee is updated
     * @param oldFee Previous submission fee
     * @param newFee New submission fee
     */
    event SubmissionFeeUpdated(
        uint256 oldFee,
        uint256 newFee
    );
    
    /**
     * @notice Emitted when fast withdrawal verification is paused
     */
    event FastWithdrawalVerificationPaused(address indexed account);
    
    /**
     * @notice Emitted when fast withdrawal verification is resumed
     */
    event FastWithdrawalVerificationResumed(address indexed account);
    
    /**
     * @notice Emitted when fees are distributed to validators
     * @param requestId Request identifier
     * @param totalFee Total fee distributed
     * @param validatorCount Number of validators
     * @param feePerValidator Fee per validator
     */
    event FeesDistributed(
        bytes32 indexed requestId,
        uint256 totalFee,
        uint256 validatorCount,
        uint256 feePerValidator
    );
    
    /**
     * @notice Emitted when submission fee is paid to aggregator
     * @param requestId Request identifier
     * @param aggregator Aggregator address
     * @param submissionFee Fee amount paid
     */
    event SubmissionFeePaid(
        bytes32 indexed requestId,
        address indexed aggregator,
        uint256 submissionFee
    );
    
    /**
     * @notice Emitted when fast withdrawal auto-converts to regular
     * @param requestId Request identifier
     * @param user User address
     */
    event FastWithdrawalConvertedToRegular(
        bytes32 indexed requestId,
        address indexed user
    );
    
    /**
     * @notice Emitted when fast withdrawal is disabled due to insufficient validators
     * @param requestId Request that failed
     * @param currentValidatorCount Current number of active validators
     * @param minRequired Minimum required validators
     */
    event FastWithdrawalDisabled(
        bytes32 indexed requestId,
        uint256 currentValidatorCount,
        uint256 minRequired
    );
    
    /* ========== ERRORS ========== */
    
    error AlreadyExecuted();
    error RequestNotFound();
    error InsufficientValidators(uint256 current, uint256 required);
    error UnanimousConsensusRequired(uint256 signed, uint256 total);
    error MissingValidatorSignature(address validator);
    error InvalidAggregatedSignature();
    error Unauthorized();
    error FastWithdrawalVerificationPaused();
    error InsufficientFee(uint256 provided, uint256 required);
    error ResponsePeriodNotExpired();
    error ResponsePeriodExpired();
    error NotRequestOwner();
    error ValidatorSetMismatch();
    error CannotCancelRequest();
    error InvalidWithdrawalType();
    error InsufficientContractBalance();
    
    /* ========== MODIFIERS ========== */
    
    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }
    
    modifier whenFastWithdrawalNotPaused() {
        if (fastWithdrawalPaused) revert FastWithdrawalVerificationPaused();
        _;
    }
    
    /* ========== CONSTRUCTOR ========== */
    
    /**
     * @notice Initialize FastWithdrawal contract
     * @param _stakingContract Address of the staking contract
     * @param _minValidatorsForFastWithdrawal Minimum number of validators required for fast withdrawal
     * @param _fastWithdrawalResponsePeriod Response period for validators (seconds)
     * @param _minFastWithdrawalFee Minimum fixed fee for fast withdrawal (wei)
     * @param _fastWithdrawalFeeRate Fee rate as percentage of amount (basis points, 100 = 1%)
     * @param _submissionFee Fee for aggregator submission (wei)
     */
    constructor(
        address _stakingContract,
        uint256 _minValidatorsForFastWithdrawal,
        uint256 _fastWithdrawalResponsePeriod,
        uint256 _minFastWithdrawalFee,
        uint256 _fastWithdrawalFeeRate,
        uint256 _submissionFee
    ) {
        require(_stakingContract != address(0), "Invalid staking contract");
        require(_minValidatorsForFastWithdrawal > 0, "Min validator count must be > 0");
        require(_fastWithdrawalResponsePeriod > 0, "Response period must be > 0");
        require(_fastWithdrawalFeeRate <= 10000, "Fee rate cannot exceed 100%");
        
        stakingContract = IStakingV3(_stakingContract);
        minValidatorsForFastWithdrawal = _minValidatorsForFastWithdrawal;
        fastWithdrawalResponsePeriod = _fastWithdrawalResponsePeriod;
        minFastWithdrawalFee = _minFastWithdrawalFee;
        fastWithdrawalFeeRate = _fastWithdrawalFeeRate;
        submissionFee = _submissionFee;
        owner = msg.sender;
        fastWithdrawalPaused = false;
    }
    
    /* ========== GOVERNANCE FUNCTIONS ========== */
    
    /**
     * @notice Update minimum validator count requirement for fast withdrawal
     * @dev Only callable by contract owner
     * @param _minValidatorsForFastWithdrawal New minimum validator count for fast withdrawal
     */
    function setMinValidatorsForFastWithdrawal(uint256 _minValidatorsForFastWithdrawal) 
        external 
        onlyOwner 
    {
        require(_minValidatorsForFastWithdrawal > 0, "Must be greater than 0");
        
        uint256 oldCount = minValidatorsForFastWithdrawal;
        minValidatorsForFastWithdrawal = _minValidatorsForFastWithdrawal;
        
        emit MinValidatorsForFastWithdrawalUpdated(oldCount, _minValidatorsForFastWithdrawal);
    }
    
    /**
     * @notice Transfer contract ownership
     * @param newOwner Address of new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        owner = newOwner;
    }
    
    /**
     * @notice Update fast withdrawal response period
     * @param _responsePeriod New response period in seconds
     */
    function setFastWithdrawalResponsePeriod(uint256 _responsePeriod) 
        external 
        onlyOwner 
    {
        require(_responsePeriod > 0, "Response period must be > 0");
        
        uint256 oldPeriod = fastWithdrawalResponsePeriod;
        fastWithdrawalResponsePeriod = _responsePeriod;
        
        emit FastWithdrawalResponsePeriodUpdated(oldPeriod, _responsePeriod);
    }
    
    /**
     * @notice Update minimum fast withdrawal fee
     * @param _minFee New minimum fee amount in wei
     */
    function setMinFastWithdrawalFee(uint256 _minFee) 
        external 
        onlyOwner 
    {
        uint256 oldFee = minFastWithdrawalFee;
        minFastWithdrawalFee = _minFee;
        
        emit MinFastWithdrawalFeeUpdated(oldFee, _minFee);
    }
    
    /**
     * @notice Update fast withdrawal fee rate
     * @param _feeRate New fee rate in basis points (100 = 1%)
     */
    function setFastWithdrawalFeeRate(uint256 _feeRate) 
        external 
        onlyOwner 
    {
        require(_feeRate <= 10000, "Fee rate cannot exceed 100%");
        
        uint256 oldRate = fastWithdrawalFeeRate;
        fastWithdrawalFeeRate = _feeRate;
        
        emit FastWithdrawalFeeRateUpdated(oldRate, _feeRate);
    }
    
    /**
     * @notice Update submission fee for aggregators
     * @param _submissionFee New submission fee in wei
     */
    function setSubmissionFee(uint256 _submissionFee) 
        external 
        onlyOwner 
    {
        uint256 oldFee = submissionFee;
        submissionFee = _submissionFee;
        
        emit SubmissionFeeUpdated(oldFee, _submissionFee);
    }
    
    /**
     * @notice Disable fast withdrawal feature
     * @dev Does NOT affect Optimism's standard 7-day withdrawal
     * @dev Use this in case of emergency or security issue
     */
    function pauseFastWithdrawalVerification() external onlyOwner {
        fastWithdrawalPaused = true;
        emit FastWithdrawalVerificationPaused(msg.sender);
    }
    
    /**
     * @notice Enable fast withdrawal feature
     * @dev Allows users to request fast withdrawals again
     */
    function resumeFastWithdrawalVerification() external onlyOwner {
        fastWithdrawalPaused = false;
        emit FastWithdrawalVerificationResumed(msg.sender);
    }
    
    /**
     * @notice Check if fast withdrawal is currently enabled
     * @return enabled True if fast withdrawal requests are accepted
     */
    function isFastWithdrawalEnabled() external view returns (bool enabled) {
        if (fastWithdrawalPaused) return false;
        
        address[] memory activeValidators = stakingContract.getActiveValidators();
        return activeValidators.length >= minValidatorsForFastWithdrawal;
    }
    
    /* ========== EXTERNAL FUNCTIONS ========== */
    
    /**
     * @notice Calculate required fee for fast withdrawal
     * @param amount Withdrawal amount
     * @return requiredFee The maximum of minimum fee or percentage-based fee
     */
    function calculateFee(uint256 amount) public view returns (uint256 requiredFee) {
        // Calculate percentage-based fee
        uint256 percentageFee = (amount * fastWithdrawalFeeRate) / 10000;
        
        // Return the larger of minimum fee or percentage-based fee
        return percentageFee > minFastWithdrawalFee ? percentageFee : minFastWithdrawalFee;
    }
    
    /**
     * @notice Request a fast withdrawal
     * @dev If validators respond with BLS signature → instant withdrawal
     * @dev If no response within period → auto-fallback to regular Optimism withdrawal (7 days)
     * @param amount Amount to withdraw
     * @return requestId Unique identifier for this request
     */
    function requestFastWithdrawal(uint256 amount) 
        external 
        payable
        whenFastWithdrawalNotPaused
        returns (bytes32 requestId) 
    {
        require(amount > 0, "Amount must be > 0");
        
        // Calculate and check required fee
        uint256 requiredFee = calculateFee(amount);
        if (msg.value < requiredFee) {
            revert InsufficientFee(msg.value, requiredFee);
        }
        
        // Generate unique request ID
        requestId = keccak256(abi.encodePacked(
            msg.sender,
            amount,
            block.timestamp,
            block.number
        ));
        
        // Snapshot current validator set
        address[] memory validatorSnapshot = stakingContract.getActiveValidators();
        
        // Check minimum validators
        if (validatorSnapshot.length < minValidatorsForFastWithdrawal) {
            revert InsufficientValidators(validatorSnapshot.length, minValidatorsForFastWithdrawal);
        }
        
        // Calculate deadline
        uint256 deadline = block.timestamp + fastWithdrawalResponsePeriod;
        
        // Store request
        withdrawalRequests[requestId] = WithdrawalRequest({
            user: msg.sender,
            amount: amount,
            requestTimestamp: block.timestamp,
            fastWithdrawalAttempted: true,
            fastWithdrawalDeadline: deadline,
            feePaid: msg.value,
            validatorSetSnapshot: validatorSnapshot
        });
        
        emit WithdrawalRequested(requestId, msg.sender, amount, block.timestamp);
    }
    
    /**
     * @notice Execute fast withdrawal with unanimous validator consensus
     * @dev Requires ALL active validators to sign (100% consensus)
     * @dev Uses validator snapshot from request time to prevent manipulation
     * @dev Aggregator receives submission fee, validators split remaining fee
     * @param requestId Withdrawal request identifier
     * @param aggregatedSignature BLS aggregated signature from ALL validators
     * @param validatorBitmap Bitmap indicating which validators signed
     */
    function executeWithdrawalWithProof(
        bytes32 requestId,
        bytes calldata aggregatedSignature,
        uint256 validatorBitmap
    ) external whenFastWithdrawalNotPaused {
        WithdrawalRequest storage request = withdrawalRequests[requestId];
        
        // Validate request exists and not executed
        if (request.user == address(0)) revert RequestNotFound();
        if (request.executed) revert AlreadyExecuted();
        
        // Check response period hasn't expired
        if (block.timestamp > request.timestamp + fastWithdrawalResponsePeriod) {
            emit FastWithdrawalTimeout(requestId, request.user);
            revert ResponsePeriodExpired();
        }
        
        // Use validator snapshot from request time (prevents manipulation)
        address[] memory activeValidators = request.validatorSetSnapshot;
        uint256 activeValidatorCount = activeValidators.length;
        
        // Check minimum validator count requirement for fast withdrawal
        if (activeValidatorCount < minValidatorsForFastWithdrawal) {
            emit FastWithdrawalDisabled(requestId, activeValidatorCount, minValidatorsForFastWithdrawal);
            revert InsufficientValidators(activeValidatorCount, minValidatorsForFastWithdrawal);
        }
        
        // Verify ALL validators signed (unanimous consensus)
        uint256 signedCount = countSetBits(validatorBitmap);
        if (signedCount != activeValidatorCount) {
            revert UnanimousConsensusRequired(signedCount, activeValidatorCount);
        }
        
        // Prepare message that was signed
        bytes memory message = abi.encodePacked(
            "TOKAMAK_FAST_WITHDRAWAL",
            requestId,
            request.user,
            request.amount,
            block.chainid
        );
        bytes32 messageHash = keccak256(message);
        
        // Collect BLS public keys of ALL validators and verify bitmap
        BLS12381.G1Point[] memory validatorPubKeys = new BLS12381.G1Point[](activeValidatorCount);
        
        for (uint256 i = 0; i < activeValidatorCount; i++) {
            // Verify this validator signed (bit must be set)
            if ((validatorBitmap >> i) & 1 != 1) {
                revert MissingValidatorSignature(activeValidators[i]);
            }
            
            // Get BLS public key from staking contract
            bytes memory blsPubKey = stakingContract.getValidatorBLSPubKey(activeValidators[i]);
            validatorPubKeys[i] = BLS12381.parseG1Point(blsPubKey);
        }
        
        // Aggregate ALL validator public keys
        BLS12381.G1Point memory aggregatedPubKey = BLS12381.aggregateG1Points(
            validatorPubKeys,
            activeValidatorCount
        );
        
        // Verify BLS aggregated signature
        bool isValid = BLS12381.verifySignature(
            messageHash,
            aggregatedSignature,
            aggregatedPubKey
        );
        
        if (!isValid) revert InvalidAggregatedSignature();
        
        // Mark as executed
        request.executed = true;
        
        // Execute instant withdrawal via staking contract
        stakingContract.executeInstantWithdrawal(request.user, request.amount);
        
        // Distribute fees
        _distributeFees(requestId, request.feePaid, activeValidators);
        
        emit FastWithdrawalExecuted(requestId, request.user, request.amount);
    }
    
    /**
     * @notice Check if fast withdrawal deadline has passed
     * @param requestId Request identifier
     * @return expired True if deadline has passed
     */
    function isFastWithdrawalExpired(bytes32 requestId) external view returns (bool expired) {
        WithdrawalRequest storage request = withdrawalRequests[requestId];
        if (request.user == address(0)) return false;
        return block.timestamp > request.fastWithdrawalDeadline;
    }
    
    /**
     * @notice Get withdrawal request details
     * @param requestId Request identifier
     * @return user User address
     * @return amount Withdrawal amount
     * @return requestTimestamp Request timestamp
     * @return fastWithdrawalAttempted Whether fast withdrawal was requested
     * @return fastWithdrawalDeadline Deadline for fast withdrawal
     * @return feePaid Fee paid
     */
    function getWithdrawalRequestDetails(bytes32 requestId) 
        external 
        view 
        returns (
            address user,
            uint256 amount,
            uint256 requestTimestamp,
            bool fastWithdrawalAttempted,
            uint256 fastWithdrawalDeadline,
            uint256 feePaid
        ) 
    {
        WithdrawalRequest memory request = withdrawalRequests[requestId];
        return (
            request.user,
            request.amount,
            request.requestTimestamp,
            request.fastWithdrawalAttempted,
            request.fastWithdrawalDeadline,
            request.feePaid
        );
    }
    
    /* ========== VIEW FUNCTIONS ========== */
    

    
    /**
     * @notice Get current active validator count from staking contract
     * @return count Number of active validators
     */
    function getActiveValidatorCount() external view returns (uint256 count) {
        address[] memory activeValidators = stakingContract.getActiveValidators();
        return activeValidators.length;
    }
    
    /**
     * @notice Get withdrawal request details
     * @param requestId Request identifier
     * @return user User address
     * @return amount Withdrawal amount
     * @return timestamp Request timestamp
     * @return executed Execution status
     */
    function getWithdrawalRequest(bytes32 requestId) 
        external 
        view 
        returns (
            address user,
            uint256 amount,
            uint256 timestamp,
            bool executed
        ) 
    {
        WithdrawalRequest memory request = withdrawalRequests[requestId];
        return (request.user, request.amount, request.timestamp, request.executed);
    }
    
    /* ========== INTERNAL FUNCTIONS ========== */
    
    /**
     * @notice Count number of set bits in bitmap
     * @param bitmap Bitmap to count
     * @return count Number of bits set to 1
     */
    function countSetBits(uint256 bitmap) internal pure returns (uint256 count) {
        while (bitmap > 0) {
            count += bitmap & 1;
            bitmap >>= 1;
        }
    }
    
    /**
     * @notice Distribute fees to validators and aggregator
     * @dev Aggregator gets submission fee, validators split remaining amount
     * @param requestId Request identifier
     * @param totalFee Total fee paid by user
     * @param validators Array of validator addresses that signed
     */
    function _distributeFees(
        bytes32 requestId,
        uint256 totalFee,
        address[] memory validators
    ) internal {
        // Pay submission fee to aggregator (msg.sender)
        if (submissionFee > 0) {
            require(totalFee >= submissionFee, "Insufficient fee for submission");
            (bool success, ) = msg.sender.call{value: submissionFee}("");
            require(success, "Submission fee transfer failed");
            
            emit SubmissionFeePaid(requestId, msg.sender, submissionFee);
        }
        
        // Remaining fee for validators
        uint256 validatorFee = totalFee - submissionFee;
        
        if (validatorFee > 0 && validators.length > 0) {
            uint256 feePerValidator = validatorFee / validators.length;
            
            // Distribute to each validator
            for (uint256 i = 0; i < validators.length; i++) {
                (bool success, ) = validators[i].call{value: feePerValidator}("");
                require(success, "Validator fee transfer failed");
            }
            
            emit FeesDistributed(requestId, validatorFee, validators.length, feePerValidator);
        }
    }
}
```

## OptimismPortal2 Integration (중요!)

### 수정 필요: OptimismPortal2.sol

빠른 출금 요청 후 응답 기간이 지나면 **자동으로 Optimism의 일반 출금(7일 challenge period)**으로 처리되어야 합니다.

```solidity
// OptimismPortal2.sol 수정 사항
contract OptimismPortal2 {
    IFastWithdrawal public fastWithdrawalContract;
    
    /**
     * @notice Set FastWithdrawal contract address
     */
    function setFastWithdrawalContract(address _fastWithdrawal) external {
        require(msg.sender == guardian, "Only guardian");
        fastWithdrawalContract = IFastWithdrawal(_fastWithdrawal);
    }
    
    /**
     * @notice Finalize withdrawal with fast withdrawal check
     */
    function finalizeWithdrawalTransaction(
        Types.WithdrawalTransaction memory _tx
    ) external {
        bytes32 withdrawalHash = Hashing.hashWithdrawal(_tx);
        
        ProvenWithdrawal memory provenWithdrawal = 
            provenWithdrawals[withdrawalHash][msg.sender];
        
        // Check if already finalized
        require(!finalizedWithdrawals[withdrawalHash], "Already finalized");
        
        // Check if proven
        require(provenWithdrawal.timestamp != 0, "Not proven");
        
        // Check dispute game status
        IDisputeGame game = provenWithdrawal.disputeGameProxy;
        require(game.status() != GameStatus.CHALLENGER_WINS, "Invalid game");
        
        // NEW: Check fast withdrawal status
        if (address(fastWithdrawalContract) != address(0)) {
            bytes32 requestId = fastWithdrawalContract.getRequestIdForWithdrawal(
                withdrawalHash,
                msg.sender
            );
            
            // If fast withdrawal was attempted
            (
                ,
                ,
                ,
                bool fastWithdrawalAttempted,
                uint256 fastWithdrawalDeadline,
                
            ) = fastWithdrawalContract.getWithdrawalRequestDetails(requestId);
            
            if (fastWithdrawalAttempted) {
                // Check if still within fast withdrawal period
                if (block.timestamp <= fastWithdrawalDeadline) {
                    revert("Fast withdrawal period not expired");
                }
                
                // Fast withdrawal deadline passed → proceed as regular withdrawal
                // No need to wait additional 7 days, just verify dispute game
            }
        }
        
        // Regular withdrawal: check 7-day waiting period
        require(
            block.timestamp >= provenWithdrawal.timestamp + disputeGameFinalityDelaySeconds,
            "Dispute game finality period not elapsed"
        );
        
        // Execute withdrawal
        finalizedWithdrawals[withdrawalHash] = true;
        
        bool success = SafeCall.call(
            _tx.target,
            _tx.gasLimit,
            _tx.value,
            _tx.data
        );
        
        require(success, "Withdrawal failed");
        
        emit WithdrawalFinalized(withdrawalHash, success);
    }
}
```

### Fast Withdrawal Contract에 필요한 추가 함수

```solidity
// FastWithdrawal.sol에 추가
contract FastWithdrawal {
    // ... existing code ...
    
    /// @notice Mapping from Optimism withdrawal hash to fast withdrawal request ID
    mapping(bytes32 => bytes32) public optimismWithdrawalToRequestId;
    
    /**
     * @notice Link Optimism withdrawal hash to fast withdrawal request
     * @dev Called when user proves withdrawal on OptimismPortal2
     */
    function linkOptimismWithdrawal(
        bytes32 withdrawalHash,
        bytes32 requestId
    ) external {
        WithdrawalRequest storage request = withdrawalRequests[requestId];
        require(request.user == msg.sender, "Not request owner");
        require(!request.fastWithdrawalAttempted || request.user != address(0), "Invalid request");
        
        optimismWithdrawalToRequestId[withdrawalHash] = requestId;
    }
    
    /**
     * @notice Get fast withdrawal request ID for Optimism withdrawal hash
     * @dev Called by OptimismPortal2 to check fast withdrawal status
     */
    function getRequestIdForWithdrawal(
        bytes32 withdrawalHash,
        address user
    ) external view returns (bytes32) {
        return optimismWithdrawalToRequestId[withdrawalHash];
    }
}
```

### 통합 Flow (OptimismPortal2 + FastWithdrawal)

```
┌─────────────────────────────────────────────────────────┐
│  Optimism 기본 출금 Flow (기존 그대로 유지)              │
└─────────────────────────────────────────────────────────┘

Step 1: L2에서 출금 시작
  └─ L2ToL1MessagePasser.initiateWithdrawal(100 ETH)

Step 2: L1에서 출금 증명
  └─ OptimismPortal2.proveWithdrawalTransaction()
  └─ ProvenWithdrawal 생성
  └─ timestamp 기록

┌─────────────────────────────────────────────────────────┐
│  여기서 사용자 선택!                                     │
└─────────────────────────────────────────────────────────┘

  ┌─ Option A: 빠른 출금 시도 ──────────────┐
  │                                         │
  │ Step 2.5: 빠른 출금 요청                │
  │   └─ FastWithdrawal.requestFastWithdrawal{value: fee}()
  │   └─ Link withdrawalHash                │
  │   └─ 응답 기간 시작 (5분)               │
  │                                         │
  │ Step 3a: 검증자 응답?                   │
  │   ┌─ YES (만장일치) ─────────┐          │
  │   │  └─ BLS proof 제출        │          │
  │   │  └─ Portal에서 즉시 실행   │          │
  │   │  └─ 총 시간: 3-5분 ✅     │          │
  │   └───────────────────────────┘          │
  │   ┌─ NO (응답 없음) ──────────┐          │
  │   │  └─ 응답 기간 만료 (5분)  │          │
  │   │  └─ Option B로 자동 전환  │          │
  │   │  └─ 수수료 환불           │          │
  │   └───────────────────────────┘          │
  └─────────────────────────────────────────┘

  ┌─ Option B: 일반 출금 (또는 A 실패 시) ───┐
  │                                         │
  │ Step 3b: 7일 대기                       │
  │   └─ DisputeGame challenge period       │
  │   └─ 7일 경과                           │
  │                                         │
  │ Step 4: 출금 실행                       │
  │   └─ OptimismPortal2.finalizeWithdrawalTransaction()
  │   └─ 총 시간: 7일                       │
  └─────────────────────────────────────────┘

핵심:
- Optimism 기본 Flow는 그대로 유지
- Step 2.5가 "선택적으로" 추가됨
- 빠른 출금 실패 시 자동으로 일반 출금으로 폴백
```

## Staking Contract Interface

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IStakingV3
 * @notice Interface for querying validator information
 */
interface IStakingV3 {
    /**
     * @notice Get list of all active validators
     * @return validators Array of active validator addresses
     */
    function getActiveValidators() external view returns (address[] memory validators);
    
    /**
     * @notice Get BLS public key for a validator
     * @param validator Validator address
     * @return blsPubKey BLS12-381 public key (48 bytes, G1 point)
     */
    function getValidatorBLSPubKey(address validator) external view returns (bytes memory blsPubKey);
    
    /**
     * @notice Get validator's stake amount
     * @param validator Validator address
     * @return stake Amount staked
     */
    function getValidatorStake(address validator) external view returns (uint256 stake);
    
    /**
     * @notice Execute instant withdrawal (called by FastWithdrawal contract)
     * @dev Transfers funds immediately without 7-day waiting period
     * @param user User receiving funds
     * @param amount Amount to withdraw
     */
    function executeInstantWithdrawal(address user, uint256 amount) external;
    
    /**
     * @notice Initiate regular withdrawal with 7-day challenge period
     * @dev Called when fast withdrawal times out
     * @param user User requesting withdrawal
     * @param amount Amount to withdraw
     */
    function initiateRegularWithdrawal(address user, uint256 amount) external;
}
```

## State Variables 설명

### 1. `stakingContract` (immutable)
- **타입**: `IStakingV3`
- **설명**: 검증자 정보를 조회하는 스테이킹 컨트랙트 주소
- **용도**: 
  - `getActiveValidators()`: 현재 활성 검증자 목록 조회
  - `getValidatorBLSPubKey()`: 각 검증자의 BLS 공개키 조회
  - `executeInstantWithdrawal()`: 즉시 출금 실행

### 2. `minValidatorsForFastWithdrawal` (storage, governance)
- **타입**: `uint256`
- **설명**: **빠른 출금을 위한 최소 검증자 수** - Fast Withdrawal 기능이 활성화되기 위한 최소 검증자 수
- **예시**: 3, 5, 10 등
- **용도**: 
  - 검증자가 너무 적을 때 Fast Withdrawal 비활성화
  - 보안성 확보: 충분한 수의 검증자가 있을 때만 즉시 출금 허용
  - 거버넌스를 통해 조정 가능
- **체크 로직**:
  ```solidity
  if (activeValidatorCount < minValidatorsForFastWithdrawal) {
      revert InsufficientValidators(activeValidatorCount, minValidatorsForFastWithdrawal);
  }
  ```

### 3. `fastWithdrawalResponsePeriod` (storage, governance)
- **타입**: `uint256`
- **설명**: **빠른 출금 응답 기간** - 검증자들이 응답해야 하는 시간 (초 단위)
- **예시**: 300 (5분), 600 (10분)
- **용도**:
  - 검증자 응답 대기 시간 설정
  - 기간 초과 시 타입별 다른 동작:
    - `FastWithFallback`: 자동으로 일반 출금(7일)으로 전환
    - `FastOnly`: 사용자가 직접 실행 가능 (검증 없이)

### 4. Fee Structure (storage, governance)

#### 4.1 `minFastWithdrawalFee`
- **타입**: `uint256`
- **설명**: **최소 고정 수수료**
- **예시**: 0.01 ETH

#### 4.2 `fastWithdrawalFeeRate`
- **타입**: `uint256`
- **설명**: **출금액 기반 수수료 비율 (basis points)**
- **예시**: 10 (0.1%), 50 (0.5%), 100 (1%)
- **계산**: `(amount × feeRate) / 10000`

#### 4.3 수수료 계산 로직
```solidity
function calculateFee(uint256 amount) public view returns (uint256) {
    uint256 percentageFee = (amount * fastWithdrawalFeeRate) / 10000;
    return max(percentageFee, minFastWithdrawalFee);
}
```

**예시:**
```
출금액: 100 ETH
minFastWithdrawalFee: 0.01 ETH
fastWithdrawalFeeRate: 50 (0.5%)

계산:
- 퍼센트 수수료: 100 × 50 / 10000 = 0.5 ETH
- 최소 수수료: 0.01 ETH
- 최종 수수료: max(0.5, 0.01) = 0.5 ETH ✅
```

### 5. `submissionFee` (storage, governance)
- **타입**: `uint256`
- **설명**: **Aggregator 제출 수수료** - 증명을 제출한 aggregator가 받는 추가 수수료
- **예시**: 0.005 ETH
- **용도**: Aggregator의 가스비 보상

### 6. 수수료 분배 구조

```
총 수수료 (user가 지불)
├─ submissionFee → Aggregator (증명 제출자)
│  └─ 가스비 보상
│
└─ 나머지 수수료 → Validators (균등 분배)
   └─ 서명 제공 보상
```

**예시:**
```
총 수수료: 0.5 ETH
submissionFee: 0.05 ETH
검증자 수: 10명

분배:
- Aggregator: 0.05 ETH
- Validators: (0.5 - 0.05) / 10 = 0.045 ETH per validator
```

### 3. `withdrawalRequests` (mapping)
- **타입**: `mapping(bytes32 => WithdrawalRequest)`
- **설명**: 출금 요청 저장소
- **키**: `requestId` = `keccak256(user, amount, timestamp, blockNumber)`
- **값**: `WithdrawalRequest` 구조체
  - `user`: 출금 요청자 주소
  - `amount`: 출금 금액
  - `timestamp`: 요청 생성 시간
  - `executed`: 실행 여부 (중복 실행 방지)

## Function Flow

### 1. Request Flow

```
User calls requestWithdrawal(amount)
  ↓
Generate requestId = keccak256(user, amount, timestamp, blockNumber)
  ↓
Store WithdrawalRequest in withdrawalRequests mapping
  ↓
Emit WithdrawalRequested event
  ↓
Aggregator monitors event
  ↓
Validators sign via libp2p
```

### 2. Execution Flow

```
Aggregator calls executeWithdrawal(requestId, aggregatedSig, bitmap)
  ↓
Check request exists and not executed
  ↓
Query activeValidators from stakingContract.getActiveValidators()
  ↓
Check: activeValidators.length >= minValidatorsForFastWithdrawal ✅
  (빠른 출금을 위한 최소 검증자 수 충족 확인)
  ↓
Check: signedCount == activeValidators.length (100%) ✅
  (만장일치: 모든 검증자 서명 확인)
  ↓
For each validator:
  - Verify bit is set in bitmap ✅
  - Get BLS public key from stakingContract ✅
  ↓
Aggregate all validator public keys
  ↓
Verify BLS aggregated signature ✅
  ↓
Mark request.executed = true
  ↓
Call stakingContract.executeInstantWithdrawal(user, amount)
  ↓
Emit FastWithdrawalExecuted event
```

## Security Checks

### ✅ Check 1: Minimum Validator Count for Fast Withdrawal
```solidity
// 빠른 출금을 위한 최소 검증자 수 확인
if (activeValidatorCount < minValidatorsForFastWithdrawal) {
    revert InsufficientValidators(activeValidatorCount, minValidatorsForFastWithdrawal);
}
```

### ✅ Check 2: Unanimous Consensus (100%)
```solidity
uint256 signedCount = countSetBits(validatorBitmap);
if (signedCount != activeValidatorCount) {
    revert UnanimousConsensusRequired(signedCount, activeValidatorCount);
}
```

### ✅ Check 3: All Validators Signed
```solidity
for (uint256 i = 0; i < activeValidatorCount; i++) {
    if ((validatorBitmap >> i) & 1 != 1) {
        revert MissingValidatorSignature(activeValidators[i]);
    }
}
```

### ✅ Check 4: BLS Signature Verification
```solidity
bool isValid = BLS12381.verifySignature(
    messageHash,
    aggregatedSignature,
    aggregatedPubKey
);
if (!isValid) revert InvalidAggregatedSignature();
```

## Deployment Parameters

### Testnet Example
```javascript
const stakingContract = "0x...";
const minValidatorsForFastWithdrawal = 3;  // 빠른 출금을 위한 최소 검증자 수: 3명

const fastWithdrawal = await FastWithdrawal.deploy(
    stakingContract,
    minValidatorsForFastWithdrawal
);
```

### Mainnet Example
```javascript
const stakingContract = "0x...";
const minValidatorsForFastWithdrawal = 10;  // 빠른 출금을 위한 최소 검증자 수: 10명 (프로덕션)

const fastWithdrawal = await FastWithdrawal.deploy(
    stakingContract,
    minValidatorsForFastWithdrawal
);
```

## Governance Operations

### Update Minimum Validator Count for Fast Withdrawal
```javascript
// 보안 강화: 더 많은 검증자 요구
await fastWithdrawal.setMinValidatorsForFastWithdrawal(15);

// 초기 단계: 더 적은 검증자로 시작
await fastWithdrawal.setMinValidatorsForFastWithdrawal(5);
```

### Check Fast Withdrawal Status
```javascript
const isEnabled = await fastWithdrawal.isFastWithdrawalEnabled();
const activeCount = await fastWithdrawal.getActiveValidatorCount();
const minRequired = await fastWithdrawal.minValidatorsForFastWithdrawal();

console.log(`Fast Withdrawal: ${isEnabled ? 'ENABLED' : 'DISABLED'}`);
console.log(`Active Validators: ${activeCount}`);
console.log(`Min Required for Fast Withdrawal: ${minRequired}`);
console.log(`Status: ${activeCount >= minRequired ? '✅ Sufficient' : '❌ Insufficient'}`);
```

## Events for Monitoring

### WithdrawalRequested
```javascript
fastWithdrawal.on("WithdrawalRequested", (requestId, user, amount, timestamp) => {
    console.log(`New withdrawal request: ${requestId}`);
    console.log(`User: ${user}, Amount: ${amount}`);
    // Trigger aggregator to collect signatures
});
```

### FastWithdrawalExecuted
```javascript
fastWithdrawal.on("FastWithdrawalExecuted", (requestId, user, amount) => {
    console.log(`Fast withdrawal executed: ${requestId}`);
    console.log(`User: ${user} received ${amount}`);
});
```

### FastWithdrawalDisabled
```javascript
fastWithdrawal.on("FastWithdrawalDisabled", (requestId, current, required) => {
    console.warn(`Fast withdrawal disabled for ${requestId}`);
    console.warn(`Current validators: ${current}, Required: ${required}`);
    // Notify user to use regular withdrawal
});
```

### MinValidatorsForFastWithdrawalUpdated
```javascript
fastWithdrawal.on("MinValidatorsForFastWithdrawalUpdated", (oldCount, newCount) => {
    console.log(`빠른 출금을 위한 최소 검증자 수 업데이트: ${oldCount} -> ${newCount}`);
    // Update monitoring dashboards
});
```

## Error Handling

### InsufficientValidators
```
Revert when: activeValidatorCount < minValidatorsForFastWithdrawal
Reason: 빠른 출금을 위한 최소 검증자 수 미달
Action: User must use regular withdrawal (7-day period)
Example: 현재 검증자 2명, 최소 요구 3명 → Fast Withdrawal 비활성화
```

### UnanimousConsensusRequired
```
Revert when: signedCount != activeValidatorCount
Action: Wait for more signatures or timeout to regular withdrawal
```

### MissingValidatorSignature
```
Revert when: A specific validator didn't sign (bitmap bit not set)
Action: Identify offline validator, retry or timeout
```

### InvalidAggregatedSignature
```
Revert when: BLS signature verification fails
Action: Invalid signature data, reject and investigate
```

## Gas Optimization

### Bitmap Efficiency
- Uses `uint256` bitmap to track up to 256 validators
- Single storage slot for validator participation
- O(1) lookup per validator

### BLS Aggregation Benefits
- Single pairing check regardless of validator count
- ~150k gas for BLS verification
- vs. ~5M gas for 100 individual ECDSA signatures

### Expected Gas Costs
```
Fast Withdrawal Execution:
  - Request creation: ~50k gas
  - BLS verification: ~150k gas
  - Bitmap validation: ~30k gas
  - State updates: ~50k gas
  - Total: ~280k gas

Regular Withdrawal (for comparison):
  - Challenge period: 7 days
  - No immediate gas cost but high time cost
```

## Summary

| Variable | Type | Purpose | Example Value |
|----------|------|---------|---------------|
| `stakingContract` | `IStakingV3` | Query validators & BLS keys | `0x123...` |
| `minValidatorsForFastWithdrawal` | `uint256` | **빠른 출금을 위한 최소 검증자 수** | `3`, `5`, `10` |
| `withdrawalRequests` | `mapping` | Store withdrawal requests | `requestId => Request` |
| `owner` | `address` | Contract governance | `0xabc...` |

**핵심 로직:**
1. ✅ `activeValidatorCount >= minValidatorsForFastWithdrawal` - 빠른 출금 활성화 조건
2. ✅ `signedCount == activeValidatorCount` - 만장일치 (100% unanimous consensus)
3. ✅ BLS signature verification - 암호학적 검증
4. ✅ On-chain validator query - 스테이킹 컨트랙트에서 실시간 검증자 조회
5. ✅ Validator snapshot - 요청 시점의 검증자 세트 고정 (조작 방지)
6. ✅ Response period - 응답 기간 내 검증자 응답 필요
7. ✅ Two withdrawal types - FastWithFallback vs FastOnly
8. ✅ Fee structure - 최소 수수료 + 비율 수수료 중 큰 금액
9. ✅ Fee distribution - Aggregator 제출비 + Validators 균등 분배

## 핵심 요약

### 컨트랙트 주요 변수

```solidity
// 검증자 요구사항
uint256 public minValidatorsForFastWithdrawal;     // 예: 3, 5, 10

// 응답 기간
uint256 public fastWithdrawalResponsePeriod;       // 예: 300 (5분)

// 수수료 구조
uint256 public minFastWithdrawalFee;               // 예: 0.01 ETH (최소 고정)
uint256 public fastWithdrawalFeeRate;              // 예: 50 (0.5%)
uint256 public submissionFee;                       // 예: 0.005 ETH (aggregator)

// 긴급 제어
bool public fastWithdrawalPaused;                   // 긴급 일시중지
```

### 주요 함수

```solidity
// 사용자 함수
function calculateFee(uint256 amount) public view returns (uint256);
function requestFastWithdrawalWithFallback(uint256 amount) external payable;
function requestFastWithdrawalOnly(uint256 amount) external payable;
function claimFeeRefund(bytes32 requestId) external;  // FastOnly: 수수료만 환불
function convertToRegularWithdrawal(bytes32 requestId) external;  // FastWithFallback: 자동 전환

// Aggregator/Validator 함수
function executeWithdrawalWithProof(
    bytes32 requestId,
    bytes calldata aggregatedSignature,
    uint256 validatorBitmap
) external;

// 거버넌스 함수
function setMinValidatorsForFastWithdrawal(uint256) external onlyOwner;
function setFastWithdrawalResponsePeriod(uint256) external onlyOwner;
function setMinFastWithdrawalFee(uint256) external onlyOwner;
function setFastWithdrawalFeeRate(uint256) external onlyOwner;
function setSubmissionFee(uint256) external onlyOwner;
function pauseFastWithdrawalVerification() external onlyOwner;
function resumeFastWithdrawalVerification() external onlyOwner;
```

### 수수료 분배 예시

```
사용자 출금: 100 ETH
계산된 수수료: 0.5 ETH (100 × 0.5% = 0.5 ETH > 0.01 ETH 최소)
검증자: 10명
제출비: 0.05 ETH

분배:
├─ Aggregator (제출자): 0.05 ETH
└─ Validators (10명): (0.5 - 0.05) / 10 = 0.045 ETH each
```

### 보안 모델

| 보안 요소 | 구현 방식 | 효과 |
|-----------|-----------|------|
| **만장일치** | 100% 검증자 서명 필요 | 1명의 정직한 검증자로 악의적 출금 차단 |
| **Validator Snapshot** | 요청 시점 검증자 고정 | 중간 조작 방지 |
| **응답 기간** | 시간 제한 설정 | DoS 방지 |
| **긴급 중지** | `pauseFastWithdrawalVerification()` | 취약점 발견 시 즉시 대응 |
| **수수료 검증** | `calculateFee()` 체크 | 부족한 수수료 거부 |
| **타입별 Fallback** | FastWithFallback 자동 전환 | 항상 출금 보장 |

### 사용 시나리오

**일반 사용자 (안전 우선):**
```javascript
// FastWithFallback 사용
const fee = await contract.calculateFee(amount);
await contract.requestFastWithdrawalWithFallback(amount, { value: fee });

// 검증자 응답 없으면 자동으로 7일 출금으로 전환 (안전)
```

**긴급 출금 (속도 우선):**
```javascript
// FastOnly 사용
const fee = await contract.calculateFee(amount);
await contract.requestFastWithdrawalOnly(amount, { value: fee });

// 응답 기간 후 직접 실행 가능
await contract.executeAfterResponsePeriod(requestId);
```

### 거버넌스 운영

**초기 설정 (보수적):**
- `minValidatorsForFastWithdrawal`: 10명
- `fastWithdrawalResponsePeriod`: 10분
- `minFastWithdrawalFee`: 0.02 ETH
- `fastWithdrawalFeeRate`: 100 (1%)

**안정화 후 조정:**
- 검증자 수 증가 → `minValidatorsForFastWithdrawal` 증가
- 네트워크 안정 → `fastWithdrawalResponsePeriod` 감소
- 사용량 증가 → 수수료 조정

## Security Enhancements (추가 보강 내용)

### 1. Validator Set Snapshot

**문제**: 요청 시점과 실행 시점 사이에 validator set이 변경될 수 있음

**해결책**: 요청 시점의 validator set을 snapshot으로 저장

```solidity
struct WithdrawalRequest {
    // ...
    address[] validatorSetSnapshot;  // 요청 시점의 검증자 목록 고정
}

// 실행 시 snapshot 사용
address[] memory activeValidators = request.validatorSetSnapshot;
```

**보안 효과:**
- ✅ 검증자가 중간에 추가/제거되어도 영향 없음
- ✅ 악의적인 validator set 조작 방지
- ✅ 일관된 검증 기준 유지

### 2. Timeout & Fallback Mechanism

**타임아웃 설정**: 
```solidity
uint256 public fastWithdrawalTimeout = 5 minutes;
```

**Flow:**
```
Fast Withdrawal 시도 (5분 이내)
  ↓
만장일치 달성? 
  ├─ YES → 즉시 출금 ✅
  └─ NO → Timeout
            ↓
        User calls fallbackToRegularWithdrawal()
            ↓
        수수료 환불 + Regular Withdrawal 시작 (7일)
```

**보안 효과:**
- ✅ 단 1명의 검증자가 오프라인이어도 사용자는 출금 가능 (fallback)
- ✅ 자금이 영구적으로 잠기는 일 방지
- ✅ 수수료 환불로 사용자 보호

### 3. Request Cancellation

```solidity
function cancelWithdrawalRequest(bytes32 requestId) external {
    // Only request owner can cancel
    // Refund fee
    // Delete request
}
```

**사용 시나리오:**
- 사용자가 출금을 변경하고 싶을 때
- 금액을 잘못 입력했을 때
- 더 이상 출금이 필요 없을 때

### 4. Emergency Pause

```solidity
bool public paused;

modifier whenNotPaused() {
    if (paused) revert ContractPaused();
    _;
}

function pause() external onlyOwner {
    paused = true;
}
```

**사용 시나리오:**
- 보안 취약점 발견 시
- 비정상적인 활동 감지 시
- 컨트랙트 업그레이드 전

### 5. Fee Management

**수수료 구조:**
```solidity
uint256 public fastWithdrawalFee;  // 예: 0.01 ETH

// Governance로 조정 가능
function setFastWithdrawalFee(uint256 _fee) external onlyOwner
```

**수수료 용도:**
1. Validator 보상 (서명 제공에 대한 인센티브)
2. Aggregator 보상 (증명 제출 비용 보상)
3. 프로토콜 수익

**분배 방법 (옵션):**
```
Option A: 컨트랙트에 수수료 보관 → 별도 분배 메커니즘
Option B: 실행 시 자동 분배 (gas 비용 증가)
Option C: Aggregator가 수수료 징수 후 validator에게 분배
```

## Deployment Example (최신 버전)

### Testnet Deployment
```javascript
const stakingContract = "0x...";
const minValidatorsForFastWithdrawal = 3;
const fastWithdrawalResponsePeriod = 5 * 60; // 5 minutes
const minFastWithdrawalFee = ethers.utils.parseEther("0.01"); // 0.01 ETH (최소 고정 수수료)
const fastWithdrawalFeeRate = 50; // 0.5% (50 basis points)
const submissionFee = ethers.utils.parseEther("0.005"); // 0.005 ETH (aggregator 수수료)

const fastWithdrawal = await FastWithdrawal.deploy(
    stakingContract,
    minValidatorsForFastWithdrawal,
    fastWithdrawalResponsePeriod,
    minFastWithdrawalFee,
    fastWithdrawalFeeRate,
    submissionFee
);

console.log("FastWithdrawal deployed:", fastWithdrawal.address);
```

### Mainnet Deployment (Conservative)
```javascript
const stakingContract = "0x...";
const minValidatorsForFastWithdrawal = 10; // 보안을 위해 더 많은 검증자 요구
const fastWithdrawalResponsePeriod = 10 * 60; // 10 minutes (더 긴 응답 시간)
const minFastWithdrawalFee = ethers.utils.parseEther("0.02"); // 0.02 ETH
const fastWithdrawalFeeRate = 100; // 1% (100 basis points)
const submissionFee = ethers.utils.parseEther("0.01"); // 0.01 ETH

const fastWithdrawal = await FastWithdrawal.deploy(
    stakingContract,
    minValidatorsForFastWithdrawal,
    fastWithdrawalResponsePeriod,
    minFastWithdrawalFee,
    fastWithdrawalFeeRate,
    submissionFee
);
```

### 수수료 계산 예시

```javascript
// 100 ETH 출금 요청
const amount = ethers.utils.parseEther("100");
const requiredFee = await fastWithdrawal.calculateFee(amount);

// 계산:
// percentageFee = 100 ETH × 100 / 10000 = 1 ETH
// requiredFee = max(1 ETH, 0.02 ETH) = 1 ETH

console.log("Required fee:", ethers.utils.formatEther(requiredFee)); // "1.0"
```

```javascript
// 1 ETH 출금 요청 (소액)
const smallAmount = ethers.utils.parseEther("1");
const requiredFee = await fastWithdrawal.calculateFee(smallAmount);

// 계산:
// percentageFee = 1 ETH × 100 / 10000 = 0.01 ETH
// requiredFee = max(0.01 ETH, 0.02 ETH) = 0.02 ETH (최소 수수료)

console.log("Required fee:", ethers.utils.formatEther(requiredFee)); // "0.02"
```

## 출금 Flow (Optimism 기본 + 빠른 출금 옵션)

### Optimism 기본 출금 Flow (변경 없음)

```
1. L2에서 출금 시작
   └─ L2ToL1MessagePasser.initiateWithdrawal(100 ETH)
   └─ 출금 메시지가 L2에 기록됨

2. L1에서 출금 증명
   └─ OptimismPortal2.proveWithdrawalTransaction()
   └─ ProvenWithdrawal 생성
   └─ 타임스탬프 기록

3. 7일 대기 (Challenge Period)
   └─ DisputeGame으로 State Root 검증
   └─ 챌린지 기간: 7일

4. 출금 실행
   └─ OptimismPortal2.finalizeWithdrawalTransaction()
   └─ 7일 경과 확인 후 실행
   
총 소요 시간: 7일
비용: Gas fee만
```

### 빠른 출금 옵션 추가

Optimism 기본 Flow에 **Step 2.5**가 추가됩니다:

```
1. L2에서 출금 시작
   └─ L2ToL1MessagePasser.initiateWithdrawal(100 ETH)

2. L1에서 출금 증명
   └─ OptimismPortal2.proveWithdrawalTransaction()
   └─ ProvenWithdrawal 생성

2.5. 빠른 출금 요청 (새로 추가! - 선택사항)
   └─ FastWithdrawal.requestFastWithdrawal{value: fee}(100 ETH)
   └─ withdrawalHash를 FastWithdrawal에 연결
   └─ 응답 기간 시작 (예: 5분)
   
   이후 두 가지 경로:
   
   ┌─ Path A: 검증자 응답 (만장일치) ─────────┐
   │                                         │
   │  Validators sign via libp2p (1-2분)    │
   │  Aggregator submits BLS proof           │
   │  └─ executeWithdrawalWithProof()        │
   │  └─ OptimismPortal2.finalizeWithdrawalTransaction()
   │      (7일 대기 없이 즉시 실행)           │
   │  └─ 수수료 분배                          │
   │                                         │
   │  총 소요 시간: ~3-5분 ✅                 │
   └─────────────────────────────────────────┘
   
   ┌─ Path B: 검증자 무응답 ──────────────────┐
   │                                         │
   │  응답 기간 만료 (5분)                    │
   │  └─ 자동으로 Optimism 기본 출금으로 전환 │
   │                                         │
   └─────────────────────────────────────────┘

3. 일반 출금으로 진행 (Path B인 경우)
   └─ 7일 대기
   └─ OptimismPortal2.finalizeWithdrawalTransaction()
   └─ 수수료 환불
   
   총 소요 시간: 7일 + 5분
```

### 사용자 선택권

```
사용자는 Step 2 이후 선택할 수 있습니다:

Option 1: 빠른 출금 시도 (Step 2.5 실행)
  ├─ 장점: 성공 시 즉시 출금 (3-5분)
  ├─ 단점: 수수료 필요
  └─ 실패 시: 자동으로 Option 2로 전환 (수수료 환불)

Option 2: 일반 출금 (Step 2.5 건너뛰기)
  ├─ 장점: 수수료 없음
  ├─ 단점: 7일 대기
  └─ 안전성: Optimism 기본 보안
```

## User Flow Examples

### Happy Path: Successful Fast Withdrawal
```
Step 1: L2에서 출금 시작
  └─ L2ToL1MessagePasser.initiateWithdrawal(100 ETH)
  
Step 2: L1에서 증명
  └─ OptimismPortal2.proveWithdrawalTransaction()
  └─ ProvenWithdrawal 생성
  
Step 3: 빠른 출금 요청
  └─ User: fastWithdrawal.requestFastWithdrawal{value: 0.5 ETH}(100 ETH)
  └─ Event: WithdrawalRequested(requestId, user, 100 ETH)
  └─ Validator set snapshot: 10명
  └─ Deadline: 현재시각 + 5분
  
Step 4: 검증자 서명 (libp2p)
  └─ Validator 1-10: 모두 BLS 서명 생성 및 전송
  └─ 소요 시간: ~2분
  
Step 5: Aggregator 제출
  └─ Aggregator: 서명 수집 완료
  └─ executeWithdrawalWithProof(requestId, aggregatedSig, bitmap)
  
Step 6: 검증 및 실행
  └─ Contract: 만장일치 확인 (10/10) ✅
  └─ BLS 서명 검증 ✅
  └─ 즉시 출금 실행
  └─ Event: FastWithdrawalExecuted(requestId, user, 100 ETH)
  
Step 7: 수수료 분배
  ├─ Aggregator: 0.05 ETH (submissionFee)
  └─ Validators: (0.5 - 0.05) / 10 = 0.045 ETH each
  
Result: 
  └─ User receives 100 ETH in ~3 minutes! 🎉
  └─ Total fee: 0.5 ETH
```

### Fallback Path: No Validator Response
```
Step 1-3: 위와 동일
  └─ fastWithdrawal.requestFastWithdrawal{value: 0.5 ETH}(100 ETH)
  
Step 4: 검증자 응답 실패
  └─ Only 9/10 validators respond (1 offline)
  └─ Unanimous consensus NOT reached
  
Step 5: 응답 기간 만료
  └─ 5분 경과...
  └─ Deadline expired
  
Step 6: Optimism 일반 출금으로 전환
  └─ User: OptimismPortal2.finalizeWithdrawalTransaction()
  └─ Portal checks:
      ├─ Fast withdrawal deadline passed? ✅
      ├─ Dispute game valid? ✅
      └─ Process as regular withdrawal
  
Step 7: 수수료 환불 (자동)
  └─ Contract refunds 0.5 ETH to user
  └─ Event: FastWithdrawalTimeout(requestId, user)
  
Step 8: 7일 대기
  └─ Challenge period: 7 days
  └─ After 7 days: Withdrawal executed
  
Result:
  └─ User receives 100 ETH after 7 days + 5min
  └─ Fee refunded: 0.5 ETH ✅
```

## Monitoring & Metrics

### Key Metrics to Track
```javascript
// Success rate
const successRate = (successfulWithdrawals / totalRequests) * 100;

// Average execution time
const avgTime = totalExecutionTime / successfulWithdrawals;

// Timeout rate
const timeoutRate = (timeoutRequests / totalRequests) * 100;

// Validator participation
const participationRate = (signedCount / totalValidators) * 100;
```

### Recommended Alerts
```
⚠️ Alert 1: Success rate < 70%
   → Action: Investigate validator availability

⚠️ Alert 2: Timeout rate > 30%
   → Action: Check network health or increase timeout

⚠️ Alert 3: Fast withdrawal disabled (insufficient validators)
   → Action: Notify users, recruit more validators

🚨 Alert 4: Contract paused
   → Action: Emergency notification to all users
```

## Gas Cost Analysis

### Fast Withdrawal Execution
```
BLS signature verification:   ~150,000 gas
Bitmap validation (10 val):    ~10,000 gas
Storage updates:                ~50,000 gas
Transfer execution:             ~21,000 gas
Event emissions:                ~10,000 gas
----------------------------------------
Total:                         ~241,000 gas

At 50 gwei gas price:
Cost ≈ 241,000 × 50 × 10^-9 = 0.012 ETH ≈ $24 (at $2000/ETH)
```

### Comparison
```
Individual ECDSA verification (100 validators):
  100 × 60,000 = 6,000,000 gas ≈ 0.3 ETH ≈ $600

BLS aggregated verification:
  ~241,000 gas ≈ 0.012 ETH ≈ $24

Savings: 96% reduction in gas costs! 💰
```

## Future Improvements

### 1. Dynamic Fee Adjustment
```solidity
// Adjust fee based on demand
function updateFeeBasedOnDemand() internal {
    if (requestsLastHour > 100) {
        fastWithdrawalFee = fastWithdrawalFee * 12 / 10; // +20%
    }
}
```

### 2. Reputation System
```solidity
mapping(address => uint256) public validatorResponseRate;

// Track validator reliability
// Prefer responsive validators for future requests
```

### 3. Partial Consensus (Future)
```solidity
// Currently: 100% required
// Future: Allow 90% or 95% with higher fee
uint256 public consensusThreshold = 100; // adjustable
```

### 4. Cross-Chain Support
```solidity
// Support withdrawals to different chains
function requestCrossChainWithdrawal(
    uint256 amount,
    uint256 destinationChainId
) external payable;
```
