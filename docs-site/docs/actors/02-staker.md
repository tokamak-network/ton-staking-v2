---
id: actors-staker
sidebar_position: 2
---

# Staker

## Definition

Users who stake TON on L2.

## Role

- Stake TON/WTON on L2 through DepositManager
- Request and process withdrawals

## V3 Changes

**Important**: Stakers do not receive seigniorage in V3.

| Item | V2 | V3 |
|------|-----|-----|
| Seigniorage receipt | O | **X** |
| Staking purpose | Seigniorage receipt | Sequencer/validator collateral conditions |
| Withdrawal restrictions | None | Sequencers/validators must maintain minimum collateral |

## Interactions

```
┌────────────────────────────────────────────────────────────┐
│                        Staker                               │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Staking:                                             │   │
│  │   TON.approve(DepositManager, amount)                │   │
│  │   DepositManager.deposit(layer2, amount)             │   │
│  │                                                      │   │
│  │ Or:                                                  │   │
│  │   TON.approveAndCall(wton, amount, layer2)           │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Withdrawal:                                          │   │
│  │   DepositManager.requestWithdrawal(layer2, amount)   │   │
│  │   (2 weeks wait)                                     │   │
│  │   DepositManager.processRequest(layer2)              │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└────────────────────────────────────────────────────────────┘
```
