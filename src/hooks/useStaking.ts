'use client';

import { useReadContract, useReadContracts, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { useChainId, useAccount } from 'wagmi';
import { DELEGATE_STAKING_ABI, ERC20_ABI } from '@/lib/contracts/abi';
import { getAddresses } from '@/lib/contracts/addresses';
import { Address } from 'viem';
import { useMemo } from 'react';

export function useStakingContract() {
  const chainId = useChainId();
  const addresses = getAddresses(chainId);
  return addresses.delegateStaking;
}

export function useTotalStaked() {
  const address = useStakingContract();

  return useReadContract({
    address,
    abi: DELEGATE_STAKING_ABI,
    functionName: 'getTotalStaked',
  });
}

export function useSequencerList() {
  const address = useStakingContract();

  return useReadContract({
    address,
    abi: DELEGATE_STAKING_ABI,
    functionName: 'getSequencerList',
  });
}

export function useSequencerInfo(sequencer: Address | undefined) {
  const address = useStakingContract();

  return useReadContract({
    address,
    abi: DELEGATE_STAKING_ABI,
    functionName: 'getSequencerInfo',
    args: sequencer ? [sequencer] : undefined,
    query: { enabled: !!sequencer },
  });
}

export function useStakeInfo(staker: Address | undefined, sequencer: Address | undefined) {
  const address = useStakingContract();

  return useReadContract({
    address,
    abi: DELEGATE_STAKING_ABI,
    functionName: 'getStakeInfo',
    args: staker && sequencer ? [staker, sequencer] : undefined,
    query: { enabled: !!staker && !!sequencer },
  });
}

export function usePendingRewards(staker: Address | undefined, sequencer: Address | undefined) {
  const address = useStakingContract();

  return useReadContract({
    address,
    abi: DELEGATE_STAKING_ABI,
    functionName: 'pendingRewards',
    args: staker && sequencer ? [staker, sequencer] : undefined,
    query: { enabled: !!staker && !!sequencer },
  });
}

export function useUnbondingPeriod() {
  const address = useStakingContract();

  return useReadContract({
    address,
    abi: DELEGATE_STAKING_ABI,
    functionName: 'unbondingPeriod',
  });
}

export function useTonBalance(account: Address | undefined) {
  const chainId = useChainId();
  const addresses = getAddresses(chainId);

  return useReadContract({
    address: addresses.ton,
    abi: ERC20_ABI,
    functionName: 'balanceOf',
    args: account ? [account] : undefined,
    query: { enabled: !!account },
  });
}

export function useTonAllowance(owner: Address | undefined) {
  const chainId = useChainId();
  const addresses = getAddresses(chainId);

  return useReadContract({
    address: addresses.ton,
    abi: ERC20_ABI,
    functionName: 'allowance',
    args: owner ? [owner, addresses.delegateStaking] : undefined,
    query: { enabled: !!owner },
  });
}

export function useStake() {
  const address = useStakingContract();
  const { writeContract, data: hash, isPending, error } = useWriteContract();

  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const stake = (sequencer: Address, amount: bigint) => {
    writeContract({
      address,
      abi: DELEGATE_STAKING_ABI,
      functionName: 'stake',
      args: [sequencer, amount],
    });
  };

  return { stake, isPending, isConfirming, isSuccess, error, hash };
}

export function useUnstake() {
  const address = useStakingContract();
  const { writeContract, data: hash, isPending, error } = useWriteContract();

  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const unstake = (sequencer: Address, amount: bigint) => {
    writeContract({
      address,
      abi: DELEGATE_STAKING_ABI,
      functionName: 'unstake',
      args: [sequencer, amount],
    });
  };

  return { unstake, isPending, isConfirming, isSuccess, error, hash };
}

export function useWithdraw() {
  const address = useStakingContract();
  const { writeContract, data: hash, isPending, error } = useWriteContract();

  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const withdraw = (sequencer: Address) => {
    writeContract({
      address,
      abi: DELEGATE_STAKING_ABI,
      functionName: 'withdraw',
      args: [sequencer],
    });
  };

  return { withdraw, isPending, isConfirming, isSuccess, error, hash };
}

export function useClaimRewards() {
  const address = useStakingContract();
  const { writeContract, data: hash, isPending, error } = useWriteContract();

  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const claimRewards = (sequencer: Address) => {
    writeContract({
      address,
      abi: DELEGATE_STAKING_ABI,
      functionName: 'claimRewards',
      args: [sequencer],
    });
  };

  return { claimRewards, isPending, isConfirming, isSuccess, error, hash };
}

export function useRedelegate() {
  const address = useStakingContract();
  const { writeContract, data: hash, isPending, error } = useWriteContract();

  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const redelegate = (fromSequencer: Address, toSequencer: Address, amount: bigint) => {
    writeContract({
      address,
      abi: DELEGATE_STAKING_ABI,
      functionName: 'redelegate',
      args: [fromSequencer, toSequencer, amount],
    });
  };

  return { redelegate, isPending, isConfirming, isSuccess, error, hash };
}

export function useApproveTon() {
  const chainId = useChainId();
  const addresses = getAddresses(chainId);
  const { writeContract, data: hash, isPending, error } = useWriteContract();

  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const approve = (amount: bigint) => {
    writeContract({
      address: addresses.ton,
      abi: ERC20_ABI,
      functionName: 'approve',
      args: [addresses.delegateStaking, amount],
    });
  };

  return { approve, isPending, isConfirming, isSuccess, error, hash };
}

// V3 Specific Hooks

export function useTriggerSeigniorage() {
  const address = useStakingContract();
  const { writeContract, data: hash, isPending, error } = useWriteContract();

  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const triggerSeigniorage = (sequencer: Address) => {
    writeContract({
      address,
      abi: DELEGATE_STAKING_ABI,
      functionName: 'triggerSeigniorage',
      args: [sequencer],
    });
  };

  return { triggerSeigniorage, isPending, isConfirming, isSuccess, error, hash };
}

export function useEstimateSeigniorage(sequencer: Address | undefined) {
  const address = useStakingContract();

  return useReadContract({
    address,
    abi: DELEGATE_STAKING_ABI,
    functionName: 'estimateSeigniorage',
    args: sequencer ? [sequencer] : undefined,
    query: { enabled: !!sequencer },
  });
}

export function useContractVersion() {
  const address = useStakingContract();

  return useReadContract({
    address,
    abi: DELEGATE_STAKING_ABI,
    functionName: 'version',
  });
}

export function useSequencerCount() {
  const address = useStakingContract();

  return useReadContract({
    address,
    abi: DELEGATE_STAKING_ABI,
    functionName: 'getSequencerCount',
  });
}

export function useCheckLayer2Eligibility(layer2: Address | undefined) {
  const address = useStakingContract();

  return useReadContract({
    address,
    abi: DELEGATE_STAKING_ABI,
    functionName: 'checkLayer2Eligibility',
    args: layer2 ? [layer2] : undefined,
    query: { enabled: !!layer2 },
  });
}

export function useEmergencyWithdraw() {
  const address = useStakingContract();
  const { writeContract, data: hash, isPending, error } = useWriteContract();

  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const emergencyWithdraw = (sequencer: Address) => {
    writeContract({
      address,
      abi: DELEGATE_STAKING_ABI,
      functionName: 'emergencyWithdraw',
      args: [sequencer],
    });
  };

  return { emergencyWithdraw, isPending, isConfirming, isSuccess, error, hash };
}

// Batch hook to get aggregated user stats across all sequencers
export function useUserStakingStats(
  userAddress: Address | undefined,
  sequencers: readonly string[] | undefined
) {
  const stakingContractAddress = useStakingContract();

  // Build contracts array for batch reading stake info
  const stakeInfoContracts = useMemo(() => {
    if (!userAddress || !sequencers || sequencers.length === 0) return [];
    return sequencers.map((seq) => ({
      address: stakingContractAddress,
      abi: DELEGATE_STAKING_ABI,
      functionName: 'getStakeInfo' as const,
      args: [userAddress, seq as Address],
    }));
  }, [userAddress, sequencers, stakingContractAddress]);

  // Build contracts array for batch reading pending rewards
  const rewardsContracts = useMemo(() => {
    if (!userAddress || !sequencers || sequencers.length === 0) return [];
    return sequencers.map((seq) => ({
      address: stakingContractAddress,
      abi: DELEGATE_STAKING_ABI,
      functionName: 'pendingRewards' as const,
      args: [userAddress, seq as Address],
    }));
  }, [userAddress, sequencers, stakingContractAddress]);

  const { data: stakeResults } = useReadContracts({
    contracts: stakeInfoContracts,
    query: { enabled: stakeInfoContracts.length > 0 },
  });

  const { data: rewardsResults } = useReadContracts({
    contracts: rewardsContracts,
    query: { enabled: rewardsContracts.length > 0 },
  });

  // Calculate totals
  const totals = useMemo(() => {
    let totalStaked = 0n;
    let totalPendingUnstake = 0n;
    let totalRewards = 0n;

    if (stakeResults) {
      for (const result of stakeResults) {
        if (result.status === 'success' && result.result) {
          // Handle both array (tuple) and object formats
          const data = result.result as unknown;
          if (Array.isArray(data)) {
            // Tuple format: [amount, rewardDebt, unstakeAmount, unstakeTime]
            const tupleData = data as [bigint, bigint, bigint, bigint];
            totalStaked += tupleData[0] || 0n;
            totalPendingUnstake += tupleData[2] || 0n;
          } else {
            // Object format with named properties
            const objData = data as { amount: bigint; unstakeAmount: bigint };
            totalStaked += objData.amount || 0n;
            totalPendingUnstake += objData.unstakeAmount || 0n;
          }
        }
      }
    }

    if (rewardsResults) {
      for (const result of rewardsResults) {
        if (result.status === 'success' && result.result) {
          totalRewards += result.result as bigint;
        }
      }
    }

    return { totalStaked, totalPendingUnstake, totalRewards };
  }, [stakeResults, rewardsResults]);

  return totals;
}

// Hook to get stake info for multiple sequencers at once
export function useMultipleStakeInfo(
  userAddress: Address | undefined,
  sequencers: readonly Address[]
) {
  const stakingContractAddress = useStakingContract();

  const contracts = useMemo(() => {
    if (!userAddress || sequencers.length === 0) return [];
    return sequencers.map((seq) => ({
      address: stakingContractAddress,
      abi: DELEGATE_STAKING_ABI,
      functionName: 'getStakeInfo' as const,
      args: [userAddress, seq],
    }));
  }, [userAddress, sequencers, stakingContractAddress]);

  const { data: results, isLoading, error } = useReadContracts({
    contracts,
    query: { enabled: contracts.length > 0 },
  });

  // Normalize results to a consistent format
  const normalizedData = useMemo(() => {
    if (!results) return undefined;

    return results.map((result) => {
      if (result.status !== 'success' || !result.result) {
        return { amount: 0n, unstakeAmount: 0n, unstakeTime: 0n };
      }

      const data = result.result as unknown;
      if (Array.isArray(data)) {
        // Tuple format: [amount, rewardDebt, unstakeAmount, unstakeTime]
        const tupleData = data as [bigint, bigint, bigint, bigint];
        return {
          amount: tupleData[0] || 0n,
          unstakeAmount: tupleData[2] || 0n,
          unstakeTime: tupleData[3] || 0n,
        };
      } else {
        // Object format
        const objData = data as { amount?: bigint; unstakeAmount?: bigint; unstakeTime?: bigint };
        return {
          amount: objData.amount || 0n,
          unstakeAmount: objData.unstakeAmount || 0n,
          unstakeTime: objData.unstakeTime || 0n,
        };
      }
    });
  }, [results]);

  return { data: normalizedData, isLoading, error };
}
