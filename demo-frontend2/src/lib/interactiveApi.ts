const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3001';

export interface Game {
  id: string;
  address: string;
  rootBlock: number;
  status: string;
  rootClaim: string;
  createdAt: string;
  updatedAt: string;
  maxDepth: number;
  splitDepth: number;
  claims: any[];
  winner?: string;
}

export interface ValidMove {
  id: string;
  type: 'attack' | 'defend';
  description: string;
  strategyHint: string;
  riskLevel: 'low' | 'medium' | 'high';
  claimData: {
    parentClaimId: string;
    depth: number;
    position: string;
    claim: string;
  };
  estimatedGas: number;
  expectedOutcome: 'win' | 'lose' | 'unknown';
}

export interface CreateGameResponse {
  success: boolean;
  game: Game;
}

export interface GetStatusResponse {
  success: boolean;
  game: Game;
}

export interface GetMovesResponse {
  success: boolean;
  moves: ValidMove[];
}

export interface SubmitMoveResponse {
  success: boolean;
  claimId: string;
}

export interface ResolveResponse {
  success: boolean;
  reward: {
    winner: string;
    rewardAmount: string;
    slashedAddresses: string[];
    slashedAmounts: string[];
  };
}

export const interactiveApi = {
  // 게임 생성
  createGame: async (rootBlock: number, userAddress: string): Promise<Game> => {
    const res = await fetch(`${BACKEND_URL}/api/game/create`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ rootBlock, userAddress }),
    });
    const data: CreateGameResponse = await res.json();
    if (!data.success) throw new Error('Failed to create game');
    return data.game;
  },

  // 게임 상태 조회
  getGameStatus: async (gameId: string): Promise<Game> => {
    const res = await fetch(`${BACKEND_URL}/api/game/${gameId}/status`);
    const data: GetStatusResponse = await res.json();
    if (!data.success) throw new Error('Failed to get game status');
    return data.game;
  },

  // 유효한 move들 조회
  getValidMoves: async (gameId: string, userAddress: string): Promise<ValidMove[]> => {
    const res = await fetch(`${BACKEND_URL}/api/game/${gameId}/moves?userAddress=${userAddress}`);
    const data: GetMovesResponse = await res.json();
    if (!data.success) throw new Error('Failed to get valid moves');
    return data.moves;
  },

  // move 제출
  submitMove: async (gameId: string, moveId: string, userAddress: string): Promise<string> => {
    const res = await fetch(`${BACKEND_URL}/api/game/${gameId}/move/submit`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ moveId, userAddress }),
    });
    const data: SubmitMoveResponse = await res.json();
    if (!data.success) throw new Error('Failed to submit move');
    return data.claimId;
  },

  // 게임 종료
  resolveGame: async (gameId: string): Promise<any> => {
    const res = await fetch(`${BACKEND_URL}/api/game/${gameId}/resolve`, {
      method: 'POST',
    });
    const data: ResolveResponse = await res.json();
    if (!data.success) throw new Error('Failed to resolve game');
    return data.reward;
  },
};
