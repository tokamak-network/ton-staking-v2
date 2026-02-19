import { ethers } from "ethers";
import { Game, GameStatus, Claim, ValidMove, RewardDistribution } from "../types.js";
import { ContractService } from "./contractService.js";
import { ChallengerAssistant } from "./challengerAssistant.js";
import { EventWatcher } from "./eventWatcher.js";
import { config } from "../config.js";

export class InteractiveGameRunner {
  private contractService: ContractService;
  private challengerAssistant: ChallengerAssistant;
  private eventWatcher: EventWatcher;
  private games: Map<string, Game>;

  constructor() {
    this.contractService = new ContractService();
    this.challengerAssistant = new ChallengerAssistant(this.contractService);
    this.eventWatcher = new EventWatcher();
    this.games = new Map();
  }

  /**
   * 새로운 게임 생성
   */
  async createGame(rootBlock: number, userAddress: string): Promise<Game> {
    // Root claim 생성 (잘못된 claim을 가정)
    const rootClaim = ethers.keccak256(
      ethers.toUtf8Bytes(`root-${rootBlock}-${Date.now()}`)
    );

    const gameAddress = await this.contractService.createGame(rootClaim, "0x");
    const gameInfo = await this.contractService.getGameInfo(gameAddress);

    const game: Game = {
      id: gameAddress,
      address: gameAddress,
      rootBlock,
      status: GameStatus.IN_PROGRESS,
      rootClaim,
      createdAt: new Date(),
      updatedAt: new Date(),
      maxDepth: gameInfo.maxDepth,
      splitDepth: gameInfo.splitDepth,
      claims: [
        {
          id: "0",
          claimant: await this.contractService["signer"].getAddress(),
          parentClaimId: "",
          depth: 0,
          position: BigInt(1),
          claim: gameInfo.rootClaim.claim,
          timestamp: new Date(),
        },
      ],
    };

    this.games.set(gameAddress, game);

    // 이벤트 리스너 등록
    this.eventWatcher.watchGame(gameAddress, game, (event) => {
      this.handleGameEvent(gameAddress, event);
    });

    return game;
  }

  /**
   * 게임 상태 조회
   */
  getGame(gameId: string): Game | undefined {
    return this.games.get(gameId);
  }

  /**
   * 유효한 move들 조회
   */
  async getValidMoves(gameId: string, userAddress: string): Promise<ValidMove[]> {
    const game = this.games.get(gameId);
    if (!game) {
      throw new Error(`Game ${gameId} not found`);
    }

    return this.challengerAssistant.getValidMoves(game, userAddress);
  }

  /**
   * Move 제출
   */
  async submitMove(
    gameId: string,
    moveId: string,
    userAddress: string
  ): Promise<{ claimId: string }> {
    const game = this.games.get(gameId);
    if (!game) {
      throw new Error(`Game ${gameId} not found`);
    }

    const validMoves = await this.challengerAssistant.getValidMoves(game, userAddress);
    const move = validMoves.find(m => m.id === moveId);

    if (!move) {
      throw new Error(`Invalid move: ${moveId}`);
    }

    const signer = new ethers.Wallet(config.privateKey);
    const result = await this.challengerAssistant.submitMove(game.address, move, signer);

    // 새 claim 추가
    game.claims.push({
      id: result.claimId,
      claimant: await signer.getAddress(),
      parentClaimId: move.claimData.parentClaimId,
      depth: move.claimData.depth,
      position: move.claimData.position,
      claim: move.claimData.claim,
      timestamp: new Date(),
    });

    game.updatedAt = new Date();

    return { claimId: result.claimId };
  }

  /**
   * 게임 종료
   */
  async resolveGame(gameId: string): Promise<RewardDistribution> {
    const game = this.games.get(gameId);
    if (!game) {
      throw new Error(`Game ${gameId} not found`);
    }

    const winner = await this.contractService.resolveGame(game.address);
    
    game.status = winner.toLowerCase() === (await this.contractService["signer"].getAddress()).toLowerCase()
      ? GameStatus.CHALLENGER_WINS
      : GameStatus.PROPOSER_WINS;
    game.winner = winner;
    game.updatedAt = new Date();

    // Bond 분배
    await this.contractService.distributeBond(parseInt(gameId));

    return {
      winner,
      rewardAmount: config.bondAmount,
      slashedAddresses: [],
      slashedAmounts: [],
    };
  }

  /**
   * 게임 이벤트 처리
   */
  private handleGameEvent(gameId: string, event: any) {
    const game = this.games.get(gameId);
    if (!game) return;

    console.log(`[EventWatcher] Event for game ${gameId}:`, event);

    if (event.type === "CLAIM_ADDED") {
      // Claim 추가 처리
      // (실제로는 submitMove에서 이미 처리하지만, 다른 참여자의 claim도 처리)
    } else if (event.type === "GAME_RESOLVED") {
      game.status = GameStatus.CHALLENGER_WINS;
      game.winner = event.data.winner;
      game.updatedAt = new Date();
    }
  }

  /**
   * 게임 정리
   */
  cleanupGame(gameId: string) {
    this.games.delete(gameId);
    this.eventWatcher.unwatchGame(gameId);
  }

  /**
   * 모든 정리
   */
  cleanup() {
    this.games.clear();
    this.eventWatcher.cleanup();
  }
}
