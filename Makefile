-include .env

build:; forge build

deploy-all-llhh:
	forge script script/DeploySystem.s.sol:DeploySystem --rpc-url llhh  --watch -vvvv --broadcast