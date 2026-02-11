// Comprehensive ABIs for TON Staking V3 Dashboard

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

export const SEIG_MANAGER_ABI = [
  // V3 Core Functions
  'function stakeOf(address layer2, address account) view returns (uint256)',
  'function stakeOfTotal(address layer2) view returns (uint256)',
  'function checkCurrentEligibility(address layer2) view returns (bool eligible, uint256 requiredStake, uint256 currentStake)',
  'function getEffectiveBridgedTon(address layer2) view returns (uint256)',
  'function getSequencerStaked(address layer2) view returns (uint256)',
  'function v3Migrated() view returns (bool)',
  'function minimumAmount() view returns (uint256)',
  'function claimableL2Seigniorage(address layer2) view returns (uint256)',
  'function updateSeigniorage() returns (bool)',
  'function updateSeigniorageLayer(address layer2) returns (bool)',
  'function lastSeigBlock() view returns (uint256)',
  'function paused() view returns (bool)',
  
  // State variables
  'function validatorReward() view returns (address)',
  'function ratContract() view returns (address)',
  'function daoDistributionRatio() view returns (uint256)',
  'function minStakingRatio() view returns (uint256)',
  'function validatorDistributionRatio() view returns (uint256)',
  'function totalEffectiveBridgedTON() view returns (uint256)',
  'function bridgedTONRewardPerUint() view returns (uint256)',
  'function validatorRewardPerUint() view returns (uint256)',
  'function seigPerBlock() view returns (uint256)',
  'function halfSaturationPoint() view returns (uint256)',

  // V3 Setter Functions (onlyOwner)
  'function setHalfSaturationPoint(uint256 k)',
  'function setDaoDistributionRatio(uint256 ratio)',
  'function setMinStakingRatio(uint256 ratio)',
  'function setValidatorDistributionRatio(uint256 ratio)',
];

export const DEPOSIT_MANAGER_ABI = [
  'function deposit(address layer2, uint256 amount) returns (bool)',
  'function deposit(address layer2, address account, uint256 amount) returns (bool)',
  'function requestWithdrawal(address layer2, uint256 amount) returns (bool)',
  'function processWithdrawal(address layer2, uint256 num) returns (bool)',
  'function pendingUnstaked(address layer2, address account) view returns (uint256)',
  'function numRequests(address layer2, address account) view returns (uint256)',
  'function numPendingRequests(address layer2, address account) view returns (uint256)',
  'function withdrawalRequest(address layer2, address account, uint256 index) view returns (uint128 withdrawableBlockNumber, uint128 amount, bool processed)',
  'function globalWithdrawalDelay() view returns (uint256)',
];

export const LAYER2_MANAGER_ABI = [
  'function rollupConfigInfo(address rollupConfig) view returns (uint8 status, address candidateAddOn)',
  'function operatorOfRollupConfig(address rollupConfig) view returns (address)',
  'function candidateAddOnOfOperator(address operator) view returns (address)',
  'function getLayer2BySystemConfig(address systemConfig) view returns (address)',
  'function getBridgedTon(address rollupConfig) view returns (uint256)',
  'function getBridgedTonByLayer(address layer2) view returns (uint256)',
  'function checkLayer2Tvl(address rollupConfig) view returns (bool result, uint256 amount)',
  'function statusLayer2(address rollupConfig) view returns (uint8)',
  'function getRollupConfig(address layer2) view returns (address)',
];

export const OPERATOR_MANAGER_ABI = [
  'function manager() view returns (address)',
  'function layer2() view returns (address)',
  'function wton() view returns (address)',
  'function balanceOf(address account) view returns (uint256)',
];

export const L1_BRIDGE_REGISTRY_ABI = [
  'function getRollupInfo(address rollupConfig) view returns (uint8 rollupType, address l2Ton, bool rejectedSeigs, bool rejectedL2Deposit, string memory name)',
  'function rollupType(address rollupConfig) view returns (uint8)',
  'function l2Ton(address rollupConfig) view returns (address)',
  'function layer2Tvl(address rollupConfig) view returns (uint256)',
  'function isRejectedSeigs(address rollupConfig) view returns (bool)',
  'function rollupConfigWithDisputeGameFactory(address factory) view returns (address)',
];

export const LAYER2_REGISTRY_ABI = [
  'function layer2s(address) view returns (bool)',
  'function numLayer2s() view returns (uint256)',
];

