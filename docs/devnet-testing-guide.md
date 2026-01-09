# TON Staking V3 + RAT Devnet Testing Guide

## 개요

이 가이드는 TON Staking V3 RAT (Randomized Attention Test) 시스템을 Kurtosis persistent devnet에서 테스트하는 방법을 설명합니다.

**핵심 아이디어**:
1. 기존 E2E 테스트의 Genesis 재사용 (수정 없이)
2. Kurtosis로 persistent devnet 시작
3. RAT Client를 수동/자동으로 테스트

**기존 E2E 테스트와의 차이**:
- **기존 E2E** (`make test-e2e`): Go 테스트가 isolated nodes를 매번 시작/종료
- **Devnet E2E** (이 가이드): Persistent devnet을 띄우고 RAT Client를 장시간 테스트

## 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                     L1 (Anvil - Genesis)                    │
├─────────────────────────────────────────────────────────────┤
│  Optimism Contracts:                                        │
│  ├─ DisputeGameFactory                                      │
│  ├─ FaultDisputeGame                                        │
│  ├─ SystemConfig                                            │
│  └─ ... (기타 Optimism L1 contracts)                        │
│                                                             │
│  TON Staking V3 Contracts:                                  │
│  ├─ TON, WTON (mocks)                                       │
│  ├─ SeigManager, DepositManager                             │
│  ├─ Layer2Manager, L1BridgeRegistry                         │
│  ├─ ValidatorReward                                         │
│  └─ RAT ⭐ (DisputeGameFactory와 연동)                     │
└─────────────────────────────────────────────────────────────┘
                         │
                         │ Batch Data
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                     L2 (OP Stack)                           │
├─────────────────────────────────────────────────────────────┤
│  ├─ op-geth (L2 execution)                                  │
│  ├─ op-node (L2 consensus + Rollup RPC)                     │
│  ├─ op-batcher (Batch submission)                           │
│  └─ op-proposer (Output root proposal)                      │
└─────────────────────────────────────────────────────────────┘
                         │
                         │ Verification
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    RAT Client                               │
├─────────────────────────────────────────────────────────────┤
│  ├─ L1 RPC: http://localhost:xxxxx                          │
│  ├─ L2 RPC: http://localhost:xxxxx                          │
│  ├─ Rollup RPC: http://localhost:xxxxx                      │
│  └─ RAT Contract: 0x<deterministic_address>                 │
└─────────────────────────────────────────────────────────────┘
```

## 전제 조건

### 필수 소프트웨어
- Docker
- Go 1.22+
- Foundry (forge, cast)
- Kurtosis
- Just (makefile alternative)

### 시스템 요구사항
- CPU: 4+ cores
- RAM: 16GB+
- Disk: 50GB+

## 단계별 가이드

### Step 0: 환경 준비 (한 번만)

```bash
# 1. Optimism devnet 도구 설치
cd lib/optimism/op-challenger/scripts
./install-tools.sh

# 2. Docker 이미지 사전 다운로드 (선택 사항, 하지만 권장)
./pre-download-images.sh --skip-asterisc  # GameType 0만 사용
```

### Step 1: Genesis 생성 (한 번만)

**기존 E2E 테스트의 Genesis 생성 재사용**:

```bash
# 프로젝트 루트로 이동
cd /Users/zena/tokamak-projects/ton-staking-v2

# 기존 방법으로 Genesis 생성 (기존 코드 수정 없음)
make devnet-allocs-offline
```

**이 명령은 다음을 수행합니다** (기존 방식 그대로):

1. Optimism devnet allocs 생성
2. TON Staking V3 contracts 컴파일
3. Genesis 병합 (`vm.loadAllocs` + `vm.dumpState`)
4. `.devnet/genesis-l1-staking-v3.json` 생성

**출력 확인**:
```bash
ls -lh .devnet/
# genesis-l1-staking-v3.json  # Anvil용 Genesis
# allocs-l1-staking-v3.json    # Raw allocs
# addresses.json               # Contract 주소들
```

### Step 2: Genesis를 Kurtosis용으로 준비

Kurtosis는 `allocs-l1.json` 형식을 사용하므로 변환이 필요합니다:

```bash
# Genesis를 Optimism devnet 디렉토리로 복사
cp .devnet/allocs-l1-staking-v3.json lib/optimism/.devnet/allocs-l1.json

