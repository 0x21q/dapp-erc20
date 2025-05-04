# run from the root project directory

.PHONY: network deploy dapp test

network:
	anvil

deploy:
	forge script script/Deploy.s.sol:DeployScript --rpc-url http://localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast

dapp:
	cd dapp-wagmi && npx wagmi generate && npm run dev

test:
	forge test