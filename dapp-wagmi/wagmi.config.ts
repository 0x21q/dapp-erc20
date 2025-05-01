import { defineConfig } from "@wagmi/cli";
import { foundry } from "@wagmi/cli/plugins";
import { react } from "@wagmi/cli/plugins";

// config for abi generation

export default defineConfig({
  out: "src/generated.ts",
  plugins: [
    foundry({
      project: "../",
    }),
  ],
});
