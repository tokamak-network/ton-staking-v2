# TON Staking V2 전체 배포 가이드

이 문서는 TON Staking V2 시스템을 새로운 체인에 처음부터 배포하는 방법을 설명합니다.

## 목차

1. [배포 개요](#배포-개요)
2. [사전 요구사항](#사전-요구사항)
3. [배포 순서](#배포-순서)


## 배포 개요

TON Staking V3 시스템은 다음과 같은 구성요소로 이루어져 있습니다:

### 배포 컨트랙트 목록 (메인넷 기준)

#### 1. 토큰 컨트랙트 (프록시 없음)
| 컨트랙트 | 설명 | 비고 |
|----------|------|------|
| TON | 네이티브 TON 토큰 | ERC20 |
| WTON | Wrapped TON | ERC20, swapFromTON/swapToTON |

#### 2. 코어 인프라 (프록시 없음)
| 컨트랙트 | 설명 | 비고 |
|----------|------|------|
| RefactorCoinageSnapshot | 코이니지 로직 | 개별 코이니지의 구현체 |
| CoinageFactory | 코이니지 생성 팩토리 | setAutoCoinageLogic 필요 |

#### 3. 핵심 매니저 (프록시 패턴)
| 프록시 | 구현체 | 설명 | 
|--------|--------|------|
| SeigManagerProxy | SeigManager → V1_2 → V1_3 | 다중 구현체 패턴 |
| DepositManagerProxy | DepositManager → V1_1 | 스테이킹 관리 |
| Layer2RegistryProxy | Layer2Registry | Layer2 등록 | - |
| Layer2ManagerProxy | Layer2ManagerV1_1 → V1_2 | Layer2 관리 |
| L1BridgeRegistryProxy | L1BridgeRegistryV1_1 → V1_2 | 브릿지 등록 |

#### 4. DAO 관련 (프록시 패턴)
| 프록시 | 구현체 | 설명 |
|--------|--------|------|
| DAOCommitteeProxy | DAOCommitteeProxy2 → DAOCommittee_V1/Owner | DAO 거버넌스 (tokamak-dao-contracts) |
| - | DAOAgendaManager | DAO 안건 관리 (tokamak-dao-contracts) |
| - | DAOVault | DAO 자금 관리 (tokamak-dao-contracts) |
| CandidateFactoryProxy | CandidateFactory | DAO 후보자 팩토리 |
| CandidateAddOnFactoryProxy | CandidateAddOnFactory | 후보자 애드온 팩토리 |
| - | Candidate | 개별 후보자 구현체 |
| - | CandidateAddOnV1_1 | 개별 애드온 구현체 |

#### 5. 오퍼레이터 (프록시 없음)
| 컨트랙트 | 설명 | 비고 |
|----------|------|------|
| OperatorManagerFactory | 오퍼레이터 매니저 생성 | constructor에 impl 주소 |
| OperatorManagerV1_1 | 오퍼레이터 매니저 로직 | 팩토리가 프록시 생성 |

#### 6. 기타 (선택사항)
| 프록시 | 설명 | 비고 |
|--------|------|------|
| SwapProxy | TON↔WTON 스왑 | 없으면 address(0) 사용 |


### 아키텍처 다이어그램

```
┌─────────────────────────────────────────────────────────────────┐
│                    TON Staking V3 Architecture                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐     │
│  │     TON      │     │     WTON     │     │  Coinage     │     │
│  │   (ERC20)    │◄───►│   (ERC20)    │◄───►│   Factory    │     │
│  └──────────────┘     └──────────────┘     └──────────────┘     │
│         │                    │                    │             │
│         ▼                    ▼                    ▼             │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    SeigManager                          │    │
│  │           (시뇨리지 계산 및 분배 핵심 로직)                    │    │
│  └─────────────────────────────────────────────────────────┘    │
│         │                    │                    │             │
│         ▼                    ▼                    ▼             │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐     │
│  │   Deposit    │     │   Layer2     │     │ L1Bridge     │     │
│  │   Manager    │     │   Registry   │     │  Registry    │     │
│  └──────────────┘     └──────────────┘     └──────────────┘     │
│         │                                         │             │
│         ▼                                         ▼             │
│  ┌──────────────┐                         ┌──────────────┐      │
│  │   Layer2     │◄───────────────────────►│  Operator    │      │
│  │   Manager    │                         │ Mgr Factory  │      │
│  └──────────────┘                         └──────────────┘      │
│         │                                                       │
│         ▼                                                       │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    DAO (거버넌스)                         │    │
│  │  ┌─────────────────────────────────────────────────┐    │    │
│  │  │  DAOCommitteeProxy (tokamak-dao-contracts)      │    │    │
│  │  │      └── impl: DAOCommitteeProxy2               │    │    │
│  │  │              ├── [0] DAOCommittee_V1            │    │    │
│  │  │              └── [1] DAOCommitteeOwner          │    │    │
│  │  └─────────────────────────────────────────────────┘    │    │
│  │  ┌────────────┐ ┌──────────┐ ┌──────────┐ ┌─────────┐   │    │
│  │  │ Candidate  │ │ AddOn    │ │  Agenda  │ │   DAO   │   │    │
│  │  │  Factory   │ │ Factory  │ │  Manager │ │  Vault  │   │    │
│  │  └────────────┘ └──────────┘ └──────────┘ └─────────┘   │    │
│  │                                                         │    │
│  │  ※ 모든 프록시의 Owner = DAOCommitteeProxy                 │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```


## 사전 요구사항

### 필수 도구
- Foundry (forge, anvil)v1.5.0-stable 이상


## 배포 순서

배포는 **의존성 순서**를 반드시 지켜야 합니다. 잘못된 순서로 배포하면 초기화가 실패합니다.

### Phase 1: 토큰 배포

```
1. TON (ERC20)
   └── 의존성: 없음

2. WTON (Wrapped TON)
   └── 의존성: TON 주소 필요 (setTON 호출)
```

### Phase 2: 코이니지 인프라

```
3. RefactorCoinageSnapshot (로직 컨트랙트)
   └── 의존성: 없음

4. CoinageFactory
   └── 의존성: RefactorCoinageSnapshot 주소
   └── 설정: setAutoCoinageLogic(coinageLogic)
```


### Phase 3: 레지스트리

```
5. Layer2Registry (Proxy + Implementation)
   └── 의존성: 없음
   └── 패턴: Proxy.upgradeTo(implementation)
```

### Phase 4: 매니저 프록시 배포

```
6. SeigManagerProxy
7. DepositManagerProxy
8. Layer2ManagerProxy
9. L1BridgeRegistryProxy

└── 이 단계에서는 프록시만 배포 (구현체는 아직 연결 안함)
```

### Phase 5: 매니저 구현체 배포 및 초기화

```
10. SeigManager (Base Implementation)
    └── Proxy.upgradeTo(seigManagerBase)
    └── SeigManager.initialize(...)
    └── SeigManager.setData(...)  // 시뇨리지 분배 비율 설정

11. DepositManager (Base Implementation)
    └── Proxy.upgradeTo(depositManagerBase)
    └── DepositManager.initialize(...)

12. Layer2ManagerV1_1
    └── Proxy.upgradeTo(layer2ManagerV1_1)
    └── 나중에 setAddresses

13. L1BridgeRegistryV1_1
    └── Proxy.upgradeTo(l1BridgeRegistryV1_1)
    └── 나중에 setAddresses 
```

### Phase 5.5: Minter 권한 설정 (중요!)


```
14. Layer2Registry.addMinter(seigManagerProxy)
    └── SeigManager가 코이니지 생성 가능하도록

15. WTON.addMinter(seigManagerProxy)
    └── SeigManager가 시뇨리지(WTON) 발행 가능하도록
```


### Phase 6: OperatorManagerFactory

```
16. OperatorManagerV1_1 (구현체) - 기본 구현체
17. OperatorManagerFactory(operatorManagerV1_1Impl)
```