# Simple RAT Client Test Plan (Mock-based)

## 개요

Kurtosis 없이 간단하게 RAT Client를 테스트하는 방법입니다.

**핵심 아이디어**:
- L1만 Anvil로 실제 실행
- L2, Batcher, Proposer는 Mock 또는 최소 구성
- RAT Client 핵심 로직만 집중 테스트

## 아키텍처

```
┌─────────────────────────────────────────────────┐
│              L1 (Anvil)                         │
│  - Genesis에 모든 컨트랙트 포함                   │
│  - DisputeGameFactory, RAT, SystemConfig 등      │
├─────────────────────────────────────────────────┤
│  Mock Batch Submissions (cast send)             │
│  ↓                                              │
│  Batch Inbox (0xff00...0998)                    │
└─────────────────────────────────────────────────┘
         │
         │ L1 batch data
         ▼
┌─────────────────────────────────────────────────┐
│         op-node (Follower Mode)                 │
│  - L1에서 batch 읽기                             │
│  - L2 상태 재구성                                │
│  - Rollup RPC 제공                               │
└─────────────────────────────────────────────────┘
         │
         │ Rollup RPC
         ▼
┌─────────────────────────────────────────────────┐
│            RAT Client                           │
│  - L1 RPC로 RAT 컨트랙트 모니터링                │
│  - Rollup RPC로 L2 상태 검증                     │
│  - Evidence 생성 및 제출                         │
└─────────────────────────────────────────────────┘
```

## 옵션별 비교

### 옵션 A: Full Mock (가장 간단)
```
L1 (Anvil) ✅
  └─> RAT Client (L1만 모니터링)

장점: 매우 간단
단점: L2 검증 로직 테스트 불가
```

### 옵션 B: op-node 포함 (권장)
```
L1 (Anvil) ✅
  └─> op-node (follower) ✅
      └─> RAT Client

장점: L2 상태 검증 가능
단점: op-node 설정 필요
```

### 옵션 C: Full Stack (복잡)
```
L1 (Anvil) ✅
  └─> op-geth (L2) ✅
      └─> op-node ✅
          ├─> op-batcher ✅
          ├─> op-proposer ✅
          └─> RAT Client ✅

장점: 완전한 테스트
단점: 복잡함 (Kurtosis와 유사한 문제)
```

## 옵션 B 구현 계획 (권장)

### 사전 준비

#### 1. Genesis 파일 생성 (이미 완료)
```bash
make devnet-allocs-offline
# → .devnet/genesis-l1-staking-v3.json
# → .devnet/allocs-l1-staking-v3.json
```

#### 2. Rollup 설정 파일 필요
`rollup.json` - op-node가 L2 체인을 어떻게 구성할지 정의

**필요한 정보**:
- Genesis hash
- L2 chain ID
- Block time
- Batch inbox address
- SystemConfig address

### 단계별 실행

#### Step 1: L1 시작
```bash
# Terminal 1: L1 (Anvil)
anvil \
  --init .devnet/genesis-l1-staking-v3.json \
  --host 0.0.0.0 \
  --port 8545 \
  --block-time 2
```

**확인**:
```bash
cast block-number --rpc-url http://localhost:8545
# 출력: 0 (또는 블록 번호)

# RAT 컨트랙트 확인
export RAT_PROXY=0xBa3e08b4753E68952031102518379ED2fDADcA30
cast code $RAT_PROXY --rpc-url http://localhost:8545
# 출력: 0x... (bytecode)
```

#### Step 2: Rollup 설정 생성

`.devnet/rollup.json` 생성:
```json
{
  "genesis": {
    "l1": {
      "hash": "0x...",
      "number": 0
    },
    "l2": {
      "hash": "0x...",
      "number": 0
    },
    "l2_time": 0,
    "system_config": {
      "batcherAddr": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
      "overhead": "0x0",
      "scalar": "0x0",
      "gasLimit": 30000000
    }
  },
  "block_time": 2,
  "max_sequencer_drift": 600,
  "seq_window_size": 3600,
  "channel_timeout": 300,
  "l1_chain_id": 900,
  "l2_chain_id": 2151908,
  "batch_inbox_address": "0xff00000000000000000000000000000000000998",
  "deposit_contract_address": "0x...",
  "l1_system_config_address": "0xc3f34628df2e60dfcb26b17ffd027133f87517ec"
}
```

