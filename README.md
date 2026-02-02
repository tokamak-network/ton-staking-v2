# Delegate Staking MVP

Tokamak Network V3를 위한 위임 스테이킹(Delegate Staking) MVP 구현체입니다.

## 개요

Tokamak Network V3에서는 시뇨리지 분배 기준이 **Bridged TON**으로 변경됩니다. 일반 사용자가 직접 스테이킹하여 보상을 받을 수 없게 됨에 따라, **시퀀서에게 TON을 위임하여 간접적으로 시뇨리지 보상을 받을 수 있는 구조**를 제공합니다.

### 주요 기능

- **스테이킹**: 사용자가 TON을 시퀀서에게 위임
- **언스테이킹**: 언본딩 기간 후 TON 출금
- **리델리게이션**: 시퀀서 간 위임 이동 (즉시 처리)
- **보상 분배**: MasterChef 패턴 기반 WTON 보상 분배
- **커미션**: 시퀀서가 보상의 일정 비율을 수수료로 수취

## 아키텍처

```
┌─────────────────────────────────────────────────────────┐
│                      L1 (Ethereum)                       │
│                                                          │
│   User ──TON──► DelegateStakingMVP ◄──WTON── Sequencer  │
│     ▲                   │                                │
│     │                   │                                │
│     └──── WTON ─────────┘ (rewards)                     │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### 토큰 단위

| 토큰 | 소수점 | 용도 |
|------|--------|------|
| TON | 18 decimals | 스테이킹 |
| WTON | 27 decimals (RAY) | 보상 |

## 기술 스택

### Smart Contracts
- Solidity ^0.8.24
- OpenZeppelin Contracts v5
- Foundry (개발 & 테스트)
- Hardhat (추가 도구)

### Frontend
- Next.js 14 (App Router)
- React 18
- TypeScript
- RainbowKit + wagmi (지갑 연동)
- Tailwind CSS + shadcn/ui

## 설치

```bash
# 저장소 클론
git clone https://github.com/tokamak-network/delegate-staking-mvp.git
cd delegate-staking-mvp

# 의존성 설치
npm install

# Foundry 의존성 설치
forge install
```

## 환경 설정

`.env.example`을 복사하여 `.env` 파일을 생성합니다:

```bash
cp .env.example .env
```

필요한 환경 변수:

```env
# RPC URLs
MAINNET_RPC_URL=
SEPOLIA_RPC_URL=

# Private Keys (테스트용)
PRIVATE_KEY=

# Etherscan (검증용)
ETHERSCAN_API_KEY=

# Frontend
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=
```

## 개발

### 컨트랙트 빌드

```bash
# Foundry 빌드
npm run build:forge

# Hardhat 빌드
npm run build:hardhat

# 둘 다 빌드
npm run build
```

### 테스트

```bash
# 기본 테스트
npm run test

# 상세 출력
npm run test:v

# 가스 리포트
npm run test:gas

# 커버리지
npm run test:coverage
```

### 로컬 배포

```bash
# Anvil 실행 (별도 터미널)
npm run anvil

# 로컬 배포
npm run deploy:local

# 테스트 토큰 민팅
npm run mint:local
```

### 프론트엔드 개발

```bash
# 개발 서버
npm run dev

# 빌드
npm run build:next

# 프로덕션 실행
npm run start
```

## 스마트 컨트랙트

### DelegateStakingMVP

메인 컨트랙트로 다음 기능을 제공합니다:

#### 시퀀서 함수

| 함수 | 설명 |
|------|------|
| `registerSequencer(layer2, commission)` | 시퀀서 등록 |
| `deregisterSequencer()` | 시퀀서 등록 해제 |
| `updateCommission(newCommission)` | 커미션 변경 |
| `receiveReward(amount)` | 보상 수령 및 분배 |
| `claimCommission()` | 커미션 출금 |

#### 위임자 함수

| 함수 | 설명 |
|------|------|
| `stake(sequencer, amount)` | TON 스테이킹 |
| `unstake(sequencer, amount)` | 언스테이킹 요청 |
| `withdraw(sequencer)` | 언본딩 완료 후 출금 |
| `claimRewards(sequencer)` | 보상 수령 |
| `redelegate(from, to, amount)` | 시퀀서 간 위임 이동 |

#### 조회 함수

| 함수 | 설명 |
|------|------|
| `getStakeInfo(staker, sequencer)` | 스테이킹 정보 조회 |
| `getSequencerInfo(sequencer)` | 시퀀서 정보 조회 |
| `pendingRewards(staker, sequencer)` | 미수령 보상 조회 |
| `getSequencerList()` | 등록된 시퀀서 목록 |

### 상수

| 상수 | 값 | 설명 |
|------|-----|------|
| `MAX_COMMISSION` | 3000 (30%) | 최대 커미션 |
| `RAY` | 1e27 | WTON 정밀도 |

## 프로젝트 구조

```
delegate-staking-mvp/
├── contracts/                 # Solidity 컨트랙트
│   ├── DelegateStakingMVP.sol
│   └── interfaces/
├── script/                    # 배포 스크립트
│   ├── Deploy.s.sol
│   ├── DeployLocal.s.sol
│   └── MintTokens.s.sol
├── test/                      # Foundry 테스트
│   ├── DelegateStakingMVP.t.sol
│   └── mocks/
├── src/                       # Next.js 프론트엔드
│   ├── app/                   # App Router 페이지
│   ├── components/            # React 컴포넌트
│   ├── hooks/                 # 커스텀 훅
│   ├── lib/                   # 유틸리티
│   └── stores/                # Zustand 스토어
├── docs/                      # 문서
│   ├── DESIGN.md              # 설계 문서 (한글)
│   ├── DESIGN_EN.md           # 설계 문서 (영문)
│   └── ...
├── foundry.toml               # Foundry 설정
├── hardhat.config.ts          # Hardhat 설정
└── package.json
```

## 문서

- [설계 문서 (한글)](./docs/DESIGN.md)
- [설계 문서 (영문)](./docs/DESIGN_EN.md)
- [개발 고려사항](./docs/DEVELOPMENT-CONSIDERATIONS.md)
- [프론트엔드 아키텍처](./docs/FRONTEND-ARCHITECTURE.md)
- [V3 논의사항](./docs/V3-DISCUSSION-POINTS.md)

## 보안 고려사항

- **Reentrancy Guard**: 모든 상태 변경 함수에 적용
- **SafeERC20**: 토큰 전송 시 사용
- **Checks-Effects-Interactions**: 패턴 준수
- **커미션 상한**: 최대 30%로 제한
- **소유자 권한**: 긴급 출금 및 언본딩 기간 설정

## 라이선스

MIT License

## 참고 자료

- [Tokamak Economics Whitepaper V3](./docs/Tokamak_Economics_Whitepaper_V3.pdf)
- [Staking V2 Documentation](./docs/StakingV2.md)
