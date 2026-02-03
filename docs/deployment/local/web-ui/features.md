# Web UI - 기능 가이드

TON Staking V3 Web UI의 모든 기능을 상세히 설명합니다.

---

## 📊 메뉴 구조

Web UI는 다음과 같이 구성되어 있습니다:

### Dashboard
- **Overview** - 전체 시스템 현황

### Management
- **Operator** - Operator 및 Sequencer 관리
- **Validators** - Validator 목록 및 상태
- **TON Staking** - 스테이킹 및 출금 관리
- **Seigniorage** - 시뇨리지 정보 및 발행

### L2 Network
- **L2 Information** - L2 네트워크 상세 정보
- **Bridge to L2** - L1 ↔ L2 브리지

### Monitoring
- **Dispute Games** - Dispute Game 목록
- **Balances** - 지갑 잔액 조회

---

## 1️⃣ Overview (개요)

**경로**: Dashboard → Overview

### 표시 정보

#### 📡 Node Status
- **L1 Status**: L1 네트워크 온라인 여부
- **L1 Block**: 현재 L1 블록 번호
- **L1 Chain ID**: 900 (확인)
- **L2 Status**: L2 네트워크 온라인 여부
- **L2 Block**: 현재 L2 블록 번호
- **L2 Chain ID**: 901 (확인)

**구현 함수**: `loadNodeStatus()`
```typescript
// L1 및 L2 Provider에서 블록 번호와 Chain ID 조회
const l1Block = await l1Provider.getBlockNumber();
const l1ChainId = await l1Provider.getNetwork().then(n => n.chainId);
const l2Block = await l2Provider.getBlockNumber();
const l2ChainId = await l2Provider.getNetwork().then(n => n.chainId);
```

#### 🌐 Rollup Information
- **SystemConfig**: SystemConfig 컨트랙트 주소
- **Rollup Type**: Optimism Bedrock DisputeGame (타입 3)
- **L2 TON**: L2 TON 토큰 주소
- **Name**: Rollup 이름
- **Rejected Seigs**: 시뇨리지 거부 여부

**구현 함수**: `loadRollupInfo()`
```typescript
// L1BridgeRegistry에서 getRollupInfo 호출
const registry = new ethers.Contract(
  CONFIG.contracts.l1BridgeRegistry,
  L1_BRIDGE_REGISTRY_ABI,
  l1Provider
);
const info = await registry.getRollupInfo(CONFIG.contracts.systemConfig);
```

#### ⚙️ System Parameters
- **V3 Migrated**: V3 마이그레이션 완료 여부
- **Total Validators**: 전체 Validator 수
- **Active Validators**: 활성 Validator 수
- **Min Collateral**: 최소 담보금 (WTON)

**구현 함수**: `loadSystemParams()`
```typescript
// SeigManager 및 RAT에서 시스템 파라미터 조회
const migrated = await seigManager.v3Migrated();
const total = await rat.getValidatorCount(CONFIG.contracts.systemConfig);
const active = await rat.getActiveValidatorCount(CONFIG.contracts.systemConfig);
const minColl = await rat.getDynamicMinimumCollateral(CONFIG.contracts.systemConfig);
```

#### 📍 TON Staking V3 Core Contracts
모든 핵심 컨트랙트 주소 표시:
- TON, WTON
- SeigManager, DepositManager, Layer2Manager
- L1BridgeRegistry, Layer2Registry
- RAT, ValidatorReward

#### 🌉 Optimism Stack Contracts
Optimism 관련 컨트랙트 주소:
- SystemConfig
- DisputeGameFactory
- OperatorManager
- CandidateAddOn

### 자동 업데이트
- **주기**: 10초마다 자동 새로고침
- **함수**: `loadDashboardData()`

---

## 2️⃣ Operator (운영자 관리)

**경로**: Management → Operator

### 기능

#### 👤 Operator & Sequencer Information

