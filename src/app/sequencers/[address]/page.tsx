'use client';

import { useParams } from 'next/navigation';
import { Address } from 'viem';
import { useMemo } from 'react';
import {
  useSequencerInfo,
  useTotalStaked,
  useStakeInfo,
  usePendingRewards,
  useCheckLayer2Eligibility,
  useEstimateSeigniorage,
  useUnbondingPeriod,
} from '@/hooks/useStaking';
import { useAccount } from 'wagmi';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { useUIStore } from '@/stores/ui';
import { formatAddress, formatTON, formatWTON, formatPercent } from '@/lib/utils';
import { Skeleton } from '@/components/ui/skeleton';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';
import { ArrowLeft, ExternalLink, Copy, TrendingUp, Shield, AlertTriangle, CheckCircle } from 'lucide-react';
import Link from 'next/link';
import { StakeModal } from '@/components/features/staking/StakeModal';
import { UnstakeModal } from '@/components/features/staking/UnstakeModal';
import { ClaimRewardsModal } from '@/components/features/staking/ClaimRewardsModal';
import { WithdrawModal } from '@/components/features/staking/WithdrawModal';
import { RedelegateModal } from '@/components/features/staking/RedelegateModal';
import { UnstakeCountdown } from '@/components/features/staking/UnstakeCountdown';
import { toast } from 'sonner';

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

