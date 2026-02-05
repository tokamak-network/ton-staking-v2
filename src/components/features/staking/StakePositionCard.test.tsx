import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

// Mock the hooks before importing the component
const mockOpenWithdrawModal = vi.fn();
const mockOpenStakeModal = vi.fn();
const mockOpenUnstakeModal = vi.fn();
const mockOpenClaimModal = vi.fn();
const mockOpenRedelegateModal = vi.fn();

vi.mock('@/stores/ui', () => ({
  useUIStore: () => ({
    openStakeModal: mockOpenStakeModal,
    openUnstakeModal: mockOpenUnstakeModal,
    openClaimModal: mockOpenClaimModal,
    openWithdrawModal: mockOpenWithdrawModal,
    openRedelegateModal: mockOpenRedelegateModal,
  }),
}));

vi.mock('@/hooks/useStaking', () => ({
  useStakeInfo: vi.fn(),
  usePendingRewards: vi.fn(),
  useUnbondingPeriod: vi.fn(),
}));

vi.mock('wagmi', () => ({
  useAccount: () => ({ address: '0x1234567890123456789012345678901234567890' }),
}));

vi.mock('next/link', () => ({
  default: ({ children, href }: { children: React.ReactNode; href: string }) => (
    <a href={href}>{children}</a>
  ),
}));

import { useStakeInfo, usePendingRewards, useUnbondingPeriod } from '@/hooks/useStaking';
import { StakePositionCard } from './StakePositionCard';

const mockUseStakeInfo = vi.mocked(useStakeInfo);
const mockUsePendingRewards = vi.mocked(usePendingRewards);
const mockUseUnbondingPeriod = vi.mocked(useUnbondingPeriod);

const TEST_SEQUENCER = '0xabcdef1234567890123456789012345678901234' as const;
const TEST_USER = '0x1234567890123456789012345678901234567890' as const;

// 7 days in seconds
const UNBONDING_PERIOD = 7n * 24n * 60n * 60n;

