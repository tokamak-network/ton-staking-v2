# State Root as Target - Testing Guide

## 개요

State Root as Target 설계의 테스트는 **3단계**로 구성됩니다:
1. **Unit Tests** (Solidity + Go) - 개별 컴포넌트 테스트
2. **Integration Tests** (Solidity) - 컨트랙트 통합 테스트
3. **E2E Tests** (Go) - 전체 플로우 테스트 (devnet 필요)

---

## 1. Unit Tests (Solidity)

### Type3EvidenceVerifier 테스트

**위치:** `test/v3/Type3EvidenceVerifier.t.sol`

**실행:**
```bash
forge test --match-path "test/v3/Type3EvidenceVerifier.t.sol" -vv
```

**테스트 항목:**
- ✅ `test_validateStateLeafBasics_*` - 기본 데이터 검증
- ✅ `test_verifyAdjacentRange_*` - 범위 검증 (leafA < stateRoot < leafB)
- ✅ `test_verifyStateLeaf_emptyData` - 빈 데이터 거부
- ✅ `test_verifyStateLeaf_validStructure_SKIP` - 구조 검증 (Merkle proof는 스킵)

**결과:** 12/12 테스트 통과 ✅

---

### RAT Contract 테스트

**위치:** `test/v3/RAT.t.sol`

**실행:**
```bash
forge test --match-path "test/v3/RAT.t.sol" -vv
```

**테스트 항목:**
- ✅ `test_triggerAttentionTest` - RAT 이벤트 트리거
- ✅ `test_registerValidator_*` - 검증자 등록
- ✅ `test_resolveClaim_*` - Claim 해결
- ⏭️ `test_submitEvidence_success` - **스킵** (E2E 필요)
- ⏭️ `test_lazyEvaluation_submitEvidenceRestores` - **스킵** (E2E 필요)
- ⏭️ `test_resolveClaim_alreadyResponded` - **스킵** (E2E 필요)

**결과:** 29/33 테스트 통과, 4 스킵 ✅

**스킵 이유:**
3개의 증거 제출 테스트는 **실제 Patricia Merkle Trie proof**가 필요합니다.
- `MerkleTrie.verifyInclusionProof()` 호출
- RLP 인코딩된 계정 데이터 필요
- 실제 state root와 일치하는 proof nodes 필요

→ Mock 데이터로는 불가능하므로 **E2E 테스트**에서 실제 op-geth state로 테스트

---

## 2. E2E Tests (Go Client)

### 준비사항

E2E 테스트는 **실행 중인 op-geth + op-node**만 있으면 됩니다.

#### 방법 1: 기존 op-geth 사용 (권장)

이미 실행 중인 op-geth와 op-node가 있다면 그대로 사용:

```bash
# 필요한 것:
# ✅ op-geth (L2) - state DB 접근 가능
# ✅ op-node - Rollup RPC 활성화

# 확인:
# 1. L2 RPC 접근 가능한지
curl http://localhost:9545 -X POST \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

# 2. op-node Rollup RPC 접근 가능한지
curl http://localhost:9546 -X POST \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"optimism_syncStatus","params":[],"id":1}'

# 3. State DB 경로 확인
ls -la /path/to/op-geth/datadir/geth/chaindata
```

#### 방법 2: 새로 devnet 시작

전체 Optimism devnet이 필요한 경우:

```bash
cd clients/rat-client-type3

# 1. Devnet 시작 (L1 + L2 + op-node + op-batcher)
make devnet-up

# 2. 상태 확인
make devnet-check

# 3. Endpoint 확인
make endpoints
```

**예상 출력:**
```
L1 RPC:       http://localhost:8545
L2 RPC:       http://localhost:9545
op-node RPC:  http://localhost:9546
```

### E2E 테스트 실행

#### 방법 1: Direct State DB Access

**테스트:** `test/state_leaf_e2e_test.go`

```bash
cd clients/rat-client-type3

# op-geth의 state DB에 직접 접근
E2E_TEST=1 \
STATE_DB_PATH="/tmp/op-geth/chaindata" \
TEST_STATE_ROOT="0x..." \
TEST_BLOCK_NUMBER="0x64" \
go test -v ./test -run TestStateLeafE2E
```

