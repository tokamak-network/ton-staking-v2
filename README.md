# Delegate Staking

Tokamak Network V3를 위한 위임 스테이킹(Delegate Staking) 구현체입니다.

## 개요

Tokamak Network V3에서는 시뇨리지 분배 기준이 **Bridged TON**으로 변경됩니다. 일반 사용자가 직접 스테이킹하여 보상을 받을 수 없게 됨에 따라, **시퀀서에게 TON을 위임하여 간접적으로 시뇨리지 보상을 받을 수 있는 구조**를 제공합니다.

### 주요 기능

- **스테이킹**: 사용자가 TON을 시퀀서에게 위임
- **언스테이킹**: 언본딩 기간 후 TON 출금
- **리델리게이션**: 시퀀서 간 위임 이동 (즉시 처리)
- **보상 분배**: MasterChef 패턴 기반 WTON 보상 분배
- **커미션**: 시퀀서가 보상의 일정 비율을 수수료로 수취 (7일 타임락)
- **자동 트리거**: Keeper 패턴 기반 시뇨리지 자동 분배
- **비상 탈출**: L2 장애 시 Emergency Exit 메커니즘
- **업그레이드**: UUPS 프록시 패턴 지원

## 버전 히스토리

| 버전 | 주요 변경사항 |
|------|--------------|
| v1.3.0 | Low 이슈 해결 (코드 품질 개선, NatSpec, 상수화) |
| v1.2.0 | Medium 이슈 해결 (배치 제한, 이벤트 추가, O(1) 삭제) |
| v1.1.0 | High 이슈 해결 (커미션 타임락, 플래시론 보호, 최소 스테이크) |
| v1.0.0 | Critical 이슈 해결 (Pausable, Upgradeable, rescueTokens 보안) |

## 컨트랙트 구조

### V3 통합 버전 (권장)

```
┌─────────────────────────────────────────────────────────────────────┐
│                           L1 (Ethereum)                              │
│                                                                      │
│  ┌──────────────┐     ┌─────────────────────┐     ┌──────────────┐ │
│  │ SeigManager  │────►│  DelegateStakingV3  │◄────│ DelegateTrigger│
│  │    (V3)      │     │   (Upgradeable)     │     │   (Keeper)    │
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
| `DelegateStakingV3Upgradeable.sol` | V3 통합 UUPS 업그레이드 버전 **(권장)** | ✅ v1.3.0 |
| `DelegateStakingV3.sol` | V3 통합 일반 버전 | ✅ 완료 |
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
- OpenZeppelin Contracts v5 (Upgradeable)
- Foundry (개발 & 테스트)
- UUPS Proxy Pattern

### V3 Dependencies
- ton-staking-v2 (ton-staking-v3/dev branch)

## 설치

```bash
# 저장소 클론
git clone https://github.com/tokamak-network/delegate-staking.git
cd delegate-staking

# Git submodules 초기화 (ton-staking-v2)
git submodule update --init --recursive

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
```

## 개발

### 컨트랙트 빌드

```bash
forge build
```

### 테스트

```bash
# 전체 테스트 (300개)
forge test

# Upgradeable 버전 테스트
forge test --match-contract DelegateStakingV3Upgradeable -vvv

# V3 테스트
forge test --match-contract DelegateStakingV3Test -vvv

# 가스 리포트
forge test --gas-report

# 커버리지 (99.67%)
forge coverage
```

### 로컬 배포

```bash
# Anvil 실행 (별도 터미널)
anvil

