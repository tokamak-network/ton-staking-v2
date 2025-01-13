# RefactorCoinageSnapshot
- Token Information
    - Token Name: StakedWTON
    - Symbol: SWTON
    - decimals: 27


- When you stake TON, it is a token that represents the amount of TON staked.

- When issuing seigniorage, you can receive seigniorage based on the amount of SWTON you hold. The seigniorage you receive at this time is added to SWTON. (reflected when executing seigManager's updateSeigniorage function)

- There are no approve, transfer, or transferFrom functions.



## Differentiated functions

### [balanceOf(address account) external view returns (uint256 amount)](https://github.com/tokamak-network/ton-staking-v2/blob/18328e65957b23dca8553bfd2f988ea724f20d02/contracts/stake/tokens/RefactorCoinageSnapshot.sol#L259-L262)

    - Balance calculation reflecting seigniorage: Balance is calculated by factor value, factor is changed when seigniorage is issued.
    - Since the balance is determined by calculation (supported only in integer type), immediately after staking TON,  the SWTON amount and the amount of TON entered are different. (Ex) When staking 100 TON, 99.999..99 SWTON value is obtained.

