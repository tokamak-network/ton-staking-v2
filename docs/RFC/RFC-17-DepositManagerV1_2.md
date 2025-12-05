# RFC: Add WithdrawalRequestCanceled Event to DepositManager

> **Note**: This RFC is discussed in the [tokamak-dao-contracts](https://github.com/tokamak-network/tokamak-dao-contracts) repository, while the implementation is in the [ton-staking-v2](https://github.com/tokamak-network/ton-staking-v2) repository.

## Summary

This RFC proposes adding a `WithdrawalRequestCanceled` event to the `DepositManager` contract to enable accurate tracking of TON circulating supply by distinguishing between "fresh deposits" and "withdrawal cancellations (redeposits)".

## Motivation

Currently, when users cancel their withdrawal requests via `redeposit` or `redepositMulti`, only a `Deposited` event is emitted. This makes it difficult to:
- Accurately calculate net pending withdrawals for liquidity analysis
- Distinguish between new deposits and withdrawal cancellations
- Track the true circulating supply of TON

By adding a `WithdrawalRequestCanceled` event that is emitted alongside `Deposited` when redepositing, we can:
- Enable precise calculation of net pending withdrawals
- Improve on-chain analytics and reporting
- Support better liquidity management decisions

**Related Proposal**: This RFC is based on the original proposal discussion: [Add WithdrawalRequestCanceled Event to Distinguish Redeposits from Fresh Deposits](https://github.com/tokamak-network/tokamak-dao-contracts/discussions/16)

## Proposal

### Contract Changes

Create `DepositManagerV1_2` as an upgraded version of `DepositManager` that:
1. Adds a new `WithdrawalRequestCanceled` event
2. Emits both `Deposited` and `WithdrawalRequestCanceled` events when `redeposit` or `redepositMulti` is called

### Event Definition

```solidity
event WithdrawalRequestCanceled(address indexed layer2, address depositor, uint256 amount);
```

### Implementation Details

- When `redeposit` or `redepositMulti` is called:
  - Both `Deposited` and `WithdrawalRequestCanceled` events are emitted with the same parameters
  - The amount represents the total canceled withdrawal requests
  - This allows downstream systems to track both the deposit and the cancellation

### Upgrade Path

- Deploy `DepositManagerV1_2` as a new implementation
- Register via DAO agenda using `setImplementation2` and `setSelectorImplementations2`
- Only `redeposit` and `redepositMulti` functions will use the new implementation
- All other functions remain unchanged

## Technical Specification

### Contract: DepositManagerV1_2

**Location**: `contracts/stake/managers/DepositManagerV1_2.sol`

**Key Changes**:
- Inherits from `DepositManagerStorage` and `DepositManagerV1_1Storage`
- Adds `WithdrawalRequestCanceled` event
- Modifies `_redeposit` internal function to emit both events

**Function Signatures** (unchanged):
- `redeposit(address layer2) external returns (bool)`
- `redepositMulti(address layer2, uint256 n) external returns (bool)`

### Event Emission Pattern

```solidity
emit Deposited(layer2, msg.sender, accAmount);
emit WithdrawalRequestCanceled(layer2, msg.sender, accAmount);
```

Both events are emitted with identical parameters, allowing:
- `Deposited` event: Tracks the deposit action
- `WithdrawalRequestCanceled` event: Tracks the cancellation of withdrawal requests

## Reference Implementation

### Contract Code

**Repository**: [tokamak-network/ton-staking-v2](https://github.com/tokamak-network/ton-staking-v2)
**Branch**: `rfc-17`
**Full Implementation**: [`contracts/stake/managers/DepositManagerV1_2.sol`](https://github.com/tokamak-network/ton-staking-v2/blob/rfc-17/contracts/stake/managers/DepositManagerV1_2.sol)

### Key Implementation Details

The core change is in the `_redeposit` internal function, where both events are emitted:

```solidity
function _redeposit(address layer2, uint256 i, uint256 n) internal onlyLayer2(layer2) returns (bool) {
    // ... withdrawal request processing logic ...

    // deposit-related storages
    _accStaked[layer2][msg.sender] = _accStaked[layer2][msg.sender] + accAmount;
    _accStakedLayer2[layer2] = _accStakedLayer2[layer2] + accAmount;
    _accStakedAccount[msg.sender] = _accStakedAccount[msg.sender] + accAmount;

    // withdrawal-related storages
    _pendingUnstaked[layer2][msg.sender] = _pendingUnstaked[layer2][msg.sender] - accAmount;
    _pendingUnstakedLayer2[layer2] = _pendingUnstakedLayer2[layer2] - accAmount;
    _pendingUnstakedAccount[msg.sender] = _pendingUnstakedAccount[msg.sender] - accAmount;

    _withdrawalRequestIndex[layer2][msg.sender] += n;

    emit Deposited(layer2, msg.sender, accAmount);

    // add event for withdrawal request canceled
    emit WithdrawalRequestCanceled(layer2, msg.sender, accAmount);

    require(ISeigManager(_seigManager).onDeposit(layer2, msg.sender, accAmount), "fail SeigManager.onDeposit");

    return true;
}
```

### Event Declaration

```solidity
event Deposited(address indexed layer2, address depositor, uint256 amount);
event WithdrawalRequestCanceled(address indexed layer2, address depositor, uint256 amount);
```

### Test Implementation

**Repository**: [tokamak-network/ton-staking-v2](https://github.com/tokamak-network/ton-staking-v2)
**Branch**: `rfc-17`

**Test Files**:
- [`test/deposit-manager-v1-2-standalone.test.ts`](https://github.com/tokamak-network/ton-staking-v2/blob/rfc-17/test/deposit-manager-v1-2-standalone.test.ts) - Standalone tests
- [`test/deposit-manager-v1-2-agenda.test.ts`](https://github.com/tokamak-network/ton-staking-v2/blob/rfc-17/test/deposit-manager-v1-2-agenda.test.ts) - Agenda-based registration tests
- [`test/shared/depositManagerHelpers.ts`](https://github.com/tokamak-network/ton-staking-v2/blob/rfc-17/test/shared/depositManagerHelpers.ts) - Shared helper functions

## Testing

Comprehensive test coverage has been implemented:

### 1. Standalone Tests (`deposit-manager-v1-2-standalone.test.ts`)
- ✅ `WithdrawalRequestCanceled` event emission for `redeposit`
- ✅ Both `Deposited` and `WithdrawalRequestCanceled` events for `redeposit`
- ✅ Both events for `redepositMulti`
- ✅ E2E flow: Deposit -> RequestWithdrawal -> Redeposit
- ✅ Net pending withdrawals tracking

### 2. Agenda-based Registration Tests (`deposit-manager-v1-2-agenda.test.ts`)
- ✅ Full DAO agenda process: creation -> voting -> execution
- ✅ Verification of DepositManagerV1_2 registration
- ✅ Functionality tests after agenda execution

### Test Results
- All tests passing ✅
- Event parameters validated
- Edge cases covered (rounding, multiple withdrawals, etc.)

## Impact Analysis

### Positive Impacts
1. **Improved Analytics**: Better tracking of withdrawal cancellations
2. **Liquidity Management**: Accurate net pending withdrawal calculations
3. **Transparency**: Clear distinction between fresh deposits and redeposits
4. **Backward Compatibility**: Existing functionality remains unchanged

### Risks & Mitigations
1. **Event Log Growth**: Minimal impact as events are already being emitted
2. **Gas Cost**: Negligible increase (~1 event emission per redeposit)
3. **Integration**: Downstream systems can optionally listen to the new event

### Breaking Changes
- ❌ None - This is a non-breaking upgrade
- Existing integrations continue to work
- New event is additive only

## Deployment Plan

1. **Development**: ✅ Complete
   - Contract implementation
   - Comprehensive test coverage
   - Helper function modularization

2. **Testing**: ✅ Complete
   - Unit tests
   - Integration tests
   - Agenda-based registration tests

3. **DAO Proposal**: Pending
   - Create agenda to register DepositManagerV1_2
   - Set implementation via `setImplementation2`
   - Set selector implementations for `redeposit` and `redepositMulti`

4. **Execution**: Pending
   - DAO voting and execution
   - Verification of registration

## Security Considerations

- **No Security Impact**: This is a non-breaking upgrade that only adds event emissions
- **Event-only Change**: No state changes or logic modifications
- **Audit Status**: Code follows existing patterns and has comprehensive test coverage

## References

### Discussions & Proposals
- **RFC Discussion**: [tokamak-dao-contracts/discussions/17](https://github.com/tokamak-network/tokamak-dao-contracts/discussions/17)
- **Original Proposal**: [tokamak-dao-contracts/discussions/16](https://github.com/tokamak-network/tokamak-dao-contracts/discussions/16)

### Implementation Repository
- **Repository**: [tokamak-network/ton-staking-v2](https://github.com/tokamak-network/ton-staking-v2)
- **Branch**: `rfc-17`
- **Pull Request**: _[To be added after PR creation]_

### Code Files
- **Contract**: [`contracts/stake/managers/DepositManagerV1_2.sol`](https://github.com/tokamak-network/ton-staking-v2/blob/rfc-17/contracts/stake/managers/DepositManagerV1_2.sol)
- **Test Files**:
  - [`test/deposit-manager-v1-2-standalone.test.ts`](https://github.com/tokamak-network/ton-staking-v2/blob/rfc-17/test/deposit-manager-v1-2-standalone.test.ts)
  - [`test/deposit-manager-v1-2-agenda.test.ts`](https://github.com/tokamak-network/ton-staking-v2/blob/rfc-17/test/deposit-manager-v1-2-agenda.test.ts)
  - [`test/shared/depositManagerHelpers.ts`](https://github.com/tokamak-network/ton-staking-v2/blob/rfc-17/test/shared/depositManagerHelpers.ts)

## Questions for Discussion

1. Are there any concerns about the event emission pattern?
2. Should we consider additional events for other withdrawal-related operations?
3. Are there any analytics or reporting requirements we should consider?
4. Any feedback on the upgrade path and deployment plan?

## Next Steps

1. Review and gather feedback from the community
2. Address any concerns or suggestions
3. Prepare DAO agenda proposal
4. Execute deployment after approval

