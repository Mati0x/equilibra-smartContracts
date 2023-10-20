// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/librerias/gnosis/GnosisWallet.sol";

contract GSafeBuild is GnosisWallet {
    constructor() {}
}

contract TestUnita is Test {
    GSafeBuild internal gSafeBuild;
    uint val = 1;
    int128 min500 = -500;

    function setUp() external  {
        gSafeBuild= new GSafeBuild();
    }
    // forge test --match-contract TestUnita --match-test test_createSafe -vv
    function test_createSafe() external  {
        address[] memory gOwners=new address[](4);
        gOwners[0]=makeAddr('M');
        gOwners[1]=makeAddr('V');
        gOwners[2]=makeAddr('L');
        gOwners[3]=makeAddr('F');
        bytes memory zBytes;
        uint th=3;
        address ZER0=address(0);
        address gProxy=address(gSafeBuild.createGnosisSafe(gOwners,th,ZER0,zBytes,ZER0,ZER0,0,payable(ZER0)));
        emit log_named_address('PROXY_GNOSIS_NEW',gProxy);
        emit log_named_address('B_OWNR',makeAddr('bOwner'));


    }

    //  forge test --match-test test_unidades -vv
    function test_unidades() external {
        // delta += -100
        int result = int(val);
        result += min500;
        // console.log(result);
        emit log_int(result);
    }

    //  forge test --match-test test_bytesEncoding -vv
    // function _encodeSupport(
    //     uint40 _time,
    //     uint200 _amount
    // ) internal pure returns (bytes32) {
    //     bytes32 returnValue;
    //     bytes5 bTime = bytes5(_time);
    //     bytes25 bAmount = bytes25(_amount);

    //     assembly {
    //         let x := mload(0x20)
    //         x := add(bTime, 0x00)
    //         x := add(bAmount, 0x07)
    //         returnValue := mload(0x20)
    //     }
    //     return returnValue;
    // }

    // function _encodeSupport(
    //     uint40 _time,
    //     uint200 _amount
    // ) internal pure returns (bytes32) {
    //     bytes32 returnValue;

    //     assembly {
    //         let data := mload(0x40)
    //         mstore(add(data, 0), _time)
    //         mstore(add(data, 30), _amount)
    //         mstore(data, 0x20)

    //         returnValue := data
    //     }
    //     return returnValue;
    // }
    function _encodeSupport(
        uint40 _time,
        uint200 _amount
    ) internal pure returns (bytes32) {
        bytes32 returnValue;

        assembly {
            let data := mload(0x40)
            mstore(add(data, 12), _amount) // Almacena _amount en los bytes 12-32
            mstore(add(data, 5), _time) // Almacena _time en los bytes 5-9
            mstore(data, 0x40)

            returnValue := data
        }
        return returnValue;
    }

    // function _dencodeSupport(
    //     bytes32 _data
    // ) internal pure returns (uint40,uint200) {
    //     // bytes32 returnValue;
    //     // bytes5 bTime=bytes5(_time);
    //     // bytes25 bAmount=bytes25(_amount);
    //     bytes5 _btime;
    //     bytes25 _bamount;

    //     // assembly {
    //     //     let x := mload(0x20)
    //     //     x:= add(bTime,0x00)
    //     //     x:= add(bAmount,0x07)
    //     //     returnValue:=mload(0x20)
    //     // }

    //     // return returnValue;
    // }

    // function _encodeSupport(
    //     uint40 _time,
    //     uint200 _amount
    // ) internal pure returns (bytes32) {
    //     bytes32 returnValue;

    //     assembly {
    //         let data := mload(0x40)
    //         mstore(add(data, 12), _time) // Almacenar _time en los bytes 12-16
    //         mstore(add(data, 32), _amount) // Almacenar _amount en los bytes 32-64
    //         mstore(data, 0x40)

    //         returnValue := data
    //     }
    //     return returnValue;
    // }

    function _decodeSupport(
        bytes32 data
    ) internal pure returns (uint40, uint200) {
        uint40 _time;
        uint200 _amount;

        assembly {
            _time := mload(add(data, 5))
            _amount := mload(add(data, 12))
        }

        return (_time, _amount);
    }
    //     function _encodeSupport(uint40 _time, uint200 _amount) internal pure returns (bytes32) {
    //     bytes32 returnValue;

    //     assembly {
    //         let data := mload(0x40)
    //         mstore(data, _time)             // Almacena _time en los bytes 0-4
    //         mstore(add(data, 12), _amount)  // Almacena _amount en los bytes 12-32

    //         returnValue := data
    //     }
    //     return returnValue;
    // }

    // function _decodeSupport(bytes32 data) internal pure returns (uint40, uint200) {
    //     uint40 _time;
    //     uint200 _amount;

    //     assembly {
    //         _time := mload(data)            // Obtiene _time de los bytes 0-4
    //         _amount := mload(add(data, 12))  // Obtiene _amount de los bytes 12-32
    //     }

    //     return (_time, _amount);
    // }

    //  forge test --match-test test_bytesEncoding -vv
    //  forge test --debug test_bytesEncoding -vv

    // function test_bytesEncoding() external {
    //     uint40 time = type(uint32).max;
    //     uint200 amount = type(uint144).max;

    //     bytes32 resGuardado = _encodeSupport(time, amount);
    //     emit log_named_bytes32('RESULTADO',resGuardado);
    //     (uint40 time_, uint200 amount_) = _decodeSupport(resGuardado);

    //     assertEq(time,time_,'ALGO_ANDA_MAL_TIEMPO');
    //     assertEq(amount, amount_, "ALGO_ANDA_MA_AMOUNT");
    //     emit log_named_uint("TIME", time);
    //     emit log_named_uint("TIME_DECODED", time_);
    //     emit log_named_uint("AMOUNT", amount);
    //     emit log_named_uint("AMOUNT_DECODED", amount_);
    // }
}