# CANNON binaries 빌드 (처음 한 번만)
cd lib/optimism/op-challenger/scripts
./build-binaries-for-challenger.sh --force
```

### Step 3: Persistent Devnet 시작

```bash
# 프로젝트 루트로 돌아가기
cd /Users/zena/tokamak-projects/ton-staking-v2

# 방법 1: Makefile 사용 (권장)
make devnet-start

# 방법 2: 스크립트 직접 실행
./scripts/start-persistent-devnet.sh
```

**Devnet 시작 확인:**

```bash
# Kurtosis 서비스 상태 확인
kurtosis enclave inspect simple-devnet

# 예상 출력:
# - el-1-geth-teku (L1 execution)
# - cl-1-teku-geth (L1 consensus)
# - op-el-2151908-node0-op-geth (L2 execution)
# - op-cl-2151908-node0-op-node (L2 consensus)
# - op-batcher-2151908-op-kurtosis
# - op-proposer-2151908-op-kurtosis
```

**RPC 엔드포인트 자동 추출:**

```bash
# RPC 정보 스크립트 실행
./scripts/get-devnet-info.sh

# 출력 예시:
# L1 RPC: http://localhost:53620
# L2 RPC: http://localhost:56781
# Rollup RPC: http://localhost:57029
#
# Contract Addresses (from genesis):
# DisputeGameFactory: 0x...
# RAT Proxy: 0x...
# SystemConfig: 0x...
```

### Step 4: RAT 연동 확인

```bash
# L1 RPC URL (위에서 확인한 값 사용)
export L1_RPC=http://localhost:53620

# RAT이 DisputeGameFactory에 연결되었는지 확인
cast call $DISPUTE_GAME_FACTORY "rat()(address)" --rpc-url $L1_RPC
# 예상 출력: RAT Proxy 주소

# RAT 파라미터 확인
cast call $RAT_PROXY "triggerProbability()(uint256)" --rpc-url $L1_RPC
# 예상 출력: 1000000000000000000000000000 (100% = RAY)
```

### Step 5: RAT Client 실행

```bash
# 방법 1: 자동화 스크립트 (권장)
./scripts/run-rat-client.sh

# 방법 2: 수동 실행
./bin/rat-client \
  --l1-rpc http://localhost:53620 \
  --l2-rpc http://localhost:56781 \
  --rollup-rpc http://localhost:57029 \
  --rat-contract 0x<RAT_PROXY_ADDRESS> \
  --private-key 0x... \
  --poll-interval 10s
```

**RAT Client 설정 파일 사용:**

```bash
# config/rat-client.yaml 생성 후
./bin/rat-client --config config/rat-client.yaml
```

### Step 6: 테스트 시나리오 실행

#### 시나리오 1: 기본 동작 확인

```bash
# 1. L2에서 트랜잭션 발생
cast send 0x... "transfer(address,uint256)" \
  0x... 1000000000000000000 \
  --rpc-url http://localhost:56781 \
  --private-key 0x...

# 2. op-batcher가 배치를 L1에 제출 (자동)
# 3. op-proposer가 output root 제출 (자동)
# 4. DisputeGame 생성 및 RAT 트리거 (자동)

# 5. RAT Client 로그 확인
# - AttentionTestTriggered 이벤트 감지
# - Validator 선택 여부 확인
# - Evidence 제출 (선택된 경우)
```

#### 시나리오 2: Attention Test 강제 트리거

```bash
# RAT triggerProbability가 100%로 설정되어 있어
# 모든 DisputeGame 생성 시 Attention Test가 트리거됩니다.

