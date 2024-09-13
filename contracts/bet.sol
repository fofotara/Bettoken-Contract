// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract Bettoken is ERC20, Ownable, ReentrancyGuard, Pausable, ERC20Permit {
    using SafeMath for uint256;

    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 10 ** 18; // Toplam arz

    struct TokenAllocation {
        uint256 marketAllocation;
        uint256 teamAllocation;
        uint256 presaleAllocation;
        uint256 airdropAllocation;
        uint256 burnAllocation;
    }

    TokenAllocation public tokenAllocation = TokenAllocation({
        marketAllocation: 500_000_000 * 10 ** 18,   // %50 Piyasa için
        teamAllocation: 100_000_000 * 10 ** 18,     // %10 Takım için (kilitli)
        presaleAllocation: 200_000_000 * 10 ** 18,  // %20 Ön Satış
        airdropAllocation: 50_000_000 * 10 ** 18,   // %5 Airdrop ve Bonuslar
        burnAllocation: 150_000_000 * 10 ** 18      // %15 Yakılacak Tokenlar
    });

    struct SaleInfo {
        uint256 soldTokens;
        uint256 startPrice;
        uint256 endPrice;
        uint256 totalTokens;
    }

    SaleInfo public privateSaleInfo = SaleInfo({
        soldTokens: 0,
        startPrice: 0.001 * 10 ** 18,
        endPrice: 0.0505 * 10 ** 18,
        totalTokens: 38_835_764 * 10 ** 18
    });

    SaleInfo public preSaleInfo = SaleInfo({
        soldTokens: 0,
        startPrice: 0.0505 * 10 ** 18,
        endPrice: 0.1 * 10 ** 18,
        totalTokens: 161_164_236 * 10 ** 18
    });

    uint256 public minPurchaseAmount = 100 * 10 ** 18;
    uint256 public maxPurchaseAmount = 3000 * 10 ** 18;

    // White List Mapping
    mapping(address => bool) public whiteList;

    // Affiliate Sistemleri
    mapping(address => string) public affiliateCodes; // Her kullanıcıya ait affiliate kodu
    mapping(string => address) public affiliateOwners; // Her affiliate kodu için adres

    uint8 public affiliateRewardPercentage = 5;  // %5 varsayılan affiliate ödülü

    // Event Definitions
    event PrivateSale(address indexed buyer, uint256 amount, string affiliateCode);
    event PreSale(address indexed buyer, uint256 amount, string affiliateCode);
    event AffiliateRewardPaid(address indexed affiliate, uint256 reward);
    event AffiliateAdded(address indexed affiliate, string code);
    event AffiliateRemoved(address indexed affiliate, string code);
    event WhiteListAdded(address indexed account);
    event WhiteListRemoved(address indexed account);

    constructor() 
        ERC20("Bettoken", "BETT")
        ERC20Permit("Bettoken")
        Ownable(msg.sender)
    {
        _mint(address(this), TOTAL_SUPPLY); // Tüm tokenları kontrata mint et
    }

    // --- White List Fonksiyonları ---

    /**
     * @dev Adresi whitelist'e ekler
     */
    function addToWhiteList(address account) external onlyOwner {
        require(!whiteList[account], "Already whitelisted");
        whiteList[account] = true;
        emit WhiteListAdded(account);
    }

    /**
     * @dev Adresi whitelist'ten çıkarır
     */
    function removeFromWhiteList(address account) external onlyOwner {
        require(whiteList[account], "Not whitelisted");
        whiteList[account] = false;
        emit WhiteListRemoved(account);
    }

    // --- Affiliate Sistem Fonksiyonları ---

    /**
     * @dev Affiliate adresi ve kodu ekler
     */
    function addAffiliate(address affiliate, string memory code) external onlyOwner {
        require(bytes(affiliateCodes[affiliate]).length == 0, "Affiliate exists");
        require(affiliateOwners[code] == address(0), "Code in use");

        affiliateCodes[affiliate] = code;
        affiliateOwners[code] = affiliate;
        emit AffiliateAdded(affiliate, code);
    }

    /**
     * @dev Affiliate adresi ve kodu siler
     */
    function removeAffiliate(address affiliate) external onlyOwner {
        string memory code = affiliateCodes[affiliate]; // burada memory kullanıyoruz
        require(bytes(code).length > 0, "No affiliate");

        delete affiliateOwners[code];
        delete affiliateCodes[affiliate];
        emit AffiliateRemoved(affiliate, code);
    }

    // --- Private Sale Fonksiyonu ---
    function buyTokensPrivateSale(uint256 usdAmount, string memory affiliateCode) external payable nonReentrant whenNotPaused {
        require(whiteList[msg.sender], "Not whitelisted");
        require(privateSaleInfo.soldTokens < privateSaleInfo.totalTokens, "Sold out");

        uint256 tokensToBuy = calculateTokensPrivateSale(usdAmount);
        privateSaleInfo.soldTokens = privateSaleInfo.soldTokens.add(tokensToBuy);
        require(privateSaleInfo.soldTokens <= privateSaleInfo.totalTokens, "Exceeds limit");

        _transfer(address(this), msg.sender, tokensToBuy);

        if (bytes(affiliateCode).length > 0) {
            address affiliate = affiliateOwners[affiliateCode]; // burada memory kullanıyoruz
            require(affiliate != address(0), "Invalid code");

            uint256 affiliateReward = tokensToBuy.mul(affiliateRewardPercentage).div(100);
            _transfer(address(this), affiliate, affiliateReward);
            emit AffiliateRewardPaid(affiliate, affiliateReward);
        }

        emit PrivateSale(msg.sender, tokensToBuy, affiliateCode);
    }

    // --- Pre-Sale Fonksiyonu ---
    function buyTokensPreSale(uint256 usdAmount, string memory affiliateCode) external payable nonReentrant whenNotPaused {
        require(preSaleInfo.soldTokens < preSaleInfo.totalTokens, "Sold out");
        require(usdAmount >= minPurchaseAmount && usdAmount <= maxPurchaseAmount, "Amount out of range");

        uint256 tokensToBuy = calculateTokensPreSale(usdAmount);
        preSaleInfo.soldTokens = preSaleInfo.soldTokens.add(tokensToBuy);
        require(preSaleInfo.soldTokens <= preSaleInfo.totalTokens, "Exceeds limit");

        _transfer(address(this), msg.sender, tokensToBuy);

        if (bytes(affiliateCode).length > 0) {
            address affiliate = affiliateOwners[affiliateCode]; // burada memory kullanıyoruz
            require(affiliate != address(0), "Invalid code");

            uint256 affiliateReward = tokensToBuy.mul(affiliateRewardPercentage).div(100);
            _transfer(address(this), affiliate, affiliateReward);
            emit AffiliateRewardPaid(affiliate, affiliateReward);
        }

        emit PreSale(msg.sender, tokensToBuy, affiliateCode);
    }

    // --- Token Hesaplama Fonksiyonları ---
    function calculateTokensPrivateSale(uint256 usdAmount) public view returns (uint256) {
        uint256 tokenRange = privateSaleInfo.endPrice.sub(privateSaleInfo.startPrice);
        uint256 currentPrice = privateSaleInfo.startPrice.add(
            tokenRange.mul(privateSaleInfo.soldTokens).div(privateSaleInfo.totalTokens)
        );
        require(currentPrice >= privateSaleInfo.startPrice && currentPrice <= privateSaleInfo.endPrice, "Invalid price");

        uint256 tokens = usdAmount.div(currentPrice);
        return tokens;
    }

    function calculateTokensPreSale(uint256 usdAmount) public view returns (uint256) {
        uint256 tokenRange = preSaleInfo.endPrice.sub(preSaleInfo.startPrice);
        uint256 currentPrice = preSaleInfo.startPrice.add(
            tokenRange.mul(preSaleInfo.soldTokens).div(preSaleInfo.totalTokens)
        );
        require(currentPrice >= preSaleInfo.startPrice && currentPrice <= preSaleInfo.endPrice, "Invalid price");

        uint256 tokens = usdAmount.div(currentPrice);
        return tokens;
    }
}
