# RAT E2E Testing - Complete Guide

## 개요

**State Root as Target** 설계의 완전한 E2E 테스트 가이드입니다.

실제 Optimism 환경에서:
1. ✅ **op-proposer**가 DisputeGame 생성 (rootClaim = hash(OutputRootProof))
2. ✅ **RAT contract**가 AttentionTest trigger
3. ✅ **RAT client**가 state trie에서 adjacent leaves 찾기
4. ✅ **op-node**에서 OutputRootProof 가져오기
5. ✅ **검증 후 L1에 제출**

---

## 사전 준비

### 1. 필수 도구 설치

```bash
# Foundry (forge, cast, anvil)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Go 1.21+
# https://go.dev/dl/

# Kurtosis (devnet 관리)
# https://docs.kurtosis.com/install

# Docker
# https://docs.docker.com/get-docker/
```

### 2. Optimism 레포지토리 클론

```bash
cd ton-staking-v2

# Optimism monorepo
git submodule update --init --recursive lib/optimism

# 또는 직접 클론
git clone https://github.com/ethereum-optimism/optimism.git lib/optimism
```

---

## E2E 테스트 실행

### Phase 1: Devnet 시작

Optimism 전체 스택을 시작합니다:
- L1 geth
- L2 op-geth (디버그 모드, state DB 접근 가능)
- op-node (Rollup RPC)
- op-batcher
- op-proposer (DisputeGame 생성)

```bash
cd clients/rat-client-type3

# Devnet 시작 (5-10분 소요)
make devnet-up
```

**예상 출력:**
```
🚀 Starting Optimism devnet...
This will start:
  - L1 geth
  - L2 geth
  - op-node (Rollup RPC)
  - op-batcher
  - op-proposer

Building devnet...
[Kurtosis] Creating enclave 'simple-devnet'...
[Kurtosis] Starting services...

✅ Devnet started successfully!

Endpoints:
  L1 RPC:       http://localhost:8545
  L2 RPC:       http://localhost:9545
  op-node RPC:  http://localhost:9546
```

### Phase 2: Devnet 상태 확인

```bash
# 전체 상태 확인
make devnet-check

# 개별 서비스 확인
kurtosis service inspect simple-devnet l1-el-cl-genesis-data
kurtosis service inspect simple-devnet op-geth
kurtosis service inspect simple-devnet op-node
kurtosis service inspect simple-devnet op-batcher
kurtosis service inspect simple-devnet op-proposer
```

**중요 확인 사항:**

1. **L2 op-geth가 실행 중이고 블록 생성 중**
```bash
cast block latest --rpc-url http://localhost:9545
```

2. **op-node가 sync 중**
```bash
curl http://localhost:9546 -X POST \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"optimism_syncStatus","params":[],"id":1}'
```

3. **op-proposer가 DisputeGame 생성 중**
```bash
# L1에서 DisputeGame 이벤트 확인
cast logs --rpc-url http://localhost:8545 \
  --address <DisputeGameFactory> \
  --from-block 0
```

### Phase 3: RAT 컨트랙트 배포

```bash
# RAT + TON Staking V3 컨트랙트를 L1에 배포
make deploy-rat
```

**예상 출력:**
```
📝 Deploying RAT contract to devnet L1...

Step 1: Get Optimism contract addresses from devnet...
  DisputeGameFactory: 0x5FbDB2315678afecb367f032d93F642f64180aa3
  SystemConfig:       0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512

Step 2: Deploy full TON Staking V3 + RAT...
  [Deploying contracts...]
  RAT:  0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
  TON:  0x5FC8d32690cc91D4c39d9d3abcBD16989F875707
  WTON: 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9

Step 3: Extract deployed addresses...
  ✅ Saved to deployments/devnet.json

✅ RAT contract deployed successfully!
```

### Phase 4: State 생성 (트랜잭션 발생)

op-geth의 state trie를 채우기 위해 L2에서 트랜잭션을 발생시킵니다.