# 로컬 V3 배포
forge script script/DeployLocalV3.s.sol --rpc-url local --broadcast
```

## 스마트 컨트랙트 API

### DelegateStakingV3Upgradeable (권장)

#### 상수

| 상수 | 값 | 설명 |
|------|-----|------|
| `MAX_COMMISSION` | 3000 (30%) | 최대 커미션 |
| `COMMISSION_TIMELOCK` | 7 days | 커미션 변경 타임락 |
| `STAKE_COOLDOWN` | 12 seconds | 플래시론 보호 쿨다운 |
| `DEFAULT_MIN_STAKE` | 100 TON | 기본 최소 스테이크 |
| `MAX_BATCH_SIZE` | 50 | 배치 작업 최대 크기 |
| `MIN_UNBONDING_PERIOD` | 1 day | 최소 언본딩 기간 |
| `MAX_UNBONDING_PERIOD` | 30 days | 최대 언본딩 기간 |
| `MIN_EMERGENCY_COOLDOWN` | 1 hour | 최소 비상 쿨다운 |
| `MAX_EMERGENCY_COOLDOWN` | 14 days | 최대 비상 쿨다운 |
| `DEFAULT_EMERGENCY_COOLDOWN` | 3 days | 기본 비상 쿨다운 |
| `RAY` | 1e27 | WTON 정밀도 |

#### 시퀀서 함수

| 함수 | 설명 |
|------|------|
| `registerSequencer(layer2, operatorManager, commission)` | 시퀀서 등록 (V3 연동) |
| `deregisterSequencer()` | 시퀀서 등록 해제 |
| `requestCommissionUpdate(newCommission)` | 커미션 변경 요청 (7일 타임락) |
| `applyCommissionUpdate()` | 커미션 변경 적용 |
| `cancelCommissionUpdate()` | 커미션 변경 취소 |
| `setAutoTrigger(enabled)` | 자동 트리거 활성화 |
| `receiveReward(amount)` | 보상 수동 수령 |
| `claimCommission()` | 커미션 출금 |

#### 위임자 함수

| 함수 | 설명 |
|------|------|
| `stake(sequencer, amount)` | TON 스테이킹 (최소 100 TON) |
| `unstake(sequencer, amount)` | 언스테이킹 요청 |
| `withdraw(sequencer)` | 언본딩 완료 후 출금 |
| `claimRewards(sequencer)` | 보상 수령 (12초 쿨다운) |
| `redelegate(from, to, amount)` | 시퀀서 간 위임 이동 |

#### 트리거 함수

| 함수 | 설명 |
|------|------|
| `triggerSeigniorage(sequencer)` | 시뇨리지 트리거 |
| `batchTriggerSeigniorage(sequencers)` | 배치 트리거 (최대 50개) |

#### 비상 함수

| 함수 | 설명 |
|------|------|
| `activateEmergency(layer2)` | 비상 모드 활성화 |
| `deactivateEmergency(layer2)` | 비상 모드 해제 |
| `emergencyWithdraw(sequencer)` | 비상 출금 (보상 포함) |

#### 관리자 함수

| 함수 | 설명 |
|------|------|
| `pause()` / `unpause()` | 컨트랙트 일시 정지 |
| `setUnbondingPeriod(period)` | 언본딩 기간 설정 |
| `setSeigManager(address)` | SeigManager 주소 설정 |
| `setLayer2Manager(address)` | Layer2Manager 주소 설정 |
| `setDefaultGuardian(address)` | 기본 Guardian 설정 |
| `setLayer2Guardian(layer2, guardian)` | L2별 Guardian 설정 |
| `setEmergencyCooldown(layer2, period)` | 비상 쿨다운 설정 |
| `setMinStakeAmount(amount)` | 최소 스테이크 설정 |
| `rescueTokens(token, to, amount)` | 잔류 토큰 회수 (TON/WTON 제외) |

#### 조회 함수

| 함수 | 반환값 |
|------|--------|
| `getStakeInfo(staker, sequencer)` | StakeInfo (amount, rewardDebt, unstakeAmount, unstakeTime) |
| `getSequencerInfo(sequencer)` | SequencerInfo (전체 시퀀서 정보) |
| `pendingRewards(staker, sequencer)` | 미수령 WTON 보상 |
| `getSequencerList()` | 등록된 시퀀서 목록 |
| `getSequencerCount()` | 등록된 시퀀서 수 |
| `getSequencerByLayer2(layer2)` | L2에 매핑된 시퀀서 |
| `getTotalStaked()` | 전체 스테이킹량 |
| `getPendingCommission(sequencer)` | 대기 중인 커미션 변경 정보 |
| `getEmergencyConfig(layer2)` | 비상 설정 정보 |
| `checkLayer2Eligibility(layer2)` | L2 자격 요건 확인 |
| `estimateSeigniorage(sequencer)` | 예상 시뇨리지 |
| `version()` | 컨트랙트 버전 |

### 이벤트

#### 시퀀서 이벤트
```solidity
event SequencerRegistered(address indexed sequencer, address indexed layer2, address indexed operatorManager, uint256 commission);
event SequencerDeregistered(address indexed sequencer);
event CommissionUpdated(address indexed sequencer, uint256 oldCommission, uint256 newCommission);
event CommissionUpdateRequested(address indexed sequencer, uint256 currentCommission, uint256 newCommission, uint256 effectiveTime);
event CommissionUpdateCancelled(address indexed sequencer, uint256 cancelledCommission);
event AutoTriggerToggled(address indexed sequencer, bool enabled);
```

#### 스테이킹 이벤트
```solidity
event Staked(address indexed staker, address indexed sequencer, uint256 amount);
event UnstakeRequested(address indexed staker, address indexed sequencer, uint256 amount, uint256 unlockTime);
event Withdrawn(address indexed staker, address indexed sequencer, uint256 amount);
event Redelegated(address indexed staker, address indexed fromSequencer, address indexed toSequencer, uint256 amount);
```

#### 보상 이벤트
```solidity
event RewardsReceived(address indexed sequencer, uint256 totalAmount, uint256 commission, uint256 distributed);
event RewardsClaimed(address indexed staker, address indexed sequencer, uint256 amount);
event CommissionClaimed(address indexed sequencer, uint256 amount);
event SeigniorageTriggered(address indexed sequencer, uint256 amount, address indexed triggeredBy);
```

#### 비상 이벤트
```solidity
event EmergencyActivated(address indexed layer2, address indexed activatedBy, uint256 activationTime);
event EmergencyDeactivated(address indexed layer2, address indexed deactivatedBy);
event EmergencyWithdrawn(address indexed staker, address indexed sequencer, uint256 amount);
```

#### 관리 이벤트
```solidity
event UnbondingPeriodUpdated(uint256 oldPeriod, uint256 newPeriod);
event SeigManagerUpdated(address oldManager, address newManager);
event Layer2ManagerUpdated(address oldManager, address newManager);
event DefaultGuardianUpdated(address oldGuardian, address newGuardian);
event Layer2GuardianUpdated(address indexed layer2, address oldGuardian, address newGuardian);
event EmergencyCooldownUpdated(address indexed layer2, uint256 oldCooldown, uint256 newCooldown);
event MinStakeAmountUpdated(uint256 oldAmount, uint256 newAmount);
event TokensRescued(address indexed token, address indexed to, uint256 amount);
```

### 에러

```solidity
// 일반 에러
error ZeroAddress();
error ZeroAmount();
error InvalidCommission();
error InsufficientBalance();
error Unauthorized();

