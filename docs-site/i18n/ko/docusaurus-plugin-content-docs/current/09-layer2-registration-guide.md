---
id: 09-layer2-registration-guide
sidebar_position: 9
---

# Layer2 등록 가이드

## 개요

TON Staking V3에서 Layer2를 등록하고 검증자를 등록하는 전체 흐름을 설명합니다.

## 사전 요구사항

**Optimism SystemConfig 배포**
- L1 Standard Bridge
- Optimism Portal
- Dispute Game Factory (TYPE 3인 경우)
- Unsafe Block Signer (시퀀서 주소)

## 등록 절차 개요

**권한 모델**:
- **L1BridgeRegistry**: 권한자(Manager + Registrant)만 등록 가능
- **Layer2Manager**: 아무나 등록 가능 (permissionless)

### 1단계: L1BridgeRegistry에 SystemConfig 등록

**호출자**: Manager + Registrant 권한을 가진 주소 (DAO 또는 관리자)
**호출 컨트랙트**: `L1BridgeRegistry`
**호출 함수**: `registerRollupConfig()`

#### 1-1. 권한 부여 (선행 작업)

```solidity
// L1BridgeRegistry에 권한 부여 (DAO 또는 관리자가 실행)
l1BridgeRegistry.addManager(owner);      // Manager 권한 부여
l1BridgeRegistry.addRegistrant(owner);   // Registrant 권한 부여
```

#### 1-2. registerRollupConfig 호출

```solidity
// L1BridgeRegistry.registerRollupConfig() 호출
l1BridgeRegistry.registerRollupConfig(
    address(systemConfig),  // 파라미터 1: Optimism SystemConfig 컨트랙트 주소
    3,                      // 파라미터 2: rollupType (TYPE_3 = bedrock + DisputeGame + nativeTON)
    l2TONAddress,          // 파라미터 3: L2 네이티브 TON 컨트랙트 주소
    "Layer2Name"           // 파라미터 4: Layer2 이름 (문자열)
);
```

**결과**:
- SystemConfig가 L1BridgeRegistry에 등록됨
- `rollupInfo[systemConfig] = {rollupType: 3, l2TON: l2TONAddress, ...}` 매핑 생성

**중요**: 2단계의 registerCandidateAddOn은 내부적으로 L1BridgeRegistry를 확인하므로 이 단계를 먼저 완료해야 합니다.

### 2단계: Layer2 Candidate 등록

**호출자**: 아무나 (permissionless)
**호출 컨트랙트**: `Layer2Manager`
**호출 함수**: `registerCandidateAddOn()`

#### 2-1. WTON 준비

```solidity
uint256 operatorDeposit = 1000 * RAY; // 1000 WTON (예치 금액 결정)

// WTON 발행 및 Layer2Manager 승인
wton.mint(msg.sender, operatorDeposit);
wton.approve(layer2ManagerProxy, operatorDeposit);
```

#### 2-2. registerCandidateAddOn 호출

```solidity
// Layer2Manager.registerCandidateAddOn() 호출
layer2Manager.registerCandidateAddOn(
    address(systemConfig),  // 파라미터 1: Optimism SystemConfig 주소 (1단계에서 등록한 것)
    operatorDeposit,        // 파라미터 2: 예치 금액 (RAY 단위 WTON, 1e27)
    false,                  // 파라미터 3: flagTON (false=WTON, true=TON)
    "Layer2 Memo"           // 파라미터 4: 메모 (DAO가 CandidateAddOn 생성 시 사용)
);
```

#### 2-3. 내부 자동 처리 흐름

`registerCandidateAddOn()` 호출 시 다음 과정이 **자동으로** 순차 실행됩니다:

1. **OperatorManager 생성**
   ```
   OperatorManagerFactory.createOperatorManager(systemConfig) 호출
   → SystemConfig의 unsafeBlockSigner를 operator로 사용하는 OperatorManager 생성
   ```

2. **CandidateAddOn 생성 및 Layer2Registry 자동 등록**
   ```
   DAO.createCandidateAddOn(memo, operatorManager) 호출
   → 새로운 CandidateAddOn 컨트랙트 생성
   → 내부에서 Layer2Registry.registerAndDeployCoinage(candidateAddOn) 자동 호출
   → Coinage 컨트랙트 생성
   ```

3. **매핑 생성**
   ```
   rollupConfigInfo[systemConfig] = {status: 1, operatorManager: operatorManagerAddress}
   operatorInfo[operatorManager] = {rollupConfig: systemConfig, candidateAddOn: candidateAddOn}
   ```

4. **Operator 예치**
   ```
   DepositManager.deposit(candidateAddOn, operatorManager, operatorDeposit) 자동 호출
   → Operator의 WTON이 해당 Layer2의 Coinage로 예치됨
   ```

**결과**:
- `systemConfig → layer2 (candidateAddOn)` 매핑 완성
- Layer2Registry에 candidateAddOn 등록 완료 (Coinage 생성됨)
- Operator 예치 완료
- Layer2 등록 완료: `Layer2Manager.getLayer2BySystemConfig(systemConfig)` 호출로 layer2 조회 가능

## 테스트 환경 설정

### SimpleMockSystemConfig 설정

```solidity
SimpleMockSystemConfig mockSystemConfig = new SimpleMockSystemConfig();
mockSystemConfig.setL1StandardBridge(mockL1Bridge);
mockSystemConfig.setOptimismPortal(mockPortal);
mockSystemConfig.setDisputeGameFactory(mockDisputeGameFactory);
mockSystemConfig.setUnsafeBlockSigner(sequencer); // 시퀀서 주소 설정 (중요!)
```

**참고**: unsafeBlockSigner는 시퀀서 주소여야 합니다. operator와 구분이 필요합니다.

## 참고

- 실제 구현: `test/v3/V3ScenarioReal.t.sol`
- 단위 테스트: `test/v3/BasicFunctions.t.sol`
- Layer2Manager: `src/layer2/Layer2ManagerV1_1.sol`
- RAT: `src/validator/RAT.sol`
