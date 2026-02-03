import { useState, useEffect, useRef } from 'react'
import { useAccount, useWriteContract, useWaitForTransactionReceipt, useReadContract } from 'wagmi'
import { parseUnits } from 'viem'
import { ERC20_ABI, LOTTERY_CANDIDATE_ABI } from '../contracts/abi'

interface Props {
  tonAddress: `0x${string}`
  lotteryCandidateAddress: `0x${string}`
}

export function DepositForm({ tonAddress, lotteryCandidateAddress }: Props) {
  const { address, isConnected } = useAccount()
  const [amount, setAmount] = useState('')
  const [step, setStep] = useState<'idle' | 'approving' | 'depositing'>('idle')
  const depositTriggeredRef = useRef(false)

  const { data: allowance } = useReadContract({
    address: tonAddress,
    abi: ERC20_ABI,
    functionName: 'allowance',
    args: address ? [address, lotteryCandidateAddress] : undefined,
  })

  const { writeContract: approve, data: approveHash } = useWriteContract()
  const { writeContract: deposit, data: depositHash } = useWriteContract()

  const { isLoading: isApproving, isSuccess: approveSuccess } = useWaitForTransactionReceipt({
    hash: approveHash,
  })

  const { isLoading: isDepositing, isSuccess: depositSuccess } = useWaitForTransactionReceipt({
    hash: depositHash,
  })

  const handleDeposit = async () => {
    if (!amount || !address) return

    const amountWei = parseUnits(amount, 18)
    const currentAllowance = allowance ?? 0n

    if (currentAllowance < amountWei) {
      setStep('approving')
      approve({
        address: tonAddress,
        abi: ERC20_ABI,
        functionName: 'approve',
        args: [lotteryCandidateAddress, amountWei],
      })
    } else {
      setStep('depositing')
      deposit({
        address: lotteryCandidateAddress,
        abi: LOTTERY_CANDIDATE_ABI,
        functionName: 'depositTON',
        args: [amountWei],
      })
    }
  }

  useEffect(() => {
    if (approveSuccess && step === 'approving' && !depositTriggeredRef.current) {
      depositTriggeredRef.current = true
      setStep('depositing')
      const amountWei = parseUnits(amount, 18)
      deposit({
        address: lotteryCandidateAddress,
        abi: LOTTERY_CANDIDATE_ABI,
        functionName: 'depositTON',
        args: [amountWei],
      })
    }
  }, [approveSuccess, step, amount, lotteryCandidateAddress, deposit])

  useEffect(() => {
    if (depositSuccess && step === 'depositing') {
      setStep('idle')
      setAmount('')
      depositTriggeredRef.current = false
    }
  }, [depositSuccess, step])

  if (!isConnected) return null

  const isProcessing = isApproving || isDepositing

  return (
    <div className="bg-white rounded-xl shadow-lg p-6">
      <h2 className="text-2xl font-bold text-gray-800 mb-4">📥 Deposit TON</h2>

      <div className="space-y-4">
        <div>
          <label className="block text-sm text-gray-600 mb-1">Amount (TON)</label>
          <input
            type="number"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="Enter amount"
            className="w-full px-4 py-3 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            disabled={isProcessing}
          />
        </div>

        <div className="flex gap-2">
          {['10', '50', '100'].map((preset) => (
            <button
              key={preset}
              onClick={() => setAmount(preset)}
              className="flex-1 px-3 py-2 bg-gray-100 rounded-lg hover:bg-gray-200"
              disabled={isProcessing}
            >
              {preset} TON
            </button>
          ))}
        </div>

        <button
          onClick={handleDeposit}
          disabled={!amount || isProcessing}
          className={`w-full py-3 rounded-lg font-bold text-white transition-all ${
            isProcessing
              ? 'bg-gray-400 cursor-not-allowed'
              : 'bg-blue-600 hover:bg-blue-700'
          }`}
        >
          {isApproving
            ? 'Approving...'
            : isDepositing
            ? 'Depositing...'
            : 'Deposit'}
        </button>

        {(approveSuccess || depositSuccess) && (
          <p className="text-green-600 text-center text-sm">
            {depositSuccess ? '✅ Deposit successful!' : '✅ Approval successful!'}
          </p>
        )}
      </div>
    </div>
  )
}
