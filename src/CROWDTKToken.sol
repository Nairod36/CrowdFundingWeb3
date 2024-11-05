// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CROWDTKToken is ERC20, Ownable {
    constructor() ERC20("CROWDTK", "CTK") Ownable(msg.sender) {
        // msg.sender est passé explicitement en tant que propriétaire initial
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
