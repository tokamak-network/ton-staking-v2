'use client';

import { useEffect } from 'react';
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
import { useUIStore } from '@/stores/ui';
import { useWithdraw, useStakeInfo, useUnbondingPeriod } from '@/hooks/useStaking';
import { formatTON, formatAddress } from '@/lib/utils';
import { toast } from 'sonner';
import { Loader2, CheckCircle, Clock } from 'lucide-react';
import { useAccount } from 'wagmi';

// Helper to normalize stakeInfo from tuple or object format
function normalizeStakeInfo(data: unknown): { amount: bigint; unstakeAmount: bigint; unstakeTime: bigint } | null {
  if (!data) return null;
  if (Array.isArray(data)) {
    return { amount: data[0] as bigint, unstakeAmount: data[2] as bigint, unstakeTime: data[3] as bigint };
  }
  const obj = data as { amount?: bigint; unstakeAmount?: bigint; unstakeTime?: bigint };
  return { amount: obj.amount || 0n, unstakeAmount: obj.unstakeAmount || 0n, unstakeTime: obj.unstakeTime || 0n };
}

export function WithdrawModal() {
  const { address } = useAccount();
  const queryClient = useQueryClient();
  const { isWithdrawModalOpen, closeWithdrawModal, selectedSequencer } = useUIStore();

  const { data: stakeInfoRaw } = useStakeInfo(address, selectedSequencer ?? undefined);
  const { data: unbondingPeriod } = useUnbondingPeriod();
  const { withdraw, isPending, isSuccess, isConfirming } = useWithdraw();

  const stakeInfo = normalizeStakeInfo(stakeInfoRaw);

  useEffect(() => {
    if (isSuccess) {
      toast.success('Withdrawal successful! TON returned to your wallet.');
      queryClient.invalidateQueries({ queryKey: ['readContract'] });
      closeWithdrawModal();
    }
  }, [isSuccess, closeWithdrawModal, queryClient]);

  const handleWithdraw = () => {
    if (!selectedSequencer) return;
    withdraw(selectedSequencer);
  };

  const now = BigInt(Math.floor(Date.now() / 1000));
  const withdrawTime = stakeInfo && unbondingPeriod
    ? stakeInfo.unstakeTime + unbondingPeriod
    : 0n;
  const canWithdraw = stakeInfo && stakeInfo.unstakeAmount > 0n && withdrawTime <= now;
  const isLoading = isPending || isConfirming;

  return (
    <Dialog open={isWithdrawModalOpen} onOpenChange={() => closeWithdrawModal()}>
      <DialogContent className="bg-slate-900 border-slate-800">
        <DialogHeader>
          <DialogTitle className="text-white">Withdraw</DialogTitle>
          <DialogDescription>
            Withdraw your unstaked TON to your wallet.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4 py-4">
          {selectedSequencer && (
            <div className="text-sm text-slate-400">
              Sequencer: <span className="font-mono text-white">{formatAddress(selectedSequencer, 6)}</span>
            </div>
          )}

          <div className="p-4 rounded-lg bg-slate-800/50 border border-slate-700">
            <p className="text-sm text-slate-400 mb-2">Available to Withdraw</p>
            <p className="text-2xl font-bold text-white">
              {stakeInfo ? formatTON(stakeInfo.unstakeAmount) : '0'} TON
            </p>
          </div>

          {canWithdraw ? (
            <div className="flex items-center gap-2 text-green-400">
              <CheckCircle className="h-4 w-4" />
              <span className="text-sm">Unbonding period complete</span>
            </div>
          ) : stakeInfo && stakeInfo.unstakeAmount > 0n ? (
            <div className="flex items-center gap-2 text-yellow-400">
              <Clock className="h-4 w-4" />
              <span className="text-sm">Unbonding period not yet complete</span>
            </div>
          ) : null}

          <p className="text-sm text-slate-400">
            Your TON will be returned to your wallet.
          </p>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={() => closeWithdrawModal()}>
            Cancel
          </Button>
          <Button
            variant="gradient"
            onClick={handleWithdraw}
            disabled={!canWithdraw || isLoading}
          >
            {isLoading ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                {isConfirming ? 'Confirming...' : 'Withdrawing...'}
              </>
            ) : (
              'Withdraw'
            )}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
