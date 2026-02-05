# Delegate Staking 프로젝트 Handoff

> **마지막 업데이트**: 2025-02-06
> **브랜치**: master
> **최신 커밋**: `3c91862` - fix: Migrate from OpenZeppelin v5 to v4.9.6

## 프로젝트 개요

Tokamak Network V3의 **Sequencer Delegate Staking** 시스템을 위한 스마트 컨트랙트 및 웹 프론트엔드.

## 최근 완료된 작업

### 1. Withdraw UX 개선 (커밋: `33ac91e`)
- **StakePositionCard 컴포넌트 추출**: `src/components/features/staking/StakePositionCard.tsx`
- **Withdraw 버튼**: Pending Unstake가 있으면 항상 표시 (unbonding 중에는 비활성화)
- **툴팁**: 정확한 출금 가능 시간 표시
- **적용 페이지**: `/dashboard`, `/sequencers/[address]`

### 2. Dashboard 필터 기능
- **새 훅**: `src/hooks/useFilteredSequencers.ts`
- **필터 탭**: All / Active / Pending
  - All: `stakedAmount > 0 || unstakeAmount > 0` (스테이킹/언스테이킹이 있는 것만)
  - Active: `stakedAmount > 0`
  - Pending: `unstakeAmount > 0`
- **중요**: 스테이킹을 하지 않은 시퀀서(amount=0, unstakeAmount=0)는 표시하지 않음

### 3. 테스트 환경 설정
- **Vitest 설정**: `vitest.config.ts`
- **테스트 파일**:
  - `src/components/features/staking/StakePositionCard.test.tsx` (9 tests)
  - `src/hooks/useFilteredSequencers.test.ts` (8 tests)
- **총 17개 테스트 통과**

### 4. Unbonding Period 변경 (테스트용)
- **컨트랙트**: `MIN_UNBONDING_PERIOD = 5 minutes` (기존 1 day)
- **로컬 배포**: `unbondingPeriod = 5 minutes`
- **파일**:
  - `contracts/DelegateStakingV3Upgradeable.sol`
  - `script/DeployLocalV3Upgradeable.s.sol`
  - `test/DelegateStakingV3Upgradeable.t.sol`

## 현재 배포 상태 (Anvil 로컬)

| 컨트랙트 | 주소 |
|---------|------|
| Proxy (DelegateStakingV3) | `0x8198f5d8F8CfFE8f9C413d98a0A55aEB8ab9FbB7` |
| Implementation | `0x36b58F5C1969B7b6591D752ea6F5486D069010AB` |
| TON | `0x04C89607413713Ec9775E14b954286519d836FEf` |
| WTON | `0x4C4a2f8c81640e47606d3fd77B353E87Ba015584` |
| DelegateTrigger | `0x0355B7B8cb128fA5692729Ab3AAa199C1753f726` |

**Unbonding Period**: 5분

## 주요 파일 구조

```
src/
├── app/
│   ├── dashboard/page.tsx      # 대시보드 (필터 기능 포함)
│   ├── sequencers/
│   │   └── [address]/page.tsx  # 시퀀서 상세
│   └── page.tsx                # 홈
├── components/features/staking/
│   ├── StakePositionCard.tsx   # 포지션 카드 (NEW)
│   ├── StakeModal.tsx
│   ├── UnstakeModal.tsx
│   ├── WithdrawModal.tsx
│   ├── ClaimRewardsModal.tsx
│   ├── RedelegateModal.tsx
│   └── UnstakeCountdown.tsx
├── hooks/
│   ├── useStaking.ts           # 스테이킹 훅 (useMultipleStakeInfo 추가)
│   └── useFilteredSequencers.ts # 필터링 훅 (NEW)
└── stores/
    └── ui.ts                   # UI 상태 (모달 관리)
```

## 다음 작업 후보

### MVP 남은 항목 (tasks/frontend-plan.md 참조)
- [ ] Phase 5: 대시보드 & 관리
  - [ ] 활동 로그 (최근 트랜잭션)
  - [ ] Sequencer Admin 페이지 완성
- [ ] Phase 6: 테스트 & 최적화
  - [ ] E2E 테스트 (Playwright)
  - [ ] 성능 최적화
  - [ ] 배포 설정

### 개선 사항
- APY 계산 및 표시
- 일괄 청구 (Batch Claim) 기능
- 다크/라이트 모드 토글

## 명령어

```bash
# 프론트엔드 개발 서버
npm run dev

# UI 테스트
npm run test:ui:run

# 스마트 컨트랙트 빌드
forge build

# 스마트 컨트랙트 테스트
forge test

# Anvil 로컬 배포
forge script script/DeployLocalV3Upgradeable.s.sol --rpc-url http://127.0.0.1:8545 --broadcast
```

## 설계 문서

- `docs/design/FRONTEND-PRD.md` - 프론트엔드 요구사항 (Withdraw UX 상세 추가됨)
- `docs/design/FRONTEND-ARCHITECTURE.md` - 아키텍처
- `tasks/frontend-plan.md` - 개발 계획

## 참고사항

- **프로덕션 배포 시**: `MIN_UNBONDING_PERIOD`를 1 day 이상으로 복원 필요
- **테스트 계정**: Anvil 기본 계정 사용 (Account #0~#5)
- **환경변수**: `ANTHROPIC_SMALL_FAST_MODEL=claude-haiku-4-5`
