# 10. 향후 개선 포인트

[← 목차로 돌아가기](./README.md) | [← 이전: Known Issues](./09-known-issues.md)

---

## 10.1 프로덕션 준비 (P0-P1)

| 우선순위 | 항목 | 상세 | 예상 난이도 |
|---------|------|------|-----------|
| **P0** | VRF 오라클 통합 | `drawWinner()`의 난수를 Chainlink VRF v2.5로 교체. `requestDraw()` → `fulfillDraw()` 2단계 패턴 필요. VRF Subscription 관리 추가 | 높음 |
| **P0** | 보안 감사 (Audit) | 스마트 컨트랙트 전문 감사 업체에 의한 보안 리뷰. LotteryCandidate + DAOCommittee 확장 부분 최소 범위 | - |
| **P1** | 테스트넷 배포 | Sepolia 또는 Thanos Sepolia에 배포하여 실환경 테스트. wagmi 멀티체인 설정, 실제 가스비/트랜잭션 검증 | 중간 |
| **P1** | 가스 최적화 | `_depositors` 배열 순회 가스 측정, 대규모 예치자(100+) 시나리오 스트레스 테스트, 가스 리밋 초과 시 배치 처리 로직 추가 검토 | 중간 |

---

## 10.2 기능 개선 (P1-P3)

| 우선순위 | 항목 | 상세 | 예상 난이도 |
|---------|------|------|-----------|
| **P1** | 출금 UI 구현 | `requestWithdrawal`/`processWithdrawal` 프론트엔드 컴포넌트. 출금 상태(대기/처리 가능/완료) 표시, 남은 블록 수 카운트다운 | 중간 |
| **P2** | 참가비 변경 UI | 오퍼레이터 전용 패널에서 `setEntryFee` 호출. 현재/다음 라운드 참가비 표시 | 낮음 |
| **P2** | 라운드 통계 대시보드 | 라운드별 상세 통계: 총 참가자 수, 상금 풀 크기, 당첨 확률, 수익률 그래프 | 중간 |
| **P2** | ABI 자동 생성 | Forge 빌드 아티팩트(`out/LotteryCandidate.sol/LotteryCandidate.json`)에서 프론트엔드 ABI를 자동 추출하는 npm 스크립트 | 낮음 |
| **P2** | nftgame-zk-dex 연동 | `nftgame-zk-dex`를 활용하여 단순 복권을 넘어선 재미있는 카드 게임 요소 결합 및 스테이킹 보상 강화 | 중간 |
| **P3** | 모바일 최적화 | Tailwind 반응형 브레이크포인트 개선, 모바일 터치 UX | 낮음 |
| **P3** | 프론트엔드 E2E 테스트 | Playwright 기반 자동 테스트: 지갑 연결 → 예치 → 복권 참가 → 추첨 시나리오 | 중간 |

---

## 10.3 아키텍처 개선 (P1-P3)

| 우선순위 | 항목 | 상세 | 예상 난이도 |
|---------|------|------|-----------|
| **P1** | Solidity 버전 통일 | LotteryCandidate 관련 파일(`0.8.4`)을 프로젝트 표준(`0.8.19`)으로 업그레이드. breaking change 확인 필요 | 낮음 |
| **P2** | 이벤트 기반 UI 업데이트 | `useWatchContractEvent`로 `Deposited`, `LotteryWinnerDrawn`, `SeigniorageDistributed` 이벤트 구독. 폴링 대신 실시간 반영 | 중간 |
| **P2** | 멀티체인 wagmi 설정 | `wagmi.ts`에 Sepolia, Thanos Sepolia, Ethereum Mainnet 체인 추가. 환경변수 기반 동적 선택 | 낮음 |
| **P3** | `_depositors` 정리 로직 | 잔액 0인 예치자를 배열에서 제거하는 메커니즘. swap-and-pop 패턴 또는 EnumerableSet 사용 검토. 가스 비용과 트레이드오프 분석 필요 | 높음 |
| **P3** | 시뇨리지 자동 분배 | 예치/출금 시 자동으로 `updateSeigniorage()` 호출하여 최신 보상 반영. 가스 비용 증가 트레이드오프 | 중간 |

---

## 10.4 개선 의존 관계

```
P0: VRF 통합 ──┐
P0: 보안 감사 ──┼── P1: 테스트넷 배포 ──── 메인넷 배포
P1: 가스 최적화 ┘                │
                                 │
P1: 출금 UI ─────────────────────┘
P1: Solidity 버전 통일 ───────────┘
```

---

*이 문서는 2026-03-03 기준으로 작성되었으며, 우선순위는 프로젝트 상황에 따라 조정이 필요합니다.*

---

[← 목차로 돌아가기](./README.md)
