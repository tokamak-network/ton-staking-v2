# Web UI 전체 페이지 검증 체크리스트

이 문서는 Web UI의 모든 페이지에 표시되는 모든 데이터 항목을 하나씩 검증하기 위한 체크리스트입니다.

---

## 📋 검증 방법

1. 각 섹션의 모든 항목을 순서대로 확인
2. 표시되는 값이 실제 온체인 데이터와 일치하는지 검증
3. ✓ 또는 ✗ 로 체크 표시

---

## 1️⃣ Overview 탭

### 📡 Node Status (6개 항목)

```bash
# 검증 명령어
cast chain-id --rpc-url http://localhost:8545
cast block-number --rpc-url http://localhost:8545
cast chain-id --rpc-url http://localhost:9545
cast block-number --rpc-url http://localhost:9545
```

- [ ] **L1 Status**: 🟢 Online / 🔴 Offline
- [ ] **L1 Block**: 숫자 (증가하는지 확인)
- [ ] **L1 Chain ID**: 900
- [ ] **L2 Status**: 🟢 Online / ⚠️ Offline
- [ ] **L2 Block**: 숫자 (증가하는지 확인)
- [ ] **L2 Chain ID**: 901

### 🌐 Rollup Information (5개 항목)

```bash
# 검증 명령어
SYSTEM_CONFIG=$(jq -r '.systemConfig' .devnet/addresses.json)
L1_BRIDGE_REGISTRY=$(jq -r '.l1BridgeRegistryProxy' .devnet/addresses.json)
cast call $L1_BRIDGE_REGISTRY "getRollupInfo(address)(uint8,address,bool,bool,string)" $SYSTEM_CONFIG --rpc-url http://localhost:8545
```

- [ ] **SystemConfig**: 주소 표시 (0x577...)
- [ ] **Rollup Type**: 숫자 (0-3) 및 타입명
  - 0: Invalid
  - 1: Optimism Legacy
  - 2: Optimism Bedrock Native
  - 3: Optimism Bedrock DisputeGame
- [ ] **L2 TON**: L2 TON 토큰 주소
- [ ] **Name**: Rollup 이름 (문자열)
- [ ] **Rejected Seigs**: ✅ No / ❌ Yes

### ⚙️ System Parameters (4개 항목)

```bash
# 검증 명령어
SEIG=$(jq -r '.seigManagerProxy' .devnet/addresses.json)
RAT=$(jq -r '.ratProxy' .devnet/addresses.json)
SYSTEM_CONFIG=$(jq -r '.systemConfig' .devnet/addresses.json)

cast call $SEIG "v3Migrated()(bool)" --rpc-url http://localhost:8545
cast call $RAT "getValidatorCount(address)(uint256)" $SYSTEM_CONFIG --rpc-url http://localhost:8545
cast call $RAT "getActiveValidatorCount(address)(uint256)" $SYSTEM_CONFIG --rpc-url http://localhost:8545
cast call $RAT "getDynamicMinimumCollateral(address)(uint256)" $SYSTEM_CONFIG --rpc-url http://localhost:8545
```

- [ ] **V3 Migrated**: ✅ Yes / ❌ No
- [ ] **Total Validators**: 숫자
- [ ] **Active Validators**: 숫자
- [ ] **Min Collateral**: 숫자 WTON

### 📍 TON Staking V3 Core Contracts (9개 항목)

```bash
# 검증 명령어
cat .devnet/addresses.json | jq '{ton, wton, seigManagerProxy, depositManagerProxy, layer2ManagerProxy, l1BridgeRegistryProxy, layer2RegistryProxy, ratProxy, validatorRewardProxy}'
```

- [ ] **TON**: 주소 표시
- [ ] **WTON**: 주소 표시
- [ ] **SeigManager**: 주소 표시
- [ ] **DepositManager**: 주소 표시
- [ ] **Layer2Manager**: 주소 표시
- [ ] **L1BridgeRegistry**: 주소 표시
- [ ] **Layer2Registry**: 주소 표시
- [ ] **RAT**: 주소 표시
- [ ] **ValidatorReward**: 주소 표시

### 🌉 Optimism Stack Contracts (4개 항목 + 조건부 2개)