**표시 정보**:
- **Operator Address**: Operator 주소
- **OperatorManager**: OperatorManager 컨트랙트 주소
- **OperatorManager.manager()**: Manager 주소
- **CandidateAddOn (Layer2)**: Layer2 주소
- **Sequencer Collateral**: Sequencer 담보금 (WTON)
- **Layer2Registry Status**: Layer2 등록 상태

**구현 함수**: `loadOperatorInfo()`
```typescript
const layer2Manager = new ethers.Contract(
  CONFIG.contracts.layer2Manager,
  LAYER2_MANAGER_ABI,
  l1Provider
);

const configInfo = await layer2Manager.rollupConfigInfo(CONFIG.contracts.systemConfig);
const operator = await layer2Manager.operatorOfRollupConfig(CONFIG.contracts.systemConfig);
const operatorManager = configInfo[1];
const candidateAddOn = await layer2Manager.candidateAddOnOfOperator(operatorManager);
const sequencerStake = await seigManager.stakeOf(candidateAddOn, operatorManager);
const isLayer2Registered = await layer2Registry.layer2s(candidateAddOn);
```

#### 💎 Add Sequencer Collateral

**기능**: Sequencer 담보금 추가

**절차**:
1. WTON 금액 입력
2. "Add Collateral" 버튼 클릭
3. WTON Approve 트랜잭션 (SeigManager에게)
4. Deposit 트랜잭션 (DepositManager.deposit)

**구현 함수**: `handleAddCollateral()`
```typescript
// 1. Approve WTON
const wtonContract = new ethers.Contract(CONFIG.contracts.wton, WTON_ABI, signer);
await wtonContract.approve(CONFIG.contracts.seigManager, amountWei);

// 2. Deposit to SeigManager
const depositManager = new ethers.Contract(CONFIG.contracts.depositManager, DEPOSIT_MANAGER_ABI, signer);
await depositManager.deposit(operatorInfo.operatorManager, amountWei);
```

**필요 조건**:
- WTON 잔액 충분
- 지갑 연결됨

---

## 3️⃣ Validators (검증자 관리)

**경로**: Management → Validators

### 기능

#### 👥 Registered Validators

**표시 정보** (테이블 형식):
| 열 | 설명 |
|----|------|
| Address | Validator 주소 |
| Deposit | 예치금 (WTON) |
| Available | 사용 가능 담보금 (WTON) |
| RAT Status | RAT 등록 상태 |
| Active | 활성 상태 |

**구현 함수**: `loadValidators()`
```typescript
const rat = new ethers.Contract(CONFIG.contracts.rat, RAT_ABI, l1Provider);

// L2의 모든 Validator 주소 가져오기
const validatorAddrs = await rat.getL2Validators(CONFIG.contracts.systemConfig);

// 각 Validator 정보 조회
for (const addr of validatorAddrs) {
  const deposit = await rat.getValidatorDeposit(addr, CONFIG.contracts.systemConfig);
  const available = await rat.getAvailableCollateral(addr, CONFIG.contracts.systemConfig);
  const isActive = await rat.isValidatorActive(addr, CONFIG.contracts.systemConfig);
  const registration = await rat.getValidatorRegistration(addr, CONFIG.contracts.systemConfig);
}
```

**특징**:
- Validator가 없으면 "No validators registered yet" 메시지 표시
- 10초마다 자동 업데이트

---

## 4️⃣ TON Staking (스테이킹 관리)

**경로**: Management → TON Staking

### 기능

#### 💎 Deposit (스테이킹)

**기능**: WTON 토큰을 스테이킹

**절차**:
1. WTON 금액 입력
2. "Stake" 버튼 클릭
3. WTON Approve 트랜잭션 (DepositManager에게)
4. Deposit 트랜잭션

