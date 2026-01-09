# RAT E2E 자동화 테스트 가이드

## 개요

**완전 자동화된 E2E 테스트 스크립트**입니다. 한 번의 명령으로 전체 RAT 플로우를 테스트할 수 있습니다.

## 특징

✅ **완전 자동화**: 수동 개입 없이 전체 테스트 실행
✅ **Kurtosis 불필요**: 간단한 도구만 사용
✅ **빠른 실행**: 약 1-2분 내 완료
✅ **실제 환경**: Real L2 state DB 사용
✅ **검증 포함**: 자동으로 결과 확인

## 필요한 도구

```bash
# Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Go 1.22+
# geth (이미 설치되어 있음)
```

## 실행 방법

### 한 줄 명령어

```bash
./scripts/run-e2e-test-auto.sh
```

### 전체 흐름

스크립트가 자동으로 다음을 수행합니다:

1. **환경 셋업** (30초)
   - L1 (Anvil) 시작
   - L2 (geth dev mode) 시작
   - L2 state 생성 (20 accounts)

2. **Contract 배포** (10초)
   - RAT Contract
   - DisputeGameFactory (mock)
   - SystemConfig (mock)
   - TON Token

3. **Validator 등록** (5초)
   - TON approve
   - Validator 등록
   - 담보금 200 TON

4. **DisputeGame 생성** (5초)
   - L2 state root 조회
   - OutputRootProof 생성
   - DisputeGame 생성 (Forge script)

5. **RAT Client 시작** (5초)
   - Config 자동 생성
   - Background로 실행

6. **RAT 트리거** (즉시)
   - AttentionTest 발생
   - RAT Client가 이벤트 감지

7. **Evidence 제출 대기** (10-30초)
   - RAT Client가 adjacent leaves 검색
   - Evidence 자동 생성
   - L1에 제출

8. **검증** (즉시)
   - Test status 확인
   - Validator deposit 확인
   - 결과 출력

9. **Cleanup** (자동)
   - 모든 프로세스 종료
   - 로그 저장

## 예상 출력

