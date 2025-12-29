# TON Staking V3 컨트랙트별 상세 설명

이 문서는 각 컨트랙트의 배포 절차와 다중 구현체 패턴을 상세히 설명합니다.

> **관련 문서**
> - [deployment-guide.md](./deployment-guide.md): 배포 개요 및 순서

---

## 목차

1. [TON / WTON](#1-ton--wton)
2. [CoinageFactory](#2-coinagefactory)
3. [Proxy Deploy](#3-proxy-deploy)
4. [Layer2Registry](#4-layer2registry-setting)
5. [SeigManager (다중 구현체)](#5-seigmanager-다중-구현체-패턴)
6. [DepositManager (다중 구현체)](#6-depositmanager-다중-구현체-패턴)
7. [Layer2Manager (Proxy 패턴)](#7-layer2manager-proxy-패턴)
8. [L1BridgeRegistry (Proxy 패턴)](#8-l1bridgeregistry-proxy-패턴)
9. [OperatorManagerFactory](#9-operatormanagerfactory)
10. [DAOVault](#10-daovault)
11. [DAOAgendaManager](#11-daoagendamanager)
12. [DAOCommittee (다중 구현체)](#12-daocommittee)
13. [CandiateFactory](#13-candidatefactory)
14. [CandidateFAddOnFactory](#14-candidatefaddonfactory)


---

## 1. TON / WTON

| 항목 | 설명 |
|------|------|
| 역할 | TON은 네이티브 토큰, WTON은 Wrapped 버전 |
| 테스트용 | abi를 이용해 배포 |
| 프로덕션용 | 실제 TON/WTON 주소 사용 |

```solidity
// 테스트 배포
ton = deployCode("abis/TON.json");
bytes memory wtonArgs = abi.encode(ton);
wton = deployCode("abis/WTON.json", wtonArgs);
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

## 3. Proxy Deploy (SeigManagerProxy, DepositManagerProxy, Layer2RegistryProxy, Layer2ManagerProxy, L1BridgeRegistryProxy)

| 항목 | 설명 |
|------|------|
| 역할 | 프록시 컨트랙트들을 미리 배포 |
| 의존성 | SeigManager, DepositManager, Layer2Manager, L1BridgeRegistry |

```solidity
SeigManagerProxy seigManagerProxy = new SeigManagerProxy();
DepositManagerProxy depositManagerProxy = new DepositManagerProxy();
Layer2RegistryProxy layer2RegistryProxy = new Layer2RegistryProxy();
Layer2ManagerProxy layer2ManagerProxy = new Layer2ManagerProxy();
L1BridgeRegistryProxy l1BridgeRegistryProxy = new L1BridgeRegistryProxy();
```

---

## 4. Layer2Registry
| 항목 | 설명 |
|------|------|
| 역할 | Layer2Registry의 기본 설정 |
| 버전 | Base, V1_1, V1_2, V1_3 (다중 구현체) |
| 주요 기능 | Layer2Registry의 기본 설정 |


### 배포 절차 

```solidity
// Step 1: 구현체 배포
Layer2Registry layer2RegistryBase = new Layer2Registry();

// Step 2: 프록시 배포 및 기본 구현체 설정
Layer2RegistryProxy proxy = new Layer2RegistryProxy();
proxy.upgradeTo(address(layer2RegistryBase));
```


## 5. SeigManager Settings (다중 구현체 패턴) 

| 항목 | 설명 |
|------|------|
| 역할 | 시뇨리지 계산 및 분배의 핵심 |
| 버전 | Base, V1_1, V1_2, V1_3 (다중 구현체) |
| 주요 기능 | 블록당 시뇨리지 계산, Layer2별 분배 |

**중요**: SeigManager는 **다중 구현체 패턴**을 사용합니다. 단순 프록시 업그레이드가 아닌 **함수별 라우팅(Selector Routing)**으로 여러 구현체가 동시에 활성화됩니다.

### 버전별 함수 분포

| 버전 | 역할 | 비고 | 
|------|------|------|
| **SeigManagerV1_2** | 기본 구현체 (Index 0) - initialize, setData, deployCoinage 등 | `upgradeTo()`로 설정 |
| **SeigManagerV1_3** | pause/unpause, L2 시뇨리지 제외/포함 | Selector routing 필요 | 

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


### 상세 배포 절차 (Selector Routing 방식)

```solidity
// ==========================================
// Step 1: 모든 구현체 배포
// ==========================================
SeigManagerV1_2 seigManagerV1_2 = new SeigManagerV1_2();
SeigManagerV1_3 seigManagerV1_3 = new SeigManagerV1_3();

// ==========================================
// Step 2: 프록시 배포 및 기본 구현체 설정
// ==========================================
// 프록시는 3번 과정에서 배포한 seigManagerProxy를 사용
SeigManagerProxy proxy = new SeigManagerProxy();
proxy.upgradeTo(address(seigManagerV1_2));

// ==========================================
// Step 3: 초기화 (기본 구현체 함수 사용)
// ==========================================
//registry, seigPerBlock, factory 값 찾아오기
SeigManagerV1_2(address(proxy)).initialize(
    ton, wton, registry_, depositManagerProxy,
    seigPerBlock_, factory_, block.number
);

//아직 DAO가 배포되기 전이니 DAO 배포 후 세팅
// SeigManagerV1_2(address(proxy)).setData(
//     powerton_, daoAddress_, 0, 0.5e27, 0.5e27, 93096, 1000.1e27
// );

// ==========================================
// Step 4: V1_3 구현체 활성화
// ==========================================
proxy.setAliveImplementation2(address(seigManagerV1_3), true);

// ==========================================
// Step 5: V1_3 함수들을 V1_3 구현체로 라우팅
// ==========================================
bytes4[] memory v1_3Selectors = new bytes4[](N);
v1_3Selectors[0] = SeigManagerV1_3.pause.selector;
v1_3Selectors[1] = SeigManagerV1_3.unpause.selector;
v1_3Selectors[2] = SeigManagerV1_3.updateSeigniorage.selector;
v1_3Selectors[3] = SeigManagerV1_3.updateSeigniorageLayer.selector;
v1_3Selectors[4] = SeigManagerV1_3.estimatedDistribute.selector;
v1_3Selectors[5] = SeigManagerV1_3.claimableL2Seigniorage.selector;
v1_3Selectors[6] = SeigManagerV1_3.excludeFromL2Seigniorage.selector;
v1_3Selectors[7] = SeigManagerV1_3.includeFromL2Seigniorage.selector;

proxy.setSelectorImplementations2(v1_3Selectors, address(seigManagerV1_3));
```

---

## 6. DepositManager (다중 구현체 패턴) 

| 항목 | 설명 |
|------|------|
| 역할 | 스테이킹 예치/출금 관리 |
| 버전 | Base, _setWithdrawalDelay, V1_1, V1_2 (다중 구현체) |
| 패턴 | SeigManager와 동일한 Selector Routing 방식 |

### 버전별 함수 분포

| 버전 | Index | 역할 | 
|------|-------|------|
| **DepositManager** | 0 | 기본 구현체 - initialize, deposit, requestWithdrawal 등 | 
| **DepositManager_setWithdrawalDelay** | 1 | 출금 지연 설정 |
| **DepositManagerV1_1** | 2 | L2 출금 및 가스 제한 설정 | 

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

### 상세 배포 절차

```solidity
// Step 1: 모든 구현체 배포
DepositManager depositManagerBase = new DepositManager();
DepositManager_setWithdrawalDelay depositManagerSetDelay = new DepositManager_setWithdrawalDelay();
DepositManagerV1_1 depositManagerV1_1 = new DepositManagerV1_1();

// Step 2: 프록시 배포 및 기본 구현체 설정
// 프록시는 3번 과정에서 배포한 depositManagerProxy를 사용
DepositManagerProxy proxy = new DepositManagerProxy();
proxy.upgradeTo(address(depositManagerBase));

// Step 3: 초기화
// registry_ 값찾기
DepositManager(address(proxy)).initialize(
    wton, registry_, seigManagerProxy, globalWithdrawalDelay_, address(0)
);

// Step 4: Index 1, 2구현체 활성화
proxy.setAliveImplementation2(address(depositManagerSetDelay), true);
proxy.setAliveImplementation2(address(depositManagerV1_1), true);

// ==========================================
// Step 5: setWithdrawalDelay 함수들을 setWithdrawalDelay 구현체로 라우팅
// ==========================================
bytes4[] memory setWithdrawalDelaySelectors = new bytes4[](2);
setWithdrawalDelaySelectors[0] = DepositManager_setWithdrawalDelay.setWithdrawalDelay.selector;
setWithdrawalDelaySelectors[1] = DepositManager_setWithdrawalDelay.setWithdrawalDelayByOwner.selector;
proxy.setSelectorImplementations2(setWithdrawalDelaySelectors, address(depositManagerSetDelay));

// ==========================================
// Step 6: V1_1 함수들을 V1_1 구현체로 라우팅
// ==========================================
bytes4[] memory v1_1Selectors = new bytes4[](3);
v1_1Selectors[0] = DepositManagerV1_1.setMinDepositGasLimit.selector;
v1_1Selectors[1] = DepositManagerV1_1.setAddresses.selector;
v1_1Selectors[2] = DepositManagerV1_1.withdrawAndDepositL2.selector;
proxy.setSelectorImplementations2(v1_1Selectors, address(depositManagerV1_1));
```

---

## 7. Layer2Manager (Proxy 패턴) 

| 항목 | 설명 |
|------|------|
| 역할 | Layer2 등록 및 관리 |
| 버전 | V1_1 |

### 버전별 함수 분포

| 버전 | Index | 주요 함수 |
|------|-------|----------|
| **Layer2ManagerV1_1** | 0 | `setAddresses()`, `registerCandidateAddOn()`, `transferL2Seigniorage()` |


### 배포 절차

```solidity
// Step 1: 구현체 배포
Layer2ManagerV1_1 layer2ManagerV1_1 = new Layer2ManagerV1_1();

// Step 2: 프록시 배포 및 V1_1을 기본 구현체로 설정
// 프록시는 3번 과정에서 배포한 layer2ManagerProxy를 사용
Layer2ManagerProxy proxy = new Layer2ManagerProxy();
proxy.upgradeTo(address(layer2ManagerV1_1));

// Step 3: 초기화
// swapProxy는 address(0으로 설정해도 괜찮음
Layer2ManagerV1_1(address(proxy)).setAddresses(
    l1BridgeRegistry_, operatorManagerFactory_, ton_, wton_,
    dao_, depositManager_, seigManager_, swapProxy_
);
```

---

## 8. L1BridgeRegistry (Proxy 패턴) 

| 항목 | 설명 |
|------|------|
| 역할 | Optimism SystemConfig 등록 및 관리 |
| 버전 | V1_1 |

### 버전별 함수 분포

| 버전 | Index | 주요 함수 | 
|------|-------|----------|
| **L1BridgeRegistryV1_1** | 0 | `setAddresses()`, `rejectCandidateAddOn()`, `restoreCandidateAddOn()` |

### 배포 절차

```solidity
// Step 1: 구현체 배포
L1BridgeRegistryV1_1 l1BridgeRegistryV1_1 = new L1BridgeRegistryV1_1();

// Step 2: 프록시 배포 및 V1_1을 기본 구현체로 설정
// 프록시는 3번 과정에서 배포한 l1BridgeRegistryProxy를 사용
L1BridgeRegistryProxy proxy = new L1BridgeRegistryProxy();
proxy.upgradeTo(address(l1BridgeRegistryV1_1));

// Step 3: 초기화
// swapProxy는 address(0으로 설정해도 괜찮음
L1BridgeRegistryV1_1(address(proxy)).setAddresses(
    l1BridgeRegistry_, operatorManagerFactory_, ton_, wton_,
    dao_, depositManager_, seigManager_, swapProxy_
);
```

---


## 9. OperatorManagerFactory

| 항목 | 설명 |
|------|------|
| 역할 | Layer2 오퍼레이터 관리 | 
| 배포 방식 | OperatorManagerFactory가 프록시 생성 | 
| 구현체 | OperatorManagerV1_1 (기본) |

### 배포 절차

```solidity
// 1. OperatorManager 구현체 배포
OperatorManagerV1_1 operatorManagerV1_1Impl = new OperatorManagerV1_1();

// 2. Factory 배포 (V1_1을 기본 구현체로 사용)
OperatorManagerFactory factory = new OperatorManagerFactory(address(operatorManagerV1_1Impl));

// 3. 주소 설정
factory.setAddresses(depositManagerProxy, ton, wton, layer2ManagerProxy);
```

---


## 10. DAOCommittee (다중 구현체 패턴)

| 항목 | 설명 |
|------|------|
| 역할 | Tokamak생태계를 운영하는 DAO | 
| 버전 | DAOCommitteeProxy2, DAOCommittee_V1, DAOCommitteeOwner | 
| 패턴 | DAOCommitteeProxy가 DAOCommitteeProxy2를 라우팅, DAOCommitteeProxy2가 DAOCommittee_V1과 DAOCommitteeOwner를 라우팅 |


