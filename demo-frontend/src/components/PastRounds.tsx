import { useReadContracts } from 'wagmi'
import { LOTTERY_CANDIDATE_ABI } from '../contracts/abi'
import { formatUnits } from 'viem'

interface Props {
  lotteryCandidateAddress: `0x${string}`
}

export function PastRounds({ lotteryCandidateAddress }: Props) {
  const { data: currentRoundData } = useReadContracts({
    contracts: [
      {
        address: lotteryCandidateAddress,
        abi: LOTTERY_CANDIDATE_ABI,
        functionName: 'currentRound',
      },
    ],
  })

  const currentRound = currentRoundData?.[0]?.result as bigint | undefined
  const pastRounds = currentRound && currentRound > 1n
    ? Array.from({ length: Number(currentRound) - 1 }, (_, i) => BigInt(i + 1))
    : []

  const { data: roundsData } = useReadContracts({
    contracts: pastRounds.flatMap((round) => [
      {
        address: lotteryCandidateAddress,
        abi: LOTTERY_CANDIDATE_ABI,
        functionName: 'roundWinner',
        args: [round],
      },
      {
        address: lotteryCandidateAddress,
        abi: LOTTERY_CANDIDATE_ABI,
        functionName: 'roundPrizePool',
        args: [round],
      },
      {
        address: lotteryCandidateAddress,
        abi: LOTTERY_CANDIDATE_ABI,
        functionName: 'getRoundParticipantCount',
        args: [round],
      },
    ]),
  })

  const { refetch: refetchCurrentRound } = useReadContracts({
    contracts: [
      {
        address: lotteryCandidateAddress,
        abi: LOTTERY_CANDIDATE_ABI,
        functionName: 'currentRound',
      },
    ],
  })

  const { refetch: refetchRoundsData } = useReadContracts({
    contracts: pastRounds.flatMap((round) => [
      {
        address: lotteryCandidateAddress,
        abi: LOTTERY_CANDIDATE_ABI,
        functionName: 'roundWinner',
        args: [round],
      },
      {
        address: lotteryCandidateAddress,
        abi: LOTTERY_CANDIDATE_ABI,
        functionName: 'roundPrizePool',
        args: [round],
      },
      {
        address: lotteryCandidateAddress,
        abi: LOTTERY_CANDIDATE_ABI,
        functionName: 'getRoundParticipantCount',
        args: [round],
      },
    ]),
  })

  const handleRefresh = () => {
    refetchCurrentRound()
    refetchRoundsData()
  }

  if (!pastRounds.length) {
    return (
      <div className="bg-white rounded-xl shadow-lg p-6">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-2xl font-bold text-gray-800">📜 Past Rounds</h2>
          <button
            onClick={handleRefresh}
            className="px-3 py-1 bg-gray-100 rounded-lg hover:bg-gray-200 text-sm"
          >
            🔄 Refresh
          </button>
        </div>
        <p className="text-gray-500 text-center py-8">No completed rounds yet</p>
      </div>
    )
  }

  const formatWTON = (value: bigint | undefined) => {
    if (!value) return '0'
    return Number(formatUnits(value, 27)).toFixed(2)
  }

  return (
    <div className="bg-white rounded-xl shadow-lg p-6">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-2xl font-bold text-gray-800">📜 Past Rounds</h2>
        <button
          onClick={handleRefresh}
          className="px-3 py-1 bg-gray-100 rounded-lg hover:bg-gray-200 text-sm"
        >
          🔄 Refresh
        </button>
      </div>

      <div className="space-y-3">
        {pastRounds.map((round, index) => {
          const baseIdx = index * 3
          const winner = roundsData?.[baseIdx]?.result as `0x${string}` | undefined
          const prizePool = roundsData?.[baseIdx + 1]?.result as bigint | undefined
          const participants = roundsData?.[baseIdx + 2]?.result as bigint | undefined

          return (
            <div
              key={round.toString()}
              className="p-4 bg-gradient-to-r from-gray-50 to-gray-100 rounded-lg"
            >
              <div className="flex justify-between items-center">
                <span className="font-bold text-gray-700">Round #{round.toString()}</span>
                <span className="text-sm text-gray-500">
                  {participants?.toString() ?? '0'} participants
                </span>
              </div>
              <div className="mt-2 flex justify-between items-center">
                <div className="text-sm">
                  <span className="text-gray-600">Winner: </span>
                  <span className="font-mono text-green-600">
                    {winner ? `${winner.slice(0, 8)}...${winner.slice(-6)}` : '-'}
                  </span>
                </div>
                <div className="text-sm font-bold text-yellow-600">
                  🏆 {formatWTON(prizePool)} WTON
                </div>
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
