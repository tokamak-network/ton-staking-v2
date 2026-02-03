'use client';

import { useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { DELEGATE_STAKING_ABI } from '@/lib/contracts/abi';
import { useStakingContract } from './useStaking';
import { Address } from 'viem';

export function useRegisterSequencer() {
  const address = useStakingContract();
  const { writeContract, data: hash, isPending, error } = useWriteContract();

  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const register = (layer2: Address, operatorManager: Address, commission: bigint) => {
    writeContract({
      address,
      abi: DELEGATE_STAKING_ABI,
      functionName: 'registerSequencer',
      args: [layer2, operatorManager, commission],
    });
  };

  return { register, isPending, isConfirming, isSuccess, error, hash };
}

export function useSetAutoTrigger() {
  const address = useStakingContract();
  const { writeContract, data: hash, isPending, error } = useWriteContract();

  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const setAutoTrigger = (enabled: boolean) => {
    writeContract({
      address,
      abi: DELEGATE_STAKING_ABI,
      functionName: 'setAutoTrigger',
      args: [enabled],
    });
  };

  return { setAutoTrigger, isPending, isConfirming, isSuccess, error, hash };
}

export function useDeregisterSequencer() {
  const address = useStakingContract();
  const { writeContract, data: hash, isPending, error } = useWriteContract();

  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const deregister = () => {
    writeContract({
      address,
      abi: DELEGATE_STAKING_ABI,
      functionName: 'deregisterSequencer',
    });
  };

  return { deregister, isPending, isConfirming, isSuccess, error, hash };
}

export function useUpdateCommission() {
  const address = useStakingContract();
  const { writeContract, data: hash, isPending, error } = useWriteContract();

  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const updateCommission = (newCommission: bigint) => {
    writeContract({
      address,
      abi: DELEGATE_STAKING_ABI,
      functionName: 'updateCommission',
      args: [newCommission],
    });
  };

  return { updateCommission, isPending, isConfirming, isSuccess, error, hash };
}

export function useClaimCommission() {
  const address = useStakingContract();
  const { writeContract, data: hash, isPending, error } = useWriteContract();

  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const claimCommission = () => {
    writeContract({
      address,
      abi: DELEGATE_STAKING_ABI,
      functionName: 'claimCommission',
    });
  };

  return { claimCommission, isPending, isConfirming, isSuccess, error, hash };
}
