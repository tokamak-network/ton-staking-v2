# 로컬 환경 문제 해결 기록

이 문서는 TON Staking V3 로컬 환경의 제한사항을 해결하는 과정을 기록합니다.

## Issue #1: SystemConfig unsafeBlockSigner 미설정

### 문제
- op-node 시작 실패
- 에러: `failed to fetch unsafe block signing address from system config`

### 원인
- SystemConfig의 `unsafeBlockSigner` 스토리지 슬롯이 초기화되지 않음
- Genesis 배포 시 `initialize()` 호출 또는 스토리지 직접 설정 필요

### 해결 시도 #1: setUnsafeBlockSigner 트랜잭션 전송

✅ **성공적으로 실행됨**

```bash
export RPC_URL="http://localhost:8545"
export SYSTEM_CONFIG=$(jq -r '.systemConfig' .devnet/addresses.json)
export PROPOSER="0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65"
export OWNER_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

# Set unsafeBlockSigner to Proposer
cast send $SYSTEM_CONFIG \
  --legacy \
  --private-key $OWNER_KEY \
  --rpc-url $RPC_URL \
  --gas-limit 100000 \
  "setUnsafeBlockSigner(address)" \
  $PROPOSER
```

**결과**:
- ✅ 트랜잭션 성공 (status: 0x1)
- ✅ ConfigUpdate 이벤트 발생
- ✅ unsafeBlockSigner() 함수 호출 시 Proposer 주소 반환
- ✅ 스토리지 슬롯에 값 저장됨

**검증**:
```bash
# Function call
cast call $SYSTEM_CONFIG "unsafeBlockSigner()(address)" --rpc-url $RPC_URL
# 결과: 0x15d34aaf54267db7d7c367839aaf71a00a2c6a65

# Storage slot
SLOT="0x65a7ed542fb37fe237fdfbdd70b31598523fe5b32879e307bae27a0bd9581c08"
cast storage $SYSTEM_CONFIG $SLOT --rpc-url $RPC_URL
# 결과: 0x0000000000000000000000015d34aaf54267db7d7c367839aaf71a00a2c6a65
```

### 해결 시도 #2: op-node 재시작

❌ **여전히 실패**

op-node를 재시작했지만 여전히 같은 에러 발생:
```
t=2026-02-03T05:33:02+0000 lvl=error msg="failed to fetch runtime config data" 
err="failed to fetch unsafe block signing address from system config: Invalid string length"
```

### 분석

