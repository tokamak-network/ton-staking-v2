# Front Demo: Multi-Challenger Slashing 시나리오

이 문서는 **Front 기반 Slashing 데모**의 실행 방법과 테스트 흐름을 정리합니다.  
목표는 **DisputeGame에서 멀티 챌린저 승리 → Slashing → Reward 분배** 과정을 UI에서 확인하는 것입니다.

---

## ✅ 구성 요소

### 1) Demo Backend (Express)
- 역할: demo script 실행 + 로그/상태 전달
- 실행: `demo-backend`

### 2) Demo Frontend (Next.js)
- 역할: 시나리오 선택 + 실행 + 이벤트/로그 모니터링
- 실행: `demo-frontend`

### 3) Demo Config
- `demo-config/` 아래 설정 파일 사용
  - `scenarios.json`
  - `networks.json`
  - `challengers.json`
  - `events.json`

### 4) Demo Scripts
- `scripts/demo/run-two-challengers.sh`
- `scripts/demo/run-three-challengers.sh`

---

## ✅ 사전 준비

