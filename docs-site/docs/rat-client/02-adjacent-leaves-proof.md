# Core Concept: Adjacent Leaves Proof

## 2.1 What is Divergence Witness?

A mechanism that proves **perfect adjacency** by explicitly providing the node where two leaves (leafA, leafB) diverge.

**Components**:
- `divergenceNode`: RLP encoding of the divergence branch node
- `indexA`: Slot index where LeafA is located (0-15)
- `indexB`: Slot index where LeafB is located (0-15)
- `divergenceDepth`: Depth of the divergence point (0=root)

**Verification Process**:
1. **Divergence Node Verification**: Verify that divergenceNode is included in both leafA and leafB proofs
2. **Order Verification**: `indexA < indexB`
3. **Gap Verification**: Verify slots between indexA and indexB are empty → **no other leaf in between**

## 2.2 Gap Verification

**What is a Gap?** Empty **slots** between two adjacent leaves (leafA, leafB) in a Patricia Trie branch node.

A Patricia Trie branch node has 17 slots (0-15: children, 16: value).

**Visual Explanation**:
```
Branch Node (17 slots):
┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬─────┐
│ 0 │ 1 │ 2 │ 3 │ 4 │ 5 │ 6 │ 7 │ 8 │ 9 │ A │ B │ C │ D │ E │ F │value│
└───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴─────┘
  ↑       ↑   ↑   ↑       ↑
leafA   empty empty empty  leafB
(idx=0)   slots           (idx=5)
          ← Gap →

Gap = slots 1, 2, 3, 4 (all must be empty for adjacency)
```

**Verification Logic**:
```
if indexB - indexA == 1:
    → Directly adjacent, no gap (verification unnecessary)

else:
    for i in (indexA+1) to (indexB-1):
        Check if slot is empty (RLP: 0x80)
        If not empty, FAIL → another leaf exists in between
```

**Purpose**: Prove **no other leaf** exists between LeafA and LeafB

**Examples**:
- **Case 1** (directly adjacent): `indexA=3, indexB=4` → No gap ✅
- **Case 2** (gap empty): `indexA=2, indexB=7`, slots 3,4,5,6 all 0x80 → ✅ Valid
- **Case 3** (gap has data): `indexA=2, indexB=7`, slot 4 has another leaf → ❌ Invalid

## 2.3 Binary Search Algorithm

**Purpose**: Find adjacent leaves based on StateRoot value in the state trie

```go
// 1. Determine L2 block number from DisputeGame (already specified)
blockNumber := game.L2BlockNumber()

// 2. Query StateRoot of the block
stateRoot := GetStateRoot(blockNumber)

// 3. Convert StateRoot to big.Int (target value)
targetValue := new(big.Int).SetBytes(stateRoot[:])

// 4. Collect all accounts in state trie with debug_accountRange
// Sorted by keccak256(address)
accounts := GetAccountRange(stateRoot, blockNumber)

// 5. Find position with binary search
targetHash := BigToHash(targetValue)  // = stateRoot
idx := BinarySearch(accounts, targetHash)

// 6. Return adjacent pair
leafA := accounts[idx-1]  // leafA.key < stateRoot
leafB := accounts[idx]    // leafB.key >= stateRoot
```

**Edge Cases**:
- `stateRoot` < all keys: Use first two accounts
- `stateRoot` > all keys: Use last two accounts
- General: `leafA.key < stateRoot <= leafB.key`

---

**Next**: [Solidity Implementation](./03-solidity-implementation.md)
