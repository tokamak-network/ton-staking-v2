# Stake

## Scenario

1. user or operator deposit TON to DepositManager.
2. operator submits(commits) NRE or ORB.
3. when committed, the depositor gets seigniorages of compound interest, calculated from `deposited amount` and `committed time - deposited time`.
4. seigniorages are claimed and swapped with TON.

`user` -- TON --> `DepositManager` -- increase effectiveBalanaces --> `SeigManager`



## TODOs

1. use concrete implementation of coinage contracts, instead of mocks.
2. make upgradable