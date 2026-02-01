'use client';

import { Address } from 'viem';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { useSequencerInfo } from '@/hooks/useStaking';
import { useUIStore } from '@/stores/ui';
import { formatAddress, formatTON, formatPercent } from '@/lib/utils';
import { Skeleton } from '@/components/ui/skeleton';
import { Users, Percent, Coins } from 'lucide-react';
import Link from 'next/link';

interface SequencerCardProps {
  address: Address;
}

export function SequencerCard({ address }: SequencerCardProps) {
  const { data: info, isLoading } = useSequencerInfo(address);
  const openStakeModal = useUIStore((s) => s.openStakeModal);

  if (isLoading) {
    return (
      <Card className="bg-slate-900/50 border-slate-800">
        <CardContent className="p-6">
          <Skeleton className="h-6 w-32 mb-4" />
          <Skeleton className="h-4 w-full mb-2" />
          <Skeleton className="h-4 w-3/4 mb-4" />
          <Skeleton className="h-10 w-full" />
        </CardContent>
      </Card>
    );
  }

  if (!info || !info.isRegistered) {
    return null;
  }

  return (
    <Card className="bg-slate-900/50 border-slate-800 hover:border-slate-700 transition-colors">
      <CardHeader className="pb-2">
        <div className="flex items-center justify-between">
          <CardTitle className="text-lg text-white font-mono">
            {formatAddress(address)}
          </CardTitle>
          <span className="px-2 py-1 rounded-full text-xs bg-green-500/20 text-green-400">
            Active
          </span>
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="grid grid-cols-2 gap-4">
          <div className="flex items-center gap-2">
            <Coins className="h-4 w-4 text-slate-400" />
            <div>
              <p className="text-xs text-slate-400">Total Staked</p>
              <p className="text-sm font-medium text-white">{formatTON(info.totalStaked)} TON</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <Percent className="h-4 w-4 text-slate-400" />
            <div>
              <p className="text-xs text-slate-400">Commission</p>
              <p className="text-sm font-medium text-white">{formatPercent(Number(info.commission))}</p>
            </div>
          </div>
        </div>

        <div className="flex items-center gap-2 text-sm text-slate-400">
          <span>Layer2:</span>
          <span className="font-mono">{formatAddress(info.layer2)}</span>
        </div>

        <div className="flex gap-2">
          <Link href={`/sequencers/${address}`} className="flex-1">
            <Button variant="outline" className="w-full">
              Details
            </Button>
          </Link>
          <Button variant="gradient" className="flex-1" onClick={() => openStakeModal(address)}>
            Stake
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}
