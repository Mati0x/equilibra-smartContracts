// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './SetUpPool.t.sol';
import{GovTokenMock,StableMock}from '../mocks/mocks.sol';
import {ProjectSupport}from'../../src/structs.sol';

contract ListMock {
    struct Project {
        address admin;
        address beneficiary;
        bytes contenthash;
    }
    Project pr;

    constructor(address[2] memory _prAddr, bytes memory _content) {
        pr = Project(_prAddr[0], _prAddr[1], _content);
    }

    function projectExists(uint _id) external pure returns (bool) {
        _id;
        return true;
    }

    function getProject(
        uint256 _projectId
    ) external view returns (Project memory) {
        _projectId;
        return pr;
    }
}
// forge test --match-contract PoolFuzz
contract PoolFuzz is SetUpPool {
    Pool poolC;
    PoolInitValues initValues;
    ManagerDummy mDummy;
    GovTokenMock govmock;
    StableMock stablemock;

    constructor(){
        initValues=_initValues();
    }
    function setUp() external {
       (poolBeacon,poolProxy)= _buildImplAndProxy(false,'',initValues);
       emit log_named_address('POOL_BEACON',address(poolBeacon));
       emit log_named_address('POOL_PROXY',address(poolProxy));
       poolC=Pool(address(poolProxy));
    }
    function test_publicVars() external   {
        emit log_named_address('CFA_FORWARDED',poolC.cfaForwarder());
        emit log_named_address('MANAGER',poolC.manager());
        emit log_named_address('PROJECT_LIST',poolC.projectList());
        emit log_named_address('FUNDING_TKN',poolC.fundingToken());
        emit log_named_address('GOV_TOKEN',address(poolC.govToken()));
    }
    // forge test --match-contract PoolFuzz --match-test test_stake -vvvv
    function test_stake(uint128 _amount,address _participant)external {
        vm.assume(_amount>0);
        vm.assume(_participant!=address(0));
        govmock.mint(_participant,_amount);
        vm.startPrank(_participant);
        vm.expectRevert();// no enough allowence
        poolC.stakeGov(_amount);
        govmock.approve(address(poolC),_amount);
        poolC.stakeGov(_amount);
        vm.stopPrank();
    }
    function test_unstake(uint128 _amount,address _participant)external {
        vm.assume(_amount>0);
        vm.assume(_participant!=address(0));
        govmock.mint(_participant,_amount);

        vm.startPrank(_participant);
        vm.expectRevert();//no enough staked
        poolC.unstakeGov(_amount);
        govmock.approve(address(poolC),_amount);
        poolC.stakeGov(_amount);
        poolC.unstakeGov(_amount);
        vm.stopPrank();
    }
    // forge test --match-contract PoolFuzz --match-test test_support -vvvv
    function test_support(uint128 _amount,address _participant,ProjectSupport[] calldata _projectSupports)external {
        vm.assume(_amount>0);

        vm.assume(_participant!=address(0));
        vm.assume(_projectSupports.length<25 && _projectSupports.length>0);
        uint sum;
        for (uint i = 0; i < _projectSupports.length; i++) {
            vm.assume(uint(_projectSupports[i].deltaSupport)>0&& uint(_projectSupports[i].deltaSupport)<type(uint40).max);
            sum+=uint(_projectSupports[i].deltaSupport);
        }
        ProjectSupport[] memory _zeroL=new ProjectSupport[](0);
        ProjectSupport[] memory _exceedLimit=new ProjectSupport[](50);
        uint toStake;
        if (_amount<sum) {
            toStake=sum;
            govmock.mint(_participant,sum +1);
        }else{
            toStake=_amount;
            govmock.mint(_participant,_amount +1);
        }

        //Invalid legth [0,25 <]
        // Project no exists
        // Not enough staked
        vm.startPrank(_participant);
        vm.expectRevert();// no enough allowence
        poolC.supportProjects(_projectSupports);
        govmock.approve(address(poolC),toStake);
        poolC.stakeGov(toStake);
        vm.expectRevert();// zero length
        poolC.supportProjects(_zeroL);
        vm.expectRevert();// exceed limit
        poolC.supportProjects(_exceedLimit);
        // Success
        poolC.supportProjects(_projectSupports);
        vm.stopPrank();
    }
    
    function _initValues() internal returns (PoolInitValues memory) {
        poolOwner = makeAddr("pOWNER");
        mDummy = new ManagerDummy();
        govmock = new GovTokenMock(["EQUI_DAO", "EQ"]);
        stablemock = new StableMock(["USDC_MOCK", "mUSD"]);
        address listMock = address(
            new ListMock(
                [makeAddr("listAdmon"), makeAddr("listBenef")],
                type(ManagerDummy).creationCode
            )
        );

        FormulaParams memory NEW_FORMULA_PARAMS = FormulaParams({
            decay: 1000,
            drop: 1001,
            maxFlow: 1002,
            minStakeRatio: 1003
        });
        PoolInitValues memory _initVals = PoolInitValues(
            [
                poolOwner,
                address(mDummy),
                address(stablemock),
                listMock,
                address(govmock)
            ],
            NEW_FORMULA_PARAMS
        );
        return _initVals;
    }



    /**
     * Stake:
     * - no allowence
     * supportProjects
     * - no enough freestake
     * StakeAndSupport:
     * - no allowence 
     * - no enough freestake
     * activateProject:
     * - no exists
     * - already active
     * sync:
     * 
     * formula:
     * invalid variables
     * 
     * getters:
     * getProjectSupport
     * getParticipantSupport
     * getTotalSupport
     * getTotalParticipantSupport
     * getCurrentRate
     * getTargetRate
     */
}