#### 1. SystemConfig 상태 확인 ✅
- Owner: `0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266` (Account #0)
- unsafeBlockSigner: `0x15d34aaf54267db7d7c367839aaf71a00a2c6a65` (Proposer)
- 스토리지 슬롯: 정상 설정됨
- 함수 호출: 정상 작동

#### 2. op-node 설정 확인 ✅
- rollup.json의 l1_system_config_address: `0x577AcB7fA48878245a854ba51eD051a5B47cF83f`
- L1 RPC: `http://l1:8545` (정상 연결)
- 버전: `v1.7.7-f8143c8c-1717593043`

#### 3. 추정 원인

op-node가 unsafeBlockSigner를 읽는 방식에 문제가 있을 가능성:

**가능성 A: ABI 불일치**
- op-node v1.7.7의 SystemConfig ABI가 배포된 컨트랙트와 불일치
- `unsafeBlockSigner()` 함수 시그니처가 다를 수 있음

**가능성 B: 스토리지 레이아웃 불일치**
- op-node가 기대하는 스토리지 슬롯 위치와 실제 위치가 다름
- Proxy 패턴으로 인한 스토리지 충돌

**가능성 C: RPC 호출 방식 차이**
- op-node가 사용하는 RPC 메서드와 Anvil의 구현 불일치
- "Invalid string length" 에러는 ABI 디코딩 문제를 시사

### 다음 시도 방안

#### Option 1: SystemConfig 버전 확인
배포된 SystemConfig 컨트랙트가 op-node v1.7.7과 호환되는 버전인지 확인

```bash
# Check SystemConfig version
cast call $SYSTEM_CONFIG "version()(string)" --rpc-url $RPC_URL
```

#### Option 2: 더 낮은 버전의 op-node 사용
v1.7.7보다 낮은 버전 시도 (v1.7.0, v1.6.0 등)

#### Option 3: Genesis에서 unsafeBlockSigner 직접 설정
DeployAll 스크립트에서 SystemConfig allocs에 unsafeBlockSigner 스토리지 슬롯 직접 추가

```json
{
  "alloc": {
    "0x577AcB7fA48878245a854ba51eD051a5B47cF83f": {
      "code": "0x...",
      "storage": {
        "0x65a7ed542fb37fe237fdfbdd70b31598523fe5b32879e307bae27a0bd9581c08": 
          "0x00000000000000000000000015d34aaf54267db7d7c367839aaf71a00a2c6a65"
      }
    }
  }
}
```

#### Option 4: SystemConfig를 초기화된 상태로 배포
DeployAll 스크립트에서 `initialize()` 함수 호출 시뮬레이션 추가

### 결론

- ✅ unsafeBlockSigner 설정 자체는 성공
- ❌ op-node가 여전히 값을 읽지 못함
- 🔍 op-node와 SystemConfig 간의 통신 문제로 추정
- 🛠️ 근본적인 해결을 위해서는 Genesis 생성 시 초기화 필요

---

## Issue #2: cast send 호환성 문제

### 문제
- `cast send` 명령이 Anvil과 호환되지 않음
- 에러: `unknown field 'input', expected 'data'`

### 원인
- Foundry의 최신 버전과 Anvil의 RPC 포맷 불일치

### 해결 방법

#### 방법 1: --legacy 플래그 사용 (부분적 성공)
```bash
cast send $CONTRACT \
  --legacy \
  --private-key $KEY \
  --rpc-url $RPC_URL \
  "function(args)" \
  args
```

**문제점**: deserialization 오류는 여전히 발생하지만 트랜잭션은 성공

#### 방법 2: curl + RPC 직접 호출 (권장)
```bash
# Get nonce
NONCE=$(curl -s -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_getTransactionCount","params":["'$FROM'","latest"],"id":1}' \
  $RPC_URL | jq -r '.result')

# Build transaction data
DATA=$(cast calldata "transfer(address,uint256)" $TO $AMOUNT)

# Sign and send with ethers.js or web3.js
```

#### 방법 3: Hardhat 스크립트 사용 (가장 안정적)
```javascript
// scripts/transfer.js
const { ethers } = require("hardhat");

async function main() {
  const [signer] = await ethers.getSigners();
  const contract = await ethers.getContractAt("TON", TON_ADDRESS);
  const tx = await contract.transfer(to, amount);
  await tx.wait();
}
```

### 상태
- ⚠️ 임시 해결책 사용 중 (--legacy 플래그)
- 🛠️ Hardhat 스크립트 작성 필요

---

## Issue #3: 높은 최소 담보금

### 문제
- RAT 최소 담보금: ~60,000,000,000 TON
- 로컬 테스트용으로 비현실적으로 높음

### 원인
RAT 파라미터가 프로덕션 값으로 설정됨:
```
slashingPenalty: 10,000,000,000 TON
attentionCost: 1,000,000,000 TON
ratTriggerProbability: 1e27 (RAY)
```

### 해결 방법

#### Option 1: DeployAll 스크립트에서 파라미터 조정
```solidity
// scripts/DeployAll.s.sol
rat.setSlashingPenalty(100 ether); // 100 TON
rat.setAttentionCost(10 ether);    // 10 TON
```

#### Option 2: 테스트 계정에 충분한 TON 배분
Genesis에서 Validator 계정들에게 각각 100,000 TON 할당

### 상태
- ❌ 미해결
- 🛠️ DeployAll 스크립트 수정 필요

---

## Issue #4: L2 미등록

### 문제
- SystemConfig가 Layer2로 등록되지 않음
- `registerCandidateAddOn` 함수가 복잡한 파라미터 필요

### 원인
- Genesis 배포 시 L2 등록 단계 누락
- Layer2ManagerV3의 registerCandidateAddOn 요구사항:
  - TON/WTON 스테이킹
  - Operator 생성
  - L1 Bridge 검증
  - Memo (L2 이름)

### 해결 방법

#### Option 1: 간소화된 등록 함수 추가
```solidity
// Add to Layer2ManagerV3
function registerLayer2Simple(address systemConfig) external onlyOwner {
    // Simplified registration for testing
}
```

#### Option 2: Genesis에서 자동 등록
DeployAll 스크립트에서 registerCandidateAddOn 호출 시뮬레이션

### 상태
- ❌ 미해결
- 🛠️ 코드 수정 또는 스크립트 작성 필요

---

## 해결 우선순위

### P0 - Critical (현재 차단 요소)

1. ✅ **SystemConfig unsafeBlockSigner 설정** 
   - 완료: 트랜잭션으로 설정 성공
   - 남은 문제: op-node 호환성

2. ❌ **op-node 호환성 해결**
   - 시도 필요: Genesis에 스토리지 직접 추가
   - 시도 필요: 다른 op-node 버전

### P1 - High (기능 완성)

3. ❌ **RAT 파라미터 조정**
   - DeployAll 스크립트 수정
   - 로컬 테스트용 낮은 값 설정

4. ❌ **L2 자동 등록**
   - registerCandidateAddOn 자동화
   - 또는 간소화된 함수 추가

### P2 - Medium (편의성)

5. ⚠️ **cast send 문제 해결**
   - Hardhat 스크립트로 대체
   - 또는 ethers.js 사용

## 다음 단계

1. Genesis 생성 시 SystemConfig 스토리지 직접 설정
2. RAT 파라미터를 로컬 테스트용으로 조정
3. L2 자동 등록 스크립트 작성
4. Hardhat 기반 설정 스크립트 작성
5. 전체 통합 테스트
