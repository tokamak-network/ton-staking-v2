# RAT E2E 테스트 빠른 시작 가이드

## 개요

Kurtosis 없이 RAT client를 테스트할 수 있는 가장 실용적인 방법입니다.

## 아키텍처

```
┌─────────────┐
│   L1 (Anvil) │  ← RAT Contract, DisputeGameFactory
└──────┬──────┘
       │
       │ RAT Event
       ↓
┌─────────────────┐         ┌────────────────┐
│  RAT Client     │────────→│  L2 (geth)     │
│  (Go)           │  Query  │  State DB      │
└─────────────────┘         └────────────────┘
        │
        │ Submit Evidence
        ↓
   L1 RAT Contract
```

## 단계별 설명

### Step 1: L1 (Anvil) 시작
```bash
anvil --port 8545 --block-time 1
```
- 빠른 블록 생성 (1초)
- 고정된 계정 사용 가능

### Step 2: L2 (geth) 시작
```bash
# Genesis 생성
geth --datadir /tmp/l2 init genesis-l2.json

# Dev mode로 실행
geth --datadir /tmp/l2 \
  --http --http.port 9545 \
  --http.api "eth,web3,net,debug" \
  --dev --dev.period 2 \
  --gcmode archive
```
- Dev mode: 트랜잭션 즉시 처리
- Archive mode: 모든 state 보존
- Debug API: state trie 접근 가능

### Step 3: L2에 State 생성
```bash
# 계정 20개 생성 → state trie에 leaf 추가
for i in {1..20}; do
    cast send --rpc-url http://localhost:9545 \
        --value 0.1ether \
        "0x$(printf '%040x' $i)"
done
```

### Step 4: L1에 Contract 배포
```bash
forge script script/DeployV3Full.s.sol:DeployV3Full \
    --rpc-url http://localhost:8545 \
    --broadcast
```
- RAT Contract
- DisputeGameFactory (mock)
- SystemConfig (mock)

### Step 5: DisputeGame 생성
**핵심!** op-proposer 없이 수동으로 게임 생성:

```solidity
// CreateGame.s.sol
bytes32 stateRoot = vm.envBytes32("STATE_ROOT");
bytes32 l2BlockHash = vm.envBytes32("L2_BLOCK_HASH");

// OutputRootProof 생성
bytes32 rootClaim = keccak256(abi.encode(
    bytes32(0),           // version
    stateRoot,            // L2 state root
    bytes32(0x5678),      // withdrawalRoot (mock)
    l2BlockHash           // L2 block hash
));

// DisputeGame 생성
address game = IDisputeGameFactory(factory).create(
    0,          // gameType
    rootClaim,  // hash(OutputRootProof)
    abi.encode(uint256(1))
);
```

### Step 6: RAT Client 실행
```yaml
# config.test.yaml
l1_rpc_url: "http://localhost:8545"
l2_rpc_url: "http://localhost:9545"
state_db_path: "/tmp/l2/geth/chaindata"
rat_contract: "0x5FbDB2315678afecb367f032d93F642f64180aa3"
validator_address: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
private_key: "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
```

```bash
./bin/rat-client --config config.test.yaml
```

### Step 7: RAT Client 동작

1. **RAT Event 감지**
   - L1에서 AttentionTestTriggered 이벤트 수신
   - testId, gameAddress 추출

2. **Adjacent Leaves 검색**
   - L2 state DB 연결 (`/tmp/l2/geth/chaindata`)
   - DisputeGame의 rootClaim 조회
   - OutputRootProof 복원 → stateRoot 추출
   - Patricia trie에서 adjacent leaves 검색:
     - leafA.key < stateRoot < leafB.key
     - 연속된 두 leaf (사이에 다른 leaf 없음)

3. **Evidence 생성**
   ```go
   evidence := StateLeafEvidence{
       LeafAKey:   leafA.Key,
       LeafAValue: leafA.Value,
       LeafAProof: leafA.Proof,
       LeafBKey:   leafB.Key,
       LeafBValue: leafB.Value,
       LeafBProof: leafB.Proof,
       OutputRootProof: OutputRootProof{
           Version:                  [32]byte{},
           StateRoot:                stateRoot,
           MessagePasserStorageRoot: withdrawalRoot,
           LatestBlockHash:          blockHash,
       },
   }
   ```

4. **L1에 제출**
   ```solidity
   RAT.submitEvidence(testId, 1, abi.encode(evidence))
   ```

5. **Contract 검증**
   - `hash(OutputRootProof) == rootClaim` ✅
   - `leafA.key < stateRoot < leafB.key` ✅
   - Merkle proofs valid ✅

## 전체 흐름 다이어그램

