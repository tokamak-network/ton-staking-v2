# Optimism Fast Withdrawal Integration Design

이 문서는 Optimism의 출금 메커니즘을 분석하고, RAT 집단 BLS 서명을 활용한 빠른 출금 통합 설계를 제안합니다.

---

## 1. Optimism 출금 메커니즘 분석

### 1.1 핵심 스토리지

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         출금 관련 핵심 스토리지                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  L2: L2ToL1MessagePasser (0x4200...0016)                                   │
│  ═══════════════════════════════════════                                    │
│                                                                             │
│  mapping(bytes32 => bool) public sentMessages;                              │
│  └─ sentMessages[withdrawalHash] = true                                     │
│     → "이 출금이 L2에서 시작됨"                                              │
│                                                                             │
│  ─────────────────────────────────────────────────────────────────────────  │
│                                                                             │
│  L1: OptimismPortal2                                                        │
│  ═══════════════════                                                        │
│                                                                             │
│  struct ProvenWithdrawal {                                                  │
│      IDisputeGame disputeGameProxy;  // 어떤 게임 기준인지                   │
│      uint64 timestamp;                // 언제 증명했는지 (7일 카운트 시작)    │
│  }                                                                          │
│                                                                             │
│  // withdrawalHash => proofSubmitter => ProvenWithdrawal                    │
│  mapping(bytes32 => mapping(address => ProvenWithdrawal)) provenWithdrawals;│
│  └─ "이 출금이 언제, 어떤 DisputeGame으로 증명되었는지"                       │
│                                                                             │
│  mapping(bytes32 => bool) public finalizedWithdrawals;                      │
│  └─ "이 출금이 최종화되었는지 (true면 이미 출금됨)"                           │
│                                                                             │
│  uint256 immutable PROOF_MATURITY_DELAY_SECONDS;  // 7일                    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 1.2 출금 흐름

```
L2: initiateWithdrawal()
    └─ sentMessages[hash] = true

        ▼

L1: proveWithdrawalTransaction()
    └─ provenWithdrawals[hash][submitter] = {game, timestamp}
    └─ DisputeGame 정보 등록, 7일 카운트 시작

        ▼  (7일 대기 - DisputeGame 챌린지 기간)

L1: finalizeWithdrawalTransaction()
    └─ checkWithdrawal(): timestamp + 7일 지났는지 확인
    └─ finalizedWithdrawals[hash] = true
    └─ ETH 전송
```

### 1.3 7일 대기의 목적

```solidity
function checkWithdrawal(bytes32 _withdrawalHash, address _proofSubmitter) public view {
    // ...

    // 7일 대기 확인 ← Fast Withdrawal이 우회해야 할 핵심
    if (block.timestamp - provenWithdrawal.timestamp <= PROOF_MATURITY_DELAY_SECONDS) {
        revert OptimismPortal_ProofNotOldEnough();
    }

    // DisputeGame이 여전히 유효한지 (챌린저가 이겼으면 차단)
    if (!anchorStateRegistry.isGameClaimValid(disputeGameProxy)) {
        revert OptimismPortal_InvalidRootClaim();
    }
}
```

**7일 = Fraud Proof 챌린지 기간**
- "일단 맞다고 가정 (Optimistic), 틀리면 누군가 증명해라"
- 정직한 1명이 잘못된 Output Root를 발견하면 챌린지 → 출금 차단

---

## 2. Fast Withdrawal 스토리지 설계

