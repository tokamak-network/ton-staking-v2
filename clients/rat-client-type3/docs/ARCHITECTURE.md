# RAT Client Type 3 - Architecture

## Overview

RAT (Randomized Attention Test) Client는 TON Staking V3에서 **validator liveness를 검증**하기 위한 시스템입니다. Type 3 rollup (Optimism Bedrock with DisputeGameFactory)의 경우, validator가 실제로 L2 노드를 운영하고 있는지 증명하기 위해 **State Trie 기반 검증**을 수행합니다.

## Design Philosophy

### 목적: Fast Path for Validator Liveness

```
RAT Client = 빠른 검증 (10-30분)
DisputeGame = 최종 안전성 (7일, 완전 trustless)

→ 2-tier 보안 모델
```

**핵심 설계 원칙:**
1. **빠름**: 10-30분 내 증거 제출
2. **단순함**: 복잡한 fraud proof 대신 state trie iteration
3. **실용적**: L2 RPC 활용 허용 (liveness test이므로)
4. **폴백 가능**: 실패 시 DisputeGame으로 최종 검증

### Trade-offs

| 항목 | RAT Client | DisputeGame (Optimism) |
|------|-----------|------------------------|
| 검증 시간 | 10-30분 | 7일 |
| 복잡도 | 낮음 | 높음 |
| 비용 | 낮음 (1-2 tx) | 높음 (수십 tx) |
| L2 의존성 | 있음 (op-geth 필요) | 없음 (L1만 사용) |
| 목적 | Liveness test | Final safety |

## System Architecture

```
┌───────────────────────────────────────────────────────────────┐
│                         L1 (Ethereum)                         │
│                                                               │
│  ┌─────────────────┐              ┌─────────────────┐        │
│  │  RAT Contract   │              │  Batch Inbox    │        │
│  │  - Trigger test │              │  - L2 batches   │        │
│  │  - Verify proof │              └─────────────────┘        │
│  └─────────────────┘                       │                 │
│         ▲                                  │                 │
└─────────┼──────────────────────────────────┼─────────────────┘
          │                                  │
          │ Evidence                         │ Batches
          │                                  ▼
┌─────────┴──────────────────────────────────────────────────────┐
│                    Validator Infrastructure                    │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │                       op-node                            │ │
│  │  - Derives L2 blocks from L1 batches (trustless)         │ │
│  │  - Provides OutputRootProof                              │ │
│  │  - Sends execution payloads to op-geth                   │ │
│  └──────────────────────────────────────────────────────────┘ │
│                              │                                 │
│                              ▼                                 │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │                      op-geth                             │ │
│  │  - Executes L2 blocks                                    │ │
│  │  - Stores state in Patricia trie                         │ │
│  │  - Provides RPC (eth_getProof, debug_accountRange)       │ │
│  │  - State DB: LevelDB/Pebble                              │ │
│  └──────────────────────────────────────────────────────────┘ │
│                              │                                 │
│                              ▼                                 │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │                  RAT Client Type 3                       │ │
│  │                                                          │ │
│  │  ┌────────────────┐  ┌────────────────┐                │ │
│  │  │ Event Monitor  │  │ Op-node Client │                │ │
│  │  │ - Watch L1     │  │ - Get OutputRoot│               │ │
│  │  └────────────────┘  └────────────────┘                │ │
│  │          │                    │                         │ │
│  │          ▼                    ▼                         │ │
│  │  ┌──────────────────────────────────┐                  │ │
│  │  │   State Synchronizer             │                  │ │
│  │  │   - Iterate state trie           │                  │ │
│  │  │   - Find adjacent leaves         │                  │ │
│  │  │   - Generate Merkle proofs       │                  │ │
│  │  └──────────────────────────────────┘                  │ │
│  │          │                                              │ │
│  │          ▼                                              │ │
│  │  ┌──────────────────────────────────┐                  │ │
│  │  │   Evidence Generator             │                  │ │
│  │  │   - StateLeafEvidence            │                  │ │
│  │  │   - OutputRootProof              │                  │ │
│  │  │   - ABI encoding                 │                  │ │
│  │  └──────────────────────────────────┘                  │ │
│  │          │                                              │ │
│  │          ▼                                              │ │
│  │  ┌──────────────────────────────────┐                  │ │
│  │  │   Evidence Submitter             │                  │ │
│  │  │   - Build tx                     │                  │ │
│  │  │   - Sign & submit                │                  │ │
│  │  │   - Gas management               │                  │ │
│  │  └──────────────────────────────────┘                  │ │
│  └──────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. Event Monitor (`pkg/monitor`)

**역할**: L1의 RAT contract를 모니터링하여 AttentionTest 이벤트 감지

```go
type AttentionTestTriggered struct {
    TestID      [32]byte
    SystemConfig common.Address
    BatchIndex  uint64
    RandomValue *big.Int
}
```

**주요 기능:**
- L1 블록 폴링 (12초 간격)
- 이벤트 파싱
- Reorg 보호 (64 confirmations)

### 2. Op-node Client (`pkg/verification`)

**역할**: op-node의 Rollup RPC를 통해 OutputRootProof 조회

```go
type OutputRootProof struct {
    Version                  [32]byte    // Always 0x0
    StateRoot                common.Hash
    MessagePasserStorageRoot common.Hash
    LatestBlockHash          common.Hash
}
```

**핵심**: L2 state root의 진위를 확인하는 구조체

### 3. State Synchronizer (`pkg/l2sync`)

**역할**: L2 state trie를 순회하며 인접한 leaf 쌍을 찾음

**주요 컴포넌트:**
- `StateTrie`: Patricia trie iterator
- `StateRPC`: RPC 기반 state fetcher
- `AdjacentLeaves`: 인접 leaf 쌍 + Merkle proofs

**왜 Adjacent Leaves?**
```
일반 RPC (eth_getProof):
  - 특정 주소의 proof만 조회 가능
  - 누구나 외부 RPC로 호출 가능
  → Validator가 full node를 운영하는지 증명 불가

