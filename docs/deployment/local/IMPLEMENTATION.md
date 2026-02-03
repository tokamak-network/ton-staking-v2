# TON Staking V3 로컬 환경 구축 - 구현 상세

이 문서는 TON Staking V3 로컬 개발 환경의 기술적 구현 상세를 설명합니다.

> **Note**: 일반 사용자는 [빠른 시작 가이드](./QUICKSTART.md)를 먼저 참조하세요. 이 문서는 시스템 내부 동작, 문제 해결 과정, 설계 결정을 이해하고자 하는 개발자를 위한 문서입니다.

## 아키텍처 개요

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Docker Compose Network                          │
│                     (ton-staking-network)                              │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  ┌─────────────────────┐       ┌──────────────────────────────────┐  │
│  │        L1           │       │              L2                   │  │
│  │      (Anvil)        │       │                                   │  │
│  │                     │       │  ┌─────────────┐ ┌─────────────┐ │  │
│  │  - Chain ID: 900    │◄──────┤  │   op-geth   │ │   op-node   │ │  │
│  │  - Port: 8545       │       │  │  (execution)│ │  (consensus)│ │  │
│  │  - Block Time: 12s  │       │  │  Port: 9545 │ │  Port: 7545 │ │  │
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
└────────────────────────────────────────────────────────────────────────┘
```

## Docker Compose 서비스 구성

### 1. L1 서비스 (Anvil)

```yaml
l1:
  image: ethereumoptimism/foundry:latest
  platform: linux/amd64
  container_name: ton-staking-l1
  ports:
    - "8545:8545"
  volumes:
    - ./.devnet:/data
  command:
    - |
      anvil \
        --host 0.0.0.0 \
        --port 8545 \
        --init /data/genesis-l1-staking-v3.json \
        --block-time 12 \
        --chain-id 900
```

**주요 설정 사항:**
- `platform: linux/amd64`: Apple Silicon (ARM64) 호환성을 위해 필수
- `--host 0.0.0.0`: Docker 네트워크에서 접근 가능하도록 설정
- `--init`: genesis 상태를 로드 (모든 컨트랙트와 계정 포함)

### 2. L2 Execution 서비스 (op-geth)

```yaml
l2-execution:
  image: us-docker.pkg.dev/oplabs-tools-artifacts/images/op-geth:latest
  command:
    - |
      rm -rf /data/geth /data/geth.ipc
      geth init --datadir=/data /genesis/genesis-l2.json
      exec geth \
        --datadir=/data \
        --http --http.addr=0.0.0.0 \
        --authrpc.addr=0.0.0.0 \
        --authrpc.jwtsecret=/genesis/jwt-secret.txt \
        --syncmode=full \
        --gcmode=archive \
        --maxpeers=0 \
        --networkid=901 \
        --rollup.disabletxpoolgossip=true
```

**주요 설정 사항:**
- `rm -rf /data/geth`: 매 시작 시 genesis 재초기화 (일관된 상태 보장)
- `--authrpc.jwtsecret`: op-node와의 인증 통신에 필요
- `--rollup.disabletxpoolgossip=true`: 롤업 모드 활성화

### 3. L2 Node 서비스 (op-node)

```yaml
l2-node:
  image: us-docker.pkg.dev/oplabs-tools-artifacts/images/op-node:v1.7.7
  command:
    - |
      exec op-node \
        --l1=http://l1:8545 \
        --l1.trustrpc \
        --l1.rpckind=basic \
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
- `v1.7.7` 버전 사용: 최신 버전(v1.16.6+)은 L1 Beacon API를 필수로 요구
- 로컬 Anvil 환경에서는 Beacon API가 없으므로 이전 버전 사용

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
    "terminalTotalDifficultyPassed": true
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
  }
}
```

### L2 Genesis (genesis-l2.json)

```json
{
  "config": {
    "chainId": 901,
    "terminalTotalDifficulty": 0,
    "terminalTotalDifficultyPassed": true,
    "shanghaiTime": 0,
    "cancunTime": 0,
    "bedrockBlock": 0,
    "regolithTime": 0,
    "canyonTime": 0,
    "deltaTime": 0,
    "ecotoneTime": 0,
    "optimism": {
      "eip1559Elasticity": 6,
      "eip1559Denominator": 50,
      "eip1559DenominatorCanyon": 250
    }
  },
  "gasLimit": "0x1c9c380",
  "baseFeePerGas": "0x3b9aca00",
  "alloc": {}
}
```

**필수 설정:**
- `cancunTime`: `ecotoneTime`과 동일해야 함
- `optimism.eip1559DenominatorCanyon`: Canyon 포크에서 필수

### Rollup Config (rollup.json)

```json
{
  "genesis": {
    "l1": {
      "hash": "0x...",  // L1 genesis block hash
      "number": 0
    },
    "l2": {
      "hash": "0x...",  // L2 genesis block hash
      "number": 0
    },
    "l2_time": 1770091441,  // L2 genesis timestamp
    "system_config": {
      "batcherAddr": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
      "overhead": "0x0000000000000000000000000000000000000000000000000000000000000834",
      "scalar": "0x01000000000000000000000000000000000000000000000000000fa000000000",
      "gasLimit": 30000000
    }
  },
  "block_time": 2,
  "l1_chain_id": 900,
  "l2_chain_id": 901,
  "regolith_time": 0,
  "canyon_time": 0,
  "delta_time": 0,
  "batch_inbox_address": "0xff00000000000000000000000000000000000901",
  "deposit_contract_address": "0x...",  // OptimismPortalProxy
  "l1_system_config_address": "0x..."   // SystemConfig
}
```

## 시작 스크립트 동작 순서

`scripts/start-persistent-devnet.sh`는 다음 순서로 실행됩니다:

### Step 1: L1 시작 및 대기
```bash
docker-compose up -d l1