```bash
# L2에 여러 계정 생성 (state trie 채우기)
for i in {1..20}; do
  cast send \
    --rpc-url http://localhost:9545 \
    --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
    --value 1ether \
    "0x$(printf '%040x' $i)"
done

# State root 확인
cast block latest --rpc-url http://localhost:9545 -j | jq -r .stateRoot
```

**예상 출력:**
```
0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
```

### Phase 5: op-node에서 OutputRootProof 확인

op-proposer가 DisputeGame을 생성할 때 사용하는 OutputRootProof를 직접 조회합니다.

```bash
# Latest L2 block number
BLOCK_NUM=$(cast block latest --rpc-url http://localhost:9545 -j | jq -r .number)

# OutputRootProof 조회
curl http://localhost:9546 -X POST \
  -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"optimism_outputAtBlock\",\"params\":[\"$BLOCK_NUM\"],\"id\":1}" \
  | jq
```

**예상 출력:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "version": "0x0000000000000000000000000000000000000000000000000000000000000000",
    "outputRoot": "0x920b80f1b5b12f04032ab134ae55e049056785e5e36542c07a7a4a1fa7368bc1",
    "blockRef": {
      "hash": "0xabcd...",
      "number": 100,
      "parentHash": "0x1234...",
      "timestamp": 1704067200
    },
    "withdrawalStorageRoot": "0xfedcba0987654321...",
    "stateRoot": "0x1234567890abcdef...",
    "syncStatus": {...}
  }
}
```

**핵심:** `outputRoot` = `keccak256(abi.encode(version, stateRoot, withdrawalStorageRoot, blockHash))`

### Phase 6: DisputeGame 생성 확인

op-proposer가 주기적으로 DisputeGame을 생성합니다.

```bash
# DisputeGameFactory 주소 확인
DGF_ADDR=$(cat deployments/devnet.json | jq -r .DisputeGameFactory)

# 최근 생성된 게임 확인
cast call $DGF_ADDR "gameCount()" --rpc-url http://localhost:8545

# 특정 게임의 rootClaim 확인
GAME_ADDR=$(cast call $DGF_ADDR "gameAtIndex(uint256)" 0 --rpc-url http://localhost:8545)
cast call $GAME_ADDR "rootClaim()(bytes32)" --rpc-url http://localhost:8545
```

**중요:** 이 `rootClaim`이 바로 `hash(OutputRootProof)`입니다!

### Phase 7: RAT Client 설정

RAT client 설정 파일을 생성합니다.

```bash
cd clients/rat-client-type3

cat > config.devnet.yaml <<EOF
# L1 Configuration
l1_rpc_url: "http://localhost:8545"
rat_contract: "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"  # deployments/devnet.json에서
poll_interval: 5s
confirmations: 1
start_block: 0

# L2 Configuration
l2_rpc_url: "http://localhost:9545"
opnode_rpc_url: "http://localhost:9546"  # ← OutputRootProof 가져올 op-node

# State DB (op-geth의 state trie 접근)
state_db_path: "/path/to/op-geth/datadir/geth/chaindata"
# Kurtosis를 사용하는 경우 경로 확인 필요

# Validator
validator_address: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
private_key: "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

# Gas settings
gas_limit: 500000
max_gas_price: 100000000000  # 100 gwei
EOF
```

**State DB 경로 찾기:**
```bash
# Kurtosis로 실행한 경우
kurtosis service inspect simple-devnet op-geth

# 출력에서 volume mount 확인
# 또는 docker inspect로 확인
docker ps | grep op-geth
docker inspect <container_id> | grep -i volume
```

### Phase 8: RAT Client 실행

```bash
cd clients/rat-client-type3

# Build
make build

# Run
./bin/rat-client --config config.devnet.yaml
```

**예상 로그:**
```
INFO[0000] RAT Client Started
INFO[0000] Configuration:
  L1 RPC: http://localhost:8545
  L2 RPC: http://localhost:9545
  op-node RPC: http://localhost:9546
  RAT Contract: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
  State DB: /path/to/op-geth/datadir/geth/chaindata

INFO[0001] Monitoring L1 for AttentionTest events...
INFO[0005] Current L1 block: 100
```

### Phase 9: RAT 트리거 (수동)

테스트를 위해 수동으로 AttentionTest를 트리거합니다.

```bash
# RAT contract에서 triggerAttentionTest 호출
cd ../../  # ton-staking-v2 root

# Forge script로 트리거
cat > script/TriggerRATTest.s.sol <<EOF
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import {RAT} from "../src/validator/RAT.sol";

contract TriggerRATTest is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address ratAddress = vm.envAddress("RAT_ADDRESS");
        address gameAddress = vm.envAddress("GAME_ADDRESS");
        address systemConfig = vm.envAddress("SYSTEM_CONFIG");

        vm.startBroadcast(deployerPrivateKey);

        RAT rat = RAT(ratAddress);

        // Trigger attention test
        rat.triggerAttentionTest(
            gameAddress,
            systemConfig,
            1,  // batchIndex
            keccak256("batch1"),
            keccak256("block1")
        );

        vm.stopBroadcast();
    }
}
EOF

