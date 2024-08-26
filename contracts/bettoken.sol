

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Bettoken is ERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public constant TOTAL_SUPPLY = 200_000_000 * 10 ** 18; // 200 million BETT with 18 decimals

    // Private Sale variables
    uint256 public privateSaleTarget = 1_000_000 * 10 ** 18; // 1 million USD target
    uint256 public privateSaleTokens = 38_835_764 * 10 ** 18; // 38,835,764 BETT
    uint256 public privateSaleStartPrice = 0.001 * 10 ** 18; // 0.001 USD per BETT
    uint256 public privateSaleEndPrice = 0.0505 * 10 ** 18; // 0.0505 USD per BETT
    uint256 public privateSaleSoldTokens = 0;

    // Pre-Sale variables
    uint256 public preSaleTarget = 19_000_000 * 10 ** 18; // 19 million USD target
    uint256 public preSaleTokens = 161_164_236 * 10 ** 18; // 161,164,236 BETT
    uint256 public preSaleStartPrice = 0.0505 * 10 ** 18; // 0.0505 USD per BETT
    uint256 public preSaleEndPrice = 0.1 * 10 ** 18; // 0.1 USD per BETT
    uint256 public preSaleSoldTokens = 0;

    // Sale States
    enum SaleStage { NONE, PRIVATE, PRESALE }
    SaleStage public stage = SaleStage.NONE;

    // Vesting Parameters
    mapping(address => uint256) public vestingBalance;
    mapping(address => uint256) public vestingReleaseTime;
    uint256 public vestingDuration = 180 days; // 6 ay
    uint256 public stakeDuration = 365 days; // 1 yıl

    AggregatorV3Interface[] public priceFeeds; // Birden fazla Chainlink Price Oracle

    // Event Definitions
    event PrivateSale(address indexed buyer, uint256 amount);
    event PreSale(address indexed buyer, uint256 amount);
    event TokensStaked(address indexed staker, uint256 amount, uint256 releaseTime);
    event VestedTokensReleased(address indexed beneficiary, uint256 amount);
    event StageChanged(SaleStage newStage);
    event FundsWithdrawn(address indexed owner, uint256 amount);

    constructor(address[] memory _priceFeeds) ERC20("Bettoken", "BETT") Ownable(msg.sender) {
        _mint(address(this), TOTAL_SUPPLY);
        for (uint256 i = 0; i < _priceFeeds.length; i++) {
            priceFeeds.push(AggregatorV3Interface(_priceFeeds[i]));
        }
    }

    // Birden fazla oracle'dan fiyat ortalamasını alır
    function getLatestPrice() public view returns (uint256) {
        uint256 totalPrice = 0;
        for (uint256 i = 0; i < priceFeeds.length; i++) {
            (
                ,
                int price,
                ,
                ,
            ) = priceFeeds[i].latestRoundData();
            require(price > 0, "Invalid price data from oracle");
            totalPrice = totalPrice.add(uint256(price));
        }
        return totalPrice.div(priceFeeds.length).mul(10 ** 10); // Ölçeklendirme
    }

    function startPrivateSale() external onlyOwner {
        require(stage == SaleStage.NONE, "Private Sale can only start from NONE stage.");
        require(privateSaleSoldTokens == 0, "Private Sale tokens should be unsold at start.");
        require(preSaleSoldTokens == 0, "Pre-Sale should not have started before Private Sale.");

        stage = SaleStage.PRIVATE;
        emit StageChanged(stage);
    }

    function startPreSale() external onlyOwner {
        require(stage == SaleStage.PRIVATE, "Pre-Sale can only start after Private Sale.");
        require(privateSaleSoldTokens == privateSaleTokens, "Private Sale must be completed before starting Pre-Sale.");
        
        stage = SaleStage.PRESALE;
        emit StageChanged(stage);
    }

    function buyTokens(uint256 usdAmount) external payable nonReentrant {
        require(stage != SaleStage.NONE, "No sale is active.");

        uint256 latestPrice = getLatestPrice();
        require(latestPrice > 0, "Invalid price from oracle");

        uint256 tokensToBuy;
        if (stage == SaleStage.PRIVATE) {
            require(privateSaleSoldTokens < privateSaleTokens, "Private Sale sold out.");
            tokensToBuy = calculatePrivateSaleTokens(usdAmount.mul(latestPrice).div(1 ether));
            privateSaleSoldTokens = privateSaleSoldTokens.add(tokensToBuy);
            require(privateSaleSoldTokens <= privateSaleTokens, "Exceeds Private Sale token limit.");
            vestingBalance[msg.sender] = vestingBalance[msg.sender].add(tokensToBuy);
            vestingReleaseTime[msg.sender] = block.timestamp.add(stakeDuration).add(vestingDuration);
            emit PrivateSale(msg.sender, tokensToBuy);
        } else if (stage == SaleStage.PRESALE) {
            require(preSaleSoldTokens < preSaleTokens, "Pre-Sale sold out.");
            require(usdAmount >= 100 * 10 ** 18 && usdAmount <= 3_000 * 10 ** 18, "Purchase amount out of limits.");
            tokensToBuy = calculatePreSaleTokens(usdAmount.mul(latestPrice).div(1 ether));
            preSaleSoldTokens = preSaleSoldTokens.add(tokensToBuy);
            require(preSaleSoldTokens <= preSaleTokens, "Exceeds Pre-Sale token limit.");
            _transfer(address(this), msg.sender, tokensToBuy);
            emit PreSale(msg.sender, tokensToBuy);
        }
    }

    function calculatePrivateSaleTokens(uint256 usdAmount) internal view returns (uint256) {
        require(usdAmount > 0, "USD amount must be greater than 0");
        require(privateSaleTokens > 0, "Private Sale tokens must be greater than 0");
        require(privateSaleSoldTokens <= privateSaleTokens, "Private Sale sold tokens exceed available tokens");

        uint256 tokenRange = privateSaleEndPrice.sub(privateSaleStartPrice);
        uint256 currentPrice = privateSaleStartPrice.add(
            tokenRange.mul(privateSaleSoldTokens).div(privateSaleTokens)
        );

        require(currentPrice >= privateSaleStartPrice && currentPrice <= privateSaleEndPrice, "Invalid token price calculated");

        uint256 tokens = usdAmount.div(currentPrice);
        require(tokens > 0, "Calculated tokens must be greater than 0");

        return tokens;
    }

    function calculatePreSaleTokens(uint256 usdAmount) internal view returns (uint256) {
        uint256 currentPrice = preSaleStartPrice.add(
            (preSaleEndPrice.sub(preSaleStartPrice)).mul(preSaleSoldTokens).div(preSaleTokens)
        );
        require(currentPrice >= preSaleStartPrice && currentPrice <= preSaleEndPrice, "Invalid token price calculated");

        uint256 tokens = usdAmount.div(currentPrice);
        require(tokens > 0, "Calculated tokens must be greater than 0");

        return tokens;
    }

    function stakeTokens(uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance to stake");

        _transfer(msg.sender, address(this), amount);

        vestingBalance[msg.sender] = vestingBalance[msg.sender].add(amount);
        vestingReleaseTime[msg.sender] = block.timestamp.add(stakeDuration);

        emit TokensStaked(msg.sender, amount, vestingReleaseTime[msg.sender]);
    }

    function releaseVestedTokens() external nonReentrant {
        require(block.timestamp >= vestingReleaseTime[msg.sender], "Vesting period not yet completed.");
        uint256 amount = vestingBalance[msg.sender];
        require(amount > 0, "No vested tokens to release");

        vestingBalance[msg.sender] = 0;
        vestingReleaseTime[msg.sender] = 0;

        _transfer(address(this), msg.sender, amount);

        emit VestedTokensReleased(msg.sender, amount);
    }

    function haltSales() external onlyOwner {
        require(privateSaleSoldTokens == privateSaleTokens || preSaleSoldTokens == preSaleTokens, 
                "Sales targets not yet met.");
        stage = SaleStage.NONE;
        emit StageChanged(stage);
    }

    function emergencyWithdraw(address tokenAddress, uint256 amount) external onlyOwner nonReentrant {
        IERC20(tokenAddress).transfer(owner(), amount);
        emit FundsWithdrawn(owner(), amount);
    }

    function withdrawFunds() external onlyOwner nonReentrant {
        uint256 amount = address(this).balance;
        payable(owner()).transfer(amount);
        emit FundsWithdrawn(owner(), amount);
    }

    fallback() external payable {
        revert("Direct ETH transfers not allowed.");
    }

    receive() external payable {
        revert("Direct ETH transfers not allowed.");
    }
}