```
╔════════════════════════════════════════════════════╗
║  RAT E2E Automated Test                           ║
║  Complete Flow: Setup → Trigger → Submit → Verify ║
╚════════════════════════════════════════════════════╝

═══════════════════════════════════════════════════
Step 1: Starting L1 (Anvil) & L2 (geth)
═══════════════════════════════════════════════════
✅ L1 started (PID: 12345)
✅ L2 started (PID: 12346)

═══════════════════════════════════════════════════
Step 2: Generating L2 State
═══════════════════════════════════════════════════
....................
✅ L2 state generated
ℹ️   Block: 21
ℹ️   State Root: 0x1234...5678
ℹ️   Block Hash: 0xabcd...ef00

═══════════════════════════════════════════════════
Step 3: Deploying Contracts
═══════════════════════════════════════════════════
✅ Contracts deployed
ℹ️   RAT: 0x5FbDB2315678afecb367f032d93F642f64180aa3
ℹ️   DisputeGameFactory: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
ℹ️   SystemConfig: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
ℹ️   TON: 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9

═══════════════════════════════════════════════════
Step 4: Registering Validator
═══════════════════════════════════════════════════
✅ Validator registered

═══════════════════════════════════════════════════
Step 5: Creating DisputeGame with OutputRootProof
═══════════════════════════════════════════════════
ℹ️  Creating OutputRootProof from L2 state...
✅ DisputeGame created!
ℹ️   Game Address: 0x1234...5678

═══════════════════════════════════════════════════
Step 6: Building RAT Client
═══════════════════════════════════════════════════
✅ RAT client ready

═══════════════════════════════════════════════════
Step 7: Preparing RAT Client Config
═══════════════════════════════════════════════════
✅ Config created

═══════════════════════════════════════════════════
Step 8: Starting RAT Client
═══════════════════════════════════════════════════
✅ RAT client started (PID: 12347)

═══════════════════════════════════════════════════
Step 9: Triggering Attention Test
═══════════════════════════════════════════════════
ℹ️  Triggering RAT...
ℹ️   Game: 0x1234...5678
ℹ️   SystemConfig: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
ℹ️   BatchIndex: 1
✅ Attention test triggered
ℹ️   Test ID: 0xabcd...ef00

═══════════════════════════════════════════════════
Step 10: Waiting for Evidence Submission
═══════════════════════════════════════════════════
ℹ️  Waiting for RAT client to submit evidence...
ℹ️  (This may take 10-30 seconds)
.............
✅ Evidence submitted!
ℹ️   Test status: Responded

═══════════════════════════════════════════════════
Step 11: Verifying Test Result
═══════════════════════════════════════════════════
ℹ️   Validator deposit: 200000000000000000000000000
✅ Test status retrieved

═══════════════════════════════════════════════════
Step 12: RAT Client Logs
═══════════════════════════════════════════════════

Last 20 lines of RAT client log:
═══════════════════════════════════════════════════
INFO[0005] RAT client started
INFO[0010] AttentionTestTriggered event detected         testId=0xabcd...
INFO[0012] Querying DisputeGame for rootClaim           game=0x1234...
INFO[0013] OutputRootProof decoded                      stateRoot=0x1234...
INFO[0014] Searching for adjacent leaves                target=0x1234...
INFO[0015] Found adjacent leaves                        leafA=0x1000 leafB=0x1500
INFO[0016] Generating Merkle proofs
INFO[0017] Creating StateLeafEvidence
INFO[0018] Submitting evidence to L1                    testId=0xabcd...
INFO[0019] Evidence submitted successfully              txHash=0x...
═══════════════════════════════════════════════════

═══════════════════════════════════════════════════
Summary
═══════════════════════════════════════════════════

╔════════════════════════════════════════════════════╗
║  ✅ E2E Test Completed Successfully!              ║
╚════════════════════════════════════════════════════╝

📊 Test Flow:

   1. ✅ L1 (Anvil) started
   2. ✅ L2 (geth) started with real state
   3. ✅ Contracts deployed (RAT, TON, DGF)
   4. ✅ Validator registered
   5. ✅ DisputeGame created with OutputRootProof
   6. ✅ RAT client started
   7. ✅ Attention test triggered
   8. ✅ Evidence submitted by RAT client
   9. ✅ Evidence verified on-chain

📝 Key Addresses:

   RAT Contract:    0x5FbDB2315678afecb367f032d93F642f64180aa3
   DisputeGame:     0x1234567890123456789012345678901234567890
   SystemConfig:    0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
   Validator:       0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

📋 Logs:

   L1:              /tmp/rat-e2e-auto-1234567890/l1.log
   L2:              /tmp/rat-e2e-auto-1234567890/l2.log
   RAT Client:      /tmp/rat-e2e-auto-1234567890/rat-client.log
   Full logs:       /tmp/rat-e2e-auto-1234567890/

✅ All tests passed!

🧹 Cleanup...
✅ E2E Test PASSED!
```

## 테스트 항목

이 스크립트는 다음을 검증합니다:

### 1. L2 State 생성 ✅
- geth dev mode에서 transactions 실행
- Real Patricia Merkle Trie 생성
- State root 생성

### 2. OutputRootProof 생성 ✅
```solidity
OutputRootProof {
    version: bytes32(0),
    stateRoot: 0x1234...,  // L2 state root
    messagePasserStorageRoot: 0x5678...,
    latestBlockHash: 0xabcd...
}

rootClaim = keccak256(abi.encode(OutputRootProof))
```

### 3. DisputeGame 생성 ✅
- Forge script로 수동 생성
- rootClaim 설정
- L1에 배포

### 4. RAT Event 감지 ✅
- L1 이벤트 리스닝
- AttentionTestTriggered 파싱
- testId, gameAddress 추출

### 5. Adjacent Leaves 검색 ✅
- L2 state DB 직접 접근
- Patricia Merkle Trie 순회
- leafA < target < leafB 찾기

### 6. Evidence 생성 ✅
```go
StateLeafEvidence {
    LeafAKey:   0x1000,
    LeafAValue: 0x...,
    LeafAProof: [...]bytes,
    LeafBKey:   0x1500,
    LeafBValue: 0x...,
    LeafBProof: [...]bytes,
    OutputRootProof: {...},
    BlockNumber: 21
}
```

### 7. Evidence 제출 ✅
- L1 transaction 생성
- ABI encoding
- Gas estimation
- Transaction 전송

### 8. On-chain 검증 ✅
```solidity
// Contract에서 자동 검증:
1. hash(OutputRootProof) == rootClaim
2. leafA.key < stateRoot < leafB.key
3. Merkle proofs valid
4. Test status → Responded
5. Validator deposit restored
```

## 실패 시 디버깅

### 로그 확인

