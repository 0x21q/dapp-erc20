import { createConfig, http } from 'wagmi'
import { mainnet, sepolia } from 'wagmi/chains'
import { metaMask } from 'wagmi/connectors'

const connector = metaMask({
    dappMetadata: { 
      name: 'ERC20 BDA - dApp', 
    }
  })

export const config = createConfig({
  chains: [mainnet, sepolia],
  connectors: [connector],
  transports: {
    [mainnet.id]: http(),
    [sepolia.id]: http(),
  },
})

// Define contract address
export const CONTRACT_ADDRESS = '0x6B175474E89094C44Da98b954EedeAC495271d0F' as `0x${string}`;

// ERC20 ABI for transfer function
export const erc20ABI = [
  {
    "constant": false,
    "inputs": [
      { "name": "_to", "type": "address" },
      { "name": "_value", "type": "uint256" }
    ],
    "name": "transfer",
    "outputs": [{ "name": "", "type": "bool" }],
    "type": "function"
  }
] as const;


