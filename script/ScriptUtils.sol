// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;
import "forge-std/Script.sol";

import {BeaconProxy} from "@oz/proxy/beacon/BeaconProxy.sol";
import {UpgradeableBeacon} from "@oz/proxy/beacon/UpgradeableBeacon.sol";

import {ABDKMath64x64} from "abdk-libraries/ABDKMath64x64.sol";

import {Formula, FormulaParams} from "../src/Formula.sol";
import {Manager} from "../src/manager/Manager.sol";
import "../src/librerias/gnosis/GnosisWallet.sol";
import "../src/ProjectRegistry.sol";
import "../src/pool/Pool.sol";

contract GSafeBuild is GnosisWallet {
    constructor() {}
}
contract CFADummy {

}

abstract contract ScriptUtils is Script {
    struct ManagerConstr {
        uint version;
        address poolImplemetation;
        address safeImplementation;
        address projectRegistry;
    }
    bytes32 SALT = "TR0YA";

    /**
     * @dev Manager data
     */
    UpgradeableBeacon managerBeacon;
    BeaconProxy managerProxy;
    Manager managerImpl;
    /**
     * @dev Registry data
     */
    UpgradeableBeacon registryBeacon;
    BeaconProxy registryProxy;
    ProjectRegistry registryImpl;
    /**
     * @dev Pool data
     */
    Pool poolImpl;

    //--------------------------------------------
    //              MANAGER_UTILS
    //--------------------------------------------

    function createManagerImpl(
        ManagerConstr memory _mngSetup
    ) internal returns (Manager manager) {
        return new Manager(
                _mngSetup.version,
                _mngSetup.poolImplemetation,
                _mngSetup.safeImplementation,
                _mngSetup.projectRegistry
            );
    }

    function createManagerProxy(
        address impl_,
        address _managerOwner,
        address _beaconOwner
    ) internal returns (Manager, UpgradeableBeacon, BeaconProxy) {
        // Manager impl_ = createManagerImpl(_mngSetup);
        console.log('MANAGER_IMPL',address(impl_));

        bytes memory initData = abi.encodeWithSignature(
            "initialize(address)",
            _managerOwner
        );

        (managerBeacon, managerProxy) = createBeaconAndProxy(
            address(impl_),
            _beaconOwner,
            initData
        );
        // managerBeacon=bcn_;

        // managerProxy=BeaconProxy(payable(bcnProxy_));

        return (Manager(address(managerProxy)) ,managerBeacon, managerProxy);
    }

    //--------------------------------------------
    //              SAFE_UTILS
    //--------------------------------------------

    function createCFA_llhh()internal  returns (address impl_) {
        return address(new CFADummy());
    }
    /**
     * @dev solo para LLHH
     */
    function createSafeImpl() internal returns (address impl_) {
        GSafeBuild gBuild = new GSafeBuild();
        return gBuild.getSafeImplementation();
    }

    //--------------------------------------------
    //              POOL_UTILS
    //--------------------------------------------
    function createPoolImplementation(
        address _cfaForwarder
    ) internal returns (address _poolImpl) {
        return address(new Pool(_cfaForwarder));
    }

    //--------------------------------------------
    //              REGISTRY_UTILS
    //--------------------------------------------

    function createRegistryProxied(
        uint _version,
        address _registryOwner,
        address registryBeaconOwner
    )
        internal
        returns (UpgradeableBeacon registryBeacon_, BeaconProxy registryproxy_)
    {
        registryImpl = new ProjectRegistry(_version);
        bytes memory initRegistry = abi.encodeWithSignature(
            "initialize(address)",
            _registryOwner
        );
        (registryBeacon_, registryproxy_) = createBeaconAndProxy(
            address(registryImpl),
            registryBeaconOwner,
            initRegistry
        );
    }

    //--------------------------------------------
    //              PROXY_UTILS
    //--------------------------------------------

    function createBeaconAndProxy(
        address _implementation,
        address _initalOwner,
        bytes memory _initPayload
    ) internal returns (UpgradeableBeacon beacon_, BeaconProxy beaconProxy_) {
        beacon_ = new UpgradeableBeacon(_implementation, _initalOwner);
        beaconProxy_ = new BeaconProxy(address(beacon_), _initPayload);
    }

    //--------------------------------------------
    //              FORMULA_UTILS
    //--------------------------------------------
    // function createPool()  returns () {

    // }
    /**
     * Crear pool & proxy
     * Crear manager
     * Crear registry
     *
     */
}
