// SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract JimToken is ERC20 {
    constructor() ERC20("Jim Token", "JT") {
        _mint(msg.sender, 10000 * 10 ** uint(decimals()));
    }
}