```bash
# 검증 명령어
cat .devnet/addresses.json | jq '{systemConfig, disputeGameFactory}'
LAYER2_MANAGER=$(jq -r '.layer2ManagerProxy' .devnet/addresses.json)
SYSTEM_CONFIG=$(jq -r '.systemConfig' .devnet/addresses.json)
cast call $LAYER2_MANAGER "rollupConfigInfo(address)" $SYSTEM_CONFIG --rpc-url http://localhost:8545
```

- [ ] **SystemConfig**: 주소 표시
- [ ] **DisputeGameFactory**: 주소 표시
- [ ] **OperatorManager**: 주소 표시 (OperatorManager가 0x0이 아닐 때)
- [ ] **CandidateAddOn**: 주소 표시 (OperatorManager가 0x0이 아닐 때)

---

## 2️⃣ Operator 탭

### 👤 Operator & Sequencer Information (6개 항목)

```bash
# 검증 명령어
LAYER2_MANAGER=$(jq -r '.layer2ManagerProxy' .devnet/addresses.json)
SEIG=$(jq -r '.seigManagerProxy' .devnet/addresses.json)
LAYER2_REGISTRY=$(jq -r '.layer2RegistryProxy' .devnet/addresses.json)
SYSTEM_CONFIG=$(jq -r '.systemConfig' .devnet/addresses.json)

cast call $LAYER2_MANAGER "operatorOfRollupConfig(address)(address)" $SYSTEM_CONFIG --rpc-url http://localhost:8545
cast call $LAYER2_MANAGER "rollupConfigInfo(address)" $SYSTEM_CONFIG --rpc-url http://localhost:8545
# OperatorManager, CandidateAddOn 등 추가 조회
```

- [ ] **Operator Address**: 주소 표시
- [ ] **OperatorManager**: 주소 표시
- [ ] **OperatorManager.manager()**: 주소 표시
- [ ] **CandidateAddOn (Layer2)**: 주소 표시
- [ ] **Sequencer Collateral**: 숫자 WTON
- [ ] **Layer2Registry Status**: ✅ Registered / ❌ Not Registered

### 💎 Add Sequencer Collateral (3개 항목)

- [ ] **입력 필드**: Amount (WTON) 입력 가능
- [ ] **Add Collateral 버튼**: 클릭 가능
- [ ] **Your WTON Balance**: 숫자 표시

---

## 3️⃣ Validators 탭

### ✅ Validator 자동 등록 (Step 10에서 완료)

`start-dev.sh` 스크립트의 **Step 10**에서 3명의 Validator가 자동으로 등록됩니다.

| 역할 | 주소 | Anvil 계정 | Private Key |
|------|------|------------|-------------|
| Validator1 | `0x90F79bf6EB2c4f870365E785982E1f101E93b906` | #3 | `0x7c852118...` |
| Validator2 | `0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65` | #4 | `0x47e179ec...` |
| Validator3 | `0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc` | #5 | `0x8b3a350c...` |

**자동 등록 과정** (검증자당):
1. WTON approve → DepositManager
2. WTON deposit → CandidateAddOn (100 WTON)
3. RAT.registerValidator(systemConfig)

**등록 확인**:
```bash
RAT=$(jq -r '.ratProxy' .devnet/addresses.json)
SYSTEM_CONFIG=$(jq -r '.systemConfig' .devnet/addresses.json)

# 검증자 수 확인
cast call $RAT "getValidatorCount(address)(uint256)" $SYSTEM_CONFIG --rpc-url http://localhost:8545
# 결과: 3

# 검증자 목록 확인
cast call $RAT "getL2Validators(address)(address[])" $SYSTEM_CONFIG --rpc-url http://localhost:8545
# 결과: [0x90F7..., 0x15d3..., 0x9965...]
```

---

### 👥 Registered Validators (테이블 - 각 Validator당 5개 항목)