**구현 코드**:
```typescript
// 1. Approve WTON
const wtonContract = new ethers.Contract(CONFIG.contracts.wton, WTON_ABI, signer);
await wtonContract.approve(CONFIG.contracts.depositManager, amountWei);

// 2. Deposit
const depositManager = new ethers.Contract(CONFIG.contracts.depositManager, DEPOSIT_MANAGER_ABI, signer);
await depositManager.deposit(operatorInfo.candidateAddOn, amountWei);
```

**표시 정보**:
- Target Layer2: 스테이킹 대상 Layer2 주소
- Your Staked Amount: 현재 스테이킹 금액
- Your WTON Balance: 사용 가능한 WTON 잔액

**필요 조건**:
- ✅ CandidateAddOn이 설정되어 있어야 함
- ✅ WTON 잔액 충분

#### 📤 Request Withdrawal (출금 요청)

**기능**: 스테이킹된 WTON 출금 요청

**절차**:
1. 출금할 WTON 금액 입력
2. "Request Withdrawal" 버튼 클릭
3. RequestWithdrawal 트랜잭션

**구현 코드**:
```typescript
const depositManager = new ethers.Contract(CONFIG.contracts.depositManager, DEPOSIT_MANAGER_ABI, signer);
await depositManager.requestWithdrawal(operatorInfo.candidateAddOn, amountWei);
```

**표시 정보**:
- Staked Amount: 스테이킹된 금액
- Pending Unstaked: 출금 대기 중인 금액
- Pending Requests: 출금 요청 개수

**유효성 검사**:
- 출금 금액이 스테이킹 금액을 초과하지 않는지 확인

#### ✅ Process Withdrawal (출금 처리)

**기능**: 완료된 출금 요청을 처리하여 WTON 수령

**절차**:
1. 처리할 요청 개수 입력
2. "Process Withdrawal" 버튼 클릭
3. ProcessWithdrawal 트랜잭션

**구현 코드**:
```typescript
const depositManager = new ethers.Contract(CONFIG.contracts.depositManager, DEPOSIT_MANAGER_ABI, signer);
await depositManager.processWithdrawal(operatorInfo.candidateAddOn, parseInt(num));
```

**표시 정보**:
- Pending Requests: 처리 가능한 요청 개수
- Pending Amount: 출금 대기 중인 총 금액

**필요 조건**:
- Pending Requests > 0

---

## 5️⃣ Seigniorage (시뇨리지)

**경로**: Management → Seigniorage

### 기능

#### 💰 Seigniorage Information

**주의**: 이 탭은 코드에 구현되어 있지만 UI에서 접근할 수 없습니다 (activeTab 조건에 'seigniorage'가 없음).

**표시될 정보** (구현됨):
- Last Seig Block: 마지막 시뇨리지 발행 블록
- Current Block: 현재 블록
- Bridged TON: 브리지된 TON
- Effective Bridged TON: 유효 브리지 TON
- Total Effective Bridged TON: 전체 유효 브리지 TON
- Eligibility: 수령 자격 여부
- Required Stake: 필요한 스테이킹
- Current Stake: 현재 스테이킹
- Claimable Amount: 수령 가능한 금액
- Seig Per Block: 블록당 시뇨리지
- DAO Distribution Ratio: DAO 배분 비율
- Validator Distribution Ratio: Validator 배분 비율

**구현 함수**: `loadSeigniorageInfo()`

**현재 상태**: ⚠️ UI에서 접근 불가 (메뉴에 없음)

---

## 6️⃣ L2 Information (L2 정보)

**경로**: L2 Network → L2 Information

### 기능

#### 🌐 L2 Network Information
- **SystemConfig**: SystemConfig 주소
- **Expected L2 Chain ID**: 901
- **Actual L2 Chain ID**: 실제 L2 Chain ID
- **L2 Block Number**: L2 블록 번호
- **L2 RPC URL**: L2 RPC 엔드포인트

**검증**:
- L2 Chain ID가 901인지 확인
- 불일치 시 경고 메시지 표시

