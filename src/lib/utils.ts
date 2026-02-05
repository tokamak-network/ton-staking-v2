import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatAddress(address: string, chars = 4): string {
  return `${address.slice(0, chars + 2)}...${address.slice(-chars)}`;
}

export function formatTON(value: bigint, decimals = 18): string {
  const divisor = BigInt(10 ** decimals);
  const intPart = value / divisor;
  const decPart = value % divisor;
  const decStr = decPart.toString().padStart(decimals, '0').slice(0, 2);
  return `${intPart.toLocaleString()}.${decStr}`;
}

export function formatWTON(value: bigint): string {
  return formatTON(value, 27);
}

export function parseTON(value: string): bigint {
  const [intPart, decPart = ''] = value.split('.');
  const paddedDec = decPart.padEnd(18, '0').slice(0, 18);
  return BigInt(intPart + paddedDec);
}

export function formatPercent(bps: number): string {
  return `${(bps / 100).toFixed(2)}%`;
}

export function formatTimeRemaining(seconds: number): string {
  if (seconds <= 0) return 'Ready';

  const days = Math.floor(seconds / 86400);
  const hours = Math.floor((seconds % 86400) / 3600);
  const mins = Math.floor((seconds % 3600) / 60);

  if (days > 0) return `${days}d ${hours}h`;
  if (hours > 0) return `${hours}h ${mins}m`;
  return `${mins}m`;
}
