// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ScriptUtils.sol";

contract DeploySystem is ScriptUtils {
    ManagerConstr mContructor;

    uint VERSION = 1;
    /**
     * @dev Pool contructor values
     */
    address CFA_FORWARDED;
    /**
     * @dev Registry init values
     */
    address REGISTRY_OWNER;
    address REGISTRY_BEACON_OWNER;
    /**
     * @dev Manager init values
     */
    address MANAGER_OWNER;
    address MANAGER_BEACON_OWNER;
    /**
     * @dev Deploy values
     */
    string CHAIN_NAME = "LOCAL_HOST";
    bool isLH = true;

    /**
     * @custom:set-up
     * @custom:env
     * 1. Create a `.env` file (in case you dont have one)
     * 2. Load all variables needed:
     *  - LH_PRIVATE_KEY                (llhh)
     *  - LH_REG_OWNER                  (llhh)
     *  - LH_REG_BEACON_OWNER           (llhh)
     *  - LH_MNGR_OWNER                 (llhh)
     *  - LH_MNGR_BEACON_OWNER          (llhh)
     * 
     *  - DEPLOY_PRIVATE_KEY            (!llhh)
     *  - SAFE_IMPL                     (!llhh)
     *  - DEPLOY_REG_OWNER              (!llhh)
     *  - DEPLOY_REG_BEACON_OWNER       (!llhh)
     *  - DEPLOY_CFA_FORWARDED          (!llhh)
     *  - DEPLOY_MNGR_OWNER             (!llhh)
     *  - DEPLOY_MNGR_BEACON_OWNER      (!llhh)
     * @custom:toml
     * 3. Create the desired profile to the chain you are going to deploy. Ej := llhh
     * [rpc_endpoints]
     * llhh='http://127.0.0.1:8545'
     * 
     * @custom:make
     * 4. create a custom command to deploy all seamesly. 
     * Ej: deploy-all-llhh:
	    forge script script/DeploySystem.s.sol:DeploySystem --rpc-url llhh  --watch -vvvv --broadcast
     *  
     * @custom:deploy
     * 
     * xCHAIN - >[open a terminal]: make deploy-all-xchain (@dev needs to be built)
     * 
     * LLHH   - >[open a terminal]: anvil ${ANVIL_CUSTOMISATION}
     *        - >[open a terminal]: make deploy-all-llhh
     */

    function run() external {
        uint pk = isLH
            ? vm.envUint("LH_PRIVATE_KEY")
            : vm.envUint("DEPLOY_PRIVATE_KEY");
        console.log("DEPLOYING_TO ->");
        console.log(CHAIN_NAME);
        vm.startBroadcast(pk);

        ///@custom:setups-manager-proxy-values
        mContructor = _deploySetup();

        ///@custom:deploy-manager-proxy
        managerImpl=createManagerImpl(mContructor);
        console.log('MANAGER_IMPL',address(managerImpl));

        (,managerBeacon, managerProxy) = createManagerProxy(
            address(managerImpl),
            MANAGER_OWNER,
            MANAGER_BEACON_OWNER
        );

        vm.stopBroadcast();
        ///@custom:console-logs-results
        _logResults();
    }

    function _logResults() internal view {
       
        console.log('-------------------------------');
        console.log('SAFE_IMPLEMENTATION:',mContructor.safeImplementation);
        console.log('-------------------------------');
        console.log('POOL_IMPLEMENTATION:',mContructor.poolImplemetation);
        console.log('POOL_CONSTR:',CFA_FORWARDED);
        console.log('INIT: FALSE');
        console.log('-------------------------------');
        console.log('REGISTRY_PROXY:',mContructor.projectRegistry);
        console.log('REGISTRY_IMPLEMENTATION:',address(registryImpl));
        console.log('REGISTRY_UPGRADEABLE_BEACON:',address(registryBeacon));
        console.log('');
        console.log('REGISTRY_CONSTR:',VERSION);
        console.log('INIT: TRUE');
        console.log('REGISTRY_OWNER:',REGISTRY_OWNER);
        console.log('REGISTRY_BEACON_OWNER:',REGISTRY_BEACON_OWNER);

        console.log('-------------------------------');

        console.log('MANAGER_PROXY:',address(managerProxy));
        console.log('MANAGER_IMPLEMENTATION:',address(managerImpl));
        console.log('MANAGER_UPGRADEABLE_BEACON:',address(managerBeacon));
        console.log('');
        console.log('MANAGER_CONSTR:',VERSION);
        console.log('MANAGER_CONSTR:',mContructor.poolImplemetation);
        console.log('MANAGER_CONSTR:',mContructor.safeImplementation);
        console.log('MANAGER_CONSTR:',mContructor.projectRegistry);
        console.log('INIT: TRUE');
        console.log('MANAGER_OWNER:',MANAGER_OWNER);
        console.log('MANAGER_BEACON_OWNER:',MANAGER_BEACON_OWNER);


    }

    function _deploySetup() internal returns (ManagerConstr memory) {
        ManagerConstr memory vars;
        vars.version = VERSION;
        if (isLH) {
            vars.safeImplementation = createSafeImpl();
            REGISTRY_OWNER = vm.envAddress("LH_REG_OWNER");
            REGISTRY_BEACON_OWNER = vm.envAddress("LH_REG_BEACON_OWNER");
            MANAGER_OWNER = vm.envAddress("LH_MNGR_OWNER");
            MANAGER_BEACON_OWNER = vm.envAddress("LH_MNGR_BEACON_OWNER");
            CFA_FORWARDED = createCFA_llhh();
            ///@custom:deploy-pool-implementatoin
            vars.poolImplemetation = createPoolImplementation(
                CFA_FORWARDED
            );
            console.log('POOL_IMPL_CREATED');
            ///@custom:deploy-project-registry-proxy
            (registryBeacon, registryProxy) = createRegistryProxied(
                VERSION,
                REGISTRY_OWNER,
                REGISTRY_BEACON_OWNER
            );
            console.log('SAFE',vars.safeImplementation);
            console.log('REGISTRY',address(registryProxy));
            console.log('POOL',vars.poolImplemetation);
            console.log('VERSION',vars.version);
            vars.projectRegistry = address(registryProxy);
        } else {
            vars.safeImplementation = vm.envAddress("SAFE_IMPL");
            REGISTRY_OWNER = vm.envAddress("DEPLOY_REG_OWNER");
            REGISTRY_BEACON_OWNER = vm.envAddress("DEPLOY_REG_BEACON_OWNER");
            CFA_FORWARDED = vm.envAddress("DEPLOY_CFA_FORWARDED");
            MANAGER_OWNER = vm.envAddress("DEPLOY_MNGR_OWNER");
            MANAGER_BEACON_OWNER = vm.envAddress("DEPLOY_MNGR_BEACON_OWNER");
            ///@custom:deploy-pool-implementatoin
            mContructor.poolImplemetation = createPoolImplementation(
                CFA_FORWARDED
            );
            ///@custom:deploy-project-registry-proxy
            (registryBeacon, registryProxy) = createRegistryProxied(
                VERSION,
                REGISTRY_OWNER,
                REGISTRY_BEACON_OWNER
            );
            vars.projectRegistry = address(registryProxy);
        }

        return vars;
    }
}
