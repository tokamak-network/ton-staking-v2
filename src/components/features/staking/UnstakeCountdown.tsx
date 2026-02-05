'use client';

import { useState, useEffect } from 'react';
import { Clock, CheckCircle } from 'lucide-react';

interface UnstakeCountdownProps {
  unstakeTime: bigint;
  unbondingPeriod: bigint;
}

function formatTimeRemaining(seconds: number): string {
  if (seconds <= 0) return 'Ready';

  const days = Math.floor(seconds / 86400);
  const hours = Math.floor((seconds % 86400) / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secs = seconds % 60;

  if (days > 0) {
    return `${days}d ${hours}h ${minutes}m`;
  } else if (hours > 0) {
    return `${hours}h ${minutes}m ${secs}s`;
  } else if (minutes > 0) {
    return `${minutes}m ${secs}s`;
  } else {
    return `${secs}s`;
  }
}

export function UnstakeCountdown({ unstakeTime, unbondingPeriod }: UnstakeCountdownProps) {
  const [timeLeft, setTimeLeft] = useState(0);

  useEffect(() => {
    const withdrawTime = Number(unstakeTime) + Number(unbondingPeriod);
    const now = Math.floor(Date.now() / 1000);
    setTimeLeft(Math.max(0, withdrawTime - now));

    const interval = setInterval(() => {
      const currentNow = Math.floor(Date.now() / 1000);
      const remaining = Math.max(0, withdrawTime - currentNow);
      setTimeLeft(remaining);

      if (remaining <= 0) {
        clearInterval(interval);
      }
    }, 1000);

    return () => clearInterval(interval);
  }, [unstakeTime, unbondingPeriod]);

  if (timeLeft <= 0) {
    return (
      <span className="flex items-center gap-1 text-green-400 text-sm">
        <CheckCircle className="h-3 w-3" />
        Ready to withdraw
      </span>
    );
  }

  return (
    <span className="flex items-center gap-1 text-yellow-400 text-sm">
      <Clock className="h-3 w-3" />
      {formatTimeRemaining(timeLeft)}
    </span>
  );
}
