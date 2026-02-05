import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook, waitFor } from '@testing-library/react';
import { Address } from 'viem';

// Mock the useStaking hooks
const mockStakeInfoResults = new Map<string, { amount: bigint; unstakeAmount: bigint }>();

vi.mock('@/hooks/useStaking', () => ({
  useMultipleStakeInfo: vi.fn((userAddress: Address | undefined, sequencers: Address[]) => {
    if (!userAddress || !sequencers.length) {
      return { data: undefined, isLoading: false };
    }

    const results = sequencers.map(seq => {
      const key = `${userAddress}-${seq}`;
      return mockStakeInfoResults.get(key) || { amount: 0n, unstakeAmount: 0n };
    });

    return { data: results, isLoading: false };
  }),
}));

import { useFilteredSequencers, FilterTab } from './useFilteredSequencers';

const TEST_USER = '0x1234567890123456789012345678901234567890' as Address;
const SEQUENCER_1 = '0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' as Address;
const SEQUENCER_2 = '0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb' as Address;
const SEQUENCER_3 = '0xcccccccccccccccccccccccccccccccccccccccc' as Address;

describe('useFilteredSequencers', () => {
  beforeEach(() => {
    mockStakeInfoResults.clear();
    vi.clearAllMocks();
  });

  describe('All filter', () => {
    it('should return only sequencers with stake or pending unstake when filter is "all"', () => {
      const sequencers = [SEQUENCER_1, SEQUENCER_2, SEQUENCER_3];

      // Set up stake info: seq1 has stake, seq2 has pending, seq3 has nothing
      mockStakeInfoResults.set(`${TEST_USER}-${SEQUENCER_1}`, { amount: 1000n, unstakeAmount: 0n });
      mockStakeInfoResults.set(`${TEST_USER}-${SEQUENCER_2}`, { amount: 0n, unstakeAmount: 500n });
      mockStakeInfoResults.set(`${TEST_USER}-${SEQUENCER_3}`, { amount: 0n, unstakeAmount: 0n });

      const { result } = renderHook(() =>
        useFilteredSequencers(sequencers, 'all', TEST_USER)
      );

      // seq3 should be excluded because it has no stake and no pending unstake
      expect(result.current.filteredSequencers).toHaveLength(2);
      expect(result.current.filteredSequencers).toContain(SEQUENCER_1);
      expect(result.current.filteredSequencers).toContain(SEQUENCER_2);
      expect(result.current.filteredSequencers).not.toContain(SEQUENCER_3);
    });

    it('should return empty array when no sequencers have positions', () => {
      const sequencers = [SEQUENCER_1, SEQUENCER_2];

      // No stakes or pending unstakes
      mockStakeInfoResults.set(`${TEST_USER}-${SEQUENCER_1}`, { amount: 0n, unstakeAmount: 0n });
      mockStakeInfoResults.set(`${TEST_USER}-${SEQUENCER_2}`, { amount: 0n, unstakeAmount: 0n });

      const { result } = renderHook(() =>
        useFilteredSequencers(sequencers, 'all', TEST_USER)
      );

      expect(result.current.filteredSequencers).toHaveLength(0);
    });
  });

  describe('Active filter', () => {
    it('should return only sequencers with staked amount > 0 when filter is "active"', () => {
      const sequencers = [SEQUENCER_1, SEQUENCER_2, SEQUENCER_3];

      // seq1: has stake, seq2: pending only, seq3: nothing
      mockStakeInfoResults.set(`${TEST_USER}-${SEQUENCER_1}`, { amount: 1000n, unstakeAmount: 0n });
      mockStakeInfoResults.set(`${TEST_USER}-${SEQUENCER_2}`, { amount: 0n, unstakeAmount: 500n });
      mockStakeInfoResults.set(`${TEST_USER}-${SEQUENCER_3}`, { amount: 0n, unstakeAmount: 0n });

      const { result } = renderHook(() =>
        useFilteredSequencers(sequencers, 'active', TEST_USER)
      );

      expect(result.current.filteredSequencers).toHaveLength(1);
      expect(result.current.filteredSequencers).toContain(SEQUENCER_1);
    });

    it('should return empty array when no sequencers have active stakes', () => {
      const sequencers = [SEQUENCER_1, SEQUENCER_2];

      mockStakeInfoResults.set(`${TEST_USER}-${SEQUENCER_1}`, { amount: 0n, unstakeAmount: 500n });
      mockStakeInfoResults.set(`${TEST_USER}-${SEQUENCER_2}`, { amount: 0n, unstakeAmount: 0n });

      const { result } = renderHook(() =>
        useFilteredSequencers(sequencers, 'active', TEST_USER)
      );

      expect(result.current.filteredSequencers).toHaveLength(0);
    });
  });

  describe('Pending filter', () => {
    it('should return only sequencers with pending unstake > 0 when filter is "pending"', () => {
      const sequencers = [SEQUENCER_1, SEQUENCER_2, SEQUENCER_3];

      // seq1: has stake only, seq2: pending only, seq3: both
      mockStakeInfoResults.set(`${TEST_USER}-${SEQUENCER_1}`, { amount: 1000n, unstakeAmount: 0n });
      mockStakeInfoResults.set(`${TEST_USER}-${SEQUENCER_2}`, { amount: 0n, unstakeAmount: 500n });
      mockStakeInfoResults.set(`${TEST_USER}-${SEQUENCER_3}`, { amount: 200n, unstakeAmount: 300n });

      const { result } = renderHook(() =>
        useFilteredSequencers(sequencers, 'pending', TEST_USER)
      );

      expect(result.current.filteredSequencers).toHaveLength(2);
      expect(result.current.filteredSequencers).toContain(SEQUENCER_2);
      expect(result.current.filteredSequencers).toContain(SEQUENCER_3);
    });

    it('should return empty array when no sequencers have pending unstakes', () => {
      const sequencers = [SEQUENCER_1, SEQUENCER_2];

      mockStakeInfoResults.set(`${TEST_USER}-${SEQUENCER_1}`, { amount: 1000n, unstakeAmount: 0n });
      mockStakeInfoResults.set(`${TEST_USER}-${SEQUENCER_2}`, { amount: 500n, unstakeAmount: 0n });

      const { result } = renderHook(() =>
        useFilteredSequencers(sequencers, 'pending', TEST_USER)
      );

      expect(result.current.filteredSequencers).toHaveLength(0);
    });
  });

  describe('Edge cases', () => {
    it('should return empty array when sequencers list is empty', () => {
      const { result } = renderHook(() =>
        useFilteredSequencers([], 'all', TEST_USER)
      );

      expect(result.current.filteredSequencers).toHaveLength(0);
    });

    it('should return empty array when user address is undefined', () => {
      const sequencers = [SEQUENCER_1, SEQUENCER_2];

      const { result } = renderHook(() =>
        useFilteredSequencers(sequencers, 'all', undefined)
      );

      expect(result.current.filteredSequencers).toHaveLength(0);
    });

    it('should handle sequencers with both active stake and pending unstake', () => {
      const sequencers = [SEQUENCER_1];

      // Sequencer has both stake and pending unstake
      mockStakeInfoResults.set(`${TEST_USER}-${SEQUENCER_1}`, { amount: 1000n, unstakeAmount: 500n });

      // Should appear in both 'active' and 'pending' filters
      const { result: activeResult } = renderHook(() =>
        useFilteredSequencers(sequencers, 'active', TEST_USER)
      );
      const { result: pendingResult } = renderHook(() =>
        useFilteredSequencers(sequencers, 'pending', TEST_USER)
      );

      expect(activeResult.current.filteredSequencers).toContain(SEQUENCER_1);
      expect(pendingResult.current.filteredSequencers).toContain(SEQUENCER_1);
    });
  });
});
