// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "./SetUpManager.t.sol";

contract PoolDummy {}

contract ProjectRegistryDummy {}
// forge test --match-contract ManagerInitialize -vvvv
contract ManagerInitialize is ManagerSetup {
    // address bOwnr_=makeAddr('bOwner');
    /**
     * @custom:ubeaconowner :=
     * address bOwnr_=makeAddr('bOwner')
     * 0x7a50CB979955F18AE69bC88e6BDF6fEF0E940FDe
     */

    constructor() ManagerSetup(0x7a50CB979955F18AE69bC88e6BDF6fEF0E940FDe) {}

    ManagerConstr mConstr;
    ManagerInit mInit;

    function setUp() external {
        address safeImpl = gSafeBuild.getSafeImplementation();
        mConstr = ManagerConstr(
            1,
            address(new PoolDummy()),
            safeImpl,
            address(new ProjectRegistryDummy())
        );
        mInit = ManagerInit(makeAddr("mOwner"));
    }

    function test_initManager() external {
        createManagerProxy(mConstr, mInit);
        // vm.expectRevert("InvalidInitialization");
        vm.expectRevert();
        Manager(address(managerProxy)).initialize(mInit.newOwner);
    }
}
