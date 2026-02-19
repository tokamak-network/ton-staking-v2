# 🚀 새로운 Front Demo 구축 계획

## 1. 현재 분석

### 📊 현재 아키텍처 (기존 방식)

```
┌─────────────┐      ┌──────────────┐      ┌─────────────────┐
│   Frontend  │ ──▶  │  demo-backend │ ──▶ │  bash 스크립트  │
│  (Next.js)  │      │  (Express)    │      │ (Hardhat test) │
└─────────────┘      └──────────────┘      └─────────────────┘
```

**동작 방식:**
1. 사용자가 시나리오 선택 → `POST /api/demo/start`
2. `demo-backend`가 `scripts/demo/run-two-challengers.sh` 실행
3. Bash 스크립트가 Hardhat 테스트 실행
4. 테스트 완료 후 로그를 Frontend로 반환

**한계점:**
- ❌ 테스트가 **이미 세팅된 상태**에서 시작 (DisputeGame이 이미 생성済み)
- ❌ Challenger들이 **어떻게 참여**하는지 보여주지 않음
- ❌ Proposer → Challenger攻防 과정 전체를 시각화하지 않음
- ❌ 정적 시나리오만 가능 (동적 파라미터 변경 불가)

---

## 2. 원하는 새로운 데모

**핵심 목표:**  
> "DisputeGame이 생성되는 순간부터 → Challenger들이 참여해서 승리하기까지 → Slashing/보상 분배까지" **전체 플로우를 시각화**

### 🎯 새로운 데모에서 테스트할 내용

| 순서 | 단계 | 설명 |
|------|------|------|
| 1 | **Game 생성** | FaultDisputeGame이 생성되고 root claim이 등록됨 |
| 2 | **Proposer 활동** | Proposer가 block 제안 (challenge할 만한 잘못된 block) |
| 3 | **Challenger 참여** | Challenger들이 challenge提出 (了自己的利益的) |
| 4 | **攻防 진행** | Claim tree 확장, chess clock 진행 |
| 5 | **승자 결정** | 한 명의 Challenger가 최종 승리 |
| 6 | **Slashing** | 패배자의 bond가 슬래싱되고 보상 분배 |
| 7 | **보상 수령** | 승리자가 보상(WTON) 수령 |

---

## 3. 개발 가능성 분석

### ✅ 가능한 이유

1. **OP Stack 친화적 구조**: 이미 FaultDisputeGame, SeigManager 등 핵심 컨트랙트 존재
2. **이벤트 기반 가능**: `FaultDisputeGame`의 이벤트 (`ClaimAdded`, `GameResolved` 등) 활용
3. **Hardhat/Foundry 연동**: 기존 `demo-backend`가 이미 bash로 테스트 실행 가능
4. **UI 기반**: Next.js + Express로 실시간 상태 표시 가능

### ⚠️ 해결해야 할 기술적 과제

| 과제 | 해결 방안 |
|------|-----------|
| **Blochain 시간同步** | WebSocket으로 block/이벤트 리스닝 |
| **다중账户 동시 조작** | 여러 개의 wallet instances 생성 (ethers.js) |
| **게임 로직 구현** | Mock 또는 실제 VM (Cannon/Asterisc) 연동 |
| **실시간 UI 업데이트** | Server-Sent Events (SSE) 또는 WebSocket |

---

## 4. 구현 계획 (3단계)

### Phase 1:基础 구축 (1-2주)
```
📁 new-demo-backend/
├── src/
│   ├── services/
│   │   ├── gameLifecycle.ts      # DisputeGame 생성~종료 관리
│   │   ├── challengerAgent.ts    # Challenger 행위자 시뮬레이션
│   │   ├── proposerAgent.ts      # Proposer 행위자
│   │   └── eventWatcher.ts       # Blockchain 이벤트 리스너
│   ├── services/gameRunner.ts    # 전체 게임 오케스트레이션
│   └── types.ts                  # 새로운 타입 정의
```

**주요 기능:**
- `FaultDisputeGameFactory`를 통한 게임 생성
- 여러 wallet으로 Challenger들 조작
- 블록체인 이벤트 리스닝 (ethers.js Filter)

### Phase 2: Backend API 확장 (1주)
```
📁 new-demo-backend/src/routes/
├── gameRoutes.ts     # POST /api/game/create, /api/game/status
├── agentRoutes.ts    # POST /api/agent/:id/challenge
└── eventRoutes.ts    # SSE /api/events/:gameId
```

