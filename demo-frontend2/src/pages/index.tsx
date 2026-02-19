import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { useInteractiveGame } from '../hooks/useInteractiveGame';
import GameInfoPanel from '../components/GameInfoPanel';
import MoveSelectionPanel from '../components/MoveSelectionPanel';
import RewardPanel from '../components/RewardPanel';
import GameLogPanel from '../components/GameLogPanel';

export default function HomePage() {
  const [userAddress, setUserAddress] = useState<string>('');
  const [reward, setReward] = useState<any>(null);
  const [rootBlock, setRootBlock] = useState<number>(1000);

  const {
    game,
    moves,
    selectedMove,
    setSelectedMove,
    loading,
    error,
    createGame,
    loadMoves,
    submitMove,
    resolveGame,
  } = useInteractiveGame(userAddress);

  // 지갑 연결
  const connectWallet = async () => {
    if (typeof window !== 'undefined' && (window as any).ethereum) {
      try {
        const provider = new ethers.BrowserProvider((window as any).ethereum);
        const signer = await provider.getSigner();
        const address = await signer.getAddress();
        setUserAddress(address);
      } catch (err) {
        console.error('Failed to connect wallet:', err);
        alert('지갑 연결에 실패했습니다.');
      }
    } else {
      alert('MetaMask를 설치해주세요.');
    }
  };

  // 게임 생성
  const handleCreateGame = async () => {
    try {
      await createGame(rootBlock);
      await loadMoves();
    } catch (err) {
      console.error('Failed to create game:', err);
    }
  };

  // move 제출
  const handleSubmitMove = async () => {
    try {
      await submitMove();
      await loadMoves();
    } catch (err) {
      console.error('Failed to submit move:', err);
    }
  };

  // 게임 종료
  const handleResolveGame = async () => {
    try {
      const rewardData = await resolveGame();
      setReward(rewardData);
    } catch (err) {
      console.error('Failed to resolve game:', err);
    }
  };

  // 새 게임 시작
  const handleNewGame = () => {
    setGame(null);
    setMoves([]);
    setSelectedMove(null);
    setReward(null);
  };

  return (
    <div className="min-h-screen bg-gray-100">
      {/* Header */}
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 py-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">
                🎮 Interactive Challenger Demo
              </h1>
              <p className="text-gray-600 mt-1">
                옵션 1: 선택형 Challenger
              </p>
            </div>
            
            {userAddress ? (
              <div className="text-right">
                <p className="text-sm text-gray-600">연결된 지갑:</p>
                <p className="font-mono text-sm">
                  {userAddress.slice(0, 10)}...{userAddress.slice(-8)}
                </p>
              </div>
            ) : (
              <button
                onClick={connectWallet}
                className="bg-primary-600 text-white px-6 py-2 rounded-lg hover:bg-primary-700 transition-colors"
              >
                지갑 연결
              </button>
            )}
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 py-8">
        {error && (
          <div className="bg-red-50 border-red-200 text-red-800 px-4 py-3 rounded mb-6">
            {error}
          </div>
        )}

        {!userAddress && (
          <div className="bg-blue-50 border-blue-200 text-blue-800 px-4 py-3 rounded mb-6">
            시작하려면 지갑을 연결해주세요.
          </div>
        )}

        {!game && userAddress && (
          <div className="bg-white rounded-lg shadow p-6 mb-6">
            <h2 className="text-xl font-bold mb-4">새 게임 시작</h2>
            
            <div className="mb-4">
              <label className="block text-gray-700 font-medium mb-2">
                Root Block Number
              </label>
              <input
                type="number"
                value={rootBlock}
                onChange={(e) => setRootBlock(Number(e.target.value))}
                className="w-full px-4 py-2 border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent"
              />
            </div>
            
            <button
              onClick={handleCreateGame}
              disabled={loading}
              className={`w-full py-3 px-6 rounded-lg font-bold text-white ${
                loading ? 'bg-gray-300 cursor-not-allowed' : 'bg-primary-600 hover:bg-primary-700'
              }`}
            >
              {loading ? '생성 중...' : '게임 생성'}
            </button>
          </div>
        )}

        {game && (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* 왼쪽: 게임 정보 + Move 선택 */}
            <div className="space-y-6">
              <GameInfoPanel game={game} />
              
              {game.status === 'IN_PROGRESS' && !reward && (
                <MoveSelectionPanel
                  moves={moves}
                  selectedMove={selectedMove}
                  onSelectMove={setSelectedMove}
                  onSubmit={handleSubmitMove}
                  loading={loading}
                />
              )}
              
              {game.status !== 'IN_PROGRESS' && !reward && (
                <div className="bg-white rounded-lg shadow p-6">
                  <button
                    onClick={handleResolveGame}
                    disabled={loading}
                    className="w-full py-3 px-6 rounded-lg font-bold text-white bg-green-600 hover:bg-green-700 transition-colors"
                  >
                    {loading ? '종료 중...' : '게임 종료 및 보상 분배'}
                  </button>
                </div>
              )}
              
              {reward && (
                <>
                  <RewardPanel reward={reward} userAddress={userAddress} />
                  <button
                    onClick={handleNewGame}
                    className="w-full py-3 px-6 rounded-lg font-bold text-white bg-primary-600 hover:bg-primary-700 transition-colors"
                  >
                    새로운 게임 시작
                  </button>
                </>
              )}
            </div>
            
            {/* 오른쪽: 로그 */}
            <div>
              <GameLogPanel />
            </div>
          </div>
        )}
      </main>

      {/* Footer */}
      <footer className="bg-white border-t mt-12 py-6">
        <div className="max-w-7xl mx-auto px-4 text-center text-gray-600">
          <p>Interactive Challenger Demo - Option 1</p>
          <p className="text-sm mt-1">
            demo-backend2 + demo-frontend2
          </p>
        </div>
      </footer>
    </div>
  );
}
