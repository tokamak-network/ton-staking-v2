# 배포 및 운영

## 6.1 필수 인프라

### 전체 구조

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

### 핵심 원칙

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

## 6.2 왜 Archive Mode가 필수인가?

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

## 6.3 왜 Debug API가 필수인가?

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

## 6.4 각 컴포넌트 상세

### 1. L1 RPC 접근

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

### 2. op-node (Follower Mode) ⭐ 권장 (Validator Best Practice)

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

### 3. op-geth (Archive + Debug) ⭐ 필수

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

### 4. RAT Client

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

## 6.5 시스템 사양

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

## 6.6 배포 단계

### Step 1: JWT Secret 생성 (필수)

```bash
openssl rand -hex 32 > /data/jwt.hex
```

**중요**: op-node와 op-geth가 같은 JWT secret을 공유해야 Engine API 인증 가능

### Step 2: Rollup Config 준비 (필수)

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

### Step 3: op-geth 시작 (필수)

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

### Step 4: op-node 시작 (필수)

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

### Step 5: debug API 테스트 (필수)

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

### Step 6: RAT Client 설정

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

### Step 7: RAT Client 시작

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
