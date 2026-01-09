# StateLeaf E2E Testing Guide

## Overview

이 가이드는 StateLeaf Evidence 생성 기능을 테스트하는 방법을 설명합니다.

## Prerequisites

- Go 1.21 이상
- geth 또는 op-geth (state database 필요)

## 테스트 방법 3가지

### 방법 1: 로컬 Geth (가장 빠름, 추천) ⭐

**소요 시간**: ~5분
**난이도**: 쉬움
**장점**: 빠르고 간단, state trie 기능만 테스트

#### 1.1 Geth 시작

```bash
# Geth가 없다면 설치
# brew install ethereum (macOS)
# 또는 https://geth.ethereum.org/downloads

# Dev mode로 geth 시작
mkdir -p /tmp/geth-test
geth --dev \
  --http \
  --http.addr "0.0.0.0" \
  --http.port 9545 \
  --http.api "eth,net,web3,debug" \
  --datadir /tmp/geth-test \
  --dev.period 2 \
  > /tmp/geth.log 2>&1 &

# PID 저장
echo $! > /tmp/geth.pid
```

#### 1.2 연결 확인

```bash
# RPC 연결 테스트
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
  http://localhost:9545

# 예상 출력: {"jsonrpc":"2.0","id":1,"result":"0x539"}
```

#### 1.3 State 생성 (선택)

Dev mode는 자동으로 블록을 생성하므로 기본 state가 있지만, 더 많은 state를 원하면:

```bash
# 몇 개 트랜잭션 전송
for i in {1..5}; do
  curl -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_sendTransaction","params":[{"from":"0x...","to":"0x...","value":"0x1"}],"id":1}' \
    http://localhost:9545
  sleep 1
done
```

#### 1.4 E2E 테스트 실행

```bash
cd /Users/zena/tokamak-projects/ton-staking-v2/clients/rat-client-type3

# 환경 변수 설정
export E2E_TEST=1
export L2_RPC_URL="http://localhost:9545"
export STATE_DB_PATH="/tmp/geth-test/geth/chaindata"

# 테스트 실행
./test/run_e2e.sh
```

#### 1.5 정리

```bash
# Geth 종료
kill $(cat /tmp/geth.pid)
rm -rf /tmp/geth-test
```

---

### 방법 2: 기존 op-geth 사용 (실전과 유사)

**소요 시간**: ~10분
**난이도**: 중간
**장점**: 실제 op-geth 환경, 프로덕션과 유사

#### 2.1 Prerequisites

실행 중인 op-geth가 있어야 합니다:
- RPC 접근 가능
- State database 접근 가능 (파일시스템)

#### 2.2 op-geth 정보 확인

```bash
# RPC URL 확인
# 일반적으로: http://localhost:8545 또는 http://localhost:9545

# State DB 경로 찾기
# op-geth 로그에서 확인:
grep "Database" /path/to/op-geth.log

# 또는 프로세스에서 확인:
ps aux | grep op-geth | grep datadir

# 일반적인 경로:
# - Linux: /root/.ethereum/geth/chaindata
# - macOS: ~/Library/Ethereum/geth/chaindata
# - Custom: <datadir>/geth/chaindata
```

#### 2.3 테스트 실행

```bash
cd /Users/zena/tokamak-projects/ton-staking-v2/clients/rat-client-type3

# 환경 변수 설정 (실제 경로로 변경)
export E2E_TEST=1
export L2_RPC_URL="http://localhost:8545"  # 실제 RPC URL
export STATE_DB_PATH="/path/to/geth/chaindata"  # 실제 경로

# 테스트 실행
./test/run_e2e.sh
```

---

### 방법 3: Docker Compose (전체 스택)

**소요 시간**: ~30-60분
**난이도**: 어려움
**장점**: 완전한 Optimism 스택, L1-L2 통합 테스트

#### 3.1 Docker Compose 시작

```bash
cd /Users/zena/tokamak-projects/ton-staking-v2/clients/rat-client-type3

# 전체 스택 시작
docker-compose -f docker-compose.test.yml up -d

# 로그 확인
docker-compose -f docker-compose.test.yml logs -f
```

#### 3.2 동기화 대기

op-geth가 L1과 동기화될 때까지 기다립니다:

```bash
# op-geth 로그 확인
docker logs -f $(docker ps -qf "name=l2")

# 동기화 완료 확인:
# - "Syncing" 메시지가 사라짐
# - "Imported new chain segment" 메시지 보임
```

#### 3.3 State DB 경로 확인

