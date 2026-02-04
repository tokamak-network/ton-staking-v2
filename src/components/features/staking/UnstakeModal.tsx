'use client';

import { useState, useEffect } from 'react';
import { useAccount } from 'wagmi';
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
import { useUnstake, useStakeInfo, useUnbondingPeriod } from '@/hooks/useStaking';
import { formatTON, parseTON } from '@/lib/utils';
import { toast } from 'sonner';
import { Clock, Loader2 } from 'lucide-react';

export function UnstakeModal() {
  const { address } = useAccount();
  const queryClient = useQueryClient();
  const { isUnstakeModalOpen, closeUnstakeModal, selectedSequencer } = useUIStore();
  const [amount, setAmount] = useState('');

  const { data: stakeInfo } = useStakeInfo(address, selectedSequencer || undefined);
  const { data: unbondingPeriod } = useUnbondingPeriod();

  const { unstake, isPending, isSuccess, isConfirming } = useUnstake();

  const parsedAmount = amount ? parseTON(amount) : 0n;
  const stakedBalance = stakeInfo?.amount || 0n;

  useEffect(() => {
    if (isSuccess) {
      toast.success('Unstake request submitted');
      // Invalidate all staking queries to refresh data
      queryClient.invalidateQueries({ queryKey: ['readContract'] });
      setAmount('');
      closeUnstakeModal();
    }
  }, [isSuccess, closeUnstakeModal, queryClient]);

  const handleSubmit = () => {
    if (!selectedSequencer || parsedAmount === 0n) return;
    unstake(selectedSequencer, parsedAmount);
  };

  const setMaxAmount = () => {
    if (stakedBalance > 0n) {
      setAmount(formatTON(stakedBalance));
    }
  };

  const unbondingDays = unbondingPeriod ? Number(unbondingPeriod) / 86400 : 14;
  const isLoading = isPending || isConfirming;
  const isValid = parsedAmount > 0n && parsedAmount <= stakedBalance;

  return (
    <Dialog open={isUnstakeModalOpen} onOpenChange={() => closeUnstakeModal()}>
      <DialogContent className="bg-slate-900 border-slate-800">
        <DialogHeader>
          <DialogTitle className="text-white">Unstake TON</DialogTitle>
          <DialogDescription>
            Request to withdraw your staked TON from this sequencer.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4 py-4">
          {/* Unbonding Info */}
          <div className="flex items-start gap-3 p-3 rounded-lg bg-slate-800/50 border border-slate-700">
            <Clock className="h-5 w-5 text-slate-400 flex-shrink-0 mt-0.5" />
            <div>
              <p className="text-sm text-white font-medium">Unbonding Period</p>
              <p className="text-sm text-slate-400">
                Your TON will be available to withdraw after {unbondingDays} days.
              </p>
            </div>
          </div>

          {/* Amount Input */}
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <label className="text-sm text-slate-400">Amount</label>
              <span className="text-sm text-slate-400">
                Staked: {formatTON(stakedBalance)} TON
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
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={() => closeUnstakeModal()}>
            Cancel
          </Button>
          <Button
            variant="destructive"
            onClick={handleSubmit}
            disabled={!isValid || isLoading}
          >
            {isLoading ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                {isConfirming ? 'Confirming...' : 'Processing...'}
              </>
            ) : (
              'Request Unstake'
            )}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
