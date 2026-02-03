# Delegate Staking Frontend 개발 계획

> **기반 문서**: `docs/design/FRONTEND-PRD.md`, `docs/design/FRONTEND-ARCHITECTURE.md`

## 기술 스택 요약

| 카테고리 | 기술 |
|---------|------|
| Framework | Next.js 14+ (App Router) |
| Language | TypeScript (Strict) |
| Styling | Tailwind CSS + shadcn/ui |
| Web3 | Wagmi v2 + Viem |
| Wallet | RainbowKit |
| State | Zustand (UI) + TanStack Query (Server) |
| Form | React Hook Form + Zod |

---

## Phase 1: 프로젝트 셋업 (1-2일)

### 1.1 프로젝트 초기화
- [ ] Next.js 14 프로젝트 생성 (`create-next-app`)
- [ ] TypeScript strict mode 설정
- [ ] ESLint + Prettier 설정
- [ ] 폴더 구조 생성

```bash
frontend/
├── src/
│   ├── app/                    # Next.js App Router
│   │   ├── page.tsx            # Home
│   │   ├── dashboard/          # Dashboard
│   │   ├── sequencers/         # Sequencer List & Detail
│   │   ├── admin/              # Sequencer Admin
│   │   └── layout.tsx
│   ├── components/
│   │   ├── ui/                 # shadcn/ui components
│   │   ├── common/             # Header, Footer, WalletButton
│   │   └── features/           # Feature components
│   ├── hooks/                  # Custom hooks
│   ├── lib/                    # Utils, contracts
│   ├── services/               # API services
│   └── stores/                 # Zustand stores
├── public/
└── package.json
```

### 1.2 스타일링 설정
- [ ] Tailwind CSS 설치 및 설정
- [ ] shadcn/ui 초기화
- [ ] 기본 UI 컴포넌트 추가 (Button, Card, Input, Dialog, Toast)
- [ ] 다크 모드 테마 설정
- [ ] 글로벌 스타일 정의

### 1.3 환경 설정
- [ ] 환경 변수 설정 (RPC URL, Contract Addresses)
- [ ] 네트워크 설정 (Mainnet, Testnet, Local)

---

## Phase 2: Web3 통합 (2-3일)

### 2.1 지갑 연결
- [ ] Wagmi + Viem 설정
- [ ] RainbowKit 통합
- [ ] 지갑 연결 버튼 컴포넌트
- [ ] 연결 상태 관리 (연결됨/해제됨)
- [ ] 네트워크 전환 처리

### 2.2 컨트랙트 통합
- [ ] ABI 파일 준비 (DelegateStakingV3Upgradeable)
- [ ] 컨트랙트 주소 설정
- [ ] 기본 Read hooks 구현:
  - `useSequencerList()` - 시퀀서 목록
  - `useSequencerInfo(address)` - 시퀀서 정보
  - `useStakeInfo(user, sequencer)` - 스테이킹 정보
  - `usePendingRewards(user, sequencer)` - 대기 보상
  - `useTotalStaked()` - 총 스테이킹량

### 2.3 트랜잭션 관리
- [ ] Write hooks 구현:
  - `useStake()` - 스테이킹
  - `useUnstake()` - 언스테이킹
  - `useWithdraw()` - 출금
  - `useClaimRewards()` - 보상 청구
  - `useRedelegate()` - 재위임
- [ ] 트랜잭션 상태 관리 (pending, success, error)
- [ ] Toast 알림 통합

---

## Phase 3: 핵심 페이지 개발 (3-4일)

### 3.1 레이아웃 & 공통 컴포넌트
- [ ] Header (로고, 네비게이션, 지갑 버튼)
- [ ] Footer
- [ ] Sidebar (모바일)
- [ ] Loading 스켈레톤
- [ ] Error Boundary

### 3.2 홈페이지 (`/`)
- [ ] 히어로 섹션 (서비스 소개)
- [ ] 주요 통계 (총 스테이킹량, 참여자 수)
- [ ] 인기 Sequencer 하이라이트
- [ ] CTA 버튼 (시작하기)

### 3.3 Sequencer 목록 (`/sequencers`)
- [ ] Sequencer 카드 컴포넌트
  - 이름/주소
  - TVL (총 위임량)
  - Commission Rate
  - Delegator 수
  - 상태 (Active/Inactive)
- [ ] 필터링 (상태별)
- [ ] 정렬 (TVL, 수수료, APY)
- [ ] 검색 기능
- [ ] 페이지네이션 또는 무한 스크롤

