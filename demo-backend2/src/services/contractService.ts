import { ethers } from "ethers";
import { config } from "../config.js";
import { getProvider, getSigner, getContract, FAULT_DISPUTE_GAME_ABI, FAULT_DISPUTE_GAME_FACTORY_ABI, SEIG_MANAGER_ABI } from "../utils/ethers.js";

export class ContractService {
  private provider: ethers.JsonRpcProvider;
  private signer: ethers.Wallet;
  private gameFactory: ethers.Contract;
  private seigManager: ethers.Contract;

  constructor() {
    this.provider = getProvider();
    this.signer = getSigner(config.privateKey);
    
    // Initialize contracts
    if (config.faultDisputeGameFactory) {
      this.gameFactory = new ethers.Contract(
        config.faultDisputeGameFactory,
        FAULT_DISPUTE_GAME_FACTORY_ABI,
        this.signer
      );
    }
    
    if (config.seigManager) {
      this.seigManager = new ethers.Contract(
        config.seigManager,
        SEIG_MANAGER_ABI,
        this.signer
      );
    }
  }

  /**
   * Create a new DisputeGame
   */
  async createGame(rootClaim: string, extraData: string = "0x"): Promise<string> {
    if (!this.gameFactory) {
      throw new Error("GameFactory not configured");
    }

    const tx = await this.gameFactory.create(
      ethers.hexlify(rootClaim),
      extraData
    );
    const receipt = await tx.wait();

    // Extract game address from event
    const event = receipt?.logs.find((log: any) => {
      try {
        const parsed = this.gameFactory.interface.parseLog(log);
        return parsed?.name === "DisputeGameCreated";
      } catch {
        return false;
      }
    });

    if (!event) {
      throw new Error("DisputeGameCreated event not found");
    }

    const parsed = this.gameFactory.interface.parseLog(event);
    return parsed.args.disputeProxy as string;
  }

  /**
   * Attack a claim in the game
   */
  async attack(gameAddress: string, parentClaimId: string, claim: string): Promise<string> {
    const gameContract = new ethers.Contract(
      gameAddress,
      FAULT_DISPUTE_GAME_ABI,
      this.signer
    );

    const tx = await gameContract.attack(
      parseInt(parentClaimId),
      ethers.hexlify(claim)
    );
    const receipt = await tx.wait();

    // Extract claim ID from event
    const event = receipt?.logs.find((log: any) => {
      try {
        const parsed = gameContract.interface.parseLog(log);
        return parsed?.name === "ClaimAdded";
      } catch {
        return false;
      }
    });

    if (!event) {
      throw new Error("ClaimAdded event not found");
    }

    const parsed = gameContract.interface.parseLog(event);
    return parsed.args.claimId.toString();
  }

  /**
   * Defend a claim in the game
   */
  async defend(gameAddress: string, parentClaimId: string, position: bigint, claim: string): Promise<string> {
    const gameContract = new ethers.Contract(
      gameAddress,
      FAULT_DISPUTE_GAME_ABI,
      this.signer
    );

    const tx = await gameContract.move(
      parseInt(parentClaimId),
      position,
      ethers.hexlify(claim)
    );
    const receipt = await tx.wait();

    const event = receipt?.logs.find((log: any) => {
      try {
        const parsed = gameContract.interface.parseLog(log);
        return parsed?.name === "ClaimAdded";
      } catch {
        return false;
      }
    });

    if (!event) {
      throw new Error("ClaimAdded event not found");
    }

    const parsed = gameContract.interface.parseLog(event);
    return parsed.args.claimId.toString();
  }

  /**
   * Resolve the game and determine winner
   */
  async resolveGame(gameAddress: string): Promise<string> {
    const gameContract = new ethers.Contract(
      gameAddress,
      FAULT_DISPUTE_GAME_ABI,
      this.signer
    );

    const tx = await gameContract.resolve();
    const receipt = await tx.wait();

    // Extract winner from event
    const event = receipt?.logs.find((log: any) => {
      try {
        const parsed = gameContract.interface.parseLog(log);
        return parsed?.name === "GameResolved";
      } catch {
        return false;
      }
    });

    if (!event) {
      throw new Error("GameResolved event not found");
    }

    const parsed = gameContract.interface.parseLog(event);
    return parsed.args.winner as string;
  }

  /**
   * Distribute bond to the winner
   */
  async distributeBond(gameIndex: number): Promise<void> {
    if (!this.seigManager) {
      throw new Error("SeigManager not configured");
    }

    const tx = await this.seigManager.distributeBond(gameIndex);
    await tx.wait();
  }

  /**
   * Get game information
   */
  async getGameInfo(gameAddress: string): Promise<any> {
    const gameContract = new ethers.Contract(
      gameAddress,
      FAULT_DISPUTE_GAME_ABI,
      this.provider
    );

    const [rootClaim, duration, maxDepth, splitDepth] = await Promise.all([
      gameContract.getRootClaim(),
      gameContract.gameDuration(),
      gameContract.maxDepth(),
      gameContract.splitDepth(),
    ]);

    return {
      address: gameAddress,
      rootClaim: {
        claimant: rootClaim.claimant,
        claim: rootClaim.claim,
        position: rootClaim.position,
      },
      duration,
      maxDepth,
      splitDepth,
    };
  }

  /**
   * Get claim information
   */
  async getClaim(gameAddress: string, claimId: number): Promise<any> {
    const gameContract = new ethers.Contract(
      gameAddress,
      FAULT_DISPUTE_GAME_ABI,
      this.provider
    );

    const claim = await gameContract.getClaim(claimId);
    return {
      id: claimId.toString(),
      parentClaimId: claim.parentIndex.toString(),
      claimant: claim.claimant,
      claim: claim.claim,
      position: claim.position,
      clock: claim.clock,
    };
  }
}
