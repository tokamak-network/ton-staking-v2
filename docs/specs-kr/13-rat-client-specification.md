# 13. RAT Client 구현 및 운영 스펙

**작성일**: 2026-01-30
**버전**: 4.0
**대상**: Type 3 롤업 (OPTIMISM_BEDROCK_WITH_DISPUTE_GAME)
**상태**: 통합 스펙 문서 (구현 + 운영)

## 목차

1. [개요](#1-개요)
2. [핵심 개념: Adjacent Leaves 증명](#2-핵심-개념-adjacent-leaves-증명)
3. [Solidity 계약 구현](#3-solidity-계약-구현)
4. [Go Client 구현](#4-go-client-구현)
5. [OutputRootProof 검증](#5-outputrootproof-검증)
6. [배포 및 운영](#6-배포-및-운영)

---

## 1. 개요

### 1.1 RAT Client란?

RAT (Randomized Attention Test) Client는 **RollupType 3 롤업(Optimism Bedrock with Dispute Game)** 에서 검증자가 **full node를 운영하고 있음을 증명**하기 위한 오프체인 클라이언트입니다.

**핵심 목적**:
- **Liveness 검증**: 검증자가 L2 full archive node를 직접 운영 중임을 증명
- **Full State 보유 증명**: 전체 state trie 접근 능력 증명
- **Public RPC 사용 불가**: Self-hosted node with debug API 필수

**DisputeGame과의 차이**:
| 항목 | RAT Client | DisputeGame (Optimism) |
|------|-----------|------------------------|
| 검증 시간 | 즉시 ~ 수분 | 7일 |
| 복잡도 | 낮음 | 높음 |
| 비용 | 낮음 (1-2 tx) | 높음 (수십 tx) |
| 요구사항 | Full op-geth + debug API | L1만 사용 |
| 검증 내용 | Liveness (node 보유 + 모니터링) | Correctness (state 정확성) |
| 목적 | Fast path (99% 케이스) | Final safety (1% 의심 케이스) |

### 1.2 핵심 메커니즘: State Leaf Evidence

**State Root as Target** 방식:
- L2 state root를 랜덤값으로 사용
- State trie에서 **인접한 두 개의 account (leafA, leafB)** 를 찾아서 제출
- `leafA.key < stateRoot < leafB.key` 관계를 증명
- 두 리프 사이에 다른 리프가 없음을 **Divergence Witness**로 증명

**왜 State Root를 Target으로 사용하는가?**:
```
일반적인 방식 (예측 가능):
  - 특정 주소 지정 → validator가 미리 proof 준비 가능
  - Public RPC로도 가능
  - Full node 불필요

StateRoot 방식 (예측 불가능):
  - StateRoot = 32 bytes random hash
  - State trie에서 임의의 위치
  - 어떤 계정 쌍이 선택될지 사전에 알 수 없음
  - debug_accountRange로 전체 trie 순회 필요
  - Self-hosted archive node 필수!
```

### 1.3 왜 Adjacent Leaves인가?

| 기존 방식 (Single Merkle Proof) | Adjacent Leaves 방식 |
|-------------------------------|---------------------|
| ❌ Light node도 속일 수 있음 | ✅ Full state 필요 |
| ❌ 랜덤값에 해당하는 주소만 조회 | ✅ Trie 전체 스캔 필요 |
| ❌ 인접성 보장 없음 | ✅ Divergence witness로 완벽 증명 |

**결론**: Adjacent Leaves 방식은 검증자가 **전체 state trie를 보유**하고 있어야만 제출 가능한 증거입니다.

---

## 2. 핵심 개념: Adjacent Leaves 증명

### 2.1 Divergence Witness란?

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

### 2.2 Gap 검증

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

### 2.3 Binary Search 알고리즘

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

## 3. Solidity 계약 구현

### 3.1 Type3EvidenceVerifier 라이브러리

#### 3.1.1 핵심 구조체

**StateLeafEvidence**: Adjacent Leaves 방식의 증거 구조
**OutputRootProof**: Optimism의 Output Root 포맷
**DivergenceWitness**: 분기점 노드 증명 (인접성 완벽 보장)

자세한 구조체 정의는 `src/validator/libraries/Type3EvidenceVerifier.sol` 참고.

#### 3.1.2 검증 로직 단계

1. **기본 검증**: 필드 존재성, 타입 체크
2. **OutputRootProof 검증**: `hash(outputRootProof) == rootClaim`
3. **범위 검증**: `leafA.key < stateRoot < leafB.key`
4. **Merkle Proof 검증**: leafA와 leafB가 stateRoot에 실제로 존재
5. **Divergence 검증**: leafA와 leafB 사이에 다른 리프가 없음을 증명

### 3.2 RAT 계약 통합

#### 증거 타입별 디스패처

- **Evidence Type 0**: FraudProof (batch derivation)
- **Evidence Type 1**: StateLeaf (adjacent leaves) ← **현재 사용**

`_verifyEvidenceWithType()` 함수에서 롤업 타입과 증거 타입에 따라 적절한 검증 로직 호출.

### 3.3 가스 최적화 전략

#### 오프체인 vs 온체인 분업

| 작업 | 위치 | 복잡도 | 비고 |
|------|------|--------|------|
| Divergence node 계산 | 오프체인 | O(n) | 클라이언트가 계산 |
| IndexA, IndexB 추출 | 오프체인 | O(1) | 클라이언트가 계산 |
| Gap 사전 검증 | 오프체인 | O(k) | 실패 시 제출하지 않음 |
| Merkle proof 검증 | 온체인 | O(depth) | 필수 온체인 작업 |
| Divergence 검증 | 온체인 | O(k) | k = indexB - indexA |
| OutputRootProof 해싱 | 온체인 | O(1) | keccak256 1회 |

#### 예상 가스 비용

- Merkle proof 검증 (x2): ~100,000 gas
- Divergence 검증: ~20,000 gas
- 기타 (range check, hashing): ~30,000 gas
- **Total: ~150,000 gas**

**기존 fraud proof 대비 1/3 수준의 가스 비용** 달성.

#### 최적화 기법

1. **오프체인 사전 검증**: Gap이 유효하지 않으면 제출하지 않음
2. **Direct Divergence 권장**: indexA, indexB 슬롯이 직접 leaf로 가면 Gap 검증 불필요 (O(1))
3. **Storage SLOAD 최소화**: 필요한 데이터만 읽기

---

## 4. Go Client 구현

### 4.1 패키지 구조

```
clients/rat-client-type3/
├── cmd/main.go                 # 엔트리포인트
├── pkg/
│   ├── monitor/                # L1 이벤트 모니터링
│   ├── l2sync/                 # L2 상태 동기화 ⭐ (Debug RPC)
│   ├── evidence/               # 증거 생성 (StateLeafEvidence)
│   ├── verification/           # OutputRootProof 검증 (선택)
│   ├── submitter/              # 증거 제출 (L1 트랜잭션)
│   └── client/                 # 메인 서비스
│       └── service_adjacent.go # ⭐ 실제 프로덕션 사용
└── test/                       # E2E 테스트
    └── state_leaf_rpc_e2e_test.go  ⭐ 추천
```

### 4.2 핵심 패키지

#### monitor - L1 이벤트 감지
- RAT 계약에서 `AttentionTestTriggered` 이벤트 모니터링
- 본인 검증자 주소 필터링
- L1 confirmations 적용

#### l2sync - Adjacent Leaves 찾기 ⭐
- **Debug RPC 모드** (✅ 프로덕션): `debug_accountRange` + `eth_getProof`
- Divergence node 계산
- Gap 사전 검증

**핵심 파일**: `pkg/l2sync/state_rpc.go`

#### evidence - 증거 생성
- StateLeafEvidence 구조체 생성
- OutputRootProof 추가
- DivergenceWitness 계산
- ABI 인코딩 (Solidity 호환)

#### verification - OutputRootProof 검증
- **방법 1**: L2 RPC로 직접 계산 (`eth_getProof`)
- **방법 2**: OpNode Rollup RPC 사용 (`optimism_outputAtBlock`)
- State root 무결성 확인

#### submitter - 증거 제출
- RAT 계약 `submitEvidence()` 호출
- 가스 가격 최적화
- 재시도 로직

### 4.3 Debug RPC 기반 증거 생성 플로우

```
[RAT Test 트리거]
       ↓
[EventMonitor 감지]
       ↓
[L2 Block 결정 (DisputeGame 조회)]
       ↓
[StateRoot 조회 (L2 RPC)]
       ↓
[(선택) OutputRootProof 검증]
├─ L2 RPC: eth_getProof로 계산
└─ 또는 OpNode: optimism_outputAtBlock
       ↓
┌──────────────────────────────────┐
│ l2sync.FindAdjacentLeavesViaRPC  │ ⭐ 메인 로직
├──────────────────────────────────┤
│ 1. debug_accountRange 호출       │
│    → 전체 accounts 조회          │
│ 2. Binary search                 │
│    → StateRoot 기준 위치 찾기    │
│ 3. Adjacent addresses 선택       │
│    → leafA.key < stateRoot <= leafB.key │
│ 4. eth_getProof 호출 (x2)        │
│    → Merkle proof 가져오기       │
│ 5. Account RLP 인코딩            │
│ 6. 로컬 검증                     │
└──────────────────────────────────┘
       ↓
┌──────────────────────────────────┐
│ l2sync.FindDivergenceNode        │
├──────────────────────────────────┤
│ 1. 두 proof의 공통 조상 찾기     │
│ 2. IndexA, IndexB 추출           │
│ 3. Direct divergence 확인        │
│ 4. Gap 사전 검증                 │
└──────────────────────────────────┘
       ↓
┌──────────────────────────────────┐
│ evidence.NewStateLeafEvidence    │
├──────────────────────────────────┤
│ 1. Key 순서 검증                 │
│ 2. OutputRootProof 추가          │
│ 3. DivergenceWitness 추가        │
│ 4. ABI 인코딩                    │
└──────────────────────────────────┘
       ↓
┌──────────────────────────────────┐
│ submitter.SubmitEvidence         │
├──────────────────────────────────┤
│ RAT.submitEvidence() 호출        │
└──────────────────────────────────┘

⭐ OutputRootProof가 올바른 경우 증거 생성 및 제출
```

### 4.4 핵심 함수: FindAdjacentLeavesViaRPC()

**Debug RPC 모드** (✅ **프로덕션 사용 중** - Geth v1.13+ PBSS 호환):

```go
// 1. debug_accountRange로 전체 accounts 조회
result, err := client.CallContext(ctx, &result, "debug_accountRange",
    blockHex,                    // 블록 번호
    "0x0000...0000",            // 시작 주소 (전체 조회)
    10000000,                    // 최대 개수 (충분히 크게)
    false, false, false)

// 2. Sorted accounts (keccak256(address) 순으로 정렬됨)
sorted := SortAccountsByKey(result.Accounts)

// 3. Binary search로 StateRoot 기준 위치 찾기
randomHash := common.BigToHash(new(big.Int).SetBytes(stateRoot[:]))
idx := BinarySearch(sorted, randomHash)

// 4. Adjacent leaves 선택
if idx == 0 {
    // StateRoot < 모든 키 → 첫 두 계정 사용
    accountA, accountB = sorted[0], sorted[1]
} else if idx >= len(sorted) {
    // StateRoot > 모든 키 → 마지막 두 계정 사용
    accountA, accountB = sorted[len-2], sorted[len-1]
} else {
    // 일반 케이스: leafA.key < stateRoot <= leafB.key
    accountA, accountB = sorted[idx-1], sorted[idx]
}

// 5. eth_getProof로 Merkle proofs 가져오기
proofA, accountDataA := client.CallContext("eth_getProof", accountA.Address, [], blockHex)
proofB, accountDataB := client.CallContext("eth_getProof", accountB.Address, [], blockHex)

// 6. Account RLP 인코딩
leafAValue := RLP(accountDataA.Nonce, accountDataA.Balance,
                  accountDataA.StorageHash, accountDataA.CodeHash)
leafBValue := RLP(accountDataB.Nonce, accountDataB.Balance,
                  accountDataB.StorageHash, accountDataB.CodeHash)

// 7. 로컬 검증
VerifyStateProof(stateRoot, leafA.Key, leafA.Value, proofA)
VerifyStateProof(stateRoot, leafB.Key, leafB.Value, proofB)
```

**장점**:
- ✅ Geth v1.13+ **PBSS (Path-Based State Storage) 호환**
- ✅ StateDB 직접 접근 불필요
- ✅ 매우 빠름
- ✅ 가벼운 리소스
- ✅ **프로덕션 환경 사용 중**

**요구사항**:
- L2 RPC 노드 (op-geth, archive mode)
- `debug_accountRange` API 활성화 ⭐
- `eth_getProof` API 활성화

**⚠️ 주의**: Geth v1.13+에서는 PBSS로 인해 StateDB 직접 접근이 제한됩니다. **Debug RPC 모드를 사용하세요.**

### 4.5 핵심 함수: FindDivergenceNode()

**목적**: 오프체인에서 분기점 계산 → 온체인 가스 절약

```go
// 1. 두 proof를 앞에서부터 비교
for i := 0; i < minLen; i++ {
    if hash(proofA[i]) != hash(proofB[i]) {
        divergenceNode = proofA[i-1]  // 직전 노드가 분기점
        break
    }
}

// 2. 분기점 노드에서 indexA, indexB 추출
indexA, indexB = FindChildIndices(divergenceNode, leafAKey, leafBKey, depth)

// 3. Direct divergence 확인 (Best Practice)
isDirectDivergence := VerifyDirectDivergence(divergenceNode, indexA, indexB)

// 4. Gap 사전 검증 (온체인 실패 방지)
if indexB - indexA > 1 {
    gapValid := VerifyGapBetweenIndices(divergenceNode, indexA, indexB)
    if !gapValid {
        return error("Gap에 데이터 있음 - 증거 제출 중단")
        // 가스 낭비 방지! 온체인 검증 실패 예방
    }
}
```

---

## 5. OutputRootProof 검증

### 5.1 OutputRootProof란?

Optimism의 Output Root는 L2 state를 L1에 커밋하는 해시값입니다:

```
OutputRoot = keccak256(
    version                  ||  // 0x0000...0000 (32 bytes)
    stateRoot                ||  // L2 state root
    messagePasserStorageRoot ||  // L2ToL1MessagePasser storage root
    blockHash                    // L2 block hash
)
```

**OutputRootProof 구조체**:
```solidity
struct OutputRootProof {
    bytes32 version;                      // Always 0x0
    bytes32 stateRoot;                    // L2 state root
    bytes32 messagePasserStorageRoot;     // Withdrawal storage root
    bytes32 latestBlockHash;              // L2 block hash
}
```

### 5.2 방법 1: L2 RPC로 OutputRootProof 생성 (✅ 기본값)

**장점**:
- OpNode 불필요
- 빠름 (추가 인프라 없음)
- L2 RPC만으로 완결

**구현** (`service_adjacent.go:431-490`):
```go
// 1. L2 block header 조회
header, err := l2Client.HeaderByNumber(ctx, blockNumber)
stateRoot := header.Root
blockHash := header.Hash()

// 2. L2ToL1MessagePasser predeploy address
messagePasserAddr := common.HexToAddress("0x4200000000000000000000000000000000000016")

// 3. eth_getProof로 MessagePasser storage root 조회
proofResult, err := l2Client.CallContext(ctx, &result, "eth_getProof",
    messagePasserAddr, []string{}, blockHex)
messagePasserStorageRoot := proofResult.StorageHash

// 4. OutputRootProof 생성
outputRootProof := &OutputRootProof{
    Version:                  [32]byte{}, // 0x0
    StateRoot:                stateRoot,
    MessagePasserStorageRoot: messagePasserStorageRoot,
    LatestBlockHash:          blockHash,
}

// 5. OutputRoot 계산 및 검증
computedOutputRoot := keccak256(
    outputRootProof.Version,
    outputRootProof.StateRoot,
    outputRootProof.MessagePasserStorageRoot,
    outputRootProof.LatestBlockHash,
)

if computedOutputRoot != expectedOutputRoot {
    return error("OutputRoot mismatch")
}
```

**요구사항**:
- L2 geth (archive mode)
- `eth_getProof` API
- L2ToL1MessagePasser predeploy contract

**Trustless 수준**: Self-hosted L2 RPC 신뢰 필요 (운영자가 직접 관리하므로 실질적으로 trustless)

### 5.3 방법 2: OpNode로 OutputRootProof 조회

**장점**:
- L1에서 trustless 유도
- L2 state를 L1 데이터로부터 재계산
- 100% trustless 검증

**구현** (`service_adjacent.go:374-390`):
```go
// op-node가 설정되어 있으면 사용
if s.opNodeClient != nil {
    opNodeProof, err := s.opNodeClient.GetOutputRootProof(ctx, blockNumber)
    if err != nil {
        log.Printf("Failed to get OutputRootProof from op-node: %v", err)
        // Fallback to L2 RPC calculation
    } else {
        // op-node에서 가져온 OutputRootProof 사용
        ev.OutputRootProof = *opNodeProof
    }
}
```

**요구사항**:
- op-node 실행 중
- Rollup RPC 접근 (`optimism_outputAtBlock`)
- L1 RPC 접근

**Trustless 수준**: 100% (L1 데이터만 사용)

**참고**: 코드에서 `opNodeClient == nil`이면 에러 무시하고 L2 RPC로 계속 진행

### 5.4 OutputRootProof 검증의 역할

**질문**: OutputRootProof 검증이 실패하면?

**답변**:
- 현재 구현: 에러 반환하고 증거 제출 중단 (`service_adjacent.go:324`)
- OpNode 사용 불가 시: L2 RPC로 OutputRootProof 생성하고 계속 진행

**목적**:
1. StateRoot 무결성 확인
2. 올바른 L2 블록 번호 확인
3. DisputeGame rootClaim과 비교

**중요**: **OutputRootProof가 올바를 때** Adjacent Leaves 증거를 생성하고 제출
- RAT는 Liveness 검증 (Full node 운영 증명)
- Validator가 올바른 state를 보유하고 있음을 증명
- DisputeGame의 rootClaim과 계산된 OutputRoot가 일치해야 증거 제출

---

## 6. 배포 및 운영

### 6.1 필수 인프라

#### 전체 구조

**Validator는 Follower Mode L2 노드를 운영해야 합니다**:

```
┌─────────────────────────────────────────────────────────────┐
│                    Validator Infrastructure                 │
│                                                             │
│  ┌────────────────────────────────────────────────────┐   │
│  │  L1 RPC (Ethereum)                                 │   │
│  │  - RAT contract 이벤트 모니터링                    │   │
│  │  - 증거 제출 트랜잭션 전송                         │   │
│  │  - Batch data 조회 (BatchInbox)                   │   │
│  └────────────────────────────────────────────────────┘   │
│                          ▲                                  │
│                          │ L1 Data                          │
│                          ▼                                  │
│  ┌────────────────────────────────────────────────────┐   │
│  │  op-node (Follower Mode) ⭐ 권장                   │   │
│  │  - L1 batch data 읽기                              │   │
│  │  - L2 블록 재구성 (trustless derivation)          │   │
│  │  - Execution payload 생성                          │   │
│  │  - OutputRootProof 제공                            │   │
│  └────────────────────────────────────────────────────┘   │
│                          │                                  │
│                          │ Engine API (JWT 인증)            │
│                          ▼                                  │
│  ┌────────────────────────────────────────────────────┐   │
│  │  op-geth (Archive + Debug) ⭐ 필수                 │   │
│  │  - Engine API로 op-node에서 블록 수신             │   │
│  │  - Archive mode (--gcmode=archive)                 │   │
│  │  - Debug API (debug_accountRange, eth_getProof)   │   │
│  │  - L2 state 저장 (Patricia Trie)                  │   │
│  └────────────────────────────────────────────────────┘   │
│             ▲                          ▲                    │
│             │                          │                    │
│    Engine API (8551)          Debug RPC (8545)             │
│             │                          │                    │
│  ┌────────────────────────────────────────────────────┐   │
│  │  RAT Client Type 3                                 │   │
│  │  - L1 이벤트 감지                                  │   │
│  │  - debug_accountRange로 Adjacent leaves 찾기      │   │
│  │  - eth_getProof로 Merkle proofs 생성              │   │
│  │  - OutputRootProof 검증 (op-node 또는 L2 RPC)    │   │
│  │  - 증거 생성 및 제출                               │   │
│  └────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

**핵심 포인트**:
1. **Validator = Follower Mode Challenger 노드 운영자**
2. **op-node**: L1 batch data에서 L2를 재구성 (100% trustless)
3. **op-geth**: op-node가 보낸 블록을 실행하고 state 저장
4. **RAT Client**: op-geth의 debug API 사용

#### 핵심 원칙

**✅ Validator = Follower Mode L2 노드 운영**:
- Validator는 **Challenger의 Follower Mode**를 운영해야 함
- L1 batch data를 읽어서 L2를 **trustless하게 재구성**
- op-node + op-geth가 Engine API로 연결됨
- **이것이 "Full node 운영 증명"의 핵심!**

**✅ op-node (Follower Mode) - 필수**:
- L1에서 batch data 읽기 (100% trustless)
- L2 블록 재구성 (Derivation Pipeline)
- Engine API로 op-geth에 블록 전달
- RAT Client에 OutputRootProof 제공

**✅ op-geth (Archive + Debug) - 필수**:
- Engine API로 op-node에서 블록 수신
- Archive mode로 모든 과거 state 보존 (`--gcmode=archive`)
- Debug API 활성화 (`debug_accountRange`, `eth_getProof`)
- RAT Client가 debug RPC로 Adjacent leaves 찾기

**❌ Public L2 RPC 사용 불가**:
- debug API 없음 → Adjacent leaves 찾기 불가능
- Trustless derivation 없음
- Infura, Alchemy 등 외부 provider 사용 불가
- **Validator는 반드시 자체 L2 노드 운영**

### 6.2 왜 Archive Mode가 필수인가?

**RAT 챌린지의 특성:**
```
Time T: DisputeGame 생성 (L2 block #12345)
        - State root = 0xabc...
        - RAT triggered

Time T+1h: Validator must submit evidence
           - Must prove possession of state at block #12345
           - ❌ Full node may have pruned block #12345's state!
           - ✅ Archive node always has it
```

**Full Node의 문제점:**
- Default `--gcmode=full`: 최근 128 블록만 유지
- L2 블록 생성: 매 ~2초
- evidenceSubmissionPeriod: 1시간
- **128 블록 = 약 4분** → 1시간 전 state는 이미 삭제됨!

**Archive Node (필수):**
- 모든 과거 state 보존
- 디스크: ~10+ TB
- **어떤 과거 블록이라도 state 접근 가능**

**Patricia Merkle Trie 특성:**
```
계정 A의 balance 변경 (블록 N → N+1):
  1. 계정 A의 leaf hash 재계산
  2. 상위 branch node hash 재계산
  3. ... Root까지 모든 경로 재계산
  4. State Root: 완전히 변경!

결과:
  - 계정 B는 변경 없어도
  - State Root 변경 → 모든 proof 재생성 필요
  - Root_N 기준 proof는 검증 실패
  → 챌린지된 블록의 state 보유 필수!
```

### 6.3 왜 Debug API가 필수인가?

**보안 메커니즘**:

| API | 역할 | Public RPC 지원 | Full Node 증명 |
|-----|------|-----------------|---------------|
| `debug_accountRange` | State trie 전체 순회 | ❌ 대부분 비활성화 | ✅ 필수 |
| `eth_getProof` | Merkle proof 생성 | ✅ 대부분 지원 | ⚠️ 단독으로는 불충분 |

**Public RPC 사용 시도**:
```
Validator → Public RPC (Infura, Alchemy)
         → debug_accountRange 호출
         → ❌ Method not found (비활성화)
         → 증거 생성 불가능
         → 검증자 실격 (슬래싱)
```

**Self-hosted op-geth**:
```
Validator → Self-hosted op-geth (archive + debug API)
         → debug_accountRange 호출
         → ✅ 성공 (전체 state trie 접근)
         → Adjacent leaves 찾기
         → StateLeafEvidence 생성
         → 증거 제출
         → ✅ Full node 운영 증명
```

**Liveness vs Correctness**:
```
RAT Client = Liveness 검증
  - Full archive node 직접 보유?
  - L2를 실시간 모니터링?
  - debug API 접근 가능? (Public RPC 불가)

DisputeGame = Correctness 검증
  - State가 올바른가?
  - L1 데이터와 일치하는가?
```

**Trustless 수준**:
- Debug API 자체: Self-hosted node 신뢰 (운영자가 직접 관리)
- Merkle proofs: 암호학적 검증 가능 (100% trustless)
- OutputRootProof: L2 RPC (신뢰) 또는 OpNode (L1 기반, 100% trustless)

**결론**: Debug API는 **Liveness 증명** (Full node 운영), DisputeGame은 **Correctness 증명** (State 정확성)

### 6.4 각 컴포넌트 상세

#### 1. L1 RPC 접근

**목적**:
- RAT contract 이벤트 모니터링
- DisputeGameFactory 조회
- 증거 제출 트랜잭션 전송

**옵션**:
- Self-hosted Ethereum node (Geth, Erigon 등)
- 또는 Infura, Alchemy 등 provider

**요구사항**:
- 안정적인 연결
- 트랜잭션 전송 가능

#### 2. op-node (Follower Mode) ⭐ 권장 (Validator Best Practice)

**역할**: L1 batch data로부터 L2 블록을 재구성 (100% trustless)

**중요**: Validator는 Follower Mode op-node 운영 필수

```bash
op-node \
  --l1=https://ethereum-rpc.example.com \
  --l2=http://localhost:8551 \              # Engine API (op-geth)
  --l2.jwt-secret=/data/jwt.hex \            # JWT 인증
  --rollup.config=/data/rollup.json \        # L2 설정
  --rpc.addr=0.0.0.0 \
  --rpc.port=9545 \                          # Rollup RPC (RAT Client 사용)
  --l1.trustrpc=false                        # Trustless 모드
```

**Trustless Derivation 과정**:
```
1. L1에서 batch data 읽기 (BatchInbox contract)
2. Batch 디코딩 (SingularBatch, SpanBatch)
3. L2 transaction 추출
4. Execution payload 생성
5. Engine API로 op-geth에 전달 (JWT 인증)
6. op-geth가 블록 실행 및 state 저장
```

**요구사항**:
- CPU: 2-4 cores
- RAM: 4-8 GB
- Storage: ~100 GB SSD
- L1 RPC 접근
- rollup.json (L2 네트워크 설정)

**중요**:
- **Validator는 Follower Mode op-node 운영 필수**
- L1 batch data에서 L2를 trustless하게 재구성
- Engine API로 op-geth와 연결하여 블록 전달

#### 3. op-geth (Archive + Debug) ⭐ 필수

**역할**: op-node가 보낸 블록을 실행하고 state 저장 + debug API 제공

```bash
op-geth \
  --datadir=/data/op-geth \
  --http \
  --http.api=eth,net,web3,debug \     # ⭐ debug API 필수!
  --http.addr=0.0.0.0 \
  --http.port=8545 \                   # RAT Client가 사용
  --http.corsdomain="*" \
  --ws \
  --ws.api=eth,net,web3,debug \       # ⭐ debug API 필수!
  --ws.addr=0.0.0.0 \
  --ws.port=8546 \
  --authrpc.addr=localhost \           # ⭐ Engine API (op-node 연결)
  --authrpc.port=8551 \                # ⭐ Engine API 포트
  --authrpc.jwtsecret=/data/jwt.hex \  # ⭐ JWT 인증
  --syncmode=full \
  --gcmode=archive                     # ⭐ Archive mode 필수!
```

**Archive Mode (--gcmode=archive)**:
- 모든 historical state 보존
- Pruning 비활성화
- 디스크: ~10+ TB
- **어떤 과거 블록이라도 state 접근 가능**

**debug API (--http.api=debug)**:
- `debug_accountRange`: State trie 전체 순회
- `eth_getProof`: Merkle proof 생성
- **Self-hosted node만 활성화 가능**
- Public RPC는 대부분 비활성화

**요구사항**:
- CPU: 4-8 cores
- RAM: 16-32 GB
- Storage: ~10+ TB NVMe SSD (Archive mode)
- JWT secret (op-node와 공유)

**중요**:
- **op-node와 Engine API로 연결 필수** (JWT 인증)
- op-node가 보낸 블록만 실행 (trustless derivation)
- P2P 동기화 불필요 (Follower Mode)

**⚠️ Full Node의 문제점**:
```
--gcmode=full (기본값):
  - 최근 128 블록만 유지
  - L2 블록: 매 ~2초
  - 128 블록 = 약 4분
  - evidenceSubmissionPeriod = 1시간
  → 4분 전 state는 이미 삭제됨!
  → RAT 증거 제출 불가능!
  → 검증자 실격 (Slashing)!
```

**결론**: Archive mode 필수!

#### 4. RAT Client

**역할**: op-geth의 debug API를 사용해 증거 생성

**사용하는 API**:
1. **op-geth debug RPC** (필수):
   - `debug_accountRange`: Adjacent leaves 찾기
   - `eth_getProof`: Merkle proofs 생성

2. **OutputRootProof 생성**:
   - 방법 1: L2 RPC (`eth_getProof`로 MessagePasser storage root 조회)
   - 방법 2: op-node Rollup RPC (`optimism_outputAtBlock`)

**요구사항**:
- CPU: 1-2 cores
- RAM: 2-4 GB
- Storage: ~10 GB

### 6.5 시스템 사양

**Validator 필수 구성 (Follower Mode L2 노드)**:

| 컴포넌트 | CPU | RAM | Storage | 역할 |
|----------|-----|-----|---------|------|
| L1 RPC | - | - | - | Self-hosted 또는 Provider |
| op-node | 2-4 cores | 4-8 GB | ~100 GB SSD | L1에서 L2 재구성 (Follower Mode) |
| op-geth | 4-8 cores | 16-32 GB | ~10+ TB NVMe | Archive + Debug API |
| RAT Client | 1-2 cores | 2-4 GB | ~10 GB | Adjacent Leaves 증거 생성 |
| **Total** | **7-14 cores** | **22-44 GB** | **~10+ TB** | |

**핵심 원칙**:
- Validator는 Follower Mode L2 노드 운영 필수
- op-node + op-geth를 Engine API로 연결 (JWT 인증)
- L1 batch data에서 L2를 trustless하게 재구성
- Public L2 RPC 사용 불가

### 6.6 배포 단계

#### Step 1: JWT Secret 생성 (필수)

```bash
openssl rand -hex 32 > /data/jwt.hex
```

**중요**: op-node와 op-geth가 같은 JWT secret을 공유해야 Engine API 인증 가능

#### Step 2: Rollup Config 준비 (필수)

```bash
# rollup.json 다운로드 또는 생성
# L2 체인별로 다름 (genesis, block time, contracts 등)
curl -o /data/rollup.json https://example.com/optimism-rollup.json

# 또는 수동 생성
cat > /data/rollup.json <<EOF
{
  "genesis": {
    "l1": {...},
    "l2": {...}
  },
  "block_time": 2,
  ...
}
EOF
```

#### Step 3: op-geth 시작 (필수)

```bash
op-geth \
  --datadir=/data/op-geth \
  --http \
  --http.api=eth,net,web3,debug \
  --http.addr=0.0.0.0 \
  --http.port=8545 \
  --ws \
  --ws.api=eth,net,web3,debug \
  --ws.addr=0.0.0.0 \
  --ws.port=8546 \
  --authrpc.addr=localhost \
  --authrpc.port=8551 \
  --authrpc.jwtsecret=/data/jwt.hex \
  --syncmode=full \
  --gcmode=archive
```

**동기화 대기**: 수일 ~ 수주 (체인 크기에 따라)

#### Step 4: op-node 시작 (필수)

```bash
op-node \
  --l1=https://ethereum-rpc.example.com \
  --l2=http://localhost:8551 \
  --l2.jwt-secret=/data/jwt.hex \
  --rollup.config=/data/rollup.json \
  --rpc.addr=0.0.0.0 \
  --rpc.port=9545 \
  --l1.trustrpc=false
```

**동기화 확인**:
```bash
curl http://localhost:9545 -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"optimism_syncStatus","params":[],"id":1}'
```

#### Step 5: debug API 테스트 (필수)

```bash
# debug_accountRange 테스트
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "method":"debug_accountRange",
    "params":["latest", "0x0000000000000000000000000000000000000000", 10, false, false, false],
    "id":1
  }'

# eth_getProof 테스트
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "method":"eth_getProof",
    "params":["0x0000000000000000000000000000000000000000", [], "latest"],
    "id":1
  }'
```

**모두 성공 응답이 와야 RAT Client 실행 가능!**

#### Step 6: RAT Client 설정

```yaml
# config.yaml
# RAT Client 설정 (service_adjacent.go 기반)

# L1 Configuration
l1:
  rpc_url: "https://ethereum-rpc.example.com"
  beacon_url: "http://localhost:5052"  # EIP-4844 blob용

# L2 RPC (Self-hosted op-geth with debug API) ⭐ 필수
l2:
  rpc_url: "http://localhost:8545"  # debug_accountRange + eth_getProof

# op-node RPC - OutputRootProof 검증
opnode:
  rpc_url: "http://localhost:9545"  # op-node Rollup RPC

# Contract addresses
contracts:
  rat_contract: "0x..."
  dispute_game_factory: "0x..."
  l1_bridge_registry: "0x..."
  batch_inbox: "0xff03000000000000000000000000000000000000"

# Validator identity
validator:
  private_key: "${VALIDATOR_PRIVATE_KEY}"  # 환경 변수 권장
  address: "0x..."  # 개인키에서 파생됨

# RAT Client Settings
rat:
  poll_interval: 12s          # L1 이벤트 폴링 간격
  deadline_buffer: 10m        # Evidence 제출 마감 버퍼
  max_gas_price: 100          # gwei
  gas_limit: 500000
  confirmations: 64           # Production: 64, Devnet: 1-6

# Verification Settings
verification:
  enable_proof_verification: true
  rpc_timeout: 20m

# Logging
logging:
  level: info  # debug | info | warn | error
  format: json # json | text

# Metrics
metrics:
  enabled: true
  addr: "0.0.0.0"
  port: 7300
```

#### Step 7: RAT Client 시작

```bash
cd clients/rat-client-type3
go build -o bin/rat-client ./cmd
./bin/rat-client --config config.yaml
```

**로그 확인**:
```
RAT Client running in Adjacent Leaves mode (State Root as Target)
Using RPC mode (debug_accountRange + eth_getProof)
Validator: 0x...
RAT Contract: 0x...
Press Ctrl+C to stop...
```

---

## 참고 자료

### 코드
- `clients/rat-client-type3/cmd/main.go` - 엔트리포인트
- `clients/rat-client-type3/pkg/client/service_adjacent.go` ⭐ 프로덕션 사용
- `clients/rat-client-type3/pkg/l2sync/state_rpc.go` ⭐ Debug RPC 구현
- `clients/rat-client-type3/test/state_leaf_rpc_e2e_test.go` ⭐ 추천
- `src/validator/libraries/Type3EvidenceVerifier.sol`
- `test/v3/rat-client/RATClient.t.sol`

### 문서
- 12. Optimism Integration
- clients/rat-client-type3/docs/ARCHITECTURE_KR.md
- clients/README.md

### 외부 참고
- Geth v1.13+ PBSS (Path-Based State Storage)
- Optimism Derivation Specification
- Optimism op-node + op-geth Architecture
- Ethereum Patricia Trie Specification

---

**마지막 업데이트**: 2026-01-30
**주요 변경**:
- 문서 13, 14 통합 (중복 제거)
- 논리적 흐름으로 재구성 (개념 → 구현 → 운영)
- Follower Mode op-node 역할 명확화
- Debug API 필수성 강조
- 실측 불가능한 추정치 제거
