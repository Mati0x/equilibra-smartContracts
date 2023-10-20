// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.17;

// import "forge-std/Test.sol";

// import{PoolV2 as Pool,FormulaParams}from  "../src/PoolV2.sol";
// // import "../../src/PoolV1.sol";
// import {BeaconProxy} from "@oz/proxy/beacon/BeaconProxy.sol";
// import {UpgradeableBeacon} from "@oz/proxy/beacon/UpgradeableBeacon.sol";

// import {ERC1967Proxy}from '@oz/proxy/ERC1967/ERC1967Proxy.sol';

// import {ManagerV2 as Manager}from '../src/ManagerV2.sol';
// import {ProjectRegistry} from '../src/ProjectRegistry.sol';
// import './mocks/GovTokenMock.sol';
// import './mocks/StableMock.sol';
// // import {UpgradeScripts} from "upgrade-scripts/src/UpgradeScripts.sol";
// contract DummyImpl {
// }
// contract MockManager {
//     UpgradeableBeacon public beacon;

//     mapping (address => bool) public isPool;
//     constructor(address _impl){
//         beacon = new UpgradeableBeacon(_impl, msg.sender);
//     }

//     function isList(address) external pure returns (bool) {
//         return true;
//     }

//     function createPool(
//         bytes calldata _initPayload
//     ) external returns (address pool_) {
//         pool_ = address(new BeaconProxy(address(beacon), _initPayload));
//         // Probar si funciona con la interfaz
//         // PoolV2(pool_).transferOwnership(msg.sender);
//         // Que cree una lista de forma automatica
//         // Que cree una SAFE

//         isPool[pool_] = true;

//         // emit PoolCreated(pool_);
//     }
// }

// // forge test --match-contract SetUpManager -vvvv
// contract SetUpManager is Test {
//     uint constant VERSION=1;
//     UpgradeableBeacon public beacon;

//     address internal cfaForwarder = makeAddr("cfaForwarder");
//     address internal manager = makeAddr("manager");
//     DummyImpl internal mockVersion= new DummyImpl();

//     Pool internal poolImpl;

//     ERC1967Proxy managerProxy;
//     string constant manInit= 'initialize(address,uint256)';
//     address managerProxyOwner=makeAddr('RProxy_Owner');
//     uint claimDuration= 15 days;
//     Manager internal managerImpl;
//     Manager internal managerProxyContract;

//     ERC1967Proxy registryProxy;
//     string constant regInit= 'initialize(address)';
//     address registryProxyOwner=makeAddr('RProxy_Owner');
//     ProjectRegistry internal registryImpl;

//     string constant poolInit='initialize(address,address,address,address,address,address,(uint,uint,uint,uint)';

//     GovTokenMock mockGov;
//     StableMock mockStable;

//     function _initImplementations() internal {
//         mockGov=new GovTokenMock(['EQUI_DAO','EQd']);
//         mockStable=new StableMock(['USDC_MOCK','mUSDC']);

//         registryImpl= new ProjectRegistry(VERSION);

//         registryProxy = new ERC1967Proxy(address(registryImpl),abi.encodeWithSignature(regInit,registryProxyOwner));


//         poolImpl= new Pool();
//         console.log(address(poolImpl));
        
//         managerImpl= new Manager(VERSION,address(poolImpl),address(registryProxy));

//         // managerImpl.beacon().upgradeTo(address(poolImpl));

//         managerProxy = new ERC1967Proxy(address(managerImpl),abi.encodeWithSignature(manInit,managerProxyOwner,claimDuration));
//         managerProxyContract=Manager(address(managerProxy));
//     }
//     // forge test --match-contract SetUpManager --match-test test_createPool -vvvv
//     function test_createPool() external {
//         _initImplementations();
//         // vm.assume(_poolOwner!=address(0));
//         address poolOwner=makeAddr('POOL_OWNER');
//         address projectList=managerProxyContract.createProjectList(makeAddr('PROJECT_LIST'),'LIST_0');
//         address beaconImpl= managerProxyContract.beacon().implementation();
//         console.log(beaconImpl);
//         assertEq(beaconImpl,address(poolImpl));
//         MockManager mockMNGR=new MockManager(address(poolImpl));

//         address poolNew=mockMNGR.createPool(abi.encodeWithSignature(poolInit,
//             address(mockStable),poolOwner,address(mockGov),projectList,cfaForwarder,address(managerProxy),FormulaParams(10 days,2,19290123456,25000000000000000)
//         ));
//         console.log(poolNew);
//     }
     
//     // forge test --match-contract SetUpManager --match-test test_initProxys -vvvv

//     function test_initProxys() external  {
//         _initImplementations();
//     }

//     function _constructorInit(
//         bool exRev,
//         address[2] memory _addressInit
//     ) internal {
//         poolImpl = new Pool();
//         if (!exRev) {
//             beacon = new UpgradeableBeacon(address(poolImpl), msg.sender);
//             vm.label(address(beacon), "PoolBeacon");
//         }
//     }

//     function test_constructorSuccess() external {
//         _constructorInit(false,[cfaForwarder, manager]);
//         assertEq(cfaForwarder, poolImpl.cfaForwarder());
//         assertEq(manager,poolImpl.manager());
//     }

//     function test_Constructor_managerZero() external {
//         // vm.expectRevert("Zero Manager");
//         vm.expectRevert();
//         _constructorInit(true,[cfaForwarder, address(0)]);
//     }

//     function test_Constructor_cfaZero() external {
//         vm.expectRevert("Zero CFA Forwarder");
//         _constructorInit(true,[address(0), manager]);
//     }
// }
