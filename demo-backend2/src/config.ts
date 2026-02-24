import dotenv from "dotenv";
import * as fs from "fs";
import * as path from "path";

dotenv.config();

// ⭐ 기본값 추가 (development 모드에서)
const DEFAULT_PRIVATE_KEY = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"; // Hardhat account #0

// ⭐ 동적으로 networks.json과 addresses.json 읽기
const PROJECT_ROOT = path.resolve(__dirname, "../..");

function loadJson(filePath: string): any {
  try {
    const fullPath = path.join(PROJECT_ROOT, filePath);
    if (fs.existsSync(fullPath)) {
      return JSON.parse(fs.readFileSync(fullPath, "utf-8"));
    }
  } catch (e) {
    console.warn(`⚠️  Failed to load ${filePath}:`, e);
  }
  return {};
}

// networks.json에서 RPC URL 가져오기
const networksConfig = loadJson("demo-config/networks.json");
const addressesConfig = loadJson(".devnet/addresses.json");

// L1 RPC URL (55683) - networks.json이 우선, 없으면 기본값
const L1_RPC_URL = networksConfig.l1?.rpcUrl || "http://127.0.0.1:55683";

export const config = {
  port: parseInt(process.env.PORT || "3001"),
  nodeEnv: process.env.NODE_ENV || "development",
  
  // ⭐ L1 RPC URL 사용 (55683)
  hardhatRpcUrl: process.env.HARDHAT_RPC_URL || L1_RPC_URL,
  
  // Contract addresses - 환경변수 우선, 없으면 addresses.json에서
  faultDisputeGameFactory: process.env.FAULT_DISPUTE_GAME_FACTORY || addressesConfig.disputeGameFactory || "",
  faultDisputeGame: process.env.FAULT_DISPUTE_GAME || "",
  seigManager: process.env.SEIG_MANAGER || addressesConfig.seigManagerProxy || "",
  depositManager: process.env.DEPOSIT_MANAGER || addressesConfig.depositManagerProxy || "",
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
