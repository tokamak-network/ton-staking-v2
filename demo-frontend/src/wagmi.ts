import { http, createConfig } from 'wagmi'
import { localhost } from 'wagmi/chains'

const anvilChain = {
  ...localhost,
  id: 31337,
  name: 'Anvil',
  rpcUrls: {
    default: { http: ['http://localhost:8545'] },
  },
}

export const config = createConfig({
  chains: [anvilChain],
  transports: {
    [anvilChain.id]: http('http://localhost:8545'),
  },
})

declare module 'wagmi' {
  interface Register {
    config: typeof config
  }
}
