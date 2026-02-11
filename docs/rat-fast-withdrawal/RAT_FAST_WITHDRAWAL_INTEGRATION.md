# RAT Fast Withdrawal - Layer2 Integration Guide

This document describes the contract modifications required for Layer2 projects to integrate RAT Fast Withdrawal.

**Goal:** Reduce 7-day withdrawal delay → Instant withdrawal (RAT validator signatures)

---

## Modified/Created Files

### Optimism Portal

| File | Changes |
|------|---------|
| `src/L1/OptimismPortal2.sol` | Added Fast Withdrawal functions and storage |

### RAT Contract (Already Implemented)

| File | Status |
|------|--------|
| `ton-staking-v2/src/validator/RATFastWithdrawal.sol` | ✅ Implemented |
| `ton-staking-v2/src/libraries/RATFastWithdrawalLib.sol` | ✅ Implemented |

---

## 1. OptimismPortal2 Modifications

**File:** `packages/contracts-bedrock/src/L1/OptimismPortal2.sol`

### 1.1 Added Storage

**Location:** After existing storage variables (around line 100)

```solidity
// ============================================================
// Fast Withdrawal Storage (RAT Integration)
// ============================================================

/// @notice RAT contract address for Fast Withdrawal verification
address public ratContract;

/// @notice RAT-verified withdrawals that can bypass the 7-day delay
mapping(bytes32 => bool) public ratVerifiedWithdrawals;

/// @notice Fast Withdrawal response period (default: 10 minutes)
uint256 public fastWithdrawalResponsePeriod;
```

**Storage Reuse:**
```solidity
/// @notice Existing mapping - reuse for both regular and fast withdrawals
mapping(bytes32 => bool) public finalizedWithdrawals;
```

### 1.2 Added Events

```solidity
/// @notice Emitted when a fast withdrawal is requested (via RAT)
event FastWithdrawalRequested(
    bytes32 indexed withdrawalHash,
    address indexed user,
    uint256 amount,
    bytes32 stateRoot,
    uint256 deadline
);

/// @notice Emitted when a withdrawal is verified by RAT
event RATWithdrawalVerified(bytes32 indexed withdrawalHash);

/// @notice Emitted when a fast withdrawal is finalized
event FastWithdrawalFinalized(bytes32 indexed withdrawalHash, bool success);

/// @notice Emitted when the RAT contract address is updated
event RATContractUpdated(address indexed oldRatContract, address indexed newRatContract);
```

### 1.3 Added Errors

```solidity
/// @notice Thrown when a withdrawal has not been verified by RAT
error OptimismPortal_NotVerifiedByRAT();

/// @notice Thrown when the caller is not the RAT contract
error OptimismPortal_OnlyRAT();
```

**Error Reuse:**
```solidity
/// @notice Existing error - reuse for both regular and fast withdrawals
error OptimismPortal_AlreadyFinalized();
```

### 1.4 Added Functions

#### A. proveAndRequestFastWithdrawal() - RAT Only

**Access Control:** Only callable by RAT contract. Users call `RAT.requestFastWithdrawal()` which internally calls this function.

```solidity
/// @notice Prove withdrawal and request fast withdrawal (RAT only)
function proveAndRequestFastWithdrawal(
    Types.WithdrawalTransaction memory _tx,
    uint256 _disputeGameIndex,
    Types.OutputRootProof calldata _outputRootProof,
    bytes[] calldata _withdrawalProof
) external {
    if (msg.sender != ratContract) {
        revert OptimismPortal_OnlyRAT();
    }

    // Step 1: Prove the withdrawal transaction (starts 7-day countdown as fallback)
    this.proveWithdrawalTransaction(_tx, _disputeGameIndex, _outputRootProof, _withdrawalProof);

    // Step 2: Emit event for RAT validators to detect and sign
    bytes32 withdrawalHash = Hashing.hashWithdrawal(_tx);
    uint256 deadline = block.timestamp + fastWithdrawalResponsePeriod;

    emit FastWithdrawalRequested(
        withdrawalHash,
        msg.sender,
        _tx.value,
        _outputRootProof.stateRoot,
        deadline
    );
}
```

#### B. setWithdrawalVerified() - RAT Only

```solidity
/// @notice Mark a withdrawal as verified by RAT (RAT only)
function setWithdrawalVerified(bytes32 _withdrawalHash) external {
    if (msg.sender != ratContract) {
        revert OptimismPortal_OnlyRAT();
    }

    ratVerifiedWithdrawals[_withdrawalHash] = true;

    emit RATWithdrawalVerified(_withdrawalHash);
}
```

