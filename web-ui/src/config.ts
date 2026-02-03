// TON Staking V3 Configuration
export const CONFIG = {
  chainId: 900,
  rpcUrl: 'http://localhost:8545',
  chainName: 'TON Staking V3 Local',
  nativeCurrency: {
    name: 'Ethereum',
    symbol: 'ETH',
    decimals: 18,
  },
  
  // Contract addresses (loaded from .devnet/addresses.json)
  contracts: {
    ton: '0xd55b55304b5cf7607B6dEd6DA6EeB487918AaD2E',
    wton: '0x2B2fE3204CcB8282ac6bC31d485cB6aa010d193a',
    seigManager: '0x0f5D1ef48f12b6f691401bfe88c2037c690a6afe',
    depositManager: '0x90118d110B07ABB82Ba8980D1c5cC96EeA810d2C',
    layer2Manager: '0xcA03Dc4665A8C3603cb4Fd5Ce71Af9649dC00d44',
    rat: '0xE5BD5bDC03371fB239956dbbF40bD185D6c2ea28',
    validatorReward: '0x55cb3b67D9E65F0Cf4eABCAC84564a1bE6E3b06A',
  },
};

// Test accounts (from Anvil)
export const TEST_ACCOUNTS = [
  {
    name: 'Optimism Deployer',
    address: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
    privateKey: '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
  },
  {
    name: 'TON Staking Deployer',
    address: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
    privateKey: '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d',
  },
  {
    name: 'Validator',
    address: '0x90F79bf6EB2c4f870365E785982E1f101E93b906',
    privateKey: '0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a',
  },
];