```bash
# 검증 명령어
RAT=$(jq -r '.ratProxy' .devnet/addresses.json)
SYSTEM_CONFIG=$(jq -r '.systemConfig' .devnet/addresses.json)

cast call $RAT "getL2Validators(address)(address[])" $SYSTEM_CONFIG --rpc-url http://localhost:8545
# 각 Validator에 대해:
# cast call $RAT "getValidatorDeposit(address,address)(uint256)" $VALIDATOR_ADDR $SYSTEM_CONFIG --rpc-url http://localhost:8545
# cast call $RAT "getAvailableCollateral(address,address)(uint256)" $VALIDATOR_ADDR $SYSTEM_CONFIG --rpc-url http://localhost:8545
# cast call $RAT "isValidatorActive(address,address)(bool)" $VALIDATOR_ADDR $SYSTEM_CONFIG --rpc-url http://localhost:8545
```

**Step 10 완료 후 (3명 등록됨)**:

**각 Validator당 표시 항목**:
- [ ] **Address**: Validator 주소 (6자...38자 형식)
- [ ] **Deposit**: 숫자 WTON
- [ ] **Available**: 숫자 WTON
- [ ] **RAT Status**: ✅ Registered / ⚠️ Not Registered
- [ ] **Active**: 🟢 Active / 🔴 Inactive

---

## 4️⃣ TON Staking 탭

### 💎 Deposit (Stake) (3개 항목)

```bash
# 검증 명령어
WTON=$(jq -r '.wton' .devnet/addresses.json)
SEIG=$(jq -r '.seigManagerProxy' .devnet/addresses.json)
# OperatorManager, CandidateAddOn 조회
# 사용자 주소의 stakeOf 조회
```

**CandidateAddOn이 없을 경우**:
- [ ] "⚠️ CandidateAddOn not found" 경고 메시지

**CandidateAddOn이 있을 경우**:
- [ ] **Target Layer2**: 주소 표시
- [ ] **Your Staked Amount**: 숫자 WTON
- [ ] **입력 필드 및 버튼**: Amount 입력 + Stake 버튼
- [ ] **Your WTON Balance**: 숫자 WTON

### 📤 Request Withdrawal (4개 항목)

- [ ] **Staked Amount**: 숫자 WTON
- [ ] **Pending Unstaked**: 숫자 WTON
- [ ] **Pending Requests**: 숫자
- [ ] **입력 필드 및 버튼**: Amount 입력 + Request Withdrawal 버튼
- [ ] **Available to withdraw**: 숫자 WTON

### ✅ Process Withdrawal (3개 항목)

- [ ] **Pending Requests**: 숫자
- [ ] **Pending Amount**: 숫자 WTON
- [ ] **입력 필드 및 버튼**: Number of requests 입력 + Process Withdrawal 버튼
- [ ] **상태 메시지**: "No pending withdrawal requests" 또는 "X request(s) ready"

---

## 5️⃣ Seigniorage 탭

**현재 상태**: ⚠️ UI 메뉴에서 접근 불가 (activeTab 조건 누락)

**구현되어 있는 항목 (20개+)**:
- [ ] **Last Seig Block**: 블록 번호
- [ ] **Current Block**: 블록 번호
- [ ] **Bridged TON**: 숫자 TON
- [ ] **Effective Bridged TON**: 숫자 TON
- [ ] **Total Effective Bridged TON**: 숫자 TON
- [ ] **Eligibility**: true/false
- [ ] **Required Stake**: 숫자 WTON
- [ ] **Current Stake**: 숫자 WTON
- [ ] **Claimable Amount**: 숫자 WTON
- [ ] **Seig Per Block**: 숫자 WTON
- [ ] **DAO Distribution Ratio**: 퍼센트
- [ ] **Validator Distribution Ratio**: 퍼센트
- [ ] **기타 시뇨리지 팩터들**

---

## 6️⃣ L2 Information 탭

### 🌐 L2 Network Information (6개 항목)

```bash
# 검증 명령어
SYSTEM_CONFIG=$(jq -r '.systemConfig' .devnet/addresses.json)
cast chain-id --rpc-url http://localhost:9545
cast block-number --rpc-url http://localhost:9545
```

- [ ] **SystemConfig**: 주소 표시
- [ ] **Expected L2 Chain ID**: 901 (badge 형식)
- [ ] **Actual L2 Chain ID**: 숫자
  - 901이면 초록색 badge
  - N/A면 경고
  - 다른 값이면 에러 표시
- [ ] **L2 Block Number**: 숫자
- [ ] **L2 RPC URL**: http://localhost:9545