### 2.1 핵심: 어떤 스토리지를 컨트롤해야 하는가?

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    출금을 가능하게 하는 스토리지 조건                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  일반 출금 (7일):                                                           │
│  ───────────────                                                            │
│  ✅ provenWithdrawals[hash][submitter].timestamp != 0  (증명됨)             │
│  ✅ block.timestamp - timestamp > 7 days               (7일 지남)           │
│  ✅ finalizedWithdrawals[hash] == false                (미출금)             │
│  ✅ isGameClaimValid(game) == true                     (게임 유효)          │
│                                                                             │
│  ═══════════════════════════════════════════════════════════════════════   │
│                                                                             │
│  Fast Withdrawal (즉시):                                                    │
│  ─────────────────────                                                      │
│  ✅ withdrawalVerified[hash] == true      ← RAT이 컨트롤!                   │
│  ✅ fastFinalizedWithdrawals[hash] == false            (미출금)             │
│                                                                             │
│  ═══════════════════════════════════════════════════════════════════════   │
│                                                                             │
│  withdrawalVerified[hash] = true 설정 조건:                                 │
│  1. BLS 집계 서명 검증 통과 (100% 합의)                                     │
│  2. 인접 리프 증명 검증 통과 (State Root 유효성)                            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 추가할 스토리지 (OptimismPortal2)

```solidity
// OptimismPortal2.sol 추가 스토리지

/// @notice RAT 컨트랙트 주소 (Fast Withdrawal 검증자)
address public ratContract;

/// @notice RAT 검증 완료된 출금 (7일 대기 우회 가능)
mapping(bytes32 => bool) public withdrawalVerified;

/// @notice Fast withdrawal로 최종화된 출금
mapping(bytes32 => bool) public fastFinalizedWithdrawals;
```

### 2.3 스토리지 상태 전이

```
                    withdrawalVerified    fastFinalizedWithdrawals
                    ─────────────────    ────────────────────────
요청 전                  false                   false
    │
    ▼ proveAndRequestFastWithdrawal() [이벤트 발생]
요청 중                  false                   false
    │
    │  ← RAT 검증자들이 오프체인에서 이벤트 감지 및 서명
    │
    ├──────────────────────────────────────────────────────────┐
    │                                                          │
    ▼ RAT.verifyAndExecuteFastWithdrawal() 성공                ▼ 타임아웃
검증 완료                true ←───────────────┐              false
    │                                        │                 │
    ▼ fastWithdrawalFinalize()               │                 ▼ 7일 대기 후 일반 finalize
출금 완료                true                 true              → finalizedWithdrawals = true
```

---

## 3. 이벤트 기반 아키텍처

### 3.1 전체 흐름

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         이벤트 기반 Fast Withdrawal 흐름                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  [1] 사용자 → OptimismPortal2                                               │
│      proveAndRequestFastWithdrawal()                                        │
│      └─ 일반 출금 증명 (7일 fallback 준비)                                   │
│      └─ FastWithdrawalRequested 이벤트 발생 ◄────────────────────────┐      │
│                                                                      │      │
│  ════════════════════════════════════════════════════════════════════│══    │
│                                                                      │      │
│  [2] RAT 검증자들 (오프체인)                                          │      │
│      └─ 이벤트 감지 ◄────────────────────────────────────────────────┘      │
│      └─ L2 State 검증 (withdrawalHash가 실제 존재하는지)                     │
│      └─ State Root 유효성 검증                                              │
│      └─ BLS 서명 생성 및 P2P 전파                                           │
│                                                                             │
│  ════════════════════════════════════════════════════════════════════════   │
│                                                                             │
│  [3] Aggregator (누구나 가능)                                               │
│      └─ 모든 검증자 서명 수집                                               │
│      └─ 집계 서명 생성                                                      │
│      └─ RAT 컨트랙트에 제출                                                 │
│                                                                             │
│  ════════════════════════════════════════════════════════════════════════   │
│                                                                             │
│  [4] RAT 컨트랙트 (온체인)                                                  │
│      verifyAndExecuteFastWithdrawal()                                       │
│      └─ BLS 집계 서명 검증 (100% 합의)                                      │
│      └─ 인접 리프 증명 검증                                                 │
│      └─ 검증 성공 시:                                                       │
│          → OptimismPortal2.setWithdrawalVerified(hash)                     │
│          → OptimismPortal2.fastWithdrawalFinalize(tx)                      │
│                                                                             │
│  ════════════════════════════════════════════════════════════════════════   │
│                                                                             │
│  [5] OptimismPortal2                                                        │
│      └─ withdrawalVerified[hash] = true                                    │
│      └─ fastFinalizedWithdrawals[hash] = true                              │
│      └─ ETH 전송                                                            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. OptimismPortal2 수정

