import express from "express";
import { InteractiveGameRunner } from "../services/interactiveGameRunner.js";

const router = express.Router();
const gameRunner = new InteractiveGameRunner();

/**
 * POST /api/game/create
 * 새로운 DisputeGame 생성
 */
router.post("/create", async (req, res) => {
  try {
    const { rootBlock, userAddress } = req.body;

    if (!rootBlock || !userAddress) {
      return res.status(400).json({ error: "rootBlock and userAddress are required" });
    }

    const game = await gameRunner.createGame(rootBlock, userAddress);

    res.json({
      success: true,
      game,
    });
  } catch (error: any) {
    console.error("[POST /api/game/create] Error:", error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /api/game/:id/status
 * 게임 상태 조회
 */
router.get("/:id/status", (req, res) => {
  try {
    const { id } = req.params;
    const game = gameRunner.getGame(id);

    if (!game) {
      return res.status(404).json({ error: "Game not found" });
    }

    res.json({
      success: true,
      game,
    });
  } catch (error: any) {
    console.error("[GET /api/game/:id/status] Error:", error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /api/game/:id/moves
 * 현재 가능한 move 목록
 */
router.get("/:id/moves", async (req, res) => {
  try {
    const { id } = req.params;
    const { userAddress } = req.query;

    if (!userAddress || typeof userAddress !== "string") {
      return res.status(400).json({ error: "userAddress is required" });
    }

    const moves = await gameRunner.getValidMoves(id, userAddress);

    res.json({
      success: true,
      moves,
    });
  } catch (error: any) {
    console.error("[GET /api/game/:id/moves] Error:", error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * POST /api/game/:id/move/submit
 * 선택한 move 제출
 */
router.post("/:id/move/submit", async (req, res) => {
  try {
    const { id } = req.params;
    const { moveId, userAddress } = req.body;

    if (!moveId || !userAddress) {
      return res.status(400).json({ error: "moveId and userAddress are required" });
    }

    const result = await gameRunner.submitMove(id, moveId, userAddress);

    res.json({
      success: true,
      claimId: result.claimId,
    });
  } catch (error: any) {
    console.error("[POST /api/game/:id/move/submit] Error:", error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * POST /api/game/:id/resolve
 * 게임 종료 & 보상 분배
 */
router.post("/:id/resolve", async (req, res) => {
  try {
    const { id } = req.params;

    const reward = await gameRunner.resolveGame(id);

    res.json({
      success: true,
      reward,
    });
  } catch (error: any) {
    console.error("[POST /api/game/:id/resolve] Error:", error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /api/game/:id/events
 * SSE로 실시간 이벤트 스트림
 */
router.get("/:id/events", (req, res) => {
  const { id } = req.params;

  res.setHeader("Content-Type", "text/event-stream");
  res.setHeader("Cache-Control", "no-cache");
  res.setHeader("Connection", "keep-alive");

  // SSE 구현 (실제로는 EventWatcher와 연동)
  const sendEvent = (data: any) => {
    res.write(`data: ${JSON.stringify(data)}\n\n`);
  };

  // 초기 상태 전송
  const game = gameRunner.getGame(id);
  if (game) {
    sendEvent({ type: "STATUS", data: game });
  }

  // 주기적으로 상태 확인 (실제로는 이벤트 기반으로 변경)
  const interval = setInterval(() => {
    const currentGame = gameRunner.getGame(id);
    if (currentGame) {
      sendEvent({ type: "STATUS", data: currentGame });
    } else {
      clearInterval(interval);
      res.end();
    }
  }, 2000);

  req.on("close", () => {
    clearInterval(interval);
  });
});

export function createInteractiveRoutes() {
  return router;
}