# L1 준비 대기
for i in {1..30}; do
    if cast block-number --rpc-url http://localhost:8545; then
        break
    fi
    sleep 2
done
```

### Step 2: L1 Genesis Hash 조회 및 Rollup 설정
```bash
# curl 사용 (cast보다 안정적)
L1_BLOCK_0=$(curl -s -X POST -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["0x0", false],"id":1}' \
    http://localhost:8545)

L1_GENESIS_HASH=$(echo "$L1_BLOCK_0" | jq -r '.result.hash')

# rollup.json 생성
cat > "$DEVNET_DIR/rollup.json" <<EOF
{
  "genesis": {
    "l1": {
      "hash": "$L1_GENESIS_HASH",
      "number": 0
    },
    ...
  }
}
EOF
```

### Step 3: L2 Execution 시작
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

### Step 3.5: L2 Genesis Hash 조회 및 Rollup 업데이트
```bash
L2_GENESIS_HASH=$(curl -s -X POST -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["0x0", false],"id":1}' \
    http://localhost:9545 | jq -r '.result.hash')

# rollup.json 업데이트
jq --arg hash "$L2_GENESIS_HASH" '.genesis.l2.hash = $hash' \
    "$DEVNET_DIR/rollup.json" > "$DEVNET_DIR/rollup.json.tmp"
mv "$DEVNET_DIR/rollup.json.tmp" "$DEVNET_DIR/rollup.json"
```

### Step 4-5: op-node, Batcher, Proposer 시작
```bash
docker-compose up -d l2-node
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

### 2. Anvil 네트워크 바인딩

**문제:** Anvil이 127.0.0.1에만 바인딩되어 Docker 네트워크에서 접근 불가

**해결:** `--host 0.0.0.0` 플래그 추가

### 3. L1 Healthcheck 실패

**문제:** wget, curl이 Anvil 이미지에 없음

**해결:** netcat 사용
```yaml
healthcheck:
  test: ["CMD-SHELL", "echo | nc -w1 0.0.0.0 8545"]
```

### 4. op-node "chain spec not found" 오류

**문제:** 환경 변수와 명령줄 인수 충돌

**해결:** environment 섹션 제거하고 command에서 직접 설정

### 5. op-node Beacon API 요구

**문제:** 최신 op-node가 L1 Beacon API를 필수로 요구

**해결:** v1.7.7 버전으로 다운그레이드 (Beacon API 불필요)

### 6. L2 Chain ID 불일치

**문제:** L2가 Chain ID 1로 시작됨 (genesis 초기화 실패)

**해결:** 매 시작 시 기존 데이터 삭제
```bash
rm -rf /data/geth /data/geth.ipc
geth init --datadir=/data /genesis/genesis-l2.json
```

### 7. Genesis Hash 불일치

**문제:** cast 명령이 잘못된 genesis hash 반환

**해결:** curl RPC 직접 호출 사용

### 8. L2 Genesis 설정 오류

**문제:** `CancunTime must equal EcotoneTime`

**해결:** genesis-l2.json에 `ecotoneTime: 0` 추가

### 9. SystemConfig unsafeBlockSigner

