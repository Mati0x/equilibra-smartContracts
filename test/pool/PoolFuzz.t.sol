// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./SetUpPool.t.sol";
import {GovTokenMock, StableMock} from "../mocks/mocks.sol";
import {ProjectSupport} from "../../src/structs.sol";
import "@oz/utils/Strings.sol";

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

    constructor() {
        initValues = _initValues();
    }

    function setUp() external {
        (poolBeacon, poolProxy) = _buildImplAndProxy(false, "", initValues);
        emit log_named_address("POOL_BEACON", address(poolBeacon));
        emit log_named_address("POOL_PROXY", address(poolProxy));
        poolC = Pool(address(poolProxy));
    }

    function test_publicVars() external {
        emit log_named_address("CFA_FORWARDED", poolC.cfaForwarder());
        emit log_named_address("MANAGER", poolC.manager());
        emit log_named_address("PROJECT_LIST", poolC.projectList());
        emit log_named_address("FUNDING_TKN", poolC.fundingToken());
        emit log_named_address("GOV_TOKEN", address(poolC.govToken()));
    }

    // forge test --match-contract PoolFuzz --match-test test_stake -vvvv
    function test_stake(uint128 _amount, address _participant) external {
        vm.assume(_amount > 0);
        vm.assume(_participant != address(0));
        govmock.mint(_participant, _amount);
        vm.startPrank(_participant);
        vm.expectRevert(); // no enough allowence
        poolC.stakeGov(_amount);
        govmock.approve(address(poolC), _amount);
        poolC.stakeGov(_amount);
        vm.stopPrank();
    }

    uint UNIT = 1e12;

    // forge test --match-contract PoolFuzz --match-test test_support -vvvv
    function test_support(uint _senderSeed, uint16[] memory _factors) external {
        vm.assume(_factors.length < 25);
        for (uint i = 0; i < _factors.length; i++) {
            _factors[i] = uint16(bound(_factors[i], 100, type(uint16).max));
        }
        ProjectSupport[] memory _supports;

        address _sender = makeAddr(Strings.toString(_senderSeed));
        vm.label(_sender, "PARTICIPANT0");

        uint sum;
        if (_factors.length == 0) {
            _supports = new ProjectSupport[](5);
            _supports[0] = ProjectSupport(0, UNIT);
            _supports[1] = ProjectSupport(1, 2 * UNIT);
            _supports[2] = ProjectSupport(2, 3 * UNIT);
            _supports[3] = ProjectSupport(3, 4 * UNIT);
            _supports[4] = ProjectSupport(4, 5 * UNIT);
            sum = UNIT * 16;
        } else if (_factors.length == 1) {
            _supports = new ProjectSupport[](1);
            _supports[0] = ProjectSupport(_factors[0], (UNIT * _factors[0]));
            sum = UNIT * _factors[0];
        } else {
            _supports = new ProjectSupport[](_factors.length);
            for (uint i = 0; i < _factors.length; i++) {
                _supports[i] = ProjectSupport(
                    _factors[i],
                    (UNIT * _factors[i])
                );
                sum += _factors[i];
            }
            sum *= UNIT;
        }
        ProjectSupport[] memory _zeroL = new ProjectSupport[](0);
        ProjectSupport[] memory _exceedLimit = new ProjectSupport[](50);

        govmock.mint(_sender, sum + 1);

        //Invalid legth [0,25 <]
        // Project no exists
        // Not enough staked
        vm.startPrank(_sender);
        vm.expectRevert(); // no enough allowence
        poolC.supportProjects(_supports);
        govmock.approve(address(poolC), sum);
        poolC.stakeGov(sum);
        vm.expectRevert(); // zero length
        poolC.supportProjects(_zeroL);
        vm.expectRevert(); // exceed limit
        poolC.supportProjects(_exceedLimit);
        // Success
        poolC.supportProjects(_supports);
        vm.stopPrank();
    }

    // forge test --match-contract PoolFuzz --match-test test_stakeAndSupport -vvvv
    function test_stakeAndSupport(
        uint _senderSeed,
        uint16[] memory _factors
    ) external {
        vm.assume(_factors.length < 25);
        _stakeAndSupport(_senderSeed, _factors);
    }

    // forge test --match-contract PoolFuzz --match-test test_unstake -vvvv

    function test_unstake(uint128 _amount, address _participant) external {
        vm.assume(_amount > 0);
        vm.assume(_participant != address(0));
        govmock.mint(_participant, _amount);

        vm.startPrank(_participant);
        vm.expectRevert(); //no enough staked
        poolC.unstakeGov(_amount);
        govmock.approve(address(poolC), _amount);
        poolC.stakeGov(_amount);
        poolC.unstakeGov(_amount);
        vm.stopPrank();
    }
    ///@custom:retomar-despues
    // // forge test --match-contract PoolFuzz --match-test test_unsupport -vvvv
    function test_unsupport(
        uint _senderSeed,
        uint16[] memory _factors
    ) external {
        address _prankist = makeAddr("PRANKIST");
        vm.assume(_factors.length < 25);
        (
            address _sender,
            ProjectSupport[] memory _participantSupport
        ) = _stakeAndSupport(_senderSeed, _factors);
        ProjectSupport[] memory _zeroL = new ProjectSupport[](0);
        ProjectSupport[] memory _p1 = new ProjectSupport[](1);
        ProjectSupport[] memory _exceedLimit = new ProjectSupport[](50);
        vm.prank(_prankist);
        vm.expectRevert(); //EXCEEDS_PARTICIPANT_BALANCE
        poolC.unsupportProjects(_participantSupport);

        vm.prank(_sender);
        vm.expectRevert(); //WRONG_AMOUNT_OF_PROJECTS
        poolC.unsupportProjects(_zeroL);
        vm.prank(_sender);
        vm.expectRevert(); //WRONG_AMOUNT_OF_PROJECTS
        poolC.unsupportProjects(_exceedLimit);
        if (_participantSupport.length != 1) {
            if (_participantSupport[0].projectId!=_participantSupport[1].projectId) {
                _participantSupport[0].deltaSupport += 50;
                _participantSupport[1].deltaSupport -= 50;
                vm.prank(_sender);
                vm.expectRevert(); //SUPPORT_UNDERFLOW
                poolC.unsupportProjects(_participantSupport);
            }else console.log('SE_REPITEN_IDS_Y_NO_REVIERTE');
        }

        _p1[0].projectId=_participantSupport[0].projectId;
        _p1[0].deltaSupport=_participantSupport[0].deltaSupport-50;

        vm.prank(_sender); //success
        poolC.unsupportProjects(_p1);

        /**
         * Not enough staked             [ok]
         * Invalid support length (0,50) [ok]
         * Wrong support amount (> supported)
         * Success
         */
    }

    function test_activateProject() external{
        
    }
    function test_sync() external{
        
    }
    

    function _stakeAndSupport(
        uint _senderSeed,
        uint16[] memory _factors
    ) internal returns (address, ProjectSupport[] memory) {
        for (uint i = 0; i < _factors.length; i++) {
            _factors[i] = uint16(bound(_factors[i], 100, type(uint16).max));
        }
        ProjectSupport[] memory _supports;

        address _sender = makeAddr(Strings.toString(_senderSeed));
        vm.label(_sender, "PARTICIPANT0");

        uint sum;
        if (_factors.length == 0) {
            _supports = new ProjectSupport[](5);
            _supports[0] = ProjectSupport(0, (UNIT));
            _supports[1] = ProjectSupport(1, (2 * UNIT));
            _supports[2] = ProjectSupport(2, (3 * UNIT));
            _supports[3] = ProjectSupport(3, (4 * UNIT));
            _supports[4] = ProjectSupport(4, (5 * UNIT));
            sum = UNIT * 16;
        } else if (_factors.length == 1) {
            _supports = new ProjectSupport[](1);
            _supports[0] = ProjectSupport(_factors[0], (UNIT * _factors[0]));
            sum = UNIT * _factors[0];
        } else {
            _supports = new ProjectSupport[](_factors.length);
            for (uint i = 0; i < _factors.length; i++) {
                _supports[i] = ProjectSupport(
                    _factors[i],
                    (UNIT * _factors[i])
                );
                sum += _factors[i];
            }
            sum *= UNIT;
        }
        ProjectSupport[] memory _zeroL = new ProjectSupport[](0);
        ProjectSupport[] memory _exceedLimit = new ProjectSupport[](50);

        govmock.mint(_sender, sum + 1);

        //Invalid legth [0,25 <]
        // Project no exists
        // Not enough staked
        vm.startPrank(_sender);
        vm.expectRevert(); // no enough allowence
        poolC.stakeAndSupport(sum, _supports);
        govmock.approve(address(poolC), sum);
        vm.expectRevert(); // zero length
        poolC.stakeAndSupport(sum, _zeroL);
        vm.expectRevert(); // exceed limit
        poolC.stakeAndSupport(sum, _exceedLimit);
        // Success
        poolC.stakeAndSupport(sum, _supports);
        vm.stopPrank();
        return (_sender, _supports);
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
     * Stake:               [ok]
     * - no allowence
     * supportProjects      [ok]
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
