# Delegate Staking

Tokamak Network V3를 위한 위임 스테이킹(Delegate Staking) 구현체입니다.

## 개요

Tokamak Network V3에서는 시뇨리지 분배 기준이 **Bridged TON**으로 변경됩니다. 일반 사용자가 직접 스테이킹하여 보상을 받을 수 없게 됨에 따라, **시퀀서에게 TON을 위임하여 간접적으로 시뇨리지 보상을 받을 수 있는 구조**를 제공합니다.

### 주요 기능

- **스테이킹**: 사용자가 TON을 시퀀서에게 위임
- **언스테이킹**: 언본딩 기간 후 TON 출금
- **리델리게이션**: 시퀀서 간 위임 이동 (즉시 처리)
- **보상 분배**: MasterChef 패턴 기반 WTON 보상 분배
- **커미션**: 시퀀서가 보상의 일정 비율을 수수료로 수취
- **자동 트리거**: Keeper 패턴 기반 시뇨리지 자동 분배
- **비상 탈출**: L2 장애 시 Emergency Exit 메커니즘

## 컨트랙트 구조

### V3 통합 버전 (권장)

```
┌─────────────────────────────────────────────────────────────────────┐
│                           L1 (Ethereum)                              │
│                                                                      │
│  ┌──────────────┐     ┌─────────────────────┐     ┌──────────────┐ │
│  │ SeigManager  │────►│  DelegateStakingV3  │◄────│ DelegateTrigger│
│  │    (V3)      │     │                     │     │   (Keeper)    │
│  └──────────────┘     └──────────┬──────────┘     └──────────────┘ │
│                                  │                                   │
│  ┌──────────────┐               │                                   │
│  │OperatorMgr   │◄──────────────┘                                   │
│  │ (Per L2)     │                                                   │
│  └──────────────┘                                                   │
│                                                                      │
│   User ──TON──► DelegateStakingV3 ◄──WTON── OperatorManager        │
│     ▲                   │                                           │
│     │                   │                                           │
│     └──── WTON ─────────┘ (rewards)                                 │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### 컨트랙트 목록

| 컨트랙트 | 설명 | 상태 |
|----------|------|------|
| `DelegateStakingV3.sol` | V3 통합 메인 컨트랙트 | ✅ 완료 |
| `DelegateTrigger.sol` | 시뇨리지 자동 트리거 | ✅ 완료 |
| `DelegateStakingMVP.sol` | MVP 버전 (수동 분배) | ✅ 완료 |

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

### V3 Dependencies
- ton-staking-v2 (ton-staking-v3/dev branch)

## 설치

```bash
# 저장소 클론
git clone https://github.com/tokamak-network/delegate-staking-mvp.git
cd delegate-staking-mvp

# 의존성 설치
npm install

# Git submodules 초기화 (ton-staking-v2)
git submodule update --init --recursive
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
forge build

# 또는 npm script
npm run build:forge
```

### 테스트

```bash
# 전체 테스트
forge test

# V3 테스트만
forge test --match-path "test/DelegateStakingV3.t.sol" -vvv

# MVP 테스트만
forge test --match-path "test/DelegateStakingMVP.t.sol" -vvv

# 가스 리포트
forge test --gas-report

# 커버리지
forge coverage
```

### 로컬 배포

```bash
# Anvil 실행 (별도 터미널)
anvil

