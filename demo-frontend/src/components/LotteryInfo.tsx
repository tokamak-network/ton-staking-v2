import { useReadContracts, useAccount } from 'wagmi'
import { LOTTERY_CANDIDATE_ABI } from '../contracts/abi'
import { formatUnits } from 'viem'

interface Props {
  lotteryCandidateAddress: `0x${string}`
}

export function LotteryInfo({ lotteryCandidateAddress }: Props) {
  const { address } = useAccount()

  const { data, isLoading, refetch } = useReadContracts({
    contracts: [
      {
        address: lotteryCandidateAddress,
        abi: LOTTERY_CANDIDATE_ABI,
        functionName: 'currentRound',
      },
      {
        address: lotteryCandidateAddress,
        abi: LOTTERY_CANDIDATE_ABI,
        functionName: 'entryFee',
      },
      {
        address: lotteryCandidateAddress,
        abi: LOTTERY_CANDIDATE_ABI,
        functionName: 'totalDeposited',
      },
      {
        address: lotteryCandidateAddress,
        abi: LOTTERY_CANDIDATE_ABI,
        functionName: 'getDepositorCount',
      },
      {
        address: lotteryCandidateAddress,
        abi: LOTTERY_CANDIDATE_ABI,
        functionName: 'candidate',
      },
    ],
  })

  const currentRound = data?.[0]?.result as bigint | undefined
  const entryFee = data?.[1]?.result as bigint | undefined
  const totalDeposited = data?.[2]?.result as bigint | undefined
  const depositorCount = data?.[3]?.result as bigint | undefined
  const operator = data?.[4]?.result as `0x${string}` | undefined

  const { data: roundData } = useReadContracts({
    contracts: currentRound
      ? [
          {
            address: lotteryCandidateAddress,
            abi: LOTTERY_CANDIDATE_ABI,
            functionName: 'roundPrizePool',
            args: [currentRound],
          },
          {
            address: lotteryCandidateAddress,
            abi: LOTTERY_CANDIDATE_ABI,
            functionName: 'getRoundParticipantCount',
            args: [currentRound],
          },
          ...(address
            ? [
                {
                  address: lotteryCandidateAddress,
                  abi: LOTTERY_CANDIDATE_ABI,
                  functionName: 'roundEntered',
                  args: [currentRound, address],
                },
              ]
            : []),
        ]
      : [],
  })

  const prizePool = roundData?.[0]?.result as bigint | undefined
  const participantCount = roundData?.[1]?.result as bigint | undefined
  const hasEntered = roundData?.[2]?.result as boolean | undefined

  if (isLoading) {
    return <div className="animate-pulse bg-gray-200 h-48 rounded-lg" />
  }

  const formatWTON = (value: bigint | undefined) => {
    if (!value) return '0'
    return formatUnits(value, 27)
  }

  const isOperator = address?.toLowerCase() === operator?.toLowerCase()

  return (
    <div className="bg-white rounded-xl shadow-lg p-6">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-2xl font-bold text-gray-800">🎰 Lottery Info</h2>
        <button
          onClick={() => refetch()}
          className="px-3 py-1 bg-gray-100 rounded-lg hover:bg-gray-200 text-sm"
        >
          Refresh
        </button>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="p-4 bg-gradient-to-r from-purple-50 to-purple-100 rounded-lg">
          <p className="text-sm text-gray-600">Current Round</p>
          <p className="text-3xl font-bold text-purple-700">
            #{currentRound?.toString() ?? '-'}
          </p>
        </div>

        <div className="p-4 bg-gradient-to-r from-green-50 to-green-100 rounded-lg">
          <p className="text-sm text-gray-600">Prize Pool</p>
          <p className="text-2xl font-bold text-green-700">
            {Number(formatWTON(prizePool)).toFixed(2)} WTON
          </p>
        </div>

        <div className="p-4 bg-gradient-to-r from-blue-50 to-blue-100 rounded-lg">
          <p className="text-sm text-gray-600">Entry Fee</p>
          <p className="text-xl font-bold text-blue-700">
            {Number(formatWTON(entryFee)).toFixed(0)} TON
          </p>
        </div>

        <div className="p-4 bg-gradient-to-r from-orange-50 to-orange-100 rounded-lg">
          <p className="text-sm text-gray-600">Participants</p>
          <p className="text-2xl font-bold text-orange-700">
            {participantCount?.toString() ?? '0'}
          </p>
        </div>
      </div>

      <div className="mt-4 p-4 bg-gray-50 rounded-lg">
        <div className="flex justify-between">
          <span className="text-sm text-gray-600">Total Deposited:</span>
          <span className="font-mono">
            {Number(formatWTON(totalDeposited)).toFixed(2)} WTON
          </span>
        </div>
        <div className="flex justify-between mt-2">
          <span className="text-sm text-gray-600">Depositors:</span>
          <span className="font-mono">{depositorCount?.toString() ?? '0'}</span>
        </div>
      </div>

      {address && (
        <div className="mt-4 p-4 bg-yellow-50 rounded-lg">
          <p className="text-sm text-gray-600">Your Status</p>
          <div className="flex items-center gap-2 mt-1">
            {hasEntered ? (
              <span className="px-2 py-1 bg-green-100 text-green-700 rounded-full text-sm">
                ✅ Entered
              </span>
            ) : (
              <span className="px-2 py-1 bg-gray-100 text-gray-600 rounded-full text-sm">
                Not Entered
              </span>
            )}
            {isOperator && (
              <span className="px-2 py-1 bg-purple-100 text-purple-700 rounded-full text-sm">
                👑 Operator
              </span>
            )}
          </div>
        </div>
      )}
    </div>
  )
}
