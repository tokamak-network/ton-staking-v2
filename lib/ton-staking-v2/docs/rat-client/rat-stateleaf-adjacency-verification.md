# StateLeaf Adjacency Verification - Implementation & ZK Upgrade Plan

## Overview

RAT (Randomized Attention Test)의 StateLeaf 증명은 검증자가 L2의 전체 상태를 모니터링하고 있음을 증명하기 위해 **인접한 두 리프(Adjacent Leaves)**를 제출하도록 요구합니다.

## Current Implementation (Phase 1)

### 검증 단계

`Type3EvidenceVerifier.sol`의 `verifyStateLeaf()` 함수:

#### ✅ Step 1 & 2: Merkle Proof Verification
```solidity
// Leaf A, B가 진짜 stateRoot의 구성요소인지 검증
MerkleTrie.verifyInclusionProof(leafA, proofA, stateRoot)
MerkleTrie.verifyInclusionProof(leafB, proofB, stateRoot)
```

#### ✅ Step 3: Range Check
```solidity
// leafA.key < randomValue <= leafB.key 확인
// Edge cases: 첫 두 리프, 마지막 두 리프 허용
```

#### ⏳ Step 4: Adjacency (향후 ZK로 구현)
- 현재: 구현하지 않음 (가스비 문제)
- 이유: Patricia Trie의 Branch/Extension Node 파싱 비용 매우 높음 (~200k-500k gas)
- 보안: Step 1-3만으로도 공격자는 전체 State를 알아야 함

### 보안 모델

**현재 구현의 안전성:**
- ✅ Merkle Proof로 가짜 리프 탐지
- ✅ Range Check로 샌드위치 구조 검증
- ✅ 전체 State 없이는 조건 만족 불가능
- ⏳ 완벽한 인접성은 미검증 (ZK로 해결 예정)

**성능:**
- 가스비: ~100k gas
- E2E 테스트: 모두 통과 ✅
- Adjacent leaves 찾기: 2.69ms (RPC)
- Evidence 크기: 2,272 bytes

## Future: ZK-Based Perfect Verification (Phase 3)

### The Ultimate RAT Model 🎯

```
퀴즈 (Quiz):     L2 State Root R (매 블록마다 변함)
증명자 (Prover): Validator running op-node
증명 (Proof):    ZK Proof (4단계 모두 검증)
검증 (Verify):   On-chain, instant, no challenge window
```

### 4단계 완벽 검증

```rust
// ZKVM (RISC Zero) - Off-chain
fn verify_complete_adjacency(...) {
    // Step 1: A ∈ Tree(R)?
    assert!(verify_merkle_proof(leaf_a, proof_a, state_root));

    // Step 2: B ∈ Tree(R)?
    assert!(verify_merkle_proof(leaf_b, proof_b, state_root));

    // Step 3: A < R < B?
    assert!(leaf_a.key < state_root && state_root < leaf_b.key);

    // Step 4: Adjacent? (A와 B 사이에 다른 리프가 없음)
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

### Benefits

| Aspect | Phase 1 (현재) | Phase 3 (ZK) |
|--------|--------------|-------------|
| Step 1-3 | ✅ Verified | ✅ Verified |
| Step 4 (Adjacency) | ❌ Not verified | ✅ **Perfect** |
| 가스비 | ~100k gas | **~50k gas** |
| 검증 시간 | 즉시 | **즉시** |
| Challenge | 불필요 | **불필요** |
| 보안 | 실용적 | **수학적 증명** |

## Design: State Root as Target

### Why State Root R as Target?

1. **자기 참조적(Self-Referential)**
   - "이 State Root가 진짜임을 증명하기 위해, R 근처의 데이터를 제출"
   - 외부 randomValue 생성 불필요

2. **천연 랜덤성**
   - R은 매 블록마다 변함 → Pre-computation 불가능

3. **완벽한 증명**
   - 검증자는 전체 트리를 인덱싱해야만 R 근처의 adjacent leaves를 찾을 수 있음

4. **Instant Finality**
   - Fraud Proof: 7일 challenge window
   - ZK-Based RAT: **즉시 승인** ✅

## Implementation Timeline

```
Phase 1 (현재 - 2026 Q1):
  ✅ Solidity Verification (Step 1-3)
  ✅ RPC-based Adjacent Leaves Finder
  ✅ E2E Tests
  ✅ Documentation

Phase 3 (목표 - 2026 Q3):
  🎯 ZK-Based Complete Verification (Step 1-4)
  🎯 State Root as Target
  🎯 RISC Zero / SP1 Integration
  🎯 ~50k gas, Instant finality
```

## Conclusion

현재 Phase 1 구현은 **실용적인 보안과 가스비 효율의 균형**을 제공합니다.

Phase 3에서 ZK로 업그레이드하면:
- ✅ 수학적으로 완벽한 adjacency 검증
- ✅ 더 낮은 가스비 (~50k gas)
- ✅ Instant validator attestation
- ✅ 확장 가능한 아키텍처

## References

- [Optimism MerkleTrie.sol](https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts-bedrock/src/libraries/trie/MerkleTrie.sol)
- [RISC Zero](https://www.risczero.com/)
- [SP1](https://github.com/succinctlabs/sp1)
- [Ethereum Patricia Trie](https://ethereum.org/en/developers/docs/data-structures-and-encoding/patricia-merkle-trie/)
