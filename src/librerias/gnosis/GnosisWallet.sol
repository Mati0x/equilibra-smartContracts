// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "./GnosisSafeL2.sol";
import "./proxies/GnosisSafeProxyFactory.sol";

abstract contract GnosisWallet {
    GnosisSafeL2 internal gnosisImplementation;
    GnosisSafeProxyFactory internal gnosisFactory;

    constructor() {
        gnosisImplementation = new GnosisSafeL2();
        gnosisFactory = new GnosisSafeProxyFactory();
    }
    
    function getSafeImplementation() external view returns (address) {
        return address(gnosisImplementation);
    }

    function createGnosisSafe(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external returns (GnosisSafeProxy proxy) {
        bytes memory setupCode= abi.encodeWithSelector(GnosisSafe.setup.selector,_owners,_threshold,to,data,fallbackHandler,paymentToken,payment,paymentReceiver);
        proxy =gnosisFactory.createProxy(address(gnosisImplementation),setupCode);
        // bytes memory setupCode= abi.encodeWithSignature
    }
}