### 👤 Proposer & Batcher (4개 항목)

```bash
# 검증 명령어
SYSTEM_CONFIG=$(jq -r '.systemConfig' .devnet/addresses.json)
cast call $SYSTEM_CONFIG "batcherHash()(bytes32)" --rpc-url http://localhost:8545
cast call $SYSTEM_CONFIG "unsafeBlockSigner()(address)" --rpc-url http://localhost:8545
cast call $SYSTEM_CONFIG "batchInbox()(address)" --rpc-url http://localhost:8545
```

- [ ] **Batcher Hash**: bytes32 값
- [ ] **Batcher Address (from hash)**: 주소 (해시의 처음 42자)
- [ ] **Unsafe Block Signer (Proposer)**: 주소
- [ ] **Batch Inbox**: 주소

### 🔧 System Configuration (5개 항목)

```bash
# 검증 명령어
cast call $SYSTEM_CONFIG "gasLimit()(uint64)" --rpc-url http://localhost:8545
cast call $SYSTEM_CONFIG "overhead()(uint256)" --rpc-url http://localhost:8545
cast call $SYSTEM_CONFIG "scalar()(uint256)" --rpc-url http://localhost:8545
cast call $SYSTEM_CONFIG "basefeeScalar()(uint32)" --rpc-url http://localhost:8545
cast call $SYSTEM_CONFIG "blobbasefeeScalar()(uint32)" --rpc-url http://localhost:8545
```

- [ ] **Gas Limit**: 숫자 (천 단위 구분)
- [ ] **Overhead**: 숫자
- [ ] **Scalar**: 숫자
- [ ] **Base Fee Scalar**: 숫자
- [ ] **Blob Base Fee Scalar**: 숫자

### 🌉 Bridge & Portal Addresses (4개 항목)

```bash
# 검증 명령어
cast call $SYSTEM_CONFIG "l1StandardBridge()(address)" --rpc-url http://localhost:8545
cast call $SYSTEM_CONFIG "optimismPortal()(address)" --rpc-url http://localhost:8545
cast call $SYSTEM_CONFIG "l1CrossDomainMessenger()(address)" --rpc-url http://localhost:8545
cast call $SYSTEM_CONFIG "disputeGameFactory()(address)" --rpc-url http://localhost:8545
```

- [ ] **L1 Standard Bridge**: 주소
- [ ] **Optimism Portal**: 주소
- [ ] **L1 CrossDomain Messenger**: 주소
- [ ] **Dispute Game Factory**: 주소

### 🛡️ Portal Status & Balances (5개 항목)

```bash
# 검증 명령어
PORTAL=$(cast call $SYSTEM_CONFIG "optimismPortal()(address)" --rpc-url http://localhost:8545)
cast call $PORTAL "guardian()(address)" --rpc-url http://localhost:8545
cast call $PORTAL "paused()(bool)" --rpc-url http://localhost:8545

TON=$(jq -r '.ton' .devnet/addresses.json)
cast call $TON "balanceOf(address)(uint256)" $PORTAL --rpc-url http://localhost:8545
cast balance $PORTAL --rpc-url http://localhost:8545

L1_BRIDGE=$(cast call $SYSTEM_CONFIG "l1StandardBridge()(address)" --rpc-url http://localhost:8545)
cast call $TON "balanceOf(address)(uint256)" $L1_BRIDGE --rpc-url http://localhost:8545
```

- [ ] **Guardian**: 주소
- [ ] **Paused**: ✅ No (Active) / ⚠️ Yes (Paused)
- [ ] **Portal TON Balance**: 숫자 TON
- [ ] **Portal ETH Balance**: 숫자 ETH
- [ ] **Bridge TON Balance**: 숫자 TON

---

## 7️⃣ Bridge to L2 탭

### ⚠️ 알려진 제한사항 (중요!)

**현재 Sepolia Fork 환경에서 Bridge 기능은 제한됩니다:**

```
Error: historical state is not available
```

**원인**:
- Optimism 컨트랙트들(Portal, Bridge, Messenger)이 Sepolia에서 fork됨
- Anvil fork 환경에서 이 컨트랙트들의 historical state 조회 시 오류 발생
- TON Staking V3 컨트랙트는 allocs로 배포되어 정상 동작

