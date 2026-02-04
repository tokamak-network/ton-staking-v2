# Delegate Staking

Delegate Staking implementation for Tokamak Network V3.

## Overview

In Tokamak Network V3, the seigniorage distribution basis changes to **Bridged TON**. Since regular users can no longer stake directly to receive rewards, this system provides **a structure where users can delegate TON to sequencers and indirectly receive seigniorage rewards**.

### Key Features

- **Staking**: Users delegate TON to sequencers
- **Unstaking**: TON withdrawal after unbonding period
- **Redelegation**: Delegation transfer between sequencers (instant processing)
- **Reward Distribution**: WTON reward distribution based on MasterChef pattern
- **Commission**: Sequencers collect a percentage of rewards as fees (7-day timelock)
- **Auto Trigger**: Automatic seigniorage distribution based on Keeper pattern
- **Emergency Exit**: Emergency Exit mechanism for L2 failures
- **Upgrade**: UUPS proxy pattern support

## Version History

| Version | Major Changes |
|---------|--------------|
| v1.3.0 | Low issue fixes (code quality improvements, NatSpec, constants) |
| v1.2.0 | Medium issue fixes (batch limits, event additions, O(1) deletion) |
| v1.1.0 | High issue fixes (commission timelock, flash loan protection, minimum stake) |
| v1.0.0 | Critical issue fixes (Pausable, Upgradeable, rescueTokens security) |

## Contract Structure

### V3 Integrated Version (Recommended)

```
+---------------------------------------------------------------------+
|                           L1 (Ethereum)                              |
|                                                                      |
|  +--------------+     +---------------------+     +--------------+   |
|  | SeigManager  |---->|  DelegateStakingV3  |<----| DelegateTrigger| |
|  |    (V3)      |     |   (Upgradeable)     |     |   (Keeper)    |  |
|  +--------------+     +----------+----------+     +--------------+   |
|                                  |                                   |
|  +--------------+                |                                   |
|  |OperatorMgr   |<---------------+                                   |
|  | (Per L2)     |                                                    |
|  +--------------+                                                    |
|                                                                      |
|   User --TON--> DelegateStakingV3 <--WTON-- OperatorManager          |
|     ^                   |                                            |
|     |                   |                                            |
|     +---- WTON ---------+ (rewards)                                  |
|                                                                      |
+---------------------------------------------------------------------+
```

### Contract List

| Contract | Description | Status |
|----------|-------------|--------|
| `DelegateStakingV3Upgradeable.sol` | V3 integrated UUPS upgradeable version **(Recommended)** | v1.3.0 |
| `DelegateStakingV3.sol` | V3 integrated standard version | Complete |
| `DelegateTrigger.sol` | Automatic seigniorage trigger | Complete |
| `DelegateStakingMVP.sol` | MVP version (manual distribution) | Complete |

### Token Units

| Token | Decimals | Usage |
|-------|----------|-------|
| TON | 18 decimals | Staking |
| WTON | 27 decimals (RAY) | Rewards |

## Technology Stack

### Smart Contracts
- Solidity ^0.8.24
- OpenZeppelin Contracts v5 (Upgradeable)
- Foundry (Development & Testing)
- UUPS Proxy Pattern

### V3 Dependencies
- ton-staking-v2 (ton-staking-v3/dev branch)

## Installation

```bash
# Clone repository
git clone https://github.com/tokamak-network/delegate-staking.git
cd delegate-staking

# Initialize Git submodules (ton-staking-v2)
git submodule update --init --recursive

# Install Foundry dependencies
forge install
```

## Environment Setup

Copy `.env.example` to create a `.env` file:

```bash
cp .env.example .env
```

Required environment variables:

```env
# RPC URLs
MAINNET_RPC_URL=
SEPOLIA_RPC_URL=

# Private Keys (for testing)
PRIVATE_KEY=

# Etherscan (for verification)
ETHERSCAN_API_KEY=
```

## Development

### Build Contracts

```bash
forge build
```

### Testing

```bash
# Full test suite (300 tests)
forge test

# Upgradeable version tests
forge test --match-contract DelegateStakingV3Upgradeable -vvv

# V3 tests
forge test --match-contract DelegateStakingV3Test -vvv

# Gas report
forge test --gas-report

# Coverage (99.67%)
forge coverage
```

### Local Deployment

```bash
# Run Anvil (separate terminal)
anvil

# Local V3 deployment
forge script script/DeployLocalV3.s.sol --rpc-url local --broadcast
```