#### Step 3: op-node 시작 (follower mode)

```bash
# Terminal 2: op-node
op-node \
  --l1=http://localhost:8545 \
  --l2=http://localhost:9545 \
  --rollup.config=.devnet/rollup.json \
  --rpc.addr=0.0.0.0 \
  --rpc.port=9545 \
  --rpc.enable-admin \
  --l1.trustrpc \
  --sequencer.l1-confs=0 \
  --verifier.l1-confs=0
```

**Note**: follower mode이므로 `--sequencer.enabled=false` (default)

**확인**:
```bash
# Rollup RPC 확인
curl -X POST \
  -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"optimism_syncStatus","params":[],"id":1}' \
  http://localhost:9545
```

#### Step 4: Mock batch 제출

```bash
# L1에 batch data 제출
export BATCH_INBOX=0xff00000000000000000000000000000000000998
export BATCHER_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Mock batch (실제로는 압축된 L2 블록 데이터)
cast send $BATCH_INBOX \
  --rpc-url http://localhost:8545 \
  --private-key $BATCHER_KEY \
  --gas-limit 1000000 \
  0x0000000000000001  # Mock data
```

**op-node가 자동으로**:
1. L1에서 batch 감지
2. Batch 디코딩
3. L2 블록 재구성
4. Rollup RPC로 제공

#### Step 5: RAT Client 실행

```bash
# Terminal 3: RAT Client
./bin/rat-client \
  --l1-rpc http://localhost:8545 \
  --rollup-rpc http://localhost:9545 \
  --rat-contract $RAT_PROXY \
  --private-key 0x... \
  --poll-interval 10s
```

**RAT Client가 할 일**:
1. L1의 RAT 컨트랙트 이벤트 모니터링
2. AttentionTestTriggered 감지
3. Rollup RPC에서 L2 상태 조회
4. Evidence 생성 및 검증
5. L1에 Evidence 제출

## 간소화된 버전 (옵션 A)

op-node 없이 RAT 컨트랙트 연동만 테스트:

```bash
# 1. L1만 시작
anvil --init .devnet/genesis-l1-staking-v3.json --port 8545

# 2. RAT 컨트랙트 직접 호출 테스트
export RAT=0xBa3e08b4753E68952031102518379ED2fDADcA30

# triggerProbability 확인
cast call $RAT "triggerProbability()(uint256)" --rpc-url http://localhost:8545

# DisputeGameFactory 연동 확인
export DGF=0x21880f37f66d5be00d91d9fd30fed732063d2250
cast call $DGF "rat()(address)" --rpc-url http://localhost:8545
# 출력: 0xBa3e08b4753E68952031102518379ED2fDADcA30

# 3. Mock으로 AttentionTest 트리거 (수동)
cast send $RAT \
  "triggerAttentionTest(address,address,uint32,bytes32,bytes32)" \
  0x1234... \  # gameAddress
  0xc3f3... \  # systemConfig
  1 \          # batchIndex
  0x00...01 \  # batchHash
  0x00...02 \  # blockHash
  --rpc-url http://localhost:8545 \
  --private-key $KEY
```

## 자동화 스크립트

### scripts/test-rat-simple.sh

```bash
#!/bin/bash
# 옵션 A: RAT 컨트랙트 기본 테스트

# 1. L1 시작
anvil --init .devnet/genesis-l1-staking-v3.json --port 8545 &
ANVIL_PID=$!

sleep 3

# 2. 컨트랙트 확인
source .devnet.env
./scripts/verify-rat-deployment.sh

# 3. Mock trigger
./scripts/mock-attention-test.sh

# 4. Cleanup
kill $ANVIL_PID
```

