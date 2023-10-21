// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import './SetUpPool.t.sol';
import{StableMock,GovTokenMock}from '../mocks/mocks.sol';
// forge test --match-contract InitPool
contract InitPool is SetUpPool {

    PoolInitValues initVals;
    ManagerDummy mDummy;
    GovTokenMock govmock;
    StableMock stablemock;
    constructor() {
        initVals=_initValues();
    }

    function _initValues() internal returns (PoolInitValues memory) {
        poolOwner=makeAddr('pOWNER');
        mDummy= new ManagerDummy();
        govmock= new GovTokenMock(['EQUI_DAO','EQ']);
        stablemock= new StableMock(['USDC_MOCK','mUSD']);
        address listMock=makeAddr('listMOCK');

        FormulaParams memory NEW_FORMULA_PARAMS = FormulaParams({decay: 1000, drop: 1001, maxFlow: 1002, minStakeRatio: 1003});
        PoolInitValues memory _initVals=PoolInitValues(
            [poolOwner,address(mDummy),address(stablemock),listMock,address(govmock)],NEW_FORMULA_PARAMS
        );
        return _initVals;
    }

    function test_initPool_success() external{
        _buildImplAndProxy(false,'',initVals);
    }
    function test_initPool_fail_reINIT() external{
       (,BeaconProxy _poolPr)=_buildImplAndProxy(false,'',initVals);
        //    
        vm.expectRevert();
        Pool(address(_poolPr)).initialize(initVals.addresses,initVals.params);
        
    }

    function test_initPool_fail_zeroCases() external{
        PoolInitValues memory zeroOwner=initVals;
        zeroOwner.addresses[0]=address(0);
        PoolInitValues memory zeroManager=initVals;
        zeroManager.addresses[1]=address(0);
        PoolInitValues memory zeroFundinig=initVals;
        zeroFundinig.addresses[2]=address(0);
        PoolInitValues memory zeroList=initVals;
        zeroList.addresses[3]=address(0);
        PoolInitValues memory zeroGov=initVals;
        zeroGov.addresses[4]=address(0);
        /**
         * (bool,PoolInitValues )
         * bool:= if expect reverts
         * 
         * PoolInitValues := init values (address[5], FormulaParams)
         * 
         */
        _buildImplAndProxy(true,'ZER0_OWNER',zeroOwner);
        _buildImplAndProxy(true,'ZER0_MNGR',zeroManager);
        _buildImplAndProxy(true,'ZER0_FUNDING',zeroFundinig);
        _buildImplAndProxy(true,'ZER0_LIST',zeroList);
        _buildImplAndProxy(true,'ZER0_GOV',zeroGov);

    }
    
}
