
# TON Staking Contracts

The TON staking contract is a contract that distributes TON seigniorage by staking TON. It is the most important function of the Tokamak economy, and you can understand it in more detail by reading [the Tokamak Network white paper](https://github.com/tokamak-network/papers/blob/master/cryptoeconomics/tokamak-cryptoeconomics-en.md).


## Overview Of Contracts


**Table of Contracts**
- [TON](./contracts/TON.md)
- [WTON](./contracts/WTON.md)
- [SWTON : RefactorCoinageSnapshot](./contracts/RefactorCoinageSnapshot.md)
- [DepositManager](./contracts/DepositManager.md)
- [SeigManager](./contracts/SeigManager.md)
- [Layer2Registry](./contracts/Layer2Registry.md)
- [AutoRefactorCoinageFactory](./contracts/AutoRefactorCoinageFactory.md)

## Tokens
- TON
    - Utility tokens in the Tokamak ecosystem

- WTON
    - TON Seigniorage Token

- SWTON
    - Staked TON Token

## Seigniorage issuance
- 3.92 TON seigniorage issued per block
- After staking TON, seigniorage can only be issued through the 'Update Seigniorage' function of SeigManager Contract.

- Seigniorage Distribution Logic (V1.0 & V2.0)
    - Reference: [White paper](https://github.com/tokamak-network/papers/blob/master/cryptoeconomics/tokamak-cryptoeconomics-en.md#221-ton-staking-v1)
    - Implementation Code([Mainnet deployed](https://etherscan.io/address/0x0b55a0f463b6defb81c6063973763951712d0e5f#readProxyContract)): [SeigManagerV1_2.sol](https://github.com/tokamak-network/ton-staking-v2/blob/18328e65957b23dca8553bfd2f988ea724f20d02/contracts/stake/managers/SeigManagerV1_2.sol#L429-L503)
        - The reason why the branch of the code is ton-staking-v2.0 is because [V1](https://github.com/tokamak-network/plasma-evm-contracts/blob/master/contracts/stake/managers/SeigManager.sol) version consists of a contract that cannot be upgraded, so V1 was modified to be upgradeable and named [V2](https://github.com/tokamak-network/ton-staking-v2/blob/ton-staking-v2.0/contracts/stake/managers/SeigManagerV1_2.sol#L429-L503). V1 and V2 in the repo have the same logic.


- Seigniorage Distribution Logic (V2.5)
    - Reference 1: [White paper](https://github.com/tokamak-network/papers/blob/master/cryptoeconomics/tokamak-cryptoeconomics-en.md#222-ton-staking-v2)
    - Reference 2: [V2.5 Changelog](https://github.com/tokamak-network/ton-staking-v2/blob/deploy-ton-staking-v2.5/docs/en/ton-staking-v2.md#changes-in-seigniorage-distribution)
    - Implementation Code: [SeigManagerV1_3.sol](https://github.com/tokamak-network/ton-staking-v2/blob/3897c0ede97a6f8229d835b9d60653217adb6132/contracts/stake/managers/SeigManagerV1_3.sol#L414-L482)