### 3.4 Sequencer 상세 (`/sequencers/[address]`)
- [ ] Sequencer 프로필 정보
- [ ] 성과 통계 (TVL, Delegators, Commission)
- [ ] 위임 모달 연동
- [ ] Layer2 정보 표시

---

## Phase 4: 스테이킹 기능 구현 (3-4일)

### 4.1 스테이킹 모달
- [ ] 금액 입력 필드 (MAX 버튼)
- [ ] 잔액 표시
- [ ] 예상 APY 표시
- [ ] Approve + Stake 2단계 트랜잭션
- [ ] 트랜잭션 진행 상태 표시
- [ ] 성공/실패 피드백

### 4.2 언스테이킹 모달
- [ ] 금액 입력 (부분/전체)
- [ ] 언본딩 기간 안내 (7일)
- [ ] 트랜잭션 처리
- [ ] 대기 중인 출금 표시

### 4.3 출금 기능
- [ ] 출금 가능 여부 체크
- [ ] 출금 버튼
- [ ] 카운트다운 타이머 (남은 언본딩 기간)

### 4.4 재위임 모달
- [ ] 소스 Sequencer 표시
- [ ] 타겟 Sequencer 선택
- [ ] 금액 입력
- [ ] 즉시 이동 처리

### 4.5 보상 청구
- [ ] 대기 보상 표시
- [ ] 청구 버튼
- [ ] 일괄 청구 (여러 Sequencer)

---

## Phase 5: 대시보드 & 관리 (2-3일)

### 5.1 대시보드 (`/dashboard`)
- [ ] 내 자산 현황 카드
  - 총 위임 금액
  - 출금 대기 금액
  - 수령 가능 보상
  - 예상 APY
- [ ] 위임 목록 (Sequencer별)
- [ ] 활동 로그 (최근 트랜잭션)
- [ ] 빠른 액션 버튼 (청구, 출금 등)

### 5.2 Sequencer Admin (`/admin`)
- [ ] 등록 폼
  - Layer2 주소 입력
  - OperatorManager 주소 입력
  - Commission Rate 설정
- [ ] 내 Sequencer 관리
  - 통계 조회
  - Commission 변경
  - Auto Trigger 설정
- [ ] 커미션 청구

---

## Phase 6: 테스트 & 최적화 (2-3일)

### 6.1 테스트
- [ ] 컴포넌트 단위 테스트 (Jest + Testing Library)
- [ ] E2E 테스트 (Playwright) - 주요 플로우
- [ ] 지갑 연결 테스트 (Mock)

### 6.2 성능 최적화
- [ ] 이미지 최적화 (next/image)
- [ ] 번들 사이즈 분석 및 최적화
- [ ] Lighthouse 성능 체크

### 6.3 배포
- [ ] Vercel 배포 설정
- [ ] 환경별 설정 (Testnet, Mainnet)
- [ ] CI/CD 파이프라인

---

## 마일스톤 요약

| Phase | 내용 | 예상 기간 |
|-------|------|----------|
| 1 | 프로젝트 셋업 | 1-2일 |
| 2 | Web3 통합 | 2-3일 |
| 3 | 핵심 페이지 | 3-4일 |
| 4 | 스테이킹 기능 | 3-4일 |
| 5 | 대시보드 & 관리 | 2-3일 |
| 6 | 테스트 & 최적화 | 2-3일 |
| **Total** | | **13-19일** |

---

## 우선순위 (MVP Scope)

### Must Have (MVP)
1. 지갑 연결
2. Sequencer 목록 조회
3. 스테이킹 (Stake)
4. 언스테이킹 (Unstake)
5. 출금 (Withdraw)
6. 보상 청구 (Claim)
7. 대시보드 (내 현황)

### Should Have
1. 재위임 (Redelegate)
2. Sequencer 상세 페이지
3. 필터/정렬 기능
4. 다크/라이트 모드

### Nice to Have
1. Sequencer Admin 페이지
2. 활동 로그/히스토리
3. APY 차트
4. 일괄 청구

---

## 다음 단계

1. **프로젝트 생성**: `npx create-next-app@latest frontend --typescript --tailwind --app`
2. **shadcn/ui 초기화**: `npx shadcn@latest init`
3. **Web3 패키지 설치**: `npm install wagmi viem @rainbow-me/rainbowkit @tanstack/react-query`
4. **개발 시작**: Phase 1부터 순차 진행

---

## 참고 자료

- [Next.js 14 Docs](https://nextjs.org/docs)
- [Wagmi v2 Docs](https://wagmi.sh)
- [shadcn/ui](https://ui.shadcn.com)
- [RainbowKit](https://www.rainbowkit.com/docs)