```bash
# L1 로그
tail -f /tmp/rat-e2e-auto-*/l1.log

# L2 로그
tail -f /tmp/rat-e2e-auto-*/l2.log

# RAT Client 로그
tail -f /tmp/rat-e2e-auto-*/rat-client.log
```

### 일반적인 문제

#### 1. L2 시작 실패
```
❌ L2 failed to start
```
**해결**: geth가 이미 실행 중일 수 있음
```bash
killall geth
./scripts/run-e2e-test-auto.sh
```

#### 2. Contract 배포 실패
```
❌ Deployment failed
```
**해결**: L1이 제대로 시작되지 않음
```bash
# L1 로그 확인
cat /tmp/rat-e2e-auto-*/l1.log
```

#### 3. RAT Client 실행 실패
```
❌ RAT client failed to start
```
**해결**: 빌드 필요
```bash
cd clients/rat-client-type3
make build
cd ../..
./scripts/run-e2e-test-auto.sh
```

#### 4. Evidence 제출 타임아웃
```
❌ No evidence submitted within 60 seconds
```
**해결**: RAT Client 로그 확인
```bash
cat /tmp/rat-e2e-auto-*/rat-client.log
```

가능한 원인:
- State DB 경로 잘못됨
- Adjacent leaves를 찾지 못함
- Merkle proof 생성 실패
- L1 연결 문제

## 환경 변수 (선택사항)

```bash
# L1 포트 변경
L1_PORT=8545 ./scripts/run-e2e-test-auto.sh

# L2 포트 변경
L2_PORT=9545 ./scripts/run-e2e-test-auto.sh

# 더 많은 L2 accounts 생성
L2_ACCOUNT_COUNT=50 ./scripts/run-e2e-test-auto.sh

# Evidence 제출 대기 시간 증가
MAX_WAIT=120 ./scripts/run-e2e-test-auto.sh
```

## CI/CD 통합

### GitHub Actions

```yaml
name: RAT E2E Test

on: [push, pull_request]

jobs:
  e2e-test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3
        with:
          submodules: recursive

      - name: Install Foundry
        uses: foundry-rs/foundry-toolchain@v1

      - name: Install Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.22'

      - name: Install geth
        run: |
          sudo add-apt-repository -y ppa:ethereum/ethereum
          sudo apt-get update
          sudo apt-get install -y ethereum

      - name: Run E2E Test
        run: ./scripts/run-e2e-test-auto.sh
        timeout-minutes: 5

      - name: Upload logs on failure
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: e2e-logs
          path: /tmp/rat-e2e-auto-*/
```

## 수동 테스트 vs 자동 테스트

### 수동 테스트 (`run-e2e-test-final.sh`)
- 환경만 셋업
- RAT Client 수동 실행
- 직접 검증

**장점**: 디버깅 용이, 세밀한 제어
**단점**: 수동 작업 필요

### 자동 테스트 (`run-e2e-test-auto.sh`)
- 전체 플로우 자동 실행
- 결과 자동 검증
- CI/CD 통합 가능

**장점**: 빠름, 반복 가능, CI 적합
**단점**: 실패 시 디버깅 어려움

## 권장 워크플로우

### 개발 중
```bash
# 수동 테스트로 디버깅
./scripts/run-e2e-test-final.sh

# 다른 터미널에서
cd clients/rat-client-type3
./bin/rat-client --config /tmp/rat-e2e-final-*/config.yaml
```

### PR 전
```bash
# 자동 테스트로 전체 검증
./scripts/run-e2e-test-auto.sh
```

### CI/CD
```bash
# 자동 테스트만 실행
./scripts/run-e2e-test-auto.sh
```

## 다음 단계

이 E2E 테스트가 통과하면:

1. ✅ **Solidity 구현 완료** 확인됨
2. ✅ **Go Client 구현 완료** 확인됨
3. ✅ **전체 통합 작동** 확인됨

남은 작업:
- [ ] 실제 Optimism devnet 테스트 (Kurtosis)
- [ ] 다양한 edge cases 테스트
- [ ] Performance 테스트
- [ ] Security audit 준비

## 결론

`run-e2e-test-auto.sh`는 RAT "State Root as Target" 설계의 **완전 자동화된 End-to-End 테스트**입니다.

- ✅ 1-2분 내 전체 플로우 검증
- ✅ Kurtosis 없이 실행 가능
- ✅ Real L2 state DB 사용
- ✅ CI/CD 통합 가능
- ✅ 자동 검증 포함

이제 단 한 줄의 명령으로 RAT 시스템 전체를 테스트할 수 있습니다! 🎉
