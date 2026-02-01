# Frontend Architecture Document

> **Project**: Delegate Staking Frontend
> **Date**: 2026-01-28
> **Status**: DRAFT

## 1. 기술 스택 (Tech Stack)

### 1.1 Core Framework
- **Framework**: [Next.js 14+](https://nextjs.org/) (App Router)
  - 선택 이유: React Server Components(RSC)를 활용한 초기 로딩 최적화 및 SEO 이점.
- **Language**: [TypeScript](https://www.typescriptlang.org/) (Strict Mode)

### 1.2 Styling
- **Engine**: [Tailwind CSS](https://tailwindcss.com/)
- **Components**: [shadcn/ui](https://ui.shadcn.com/) (Radix UI 기반)
  - 선택 이유: 커스터마이징이 용이하고 디자인 시스템 구축에 효율적.
- **Icons**: Lucide React

### 1.3 Web3 Integration
- **Client Library**: [Viem](https://viem.sh/) (Low-level interaction)
- **Hooks Library**: [Wagmi](https://wagmi.sh/) v2 (React hooks)
- **Wallet Connection**: [RainbowKit](https://www.rainbowkit.com/) 또는 [ConnectKit](https://docs.family.co/connectkit)
- **Query Management**: [TanStack Query](https://tanstack.com/query/v5) (Wagmi 내부 사용)

---

## 2. 아키텍처 설계 (Architecture Design)

### 2.1 폴더 구조 (Feature-based)

```bash
src/
├── app/                    # Next.js App Router
│   ├── (public)/           # Public pages (Home, List)
│   ├── (auth)/             # Protected pages (Dashboard)
│   └── layout.tsx
├── components/
│   ├── ui/                 # Shadcn/Base UI components (Button, Input)
│   ├── common/             # Shared components (Header, Footer, WalletBtn)
│   └── features/           # Feature-specific components
│       ├── staking/        # Staking forms, modals
│       ├── sequencers/     # Sequencer list/cards
│       └── dashboard/      # Charts, Stats cards
├── hooks/
│   ├── useStaking.ts       # Contract interactions facade
│   └── useCurrency.ts      # Price conversion helpers
├── lib/
│   ├── contracts/          # ABI, Addresses
│   └── utils.ts            # Formatting helpers
└── services/               # External API services (Indexer, Price API)
```

### 2.2 상태 관리 (State Management)

1. **Server State (Chain Data)**:
   - `Wagmi` + `TanStack Query`를 사용하여 캐싱 및 자동 갱신 관리.
   - `watchContractEvent`를 활용한 실시간 업데이트.

2. **Client State (UI)**:
   - **Zustand**: 전역 UI 상태 (예: 사이드바 열림, 선택된 Sequencer 등) 관리.
   - 복잡한 Context API 사용 지양.

3. **Form State**:
   - **React Hook Form** + **Zod**: 유효성 검사 및 폼 상태 관리.

### 2.3 데이터 흐름 전략 (Data Fetching Strategy)

#### Phase 1: Direct Contract Calls (MVP)
- 별도의 인덱서 없이 RPC 노드를 통해 데이터 직접 조회.
- **Multicall3** 컨트랙트 활용:
  - Sequencer 목록 순회 시 `multicall`을 사용하여 RPC 요청 횟수 최소화.
  - `ISeigManager`와 `DelegateStaking` 컨트랙트의 View 함수들을 배치 처리.

#### Phase 2: Hybrid (Contract + Indexer)
- 과거 이력(History), APY 차트 등은 The Graph 등의 인덱싱 서비스 도입.

---

## 3. 주요 모듈 설계

### 3.1 Contract Integration Hook (`useStaking`)

```typescript
// 예시 아키텍처
export const useDelegate = () => {
  const { writeContract, isPending } = useWriteContract();
  
  const delegate = async (sequencer: Address, amount: bigint) => {
    // 1. Check Approval
    // 2. Approve if needed (Permit preferred)
    // 3. Call execute
    return writeContract({
        abi: DelegateStakingABI,
        address: CONTRACT_ADDRESS,
        functionName: 'delegate',
        args: [sequencer, amount]
    });
  };
  
  return { delegate, isLoading: isPending };
};
```

### 3.2 에러 처리 및 사용자 피드백

- **Toast Notifications**: `sonner` 또는 `react-hot-toast` 사용.
- **Transaction Hash Link**: 성공 시 Explorer 링크 제공.
- **User Friendly Errors**: "Contract execution reverted" 대신 "잔액이 부족하거나 승인이 필요합니다" 등으로 변환하여 표시.

---

## 4. 보안 및 성능 (Security & Performance)

- **Input Validation**: 모든 숫자 입력값은 bigint 변환 전 validation 수행.
- **BigInt 처리**: JavaScript Number의 정밀도 한계를 피하기 위해 항상 BigInt 사용.
- **SSR & SEO**: 정적 데이터(Sequencer 기본 정보 등)는 서버 사이드 렌더링 활용 가능.