```bash
# Docker volume 위치 확인
docker volume inspect rat-client-type3_l2_data --format '{{ .Mountpoint }}'

# 출력 예시: /var/lib/docker/volumes/rat-client-type3_l2_data/_data
# State DB 경로: <Mountpoint>/geth/chaindata
```

#### 3.4 테스트 실행

**옵션 A: 호스트에서 실행**

```bash
export E2E_TEST=1
export L2_RPC_URL="http://localhost:9545"
export STATE_DB_PATH="/var/lib/docker/volumes/rat-client-type3_l2_data/_data/geth/chaindata"

./test/run_e2e.sh
```

**옵션 B: Docker 컨테이너 내부에서 실행**

```bash
# RAT client를 컨테이너로 실행
docker run --rm \
  --network rat-client-type3_default \
  -v $(pwd):/app \
  -v rat-client-type3_l2_data:/data \
  -w /app \
  -e E2E_TEST=1 \
  -e L2_RPC_URL="http://l2:8545" \
  -e STATE_DB_PATH="/data/geth/chaindata" \
  golang:1.21 \
  bash -c "cd /app && ./test/run_e2e.sh"
```

#### 3.5 정리

```bash
# 전체 스택 종료
docker-compose -f docker-compose.test.yml down

# Volume까지 삭제 (선택)
docker-compose -f docker-compose.test.yml down -v
```

---

## 예상 출력

성공적인 테스트 실행 시:

```
=== RAT Client E2E Test Runner ===
✓ L2 RPC is accessible
✓ State database found
Running E2E tests...

=== RUN   TestStateLeafE2E
    state_leaf_e2e_test.go:30: Connecting to L2 RPC: http://localhost:9545
    state_leaf_e2e_test.go:37: Connected to L2 chain ID: 1337
    state_leaf_e2e_test.go:44: Latest block number: 123
    state_leaf_e2e_test.go:54: Using block number: 118
    state_leaf_e2e_test.go:62: Estimated state size: 15 accounts (sample)
    state_leaf_e2e_test.go:69: Random value (test ID): 0x123456789abcdef0
    state_leaf_e2e_test.go:72: Finding adjacent leaves in state trie...
    state_leaf_e2e_test.go:77: Found adjacent leaves in 3.2s
    state_leaf_e2e_test.go:87: LeafA key: 0x1234567890abcdef...
    state_leaf_e2e_test.go:88: LeafA balance: 1000000000000000000
    state_leaf_e2e_test.go:89: LeafB key: 0xfedcba0987654321...
    state_leaf_e2e_test.go:90: LeafB balance: 2000000000000000000
    state_leaf_e2e_test.go:91: ProofA nodes: 8
    state_leaf_e2e_test.go:92: ProofB nodes: 9
    state_leaf_e2e_test.go:93: State root: 0xabcdef1234567890...
    state_leaf_e2e_test.go:120: === E2E Test Summary ===
    state_leaf_e2e_test.go:121: ✅ Successfully generated StateLeafEvidence
    state_leaf_e2e_test.go:122:    - Block: 118
    state_leaf_e2e_test.go:123:    - State root: 0xabcdef1234567890...
    state_leaf_e2e_test.go:124:    - LeafA: 0x1234567890abcdef... (balance: 1000000000000000000)
    state_leaf_e2e_test.go:125:    - LeafB: 0xfedcba0987654321... (balance: 2000000000000000000)
    state_leaf_e2e_test.go:126:    - Proof size: 8 + 9 nodes
    state_leaf_e2e_test.go:127:    - Evidence size: 2847 bytes
    state_leaf_e2e_test.go:128:    - Generation time: 3.2s
    state_leaf_e2e_test.go:129: ========================
--- PASS: TestStateLeafE2E (3.45s)

=== RUN   TestStateLeafWithMultipleBlocks
    state_leaf_e2e_test.go:157: Testing block 123
    state_leaf_e2e_test.go:172: ✅ Block 123: 8 + 9 proof nodes
    state_leaf_e2e_test.go:157: Testing block 113
    state_leaf_e2e_test.go:172: ✅ Block 113: 7 + 8 proof nodes
    state_leaf_e2e_test.go:157: Testing block 103
    state_leaf_e2e_test.go:172: ✅ Block 103: 7 + 7 proof nodes
--- PASS: TestStateLeafWithMultipleBlocks (8.93s)

=== RUN   TestEdgeCases
=== RUN   TestEdgeCases/Very_small_value
    state_leaf_e2e_test.go:223: Testing: Should return first two leaves
    state_leaf_e2e_test.go:224: Random value: 0x1
    state_leaf_e2e_test.go:235: ✅ Very small value: LeafA=0x00000001..., LeafB=0x12345678...
--- PASS: TestEdgeCases/Very_small_value (2.15s)
=== RUN   TestEdgeCases/Very_large_value
    state_leaf_e2e_test.go:223: Testing: Should return last two leaves
    state_leaf_e2e_test.go:224: Random value: 0x8000000000000000000000000000000000000000000000000000000000000000
    state_leaf_e2e_test.go:235: ✅ Very large value: LeafA=0xabcdef12..., LeafB=0xffffffff...
--- PASS: TestEdgeCases/Very_large_value (2.34s)
=== RUN   TestEdgeCases/Medium_value
    state_leaf_e2e_test.go:223: Testing: Should return adjacent leaves in middle of trie
    state_leaf_e2e_test.go:224: Random value: 0x100000000000000000000000000000000
    state_leaf_e2e_test.go:235: ✅ Medium value: LeafA=0x0fedcba9..., LeafB=0x10234567...
--- PASS: TestEdgeCases/Medium_value (2.67s)
--- PASS: TestEdgeCases (7.16s)

PASS
ok  	github.com/tokamak-network/ton-staking-v2/clients/rat-client-type3/test	19.544s

=== E2E Tests Completed ===
```

