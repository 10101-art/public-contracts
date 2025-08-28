// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestTokenD6 is ERC20 {
    constructor() ERC20("TestTokenD6", "TTD6") {}

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}