// 시퀀서 에러
error SequencerAlreadyRegistered();
error SequencerNotRegistered();
error Layer2AlreadyRegistered();
error InvalidOperatorManager();
error AutoTriggerDisabled();

// 스테이킹 에러
error NoUnstakeRequest();
error UnstakingPeriodNotElapsed();
error NoPendingRewards();
error BelowMinimumStake();
error StakeCooldownNotElapsed();
error CannotRedelegateToSame();

// 커미션 에러
error NoPendingCommission();
error CommissionTimelockNotElapsed();

// 비상 에러
error EmergencyNotActive();
error EmergencyAlreadyActive();
error EmergencyCooldownNotElapsed();
error NotGuardian();

// 설정 에러
error UnbondingPeriodOutOfBounds();
error EmergencyCooldownOutOfBounds();
error BatchSizeExceeded();
error CannotRescueStakingTokens();
```

## 보안 기능

### v1.0.0 (Critical)
- **Pausable**: 비상 시 컨트랙트 일시 정지
- **UUPS Upgradeable**: 안전한 업그레이드 패턴
- **rescueTokens 보안**: TON/WTON 출금 차단

### v1.1.0 (High)
- **Commission Timelock**: 커미션 변경 7일 타임락
- **Flash Loan Protection**: 12초 쿨다운 후 보상 수령
- **Minimum Stake**: 최소 100 TON 스테이킹 요구
- **Emergency Withdraw Rewards**: 비상 출금 시 보상 포함

### v1.2.0 (Medium)
- **Batch Size Limit**: 최대 50개 배치 처리
- **O(1) Sequencer Removal**: Swap-and-pop 알고리즘
- **Unbonding Bounds**: 1일~30일 언본딩 기간 제한
- **Admin Events**: 모든 관리 함수에 이벤트 추가

### v1.3.0 (Low)
- **Constants**: 매직 넘버 상수화 (BASIS_POINTS 등)
- **Specific Errors**: CannotRedelegateToSame 등 구체적 에러
- **Emergency Cooldown Bounds**: 1시간~14일 제한
- **Improved NatSpec**: 상세한 함수 문서화

## 사용 예시

### 시퀀서 등록

```solidity
// 시퀀서가 V3 연동으로 등록
staking.registerSequencer(
    layer2Address,
    operatorManagerAddress,
    1000 // 10% commission (basis points)
);

