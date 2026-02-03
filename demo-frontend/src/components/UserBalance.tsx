import { useAccount, useReadContracts } from 'wagmi'
import { LOTTERY_CANDIDATE_ABI, ERC20_ABI } from '../contracts/abi'
import { formatUnits } from 'viem'

interface Props {
  tonAddress: `0x${string}`
  wtonAddress: `0x${string}`
  lotteryCandidateAddress: `0x${string}`
}

export function UserBalance({
  tonAddress,
  wtonAddress,
  lotteryCandidateAddress,
}: Props) {
  const { address, isConnected } = useAccount()

  const { data, isLoading, refetch } = useReadContracts({
    contracts: address
      ? [
          {
            address: tonAddress,
            abi: ERC20_ABI,
            functionName: 'balanceOf',
            args: [address],
          },
          {
            address: wtonAddress,
            abi: ERC20_ABI,
            functionName: 'balanceOf',
            args: [address],
          },
          {
            address: lotteryCandidateAddress,
            abi: LOTTERY_CANDIDATE_ABI,
            functionName: 'balanceOf',
            args: [address],
          },
        ]
      : [],
  })

  if (!isConnected) {
    return (
      <div className="bg-gray-100 rounded-xl p-6 text-center text-gray-500">
        Connect wallet to see your balance
      </div>
    )
  }

  if (isLoading) {
    return <div className="animate-pulse bg-gray-200 h-32 rounded-lg" />
  }

  const tonBalance = data?.[0]?.result as bigint | undefined
  const wtonBalance = data?.[1]?.result as bigint | undefined
  const depositedBalance = data?.[2]?.result as bigint | undefined

  return (
    <div className="bg-white rounded-xl shadow-lg p-6">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-2xl font-bold text-gray-800">💰 Your Balance</h2>
        <button
          onClick={() => refetch()}
          className="px-3 py-1 bg-gray-100 rounded-lg hover:bg-gray-200 text-sm"
        >
          Refresh
        </button>
      </div>

      <div className="space-y-3">
        <div className="flex justify-between items-center p-3 bg-gray-50 rounded-lg">
          <span className="text-gray-600">TON (Wallet)</span>
          <span className="font-mono font-bold">
            {tonBalance ? Number(formatUnits(tonBalance, 18)).toFixed(4) : '0'} TON
          </span>
        </div>

        <div className="flex justify-between items-center p-3 bg-gray-50 rounded-lg">
          <span className="text-gray-600">WTON (Wallet)</span>
          <span className="font-mono font-bold">
            {wtonBalance ? Number(formatUnits(wtonBalance, 27)).toFixed(4) : '0'} WTON
          </span>
        </div>

        <div className="flex justify-between items-center p-3 bg-gradient-to-r from-blue-50 to-blue-100 rounded-lg border-2 border-blue-200">
          <span className="text-blue-700 font-medium">Deposited in Lottery</span>
          <span className="font-mono font-bold text-blue-700">
            {depositedBalance
              ? Number(formatUnits(depositedBalance, 27)).toFixed(4)
              : '0'}{' '}
            WTON
          </span>
        </div>
      </div>
    </div>
  )
}
