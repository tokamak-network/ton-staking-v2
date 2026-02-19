import { useState, useEffect, useCallback } from 'react';
import { interactiveApi, Game, ValidMove } from '../lib/interactiveApi';

export function useInteractiveGame(userAddress: string) {
  const [game, setGame] = useState<Game | null>(null);
  const [moves, setMoves] = useState<ValidMove[]>([]);
  const [selectedMove, setSelectedMove] = useState<ValidMove | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // 게임 생성
  const createGame = useCallback(async (rootBlock: number) => {
    setLoading(true);
    setError(null);
    try {
      const newGame = await interactiveApi.createGame(rootBlock, userAddress);
      setGame(newGame);
      return newGame;
    } catch (err: any) {
      setError(err.message || 'Failed to create game');
      throw err;
    } finally {
      setLoading(false);
    }
  }, [userAddress]);

  // 게임 상태 갱신
  const refreshGame = useCallback(async () => {
    if (!game?.id) return;
    setLoading(true);
    setError(null);
    try {
      const updatedGame = await interactiveApi.getGameStatus(game.id);
      setGame(updatedGame);
    } catch (err: any) {
      setError(err.message || 'Failed to refresh game');
    } finally {
      setLoading(false);
    }
  }, [game?.id]);

  // 유효한 move들 로드
  const loadMoves = useCallback(async () => {
    if (!game?.id) return;
    setLoading(true);
    setError(null);
    try {
      const validMoves = await interactiveApi.getValidMoves(game.id, userAddress);
      setMoves(validMoves);
    } catch (err: any) {
      setError(err.message || 'Failed to load moves');
    } finally {
      setLoading(false);
    }
  }, [game?.id, userAddress]);

  // move 제출
  const submitMove = useCallback(async () => {
    if (!game?.id || !selectedMove) return;
    setLoading(true);
    setError(null);
    try {
      await interactiveApi.submitMove(game.id, selectedMove.id, userAddress);
      setSelectedMove(null);
      setMoves([]);
      await refreshGame();
    } catch (err: any) {
      setError(err.message || 'Failed to submit move');
      throw err;
    } finally {
      setLoading(false);
    }
  }, [game?.id, selectedMove, userAddress, refreshGame]);

  // 게임 종료
  const resolveGame = useCallback(async () => {
    if (!game?.id) return;
    setLoading(true);
    setError(null);
    try {
      const reward = await interactiveApi.resolveGame(game.id);
      await refreshGame();
      return reward;
    } catch (err: any) {
      setError(err.message || 'Failed to resolve game');
      throw err;
    } finally {
      setLoading(false);
    }
  }, [game?.id, refreshGame]);

  // 주기적으로 상태 갱신
  useEffect(() => {
    if (!game?.id) return;
    
    const interval = setInterval(() => {
      refreshGame();
    }, 5000); // 5초마다 갱신

    return () => clearInterval(interval);
  }, [game?.id, refreshGame]);

  return {
    game,
    moves,
    selectedMove,
    setSelectedMove,
    loading,
    error,
    createGame,
    refreshGame,
    loadMoves,
    submitMove,
    resolveGame,
  };
}
