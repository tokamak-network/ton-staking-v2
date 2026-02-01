'use client';

import { useSequencerList } from '@/hooks/useStaking';
import { SequencerCard } from '@/components/features/sequencers/SequencerCard';
import { Skeleton } from '@/components/ui/skeleton';
import { Card, CardContent } from '@/components/ui/card';
import { Search, Filter } from 'lucide-react';
import { Input } from '@/components/ui/input';
import { useState } from 'react';
import { Address } from 'viem';

export default function SequencersPage() {
  const { data: sequencers, isLoading } = useSequencerList();
  const [searchQuery, setSearchQuery] = useState('');

  const filteredSequencers = sequencers?.filter((seq) =>
    seq.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold text-white mb-2">Sequencers</h1>
        <p className="text-slate-400">
          Browse and delegate to active sequencers on Tokamak Network
        </p>
      </div>

      {/* Search and Filter */}
      <div className="flex gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
          <Input
            placeholder="Search by address..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-10 bg-slate-900/50 border-slate-800"
          />
        </div>
        <button className="flex items-center gap-2 px-4 py-2 rounded-md border border-slate-800 text-slate-400 hover:text-white hover:border-slate-700 transition-colors">
          <Filter className="h-4 w-4" />
          Filters
        </button>
      </div>

      {/* Sequencer List */}
      {isLoading ? (
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {[...Array(6)].map((_, i) => (
            <Card key={i} className="bg-slate-900/50 border-slate-800">
              <CardContent className="p-6">
                <Skeleton className="h-6 w-32 mb-4" />
                <Skeleton className="h-4 w-full mb-2" />
                <Skeleton className="h-4 w-3/4 mb-4" />
                <Skeleton className="h-10 w-full" />
              </CardContent>
            </Card>
          ))}
        </div>
      ) : filteredSequencers && filteredSequencers.length > 0 ? (
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredSequencers.map((sequencer) => (
            <SequencerCard key={sequencer} address={sequencer as Address} />
          ))}
        </div>
      ) : (
        <Card className="bg-slate-900/50 border-slate-800">
          <CardContent className="p-12 text-center">
            <p className="text-slate-400">
              {searchQuery ? 'No sequencers found matching your search.' : 'No sequencers registered yet.'}
            </p>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
