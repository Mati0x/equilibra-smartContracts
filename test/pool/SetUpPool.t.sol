// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import{ Pool}from  "../../src/pool/Pool.sol";
// import "../../src/PoolV1.sol";
import {BeaconProxy} from "@oz/proxy/beacon/BeaconProxy.sol";
import {UpgradeableBeacon} from "@oz/proxy/beacon/UpgradeableBeacon.sol";

import "../utils/Utils.sol";

// import {UpgradeScripts} from "upgrade-scripts/src/UpgradeScripts.sol";
contract CFADummy {
}
contract ManagerDummy {
    constructor() {
        
    }
    function isList(address _addr) external pure returns (bool) {
        if (_addr==address(0)) {
            return false;
        }
        return true;
    }
}

struct PoolInitValues {
    address[5] addresses;
    FormulaParams params;
}

// forge test --match-contract SetUpPool -vvvv
abstract contract SetUpPool is Utils_Test {
    UpgradeableBeacon public beacon;

    
     /**
     * @custom:info Aca va la data de Pool (constructor& initialize)
     */
    CFADummy cfaDummy;
    Pool poolImpl;
    UpgradeableBeacon poolBeacon;
    BeaconProxy poolProxy;
    address poolOwner;
    address poolBeaconOwner=makeAddr('pBCNOWNER');
    bytes initPoolData;

    function _constructorInit(
        address _cfa
    ) internal {
        poolImpl= new Pool(_cfa);
    }

    function _buildImplAndProxy(bool exRev,string memory revertInfo,PoolInitValues memory _poolInitVars)internal   returns (UpgradeableBeacon, BeaconProxy) {
        cfaDummy= new CFADummy();
        poolImpl= new Pool(address(cfaDummy));

        initPoolData = abi.encodeWithSignature(
            "initialize(address[5],(uint256,uint256,uint256,uint256))",
            _poolInitVars.addresses,_poolInitVars.params.decay,_poolInitVars.params.drop,_poolInitVars.params.maxFlow,_poolInitVars.params.minStakeRatio
        );
        if(exRev){
            return expectRevertWhenCreatingBeaconProxy(address(poolImpl),poolBeaconOwner,initPoolData,revertInfo);
            
        }else{
            return createBeaconAndProxy(address(poolImpl),poolBeaconOwner,initPoolData);
        }
    }

    function test_constructorSuccess() external {
        cfaDummy= new CFADummy();
        _constructorInit(address(cfaDummy));
        assertEq(address(cfaDummy), poolImpl.cfaForwarder());
        // assertEq(manager,pool.manager());
    }

    function test_Constructor_cfaZero() external {
        vm.expectRevert("Zero CFA Forwarder");
        _constructorInit(address(0));
    }
}


