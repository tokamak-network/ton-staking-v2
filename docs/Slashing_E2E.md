# Slashing E2E Test Plan

이 문서는 Slashing 메커니즘의 전체적인 과정을 검증하기 위한 End-to-End (E2E) 테스트 시나리오와 절차를 정리합니다.

## 1. Environment Setup (Contract Deployment & Configuration)

Slashing 테스트를 수행하기 위해서는 먼저 검증 대상이 될 Layer2 Candidate가 네트워크에 등록되어 있어야 하며, 해당 Candidate에 스테이킹 된 자산(TON)이 존재해야 합니다.

이를 위해 전체 E2E 테스트는 크게 **1) 환경 설정(Contract Deployment)**, **2) Candidate 등록(Registration)**, **3) Slashing 시나리오 검증**으로 나뉩니다.

Slashing 테스트를 수행하기 위해 필요한 핵심 컨트랙트들을 순서대로 배포하고 연결해야 합니다.

### 1. Deploy 과정
Deploy과정은 [deployment-deployscript-slashUpdated.md](./deployment-deployscript-slashUpdated.md)에서 자세히 설명되어 있습니다.

### 2. Layer2 Candidate Registration (Pre-condition for Slashing)

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

### 3. 초기 자본금 예치 (Deposit TON)

Candidate 등록이 완료된 후, 해당 Candidate의 활성화를 위해 TON을 예치해야 합니다.

1.  **TON 예치 요청 (`deposit`)**
    - **Actor**는 `DepositManager.deposit(layer2, amount)`을 호출하여 자산을 예치합니다.
    - **Asset**: 예치하는 자산은 **TON**입니다.
    - **Minimum Amount**: 최소 **1000.1 TON** 이상을 예치해야 Candidate 등록이 유효합니다.
    - **Target**: `layer2` 파라미터는 위 과정에서 생성된 `CandidateAddOn` 주소를 가리킵니다.

2.  **지분 반영**
    - `DepositManager`는 예치된 TON을 컨트랙트에 보관하고, `SeigManager`와 연동하여 해당 Layer2의 스테이킹 지분을 업데이트합니다.

---

## 2. Test Scenario Reference 

Slashing 메커니즘을 검증하기 위한 주요 테스트 시나리오입니다. 모든 테스트는 `SlashingE2E_improved_Deploy`를 상속받아 동일한 배포 환경에서 실행됩니다.

### 2.1. 정상 시나리오 (Functional Success)
**테스트 파일**: `test/SlashingE2E_improved_Functional.t.sol`

1. **오퍼레이터 등록 및 스테이킹 성공**
    - 오퍼레이터가 `Layer2Manager`를 통해 Candidate로 등록하고 10,000 TON을 성공적으로 스테이킹하는지 검증합니다.
    - `DepositManager` 장부에 해당 금액이 RAY 단위로 정확히 기록되는지 확인합니다.

2. **챌린저 승리 및 슬래싱 실행**
    - 오퍼레이터가 가짜 상태를 제출하여 분쟁(Dispute)이 발생한 상황을 시뮬레이션합니다.
    - `MockFaultDisputeGame`을 통해 챌린저가 승리(`CHALLENGER_WINS`)한 상태를 만듭니다.
    - `Layer2Manager.slashingCandidate`를 호출했을 때:
        - 오퍼레이터의 스테이킹 원금 및 보상이 전액 소각(Burn)되는지 확인합니다.
        - 설정된 보상 비율(예: 10%)에 따라 챌린저에게 WTON 보상이 지급되는지 확인합니다.

3. **보상 비율 변경 테스트 (Reward Rate Change)**
    - 슬래싱 보상 비율을 50% 등 다른 값으로 변경한 후, 챌린저에게 변경된 비율만큼의 보상이 정확히 지급되는지 확인합니다.

4. **시뇨리지 포함 슬래싱 테스트 (Slashing with Seigniorage)**
    - 일정 시간이 경과하여 스테이킹 이자(Seigniorage)가 쌓인 상태에서 슬래싱을 진행합니다.
    - 이때 원금뿐만 아니라 그동안 쌓인 이자(Tot 토큰 잔액)까지 모두 소각되어 0이 되는지 검증합니다.

5. **미수령 시뇨리지 포함 슬래싱 테스트 (Slashing with Unchecked Seigniorage)**
    - 오퍼레이터가 직접 `updateSeigniorage`를 호출하여 이자를 받지(Receive) 않은 상태에서도, 글로벌 시뇨리지 업데이트에 의해 자동으로 계산된 "미수령 이자"까지 모두 누락 없이 소각되는지 검증합니다.

### 2.2. 에러 시나리오 (Revert Cases)
**테스트 파일**: `test/SlashingE2E_Revert.t.sol`

1. **유효하지 않은 게임 상태 (Invalid Game Status)**
    - 분쟁 게임이 아직 진행 중(`IN_PROGRESS`)이거나 오퍼레이터(Defender)가 승리(`DEFENDER_WINS`)한 상태에서 슬래싱을 시도할 경우 `StatusError()`와 함께 Revert 되는지 검증합니다.

2. **권한 없는 슬래싱 호출 (Unauthorized Access - DepositManager)**
    - `DepositManager.slash` 함수는 내부적으로 중요한 자산을 소각하므로 오직 `Layer2Manager`만 호출할 수 있어야 합니다. 
    - 일반 사용자가 직접 `slash` 함수 호출을 시도할 때 `not layer2Manager` 메시지와 함께 차단되는지 확인합니다.

3. **권한 없는 SeigManager 소각 호출 (Unauthorized Access - SeigManager)**
    - `SeigManager.onSlash` 함수는 오직 `DepositManager`에 의해서만 호출되어야 합니다.
    - 일반 사용자나 다른 컨트랙트가 직접 `onSlash`를 호출하여 오퍼레이터의 자산 소각을 시도할 때 `not onlyDepositManager`와 함께 차단되는지 확인합니다.

---

## 3. 테스트 실행 방법

전체 시나리오 테스트를 실행하려면 다음 명령어를 사용합니다.

```bash
# 기능 테스트 실행 (성공 케이스)
forge test --match-path test/SlashingE2E_improved_Functional.t.sol -vvv

# 예외 처리 테스트 실행 (실패 케이스)
forge test --match-path test/SlashingE2E_Revert.t.sol -vvv
```