**API 设计:**
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/game/create` | 새로운 DisputeGame 생성 |
| GET | `/api/game/:id/status` | 게임 상태 조회 (claims, clock, participants) |
| POST | `/api/agent/:id/challenge` | Challenger가 challenge 提出 |
| POST | `/api/agent/:id/move` | Challenger가 다음 수 저장 |
| GET | `/api/game/:id/events` | Server-Sent Events로 실시간 업데이트 |

### Phase 3: Frontend 시각화 (1-2주)
```
📁 new-demo-frontend/
├── src/
│   ├── pages/demo/
│   │   ├── index.tsx         # 새 데모 메인 페이지
│   │   ├── game-board.tsx    # DisputeGame 시각화 (Tree)
│   │   └── timeline.tsx      # 타임라인 (攻防 과정)
│   ├── components/
│   │   ├── ClaimTree.tsx     # Claim Tree 시각화
│   │   ├── AgentPanel.tsx    # Challenger 목록 및 상태
│   │   ├── GameClock.tsx     # Chess clock 표시
│   │   └── RewardPanel.tsx   # 보상 분배 결과
│   └── hooks/
│       ├── useGameEvents.ts  # SSE 리스닝
│       └── useAgentActions.ts # Challenger 조작
```

**UI 구성:**
```
┌─────────────────────────────────────────────────────┐
│  🕹️ New Slashing Demo                               │
├──────────────┬──────────────────────┬───────────────┤
│  Game Info   │   Claim Tree         │  Agents       │
│  - Status    │   (Visualization)    │  - Challenger │
│  - Block#    │   - Claims           │  - Proposer   │
│  - Clock     │   - Moves            │  - Bond       │
├──────────────┴──────────────────────┴───────────────┤
│  📜 Timeline / Logs                                  │
│  - Challenge 1 by Challenger A at block 12345       │
│  - Challenge 2 by Challenger B at block 12346       │
│  - Game Resolved! Winner: Challenger A              │
├─────────────────────────────────────────────────────┤
│  🎁 Reward Distribution                             │
│  - Winner: 0xA... (+15 WTON)                        │
│  - Loser: 0xB... (Slashed -10 WTON)                │
└─────────────────────────────────────────────────────┘
```

---

## 5. 기술 스택

| 구분 | 기술 |
|------|------|
| **Blockchain** | Hardhat (로컬) + ethers.js v6 |
| **Backend** | Express + TypeScript |
| **실시간 통신** | Server-Sent Events (SSE) |
| **Frontend** | Next.js + React + Tailwind CSS |
| **시각화** | D3.js 또는 React Flow (Tree) |

---

## 6. 테스트 시나리오 예시

### Scenario 1: "Single Challenger Win"
1. Proposer가 잘못된 output root 제안
2. Challenger A가 challenge 提出
3. Challenger A가 최종 승리 → 보상 수령

### Scenario 2: "Multi-Challenger Race"
1. Proposer가 잘못된 block 제안
2. Challenger A, B, C가 동시에 참여
3. B가 더 나은 전략으로 승리 → 보상 수령
4. A, C는 패배 → bond 슬래싱

### Scenario 3: "Proposer Defends"
1. Proposer가 정확한 output root 제안
2. Challenger가 잘못된 challenge 提出
3. Proposer가 방어 성공 → Challenger bond 슬래싱

---

## 7. 마일스톤

| 마일스톤 | 내용 | 예상 기간 |
|----------|------|-----------|
| M1 | 게임 생성 + 이벤트 리스닝 기초 | 1주 |
| M2 | 다중 Challenger 행위자 시뮬레이션 | 1주 |
| M3 | Backend API + SSE 완성 | 1주 |
| M4 | Frontend 시각화 (Tree, Timeline) | 1주 |
| M5 | 보상 분매 시각화 + 테스트 | 1주 |
| **Total** | **완전한 데모 구축** | **5주** |

---

## 8. 우선 실행 항목 ( Immediate Actions)

1. **Proof of Concept**: Hardhat으로 DisputeGame 생성 + 이벤트 확인
2. **단일 Challenger로 테스트**: Proposer → Challenger 1인칭 → 승리 → 보상
3. **UI 프로토타입**: Claim Tree 시각화

---

📌 **이 계획으로 진행할까요?**  
확인하시면 Phase 1부터 코드 작성 시작하겠습니다.

---
*문서 작성일: 2025-04-05*
*문서 버전: v1.0*