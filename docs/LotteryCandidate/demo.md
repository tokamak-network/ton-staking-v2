# LotteryCandidate 프론트엔드 데모 가이드

## 개요

이 데모는 LotteryCandidate 스마트 컨트랙트를 로컬 Anvil 네트워크에 배포하고, React 기반 웹 인터페이스를 통해 실시간으로 로또 참가, 당첨, 시뇨리지 분배를 체험할 수 있는 환경을 제공합니다.

**기술 스택**:
- **백엔드**: Solidity + Foundry (Forge, Anvil)
- **프론트엔드**: React + Vite + TypeScript + TailwindCSS
- **Web3 라이브러리**: Viem + Wagmi
- **네트워크**: Anvil (로컬 Ethereum 네트워크)

## 사전 요구사항

### 1. Foundry 설치

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

확인:
```bash
forge --version
anvil --version
```

### 2. Node.js 설치 (v18 이상)

```bash
node --version
npm --version
```

### 3. MetaMask 브라우저 확장 프로그램

Chrome, Brave, Firefox 등에서 [MetaMask](https://metamask.io/) 설치

## 빠른 시작

### 원클릭 실행

프로젝트 루트 디렉토리에서:

```bash
chmod +x run-lottery-demo.sh
./run-lottery-demo.sh
```

이 스크립트는 다음을 자동으로 수행합니다:
1. ✅ Anvil 네트워크 시작 (localhost:8545, block-time: 1s)
2. ✅ LotteryCandidate 컨트랙트 배포
3. ✅ 시뇨리지 초기화 (First-call trap 해결을 위한 자동 호출)
4. ✅ 프론트엔드 의존성 설치
5. ✅ 개발 서버 시작 (localhost:5173)

### 실행 결과

스크립트가 성공적으로 실행되면 다음과 같은 정보가 출력됩니다:

```
============================
🎉 Demo is ready!
============================

Step 2.5: Initializing seigniorage...
Seigniorage initialized (startBlock set)

Frontend: http://localhost:5173
...
```

============================
🎉 Demo is ready!
============================

Frontend: http://localhost:5173
Anvil RPC: http://localhost:8545

Test Accounts (import to MetaMask):
  Operator: 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
  User1:    0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
  User2:    0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6
  User3:    0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a

Configuration JSON for frontend:
{
  "ton": "0x...",
  "wton": "0x...",
  "lotteryCandidate": "0x...",
  ...
}
```

## MetaMask 설정

### 1. 로컬 네트워크 추가

MetaMask 열기 → 네트워크 선택 → "네트워크 추가" → "네트워크 수동 추가"

| 항목 | 값 |
|------|-----|
| Network Name | `Anvil Local` |
| RPC URL | `http://localhost:8545` |
| Chain ID | `31337` |
| Currency Symbol | `ETH` |

### 2. 테스트 계정 가져오기

MetaMask → 계정 아이콘 → "계정 가져오기" → 프라이빗 키 입력

**테스트 계정 목록**:

| 역할 | 주소 | 프라이빗 키 | 초기 잔액 |
|------|------|------------|-----------|
| **Operator** | `0x70997970C51812dc3A010C7d01b50e0d17dc79C8` | `0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d` | 1000 TON + 1001 TON (예치됨) |
| **User1** | `0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC` | `0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a` | 1000 TON |
| **User2** | `0x90F79bf6EB2c4f870365E785982E1f101E93b906` | `0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6` | 1000 TON |
| **User3** | `0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65` | `0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a` | 1000 TON |

> **주의**: 이 프라이빗 키는 **로컬 테스트 전용**입니다. 실제 자금을 절대 보내지 마세요.

## 프론트엔드 사용법

### Step 1: 브라우저 접속

http://localhost:5173 접속

### Step 2: 컨트랙트 주소 설정

1. 우측 상단 "⚙️ Config" 버튼 클릭
2. 배포 스크립트에서 출력된 JSON 복사 (DEPLOYMENT_JSON_START ~ END 사이)
3. 텍스트 영역에 붙여넣기
4. "Save Config" 클릭

예시 JSON:
```json
{
  "ton": "0x5FbDB2315678afecb367f032d93F642f64180aa3",
  "wton": "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
  "lotteryCandidate": "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0",
  "operator": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
}
```

### Step 3: 지갑 연결

1. "Connect Wallet" 버튼 클릭
2. MetaMask 팝업에서 계정 선택 (User1 권장)
3. "연결" 클릭

## UI 컴포넌트 가이드

### 🎰 Lottery Info (좌측 상단)
현재 로또 상태를 실시간으로 표시합니다.

- **Current Round**: 현재 라운드 번호
- **Prize Pool**: 현재 라운드 누적 상금
- **Entry Fee**: 참가 비용 (기본 10 TON)
- **Participants**: 현재 라운드 참가자 수
- **Your Status**: 사용자의 참가 여부 (✅ Entered / Not Entered)

### 💰 Your Balance (우측 상단)
사용자의 토큰 잔액을 표시합니다.

- **TON (Wallet)**: 지갑 내 TON 잔액
- **WTON (Wallet)**: 지갑 내 WTON 잔액
- **Deposited in Lottery**: LotteryCandidate에 예치된 잔액 (로또 참가 및 출금 가능)

### 📥 Deposit TON (좌측 중앙)
TON을 LotteryCandidate에 예치합니다.

**사용법**:
1. 금액 입력 또는 프리셋 버튼 클릭 (10, 50, 100 TON)
2. "Deposit" 버튼 클릭
3. **1차**: MetaMask에서 Approve 트랜잭션 승인 (LotteryCandidate가 TON 사용 권한 획득)
4. **2차**: MetaMask에서 Deposit 트랜잭션 승인 (실제 예치)

> **참고**: TON은 자동으로 WTON으로 변환됩니다 (1 TON = 1e9 WTON)

### 🎯 Lottery Actions (우측 중앙)

**일반 사용자**:
- **Enter Lottery**: 로또 참가 (Entry Fee 차감)
  - 조건: Deposited 잔액 ≥ Entry Fee (10 TON)
  - 라운드당 1회만 참가 가능

**Operator 전용** (👑 아이콘 표시):
- **Draw Winner**: 당첨자 추첨
  - 조건: 참가자가 1명 이상
  - 무작위로 당첨자 선정, Prize Pool 전액 지급
  - 자동으로 다음 라운드로 진행

### 📈 Seigniorage Distribution (우측 하단)

시뇨리지 분배 정보 및 청구 기능을 제공합니다.

- **Total Deposited (Pool)**: 전체 예치 풀 (WTON 단위 및 Raw BigInt 값 표시)
- **Your Share**: 사용자의 점유율 (%)
- **Claim Seigniorage**: 시뇨리지 청구 버튼
  - 클릭 시 `updateSeigniorage()` 호출
  - 성공 시 받은 시뇨리지 양을 과학적 표기법으로 상세 표시 (예: `+1.9405e-7 WTON`)
  - 데이터 자동 갱신 (Refetch) 지원

### ⚡ Dev Tools: Advance Blocks

로컬 환경(Anvil)에서 시뇨리지를 빠르게 생성하기 위한 도구입니다.

- **Mine 버튼**: 지정된 수만큼 블록을 즉시 생성합니다.
- 시뇨리지는 블록 수에 비례하여 발생하므로, "Claim Seigniorage" 클릭 전 최소 100블록 이상 마이닝하는 것을 권장합니다.

### 📜 Past Rounds (좌측 하단)

과거 라운드 히스토리를 표시합니다.

- 라운드 번호
- 참가자 수
- 당첨자 주소
- 상금 금액

## 데모 시나리오

### 시나리오 1: 기본 로또 플로우

**목표**: 2명의 사용자가 로또에 참가하고, Operator가 당첨자를 추첨합니다.

#### Step 1: User1 예치 및 참가

1. MetaMask에서 **User1** 계정으로 전환
2. Frontend 새로고침 (F5)
3. "Connect Wallet" 클릭
4. **Deposit TON**: `50` 입력 → "Deposit" → Approve → Deposit 승인
5. 잔액 확인: "Deposited in Lottery"에 50 TON 표시
6. **Enter Lottery** 클릭 → MetaMask 승인
7. 상태 확인: "Your Status" → "✅ Entered"
8. Prize Pool: 10 TON 증가 확인

#### Step 2: User2 예치 및 참가

1. MetaMask에서 **User2** 계정으로 전환
2. Frontend 새로고침 (F5)
3. "Connect Wallet" 클릭
4. **Deposit TON**: `50` 입력 → Deposit 프로세스 진행
5. **Enter Lottery** 클릭 → 승인
6. Participants: 2명 확인
7. Prize Pool: 20 TON 확인

#### Step 3: Operator가 당첨자 추첨

1. MetaMask에서 **Operator** 계정으로 전환
2. Frontend 새로고침 (F5)
3. "Connect Wallet" 클릭
4. 화면에 "👑 Operator Controls" 섹션 표시 확인
5. **Draw Winner** 버튼 클릭 → 승인
6. 결과 확인:
   - "✅ Winner has been drawn!" 메시지 표시
   - Current Round: 2로 증가
   - Past Rounds에 Round #1 표시
   - 당첨자 주소와 상금(20 TON) 표시

#### Step 4: 당첨 확인

1. MetaMask를 당첨자 계정으로 전환
2. Frontend 새로고침
3. "Your Balance" → "Deposited in Lottery" 확인
   - 당첨자: 40 TON + 20 TON (상금) = 60 TON
   - 낙첨자: 50 TON - 10 TON (Entry Fee) = 40 TON

### 시나리오 2: 시뇨리지 분배 테스트

**목표**: 여러 사용자가 예치한 상태에서 시뇨리지를 분배받습니다.

#### Step 1: 다수 사용자 예치

1. **User1**: 100 TON 예치
2. **User2**: 200 TON 예치  
3. **User3**: 300 TON 예치

결과: Total Deposited = 600 TON (+ Operator 1001 TON = 1601 TON)

#### Step 2: 시뇨리지 분배

1. 아무 계정으로 로그인
2. **Seigniorage Distribution** 섹션 확인
3. "Your Share" 확인:
   - User1: ~6.2% (100/1601)
   - User2: ~12.5% (200/1601)
   - User3: ~18.7% (300/1601)
   - Operator: ~62.6% (1001/1601)
4. **Claim Seigniorage** 클릭 → 승인
5. 블록 생성 → 시뇨리지 발생
6. "You received: +X WTON" 메시지 확인
7. 각 계정 "Your Balance" 증가 확인

#### Step 3: 비례 분배 검증

시뇨리지가 10 WTON 발생했다고 가정:
- User1: 10 × 6.2% = 0.62 WTON
- User2: 10 × 12.5% = 1.25 WTON
- User3: 10 × 18.7% = 1.87 WTON
- Operator: 10 × 62.6% = 6.26 WTON

각 계정에서 "Refresh" 클릭하여 증가분 확인

### 시나리오 3: 로또 + 시뇨리지 복합

**목표**: 로또 참가와 시뇨리지 분배가 동시에 작동하는 것을 확인합니다.

#### Step 1: 초기 상태

- User1: 100 TON 예치
- User2: 100 TON 예치

#### Step 2: Round 1

1. User1, User2 모두 로또 참가
2. Entry Fee 차감 → 각 90 TON 잔액
3. Prize Pool: 20 TON

#### Step 3: 시뇨리지 청구 (Round 1 진행 중)

1. "Claim Seigniorage" 실행
2. 분배 기준: 90 TON : 90 TON (1:1)
3. 시뇨리지 10 WTON 발생 시 → 각 5 WTON 수령
4. 새 잔액: User1 95 TON, User2 95 TON

#### Step 4: 당첨자 추첨

1. Operator가 Draw Winner 실행
2. 당첨자(예: User1): 95 + 20 = 115 TON
3. 낙첨자(User2): 95 TON 유지

#### 결과 분석

- **당첨자**: Entry Fee 손실(-10) + 상금(+20) + 시뇨리지(+5) = **순이익 +15 TON**
- **낙첨자**: Entry Fee 손실(-10) + 시뇨리지(+5) = **순손실 -5 TON**

## 수동 실행 (단계별)

자동 스크립트를 사용하지 않고 수동으로 실행하려면:

### Terminal 1: Anvil 시작

```bash
anvil --host 0.0.0.0 --port 8545 --chain-id 31337
```

실행 유지

### Terminal 2: 컨트랙트 배포

```bash
forge script script/DeployLotteryDemo.s.sol:DeployLotteryDemo \
  --rpc-url http://localhost:8545 \
  --broadcast \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

출력에서 `DEPLOYMENT_JSON_START` ~ `DEPLOYMENT_JSON_END` 사이 JSON 복사

### Terminal 3: 프론트엔드 시작

```bash
cd demo-frontend
npm install
npm run dev
```

브라우저에서 http://localhost:5173 접속

## 트러블슈팅

### 문제: "Connect Wallet" 버튼 무반응

**원인**: MetaMask 미설치 또는 권한 문제

**해결**:
1. MetaMask 설치 확인
2. 브라우저 확장 프로그램 권한 확인
3. 페이지 새로고침 (F5)
4. 브라우저 콘솔 (F12) 에러 확인

### 문제: "Failed to fetch" 네트워크 에러

**원인**: Anvil이 실행되지 않았거나 RPC URL 불일치

**해결**:
```bash
ps aux | grep anvil
```

프로세스 확인 후 없으면 재시작:
```bash
anvil --host 0.0.0.0 --port 8545 --chain-id 31337
```

MetaMask 네트워크 설정에서 RPC URL이 `http://localhost:8545`인지 확인

### 문제: 트랜잭션 실패 (Transaction failed)

**원인 1**: 잔액 부족

**해결**: 
- TON 잔액 확인 (최소 10 TON 필요)
- 먼저 Deposit 실행

**원인 2**: Nonce 불일치

**해결**:
1. MetaMask → 설정 → 고급 → "계정 재설정" 클릭
2. Anvil 재시작
3. 컨트랙트 재배포

**원인 3**: Gas 부족

**해결**: Anvil은 무한 ETH 제공하므로 발생하지 않음. 다른 원인 확인

### 문제: "Insufficient balance" 에러 (로또 참가 시)

**원인**: Deposited 잔액 < Entry Fee (10 TON)

**해결**:
1. "Your Balance" → "Deposited in Lottery" 확인
2. 부족하면 "Deposit TON"으로 추가 예치
3. 최소 10 TON 예치 필요

### 문제: Approve 후 Deposit 자동 진행 안 됨

**원인**: React state 업데이트 타이밍 문제

**해결**:
1. Approve 승인 후 5초 대기
2. "Deposit" 버튼 다시 클릭
3. 이미 Approve되어 바로 Deposit 진행

### 문제: npm install 실패

**원인**: Node.js 버전 또는 의존성 충돌

**해결**:
```bash
cd demo-frontend
rm -rf node_modules package-lock.json
npm cache clean --force
npm install
```

Node.js 버전 확인:
```bash
node --version
```

18.0.0 이상 필요. 낮으면 업그레이드:
```bash
nvm install 18
nvm use 18
```

### 문제: 데모 실행 후 Anvil이 종료되지 않음

**원인**: 백그라운드 프로세스로 실행

**해결**:
```bash
pkill -f anvil
```

또는:
```bash
ps aux | grep anvil
kill -9 [PID]
```

## 프로젝트 구조

```
ton-staking-v2/
├── script/
│   └── DeployLotteryDemo.s.sol           # 배포 스크립트
├── src/
│   └── dao/
│       ├── LotteryCandidate.sol          # 메인 컨트랙트
│       ├── LotteryCandidateStorage.sol   # Storage 구조
│       ├── LotteryCandidateProxy.sol     # Proxy 패턴
│       └── factory/
│           ├── LotteryCandidateFactory.sol
│           └── LotteryCandidateFactoryStorage.sol
├── demo-frontend/                         # React 프론트엔드
│   ├── src/
│   │   ├── main.tsx                      # 진입점
│   │   ├── App.tsx                       # 메인 앱
│   │   ├── wagmi.ts                      # Web3 설정
│   │   ├── components/                   # UI 컴포넌트
│   │   │   ├── ConnectWallet.tsx
│   │   │   ├── LotteryInfo.tsx
│   │   │   ├── UserBalance.tsx
│   │   │   ├── DepositForm.tsx
│   │   │   ├── LotteryActions.tsx
│   │   │   ├── SeignioragePanel.tsx
│   │   │   └── PastRounds.tsx
│   │   └── contracts/                    # ABI & 주소
│   │       ├── abi.ts
│   │       └── addresses.ts
│   ├── package.json
│   ├── vite.config.ts
│   ├── tailwind.config.js
│   └── tsconfig.json
├── run-lottery-demo.sh                   # 원클릭 실행 스크립트
└── docs/
    └── LotteryCandidate/
        ├── README.md                     # LotteryCandidate 개요
        ├── contracts.md                  # 컨트랙트 구조
        ├── scenario.md                   # 사용 시나리오
        └── demo.md                       # 이 문서
```

## 기술 상세

### 스마트 컨트랙트

- **언어**: Solidity 0.8.4
- **프레임워크**: Foundry (Forge, Anvil)
- **패턴**: Proxy 패턴 (업그레이드 가능)
- **토큰**: ERC20 (TON, WTON)

### 프론트엔드

- **프레임워크**: React 18 + Vite
- **언어**: TypeScript
- **스타일링**: TailwindCSS
- **Web3 라이브러리**:
  - **Viem**: 저수준 Ethereum 상호작용
  - **Wagmi**: React hooks for Ethereum
  - **TanStack Query**: 데이터 캐싱 및 상태 관리

### 네트워크

- **Anvil**: 로컬 Ethereum 개발 네트워크
- **Chain ID**: 31337
- **블록 생성**: 즉시 (트랜잭션 수신 시)
- **계정**: 10개 사전 펀딩 계정 (각 10000 ETH)

## 추가 학습 자료

- [LotteryCandidate 개요](./README.md)
- [컨트랙트 구조 상세](./contracts.md)
- [사용 시나리오](./scenario.md)
- [Foundry Book](https://book.getfoundry.sh/)
- [Viem Documentation](https://viem.sh)
- [Wagmi Documentation](https://wagmi.sh)
- [TailwindCSS](https://tailwindcss.com/)

## 다음 단계

1. **실제 테스트넷 배포**: Sepolia 또는 Holesky 테스트넷에 배포
2. **기능 확장**: 
   - 출금 기능 UI 추가
   - Entry Fee 변경 기능
   - 라운드별 통계 차트
3. **모바일 최적화**: 반응형 디자인 개선
4. **E2E 테스트**: Playwright로 자동화 테스트 작성


## 데모 시나리오 (요약)

### 시나리오: 스테이킹 & 로터리 통합 체험
1. **User1**으로 100 TON 예치.
2. **Enter Lottery** 클릭하여 로또 참여.
3. **Mine** 버튼으로 100블록 생성.
4. **Claim Seigniorage** 클릭하여 네트워크 보상 수령 확인.
5. **Operator** 계정으로 전환하여 **Draw Winner** 실행.
6. 당첨자 계정에서 잔액 증가 확인.