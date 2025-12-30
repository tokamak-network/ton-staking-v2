# TON Staking V3 컨트랙트별 상세 설명

이 문서는 각 컨트랙트의 배포 절차와 다중 구현체 패턴을 상세히 설명합니다.

> **관련 문서**
> - [deployment-guide.md](./deployment-guide.md): 배포 개요 및 순서

---

## 목차

1. [TON / WTON](#1-ton--wton)
2. [CoinageFactory](#2-coinagefactory)
3. [Proxy Deploy](#3-proxy-deploy)
4. [Layer2Registry (Proxy 패턴)](#4-layer2registry-proxy-패턴)
5. [SeigManager (다중 구현체)](#5-seigmanager-다중-구현체-패턴)
6. [DepositManager (다중 구현체)](#6-depositmanager-다중-구현체-패턴)
7. [Layer2Manager (Proxy 패턴)](#7-layer2manager-proxy-패턴)
8. [L1BridgeRegistry (Proxy 패턴)](#8-l1bridgeregistry-proxy-패턴)
9. [OperatorManagerFactory](#9-operatormanagerfactory)
10. [DAOVault](#10-daovault)
11. [DAOAgendaManager](#11-daoagendamanager)
12. [DAOCommittee (다중 구현체)](#12-daocommittee)
13. [CandidateFactory](#13-candidatefactory)
14. [CandidateAddOnFactory](#14-candidateaddonfactory)
15. [DAOContract 설정](#15-daocontract-설정)
16. [Contract Owner 설정](#16-contract-owner-설정)
17. [Mint 권한 설정](#17-mint-권한-설정)


---

## 1. TON / WTON

| 항목 | 설명 |
|------|------|
| 역할 | TON은 네이티브 토큰, WTON은 Wrapped 버전 |
| 테스트용 | abi를 이용해 배포 |
| 프로덕션용 | 실제 TON/WTON 주소 사용 |

```solidity
// TON 배포
ton = deployCode("abis/TON.json");

// WTON 배포
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
// RefactorCoinageSnapshot 배포
RefactorCoinageSnapshot coinageLogic = new RefactorCoinageSnapshot();

// CoinageFactory 배포s
CoinageFactory factory = new CoinageFactory();

// CoinageFactory 기본 구현체 설정
factory.setAutoCoinageLogic(address(coinageLogic));
```

---

## 3. Proxy Deploy (SeigManagerProxy, DepositManagerProxy, Layer2RegistryProxy, Layer2ManagerProxy, L1BridgeRegistryProxy)

| 항목 | 설명 |
|------|------|
| 역할 | 프록시 컨트랙트들을 미리 배포 |

```solidity
// Proxy들 배포
SeigManagerProxy seigManagerProxy = new SeigManagerProxy();
DepositManagerProxy depositManagerProxy = new DepositManagerProxy();
Layer2RegistryProxy layer2RegistryProxy = new Layer2RegistryProxy();
Layer2ManagerProxy layer2ManagerProxy = new Layer2ManagerProxy();
L1BridgeRegistryProxy l1BridgeRegistryProxy = new L1BridgeRegistryProxy();
```

---

## 4. Layer2Registry (Proxy 패턴)
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


## 5. SeigManager (다중 구현체 패턴) 

| 항목 | 설명 |
|------|------|
| 역할 | 시뇨리지 계산 및 분배의 핵심 |
| 버전 | Base, V1_1, V1_2, V1_Slashing (다중 구현체) |
| 주요 기능 | 블록당 시뇨리지 계산, Layer2별 분배 |

**중요**: SeigManager는 **다중 구현체 패턴**을 사용합니다. 단순 프록시 업그레이드가 아닌 **함수별 라우팅(Selector Routing)**으로 여러 구현체가 동시에 활성화됩니다.

### 버전별 함수 분포

| 버전 | 역할 | 비고 | 
|------|------|------|
| **SeigManagerV1_2** | 기본 구현체 (Index 0) - initialize, setData, deployCoinage 등 | `upgradeTo()`로 설정 |
| **SeigManagerV1_Slashing** | pause/unpause, L2 시뇨리지 제외/포함 | Selector routing 필요 | 

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
| `onSlash(address,address)` | `0x453260d7` | L2의 Operator에 대한 슬래시 발생 |


### 상세 배포 절차 (Selector Routing 방식)

```solidity
// ==========================================
// Step 1: 모든 구현체 배포
// ==========================================
SeigManagerV1_2 seigManagerV1_2 = new SeigManagerV1_2();
SeigManagerV1_Slashing seigManagerV1_Slashing = new SeigManagerV1_Slashing();

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
// Step 4: V1_Slashing 구현체 활성화
// ==========================================
proxy.setAliveImplementation2(address(seigManagerV1_Slashing), true);

// ==========================================
// Step 5: V1_Slashing 함수들을 V1_Slashing 구현체로 라우팅
// ==========================================
bytes4[] memory v1_SlashingSelectors = new bytes4[](N);
v1_SlashingSelectors[0] = SeigManagerV1_Slashing.pause.selector;
v1_SlashingSelectors[1] = SeigManagerV1_Slashing.unpause.selector;
v1_SlashingSelectors[2] = SeigManagerV1_Slashing.updateSeigniorage.selector;
v1_SlashingSelectors[3] = SeigManagerV1_Slashing.updateSeigniorageLayer.selector;
v1_SlashingSelectors[4] = SeigManagerV1_Slashing.estimatedDistribute.selector;
v1_SlashingSelectors[5] = SeigManagerV1_Slashing.claimableL2Seigniorage.selector;
v1_SlashingSelectors[6] = SeigManagerV1_Slashing.excludeFromL2Seigniorage.selector;
v1_SlashingSelectors[7] = SeigManagerV1_Slashing.includeFromL2Seigniorage.selector;
v1_SlashingSelectors[8] = SeigManagerV1_Slashing.onSlash.selector;

proxy.setSelectorImplementations2(v1_SlashingSelectors, address(seigManagerV1_Slashing));

// ==========================================
// Step 6: SlashingRewardRate를 세팅
// ==========================================
// 1000 = 10%, 10000 = 100%
SeigManagerV1_Slashing(address(proxy)).setSlashingRewardRate(1000);
```

---

## 6. DepositManager (다중 구현체 패턴) 

| 항목 | 설명 |
|------|------|
| 역할 | 스테이킹 예치/출금 관리 |
| 버전 | Base, _setWithdrawalDelay, V1_Slashing (다중 구현체) |
| 패턴 | SeigManager와 동일한 Selector Routing 방식 |

### 버전별 함수 분포

| 버전 | Index | 역할 | 
|------|-------|------|
| **DepositManager** | 0 | 기본 구현체 - initialize, deposit, requestWithdrawal 등 | 
| **DepositManager_setWithdrawalDelay** | 1 | 출금 지연 설정 |
| **DepositManagerV1_Slashing** | 2 | L2 출금 및 가스 제한 설정 및 슬래싱 기능 추가 | 

### DepositManager_setWithdrawalDelay (Index 1) 등록 함수 목록

| 함수 시그니처 | Selector | 설명 |
|--------------|----------|------|
| `setWithdrawalDelay(address,uint256)` | `0xdc5a709f` | Layer2별 출금 지연 설정 |
| `setWithdrawalDelayByOwner(address,uint256)` | `0x377db38b` | Owner 전용 출금 지연 설정 |

### DepositManagerV1_Slashing (Index 2) 등록 함수 목록

| 함수 시그니처 | Selector | 설명 |
|--------------|----------|------|
| `setMinDepositGasLimit(uint256)` | - | 최소 예치 가스 제한 설정 |
| `setAddresses(address,address)` | `0x90107afe` | L1BridgeRegistry, Layer2Manager 주소 설정 |
| `withdrawAndDepositL2(address,uint256)` | `0x9f382d11` | 출금 후 L2 예치 |
| `slash(address,address,address)` | `0x563bf264` | Operator에 대한 슬래싱 진행 및 Challenger에게 reward 지급 |

### 상세 배포 절차

```solidity
// Step 1: 모든 구현체 배포
DepositManager depositManagerBase = new DepositManager();
DepositManager_setWithdrawalDelay depositManagerSetDelay = new DepositManager_setWithdrawalDelay();
DepositManagerV1_Slashing depositManagerV1_Slashing = new DepositManagerV1_Slashing();

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
proxy.setAliveImplementation2(address(depositManagerV1_Slashing), true);

// ==========================================
// Step 5: setWithdrawalDelay 함수들을 setWithdrawalDelay 구현체로 라우팅
// ==========================================
bytes4[] memory setWithdrawalDelaySelectors = new bytes4[](2);
setWithdrawalDelaySelectors[0] = DepositManager_setWithdrawalDelay.setWithdrawalDelay.selector;
setWithdrawalDelaySelectors[1] = DepositManager_setWithdrawalDelay.setWithdrawalDelayByOwner.selector;
proxy.setSelectorImplementations2(setWithdrawalDelaySelectors, address(depositManagerSetDelay));

// ==========================================
// Step 6: V1_Slashing 함수들을 V1_Slashing 구현체로 라우팅
// ==========================================
bytes4[] memory v1_SlashingSelectors = new bytes4[](3);
v1_SlashingSelectors[0] = Deposit   ManagerV1_Slashing.setMinDepositGasLimit.selector;
v1_SlashingSelectors[1] = DepositManagerV1_Slashing.setAddresses.selector;
v1_SlashingSelectors[2] = DepositManagerV1_Slashing.withdrawAndDepositL2.selector;
proxy.setSelectorImplementations2(v1_SlashingSelectors, address(depositManagerV1_Slashing));
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
| **Layer2ManagerV1_Slashing** | 0 | `setAddresses()`, `registerCandidateAddOn()`, `transferL2Seigniorage()`, `slashingCandidate()` |


### 배포 절차

```solidity
// Step 1: 구현체 배포
Layer2ManagerV1_Slashing layer2ManagerV1_Slashing = new Layer2ManagerV1_Slashing();

// Step 2: 프록시 배포 및 V1_1을 기본 구현체로 설정
// 프록시는 3번 과정에서 배포한 layer2ManagerProxy를 사용
Layer2ManagerProxy proxy = new Layer2ManagerProxy();
proxy.upgradeTo(address(layer2ManagerV1_Slashing));

// Step 3: 초기화
// swapProxy는 address(0으로 설정해도 괜찮음
Layer2ManagerV1_Slashing(address(proxy)).setAddresses(
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

## 10. DAOVault

| 항목 | 설명 |
|------|------|
| 역할 | TokamakDAO의 자금 관리 | 
| 버전 | DAOVault | 
| 의존성 | TON, WTON 주소 |

```solidity
// DAOVault 배포 (TON, WTON 의존성)
bytes memory daovaultArgs = abi.encode(ton, wton);
daoVault = deployCode("abis/DAOVault.json", daovaultArgs);
```


---

## 11. DAOAgendaManager

| 항목 | 설명 |
|------|------|
| 역할 | TokamakDAO의 Agenda 관리 | 
| 버전 | DAOAgendaManager | 

```solidity
// DAOAgendaManager 배포 (의존성 없음)
daoAgendaManager = deployCode("abis/DAOAgendaManager.json");
```


---

## 12. DAOCommittee (다중 구현체 패턴)

| 항목 | 설명 |
|------|------|
| 역할 | Tokamak생태계를 운영하는 DAO | 
| 버전 | DAOCommitteeProxy2, DAOCommittee_V1, DAOCommitteeOwner | 
| 패턴 | DAOCommitteeProxy가 DAOCommitteeProxy2를 라우팅, DAOCommitteeProxy2가 DAOCommittee_V1과 DAOCommitteeOwner를 라우팅 |


## DAO 프록시 구조

```
┌─────────────────────────────────────────────────────────────────┐
│                    DAO Committee 호출 흐름                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  User Call                                                      │
│      │                                                          │
│      ▼                                                          │
│  ┌───────────────────────────────────────────┐                  │
│  │  DAOCommitteeProxy (tokamak-dao-contracts)│                  │
│  │  - 메인 프록시                               │                  │
│  │  - implementation() → DAOCommitteeProxy2  │                  │
│  └───────────────────────────────────────────┘                  │
│      │ delegatecall                                             │
│      ▼                                                          │
│  ┌───────────────────────────────────────────┐                  │
│  │  DAOCommitteeProxy2 (ton-staking-v2)      │                  │
│  │  - 다중 구현체 라우터                         │                  │
│  │  - implementation2(0) → DAOCommittee_V1   │                  │
│  │  - setAliveImplementation2()              │                  │
│  │  - setSelectorImplementations2()          │                  │
│  └───────────────────────────────────────────┘                  │
│      │ delegatecall (selector 기반)                              │
│      ▼                                                          │
│  ┌───────────────────────────────────────────┐                  │
│  │  implementation2[0]: DAOCommittee_V1      │                  │
│  │  - 메인 비즈니스 로직                         │                  │
│  │  - createCandidate()                      │                  │
│  │  - createCandidateAddOn()                 │                  │
│  │  - castVote(), executeAgenda()            │                  │
│  └───────────────────────────────────────────┘                  │
│                                                                 │
│  ┌───────────────────────────────────────────┐                  │
│  │  implementation2[1]: DAOCommitteeOwner    │                  │
│  │  - Owner 전용 설정 함수                      │                  │
│  │  - setSeigManager(), setLayer2Manager()   │                  │
│  │  - setCandidateFactory()                  │                  │
│  │  - increaseMaxMember(), setQuorum()       │                  │
│  │  - daoExecuteTransaction()                │                  │
│  └───────────────────────────────────────────┘                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## DAOCommitteeOwner 함수 목록

| Index | 함수 시그니처 | 설명 |
|-------|--------------|------|
| 0 | `setCooldownTime(uint256)` | 쿨다운 시간 설정 |
| 1 | `setCandidateAddOnFactory(address)` | CandidateAddOnFactory 주소 설정 |
| 2 | `setLayer2Manager(address)` | Layer2Manager 주소 설정 |
| 3 | `setSeigManager(address)` | SeigManager 주소 설정 |
| 4 | `setDaoVault(address)` | DAOVault 주소 설정 |
| 5 | `setLayer2Registry(address)` | Layer2Registry 주소 설정 |
| 6 | `setAgendaManager(address)` | AgendaManager 주소 설정 |
| 7 | `setCandidateFactory(address)` | CandidateFactory 주소 설정 |
| 8 | `setTon(address)` | TON 주소 설정 |
| 9 | `setWton(address)` | WTON 주소 설정 |
| 10 | `increaseMaxMember(uint256,uint256)` | 최대 멤버 수 증가 |
| 11 | `setQuorum(uint256,uint256)` | 정족수 설정 |
| 12 | `decreaseMaxMember(uint256,uint256)` | 최대 멤버 수 감소 |
| 13 | `setActivityRewardPerSecond(uint256)` | 활동 보상 설정 |
| 14 | `setCandidatesSeigManager(address,address)` | 후보자 SeigManager 설정 |
| 15 | `setCandidatesCommittee(address,address)` | 후보자 Committee 설정 |
| 16 | `daoExecuteTransaction(address,bytes)` | DAO 트랜잭션 실행 |

---

### 배포 순서

```
1. DAOCommitteeProxy (tokamak-dao-contracts) - 메인 프록시
   └── Constructor(ton, impl, seigManager, layer2Registry, agendaManager, candidateFactory, daoVault)
   └── impl에 DAOCommitteeProxy2 설정

2. DAOCommitteeProxy2 (ton-staking-v2) - DAOCommitteeProxy의 implementation
   └── 다중 구현체 패턴 라우터 (setAliveImplementation2, setSelectorImplementations2)
   └── DAOCommitteeProxy.upgradeTo(DAOCommitteeProxy2)로 설정

3. DAOCommittee_V1 (구현체) - implementation2[0]
   └── DAO 위원회 메인 로직 (createCandidate, castVote, executeAgenda 등)
   └── DAOCommitteeProxy2.upgradeTo2(DAOCommittee_V1)로 설정

4. DAOCommitteeOwner (구현체) - implementation2[1]
   └── Owner 전용 설정 함수 (setSeigManager, setLayer2Manager, setQuorum 등)
   └── setAliveImplementation2 + setSelectorImplementations2로 함수 매칭

5. Candidate (구현체)
   └── DAO 후보자 로직 (개별 인스턴스)

6. CandidateFactory (Proxy + Implementation)
   └── CandidateFactoryProxy + CandidateFactory
   └── 설정: setAddress(depositManager, daoCommittee, candidate, ton, wton)

7. CandidateAddOnV1_1 (구현체)
   └── DAO 후보자 애드온 로직 (Layer2Manager 연동)

8. CandidateAddOnFactory (Proxy + Implementation)
   └── CandidateAddOnFactoryProxy + CandidateAddOnFactory
   └── 설정: setAddresses(...)
```

### 상세 배포 코드

```solidity
// ==========================================
// Step 1: DAOCommitteeProxy 배포 (tokamak-dao-contracts)
// ==========================================
DAOCommitteeProxy daoCommitteeProxy = new DAOCommitteeProxy(
    ton_,                    // TON 토큰 주소
    address(0),              // impl (Step 2에서 DAOCommitteeProxy2로 설정)
    seigManagerProxy_,       // SeigManager 프록시
    layer2RegistryProxy_,    // Layer2Registry 프록시
    agendaManagerProxy_,     // AgendaManager 프록시 (별도 배포 필요)
    address(0),              // candidateFactory (나중에 설정)
    daoVaultProxy_           // DAOVault 프록시 (별도 배포 필요)
);

// ==========================================
// Step 2: DAOCommitteeProxy2 배포 및 설정 (ton-staking-v2)
// ==========================================
DAOCommitteeProxy2 daoCommitteeProxy2 = new DAOCommitteeProxy2();
daoCommitteeProxy.upgradeTo(address(daoCommitteeProxy2));

// ==========================================
// Step 3: DAOCommittee_V1 구현체 배포 및 설정
// ==========================================
DAOCommittee_V1 daoCommitteeImpl = new DAOCommittee_V1();
DAOCommitteeProxy2(address(daoCommitteeProxy)).upgradeTo2(address(daoCommitteeImpl));

// ==========================================
// Step 4: DAOCommitteeOwner 배포 및 Selector Routing
// ==========================================
DAOCommitteeOwner daoCommitteeOwner = new DAOCommitteeOwner();
DAOCommitteeProxy2(address(daoCommitteeProxy)).setAliveImplementation2(address(daoCommitteeOwner), true);

// DAOCommitteeOwner 함수들을 Index 1로 라우팅
bytes4[] memory ownerSelectors = new bytes4[](17);
ownerSelectors[0] = DAOCommitteeOwner.setCooldownTime.selector;
ownerSelectors[1] = DAOCommitteeOwner.setCandidateAddOnFactory.selector;
ownerSelectors[2] = DAOCommitteeOwner.setLayer2Manager.selector;
ownerSelectors[3] = DAOCommitteeOwner.setSeigManager.selector;
ownerSelectors[4] = DAOCommitteeOwner.setDaoVault.selector;
ownerSelectors[5] = DAOCommitteeOwner.setLayer2Registry.selector;
ownerSelectors[6] = DAOCommitteeOwner.setAgendaManager.selector;
ownerSelectors[7] = DAOCommitteeOwner.setCandidateFactory.selector;
ownerSelectors[8] = DAOCommitteeOwner.setTon.selector;
ownerSelectors[9] = DAOCommitteeOwner.setWton.selector;
ownerSelectors[10] = DAOCommitteeOwner.increaseMaxMember.selector;
ownerSelectors[11] = DAOCommitteeOwner.setQuorum.selector;
ownerSelectors[12] = DAOCommitteeOwner.decreaseMaxMember.selector;
ownerSelectors[13] = DAOCommitteeOwner.setActivityRewardPerSecond.selector;
ownerSelectors[14] = DAOCommitteeOwner.setCandidatesSeigManager.selector;
ownerSelectors[15] = DAOCommitteeOwner.setCandidatesCommittee.selector;
ownerSelectors[16] = DAOCommitteeOwner.daoExecuteTransaction.selector;
DAOCommitteeProxy2(address(daoCommitteeProxy)).setSelectorImplementations2(ownerSelectors, address(daoCommitteeOwner));

// ==========================================
// Step 5: Candidate 구현체 배포
// ==========================================
Candidate candidateImpl = new Candidate();

// ==========================================
// Step 6: CandidateFactory 배포 및 설정
// ==========================================
CandidateFactory candidateFactoryLogic = new CandidateFactory();
CandidateFactoryProxy candidateFactoryProxy = new CandidateFactoryProxy();
candidateFactoryProxy.upgradeTo(address(candidateFactoryLogic));

CandidateFactory(address(candidateFactoryProxy)).setAddress(
    depositManagerProxy_,
    address(daoCommitteeProxy),
    address(candidateImpl),
    ton_,
    wton_
);

// ==========================================
// Step 7: CandidateAddOn 배포 및 설정
// ==========================================
CandidateAddOnV1_1 candidateAddOnImpl = new CandidateAddOnV1_1();

CandidateAddOnFactory candidateAddOnFactoryLogic = new CandidateAddOnFactory();
CandidateAddOnFactoryProxy candidateAddOnFactoryProxy = new CandidateAddOnFactoryProxy();
candidateAddOnFactoryProxy.upgradeTo(address(candidateAddOnFactoryLogic));

CandidateAddOnFactory(address(candidateAddOnFactoryProxy)).setAddresses(
    address(candidateAddOnImpl),
    address(daoCommitteeProxy),
    seigManagerProxy_,
    ton_,
    wton_
);

// ==========================================
// Step 8: DAOCommittee 설정
// ==========================================
DAOCommitteeOwner(address(daoCommitteeProxy)).setCandidateFactory(address(candidateFactoryProxy));
DAOCommitteeOwner(address(daoCommitteeProxy)).setSeigManager(seigManagerProxy_);
DAOCommitteeOwner(address(daoCommitteeProxy)).setCandidateAddOnFactory(address(candidateAddOnFactoryProxy));
DAOCommitteeOwner(address(daoCommitteeProxy)).setLayer2Manager(layer2ManagerProxy_);
```

---

## 13. CandidateFactory

| 항목 | 설명 |
|------|------|
| 역할 | 후보자 생성 | 
| 배포 방식 | CandidateFactoryProxy가 프록시 생성 | 
| 구현체 | Candidate (기본) |

### 배포 절차

```solidity
// ==========================================
// Step 1: Candidate 구현체 배포
// ==========================================
Candidate candidateImpl = new Candidate();

// ==========================================
// Step 2: CandidateFactory 배포 및 설정
// ==========================================
CandidateFactory candidateFactoryLogic = new CandidateFactory();
CandidateFactoryProxy candidateFactoryProxy = new CandidateFactoryProxy();
candidateFactoryProxy.upgradeTo(address(candidateFactoryLogic));

CandidateFactory(address(candidateFactoryProxy)).setAddress(
    depositManagerProxy_,
    address(daoCommitteeProxy),
    address(candidateImpl),
    ton_,
    wton_
);
```

---

## 14. CandidateAddOnFactory

| 항목 | 설명 |
|------|------|
| 역할 | L2 후보자 생성 | 
| 배포 방식 | CandidateAddOnFactoryProxy가 프록시 생성 | 
| 구현체 | CandidateAddOnV1_1 (기본) |

### 배포 절차

```solidity
// ==========================================
// Step 1: CandidateAddOn 배포 및 설정
// ==========================================
CandidateAddOnV1_1 candidateAddOnImpl = new CandidateAddOnV1_1();

CandidateAddOnFactory candidateAddOnFactoryLogic = new CandidateAddOnFactory();
CandidateAddOnFactoryProxy candidateAddOnFactoryProxy = new CandidateAddOnFactoryProxy();
candidateAddOnFactoryProxy.upgradeTo(address(candidateAddOnFactoryLogic));

CandidateAddOnFactory(address(candidateAddOnFactoryProxy)).setAddresses(
    address(candidateAddOnImpl),
    address(daoCommitteeProxy),
    seigManagerProxy_,
    ton_,
    wton_
);
```

---

## 15. DAOContract 설정
| 항목 | 설명 |
|------|------|
| 역할 | DAOContract 설정 | 

### 설정 절차

```solidity
// ==========================================
// Step 8: DAOCommittee 설정
// ==========================================
DAOCommitteeOwner(address(daoCommitteeProxy)).setCandidateFactory(address(candidateFactoryProxy));
DAOCommitteeOwner(address(daoCommitteeProxy)).setSeigManager(seigManagerProxy_);
DAOCommitteeOwner(address(daoCommitteeProxy)).setCandidateAddOnFactory(address(candidateAddOnFactoryProxy));
DAOCommitteeOwner(address(daoCommitteeProxy)).setLayer2Manager(layer2ManagerProxy_);
```
---

## 16. Contract Owner 설정
| 항목 | 설명 |
|------|------|
| 역할 | 컨트랙트의 Owner 설정 | 

### 설정 절차

```solidity
// 배포 완료 후 owner를 DAO로 이전

// 핵심 매니저
SeigManagerProxy(seigManagerProxy).transferOwnership(daoCommitteeProxy);
DepositManagerProxy(depositManagerProxy).transferOwnership(daoCommitteeProxy);
Layer2RegistryProxy(layer2RegistryProxy).transferOwnership(daoCommitteeProxy);
Layer2ManagerProxy(layer2ManagerProxy).transferOwnership(daoCommitteeProxy);
L1BridgeRegistryProxy(l1BridgeRegistryProxy).transferOwnership(daoCommitteeProxy);

// DAO 관련
CandidateFactoryProxy(candidateFactoryProxy).transferOwnership(daoCommitteeProxy);
CandidateAddOnFactoryProxy(candidateAddOnFactoryProxy).transferOwnership(daoCommitteeProxy);

// V3 신규
RATProxy(ratProxy).transferOwnership(daoCommitteeProxy);
ValidatorRewardProxy(validatorRewardProxy).transferOwnership(daoCommitteeProxy);
SequencerVaultProxy(sequencerVaultProxy).transferOwnership(daoCommitteeProxy);
```

## 17. Mint 권한 설정
| 항목 | 설명 |
|------|------|
| 역할 | Mint 권한 설정 | 

### 설정 절차

```solidity
//SeigManager가 코이니지 생성 가능하도록
layer2Registry.addMinter(seigManagerProxy)
//SeigManager가 시뇨리지(WTON) 발행 가능하도록
wton.addMinter(seigManagerProxy)
```