#### C. fastWithdrawalFinalize()

```solidity
/// @notice Finalize a fast withdrawal (bypass 7-day delay)
function fastWithdrawalFinalize(Types.WithdrawalTransaction memory _tx) external {
    bytes32 withdrawalHash = Hashing.hashWithdrawal(_tx);

    require(ratVerifiedWithdrawals[withdrawalHash], OptimismPortal_NotVerifiedByRAT());
    require(!finalizedWithdrawals[withdrawalHash], OptimismPortal_AlreadyFinalized());

    _transferAssets(_tx);
    finalizedWithdrawals[withdrawalHash] = true;

    emit FastWithdrawalFinalized(withdrawalHash, true);
}
```

#### D. Admin Functions

```solidity
function setRATContract(address _ratContract) external {
    require(msg.sender == guardian(), "OptimismPortal: only guardian");
    address oldRatContract = ratContract;
    ratContract = _ratContract;
    emit RATContractUpdated(oldRatContract, _ratContract);
}

function setFastWithdrawalResponsePeriod(uint256 _period) external {
    require(msg.sender == guardian(), "OptimismPortal: only guardian");
    fastWithdrawalResponsePeriod = _period;
}
```

---

## 2. RAT Contract - Fee System

**File:** `ton-staking-v2/src/validator/RATFastWithdrawal.sol`

### 2.1 Fee Model

- **Fee Token:** TON (ERC20)
- **Fee Amount:** Fixed (e.g., 10 TON = 10e18)
- **Fee Collection:** RAT collects TON via `transferFrom` (user must `approve` first)
- **Fee Distribution:** On successful fast withdrawal, distributed to aggregator + validators (TON transfer)
- **Fee Reclaim:** If deadline passes without processing, user can reclaim fee

### 2.2 requestFastWithdrawal (User Entry Point)

```solidity
/// @notice 빠른 출금 요청 (수수료: TON)
function requestFastWithdrawal(
    Types.WithdrawalTransaction memory _tx,
    uint256 _disputeGameIndex,
    Types.OutputRootProof calldata _outputRootProof,
    bytes[] calldata _withdrawalProof,
    address _systemConfig
) external whenNotPaused {
    uint256 fee = fastWithdrawalFee;
    if (fee == 0) revert InsufficientFastWithdrawalFeeError();

    // TON 수수료 수령
    IERC20(ton).transferFrom(msg.sender, address(this), fee);

    address portal = _getOptimismPortal(_systemConfig);
    if (portal == address(0)) revert FastWithdrawalPortalNotSetError();

    // Portal 빠른 출금 증명 호출 (RAT만 호출 가능)
    IOptimismPortal2ForRAT(portal).proveAndRequestFastWithdrawal(
        _tx, _disputeGameIndex, _outputRootProof, _withdrawalProof
    );

    // 수수료 저장
    bytes32 withdrawalHash = keccak256(abi.encode(
        _tx.nonce, _tx.sender, _tx.target, _tx.value, _tx.gasLimit, _tx.data
    ));
    uint256 deadline = block.timestamp + IOptimismPortal2ForRAT(portal).fastWithdrawalResponsePeriod();
    pendingFees[withdrawalHash] = PendingFee({
        amount: fee,
        user: msg.sender,
        deadline: deadline
    });

    emit FastWithdrawalRequested(withdrawalHash, msg.sender, _tx.value, fee, deadline);
}
```

### 2.3 verifyAndExecuteFastWithdrawal (Aggregator)

```solidity
/// @notice Verify and execute fast withdrawal
function verifyAndExecuteFastWithdrawal(
    Types.WithdrawalTransaction calldata _tx,
    RATFastWithdrawalLib.FastWithdrawalInput calldata input,
    bytes calldata _aggregatedSignature
) external ifFree whenNotPaused {
    // 1. Validate preconditions
    // 2. Check game claims
    // 3. Check minimum validators
    // 4. Check unanimous consensus (100%)
    // 5. Verify BLS aggregated signature
    // 6. Verify adjacent leaves proof
    // 7. Portal.setWithdrawalVerified + fastWithdrawalFinalize
    // 8. Distribute TON fees (aggregator + validators)
}
```

### 2.4 reclaimFee (User - Timeout Recovery)

