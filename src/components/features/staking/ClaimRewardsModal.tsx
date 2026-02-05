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
import { useClaimRewards, usePendingRewards } from '@/hooks/useStaking';
import { formatWTON } from '@/lib/utils';
import { toast } from 'sonner';
import { Loader2, Gift } from 'lucide-react';
import { useAccount } from 'wagmi';

export function ClaimRewardsModal() {
  const { address } = useAccount();
  const queryClient = useQueryClient();
  const { isClaimModalOpen, closeClaimModal, selectedSequencer } = useUIStore();

  const { data: pendingRewards } = usePendingRewards(address, selectedSequencer ?? undefined);
  const { claimRewards, isPending, isSuccess, isConfirming } = useClaimRewards();

  useEffect(() => {
    if (isSuccess) {
      toast.success('Rewards claimed successfully');
      queryClient.invalidateQueries({ queryKey: ['readContract'] });
      closeClaimModal();
    }
  }, [isSuccess, closeClaimModal, queryClient]);

  const handleClaim = () => {
    if (!selectedSequencer) return;
    claimRewards(selectedSequencer);
  };

  const isLoading = isPending || isConfirming;
  const hasRewards = pendingRewards && pendingRewards > 0n;

  return (
    <Dialog open={isClaimModalOpen} onOpenChange={() => closeClaimModal()}>
      <DialogContent className="bg-slate-900 border-slate-800">
        <DialogHeader>
          <DialogTitle className="text-white flex items-center gap-2">
            <Gift className="h-5 w-5 text-tokamak-cyan" />
            Claim Rewards
          </DialogTitle>
          <DialogDescription>
            Claim your pending WTON rewards from this sequencer.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4 py-4">
          <div className="p-4 rounded-lg bg-slate-800/50 border border-slate-700">
            <p className="text-sm text-slate-400 mb-2">Available Rewards</p>
            <p className="text-2xl font-bold text-tokamak-cyan">
              {pendingRewards ? formatWTON(pendingRewards) : '0'} WTON
            </p>
          </div>

          <p className="text-sm text-slate-400">
            You will receive WTON rewards directly to your wallet.
          </p>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={() => closeClaimModal()}>
            Cancel
          </Button>
          <Button
            variant="gradient"
            onClick={handleClaim}
            disabled={!hasRewards || isLoading}
          >
            {isLoading ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                {isConfirming ? 'Confirming...' : 'Claiming...'}
              </>
            ) : (
              'Claim'
            )}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
