# Tokamak Delegate Staking - 페이지 상세 설계

> **생성일**: 2026-02-05
> **상태**: APPROVED
> **관련 문서**: `PAGE-SPECIFICATION.md`, `FRONTEND-PRD.md`, `FRONTEND-ARCHITECTURE.md`

---

## 개요

이 문서는 Tokamak Delegate Staking dApp의 5개 페이지에 대한 완전한 상세 설계를 담고 있습니다.

### 페이지 목록
1. [Home Page (/)](#1-home-page-)
2. [Sequencers Page (/sequencers)](#2-sequencers-page-sequencers)
3. [Sequencer Detail Page (/sequencers/[address])](#3-sequencer-detail-page-sequencersaddress)
4. [Dashboard Page (/dashboard)](#4-dashboard-page-dashboard)
5. [Admin Page (/admin)](#5-admin-page-admin)

### 공통 모달
- [StakeModal](#stakemodal)
- [UnstakeModal](#unstakemodal)
- [ClaimRewardsModal (NEW)](#claimrewardsmodal-new)
- [WithdrawModal (NEW)](#withdrawmodal-new)
- [RedelegateModal (NEW)](#redelegatemodal-new)

---

## 공통 UI/UX 가이드라인

### 숫자 포맷팅
모든 토큰 수량 및 숫자 값은 **소수점 2자리**까지만 표시합니다.

| 유형 | 포맷 | 예시 |
|------|------|------|
| TON 수량 | `X,XXX.XX TON` | `1,000.00 TON` |
| WTON 수량 | `X,XXX.XX WTON` | `949,999.99 WTON` |
| 퍼센트 | `X.XX%` | `10.00%` |

```typescript
// formatTON 함수는 항상 소수점 2자리까지만 표시
export function formatTON(value: bigint, decimals = 18): string {
  const divisor = BigInt(10 ** decimals);
  const intPart = value / divisor;
  const decPart = value % divisor;
  const decStr = decPart.toString().padStart(decimals, '0').slice(0, 2);
  return `${intPart.toLocaleString()}.${decStr}`;
}
```

### 버튼 레이아웃
액션 버튼들은 **항상 한 줄에 배치**되어야 합니다. 줄바꿈 없이 가로로 나열됩니다.

```tsx
// 올바른 버튼 레이아웃
<div className="flex items-center gap-1.5 flex-nowrap">
  <Button size="sm">Stake</Button>
  <Button size="sm">Unstake</Button>
  <Button size="sm">Redelegate</Button>
  <Button size="sm">Claim</Button>
</div>

// 잘못된 버튼 레이아웃 (flex-wrap 사용 금지)
<div className="flex flex-wrap gap-2">...</div>
```

---

## 1. Home Page (/)

### 목적
서비스 소개 및 네트워크 통계를 보여주는 랜딩 페이지

### 지갑 연결
- **필수 아님** - 지갑 없이 접근 가능

### 컴포넌트 구조
```
HomePage
├── HeroSection
│   ├── Title (gradient text)
│   ├── Description
│   └── CTAButtons
│       ├── PrimaryButton ("Explore Sequencers" → /sequencers)
│       └── SecondaryButton ("View Dashboard" → /dashboard)
├── FeaturesSection
│   └── FeatureCard[] (3 cards: Secure Staking, Earn Rewards, Easy Redelegation)
├── StatsSection
│   └── StatCard[] (4 cards)
│       ├── TotalStaked (useTotalStaked)
│       ├── ActiveSequencers (useSequencerCount)
│       ├── TotalDelegators (---) ← 인덱서 필요
│       └── AvgAPY (---) ← 복잡한 계산 필요
└── HowItWorksSection
    └── Step[] (4 steps)
```

### 데이터 요구사항
| 데이터 | Hook | 비고 |
|--------|------|------|
| Total Staked | `useTotalStaked()` | 현재 placeholder |
| Sequencer Count | `useSequencerCount()` | 현재 placeholder |
| Total Delegators | N/A | 인덱서 필요 |
| Avg APY | N/A | V3 복잡 계산 필요 |

### 로딩/에러 상태
- Stats: "---" 표시 후 데이터 로드 시 업데이트
- 에러: Toast 알림 + 재시도 버튼

### 반응형 설계
| 브레이크포인트 | 레이아웃 변화 |
|----------------|---------------|
| Mobile (<768px) | Feature 카드 세로 배치, Hero 텍스트 축소 |
| Tablet (768-1024px) | 2열 Feature 그리드 |
| Desktop (>1024px) | 3열 Feature 그리드 |

---

## 2. Sequencers Page (/sequencers)

### 목적
모든 등록된 시퀀서를 탐색하고 스테이킹할 시퀀서 선택

### 지갑 연결
- **조회**: 불필요
- **스테이킹 액션**: 필요

### 컴포넌트 구조
```
SequencersPage
├── PageHeader
│   ├── Title ("Sequencers")
│   └── Description
├── SearchAndFilterBar
│   ├── SearchInput (주소 검색)
│   └── FilterButton (향후: TVL 순, Commission 순 정렬)
├── SequencerGrid
│   └── SequencerCard[]
│       ├── CardHeader
│       │   ├── Address (truncated)
│       │   └── StatusBadge (Active/Inactive)
│       ├── CardContent
│       │   ├── TotalStaked
│       │   ├── Commission
│       │   └── Layer2Info
│       └── CardActions
│           ├── DetailsButton → /sequencers/[address]
│           └── StakeButton → StakeModal
├── StakeModal
└── UnstakeModal
```

### 데이터 요구사항
| 데이터 | Hook | 컨트랙트 함수 |
|--------|------|---------------|
| Sequencer List | `useSequencerList()` | `getSequencerList()` |
| Sequencer Info (per card) | `useSequencerInfo(address)` | `getSequencerInfo(address)` |

### 상태 관리
```typescript
// Local State
const [searchQuery, setSearchQuery] = useState("");

// Zustand UI Store
{
  selectedSequencer: Address | null;
  isStakeModalOpen: boolean;
  openStakeModal: (sequencer: Address) => void;
  closeStakeModal: () => void;
}
```

### 사용자 플로우

**Flow 1: 시퀀서 검색**
1. 사용자가 검색 입력
2. `searchQuery` 상태 업데이트
3. 필터링된 목록 렌더링 (address.includes()로 클라이언트 필터)

**Flow 2: 시퀀서 상세 보기**
1. "Details" 버튼 클릭
2. `/sequencers/[address]`로 라우팅

**Flow 3: 스테이킹**
1. "Stake" 버튼 클릭
2. `openStakeModal(sequencerAddress)` 호출
3. StakeModal 열림

### 엣지 케이스
| 케이스 | 처리 |
|--------|------|
| 등록된 시퀀서 없음 | "No sequencers registered yet." |
| 검색 결과 없음 | "No sequencers found matching your search." |
| 시퀀서 탈퇴 | 카드 숨김 (isRegistered = false) |

### 로딩 상태
```tsx
// Skeleton 구조
<Card className="bg-slate-900/50 border-slate-800">
  <CardContent className="p-6">
    <Skeleton className="h-6 w-32 mb-4" />
    <Skeleton className="h-4 w-full mb-2" />
    <Skeleton className="h-4 w-3/4 mb-4" />
    <Skeleton className="h-10 w-full" />
  </CardContent>
</Card>
```

### 반응형 설계
| 브레이크포인트 | 레이아웃 변화 |
|----------------|---------------|
| Mobile (<768px) | 1열 그리드, 전체 너비 검색 |
| Tablet (768-1024px) | 2열 그리드 |
| Desktop (>1024px) | 3열 그리드 |

---

## 3. Sequencer Detail Page (/sequencers/[address])

### 목적
특정 시퀀서의 상세 정보, 경제 지표, 개인 포지션 관리

### 지갑 연결
- **기본 정보/경제 지표**: 불필요
- **개인 포지션/액션**: 필요

### URL 파라미터
- `address` - 시퀀서의 이더리움 주소

### 컴포넌트 구조
```
SequencerDetailPage
├── BackButton (← Back to Sequencers)
├── PageHeader
│   ├── AddressDisplay (with copy button)
│   ├── StatusBadge
│   └── ExternalLinks (Etherscan)
├── StatsGrid (4 cards)
│   ├── TotalStakedCard
│   ├── CommissionCard
│   ├── ShareOfTotalCard (계산: totalStaked / getTotalStaked)
│   └── Layer2AddressCard
├── YourPositionCard (지갑 연결 필요)
│   ├── ConnectedState
│   │   ├── StakedAmount
│   │   ├── PendingRewards (WTON)
│   │   ├── PendingUnstake
│   │   │   └── UnstakeCountdown (NEW) ← 카운트다운 타이머
│   │   └── ActionButtons
│   │       ├── StakeButton
│   │       ├── UnstakeButton (amount > 0 시 활성화)
│   │       ├── ClaimButton (NEW) (rewards > 0 시 활성화)
│   │       ├── WithdrawButton (NEW) (unbonding 완료 시 활성화)
│   │       └── RedelegateButton (NEW)
│   └── NotConnectedState
│       └── ConnectPrompt ("Connect your wallet to view your position")
├── EconomicsCard
│   ├── L2EligibilitySection
│   │   ├── StatusIndicator (✓ Eligible / ⚠ Not Eligible)
│   │   ├── RequiredStake (θ × Bridged TON)
│   │   ├── CurrentStake
│   │   └── WarningBanner (미충족 시 얼마나 부족한지)
│   ├── EstimatedSeigniorageSection
│   │   ├── SequencerReward (위임자용)
│   │   ├── ValidatorReward
│   │   └── YourEstimatedReward (스테이킹 시)
│   │       └── 계산: estimatedRewards[0] × userStake / totalStaked
│   └── RewardDistributionSection
│       ├── DelegatorsBar (100% - commission)
│       └── CommissionBar (commission %)
└── Modals
    ├── StakeModal
    ├── UnstakeModal
    ├── ClaimRewardsModal (NEW)
    ├── WithdrawModal (NEW)
    └── RedelegateModal (NEW)
```

### 데이터 요구사항
| 데이터 | Hook | 용도 |
|--------|------|------|
| Sequencer Info | `useSequencerInfo(address)` | 기본 정보 |
| Total Network Staked | `useTotalStaked()` | Share 계산 |
| User Stake Info | `useStakeInfo(user, sequencer)` | 개인 포지션 |
| Pending Rewards | `usePendingRewards(user, sequencer)` | 청구 가능 보상 |
| L2 Eligibility | `useCheckLayer2Eligibility(layer2)` | 자격 상태 |
| Est. Seigniorage | `useEstimateSeigniorage(sequencer)` | 예상 보상 |
| Unbonding Period | `useUnbondingPeriod()` | 카운트다운 계산 |

### 파생 데이터 계산
```typescript
// 네트워크 점유율
const shareOfTotal = totalStaked > 0n
  ? (Number(sequencerInfo.totalStaked) / Number(totalStaked) * 100).toFixed(2)
  : '0';

// 사용자의 시퀀서 내 점유율
const userShare = sequencerInfo.totalStaked > 0n
  ? (Number(stakeInfo.amount) / Number(sequencerInfo.totalStaked) * 100).toFixed(2)
  : '0';

// 사용자 예상 보상
const userEstimatedReward = estimatedRewards && sequencerInfo.totalStaked > 0n
  ? (estimatedRewards[0] * stakeInfo.amount) / sequencerInfo.totalStaked
  : 0n;

// 출금 가능 여부
const canWithdraw = stakeInfo.unstakeTime + unbondingPeriod <= now;
```

### UnstakeCountdown 컴포넌트 (NEW)
```typescript
function UnstakeCountdown({ unstakeTime, unbondingPeriod }: Props) {
  const [timeLeft, setTimeLeft] = useState(0);

  useEffect(() => {
    const withdrawTime = Number(unstakeTime) + Number(unbondingPeriod);
    const now = Math.floor(Date.now() / 1000);
    setTimeLeft(Math.max(0, withdrawTime - now));

    const interval = setInterval(() => {
      setTimeLeft(prev => Math.max(0, prev - 1));
    }, 1000);

    return () => clearInterval(interval);
  }, [unstakeTime, unbondingPeriod]);

  if (timeLeft <= 0) return <span className="text-green-400">Ready to withdraw</span>;
  return <span>{formatTimeRemaining(timeLeft)}</span>;
}
```

### 사용자 플로우

**Flow 1: Stake**
1. "Stake" 버튼 클릭
2. StakeModal 열림
3. 금액 입력, "Stake" 또는 "Approve" 먼저 클릭
4. 트랜잭션 제출
5. 성공 시: Toast, 모달 닫힘, 데이터 새로고침

**Flow 2: Unstake**
1. "Unstake" 버튼 클릭 (staked > 0일 때만 활성화)
2. UnstakeModal 열림
3. 금액 입력, "Request Unstake" 클릭
4. 트랜잭션 제출
5. 성공 시: Toast, unstakeTime 설정, 카운트다운 시작

**Flow 3: Claim Rewards (NEW)**
1. "Claim" 버튼 클릭 (pendingRewards > 0일 때만 활성화)
2. 확인 모달 또는 직접 트랜잭션
3. `claimRewards(sequencer)` 호출
4. 성공 시: Toast, 보상 0으로 리셋

**Flow 4: Redelegate (NEW)**
1. "Redelegate" 버튼 클릭
2. RedelegateModal 열림
3. 드롭다운에서 대상 시퀀서 선택
4. 금액 입력
5. `redelegate(fromSeq, toSeq, amount)` 호출
6. 성공 시: 포지션 즉시 이동 (unbonding 없음)

**Flow 5: 주소 복사**
1. 주소 옆 복사 아이콘 클릭
2. 주소가 클립보드에 복사됨
3. Toast: "Address copied to clipboard"

### 엣지 케이스
| 케이스 | 처리 |
|--------|------|
| 사용자 스테이킹 0 | "0 TON" 표시, Unstake 버튼 비활성화 |
| 보상 0 | "0 WTON" 표시, Claim 버튼 비활성화 |
| 자격 미충족 | 경고 배너 + 부족 금액 표시 |
| 대기 중인 언스테이크 | 카운트다운 타이머 표시 |
| 지갑 미연결 | 포지션 섹션에 연결 프롬프트 |
| 시퀀서 탈퇴 | /sequencers로 리다이렉트 |

### 반응형 설계
| 브레이크포인트 | 레이아웃 변화 |
|----------------|---------------|
| Mobile (<768px) | 모든 카드 세로 배치, 1열 통계 |
| Tablet (768-1024px) | 2열 통계 그리드 |
| Desktop (>1024px) | 4열 통계 그리드 |

---

## 4. Dashboard Page (/dashboard)

### 목적
모든 시퀀서에 걸친 개인 스테이킹 포지션 관리

### 지갑 연결
- **필수** - 전체 페이지에 지갑 연결 필요

### 컴포넌트 구조
```
DashboardPage
├── NotConnectedState
│   ├── WalletIcon
│   ├── Title
│   ├── Description
│   └── ConnectButton (RainbowKit)
├── ConnectedState
│   ├── PageHeader
│   ├── OverviewStatsGrid (4 cards)
│   │   ├── TONBalanceCard
│   │   │   └── useTonBalance(address)
│   │   ├── TotalStakedCard
│   │   │   └── 집계: sum of all stakeInfo.amount
│   │   ├── ClaimableRewardsCard
│   │   │   └── 집계: sum of all pendingRewards (표시만, 개별 청구)
│   │   └── PendingUnstakeCard
│   │       └── 집계: sum of all stakeInfo.unstakeAmount
│   ├── StakingPositionsCard
│   │   ├── CardHeader
│   │   │   ├── Title
│   │   │   └── FilterTabs (NEW): All | Active | Pending
│   │   └── PositionList
│   │       └── StakePositionCard[]
│   │           ├── SequencerInfo
│   │           │   ├── Address (link to detail)
│   │           │   └── StatusBadge (Staked/Not Staked)
│   │           ├── PositionStats
│   │           │   ├── Staked
│   │           │   ├── Rewards
│   │           │   ├── PendingUnstake
│   │           │   └── UnstakeCountdown (NEW)
│   │           └── ActionButtons
│   │               ├── StakeButton
│   │               ├── UnstakeButton (staked > 0)
│   │               ├── ClaimButton (NEW) (rewards > 0)
│   │               ├── WithdrawButton (NEW) (unbonding 완료)
│   │               └── RedelegateButton (NEW)
│   └── Modals (all)
└── EmptyState (연결됨 but 포지션 없음)
    └── CallToAction → /sequencers
```

### 데이터 요구사항
| 데이터 | Hook | 비고 |
|--------|------|------|
| TON Balance | `useTonBalance(address)` | 지갑 잔액 |
| Sequencer List | `useSequencerList()` | 전체 시퀀서 |
| Aggregated Stats | `useUserStakingStats(address, sequencers)` | 총합 계산 |
| Unbonding Period | `useUnbondingPeriod()` | 카운트다운 |

### 포지션 필터링
```typescript
const [filterTab, setFilterTab] = useState<'all' | 'active' | 'pending'>('all');

const filteredPositions = positions.filter(p => {
  if (filterTab === 'all') return true;
  if (filterTab === 'active') return p.stakeInfo.amount > 0n;
  if (filterTab === 'pending') return p.stakeInfo.unstakeAmount > 0n;
  return true;
});
```

### 사용자 플로우

**Flow 1: 대시보드 보기**
1. 페이지 로드
2. 미연결 시: 연결 프롬프트 표시
3. 연결됨: 모든 데이터 가져오기
4. 개요 통계 + 포지션 카드 표시

**Flow 2: 시퀀서에 스테이킹**
1. 포지션 카드에서 "Stake" 클릭
2. 해당 시퀀서가 선택된 StakeModal 열림
3. 스테이킹 플로우 완료

**Flow 3: Withdraw (NEW)**
1. `unstakeTime + unbondingPeriod <= now` 일 때 버튼 활성화
2. "Withdraw" 클릭
3. `withdraw(sequencer)` 트랜잭션
4. 성공 시: TON이 지갑으로 반환

**Flow 4: Redelegate**
1. 포지션 카드에서 "Redelegate" 클릭
2. 소스가 미리 선택된 RedelegateModal 열림
3. 대상 시퀀서 선택
4. 금액 입력
5. redelegate 실행

### 엣지 케이스
| 케이스 | 처리 |
|--------|------|
| 포지션 없음 | /sequencers로 CTA가 있는 빈 상태 표시 |
| 포지션 잔액 0 | "0 TON"으로 카드 표시 |
| 여러 대기 중 언스테이크 | 각각 카운트다운으로 표시 |
| 카운트다운 0 도달 | 출금 버튼 활성화, "Ready" 표시 |
| 모든 보상 0 | 청구 버튼 비활성화 |
| 사용자 연결 해제 | 연결 상태로 리다이렉트 |

### 반응형 설계
| 브레이크포인트 | 레이아웃 변화 |
|----------------|---------------|
| Mobile (<768px) | 개요 카드 스택, 컴팩트한 포지션 카드 |
| Tablet (768-1024px) | 2열 개요 그리드 |
| Desktop (>1024px) | 4열 개요 그리드 |

---

## 5. Admin Page (/admin)

### 목적
시퀀서 운영자의 등록, 설정, 커미션 관리

### 지갑 연결
- **필수** - 전체 페이지에 지갑 연결 필요

### 3가지 상태
1. **Not Connected**: 지갑 연결 프롬프트
2. **Not Registered**: 등록 폼
3. **Registered**: 관리 패널

### 컴포넌트 구조
```
AdminPage
├── NotConnectedState
│   └── ConnectPrompt
├── NotRegisteredState
│   └── RegistrationCard
│       └── RegistrationForm
│           ├── Layer2AddressInput (isAddress 검증)
│           ├── OperatorManagerInput (isAddress 검증)
│           ├── CommissionInput (0-30% 검증)
│           └── SubmitButton
└── RegisteredState
    ├── SequencerStatusCard
    │   ├── Address
    │   ├── Layer2
    │   ├── Commission
    │   ├── TotalStaked
    │   ├── AutoTrigger (NEW) (on/off 상태)
    │   └── TotalCommission (청구 가능)
    ├── ManagementCards
    │   ├── UpdateCommissionCard
    │   │   ├── CurrentCommission
    │   │   ├── NewCommissionInput (0-30%)
    │   │   └── UpdateButton
    │   ├── ClaimCommissionCard
    │   │   ├── ClaimableAmount
    │   │   └── ClaimButton (0이면 비활성화)
    │   └── AutoTriggerCard (NEW)
    │       ├── CurrentStatus
    │       ├── Toggle
    │       └── Description
    └── DangerZoneCard
        ├── WarningBanner
        ├── Description
        └── DeregisterButton
            └── 조건: totalStaked === 0n 일 때만 활성화
```

### 등록 폼 검증
```typescript
const validateRegistration = (form: RegistrationForm) => {
  if (!isAddress(form.layer2Address)) {
    return { valid: false, error: 'Invalid Layer2 address' };
  }
  if (!isAddress(form.operatorManagerAddress)) {
    return { valid: false, error: 'Invalid OperatorManager address' };
  }
  const commission = parseFloat(form.commission);
  if (isNaN(commission) || commission < 0 || commission > 30) {
    return { valid: false, error: 'Commission must be 0-30%' };
  }
  return { valid: true };
};
```

### 사용자 플로우

**Flow 1: 시퀀서로 등록**
1. Layer2 주소 입력
2. OperatorManager 주소 입력
3. 커미션 비율 입력 (0-30%)
4. "Register Sequencer" 클릭
5. 입력값 검증 (유효하지 않으면 에러 표시)
6. `registerSequencer(layer2, operatorManager, commissionBps)` 트랜잭션
7. 성공 시: Toast, 시퀀서 정보 다시 가져오기, 관리 패널 표시

**Flow 2: 커미션 업데이트**
1. 새 커미션 비율 입력
2. "Update Commission" 클릭
3. 검증 (0-30%)
4. `updateCommission(newCommissionBps)` 트랜잭션
5. 성공 시: Toast, 데이터 새로고침

**Flow 3: 커미션 청구**
1. 청구 가능 금액 확인
2. "Claim Commission" 클릭 (0이면 비활성화)
3. `claimCommission()` 트랜잭션
4. 성공 시: Toast, totalCommission 리셋

**Flow 4: Auto Trigger 토글 (NEW)**
1. 현재 auto-trigger 상태 확인
2. 토글/버튼 클릭
3. `setAutoTrigger(!currentStatus)` 트랜잭션
4. 성공 시: Toast, 상태 업데이트됨

**Flow 5: 시퀀서 탈퇴**
1. Danger Zone에서 "Deregister Sequencer" 클릭
2. 확인 대화상자: "Are you sure?"
3. `deregisterSequencer()` 트랜잭션 (totalStaked = 0일 때만)
4. 성공 시: Toast, 등록 폼 표시

### 탈퇴 확인 다이얼로그
```
┌────────────────────────────────────┐
│ Confirm Deregistration           X │
├────────────────────────────────────┤
│ ⚠ Warning                          │
│                                    │
│ Are you sure you want to           │
│ deregister as a sequencer?         │
│                                    │
│ This action cannot be undone.      │
│ You will need to re-register if    │
│ you want to accept delegations     │
│ again.                             │
│                                    │
├────────────────────────────────────┤
│    [Cancel]    [Deregister]        │
└────────────────────────────────────┘
```

### 에러 상태
| 에러 | 처리 |
|------|------|
| 유효하지 않은 Layer2 주소 | Toast: "Invalid Layer2 address" |
| 유효하지 않은 OperatorManager | Toast: "Invalid OperatorManager address" |
| 커미션 범위 초과 | Toast: "Commission must be 0-30%" |
| Layer2 이미 등록됨 | Toast: "This Layer2 is already registered" |
| 트랜잭션 실패 | 에러 메시지가 포함된 Toast |
| 스테이크가 있어 탈퇴 불가 | 버튼 비활성화 + 이유 설명 툴팁 |

### 반응형 설계
| 브레이크포인트 | 레이아웃 변화 |
|----------------|---------------|
| Mobile (<768px) | 전체 너비 카드, 모두 스택 |
| Tablet (768-1024px) | 2열 관리 카드 |
| Desktop (>1024px) | 2열 관리 카드 |

---

## 신규 모달 사양

### ClaimRewardsModal (NEW)
```
┌────────────────────────────────────┐
│ Claim Rewards                    X │
├────────────────────────────────────┤
│ Available Rewards                  │
│ ┌────────────────────────────────┐ │
│ │ 12.3456 WTON                   │ │
│ └────────────────────────────────┘ │
│                                    │
│ You will receive WTON rewards to   │
│ your wallet.                       │
├────────────────────────────────────┤
│        [Cancel]    [Claim]         │
└────────────────────────────────────┘
```

**파일**: `src/components/features/staking/ClaimRewardsModal.tsx`
**트리거**: "Claim" 버튼
**데이터**: `usePendingRewards(user, sequencer)` - 청구 가능 금액
**Hook**: `useClaimRewards()` → `claimRewards(sequencer)`

### WithdrawModal (NEW)
```
┌────────────────────────────────────┐
│ Withdraw                         X │
├────────────────────────────────────┤
│ Sequencer: 0x7099...79C8          │
│                                    │
│ Available to Withdraw              │
│ ┌────────────────────────────────┐ │
│ │ 50.0000 TON                    │ │
│ └────────────────────────────────┘ │
│                                    │
│ ✓ Unbonding period complete        │
│                                    │
│ Your TON will be returned to your  │
│ wallet.                            │
├────────────────────────────────────┤
│      [Cancel]    [Withdraw]        │
└────────────────────────────────────┘
```

**파일**: `src/components/features/staking/WithdrawModal.tsx`
**트리거**: "Withdraw" 버튼 (unbonding 완료 시)
**데이터**: `useStakeInfo(user, sequencer)` - 대기 중 언스테이크 금액
**Hook**: `useWithdraw()` → `withdraw(sequencer)`
**조건**: `unstakeTime + unbondingPeriod <= now`

### RedelegateModal (NEW)
```
┌────────────────────────────────────┐
│ Redelegate                       X │
├────────────────────────────────────┤
│ From: 0x7099...79C8               │
│ Current Stake: 100 TON             │
│                                    │
│ To Sequencer                       │
│ ┌────────────────────────────────┐ │
│ │ Select sequencer...        ▼  │ │
│ └────────────────────────────────┘ │
│                                    │
│ Amount                             │
│ ┌────────────────────────────────┐ │
│ │ 0.0                       MAX │ │
│ └────────────────────────────────┘ │
│                                    │
│ ℹ No unbonding period for         │
│   redelegation                     │
├────────────────────────────────────┤
│      [Cancel]    [Redelegate]      │
└────────────────────────────────────┘
```

**파일**: `src/components/features/staking/RedelegateModal.tsx`
**트리거**: "Redelegate" 버튼
**데이터**:
- `useSequencerList()` - 대상 시퀀서 옵션
- `useStakeInfo(user, fromSequencer)` - 현재 스테이크
**상태**:
- `toSequencer: Address | null` - 선택된 대상
- `amount: string` - 입력 값
**Hook**: `useRedelegate()` → `redelegate(fromSeq, toSeq, amount)`
**특징**: 즉시 이동 (unbonding 기간 없음)

---

## UI Store 업데이트 필요

```typescript
// src/stores/ui.ts
interface UIState {
  // 기존
  selectedSequencer: Address | null;
  isStakeModalOpen: boolean;
  isUnstakeModalOpen: boolean;

  // 신규
  isClaimModalOpen: boolean;
  isWithdrawModalOpen: boolean;
  isRedelegateModalOpen: boolean;

  // Actions
  openClaimModal: (sequencer: Address) => void;
  closeClaimModal: () => void;
  openWithdrawModal: (sequencer: Address) => void;
  closeWithdrawModal: () => void;
  openRedelegateModal: (sequencer: Address) => void;
  closeRedelegateModal: () => void;
}
```

---

## 누락된 기능 구현 우선순위

| 기능 | 우선순위 | 작업량 | 위치 |
|------|----------|--------|------|
| Withdraw 버튼 + 모달 | **높음** | 중간 | Dashboard, Detail |
| Claim Rewards 버튼 | **높음** | 낮음 | Dashboard, Detail |
| Countdown 타이머 | **높음** | 낮음 | StakePositionCard |
| Redelegate 모달 | **중간** | 중간 | Dashboard, Detail |
| Filter 탭 (Dashboard) | 낮음 | 낮음 | Dashboard |
| Sort/Filter (Sequencers) | 낮음 | 중간 | Sequencers page |
| Auto-trigger 토글 | 낮음 | 낮음 | Admin page |
| Home 통계 실데이터 | 낮음 | 낮음 | Home page |

> **참고**: Claim All (일괄 청구) 및 Activity History는 미구현/Phase 2로 연기

---

## 결정 사항 (확정)

| 항목 | 결정 | 비고 |
|------|------|------|
| **Withdraw 플로우** | 수동 액션 필요 | 카운트다운 완료 후 사용자가 Withdraw 버튼 클릭 |
| **Redelegate 위치** | Dashboard + Detail 모두 | 두 페이지에서 모두 접근 가능 |
| **Batch Claim** | 미구현 | 개별 시퀀서별 청구만 지원 |
| **Activity History** | Phase 2로 연기 | 인덱서 구축 후 추가 |
| **보상 표시** | 예상 보상만 | APY 계산 없이 estimateSeigniorage 결과만 표시 |
| **실시간 업데이트** | Polling (30초) + Optimistic Updates | WebSocket 대신 단순한 폴링 방식 |

---

## 검증 방법

### 기능 테스트
1. 각 페이지 로딩 및 데이터 표시 확인
2. 지갑 연결/해제 시 UI 상태 변화 확인
3. 모든 모달 열기/닫기 동작 확인
4. 트랜잭션 성공/실패 시 피드백 확인

### 엣지 케이스 테스트
1. 잔액 0, 보상 0, 포지션 없음 상태
2. Unbonding 기간 중 출금 시도
3. 자격 미충족 시퀀서 표시
4. 네트워크 에러 처리

### 반응형 테스트
1. Mobile (< 768px)
2. Tablet (768-1024px)
3. Desktop (> 1024px)
