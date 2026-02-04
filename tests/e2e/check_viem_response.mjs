// Check how viem returns stakeInfo data
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

  console.log('=== VIEM RESPONSE FORMAT ===');
  console.log('Result type:', typeof result);
  console.log('Is array:', Array.isArray(result));
  console.log('Result:', JSON.stringify(result, (k, v) => typeof v === 'bigint' ? v.toString() : v, 2));
  console.log('Result keys:', Object.keys(result));
  console.log('');

  // Test array access
  console.log('=== ARRAY ACCESS ===');
  try {
    console.log('result[0]:', result[0]?.toString());
    console.log('result[2]:', result[2]?.toString());
  } catch (e) {
    console.log('Array access failed:', e.message);
  }

  // Test object access
  console.log('');
  console.log('=== OBJECT ACCESS ===');
  try {
    console.log('result.amount:', result.amount?.toString());
    console.log('result.unstakeAmount:', result.unstakeAmount?.toString());
  } catch (e) {
    console.log('Object access failed:', e.message);
  }
}

main().catch(console.error);
