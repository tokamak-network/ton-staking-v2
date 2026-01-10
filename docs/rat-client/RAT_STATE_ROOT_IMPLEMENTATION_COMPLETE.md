# RAT State Root as Target 구현 상태

---

## 📋 목차

1. [개요](#개요)
2. [구현 내용](#구현-내용)
3. [테스트 현황](#테스트-현황)
4. [사용 방법](#사용-방법)
5. [다음 단계](#다음-단계)

---

## 개요

### State Root as Target 설계

Optimism의 OutputRootProof를 활용한 자기참조 증명 시스템:

```
rootClaim = keccak256(abi.encode(OutputRootProof))
OutputRootProof = {version, stateRoot, withdrawalRoot, blockHash}

→ stateRoot를 target으로 사용하여 adjacent leaves 검증
→ leafA < stateRoot < leafB 를 증명
```

### 핵심 장점

1. **Self-referential**: State root 자체가 target
2. **Optimism Compatible**: OutputRootProof 표준 사용
3. **Verifiable on-chain**: Contract에서 hash 검증 가능
4. **Merkle-based**: Patricia trie proof 활용

---

## 구현 내용

### 1. Solidity Contracts

#### Type3EvidenceVerifier.sol
```solidity
struct OutputRootProof {
    bytes32 version;
    bytes32 stateRoot;
    bytes32 messagePasserStorageRoot;
    bytes32 latestBlockhash;
}

function verifyStateLeaf(bytes32 rootClaim, bytes calldata evidenceData)
    internal pure returns (bool)
{
    // 1. Decode evidence
    StateLeafEvidence memory ev = abi.decode(evidenceData, (StateLeafEvidence));

    // 2. Verify hash(OutputRootProof) == rootClaim
    bytes32 computedRootClaim = _hashOutputRootProof(ev.outputRootProof);
    if (computedRootClaim != rootClaim) return false;

    // 3. Extract stateRoot as target
    bytes32 stateRoot = ev.outputRootProof.stateRoot;

    // 4. Verify adjacent range
    if (!_verifyAdjacentRange(ev.leafAKey, ev.leafBKey, stateRoot)) return false;

    // 5. Verify Merkle proofs
    if (!_verifyPatriciaProofsWithRoot(ev, stateRoot)) return false;

    return true;
}
```

**변경사항**:
- ✅ OutputRootProof 구조체 추가
- ✅ verifyStateLeaf에 rootClaim 파라미터 추가
- ✅ _hashOutputRootProof() 함수 추가
- ✅ Unused imports 제거 (MerkleProof, RLPReader)

#### RAT.sol
```solidity
function _verifyEvidence(...) internal view returns (bool) {
    if (rollupType == 3) {
        if (evidenceType == 1) {  // StateLeaf
            AttentionTest storage test = attentionTests[testId];
            bytes32 rootClaim = IDisputeGame(test.gameAddress).rootClaim();
            return Type3EvidenceVerifier.verifyStateLeaf(rootClaim, evidenceData);
        }
    }
}
```

**변경사항**:
- ✅ gameAddress 필드를 AttentionTest에 추가
- ✅ DisputeGame에서 rootClaim 조회
- ✅ rootClaim을 verifyStateLeaf에 전달

#### RATStorage.sol
```solidity
struct AttentionTest {
    address validatorAddress;
    address systemConfig;
    uint32 batchIndex;
    address gameAddress;    // Added for rootClaim queries
    bytes32 batchHash;
    uint256 bondAmount;
    uint256 createdAt;
    uint256 deadline;
    AttentionTestStatus status;
}
```

**변경사항**:
- ✅ gameAddress 필드 추가

#### IDisputeGame.sol (NEW)
```solidity
interface IDisputeGame {
    function rootClaim() external view returns (bytes32);
}
```

**목적**: DisputeGame에서 rootClaim 조회

### 2. Go Client

#### pkg/evidence/state_leaf_evidence.go
```go
type OutputRootProof struct {
    Version                  [32]byte
    StateRoot                common.Hash
    MessagePasserStorageRoot common.Hash
    LatestBlockHash          common.Hash
}

type StateLeafEvidence struct {
    LeafAKey   common.Hash
    LeafAValue []byte
    LeafAProof [][]byte
    LeafBKey   common.Hash
    LeafBValue []byte
    LeafBProof [][]byte
    StateRoot   common.Hash // Deprecated (kept for compatibility)
    BlockNumber uint64
    OutputRootProof OutputRootProof  // Added
}
```

**변경사항**:
- ✅ OutputRootProof 구조체 추가
- ✅ StateLeafEvidence에 OutputRootProof 필드 추가
- ✅ Encode() 메서드 업데이트

#### pkg/verification/opnode_provider.go
```go
func (c *OpNodeRollupClient) GetOutputRootProof(ctx context.Context, blockNum uint64) (*OutputRootProof, error) {
    output, err := c.OutputAtBlock(ctx, blockNum)
    if err != nil {
        return nil, fmt.Errorf("failed to get output at block %d: %w", blockNum, err)
    }

    return &OutputRootProof{
        Version:                  [32]byte{},
        StateRoot:                output.StateRoot,
        MessagePasserStorageRoot: output.WithdrawalStorageRoot,
        LatestBlockHash:          output.BlockRef.Hash,
    }, nil
}

func HashOutputRootProof(proof *OutputRootProof) common.Hash {
    bytes32Ty, _ := abi.NewType("bytes32", "", nil)
    arguments := abi.Arguments{
        {Type: bytes32Ty}, {Type: bytes32Ty},
        {Type: bytes32Ty}, {Type: bytes32Ty},
    }
    encoded, _ := arguments.Pack(
        proof.Version,
        proof.StateRoot,
        proof.MessagePasserStorageRoot,
        proof.LatestBlockHash,
    )
    return crypto.Keccak256Hash(encoded)
}

func (c *OpNodeRollupClient) VerifyOutputRootProof(proof *OutputRootProof, expectedRootClaim common.Hash) bool {
    computedRootClaim := HashOutputRootProof(proof)
    return computedRootClaim == expectedRootClaim
}
```

**변경사항**:
- ✅ GetOutputRootProof() 함수 추가
- ✅ HashOutputRootProof() 함수 추가
- ✅ VerifyOutputRootProof() 함수 추가

#### pkg/client/service_adjacent.go
```go
// Current Implementation (2026-01-10):
// OutputRootProof is constructed from L2 geth directly
// - StateRoot: from eth_getBlockByNumber
// - MessagePasserStorageRoot: from eth_getProof (L2ToL1MessagePasser account)
// - LatestBlockHash: from eth_getBlockByNumber
// - Version: always 0x0

ev.OutputRootProof = evidence.OutputRootProof{
    Version:                  [32]byte{}, // Always 0x0
    StateRoot:                adjacentLeaves.StateRoot,
    MessagePasserStorageRoot: messagePasserStorageRoot, // from eth_getProof
    LatestBlockHash:          blockHash,
}
```

**변경사항**:
- ✅ **Method 1 (Current)**: L2 geth RPC 사용 (`eth_getBlockByNumber`, `eth_getProof`)
- ⚠️ **Method 2 (Optional)**: op-node 통합 지원 (코드에 남아있음, 선택적)
- ✅ `debug_accountRange` - adjacent leaves 찾기
- ✅ `eth_getProof` - account data + Merkle proof 가져오기

### 3. Tests

#### Solidity Tests

**Type3EvidenceVerifier.t.sol**: 12/12 passing ✅
```
[PASS] testVerifyStateLeaf_Success
[PASS] testVerifyStateLeaf_InvalidRootClaim
[PASS] testVerifyStateLeaf_InvalidRange
[PASS] testVerifyStateLeaf_KeysNotAdjacent
[PASS] testVerifyStateLeaf_InvalidProofs
...
```

**RAT.t.sol**: 29/33 passing (4 skipped for E2E) ✅
```
[PASS] testTriggerAttentionTest
[PASS] testValidatorRegistration
[PASS] testDepositPreDeduction
[SKIP] testSubmitEvidence_StateLeaf (requires valid Merkle proofs)
[SKIP] testSubmitEvidence_InvalidRootClaim (E2E)
[SKIP] testSubmitEvidence_InvalidRange (E2E)
...
```

**Skipped tests**: Real Merkle proofs 필요, E2E 테스트에서 검증

#### Go Tests

**integration_mock_test.go**: Mock HTTP server 테스트 ✅
```go
func TestOutputRootProofIntegration(t *testing.T) {
    // Mock op-node server
    // Test OutputRootProof fetching
    // Test hash computation
    // Test verification
}
```

### 4. Documentation

현재 문서 (2026-01-10):
1. ✅ `docs/rat-client/rat-state-root-as-target.md` - State Root as Target 설계
2. ✅ `docs/rat-client/rat-stateleaf-adjacency-verification.md` - Adjacency 검증
3. ✅ `docs/rat-client/state-leaf-verification-implementation.md` - 구현 요약
4. ✅ `docs/rat-client/debug-api-usage.md` - debug_accountRange 가이드
5. ✅ `op-e2e/README.md` - E2E 테스트 상세 문서
6. ✅ `docs/test/e2e-tests.md` - E2E 테스트 진입점

---

## 테스트 현황

### Unit Tests: ✅ 41/45 Passing

```
src/validator/libraries/Type3EvidenceVerifier.sol
├─ testVerifyStateLeaf_Success                         ✅
├─ testVerifyStateLeaf_InvalidRootClaim                ✅
├─ testVerifyStateLeaf_InvalidRange                    ✅
├─ testVerifyStateLeaf_KeysNotAdjacent                 ✅
└─ ... (12 tests total)                                ✅

src/validator/RAT.sol
├─ testTriggerAttentionTest                            ✅
├─ testValidatorRegistration                           ✅
├─ testDepositPreDeduction                             ✅
├─ testSubmitEvidence_StateLeaf                        ⏭️ (E2E)
├─ testSubmitEvidence_InvalidRootClaim                 ⏭️ (E2E)
├─ testSubmitEvidence_InvalidRange                     ⏭️ (E2E)
├─ testSubmitEvidence_Timeout                          ⏭️ (E2E)
└─ ... (29 passing, 4 skipped)
```

**Result**: 실제 Merkle proof가 필요한 4개 테스트는 E2E에서 검증

### Integration Tests: ✅ Mock Server

```
clients/rat-client-type3/test/integration_mock_test.go
├─ TestOutputRootProofIntegration                      ✅
└─ TestOpNodeMockServer                                ✅
```

### E2E Tests: ✅ Go Tests (op-e2e/faultproofs)

**현재 E2E 테스트 (2026-01-10)**:
- **Location**: `op-e2e/faultproofs/`
- **Framework**: Go testing package
- **Total**: 8 tests (all passing)

| Test File | Tests | Status |
|-----------|-------|--------|
| `rat_system_test.go` | 3 tests | ✅ System startup, balances, contract calls |
| `rat_challenge_test.go` | 4 tests | ✅ Registration, game creation, evidence, challenger wins |
| `rat_state_root_test.go` | 1 test | ✅ **Full State Root E2E with L2 integration** |

**TestRATStateRootAsTarget** (핵심):
- L1 (Anvil) + L2 (geth) 자동 시작
- OutputRootProof 계산 및 검증
- RAT client subprocess 실행
- StateLeafEvidence 제출 (1504 bytes)
- Gas Used: ~277,247
- **Status**: ✅ PASS

---

## 사용 방법

### E2E Tests

```bash
# 전체 E2E 테스트 실행 (8 tests)
cd op-e2e
make test

# 또는 프로젝트 루트에서
make test-e2e

# State Root E2E 테스트만 실행
cd op-e2e
GOWORK=off go test -v -run TestRATStateRootAsTarget ./faultproofs
```

### Unit Tests

```bash
# Solidity tests
forge test -vv

# Go tests
cd clients/rat-client-type3
go test ./...
```

---

## 전체 플로우

### 1. L2 State 생성
```
geth (dev mode)
  ↓
Transactions (20 accounts)
  ↓
State Trie updated
  ↓
stateRoot: 0x1234...
```

### 2. DisputeGame 생성
```
Forge Script
  ↓
OutputRootProof {
    version: 0x0,
    stateRoot: 0x1234...,
    messagePasserStorageRoot: 0x5678...,
    latestBlockHash: 0xabcd...
}
  ↓
rootClaim = keccak256(abi.encode(OutputRootProof))
  ↓
DisputeGame deployed with rootClaim
```

### 3. RAT 트리거
```
L1: RAT.triggerAttentionTest(...)
  ↓
Event: AttentionTestTriggered(testId, gameAddress, ...)
  ↓
RAT Client listens
```

### 4. Adjacent Leaves 검색
```
RAT Client
  ↓
Query DisputeGame.rootClaim()
  ↓
Decode → OutputRootProof → stateRoot
  ↓
Access L2 State DB: /tmp/.../chaindata
  ↓
Search Patricia Trie
  ↓
Find: leafA (0x1000) < stateRoot (0x1234) < leafB (0x1500)
```

### 5. Evidence 생성 & 제출
```
RAT Client
  ↓
Generate Merkle Proofs
  ↓
Create StateLeafEvidence {
    leafA: {...},
    leafB: {...},
    OutputRootProof: {...}
}
  ↓
Submit to L1: RAT.submitEvidence(testId, 1, evidence)
```

### 6. On-chain 검증
```
Type3EvidenceVerifier.verifyStateLeaf(rootClaim, evidenceData)
  ↓
1. hash(OutputRootProof) == rootClaim ✅
2. leafA.key < stateRoot < leafB.key ✅
3. Merkle proofs valid ✅
  ↓
Status: Responded
Deposit: Restored
```

---

## 핵심 기술

### 1. OutputRootProof
```solidity
struct OutputRootProof {
    bytes32 version;                    // 0x0
    bytes32 stateRoot;                  // L2 state root
    bytes32 messagePasserStorageRoot;   // Withdrawal root
    bytes32 latestBlockhash;            // L2 block hash
}

// Optimism standard
rootClaim = keccak256(abi.encode(OutputRootProof))
```

### 2. State Root as Target
```
stateRoot = 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef

Adjacent Leaves:
  leafA: key = 0x1000... (< 0x1234...)
  leafB: key = 0x1500... (> 0x1234...)

Proof: leafA < stateRoot < leafB
```

### 3. Patricia Merkle Trie
```
Ethereum State Trie:
         root
        /    \
     [0]      [1]
    /  \      /  \
  [A]  [B]  [C]  [D]

Query: path(key) → value + proof
Verify: MerkleTrie.verifyInclusionProof(key, value, proof, root)
```

---

## 다음 단계

### Immediate (이미 완료됨)
- [x] Solidity 구현
- [x] Go client 구현
- [x] Unit tests (41/45 passing)
- [x] Integration tests (mock server)
- [x] E2E tests (8 tests, all passing)
- [x] Documentation

### Short Term (다음 작업)
- [ ] Gas 최적화
- [ ] Edge cases 추가 테스트
- [ ] 프로덕션 배포 준비

### Medium Term
- [ ] Kurtosis 전체 devnet 테스트
- [ ] Edge cases 테스트
  - 빈 state trie
  - 극단적인 key 값들
  - 동시 다발 RAT 트리거
- [ ] Performance 최적화
  - State DB 접근 최적화
  - Proof 생성 최적화

### Long Term
- [ ] Mainnet 배포 준비
- [ ] Security audit
- [ ] Monitoring & alerting
- [ ] Production 운영 가이드

---

## 참고 자료

### 코드
- Solidity: `src/validator/libraries/Type3EvidenceVerifier.sol`
- Go: `clients/rat-client-type3/pkg/`
- Tests: `test/v3/`, `clients/rat-client-type3/test/`

### 문서
- State Root as Target: `docs/rat-client/rat-state-root-as-target.md`
- Adjacency Verification: `docs/rat-client/rat-stateleaf-adjacency-verification.md`
- Implementation Summary: `docs/rat-client/state-leaf-verification-implementation.md`
- E2E Tests Guide: `op-e2e/README.md`

---

## 결론

RAT "State Root as Target" 설계가 **완전히 구현되고 테스트 준비가 완료**되었습니다.

### 완료된 작업
✅ Solidity contracts (Type3EvidenceVerifier, RAT, interfaces)
✅ Go client (OutputRootProof integration, L2 geth RPC)
✅ Unit tests (41/45 passing, 4 skipped for E2E)
✅ Integration tests (mock server)
✅ E2E tests (8 Go tests, all passing)
✅ Complete documentation

### 바로 실행 가능
```bash
# E2E 테스트 실행
cd op-e2e && make test

# 또는 프로젝트 루트에서
make test-e2e
```

전체 RAT 플로우를 ~40초 내에 테스트할 수 있습니다!
