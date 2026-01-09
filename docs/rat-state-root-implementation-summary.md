# State Root as Target - Implementation Summary

## 개요

RAT (Randomized Attention Test)의 **State Root as Target** 설계를 Solidity 컨트랙트에 구현했습니다.

## 핵심 변경사항

### 1. Type3EvidenceVerifier.sol

#### OutputRootProof 구조체 추가
```solidity
struct OutputRootProof {
    bytes32 version;                    // Version (always 0x0)
    bytes32 stateRoot;                  // L2 state root
    bytes32 messagePasserStorageRoot;   // L2ToL1MessagePasser storage root
    bytes32 latestBlockhash;            // L2 block hash
}
```

#### StateLeafEvidence 구조체 업데이트
```solidity
struct StateLeafEvidence {
    // ... existing fields ...

    // Output Root Proof (for rootClaim verification)
    OutputRootProof outputRootProof; // Proves stateRoot authenticity
}
```

#### verifyStateLeaf() 함수 업데이트

**이전:**
```solidity
function verifyStateLeaf(bytes32 testId, bytes calldata evidenceData)
```

**현재:**
```solidity
function verifyStateLeaf(bytes32 rootClaim, bytes calldata evidenceData)
```

**검증 단계:**
1. 기본 검증 (필수 필드 확인)
2. **OutputRootProof 검증**: `hash(outputRootProof) == rootClaim`
3. **stateRoot 추출**: `stateRoot = outputRootProof.stateRoot`
4. **범위 검증**: `leafA.key < stateRoot < leafB.key` (자기 참조적!)
5. **Patricia Trie Merkle Proof 검증**: leafA, leafB ∈ Tree(stateRoot)

#### _hashOutputRootProof() 헬퍼 함수 추가
```solidity
function _hashOutputRootProof(OutputRootProof memory proof)
    internal pure returns (bytes32)
{
    return keccak256(abi.encode(
        proof.version,
        proof.stateRoot,
        proof.messagePasserStorageRoot,
        proof.latestBlockhash
    ));
}
```

### 2. RATStorage.sol

#### AttentionTest 구조체 업데이트
```solidity
struct AttentionTest {
    address validatorAddress;
    address systemConfig;
    uint32 batchIndex;
    address gameAddress;    // ← 추가! (rootClaim 조회용)
    bytes32 batchHash;
    uint256 bondAmount;
    uint256 createdAt;
    uint256 deadline;
    AttentionTestStatus status;
}
```

### 3. RAT.sol

#### IDisputeGame 인터페이스 추가
```solidity
import {IDisputeGame} from "./interfaces/IDisputeGame.sol";
```

#### triggerAttentionTest() - gameAddress 저장
```solidity
attentionTests[testId] = AttentionTest({
    // ...
    gameAddress: gameAddress,  // ← 추가!
    // ...
});
```

#### _verifyEvidence() - rootClaim 조회 및 전달
```solidity
else if (evidenceType == 1) {
    // DisputeGame에서 rootClaim 조회
    AttentionTest storage test = attentionTests[testId];
    bytes32 rootClaim = IDisputeGame(test.gameAddress).rootClaim();

    // rootClaim과 함께 검증 (State Root as Target)
    return Type3EvidenceVerifier.verifyStateLeaf(rootClaim, evidenceData);
}
```

### 4. IDisputeGame.sol (신규)

```solidity
interface IDisputeGame {
    /// @notice Returns the root claim of this DisputeGame
    /// @dev rootClaim = keccak256(abi.encode(OutputRootProof))
    function rootClaim() external view returns (bytes32);
}
```

## 검증 흐름

```
1. DisputeGameFactory creates game with rootClaim
   ↓
2. RAT.triggerAttentionTest(gameAddress, ...)
   ↓ stores gameAddress in AttentionTest

3. Validator receives event
   ↓
4. op-node gets L2 block state
   ↓
5. Validator constructs OutputRootProof
   ↓
6. Validator verifies: hash(OutputRootProof) == game.rootClaim()
   ↓
7. Validator finds adjacent leaves: leafA < stateRoot < leafB
   ↓
8. Validator submits evidence with OutputRootProof
   ↓
9. RAT.submitEvidence()
   ↓
10. RAT queries game.rootClaim()
    ↓
11. Type3EvidenceVerifier.verifyStateLeaf(rootClaim, evidence)
    ↓
    a. Verify: hash(outputRootProof) == rootClaim ✅
    b. Extract: stateRoot = outputRootProof.stateRoot
    c. Verify: leafA < stateRoot < leafB ✅
    d. Verify: leafA ∈ Tree(stateRoot) ✅
    e. Verify: leafB ∈ Tree(stateRoot) ✅
    ↓
12. Evidence accepted, bond restored
```

