import { ethers } from "ethers";

export function getProvider(): ethers.JsonRpcProvider {
  return new ethers.JsonRpcProvider(process.env.HARDHAT_RPC_URL || "http://127.0.0.1:8545");
}

export function getSigner(privateKey?: string): ethers.Wallet {
  const provider = getProvider();
  
  // ⭐ 개발 환경에서는 기본 hardhat 계정 사용
  if (!privateKey || privateKey === "") {
    // Hardhat 기본 계정 #0의 private key
    const defaultKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
    return new ethers.Wallet(defaultKey, provider);
  }
  
  return new ethers.Wallet(privateKey, provider);
}

export async function getContract(
  address: string,
  abi: any[],
  signerOrProvider?: ethers.Signer | ethers.Provider
): Promise<ethers.Contract> {
  const provider = getProvider();
  return new ethers.Contract(address, abi, signerOrProvider || provider);
}

// ABI Definitions (simplified - load from actual contract files in production)
export const FAULT_DISPUTE_GAME_ABI = [
  "function attack(uint32 parentClaim, bytes32 claim) external returns (uint256)",
  "function move(uint32 parentClaim, uint256 claimPos, bytes32 claim) external returns (uint256)",
  "function defend(uint32 parentClaim, uint256 claimPos, bytes32 claim) external returns (uint256)",
  "function resolve() external",
  "function getRootClaim() external view returns (uint32, address, bytes32, uint256)",
  "function getClaim(uint256 claimId) external view returns (tuple(uint32 parentIndex, address claimant, bytes32 claim, uint32 position, uint32 clock))",
  "function gameDuration() external view returns (uint64)",
  "function maxDepth() external view returns (uint8)",
  "function splitDepth() external view returns (uint8)",
  "event ClaimAdded(uint256 indexed claimId, uint32 indexed parentClaim, address indexed claimant, bytes32 claim, uint32 position)",
  "event GameResolved(address indexed winner, uint256 bondAmount, bytes32 rootClaim)",
];

export const FAULT_DISPUTE_GAME_FACTORY_ABI = [
  "function create(bytes32 rootClaim, bytes extraData) external returns (address)",
  "function gameImplementation() external view returns (address)",
  "function initBond() external view returns (uint256)",
  "event DisputeGameCreated(address indexed disputeProxy, bytes32 indexed rootClaim, bytes extraData)",
];

export const SEIG_MANAGER_ABI = [
  "function distributeBond(uint256 gameIndex) external",
  "function getChallengerReward(address challenger) external view returns (uint256)",
  "event BondDistributed(uint256 indexed gameIndex, address indexed challenger, uint256 reward)",
];