**영향받는 기능**:
- ❌ Bridge ETH to L2 (L1StandardBridge.depositETH)
- ❌ Bridge TON to L2 (L1StandardBridge.depositERC20)
- ❌ OptimismPortal.depositTransaction
- ❌ L1CrossDomainMessenger 관련 기능

**해결 방법** (향후 작업):
1. Optimism 컨트랙트도 allocs로 생성하여 배포
2. 또는 전체 Optimism 스택을 로컬에서 새로 배포

```bash
# 에러 재현 명령어
PORTAL=0xbF6531954Aa355f478e54fEDff94D9D9E7008D79
cast send $PORTAL "depositTransaction(address,uint256,uint64,bool,bytes)" \
    0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 10000000000000000 100000 false "0x" \
    --value 0.01ether --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
    --rpc-url http://localhost:8545
# 결과: Error: historical state is not available
```

---

### ⚡ Bridge ETH to L2 (Deposit)

```bash
# 검증 명령어
SYSTEM_CONFIG=$(jq -r '.systemConfig' .devnet/addresses.json)
L1_BRIDGE=$(cast call $SYSTEM_CONFIG "l1StandardBridge()(address)" --rpc-url http://localhost:8545)
echo "L1 Standard Bridge: $L1_BRIDGE"

# Bridge 상태 확인
cast call $L1_BRIDGE "paused()(bool)" --rpc-url http://localhost:8545
cast call $L1_BRIDGE "OTHER_BRIDGE()(address)" --rpc-url http://localhost:8545
```

**UI 표시 항목**:
- [ ] **L1 Standard Bridge**: 주소 표시 (0x95E1bDf...)
- [ ] **Your L1 ETH Balance**: 숫자 ETH
- [ ] **Portal ETH Balance**: 숫자 ETH
- [ ] **입력 필드**: Amount (ETH) 입력 가능
- [ ] **Deposit 버튼**: 클릭 가능
- [ ] **Gas Limit 안내**: "200,000 (sufficient for standard bridge)"

**기능 테스트**:
- [ ] Deposit 버튼 클릭 시 에러 메시지 표시 (historical state 문제)
- [ ] 에러 메시지가 사용자에게 명확하게 표시되는지 확인

---

### 💎 Bridge TON to L2 (Deposit)

```bash
# 검증 명령어
TON=$(jq -r '.ton' .devnet/addresses.json)
L1_BRIDGE_REGISTRY=$(jq -r '.l1BridgeRegistryProxy' .devnet/addresses.json)
SYSTEM_CONFIG=$(jq -r '.systemConfig' .devnet/addresses.json)

# L2 TON 주소 확인
cast call $L1_BRIDGE_REGISTRY "getRollupInfo(address)(uint8,address,bool,bool,string)" $SYSTEM_CONFIG --rpc-url http://localhost:8545
```

**UI 표시 항목**:
- [ ] **L1 TON**: 주소 표시
- [ ] **L2 TON**: 주소 표시 (from getRollupInfo)
- [ ] **Your L1 TON Balance**: 숫자 TON
- [ ] **입력 필드**: Amount (TON) 입력 가능
- [ ] **Deposit 버튼**: 클릭 가능

**기능 테스트**:
- [ ] Deposit 버튼 클릭 시 에러 메시지 표시 (historical state 문제)

---

### 📤 Withdraw ETH from L2

**현재 상태**: ⚠️ L2 지갑 자동 전환 미구현

```bash
# L2 Standard Bridge 확인
L2_BRIDGE=0x4200000000000000000000000000000000000010
cast call $L2_BRIDGE "OTHER_BRIDGE()(address)" --rpc-url http://localhost:9545
```

**UI 표시 항목**:
- [ ] **L2 Standard Bridge**: 0x4200000000000000000000000000000000000010 표시
- [ ] **L2 RPC**: http://localhost:9545 표시
- [ ] **입력 필드**: Amount (ETH) 입력 가능
- [ ] **Withdraw 버튼**: 클릭 가능

**기능 테스트**:
- [ ] L2 지갑 전환 필요 안내 메시지 표시

---

## 8️⃣ Dispute Games 탭

### 🎮 Recent Dispute Games (테이블 - 각 Game당 4개 항목)

