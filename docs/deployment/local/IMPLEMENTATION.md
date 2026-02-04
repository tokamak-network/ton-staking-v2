# TON Staking V3 로컬 환경 구축 - 구현 상세

이 문서는 TON Staking V3 로컬 개발 환경의 기술적 구현 상세를 설명합니다.

> **Note**: 일반 사용자는 [빠른 시작 가이드](./QUICKSTART.md)를 먼저 참조하세요. 이 문서는 시스템 내부 동작, 문제 해결 과정, 설계 결정을 이해하고자 하는 개발자를 위한 문서입니다.

## 목차

- [아키텍처 개요](#아키텍처-개요)
- [Docker Compose 서비스 구성](#docker-compose-서비스-구성)
- [Genesis 파일 구조](#genesis-파일-구조)
- [시작 스크립트 동작 순서](#시작-스크립트-동작-순서)
- [발생한 문제와 해결 방법](#발생한-문제와-해결-방법)
- [성능 고려사항](#성능-고려사항)
- [참고 자료](#참고-자료)

## 아키텍처 개요

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Docker Compose Network                          │
│                     (ton-staking-network)                              │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  ┌─────────────────────┐       ┌──────────────────────────────────┐  │
│  │        L1           │       │              L2                   │  │
│  │  (Geth Clique PoA)  │       │                                   │  │
│  │                     │       │  ┌─────────────┐ ┌─────────────┐ │  │
│  │  - Chain ID: 900    │◄──────┤  │   op-geth   │ │   op-node   │ │  │
│  │  - Port: 8545/8546  │       │  │  (execution)│ │  (consensus)│ │  │
│  │  - Auto-mining ~1s  │       │  │  Port: 9545 │ │  Port: 7545 │ │  │
│  │                     │       │  └──────┬──────┘ └──────┬──────┘ │  │
│  │  TON Staking V3     │       │         │               │         │  │
│  │  Contracts:         │       │         │    JWT Auth   │         │  │
│  │  - TON/WTON         │       │         └───────────────┘         │  │
│  │  - SeigManager      │       │                                   │  │
│  │  - DepositManager   │       │  ┌─────────────┐ ┌─────────────┐ │  │
│  │  - Layer2Manager    │       │  │  op-batcher │ │ op-proposer │ │  │
│  │  - RAT              │       │  │             │ │             │ │  │
│  │  - ValidatorReward  │       │  └─────────────┘ └─────────────┘ │  │
│  │                     │       │                                   │  │
│  │  Optimism L1        │       │  Chain ID: 901                   │  │
│  │  Contracts:         │       │  Block Time: 2s                  │  │
│  │  - OptimismPortal   │       │                                   │  │
│  │  - SystemConfig     │       └──────────────────────────────────┘  │
│  │  - L1Bridge         │                                             │
│  └─────────────────────┘                                             │
│                                                                        │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │                      RAT Clients (3개)                           │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │  │
│  │  │ rat-client-1│  │ rat-client-2│  │ rat-client-3│             │  │
│  │  │ (Account #2)│  │ (Account #3)│  │ (Account #4)│             │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘             │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

## Docker Compose 서비스 구성

### 1. L1 서비스 (Geth with Clique PoA)

```yaml
l1:
  image: ethereum/client-go:v1.13.15
  platform: linux/amd64
  container_name: ton-staking-l1
  ports:
    - "8545:8545"    # HTTP RPC
    - "8546:8546"    # WebSocket
  volumes:
    - l1-data:/datadir
    - ./.devnet:/genesis
  command:
    - |
      # Initialize with custom genesis if not already done
      if [ ! -d /datadir/geth ]; then
        geth init --datadir=/datadir /genesis/genesis-l1-staking-v3.json
      fi
      
      # Import clique signer account
      echo "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80" > /tmp/pk.txt
      geth account import --datadir=/datadir --password=/tmp/password.txt /tmp/pk.txt
      
      # Start Geth with clique mining
      exec geth \
        --datadir=/datadir \
        --http --http.addr=0.0.0.0 --http.port=8545 \
        --http.api=eth,net,web3,debug,admin,personal,txpool,miner,clique \
        --ws --ws.addr=0.0.0.0 --ws.port=8546 \
        --ws.api=eth,net,web3,debug,txpool \
        --networkid=900 \
        --unlock=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
        --mine \
        --miner.etherbase=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
        --allow-insecure-unlock
```

**주요 설정 사항:**

- `platform: linux/amd64`: Apple Silicon (ARM64) 호환성을 위해 필수
- **Geth v1.13.15**: Clique PoA 합의 알고리즘 지원
- **Clique PoA**: Beacon client 없이 블록 생성 가능
- `--mine`: 자동 채굴 활성화 (~1초 간격)
- `--http.api`: debug, admin, clique API 포함
- `--ws`: WebSocket 지원 (포트 8546)
- **op-node 호환**: block hash를 blockTag로 사용 가능

**Anvil 대신 Geth를 사용하는 이유:**

- op-node는 `eth_getBlockByHash`를 blockTag로 요구하는데, Anvil은 이 기능을 지원하지 않음
- Geth는 Clique PoA로 Beacon API 없이도 블록 자동 생성 가능
- 프로덕션 환경과 더 유사한 동작

### 2. L2 Execution 서비스 (op-geth)

```yaml
l2-execution:
  image: us-docker.pkg.dev/oplabs-tools-artifacts/images/op-geth:latest
  platform: linux/amd64
  ports:
    - "9545:8545"      # HTTP RPC
    - "9546:8546"      # WebSocket
  volumes:
    - l2-execution-data:/data
    - ./.devnet:/genesis
  command:
    - |
      echo "Initializing L2 geth with genesis..."
      rm -rf /data/geth /data/geth.ipc
      geth init --datadir=/data /genesis/genesis-l2.json
      exec geth \
        --datadir=/data \
        --http --http.addr=0.0.0.0 --http.port=8545 \
        --http.api=eth,net,web3,debug,txpool,trace \
        --ws --ws.addr=0.0.0.0 --ws.port=8546 \
        --ws.api=eth,net,web3,debug,txpool,trace \
        --authrpc.addr=0.0.0.0 --authrpc.port=8551 \
        --authrpc.jwtsecret=/genesis/jwt-secret.txt \
        --syncmode=full \
        --gcmode=archive \
        --networkid=901 \
        --rollup.disabletxpoolgossip=true
```

**주요 설정 사항:**

- `rm -rf /data/geth`: 매 시작 시 genesis 재초기화 (일관된 상태 보장)
- `--authrpc.jwtsecret`: op-node와의 인증 통신에 필요
- `--rollup.disabletxpoolgossip=true`: 롤업 모드 활성화
- `--gcmode=archive`: 전체 상태 히스토리 보관 (RAT Client 필요)
- `--http.api=...,trace`: **trace API 추가** (트랜잭션 추적용)
- `--ws.api=...,trace`: WebSocket에도 trace API 지원

**Debug/Trace API가 필요한 이유:**

- RAT Client가 `debug_accountRange` 사용
- 트랜잭션 추적 및 디버깅

### 3. L2 Node 서비스 (op-node)

```yaml
l2-node:
  image: us-docker.pkg.dev/oplabs-tools-artifacts/images/op-node:v1.7.0
  platform: linux/amd64
  depends_on:
    l1:
      condition: service_healthy
    l2-execution:
      condition: service_healthy
  ports:
    - "7545:8545"      # RPC
  volumes:
    - ./.devnet:/genesis
  command:
    - |
      exec op-node \
        --l1=http://l1:8545 \
        --l1.rpckind=basic \
        --l1.trustrpc \
        --l1.beacon.ignore \
        --l2=http://l2-execution:8551 \
        --l2.jwt-secret=/genesis/jwt-secret.txt \
        --rollup.config=/genesis/rollup.json \
        --rpc.addr=0.0.0.0 \
        --p2p.disable \
        --sequencer.enabled \
        --sequencer.l1-confs=0 \
        --verifier.l1-confs=0
```

**버전 선택 이유:**

- `v1.7.0` 버전 사용: 최신 버전(v1.16.6+)은 L1 Beacon API를 필수로 요구
- 로컬 Geth Clique PoA 환경에서는 Beacon API가 없으므로 이전 버전 사용
- `--l1.beacon.ignore`: Beacon API 요구사항 무시

**주요 플래그:**

- `--l1.trustrpc`: L1 RPC를 신뢰 (로컬 환경)
- `--sequencer.l1-confs=0`: L1 블록 확인 대기 없음 (빠른 개발)
- `--verifier.l1-confs=0`: 검증 시 L1 블록 확인 대기 없음

### 4. L2 Batcher 서비스

```yaml
l2-batcher:
  image: us-docker.pkg.dev/oplabs-tools-artifacts/images/op-batcher:latest
  platform: linux/amd64
  environment:
    - OP_BATCHER_L1_ETH_RPC=http://l1:8545
    - OP_BATCHER_L2_ETH_RPC=http://l2-execution:8545
    - OP_BATCHER_ROLLUP_RPC=http://l2-node:8545
    - OP_BATCHER_POLL_INTERVAL=1s
    - OP_BATCHER_PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

**역할:** L2 트랜잭션을 배치로 묶어서 L1에 제출

### 5. L2 Proposer 서비스

```yaml
l2-proposer:
  image: us-docker.pkg.dev/oplabs-tools-artifacts/images/op-proposer:latest
  platform: linux/amd64
  environment:
    - OP_PROPOSER_L1_ETH_RPC=http://l1:8545
    - OP_PROPOSER_ROLLUP_RPC=http://l2-node:8545
    - OP_PROPOSER_GAME_FACTORY_ADDRESS=0x52d01b38b78b559142B04CC19F5cC50D5C03dbAc
    - OP_PROPOSER_PRIVATE_KEY=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
    - OP_PROPOSER_PROPOSAL_INTERVAL=12s
```

**역할:** L2 상태 루트를 L1에 제안

### 6. RAT Client 서비스 (3개)

```yaml
rat-client-1:
  build:
    context: ./clients/rat-client-type3
    dockerfile: Dockerfile
  environment:
    - L1_RPC_URL=http://l1:8545
    - L2_RPC_URL=http://l2-execution:8545
    - PRIVATE_KEY=0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a  # Account #2
    - POLL_INTERVAL=10
```

**역할:** Validator로서 L2 상태를 모니터링하고 RAT 컨트랙트에 보고

**3개 실행 이유:** 다중 Validator 환경 시뮬레이션

## Genesis 파일 구조

### L1 Genesis (genesis-l1-staking-v3.json)

```json
{
  "config": {
    "chainId": 900,
    "homesteadBlock": 0,
    "eip155Block": 0,
    "londonBlock": 0,
    "shanghaiTime": 0,
    "cancunTime": 0,
    "terminalTotalDifficulty": 0,
    "terminalTotalDifficultyPassed": true,
    "clique": {
      "period": 0,
      "epoch": 30000
    }
  },
  "alloc": {
    "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266": {
      "balance": "0x21e19e0c9bab2400000"
    },
    "0xTON_CONTRACT_ADDRESS": {
      "code": "0x...",
      "storage": { ... },
      "balance": "0x0"
    }
    // ... 모든 컨트랙트와 계정
  },
  "extraData": "0x0000000000000000000000000000000000000000000000000000000000000000f39Fd6e51aad88F6F4ce6aB8827279cffFb922660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
}
```

**주요 필드:**

- `clique.period`: 0 = 트랜잭션이 있을 때만 블록 생성
- `extraData`: Clique 서명자 주소 포함
- `alloc`: Genesis 시점의 모든 컨트랙트 및 계정 상태

### L2 Genesis (genesis-l2.json)

```json
{
  "config": {
    "chainId": 901,
    "terminalTotalDifficulty": 0,
    "terminalTotalDifficultyPassed": true,
    "bedrockBlock": 0,
    "regolithTime": 0,
    "canyonTime": 0,
    "shanghaiTime": 0,
    "deltaTime": 0,
    "optimism": {
      "eip1559Elasticity": 6,
      "eip1559Denominator": 50,
      "eip1559DenominatorCanyon": 250
    }
  },
  "gasLimit": "0x1c9c380",
  "baseFeePerGas": "0x3b9aca00",
  "alloc": {
    "0x4200000000000000000000000000000000000015": {
      "code": "0x",
      "storage": {},
      "balance": "0x0"
    }
  }
}
```

**필수 설정:**

- `shanghaiTime`: `canyonTime`과 동일해야 함
- `optimism.eip1559DenominatorCanyon`: Canyon 포크에서 필수
- Optimism 특수 주소들 (0x4200...) 포함

### Rollup Config (rollup.json)

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
    "l2_time": 1707091441,
    "system_config": {
      "batcherAddr": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
      "overhead": "0x0000000000000000000000000000000000000000000000000000000000000834",
      "scalar": "0x01000000000000000000000000000000000000000000000000000fa000000000",
      "gasLimit": 30000000
    }
  },
  "block_time": 2,
  "max_sequencer_drift": 600,
  "seq_window_size": 3600,
  "channel_timeout": 300,
  "l1_chain_id": 900,
  "l2_chain_id": 901,
  "regolith_time": 0,
  "canyon_time": 0,
  "delta_time": 0,
  "batch_inbox_address": "0xff00000000000000000000000000000000000901",
  "deposit_contract_address": "0x...",
  "l1_system_config_address": "0x..."
}
```

**동적 생성 필드:**

- `genesis.l1.hash`: L1 genesis 블록 해시 (런타임에 조회)
- `genesis.l2.hash`: L2 genesis 블록 해시 (런타임에 조회)
- `deposit_contract_address`: OptimismPortalProxy 주소
- `l1_system_config_address`: SystemConfig 주소

## 시작 스크립트 동작 순서

`scripts/start-persistent-devnet.sh`는 다음 순서로 실행됩니다:

### Step 1: 사전 검사

```bash
# Docker, jq, cast 설치 확인
# genesis-l1-staking-v3.json 존재 확인
# optimism-addresses.json 존재 확인
```

### Step 2: JWT Secret 생성

```bash
if [ ! -f "$DEVNET_DIR/jwt-secret.txt" ]; then
    openssl rand -hex 32 > "$DEVNET_DIR/jwt-secret.txt"
fi
```

**용도:** op-geth와 op-node 간 인증

### Step 3: L1 시작

```bash
docker-compose up -d l1

# L1 준비 대기
for i in {1..30}; do
    if cast block-number --rpc-url http://localhost:8545 &> /dev/null; then
        break
    fi
    sleep 2
done
```

### Step 4: L1 Genesis Hash 조회 및 Rollup 설정

```bash
# curl 사용 (cast보다 안정적)
L1_BLOCK_0=$(curl -s -X POST -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["0x0", false],"id":1}' \
    http://localhost:8545)

L1_GENESIS_HASH=$(echo "$L1_BLOCK_0" | jq -r '.result.hash')
L1_GENESIS_TIME_DEC=$(echo "$L1_BLOCK_0" | jq -r '.result.timestamp' | xargs printf "%d")

# rollup.json 생성
cat > "$DEVNET_DIR/rollup.json" <<EOF
{
  "genesis": {
    "l1": {
      "hash": "$L1_GENESIS_HASH",
      "number": 0
    },
    "l2_time": $L1_GENESIS_TIME_DEC,
    ...
  }
}
EOF
```

### Step 5: L2 Genesis 파일 생성

```bash
cat > "$DEVNET_DIR/genesis-l2.json" <<'EOF'
{
  "config": {
    "chainId": 901,
    ...
  }
}
EOF
```

### Step 6: L2 Execution 시작

```bash
docker-compose up -d l2-execution

# healthcheck 대기
for i in {1..30}; do
    if docker-compose ps l2-execution | grep -q "healthy"; then
        break
    fi
    sleep 2
done
```

### Step 7: L2 Genesis Hash 조회 및 Rollup 업데이트

```bash
L2_GENESIS_HASH=$(curl -s -X POST -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["0x0", false],"id":1}' \
    http://localhost:9545 | jq -r '.result.hash')

# rollup.json 업데이트
jq --arg hash "$L2_GENESIS_HASH" '.genesis.l2.hash = $hash' \
    "$DEVNET_DIR/rollup.json" > "$DEVNET_DIR/rollup.json.tmp"
mv "$DEVNET_DIR/rollup.json.tmp" "$DEVNET_DIR/rollup.json"
```

### Step 8: op-node, Batcher, Proposer 시작

```bash
docker-compose up -d l2-node
sleep 10
docker-compose up -d l2-batcher l2-proposer
```

## 발생한 문제와 해결 방법

### 1. ARM64 플랫폼 호환성

**문제:** Apple Silicon에서 x86_64 이미지 실행 실패

**해결:** 모든 서비스에 `platform: linux/amd64` 추가

```yaml
services:
  l1:
    platform: linux/amd64
  l2-execution:
    platform: linux/amd64
  l2-node:
    platform: linux/amd64
```

### 2. Anvil Block Hash BlockTag 미지원

**문제:** Anvil이 `eth_getBlockByHash`를 blockTag로 지원하지 않음

**해결:** Geth Clique PoA 사용

### 3. op-node Beacon API 요구

**문제:** 최신 op-node(v1.16.6+)가 L1 Beacon API를 필수로 요구

**해결:** 
- v1.7.0 버전으로 다운그레이드
- `--l1.beacon.ignore` 플래그 추가

### 4. L2 Chain ID 불일치

**문제:** L2가 Chain ID 1로 시작됨 (genesis 초기화 실패)

**해결:** 매 시작 시 기존 데이터 삭제

```bash
rm -rf /data/geth /data/geth.ipc
geth init --datadir=/data /genesis/genesis-l2.json
```

### 5. Genesis Hash 불일치

**문제:** cast 명령이 잘못된 genesis hash 반환

**해결:** curl RPC 직접 호출 사용

```bash
curl -s -X POST -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["0x0", false],"id":1}' \
    http://localhost:8545 | jq -r '.result.hash'
```

### 6. RAT Client 계정 역할 충돌

**문제:** Account #2가 RAT proxy admin이어서 RAT 함수 호출 불가

**원인:** TransparentUpgradeableProxy 패턴

**해결:** Validator는 Account #3-8 사용

## 파일 구조

```
ton-staking-v2/
├── .devnet/
│   ├── genesis-l1-staking-v3.json   # L1 genesis (컨트랙트 포함)
│   ├── genesis-l2.json               # L2 genesis (동적 생성)
│   ├── rollup.json                   # Rollup 설정 (동적 생성)
│   ├── jwt-secret.txt                # JWT 인증 키 (동적 생성)
│   ├── addresses.json                # TON Staking 컨트랙트 주소
│   └── optimism-addresses.json       # Optimism 컨트랙트 주소
├── docker-compose.yml                # 서비스 정의
├── scripts/
│   ├── start-persistent-devnet.sh    # 시작 스크립트
│   ├── stop-devnet.sh                # 종료 스크립트
│   ├── get-devnet-info.sh            # 정보 조회
│   ├── check-devnet-health.sh        # 헬스 체크
│   └── test-local-devnet.sh          # 테스트 스크립트
├── clients/
│   └── rat-client-type3/
│       ├── Dockerfile                # RAT Client 이미지
│       └── entrypoint.sh             # 시작 스크립트
└── docs/deployment/local/
    ├── README.md                     # 메인 가이드
    ├── QUICKSTART.md                 # 빠른 시작
    └── IMPLEMENTATION.md             # 이 문서
```

## 성능 고려사항

### 리소스 요구사항

- **메모리**: 최소 8GB RAM 권장
- **디스크**: 2GB 이상 여유 공간
- **CPU**: 4코어 이상 권장

### 시작 시간

- L1 시작: 약 10-20초
- L2 Execution 시작: 약 30-60초
- 전체 환경 준비: 약 2-3분

### 블록 생성

- L1: ~1초 간격 (트랜잭션 발생 시)
- L2: 2초 간격

### 디스크 사용량

- L1: ~500MB (Docker 볼륨)
- L2: ~500MB (Docker 볼륨)
- 총: ~1GB

## 모니터링

### 로그 확인

```bash
# 전체 로그
docker-compose logs -f

# L1 로그
docker-compose logs -f l1

# L2 로그
docker-compose logs -f l2-execution l2-node

# RAT Client 로그
docker-compose logs -f rat-client-1 rat-client-2 rat-client-3
```

### 헬스 체크

```bash
make devnet-health

# 또는
./scripts/check-devnet-health.sh
```

### Web UI

Web UI를 통한 실시간 모니터링:

```bash
cd web-ui
npm install
npm run dev
# http://localhost:5173 접속
```

**Web UI 기능:**
- 실시간 시스템 상태
- 컨트랙트 상호작용
- Validator 관리
- Token faucet
- TON/WTON 스왑

## 참고 자료

- [Optimism Specs](https://github.com/ethereum-optimism/specs)
- [op-geth Documentation](https://github.com/ethereum-optimism/op-geth)
- [op-node Documentation](https://github.com/ethereum-optimism/optimism/tree/develop/op-node)
- [Geth Documentation](https://geth.ethereum.org/docs)
- [Clique PoA Consensus](https://github.com/ethereum/EIPs/issues/225)

---

# Sepolia Fork Devnet (권장)

이 섹션은 **검증된 방법**으로 Sepolia 테스트넷을 fork하여 로컬 데브넷을 구축하는 방법을 설명합니다.

## 핵심 개념: Allocs 기반 배포

기존의 `forge script --broadcast` 방식 대신 **allocs 파일**을 사용하여 컨트랙트를 배포합니다.

### 왜 Allocs 방식인가?

1. **Nonce 문제 해결**: Sepolia fork에서 테스트 계정(0xf39Fd6e...)의 nonce가 이미 높음
2. **결정적 주소**: 항상 동일한 컨트랙트 주소 보장
3. **완전한 초기화**: 배포 + 초기화가 모두 포함된 상태
4. **빠른 시작**: 111개 컨트랙트를 수 초 내에 배포

### Allocs 파일 구조

```json
{
  "0xd55b55304b5cf7607B6dEd6DA6EeB487918AaD2E": {
    "code": "0x608060...",
    "storage": {
      "0x0": "0x544f4e...",
      "0x1": "0x544f4e..."
    },
    "balance": "0x0",
    "nonce": "0x1"
  }
}
```

### 배포 방식

```bash
# Anvil cheatcode로 코드/스토리지/잔액/논스 주입
cast rpc anvil_setCode "$addr" "$code" --rpc-url $RPC
cast rpc anvil_setStorageAt "$addr" "$slot" "$value" --rpc-url $RPC
cast rpc anvil_setBalance "$addr" "$balance" --rpc-url $RPC
cast rpc anvil_setNonce "$addr" "$nonce" --rpc-url $RPC
```

## 빠른 시작 (검증된 방법)

```bash
# 1. 데브넷 시작 (L1 + L2 + RAT Clients + L2 등록 전체 자동화)
./scripts/local/start-sepolia-fork.sh

# 2. 상태 확인
docker ps --filter "name=ton-staking"   # 컨테이너 상태 (7개)
cast block-number --rpc-url http://localhost:8545  # L1 블록
cast block-number --rpc-url http://localhost:9545  # L2 블록

# 3. L2 등록 확인
L1_BRIDGE_REGISTRY=$(jq -r '.l1BridgeRegistryProxy' .devnet/addresses.json)
SYSTEM_CONFIG=$(jq -r '.systemConfig' .devnet/addresses.json)
cast call $L1_BRIDGE_REGISTRY "getRollupInfo(address)(uint8,address,bool,bool,string)" $SYSTEM_CONFIG --rpc-url http://localhost:8545
# 결과: Type 3, L2 TON 주소, "Devnet L2"

# 4. 로그 확인
tail -f /tmp/anvil.log                    # L1 (Anvil)
docker logs -f ton-staking-l2-node        # L2 (op-node)
docker logs -f ton-staking-rat-client-1   # RAT Client

# 5. Web UI 실행
cd web-ui && npm install && npm run dev
# http://localhost:5173 접속

# 6. 종료
./scripts/local/stop-sepolia-fork.sh
```

### 시작 스크립트가 수행하는 작업

| 단계 | 설명 |
|------|------|
| Step 1 | 필수 도구 확인 (docker, jq, cast, anvil) |
| Step 2 | Anvil Sepolia Fork 시작 |
| Step 3 | Optimism 컨트랙트 배포 (77개, allocs로 포크 상태 덮어쓰기) |
| Step 4 | TON Staking V3 컨트랙트 배포 (111개, allocs 방식) |
| Step 5 | 컨트랙트 검증 (TON, WTON, SeigManager) |
| Step 6 | L2 설정 파일 생성 (genesis-l2.json, rollup.json) |
| Step 7 | L2 Docker 서비스 시작 (op-geth, op-node, batcher, proposer, RAT clients) |
| Step 8 | L1 자동 블록 생성 활성화 (12초 간격) |
| Step 9 | **L2 등록** (Rollup Type 등록 → Rollup Config 등록 → CandidateAddOn 등록) |
| Step 10 | **검증자 등록** (WTON approve → Deposit → RAT.registerValidator) × 3명 |

### 구동되는 서비스

| 서비스 | 설명 | 포트 |
|--------|------|------|
| Anvil (L1) | Sepolia Fork, TON Staking V3 컨트랙트 | 8545 |
| op-geth (L2) | Optimism Execution Layer | 9545 |
| op-node | Optimism Consensus/Sequencer | 7545 |
| op-batcher | L2 → L1 배치 제출 | - |
| op-proposer | 상태 루트 제안 | - |
| rat-client-1~3 | Validator 모니터링 (Off-chain) | - |

## Sepolia Fork vs Local Devnet

| 항목 | Local Devnet | Sepolia Fork |
|------|--------------|--------------|
| L1 | Geth Clique PoA (Chain ID: 900) | Anvil Fork (Chain ID: 11155111) |
| L1 컨트랙트 | Genesis에 포함 | 런타임 배포 |
| ETH 공급 | Genesis에서 할당 | anvil_setBalance로 민팅 |
| 시작 시간 | 빠름 (~2분) | 느림 (~5분, 네트워크 의존) |
| 재현성 | 높음 | Fork 블록에 따라 다름 |
| 실제 환경 유사성 | 낮음 | 높음 (실제 Sepolia 상태 사용) |

## 왜 Sepolia Fork인가?

Sepolia 포크를 사용하는 핵심 이유:

### 1. EIP-2537 BLS12-381 프리컴파일 지원

Sepolia는 **Pectra 업그레이드** 이후 EIP-2537이 활성화되어 BLS12-381 연산을 네이티브로 지원합니다.

**지원되는 프리컴파일 주소:**

| 주소 | 연산 | 용도 |
|------|------|------|
| `0x0b` | G1ADD | G1 포인트 덧셈 |
| `0x0c` | G1MUL | G1 포인트 스칼라 곱 |
| `0x0d` | G1MSM | G1 다중 스칼라 곱 |
| `0x0e` | G2ADD | G2 포인트 덧셈 |
| `0x0f` | G2MUL | G2 포인트 스칼라 곱 |
| `0x10` | G2MSM | G2 다중 스칼라 곱 |
| `0x11` | PAIRING | 페어링 검증 |
| `0x12` | MAP_FP_TO_G1 | Fp → G1 매핑 |
| `0x13` | MAP_FP2_TO_G2 | Fp2 → G2 매핑 |

**BLS12381.sol 라이브러리:**

```solidity
// src/libraries/BLS12381.sol
library BLS12381 {
    // 프리컴파일 사용 가능 여부 확인
    function isPrecompileAvailable() internal view returns (bool) {
        // G1ADD에 영점 2개를 전달하고 128 bytes 반환 확인
        (bool success, bytes memory result) = BLS_G1ADD.staticcall(
            abi.encodePacked(new bytes(256))
        );
        return success && result.length == 128;
    }

    // BLS 서명 검증
    function verifySignature(
        bytes memory message,
        bytes memory signature,
        bytes memory publicKey
    ) internal view returns (bool);
}
```

**프리컴파일 동작 확인:**

```bash
# G1ADD 프리컴파일 테스트 (두 영점 덧셈)
INPUT="0x$(printf '0%.0s' {1..512})"  # 256 bytes
cast call 0x000000000000000000000000000000000000000b "$INPUT" --rpc-url http://localhost:8545

# 결과: 128 bytes 영점 반환 → 프리컴파일 정상 동작
```

**순수 Anvil/Geth와의 차이:**
- 순수 Anvil: EIP-2537 프리컴파일 미구현
- 로컬 Geth: Pectra 업그레이드 설정 필요
- **Sepolia Fork: 이미 활성화됨** ✅

### 2. Optimism Bedrock 호환성

- op-node가 L1과 통신할 때 실제 Sepolia 체인의 블록 구조와 컨센서스 메커니즘을 기대
- 임의의 Chain ID를 가진 로컬 체인에서는 op-node 동기화가 실패할 수 있음
- Sepolia Fork는 실제 Sepolia의 상태를 그대로 가져오므로 호환성 문제 없음

### 3. 실제 메인넷과 유사한 환경

- Sepolia 포크는 실제 이더리움 메인넷의 상태와 프리컴파일을 그대로 가져옴
- 개발 중 발생할 수 있는 메인넷 배포 시 문제를 미리 발견 가능
- 실제 Sepolia에 배포된 Optimism 컨트랙트 재사용 가능

### 요약

| 기능 | Local Devnet | Sepolia Fork |
|------|--------------|--------------|
| EIP-2537 BLS 프리컴파일 | ❌ 미지원 | ✅ 지원 |
| op-node 호환성 | ⚠️ 제한적 | ✅ 완전 호환 |
| 메인넷 유사성 | 낮음 | 높음 |

**한 줄 요약**: "BLS 서명 검증(EIP-2537)과 Optimism L2 연동을 위해 실제 Sepolia 체인을 포크해서 사용합니다."

### ⚠️ 알려진 제한사항

#### 1. Bridge 기능 제한 (L1 ↔ L2)

Sepolia Fork 환경에서 **Bridge 기능은 동작하지 않습니다**:

```
Error: historical state is not available
```

**원인**:
- Optimism 컨트랙트들(Portal, Bridge, Messenger)이 Sepolia에서 fork됨
- Anvil fork 환경에서 이 컨트랙트들의 historical state 조회 시 오류 발생
- TON Staking V3 컨트랙트는 allocs로 배포되어 정상 동작

**영향받는 기능**:
| 기능 | 상태 |
|------|------|
| L1StandardBridge.depositETH | ❌ 불가 |
| L1StandardBridge.depositERC20 | ❌ 불가 |
| OptimismPortal.depositTransaction | ❌ 불가 |
| L1CrossDomainMessenger | ❌ 불가 |

**해결 방법** (향후 작업):
1. Optimism 컨트랙트도 allocs로 생성하여 배포
2. 또는 전체 Optimism 스택을 로컬에서 새로 배포

#### 2. Validator 등록 필요

RAT Client가 실행 중이어도 **온체인에 Validator로 등록되지 않습니다**. 수동 등록 필요:

```bash
# Validator 등록 (각 Validator마다 실행)
RAT=$(jq -r '.ratProxy' .devnet/addresses.json)
SYSTEM_CONFIG=$(jq -r '.systemConfig' .devnet/addresses.json)
WTON=$(jq -r '.wton' .devnet/addresses.json)
DEPOSIT_MANAGER=$(jq -r '.depositManagerProxy' .devnet/addresses.json)
CANDIDATE_ADDON=0x97F06B72fa7D6ea5B8BE8BDE4B67e272128Ac7B7

# Step 1: WTON approve + deposit
cast send $WTON "approve(address,uint256)" $DEPOSIT_MANAGER 60000000000000000000000000000 \
    --private-key $VALIDATOR_KEY --rpc-url http://localhost:8545
cast send $DEPOSIT_MANAGER "deposit(address,uint256)" $CANDIDATE_ADDON 60000000000000000000000000000 \
    --private-key $VALIDATOR_KEY --rpc-url http://localhost:8545

# Step 2: Register as Validator
cast send $RAT "registerValidator(address)" $SYSTEM_CONFIG \
    --private-key $VALIDATOR_KEY --rpc-url http://localhost:8545
```

#### 3. 잔액 자동 업데이트 제한

Web UI에서 **TON/WTON 잔액이 자동 업데이트되지 않습니다**:
- ETH 잔액: ✅ 정상 (10초마다 업데이트)
- TON 잔액: ❌ 자동 업데이트 안됨
- WTON 잔액: ❌ 자동 업데이트 안됨

**원인**: `loadDashboardData`에 `loadUserBalances` 누락

**임시 해결**: 페이지 새로고침(F5)

## 아키텍처 (Sepolia Fork) - 검증됨

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Host Machine                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌────────────────────────────┐                                             │
│  │   L1: Anvil (호스트 직접)    │                                             │
│  │                            │                                             │
│  │   - Chain ID: 11155111     │                                             │
│  │   - Fork: Sepolia Testnet  │                                             │
│  │   - Port: 8545             │                                             │
│  │   - Block Time: 12s        │                                             │
│  │                            │                                             │
│  │   Deployed via Allocs:     │                                             │
│  │   ┌──────────────────────┐ │                                             │
│  │   │ TON Staking V3       │ │                                             │
│  │   │ - TON/WTON           │ │                                             │
│  │   │ - SeigManager        │ │                                             │
│  │   │ - DepositManager     │ │                                             │
│  │   │ - Layer2Manager      │ │                                             │
│  │   │ - RAT/ValidatorReward│ │                                             │
│  │   │ - DAO Infrastructure │ │                                             │
│  │   │ (111 contracts)      │ │                                             │
│  │   └──────────────────────┘ │                                             │
│  │                            │                                             │
│  │   From Sepolia Fork:       │                                             │
│  │   ┌──────────────────────┐ │                                             │
│  │   │ Optimism L1          │ │                                             │
│  │   │ - SystemConfig       │ │                                             │
│  │   │ - DisputeGameFactory │ │                                             │
│  │   │ - OptimismPortal     │ │                                             │
│  │   └──────────────────────┘ │                                             │
│  └────────────────────────────┘                                             │
│              │                                                               │
│              │ host.docker.internal:8545                                    │
│              ▼                                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                   L2 Docker Containers                               │   │
│  │  ┌─────────────────────┐  ┌─────────────────────┐                  │   │
│  │  │   L2: op-geth       │  │   L2: op-node       │                  │   │
│  │  │   (Execution)       │◄─┤   (Consensus)       │                  │   │
│  │  │                     │  │                     │                  │   │
│  │  │   Port: 9545 (RPC)  │  │   Port: 7545 (RPC)  │                  │   │
│  │  │   Port: 8551 (Auth) │  │   Sequencer Mode    │                  │   │
│  │  │   Chain ID: 901     │  │                     │                  │   │
│  │  │   Block Time: 2s    │  │                     │                  │   │
│  │  └─────────────────────┘  └─────────────────────┘                  │   │
│  │                                                                      │   │
│  │  ┌─────────────────────┐  ┌─────────────────────┐                  │   │
│  │  │   op-batcher        │  │   op-proposer       │                  │   │
│  │  │   (Batch Submitter) │  │   (Output Proposer) │                  │   │
│  │  │   → L1 batch inbox  │  │   → DisputeGame     │                  │   │
│  │  └─────────────────────┘  └─────────────────────┘                  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │              Off-chain: RAT Clients (Docker Containers)              │   │
│  │                                                                      │   │
│  │   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐              │   │
│  │   │ rat-client-1│   │ rat-client-2│   │ rat-client-3│              │   │
│  │   │ (Validator) │   │ (Validator) │   │ (Validator) │              │   │
│  │   └──────┬──────┘   └──────┬──────┘   └──────┬──────┘              │   │
│  │          │                 │                 │                      │   │
│  │          └────────────┬────┴────────────────┘                      │   │
│  │                       │                                             │   │
│  │                       ▼                                             │   │
│  │   ┌─────────────────────────────────────────────────────────────┐  │   │
│  │   │  - L1 모니터링: DisputeGameFactory 이벤트 감시               │  │   │
│  │   │  - L2 조회: op-geth에서 블록 상태 조회                       │  │   │
│  │   │  - L1 제출: RAT 컨트랙트에 상태 증명 (Attestation) 제출      │  │   │
│  │   └─────────────────────────────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

**핵심 포인트:**
- L1(Anvil)은 **호스트에서 직접** 실행 (Docker 아님)
- L2 서비스는 **Docker 컨테이너**로 실행
- L2가 L1에 접속할 때 `host.docker.internal` 사용
- TON Staking V3 컨트랙트는 **allocs 방식**으로 배포 (완전 초기화 상태)

## RAT Client 동작 방식

RAT (Rollup Attestation Token) Client는 **오프체인**에서 동작하며, L1 컨트랙트를 모니터링하고 L2 블록을 조회하여 Validator로서 상태 증명을 제출합니다.

### 동작 흐름

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       RAT Client (Off-chain)                             │
│                        Docker Container                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ 1. L1 모니터링 (DisputeGameFactory)                              │    │
│  │    - 새로운 DisputeGame 생성 이벤트 감지                          │    │
│  │    - 게임 상태 변화 추적                                          │    │
│  │    - Proposer가 제출한 상태 루트 확인                             │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                              │                                           │
│                              ▼                                           │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ 2. L2 블록 조회 (op-geth)                                        │    │
│  │    - 해당 블록 번호의 상태 루트 조회                               │    │
│  │    - L1에 제출된 상태 루트와 비교/검증                            │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                              │                                           │
│                              ▼                                           │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ 3. RAT 컨트랙트에 증명 제출 (L1)                                  │    │
│  │    - RAT.submitAttestation(): Validator로서 상태 증명 제출        │    │
│  │    - 다수의 Validator가 동일한 상태를 증명하면 보상 획득           │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 환경 변수

| 변수 | 설명 | 예시 |
|------|------|------|
| `L1_RPC_URL` | L1 RPC (모니터링 + 트랜잭션 전송) | `http://host.docker.internal:8545` |
| `L2_RPC_URL` | L2 RPC (블록/상태 조회) | `http://l2-execution:8545` |
| `PRIVATE_KEY` | Validator 서명용 개인키 | `0x5de4111a...` (Anvil #3) |
| `POLL_INTERVAL` | 폴링 간격 (초) | `10` |
| `LOG_LEVEL` | 로그 레벨 | `info` |

### RAT Client 계정

| Client | Anvil Account | Address | Private Key |
|--------|---------------|---------|-------------|
| rat-client-1 | #3 | `0x90F79bf6EB2c4f870365E785982E1f101E93b906` | `0x5de4111a...` |
| rat-client-2 | #4 | `0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65` | `0x7c852118...` |
| rat-client-3 | #5 | `0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc` | `0x47e179ec...` |

각 계정에는 배포 시 100,000 TON + 100,000 WTON이 할당되어 있습니다.

### 로그 확인

```bash
# 개별 RAT Client 로그
docker logs -f ton-staking-rat-client-1
docker logs -f ton-staking-rat-client-2
docker logs -f ton-staking-rat-client-3

# 모든 RAT Client 로그
docker logs -f ton-staking-rat-client-1 &
docker logs -f ton-staking-rat-client-2 &
docker logs -f ton-staking-rat-client-3 &
```

### RAT 시스템 컨트랙트

| 컨트랙트 | 역할 | 주소 |
|----------|------|------|
| RAT Proxy | Rollup Attestation Token 메인 컨트랙트 | `.devnet/addresses.json` → `ratProxy` |
| ValidatorReward Proxy | Validator 보상 분배 | `.devnet/addresses.json` → `validatorRewardProxy` |
| DisputeGameFactory | 옵티미즘 분쟁 게임 (Sepolia fork) | `0x52d01b38b78b559142B04CC19F5cC50D5C03dbAc` |

## L2 등록 과정 (자동화됨)

스크립트의 **Step 9**에서 다음 L2 등록 과정이 자동으로 수행됩니다:

### Step 9.1: Rollup Type 등록

L1BridgeRegistry에 지원하는 Rollup 타입을 등록합니다:

```solidity
// Type 1: Optimism Legacy (V2 전용)
addRollupType(1, "Optimism Legacy", 0x078f29cf, 0x078f29cf, 0x00000000, 0, false)

// Type 2: Optimism Bedrock (V2 전용)
addRollupType(2, "Optimism Bedrock", 0x078f29cf, 0x0a49cb03, 0x00000000, 1, false)

// Type 3: Optimism Bedrock DisputeGame (V3 지원)
addRollupType(3, "Optimism Bedrock DisputeGame", 0x078f29cf, 0x0a49cb03, 0x0a1e5c7d, 1, true)
```

### Step 9.2: Rollup Config 등록

SystemConfig 주소를 L1BridgeRegistry에 Type 3으로 등록합니다:

```bash
cast send $L1_BRIDGE_REGISTRY \
    "registerRollupConfigByManager(address,uint8,address,string)" \
    $SYSTEM_CONFIG 3 $TON "Devnet L2" \
    --private-key $MANAGER_KEY --rpc-url http://localhost:8545
```

**결과**:
- L1StandardBridge, OptimismPortal, DisputeGameFactory 주소가 자동으로 조회되어 등록
- Rollup 정보가 `rollupInfo[systemConfig]`에 저장

### Step 9.3: CandidateAddOn 등록 (Operator Staking)

Layer2Manager를 통해 L2 운영자를 등록하고 최소 스테이킹 (1001 WTON)을 수행합니다:

```bash
# 1. WTON 승인
cast send $WTON "approve(address,uint256)" $LAYER2_MANAGER MAX_UINT256 \
    --private-key $OPERATOR_KEY --rpc-url http://localhost:8545

# 2. CandidateAddOn 등록 (OperatorManager 자동 생성 + 스테이킹)
cast send $LAYER2_MANAGER \
    "registerCandidateAddOn(address,uint256,bool,string)" \
    $SYSTEM_CONFIG 1001000000000000000000000000000 false "Devnet L2 Operator" \
    --private-key $OPERATOR_KEY --rpc-url http://localhost:8545
```

**내부 동작**:
1. `OperatorManagerFactory.createOperatorManager(systemConfig)` 호출
2. OperatorManager 프록시 생성 (CREATE2로 결정적 주소)
3. `DAOCommittee.createCandidateAddOn()` 호출 → CandidateAddOn(Layer2) 생성
4. `DepositManager.deposit()` 호출 → 운영자 스테이킹 완료

### 등록 결과

| 항목 | 값 |
|------|-----|
| Rollup Type | 3 (V3 지원) |
| Status | 1 (Registered) |
| OperatorManager | `0x97F06B...` (자동 생성) |
| CandidateAddOn | `0x0D6603...` (자동 생성) |
| Operator Stake | 1001 WTON |

## 검증자 등록 과정 (자동화됨)

스크립트의 **Step 10**에서 다음 검증자 등록 과정이 자동으로 수행됩니다:

### 검증자 계정

| 역할 | 주소 | Anvil 계정 |
|------|------|------------|
| Validator1 | `0x90F79bf6EB2c4f870365E785982E1f101E93b906` | #3 |
| Validator2 | `0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65` | #4 |
| Validator3 | `0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc` | #5 |

### 등록 절차 (검증자 당 3단계)

```bash
# 1. WTON 승인 (DepositManager에게 무제한 승인)
cast send $WTON "approve(address,uint256)" $DEPOSIT_MANAGER MAX_UINT256 \
    --private-key $VALIDATOR_KEY --rpc-url http://localhost:8545

# 2. WTON 예치 (CandidateAddOn에 100 WTON 예치)
cast send $DEPOSIT_MANAGER "deposit(address,uint256)" $CANDIDATE_ADDON 100000000000000000000000000000 \
    --private-key $VALIDATOR_KEY --rpc-url http://localhost:8545

# 3. RAT에 검증자 등록
cast send $RAT "registerValidator(address)" $SYSTEM_CONFIG \
    --private-key $VALIDATOR_KEY --rpc-url http://localhost:8545
```

### 등록 결과

| 항목 | 값 |
|------|-----|
| 등록된 검증자 수 | 3 |
| 활성 검증자 수 | 3 |
| 검증자당 담보금 | 100 WTON (1e29 ray) |
| 검증자 상태 | 모두 `isActive: true` |

### 검증자 등록 확인

```bash
# 검증자 수 조회
cast call $RAT "getValidatorCount(address)(uint256)" $SYSTEM_CONFIG --rpc-url http://localhost:8545
# 결과: 3

# 검증자 목록 조회
cast call $RAT "getL2Validators(address)(address[])" $SYSTEM_CONFIG --rpc-url http://localhost:8545
# 결과: [0x90F7..., 0x15d3..., 0x9965...]

# 개별 검증자 정보 조회
cast call $RAT "getValidatorRegistration(address,address)(uint256,uint32,bool)" $VALIDATOR1 $SYSTEM_CONFIG --rpc-url http://localhost:8545
# 결과: collateral, validatorIndex, isActive
```

### 수동 등록 (필요시)

스크립트 대신 수동으로 등록하려면:

```bash
./scripts/register-and-stake.sh
```

```bash
# 1. Allocs 파일 생성 (최초 1회, 또는 컨트랙트 변경 시)
./scripts/generate-allocs-offline.sh

# 2. Sepolia Fork 데브넷 시작
./scripts/local/start-sepolia-fork.sh

# 3. 상태 확인
cast block-number --rpc-url http://localhost:8545  # L1
cast block-number --rpc-url http://localhost:9545  # L2

# 4. 컨트랙트 테스트
cast call $(jq -r '.ton' .devnet/addresses.json) "name()(string)" --rpc-url http://localhost:8545
# 결과: "TON"

# 5. 로그 확인
tail -f /tmp/anvil.log           # L1
docker logs -f ton-staking-l2-node  # L2

# 6. 종료
./scripts/local/stop-sepolia-fork.sh
```

## 상세 시작 절차

### Step 1: Anvil Sepolia Fork 시작

```bash
anvil \
  --host 0.0.0.0 \
  --port 8545 \
  --fork-url "https://ethereum-sepolia-rpc.publicnode.com" \
  --chain-id 11155111 \
  --no-rate-limit \
  --gas-limit 30000000 \
  --code-size-limit 1000000
```

### Step 2: TON Staking V3 컨트랙트 배포

```bash
# allocs 파일의 모든 주소에 대해:
for addr in $(jq -r 'keys[]' .devnet/allocs-l1-staking-v3.json); do
    # 코드 주입
    cast rpc anvil_setCode "$addr" "$(jq -r --arg a "$addr" '.[$a].code' allocs.json)"

    # 스토리지 주입
    for slot in $(jq -r --arg a "$addr" '.[$a].storage | keys[]' allocs.json); do
        value=$(jq -r --arg a "$addr" --arg s "$slot" '.[$a].storage[$s]' allocs.json)
        cast rpc anvil_setStorageAt "$addr" "$slot" "$value"
    done
done
```

### Step 3: L2 Genesis 설정

```bash
# 현재 L1 블록 정보로 rollup.json 생성
L1_BLOCK=$(cast block latest --rpc-url http://localhost:8545 --json)
L1_HASH=$(echo $L1_BLOCK | jq -r '.hash')
L1_NUM=$(echo $L1_BLOCK | jq -r '.number')
L1_TIME=$(echo $L1_BLOCK | jq -r '.timestamp')
```

### Step 4: L2 서비스 시작

```bash
docker compose -f docker-compose.l2-only.yml up -d l2-execution
# op-geth 준비 대기 후 L2 genesis hash 조회
L2_HASH=$(cast block 0 --rpc-url http://localhost:9545 --json | jq -r '.hash')
# rollup.json 업데이트
jq --arg h "$L2_HASH" '.genesis.l2.hash = $h' rollup.json > tmp && mv tmp rollup.json
# op-node 시작
docker compose -f docker-compose.l2-only.yml up -d l2-node
```

### Step 5: 자동 블록 생성 활성화

```bash
cast rpc anvil_setIntervalMining 12 --rpc-url http://localhost:8545
```

## 빠른 시작 (레거시 방법)

```bash
# 1. Sepolia Fork 데브넷 시작 (기존 Sepolia Optimism 사용)
make devnet-sepolia-fork-start

# 2. 상태 확인
make devnet-sepolia-fork-health
make devnet-sepolia-fork-info

# 3. ETH 민팅 (필요시)
./scripts/sepolia-fork/faucet.sh 0xYourAddress 100

# 4. 로그 확인
make devnet-sepolia-fork-logs

# 5. 종료
make devnet-sepolia-fork-stop
```

## Optimism 컨트랙트 배포 옵션

### 옵션 1: 기존 Sepolia Optimism 컨트랙트 사용 (기본값)

```bash
# DEPLOY_OPTIMISM=false (기본값)
make devnet-sepolia-fork-start
```

이 모드에서는 실제 Sepolia에 배포된 Optimism 컨트랙트를 사용합니다:
- OptimismPortal: `0x16Fc5058F25648194471939df75CF27A2fdC48BC`
- SystemConfig: `0x034edD2A225f7f429A63E0f1D2084B9E0A93b538`

**장점**: 빠름, 실제 환경과 동일
**단점**: RAT 통합 불가 (DisputeGameFactory가 RAT을 지원하지 않음)

### 옵션 2: 커스텀 Optimism 컨트랙트 배포

```bash
# 1. 먼저 기본 모드로 시작
make devnet-sepolia-fork-start

# 2. 커스텀 Optimism 컨트랙트 배포
make devnet-sepolia-fork-deploy-optimism
```

이 모드에서는 `scripts/config/optimism-allocs-l1.json`의 바이트코드를 사용하여
RAT 통합이 포함된 Optimism 컨트랙트를 배포합니다.

**동작 원리**:
```bash
# Anvil cheatcode로 컨트랙트 코드 주입
cast rpc anvil_setCode <address> <bytecode>
cast rpc anvil_setStorageAt <address> <slot> <value>
```

## 환경 변수 설정

`deployments/sepolia-fork/.env` 파일:

```bash
# Sepolia RPC (공개 RPC 또는 개인 노드)
SEPOLIA_RPC=https://rpc.sepolia.org

# Fork 블록 번호 (latest 또는 특정 블록)
FORK_BLOCK=latest

# Optimism 컨트랙트 배포 여부
DEPLOY_OPTIMISM=false

# 기존 Sepolia Optimism 컨트랙트 주소
OPTIMISM_PORTAL=0x16Fc5058F25648194471939df75CF27A2fdC48BC
SYSTEM_CONFIG=0x034edD2A225f7f429A63E0f1D2084B9E0A93b538
```

## 파일 구조 (Sepolia Fork) - 검증됨

```
ton-staking-v2/
├── .devnet/                              # 빌드된 allocs 및 설정
│   ├── allocs-l1-staking-v3.json         # ★ TON Staking V3 allocs (2MB, 111개 컨트랙트)
│   ├── allocs-l1.json                    # Optimism allocs
│   ├── genesis-l1-staking-v3.json        # L1 genesis (Geth Clique용)
│   ├── addresses.json                    # ★ TON Staking 배포 주소
│   ├── optimism-addresses.json           # Optimism 컨트랙트 주소
│   ├── devnetL1.json                     # L1 설정 정보
│   └── jwt-secret.txt                    # JWT 인증 키
│
├── .devnet-sepolia-fork/                 # 런타임 생성 (시작 시 자동)
│   ├── genesis-l2.json                   # L2 genesis (동적 생성)
│   ├── rollup.json                       # Rollup 설정 (동적 생성)
│   ├── addresses.json                    # .devnet/에서 복사
│   └── jwt-secret.txt                    # .devnet/에서 복사
│
├── docker-compose.l2-only.yml            # ★ L2 서비스 (op-geth, op-node, batcher, proposer)
│
├── scripts/local/
│   ├── start-sepolia-fork.sh             # ★ 시작 스크립트 (권장)
│   ├── stop-sepolia-fork.sh              # ★ 종료 스크립트
│   ├── start-devnet.sh                   # Geth Clique용 (레거시)
│   └── stop-devnet.sh                    # Geth Clique용 (레거시)
│
├── scripts/
│   └── generate-allocs-offline.sh        # ★ Allocs 생성 스크립트
│
└── docs/deployment/local/
    ├── README.md                         # 메인 가이드
    ├── QUICKSTART.md                     # 빠른 시작
    └── IMPLEMENTATION.md                 # 이 문서
```

**★ 표시된 파일이 핵심 파일입니다.**

## Docker Compose 서비스 (Sepolia Fork)

### L1: Anvil Sepolia Fork

```yaml
l1-sepolia-fork:
  image: ethereumoptimism/foundry:latest
  command: |
    anvil \
      --fork-url "${SEPOLIA_RPC}" \
      --fork-block-number ${FORK_BLOCK} \
      --block-time 12 \
      --chain-id 11155111
```

**Anvil vs Geth 차이점**:
- Anvil은 `anvil_setBalance`, `anvil_setCode` 등의 cheatcode 지원
- Fork 모드에서 실제 Sepolia 상태 사용 가능
- 하지만 op-node와 완전 호환되지 않을 수 있음

### L2 서비스

L2 서비스 (op-geth, op-node, batcher, proposer)는 Local Devnet과 동일합니다.
주요 차이점:
- 컨테이너 이름에 `-sepolia-fork` 접미사 추가
- 볼륨 이름에 `-sepolia-fork` 접미사 추가

## 문제 해결

### 1. Sepolia RPC 연결 실패

**문제**: Fork 시작 시 Sepolia RPC 연결 오류

**해결**:
```bash
# 다른 RPC 사용
export SEPOLIA_RPC=https://rpc.ankr.com/eth_sepolia
# 또는 Alchemy/Infura 사용
export SEPOLIA_RPC=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY
```

### 2. ETH 잔액 부족

**문제**: 배포자 계정에 ETH 없음

**해결**:
```bash
./scripts/sepolia-fork/faucet.sh 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 1000
```

### 3. 컨트랙트 배포 실패

**문제**: forge script 실행 실패

**해결**:
1. .devnet-sepolia-fork 디렉토리 삭제 후 재시작
2. 로그 확인: `docker logs ton-staking-l1-sepolia-fork`

### 4. op-node 동기화 실패

**문제**: op-node가 L1과 동기화되지 않음

**원인**: Anvil fork와 op-node 호환성 문제

**해결**:
- `--l1.beacon.ignore` 플래그 사용 (docker-compose에 이미 설정됨)
- op-node v1.7.0 사용 (최신 버전은 Beacon API 필수)

## Make 명령어 요약

```bash
# 시작/종료
make devnet-sepolia-fork-start      # 데브넷 시작
make devnet-sepolia-fork-stop       # 데브넷 종료

# 모니터링
make devnet-sepolia-fork-info       # 정보 조회
make devnet-sepolia-fork-health     # 헬스 체크
make devnet-sepolia-fork-logs       # 로그 보기

# 유틸리티
make devnet-sepolia-fork-faucet ADDRESS=0x... AMOUNT=100  # ETH 민팅
make devnet-sepolia-fork-deploy-optimism  # Optimism 컨트랙트 배포
```
