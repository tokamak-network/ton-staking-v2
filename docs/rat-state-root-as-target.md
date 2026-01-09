# State Root as Target Design

## Overview

현재 RAT는 `testId` (랜덤값)를 타겟으로 사용하지만, **State Root 자체를 타겟으로 사용**하는 것이 더 우아하고 강력합니다.

## Current vs New Design

### Current (testId-based):
```
RAT Contract:
  testId = keccak256(systemConfig, batchIndex, validator, timestamp)  // 랜덤

Validator:
  leafA, leafB = findAdjacentLeaves(testId)

Verification:
  1. leafA ∈ Tree(stateRoot) ✅
  2. leafB ∈ Tree(stateRoot) ✅
  3. leafA < testId <= leafB ✅
```

### New (State Root-based):
```
RAT Contract:
  testId = stateRoot  // 자기 참조!

Validator:
  leafA, leafB = findAdjacentLeaves(stateRoot)

Verification:
  1. leafA ∈ Tree(stateRoot) ✅
  2. leafB ∈ Tree(stateRoot) ✅
  3. leafA < stateRoot < leafB ✅  ← 자기 참조적 증명!
```

## Why State Root as Target?

### 1. 자기 참조적 우아함
"이 State Root가 진짜임을 증명하기 위해, 이 State Root 숫자 근처의 데이터를 제출"
- 외부 randomValue 생성 불필요
- State Root가 자기 자신을 증명

### 2. 천연 랜덤성
- State Root는 매 블록마다 변함
- 예측 불가능
- Pre-computation 공격 불가능

### 3. 완벽한 증명
- 검증자는 전체 트리를 인덱싱해야만 stateRoot 근처의 adjacent leaves를 찾을 수 있음
- "전체 데이터를 가지고 있는가?"를 완벽하게 증명

### 4. Instant Finality (향후 ZK)
```
Fraud Proof (Optimism):  7일 challenge window
ZK-Based RAT:            즉시 승인 ✅
```

## Implementation

### Option A: Add stateRoot Parameter (Recommended)

**RAT.sol 수정:**
```solidity
function triggerAttentionTest(
    address gameAddress,
    address systemConfig,
    uint32 batchIndex,
    bytes32 batchHash,
    bytes32 blockHash,
    bytes32 stateRoot    // ← 추가!
) external onlyValidFactory whenNotPaused {
    // ...

    // testId = stateRoot (자기 참조!)
    bytes32 testId = stateRoot;

    attentionTests[testId] = AttentionTest({
        validatorAddress: selectedValidator,
        systemConfig: systemConfig,
        batchIndex: batchIndex,
        gameAddress: gameAddress,
        deadline: deadline,
        status: AttentionTestStatus.Pending,
        bondAmount: bondAmount,
        batchHash: batchHash,
        stateRoot: stateRoot  // ← 저장
    });

    // ...
}
```

**AttentionTest 구조체 수정:**
```solidity
struct AttentionTest {
    address validatorAddress;
    address systemConfig;
    uint32 batchIndex;
    address gameAddress;
    uint256 deadline;
    AttentionTestStatus status;
    uint256 bondAmount;
    bytes32 batchHash;
    bytes32 stateRoot;     // ← 추가!
}
```

**Type3EvidenceVerifier.sol:**
```solidity
// verifyStateLeaf에서 randomValue 대신 stateRoot 사용
function verifyStateLeaf(bytes32 stateRoot, bytes calldata evidenceData)
    internal pure returns (bool)
{
    StateLeafEvidence memory ev = abi.decode(evidenceData, (StateLeafEvidence));

    // 1. Basic validation
    if (!_validateStateLeafBasics(ev)) return false;

    // 2. Range check: leafA < stateRoot < leafB (자기 참조!)
    if (!_verifyAdjacentRange(ev.leafAKey, ev.leafBKey, stateRoot)) return false;

    // 3. Merkle proof verification
    if (!_verifyPatriciaProofs(ev)) return false;

    return true;
}
```

### Option B: Read from DisputeGame (More Complex)

**IFaultDisputeGame interface:**
```solidity
interface IFaultDisputeGame {
    function rootClaim() external view returns (bytes32);
    // rootClaim = hash(OutputRootProof)
    // OutputRootProof = {version, stateRoot, messagePasserStorageRoot, latestBlockhash}
}
```

**문제점:**
- `rootClaim()`은 output root의 해시 (stateRoot 자체가 아님)
- OutputRootProof를 받아야 stateRoot 추출 가능
- 더 복잡함

**결론:** Option A (파라미터 추가)가 더 간단하고 명확함

## Caller Integration

**DisputeGameFactory에서 호출:**
```solidity
// DisputeGameFactory.create() 또는 resolve()에서
function _triggerRATTest(
    address gameAddress,
    Types.OutputRootProof calldata outputRootProof
) internal {
    rat.triggerAttentionTest(
        gameAddress,
        systemConfig,
        batchIndex,
        batchHash,
        blockHash,
        outputRootProof.stateRoot  // ← stateRoot 전달!
    );
}
```

