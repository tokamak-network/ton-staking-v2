# op-node와 함께 RAT Client 실행 가이드

## 개요

RAT Client는 **op-node의 Rollup RPC**를 사용하여 100% trustless 검증을 수행합니다.

```
┌─────────────────────────────────────────────────────────────┐
│                    실행 순서                                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. L1 Ethereum (Sepolia/Mainnet) 준비                     │
│  2. L2 geth 실행                                            │
│  3. op-node 실행 ⭐ (L1→L2 동기화)                         │
│  4. RAT Client 실행                                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**핵심**: op-node가 L1 배치 데이터로 L2를 동기화하면, RAT Client는 op-node에 질의만 하면 됩니다!

---

## 사전 요구사항

### 1. L1 Ethereum 노드 또는 RPC

**Sepolia 테스트넷** (개발/테스트):
```bash
# Infura 사용
L1_RPC="https://sepolia.infura.io/v3/YOUR_API_KEY"
L1_BEACON="https://sepolia.beaconcha.in"
```

**Mainnet** (프로덕션):
```bash
# 자체 노드 또는 Alchemy/Infura
L1_RPC="http://localhost:8545"
L1_BEACON="http://localhost:5052"
```

### 2. L2 geth 실행

L2 geth는 op-node로부터 블록을 받아 실행합니다.

```bash
# L2 geth 실행 (engine API 활성화)
./geth \
  --datadir=/data/l2 \
  --http \
  --http.addr=0.0.0.0 \
  --http.port=8545 \
  --http.api=eth,net,web3,debug \
  --ws \
  --ws.addr=0.0.0.0 \
  --ws.port=8546 \
  --authrpc.addr=0.0.0.0 \
  --authrpc.port=8551 \
  --authrpc.jwtsecret=/data/jwt.txt \
  --syncmode=full \
  --gcmode=archive \  # Archive 모드 (선택사항, 필요시)
  --rollup.disabletxpoolgossip
```

**중요 설정**:
- `--authrpc.*`: op-node가 Engine API로 연결
- `--http.api=eth,debug`: RAT Client가 헤더 조회용으로 사용
- `--rollup.disabletxpoolgossip`: Rollup 전용 설정

---

## Step 1: op-node 실행 ⭐

op-node가 **핵심**입니다. L1 배치 데이터로 L2를 동기화합니다.

### Sepolia 테스트넷

```bash
# op-node 실행
./op-node \
  --l1=https://sepolia.infura.io/v3/YOUR_API_KEY \
  --l1.beacon=https://sepolia.beaconcha.in \
  --l2=http://localhost:8551 \
  --l2.jwt-secret=/data/jwt.txt \
  --network=op-sepolia \
  --rpc.addr=0.0.0.0 \
  --rpc.port=9545 \
  --rpc.enable-admin \
  --p2p.disable \
  --verifier.l1-confs=4 \
  --rollup.load-protocol-versions=true
```

### Mainnet

```bash
./op-node \
  --l1=http://localhost:8545 \
  --l1.beacon=http://localhost:5052 \
  --l2=http://localhost:8551 \
  --l2.jwt-secret=/data/jwt.txt \
  --network=optimism \
  --rpc.addr=0.0.0.0 \
  --rpc.port=9545 \
  --rpc.enable-admin \
  --p2p.disable \
  --verifier.l1-confs=64 \
  --rollup.load-protocol-versions=true
```

### 커스텀 Rollup (TON Staking V3)

```bash
./op-node \
  --l1=http://localhost:8545 \
  --l1.beacon=http://localhost:5052 \
  --l2=http://localhost:8551 \
  --l2.jwt-secret=/data/jwt.txt \
  --rollup.config=/path/to/rollup.json \  # 커스텀 rollup config
  --rpc.addr=0.0.0.0 \
  --rpc.port=9545 \
  --rpc.enable-admin \
  --p2p.disable \
  --verifier.l1-confs=64
