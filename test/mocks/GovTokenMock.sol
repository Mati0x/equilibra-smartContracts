// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20} from "@oz/token/ERC20/ERC20.sol";

contract GovTokenMock is ERC20 {
    constructor(string[2] memory _strs) ERC20(_strs[0], _strs[1]) {}

    function mint(address _beneficiary,uint _amount) external {
        _mint(_beneficiary,_amount);
    }
    function burn(address _account,uint _amount) external {
        _burn(_account,_amount);
    }
}

