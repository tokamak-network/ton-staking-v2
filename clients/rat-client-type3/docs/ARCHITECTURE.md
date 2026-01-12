# RAT Client Type 3 - Architecture

## Overview

RAT (Randomized Attention Test) Client는 TON Staking V3에서 **validator가 L2 rollup node를 직접 보유하고 있는지 검증**하기 위한 시스템입니다. Type 3 rollup (Optimism Bedrock with DisputeGameFactory)의 경우, **debug API를 통한 State Trie 기반 검증**으로 validator의 full op-geth node 운영을 확인합니다.

**핵심 요구사항:**
- debug_accountRange API 사용 → Full node + debug API 필요
- RandomValue로 L2 블록 선택 → 어떤 블록이 선택될지 예측 불가
- debug API는 self-hosted node에서만 활성화 가능

## Design Philosophy

### 목적: Validator Liveness 증명

```
Liveness = Full node 직접 보유 + L2 실시간 모니터링
Correctness = State가 올바른지 검증

RAT Client = Liveness 검증 (20-30분, debug API)
DisputeGame = Correctness 검증 (7일, L1-only)

→ 2-tier 보안 모델
```

**검증 시간 상세:**
- **Production**: ~20-30분
  - Reorg 보호 (64 confirmations): ~12.8분
  - State iteration + proof generation: ~5-15분
- **Test/Devnet**: ~5-10분
  - Reorg 보호 (1-6 confirmations): ~12초-1.2분
  - State iteration + proof generation: ~5-10분

**핵심 설계 원칙:**
1. **빠름**: 20-30분 내 증거 제출 (Production)
2. **단순함**: 복잡한 fraud proof 대신 state trie iteration
3. **실용적**: debug API 사용 (state trie 인덱스 접근)
4. **폴백 가능**: 실패 시 DisputeGame으로 최종 검증

### Trade-offs

| 항목 | RAT Client | DisputeGame (Optimism) |
|------|-----------|------------------------|
| 검증 시간 | 20-30분 (Production) | 7일 |
| 복잡도 | 낮음 | 높음 |
| 비용 | 낮음 (1-2 tx) | 높음 (수십 tx) |
| 요구사항 | Full op-geth + debug API | L1만 사용 |
| 검증 내용 | Liveness (node 보유 + 모니터링) | Correctness (state 정확성) |
| 목적 | Fast path (99% 케이스) | Final safety (1% 의심 케이스) |

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
│  │  - Stores state in Patricia trie (State DB)              │ │
│  │  - Provides debug_accountRange (state iteration)         │ │
│  │  - Provides eth_getProof (Merkle proof generation)       │ │
│  └──────────────────────────────────────────────────────────┘ │
│                              │                                 │
│                              │ RPC Calls                       │
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
│  │  │   RPC Client                     │                  │ │
│  │  │   - Call debug_accountRange      │                  │ │
│  │  │   - Select adjacent leaves       │                  │ │
│  │  │   - Call eth_getProof            │                  │ │
│  │  └──────────────────────────────────┘                  │ │
│  │          │                                              │ │
│  │          ▼                                              │ │
│  │  ┌──────────────────────────────────┐                  │ │
│  │  │   Evidence Generator             │                  │ │
│  │  │   - Assemble StateLeafEvidence   │                  │ │
│  │  │   - Add OutputRootProof          │                  │ │
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
- Reorg 보호 (64 confirmations, ~12.8분)
  - Production: 64 confirmations (안전성)
  - Test/Devnet: 1-6 confirmations (빠른 테스트)

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
- `StateRPC`: RPC 기반 state fetcher (debug_accountRange 사용)
- `AdjacentLeaves`: 인접 leaf 쌍 + Merkle proofs

**debug_accountRange API 사용:**
```go
// debug_accountRange는 state trie의 특정 범위를 페이징으로 조회
// 파라미터: (stateRoot, startKey, maxResults, excludeCode, excludeStorage)
debug_accountRange(stateRoot, startKey, 1000, true, true)

// 반환: {
//   accounts: { "0x123...": { balance, nonce, ... }, ... }
//   next: "0x456..."  // 다음 페이지 시작 키
// }
```

**왜 Full Node + debug API가 필요한가?**
```
일반 RPC (eth_getProof):
  - 특정 주소의 proof만 조회 가능
  - 누구나 외부 RPC로 호출 가능
  - 주소를 알면 증거 미리 준비 가능
  → Full node 필요 없음

debug_accountRange:
  - State trie를 순회하여 adjacent leaves 조회
  - RandomValue로 선택된 L2 블록의 StateRoot 사용
  - 어떤 블록이 선택될지 사전에 예측 불가
  - 대부분의 Public RPC는 debug API를 비활성화
  → Full node 필요
  → debug API 활성화 필요
  → Self-hosted op-geth 필요
```