---

## Troubleshooting

### 문제 1: "L2 RPC not accessible"

**원인**: geth/op-geth가 실행 중이지 않거나 포트가 다름

**해결**:
```bash
# RPC 포트 확인
netstat -an | grep LISTEN | grep 9545

# geth 프로세스 확인
ps aux | grep geth

# 다시 시작
# (위의 각 방법 참조)
```

### 문제 2: "State database not found"

**원인**: STATE_DB_PATH가 잘못됨

**해결**:
```bash
# 경로 확인
ls -la $STATE_DB_PATH

# geth 로그에서 실제 경로 찾기
grep "Database" /tmp/geth.log

# 또는 find로 찾기
find /tmp/geth-test -name "chaindata" -type d
```

### 문제 3: "not enough leaves in state trie"

**원인**: State trie가 비어있음 (블록이 없음)

**해결**:
```bash
# 블록 수 확인
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:9545

# Dev mode에서는 자동으로 블록 생성됨
# 몇 초 기다렸다가 다시 시도
```

### 문제 4: "permission denied" (Docker)

**원인**: Docker volume 권한 문제

**해결**:
```bash
# Option A: sudo로 실행
sudo -E ./test/run_e2e.sh

# Option B: Docker 컨테이너 내부에서 실행 (위의 방법 3.4 옵션 B 참조)

# Option C: volume을 user:group으로 마운트
docker-compose -f docker-compose.test.yml down
# docker-compose.yml에서 volume 설정 수정 후 재시작
```

### 문제 5: "test timed out"

**원인**: State trie가 너무 큼

**해결**:
```bash
# 타임아웃 증가
E2E_TEST=1 L2_RPC_URL="..." STATE_DB_PATH="..." \
  go test -v ./test -run TestStateLeaf -timeout 30m

# 또는 작은 state로 테스트 (dev mode geth 사용)
```

---

## Performance Benchmarks

참고용 성능 지표:

| State Size | Iteration Time | Proof Generation | Total Time |
|-----------|---------------|------------------|------------|
| 10 accounts | ~0.5s | ~0.1s | ~0.6s |
| 100 accounts | ~2s | ~0.2s | ~2.2s |
| 1,000 accounts | ~8s | ~0.3s | ~8.3s |
| 10,000 accounts | ~45s | ~0.5s | ~45.5s |
| 100,000 accounts | ~6min | ~0.8s | ~6min |

*MacBook Pro M1, SSD 기준*

---

## Next Steps

E2E 테스트 성공 후:

1. **Solidity 통합 테스트**
   - Forge로 실제 proof 검증
   - Gas cost 측정

2. **Full Stack 테스트**
   - RAT contract 배포
   - L1에 evidence 제출
   - 온체인 검증

3. **Production Testing**
   - 실제 op-geth mainnet/testnet
   - Large state 성능 테스트
   - 여러 validator concurrent 테스트

---

## References

- [Adjacent Leaves Approach](../docs/ADJACENT_LEAVES_APPROACH.md)
- [RAT Client README](../README.md)
- [State Leaf Verification Implementation](../../../docs/state-leaf-verification-implementation.md)
