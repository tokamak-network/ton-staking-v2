'use client';

import { useMemo } from 'react';
import { Address } from 'viem';
import { useMultipleStakeInfo } from '@/hooks/useStaking';

export type FilterTab = 'all' | 'active' | 'pending';

interface UseFilteredSequencersResult {
  filteredSequencers: Address[];
  isLoading: boolean;
}

export function useFilteredSequencers(
  sequencers: readonly Address[],
  filterTab: FilterTab,
  userAddress: Address | undefined
): UseFilteredSequencersResult {
  const { data: stakeInfos, isLoading } = useMultipleStakeInfo(userAddress, sequencers);

  const filteredSequencers = useMemo(() => {
    // Return empty if no user or no sequencers
    if (!userAddress || sequencers.length === 0) {
      return [];
    }

    // If 'all' filter or no stake data yet, return all sequencers
    if (filterTab === 'all') {
      return [...sequencers];
    }

    // Wait for stake info to be loaded for filtering
    if (!stakeInfos) {
      return [];
    }

    return sequencers.filter((_, index) => {
      const info = stakeInfos[index];
      if (!info) return false;

      switch (filterTab) {
        case 'active':
          return info.amount > 0n;
        case 'pending':
          return info.unstakeAmount > 0n;
        default:
          return true;
      }
    });
  }, [sequencers, filterTab, userAddress, stakeInfos]);

  return {
    filteredSequencers,
    isLoading,
  };
}
