// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenBridgeETH is Ownable {
    IERC20 public token;
    mapping(address => uint256) public lockedTokens;

    event TokensLocked(address indexed user, uint256 amount);
    event TokensReleased(address indexed user, uint256 amount);

    constructor(address _token) Ownable(msg.sender) {
        token = IERC20(_token);
    }

    function lockTokens(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        lockedTokens[msg.sender] += amount;

        emit TokensLocked(msg.sender, amount);
    }

    function releaseTokens(address user, uint256 amount) external onlyOwner {
        require(lockedTokens[user] >= amount, "Insufficient locked tokens");
        lockedTokens[user] -= amount;
        require(token.transfer(user, amount), "Transfer failed");

        emit TokensReleased(user, amount);
    }
}