```solidity
/// @notice 기한 초과 시 TON 수수료 환불
function reclaimFee(bytes32 _withdrawalHash) external {
    PendingFee memory fee = pendingFees[_withdrawalHash];
    if (fee.amount == 0) revert FeeAlreadyClaimedError();
    if (block.timestamp <= fee.deadline + 120) revert FeeNotReclaimableError();
    if (processedWithdrawals[_withdrawalHash]) revert FeeAlreadyClaimedError();

    delete pendingFees[_withdrawalHash];
    IERC20(ton).transfer(fee.user, fee.amount);

    emit FeeReclaimed(_withdrawalHash, fee.user, fee.amount);
}
```

### 2.5 Input Structure

**File:** `ton-staking-v2/src/libraries/RATFastWithdrawalLib.sol`

```solidity
struct FastWithdrawalInput {
    bytes32 withdrawalHash;
    address systemConfig;
    address gameAddress;      // For dispute check
    bytes32 stateRoot;
    uint256 validatorBitmap;  // Signed validators bitmap
    bytes32 leafA;            // Adjacent leaf A
    bytes32 leafB;            // Adjacent leaf B
    bytes[] proofsA;          // Merkle proof for leaf A
    bytes[] proofsB;          // Merkle proof for leaf B
}
```

---

## 3. Integration Flow

### Call Sequence

```
User → TON.approve(RAT, fee)
  ↓
User → RAT.requestFastWithdrawal()
  ↓ RAT collects TON fee via transferFrom
  ↓ RAT calls Portal.proveAndRequestFastWithdrawal() (RAT only)
  ↓ Portal emits FastWithdrawalRequested
  ↓ RAT emits FastWithdrawalRequested (with fee info)
Validators → Generate BLS signatures (offchain)
  ↓
Aggregator → RAT.verifyAndExecuteFastWithdrawal()
  ↓ verify BLS signatures + adjacent leaves
RAT → Portal.setWithdrawalVerified()
RAT → Portal.fastWithdrawalFinalize() → transfer assets to user
RAT → distribute TON fees (aggregator + validators)
  ↓
Done (3 minutes vs 7 days)

Timeout (fallback):
  User → RAT.reclaimFee(withdrawalHash) → TON refund
  User → Portal.finalizeWithdrawalTransaction() → 7-day standard path
```

### Access Control

| Function | Caller | Restriction |
|----------|--------|-------------|
| `Portal.proveAndRequestFastWithdrawal` | **RAT only** | `OptimismPortal_OnlyRAT` |
| `Portal.setWithdrawalVerified` | **RAT only** | `OptimismPortal_OnlyRAT` |
| `Portal.fastWithdrawalFinalize` | Anyone | RAT verification required |
| `RAT.requestFastWithdrawal` | Anyone (User) | TON fee required (approve first) |
| `RAT.verifyAndExecuteFastWithdrawal` | Anyone (Aggregator) | Valid BLS signature required |
| `RAT.reclaimFee` | Anyone | Deadline passed + not yet processed |

---

## 4. Key Security Features

### 4.1 Access Control

```solidity
// CRITICAL: Only RAT can prove + request fast withdrawal
if (msg.sender != ratContract) revert OptimismPortal_OnlyRAT();

// CRITICAL: Only RAT can mark withdrawal as verified
if (msg.sender != ratContract) revert OptimismPortal_OnlyRAT();
```

### 4.2 Double Withdrawal Prevention

```solidity
// Reuse existing mapping - prevents both regular and fast withdrawal replay
require(!finalizedWithdrawals[withdrawalHash], OptimismPortal_AlreadyFinalized());
```

### 4.3 Game Claim Check

```solidity
// Block fast withdrawal if dispute exists
if (claimCount > 0) revert FastWithdrawalGameHasClaimsError();
```

### 4.4 Unanimous Consensus

```solidity
// All validators must sign (N-of-N)
if (validatorBitmap != (1 << validatorCount) - 1) {
    revert FastWithdrawalNotUnanimousError();
}
```

### 4.5 Fee Protection

```solidity
// Timeout recovery: user can reclaim TON fee if fast withdrawal is not processed
if (block.timestamp <= fee.deadline + 120) revert FeeNotReclaimableError();
if (processedWithdrawals[_withdrawalHash]) revert FeeAlreadyClaimedError();
```

---

## 5. Deployment Steps

### Step 1: Deploy/Configure RAT

