// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "./SetUpManager.t.sol";
import "../../src/ProjectRegistry.sol";
import {OwnableUpgradeable} from "@oz-upgradeable/access/OwnableUpgradeable.sol";
import { Pool} from "../../src/pool/Pool.sol";


contract CFADummy {

}
import {StableMock} from "../mocks/StableMock.sol";
import {GovTokenMock} from "../mocks/GovTokenMock.sol";
import {PoolInitParams, SafeSetUp} from "../../src/structs.sol";


// forge test --match-contract ManagerNewPool_ReadFuncs -vvvv
contract ManagerNewPool_ReadFuncs is ManagerSetup {
    // address bOwnr_=makeAddr('bOwner');
    /**
     * @custom:ubeaconowner :=
     * address bOwnr_=makeAddr('bOwner')
     * 0x7a50CB979955F18AE69bC88e6BDF6fEF0E940FDe
     */

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

    // forge test --match-contract ManagerNewPool_Safe_Combo --match-test test_createPool_success -vvvv

    function test_createPool_success() external {
        // address fundingToken = address(new StableMock(["USDC_MOCK", "mUSD"]));
        // address govToken = address(new GovTokenMock(["EQUI_DAO", "$EQ"]));
        Manager mngr = Manager(address(managerProxy));

        // address listOw = makeAddr("List_Owner");
        // address list_ = mngr.createProjectList(listOw, "LIST_ZER0");
        // ///@custom:pool-init-data
        // address[5] memory poolAddr = [
        //     poolOwner,
        //     address(managerProxy),
        //     fundingToken,
        //     list_,
        //     govToken
        // ];

        // initPoolData = abi.encodeWithSignature(
        //     "initialize(address[5],(uint256,uint256,uint256,uint256))",
        //     poolAddr,
        //     1e18,
        //     1e6,
        //     1e22,
        //     1e18
        // );
        // vm.expectRevert("InvalidInitialization");
        // vm.expectRevert();
        ///@custom:safe-init-data
        // address[] memory safeAddr = new address[](2);
        // safeAddr[0] = makeAddr("SAFE1");
        // safeAddr[1] = makeAddr("SAFE2");
        // address ZERO = address(0);
        // bytes memory data_;
        // bytes memory safeSetup = abi.encodeWithSignature(
        //     "setup(address[],uint256,address,bytes,address,address,uint256,address payable)",
        //     safeAddr,
        //     2,
        //     ZERO,
        //     data_,
        //     ZERO,
        //     ZERO,
        //     0,
        //     payable(ZERO)
        // );

        (SafeSetUp memory _safeSetUp, PoolInitParams memory _poolSetUp) = _setUpParams(mngr);

        (address pool, address safe) = mngr.createPoolMultiSig(
            _safeSetUp,
            _poolSetUp
        );
        assertEq(mngr.isPool(pool), true);
        assertEq(mngr.isMultisig(safe), true);
        assertEq(mngr.isList(safe), false);

        assertEq(OwnableUpgradeable(pool).owner(), safe);

        UpgradeableBeacon poolBcn_=mngr.poolBeacon();
        UpgradeableBeacon safeBcn_=mngr.safeBeacon();
        emit log_named_address('PoolBeacon',address(poolBcn_));
        emit log_named_address('SafeBeacon',address(safeBcn_));
        emit log_named_address('ProjectRegistry',mngr.projectRegistry());
        emit log_named_uint('Version',mngr.version());
        emit log_named_uint('Version',mngr.version());

    }
    function _setUpParams(
        Manager mngr
    ) internal returns (SafeSetUp memory, PoolInitParams memory) {
        address fundingToken = address(new StableMock(["USDC_MOCK", "mUSD"]));
        address govToken = address(new GovTokenMock(["EQUI_DAO", "$EQ"]));
        address listOw = makeAddr("List_Owner");
        address list_ = mngr.createProjectList(listOw, "LIST_ZER0");
        ///@custom:pool-init-data
        address[5] memory poolAddr = [
            poolOwner,
            address(managerProxy),
            fundingToken,
            list_,
            govToken
        ];
        uint[4] memory fparams;
        fparams[0]=1e18;
        fparams[1]=1e6;
        fparams[2]=1e22;
        fparams[3]=1e18;

        address[] memory safeAddr = new address[](2);
        safeAddr[0] = makeAddr("SAFE1");
        safeAddr[1] = makeAddr("SAFE2");
        SafeSetUp memory _safeSetUp;
        _safeSetUp._owners = safeAddr;
        _safeSetUp._threshold = 2;
        PoolInitParams memory _poolSetUp;
        _poolSetUp.addr = poolAddr;
        _poolSetUp.fParams = fparams;
        return (_safeSetUp, _poolSetUp);
    }


}
