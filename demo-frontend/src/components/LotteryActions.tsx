import { useAccount, useWriteContract, useWaitForTransactionReceipt, useReadContracts } from 'wagmi'
import { LOTTERY_CANDIDATE_ABI } from '../contracts/abi'

interface Props {
  lotteryCandidateAddress: `0x${string}`
  operatorAddress: `0x${string}`
}

export function LotteryActions({ lotteryCandidateAddress, operatorAddress }: Props) {
  const { address, isConnected } = useAccount()

  const { data: lotteryData, refetch } = useReadContracts({
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
        functionName: 'balanceOf',
        args: address ? [address] : undefined,
      },
    ],
  })

  const currentRound = lotteryData?.[0]?.result as bigint | undefined
  const entryFee = lotteryData?.[1]?.result as bigint | undefined
  const userBalance = lotteryData?.[2]?.result as bigint | undefined

  const { data: roundData } = useReadContracts({
    contracts: currentRound && address
      ? [
          {
            address: lotteryCandidateAddress,
            abi: LOTTERY_CANDIDATE_ABI,
            functionName: 'roundEntered',
            args: [currentRound, address],
          },
          {
            address: lotteryCandidateAddress,
            abi: LOTTERY_CANDIDATE_ABI,
            functionName: 'getRoundParticipantCount',
            args: [currentRound],
          },
        ]
      : [],
  })

  const hasEntered = roundData?.[0]?.result as boolean | undefined
  const participantCount = roundData?.[1]?.result as bigint | undefined

  const { writeContract: enterLottery, data: enterHash } = useWriteContract()
  const { writeContract: drawWinner, data: drawHash } = useWriteContract()

  const { isLoading: isEntering, isSuccess: enterSuccess } = useWaitForTransactionReceipt({
    hash: enterHash,
  })

  const { isLoading: isDrawing, isSuccess: drawSuccess } = useWaitForTransactionReceipt({
    hash: drawHash,
  })

  const isOperator = address?.toLowerCase() === operatorAddress?.toLowerCase()
  const canEnter = !hasEntered && userBalance && entryFee && userBalance >= entryFee
  const canDraw = isOperator && participantCount && participantCount > 0n

  const handleEnterLottery = () => {
    enterLottery({
      address: lotteryCandidateAddress,
      abi: LOTTERY_CANDIDATE_ABI,
      functionName: 'enterLottery',
    })
  }

  const handleDrawWinner = () => {
    drawWinner({
      address: lotteryCandidateAddress,
      abi: LOTTERY_CANDIDATE_ABI,
      functionName: 'drawWinner',
    })
  }

  if (!isConnected) return null

  return (
    <div className="bg-white rounded-xl shadow-lg p-6">
      <h2 className="text-2xl font-bold text-gray-800 mb-4">🎯 Lottery Actions</h2>

      <div className="space-y-4">
        <button
          onClick={handleEnterLottery}
          disabled={!canEnter || isEntering}
          className={`w-full py-4 rounded-lg font-bold text-white transition-all ${
            !canEnter || isEntering
              ? 'bg-gray-400 cursor-not-allowed'
              : 'bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700'
          }`}
        >
          {isEntering ? (
            '🎰 Entering...'
          ) : hasEntered ? (
            '✅ Already Entered'
          ) : !userBalance || !entryFee || userBalance < entryFee ? (
            '❌ Insufficient Balance'
          ) : (
            '🎰 Enter Lottery'
          )}
        </button>

        {enterSuccess && (
          <p className="text-green-600 text-center">✅ Successfully entered the lottery!</p>
        )}

        {isOperator && (
          <div className="mt-6 p-4 bg-purple-50 rounded-lg border-2 border-purple-200">
            <h3 className="text-lg font-bold text-purple-700 mb-3">👑 Operator Controls</h3>

            <button
              onClick={handleDrawWinner}
              disabled={!canDraw || isDrawing}
              className={`w-full py-3 rounded-lg font-bold text-white ${
                !canDraw || isDrawing
                  ? 'bg-gray-400 cursor-not-allowed'
                  : 'bg-gradient-to-r from-yellow-500 to-orange-500 hover:from-yellow-600 hover:to-orange-600'
              }`}
            >
              {isDrawing ? '🎲 Drawing...' : '🎲 Draw Winner'}
            </button>

            {!canDraw && participantCount === 0n && (
              <p className="text-sm text-gray-500 mt-2 text-center">
                No participants yet
              </p>
            )}

            {drawSuccess && (
              <p className="text-green-600 text-center mt-2">
                ✅ Winner has been drawn!
              </p>
            )}
          </div>
        )}

        <button
          onClick={() => refetch()}
          className="w-full py-2 bg-gray-100 rounded-lg hover:bg-gray-200 text-sm"
        >
          🔄 Refresh Status
        </button>
      </div>
    </div>
  )
}