```bash
# 검증 명령어
DISPUTE_FACTORY=$(jq -r '.disputeGameFactory' .devnet/addresses.json)
cast call $DISPUTE_FACTORY "gameCount()(uint256)" --rpc-url http://localhost:8545
# 각 게임 조회: gameAtIndex(i)
```

**게임이 0개일 경우**:
- [ ] "No dispute games created yet" 메시지

**게임이 있을 경우 (각 게임당, 최근 10개)**:
- [ ] **#**: 게임 인덱스
- [ ] **Type**: 게임 타입 (숫자)
- [ ] **Proxy Address**: 게임 프록시 주소 (6자...38자)
- [ ] **Created At**: 타임스탬프 (날짜/시간 형식)

---

## 9️⃣ Balances 탭

### 💰 Token Balances (6개 항목)

```bash
# 검증 명령어
ACCOUNT=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266  # 연결된 지갑 주소
TON=$(jq -r '.ton' .devnet/addresses.json)
WTON=$(jq -r '.wton' .devnet/addresses.json)

cast balance $ACCOUNT --rpc-url http://localhost:8545
cast call $TON "balanceOf(address)(uint256)" $ACCOUNT --rpc-url http://localhost:8545
cast call $WTON "balanceOf(address)(uint256)" $ACCOUNT --rpc-url http://localhost:8545
```

- [ ] **ETH Balance**: 숫자 ETH (화면 표시 + 온체인 일치)
- [ ] **TON Balance**: 숫자 TON (화면 표시 + 온체인 일치)
- [ ] **WTON Balance**: 숫자 WTON (화면 표시 + 온체인 일치)
- [ ] **Staked Amount**: 숫자 WTON
- [ ] **Pending Unstaked**: 숫자 WTON
- [ ] **Withdrawal Requests**: 숫자

### 🚰 Faucet (Token Mint) 기능

```bash
# ETH 민트 (Anvil cheatcode)
cast rpc anvil_setBalance $ACCOUNT 0x56BC75E2D63100000 --rpc-url http://localhost:8545
# 100 ETH = 0x56BC75E2D63100000

# TON은 mint 함수가 필요 (owner만 가능하거나 별도 faucet 필요)
```

**Faucet 버튼 동작 검증**:
- [ ] **ETH Faucet**: 버튼 클릭 → 잔액 증가 → 화면 업데이트
- [ ] **TON Faucet**: 버튼 클릭 → 잔액 증가 → 화면 업데이트
- [ ] **WTON Faucet**: 버튼 클릭 → 잔액 증가 → 화면 업데이트

### 🔄 Swap 기능 (TON ↔ WTON)

```bash
# TON → WTON 스왑 검증
WTON=$(jq -r '.wton' .devnet/addresses.json)
# WTON.swapFromTON(amount) 또는 WTON.deposit(amount)

# WTON → TON 스왑 검증
# WTON.swapToTON(amount) 또는 WTON.withdraw(amount)
```

**Swap 기능 검증**:
- [ ] **TON → WTON 스왑**: 버튼 + 입력필드 표시
- [ ] **스왑 후 TON 잔액 감소**: 화면 반영
- [ ] **스왑 후 WTON 잔액 증가**: 화면 반영
- [ ] **WTON → TON 스왑**: 버튼 + 입력필드 표시
- [ ] **스왑 후 WTON 잔액 감소**: 화면 반영
- [ ] **스왑 후 TON 잔액 증가**: 화면 반영

### ⚠️ 잔액 업데이트 검증 (중요!)

**알려진 이슈**:
| 토큰 | Faucet/민트 후 화면 반영 | 스왑 후 화면 반영 |
|------|-------------------------|------------------|
| ETH | ✅ 정상 | N/A |
| TON | ❌ 미반영 | ⚠️ 확인 필요 |
| WTON | ❌ 미반영 | ⚠️ 확인 필요 |

**원인 분석 필요**:
- Web UI에서 TON/WTON balanceOf 조회 시점
- useEffect 의존성 배열에 잔액 관련 상태 누락 가능
- RPC 호출 실패 또는 캐싱 문제

**수동 새로고침 필요 시**:
- [ ] 페이지 새로고침(F5) 후 잔액 정상 표시

