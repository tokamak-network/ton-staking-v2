# Go Client 구현

## 4.1 패키지 구조

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

## 4.2 핵심 패키지

### monitor - L1 이벤트 감지
- RAT 계약에서 `AttentionTestTriggered` 이벤트 모니터링
- 본인 검증자 주소 필터링
- L1 confirmations 적용

### l2sync - Adjacent Leaves 찾기 ⭐
- **Debug RPC 모드** (✅ 프로덕션): `debug_accountRange` + `eth_getProof`
- Divergence node 계산
- Gap 사전 검증

**핵심 파일**: `pkg/l2sync/state_rpc.go`

### evidence - 증거 생성
- StateLeafEvidence 구조체 생성
- OutputRootProof 추가
- DivergenceWitness 계산
- ABI 인코딩 (Solidity 호환)

### verification - OutputRootProof 검증
- **방법 1**: L2 RPC로 직접 계산 (`eth_getProof`)
- **방법 2**: OpNode Rollup RPC 사용 (`optimism_outputAtBlock`)
- State root 무결성 확인

### submitter - 증거 제출
- RAT 계약 `submitEvidence()` 호출
- 가스 가격 최적화
- 재시도 로직

## 4.3 Debug RPC 기반 증거 생성 플로우

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

## 4.4 핵심 함수: FindAdjacentLeavesViaRPC()

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

## 4.5 핵심 함수: FindDivergenceNode()

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

**다음**: [OutputRootProof 검증](./05-outputrootproof-verification.md)
