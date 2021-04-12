// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CropToken is Context, ERC20 {


    constructor () ERC20("CropToken", "CRP") {
        _mint(_msgSender(), 3000000 * (10 ** uint256(decimals())));
    }
}