// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "@oz/access/Ownable.sol";
import {BeaconProxy} from "@oz/proxy/beacon/BeaconProxy.sol";
import {UpgradeableBeacon} from "@oz/proxy/beacon/UpgradeableBeacon.sol";

// import {MimeToken} from "./MimeToken.sol";
import {MOCK_MIME as MimeToken} from '../../MockMime.sol';

contract MimeTokenFactory {
    UpgradeableBeacon public immutable beacon;

    mapping(address => bool) public isMimeToken;

    event MimeTokenCreated(address token);

    constructor(address _mimeTokenImplementation) {
        beacon = new UpgradeableBeacon(_mimeTokenImplementation);
        beacon.transferOwnership(msg.sender);
    }

    function createMimeToken(bytes calldata _initPayload) public returns (address proxy) {
        proxy = address(new BeaconProxy(address(beacon), _initPayload));
        isMimeToken[proxy] = true;

        Ownable(proxy).transferOwnership(msg.sender);

        emit MimeTokenCreated(proxy);
    }
}