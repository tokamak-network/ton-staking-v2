# op-e2e Genesis Setup Guide

> 🏗️ Genesis 파일 생성 및 E2E 테스트 환경 설정 가이드

## 📋 Overview

TON Staking V3 E2E 테스트는 **Genesis 기반**으로 동작합니다. 모든 컨트랙트가 사전 배포된 상태로 시작하여 빠르고 안정적인 테스트를 제공합니다.

**핵심 특징:**
- ✅ 한 번 생성, 여러 번 사용
- ✅ 테스트마다 독립된 Anvil 노드
- ✅ 병렬 실행 지원
- ✅ 일관된 테스트 환경

## 핵심 개념: Genesis vs Runtime 초기화

### Genesis에서 하는 것 (순수 TON Staking)
**컨트랙트 배포 및 초기화** (Forge 스크립트 내 트랜잭션):
- 모든 TON Staking 컨트랙트 배포 및 초기화
- Manager 간 cross-reference 설정
- Multi-implementation proxy 라우팅 설정
- DAO 컨트랙트 설정
- 테스트 토큰 민팅 (TON, WTON)
- RAT.setTreasury(), RAT.setL1BridgeRegistry()

### Runtime에서 하는 것 (Optimism 연동)
테스트 환경에서 **Optimism 관련 설정**만 트랜잭션으로 수행:
- **L1BridgeRegistry SystemConfig 등록**
  - `L1BridgeRegistry.addManager()` - Manager 권한 부여
  - `L1BridgeRegistry.registerRollupConfigByManager()` - SystemConfig 매핑
- **V3 파라미터 설정** (`configureV3Parameters()`)
  - `setDaoDistributionRatio()`, `setMinStakingRatio()` 등
  - `setRATContract()`, `migrateToV3()`
- **Layer2 (CandidateAddOn) 생성** (`createMockLayer2()`)
  - `Layer2Manager.registerCandidateAddOn()` 트랜잭션
- **Validator 등록** (`registerValidatorWithTON()`)
  - `DepositManager.deposit()` 트랜잭션
  - `RAT.registerValidator()` 트랜잭션

**설계 원칙**:
- Genesis: 순수 TON Staking 배포/설정 (Forge 스크립트 내 트랜잭션)
- Runtime: Optimism 연동 설정 (테스트 환경에서 트랜잭션)

## 🚀 Quick Start

### Step 1: Genesis 파일 생성 (처음 1회만)
```bash
# 프로젝트 루트에서
cd /Users/zena/tokamak-projects/ton-staking-v2
make devnet-allocs-offline
```

**소요 시간:** ~30초

**생성되는 파일:**
```
.devnet/
├── genesis-l1-staking-v3.json    # Anvil용 genesis 파일 (~2MB)
└── addresses.json                 # 배포된 컨트랙트 주소들
```

### Step 2: E2E 테스트 실행
```bash
# 바로 테스트 실행 가능
make test-e2e

# 또는 op-e2e 디렉토리에서
cd op-e2e && make test
```

---

## 🔧 Genesis 생성 프로세스

### 내부 동작
```
make devnet-allocs-offline
    │
    ├─ 1. Optimism allocs 로드
    │   └─ .devnet/allocs-l1.json
    │       (DisputeGameFactory, SystemConfig, OptimismPortal)
    │
    ├─ 2. TON Staking 배포 (DeployV3FullForDevnet.s.sol)
    │   ├─ Tokens: TON, WTON
    │   ├─ Managers: SeigManager, DepositManager, Layer2Manager
    │   ├─ V3 Contracts: RAT, ValidatorReward
    │   ├─ DAO: MockDAOCommitteeProxy, Factories
    │   └─ OperatorManager: Factory
    │
    ├─ 3. 초기화 및 설정
    │   ├─ Manager cross-references
    │   ├─ Multi-implementation proxy routing
    │   ├─ RAT parameters
    │   └─ Test token minting (100,000 TON/WTON per account)
    │
    └─ 4. Genesis 파일 생성
        └─ .devnet/genesis-l1-staking-v3.json
```