## Smart Contract API

### DelegateStakingV3Upgradeable (Recommended)

#### Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `MAX_COMMISSION` | 3000 (30%) | Maximum commission |
| `COMMISSION_TIMELOCK` | 7 days | Commission change timelock |
| `STAKE_COOLDOWN` | 12 seconds | Flash loan protection cooldown |
| `DEFAULT_MIN_STAKE` | 100 TON | Default minimum stake |
| `MAX_BATCH_SIZE` | 50 | Maximum batch operation size |
| `MIN_UNBONDING_PERIOD` | 1 day | Minimum unbonding period |
| `MAX_UNBONDING_PERIOD` | 30 days | Maximum unbonding period |
| `MIN_EMERGENCY_COOLDOWN` | 1 hour | Minimum emergency cooldown |
| `MAX_EMERGENCY_COOLDOWN` | 14 days | Maximum emergency cooldown |
| `DEFAULT_EMERGENCY_COOLDOWN` | 3 days | Default emergency cooldown |
| `RAY` | 1e27 | WTON precision |

#### Sequencer Functions

| Function | Description |
|----------|-------------|
| `registerSequencer(layer2, operatorManager, commission)` | Register sequencer (V3 integration) |
| `deregisterSequencer()` | Deregister sequencer |
| `requestCommissionUpdate(newCommission)` | Request commission change (7-day timelock) |
| `applyCommissionUpdate()` | Apply commission change |
| `cancelCommissionUpdate()` | Cancel commission change |
| `setAutoTrigger(enabled)` | Enable auto trigger |
| `receiveReward(amount)` | Receive rewards manually |
| `claimCommission()` | Withdraw commission |

#### Delegator Functions

| Function | Description |
|----------|-------------|
| `stake(sequencer, amount)` | Stake TON (minimum 100 TON) |
| `unstake(sequencer, amount)` | Request unstaking |
| `withdraw(sequencer)` | Withdraw after unbonding |
| `claimRewards(sequencer)` | Claim rewards (12-second cooldown) |
| `redelegate(from, to, amount)` | Transfer delegation between sequencers |

#### Trigger Functions

| Function | Description |
|----------|-------------|
| `triggerSeigniorage(sequencer)` | Trigger seigniorage |
| `batchTriggerSeigniorage(sequencers)` | Batch trigger (max 50) |

#### Emergency Functions

| Function | Description |
|----------|-------------|
| `activateEmergency(layer2)` | Activate emergency mode |
| `deactivateEmergency(layer2)` | Deactivate emergency mode |
| `emergencyWithdraw(sequencer)` | Emergency withdrawal (including rewards) |

#### Admin Functions

| Function | Description |
|----------|-------------|
| `pause()` / `unpause()` | Pause contract |
| `setUnbondingPeriod(period)` | Set unbonding period |
| `setSeigManager(address)` | Set SeigManager address |
| `setLayer2Manager(address)` | Set Layer2Manager address |
| `setDefaultGuardian(address)` | Set default Guardian |
| `setLayer2Guardian(layer2, guardian)` | Set L2-specific Guardian |
| `setEmergencyCooldown(layer2, period)` | Set emergency cooldown |
| `setMinStakeAmount(amount)` | Set minimum stake amount |
| `rescueTokens(token, to, amount)` | Rescue stuck tokens (except TON/WTON) |

#### View Functions

| Function | Returns |
|----------|---------|
| `getStakeInfo(staker, sequencer)` | StakeInfo (amount, rewardDebt, unstakeAmount, unstakeTime) |
| `getSequencerInfo(sequencer)` | SequencerInfo (full sequencer information) |
| `pendingRewards(staker, sequencer)` | Unclaimed WTON rewards |
| `getSequencerList()` | List of registered sequencers |
| `getSequencerCount()` | Number of registered sequencers |
| `getSequencerByLayer2(layer2)` | Sequencer mapped to L2 |
| `getTotalStaked()` | Total staked amount |
| `getPendingCommission(sequencer)` | Pending commission change info |
| `getEmergencyConfig(layer2)` | Emergency configuration info |
| `checkLayer2Eligibility(layer2)` | Check L2 eligibility requirements |
| `estimateSeigniorage(sequencer)` | Estimated seigniorage |
| `version()` | Contract version |

### Events

