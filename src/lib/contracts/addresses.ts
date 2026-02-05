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
  delegateStaking: '0x4c5859f0F772848b2D91F1D83E2Fe57935348029', // Proxy
  ton: '0x4826533B4897376654Bb4d4AD88B7faFD0C98528',
  wton: '0x99bbA657f2BbC93c02D617f8bA121cB8Fc104Acf',
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
