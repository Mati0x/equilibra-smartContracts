// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./SetUpManager.t.sol";
import "../../src/ProjectRegistry.sol";
import {OwnableUpgradeable} from "@oz-upgradeable/access/OwnableUpgradeable.sol";
import {Pool} from "../../src/pool/Pool.sol";

contract CFADummy {}
import {StableMock} from "../mocks/StableMock.sol";
import {GovTokenMock} from "../mocks/GovTokenMock.sol";
import {PoolInitParams, SafeSetUp} from "../../src/structs.sol";
// forge test --match-contract ManagerFuzzTest -vvvv

contract ManagerFuzzTest is ManagerSetup {
    constructor() ManagerSetup(0x7a50CB979955F18AE69bC88e6BDF6fEF0E940FDe) {}

    uint VERSION = 1;
    /**
     * @custom:info Aca va la data de projectRegistry
     */
    ProjectRegistry regImpl;
    UpgradeableBeacon registryBeacon;
    BeaconProxy registryProxy;
    address registryOwner;
    address registryBeaconOwner;
    bytes initRegistry;
    /**
     * @custom:info Aca va la data de Manager (constructor& initialize)
     */
    ManagerConstr mConstr;
    ManagerInit mInit;
    /**
     * @custom:info Aca va la data de Pool (constructor& initialize)
     */
    CFADummy cfaDummy;
    Pool poolImpl;
    UpgradeableBeacon poolBeacon;
    BeaconProxy poolProxy;
    address poolOwner;
    address poolBeaconOwner;
    bytes initPoolData;

    function setUp() external {
        regImpl = new ProjectRegistry(VERSION);
        registryOwner = makeAddr("regOWNER");
        registryBeaconOwner = makeAddr("regBCNOWNER");

        initRegistry = abi.encodeWithSignature(
            "initialize(address)",
            registryOwner
        );
        (registryBeacon, registryProxy) = createBeaconAndProxy(
            address(regImpl),
            registryBeaconOwner,
            initRegistry
        );
        cfaDummy = new CFADummy();
        poolImpl = new Pool(address(cfaDummy));
        poolOwner = makeAddr("poolOWNER");
        poolBeaconOwner = makeAddr("poolBCNOWNER");

        address safeImpl = gSafeBuild.getSafeImplementation();
        mConstr = ManagerConstr(
            1,
            address(poolImpl),
            safeImpl,
            address(registryProxy)
        );
        mInit = ManagerInit(makeAddr("mOwner"));
        createManagerProxy(mConstr, mInit);
    }

    function test_externalFuncs(address _addr) external view {
        Manager mngr = Manager(address(managerProxy));
        mngr.version();
        mngr.projectRegistry();
        mngr.poolBeacon();
        mngr.safeBeacon();
        mngr.implementation();
        mngr.poolImplementation();
        mngr.safeImplementation();
        mngr.isSafeCustomizationAllowed();
        mngr.isPool(_addr);
        mngr.isList(_addr);
        mngr.isMultisig(_addr);
        mngr.getAddressInfo(_addr);
    }
    struct ProjectListCreation{
        address owner;
        string name;
    }

    function test_createProjectList(ProjectListCreation memory _prListCreation,address _pranker)external  {
        vm.assume(_prListCreation.owner!=address(0));
        vm.assume(_pranker!=address(0));

        Manager mngr = Manager(address(managerProxy));

        vm.prank(_pranker);
        mngr.createProjectList(_prListCreation.owner,_prListCreation.name);

    }
    struct PoolCreationData{
        uint[4] formulaParams;
        ProjectListCreation listData;
    }

    // forge test --match-contract ManagerFuzzTest --match-test test_createPool -vvvv

    function test_createPool(address _sender,PoolCreationData memory _poolInitSetup) external{
        for (uint i = 0; i < _poolInitSetup.formulaParams.length; i++) {
            vm.assume(_poolInitSetup.formulaParams[i]>=1e18);
        }
        address fundingToken = address(new StableMock(["USDC_MOCK", "mUSD"]));
        address govToken = address(new GovTokenMock(["EQUI_DAO", "$EQ"]));
        Manager mngr = Manager(address(managerProxy));
        vm.assume(_poolInitSetup.listData.owner!=address(0));
        vm.assume(_sender!=address(0));
        vm.prank(_sender);
        address list=mngr.createProjectList(_poolInitSetup.listData.owner,_poolInitSetup.listData.name);

        PoolInitParams memory initPool;
        initPool.addr=[makeAddr('PoolOwner'),makeAddr('Manager'),fundingToken,list,govToken];
        initPool.fParams=_poolInitSetup.formulaParams;

        // paused (revert)
        vm.prank(mngr.owner());
        mngr.pause();
        vm.prank(makeAddr('PRANKIST'));
        vm.expectRevert();
        mngr.createPool(initPool);
        // unpaused (success)
        vm.prank(mngr.owner());
        mngr.unpause();
        vm.prank(makeAddr('PRANKIST'));
        mngr.createPool(initPool);

    }
}