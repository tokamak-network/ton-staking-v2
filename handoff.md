# Handoff Document - Delegate Staking Frontend

## 프로젝트 개요
Tokamak Network V3 Delegate Staking dApp 프론트엔드 개발

## 완료된 작업

### 1. useUserStakingStats 훅 수정 (React Hooks 규칙 위반 수정)

**문제**: 기존 코드가 `map` 내부에서 훅을 호출하여 React 규칙 위반

**해결**: `useReadContracts`를 사용한 배치 읽기로 변경

**파일**: `src/hooks/useStaking.ts`

```typescript
export function useUserStakingStats(
  userAddress: Address | undefined,
  sequencers: readonly string[] | undefined
) {
  const stakingContractAddress = useStakingContract();

  const stakeInfoContracts = useMemo(() => {
    if (!userAddress || !sequencers || sequencers.length === 0) return [];
    return sequencers.map((seq) => ({
      address: stakingContractAddress,
      abi: DELEGATE_STAKING_ABI,
      functionName: 'getStakeInfo' as const,
      args: [userAddress, seq as Address],
    }));
  }, [userAddress, sequencers, stakingContractAddress]);

  // ... useReadContracts로 배치 읽기
}
```

### 2. Wagmi 체인 설정 수정 (데이터 로딩 문제 해결)

**문제**: 지갑 연결 없이 접속 시 wagmi가 mainnet(체인 ID 1)을 기본으로 사용하여 hardhat 로컬 노드 데이터를 읽지 못함

**해결**: 개발 모드에서 hardhat을 첫 번째 체인으로 설정

**파일**: `src/lib/wagmi.ts`

```typescript
const isDev = process.env.NODE_ENV === 'development';

export const config = getDefaultConfig({
  appName: 'Tokamak Delegate Staking',
  projectId: process.env.NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID || 'demo-project-id',
  chains: isDev ? [hardhat, mainnet, sepolia] : [mainnet, sepolia, hardhat],
  ssr: true,
});
```

### 3. E2E 테스트 작성

**파일**: `tests/e2e/quick_test.py`

- Playwright + Chromium 사용
- `--no-sandbox` 플래그로 Windows 호환성 확보
- `localhost` 대신 `127.0.0.1` 사용 (Playwright 연결 문제 해결)

**테스트 결과**:
- Sequencers 페이지: 2개 시퀀서 표시 (Total Staked, Commission, Layer2)
- Dashboard: "Connect Your Wallet" 메시지 (지갑 미연결 시 정상)
- Sequencer Detail: Economics & Rewards 섹션 포함 모든 데이터 표시

## 현재 상태

### 작동 확인된 기능
- ✅ Sequencers 목록 페이지 - 실제 데이터 표시
- ✅ Sequencer 상세 페이지 - 모든 섹션 작동
- ✅ Dashboard - 지갑 연결 안내 표시 (미연결 시)

### 테스트 실행 방법

```bash
# 1. Hardhat 노드 실행 (터미널 1)
npx hardhat node

# 2. 컨트랙트 배포 (터미널 2)
npx hardhat run scripts/deploy-local.ts --network localhost

# 3. 프론트엔드 실행 (터미널 3)
npm run dev -- -p 4000

# 4. E2E 테스트 실행 (터미널 4)
python tests/e2e/quick_test.py
```

### 스크린샷 위치
`tests/e2e/screenshots/`
- `01_sequencers.png` - Sequencers 목록
- `02_dashboard.png` - Dashboard
- `03_detail.png` - Sequencer 상세

## 남은 작업 / 확인 필요 사항

### 지갑 연결 후 테스트 필요
- Dashboard의 "Total Staked", "Pending Unstake", "Claimable Rewards" 값 표시 확인
- 실제 스테이킹/언스테이킹 트랜잭션 테스트

### 포트 관련 참고사항
- 포트 3000, 3001, 3005가 사용 중일 수 있음
- 포트 4000 사용 권장
- Playwright에서 `localhost` 대신 `127.0.0.1` 사용 필수

## 주요 파일 목록

| 파일 | 설명 |
|------|------|
| `src/hooks/useStaking.ts` | 스테이킹 관련 커스텀 훅 (useUserStakingStats 포함) |
| `src/lib/wagmi.ts` | Wagmi/RainbowKit 설정 |
| `src/app/dashboard/page.tsx` | Dashboard 페이지 |
| `src/app/sequencers/page.tsx` | Sequencers 목록 페이지 |
| `src/app/sequencers/[address]/page.tsx` | Sequencer 상세 페이지 |
| `tests/e2e/quick_test.py` | E2E 테스트 스크립트 |

## 트러블슈팅

### 데이터가 로딩되지 않을 때
1. Hardhat 노드가 실행 중인지 확인
2. 컨트랙트가 배포되었는지 확인
3. `src/lib/wagmi.ts`에서 hardhat이 첫 번째 체인인지 확인

### Playwright 테스트 실패 시
1. `127.0.0.1` 사용 (localhost X)
2. Chromium에 `--no-sandbox` 플래그 추가
3. 서버가 실행 중인지 curl로 확인: `curl http://127.0.0.1:4000`

---
*마지막 업데이트: 2026-02-04*
