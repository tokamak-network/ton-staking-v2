---
id: functions-events
sidebar_position: 11
---

# Event List

Complete list of events emitted by TON Staking V3 contracts.

## SeigManager Events

```solidity
// V3 seigniorage distribution event
event V3SeigniorageDistributed(
    uint256 totalSeigniorage,
    uint256 l2MaxAllocation,
    uint256 totalDistributed,
    uint256 daoAmount,
    uint256 validatorPoolAmount
);

// Eligibility status change event
event EligibilityChanged(
    address indexed layer2,
    bool eligible,
    uint256 bridgedTON,
    uint256 effectiveBridgedTON
);

// V3 migration completion event
event V3MigrationCompleted(
    uint256 blockNumber,
    uint256 totalMigratedL2s
);

// Detailed seigniorage distribution event (V2 compatible)
event SeigGiven2(
    address indexed layer2,
    uint256 totalSeig,
    uint256 stakedSeig,
    uint256 unstakedSeig,
    uint256 powertonSeig,
    uint256 daoSeig,
    uint256 pseig,
    uint256 l2TotalSeigs,
    uint256 layer2Seigs
);

// Auto claim on eligibility loss
event AutoClaimBeforeEligibilityLoss(
    address indexed layer2,
    uint256 claimedAmount
);
```

---

## RAT Events

```solidity
// Validator registration event
event ValidatorRegistered(
    address indexed validator,
    address indexed systemConfig,
    uint256 depositAmount,
    uint256 registrationId
);

// Validator deactivation event
event ValidatorDeactivated(
    address indexed validator,
    address indexed systemConfig,
    uint256 returnedAmount
);

// RAT test trigger event
event AttentionTestTriggered(
    bytes32 indexed testId,
    address indexed validator,
    address indexed systemConfig,
    address gameAddress,
    uint32 batchIndex,
    uint256 deadline
);

// Evidence submission event
event EvidenceSubmitted(
    bytes32 indexed testId,
    address indexed validator,
    address indexed systemConfig,
    uint32 batchIndex
);

// Validator slashing event
event ValidatorSlashed(
    bytes32 indexed testId,
    address indexed validator,
    address indexed systemConfig,
    uint256 slashedAmount,
    bool removedFromSet
);

// Collateral restoration event (on challenge win)
event BondRestored(
    bytes32 indexed testId,
    address indexed validator,
    address indexed systemConfig,
    uint256 restoredAmount
);

// Validator reactivation event
event ValidatorReactivated(
    address indexed validator,
    address indexed systemConfig,
    uint256 currentCollateral
);
```

---

## ValidatorReward Events

```solidity
// L2-specific validator reward distribution event (summary)
event L2RewardDistributed(
    address indexed systemConfig,
    uint256 totalAmount,           // Total distribution amount
    uint256 activeValidatorCount,  // Active validator count
    uint256 perValidator           // Per-validator distribution amount
);

// Per-validator reward distribution event (occurs at claim time)
event ValidatorRewardReceived(
    address indexed validator,
    address indexed systemConfig,
    uint256 amount
);

// Event when no validators, reward goes to DAO
event RewardToDAO(
    address indexed systemConfig,
    uint256 amount
);

// Validator reward claim event
event RewardsClaimed(
    address indexed validator,
    uint256 amount
);

// Validator L2 registration event
event ValidatorRegisteredToL2(
    address indexed validator,
    address indexed systemConfig,
    uint256 initialDebt
);
```

---

## Sequencer Slashing Event

```solidity
// Sequencer slashing event
event SequencerSlashed(
    address indexed layer2,
    address indexed gameAddress,
    uint256 slashedAmount,
    address challenger,
    uint256 challengerReward
);
```

---

## L1BridgeRegistry Events

```solidity
// Rollup registration event
event RollupRegistered(
    address indexed rollupConfig,
    uint8 rollupType,
    address l2TON,
    string name
);

// Rollup type upgrade event
event RollupTypeUpgraded(
    address indexed rollupConfig,
    uint8 oldType,
    uint8 newType
);

// Seigniorage rejection event
event RejectedCandidateAddOn(
    address indexed rollupConfig
);

// Seigniorage restoration event
event RestoredCandidateAddOn(
    address indexed rollupConfig,
    bool rejectedL2Deposit
);
```

---

## Event Usage Patterns

### Tracking L2-Specific Validator Rewards

To track validator rewards by L2, subscribe to `ValidatorRewardReceived` events:

```javascript
// Listen for validator rewards by L2
validatorReward.on("ValidatorRewardReceived", (validator, systemConfig, amount) => {
    console.log(`Validator ${validator} received ${amount} from L2 ${systemConfig}`);
});
```

### Monitoring Eligibility Changes

```javascript
// Monitor L2 eligibility status
seigManager.on("EligibilityChanged", (layer2, eligible, bridgedTON, effectiveBridgedTON) => {
    console.log(`L2 ${layer2} eligibility: ${eligible}`);
    console.log(`Bridged TON: ${bridgedTON}, Effective: ${effectiveBridgedTON}`);
});
```

### Tracking RAT Test Lifecycle

```javascript
// Monitor RAT test lifecycle
rat.on("AttentionTestTriggered", (testId, validator, systemConfig, gameAddress, batchIndex, deadline) => {
    console.log(`RAT test ${testId} triggered for validator ${validator}`);
});

rat.on("EvidenceSubmitted", (testId, validator, systemConfig, batchIndex) => {
    console.log(`Evidence submitted for test ${testId}`);
});

rat.on("BondRestored", (testId, validator, systemConfig, restoredAmount) => {
    console.log(`Bond restored for validator ${validator}: ${restoredAmount}`);
});
```
