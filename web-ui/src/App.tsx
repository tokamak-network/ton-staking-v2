import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { CONFIG, TEST_ACCOUNTS, ROLLUP_TYPES } from './config';
import {
  TON_ABI, WTON_ABI, SEIG_MANAGER_ABI, DEPOSIT_MANAGER_ABI,
  LAYER2_MANAGER_ABI, L1_BRIDGE_REGISTRY_ABI, LAYER2_REGISTRY_ABI,
  RAT_ABI, DISPUTE_GAME_FACTORY_ABI, DISPUTE_GAME_ABI, SYSTEM_CONFIG_ABI,
  OPTIMISM_PORTAL_ABI, L1_STANDARD_BRIDGE_ABI, L2_STANDARD_BRIDGE_ABI, OPERATOR_MANAGER_ABI,
  DELAYED_WETH_ABI, L2_TO_L1_MESSAGE_PASSER_ABI
} from './abis';
import './App.css';

declare global {
  interface Window {
    ethereum?: any;
  }
}

interface NodeStatus {
  l1Running: boolean;
  l1Block: string;
  l1ChainId: string;
  l2Running: boolean;
  l2Block: string;
  l2ChainId: string;
}

interface RollupInfo {
  rollupType: number;
  l2Ton: string;
  rejectedSeigs: boolean;
  rejectedL2Deposit: boolean;
  name: string;
}

interface OperatorInfo {
  operator: string;
  operatorManager: string;
  operatorManagerManager: string;
  candidateAddOn: string;
  sequencerStake: string;
  operatorManagerWtonBalance: string;
  isLayer2Registered: boolean;
  isEligible: boolean;
  requiredStake: string;
  currentStake: string;
}

interface ValidatorInfo {
  address: string;
  deposit: string;
  available: string;
  wtonBalance: string;
  isActive: boolean;
  ratRegistered: boolean;
}

interface GameInfo {
  index: number;
  gameType: number;
  timestamp: number;
  proxy: string;
}

interface AttentionTestInfo {
  testId: string;
  validator: string;
  systemConfig: string;
  batchIndex: number;
  gameAddress: string;
  batchHash: string;
  bondAmount: string;
  createdAt: number;
  deadline: number;
  status: number;
  statusLabel: string;
}

interface EnhancedGameInfo extends GameInfo {
  rootClaim: string;
  status: number;
  l2BlockNumber: number;
  claimCount: number;
  ratTestId: string;
  hasFastWithdrawal: boolean;
}

interface ClaimDataInfo {
  index: number;
  parentIndex: number;
  counteredBy: string;
  claimant: string;
  bond: string;
  claim: string;
  position: number;
  clock: number;
}

interface GameDetailInfo extends EnhancedGameInfo {
  createdAt: number;
  resolvedAt: number;
  maxClockDuration: number;
  startingBlockNumber: number;
  claims: ClaimDataInfo[];
  ratTestDetail: AttentionTestInfo | null;
  proposerBond: string;        // proposer's initial bond (from claim[0])
  proposerCredit: string;      // proposer's unclaimed credit
  proposerAddress: string;     // proposer address (claim[0].claimant)
}

interface GameStatusSummary {
  total: number;
  inProgress: number;
  challengerWins: number;
  defenderWins: number;
}

interface SyncStatus {
  currentL1: { number: number; hash: string };
  unsafeL2: { number: number; hash: string };
  safeL2: { number: number; hash: string };
  finalizedL2: { number: number; hash: string };
}

interface ProposerInfo {
  totalGames: number;
  latestGame: EnhancedGameInfo | null;
  syncStatus: SyncStatus | null;
  gamesLast1h: number;
  gamesLast24h: number;
  averageInterval: number;
  lag: number;
  isHealthy: boolean;
  recentGames: EnhancedGameInfo[];
  proposerAddress: string;
  proposerAddressSource: string;  // 'config' | 'claimant' - 주소 출처
  gameIntervals: number[];
  outputRoots: { index: number; l2Block: number; rootClaim: string; blockRange: string }[];
  ethBalance: string;
  lastGameAge: number;
  initBond: string;       // 게임 생성 시 필요한 ETH bond (DisputeGameFactory.initBonds)
  gameType: number;        // 생성하는 게임 타입 (보통 0 = FaultDisputeGame)
  inferredProposalInterval: number; // 게임 타임스탬프에서 추론한 실제 proposal interval (초)
}

interface BatcherInfo {
  address: string;
  ethBalance: string;
  nonce: number;
  syncStatus: SyncStatus | null;
  safeLag: number;
  recentBatchTxs: BatchTxInfo[];
  isHealthy: boolean;
  batchInbox: string;
  avgBatchInterval: number;
  totalDataBytes: number;
  avgDataPerTx: number;
  avgGasPerTx: number;
  txCount: number;
  daType: string;
}

interface BatchTxInfo {
  hash: string;
  blockNumber: number;
  timestamp: number;
  gasUsed: string;
  dataSize: number;
  type: number;
}

interface L2Info {
  l2ChainId: string;
  l2BlockNumber: string;
  batcherHash: string;
  unsafeBlockSigner: string;
  gasLimit: string;
  l1Bridge: string;
  portal: string;
  disputeGameFactory: string;
  l1CrossDomainMessenger: string;
  batchInbox: string;
  overhead: string;
  scalar: string;
  basefeeScalar: string;
  blobbasefeeScalar: string;
  portalGuardian: string;
  portalPaused: boolean;
  portalTonBalance: string;
  portalEthBalance: string;
  bridgeTonBalance: string;
  ethLockboxAddress: string;
  ethLockboxBalance: string;
}

interface BlockInfo {
  number: number;
  hash: string;
  parentHash: string;
  timestamp: number;
  miner: string;
  gasUsed: string;
  gasLimit: string;
  baseFeePerGas?: string;
  transactions: string[];
}

interface TransactionInfo {
  hash: string;
  from: string;
  to: string | null;
  value: string;
  gasPrice: string;
  gasUsed?: string;
  status?: number;
  blockNumber: number;
  blockHash: string;
  transactionIndex: number;
  data?: string;
  methodId?: string;
}

interface GameWithdrawalSettings {
  // FaultDisputeGame (immutable)
  gameProxy: string;
  gameImplAddress: string;
  maxClockDuration: number;
  clockExtension: number;
  maxGameDepth: number;
  splitDepth: number;
  absolutePrestate: string;
  l2ChainId: number;
  wethAddress: string;
  // DelayedWETH
  wethDelay: number;
  // OptimismPortal2
  portalAddress: string;
  proofMaturityDelay: number;
  disputeGameFinalityDelay: number;
  fastWithdrawalResponsePeriod: number;
  ratContractOnPortal: string;
  seigManagerOnPortal: string;
  // DisputeGameFactory
  dgfAddress: string;
  initBond: string;
  // RAT
  ratAddress: string;
  evidenceSubmissionPeriod: number;
  minValidatorsForFW: number;
}

type WithdrawalStatus = 'initiated' | 'ready_to_prove' | 'proven' | 'ready_to_finalize' | 'finalized' | 'fast_verified' | 'fast_finalized';

interface WithdrawalInfo {
  l2TxHash: string;
  l2BlockNumber: number;
  nonce: bigint;
  sender: string;
  target: string;
  value: bigint;
  gasLimit: bigint;
  data: string;
  withdrawalHash: string;
  status: WithdrawalStatus;
  statusMessage: string;
  nextAction: string;
  gameIndex?: number;
  gameProxy?: string;
  gameL2Block?: number;
  gameType?: number;
  gameStatus?: number;
  isGameRespected?: boolean;
  provenTimestamp?: number;
  provenGameProxy?: string;
  proofMaturityDelay?: number;
  disputeGameFinalityDelay?: number;
  timeUntilFinalizable?: number;
  isFastVerified?: boolean;
  isFastFinalized?: boolean;
}

interface MerkleProofData {
  outputRootProof: {
    version: string;
    stateRoot: string;
    messagePasserStorageRoot: string;
    latestBlockhash: string;
  };
  withdrawalProof: string[];
  gameIndex: number;
}

const L2_TO_L1_MESSAGE_PASSER = '0x4200000000000000000000000000000000000016';

