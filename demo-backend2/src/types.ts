// Game Status
export enum GameStatus {
  IN_PROGRESS = "IN_PROGRESS",
  CHALLENGER_WINS = "CHALLENGER_WINS",
  PROPOSER_WINS = "PROPOSER_WINS",
}

export interface Game {
  id: string;
  address: string;
  rootBlock: number;
  status: GameStatus;
  rootClaim: string;
  createdAt: Date;
  updatedAt: Date;
  maxDepth: number;
  splitDepth: number;
  claims: Claim[];
  winner?: string;
}

export interface Claim {
  id: string;
  claimant: string;
  parentClaimId: string;
  depth: number;
  position: bigint;
  claim: string;
  counteredBy?: string;
  timestamp: Date;
}

// Valid Move (calculated by ChallengerAssistant)
export interface ValidMove {
  id: string;
  type: "attack" | "defend";
  description: string;
  strategyHint: string;
  riskLevel: "low" | "medium" | "high";
  claimData: {
    parentClaimId: string;
    depth: number;
    position: bigint;
    claim: string;
  };
  estimatedGas: number;
  expectedOutcome: "win" | "lose" | "unknown";
}

// Game Events
export interface GameEvent {
  type: "CLAIM_ADDED" | "GAME_RESOLVED" | "GAME_CREATED" | "MOVE_SUBMITTED";
  gameId: string;
  data: any;
  timestamp: Date;
}

// Reward Distribution
export interface RewardDistribution {
  winner: string;
  rewardAmount: string;
  slashedAddresses: string[];
  slashedAmounts: string[];
}