# 실행
RAT_ADDRESS=0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 \
GAME_ADDRESS=<DisputeGame address> \
SYSTEM_CONFIG=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 \
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
forge script script/TriggerRATTest.s.sol:TriggerRATTest \
  --rpc-url http://localhost:8545 \
  --broadcast
```

### Phase 10: RAT Client 동작 확인

RAT Client 로그에서 전체 플로우를 확인합니다.

**예상 로그:**
```
INFO[0010] AttentionTest triggered!
  testID: 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
  validator: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
  gameAddress: 0x5FbDB2315678afecb367f032d93F642f64180aa3
  deadline: 2024-01-09 12:00:00

INFO[0011] Finding adjacent leaves in state trie...
  randomValue: 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
  blockNumber: 12345

INFO[0015] Found adjacent leaves
  leafA.key: 0x0000000000000000000000000000000000000000000000000000000000001000
  leafA.balance: 1000000000000000000
  leafB.key: 0x0000000000000000000000000000000000000000000000000000000000002000
  leafB.balance: 2000000000000000000
  stateRoot: 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef

INFO[0016] Fetching OutputRootProof from op-node
  blockNumber: 12345

INFO[0017] OutputRootProof fetched ← 🎯 KEY STEP!
  version: 0x0000000000000000000000000000000000000000000000000000000000000000
  stateRoot: 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
  messagePasserStorageRoot: 0xfedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321
  latestBlockHash: 0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd

INFO[0017] StateRoot matches between op-node and state trie ✅

INFO[0018] Evidence created
  size: 2456 bytes
  leafA: 0x1000
  leafB: 0x2000
  proofA nodes: 12
  proofB nodes: 12
  outputRootProof: included ✅

INFO[0019] Submitting evidence to L1...

INFO[0022] Evidence submitted successfully! ✅
  txHash: 0xdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abc
  blockNumber: 105
  gasUsed: 234567

INFO[0023] Validator deposit restored ✅
```

### Phase 11: 온체인 검증 확인

L1에서 실제로 검증이 통과했는지 확인합니다.

```bash
# RAT contract에서 테스트 상태 확인
TEST_ID=0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef

# Test status 확인
cast call $RAT_ADDRESS \
  "attentionTests(bytes32)(address,address,uint32,address,bytes32,uint256,uint256,uint256,uint8)" \
  $TEST_ID \
  --rpc-url http://localhost:8545

# Status should be RESPONDED (1)

# Validator registration 확인
cast call $RAT_ADDRESS \
  "getValidatorRegistration(address,address)(uint256,uint256,uint256,bool)" \
  0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
  $SYSTEM_CONFIG \
  --rpc-url http://localhost:8545