**RandomValue 활용:**
- RandomValue로 L2 OutputRoot (StateRoot) 선택
- 선택된 StateRoot 기준으로 state trie에서 adjacent leaves 찾기
- Pre-computed proof 불가능
- 항상 최신 state 유지 필요

**RandomValue로 StateRoot를 선택하는 방법:**

```
1. RAT contract가 RandomValue 제공 (예: 0x1a2b3c...)

2. RandomValue를 사용해서 L2 블록 번호 결정
   blockNumber = batchIndex + (RandomValue % N)
   // N은 검증 범위 (예: 최근 100개 블록)

3. 해당 블록의 OutputRoot 조회 (op-node RPC)
   OutputRoot = {
     Version: 0x0,
     StateRoot: 0xabc...,  ← 이것을 사용!
     MessagePasserStorageRoot: 0xdef...,
     LatestBlockHash: 0x123...
   }

4. StateRoot 기준으로 state trie에서 adjacent leaves 찾기
```

**왜 Pre-computed proof가 불가능한가?**

Patricia Merkle Trie의 특성상, **한 계정만 변경되어도 Root까지 전체 경로가 갱신됩니다**:

```
블록 N에서 계정 A의 balance 변경:
  1. 계정 A의 leaf hash 재계산
  2. 계정 A를 포함하는 branch node hash 재계산
  3. 그 상위 branch node hash 재계산
  4. ...Root까지 모든 상위 노드 hash 재계산
  5. State Root: Root_N → Root_N+1 (완전히 변경!)

결과:
  - 계정 B는 전혀 변경되지 않았어도
  - State Root가 Root_N+1로 변경됨
  - 계정 B의 proof는 Root_N+1 기준으로 새로 생성해야 함
  - Root_N 기준 proof는 검증 실패!

→ RandomValue로 선택된 StateRoot의 proof를 생성하려면
→ 해당 블록의 State를 보유해야 함
→ 실시간으로 L2 모니터링 필수!
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

2. [RAT Client] Event 감지 (~12.8분 대기)
   - L1 블록 생성 후 64 confirmations 대기 (Reorg 보호)
   - Production: ~12.8분 (64 confirmations)
   - Test/Devnet: ~12초-1.2분 (1-6 confirmations)
   - Event Monitor가 AttentionTestTriggered 이벤트 수신
   - TestID, RandomValue 추출

3. [RandomValue로 블록 선택]
   - RandomValue를 사용해서 검증할 L2 블록 결정
   - 예: blockNumber = batchIndex + (RandomValue % N)

4. [Op-node] OutputRootProof 조회
   - 선택된 L2 블록의 OutputRootProof 가져오기
   - OutputRootProof.StateRoot 추출

5. [RPC Client] Adjacent Leaves 찾기
   - debug_accountRange로 state trie 조회 (StateRoot 기준)
   - 임의의 adjacent leaf 쌍 선택 (또는 첫 번째 쌍)
   - eth_getProof로 Merkle proof 생성

6. [Evidence Generator] 증거 생성
   - StateLeafEvidence 구조체 생성
   - OutputRootProof 포함
   - ABI 인코딩

7. [Submitter] L1 제출
   - submitEvidence(testID, randomValue, evidence)
   - Gas 관리 및 재시도

8. [L1] On-chain 검증
   - Merkle proof 검증
   - 인접성 확인
   - OutputRootProof 검증
   - 성공 → Validator가 full node를 직접 운영 중임을 확인!
```

### RandomValue와 블록 선택

**RandomValue로 L2 블록 선택:**

```go
// RandomValue를 사용해서 검증할 L2 블록 번호 결정
func SelectBlockNumber(batchIndex uint64, randomValue *big.Int, range uint64) uint64 {
    // 예: 최근 100개 블록 중에서 선택
    offset := randomValue.Mod(randomValue, big.NewInt(int64(range)))
    return batchIndex + offset.Uint64()
}

// 선택된 블록의 OutputRoot 조회
outputRoot := opNodeClient.GetOutputRoot(blockNumber)
stateRoot := outputRoot.StateRoot

// StateRoot 기준으로 adjacent leaves 찾기
// (state trie에서 임의의 인접 쌍 또는 첫 번째 쌍 사용)
```