State Trie Iteration:
  - 전체 state trie를 순회해야 함
  - op-geth의 state DB 직접 접근 필요
  - 외부 RPC로는 불가능 (debug_accountRange는 페이징만)
  → Full node 운영 증명!
```

### 4. Evidence Generator (`pkg/evidence`)

**역할**: StateLeafEvidence 생성 및 ABI 인코딩

```go
type StateLeafEvidence struct {
    // Adjacent leaves
    LeafAKey   common.Hash
    LeafAValue []byte
    LeafAProof [][]byte
    LeafBKey   common.Hash
    LeafBValue []byte
    LeafBProof [][]byte

    // State verification
    StateRoot   common.Hash
    BlockNumber uint64

    // Output root proof
    OutputRootProof OutputRootProof
}
```

**검증 로직 (on-chain):**
1. LeafA Merkle proof → StateRoot 검증
2. LeafB Merkle proof → StateRoot 검증
3. LeafA.key < LeafB.key (인접성 확인)
4. OutputRootProof → rootClaim 검증
5. 모두 통과 → Validator는 full node를 운영 중!

### 5. Evidence Submitter (`pkg/submitter`)

**역할**: 생성된 증거를 L1에 제출

**주요 기능:**
- 트랜잭션 빌드 및 서명
- Gas estimation
- Nonce 관리
- Receipt 대기

## Verification Process

### 전체 흐름

```
1. [L1] RAT contract가 AttentionTest 트리거
   - TestID 생성
   - RandomValue 제공
   - Deadline 설정 (예: 30분)

2. [RAT Client] Event 감지
   - Event Monitor가 AttentionTestTriggered 이벤트 수신
   - TestID, RandomValue 추출

3. [Op-node] OutputRootProof 조회
   - BatchIndex에 해당하는 L2 block 확인
   - OutputRootProof 가져오기 (StateRoot 포함)

4. [State Synchronizer] Adjacent Leaves 찾기
   - op-geth state DB 접근
   - State trie 순회
   - RandomValue를 시드로 특정 leaf 쌍 선택
   - Merkle proof 생성

5. [Evidence Generator] 증거 생성
   - StateLeafEvidence 구조체 생성
   - OutputRootProof 포함
   - ABI 인코딩

6. [Submitter] L1 제출
   - submitEvidence(testID, randomValue, evidence)
   - Gas 관리 및 재시도

7. [L1] On-chain 검증
   - Merkle proof 검증
   - 인접성 확인
   - OutputRootProof 검증
   - 성공 → Validator liveness 확인!
```

### Adjacent Leaves Selection

**RandomValue 활용:**

```go
// RandomValue를 시드로 사용하여 deterministic하게 leaf 선택
func SelectLeafIndex(randomValue *big.Int, totalLeaves int) int {
    return int(randomValue.Mod(randomValue, big.NewInt(int64(totalLeaves-1))).Int64())
}