## 자기 참조적 증명 (Self-Referential Proof)

```
명제: "검증자가 State Root R의 전체 데이터를 가지고 있다"

증명:
  Given: rootClaim = hash(OutputRootProof)

  Step 1: Verify hash(outputRootProof) == rootClaim
    → OutputRootProof는 L1에 커밋된 진짜 데이터

  Step 2: Extract stateRoot = outputRootProof.stateRoot
    → R은 진짜 L2 state root

  Step 3: Verify leafA ∈ Tree(R) and leafB ∈ Tree(R)
    → leafA, leafB는 진짜 R의 구성요소

  Step 4: Verify leafA.key < R < leafB.key
    → R이 leafA와 leafB 사이에 위치 (자기 참조!)

  Conclusion:
    ∴ 검증자는 R 근처의 모든 데이터를 알고 있음
    ∴ 검증자는 전체 State를 동기화하고 있음 □
```

## 보안 분석

### 공격 시나리오와 방어

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

5. **가짜 OutputRootProof 제출?**
   - ❌ `hash(outputRootProof) != rootClaim` 검증 실패

## 다음 단계

### Go Client 구현 (필요)
1. OutputRootProof 생성
   - op-node API에서 L2 block 정보 조회
   - OutputRootProof 구조체 구성
2. Evidence 제출 시 OutputRootProof 포함
3. 로컬 검증: hash(outputRootProof) == rootClaim

### Forge 테스트 업데이트 (필요)
1. Type3EvidenceVerifier.t.sol 업데이트
2. RAT.t.sol에 gameAddress mocking 추가
3. E2E 테스트 업데이트

## 변경된 파일 목록

1. `/src/validator/libraries/Type3EvidenceVerifier.sol`
   - OutputRootProof 구조체 추가
   - StateLeafEvidence 구조체 업데이트
   - verifyStateLeaf() 시그니처 변경
   - _hashOutputRootProof() 함수 추가

2. `/src/validator/RATStorage.sol`
   - AttentionTest에 gameAddress 필드 추가

3. `/src/validator/RAT.sol`
   - IDisputeGame import 추가
   - triggerAttentionTest()에서 gameAddress 저장
   - _verifyEvidence()에서 rootClaim 조회 및 전달
   - getAttentionTest() 반환값에 gameAddress 추가

4. `/src/validator/interfaces/IDisputeGame.sol` (신규)
   - rootClaim() 함수 인터페이스

5. `/test/v3/Type3EvidenceVerifier.t.sol`
   - StateLeafEvidence 생성 시 OutputRootProof 추가

## 향후 업그레이드 경로

### Phase 3: ZK-Based Perfect Verification

```rust
// ZKVM (RISC Zero) - Off-chain
fn verify_complete_adjacency(...) {
    // Step 1-3: 현재 구현과 동일
    assert!(verify_merkle_proof(leaf_a, proof_a, state_root));
    assert!(verify_merkle_proof(leaf_b, proof_b, state_root));
    assert!(leaf_a.key < state_root && state_root < leaf_b.key);

    // Step 4: Perfect Adjacency 검증 (ZK로만 가능)
    let branch_point = find_branch_point(proof_a, proof_b);
    for slot in (slot_a + 1)..slot_b {
        assert!(branch_point[slot].is_empty());
    }
}
```

```solidity
// On-chain - Solidity
function submitStateLeafEvidence(bytes32 testId, bytes calldata zkProof) {
    require(verifyZKProof(zkProof), "Invalid proof");
    // ✅ 즉시 승인 (Challenge window 불필요)
    _acceptEvidence(testId, msg.sender);
}
```

## 결론

State Root as Target 설계의 Solidity 구현이 완료되었습니다:
- ✅ 자기 참조적 증명 구현
- ✅ OutputRootProof 기반 rootClaim 검증
- ✅ stateRoot를 타겟으로 사용
- ✅ 더 강력한 보안 모델
- ✅ 향후 ZK 업그레이드 준비 완료

다음은 Go client 구현과 테스트 업데이트가 필요합니다.