### 4.1 통합 함수: proveAndRequestFastWithdrawal

```solidity
/// @notice 빠른 출금 요청 이벤트
event FastWithdrawalRequested(
    bytes32 indexed withdrawalHash,
    address indexed user,
    uint256 amount,
    bytes32 stateRoot,
    uint256 feePaid,
    uint256 deadline
);

/// @notice 출금 증명 + 빠른 출금 요청을 한 번에 수행
/// @dev Fast Withdrawal 실패 시 자동으로 일반 출금 경로 사용 가능
function proveAndRequestFastWithdrawal(
    Types.WithdrawalTransaction memory _tx,
    uint256 _disputeGameIndex,
    Types.OutputRootProof calldata _outputRootProof,
    bytes[] calldata _withdrawalProof
) external payable {
    // ═══════════════════════════════════════════════════════════════════
    // Step 1: 일반 출금 증명 (기존 로직)
    // → 7일 카운트 시작, Fast Withdrawal 실패 시 fallback 경로
    // ═══════════════════════════════════════════════════════════════════
    _proveWithdrawalTransactionInternal(
        _tx,
        _disputeGameIndex,
        _outputRootProof,
        _withdrawalProof
    );

    // ═══════════════════════════════════════════════════════════════════
    // Step 2: 빠른 출금 요청 이벤트 발생
    // → RAT 검증자들이 이 이벤트를 감지하여 서명 시작
    // ═══════════════════════════════════════════════════════════════════
    bytes32 withdrawalHash = Hashing.hashWithdrawal(_tx);
    uint256 deadline = block.timestamp + FAST_WITHDRAWAL_RESPONSE_PERIOD;

    emit FastWithdrawalRequested(
        withdrawalHash,
        msg.sender,
        _tx.value,
        _outputRootProof.stateRoot,
        msg.value,        // 수수료
        deadline
    );
}
```

**장점:**
- 한 번의 트랜잭션으로 두 경로 모두 준비
- Fast Withdrawal 실패 시 자동 fallback (이미 prove 완료)
- 이벤트만 발생 → RAT과의 직접 호출 없음 (느슨한 결합)

### 4.2 RAT이 호출하는 함수들

```solidity
/// @notice RAT 컨트랙트가 검증 완료 플래그 설정
/// @dev RAT 컨트랙트만 호출 가능
function setWithdrawalVerified(bytes32 _withdrawalHash) external {
    require(msg.sender == ratContract, "Only RAT");
    withdrawalVerified[_withdrawalHash] = true;

    emit WithdrawalVerifiedByRAT(_withdrawalHash);
}

/// @notice Fast withdrawal 최종화 (7일 대기 없이)
/// @dev RAT 컨트랙트만 호출 가능
function fastWithdrawalFinalize(
    Types.WithdrawalTransaction memory _tx
) external {
    require(msg.sender == ratContract, "Only RAT");

    bytes32 withdrawalHash = Hashing.hashWithdrawal(_tx);

    // 이중 출금 방지
    require(!finalizedWithdrawals[withdrawalHash], "Already finalized");
    require(!fastFinalizedWithdrawals[withdrawalHash], "Already fast finalized");

    // RAT 검증 완료 확인
    require(withdrawalVerified[withdrawalHash], "Not verified by RAT");

    // Fast finalized로 마킹
    fastFinalizedWithdrawals[withdrawalHash] = true;

    // ETH 언락 및 전송
    if (_tx.value > 0) ethLockbox.unlockETH(_tx.value);

    l2Sender = _tx.sender;
    bool success = SafeCall.callWithMinGas(_tx.target, _tx.gasLimit, _tx.value, _tx.data);
    l2Sender = Constants.DEFAULT_L2_SENDER;

    emit WithdrawalFinalized(withdrawalHash, success);

    if (!success && _tx.value > 0) {
        ethLockbox.lockETH{ value: _tx.value }();
    }
}
```

