---
id: functions-layer2-manager
sidebar_position: 4
---

# Layer2Manager 함수

L2 등록 및 Bridged TON 조회 함수입니다.

## getBridgedTon

Bridged TON을 조회합니다.

```solidity
function getBridgedTon(address rollupConfig) public view returns (uint256 bridgedTON)
function getBridgedTonByLayer(address layer2) public view returns (uint256 bridgedTON)
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | 누구나 |
| **조회 방식** | L1BridgeRegistry.layer2Tvl() 호출 |

---

## 설정 함수 (V3 전용)

Layer2ManagerV3에서 추가된 설정 함수들입니다.

```solidity
// 주소 설정 1 (L1BridgeRegistry, DepositManager)
function setAddresses1(address _l1BridgeRegistry, address _depositManager) external onlyOwner

// 주소 설정 2 (SeigManager, OperatorManagerFactory)
function setAddresses2(address _seigManager, address _operatorManagerFactory) external onlyOwner

// OperatorManagerFactory 업데이트
function setOperatorManagerFactory(address _operatorManagerFactory) external onlyOwner
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | Owner (DAO) |
| **용도** | V3 배포 후 초기 설정 및 업데이트 |

---

## getLayer2BySystemConfig

SystemConfig로 Layer2 주소를 조회합니다.

```solidity
function getLayer2BySystemConfig(address systemConfig) external view returns (address layer2)
```
