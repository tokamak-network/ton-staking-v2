'use client';

import { useState, useEffect } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { useUIStore } from '@/stores/ui';
import { useRedelegate, useStakeInfo, useSequencerList } from '@/hooks/useStaking';
import { formatTON, formatAddress, parseTON } from '@/lib/utils';
import { toast } from 'sonner';
import { Loader2, ArrowRight, Info } from 'lucide-react';
import { useAccount } from 'wagmi';
import { Address } from 'viem';

// Helper to normalize stakeInfo from tuple or object format
function normalizeStakeInfo(data: unknown): { amount: bigint; unstakeAmount: bigint } | null {
  if (!data) return null;
  if (Array.isArray(data)) {
    return { amount: data[0] as bigint, unstakeAmount: data[2] as bigint };
  }
  const obj = data as { amount?: bigint; unstakeAmount?: bigint };
  return { amount: obj.amount || 0n, unstakeAmount: obj.unstakeAmount || 0n };
}

export function RedelegateModal() {
  const { address } = useAccount();
  const queryClient = useQueryClient();
  const { isRedelegateModalOpen, closeRedelegateModal, selectedSequencer } = useUIStore();

  const [toSequencer, setToSequencer] = useState<Address | ''>('');
  const [amount, setAmount] = useState('');

  const { data: sequencers } = useSequencerList();
  const { data: stakeInfoRaw } = useStakeInfo(address, selectedSequencer ?? undefined);
  const { redelegate, isPending, isSuccess, isConfirming } = useRedelegate();

  const stakeInfo = normalizeStakeInfo(stakeInfoRaw);

  // Filter out the current sequencer from the list
  const availableSequencers = sequencers?.filter(seq => seq !== selectedSequencer) || [];

  useEffect(() => {
    if (isSuccess) {
      toast.success('Redelegation successful');
      queryClient.invalidateQueries({ queryKey: ['readContract'] });
      setAmount('');
      setToSequencer('');
      closeRedelegateModal();
    }
  }, [isSuccess, closeRedelegateModal, queryClient]);

  // Reset form when modal opens
  useEffect(() => {
    if (isRedelegateModalOpen) {
      setAmount('');
      setToSequencer('');
    }
  }, [isRedelegateModalOpen]);

  const handleRedelegate = () => {
    if (!selectedSequencer || !toSequencer || !amount) return;
    const parsedAmount = parseTON(amount);
    if (parsedAmount === 0n) return;
    redelegate(selectedSequencer, toSequencer as Address, parsedAmount);
  };

  const setMaxAmount = () => {
    if (stakeInfo && stakeInfo.amount > 0n) {
      setAmount(formatTON(stakeInfo.amount));
    }
  };

  const parsedAmount = amount ? parseTON(amount) : 0n;
  const isLoading = isPending || isConfirming;
  const isValid = parsedAmount > 0n && stakeInfo && parsedAmount <= stakeInfo.amount && toSequencer;

  return (
    <Dialog open={isRedelegateModalOpen} onOpenChange={() => closeRedelegateModal()}>
      <DialogContent className="bg-slate-900 border-slate-800">
        <DialogHeader>
          <DialogTitle className="text-white flex items-center gap-2">
            Redelegate
            <ArrowRight className="h-4 w-4" />
          </DialogTitle>
          <DialogDescription>
            Move your stake to a different sequencer without unbonding.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4 py-4">
          {/* From Sequencer */}
          <div className="space-y-2">
            <label className="text-sm text-slate-400">From</label>
            <div className="p-3 rounded-lg bg-slate-800/50 border border-slate-700">
              <p className="font-mono text-white text-sm">
                {selectedSequencer ? formatAddress(selectedSequencer, 8) : '-'}
              </p>
              <p className="text-xs text-slate-400 mt-1">
                Current Stake: {stakeInfo ? formatTON(stakeInfo.amount) : '0'} TON
              </p>
            </div>
          </div>

          {/* To Sequencer */}
          <div className="space-y-2">
            <label className="text-sm text-slate-400">To Sequencer</label>
            <select
              value={toSequencer}
              onChange={(e) => setToSequencer(e.target.value as Address)}
              className="w-full p-3 rounded-lg bg-slate-800 border border-slate-700 text-white"
            >
              <option value="">Select sequencer...</option>
              {availableSequencers.map((seq) => (
                <option key={seq} value={seq}>
                  {formatAddress(seq as Address, 8)}
                </option>
              ))}
            </select>
          </div>

          {/* Amount Input */}
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <label className="text-sm text-slate-400">Amount</label>
              <span className="text-sm text-slate-400">
                Available: {stakeInfo ? formatTON(stakeInfo.amount) : '0'} TON
              </span>
            </div>
            <div className="relative">
              <Input
                type="text"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                placeholder="0.0"
                className="pr-20 bg-slate-800 border-slate-700"
              />
              <button
                onClick={setMaxAmount}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-xs text-tokamak-blue hover:text-tokamak-cyan"
              >
                MAX
              </button>
            </div>
          </div>

          {/* Info */}
          <div className="flex items-start gap-2 p-3 rounded-lg bg-blue-500/10 border border-blue-500/20">
            <Info className="h-4 w-4 text-blue-400 flex-shrink-0 mt-0.5" />
            <p className="text-sm text-blue-200">
              No unbonding period for redelegation. Your stake moves instantly.
            </p>
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={() => closeRedelegateModal()}>
            Cancel
          </Button>
          <Button
            variant="gradient"
            onClick={handleRedelegate}
            disabled={!isValid || isLoading}
          >
            {isLoading ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                {isConfirming ? 'Confirming...' : 'Redelegating...'}
              </>
            ) : (
              'Redelegate'
            )}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
