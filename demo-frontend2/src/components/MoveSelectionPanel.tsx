import { ValidMove } from '../lib/interactiveApi';

interface MoveSelectionPanelProps {
  moves: ValidMove[];
  selectedMove: ValidMove | null;
  onSelectMove: (move: ValidMove) => void;
  onSubmit: () => void;
  loading: boolean;
}

export default function MoveSelectionPanel({
  moves,
  selectedMove,
  onSelectMove,
  onSubmit,
  loading,
}: MoveSelectionPanelProps) {
  if (moves.length === 0) {
    return (
      <div className="bg-white rounded-lg shadow p-6">
        <h2 className="text-xl font-bold mb-4">🎯 Move 선택</h2>
        <p className="text-gray-600">가능한 move가 없습니다.</p>
      </div>
    );
  }

  const getRiskColor = (level: string) => {
    switch (level) {
      case 'low': return 'bg-green-100 text-green-800';
      case 'medium': return 'bg-yellow-100 text-yellow-800';
      case 'high': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getOutcomeIcon = (outcome: string) => {
    switch (outcome) {
      case 'win': return '✅';
      case 'lose': return '❌';
      default: return '❓';
    }
  };

  return (
    <div className="bg-white rounded-lg shadow p-6">
      <h2 className="text-xl font-bold mb-4">🎯 당신의 차례!</h2>
      <p className="text-gray-600 mb-6">다음 중 하나를 선택하세요:</p>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
        {moves.map((move) => (
          <div
            key={move.id}
            className={`p-4 rounded-lg border-2 cursor-pointer transition-all ${
              selectedMove?.id === move.id
                ? 'border-primary-500 bg-primary-50'
                : 'border-gray-200 hover:border-primary-300 hover:bg-gray-50'
            }`}
            onClick={() => onSelectMove(move)}
          >
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-2">
                <span className="text-2xl">
                  {move.type === 'attack' ? '🗡️' : '🛡️'}
                </span>
                <span className="font-bold uppercase text-sm">
                  {move.type}
                </span>
              </div>
              <span className="text-lg">
                {getOutcomeIcon(move.expectedOutcome)}
              </span>
            </div>
            
            <h3 className="font-semibold mb-2">{move.description}</h3>
            
            <div className={`inline-block px-2 py-1 rounded text-xs font-medium ${getRiskColor(move.riskLevel)} mb-3`}>
              {move.riskLevel.toUpperCase()}
            </div>
            
            <div className="text-sm text-gray-600 bg-gray-50 p-2 rounded">
              <span className="font-medium">💡 </span>
              {move.strategyHint}
            </div>
          </div>
        ))}
      </div>
      
      <button
        onClick={onSubmit}
        disabled={!selectedMove || loading}
        className={`w-full py-3 px-6 rounded-lg font-bold text-white transition-colors ${
          !selectedMove || loading
            ? 'bg-gray-300 cursor-not-allowed'
            : 'bg-primary-600 hover:bg-primary-700'
        }`}
      >
        {loading ? '제출 중...' : '선택한 Move 제출하기'}
      </button>
    </div>
  );
}
