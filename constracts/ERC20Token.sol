// SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract ERC20Token is ERC20 {
    constructor(string memory name,string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 10000 * 10 ** uint(decimals()));
    }

    function mint(uint amount) public {
        _mint(msg.sender, amount * 10 ** uint(decimals()));
    }
}