**왜 RandomValue가 필요한가?**
- 어떤 블록이 선택될지 사전에 예측 불가
- Pre-computed proof 방지
- Validator가 모든 블록의 state를 유지해야 함
- 특정 블록만 선별적으로 모니터링 불가

## Trust Model

### Trustless Components

1. **L1 Data**: Ethereum L1 consensus (완전 trustless)
2. **op-node**: L1 batch data에서 deterministic derivation (trustless)
3. **State Trie**: Cryptographic Merkle Patricia Trie (trustless)
4. **Merkle Proofs**: 암호학적 검증 (trustless)

### Trust Assumptions

1. **op-geth Execution**: Validator가 정직하게 op-geth를 실행한다고 가정
   - **왜 OK?**: RAT은 Liveness 검증 (node 운영 여부)
   - **Correctness**: DisputeGame이 state 정확성 보장

2. **debug API Access**: Validator가 자신의 op-geth에서 debug API 사용
   - **요구사항**: debug API는 self-hosted node만 제공
   - **보안**: Public RPC는 debug API 비활성화
   - **모니터링**: RandomValue로 최신 state 유지 강제
   - **검증**: Merkle proof로 state 일관성 확인

### Security Model

```
RAT Client (Fast):
  - Liveness 검증
    * Full node 직접 보유 (debug API)
    * L2 실시간 모니터링
  - 20-30분 (Production)
  - 대부분(99%)의 케이스

      실패? → 의심스러움
         ↓
DisputeGame (Slow):
  - Correctness 검증
    * State 정확성
    * L1 데이터만 사용
  - 7일
  - 최종 안전성 보장
```

## Design Decisions

### 1. 왜 Adjacent Leaves?

**대안들:**
- ❌ Random address의 eth_getProof: 외부 RPC로 가능 (full node 필요 없음)
- ❌ Full state re-execution: 너무 느림 (수 시간)
- ❌ Challenge-response: 너무 복잡, 여러 round 필요

**Adjacent Leaves + debug_accountRange:**
- ✅ Full node + debug API 필요
- ✅ Public RPC 사용 불가 (대부분 debug API 비활성화)
- ✅ 빠름 (20-30분)
- ✅ 단순함 (1 tx)
- ✅ RandomValue로 caching 방지
- ✅ 예측 불가능 (어떤 계정이 선택될지 사전에 알 수 없음)

### 2. 왜 debug API 의존?

**검증 목적이 다름:**
```
RAT Client = Liveness
  - Full node 직접 보유?
  - L2를 실시간 모니터링?

DisputeGame = Correctness
  - State가 올바른가?
  - L1 데이터와 일치하는가?
```

**Liveness 검증 핵심:**
"Validator가 full op-geth node를 직접 운영하며 L2를 모니터링 중인가?"

**debug API가 필요한 이유:**
```
debug_accountRange:
  - Full node만 활성화 (Archive node도 가능)
  - Public RPC는 대부분 비활성화 (보안/리소스 이유)
  - Infura, Alchemy 등 외부 서비스 불가
  - RandomValue로 L2 블록 선택 → 어떤 블록이 선택될지 예측 불가
  → Self-hosted op-geth 필수!
  → debug API 활성화 필수!
  → 모든 블록의 state 유지 필수!

eth_getProof (일반 API):
  - 어떤 RPC에서든 호출 가능
  - 특정 주소만 조회 (사전 준비 가능)
  - 외부 서비스 의존 가능
  → Full node + debug API 필요 없음
```

**왜 이것으로 충분한가?**
- RAT = Liveness (node 운영 + 모니터링)
- DisputeGame = Correctness (state 정확성)
- debug API 요구 + RandomValue = Liveness 검증

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
  - 20-30분 (Production)

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

RAT Client Type 3는 **Validator Liveness를 검증하는 실용적인 시스템**입니다:

**Liveness란?**
- Full node 직접 보유 (Self-hosted op-geth)
- L2 실시간 모니터링 (최신 state 유지)
- debug API 접근 가능 (Public RPC 불가)

**핵심 특징:**
- Fast (20-30분, Production)
- Simple (adjacent leaves + debug API)
- Practical (RandomValue로 예측 불가능)
- Safe (DisputeGame 폴백)

**설계 철학:**
- Liveness (RAT) vs Correctness (DisputeGame)
- debug API 요구 → Full node + debug 모드 필요
- RandomValue → Pre-computed proof 방지
- 99% 케이스를 빠르게 처리
- 1% 의심 케이스는 DisputeGame으로 해결
- 2-tier 보안 모델로 balance 달성