#### 👤 Proposer & Batcher
- **Batcher Hash**: Batcher 해시
- **Batcher Address**: Batcher 주소 (해시에서 추출)
- **Unsafe Block Signer (Proposer)**: Proposer 주소
- **Batch Inbox**: Batch Inbox 주소

#### 🔧 System Configuration
- **Gas Limit**: L2 가스 한도
- **Overhead**: 오버헤드
- **Scalar**: 스칼라
- **Base Fee Scalar**: 베이스 수수료 스칼라
- **Blob Base Fee Scalar**: Blob 베이스 수수료 스칼라

#### 🌉 Bridge & Portal Addresses
- **L1 Standard Bridge**: L1 브리지 주소
- **Optimism Portal**: Portal 주소
- **L1 CrossDomain Messenger**: L1 메신저 주소
- **Dispute Game Factory**: DisputeGameFactory 주소

#### 🛡️ Portal Status & Balances
- **Guardian**: Portal Guardian 주소
- **Paused**: Portal 일시 중지 상태
- **Portal TON Balance**: Portal의 TON 잔액
- **Portal ETH Balance**: Portal의 ETH 잔액
- **Bridge TON Balance**: Bridge의 TON 잔액

**구현 함수**: `loadL2Info()`

---

## 7️⃣ Bridge to L2 (브리지)

**경로**: L2 Network → Bridge to L2

### 기능

#### ⚡ Bridge ETH to L2 (Deposit)

**기능**: L1에서 L2로 ETH 전송

**절차**:
1. ETH 금액 입력
2. "Deposit ETH to L2" 버튼 클릭
3. depositETH 트랜잭션 (L1 Standard Bridge)

**구현 코드**:
```typescript
const bridgeContract = new ethers.Contract(l2Info.l1Bridge, L1_STANDARD_BRIDGE_ABI, signer);
await bridgeContract.depositETH(200000, '0x', { value: amountWei });
```

**표시 정보**:
- L1 Standard Bridge: 브리지 주소
- Your L1 ETH Balance: L1 ETH 잔액
- Portal ETH Balance: Portal의 ETH 잔액

**Gas Limit**: 200,000 (충분한 가스)

#### 💎 Bridge TON to L2 (Deposit)

**기능**: L1에서 L2로 TON 전송

**절차**:
1. TON 금액 입력
2. "Deposit TON to L2" 버튼 클릭
3. TON Approve 트랜잭션 (L1 Standard Bridge에게)
4. depositERC20 트랜잭션

**구현 코드**:
```typescript
// 1. Approve TON
const tonContract = new ethers.Contract(CONFIG.contracts.ton, TON_ABI, signer);
await tonContract.approve(l2Info.l1Bridge, amountWei);

// 2. Bridge TON
const bridgeContract = new ethers.Contract(l2Info.l1Bridge, L1_STANDARD_BRIDGE_ABI, signer);
await bridgeContract.depositERC20(
  CONFIG.contracts.ton,
  rollupInfo.l2Ton,
  amountWei,
  200000,
  '0x'
);
```

**표시 정보**:
- L1 TON: L1 TON 주소
- L2 TON: L2 TON 주소
- Your L1 TON Balance: L1 TON 잔액

#### 📤 Withdraw ETH from L2

**기능**: L2에서 L1로 ETH 출금

**주의**: ⚠️ **이 기능은 L2 지갑 연결이 필요합니다**

**구현 코드**:
```typescript
// L2 Provider 사용
const l2BridgeAddress = '0x4200000000000000000000000000000000000010';
const l2Bridge = new ethers.Contract(l2BridgeAddress, L2_STANDARD_BRIDGE_ABI, l2Signer);
await l2Bridge.withdraw(ethers.ZeroAddress, amountWei, 200000, '0x');
```

**현재 상태**: ⚠️ **L2 지갑 자동 전환 미구현**

사용자가 수동으로 MetaMask에서 L2 네트워크로 전환해야 합니다.

---

## 8️⃣ Dispute Games (분쟁 게임)

**경로**: Monitoring → Dispute Games

