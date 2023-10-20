// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "./SetUpManager.t.sol";
import "../../src/ProjectRegistry.sol";

contract PoolDummy {}

// forge test --match-contract ManagerNewList -vvvv
contract ManagerNewList is ManagerSetup {
    // address bOwnr_=makeAddr('bOwner');
    /**
     * @custom:ubeaconowner :=
     * address bOwnr_=makeAddr('bOwner')
     * 0x7a50CB979955F18AE69bC88e6BDF6fEF0E940FDe
     */

    constructor() ManagerSetup(0x7a50CB979955F18AE69bC88e6BDF6fEF0E940FDe) {}

    uint VERSION = 1;

    ProjectRegistry regImpl;
    UpgradeableBeacon registryBeacon;
    BeaconProxy registryProxy;
    address registryOwner;
    address registryBeaconOwner;

    ManagerConstr mConstr;
    ManagerInit mInit;

    function setUp() external {
        regImpl = new ProjectRegistry(VERSION);
        registryOwner = makeAddr("regOWNER");
        registryBeaconOwner = makeAddr("regBCNOWNER");

        bytes memory initRegistry = abi.encodeWithSignature(
            "initialize(address)",
            registryOwner
        );
        (registryBeacon, registryProxy) = createBeaconAndProxy(
            address(regImpl),
            registryBeaconOwner,
            initRegistry
        );

        address safeImpl = gSafeBuild.getSafeImplementation();
        mConstr = ManagerConstr(
            1,
            address(new PoolDummy()),
            safeImpl,
            address(registryProxy)
        );
        mInit = ManagerInit(makeAddr("mOwner"));
        createManagerProxy(mConstr, mInit);
    }

    function test_createProjectList() external {
        // vm.expectRevert("InvalidInitialization");
        // vm.expectRevert();
        Manager mngr = Manager(address(managerProxy));
        address listOw=makeAddr("List_Owner");
        address list_ = mngr.createProjectList(listOw
            ,
            "LIST_ZER0"
        );
        assertEq(mngr.isList(list_), true);
        assertEq(OwnableUpgradeable(list_).owner(),listOw);
    }
}
