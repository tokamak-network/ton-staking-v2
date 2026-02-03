'use client';

import { useState, useEffect } from 'react';
import { useAccount } from 'wagmi';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { useSequencerInfo } from '@/hooks/useStaking';
import {
  useRegisterSequencer,
  useUpdateCommission,
  useClaimCommission,
  useDeregisterSequencer,
} from '@/hooks/useSequencerAdmin';
import { formatAddress, formatPercent, formatWTON } from '@/lib/utils';
import { toast } from 'sonner';
import { Wallet, Settings, Shield, AlertTriangle, Loader2 } from 'lucide-react';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { Address, isAddress } from 'viem';

export default function AdminPage() {
  const { address, isConnected } = useAccount();
  const { data: sequencerInfo, refetch } = useSequencerInfo(address);

  const [layer2Address, setLayer2Address] = useState('');
  const [operatorManagerAddress, setOperatorManagerAddress] = useState('');
  const [commission, setCommission] = useState('');
  const [newCommission, setNewCommission] = useState('');

  const {
    register,
    isPending: isRegistering,
    isSuccess: registerSuccess,
  } = useRegisterSequencer();

  const {
    updateCommission,
    isPending: isUpdating,
    isSuccess: updateSuccess,
  } = useUpdateCommission();

  const {
    claimCommission,
    isPending: isClaiming,
    isSuccess: claimSuccess,
  } = useClaimCommission();

  const {
    deregister,
    isPending: isDeregistering,
    isSuccess: deregisterSuccess,
  } = useDeregisterSequencer();

  useEffect(() => {
    if (registerSuccess) {
      toast.success('Sequencer registered successfully');
      refetch();
    }
  }, [registerSuccess, refetch]);

  useEffect(() => {
    if (updateSuccess) {
      toast.success('Commission updated successfully');
      refetch();
    }
  }, [updateSuccess, refetch]);

  useEffect(() => {
    if (claimSuccess) {
      toast.success('Commission claimed successfully');
      refetch();
    }
  }, [claimSuccess, refetch]);

  useEffect(() => {
    if (deregisterSuccess) {
      toast.success('Sequencer deregistered successfully');
      refetch();
    }
  }, [deregisterSuccess, refetch]);

  const handleRegister = () => {
    if (!isAddress(layer2Address)) {
      toast.error('Invalid Layer2 address');
      return;
    }
    if (!isAddress(operatorManagerAddress)) {
      toast.error('Invalid OperatorManager address');
      return;
    }
    const commissionBps = BigInt(Math.round(parseFloat(commission) * 100));
    register(layer2Address as Address, operatorManagerAddress as Address, commissionBps);
  };

  const handleUpdateCommission = () => {
    const commissionBps = BigInt(Math.round(parseFloat(newCommission) * 100));
    updateCommission(commissionBps);
  };

  if (!isConnected) {
    return (
      <div className="flex flex-col items-center justify-center py-20">
        <Wallet className="h-16 w-16 text-slate-600 mb-4" />
        <h2 className="text-2xl font-bold text-white mb-2">Connect Your Wallet</h2>
        <p className="text-slate-400 mb-6">Connect your wallet to access sequencer admin</p>
        <ConnectButton />
      </div>
    );
  }

  const isRegistered = sequencerInfo?.isRegistered;

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold text-white mb-2">Sequencer Admin</h1>
        <p className="text-slate-400">
          Register and manage your sequencer on Tokamak Network
        </p>
      </div>

      {!isRegistered ? (
        // Registration Form
        <Card className="bg-slate-900/50 border-slate-800 max-w-xl">
          <CardHeader>
            <CardTitle className="text-white flex items-center gap-2">
              <Shield className="h-5 w-5" />
              Register as Sequencer
            </CardTitle>
            <CardDescription>
              Register your address as a sequencer to receive delegations
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <label className="text-sm text-slate-400">Layer2 Address</label>
              <Input
                value={layer2Address}
                onChange={(e) => setLayer2Address(e.target.value)}
                placeholder="0x..."
                className="bg-slate-800 border-slate-700"
              />
              <p className="text-xs text-slate-500">
                The Layer2 contract address you operate
              </p>
            </div>

            <div className="space-y-2">
              <label className="text-sm text-slate-400">OperatorManager Address</label>
              <Input
                value={operatorManagerAddress}
                onChange={(e) => setOperatorManagerAddress(e.target.value)}
                placeholder="0x..."
                className="bg-slate-800 border-slate-700"
              />
              <p className="text-xs text-slate-500">
                The OperatorManager contract address from V3 Layer2Manager
              </p>
            </div>

            <div className="space-y-2">
              <label className="text-sm text-slate-400">Commission Rate (%)</label>
              <Input
                type="number"
                value={commission}
                onChange={(e) => setCommission(e.target.value)}
                placeholder="5"
                min="0"
                max="30"
                step="0.01"
                className="bg-slate-800 border-slate-700"
              />
              <p className="text-xs text-slate-500">
                Maximum commission is 30%
              </p>
            </div>

            <Button
              variant="gradient"
              className="w-full"
              onClick={handleRegister}
              disabled={isRegistering || !layer2Address || !operatorManagerAddress || !commission}
            >
              {isRegistering ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Registering...
                </>
              ) : (
                'Register Sequencer'
              )}
            </Button>
          </CardContent>
        </Card>
      ) : (
        // Management Panel
        <div className="space-y-6">
          {/* Sequencer Info */}
          <Card className="bg-slate-900/50 border-slate-800">
            <CardHeader>
              <CardTitle className="text-white">Sequencer Status</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid md:grid-cols-4 gap-6">
                <div>
                  <p className="text-slate-400 text-sm mb-1">Address</p>
                  <p className="text-white font-mono">{formatAddress(address!, 6)}</p>
                </div>
                <div>
                  <p className="text-slate-400 text-sm mb-1">Layer2</p>
                  <p className="text-white font-mono">{formatAddress(sequencerInfo.layer2, 6)}</p>
                </div>
                <div>
                  <p className="text-slate-400 text-sm mb-1">Commission</p>
                  <p className="text-white">{formatPercent(Number(sequencerInfo.commission))}</p>
                </div>
                <div>
                  <p className="text-slate-400 text-sm mb-1">Total Staked</p>
                  <p className="text-white">{formatWTON(sequencerInfo.totalStaked)} TON</p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Commission Management */}
          <div className="grid md:grid-cols-2 gap-6">
            <Card className="bg-slate-900/50 border-slate-800">
              <CardHeader>
                <CardTitle className="text-white flex items-center gap-2">
                  <Settings className="h-5 w-5" />
                  Update Commission
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <label className="text-sm text-slate-400">New Commission Rate (%)</label>
                  <Input
                    type="number"
                    value={newCommission}
                    onChange={(e) => setNewCommission(e.target.value)}
                    placeholder="5"
                    min="0"
                    max="30"
                    step="0.01"
                    className="bg-slate-800 border-slate-700"
                  />
                </div>
                <Button
                  variant="outline"
                  className="w-full"
                  onClick={handleUpdateCommission}
                  disabled={isUpdating || !newCommission}
                >
                  {isUpdating ? (
                    <>
                      <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                      Updating...
                    </>
                  ) : (
                    'Update Commission'
                  )}
                </Button>
              </CardContent>
            </Card>

            <Card className="bg-slate-900/50 border-slate-800">
              <CardHeader>
                <CardTitle className="text-white">Claim Commission</CardTitle>
                <CardDescription>
                  Claimable: {formatWTON(sequencerInfo.totalCommission)} WTON
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <Button
                  variant="gradient"
                  className="w-full"
                  onClick={() => claimCommission()}
                  disabled={isClaiming || sequencerInfo.totalCommission === 0n}
                >
                  {isClaiming ? (
                    <>
                      <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                      Claiming...
                    </>
                  ) : (
                    'Claim Commission'
                  )}
                </Button>
              </CardContent>
            </Card>
          </div>

          {/* Danger Zone */}
          <Card className="bg-red-950/30 border-red-900/50">
            <CardHeader>
              <CardTitle className="text-red-400 flex items-center gap-2">
                <AlertTriangle className="h-5 w-5" />
                Danger Zone
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-slate-400 text-sm mb-4">
                Deregistering will remove you as a sequencer. This can only be done when you have no staked tokens.
              </p>
              <Button
                variant="destructive"
                onClick={() => deregister()}
                disabled={isDeregistering || sequencerInfo.totalStaked > 0n}
              >
                {isDeregistering ? (
                  <>
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    Deregistering...
                  </>
                ) : (
                  'Deregister Sequencer'
                )}
              </Button>
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  );
}
