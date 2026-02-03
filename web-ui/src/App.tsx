import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { CONFIG, TEST_ACCOUNTS } from './config';
import { TON_ABI, WTON_ABI, DEPOSIT_MANAGER_ABI, LAYER2_MANAGER_ABI } from './abis';
import './App.css';

declare global {
  interface Window {
    ethereum?: any;
  }
}

function App() {
  const [provider, setProvider] = useState<ethers.BrowserProvider | null>(null);
  const [signer, setSigner] = useState<ethers.Signer | null>(null);
  const [address, setAddress] = useState<string>('');
  const [tonBalance, setTonBalance] = useState<string>('0');
  const [wtonBalance, setWtonBalance] = useState<string>('0');
  const [stakedAmount, setStakedAmount] = useState<string>('0');
  const [stakeInput, setStakeInput] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(false);
  const [selectedL2, setSelectedL2] = useState<string>('');
  const [l2List, setL2List] = useState<string[]>([]);

  // Initialize provider and connect
  useEffect(() => {
    initializeProvider();
  }, []);

  const initializeProvider = async () => {
    try {
      if (typeof window.ethereum !== 'undefined') {
        const prov = new ethers.BrowserProvider(window.ethereum);
        setProvider(prov);
        
        // Try to get existing accounts
        const accounts = await window.ethereum.request({ method: 'eth_accounts' });
        if (accounts.length > 0) {
          const sign = await prov.getSigner();
          setSigner(sign);
          const addr = await sign.getAddress();
          setAddress(addr);
          await loadBalances(addr, prov);
        }
      } else {
        alert('Please install MetaMask to use this dApp');
      }
    } catch (error) {
      console.error('Failed to initialize provider:', error);
    }
  };

  const connectWallet = async () => {
    if (!provider) return;
    
    try {
      setLoading(true);
      
      // Request account access
      await window.ethereum.request({ method: 'eth_requestAccounts' });
      
      // Switch to or add custom network
      try {
        await window.ethereum.request({
          method: 'wallet_switchEthereumChain',
          params: [{ chainId: `0x${CONFIG.chainId.toString(16)}` }],
        });
      } catch (switchError: any) {
        // Chain doesn't exist, add it
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
      
      await loadBalances(addr, provider);
      await loadL2List(provider);
    } catch (error) {
      console.error('Failed to connect wallet:', error);
      alert('Failed to connect wallet. See console for details.');
    } finally {
      setLoading(false);
    }
  };

  const loadBalances = async (addr: string, prov: ethers.BrowserProvider) => {
    try {
      const tonContract = new ethers.Contract(CONFIG.contracts.ton, TON_ABI, prov);
      const wtonContract = new ethers.Contract(CONFIG.contracts.wton, WTON_ABI, prov);
      const depositManager = new ethers.Contract(CONFIG.contracts.depositManager, DEPOSIT_MANAGER_ABI, prov);
      
      const [ton, wton] = await Promise.all([
        tonContract.balanceOf(addr),
        wtonContract.balanceOf(addr),
      ]);
      
      setTonBalance(ethers.formatEther(ton));
      setWtonBalance(ethers.formatEther(wton));
      
      // Get staked amount if L2 is selected
      if (selectedL2) {
        const staked = await depositManager.stakeOf(selectedL2, addr);
        setStakedAmount(ethers.formatEther(staked));
      }
    } catch (error) {
      console.error('Failed to load balances:', error);
    }
  };

  const loadL2List = async (prov: ethers.BrowserProvider) => {
    try {
      const layer2Manager = new ethers.Contract(CONFIG.contracts.layer2Manager, LAYER2_MANAGER_ABI, prov);
      const numL2s = await layer2Manager.numLayer2s();
      
      const l2s: string[] = [];
      for (let i = 0; i < numL2s; i++) {
        const l2Address = await layer2Manager.layer2s(i);
        l2s.push(l2Address);
      }
      
      setL2List(l2s);
      if (l2s.length > 0 && !selectedL2) {
        setSelectedL2(l2s[0]);
      }
    } catch (error) {
      console.error('Failed to load L2 list:', error);
    }
  };

  const handleStake = async () => {
    if (!signer || !stakeInput || parseFloat(stakeInput) <= 0) {
      alert('Please enter a valid amount');
      return;
    }
    
    if (!selectedL2) {
      alert('No L2 registered yet. Please register an L2 first.');
      return;
    }
    
    try {
      setLoading(true);
      const amount = ethers.parseEther(stakeInput);
      
      // 1. Approve TON
      const tonContract = new ethers.Contract(CONFIG.contracts.ton, TON_ABI, signer);
      const approveTx = await tonContract.approve(CONFIG.contracts.depositManager, amount);
      await approveTx.wait();
      
      // 2. Deposit to DepositManager
      const depositManager = new ethers.Contract(CONFIG.contracts.depositManager, DEPOSIT_MANAGER_ABI, signer);
      const depositTx = await depositManager.deposit(selectedL2, amount);
      await depositTx.wait();
      
      alert('Staking successful!');
      setStakeInput('');
      
      // Reload balances
      if (provider) {
        await loadBalances(address, provider);
      }
    } catch (error: any) {
      console.error('Staking failed:', error);
      alert(`Staking failed: ${error.message || 'Unknown error'}`);
    } finally {
      setLoading(false);
    }
  };

  const importTestAccount = async (index: number) => {
    if (!provider) return;
    
    try {
      const account = TEST_ACCOUNTS[index];
      alert(`Please import this private key to MetaMask:\n\n${account.privateKey}\n\nAccount: ${account.name}`);
    } catch (error) {
      console.error('Failed to show account info:', error);
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>TON Staking V3</h1>
        <p className="subtitle">Local Development Interface</p>
      </header>

      <main className="container">
        {!address ? (
          <div className="connect-section">
            <h2>Connect Your Wallet</h2>
            <p>Connect to interact with TON Staking V3</p>
            <button onClick={connectWallet} disabled={loading} className="btn btn-primary">
              {loading ? 'Connecting...' : 'Connect Wallet'}
            </button>
            
            <div className="test-accounts">
              <h3>Test Accounts</h3>
              <p>Import one of these accounts to MetaMask:</p>
              {TEST_ACCOUNTS.map((account, index) => (
                <div key={index} className="test-account">
                  <strong>{account.name}</strong>
                  <div className="address">{account.address}</div>
                  <button onClick={() => importTestAccount(index)} className="btn btn-small">
                    Show Private Key
                  </button>
                </div>
              ))}
            </div>
          </div>
        ) : (
          <div className="dashboard">
            <div className="account-info">
              <h2>Account</h2>
              <div className="address-display">{address}</div>
            </div>

            <div className="balances">
              <h2>Balances</h2>
              <div className="balance-grid">
                <div className="balance-card">
                  <div className="balance-label">TON</div>
                  <div className="balance-value">{parseFloat(tonBalance).toFixed(4)}</div>
                </div>
                <div className="balance-card">
                  <div className="balance-label">WTON</div>
                  <div className="balance-value">{parseFloat(wtonBalance).toFixed(4)}</div>
                </div>
                <div className="balance-card">
                  <div className="balance-label">Staked</div>
                  <div className="balance-value">{parseFloat(stakedAmount).toFixed(4)}</div>
                </div>
              </div>
            </div>

            <div className="staking-section">
              <h2>Stake TON</h2>
              
              {l2List.length === 0 ? (
                <div className="warning-box">
                  <p>No L2 registered yet. Register L2 using SystemConfig: {CONFIG.contracts.systemConfig || 'N/A'}</p>
                </div>
              ) : (
                <>
                  <div className="input-group">
                    <label>Select L2:</label>
                    <select 
                      value={selectedL2} 
                      onChange={(e) => setSelectedL2(e.target.value)}
                      className="input"
                    >
                      {l2List.map((l2, index) => (
                        <option key={index} value={l2}>
                          {l2.substring(0, 6)}...{l2.substring(38)}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div className="input-group">
                    <label>Amount (TON):</label>
                    <input
                      type="number"
                      value={stakeInput}
                      onChange={(e) => setStakeInput(e.target.value)}
                      placeholder="0.0"
                      className="input"
                    />
                    <small>Balance: {parseFloat(tonBalance).toFixed(4)} TON</small>
                  </div>

                  <button 
                    onClick={handleStake} 
                    disabled={loading || !stakeInput}
                    className="btn btn-primary"
                  >
                    {loading ? 'Staking...' : 'Stake'}
                  </button>
                </>
              )}
            </div>

            <div className="info-section">
              <h2>Information</h2>
              <div className="info-grid">
                <div className="info-item">
                  <div className="info-label">Network:</div>
                  <div className="info-value">{CONFIG.chainName}</div>
                </div>
                <div className="info-item">
                  <div className="info-label">Chain ID:</div>
                  <div className="info-value">{CONFIG.chainId}</div>
                </div>
                <div className="info-item">
                  <div className="info-label">RPC URL:</div>
                  <div className="info-value">{CONFIG.rpcUrl}</div>
                </div>
                <div className="info-item">
                  <div className="info-label">Registered L2s:</div>
                  <div className="info-value">{l2List.length}</div>
                </div>
              </div>
            </div>

            <div className="contracts-section">
              <h3>Contract Addresses</h3>
              <div className="contracts-list">
                {Object.entries(CONFIG.contracts).map(([name, addr]) => (
                  <div key={name} className="contract-item">
                    <strong>{name}:</strong>
                    <code>{addr}</code>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}
      </main>

      <footer className="footer">
        <p>TON Staking V3 - Local Development Environment</p>
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
