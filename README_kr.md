# TON Staking V3

Tokamak Network의 V3 스테이킹 스마트 컨트랙트입니다. Tokamak Economics Whitepaper V2 (December 2025)를 기반으로 구현되었습니다.

## 시스템 소개

TON Staking V3는 이더리움 L1에서 운영되며, 여러 L2 롤업(Titan, Thanos 등)과 상호작용하여 네트워크 보안과 경제적 인센티브를 제공합니다.

### 핵심 목표

- **L2 네트워크 보안**: 시뇨리지 인센티브를 통해 L2 운영자(시퀀서)가 정직하게 행동하도록 유도
- **검증자 참여 유도**: RAT(Randomized Attention Test)를 통해 검증자가 네트워크를 상시 감시하도록 동기 부여
- **공정한 보상 분배**: Bridged TON 기반으로 실제 네트워크 기여도에 따른 보상 분배
- **DAO 거버넌스**: 시스템 파라미터 조정 및 업그레이드를 DAO를 통해 관리

## V3 핵심 변경사항

| 구분 | V2 | V3 |
|------|-----|-----|
| **시뇨리지 분배 기준** | L2 TVL (단순 비례) | Bridged TON (성과 기반) |
| **분배 함수** | 선형 분배 | 쌍곡선 포화 함수 `y(x) = L·(x/(k+x))` |
| **자격 조건** | 최소 예치금만 | S_i ≥ θ·B_i (스테이킹 비율 조건) |
| **검증자 보상** | 없음 | α·y(x) / n (검증자 풀 분배) |
| **DAO 할당** | 고정 비율 | 고정 비율 + 미분배분 |
| **스테이커 시뇨리지** | 제공 | **미제공** (V3에서 폐지) |

## 핵심 컨트랙트

| 컨트랙트 | 역할 |
|---------|------|
| **SeigManagerV1_4** | 시뇨리지 계산 및 분배 (V3 핵심) |
| **DepositManagerV1_2** | TON/WTON 스테이킹 관리 |
| **Layer2ManagerV1_2** | L2 등록 및 Bridged TON 조회 |
| **L1BridgeRegistryV1_2** | 브릿지/포탈 등록, TVL 조회 |
| **RAT** | 검증자 등록, RAT 테스트, 슬래싱 |
| **ValidatorRewardV1** | 검증자 보상 분배 |
| **SequencerVault** | 시퀀서 담보금 관리, 슬래싱 |

## V3 핵심 파라미터

| 파라미터 | 기호 | 설명 |
|---------|------|------|
| `daoDistributionRatio` | d | DAO 분배 비율 |
| `minStakingRatio` | θ | 최소 스테이킹 비율 |
| `validatorDistributionRatio` | α | 검증자 분배 비율 |
| `halfSaturationPoint` | k | 반포화점 |
| `ratTriggerProbability` | π_a | RAT 트리거 확률 |
| `slashingPenalty` | C_off | 검증자 슬래싱 페널티 |
| `evidenceSubmissionPeriod` | - | 증거 제출 기간 |

> **RAY 단위**: 모든 비율 파라미터는 RAY(10^27) 단위로 표현됩니다.

## 설치

### 요구사항

