import { Game } from '../lib/interactiveApi';

interface GameInfoPanelProps {
  game: Game | null;
}

export default function GameInfoPanel({ game }: GameInfoPanelProps) {
  if (!game) {
    return (
      <div className="bg-white rounded-lg shadow p-6">
        <h2 className="text-xl font-bold mb-4">🎮 게임 정보</h2>
        <p className="text-gray-600">게임이 생성되지 않았습니다.</p>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-lg shadow p-6">
      <h2 className="text-xl font-bold mb-4">🎮 게임 정보</h2>
      
      <div className="space-y-3">
        <div className="flex justify-between">
          <span className="text-gray-600">게임 ID:</span>
          <span className="font-mono text-sm">{game.id.slice(0, 10)}...</span>
        </div>
        
        <div className="flex justify-between">
          <span className="text-gray-600">상태:</span>
          <span className={`font-bold ${
            game.status === 'IN_PROGRESS' ? 'text-blue-600' :
            game.status === 'CHALLENGER_WINS' ? 'text-green-600' :
            'text-red-600'
          }`}>
            {game.status === 'IN_PROGRESS' ? '진행 중' :
             game.status === 'CHALLENGER_WINS' ? '챌린저 승리!' :
             '제안자 승리'}
          </span>
        </div>
        
        <div className="flex justify-between">
          <span className="text-gray-600">Root Block:</span>
          <span>#{game.rootBlock}</span>
        </div>
        
        <div className="flex justify-between">
          <span className="text-gray-600">Max Depth:</span>
          <span>{game.maxDepth}</span>
        </div>
        
        <div className="flex justify-between">
          <span className="text-gray-600">Claim 수:</span>
          <span>{game.claims.length}</span>
        </div>
        
        {game.winner && (
          <div className="mt-4 p-3 bg-green-50 rounded">
            <span className="text-gray-600">승자:</span>
            <span className="font-mono text-sm ml-2">{game.winner.slice(0, 10)}...</span>
          </div>
        )}
      </div>
    </div>
  );
}
