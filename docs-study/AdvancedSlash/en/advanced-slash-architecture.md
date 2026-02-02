# Advanced Slash System Architecture

> **Date**: 2026-02-02  
> **Version**: 1.0  
> **Status**: Design Complete / Implementation in Progress

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [System Architecture](#system-architecture)
3. [Core Components](#core-components)
4. [Data Flow](#data-flow)
5. [Implementation Details](#implementation-details)
6. [Deployment Pipeline](#deployment-pipeline)
7. [Security Considerations](#security-considerations)
8. [Future Enhancements](#future-enhancements)

---

## Overview

### Purpose

The Advanced Slash system integrates the Optimism Fault Proof mechanism with TON Staking V3 to **slash Operators who submit invalid L2 Output Proposals and pull rewards for all participants who successfully challenge them.**

### Core Objectives

1. **Fairness**: Provide equal rewards to all winning Challengers.
2. **Transparency**: All winners are traceable on-chain.
3. **Efficiency**: Distribute rewards to multiple participants with minimal gas costs.
4. **Scalability**: Expandable to weight-based reward systems in the future.

### Limitations of the Existing System

```
Existing Structure (Single Challenger):
┌─────────────────────────────────────────────────────┐
│ Layer2Manager_Slashing.slashingCandidate()         │
│   ↓                                                 │
│ _getWinningChallenger() → claimData(0).counteredBy │
│   ↓                                                 │
│ DepositManager.slash(challenger) → Single Reward    │
└─────────────────────────────────────────────────────┘

Issues:
- Only the first counter is recorded.
- Subsequent Challengers received no reward.
- Unfair incentive structure.
```

---

## System Architecture

### Overall Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         L1 (Ethereum)                               │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │              Optimism Dispute System                         │ │
│  │                                                              │ │
│  │  ┌────────────────────┐      ┌──────────────────────────┐  │ │
│  │  │DisputeGameFactory  │─────▶│  FaultDisputeGame        │  │ │
│  │  │                    │      │  ┌────────────────────┐  │  │ │
│  │  │ - create()         │      │  │ resolveClaim()     │  │  │ │
│  │  │ - setWCT()         │      │  │   ↓                │  │  │ │
│  │  └────────────────────┘      │  │ _distributeBond()  │  │  │ │
│  │           │                  │  │   ↓                │  │  │ │
│  │           │ initialize       │  │ _recordWinning     │  │  │ │
│  │           │                  │  │   Challenger()     │  │  │ │
│  │           ▼                  │  └────────────────────┘  │  │ │
│  │  ┌────────────────────┐      │           │              │  │ │
│  │  │WinningChallenger   │◀─────┼───────────┘              │  │ │
│  │  │Tracker             │      │                          │  │ │
│  │  │                    │      │  - winningChallenger     │  │ │
│  │  │ - recordWinner()   │      │    Tracker (address)     │  │ │
│  │  │ - getWinning       │      │                          │  │ │
│  │  │   Challengers()    │      └──────────────────────────┘  │ │
│  │  └────────────────────┘                                    │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │              TON Staking V3 System                       │ │
│  │                                                          │ │
│  │  ┌────────────────────┐      ┌──────────────────────┐  │ │
│  │  │Layer2Manager       │      │DepositManager        │  │ │
│  │  │_Slashing           │      │_Slashing             │  │ │
│  │  │                    │      │                      │  │ │
│  │  │ slashingCandidate()│─────▶│ slash()              │  │ │
│  │  │   ↓                │      │   ↓                  │  │ │
│  │  │ _getWinning        │      │ _distributeRewards() │  │ │
│  │  │   Challengers()    │      │                      │  │ │
│  │  └────────────────────┘      └──────────────────────┘  │ │
│  │           │                           │                 │ │
│  │           │ query                     │ transfer WTON   │ │
│  │           ▼                           ▼                 │ │
│  │  ┌────────────────────┐      ┌──────────────────────┐  │ │
│  │  │FaultDisputeGame    │      │ Challengers          │  │ │
│  │  │.getWinning         │      │ (address[])          │  │ │
│  │  │ Challengers()      │      │                      │  │ │
│  │  └────────────────────┘      └──────────────────────┘  │ │
│  └──────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Layered Structure

```
┌─────────────────────────────────────────────────────┐
│ Layer 4: Application Layer                         │
│ - E2E Tests                                         │
│ - Integration Tests                                 │
│ - Monitoring & Analytics                            │
└─────────────────────────────────────────────────────┘
                        ▲
                        │
┌─────────────────────────────────────────────────────┐
│ Layer 3: Business Logic Layer                      │
│ - Layer2Manager_Slashing                           │
│ - DepositManager_Slashing                          │
│ - SeigManager_Slashing                             │
└─────────────────────────────────────────────────────┘
                        ▲
                        │
┌─────────────────────────────────────────────────────┐
│ Layer 2: Tracking Layer                            │
│ - WinningChallengerTracker                         │
│ - FaultDisputeGame (tracking logic)                │
└─────────────────────────────────────────────────────┘
                        ▲
                        │
┌─────────────────────────────────────────────────────┐
│ Layer 1: Dispute Resolution Layer                  │
│ - DisputeGameFactory                               │
│ - FaultDisputeGame (core logic)                    │
│ - AnchorStateRegistry                              │
└─────────────────────────────────────────────────────┘
```

---

## Core Components

### 1. WinningChallengerTracker

**Role**: Tracks all winning Challengers in each DisputeGame.

```solidity
contract WinningChallengerTracker {
    // game address => challenger address => is winner
    mapping(address => mapping(address => bool)) public isWinner;
    
    // game address => array of winners
    mapping(address => address[]) internal winners;
    
    function recordWinner(
        address game,
        address winner,
        address gameCreator
    ) external;
    
    function getWinningChallengers(address game) 
        external view returns (address[] memory);
}
```

**Features**:
- Independent winner list management per game.
- Automatic filtering of gameCreator (Proposer).
- Duplication prevention mechanism.
- Gas-efficient view functions.

### 2. FaultDisputeGame (Modified)

**Role**: Records winners at the time of bond distribution.

```solidity
contract FaultDisputeGame {
    address public winningChallengerTracker;
    
    function initialize(
        address _rat,
        address _winningChallengerTracker
    ) public payable {
        // ...
        winningChallengerTracker = _winningChallengerTracker;
    }
    
    function _recordWinningChallenger(address recipient) internal {
        if (winningChallengerTracker != address(0)) {
            IWinningChallengerTracker(winningChallengerTracker)
                .recordWinner(
                    address(this),
                    recipient,
                    gameCreator()
                );
        }
    }
    
    function resolveClaim(...) external {
        // ...
        _distributeBond(recipient, claim);
        _recordWinningChallenger(recipient);  // Added
        // ...
    }
}
```

**Recording Points** (3 locations):
1. **Childless claim resolution** (Line ~846)
2. **L2 block number challenge** (Line ~913)
3. **General subgame resolution** (Line ~921)

### 3. DisputeGameFactory (Modified)

**Role**: Manages WinningChallengerTracker address and game initialization.

```solidity
contract DisputeGameFactory {
    address public winningChallengerTracker;
    
    function setWinningChallengerTracker(address _tracker) 
        external onlyOwner {
        winningChallengerTracker = _tracker;
    }
    
    function create(...) external payable returns (IDisputeGame) {
        // ...
        if (gameType == CANNON && 
            (rat != address(0) || winningChallengerTracker != address(0))) {
            IInitializable(proxy_).initialize{value: msg.value}(
                rat,
                winningChallengerTracker
            );
        }
        // ...
    }
}
```

### 4. Layer2Manager_Slashing (Modified)

**Role**: Retrieves winner lists and executes slashing.

```solidity
contract Layer2Manager_Slashing {
    function _getWinningChallengers(address disputeGame) 
        internal view returns (address[] memory) {
        return IFaultDisputeGame(disputeGame).getWinningChallengers();
    }
    
    function slashingCandidate(...) external {
        // Validation logic
        address[] memory challengers = _getWinningChallengers(_disputeGame);
        require(challengers.length > 0, "no winning challengers");
        
        // Execute Slashing
        IIDepositManager(depositManager).slash(
            candidateAddOn,
            operatorManager,
            challengers  // Pass multiple addresses
        );
    }
}
```

### 5. DepositManager_Slashing (Modified)

**Role**: Executes slashing and distributes rewards equally.

```solidity
contract DepositManager_Slashing {
    function slash(
        address layer2,
        address operator,
        address[] calldata challengers
    ) external onlyLayer2Manager returns (bool) {
        // Execute Slashing
        uint256 totalSlashed = ISeigManager(seigManager)
            .onSlash(layer2, operator);
        
        // Calculate Rewards
        uint256 rewardAmount = (totalSlashed * slashingRewardRate) / 10000;
        
        // Equal Distribution
        if (rewardAmount > 0) {
            _distributeRewards(layer2, challengers, rewardAmount);
        }
        
        return true;
    }
    
    function _distributeRewards(
        address layer2,
        address[] calldata challengers,
        uint256 totalReward
    ) internal {
        uint256 rewardPerChallenger = totalReward / challengers.length;
        uint256 remainder = totalReward % challengers.length;
        
        for (uint256 i = 0; i < challengers.length; i++) {
            uint256 amount = rewardPerChallenger;
            if (i == 0) amount += remainder;  // Remainder goes to the first
            
            IERC20(wton).safeTransfer(challengers[i], amount);
            emit ChallengerRewarded(layer2, challengers[i], amount);
        }
    }
}
```

---

## Data Flow

### 1. Game Creation and Initialization

```
Proposer
   │
   ▼
DisputeGameFactory.create(gameType, rootClaim, extraData)
   │
   ├─ Clone FaultDisputeGame implementation
   │
   ├─ IInitializable.initialize(rat, winningChallengerTracker)
   │     │
   │     └─▶ FaultDisputeGame.winningChallengerTracker = _tracker
   │
   └─ Return game proxy address
```

### 2. Challenge and Resolution

```
Challenger A, B, C
   │
   ├─▶ FaultDisputeGame.move() / attack() / defend()
   │
   ▼
FaultDisputeGame.resolveClaim()
   │
   ├─ Determine winner (recipient)
   │
   ├─ _distributeBond(recipient, claim)
   │
   └─ _recordWinningChallenger(recipient)
         │
         └─▶ WinningChallengerTracker.recordWinner(game, recipient, gameCreator)
               │
               ├─ Filter out gameCreator
               ├─ Check duplicate
               └─ winners[game].push(recipient)
```

### 3. Slashing and Reward Distribution

```
Anyone
   │
   ▼
Layer2Manager_Slashing.slashingCandidate(...)
   │
   ├─ Verify game status (CHALLENGER_WINS)
   │
   ├─ address[] challengers = _getWinningChallengers(disputeGame)
   │     │
   │     └─▶ FaultDisputeGame.getWinningChallengers()
   │           │
   │           └─▶ WinningChallengerTracker.getWinningChallengers(game)
   │
   └─ DepositManager.slash(layer2, operator, challengers)
         │
         ├─ SeigManager.onSlash() → totalSlashed
         │
         ├─ rewardAmount = totalSlashed * rate / 10000
         │
         └─ _distributeRewards(challengers, rewardAmount)
               │
               └─ For each challenger:
                     WTON.transfer(challenger, amount)
```

---

## Implementation Details

### Phase 1: Tracking Layer (Complete ✅)

**Implementation Files**:
- `src/dispute/WinningChallengerTracker.sol`
- `src/dispute/IWinningChallengerTracker.sol`

**Core Logic**:
```solidity
function recordWinner(
    address game,
    address winner,
    address gameCreator
) external {
    require(msg.sender == game, "only game can record");
    require(winner != gameCreator, "proposer cannot be winner");
    
    if (isWinner[game][winner]) return;  // Duplication check
    
    isWinner[game][winner] = true;
    winners[game].push(winner);
    
    emit WinnerRecorded(game, winner);
}
```

### Phase 2: Integration Layer (Complete ✅)

**DisputeGameFactory Integration**:
```solidity
// State Variable
address public winningChallengerTracker;

// Setter
function setWinningChallengerTracker(address _tracker) external onlyOwner {
    winningChallengerTracker = _tracker;
}

// create() Modified
if (gameType.raw() == GameTypes.CANNON.raw() && 
    (rat != address(0) || winningChallengerTracker != address(0))) {
    IInitializable(proxy_).initialize{value: msg.value}(
        rat,
        winningChallengerTracker
    );
}
```

**FaultDisputeGame Integration**:
```solidity
// State Variable
address public winningChallengerTracker;

// Initialization
function initialize(address _rat, address _winningChallengerTracker) 
    public payable {
    _initialize(_rat, _winningChallengerTracker);
}

function _initialize(address _rat, address _winningChallengerTracker) 
    internal {
    // ...
    if (_winningChallengerTracker != address(0)) {
        winningChallengerTracker = _winningChallengerTracker;
    }
}

// Recording Logic
function _recordWinningChallenger(address recipient) internal {
    if (winningChallengerTracker != address(0)) {
        IWinningChallengerTracker(winningChallengerTracker)
            .recordWinner(address(this), recipient, gameCreator());
    }
}
```

### Phase 3: Slashing Layer (In Progress 🔄)

**Layer2Manager_Slashing**:
```solidity
// Previous: Returns single address
function _getWinningChallenger(address disputeGame) 
    internal view returns (address)

// Changed: Returns array
function _getWinningChallengers(address disputeGame) 
    internal view returns (address[] memory)
```

**DepositManager_Slashing**:
```solidity
// Previous: Single challenger
function slash(address layer2, address operator, address challenger)

// Changed: Multiple challengers
function slash(address layer2, address operator, address[] calldata challengers)
```

---

## Deployment Pipeline

### 1. Solidity Compilation

```bash
cd lib/optimism/packages/contracts-bedrock
forge build --skip test
```

**Optimization Settings** (`foundry.toml`):
```toml
[profile.default.optimizer_details.yul_details]
optimizerSteps = "..."

[[profile.default.optimizer_details.yul_details.optimizer_runs]]
src = "src/dispute/FaultDisputeGame.sol"
runs = 200  # Decrease code size (24KB → 22.2KB)
```

### 2. Go Pipeline

**ChainIntent Structure**:
```go
// op-deployer/pkg/deployer/state/chain_intent.go
type ChainProofParams struct {
    RatAddress                      common.Address
    WinningChallengerTrackerAddress common.Address  // Added
}
```

**DeployOPChainInput**:
```go
// op-deployer/pkg/deployer/opcm/opchain.go
type DeployOPChainInput struct {
    // ...
    RatAddress                      common.Address
    WinningChallengerTrackerAddress common.Address  // Added
}
```

**Pipeline Passing**:
```go
// op-deployer/pkg/deployer/pipeline/opchain.go
func makeDCI(...) opcm.DeployOPChainInput {
    return opcm.DeployOPChainInput{
        // ...
        WinningChallengerTrackerAddress: intent.WinningChallengerTrackerAddress,
    }
}
```

### 3. Devnet Allocs Generation

```bash
cd lib/optimism
just devnet-allocs
```

**GlobalDeployOverrides** (`op-chain-ops/cmd/devnet-allocs/main.go`):
```go
GlobalDeployOverrides: map[string]any{
    "deployWinningChallengerTracker": true,
}
```

### 4. E2E Test Environment

```go
// op-e2e/system/ton_system.go
func (sys *TONSystem) DeployWinningChallengerTracker() {
    trackerAddr, _, tracker, err := bindings.DeployWinningChallengerTracker(
        sys.Cfg.Secrets.Deployer,
        sys.Clients["l1"],
    )
    // ...
    sys.WinningChallengerTracker = tracker
}
```

---

## Security Considerations

### 1. Access Control

```solidity
// WinningChallengerTracker
function recordWinner(...) external {
    require(msg.sender == game, "only game can record");
    // ✅ Only DisputeGame can call
}

// DisputeGameFactory
function setWinningChallengerTracker(...) external onlyOwner {
    // ✅ Only Owner can set
}
```

### 2. DoS Prevention

```solidity
// Maximum number of winning challengers (optional)
uint256 public constant MAX_WINNING_CHALLENGERS = 100;

function _recordWinningChallenger(address recipient) internal {
    if (winners[game].length >= MAX_WINNING_CHALLENGERS) return;
    // ...
}
```

### 3. Reentrancy Prevention

```solidity
// DepositManager_Slashing
function _distributeRewards(...) internal {
    // ✅ State change complete before external call
    // ✅ Use SafeERC20.safeTransfer
    for (uint256 i = 0; i < challengers.length; i++) {
        IERC20(wton).safeTransfer(challengers[i], amount);
    }
}
```

### 4. Duplication Prevention

```solidity
// WinningChallengerTracker
mapping(address => mapping(address => bool)) public isWinner;

function recordWinner(...) external {
    if (isWinner[game][winner]) return;  // ✅ Duplicate check
    // ...
}
```

---

## Future Enhancements

### 1. Weight-based Rewards

```solidity
struct ChallengerContribution {
    address challenger;
    uint256 bondAmount;      // Bond amount contributed
    uint256 moveCount;       // Number of moves performed
    uint256 timestamp;       // Timestamp of first participation
}

function _distributeRewards(...) internal {
    uint256 totalWeight = calculateTotalWeight(contributions);
    
    for (uint256 i = 0; i < challengers.length; i++) {
        uint256 weight = calculateWeight(contributions[i]);
        uint256 amount = (totalReward * weight) / totalWeight;
        // ...
    }
}
```

### 2. Time-based Incentives

```solidity
// Bonus for early participants
function calculateEarlyBirdBonus(uint256 timestamp) internal view returns (uint256) {
    uint256 elapsed = block.timestamp - gameCreatedAt;
    if (elapsed < 1 hours) return 120;  // 20% bonus
    if (elapsed < 6 hours) return 110;  // 10% bonus
    return 100;  // No bonus
}
```

### 3. Multi-chain Support

```solidity
// Cross-chain challenger tracking
interface ICrossChainTracker {
    function recordWinnerCrossChain(
        uint256 chainId,
        address game,
        address winner
    ) external;
}
```

### 4. Analytics & Monitoring

```solidity
event DetailedWinnerRecorded(
    address indexed game,
    address indexed winner,
    uint256 bondReceived,
    uint256 moveCount,
    uint256 timestamp
);

function getGameStatistics(address game) external view returns (
    uint256 totalChallengers,
    uint256 totalBondDistributed,
    uint256 averageReward
);
```

---

## References

### Documents
- [Winning Challenger Tracking Plan](../winning-challenger-tracking-plan.md)
- [WinningChallengerTracker Integration Implementation](../e2e-test/winning-challenger-tracker-integration.md)
- [Integration Issues Log](../e2e-test/integration-issues-log.md)

### Code
- `src/dispute/WinningChallengerTracker.sol`
- `src/dispute/FaultDisputeGame.sol`
- `src/layer2/Layer2Manager_Slashing.sol`
- `src/stake/managers/DepositManager_Slashing.sol`

### Tests
- `test/dispute/WinningChallengerTracker.t.sol`
- `test/v3/v3mode/BasicSlashing/SlashingMultiChallenger.t.sol`
- `op-e2e/system/ton_system.go`

---

## Version History

| Version | Date | Changes |
|------|------|-----------|
| 1.0 | 2026-02-02 | Initial architecture document creation |
| 0.9 | 2026-02-01 | WinningChallengerTracker integration complete |
| 0.5 | 2026-01-30 | Initial design and project planning |