#### Sequencer Events
```solidity
event SequencerRegistered(address indexed sequencer, address indexed layer2, address indexed operatorManager, uint256 commission);
event SequencerDeregistered(address indexed sequencer);
event CommissionUpdated(address indexed sequencer, uint256 oldCommission, uint256 newCommission);
event CommissionUpdateRequested(address indexed sequencer, uint256 currentCommission, uint256 newCommission, uint256 effectiveTime);
event CommissionUpdateCancelled(address indexed sequencer, uint256 cancelledCommission);
event AutoTriggerToggled(address indexed sequencer, bool enabled);
```

#### Staking Events
```solidity
event Staked(address indexed staker, address indexed sequencer, uint256 amount);
event UnstakeRequested(address indexed staker, address indexed sequencer, uint256 amount, uint256 unlockTime);
event Withdrawn(address indexed staker, address indexed sequencer, uint256 amount);
event Redelegated(address indexed staker, address indexed fromSequencer, address indexed toSequencer, uint256 amount);
```

#### Reward Events
```solidity
event RewardsReceived(address indexed sequencer, uint256 totalAmount, uint256 commission, uint256 distributed);
event RewardsClaimed(address indexed staker, address indexed sequencer, uint256 amount);
event CommissionClaimed(address indexed sequencer, uint256 amount);
event SeigniorageTriggered(address indexed sequencer, uint256 amount, address indexed triggeredBy);
```

#### Emergency Events
```solidity
event EmergencyActivated(address indexed layer2, address indexed activatedBy, uint256 activationTime);
event EmergencyDeactivated(address indexed layer2, address indexed deactivatedBy);
event EmergencyWithdrawn(address indexed staker, address indexed sequencer, uint256 amount);
```

#### Admin Events
```solidity
event UnbondingPeriodUpdated(uint256 oldPeriod, uint256 newPeriod);
event SeigManagerUpdated(address oldManager, address newManager);
event Layer2ManagerUpdated(address oldManager, address newManager);
event DefaultGuardianUpdated(address oldGuardian, address newGuardian);
event Layer2GuardianUpdated(address indexed layer2, address oldGuardian, address newGuardian);
event EmergencyCooldownUpdated(address indexed layer2, uint256 oldCooldown, uint256 newCooldown);
event MinStakeAmountUpdated(uint256 oldAmount, uint256 newAmount);
event TokensRescued(address indexed token, address indexed to, uint256 amount);
```

### Errors

```solidity
// General Errors
error ZeroAddress();
error ZeroAmount();
error InvalidCommission();
error InsufficientBalance();
error Unauthorized();

// Sequencer Errors
error SequencerAlreadyRegistered();
error SequencerNotRegistered();
error Layer2AlreadyRegistered();
error InvalidOperatorManager();
error AutoTriggerDisabled();

// Staking Errors
error NoUnstakeRequest();
error UnstakingPeriodNotElapsed();
error NoPendingRewards();
error BelowMinimumStake();
error StakeCooldownNotElapsed();
error CannotRedelegateToSame();

// Commission Errors
error NoPendingCommission();
error CommissionTimelockNotElapsed();

// Emergency Errors
error EmergencyNotActive();
error EmergencyAlreadyActive();
error EmergencyCooldownNotElapsed();
error NotGuardian();

// Configuration Errors
error UnbondingPeriodOutOfBounds();
error EmergencyCooldownOutOfBounds();
error BatchSizeExceeded();
error CannotRescueStakingTokens();
```

## Security Features

### v1.0.0 (Critical)
- **Pausable**: Contract pause during emergencies
- **UUPS Upgradeable**: Safe upgrade pattern
- **rescueTokens Security**: TON/WTON withdrawal blocked

### v1.1.0 (High)
- **Commission Timelock**: 7-day timelock for commission changes
- **Flash Loan Protection**: 12-second cooldown before claiming rewards
- **Minimum Stake**: Minimum 100 TON staking requirement
- **Emergency Withdraw Rewards**: Rewards included in emergency withdrawal

### v1.2.0 (Medium)
- **Batch Size Limit**: Maximum 50 batch operations
- **O(1) Sequencer Removal**: Swap-and-pop algorithm
- **Unbonding Bounds**: 1-30 day unbonding period limits
- **Admin Events**: Events added to all admin functions

### v1.3.0 (Low)
- **Constants**: Magic numbers converted to constants (BASIS_POINTS, etc.)
- **Specific Errors**: Specific errors like CannotRedelegateToSame
- **Emergency Cooldown Bounds**: 1 hour to 14 days limit
- **Improved NatSpec**: Detailed function documentation