# Deposit should be restored
# Bond should be 0
```

---

## 전체 플로우 다이어그램

```
┌─────────────────────────────────────────────────────────────────┐
│  Phase 1-5: Environment Setup                                   │
│  - Devnet 시작                                                   │
│  - RAT contract 배포                                             │
│  - State 생성 (트랜잭션)                                         │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  Phase 6: op-proposer                                           │
│                                                                  │
│  1. L2 state root 조회                                          │
│  2. OutputRootProof 생성:                                        │
│     {version, stateRoot, withdrawalRoot, blockHash}             │
│  3. rootClaim = keccak256(abi.encode(OutputRootProof))          │
│  4. DisputeGame 생성 with rootClaim                             │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  Phase 9: RAT Trigger (Manual or Automatic)                     │
│                                                                  │
│  RAT.triggerAttentionTest(gameAddress, ...)                     │
│  → AttentionTestTriggered event                                 │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  Phase 10: RAT Client                                           │
│                                                                  │
│  1. Monitor L1 for AttentionTest events                         │
│  2. Find adjacent leaves in op-geth state trie:                 │
│     - Open LevelDB: /path/to/op-geth/datadir/geth/chaindata    │
│     - Search Patricia Merkle Trie                               │
│     - Find leafA, leafB where: leafA < stateRoot < leafB        │
│  3. Generate Merkle proofs for leafA and leafB                  │
│  4. Fetch OutputRootProof from op-node:                         │
│     - Call optimism_outputAtBlock(blockNum)                     │
│     - Extract {version, stateRoot, withdrawalRoot, blockHash}   │
│  5. Verify: hash(OutputRootProof) == rootClaim                  │
│  6. Create StateLeafEvidence:                                    │
│     {leafA, leafB, proofs, OutputRootProof}                     │
│  7. Submit to L1: rat.submitEvidence(testId, 1, evidence)       │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  Phase 11: On-chain Verification                                │
│                                                                  │
│  Type3EvidenceVerifier.verifyStateLeaf():                        │
│  1. Decode evidence → StateLeafEvidence                          │
│  2. hash(OutputRootProof) == rootClaim? ✅                       │
│  3. leafA.key < stateRoot < leafB.key? ✅                        │
│  4. Verify Merkle proofs for leafA ✅                            │
│  5. Verify Merkle proofs for leafB ✅                            │
│  6. All checks passed → Restore validator deposit ✅            │
└─────────────────────────────────────────────────────────────────┘
```

---

## 트러블슈팅

### 1. Devnet 시작 실패

```bash
# Kurtosis 상태 확인
kurtosis enclave ls

# 기존 enclave 삭제
kurtosis enclave rm -f simple-devnet

# 재시작
cd clients/rat-client-type3
make devnet-up
```

### 2. State DB 접근 실패

```bash
# op-geth 컨테이너 찾기
docker ps | grep op-geth

# State DB 경로 확인
docker inspect <container_id> | grep -A 10 Mounts

# 직접 접근 테스트
ls -la /path/to/state/db/geth/chaindata
```

### 3. op-node 연결 실패

```bash
# op-node 상태 확인
curl http://localhost:9546 -X POST \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"optimism_syncStatus","params":[],"id":1}'

# 로그 확인
make devnet-logs
```

### 4. RAT Client가 adjacent leaves를 못 찾음

```bash
# State trie에 데이터가 충분한지 확인
cast block latest --rpc-url http://localhost:9545 -j | jq .stateRoot

# 더 많은 트랜잭션 생성
for i in {1..50}; do
  cast send --rpc-url http://localhost:9545 \
    --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
    --value 0.1ether "0x$(printf '%040x' $i)"
done
```

---

## 정리 및 종료

```bash
# RAT client 중지 (Ctrl+C)

# Devnet 중지
cd clients/rat-client-type3
make devnet-down

# 데이터 정리
rm -rf /tmp/rat-e2e
```

---

## 자동화된 E2E 테스트

위 과정을 자동화한 스크립트:

```bash
cd clients/rat-client-type3

# 전체 E2E 테스트 실행 (devnet 시작 → 테스트 → 종료)
make test-full
```

---

## 결론

이 가이드를 따라하면:

✅ **op-proposer**가 DisputeGame을 생성하는 과정 확인
✅ **RAT client**가 state trie에서 adjacent leaves를 찾는 과정 확인
✅ **op-node**에서 OutputRootProof를 가져오는 과정 확인
✅ **온체인 검증**이 통과하는 것 확인

**State Root as Target** 설계의 전체 플로우가 실제 환경에서 동작하는 것을 확인할 수 있습니다! 🎉