```

### 핵심 파라미터 설명

| 파라미터 | 설명 |
|---------|------|
| `--l1` | L1 RPC URL (배치 데이터 소스) |
| `--l1.beacon` | L1 Beacon API (EIP-4844 blob용) |
| `--l2` | L2 geth Engine API URL (JWT 인증) |
| `--rpc.addr` | Rollup RPC 바인딩 주소 |
| `--rpc.port` | **Rollup RPC 포트 (9545)** ⭐ |
| `--network` | 네트워크 (op-sepolia, optimism, base 등) |
| `--rollup.config` | 커스텀 rollup config 파일 |
| `--verifier.l1-confs` | L1 confirmations (테스트넷: 4, 메인넷: 64) |

### op-node 동기화 확인

```bash
# Sync 상태 확인
curl -X POST http://localhost:9545 \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "optimism_syncStatus",
    "params": [],
    "id": 1
  }' | jq
```

**결과 예시**:
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "current_l1": {
      "hash": "0x...",
      "number": 5000000
    },
    "head_l1": {
      "hash": "0x...",
      "number": 5000100
    },
    "safe_l2": {
      "hash": "0x...",
      "number": 12000000
    },
    "finalized_l2": {
      "hash": "0x...",
      "number": 11999000
    }
  }
}
```

**동기화 완료 조건**:
- `safe_l2.number`가 계속 증가함
- `current_l1.number ≈ head_l1.number` (거의 따라잡음)

---

## Step 2: RAT Client 실행

op-node가 동기화 중이면 RAT Client를 실행할 수 있습니다.

### 설정 파일 작성

```yaml
# config.yaml
verification_mode: opnode

opnode:
  rollup_rpc: "http://localhost:9545"  # op-node Rollup RPC
  max_wait_time: 30m
  check_interval: 10s

l1:
  rpc_url: "http://localhost:8545"
  beacon_url: "http://localhost:5052"

l2:
  rpc_url: "http://localhost:8545"  # L2 geth (보조용)

contracts:
  rat_contract: "0x..."
  system_config: "0x..."
  dispute_game_factory: "0x..."
  l1_bridge_registry: "0x..."
  batch_inbox: "0xff03000000000000000000000000000000000000"
  batcher_address: "0x..."

validator:
  private_key: "${VALIDATOR_PRIVATE_KEY}"
  address: "0x..."

rat:
  poll_interval: 12s
  deadline_buffer: 10m
  max_gas_price: 100
```

### RAT Client 실행

```bash
# 환경 변수 설정
export VALIDATOR_PRIVATE_KEY="0x..."

# RAT Client 실행
./rat-client-type3 --config config.yaml
```

### 로그 예시

```
2024-01-09 10:00:00 INFO  Starting RAT Client (op-node mode)
2024-01-09 10:00:00 INFO  Connecting to op-node at http://localhost:9545
2024-01-09 10:00:01 INFO  op-node sync status: safe_l2=12000000, finalized_l2=11999000
2024-01-09 10:00:01 INFO  Connecting to L1 at http://localhost:8545
2024-01-09 10:00:01 INFO  RAT Contract: 0x...
2024-01-09 10:00:01 INFO  Monitoring RAT events (poll interval: 12s)

2024-01-09 10:05:23 INFO  📢 AttentionTestTriggered detected!
2024-01-09 10:05:23 INFO     testId: 0x123...
2024-01-09 10:05:23 INFO     validator: 0xabc...
2024-01-09 10:05:23 INFO     L2 block: 12001000
2024-01-09 10:05:23 INFO     deadline: 2024-01-09 11:05:23

2024-01-09 10:05:23 INFO  Checking if op-node is synced to block 12001000...
2024-01-09 10:05:23 INFO  ✅ op-node is synced (safe_l2=12001500)

2024-01-09 10:05:24 INFO  Querying op-node for output root at block 12001000...
2024-01-09 10:05:24 INFO  ✅ Verification PASSED: output roots match
2024-01-09 10:05:24 INFO     Computed: 0xdef...
2024-01-09 10:05:24 INFO     Claimed:  0xdef...
2024-01-09 10:05:24 INFO  Verification completed in 1.2s

2024-01-09 10:05:25 INFO  ✅ Valid state root - no evidence needed
```