// 선택된 index의 leaf와 그 다음 leaf를 adjacent pair로 사용
```

**왜 Random Selection?**
- Pre-computed proof 방지
- Validator가 항상 최신 state를 유지해야 함
- Caching 불가능

## Trust Model

### Trustless Components

1. **L1 Data**: Ethereum L1 consensus (완전 trustless)
2. **op-node**: L1 batch data에서 deterministic derivation (trustless)
3. **State Trie**: Cryptographic Merkle Patricia Trie (trustless)
4. **Merkle Proofs**: 암호학적 검증 (trustless)

### Trust Assumptions

1. **op-geth Execution**: Validator가 정직하게 op-geth를 실행한다고 가정
   - **왜 OK?**: RAT은 liveness test이지 correctness test가 아님
   - **최종 검증**: DisputeGame이 correctness 보장

2. **L2 RPC Access**: op-geth RPC가 올바른 데이터 제공
   - **왜 OK?**: Validator 자신의 노드 (self-hosted)
   - **검증**: Merkle proof로 일관성 확인

### Security Model

```
RAT Client (Fast):
  - Validator liveness 검증
  - 10-30분
  - 대부분(99%)의 케이스

      실패? → 의심스러움
         ↓
DisputeGame (Slow):
  - State correctness 검증
  - 7일
  - 최종 안전성 보장
```

## Design Decisions

### 1. 왜 Adjacent Leaves?

**대안들:**
- ❌ Random address의 eth_getProof: 외부 RPC로 가능 (full node 증명 안됨)
- ❌ Full state re-execution: 너무 느림 (수 시간)
- ❌ Challenge-response: 너무 복잡, 여러 round 필요

**Adjacent Leaves:**
- ✅ Full node 증명 (state DB 직접 접근)
- ✅ 빠름 (10-30분)
- ✅ 단순함 (1 tx)
- ✅ RandomValue로 caching 방지

### 2. 왜 L2 RPC 의존?

**목적이 다름:**
```
RAT = Validator liveness (살아있는가?)
DisputeGame = State correctness (정확한가?)
```

RAT에서는 "Validator가 full node를 운영 중인가?"만 확인하면 됨
→ L2 RPC 의존 허용

### 3. 왜 OutputRootProof?

**On-chain 검증 효율성:**
```
Option 1: StateRoot만 제출
  → On-chain에서 rootClaim과 비교할 방법 없음
  → Challenger가 rootClaim을 모름

Option 2: OutputRootProof 제출
  → OutputRootProof.StateRoot를 검증
  → OutputRootProof 전체를 hash → rootClaim과 비교
  → 검증 완료!
```

### 4. 왜 E2E Test?

**신뢰성:**
- State trie iteration은 복잡
- Merkle proof 생성은 까다로움
- ABI encoding은 정확해야 함

→ 실제 op-geth state로 E2E test 필수

## Performance Considerations

### State Trie Iteration

```
문제: State trie 크기
  - Mainnet: ~수백만 accounts
  - Iteration: 수 분 ~ 수십 분

해결: Parallel fetching
  - RPC 기반: debug_accountRange로 페이징
  - Direct DB: 더 빠름 (LevelDB iterator)
```

### Merkle Proof Generation

```
문제: Proof 크기
  - Trie depth: ~64 levels
  - Proof 크기: ~2-4KB per leaf

최적화: Compact encoding
  - RLP 사용
  - 중복 제거 (같은 branch node)
```

## Future Improvements

### 1. Stateless Execution Mode

현재는 state trie iteration에만 집중
향후: L1-only execution 추가 가능
```
Stateless Executor:
  - L1 batch data만 사용
  - State pre-fetching with proofs
  - 완전 trustless
  - 느리지만 L2 RPC 불필요
```

### 2. Multiple Verification Methods

```
Fast Path (현재):
  - Adjacent leaves
  - 10-30분

Medium Path (미래):
  - Stateless execution
  - 1-2시간
  - L2 RPC 불필요

Slow Path (항상):
  - DisputeGame
  - 7일
  - Final safety
```

## Reference Implementation

주요 파일:
- `pkg/client/service_adjacent.go` - Main service
- `pkg/l2sync/state_trie.go` - State trie iterator
- `pkg/evidence/state_leaf_evidence.go` - Evidence structure
- `pkg/submitter/adjacent_submitter.go` - Submission logic
- `test/state_leaf_e2e_test.go` - E2E tests

## Conclusion

RAT Client Type 3는 **실용적인 validator liveness test**입니다:

**핵심:**
- Fast (10-30분)
- Simple (adjacent leaves)
- Practical (L2 RPC 사용)
- Safe (DisputeGame 폴백)

**철학:**
- 완벽한 trustless보다 **빠른 liveness 검증**
- 99% 케이스를 빠르게 처리
- 1% 의심 케이스는 DisputeGame으로 해결
- 2-tier 보안 모델로 balance 달성