```bash
# Set minimum validators
cast send $RAT "setMinValidatorsForFastWithdrawal(uint256)" 3

# Set aggregator fee rate (10%)
cast send $RAT "setAggregatorFeeRate(uint256)" 1e26

# Set fast withdrawal fee (10 TON)
cast send $RAT "setFastWithdrawalFee(uint256)" 10000000000000000000
```

### Step 2: Upgrade OptimismPortal2

```bash
# Deploy new implementation with Fast Withdrawal functions
forge script script/UpgradePortal.s.sol --broadcast
```

### Step 3: Connect Portal and RAT

```bash
# Portal: Set RAT address
cast send $PORTAL "setRATContract(address)" $RAT

# Portal: Set response period (10 minutes)
cast send $PORTAL "setFastWithdrawalResponsePeriod(uint256)" 600
```

### Step 4: Register Validators

```bash
# Each validator registers BLS public key
cast send $RAT "registerValidator(address)" $SYSTEM_CONFIG
cast send $RAT "registerBLSPublicKey(address,bytes,bytes)" \
  $SYSTEM_CONFIG $BLS_PUBKEY $BLS_SIGNATURE
```

---

## 6. Verification Checklist

### OptimismPortal2

- [ ] `ratContract` storage added
- [ ] `ratVerifiedWithdrawals` mapping added
- [ ] `fastWithdrawalResponsePeriod` storage added
- [ ] `proveAndRequestFastWithdrawal()` implemented with **RAT-only** access control
- [ ] `setWithdrawalVerified()` implemented with RAT-only access control
- [ ] `fastWithdrawalFinalize()` implemented
- [ ] Admin functions implemented
- [ ] 4 events added
- [ ] 2 errors added

### RAT Integration

- [ ] RAT contract deployed
- [ ] Portal.setRATContract() called
- [ ] Portal.setFastWithdrawalResponsePeriod() called
- [ ] RAT.setMinValidatorsForFastWithdrawal() called
- [ ] RAT.setFastWithdrawalFee() called (e.g., 10 TON)
- [ ] Validators registered with BLS keys

### Testing

- [ ] Normal fast withdrawal flow (User → RAT → Portal)
- [ ] Access control (only RAT can call proveAndRequestFastWithdrawal)
- [ ] Access control (only RAT can verify)
- [ ] Double withdrawal prevention
- [ ] Game claim check
- [ ] TON fee collection and distribution
- [ ] Fee reclaim on timeout

---

## 7. Implementation Notes

### Storage Optimization

- Reuse existing `finalizedWithdrawals` mapping for both regular and fast withdrawals
- Reuse existing error `OptimismPortal_AlreadyFinalized` for both types
- Only 3 new storage variables needed (`ratContract`, `ratVerifiedWithdrawals`, `fastWithdrawalResponsePeriod`)

### Fee Architecture

- Portal does NOT handle fees - it only handles proof + verification + finalization
- RAT handles the entire fee lifecycle: collection (TON) → storage → distribution / refund
- Fee is paid in TON (ERC20), not ETH
- Fixed fee amount (e.g., 10 TON), not percentage-based

### Custom Gas Token Support

OptimismPortal2 already supports both Native ETH and Custom Gas Token.
Fast Withdrawal uses the existing asset transfer logic - no additional changes needed.

---

## 8. Gas Costs

| Operation | Gas | Notes |
|-----------|-----|-------|
| `RAT.requestFastWithdrawal` | ~100k | TON transfer + Portal prove + event |
| `RAT.verifyAndExecuteFastWithdrawal` | ~280k | BLS + adjacent leaves verification |
| `Portal.fastWithdrawalFinalize` | ~50k | Asset transfer + state update |
| **Total** | **~430k** | vs 7 days wait |

---

## 9. op-proposer Gas Limit Fix

### Problem

`DisputeGameFactory.create()`에서 `IRAT.triggerAttentionTest()`가 try-catch로 감싸져 있어,
RAT 호출이 가스 부족으로 실패해도 트랜잭션은 성공합니다.
이로 인해 op-proposer의 `eth_estimateGas`가 RAT에 필요한 가스를 제외한 최소값만 반환합니다.

| 시나리오 | gasLimit | gasUsed | RAT 결과 |
|----------|----------|---------|----------|
| eth_estimateGas (수정 전) | ~475,000 | ~468,000 | out of gas (try-catch로 무시됨) |
| 명시적 설정 (수정 후) | 1,500,000 | ~943,000 | AttentionTestTriggered 성공 |

### Fix

**File:** `op-proposer/contracts/disputegamefactory.go` - `ProposalTx` 함수

