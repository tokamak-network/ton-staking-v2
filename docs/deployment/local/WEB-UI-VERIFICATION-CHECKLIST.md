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

**Validator가 0명일 경우**:
- [ ] "No validators registered yet" 메시지 표시

**Validator가 있을 경우 (각 Validator당)**:
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

### ⚡ Bridge ETH to L2 (Deposit) (4개 항목)

```bash
# 검증 명령어
# L1 Bridge, Portal, 사용자 ETH 잔액 조회
```

- [ ] **L1 Standard Bridge**: 주소 표시
- [ ] **Your L1 ETH Balance**: 숫자 ETH
- [ ] **Portal ETH Balance**: 숫자 ETH
- [ ] **입력 필드 및 버튼**: Amount (ETH) 입력 + Deposit ETH to L2 버튼
- [ ] **Gas Limit 안내**: "200,000 (sufficient for standard bridge)"

### 💎 Bridge TON to L2 (Deposit) (4개 항목)

```bash
# 검증 명령어
# L1 TON, L2 TON 주소, 사용자 TON 잔액 조회
```

- [ ] **L1 TON**: 주소 표시
- [ ] **L2 TON**: 주소 표시
- [ ] **Your L1 TON Balance**: 숫자 TON
- [ ] **입력 필드 및 버튼**: Amount (TON) 입력 + Deposit TON to L2 버튼
- [ ] **Your L1 TON Balance (하단)**: 숫자 TON

### 📤 Withdraw ETH from L2 (3개 항목)

**현재 상태**: ⚠️ L2 지갑 자동 전환 미구현

- [ ] **L2 Standard Bridge**: 0x4200000000000000000000000000000000000010 표시
- [ ] **L2 RPC**: http://localhost:9545 표시
- [ ] **입력 필드 및 버튼**: Amount (ETH) 입력 + Withdraw ETH from L2 버튼

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

**현재 상태**: ⚠️ UI 메뉴에서 접근 불가 (activeTab 조건 누락)

**구현되어 있는 항목 (6개)**:
- [ ] **ETH Balance**: 숫자 ETH
- [ ] **TON Balance**: 숫자 TON
- [ ] **WTON Balance**: 숫자 WTON
- [ ] **Staked Amount**: 숫자 WTON
- [ ] **Pending Unstaked**: 숫자 WTON
- [ ] **Withdrawal Requests**: 숫자

**대안**: 각 기능 탭에서 관련 잔액 표시됨

---

## 🔄 자동 업데이트 기능

모든 탭의 데이터는 **10초마다 자동 새로고침**됩니다.

**검증 방법**:
1. 초기 값 기록 (예: L1 Block: 1000)
2. 10초 대기
3. 값이 변경되었는지 확인 (예: L1 Block: 1010)

- [ ] **자동 업데이트 작동**: 10초 후 블록 번호 증가 확인

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