# RAT Client가 선택되었는지 로그 확인:
# [INFO] AttentionTestTriggered: gameAddress=0x..., batchIndex=1
# [INFO] Selected validator: 0x... (matches our address)
# [INFO] Starting verification...
# [INFO] Evidence submitted successfully
```

#### 시나리오 3: 여러 DisputeGame 동시 처리

```bash
# L2에서 여러 트랜잭션을 빠르게 발생
for i in {1..10}; do
  cast send 0x... "transfer(address,uint256)" \
    0x... $((i * 1000000000000000000)) \
    --rpc-url http://localhost:56781 \
    --private-key 0x... &
done
wait

# RAT Client가 여러 게임을 올바르게 추적하는지 확인
```

## 로그 모니터링

### L1 Chain
```bash
# L1 Execution
kurtosis service logs simple-devnet el-1-geth-teku -f

# L1 Consensus
kurtosis service logs simple-devnet cl-1-teku-geth -f
```

### L2 Chain
```bash
# L2 Execution
kurtosis service logs simple-devnet op-el-2151908-node0-op-geth -f

# L2 Consensus (Rollup RPC)
kurtosis service logs simple-devnet op-cl-2151908-node0-op-node -f

# Batcher
kurtosis service logs simple-devnet op-batcher-2151908-op-kurtosis -f

# Proposer
kurtosis service logs simple-devnet op-proposer-2151908-op-kurtosis -f
```

### RAT Contract Events
```bash
# AttentionTestTriggered 이벤트 모니터링
cast logs --from-block 0 \
  --address $RAT_PROXY \
  --rpc-url $L1_RPC

# EvidenceSubmitted 이벤트
cast logs --from-block 0 \
  --address $RAT_PROXY \
  --event-sig "EvidenceSubmitted(address,uint256,bool)" \
  --rpc-url $L1_RPC
```

## Cleanup

### Devnet 중지
```bash
# 방법 1: Makefile 사용 (권장)
make devnet-stop

# 방법 2: 스크립트 직접 실행
./scripts/stop-devnet.sh

# 방법 3: 수동 (Kurtosis 명령)
kurtosis enclave rm simple-devnet --force
```

### 완전 초기화 (필요 시)
```bash
# 모든 Kurtosis 리소스 정리
kurtosis clean -a

# Docker 컨테이너 및 볼륨 정리
docker system prune -a --volumes

# Genesis 파일 재생성이 필요하면
make devnet-clean
make devnet-allocs-offline  # Genesis 재생성
```

## 트러블슈팅

### Genesis 생성 실패

**문제**: `vm.loadAllocs()` 실패
```
Error: Unable to load allocs from /.devnet/allocs-l1.json
```

**해결**:
```bash
# Optimism contracts가 컴파일되었는지 확인
cd lib/optimism/packages/contracts-bedrock
forge build --force

# allocs-l1.json이 있는지 확인
ls -la lib/optimism/.devnet/allocs-l1.json
```

### Devnet 시작 실패

**문제**: op-deployer 이미지 없음
```
Error: Failed to pull Docker image 'op-deployer:devnet'
```

**해결**: Genesis 방식을 사용하면 op-deployer가 필요 없습니다.
```bash
# Genesis 파일이 올바르게 복사되었는지 확인
diff .devnet/allocs-l1-staking-v3.json lib/optimism/.devnet/allocs-l1.json
```

### RAT 연동 확인 실패

**문제**: DisputeGameFactory.rat() 호출 시 0x0 반환
```bash
cast call $DISPUTE_GAME_FACTORY "rat()(address)" --rpc-url $L1_RPC
# 0x0000000000000000000000000000000000000000
```

**원인**: `_connectToOptimism()` 함수가 실행되지 않았습니다.

**해결**: Genesis에서는 storage가 올바르게 설정되어야 합니다.
```bash
# runForDevnetAlloc()가 vm.dumpState()를 호출했는지 확인
# Storage 값이 포함되는지 확인
```

### RAT Client 연결 실패

**문제**: RPC connection refused
```
Error: dial tcp [::1]:8545: connect: connection refused
```

**해결**:
```bash
# Kurtosis 포트 매핑 확인
kurtosis enclave inspect simple-devnet

