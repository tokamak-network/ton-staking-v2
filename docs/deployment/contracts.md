# TON Staking V3 컨트랙트별 상세 설명

이 문서는 각 컨트랙트의 배포 절차와 다중 구현체 패턴을 상세히 설명합니다.

> **관련 문서**
> - [README.md](./README.md): 배포 개요 및 순서
> - [scripts.md](./scripts.md): 스크립트 사용법 및 파라미터

---

## 목차

1. [TON / WTON](#1-ton--wton)
2. [CoinageFactory](#2-coinagefactory)
3. [SeigManager (다중 구현체)](#3-seigmanager-다중-구현체-패턴--v3-변경)
4. [DepositManager (다중 구현체)](#4-depositmanager-다중-구현체-패턴--v3-변경)
5. [Layer2Manager (다중 구현체)](#5-layer2manager-다중-구현체-패턴--v3-변경)
6. [L1BridgeRegistry (다중 구현체)](#6-l1bridgeregistry-다중-구현체-패턴--v3-변경)
7. [OperatorManager](#7-operatormanager)
8. [RAT](#8--rat-randomized-attention-test---v3-신규)
9. [ValidatorReward](#9--validatorreward---v3-신규)
10. [SequencerVault](#10--sequencervault---v3-신규)

---

## 1. TON / WTON

| 항목 | 설명 |
|------|------|
| 역할 | TON은 네이티브 토큰, WTON은 Wrapped 버전 |
| 테스트용 | MockTON, MockWTON 사용 |
| 프로덕션용 | 실제 TON/WTON 주소 사용 |

```solidity
// 테스트 배포
MockTON ton = new MockTON();
MockWTON wton = new MockWTON();
wton.setTON(address(ton));
```

---

## 2. CoinageFactory

| 항목 | 설명 |
|------|------|
| 역할 | Layer2별 코이니지(스테이킹 토큰) 생성 |
| 의존성 | RefactorCoinageSnapshot 로직 주소 |

```solidity
RefactorCoinageSnapshot coinageLogic = new RefactorCoinageSnapshot();
CoinageFactory factory = new CoinageFactory();
factory.setAutoCoinageLogic(address(coinageLogic));
```

---

## 3. SeigManager (다중 구현체 패턴) 🔄 V3 변경

| 항목 | 설명 |
|------|------|
| 역할 | 시뇨리지 계산 및 분배의 핵심 |
| 버전 | Base, V1_1, V1_2, V1_3, V1_4 (다중 구현체) |
| 주요 기능 | 블록당 시뇨리지 계산, Layer2별 분배, RAT 연동 |
| 🆕 V3 추가 | **SeigManagerV1_4** - V3 신규 함수 (RAT, Bridged TON 등) |

**중요**: SeigManager는 **다중 구현체 패턴**을 사용합니다. 단순 프록시 업그레이드가 아닌 **함수별 라우팅(Selector Routing)**으로 여러 구현체가 동시에 활성화됩니다.

### 버전별 함수 분포

| 버전 | 역할 | 비고 | V3 |
|------|------|------|-----|
| **SeigManagerV1_2** | 기본 구현체 (Index 0) - initialize, setData, deployCoinage 등 | `upgradeTo()`로 설정 | - |
| **SeigManagerV1_3** | pause/unpause, L2 시뇨리지 제외/포함 | Selector routing 필요 | - |
| **SeigManagerV1_4** | V3 신규 함수 - RAT, Layer2Manager, 슬래싱 등 | Selector routing 필요 | 🆕 |

### SeigManagerV1_3 등록 함수 목록

> **메인넷 상태**: 등록됨 (0xce18C6F84F10881eA47A43AF7311A29bb116F628)

| 함수 시그니처 | Selector | 설명 |
|--------------|----------|------|
| `pause()` | `0x8456cb59` | 컨트랙트 일시 정지 |
| `unpause()` | `0x3f4ba83a` | 컨트랙트 재개 |
| `updateSeigniorage()` | `0x764a7856` | 시뇨리지 분배 실행 |
| `updateSeigniorageLayer(address)` | `0x1e1f0b60` | Layer2별 시뇨리지 분배 |
| `estimatedDistribute(uint256,address)` | `0x5015cb2b` | 예상 시뇨리지 분배량 조회 (view) |
| `claimableL2Seigniorage(address)` | `0xd732785e` | Layer2 청구 가능 시뇨리지 조회 (view) |
| `excludeFromL2Seigniorage(address)` | `0x2c1e0156` | L2 시뇨리지 분배 제외 |
| `includeFromL2Seigniorage(address)` | `0x54798b55` | L2 시뇨리지 분배 포함 |

### SeigManagerV1_4 등록 함수 목록 (🆕 V3 신규)

> **메인넷 상태**: 미등록 (V3 업그레이드 시 등록 필요)

| 함수 시그니처 | Selector | 설명 |
|--------------|----------|------|
| `setValidatorReward(address)` | - | ValidatorReward 주소 설정 |
| `setDaoDistributionRatio(uint256)` | `0xb36124ee` | DAO 분배 비율 설정 |
| `setMinStakingRatio(uint256)` | `0xfddecacb` | 최소 스테이킹 비율 설정 |
| `setValidatorDistributionRatio(uint256)` | `0x82713813` | 검증자 분배 비율 설정 |
| `setHalfSaturationPoint(uint256)` | `0x037f1227` | Half Saturation 포인트 설정 |
| `migrateToV3()` | `0x3cd1a78b` | V3 마이그레이션 실행 |
| `onBridgedTONChange()` | `0x9a6288eb` | Bridged TON 변경 콜백 (트리거 함수, 타입 3 전용) |
| `updateSeigniorage()` | `0x764a7856` | 시뇨리지 분배 (V1_2 오버라이드 - V3 로직) |
| `updateSeigniorageLayer(address)` | `0x1e1f0b60` | Layer2별 시뇨리지 분배 (V1_2 오버라이드 - V3 로직) |

### 다중 구현체 패턴 동작 원리

```
┌─────────────────────────────────────────────────────────────────┐
│                    SeigManagerProxy                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  함수 호출 흐름:                                                  │
│                                                                  │
│  1. 외부 호출 → Proxy fallback()                                 │
│  2. selector 확인 → selectorImplementation[selector] 조회        │
│  3-A. selector가 등록됨 → 해당 구현체로 delegatecall             │
│  3-B. selector 미등록 → 기본 구현체(implementation)로 delegatecall│
│                                                                  │
│  ┌──────────────┐                                                │
│  │  initialize  │ → selectorImpl[0x...] 없음 → V1_2 (기본)       │
│  │  setData     │ → selectorImpl[0x...] 없음 → V1_2 (기본)       │
│  │  pause       │ → selectorImpl[0x...] = V1_3 → V1_3            │
│  │setLayer2Mgr  │ → selectorImpl[0x...] = V1_4 → V1_4            │
│  └──────────────┘                                                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 상세 배포 절차 (Selector Routing 방식)

```solidity
// ==========================================
// Step 1: 모든 구현체 배포
// ==========================================
SeigManagerV1_2 seigManagerV1_2 = new SeigManagerV1_2();
SeigManagerV1_3 seigManagerV1_3 = new SeigManagerV1_3();
SeigManagerV1_4 seigManagerV1_4 = new SeigManagerV1_4();

// ==========================================
// Step 2: 프록시 배포 및 기본 구현체 설정
// ==========================================
SeigManagerProxy proxy = new SeigManagerProxy();
proxy.upgradeTo(address(seigManagerV1_2));

// ==========================================
// Step 3: 초기화 (기본 구현체 함수 사용)
// ==========================================
SeigManagerV1_2(address(proxy)).initialize(
    ton_, wton_, registry_, depositManager_,
    seigPerBlock_, factory_, block.number
);

SeigManagerV1_2(address(proxy)).setData(
    powerton_, daoAddress_, 0, 0.5e27, 0.5e27, 93096, 1000.1e27
);

// ==========================================
// Step 4: V1_3, V1_4 구현체 활성화
// ==========================================
proxy.setAliveImplementation2(address(seigManagerV1_3), true);
proxy.setAliveImplementation2(address(seigManagerV1_4), true);

// ==========================================
// Step 5: V1_4 함수들을 V1_4 구현체로 라우팅
// ==========================================
bytes4[] memory v1_4Selectors = new bytes4[](N);
v1_4Selectors[0] = SeigManagerV1_4.setValidatorReward.selector;
// ... 추가 selectors
proxy.setSelectorImplementations2(v1_4Selectors, address(seigManagerV1_4));
```

### 프록시 주요 함수 설명

| 함수 | 설명 |
|------|------|
| `upgradeTo(address impl)` | 기본 구현체 설정. 미등록 selector 호출시 이 구현체가 처리 |
| `setAliveImplementation2(address impl, bool alive)` | 구현체 활성화/비활성화. selector routing 전 반드시 호출 |
| `setSelectorImplementations2(bytes4[] selectors, address impl)` | 특정 selector들을 특정 구현체로 라우팅 |
| `selectorImplementation(bytes4 selector)` | 특정 selector가 어느 구현체로 라우팅되는지 조회 |

---

## 4. DepositManager (다중 구현체 패턴) 🔄 V3 변경

| 항목 | 설명 |
|------|------|
| 역할 | 스테이킹 예치/출금 관리 |
| 버전 | Base, _setWithdrawalDelay, V1_1, V1_2 (다중 구현체) |
| 패턴 | SeigManager와 동일한 Selector Routing 방식 |
| 🆕 V3 추가 | **DepositManagerV1_2** - V3 콜백 기능 |

### 버전별 함수 분포

| 버전 | Index | 역할 | V3 |
|------|-------|------|-----|
| **DepositManager** | 0 | 기본 구현체 - initialize, deposit, requestWithdrawal 등 | - |
| **DepositManager_setWithdrawalDelay** | 1 | 출금 지연 설정 | - |
| **DepositManagerV1_1** | 2 | L2 출금 및 가스 제한 설정 | - |
| **DepositManagerV1_2** | 3 | V3 콜백 및 함수 오버라이드 | 🆕 |

### DepositManager_setWithdrawalDelay (Index 1) 등록 함수 목록

| 함수 시그니처 | Selector | 설명 |
|--------------|----------|------|
| `setWithdrawalDelay(address,uint256)` | `0xdc5a709f` | Layer2별 출금 지연 설정 |
| `setWithdrawalDelayByOwner(address,uint256)` | `0x377db38b` | Owner 전용 출금 지연 설정 |

### DepositManagerV1_1 (Index 2) 등록 함수 목록

| 함수 시그니처 | Selector | 설명 |
|--------------|----------|------|
| `setMinDepositGasLimit(uint256)` | - | 최소 예치 가스 제한 설정 |
| `setAddresses(address,address)` | `0x90107afe` | L1BridgeRegistry, Layer2Manager 주소 설정 |
| `withdrawAndDepositL2(address,uint256)` | `0x9f382d11` | 출금 후 L2 예치 |

### DepositManagerV1_2 (Index 3) 등록 함수 목록 (🆕 V3 신규)

| 함수 시그니처 | Selector | 설명 |
|--------------|----------|------|
| `deposit(address,address,uint256)` | `0x8340f549` | 예치 (V3 콜백 포함) |
| `withdrawAndDepositL2(address,uint256)` | `0x9f382d11` | 출금 후 L2 예치 (V1_1 오버라이드) |
| `requestWithdrawal(address,uint256)` | `0xda95ebf7` | 출금 요청 |

### 상세 배포 절차

```solidity
// Step 1: 모든 구현체 배포
DepositManager depositManagerBase = new DepositManager();
DepositManager_setWithdrawalDelay depositManagerSetDelay = new DepositManager_setWithdrawalDelay();
DepositManagerV1_1 depositManagerV1_1 = new DepositManagerV1_1();
DepositManagerV1_2 depositManagerV1_2 = new DepositManagerV1_2();

// Step 2: 프록시 배포 및 기본 구현체 설정
DepositManagerProxy proxy = new DepositManagerProxy();
proxy.upgradeTo(address(depositManagerBase));

// Step 3: 초기화
DepositManager(address(proxy)).initialize(
    wton_, registry_, seigManager_, globalWithdrawalDelay_, address(0)
);

// Step 4: Index 1, 2, 3 구현체 활성화
proxy.setAliveImplementation2(address(depositManagerSetDelay), true);
proxy.setAliveImplementation2(address(depositManagerV1_1), true);
proxy.setAliveImplementation2(address(depositManagerV1_2), true);

// Step 5-7: 각 Index에 대해 Selector Routing 설정
// ...
```

---

## 5. Layer2Manager (다중 구현체 패턴) 🔄 V3 변경

| 항목 | 설명 |
|------|------|
| 역할 | Layer2 등록 및 관리 |
| 버전 | V1_1, V1_2 (다중 구현체) |
| 🆕 V3 추가 | **Layer2ManagerV1_2** - Bridged TON 관리, SequencerVault 설정 |

### 버전별 함수 분포

| 버전 | Index | 주요 함수 | V3 |
|------|-------|----------|-----|
| **Layer2ManagerV1_1** | 0 | `setAddresses()`, `registerCandidateAddOn()`, `transferL2Seigniorage()` | - |
| **Layer2ManagerV1_2** | 1 | `getBridgedTONByLayer()`, `getBridgedTON()`, `getLayer2BySystemConfig()`, `setSequencerVault()`, `sequencerVault()` | 🆕 신규 |

### Layer2ManagerV1_2 (Index 1) 등록 함수 목록 (🆕 V3 신규)

| 함수 시그니처 | Selector | 설명 |
|--------------|----------|------|
| `getBridgedTONByLayer(address)` | - | Layer2 주소로 Bridged TON 조회 |
| `getBridgedTON(address)` | - | rollupConfig로 Bridged TON 조회 |
| `getLayer2BySystemConfig(address)` | - | SystemConfig → Layer2 주소 조회 |
| `setSequencerVault(address)` | - | SequencerVault 주소 설정 (onlyOwner) |
| `sequencerVault()` | - | SequencerVault 주소 조회 (view) |

### 배포 절차

```solidity
// Step 1: 구현체 배포
Layer2ManagerV1_1 layer2ManagerV1_1 = new Layer2ManagerV1_1();
Layer2ManagerV1_2 layer2ManagerV1_2 = new Layer2ManagerV1_2();

// Step 2: 프록시 배포 및 V1_1을 기본 구현체로 설정
Layer2ManagerProxy proxy = new Layer2ManagerProxy();
proxy.upgradeTo(address(layer2ManagerV1_1));

// Step 3: 초기화
Layer2ManagerV1_1(address(proxy)).setAddresses(
    l1BridgeRegistry_, operatorManagerFactory_, ton_, wton_,
    dao_, depositManager_, seigManager_, swapProxy_
);

// Step 4: V1_2 구현체 활성화 및 Selector Routing
proxy.setAliveImplementation2(address(layer2ManagerV1_2), true);

bytes4[] memory v1_2Selectors = new bytes4[](5);
v1_2Selectors[0] = Layer2ManagerV1_2.getBridgedTONByLayer.selector;
v1_2Selectors[1] = Layer2ManagerV1_2.getBridgedTON.selector;
v1_2Selectors[2] = Layer2ManagerV1_2.getLayer2BySystemConfig.selector;
v1_2Selectors[3] = Layer2ManagerV1_2.setSequencerVault.selector;
v1_2Selectors[4] = bytes4(keccak256("sequencerVault()"));
proxy.setSelectorImplementations2(v1_2Selectors, address(layer2ManagerV1_2));

// Step 5: SequencerVault 설정 (V3)
Layer2ManagerV1_2(address(proxy)).setSequencerVault(sequencerVaultProxy);
```

---

## 6. L1BridgeRegistry (다중 구현체 패턴) 🔄 V3 변경

| 항목 | 설명 |
|------|------|
| 역할 | Optimism SystemConfig 등록 및 관리 |
| 버전 | V1_1, V1_2 (다중 구현체) |
| 🆕 V3 추가 | **L1BridgeRegistryV1_2** - DisputeGameFactory 관리 (TYPE 3) |

### 버전별 함수 분포

| 버전 | Index | 주요 함수 | V3 |
|------|-------|----------|-----|
| **L1BridgeRegistryV1_1** | 0 | `setAddresses()`, `rejectCandidateAddOn()`, `restoreCandidateAddOn()` | - |
| **L1BridgeRegistryV1_2** | 1 | `registerRollupConfig()` (TYPE 3), `layer2TVL()` (TYPE 3 지원), `upgradeToType3()` | 🆕 신규 |

### L1BridgeRegistryV1_2 (Index 1) 등록 함수 목록 (🆕 V3 신규)

| 함수 시그니처 | Selector | 설명 |
|--------------|----------|------|
| `registerRollupConfig(address,uint8,address,string)` | - | TYPE 3 포함 롤업 등록 (4 params) |
| `registerRollupConfig(address,uint8,address)` | - | TYPE 3 포함 롤업 등록 (3 params) |
| `registerRollupConfigByManager(address,uint8,address,string)` | - | Manager 전용 등록 (4 params) |
| `registerRollupConfigByManager(address,uint8,address)` | - | Manager 전용 등록 (3 params) |
| `layer2TVL(address)` | - | TYPE 3 지원 TVL 조회 |
| `upgradeToType3(address)` | - | TYPE 1/2 → TYPE 3 업그레이드 |
| `rollupConfigWithDisputeGameFactory(address)` | - | DisputeGameFactory → rollupConfig 역조회 |
| `disputeGameFactory(address)` | - | rollupConfig → DisputeGameFactory 조회 |

---

## 7. OperatorManager

| 항목 | 설명 | V3 |
|------|------|-----|
| 역할 | Layer2 오퍼레이터 관리 | - |
| 배포 방식 | OperatorManagerFactory가 프록시 생성 | - |
| 구현체 | OperatorManagerV1_1 (기본), V1_2 (TYPE 3 업그레이드용) | 🆕 V1_2 추가 |

### OperatorManagerV1_2 신규 함수 (SequencerVault 연동) 🆕

| 함수 시그니처 | 접근제어 | 설명 |
|--------------|----------|------|
| `syncSequencerVault()` | 누구나 | Layer2Manager에서 SequencerVault 조회하여 로컬에 설정 |
| `registerSequencer(uint256)` | onlyOwnerOrManager | SequencerVault에 시퀀서 등록 |
| `deactivateSequencer()` | onlyOwnerOrManager | 시퀀서 탈퇴 및 출금 |
| `addSequencerDeposit(uint256)` | onlyOwnerOrManager | 담보금 추가 |
| `getSequencerDeposit()` | view | 담보금 조회 |
| `isSequencerActive()` | view | 활성 상태 확인 |

> **참고**: `_getSequencerVault()` 내부 함수는 로컬 스토리지에 값이 없으면 `Layer2Manager.sequencerVault()`에서 자동으로 조회합니다.

### OperatorManagerFactory 배포

```solidity
// 1. OperatorManager 구현체 배포
OperatorManagerV1_1 operatorManagerV1_1Impl = new OperatorManagerV1_1();
OperatorManagerV1_2 operatorManagerV1_2Impl = new OperatorManagerV1_2();

// 2. Factory 배포 (V1_1을 기본 구현체로 사용)
OperatorManagerFactory factory = new OperatorManagerFactory(address(operatorManagerV1_1Impl));

// 3. 주소 설정
factory.setAddresses(depositManager_, ton_, wton_, layer2Manager_);
```

### 🔄 TYPE 3 업그레이드 절차

```solidity
// ==========================================
// Step 1: L1BridgeRegistry에서 TYPE 업그레이드
// ==========================================
L1BridgeRegistry(l1BridgeRegistryProxy).upgradeToType3(rollupConfig);

// ==========================================
// Step 2: OperatorManager를 V1_2로 업그레이드
// ==========================================
address operatorManager = OperatorManagerFactory(factory).getAddress(rollupConfig);
OperatorManagerProxy(operatorManager).upgradeTo(address(operatorManagerV1_2Impl));

// ==========================================
// Step 3: SequencerVault 동기화 (누구나 호출 가능)
// ==========================================
// Layer2Manager에 SequencerVault가 설정되어 있어야 함
OperatorManagerV1_2(operatorManager).syncSequencerVault();

// 이후 시퀀서 담보금 예치 가능
```

---

## 8. 🆕 RAT (Randomized Attention Test) - V3 신규

| 항목 | 설명 |
|------|------|
| 역할 | 검증자 무작위 주의 테스트 |
| 🆕 V3 신규 | DisputeGame 생성시 검증자 선택 및 테스트 |

```solidity
RAT.initialize(
    seigManager_,          // SeigManager 주소
    wton_, ton_,           // 토큰 주소
    layer2Manager_,        // Layer2Manager 주소
    owner_,                // 관리자 주소
    ratTriggerProbability_ // RAT 트리거 확률 (RAY 단위, 예: 0.01e27 = 1%)
);

// 파라미터 설정
// 주의: 배포 스크립트(DeployV3Full.s.sol)에서는 RAY 단위(e27) 사용
// RAT 컨트랙트 내부에서 자동으로 WEI 단위(e18)로 변환됨
RAT.setSlashingPenalty(100e27);          // 100 TON (RAY 단위 입력)
RAT.setValidatorBuffer(100e27);          // 100 TON (RAY 단위 입력)
RAT.setMinimumThreshold(1000e27);        // 1000 TON (RAY 단위 입력)
RAT.setEvidenceSubmissionPeriod(1 hours);
```

---

## 9. 🆕 ValidatorReward - V3 신규

| 항목 | 설명 |
|------|------|
| 역할 | 검증자 보상 분배 |
| 🆕 V3 신규 | 검증자 등록, 보상 분배 |
| 컨트랙트 | ValidatorRewardV1 (구현체), ValidatorRewardProxy (프록시) |

```solidity
ValidatorRewardV1.initialize(
    seigManager_,  // SeigManager 주소
    wton_,         // WTON 주소
    ratContract_,  // RAT 주소
    owner_         // 관리자 주소
);
```

---

## 10. 🆕 SequencerVault - V3 신규

| 항목 | 설명 |
|------|------|
| 역할 | 시퀀서 담보금 관리 (TYPE 3 전용) |
| 🆕 V3 신규 | 시퀀서 담보금 예치, Fraud Proof 기반 슬래싱 |
| 프록시 패턴 | Proxy (upgradeTo 패턴) |

```solidity
// 배포
SequencerVault impl = new SequencerVault();
SequencerVaultProxy proxy = new SequencerVaultProxy();
IProxy(address(proxy)).upgradeTo(address(impl));

// 초기화
SequencerVault(address(proxy)).initialize(
    seigManager_, wton_, ton_,
    layer2Manager_, l1BridgeRegistry_, owner_
);
```

### SequencerVault 주요 함수

| 함수 | 설명 |
|------|------|
| `registerSequencer(systemConfig, amount)` | 시퀀서 등록 및 담보금 예치 |
| `deactivateSequencer(systemConfig)` | 시퀀서 탈퇴 및 담보금 즉시 반환 |
| `addDeposit(systemConfig, amount)` | 담보금 추가 |
| `slashSequencerByGame(gameAddress)` | Fraud Proof 슬래싱 (Permissionless) |
| `claimChallengerReward()` | 챌린저 보상 청구 |
| `getMinimumCollateral(bridgedTON)` | 최소 담보금 계산 |

### SequencerVault 파라미터

| 파라미터 | 기본값 | 설명 |
|----------|--------|------|
| `minimumStakingRatio` | 0.1e27 | θ = 10% (Bridged TON 대비 최소 담보금) |
| `maxFraudProofCost` | 1000e18 | C_max = 1000 TON |
| `sequencerAdditionalReward` | 100e18 | Δ_sequencer = 100 TON |
| `maxChallengers` | 10 | H_max = 10 |
