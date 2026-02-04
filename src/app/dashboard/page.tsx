'use client';

import { useAccount } from 'wagmi';
import { useSequencerList, useStakeInfo, usePendingRewards, useTonBalance, useUserStakingStats } from '@/hooks/useStaking';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { formatTON, formatWTON, formatAddress } from '@/lib/utils';
import { Skeleton } from '@/components/ui/skeleton';
import { Wallet, Coins, Gift, Clock } from 'lucide-react';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { Address } from 'viem';
import { StakeModal } from '@/components/features/staking/StakeModal';
import { UnstakeModal } from '@/components/features/staking/UnstakeModal';
import { useUIStore } from '@/stores/ui';
import Link from 'next/link';

function StakePositionCard({ sequencer, userAddress }: { sequencer: Address; userAddress: Address }) {
  const { data: stakeInfo } = useStakeInfo(userAddress, sequencer);
  const { data: pendingRewards } = usePendingRewards(userAddress, sequencer);
  const { openStakeModal, openUnstakeModal } = useUIStore();

  // Show card even if no stake, so user can stake
  const hasStake = stakeInfo && stakeInfo.amount > 0n;

  return (
    <Card className="bg-slate-900/50 border-slate-800">
      <CardContent className="p-4">
        <div className="flex items-center justify-between mb-3">
          <Link href={`/sequencers/${sequencer}`} className="font-mono text-sm text-slate-400 hover:text-white">
            {formatAddress(sequencer)}
          </Link>
          {hasStake ? (
            <span className="px-2 py-0.5 rounded-full text-xs bg-green-500/20 text-green-400">Staked</span>
          ) : (
            <span className="px-2 py-0.5 rounded-full text-xs bg-slate-500/20 text-slate-400">Not Staked</span>
          )}
        </div>
        <div className="grid grid-cols-4 gap-4">
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
          </div>
          <div className="flex items-center gap-2">
            <Button size="sm" variant="gradient" onClick={() => openStakeModal(sequencer)}>
              Stake
            </Button>
            {hasStake && (
              <Button size="sm" variant="outline" onClick={() => openUnstakeModal(sequencer)}>
                Unstake
              </Button>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

export default function DashboardPage() {
  const { address, isConnected } = useAccount();
  const { data: sequencers, isLoading } = useSequencerList();
  const { data: tonBalance } = useTonBalance(address);
  const { totalStaked, totalPendingUnstake, totalRewards } = useUserStakingStats(address, sequencers);

  if (!isConnected) {
    return (
      <div className="flex flex-col items-center justify-center py-20">
        <Wallet className="h-16 w-16 text-slate-600 mb-4" />
        <h2 className="text-2xl font-bold text-white mb-2">Connect Your Wallet</h2>
        <p className="text-slate-400 mb-6">Connect your wallet to view your staking dashboard</p>
        <ConnectButton />
      </div>
    );
  }

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold text-white mb-2">My Dashboard</h1>
        <p className="text-slate-400">Manage your staking positions and rewards</p>
      </div>

      {/* Overview Stats */}
      <div className="grid md:grid-cols-4 gap-4">
        <Card className="bg-slate-900/50 border-slate-800">
          <CardContent className="p-6">
            <div className="flex items-center gap-3 mb-2">
              <div className="h-10 w-10 rounded-lg bg-tokamak-blue/20 flex items-center justify-center">
                <Wallet className="h-5 w-5 text-tokamak-blue" />
              </div>
              <p className="text-slate-400 text-sm">TON Balance</p>
            </div>
            <p className="text-2xl font-bold text-white">
              {tonBalance ? formatTON(tonBalance) : '0'}
            </p>
          </CardContent>
        </Card>

        <Card className="bg-slate-900/50 border-slate-800">
          <CardContent className="p-6">
            <div className="flex items-center gap-3 mb-2">
              <div className="h-10 w-10 rounded-lg bg-green-500/20 flex items-center justify-center">
                <Coins className="h-5 w-5 text-green-500" />
              </div>
              <p className="text-slate-400 text-sm">Total Staked</p>
            </div>
            <p className="text-2xl font-bold text-white">
              {formatTON(totalStaked)} TON
            </p>
          </CardContent>
        </Card>

        <Card className="bg-slate-900/50 border-slate-800">
          <CardContent className="p-6">
            <div className="flex items-center gap-3 mb-2">
              <div className="h-10 w-10 rounded-lg bg-tokamak-cyan/20 flex items-center justify-center">
                <Gift className="h-5 w-5 text-tokamak-cyan" />
              </div>
              <p className="text-slate-400 text-sm">Claimable Rewards</p>
            </div>
            <p className="text-2xl font-bold text-tokamak-cyan">
              {formatWTON(totalRewards)} WTON
            </p>
          </CardContent>
        </Card>

        <Card className="bg-slate-900/50 border-slate-800">
          <CardContent className="p-6">
            <div className="flex items-center gap-3 mb-2">
              <div className="h-10 w-10 rounded-lg bg-yellow-500/20 flex items-center justify-center">
                <Clock className="h-5 w-5 text-yellow-500" />
              </div>
              <p className="text-slate-400 text-sm">Pending Unstake</p>
            </div>
            <p className="text-2xl font-bold text-white">
              {formatTON(totalPendingUnstake)} TON
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Staking Positions */}
      <Card className="bg-slate-900/50 border-slate-800">
        <CardHeader>
          <CardTitle className="text-white">Staking Positions</CardTitle>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="space-y-4">
              {[...Array(3)].map((_, i) => (
                <Skeleton key={i} className="h-24 w-full" />
              ))}
            </div>
          ) : sequencers && sequencers.length > 0 ? (
            <div className="space-y-4">
              {sequencers.map((seq) => (
                <StakePositionCard
                  key={seq}
                  sequencer={seq as Address}
                  userAddress={address!}
                />
              ))}
            </div>
          ) : (
            <div className="text-center py-8">
              <p className="text-slate-400 mb-4">You don&apos;t have any staking positions yet.</p>
              <Button variant="gradient" asChild>
                <a href="/sequencers">Explore Sequencers</a>
              </Button>
            </div>
          )}
        </CardContent>
      </Card>

      <StakeModal />
      <UnstakeModal />
    </div>
  );
}
