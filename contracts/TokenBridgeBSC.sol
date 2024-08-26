// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TokenBridgeBSC is ERC20, Ownable, ReentrancyGuard {
    mapping(address => uint256) public mintedTokens;
    AggregatorV3Interface internal priceFeed;

    event TokensMinted(address indexed user, uint256 amount);
    event TokensBurned(address indexed user, uint256 amount);
    event TokensLocked(address indexed user, uint256 amount);
    event TokensReleased(address indexed user, uint256 amount);
    event TransferFailed(address indexed user, uint256 amount);
    event PriceFeedError(string message);

    // Oracle adresi constructor'a ekleniyor
    constructor(address _priceFeed) ERC20("Wrapped Token", "WTKN") Ownable(msg.sender) {
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

    // Token'ları BSC'de kilitler ve Ethereum'da mint edilmesi için hazırlık yapar
    function lockTokens(uint256 amount) external nonReentrant {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        _burn(msg.sender, amount); // BSC'deki token'ları yakar
        mintedTokens[msg.sender] += amount; // Ethereum'da mint edilecek miktarı kaydeder

        emit TokensLocked(msg.sender, amount);
    }

    // Token'ları BSC'de mint eder
    function mintTokens(address to, uint256 amount) external onlyOwner nonReentrant {
        int price = getLatestPrice();
        require(price > 0, "Invalid price data from oracle");
        
        _mint(to, amount);
        mintedTokens[to] += amount;

        emit TokensMinted(to, amount);
    }

    // Token'ları BSC'de yakar ve Ethereum'da kilitli token'ların serbest bırakılması için hazırlık yapar
    function burnTokens(uint256 amount) external nonReentrant {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        _burn(msg.sender, amount);
        mintedTokens[msg.sender] -= amount;

        emit TokensBurned(msg.sender, amount);
    }

    // Token'ları Ethereum'da serbest bırakır
    function releaseTokens(address user, uint256 amount) external onlyOwner nonReentrant {
        require(mintedTokens[user] >= amount, "Insufficient locked tokens");

        mintedTokens[user] -= amount;
        _mint(user, amount); // Ethereum'da token'ları mint eder (BSC'de yakılan token'ların karşılığı)

        emit TokensReleased(user, amount);
    }
}
