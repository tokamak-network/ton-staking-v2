# 8. Security Considerations

[← Back to Table of Contents](./README.md) | [← Previous: Deployment and Operations](./07-deployment-operations.md)

---

## 8.1 Random Number Generation Vulnerability (Severity: High - Mainnet)

**File:** `src/dao/LotteryCandidate.sol` - `drawWinner()` function

```solidity
uint256 randomIndex = uint256(keccak256(abi.encodePacked(
    block.prevrandao, block.timestamp, round, participants.length
))) % participants.length;
```

### Risks
- `block.prevrandao` and `block.timestamp` are values that block producers (validators) can influence.
- If a validator is a participant, they can selectively produce blocks that are advantageous to them.
- MEV (Miner Extractable Value) bots could front-run the draw transaction.

### Current Status
- **Demo/Test Environment:** No issue (Anvil local chain).
- **Mainnet Deployment:** MUST BE REPLACED.

### Recommended Solutions
- Integrate **Chainlink VRF v2.5**.
- 2-transaction pattern: Request draw (`requestRandomWords`) → Receive callback (`fulfillRandomWords`).
- When using VRF, the `drawWinner()` function must be split into `requestDraw()` and `fulfillDraw()`.

---

## 8.2 Access Control

| Role | Control Method | Authority Scope |
|------|----------|----------|
| **Owner (Admin)** | `AccessibleCommon` (`DEFAULT_ADMIN_ROLE`) | Initialization, address settings, proxy upgrades |
| **Operator** | `onlyOperator` (`msg.sender == candidate`) | Lottery draw, entry fee setting, DAO governance |
| **General User** | No restriction | Deposit, withdrawal request, lottery entry, seigniorage update |

### Precautions
- The address stored in the `candidate` variable is the operator.
- The `operator()` function returns `address(this)` (for implementing the ILayer2 interface).
- The operator cannot be changed (`changeOperator()` will always revert).

---

## 8.3 Proxy Upgrade Security

- `upgradeTo()`, `setImplementation2()`, and `setSelectorImplementations2()` are restricted to `onlyOwner`.
- **Beware of Storage Slot Collisions:**
  - New variables must be added to the very bottom of the `LotteryCandidateStorage.sol` file.
  - The order or type of existing variables must not be changed.
  - Variables must not be deleted (keep as an empty slot by commenting out).
- When `pauseProxy` is set, all delegatecalls revert.

---

## 8.4 Reentrancy Attacks

### Risk Point: `processWithdrawal()`
- State change (`processed = true`, `lastProcessedRequestIndex++`) happens after the WTON `transfer()` call.

### Current Mitigation Factors
- Since WTON is a standard ERC20, there is no callback upon transfer → Reentrancy risk is low.
- The `require(!req.processed)` guard prevents double processing.

### Recommendations
- If using custom tokens or ERC777 tokens, make sure to adhere to the Checks-Effects-Interactions pattern.
- Review adding the OpenZeppelin `ReentrancyGuard` if necessary.

---

## 8.5 Seigniorage Distribution Precision

- WTON has high precision with 27 decimals (`1e27 = 1 WTON`).
- Division during seigniorage distribution results in dust.
  - `share = increase * _balances[depositor] / totalDeposited`
  - The remainder (dust) is allocated to the last depositor.
- Verified in tests allowing a 1~2 wei margin of error using `assertApproxEqAbs`.

---

## 8.6 Operator Minimum Staking Requirement

- The `address(this)` of the LotteryCandidate serves as the staking entity in `DepositManager`.
- A stake greater than `SeigManager.minimumAmount()` is required.
  - Test: 100 WTON
  - Demo: 1001 TON (1001e27 WTON)
  - Mainnet: **Needs Verification**
- If the minimum amount is not met, `updateSeigniorage()` will execute but no rewards will be distributed (Silent Success).

---

## 8.7 Frontend Security

- Private keys are included in `.env.example`, but they are default Anvil keys.
- Needs verification that `.env` is included in `.gitignore`.
- The frontend is purely client-side → No risk of exposing server secrets.
- However, since contract addresses are included in `deployment.json`, manage them carefully upon mainnet deployment.

---

[Next: Known Issues →](./09-known-issues.md)
