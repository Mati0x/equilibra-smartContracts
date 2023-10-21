//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./SetUpManager.t.sol";
import '@oz/utils/Strings.sol';
import {OwnableUpgradeable} from "@oz-upgradeable/access/OwnableUpgradeable.sol";
import "../../src/ProjectRegistry.sol";
import {Pool} from "../../src/pool/Pool.sol";
import {PoolInitParams, SafeSetUp} from "../../src/structs.sol";

import {StableMock} from "../mocks/StableMock.sol";
import {GovTokenMock} from "../mocks/GovTokenMock.sol";
// forge test --match-contract ManagerFuzzTest -vvvv
contract CFADummy {}

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
   

    // forge test --match-contract ManagerFuzzTest --match-test test_createPool -vvvv
    uint UNIT=1e18;

    function test_createPool(uint32 _senderSeed,uint16 _seed2,uint8[4] memory formulaParams) external{
        vm.assume(_senderSeed!=0);
        vm.assume(_seed2!=0);
        
        string memory _listName=string.concat('LIST_#',Strings.toString(_seed2));

        address _listOwner=makeAddr(Strings.toString(uint(_seed2)));
        address _sender=makeAddr(Strings.toString(_senderSeed));
        vm.label(_sender,'SENDER');
        vm.label(_listOwner,'LIST_OWNER');

        for (uint i = 0; i < 4; i++) {
            vm.assume(formulaParams[i]!=0);
        }
        address fundingToken = address(new StableMock(["USDC_MOCK", "mUSD"]));
        address govToken = address(new GovTokenMock(["EQUI_DAO", "$EQ"]));
        Manager mngr = Manager(address(managerProxy));
        
        vm.prank(_sender);
        address list=mngr.createProjectList(_listOwner,_listName);

        PoolInitParams memory initPool;
        initPool.addr=[makeAddr('PoolOwner'),makeAddr('Manager'),fundingToken,list,govToken];
        initPool.fParams[0]=formulaParams[0]*UNIT;
        initPool.fParams[1]=formulaParams[1]*UNIT;
        initPool.fParams[2]=formulaParams[2]*UNIT;
        initPool.fParams[3]=formulaParams[3]*UNIT;


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
    // forge test --match-contract ManagerFuzzTest --match-test test_createMultisigAndPool -vvvv
    function test_createMultisigAndPool(uint32 _senderSeed,uint16 _seed2,uint8[4] memory _formulaParams,uint8[5] memory _safeParams) external{
        vm.assume(_senderSeed!=0);
        vm.assume(_seed2!=0);
        
        string memory _listName=string.concat('LIST_#',Strings.toString(_seed2));

        address _listOwner=makeAddr(Strings.toString(uint(_seed2)));
        address _sender=makeAddr(Strings.toString(_senderSeed));
        vm.label(_sender,'SENDER');
        vm.label(_listOwner,'LIST_OWNER');

        for (uint i = 0; i < 4; i++) {
            vm.assume(_formulaParams[i]!=0);
        }
        address fundingToken = address(new StableMock(["USDC_MOCK", "mUSD"]));
        address govToken = address(new GovTokenMock(["EQUI_DAO", "$EQ"]));
        Manager mngr = Manager(address(managerProxy));
        
        vm.prank(_sender);
        address list=mngr.createProjectList(_listOwner,_listName);

        address[] memory _owns=new address[](5);
        for (uint i = 0; i < _safeParams.length; i++) {
            _owns[i]=makeAddr(Strings.toString(_safeParams[i]));
        }
        SafeSetUp memory initSafe;
        initSafe._owners=_owns;
        initSafe._threshold=bound(initSafe._threshold,1,5);
        PoolInitParams memory initPool;
        initPool.addr=[makeAddr('PoolOwner'),makeAddr('Manager'),fundingToken,list,govToken];
        initPool.fParams[0]=_formulaParams[0]*UNIT;
        initPool.fParams[1]=_formulaParams[1]*UNIT;
        initPool.fParams[2]=_formulaParams[2]*UNIT;
        initPool.fParams[3]=_formulaParams[3]*UNIT;


        // paused (revert)
        vm.prank(mngr.owner());
        mngr.pause();
        vm.prank(makeAddr('PRANKIST'));
        vm.expectRevert();
        mngr.createPoolMultiSig(initSafe,initPool);
        // unpaused (success)
        vm.prank(mngr.owner());
        mngr.unpause();
        vm.prank(makeAddr('PRANKIST'));
        mngr.createPoolMultiSig(initSafe,initPool);

    }
    /**
     * EXTERNAL_FUNCTIONS:=
     * 
     * initialize   
     * createProjectList
     * createPoolMultiSig
     * createPool
     * 
     * VIEW_FUNCTIONS:=
     *
     * isPool
     * isList
     * isMultiSig
     * getAddressInfo
     * isSafeCustomizationAllowed
     * pause
     * unpause
     * implementation
     * poolImplementation
     * safeImplementation
     */
}