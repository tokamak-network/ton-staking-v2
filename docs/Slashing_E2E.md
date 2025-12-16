# Slashing E2E Test Plan

이 문서는 Slashing 메커니즘의 전체적인 과정을 검증하기 위한 End-to-End (E2E) 테스트 시나리오와 절차를 정리합니다.

## 1. Environment Setup (Contract Deployment & Configuration)

Slashing 테스트를 수행하기 위해서는 먼저 검증 대상이 될 Layer2 Candidate가 네트워크에 등록되어 있어야 하며, 해당 Candidate에 스테이킹 된 자산(TON)이 존재해야 합니다.

이를 위해 전체 E2E 테스트는 크게 **1) 환경 설정(Contract Deployment)**, **2) Candidate 등록(Registration)**, **3) Slashing 시나리오 검증**으로 나뉩니다.

Slashing 테스트를 수행하기 위해 필요한 핵심 컨트랙트들을 순서대로 배포하고 연결해야 합니다.

### 1.1. Token Deployment
- **TON**: `abis/TON.json`을 사용하여 배포.
- **WTON**: `abis/WTON.json`을 사용하여 배포 (생성자에 TON 주소 주입).
- Token Deployment 테스트 : forge test --match-path test/TONWTONTest.sol

### 1.2. DAOCommitteeProxy Deployment Structure
DAOCommittee는 복합적인 프록시 구조를 가지고 있으며, 다음과 같은 단계로 구성됩니다.

1.  **Base Proxy 배포 (`DAOCommitteeProxy`)**
    - 최초의 진입점인 `DAOCommitteeProxy`를 배포합니다. 이는 `abis/DAOCommitteeProxy.json`을 사용하여 배포됩니다.
    - 생성자인 _ton, _impl, _seigManager, _layer2Registry, _agendaManager, _candidateFactory, _daoVault 주소는 랜덤주소를 넣습니다.

2.  **Upgrade to Proxy2 (`DAOCommitteeProxy2`)**
    - `DAOCommitteeProxy2` 컨트랙트를 배포합니다.
    - `DAOCommitteeProxy.upgradeTo(DAOCommitteeProxy2)`를 호출하여 로직을 `DAOCommitteeProxy2`로 위임합니다.
    - 이제 `DAOCommitteeProxy`를 통해 `DAOCommitteeProxy2`의 기능을 사용할 수 있습니다.

3.  **Logic Implementation 설정 (`DAOCommittee_V1`, `DAOCommitteeOwner`)**
    - **Main Logic**: `DAOCommittee_V1`을 배포하고, `DAOCommitteeProxy(as Proxy2).upgradeTo2(DAOCommittee_V1)`을 호출하여 메인 로직을 연결합니다.
    - **Owner Logic**: `DAOCommitteeOwner`를 배포하고, `DAOCommitteeProxy(as Proxy2).setImplementation2(1, DAOCommitteeOwner, true)`를 호출하여 서브 로직으로 등록합니다.

4. **DAOCommitteeProxy Deployment 테스트** 
    - forge test --match-path test/DAOCommitteeProxy.t.sol

*(이후 Layer2Manager, SeigManager 등의 배포 과정이 이어집니다)*

## 2. Layer2 Candidate Registration (Pre-condition for Slashing)

Actor(운영자/신청자)는 `Layer2Manager` 컨트랙트를 통해 등록을 시작합니다.

**Pre-condition**:
- `Layer2Manager`, `L1BridgeRegistry`, `OperatorManagerFactory`, `DAOCommitteeProxy`, `CandidateAddOnFactory` 등 주요 컨트랙트가 배포되어 있어야 함.

**Flow Details**:

1.  **후보자 등록 요청 (`registerCandidateAddOn`)**
    - **Actor**는 `Layer2Manager.registerCandidateAddOn(rollupConfig, rollupType, l2TON)`을 호출합니다.
    - **Layer2Manager**는 `L1BridgeRegistry`를 통해 제출된 `rollupConfigType`이 유효한지 검증합니다.

2.  **OperatorManager 생성**
    - **Layer2Manager**는 `OperatorManagerFactory`를 호출하여 해당 Candidate를 위한 `OperatorManager` 컨트랙트를 배포합니다.

3.  **CandidateAddOn 생성**
    - **Layer2Manager**는 `DAOCommitteeProxy`에게 `createCandidateAddOn(memo, operatorManager)`를 요청합니다.
    - **DAOCommitteeProxy**는 `CandidateAddOnFactory`를 통해 `CandidateAddOn` 컨트랙트를 생성합니다.

4.  **레지스트리 및 SeigManager 등록**
    - **DAOCommitteeProxy**는 `Layer2Registry`의 `registerAndDeployCoinage` 함수를 호출합니다.
    - **Layer2Registry**는 내부적으로 다음을 수행합니다:
        - `CandidateFactory`를 통해 `Candidate` 인스턴스 관리(필요 시).
        - **SeigManager**에 새로운 Layer2(`candidateAddOn`)를 등록.
    - **SeigManager**는 등록된 Layer2를 위해 `AutoCoinageFactory`를 통해 Coinage(Seigniorage 토큰)를 배포합니다.

### 1.2. 초기 자본금 예치 (Deposit TON)

Candidate 등록이 완료된 후, 해당 Candidate의 활성화를 위해 TON을 예치해야 합니다.

1.  **TON 예치 요청 (`deposit`)**
    - **Actor**는 `DepositManager.deposit(layer2, amount)`을 호출하여 자산을 예치합니다.
    - **Asset**: 예치하는 자산은 **TON**입니다.
    - **Minimum Amount**: 최소 **1000.1 TON** 이상을 예치해야 Candidate 등록이 유효합니다.
    - **Target**: `layer2` 파라미터는 위 과정에서 생성된 `CandidateAddOn` 주소를 가리킵니다.

2.  **지분 반영**
    - `DepositManager`는 예치된 TON을 컨트랙트에 보관하고, `SeigManager`와 연동하여 해당 Layer2의 스테이킹 지분을 업데이트합니다.

---

## 2. Test Scenario Reference (To be added)

*이후 Slashing, Challenge 등 추가적인 시나리오에 대한 테스트 절차가 이곳에 작성될 예정입니다.*