**문제:** op-node가 SystemConfig에서 unsafeBlockSigner를 찾지 못함

**에러 메시지:**
```
failed to fetch unsafe block signing address from system config: Invalid string length
```

**원인 분석:**
- SystemConfig 컨트랙트가 Genesis에 배포되지만 `unsafeBlockSigner` 스토리지 슬롯이 초기화되지 않음
- op-node는 이 값을 필수로 요구하지만, offline genesis 배포 방식에서는 initialize 트랜잭션을 실행할 수 없음

**현재 상태:** 
- L1과 L2 execution은 정상 작동
- L1의 모든 TON Staking 기능 사용 가능
- op-node는 SystemConfig 초기화 필요 (향후 개선 예정)

**해결 방법 (향후 계획):**
1. DeployAll 스크립트에서 SystemConfig initialize 추가
2. 또는 Genesis allocs에 스토리지 슬롯 직접 설정
3. 또는 op-node v1.7.7 이하 버전 사용 (현재 적용)

## 파일 구조

```
ton-staking-v2/
├── .devnet/
│   ├── genesis-l1-staking-v3.json   # L1 genesis (컨트랙트 포함)
│   ├── genesis-l2.json               # L2 genesis
│   ├── rollup.json                   # Rollup 설정
│   ├── jwt-secret.txt                # JWT 인증 키
│   ├── addresses.json                # 배포된 컨트랙트 주소
│   ├── optimism-addresses.json       # Optimism 컨트랙트 주소
│   └── l1-genesis-for-opnode.json    # op-node용 L1 genesis
├── docker-compose.yml                # 서비스 정의
├── scripts/
│   ├── start-persistent-devnet.sh    # 시작 스크립트
│   ├── stop-devnet.sh                # 종료 스크립트
│   ├── get-devnet-info.sh            # 정보 조회
│   └── test-local-devnet.sh          # 테스트 스크립트
└── docs/deployment/local/
    ├── README.md                     # 메인 가이드
    ├── QUICKSTART.md                 # 빠른 시작
    └── IMPLEMENTATION.md             # 이 문서
```

## 테스트 스크립트

`scripts/test-local-devnet.sh`는 다음을 테스트합니다:

1. **네트워크 연결 테스트**
   - L1/L2 RPC 접근성
   - Chain ID 확인
   - 블록 생성 확인

2. **컨트랙트 배포 테스트**
   - TON, WTON 컨트랙트 존재 확인
   - SeigManager, DepositManager 확인
   - Layer2Manager, RAT, SystemConfig 확인

3. **계정 잔액 테스트**
   - 배포자 ETH/TON 잔액
   - Validator ETH 잔액

4. **컨트랙트 함수 테스트**
   - totalSupply 조회
   - 컨트랙트 getter 함수

5. **트랜잭션 테스트**
   - TON approve 트랜잭션
   - allowance 확인

6. **Docker 컨테이너 상태**
   - 각 서비스 running 상태 확인

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
- L1: 12초 간격
- L2: 2초 간격

## 향후 개선 사항

### 우선순위: High

1. **SystemConfig 초기화**: 
   - op-node 완전 동작을 위한 unsafeBlockSigner 설정
   - Genesis allocs에 스토리지 슬롯 추가 또는 초기화 트랜잭션 추가
   - L2 블록 자동 생성 가능

2. **스테이킹 가이드 작성**:
   - Layer2 등록 절차 (registerCandidateAddOn 사용)
   - TON 스테이킹 전체 플로우
   - 실제 동작하는 예제 코드

### 우선순위: Medium

3. **RAT Client 통합**: 
   - Validator 클라이언트 Docker 이미지
   - 자동 시작 스크립트
   - RAT 테스트 시나리오

4. **웹 UI 개발**:
   - 스테이킹 인터페이스
   - 실시간 상태 모니터링
   - MetaMask 연동

### 우선순위: Low

5. **모니터링 대시보드**: 
   - Prometheus/Grafana 통합
   - 블록 생성 모니터링
   - 컨트랙트 이벤트 추적

6. **테스트 자동화**: 
   - CI/CD 파이프라인 통합
   - 자동 회귀 테스트
   - 성능 벤치마크

## 참고 자료

- [Optimism Specs](https://github.com/ethereum-optimism/specs)
- [op-geth Documentation](https://github.com/ethereum-optimism/op-geth)
- [op-node Documentation](https://github.com/ethereum-optimism/optimism/tree/develop/op-node)
- [Anvil Documentation](https://book.getfoundry.sh/reference/anvil/)
