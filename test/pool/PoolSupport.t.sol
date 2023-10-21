// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./SetUpPool.t.sol";
import {ProjectSupport}from '../../src/structs.sol';
import {StableMock, GovTokenMock} from "../mocks/mocks.sol";
import '@oz/utils/Strings.sol';
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

// forge test --match-contract PoolSupport
contract PoolSupport is SetUpPool {
    PoolInitValues initVals;
    ManagerDummy mDummy;
    GovTokenMock govmock;
    StableMock stablemock;

    constructor() {
        initVals = _initValues();
    }

    

    uint GOV_AMOUNT = 100000;

    // forge test --match-contract PoolSupport --match-test test_stake -vvvv
    function test_stake() external {
        (, BeaconProxy _poolPr) = _buildImplAndProxy(false, "", initVals);
        address participant = makeAddr("participant");
        govmock.mint(participant, GOV_AMOUNT);
        vm.startPrank(participant);
        vm.expectRevert(); //No_allowence
        Pool(address(_poolPr)).stakeGov(GOV_AMOUNT);
        govmock.approve(address(_poolPr), GOV_AMOUNT);
        Pool(address(_poolPr)).stakeGov(GOV_AMOUNT);
        vm.stopPrank();
    }
    
    // forge test --match-contract PoolSupport --match-test test_stakeAndSupport -vvvv
    function test_stakeAndSupport() external {
        (, BeaconProxy _poolPr) = _buildImplAndProxy(false, "", initVals);
        ProjectSupport[] memory pr_=new ProjectSupport[](4);
        pr_[0]=ProjectSupport(0,25);
        pr_[1]=ProjectSupport(1,25);
        pr_[2]=ProjectSupport(2,25);
        pr_[3]=ProjectSupport(3,25);

        Pool _pool=Pool(address(_poolPr));
        uint[]memory ids_=new uint[](4);
        ids_[0]=0;
        ids_[1]=1;
        ids_[2]=2;
        ids_[3]=3;

        address participant = makeAddr("participant");
        govmock.mint(participant, GOV_AMOUNT);
        vm.startPrank(participant);
        vm.expectRevert(); //No_allowence
        _pool.stakeGov(GOV_AMOUNT);
        govmock.approve(address(_poolPr), GOV_AMOUNT);
        _pool.stakeAndSupport(GOV_AMOUNT,pr_);

        vm.stopPrank();

        _externalFunctions(_pool,ids_,participant);

    }
    
    function test_support() external {
        (, BeaconProxy _poolPr) = _buildImplAndProxy(false, "", initVals);
        ProjectSupport[] memory pr_=new ProjectSupport[](4);
        pr_[0]=ProjectSupport(0,25);
        pr_[1]=ProjectSupport(1,25);
        pr_[2]=ProjectSupport(2,25);
        pr_[3]=ProjectSupport(3,25);

        Pool _pool=Pool(address(_poolPr));
        uint[]memory ids_=new uint[](4);
        ids_[0]=0;
        ids_[1]=1;
        ids_[2]=2;
        ids_[3]=3;

        address participant = makeAddr("participant");
        govmock.mint(participant, GOV_AMOUNT);
        vm.startPrank(participant);
        govmock.approve(address(_poolPr), GOV_AMOUNT);
        _pool.stakeGov(GOV_AMOUNT);
        _pool.supportProjects(pr_);
        vm.stopPrank();

        _externalFunctions(_pool,ids_,participant);
    }

    // forge test --match-contract PoolSupport --match-test test_unstake -vvvv
    function test_unstake() external {
        (, BeaconProxy _poolPr) = _buildImplAndProxy(false, "", initVals);
        Pool _pool=Pool(address(_poolPr));
        address participant = makeAddr("participant");
        govmock.mint(participant, GOV_AMOUNT);
        vm.startPrank(participant);
        vm.expectRevert(); //No_enough_staked
       _pool.unstakeGov(GOV_AMOUNT);
        govmock.approve(address(_poolPr), GOV_AMOUNT);
       _pool.stakeGov(GOV_AMOUNT);
       _pool.unstakeGov(GOV_AMOUNT);
        vm.stopPrank();

    }
    // forge test --match-contract PoolSupport --match-test test_unsupport -vvvv
    function test_unsupport() external {
        (, BeaconProxy _poolPr) = _buildImplAndProxy(false, "", initVals);
        ProjectSupport[] memory pr_=new ProjectSupport[](4);
        pr_[0]=ProjectSupport(0,25);
        pr_[1]=ProjectSupport(1,25);
        pr_[2]=ProjectSupport(2,25);
        pr_[3]=ProjectSupport(3,25);

        Pool _pool=Pool(address(_poolPr));
        uint[]memory ids_=new uint[](4);
        ids_[0]=0;
        ids_[1]=1;
        ids_[2]=2;
        ids_[3]=3;

        address participant = makeAddr("participant");
        govmock.mint(participant, GOV_AMOUNT);
        vm.startPrank(participant);
        govmock.approve(address(_poolPr), GOV_AMOUNT);
        _pool.stakeGov(GOV_AMOUNT);
        _pool.supportProjects(pr_);
        vm.stopPrank();
        vm.prank(participant);
        _pool.unsupportProjects(pr_);
        _externalFunctions(_pool,ids_,participant);
    }
   
    // forge test --match-contract PoolSupport --match-test test_unstakeAndUnsupport -vvvv
    function test_unstakeAndUnsupport() external {
        (, BeaconProxy _poolPr) = _buildImplAndProxy(false, "", initVals);
        ProjectSupport[] memory pr_=new ProjectSupport[](4);
        pr_[0]=ProjectSupport(0,25);
        pr_[1]=ProjectSupport(1,25);
        pr_[2]=ProjectSupport(2,25);
        pr_[3]=ProjectSupport(3,25);

        Pool _pool=Pool(address(_poolPr));
        uint[]memory ids_=new uint[](4);
        ids_[0]=0;
        ids_[1]=1;
        ids_[2]=2;
        ids_[3]=3;

        address participant = makeAddr("participant");
        govmock.mint(participant, GOV_AMOUNT);
        vm.startPrank(participant);
        govmock.approve(address(_poolPr), GOV_AMOUNT);
        _pool.stakeAndSupport(GOV_AMOUNT,pr_);
        vm.stopPrank();
        _externalFunctions(_pool,ids_,participant);
        vm.prank(participant);
        _pool.unstakeAndUnsupport(GOV_AMOUNT,pr_);
        _externalFunctions(_pool,ids_,participant);



    }

    function _externalFunctions(Pool _pool,uint[] memory _ids,address _participant)internal  {
        assert(_ids.length>1);
        (uint _totalStaked,uint _freeStake)=_pool.getTotalParticipantSupport(_participant);

        emit log_named_uint('Participants amount stake',_totalStaked);
        emit log_named_uint('Participants free stake',_freeStake);

        for (uint i = 0; i < _ids.length; i++) {
            string memory key_=string.concat('Projects #',Strings.toString(_ids[i]));
            emit log_named_uint(string.concat(key_,'-CurretnRate'),_pool.getCurrentRate(_ids[i]));
            emit log_named_uint(string.concat(key_,'-TargetRate'),_pool.getTargetRate(_ids[i]));
            emit log_named_uint(string.concat(key_,'-ParticipantSupport'),_pool.getParticipantSupport(_ids[i],_participant));
        }

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
}

/**
 * Armar los scripts para subir la gilada
 * Subir a mantle testnet
 * Subimos a op testnet (si hay superfluid)
 * 
 * 
 */
