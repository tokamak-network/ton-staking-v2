# 🎯 Front Demo 아키텍처 및 테스트 전략 문서

이 문서는 `ton-staking-v2` 프로젝트의 **Slashing 메커니즘을 시각화한 프론트 데모**의 구성, 동작 흐름, 테스트 목적을 설명하며, 향후 개선 방향을 제안합니다.

---

## 1. 개요

### 목적
- **Slashing 메커니즘**(특히 다중 챌린저, 보상 분배)을 시각적으로 검증하고 이해하기 위함
- 실제 Fault Dispute Game에서의 **Winning Challenger 추적**, **보상 분배 로직**, **다중 참가자 간 상호작용**을 시뮬레이션
- 팀 내/외부 스테이크홀더, 검증인, 개발자 대상으로 **메커니즘 신뢰성 증진**

---

## 2. 아키텍처 구성

### 📁 폴더 구조
```
demo-frontend/
├── src/pages/_app.tsx         → Next.js 앱 진입점
demo-backend/
├── src/
│   ├── routes/demoRoutes.ts   → 데모 시나리오 실행 엔드포인트
│   ├── services/demoRunner.ts → 데모 로직 실행 및 상태 관리
│   └── services/demoStore.ts  → 데모 상태 저장소
demo-config/
├── scenarios.json             → 데모 시나리오 정의 (예: 2명 챌린저 등록)
├── challengers.json           → 챌린저 정보 (주소, 전략 등)
├── networks.json              → Devnet/L1/L2 네트워크 설정
└── abis/                      → 컨트랙트 ABI (DisputeGame, SeigManager 등)
```

### 🔗 통신 흐름
```
[Frontend UI] 
    → (HTTP) → [Backend API (demo-backend)] 
        → (Hardhat/Forge/Ethers.js) → [Devnet (Hardhat 또는 OP Stack Devnet)]
            → (Contract Call) → [FaultDisputeGame, SeigManager_Slashing, WinningChallengerTracker]
```

---

## 3. 핵심 기능 요소

| 요소 | 설명 |
|------|------|
| **시나리오 기반 실행** | `scenarios.json`에서 정의된 시나리오(예: 2명 챌린저가 서로 다른 시점에 참여)를 순차적으로 실행 |
| **실시간 상태 갱신** | Dispute Game 상태(claim tree, turn), 보상 풀, 챌린저 참여 여부 등을 UI에 반영 |
| **다중 챌린저 시뮬레이션** | 두 명 이상의 챌린저가 서로 다른 전략으로 참여하고, 최종 승리자(Winning Challenger)가 결정됨 |
| **보상 분배 시각화** | `SeigManager_Slashing`이 슬래싱된 보상 토큰을 어떻게 분배하는지 보여줌 (예: 승리자에게 10% 또는 비율 기반) |
| **Winning Challenger 추적** | `MockWinningChallengerTracker` 또는 실제 트래커 컨트랙트를 통해 승리자 식별 |

---

## 4. 현재 테스트 한계점

| 문제점 | 설명 |
|--------|------|
| ✅ **1. 정적 시나리오에 의존** | `scenarios.json`은 하드코딩되어 있어, 다양한 조건(예: 네트워크 지연, 전략 변경)을 테스트하기 어려움 |
| ✅ **2. 백엔드 자동화 부족** | `demoRunner.ts`가 수동 트리거 방식이며, 이벤트 기반 자동 실행 미흡 |
| ✅ **3. 실패 케이스 커버리지 낮음** | 예: 승리자 추적 실패, 보상 풀 잔액 부족, 권한 오류 등은 시뮬레이션되지 않음 |
| ✅ **4. 메트릭 수집 미흡** | 실행 시간, 가스 비용, 상태 전이 로그 등이 기록되지 않아 분석 어려움 |
| ✅ **5. 다국어/접근성 고려 없음** | UI는 영어 중심이며, 스크린 리더 등 접근성 고려 부족 |

---

## 5. 개선 제안: 더 나은 테스트를 위한 방향

### ✅ 1. **동적 시나리오 엔진 도입**
- `scenario.yaml` 또는 `scenario.json`을 기반으로 파라미터화된 시나리오 생성
- 예: `challenger_count: 3`, `attack_strategy: "late_challenge"`, `bond_ratio: 0.5`

### ✅ 2. **이벤트 기반 자동 실행**
- `FaultDisputeGame`의 `ClaimUpdated`, `GameResolved` 이벤트를 구독하여 다음 단계 자동 실행
- `demo-backend`에서 WebSocket 또는 The Graph-like 인덱서 활용

### ✅ 3. **실패 및 에지 케이스 테스트 추가**
- 다음 케이스를 시나리오에 포함:
  - 승리자 추적 실패 → `SeigManager`가 보상 미지급
  - 보상 풀 잔액 부족 → `distributeBond()`에서 revert
  - 권한 없는 주소가 `claimReward()` 시도

### ✅ 4. **테스트 메트릭 대시보드**
- 실행 후 다음 항목을 자동 보고:
  - 총 거래 수
  - 평균 가스 비용
  - 승리자 결정까지 걸린 시간
  - 보상 분배 비율
- 결과를 JSON으로 저장 → CI/CD에서 리그레션 테스트 가능

### ✅ 5. **프론트엔드 테스트 자동화**
- `Playwright` 또는 `Cypress`로 UI 테스트 자동화
- 예: “2명 챌린저 등록 → 승리자 결정 → 보상 수령” 흐름 자동 검증

### ✅ 6. **멀티플레이어 시뮬레이션 확장**
- 로컬에서 여러 챌린저 역할을 하는 **가상 에이전트** 실행 (Go 또는 Node.js 기반)
- 네트워크 조건(지연, 가스비 변동)을 조절하여 현실감 향상

---

## 6. 결론

현재 프론트 데모는 **Slashing 메커니즘을 이해하는 데 매우 유용**하지만,  
**자동화, 확장성, 테스트 커버리지 측면에서 개선 여지가 큽니다.**

향후 방향은:
> **“정적인 데모 → 동적인 테스트 환경”** 으로 전환

이를 통해:
- 실제 운영 환경과 유사한 검증 가능
- 슬래싱 로직의 **신뢰성, 공정성, 회복성**을 입증 가능
- 외부 감사자, 스테이크홀더에게 강력한 증거 제공

---

📌 **다음 단계 제안**
1. `demo-backend`에 이벤트 리스너 추가
2. `scenario.json`을 YAML 기반으로 확장
3. `playwright/` 폴더 생성 및 UI 테스트 작성
4. `test-results/` 폴더에 실행 결과 저장 구조 마련

---
*문서 작성자: AI Assistant | 기준일: 2025-04-05*

안녕하세요!