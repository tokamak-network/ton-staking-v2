# TON Staking V3 DAO 컨트랙트 배포

이 문서는 DAO 거버넌스 컨트랙트 배포 및 프록시 Owner 설정을 설명합니다.

> **관련 문서**
> - [README.md](./README.md): 배포 개요 및 순서
> - [contracts.md](./contracts.md): 컨트랙트별 상세 설명

---

## 목차

1. [DAO 컨트랙트 목록](#dao-컨트랙트-목록)
2. [DAO 프록시 구조](#dao-프록시-구조)
3. [배포 절차](#배포-절차)
4. [DAOCommitteeOwner 함수 목록](#daocommitteeowner-함수-목록)
5. [프록시 Owner 설정](#프록시-owner-설정)

---

## DAO 컨트랙트 목록

> **참고**: tokamak-dao-contracts가 서브모듈로 포함되어 있습니다.
> - 경로: `lib/tokamak-dao-contracts`
> - GitHub: https://github.com/tokamak-network/tokamak-dao-contracts

| 프록시 | 구현체 | 설명 | 리포지토리 |
|--------|--------|------|-----------|
| DAOCommitteeProxy | DAOCommitteeProxy2 → DAOCommittee_V1/Owner | DAO 거버넌스 | tokamak-dao-contracts |
| DAOAgendaManagerProxy | DAOAgendaManager | DAO 안건 관리 | tokamak-dao-contracts |
| DAOVaultProxy | DAOVault | DAO 자금 관리 | tokamak-dao-contracts |
| CandidateFactoryProxy | CandidateFactory | DAO 후보자 팩토리 | ton-staking-v2 |
| CandidateAddOnFactoryProxy | CandidateAddOnFactory | 후보자 애드온 팩토리 | ton-staking-v2 |
| - | Candidate | 개별 후보자 구현체 | ton-staking-v2 |
| - | CandidateAddOnV1_1 | 개별 애드온 구현체 | ton-staking-v2 |

---

## DAO 프록시 구조

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

---

## 배포 절차

> ✅ **구현 완료**: `script/DeployDAO.s.sol` 스크립트를 사용하여 배포할 수 있습니다. DeployV3Full.s.sol과 별도로 실행해야 합니다.

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

## 프록시 Owner 설정

> ⚠️ **중요**: TON Staking의 **모든 프록시 컨트랙트의 owner는 DAOCommitteeProxy 주소**가 됩니다.

이는 거버넌스를 통해서만 프록시 업그레이드 및 설정 변경이 가능하도록 하기 위함입니다.

### Owner 이전 코드

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

### Owner 이전 후 동작

프록시들의 owner가 DAOCommitteeProxy로 이전되면, 두 가지 경로로 owner 함수를 실행할 수 있습니다:

#### 1. Agenda 시스템 (투표 기반)

```
1. 누군가 안건(Agenda) 생성 (target, functionBytecode 포함)
2. DAO 멤버들이 투표
3. 투표 통과 후 누구나 executeAgenda() 호출
4. DAOCommitteeProxy가 target.call(functionBytecode) 실행
   └── DAOCommitteeProxy가 owner이므로 onlyOwner 함수 호출 가능
```

| 동작 | 방법 |
|------|------|
| 프록시 업그레이드 | Agenda에 `upgradeTo(newImpl)` 포함하여 투표 |
| 설정 변경 함수 | Agenda에 설정 함수 호출 포함하여 투표 |

#### 2. daoExecuteTransaction (멀티시그 카운슬 전용)

```solidity
/// @notice This is a function executed by the DAO multisig wallet council.
function daoExecuteTransaction(address _to, bytes memory _data) external onlyOwner
```

- `onlyOwner` = `DEFAULT_ADMIN_ROLE` 필요 (멀티시그 카운슬)
- Agenda 투표 없이 카운슬이 직접 실행
- 긴급 상황이나 카운슬 권한 범위 내 작업용