```
[L2 geth]
   │
   ├─ Transactions → State changes
   │                     │
   │                     ↓
   │              State Trie updated
   │                     │
   │                     ├─ stateRoot: 0x1234...
   │                     ├─ Leaf 0x1000: Account A
   │                     ├─ Leaf 0x1234: Account B  ← Target!
   │                     └─ Leaf 0x1500: Account C
   │
   └─ State DB: /tmp/l2/geth/chaindata

[L1 Anvil]
   │
   ├─ RAT Contract deployed
   ├─ DisputeGame created with:
   │    rootClaim = keccak256(abi.encode(
   │        version, stateRoot=0x1234..., withdrawalRoot, blockHash
   │    ))
   │
   └─ RAT Event: AttentionTestTriggered(testId, gameAddress)

[RAT Client]
   │
   ├─ Listen to RAT Event
   │
   ├─ Query DisputeGame.rootClaim()
   │
   ├─ Decode rootClaim → OutputRootProof → stateRoot = 0x1234...
   │
   ├─ Connect to State DB: /tmp/l2/geth/chaindata
   │
   ├─ Search Adjacent Leaves:
   │    ├─ Find leafA: key=0x1000 (< 0x1234)
   │    └─ Find leafB: key=0x1500 (> 0x1234)
   │
   ├─ Generate Merkle Proofs for both leaves
   │
   ├─ Create Evidence with OutputRootProof
   │
   └─ Submit to L1: RAT.submitEvidence(testId, evidence)
```

## 왜 이 방법이 작동하는가?

### 1. Real L2 State DB ✅
- geth가 실제 Patricia trie 생성
- RAT client가 direct access 가능
- Adjacent leaves 실제로 검색 가능

### 2. Real State Root ✅
- L2 transactions → state changes → stateRoot 생성
- 이 stateRoot를 target으로 사용
- Merkle proofs가 실제로 검증 가능

### 3. Simplified DisputeGame ✅
- op-proposer 없이 수동 생성
- 하지만 구조는 동일:
  ```
  rootClaim = hash(OutputRootProof)
  OutputRootProof.stateRoot = L2 state root
  ```

### 4. Full RAT Flow ✅
```
Trigger → Listen → Query → Search → Generate → Submit → Verify
```
모든 단계가 실제로 작동!

## 무엇이 Mock인가?

| Component | Status | Note |
|-----------|--------|------|
| L2 State | ✅ Real | geth dev mode |
| State Trie | ✅ Real | Patricia Merkle Trie |
| Adjacent Leaves | ✅ Real | Actual search |
| OutputRootProof | ⚠️ Simplified | Manual creation |
| DisputeGame | ⚠️ Mock | No op-proposer |
| Merkle Proofs | ✅ Real | From state DB |
| RAT Verification | ✅ Real | Full contract logic |

## 자동화 스크립트

모든 과정을 자동화한 스크립트:
```bash
./scripts/run-e2e-test-final.sh
```

이 스크립트는:
1. ✅ L1 (Anvil) 시작
2. ✅ L2 (geth) 시작 + genesis
3. ✅ L2 state 생성 (20 accounts)
4. ✅ L1 contracts 배포
5. ✅ DisputeGame 생성 (Forge script)
6. ✅ 환경 정보 출력

그 다음 RAT client 수동 실행:
```bash
cd clients/rat-client-type3
./bin/rat-client --config config.test.yaml
```

## 실제 실행 예시

```bash
# Terminal 1: E2E 환경 시작
./scripts/run-e2e-test-final.sh

# 출력:
# ✅ L1 started
# ✅ L2 started
# ✅ State generated (Block: 21, StateRoot: 0x1234...)
# ✅ Contracts deployed
# ✅ DisputeGame created: 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
#
# RAT Client Config:
# l1_rpc_url: "http://localhost:8545"
# l2_rpc_url: "http://localhost:9545"
# state_db_path: "/tmp/rat-e2e-final-1234567/l2/geth/chaindata"
# rat_contract: "0x5FbDB2315678afecb367f032d93F642f64180aa3"

# Terminal 2: RAT Client 실행
cd clients/rat-client-type3
cat > config.test.yaml <<EOF
l1_rpc_url: "http://localhost:8545"
l2_rpc_url: "http://localhost:9545"
state_db_path: "/tmp/rat-e2e-final-1234567/l2/geth/chaindata"
rat_contract: "0x5FbDB2315678afecb367f032d93F642f64180aa3"
validator_address: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
private_key: "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
EOF

make build
./bin/rat-client --config config.test.yaml

# Terminal 3: RAT 트리거 (테스트용)
cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 \
  "triggerAttentionTest(address,address,uint32,bytes32,bytes32)" \
  0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9 \
  0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 \
  1 \
  0x0000000000000000000000000000000000000000000000000000000000000001 \
  0x0000000000000000000000000000000000000000000000000000000000000002 \
  --rpc-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

## 결론

이 방법은:
- ✅ Kurtosis 불필요
- ✅ 빠른 시작 (30초)
- ✅ 실제 L2 state DB 사용
- ✅ RAT client의 모든 기능 테스트 가능
- ✅ 디버깅 용이

유일한 단순화:
- DisputeGame을 op-proposer가 아닌 Forge script로 생성
- 하지만 RAT 검증 로직은 완전히 동일!
