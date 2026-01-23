# Slashing Mechanism Specification

## 1. Overview

The Slashing mechanism is a system in Tokamak Network that confiscates staking assets from Operators (sequencers) who have acted maliciously or incorrectly, and provides rewards to Challengers who discover and report such behavior.

### 1.1 Core Objectives

1. **Network Security**: Incentivize honest behavior by imposing economic loss on malicious Operators
2. **Challenger Incentives**: Provide economic rewards to Challengers who submit Fraud Proofs
3. **Automated Execution**: Enable permissionless slashing—anyone can trigger slashing

### 1.2 Related Contracts

| Contract | Role |
|----------|------|
| **Layer2Manager_Slashing** | DisputeGame verification and slashing trigger |
| **DepositManager_Slashing** | Staking accounting and reward distribution |
| **SeigManager_Slashing** | Coinage and TOT token burning |

---

## 2. Slashing Process

### 2.1 End-to-End Flow

```
1. Operator submits incorrect Output Root
   │
2. Challenger submits Fraud Proof
   │
3. DisputeGame proceeds and resolves
   │ (GameStatus.CHALLENGER_WINS)
   │
4. Layer2Manager_Slashing.slashingCandidate() called
   │ - DisputeGame verification
   │ - Challenger address extraction
   │
5. DepositManager_Slashing.slash() called
   │ - Staking ledger reset
   │ - Reward calculation and payout
   │
6. SeigManager_Slashing.onSlash() called
   │ - Coinage token burn
   │ - TOT token burn
   │
7. Complete
   └─► Operator staking removed
   └─► Challenger reward paid
```

### 2.2 Step-by-Step Details

#### 2.2.1 DisputeGame Verification (Layer2Manager_Slashing)

**Function**: `slashingCandidate(address _operator, GameType _gameType, Claim _rootClaim, bytes calldata _extraData, address _disputeGame)`

**Verification steps**:

1. **Operator address validation**
   ```solidity
   require(_operator != address(0), "ZeroAddressError");
   ```

2. **DisputeGameFactory address resolution**
   
   Each Operator has a unique `rollupConfig` address, which is used to look up that Operator's DisputeGameFactory address.
   **Each Operator uses a different DisputeGameFactory.**
   
   ```solidity
   address disputeGameFactory = ISystemConfig(operatorInfo[_operator].rollupConfig)
       .disputeGameFactory();
   require(disputeGameFactory != address(0), "ZeroAddressError");
   ```
   
   - `operatorInfo[_operator].rollupConfig`: Operator-specific RollupConfig address
   - Each Operator uses the DisputeGameFactory for their L2 chain

3. **DisputeGame registration check**
   ```solidity
   (IDisputeGame disputeGame, ) = IDisputeGameFactory(disputeGameFactory).games(
       _gameType,
       _rootClaim,
       _extraData
   );
   require(address(disputeGame) == _disputeGame, "wrong dispute game Address");
   ```

4. **DisputeGame status check**
   ```solidity
   GameStatus status = IDisputeGame(disputeGame).status();
   require(status == GameStatus.CHALLENGER_WINS, "StatusError");
   ```

5. **Challenger address extraction**
   ```solidity
   address challenger = _getWinningChallenger(_disputeGame);
   require(challenger != address(0), "invalid challenger");
   ```

   - `_getWinningChallenger()`: Extracts Challenger address from DisputeGame's `claimData(0).counteredBy`
   - `claimData(0)` is the root claim; `counteredBy` is the Challenger who defeated it

#### 2.2.2 Staking Accounting (DepositManager_Slashing)

**Function**: `slash(address layer2, address operator, address challenger)`

**Processing steps**:

1. **Operator validation**
   ```solidity
   require(operator == ILayer2(layer2).operator(), "operator is not an operator");
   require(challenger != address(0), "invalid challenger address");
   ```

2. **Slashing amount check**
   ```solidity
   uint256 slashedAmount = _accStaked[layer2][operator];
   require(slashedAmount > 0, "no staked amount to slash");
   ```

3. **Reward amount calculation**
   ```solidity
   uint256 rewardAmount = 0;
   if (slashingRewardRate > 0) {
       // 100% = 10000 units
       rewardAmount = (slashedAmount * slashingRewardRate) / 10000;
   }
   ```

   - `slashingRewardRate`: Share of slashed amount paid to Challenger (default: 10% = 1000)
   - Example: slashedAmount = 1000 WTON, slashingRewardRate = 1000 → rewardAmount = 100 WTON

4. **Ledger reset**
   ```solidity
   _accStaked[layer2][operator] = 0;
   _accStakedLayer2[layer2] = _accStakedLayer2[layer2] - slashedAmount;
   _accStakedAccount[operator] = _accStakedAccount[operator] - slashedAmount;
   ```

5. **Request slashing from SeigManager**
   ```solidity
   uint256 totalSlashedAmount = ISeigManager(_seigManager).onSlash(layer2, operator);
   ```

