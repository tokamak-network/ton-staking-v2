# Winning Challenger Tracking Implementation Plan

## Overview

Implement a system to track bond recipients during `_distributeBond` calls within the FaultDisputeGame's `resolveClaim` function, allowing for equal distribution of slashing rewards to all winning challengers.

---

## Current Structure vs New Structure

### Current Structure

```
Layer2Manager_Slashing.slashingCandidate()
    ↓
_getWinningChallenger() → claimData(0).counteredBy (Single Address)
    ↓
DepositManager_Slashing.slash(challenger) → Transfers total reward to a single challenger
```

### New Structure

```
FaultDisputeGame.resolveClaim()
    ↓
When calling _distributeBond() → Call _recordWinningChallenger()
    ↓
Record winner in winningChallengers array (Excluding gameCreator)
    ↓
Layer2Manager_Slashing.slashingCandidate()
    ↓
getWinningChallengers() → Returns address[]
    ↓
DepositManager_Slashing.slash(challengers[]) → Equal distribution of rewards
```

---

## Core Logic

### Winner Recording Conditions

1.  Called during `_distributeBond(recipient, claim)`
2.  `recipient != gameCreator()` (Excluding the Proposer)
3.  Record duplicate addresses only once

### Recording Timing

Immediately after calling `_distributeBond` within the `resolveClaim` function (3 locations):
-   Line 793: When resolving a claim with no children
-   Line 854: When challenging the L2 block number
-   Line 861: When resolving a standard subgame

---

## Modifications by File

### 1. FaultDisputeGame.sol Modification

**File:** `lib/optimism/packages/contracts-bedrock/src/dispute/FaultDisputeGame.sol`

#### 1.1 Adding State Variables

```solidity
/// @notice Mapping to track if an address is a winning challenger
mapping(address => bool) public isWinningChallenger;

/// @notice Array of all winning challengers
address[] internal _winningChallengers;
```

#### 1.2 Adding Internal Functions

```solidity
/// @notice Records a winning challenger address
/// @param recipient The address that received a bond
function _recordWinningChallenger(address recipient) internal {
    // Excluding gameCreator (Proposer)
    if (recipient == gameCreator()) return;
    
    // Duplicate check
    if (isWinningChallenger[recipient]) return;
    
    isWinningChallenger[recipient] = true;
    _winningChallengers.push(recipient);
}
```

#### 1.3 Adding View Functions

```solidity
/// @notice Returns all winning challengers
/// @return challengers Array of winning challenger addresses
function getWinningChallengers() external view returns (address[] memory challengers) {
    return _winningChallengers;
}

/// @notice Returns the count of winning challengers
/// @return count Number of winning challengers
function getWinningChallengersCount() external view returns (uint256 count) {
    return _winningChallengers.length;
}
```

#### 1.4 Modifying resolveClaim Function

```solidity
// Case 1: Add after Line 793
_distributeBond(recipient, subgameRootClaim);
_recordWinningChallenger(recipient);  // Added

// Case 2: Add after Line 854
_distributeBond(challenger, subgameRootClaim);
_recordWinningChallenger(challenger);  // Added

// Case 3: Add after Line 861
_distributeBond(bondRecipient, subgameRootClaim);
_recordWinningChallenger(bondRecipient);  // Added
```

---

### 2. IFaultDisputeGame Interface Modification

**File:** `src/layer2/interfaces/IFaultDisputeGame.sol`

```solidity
interface IFaultDisputeGame is IDisputeGame {
    // ... Existing functions ...
    
    /// @notice Returns all winning challengers
    function getWinningChallengers() external view returns (address[] memory);
    
    /// @notice Returns the count of winning challengers
    function getWinningChallengersCount() external view returns (uint256);
    
    /// @notice Check if an address is a winning challenger
    function isWinningChallenger(address) external view returns (bool);
}
```

---

### 3. Layer2Manager_Slashing Modification

**File:** `src/layer2/Layer2Manager_Slashing.sol`

#### 3.1 Changing Function Signature

```solidity
// Previous
function _getWinningChallenger(address disputeGame) internal view returns (address challenger)

// Changed
function _getWinningChallengers(address disputeGame) internal view returns (address[] memory challengers)
```

#### 3.2 Implementation Change

```solidity
function _getWinningChallengers(address disputeGame) internal view returns (address[] memory challengers) {
    return IFaultDisputeGame(disputeGame).getWinningChallengers();
}
```

#### 3.3 Modifying slashingCandidate Function

```solidity
function slashingCandidate(
    address _operatorManager,
    GameType _gameType,
    Claim _rootClaim,
    bytes calldata _extraData,
    address _disputeGame
) external {
    // ... Existing validation logic ...
    
    // Extract winning challenger addresses
    address[] memory challengers = _getWinningChallengers(_disputeGame);
    require(challengers.length > 0, "no winning challengers");
    
    // Slashing the operator and reward the challengers
    if (
        !IIDepositManager(depositManager).slash(
            operatorInfo[_operatorManager].candidateAddOn,
            _operatorManager,
            challengers  // Passing address[]
        )
    ) revert SlashingError();
    
    // ... Rest of the logic ...
}
```

---

### 4. IIDepositManager Interface Modification

**File:** `src/stake/interfaces/IIDepositManager.sol`

```solidity
// Previous
function slash(address layer2, address operator, address challenger) external returns (bool);

// Changed
function slash(address layer2, address operator, address[] calldata challengers) external returns (bool);
```

---

### 5. DepositManager_Slashing Modification

**File:** `src/stake/managers/DepositManager_Slashing.sol`

#### 5.1 Changing Function Signature

