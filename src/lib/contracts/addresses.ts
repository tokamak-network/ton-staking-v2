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
  delegateStaking: '0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82', // Proxy
  ton: '0x5FC8d32690cc91D4c39d9d3abcBD16989F875707',
  wton: '0x0165878A594ca255338adfa4d48449f69242Eb8F',
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
