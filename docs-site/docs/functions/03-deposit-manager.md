---
id: functions-deposit-manager
sidebar_position: 3
---

# DepositManager Functions

TON/WTON staking management functions.

## deposit

Stakes WTON.

```solidity
function deposit(address layer2, address account, uint256 amount)
    external
    onlyLayer2(layer2)
    returns (bool)
```

| Item | Content |
|------|---------|
| **Caller** | Staker |
| **Parameters** | layer2: L2 address, account: beneficiary, amount: WTON amount |

**Operation Flow**:
```
1. WTON.transferFrom(msg.sender, this, amount)
2. Update staking records
   - _accStaked[layer2][account] += amount
   - _accStakedLayer2[layer2] += amount
3. SeigManager.onDeposit(layer2, account, amount)
   - V3: Includes minimum collateral check and eligibility status update
```

---

## Configuration Functions (V3 Only)

Configuration functions added in DepositManagerV3.

```solidity
// Initial address setup (L1BridgeRegistry, Layer2Manager)
function setAddresses(address _l1BridgeRegistry, address _layer2Manager) external onlyOwner
```

| Item | Content |
|------|---------|
| **Caller** | Owner (DAO) |
| **Purpose** | Initial setup after V3 deployment |

---

## onApprove

TON.approveAndCall callback.

```solidity
function onApprove(
    address owner,
    address spender,
    uint256 amount,
    bytes calldata data
) external returns (bool)
```

| Item | Content |
|------|---------|
| **Caller** | WTON contract (via TON.approveAndCall) |
| **data Format** | layer2 address (32 bytes) |

---

## requestWithdrawal

Requests withdrawal.

```solidity
function requestWithdrawal(address layer2, uint256 amount) external
```

| Item | Content |
|------|---------|
| **Caller** | Staker |
| **Waiting Period** | 2 weeks (approximately 100,800 blocks) |
| **Withdrawal Restrictions** | Checked in SeigManager.onWithdraw() |

---

## processRequest

Processes withdrawal.

```solidity
function processRequest(address layer2) external
```

| Item | Content |
|------|---------|
| **Caller** | Staker |
| **Condition** | 2 weeks waiting period elapsed |
