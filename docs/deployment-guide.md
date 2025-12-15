# TON Staking V3 전체 배포 가이드

이 문서는 TON Staking V3 시스템을 새로운 체인에 처음부터 배포하는 방법을 설명합니다.

> **V3 업그레이드 표시 범례**
> - 🆕 **V3 신규**: V3에서 새로 추가된 컨트랙트/기능
> - 🔄 **V3 변경**: V3에서 수정/업그레이드된 부분
> - ⚠️ **V3 주의**: V3 업그레이드시 특별히 주의해야 할 사항

## 목차

1. [배포 개요](#배포-개요)
2. [사전 요구사항](#사전-요구사항)
3. [배포 순서](#배포-순서)
4. [컨트랙트별 상세 설명](#컨트랙트별-상세-설명)
5. [초기화 파라미터](#초기화-파라미터)
6. [배포 스크립트 사용법](#배포-스크립트-사용법)
7. [검증 및 테스트](#검증-및-테스트)

---

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
| 프록시 | 구현체 | 설명 | V3 |
|--------|--------|------|-----|
| SeigManagerProxy | SeigManager → V1_2 → V1_3 → V1_4 | 다중 구현체 패턴 | 🔄 V1_4 추가 |
| DepositManagerProxy | DepositManager → V1_1 → V1_2 | 스테이킹 관리 | 🔄 V1_2 추가 |
| Layer2RegistryProxy | Layer2Registry | Layer2 등록 | - |
| Layer2ManagerProxy | Layer2ManagerV1_1 → V1_2 | Layer2 관리 | 🔄 V1_2 multi-impl |
| L1BridgeRegistryProxy | L1BridgeRegistryV1_1 → V1_2 | 브릿지 등록 | 🔄 V1_2 multi-impl |

#### 4. DAO 관련 (프록시 패턴)
| 프록시 | 구현체 | 설명 |
|--------|--------|------|
| DAOCommitteeProxy | DAOCommitteeProxy2 → DAOCommittee_V1/Owner | DAO 거버넌스 (tokamak-dao-contracts) |
| DAOAgendaManagerProxy | DAOAgendaManager | DAO 안건 관리 (tokamak-dao-contracts) |
| DAOVaultProxy | DAOVault | DAO 자금 관리 (tokamak-dao-contracts) |
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

#### 7. 🆕 V3 신규 컨트랙트 (프록시 패턴)
| 프록시 | 구현체 | 설명 | V3 |
|--------|--------|------|-----|
| RATProxy | RAT | Randomized Attention Test | 🆕 신규 |
| ValidatorPoolProxy | ValidatorPoolV1 | 검증자 풀 관리 | 🆕 신규 |

### 아키텍처 다이어그램

```
┌─────────────────────────────────────────────────────────────────┐
│                    TON Staking V3 Architecture                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐     │
│  │     TON      │     │     WTON     │     │  Coinage     │     │
│  │   (ERC20)    │◄───►│   (ERC20)    │◄───►│   Factory    │     │
│  └──────────────┘     └──────────────┘     └──────────────┘     │
│         │                    │                    │              │
│         ▼                    ▼                    ▼              │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    SeigManager                           │    │
│  │           (시뇨리지 계산 및 분배 핵심 로직)               │    │
│  └─────────────────────────────────────────────────────────┘    │
│         │                    │                    │              │
│         ▼                    ▼                    ▼              │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐     │
│  │   Deposit    │     │   Layer2     │     │ L1Bridge     │     │
│  │   Manager    │     │   Registry   │     │  Registry    │     │
│  └──────────────┘     └──────────────┘     └──────────────┘     │
│         │                                         │              │
│         ▼                                         ▼              │
│  ┌──────────────┐                         ┌──────────────┐      │
│  │   Layer2     │◄───────────────────────►│  Operator    │      │
│  │   Manager    │                         │ Mgr Factory  │      │
│  └──────────────┘                         └──────────────┘      │
│         │                                                        │
│         ▼                                                        │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    DAO (거버넌스)                         │    │
│  │  ┌─────────────────────────────────────────────────┐    │    │
│  │  │  DAOCommitteeProxy (tokamak-dao-contracts)      │    │    │
│  │  │      └── impl: DAOCommitteeProxy2               │    │    │
│  │  │              ├── [0] DAOCommittee_V1            │    │    │
│  │  │              └── [1] DAOCommitteeOwner          │    │    │
│  │  └─────────────────────────────────────────────────┘    │    │
│  │  ┌────────────┐ ┌──────────┐ ┌──────────┐ ┌─────────┐  │    │
│  │  │ Candidate  │ │ AddOn    │ │  Agenda  │ │   DAO   │  │    │
│  │  │  Factory   │ │ Factory  │ │  Manager │ │  Vault  │  │    │
│  │  └────────────┘ └──────────┘ └──────────┘ └─────────┘  │    │
│  │                                                         │    │
│  │  ※ 모든 프록시의 Owner = DAOCommitteeProxy              │    │
│  └─────────────────────────────────────────────────────────┘    │
│         │                                                        │
│         ▼                                                        │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    V3 New Contracts                      │    │
│  │  ┌──────────────┐              ┌──────────────┐         │    │
│  │  │     RAT      │              │  Validator   │         │    │
│  │  │  (Attention  │              │    Pool      │         │    │
│  │  │    Test)     │              │              │         │    │
│  │  └──────────────┘              └──────────────┘         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 사전 요구사항

### 필수 도구
- Foundry (forge, anvil) v0.2.0 이상
- Node.js v18+ (선택사항, 테스트용)
- Go 1.22+ (E2E 테스트용)

### 환경 변수
```bash
# 배포자 개인키 (테스트용 기본값 사용 가능)
export PRIVATE_KEY=0x...

# RPC URL
export RPC_URL=http://localhost:8545
```

---

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
    └── Proxy.upgradeTo(seigManagerV1_4)  // V1_4로 업그레이드

11. DepositManager (Base Implementation)
    └── Proxy.upgradeTo(depositManagerBase)
    └── DepositManager.initialize(...)
    └── Proxy.upgradeTo(depositManagerV1_2)  // V1_2로 업그레이드

12. Layer2ManagerV1_1
    └── Proxy.upgradeTo(layer2ManagerV1_1)
    └── 나중에 setAddresses 후 V1_2 Selector Routing (multi-impl)

13. L1BridgeRegistryV1_1
    └── Proxy.upgradeTo(l1BridgeRegistryV1_1)
    └── 나중에 setAddresses 후 V1_2 Selector Routing (multi-impl)
```

### Phase 5.5: Minter 권한 설정 (중요!)

> ✅ **구현 완료**: DeployV3Full.s.sol의 `_setupMinterPermissions()` 함수에서 자동으로 설정됩니다.

```
14. Layer2Registry.addMinter(seigManagerProxy)
    └── SeigManager가 코이니지 생성 가능하도록

15. WTON.addMinter(seigManagerProxy)
    └── SeigManager가 시뇨리지(WTON) 발행 가능하도록
```

### Phase 6: OperatorManagerFactory

```
16. OperatorManagerV1_1 (구현체)
17. OperatorManagerFactory
    └── constructor(operatorManagerV1_1)
```

### Phase 6.5: DAO 컨트랙트

> ✅ **구현 완료**: `script/DeployDAO.s.sol` 스크립트를 사용하여 배포할 수 있습니다. DeployV3Full.s.sol과 별도로 실행해야 합니다.

DAO 컨트랙트는 거버넌스 기능을 위해 필요합니다. Layer2 후보자 등록, 투표 등의 기능을 제공합니다.

```
18. DAOCommitteeProxy (tokamak-dao-contracts) - 메인 프록시
    └── Constructor(ton, impl, seigManager, layer2Registry, agendaManager, candidateFactory, daoVault)
    └── impl에 DAOCommitteeProxy2 설정

19. DAOCommitteeProxy2 (ton-staking-v2) - DAOCommitteeProxy의 implementation
    └── 다중 구현체 패턴 라우터 (setAliveImplementation2, setSelectorImplementations2)
    └── DAOCommitteeProxy.upgradeTo(DAOCommitteeProxy2)로 설정

20. DAOCommittee_V1 (구현체) - implementation2[0]
    └── DAO 위원회 메인 로직 (createCandidate, castVote, executeAgenda 등)
    └── DAOCommitteeProxy2.upgradeTo2(DAOCommittee_V1)로 설정

21. DAOCommitteeOwner (구현체) - implementation2[1]
    └── Owner 전용 설정 함수 (setSeigManager, setLayer2Manager, setQuorum 등)
    └── setAliveImplementation2 + setSelectorImplementations2로 함수 매칭

22. Candidate (구현체)
    └── DAO 후보자 로직 (개별 인스턴스)

23. CandidateFactory (Proxy + Implementation)
    └── CandidateFactoryProxy + CandidateFactory
    └── 설정: setAddress(depositManager, daoCommittee, candidate, ton, wton)

24. CandidateAddOnV1_1 (구현체)
    └── DAO 후보자 애드온 로직 (Layer2Manager 연동)

25. CandidateAddOnFactory (Proxy + Implementation)
    └── CandidateAddOnFactoryProxy + CandidateAddOnFactory
    └── 설정: setAddresses(...)
```

#### DAO 프록시 구조

```
┌─────────────────────────────────────────────────────────────────┐
│                    DAO Committee 호출 흐름                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  User Call                                                       │
│      │                                                           │
│      ▼                                                           │
│  ┌─────────────────────────────────────────┐                     │
│  │  DAOCommitteeProxy (tokamak-dao-contracts)│                   │
│  │  - 메인 프록시                            │                     │
│  │  - implementation() → DAOCommitteeProxy2  │                   │
│  └─────────────────────────────────────────┘                     │
│      │ delegatecall                                              │
│      ▼                                                           │
│  ┌─────────────────────────────────────────┐                     │
│  │  DAOCommitteeProxy2 (ton-staking-v2)     │                    │
│  │  - 다중 구현체 라우터                      │                    │
│  │  - implementation2(0) → DAOCommittee_V1   │                   │
│  │  - setAliveImplementation2()              │                   │
│  │  - setSelectorImplementations2()          │                   │
│  └─────────────────────────────────────────┘                     │
│      │ delegatecall (selector 기반)                               │
│      ▼                                                           │
│  ┌─────────────────────────────────────────┐                     │
│  │  implementation2[0]: DAOCommittee_V1     │                    │
│  │  - 메인 비즈니스 로직                      │                    │
│  │  - createCandidate()                     │                    │
│  │  - createCandidateAddOn()                │                    │
│  │  - castVote(), executeAgenda()           │                    │
│  └─────────────────────────────────────────┘                     │
│                                                                  │
│  ┌─────────────────────────────────────────┐                     │
│  │  implementation2[1]: DAOCommitteeOwner   │                    │
│  │  - Owner 전용 설정 함수                    │                    │
│  │  - setSeigManager(), setLayer2Manager()  │                    │
│  │  - setCandidateFactory()                 │                    │
│  │  - increaseMaxMember(), setQuorum()      │                    │
│  │  - daoExecuteTransaction()               │                    │
│  └─────────────────────────────────────────┘                     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

#### DAO 컨트랙트 배포 절차

> **참고**: tokamak-dao-contracts가 서브모듈로 포함되어 있습니다.
> - 경로: `lib/tokamak-dao-contracts`
> - Import: `@tokamak-dao/dao/DAOCommitteeProxy.sol`
> - GitHub: https://github.com/tokamak-network/tokamak-dao-contracts

```solidity
// ==========================================
// Step 1: DAOCommitteeProxy 배포 (tokamak-dao-contracts)
// ==========================================
// Constructor에서 초기화 (initialize 없음)
// impl은 address(0)으로 시작, 나중에 DAOCommitteeProxy2로 설정
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
// DAOCommitteeProxy2는 다중 구현체 패턴을 제공하는 중간 레이어
// DAOCommitteeProxy의 implementation으로 설정됨
DAOCommitteeProxy2 daoCommitteeProxy2 = new DAOCommitteeProxy2();

// DAOCommitteeProxy의 impl을 DAOCommitteeProxy2로 설정
// 이후 모든 호출은 DAOCommitteeProxy → DAOCommitteeProxy2 → 실제 구현체로 라우팅
daoCommitteeProxy.upgradeTo(address(daoCommitteeProxy2));

// ==========================================
// Step 3: DAOCommittee_V1 구현체 배포 및 설정
// ==========================================
DAOCommittee_V1 daoCommitteeImpl = new DAOCommittee_V1();

// DAOCommitteeProxy2의 Index 0에 DAOCommittee_V1 설정
// 호출 흐름: User → DAOCommitteeProxy → DAOCommitteeProxy2 → DAOCommittee_V1
DAOCommitteeProxy2(address(daoCommitteeProxy)).upgradeTo2(address(daoCommitteeImpl));

// ==========================================
// Step 4: DAOCommitteeOwner 배포 및 Selector Routing
// ==========================================
DAOCommitteeOwner daoCommitteeOwner = new DAOCommitteeOwner();

// Index 1에 DAOCommitteeOwner 활성화
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
// Step 7: CandidateAddOn 배포 및 설정 (Layer2Manager 연동용)
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
// Step 8: DAOCommittee 설정 (DAOCommitteeOwner 함수 - Selector Routing됨)
// ==========================================
// DAOCommitteeOwner 함수들이 selector routing으로 호출됨
DAOCommitteeOwner(address(daoCommitteeProxy)).setCandidateFactory(address(candidateFactoryProxy));
DAOCommitteeOwner(address(daoCommitteeProxy)).setSeigManager(seigManagerProxy_);
DAOCommitteeOwner(address(daoCommitteeProxy)).setCandidateAddOnFactory(address(candidateAddOnFactoryProxy));
// layer2Manager 설정 (V3 연동)
DAOCommitteeOwner(address(daoCommitteeProxy)).setLayer2Manager(layer2ManagerProxy_);
```

#### DAO 관련 추가 컨트랙트 (별도 배포 필요)

| 컨트랙트 | 설명 | 리포지토리 |
|----------|------|-----------|
| DAOAgendaManager | 안건 관리 | tokamak-dao-contracts |
| DAOVault | DAO 자금 관리 | tokamak-dao-contracts |

> **참고**: DAO 전체 시스템은 tokamak-dao-contracts 리포지토리를 참조하세요.
> https://github.com/tokamak-network/tokamak-dao-contracts

#### ⚠️ 중요: 프록시 Owner 설정

**TON Staking의 모든 프록시 컨트랙트의 owner는 DAOCommitteeProxy 주소가 됩니다.**

이는 거버넌스를 통해서만 프록시 업그레이드 및 설정 변경이 가능하도록 하기 위함입니다.

```solidity
// 배포 완료 후 owner를 DAO로 이전
// 각 프록시의 owner/admin을 DAOCommitteeProxy로 설정

// SeigManagerProxy
SeigManagerProxy(seigManagerProxy).transferOwnership(daoCommitteeProxy);

// DepositManagerProxy
DepositManagerProxy(depositManagerProxy).transferOwnership(daoCommitteeProxy);

// Layer2RegistryProxy
Layer2RegistryProxy(layer2RegistryProxy).transferOwnership(daoCommitteeProxy);

// Layer2ManagerProxy
Layer2ManagerProxy(layer2ManagerProxy).transferOwnership(daoCommitteeProxy);

// L1BridgeRegistryProxy
L1BridgeRegistryProxy(l1BridgeRegistryProxy).transferOwnership(daoCommitteeProxy);

// CandidateFactoryProxy
CandidateFactoryProxy(candidateFactoryProxy).transferOwnership(daoCommitteeProxy);

// CandidateAddOnFactoryProxy
CandidateAddOnFactoryProxy(candidateAddOnFactoryProxy).transferOwnership(daoCommitteeProxy);

// RATProxy (V3)
RATProxy(ratProxy).transferOwnership(daoCommitteeProxy);

// ValidatorPoolProxy (V3)
ValidatorPoolProxy(validatorPoolProxy).transferOwnership(daoCommitteeProxy);
```

**Owner 이전 후:**
- 프록시 업그레이드 (`upgradeTo`, `setImplementation2` 등)는 DAO 안건을 통해서만 실행 가능
- 설정 변경 함수들도 DAO를 통해서만 호출 가능
- `daoExecuteTransaction()`을 통해 DAO가 각 컨트랙트의 owner 함수 실행

### Phase 7: V3 신규 컨트랙트

```
26. RAT (Proxy + Implementation)
    └── RATProxy + RAT
    └── RAT.initialize(seigManager, wton, ton, depositManager, owner)
    └── RAT 파라미터 설정

27. ValidatorPool (Proxy + Implementation)
    └── ValidatorPoolProxy + ValidatorPoolV1
    └── ValidatorPool.initialize(seigManager, wton, ton, owner)
    └── ValidatorPool 파라미터 설정
```

### Phase 8: Cross-Reference 설정

```
28. SeigManager.setLayer2Manager(layer2Manager)
29. SeigManager.setRATContract(rat)

30. Layer2Manager.setAddresses(
      l1BridgeRegistry,
      operatorManagerFactory,
      ton, wton,
      dao,
      depositManager,
      seigManager,
      swapProxy
    )
    └── V1_2 활성화 및 Selector Routing (multi-impl 패턴)

31. L1BridgeRegistry.setAddresses(
      layer2Manager,
      seigManager,
      ton
    )
    └── V1_2 활성화 및 Selector Routing (multi-impl 패턴)

32. OperatorManagerFactory.setAddresses(
      depositManager,
      ton, wton,
      layer2Manager
    )
```

---

## 컨트랙트별 상세 설명

### 1. TON / WTON

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

### 2. CoinageFactory

| 항목 | 설명 |
|------|------|
| 역할 | Layer2별 코이니지(스테이킹 토큰) 생성 |
| 의존성 | RefactorCoinageSnapshot 로직 주소 |

```solidity
RefactorCoinageSnapshot coinageLogic = new RefactorCoinageSnapshot();
CoinageFactory factory = new CoinageFactory();
factory.setAutoCoinageLogic(address(coinageLogic));
```

### 3. SeigManager (다중 구현체 패턴) 🔄 V3 변경

| 항목 | 설명 |
|------|------|
| 역할 | 시뇨리지 계산 및 분배의 핵심 |
| 버전 | Base, V1_1, V1_2, V1_3, V1_4 (다중 구현체) |
| 주요 기능 | 블록당 시뇨리지 계산, Layer2별 분배, RAT 연동 |
| 🆕 V3 추가 | **SeigManagerV1_4** - V3 신규 함수 (RAT, Bridged TON 등) |

**중요**: SeigManager는 **다중 구현체 패턴**을 사용합니다. 단순 프록시 업그레이드가 아닌 **함수별 라우팅(Selector Routing)**으로 여러 구현체가 동시에 활성화됩니다.

#### 버전별 함수 분포

| 버전 | 역할 | 비고 | V3 |
|------|------|------|-----|
| **SeigManagerV1_2** | 기본 구현체 (Index 0) - initialize, setData, deployCoinage 등 | `upgradeTo()`로 설정 | - |
| **SeigManagerV1_3** | pause/unpause, L2 시뇨리지 제외/포함 | Selector routing 필요 | - |
| **SeigManagerV1_4** | V3 신규 함수 - RAT, Layer2Manager, 슬래싱 등 | Selector routing 필요 | 🆕 |

##### SeigManagerV1_3 등록 함수 목록

> **메인넷 상태**: 등록됨 (0xce18C6F84F10881eA47A43AF7311A29bb116F628)
> **참고**: V3 업그레이드시 `pause`, `unpause`, `updateSeigniorage`, `updateSeigniorageLayer`는 V1_4로 재라우팅 권장

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

##### SeigManagerV1_4 등록 함수 목록 (🆕 V3 신규)

> **메인넷 상태**: 미등록 (V3 업그레이드 시 등록 필요)
> **참고**: `setLayer2Manager`는 V1_2(기본 구현체)에 이미 있으므로 V1_4 라우팅 불필요

| 함수 시그니처 | Selector | 설명 |
|--------------|----------|------|
| `setRATContract(address)` | `0x6ac8da17` | RAT 컨트랙트 주소 설정 |
| `setDisputeContract(address)` | `0x44d23d6f` | Dispute 컨트랙트 주소 설정 |
| `setValidatorPool(address)` | `0x49627b74` | ValidatorPool 주소 설정 |
| `setDaoDistributionRatio(uint256)` | `0xb36124ee` | DAO 분배 비율 설정 |
| `setMinStakingRatio(uint256)` | `0xfddecacb` | 최소 스테이킹 비율 설정 |
| `setValidatorDistributionRatio(uint256)` | `0x82713813` | 검증자 분배 비율 설정 |
| `setHalfSaturationPoint(uint256)` | `0x037f1227` | Half Saturation 포인트 설정 |
| `setStakedSeigFactor(uint256)` | `0xafa5c0f4` | 스테이킹 시뇨리지 팩터 설정 |
| `migrateToV3()` | `0x3cd1a78b` | V3 마이그레이션 실행 |
| `slashSequencer(address,address[])` | `0x484ebff6` | 시퀀서 슬래싱 |
| `slashSequencerByGame(address,address[])` | `0xf4266fde` | DisputeGame 기반 시퀀서 슬래싱 |
| `transferStake(address,address,address,uint256)` | `0x26334f93` | 스테이크 전송 |
| `onBridgedTONChange(address,uint256)` | `0x92736bfd` | Bridged TON 변경 콜백 |
| `initializeBridgedTON(address,uint256)` | `0xa71827f4` | Bridged TON 초기화 |
| `updateSeigniorage()` | `0x764a7856` | 시뇨리지 분배 (V1_2 오버라이드 - V3 로직) |
| `updateSeigniorageLayer(address)` | `0x1e1f0b60` | Layer2별 시뇨리지 분배 (V1_2 오버라이드 - V3 로직) |

#### 다중 구현체 패턴 동작 원리

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
│  │slashSequencer│ → selectorImpl[0x...] = V1_4 → V1_4            │
│  └──────────────┘                                                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

#### 상세 배포 절차 (Selector Routing 방식)

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

// V1_2를 기본 구현체로 설정 (upgradeTo)
// 등록되지 않은 모든 함수 호출은 이 구현체가 처리
proxy.upgradeTo(address(seigManagerV1_2));

// ==========================================
// Step 3: 초기화 (기본 구현체 함수 사용)
// ==========================================
// initialize()는 V1_2에 있음 → 기본 구현체가 처리
SeigManagerV1_2(address(proxy)).initialize(
    ton_,
    wton_,
    registry_,
    depositManager_,
    seigPerBlock_,
    factory_,
    block.number
);

// setData()도 V1_2에 있음 → 기본 구현체가 처리
SeigManagerV1_2(address(proxy)).setData(
    powerton_,
    daoAddress_,
    0,              // powerTONSeigRate: 0%
    0.5e27,         // daoSeigRate: 50%
    0.5e27,         // relativeSeigRate: 50%
    93096,          // adjustCommissionDelay
    1000.1e27       // minimumAmount
);

// ==========================================
// Step 4: V1_3, V1_4 구현체 활성화
// ==========================================
// Selector routing 전에 먼저 구현체를 "alive" 상태로 설정
proxy.setAliveImplementation2(address(seigManagerV1_3), true);
proxy.setAliveImplementation2(address(seigManagerV1_4), true);

// ==========================================
// Step 5: V1_4 함수들을 V1_4 구현체로 라우팅
// ==========================================
// 참고: setLayer2Manager는 V1_2(기본 구현체)에 이미 있으므로 라우팅 불필요
bytes4[] memory v1_4Selectors = new bytes4[](16);
v1_4Selectors[0] = SeigManagerV1_4.setRATContract.selector;
v1_4Selectors[1] = SeigManagerV1_4.setDisputeContract.selector;
v1_4Selectors[2] = SeigManagerV1_4.setValidatorPool.selector;
v1_4Selectors[3] = SeigManagerV1_4.setDaoDistributionRatio.selector;
v1_4Selectors[4] = SeigManagerV1_4.setMinStakingRatio.selector;
v1_4Selectors[5] = SeigManagerV1_4.setValidatorDistributionRatio.selector;
v1_4Selectors[6] = SeigManagerV1_4.setHalfSaturationPoint.selector;
v1_4Selectors[7] = SeigManagerV1_4.setStakedSeigFactor.selector;
v1_4Selectors[8] = SeigManagerV1_4.migrateToV3.selector;
v1_4Selectors[9] = SeigManagerV1_4.slashSequencer.selector;
v1_4Selectors[10] = SeigManagerV1_4.slashSequencerByGame.selector;
v1_4Selectors[11] = SeigManagerV1_4.transferStake.selector;
v1_4Selectors[12] = SeigManagerV1_4.onBridgedTONChange.selector;
v1_4Selectors[13] = SeigManagerV1_4.initializeBridgedTON.selector;
v1_4Selectors[14] = SeigManagerV1_4.updateSeigniorage.selector;        // V1_2 오버라이드
v1_4Selectors[15] = SeigManagerV1_4.updateSeigniorageLayer.selector;   // V1_2 오버라이드

// 이 호출 후, 위 selector들로 호출하면 V1_4로 라우팅됨
proxy.setSelectorImplementations2(v1_4Selectors, address(seigManagerV1_4));

// ==========================================
// Step 6: V1_4 전용 설정
// ==========================================
// setLayer2Manager()는 V1_2(기본 구현체)가 처리
SeigManagerV1_2(address(proxy)).setLayer2Manager(layer2Manager);
SeigManagerV1_4(address(proxy)).setRATContract(rat);
```

#### 프록시 주요 함수 설명

| 함수 | 설명 |
|------|------|
| `upgradeTo(address impl)` | 기본 구현체 설정. 미등록 selector 호출시 이 구현체가 처리 |
| `setAliveImplementation2(address impl, bool alive)` | 구현체 활성화/비활성화. selector routing 전 반드시 호출 |
| `setSelectorImplementations2(bytes4[] selectors, address impl)` | 특정 selector들을 특정 구현체로 라우팅 |
| `selectorImplementation(bytes4 selector)` | 특정 selector가 어느 구현체로 라우팅되는지 조회 |

#### 주의사항

1. **구현체 활성화 순서**: `setSelectorImplementations2()` 호출 전 반드시 `setAliveImplementation2(impl, true)` 호출
2. **스토리지 호환성**: 모든 버전은 동일한 스토리지 레이아웃 공유 (ProxyStorage, SeigManagerStorage 상속)
3. **기본 구현체**: `upgradeTo()`로 설정한 구현체가 등록되지 않은 모든 함수 처리
4. **selector 충돌**: 동일 selector가 여러 구현체에 있으면 마지막 등록된 구현체가 처리

#### 메인넷 현재 구성 (참고용)

```
SeigManager Proxy: 0x0b55a0f463b6DEFb81c6063973763951712D0E5F

Implementation Index 0: SeigManagerV1_2 (0xb1958719b3Af9B4d85D93EFC5e317C97cCe9aBc4)
  └── 기본 fallback 구현체 (대부분의 함수 처리)

Implementation Index 1: SeigManagerV1_3 (0xce18C6F84F10881eA47A43AF7311A29bb116F628)
  └── V1_3 전용 함수만 selector routing으로 연결
```

**함수 라우팅 방식:**
- 기본적으로 모든 함수 호출은 Index 0 (V1_2)로 전달
- `setSelectorImplementations2()`로 특정 함수만 Index 1 (V1_3)로 라우팅
- V3 업그레이드 시 Index 2에 V1_4 추가

#### 🔄 V3 업그레이드 방법 (기존 메인넷/테스트넷)

> ⚠️ **V3 주의**: 이 섹션은 **기존 V2 배포**를 V3로 업그레이드하는 방법입니다. 새로운 체인에 처음 배포하는 경우 "상세 배포 절차" 섹션을 참조하세요.

```solidity
// ==========================================
// Step 1: V1_4 구현체 배포
// ==========================================
SeigManagerV1_4 seigManagerV1_4 = new SeigManagerV1_4();

// ==========================================
// Step 2: Index 2에 V1_4 구현체 추가
// ==========================================
SeigManagerProxy proxy = SeigManagerProxy(0x0b55a0f463b6DEFb81c6063973763951712D0E5F);
proxy.setImplementation2(address(seigManagerV1_4), 2, true);

// ==========================================
// Step 3: V1_4 전용 함수들을 Index 2로 라우팅
// ==========================================
bytes4[] memory v1_4Selectors = new bytes4[](X);  // X = V1_4 함수 개수
v1_4Selectors[0] = bytes4(keccak256("setLayer2Manager(address)"));
v1_4Selectors[1] = bytes4(keccak256("setRATContract(address)"));
v1_4Selectors[2] = bytes4(keccak256("calculateL2Seigniorage(address,uint256,uint256)"));
// ... 추가 V1_4 함수들

proxy.setSelectorImplementations2(v1_4Selectors, address(seigManagerV1_4));

// ==========================================
// Step 4: V1_4 설정
// ==========================================
SeigManagerV1_4(address(proxy)).setLayer2Manager(layer2Manager);
SeigManagerV1_4(address(proxy)).setRATContract(rat);
```

**V3 업그레이드 후 구조:**
```
SeigManager Proxy
├── Index 0: SeigManagerV1_2 (기본 함수)
├── Index 1: SeigManagerV1_3 (pause/unpause V3)
└── Index 2: SeigManagerV1_4 (V3 신규 함수) ← NEW
```

#### 배포 전 필수 의존성

- TON, WTON
- CoinageFactory (+ RefactorCoinageSnapshot 로직)
- Layer2Registry (프록시 배포 완료)
- DepositManager (프록시만 - 순환 의존성 해결용)

#### 배포 순서 요약

> **참고**: 상세 코드는 위의 "상세 배포 절차 (Selector Routing 방식)" 섹션을 참조하세요.

1. **구현체 배포**: V1_2, V1_3, V1_4 배포
2. **프록시 설정**: `upgradeTo(V1_2)` - 기본 구현체
3. **초기화**: `initialize()`, `setData()` 호출
4. **V1_3, V1_4 활성화**: `setAliveImplementation2()`
5. **Selector Routing**: `setSelectorImplementations2()` - V1_4 함수 16개 등록
6. **V3 설정**: `setLayer2Manager()`, `setRATContract()` 호출

**Minter 권한 설정** (중요):
```solidity
// Layer2Registry에 minter 권한 추가 (SeigManager가 코이니지 생성 가능하도록)
Layer2Registry.addMinter(seigManagerProxy);

// WTON에 SeigManager를 minter로 추가 (시뇨리지 발행용)
WTON.addMinter(seigManagerProxy);
```

### 4. DepositManager (다중 구현체 패턴) 🔄 V3 변경

| 항목 | 설명 |
|------|------|
| 역할 | 스테이킹 예치/출금 관리 |
| 버전 | Base, _setWithdrawalDelay, V1_1, V1_2 (다중 구현체) |
| 패턴 | SeigManager와 동일한 Selector Routing 방식 |
| 🆕 V3 추가 | **DepositManagerV1_2** - V3 콜백 기능 |

**중요**: DepositManager도 **다중 구현체 패턴**을 사용합니다.

#### 버전별 함수 분포

| 버전 | Index | 역할 | 비고 | V3 |
|------|-------|------|------|-----|
| **DepositManager** | 0 | 기본 구현체 - initialize, deposit, requestWithdrawal 등 | `upgradeTo()`로 설정 | - |
| **DepositManager_setWithdrawalDelay** | 1 | 출금 지연 설정 | Selector routing 필요 | - |
| **DepositManagerV1_1** | 2 | L2 출금 및 가스 제한 설정 | Selector routing 필요 | - |
| **DepositManagerV1_2** | 3 | V3 콜백 및 함수 오버라이드 | Selector routing 필요 | 🆕 |

##### DepositManager_setWithdrawalDelay (Index 1) 등록 함수 목록

> **메인넷 상태**: 확인 필요

| 함수 시그니처 | Selector | 설명 |
|--------------|----------|------|
| `setWithdrawalDelay(address,uint256)` | `0xdc5a709f` | Layer2별 출금 지연 설정 |
| `setWithdrawalDelayByOwner(address,uint256)` | `0x377db38b` | Owner 전용 출금 지연 설정 |

##### DepositManagerV1_1 (Index 2) 등록 함수 목록

> **메인넷 상태**: 확인 필요

| 함수 시그니처 | Selector | 설명 |
|--------------|----------|------|
| `setMinDepositGasLimit(uint256)` | (확인필요) | 최소 예치 가스 제한 설정 |
| `setAddresses(address,address)` | `0x90107afe` | L1BridgeRegistry, Layer2Manager 주소 설정 |
| `withdrawAndDepositL2(address,uint256)` | `0x9f382d11` | 출금 후 L2 예치 |

##### DepositManagerV1_2 (Index 3) 등록 함수 목록 (🆕 V3 신규)

> **메인넷 상태**: 미등록 (V3 업그레이드 시 등록 필요)

| 함수 시그니처 | Selector | 설명 |
|--------------|----------|------|
| `setV3CallbackEnabled(bool)` | `0x2150fab0` | V3 콜백 활성화/비활성화 |
| `deposit(address,address,uint256)` | `0x8340f549` | 예치 (V3 콜백 포함) |
| `withdrawAndDepositL2(address,uint256)` | `0x9f382d11` | 출금 후 L2 예치 (V1_1 오버라이드) |
| `requestWithdrawal(address,uint256)` | `0xda95ebf7` | 출금 요청 |
| `processRequest(address)` | `0x5d6f7cca` | 출금 요청 처리 |
| `processRequests(address,uint256)` | `0x06260ceb` | 다중 출금 요청 처리 |
| `getWithdrawalRequests(address,address)` | `0x862ae6d0` | 출금 요청 조회 |
| `pendingUnstaked(address,address)` | `0x2638fdf5` | 대기 중인 언스테이킹 조회 |
| `accStaked(address,address)` | `0x2d2fab94` | 누적 스테이킹 조회 |
| `accUnstaked(address,address)` | `0x9d91b87b` | 누적 언스테이킹 조회 |

#### 다중 구현체 패턴 동작 원리

```
┌─────────────────────────────────────────────────────────────────┐
│                  DepositManagerProxy                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  함수 호출 흐름:                                                  │
│                                                                  │
│  ┌──────────────────────┐                                        │
│  │     initialize       │ → selectorImpl 없음 → Index 0 (Base)   │
│  │     deposit          │ → selectorImpl 없음 → Index 0 (Base)   │
│  │ setWithdrawalDelay   │ → selectorImpl[0x...] = Index 1        │
│  │ setMinDepositGasLimit│ → selectorImpl[0x...] = Index 2 (V1_1) │
│  │setV3CallbackEnabled  │ → selectorImpl[0x...] = Index 3 (V1_2) │
│  └──────────────────────┘                                        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

#### 상세 배포 절차

```solidity
// ==========================================
// Step 1: 모든 구현체 배포
// ==========================================
DepositManager depositManagerBase = new DepositManager();
DepositManager_setWithdrawalDelay depositManagerSetDelay = new DepositManager_setWithdrawalDelay();
DepositManagerV1_1 depositManagerV1_1 = new DepositManagerV1_1();
DepositManagerV1_2 depositManagerV1_2 = new DepositManagerV1_2();

// ==========================================
// Step 2: 프록시 배포 및 기본 구현체 설정 (Index 0)
// ==========================================
DepositManagerProxy proxy = new DepositManagerProxy();
proxy.upgradeTo(address(depositManagerBase));

// ==========================================
// Step 3: 초기화 (Base 구현체 함수 사용)
// ==========================================
DepositManager(address(proxy)).initialize(
    wton_,                  // WTON 주소
    registry_,              // Layer2Registry 주소
    seigManager_,           // SeigManager 주소
    globalWithdrawalDelay_, // 출금 지연 블록 (93046 ≈ 2주)
    address(0)              // 이전 DepositManager (새 배포시 address(0))
);

// ==========================================
// Step 4: Index 1, 2, 3 구현체 활성화
// ==========================================
proxy.setAliveImplementation2(address(depositManagerSetDelay), true);
proxy.setAliveImplementation2(address(depositManagerV1_1), true);
proxy.setAliveImplementation2(address(depositManagerV1_2), true);

// ==========================================
// Step 5: Index 1 함수 Selector Routing (setWithdrawalDelay)
// ==========================================
bytes4[] memory index1Selectors = new bytes4[](2);
index1Selectors[0] = DepositManager_setWithdrawalDelay.setWithdrawalDelay.selector;
index1Selectors[1] = DepositManager_setWithdrawalDelay.setWithdrawalDelayByOwner.selector;
proxy.setSelectorImplementations2(index1Selectors, address(depositManagerSetDelay));

// ==========================================
// Step 6: Index 2 함수 Selector Routing (V1_1)
// ==========================================
bytes4[] memory index2Selectors = new bytes4[](3);
index2Selectors[0] = DepositManagerV1_1.setMinDepositGasLimit.selector;
index2Selectors[1] = DepositManagerV1_1.setAddresses.selector;
index2Selectors[2] = DepositManagerV1_1.withdrawAndDepositL2.selector;
proxy.setSelectorImplementations2(index2Selectors, address(depositManagerV1_1));

// ==========================================
// Step 7: Index 3 함수 Selector Routing (V1_2)
// ==========================================
bytes4[] memory index3Selectors = new bytes4[](10);
index3Selectors[0] = DepositManagerV1_2.setV3CallbackEnabled.selector;
index3Selectors[1] = DepositManagerV1_2.deposit.selector;
index3Selectors[2] = DepositManagerV1_2.withdrawAndDepositL2.selector;  // V1_1 오버라이드
index3Selectors[3] = DepositManagerV1_2.requestWithdrawal.selector;
index3Selectors[4] = DepositManagerV1_2.processRequest.selector;
index3Selectors[5] = DepositManagerV1_2.processRequests.selector;
index3Selectors[6] = DepositManagerV1_2.getWithdrawalRequests.selector;
index3Selectors[7] = DepositManagerV1_2.pendingUnstaked.selector;
index3Selectors[8] = DepositManagerV1_2.accStaked.selector;
index3Selectors[9] = DepositManagerV1_2.accUnstaked.selector;
proxy.setSelectorImplementations2(index3Selectors, address(depositManagerV1_2));

// ==========================================
// Step 8: V1_2 전용 설정
// ==========================================
DepositManagerV1_2(address(proxy)).setAddresses(l1BridgeRegistry, layer2Manager);
DepositManagerV1_2(address(proxy)).setV3CallbackEnabled(true);
```

#### 주의사항

1. **Index 0 (Base)**: `upgradeTo()`로 설정, 미등록 selector의 기본 처리
2. **Index 1-3**: `setAliveImplementation2()` + `setSelectorImplementations2()`로 설정
3. **함수 오버라이드**: V1_2의 `withdrawAndDepositL2`는 V1_1을 오버라이드하므로 V1_2로 라우팅
4. **순서 중요**: 나중에 등록한 selector가 우선

### 5. Layer2Manager (다중 구현체 패턴) 🔄 V3 변경

| 항목 | 설명 |
|------|------|
| 역할 | Layer2 등록 및 관리 |
| 버전 | V1_1, V1_2 (다중 구현체) |
| 패턴 | Selector Routing 방식 |
| 🆕 V3 추가 | **Layer2ManagerV1_2** - Bridged TON 관리 기능 |

**중요**: Layer2Manager도 **다중 구현체 패턴**을 사용합니다.

> ⚠️ **V3 주의**: V3에서는 단순 `upgradeTo()` 대신 **Selector Routing**으로 V1_2 함수를 추가합니다. V1_1의 `setAddresses()`는 초기화 가드가 있으므로 기본 구현체로 유지해야 합니다.

#### 버전별 함수 분포

| 버전 | Index | 주요 함수 | 비고 | V3 |
|------|-------|----------|------|-----|
| **Layer2ManagerV1_1** | 0 | `setAddresses()`, `registerCandidateAddOn()`, `transferL2Seigniorage()`, `pauseCandidateAddOn()` | 기본 구현체 | - |
| **Layer2ManagerV1_2** | 1 | `registerCandidateAddOnV3()`, `updateBridgedTON()`, `getBridgedTON()`, `getCachedBridgedTON()` | Selector routing | 🆕 신규 |

#### 배포 절차

```solidity
// Step 1: 구현체 배포
Layer2ManagerV1_1 layer2ManagerV1_1 = new Layer2ManagerV1_1();
Layer2ManagerV1_2 layer2ManagerV1_2 = new Layer2ManagerV1_2();

// Step 2: 프록시 배포 및 V1_1을 기본 구현체로 설정
Layer2ManagerProxy proxy = new Layer2ManagerProxy();
proxy.upgradeTo(address(layer2ManagerV1_1));

// Step 3: 초기화 (V1_1의 setAddresses 호출)
Layer2ManagerV1_1(address(proxy)).setAddresses(
    l1BridgeRegistry_,
    operatorManagerFactory_,
    ton_,
    wton_,
    dao_,
    depositManager_,
    seigManager_,
    swapProxy_   // 선택사항, address(0) 가능
);

// Step 4: V1_2 구현체 활성화 및 Selector Routing
proxy.setAliveImplementation2(address(layer2ManagerV1_2), true);

bytes4[] memory v1_2Selectors = new bytes4[](4);
v1_2Selectors[0] = Layer2ManagerV1_2.registerCandidateAddOnV3.selector;
v1_2Selectors[1] = Layer2ManagerV1_2.updateBridgedTON.selector;
v1_2Selectors[2] = Layer2ManagerV1_2.getBridgedTON.selector;
v1_2Selectors[3] = Layer2ManagerV1_2.getCachedBridgedTON.selector;
proxy.setSelectorImplementations2(v1_2Selectors, address(layer2ManagerV1_2));
```

### 6. L1BridgeRegistry (다중 구현체 패턴) 🔄 V3 변경

| 항목 | 설명 |
|------|------|
| 역할 | Optimism SystemConfig 등록 및 관리 |
| 버전 | V1_1, V1_2 (다중 구현체) |
| 🆕 V3 추가 | **L1BridgeRegistryV1_2** - DisputeGameFactory 관리 (TYPE 3, RAT 연동용) |

**중요**: L1BridgeRegistry도 **다중 구현체 패턴**을 사용합니다.

> ⚠️ **V3 주의**: V1_2는 TYPE 3 (DisputeGame) 지원을 추가합니다. V1_1의 `setAddresses()`는 초기화 가드가 있으므로 기본 구현체로 유지해야 합니다.

#### 버전별 함수 분포

| 버전 | Index | 주요 함수 | 비고 | V3 |
|------|-------|----------|------|-----|
| **L1BridgeRegistryV1_1** | 0 | `setAddresses()`, `setSeigniorageCommittee()`, 기타 기본 함수 | 기본 구현체 | - |
| **L1BridgeRegistryV1_2** | 1 | `registerRollupConfig()` (TYPE 3), `layer2TVL()`, `rejectCandidateAddOn()`, `restoreCandidateAddOn()` | Selector routing | 🆕 신규 |

#### 배포 절차

```solidity
// Step 1: 구현체 배포
L1BridgeRegistryV1_1 l1BridgeRegistryV1_1 = new L1BridgeRegistryV1_1();
L1BridgeRegistryV1_2 l1BridgeRegistryV1_2 = new L1BridgeRegistryV1_2();

// Step 2: 프록시 배포 및 V1_1을 기본 구현체로 설정
L1BridgeRegistryProxy proxy = new L1BridgeRegistryProxy();
proxy.upgradeTo(address(l1BridgeRegistryV1_1));

// Step 3: 초기화 (V1_1의 setAddresses 호출)
L1BridgeRegistryV1_1(address(proxy)).setAddresses(
    layer2Manager_,
    seigManager_,
    ton_
);

// Step 4: V1_2 구현체 활성화 및 Selector Routing
proxy.setAliveImplementation2(address(l1BridgeRegistryV1_2), true);

// V1_2 전용 함수 (또는 오버라이드 함수) 등록
// 주의: overloaded 함수는 keccak256으로 selector 계산 필요
bytes4[] memory v1_2Selectors = new bytes4[](7);
// registerRollupConfig - TYPE 3 DisputeGame 지원
v1_2Selectors[0] = bytes4(keccak256("registerRollupConfig(address,uint8,address,string)"));
v1_2Selectors[1] = bytes4(keccak256("registerRollupConfig(address,uint8,address)"));
// registerRollupConfigByManager - TYPE 3 DisputeGame 지원
v1_2Selectors[2] = bytes4(keccak256("registerRollupConfigByManager(address,uint8,address,string)"));
v1_2Selectors[3] = bytes4(keccak256("registerRollupConfigByManager(address,uint8,address)"));
// layer2TVL - TYPE 3 지원
v1_2Selectors[4] = L1BridgeRegistryV1_2.layer2TVL.selector;
// rejectCandidateAddOn / restoreCandidateAddOn
v1_2Selectors[5] = L1BridgeRegistryV1_2.rejectCandidateAddOn.selector;
v1_2Selectors[6] = L1BridgeRegistryV1_2.restoreCandidateAddOn.selector;
proxy.setSelectorImplementations2(v1_2Selectors, address(l1BridgeRegistryV1_2));
```

### 6.5 OperatorManager

| 항목 | 설명 |
|------|------|
| 역할 | Layer2 오퍼레이터 관리 |
| 배포 방식 | OperatorManagerFactory가 프록시 생성 |
| 구현체 | OperatorManagerV1_1 |

**참고**: OperatorManager는 Layer2 등록시 Factory가 개별 프록시를 생성합니다.

```solidity
// OperatorManagerFactory 배포 및 설정
OperatorManagerV1_1 operatorManagerImpl = new OperatorManagerV1_1();
OperatorManagerFactory factory = new OperatorManagerFactory(address(operatorManagerImpl));

factory.setAddresses(
    depositManager_,
    ton_,
    wton_,
    layer2Manager_
);

// 이후 registerCandidateAddOn() 호출시 Factory가 자동으로
// OperatorManagerProxy를 생성하고 operatorManagerImpl로 설정
```

### 7. 🆕 RAT (Randomized Attention Test) - V3 신규

| 항목 | 설명 |
|------|------|
| 역할 | 검증자 무작위 주의 테스트 |
| 🆕 V3 신규 | DisputeGame 생성시 검증자 선택 및 테스트 |

```solidity
RAT.initialize(
    seigManager_,    // SeigManager 주소
    wton_,           // WTON 주소
    ton_,            // TON 주소
    depositManager_, // DepositManager 주소
    owner_           // 관리자 주소
);

// 파라미터 설정
RAT.setRatTriggerProbability(0.01e27);   // 1% (RAY)
RAT.setSlashingPenalty(100e27);          // 100 WTON
RAT.setValidatorBuffer(100e27);          // 100 WTON
RAT.setMinimumThreshold(1000e27);        // 1000 WTON
RAT.setEvidenceSubmissionPeriod(1 hours);
```

### 8. 🆕 ValidatorPool - V3 신규

| 항목 | 설명 |
|------|------|
| 역할 | 검증자 풀 관리 |
| 🆕 V3 신규 | 검증자 등록, 슬래싱 관리 |

```solidity
ValidatorPoolV1.initialize(
    seigManager_,  // SeigManager 주소
    wton_,         // WTON 주소
    ton_,          // TON 주소
    owner_         // 관리자 주소
);

// 파라미터 설정
ValidatorPoolV1.setSlashingPenalty(100e27);
ValidatorPoolV1.setMinimumThreshold(1000e27);
ValidatorPoolV1.setRatProbability(0.01e27);
ValidatorPoolV1.setRatResponseWindow(1 hours);
```

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

#### RAT/ValidatorPool 파라미터

| 파라미터 | 값 | 설명 |
|----------|-----|------|
| `ratTriggerProbability` | 0.01e27 | 1% (RAY 단위) |
| `slashingPenalty` | 100e27 | 100 WTON (RAY 단위) |
| `validatorBuffer` | 100e27 | 100 WTON (RAY 단위) |
| `minimumThreshold` | 1000e27 | 1000 WTON (RAY 단위) |
| `evidenceSubmissionPeriod` | 3600 | 1시간 (초) |

### RAY 단위

TON Staking에서는 정밀도를 위해 RAY 단위(10^27)를 사용합니다.

```solidity
uint256 constant RAY = 10**27;

// 예시
uint256 onePercent = 0.01e27;  // 1%
uint256 hundredWTON = 100e27;  // 100 WTON
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
  "validatorPoolProxy": "0x..."
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
cast call $SEIG_MANAGER_PROXY "ratContract()(address)"

# 3. RAT 설정 확인
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
V3 배포시 참고용으로 활용하세요.

### 토큰

| 컨트랙트 | 주소 | 비고 |
|----------|------|------|
| TON | `0x2be5e8c109e2197D077D13A82dAead6a9b3433C5` | ERC20 토큰 |
| WTON | `0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2` | Wrapped TON |

### 프록시 컨트랙트

| 컨트랙트 | 주소 | 비고 |
|----------|------|------|
| SeigManagerProxy | `0x0b55a0f463b6DEFb81c6063973763951712D0E5F` | 시뇨리지 관리 |
| DepositManagerProxy | `0x0b58ca72b12f01fc05f8f252e226f3e2089bd00e` | 스테이킹 관리 |
| Layer2RegistryProxy | `0x7846c2248a7b4de77e9c2bae7fbb93bfc286837b` | Layer2 등록 |
| Layer2ManagerProxy | `0xD6Bf6B2b7553c8064Ba763AD6989829060FdFC1D` | Layer2 관리 |
| L1BridgeRegistryProxy | `0x39d43281A4A5e922AB0DCf89825D73273D8C5BA4` | 브릿지 등록 |
| CandidateFactoryProxy | `0x9fc7100a16407ee24a79c834a56e6eca555a5d7c` | DAO 후보자 팩토리 |
| CandidateAddOnFactoryProxy | `0xFA8ce5caF456115E72B96E5074769b8f66AA5861` | 후보자 애드온 팩토리 |
| SwapProxy | `0x30e65B3A6e6868F044944Aa0e9C5d52F8dcb138d` | 스왑 |

### 구현체 컨트랙트

| 컨트랙트 | 주소 | 비고 |
|----------|------|------|
| SeigManagerV1_2 | `0xb1958719b3Af9B4d85D93EFC5e317C97cCe9aBc4` | Index 0 (기본) |
| SeigManagerV1_3 | `0xce18C6F84F10881eA47A43AF7311A29bb116F628` | Index 1 (pause/unpause) |
| DepositManagerV1_1 | `0x74bC3031b9369e6b898e82784106257D4D37Eac5` | 예치 관리 |
| Layer2ManagerV1_1 | `0x2EB7f500125f11544392B83B87cDEb9456f3509f` | Layer2 관리 |
| L1BridgeRegistryV1_1 | `0x259Ac335EB42d345A61bE48104eC0Ec20b283F14` | 브릿지 등록 |
| OperatorManagerV1_1 | `0xB5F3b31dFB4DCe9a2FA12dE50A97250d60823750` | 오퍼레이터 관리 로직 |
| CandidateAddOnV1_1 | `0x73Bfd5cAEC63307784C7B6d2555F18ec24D96E2e` | 후보자 애드온 |

### 팩토리 컨트랙트 (프록시 아님)

| 컨트랙트 | 주소 | 비고 |
|----------|------|------|
| CoinageFactory | `0xe8fae91b80dd515c3d8b9fc02cb5b2ecfddabf43` | 코이니지 생성 |
| RefactorCoinageSnapshot | `0xef12310ff8a6e96357b7d2c4a759b19ce94f7dfb` | 코이니지 로직 |
| OperatorManagerFactory | `0xAf86b21edDdC78ea27E23A7F2151d60d4e069450` | 오퍼레이터 팩토리 |

### SeigManager 다중 구현체 구조 (메인넷)

```
SeigManagerProxy (0x0b55a0f463b6DEFb81c6063973763951712D0E5F)
├── Index 0: SeigManagerV1_2 (0xb1958719b3Af9B4d85D93EFC5e317C97cCe9aBc4)
│   └── 기본 함수들 (fallback)
├── Index 1: SeigManagerV1_3 (0xce18C6F84F10881eA47A43AF7311A29bb116F628)
│   └── pauseV3(), unpauseV3(), setNewPauser()
└── Index 2: SeigManagerV1_4 (V3 업그레이드시 추가)
    └── setLayer2Manager(), setRATContract(), calculateL2Seigniorage() 등
```

---

## 참고 자료

- [TON Staking V2 Test Fixtures](https://github.com/tokamak-network/ton-staking-v2/blob/ton-staking-v2/test/shared/fixtures.ts)
- [RAT Implementation Guide](./for-llm-kr/07_rat_implementation.md)
- [E2E Test Design](./e2e-test-design.md)
- [Mainnet Deployed Addresses](./deployed-addresses-mainnet.md)
