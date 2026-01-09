# RAT Go Client - State Root as Target Implementation

## 개요

RAT Go client에 **State Root as Target** 설계를 구현했습니다. 이제 Go client는 op-node에서 OutputRootProof를 가져와 StateLeafEvidence에 포함시킵니다.

## 구현된 기능

### 1. OutputRootProof 구조체 (evidence/state_leaf_evidence.go)

```go
// OutputRootProof represents Optimism OutputRootProof structure
// This matches the Solidity struct in Type3EvidenceVerifier.sol
type OutputRootProof struct {
    Version                  [32]byte    // Version (always 0x0)
    StateRoot                common.Hash // L2 state root
    MessagePasserStorageRoot common.Hash // L2ToL1MessagePasser storage root
    LatestBlockHash          common.Hash // L2 block hash
}
```

### 2. StateLeafEvidence 업데이트

**이전:**
```go
type StateLeafEvidence struct {
    LeafAKey   common.Hash
    LeafAValue []byte
    LeafAProof [][]byte
    LeafBKey   common.Hash
    LeafBValue []byte
    LeafBProof [][]byte
    StateRoot   common.Hash
    BlockNumber uint64
}
```

**현재:**
```go
type StateLeafEvidence struct {
    LeafAKey   common.Hash
    LeafAValue []byte
    LeafAProof [][]byte
    LeafBKey   common.Hash
    LeafBValue []byte
    LeafBProof [][]byte
    StateRoot   common.Hash // Deprecated: use OutputRootProof.StateRoot
    BlockNumber uint64
    OutputRootProof OutputRootProof // ← 추가!
}
```

### 3. Encode() 함수 업데이트

OutputRootProof를 ABI encoding에 포함:

```go
func (e *StateLeafEvidence) Encode() ([]byte, error) {
    // Define OutputRootProof tuple type
    outputRootProofTy, _ := abi.NewType("tuple", "", []abi.ArgumentMarshaling{
        {Name: "version", Type: "bytes32"},
        {Name: "stateRoot", Type: "bytes32"},
        {Name: "messagePasserStorageRoot", Type: "bytes32"},
        {Name: "latestBlockhash", Type: "bytes32"},
    })

    arguments := abi.Arguments{
        {Type: bytes32Ty},         // leafAKey
        {Type: bytesTy},           // leafAValue
        {Type: bytesArrayTy},      // leafAProof
        {Type: bytes32Ty},         // leafBKey
        {Type: bytesTy},           // leafBValue
        {Type: bytesArrayTy},      // leafBProof
        {Type: bytes32Ty},         // stateRoot
        {Type: uint256Ty},         // blockNumber
        {Type: outputRootProofTy}, // outputRootProof ← 추가!
    }

    // Pack arguments...
}
```

### 4. op-node API 통합 (verification/opnode_provider.go)

#### GetOutputRootProof()
```go
// GetOutputRootProof queries op-node and constructs OutputRootProof
func (c *OpNodeRollupClient) GetOutputRootProof(
    ctx context.Context,
    blockNum uint64,
) (*OutputRootProof, error) {
    output, err := c.OutputAtBlock(ctx, blockNum)
    if err != nil {
        return nil, fmt.Errorf("failed to get output at block %d: %w", blockNum, err)
    }

    return &OutputRootProof{
        Version:                  [32]byte{}, // Version 0
        StateRoot:                output.StateRoot,
        MessagePasserStorageRoot: output.WithdrawalStorageRoot,
        LatestBlockHash:          output.BlockRef.Hash,
    }, nil
}
```

#### HashOutputRootProof()
```go
// HashOutputRootProof computes keccak256(abi.encode(OutputRootProof))
// Matches Solidity implementation
func HashOutputRootProof(proof *OutputRootProof) common.Hash {
    bytes32Ty, _ := abi.NewType("bytes32", "", nil)

    arguments := abi.Arguments{
        {Type: bytes32Ty}, // version
        {Type: bytes32Ty}, // stateRoot
        {Type: bytes32Ty}, // messagePasserStorageRoot
        {Type: bytes32Ty}, // latestBlockhash
    }

    encoded, err := arguments.Pack(
        proof.Version,
        proof.StateRoot,
        proof.MessagePasserStorageRoot,
        proof.LatestBlockHash,
    )
    if err != nil {
        panic(fmt.Sprintf("failed to encode OutputRootProof: %v", err))
    }

    return crypto.Keccak256Hash(encoded)
}
```