---

## 동작 흐름

### RAT 이벤트 발생 시

```
1. RAT Contract에서 AttentionTestTriggered 이벤트 발생
   ├─ testId: 0x123...
   ├─ validator: 0xabc...
   ├─ L2 block: 12001000
   └─ deadline: 1 hour later

2. RAT Client 이벤트 감지
   └─ "블록 12001000을 검증해야 함"

3. op-node 동기화 확인
   ├─ safe_l2 = 12001500 (✅ 이미 동기화됨!)
   └─ 또는 safe_l2 = 12000800 (⏰ 아직 안 됨, 대기 필요)

4. op-node에 질의 (Rollup RPC)
   ├─ optimism_outputAtBlock(12001000)
   └─ → { outputRoot: 0xdef..., stateRoot: 0x456..., ... }

5. 비교
   ├─ Computed (op-node): 0xdef...
   ├─ Claimed (RAT event): 0xdef...
   └─ → Match! ✅

6. 결과
   ├─ Match → No action needed (valid state)
   └─ Mismatch → Generate evidence + Submit to RAT contract
```

### op-node가 아직 동기화 안 된 경우

```
3. op-node 동기화 확인
   └─ safe_l2 = 12000800 (target: 12001000, behind by 200 blocks)

4. 대기 (max_wait_time: 30분 이내)
   ├─ 10초마다 sync 상태 확인
   ├─ safe_l2 = 12000850... (계속 증가)
   ├─ safe_l2 = 12000900...
   └─ safe_l2 = 12001050 (✅ 동기화 완료!)

5. op-node에 질의
   └─ optimism_outputAtBlock(12001000)
```

---

## 트러블슈팅

### 1. op-node 연결 실패

**증상**:
```
ERROR Failed to connect to op-node: dial tcp 127.0.0.1:9545: connection refused
```

**해결**:
- op-node가 실행 중인지 확인
- `--rpc.addr=0.0.0.0 --rpc.port=9545` 설정 확인
- 방화벽 설정 확인

```bash
# op-node 프로세스 확인
ps aux | grep op-node

# 포트 확인
netstat -tlnp | grep 9545
```

### 2. op-node 동기화 안 됨

**증상**:
```
WARN op-node not synced yet: safe_l2=0, target=12001000
```

**해결**:
- op-node가 충분히 동기화될 때까지 대기 (수 시간~수 일)
- L1 RPC 연결 확인
- L2 geth 상태 확인

```bash
# op-node 로그 확인
tail -f /var/log/op-node.log

# L2 geth 연결 확인
curl http://localhost:8551  # JWT 에러가 정상 (op-node만 접근 가능)
```

### 3. 동기화 타임아웃

**증상**:
```
ERROR op-node sync timeout: context deadline exceeded
```

**원인**:
- op-node 동기화가 너무 느림
- L1 블록 진행이 빠름 (타겟 블록이 계속 증가)

**해결**:
- `max_wait_time` 증가 (config.yaml)
- op-node 성능 개선 (더 빠른 L1 RPC 사용)
- DisputeGame fallback 사용

### 4. RPC 응답 오류

**증상**:
```
ERROR optimism_outputAtBlock(12001000) failed: method not found
```

**해결**:
- op-node 버전 확인 (최신 버전 필요)
- `--rpc.enable-admin` 플래그 확인

---

## 성능 최적화

### 1. op-node 성능 개선

**L1 RPC 최적화**:
- 자체 L1 노드 운영 (가장 빠름)
- Premium RPC 사용 (Alchemy, Infura)
- 여러 L1 RPC 병렬 사용 (fallback)