## Usage Examples

### Sequencer Registration

```solidity
// Sequencer registers with V3 integration
staking.registerSequencer(
    layer2Address,
    operatorManagerAddress,
    1000 // 10% commission (basis points)
);

// Enable auto trigger
staking.setAutoTrigger(true);
```

### User Staking

```solidity
// Approve TON
ton.approve(address(staking), 1000 ether);

// Stake (minimum 100 TON)
staking.stake(sequencerAddress, 1000 ether);

// Claim rewards after 12 seconds
staking.claimRewards(sequencerAddress);

// Request unstaking
staking.unstake(sequencerAddress, 500 ether);

// Withdraw after unbonding period
staking.withdraw(sequencerAddress);
```

### Commission Change (7-Day Timelock)

```solidity
// Request commission change
staking.requestCommissionUpdate(2000); // 20%

// Apply after 7 days
staking.applyCommissionUpdate();

// Or cancel
staking.cancelCommissionUpdate();
```

### Emergency Exit

```solidity
// Guardian: Activate emergency mode
staking.activateEmergency(layer2);

// After cooldown (default 3 days), user can withdraw immediately
staking.emergencyWithdraw(sequencer);
```

## Project Structure

```
delegate-staking/
├── contracts/
│   ├── DelegateStakingV3Upgradeable.sol  # UUPS upgradeable version (Recommended)
│   ├── DelegateStakingV3.sol             # V3 integrated standard version
│   ├── DelegateTrigger.sol               # Auto trigger
│   ├── DelegateStakingMVP.sol            # MVP version
│   └── interfaces/
│       ├── IDelegateStakingV3.sol
│       └── IDelegateStakingMVP.sol
├── lib/
│   ├── forge-std/
│   ├── openzeppelin-contracts/
│   ├── openzeppelin-contracts-upgradeable/
│   └── ton-staking-v2/                   # V3 dependency (submodule)
├── script/
│   ├── DeployLocalV3.s.sol               # Local V3 deployment
│   └── InteractV3.s.sol                  # V3 interaction
├── test/
│   ├── DelegateStakingV3Upgradeable.t.sol  # 143 tests
│   ├── DelegateStakingV3.t.sol             # 52 tests
│   ├── DelegateStakingV3Extended.t.sol     # 52 tests
│   ├── DelegateStakingE2E.t.sol            # E2E tests
│   ├── DelegateTriggerE2E.t.sol            # Trigger E2E
│   └── mocks/
│       ├── MockSeigManagerV3.sol
│       ├── MockOperatorManagerV3.sol
│       └── MockLayer2ManagerV3.sol
├── docs/
│   ├── design/                           # Design and requirements
│   │   ├── DESIGN.md
│   │   └── ...
│   ├── testing/                          # Test results
│   │   └── LOCAL-TESTING-RESULTS.md
│   └── guides/                           # Usage guides
│       ├── API.md
│       └── DEPLOYMENT.md
├── foundry.toml
└── README.md
```

## Test Status

| Test Suite | Test Count | Status |
|------------|------------|--------|
| DelegateStakingV3Upgradeable | 143 | All Pass |
| DelegateStakingV3 | 52 | All Pass |
| DelegateStakingV3Extended | 52 | All Pass |
| DelegateStakingE2E | 38 | All Pass |
| DelegateTriggerE2E | 9 | All Pass |
| DelegateStakingMVP | 6 | All Pass |
| **Total** | **300** | All Pass |

**Line Coverage**: 99.67%

## Documentation

Documentation is organized by category in the `docs/` folder. [Documentation Index](../README.md)

### Guides
- [API Documentation](./guides/API.md)
- [Deployment Guide](./guides/DEPLOYMENT.md)

### Design
- [Design Document (Korean)](../design/DESIGN.md)
- [Design Document (English)](./design/DESIGN.md)
- [V3 Integration Discussion Results](./design/v3-discussion-result.md)

### Testing
- [Local Testing Guide](./testing/LOCAL-TESTING.md)
- [Test Results](../testing/LOCAL-TESTING-RESULTS.md)

## License

MIT License

## References

- [Tokamak Economics Whitepaper V3](../design/Tokamak_Economics_Whitepaper_V3.pdf)
- [ton-staking-v2 Repository](https://github.com/tokamak-network/ton-staking-v2)
