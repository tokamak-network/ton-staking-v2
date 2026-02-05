'use client';

import Link from 'next/link';
import { Address } from 'viem';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';
import { useStakeInfo, usePendingRewards, useUnbondingPeriod } from '@/hooks/useStaking';
import { useUIStore } from '@/stores/ui';
import { formatTON, formatWTON, formatAddress } from '@/lib/utils';
import { UnstakeCountdown } from './UnstakeCountdown';

// Helper to normalize stakeInfo from tuple or object format
function normalizeStakeInfo(data: unknown): { amount: bigint; unstakeAmount: bigint; unstakeTime: bigint } | null {
  if (!data) return null;
  if (Array.isArray(data)) {
    // Tuple format: [amount, rewardDebt, unstakeAmount, unstakeTime]
    return { amount: data[0] as bigint, unstakeAmount: data[2] as bigint, unstakeTime: data[3] as bigint };
  }
  // Object format with named properties
  const obj = data as { amount?: bigint; unstakeAmount?: bigint; unstakeTime?: bigint };
  return { amount: obj.amount || 0n, unstakeAmount: obj.unstakeAmount || 0n, unstakeTime: obj.unstakeTime || 0n };
}

interface StakePositionCardProps {
  sequencer: Address;
  userAddress: Address;
}

export function StakePositionCard({ sequencer, userAddress }: StakePositionCardProps) {
  const { data: stakeInfoRaw } = useStakeInfo(userAddress, sequencer);
  const { data: pendingRewards } = usePendingRewards(userAddress, sequencer);
  const { data: unbondingPeriod } = useUnbondingPeriod();
  const { openStakeModal, openUnstakeModal, openClaimModal, openWithdrawModal, openRedelegateModal } = useUIStore();

  const stakeInfo = normalizeStakeInfo(stakeInfoRaw);
  const hasStake = stakeInfo && stakeInfo.amount > 0n;
  const hasPendingUnstake = stakeInfo && stakeInfo.unstakeAmount > 0n;
  const hasRewards = pendingRewards && pendingRewards > 0n;

  // Check if withdraw is available (unbonding period complete)
  const now = BigInt(Math.floor(Date.now() / 1000));
  const canWithdraw = stakeInfo && unbondingPeriod && stakeInfo.unstakeAmount > 0n &&
    (stakeInfo.unstakeTime + unbondingPeriod <= now);

  // Format the withdraw available time for tooltip
  const getWithdrawTimeTooltip = (): string => {
    if (!stakeInfo || !unbondingPeriod || stakeInfo.unstakeAmount === 0n) {
      return '';
    }
    const withdrawTime = stakeInfo.unstakeTime + unbondingPeriod;
    const withdrawDate = new Date(Number(withdrawTime) * 1000);
    return `Available at: ${withdrawDate.toLocaleString()}`;
  };

  return (
    <Card className="bg-slate-900/50 border-slate-800">
      <CardContent className="p-4">
        <div className="flex items-center justify-between mb-3">
          <Link href={`/sequencers/${sequencer}`} className="font-mono text-sm text-slate-400 hover:text-white">
            {formatAddress(sequencer)}
          </Link>
          {hasStake ? (
            <span className="px-2 py-0.5 rounded-full text-xs bg-green-500/20 text-green-400">Staked</span>
          ) : hasPendingUnstake ? (
            <span className="px-2 py-0.5 rounded-full text-xs bg-yellow-500/20 text-yellow-400">Pending</span>
          ) : (
            <span className="px-2 py-0.5 rounded-full text-xs bg-slate-500/20 text-slate-400">Not Staked</span>
          )}
        </div>

        <div className="flex flex-col md:flex-row md:items-center gap-4 mb-4">
          <div className="grid grid-cols-3 gap-4 flex-1">
            <div>
              <p className="text-xs text-slate-400">Staked</p>
              <p className="text-sm font-medium text-white">
                {stakeInfo ? formatTON(stakeInfo.amount) : '0'} TON
              </p>
            </div>
            <div>
              <p className="text-xs text-slate-400">Rewards</p>
              <p className="text-sm font-medium text-tokamak-cyan">
                {pendingRewards ? formatWTON(pendingRewards) : '0'} WTON
              </p>
            </div>
            <div>
              <p className="text-xs text-slate-400">Pending Unstake</p>
              <p className="text-sm font-medium text-white">
                {stakeInfo ? formatTON(stakeInfo.unstakeAmount) : '0'} TON
              </p>
              {hasPendingUnstake && unbondingPeriod && stakeInfo && (
                <UnstakeCountdown unstakeTime={stakeInfo.unstakeTime} unbondingPeriod={unbondingPeriod} />
              )}
            </div>
          </div>
          <div className="flex items-center gap-1.5 flex-nowrap flex-shrink-0">
            <Button size="sm" variant="gradient" onClick={() => openStakeModal(sequencer)}>
              Stake
            </Button>
            {hasStake && (
              <>
                <Button size="sm" variant="outline" onClick={() => openUnstakeModal(sequencer)}>
                  Unstake
                </Button>
                <Button size="sm" variant="outline" onClick={() => openRedelegateModal(sequencer)}>
                  Redelegate
                </Button>
              </>
            )}
            {hasRewards && (
              <Button size="sm" variant="outline" className="text-tokamak-cyan border-tokamak-cyan/50" onClick={() => openClaimModal(sequencer)}>
                Claim
              </Button>
            )}
            {hasPendingUnstake && (
              <TooltipProvider>
                <Tooltip>
                  <TooltipTrigger asChild>
                    <span>
                      <Button
                        size="sm"
                        variant={canWithdraw ? 'gradient' : 'outline'}
                        onClick={() => canWithdraw && openWithdrawModal(sequencer)}
                        disabled={!canWithdraw}
                        className={!canWithdraw ? 'opacity-60 cursor-not-allowed' : ''}
                      >
                        Withdraw
                      </Button>
                    </span>
                  </TooltipTrigger>
                  <TooltipContent>
                    <p>{canWithdraw ? 'Ready to withdraw' : getWithdrawTimeTooltip()}</p>
                  </TooltipContent>
                </Tooltip>
              </TooltipProvider>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
