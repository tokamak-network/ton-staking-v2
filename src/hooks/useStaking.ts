'use client';

import { useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { useChainId, useAccount } from 'wagmi';
import { DELEGATE_STAKING_ABI, ERC20_ABI } from '@/lib/contracts/abi';
import { getAddresses } from '@/lib/contracts/addresses';
import { Address } from 'viem';

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