// 자동 트리거 활성화
staking.setAutoTrigger(true);
```

### 사용자 스테이킹

```solidity
// TON 승인
ton.approve(address(staking), 1000 ether);

// 스테이킹 (최소 100 TON)
staking.stake(sequencerAddress, 1000 ether);

// 12초 후 보상 수령
staking.claimRewards(sequencerAddress);

// 언스테이킹 요청
staking.unstake(sequencerAddress, 500 ether);

// 언본딩 기간 후 출금
staking.withdraw(sequencerAddress);
```

### 커미션 변경 (7일 타임락)

```solidity
// 커미션 변경 요청
staking.requestCommissionUpdate(2000); // 20%

// 7일 후 적용
staking.applyCommissionUpdate();

// 또는 취소
staking.cancelCommissionUpdate();
```

### 비상 탈출

```solidity
// Guardian: 비상 모드 활성화
staking.activateEmergency(layer2);

// 쿨다운 후 (기본 3일) 사용자 즉시 출금
staking.emergencyWithdraw(sequencer);
```

## 프로젝트 구조

```
delegate-staking/
├── contracts/
│   ├── DelegateStakingV3Upgradeable.sol  # UUPS 업그레이드 버전 (권장)
│   ├── DelegateStakingV3.sol             # V3 통합 일반 버전
│   ├── DelegateTrigger.sol               # 자동 트리거
│   ├── DelegateStakingMVP.sol            # MVP 버전
│   └── interfaces/
│       ├── IDelegateStakingV3.sol
│       └── IDelegateStakingMVP.sol
├── lib/
│   ├── forge-std/
│   ├── openzeppelin-contracts/
│   ├── openzeppelin-contracts-upgradeable/
│   └── ton-staking-v2/                   # V3 의존성 (submodule)
├── script/
│   ├── DeployLocalV3.s.sol               # 로컬 V3 배포
│   └── InteractV3.s.sol                  # V3 상호작용
├── test/
│   ├── DelegateStakingV3Upgradeable.t.sol  # 143 테스트
│   ├── DelegateStakingV3.t.sol             # 52 테스트
│   ├── DelegateStakingV3Extended.t.sol     # 52 테스트
│   ├── DelegateStakingE2E.t.sol            # E2E 테스트
│   ├── DelegateTriggerE2E.t.sol            # 트리거 E2E
│   └── mocks/
│       ├── MockSeigManagerV3.sol
│       ├── MockOperatorManagerV3.sol
│       └── MockLayer2ManagerV3.sol
├── docs/
│   ├── design/                           # 설계 및 요구사항
│   │   ├── DESIGN.md
│   │   └── ...
│   ├── testing/                          # 테스트 결과
│   │   └── LOCAL-TESTING-RESULTS.md
│   └── guides/                           # 사용 가이드
│       ├── API.md
│       └── DEPLOYMENT.md
├── foundry.toml
└── README.md
```

## 테스트 현황

| 테스트 스위트 | 테스트 수 | 상태 |
|---------------|----------|------|
| DelegateStakingV3Upgradeable | 143 | ✅ All Pass |
| DelegateStakingV3 | 52 | ✅ All Pass |
| DelegateStakingV3Extended | 52 | ✅ All Pass |
| DelegateStakingE2E | 38 | ✅ All Pass |
| DelegateTriggerE2E | 9 | ✅ All Pass |
| DelegateStakingMVP | 6 | ✅ All Pass |
| **Total** | **300** | ✅ All Pass |

**라인 커버리지**: 99.67%

## 문서

문서는 `docs/` 폴더에 카테고리별로 정리되어 있습니다. [문서 인덱스](./docs/README.md)

### 가이드
- [API 문서](./docs/guides/API.md)
- [배포 가이드](./docs/guides/DEPLOYMENT.md)

### 설계
- [설계 문서 (한글)](./docs/design/DESIGN.md)
- [설계 문서 (영문)](./docs/design/DESIGN_EN.md)
- [V3 통합 논의 결과](./docs/design/v3-discussion-result.md)

### 테스트
- [로컬 테스트 가이드](./docs/testing/LOCAL-TESTING.md)
- [테스트 결과](./docs/testing/LOCAL-TESTING-RESULTS.md)

## 라이선스

MIT License

## 참고 자료

- [Tokamak Economics Whitepaper V3](./docs/design/Tokamak_Economics_Whitepaper_V3.pdf)
- [ton-staking-v2 Repository](https://github.com/tokamak-network/ton-staking-v2)