### Genesis에서 배포되는 컨트랙트
```
Optimism (기존):
  - DisputeGameFactory
  - SystemConfig  
  - OptimismPortal2
  - AnchorStateRegistry (Mock)

TON Staking (신규 배포):
  - TON, WTON
  - CoinageFactory, Layer2Registry
  - SeigManager (Proxy + V3_1, V3_2)
  - DepositManager (Proxy + V3)
  - Layer2Manager (Proxy + V3)
  - L1BridgeRegistry (Proxy + V1_2)
  - RAT (Proxy + Impl)
  - ValidatorReward (Proxy + V1)
  - OperatorManagerFactory
  - DAO Infrastructure (MockDAOCommitteeProxy, Factories)
```

## 제네시스에 포함된 컨트랙트

| 카테고리 | 컨트랙트 |
|---------|---------|
| Optimism | DisputeGameFactory, SystemConfig, OptimismPortal, AnchorStateRegistry (Mock) |
| TON Staking Core | TON, WTON, CoinageFactory, Layer2Registry |
| Managers | SeigManager (V1_2/V1_3/V1_4), DepositManager (V1_1/V1_2), Layer2Manager (V1_1/V1_2), L1BridgeRegistry (V1_2) |
| V3 Contracts | RAT, ValidatorReward |
| Operator | OperatorManagerFactory, OperatorManagerV1_2 |
| DAO | MockDAOCommitteeProxy, DAOCommitteeProxy2, DAOCommittee_V1, DAOCommitteeOwner, CandidateFactory, CandidateAddOnFactory |

---

## 🔑 주요 설계 결정

### SeigManager Multi-Implementation Proxy

SeigManager는 **selector routing 기반 multi-implementation proxy**를 사용합니다.

**구조:**
```
SeigManagerProxy
    │
    ├─ Default: SeigManagerV1_2 (기본 V2 로직)
    ├─ V3_1: V3 신규 기능 (RAT 연동, V3 분배 등)
    └─ V3_2: V2 호환 레이어 (delegatecall)
```

**V3_1 Selectors (RAT 연동):**
```solidity
// Genesis에서 자동 설정됨
- setRatContract()
- transferCoinageToRat()
- transferCoinageFromRat()
- transferCoinageFromRatTo()
- ratContract()
- setDaoDistributionRatio()
- setMinStakingRatio()
- setValidatorDistributionRatio()
// ... (총 30+ selectors)
```

**✅ Genesis 스크립트가 모든 라우팅을 자동 설정하므로 수동 작업 불필요**

## 테스트 런타임 초기화 (Optimism 연동)

테스트 시작 시 `rat_challenge_helpers.go`의 함수들이 **Optimism 연동 설정**을 트랜잭션으로 수행합니다.

### `registerSystemConfigInL1BridgeRegistry()`
SystemConfig를 L1BridgeRegistry에 등록:
- `L1BridgeRegistry.addManager()` - deployer에게 manager 권한 부여
- `L1BridgeRegistry.registerRollupConfigByManager()` - SystemConfig ↔ DisputeGameFactory 매핑

### `configureV3Parameters()`
SeigManager V3 파라미터를 트랜잭션으로 설정:
- `setDaoDistributionRatio()` - 20%
- `setMinStakingRatio()` - 10%
- `setValidatorDistributionRatio()` - 20%
- `setHalfSaturationPoint()` - 10M TON
- `setMaxChallengers()` - 10
- `setMaxFraudProofCost()` - 1000 WTON
- `setSequencerAdditionalReward()` - 100 WTON
- `setRATContract()`
- `migrateToV3()`

### `createMockLayer2()`
테스트용 Layer2 (CandidateAddOn)를 트랜잭션으로 생성:
- WTON 민팅 및 승인
- `Layer2Manager.registerCandidateAddOn()` 호출
- Coinage 자동 생성

### `registerValidatorWithTON()`
Validator를 트랜잭션으로 등록:
- WTON 민팅 및 승인
- `DepositManager.deposit()` 호출
- `RAT.registerValidator()` 호출

## 테스트 계정 (Anvil 기본)

| 역할 | 주소 | Account # |
|-----|------|-----------|
| optimismDeployer | 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 | #0 |
| tonStakingDeployer | 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 | #1 |
| proxyAdmin | 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC | #2 |
| validator | 0x90F79bf6EB2c4f870365E785982E1f101E93b906 | #3 |
| proposer | 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65 | #4 |
| challenger | 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc | #5 |

**참고**: Optimism과 TON Staking은 **다른 deployer**를 사용하여 nonce 충돌을 방지합니다.