### 기능

#### 🎮 Recent Dispute Games

**표시 정보** (테이블 형식):
| 열 | 설명 |
|----|------|
| # | 게임 인덱스 |
| Type | 게임 타입 |
| Proxy Address | 게임 프록시 주소 |
| Created At | 생성 시간 |

**구현 함수**: `loadGames()`
```typescript
const factory = new ethers.Contract(
  CONFIG.contracts.disputeGameFactory,
  DISPUTE_GAME_FACTORY_ABI,
  l1Provider
);

const gameCount = await factory.gameCount();

// 최근 10개 게임만 표시
const maxGames = Math.min(Number(gameCount), 10);
for (let i = Number(gameCount) - maxGames; i < Number(gameCount); i++) {
  const game = await factory.gameAtIndex(i);
  // game[0]: gameType
  // game[1]: timestamp
  // game[2]: proxy address
}
```

**특징**:
- 최근 10개 게임만 표시
- 역순으로 정렬 (최신 게임이 먼저)
- 게임이 없으면 "No dispute games created yet" 메시지

---

## 9️⃣ Balances (잔액 조회)

**경로**: Monitoring → Balances

### 기능

#### 💰 Account Balances

**주의**: 이 탭은 코드에 구현되어 있지만 UI에서 접근할 수 없습니다 (activeTab 조건에 'balances'가 없음).

**표시될 정보** (구현됨):
- **ETH Balance**: ETH 잔액
- **TON Balance**: TON 잔액  
- **WTON Balance**: WTON 잔액
- **Staked Amount**: 스테이킹 금액
- **Pending Unstaked**: 출금 대기 금액
- **Withdrawal Requests**: 출금 요청 개수

**구현 함수**: `loadUserBalances()`

**현재 상태**: ⚠️ UI에서 접근 불가 (메뉴에 없음)

**대안**: Overview 탭이나 각 기능 탭에서 관련 잔액이 표시됩니다.

---

## 🔄 자동 업데이트 기능

모든 데이터는 **10초마다 자동으로 새로고침**됩니다:

```typescript
useEffect(() => {
  loadDashboardData();
  
  // Auto refresh every 10 seconds
  const interval = setInterval(loadDashboardData, 10000);
  return () => clearInterval(interval);
}, []);
```

**자동 업데이트 대상**:
- ✅ Node Status (L1/L2 블록 번호)
- ✅ Rollup Info
- ✅ Operator Info
- ✅ Validators
- ✅ Games
- ✅ System Params
- ✅ L2 Info

**수동 업데이트 필요**:
- ⚠️ Seigniorage Info (Layer2 선택 후 호출)
- ⚠️ User Balances (지갑 연결/트랜잭션 후)

---

## ⚠️ 알려진 제한사항

### 1. 접근 불가능한 메뉴
다음 기능은 구현되어 있지만 UI 메뉴에서 접근할 수 없습니다:
- ❌ **Seigniorage 탭** - activeTab 조건 누락
- ❌ **Balances 탭** - activeTab 조건 누락

### 2. 미완성 기능
- ⚠️ **L2 Withdraw** - L2 지갑 자동 전환 미구현
- ⚠️ **Seigniorage Claim** - UI 버튼 없음 (조회만 가능)

### 3. 사용 조건
- ✅ **Staking**: CandidateAddOn 필요 (Operator 등록 후)
- ✅ **Bridge**: L2 네트워크 정상 작동 필요
- ✅ **Validators**: RAT 컨트랙트 정상 작동 필요

---

## 다음 단계

- **[문제 해결](./troubleshooting.md)** - 일반적인 문제 및 해결 방법
- **[시작하기](./getting-started.md)** - 설치 및 실행 가이드

---

## 📞 도움말

기능 사용 중 문제가 발생하면:
1. 브라우저 개발자 도구의 Console 확인
2. [문제 해결](./troubleshooting.md) 문서 확인
3. GitHub Issues에 문의
