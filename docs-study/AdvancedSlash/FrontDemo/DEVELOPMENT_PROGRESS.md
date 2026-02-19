# 🚀 Interactive Challenger Demo - 개발 현황

**옵션 1: 선택형 Challenger (Simplified Challenger)** 구현 진행 상황

*생성일: 2025-04-05*
*마지막 업데이트: 2025-04-05*

---

## 📋 목차

1. [현재 상황](#현재-상황)
2. [완료된 개발](#완료된-개발)
3. [백엔드 상세](#백엔드-상세)
4. [프론트엔드 상세](#프론트엔드-상세)
5. [실행 방법](#실행-방법)
6. [문제 해결](#문제-해결)

---

## 현재 상황

### ✅ 완료
- [x] demo-backend2 폴더 구조 설계
- [x] 백엔드 핵심 기능 구현 (100%)
- [x] Option 1 로직 구현 (ChallengerAssistant)
- [x] API 라우트 구현
- [x] 이벤트 리스너 구현
- [x] 환경설정 최적화 (.env 없이도 작동)
- [x] demo-frontend2 폴더 구조 설계
- [x] 프론트엔드 핵심 기능 구현 (100%)
- [x] UI 컴포넌트 개발
- [x] 게임 상태 관리 훅
- [x] API 연동

### ✅ 전체 완료
- [x] **프로젝트 완성** (백엔드 + 프론트엔드)

---

## 완료된 개발

### 📁 전체 프로젝트 구조

```
ton-staking-v2/
├── scripts/demo/                    # 기존 (변경 없음)
│   ├── devnet-up.sh
│   └── run-*.sh
│
├── demo-backend/                    # 기존 (변경 없음) - 포트 3000
│   └── src/
│
├── demo-backend2/                   # 새 백엔드 - 포트 3001
│   ├── package.json
│   ├── tsconfig.json
│   ├── .env.example
│   ├── README.md
│   └── src/
│       ├── index.ts
│       ├── config.ts
│       ├── types.ts
│       ├── routes/
│       │   └── interactiveRoutes.ts
│       ├── services/
│       │   ├── contractService.ts
│       │   ├── challengerAssistant.ts
│       │   ├── eventWatcher.ts
│       │   └── interactiveGameRunner.ts
│       └── utils/
│           └── ethers.ts
│
└── demo-frontend2/                  # 새 프론트엔드 - 포트 3002
    ├── package.json
    ├── tsconfig.json
    ├── next.config.js
    ├── tailwind.config.ts
    ├── postcss.config.js
    ├── .env.local
    ├── README.md
    └── src/
        ├── pages/
        │   ├── _app.tsx
        │   └── index.tsx
        ├── components/
        │   ├── GameInfoPanel.tsx
        │   ├── MoveSelectionPanel.tsx
        │   ├── RewardPanel.tsx
        │   └── GameLogPanel.tsx
        ├── hooks/
        │   └── useInteractiveGame.ts
        ├── lib/
        │   └── interactiveApi.ts
        └── styles/
            └── globals.css
```

---

## 백엔드 상세

### 🏗️ 시스템 구조

```
┌──────────────┐
│                    demo-frontend2 (Next.js)              │
│            Port: 3002                                      │
└──────────────┘
                          ▲
                          │ HTTP
                          │
┌──────────────┐
│              demo-backend2 (Express)                     │
│            Port: 3001                                      │
│                                                            │
│ ┌──────────────┐   │
│  │  API Routes                                           │   │
│  │  • POST /api/game/create                            │   │
│  │  • GET  /api/game/:id/status                        │   │
│  │  • GET  /api/game/:id/moves                         │   │
│  │  • POST /api/game/:id/move/submit                    │   │
│  │  • POST /api/game/:id/resolve                        │   │
│  │  • GET  /api/game/:id/events (SSE)                    │   │
│ └──────────────┘   │
│                          ▲                                 │
│                          │                                 │
│ ┌──────────────┐   │
│  │  Services                                             │   │
│  │                                                        │   │
│  │ ┌──────────────┐   │   │
│  │  │ InteractiveGameRunner                       │   │   │
│  │  │ - 게임 생성, 진행, 종료 관리                     │   │   │
│  │  │ - 게임 상태 저장                                 │   │   │
│  │ └──────────────┬───────────┘   │   │
│  │                       │                               │   │
│  │ ┌──────────────▼───────────┐   │   │
│  │  │ ChallengerAssistant ⭐ 핵심               │   │   │
│  │  │ - 옵션 1: 올바른 move 계산                      │   │   │
│  │  │ - 사용자가 VM 실행 안 해도 됨                     │   │   │
│  │  │ - 전략적 힌트 제공                               │   │   │
│  │ └──────────────┬───────────┘   │   │
│  │                       │                               │   │
│  │ ┌──────────────▼───────────┐   │   │
│  │  │ ContractService                               │   │   │
│  │  │ - 블록체인 컨트랙트 호출                           │   │   │
│  │  │ - 트랜잭션 서명 및 전송                           │   │   │
│  │ └──────────────┬───────────┘   │   │
│  │                       │                               │   │
│  │ ┌──────────────▼───────────┐   │   │
│  │  │ EventWatcher                                │   │   │
│  │  │ - 블록체인 이벤트 리스닝                           │   │   │
│  │  │ - 실시간 업데이트                                  │   │   │
│  │ └──────────────┘   │   │
│ └──────────────┘   │
└──────────────┘
                          ▲
                          │ RPC (ethers.js)
                          │
┌──────────────┐
│              Hardhat Network (localhost:8545)                │
│                                                            │
│  • FaultDisputeGame                                         │
│  • FaultDisputeGameFactory                                 │
│  • SeigManager_Slashing                                     │
│  • WinningChallengerTracker                                 │
└──────────────┘
```

---

### 📡 API 엔드포인트 상세

| Method | Endpoint | Request Body | Response | 설명 |
|--------|----------|--------------|----------|------|
| POST | `/api/game/create` | `{rootBlock, userAddress}` | `{game}` | 새로운 DisputeGame 생성 |
| GET | `/api/game/:id/status` | - | `{game}` | 게임 상태 조회 |
| GET | `/api/game/:id/moves` | `?userAddress=...` | `{moves}` | 현재 가능한 move 목록 |
| POST | `/api/game/:id/move/submit` | `{moveId, userAddress}` | `{claimId}` | 선택한 move 제출 |
| POST | `/api/game/:id/resolve` | - | `{reward}` | 게임 종료 & 보상 분배 |
| GET | `/api/game/:id/events` | - | SSE Stream | 실시간 이벤트 스트림 |

---

### ⭐ 핵심 컴포넌트: ChallengerAssistant

```typescript
class ChallengerAssistant {
  /**
   * 현재 게임 상태에서 가능한 모든 유효한 move 계산
   * 옵션 1 특징:
   * - 사용자가 복잡한 VM 실행을 하지 않음
   * - 데모가 미리 계산한 올바른 move를 제공
   * - 사용자는 전략적 선택만 함
   */
  async getValidMoves(game: Game, userAddress: string): Promise<ValidMove[]>
}
```

**기능:**
- ✅ 가능한 공격 move 계산
- ✅ 가능한 방어 move 계산
- ✅ VM 실행 결과 시뮬레이션 (간소화)
- ✅ 전략적 힌트 제공
- ✅ 리스크 레벨 부여 (low/medium/high)
- ✅ 좋은 move 순으로 정렬

---

## 프론트엔드 상세

### 🎨 아키텍처

```
┌──────────────┐
│      demo-frontend2 (Next.js)    │
│                                 │
│ ┌───────────────┐       │
│  │  pages/               │       │
│  │  • _app.tsx           │       │
│  │    - App 컴포넌트     │       │
│  │  • index.tsx (메인)    │       │
│  │    - 메인 페이지       │       │
│ └───────────────┘       │
│                                 │
│ ┌───────────────┐       │
│  │  components/          │       │
│  │                        │       │
│  │  • GameInfoPanel      │       │
│  │    - 게임 ID          │       │
│  │    - 게임 상태         │       │
│  │    - Root Block       │       │
│  │    - Claim 수         │       │
│  │    - 승자 정보         │       │
│  │                        │       │
│  │  • MoveSelectionPanel  │       │
│  │    - move 카드 리스트   │       │
│  │    - 선택 UI          │       │
│  │    - 리스크/전략 표시   │       │
│  │                        │       │
│  │  • RewardPanel         │       │
│  │    - 승리/패배 메시지   │       │
│  │    - 보상 금액         │       │
│  │    - 슬래싱 정보       │       │
│  │                        │       │
│  │  • GameLogPanel        │       │
│  │    - 이벤트 로그       │       │
│  │    - 타임스탬프       │       │
│ └───────────────┘       │
│                                 │
│ ┌───────────────┐       │
│  │  hooks/               │       │
│  │  • useInteractiveGame  │       │
│  │    - 게임 상태 관리     │       │
│  │    - move 선택 관리    │       │
│  │    - API 호출 처리     │       │
│  │    - 주기적 갱신       │       │
│ └───────────────┘       │
│                                 │
│ ┌───────────────┐       │
│  │  lib/                 │       │
│  │  • interactiveApi      │       │
│  │    - createGame()     │       │
│  │    - getGameStatus()  │       │
│  │    - getValidMoves()  │       │
│  │    - submitMove()     │       │
│  │    - resolveGame()     │       │
│ └───────────────┘       │
└──────────────┘
```

---

### 📦 컴포넌트 상세 설명

#### 1. GameInfoPanel.tsx

**기능:** 게임의 전체 상태를 표시

**표시 정보:**
- 게임 ID
- 게임 상태 (IN_PROGRESS / CHALLENGER_WINS / PROPOSER_WINS)
- Root Block Number
- Max Depth
- 현재 Claim 수
- 승자 정보 (게임 종료 시)

**UI 특징:**
- 상태별 색상 구분 (파란색=진행중, 초록색=승리, 빨간색=패배)
- 깔끔한 카드 레이아웃

---

#### 2. MoveSelectionPanel.tsx

**기능:** 사용자가 move를 선택하고 제출할 수 있는 UI

**특징:**
- 유효한 move들을 카드 형태로 표시
- move 타입 (공격 🗡️ / 방어 🛡️) 아이콘
- 리스크 레벨 색상 (초록/노란/빨강)
- 전략적 힌트 표시
- 예상 결과 표시 (✅/❌/❓)
- 선택한 move 하이라이트

**UI 구조:**
```
┌────────┐
│ 당신의 차례!         │
├────────┤
│                      │
│ ┌────────┐ ┌────────┐ │
│ 🗡️ 공격   │ 🛡️ 방어   │
│  Depth 1   │  나의 claim │
│  [중간]   │  [낮음]   │
│ 빠르게... │  안전...  │
│ ✅ Win   │ ✅ Win   │
│ └────────┘ └────────┘ │
│                      │
│ [제출하기]            │
└────────┘
```

---

#### 3. RewardPanel.tsx

**기능:** 보상 분배 결과 표시

**표시 정보:**
- 승리 여부 (🎉 / 😢)
- 승자 주소
- 보상 금액 (WTON)
- 슬래싱된 계정 목록
- 슬래싱된 금액

**UI 특징:**
- 승리시: 녹색 백그라운드, 이모지 🎉
- 패배시: 빨강 백그라운드, 이모지 😢

---

#### 4. GameLogPanel.tsx

**기능:** 게임 이벤트 실시간 로그

**로그 항목:**
- 타임스탬프
- 이벤트 메시지

**추가 예정:**
- 실제 이벤트 연동
- 자동 스크롤
- 로그 필터링

---

### 🪝 useInteractiveGame 훅

**기능:** 게임의 모든 상태를 관리하는 커스텀 훅

**상태 관리:**
```typescript
{
  game: Game | null,          // 게임 전체 정보
  moves: ValidMove[],         // 가능한 move들
  selectedMove: ValidMove | null,  // 선택한 move
  loading: boolean,          // 로딩 상태
  error: string | null,      // 에러 메시지
}
```

**함수:**
- `createGame(rootBlock)` - 게임 생성
- `refreshGame()` - 게임 상태 갱신
- `loadMoves()` - 유효한 move들 로드
- `submitMove()` - move 제출
- `resolveGame()` - 게임 종료

**자동 동작:**
- 5초마다 게임 상태 자동 갱신

---

### 📡 interactiveApi.ts

**기능:** 백엔드 API 호출 함수들

**API 함수:**

| 함수 | 설명 |
|------|------|
| `createGame(rootBlock, userAddress)` | 게임 생성 |
| `getGameStatus(gameId)` | 게임 상태 조회 |
| `getValidMoves(gameId, userAddress)` | 유효한 move들 조회 |
| `submitMove(gameId, moveId, userAddress)` | move 제출 |
| `resolveGame(gameId)` | 게임 종료 |

**타입 정의:**
```typescript
interface Game { ... }
interface ValidMove { ... }
interface CreateGameResponse { ... }
// ... 등
```

---

### 🎨 디자인 시스템

#### Tailwind CSS 설정

**커스텀 색상:**
```css
primary: {
 50: '#eff6ff',
 100: '#dbeafe',
  // ...
 600: '#2563eb',  // 메인 버튼 색상
 700: '#1d4ed8',
}
```

**반응형:**
- 모바일: `grid-cols-1`
- 태블릿: `md:grid-cols-2`
- 데스크탑: `lg:grid-cols-2`

---

### 🔄 페이지 플로우

#### 1. 초기 상태
```
┌──────────────┐
│ 🎮 Interactive Demo │
│                      │
│ [지갑 연결]          │
└──────────────┘
```

---

#### 2. 지갑 연결 후
```
┌──────────────┐
│ 🎮 Interactive Demo │
│ 연결된 지갑: 0x123..│
│                      │
│ ┌──────────┐ │
│  │ 새 게임 시작    │
│  │ Block #: [____]│ │
│  │ [게임 생성]     │
│ └──────────┘ │
└──────────────┘
```

---

#### 3. 게임 진행 중
```
┌────────┐
│ 🎮 Interactive Demo            │
│ 연결된 지갑: 0x123...         │
├────────┤
│                                │
│ ┌────────────┐ ┌────────────┐ │
│  │ 게임 정보   │  │ Move 선택  │
│  │ Status: ...│  │            │
│  │            │  │ ┌────────┐ │
│ └────────────┘  │ 공격   │
│                  │ └────────┘ │
│ ┌────────────┐ │ ┌────────┐ │
│  │ 로그        │  │ 방어   │
│  │            │  │ └────────┘ │
│  │            │  │            │
│ └────────────┘ │ [제출하기]  │
└────────┘
```

---

#### 4. 게임 종료
```
┌────────┐
│ 🎮 Interactive Demo            │
│ 연결된 지갑: 0x123...         │
├────────┤
│                                │
│ ┌───────────┐ │
│  │ 🎉 축하합니다! 승리!     │
│  │ 보상: 15.5 WTON          │
│ └───────────┘ │
│                                │
│  [새로운 게임 시작]            │
└────────┘
```

---

## 실행 방법

### 🚀 완전한 실행 순서

#### 터미널 1: Hardhat Devnet

```bash
bash scripts/demo/devnet-up.sh
```

**출력:** Hardhat 네트워크 실행 + 컨트랙트 배포

---

#### 터미널 2: demo-backend2

```bash
cd demo-backend2
npm install  # 처음 한 번
npm run dev
```

**출력:**
```
============================================================
demo-backend2 - Interactive Challenger
============================================================
Server running on port 3001
Health check: http://localhost:3001/health
API endpoint: http://localhost:3001/api/game

Press Ctrl+C to stop
```

---

#### 터미널 3: demo-frontend2

```bash
cd demo-frontend2
npm install  # 처음 한 번
npm run dev
```

**출력:**
```
▲ Next.js 14.0.4
  - Local:        http://localhost:3002
  - Network:      http://192.168.x:3002

✓ Ready in 2.3s
```

---

#### 브라우저 접속

```
기존 데모:      http://localhost:3000/demo
새 데모:        http://localhost:3002
```

---

## 📡 사용 방법

### 1. 지갑 연결

1. MetaMask 설치
2. "지갑 연결" 버튼 클릭
3. 계정 연결

---

### 2. 게임 생성

1. Root Block Number 입력 (예: 1000)
2. "게임 생성" 버튼 클릭
3. 게임 생성됨

---

### 3. Move 선택

1. 가능한 move들 표시됨
2. move 하나 선택 (공격/방어)
3. "선택한 Move 제출하기" 클릭

---

### 4. 게임 진행

1. 게임이 자동으로 진행됨
2. 상태 주기적 갱신 (5초마다)
3. 필요한 move 제출 반복

---

### 5. 게임 종료

1. 승리 후 "게임 종료 및 보상 분배" 클릭
2. 보상 분배됨
3. 승리/패배 표시

---

### 6. 새 게임

1. "새로운 게임 시작" 버튼 클릭
2. 위 과정 반복

---

## 문제 해결

### ❌ 에러: connection refused

**원인:** devnet 실행 안 됨

**해결:**
```bash
# 먼저 devnet 실행
bash scripts/demo/devnet-up.sh

# 그 다음 backend2, frontend2 실행
```

---

### ❌ 에러: Failed to create game

**원인:** devnet 실행 안 됨

**해결:**
```bash
bash scripts/demo/devnet-up.sh
```

---

### ❌ 에러: Failed to load moves

**원인:** 게임 생성 안 됨

**해결:** 먼저 게임 생성

---

## ✅ 완료된 기능

### 백엔드 (demo-backend2)

- [x] 게임 생성 API
- [x] 게임 상태 조회 API
- [x] 유효한 move들 조회 API
- [x] move 제출 API
- [x] 게임 종료 API
- [x] SSE 실시간 이벤트 스트림
- [x] ChallengerAssistant (옵션 1 핵심)
- [x] ContractService
- [x] EventWatcher
- [x] 환경설정 (.env 없이도 작동)

---

### 프론트엔드 (demo-frontend2)

- [x] 메인 페이지
- [x] 지갑 연결 (MetaMask)
- [x] 게임 생성 UI
- [x] 게임 정보 패널
  - [x] 게임 상태 표시
  - [x] 상태별 색상 구분
  - [x] 승자 정보 표시
- [x] Move 선택 패널
  - [x] move 카드 UI
  - [x] 공격/방어 아이콘
  - [x] 리스크 레벨 표시
  - [x] 전략적 힌트 표시
  - [x] 선택 및 제출 UI
- [x] 보상 패널
  - [x] 승리/패배 메시지
  - [x] 보상 금액 표시
  - [x] 슬래싱 정보 표시
- [x] 로그 패널
  - [x] 이벤트 로그 표시
  - [x] 타임스탬프 표시
- [x] 게임 상태 관리 훅
  - [x] 상태 관리
  - [x] API 호출 처리
  - [x] 주기적 갱신
- [x] API 연동
  - [x] 게임 생성
  - [x] 상태 조회
  - [x] move 조회
  - [x] move 제출
  - [x] 게임 종료
- [x] 반응형 UI

---

## 🎯 옵션 1 특징

### 사용자 경험

- 사용자가 Challenger 역할로 직접 참여
- 전략적 선택 (공격 vs 방어) 가능
- 복잡한 VM 실행은 데모가 처리
- 직관적인 UI

---

### 기술적 접근

- 미리 계산된 올바른 move 제공
- 전략적 힌트와 리스크 레벨 부여
- 사용자는 선택만 하면 됨
- TypeScript로 타입 안전성 확보

---

### 장점

- 기존 코드와 완전히 독립
- 개발 기간 단축
- 사용자 경험 향상
- 올바른 게임 플레이 보장

---

## 📊 기술 스택

| 구분 | 기술 | 버전 |
|------|------|------|
| **Backend** | |
| 런타임 | Node.js | 20.18.2 |
| 프레임워크 | Express | 4.18.2 |
| 언어 | TypeScript | 5.3.0 |
| 블록체인 | ethers.js | 6.9.0 |
| **Frontend** | |
| 프레임워크 | Next.js | 14.0.4 |
| 언어 | TypeScript | 5.3.0 |
| 스타일링 | Tailwind CSS | 3.4.0 |
| 상태 관리 | React Hooks | 18.2.0 |
| **Blockchain** | |
| 네트워크 | Hardhat | devnet |
| 컨트랙트 | Solidity | ^0.8.20 |

---

## 📚 참고 문서

- [옵션 1 상세 계획](./NEW_DEMO_PLAN.md)
- [기존 Demo Backend](../../demo-backend/)
- [Demo Config](../../demo-config/)

---

## 📝 변경 이력

| 날짜 | 변경 사항 |
|------|-----------|
| 2025-04-05 | demo-backend2 백엔드 개발 완료 |
| 2025-04-05 | config.ts 수정 (.env 없이도 작동하도록) |
| 2025-04-05 | demo-frontend2 프론트엔드 개발 완료 |
| 2025-04-05 | 프론트엔드 상세 문서 추가 |

---

## 🎉 완료!

**demo-backend2 + demo-frontend2** 완성되었습니다!

### 실행 명령어 요약

```bash
# 터미널 1
bash scripts/demo/devnet-up.sh

# 터미널 2
cd demo-backend2 && npm run dev

# 터미널 3
cd demo-frontend2 && npm run dev
```

브라우저: http://localhost:3002

---

📌 **질문이나 문제가 있으면 말씀해주세요!**