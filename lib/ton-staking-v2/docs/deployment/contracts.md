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
6. [L1BridgeRegistry (단일 구현체)](#6-l1bridgeregistry-단일-구현체--v3-변경)
7. [OperatorManager](#7-operatormanager)
8. [RAT](#8--rat-randomized-attention-test---v3-신규)
9. [ValidatorReward](#9--validatorreward---v3-신규)

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
| 버전 | V1_2 (기본), V3_1, V3_2 (다중 구현체) |
| 주요 기능 | 블록당 시뇨리지 계산, Layer2별 분배, RAT 연동 |
| 🆕 V3 추가 | **SeigManagerV3_1** - V3 메인 로직, **SeigManagerV3_2** - V2 호환 로직 |

**중요**: SeigManager는 **다중 구현체 패턴**을 사용합니다. 단순 프록시 업그레이드가 아닌 **함수별 라우팅(Selector Routing)**으로 여러 구현체가 동시에 활성화됩니다.

### 버전별 함수 분포

| 버전 | 역할 | 비고 | V3 |
|------|------|------|-----|
| **SeigManagerV1_2** | 기본 구현체 - initialize, setData, deployCoinage 등 | `upgradeTo()`로 설정 | - |
| **SeigManagerV3_1** | V3 메인 로직 - RAT, 검증자, 마이그레이션 등 | Selector routing 필요 | 🆕 |
| **SeigManagerV3_2** | V2 호환 로직 - v3Migrated == false일 때 delegatecall | Selector routing 필요 | 🆕 |

### SeigManagerV3_1 등록 함수 목록 (🆕 V3 신규)

> V3 메인 로직 컨트랙트

| 함수 시그니처 | Selector | 설명 |
|--------------|----------|------|
| `setValidatorReward(address)` | - | ValidatorReward 주소 설정 |
| `setRATContract(address)` | - | RAT 컨트랙트 주소 설정 |
| `setV3CompatContract(address)` | - | V3_2 호환 컨트랙트 주소 설정 |
| `setLayer2Manager(address)` | - | Layer2Manager 주소 설정 |
| `migrateToV3()` | - | V3 마이그레이션 실행 |
| `updateSeigniorage()` | `0x764a7856` | 시뇨리지 분배 (V3 로직) |
| `updateSeigniorageLayer(address)` | `0x1e1f0b60` | Layer2별 시뇨리지 분배 (V3 로직) |
| `estimatedDistribute(uint256,address)` | `0x5015cb2b` | 예상 시뇨리지 분배량 조회 |
| `claimableL2Seigniorage(address)` | - | Layer2 청구 가능 시뇨리지 조회 |
| `transferCoinageToRAT(...)` | - | 검증자 coinage → RAT coinage 전송 |
| `transferCoinageFromRAT(...)` | - | RAT coinage → 검증자 coinage 복구 |
| `pause()` / `unpause()` | - | 컨트랙트 일시 정지/재개 |

### SeigManagerV3_2 등록 함수 목록 (🆕 V3 신규)

> V2 호환 로직 컨트랙트 - V3_1에서 v3Migrated == false일 때 delegatecall로 호출

| 함수 시그니처 | 설명 |
|--------------|------|
| `updateSeigniorageV2()` | V2 방식 시뇨리지 분배 |
| `estimatedDistributeV2(uint256,address)` | V2 방식 예상 분배량 조회 |
| `claimableL2SeigniorageV2(address)` | V2 방식 청구 가능 시뇨리지 |

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
│  3-B. selector 미등록 → 기본 구현체(V1_2)로 delegatecall         │
│                                                                  │
│  ┌──────────────┐                                                │
│  │  initialize  │ → selectorImpl[0x...] 없음 → V1_2 (기본)       │
│  │  setData     │ → selectorImpl[0x...] 없음 → V1_2 (기본)       │
│  │updateSeig    │ → selectorImpl[0x...] = V3_1 → V3_1            │
│  │setLayer2Mgr  │ → selectorImpl[0x...] = V3_1 → V3_1            │
│  └──────────────┘                                                │
│                                                                  │
│  V3_1 내부 (v3Migrated == false인 경우):                          │
│  updateSeigniorage() → delegatecall V3_2.updateSeigniorageV2()   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 상세 배포 절차 (Selector Routing 방식)

```solidity
// ==========================================
// Step 1: 모든 구현체 배포
// ==========================================
SeigManagerV1_2 seigManagerV1_2 = new SeigManagerV1_2();
SeigManagerV3_1 seigManagerV3_1 = new SeigManagerV3_1();
SeigManagerV3_2 seigManagerV3_2 = new SeigManagerV3_2();

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
// Step 4: V3_1, V3_2 구현체 활성화
// ==========================================
proxy.setAliveImplementation2(address(seigManagerV3_1), true);
proxy.setAliveImplementation2(address(seigManagerV3_2), true);

// ==========================================
// Step 5: V3_1 함수들을 V3_1 구현체로 라우팅
// ==========================================
bytes4[] memory v3_1Selectors = new bytes4[](N);
v3_1Selectors[0] = SeigManagerV3_1.setValidatorReward.selector;
v3_1Selectors[1] = SeigManagerV3_1.setRATContract.selector;
v3_1Selectors[2] = SeigManagerV3_1.setLayer2Manager.selector;
v3_1Selectors[3] = SeigManagerV3_1.updateSeigniorage.selector;
v3_1Selectors[4] = SeigManagerV3_1.updateSeigniorageLayer.selector;
// ... 추가 selectors
proxy.setSelectorImplementations2(v3_1Selectors, address(seigManagerV3_1));

// ==========================================
// Step 6: V3_2 호환 컨트랙트 설정 (V3_1에서 delegatecall용)
// ==========================================
SeigManagerV3_1(address(proxy)).setV3CompatContract(address(seigManagerV3_2));
```

### 프록시 주요 함수 설명

| 함수 | 설명 |
|------|------|
| `upgradeTo(address impl)` | 기본 구현체 설정. 미등록 selector 호출시 이 구현체가 처리 |
| `setAliveImplementation2(address impl, bool alive)` | 구현체 활성화/비활성화. selector routing 전 반드시 호출 |
| `setSelectorImplementations2(bytes4[] selectors, address impl)` | 특정 selector들을 특정 구현체로 라우팅 |
| `selectorImplementation(bytes4 selector)` | 특정 selector가 어느 구현체로 라우팅되는지 조회 |

---

## 4. DepositManager 🆕 V3 단일 구현체

| 항목 | 설명 |
|------|------|
| 역할 | 스테이킹 예치/출금 관리 |
| 🆕 V3 변경 | **DepositManagerV3** 단일 구현체로 통합 |
| 패턴 | 기존 다중 구현체 → 단일 구현체로 단순화 |

### V3 통합 내용

기존 4개 구현체(DepositManager, DepositManager_setWithdrawalDelay, DepositManagerV1_1, DepositManagerV1_2)가 **DepositManagerV3** 하나로 통합되었습니다.

| 기존 구현체 | 통합된 기능 |
|------------|------------|
| DepositManager | initialize, deposit, requestWithdrawal 등 기본 기능 |
| DepositManager_setWithdrawalDelay | setWithdrawalDelay, setWithdrawalDelayByOwner |
| DepositManagerV1_1 | setMinDepositGasLimit, setAddresses, withdrawAndDepositL2 |
| DepositManagerV1_2 | V3 콜백 (스테이킹 변경 알림) |

### 주요 함수

| 함수 시그니처 | 설명 |
|--------------|------|
| `initialize(address,address,address,uint256,address)` | 초기화 |
| `deposit(address,address,uint256)` | 예치 (V3 콜백 포함) |
| `requestWithdrawal(address,uint256)` | 출금 요청 |
| `withdrawAndDepositL2(address,uint256)` | 출금 후 L2 예치 |
| `setWithdrawalDelay(address,uint256)` | Layer2별 출금 지연 설정 |
| `setAddresses(address,address)` | L1BridgeRegistry, Layer2Manager 주소 설정 |

### 배포 절차

```solidity
// Step 1: 단일 구현체 배포
DepositManagerV3 depositManagerV3 = new DepositManagerV3();

// Step 2: 프록시 배포 및 구현체 설정
DepositManagerProxy proxy = new DepositManagerProxy();
proxy.upgradeTo(address(depositManagerV3));

// Step 3: 초기화
DepositManagerV3(address(proxy)).initialize(
    wton_, registry_, seigManager_, globalWithdrawalDelay_, address(0)
);

// Step 4: 필요 시 추가 설정
DepositManagerV3(address(proxy)).setAddresses(l1BridgeRegistry_, layer2Manager_);
```

---

## 5. Layer2Manager 🆕 V3 단일 구현체

| 항목 | 설명 |
|------|------|
| 역할 | Layer2 등록 및 관리 |
| 🆕 V3 변경 | **Layer2ManagerV3** 단일 구현체로 통합 |
| 패턴 | 기존 다중 구현체(V1_1, V1_2) → 단일 구현체로 단순화 |

### V3 통합 내용

기존 2개 구현체(Layer2ManagerV1_1, Layer2ManagerV1_2)가 **Layer2ManagerV3** 하나로 통합되었습니다.

| 기존 구현체 | 통합된 기능 |
|------------|------------|
| Layer2ManagerV1_1 | setAddresses, registerCandidateAddOn, transferL2Seigniorage 등 |
| Layer2ManagerV1_2 | getBridgedTONByLayer, getBridgedTON, getLayer2BySystemConfig |

### 주요 함수

| 함수 시그니처 | 설명 |
|--------------|------|
| `setAddresses(...)` | 주소 설정 |
| `registerCandidateAddOn(address,address)` | CandidateAddOn 등록 |
| `transferL2Seigniorage(address)` | L2 시뇨리지 전송 |
| `getBridgedTONByLayer(address)` | Layer2 주소로 Bridged TON 조회 |
| `getBridgedTON(address)` | rollupConfig로 Bridged TON 조회 |
| `getLayer2BySystemConfig(address)` | SystemConfig → Layer2 주소 조회 |

### 배포 절차

```solidity
// Step 1: 단일 구현체 배포
Layer2ManagerV3 layer2ManagerV3 = new Layer2ManagerV3();

// Step 2: 프록시 배포 및 구현체 설정
Layer2ManagerProxy proxy = new Layer2ManagerProxy();
proxy.upgradeTo(address(layer2ManagerV3));

// Step 3: 초기화
Layer2ManagerV3(address(proxy)).setAddresses(
    l1BridgeRegistry_, operatorManagerFactory_, ton_, wton_,
    dao_, depositManager_, seigManager_, swapProxy_
);
```

---

## 6. L1BridgeRegistry (단일 구현체) 🔄 V3 변경

| 항목 | 설명 |
|------|------|
| 역할 | Optimism SystemConfig 등록 및 관리 |
| 구현체 | **L1BridgeRegistryV1_2** (V1_1 기능 모두 포함) |
| 🔄 V3 변경 | V1_2가 V1_1을 완전히 대체 (Selector Routing 불필요) |

### L1BridgeRegistryV1_2 주요 함수

| 함수 시그니처 | 설명 | 비고 |
|--------------|------|------|
| `setAddresses(address,address,address)` | layer2Manager, seigManager, ton 설정 | V1_1 포함 |
| `setSeigniorageCommittee(address)` | 시뇨리지 위원회 설정 | V1_1 포함 |
| `rejectCandidateAddOn(address)` | 시뇨리지 발급 중지 | V1_1 포함 |
| `restoreCandidateAddOn(address,bool)` | 시뇨리지 발급 재개 | V1_1 포함 |
| `registerRollupConfig(...)` | TYPE 1/2/3 롤업 등록 | 🔄 TYPE 3 추가 |
| `registerRollupConfigByManager(...)` | Manager 전용 등록 | 🔄 TYPE 3 추가 |
| `registerRollupConfigByType(...)` | 타입별 권한 체크 등록 | 🆕 V3 신규 |
| `setTypeRegistrant(uint8,address)` | 타입별 등록 권한자 설정 | 🆕 V3 신규 |
| `upgradeToType3(address)` | TYPE 1/2 → TYPE 3 업그레이드 | 🆕 V3 신규 |
| `layer2TVL(address)` | TVL 조회 (TYPE 3 지원) | 🔄 TYPE 3 추가 |

### 배포 코드

```solidity
// L1BridgeRegistryV1_2 단일 구현체 배포 (V1_1 기능 모두 포함)
L1BridgeRegistryV1_2 l1BridgeRegistryImpl = new L1BridgeRegistryV1_2();

L1BridgeRegistryProxy l1BridgeRegistryProxy = new L1BridgeRegistryProxy();
l1BridgeRegistryProxy.upgradeTo(address(l1BridgeRegistryImpl));

// 주소 설정
L1BridgeRegistryV1_2(address(l1BridgeRegistryProxy)).setAddresses(
    layer2ManagerProxy_,
    seigManagerProxy_,
    ton_
);
```

---

## 7. OperatorManager 🆕 V3 단일 구현체

| 항목 | 설명 |
|------|------|
| 역할 | Layer2 오퍼레이터 관리 |
| 배포 방식 | OperatorManagerFactory가 프록시 생성 |
| 🆕 V3 변경 | **OperatorManagerV1_2** 단일 구현체 사용 |

### OperatorManagerFactory 배포

```solidity
// 1. OperatorManagerV1_2 단일 구현체 배포
OperatorManagerV1_2 operatorManagerV1_2Impl = new OperatorManagerV1_2();

// 2. Factory 배포 (V1_2를 기본 구현체로 사용)
OperatorManagerFactory factory = new OperatorManagerFactory(address(operatorManagerV1_2Impl));

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
// Step 2: 시퀀서 담보금 예치 (기존 스테이킹 시스템 사용)
// ==========================================
// 시퀀서는 DepositManager를 통해 스테이킹합니다.
DepositManagerV3(depositManagerProxy).deposit(layer2, operator, amount);

// 담보금 조회
SeigManager(seigManagerProxy).getSequencerStaked(layer2);
```

---

## 8. 🆕 RAT (Randomized Attention Test) - V3 신규

| 항목 | 설명 |
|------|------|
| 역할 | 검증자 무작위 주의 테스트 |
| 🆕 V3 신규 | DisputeGame 생성시 검증자 선택 및 테스트 |

```solidity
// RATInitParams 구조체를 사용하여 초기화
RATInitParams memory params = RATInitParams({
    seigManager: seigManager_,
    wton: wton_,
    ton: ton_,
    layer2Manager: layer2Manager_,
    owner: owner_,
    ratTriggerProbability: 0.01e27,      // RAT 트리거 확률 (RAY 단위, 1%)
    evidenceSubmissionPeriod: 1 hours,   // 증거 제출 기간
    slashingPenalty: 100e27,             // 100 TON (C_off, RAY 단위)
    validatorBuffer: 100e27,             // 100 TON (Δ_validator, RAY 단위)
    minimumThreshold: 200e27,            // 200 TON (D_min = C_off + Δ_validator)
    maxValidatorsPerL2: 100,             // L2별 최대 검증자 수
    challengeGameDuration: 7 days,       // 챌린지 게임 기간
    safetyBuffer: 1 days,                // 안전 버퍼 시간
    l1BridgeRegistry: l1BridgeRegistry_, // L1BridgeRegistry 주소
    treasury: treasury_,                 // Treasury 주소
    attentionCost: 1e27,                 // c_m: 에폭당 attentiveness 유지 비용
    relaxedValidatorCheck: true          // 검증자 유효성 검사 완화 (초기값: true)
});

RAT.initialize(params);
```

### relaxedValidatorCheck 플래그

| 값 | 유효성 기준 | 설명 |
|----|------------|------|
| `true` (초기) | `stakeOf >= C_off` | 완화된 검사 - 검증자 유치 용이 |
| `false` | `stakeOf >= D_min` | 엄격한 검사 - 보안 강화 |

> **참고**: 등록 시에는 flag와 무관하게 항상 `D_min` 이상 필요합니다.

### 검증자 담보금 시스템 (V3 구현 완료)

V3에서 검증자 담보금은 시퀀서와 동일하게 기존 coinage 시스템을 사용합니다.
RAT은 coinage를 직접 조작할 권한이 없으므로, **SeigManager를 통해** burn/mint를 수행합니다.

| 항목 | 설명 |
|------|------|
| 담보금 예치 | DepositManager를 통해 스테이킹 (별도 예치 불필요) |
| 자격 체크 | `stakeOf(layer2, validator)` |
| 선차감 (트리거 시) | SeigManager.transferCoinageToRAT() 호출 |
| 복구 (응답 시) | SeigManager.transferCoinageFromRAT() 호출 |
| 슬래싱 확정 (타임아웃) | RAT이 coinage 보유, treasury로 전송 가능 |

### 배포 시 필수 설정

```solidity
// SeigManager에 RAT 컨트랙트 등록 (RAT이 coinage 전송 함수를 호출하기 위해 필요)
SeigManagerV3_1(seigManagerProxy).setRATContract(ratProxy);
```

### 검증자 등록 절차

```solidity
// 1. 검증자는 미리 DepositManager를 통해 스테이킹
DepositManager(depositManagerProxy).deposit(layer2, validator, amount);

// 2. RAT에 검증자 등록 (별도 TON 전송 없음)
RAT(ratProxy).registerValidator(systemConfig);

// 3. 담보금 조회 (coinage에서 직접 조회)
uint256 collateral = RAT(ratProxy).getValidatorDeposit(validator, systemConfig);
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
