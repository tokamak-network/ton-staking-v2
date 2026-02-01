'use client';

import { useParams } from 'next/navigation';
import { Address } from 'viem';
import { useSequencerInfo, useTotalStaked, useStakeInfo, usePendingRewards } from '@/hooks/useStaking';
import { useAccount } from 'wagmi';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { useUIStore } from '@/stores/ui';
import { formatAddress, formatTON, formatWTON, formatPercent } from '@/lib/utils';
import { Skeleton } from '@/components/ui/skeleton';
import { ArrowLeft, ExternalLink, Copy } from 'lucide-react';
import Link from 'next/link';
import { StakeModal } from '@/components/features/staking/StakeModal';
import { UnstakeModal } from '@/components/features/staking/UnstakeModal';
import { toast } from 'sonner';

export default function SequencerDetailPage() {
  const params = useParams();
  const sequencerAddress = params.address as Address;

  const { address: userAddress } = useAccount();
  const { data: info, isLoading } = useSequencerInfo(sequencerAddress);
  const { data: totalStaked } = useTotalStaked();
  const { data: stakeInfo } = useStakeInfo(userAddress, sequencerAddress);
  const { data: pendingRewards } = usePendingRewards(userAddress, sequencerAddress);

  const { openStakeModal, openUnstakeModal } = useUIStore();

  const copyAddress = () => {
    navigator.clipboard.writeText(sequencerAddress);
    toast.success('Address copied to clipboard');
  };

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
      {userAddress && (
        <Card className="bg-slate-900/50 border-slate-800">
          <CardHeader>
            <CardTitle className="text-white">Your Position</CardTitle>
          </CardHeader>
          <CardContent>
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
              </div>
              <div className="flex items-end gap-2">
                <Button
                  variant="gradient"
                  onClick={() => openStakeModal(sequencerAddress)}
                >
                  Stake
                </Button>
                <Button
                  variant="outline"
                  onClick={() => openUnstakeModal(sequencerAddress)}
                  disabled={!stakeInfo || stakeInfo.amount === 0n}
                >
                  Unstake
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Stake/Unstake Modals */}
      <StakeModal />
      <UnstakeModal />
    </div>
  );
}
