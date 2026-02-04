# Delegate Staking Frontend Development Plan

> **Reference Documents**: `docs/design/FRONTEND-PRD.md`, `docs/design/FRONTEND-ARCHITECTURE.md`

## Tech Stack Summary

| Category | Technology |
|---------|------|
| Framework | Next.js 14+ (App Router) |
| Language | TypeScript (Strict) |
| Styling | Tailwind CSS + shadcn/ui |
| Web3 | Wagmi v2 + Viem |
| Wallet | RainbowKit |
| State | Zustand (UI) + TanStack Query (Server) |
| Form | React Hook Form + Zod |

---

## Phase 1: Project Setup (1-2 days)

### 1.1 Project Initialization
- [ ] Create Next.js 14 project (`create-next-app`)
- [ ] Configure TypeScript strict mode
- [ ] Configure ESLint + Prettier
- [ ] Create folder structure

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

### 1.2 Styling Setup
- [ ] Install and configure Tailwind CSS
- [ ] Initialize shadcn/ui
- [ ] Add basic UI components (Button, Card, Input, Dialog, Toast)
- [ ] Configure dark mode theme
- [ ] Define global styles

### 1.3 Environment Configuration
- [ ] Configure environment variables (RPC URL, Contract Addresses)
- [ ] Configure networks (Mainnet, Testnet, Local)

---

## Phase 2: Web3 Integration (2-3 days)

### 2.1 Wallet Connection
- [ ] Configure Wagmi + Viem
- [ ] Integrate RainbowKit
- [ ] Wallet connect button component
- [ ] Connection state management (connected/disconnected)
- [ ] Network switching handling

### 2.2 Contract Integration
- [ ] Prepare ABI files (DelegateStakingV3Upgradeable)
- [ ] Configure contract addresses
- [ ] Implement basic Read hooks:
  - `useSequencerList()` - Sequencer list
  - `useSequencerInfo(address)` - Sequencer info
  - `useStakeInfo(user, sequencer)` - Staking info
  - `usePendingRewards(user, sequencer)` - Pending rewards
  - `useTotalStaked()` - Total staked amount

### 2.3 Transaction Management
- [ ] Implement Write hooks:
  - `useStake()` - Staking
  - `useUnstake()` - Unstaking
  - `useWithdraw()` - Withdrawal
  - `useClaimRewards()` - Claim rewards
  - `useRedelegate()` - Redelegation
- [ ] Transaction state management (pending, success, error)
- [ ] Toast notification integration

---

## Phase 3: Core Page Development (3-4 days)

### 3.1 Layout & Common Components
- [ ] Header (logo, navigation, wallet button)
- [ ] Footer
- [ ] Sidebar (mobile)
- [ ] Loading skeleton
- [ ] Error Boundary

### 3.2 Homepage (`/`)
- [ ] Hero section (service introduction)
- [ ] Key statistics (total staked, participant count)
- [ ] Popular Sequencer highlights
- [ ] CTA button (Get Started)

### 3.3 Sequencer List (`/sequencers`)
- [ ] Sequencer card component
  - Name/Address
  - TVL (Total Delegated Amount)
  - Commission Rate
  - Delegator count
  - Status (Active/Inactive)
- [ ] Filtering (by status)
- [ ] Sorting (TVL, fees, APY)
- [ ] Search functionality
- [ ] Pagination or infinite scroll

### 3.4 Sequencer Detail (`/sequencers/[address]`)
- [ ] Sequencer profile information
- [ ] Performance statistics (TVL, Delegators, Commission)
- [ ] Delegation modal integration
- [ ] Layer2 information display

---

## Phase 4: Staking Feature Implementation (3-4 days)

### 4.1 Staking Modal
- [ ] Amount input field (MAX button)
- [ ] Balance display
- [ ] Expected APY display
- [ ] Approve + Stake 2-step transaction
- [ ] Transaction progress status display
- [ ] Success/failure feedback

### 4.2 Unstaking Modal
- [ ] Amount input (partial/full)
- [ ] Unbonding period notice (7 days)
- [ ] Transaction processing
- [ ] Pending withdrawal display

### 4.3 Withdrawal Feature
- [ ] Withdrawal eligibility check
- [ ] Withdraw button
- [ ] Countdown timer (remaining unbonding period)

### 4.4 Redelegation Modal
- [ ] Source Sequencer display
- [ ] Target Sequencer selection
- [ ] Amount input
- [ ] Instant transfer processing

### 4.5 Rewards Claim
- [ ] Pending rewards display
- [ ] Claim button
- [ ] Batch claim (multiple Sequencers)

---

## Phase 5: Dashboard & Management (2-3 days)

### 5.1 Dashboard (`/dashboard`)
- [ ] My assets overview card
  - Total delegated amount
  - Pending withdrawal amount
  - Claimable rewards
  - Expected APY
- [ ] Delegation list (by Sequencer)
- [ ] Activity log (recent transactions)
- [ ] Quick action buttons (claim, withdraw, etc.)

### 5.2 Sequencer Admin (`/admin`)
- [ ] Registration form
  - Layer2 address input
  - OperatorManager address input
  - Commission Rate setting
- [ ] My Sequencer management
  - Statistics view
  - Commission change
  - Auto Trigger setting
- [ ] Commission claim

---

## Phase 6: Testing & Optimization (2-3 days)

### 6.1 Testing
- [ ] Component unit tests (Jest + Testing Library)
- [ ] E2E tests (Playwright) - main flows
- [ ] Wallet connection tests (Mock)

### 6.2 Performance Optimization
- [ ] Image optimization (next/image)
- [ ] Bundle size analysis and optimization
- [ ] Lighthouse performance check

### 6.3 Deployment
- [ ] Vercel deployment configuration
- [ ] Environment-specific settings (Testnet, Mainnet)
- [ ] CI/CD pipeline

---

## Milestone Summary

| Phase | Description | Estimated Duration |
|-------|------|----------|
| 1 | Project Setup | 1-2 days |
| 2 | Web3 Integration | 2-3 days |
| 3 | Core Pages | 3-4 days |
| 4 | Staking Features | 3-4 days |
| 5 | Dashboard & Management | 2-3 days |
| 6 | Testing & Optimization | 2-3 days |
| **Total** | | **13-19 days** |

---

## Priority (MVP Scope)

### Must Have (MVP)
1. Wallet connection
2. Sequencer list view
3. Staking (Stake)
4. Unstaking (Unstake)
5. Withdrawal (Withdraw)
6. Rewards claim (Claim)
7. Dashboard (my status)

### Should Have
1. Redelegation (Redelegate)
2. Sequencer detail page
3. Filter/sort functionality
4. Dark/light mode

### Nice to Have
1. Sequencer Admin page
2. Activity log/history
3. APY chart
4. Batch claim

---

## Next Steps

1. **Create project**: `npx create-next-app@latest frontend --typescript --tailwind --app`
2. **Initialize shadcn/ui**: `npx shadcn@latest init`
3. **Install Web3 packages**: `npm install wagmi viem @rainbow-me/rainbowkit @tanstack/react-query`
4. **Start development**: Proceed sequentially from Phase 1

---

## References

- [Next.js 14 Docs](https://nextjs.org/docs)
- [Wagmi v2 Docs](https://wagmi.sh)
- [shadcn/ui](https://ui.shadcn.com)
- [RainbowKit](https://www.rainbowkit.com/docs)
