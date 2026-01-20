# op-e2e Genesis Setup Guide

## Overview

TON Staking V3의 op-e2e 테스트를 위한 제네시스 파일 생성 가이드입니다.

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

## 제네시스 파일 생성

```bash
make devnet-allocs-offline
```

**생성되는 파일:**
- `.devnet/genesis-l1-staking-v3.json` - Anvil용 제네시스 파일
- `.devnet/addresses.json` - 배포된 컨트랙트 주소들

**Genesis에서 수행:**
1. Optimism devnet allocs 로드 (Optimism 컨트랙트 bytecode)
2. TON Staking 컨트랙트 배포 및 초기화
   - Managers: SeigManager, DepositManager, Layer2Manager, L1BridgeRegistry
   - V3: RAT, ValidatorReward
   - DAO: MockDAOCommitteeProxy, CandidateFactory 등
3. 토큰 컨트랙트 배포 (TON, WTON) 및 테스트 토큰 민팅
4. Manager 간 cross-reference 설정
5. RAT treasury/l1BridgeRegistry 설정

## 제네시스에 포함된 컨트랙트

| 카테고리 | 컨트랙트 |
|---------|---------|
| Optimism | DisputeGameFactory, SystemConfig, OptimismPortal, AnchorStateRegistry (Mock) |
| TON Staking Core | TON, WTON, CoinageFactory, Layer2Registry |
| Managers | SeigManager (V1_2/V1_3/V1_4), DepositManager (V1_1/V1_2), Layer2Manager (V1_1/V1_2), L1BridgeRegistry (V1_2) |
| V3 Contracts | RAT, ValidatorReward |
| Operator | OperatorManagerFactory, OperatorManagerV1_2 |
| DAO | MockDAOCommitteeProxy, DAOCommitteeProxy2, DAOCommittee_V1, DAOCommitteeOwner, CandidateFactory, CandidateAddOnFactory |

## SeigManager Multi-Implementation Proxy

SeigManager는 **multi-implementation proxy 패턴**을 사용합니다. 함수 selector에 따라 다른 implementation으로 라우팅됩니다.

**V1_4 Selectors (RAT 연동 필수):**
```solidity
// Genesis 스크립트에서 반드시 라우팅 설정 필요
SeigManagerV1_4.setRATContract.selector
SeigManagerV1_4.transferCoinageToRAT.selector
SeigManagerV1_4.transferCoinageFromRAT.selector
SeigManagerV1_4.transferCoinageFromRATTo.selector
SeigManagerV1_4.estimateL2Seigniorage.selector
bytes4(keccak256("ratContract()"))
```

이 selector들이 누락되면 RAT에서 `transferCoinageToRAT` 호출 시 실패합니다.

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

## E2E 테스트 실행

```bash
cd op-e2e

# 전체 테스트 실행
make test

# RAT 테스트만 실행
make test-rat

# SimpleRAT 테스트만 실행
make test-rat-simple
```

### 제네시스 재생성
```bash
make devnet-allocs-offline
```

## 참고 파일

| 파일 | 설명 |
|------|------|
| `script/DeployV3FullForDevnet.s.sol` | Genesis 배포 스크립트 (순수 TON Staking 배포/설정) |
| `op-e2e/faultproofs/rat_challenge_helpers.go` | 테스트 헬퍼 (Optimism 연동, V3 설정, 트랜잭션 호출) |
| `op-e2e/faultproofs/rat_challenge_test.go` | RAT 통합 테스트 |
| `op-e2e/e2eutils/rat/system.go` | 테스트 시스템 설정 (Anvil 시작) |

## 버그 수정 및 알려진 이슈

### CandidateAddOnProxy 스토리지 레이아웃 충돌 (Issue #311)

**문제**: `CandidateAddOnProxy`와 `CandidateAddOnV1_1` 구현체 간 스토리지 레이아웃 불일치

**원인**:
- `CandidateAddOnProxy`가 `CandidateStorage`를 상속 (slot 2 = `candidate` address)
- `CandidateAddOnV1_1`이 `CandidateAddOnStorage1`을 상속 (slot 2 = `memo` string)

**증상**:
- `Layer2Manager.registerCandidateAddOn()` 호출 시 revert
- `CandidateAddOnFactory.deploy()`가 생성하는 프록시에서 스토리지 충돌 발생
- DAO 관련 기능 (changeMember, retireMember, castVote, claimActivityReward) 불가

**수정** (`src/dao/CandidateAddOnProxy.sol`):
```solidity
// Before (버그)
contract CandidateAddOnProxy is Proxy, CandidateStorage, CandidateAddOnStorage

// After (수정)
contract CandidateAddOnProxy is Proxy, CandidateAddOnStorage1, CandidateAddOnStorage
```

**수정 후 필요한 작업**:
```bash
# 1. 캐시 삭제 및 재빌드
pkill -f anvil
forge clean && forge build

# 2. Genesis 재생성
make devnet-allocs-offline

# 3. 테스트 실행
cd op-e2e && make test-rat-simple
```

**관련 파일**:
- `src/dao/CandidateAddOnProxy.sol` - 프록시 컨트랙트
- `src/dao/CandidateAddOnV1_1.sol` - 구현 컨트랙트
- `src/dao/CandidateStorage.sol` - 기존 스토리지 (버그)
- `src/dao/CandidateAddOnStorage1.sol` - 수정된 스토리지 (ERC7201 named slots 사용)
