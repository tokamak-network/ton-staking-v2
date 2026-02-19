interface RewardPanelProps {
  reward: any;
  userAddress: string;
}

export default function RewardPanel({ reward, userAddress }: RewardPanelProps) {
  if (!reward) {
    return null;
  }

  const isUserWinner = reward.winner?.toLowerCase() === userAddress.toLowerCase();

  return (
    <div className="bg-white rounded-lg shadow p-6">
      <h2 className="text-xl font-bold mb-4">🎁 보상 분배</h2>
      
      {isUserWinner ? (
        <div className="bg-green-50 border-green-200 rounded-lg p-6 text-center">
          <div className="text-6xl mb-4">🎉</div>
          <h3 className="text-2xl font-bold text-green-800 mb-2">
            축하합니다! 승리하셨습니다!
          </h3>
          <p className="text-green-700">
            보상: {reward.rewardAmount} WTON
          </p>
        </div>
      ) : (
        <div className="bg-red-50 border-red-200 rounded-lg p-6 text-center">
          <div className="text-6xl mb-4">😢</div>
          <h3 className="text-2xl font-bold text-red-800 mb-2">
            아쉽네요...
          </h3>
          <p className="text-red-700">
            승자: {reward.winner?.slice(0, 10)}...
          </p>
        </div>
      )}
      
      {reward.slashedAddresses && reward.slashedAddresses.length > 0 && (
        <div className="mt-4 p-4 bg-orange-50 rounded-lg">
          <h4 className="font-semibold mb-2">슬래싱된 계정:</h4>
          <div className="space-y-2">
            {reward.slashedAddresses.map((addr: string, i: number) => (
              <div key={i} className="text-sm font-mono">
                {addr.slice(0, 10)}... - {reward.slashedAmounts[i]} WTON
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
