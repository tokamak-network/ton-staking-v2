import { Address } from 'viem';

export type ChainAddresses = {
  delegateStaking: Address;
  ton: Address;
  wton: Address;
};

// Mainnet addresses (to be updated after deployment)
export const MAINNET_ADDRESSES: ChainAddresses = {
  delegateStaking: '0x0000000000000000000000000000000000000000',
  ton: '0x2be5e8c109e2197D077D13A82dAead6a9b3433C5', // TON on Ethereum Mainnet
  wton: '0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2', // WTON on Ethereum Mainnet
};

// Sepolia testnet addresses (to be updated after deployment)
export const SEPOLIA_ADDRESSES: ChainAddresses = {
  delegateStaking: '0x0000000000000000000000000000000000000000',
  ton: '0x0000000000000000000000000000000000000000',
  wton: '0x0000000000000000000000000000000000000000',
};

// Local development addresses (anvil)
// Deployed by: forge script script/DeployLocalV3Upgradeable.s.sol --rpc-url http://localhost:8545 --broadcast
export const LOCAL_ADDRESSES: ChainAddresses = {
  delegateStaking: '0xfbC22278A96299D91d41C453234d97b4F5Eb9B2d', // Proxy
  ton: '0x0355B7B8cb128fA5692729Ab3AAa199C1753f726',
  wton: '0x202CCe504e04bEd6fC0521238dDf04Bc9E8E15aB',
};

export function getAddresses(chainId: number): ChainAddresses {
  switch (chainId) {
    case 1:
      return MAINNET_ADDRESSES;
    case 11155111:
      return SEPOLIA_ADDRESSES;
    case 31337:
      return LOCAL_ADDRESSES;
    default:
      return LOCAL_ADDRESSES;
  }
}
