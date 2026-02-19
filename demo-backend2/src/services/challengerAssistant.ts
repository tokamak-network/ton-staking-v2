import { ethers } from "ethers";
import { Game, Claim, ValidMove } from "../types.js";
import { ContractService } from "./contractService.js";

/**
 * ChallengerAssistant - 미리 계산된 올바른 move들을 제공
 * 
 * Option 1 핵심: 사용자가 복잡한 VM 실행을 하지 않고,
 * 미리 계산된 올바른 move 중에서 전략적으로 선택만 함
 */
export class ChallengerAssistant {
  private contractService: ContractService;

  constructor(contractService: ContractService) {
    this.contractService = contractService;
  }

  /**
   * 현재 게임 상태에서 가능한 모든 유효한 move 계산
   */
  async getValidMoves(game: Game, userAddress: string): Promise<ValidMove[]> {
    const moves: ValidMove[] = [];

    // 1. 가능한 공격 move 계산
    for (const claim of game.claims) {
      // 이미 방어된 claim은 공격 불가
      if (claim.counteredBy) continue;

      // maxDepth 도달하면 공격 불가
      if (claim.depth >= game.maxDepth) continue;

      const attackMove = await this.calculateAttackMove(game, claim, userAddress);
      if (attackMove) {
        moves.push(attackMove);
      }
    }

    // 2. 가능한 방어 move 계산
    const userClaims = game.claims.filter(c => 
      c.claimant.toLowerCase() === userAddress.toLowerCase()
    );

    for (const claim of userClaims) {
      if (claim.depth >= game.maxDepth) continue;

      const defendMove = await this.calculateDefendMove(game, claim, userAddress);
      if (defendMove) {
        moves.push(defendMove);
      }
    }

    // 3. 전략적 정렬 (좋은 move가 먼저)
    return this.sortMovesByStrategy(moves);
  }

  /**
   * 공격 move 계산
   * 
   * Option 1: 실제 VM 대신 미리 계산된 결과를 제공
   */
  private async calculateAttackMove(
    game: Game,
    parentClaim: Claim,
    userAddress: string
  ): Promise<ValidMove | null> {
    // VM 실행 결과 시뮬레이션
    // 실제로는 Cannon/Asterisc를 실행해야 하지만,
    // Option 1에서는 미리 계산된 올바른 값을 사용
    
    const executionResult = await this.simulateVMExecution(
      game.rootBlock,
      parentClaim.depth + 1,
      parentClaim.position,
      true // attack
    );

    if (!executionResult) {
      return null;
    }

    // 올바른 counter-claim 계산
    const correctClaim = executionResult.hash;
    const newPosition = this.calculateAttackPosition(parentClaim.position);

    return {
      id: `attack-${parentClaim.id}`,
      type: "attack",
      description: `Depth ${parentClaim.depth + 1}에서 Claim #${parentClaim.id} 공격`,
      strategyHint: "빠르게 공격하면 게임을 일찍 끝낼 수 있습니다",
      riskLevel: "medium",
      claimData: {
        parentClaimId: parentClaim.id,
        depth: parentClaim.depth + 1,
        position: newPosition,
        claim: correctClaim,
      },
      estimatedGas: 150000,
      expectedOutcome: executionResult.isCorrect ? "win" : "unknown",
    };
  }

  /**
   * 방어 move 계산
   */
  private async calculateDefendMove(
    game: Game,
    claim: Claim,
    userAddress: string
  ): Promise<ValidMove | null> {
    // VM 실행 결과 시뮬레이션
    const executionResult = await this.simulateVMExecution(
      game.rootBlock,
      claim.depth + 1,
      this.calculateDefensePosition(claim.position),
      false // defend
    );

    if (!executionResult) {
      return null;
    }

    return {
      id: `defend-${claim.id}`,
      type: "defend",
      description: `나의 Claim #${claim.id} at depth ${claim.depth} 방어`,
      strategyHint: "안전한 선택이지만 더 오래 걸릴 수 있습니다",
      riskLevel: "low",
      claimData: {
        parentClaimId: claim.id,
        depth: claim.depth + 1,
        position: this.calculateDefensePosition(claim.position),
        claim: executionResult.hash,
      },
      estimatedGas: 150000,
      expectedOutcome: "win",
    };
  }

  /**
   * VM 실행 결과 시뮬레이션
   * 
   * Option 1 핵심: 실제 VM 실행 대신 시뮬레이션
   * 
   * 실제 환경에서는 op-challenger (Go)를 사용하여
   * Cannon/Asterisc VM을 실행하고 올바른 hash를 계산
   */
  private async simulateVMExecution(
    rootBlock: number,
    depth: number,
    position: bigint,
    isAttack: boolean
  ): Promise<{ hash: string; isCorrect: boolean } | null> {
    // 간소화된 시뮬레이션
    // 실제로는 해당 position에서의 VM 실행 결과를 계산해야 함
    
    // 랜덤하지만 결정적인 hash 생성 (데모용)
    const input = `${rootBlock}-${depth}-${position}-${isAttack}`;
    const hash = ethers.keccak256(ethers.toUtf8Bytes(input));
    
    // 데모 시나리오: 깊어질수록 올바른 확률 감소
    const isCorrect = depth < game.maxDepth - 2;
    
    return { hash, isCorrect };
  }

  /**
   * 공격 position 계산 (left child)
   */
  private calculateAttackPosition(parentPosition: bigint): bigint {
    // Left child: position * 2
    return parentPosition * 2n;
  }

  /**
   * 방어 position 계산 (right child)
   */
  private calculateDefensePosition(parentPosition: bigint): bigint {
    // Right child: position * 2 + 1
    return parentPosition * 2n + 1n;
  }

  /**
   * Move들 전략적 정렬 (좋은 move가 먼저)
   */
  private sortMovesByStrategy(moves: ValidMove[]): ValidMove[] {
    return moves.sort((a, b) => {
      // 1. 승리 확률이 높은 것 우선
      if (a.expectedOutcome !== b.expectedOutcome) {
        const outcomeOrder = { "win": 0, "unknown": 1, "lose": 2 };
        return outcomeOrder[a.expectedOutcome] - outcomeOrder[b.expectedOutcome];
      }
      
      // 2. 리스크가 낮은 것 우선
      const riskOrder = { "low": 0, "medium": 1, "high": 2 };
      if (riskOrder[a.riskLevel] !== riskOrder[b.riskLevel]) {
        return riskOrder[a.riskLevel] - riskOrder[b.riskLevel];
      }
      
      // 3. 가스 비용이 낮은 것 우선
      return a.estimatedGas - b.estimatedGas;
    });
  }

  /**
   * Move 제출
   */
  async submitMove(
    gameAddress: string,
    move: ValidMove,
    signer: ethers.Signer
  ): Promise<{ claimId: string; txHash: string }> {
    if (move.type === "attack") {
      const claimId = await this.contractService.attack(
        gameAddress,
        move.claimData.parentClaimId,
        move.claimData.claim
      );
      return { claimId, txHash: "" }; // txHash는 contractService에서 추출 가능
    } else {
      const claimId = await this.contractService.defend(
        gameAddress,
        move.claimData.parentClaimId,
        move.claimData.position,
        move.claimData.claim
      );
      return { claimId, txHash: "" };
    }
  }
}
