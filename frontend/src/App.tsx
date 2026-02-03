import { useMemo, useState, useEffect } from "react";
import { BrowserProvider, Contract, parseEther, parseUnits } from "ethers";

const lotteryCandidateAbi = [
  "function depositTON(uint256 tonAmount) returns (bool)",
  "function depositWTON(uint256 wtonAmount) returns (bool)",
  "function enterLottery() returns (bool)",
  "function drawWinner() returns (address)",
  "function currentRound() view returns (uint256)",
  "function roundWinner(uint256 round) view returns (address)",
  "function roundTotalTickets(uint256 round) view returns (uint256)",
  "function depositSeigniorage(address token, uint256 amount) returns (bool)",
  "function distributeSeigniorage(uint256 round, address token) returns (bool)"
];

const depositManagerAbi = [
  "function requestWithdrawal(address layer2, uint256 amount) returns (bool)",
  "function processRequest(address layer2, bool receiveTon) returns (bool)"
];

const tonAbi = [
  "function approveAndCall(address spender, uint256 amount, bytes data) returns (bool)"
];

const erc20Abi = [
  "function approve(address spender, uint256 amount) returns (bool)"
];

export default function App() {
  const [account, setAccount] = useState<string>("");
  const [candidateAddress, setCandidateAddress] = useState("");
  const [depositManagerAddress, setDepositManagerAddress] = useState("");
  const [tonAddress, setTonAddress] = useState("");
  const [wtonAddress, setWtonAddress] = useState("");
  const [tonAmount, setTonAmount] = useState("0");
  const [wtonAmount, setWtonAmount] = useState("0");
  const [unstakeAmount, setUnstakeAmount] = useState("0");
  const [seigAmount, setSeigAmount] = useState("0");
  const [status, setStatus] = useState("");

  // localStorage에서 주소 불러오기
  useEffect(() => {
    const saved = localStorage.getItem("lotteryCandidateAddresses");
    if (saved) {
      try {
        const addresses = JSON.parse(saved);
        if (addresses.candidate) setCandidateAddress(addresses.candidate);
        if (addresses.depositManager) setDepositManagerAddress(addresses.depositManager);
        if (addresses.ton) setTonAddress(addresses.ton);
        if (addresses.wton) setWtonAddress(addresses.wton);
      } catch (e) {
        console.error("Failed to load saved addresses", e);
      }
    }
  }, []);

  // 주소 저장
  const saveAddresses = () => {
    const addresses = {
      candidate: candidateAddress,
      depositManager: depositManagerAddress,
      ton: tonAddress,
      wton: wtonAddress,
    };
    localStorage.setItem("lotteryCandidateAddresses", JSON.stringify(addresses));
    setStatus("Addresses saved to localStorage!");
  };

  // 로컬 네트워크 프리필드 (배포 후 주소를 여기에 입력)
  const loadLocalAddresses = () => {
    // 배포 로그에서 확인한 주소를 여기에 입력하세요
    const localAddresses = {
      candidate: "", // LotteryCandidate 주소
      depositManager: "", // DepositManager 주소
      ton: "", // TON 주소
      wton: "", // WTON 주소
    };
    
    if (localAddresses.candidate) {
      setCandidateAddress(localAddresses.candidate);
      setDepositManagerAddress(localAddresses.depositManager);
      setTonAddress(localAddresses.ton);
      setWtonAddress(localAddresses.wton);
      saveAddresses();
      setStatus("Local addresses loaded! (Edit loadLocalAddresses() with your deployed addresses)");
    } else {
      setStatus("Please edit loadLocalAddresses() in App.tsx with your deployed addresses first!");
    }
  };

  const provider = useMemo(() => {
    if (!window.ethereum) return null;
    return new BrowserProvider(window.ethereum);
  }, []);

  const lotteryCandidate = useMemo(() => {
    if (!provider || !candidateAddress) return null;
    return provider.getSigner().then((signer) => new Contract(candidateAddress, lotteryCandidateAbi, signer));
  }, [provider, candidateAddress]);

  const depositManager = useMemo(() => {
    if (!provider || !depositManagerAddress) return null;
    return provider.getSigner().then((signer) => new Contract(depositManagerAddress, depositManagerAbi, signer));
  }, [provider, depositManagerAddress]);

  const ton = useMemo(() => {
    if (!provider || !tonAddress) return null;
    return provider.getSigner().then((signer) => new Contract(tonAddress, tonAbi, signer));
  }, [provider, tonAddress]);

  const wton = useMemo(() => {
    if (!provider || !wtonAddress) return null;
    return provider.getSigner().then((signer) => new Contract(wtonAddress, erc20Abi, signer));
  }, [provider, wtonAddress]);

  const connect = async () => {
    if (!provider) {
      setStatus("No wallet found. Install MetaMask.");
      return;
    }
    const signer = await provider.getSigner();
    const addr = await signer.getAddress();
    setAccount(addr);
    setStatus(`Connected: ${addr}`);
  };

  const depositWithTON = async () => {
    const tonContract = await ton;
    if (!tonContract || !candidateAddress) return;
    const amount = parseEther(tonAmount);
    const tx = await tonContract.approveAndCall(candidateAddress, amount, "0x");
    await tx.wait();
    setStatus("TON deposited via approveAndCall.");
  };

  const depositWithWTON = async () => {
    const candidate = await lotteryCandidate;
    const wtonContract = await wton;
    if (!candidate) return;
    const amount = parseUnits(wtonAmount, 27);
    if (wtonContract) {
      const approveTx = await wtonContract.approve(candidateAddress, amount);
      await approveTx.wait();
    }
    const tx = await candidate.depositWTON(amount);
    await tx.wait();
    setStatus("WTON deposited to LotteryCandidate.");
  };

  const enterLottery = async () => {
    const candidate = await lotteryCandidate;
    if (!candidate) return;
    const tx = await candidate.enterLottery();
    await tx.wait();
    setStatus("Entered lottery.");
  };

  const drawWinner = async () => {
    const candidate = await lotteryCandidate;
    if (!candidate) return;
    const tx = await candidate.drawWinner();
    await tx.wait();
    setStatus("Winner drawn.");
  };

  const fetchRound = async () => {
    const candidate = await lotteryCandidate;
    if (!candidate) return;
    const round = await candidate.currentRound();
    const lastRound = round - 1n;
    if (lastRound > 0n) {
      const winner = await candidate.roundWinner(lastRound);
      const totalTickets = await candidate.roundTotalTickets(lastRound);
      setStatus(`Last round ${lastRound}: winner ${winner}, total tickets ${totalTickets}`);
    } else {
      setStatus("No completed rounds yet.");
    }
  };

  const requestUnstake = async () => {
    const manager = await depositManager;
    if (!manager || !candidateAddress) return;
    const amount = parseUnits(unstakeAmount, 27);
    const tx = await manager.requestWithdrawal(candidateAddress, amount);
    await tx.wait();
    setStatus("Withdrawal requested.");
  };

  const processUnstake = async () => {
    const manager = await depositManager;
    if (!manager || !candidateAddress) return;
    const tx = await manager.processRequest(candidateAddress, true);
    await tx.wait();
    setStatus("Withdrawal processed (TON received).");
  };

  const depositSeigniorage = async () => {
    const candidate = await lotteryCandidate;
    const wtonContract = await wton;
    if (!candidate || !wtonContract || !wtonAddress) return;
    const amount = parseUnits(seigAmount, 27);
    const approveTx = await wtonContract.approve(candidateAddress, amount);
    await approveTx.wait();
    const tx = await candidate.depositSeigniorage(wtonAddress, amount);
    await tx.wait();
    setStatus("Seigniorage deposited.");
  };

  const distributeSeigniorage = async () => {
    const candidate = await lotteryCandidate;
    if (!candidate || !wtonAddress) return;
    const round = await candidate.currentRound();
    const distRound = round - 1n;
    if (distRound <= 0n) {
      setStatus("No completed rounds to distribute.");
      return;
    }
    const tx = await candidate.distributeSeigniorage(distRound, wtonAddress);
    await tx.wait();
    setStatus(`Seigniorage distributed for round ${distRound}.`);
  };

  return (
    <div style={{ padding: 24, fontFamily: "sans-serif" }}>
      <h2>Lottery Candidate Demo</h2>
      <div style={{ marginBottom: 16 }}>
        <button onClick={connect}>Connect Wallet</button>
        <div style={{ marginTop: 8 }}>Account: {account || "Not connected"}</div>
        <div style={{ marginTop: 8, fontSize: 12, color: "#666" }}>
          💡 로컬 네트워크 사용: MetaMask에서 네트워크 추가 → RPC URL: http://127.0.0.1:8545, Chain ID: 31337
        </div>
      </div>

      <h3>Contract Addresses</h3>
      <div>
        <input
          style={{ width: "100%", marginBottom: 6 }}
          placeholder="LotteryCandidate address"
          value={candidateAddress}
          onChange={(e) => setCandidateAddress(e.target.value)}
        />
        <input
          style={{ width: "100%", marginBottom: 6 }}
          placeholder="DepositManager address"
          value={depositManagerAddress}
          onChange={(e) => setDepositManagerAddress(e.target.value)}
        />
        <input
          style={{ width: "100%", marginBottom: 6 }}
          placeholder="TON address"
          value={tonAddress}
          onChange={(e) => setTonAddress(e.target.value)}
        />
        <input
          style={{ width: "100%", marginBottom: 6 }}
          placeholder="WTON address"
          value={wtonAddress}
          onChange={(e) => setWtonAddress(e.target.value)}
        />
        <div style={{ marginTop: 8 }}>
          <button onClick={saveAddresses} style={{ marginRight: 8 }}>
            Save Addresses
          </button>
          <button onClick={loadLocalAddresses}>
            Load Local Addresses (Edit App.tsx first!)
          </button>
        </div>
      </div>

      <h3>Stake (Deposit)</h3>
      <div>
        <input
          style={{ width: "100%", marginBottom: 6 }}
          placeholder="TON amount"
          value={tonAmount}
          onChange={(e) => setTonAmount(e.target.value)}
        />
        <button onClick={depositWithTON}>Deposit TON (approveAndCall)</button>
      </div>
      <div style={{ marginTop: 8 }}>
        <input
          style={{ width: "100%", marginBottom: 6 }}
          placeholder="WTON amount (27 decimals)"
          value={wtonAmount}
          onChange={(e) => setWtonAmount(e.target.value)}
        />
        <button onClick={depositWithWTON}>Deposit WTON</button>
      </div>

      <h3>Unstake</h3>
      <div>
        <input
          style={{ width: "100%", marginBottom: 6 }}
          placeholder="WTON amount (27 decimals)"
          value={unstakeAmount}
          onChange={(e) => setUnstakeAmount(e.target.value)}
        />
        <button onClick={requestUnstake}>Request Withdrawal</button>
        <button onClick={processUnstake} style={{ marginLeft: 8 }}>
          Process Withdrawal (TON)
        </button>
      </div>

      <h3>Lottery</h3>
      <div>
        <button onClick={enterLottery}>Enter Lottery</button>
        <button onClick={drawWinner} style={{ marginLeft: 8 }}>
          Draw Winner (operator)
        </button>
        <button onClick={fetchRound} style={{ marginLeft: 8 }}>
          Fetch Last Round
        </button>
      </div>

      <h3>Seigniorage</h3>
      <div>
        <input
          style={{ width: "100%", marginBottom: 6 }}
          placeholder="Seigniorage WTON amount (27 decimals)"
          value={seigAmount}
          onChange={(e) => setSeigAmount(e.target.value)}
        />
        <button onClick={depositSeigniorage}>Deposit Seigniorage</button>
        <button onClick={distributeSeigniorage} style={{ marginLeft: 8 }}>
          Distribute Seigniorage
        </button>
      </div>

      <h3>Status</h3>
      <pre style={{ background: "#f4f4f4", padding: 12 }}>{status}</pre>
    </div>
  );
}