# 올바른 포트 사용
export L1_RPC=http://localhost:<ACTUAL_PORT>
```

## 참고 자료

### Optimism Devnet 문서
- [Build Local Network Guide](../lib/optimism/op-challenger/scripts/README.md)
- [Fast Dispute Game Setup](../lib/optimism/op-challenger/scripts/docs/fast-dispute-game-setup.md)
- [Devnet Management](../lib/optimism/op-challenger/scripts/docs/devnet-management.md)

### TON Staking V3 문서
- [RAT Implementation Plan](./rat-client-implementation-plan.md)
- [Type 3 Evidence Verifier](../src/validator/Type3EvidenceVerifier.sol)

### 관련 컨트랙트
- DisputeGameFactory: `lib/optimism/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol`
- FaultDisputeGame: `lib/optimism/packages/contracts-bedrock/src/dispute/FaultDisputeGame.sol`
- RAT: `src/validator/RAT.sol`
- DeployV3FullForDevnet: `script/DeployV3FullForDevnet.s.sol`

## FAQ

**Q: 기존 E2E 테스트 (`make test-e2e`)와 어떻게 다른가요?**

A:
- **기존 E2E**: Go 테스트가 isolated nodes를 매번 시작하고 자동 테스트 후 종료
  - 빠른 자동화 테스트에 적합
  - CI/CD에서 사용

- **Persistent Devnet**: Kurtosis로 devnet을 띄우고 수동/장시간 테스트
  - RAT Client 개발 및 디버깅에 적합
  - 수동 테스트 및 로그 관찰

둘 다 같은 Genesis를 사용하므로 **동일한 초기 상태**를 가집니다.

**Q: 기존 코드를 수정하지 않는다는데, 추가만 하는 건가요?**

A: 네, 맞습니다:
- ✅ 기존 `make test-e2e` 그대로 작동
- ✅ 기존 `make devnet-allocs-offline` 재사용
- ✅ 새로운 `make devnet-start`, `make devnet-stop` 추가
- ❌ 기존 스크립트/타겟 수정 없음

**Q: `lib/optimism/.devnet/allocs-l1.json`을 git에 커밋해야 하나요?**

A: 아니요. 이 파일은 생성된 파일이므로 `.gitignore`에 추가되어 있고, `make devnet-allocs-offline`로 매번 생성합니다.

**Q: 컨트랙트를 수정하면 어떻게 해야 하나요?**

A: Genesis를 다시 생성하고 devnet을 재시작합니다:
```bash
# 1. 코드 수정
vim src/validator/RAT.sol

# 2. Genesis 재생성
./scripts/setup-devnet-genesis.sh

# 3. Devnet 재시작
kurtosis enclave rm simple-devnet --force
./scripts/start-devnet.sh
```

**Q: 여러 개의 RAT Client를 실행할 수 있나요?**

A: 네, 다른 private key로 여러 validator를 실행할 수 있습니다:
```bash
# Validator 1
./bin/rat-client --config config/rat-client-1.yaml &

# Validator 2
./bin/rat-client --config config/rat-client-2.yaml &
```

각 validator는 독립적으로 선택되고 evidence를 제출합니다.

## 다음 단계

1. **자동화 스크립트 개선**
   - 헬스체크 추가
   - 에러 핸들링 강화
   - 로그 집계

2. **모니터링 대시보드**
   - Grafana/Prometheus 통합
   - RAT Client 메트릭

3. **CI/CD 통합**
   - GitHub Actions에서 E2E 테스트 자동 실행
   - 컨트랙트 변경 시 자동 검증

4. **프로덕션 배포 준비**
   - Mainnet fork 테스트
   - Gas 최적화
   - Security audit
