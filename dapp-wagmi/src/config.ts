import { createConfig, http } from "wagmi";
import { metaMask } from "wagmi/connectors";

// Define contract address (currently localhost contract address)
export const CONTRACT_ADDRESS =
  "0x5FbDB2315678afecb367f032d93F642f64180aa3" as `0x${string}`;

const connector = metaMask({
  dappMetadata: {
    name: "ERC20 BDA - dApp",
  },
});

const anvilChain = {
    id: 31337,
    name: "Anvil",
    network: "anvil",
    nativeCurrency: {
      name: "Ether",
      symbol: "ETH",
      decimals: 18,
    },
    rpcUrls: {
      default: {
        http: ["http://localhost:8545"],
      },
    },
  };

export const config = createConfig({
  chains: [anvilChain],
  connectors: [connector],
  transports: {
    [anvilChain.id]: http()
  },
});
