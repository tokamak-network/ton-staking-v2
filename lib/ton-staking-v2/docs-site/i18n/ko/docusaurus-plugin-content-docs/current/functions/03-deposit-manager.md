---
id: functions-deposit-manager
sidebar_position: 3
---

# DepositManager 함수

TON/WTON 스테이킹 관리 함수입니다.

## deposit

WTON을 스테이킹합니다.

```solidity
function deposit(address layer2, address account, uint256 amount)
    external
    onlyLayer2(layer2)
    returns (bool)
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | 스테이커 |
| **파라미터** | layer2: L2 주소, account: 수혜자, amount: WTON 금액 |

**동작 흐름**:
```
1. WTON.transferFrom(msg.sender, this, amount)
2. 스테이킹 기록 업데이트
   - _accStaked[layer2][account] += amount
   - _accStakedLayer2[layer2] += amount
3. SeigManager.onDeposit(layer2, account, amount)
   - V3: 최소 담보금 체크 및 자격 상태 업데이트 포함
```

---

## 설정 함수 (V3 전용)

DepositManagerV3에서 추가된 설정 함수들입니다.

```solidity
// 주소 초기 설정 (L1BridgeRegistry, Layer2Manager)
function setAddresses(address _l1BridgeRegistry, address _layer2Manager) external onlyOwner
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | Owner (DAO) |
| **용도** | V3 배포 후 초기 설정 |

---

## onApprove

TON.approveAndCall 콜백입니다.

```solidity
function onApprove(
    address owner,
    address spender,
    uint256 amount,
    bytes calldata data
) external returns (bool)
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | WTON 컨트랙트 (TON.approveAndCall 경유) |
| **data 형식** | layer2 주소 (32바이트) |

---

## requestWithdrawal

출금을 요청합니다.

```solidity
function requestWithdrawal(address layer2, uint256 amount) external
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | 스테이커 |
| **대기 기간** | 2주 (약 100,800 블록) |
| **출금 제한** | SeigManager.onWithdraw()에서 체크 |

---

## processRequest

출금을 처리합니다.

```solidity
function processRequest(address layer2) external
```

| 항목 | 내용 |
|------|------|
| **호출 주체** | 스테이커 |
| **조건** | 2주 대기 기간 경과 |
