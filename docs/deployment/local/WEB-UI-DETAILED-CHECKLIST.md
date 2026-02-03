# TON Staking V3 Web UI - 상세 점검 체크리스트

> **목적**: Web UI의 모든 페이지, 모든 데이터, 모든 인터페이스 요소가 올바르게 구현되고 작동하는지 검증

최종 업데이트: 2026-02-03

---

## 📋 목차

1. [사전 준비 체크리스트](#1-사전-준비-체크리스트)
2. [빌드 & 설치 체크리스트](#2-빌드--설치-체크리스트)
3. [설정 파일 검증](#3-설정-파일-검증)
4. [페이지별 상세 검증](#4-페이지별-상세-검증)
   - [Overview 탭](#41-overview-탭)
   - [Operator 탭](#42-operator-탭)
   - [Validators 탭](#43-validators-탭)
   - [TON Staking 탭](#44-ton-staking-탭)
   - [Seigniorage 탭](#45-seigniorage-탭)
   - [L2 Information 탭](#46-l2-information-탭)
   - [Bridge to L2 탭](#47-bridge-to-l2-탭)
   - [Dispute Games 탭](#48-dispute-games-탭)
   - [Balances 탭](#49-balances-탭)
5. [인터랙션 테스트](#5-인터랙션-테스트)
6. [데이터 정확성 검증](#6-데이터-정확성-검증)
7. [에러 핸들링 테스트](#7-에러-핸들링-테스트)
8. [UI/UX 검증](#8-uiux-검증)

---

## 1. 사전 준비 체크리스트

### [ ] 1.1 로컬 환경 실행 확인

```bash
# L1 노드 확인
cast chain-id --rpc-url http://localhost:8545
# 출력 예상: 900

# L2 노드 확인
cast chain-id --rpc-url http://localhost:9545
# 출력 예상: 901

# 컨트랙트 주소 확인
ls -lh .devnet/addresses.json
```

**검증 기준**:
- [ ] L1 노드가 8545 포트에서 실행 중
- [ ] L2 노드가 9545 포트에서 실행 중
- [ ] `.devnet/addresses.json` 파일 존재
- [ ] 모든 컨트랙트 주소가 유효한 Ethereum 주소 형식 (0x로 시작, 42자리)

---

## 2. 빌드 & 설치 체크리스트

### [ ] 2.1 의존성 설치

```bash
cd web-ui
npm install
```

**검증 항목**:
- [ ] `npm install` 성공 (에러 없음)
- [ ] `node_modules/` 폴더 생성됨
- [ ] `package-lock.json` 생성/업데이트됨
- [ ] 다음 핵심 패키지 설치 확인:
  - [ ] ethers@^6.16.0
  - [ ] react@^19.2.0
  - [ ] vite@^7.2.4
  - [ ] @rainbow-me/rainbowkit@^2.2.10
  - [ ] wagmi@^2.19.5

### [ ] 2.2 TypeScript 컴파일

```bash
npm run build
```

**검증 항목**:
- [ ] TypeScript 컴파일 성공 (에러 0개)
- [ ] `dist/` 폴더 생성됨
- [ ] `dist/index.html` 존재
- [ ] `dist/assets/` 폴더에 번들 파일 존재
- [ ] 빌드 출력에 경고 없음

### [ ] 2.3 개발 서버 실행

```bash
npm run dev
```

**검증 항목**:
- [ ] 개발 서버가 포트 5173에서 시작됨
- [ ] 브라우저에서 `http://localhost:5173` 접근 가능
- [ ] 콘솔에 에러 없음
- [ ] Hot Module Replacement (HMR) 작동

---

## 3. 설정 파일 검증

### [ ] 3.1 config.ts 주소 정확성

**자동 검증 스크립트**:
```bash
cd /Users/zena/gitwork/ton-staking-v2
./scripts/verify-webui-config.sh
```

**수동 검증**:
```bash
# TON 주소 일치 확인
DEVNET_TON=$(jq -r '.ton' .devnet/addresses.json)
CONFIG_TON=$(grep "ton:" web-ui/src/config.ts | grep -o '0x[a-fA-F0-9]\{40\}' | head -1)
echo "Devnet: $DEVNET_TON"
echo "Config: $CONFIG_TON"
test "$DEVNET_TON" == "$CONFIG_TON" && echo "✅ TON address matches" || echo "❌ Mismatch!"
```

**검증 대상 컨트랙트** (총 11개):
- [ ] ton
- [ ] wton
- [ ] seigManager (seigManagerProxy)
- [ ] depositManager (depositManagerProxy)
- [ ] layer2Manager (layer2ManagerProxy)
- [ ] l1BridgeRegistry (l1BridgeRegistryProxy)
- [ ] layer2Registry (layer2RegistryProxy)
- [ ] rat (ratProxy)
- [ ] validatorReward (validatorRewardProxy)
- [ ] systemConfig
- [ ] disputeGameFactory

### [ ] 3.2 네트워크 설정 확인

**config.ts 파일 내용**:
```typescript
chainId: 900,
rpcUrl: 'http://localhost:8545',
l2RpcUrl: 'http://localhost:9545',
chainName: 'TON Staking V3 Local',
```

**검증**:
- [ ] chainId = 900 (L1)
- [ ] rpcUrl = http://localhost:8545
- [ ] l2RpcUrl = http://localhost:9545
- [ ] chainName 설정됨

### [ ] 3.3 테스트 계정 설정

**검증 항목** (총 5개 계정):
- [ ] Account #0: Deployer/Operator (0xf39Fd...)
- [ ] Account #1: TON Staking Deployer (0x70997...)
- [ ] Account #2: Validator #1 (0x90F79...)
- [ ] Account #3: Validator #2 (0x15d34...)
- [ ] Account #4: Validator #3 (0x99655...)
- [ ] 모든 privateKey가 올바른 형식 (0x + 64 hex characters)

---

## 4. 페이지별 상세 검증

### 4.1 Overview 탭

#### [ ] 4.1.1 Node Status 카드

**표시 데이터**:
- [ ] L1 Status: 🟢 Online / 🔴 Offline
- [ ] L1 Block: 숫자 표시 (예: 2050)
- [ ] L1 Chain ID: 900
- [ ] L2 Status: 🟢 Online / ⚠️ Offline
- [ ] L2 Block: 숫자 표시 (예: 320000)
- [ ] L2 Chain ID: 901 (정상) 또는 ❌ (오류)

**자동 갱신 테스트**:
- [ ] 10초마다 자동으로 블록 번호가 증가하는지 확인
- [ ] L1 블록이 실시간으로 업데이트되는지 확인 (1초마다 증가)
- [ ] L2 블록이 실시간으로 업데이트되는지 확인 (2초마다 증가)

**데이터 소스 검증**:
```typescript
// L1
const l1Block = await l1Provider.getBlockNumber();
const l1ChainId = (await l1Provider.getNetwork()).chainId.toString();

// L2
const l2Block = await l2Provider.getBlockNumber();
const l2ChainId = (await l2Provider.getNetwork()).chainId.toString();
```

**CLI 검증**:
```bash
# L1
cast block-number --rpc-url http://localhost:8545

# L2
cast block-number --rpc-url http://localhost:9545
```

#### [ ] 4.1.2 Rollup Information 카드

**표시 데이터**:
- [ ] SystemConfig: 주소 표시 (0x577AcB...)
- [ ] Rollup Type: "Optimism Bedrock DisputeGame" (타입 3)
- [ ] L2 TON: 주소 표시
- [ ] Name: 문자열 표시 (예: "Devnet L2")
- [ ] Rejected Seigs: ✅ No / ❌ Yes
- [ ] Rejected L2 Deposit: ✅ No / ❌ Yes (5행 추가)

**데이터 소스**:
```solidity
// L1BridgeRegistry.getRollupInfo(systemConfig)
returns (
  uint8 rollupType,
  address l2Ton,
  bool rejectedSeigs,
  bool rejectedL2Deposit,
  string memory name
)
```

**CLI 검증**:
```bash
cast call $L1_BRIDGE_REGISTRY \
  "getRollupInfo(address)(uint8,address,bool,bool,string)" \
  $SYSTEM_CONFIG --rpc-url http://localhost:8545
```

**예상 출력**:
```
3  # Rollup Type
0x... # L2 TON address
false # rejectedSeigs
false # rejectedL2Deposit
"Devnet L2"
```

#### [ ] 4.1.3 System Parameters 카드

**표시 데이터**:
- [ ] V3 Migrated: ✅ Yes / ❌ No
- [ ] Total Validators: 숫자 (예: 0, 1, 2, ...)
- [ ] Active Validators: 숫자 (예: 0)
- [ ] Min Collateral: 숫자 WTON (예: 60.00 WTON)

**데이터 소스**:
```typescript
const v3Migrated = await seigManager.v3Migrated();
const totalValidators = await rat.getValidatorCount(systemConfig);
const activeValidators = await rat.getActiveValidatorCount(systemConfig);
const minCollateral = await rat.getDynamicMinimumCollateral(systemConfig);
```

**CLI 검증**:
```bash
# V3 Migrated
cast call $SEIG_MANAGER "v3Migrated()(bool)" --rpc-url http://localhost:8545
# 출력: true

# Total Validators
cast call $RAT "getValidatorCount(address)(uint256)" $SYSTEM_CONFIG --rpc-url http://localhost:8545

# Active Validators
cast call $RAT "getActiveValidatorCount(address)(uint256)" $SYSTEM_CONFIG --rpc-url http://localhost:8545

# Min Collateral (WTON 27 decimals)
cast call $RAT "getDynamicMinimumCollateral(address)(uint256)" $SYSTEM_CONFIG --rpc-url http://localhost:8545
```

#### [ ] 4.1.4 TON Staking V3 Core Contracts 카드

**표시 주소** (총 9개):
- [ ] 💰 TON
- [ ] 💎 WTON
- [ ] 🎯 SeigManager
- [ ] 🏦 DepositManager
- [ ] 🏗️ Layer2Manager
- [ ] 📋 L1BridgeRegistry
- [ ] 📝 Layer2Registry
- [ ] 🎲 RAT
- [ ] 🏆 ValidatorReward

**검증**:
- [ ] 모든 주소가 `0x`로 시작하고 42자리
- [ ] config.ts의 주소와 일치
- [ ] `.devnet/addresses.json`의 주소와 일치

#### [ ] 4.1.5 Optimism Stack Contracts 카드

**표시 주소** (최소 2개, 최대 4개):
- [ ] ⚙️ SystemConfig
- [ ] 🎮 DisputeGameFactory
- [ ] 👤 OperatorManager (조건부: 등록된 경우에만)
- [ ] 🎯 CandidateAddOn (조건부: 등록된 경우에만)

**조건부 표시 로직 검증**:
```typescript
if (operatorInfo && operatorInfo.operatorManager !== ethers.ZeroAddress) {
  // OperatorManager와 CandidateAddOn 표시
}
```

---

### 4.2 Operator 탭

#### [ ] 4.2.1 Operator & Sequencer Information 카드

**표시 데이터** (총 6개 필드):
- [ ] Operator Address: 주소 표시
- [ ] OperatorManager: 주소 표시
- [ ] OperatorManager.manager(): 주소 표시
- [ ] CandidateAddOn (Layer2): 주소 표시
- [ ] Sequencer Collateral: 숫자 WTON (예: 1001.00 WTON)
- [ ] Layer2Registry Status: ✅ Registered / ❌ Not Registered

**데이터 소스**:
```typescript
// Layer2Manager
const configInfo = await layer2Manager.rollupConfigInfo(systemConfig);
const operator = await layer2Manager.operatorOfRollupConfig(systemConfig);
const operatorManager = configInfo[1];
const candidateAddOn = await layer2Manager.candidateAddOnOfOperator(operatorManager);

// SeigManager
const sequencerStake = await seigManager.stakeOf(candidateAddOn, operatorManager);

// Layer2Registry
const isLayer2Registered = await layer2Registry.layer2s(candidateAddOn);

// OperatorManager
const opManagerContract = new ethers.Contract(operatorManager, OPERATOR_MANAGER_ABI, l1Provider);
const operatorManagerManager = await opManagerContract.manager();
```

**CLI 검증**:
```bash
# Rollup Config Info
cast call $LAYER2_MANAGER "rollupConfigInfo(address)(uint8,address)" $SYSTEM_CONFIG --rpc-url http://localhost:8545

# Operator
cast call $LAYER2_MANAGER "operatorOfRollupConfig(address)(address)" $SYSTEM_CONFIG --rpc-url http://localhost:8545

# CandidateAddOn
cast call $LAYER2_MANAGER "candidateAddOnOfOperator(address)(address)" $OPERATOR_MANAGER --rpc-url http://localhost:8545

# Sequencer Stake
cast call $SEIG_MANAGER "stakeOf(address,address)(uint256)" $CANDIDATE_ADDON $OPERATOR_MANAGER --rpc-url http://localhost:8545

# Layer2Registry
cast call $LAYER2_REGISTRY "layer2s(address)(bool)" $CANDIDATE_ADDON --rpc-url http://localhost:8545

# OperatorManager.manager()
cast call $OPERATOR_MANAGER "manager()(address)" --rpc-url http://localhost:8545
```

#### [ ] 4.2.2 Add Sequencer Collateral 카드

**UI 요소**:
- [ ] 입력 필드: type="number", placeholder="Amount (WTON)"
- [ ] 버튼: "Add Collateral" / "Adding..." (로딩 중)
- [ ] 잔액 표시: "Your WTON Balance: X.XXXX"

**인터랙션 테스트**:
1. [ ] 금액 입력 가능
2. [ ] 금액 미입력 시 알림 표시
3. [ ] 지갑 미연결 시 비활성화
4. [ ] 로딩 중 버튼 비활성화
5. [ ] 성공 시 "Collateral added successfully!" 알림
6. [ ] 실패 시 에러 메시지 표시

**트랜잭션 검증**:
```typescript
// 1. WTON approve
const wtonContract = new ethers.Contract(CONFIG.contracts.wton, WTON_ABI, signer);
await wtonContract.approve(CONFIG.contracts.seigManager, amountWei);

// 2. Deposit
const depositManager = new ethers.Contract(CONFIG.contracts.depositManager, DEPOSIT_MANAGER_ABI, signer);
await depositManager.deposit(operatorInfo.operatorManager, amountWei);
```

---

### 4.3 Validators 탭

#### [ ] 4.3.1 Registered Validators 테이블

**테이블 헤더** (총 5개 컬럼):
- [ ] Address
- [ ] Deposit
- [ ] Available
- [ ] RAT Status
- [ ] Active

**빈 상태 메시지**:
- [ ] "No validators registered yet" (validators.length === 0)

**데이터 행 검증**:
- [ ] Address: 주소 축약 표시 (formatAddress: 0xABCD...5678)
- [ ] Deposit: 숫자.00 WTON
- [ ] Available: 숫자.00 WTON
- [ ] RAT Status: ✅ Registered / ⚠️ Not Registered
- [ ] Active: 🟢 Active / 🔴 Inactive

**데이터 소스**:
```typescript
// Validator 목록
const validatorAddrs = await rat.getL2Validators(systemConfig);

// 각 Validator 정보
for (const addr of validatorAddrs) {
  const deposit = await rat.getValidatorDeposit(addr, systemConfig);
  const available = await rat.getAvailableCollateral(addr, systemConfig);
  const isActive = await rat.isValidatorActive(addr, systemConfig);
  const registration = await rat.getValidatorRegistration(addr, systemConfig);
  const ratRegistered = registration[2]; // isActive field
}
```

**CLI 검증**:
```bash
# Validator 목록
cast call $RAT "getL2Validators(address)(address[])" $SYSTEM_CONFIG --rpc-url http://localhost:8545

# Validator 정보 (VALIDATOR_ADDR를 실제 주소로 대체)
cast call $RAT "getValidatorDeposit(address,address)(uint256)" $VALIDATOR_ADDR $SYSTEM_CONFIG --rpc-url http://localhost:8545
cast call $RAT "getAvailableCollateral(address,address)(uint256)" $VALIDATOR_ADDR $SYSTEM_CONFIG --rpc-url http://localhost:8545
cast call $RAT "isValidatorActive(address,address)(bool)" $VALIDATOR_ADDR $SYSTEM_CONFIG --rpc-url http://localhost:8545
cast call $RAT "getValidatorRegistration(address,address)(uint256,uint256,bool)" $VALIDATOR_ADDR $SYSTEM_CONFIG --rpc-url http://localhost:8545
```

---

### 4.4 TON Staking 탭

#### [ ] 4.4.1 Deposit (Stake) 카드

**조건부 표시**:
- [ ] CandidateAddOn 없을 때: "⚠️ CandidateAddOn not found. Please register L2 operator first."
- [ ] CandidateAddOn 있을 때: 스테이킹 폼 표시

**표시 데이터**:
- [ ] Target Layer2: CandidateAddOn 주소
- [ ] Your Staked Amount: 숫자.XXXX WTON

**UI 요소**:
- [ ] 입력 필드: type="number", placeholder="Amount (WTON)"
- [ ] 버튼: "💎 Stake" / "⏳ Staking..."
- [ ] 잔액 표시: "Your WTON Balance: X.XXXX"

**인터랙션 테스트**:
1. [ ] 금액 입력 가능
2. [ ] 음수 입력 불가
3. [ ] 금액 미입력 시 "Please enter a valid amount"
4. [ ] 로딩 중 버튼 비활성화
5. [ ] 성공 시 "✅ Staking successful!"
6. [ ] 실패 시 에러 메시지
7. [ ] 성공 후 입력 필드 초기화
8. [ ] 성공 후 잔액 자동 갱신

**트랜잭션 검증**:
```typescript
// 1. WTON approve
await wtonContract.approve(CONFIG.contracts.depositManager, amountWei);

// 2. Deposit
await depositManager.deposit(candidateAddOn, amountWei);
```

#### [ ] 4.4.2 Request Withdrawal 카드

**표시 데이터**:
- [ ] Staked Amount: 숫자.XXXX WTON
- [ ] Pending Unstaked: 숫자.XXXX WTON
- [ ] Pending Requests: 숫자

**UI 요소**:
- [ ] 입력 필드: type="number", placeholder="Amount (WTON)"
- [ ] 버튼: "📤 Request Withdrawal" / "⏳ Requesting..."
- [ ] 안내: "Available to withdraw: X.XXXX WTON"

**인터랙션 테스트**:
1. [ ] 금액 > stakedAmount 시 "Amount exceeds staked balance"
2. [ ] stakedAmount = 0 시 버튼 비활성화
3. [ ] 성공 시 "✅ Withdrawal requested successfully!"
4. [ ] 성공 후 데이터 갱신

**트랜잭션**:
```typescript
await depositManager.requestWithdrawal(candidateAddOn, amountWei);
```

**CLI 검증**:
```bash
# Staked Amount
cast call $SEIG_MANAGER "stakeOf(address,address)(uint256)" $CANDIDATE_ADDON $MY_ADDRESS --rpc-url http://localhost:8545

# Pending Unstaked
cast call $DEPOSIT_MANAGER "pendingUnstaked(address,address)(uint256)" $CANDIDATE_ADDON $MY_ADDRESS --rpc-url http://localhost:8545

# Pending Requests
cast call $DEPOSIT_MANAGER "numPendingRequests(address,address)(uint256)" $CANDIDATE_ADDON $MY_ADDRESS --rpc-url http://localhost:8545
```

#### [ ] 4.4.3 Process Withdrawal 카드

**표시 데이터**:
- [ ] Pending Requests: 숫자
- [ ] Pending Amount: 숫자.XXXX WTON

**UI 요소**:
- [ ] 입력 필드: type="number", placeholder="Number of requests to process", defaultValue="1"
- [ ] 버튼: "✅ Process Withdrawal" / "⏳ Processing..."
- [ ] 안내: "No pending withdrawal requests" / "X request(s) ready to process"

**인터랙션 테스트**:
1. [ ] num > withdrawalRequests 시 "Number exceeds pending requests"
2. [ ] withdrawalRequests = 0 시 버튼 비활성화
3. [ ] 성공 시 "✅ Withdrawal processed successfully!"

**트랜잭션**:
```typescript
await depositManager.processWithdrawal(candidateAddOn, numRequests);
```

---

### 4.5 Seigniorage 탭

#### [ ] 4.5.1 Select Layer2 Address 카드

**UI 요소**:
- [ ] 입력 필드: placeholder="Layer2 Address (e.g., CandidateAddOn address)"
- [ ] 버튼: "🔍 Query" / "⏳ Loading..."
- [ ] Quick select 버튼 (조건부): "Use My CandidateAddOn (0xABCD...5678)"

**인터랙션 테스트**:
1. [ ] 주소 입력 가능
2. [ ] 빈 주소 입력 시 "Please enter a Layer2 address"
3. [ ] 잘못된 주소 형식 시 "Invalid Ethereum address"
4. [ ] Quick select 버튼 클릭 시 자동으로 CandidateAddOn 주소 입력 및 쿼리
5. [ ] 성공 시 아래 섹션들이 표시됨

#### [ ] 4.5.2 Layer2 Registration Status 카드

**표시 데이터**:
- [ ] Target Layer2: 입력한 주소
- [ ] Registered in Layer2Registry: ✅ Yes / ❌ No
- [ ] Layer2 Status: ❌ Not Registered (0) / ✅ Active (1) / ⚠️ Paused (2)
- [ ] RollupConfig (SystemConfig): 주소

**데이터 소스**:
```typescript
const isRegistered = await layer2Registry.layer2s(layer2Address);
const rollupConfig = await layer2Manager.getRollupConfig(layer2Address);
const layer2Status = await layer2Manager.statusLayer2(rollupConfig);
```

#### [ ] 4.5.3 Operator Manager Information 카드

**표시 데이터**:
- [ ] OperatorManager Address: 주소
- [ ] Claimable Seigniorage (in OperatorManager): 숫자.XXXX WTON
- [ ] OperatorManager.manager(): 주소
- [ ] SystemConfig.unsafeBlockSigner(): 주소
- [ ] Manager == UnsafeBlockSigner: ✅ Match / ⚠️ Different

**중요 검증**:
- [ ] manager와 unsafeBlockSigner가 일치하면 ✅ Match
- [ ] 불일치하면 ⚠️ Different (경고 상태)

**데이터 소스**:
```typescript
const operatorManager = await layer2Manager.operatorOfRollupConfig(rollupConfig);
const opManagerBalance = await wtonContract.balanceOf(operatorManager);
const opManagerManager = await opManagerContract.manager();
const systemConfigSigner = await systemConfigContract.unsafeBlockSigner();
const signersMatch = opManagerManager.toLowerCase() === systemConfigSigner.toLowerCase();
```

#### [ ] 4.5.4 Seigniorage Issuance Factors 카드

**표시 데이터** (총 8개 필드):
- [ ] Seigniorage Per Block: 숫자.XXXX WTON/block
- [ ] DAO Distribution Ratio (d): XX.XX%
- [ ] Min Staking Ratio (θ): XX.XX%
- [ ] Validator Distribution Ratio (α): XX.XX%
- [ ] Half Saturation Point (k): 숫자 TON (천단위 콤마)
- [ ] Total Effective Bridged TON (x): 숫자.XXXX TON
- [ ] My Bridged TON: 숫자.XXXX TON
- [ ] My Effective Bridged TON: 숫자.XXXX TON

**데이터 소스**:
```typescript
const seigPerBlock = await seigManager.seigPerBlock();
const daoDistributionRatio = await seigManager.daoDistributionRatio();
const minStakingRatio = await seigManager.minStakingRatio();
const validatorDistributionRatio = await seigManager.validatorDistributionRatio();
const halfSaturationPoint = await seigManager.halfSaturationPoint();
const totalEffectiveBridgedTon = await seigManager.totalEffectiveBridgedTON();
const bridgedTon = await layer2Manager.getBridgedTonByLayer(layer2Address);
const effectiveBridgedTon = await seigManager.getEffectiveBridgedTon(layer2Address);
```

**단위 변환 검증**:
- [ ] seigPerBlock: 27 decimals → WTON
- [ ] Ratios: RAY (27 decimals) → percentage (%)
- [ ] halfSaturationPoint: 18 decimals → TON
- [ ] Bridged TON: 18 decimals → TON

#### [ ] 4.5.5 Seigniorage Update History 카드

**표시 데이터**:
- [ ] 🔄 Last Seigniorage Update Block: 숫자 (강조 표시)
- [ ] Current L1 Block: 숫자
- [ ] Blocks Since Last Update: 숫자 blocks
- [ ] Estimated Pending Seigniorage: 숫자.XXXX WTON
- [ ] System Paused: ⚠️ Yes (Cannot Update) / ✅ No (Can Update)

**계산식 검증**:
```typescript
const blocksSinceUpdate = currentBlock - lastSeigBlock;
const estimatedPending = blocksSinceUpdate * seigPerBlock * (1 - daoRatio/100);
```

#### [ ] 4.5.6 Reward Per Unit Tracking 카드

**표시 데이터**:
- [ ] Bridged TON Reward Per Unit (Sequencer): 소수점 9자리
- [ ] Validator Reward Per Unit: 소수점 9자리
- [ ] Ratio (Validator / Sequencer): 소수점 4자리
- [ ] Expected Ratio (α / (1-α)): 소수점 4자리

**계산식 검증**:
```typescript
const actualRatio = validatorRewardPerUint / bridgedTONRewardPerUint;
const expectedRatio = validatorDistributionRatio / (100 - validatorDistributionRatio);
// actualRatio와 expectedRatio가 일치해야 함
```

#### [ ] 4.5.7 Bridged TON & Required Stake 카드

**표시 데이터**:
- [ ] Bridged TON (Portal Balance): 숫자.XXXX TON
- [ ] Required Stake (최소 담보금): 숫자.XXXX WTON
- [ ] Current Stake (현재 담보금): 숫자.XXXX WTON
- [ ] Min Staking Ratio (θ): XX.XX%
- [ ] Calculated Min (θ × Bridged TON): 숫자.XXXX WTON
- [ ] Stake Coverage: XX.XX% (✅ green if >= 100%, ❌ red if < 100%)

**계산식 검증**:
```typescript
const calculatedMin = bridgedTon * minStakingRatio / 100;
const coverage = (currentStake / requiredStake) * 100;
```

**Coverage 색상 로직**:
- [ ] currentStake >= requiredStake: status-success (green)
- [ ] currentStake < requiredStake: status-error (red)

#### [ ] 4.5.8 Eligibility Checklist 카드

**검증 항목** (총 5개):
1. [ ] Registered in Layer2Registry: ✅ / ❌
2. [ ] Layer2 Status Active: ✅ / ❌
3. [ ] Bridged TON > 0: ✅ / ❌
4. [ ] Current Stake >= Required Stake: ✅ / ❌
5. [ ] Not Paused: ✅ / ❌

**Final Eligibility 표시**:
- [ ] ✅ ELIGIBLE (모든 조건 만족, 강조 표시)
- [ ] ❌ NOT ELIGIBLE (하나라도 실패)

**조건부 UI**:
- [ ] Not eligible 시: "⚠️ Not eligible for seigniorage distribution. Fix the failed checks above to become eligible."
- [ ] Eligible + claimable > 0 시: "💰 Claimable Seigniorage: X.XXXX WTON" (녹색 배경)

**데이터 소스**:
```typescript
const eligibilityInfo = await seigManager.checkCurrentEligibility(layer2Address);
// returns (bool isEligible, uint256 requiredStake, uint256 currentStake)
```

#### [ ] 4.5.9 Update Seigniorage 카드

**조건부 표시**:
- [ ] Paused 시: "⚠️ Seigniorage is currently paused. Cannot update until unpaused."
- [ ] Not paused 시: Update 버튼 표시

**표시 데이터**:
- [ ] Blocks Since Last Update: 숫자
- [ ] Eligible for Distribution: ✅ Yes / ❌ No

**UI 요소**:
- [ ] 버튼: "🔄 Update Seigniorage" / "⏳ Updating..."
- [ ] 안내: "Trigger seigniorage distribution and claim rewards" / "Not eligible - ensure you have sufficient stake and bridged TON"

**인터랙션 테스트**:
1. [ ] 지갑 미연결 시 "Please connect wallet first"
2. [ ] selectedLayer2 없을 때 버튼 비활성화
3. [ ] isPaused=true 시 버튼 비활성화
4. [ ] 성공 시 "✅ Seigniorage updated successfully!"
5. [ ] 성공 후 데이터 자동 갱신

**트랜잭션**:
```typescript
await seigManager.updateSeigniorage();
```

---

### 4.6 L2 Information 탭

#### [ ] 4.6.1 L2 Network Information 카드

**표시 데이터**:
- [ ] SystemConfig: 주소
- [ ] Expected L2 Chain ID: 901 (녹색 배지)
- [ ] Actual L2 Chain ID: 901 (녹색) / 다른 값 (빨강) / N/A (회색)
- [ ] Status: ⚠️ Chain ID mismatch (조건부) / ⚠️ L2 not reachable (조건부)
- [ ] L2 Block Number: 숫자 / N/A
- [ ] L2 RPC URL: http://localhost:9545

**조건부 메시지**:
- [ ] l2ChainId !== '901' && l2ChainId !== 'N/A': "⚠️ Chain ID mismatch! L2 should be 901"
- [ ] l2ChainId === 'N/A': "⚠️ L2 not reachable. Check if L2 node is running."

#### [ ] 4.6.2 Proposer & Batcher 카드

**표시 데이터**:
- [ ] Batcher Hash: 0x000000...000f39fd... (66자)
- [ ] Batcher Address (from hash): 0xf39Fd... (처음 42자)
- [ ] Unsafe Block Signer (Proposer): 주소
- [ ] Batch Inbox: 주소

**데이터 소스**:
```typescript
const batcherHash = await systemConfig.batcherHash();
const batcherAddress = batcherHash.substring(0, 42);
const unsafeBlockSigner = await systemConfig.unsafeBlockSigner();
const batchInbox = await systemConfig.batchInbox();
```

#### [ ] 4.6.3 System Configuration 카드

**표시 데이터**:
- [ ] Gas Limit: 숫자 (천단위 콤마)
- [ ] Overhead: 숫자
- [ ] Scalar: 숫자
- [ ] Base Fee Scalar: 숫자
- [ ] Blob Base Fee Scalar: 숫자

**데이터 소스**:
```typescript
const gasLimit = await systemConfig.gasLimit();
const overhead = await systemConfig.overhead();
const scalar = await systemConfig.scalar();
const basefeeScalar = await systemConfig.basefeeScalar();
const blobbasefeeScalar = await systemConfig.blobbasefeeScalar();
```

#### [ ] 4.6.4 Bridge & Portal Addresses 카드

**표시 주소**:
- [ ] L1 Standard Bridge
- [ ] Optimism Portal
- [ ] L1 CrossDomain Messenger
- [ ] Dispute Game Factory

#### [ ] 4.6.5 Portal Status & Balances 카드

**표시 데이터**:
- [ ] Guardian: 주소
- [ ] Paused: ⚠️ Yes (Paused) (빨강) / ✅ No (Active) (녹색)
- [ ] Portal TON Balance: 숫자.XXXX TON (큰 글씨)
- [ ] Portal ETH Balance: 숫자.XXXX ETH
- [ ] Bridge TON Balance: 숫자.XXXX TON (큰 글씨)

**데이터 소스**:
```typescript
const portalGuardian = await portalContract.guardian();
const portalPaused = await portalContract.paused();
const portalTonBal = await tonContract.balanceOf(portal);
const portalEthBal = await l1Provider.getBalance(portal);
const bridgeTonBal = await tonContract.balanceOf(l1Bridge);
```

---

### 4.7 Bridge to L2 탭

#### [ ] 4.7.1 Bridge ETH to L2 (Deposit) 카드

**표시 데이터**:
- [ ] L1 Standard Bridge: 주소
- [ ] Your L1 ETH Balance: 숫자.XXXX ETH
- [ ] Portal ETH Balance: 숫자.XXXX ETH

**UI 요소**:
- [ ] 입력 필드: placeholder="Amount (ETH)"
- [ ] 버튼: "⬇️ Deposit ETH to L2" / "⏳ Depositing..."
- [ ] 안내: "Gas Limit: 200,000 (sufficient for standard bridge)"

**인터랙션 테스트**:
1. [ ] 금액 입력 가능
2. [ ] 음수 불가
3. [ ] 성공 시 "✅ ETH deposit to L2 successful! Wait ~1 minute for L2 confirmation."
4. [ ] 성공 후 데이터 갱신

**트랜잭션**:
```typescript
await bridgeContract.depositETH(200000, '0x', { value: amountWei });
```

#### [ ] 4.7.2 Bridge TON to L2 (Deposit) 카드

**표시 데이터**:
- [ ] L1 TON: 주소
- [ ] L2 TON: 주소
- [ ] Your L1 TON Balance: 숫자.XXXX TON

**UI 요소**:
- [ ] 입력 필드: placeholder="Amount (TON)"
- [ ] 버튼: "⬇️ Deposit TON to L2" / "⏳ Depositing..."
- [ ] 안내: "Your L1 TON Balance: X.XXXX TON"

**인터랙션 테스트**:
1. [ ] 2-step 프로세스: approve → bridge
2. [ ] 성공 시 "✅ TON deposit to L2 successful! Wait ~1 minute for L2 confirmation."

**트랜잭션**:
```typescript
// 1. Approve
await tonContract.approve(l1Bridge, amountWei);

// 2. Bridge
await bridgeContract.depositERC20(l1Ton, l2Ton, amountWei, 200000, '0x');
```

#### [ ] 4.7.3 Withdraw ETH from L2 카드

**조건부 표시**:
- [ ] L2 running: 출금 폼 표시
- [ ] L2 not running: "⚠️ L2 is not running. Please start the L2 node first."

**표시 데이터**:
- [ ] L2 Standard Bridge: 0x4200000000000000000000000000000000000010
- [ ] L2 RPC: http://localhost:9545

**UI 요소**:
- [ ] 입력 필드: placeholder="Amount (ETH)"
- [ ] 버튼: "⬆️ Withdraw ETH from L2" / "⏳ Withdrawing..."
- [ ] 경고: "⚠️ Note: After withdrawal request, you must wait for challenge period and finalize on L1"

**인터랙션 테스트**:
1. [ ] 자동 네트워크 전환 (L1 → L2 Chain ID 901)
2. [ ] L2 네트워크 없을 시 자동 추가
3. [ ] 성공 시 "✅ Withdrawal initiated! Now you need to wait for the challenge period (~7 days on mainnet, shorter on testnet) and then finalize on L1."
4. [ ] 완료 후 L1으로 자동 전환

**트랜잭션 (L2)**:
```typescript
await l2BridgeContract.bridgeETH(200000, '0x', { value: amountWei });
```

#### [ ] 4.7.4 Withdraw TON from L2 카드

**조건부 표시**:
- [ ] L2 running && rollupInfo 존재: 출금 폼
- [ ] 그 외: "⚠️ L2 is not running or rollup info not available."

**인터랙션 테스트**:
1. [ ] 자동 네트워크 전환 (L1 → L2)
2. [ ] 2-step 프로세스: L2 TON approve → withdraw
3. [ ] 성공 시 경고 메시지
4. [ ] 완료 후 L1으로 자동 전환

**트랜잭션 (L2)**:
```typescript
// 1. Approve L2 TON
await l2TonContract.approve(l2Bridge, amountWei);

// 2. Withdraw
await l2BridgeContract.withdraw(l2Ton, amountWei, 200000, '0x');
```

#### [ ] 4.7.5 Finalize Withdrawal on L1 카드

**UI 상태**:
- [ ] 경고 박스: "⚠️ Advanced Feature: Requires withdrawal proof from L2 transaction."
- [ ] 상세 설명 표시 (5단계 프로세스)
- [ ] OptimismPortal 주소 표시
- [ ] 입력 필드: placeholder="L2 Withdrawal Transaction Hash", 비활성화
- [ ] 버튼: "🔧 Finalize (Advanced - Coming Soon)", 비활성화

**클릭 시 알림**:
- [ ] "⚠️ This is a placeholder. In production, you would need to implement: ..." (상세 안내)

---

### 4.8 Dispute Games 탭

#### [ ] 4.8.1 Recent Dispute Games 테이블

**테이블 헤더**:
- [ ] #
- [ ] Type
- [ ] Proxy Address
- [ ] Created At

**빈 상태**:
- [ ] "No dispute games created yet" (games.length === 0)

**데이터 행**:
- [ ] #: 게임 인덱스 (숫자)
- [ ] Type: 게임 타입 (숫자, 배지 스타일)
- [ ] Proxy Address: 주소 축약 (formatAddress)
- [ ] Created At: 날짜/시간 (formatTimestamp: MM/DD/YYYY, HH:MM:SS)

**데이터 소스**:
```typescript
const gameCount = await factory.gameCount();
// 최근 10개만 표시
for (let i = gameCount - 10; i < gameCount; i++) {
  const game = await factory.gameAtIndex(i);
  // game[0]: gameType
  // game[1]: timestamp
  // game[2]: proxy
}
```

**CLI 검증**:
```bash
# Game Count
cast call $DISPUTE_GAME_FACTORY "gameCount()(uint256)" --rpc-url http://localhost:8545

# Game at Index
cast call $DISPUTE_GAME_FACTORY "gameAtIndex(uint256)(uint32,uint64,address)" 0 --rpc-url http://localhost:8545
```

---

### 4.9 Balances 탭

#### [ ] 4.9.1 Your Token Balances 카드

**Balance Cards** (총 4개):
1. [ ] ⚡ ETH: 숫자.XXXX
2. [ ] 🪙 TON: 숫자.XXXX
3. [ ] 💎 WTON: 숫자.XXXX
4. [ ] 🔒 Staked: 숫자.XXXX

**스타일 검증**:
- [ ] balance-cards 그리드 레이아웃
- [ ] 각 카드: balance-card 클래스
- [ ] 아이콘, 라벨, 값이 명확하게 표시

#### [ ] 4.9.2 Faucet - Get Test Tokens 카드

**버튼** (총 3개):
1. [ ] ⚡ Get 100 ETH
2. [ ] 🪙 Get 10,000 TON
3. [ ] 💎 Get 10,000 WTON

**인터랙션 테스트**:

**Get 100 ETH**:
- [ ] 지갑 미연결 시 "Please connect wallet first"
- [ ] 성공 시 "✅ Successfully sent 100 ETH!"
- [ ] 실패 시 에러 메시지 + "Tip: You can also use 'cast send' command in terminal."
- [ ] 성공 후 잔액 자동 갱신

**트랜잭션**:
```typescript
const testAccount = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';
const testSigner = await l1Provider.getSigner(testAccount);
await testSigner.sendTransaction({
  to: address,
  value: ethers.parseEther('100'),
});
```

**Get 10,000 TON**:
- [ ] 성공 시 "✅ Successfully minted 10,000 TON!"
- [ ] 성공 후 잔액 갱신

**트랜잭션**:
```typescript
const tonContract = new ethers.Contract(CONFIG.contracts.ton, [
  ...TON_ABI,
  'function mint(address to, uint256 amount) returns (bool)',
], signer);
await tonContract.mint(address, ethers.parseEther('10000'));
```

**Get 10,000 WTON**:
- [ ] 성공 시 "✅ Successfully minted 10,000 WTON!"
- [ ] WTON은 27 decimals 사용

**트랜잭션**:
```typescript
const wtonContract = new ethers.Contract(CONFIG.contracts.wton, [
  ...WTON_ABI,
  'function mint(address to, uint256 amount) returns (bool)',
], signer);
await wtonContract.mint(address, ethers.parseUnits('10000', 27));
```

**경고 메시지**:
- [ ] "⚠️ Devnet only - These functions may not work on mainnet"

#### [ ] 4.9.3 Token Swap 카드

**버튼** (총 2개):
1. [ ] 🪙→💎 TON to WTON
2. [ ] 💎→🪙 WTON to TON

**UI 요소**:
- [ ] 입력 필드: placeholder="Amount", type="number", step="1", min="0"

**TON to WTON 테스트**:
- [ ] 2-step: TON approve → swapFromTON
- [ ] 성공 시 "✅ Successfully swapped X TON to WTON!"
- [ ] 성공 후 입력 필드 초기화 및 잔액 갱신

**트랜잭션**:
```typescript
// 1. Approve
await tonContract.approve(CONFIG.contracts.wton, amountWei);

// 2. Swap
await wtonContract.swapFromTON(amountWei);
```

**WTON to TON 테스트**:
- [ ] 1-step: swapToTON (approval 불필요, 보유 WTON 소각)
- [ ] 성공 시 "✅ Successfully swapped X WTON to TON!"

**트랜잭션**:
```typescript
await wtonContract.swapToTON(amountWei); // WTON is 27 decimals
```

#### [ ] 4.9.4 Your Account 카드

**표시 정보**:
- [ ] Address: 전체 주소
- [ ] Network: "TON Staking V3 Local (Chain ID: 900)"

---

## 5. 인터랙션 테스트

### [ ] 5.1 지갑 연결

**미연결 상태**:
- [ ] "Connect Your Wallet" 화면 표시
- [ ] "Connect Wallet" 버튼 표시
- [ ] 테스트 계정 5개 표시 (이름, 주소, 역할)

**연결 프로세스**:
1. [ ] "Connect Wallet" 클릭
2. [ ] MetaMask 팝업 표시
3. [ ] 네트워크 추가 요청 (Chain ID 900 없을 때)
4. [ ] 계정 승인 요청
5. [ ] 연결 성공 시 대시보드 표시
6. [ ] 헤더에 "🟢 Connected: 0xABCD...5678" 표시

**네트워크 전환**:
- [ ] 다른 네트워크에 있을 때 자동 전환 요청
- [ ] 네트워크 추가 필요 시 자동 요청 (Chain ID 900)

### [ ] 5.2 데이터 자동 갱신

**10초 자동 갱신**:
- [ ] 10초마다 loadDashboardData() 호출
- [ ] 블록 번호 증가 확인
- [ ] 밸런스 업데이트 확인

**수동 갱신**:
- [ ] "🔄 Refresh Data" 버튼 클릭 시 즉시 갱신
- [ ] 로딩 중 "🔄 Refreshing..." 표시
- [ ] 로딩 중 버튼 비활성화

### [ ] 5.3 사이드바 네비게이션

**데스크톱**:
- [ ] 사이드바 항상 표시
- [ ] 활성 탭 하이라이트 (is-active 클래스)
- [ ] 클릭 시 탭 전환

**모바일**:
- [ ] 햄버거 메뉴 버튼 표시
- [ ] 버튼 클릭 시 사이드바 토글
- [ ] 사이드바 열림 시 "✕" 아이콘
- [ ] 메뉴 항목 클릭 시 사이드바 자동 닫힘

**탭 목록** (총 9개):
1. [ ] 📊 Overview
2. [ ] 👤 Operator
3. [ ] 👥 Validators
4. [ ] 💎 TON Staking
5. [ ] 💰 Seigniorage
6. [ ] 🌐 L2 Information
7. [ ] 🌉 Bridge to L2
8. [ ] 🎮 Dispute Games
9. [ ] 💰 Balances

---

## 6. 데이터 정확성 검증

### [ ] 6.1 컨트랙트 주소 일치 검증

**자동 스크립트 실행**:
```bash
./scripts/verify-webui-config.sh
```

**수동 검증 (각 컨트랙트별)**:
```bash
# TON
DEVNET=$(jq -r '.ton' .devnet/addresses.json)
CONFIG=$(grep "ton:" web-ui/src/config.ts | grep -o '0x[a-fA-F0-9]\{40\}' | head -1)
test "$DEVNET" == "$CONFIG" && echo "✅ TON" || echo "❌ TON mismatch"

# WTON
DEVNET=$(jq -r '.wton' .devnet/addresses.json)
CONFIG=$(grep "wton:" web-ui/src/config.ts | grep -o '0x[a-fA-F0-9]\{40\}' | head -1)
test "$DEVNET" == "$CONFIG" && echo "✅ WTON" || echo "❌ WTON mismatch"

# SeigManager
DEVNET=$(jq -r '.seigManagerProxy' .devnet/addresses.json)
CONFIG=$(grep "seigManager:" web-ui/src/config.ts | grep -o '0x[a-fA-F0-9]\{40\}' | head -1)
test "$DEVNET" == "$CONFIG" && echo "✅ SeigManager" || echo "❌ SeigManager mismatch"

# (나머지 8개 컨트랙트도 동일하게 검증)
```

### [ ] 6.2 블록 번호 실시간 검증

**CLI와 Web UI 비교**:
```bash
# CLI로 블록 번호 확인
L1_BLOCK=$(cast block-number --rpc-url http://localhost:8545)
echo "CLI L1 Block: $L1_BLOCK"

# Web UI에 표시된 블록 번호와 비교
# (브라우저 개발자 도구에서 확인)
```

**검증**:
- [ ] CLI 블록 번호 ± 2 이내에 Web UI 블록 번호가 표시됨
- [ ] 10초 후 재확인 시 블록 번호 증가

### [ ] 6.3 잔액 정확성 검증

**ETH 잔액**:
```bash
MY_ADDR="0x..." # 연결된 지갑 주소
cast balance $MY_ADDR --rpc-url http://localhost:8545 | xargs cast from-wei
# Web UI "Balances" 탭의 ETH 값과 비교
```

**TON 잔액**:
```bash
TON=$(jq -r '.ton' .devnet/addresses.json)
cast call $TON "balanceOf(address)(uint256)" $MY_ADDR --rpc-url http://localhost:8545 | xargs cast from-wei
# Web UI의 TON 값과 비교
```

**WTON 잔액** (27 decimals):
```bash
WTON=$(jq -r '.wton' .devnet/addresses.json)
cast call $WTON "balanceOf(address)(uint256)" $MY_ADDR --rpc-url http://localhost:8545 | awk '{print $1 / 10^27}'
# Web UI의 WTON 값과 비교
```

### [ ] 6.4 Operator 정보 정확성

**OperatorManager 주소**:
```bash
LAYER2_MANAGER=$(jq -r '.layer2ManagerProxy' .devnet/addresses.json)
SYSTEM_CONFIG=$(jq -r '.systemConfig' .devnet/addresses.json)
cast call $LAYER2_MANAGER "rollupConfigInfo(address)(uint8,address)" $SYSTEM_CONFIG --rpc-url http://localhost:8545
# 두 번째 값이 OperatorManager 주소
# Web UI "Operator" 탭의 OperatorManager와 비교
```

**Sequencer Collateral**:
```bash
SEIG_MANAGER=$(jq -r '.seigManagerProxy' .devnet/addresses.json)
CANDIDATE_ADDON="0x..." # Web UI에서 확인한 주소
OPERATOR_MANAGER="0x..." # Web UI에서 확인한 주소
cast call $SEIG_MANAGER "stakeOf(address,address)(uint256)" $CANDIDATE_ADDON $OPERATOR_MANAGER --rpc-url http://localhost:8545 | awk '{print $1 / 10^27}'
# Web UI의 Sequencer Collateral과 비교
```

### [ ] 6.5 Validator 목록 정확성

**Validator 수**:
```bash
RAT=$(jq -r '.ratProxy' .devnet/addresses.json)
SYSTEM_CONFIG=$(jq -r '.systemConfig' .devnet/addresses.json)
cast call $RAT "getValidatorCount(address)(uint256)" $SYSTEM_CONFIG --rpc-url http://localhost:8545
# Web UI "Validators" 탭의 숫자와 비교
```

**Active Validator 수**:
```bash
cast call $RAT "getActiveValidatorCount(address)(uint256)" $SYSTEM_CONFIG --rpc-url http://localhost:8545
# Web UI "Overview"의 Active Validators와 비교
```

---

## 7. 에러 핸들링 테스트

### [ ] 7.1 네트워크 에러

**L1 노드 중지 시나리오**:
1. [ ] L1 노드 중지: `docker stop ton-staking-l1`
2. [ ] Web UI 접속
3. [ ] "L1 Status: 🔴 Offline" 표시 확인
4. [ ] 콘솔에 적절한 에러 로그 확인
5. [ ] 다른 기능 시도 시 에러 메시지 표시
6. [ ] L1 재시작 후 자동 복구 확인

**L2 노드 중지 시나리오**:
1. [ ] L2 노드 중지: `docker stop ton-staking-l2-execution`
2. [ ] "L2 Status: ⚠️ Offline" 표시 확인
3. [ ] L2 Chain ID: N/A
4. [ ] "⚠️ L2 not reachable" 메시지 확인
5. [ ] Bridge 기능 비활성화 확인

### [ ] 7.2 트랜잭션 에러

**잔액 부족**:
1. [ ] WTON 잔액 0인 계정으로 테스트
2. [ ] "Add Collateral"에 큰 금액 입력
3. [ ] 트랜잭션 실행
4. [ ] "insufficient funds" 또는 유사 에러 표시 확인
5. [ ] 사용자 친화적 에러 메시지 확인

**권한 없음**:
1. [ ] Deployer가 아닌 계정으로 연결
2. [ ] 관리자 전용 기능 시도
3. [ ] "Caller is not authorized" 또는 유사 에러 확인

**가스 부족**:
1. [ ] ETH 잔액이 거의 없는 계정
2. [ ] 트랜잭션 시도
3. [ ] "out of gas" 에러 확인

### [ ] 7.3 입력 검증

**빈 입력**:
- [ ] 모든 입력 필드에 빈 값 입력 후 제출
- [ ] "Please enter a valid amount/address" 메시지 확인

**음수 입력**:
- [ ] 금액 필드에 음수 입력 시도
- [ ] HTML5 min="0" 속성으로 차단 확인

**잘못된 주소 형식**:
- [ ] Seigniorage 탭에서 "0x123" 입력
- [ ] "Invalid Ethereum address" 확인

**범위 초과**:
- [ ] Withdrawal 시 stakedAmount보다 큰 금액 입력
- [ ] "Amount exceeds staked balance" 확인

---

## 8. UI/UX 검증

### [ ] 8.1 반응형 디자인

**데스크톱 (1920px)**:
- [ ] 사이드바 고정 표시
- [ ] 카드 그리드 레이아웃 정상
- [ ] 모든 텍스트 읽기 쉬움

**태블릿 (768px)**:
- [ ] 사이드바 토글 버튼 표시
- [ ] 카드 1-2열 레이아웃
- [ ] 주소 축약 표시

**모바일 (375px)**:
- [ ] 햄버거 메뉴 버튼
- [ ] 카드 1열 레이아웃
- [ ] 가로 스크롤 없음
- [ ] 터치 영역 충분

### [ ] 8.2 로딩 상태

**버튼 로딩**:
- [ ] 로딩 중 버튼 텍스트 변경 (예: "Staking..." )
- [ ] 로딩 중 버튼 비활성화
- [ ] 스피너 또는 아이콘 애니메이션

**데이터 로딩**:
- [ ] 초기 로드 시 로딩 인디케이터
- [ ] 갱신 중 데이터 깜빡임 없음

### [ ] 8.3 성공/에러 피드백

**alert() 사용**:
- [ ] 성공 시 "✅ ..." 메시지
- [ ] 실패 시 "❌ Failed: ..." 메시지
- [ ] 경고 시 "⚠️ ..." 메시지

**미래 개선 사항**:
- [ ] Toast 알림으로 대체 고려
- [ ] 모달 다이얼로그 추가 고려

### [ ] 8.4 색상 및 아이콘

**상태 색상**:
- [ ] 녹색: 성공, 활성, 정상
- [ ] 빨강: 에러, 비활성, 경고
- [ ] 노랑: 주의, 대기
- [ ] 파랑: 정보

**아이콘 일관성**:
- [ ] ✅ 성공
- [ ] ❌ 실패
- [ ] ⚠️ 경고
- [ ] 🟢 온라인
- [ ] 🔴 오프라인
- [ ] 💰 금액
- [ ] 🔄 갱신

### [ ] 8.5 접근성

**키보드 네비게이션**:
- [ ] Tab 키로 모든 인터랙티브 요소 접근 가능
- [ ] Enter 키로 버튼 클릭 가능
- [ ] 포커스 표시 명확

**ARIA 라벨**:
- [ ] 버튼에 적절한 라벨
- [ ] 입력 필드에 라벨 연결
- [ ] 상태 메시지 읽기 가능

---

## 9. 최종 체크리스트

### [ ] 9.1 전체 플로우 테스트

**신규 사용자 시나리오**:
1. [ ] Web UI 접속
2. [ ] "Connect Wallet" 클릭
3. [ ] MetaMask 연결 및 네트워크 추가
4. [ ] Overview 탭에서 시스템 상태 확인
5. [ ] Balances 탭에서 Faucet으로 테스트 토큰 받기
6. [ ] TON → WTON swap
7. [ ] Operator 탭에서 Collateral 추가
8. [ ] TON Staking 탭에서 Stake
9. [ ] Seigniorage 탭에서 정보 조회
10. [ ] L2 Information 확인
11. [ ] Bridge to L2로 ETH 브리징
12. [ ] 전체 과정에서 에러 없음 확인

**Operator 시나리오**:
1. [ ] Operator 계정으로 연결
2. [ ] Operator 탭에서 정보 확인
3. [ ] Collateral 추가
4. [ ] Seigniorage 조회 및 Update
5. [ ] 성공 확인

**Validator 시나리오**:
1. [ ] Validator 계정으로 연결
2. [ ] Balances 탭에서 WTON 받기
3. [ ] TON Staking 탭에서 Stake
4. [ ] Validators 탭에서 본인 확인
5. [ ] RAT 등록 (별도 스크립트)

### [ ] 9.2 성능 테스트

**페이지 로드 시간**:
- [ ] 초기 로드 < 3초
- [ ] 탭 전환 < 500ms
- [ ] 데이터 갱신 < 2초

**메모리 사용**:
- [ ] 브라우저 개발자 도구에서 메모리 프로파일링
- [ ] 10분 사용 후 메모리 누수 없음 확인

### [ ] 9.3 브라우저 호환성

**테스트 브라우저**:
- [ ] Chrome (최신)
- [ ] Firefox (최신)
- [ ] Safari (macOS)
- [ ] Edge (최신)

**각 브라우저에서**:
- [ ] 지갑 연결 정상
- [ ] 모든 기능 작동
- [ ] UI 레이아웃 정상
- [ ] 콘솔 에러 없음

---

## 10. 자동 검증 스크립트 실행

### [ ] 10.1 Config 검증

```bash
./scripts/verify-webui-config.sh
```

**예상 출력**:
```
✅ TON address matches
✅ WTON address matches
✅ SeigManager address matches
...
✅ All 11 contract addresses verified!
```

### [ ] 10.2 Build 검증

```bash
cd web-ui
npm run build
echo $?  # 0이면 성공
```

### [ ] 10.3 완전한 통합 테스트

```bash
./scripts/test-webui-integration.sh
```

---

## ✅ 검증 완료 기준

**모든 항목이 체크되어야 함**:
- [ ] 3. 설정 파일 검증: 11/11 항목 통과
- [ ] 4. 페이지별 상세 검증: 모든 탭, 모든 카드, 모든 필드 확인
- [ ] 5. 인터랙션 테스트: 지갑 연결, 트랜잭션, 에러 핸들링
- [ ] 6. 데이터 정확성: CLI와 Web UI 비교하여 일치
- [ ] 7. 에러 핸들링: 모든 에러 시나리오 처리
- [ ] 8. UI/UX: 반응형, 로딩, 피드백, 접근성
- [ ] 9. 최종 체크리스트: 전체 플로우, 성능, 브라우저 호환성

**검증 완료 보고서 작성**:
```markdown
## Web UI 검증 완료 보고서

**날짜**: 2026-02-03
**검증자**: [이름]
**환경**: [OS], [브라우저]

### 검증 결과
- 총 항목: [숫자]
- 통과: [숫자]
- 실패: [숫자]

### 실패 항목
1. [항목명]: [원인] - [해결 방법]
2. ...

### 결론
✅ 모든 검증 통과 - Production Ready
또는
❌ [N]개 항목 실패 - 수정 필요
```

---

**문의**: [GitHub Issues](https://github.com/tokamak-network/ton-staking-v2/issues)