6. **Pay Challenger reward**
   ```solidity
   if (rewardAmount > 0) {
       IERC20(_wton).safeTransfer(challenger, rewardAmount);
       emit ChallengerRewarded(layer2, challenger, rewardAmount);
   }
   ```

#### 2.2.3 Token Burning (SeigManager_Slashing)

**Function**: `onSlash(address layer2, address operator)`

**Burning logic**:

Burns the Operator's full staking amount (principal + accrued seigniorage) from Coinage and TOT.

**Burning formula**:

```
v = operator's coinages[layer2] balance
α = (tot.balanceOf(layer2) - coinages[layer2].totalSupply()) × (v / coinages[layer2].totalSupply())

Burn amounts:
- coinages[layer2]: v
- tot: v + α
```

**Implementation**:

```solidity
function onSlash(address layer2, address operator) external onlyDepositManager returns (uint256 totalSlashedAmount) {
    uint256 operatorAmount = _coinages[layer2].balanceOf(operator);

    // burn {v + α} {tot} tokens from the layer2 contract
    uint256 totAmount = _uncommittedOperatorSeigniorage(layer2, operatorAmount);
    _tot.burnFrom(layer2, operatorAmount + totAmount);

    // burn {v} {coinages[layer2]} tokens from the operator
    _coinages[layer2].burnFrom(operator, operatorAmount);

    emit Slashed(layer2, operator);

    return operatorAmount + totAmount;
}
```

**α calculation**:

```solidity
function _uncommittedOperatorSeigniorage(
    address layer2,
    uint256 amount
) internal view returns (uint256) {
    uint256 coinageTotalSupply = _coinages[layer2].totalSupply();
    uint256 totBalance = _tot.balanceOf(layer2);

    // Error correction: treat difference ≤ 1e-9 WTON as 0
    if (coinageTotalSupply >= totBalance && coinageTotalSupply - totBalance < WEI_UNIT) {
        return 0;
    }

    return FullMath.rdiv(
        FullMath.rmul(totBalance - coinageTotalSupply, amount),
        coinageTotalSupply
    );
}
```

---

## 3. Key Parameters

### 3.1 slashingRewardRate

**Description**: Share of slashed amount paid to the Challenger

**Units**: 10000 = 100%

**Setter**: `DepositManager_Slashing.setSlashingRewardRate(uint256 newRate)`

**Constraints**:
```solidity
require(newRate <= 10000, "rate exceeds 100%");
```

**Recommended value**: 1000 (10%)

**Examples**:
| slashingRewardRate | Slashed Amount | Challenger Reward | DAO / Burned |
|--------------------|----------------|-------------------|--------------|
| 1000 (10%) | 1000 WTON | 100 WTON | 900 WTON |
| 2000 (20%) | 1000 WTON | 200 WTON | 800 WTON |
| 5000 (50%) | 1000 WTON | 500 WTON | 500 WTON |

---

## 4. Permissions and Access Control

### 4.1 Function Permissions

| Function | Contract | Permission | Description |
|----------|----------|------------|-------------|
| `slashingCandidate()` | Layer2Manager_Slashing | **Permissionless** | Callable by anyone |
| `slash()` | DepositManager_Slashing | `onlyLayer2Manager` | Callable only by Layer2Manager |
| `onSlash()` | SeigManager_Slashing | `onlyDepositManager` | Callable only by DepositManager |
| `setSlashingRewardRate()` | DepositManager_Slashing | `onlyOwner` | Callable only by Owner (DAO) |

### 4.2 Modifier Definitions

```solidity
// DepositManager_Slashing
modifier onlyLayer2Manager() {
    require(msg.sender == layer2Manager, "not layer2Manager");
    _;
}

// SeigManager_Slashing
modifier onlyDepositManager() {
    require(msg.sender == _depositManager, "not onlyDepositManager");
    _;
}
```

---

## 5. Events

### 5.1 Layer2Manager_Slashing

```solidity
event CandidateSlashed(
    address indexed operator,
    address indexed challenger,
    address disputeGame
);
```

**Emitted**: On successful `slashingCandidate()` call

**Parameters**:
- `operator`: Slashed Operator address
- `challenger`: Challenger address receiving reward
- `disputeGame`: DisputeGame contract address

### 5.2 DepositManager_Slashing

```solidity
event Slashed(
    address indexed layer2,
    address indexed operator,
    address indexed challenger,
    uint256 slashedAmount,
    uint256 rewardAmount
);

event ChallengerRewarded(
    address indexed layer2,
    address indexed challenger,
    uint256 amount
);

event SlashingRewardRateSet(uint256 newRate);
```

**Slashed**:
- `layer2`: Layer2 (CandidateAddOn) address
- `operator`: Slashed Operator address
- `challenger`: Challenger address
- `slashedAmount`: Total slashed amount
- `rewardAmount`: Reward paid to Challenger

**ChallengerRewarded**:
- `layer2`: Layer2 address
- `challenger`: Challenger address
- `amount`: Reward amount paid

**SlashingRewardRateSet**:
- `newRate`: New reward rate

### 5.3 SeigManager_Slashing

