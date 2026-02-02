---
id: functions-operator-manager-factory
sidebar_position: 9
---

# OperatorManagerFactory 함수

오퍼레이터 매니저 생성 및 관리 함수입니다.

## createOperatorManager

오퍼레이터 매니저를 생성합니다.

```solidity
function createOperatorManager(address rollupConfig) external returns (address operatorManager)
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | Layer2Manager만 |
| **구현체** | V1_1 (기본, TYPE 3 업그레이드시 V1_2로 수동 업그레이드) |

**동작 흐름**:
```
1. msg.sender == layer2Manager 확인
2. rollupConfig의 unsafeBlockSigner() → sManager 조회
3. CREATE2로 OperatorManagerProxy 생성
4. upgradeTo(operatorManagerImp), setAddresses() 호출
5. transferManager(sManager), transferOwnership(sOwner)
```

---

## getAddress

오퍼레이터 매니저 주소를 계산합니다.

```solidity
function getAddress(address rollupConfig) public view returns (address)
```

| 항목 | 내용 |
|------|------|
| **용도** | CREATE2 주소 계산 |

---

## 설정 함수

```solidity
// 구현체 변경
function changeOperatorManagerImp(address newOperatorManagerImp) external onlyOwner

// 주소 설정
function setAddresses(address _depositManager, address _ton, address _wton, address _layer2Manager) external onlyOwner
```

---

## TYPE 3 업그레이드 절차

TYPE 1/2 롤업이 DisputeGame을 도입하여 TYPE 3로 업그레이드하려면:

```
1. L1BridgeRegistry.upgradeToType3(rollupConfig)
   └── DisputeGameFactory 확인 및 등록
   └── rollupType = 3으로 변경

2. OperatorManagerProxy.upgradeTo(V1_2 impl)
   └── owner가 직접 호출
   └── TYPE 3 기능 활성화
```
