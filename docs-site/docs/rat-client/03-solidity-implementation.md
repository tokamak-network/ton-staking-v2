# Solidity Contract Implementation

## 3.1 Type3EvidenceVerifier Library

### 3.1.1 Core Structures

**StateLeafEvidence**: Evidence structure for Adjacent Leaves approach
**OutputRootProof**: Optimism's Output Root format
**DivergenceWitness**: Divergence point proof (perfect adjacency guarantee)

See `src/validator/libraries/Type3EvidenceVerifier.sol` for detailed structure definitions.

### 3.1.2 Verification Logic Steps

1. **Basic Verification**: Field existence, type check
2. **OutputRootProof Verification**: `hash(outputRootProof) == rootClaim`
3. **Range Verification**: `leafA.key < stateRoot < leafB.key`
4. **Merkle Proof Verification**: Verify leafA and leafB actually exist in stateRoot
5. **Divergence Verification**: Prove no other leaf exists between leafA and leafB

## 3.2 RAT Contract Integration

### Evidence Type Dispatcher

- **Evidence Type 0**: FraudProof (batch derivation)
- **Evidence Type 1**: StateLeaf (adjacent leaves) ← **Currently used**

The `_verifyEvidenceWithType()` function calls appropriate verification logic based on rollup type and evidence type.

## 3.3 Gas Optimization Strategy

### Off-chain vs On-chain Division

| Task | Location | Complexity | Notes |
|------|------|--------|------|
| Divergence node calculation | Off-chain | O(n) | Calculated by client |
| IndexA, IndexB extraction | Off-chain | O(1) | Calculated by client |
| Gap pre-verification | Off-chain | O(k) | Don't submit if fails |
| Merkle proof verification | On-chain | O(depth) | Required on-chain work |
| Divergence verification | On-chain | O(k) | k = indexB - indexA |
| OutputRootProof hashing | On-chain | O(1) | Single keccak256 |

### Expected Gas Cost

- Merkle proof verification (x2): ~100,000 gas
- Divergence verification: ~20,000 gas
- Other (range check, hashing): ~30,000 gas
- **Total: ~150,000 gas**

**Achieves 1/3 gas cost compared to traditional fraud proofs**.

### Optimization Techniques

1. **Off-chain Pre-verification**: Don't submit if gap is invalid
2. **Direct Divergence Recommended**: No gap verification needed if indexA, indexB slots directly point to leaves (O(1))
3. **Minimize Storage SLOAD**: Read only necessary data

---

**Next**: [Go Client Implementation](./04-go-client-implementation.md)
