import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { CONFIG, TEST_ACCOUNTS, ROLLUP_TYPES } from './config';
import {
  TON_ABI, WTON_ABI, SEIG_MANAGER_ABI, DEPOSIT_MANAGER_ABI,
  LAYER2_MANAGER_ABI, L1_BRIDGE_REGISTRY_ABI, LAYER2_REGISTRY_ABI,
  RAT_ABI, DISPUTE_GAME_FACTORY_ABI, SYSTEM_CONFIG_ABI,
  OPTIMISM_PORTAL_ABI, L1_STANDARD_BRIDGE_ABI, L2_STANDARD_BRIDGE_ABI, OPERATOR_MANAGER_ABI
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
  isLayer2Registered: boolean;
  isEligible: boolean;
  requiredStake: string;
  currentStake: string;
}

interface ValidatorInfo {
  address: string;
  deposit: string;
  available: string;
  isActive: boolean;
  ratRegistered: boolean;
}

interface GameInfo {
  index: number;
  gameType: number;
  timestamp: number;
  proxy: string;
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

  useEffect(() => {
    initializeProvider();
    loadDashboardData();
    
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

  // Load seigniorage info when operator tab is active
  useEffect(() => {
    if (activeTab === 'operator' && operatorInfo?.candidateAddOn && operatorInfo.candidateAddOn !== ethers.ZeroAddress) {
      loadSeigniorageInfo(operatorInfo.candidateAddOn);
    }
  }, [activeTab, operatorInfo?.candidateAddOn]);

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
    await Promise.all([
      loadNodeStatus(),
      loadRollupInfo(),
      loadValidators(),
      loadGames(),
      loadSystemParams(),
      loadL2Info(),
    ]);
    
    // Load operator info first, then load seigniorage info
    await loadOperatorInfo();
    
    // 잔액은 수동 새로고침 버튼으로 업데이트 (부하 감소)
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
      const registry = new ethers.Contract(
        CONFIG.contracts.l1BridgeRegistry,
        L1_BRIDGE_REGISTRY_ABI,
        l1Provider
      );

      const info = await registry.getRollupInfo(CONFIG.contracts.systemConfig);
      setRollupInfo({
        rollupType: Number(info[0]),
        l2Ton: info[1],
        rejectedSeigs: info[2],
        rejectedL2Deposit: info[3],
        name: info[4],
      });
    } catch (error) {
      console.error('Failed to load rollup info:', error);
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
      } catch (e) {
        console.error('Failed to load eligibility:', e);
      }

      setOperatorInfo({
        operator,
        operatorManager,
        operatorManagerManager,
        candidateAddOn,
        sequencerStake,
        isLayer2Registered,
        isEligible,
        requiredStake,
        currentStake,
      });
    } catch (error) {
      console.error('Failed to load operator info:', error);
    }
  };

  const loadValidators = async () => {
    try {
      const rat = new ethers.Contract(CONFIG.contracts.rat, RAT_ABI, l1Provider);

      const validatorAddrs = await rat.getL2Validators(CONFIG.contracts.systemConfig);
      
      const validatorList: ValidatorInfo[] = [];
      
      for (const addr of validatorAddrs) {
        try {
          const deposit = await rat.getValidatorDeposit(addr, CONFIG.contracts.systemConfig);
          const available = await rat.getAvailableCollateral(addr, CONFIG.contracts.systemConfig);
          const isActive = await rat.isValidatorActive(addr, CONFIG.contracts.systemConfig);
          
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
            isActive,
            ratRegistered,
          });
        } catch (e) {
          console.error(`Failed to load validator ${addr}:`, e);
        }
      }

      setValidators(validatorList);
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
      } catch (e) {
        console.log('L2 not available:', e);
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

      setL2Info({
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
      });
    } catch (error) {
      console.error('Failed to load L2 info:', error);
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

  const loadSeigniorageInfo = async (layer2Address?: string) => {
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
        eligibilityInfo,
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
        seigManager.checkCurrentEligibility(targetLayer2),
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

      // RollupConfig 및 추가 정보 조회
      let rollupConfig = ethers.ZeroAddress;
      let layer2Status = 0;
      let operatorManagerAddress = ethers.ZeroAddress;
      let operatorManagerBalance = '0';
      let operatorManagerManager = ethers.ZeroAddress;
      let systemConfigSigner = ethers.ZeroAddress;
      let signersMatch = false;

      try {
        rollupConfig = await layer2Manager.getRollupConfig(targetLayer2);
        
        if (rollupConfig !== ethers.ZeroAddress) {
          layer2Status = await layer2Manager.statusLayer2(rollupConfig);
          
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
        effectiveBridgedTon: ethers.formatEther(effectiveBridgedTon), // TON is 18 decimals
        totalEffectiveBridgedTon: ethers.formatEther(totalEffectiveBridgedTon), // TON is 18 decimals
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
        halfSaturationPoint: ethers.formatEther(halfSaturationPoint), // TON is 18 decimals
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

  const formatAddress = (addr: string) => {
    return `${addr.substring(0, 6)}...${addr.substring(38)}`;
  };

  const formatTimestamp = (ts: number) => {
    return new Date(ts * 1000).toLocaleString();
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
      
      let loaded = 0;
      for (let i = 0; i < 50 && loaded < count; i++) {
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
                    <h2>🎯 Sequencer Information</h2>
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
                        {seigniorageInfo && (
                          <div className="info-row">
                            <span className="info-label">Bridged TON (B_i):</span>
                            <span style={{fontSize: '1.1rem', fontWeight: 'bold', color: '#FF9800'}}>
                              {parseFloat(seigniorageInfo.bridgedTon).toFixed(2)} TON
                            </span>
                          </div>
                        )}
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
                  <section className="card">
                    <h2>🎮 Recent Dispute Games ({games.length})</h2>
                    {games.length === 0 ? (
                      <p className="empty-state">No dispute games created yet</p>
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
                  </section>
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
                          <span>{l2Info.basefeeScalar}</span>
                        </div>
                        <div className="info-row">
                          <span className="info-label">Blob Base Fee Scalar:</span>
                          <span>{l2Info.blobbasefeeScalar}</span>
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
                                await tx.wait();
                                
                                alert('✅ Withdrawal initiated! Now you need to wait for the challenge period (~7 days on mainnet, shorter on testnet) and then finalize on L1.');
                                input.value = '';
                                
                                // Switch back to L1
                                await window.ethereum.request({
                                  method: 'wallet_switchEthereumChain',
                                  params: [{ chainId: `0x${CONFIG.chainId.toString(16)}` }],
                                });
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
                                await tx.wait();
                                
                                alert('✅ TON withdrawal initiated! Now you need to wait for the challenge period and then finalize on L1.');
                                input.value = '';
                                
                                // Switch back to L1
                                await window.ethereum.request({
                                  method: 'wallet_switchEthereumChain',
                                  params: [{ chainId: `0x${CONFIG.chainId.toString(16)}` }],
                                });
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

                  <section className="card">
                    <h2>✅ Finalize Withdrawal on L1</h2>
                    <p>Complete the withdrawal process after challenge period (prove and finalize)</p>
                    <div className="warning-box" style={{ marginBottom: '1rem' }}>
                      <p>⚠️ Advanced Feature: Requires withdrawal proof from L2 transaction.</p>
                      <p>In production, you would need to:</p>
                      <ul style={{ marginLeft: '1.5rem', marginTop: '0.5rem' }}>
                        <li>Wait for challenge period (7 days mainnet)</li>
                        <li>Generate withdrawal proof using L2 transaction hash</li>
                        <li>Call proveWithdrawalTransaction on OptimismPortal</li>
                        <li>Wait for finalization period</li>
                        <li>Call finalizeWithdrawalTransaction</li>
                      </ul>
                    </div>
                    <div className="info-list" style={{ marginBottom: '1rem' }}>
                      <div className="info-row">
                        <span className="info-label">OptimismPortal:</span>
                        <code>{l2Info?.portal}</code>
                      </div>
                    </div>
                    <div className="action-form">
                      <input
                        type="text"
                        placeholder="L2 Withdrawal Transaction Hash"
                        className="input"
                        id="finalize-tx-hash"
                        style={{ fontFamily: 'monospace' }}
                      />
                      <button
                        onClick={() => {
                          alert('⚠️ This is a placeholder. In production, you would need to implement:\n\n1. Fetch withdrawal proof from L2\n2. Submit proof to OptimismPortal\n3. Wait for dispute game resolution\n4. Finalize withdrawal\n\nUse official Optimism SDK for this functionality.');
                        }}
                        disabled={true}
                        className="btn btn-secondary"
                      >
                        🔧 Finalize (Advanced - Coming Soon)
                      </button>
                    </div>
                    <small>Use Optimism SDK or official tools for withdrawal finalization</small>
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
                              <span className="info-label">Claimable Seigniorage (in OperatorManager):</span>
                              <span className="value-large">{parseFloat(seigniorageInfo.operatorManagerBalance).toFixed(4)} WTON</span>
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
                              <span className="value-large">{parseFloat(seigniorageInfo.totalEffectiveBridgedTon).toFixed(4)} TON</span>
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
                              <div className="info-row">
                                <span className="info-label">Estimated Pending Seigniorage:</span>
                                <span className="value-large">
                                  {((parseInt(seigniorageInfo.currentBlock) - parseInt(seigniorageInfo.lastSeigBlock)) * parseFloat(seigniorageInfo.seigPerBlock) * (1 - parseFloat(seigniorageInfo.daoDistributionRatio) / 100)).toFixed(4)} WTON
                                </span>
                              </div>
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
                              <span className="info-label">Bridged TON (Portal Balance):</span>
                              <span className="value-large">{parseFloat(seigniorageInfo.bridgedTon).toFixed(4)} TON</span>
                            </div>
                            <div className="info-row">
                              <span className="info-label">Required Stake (최소 담보금):</span>
                              <span className="value-large">{parseFloat(seigniorageInfo.requiredStake).toFixed(4)} WTON</span>
                            </div>
                            <div className="info-row">
                              <span className="info-label">Current Stake (현재 담보금):</span>
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
                                    const tx = await seigManager.updateSeigniorage();
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
                    <p style={{marginBottom: '1rem'}}>MetaMask에 테스트 계정을 추가하세요. <strong>이 계정들만</strong> 잔액 조회가 가능합니다.</p>
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
                              <span style={{marginLeft: '0.5rem', color: '#4caf50'}}>✓ 연결됨</span>
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
                              alert(`✅ Private Key 복사됨!\n\n📋 MetaMask 추가 방법:\n1. MetaMask 열기\n2. 계정 아이콘 클릭\n3. "계정 가져오기" 선택\n4. Private Key 붙여넣기 (Ctrl+V)\n5. "가져오기" 클릭`);
                            }}
                          >
                            📋 Private Key 복사
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