export default function SequencerDetailPage() {
  const params = useParams();
  const sequencerAddress = params.address as Address;

  const { address: userAddress } = useAccount();
  const { data: info, isLoading } = useSequencerInfo(sequencerAddress);
  const { data: totalStaked } = useTotalStaked();
  const { data: stakeInfoRaw } = useStakeInfo(userAddress, sequencerAddress);
  const { data: pendingRewards } = usePendingRewards(userAddress, sequencerAddress);
  const { data: unbondingPeriod } = useUnbondingPeriod();

  const stakeInfo = useMemo(() => normalizeStakeInfo(stakeInfoRaw), [stakeInfoRaw]);

  // Economics data
  const { data: eligibility } = useCheckLayer2Eligibility(info?.layer2);
  const { data: estimatedRewards } = useEstimateSeigniorage(sequencerAddress);

  const { openStakeModal, openUnstakeModal, openClaimModal, openWithdrawModal, openRedelegateModal } = useUIStore();

  const copyAddress = () => {
    navigator.clipboard.writeText(sequencerAddress);
    toast.success('Address copied to clipboard');
  };

  // Check conditions
  const hasStake = stakeInfo && stakeInfo.amount > 0n;
  const hasPendingUnstake = stakeInfo && stakeInfo.unstakeAmount > 0n;
  const hasRewards = pendingRewards && pendingRewards > 0n;
  const now = BigInt(Math.floor(Date.now() / 1000));
  const canWithdraw = stakeInfo && unbondingPeriod && stakeInfo.unstakeAmount > 0n &&
    (stakeInfo.unstakeTime + unbondingPeriod <= now);

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-8 w-48" />
        <Skeleton className="h-64 w-full" />
      </div>
    );
  }

  if (!info || !info.isRegistered) {
    return (
      <div className="text-center py-12">
        <p className="text-slate-400">Sequencer not found</p>
        <Link href="/sequencers">
          <Button variant="outline" className="mt-4">
            <ArrowLeft className="mr-2 h-4 w-4" />
            Back to Sequencers
          </Button>
        </Link>
      </div>
    );
  }

  const shareOfTotal = totalStaked && totalStaked > 0n
    ? (Number(info.totalStaked) / Number(totalStaked) * 100).toFixed(2)
    : '0';

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Link href="/sequencers">
            <Button variant="ghost" size="icon">
              <ArrowLeft className="h-5 w-5" />
            </Button>
          </Link>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-2xl font-bold text-white font-mono">
                {formatAddress(sequencerAddress, 6)}
              </h1>
              <button onClick={copyAddress} className="text-slate-400 hover:text-white">
                <Copy className="h-4 w-4" />
              </button>
            </div>
            <p className="text-slate-400 text-sm">Sequencer Details</p>
          </div>
        </div>
        <span className="px-3 py-1 rounded-full text-sm bg-green-500/20 text-green-400">
          Active
        </span>
      </div>

      {/* Stats Grid */}
      <div className="grid md:grid-cols-4 gap-4">
        <Card className="bg-slate-900/50 border-slate-800">
          <CardContent className="p-6">
            <p className="text-slate-400 text-sm mb-1">Total Staked</p>
            <p className="text-2xl font-bold text-white">{formatTON(info.totalStaked)}</p>
            <p className="text-xs text-slate-500">TON</p>
          </CardContent>
        </Card>

        <Card className="bg-slate-900/50 border-slate-800">
          <CardContent className="p-6">
            <p className="text-slate-400 text-sm mb-1">Commission</p>
            <p className="text-2xl font-bold text-white">{formatPercent(Number(info.commission))}</p>
          </CardContent>
        </Card>

        <Card className="bg-slate-900/50 border-slate-800">
          <CardContent className="p-6">
            <p className="text-slate-400 text-sm mb-1">Share of Total</p>
            <p className="text-2xl font-bold text-white">{shareOfTotal}%</p>
          </CardContent>
        </Card>

        <Card className="bg-slate-900/50 border-slate-800">
          <CardContent className="p-6">
            <p className="text-slate-400 text-sm mb-1">Layer2 Address</p>
            <p className="text-sm font-mono text-white truncate">{formatAddress(info.layer2, 6)}</p>
            <a
              href={`https://etherscan.io/address/${info.layer2}`}
              target="_blank"
              rel="noopener noreferrer"
              className="text-xs text-tokamak-blue hover:underline inline-flex items-center gap-1 mt-1"
            >
              View on Etherscan
              <ExternalLink className="h-3 w-3" />
            </a>
          </CardContent>
        </Card>
      </div>

      {/* User Position */}
      <Card className="bg-slate-900/50 border-slate-800">
        <CardHeader>
          <CardTitle className="text-white">Your Position</CardTitle>
        </CardHeader>
        <CardContent>
          {userAddress ? (
            <div className="space-y-4">
              <div className="grid md:grid-cols-4 gap-6">
                <div>
                  <p className="text-slate-400 text-sm mb-1">Staked Amount</p>
                  <p className="text-xl font-bold text-white">
                    {stakeInfo ? formatTON(stakeInfo.amount) : '0'} TON
                  </p>
                </div>
                <div>
                  <p className="text-slate-400 text-sm mb-1">Pending Rewards</p>
                  <p className="text-xl font-bold text-tokamak-cyan">
                    {pendingRewards ? formatWTON(pendingRewards) : '0'} WTON
                  </p>
                </div>
                <div>
                  <p className="text-slate-400 text-sm mb-1">Pending Unstake</p>
                  <p className="text-xl font-bold text-white">
                    {stakeInfo ? formatTON(stakeInfo.unstakeAmount) : '0'} TON
                  </p>
                  {hasPendingUnstake && unbondingPeriod && stakeInfo && (
                    <UnstakeCountdown unstakeTime={stakeInfo.unstakeTime} unbondingPeriod={unbondingPeriod} />
                  )}
                </div>
                <div className="flex items-end gap-1.5 flex-nowrap pr-4">
                  <Button
                    variant="gradient"
                    onClick={() => openStakeModal(sequencerAddress)}
                  >
                    Stake
                  </Button>
                  <Button
                    variant="outline"
                    onClick={() => openUnstakeModal(sequencerAddress)}
                    disabled={!hasStake}
                  >
                    Unstake
                  </Button>
                  {hasStake && (
                    <Button
                      variant="outline"
                      onClick={() => openRedelegateModal(sequencerAddress)}
                    >
                      Redelegate
                    </Button>
                  )}
                  {hasRewards && (
                    <Button
                      variant="outline"
                      className="text-tokamak-cyan border-tokamak-cyan/50"
                      onClick={() => openClaimModal(sequencerAddress)}
                    >
                      Claim
                    </Button>
                  )}
                  {hasPendingUnstake && (
                    <TooltipProvider>
                      <Tooltip>
                        <TooltipTrigger asChild>
                          <span>
                            <Button
                              variant={canWithdraw ? 'gradient' : 'outline'}
                              onClick={() => canWithdraw && openWithdrawModal(sequencerAddress)}
                              disabled={!canWithdraw}
                              className={!canWithdraw ? 'opacity-60 cursor-not-allowed' : ''}
                            >
                              Withdraw
                            </Button>
                          </span>
                        </TooltipTrigger>
                        <TooltipContent>
                          <p>
                            {canWithdraw
                              ? 'Ready to withdraw'
                              : stakeInfo && unbondingPeriod
                              ? `Available at: ${new Date(Number(stakeInfo.unstakeTime + unbondingPeriod) * 1000).toLocaleString()}`
                              : 'Calculating...'}
                          </p>
                        </TooltipContent>
                      </Tooltip>
                    </TooltipProvider>
                  )}
                </div>
              </div>
            </div>
          ) : (
            <div className="text-center py-6">
              <p className="text-slate-400 mb-4">Connect your wallet to view your position and stake</p>
              <Button variant="gradient" onClick={() => openStakeModal(sequencerAddress)}>
                Connect & Stake
              </Button>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Economics & Saturation Info */}
      <Card className="bg-slate-900/50 border-slate-800">
        <CardHeader>
          <CardTitle className="text-white flex items-center gap-2">
            <TrendingUp className="h-5 w-5 text-tokamak-cyan" />
            Economics & Rewards
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-6">
          {/* Eligibility Status */}
          <div className="p-4 rounded-lg bg-slate-800/50 border border-slate-700">
            <div className="flex items-center gap-3 mb-3">
              {eligibility?.[0] ? (
                <CheckCircle className="h-5 w-5 text-green-400" />
              ) : (
                <AlertTriangle className="h-5 w-5 text-yellow-400" />
              )}
              <h3 className="text-white font-medium">L2 Eligibility Status</h3>
            </div>
            <div className="grid md:grid-cols-3 gap-4">
              <div>
                <p className="text-xs text-slate-400 mb-1">Status</p>
                <p className={`text-sm font-medium ${eligibility?.[0] ? 'text-green-400' : 'text-yellow-400'}`}>
                  {eligibility?.[0] ? 'Eligible for Rewards' : 'Not Eligible'}
                </p>
              </div>
              <div>
                <p className="text-xs text-slate-400 mb-1">Required Stake (theta x Bridged TON)</p>
                <p className="text-sm font-medium text-white">
                  {eligibility?.[1] ? formatTON(eligibility[1]) : '---'} TON
                </p>
              </div>
              <div>
                <p className="text-xs text-slate-400 mb-1">Current Stake</p>
                <p className="text-sm font-medium text-white">
                  {eligibility?.[2] ? formatTON(eligibility[2]) : '---'} TON
                </p>
              </div>
            </div>
            {eligibility && !eligibility[0] && eligibility[1] > 0n && (
              <div className="mt-3 p-2 rounded bg-yellow-500/10 border border-yellow-500/20">
                <p className="text-xs text-yellow-200">
                  This sequencer needs {formatTON(eligibility[1] - eligibility[2])} more TON staked to become eligible for seigniorage rewards.
                </p>
              </div>
            )}
          </div>

          {/* Estimated Rewards */}
          <div className="grid md:grid-cols-2 gap-4">
            <div className="p-4 rounded-lg bg-slate-800/50 border border-slate-700">
              <div className="flex items-center gap-2 mb-3">
                <Shield className="h-4 w-4 text-tokamak-blue" />
                <h3 className="text-white font-medium text-sm">Estimated Seigniorage</h3>
              </div>
              <div className="space-y-3">
                <div>
                  <p className="text-xs text-slate-400 mb-1">Sequencer Reward (for delegators)</p>
                  <p className="text-lg font-bold text-tokamak-cyan">
                    {estimatedRewards ? formatWTON(estimatedRewards[0]) : '0'} WTON
                  </p>
                </div>
                <div>
                  <p className="text-xs text-slate-400 mb-1">Validator Reward</p>
                  <p className="text-lg font-bold text-white">
                    {estimatedRewards ? formatWTON(estimatedRewards[1]) : '0'} WTON
                  </p>
                </div>
                {userAddress && stakeInfo && stakeInfo.amount > 0n && (
                  <div className="pt-3 border-t border-slate-700">
                    <p className="text-xs text-slate-400 mb-1">Your Estimated Reward</p>
                    <p className="text-lg font-bold text-green-400">
                      {estimatedRewards && info?.totalStaked && info.totalStaked > 0n
                        ? formatWTON((estimatedRewards[0] * stakeInfo.amount) / info.totalStaked)
                        : '0'} WTON
                    </p>
                    <p className="text-xs text-slate-500 mt-1">
                      Your share: {info?.totalStaked && info.totalStaked > 0n
                        ? (Number(stakeInfo.amount) / Number(info.totalStaked) * 100).toFixed(2)
                        : '0'}%
                    </p>
                  </div>
                )}
              </div>
            </div>

            <div className="p-4 rounded-lg bg-slate-800/50 border border-slate-700">
              <h3 className="text-white font-medium text-sm mb-3">Reward Distribution</h3>
              <div className="space-y-3">
                <div>
                  <div className="flex justify-between text-xs mb-1">
                    <span className="text-slate-400">Delegators</span>
                    <span className="text-white">{100 - Number(info?.commission || 0) / 100}%</span>
                  </div>
                  <div className="h-2 bg-slate-700 rounded-full overflow-hidden">
                    <div
                      className="h-full bg-gradient-to-r from-tokamak-blue to-tokamak-cyan"
                      style={{ width: `${100 - Number(info?.commission || 0) / 100}%` }}
                    />
                  </div>
                </div>
                <div>
                  <div className="flex justify-between text-xs mb-1">
                    <span className="text-slate-400">Sequencer Commission</span>
                    <span className="text-white">{formatPercent(Number(info?.commission || 0))}</span>
                  </div>
                  <div className="h-2 bg-slate-700 rounded-full overflow-hidden">
                    <div
                      className="h-full bg-purple-500"
                      style={{ width: `${Number(info?.commission || 0) / 100}%` }}
                    />
                  </div>
                </div>
              </div>
              <p className="text-xs text-slate-500 mt-3">
                * Based on Hyperbolic Saturation Function (Economics Whitepaper V2)
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* All Modals */}
      <StakeModal />
      <UnstakeModal />
      <ClaimRewardsModal />
      <WithdrawModal />
      <RedelegateModal />
    </div>
  );
}