#### VerifyOutputRootProof()
```go
// VerifyOutputRootProof verifies that hash(OutputRootProof) == expectedRootClaim
// This is the same verification that happens on-chain
func (c *OpNodeRollupClient) VerifyOutputRootProof(
    proof *OutputRootProof,
    expectedRootClaim common.Hash,
) error {
    computedHash := HashOutputRootProof(proof)

    if computedHash != expectedRootClaim {
        return fmt.Errorf(
            "OutputRootProof hash mismatch: computed=%s, expected=%s",
            computedHash.Hex(),
            expectedRootClaim.Hex(),
        )
    }

    return nil
}
```

### 5. Service 업데이트 (client/service_adjacent.go)

#### Config에 OpNodeRPCURL 추가
```go
type AdjacentServiceConfig struct {
    // ...
    OpNodeRPCURL    string // op-node Rollup RPC URL (for OutputRootProof)
    // ...
}
```

#### op-node client 초기화
```go
// Create op-node client (for OutputRootProof)
var opNodeClient *verification.OpNodeRollupClient
if config.OpNodeRPCURL != "" {
    opNodeClient, err = verification.NewOpNodeRollupClient(config.OpNodeRPCURL)
    if err != nil {
        cancel()
        return nil, fmt.Errorf("failed to create op-node client: %w", err)
    }
    log.Info("op-node client created", "opNodeRPC", config.OpNodeRPCURL)
} else {
    log.Warn("OpNodeRPCURL not configured - OutputRootProof will not be included in evidence")
}
```

#### handleAttentionTest()에서 OutputRootProof 가져오기
```go
// Create evidence from state trie leaves
ev, err := evidence.NewStateLeafEvidence(adjacentLeaves)
if err != nil {
    return fmt.Errorf("failed to create evidence: %w", err)
}

// Get OutputRootProof from op-node (if configured)
if s.opNodeClient != nil {
    log.Info("Fetching OutputRootProof from op-node", "blockNumber", adjacentLeaves.BlockNumber)

    opNodeProof, err := s.opNodeClient.GetOutputRootProof(s.ctx, adjacentLeaves.BlockNumber)
    if err != nil {
        log.Warn("Failed to get OutputRootProof from op-node", "error", err)
        // Continue without OutputRootProof (backward compatibility)
    } else {
        // Convert opNodeProof to evidence.OutputRootProof
        ev.OutputRootProof = evidence.OutputRootProof{
            Version:                  opNodeProof.Version,
            StateRoot:                opNodeProof.StateRoot,
            MessagePasserStorageRoot: opNodeProof.MessagePasserStorageRoot,
            LatestBlockHash:          opNodeProof.LatestBlockHash,
        }

        log.Info("OutputRootProof fetched",
            "version", common.Bytes2Hex(opNodeProof.Version[:]),
            "stateRoot", opNodeProof.StateRoot.Hex(),
            "messagePasserStorageRoot", opNodeProof.MessagePasserStorageRoot.Hex(),
            "latestBlockHash", opNodeProof.LatestBlockHash.Hex(),
        )

        // Verify StateRoot matches
        if opNodeProof.StateRoot != adjacentLeaves.StateRoot {
            log.Warn("StateRoot mismatch between op-node and state trie",
                "opNodeStateRoot", opNodeProof.StateRoot.Hex(),
                "stateTrie StateRoot", adjacentLeaves.StateRoot.Hex(),
            )
        }
    }
}
```

## 실행 흐름

