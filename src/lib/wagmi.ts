import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { mainnet, sepolia, hardhat } from 'wagmi/chains';

// Put hardhat first for local development (default chain when no wallet connected)
const isDev = process.env.NODE_ENV === 'development';

export const config = getDefaultConfig({
  appName: 'Tokamak Delegate Staking',
  projectId: process.env.NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID || 'demo-project-id',
  chains: isDev ? [hardhat, mainnet, sepolia] : [mainnet, sepolia, hardhat],
  ssr: true,
});
