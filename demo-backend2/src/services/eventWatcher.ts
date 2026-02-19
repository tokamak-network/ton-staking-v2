import { ethers } from "ethers";
import { Game, GameEvent } from "../types.js";
import { getProvider, FAULT_DISPUTE_GAME_ABI } from "../utils/ethers.js";

export class EventWatcher {
  private provider: ethers.JsonRpcProvider;
  private games: Map<string, Game>;
  private eventCallbacks: Map<string, (event: GameEvent) => void>;

  constructor() {
    this.provider = getProvider();
    this.games = new Map();
    this.eventCallbacks = new Map();
  }

  /**
   * 게임에 이벤트 리스너 등록
   */
  async watchGame(gameAddress: string, game: Game, callback: (event: GameEvent) => void) {
    this.games.set(gameAddress, game);
    this.eventCallbacks.set(gameAddress, callback);

    const gameContract = new ethers.Contract(
      gameAddress,
      FAULT_DISPUTE_GAME_ABI,
      this.provider
    );

    // ClaimAdded 이벤트 리스닝
    gameContract.on("ClaimAdded", (...args) => {
      const event = args[args.length - 1];
      const claimId = args[0].toString();
      const parentClaim = args[1].toString();
      const claimant = args[2];
      const claim = args[3];
      const position = args[4];

      const gameEvent: GameEvent = {
        type: "CLAIM_ADDED",
        gameId: gameAddress,
        data: {
          claimId,
          parentClaim,
          claimant,
          claim,
          position: position.toString(),
        },
        timestamp: new Date(),
      };

      const cb = this.eventCallbacks.get(gameAddress);
      if (cb) {
        cb(gameEvent);
      }
    });

    // GameResolved 이벤트 리스닝
    gameContract.on("GameResolved", (...args) => {
      const event = args[args.length - 1];
      const winner = args[0];
      const bondAmount = args[1];
      const rootClaim = args[2];

      const gameEvent: GameEvent = {
        type: "GAME_RESOLVED",
        gameId: gameAddress,
        data: {
          winner,
          bondAmount: bondAmount.toString(),
          rootClaim,
        },
        timestamp: new Date(),
      };

      const cb = this.eventCallbacks.get(gameAddress);
      if (cb) {
        cb(gameEvent);
      }
    });
  }

  /**
   * 게임 이벤트 리스너 중지
   */
  unwatchGame(gameAddress: string) {
    const game = this.games.get(gameAddress);
    if (game) {
      // 모든 이벤트 리스너 제거
      const gameContract = new ethers.Contract(
        gameAddress,
        FAULT_DISPUTE_GAME_ABI,
        this.provider
      );
      gameContract.removeAllListeners();
    }

    this.games.delete(gameAddress);
    this.eventCallbacks.delete(gameAddress);
  }

  /**
   * 모든 리스너 중지
   */
  cleanup() {
    for (const gameAddress of this.games.keys()) {
      this.unwatchGame(gameAddress);
    }
  }
}
