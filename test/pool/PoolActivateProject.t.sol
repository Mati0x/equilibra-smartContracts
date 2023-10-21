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

// forge test --match-contract PoolActiveProject
contract PoolActiveProject is SetUpPool {
    PoolInitValues initVals;
    ManagerDummy mDummy;
    GovTokenMock govmock;
    StableMock stablemock;

    constructor() {
        initVals = _initValues();
    }


    uint GOV_AMOUNT = 100;

    // forge test --match-contract PoolActiveProject --match-test test_activateProject -vvvv
    function test_activateProject() external {
        (, BeaconProxy _poolPr) = _buildImplAndProxy(false, "", initVals);
        address participant = makeAddr("participant");
        govmock.mint(participant, GOV_AMOUNT);
        vm.startPrank(participant);
        Pool(address(_poolPr)).activateProject(1);

        vm.stopPrank();
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

