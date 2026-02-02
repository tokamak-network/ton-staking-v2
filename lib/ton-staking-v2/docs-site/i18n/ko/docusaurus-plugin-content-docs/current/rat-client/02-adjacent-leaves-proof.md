# 핵심 개념: Adjacent Leaves 증명

## 2.1 Divergence Witness란?

두 리프(leafA, leafB)가 분기하는 노드를 명시적으로 제공하여 **완벽한 인접성**을 증명하는 메커니즘입니다.

**구성 요소**:
- `divergenceNode`: 분기점 브랜치 노드의 RLP 인코딩
- `indexA`: LeafA가 위치한 슬롯 인덱스 (0-15)
- `indexB`: LeafB가 위치한 슬롯 인덱스 (0-15)
- `divergenceDepth`: 분기점의 깊이 (0=root)

**검증 과정**:
1. **분기점 노드 검증**: divergenceNode가 leafA와 leafB의 proof에 모두 포함되는지 확인
2. **순서 검증**: `indexA < indexB`
3. **Gap 검증**: indexA와 indexB 사이의 슬롯이 비어있는지 확인 → **중간에 다른 리프 없음**

## 2.2 Gap 검증

**Gap이란?** Patricia Trie 브랜치 노드에서 두 인접한 리프(leafA, leafB) 사이에 있는 **빈 슬롯**들을 의미합니다.

Patricia Trie 브랜치 노드는 17개 슬롯 (0-15: 자식, 16: value)을 가집니다.

**시각적 설명**:
```
Branch Node (17개 슬롯):
┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬─────┐
│ 0 │ 1 │ 2 │ 3 │ 4 │ 5 │ 6 │ 7 │ 8 │ 9 │ A │ B │ C │ D │ E │ F │value│
└───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴─────┘
  ↑       ↑   ↑   ↑       ↑
leafA    빈  빈  빈     leafB
(idx=0)   슬롯           (idx=5)
          ← Gap →

Gap = 슬롯 1, 2, 3, 4 (모두 비어있어야 인접성 성립)
```

**검증 로직**:
```
if indexB - indexA == 1:
    → 바로 인접, Gap 없음 (검증 불필요)

else:
    for i in (indexA+1) to (indexB-1):
        슬롯이 비어있는지 확인 (RLP: 0x80)
        비어있지 않으면 FAIL → 중간에 다른 리프 존재
```

**목적**: LeafA와 LeafB 사이에 **다른 리프가 없음**을 증명

**예시**:
- **케이스 1** (바로 인접): `indexA=3, indexB=4` → Gap 없음 ✅
- **케이스 2** (Gap 비어있음): `indexA=2, indexB=7`, 슬롯 3,4,5,6 모두 0x80 → ✅ 유효
- **케이스 3** (Gap에 데이터): `indexA=2, indexB=7`, 슬롯 4에 다른 리프 → ❌ 무효

## 2.3 Binary Search 알고리즘

**목적**: State trie에서 StateRoot 값 기준으로 adjacent leaves 찾기

```go
// 1. DisputeGame에서 L2 블록 번호 결정 (이미 지정됨)
blockNumber := game.L2BlockNumber()

// 2. 해당 블록의 StateRoot 조회
stateRoot := GetStateRoot(blockNumber)

// 3. StateRoot를 big.Int로 변환 (target value)
targetValue := new(big.Int).SetBytes(stateRoot[:])

// 4. debug_accountRange로 state trie의 모든 accounts 수집
// keccak256(address) 순으로 정렬됨
accounts := GetAccountRange(stateRoot, blockNumber)

// 5. Binary search로 위치 찾기
targetHash := BigToHash(targetValue)  // = stateRoot
idx := BinarySearch(accounts, targetHash)

// 6. 인접한 쌍 반환
leafA := accounts[idx-1]  // leafA.key < stateRoot
leafB := accounts[idx]    // leafB.key >= stateRoot
```

**엣지 케이스**:
- `stateRoot` < 모든 키: 첫 두 계정 사용
- `stateRoot` > 모든 키: 마지막 두 계정 사용
- 일반: `leafA.key < stateRoot <= leafB.key`

---

**다음**: [Solidity 계약 구현](./03-solidity-implementation.md)
