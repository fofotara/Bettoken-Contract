// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TokenBridgeETH is Ownable, ReentrancyGuard {
    IERC20 public token;
    AggregatorV3Interface internal priceFeed;
    mapping(address => uint256) public lockedTokens;

    event TokensLocked(address indexed user, uint256 amount);
    event TokensReleased(address indexed user, uint256 amount);        
    event TransferFailed(address indexed user, uint256 amount);
    event PriceFeedError(string message);

    constructor(address _token, address _priceFeed) Ownable(msg.sender) {
        token = IERC20(_token);
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    // Oracle'dan son fiyat verisini alır
    function getLatestPrice() public view returns (int) {
        (
            ,
            int price,
            ,
            ,
        ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price data from oracle");
        return price;
    }

    function lockTokens(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");

        int price = getLatestPrice(); // Oracle'dan fiyat alınıyor
        require(price > 0, "Price feed error"); // Fiyatın geçerliliği kontrol ediliyor

        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        lockedTokens[msg.sender] += amount;

        emit TokensLocked(msg.sender, amount);
    }

    function releaseTokens(address user, uint256 amount) external onlyOwner nonReentrant {
        require(lockedTokens[user] >= amount, "Insufficient locked tokens");

        lockedTokens[user] -= amount;

        if (!token.transfer(user, amount)) {
            emit TransferFailed(user, amount); // Transfer başarısız olduğunda bir event emit ediliyor
            revert("Transfer failed");
        }

        emit TokensReleased(user, amount);
    }
}