**하드웨어**:
```
권장 사양 (op-node):
- CPU: 4+ cores
- RAM: 16+ GB
- Disk: 500+ GB SSD (archive 모드)
- Network: 1 Gbps
```

### 2. RAT Client 설정

```yaml
opnode:
  max_wait_time: 20m  # 동기화 대기 시간 줄임
  check_interval: 5s  # 확인 빈도 증가

rat:
  poll_interval: 6s   # 이벤트 폴링 빈도 증가
```

---

## 모니터링

### 1. op-node 헬스체크

```bash
#!/bin/bash
# opnode-healthcheck.sh

ROLLUP_RPC="http://localhost:9545"

# Sync 상태 조회
SYNC_STATUS=$(curl -s -X POST $ROLLUP_RPC \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"optimism_syncStatus","params":[],"id":1}')

SAFE_L2=$(echo $SYNC_STATUS | jq -r '.result.safe_l2.number')
HEAD_L1=$(echo $SYNC_STATUS | jq -r '.result.head_l1.number')
CURRENT_L1=$(echo $SYNC_STATUS | jq -r '.result.current_l1.number')

echo "op-node Health:"
echo "  Safe L2: $SAFE_L2"
echo "  Current L1: $CURRENT_L1"
echo "  Head L1: $HEAD_L1"
echo "  L1 Behind: $(($HEAD_L1 - $CURRENT_L1))"

# Alert if too far behind
if [ $(($HEAD_L1 - $CURRENT_L1)) -gt 100 ]; then
  echo "⚠️  WARNING: op-node is >100 blocks behind L1 head!"
fi
```

### 2. Prometheus Metrics

op-node와 RAT Client 모두 metrics 노출:

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'opnode'
    static_configs:
      - targets: ['localhost:7300']  # op-node metrics

  - job_name: 'rat-client'
    static_configs:
      - targets: ['localhost:7301']  # RAT client metrics
```

---

## 프로덕션 배포

### Docker Compose 예시

```yaml
version: '3.8'

services:
  l2-geth:
    image: us-docker.pkg.dev/oplabs-tools-artifacts/images/op-geth:latest
    command:
      - --datadir=/data
      - --http
      - --http.addr=0.0.0.0
      - --http.port=8545
      - --authrpc.addr=0.0.0.0
      - --authrpc.port=8551
      - --authrpc.jwtsecret=/data/jwt.txt
    volumes:
      - ./data/l2:/data
    ports:
      - "8545:8545"

  op-node:
    image: us-docker.pkg.dev/oplabs-tools-artifacts/images/op-node:latest
    command:
      - --l1=${L1_RPC}
      - --l1.beacon=${L1_BEACON}
      - --l2=http://l2-geth:8551
      - --l2.jwt-secret=/data/jwt.txt
      - --network=op-sepolia
      - --rpc.addr=0.0.0.0
      - --rpc.port=9545
    volumes:
      - ./data/l2:/data
    ports:
      - "9545:9545"
    depends_on:
      - l2-geth

  rat-client:
    image: rat-client-type3:latest
    command:
      - --config=/config/config.yaml
    volumes:
      - ./config.yaml:/config/config.yaml
    environment:
      - VALIDATOR_PRIVATE_KEY=${VALIDATOR_PRIVATE_KEY}
    depends_on:
      - op-node
```

---

## 결론

**핵심 포인트**:

1. ✅ **op-node를 먼저 실행** (L1→L2 동기화)
2. ✅ **op-node가 동기화되면 RAT Client 실행**
3. ✅ **RAT Client는 op-node에 질의만** (100% trustless!)

**장점**:
- 검증된 Optimism 코드 사용
- 100% trustless (L1 data only)
- 빠른 검증 (1-10초)
- 즉시 사용 가능

**다음 단계**:
- [x] op-node 설치 및 실행
- [x] RAT Client 설정
- [ ] 테스트넷에서 테스트
- [ ] 메인넷 배포