```solidity
function slash(
    address layer2,
    address operator,
    address[] calldata challengers
) external onlyLayer2Manager returns (bool) {
    require(operator == ILayer2(layer2).operator(), "operator is not an operator");
    require(challengers.length > 0, "no challengers");
    
    // Validate all challenger addresses
    for (uint256 i = 0; i < challengers.length; i++) {
        require(challengers[i] != address(0), "invalid challenger address");
    }
    
    // ... Existing slashing logic ...
    
    uint256 totalSlashedAmount = ISeigManager(_seigManager).onSlash(layer2, operator);
    require(totalSlashedAmount > 0, "Slashed Amount is 0");
    
    // Calculate reward amount
    uint256 rewardAmount = 0;
    if (slashingRewardRate > 0) {
        rewardAmount = (totalSlashedAmount * slashingRewardRate) / 10000;
    }
    
    // Equal distribution of rewards
    if (rewardAmount > 0) {
        _distributeRewards(layer2, challengers, rewardAmount);
    }
    
    emit Slashed(layer2, operator, challengers[0], totalSlashedAmount, rewardAmount);
    
    return true;
}
```

#### 5.2 Adding Reward Distribution Function

```solidity
/// @notice Distribute rewards equally among challengers
/// @param layer2 The layer2 address
/// @param challengers Array of challenger addresses
/// @param totalReward Total reward amount to distribute
function _distributeRewards(
    address layer2,
    address[] calldata challengers,
    uint256 totalReward
) internal {
    uint256 rewardPerChallenger = totalReward / challengers.length;
    uint256 remainder = totalReward % challengers.length;
    
    for (uint256 i = 0; i < challengers.length; i++) {
        uint256 amount = rewardPerChallenger;
        // Remaining goes to the first challenger
        if (i == 0) {
            amount += remainder;
        }
        
        IERC20(_wton).safeTransfer(challengers[i], amount);
        emit ChallengerRewarded(layer2, challengers[i], amount);
    }
}
```

#### 5.3 Adding New Event (Optional)

```solidity
/// @notice Emitted when multiple challengers receive rewards
event ChallengersRewarded(
    address indexed layer2,
    uint256 totalReward,
    uint256 challengerCount
);
```

---

## Test Plan

### 1. FaultDisputeGame Test

**File:** `test/dispute/FaultDisputeGame.t.sol` (New or modifying existing)

```solidity
function test_WinningChallengersTracking() public {
    // 1. Create Game
    // 2. Perform moves by multiple challengers
    // 3. Resolve Game
    // 4. Verify getWinningChallengers() results
    // 5. Verify gameCreator is not included
    // 6. Verify no duplicate addresses
}
```

### 2. Slashing Reward Distribution Test

**File:** `test/v3/v3mode/BasicSlashing/SlashingMultiChallengerTest.t.sol` (New)

```solidity
function test_MultipleChallengers_EqualDistribution() public {
    // 1. Register Candidate and Stake
    // 2. Create DisputeGame
    // 3. Perform moves by 3 challengers each
    // 4. Resolve Game (CHALLENGER_WINS)
    // 5. Execute slashingCandidate
    // 6. Verify all 3 receive equal rewards
}

function test_SingleChallenger_FullReward() public {
    // Single challenger scenario (backward compatibility)
}

function test_Remainder_GoesToFirstChallenger() public {
    // Verification of remainder handling
}
```

---

## TODO Checklist

### Phase 1: FaultDisputeGame Modification
- [ ] Add state variables (isWinningChallenger, _winningChallengers)
- [ ] Add _recordWinningChallenger function
- [ ] Add getWinningChallengers, getWinningChallengersCount functions
- [ ] Add _recordWinningChallenger calls in 3 locations within resolveClaim
- [ ] Write unit tests

### Phase 2: Interface Modification
- [ ] Update IFaultDisputeGame interface
- [ ] Update IIDepositManager interface

### Phase 3: Layer2Manager_Slashing Modification
- [ ] Change to _getWinningChallengers function
- [ ] Modify slashingCandidate function

### Phase 4: DepositManager_Slashing Modification
- [ ] Change slash function signature
- [ ] Add _distributeRewards function
- [ ] Update events

### Phase 5: Integration Testing
- [ ] Test equal distribution for multiple challengers
- [ ] Test single challenger compatibility
- [ ] Test edge cases

---

## Considerations

### 1. Gas Costs

| Item | Additional Cost |
|------|----------|
| _recordWinningChallenger call | ~20,000 gas (per new address) |
| getWinningChallengers view | Proportional to array size |
| Multiple transfers | Number of challengers × ~21,000 gas |

### 2. Limiting Maximum Number of Challengers

Optionally add a limit for DoS prevention:

```solidity
uint256 public constant MAX_WINNING_CHALLENGERS = 100;

function _recordWinningChallenger(address recipient) internal {
    if (_winningChallengers.length >= MAX_WINNING_CHALLENGERS) return;
    // ...
}
```

### 3. Backward Compatibility

- Existing single challenger scenarios function correctly
- Identical results as before when challengers.length == 1

---

## Benefits

1.  **Accuracy**: Records only actual bond recipients as winners
2.  **Efficiency**: Recorded only once at resolution point
3.  **Simplicity**: Challengers identified by simply filtering gameCreator
4.  **Extensibility**: Allows for future expansion into weight-based distribution

---

## Risk Factors

1.  **FaultDisputeGame Modification Required**: Modifies original Optimism code
2.  **Storage Costs**: Increased costs with many challengers in large games
3.  **Unbounded Array Growth**: Per-game array size growth (although games are one-time use)