### 4.3 일반 finalize 수정

```solidity
function finalizeWithdrawalTransaction(Types.WithdrawalTransaction memory _tx) external {
    bytes32 withdrawalHash = Hashing.hashWithdrawal(_tx);

    // Fast finalized도 확인 추가
    require(!fastFinalizedWithdrawals[withdrawalHash], "Already fast finalized");

    // 기존 로직...
}
```

---

## 5. RAT 컨트랙트 Fast Withdrawal 함수

### 5.1 추가 스토리지 (RATStorage.sol)

```solidity
/// @notice OptimismPortal2 주소
address public optimismPortal;

/// @notice 빠른 출금 응답 기간 (기본: 10분)
uint256 public fastWithdrawalResponsePeriod;

/// @notice 집계자 제출 수수료율 (RAY 단위, 기본: 10% = 1e26)
uint256 public aggregatorFeeRate;

/// @notice 처리된 출금 해시 (재실행 방지)
mapping(bytes32 => bool) public processedWithdrawals;
```

### 5.2 검증 및 실행 함수

```solidity
/// @notice BLS 집계 서명 + 인접 리프 증명으로 빠른 출금 실행
/// @dev Aggregator가 호출 (누구나 가능, 수수료 인센티브)
/// @param _withdrawalHash 출금 해시 (이벤트에서 얻음)
/// @param _tx 출금 트랜잭션 정보
/// @param _stateRoot State Root
/// @param _aggregatedSignature BLS 집계 서명
/// @param _validatorBitmap 서명한 검증자 비트맵
/// @param _leafA 인접 리프 A
/// @param _leafB 인접 리프 B
/// @param _proofsA 리프 A의 Merkle Proof
/// @param _proofsB 리프 B의 Merkle Proof
function verifyAndExecuteFastWithdrawal(
    bytes32 _withdrawalHash,
    Types.WithdrawalTransaction calldata _tx,
    bytes32 _stateRoot,
    bytes calldata _aggregatedSignature,
    uint256 _validatorBitmap,
    bytes32 _leafA,
    bytes32 _leafB,
    bytes[] calldata _proofsA,
    bytes[] calldata _proofsB
) external {
    // 재실행 방지
    require(!processedWithdrawals[_withdrawalHash], "Already processed");

    // withdrawalHash 검증
    require(Hashing.hashWithdrawal(_tx) == _withdrawalHash, "Invalid withdrawal hash");

    address systemConfig = _tx.systemConfig;
    uint256 validatorCount = getActiveValidatorCount(systemConfig);

    // ═══════════════════════════════════════════════════════════════════
    // 검증 1: BLS 집계 서명 검증 (~130k gas)
    // "모든 검증자가 이 출금이 유효하다고 서명했는가?"
    // ═══════════════════════════════════════════════════════════════════
    bytes32 message = keccak256(abi.encodePacked(
        _withdrawalHash,
        _stateRoot,
        _leafA,
        _leafB
    ));

    // 100% 합의 확인 (N-of-N)
    require(
        _countSetBits(_validatorBitmap) == validatorCount,
        "Not unanimous"
    );

    // BLS 서명 검증
    bytes memory aggregatedPubKey = _aggregatePublicKeys(systemConfig, _validatorBitmap);
    require(
        BLS12381.verifySignature(aggregatedPubKey, message, _aggregatedSignature),
        "Invalid BLS signature"
    );

    // ═══════════════════════════════════════════════════════════════════
    // 검증 2: 인접 리프 증명 검증 (~60k gas)
    // "이 State Root가 실제로 존재하는 유효한 State Trie인가?"
    // ═══════════════════════════════════════════════════════════════════
    require(
        _verifyAdjacentLeaves(_stateRoot, _leafA, _leafB, _proofsA, _proofsB),
        "Invalid adjacent leaves proof"
    );

    // ═══════════════════════════════════════════════════════════════════
    // 검증 통과 → OptimismPortal2 스토리지 업데이트 및 출금 실행
    // ═══════════════════════════════════════════════════════════════════
    processedWithdrawals[_withdrawalHash] = true;

    // OptimismPortal2에 검증 완료 알림
    IOptimismPortal2(optimismPortal).setWithdrawalVerified(_withdrawalHash);

    // 출금 실행
    IOptimismPortal2(optimismPortal).fastWithdrawalFinalize(_tx);

    // 수수료 분배 (msg.value는 proveAndRequestFastWithdrawal에서 받은 수수료)
    _distributeFees(systemConfig, msg.sender);

    emit FastWithdrawalExecuted(_withdrawalHash, _tx.sender, _tx.value, msg.sender);
}

/// @notice 수수료 분배 (90% 검증자, 10% 집계자)
function _distributeFees(address _systemConfig, address _aggregator) internal {
    uint256 totalFee = address(this).balance;  // 수수료 풀에서

    uint256 aggregatorFee = (totalFee * aggregatorFeeRate) / RAY;
    uint256 validatorFees = totalFee - aggregatorFee;

    // 집계자에게 제출 수수료 지급
    if (aggregatorFee > 0) {
        payable(_aggregator).transfer(aggregatorFee);
    }

    // 검증자 수수료는 ValidatorReward로 적립
    if (validatorFees > 0) {
        IValidatorReward(validatorReward).addReward{value: validatorFees}(_systemConfig);
    }
}
```