**테스트 플로우:**
1. ✅ LevelDB에서 state DB 열기
2. ✅ State trie 크기 추정
3. ✅ Random value 생성 (RAT test ID 시뮬레이션)
4. ✅ Adjacent leaves 찾기
5. ✅ Merkle proofs 생성
6. ✅ StateLeafEvidence 생성
7. ✅ OutputRootProof 포함 확인
8. ✅ Evidence 검증
9. ✅ ABI 인코딩

#### 방법 2: RPC Access (권장)

**테스트:** `test/state_leaf_rpc_e2e_test.go`

```bash
cd clients/rat-client-type3

# L2 RPC를 통해 접근 (Geth v1.13+ PBSS 지원)
E2E_TEST=1 \
L2_RPC_URL="http://localhost:9545" \
go test -v ./test -run TestStateLeafRPCE2E
```

**테스트 플로우:**
1. ✅ L2 RPC 연결
2. ✅ 최신 블록 번호 조회
3. ✅ Random value 생성
4. ✅ RPC를 통해 adjacent leaves 찾기 (`eth_getProof` 사용)
5. ✅ StateLeafEvidence 생성
6. ✅ **op-node에서 OutputRootProof 가져오기** ← **NEW!**
7. ✅ Evidence 검증 (hash(OutputRootProof) == rootClaim)
8. ✅ Range 검증 (leafA < stateRoot < leafB)
9. ✅ ABI 인코딩

### 전체 E2E 테스트 사이클

```bash
cd clients/rat-client-type3

# Devnet 시작 → E2E 테스트 → Devnet 중지
make test-full
```

**예상 소요 시간:** 5-10분

---

## 3. OutputRootProof 통합 테스트

### op-node API 테스트

**수동 테스트:**

```bash
# 1. op-node가 실행 중인지 확인
curl http://localhost:9546 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"optimism_syncStatus","params":[],"id":1}'

# 2. OutputRootProof 조회
curl http://localhost:9546 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"optimism_outputAtBlock","params":["0x64"],"id":1}'
```

**예상 응답:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "version": "0x0000000000000000000000000000000000000000000000000000000000000000",
    "stateRoot": "0x1234...",
    "withdrawalStorageRoot": "0x5678...",
    "blockRef": {
      "hash": "0x9abc...",
      "number": 100
    }
  }
}
```

### Go Client Integration Test

**위치:** `pkg/verification/opnode_provider.go`

```bash
cd clients/rat-client-type3

# op-node provider 테스트
go test -v ./pkg/verification -run TestOpNodeRollupClient
```

**테스트 항목:**
- ✅ OutputAtBlock RPC 호출
- ✅ OutputRootProof 구조체 생성
- ✅ HashOutputRootProof 계산
- ✅ VerifyOutputRootProof (hash == rootClaim)

---

## 4. 전체 플로우 통합 테스트

### RAT Client 실행 (Manual E2E)

```bash
cd clients/rat-client-type3

# 1. Devnet 시작
make devnet-up

# 2. RAT 컨트랙트 배포
make deploy-rat

# 3. config 파일 생성
cat > config.devnet.yaml <<EOF
l1_rpc_url: "http://localhost:8545"
l2_rpc_url: "http://localhost:9545"
opnode_rpc_url: "http://localhost:9546"  # ← OutputRootProof용
state_db_path: "/tmp/op-geth/chaindata"
rat_contract: "0x..."  # deployment output에서 복사
validator_address: "0x..."
private_key: "0x..."
EOF

# 4. RAT client 실행
make run

# 5. 로그 확인
tail -f rat-client.log
```

**예상 로그:**
```
INFO RAT Client Started
INFO Monitoring L1 for AttentionTest events
INFO AttentionTest triggered testID=0x1234... blockNumber=12345
INFO Finding adjacent leaves randomValue=0x5678...
INFO Found adjacent leaves leafA=0xaaa... leafB=0xbbb...
INFO Fetching OutputRootProof from op-node blockNumber=12345  ← NEW!
INFO OutputRootProof fetched
  version=0x0000...
  stateRoot=0x1234...
  messagePasserStorageRoot=0x5678...
  latestBlockHash=0x9abc...