# 로컬 배포
forge script script/DeployLocal.s.sol --rpc-url local --broadcast
```

### 프론트엔드 개발

```bash
npm run dev       # 개발 서버
npm run build:next # 빌드
npm run start     # 프로덕션
```

## 스마트 컨트랙트

### DelegateStakingV3 (V3 통합 버전)

#### 시퀀서 함수

| 함수 | 설명 |
|------|------|
| `registerSequencer(layer2, operatorManager, commission)` | 시퀀서 등록 (V3 연동) |
| `deregisterSequencer()` | 시퀀서 등록 해제 |
| `updateCommission(newCommission)` | 커미션 변경 |
| `setAutoTrigger(enabled)` | 자동 트리거 활성화 |
| `receiveReward(amount)` | 보상 수동 수령 |
| `claimCommission()` | 커미션 출금 |

#### 위임자 함수

| 함수 | 설명 |
|------|------|
| `stake(sequencer, amount)` | TON 스테이킹 |
| `unstake(sequencer, amount)` | 언스테이킹 요청 |
| `withdraw(sequencer)` | 언본딩 완료 후 출금 |
| `claimRewards(sequencer)` | 보상 수령 |
| `redelegate(from, to, amount)` | 시퀀서 간 위임 이동 |

#### 트리거 함수

| 함수 | 설명 |
|------|------|
| `triggerSeigniorage(sequencer)` | 시뇨리지 트리거 |
| `batchTriggerSeigniorage(sequencers)` | 배치 트리거 |

#### 비상 함수

| 함수 | 설명 |
|------|------|
| `activateEmergency(layer2)` | 비상 모드 활성화 |
| `deactivateEmergency(layer2)` | 비상 모드 해제 |
| `emergencyWithdraw(sequencer)` | 비상 출금 |

#### 조회 함수

| 함수 | 설명 |
|------|------|
| `getStakeInfo(staker, sequencer)` | 스테이킹 정보 조회 |
| `getSequencerInfo(sequencer)` | 시퀀서 정보 조회 |
| `pendingRewards(staker, sequencer)` | 미수령 보상 조회 |
| `getSequencerList()` | 등록된 시퀀서 목록 |
| `checkLayer2Eligibility(layer2)` | L2 자격 요건 확인 |
| `estimateSeigniorage(sequencer)` | 예상 시뇨리지 조회 |
| `getEmergencyConfig(layer2)` | 비상 설정 조회 |

### DelegateTrigger (Keeper 컨트랙트)

| 함수 | 설명 |
|------|------|
| `registerTrigger(...)` | 트리거 설정 등록 |
| `trigger(triggerId)` | 단일 트리거 실행 |
| `batchTrigger(triggerIds)` | 배치 트리거 실행 |
| `getReadyTriggers()` | 실행 가능한 트리거 목록 |
| `setKeeperReward(amount)` | Keeper 보상 설정 |

### 상수

| 상수 | 값 | 설명 |
|------|-----|------|
| `MAX_COMMISSION` | 3000 (30%) | 최대 커미션 |
| `RAY` | 1e27 | WTON 정밀도 |
| `DEFAULT_EMERGENCY_COOLDOWN` | 3 days | 비상 쿨다운 |

## 프로젝트 구조

```
delegate-staking/
├── contracts/                    # Solidity 컨트랙트
│   ├── DelegateStakingV3.sol     # V3 통합 버전
│   ├── DelegateTrigger.sol       # 자동 트리거
│   ├── DelegateStakingMVP.sol    # MVP 버전
│   └── interfaces/
│       ├── IDelegateStakingV3.sol
│       └── IDelegateStakingMVP.sol
├── lib/
│   └── ton-staking-v2/           # V3 의존성 (submodule)
├── script/                       # 배포 스크립트
├── test/                         # Foundry 테스트
│   ├── DelegateStakingV3.t.sol   # V3 테스트 (31개)
│   ├── DelegateStakingMVP.t.sol  # MVP 테스트
│   └── mocks/
├── src/                          # Next.js 프론트엔드
├── docs/                         # 문서
│   ├── DESIGN.md
│   ├── DESIGN_EN.md
│   ├── v3-discussion-result.md   # V3 통합 논의 결과
│   └── ...
├── foundry.toml
├── hardhat.config.ts
└── package.json
```

## V3 통합

### SeigManager 연동

```solidity
// L2 자격 요건 확인
(bool eligible, uint256 required, uint256 current) =
    staking.checkLayer2Eligibility(layer2);

// 예상 시뇨리지 조회
(uint256 seqReward, uint256 valReward) =
    staking.estimateSeigniorage(sequencer);
```

### OperatorManager 연동

시퀀서 등록 시 OperatorManager 주소 필요:

```solidity
staking.registerSequencer(
    layer2Address,
    operatorManagerAddress,
    1000 // 10% commission
);
```

### 자동 트리거 설정

```solidity
// 시퀀서: 자동 트리거 활성화
staking.setAutoTrigger(true);

// Keeper: 트리거 실행
staking.triggerSeigniorage(sequencer);

// 또는 배치 트리거
staking.batchTriggerSeigniorage(sequencerList);
```

## 비상 탈출 메커니즘

L2 장애 발생 시:

1. Guardian이 비상 모드 활성화
2. 쿨다운 기간 (기본 3일) 대기
3. 사용자가 즉시 출금 가능

```solidity
// Guardian: 비상 모드 활성화
staking.activateEmergency(layer2);

// 사용자: 쿨다운 후 즉시 출금
staking.emergencyWithdraw(sequencer);
```

## 문서

- [설계 문서 (한글)](./docs/DESIGN.md)
- [설계 문서 (영문)](./docs/DESIGN_EN.md)
- [V3 통합 논의 결과](./docs/v3-discussion-result.md)
- [개발 고려사항](./docs/DEVELOPMENT-CONSIDERATIONS.md)
- [프론트엔드 아키텍처](./docs/FRONTEND-ARCHITECTURE.md)

## 보안 고려사항

- **Reentrancy Guard**: 모든 상태 변경 함수에 적용
- **SafeERC20**: 토큰 전송 시 사용
- **Checks-Effects-Interactions**: 패턴 준수
- **커미션 상한**: 최대 30%로 제한
- **비상 쿨다운**: 3일 대기 후 비상 출금
- **Guardian 시스템**: L2별 Guardian 설정 가능

## 테스트 현황

| 테스트 스위트 | 테스트 수 | 상태 |
|---------------|----------|------|
| DelegateStakingV3 | 31 | ✅ All Pass |
| DelegateStakingMVP | - | ✅ All Pass |

## 라이선스

MIT License

## 참고 자료

- [Tokamak Economics Whitepaper V3](./docs/Tokamak_Economics_Whitepaper_V3.pdf)
- [Staking V2 Documentation](./docs/StakingV2.md)
- [ton-staking-v2 Repository](https://github.com/tokamak-network/ton-staking-v2)