---

## 6. 온체인 검증 요구사항

### 6.1 이중 검증

```
┌───────────────────────────────────────────────────────────────────────┐
│                     검증 1: BLS 집계 서명 (~130k gas)                   │
│                                                                        │
│  "100명 전원이 이 출금이 유효하다고 서명했는가?"                         │
│                                                                        │
│  - 100% 합의 확인 (N-of-N)                                             │
│  - Pairing 검증: e(H(m), pk_agg) == e(σ_agg, G1)                      │
└───────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌───────────────────────────────────────────────────────────────────────┐
│                   검증 2: 인접 리프 증명 (~60k gas)                     │
│                                                                        │
│  "이 State Root가 실제로 존재하는 유효한 State Trie인가?"               │
│                                                                        │
│  - leafA, leafB의 Merkle Proof 검증                                    │
│  - 인접성 검증 (Divergence check)                                      │
└───────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
         두 검증 모두 통과 → withdrawalVerified[hash] = true
```

---

## 7. 보안 동등성

### 7.1 1-of-N Honest Assumption

```
┌────────────────────────────────────────────────────────────────┐
│                     보안 동등성                                 │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  Optimistic (7일):                                             │
│  "1명이라도 정직하면, 틀린 출금을 챌린지로 막을 수 있다"         │
│                                                                │
│  Fast Withdrawal (즉시):                                       │
│  "1명이라도 정직하면, 틀린 출금에 서명 안 한다"                 │
│                                                                │
│  → 수학적으로 동등한 보안! (1-of-N honest assumption)           │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### 7.2 이중 출금 방지

| 스토리지 | 체크 위치 | 용도 |
|---------|---------|-----|
| `finalizedWithdrawals[hash]` | 일반 finalize | 일반 출금 완료 |
| `fastFinalizedWithdrawals[hash]` | fast finalize | Fast 출금 완료 |
| `processedWithdrawals[hash]` | RAT | 재실행 방지 |

두 곳 모두에서 양쪽을 확인하여 이중 출금 방지.

---

## 8. 아키텍처 요약

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        이벤트 기반 아키텍처                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────┐                          ┌─────────────────┐          │
│  │ OptimismPortal2 │                          │       RAT       │          │
│  │                 │                          │                 │          │
│  │ - 스토리지:     │                          │ - 스토리지:     │          │
│  │   ratContract   │                          │   optimismPortal│          │
│  │   withdrawal-   │                          │   processed-    │          │
│  │   Verified[]    │                          │   Withdrawals[] │          │
│  │   fastFinalized-│                          │                 │          │
│  │   Withdrawals[] │                          │ - 검증자 BLS키  │          │
│  │                 │                          │                 │          │
│  │ - 함수:         │  FastWithdrawalRequested │ - 함수:         │          │
│  │   proveAnd-     │  ═══════════════════════►│                 │          │
│  │   RequestFast-  │  (이벤트)                │  (오프체인 감지)│          │
│  │   Withdrawal()  │                          │       ↓         │          │
│  │                 │                          │  검증자 서명    │          │
│  │                 │                          │       ↓         │          │
│  │   setWithdrawal-│◄─────────────────────────┤  verifyAnd-     │          │
│  │   Verified()    │                          │  ExecuteFast-   │          │
│  │                 │                          │  Withdrawal()   │          │
│  │   fastWithdrawal│◄─────────────────────────┤                 │          │
│  │   Finalize()    │                          │                 │          │
│  └─────────────────┘                          └─────────────────┘          │
│                                                       │                     │
│                                                       ▼                     │
│                                            ┌─────────────────┐             │
│                                            │ValidatorReward  │             │
│                                            │                 │             │
│                                            │ - 검증자 수수료 │             │
│                                            │   분배          │             │
│                                            └─────────────────┘             │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**핵심 포인트:**
- OptimismPortal2 → RAT: 이벤트만 발생 (직접 호출 없음)
- RAT → OptimismPortal2: 검증 성공 시 스토리지 업데이트 및 출금 실행

---

## 9. 사용자 흐름 요약

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              사용자 흐름                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  L2: initiateWithdrawal(100 ETH)                                           │
│       │                                                                     │
│       ▼                                                                     │
│  L1: proveAndRequestFastWithdrawal{value: fee}(...)                        │
│       │                                                                     │
│       ├─► proveWithdrawalTransaction() [7일 fallback 준비]                 │
│       │                                                                     │
│       └─► emit FastWithdrawalRequested(...) [이벤트 발생]                  │
│               │                                                             │
│               ▼ (오프체인)                                                  │
│           RAT 검증자들이 이벤트 감지                                        │
│               │                                                             │
│               ▼                                                             │
│           L2 상태 검증 + BLS 서명                                          │
│               │                                                             │
│               ▼                                                             │
│           Aggregator가 서명 수집                                           │
│               │                                                             │
│               ├──────────────────────────────────────────────────────┐     │
│               │                                                      │     │
│               ▼                                                      ▼     │
│  ┌─────────────────────┐                           ┌─────────────────────┐ │
│  │ Fast Withdrawal     │                           │ Normal Withdrawal   │ │
│  │                     │                           │ (Fallback)          │ │
│  │ RAT: verifyAnd-     │                           │                     │
│  │ ExecuteFast-        │                           │ 타임아웃 또는       │ │
│  │ Withdrawal()        │                           │ 서명 실패 시        │ │
│  │      ↓              │                           │                     │ │
│  │ Portal: setWith-    │                           │ 7일 대기 후         │ │
│  │ drawalVerified()    │                           │ finalize-           │ │
│  │      ↓              │                           │ Withdrawal-         │ │
│  │ Portal: fastWith-   │                           │ Transaction()       │ │
│  │ drawalFinalize()    │                           │                     │ │
│  │      ↓              │                           │                     │ │
│  │ ✅ 즉시 출금!       │                           │ ✅ 7일 후 출금     │ │
│  └─────────────────────┘                           └─────────────────────┘ │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

*Last Updated: 2026-02-02*