function App() {
  const [provider, setProvider] = useState<ethers.BrowserProvider | null>(null);
  const [l1Provider] = useState<ethers.JsonRpcProvider>(new ethers.JsonRpcProvider(CONFIG.rpcUrl));
  const [l2Provider] = useState<ethers.JsonRpcProvider>(new ethers.JsonRpcProvider(CONFIG.l2RpcUrl));
  
  const [signer, setSigner] = useState<ethers.Signer | null>(null);
  const [address, setAddress] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(false);
  const [activeTab, setActiveTab] = useState<string>('overview');
  const [sidebarOpen, setSidebarOpen] = useState<boolean>(false);
  
  // Dashboard Data
  const [nodeStatus, setNodeStatus] = useState<NodeStatus | null>(null);
  const [rollupInfo, setRollupInfo] = useState<RollupInfo | null>(null);
  const [operatorInfo, setOperatorInfo] = useState<OperatorInfo | null>(null);
  const [validators, setValidators] = useState<ValidatorInfo[]>([]);
  const [games, setGames] = useState<GameInfo[]>([]);
  const [v3Migrated, setV3Migrated] = useState<boolean>(false);
  const [totalValidators, setTotalValidators] = useState<number>(0);
  const [activeValidators, setActiveValidators] = useState<number>(0);
  const [minCollateral, setMinCollateral] = useState<string>('0');
  const [sequencerMinStake, setSequencerMinStake] = useState<string>('0');
  const [slashingPenalty, setSlashingPenalty] = useState<string>('0');
  const [validatorBuffer, setValidatorBuffer] = useState<string>('0');
  const [relaxedValidatorCheck, setRelaxedValidatorCheck] = useState<boolean>(true);
  const [maxValidatorsPerL2, setMaxValidatorsPerL2] = useState<number>(0);
  const [evidenceSubmissionPeriod, setEvidenceSubmissionPeriod] = useState<number>(0);
  const [l2Info, setL2Info] = useState<L2Info | null>(null);
  const [validatorRewardWtonBalance, setValidatorRewardWtonBalance] = useState<string>('0');

  // Block Explorer State
  const [l1Blocks, setL1Blocks] = useState<BlockInfo[]>([]);
  const [l2Blocks, setL2Blocks] = useState<BlockInfo[]>([]);
  const [l1Transactions, setL1Transactions] = useState<TransactionInfo[]>([]);
  const [l2Transactions, setL2Transactions] = useState<TransactionInfo[]>([]);
  const [selectedBlock, setSelectedBlock] = useState<BlockInfo | null>(null);
  const [selectedTransaction, setSelectedTransaction] = useState<TransactionInfo | null>(null);
  const [blockSearchInput, setBlockSearchInput] = useState<string>('');
  const [txSearchInput, setTxSearchInput] = useState<string>('');
  const [explorerView, setExplorerView] = useState<'blocks' | 'transactions'>('blocks');

  // Enhanced monitoring state
  const [attentionTests, setAttentionTests] = useState<AttentionTestInfo[]>([]);
  const [enhancedGames, setEnhancedGames] = useState<EnhancedGameInfo[]>([]);
  const [proposerInfo, setProposerInfo] = useState<ProposerInfo | null>(null);
  const [batcherInfo, setBatcherInfo] = useState<BatcherInfo | null>(null);
  const [validatorEvents, setValidatorEvents] = useState<{type: string; validator: string; amount: string; testId: string; blockNumber: number; timestamp: number}[]>([]);
  const [blsValidators, setBlsValidators] = useState<string[]>([]);
  const [minValidatorsForFW, setMinValidatorsForFW] = useState<number>(0);
  const [factoryInfo, setFactoryInfo] = useState<{gameImpl: string; initBond: string} | null>(null);
  const [selectedGameDetail, setSelectedGameDetail] = useState<GameDetailInfo | null>(null);
  const [selectedAttentionTest, setSelectedAttentionTest] = useState<AttentionTestInfo | null>(null);
  const [gameStatusSummary, setGameStatusSummary] = useState<GameStatusSummary>({ total: 0, inProgress: 0, challengerWins: 0, defenderWins: 0 });
  const [gameWithdrawalSettings, setGameWithdrawalSettings] = useState<GameWithdrawalSettings | null>(null);

  // Fast Withdrawal state
  const [fwStatus, setFwStatus] = useState<{ ready: boolean; blsCount: number; minRequired: number; responsePeriod: number; feeRate: string; fwFee: string } | null>(null);
  const [fwCheckResult, setFwCheckResult] = useState<{ hash: string; finalized: boolean } | null>(null);

  // Withdrawal Tracker state
  const [trackedWithdrawals, setTrackedWithdrawals] = useState<WithdrawalInfo[]>([]);
  const [withdrawalTxHashInput, setWithdrawalTxHashInput] = useState('');
  const [withdrawalLoading, setWithdrawalLoading] = useState(false);
  const [withdrawalError, setWithdrawalError] = useState('');
  const [selectedWithdrawal, setSelectedWithdrawal] = useState<WithdrawalInfo | null>(null);
  const [withdrawalProofData, setWithdrawalProofData] = useState<MerkleProofData | null>(null);
  const [lastWithdrawalResult, setLastWithdrawalResult] = useState<{ txHash: string; type: string } | null>(null);

  // User Balances (L1)
  const [ethBalance, setEthBalance] = useState<string>('0');
  const [tonBalance, setTonBalance] = useState<string>('0');
  const [wtonBalance, setWtonBalance] = useState<string>('0');
  const [stakedAmount, setStakedAmount] = useState<string>('0');
  const [pendingUnstaked, setPendingUnstaked] = useState<string>('0');
  const [withdrawalRequests, setWithdrawalRequests] = useState<number>(0);

  // User Balances (L2)
  const [l2EthBalance, setL2EthBalance] = useState<string>('0');
  const [l2TonBalance, setL2TonBalance] = useState<string>('0');

  // Seigniorage State
  const [selectedLayer2, setSelectedLayer2] = useState<string>('');
  const [seigniorageInfo, setSeigniorageInfo] = useState<{
    lastSeigBlock: string;
    currentBlock: string;
    bridgedTon: string;
    effectiveBridgedTon: string;
    totalEffectiveBridgedTon: string;
    isEligible: boolean;
    requiredStake: string;
    currentStake: string;
    claimableAmount: string;
    isPaused: boolean;
    // 추가 정보
    isRegistered: boolean;
    layer2Status: number;
    rollupConfig: string;
    operatorManagerAddress: string;
    operatorManagerBalance: string;
    operatorManagerManager: string;
    systemConfigSigner: string;
    signersMatch: boolean;
    // 시뇨리지 발행 팩터들
    seigPerBlock: string;
    daoDistributionRatio: string;
    minStakingRatio: string;
    validatorDistributionRatio: string;
    halfSaturationPoint: string;
    bridgedTONRewardPerUint: string;
    validatorRewardPerUint: string;
  } | null>(null);

  // Load addresses from JSON files
  const loadAddresses = async () => {
    try {
      const timestamp = Date.now(); // Cache buster
      const [tonResponse, optimismResponse] = await Promise.all([
        fetch(`/addresses.json?t=${timestamp}`),
        fetch(`/optimism-addresses.json?t=${timestamp}`)
      ]);
      
      if (tonResponse.ok) {
        const addresses = await tonResponse.json();
        console.log('📦 Loaded TON Staking addresses:', addresses);
        
        // Update CONFIG with deployed TON Staking addresses
        if (addresses.ton) CONFIG.contracts.ton = addresses.ton;
        if (addresses.wton) CONFIG.contracts.wton = addresses.wton;
        if (addresses.seigManagerProxy) CONFIG.contracts.seigManager = addresses.seigManagerProxy;
        if (addresses.depositManagerProxy) CONFIG.contracts.depositManager = addresses.depositManagerProxy;
        if (addresses.layer2ManagerProxy) CONFIG.contracts.layer2Manager = addresses.layer2ManagerProxy;
        if (addresses.l1BridgeRegistryProxy) CONFIG.contracts.l1BridgeRegistry = addresses.l1BridgeRegistryProxy;
        if (addresses.layer2RegistryProxy) CONFIG.contracts.layer2Registry = addresses.layer2RegistryProxy;
        if (addresses.ratProxy) CONFIG.contracts.rat = addresses.ratProxy;
        if (addresses.validatorRewardProxy) CONFIG.contracts.validatorReward = addresses.validatorRewardProxy;
        
        // SystemConfig can come from either file, prefer ton-staking addresses.json
        if (addresses.systemConfig) CONFIG.contracts.systemConfig = addresses.systemConfig;
        if (addresses.disputeGameFactory) CONFIG.contracts.disputeGameFactory = addresses.disputeGameFactory;
      } else {
        console.warn('⚠️ addresses.json not found, using default config');
      }
      
      if (optimismResponse.ok) {
        const optimismAddresses = await optimismResponse.json();
        console.log('📦 Loaded Optimism addresses:', optimismAddresses);
        
        // Update with Optimism addresses (if not already set)
        if (optimismAddresses.SystemConfigProxy && !CONFIG.contracts.systemConfig) {
          CONFIG.contracts.systemConfig = optimismAddresses.SystemConfigProxy;
        }
        if (optimismAddresses.DisputeGameFactoryProxy && !CONFIG.contracts.disputeGameFactory) {
          CONFIG.contracts.disputeGameFactory = optimismAddresses.DisputeGameFactoryProxy;
        }
      }
      
      console.log('✅ CONFIG updated with deployed addresses:', CONFIG.contracts);
      return true;
    } catch (error) {
      console.warn('⚠️ Failed to load addresses:', error);
      return false;
    }
  };

  // Reload addresses and refresh ALL data
  const reloadAddresses = async () => {
    setLoading(true);
    console.log('🔄 Starting address reload...');
    try {
      const success = await loadAddresses();
      if (success) {
        console.log('✅ Addresses loaded, clearing cached data...');
        // Force clear all cached data
        setNodeStatus(null);
        setRollupInfo(null);
        setOperatorInfo(null);
        setValidators([]);
        setGames([]);
        setSeigniorageInfo(null);
        setL2Info(null);
        
        console.log('🔄 Reloading dashboard data...');
        // Reload all data with new addresses
        await Promise.all([
          loadNodeStatus(),
          loadRollupInfo(),
          loadValidators(),
          loadGames(),
          loadSystemParams(),
          loadL2Info(),
        ]);
        
        console.log('🔄 Reloading operator info...');
        // Reload operator info (sequential, not parallel) - this also loads seigniorage info
        await loadOperatorInfo().catch(err => {
          console.warn('loadOperatorInfo failed:', err);
        });
        
        console.log('🔄 Reloading user balances...');
        // Reload user balances
        if (address) {
          await loadUserBalances(address);
        }
        
        console.log('✅ All data reloaded with new addresses');
        console.log('📊 Current CONFIG:', CONFIG.contracts);
        alert('✅ Addresses and data reloaded successfully!');
      } else {
        alert('⚠️ Failed to reload addresses. Check console for details.');
      }
    } catch (error) {
      console.error('❌ Failed to reload addresses:', error);
      alert('❌ Error reloading addresses');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    const initialize = async () => {
      await loadAddresses();
      initializeProvider();
      await loadDashboardData();
    };
    
    initialize();
    
    // Auto refresh every 10 seconds
    const interval = setInterval(loadDashboardData, 10000);
    return () => clearInterval(interval);
  }, []);

  // Load blocks when explorer tab is active
  useEffect(() => {
    if (activeTab === 'l1-explorer') {
      if (explorerView === 'blocks') {
        loadL1Blocks(20);
      } else {
        loadL1Transactions(20);
      }
    } else if (activeTab === 'l2-explorer') {
      if (explorerView === 'blocks') {
        loadL2Blocks(20);
      } else {
        loadL2Transactions(20);
      }
    }
  }, [activeTab, explorerView]);

  // Load seigniorage info when operator or seigniorage tab is active
  useEffect(() => {
    if ((activeTab === 'operator' || activeTab === 'seigniorage') && operatorInfo?.candidateAddOn && operatorInfo.candidateAddOn !== ethers.ZeroAddress) {
      // Auto-populate selectedLayer2 for seigniorage tab
      if (activeTab === 'seigniorage' && !selectedLayer2) {
        setSelectedLayer2(operatorInfo.candidateAddOn);
      }
      loadSeigniorageInfo(operatorInfo.candidateAddOn);
    }
  }, [activeTab, operatorInfo?.candidateAddOn]);

  // Load enhanced data when relevant tabs are active
  useEffect(() => {
    let interval: ReturnType<typeof setInterval> | null = null;

    const loadTabData = async () => {
      if (activeTab === 'validators') {
        await Promise.all([loadAttentionTests(), loadValidatorEvents(), loadBLSInfo(), loadGameWithdrawalSettings()]);
      } else if (activeTab === 'games') {
        await loadEnhancedGames();
      } else if (activeTab === 'proposer') {
        await loadProposerInfo();
      } else if (activeTab === 'batcher') {
        await loadBatcherInfo();
      } else if (activeTab === 'game-settings') {
        await loadGameWithdrawalSettings();
      }
    };

    loadTabData();

    if (['validators', 'games', 'proposer', 'batcher'].includes(activeTab)) {
      interval = setInterval(loadTabData, 10000);
    }

    // Clear game detail when leaving games/proposer tab
    if (activeTab !== 'games' && activeTab !== 'proposer') {
      setSelectedGameDetail(null);
    }

    return () => {
      if (interval) clearInterval(interval);
    };
  }, [activeTab]);

  const initializeProvider = async () => {
    try {
      if (typeof window.ethereum !== 'undefined') {
        const prov = new ethers.BrowserProvider(window.ethereum);
        setProvider(prov);
        
        const accounts = await window.ethereum.request({ method: 'eth_accounts' });
        if (accounts.length > 0) {
          const sign = await prov.getSigner();
          setSigner(sign);
          const addr = await sign.getAddress();
          setAddress(addr);
          await loadUserBalances(addr);
        }
      }
    } catch (error) {
      console.error('Failed to initialize provider:', error);
    }
  };

  const connectWallet = async () => {
    if (!provider) return;
    
    try {
      setLoading(true);
      await window.ethereum.request({ method: 'eth_requestAccounts' });
      
      try {
        await window.ethereum.request({
          method: 'wallet_switchEthereumChain',
          params: [{ chainId: `0x${CONFIG.chainId.toString(16)}` }],
        });
      } catch (switchError: any) {
        if (switchError.code === 4902) {
          await window.ethereum.request({
            method: 'wallet_addEthereumChain',
            params: [{
              chainId: `0x${CONFIG.chainId.toString(16)}`,
              chainName: CONFIG.chainName,
              nativeCurrency: CONFIG.nativeCurrency,
              rpcUrls: [CONFIG.rpcUrl],
            }],
          });
        } else {
          throw switchError;
        }
      }
      
      const sign = await provider.getSigner();
      setSigner(sign);
      const addr = await sign.getAddress();
      setAddress(addr);
      
      await loadUserBalances(addr);
    } catch (error) {
      console.error('Failed to connect wallet:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadDashboardData = async () => {
    try {
      await Promise.all([
        loadNodeStatus(),
        loadRollupInfo(),
        loadValidators(),
        loadGames(),
        loadSystemParams(),
        loadL2Info(),
      ]);
      
      // Load operator info (non-critical, can fail)
      await loadOperatorInfo().catch(err => {
        console.warn('loadOperatorInfo failed but continuing:', err);
      });
      
      // 잔액은 수동 새로고침 버튼으로 업데이트 (부하 감소)
    } catch (error) {
      console.error('loadDashboardData failed:', error);
      // Don't throw - partial data is better than nothing
    }
  };

  const loadNodeStatus = async () => {
    try {
      const [l1Block, l1ChainId] = await Promise.all([
        l1Provider.getBlockNumber(),
        l1Provider.getNetwork().then(n => n.chainId.toString()),
      ]);

      let l2Running = false;
      let l2Block = 'N/A';
      let l2ChainId = 'N/A';
      try {
        l2Block = (await l2Provider.getBlockNumber()).toString();
        l2ChainId = (await l2Provider.getNetwork()).chainId.toString();
        l2Running = true;
      } catch (e) {
        // L2 not running
      }

      setNodeStatus({
        l1Running: true,
        l1Block: l1Block.toString(),
        l1ChainId,
        l2Running,
        l2Block,
        l2ChainId,
      });
    } catch (error) {
      console.error('Failed to load node status:', error);
    }
  };

  const loadRollupInfo = async () => {
    try {
      console.log('🔍 loadRollupInfo: Starting...');
      const registry = new ethers.Contract(
        CONFIG.contracts.l1BridgeRegistry,
        L1_BRIDGE_REGISTRY_ABI,
        l1Provider
      );

      console.log('🔍 loadRollupInfo: Calling getRollupInfo for:', CONFIG.contracts.systemConfig);
      const info = await registry.getRollupInfo(CONFIG.contracts.systemConfig);
      console.log('🔍 loadRollupInfo: Got info:', info);
      
      const rollupData = {
        rollupType: Number(info[0]),
        l2Ton: info[1],
        rejectedSeigs: info[2],
        rejectedL2Deposit: info[3],
        name: info[4],
      };
      console.log('✅ loadRollupInfo: Setting rollupInfo:', rollupData);
      setRollupInfo(rollupData);
    } catch (error) {
      console.error('❌ Failed to load rollup info:', error);
    }
  };

  const loadOperatorInfo = async () => {
    try {
      const layer2Manager = new ethers.Contract(
        CONFIG.contracts.layer2Manager,
        LAYER2_MANAGER_ABI,
        l1Provider
      );

      const seigManager = new ethers.Contract(
        CONFIG.contracts.seigManager,
        SEIG_MANAGER_ABI,
        l1Provider
      );

      const layer2Registry = new ethers.Contract(
        CONFIG.contracts.layer2Registry,
        LAYER2_REGISTRY_ABI,
        l1Provider
      );

      // operatorOfRollupConfig returns OperatorManager address
      const operatorManager = await layer2Manager.operatorOfRollupConfig(CONFIG.contracts.systemConfig);

      let sequencerStake = '0';
      let operatorManagerWtonBalance = '0';
      let isLayer2Registered = false;
      let candidateAddOn = ethers.ZeroAddress;
      let operatorManagerManager = ethers.ZeroAddress;
      let operator = ethers.ZeroAddress;

      if (operatorManager !== ethers.ZeroAddress) {
        try {
          // Get CandidateAddOn from OperatorManager
          candidateAddOn = await layer2Manager.candidateAddOnOfOperator(operatorManager);

          // Get OperatorManager.manager() - this is the operator/sequencer address
          const opManagerContract = new ethers.Contract(operatorManager, OPERATOR_MANAGER_ABI, l1Provider);
          operatorManagerManager = await opManagerContract.manager().catch(() => ethers.ZeroAddress);
          operator = operatorManagerManager; // The manager is the actual operator

          // Get stake from SeigManager (stakeOf returns total staked amount)
          sequencerStake = (await seigManager.stakeOf(candidateAddOn, operatorManager)).toString();

          // Get WTON balance of OperatorManager
          const wtonContract = new ethers.Contract(CONFIG.contracts.wton, WTON_ABI, l1Provider);
          operatorManagerWtonBalance = (await wtonContract.balanceOf(operatorManager)).toString();

          // Check Layer2Registry with CandidateAddOn address
          isLayer2Registered = await layer2Registry.layer2s(candidateAddOn);
        } catch (e) {
          console.error('Failed to load operator stake:', e);
        }
      }

      // Get eligibility status using checkCurrentEligibility
      let isEligible = false;
      let requiredStake = '0';
      let currentStake = '0';
      try {
        const eligibility = await seigManager.checkCurrentEligibility(candidateAddOn);
        isEligible = eligibility[0];
        requiredStake = eligibility[1].toString();
        currentStake = eligibility[2].toString();
      } catch (e: any) {
        console.warn('checkCurrentEligibility not available (expected for V3 setup):', e?.message || e);
        // This is expected - SeigManager may not support this candidateAddOn yet
      }

      const opInfo = {
        operator,
        operatorManager,
        operatorManagerManager,
        candidateAddOn,
        sequencerStake,
        operatorManagerWtonBalance,
        isLayer2Registered,
        isEligible,
        requiredStake,
        currentStake,
      };
      
      setOperatorInfo(opInfo);
      
      // Load seigniorage info immediately after setting operator info
      if (candidateAddOn && candidateAddOn !== ethers.ZeroAddress) {
        await loadSeigniorageInfo(candidateAddOn, CONFIG.contracts.systemConfig).catch(err => {
          console.warn('Failed to load seigniorage info in loadOperatorInfo:', err);
        });
      }
    } catch (error) {
      console.error('Failed to load operator info:', error);
    }
  };

  const loadValidators = async () => {
    try {
      const rat = new ethers.Contract(CONFIG.contracts.rat, RAT_ABI, l1Provider);
      const wtonContract = new ethers.Contract(CONFIG.contracts.wton, WTON_ABI, l1Provider);

      const validatorAddrs = await rat.getL2Validators(CONFIG.contracts.systemConfig);
      
      const validatorList: ValidatorInfo[] = [];
      
      for (const addr of validatorAddrs) {
        try {
          const deposit = await rat.getValidatorDeposit(addr, CONFIG.contracts.systemConfig);
          const available = await rat.getAvailableCollateral(addr, CONFIG.contracts.systemConfig);
          const isActive = await rat.isValidatorActive(addr, CONFIG.contracts.systemConfig);
          const wtonBal = await wtonContract.balanceOf(addr);
          
          let ratRegistered = false;
          try {
            const registration = await rat.getValidatorRegistration(addr, CONFIG.contracts.systemConfig);
            ratRegistered = registration[2]; // isActive field
          } catch (e) {
            // Not registered
          }

          validatorList.push({
            address: addr,
            deposit: ethers.formatUnits(deposit, 27), // WTON uses ray (1e27)
            available: ethers.formatUnits(available, 27), // WTON uses ray (1e27)
            wtonBalance: ethers.formatUnits(wtonBal, 27), // WTON balance (27 decimals)
            isActive,
            ratRegistered,
          });
        } catch (e) {
          console.error(`Failed to load validator ${addr}:`, e);
        }
      }

      setValidators(validatorList);
      
      // Load ValidatorReward contract WTON balance
      try {
        const validatorRewardBalance = await wtonContract.balanceOf(CONFIG.contracts.validatorReward);
        setValidatorRewardWtonBalance(ethers.formatUnits(validatorRewardBalance, 27));
      } catch (e) {
        console.error('Failed to load ValidatorReward WTON balance:', e);
      }
    } catch (error) {
      console.error('Failed to load validators:', error);
      setValidators([]);
    }
  };

  const loadGames = async () => {
    try {
      const factory = new ethers.Contract(
        CONFIG.contracts.disputeGameFactory,
        DISPUTE_GAME_FACTORY_ABI,
        l1Provider
      );

      const gameCount = await factory.gameCount();
      const gameList: GameInfo[] = [];
      
      const maxGames = Math.min(Number(gameCount), 10); // Last 10 games
      for (let i = Number(gameCount) - maxGames; i < Number(gameCount); i++) {
        try {
          const game = await factory.gameAtIndex(i);
          gameList.push({
            index: i,
            gameType: game[0],
            timestamp: Number(game[1]),
            proxy: game[2],
          });
        } catch (e) {
          console.error(`Failed to load game ${i}:`, e);
        }
      }

      setGames(gameList.reverse());
    } catch (error) {
      console.error('Failed to load games:', error);
      setGames([]);
    }
  };

  const loadSystemParams = async () => {
    try {
      const seigManager = new ethers.Contract(
        CONFIG.contracts.seigManager,
        SEIG_MANAGER_ABI,
        l1Provider
      );

      const rat = new ethers.Contract(CONFIG.contracts.rat, RAT_ABI, l1Provider);

      const [migrated, total, active, minColl, penalty, buffer, relaxed, maxVal, evidencePeriod, seqMinStake] = await Promise.all([
        seigManager.v3Migrated(),
        rat.getValidatorCount(CONFIG.contracts.systemConfig),
        rat.getActiveValidatorCount(CONFIG.contracts.systemConfig),
        rat.getDynamicMinimumCollateral(CONFIG.contracts.systemConfig),
        rat.slashingPenalty(),
        rat.validatorBuffer(),
        rat.relaxedValidatorCheck(),
        rat.maxValidatorsPerL2(),
        rat.evidenceSubmissionPeriod(),
        seigManager.minimumAmount(), // Sequencer minimum stake
      ]);

      setV3Migrated(migrated);
      setTotalValidators(Number(total));
      setActiveValidators(Number(active));
      setMinCollateral(ethers.formatUnits(minColl, 27)); // WTON (27 decimals)
      setSequencerMinStake(ethers.formatUnits(seqMinStake, 27)); // WTON (27 decimals)
      setSlashingPenalty(ethers.formatUnits(penalty, 27)); // WTON (27 decimals)
      setValidatorBuffer(ethers.formatUnits(buffer, 27)); // WTON (27 decimals)
      setRelaxedValidatorCheck(relaxed);
      setMaxValidatorsPerL2(Number(maxVal));
      setEvidenceSubmissionPeriod(Number(evidencePeriod));
    } catch (error) {
      console.error('Failed to load system params:', error);
    }
  };

  const loadL2Info = async () => {
    try {
      console.log('🔍 loadL2Info: Starting...');
      const systemConfig = new ethers.Contract(
        CONFIG.contracts.systemConfig,
        SYSTEM_CONFIG_ABI,
        l1Provider
      );

      // L2 체인 정보
      let l2ChainId = 'N/A';
      let l2BlockNumber = 'N/A';
      try {
        const network = await l2Provider.getNetwork();
        l2ChainId = network.chainId.toString();
        l2BlockNumber = (await l2Provider.getBlockNumber()).toString();
        console.log('🔍 loadL2Info: L2 Chain ID:', l2ChainId, 'Block:', l2BlockNumber);
      } catch (e) {
        console.warn('⚠️ L2 not available:', e);
      }

      // SystemConfig에서 정보 가져오기
      const [
        batcherHash,
        unsafeBlockSigner,
        gasLimit,
        l1Bridge,
        portal,
        disputeGameFactory,
        l1CrossDomainMessenger,
        batchInbox,
        overhead,
        scalar,
        basefeeScalar,
        blobbasefeeScalar,
      ] = await Promise.all([
        systemConfig.batcherHash(),
        systemConfig.unsafeBlockSigner(),
        systemConfig.gasLimit(),
        systemConfig.l1StandardBridge(),
        systemConfig.optimismPortal(),
        systemConfig.disputeGameFactory(),
        systemConfig.l1CrossDomainMessenger(),
        systemConfig.batchInbox(),
        systemConfig.overhead().catch(() => '0'),
        systemConfig.scalar().catch(() => '0'),
        systemConfig.basefeeScalar().catch(() => 0),
        systemConfig.blobbasefeeScalar().catch(() => 0),
      ]);

      // Portal 정보
      const portalContract = new ethers.Contract(portal, OPTIMISM_PORTAL_ABI, l1Provider);
      const tonContract = new ethers.Contract(CONFIG.contracts.ton, TON_ABI, l1Provider);
      
      // ETHLockbox 주소 조회
      let ethLockboxAddress = ethers.ZeroAddress;
      let ethLockboxBal = 0n;
      try {
        // Try to get ethLockbox address from OptimismPortal
        ethLockboxAddress = await portalContract.ethLockbox();
        console.log('ETHLockbox address from portal:', ethLockboxAddress);
        
        if (ethLockboxAddress && ethLockboxAddress !== ethers.ZeroAddress) {
          ethLockboxBal = await l1Provider.getBalance(ethLockboxAddress);
          console.log('ETHLockbox balance:', ethers.formatEther(ethLockboxBal), 'ETH');
        }
      } catch (e) {
        console.error('Failed to get ETHLockbox:', e);
        // Fallback: try to get from optimism-addresses.json via config
        // For now, set to zero
      }
      
      const [portalGuardian, portalPaused, portalTonBal, portalEthBal, bridgeTonBal] = await Promise.all([
        portalContract.guardian(),
        portalContract.paused(),
        tonContract.balanceOf(portal),
        l1Provider.getBalance(portal),
        tonContract.balanceOf(l1Bridge),
      ]);

      const l2Data = {
        l2ChainId,
        l2BlockNumber,
        batcherHash,
        unsafeBlockSigner,
        gasLimit: gasLimit.toString(),
        l1Bridge,
        portal,
        disputeGameFactory,
        l1CrossDomainMessenger,
        batchInbox,
        overhead: overhead.toString(),
        scalar: scalar.toString(),
        basefeeScalar: basefeeScalar.toString(),
        blobbasefeeScalar: blobbasefeeScalar.toString(),
        portalGuardian,
        portalPaused,
        portalTonBalance: ethers.formatEther(portalTonBal),
        portalEthBalance: ethers.formatEther(portalEthBal),
        bridgeTonBalance: ethers.formatEther(bridgeTonBal),
        ethLockboxAddress: ethLockboxAddress,
        ethLockboxBalance: ethers.formatEther(ethLockboxBal),
      };
      console.log('✅ loadL2Info: Setting l2Info:', l2Data);
      setL2Info(l2Data);
    } catch (error) {
      console.error('❌ Failed to load L2 info:', error);
    }
  };

  const loadUserBalances = async (addr: string) => {
    try {
      const tonContract = new ethers.Contract(CONFIG.contracts.ton, TON_ABI, l1Provider);
      const wtonContract = new ethers.Contract(CONFIG.contracts.wton, WTON_ABI, l1Provider);
      const seigManager = new ethers.Contract(CONFIG.contracts.seigManager, SEIG_MANAGER_ABI, l1Provider);
      const depositManager = new ethers.Contract(CONFIG.contracts.depositManager, DEPOSIT_MANAGER_ABI, l1Provider);

      const [eth, ton, wton] = await Promise.all([
        l1Provider.getBalance(addr),
        tonContract.balanceOf(addr),
        wtonContract.balanceOf(addr),
      ]);
      
      console.log('Raw balances:', { eth: eth.toString(), ton: ton.toString(), wton: wton.toString() });
      
      const ethFormatted = ethers.formatEther(eth);
      const tonFormatted = ethers.formatEther(ton);
      const wtonFormatted = ethers.formatUnits(wton, 27);
      
      console.log('Formatted balances:', { eth: ethFormatted, ton: tonFormatted, wton: wtonFormatted });
      
      setEthBalance(ethFormatted);
      setTonBalance(tonFormatted);
      setWtonBalance(wtonFormatted); // WTON is 27 decimals

      // Get staked amount if operator manager exists
      if (operatorInfo?.candidateAddOn && operatorInfo.candidateAddOn !== ethers.ZeroAddress) {
        try {
          const staked = await seigManager.stakeOf(operatorInfo.candidateAddOn, addr);
          setStakedAmount(ethers.formatUnits(staked, 27)); // Staked amount is in WTON (27 decimals)
          
          // Get pending unstaked amount
          const pending = await depositManager.pendingUnstaked(operatorInfo.candidateAddOn, addr);
          setPendingUnstaked(ethers.formatUnits(pending, 27)); // WTON (27 decimals)
          
          // Get number of withdrawal requests
          const numReqs = await depositManager.numPendingRequests(operatorInfo.candidateAddOn, addr);
          setWithdrawalRequests(Number(numReqs));
        } catch (e) {
          console.error('Failed to load staking info:', e);
          setStakedAmount('0');
          setPendingUnstaked('0');
          setWithdrawalRequests(0);
        }
      }

      // Load L2 balances
      try {
        const l2Eth = await l2Provider.getBalance(addr);
        setL2EthBalance(ethers.formatEther(l2Eth));

        // L2 TON balance (if L2 TON contract exists)
        if (rollupInfo?.l2Ton && rollupInfo.l2Ton !== ethers.ZeroAddress) {
          const l2TonContract = new ethers.Contract(rollupInfo.l2Ton, TON_ABI, l2Provider);
          const l2Ton = await l2TonContract.balanceOf(addr);
          setL2TonBalance(ethers.formatEther(l2Ton));
        } else {
          setL2TonBalance('0');
        }
      } catch (e) {
        console.error('Failed to load L2 balances:', e);
        setL2EthBalance('0');
        setL2TonBalance('0');
      }
    } catch (error) {
      console.error('Failed to load user balances:', error);
    }
  };

  const loadSeigniorageInfo = async (layer2Address?: string, knownRollupConfig?: string) => {
    try {
      // Use provided address or selected address or default to candidateAddOn
      const targetLayer2 = layer2Address || selectedLayer2 || operatorInfo?.candidateAddOn;

      console.log('Loading seigniorage info for:', targetLayer2);

      if (!targetLayer2 || targetLayer2 === ethers.ZeroAddress) {
        console.log('No valid layer2 address');
        setSeigniorageInfo(null);
        return;
      }

      const seigManager = new ethers.Contract(CONFIG.contracts.seigManager, SEIG_MANAGER_ABI, l1Provider);
      const layer2Manager = new ethers.Contract(CONFIG.contracts.layer2Manager, LAYER2_MANAGER_ABI, l1Provider);
      const layer2Registry = new ethers.Contract(CONFIG.contracts.layer2Registry, LAYER2_REGISTRY_ABI, l1Provider);

      // 기본 정보 조회
      const [
        lastSeigBlock,
        currentBlock,
        bridgedTon,
        effectiveBridgedTon,
        totalEffectiveBridgedTon,
        claimableAmount,
        isPaused,
        isRegistered,
        seigPerBlock,
        daoDistributionRatio,
        minStakingRatio,
        validatorDistributionRatio,
        halfSaturationPoint,
        bridgedTONRewardPerUint,
        validatorRewardPerUint,
      ] = await Promise.all([
        seigManager.lastSeigBlock(),
        l1Provider.getBlockNumber(),
        layer2Manager.getBridgedTonByLayer(targetLayer2),
        seigManager.getEffectiveBridgedTon(targetLayer2),
        seigManager.totalEffectiveBridgedTON(),
        seigManager.claimableL2Seigniorage(targetLayer2),
        seigManager.paused(),
        layer2Registry.layer2s(targetLayer2),
        seigManager.seigPerBlock(),
        seigManager.daoDistributionRatio(),
        seigManager.minStakingRatio(),
        seigManager.validatorDistributionRatio(),
        seigManager.halfSaturationPoint(),
        seigManager.bridgedTONRewardPerUint(),
        seigManager.validatorRewardPerUint(),
      ]);

      // checkCurrentEligibility는 별도 처리 (실패할 수 있음)
      let eligibilityInfo: [boolean, any, any] = [false, 0n, 0n];
      try {
        eligibilityInfo = await seigManager.checkCurrentEligibility(targetLayer2);
      } catch (e: any) {
        console.warn('checkCurrentEligibility failed (expected for some setups):', e?.message || e);
      }

      // RollupConfig 및 추가 정보 조회
      let rollupConfig = ethers.ZeroAddress;
      let layer2Status = 0;
      let operatorManagerAddress = ethers.ZeroAddress;
      let operatorManagerBalance = '0';
      let operatorManagerManager = ethers.ZeroAddress;
      let systemConfigSigner = ethers.ZeroAddress;
      let signersMatch = false;

      try {
        // Resolve rollupConfig: use provided value, check operatorInfo, or try contract lookup
        if (knownRollupConfig && knownRollupConfig !== ethers.ZeroAddress) {
          rollupConfig = knownRollupConfig;
        } else if (operatorInfo?.candidateAddOn?.toLowerCase() === targetLayer2.toLowerCase()) {
          rollupConfig = CONFIG.contracts.systemConfig;
        } else {
          // Try getRollupConfig (may fail for addresses not in the mapping)
          try {
            rollupConfig = await layer2Manager.getRollupConfig(targetLayer2);
          } catch {
            // Fallback: check if systemConfig's operator matches this layer2
            try {
              const opMgr = await layer2Manager.operatorOfRollupConfig(CONFIG.contracts.systemConfig);
              if (opMgr !== ethers.ZeroAddress) {
                const candidateAddr = await layer2Manager.candidateAddOnOfOperator(opMgr);
                if (candidateAddr.toLowerCase() === targetLayer2.toLowerCase()) {
                  rollupConfig = CONFIG.contracts.systemConfig;
                }
              }
            } catch {
              console.warn('Fallback rollupConfig resolution also failed');
            }
          }
        }

        if (rollupConfig !== ethers.ZeroAddress) {
          layer2Status = Number(await layer2Manager.statusLayer2(rollupConfig));
          
          // OperatorManager 정보 조회
          const operatorManager = await layer2Manager.operatorOfRollupConfig(rollupConfig);
          if (operatorManager !== ethers.ZeroAddress) {
            operatorManagerAddress = operatorManager;
            const opManagerContract = new ethers.Contract(operatorManager, OPERATOR_MANAGER_ABI, l1Provider);
            const wtonContract = new ethers.Contract(CONFIG.contracts.wton, WTON_ABI, l1Provider);
            
            const [opBalance, opManager] = await Promise.all([
              wtonContract.balanceOf(operatorManager),
              opManagerContract.manager().catch(() => ethers.ZeroAddress),
            ]);
            operatorManagerBalance = opBalance;
            operatorManagerManager = opManager;
          }
          
          // SystemConfig의 unsafeBlockSigner 조회
          const systemConfigContract = new ethers.Contract(rollupConfig, SYSTEM_CONFIG_ABI, l1Provider);
          systemConfigSigner = await systemConfigContract.unsafeBlockSigner().catch(() => ethers.ZeroAddress);
          
          // Manager와 Signer가 같은지 확인
          signersMatch = operatorManagerManager.toLowerCase() === systemConfigSigner.toLowerCase();
        }
      } catch (e) {
        console.warn('Failed to load additional layer2 info:', e);
      }

      const info = {
        lastSeigBlock: lastSeigBlock.toString(),
        currentBlock: currentBlock.toString(),
        bridgedTon: ethers.formatEther(bridgedTon), // TON is 18 decimals
        effectiveBridgedTon: ethers.formatUnits(effectiveBridgedTon, 27), // WTON is 27 decimals
        totalEffectiveBridgedTon: ethers.formatUnits(totalEffectiveBridgedTon, 27), // WTON is 27 decimals
        isEligible: eligibilityInfo[0],
        requiredStake: ethers.formatUnits(eligibilityInfo[1], 27), // WTON is 27 decimals
        currentStake: ethers.formatUnits(eligibilityInfo[2], 27), // WTON is 27 decimals
        claimableAmount: ethers.formatUnits(claimableAmount, 27), // WTON is 27 decimals
        isPaused: isPaused,
        // 추가 정보
        isRegistered: isRegistered,
        layer2Status: layer2Status,
        rollupConfig: rollupConfig,
        operatorManagerAddress: operatorManagerAddress,
        operatorManagerBalance: ethers.formatUnits(operatorManagerBalance, 27), // WTON is 27 decimals
        operatorManagerManager: operatorManagerManager,
        systemConfigSigner: systemConfigSigner,
        signersMatch: signersMatch,
        // 시뇨리지 발행 팩터들
        seigPerBlock: ethers.formatUnits(seigPerBlock, 27), // WTON is 27 decimals
        daoDistributionRatio: (Number(daoDistributionRatio) / 1e27 * 100).toFixed(2), // RAY to percentage
        minStakingRatio: (Number(minStakingRatio) / 1e27 * 100).toFixed(2),
        validatorDistributionRatio: (Number(validatorDistributionRatio) / 1e27 * 100).toFixed(2),
        halfSaturationPoint: ethers.formatUnits(halfSaturationPoint, 27), // WTON 27 decimals (same value as TON)
        bridgedTONRewardPerUint: ethers.formatUnits(bridgedTONRewardPerUint, 27), // WEI_UNIT (27 decimals)
        validatorRewardPerUint: ethers.formatUnits(validatorRewardPerUint, 27),
      };
      
      console.log('Seigniorage info loaded:', info);
      setSeigniorageInfo(info);
    } catch (error) {
      console.error('Failed to load seigniorage info:', error);
      setSeigniorageInfo(null);
    }
  };

  // ===== Enhanced monitoring load functions =====

  const loadSyncStatus = async (): Promise<SyncStatus | null> => {
    try {
      const response = await fetch(CONFIG.opNodeRpcUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ jsonrpc: '2.0', method: 'optimism_syncStatus', params: [], id: 1 }),
      });
      const data = await response.json();
      if (data.result) {
        const ss: SyncStatus = {
          currentL1: { number: data.result.current_l1?.number || 0, hash: data.result.current_l1?.hash || '' },
          unsafeL2: { number: data.result.unsafe_l2?.number || 0, hash: data.result.unsafe_l2?.hash || '' },
          safeL2: { number: data.result.safe_l2?.number || 0, hash: data.result.safe_l2?.hash || '' },
          finalizedL2: { number: data.result.finalized_l2?.number || 0, hash: data.result.finalized_l2?.hash || '' },
        };
        return ss;
      }
    } catch (e) {
      console.warn('op-node sync status unavailable:', e);
    }
    return null;
  };

  const loadAttentionTests = async () => {
    try {
      const rat = new ethers.Contract(CONFIG.contracts.rat, RAT_ABI, l1Provider);
      const factory = new ethers.Contract(CONFIG.contracts.disputeGameFactory, DISPUTE_GAME_FACTORY_ABI, l1Provider);
      const systemConfig = CONFIG.contracts.systemConfig;
      const statusLabels: Record<number, string> = {
        0: '-',
        1: 'Awaiting Evidence',
        2: 'Challenge Period',
        3: 'Refunded (Evidence)',
        4: 'Refunded (Challenge Won)',
        5: 'Slashed'
      };

      // batchToTestId(systemConfig, batchIndex) 스토리지를 순회하여 어텐션 테스트 조회
      const gameCount = await factory.gameCount();
      const maxBatchIndex = Number(gameCount);
      const tests: AttentionTestInfo[] = [];
      let consecutiveEmpty = 0;

      for (let i = 0; i < maxBatchIndex && consecutiveEmpty < 5; i++) {
        try {
          const testId = await rat.batchToTestId(systemConfig, i);
          if (!testId || testId === ethers.ZeroHash) {
            consecutiveEmpty++;
            continue;
          }
          consecutiveEmpty = 0;
          const testData = await rat.getAttentionTest(testId);
          tests.push({
            testId,
            validator: testData[0],        // validatorAddress
            systemConfig: testData[1],     // systemConfig
            batchIndex: Number(testData[2]), // batchIndex
            batchHash: testData[3],        // batchHash
            bondAmount: ethers.formatUnits(testData[4], 27), // bondAmount
            createdAt: Number(testData[5]), // createdAt
            deadline: Number(testData[6]), // deadline
            status: Number(testData[7]),   // status
            statusLabel: statusLabels[Number(testData[7])] || 'Unknown',
            gameAddress: '',
          });
        } catch (e) {
          consecutiveEmpty++;
        }
      }

      // 최신순 정렬 (deadline 기준)
      tests.sort((a, b) => b.deadline - a.deadline);
      setAttentionTests(tests);
    } catch (e) {
      console.warn('Failed to load attention tests:', e);
      setAttentionTests([]);
    }
  };

  const loadValidatorEvents = async () => {
    try {
      const rat = new ethers.Contract(CONFIG.contracts.rat, RAT_ABI, l1Provider);
      const currentBlock = await l1Provider.getBlockNumber();
      const fromBlock = Math.max(0, currentBlock - 2000);

      const [evidenceEvents, slashedEvents, restoredEvents] = await Promise.all([
        rat.queryFilter(rat.filters.EvidenceSubmitted(), fromBlock, currentBlock).catch(() => []),
        rat.queryFilter(rat.filters.ValidatorSlashed(), fromBlock, currentBlock).catch(() => []),
        rat.queryFilter(rat.filters.BondRestored(), fromBlock, currentBlock).catch(() => []),
      ]);

      const allEvents: {type: string; validator: string; amount: string; testId: string; blockNumber: number; timestamp: number}[] = [];

      for (const ev of evidenceEvents) {
        const log = ev as ethers.EventLog;
        const block = await l1Provider.getBlock(log.blockNumber);
        allEvents.push({
          type: 'EvidenceSubmitted',
          validator: log.args[1],
          amount: '0',
          testId: log.args[0],
          blockNumber: log.blockNumber,
          timestamp: block?.timestamp || 0,
        });
      }
      for (const ev of slashedEvents) {
        const log = ev as ethers.EventLog;
        const block = await l1Provider.getBlock(log.blockNumber);
        allEvents.push({
          type: 'ValidatorSlashed',
          validator: log.args[1],
          amount: ethers.formatUnits(log.args[4], 27),  // slashedAmount (5th arg)
          testId: log.args[0],
          blockNumber: log.blockNumber,
          timestamp: block?.timestamp || 0,
        });
      }
      for (const ev of restoredEvents) {
        const log = ev as ethers.EventLog;
        const block = await l1Provider.getBlock(log.blockNumber);
        allEvents.push({
          type: 'BondRestored',
          validator: log.args[1],
          amount: ethers.formatUnits(log.args[4], 27),  // restoredAmount (5th arg)
          testId: log.args[0],
          blockNumber: log.blockNumber,
          timestamp: block?.timestamp || 0,
        });
      }

      allEvents.sort((a, b) => b.blockNumber - a.blockNumber);
      setValidatorEvents(allEvents.slice(0, 30));
    } catch (e) {
      console.warn('Failed to load validator events:', e);
      setValidatorEvents([]);
    }
  };

  const loadBLSInfo = async () => {
    try {
      const rat = new ethers.Contract(CONFIG.contracts.rat, RAT_ABI, l1Provider);
      const [blsVals, minFW] = await Promise.all([
        rat.getActiveValidatorsWithBLS(CONFIG.contracts.systemConfig).catch(() => []),
        rat.minValidatorsForFastWithdrawal().catch(() => 0),
      ]);
      setBlsValidators(Array.from(blsVals).map((v: any) => v.toLowerCase()));
      setMinValidatorsForFW(Number(minFW));
    } catch (e) {
      console.warn('Failed to load BLS info:', e);
    }
  };

  const loadEnhancedGames = async (): Promise<EnhancedGameInfo[]> => {
    try {
      const factory = new ethers.Contract(CONFIG.contracts.disputeGameFactory, DISPUTE_GAME_FACTORY_ABI, l1Provider);
      const rat = new ethers.Contract(CONFIG.contracts.rat, RAT_ABI, l1Provider);

      const gameCount = await factory.gameCount();
      const total = Number(gameCount);
      const maxGames = Math.min(total, 20);
      const enhanced: EnhancedGameInfo[] = [];

      // Load factory info
      try {
        const [gameImpl, initBond] = await Promise.all([
          factory.gameImpls(0).catch(() => ethers.ZeroAddress),
          factory.initBonds(0).catch(() => 0n),
        ]);
        setFactoryInfo({
          gameImpl,
          initBond: ethers.formatEther(initBond),
        });
      } catch (e) {
        console.warn('Failed to load factory info:', e);
      }

      // Load FastWithdrawalExecuted events to match games
      const fwGameSet = new Set<string>();
      try {
        const fwFilter = rat.filters.FastWithdrawalExecuted();
        const fwEvents = await rat.queryFilter(fwFilter);
        for (const ev of fwEvents) {
          const parsed = rat.interface.parseLog({ topics: ev.topics as string[], data: ev.data });
          if (parsed) {
            fwGameSet.add(parsed.args[0].toLowerCase()); // gameProxy address
          }
        }
      } catch (e) {
        console.warn('Failed to load FW events:', e);
      }

      for (let i = total - maxGames; i < total; i++) {
        try {
          const game = await factory.gameAtIndex(i);
          const gameProxy = new ethers.Contract(game[2], DISPUTE_GAME_ABI, l1Provider);

          const [rootClaim, status, l2Block, claimCount] = await Promise.all([
            gameProxy.rootClaim().catch(() => ethers.ZeroHash),
            gameProxy.status().catch(() => 0),
            gameProxy.l2BlockNumber().catch(() => 0),
            gameProxy.claimDataLen().catch(() => 0),
          ]);

          let ratTestId = '';
          try {
            ratTestId = await rat.gameToTestId(game[2]);
            if (ratTestId === ethers.ZeroHash) ratTestId = '';
          } catch {
            // no RAT test linked
          }

          enhanced.push({
            index: i,
            gameType: Number(game[0]),
            timestamp: Number(game[1]),
            proxy: game[2],
            rootClaim,
            status: Number(status),
            l2BlockNumber: Number(l2Block),
            claimCount: Number(claimCount),
            ratTestId,
            hasFastWithdrawal: fwGameSet.has(game[2].toLowerCase()),
          });
        } catch (e) {
          console.warn(`Failed to load enhanced game ${i}:`, e);
        }
      }

      const result = enhanced.reverse();
      setEnhancedGames(result);

      // Compute game status summary
      const summary: GameStatusSummary = { total: result.length, inProgress: 0, challengerWins: 0, defenderWins: 0 };
      for (const g of result) {
        if (g.status === 0) summary.inProgress++;
        else if (g.status === 1) summary.challengerWins++;
        else if (g.status === 2) summary.defenderWins++;
      }
      setGameStatusSummary(summary);

      return result;
    } catch (e) {
      console.warn('Failed to load enhanced games:', e);
      setEnhancedGames([]);
      return [];
    }
  };

  const loadGameDetail = async (game: EnhancedGameInfo) => {
    try {
      const gameProxy = new ethers.Contract(game.proxy, DISPUTE_GAME_ABI, l1Provider);
      const rat = new ethers.Contract(CONFIG.contracts.rat, RAT_ABI, l1Provider);

      const [createdAt, resolvedAt, maxClockDuration, startingBlockNumber] = await Promise.all([
        gameProxy.createdAt().catch(() => 0),
        gameProxy.resolvedAt().catch(() => 0),
        gameProxy.maxClockDuration().catch(() => 0),
        gameProxy.startingBlockNumber().catch(() => 0),
      ]);

      // Load claim data (max 50)
      const claimCount = Math.min(game.claimCount, 50);
      const claims: ClaimDataInfo[] = [];
      for (let i = 0; i < claimCount; i++) {
        try {
          const cd = await gameProxy.claimData(i);
          claims.push({
            index: i,
            parentIndex: Number(cd[0]),
            counteredBy: cd[1],
            claimant: cd[2],
            bond: ethers.formatEther(cd[3]),
            claim: cd[4],
            position: Number(cd[5]),
            clock: Number(cd[6]),
          });
        } catch {
          break;
        }
      }

      // Load RAT test detail if linked
      let ratTestDetail: AttentionTestInfo | null = null;
      if (game.ratTestId) {
        try {
          const testData = await rat.getAttentionTest(game.ratTestId);
          const statusLabels: Record<number, string> = {
            0: '-',
            1: 'Awaiting Evidence',
            2: 'Challenge Period',
            3: 'Refunded (Evidence)',
            4: 'Refunded (Challenge Won)',
            5: 'Slashed'
          };
          ratTestDetail = {
            testId: game.ratTestId,
            validator: testData[0],        // validatorAddress
            systemConfig: testData[1],     // systemConfig
            batchIndex: Number(testData[2]), // batchIndex
            batchHash: testData[3],        // batchHash
            bondAmount: ethers.formatUnits(testData[4], 27), // bondAmount
            createdAt: Number(testData[5]), // createdAt
            deadline: Number(testData[6]), // deadline
            status: Number(testData[7]),   // status
            statusLabel: statusLabels[Number(testData[7])] || 'Unknown',
            gameAddress: game.proxy,
          };
        } catch {
          // no RAT test detail
        }
      }

      // Get proposer bond info from first claim (proposer is claim[0].claimant)
      let proposerBond = '0';
      let proposerCredit = '0';
      let proposerAddr = '';
      if (claims.length > 0) {
        proposerAddr = claims[0].claimant;
        proposerBond = claims[0].bond;
        try {
          const creditWei = await gameProxy.credit(proposerAddr);
          proposerCredit = ethers.formatEther(creditWei);
        } catch {
          // credit not available (game not resolved yet)
        }
      }

      const detail: GameDetailInfo = {
        ...game,
        createdAt: Number(createdAt),
        resolvedAt: Number(resolvedAt),
        maxClockDuration: Number(maxClockDuration),
        startingBlockNumber: Number(startingBlockNumber),
        claims,
        ratTestDetail,
        proposerBond,
        proposerCredit,
        proposerAddress: proposerAddr,
      };
      setSelectedGameDetail(detail);
    } catch (e) {
      console.warn('Failed to load game detail:', e);
    }
  };

  const loadProposerInfo = async () => {
    try {
      const ss = await loadSyncStatus();
      const eg = await loadEnhancedGames();

      const factory = new ethers.Contract(CONFIG.contracts.disputeGameFactory, DISPUTE_GAME_FACTORY_ABI, l1Provider);
      const totalGames = Number(await factory.gameCount());

      const now = Math.floor(Date.now() / 1000);
      const gamesLast1h = eg.filter(g => now - g.timestamp < 3600).length;
      const gamesLast24h = eg.filter(g => now - g.timestamp < 86400).length;

      let averageInterval = 0;
      let gameIntervals: number[] = [];
      if (eg.length >= 2) {
        const sorted = [...eg].sort((a, b) => a.timestamp - b.timestamp);
        gameIntervals = sorted.slice(1).map((g, i) => g.timestamp - sorted[i].timestamp);
        averageInterval = gameIntervals.reduce((a, b) => a + b, 0) / gameIntervals.length;
      }

      const latestGame = eg.length > 0 ? eg[0] : null;
      const latestL2Block = latestGame?.l2BlockNumber || 0;
      const safeL2 = ss?.safeL2?.number || 0;
      const lag = safeL2 - latestL2Block;
      const lastGameAge = latestGame ? now - latestGame.timestamp : 0;

      // Proposer address: primary source is CONFIG (from docker-compose private key)
      // If games exist, verify by reading claimData(0).claimant from latest game
      let proposerAddress = CONFIG.proposerAddress || '';
      let proposerAddressSource = proposerAddress ? 'config' : '';
      let proposerEthBalance = '0';

      // If games exist, get the actual proposer from the game's root claim (claimant)
      if (latestGame) {
        try {
          const gameProxy = new ethers.Contract(latestGame.proxy, DISPUTE_GAME_ABI, l1Provider);
          const rootClaimData = await gameProxy.claimData(0);
          const claimant = rootClaimData[2]; // claimant field
          if (claimant && claimant !== ethers.ZeroAddress) {
            proposerAddress = claimant;
            proposerAddressSource = 'claimant';
          }
        } catch {
          // fallback to config address
        }
      }

      if (proposerAddress && proposerAddress !== ethers.ZeroAddress) {
        try {
          const bal = await l1Provider.getBalance(proposerAddress);
          proposerEthBalance = ethers.formatEther(bal);
        } catch {
          // ignore
        }
      }

      // Get factory info: initBond and gameType
      let initBond = '0';
      let gameType = 0;
      try {
        const [bond, impl] = await Promise.all([
          factory.initBonds(0).catch(() => 0n),
          factory.gameImpls(0).catch(() => ethers.ZeroAddress),
        ]);
        initBond = ethers.formatEther(bond);
        // gameType 0 is the default FaultDisputeGame
        gameType = impl !== ethers.ZeroAddress ? 0 : -1;
      } catch {
        // ignore
      }

      // Infer actual proposal interval from the median of game intervals
      let inferredProposalInterval = 0;
      if (gameIntervals.length > 0) {
        const sortedIntervals = [...gameIntervals].sort((a, b) => a - b);
        inferredProposalInterval = sortedIntervals[Math.floor(sortedIntervals.length / 2)]; // median
      }

      // Build output roots from enhanced games
      const sorted = [...eg].sort((a, b) => a.index - b.index);
      const outputRoots = sorted.map((g, idx) => {
        const prevBlock = idx > 0 ? sorted[idx - 1].l2BlockNumber : 0;
        return {
          index: g.index,
          l2Block: g.l2BlockNumber,
          rootClaim: g.rootClaim,
          blockRange: `${prevBlock + 1} - ${g.l2BlockNumber}`,
        };
      });

      setProposerInfo({
        totalGames,
        latestGame,
        syncStatus: ss,
        gamesLast1h,
        gamesLast24h,
        averageInterval: Math.round(averageInterval),
        lag,
        isHealthy: totalGames > 0 && (latestGame ? (now - latestGame.timestamp < 600) : false),
        recentGames: eg.slice(0, 10),
        proposerAddress,
        proposerAddressSource,
        gameIntervals,
        outputRoots,
        ethBalance: proposerEthBalance,
        lastGameAge,
        initBond,
        gameType,
        inferredProposalInterval,
      });
    } catch (e) {
      console.warn('Failed to load proposer info:', e);
    }
  };

  const loadBatcherInfo = async () => {
    try {
      const ss = await loadSyncStatus();

      // Get batcher address from l2Info.batcherHash
      if (!l2Info) return;
      const batcherAddr = '0x' + l2Info.batcherHash.slice(-40);
      const batchInboxAddr = l2Info.batchInbox;

      const [ethBal, nonce] = await Promise.all([
        l1Provider.getBalance(batcherAddr),
        l1Provider.getTransactionCount(batcherAddr),
      ]);

      const safeLag = (ss?.unsafeL2?.number || 0) - (ss?.safeL2?.number || 0);

      // Scan last 50 L1 blocks for batcher -> batchInbox txs
      const currentBlock = await l1Provider.getBlockNumber();
      const batchTxs: BatchTxInfo[] = [];

      for (let i = 0; i < 50 && batchTxs.length < 20; i++) {
        const blockNum = currentBlock - i;
        if (blockNum < 0) break;
        try {
          const block = await l1Provider.getBlock(blockNum, true);
          if (!block) continue;
          for (const txHash of block.transactions) {
            const hash = typeof txHash === 'string' ? txHash : (txHash as any).hash;
            try {
              const tx = await l1Provider.getTransaction(hash);
              if (tx && tx.from.toLowerCase() === batcherAddr.toLowerCase() &&
                  tx.to?.toLowerCase() === batchInboxAddr.toLowerCase()) {
                const receipt = await l1Provider.getTransactionReceipt(hash);
                batchTxs.push({
                  hash: tx.hash,
                  blockNumber: tx.blockNumber || blockNum,
                  timestamp: block.timestamp,
                  gasUsed: receipt?.gasUsed?.toString() || '0',
                  dataSize: tx.data ? Math.floor((tx.data.length - 2) / 2) : 0,
                  type: tx.type ?? 0,
                });
              }
            } catch {
              // skip tx
            }
          }
        } catch {
          // skip block
        }
      }

      // Compute batch metrics
      let avgBatchInterval = 0;
      let totalDataBytes = 0;
      let avgDataPerTx = 0;
      let avgGasPerTx = 0;
      let daType = 'calldata';

      if (batchTxs.length > 0) {
        totalDataBytes = batchTxs.reduce((sum, tx) => sum + tx.dataSize, 0);
        avgDataPerTx = Math.round(totalDataBytes / batchTxs.length);
        const totalGas = batchTxs.reduce((sum, tx) => sum + parseInt(tx.gasUsed), 0);
        avgGasPerTx = Math.round(totalGas / batchTxs.length);

        // Detect DA type from tx types
        const hasBlobTx = batchTxs.some(tx => tx.type === 3);
        daType = hasBlobTx ? 'blobs' : 'calldata';

        if (batchTxs.length >= 2) {
          const sorted = [...batchTxs].sort((a, b) => a.timestamp - b.timestamp);
          const intervals = sorted.slice(1).map((tx, i) => tx.timestamp - sorted[i].timestamp);
          avgBatchInterval = Math.round(intervals.reduce((a, b) => a + b, 0) / intervals.length);
        }
      }

      setBatcherInfo({
        address: batcherAddr,
        ethBalance: ethers.formatEther(ethBal),
        nonce,
        syncStatus: ss,
        safeLag,
        recentBatchTxs: batchTxs,
        isHealthy: safeLag < 50,
        batchInbox: batchInboxAddr,
        avgBatchInterval,
        totalDataBytes,
        avgDataPerTx,
        avgGasPerTx,
        txCount: batchTxs.length,
        daType,
      });
    } catch (e) {
      console.warn('Failed to load batcher info:', e);
    }
  };

  const loadGameWithdrawalSettings = async () => {
    try {
      const dgfAddress = CONFIG.contracts.disputeGameFactory;
      const portalAddress = l2Info?.portal || '';
      const ratAddress = CONFIG.contracts.rat;

      const dgf = new ethers.Contract(dgfAddress, DISPUTE_GAME_FACTORY_ABI, l1Provider);

      // 1. Get game impl and init bond from factory
      const [gameImplAddress, initBond, gameCount] = await Promise.all([
        dgf.gameImpls(0),
        dgf.initBonds(0),
        dgf.gameCount(),
      ]);

      // 2. Determine which address to use for immutable reads (proxy preferred)
      let gameProxy = '';
      let gameReadAddress = gameImplAddress;
      if (Number(gameCount) > 0) {
        const [, , proxy] = await dgf.gameAtIndex(0);
        gameProxy = proxy;
        gameReadAddress = proxy;
      }

      // 3. Read game immutable values
      const gameContract = new ethers.Contract(gameReadAddress, DISPUTE_GAME_ABI, l1Provider);
      const [maxClockDuration, clockExtension, maxGameDepth, splitDepth, absolutePrestate, l2ChainId, wethAddress] = await Promise.all([
        gameContract.maxClockDuration(),
        gameContract.clockExtension(),
        gameContract.maxGameDepth(),
        gameContract.splitDepth(),
        gameContract.absolutePrestate(),
        gameContract.l2ChainId(),
        gameContract.weth(),
      ]);

      // 4. DelayedWETH delay
      const wethContract = new ethers.Contract(wethAddress, DELAYED_WETH_ABI, l1Provider);
      const wethDelay = await wethContract.delay();

      // 5. Portal settings
      const portal = new ethers.Contract(portalAddress, OPTIMISM_PORTAL_ABI, l1Provider);
      const [proofMaturityDelay, disputeGameFinalityDelay, fastWithdrawalResp, ratContractOnPortal, seigManagerOnPortal] = await Promise.all([
        portal.proofMaturityDelaySeconds(),
        portal.disputeGameFinalityDelaySeconds(),
        portal.fastWithdrawalResponsePeriod(),
        portal.ratContract(),
        portal.seigManager(),
      ]);

      // 6. RAT settings
      const rat = new ethers.Contract(ratAddress, RAT_ABI, l1Provider);
      const [evidencePeriod, minValFW] = await Promise.all([
        rat.evidenceSubmissionPeriod(),
        rat.minValidatorsForFastWithdrawal(),
      ]);

      setGameWithdrawalSettings({
        gameProxy,
        gameImplAddress,
        maxClockDuration: Number(maxClockDuration),
        clockExtension: Number(clockExtension),
        maxGameDepth: Number(maxGameDepth),
        splitDepth: Number(splitDepth),
        absolutePrestate,
        l2ChainId: Number(l2ChainId),
        wethAddress,
        wethDelay: Number(wethDelay),
        portalAddress,
        proofMaturityDelay: Number(proofMaturityDelay),
        disputeGameFinalityDelay: Number(disputeGameFinalityDelay),
        fastWithdrawalResponsePeriod: Number(fastWithdrawalResp),
        ratContractOnPortal,
        seigManagerOnPortal,
        dgfAddress,
        initBond: ethers.formatEther(initBond),
        ratAddress,
        evidenceSubmissionPeriod: Number(evidencePeriod),
        minValidatorsForFW: Number(minValFW),
      });
    } catch (e) {
      console.warn('Failed to load game/withdrawal settings:', e);
    }
  };

  const handleAddCollateral = async (amount: string) => {
    if (!signer || !amount || parseFloat(amount) <= 0) {
      alert('Please enter a valid amount');
      return;
    }
    
    try {
      setLoading(true);
      const amountWei = ethers.parseUnits(amount, 27); // WTON is 27 decimals
      
      // 1. Approve WTON to DepositManager
      const wtonContract = new ethers.Contract(CONFIG.contracts.wton, WTON_ABI, signer);
      const approveTx = await wtonContract.approve(CONFIG.contracts.depositManager, amountWei);
      await approveTx.wait();
      
      // 2. Deposit to CandidateAddOn (Layer2) via DepositManager
      // deposit(layer2, account, amount) - stakes in account's name
      // - layer2: CandidateAddOn address
      // - account: OperatorManager address (so it's staked in sequencer's name)
      const layer2Address = operatorInfo?.candidateAddOn;
      const operatorManagerAddress = operatorInfo?.operatorManager;
      if (!layer2Address || layer2Address === ethers.ZeroAddress) {
        throw new Error('CandidateAddOn (Layer2) address not found');
      }
      if (!operatorManagerAddress || operatorManagerAddress === ethers.ZeroAddress) {
        throw new Error('OperatorManager address not found');
      }
      const depositManager = new ethers.Contract(CONFIG.contracts.depositManager, DEPOSIT_MANAGER_ABI, signer);
      const depositTx = await depositManager['deposit(address,address,uint256)'](layer2Address, operatorManagerAddress, amountWei);
      await depositTx.wait();
      
      alert('Collateral added successfully!');
      await loadDashboardData();
      if (address) await loadUserBalances(address);
    } catch (error: any) {
      console.error('Failed to add collateral:', error);
      alert(`Failed: ${error.message || 'Unknown error'}`);
    } finally {
      setLoading(false);
    }
  };

  // ========================
  // Withdrawal Tracker Functions
  // ========================

  const lookupWithdrawalFromL2Tx = async (l2TxHash: string): Promise<WithdrawalInfo | null> => {
    try {
      const receipt = await l2Provider.getTransactionReceipt(l2TxHash);
      if (!receipt) throw new Error('L2 transaction not found');

      const iface = new ethers.Interface(L2_TO_L1_MESSAGE_PASSER_ABI);
      for (const log of receipt.logs) {
        if (log.address.toLowerCase() !== L2_TO_L1_MESSAGE_PASSER.toLowerCase()) continue;
        try {
          const parsed = iface.parseLog({ topics: log.topics as string[], data: log.data });
          if (parsed && parsed.name === 'MessagePassed') {
            return {
              l2TxHash,
              l2BlockNumber: receipt.blockNumber,
              nonce: parsed.args[0],
              sender: parsed.args[1],
              target: parsed.args[2],
              value: parsed.args[3],
              gasLimit: parsed.args[4],
              data: parsed.args[5],
              withdrawalHash: parsed.args[6],
              status: 'initiated',
              statusMessage: 'Withdrawal initiated on L2',
              nextAction: 'Checking status...',
            };
          }
        } catch {
          // not a MessagePassed log
        }
      }
      throw new Error('No MessagePassed event found in this transaction');
    } catch (error: any) {
      throw new Error(`Failed to lookup L2 tx: ${error.message}`);
    }
  };

  const findCoveringGame = async (l2BlockNumber: number): Promise<{ gameIndex: number; gameProxy: string; gameL2Block: number; gameType: number; gameStatus: number; isRespected: boolean } | null> => {
    try {
      if (!l2Info?.portal) return null;
      const factory = new ethers.Contract(CONFIG.contracts.disputeGameFactory, DISPUTE_GAME_FACTORY_ABI, l1Provider);
      const portal = new ethers.Contract(l2Info.portal, OPTIMISM_PORTAL_ABI, l1Provider);

      const [gameCount, respectedType] = await Promise.all([
        factory.gameCount(),
        portal.respectedGameType().catch(() => 0),
      ]);
      const total = Number(gameCount);
      const respectedGameType = Number(respectedType);
      if (total === 0) return null;

      console.log(`findCoveringGame: total=${total}, respectedGameType=${respectedGameType}, targetL2Block=${l2BlockNumber}`);

      // Search backwards from the latest game
      const searchCount = Math.min(total, 50);
      for (let i = total - 1; i >= total - searchCount; i--) {
        try {
          const game = await factory.gameAtIndex(i);
          const gameType = Number(game[0]);
          const gameContract = new ethers.Contract(game[2], DISPUTE_GAME_ABI, l1Provider);
          const [gameL2Block, gameStatus] = await Promise.all([
            gameContract.l2BlockNumber(),
            gameContract.status(),
          ]);
          const l2Block = Number(gameL2Block);
          const status = Number(gameStatus);

          // Skip games that resolved as CHALLENGER_WINS (status 1)
          if (status === 1) continue;

          if (l2Block >= l2BlockNumber) {
            const isRespected = gameType === respectedGameType;
            console.log(`findCoveringGame: found game #${i}, type=${gameType}, l2Block=${l2Block}, status=${status}, respected=${isRespected}`);
            return { gameIndex: i, gameProxy: game[2], gameL2Block: l2Block, gameType, gameStatus: status, isRespected };
          }
        } catch {
          continue;
        }
      }
      return null;
    } catch (error) {
      console.error('findCoveringGame error:', error);
      return null;
    }
  };

  const checkWithdrawalStatus = async (withdrawal: WithdrawalInfo): Promise<WithdrawalInfo> => {
    try {
      if (!l2Info?.portal) throw new Error('Portal address not available');

      const portal = new ethers.Contract(l2Info.portal, OPTIMISM_PORTAL_ABI, l1Provider);
      const updated = { ...withdrawal };

      // 1. Check if finalized
      const [isFinalized, isFastFinalized] = await Promise.all([
        portal.finalizedWithdrawals(withdrawal.withdrawalHash).catch(() => false),
        portal.fastFinalizedWithdrawals(withdrawal.withdrawalHash).catch(() => false),
      ]);

      if (isFastFinalized) {
        updated.status = 'fast_finalized';
        updated.statusMessage = 'Fast withdrawal finalized';
        updated.nextAction = 'Complete';
        updated.isFastFinalized = true;
        return updated;
      }
      if (isFinalized) {
        updated.status = 'finalized';
        updated.statusMessage = 'Withdrawal finalized';
        updated.nextAction = 'Complete';
        return updated;
      }

      // 2. Check if proven
      const userAddr = address || withdrawal.sender;
      const proven = await portal.provenWithdrawals(withdrawal.withdrawalHash, userAddr).catch(() => null);

      if (proven && proven.timestamp > 0n) {
        updated.provenTimestamp = Number(proven.timestamp);
        updated.provenGameProxy = proven.disputeGameProxy;

        // Check proof maturity and game resolution
        const [maturityDelay, finalityDelay] = await Promise.all([
          portal.proofMaturityDelaySeconds().catch(() => 0n),
          portal.disputeGameFinalityDelaySeconds().catch(() => 0n),
        ]);

        updated.proofMaturityDelay = Number(maturityDelay);
        updated.disputeGameFinalityDelay = Number(finalityDelay);

        const now = Math.floor(Date.now() / 1000);
        const proofAge = now - updated.provenTimestamp;

        // Check if the dispute game is resolved
        let gameResolved = false;
        let gameResolvedAt = 0;
        if (proven.disputeGameProxy && proven.disputeGameProxy !== ethers.ZeroAddress) {
          try {
            const gameContract = new ethers.Contract(proven.disputeGameProxy, DISPUTE_GAME_ABI, l1Provider);
            const [gameStatus, resolvedAt] = await Promise.all([
              gameContract.status(),
              gameContract.resolvedAt().catch(() => 0),
            ]);
            // status 2 = DEFENDER_WINS (resolved in favor of the proposal)
            gameResolved = Number(gameStatus) === 2;
            gameResolvedAt = Number(resolvedAt);
          } catch {
            // game not accessible
          }
        }

        const proofMature = proofAge >= Number(maturityDelay);
        const gameFinalityMet = gameResolved && (now - gameResolvedAt >= Number(finalityDelay));

        if (proofMature && gameFinalityMet) {
          updated.status = 'ready_to_finalize';
          updated.statusMessage = 'Ready to finalize';
          updated.nextAction = 'Finalize Withdrawal';
          updated.timeUntilFinalizable = 0;
        } else {
          updated.status = 'proven';
          updated.statusMessage = 'Withdrawal proven, waiting for maturity';

          // Calculate remaining time
          const timeUntilProofMature = Math.max(0, Number(maturityDelay) - proofAge);
          const timeUntilGameFinality = gameResolved ? Math.max(0, Number(finalityDelay) - (now - gameResolvedAt)) : Number(finalityDelay);
          updated.timeUntilFinalizable = Math.max(timeUntilProofMature, timeUntilGameFinality);
          updated.nextAction = `Wait ${Math.ceil(updated.timeUntilFinalizable / 60)}m`;
        }
        return updated;
      }

      // 3. Not proven yet - find covering game
      const coveringGame = await findCoveringGame(withdrawal.l2BlockNumber);
      if (coveringGame) {
        updated.gameIndex = coveringGame.gameIndex;
        updated.gameProxy = coveringGame.gameProxy;
        updated.gameL2Block = coveringGame.gameL2Block;
        updated.gameType = coveringGame.gameType;
        updated.gameStatus = coveringGame.gameStatus;
        updated.isGameRespected = coveringGame.isRespected;
        updated.status = 'ready_to_prove';
        updated.statusMessage = `Game #${coveringGame.gameIndex} (L2 block ${coveringGame.gameL2Block}) covers this withdrawal`;
        updated.nextAction = coveringGame.isRespected ? 'Prove Withdrawal' : 'Prove Withdrawal (game not respected)';
      } else {
        updated.status = 'initiated';
        updated.statusMessage = 'Waiting for dispute game to cover L2 block ' + withdrawal.l2BlockNumber;
        updated.nextAction = 'Wait for game proposal';
      }

      return updated;
    } catch (error: any) {
      console.error('checkWithdrawalStatus error:', error);
      return { ...withdrawal, statusMessage: `Error: ${error.message}` };
    }
  };

  const generateMerkleProof = async (withdrawal: WithdrawalInfo): Promise<MerkleProofData | null> => {
    try {
      if (!withdrawal.gameProxy || withdrawal.gameIndex === undefined) {
        throw new Error('No covering game found. Cannot generate proof.');
      }

      // Get game's L2 block number
      const gameContract = new ethers.Contract(withdrawal.gameProxy, DISPUTE_GAME_ABI, l1Provider);
      const gameL2Block = await gameContract.l2BlockNumber();
      const blockTag = '0x' + BigInt(gameL2Block).toString(16);

      // Get L2 block for stateRoot and latestBlockhash
      const l2Block = await l2Provider.send('eth_getBlockByNumber', [blockTag, false]);
      if (!l2Block) throw new Error('L2 block not found');

      // Compute storage slot: keccak256(abi.encode(withdrawalHash, uint256(0)))
      const storageSlot = ethers.keccak256(
        ethers.AbiCoder.defaultAbiCoder().encode(
          ['bytes32', 'uint256'],
          [withdrawal.withdrawalHash, 0]
        )
      );

      // Get proof from L2
      const proof = await l2Provider.send('eth_getProof', [
        L2_TO_L1_MESSAGE_PASSER,
        [storageSlot],
        blockTag,
      ]);

      if (!proof || !proof.storageProof || proof.storageProof.length === 0) {
        throw new Error('Failed to get storage proof');
      }

      // Verify the withdrawal exists in L2 state (sentMessages[hash] = true)
      const storageValue = proof.storageProof[0].value;
      if (storageValue === '0x0' || storageValue === '0x') {
        throw new Error('Withdrawal not found in L2 state at the game block. The withdrawal may not be included in this game.');
      }

      // Pre-validate: compute output root and verify it matches the game's rootClaim
      const outputRootProof = {
        version: ethers.ZeroHash,
        stateRoot: l2Block.stateRoot,
        messagePasserStorageRoot: proof.storageHash,
        latestBlockhash: l2Block.hash,
      };

      const computedOutputRoot = ethers.keccak256(
        ethers.AbiCoder.defaultAbiCoder().encode(
          ['bytes32', 'bytes32', 'bytes32', 'bytes32'],
          [outputRootProof.version, outputRootProof.stateRoot, outputRootProof.messagePasserStorageRoot, outputRootProof.latestBlockhash]
        )
      );

      const rootClaim = await gameContract.rootClaim();
      if (computedOutputRoot !== rootClaim) {
        console.error('Output root mismatch!', { computedOutputRoot, rootClaim, outputRootProof });
        throw new Error(`Output root mismatch: computed ${computedOutputRoot.substring(0, 18)}... vs game rootClaim ${rootClaim.substring(0, 18)}...`);
      }

      console.log('generateMerkleProof: output root verified, proof generated successfully');

      return {
        outputRootProof,
        withdrawalProof: proof.storageProof[0].proof,
        gameIndex: withdrawal.gameIndex,
      };
    } catch (error: any) {
      console.error('generateMerkleProof error:', error);
      throw new Error(`Failed to generate proof: ${error.message}`);
    }
  };

  const proveWithdrawalTx = async (withdrawal: WithdrawalInfo, proofData: MerkleProofData) => {
    if (!signer || !l2Info?.portal) {
      alert('Please connect wallet first');
      return;
    }

    try {
      setWithdrawalLoading(true);

      // Ensure we're on L1
      await window.ethereum.request({
        method: 'wallet_switchEthereumChain',
        params: [{ chainId: `0x${CONFIG.chainId.toString(16)}` }],
      });

      const browserProvider = new ethers.BrowserProvider(window.ethereum);
      const browserSigner = await browserProvider.getSigner();
      const portal = new ethers.Contract(l2Info.portal, OPTIMISM_PORTAL_ABI, browserSigner);

      const withdrawalTx = {
        nonce: withdrawal.nonce,
        sender: withdrawal.sender,
        target: withdrawal.target,
        value: withdrawal.value,
        gasLimit: withdrawal.gasLimit,
        data: withdrawal.data,
      };

      const tx = await portal.proveWithdrawalTransaction(
        withdrawalTx,
        proofData.gameIndex,
        [
          proofData.outputRootProof.version,
          proofData.outputRootProof.stateRoot,
          proofData.outputRootProof.messagePasserStorageRoot,
          proofData.outputRootProof.latestBlockhash,
        ],
        proofData.withdrawalProof
      );
      await tx.wait();
      alert('Withdrawal proven successfully!');

      // Refresh status
      const updated = await checkWithdrawalStatus(withdrawal);
      setSelectedWithdrawal(updated);
      setTrackedWithdrawals(prev => prev.map(w => w.withdrawalHash === updated.withdrawalHash ? updated : w));
    } catch (error: any) {
      console.error('proveWithdrawal error:', error);
      alert(`Failed to prove: ${error.message}`);
    } finally {
      setWithdrawalLoading(false);
    }
  };

  const proveAndRequestFastWithdrawalTx = async (withdrawal: WithdrawalInfo, proofData: MerkleProofData) => {
    if (!signer || !l2Info?.portal) {
      alert('Please connect wallet first');
      return;
    }

    try {
      setWithdrawalLoading(true);

      await window.ethereum.request({
        method: 'wallet_switchEthereumChain',
        params: [{ chainId: `0x${CONFIG.chainId.toString(16)}` }],
      });

      const browserProvider = new ethers.BrowserProvider(window.ethereum);
      const browserSigner = await browserProvider.getSigner();
      const rat = new ethers.Contract(CONFIG.contracts.rat, RAT_ABI, browserSigner);

      // RAT에서 고정 수수료 조회
      const fwFee = await rat.fastWithdrawalFee();
      console.log('Fast Withdrawal fee:', ethers.formatEther(fwFee), 'TON');

      // TON approve
      const tonContract = new ethers.Contract(CONFIG.contracts.ton, TON_ABI, browserSigner);
      const approveTx = await tonContract.approve(CONFIG.contracts.rat, fwFee);
      await approveTx.wait();
      console.log('TON approved for RAT');

      const withdrawalTx = {
        nonce: withdrawal.nonce,
        sender: withdrawal.sender,
        target: withdrawal.target,
        value: withdrawal.value,
        gasLimit: withdrawal.gasLimit,
        data: withdrawal.data,
      };

      const tx = await rat.requestFastWithdrawal(
        withdrawalTx,
        proofData.gameIndex,
        [
          proofData.outputRootProof.version,
          proofData.outputRootProof.stateRoot,
          proofData.outputRootProof.messagePasserStorageRoot,
          proofData.outputRootProof.latestBlockhash,
        ],
        proofData.withdrawalProof,
        CONFIG.contracts.systemConfig,
      );
      await tx.wait();
      alert('Prove + Fast Withdrawal requested successfully!');

      const updated = await checkWithdrawalStatus(withdrawal);
      setSelectedWithdrawal(updated);
      setTrackedWithdrawals(prev => prev.map(w => w.withdrawalHash === updated.withdrawalHash ? updated : w));
    } catch (error: any) {
      console.error('requestFastWithdrawal error:', error);
      alert(`Failed: ${error.message}`);
    } finally {
      setWithdrawalLoading(false);
    }
  };

  const reclaimFeeTx = async (withdrawalHash: string) => {
    if (!signer) {
      alert('Please connect wallet first');
      return;
    }

    try {
      setWithdrawalLoading(true);

      await window.ethereum.request({
        method: 'wallet_switchEthereumChain',
        params: [{ chainId: `0x${CONFIG.chainId.toString(16)}` }],
      });

      const browserProvider = new ethers.BrowserProvider(window.ethereum);
      const browserSigner = await browserProvider.getSigner();
      const rat = new ethers.Contract(CONFIG.contracts.rat, RAT_ABI, browserSigner);

      const tx = await rat.reclaimFee(withdrawalHash);
      await tx.wait();
      alert('Fee reclaimed successfully!');
    } catch (error: any) {
      console.error('reclaimFee error:', error);
      alert(`Failed to reclaim fee: ${error.message}`);
    } finally {
      setWithdrawalLoading(false);
    }
  };

  const finalizeWithdrawalTx = async (withdrawal: WithdrawalInfo) => {
    if (!signer || !l2Info?.portal) {
      alert('Please connect wallet first');
      return;
    }

    try {
      setWithdrawalLoading(true);

      await window.ethereum.request({
        method: 'wallet_switchEthereumChain',
        params: [{ chainId: `0x${CONFIG.chainId.toString(16)}` }],
      });

      const browserProvider = new ethers.BrowserProvider(window.ethereum);
      const browserSigner = await browserProvider.getSigner();
      const portal = new ethers.Contract(l2Info.portal, OPTIMISM_PORTAL_ABI, browserSigner);

      const withdrawalTx = {
        nonce: withdrawal.nonce,
        sender: withdrawal.sender,
        target: withdrawal.target,
        value: withdrawal.value,
        gasLimit: withdrawal.gasLimit,
        data: withdrawal.data,
      };

      const tx = await portal.finalizeWithdrawalTransaction(withdrawalTx);
      await tx.wait();
      alert('Withdrawal finalized successfully!');

      const updated = await checkWithdrawalStatus(withdrawal);
      setSelectedWithdrawal(updated);
      setTrackedWithdrawals(prev => prev.map(w => w.withdrawalHash === updated.withdrawalHash ? updated : w));
    } catch (error: any) {
      console.error('finalizeWithdrawal error:', error);
      alert(`Failed: ${error.message}`);
    } finally {
      setWithdrawalLoading(false);
    }
  };

  const trackWithdrawal = async (txHash: string) => {
    try {
      setWithdrawalLoading(true);
      setWithdrawalError('');

      // Check for duplicates
      if (trackedWithdrawals.find(w => w.l2TxHash.toLowerCase() === txHash.toLowerCase())) {
        // Already tracked, just refresh status
        const existing = trackedWithdrawals.find(w => w.l2TxHash.toLowerCase() === txHash.toLowerCase())!;
        const updated = await checkWithdrawalStatus(existing);
        setTrackedWithdrawals(prev => prev.map(w => w.l2TxHash.toLowerCase() === txHash.toLowerCase() ? updated : w));
        setSelectedWithdrawal(updated);
        return;
      }

      const withdrawal = await lookupWithdrawalFromL2Tx(txHash);
      if (!withdrawal) {
        setWithdrawalError('No withdrawal found in this transaction');
        return;
      }

      const updated = await checkWithdrawalStatus(withdrawal);
      setTrackedWithdrawals(prev => [updated, ...prev]);
      setSelectedWithdrawal(updated);
    } catch (error: any) {
      setWithdrawalError(error.message);
    } finally {
      setWithdrawalLoading(false);
    }
  };

  const refreshAllWithdrawals = async () => {
    try {
      setWithdrawalLoading(true);
      const updated = await Promise.all(trackedWithdrawals.map(w => checkWithdrawalStatus(w)));
      setTrackedWithdrawals(updated);
      if (selectedWithdrawal) {
        const sel = updated.find(w => w.withdrawalHash === selectedWithdrawal.withdrawalHash);
        if (sel) setSelectedWithdrawal(sel);
      }
    } catch (error: any) {
      console.error('refreshAllWithdrawals error:', error);
    } finally {
      setWithdrawalLoading(false);
    }
  };

  const getStatusColor = (status: WithdrawalStatus): string => {
    switch (status) {
      case 'initiated': return '#6b7280';
      case 'ready_to_prove': return '#3b82f6';
      case 'proven': return '#f59e0b';
      case 'ready_to_finalize': return '#8b5cf6';
      case 'finalized': return '#10b981';
      case 'fast_verified': return '#06b6d4';
      case 'fast_finalized': return '#10b981';
      default: return '#6b7280';
    }
  };

  const getStatusLabel = (status: WithdrawalStatus): string => {
    switch (status) {
      case 'initiated': return 'Initiated';
      case 'ready_to_prove': return 'Ready to Prove';
      case 'proven': return 'Proven';
      case 'ready_to_finalize': return 'Ready to Finalize';
      case 'finalized': return 'Finalized';
      case 'fast_verified': return 'Fast Verified';
      case 'fast_finalized': return 'Fast Finalized';
      default: return status;
    }
  };

  const getStepNumber = (status: WithdrawalStatus): number => {
    switch (status) {
      case 'initiated': return 1;
      case 'ready_to_prove': return 1;
      case 'proven': return 3;
      case 'ready_to_finalize': return 3;
      case 'finalized': return 4;
      case 'fast_verified': return 3;
      case 'fast_finalized': return 4;
      default: return 1;
    }
  };

  const formatAddress = (addr: string) => {
    return `${addr.substring(0, 6)}...${addr.substring(38)}`;
  };

  const formatTimestamp = (ts: number) => {
    return new Date(ts * 1000).toLocaleString('en-US', {
      month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false
    });
  };

  const formatDuration = (seconds: number) => {
    if (seconds < 60) return `${seconds}s`;
    if (seconds < 3600) return `${Math.floor(seconds / 60)}m ${seconds % 60 ? (seconds % 60) + 's' : ''}`.trim();
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = seconds % 60;
    let result = `${h}h`;
    if (m) result += ` ${m}m`;
    if (s) result += ` ${s}s`;
    return result;
  };

  const getDetailedGameStatus = (game: { status: number; claimCount: number; createdAt?: number; maxClockDuration?: number }): { label: string; badgeClass: string } => {
    if (game.status === 1) return { label: 'Challenger Wins', badgeClass: 'badge-error' };
    if (game.status === 2) return { label: 'Defender Wins', badgeClass: 'badge-success' };
    // status === 0 (InProgress) - subdivide
    const hasDispute = game.claimCount > 1;
    const now = Math.floor(Date.now() / 1000);
    const clockExpired = game.createdAt && game.maxClockDuration
      ? now > game.createdAt + game.maxClockDuration
      : false;
    if (!hasDispute) {
      if (clockExpired) return { label: 'Unchallenged', badgeClass: 'badge-info' };
      return { label: 'Awaiting Challenge', badgeClass: '' };
    } else {
      if (clockExpired) return { label: 'Pending Resolution', badgeClass: 'badge-warning' };
      return { label: 'Under Dispute', badgeClass: 'badge-warning' };
    }
  };

  const getResolvedAtDisplay = (game: GameDetailInfo): string => {
    if (game.resolvedAt > 0) return formatTimestamp(game.resolvedAt);
    const hasDispute = game.claimCount > 1;
    const now = Math.floor(Date.now() / 1000);
    const clockExpired = game.createdAt && game.maxClockDuration
      ? now > game.createdAt + game.maxClockDuration
      : false;
    if (!hasDispute) {
      if (clockExpired) return 'Ready to resolve (unchallenged)';
      return '- (no challenges yet)';
    } else {
      if (clockExpired) return 'Ready to resolve';
      return '- (dispute in progress)';
    }
  };

  // Parse transaction input data
  const parseInputData = (to: string | null, data: string) => {
    if (!to || !data || data === '0x') {
      return null;
    }

    // Map of contract addresses to ABIs
    const contractABIs: Record<string, any[]> = {
      [CONFIG.contracts.ton.toLowerCase()]: TON_ABI,
      [CONFIG.contracts.wton.toLowerCase()]: WTON_ABI,
      [CONFIG.contracts.seigManager.toLowerCase()]: SEIG_MANAGER_ABI,
      [CONFIG.contracts.depositManager.toLowerCase()]: DEPOSIT_MANAGER_ABI,
      [CONFIG.contracts.layer2Manager.toLowerCase()]: LAYER2_MANAGER_ABI,
      [CONFIG.contracts.l1BridgeRegistry.toLowerCase()]: L1_BRIDGE_REGISTRY_ABI,
      [CONFIG.contracts.layer2Registry.toLowerCase()]: LAYER2_REGISTRY_ABI,
      [CONFIG.contracts.rat.toLowerCase()]: RAT_ABI,
      [CONFIG.contracts.disputeGameFactory.toLowerCase()]: DISPUTE_GAME_FACTORY_ABI,
      [CONFIG.contracts.systemConfig.toLowerCase()]: SYSTEM_CONFIG_ABI,
    };

    const abi = contractABIs[to.toLowerCase()];
    if (!abi) {
      return null;
    }

    try {
      const iface = new ethers.Interface(abi);
      const parsed = iface.parseTransaction({ data });
      
      if (parsed) {
        return {
          name: parsed.name,
          signature: parsed.signature,
          args: parsed.args.map((arg: any, idx: number) => ({
            name: parsed.fragment.inputs[idx]?.name || `param${idx}`,
            type: parsed.fragment.inputs[idx]?.type || 'unknown',
            value: arg.toString(),
          })),
        };
      }
    } catch (e) {
      console.error('Failed to parse input data:', e);
    }

    return null;
  };

  // Load L1 Blocks
  const loadL1Blocks = async (count: number = 10) => {
    try {
      const currentBlock = await l1Provider.getBlockNumber();
      const blocks: BlockInfo[] = [];
      
      for (let i = 0; i < count && currentBlock - i >= 0; i++) {
        const blockNum = currentBlock - i;
        const block = await l1Provider.getBlock(blockNum, true);
        if (block) {
          const txs = block.transactions as any[];
          blocks.push({
            number: block.number,
            hash: block.hash || '',
            parentHash: block.parentHash,
            timestamp: block.timestamp,
            miner: block.miner || '',
            gasUsed: block.gasUsed.toString(),
            gasLimit: block.gasLimit.toString(),
            baseFeePerGas: block.baseFeePerGas?.toString(),
            transactions: Array.isArray(txs) ? txs.map(tx => typeof tx === 'string' ? tx : tx.hash) : [],
          });
        }
      }
      
      setL1Blocks(blocks);
    } catch (error) {
      console.error('Failed to load L1 blocks:', error);
    }
  };

  // Load L2 Blocks
  const loadL2Blocks = async (count: number = 10) => {
    try {
      const currentBlock = await l2Provider.getBlockNumber();
      const blocks: BlockInfo[] = [];
      
      for (let i = 0; i < count && currentBlock - i >= 0; i++) {
        const blockNum = currentBlock - i;
        const block = await l2Provider.getBlock(blockNum, true);
        if (block) {
          const txs = block.transactions as any[];
          blocks.push({
            number: block.number,
            hash: block.hash || '',
            parentHash: block.parentHash,
            timestamp: block.timestamp,
            miner: block.miner || '',
            gasUsed: block.gasUsed.toString(),
            gasLimit: block.gasLimit.toString(),
            baseFeePerGas: block.baseFeePerGas?.toString(),
            transactions: Array.isArray(txs) ? txs.map(tx => typeof tx === 'string' ? tx : tx.hash) : [],
          });
        }
      }
      
      setL2Blocks(blocks);
    } catch (error) {
      console.error('Failed to load L2 blocks:', error);
    }
  };

  // Load Block Details
  const loadBlockDetails = async (blockNumber: number, isL2: boolean = false) => {
    try {
      const provider = isL2 ? l2Provider : l1Provider;
      const block = await provider.getBlock(blockNumber, true);
      if (block) {
        setSelectedBlock({
          number: block.number,
          hash: block.hash || '',
          parentHash: block.parentHash,
          timestamp: block.timestamp,
          miner: block.miner || '',
          gasUsed: block.gasUsed.toString(),
          gasLimit: block.gasLimit.toString(),
            baseFeePerGas: block.baseFeePerGas?.toString(),
            transactions: Array.isArray(block.transactions) ? block.transactions.map(tx => typeof tx === 'string' ? tx : (tx as any).hash) : [],
        });
      }
    } catch (error) {
      console.error('Failed to load block details:', error);
      alert('Block not found');
    }
  };

  // Load Transaction Details
  const loadTransactionDetails = async (txHash: string, isL2: boolean = false) => {
    try {
      const provider = isL2 ? l2Provider : l1Provider;
      const tx = await provider.getTransaction(txHash);
      const receipt = await provider.getTransactionReceipt(txHash);
      
      if (tx && receipt) {
        const inputData = tx.data || '0x';
        const methodId = inputData.length >= 10 ? inputData.substring(0, 10) : inputData;
        
        setSelectedTransaction({
          hash: tx.hash,
          from: tx.from,
          to: tx.to,
          value: ethers.formatEther(tx.value),
          gasPrice: tx.gasPrice?.toString() || '0',
          gasUsed: receipt.gasUsed.toString(),
          status: receipt.status ?? undefined,
          blockNumber: tx.blockNumber ?? 0,
          blockHash: tx.blockHash || '',
          transactionIndex: tx.index,
          data: inputData,
          methodId: methodId,
        });
      }
    } catch (error) {
      console.error('Failed to load transaction details:', error);
      alert('Transaction not found');
    }
  };

  // Load Recent Transactions from L1
  const loadL1Transactions = async (count: number = 20) => {
    try {
      const currentBlock = await l1Provider.getBlockNumber();
      const transactions: TransactionInfo[] = [];
      
      let loaded = 0;
      for (let i = 0; i < 50 && loaded < count; i++) {
        const blockNum = currentBlock - i;
        if (blockNum < 0) break;
        
        const block = await l1Provider.getBlock(blockNum, true);
        if (block && block.transactions.length > 0) {
          const txs = block.transactions as any[];
          for (const txHash of txs) {
            if (loaded >= count) break;
            
            try {
              const hash = typeof txHash === 'string' ? txHash : txHash.hash;
              const tx = await l1Provider.getTransaction(hash);
              const receipt = await l1Provider.getTransactionReceipt(hash);
              
              if (tx && receipt) {
                transactions.push({
                  hash: tx.hash,
                  from: tx.from,
                  to: tx.to,
                  value: ethers.formatEther(tx.value),
                  gasPrice: tx.gasPrice?.toString() || '0',
                  gasUsed: receipt.gasUsed.toString(),
                  status: receipt.status ?? undefined,
                  blockNumber: tx.blockNumber ?? 0,
                  blockHash: tx.blockHash || '',
                  transactionIndex: tx.index,
                });
                loaded++;
              }
            } catch (e) {
              console.error('Failed to load tx:', e);
            }
          }
        }
      }
      
      setL1Transactions(transactions);
    } catch (error) {
      console.error('Failed to load L1 transactions:', error);
    }
  };

  // Load Recent Transactions from L2
  const loadL2Transactions = async (count: number = 20) => {
    try {
      const currentBlock = await l2Provider.getBlockNumber();
      const transactions: TransactionInfo[] = [];
      // L1 system deposit address - filter these out to show user txs
      const DEPOSIT_TX_SOURCE = '0xdeaddeaddeaddeaddeaddeaddeaddeaddead0001';

      let loaded = 0;
      for (let i = 0; i < 200 && loaded < count; i++) {
        const blockNum = currentBlock - i;
        if (blockNum < 0) break;

        const block = await l2Provider.getBlock(blockNum, true);
        if (block && block.transactions.length > 0) {
          const txs = block.transactions as any[];
          for (const txHash of txs) {
            if (loaded >= count) break;

            try {
              const hash = typeof txHash === 'string' ? txHash : txHash.hash;
              const tx = await l2Provider.getTransaction(hash);
              if (!tx) continue;

              // Skip L1 system deposit transactions
              if (tx.from.toLowerCase() === DEPOSIT_TX_SOURCE) continue;

              const receipt = await l2Provider.getTransactionReceipt(hash);

              if (tx && receipt) {
                transactions.push({
                  hash: tx.hash,
                  from: tx.from,
                  to: tx.to,
                  value: ethers.formatEther(tx.value),
                  gasPrice: tx.gasPrice?.toString() || '0',
                  gasUsed: receipt.gasUsed.toString(),
                  status: receipt.status ?? undefined,
                  blockNumber: tx.blockNumber ?? 0,
                  blockHash: tx.blockHash || '',
                  transactionIndex: tx.index,
                });
                loaded++;
              }
            } catch (e) {
              console.error('Failed to load tx:', e);
            }
          }
        }
      }

      setL2Transactions(transactions);
    } catch (error) {
      console.error('Failed to load L2 transactions:', error);
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <div className="header-top">
          <h1>🏗️ TON Staking V3 - Local Devnet Dashboard</h1>
          <div className="network-section">
            <div className="network-buttons">
              <button
                className="btn btn-small btn-network"
                onClick={async () => {
                  try {
                    await window.ethereum.request({
                      method: 'wallet_switchEthereumChain',
                      params: [{ chainId: '0x384' }], // 900 = 0x384
                    });
                  } catch (switchError: any) {
                    if (switchError.code === 4902) {
                      await window.ethereum.request({
                        method: 'wallet_addEthereumChain',
                        params: [{
                          chainId: '0x384',
                          chainName: 'TON Staking L1 (Devnet)',
                          nativeCurrency: { name: 'Ethereum', symbol: 'ETH', decimals: 18 },
                          rpcUrls: ['http://localhost:8546'],
                        }],
                      });
                    }
                  }
                }}
              >
                🔗 L1
              </button>
              <button
                className="btn btn-small btn-network"
                onClick={async () => {
                  try {
                    await window.ethereum.request({
                      method: 'wallet_switchEthereumChain',
                      params: [{ chainId: '0x385' }], // 901 = 0x385
                    });
                  } catch (switchError: any) {
                    if (switchError.code === 4902) {
                      await window.ethereum.request({
                        method: 'wallet_addEthereumChain',
                        params: [{
                          chainId: '0x385',
                          chainName: 'TON Staking L2 (Devnet)',
                          nativeCurrency: { name: 'Ethereum', symbol: 'ETH', decimals: 18 },
                          rpcUrls: ['http://localhost:9545'],
                        }],
                      });
                    }
                  }
                }}
              >
                🔗 L2
              </button>
            </div>
            <div className="network-info">
              <span>L1: localhost:8546 (ID: 900)</span>
              <span>L2: localhost:9545 (ID: 901)</span>
            </div>
          </div>
        </div>
        {address && (
          <div className="header-info">
            <span className="connected-badge">🟢 Connected: {formatAddress(address)}</span>
          </div>
        )}
      </header>

      <main className="container">
        {!address ? (
          <div className="connect-section">
            <h2>Connect Your Wallet</h2>
            <p>Connect to view the comprehensive dashboard</p>
            <button onClick={connectWallet} disabled={loading} className="btn btn-primary">
              {loading ? 'Connecting...' : 'Connect Wallet'}
            </button>
            
            <div className="test-accounts">
              <h3>Test Accounts</h3>
              {TEST_ACCOUNTS.map((account, index) => (
                <div key={index} className="test-account">
                  <strong>{account.name}</strong>
                  <div className="address">{account.address}</div>
                  <div className="role">{account.role}</div>
                </div>
              ))}
            </div>
          </div>
        ) : (
          <div className="columns">
            {/* Mobile Menu Toggle */}
            <button 
              className="sidebar-toggle"
              onClick={() => setSidebarOpen(!sidebarOpen)}
            >
              {sidebarOpen ? '✕' : '☰'} Menu
            </button>

            {/* Sidebar */}
            <aside className={`sidebar ${sidebarOpen ? 'is-active' : ''}`}>
              <div className="sidebar-header">
                <h3>Navigation</h3>
              </div>
              
              <nav className="menu">
                <p className="menu-label">Dashboard</p>
                <ul className="menu-list">
                  <li>
                    <a 
                      className={activeTab === 'overview' ? 'is-active' : ''} 
                      onClick={() => { setActiveTab('overview'); setSidebarOpen(false); }}
                    >
                      📊 Overview
                    </a>
                  </li>
                </ul>

                <p className="menu-label">Management</p>
                <ul className="menu-list">
                  <li>
                    <a
                      className={activeTab === 'operator' ? 'is-active' : ''}
                      onClick={() => { setActiveTab('operator'); setSidebarOpen(false); }}
                    >
                      🎯 Sequencer
                    </a>
                  </li>
                  <li>
                    <a 
                      className={activeTab === 'validators' ? 'is-active' : ''} 
                      onClick={() => { setActiveTab('validators'); setSidebarOpen(false); }}
                    >
                      👥 Validators
                    </a>
                  </li>
                  <li>
                    <a 
                      className={activeTab === 'staking' ? 'is-active' : ''} 
                      onClick={() => { setActiveTab('staking'); setSidebarOpen(false); }}
                    >
                      💎 TON Staking
                    </a>
                  </li>
                  <li>
                    <a
                      className={activeTab === 'seigniorage' ? 'is-active' : ''}
                      onClick={() => { setActiveTab('seigniorage'); setSidebarOpen(false); }}
                    >
                      💰 Seigniorage
                    </a>
                  </li>
                  <li>
                    <a
                      className={activeTab === 'proposer' ? 'is-active' : ''}
                      onClick={() => { setActiveTab('proposer'); setSidebarOpen(false); }}
                    >
                      📡 Proposer
                    </a>
                  </li>
                  <li>
                    <a
                      className={activeTab === 'batcher' ? 'is-active' : ''}
                      onClick={() => { setActiveTab('batcher'); setSidebarOpen(false); }}
                    >
                      📦 Batcher
                    </a>
                  </li>
                  <li>
                    <a
                      className={activeTab === 'game-settings' ? 'is-active' : ''}
                      onClick={() => { setActiveTab('game-settings'); setSidebarOpen(false); }}
                    >
                      ⚙️ Game/Withdrawal Settings
                    </a>
                  </li>
                </ul>

                <p className="menu-label">Network</p>
                <ul className="menu-list">
                  <li>
                    <a
                      className={activeTab === 'l1-info' ? 'is-active' : ''}
                      onClick={() => { setActiveTab('l1-info'); setSidebarOpen(false); }}
                    >
                      🔗 L1 Information
                    </a>
                  </li>
                  <li>
                    <a
                      className={activeTab === 'l2-info' ? 'is-active' : ''}
                      onClick={() => { setActiveTab('l2-info'); setSidebarOpen(false); }}
                    >
                      🌐 L2 Information
                    </a>
                  </li>
                  <li>
                    <a
                      className={activeTab === 'bridge' ? 'is-active' : ''}
                      onClick={() => { setActiveTab('bridge'); setSidebarOpen(false); }}
                    >
                      🌉 Bridge
                    </a>
                  </li>
                </ul>

                <p className="menu-label">Monitoring</p>
                <ul className="menu-list">
                  <li>
                    <a 
                      className={activeTab === 'games' ? 'is-active' : ''} 
                      onClick={() => { setActiveTab('games'); setSidebarOpen(false); }}
                    >
                      🎮 Dispute Games
                    </a>
                  </li>
                  <li>
                    <a
                      className={activeTab === 'l1-balances' ? 'is-active' : ''}
                      onClick={() => { setActiveTab('l1-balances'); setSidebarOpen(false); }}
                    >
                      💰 L1 Balances
                    </a>
                  </li>
                  <li>
                    <a
                      className={activeTab === 'l2-balances' ? 'is-active' : ''}
                      onClick={() => { setActiveTab('l2-balances'); setSidebarOpen(false); }}
                    >
                      💎 L2 Balances
                    </a>
                  </li>
                </ul>

                <p className="menu-label">Block Explorers</p>
                <ul className="menu-list">
                  <li>
                    <a 
                      className={activeTab === 'l1-explorer' ? 'is-active' : ''} 
                      onClick={() => { setActiveTab('l1-explorer'); setSidebarOpen(false); }}
                    >
                      🔍 L1 Block Explorer
                    </a>
                  </li>
                  <li>
                    <a 
                      className={activeTab === 'l2-explorer' ? 'is-active' : ''} 
                      onClick={() => { setActiveTab('l2-explorer'); setSidebarOpen(false); }}
                    >
                      🔎 L2 Block Explorer
                    </a>
                  </li>
                </ul>
              </nav>
            </aside>

            {/* Main Content */}
            <div className="main-content">
              {/* Overview Tab */}
              {activeTab === 'overview' && (
                <div className="dashboard-grid">
                  {/* Reload Addresses Button */}
                  <section className="card">
                    <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem'}}>
                      <h2>🔄 Configuration</h2>
                      <div style={{display: 'flex', gap: '0.5rem'}}>
                        <button 
                          onClick={reloadAddresses} 
                          disabled={loading}
                          className="btn btn-small"
                          style={{padding: '0.5rem 1rem'}}
                          title="Reload addresses from JSON files and refresh all data"
                        >
                          {loading ? '⏳ Reloading...' : '🔄 Reload Config'}
                        </button>
                        <button 
                          onClick={() => window.location.reload()} 
                          className="btn btn-small"
                          style={{padding: '0.5rem 1rem', background: '#f44336'}}
                          title="Full page reload (hard refresh)"
                        >
                          🔃 Full Refresh
                        </button>
                      </div>
                    </div>
                    <div className="info-grid" style={{fontSize: '0.9rem'}}>
                      <div className="info-item">
                        <span className="info-label">TON:</span>
                        <span style={{fontFamily: 'monospace', fontSize: '0.85rem'}}>{CONFIG.contracts.ton}</span>
                      </div>
                      <div className="info-item">
                        <span className="info-label">WTON:</span>
                        <span style={{fontFamily: 'monospace', fontSize: '0.85rem'}}>{CONFIG.contracts.wton}</span>
                      </div>
                      <div className="info-item">
                        <span className="info-label">SeigManager:</span>
                        <span style={{fontFamily: 'monospace', fontSize: '0.85rem'}}>{CONFIG.contracts.seigManager}</span>
                      </div>
                      <div className="info-item">
                        <span className="info-label">RAT:</span>
                        <span style={{fontFamily: 'monospace', fontSize: '0.85rem'}}>{CONFIG.contracts.rat}</span>
                      </div>
                      <div className="info-item">
                        <span className="info-label">SystemConfig:</span>
                        <span style={{fontFamily: 'monospace', fontSize: '0.85rem'}}>{CONFIG.contracts.systemConfig}</span>
                      </div>
                      <div className="info-item">
                        <span className="info-label">DisputeGameFactory:</span>
                        <span style={{fontFamily: 'monospace', fontSize: '0.85rem'}}>{CONFIG.contracts.disputeGameFactory}</span>
                      </div>
                    </div>
                  </section>

                  <section className="card">
                    <h2>📡 Node Status</h2>
                    {nodeStatus && (
                      <div style={{display: 'flex', flexDirection: 'column', gap: '1.5rem'}}>
                        {/* L1 Status */}
                        <div>
                          <h3 style={{marginBottom: '0.75rem', fontSize: '1rem', fontWeight: 'bold'}}>L1 Network</h3>
                          <div className="status-grid">
                            <div className="status-item">
                              <span className="status-label">Status:</span>
                              <span className={nodeStatus.l1Running ? 'status-online' : 'status-offline'}>
                                {nodeStatus.l1Running ? '🟢 Online' : '🔴 Offline'}
                              </span>
                            </div>
                            <div className="status-item">
                              <span className="status-label">Block:</span>
                              <span>{nodeStatus.l1Block}</span>
                            </div>
                            <div className="status-item">
                              <span className="status-label">Chain ID:</span>
                              <span>{nodeStatus.l1ChainId}</span>
                            </div>
                          </div>
                        </div>

                        {/* L2 Status */}
                        <div>
                          <h3 style={{marginBottom: '0.75rem', fontSize: '1rem', fontWeight: 'bold'}}>L2 Network</h3>
                          <div className="status-grid">
                            <div className="status-item">
                              <span className="status-label">Status:</span>
                              <span className={nodeStatus.l2Running ? 'status-online' : 'status-offline'}>
                                {nodeStatus.l2Running ? '🟢 Online' : '⚠️ Offline'}
                              </span>
                            </div>
                            {nodeStatus.l2Running && (
                              <>
                                <div className="status-item">
                                  <span className="status-label">Block:</span>
                                  <span>{nodeStatus.l2Block}</span>
                                </div>
                                <div className="status-item">
                                  <span className="status-label">Chain ID:</span>
                                  <span className={nodeStatus.l2ChainId === '901' ? 'status-online' : 'status-offline'}>
                                    {nodeStatus.l2ChainId} {nodeStatus.l2ChainId === '901' ? '✅' : '❌ (Expected: 901)'}
                                  </span>
                                </div>
                              </>
                            )}
                          </div>
                        </div>
                      </div>
                    )}
                  </section>

                  <section className="card">
                    <h2>🌐 Rollup Information</h2>
                    {rollupInfo && (
                      <div className="info-list">
                        <div className="info-row">
                          <span className="info-label">SystemConfig:</span>
                          <code>{CONFIG.contracts.systemConfig}</code>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Rollup Type:</span>
                          <span className="badge">{ROLLUP_TYPES[rollupInfo.rollupType as keyof typeof ROLLUP_TYPES]}</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">L2 TON:</span>
                          <code>{rollupInfo.l2Ton}</code>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Name:</span>
                          <span>{rollupInfo.name}</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Rejected Seigs:</span>
                          <span className={rollupInfo.rejectedSeigs ? 'status-error' : 'status-success'}>
                            {rollupInfo.rejectedSeigs ? '❌ Yes' : '✅ No'}
                          </span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Rejected L2 Deposit:</span>
                          <span className={rollupInfo.rejectedL2Deposit ? 'status-error' : 'status-success'}>
                            {rollupInfo.rejectedL2Deposit ? '❌ Yes' : '✅ No'}
                          </span>
                        </div>
                      </div>
                    )}
                  </section>

                  <section className="card">
                    <h2>⚙️ System Parameters</h2>
                    <div className="info-list">
                      <div className="info-row">
                        <span className="info-label">V3 Migrated:</span>
                        <span className={v3Migrated ? 'status-success' : 'status-error'}>
                          {v3Migrated ? '✅ Yes' : '❌ No'}
                        </span>
                      </div>
                      <div className="info-row">
                        <span className="info-label">Total Validators:</span>
                        <span className="badge">{totalValidators}</span>
                      </div>
                      <div className="info-row">
                        <span className="info-label">Active Validators:</span>
                        <span className="badge badge-success">{activeValidators}</span>
                      </div>
                      <div className="info-row">
                        <span className="info-label">Min Collateral:</span>
                        <span>{parseFloat(minCollateral).toFixed(2)} WTON</span>
                      </div>
                      <div className="info-row">
                        <span className="info-label">Sequencer Min Stake:</span>
                        <span>{parseFloat(sequencerMinStake).toFixed(2)} WTON</span>
                      </div>
                    </div>
                  </section>

                  <section className="card">
                    <h2>📍 Key Contracts</h2>
                    <div className="info-list">
                      <div className="info-row">
                        <span className="info-label">💰 TON:</span>
                        <code>{CONFIG.contracts.ton}</code>
                      </div>
                      <div className="info-row">
                        <span className="info-label">💎 WTON:</span>
                        <code>{CONFIG.contracts.wton}</code>
                      </div>
                      <div className="info-row">
                        <span className="info-label">⚙️ SystemConfig:</span>
                        <code>{CONFIG.contracts.systemConfig}</code>
                      </div>
                      <div className="info-row">
                        <span className="info-label">🎮 DisputeGameFactory:</span>
                        <code>{CONFIG.contracts.disputeGameFactory}</code>
                      </div>
                      {operatorInfo && operatorInfo.operatorManager !== ethers.ZeroAddress && (
                        <>
                          <div className="info-row">
                            <span className="info-label">👤 OperatorManager:</span>
                            <code>{operatorInfo.operatorManager}</code>
                          </div>
                          <div className="info-row">
                            <span className="info-label">🎯 CandidateAddOn:</span>
                            <code>{operatorInfo.candidateAddOn}</code>
                          </div>
                        </>
                      )}
                    </div>
                  </section>
                </div>
              )}

              {/* Sequencer Tab */}
              {activeTab === 'operator' && (
                <div className="section">
                  <section className="card">
                    <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem'}}>
                      <h2 style={{margin: 0}}>🎯 Sequencer Information</h2>
                      <button 
                        onClick={async () => {
                          setLoading(true);
                          try {
                            // loadOperatorInfo를 먼저 실행하고 결과를 받아옴
                            await loadOperatorInfo();
                            
                            // operatorInfo가 업데이트되길 기다리고 loadSeigniorageInfo 실행
                            // operatorInfo state가 업데이트되는 시간을 주기 위해 약간 대기
                            await new Promise(resolve => setTimeout(resolve, 100));
                            
                            await loadL2Info();
                            
                            // operatorInfo 체크 후 seigniorage 로드
                            const opInfo = operatorInfo;
                            if (opInfo?.candidateAddOn && opInfo.candidateAddOn !== ethers.ZeroAddress) {
                              await loadSeigniorageInfo(opInfo.candidateAddOn);
                            }
                          } catch (error) {
                            console.error('Refresh failed:', error);
                          } finally {
                            setLoading(false);
                          }
                        }}
                        className="btn btn-secondary"
                        disabled={loading}
                        style={{margin: 0}}
                      >
                        {loading ? '🔄 Refreshing...' : '🔄 Refresh Data'}
                      </button>
                    </div>
                    {operatorInfo && (
                      <div className="info-list">
                        <div className="info-row">
                          <span className="info-label">Sequencer Address:</span>
                          <code>{operatorInfo.operator}</code>
                        </div>
                        <div className="info-row">
                          <span className="info-label">OperatorManager:</span>
                          <code>{operatorInfo.operatorManager}</code>
                        </div>
                        <div className="info-row">
                          <span className="info-label">CandidateAddOn (Layer2):</span>
                          <code>{operatorInfo.candidateAddOn}</code>
                        </div>
                        <div className="info-row">
                          <span className="info-label">OperatorManager Staked Amount:</span>
                          <span className="value-large" style={{fontSize: '1.2rem', fontWeight: 'bold', color: '#2196F3'}}>
                            {parseFloat(ethers.formatUnits(operatorInfo.sequencerStake, 27)).toFixed(2)} WTON
                          </span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Current Stake (T_i) from Eligibility:</span>
                          <span className="value-large">
                            {parseFloat(ethers.formatUnits(operatorInfo.currentStake, 27)).toFixed(2)} WTON
                            {operatorInfo.sequencerStake !== operatorInfo.currentStake && (
                              <span style={{marginLeft: '0.5rem', color: '#FF5722', fontSize: '0.9rem'}}>
                                ⚠️ Different from staked amount
                              </span>
                            )}
                          </span>
                        </div>

                        <div className="info-row">
                          <span className="info-label">Required Stake (max(θ·B_i, D_seq)):</span>
                          <span style={{fontSize: '1.05rem', fontWeight: 'bold'}}>
                            {parseFloat(ethers.formatUnits(operatorInfo.requiredStake, 27)).toFixed(2)} WTON
                          </span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Seigniorage Eligibility:</span>
                          <span className={operatorInfo.isEligible ? 'status-success' : 'status-error'}>
                            {operatorInfo.isEligible ? '✅ Eligible' : '❌ Not Eligible'}
                            {!operatorInfo.isEligible && (
                              <span style={{marginLeft: '0.5rem', fontSize: '0.9rem'}}>
                                (Need {parseFloat(ethers.formatUnits(operatorInfo.requiredStake, 27)).toFixed(2)} WTON)
                              </span>
                            )}
                          </span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Bridged TON (B_i):</span>
                          <span style={{fontSize: '1.1rem', fontWeight: 'bold', color: '#FF9800'}}>
                            {seigniorageInfo ? parseFloat(seigniorageInfo.bridgedTon).toFixed(2) : 'Loading...'} TON
                          </span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">L2 effectiveBridgedTON:</span>
                          <span style={{fontSize: '1.1rem', fontWeight: 'bold', color: '#FF9800'}}>
                            {seigniorageInfo ? parseFloat(seigniorageInfo.effectiveBridgedTon).toFixed(4) : 'Loading...'} WTON
                          </span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Minimum Sequencer Stake (D_seq):</span>
                          <span>{parseFloat(sequencerMinStake).toFixed(2)} WTON</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Layer2Registry Status:</span>
                          <span className={operatorInfo.isLayer2Registered ? 'status-success' : 'status-error'}>
                            {operatorInfo.isLayer2Registered ? '✅ Registered' : '❌ Not Registered'}
                          </span>
                        </div>
                      </div>
                    )}
                    <small style={{ marginTop: '0.5rem', display: 'block', color: 'var(--text-light)', lineHeight: '1.6' }}>
                      <strong>📖 Explanation:</strong><br/>
                      • <strong>OperatorManager Staked Amount</strong>: WTON staked by OperatorManager in CandidateAddOn = stakeOf(candidateAddOn, operatorManager)<br/>
                      • <strong>Current Stake (T_i)</strong>: Effective stake from checkCurrentEligibility() - should match OperatorManager staked amount<br/>
                      • <strong>Bridged TON (B_i)</strong>: Amount of TON bridged to L2<br/>
                      • <strong>Required Stake</strong>: max(θ·B_i, D_seq) where θ = minStakingRatio (e.g., 0.1 = 10%)<br/>
                      • <strong>Eligibility Condition</strong>: T_i ≥ max(θ·B_i, D_seq)<br/>
                      • <strong>D_seq</strong>: Minimum sequencer stake (from SeigManager.minimumAmount())
                    </small>
                  </section>

                  <section className="card">
                    <h2>💎 Add Sequencer Collateral</h2>
                    <p>Increase sequencer stake amount</p>
                    <div className="action-form">
                      <input
                        type="number"
                        placeholder="Amount (WTON)"
                        className="input"
                        id="collateral-input"
                        step="0.01"
                      />
                      <button
                        onClick={() => {
                          const input = document.getElementById('collateral-input') as HTMLInputElement;
                          handleAddCollateral(input.value);
                        }}
                        disabled={loading}
                        className="btn btn-primary"
                      >
                        {loading ? 'Adding...' : 'Add Collateral'}
                      </button>
                    </div>
                    <small>Your WTON Balance: {parseFloat(wtonBalance).toFixed(4)}</small>
                  </section>
                </div>
              )}

              {/* Validators Tab */}
              {activeTab === 'validators' && (
                <div className="section">
                  <section className="card">
                    <h2>💰 Validator Reward Contract</h2>
                    <div className="info-list">
                      <div className="info-row">
                        <span className="info-label">ValidatorReward Address:</span>
                        <code>{CONFIG.contracts.validatorReward}</code>
                      </div>
                      <div className="info-row">
                        <span className="info-label">ValidatorReward WTON Balance (Seigniorage):</span>
                        <span className="value-large" style={{color: '#4CAF50', fontWeight: 'bold', fontSize: '1.2rem'}}>
                          {parseFloat(validatorRewardWtonBalance).toFixed(4)} WTON
                        </span>
                      </div>
                    </div>
                    <small style={{ marginTop: '0.5rem', display: 'block', color: 'var(--text-light)' }}>
                      This contract holds seigniorage to be distributed to validators
                    </small>
                  </section>

                  <section className="card">
                    <h2>⚙️ Validator Configuration</h2>
                    <div className="info-list">
                      <div className="info-row">
                        <span className="info-label">Minimum Collateral (D_min):</span>
                        <span>{parseFloat(minCollateral).toFixed(2)} WTON</span>
                      </div>
                      <div className="info-row">
                        <span className="info-label">Slashing Penalty (C_off):</span>
                        <span>{parseFloat(slashingPenalty).toFixed(2)} WTON</span>
                      </div>
                      <div className="info-row">
                        <span className="info-label">Validator Buffer (Δ_validator):</span>
                        <span>{parseFloat(validatorBuffer).toFixed(2)} WTON</span>
                      </div>
                      <div className="info-row">
                        <span className="info-label">Collateral Check Mode:</span>
                        <span className={relaxedValidatorCheck ? 'status-warning' : 'status-success'}>
                          {relaxedValidatorCheck ? '⚠️ Relaxed (C_off based)' : '✅ Strict (D_min based)'}
                        </span>
                      </div>
                      <div className="info-row">
                        <span className="info-label">Max Validators per L2:</span>
                        <span>{maxValidatorsPerL2 === 0 ? 'Unlimited' : maxValidatorsPerL2}</span>
                      </div>
                      <div className="info-row">
                        <span className="info-label">Evidence Submission Period:</span>
                        <span>{evidenceSubmissionPeriod} seconds</span>
                      </div>
                    </div>
                    <small style={{ marginTop: '0.5rem', display: 'block', color: 'var(--text-light)' }}>
                      D_min = C_off + Δ_validator | Relaxed mode: validators deactivated when collateral {'<'} C_off
                    </small>
                  </section>

                  <section className="card">
                    <h2>👥 Registered Validators ({validators.length})</h2>
                    {validators.length === 0 ? (
                      <p className="empty-state">No validators registered yet</p>
                    ) : (
                      <div className="table-container">
                        <table className="validators-table">
                          <thead>
                            <tr>
                              <th>Address</th>
                              <th>Deposit</th>
                              <th>Available</th>
                              <th>WTON Balance (Seigniorage)</th>
                              <th>RAT Status</th>
                              <th>Active</th>
                            </tr>
                          </thead>
                          <tbody>
                            {validators.map((val, idx) => (
                              <tr key={idx}>
                                <td><code>{formatAddress(val.address)}</code></td>
                                <td>{parseFloat(val.deposit).toFixed(2)} WTON</td>
                                <td>{parseFloat(val.available).toFixed(2)} WTON</td>
                                <td style={{color: '#4CAF50', fontWeight: 'bold'}}>
                                  {parseFloat(val.wtonBalance).toFixed(4)} WTON
                                </td>
                                <td>
                                  <span className={val.ratRegistered ? 'status-success' : 'status-warning'}>
                                    {val.ratRegistered ? '✅ Registered' : '⚠️ Not Registered'}
                                  </span>
                                </td>
                                <td>
                                  <span className={val.isActive ? 'status-online' : 'status-offline'}>
                                    {val.isActive ? '🟢 Active' : '🔴 Inactive'}
                                  </span>
                                </td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                      </div>
                    )}
                  </section>

                  <h2 style={{ margin: '2rem 0 1rem', padding: '0.5rem 0', borderBottom: '2px solid #e2e8f0', color: 'var(--text-color)' }}>
                    🧪 RAT (Random Attestation Test)
                  </h2>

                  <section className="card">
                    <h2>🧪 RAT Tests ({attentionTests.length})</h2>
                    {attentionTests.length === 0 ? (
                      <p className="empty-state">No attention tests found</p>
                    ) : (
                      <>
                        <div className="table-container">
                          <table className="validators-table">
                            <thead>
                              <tr>
                                <th>Batch</th>
                                <th>Validator</th>
                                <th>Penalty</th>
                                <th>Deadline</th>
                                <th>Status</th>
                              </tr>
                            </thead>
                            <tbody>
                              {attentionTests.map((test, idx) => (
                                <tr
                                  key={idx}
                                  className={`clickable-row ${selectedAttentionTest?.testId === test.testId ? 'selected' : ''}`}
                                  onClick={() => selectedAttentionTest?.testId === test.testId ? setSelectedAttentionTest(null) : setSelectedAttentionTest(test)}
                                >
                                  <td>#{test.batchIndex}</td>
                                  <td><code>{formatAddress(test.validator)}</code></td>
                                  <td>{parseFloat(test.bondAmount).toFixed(2)} WTON</td>
                                  <td>{formatTimestamp(test.deadline)}</td>
                                  <td>
                                    {test.status === 5 ? (
                                      <span className="badge badge-error">
                                        Slashed (-{parseFloat(test.bondAmount).toFixed(2)} WTON)
                                      </span>
                                    ) : test.status === 3 ? (
                                      <span className="badge badge-success">
                                        Refunded (Evidence)
                                      </span>
                                    ) : test.status === 4 ? (
                                      <span className="badge badge-success">
                                        Refunded (Challenge Won)
                                      </span>
                                    ) : test.status === 1 ? (
                                      <span className="badge badge-warning">
                                        Awaiting Evidence
                                      </span>
                                    ) : test.status === 2 ? (
                                      <span className="badge badge-warning">
                                        Challenge Period
                                      </span>
                                    ) : (
                                      <span className="badge">-</span>
                                    )}
                                  </td>
                                </tr>
                              ))}
                            </tbody>
                          </table>
                        </div>

                        {selectedAttentionTest && (
                          <div className="game-detail-panel" style={{marginTop: '1rem'}}>
                            <div className="detail-grid">
                              <h3>RAT Test Details</h3>
                              <div className="detail-row">
                                <span className="detail-label">Test ID:</span>
                                <code>{selectedAttentionTest.testId.substring(0, 18)}...</code>
                              </div>
                              <div className="detail-row">
                                <span className="detail-label">Validator:</span>
                                <code>{selectedAttentionTest.validator}</code>
                              </div>
                              <div className="detail-row">
                                <span className="detail-label">Batch Index:</span>
                                <span>#{selectedAttentionTest.batchIndex}</span>
                              </div>
                              <div className="detail-row">
                                <span className="detail-label">Batch Hash:</span>
                                <code>{selectedAttentionTest.batchHash.substring(0, 18)}...</code>
                              </div>
                              <div className="detail-row">
                                <span className="detail-label">Game Address:</span>
                                <code>{selectedAttentionTest.gameAddress}</code>
                              </div>
                              <div className="detail-row">
                                <span className="detail-label">Bond Amount:</span>
                                <span>{parseFloat(selectedAttentionTest.bondAmount).toFixed(2)} WTON</span>
                              </div>
                              <div className="detail-row">
                                <span className="detail-label">Created:</span>
                                <span>{formatTimestamp(selectedAttentionTest.createdAt)}</span>
                              </div>
                              <div className="detail-row">
                                <span className="detail-label">Deadline:</span>
                                <span>{formatTimestamp(selectedAttentionTest.deadline)}</span>
                              </div>
                              <div className="detail-row">
                                <span className="detail-label">Status:</span>
                                <span className={`badge ${
                                  selectedAttentionTest.status === 5 ? 'badge-error' :
                                  selectedAttentionTest.status === 3 || selectedAttentionTest.status === 4 ? 'badge-success' : 'badge-warning'
                                }`}>
                                  {selectedAttentionTest.statusLabel}
                                </span>
                              </div>
                              <div className="detail-row">
                                <span className="detail-label">System Config:</span>
                                <code>{selectedAttentionTest.systemConfig}</code>
                              </div>
                            </div>
                          </div>
                        )}
                      </>
                    )}
                  </section>

                  <h2 style={{ margin: '2rem 0 1rem', padding: '0.5rem 0', borderBottom: '2px solid #e2e8f0', color: 'var(--text-color)' }}>
                    ⚡ Fast Withdrawal (BLS)
                  </h2>

                  <section className="card">
                    <h2>🔑 BLS & Fast Withdrawal Status</h2>
                    <div className="info-list">
                      <div className="info-row">
                        <span className="info-label">BLS-Enabled Validators:</span>
                        <span className="badge badge-success">{blsValidators.length}</span>
                      </div>
                      <div className="info-row">
                        <span className="info-label">Min Validators for Fast Withdrawal:</span>
                        <span className="badge">{minValidatorsForFW}</span>
                      </div>
                      <div className="info-row">
                        <span className="info-label">Fast Withdrawal Ready:</span>
                        <span className={blsValidators.length >= minValidatorsForFW && minValidatorsForFW > 0 ? 'status-success' : 'status-warning'}>
                          {blsValidators.length >= minValidatorsForFW && minValidatorsForFW > 0 ? '✅ Yes' : '⚠️ Not enough BLS validators'}
                        </span>
                      </div>
                    </div>
                    {validators.length > 0 && (
                      <div className="table-container" style={{marginTop: '1rem'}}>
                        <table className="validators-table">
                          <thead>
                            <tr>
                              <th>Address</th>
                              <th>Active</th>
                              <th>BLS Key</th>
                            </tr>
                          </thead>
                          <tbody>
                            {validators.map((val, idx) => (
                              <tr key={idx}>
                                <td><code>{formatAddress(val.address)}</code></td>
                                <td>
                                  <span className={val.isActive ? 'status-online' : 'status-offline'}>
                                    {val.isActive ? '🟢' : '🔴'}
                                  </span>
                                </td>
                                <td>
                                  <span className={blsValidators.includes(val.address.toLowerCase()) ? 'status-success' : 'status-warning'}>
                                    {blsValidators.includes(val.address.toLowerCase()) ? '✅ Registered' : '❌ None'}
                                  </span>
                                </td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                      </div>
                    )}
                  </section>

                </div>
              )}

              {/* Staking Tab */}
              {activeTab === 'staking' && (
                <div className="section">
                  <section className="card">
                    <h2>💎 Deposit (Stake)</h2>
                    <p>Stake WTON tokens to participate in validation</p>
                    {!operatorInfo?.candidateAddOn || operatorInfo.candidateAddOn === ethers.ZeroAddress ? (
                      <div className="warning-box">
                        <p>⚠️ CandidateAddOn not found. Please register L2 operator first.</p>
                      </div>
                    ) : (
                      <>
                        <div className="info-list" style={{ marginBottom: '1rem' }}>
                          <div className="info-row">
                            <span className="info-label">Target Layer2:</span>
                            <code>{operatorInfo.candidateAddOn}</code>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Your Staked Amount:</span>
                            <span className="value-large">{parseFloat(stakedAmount).toFixed(4)} WTON</span>
                          </div>
                        </div>
                        <div className="action-form">
                          <input
                            type="number"
                            placeholder="Amount (WTON)"
                            className="input"
                            id="stake-input"
                            step="0.01"
                            min="0"
                          />
                          <button
                            onClick={async () => {
                              const input = document.getElementById('stake-input') as HTMLInputElement;
                              const amount = input.value;
                              if (!signer || !amount || parseFloat(amount) <= 0) {
                                alert('Please enter a valid amount');
                                return;
                              }
                              
                              try {
                                setLoading(true);
                                const amountWei = ethers.parseUnits(amount, 27); // WTON is 27 decimals
                                
                                // 1. Approve WTON
                                const wtonContract = new ethers.Contract(CONFIG.contracts.wton, WTON_ABI, signer);
                                const approveTx = await wtonContract.approve(CONFIG.contracts.depositManager, amountWei);
                                await approveTx.wait();
                                
                                // 2. Deposit
                                const depositManager = new ethers.Contract(CONFIG.contracts.depositManager, DEPOSIT_MANAGER_ABI, signer);
                                const depositTx = await depositManager.deposit(operatorInfo.candidateAddOn, amountWei);
                                await depositTx.wait();
                                
                                alert('✅ Staking successful!');
                                input.value = '';
                                await loadDashboardData();
                                if (address) await loadUserBalances(address);
                              } catch (error: any) {
                                console.error('Staking failed:', error);
                                alert(`❌ Failed: ${error.message || 'Unknown error'}`);
                              } finally {
                                setLoading(false);
                              }
                            }}
                            disabled={loading}
                            className="btn btn-primary"
                          >
                            {loading ? '⏳ Staking...' : '💎 Stake'}
                          </button>
                        </div>
                        <small>Your WTON Balance: {parseFloat(wtonBalance).toFixed(4)}</small>
                      </>
                    )}
                  </section>

                  <section className="card">
                    <h2>📤 Request Withdrawal</h2>
                    <p>Request to withdraw your staked WTON tokens</p>
                    {!operatorInfo?.candidateAddOn || operatorInfo.candidateAddOn === ethers.ZeroAddress ? (
                      <div className="warning-box">
                        <p>⚠️ No staking found</p>
                      </div>
                    ) : (
                      <>
                        <div className="info-list" style={{ marginBottom: '1rem' }}>
                          <div className="info-row">
                            <span className="info-label">Staked Amount:</span>
                            <span>{parseFloat(stakedAmount).toFixed(4)} WTON</span>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Pending Unstaked:</span>
                            <span className="value-large">{parseFloat(pendingUnstaked).toFixed(4)} WTON</span>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Pending Requests:</span>
                            <span className="badge">{withdrawalRequests}</span>
                          </div>
                        </div>
                        <div className="action-form">
                          <input
                            type="number"
                            placeholder="Amount (WTON)"
                            className="input"
                            id="withdrawal-input"
                            step="0.01"
                            min="0"
                          />
                          <button
                            onClick={async () => {
                              const input = document.getElementById('withdrawal-input') as HTMLInputElement;
                              const amount = input.value;
                              if (!signer || !amount || parseFloat(amount) <= 0) {
                                alert('Please enter a valid amount');
                                return;
                              }
                              
                              if (parseFloat(amount) > parseFloat(stakedAmount)) {
                                alert('Amount exceeds staked balance');
                                return;
                              }
                              
                              try {
                                setLoading(true);
                                const amountWei = ethers.parseUnits(amount, 27); // WTON is 27 decimals
                                
                                const depositManager = new ethers.Contract(CONFIG.contracts.depositManager, DEPOSIT_MANAGER_ABI, signer);
                                const tx = await depositManager.requestWithdrawal(operatorInfo.candidateAddOn, amountWei);
                                await tx.wait();
                                
                                alert('✅ Withdrawal requested successfully!');
                                input.value = '';
                                await loadDashboardData();
                                if (address) await loadUserBalances(address);
                              } catch (error: any) {
                                console.error('Withdrawal request failed:', error);
                                alert(`❌ Failed: ${error.message || 'Unknown error'}`);
                              } finally {
                                setLoading(false);
                              }
                            }}
                            disabled={loading || parseFloat(stakedAmount) <= 0}
                            className="btn btn-primary"
                          >
                            {loading ? '⏳ Requesting...' : '📤 Request Withdrawal'}
                          </button>
                        </div>
                        <small>Available to withdraw: {parseFloat(stakedAmount).toFixed(4)} WTON</small>
                      </>
                    )}
                  </section>

                  <section className="card">
                    <h2>✅ Process Withdrawal</h2>
                    <p>Process completed withdrawal requests and receive your WTON tokens</p>
                    {!operatorInfo?.candidateAddOn || operatorInfo.candidateAddOn === ethers.ZeroAddress ? (
                      <div className="warning-box">
                        <p>⚠️ No withdrawal requests found</p>
                      </div>
                    ) : (
                      <>
                        <div className="info-list" style={{ marginBottom: '1rem' }}>
                          <div className="info-row">
                            <span className="info-label">Pending Requests:</span>
                            <span className="badge">{withdrawalRequests}</span>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Pending Amount:</span>
                            <span className="value-large">{parseFloat(pendingUnstaked).toFixed(4)} WTON</span>
                          </div>
                        </div>
                        <div className="action-form">
                          <input
                            type="number"
                            placeholder="Number of requests to process"
                            className="input"
                            id="process-input"
                            step="1"
                            min="1"
                            defaultValue="1"
                          />
                          <button
                            onClick={async () => {
                              const input = document.getElementById('process-input') as HTMLInputElement;
                              const num = input.value;
                              if (!signer || !num || parseInt(num) <= 0) {
                                alert('Please enter a valid number');
                                return;
                              }
                              
                              if (parseInt(num) > withdrawalRequests) {
                                alert('Number exceeds pending requests');
                                return;
                              }
                              
                              try {
                                setLoading(true);
                                
                                const depositManager = new ethers.Contract(CONFIG.contracts.depositManager, DEPOSIT_MANAGER_ABI, signer);
                                const tx = await depositManager.processWithdrawal(operatorInfo.candidateAddOn, parseInt(num));
                                await tx.wait();
                                
                                alert('✅ Withdrawal processed successfully!');
                                input.value = '1';
                                await loadDashboardData();
                                if (address) await loadUserBalances(address);
                              } catch (error: any) {
                                console.error('Process withdrawal failed:', error);
                                alert(`❌ Failed: ${error.message || 'Unknown error'}`);
                              } finally {
                                setLoading(false);
                              }
                            }}
                            disabled={loading || withdrawalRequests === 0}
                            className="btn btn-primary"
                          >
                            {loading ? '⏳ Processing...' : '✅ Process Withdrawal'}
                          </button>
                        </div>
                        <small>
                          {withdrawalRequests === 0 
                            ? 'No pending withdrawal requests' 
                            : `${withdrawalRequests} request(s) ready to process`}
                        </small>
                      </>
                    )}
                  </section>
                </div>
              )}

              {/* L2 Balances Tab */}
              {activeTab === 'l2-balances' && (
                <div className="section">
                  <section className="card">
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
                      <h2 style={{ margin: 0 }}>💎 L2 Token Balances</h2>
                      <button
                        onClick={async () => {
                          if (!address) {
                            alert('Please connect wallet first');
                            return;
                          }
                          try {
                            setLoading(true);
                            // Load rollup info first to get L2 TON address
                            if (!rollupInfo) {
                              await loadRollupInfo();
                            }
                            await loadUserBalances(address);
                            alert('✅ Balances refreshed!');
                          } catch (error: any) {
                            console.error('Refresh failed:', error);
                            alert(`❌ Refresh failed: ${error.message || 'Unknown error'}`);
                          } finally {
                            setLoading(false);
                          }
                        }}
                        disabled={loading || !address}
                        className="btn btn-secondary"
                        style={{ padding: '0.5rem 1rem' }}
                      >
                        {loading ? '⏳' : '🔄'} Refresh
                      </button>
                    </div>
                    <div className="balance-cards">
                      <div className="balance-card">
                        <div className="balance-icon">⚡</div>
                        <div className="balance-label">L2 ETH</div>
                        <div className="balance-value">{parseFloat(l2EthBalance).toFixed(4)}</div>
                        <div className="balance-network">Layer 2</div>
                      </div>
                      <div className="balance-card">
                        <div className="balance-icon">🪙</div>
                        <div className="balance-label">L2 TON</div>
                        <div className="balance-value">{parseFloat(l2TonBalance).toFixed(4)}</div>
                        <div className="balance-network">Layer 2</div>
                      </div>
                    </div>
                    <div className="info-box" style={{ marginTop: '1rem', padding: '1rem', backgroundColor: '#f0f9ff', borderRadius: '8px', border: '1px solid #0ea5e9' }}>
                      <p style={{ margin: 0, fontSize: '0.9rem', color: '#0369a1' }}>
                        💡 <strong>Tip:</strong> L2 balances show your tokens on the Layer 2 network. 
                        Use the Bridge tab to transfer assets between L1 and L2.
                      </p>
                    </div>
                  </section>
                </div>
              )}

              {/* Dispute Games Tab */}
              {activeTab === 'games' && (
                <div className="section">
                  {/* Game Status Summary Cards */}
                  <div className="summary-cards">
                    <div className="summary-card">
                      <div className="summary-value">{gameStatusSummary.total}</div>
                      <div className="summary-label">Total Games</div>
                    </div>
                    <div className="summary-card">
                      <div className="summary-value" style={{color: '#2196F3'}}>{gameStatusSummary.inProgress}</div>
                      <div className="summary-label">In Progress</div>
                    </div>
                    <div className="summary-card">
                      <div className="summary-value" style={{color: '#f14668'}}>{gameStatusSummary.challengerWins}</div>
                      <div className="summary-label">Challenger Wins</div>
                    </div>
                    <div className="summary-card">
                      <div className="summary-value" style={{color: '#48c78e'}}>{gameStatusSummary.defenderWins}</div>
                      <div className="summary-label">Defender Wins</div>
                    </div>
                  </div>

                  <section className="card">
                    <h2>🏭 Factory Overview</h2>
                    <div className="info-list">
                      <div className="info-row">
                        <span className="info-label">Factory Address:</span>
                        <code>{CONFIG.contracts.disputeGameFactory}</code>
                      </div>
                      <div className="info-row">
                        <span className="info-label">Total Game Count:</span>
                        <span className="badge">{enhancedGames.length > 0 ? enhancedGames[0].index + 1 : games.length}</span>
                      </div>
                      {factoryInfo && (
                        <>
                          <div className="info-row">
                            <span className="info-label">Game Implementation:</span>
                            <code>{factoryInfo.gameImpl}</code>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Init Bond:</span>
                            <span>{parseFloat(factoryInfo.initBond).toFixed(6)} ETH</span>
                          </div>
                        </>
                      )}
                    </div>
                  </section>

                  <section className="card">
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <h2>🎮 Recent Dispute Games ({enhancedGames.length || games.length})</h2>
                      <button
                        onClick={async () => {
                          try {
                            setLoading(true);
                            await loadGames();
                          } catch (error: any) {
                            console.error('Refresh failed:', error);
                          } finally {
                            setLoading(false);
                          }
                        }}
                        disabled={loading}
                        className="btn btn-secondary"
                        style={{ padding: '0.3rem 0.8rem', fontSize: '0.85rem' }}
                      >
                        {loading ? '⏳' : '🔄'} Refresh
                      </button>
                    </div>
                    <small style={{display: 'block', marginBottom: '0.75rem', color: 'var(--text-light)'}}>Click a row to view game details</small>
                    {(enhancedGames.length === 0 && games.length === 0) ? (
                      <p className="empty-state">No dispute games created yet</p>
                    ) : enhancedGames.length > 0 ? (
                      <div className="table-container">
                        <table className="games-table">
                          <thead>
                            <tr>
                              <th>#</th>
                              <th>Type</th>
                              <th>Status</th>
                              <th>Root Claim</th>
                              <th>L2 Block</th>
                              <th>Claims</th>
                              <th>Proxy</th>
                              <th>Created</th>
                              <th>RAT</th>
                              <th>FW</th>
                            </tr>
                          </thead>
                          <tbody>
                            {enhancedGames.map((game, idx) => {
                              const detailedStatus = getDetailedGameStatus(game);
                              return (
                                <tr
                                  key={idx}
                                  className={`clickable-row ${selectedGameDetail?.proxy === game.proxy ? 'selected' : ''}`}
                                  onClick={() => selectedGameDetail?.proxy === game.proxy ? setSelectedGameDetail(null) : loadGameDetail(game)}
                                >
                                  <td>{game.index}</td>
                                  <td><span className="badge">{game.gameType}</span></td>
                                  <td>
                                    <span className={`badge ${detailedStatus.badgeClass}`}>
                                      {detailedStatus.label}
                                    </span>
                                  </td>
                                  <td><code>{game.rootClaim.substring(0, 10)}...</code></td>
                                  <td>{game.l2BlockNumber}</td>
                                  <td>{game.claimCount}</td>
                                  <td><code>{formatAddress(game.proxy)}</code></td>
                                  <td>{formatTimestamp(game.timestamp)}</td>
                                  <td>
                                    {game.ratTestId ? (
                                      <span
                                        style={{cursor: 'pointer', textDecoration: 'underline'}}
                                        onClick={(e) => { e.stopPropagation(); selectedGameDetail?.proxy === game.proxy ? setSelectedGameDetail(null) : loadGameDetail(game); }}
                                        title="View RAT test details"
                                      >✅ View</span>
                                    ) : '-'}
                                  </td>
                                  <td>
                                    {game.hasFastWithdrawal ? (
                                      <span className="badge badge-success">⚡ Yes</span>
                                    ) : '-'}
                                  </td>
                                </tr>
                              );
                            })}
                          </tbody>
                        </table>
                      </div>
                    ) : (
                      <div className="table-container">
                        <table className="games-table">
                          <thead>
                            <tr>
                              <th>#</th>
                              <th>Type</th>
                              <th>Proxy Address</th>
                              <th>Created At</th>
                            </tr>
                          </thead>
                          <tbody>
                            {games.map((game, idx) => (
                              <tr key={idx}>
                                <td>{game.index}</td>
                                <td className="badge">{game.gameType}</td>
                                <td><code>{formatAddress(game.proxy)}</code></td>
                                <td>{formatTimestamp(game.timestamp)}</td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                      </div>
                    )}

                    {/* Game Detail Panel */}
                    {selectedGameDetail && (
                      <div className="game-detail-panel">
                        <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
                          <h3>Game #{selectedGameDetail.index} Details</h3>
                          <button className="btn btn-small btn-secondary" onClick={() => setSelectedGameDetail(null)}>Close</button>
                        </div>
                        <div className="info-list">
                          <div className="info-row">
                            <span className="info-label">Proxy:</span>
                            <code>{selectedGameDetail.proxy}</code>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Status:</span>
                            <span className={`badge ${getDetailedGameStatus(selectedGameDetail).badgeClass}`}>
                              {getDetailedGameStatus(selectedGameDetail).label}
                            </span>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Root Claim:</span>
                            <code>{selectedGameDetail.rootClaim}</code>
                          </div>
                          <div className="info-row">
                            <span className="info-label">L2 Block:</span>
                            <span>{selectedGameDetail.l2BlockNumber}</span>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Starting Block:</span>
                            <span>{selectedGameDetail.startingBlockNumber}</span>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Created At:</span>
                            <span>{selectedGameDetail.createdAt > 0 ? formatTimestamp(selectedGameDetail.createdAt) : 'N/A'}</span>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Resolved At:</span>
                            <span>{getResolvedAtDisplay(selectedGameDetail)}</span>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Max Clock Duration:</span>
                            <span>{selectedGameDetail.maxClockDuration}s ({Math.round(selectedGameDetail.maxClockDuration / 60)}m)</span>
                          </div>
                          {selectedGameDetail.proposerAddress && (
                            <>
                              <div className="info-row">
                                <span className="info-label">Proposer:</span>
                                <code>{formatAddress(selectedGameDetail.proposerAddress)}</code>
                              </div>
                              <div className="info-row">
                                <span className="info-label">Proposer Bond:</span>
                                <span>{selectedGameDetail.proposerBond} ETH</span>
                              </div>
                              <div className="info-row">
                                <span className="info-label">Bond Credit:</span>
                                <span>
                                  {selectedGameDetail.resolvedAt > 0 ? (
                                    parseFloat(selectedGameDetail.proposerCredit) > 0 ? (
                                      <span className="badge badge-warning">Unclaimed ({selectedGameDetail.proposerCredit} ETH)</span>
                                    ) : (
                                      <span className="badge badge-success">Claimed</span>
                                    )
                                  ) : (
                                    <span className="badge">Pending (game not resolved)</span>
                                  )}
                                </span>
                              </div>
                            </>
                          )}
                        </div>

                        {/* RAT Test Info */}
                        {selectedGameDetail.ratTestDetail && (
                          <>
                            <h3 style={{marginTop: '1.5rem'}}>RAT Test Info</h3>
                            <div className="info-list">
                              <div className="info-row">
                                <span className="info-label">Test ID:</span>
                                <code>{selectedGameDetail.ratTestDetail.testId.substring(0, 18)}...</code>
                              </div>
                              <div className="info-row">
                                <span className="info-label">Validator:</span>
                                <code>{formatAddress(selectedGameDetail.ratTestDetail.validator)}</code>
                              </div>
                              <div className="info-row">
                                <span className="info-label">Status:</span>
                                <span className={`badge ${
                                  selectedGameDetail.ratTestDetail.status === 5 ? 'badge-error' :
                                  selectedGameDetail.ratTestDetail.status === 3 || selectedGameDetail.ratTestDetail.status === 4 ? 'badge-success' : 'badge-warning'
                                }`}>
                                  {selectedGameDetail.ratTestDetail.statusLabel}
                                </span>
                              </div>
                              <div className="info-row">
                                <span className="info-label">Bond:</span>
                                <span>{parseFloat(selectedGameDetail.ratTestDetail.bondAmount).toFixed(2)} WTON</span>
                              </div>
                              <div className="info-row">
                                <span className="info-label">Deadline:</span>
                                <span>{formatTimestamp(selectedGameDetail.ratTestDetail.deadline)}</span>
                              </div>
                            </div>
                          </>
                        )}

                        {/* Fast Withdrawal Info */}
                        <h3 style={{marginTop: '1.5rem'}}>⚡ Fast Withdrawal Info</h3>
                        <div className="info-list">
                          <div className="info-row">
                            <span className="info-label">Fast Withdrawal Executed:</span>
                            <span>
                              {selectedGameDetail.hasFastWithdrawal ? (
                                <span className="badge badge-success">⚡ Yes</span>
                              ) : (
                                <span className="badge">No</span>
                              )}
                            </span>
                          </div>
                        </div>

                        {/* Claim Data Table */}
                        {selectedGameDetail.claims.length > 0 && (
                          <>
                            <h3 style={{marginTop: '1.5rem'}}>Claim Data ({selectedGameDetail.claims.length})</h3>
                            <div className="table-container">
                              <table>
                                <thead>
                                  <tr>
                                    <th>#</th>
                                    <th>Parent</th>
                                    <th>Claimant</th>
                                    <th>Countered By</th>
                                    <th>Bond</th>
                                    <th>Claim</th>
                                  </tr>
                                </thead>
                                <tbody>
                                  {selectedGameDetail.claims.map((c) => (
                                    <tr key={c.index}>
                                      <td>{c.index}</td>
                                      <td>{c.parentIndex}</td>
                                      <td><code>{formatAddress(c.claimant)}</code></td>
                                      <td>
                                        {c.counteredBy === ethers.ZeroAddress ? '-' : <code>{formatAddress(c.counteredBy)}</code>}
                                      </td>
                                      <td>{parseFloat(c.bond).toFixed(4)} ETH</td>
                                      <td><code>{c.claim.substring(0, 10)}...</code></td>
                                    </tr>
                                  ))}
                                </tbody>
                              </table>
                            </div>
                          </>
                        )}
                      </div>
                    )}
                  </section>
                </div>
              )}

              {/* Proposer Tab */}
              {activeTab === 'proposer' && (
                <div className="section">
                  <section className="card">
                    <h2>📡 Proposer Health Status</h2>
                    {proposerInfo ? (
                      <div className="info-list">
                        <div className="info-row">
                          <span className="info-label">Status:</span>
                          <span className={proposerInfo.isHealthy ? 'status-success' : 'status-error'}>
                            {proposerInfo.isHealthy ? '✅ Healthy' : '⚠️ Unhealthy'}
                          </span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Proposer Address:</span>
                          <span style={{display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                            <code>{proposerInfo.proposerAddress || 'Unknown'}</code>
                            <span className="badge" style={{fontSize: '0.65rem'}}>
                              {proposerInfo.proposerAddressSource === 'claimant' ? 'from game claimant' :
                               proposerInfo.proposerAddressSource === 'config' ? 'from config' : 'unknown'}
                            </span>
                          </span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">ETH Balance:</span>
                          <span className={parseFloat(proposerInfo.ethBalance) < parseFloat(proposerInfo.initBond) ? 'status-error' : ''}>
                            {parseFloat(proposerInfo.ethBalance).toFixed(4)} ETH
                            {parseFloat(proposerInfo.ethBalance) < parseFloat(proposerInfo.initBond) && ' ⚠️ Below initBond'}
                          </span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Init Bond (Game Creation Cost):</span>
                          <span>{parseFloat(proposerInfo.initBond).toFixed(6)} ETH</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Game Type:</span>
                          <span className="badge">{proposerInfo.gameType === 0 ? '0 (FaultDisputeGame)' : proposerInfo.gameType}</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Proposal Interval (Config):</span>
                          <span className="badge">{CONFIG.proposerSettings.proposalInterval}s ({CONFIG.proposerSettings.proposalInterval / 60}m)</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Poll Interval (Config):</span>
                          <span>{CONFIG.proposerSettings.pollInterval}s</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Allow Non-Finalized:</span>
                          <span className="badge">{CONFIG.proposerSettings.allowNonFinalized ? 'Yes (based on safe_l2)' : 'No (based on finalized_l2)'}</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Total Games Created:</span>
                          <span className="badge">{proposerInfo.totalGames}</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Latest Game:</span>
                          <span>{proposerInfo.latestGame ? formatTimestamp(proposerInfo.latestGame.timestamp) : 'No games yet'}</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Latest Proposed L2 Block:</span>
                          <span>{proposerInfo.latestGame?.l2BlockNumber || 'N/A'}</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Last Game Age:</span>
                          <span className={proposerInfo.lastGameAge > 600 ? 'status-warning' : ''}>
                            {proposerInfo.lastGameAge > 0 ? `${proposerInfo.lastGameAge}s (${Math.round(proposerInfo.lastGameAge / 60)}m ago)` : 'N/A'}
                          </span>
                        </div>
                      </div>
                    ) : (
                      <p className="empty-state">Loading proposer info...</p>
                    )}
                    <small style={{ marginTop: '0.5rem', display: 'block', color: 'var(--text-light)', lineHeight: '1.6' }}>
                      <strong>op-proposer behavior:</strong> Every poll interval ({CONFIG.proposerSettings.pollInterval}s), checks the L2 output root.
                      If the root has changed after the proposal interval ({CONFIG.proposerSettings.proposalInterval}s = {CONFIG.proposerSettings.proposalInterval / 60}m),
                      calls DisputeGameFactory.create() to create a new game.
                      Requires initBond amount of ETH per game creation.
                      {CONFIG.proposerSettings.allowNonFinalized && ' (AllowNonFinalized: proposes based on safe_l2)'}
                    </small>
                  </section>

                  <section className="card">
                    <h2>🔄 Sync Status</h2>
                    {proposerInfo?.syncStatus ? (
                      <div className="info-list">
                        <div className="info-row">
                          <span className="info-label">Current L1 Block:</span>
                          <span>{proposerInfo.syncStatus.currentL1.number}</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Unsafe L2 Head:</span>
                          <span>{proposerInfo.syncStatus.unsafeL2.number}</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Safe L2 Head:</span>
                          <span>{proposerInfo.syncStatus.safeL2.number}</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Finalized L2 Head:</span>
                          <span>{proposerInfo.syncStatus.finalizedL2.number}</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Proposer Lag (Safe - Latest Proposed):</span>
                          <span className={`badge ${
                            proposerInfo.lag < 10 ? 'badge-success' :
                            proposerInfo.lag < 50 ? 'badge-warning' : 'badge-error'
                          }`}>
                            {proposerInfo.lag} blocks
                          </span>
                        </div>
                      </div>
                    ) : (
                      <p className="empty-state">op-node not reachable</p>
                    )}
                  </section>

                  <section className="card">
                    <h2>📊 Activity Metrics</h2>
                    {proposerInfo ? (
                      <div className="info-list">
                        <div className="info-row">
                          <span className="info-label">Games in Last 1h:</span>
                          <span className="badge">{proposerInfo.gamesLast1h}</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Games in Last 24h:</span>
                          <span className="badge">{proposerInfo.gamesLast24h}</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Average Interval:</span>
                          <span>{proposerInfo.averageInterval > 0 ? `${proposerInfo.averageInterval}s` : 'N/A'}</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Game Creation Rate:</span>
                          <span>
                            {proposerInfo.averageInterval > 0
                              ? `${(3600 / proposerInfo.averageInterval).toFixed(1)} games/hr`
                              : 'N/A'}
                          </span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Inferred Proposal Interval (Median):</span>
                          <span>{proposerInfo.inferredProposalInterval > 0 ? `${proposerInfo.inferredProposalInterval}s` : 'N/A'}</span>
                        </div>
                      </div>
                    ) : (
                      <p className="empty-state">Loading...</p>
                    )}
                    <small style={{ marginTop: '0.5rem', display: 'block', color: 'var(--text-light)' }}>
                      Proposal Interval is inferred from the median of game timestamp differences. Compare with the configured value (OP_PROPOSER_PROPOSAL_INTERVAL).
                    </small>
                  </section>

                  {/* Game Creation Timeline */}
                  {proposerInfo && proposerInfo.gameIntervals.length > 0 && (
                    <section className="card">
                      <h2>📈 Game Creation Timeline</h2>
                      <small style={{display: 'block', marginBottom: '0.5rem', color: 'var(--text-light)'}}>
                        Bar height = interval between consecutive games (seconds)
                      </small>
                      <div className="interval-bar-container">
                        {(() => {
                          const maxInterval = Math.max(...proposerInfo.gameIntervals);
                          return proposerInfo.gameIntervals.map((interval, idx) => (
                            <div
                              key={idx}
                              className="interval-bar"
                              style={{
                                height: `${maxInterval > 0 ? (interval / maxInterval) * 100 : 0}%`,
                                backgroundColor: interval > proposerInfo.averageInterval * 2 ? '#f14668' :
                                  interval > proposerInfo.averageInterval * 1.5 ? '#ffe08a' : '#3e8ed0',
                              }}
                              title={`Game ${idx + 1} → ${idx + 2}: ${interval}s`}
                            />
                          ));
                        })()}
                      </div>
                      <div className="interval-bar-label">
                        <span>Oldest</span>
                        <span>Avg: {proposerInfo.averageInterval}s</span>
                        <span>Latest</span>
                      </div>
                    </section>
                  )}

                  {/* Output Root Details */}
                  {proposerInfo && proposerInfo.outputRoots.length > 0 && (
                    <section className="card">
                      <h2>📋 Output Root Details</h2>
                      <small style={{display: 'block', marginBottom: '0.5rem', color: 'var(--text-light)'}}>
                        Click a row to view game details.
                      </small>
                      <div className="table-container">
                        <table className="games-table">
                          <thead>
                            <tr>
                              <th>Game #</th>
                              <th>L2 Block</th>
                              <th>Root Claim</th>
                              <th>Block Range</th>
                            </tr>
                          </thead>
                          <tbody>
                            {proposerInfo.outputRoots.slice(-10).reverse().map((root, idx) => {
                              const game = enhancedGames.find(g => g.index === root.index);
                              return (
                                <tr
                                  key={idx}
                                  className={`clickable-row ${selectedGameDetail?.index === root.index ? 'selected' : ''}`}
                                  onClick={() => game && (selectedGameDetail?.index === root.index ? setSelectedGameDetail(null) : loadGameDetail(game))}
                                >
                                  <td>{root.index}</td>
                                  <td>{root.l2Block}</td>
                                  <td><code>{root.rootClaim.substring(0, 10)}...</code></td>
                                  <td>{root.blockRange}</td>
                                </tr>
                              );
                            })}
                          </tbody>
                        </table>
                      </div>

                      {/* Game Detail Panel (inline) */}
                      {selectedGameDetail && (
                        <div className="game-detail-panel" style={{marginTop: '1rem'}}>
                          <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
                            <h3>Game #{selectedGameDetail.index} Details</h3>
                            <button className="btn btn-small btn-secondary" onClick={() => setSelectedGameDetail(null)}>Close</button>
                          </div>
                          <div className="info-list">
                            <div className="info-row">
                              <span className="info-label">Proxy:</span>
                              <code>{selectedGameDetail.proxy}</code>
                            </div>
                            <div className="info-row">
                              <span className="info-label">Status:</span>
                              <span className={`badge ${getDetailedGameStatus(selectedGameDetail).badgeClass}`}>
                                {getDetailedGameStatus(selectedGameDetail).label}
                              </span>
                            </div>
                            <div className="info-row">
                              <span className="info-label">Root Claim:</span>
                              <code>{selectedGameDetail.rootClaim}</code>
                            </div>
                            <div className="info-row">
                              <span className="info-label">L2 Block:</span>
                              <span>{selectedGameDetail.l2BlockNumber}</span>
                            </div>
                            <div className="info-row">
                              <span className="info-label">Starting Block:</span>
                              <span>{selectedGameDetail.startingBlockNumber}</span>
                            </div>
                            <div className="info-row">
                              <span className="info-label">Created At:</span>
                              <span>{selectedGameDetail.createdAt > 0 ? formatTimestamp(selectedGameDetail.createdAt) : 'N/A'}</span>
                            </div>
                            <div className="info-row">
                              <span className="info-label">Resolved At:</span>
                              <span>{getResolvedAtDisplay(selectedGameDetail)}</span>
                            </div>
                            <div className="info-row">
                              <span className="info-label">Max Clock Duration:</span>
                              <span>{selectedGameDetail.maxClockDuration}s ({Math.round(selectedGameDetail.maxClockDuration / 60)}m)</span>
                            </div>
                            {selectedGameDetail.proposerAddress && (
                              <>
                                <div className="info-row">
                                  <span className="info-label">Proposer:</span>
                                  <code>{formatAddress(selectedGameDetail.proposerAddress)}</code>
                                </div>
                                <div className="info-row">
                                  <span className="info-label">Proposer Bond:</span>
                                  <span>{selectedGameDetail.proposerBond} ETH</span>
                                </div>
                                <div className="info-row">
                                  <span className="info-label">Bond Credit:</span>
                                  <span>
                                    {selectedGameDetail.resolvedAt > 0 ? (
                                      parseFloat(selectedGameDetail.proposerCredit) > 0 ? (
                                        <span className="badge badge-warning">Unclaimed ({selectedGameDetail.proposerCredit} ETH)</span>
                                      ) : (
                                        <span className="badge badge-success">Claimed</span>
                                      )
                                    ) : (
                                      <span className="badge">Pending (game not resolved)</span>
                                    )}
                                  </span>
                                </div>
                              </>
                            )}
                          </div>

                          {/* RAT Test Info */}
                          {selectedGameDetail.ratTestDetail && (
                            <>
                              <h3 style={{marginTop: '1.5rem'}}>RAT Test Info</h3>
                              <div className="info-list">
                                <div className="info-row">
                                  <span className="info-label">Test ID:</span>
                                  <code>{selectedGameDetail.ratTestDetail.testId.substring(0, 18)}...</code>
                                </div>
                                <div className="info-row">
                                  <span className="info-label">Validator:</span>
                                  <code>{formatAddress(selectedGameDetail.ratTestDetail.validator)}</code>
                                </div>
                                <div className="info-row">
                                  <span className="info-label">Status:</span>
                                  <span className={`badge ${
                                    selectedGameDetail.ratTestDetail.status === 5 ? 'badge-error' :
                                    selectedGameDetail.ratTestDetail.status === 3 || selectedGameDetail.ratTestDetail.status === 4 ? 'badge-success' : 'badge-warning'
                                  }`}>
                                    {selectedGameDetail.ratTestDetail.statusLabel}
                                  </span>
                                </div>
                                <div className="info-row">
                                  <span className="info-label">Bond:</span>
                                  <span>{parseFloat(selectedGameDetail.ratTestDetail.bondAmount).toFixed(2)} WTON</span>
                                </div>
                                <div className="info-row">
                                  <span className="info-label">Deadline:</span>
                                  <span>{formatTimestamp(selectedGameDetail.ratTestDetail.deadline)}</span>
                                </div>
                              </div>
                            </>
                          )}

                          {/* Claim Data Table */}
                          {selectedGameDetail.claims.length > 0 && (
                            <>
                              <h3 style={{marginTop: '1.5rem'}}>Claim Data ({selectedGameDetail.claims.length})</h3>
                              <div className="table-container">
                                <table>
                                  <thead>
                                    <tr>
                                      <th>#</th>
                                      <th>Parent</th>
                                      <th>Claimant</th>
                                      <th>Countered By</th>
                                      <th>Bond</th>
                                      <th>Claim</th>
                                    </tr>
                                  </thead>
                                  <tbody>
                                    {selectedGameDetail.claims.map((c) => (
                                      <tr key={c.index}>
                                        <td>{c.index}</td>
                                        <td>{c.parentIndex}</td>
                                        <td><code>{formatAddress(c.claimant)}</code></td>
                                        <td>
                                          {c.counteredBy === ethers.ZeroAddress ? '-' : <code>{formatAddress(c.counteredBy)}</code>}
                                        </td>
                                        <td>{parseFloat(c.bond).toFixed(6)} ETH</td>
                                        <td><code>{c.claim.substring(0, 10)}...</code></td>
                                      </tr>
                                    ))}
                                  </tbody>
                                </table>
                              </div>
                            </>
                          )}
                        </div>
                      )}
                    </section>
                  )}

                  <section className="card">
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <h2>🎮 Recent Games</h2>
                      <button
                        onClick={async () => {
                          try {
                            setLoading(true);
                            await loadProposerInfo();
                          } catch (error: any) {
                            console.error('Refresh failed:', error);
                          } finally {
                            setLoading(false);
                          }
                        }}
                        disabled={loading}
                        className="btn btn-secondary"
                        style={{ padding: '0.3rem 0.8rem', fontSize: '0.85rem' }}
                      >
                        {loading ? '⏳' : '🔄'} Refresh
                      </button>
                    </div>
                    {proposerInfo && proposerInfo.recentGames.length > 0 ? (
                      <div className="table-container">
                        <table className="games-table">
                          <thead>
                            <tr>
                              <th>#</th>
                              <th>Status</th>
                              <th>L2 Block</th>
                              <th>Claims</th>
                              <th>Created</th>
                            </tr>
                          </thead>
                          <tbody>
                            {proposerInfo.recentGames.map((game, idx) => {
                              const statusLabels: Record<number, string> = { 0: 'InProgress', 1: 'ChallengerWins', 2: 'DefenderWins' };
                              return (
                                <tr key={idx}>
                                  <td>{game.index}</td>
                                  <td><span className="badge">{statusLabels[game.status] || `${game.status}`}</span></td>
                                  <td>{game.l2BlockNumber}</td>
                                  <td>{game.claimCount}</td>
                                  <td>{formatTimestamp(game.timestamp)}</td>
                                </tr>
                              );
                            })}
                          </tbody>
                        </table>
                      </div>
                    ) : (
                      <p className="empty-state">No games found</p>
                    )}
                  </section>
                </div>
              )}

              {/* Batcher Tab */}
              {activeTab === 'batcher' && (
                <div className="section">
                  <section className="card">
                    <h2>📦 Batcher Health Status</h2>
                    {batcherInfo ? (
                      <div className="info-list">
                        <div className="info-row">
                          <span className="info-label">Status:</span>
                          <span className={batcherInfo.isHealthy ? 'status-success' : 'status-error'}>
                            {batcherInfo.isHealthy ? '✅ Healthy' : '⚠️ Unhealthy (high safe lag)'}
                          </span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Batcher Address:</span>
                          <code>{batcherInfo.address}</code>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Batch Inbox:</span>
                          <code>{batcherInfo.batchInbox}</code>
                        </div>
                        <div className="info-row">
                          <span className="info-label">ETH Balance:</span>
                          <span className={parseFloat(batcherInfo.ethBalance) < 0.1 ? 'status-error' : ''}>
                            {parseFloat(batcherInfo.ethBalance).toFixed(4)} ETH
                            {parseFloat(batcherInfo.ethBalance) < 0.1 && ' ⚠️ Low Balance'}
                          </span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">DA Type:</span>
                          <span className="badge">{batcherInfo.daType}</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Poll Interval (Config):</span>
                          <span>{CONFIG.batcherSettings.pollInterval}s</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Max Channel Duration (Config):</span>
                          <span>{CONFIG.batcherSettings.maxChannelDuration} L1 blocks</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">L1 Nonce:</span>
                          <span>{batcherInfo.nonce}</span>
                        </div>
                      </div>
                    ) : (
                      <p className="empty-state">Loading batcher info... (requires L2 info to be loaded first)</p>
                    )}
                  </section>

                  {/* Batch Submission Metrics - L1 TX 분석 기반 */}
                  {batcherInfo && batcherInfo.txCount > 0 && (
                    <section className="card">
                      <h2>📊 Batch Submission Metrics</h2>
                      <div className="info-list">
                        <div className="info-row">
                          <span className="info-label">Recent Batch TXs (L1 Scan):</span>
                          <span className="badge">{batcherInfo.txCount}</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Average Batch Interval:</span>
                          <span>{batcherInfo.avgBatchInterval > 0 ? `${batcherInfo.avgBatchInterval}s` : 'N/A'}</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Submission Rate:</span>
                          <span>
                            {batcherInfo.avgBatchInterval > 0
                              ? `${(3600 / batcherInfo.avgBatchInterval).toFixed(1)} batches/hr`
                              : 'N/A'}
                          </span>
                        </div>
                      </div>
                      <small style={{ marginTop: '0.5rem', display: 'block', color: 'var(--text-light)' }}>
                        Calculated by scanning Batcher→BatchInbox TXs from the last 50 L1 blocks.
                      </small>
                    </section>
                  )}

                  {/* Data Throughput - L1 TX calldata/blob 분석 */}
                  {batcherInfo && batcherInfo.txCount > 0 && (
                    <section className="card">
                      <h2>📈 L1 Data Throughput</h2>
                      <div className="info-list">
                        <div className="info-row">
                          <span className="info-label">Total Calldata:</span>
                          <span>{(batcherInfo.totalDataBytes / 1024).toFixed(1)} KB ({batcherInfo.totalDataBytes.toLocaleString()} bytes)</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Avg Calldata per TX:</span>
                          <span>{batcherInfo.avgDataPerTx.toLocaleString()} bytes</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Avg Gas per TX:</span>
                          <span>{batcherInfo.avgGasPerTx.toLocaleString()}</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Gas Efficiency:</span>
                          <span>{batcherInfo.avgGasPerTx > 0 ? `${(batcherInfo.avgDataPerTx / batcherInfo.avgGasPerTx * 1000).toFixed(2)} bytes/kgas` : 'N/A'}</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">DA Type:</span>
                          <span className="badge">{batcherInfo.daType}</span>
                        </div>
                      </div>
                      <small style={{ marginTop: '0.5rem', display: 'block', color: 'var(--text-light)', lineHeight: '1.6' }}>
                        <strong>op-batcher behavior:</strong> Every poll interval ({CONFIG.batcherSettings.pollInterval}s), checks for new L2 blocks,
                        groups them into channels, compresses, splits into frames, and submits to L1.
                        Max Channel Duration: {CONFIG.batcherSettings.maxChannelDuration} L1 blocks.
                        If DA Type is blobs, submits via EIP-4844 blob TX (type 3); if calldata, uses regular TX.
                      </small>
                    </section>
                  )}

                  <section className="card">
                    <h2>📈 L2 Head Progress</h2>
                    {batcherInfo?.syncStatus ? (
                      <div className="info-list">
                        <div className="info-row">
                          <span className="info-label">Unsafe L2 Head:</span>
                          <span>{batcherInfo.syncStatus.unsafeL2.number}</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Safe L2 Head:</span>
                          <span>{batcherInfo.syncStatus.safeL2.number}</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Finalized L2 Head:</span>
                          <span>{batcherInfo.syncStatus.finalizedL2.number}</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Safe Lag (Unsafe - Safe):</span>
                          <span className={`badge ${
                            batcherInfo.safeLag < 20 ? 'badge-success' :
                            batcherInfo.safeLag < 50 ? 'badge-warning' : 'badge-error'
                          }`}>
                            {batcherInfo.safeLag} blocks
                            {batcherInfo.safeLag < 20 ? ' (Good)' : batcherInfo.safeLag < 50 ? ' (Behind)' : ' (Critical)'}
                          </span>
                        </div>
                      </div>
                    ) : (
                      <p className="empty-state">op-node not reachable</p>
                    )}
                    <small style={{ marginTop: '0.5rem', display: 'block', color: 'var(--text-light)' }}>
                      Safe head advances when batcher submits batches to L1
                    </small>
                  </section>

                  <section className="card">
                    <h2>📋 Recent Batch Transactions ({batcherInfo?.recentBatchTxs.length || 0})</h2>
                    {batcherInfo && batcherInfo.recentBatchTxs.length > 0 ? (
                      <div className="table-container">
                        <table className="games-table">
                          <thead>
                            <tr>
                              <th>TX Hash</th>
                              <th>Type</th>
                              <th>L1 Block</th>
                              <th>Time</th>
                              <th>Gas Used</th>
                              <th>Data Size</th>
                            </tr>
                          </thead>
                          <tbody>
                            {batcherInfo.recentBatchTxs.map((tx, idx) => (
                              <tr key={idx}>
                                <td><code>{tx.hash.substring(0, 10)}...{tx.hash.substring(62)}</code></td>
                                <td>
                                  <span className="badge">
                                    {tx.type === 3 ? 'Blob' : tx.type === 2 ? 'EIP-1559' : 'Legacy'}
                                  </span>
                                </td>
                                <td>{tx.blockNumber}</td>
                                <td>{formatTimestamp(tx.timestamp)}</td>
                                <td>{parseInt(tx.gasUsed).toLocaleString()}</td>
                                <td>{tx.dataSize.toLocaleString()} bytes</td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                      </div>
                    ) : (
                      <p className="empty-state">No batch transactions found in recent blocks</p>
                    )}
                  </section>
                </div>
              )}

              {/* Game/Withdrawal Settings Tab */}
              {activeTab === 'game-settings' && (
                <div className="section">
                  {gameWithdrawalSettings ? (
                    <>
                      {/* Card 1: Dispute Game Settings */}
                      <section className="card">
                        <h2>🎮 Dispute Game Settings</h2>
                        <p style={{ fontSize: '0.85em', color: '#888', marginBottom: '10px' }}>
                          Contract: FaultDisputeGame impl (<code>{gameWithdrawalSettings.gameImplAddress}</code>)
                          {gameWithdrawalSettings.gameProxy && <>, Ref Proxy (<code>{gameWithdrawalSettings.gameProxy}</code>)</>}
                        </p>
                        <div className="info-list">
                          <div className="info-row">
                            <span className="info-label">Max Clock Duration:</span>
                            <span>{gameWithdrawalSettings.maxClockDuration}s ({formatDuration(gameWithdrawalSettings.maxClockDuration)})</span>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Clock Extension:</span>
                            <span>{gameWithdrawalSettings.clockExtension}s ({formatDuration(gameWithdrawalSettings.clockExtension)})</span>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Max Game Depth:</span>
                            <span>{gameWithdrawalSettings.maxGameDepth}</span>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Split Depth:</span>
                            <span>{gameWithdrawalSettings.splitDepth}</span>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Absolute Prestate:</span>
                            <code style={{ fontSize: '0.85em' }}>{gameWithdrawalSettings.absolutePrestate}</code>
                          </div>
                          <div className="info-row">
                            <span className="info-label">L2 Chain ID:</span>
                            <span>{gameWithdrawalSettings.l2ChainId}</span>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Init Bond (DGF):</span>
                            <span>{gameWithdrawalSettings.initBond} ETH</span>
                          </div>
                        </div>
                      </section>

                      {/* Card 2: Bond Withdrawal Settings (DelayedWETH) */}
                      <section className="card">
                        <h2>💰 Bond Withdrawal Settings (DelayedWETH)</h2>
                        <p style={{ fontSize: '0.85em', color: '#888', marginBottom: '10px' }}>
                          Contract: <code>{gameWithdrawalSettings.wethAddress}</code>
                        </p>
                        <div className="info-list">
                          <div className="info-row">
                            <span className="info-label">Withdrawal Delay:</span>
                            <span>{gameWithdrawalSettings.wethDelay}s ({formatDuration(gameWithdrawalSettings.wethDelay)})</span>
                          </div>
                        </div>
                      </section>

                      {/* Card 3: Withdrawal Settings (OptimismPortal2) */}
                      <section className="card">
                        <h2>🚪 Withdrawal Settings (OptimismPortal2)</h2>
                        <p style={{ fontSize: '0.85em', color: '#888', marginBottom: '10px' }}>
                          Contract: <code>{gameWithdrawalSettings.portalAddress}</code>
                        </p>
                        <div className="info-list">
                          <div className="info-row">
                            <span className="info-label">Proof Maturity Delay:</span>
                            <span>{gameWithdrawalSettings.proofMaturityDelay}s ({formatDuration(gameWithdrawalSettings.proofMaturityDelay)})</span>
                          </div>
                          <div style={{ padding: '0.25rem 0 0.5rem 1rem', fontSize: '0.85em', color: '#9ca3af' }}>
                            출금 증명(prove) 후 finalize까지 기다려야 하는 최소 시간. 이 기간 동안 잘못된 증명에 대해 챌린지할 수 있습니다.
                          </div>
                          <div className="info-row">
                            <span className="info-label">Dispute Game Finality Delay:</span>
                            <span>{gameWithdrawalSettings.disputeGameFinalityDelay}s ({formatDuration(gameWithdrawalSettings.disputeGameFinalityDelay)})</span>
                          </div>
                          <div style={{ padding: '0.25rem 0 0.5rem 1rem', fontSize: '0.85em', color: '#9ca3af' }}>
                            Dispute Game이 resolve된 후 추가로 대기하는 안전 기간 (Airgap). Game 결과가 확정된 후에도 비정상적 상황에 대비합니다.
                          </div>
                          <div className="info-row">
                            <span className="info-label">Fast Withdrawal Response Period:</span>
                            <span>{gameWithdrawalSettings.fastWithdrawalResponsePeriod}s ({formatDuration(gameWithdrawalSettings.fastWithdrawalResponsePeriod)})</span>
                          </div>
                          <div style={{ padding: '0.25rem 0 0.5rem 1rem', fontSize: '0.85em', color: '#9ca3af' }}>
                            Fast Withdrawal 요청 후 RAT 검증자들이 BLS 서명을 제출할 수 있는 기간. 이 기간 내에 충분한 서명이 모이면 챌린지 기간 없이 즉시 출금됩니다.
                          </div>
                          <div className="info-row">
                            <span className="info-label">RAT Contract:</span>
                            <code>{gameWithdrawalSettings.ratContractOnPortal}</code>
                          </div>
                          <div className="info-row">
                            <span className="info-label">SeigManager:</span>
                            <code>{gameWithdrawalSettings.seigManagerOnPortal}</code>
                          </div>
                        </div>
                      </section>

                      {/* Card 3.5: Challenge Period Summary */}
                      <section className="card">
                        <h2>🛡️ Challenge Period (챌린지 기간)</h2>
                        <p style={{ fontSize: '0.85em', color: '#888', marginBottom: '15px' }}>
                          Prove 후 Finalize까지의 보안 대기 기간. 두 딜레이 모두 Evidence Submission Period 이상이어야 합니다.
                        </p>
                        <div style={{
                          background: 'rgba(139, 92, 246, 0.05)',
                          border: '1px solid rgba(139, 92, 246, 0.2)',
                          borderRadius: '12px',
                          padding: '1.25rem',
                          marginBottom: '1rem',
                        }}>
                          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', flexWrap: 'wrap', marginBottom: '1rem' }}>
                            <div style={{ background: '#3b82f6', color: 'white', padding: '0.3rem 0.7rem', borderRadius: '6px', fontSize: '0.85em', fontWeight: 'bold' }}>
                              1. Prove
                            </div>
                            <div style={{ color: '#9ca3af', fontSize: '1.2em' }}>→</div>
                            <div style={{ background: '#f59e0b', color: 'white', padding: '0.3rem 0.7rem', borderRadius: '6px', fontSize: '0.85em', fontWeight: 'bold' }}>
                              2. Proof Maturity ({formatDuration(gameWithdrawalSettings.proofMaturityDelay)})
                            </div>
                            <div style={{ color: '#9ca3af', fontSize: '1.2em' }}>+</div>
                            <div style={{ background: '#f97316', color: 'white', padding: '0.3rem 0.7rem', borderRadius: '6px', fontSize: '0.85em', fontWeight: 'bold' }}>
                              3. Game Finality ({formatDuration(gameWithdrawalSettings.disputeGameFinalityDelay)})
                            </div>
                            <div style={{ color: '#9ca3af', fontSize: '1.2em' }}>→</div>
                            <div style={{ background: '#10b981', color: 'white', padding: '0.3rem 0.7rem', borderRadius: '6px', fontSize: '0.85em', fontWeight: 'bold' }}>
                              4. Finalize
                            </div>
                          </div>
                          <div style={{
                            background: 'rgba(139, 92, 246, 0.1)',
                            border: '1px solid rgba(139, 92, 246, 0.3)',
                            borderRadius: '8px',
                            padding: '0.75rem 1rem',
                            textAlign: 'center',
                          }}>
                            <span style={{ fontSize: '0.85em', color: '#9ca3af' }}>Total Challenge Period: </span>
                            <span style={{ fontSize: '1.1em', fontWeight: 'bold', color: '#8b5cf6' }}>
                              {formatDuration(gameWithdrawalSettings.proofMaturityDelay + gameWithdrawalSettings.disputeGameFinalityDelay)}
                            </span>
                            <span style={{ fontSize: '0.85em', color: '#9ca3af' }}>
                              {' '}({gameWithdrawalSettings.proofMaturityDelay + gameWithdrawalSettings.disputeGameFinalityDelay}s)
                            </span>
                          </div>
                        </div>
                        <div className="info-list">
                          <div className="info-row">
                            <span className="info-label">Proof Maturity Delay:</span>
                            <span>
                              {gameWithdrawalSettings.proofMaturityDelay}s ({formatDuration(gameWithdrawalSettings.proofMaturityDelay)})
                              {gameWithdrawalSettings.proofMaturityDelay < gameWithdrawalSettings.evidenceSubmissionPeriod && (
                                <span style={{ color: '#ef4444', marginLeft: '0.5rem', fontWeight: 'bold' }}>(too short!)</span>
                              )}
                            </span>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Game Finality Delay:</span>
                            <span>
                              {gameWithdrawalSettings.disputeGameFinalityDelay}s ({formatDuration(gameWithdrawalSettings.disputeGameFinalityDelay)})
                              {gameWithdrawalSettings.disputeGameFinalityDelay < gameWithdrawalSettings.evidenceSubmissionPeriod && (
                                <span style={{ color: '#ef4444', marginLeft: '0.5rem', fontWeight: 'bold' }}>(too short!)</span>
                              )}
                            </span>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Evidence Submission Period:</span>
                            <span>{gameWithdrawalSettings.evidenceSubmissionPeriod}s ({formatDuration(gameWithdrawalSettings.evidenceSubmissionPeriod)})</span>
                          </div>
                          <div className="info-row">
                            <span className="info-label">FW Response Period:</span>
                            <span>{gameWithdrawalSettings.fastWithdrawalResponsePeriod}s ({formatDuration(gameWithdrawalSettings.fastWithdrawalResponsePeriod)})</span>
                          </div>
                        </div>
                        {(gameWithdrawalSettings.proofMaturityDelay < gameWithdrawalSettings.evidenceSubmissionPeriod ||
                          gameWithdrawalSettings.disputeGameFinalityDelay < gameWithdrawalSettings.evidenceSubmissionPeriod) && (
                          <div style={{
                            background: 'rgba(239, 68, 68, 0.08)',
                            border: '2px solid rgba(239, 68, 68, 0.4)',
                            borderRadius: '10px',
                            padding: '1rem',
                            marginTop: '1rem',
                          }}>
                            <div style={{ fontWeight: 'bold', color: '#ef4444', marginBottom: '0.5rem' }}>
                              Constraint Violations
                            </div>
                            {gameWithdrawalSettings.proofMaturityDelay < gameWithdrawalSettings.evidenceSubmissionPeriod && (
                              <div style={{ fontSize: '0.9em', color: '#fca5a5', marginBottom: '0.25rem' }}>
                                Proof Maturity Delay ({formatDuration(gameWithdrawalSettings.proofMaturityDelay)})
                                {' < '}Evidence Submission Period ({formatDuration(gameWithdrawalSettings.evidenceSubmissionPeriod)})
                              </div>
                            )}
                            {gameWithdrawalSettings.disputeGameFinalityDelay < gameWithdrawalSettings.evidenceSubmissionPeriod && (
                              <div style={{ fontSize: '0.9em', color: '#fca5a5' }}>
                                Game Finality Delay ({formatDuration(gameWithdrawalSettings.disputeGameFinalityDelay)})
                                {' < '}Evidence Submission Period ({formatDuration(gameWithdrawalSettings.evidenceSubmissionPeriod)})
                              </div>
                            )}
                          </div>
                        )}
                      </section>

                      {/* Card 4: RAT Verification Settings */}
                      <section className="card">
                        <h2>🔍 RAT Verification Settings</h2>
                        <p style={{ fontSize: '0.85em', color: '#888', marginBottom: '10px' }}>
                          Contract: <code>{gameWithdrawalSettings.ratAddress}</code>
                        </p>
                        <div className="info-list">
                          <div className="info-row">
                            <span className="info-label">Evidence Submission Period:</span>
                            <span>{gameWithdrawalSettings.evidenceSubmissionPeriod}s ({formatDuration(gameWithdrawalSettings.evidenceSubmissionPeriod)})</span>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Min Validators for Fast Withdrawal:</span>
                            <span>{gameWithdrawalSettings.minValidatorsForFW}</span>
                          </div>
                        </div>
                      </section>

                      {/* Card 5: Timing Summary Table */}
                      <section className="card">
                        <h2>📋 Timing Summary</h2>
                        <div className="table-container">
                          <table>
                            <thead>
                              <tr>
                                <th>Setting</th>
                                <th>Value</th>
                                <th>Contract</th>
                                <th>Mutable</th>
                              </tr>
                            </thead>
                            <tbody>
                              <tr>
                                <td>Max Clock Duration</td>
                                <td>{formatDuration(gameWithdrawalSettings.maxClockDuration)}</td>
                                <td>FaultDisputeGame</td>
                                <td>❌ Immutable</td>
                              </tr>
                              <tr>
                                <td>Clock Extension</td>
                                <td>{formatDuration(gameWithdrawalSettings.clockExtension)}</td>
                                <td>FaultDisputeGame</td>
                                <td>❌ Immutable</td>
                              </tr>
                              <tr>
                                <td>DelayedWETH Delay</td>
                                <td>{formatDuration(gameWithdrawalSettings.wethDelay)}</td>
                                <td>DelayedWETH</td>
                                <td>✅ Owner</td>
                              </tr>
                              <tr>
                                <td>Proof Maturity Delay</td>
                                <td>{formatDuration(gameWithdrawalSettings.proofMaturityDelay)}</td>
                                <td>OptimismPortal2</td>
                                <td>❌ Immutable</td>
                              </tr>
                              <tr>
                                <td>Dispute Game Finality Delay</td>
                                <td>{formatDuration(gameWithdrawalSettings.disputeGameFinalityDelay)}</td>
                                <td>OptimismPortal2</td>
                                <td>❌ Immutable</td>
                              </tr>
                              <tr>
                                <td>Fast Withdrawal Response Period</td>
                                <td>{formatDuration(gameWithdrawalSettings.fastWithdrawalResponsePeriod)}</td>
                                <td>OptimismPortal2</td>
                                <td>✅ Owner</td>
                              </tr>
                              <tr>
                                <td>Evidence Submission Period</td>
                                <td>{formatDuration(gameWithdrawalSettings.evidenceSubmissionPeriod)}</td>
                                <td>RAT</td>
                                <td>✅ Owner</td>
                              </tr>
                              <tr>
                                <td>Init Bond</td>
                                <td>{gameWithdrawalSettings.initBond} ETH</td>
                                <td>DisputeGameFactory</td>
                                <td>✅ Owner</td>
                              </tr>
                            </tbody>
                          </table>
                        </div>
                      </section>
                    </>
                  ) : (
                    <section className="card">
                      <p className="empty-state">Loading game/withdrawal settings...</p>
                    </section>
                  )}
                </div>
              )}

              {/* L1 Information Tab */}
              {activeTab === 'l1-info' && (
                <div className="section">
                  <section className="card">
                    <h2>🔗 L1 Network Information</h2>
                    {nodeStatus && (
                      <div className="info-list">
                        <div className="info-row">
                          <span className="info-label">L1 Chain ID:</span>
                          <span className="badge badge-success">{nodeStatus.l1ChainId}</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">L1 Block Number:</span>
                          <span>{nodeStatus.l1Block}</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">L1 RPC URL:</span>
                          <code>{CONFIG.rpcUrl}</code>
                        </div>
                        <div className="info-row">
                          <span className="info-label">L1 Status:</span>
                          <span className={nodeStatus.l1Running ? 'status-success' : 'status-error'}>
                            {nodeStatus.l1Running ? '✅ Running' : '❌ Not Running'}
                          </span>
                        </div>
                      </div>
                    )}
                  </section>

                  <section className="card">
                    <h2>⛓️ Optimism L1 Contracts</h2>
                    {l2Info && (
                      <div className="info-list">
                        <div className="info-row">
                          <span className="info-label">SystemConfig:</span>
                          <code>{CONFIG.contracts.systemConfig}</code>
                        </div>
                        <div className="info-row">
                          <span className="info-label">OptimismPortal:</span>
                          <code>{l2Info.portal}</code>
                        </div>
                        <div className="info-row">
                          <span className="info-label">DisputeGameFactory:</span>
                          <code>{l2Info.disputeGameFactory}</code>
                        </div>
                        <div className="info-row">
                          <span className="info-label">L1StandardBridge:</span>
                          <code>{l2Info.l1Bridge}</code>
                        </div>
                        <div className="info-row">
                          <span className="info-label">L1CrossDomainMessenger:</span>
                          <code>{l2Info.l1CrossDomainMessenger}</code>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Batch Inbox:</span>
                          <code>{l2Info.batchInbox}</code>
                        </div>
                      </div>
                    )}
                  </section>

                  <section className="card">
                    <h2>🔒 Portal Security Status</h2>
                    {l2Info && (
                      <div className="info-list">
                        <div className="info-row">
                          <span className="info-label">Portal Guardian:</span>
                          <code>{l2Info.portalGuardian}</code>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Portal Status:</span>
                          <span className={l2Info.portalPaused ? 'status-offline' : 'status-online'}>
                            {l2Info.portalPaused ? '⏸️ Paused' : '✅ Active'}
                          </span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Portal ETH Balance:</span>
                          <span>{parseFloat(l2Info.portalEthBalance).toFixed(4)} ETH</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Portal TON Balance:</span>
                          <span>{parseFloat(l2Info.portalTonBalance).toFixed(4)} TON</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Bridge TON Balance:</span>
                          <span>{parseFloat(l2Info.bridgeTonBalance).toFixed(4)} TON</span>
                        </div>
                      </div>
                    )}
                  </section>

                  <section className="card">
                    <h2>📊 TON Staking V3 Contracts</h2>
                    <div className="info-list">
                      <div className="info-row">
                        <span className="info-label">TON:</span>
                        <code>{CONFIG.contracts.ton}</code>
                      </div>
                      <div className="info-row">
                        <span className="info-label">WTON:</span>
                        <code>{CONFIG.contracts.wton}</code>
                      </div>
                      <div className="info-row">
                        <span className="info-label">SeigManager:</span>
                        <code>{CONFIG.contracts.seigManager}</code>
                      </div>
                      <div className="info-row">
                        <span className="info-label">DepositManager:</span>
                        <code>{CONFIG.contracts.depositManager}</code>
                      </div>
                      <div className="info-row">
                        <span className="info-label">Layer2Manager:</span>
                        <code>{CONFIG.contracts.layer2Manager}</code>
                      </div>
                      <div className="info-row">
                        <span className="info-label">L1BridgeRegistry:</span>
                        <code>{CONFIG.contracts.l1BridgeRegistry}</code>
                      </div>
                      <div className="info-row">
                        <span className="info-label">Layer2Registry:</span>
                        <code>{CONFIG.contracts.layer2Registry}</code>
                      </div>
                      <div className="info-row">
                        <span className="info-label">RAT:</span>
                        <code>{CONFIG.contracts.rat}</code>
                      </div>
                      <div className="info-row">
                        <span className="info-label">ValidatorReward:</span>
                        <code>{CONFIG.contracts.validatorReward}</code>
                      </div>
                    </div>
                  </section>
                </div>
              )}

              {/* L2 Information Tab */}
              {activeTab === 'l2-info' && (
                <div className="section">
                  <section className="card">
                    <h2>🌐 L2 Network Information</h2>
                    {l2Info && (
                      <>
                        <div className="info-list">
                          <div className="info-row">
                            <span className="info-label">SystemConfig:</span>
                            <code>{CONFIG.contracts.systemConfig}</code>
                          </div>
                          <div className="info-row">
                            <span className="info-label">L2 Chain ID:</span>
                            <span className={l2Info.l2ChainId === '901' ? 'badge badge-success' : l2Info.l2ChainId === 'N/A' ? 'badge' : 'badge badge-error'}>
                              {l2Info.l2ChainId}
                            </span>
                          </div>
                          <div className="info-row">
                            <span className="info-label">L2 Block Number:</span>
                            <span>{l2Info.l2BlockNumber}</span>
                          </div>
                          <div className="info-row">
                            <span className="info-label">L2 RPC URL:</span>
                            <code>{CONFIG.l2RpcUrl}</code>
                          </div>
                        </div>
                      </>
                    )}
                  </section>

                  <section className="card">
                    <h2>👤 Proposer & Batcher</h2>
                    {l2Info && (
                      <div className="info-list">
                        <div className="info-row">
                          <span className="info-label">Batcher Hash:</span>
                          <code>{l2Info.batcherHash}</code>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Batcher Address (from hash):</span>
                          <code>{l2Info.batcherHash.substring(0, 42)}</code>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Unsafe Block Signer (Proposer):</span>
                          <code>{l2Info.unsafeBlockSigner}</code>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Batch Inbox:</span>
                          <code>{l2Info.batchInbox}</code>
                        </div>
                      </div>
                    )}
                  </section>

                  <section className="card">
                    <h2>🔧 System Configuration</h2>
                    {l2Info && (
                      <div className="info-list">
                        <div className="info-row">
                          <span className="info-label">Gas Limit:</span>
                          <span>{parseInt(l2Info.gasLimit).toLocaleString()}</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Overhead:</span>
                          <span>{l2Info.overhead}</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Scalar:</span>
                          <span>{l2Info.scalar}</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Base Fee Scalar:</span>
                          <span>{l2Info.basefeeScalar} ({(parseFloat(l2Info.basefeeScalar) / 1000000 * 100).toFixed(4)}%)</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Blob Base Fee Scalar:</span>
                          <span>{l2Info.blobbasefeeScalar} ({(parseFloat(l2Info.blobbasefeeScalar) / 1000000 * 100).toFixed(4)}%)</span>
                        </div>
                      </div>
                    )}
                  </section>

                  <section className="card">
                    <h2>🌉 Bridge & Portal Addresses</h2>
                    {l2Info && (
                      <div className="info-list">
                        <div className="info-row">
                          <span className="info-label">L1 Standard Bridge:</span>
                          <code>{l2Info.l1Bridge}</code>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Optimism Portal:</span>
                          <code>{l2Info.portal}</code>
                        </div>
                        <div className="info-row">
                          <span className="info-label">L1 CrossDomain Messenger:</span>
                          <code>{l2Info.l1CrossDomainMessenger}</code>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Dispute Game Factory:</span>
                          <code>{l2Info.disputeGameFactory}</code>
                        </div>
                      </div>
                    )}
                  </section>

                  <section className="card">
                    <h2>🛡️ Portal Status & Balances</h2>
                    {l2Info && (
                      <div className="info-list">
                        <div className="info-row">
                          <span className="info-label">Guardian:</span>
                          <code>{l2Info.portalGuardian}</code>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Paused:</span>
                          <span className={l2Info.portalPaused ? 'status-error' : 'status-success'}>
                            {l2Info.portalPaused ? '⚠️ Yes (Paused)' : '✅ No (Active)'}
                          </span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Portal TON Balance:</span>
                          <span className="value-large">{parseFloat(l2Info.portalTonBalance).toFixed(4)} TON</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Portal ETH Balance:</span>
                          <span>{parseFloat(l2Info.portalEthBalance).toFixed(4)} ETH</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Bridge TON Balance:</span>
                          <span className="value-large">{parseFloat(l2Info.bridgeTonBalance).toFixed(4)} TON</span>
                        </div>
                      </div>
                    )}
                  </section>
                </div>
              )}

              {/* Bridge Tab */}
              {activeTab === 'bridge' && (
                <div className="section">
                  <section className="card">
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
                      <div>
                        <h2 style={{ margin: 0 }}>⚡ Bridge ETH to L2 (Deposit)</h2>
                        <p style={{ margin: '0.5rem 0 0 0' }}>Bridge ETH from L1 to L2 using Optimism Portal</p>
                      </div>
                      <button
                        onClick={async () => {
                          if (!address) {
                            alert('Please connect wallet first');
                            return;
                          }
                          try {
                            setLoading(true);
                            await Promise.all([
                              loadDashboardData(),
                              loadUserBalances(address)
                            ]);
                            alert('✅ Data refreshed!');
                          } catch (error: any) {
                            console.error('Refresh failed:', error);
                            alert(`❌ Refresh failed: ${error.message || 'Unknown error'}`);
                          } finally {
                            setLoading(false);
                          }
                        }}
                        disabled={loading || !address}
                        className="btn btn-secondary"
                        style={{ padding: '0.5rem 1rem', whiteSpace: 'nowrap' }}
                      >
                        {loading ? '⏳' : '🔄'} Refresh Data
                      </button>
                    </div>
                    {l2Info && (
                      <>
                        <div className="info-list" style={{ marginBottom: '1rem' }}>
                          <div className="info-row">
                            <span className="info-label">L1 Standard Bridge:</span>
                            <code>{l2Info.l1Bridge}</code>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Your L1 ETH Balance:</span>
                            <span className="value-large">{parseFloat(ethBalance).toFixed(4)} ETH</span>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Portal ETH Balance:</span>
                            <span>{parseFloat(l2Info.portalEthBalance).toFixed(4)} ETH</span>
                          </div>
                          <div className="info-row">
                            <span className="info-label">ETHLockbox ETH Balance:</span>
                            <span className="value-large">{parseFloat(l2Info.ethLockboxBalance).toFixed(4)} ETH</span>
                          </div>
                          <div className="info-row">
                            <span className="info-label">ETHLockbox Address:</span>
                            <code>{l2Info.ethLockboxAddress}</code>
                          </div>
                        </div>
                        <div className="action-form">
                          <input
                            type="number"
                            placeholder="Amount (ETH)"
                            className="input"
                            id="bridge-eth-input"
                            step="0.01"
                            min="0"
                          />
                          <button
                            onClick={async () => {
                              const input = document.getElementById('bridge-eth-input') as HTMLInputElement;
                              const amount = input.value;
                              if (!signer || !amount || parseFloat(amount) <= 0) {
                                alert('Please enter a valid amount');
                                return;
                              }
                              
                              try {
                                setLoading(true);
                                const amountWei = ethers.parseEther(amount);
                                
                                const bridgeContract = new ethers.Contract(l2Info.l1Bridge, L1_STANDARD_BRIDGE_ABI, signer);
                                const tx = await bridgeContract.depositETH(200000, '0x', { value: amountWei });
                                await tx.wait();
                                
                                alert('✅ ETH deposit to L2 successful! Wait ~1 minute for L2 confirmation.');
                                input.value = '';
                                await loadDashboardData();
                              } catch (error: any) {
                                console.error('Bridge failed:', error);
                                alert(`❌ Failed: ${error.message || 'Unknown error'}`);
                              } finally {
                                setLoading(false);
                              }
                            }}
                            disabled={loading}
                            className="btn btn-primary"
                          >
                            {loading ? '⏳ Depositing...' : '⬇️ Deposit ETH to L2'}
                          </button>
                        </div>
                        <small>Gas Limit: 200,000 (sufficient for standard bridge)</small>
                      </>
                    )}
                  </section>

                  <section className="card">
                    <h2>💎 Bridge TON to L2 (Deposit)</h2>
                    <p>Bridge TON tokens from L1 to L2</p>
                    {l2Info && rollupInfo && (
                      <>
                        <div className="info-list" style={{ marginBottom: '1rem' }}>
                          <div className="info-row">
                            <span className="info-label">L1 TON:</span>
                            <code>{CONFIG.contracts.ton}</code>
                          </div>
                          <div className="info-row">
                            <span className="info-label">L2 TON:</span>
                            <code>{rollupInfo.l2Ton}</code>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Your L1 TON Balance:</span>
                            <span>{parseFloat(tonBalance).toFixed(4)} TON</span>
                          </div>
                        </div>
                        <div className="action-form">
                          <input
                            type="number"
                            placeholder="Amount (TON)"
                            className="input"
                            id="bridge-ton-input"
                            step="0.01"
                            min="0"
                          />
                          <button
                            onClick={async () => {
                              const input = document.getElementById('bridge-ton-input') as HTMLInputElement;
                              const amount = input.value;
                              if (!signer || !amount || parseFloat(amount) <= 0) {
                                alert('Please enter a valid amount');
                                return;
                              }
                              
                              try {
                                setLoading(true);
                                const amountWei = ethers.parseEther(amount);
                                
                                // 1. Approve TON
                                const tonContract = new ethers.Contract(CONFIG.contracts.ton, TON_ABI, signer);
                                const approveTx = await tonContract.approve(l2Info.l1Bridge, amountWei);
                                await approveTx.wait();
                                
                                // 2. Bridge TON
                                const bridgeContract = new ethers.Contract(l2Info.l1Bridge, L1_STANDARD_BRIDGE_ABI, signer);
                                const bridgeTx = await bridgeContract.depositERC20(
                                  CONFIG.contracts.ton,
                                  rollupInfo.l2Ton,
                                  amountWei,
                                  200000,
                                  '0x'
                                );
                                await bridgeTx.wait();
                                
                                alert('✅ TON deposit to L2 successful! Wait ~1 minute for L2 confirmation.');
                                input.value = '';
                                await loadDashboardData();
                                if (address) await loadUserBalances(address);
                              } catch (error: any) {
                                console.error('TON bridge failed:', error);
                                alert(`❌ Failed: ${error.message || 'Unknown error'}`);
                              } finally {
                                setLoading(false);
                              }
                            }}
                            disabled={loading}
                            className="btn btn-primary"
                          >
                            {loading ? '⏳ Depositing...' : '⬇️ Deposit TON to L2'}
                          </button>
                        </div>
                        <small>Your L1 TON Balance: {parseFloat(tonBalance).toFixed(4)} TON</small>
                      </>
                    )}
                  </section>

                  <section className="card">
                    <h2>📤 Withdraw ETH from L2</h2>
                    <p>Initiate ETH withdrawal from L2 to L1 (requires L2 wallet connection)</p>
                    {nodeStatus?.l2Running ? (
                      <>
                        <div className="info-list" style={{ marginBottom: '1rem' }}>
                          <div className="info-row">
                            <span className="info-label">L2 Standard Bridge:</span>
                            <code>0x4200000000000000000000000000000000000010</code>
                          </div>
                          <div className="info-row">
                            <span className="info-label">L2 RPC:</span>
                            <code>{CONFIG.l2RpcUrl}</code>
                          </div>
                        </div>
                        <div className="action-form">
                          <input
                            type="number"
                            placeholder="Amount (ETH)"
                            className="input"
                            id="withdraw-eth-input"
                            step="0.01"
                            min="0"
                          />
                          <button
                            onClick={async () => {
                              const input = document.getElementById('withdraw-eth-input') as HTMLInputElement;
                              const amount = input.value;
                              if (!signer || !amount || parseFloat(amount) <= 0) {
                                alert('Please connect wallet and enter a valid amount');
                                return;
                              }

                              try {
                                setLoading(true);
                                const amountWei = ethers.parseEther(amount);

                                // Switch to L2 network
                                try {
                                  await window.ethereum.request({
                                    method: 'wallet_switchEthereumChain',
                                    params: [{ chainId: '0x385' }], // 901 in hex
                                  });
                                } catch (switchError: any) {
                                  if (switchError.code === 4902) {
                                    await window.ethereum.request({
                                      method: 'wallet_addEthereumChain',
                                      params: [{
                                        chainId: '0x385',
                                        chainName: 'TON L2 Local',
                                        nativeCurrency: { name: 'Ethereum', symbol: 'ETH', decimals: 18 },
                                        rpcUrls: [CONFIG.l2RpcUrl],
                                      }],
                                    });
                                  } else {
                                    throw switchError;
                                  }
                                }
                                
                                // Create new provider after chain switch
                                const l2Provider = new ethers.BrowserProvider(window.ethereum);
                                const l2Signer = await l2Provider.getSigner();
                                const l2BridgeContract = new ethers.Contract(
                                  '0x4200000000000000000000000000000000000010',
                                  L2_STANDARD_BRIDGE_ABI,
                                  l2Signer
                                );

                                // Withdraw ETH from L2
                                const tx = await l2BridgeContract.bridgeETH(200000, '0x', { value: amountWei });
                                const receipt = await tx.wait();
                                const l2TxHash = receipt?.hash || tx.hash;

                                input.value = '';

                                // Switch back to L1
                                await window.ethereum.request({
                                  method: 'wallet_switchEthereumChain',
                                  params: [{ chainId: `0x${CONFIG.chainId.toString(16)}` }],
                                });

                                // Show result on screen and auto-track
                                setLastWithdrawalResult({ txHash: l2TxHash, type: 'ETH' });
                                setWithdrawalTxHashInput(l2TxHash);
                                trackWithdrawal(l2TxHash);
                              } catch (error: any) {
                                console.error('Withdrawal failed:', error);
                                alert(`❌ Failed: ${error.message || 'Unknown error'}`);
                              } finally {
                                setLoading(false);
                              }
                            }}
                            disabled={loading}
                            className="btn btn-primary"
                          >
                            {loading ? '⏳ Withdrawing...' : '⬆️ Withdraw ETH from L2'}
                          </button>
                        </div>
                        <small>⚠️ Note: After withdrawal request, you must wait for challenge period and finalize on L1</small>
                      </>
                    ) : (
                      <div className="warning-box">
                        <p>⚠️ L2 is not running. Please start the L2 node first.</p>
                      </div>
                    )}
                  </section>

                  <section className="card">
                    <h2>💎 Withdraw TON from L2</h2>
                    <p>Initiate TON withdrawal from L2 to L1 (requires L2 wallet connection)</p>
                    {nodeStatus?.l2Running && rollupInfo ? (
                      <>
                        <div className="info-list" style={{ marginBottom: '1rem' }}>
                          <div className="info-row">
                            <span className="info-label">L2 Standard Bridge:</span>
                            <code>0x4200000000000000000000000000000000000010</code>
                          </div>
                          <div className="info-row">
                            <span className="info-label">L2 TON:</span>
                            <code>{rollupInfo.l2Ton}</code>
                          </div>
                        </div>
                        <div className="action-form">
                          <input
                            type="number"
                            placeholder="Amount (TON)"
                            className="input"
                            id="withdraw-ton-input"
                            step="0.01"
                            min="0"
                          />
                          <button
                            onClick={async () => {
                              const input = document.getElementById('withdraw-ton-input') as HTMLInputElement;
                              const amount = input.value;
                              if (!signer || !amount || parseFloat(amount) <= 0) {
                                alert('Please connect wallet and enter a valid amount');
                                return;
                              }
                              
                              try {
                                setLoading(true);
                                const amountWei = ethers.parseEther(amount);
                                
                                // Switch to L2 network
                                try {
                                  await window.ethereum.request({
                                    method: 'wallet_switchEthereumChain',
                                    params: [{ chainId: '0x385' }], // 901 in hex
                                  });
                                } catch (switchError: any) {
                                  if (switchError.code === 4902) {
                                    await window.ethereum.request({
                                      method: 'wallet_addEthereumChain',
                                      params: [{
                                        chainId: '0x385',
                                        chainName: 'TON L2 Local',
                                        nativeCurrency: { name: 'Ethereum', symbol: 'ETH', decimals: 18 },
                                        rpcUrls: [CONFIG.l2RpcUrl],
                                      }],
                                    });
                                  } else {
                                    throw switchError;
                                  }
                                }
                                
                                // Create new provider after chain switch
                                const l2Provider = new ethers.BrowserProvider(window.ethereum);
                                const l2Signer = await l2Provider.getSigner();

                                // Approve L2 TON
                                const l2TonContract = new ethers.Contract(rollupInfo.l2Ton, TON_ABI, l2Signer);
                                const approveTx = await l2TonContract.approve(
                                  '0x4200000000000000000000000000000000000010',
                                  amountWei
                                );
                                await approveTx.wait();
                                
                                // Withdraw TON from L2
                                const l2BridgeContract = new ethers.Contract(
                                  '0x4200000000000000000000000000000000000010',
                                  L2_STANDARD_BRIDGE_ABI,
                                  l2Signer
                                );
                                const tx = await l2BridgeContract.withdraw(
                                  rollupInfo.l2Ton,
                                  amountWei,
                                  200000,
                                  '0x'
                                );
                                const tonReceipt = await tx.wait();
                                const tonL2TxHash = tonReceipt?.hash || tx.hash;

                                input.value = '';

                                // Switch back to L1
                                await window.ethereum.request({
                                  method: 'wallet_switchEthereumChain',
                                  params: [{ chainId: `0x${CONFIG.chainId.toString(16)}` }],
                                });

                                // Show result on screen and auto-track
                                setLastWithdrawalResult({ txHash: tonL2TxHash, type: 'TON' });
                                setWithdrawalTxHashInput(tonL2TxHash);
                                trackWithdrawal(tonL2TxHash);
                              } catch (error: any) {
                                console.error('TON withdrawal failed:', error);
                                alert(`❌ Failed: ${error.message || 'Unknown error'}`);
                              } finally {
                                setLoading(false);
                              }
                            }}
                            disabled={loading}
                            className="btn btn-primary"
                          >
                            {loading ? '⏳ Withdrawing...' : '⬆️ Withdraw TON from L2'}
                          </button>
                        </div>
                        <small>⚠️ Note: After withdrawal request, you must wait for challenge period and finalize on L1</small>
                      </>
                    ) : (
                      <div className="warning-box">
                        <p>⚠️ L2 is not running or rollup info not available.</p>
                      </div>
                    )}
                  </section>

                  {/* Last Withdrawal Result */}
                  {lastWithdrawalResult && (
                    <section className="card" style={{ border: '2px solid #10b981' }}>
                      <h2>Withdrawal Initiated</h2>
                      <p>{lastWithdrawalResult.type} withdrawal submitted on L2. Track it below.</p>
                      <div className="info-list">
                        <div className="info-row">
                          <span className="info-label">L2 Transaction Hash:</span>
                          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                            <code style={{ fontSize: '0.85rem', wordBreak: 'break-all' }}>{lastWithdrawalResult.txHash}</code>
                            <button
                              onClick={() => {
                                navigator.clipboard.writeText(lastWithdrawalResult.txHash);
                              }}
                              className="btn btn-secondary"
                              style={{ padding: '0.2rem 0.5rem', fontSize: '0.8rem', whiteSpace: 'nowrap' }}
                            >
                              Copy
                            </button>
                          </div>
                        </div>
                      </div>
                      <button
                        onClick={() => setLastWithdrawalResult(null)}
                        className="btn btn-secondary"
                        style={{ marginTop: '0.5rem', fontSize: '0.85rem' }}
                      >
                        Dismiss
                      </button>
                    </section>
                  )}

                  {/* Withdrawal Tracker */}
                  <section className="card">
                    <h2>🔍 Withdrawal Tracker</h2>
                    <p>Track L2 withdrawal status and execute prove/finalize on L1</p>
                    <div className="info-list" style={{ marginBottom: '1rem' }}>
                      <div className="info-row">
                        <span className="info-label">OptimismPortal:</span>
                        <code>{l2Info?.portal || 'N/A'}</code>
                      </div>
                    </div>
                    <div className="action-form" style={{ marginBottom: '0.5rem' }}>
                      <input
                        type="text"
                        placeholder="L2 Withdrawal Transaction Hash (0x...)"
                        className="input"
                        value={withdrawalTxHashInput}
                        onChange={(e) => setWithdrawalTxHashInput(e.target.value)}
                        style={{ fontFamily: 'monospace', flex: 1 }}
                      />
                      <button
                        onClick={() => {
                          const hash = withdrawalTxHashInput.trim();
                          if (!hash) {
                            setWithdrawalError('Please enter a transaction hash');
                            return;
                          }
                          trackWithdrawal(hash);
                        }}
                        disabled={withdrawalLoading}
                        className="btn btn-primary"
                      >
                        {withdrawalLoading ? 'Loading...' : 'Track Withdrawal'}
                      </button>
                    </div>
                    {trackedWithdrawals.length > 0 && (
                      <button
                        onClick={refreshAllWithdrawals}
                        disabled={withdrawalLoading}
                        className="btn btn-secondary"
                        style={{ marginBottom: '0.5rem' }}
                      >
                        {withdrawalLoading ? 'Refreshing...' : 'Refresh All Status'}
                      </button>
                    )}
                    {withdrawalError && (
                      <div className="warning-box" style={{ marginTop: '0.5rem' }}>
                        <p>{withdrawalError}</p>
                      </div>
                    )}
                  </section>

                  {/* Withdrawal List */}
                  {trackedWithdrawals.length > 0 && (
                    <section className="card">
                      <h2>📋 Tracked Withdrawals ({trackedWithdrawals.length})</h2>
                      <div style={{ overflowX: 'auto' }}>
                        <table className="data-table" style={{ width: '100%', borderCollapse: 'collapse' }}>
                          <thead>
                            <tr>
                              <th style={{ textAlign: 'left', padding: '0.5rem' }}>L2 Tx</th>
                              <th style={{ textAlign: 'right', padding: '0.5rem' }}>Value</th>
                              <th style={{ textAlign: 'center', padding: '0.5rem' }}>Status</th>
                              <th style={{ textAlign: 'left', padding: '0.5rem' }}>Next Action</th>
                              <th style={{ textAlign: 'center', padding: '0.5rem' }}>Actions</th>
                            </tr>
                          </thead>
                          <tbody>
                            {trackedWithdrawals.map((w, idx) => (
                              <tr key={idx} style={{
                                borderBottom: '1px solid var(--border)',
                                background: selectedWithdrawal?.withdrawalHash === w.withdrawalHash ? 'var(--bg-hover, rgba(59,130,246,0.1))' : 'transparent',
                              }}>
                                <td style={{ padding: '0.5rem', fontFamily: 'monospace', fontSize: '0.85rem' }}>
                                  {w.l2TxHash.substring(0, 10)}...{w.l2TxHash.substring(62)}
                                </td>
                                <td style={{ padding: '0.5rem', textAlign: 'right', fontSize: '0.85rem' }}>
                                  {ethers.formatEther(w.value)} ETH
                                </td>
                                <td style={{ padding: '0.5rem', textAlign: 'center' }}>
                                  <span className="badge" style={{
                                    background: getStatusColor(w.status),
                                    color: 'white',
                                    padding: '0.2rem 0.5rem',
                                    borderRadius: '4px',
                                    fontSize: '0.8rem',
                                  }}>
                                    {getStatusLabel(w.status)}
                                  </span>
                                </td>
                                <td style={{ padding: '0.5rem', fontSize: '0.85rem' }}>
                                  {w.nextAction}
                                </td>
                                <td style={{ padding: '0.5rem', textAlign: 'center' }}>
                                  <button
                                    onClick={() => setSelectedWithdrawal(w)}
                                    className="btn btn-secondary"
                                    style={{ padding: '0.2rem 0.5rem', fontSize: '0.8rem' }}
                                  >
                                    Details
                                  </button>
                                </td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                      </div>
                    </section>
                  )}

                  {/* Withdrawal Detail */}
                  {selectedWithdrawal && (
                    <section className="card">
                      <h2>📄 Withdrawal Detail</h2>

                      {/* Progress Steps */}
                      <div style={{
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                        margin: '1rem 0 1.5rem 0',
                        padding: '1rem',
                        background: 'var(--bg-secondary, #f9fafb)',
                        borderRadius: '8px',
                      }}>
                        {[
                          { step: 1, label: 'L2 Initiated' },
                          { step: 2, label: 'Game Proposed' },
                          { step: 3, label: 'Proven' },
                          { step: 4, label: 'Finalized' },
                        ].map(({ step, label }, i) => {
                          const currentStep = getStepNumber(selectedWithdrawal.status);
                          const isReady = selectedWithdrawal.status === 'ready_to_prove' && step === 2;
                          const isComplete = step < currentStep || (step === currentStep && ['finalized', 'fast_finalized'].includes(selectedWithdrawal.status));
                          const isCurrent = step === currentStep && !['finalized', 'fast_finalized'].includes(selectedWithdrawal.status);
                          // step 2 is complete when status is ready_to_prove or beyond
                          const step2Done = step === 2 && ['ready_to_prove', 'proven', 'ready_to_finalize', 'finalized', 'fast_verified', 'fast_finalized'].includes(selectedWithdrawal.status);

                          return (
                            <div key={step} style={{ display: 'flex', alignItems: 'center', flex: i < 3 ? 1 : 'none' }}>
                              <div style={{ textAlign: 'center', minWidth: '70px' }}>
                                <div style={{
                                  width: '32px',
                                  height: '32px',
                                  borderRadius: '50%',
                                  display: 'flex',
                                  alignItems: 'center',
                                  justifyContent: 'center',
                                  margin: '0 auto 4px',
                                  fontSize: '0.9rem',
                                  fontWeight: 'bold',
                                  background: (isComplete || step2Done) ? '#10b981' : (isCurrent || isReady) ? '#3b82f6' : '#d1d5db',
                                  color: 'white',
                                }}>
                                  {(isComplete || step2Done) ? '\u2713' : step}
                                </div>
                                <div style={{
                                  fontSize: '0.75rem',
                                  color: (isComplete || step2Done) ? '#10b981' : (isCurrent || isReady) ? '#3b82f6' : '#9ca3af',
                                  fontWeight: (isCurrent || isReady) ? 'bold' : 'normal',
                                }}>
                                  {label}
                                </div>
                              </div>
                              {i < 3 && (
                                <div style={{
                                  flex: 1,
                                  height: '2px',
                                  background: (isComplete || step2Done) ? '#10b981' : '#d1d5db',
                                  margin: '0 8px',
                                  marginBottom: '20px',
                                }} />
                              )}
                            </div>
                          );
                        })}
                      </div>

                      {/* Detail Info */}
                      <div className="info-list">
                        <div className="info-row">
                          <span className="info-label">L2 Tx Hash:</span>
                          <code style={{ fontSize: '0.85rem' }}>{selectedWithdrawal.l2TxHash}</code>
                        </div>
                        <div className="info-row">
                          <span className="info-label">L2 Block:</span>
                          <span>{selectedWithdrawal.l2BlockNumber}</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Withdrawal Hash:</span>
                          <code style={{ fontSize: '0.85rem' }}>{selectedWithdrawal.withdrawalHash}</code>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Value:</span>
                          <span>{ethers.formatEther(selectedWithdrawal.value)} ETH</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Target:</span>
                          <code>{selectedWithdrawal.target}</code>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Status:</span>
                          <span style={{ color: getStatusColor(selectedWithdrawal.status), fontWeight: 'bold' }}>
                            {getStatusLabel(selectedWithdrawal.status)} - {selectedWithdrawal.statusMessage}
                          </span>
                        </div>
                      </div>

                      {/* Dispute Game Info */}
                      {(selectedWithdrawal.gameProxy || selectedWithdrawal.provenGameProxy) && (
                        <div style={{ marginTop: '1rem' }}>
                          <h3 style={{ fontSize: '1rem', marginBottom: '0.5rem' }}>Dispute Game</h3>
                          <div className="info-list">
                            {selectedWithdrawal.gameProxy && (
                              <>
                                <div className="info-row">
                                  <span className="info-label">Game Proxy:</span>
                                  <code style={{ fontSize: '0.85rem' }}>{selectedWithdrawal.gameProxy}</code>
                                </div>
                                <div className="info-row">
                                  <span className="info-label">Game Index:</span>
                                  <span>#{selectedWithdrawal.gameIndex}</span>
                                </div>
                                <div className="info-row">
                                  <span className="info-label">Game L2 Block:</span>
                                  <span>{selectedWithdrawal.gameL2Block}</span>
                                </div>
                                <div className="info-row">
                                  <span className="info-label">Game Type:</span>
                                  <span>{selectedWithdrawal.gameType}</span>
                                </div>
                                <div className="info-row">
                                  <span className="info-label">Game Status:</span>
                                  <span>{selectedWithdrawal.gameStatus === 0 ? 'In Progress' : selectedWithdrawal.gameStatus === 1 ? 'Challenger Wins' : selectedWithdrawal.gameStatus === 2 ? 'Defender Wins' : String(selectedWithdrawal.gameStatus)}</span>
                                </div>
                                <div className="info-row">
                                  <span className="info-label">Respected:</span>
                                  <span style={{ color: selectedWithdrawal.isGameRespected ? '#10b981' : '#f59e0b' }}>
                                    {selectedWithdrawal.isGameRespected ? 'Yes' : 'No (wasRespectedGameTypeWhenCreated = false)'}
                                  </span>
                                </div>
                                {selectedWithdrawal.isGameRespected === false && (
                                  <div className="warning-box" style={{ marginTop: '0.5rem' }}>
                                    <p>This game's type ({selectedWithdrawal.gameType}) was not the respected game type when created. Standard prove may fail with InvalidDisputeGame.</p>
                                  </div>
                                )}
                              </>
                            )}
                            {selectedWithdrawal.provenGameProxy && selectedWithdrawal.provenGameProxy !== ethers.ZeroAddress && (
                              <div className="info-row">
                                <span className="info-label">Proven Game Proxy:</span>
                                <code style={{ fontSize: '0.85rem' }}>{selectedWithdrawal.provenGameProxy}</code>
                              </div>
                            )}
                          </div>
                        </div>
                      )}

                      {/* Timing Info */}
                      {selectedWithdrawal.provenTimestamp && (
                        <div style={{ marginTop: '1rem' }}>
                          <h3 style={{ fontSize: '1rem', marginBottom: '0.5rem' }}>Timing</h3>
                          <div className="info-list">
                            <div className="info-row">
                              <span className="info-label">Proven At:</span>
                              <span>{new Date(selectedWithdrawal.provenTimestamp * 1000).toLocaleString()}</span>
                            </div>
                            {selectedWithdrawal.proofMaturityDelay !== undefined && (
                              <div className="info-row">
                                <span className="info-label">Proof Maturity Delay:</span>
                                <span>{(() => {
                                  const s = selectedWithdrawal.proofMaturityDelay!;
                                  const d = Math.floor(s / 86400);
                                  const h = Math.floor((s % 86400) / 3600);
                                  const m = Math.floor((s % 3600) / 60);
                                  return d > 0 ? `${d}d ${h}h ${m}m` : h > 0 ? `${h}h ${m}m` : `${m}m`;
                                })()} <span style={{ color: '#9ca3af', fontSize: '0.85rem' }}>(Prove 후 챌린지 대기 기간)</span></span>
                              </div>
                            )}
                            {selectedWithdrawal.disputeGameFinalityDelay !== undefined && (
                              <div className="info-row">
                                <span className="info-label">Game Finality Delay:</span>
                                <span>{(() => {
                                  const s = selectedWithdrawal.disputeGameFinalityDelay!;
                                  const d = Math.floor(s / 86400);
                                  const h = Math.floor((s % 86400) / 3600);
                                  const m = Math.floor((s % 3600) / 60);
                                  return d > 0 ? `${d}d ${h}h ${m}m` : h > 0 ? `${h}h ${m}m` : `${m}m`;
                                })()} <span style={{ color: '#9ca3af', fontSize: '0.85rem' }}>(Dispute Game 종료 후 추가 안전 대기)</span></span>
                              </div>
                            )}
                            {selectedWithdrawal.proofMaturityDelay !== undefined && selectedWithdrawal.disputeGameFinalityDelay !== undefined && (
                              <div className="info-row">
                                <span className="info-label">Total Challenge Period:</span>
                                <span style={{ fontWeight: 'bold' }}>{(() => {
                                  const s = selectedWithdrawal.proofMaturityDelay! + selectedWithdrawal.disputeGameFinalityDelay!;
                                  const d = Math.floor(s / 86400);
                                  const h = Math.floor((s % 86400) / 3600);
                                  const m = Math.floor((s % 3600) / 60);
                                  return d > 0 ? `${d}d ${h}h ${m}m` : h > 0 ? `${h}h ${m}m` : `${m}m`;
                                })()}</span>
                              </div>
                            )}
                            {selectedWithdrawal.proofMaturityDelay !== undefined && (
                              <div className="info-row">
                                <span className="info-label">Earliest Finalize At:</span>
                                <span style={{ fontWeight: 'bold', color: '#8b5cf6' }}>
                                  {new Date((selectedWithdrawal.provenTimestamp + selectedWithdrawal.proofMaturityDelay!) * 1000).toLocaleString()}
                                </span>
                              </div>
                            )}
                            {selectedWithdrawal.timeUntilFinalizable !== undefined && selectedWithdrawal.timeUntilFinalizable > 0 && (
                              <div className="info-row">
                                <span className="info-label">Time Remaining:</span>
                                <span style={{ color: '#f59e0b', fontWeight: 'bold' }}>
                                  {(() => {
                                    const s = selectedWithdrawal.timeUntilFinalizable!;
                                    const d = Math.floor(s / 86400);
                                    const h = Math.floor((s % 86400) / 3600);
                                    const m = Math.ceil((s % 3600) / 60);
                                    return d > 0 ? `~${d}d ${h}h ${m}m remaining` : h > 0 ? `~${h}h ${m}m remaining` : `~${m}m remaining`;
                                  })()}
                                </span>
                              </div>
                            )}
                            {selectedWithdrawal.timeUntilFinalizable !== undefined && selectedWithdrawal.timeUntilFinalizable === 0 && selectedWithdrawal.status === 'ready_to_finalize' && (
                              <div className="info-row">
                                <span className="info-label">Time Remaining:</span>
                                <span style={{ color: '#10b981', fontWeight: 'bold' }}>Ready to finalize now!</span>
                              </div>
                            )}
                          </div>
                        </div>
                      )}

                      {/* Action Buttons */}
                      <div style={{ marginTop: '1rem', display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
                        {selectedWithdrawal.status === 'ready_to_prove' && (
                          <>
                            <button
                              onClick={async () => {
                                try {
                                  setWithdrawalLoading(true);
                                  const proofData = await generateMerkleProof(selectedWithdrawal);
                                  if (proofData) {
                                    setWithdrawalProofData(proofData);
                                    await proveWithdrawalTx(selectedWithdrawal, proofData);
                                  }
                                } catch (error: any) {
                                  alert(`Failed to generate proof: ${error.message}`);
                                } finally {
                                  setWithdrawalLoading(false);
                                }
                              }}
                              disabled={withdrawalLoading || !signer}
                              className="btn btn-primary"
                            >
                              {withdrawalLoading ? 'Processing...' : 'Prove (Standard)'}
                            </button>
                            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.25rem', alignItems: 'flex-start' }}>
                              <button
                                onClick={async () => {
                                  try {
                                    setWithdrawalLoading(true);
                                    const proofData = await generateMerkleProof(selectedWithdrawal);
                                    if (proofData) {
                                      setWithdrawalProofData(proofData);
                                      await proveAndRequestFastWithdrawalTx(selectedWithdrawal, proofData);
                                    }
                                  } catch (error: any) {
                                    alert(`Failed: ${error.message}`);
                                  } finally {
                                    setWithdrawalLoading(false);
                                  }
                                }}
                                disabled={withdrawalLoading || !signer}
                                className="btn btn-primary"
                                style={{ background: '#8b5cf6', width: '100%' }}
                              >
                                {withdrawalLoading ? 'Processing...' : 'Prove + Fast Withdrawal'}
                              </button>
                              <small style={{ color: 'var(--text-light)', fontSize: '0.75rem' }}>
                                Fee: {fwStatus?.fwFee || '?'} TON
                              </small>
                            </div>
                          </>
                        )}

                        {selectedWithdrawal.status === 'ready_to_finalize' && (
                          <button
                            onClick={() => finalizeWithdrawalTx(selectedWithdrawal)}
                            disabled={withdrawalLoading || !signer}
                            className="btn btn-primary"
                            style={{ background: '#10b981' }}
                          >
                            {withdrawalLoading ? 'Processing...' : 'Finalize Withdrawal'}
                          </button>
                        )}

                        {(selectedWithdrawal.status === 'finalized' || selectedWithdrawal.status === 'fast_finalized') && (
                          <div style={{
                            padding: '0.75rem 1rem',
                            background: 'rgba(16, 185, 129, 0.1)',
                            border: '1px solid #10b981',
                            borderRadius: '8px',
                            color: '#10b981',
                            fontWeight: 'bold',
                          }}>
                            Withdrawal Complete{selectedWithdrawal.status === 'fast_finalized' ? ' (Fast)' : ''}
                          </div>
                        )}

                        {selectedWithdrawal.status === 'proven' && (
                          <button
                            onClick={() => reclaimFeeTx(selectedWithdrawal.withdrawalHash)}
                            disabled={withdrawalLoading || !signer}
                            className="btn btn-secondary"
                            style={{ background: '#ef4444' }}
                          >
                            {withdrawalLoading ? 'Processing...' : 'Reclaim Fee (if deadline passed)'}
                          </button>
                        )}

                        <button
                          onClick={async () => {
                            setWithdrawalLoading(true);
                            const updated = await checkWithdrawalStatus(selectedWithdrawal);
                            setSelectedWithdrawal(updated);
                            setTrackedWithdrawals(prev => prev.map(w => w.withdrawalHash === updated.withdrawalHash ? updated : w));
                            setWithdrawalLoading(false);
                          }}
                          disabled={withdrawalLoading}
                          className="btn btn-secondary"
                        >
                          {withdrawalLoading ? 'Refreshing...' : 'Refresh Status'}
                        </button>
                      </div>
                    </section>
                  )}

                  <section className="card">
                    <h2>⚡ Fast Withdrawal Status</h2>
                    <p>Check fast withdrawal readiness and lookup withdrawal status</p>
                    <div className="info-list">
                      <div className="info-row">
                        <span className="info-label">BLS Validators:</span>
                        <span>
                          {fwStatus ? (
                            <span className={fwStatus.ready ? 'status-success' : 'status-warning'}>
                              {fwStatus.blsCount} / {fwStatus.minRequired} required
                              {fwStatus.ready ? ' ✅ Ready' : ' ⚠️ Not enough'}
                            </span>
                          ) : '-'}
                        </span>
                      </div>
                      <div className="info-row">
                        <span className="info-label">Fast Withdrawal Response Period:</span>
                        <span>{fwStatus ? `${fwStatus.responsePeriod}s (${Math.round(fwStatus.responsePeriod / 60)}m)` : '-'}</span>
                      </div>
                      <div className="info-row">
                        <span className="info-label">Aggregator Fee Rate:</span>
                        <span>{fwStatus ? `${fwStatus.feeRate}%` : '-'}</span>
                      </div>
                      <div className="info-row">
                        <span className="info-label">Fast Withdrawal Fee:</span>
                        <span>{fwStatus ? `${fwStatus.fwFee} TON` : '-'}</span>
                      </div>
                    </div>
                    <button
                      onClick={async () => {
                        try {
                          setLoading(true);
                          const rat = new ethers.Contract(CONFIG.contracts.rat, RAT_ABI, l1Provider);
                          const portal = new ethers.Contract(l2Info?.portal || '', OPTIMISM_PORTAL_ABI, l1Provider);
                          const [blsVals, minFW, responsePeriod, feeRateRaw, fwFeeRaw] = await Promise.all([
                            rat.getActiveValidatorsWithBLS(CONFIG.contracts.systemConfig).catch(() => []),
                            rat.minValidatorsForFastWithdrawal().catch(() => 0),
                            portal.fastWithdrawalResponsePeriod().catch(() => 0),
                            rat.aggregatorFeeRate().catch(() => 0n),
                            rat.fastWithdrawalFee().catch(() => 0n),
                          ]);
                          const blsCount = blsVals.length;
                          const minRequired = Number(minFW);
                          const period = Number(responsePeriod);
                          const feeRate = (Number(feeRateRaw) / 100).toString();
                          const fwFee = ethers.formatEther(fwFeeRaw);
                          setFwStatus({
                            ready: blsCount >= minRequired && minRequired > 0,
                            blsCount,
                            minRequired,
                            responsePeriod: period,
                            feeRate,
                            fwFee,
                          });
                        } catch (error: any) {
                          console.error('Failed to load FW status:', error);
                        } finally {
                          setLoading(false);
                        }
                      }}
                      disabled={loading || !l2Info?.portal}
                      className="btn btn-secondary"
                      style={{ marginTop: '0.5rem', marginBottom: '1rem' }}
                    >
                      {loading ? '⏳ Loading...' : '🔄 Load FW Status'}
                    </button>

                    <h3 style={{marginTop: '1rem'}}>🔍 Check Withdrawal Hash</h3>
                    <div className="action-form">
                      <input
                        type="text"
                        placeholder="Withdrawal Hash (bytes32)"
                        className="input"
                        id="fw-check-hash"
                        style={{ fontFamily: 'monospace' }}
                      />
                      <button
                        onClick={async () => {
                          const input = document.getElementById('fw-check-hash') as HTMLInputElement;
                          const hash = input.value.trim();
                          if (!hash) {
                            alert('Please enter a withdrawal hash');
                            return;
                          }
                          try {
                            setLoading(true);
                            const portal = new ethers.Contract(l2Info?.portal || '', OPTIMISM_PORTAL_ABI, l1Provider);
                            const finalized = await portal.fastFinalizedWithdrawals(hash);
                            setFwCheckResult({ hash, finalized });
                          } catch (error: any) {
                            console.error('Failed to check FW hash:', error);
                            alert(`❌ Failed: ${error.message || 'Unknown error'}`);
                          } finally {
                            setLoading(false);
                          }
                        }}
                        disabled={loading || !l2Info?.portal}
                        className="btn btn-primary"
                      >
                        {loading ? '⏳' : '🔍'} Check
                      </button>
                    </div>
                    {fwCheckResult && (
                      <div className="info-list" style={{marginTop: '1rem'}}>
                        <div className="info-row">
                          <span className="info-label">Withdrawal Hash:</span>
                          <code>{fwCheckResult.hash.substring(0, 18)}...</code>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Fast Finalized:</span>
                          <span className={fwCheckResult.finalized ? 'status-success' : 'status-warning'}>
                            {fwCheckResult.finalized ? '✅ Yes' : '❌ No'}
                          </span>
                        </div>
                      </div>
                    )}
                  </section>
                </div>
              )}

              {/* Seigniorage Tab */}
              {activeTab === 'seigniorage' && (
                <div className="section">
                  <section className="card">
                    <h2>🎯 Select Layer2 Address</h2>
                    <p>Enter or select a Layer2 address to view its seigniorage information</p>
                    <div className="action-form" style={{ marginBottom: '1rem' }}>
                      <input
                        type="text"
                        placeholder="Layer2 Address (e.g., CandidateAddOn address)"
                        className="input"
                        id="layer2-address-input"
                        value={selectedLayer2}
                        onChange={(e) => setSelectedLayer2(e.target.value)}
                        style={{ fontFamily: 'monospace', flex: 1 }}
                      />
                      <button
                        onClick={async () => {
                          const input = document.getElementById('layer2-address-input') as HTMLInputElement;
                          const addr = input.value.trim();
                          
                          if (!addr) {
                            alert('Please enter a Layer2 address');
                            return;
                          }
                          
                          if (!ethers.isAddress(addr)) {
                            alert('Invalid Ethereum address');
                            return;
                          }
                          
                          try {
                            setLoading(true);
                            setSelectedLayer2(addr);
                            await loadSeigniorageInfo(addr);
                          } catch (error: any) {
                            console.error('Query failed:', error);
                            alert(`❌ Query failed: ${error.message || 'Unknown error'}`);
                          } finally {
                            setLoading(false);
                          }
                        }}
                        disabled={loading}
                        className="btn btn-primary"
                      >
                        {loading ? '⏳ Loading...' : '🔍 Query'}
                      </button>
                    </div>
                    {operatorInfo?.candidateAddOn && operatorInfo.candidateAddOn !== ethers.ZeroAddress && (
                      <div style={{ marginTop: '0.5rem' }}>
                        <small>Quick select: </small>
                        <button
                          onClick={() => {
                            setSelectedLayer2(operatorInfo.candidateAddOn);
                            loadSeigniorageInfo(operatorInfo.candidateAddOn);
                          }}
                          className="btn btn-secondary"
                          style={{ padding: '0.25rem 0.5rem', fontSize: '0.85rem', marginLeft: '0.5rem' }}
                        >
                          Use My CandidateAddOn ({formatAddress(operatorInfo.candidateAddOn)})
                        </button>
                      </div>
                    )}
                  </section>

                  {selectedLayer2 && ethers.isAddress(selectedLayer2) && (
                    <>
                      <section className="card">
                        <h2>🔄 Update Seigniorage</h2>
                        <p>Trigger seigniorage distribution for this Layer2</p>
                        {seigniorageInfo?.isPaused ? (
                          <div className="warning-box">
                            <p>⚠️ Seigniorage is currently paused. Cannot update until unpaused.</p>
                          </div>
                        ) : (
                          <>
                            <div className="info-list" style={{ marginBottom: '1rem' }}>
                              <div className="info-row">
                                <span className="info-label">Blocks Since Last Update:</span>
                                <span className="badge badge-success">
                                  {seigniorageInfo ? parseInt(seigniorageInfo.currentBlock) - parseInt(seigniorageInfo.lastSeigBlock) : 0}
                                </span>
                              </div>
                              <div className="info-row">
                                <span className="info-label">Eligible for Distribution:</span>
                                <span className={seigniorageInfo?.isEligible ? 'status-success' : 'status-error'}>
                                  {seigniorageInfo?.isEligible ? '✅ Yes' : '❌ No'}
                                </span>
                              </div>
                            </div>
                            <div className="action-form">
                              <button
                                onClick={async () => {
                                  if (!signer) {
                                    alert('Please connect wallet first');
                                    return;
                                  }

                                  try {
                                    setLoading(true);

                                    const seigManager = new ethers.Contract(CONFIG.contracts.seigManager, SEIG_MANAGER_ABI, signer);
                                    const tx = await seigManager.updateSeigniorageLayer(selectedLayer2);
                                    await tx.wait();

                                    alert('✅ Seigniorage updated successfully!');
                                    await loadDashboardData();
                                    if (address) await loadUserBalances(address);
                                    if (selectedLayer2) await loadSeigniorageInfo(selectedLayer2);
                                  } catch (error: any) {
                                    console.error('Update seigniorage failed:', error);
                                    alert(`❌ Failed: ${error.message || 'Unknown error'}`);
                                  } finally {
                                    setLoading(false);
                                  }
                                }}
                                disabled={loading || !signer || !selectedLayer2}
                                className="btn btn-primary"
                              >
                                {loading ? '⏳ Updating...' : '🔄 Update Seigniorage'}
                              </button>
                            </div>
                            <small>
                              {seigniorageInfo?.isEligible
                                ? 'Trigger seigniorage distribution and claim rewards'
                                : 'Not eligible - ensure you have sufficient stake and bridged TON'}
                            </small>
                          </>
                        )}
                      </section>

                      <section className="card">
                        <h2>✅ Layer2 Registration Status</h2>
                        <div className="info-list">
                          <div className="info-row">
                            <span className="info-label">Target Layer2:</span>
                            <code>{selectedLayer2}</code>
                          </div>
                          {seigniorageInfo && (
                            <>
                              <div className="info-row">
                                <span className="info-label">Registered in Layer2Registry:</span>
                                <span className={seigniorageInfo.isRegistered ? 'status-success' : 'status-error'}>
                                  {seigniorageInfo.isRegistered ? '✅ Yes' : '❌ No'}
                                </span>
                              </div>
                              <div className="info-row">
                                <span className="info-label">Layer2 Status:</span>
                                <span className={seigniorageInfo.layer2Status === 1 ? 'status-success' : 'status-error'}>
                                  {seigniorageInfo.layer2Status === 0 && '❌ Not Registered'}
                                  {seigniorageInfo.layer2Status === 1 && '✅ Active'}
                                  {seigniorageInfo.layer2Status === 2 && '⚠️ Paused'}
                                </span>
                              </div>
                              <div className="info-row">
                                <span className="info-label">RollupConfig (SystemConfig):</span>
                                <code>{seigniorageInfo.rollupConfig}</code>
                              </div>
                            </>
                          )}
                        </div>
                      </section>

                      <section className="card">
                        <h2>👤 Operator Manager Information</h2>
                        {seigniorageInfo ? (
                          <div className="info-list">
                            <div className="info-row">
                              <span className="info-label">OperatorManager Address:</span>
                              <code>{seigniorageInfo.operatorManagerAddress}</code>
                            </div>
                            <div className="info-row">
                              <span className="info-label">Claimable L2 Seigniorage:</span>
                              <span className="value-large" style={{color: '#FF9800', fontWeight: 'bold'}}>
                                {parseFloat(seigniorageInfo.claimableAmount).toFixed(4)} WTON
                              </span>
                            </div>
                            <div className="info-row">
                              <span className="info-label">OperatorManager WTON Balance (Seigniorage):</span>
                              <span className="value-large" style={{color: '#4CAF50', fontWeight: 'bold'}}>
                                {parseFloat(seigniorageInfo.operatorManagerBalance).toFixed(4)} WTON
                              </span>
                            </div>
                            <div className="info-row">
                              <span className="info-label">OperatorManager.manager():</span>
                              <code>{seigniorageInfo.operatorManagerManager}</code>
                            </div>
                            <div className="info-row">
                              <span className="info-label">SystemConfig.unsafeBlockSigner():</span>
                              <code>{seigniorageInfo.systemConfigSigner}</code>
                            </div>
                            <div className="info-row">
                              <span className="info-label">Manager == UnsafeBlockSigner:</span>
                              <span className={seigniorageInfo.signersMatch ? 'status-success' : 'status-warning'}>
                                {seigniorageInfo.signersMatch ? '✅ Match' : '⚠️ Different'}
                              </span>
                            </div>
                          </div>
                        ) : (
                          <div className="warning-box">
                            <p>⚠️ Please query a Layer2 address first</p>
                          </div>
                        )}
                      </section>

                      <section className="card">
                        <h2>⚙️ Seigniorage Issuance Factors</h2>
                        {seigniorageInfo ? (
                          <div className="info-list">
                            <div className="info-row">
                              <span className="info-label">Seigniorage Per Block:</span>
                              <span className="value-large">{parseFloat(seigniorageInfo.seigPerBlock).toFixed(4)} WTON/block</span>
                            </div>
                            <div className="info-row">
                              <span className="info-label">DAO Distribution Ratio (d):</span>
                              <span>{seigniorageInfo.daoDistributionRatio}%</span>
                            </div>
                            <div className="info-row">
                              <span className="info-label">Min Staking Ratio (θ):</span>
                              <span>{seigniorageInfo.minStakingRatio}%</span>
                            </div>
                            <div className="info-row">
                              <span className="info-label">Validator Distribution Ratio (α):</span>
                              <span>{seigniorageInfo.validatorDistributionRatio}%</span>
                            </div>
                            <div className="info-row">
                              <span className="info-label">Half Saturation Point (k):</span>
                              <span>{parseFloat(seigniorageInfo.halfSaturationPoint).toLocaleString()} TON</span>
                            </div>
                            <div className="info-row">
                              <span className="info-label">Total Effective Bridged TON (x):</span>
                              <span className="value-large">{parseFloat(seigniorageInfo.totalEffectiveBridgedTon).toFixed(4)} WTON</span>
                            </div>
                            <div className="info-row">
                              <span className="info-label">My Bridged TON:</span>
                              <span className="value-large">{parseFloat(seigniorageInfo.bridgedTon).toFixed(4)} TON</span>
                            </div>
                            <div className="info-row">
                              <span className="info-label">My Effective Bridged TON:</span>
                              <span className="value-large">{parseFloat(seigniorageInfo.effectiveBridgedTon).toFixed(4)} TON</span>
                            </div>
                          </div>
                        ) : (
                          <div className="warning-box">
                            <p>⚠️ Please query a Layer2 address first</p>
                          </div>
                        )}
                      </section>

                      <section className="card">
                        <h2>🔧 Modify Seigniorage Parameters</h2>
                        <p style={{fontSize: '0.85rem', color: '#666', marginBottom: '1rem'}}>SeigManager owner only (DAO or deployer)</p>
                        <div className="info-list">
                          <div className="info-row" style={{flexWrap: 'wrap', gap: '0.5rem'}}>
                            <span className="info-label" style={{minWidth: '200px'}}>Half Saturation Point (k):</span>
                            <div className="action-form" style={{flex: 1, marginBottom: 0}}>
                              <input type="text" placeholder="TON amount (e.g. 10000)" className="input" id="param-halfSaturationPoint" style={{fontFamily: 'monospace', maxWidth: '200px'}} />
                              <button className="btn btn-primary" disabled={loading || !signer} onClick={async () => {
                                const val = (document.getElementById('param-halfSaturationPoint') as HTMLInputElement).value.trim();
                                if (!val || isNaN(Number(val))) { alert('Enter a valid number (TON)'); return; }
                                try {
                                  setLoading(true);
                                  const seig = new ethers.Contract(CONFIG.contracts.seigManager, SEIG_MANAGER_ABI, signer);
                                  const tx = await seig.setHalfSaturationPoint(ethers.parseUnits(val, 27));
                                  await tx.wait();
                                  alert('Half Saturation Point updated!');
                                  if (selectedLayer2) await loadSeigniorageInfo(selectedLayer2);
                                } catch (e: any) { alert(`Failed: ${e.message || e}`); }
                                finally { setLoading(false); }
                              }}>{loading ? '...' : 'Set'}</button>
                            </div>
                          </div>
                          <div className="info-row" style={{flexWrap: 'wrap', gap: '0.5rem'}}>
                            <span className="info-label" style={{minWidth: '200px'}}>DAO Distribution Ratio (%):</span>
                            <div className="action-form" style={{flex: 1, marginBottom: 0}}>
                              <input type="text" placeholder="% (e.g. 20)" className="input" id="param-daoRatio" style={{fontFamily: 'monospace', maxWidth: '200px'}} />
                              <button className="btn btn-primary" disabled={loading || !signer} onClick={async () => {
                                const val = (document.getElementById('param-daoRatio') as HTMLInputElement).value.trim();
                                if (!val || isNaN(Number(val)) || Number(val) > 100) { alert('Enter 0-100'); return; }
                                try {
                                  setLoading(true);
                                  const seig = new ethers.Contract(CONFIG.contracts.seigManager, SEIG_MANAGER_ABI, signer);
                                  const ray = BigInt(Math.round(Number(val) * 1e25)) * 100n;
                                  const tx = await seig.setDaoDistributionRatio(ray);
                                  await tx.wait();
                                  alert('DAO Distribution Ratio updated!');
                                  if (selectedLayer2) await loadSeigniorageInfo(selectedLayer2);
                                } catch (e: any) { alert(`Failed: ${e.message || e}`); }
                                finally { setLoading(false); }
                              }}>{loading ? '...' : 'Set'}</button>
                            </div>
                          </div>
                          <div className="info-row" style={{flexWrap: 'wrap', gap: '0.5rem'}}>
                            <span className="info-label" style={{minWidth: '200px'}}>Min Staking Ratio (%):</span>
                            <div className="action-form" style={{flex: 1, marginBottom: 0}}>
                              <input type="text" placeholder="% (e.g. 10)" className="input" id="param-minStaking" style={{fontFamily: 'monospace', maxWidth: '200px'}} />
                              <button className="btn btn-primary" disabled={loading || !signer} onClick={async () => {
                                const val = (document.getElementById('param-minStaking') as HTMLInputElement).value.trim();
                                if (!val || isNaN(Number(val)) || Number(val) > 100) { alert('Enter 0-100'); return; }
                                try {
                                  setLoading(true);
                                  const seig = new ethers.Contract(CONFIG.contracts.seigManager, SEIG_MANAGER_ABI, signer);
                                  const ray = BigInt(Math.round(Number(val) * 1e25)) * 100n;
                                  const tx = await seig.setMinStakingRatio(ray);
                                  await tx.wait();
                                  alert('Min Staking Ratio updated!');
                                  if (selectedLayer2) await loadSeigniorageInfo(selectedLayer2);
                                } catch (e: any) { alert(`Failed: ${e.message || e}`); }
                                finally { setLoading(false); }
                              }}>{loading ? '...' : 'Set'}</button>
                            </div>
                          </div>
                          <div className="info-row" style={{flexWrap: 'wrap', gap: '0.5rem'}}>
                            <span className="info-label" style={{minWidth: '200px'}}>Validator Distribution Ratio (%):</span>
                            <div className="action-form" style={{flex: 1, marginBottom: 0}}>
                              <input type="text" placeholder="% (e.g. 20)" className="input" id="param-valRatio" style={{fontFamily: 'monospace', maxWidth: '200px'}} />
                              <button className="btn btn-primary" disabled={loading || !signer} onClick={async () => {
                                const val = (document.getElementById('param-valRatio') as HTMLInputElement).value.trim();
                                if (!val || isNaN(Number(val)) || Number(val) > 100) { alert('Enter 0-100'); return; }
                                try {
                                  setLoading(true);
                                  const seig = new ethers.Contract(CONFIG.contracts.seigManager, SEIG_MANAGER_ABI, signer);
                                  const ray = BigInt(Math.round(Number(val) * 1e25)) * 100n;
                                  const tx = await seig.setValidatorDistributionRatio(ray);
                                  await tx.wait();
                                  alert('Validator Distribution Ratio updated!');
                                  if (selectedLayer2) await loadSeigniorageInfo(selectedLayer2);
                                } catch (e: any) { alert(`Failed: ${e.message || e}`); }
                                finally { setLoading(false); }
                              }}>{loading ? '...' : 'Set'}</button>
                            </div>
                          </div>
                        </div>
                      </section>

                      <section className="card">
                        <h2>💰 Seigniorage Update History</h2>
                        {seigniorageInfo ? (
                          <>
                            <div className="info-list">
                              <div className="info-row">
                                <span className="info-label">🔄 Last Seigniorage Update Block:</span>
                                <span className="badge badge-success" style={{ fontSize: '1.1rem', fontWeight: 'bold' }}>
                                  {seigniorageInfo.lastSeigBlock}
                                </span>
                              </div>
                              <div className="info-row">
                                <span className="info-label">Current L1 Block:</span>
                                <span className="badge">{seigniorageInfo.currentBlock}</span>
                              </div>
                              <div className="info-row">
                                <span className="info-label">Blocks Since Last Update:</span>
                                <span className="badge badge-success">
                                  {parseInt(seigniorageInfo.currentBlock) - parseInt(seigniorageInfo.lastSeigBlock)} blocks
                                </span>
                              </div>
                              {(() => {
                                const span = parseInt(seigniorageInfo.currentBlock) - parseInt(seigniorageInfo.lastSeigBlock);
                                const seigPerBlock = parseFloat(seigniorageInfo.seigPerBlock);
                                const daoRatio = parseFloat(seigniorageInfo.daoDistributionRatio) / 100;
                                const valRatio = parseFloat(seigniorageInfo.validatorDistributionRatio) / 100;
                                const A = span * seigPerBlock;
                                const sDao = A * daoRatio;
                                const L = A - sDao;
                                const k = parseFloat(seigniorageInfo.halfSaturationPoint);
                                const totalEffective = parseFloat(seigniorageInfo.totalEffectiveBridgedTon);
                                const thisEffective = parseFloat(seigniorageInfo.effectiveBridgedTon);
                                const y = totalEffective > 0 ? (L * totalEffective) / (k + totalEffective) : 0;
                                const unallocated = L - y;
                                const thisShare = totalEffective > 0 ? (y * thisEffective) / totalEffective : 0;
                                const seqReward = thisShare * (1 - valRatio);
                                const valReward = thisShare * valRatio;
                                return (
                                  <>
                                    <div style={{ backgroundColor: 'var(--card-bg, #f8f9fa)', border: '1px solid var(--border, #dee2e6)', borderRadius: '8px', padding: '1rem', marginBottom: '0.5rem' }}>
                                      <strong style={{ fontSize: '0.95rem' }}>Step 1: Total Seigniorage (A)</strong>
                                      <div className="info-list" style={{ marginTop: '0.5rem' }}>
                                        <div className="info-row">
                                          <span className="info-label">span (blocks):</span>
                                          <span>{span}</span>
                                        </div>
                                        <div className="info-row">
                                          <span className="info-label">seigPerBlock:</span>
                                          <span>{seigPerBlock.toFixed(4)} WTON</span>
                                        </div>
                                        <div className="info-row">
                                          <span className="info-label">A = span x seigPerBlock:</span>
                                          <span style={{ fontWeight: 'bold' }}>{A.toFixed(4)} WTON</span>
                                        </div>
                                      </div>
                                    </div>

                                    <div style={{ backgroundColor: 'var(--card-bg, #f8f9fa)', border: '1px solid var(--border, #dee2e6)', borderRadius: '8px', padding: '1rem', marginBottom: '0.5rem' }}>
                                      <strong style={{ fontSize: '0.95rem' }}>Step 2: DAO Distribution</strong>
                                      <div className="info-list" style={{ marginTop: '0.5rem' }}>
                                        <div className="info-row">
                                          <span className="info-label">daoDistributionRatio (d):</span>
                                          <span>{seigniorageInfo.daoDistributionRatio}%</span>
                                        </div>
                                        <div className="info-row">
                                          <span className="info-label">sDao = A x d:</span>
                                          <span>{sDao.toFixed(4)} WTON</span>
                                        </div>
                                        <div className="info-row">
                                          <span className="info-label">L = A - sDao (L2 Pool):</span>
                                          <span style={{ fontWeight: 'bold' }}>{L.toFixed(4)} WTON</span>
                                        </div>
                                      </div>
                                    </div>

                                    <div style={{ backgroundColor: 'var(--card-bg, #f8f9fa)', border: '1px solid var(--border, #dee2e6)', borderRadius: '8px', padding: '1rem', marginBottom: '0.5rem' }}>
                                      <strong style={{ fontSize: '0.95rem' }}>Step 3: Hyperbolic Saturation y = L x X / (k + X)</strong>
                                      <div className="info-list" style={{ marginTop: '0.5rem' }}>
                                        <div className="info-row">
                                          <span className="info-label">X (totalEffectiveBridgedTON):</span>
                                          <span>{totalEffective.toFixed(4)} WTON</span>
                                        </div>
                                        <div className="info-row">
                                          <span className="info-label">k (halfSaturationPoint):</span>
                                          <span>{k.toLocaleString()} TON</span>
                                        </div>
                                        <div className="info-row">
                                          <span className="info-label">y = L x X / (k + X):</span>
                                          <span style={{ fontWeight: 'bold' }}>{y.toFixed(4)} WTON</span>
                                        </div>
                                        <div className="info-row">
                                          <span className="info-label">Saturation Rate (y / L):</span>
                                          <span>{L > 0 ? ((y / L) * 100).toFixed(2) : '0'}%</span>
                                        </div>
                                        <div className="info-row">
                                          <span className="info-label">Unallocated (L - y, staker reward):</span>
                                          <span>{unallocated.toFixed(4)} WTON</span>
                                        </div>
                                      </div>
                                    </div>

                                    <div style={{ backgroundColor: 'var(--card-bg, #f8f9fa)', border: '1px solid var(--border, #dee2e6)', borderRadius: '8px', padding: '1rem', marginBottom: '0.5rem' }}>
                                      <strong style={{ fontSize: '0.95rem' }}>Step 4: This L2 Share</strong>
                                      <div className="info-list" style={{ marginTop: '0.5rem' }}>
                                        <div className="info-row">
                                          <span className="info-label">This L2 effectiveBridgedTON:</span>
                                          <span>{thisEffective.toFixed(4)} WTON</span>
                                        </div>
                                        <div className="info-row">
                                          <span className="info-label">Share = y x thisEffective / totalEffective:</span>
                                          <span style={{ fontWeight: 'bold' }}>{thisShare.toFixed(4)} WTON</span>
                                        </div>
                                        <div className="info-row">
                                          <span className="info-label">validatorDistributionRatio:</span>
                                          <span>{seigniorageInfo.validatorDistributionRatio}%</span>
                                        </div>
                                        <div className="info-row">
                                          <span className="info-label">Sequencer Reward = share x (1 - valRatio):</span>
                                          <span style={{ color: '#2196F3', fontWeight: 'bold' }}>{seqReward.toFixed(4)} WTON</span>
                                        </div>
                                        <div className="info-row">
                                          <span className="info-label">Validator Reward = share x valRatio:</span>
                                          <span style={{ color: '#9C27B0', fontWeight: 'bold' }}>{valReward.toFixed(4)} WTON</span>
                                        </div>
                                      </div>
                                    </div>

                                    <div style={{ backgroundColor: '#fff3e0', border: '1px solid #FFB74D', borderRadius: '8px', padding: '1rem', marginBottom: '0.5rem' }}>
                                      <strong style={{ fontSize: '0.95rem' }}>Claimable L2 Seigniorage (from contract):</strong>
                                      <div className="info-list" style={{ marginTop: '0.5rem' }}>
                                        <div className="info-row">
                                          <span className="info-label">claimableL2Seigniorage(layer2):</span>
                                          <span className="value-large" style={{color: '#FF9800', fontWeight: 'bold'}}>
                                            {parseFloat(seigniorageInfo.claimableAmount).toFixed(4)} WTON
                                          </span>
                                        </div>
                                      </div>
                                      <small style={{ display: 'block', color: 'var(--text-light)', marginTop: '0.3rem', lineHeight: '1.5' }}>
                                        Contract view function. Should match Step 4 calculation. Differences may be due to already claimed rewards or eligibility changes.
                                      </small>
                                    </div>
                                  </>
                                );
                              })()}
                              <div className="info-row">
                                <span className="info-label">System Paused:</span>
                                <span className={seigniorageInfo.isPaused ? 'status-error' : 'status-success'}>
                                  {seigniorageInfo.isPaused ? '⚠️ Yes (Cannot Update)' : '✅ No (Can Update)'}
                                </span>
                              </div>
                            </div>
                          </>
                        ) : (
                          <div className="warning-box">
                            <p>⚠️ No data loaded yet. Please enter a Layer2 address above and click Query.</p>
                          </div>
                        )}
                      </section>

                      <section className="card">
                        <h2>📊 Reward Per Unit Tracking</h2>
                        {seigniorageInfo ? (
                          <div className="info-list">
                            <div className="info-row">
                              <span className="info-label">Bridged TON Reward Per Unit (Sequencer):</span>
                              <span>{parseFloat(seigniorageInfo.bridgedTONRewardPerUint).toFixed(9)}</span>
                            </div>
                            <div className="info-row">
                              <span className="info-label">Validator Reward Per Unit:</span>
                              <span>{parseFloat(seigniorageInfo.validatorRewardPerUint).toFixed(9)}</span>
                            </div>
                            <div className="info-row">
                              <span className="info-label">Ratio (Validator / Sequencer):</span>
                              <span>
                                {parseFloat(seigniorageInfo.bridgedTONRewardPerUint) > 0
                                  ? (parseFloat(seigniorageInfo.validatorRewardPerUint) / parseFloat(seigniorageInfo.bridgedTONRewardPerUint)).toFixed(4)
                                  : 'N/A'}
                              </span>
                            </div>
                            <div className="info-row">
                              <span className="info-label">Expected Ratio (α / (1-α)):</span>
                              <span>
                                {(parseFloat(seigniorageInfo.validatorDistributionRatio) / (100 - parseFloat(seigniorageInfo.validatorDistributionRatio))).toFixed(4)}
                              </span>
                            </div>
                          </div>
                        ) : (
                          <div className="warning-box">
                            <p>⚠️ Please query a Layer2 address first</p>
                          </div>
                        )}
                      </section>

                      <section className="card">
                        <h2>💎 Bridged TON & Required Stake</h2>
                        {seigniorageInfo ? (
                          <div className="info-list" style={{ marginBottom: '1rem' }}>
                            <div className="info-row">
                              <span className="info-label">Bridged TON:</span>
                              <span className="value-large">{parseFloat(seigniorageInfo.bridgedTon).toFixed(4)} TON</span>
                            </div>
                            <div className="info-row">
                              <span className="info-label">Required Stake (Min Collateral):</span>
                              <span className="value-large">{parseFloat(seigniorageInfo.requiredStake).toFixed(4)} WTON</span>
                            </div>
                            <div className="info-row">
                              <span className="info-label">Current Stake (Collateral):</span>
                              <span className="value-large">{parseFloat(seigniorageInfo.currentStake).toFixed(4)} WTON</span>
                            </div>
                            <div className="info-row">
                              <span className="info-label">Min Staking Ratio (θ):</span>
                              <span>{seigniorageInfo.minStakingRatio}%</span>
                            </div>
                            <div className="info-row">
                              <span className="info-label">Calculated Min (θ × Bridged TON):</span>
                              <span>{(parseFloat(seigniorageInfo.bridgedTon) * parseFloat(seigniorageInfo.minStakingRatio) / 100).toFixed(4)} WTON</span>
                            </div>
                            <div className="info-row">
                              <span className="info-label">Stake Coverage:</span>
                              <span className={parseFloat(seigniorageInfo.currentStake) >= parseFloat(seigniorageInfo.requiredStake) ? 'status-success' : 'status-error'}>
                                {parseFloat(seigniorageInfo.requiredStake) > 0
                                  ? `${((parseFloat(seigniorageInfo.currentStake) / parseFloat(seigniorageInfo.requiredStake)) * 100).toFixed(2)}%`
                                  : 'N/A'}
                              </span>
                            </div>
                          </div>
                        ) : (
                          <div className="warning-box">
                            <p>⚠️ Please query a Layer2 address first</p>
                          </div>
                        )}
                      </section>

                      <section className="card">
                        <h2>🎯 Eligibility Checklist</h2>
                        {seigniorageInfo ? (
                          <>
                            <div className="info-list" style={{ marginBottom: '1rem' }}>
                              <div className="info-row">
                                <span className="info-label">1. Registered in Layer2Registry:</span>
                                <span className={seigniorageInfo.isRegistered ? 'status-success' : 'status-error'}>
                                  {seigniorageInfo.isRegistered ? '✅ Yes' : '❌ No'}
                                </span>
                              </div>
                              <div className="info-row">
                                <span className="info-label">2. Layer2 Status Active:</span>
                                <span className={seigniorageInfo.layer2Status === 1 ? 'status-success' : 'status-error'}>
                                  {seigniorageInfo.layer2Status === 1 ? '✅ Yes (Status = 1)' : `❌ No (Status = ${seigniorageInfo.layer2Status})`}
                                </span>
                              </div>
                              <div className="info-row">
                                <span className="info-label">3. Bridged TON {'>'} 0:</span>
                                <span className={parseFloat(seigniorageInfo.bridgedTon) > 0 ? 'status-success' : 'status-error'}>
                                  {parseFloat(seigniorageInfo.bridgedTon) > 0 ? `✅ Yes (${parseFloat(seigniorageInfo.bridgedTon).toFixed(4)} TON)` : '❌ No (0 TON)'}
                                </span>
                              </div>
                              <div className="info-row">
                                <span className="info-label">4. Current Stake {'>='} Required Stake:</span>
                                <span className={parseFloat(seigniorageInfo.currentStake) >= parseFloat(seigniorageInfo.requiredStake) ? 'status-success' : 'status-error'}>
                                  {parseFloat(seigniorageInfo.currentStake) >= parseFloat(seigniorageInfo.requiredStake) 
                                    ? `✅ Yes (${parseFloat(seigniorageInfo.currentStake).toFixed(2)} >= ${parseFloat(seigniorageInfo.requiredStake).toFixed(2)} WTON)`
                                    : `❌ No (${parseFloat(seigniorageInfo.currentStake).toFixed(2)} < ${parseFloat(seigniorageInfo.requiredStake).toFixed(2)} WTON)`
                                  }
                                </span>
                              </div>
                              <div className="info-row">
                                <span className="info-label">5. Not Paused:</span>
                                <span className={!seigniorageInfo.isPaused ? 'status-success' : 'status-error'}>
                                  {!seigniorageInfo.isPaused ? '✅ Yes' : '❌ No (Paused)'}
                                </span>
                              </div>
                              <div className="info-row" style={{ marginTop: '1rem', paddingTop: '1rem', borderTop: '2px solid #eee' }}>
                                <span className="info-label"><strong>Final Eligibility:</strong></span>
                                <span className={seigniorageInfo.isEligible ? 'status-success' : 'status-error'} style={{ fontSize: '1.1rem', fontWeight: 'bold' }}>
                                  {seigniorageInfo.isEligible ? '✅ ELIGIBLE' : '❌ NOT ELIGIBLE'}
                                </span>
                              </div>
                            </div>
                            {!seigniorageInfo.isEligible && (
                              <div className="warning-box">
                                <p><strong>⚠️ Not eligible for seigniorage distribution.</strong></p>
                                <p>Fix the failed checks above to become eligible.</p>
                              </div>
                            )}
                            {seigniorageInfo.isEligible && parseFloat(seigniorageInfo.claimableAmount) > 0 && (
                              <div className="info-list" style={{ marginTop: '1rem', padding: '1rem', backgroundColor: '#e8f5e9', borderRadius: '8px' }}>
                                <div className="info-row">
                                  <span className="info-label">💰 Claimable Seigniorage:</span>
                                  <span className="value-large" style={{ color: '#2e7d32', fontWeight: 'bold' }}>
                                    {parseFloat(seigniorageInfo.claimableAmount).toFixed(4)} WTON
                                  </span>
                                </div>
                              </div>
                            )}
                          </>
                        ) : (
                          <div className="warning-box">
                            <p>⚠️ Please query a Layer2 address first</p>
                          </div>
                        )}
                      </section>

                    </>
                  )}
                </div>
              )}

              {/* L1 Balances Tab */}
              {activeTab === 'l1-balances' && (
                <div className="section">
                  <section className="card">
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
                      <h2 style={{ margin: 0 }}>💰 L1 Token Balances</h2>
                      <button
                        onClick={async () => {
                          if (!address) {
                            alert('Please connect wallet first');
                            return;
                          }
                          try {
                            setLoading(true);
                            await loadUserBalances(address);
                            alert('✅ Balances refreshed!');
                          } catch (error: any) {
                            console.error('Refresh failed:', error);
                            alert(`❌ Refresh failed: ${error.message || 'Unknown error'}`);
                          } finally {
                            setLoading(false);
                          }
                        }}
                        disabled={loading || !address}
                        className="btn btn-secondary"
                        style={{ padding: '0.5rem 1rem' }}
                      >
                        {loading ? '⏳' : '🔄'} Refresh
                      </button>
                    </div>
                    <div className="balance-cards">
                      <div className="balance-card">
                        <div className="balance-icon">⚡</div>
                        <div className="balance-label">ETH</div>
                        <div className="balance-value">{parseFloat(ethBalance).toFixed(4)}</div>
                      </div>
                      <div className="balance-card">
                        <div className="balance-icon">🪙</div>
                        <div className="balance-label">TON</div>
                        <div className="balance-value">{parseFloat(tonBalance).toFixed(4)}</div>
                      </div>
                      <div className="balance-card">
                        <div className="balance-icon">💎</div>
                        <div className="balance-label">WTON</div>
                        <div className="balance-value">{parseFloat(wtonBalance).toFixed(4)}</div>
                      </div>
                      <div className="balance-card">
                        <div className="balance-icon">🔒</div>
                        <div className="balance-label">Staked</div>
                        <div className="balance-value">{parseFloat(stakedAmount).toFixed(4)}</div>
                      </div>
                    </div>
                  </section>

                  <section className="card">
                    <h2>🚰 Faucet - Get Test Tokens</h2>
                    <p>Request test tokens for development</p>
                    <div className="action-form">
                      <button
                        onClick={async () => {
                          if (!signer || !address) {
                            alert('Please connect wallet first');
                            return;
                          }
                          
                          try {
                            setLoading(true);

                            // Send ETH from a test account using private key
                            const testPrivateKey = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'; // Anvil #0
                            const testWallet = new ethers.Wallet(testPrivateKey, l1Provider);

                            const tx = await testWallet.sendTransaction({
                              to: address,
                              value: ethers.parseEther('10'), // 10 ETH
                            });
                            await tx.wait();

                            alert('✅ Successfully sent 10 ETH!');
                            
                            // 잔액 갱신
                            await loadUserBalances(address);
                            await loadDashboardData();
                          } catch (error: any) {
                            console.error('Faucet failed:', error);
                            alert(`❌ Failed: ${error.message || 'Unknown error'}\n\nTip: You can also use "cast send" command in terminal.`);
                          } finally {
                            setLoading(false);
                          }
                        }}
                        disabled={loading || !signer}
                        className="btn btn-primary"
                      >
                        {loading ? '⏳ Sending...' : '⚡ Get 10 ETH'}
                      </button>
                      <button
                        onClick={async () => {
                          if (!signer || !address) {
                            alert('Please connect wallet first');
                            return;
                          }
                          
                          try {
                            setLoading(true);
                            
                            // TON 컨트랙트에서 mint (devnet에서만 가능)
                            const tonContract = new ethers.Contract(CONFIG.contracts.ton, [
                              ...TON_ABI,
                              'function mint(address to, uint256 amount)',
                            ], signer);
                            
                            const amount = ethers.parseEther('100'); // 100 TON
                            const tx = await tonContract.mint(address, amount);
                            await tx.wait();

                            alert('✅ Successfully minted 100 TON!');
                            
                            // 잔액 갱신
                            await loadUserBalances(address);
                            await loadDashboardData();
                          } catch (error: any) {
                            console.error('Faucet failed:', error);
                            alert(`❌ Failed: ${error.message || 'Unknown error'}`);
                          } finally {
                            setLoading(false);
                          }
                        }}
                        disabled={loading || !signer}
                        className="btn btn-primary"
                      >
                        {loading ? '⏳ Minting...' : '🪙 Get 100 TON'}
                      </button>
                      <button
                        onClick={async () => {
                          if (!signer || !address) {
                            alert('Please connect wallet first');
                            return;
                          }
                          
                          try {
                            setLoading(true);
                            
                            // WTON 컨트랙트에서 mint (WTON은 27 decimals)
                            const wtonContract = new ethers.Contract(CONFIG.contracts.wton, [
                              ...WTON_ABI,
                              'function mint(address to, uint256 amount) returns (bool)',
                            ], signer);
                            
                            const amount = ethers.parseUnits('100', 27); // 100 WTON (27 decimals)
                            const tx = await wtonContract.mint(address, amount);
                            await tx.wait();

                            alert('✅ Successfully minted 100 WTON!');
                            
                            // 잔액 갱신
                            await loadUserBalances(address);
                            await loadDashboardData();
                          } catch (error: any) {
                            console.error('Faucet failed:', error);
                            alert(`❌ Failed: ${error.message || 'Unknown error'}`);
                          } finally {
                            setLoading(false);
                          }
                        }}
                        disabled={loading || !signer}
                        className="btn btn-primary"
                      >
                        {loading ? '⏳ Minting...' : '💎 Get 100 WTON'}
                      </button>
                    </div>
                    <small>⚠️ Devnet only - These functions may not work on mainnet</small>
                  </section>

                  <section className="card">
                    <h2>🔄 Token Swap</h2>
                    <p>Swap between TON and WTON</p>
                    <div className="action-form">
                      <input
                        type="number"
                        placeholder="Amount"
                        className="input"
                        id="swap-amount"
                        step="1"
                        min="0"
                      />
                      <button
                        onClick={async () => {
                          const input = document.getElementById('swap-amount') as HTMLInputElement;
                          const amount = input.value;
                          if (!signer || !amount || parseFloat(amount) <= 0) {
                            alert('Please enter a valid amount');
                            return;
                          }
                          
                          try {
                            setLoading(true);
                            const amountWei = ethers.parseEther(amount); // TON is 18 decimals
                            
                            // Approve TON
                            const tonContract = new ethers.Contract(CONFIG.contracts.ton, TON_ABI, signer);
                            const approveTx = await tonContract.approve(CONFIG.contracts.wton, amountWei);
                            await approveTx.wait();
                            
                            // Swap TON to WTON
                            const wtonContract = new ethers.Contract(CONFIG.contracts.wton, WTON_ABI, signer);
                            const swapTx = await wtonContract.swapFromTON(amountWei);
                            await swapTx.wait();
                            
                            alert(`✅ Successfully swapped ${amount} TON to WTON!`);
                            input.value = '';
                            
                            // 잔액 갱신
                            if (address) await loadUserBalances(address);
                            await loadDashboardData();
                          } catch (error: any) {
                            console.error('Swap failed:', error);
                            alert(`❌ Failed: ${error.message || 'Unknown error'}`);
                          } finally {
                            setLoading(false);
                          }
                        }}
                        disabled={loading || !signer}
                        className="btn btn-primary"
                      >
                        {loading ? '⏳ Swapping...' : '🪙→💎 TON to WTON'}
                      </button>
                      <button
                        onClick={async () => {
                          const input = document.getElementById('swap-amount') as HTMLInputElement;
                          const amount = input.value;
                          if (!signer || !amount || parseFloat(amount) <= 0) {
                            alert('Please enter a valid amount');
                            return;
                          }
                          
                          try {
                            setLoading(true);
                            const amountWei = ethers.parseUnits(amount, 27); // WTON is 27 decimals
                            
                            // Swap WTON to TON
                            const wtonContract = new ethers.Contract(CONFIG.contracts.wton, WTON_ABI, signer);
                            const swapTx = await wtonContract.swapToTON(amountWei);
                            await swapTx.wait();
                            
                            alert(`✅ Successfully swapped ${amount} WTON to TON!`);
                            input.value = '';
                            
                            // 잔액 갱신
                            if (address) await loadUserBalances(address);
                            await loadDashboardData();
                          } catch (error: any) {
                            console.error('Swap failed:', error);
                            alert(`❌ Failed: ${error.message || 'Unknown error'}`);
                          } finally {
                            setLoading(false);
                          }
                        }}
                        disabled={loading || !signer}
                        className="btn btn-primary"
                      >
                        {loading ? '⏳ Swapping...' : '💎→🪙 WTON to TON'}
                      </button>
                    </div>
                  </section>

                  <section className="card">
                    <h2>📍 Your Account</h2>
                    <div className="info-list">
                      <div className="info-row">
                        <span className="info-label">Address:</span>
                        <code>{address}</code>
                      </div>
                      <div className="info-row">
                        <span className="info-label">Network:</span>
                        <span>{CONFIG.chainName} (Chain ID: {CONFIG.chainId})</span>
                      </div>
                    </div>
                  </section>

                  <section className="card">
                    <h2>🔑 Test Accounts (Anvil)</h2>
                    <p style={{marginBottom: '1rem'}}>Add test accounts to MetaMask. <strong>Only these accounts</strong> can check balances.</p>
                    <div className="test-accounts-grid" style={{display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: '1rem'}}>
                      {TEST_ACCOUNTS.map((account, idx) => (
                        <div key={idx} className="test-account-card" style={{
                          border: '1px solid #ddd',
                          borderRadius: '8px',
                          padding: '1rem',
                          background: address?.toLowerCase() === account.address.toLowerCase() ? '#e8f5e9' : '#f9f9f9'
                        }}>
                          <div style={{fontWeight: 'bold', marginBottom: '0.5rem'}}>
                            {account.name}
                            {address?.toLowerCase() === account.address.toLowerCase() &&
                              <span style={{marginLeft: '0.5rem', color: '#4caf50'}}>✓ Connected</span>
                            }
                          </div>
                          <div style={{fontSize: '0.75rem', color: '#666', marginBottom: '0.5rem'}}>{account.role}</div>
                          <div style={{fontSize: '0.7rem', fontFamily: 'monospace', marginBottom: '0.75rem', wordBreak: 'break-all'}}>
                            {account.address}
                          </div>
                          <button
                            className="btn btn-primary"
                            style={{width: '100%', padding: '0.5rem'}}
                            onClick={() => {
                              navigator.clipboard.writeText(account.privateKey);
                              alert(`✅ Private Key copied!\n\n📋 How to add to MetaMask:\n1. Open MetaMask\n2. Click account icon\n3. Select "Import Account"\n4. Paste Private Key (Ctrl+V)\n5. Click "Import"`);
                            }}
                          >
                            📋 Copy Private Key
                          </button>
                        </div>
                      ))}
                    </div>
                  </section>
                </div>
              )}

              {/* L1 Block Explorer Tab */}
              {activeTab === 'l1-explorer' && (
                <div className="section">
                  <section className="card">
                    <h2>🔍 L1 Block Explorer</h2>
                    <p>Explore L1 blockchain blocks and transactions</p>
                    
                    {/* View Toggle Tabs */}
                    <div style={{display: 'flex', gap: '1rem', marginBottom: '1.5rem', borderBottom: '2px solid #e0e0e0'}}>
                      <button
                        onClick={() => setExplorerView('blocks')}
                        style={{
                          padding: '0.75rem 1.5rem',
                          background: 'none',
                          border: 'none',
                          borderBottom: explorerView === 'blocks' ? '3px solid #4CAF50' : '3px solid transparent',
                          cursor: 'pointer',
                          fontWeight: explorerView === 'blocks' ? 'bold' : 'normal',
                          fontSize: '1rem',
                          color: explorerView === 'blocks' ? '#4CAF50' : '#666',
                        }}
                      >
                        📦 Blocks
                      </button>
                      <button
                        onClick={() => setExplorerView('transactions')}
                        style={{
                          padding: '0.75rem 1.5rem',
                          background: 'none',
                          border: 'none',
                          borderBottom: explorerView === 'transactions' ? '3px solid #4CAF50' : '3px solid transparent',
                          cursor: 'pointer',
                          fontWeight: explorerView === 'transactions' ? 'bold' : 'normal',
                          fontSize: '1rem',
                          color: explorerView === 'transactions' ? '#4CAF50' : '#666',
                        }}
                      >
                        📝 Transactions
                      </button>
                    </div>

                    {explorerView === 'blocks' ? (
                      <>
                        <div className="action-form" style={{marginBottom: '1rem'}}>
                      <input
                        type="text"
                        placeholder="Block number or hash"
                        className="input"
                        value={blockSearchInput}
                        onChange={(e) => setBlockSearchInput(e.target.value)}
                      />
                      <button
                        onClick={() => {
                          const input = blockSearchInput.trim();
                          if (!input) return;
                          
                          if (input.startsWith('0x')) {
                            alert('Hash search not yet implemented. Please enter a block number.');
                          } else {
                            loadBlockDetails(parseInt(input), false);
                          }
                        }}
                        disabled={loading}
                        className="btn btn-primary"
                      >
                        Search Block
                      </button>
                      <button
                        onClick={() => loadL1Blocks(20)}
                        disabled={loading}
                        className="btn btn-secondary"
                      >
                        Load Latest Blocks
                      </button>
                    </div>

                    <div className="action-form" style={{marginBottom: '1rem'}}>
                      <input
                        type="text"
                        placeholder="Transaction hash"
                        className="input"
                        value={txSearchInput}
                        onChange={(e) => setTxSearchInput(e.target.value)}
                      />
                      <button
                        onClick={() => {
                          const input = txSearchInput.trim();
                          if (!input) return;
                          loadTransactionDetails(input, false);
                        }}
                        disabled={loading}
                        className="btn btn-primary"
                      >
                        Search Transaction
                      </button>
                    </div>

                    {selectedBlock && (
                      <div style={{marginTop: '2rem', padding: '1rem', background: '#f5f5f5', borderRadius: '8px'}}>
                        <h3>Block Details</h3>
                        <div className="info-list">
                          <div className="info-row">
                            <span className="info-label">Block Number:</span>
                            <span>{selectedBlock.number}</span>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Block Hash:</span>
                            <code style={{fontSize: '0.8rem'}}>{selectedBlock.hash}</code>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Parent Hash:</span>
                            <code style={{fontSize: '0.8rem'}}>{selectedBlock.parentHash}</code>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Timestamp:</span>
                            <span>{formatTimestamp(selectedBlock.timestamp)}</span>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Miner:</span>
                            <code>{selectedBlock.miner}</code>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Gas Used:</span>
                            <span>{selectedBlock.gasUsed} / {selectedBlock.gasLimit}</span>
                          </div>
                          {selectedBlock.baseFeePerGas && (
                            <div className="info-row">
                              <span className="info-label">Base Fee:</span>
                              <span>{ethers.formatUnits(selectedBlock.baseFeePerGas, 'gwei')} Gwei</span>
                            </div>
                          )}
                          <div className="info-row">
                            <span className="info-label">Transactions:</span>
                            <span>{selectedBlock.transactions.length} txs</span>
                          </div>
                        </div>

                        {/* Transaction List in Block */}
                        {selectedBlock.transactions.length > 0 && (
                          <div style={{marginTop: '1.5rem'}}>
                            <h4>Transactions in this Block</h4>
                            <div className="table-container">
                              <table className="validators-table">
                                <thead>
                                  <tr>
                                    <th>TX Hash</th>
                                    <th>Actions</th>
                                  </tr>
                                </thead>
                                <tbody>
                                  {selectedBlock.transactions.slice(0, 20).map((txHash) => (
                                    <tr key={txHash}>
                                      <td><code style={{fontSize: '0.75rem'}}>{txHash}</code></td>
                                      <td>
                                        <button
                                          onClick={() => {
                                            setSelectedBlock(null);
                                            loadTransactionDetails(txHash, false);
                                          }}
                                          className="btn btn-small btn-primary"
                                        >
                                          View Details
                                        </button>
                                      </td>
                                    </tr>
                                  ))}
                                </tbody>
                              </table>
                            </div>
                            {selectedBlock.transactions.length > 20 && (
                              <p style={{marginTop: '0.5rem', fontSize: '0.9rem', color: '#666'}}>
                                Showing first 20 of {selectedBlock.transactions.length} transactions
                              </p>
                            )}
                          </div>
                        )}

                        <button
                          onClick={() => setSelectedBlock(null)}
                          className="btn btn-secondary"
                          style={{marginTop: '1rem'}}
                        >
                          Close
                        </button>
                      </div>
                    )}

                    {selectedTransaction && (
                      <div style={{marginTop: '2rem', padding: '1rem', background: '#f5f5f5', borderRadius: '8px'}}>
                        <h3>Transaction Details</h3>
                        <div className="info-list">
                          <div className="info-row">
                            <span className="info-label">TX Hash:</span>
                            <code style={{fontSize: '0.8rem'}}>{selectedTransaction.hash}</code>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Status:</span>
                            <span className={selectedTransaction.status === 1 ? 'status-success' : 'status-error'}>
                              {selectedTransaction.status === 1 ? '✅ Success' : '❌ Failed'}
                            </span>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Block:</span>
                            <span>{selectedTransaction.blockNumber}</span>
                          </div>
                          <div className="info-row">
                            <span className="info-label">From:</span>
                            <code>{selectedTransaction.from}</code>
                          </div>
                          <div className="info-row">
                            <span className="info-label">To:</span>
                            <code>{selectedTransaction.to || 'Contract Creation'}</code>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Value:</span>
                            <span>{selectedTransaction.value} ETH</span>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Gas Used:</span>
                            <span>{selectedTransaction.gasUsed}</span>
                          </div>
                          {selectedTransaction.data && selectedTransaction.data !== '0x' && (() => {
                            const parsed = parseInputData(selectedTransaction.to, selectedTransaction.data);
                            return (
                              <>
                                {parsed ? (
                                  <>
                                    <div className="info-row">
                                      <span className="info-label">Function:</span>
                                      <code style={{fontSize: '0.9rem', padding: '0.25rem 0.5rem', background: '#e8f5e9', borderRadius: '4px', fontWeight: 'bold'}}>
                                        {parsed.name}
                                      </code>
                                    </div>
                                    <div className="info-row" style={{flexDirection: 'column', alignItems: 'flex-start'}}>
                                      <span className="info-label" style={{marginBottom: '0.5rem'}}>Parameters:</span>
                                      <div style={{width: '100%', padding: '0.75rem', background: '#f5f5f5', borderRadius: '4px', border: '1px solid #ddd'}}>
                                        {parsed.args.map((arg: any, idx: number) => (
                                          <div key={idx} style={{marginBottom: '0.5rem', fontSize: '0.85rem'}}>
                                            <strong>{arg.name}</strong> <span style={{color: '#666'}}>({arg.type})</span>: <code>{arg.value}</code>
                                          </div>
                                        ))}
                                      </div>
                                    </div>
                                  </>
                                ) : (
                                  <>
                                    <div className="info-row">
                                      <span className="info-label">Method ID:</span>
                                      <code style={{fontSize: '0.9rem', padding: '0.25rem 0.5rem', background: '#e3f2fd', borderRadius: '4px'}}>
                                        {selectedTransaction.methodId}
                                      </code>
                                    </div>
                                  </>
                                )}
                                <div className="info-row" style={{flexDirection: 'column', alignItems: 'flex-start'}}>
                                  <span className="info-label" style={{marginBottom: '0.5rem'}}>Input Data:</span>
                                  <code style={{
                                    fontSize: '0.75rem',
                                    padding: '0.75rem',
                                    background: '#f5f5f5',
                                    borderRadius: '4px',
                                    wordBreak: 'break-all',
                                    width: '100%',
                                    display: 'block',
                                    maxHeight: '150px',
                                    overflowY: 'auto',
                                    border: '1px solid #ddd'
                                  }}>
                                    {selectedTransaction.data}
                                  </code>
                                </div>
                              </>
                            );
                          })()}
                        </div>
                        <button
                          onClick={() => setSelectedTransaction(null)}
                          className="btn btn-secondary"
                          style={{marginTop: '1rem'}}
                        >
                          Close
                        </button>
                      </div>
                    )}

                    {l1Blocks.length > 0 && !selectedBlock && !selectedTransaction && (
                      <div style={{marginTop: '2rem'}}>
                        <h3>Recent L1 Blocks</h3>
                        <div className="table-container">
                          <table className="validators-table">
                            <thead>
                              <tr>
                                <th>Block</th>
                                <th>Timestamp</th>
                                <th>Txs</th>
                                <th>Gas Used</th>
                                <th>Miner</th>
                                <th>Actions</th>
                              </tr>
                            </thead>
                            <tbody>
                              {l1Blocks.map((block) => (
                                <tr key={block.number}>
                                  <td>{block.number}</td>
                                  <td>{new Date(block.timestamp * 1000).toLocaleTimeString()}</td>
                                  <td>{block.transactions.length}</td>
                                  <td>{parseInt(block.gasUsed).toLocaleString()}</td>
                                  <td><code style={{fontSize: '0.8rem'}}>{formatAddress(block.miner)}</code></td>
                                  <td>
                                    <button
                                      onClick={() => loadBlockDetails(block.number, false)}
                                      className="btn btn-small btn-primary"
                                    >
                                      View
                                    </button>
                                  </td>
                                </tr>
                              ))}
                            </tbody>
                          </table>
                        </div>
                      </div>
                    )}
                      </>
                    ) : (
                      <>
                        {/* Transaction View */}
                        <div className="action-form" style={{marginBottom: '1rem'}}>
                          <input
                            type="text"
                            placeholder="Transaction hash"
                            className="input"
                            value={txSearchInput}
                            onChange={(e) => setTxSearchInput(e.target.value)}
                          />
                          <button
                            onClick={() => {
                              const input = txSearchInput.trim();
                              if (!input) return;
                              loadTransactionDetails(input, false);
                            }}
                            disabled={loading}
                            className="btn btn-primary"
                          >
                            Search Transaction
                          </button>
                          <button
                            onClick={() => loadL1Transactions(20)}
                            disabled={loading}
                            className="btn btn-secondary"
                          >
                            Load Latest Transactions
                          </button>
                        </div>

                        {selectedTransaction && (
                          <div style={{marginTop: '2rem', padding: '1rem', background: '#f5f5f5', borderRadius: '8px'}}>
                            <h3>Transaction Details</h3>
                            <div className="info-list">
                              <div className="info-row">
                                <span className="info-label">TX Hash:</span>
                                <code style={{fontSize: '0.8rem'}}>{selectedTransaction.hash}</code>
                              </div>
                              <div className="info-row">
                                <span className="info-label">Status:</span>
                                <span className={selectedTransaction.status === 1 ? 'status-success' : 'status-error'}>
                                  {selectedTransaction.status === 1 ? '✅ Success' : '❌ Failed'}
                                </span>
                              </div>
                              <div className="info-row">
                                <span className="info-label">Block:</span>
                                <span>{selectedTransaction.blockNumber}</span>
                              </div>
                              <div className="info-row">
                                <span className="info-label">From:</span>
                                <code>{selectedTransaction.from}</code>
                              </div>
                              <div className="info-row">
                                <span className="info-label">To:</span>
                                <code>{selectedTransaction.to || 'Contract Creation'}</code>
                              </div>
                              <div className="info-row">
                                <span className="info-label">Value:</span>
                                <span>{selectedTransaction.value} ETH</span>
                              </div>
                              <div className="info-row">
                                <span className="info-label">Gas Used:</span>
                                <span>{selectedTransaction.gasUsed}</span>
                              </div>
                              <div className="info-row">
                                <span className="info-label">Gas Price:</span>
                                <span>{ethers.formatUnits(selectedTransaction.gasPrice, 'gwei')} Gwei</span>
                              </div>
                              {selectedTransaction.data && selectedTransaction.data !== '0x' && (
                                <>
                                  <div className="info-row">
                                    <span className="info-label">Method ID:</span>
                                    <code style={{fontSize: '0.9rem', padding: '0.25rem 0.5rem', background: '#e3f2fd', borderRadius: '4px'}}>
                                      {selectedTransaction.methodId}
                                    </code>
                                  </div>
                                  <div className="info-row" style={{flexDirection: 'column', alignItems: 'flex-start'}}>
                                    <span className="info-label" style={{marginBottom: '0.5rem'}}>Input Data:</span>
                                    <code style={{
                                      fontSize: '0.75rem',
                                      padding: '0.75rem',
                                      background: '#f5f5f5',
                                      borderRadius: '4px',
                                      wordBreak: 'break-all',
                                      width: '100%',
                                      display: 'block',
                                      maxHeight: '150px',
                                      overflowY: 'auto',
                                      border: '1px solid #ddd'
                                    }}>
                                      {selectedTransaction.data}
                                    </code>
                                  </div>
                                </>
                              )}
                            </div>
                            <button
                              onClick={() => setSelectedTransaction(null)}
                              className="btn btn-secondary"
                              style={{marginTop: '1rem'}}
                            >
                              Close
                            </button>
                          </div>
                        )}

                        {l1Transactions.length > 0 && !selectedTransaction && (
                          <div style={{marginTop: '2rem'}}>
                            <h3>Recent L1 Transactions</h3>
                            <div className="table-container">
                              <table className="validators-table">
                                <thead>
                                  <tr>
                                    <th>TX Hash</th>
                                    <th>Block</th>
                                    <th>From</th>
                                    <th>To</th>
                                    <th>Value (ETH)</th>
                                    <th>Status</th>
                                    <th>Actions</th>
                                  </tr>
                                </thead>
                                <tbody>
                                  {l1Transactions.map((tx) => (
                                    <tr key={tx.hash}>
                                      <td><code style={{fontSize: '0.75rem'}}>{tx.hash.substring(0, 10)}...</code></td>
                                      <td>{tx.blockNumber}</td>
                                      <td><code style={{fontSize: '0.75rem'}}>{formatAddress(tx.from)}</code></td>
                                      <td><code style={{fontSize: '0.75rem'}}>{tx.to ? formatAddress(tx.to) : 'Contract'}</code></td>
                                      <td>{parseFloat(tx.value).toFixed(4)}</td>
                                      <td>
                                        <span className={tx.status === 1 ? 'status-success' : 'status-error'}>
                                          {tx.status === 1 ? '✅' : '❌'}
                                        </span>
                                      </td>
                                      <td>
                                        <button
                                          onClick={() => loadTransactionDetails(tx.hash, false)}
                                          className="btn btn-small btn-primary"
                                        >
                                          View
                                        </button>
                                      </td>
                                    </tr>
                                  ))}
                                </tbody>
                              </table>
                            </div>
                          </div>
                        )}
                      </>
                    )}
                  </section>
                </div>
              )}

              {/* L2 Block Explorer Tab */}
              {activeTab === 'l2-explorer' && (
                <div className="section">
                  <section className="card">
                    <h2>🔎 L2 Block Explorer</h2>
                    <p>Explore L2 blockchain blocks and transactions</p>
                    
                    {/* View Toggle Tabs */}
                    <div style={{display: 'flex', gap: '1rem', marginBottom: '1.5rem', borderBottom: '2px solid #e0e0e0'}}>
                      <button
                        onClick={() => setExplorerView('blocks')}
                        style={{
                          padding: '0.75rem 1.5rem',
                          background: 'none',
                          border: 'none',
                          borderBottom: explorerView === 'blocks' ? '3px solid #4CAF50' : '3px solid transparent',
                          cursor: 'pointer',
                          fontWeight: explorerView === 'blocks' ? 'bold' : 'normal',
                          fontSize: '1rem',
                          color: explorerView === 'blocks' ? '#4CAF50' : '#666',
                        }}
                      >
                        📦 Blocks
                      </button>
                      <button
                        onClick={() => setExplorerView('transactions')}
                        style={{
                          padding: '0.75rem 1.5rem',
                          background: 'none',
                          border: 'none',
                          borderBottom: explorerView === 'transactions' ? '3px solid #4CAF50' : '3px solid transparent',
                          cursor: 'pointer',
                          fontWeight: explorerView === 'transactions' ? 'bold' : 'normal',
                          fontSize: '1rem',
                          color: explorerView === 'transactions' ? '#4CAF50' : '#666',
                        }}
                      >
                        📝 Transactions
                      </button>
                    </div>

                    {explorerView === 'blocks' ? (
                      <>
                        <div className="action-form" style={{marginBottom: '1rem'}}>
                      <input
                        type="text"
                        placeholder="Block number or hash"
                        className="input"
                        value={blockSearchInput}
                        onChange={(e) => setBlockSearchInput(e.target.value)}
                      />
                      <button
                        onClick={() => {
                          const input = blockSearchInput.trim();
                          if (!input) return;
                          
                          if (input.startsWith('0x')) {
                            alert('Hash search not yet implemented. Please enter a block number.');
                          } else {
                            loadBlockDetails(parseInt(input), true);
                          }
                        }}
                        disabled={loading}
                        className="btn btn-primary"
                      >
                        Search Block
                      </button>
                      <button
                        onClick={() => loadL2Blocks(20)}
                        disabled={loading}
                        className="btn btn-secondary"
                      >
                        Load Latest Blocks
                      </button>
                    </div>

                    <div className="action-form" style={{marginBottom: '1rem'}}>
                      <input
                        type="text"
                        placeholder="Transaction hash"
                        className="input"
                        value={txSearchInput}
                        onChange={(e) => setTxSearchInput(e.target.value)}
                      />
                      <button
                        onClick={() => {
                          const input = txSearchInput.trim();
                          if (!input) return;
                          loadTransactionDetails(input, true);
                        }}
                        disabled={loading}
                        className="btn btn-primary"
                      >
                        Search Transaction
                      </button>
                    </div>

                    {selectedBlock && (
                      <div style={{marginTop: '2rem', padding: '1rem', background: '#f5f5f5', borderRadius: '8px'}}>
                        <h3>Block Details</h3>
                        <div className="info-list">
                          <div className="info-row">
                            <span className="info-label">Block Number:</span>
                            <span>{selectedBlock.number}</span>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Block Hash:</span>
                            <code style={{fontSize: '0.8rem'}}>{selectedBlock.hash}</code>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Parent Hash:</span>
                            <code style={{fontSize: '0.8rem'}}>{selectedBlock.parentHash}</code>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Timestamp:</span>
                            <span>{formatTimestamp(selectedBlock.timestamp)}</span>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Miner:</span>
                            <code>{selectedBlock.miner}</code>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Gas Used:</span>
                            <span>{selectedBlock.gasUsed} / {selectedBlock.gasLimit}</span>
                          </div>
                          {selectedBlock.baseFeePerGas && (
                            <div className="info-row">
                              <span className="info-label">Base Fee:</span>
                              <span>{ethers.formatUnits(selectedBlock.baseFeePerGas, 'gwei')} Gwei</span>
                            </div>
                          )}
                          <div className="info-row">
                            <span className="info-label">Transactions:</span>
                            <span>{selectedBlock.transactions.length} txs</span>
                          </div>
                        </div>

                        {/* Transaction List in Block */}
                        {selectedBlock.transactions.length > 0 && (
                          <div style={{marginTop: '1.5rem'}}>
                            <h4>Transactions in this Block</h4>
                            <div className="table-container">
                              <table className="validators-table">
                                <thead>
                                  <tr>
                                    <th>TX Hash</th>
                                    <th>Actions</th>
                                  </tr>
                                </thead>
                                <tbody>
                                  {selectedBlock.transactions.slice(0, 20).map((txHash) => (
                                    <tr key={txHash}>
                                      <td><code style={{fontSize: '0.75rem'}}>{txHash}</code></td>
                                      <td>
                                        <button
                                          onClick={() => {
                                            setSelectedBlock(null);
                                            loadTransactionDetails(txHash, true);
                                          }}
                                          className="btn btn-small btn-primary"
                                        >
                                          View Details
                                        </button>
                                      </td>
                                    </tr>
                                  ))}
                                </tbody>
                              </table>
                            </div>
                            {selectedBlock.transactions.length > 20 && (
                              <p style={{marginTop: '0.5rem', fontSize: '0.9rem', color: '#666'}}>
                                Showing first 20 of {selectedBlock.transactions.length} transactions
                              </p>
                            )}
                          </div>
                        )}

                        <button
                          onClick={() => setSelectedBlock(null)}
                          className="btn btn-secondary"
                          style={{marginTop: '1rem'}}
                        >
                          Close
                        </button>
                      </div>
                    )}

                    {selectedTransaction && (
                      <div style={{marginTop: '2rem', padding: '1rem', background: '#f5f5f5', borderRadius: '8px'}}>
                        <h3>Transaction Details</h3>
                        <div className="info-list">
                          <div className="info-row">
                            <span className="info-label">TX Hash:</span>
                            <code style={{fontSize: '0.8rem'}}>{selectedTransaction.hash}</code>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Status:</span>
                            <span className={selectedTransaction.status === 1 ? 'status-success' : 'status-error'}>
                              {selectedTransaction.status === 1 ? '✅ Success' : '❌ Failed'}
                            </span>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Block:</span>
                            <span>{selectedTransaction.blockNumber}</span>
                          </div>
                          <div className="info-row">
                            <span className="info-label">From:</span>
                            <code>{selectedTransaction.from}</code>
                          </div>
                          <div className="info-row">
                            <span className="info-label">To:</span>
                            <code>{selectedTransaction.to || 'Contract Creation'}</code>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Value:</span>
                            <span>{selectedTransaction.value} ETH</span>
                          </div>
                          <div className="info-row">
                            <span className="info-label">Gas Used:</span>
                            <span>{selectedTransaction.gasUsed}</span>
                          </div>
                        </div>
                        <button
                          onClick={() => setSelectedTransaction(null)}
                          className="btn btn-secondary"
                          style={{marginTop: '1rem'}}
                        >
                          Close
                        </button>
                      </div>
                    )}

                    {l2Blocks.length > 0 && !selectedBlock && !selectedTransaction && (
                      <div style={{marginTop: '2rem'}}>
                        <h3>Recent L2 Blocks</h3>
                        <div className="table-container">
                          <table className="validators-table">
                            <thead>
                              <tr>
                                <th>Block</th>
                                <th>Timestamp</th>
                                <th>Txs</th>
                                <th>Gas Used</th>
                                <th>Miner</th>
                                <th>Actions</th>
                              </tr>
                            </thead>
                            <tbody>
                              {l2Blocks.map((block) => (
                                <tr key={block.number}>
                                  <td>{block.number}</td>
                                  <td>{new Date(block.timestamp * 1000).toLocaleTimeString()}</td>
                                  <td>{block.transactions.length}</td>
                                  <td>{parseInt(block.gasUsed).toLocaleString()}</td>
                                  <td><code style={{fontSize: '0.8rem'}}>{formatAddress(block.miner)}</code></td>
                                  <td>
                                    <button
                                      onClick={() => loadBlockDetails(block.number, true)}
                                      className="btn btn-small btn-primary"
                                    >
                                      View
                                    </button>
                                  </td>
                                </tr>
                              ))}
                            </tbody>
                          </table>
                        </div>
                      </div>
                    )}
                      </>
                    ) : (
                      <>
                        {/* Transaction View */}
                        <div className="action-form" style={{marginBottom: '1rem'}}>
                          <input
                            type="text"
                            placeholder="Transaction hash"
                            className="input"
                            value={txSearchInput}
                            onChange={(e) => setTxSearchInput(e.target.value)}
                          />
                          <button
                            onClick={() => {
                              const input = txSearchInput.trim();
                              if (!input) return;
                              loadTransactionDetails(input, true);
                            }}
                            disabled={loading}
                            className="btn btn-primary"
                          >
                            Search Transaction
                          </button>
                          <button
                            onClick={() => loadL2Transactions(20)}
                            disabled={loading}
                            className="btn btn-secondary"
                          >
                            Load Latest Transactions
                          </button>
                        </div>

                        {selectedTransaction && (
                          <div style={{marginTop: '2rem', padding: '1rem', background: '#f5f5f5', borderRadius: '8px'}}>
                            <h3>Transaction Details</h3>
                            <div className="info-list">
                              <div className="info-row">
                                <span className="info-label">TX Hash:</span>
                                <code style={{fontSize: '0.8rem'}}>{selectedTransaction.hash}</code>
                              </div>
                              <div className="info-row">
                                <span className="info-label">Status:</span>
                                <span className={selectedTransaction.status === 1 ? 'status-success' : 'status-error'}>
                                  {selectedTransaction.status === 1 ? '✅ Success' : '❌ Failed'}
                                </span>
                              </div>
                              <div className="info-row">
                                <span className="info-label">Block:</span>
                                <span>{selectedTransaction.blockNumber}</span>
                              </div>
                              <div className="info-row">
                                <span className="info-label">From:</span>
                                <code>{selectedTransaction.from}</code>
                              </div>
                              <div className="info-row">
                                <span className="info-label">To:</span>
                                <code>{selectedTransaction.to || 'Contract Creation'}</code>
                              </div>
                              <div className="info-row">
                                <span className="info-label">Value:</span>
                                <span>{selectedTransaction.value} ETH</span>
                              </div>
                              <div className="info-row">
                                <span className="info-label">Gas Used:</span>
                                <span>{selectedTransaction.gasUsed}</span>
                              </div>
                              <div className="info-row">
                                <span className="info-label">Gas Price:</span>
                                <span>{ethers.formatUnits(selectedTransaction.gasPrice, 'gwei')} Gwei</span>
                              </div>
                              {selectedTransaction.data && selectedTransaction.data !== '0x' && (
                                <>
                                  <div className="info-row">
                                    <span className="info-label">Method ID:</span>
                                    <code style={{fontSize: '0.9rem', padding: '0.25rem 0.5rem', background: '#e3f2fd', borderRadius: '4px'}}>
                                      {selectedTransaction.methodId}
                                    </code>
                                  </div>
                                  <div className="info-row" style={{flexDirection: 'column', alignItems: 'flex-start'}}>
                                    <span className="info-label" style={{marginBottom: '0.5rem'}}>Input Data:</span>
                                    <code style={{
                                      fontSize: '0.75rem',
                                      padding: '0.75rem',
                                      background: '#f5f5f5',
                                      borderRadius: '4px',
                                      wordBreak: 'break-all',
                                      width: '100%',
                                      display: 'block',
                                      maxHeight: '150px',
                                      overflowY: 'auto',
                                      border: '1px solid #ddd'
                                    }}>
                                      {selectedTransaction.data}
                                    </code>
                                  </div>
                                </>
                              )}
                            </div>
                            <button
                              onClick={() => setSelectedTransaction(null)}
                              className="btn btn-secondary"
                              style={{marginTop: '1rem'}}
                            >
                              Close
                            </button>
                          </div>
                        )}

                        {l2Transactions.length > 0 && !selectedTransaction && (
                          <div style={{marginTop: '2rem'}}>
                            <h3>Recent L2 Transactions</h3>
                            <div className="table-container">
                              <table className="validators-table">
                                <thead>
                                  <tr>
                                    <th>TX Hash</th>
                                    <th>Block</th>
                                    <th>From</th>
                                    <th>To</th>
                                    <th>Value (ETH)</th>
                                    <th>Status</th>
                                    <th>Actions</th>
                                  </tr>
                                </thead>
                                <tbody>
                                  {l2Transactions.map((tx) => (
                                    <tr key={tx.hash}>
                                      <td><code style={{fontSize: '0.75rem'}}>{tx.hash.substring(0, 10)}...</code></td>
                                      <td>{tx.blockNumber}</td>
                                      <td><code style={{fontSize: '0.75rem'}}>{formatAddress(tx.from)}</code></td>
                                      <td><code style={{fontSize: '0.75rem'}}>{tx.to ? formatAddress(tx.to) : 'Contract'}</code></td>
                                      <td>{parseFloat(tx.value).toFixed(4)}</td>
                                      <td>
                                        <span className={tx.status === 1 ? 'status-success' : 'status-error'}>
                                          {tx.status === 1 ? '✅' : '❌'}
                                        </span>
                                      </td>
                                      <td>
                                        <button
                                          onClick={() => loadTransactionDetails(tx.hash, true)}
                                          className="btn btn-small btn-primary"
                                        >
                                          View
                                        </button>
                                      </td>
                                    </tr>
                                  ))}
                                </tbody>
                              </table>
                            </div>
                          </div>
                        )}
                      </>
                    )}
                  </section>
                </div>
              )}

              <button onClick={loadDashboardData} className="btn btn-secondary refresh-btn" disabled={loading}>
                {loading ? '🔄 Refreshing...' : '🔄 Refresh Data'}
              </button>
            </div>
          </div>
        )}
      </main>

      <footer className="footer">
        <p>TON Staking V3 - Local Development Dashboard</p>
        <p>
          <a href="https://github.com/tokamak-network/ton-staking-v2" target="_blank" rel="noopener noreferrer">
            GitHub
          </a>
          {' | '}
          <a href="https://tokamak-network.github.io/ton-staking-v2/" target="_blank" rel="noopener noreferrer">
            Documentation
          </a>
        </p>
      </footer>
    </div>
  );
}

export default App;