---

## 🔄 자동 업데이트 기능

모든 탭의 데이터는 **10초마다 자동 새로고침**됩니다.

**검증 방법**:
1. 초기 값 기록 (예: L1 Block: 1000)
2. 10초 대기
3. 값이 변경되었는지 확인 (예: L1 Block: 1010)

- [ ] **블록 번호 자동 업데이트**: 10초 후 L1/L2 블록 번호 증가 확인

### 💰 잔액 업데이트 검증 (중요!)

```bash
# 테스트 계정에 토큰 민트
DEPLOYER=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
TON=$(jq -r '.ton' .devnet/addresses.json)
WTON=$(jq -r '.wton' .devnet/addresses.json)

# ETH 민트 테스트
cast rpc anvil_setBalance $DEPLOYER 0x56BC75E2D63100000 --rpc-url http://localhost:8545

# TON 민트 테스트 (TON은 mint 함수가 있는 경우)
# cast send $TON "mint(address,uint256)" $DEPLOYER 1000000000000000000000 --private-key ...

# WTON 잔액 확인
cast call $WTON "balanceOf(address)(uint256)" $DEPLOYER --rpc-url http://localhost:8545
```

**각 토큰별 자동 업데이트 검증**:
- [ ] **ETH 잔액**: 민트 후 10초 내 화면 업데이트 ✅
- [ ] **TON 잔액**: 민트/전송 후 10초 내 화면 업데이트
- [ ] **WTON 잔액**: swap/전송 후 10초 내 화면 업데이트

**알려진 이슈**:
- ETH 잔액: 자동 업데이트 정상 ✅
- TON 잔액: 자동 업데이트 지연 또는 미반영 ⚠️ (확인 필요)

---

## 📊 검증 통계

### 총 검증 항목 수

- **Overview 탭**: 24개 + 조건부 2개 = 26개
- **Operator 탭**: 9개
- **Validators 탭**: 1개 (메시지) 또는 5개 × N (Validator 수)
- **TON Staking 탭**: 10개
- **Seigniorage 탭**: 20개+ (접근 불가)
- **L2 Information 탭**: 24개
- **Bridge 탭**: 11개
- **Dispute Games 탭**: 1개 (메시지) 또는 4개 × N (게임 수, 최대 10개)
- **Balances 탭**: 6개 (접근 불가)
- **자동 업데이트**: 1개

**총합**: 약 **106개+ 항목** (조건부 항목 제외)

---

## ✅ 검증 완료 기준

모든 섹션의 체크박스가 체크되면 검증 완료

**검증 리포트 작성 시 포함 사항**:
- 검증 일시
- 총 항목 수 / 검증된 항목 수
- 실패한 항목 목록 (있을 경우)
- Web UI 버전 또는 Git commit hash
- 로컬 네트워크 상태 (L1/L2 블록 높이)

---

## 🤖 자동 검증 스크립트

이 체크리스트의 모든 항목을 자동으로 검증하는 스크립트:

```bash
./scripts/verify-webui-pages.sh
```

(스크립트는 각 페이지의 모든 항목을 순차적으로 검증하고 리포트 생성)

---

## 📝 수동 검증 가이드

### 사전 준비

1. 로컬 네트워크 실행 중인지 확인
   ```bash
   make devnet-info
   ```

2. Web UI 실행
   ```bash
   cd web-ui
   npm run dev
   ```

3. 브라우저에서 http://localhost:5173 접속

### 검증 절차

1. 각 탭으로 이동
2. 해당 탭의 모든 섹션 확인
3. 각 항목의 값이 표시되는지 확인
4. 터미널에서 검증 명령어 실행하여 값 일치 확인
5. 체크리스트에 ✓ 표시

### 브라우저 개발자 도구 활용

- F12로 개발자 도구 열기
- Console 탭에서 에러 확인
- Network 탭에서 RPC 호출 확인

---

## 🔗 관련 문서

- [Web UI Features Guide](./web-ui/features.md) - 각 기능 상세 설명
- [Web UI Troubleshooting](./web-ui/troubleshooting.md) - 문제 해결
- [VERIFICATION-CHECKLIST.md](./VERIFICATION-CHECKLIST.md) - 전체 시스템 검증
