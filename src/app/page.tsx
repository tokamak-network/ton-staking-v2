'use client';

import Link from 'next/link';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { ArrowRight, Shield, Coins, Zap } from 'lucide-react';
import { useTotalStaked, useSequencerList } from '@/hooks/useStaking';
import { formatTON } from '@/lib/utils';

export default function HomePage() {
  const { data: totalStaked, isLoading: isLoadingStaked } = useTotalStaked();
  const { data: sequencers, isLoading: isLoadingSequencers } = useSequencerList();

  const activeSequencers = sequencers?.length || 0;

  return (
    <div className="space-y-16">
      {/* Hero Section */}
      <section className="text-center py-20">
        <h1 className="text-5xl font-bold mb-6 bg-gradient-to-r from-tokamak-blue to-tokamak-cyan bg-clip-text text-transparent">
          Tokamak Delegate Staking
        </h1>
        <p className="text-xl text-slate-400 mb-8 max-w-2xl mx-auto">
          Stake your TON tokens and delegate to trusted sequencers.
          Earn rewards while contributing to Tokamak Network V3 security.
        </p>
        <div className="flex gap-4 justify-center">
          <Link href="/sequencers">
            <Button variant="gradient" size="lg">
              Explore Sequencers
              <ArrowRight className="ml-2 h-5 w-5" />
            </Button>
          </Link>
          <Link href="/dashboard">
            <Button variant="outline" size="lg">
              View Dashboard
            </Button>
          </Link>
        </div>
      </section>

      {/* Features Section */}
      <section className="grid md:grid-cols-3 gap-6">
        <Card className="bg-slate-900/50 border-slate-800">
          <CardHeader>
            <div className="h-12 w-12 rounded-lg bg-tokamak-blue/20 flex items-center justify-center mb-4">
              <Shield className="h-6 w-6 text-tokamak-blue" />
            </div>
            <CardTitle className="text-white">Secure Staking</CardTitle>
          </CardHeader>
          <CardContent className="text-slate-400">
            Your TON tokens are secured in audited smart contracts.
            Delegate with confidence to verified sequencers.
          </CardContent>
        </Card>

        <Card className="bg-slate-900/50 border-slate-800">
          <CardHeader>
            <div className="h-12 w-12 rounded-lg bg-tokamak-cyan/20 flex items-center justify-center mb-4">
              <Coins className="h-6 w-6 text-tokamak-cyan" />
            </div>
            <CardTitle className="text-white">Earn Rewards</CardTitle>
          </CardHeader>
          <CardContent className="text-slate-400">
            Receive WTON rewards from sequencer seigniorage.
            Claim your rewards anytime with no lock-up period.
          </CardContent>
        </Card>

        <Card className="bg-slate-900/50 border-slate-800">
          <CardHeader>
            <div className="h-12 w-12 rounded-lg bg-purple-500/20 flex items-center justify-center mb-4">
              <Zap className="h-6 w-6 text-purple-500" />
            </div>
            <CardTitle className="text-white">Easy Redelegation</CardTitle>
          </CardHeader>
          <CardContent className="text-slate-400">
            Switch between sequencers instantly without unbonding delays.
            Optimize your staking strategy freely.
          </CardContent>
        </Card>
      </section>

      {/* Stats Section */}
      <section className="bg-slate-900/50 rounded-2xl border border-slate-800 p-8">
        <div className="grid md:grid-cols-4 gap-8 text-center">
          <div>
            <p className="text-3xl font-bold text-white">
              {isLoadingStaked ? '---' : totalStaked ? formatTON(totalStaked) : '0'}
            </p>
            <p className="text-slate-400 mt-1">Total Staked (TON)</p>
          </div>
          <div>
            <p className="text-3xl font-bold text-white">
              {isLoadingSequencers ? '---' : activeSequencers}
            </p>
            <p className="text-slate-400 mt-1">Active Sequencers</p>
          </div>
          <div>
            <p className="text-3xl font-bold text-white">---</p>
            <p className="text-slate-400 mt-1">Total Delegators</p>
          </div>
          <div>
            <p className="text-3xl font-bold text-white">---</p>
            <p className="text-slate-400 mt-1">Avg APY</p>
          </div>
        </div>
      </section>

      {/* How It Works */}
      <section>
        <h2 className="text-3xl font-bold text-white text-center mb-8">How It Works</h2>
        <div className="grid md:grid-cols-4 gap-6">
          {[
            { step: '1', title: 'Connect Wallet', desc: 'Connect your wallet to get started' },
            { step: '2', title: 'Choose Sequencer', desc: 'Browse and select a trusted sequencer' },
            { step: '3', title: 'Stake TON', desc: 'Approve and stake your TON tokens' },
            { step: '4', title: 'Earn Rewards', desc: 'Receive WTON rewards automatically' },
          ].map((item) => (
            <div key={item.step} className="text-center">
              <div className="h-12 w-12 rounded-full bg-gradient-to-r from-tokamak-blue to-tokamak-cyan flex items-center justify-center mx-auto mb-4 text-white font-bold">
                {item.step}
              </div>
              <h3 className="text-white font-semibold mb-2">{item.title}</h3>
              <p className="text-slate-400 text-sm">{item.desc}</p>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}
