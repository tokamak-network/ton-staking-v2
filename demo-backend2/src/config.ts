import dotenv from "dotenv";

dotenv.config();

// ⭐ 기본값 추가 (development 모드에서)
const DEFAULT_PRIVATE_KEY = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"; // Hardhat account #0

export const config = {
  port: parseInt(process.env.PORT || "3001"),
  nodeEnv: process.env.NODE_ENV || "development",
  
  hardhatRpcUrl: process.env.HARDHAT_RPC_URL || "http://127.0.0.1:8545",
  
  // Contract addresses
  faultDisputeGameFactory: process.env.FAULT_DISPUTE_GAME_FACTORY || "",
  faultDisputeGame: process.env.FAULT_DISPUTE_GAME || "",
  seigManager: process.env.SEIG_MANAGER || "",
  depositManager: process.env.DEPOSIT_MANAGER || "",
  winningChallengerTracker: process.env.WINNING_CHALLENGER_TRACKER || "",
  
  // ⭐ Account: 기존처럼 빈 문자열 허용, 기본값 제공
  privateKey: process.env.PRIVATE_KEY || DEFAULT_PRIVATE_KEY,
  
  // Game configuration
  gameDurationSeconds: parseInt(process.env.GAME_DURATION_SECONDS || "7200"),
  bondAmount: process.env.BOND_AMOUNT || "1000000",
};

// Validate required config (production only)
if (!config.privateKey && config.nodeEnv !== "development") {
  throw new Error("PRIVATE_KEY is required in production");
}

// ⭐ Contract addresses가 없어도 development에서는 에러 안 뱉음
if (config.nodeEnv === "development") {
  if (!config.faultDisputeGameFactory) {
    console.warn("⚠️  FAULT_DISPUTE_GAME_FACTORY not configured. Some features may not work.");
  }
  if (!config.seigManager) {
    console.warn("⚠️  SEIG_MANAGER not configured. Slashing features may not work.");
  }
}
