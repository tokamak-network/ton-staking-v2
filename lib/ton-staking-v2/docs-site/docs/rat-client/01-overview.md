# Overview

**Date**: 2026-01-30
**Version**: 4.0
**Target**: Type 3 Rollup (OPTIMISM_BEDROCK_WITH_DISPUTE_GAME)
**Status**: Integrated Specification Document (Implementation + Operations)

## 1.1 What is RAT Client?

RAT (Randomized Attention Test) Client is an off-chain client for validators to **prove they are operating a full node** in **RollupType 3 rollups (Optimism Bedrock with Dispute Game)**.

**Core Purpose**:
- **Liveness Verification**: Prove that validators are directly operating an L2 full archive node
- **Full State Possession Proof**: Prove ability to access the entire state trie
- **No Public RPC Usage**: Self-hosted node with debug API required

**Difference from DisputeGame**:
| Item | RAT Client | DisputeGame (Optimism) |
|------|-----------|------------------------|
| Verification Time | Instant ~ minutes | 7 days |
| Complexity | Low | High |
| Cost | Low (1-2 tx) | High (dozens of tx) |
| Requirements | Full op-geth + debug API | L1 only |
| Verification Content | Liveness (node possession + monitoring) | Correctness (state accuracy) |
| Purpose | Fast path (99% cases) | Final safety (1% disputed cases) |

## 1.2 Core Mechanism: State Leaf Evidence

**State Root as Target** approach:
- Use L2 state root as random value
- Find and submit **two adjacent accounts (leafA, leafB)** in the state trie
- Prove `leafA.key < stateRoot < leafB.key` relationship
- Prove no other leaf exists between the two leaves using **Divergence Witness**

**Why use State Root as Target?**:
```
Traditional approach (predictable):
  - Specify specific address → validator can prepare proof in advance
  - Possible with Public RPC
  - Full node unnecessary

StateRoot approach (unpredictable):
  - StateRoot = 32 bytes random hash
  - Random position in state trie
  - Cannot know in advance which account pair will be selected
  - Requires scanning entire trie with debug_accountRange
  - Self-hosted archive node required!
```

## 1.3 Why Adjacent Leaves?

| Traditional (Single Merkle Proof) | Adjacent Leaves Approach |
|-------------------------------|---------------------|
| ❌ Light node can be deceived | ✅ Full state required |
| ❌ Only query address corresponding to random value | ✅ Full trie scan required |
| ❌ No adjacency guarantee | ✅ Perfect proof with divergence witness |

**Conclusion**: The Adjacent Leaves approach is evidence that can only be submitted when the validator **possesses the entire state trie**.

---

**Next**: [Adjacent Leaves Proof](./02-adjacent-leaves-proof.md)
