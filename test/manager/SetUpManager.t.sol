// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/librerias/gnosis/GnosisWallet.sol";
import "../utils/Utils.sol";
import {Manager} from "../../src/manager/Manager.sol";

contract GSafeBuild is GnosisWallet {
    constructor() {}
}
struct ManagerConstr {
    uint version;
    address poolImplemetation;
    address safeImplementation;
    address projectRegistry;
}
struct ManagerInit {
    address newOwner;
}

abstract contract ManagerSetup is Utils_Test {
    GSafeBuild internal gSafeBuild;

    Manager internal managerImpl;
    address uBeaconOwner;
    UpgradeableBeacon internal managerBeacon;
    BeaconProxy internal managerProxy;

    constructor(address _uBeaconOwner) {
        gSafeBuild = new GSafeBuild();
        uBeaconOwner=_uBeaconOwner;
    }

    function createManagerImpl(
        ManagerConstr memory _mngSetup
    ) internal returns (Manager manager) {
        return
            managerImpl = new Manager(
                _mngSetup.version,
                _mngSetup.poolImplemetation,
                _mngSetup.safeImplementation,
                _mngSetup.projectRegistry
            );
    }

    function createManagerProxy(
        ManagerConstr memory _mngSetup,ManagerInit memory _mngrInit
    ) internal returns (Manager, UpgradeableBeacon, BeaconProxy) {
        Manager impl_=createManagerImpl(_mngSetup);

        bytes memory initData= abi.encodeWithSignature('initialize(address)',_mngrInit.newOwner);

        (managerBeacon, managerProxy) = createBeaconAndProxy(address(impl_),uBeaconOwner,initData);
        // managerBeacon=bcn_;

        // managerProxy=BeaconProxy(payable(bcnProxy_));

        return (impl_,managerBeacon,managerProxy);
    }
}