### 초기 토큰 잔액 (각 계정)
- TON: 100,000 (1e5 * 1e18)
- WTON: 100,000 (1e5 * 1e27)
- ETH: 10,000 (Anvil 기본값)

---

## 🧪 E2E 테스트 실행

### 전체 테스트 실행
```bash
cd op-e2e
make test
```
**실행 내용:** 7개 테스트 (3 system + 4 RAT scenarios)  
**소요 시간:** ~21초 (병렬 실행)

### 테스트 그룹별 실행
```bash
cd op-e2e

# RAT 시나리오만
make test-rat-simple

# 전체 RAT 테스트
make test-rat

# 개별 테스트
GOWORK=off go test -v -run TestSimpleRAT_ValidatorRegistration ./faultproofs
```

### Genesis 재생성 (컨트랙트 변경 시)
```bash
# 프로젝트 루트에서
make devnet-allocs-offline

# 캐시 정리 후 재생성
forge clean
make devnet-allocs-offline
```

**재생성이 필요한 경우:**
- ✅ 컨트랙트 코드 변경
- ✅ Genesis 파라미터 변경
- ✅ 배포 스크립트 수정
- ❌ 테스트 코드만 변경 (재생성 불필요)

## 참고 파일

| 파일 | 설명 |
|------|------|
| `script/DeployV3FullForDevnet.s.sol` | Genesis 배포 스크립트 (순수 TON Staking 배포/설정) |
| `op-e2e/faultproofs/rat_challenge_helpers.go` | 테스트 헬퍼 (Optimism 연동, V3 설정, 트랜잭션 호출) |
| `op-e2e/faultproofs/rat_challenge_test.go` | RAT 통합 테스트 |
| `op-e2e/e2eutils/rat/system.go` | 테스트 시스템 설정 (Anvil 시작) |

---

## 🐛 Troubleshooting

### Genesis 파일이 없다는 에러
```bash
Error: Genesis file not found at .devnet/genesis-l1-staking-v3.json
```

**해결:**
```bash
cd /Users/zena/tokamak-projects/ton-staking-v2
make devnet-allocs-offline
```

---

### Genesis 생성 실패
```bash
Error: Failed to generate genesis
```

**해결:**
```bash
# 1. 캐시 정리
forge clean

# 2. 컴파일 확인
forge build

# 3. Genesis 재생성
make devnet-allocs-offline
```

---

### 테스트 실행 시 컨트랙트가 없다는 에러
```bash
Error: Contract not found at address
```

**원인:** Genesis 파일이 오래되어 컨트랙트 주소가 변경됨

**해결:**
```bash
# Genesis 재생성
make devnet-allocs-offline

# 테스트 재실행
cd op-e2e && make test
```

---

### Anvil 포트 충돌
```bash
Error: address already in use
```

**해결:**
```bash
# Anvil 프로세스 종료
pkill anvil

# 또는 순차 실행
cd op-e2e
GOWORK=off go test -v -p 1 ./faultproofs
```

---

## 📚 관련 문서

- [e2e-tests.md](./e2e-tests.md) - E2E 테스트 상세 가이드
- [QUICK-COMMANDS.md](./QUICK-COMMANDS.md) - 테스트 명령어 레퍼런스
- [README.md](./README.md) - 테스트 개요

---

## 🔗 관련 파일

| 파일 | 설명 |
|------|------|
| `script/DeployV3FullForDevnet.s.sol` | Genesis 배포 스크립트 |
| `op-e2e/e2eutils/rat/system.go` | Anvil 노드 관리 (Genesis 로드) |
| `op-e2e/faultproofs/rat_challenge_helpers.go` | 테스트 헬퍼 함수 |
| `op-e2e/faultproofs/rat_challenge_test.go` | RAT 시나리오 테스트 |
| `.devnet/genesis-l1-staking-v3.json` | 생성된 Genesis 파일 |
| `.devnet/addresses.json` | 배포된 컨트랙트 주소 |

---

## ⚡ Quick Reference

```bash
# Genesis 생성
make devnet-allocs-offline

# 전체 테스트
make test-e2e

# Genesis 재생성 + 테스트
forge clean && make devnet-allocs-offline && make test-e2e

# Genesis 파일 확인
ls -lh .devnet/genesis-l1-staking-v3.json

# 배포된 주소 확인
cat .devnet/addresses.json | jq
```
