## Equilibra-SmartContracts


**In this repo you'll find the contracts refering to V1 of Equilibra's protocol.**

## What is Equilibra?
Equilibra is a fund distribution protocol designed to merge 2 super powerfull techlologies:
    1. Money Streaming
    2. Conviction Voting
    
Usage:
-   **Install**: forge install
-   **Test** : forge test 
-   **Deploy** : 
    1. Setup `.env` variables (see `script/DeploySystem.s.sol:DeploySystem` to check wich variables are needed)
    - LocalHost:
        - > 2. `anvil -a 22 -b 22`
        - > 3. `make deploy-all-llhh`
    -  Other chains:
        - > 2. Setup make command
        - > 3. `make {$YOU_COMMAND}`


# Local_Host vars:
- **ONLY** use this variables to test in a local enviroment, remember this addresses & private keys are being displayed to each and every user of hardhat & foundry 
LH_PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

LH_REG_OWNER='0x70997970C51812dc3A010C7d01b50e0d17dc79C8'
LH_REG_OWNER='0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC'
LH_REG_BEACON_OWNER='0x90F79bf6EB2c4f870365E785982E1f101E93b906'
LH_MNGR_OWNER='0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65'
LH_MNGR_BEACON_OWNER='0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc'