```solidity
event Slashed(address layer2, address operator);
```

**Emitted**: On successful `onSlash()` call

**Parameters**:
- `layer2`: Layer2 address
- `operator`: Slashed Operator address

---

## 6. Error Handling

### 6.1 Layer2Manager_Slashing

```solidity
error ZeroAddressError();
error StatusError();
error SlashingError();
```

**ZeroAddressError**:
- Operator address is 0x0
- Could not resolve DisputeGameFactory address
- Challenger address is 0x0

**StatusError**:
- DisputeGame status is not `CHALLENGER_WINS`

**SlashingError**:
- `DepositManager.slash()` call failed

### 6.2 DepositManager_Slashing

```solidity
require(operator == ILayer2(layer2).operator(), "operator is not an operator");
require(challenger != address(0), "invalid challenger address");
require(slashedAmount > 0, "no staked amount to slash");
uint256 totalSlashedAmount = ISeigManager(_seigManager).onSlash(layer2, operator);
```

### 6.3 SeigManager_Slashing

```solidity
require(msg.sender == _depositManager, "not onlyDepositManager");
```

---

## 7. Security Considerations

### 7.1 Reentrancy Mitigation

**DepositManager_Slashing**:
- Update ledger first, then perform external calls (Checks-Effects-Interactions)
```solidity
// 1. Ledger update (Effects)
_accStaked[layer2][operator] = 0;
_accStakedLayer2[layer2] = _accStakedLayer2[layer2] - slashedAmount;
_accStakedAccount[operator] = _accStakedAccount[operator] - slashedAmount;

// 2. External calls (Interactions)
uint256 totalSlashedAmount = ISeigManager(_seigManager).onSlash(layer2, operator);
IERC20(_wton).safeTransfer(challenger, rewardAmount);
```

### 7.2 Permission Checks

- `onSlash()`: Callable only by DepositManager
- `slash()`: Callable only by Layer2Manager
- `setSlashingRewardRate()`: Callable only by Owner (DAO)

### 7.3 DisputeGame Validation

- Confirm game is registered in DisputeGameFactory
- Confirm game status is `CHALLENGER_WINS`
- Confirm Challenger address is valid

### 7.4 Error Correction

**SeigManager_Slashing**:
- Correct RAY-precision rounding; treat difference ≤ 1e-9 WTON as zero
```solidity
if (coinageTotalSupply >= totBalance && coinageTotalSupply - totBalance < WEI_UNIT) {
    return 0;
}
```

---

## 9. Gas Optimization

### 9.1 Batched Ledger Updates

```solidity
// Update all ledger entries in one go
_accStaked[layer2][operator] = 0;
_accStakedLayer2[layer2] = _accStakedLayer2[layer2] - slashedAmount;
_accStakedAccount[operator] = _accStakedAccount[operator] - slashedAmount;
```

### 9.2 Conditional Reward Payout

```solidity
// Skip reward calculation and transfer when slashingRewardRate is 0
if (slashingRewardRate > 0) {
    rewardAmount = (slashedAmount * slashingRewardRate) / 10000;
}

if (rewardAmount > 0) {
    IERC20(_wton).safeTransfer(challenger, rewardAmount);
    emit ChallengerRewarded(layer2, challenger, rewardAmount);
}
```

### 9.3 Early Return for Small Error

```solidity
// Early return when error is negligible
if (coinageTotalSupply >= totBalance && coinageTotalSupply - totBalance < WEI_UNIT) {
    return 0;
}
```

---

## 8. Upgrade Considerations

### 8.1 Proxy Pattern

All Slashing contracts use the Proxy pattern and are upgradeable:

```solidity
contract SeigManager_Slashing is
    ProxyStorage,
    AuthControlSeigManager,
    SeigManagerStorage,
    SeigManagerV1_1Storage,
    SeigManagerV1_3Storage,
    SeigManagerV1_4Storage
```

### 8.2 Storage Layout

- Add new storage variables only after existing ones
- Do not change types or order of existing variables
- Introduce new versioned storage contracts (e.g. `DepositManagerV1_2Storage`)

### 8.3 Compatibility

- Keep existing event signatures
- Keep existing function signatures (overloading allowed)
- Keep existing permission model

---

## 9. References

### 9.1 Contract Files

- `src/layer2/Layer2Manager_Slashing.sol`
- `src/stake/managers/DepositManager_Slashing.sol`
- `src/stake/managers/SeigManager_Slashing.sol`

### 9.2 Test Files

- `test/slashing/SlashingTest.t.sol`
- `test/slashing/SlashingE2E_Functional.t.sol`
- `test/slashing/SlashingE2E_Revert.t.sol`

### 9.3 Interfaces

- `src/stake/interfaces/ISeigManager.sol`
- `src/stake/interfaces/IIDepositManager.sol`
- `src/layer2/interfaces/IDisputeGame.sol`
- `src/layer2/interfaces/IDisputeGameFactory.sol`
- `src/layer2/interfaces/IFaultDisputeGame.sol`
