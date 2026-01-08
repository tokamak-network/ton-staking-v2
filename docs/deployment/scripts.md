# TON Staking V3 배포 스크립트 및 파라미터

이 문서는 배포 스크립트 사용법, 초기화 파라미터, 검증 방법을 설명합니다.

> **관련 문서**
> - [README.md](./README.md): 배포 개요 및 순서
> - [contracts.md](./contracts.md): 컨트랙트별 상세 설명

---

## 목차

1. [초기화 파라미터](#초기화-파라미터)
2. [배포 스크립트 사용법](#배포-스크립트-사용법)
3. [검증 및 테스트](#검증-및-테스트)
4. [문제 해결](#문제-해결)
5. [메인넷 배포 주소](#메인넷-배포-주소-참고용)

---

## 초기화 파라미터

### 권장 파라미터 값

#### SeigManager 초기화 파라미터

| 파라미터 | 값 | 설명 |
|----------|-----|------|
| `seigPerBlock` | 3.92e18 | 블록당 3.92 TON 시뇨리지 |
| `globalWithdrawalDelay` | 93046 | ~2주 (13초 블록 기준) |

#### SeigManager setData 파라미터

| 파라미터 | 값 | 설명 |
|----------|-----|------|
| `powerTONSeigRate` | 0 | PowerTON 시뇨리지 비율 (0%) |
| `daoSeigRate` | 0.5e27 | DAO 시뇨리지 비율 (50%) |
| `relativeSeigRate` | 0.5e27 | 상대적 시뇨리지 비율 (50%) |
| `adjustCommissionDelay` | 93096 | 커미션 조정 지연 블록 (~2주) |
| `minimumAmount` | 1000.1e27 | 최소 스테이킹 금액 (1000.1 WTON) |

#### RAT/ValidatorReward 파라미터

| 파라미터 | 값 | 설명 |
|----------|-----|------|
| `ratTriggerProbability` | 0.01e27 | 1% (RAY 단위) |
| `slashingPenalty` | 100e27 | 100 TON (RAY 단위 입력, 내부적으로 e18로 변환) |
| `validatorBuffer` | 100e27 | 100 TON (RAY 단위 입력, 내부적으로 e18로 변환) |
| `minimumThreshold` | 1000e27 | 1000 TON (RAY 단위 입력, 내부적으로 e18로 변환) |
| `evidenceSubmissionPeriod` | 3600 | 1시간 (초) |

> **주의**: 배포 스크립트(DeployV3Full.s.sol)는 RAY 단위(e27)를 사용합니다. RAT 컨트랙트가 내부적으로 WEI 단위(e18)로 변환하므로 입력값은 e27로 제공해야 합니다.

#### SequencerVault 파라미터

| 파라미터 | 값 | 설명 |
|----------|-----|------|
| `minimumStakingRatio` | 0.1e27 | θ = 10% (RAY 단위) |
| `maxFraudProofCost` | 1000e18 | C_max = 1000 TON (18 decimals) |
| `sequencerAdditionalReward` | 100e18 | Δ_sequencer = 100 TON (18 decimals) |
| `maxChallengers` | 10 | H_max = 최대 챌린저 수 |

### RAY 단위

TON Staking에서는 비율에 RAY 단위(10^27)를 사용합니다.

```solidity
uint256 constant RAY = 10**27;

// 예시
uint256 onePercent = 0.01e27;  // 1%
uint256 tenPercent = 0.1e27;   // 10%
```

---

## 배포 스크립트 사용법

### Foundry 스크립트 실행

```bash
# 1. 로컬 Anvil 노드 시작
anvil

# 2. 전체 배포 실행
forge script script/DeployV3Full.s.sol:DeployV3Full \
    --rpc-url http://localhost:8545 \
    --broadcast \
    -vvvv

# 3. 배포 결과 확인
cat deployments/v3-full.json
```

### 배포 스크립트 종류

| 스크립트 | 용도 |
|----------|------|
| `DeployV3Full` | 전체 배포 (새 체인용) |
| `DeployV3FullLocal` | 로컬 Anvil 테스트용 |
| `DeployV3FullE2E` | E2E 테스트용 (Go 호출) |
| `DeployV3Fork` | 메인넷 포크용 (기존 컨트랙트 활용) |

### 배포 결과 JSON 형식

```json
{
  "ton": "0x...",
  "wton": "0x...",
  "coinageFactory": "0x...",
  "layer2RegistryProxy": "0x...",
  "seigManagerProxy": "0x...",
  "depositManagerProxy": "0x...",
  "layer2ManagerProxy": "0x...",
  "l1BridgeRegistryProxy": "0x...",
  "operatorManagerFactory": "0x...",
  "ratProxy": "0x...",
  "validatorRewardProxy": "0x...",
  "sequencerVaultProxy": "0x..."
}
```

---

## 검증 및 테스트

### 배포 후 검증 체크리스트

```bash
# 1. 프록시 구현체 확인
cast call $SEIG_MANAGER_PROXY "implementation()(address)"

# 2. SeigManager 설정 확인
cast call $SEIG_MANAGER_PROXY "ton()(address)"
cast call $SEIG_MANAGER_PROXY "wton()(address)"
cast call $SEIG_MANAGER_PROXY "layer2Manager()(address)"
cast call $SEIG_MANAGER_PROXY "validatorReward()(address)"

# 3. Layer2Manager 설정 확인
cast call $LAYER2_MANAGER_PROXY "sequencerVault()(address)"

# 4. RAT 설정 확인
cast call $RAT_PROXY "seigManager()(address)"
cast call $RAT_PROXY "ratTriggerProbability()(uint256)"
```

### 통합 테스트

```bash
# Foundry 테스트
forge test --match-path "test/v3/*" -vvv

# E2E 테스트
make test-e2e-rat
```

---

## 문제 해결

### 일반적인 오류

| 오류 | 원인 | 해결방법 |
|------|------|----------|
| `already initialized` | 이중 초기화 시도 | 새 프록시 배포 필요 |
| `zero address` | 의존 컨트랙트 미배포 | 배포 순서 확인 |
| `only owner` | 권한 부족 | 배포자 계정으로 실행 |
| `same addr` | 동일 구현체로 업그레이드 | 새 구현체 배포 |

### 로그 확인

```bash
# Forge 스크립트 상세 로그
forge script ... -vvvv

# 트랜잭션 추적
cast run $TX_HASH --rpc-url $RPC_URL
```

---

## 메인넷 배포 주소 (참고용)

아래는 이더리움 메인넷에 배포된 TON Staking V2 컨트랙트 주소입니다.

### 토큰

| 컨트랙트 | 주소 |
|----------|------|
| TON | `0x2be5e8c109e2197D077D13A82dAead6a9b3433C5` |
| WTON | `0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2` |

### 프록시 컨트랙트

| 컨트랙트 | 주소 |
|----------|------|
| SeigManagerProxy | `0x0b55a0f463b6DEFb81c6063973763951712D0E5F` |
| DepositManagerProxy | `0x0b58ca72b12f01fc05f8f252e226f3e2089bd00e` |
| Layer2RegistryProxy | `0x7846c2248a7b4de77e9c2bae7fbb93bfc286837b` |
| Layer2ManagerProxy | `0xD6Bf6B2b7553c8064Ba763AD6989829060FdFC1D` |
| L1BridgeRegistryProxy | `0x39d43281A4A5e922AB0DCf89825D73273D8C5BA4` |
| CandidateFactoryProxy | `0x9fc7100a16407ee24a79c834a56e6eca555a5d7c` |
| CandidateAddOnFactoryProxy | `0xFA8ce5caF456115E72B96E5074769b8f66AA5861` |

### 구현체 컨트랙트

| 컨트랙트 | 주소 | 비고 |
|----------|------|------|
| SeigManagerV1_2 | `0xb1958719b3Af9B4d85D93EFC5e317C97cCe9aBc4` | Index 0 (기본) |
| SeigManagerV1_3 | `0xce18C6F84F10881eA47A43AF7311A29bb116F628` | Index 1 (pause/unpause) |
| DepositManagerV1_1 | `0x74bC3031b9369e6b898e82784106257D4D37Eac5` | 예치 관리 |
| Layer2ManagerV1_1 | `0x2EB7f500125f11544392B83B87cDEb9456f3509f` | Layer2 관리 |
| L1BridgeRegistryV1_1 | `0x259Ac335EB42d345A61bE48104eC0Ec20b283F14` | 브릿지 등록 |
| OperatorManagerV1_1 | `0xB5F3b31dFB4DCe9a2FA12dE50A97250d60823750` | 오퍼레이터 관리 로직 |

### 팩토리 컨트랙트

| 컨트랙트 | 주소 |
|----------|------|
| CoinageFactory | `0xe8fae91b80dd515c3d8b9fc02cb5b2ecfddabf43` |
| RefactorCoinageSnapshot | `0xef12310ff8a6e96357b7d2c4a759b19ce94f7dfb` |
| OperatorManagerFactory | `0xAf86b21edDdC78ea27E23A7F2151d60d4e069450` |

### SeigManager 다중 구현체 구조 (메인넷)

```
SeigManagerProxy (0x0b55a0f463b6DEFb81c6063973763951712D0E5F)
├── Index 0: SeigManagerV1_2 (0xb1958719b3Af9B4d85D93EFC5e317C97cCe9aBc4)
│   └── 기본 함수들 (fallback)
├── Index 1: SeigManagerV1_3 (0xce18C6F84F10881eA47A43AF7311A29bb116F628)
│   └── pause(), unpause()
└── Index 2: SeigManagerV1_4 (V3 업그레이드시 추가)
    └── setValidatorReward(), migrateToV3() 등
```

---

## 참고 자료

- [TON Staking V2 Test Fixtures](https://github.com/tokamak-network/ton-staking-v2/blob/ton-staking-v2/test/shared/fixtures.ts)
- [E2E Test Design](../e2e-test-design.md)
