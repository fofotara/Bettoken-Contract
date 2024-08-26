// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenBridgeBSC is ERC20, Ownable {
    mapping(address => uint256) public mintedTokens;

    event TokensMinted(address indexed user, uint256 amount);

    constructor() ERC20("Wrapped Token", "WTKN") {
    }

    function mintTokens(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        mintedTokens[to] += amount;

        emit TokensMinted(to, amount);
    }

    function burnTokens(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        _burn(msg.sender, amount);
        mintedTokens[msg.sender] -= amount;
    }
}