```go
candidate.Value = initBond
// Set explicit gas limit to ensure sufficient gas for RAT triggerAttentionTest
// called via try-catch in DGF.create(). eth_estimateGas underestimates because
// the try-catch makes the tx succeed even when RAT call runs out of gas.
candidate.GasLimit = 1_500_000
return candidate, err
```

### Why 1,500,000?

- 게임 생성 기본 가스: ~506,000
- RAT triggerAttentionTest 추가 가스: ~437,000
- 합계: ~943,000
- 여유분 포함: 1,500,000

> **Note:** RAT 검증자가 없는 경우에도 이 가스 리밋이 적용되지만,
> 실제 가스는 ~506,000만 소비되므로 추가 비용은 없습니다 (미사용 가스는 환불됨).

---

## 10. RAT Client (Validator) Configuration

### rat-client-type3 Configuration Fix

**Repository:** `ton-staking-v2/clients/rat-client-type3/`

The RAT validator client monitors `AttentionTestTriggered` events and submits evidence (adjacent leaves proof) within the deadline. Two critical configuration parameters affect evidence submission success:

#### Problem

The original configuration prevented evidence submission:
- `DeadlineBuffer` was set to 600 seconds (= `evidenceSubmissionPeriod`)
- By the time the client detected an event, less than 600s remained before deadline
- The client always rejected with: `"deadline too close: N seconds remaining"`

#### Fix

**File: `pkg/client/config.go`**

| Parameter | Before | After | Description |
|-----------|--------|-------|-------------|
| `Confirmations` | 2 | **1** | L1 blocks to wait before treating events as final |
| `DeadlineBuffer` | 10 min | **2 min** | Safety margin before deadline to stop submission attempts |

```go
// Default config changes
Confirmations:  1,                    // Detect events faster (was 2)
DeadlineBuffer: 2 * time.Minute,      // Submit up to 2 min before deadline (was 10 min)
```

**File: `pkg/client/service_adjacent.go`**

- Added `deadlineBuffer` field to `RATClientAdjacentService` struct
- Replaced hardcoded `600s` deadline check with configurable buffer from config

```go
// Before (hardcoded):
if timeRemaining < 600 {
    return fmt.Errorf("deadline too close: %d seconds remaining", timeRemaining)
}

// After (configurable):
bufferSeconds := int64(s.deadlineBuffer.Seconds())
if timeRemaining < bufferSeconds {
    return fmt.Errorf("deadline too close: %d seconds remaining (buffer=%ds)", timeRemaining, bufferSeconds)
}
```

**File: `cmd/main.go`**

- Added `DeadlineBuffer` passthrough from config to `AdjacentServiceConfig`

#### Evidence Submission Flow

```
L1: AttentionTestTriggered event emitted
  ↓ (wait Confirmations blocks)
Client: Detect event via FilterLogs
  ↓ (check deadline - buffer)
Client: Query L2 state via debug_accountRange
  ↓
Client: Generate adjacent leaves proof via eth_getProof
  ↓
Client: Submit evidence tx to L1 RAT contract
```

#### L2 RPC Requirements

The validator client requires the following L2 RPC methods:

| Method | Purpose | Namespace |
|--------|---------|-----------|
| `debug_accountRange` | Iterate state trie to find adjacent account leaves | `debug` |
| `eth_getProof` | Generate Merkle proofs for adjacent leaves | `eth` |
| `eth_getBlockByNumber` | Fetch block header for StateRoot | `eth` |

> **Important:** The L2 node (op-geth) must have `debug` API enabled:
> `--http.api=eth,net,web3,debug,txpool,miner`

---

## 11. References

### Current Implementation

- RAT Fast Withdrawal: `ton-staking-v2/src/validator/RATFastWithdrawal.sol`
- Fast Withdrawal Library: `ton-staking-v2/src/libraries/RATFastWithdrawalLib.sol`
- BLS Library: `ton-staking-v2/src/libraries/BLS12381.sol`
- Adjacent Leaves Verifier: `ton-staking-v2/src/libraries/AdjacentLeavesVerifier.sol`
- Game Claim Check: `ton-staking-v2/docs/rat-fast-withdrawal/GAME_CLAIM_CHECK.md`

### Optimism Base

- OptimismPortal2: `optimism/packages/contracts-bedrock/src/L1/OptimismPortal2.sol`
- Types: `optimism/packages/contracts-bedrock/src/libraries/Types.sol`

---

*Last Updated: 2026-02-11*