export const RAT_ABI = [
  // Validator Queries
  'function getValidatorCount(address systemConfig) view returns (uint256)',
  'function getActiveValidatorCount(address systemConfig) view returns (uint256)',
  'function getL2Validators(address systemConfig) view returns (address[])',
  'function isValidatorActive(address validator, address systemConfig) view returns (bool)',
  'function getValidatorRegistration(address validator, address systemConfig) view returns (uint256 collateral, uint32 validatorIndex, bool isActive)',

  // Collateral Queries
  'function getValidatorDeposit(address validator, address systemConfig) view returns (uint256)',
  'function getAvailableCollateral(address validator, address systemConfig) view returns (uint256)',
  'function getDynamicMinimumCollateral(address systemConfig) view returns (uint256)',
  'function getValidatorMinCollateralForLayer2(address layer2, address validator) view returns (uint256)',
  'function getMinimumCollateral() view returns (uint256)',
  'function getCoffWithRelaxedCheck(address systemConfig) view returns (uint256)',

  // Attention Test Queries
  'function getAttentionTest(bytes32 testId) view returns (address validatorAddress, address systemConfig, uint32 batchIndex, bytes32 batchHash, uint256 bondAmount, uint256 createdAt, uint256 deadline, uint8 status)',
  'function getAttentionTestStatus(bytes32 testId) view returns (uint8)',
  'function challengeGameDuration() view returns (uint256)',
  'function safetyBuffer() view returns (uint256)',
  'function gameToTestId(address game) view returns (bytes32)',
  'function batchToTestId(address systemConfig, uint32 batchIndex) view returns (bytes32)',
  'function activeTestCount(address systemConfig) view returns (uint256)',

  // BLS Queries
  'function hasValidatorBLSKey(address validator, address systemConfig) view returns (bool)',
  'function getActiveValidatorsWithBLS(address systemConfig) view returns (address[])',
  'function minValidatorsForFastWithdrawal() view returns (uint256)',

  // Fast Withdrawal
  'function aggregatorFeeRate() view returns (uint256)',

  // Config Parameters
  'function slashingPenalty() view returns (uint256)',
  'function validatorBuffer() view returns (uint256)',
  'function minimumThreshold() view returns (uint256)',
  'function relaxedValidatorCheck() view returns (bool)',
  'function maxValidatorsPerL2() view returns (uint256)',
  'function evidenceSubmissionPeriod() view returns (uint256)',
  'function attentionCost() view returns (uint256)',
  'function ratTriggerProbability() view returns (uint256)',

  // Actions
  'function registerValidator(address systemConfig)',
  'function deactivateValidator(address systemConfig)',
  'function addCollateral(address systemConfig, uint256 amount)',

  // Events
  'event AttentionTestTriggered(bytes32 indexed testId, address indexed validator, address indexed systemConfig, address gameAddress, uint32 batchIndex, uint256 deadline)',
  'event EvidenceSubmitted(bytes32 indexed testId, address indexed validator, address indexed systemConfig, address layer2, uint32 batchIndex)',
  'event ValidatorSlashed(bytes32 indexed testId, address indexed validator, address indexed systemConfig, address layer2, uint256 slashedAmount, bool removedFromSet)',
  'event BondRestored(bytes32 indexed testId, address indexed validator, address indexed systemConfig, address layer2, uint256 restoredAmount)',
  'event FastWithdrawalExecuted(address indexed gameProxy, bytes32 indexed withdrawalHash, address indexed aggregator)',
];

export const DISPUTE_GAME_FACTORY_ABI = [
  'function gameCount() view returns (uint256)',
  'function gameAtIndex(uint256 index) view returns (uint32 gameType, uint64 timestamp, address proxy)',
  'function games(uint32 gameType, bytes32 rootClaim, bytes extraData) view returns (address proxy, uint64 timestamp)',
  'function findLatestGames(uint32 gameType, uint256 start, uint256 n) view returns (tuple(uint256 index, bytes32 metadata, uint64 timestamp, bytes32 rootClaim, bytes extraData)[])',
  'function gameImpls(uint32 gameType) view returns (address)',
  'function initBonds(uint32 gameType) view returns (uint256)',
];

