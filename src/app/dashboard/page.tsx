'use client';

import { useState } from 'react';
import { useAccount } from 'wagmi';
import { useSequencerList, useTonBalance, useUserStakingStats } from '@/hooks/useStaking';
import { useFilteredSequencers, FilterTab } from '@/hooks/useFilteredSequencers';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { formatTON, formatWTON } from '@/lib/utils';
import { Skeleton } from '@/components/ui/skeleton';
import { Wallet, Coins, Gift, Clock } from 'lucide-react';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { Address } from 'viem';
import { StakeModal } from '@/components/features/staking/StakeModal';
import { UnstakeModal } from '@/components/features/staking/UnstakeModal';
import { ClaimRewardsModal } from '@/components/features/staking/ClaimRewardsModal';
import { WithdrawModal } from '@/components/features/staking/WithdrawModal';
import { RedelegateModal } from '@/components/features/staking/RedelegateModal';
import { StakePositionCard } from '@/components/features/staking/StakePositionCard';

export default function DashboardPage() {
  const { address, isConnected } = useAccount();
  const { data: sequencers, isLoading: isLoadingSequencers } = useSequencerList();
  const { data: tonBalance } = useTonBalance(address);
  const { totalStaked, totalPendingUnstake, totalRewards } = useUserStakingStats(address, sequencers);
  const [filterTab, setFilterTab] = useState<FilterTab>('all');

  // Convert sequencers to Address[] for the filter hook
  const sequencerAddresses = (sequencers || []) as Address[];
  const { filteredSequencers, isLoading: isLoadingFilter } = useFilteredSequencers(
    sequencerAddresses,
    filterTab,
    address
  );

  const isLoading = isLoadingSequencers || (filterTab !== 'all' && isLoadingFilter);

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
          <div className="flex items-center justify-between">
            <CardTitle className="text-white">Staking Positions</CardTitle>
            <div className="flex gap-2">
              <button
                onClick={() => setFilterTab('all')}
                className={`px-3 py-1 rounded-full text-sm ${filterTab === 'all' ? 'bg-tokamak-blue text-white' : 'bg-slate-800 text-slate-400 hover:text-white'}`}
              >
                All
              </button>
              <button
                onClick={() => setFilterTab('active')}
                className={`px-3 py-1 rounded-full text-sm ${filterTab === 'active' ? 'bg-tokamak-blue text-white' : 'bg-slate-800 text-slate-400 hover:text-white'}`}
              >
                Active
              </button>
              <button
                onClick={() => setFilterTab('pending')}
                className={`px-3 py-1 rounded-full text-sm ${filterTab === 'pending' ? 'bg-tokamak-blue text-white' : 'bg-slate-800 text-slate-400 hover:text-white'}`}
              >
                Pending
              </button>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="space-y-4">
              {[...Array(3)].map((_, i) => (
                <Skeleton key={i} className="h-24 w-full" />
              ))}
            </div>
          ) : filteredSequencers.length > 0 ? (
            <div className="space-y-4">
              {filteredSequencers.map((seq) => (
                <StakePositionCard
                  key={seq}
                  sequencer={seq}
                  userAddress={address!}
                />
              ))}
            </div>
          ) : sequencerAddresses.length > 0 ? (
            <div className="text-center py-8">
              <p className="text-slate-400 mb-4">
                {filterTab === 'active'
                  ? 'No active staking positions.'
                  : filterTab === 'pending'
                  ? 'No pending withdrawals.'
                  : 'No staking positions.'}
              </p>
              <Button variant="outline" onClick={() => setFilterTab('all')}>
                View All Positions
              </Button>
            </div>
          ) : (
            <div className="text-center py-8">
              <p className="text-slate-400 mb-4">No sequencers available.</p>
              <Button variant="gradient" asChild>
                <a href="/sequencers">Explore Sequencers</a>
              </Button>
            </div>
          )}
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
