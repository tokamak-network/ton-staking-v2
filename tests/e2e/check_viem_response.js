// Run this in browser console to check viem response format
// Or run with: node --experimental-specifier-resolution=node tests/e2e/check_viem_response.js

import { createPublicClient, http } from 'viem';
import { localhost } from 'viem/chains';

const DELEGATE_STAKING_ABI = [
  {
    inputs: [
      { name: 'staker', type: 'address' },
      { name: 'sequencer', type: 'address' },
    ],
    name: 'getStakeInfo',
    outputs: [
      {
        components: [
          { name: 'amount', type: 'uint256' },
          { name: 'rewardDebt', type: 'uint256' },
          { name: 'unstakeAmount', type: 'uint256' },
          { name: 'unstakeTime', type: 'uint256' },
        ],
        name: '',
        type: 'tuple',
      },
    ],
    stateMutability: 'view',
    type: 'function',
  },
];

async function main() {
  const client = createPublicClient({
    chain: localhost,
    transport: http('http://localhost:8545'),
  });

  const result = await client.readContract({
    address: '0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82',
    abi: DELEGATE_STAKING_ABI,
    functionName: 'getStakeInfo',
    args: ['0x90F79bf6EB2c4f870365E785982E1f101E93b906', '0x70997970C51812dc3A010C7d01b50e0d17dc79C8'],
  });

  console.log('Result type:', typeof result);
  console.log('Is array:', Array.isArray(result));
  console.log('Result:', result);
  console.log('Result keys:', Object.keys(result));

  if (Array.isArray(result)) {
    console.log('Array access - result[0]:', result[0]);
    console.log('Array access - result[2]:', result[2]);
  }

  if (result.amount !== undefined) {
    console.log('Object access - result.amount:', result.amount);
    console.log('Object access - result.unstakeAmount:', result.unstakeAmount);
  }
}

main().catch(console.error);
