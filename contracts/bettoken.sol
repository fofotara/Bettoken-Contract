// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";



contract Bettoken is ERC20, Ownable, ReentrancyGuard {

    using  SafeMath for uint216;

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
    uint256 public vestingDuration = 6 * 30 days; // 6 ay = 6 * 30 gün
    uint256 public stakeDuration = 365 days; // 1 yıl = 365 gün

    // Events
    event PrivateSale(address indexed buyer, uint256 amount);
    event PreSale(address indexed buyer, uint256 amount);

    constructor() ERC20("Bettoken", "BETT") Ownable(msg.sender) {
        _mint(address(this), TOTAL_SUPPLY);
    }

    function startPrivateSale() external onlyOwner {
        require(stage == SaleStage.NONE, "Private Sale has already started or concluded.");
        stage = SaleStage.PRIVATE;
    }

    function startPreSale() external onlyOwner {
        require(stage == SaleStage.PRIVATE, "Private Sale should be concluded first.");
        require(privateSaleSoldTokens == privateSaleTokens, "Private Sale target not reached.");
        stage = SaleStage.PRESALE;
    }

    function buyTokens(uint256 usdAmount) external payable nonReentrant {
        require(stage != SaleStage.NONE, "No sale is active.");

        uint256 tokensToBuy;
        if (stage == SaleStage.PRIVATE) {
            require(privateSaleSoldTokens < privateSaleTokens, "Private Sale sold out.");
            tokensToBuy = calculatePrivateSaleTokens(usdAmount);
            privateSaleSoldTokens += tokensToBuy;
            require(privateSaleSoldTokens <= privateSaleTokens, "Exceeds Private Sale token limit.");
            vestingBalance[msg.sender] += tokensToBuy;
            vestingReleaseTime[msg.sender] = block.timestamp + stakeDuration + vestingDuration;
            emit PrivateSale(msg.sender, tokensToBuy);
        } else if (stage == SaleStage.PRESALE) {
            require(preSaleSoldTokens < preSaleTokens, "Pre-Sale sold out.");
            require(usdAmount >= 100 * 10 ** 18 && usdAmount <= 3_000 * 10 ** 18, "Purchase amount out of limits.");
            tokensToBuy = calculatePreSaleTokens(usdAmount);
            preSaleSoldTokens += tokensToBuy;
            require(preSaleSoldTokens <= preSaleTokens, "Exceeds Pre-Sale token limit.");
            _transfer(address(this), msg.sender, tokensToBuy);
            emit PreSale(msg.sender, tokensToBuy);
        }
    }

    function calculatePrivateSaleTokens(uint256 usdAmount) internal view returns (uint256) {
        uint256 currentPrice = privateSaleStartPrice + 
            ((privateSaleEndPrice - privateSaleStartPrice) * privateSaleSoldTokens / privateSaleTokens);
        return usdAmount / currentPrice;
    }

    function calculatePreSaleTokens(uint256 usdAmount) internal view returns (uint256) {
        uint256 currentPrice = preSaleStartPrice + 
            ((preSaleEndPrice - preSaleStartPrice) * preSaleSoldTokens / preSaleTokens);
        return usdAmount / currentPrice;
    }

    function releaseVestedTokens() external nonReentrant {
        require(block.timestamp >= vestingReleaseTime[msg.sender], "Vesting period not yet completed.");
        uint256 amount = vestingBalance[msg.sender];
        vestingBalance[msg.sender] = 0;
        vestingReleaseTime[msg.sender] = 0;
        _transfer(address(this), msg.sender, amount);
    }

    function haltSales() external onlyOwner {
        require(privateSaleSoldTokens == privateSaleTokens || preSaleSoldTokens == preSaleTokens, 
                "Sales targets not yet met.");
        stage = SaleStage.NONE;
    }

    function withdrawFunds() external onlyOwner nonReentrant {
        payable(owner()).transfer(address(this).balance);
    }

    fallback() external payable {
        revert("Direct ETH transfers not allowed.");
    }

    receive() external payable {
        revert("Direct ETH transfers not allowed.");
    }
}