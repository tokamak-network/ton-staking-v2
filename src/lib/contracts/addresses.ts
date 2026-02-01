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
export const LOCAL_ADDRESSES: ChainAddresses = {
  delegateStaking: '0x5FbDB2315678afecb367f032d93F642f64180aa3',
  ton: '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512',
  wton: '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0',
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
