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
import { useStake, useApproveTon, useTonBalance, useTonAllowance, useUnbondingPeriod } from '@/hooks/useStaking';
import { formatTON, parseTON } from '@/lib/utils';
import { toast } from 'sonner';
import { AlertTriangle, Loader2 } from 'lucide-react';

export function StakeModal() {
  const { address } = useAccount();
  const queryClient = useQueryClient();
  const { isStakeModalOpen, closeStakeModal, selectedSequencer } = useUIStore();
  const [amount, setAmount] = useState('');

  const { data: balance, refetch: refetchBalance } = useTonBalance(address);
  const { data: allowance, refetch: refetchAllowance } = useTonAllowance(address);
  const { data: unbondingPeriod } = useUnbondingPeriod();

  const { approve, isPending: isApproving, isSuccess: approveSuccess } = useApproveTon();
  const { stake, isPending: isStaking, isSuccess: stakeSuccess, isConfirming } = useStake();

  const parsedAmount = amount ? parseTON(amount) : 0n;
  const needsApproval = allowance !== undefined && parsedAmount > allowance;

  useEffect(() => {
    if (approveSuccess) {
      refetchAllowance();
      toast.success('Approval successful');
    }
  }, [approveSuccess, refetchAllowance]);

  useEffect(() => {
    if (stakeSuccess) {
      toast.success('Stake successful');
      // Refetch all staking-related data
      refetchBalance();
      refetchAllowance();
      // Invalidate all staking queries to refresh data
      queryClient.invalidateQueries({ queryKey: ['readContract'] });
      setAmount('');
      closeStakeModal();
    }
  }, [stakeSuccess, closeStakeModal, queryClient, refetchBalance, refetchAllowance]);

  const handleSubmit = () => {
    if (!selectedSequencer || parsedAmount === 0n) return;

    if (needsApproval) {
      approve(parsedAmount);
    } else {
      stake(selectedSequencer, parsedAmount);
    }
  };

  const setMaxAmount = () => {
    if (balance) {
      setAmount(formatTON(balance));
    }
  };

  const unbondingDays = unbondingPeriod ? Number(unbondingPeriod) / 86400 : 14;
  const isLoading = isApproving || isStaking || isConfirming;
  const isValid = parsedAmount > 0n && balance && parsedAmount <= balance;

  return (
    <Dialog open={isStakeModalOpen} onOpenChange={() => closeStakeModal()}>
      <DialogContent className="bg-slate-900 border-slate-800">
        <DialogHeader>
          <DialogTitle className="text-white">Stake TON</DialogTitle>
          <DialogDescription>
            Delegate your TON to this sequencer and earn WTON rewards.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4 py-4">
          {/* Warning */}
          <div className="flex items-start gap-3 p-3 rounded-lg bg-yellow-500/10 border border-yellow-500/20">
            <AlertTriangle className="h-5 w-5 text-yellow-500 flex-shrink-0 mt-0.5" />
            <p className="text-sm text-yellow-200">
              Staked TON has a {unbondingDays}-day unbonding period when withdrawing.
            </p>
          </div>

          {/* Amount Input */}
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <label className="text-sm text-slate-400">Amount</label>
              <span className="text-sm text-slate-400">
                Balance: {balance ? formatTON(balance) : '0'} TON
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
          <Button variant="outline" onClick={() => closeStakeModal()}>
            Cancel
          </Button>
          <Button
            variant="gradient"
            onClick={handleSubmit}
            disabled={!isValid || isLoading}
          >
            {isLoading ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                {isApproving ? 'Approving...' : isConfirming ? 'Confirming...' : 'Staking...'}
              </>
            ) : needsApproval ? (
              'Approve TON'
            ) : (
              'Stake'
            )}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
