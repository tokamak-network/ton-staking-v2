import { useState } from 'react'
import { useAccount, useWriteContract, useWaitForTransactionReceipt, useReadContracts, usePublicClient } from 'wagmi'
import { LOTTERY_CANDIDATE_ABI } from '../contracts/abi'
import { formatUnits } from 'viem'

interface Props {
  lotteryCandidateAddress: `0x${string}`
}

export function SeignioragePanel({ lotteryCandidateAddress }: Props) {
  const { address, isConnected } = useAccount()
  const [prevBalance, setPrevBalance] = useState<bigint | null>(null)
  const [seigniorageReceived, setSeigniorageReceived] = useState<bigint | null>(null)
  const [currentBlock, setCurrentBlock] = useState<bigint | null>(null)
  const [isAdvancing, setIsAdvancing] = useState(false)
  const [blocksToAdvance, setBlocksToAdvance] = useState('100')
  const publicClient = usePublicClient()

  const { data, refetch } = useReadContracts({
    contracts: [
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
        functionName: 'getDepositors',
      },
      ...(address
        ? [
            {
              address: lotteryCandidateAddress,
              abi: LOTTERY_CANDIDATE_ABI,
              functionName: 'balanceOf',
              args: [address],
            },
          ]
        : []),
    ],
  })

  const totalDeposited = data?.[0]?.result as bigint | undefined
  const depositorCount = data?.[1]?.result as bigint | undefined
  const depositors = data?.[2]?.result as `0x${string}`[] | undefined
  const userBalance = data?.[3]?.result as bigint | undefined

  const { writeContract: updateSeigniorage, data: updateHash } = useWriteContract()

  const { isLoading: isUpdating, isSuccess: updateSuccess } = useWaitForTransactionReceipt({
    hash: updateHash,
  })

  const handleUpdateSeigniorage = () => {
    if (userBalance) {
      setPrevBalance(userBalance)
    }
    updateSeigniorage({
      address: lotteryCandidateAddress,
      abi: LOTTERY_CANDIDATE_ABI,
      functionName: 'updateSeigniorage',
    })
  }

  if (updateSuccess && prevBalance && userBalance && userBalance > prevBalance) {
    if (seigniorageReceived !== userBalance - prevBalance) {
      setSeigniorageReceived(userBalance - prevBalance)
    }
  }

  const formatWTON = (value: bigint | undefined) => {
    if (!value) return '0'
    return Number(formatUnits(value, 27)).toFixed(4)
  }

  const fetchBlockNumber = async () => {
    if (publicClient) {
      const blockNum = await publicClient.getBlockNumber()
      setCurrentBlock(blockNum)
    }
  }

  const handleAdvanceBlocks = async () => {
    const numBlocks = parseInt(blocksToAdvance)
    if (isNaN(numBlocks) || numBlocks <= 0) return

    setIsAdvancing(true)
    try {
      for (let i = 0; i < numBlocks; i++) {
        await fetch('http://localhost:8545', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            jsonrpc: '2.0',
            method: 'evm_mine',
            params: [],
            id: i + 1,
          }),
        })
      }
      await fetchBlockNumber()
      await refetch()
    } catch (error) {
      console.error('Failed to advance blocks:', error)
    } finally {
      setIsAdvancing(false)
    }
  }

  useState(() => {
    fetchBlockNumber()
  })

  if (!isConnected) return null

  return (
    <div className="bg-white rounded-xl shadow-lg p-6">
      <h2 className="text-2xl font-bold text-gray-800 mb-4">📈 Seigniorage Distribution</h2>

      <div className="space-y-4">
        <div className="p-4 bg-gradient-to-r from-green-50 to-emerald-100 rounded-lg">
          <p className="text-sm text-gray-600 mb-2">Total Deposited (Pool)</p>
          <p className="text-2xl font-bold text-green-700">
            {formatWTON(totalDeposited)} WTON
          </p>
          <p className="text-sm text-gray-500 mt-1">
            {depositorCount?.toString() ?? '0'} depositors
          </p>
        </div>

        {userBalance && totalDeposited && totalDeposited > 0n && (
          <div className="p-4 bg-gradient-to-r from-blue-50 to-blue-100 rounded-lg">
            <p className="text-sm text-gray-600 mb-2">Your Share</p>
            <div className="flex justify-between items-center">
              <p className="text-xl font-bold text-blue-700">
                {((Number(userBalance) / Number(totalDeposited)) * 100).toFixed(2)}%
              </p>
              <p className="text-sm text-gray-500">
                ({formatWTON(userBalance)} WTON)
              </p>
            </div>
          </div>
        )}

        <button
          onClick={handleUpdateSeigniorage}
          disabled={isUpdating}
          className={`w-full py-4 rounded-lg font-bold text-white transition-all ${
            isUpdating
              ? 'bg-gray-400 cursor-not-allowed'
              : 'bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700'
          }`}
        >
          {isUpdating ? '⏳ Updating...' : '💰 Claim Seigniorage'}
        </button>

        {updateSuccess && (
          <div className="p-4 bg-green-50 rounded-lg border border-green-200">
            <p className="text-green-700 font-medium">✅ Seigniorage Updated!</p>
            {seigniorageReceived && seigniorageReceived > 0n && (
              <p className="text-green-600 text-sm mt-1">
                You received: +{formatWTON(seigniorageReceived)} WTON
              </p>
            )}
          </div>
        )}

        <div className="p-4 bg-gray-50 rounded-lg">
          <p className="text-sm text-gray-600 mb-2">How it works:</p>
          <ul className="text-xs text-gray-500 space-y-1">
            <li>• Seigniorage is generated each block</li>
            <li>• Distributed proportionally to depositors</li>
            <li>• Call "Claim Seigniorage" to trigger distribution</li>
          </ul>
        </div>

        {depositors && depositors.length > 0 && (
          <div className="p-4 bg-gray-50 rounded-lg">
            <p className="text-sm text-gray-600 mb-2">Depositors ({depositors.length})</p>
            <div className="space-y-1 max-h-32 overflow-y-auto">
              {depositors.map((depositor, i) => (
                <div
                  key={depositor}
                  className={`text-xs font-mono ${
                    depositor.toLowerCase() === address?.toLowerCase()
                      ? 'text-blue-600 font-bold'
                      : 'text-gray-500'
                  }`}
                >
                  {i + 1}. {depositor.slice(0, 10)}...{depositor.slice(-8)}
                  {depositor.toLowerCase() === address?.toLowerCase() && ' (You)'}
                </div>
              ))}
            </div>
          </div>
        )}

        <button
          onClick={() => refetch()}
          className="w-full py-2 bg-gray-100 rounded-lg hover:bg-gray-200 text-sm"
        >
          🔄 Refresh Data
        </button>

        <div className="p-4 bg-orange-50 rounded-lg border border-orange-200">
          <p className="text-sm font-medium text-orange-700 mb-2">⚡ Dev Tools: Advance Blocks</p>
          <p className="text-xs text-orange-600 mb-3">
            Block #{currentBlock?.toString() ?? '...'} - Mine blocks to generate seigniorage
          </p>
          <div className="flex gap-2">
            <input
              type="number"
              value={blocksToAdvance}
              onChange={(e) => setBlocksToAdvance(e.target.value)}
              min="1"
              max="1000"
              className="flex-1 px-3 py-2 border border-orange-300 rounded-lg text-sm"
              placeholder="Blocks"
            />
            <button
              onClick={handleAdvanceBlocks}
              disabled={isAdvancing}
              className={`px-4 py-2 rounded-lg font-medium text-white text-sm ${
                isAdvancing
                  ? 'bg-gray-400 cursor-not-allowed'
                  : 'bg-orange-500 hover:bg-orange-600'
              }`}
            >
              {isAdvancing ? '⏳' : '⛏️ Mine'}
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