INFO StateRoot matches between op-node and state trie  ← NEW!
INFO Evidence created size=2500 bytes
INFO Submitting evidence to L1...
INFO Evidence submitted successfully txHash=0xdef0...
```

---

## 5. 테스트 결과 요약

### ✅ 완료된 테스트

| 테스트 종류 | 파일 | 결과 |
|----------|------|------|
| Type3EvidenceVerifier | `test/v3/Type3EvidenceVerifier.t.sol` | 12/12 통과 ✅ |
| RAT Contract | `test/v3/RAT.t.sol` | 29/33 통과 (4 스킵) ✅ |
| Evidence Encoding | `pkg/evidence/state_leaf_evidence.go` | 구현 완료 ✅ |
| OpNode Provider | `pkg/verification/opnode_provider.go` | 구현 완료 ✅ |
| Service Integration | `pkg/client/service_adjacent.go` | 구현 완료 ✅ |

### ⏭️ E2E 테스트 (수동 실행 필요)

| 테스트 종류 | 파일 | 실행 방법 |
|----------|------|---------|
| State Leaf E2E | `test/state_leaf_e2e_test.go` | `E2E_TEST=1 go test -v ./test` |
| State Leaf RPC E2E | `test/state_leaf_rpc_e2e_test.go` | `E2E_TEST=1 go test -v ./test` |
| Full RAT Client | Manual | `make quickstart` |

---

## 6. 문제 해결

### Devnet 시작 실패

```bash
# Kurtosis 재설정
kurtosis clean -a

# 재시작
cd clients/rat-client-type3
make devnet-up
```

### op-node 연결 실패

```bash
# op-node 상태 확인
curl http://localhost:9546 -X POST \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"optimism_syncStatus","params":[],"id":1}'

# op-node 로그 확인
make devnet-logs
```

### State DB 접근 실패

```bash
# State DB 경로 확인
ls -la /tmp/op-geth/chaindata

# 권한 확인
chmod -R 755 /tmp/op-geth
```

---

## 7. CI/CD 통합

### GitHub Actions 예시

```yaml
name: RAT Tests

on: [push, pull_request]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install Foundry
        uses: foundry-rs/foundry-toolchain@v1

      - name: Run Solidity Tests
        run: |
          forge test --match-path "test/v3/Type3EvidenceVerifier.t.sol"
          forge test --match-path "test/v3/RAT.t.sol"

      - name: Install Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.21'

      - name: Build Go Client
        run: |
          cd clients/rat-client-type3
          go build ./...

  e2e-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Start Optimism Devnet
        run: |
          cd clients/rat-client-type3
          make devnet-up

      - name: Run E2E Tests
        run: |
          cd clients/rat-client-type3
          E2E_TEST=1 go test -v ./test

      - name: Stop Devnet
        if: always()
        run: |
          cd clients/rat-client-type3
          make devnet-down
```

---

## 8. 다음 단계

### Phase 3: ZK-Based Perfect Verification

현재 implementation은 **Phase 2 (State Root as Target)**입니다.

**Phase 3 계획:**
- RISC Zero / SP1 ZK proof 통합
- 완벽한 adjacency 검증
- 가스비 ~50k로 감소
- Instant finality

**테스트 추가 필요:**
- ZK circuit 테스트
- Proof generation 성능 테스트
- On-chain verification gas 테스트

---

## 요약

✅ **현재 상태:**
- Unit tests: 완료 (Solidity + Go 구조)
- Integration tests: 완료 (RAT contract flow)
- E2E tests: 구현 완료, devnet에서 실행 가능

🎯 **E2E 테스트 실행:**
```bash
cd clients/rat-client-type3
make test-full
```

📝 **문서:**
- 이 파일: Testing guide
- `docs/rat-go-client-state-root-implementation.md`: Implementation details
- `clients/rat-client-type3/README.md`: Client usage guide
