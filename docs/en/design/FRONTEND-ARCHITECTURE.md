# Frontend Architecture Document

> **Project**: Delegate Staking Frontend
> **Date**: 2026-01-28
> **Status**: DRAFT

## 1. Tech Stack

### 1.1 Core Framework
- **Framework**: [Next.js 14+](https://nextjs.org/) (App Router)
  - Rationale: Optimizes initial loading and provides SEO benefits through React Server Components (RSC).
- **Language**: [TypeScript](https://www.typescriptlang.org/) (Strict Mode)

### 1.2 Styling
- **Engine**: [Tailwind CSS](https://tailwindcss.com/)
- **Components**: [shadcn/ui](https://ui.shadcn.com/) (based on Radix UI)
  - Rationale: Easy to customize and efficient for building design systems.
- **Icons**: Lucide React

### 1.3 Web3 Integration
- **Client Library**: [Viem](https://viem.sh/) (Low-level interaction)
- **Hooks Library**: [Wagmi](https://wagmi.sh/) v2 (React hooks)
- **Wallet Connection**: [RainbowKit](https://www.rainbowkit.com/) or [ConnectKit](https://docs.family.co/connectkit)
- **Query Management**: [TanStack Query](https://tanstack.com/query/v5) (used internally by Wagmi)

---

## 2. Architecture Design

### 2.1 Folder Structure (Feature-based)

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

### 2.2 State Management

1. **Server State (Chain Data)**:
   - Uses `Wagmi` + `TanStack Query` for caching and automatic refresh management.
   - Real-time updates through `watchContractEvent`.

2. **Client State (UI)**:
   - **Zustand**: Manages global UI state (e.g., sidebar open/close, selected Sequencer, etc.).
   - Avoid complex Context API usage.

3. **Form State**:
   - **React Hook Form** + **Zod**: Validation and form state management.

### 2.3 Data Fetching Strategy

#### Phase 1: Direct Contract Calls (MVP)
- Query data directly through RPC nodes without a separate indexer.
- **Multicall3** contract utilization:
  - Use `multicall` when iterating through Sequencer lists to minimize RPC request count.
  - Batch process View functions from `ISeigManager` and `DelegateStaking` contracts.

#### Phase 2: Hybrid (Contract + Indexer)
- Introduce indexing services like The Graph for historical data, APY charts, etc.

---

## 3. Core Module Design

### 3.1 Contract Integration Hook (`useStaking`)

```typescript
// Example architecture
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

### 3.2 Error Handling and User Feedback

- **Toast Notifications**: Use `sonner` or `react-hot-toast`.
- **Transaction Hash Link**: Provide Explorer link on success.
- **User Friendly Errors**: Display user-friendly messages like "Insufficient balance or approval required" instead of "Contract execution reverted".

---

## 4. Security & Performance

- **Input Validation**: Perform validation on all numeric inputs before bigint conversion.
- **BigInt Handling**: Always use BigInt to avoid JavaScript Number precision limitations.
- **SSR & SEO**: Static data (basic Sequencer information, etc.) can leverage server-side rendering.