```
1. RAT Event 수신
   ↓
2. Adjacent Leaves 찾기 (State Trie)
   ↓
3. op-node에서 OutputRootProof 가져오기
   ├─ optimism_outputAtBlock(blockNum) RPC 호출
   └─ StateRoot, MessagePasserStorageRoot, BlockHash 추출
   ↓
4. OutputRootProof 검증 (선택적)
   └─ StateRoot가 State Trie와 일치하는지 확인
   ↓
5. StateLeafEvidence 생성
   ├─ LeafA, LeafB
   ├─ Merkle Proofs
   └─ OutputRootProof ← 추가!
   ↓
6. Evidence ABI 인코딩
   └─ OutputRootProof를 tuple로 인코딩
   ↓
7. L1에 제출
   ↓
8. On-chain 검증
   ├─ hash(OutputRootProof) == rootClaim ✅
   ├─ leafA < stateRoot < leafB ✅
   └─ Merkle Proof 검증 ✅
```

## Configuration 예시

```yaml
# config.yaml
l1_rpc_url: "http://localhost:8545"
l2_rpc_url: "http://localhost:9545"

# op-node Rollup RPC (for OutputRootProof)
opnode_rpc_url: "http://localhost:9546"  # ← 추가!

state_db_path: "/path/to/op-geth/datadir"
rat_contract: "0x..."
```

## 장점

### 1. 자기 참조적 증명 (Self-Referential)
- State Root 자체를 타겟으로 사용
- "이 State Root가 진짜임을 증명하기 위해, State Root 근처의 데이터 제출"

### 2. 향상된 보안
- OutputRootProof 검증: `hash(OutputRootProof) == rootClaim`
- On-chain에서 L1에 커밋된 rootClaim과 비교

### 3. 천연 랜덤성
- State Root는 매 블록마다 변함
- Pre-computation 공격 불가능

### 4. 완벽한 증명
- 검증자는 전체 State Trie를 인덱싱해야만 stateRoot 근처의 adjacent leaves를 찾을 수 있음

### 5. Backward Compatibility
- OpNodeRPCURL이 없으면 OutputRootProof 없이도 작동 (경고 로그)
- 점진적 마이그레이션 가능

## 변경된 파일

| 파일 | 변경사항 |
|------|---------|
| `pkg/evidence/state_leaf_evidence.go` | OutputRootProof 구조체 추가<br>StateLeafEvidence에 OutputRootProof 필드 추가<br>Encode() 업데이트 |
| `pkg/verification/opnode_provider.go` | OutputRootProof 구조체 추가<br>GetOutputRootProof() 함수 추가<br>HashOutputRootProof() 함수 추가<br>VerifyOutputRootProof() 함수 추가 |
| `pkg/client/service_adjacent.go` | AdjacentServiceConfig에 OpNodeRPCURL 추가<br>opNodeClient 초기화<br>handleAttentionTest()에서 OutputRootProof 가져오기 |

## 테스트 방법

### 1. op-node 실행
```bash
# op-node with Rollup RPC enabled
op-node \
  --rollup.config=./rollup.json \
  --l1=http://localhost:8545 \
  --l2=http://localhost:9545 \
  --rpc.addr=0.0.0.0 \
  --rpc.port=9546
```

### 2. RAT Client 설정
```yaml
# config.yaml
opnode_rpc_url: "http://localhost:9546"
```

### 3. RAT Client 실행
```bash
cd clients/rat-client-type3
go run cmd/main.go --config config.yaml
```

### 4. 로그 확인
```
INFO Fetching OutputRootProof from op-node blockNumber=12345
INFO OutputRootProof fetched
  version=0x0000...
  stateRoot=0x1234...
  messagePasserStorageRoot=0x5678...
  latestBlockHash=0x9abc...
INFO Evidence created size=2500 bytes
INFO Submitting evidence to L1...
INFO Evidence submitted successfully txHash=0xdef0...
```

## 향후 개선사항

### Phase 3: ZK-Based Perfect Verification
- RISC Zero / SP1 통합
- 완벽한 adjacency 검증 (Step 4)
- 가스비 감소 (~50k gas)
- Instant finality

## 결론

State Root as Target 설계의 Go client 구현이 완료되었습니다:
- ✅ op-node API 통합
- ✅ OutputRootProof 생성 및 검증
- ✅ StateLeafEvidence에 OutputRootProof 포함
- ✅ Backward compatibility 유지
- ✅ 강화된 보안 모델

이제 Go client는 Solidity contract와 완벽하게 통합되어 State Root as Target 설계를 지원합니다!