export const DISPUTE_GAME_ABI = [
  'function rootClaim() view returns (bytes32)',
  'function status() view returns (uint8)',
  'function createdAt() view returns (uint64)',
  'function resolvedAt() view returns (uint64)',
  'function gameType() view returns (uint32)',
  'function l2BlockNumber() view returns (uint256)',
  'function claimDataLen() view returns (uint256)',
  'function claimData(uint256) view returns (uint32 parentIndex, address counteredBy, address claimant, uint128 bond, bytes32 claim, uint128 position, uint128 clock)',
  'function maxClockDuration() view returns (uint64)',
  'function startingBlockNumber() view returns (uint256)',
  'function clockExtension() view returns (uint64)',
  'function maxGameDepth() view returns (uint256)',
  'function splitDepth() view returns (uint256)',
  'function weth() view returns (address)',
  'function absolutePrestate() view returns (bytes32)',
  'function l2ChainId() view returns (uint256)',
  'function credit(address) view returns (uint256)',
  'function resolved() view returns (bool)',
];

export const VALIDATOR_REWARD_ABI = [
  'function getPendingRewards(address validator) view returns (uint256)',
  'function getClaimableRewards(address validator) view returns (uint256)',
  'function claimAllRewards()',
];

export const SYSTEM_CONFIG_ABI = [
  'function owner() view returns (address)',
  'function unsafeBlockSigner() view returns (address)',
  'function batcherHash() view returns (bytes32)',
  'function gasLimit() view returns (uint64)',
  'function l1StandardBridge() view returns (address)',
  'function optimismPortal() view returns (address)',
  'function disputeGameFactory() view returns (address)',
  'function l1CrossDomainMessenger() view returns (address)',
  'function l1ERC721Bridge() view returns (address)',
  'function optimismMintableERC20Factory() view returns (address)',
  'function resourceConfig() view returns (uint32 maxResourceLimit, uint8 elasticityMultiplier, uint8 baseFeeMaxChangeDenominator, uint32 minimumBaseFee, uint32 systemTxMaxGas, uint128 maximumBaseFee)',
  'function scalar() view returns (uint256)',
  'function overhead() view returns (uint256)',
  'function basefeeScalar() view returns (uint32)',
  'function blobbasefeeScalar() view returns (uint32)',
  'function startBlock() view returns (uint256)',
  'function batchInbox() view returns (address)',
];

export const OPTIMISM_PORTAL_ABI = [
  'function guardian() view returns (address)',
  'function paused() view returns (bool)',
  'function l2Sender() view returns (address)',
  'function systemConfig() view returns (address)',
  'function ethLockbox() view returns (address)',
  'function ratContract() view returns (address)',
  'function fastWithdrawalResponsePeriod() view returns (uint256)',
  'function proofMaturityDelaySeconds() view returns (uint256)',
  'function disputeGameFinalityDelaySeconds() view returns (uint256)',
  'function seigManager() view returns (address)',
  'function fastFinalizedWithdrawals(bytes32) view returns (bool)',
];

export const L1_STANDARD_BRIDGE_ABI = [
  'function depositETH(uint32 _minGasLimit, bytes calldata _extraData) payable',
  'function depositETHTo(address _to, uint32 _minGasLimit, bytes calldata _extraData) payable',
  'function depositERC20(address _l1Token, address _l2Token, uint256 _amount, uint32 _minGasLimit, bytes calldata _extraData)',
  'function depositERC20To(address _l1Token, address _l2Token, address _to, uint256 _amount, uint32 _minGasLimit, bytes calldata _extraData)',
  'function deposits(address, address) view returns (uint256)',
  'function OTHER_BRIDGE() view returns (address)',
  'function paused() view returns (bool)',
  'function finalizeBridgeETH(address _from, address _to, uint256 _amount, bytes calldata _extraData)',
  'function finalizeBridgeERC20(address _localToken, address _remoteToken, address _from, address _to, uint256 _amount, bytes calldata _extraData)',
];

export const DELAYED_WETH_ABI = [
  'function delay() view returns (uint256)',
  'function owner() view returns (address)',
];

export const L2_STANDARD_BRIDGE_ABI = [
  'function withdraw(address _l2Token, uint256 _amount, uint32 _minGasLimit, bytes calldata _extraData) payable',
  'function withdrawTo(address _l2Token, address _to, uint256 _amount, uint32 _minGasLimit, bytes calldata _extraData) payable',
  'function bridgeETH(uint32 _minGasLimit, bytes calldata _extraData) payable',
  'function bridgeETHTo(address _to, uint32 _minGasLimit, bytes calldata _extraData) payable',
  'function OTHER_BRIDGE() view returns (address)',
  'function deposits(address, address) view returns (uint256)',
];
