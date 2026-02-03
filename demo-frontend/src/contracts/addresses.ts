export const ADDRESSES = {
  ton: '0x0000000000000000000000000000000000000000' as `0x${string}`,
  wton: '0x0000000000000000000000000000000000000000' as `0x${string}`,
  lotteryCandidate: '0x0000000000000000000000000000000000000000' as `0x${string}`,
  operator: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8' as `0x${string}`,
}

export function updateAddresses(deployed: {
  ton: string
  wton: string
  lotteryCandidate: string
  operator: string
}) {
  ADDRESSES.ton = deployed.ton as `0x${string}`
  ADDRESSES.wton = deployed.wton as `0x${string}`
  ADDRESSES.lotteryCandidate = deployed.lotteryCandidate as `0x${string}`
  ADDRESSES.operator = deployed.operator as `0x${string}`
}