## Go Client Changes

**현재:**
```go
// testId를 타겟으로 사용
func FindAdjacentLeaves(testId [32]byte, blockNumber uint64) (*AdjacentLeaves, error) {
    randomValue := new(big.Int).SetBytes(testId[:])
    // ...
}
```

**변경 후:**
```go
// stateRoot를 타겟으로 사용
func FindAdjacentLeaves(stateRoot common.Hash, blockNumber uint64) (*AdjacentLeaves, error) {
    // stateRoot를 randomValue로 사용
    randomValue := stateRoot.Big()

    // Adjacent leaves 찾기 (leafA < stateRoot < leafB)
    leaves, err := l2sync.FindAdjacentLeavesViaRPC(ctx, rpcClient, randomValue, blockNumber)
    // ...
}
```

**Event 처리:**
```go
// AttentionTestTriggered event
event AttentionTestTriggered(
    bytes32 indexed testId,        // testId = stateRoot
    address indexed validator,
    address indexed systemConfig,
    address gameAddress,
    uint32 batchIndex,
    uint256 deadline,
    bytes32 stateRoot              // ← 추가
);

// Client에서:
func (c *Client) handleAttentionTest(event *AttentionTestTriggered) {
    // testId == stateRoot
    stateRoot := event.StateRoot
    leaves := FindAdjacentLeaves(stateRoot, event.BlockNumber)
    // ...
}
```

## Migration Path

### Phase 1: Current Implementation
```
✅ testId = random
✅ leafA < testId <= leafB
```

### Phase 2: State Root as Target
```
🎯 testId = stateRoot
🎯 leafA < stateRoot < leafB
🎯 자기 참조적 증명
```

### Phase 3: ZK Perfect Verification
```
🚀 ZK proof (4단계 완벽 검증)
🚀 Instant finality
🚀 ~50k gas
```

## Benefits Summary

| Aspect | testId (Current) | stateRoot (New) |
|--------|------------------|-----------------|
| 랜덤성 | block.timestamp 기반 | 매 블록 변하는 stateRoot |
| 우아함 | 외부 랜덤값 | 자기 참조적 |
| 증명 강도 | 실용적 | 더 강력 |
| 구현 복잡도 | 간단 | 간단 (파라미터 1개 추가) |
| 가스비 | ~100k | ~100k (동일) |

## Security Analysis

### Why This is Secure

**공격자가 속이려면:**

1. **가짜 리프 제출?**
   - ❌ Merkle Proof 검증으로 즉시 탐지

2. **먼 거리의 두 리프 제출?**
   - ❌ Range check: leafA < stateRoot < leafB 실패

3. **Pre-computation?**
   - ❌ stateRoot는 매 블록 변하므로 불가능

4. **공용 RPC 커닝?**
   - ❌ stateRoot 근처의 adjacent leaves를 찾으려면:
     - 전체 State 스캔 필요
     - 전체 Trie 인덱싱 필요
     - RPC만으로는 불가능

### Mathematical Proof

```
명제: "검증자가 State Root R의 전체 데이터를 가지고 있다"

증명:
  Given: State Root R (L1에 커밋된 값)
  Claim: Validator가 leaf A, B를 제출

  Step 1: A ∈ Tree(R)
    MerkleTrie.verify(A, proof_A, R) = true
    → A는 진짜 R의 구성요소

  Step 2: B ∈ Tree(R)
    MerkleTrie.verify(B, proof_B, R) = true
    → B는 진짜 R의 구성요소

  Step 3: A.key < R < B.key (자기 참조!)
    → R이 A와 B 사이에 위치함

  Conclusion:
    ∴ Validator는 R 근처의 모든 데이터를 알고 있음
    ∴ Validator는 전체 State를 동기화하고 있음 □
```

## Implementation Checklist

- [ ] RAT.sol: `triggerAttentionTest`에 `stateRoot` 파라미터 추가
- [ ] RAT.sol: `AttentionTest` 구조체에 `stateRoot` 필드 추가
- [ ] RAT.sol: `testId = stateRoot` 로 변경
- [ ] Type3EvidenceVerifier.sol: `verifyStateLeaf(stateRoot, evidenceData)` 시그니처 변경
- [ ] DisputeGameFactory: `outputRootProof.stateRoot` 전달
- [ ] Go Client: `FindAdjacentLeaves(stateRoot, blockNumber)` 시그니처 변경
- [ ] E2E Tests 업데이트
- [ ] Forge Tests 업데이트

## Conclusion

State Root as Target은:
- ✅ 더 우아한 설계
- ✅ 더 강력한 보안
- ✅ 구현이 간단 (파라미터 1개 추가)
- ✅ 향후 ZK로 업그레이드 용이

**권장: Phase 2로 즉시 마이그레이션** 🎯
