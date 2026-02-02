# OutputRootProof 검증

## 5.1 OutputRootProof란?

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

## 5.2 방법 1: L2 RPC로 OutputRootProof 생성 (✅ 기본값)

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

## 5.3 방법 2: OpNode로 OutputRootProof 조회

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

## 5.4 OutputRootProof 검증의 역할

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

**다음**: [배포 및 운영](./06-deployment-operations.md)
