// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;
import 'forge-std/Test.sol';

import {BeaconProxy} from "@oz/proxy/beacon/BeaconProxy.sol";
import {UpgradeableBeacon} from "@oz/proxy/beacon/UpgradeableBeacon.sol";


import {ABDKMath64x64} from "abdk-libraries/ABDKMath64x64.sol";

import {Formula, FormulaParams} from "../../src/Formula.sol";

abstract contract Utils_Test is Test{

    //--------------------------------------------
    //              BEACON_UTILS
    //--------------------------------------------

    function createBeaconAndProxy(
        address _implementation,
        address _initalOwner,
        bytes memory _initPayload
    ) public returns (UpgradeableBeacon beacon_, BeaconProxy beaconProxy_) {
        beacon_ = new UpgradeableBeacon(_implementation, _initalOwner);
        beaconProxy_ = new BeaconProxy(address(beacon_), _initPayload);
    }

    function expectRevertWhenCreatingBeaconProxy(
        address _implementation,
        address _initalOwner,
        bytes memory _initPayload,
        string memory _revertData
    ) public returns (UpgradeableBeacon beacon_, BeaconProxy beaconProxy_) {
        beacon_ = new UpgradeableBeacon(
            _implementation,
            _initalOwner
        );
        emit log_string(_revertData);
        vm.expectRevert();
        beaconProxy_=new BeaconProxy(address(beacon_), _initPayload);
    }
    //--------------------------------------------
    //              FORMULA_UTILS
    //--------------------------------------------

    using ABDKMath64x64 for int128;

    function assertParams(Formula formula, FormulaParams memory _Params) public {
        assertParam(formula.decay(), _Params.decay, " param decay mismatch");
        assertParam(formula.drop(), _Params.drop, " param drop mismatch");
        assertParam(formula.maxFlow(), _Params.maxFlow, " param maxFlow mismatch");
        assertParam(
            formula.minStakeRatio(), _Params.minStakeRatio, " param minStakeRatio mismatch"
        );
    }

    function assertParam(int128 _poolParam, uint256 _param) public {
        assertEq(_poolParam.mulu(1e18), _param);
    }

    function assertParam(int128 _poolParam, uint256 _param, string memory errorMessage) public {
        assertEq(_poolParam.mulu(1e18), _param, errorMessage);
    }

    function _calculateFlowRate(
        Formula _formula,
        uint256 _poolFunds,
        uint256 _poolTotalSupport,
        uint256 _flowLastRate,
        uint256 _flowLastTime,
        uint256 _projectSupport
    ) internal view returns (uint256) {
        uint256 targetRate = _formula.calculateTargetRate(_poolFunds, _projectSupport, _poolTotalSupport);
        uint256 timePassed = block.timestamp - _flowLastTime;

        return _formula.calculateRate(timePassed, _flowLastRate, targetRate);
    }

    


}