- [Foundry](https://book.getfoundry.sh/getting-started/installation)

### Clone 및 빌드

```bash
# submodule 포함하여 clone
git clone --recursive https://github.com/tokamak-network/ton-staking-v2.git
cd ton-staking-v2

# 빌드
forge build
```

### 이미 clone한 경우 (submodule 초기화)

```bash
git submodule update --init --recursive
forge build
```

### Submodule 업데이트

```bash
# optimism 라이브러리를 최신으로 업데이트
git submodule update --remote lib/optimism
```

### lib/optimism 서브모듈 주의사항

`lib/optimism` 서브모듈의 커밋을 변경할 때는 **명시적으로 GIT_DIR을 지정**해야 합니다. 그렇지 않으면 상위 저장소(ton-staking-v2)의 HEAD가 변경될 수 있습니다.

**안전한 서브모듈 커밋 변경 방법:**

```bash
# 명시적 GIT_DIR 사용 (권장)
GIT_DIR=.git/modules/lib/optimism GIT_WORK_TREE=lib/optimism git fetch origin feature/ton-staking-v3
GIT_DIR=.git/modules/lib/optimism GIT_WORK_TREE=lib/optimism git checkout <commit-hash>
```

**현재 lib/optimism 설정:**
- Repository: `tokamak-network/optimism`
- Branch: `feature/ton-staking-v3`
- Commit: `2e955e16f` (feat: integrate TON Staking V3 RAT and SeigManager with Optimism dispute system)

## 프로젝트 구조

```
src/
├── stake/                              # 스테이킹 시스템
│   ├── managers/
│   │   ├── SeigManager.sol                    # 시뇨리지 (기본)
│   │   ├── SeigManagerV1_2.sol                # 다중 구현체 인덱스 0
│   │   ├── SeigManagerV1_3.sol                # 다중 구현체 인덱스 1 (pause)
│   │   ├── SeigManagerV1_4.sol                # 다중 구현체 인덱스 2 (V3 핵심)
│   │   ├── DepositManager.sol                 # 스테이킹 (기본)
│   │   ├── DepositManagerV1_1.sol             # L2 예치
│   │   └── DepositManagerV1_2.sol             # V3 콜백
│   ├── tokens/
│   │   ├── RefactorCoinageSnapshot.sol        # 코이니지 로직
│   │   └── AutoRefactorCoinage.sol            # 자동 리팩터 코이니지
│   ├── factory/
│   │   └── CoinageFactory.sol                 # 코이니지 팩토리
│   ├── Layer2Registry.sol                     # L2 등록
│   └── interfaces/
│
├── layer2/                             # L2 관리
│   ├── Layer2ManagerV1_1.sol                  # L2 매니저 (기본)
│   ├── Layer2ManagerV1_2.sol                  # V3 Bridged TON
│   ├── L1BridgeRegistryV1_1.sol               # 브릿지 레지스트리 (기본)
│   ├── L1BridgeRegistryV1_2.sol               # V3 DisputeGame 지원
│   ├── OperatorManagerV1_1.sol                # 오퍼레이터 매니저
│   ├── OperatorManagerV1_2.sol                # V3 오퍼레이터
│   ├── factory/
│   │   └── OperatorManagerFactory.sol         # 오퍼레이터 팩토리
│   └── interfaces/
│
├── validator/                          # 검증자 시스템 (V3 신규)
│   ├── RAT.sol                                # Randomized Attention Test
│   ├── RATProxy.sol
│   ├── ValidatorRewardV1.sol                  # 검증자 보상
│   ├── ValidatorRewardProxy.sol
│   └── interfaces/
│
├── dao/                                # DAO 거버넌스
│   ├── DAOCommittee_V1.sol                    # DAO 위원회 로직
│   ├── DAOCommitteeOwner.sol                  # Owner 함수
│   ├── Candidate.sol                          # DAO 후보자
│   ├── CandidateAddOnV1_1.sol                 # 후보자 애드온
│   ├── factory/
│   │   ├── CandidateFactory.sol               # 후보자 팩토리
│   │   └── CandidateAddOnFactory.sol          # 애드온 팩토리
│   └── interfaces/
│
├── proxy/                              # 프록시 컨트랙트
│   ├── ProxyStorage.sol                       # 기본 프록시 스토리지
│   ├── DAOCommitteeProxy2.sol                 # DAO 다중 구현체 라우터
│   └── Proxy.sol
│
├── common/                             # 공통 유틸리티
│   ├── AccessibleCommon.sol
│   ├── AuthControlSeigManager.sol
│   ├── AuthControlLayer2Manager.sol
│   └── AuthControlL1BridgeRegistry.sol
│
└── accessControl/                      # 접근 제어
    └── AccessControl.sol

lib/
├── optimism/               # tokamak-network/optimism (branch: feature/ton-staking-v3)
├── tokamak-dao-contracts/  # tokamak-network/tokamak-dao-contracts (DAO 거버넌스)
├── openzeppelin-contracts/
└── forge-std/
```

## 테스트

```bash
# 전체 테스트
forge test

# V3 테스트만
forge test --match-path "test/v3/*"

# 특정 테스트
forge test --match-test testUpdateSeigniorageV3
```

## 외부 라이브러리

| 라이브러리 | 용도 |
|-----------|------|
| `@optimism/` | Optimism L1/L2 인터페이스 (SystemConfig, L1StandardBridge, OptimismPortal 등) |
| `@openzeppelin/contracts/` | ERC20, SafeERC20, Math 등 |
| `@tokamak-dao/` | DAO 거버넌스 컨트랙트 (DAOCommitteeProxy, DAOAgendaManager 등) |

### Optimism 인터페이스 사용 예시

```solidity
import { ISystemConfig } from "@optimism/interfaces/L1/ISystemConfig.sol";
import { IL1StandardBridge } from "@optimism/interfaces/L1/IL1StandardBridge.sol";
import { IOptimismPortal2 } from "@optimism/interfaces/L1/IOptimismPortal2.sol";
```

## 토큰

| 토큰 | 역할 |
|------|------|
| **TON** | 네이티브 토큰 (18 decimals) |
| **WTON** | Wrapped TON (27 decimals, 1 TON = 1e9 WTON) |
| **Coinage** | 스테이킹 영수증 토큰 (L2별 생성) |

## 외부 시스템

| 시스템 | 역할 |
|--------|------|
| **Optimism L2** | L2 롤업 (Titan, Thanos 등) |
| **DisputeGameFactory** | Dispute Game 생성 (RAT 트리거) |
| **OptimismPortal** | L1↔L2 브릿지 |
| **DAO** | 거버넌스 (DAOCommittee) |

## 문서

| 문서 | 설명 |
|------|------|
| [specs-kr/](./docs/specs-kr/) | V3 시스템 명세서 (한국어) |
| [specs-kr/01-system-overview.md](./docs/specs-kr/01-system-overview.md) | 시스템 소개, V3 변경사항, 핵심 개념 |
| [specs-kr/02-system-architecture.md](./docs/specs-kr/02-system-architecture.md) | 전체 아키텍처, 컨트랙트 의존성, 프록시 패턴 |
| [specs-kr/03-contract-structure.md](./docs/specs-kr/03-contract-structure.md) | 디렉토리 구조, 컨트랙트 상세, 스토리지 구조 |
| [specs-kr/04-contract-roles.md](./docs/specs-kr/04-contract-roles.md) | 컨트랙트별 역할, 책임, 상호작용 |
| [specs-kr/05-actors.md](./docs/specs-kr/05-actors.md) | 액터 정의 (스테이커, 시퀀서, 검증자, 챌린저, DAO) |
| [specs-kr/06-function-specs.md](./docs/specs-kr/06-function-specs.md) | 함수별 상세 설명, 파라미터, 동작 흐름 |

## 라이선스

MIT
