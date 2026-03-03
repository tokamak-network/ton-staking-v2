# 3. Core Contract Changes Details

## 3.1 WinningChallengerTracker (New)

**Path**: `lib/optimism/packages/contracts-bedrock/src/dispute/WinningChallengerTracker.sol`
**Interface**: `lib/optimism/packages/contracts-bedrock/src/dispute/IWinningChallengerTracker.sol`

An external contract separated to address the **EVM 24KB limit** for `FaultDisputeGame`. Size: 1,203 bytes.

```solidity
contract WinningChallengerTracker {
    // game address => challenger address => is winner
    mapping(address => mapping(address => bool)) private _isWinner;
    // game address => array of winners
    mapping(address => address[]) private _winners;

    function recordWinner(address game, address winner, address gameCreator) external {
        require(msg.sender == game, "only game can record");  // Access Control
        if (winner == gameCreator) return;                     // Exclude Proposer
        if (_isWinner[game][winner]) return;                   // Prevent Duplicates
        _isWinner[game][winner] = true;
        _winners[game].push(winner);
    }

    function getWinningChallengers(address game) external view returns (address[] memory);
    function getWinningChallengersCount(address game) external view returns (uint256);
    function isWinningChallenger(address game, address challenger) external view returns (bool);
}
```

---

## 3.2 FaultDisputeGame (Modified)

**Path**: `lib/optimism/packages/contracts-bedrock/src/dispute/FaultDisputeGame.sol`
**Size after modification**: 24,102 bytes (Margin +474 bytes)

### Added State Variables

```solidity
address public winningChallengerTracker;
```

### Modified initialize Function

```solidity
// New overload added
function initialize(address _rat, address _winningChallengerTracker) public payable virtual;
function initialize(address _rat) public payable virtual;  // Existing maintained
function initialize() public payable virtual;               // Existing maintained
```

### Added Internal Functions

```solidity
function _recordWinningChallenger(address _recipient) internal {
    if (winningChallengerTracker != address(0)) {
        try IWinningChallengerTracker(winningChallengerTracker).recordWinner(
            address(this), _recipient, gameCreator()
        ) {} catch {}  // Try-catch ensures external call failure doesn't affect game logic
    }
}
```

### Call Locations within resolveClaim (3 places)

| Location | Line | Scenario |
|----------|------|----------|
| Case 1 | ~800 | Resolving claim with no children |
| Case 2 | ~864 | Challenging L2 block number |
| Case 3 | ~870 | Resolving regular subgame |

Calls `_recordWinningChallenger(recipient)` right after `_distributeBond(recipient, claim)`.

> **Note**: View functions like `getWinningChallengers()` were **removed** from `FaultDisputeGame` for size optimization. The `WinningChallengerTracker` contract must be queried directly from outside.

---

## 3.3 DisputeGameFactory (Modified)

**Path**: `lib/optimism/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol`

```solidity
// Added state variable
address public winningChallengerTracker;

// Added Setter (onlyOwner)
function setWinningChallengerTracker(address _tracker) external onlyOwner {
    winningChallengerTracker = _tracker;
}

// create() modified - Passes tracker address when creating CANNON type games
if (gameType.raw() == GameTypes.CANNON.raw() &&
    (rat != address(0) || winningChallengerTracker != address(0))) {
    IInitializable(proxy_).initialize{value: msg.value}(rat, winningChallengerTracker);
}
```

---

## 3.4 Layer2Manager_Slashing (Modified)

**Path**: `src/layer2/Layer2Manager_Slashing.sol`

### Function Changes

```solidity
// Before: Returns a single address
function _getWinningChallenger(address disputeGame) internal view returns (address)

// After: Returns an array
function _getWinningChallengers(address disputeGame) internal view returns (address[] memory) {
    return IFaultDisputeGame(disputeGame).getWinningChallengers();
}
```

### Event Changes

```solidity
// Before
event CandidateSlashed(address indexed operator, address indexed challenger, address disputeGame);
// After
event CandidateSlashed(address indexed operator, uint256 challengerCount, address disputeGame);
```

### slashingCandidate Modifications

```solidity
address[] memory challengers = _getWinningChallengers(_disputeGame);
require(challengers.length > 0, "no winning challengers");

IIDepositManager(depositManager).slash(
    candidateAddOn, operatorManager, challengers  // Passing address[]
);
```

---

## 3.5 DepositManager_Slashing (Modified)

**Path**: `src/stake/managers/DepositManager_Slashing.sol`

### slash Function Signature Changes

```solidity
// Before
function slash(address layer2, address operator, address challenger) external ...
// After
function slash(address layer2, address operator, address[] calldata challengers) external ...
```

### Added Reward Distribution Function

```solidity
function _distributeRewards(
    address layer2,
    address[] calldata challengers,
    uint256 totalReward
) internal {
    uint256 rewardPerChallenger = totalReward / challengers.length;
    uint256 remainder = totalReward % challengers.length;

    for (uint256 i = 0; i < challengers.length; i++) {
        uint256 amount = rewardPerChallenger;
        if (i == 0) amount += remainder;  // The remainder goes to the first challenger

        IERC20(_wton).safeTransfer(challengers[i], amount);
        emit ChallengerRewarded(layer2, challengers[i], amount);
    }
}
```

---

## 3.6 Interface Changes Summary

| File | Changes |
|------|---------|
| `src/layer2/interfaces/IFaultDisputeGame.sol` | Added `getWinningChallengers()`, `getWinningChallengersCount()`, `isWinningChallenger()` |
| `src/stake/interfaces/IIDepositManager.sol` | `slash()` signature: `address → address[] calldata` |
| `lib/optimism/.../interfaces/dispute/IInitializable.sol` | Added `initialize(address, address)` signature |
| `lib/optimism/.../interfaces/dispute/IDisputeGameFactory.sol` | Added `winningChallengerTracker()`, `setWinningChallengerTracker()` |

---

Next: [04-reward-logic.md](./04-reward-logic.md)
