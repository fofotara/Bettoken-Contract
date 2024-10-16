// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC20Permit.sol";

/**
@title Bettoken
@notice Bu kontrat, Bettoken (BETT) adında bir ERC20 token'ını yönetir ve çeşitli token dağıtım, stake, vesting ve satış işlevleri sunar.
*/
contract Bettoken is ERC20, Ownable, ReentrancyGuard, Pausable, ERC20Permit {

    // --- Değişken Tanımları ---

    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 10 ** 18;

    // Token dağılımı için sabit değişkenler
    uint256 public constant MARKET_ALLOCATION = 500_000_000 * 10 ** 18;   // %50 Piyasa için
    uint256 public constant TEAM_ALLOCATION = 100_000_000 * 10 ** 18;     // %10 Takım için (kilitli)
    uint256 public constant PRESALE_ALLOCATION = 150_000_000 * 10 ** 18;  // %15 Ön Satış
    uint256 public constant PRIVATE_SALE_ALLOCATION = 50_000_000 * 10 ** 18; // %5 Private Sale
    uint256 public constant AIRDROP_ALLOCATION = 50_000_000 * 10 ** 18;   // %5 Airdrop ve Bonuslar
    uint256 public constant BURN_ALLOCATION = 150_000_000 * 10 ** 18;     // %15 Yakılacak Tokenlar

    // Bekleyen yakılacak token miktarı
    uint256 public pendingBurnTokens;

    // Airdrop için zaman ve liste tanımları
    uint256 public airdropStartTime;
    uint256 public airdropEndTime;
    mapping(address => bool) public airdropEligible;
    bool public airdropActive = false;

    // Takım tokenlarının kilit süresi
    uint256 public teamTokenReleaseTime;

    // Private Sale ve Pre-Sale değişkenleri
    uint256 public constant PRIVATE_SALE_TOKENS = 50_000_000 * 10 ** 18;
    uint256 public privateSaleSoldTokens = 0;
    uint256 public privateSaleStartPrice = 0.001 * 10 ** 18; // 0.001 USD/BETT
    uint256 public privateSaleEndPrice = 0.005 * 10 ** 18; // 0.005 USD/BETT
    uint256 public minPrivateSaleAmount = 1000 * 10 ** 18; // Minimum 1000 USD
    bool public privateSaleCompleted = false;

    uint256 public constant PRESALE_TOKENS = 150_000_000 * 10 ** 18;
    uint256 public preSaleSoldTokens = 0;
    uint256 public preSaleStartPrice = 0.005 * 10 ** 18; // 0.005 USD/BETT
    uint256 public preSaleEndPrice = 0.1 * 10 ** 18; // 0.1 USD/BETT
    uint256 public minPreSaleAmount = 100 * 10 ** 18; // Minimum 100 USD
    uint256 public maxPreSaleAmount = 3000 * 10 ** 18; // Maximum 3000 USD
    bool public preSaleCompleted = false;
    uint256 public preSaleEndTime;

    // Vesting (serbest bırakma) için değişkenler
    uint256 public constant STAKE_DURATION = 365 days; // 1 yıl stake
    uint256 public constant VESTING_DURATION = 180 days; // 6 ay vesting
    mapping(address => VestingSchedule) public vestingSchedules;

    struct VestingSchedule {
        uint256 totalAmount;
        uint256 releasedAmount;
        uint256 startTime;
        uint256 duration;
        uint256 interval;
    }

    // Kullanıcıların stake bilgileri
    mapping(address => uint256) public stakes;
    mapping(address => uint256) public stakeStartTime;
    mapping(address => uint256) public vestingReleaseTime;

    // Satın alım sınırlarını izlemek için mapping
    mapping(address => uint256) public userPurchaseAmounts;

    // Affiliate sistemi için mapping
    mapping(address => string) public affiliateCodes;
    mapping(string => address) public affiliateOwners;
    uint8 public affiliateRewardPercentage = 5;

    // Affiliate ödüllerini takip eden mapping
    mapping(address => uint256) public affiliateRewards;

    // Whitelist mapping
    mapping(address => bool) public whitelist;

    // --- Event Tanımları ---
    event PrivateSale(address indexed buyer, uint256 amount, string affiliateCode);
    event PreSale(address indexed buyer, uint256 amount, string affiliateCode);
    event AffiliateRewardPaid(address indexed affiliate, uint256 reward);
    event PrivateSaleCompleted();
    event PreSaleCompleted();
    event TokensBurned(uint256 amount);
    event TeamTokensLocked(uint256 amount);
    event TeamTokensReleased(uint256 amount);
    event AirdropStarted(uint256 startTime, uint256 endTime);
    event AirdropEnded();
    event AirdropDistributed(address indexed recipient, uint256 amount);
    event TokensStaked(address indexed staker, uint256 amount, uint256 releaseTime);
    event VestedTokensReleased(address indexed beneficiary, uint256 amount);
    event TokensWithdrawn(uint256 amount);
    event FundsWithdrawn(uint256 amount);

    /**
    @notice Kontrat kurucusu, toplam token miktarını mint ederek belirli bir dağıtım yapar.
    @param initialOwner İlk sahip adresi
    */
    constructor(address initialOwner) 
        ERC20("Bettoken", "BETT")
        ERC20Permit("Bettoken")
        Ownable(initialOwner)
    {
        _mint(address(this), TOTAL_SUPPLY); // Tüm tokenları kontrata mint et

        // Token dağıtımı
        _transfer(address(this), msg.sender, MARKET_ALLOCATION); // Piyasa için
        _transfer(address(this), msg.sender, PRESALE_ALLOCATION); // Ön satış için
        _transfer(address(this), msg.sender, AIRDROP_ALLOCATION); // Airdrop ve bonuslar için

        // Takım tokenlarını kilitle (1 yıl kilitli)
        teamTokenReleaseTime = block.timestamp + 365 days;
        emit TeamTokensLocked(TEAM_ALLOCATION);
    }

    // --- Whitelist Fonksiyonları ---
    /**
    @notice Bir adresi whitelist'e ekler
    @param user Whitelist'e eklenecek adres
    */
    function addToWhitelist(address user) external onlyOwner {
        require(!whitelist[user], "Address is already whitelisted");
        whitelist[user] = true;
    }

    /**
    @notice Bir adresi whitelist'ten çıkarır
    @param user Whitelist'ten çıkarılacak adres
    */
    function removeFromWhitelist(address user) external onlyOwner {
        require(whitelist[user], "Address is not whitelisted");
        delete whitelist[user];
    }

    /**
    @notice Birden fazla adresi whitelist'e ekler
    @param users Whitelist'e eklenecek adresler
    */
    function addToWhitelistBulk(address[] calldata users) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            if (!whitelist[users[i]]) {
                whitelist[users[i]] = true;
            }
        }
    }

    /**
    @notice Bir adresin whitelist'te olup olmadığını kontrol eder
    @param user Kontrol edilecek adres
    @return bool Adres whitelist'te ise true döner
    */
    function isWhitelisted(address user) external view returns (bool) {
        return whitelist[user];
    }

    // --- Private Sale Fonksiyonları ---
    /**
    @notice Kullanıcıların Private Sale döneminde token satın almasına olanak tanır
    @param usdAmount Kullanıcının yatırım yapacağı USD miktarı
    @param affiliateCode Affiliate kodu (isteğe bağlı)
    */
    function buyTokensPrivateSale(uint256 usdAmount, string calldata affiliateCode) external payable nonReentrant whenNotPaused {
        require(whitelist[msg.sender], "Address not whitelisted");
        require(!privateSaleCompleted, "Private Sale has ended");
        require(usdAmount >= minPrivateSaleAmount, "Minimum investment amount not met");
        require(privateSaleSoldTokens < PRIVATE_SALE_TOKENS, "Private Sale sold out");

        uint256 tokensToBuy = calculateTokensPrivateSale(usdAmount);
        require(privateSaleSoldTokens + tokensToBuy <= PRIVATE_SALE_TOKENS, "Exceeds Private Sale token limit");

        privateSaleSoldTokens += tokensToBuy;
        _transfer(address(this), msg.sender, tokensToBuy);

        if (bytes(affiliateCode).length > 0) {
            address affiliate = affiliateOwners[affiliateCode];
            require(affiliate != address(0), "Invalid affiliate code");

            uint256 affiliateReward = (tokensToBuy * affiliateRewardPercentage) / 100;
            affiliateRewards[affiliate] += affiliateReward;
        }

        emit PrivateSale(msg.sender, tokensToBuy, affiliateCode);
    }

    /**
    @notice Private Sale dönemini tamamlar
    */
    function completePrivateSale() external onlyOwner {
        require(!privateSaleCompleted, "Private Sale already completed");
        privateSaleCompleted = true;
        emit PrivateSaleCompleted();
    }

    // --- Pre-Sale Fonksiyonları ---
    /**
    @notice Kullanıcıların Pre-Sale döneminde token satın almasına olanak tanır
    @param usdAmount Kullanıcının yatırım yapacağı USD miktarı
    @param affiliateCode Affiliate kodu (isteğe bağlı)
    */
    function buyTokensPreSale(uint256 usdAmount, string calldata affiliateCode) external payable nonReentrant whenNotPaused {
        require(!preSaleCompleted, "Pre-Sale has ended");
        require(usdAmount >= minPreSaleAmount && usdAmount <= maxPreSaleAmount, "Purchase amount out of limits");
        require(preSaleSoldTokens < PRESALE_TOKENS, "Pre-Sale sold out");

        uint256 tokensToBuy = calculateTokensPreSale(usdAmount);
        uint256 userPurchaseAmount = userPurchaseAmounts[msg.sender] + usdAmount;
        require(userPurchaseAmount <= maxPreSaleAmount, "Exceeds maximum purchase limit per user");
        require(preSaleSoldTokens + tokensToBuy <= PRESALE_TOKENS, "Exceeds Pre-Sale token limit");

        preSaleSoldTokens += tokensToBuy;
        userPurchaseAmounts[msg.sender] = userPurchaseAmount;
        _transfer(address(this), msg.sender, tokensToBuy);

        if (bytes(affiliateCode).length > 0) {
            address affiliate = affiliateOwners[affiliateCode];
            require(affiliate != address(0), "Invalid affiliate code");

            uint256 affiliateReward = (tokensToBuy * affiliateRewardPercentage) / 100;
            affiliateRewards[affiliate] += affiliateReward;
        }

        emit PreSale(msg.sender, tokensToBuy, affiliateCode);
    }

    /**
    @notice Pre-Sale dönemini tamamlar
    */
    function completePreSale() external onlyOwner {
        require(!preSaleCompleted, "Pre-Sale already completed");
        preSaleCompleted = true;
        preSaleEndTime = block.timestamp;
        emit PreSaleCompleted();
    }

    // --- Stake Fonksiyonu ---
    /**
    @notice Kullanıcıların tokenlarını stake etmelerini sağlar
    @param amount Stake edilecek token miktarı
    */
    function stakeTokens(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Stake amount must be greater than zero");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance to stake");
        require(preSaleCompleted, "Pre-sale must be completed before staking");

        stakes[msg.sender] += amount;
        stakeStartTime[msg.sender] = block.timestamp;
        vestingReleaseTime[msg.sender] = block.timestamp + STAKE_DURATION + VESTING_DURATION;
        _transfer(msg.sender, address(this), amount);

        emit TokensStaked(msg.sender, amount, vestingReleaseTime[msg.sender]);
    }

    // --- Vesting Çözme (Serbest Bırakma) Fonksiyonu ---
    /**
    @notice Stake edilen tokenların vesting döneminden sonra serbest bırakılmasını sağlar
    */
    function releaseVestedTokens() external nonReentrant whenNotPaused {
        require(stakes[msg.sender] > 0, "No staked tokens to release");
        require(block.timestamp >= vestingReleaseTime[msg.sender], "Tokens are still in vesting period");

        uint256 amount = stakes[msg.sender];
        stakes[msg.sender] = 0;
        vestingReleaseTime[msg.sender] = 0;
        _transfer(address(this), msg.sender, amount);

        emit VestedTokensReleased(msg.sender, amount);
    }

    // --- Token Yakımı ---
    /**
    @notice Yakılacak token miktarını bekleyen listeye ekler
    @param amount Yakılacak token miktarı
    */
    function addToPendingBurn(uint256 amount) external onlyOwner {
        require(balanceOf(address(this)) >= amount, "Insufficient tokens in contract to burn");
        pendingBurnTokens += amount;
    }

    /**
    @notice Bekleyen tokenları yakar
    */
    function burnPendingTokens() external onlyOwner {
        require(pendingBurnTokens > 0, "No pending tokens to burn");

        _burn(address(this), pendingBurnTokens);
        pendingBurnTokens = 0;

        emit TokensBurned(pendingBurnTokens);
    }

    // --- Token ve Fon Çekme ---
    /**
    @notice Sahip tarafından kontrattaki tokenları çekmek için kullanılır
    @param amount Çekilecek token miktarı
    */
    function withdrawTokens(uint256 amount) external onlyOwner nonReentrant {
        require(balanceOf(address(this)) >= amount, "Insufficient tokens in contract");
        _transfer(address(this), owner(), amount);
        emit TokensWithdrawn(amount);
    }

    /**
    @notice Sahip tarafından kontrattaki fonları çekmek için kullanılır
    */
    function withdrawFunds() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");

        (bool success, ) = owner().call{value: balance}("");
        require(success, "Withdraw failed");
        emit FundsWithdrawn(balance);
    }

    // --- Acil Durum Durdurma ---
    /**
    @notice Kontratı acil durumlarda duraklatmak için kullanılır
    */
    function emergencyPause() external onlyOwner {
        _pause(); // Kontratı duraklatır
    }

    /**
    @notice Kontratı duraklatılmış durumdan çıkarır
    */
    function unpause() external onlyOwner {
        _unpause();
    }

    // --- Satın Alım Miktarı Hesaplama ---
    /**
    @notice Private Sale sırasında USD miktarına göre token miktarını hesaplar
    @param usdAmount USD cinsinden yatırım miktarı
    @return uint256 Hesaplanan token miktarı
    */
    function calculateTokensPrivateSale(uint256 usdAmount) internal view returns (uint256) {
        uint256 tokenRange = privateSaleEndPrice - privateSaleStartPrice;
        uint256 currentPrice = privateSaleStartPrice + (tokenRange * privateSaleSoldTokens / PRIVATE_SALE_TOKENS);
        require(currentPrice >= privateSaleStartPrice && currentPrice <= privateSaleEndPrice, "Invalid price calculation");

        uint256 tokens = usdAmount / currentPrice;
        return tokens;
    }

    /**
    @notice Pre-Sale sırasında USD miktarına göre token miktarını hesaplar
    @param usdAmount USD cinsinden yatırım miktarı
    @return uint256 Hesaplanan token miktarı
    */
    function calculateTokensPreSale(uint256 usdAmount) internal view returns (uint256) {
        uint256 tokenRange = preSaleEndPrice - preSaleStartPrice;
        uint256 currentPrice = preSaleStartPrice + (tokenRange * preSaleSoldTokens / PRESALE_TOKENS);
        require(currentPrice >= preSaleStartPrice && currentPrice <= preSaleEndPrice, "Invalid price calculation");

        uint256 tokens = usdAmount / currentPrice;
        return tokens;
    }

    // --- Fallback Fonksiyonları ---
    /**
    @notice Ether'in kontrata direkt olarak gönderilmesini engeller
    */
    fallback() external payable {
        revert("Direct ETH transfers not allowed.");
    }

    /**
    @notice Ether'in kontrata direkt olarak gönderilmesini engeller
    */
    receive() external payable {
        revert("Direct ETH transfers not allowed.");
    }
}