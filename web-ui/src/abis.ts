// Minimal ABIs for TON Staking V3 contracts

export const TON_ABI = [
  'function name() view returns (string)',
  'function symbol() view returns (string)',
  'function decimals() view returns (uint8)',
  'function totalSupply() view returns (uint256)',
  'function balanceOf(address) view returns (uint256)',
  'function transfer(address to, uint256 amount) returns (bool)',
  'function approve(address spender, uint256 amount) returns (bool)',
  'function allowance(address owner, address spender) view returns (uint256)',
];

export const WTON_ABI = [
  ...TON_ABI,
  'function swapFromTON(uint256 amount) returns (bool)',
  'function swapToTON(uint256 amount) returns (bool)',
];

export const DEPOSIT_MANAGER_ABI = [
  'function deposit(address layer2, uint256 amount) returns (bool)',
  'function requestWithdrawal(address layer2, uint256 amount) returns (bool)',
  'function processWithdrawal(address layer2, uint256 num) returns (bool)',
  'function stakeOf(address layer2, address account) view returns (uint256)',
  'function withdrawalRequestIndex(address layer2, address account) view returns (uint256)',
  'function withdrawalRequest(address layer2, address account, uint256 index) view returns (uint128 withdrawableBlockNumber, uint128 amount, bool processed)',
];

export const LAYER2_MANAGER_ABI = [
  'function registerLayer2(address systemConfig) returns (bool)',
  'function layer2s(uint256) view returns (address)',
  'function numLayer2s() view returns (uint256)',
  'function layer2Info(address) view returns (address systemConfig, address l1Bridge, address portal, address l2Ton, uint8 l2Type, uint8 status, bool rejectedSeigs, bool rejectedL2Deposit)',
];

export const SEIG_MANAGER_ABI = [
  'function claimL2Seigniorage(address layer2) returns (uint256, uint256)',
  'function checkCurrentEligibility(address layer2) view returns (bool eligible, uint256 requiredStake, uint256 currentBridgedTON)',
];

export const RAT_ABI = [
  'function registerValidator(address systemConfig, uint256 stakeAmount) payable returns (bool)',
  'function unregisterValidator(address systemConfig) returns (bool)',
  'function isRegisteredValidator(address systemConfig, address validator) view returns (bool)',
  'function getValidatorInfo(address systemConfig, address validator) view returns (uint256 stakedAmount, uint256 registeredAt, bool isActive)',
];
