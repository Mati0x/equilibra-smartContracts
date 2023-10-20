// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {TestBase} from "forge-std/Base.sol";

import {BeaconProxy} from "@oz/proxy/beacon/BeaconProxy.sol";
import {UpgradeableBeacon} from "@oz/proxy/beacon/UpgradeableBeacon.sol";

abstract contract ProxyUtils is TestBase {
    function createBeaconAndProxy(
        address _implementation,
        address _initalOwner,
        bytes memory _initPayload
    ) public returns (UpgradeableBeacon beacon_, address beaconProxy_) {
        beacon_ = new UpgradeableBeacon(_implementation, _initalOwner);
        beaconProxy_ = address(new BeaconProxy(address(beacon_), _initPayload));
    }

    function expectRevertWhenCreatingBeaconProxy(
        address _implementation,
        address _initalOwner,
        bytes memory _initPayload,
        bytes memory _revertData
    ) public {
        UpgradeableBeacon beacon_ = new UpgradeableBeacon(
            _implementation,
            _initalOwner
        );

        vm.expectRevert(_revertData);
        address(new BeaconProxy(address(beacon_), _initPayload));
    }
}