### scripts/test-rat-with-opnode.sh

```bash
#!/bin/bash
# 옵션 B: op-node 포함 전체 테스트

# 1. L1 시작
anvil --init .devnet/genesis-l1-staking-v3.json --port 8545 &

# 2. rollup.json 생성
./scripts/generate-rollup-config.sh

# 3. op-node 시작
op-node \
  --l1=http://localhost:8545 \
  --rollup.config=.devnet/rollup.json \
  --rpc.addr=0.0.0.0 \
  --rpc.port=9545 &

# 4. Mock batch 제출
./scripts/submit-mock-batch.sh

# 5. RAT Client 시작
./bin/rat-client \
  --l1-rpc http://localhost:8545 \
  --rollup-rpc http://localhost:9545 \
  --rat-contract $RAT_PROXY

# 6. Cleanup
killall anvil op-node
```

## 필요한 추가 작업

### 1. rollup.json 생성기
`scripts/generate-rollup-config.sh`:
- Genesis hash 추출
- Contract 주소 자동 설정
- L1/L2 chain ID 설정

### 2. Mock batch 생성기
`scripts/submit-mock-batch.sh`:
- 유효한 batch data 포맷 생성
- Batch compression
- L1에 제출

### 3. RAT verification helper
`scripts/verify-rat-deployment.sh`:
- RAT 컨트랙트 배포 확인
- DisputeGameFactory 연동 확인
- 파라미터 검증

### 4. RAT Client config generator
`scripts/generate-rat-client-config.sh`:
- RPC URLs
- Contract addresses
- Private keys (from devnet accounts)

## 예상 출력

### 성공 케이스
```
=== Simple RAT Test ===

[1/5] L1 (Anvil)
  ✓ Started on port 8545
  ✓ Block 0 (genesis)
  ✓ RAT contract deployed at 0xBa3e...

[2/5] op-node
  ✓ Started on port 9545
  ✓ Connected to L1
  ✓ Syncing from batch inbox

[3/5] Mock batch submission
  ✓ Batch submitted to L1 (tx: 0x123...)
  ✓ op-node detected batch
  ✓ L2 block derived

[4/5] RAT Client
  ✓ Connected to L1 RPC
  ✓ Connected to Rollup RPC
  ✓ Monitoring AttentionTestTriggered events

[5/5] Verification
  ✓ Attention test triggered
  ✓ Evidence generated
  ✓ Evidence submitted to L1
  ✓ Verification passed

=== Test Complete ===
```

## 다음 단계

1. **Phase 1: 기본 연동 테스트** (옵션 A)
   - L1 + RAT 컨트랙트만
   - 수동 trigger 테스트
   - 예상 소요: 1-2시간

2. **Phase 2: rollup.json 생성**
   - Genesis hash 추출
   - 자동 설정 스크립트
   - 예상 소요: 2-3시간

3. **Phase 3: op-node 통합** (옵션 B)
   - op-node 시작
   - Mock batch 제출
   - 예상 소요: 3-4시간

4. **Phase 4: RAT Client 테스트**
   - 전체 플로우 검증
   - 예상 소요: 2-3시간

**총 예상**: 8-12시간

## 참고사항

- **op-node binary**: `lib/optimism/op-node/bin/op-node` 또는 Docker 이미지
- **Batch format**: 실제 batch는 RLP 인코딩된 압축 데이터
- **rollup.json**: Optimism 저장소의 `devnetL1.json` 참고
- **Gas 문제**: Mock batch 제출 시 충분한 gas limit 설정 필요

## 트러블슈팅

### op-node 시작 실패
```
Error: missing l2 genesis
```
→ `rollup.json`에 l2 genesis hash 추가 필요

### Batch 제출 실패
```
Error: Out of gas
```
→ `--gas-limit 1000000` 추가

### RAT Client 연결 실패
```
Error: connection refused
```
→ RPC 포트 확인, 방화벽 설정 확인
