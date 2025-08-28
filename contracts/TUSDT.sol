// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract TUSDT is ERC20 {
    constructor() ERC20("TUSDT", "TUSDT")  {
        _mint(msg.sender, 10 ether);
    }

    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }

    function decimals() public view override virtual returns (uint8) {
        return 6;
    }
}