describe('StakePositionCard - Withdraw Button', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockUseUnbondingPeriod.mockReturnValue({ data: UNBONDING_PERIOD } as ReturnType<typeof useUnbondingPeriod>);
  });

  describe('Withdraw button visibility', () => {
    it('should NOT show Withdraw button when there is no pending unstake', () => {
      mockUseStakeInfo.mockReturnValue({
        data: [1000n * 10n ** 18n, 0n, 0n, 0n], // [amount, rewardDebt, unstakeAmount=0, unstakeTime]
      } as ReturnType<typeof useStakeInfo>);
      mockUsePendingRewards.mockReturnValue({ data: 0n } as ReturnType<typeof usePendingRewards>);

      render(<StakePositionCard sequencer={TEST_SEQUENCER} userAddress={TEST_USER} />);

      expect(screen.queryByRole('button', { name: /withdraw/i })).not.toBeInTheDocument();
    });

    it('should show Withdraw button when there is pending unstake (even during unbonding)', () => {
      const futureUnstakeTime = BigInt(Math.floor(Date.now() / 1000)); // Just started unstaking
      mockUseStakeInfo.mockReturnValue({
        data: [1000n * 10n ** 18n, 0n, 500n * 10n ** 18n, futureUnstakeTime],
      } as ReturnType<typeof useStakeInfo>);
      mockUsePendingRewards.mockReturnValue({ data: 0n } as ReturnType<typeof usePendingRewards>);

      render(<StakePositionCard sequencer={TEST_SEQUENCER} userAddress={TEST_USER} />);

      expect(screen.getByRole('button', { name: /withdraw/i })).toBeInTheDocument();
    });

    it('should show Withdraw button when unbonding period is complete', () => {
      const pastUnstakeTime = BigInt(Math.floor(Date.now() / 1000) - 8 * 24 * 60 * 60); // 8 days ago
      mockUseStakeInfo.mockReturnValue({
        data: [0n, 0n, 500n * 10n ** 18n, pastUnstakeTime],
      } as ReturnType<typeof useStakeInfo>);
      mockUsePendingRewards.mockReturnValue({ data: 0n } as ReturnType<typeof usePendingRewards>);

      render(<StakePositionCard sequencer={TEST_SEQUENCER} userAddress={TEST_USER} />);

      expect(screen.getByRole('button', { name: /withdraw/i })).toBeInTheDocument();
    });
  });

  describe('Withdraw button state', () => {
    it('should disable Withdraw button when unbonding period is NOT complete', () => {
      const recentUnstakeTime = BigInt(Math.floor(Date.now() / 1000)); // Just now
      mockUseStakeInfo.mockReturnValue({
        data: [1000n * 10n ** 18n, 0n, 500n * 10n ** 18n, recentUnstakeTime],
      } as ReturnType<typeof useStakeInfo>);
      mockUsePendingRewards.mockReturnValue({ data: 0n } as ReturnType<typeof usePendingRewards>);

      render(<StakePositionCard sequencer={TEST_SEQUENCER} userAddress={TEST_USER} />);

      const withdrawButton = screen.getByRole('button', { name: /withdraw/i });
      expect(withdrawButton).toBeDisabled();
    });

    it('should enable Withdraw button when unbonding period is complete', () => {
      const pastUnstakeTime = BigInt(Math.floor(Date.now() / 1000) - 8 * 24 * 60 * 60); // 8 days ago
      mockUseStakeInfo.mockReturnValue({
        data: [0n, 0n, 500n * 10n ** 18n, pastUnstakeTime],
      } as ReturnType<typeof useStakeInfo>);
      mockUsePendingRewards.mockReturnValue({ data: 0n } as ReturnType<typeof usePendingRewards>);

      render(<StakePositionCard sequencer={TEST_SEQUENCER} userAddress={TEST_USER} />);

      const withdrawButton = screen.getByRole('button', { name: /withdraw/i });
      expect(withdrawButton).toBeEnabled();
    });

    it('should call openWithdrawModal when enabled Withdraw button is clicked', async () => {
      const user = userEvent.setup();
      const pastUnstakeTime = BigInt(Math.floor(Date.now() / 1000) - 8 * 24 * 60 * 60);
      mockUseStakeInfo.mockReturnValue({
        data: [0n, 0n, 500n * 10n ** 18n, pastUnstakeTime],
      } as ReturnType<typeof useStakeInfo>);
      mockUsePendingRewards.mockReturnValue({ data: 0n } as ReturnType<typeof usePendingRewards>);

      render(<StakePositionCard sequencer={TEST_SEQUENCER} userAddress={TEST_USER} />);

      const withdrawButton = screen.getByRole('button', { name: /withdraw/i });
      await user.click(withdrawButton);

      expect(mockOpenWithdrawModal).toHaveBeenCalledWith(TEST_SEQUENCER);
    });

    it('should NOT call openWithdrawModal when disabled Withdraw button is clicked', async () => {
      const user = userEvent.setup();
      const recentUnstakeTime = BigInt(Math.floor(Date.now() / 1000));
      mockUseStakeInfo.mockReturnValue({
        data: [1000n * 10n ** 18n, 0n, 500n * 10n ** 18n, recentUnstakeTime],
      } as ReturnType<typeof useStakeInfo>);
      mockUsePendingRewards.mockReturnValue({ data: 0n } as ReturnType<typeof usePendingRewards>);

      render(<StakePositionCard sequencer={TEST_SEQUENCER} userAddress={TEST_USER} />);

      const withdrawButton = screen.getByRole('button', { name: /withdraw/i });
      await user.click(withdrawButton);

      expect(mockOpenWithdrawModal).not.toHaveBeenCalled();
    });
  });

  describe('Countdown display', () => {
    it('should show countdown when unbonding period is in progress', () => {
      const recentUnstakeTime = BigInt(Math.floor(Date.now() / 1000)); // Just started
      mockUseStakeInfo.mockReturnValue({
        data: [1000n * 10n ** 18n, 0n, 500n * 10n ** 18n, recentUnstakeTime],
      } as ReturnType<typeof useStakeInfo>);
      mockUsePendingRewards.mockReturnValue({ data: 0n } as ReturnType<typeof usePendingRewards>);

      render(<StakePositionCard sequencer={TEST_SEQUENCER} userAddress={TEST_USER} />);

      // Should show some time remaining (6d or 7d depending on timing)
      expect(screen.getByText(/\d+[dhms]/i)).toBeInTheDocument();
    });

    it('should show "Ready to withdraw" when unbonding period is complete', () => {
      const pastUnstakeTime = BigInt(Math.floor(Date.now() / 1000) - 8 * 24 * 60 * 60);
      mockUseStakeInfo.mockReturnValue({
        data: [0n, 0n, 500n * 10n ** 18n, pastUnstakeTime],
      } as ReturnType<typeof useStakeInfo>);
      mockUsePendingRewards.mockReturnValue({ data: 0n } as ReturnType<typeof usePendingRewards>);

      render(<StakePositionCard sequencer={TEST_SEQUENCER} userAddress={TEST_USER} />);

      expect(screen.getByText(/ready to withdraw/i)).toBeInTheDocument();
    });
  });
});
