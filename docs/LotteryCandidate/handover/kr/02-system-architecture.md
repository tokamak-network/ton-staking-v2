# 2. 시스템 아키텍처

[← 목차로 돌아가기](./README.md) | [← 이전: 프로젝트 개요](./01-project-overview.md)

---

## 2.1 전체 구조 설명

LotteryCandidate는 Tokamak Network의 TON Staking V3 시스템 위에 구축된 확장 모듈이다.

```
┌─────────────────────────────────────────────────────────────────┐
│                         사용자 (EOA)                             │
│                    MetaMask / Web3 Wallet                        │
└────────┬──────────────────────────────────────────┬─────────────┘
         │ depositTON / depositWTON                  │ enterLottery
         │ requestWithdrawal                         │ updateSeigniorage
         ▼                                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                   LotteryCandidateProxy                         │
│                 (Proxy → delegatecall)                           │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │              LotteryCandidate (Implementation)             │  │
│  │                                                           │  │
│  │  _balances: 사용자별 내부 잔액 (WTON, 27 decimals)         │  │
│  │  totalDeposited: 전체 예치 합계                             │  │
│  │  currentRound: 현재 복권 라운드                              │  │
│  │  _roundPrizePool: 라운드별 상금 풀                           │  │
│  │  withdrawalRequests[]: 출금 요청 큐                          │  │
│  └───────────┬───────────────────────┬───────────────────────┘  │
└──────────────┼───────────────────────┼──────────────────────────┘
               │                       │
     ┌─────────▼──────────┐  ┌────────▼─────────────┐
     │   DepositManager   │  │     SeigManager       │
     │  (실제 자산 보관)    │  │  (시뇨리지 생성)       │
     │                    │  │                       │
     │  deposit()         │  │  updateSeigniorage()  │
     │  requestWithdrawal │  │  coinages()           │
     │  processRequest()  │  │                       │
     └────────────────────┘  └───────────────────────┘
               │                       │
     ┌─────────▼──────────┐  ┌────────▼─────────────┐
     │    TON / WTON      │  │   Coinage Token       │
     │  (ERC20 토큰)       │  │  (L2별 스테이킹       │
     │                    │  │   영수증 토큰)          │
     │  TON: 18 decimals  │  │  27 decimals          │
     │  WTON: 27 decimals │  │  totalSupply 증가 =    │
     │  1 TON = 1e9 WTON  │  │  시뇨리지 발생         │
     └────────────────────┘  └───────────────────────┘
               │
     ┌─────────▼──────────────────────────────────────┐
     │              DAOCommittee_V1                     │
     │  (DAO 거버넌스 허브)                              │
     │                                                 │
     │  createLotteryCandidate() → Factory 호출         │
     │  changeMember() / retireMember()                │
     │  castVote() / executeAgenda()                   │
     │  claimActivityReward()                          │
     └─────────────────────────────────────────────────┘
```

## 2.2 컨트랙트 배포 흐름

```
DAOCommittee_V1.createLotteryCandidate(memo)
    │
    ▼
LotteryCandidateFactory.deploy()
    │
    ├── new LotteryCandidateProxy() 배포
    ├── proxy.upgradeTo(lotteryCandidateImp) 설정
    ├── LotteryCandidate.initialize(...) 호출
    ├── Layer2Registry.registerAndDeployCoinage() 등록
    └── proxy admin → committee로 이전
```

## 2.3 사용 기술 스택

| 구분 | 기술 | 버전 |
|------|------|------|
| **스마트 컨트랙트 언어** | Solidity | 0.8.19 (주요), 0.8.4 (LotteryCandidate) |
| **컨트랙트 프레임워크** | Foundry (Forge) | 최신 |
| **보조 빌드** | Hardhat | 2.28.2 |
| **프론트엔드 프레임워크** | React | 18.2.0 |
| **번들러** | Vite | 5.0.8 |
| **프론트엔드 언어** | TypeScript | 5.2.2 |
| **CSS 프레임워크** | Tailwind CSS | 3.4.0 |
| **Web3 라이브러리** | wagmi / viem | 2.5.0 / 2.7.0 |
| **상태 관리** | TanStack React Query | 5.17.0 |
| **로컬 블록체인** | Anvil | (Foundry 내장) |
| **E2E 테스트 언어** | Go | 1.22.6 |
| **컨트랙트 라이브러리** | OpenZeppelin | git submodule |
| **L2 인터페이스** | Optimism (Tokamak fork) | feature/ton-staking-v3 브랜치 |

## 2.4 외부 의존성 (Git Submodules)

| 의존성 | 경로 | 브랜치/버전 | 용도 |
|--------|------|------------|------|
| forge-std | `lib/forge-std` | - | Foundry 표준 테스트 라이브러리 |
| openzeppelin-contracts | `lib/openzeppelin-contracts` | - | ERC20, SafeERC20, AccessControl |
| optimism | `lib/optimism` | `feature/ton-staking-v3` | L1/L2 인터페이스 (DisputeGameFactory, SystemConfig 등) |
| tokamak-dao-contracts | `lib/tokamak-dao-contracts` | - | DAO 거버넌스 인터페이스 |

> **주의:** `lib/optimism` 서브모듈의 커밋을 변경할 때 반드시 `GIT_DIR` 명시적 지정이 필요하다. 그렇지 않으면 상위 레포의 HEAD가 변경될 위험이 있다. (README.md 참조)

## 2.5 토큰 체계

| 토큰 | Decimals | 설명 | 단위 변환 |
|------|----------|------|----------|
| TON | 18 | Tokamak Network 기본 토큰 | 1 TON = `1e18` wei |
| WTON | 27 | Wrapped TON (스테이킹 단위) | 1 WTON = `1e27` ray |
| Coinage | 27 | L2별 스테이킹 영수증 토큰 | totalSupply 증가 = 시뇨리지 |

**변환:** 1 TON = 1e9 WTON (내부적으로 `swapFromTON` 사용)

---

[다음: 디렉토리 구조 →](./03-directory-structure.md)
