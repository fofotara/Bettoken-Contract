// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

/**
@title Bettoken
*/
contract Bettoken is ERC20, Ownable, ReentrancyGuard, Pausable, ERC20Permit {
    using SafeMath for uint256;

    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 10 ** 18;

    // Token Dağılımı
    uint256 public constant MARKET_ALLOCATION = 500_000_000 * 10 ** 18;   // %50 Piyasa için
    uint256 public constant TEAM_ALLOCATION = 100_000_000 * 10 ** 18;     // %10 Takım için (kilitli)
    uint256 public constant PRESALE_ALLOCATION = 200_000_000 * 10 ** 18;  // %20 Ön Satış
    uint256 public constant AIRDROP_ALLOCATION = 50_000_000 * 10 ** 18;   // %5 Airdrop ve Bonuslar
    uint256 public constant BURN_ALLOCATION = 150_000_000 * 10 ** 18;     // %15 Yakılacak Tokenlar

    // Airdrop için zaman ve liste tanımları
    uint256 public airdropStartTime;
    uint256 public airdropEndTime;
    mapping(address => bool) public airdropEligible;
    bool public airdropActive = false;

    // Takım tokenlarının kilit süresi
    uint256 public teamTokenReleaseTime;

    // Private Sale variables
    uint256 public constant PRIVATE_SALE_TOKENS = 38_835_764 * 10 ** 18;
    uint256 public privateSaleSoldTokens = 0;
    uint256 public privateSaleStartPrice = 0.001 * 10 ** 18;
    uint256 public privateSaleEndPrice = 0.0505 * 10 ** 18;

    // Pre-Sale variables
    uint256 public constant PRESALE_TOKENS = 161_164_236 * 10 ** 18;
    uint256 public preSaleSoldTokens = 0;
    uint256 public preSaleStartPrice = 0.0505 * 10 ** 18;
    uint256 public preSaleEndPrice = 0.1 * 10 ** 18;
    uint256 public minPurchaseAmount = 100 * 10 ** 18;
    uint256 public maxPurchaseAmount = 3000 * 10 ** 18;

    // Vesting Variables
    uint256 public constant STAKE_DURATION = 365 days; // 1 yıl
    uint256 public constant VESTING_DURATION = 180 days; // 6 ay
    mapping(address => VestingSchedule) public vestingSchedules;

    struct VestingSchedule {
        uint256 totalAmount;
        uint256 releasedAmount;
        uint256 startTime;
        uint256 duration;
        uint256 interval;
    }

    // Satın alım sınırlarını izlemek için mapping
    mapping(address => uint256) public userPurchaseAmounts;

    // Affiliate system
    mapping(address => string) public affiliateCodes;
    mapping(string => address) public affiliateOwners;
    uint8 public affiliateRewardPercentage = 5;  // Veri tipini uint8 yaptık

    // Event Definitions
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

    constructor() 
        ERC20("Bettoken", "BETT")
        ERC20Permit("Bettoken")
        Ownable(msg.sender)
    {
        _mint(address(this), TOTAL_SUPPLY); // Tüm tokenları kontrata mint et

        // Token dağıtımı
        _transfer(address(this), msg.sender, MARKET_ALLOCATION); // Piyasa için
        _transfer(address(this), msg.sender, PRESALE_ALLOCATION); // Ön satış için
        _transfer(address(this), msg.sender, AIRDROP_ALLOCATION); // Airdrop ve bonuslar için

        // Takım tokenlarını kilitle (1 yıl kilitli)
        teamTokenReleaseTime = block.timestamp + 365 days;
        emit TeamTokensLocked(TEAM_ALLOCATION);

        // Yakılacak tokenlar
        _burn(address(this), BURN_ALLOCATION);
        emit TokensBurned(BURN_ALLOCATION);
    }

    // --- Private Sale Fonksiyonları ---

    function buyTokensPrivateSale(uint256 usdAmount, string memory affiliateCode) external payable nonReentrant whenNotPaused {
        require(privateSaleSoldTokens < PRIVATE_SALE_TOKENS, "Private Sale sold out");

        uint256 tokensToBuy = calculateTokensPrivateSale(usdAmount);
        privateSaleSoldTokens = privateSaleSoldTokens.add(tokensToBuy);
        require(privateSaleSoldTokens <= PRIVATE_SALE_TOKENS, "Exceeds Private Sale token limit");

        _transfer(address(this), msg.sender, tokensToBuy);

        if (bytes(affiliateCode).length > 0) {
            address affiliate = affiliateOwners[affiliateCode];
            require(affiliate != address(0), "Invalid affiliate code");

            uint256 affiliateReward = tokensToBuy.mul(affiliateRewardPercentage).div(100);
            _transfer(address(this), affiliate, affiliateReward);
            emit AffiliateRewardPaid(affiliate, affiliateReward);
        }

        emit PrivateSale(msg.sender, tokensToBuy, affiliateCode);
    }

    // --- Pre-Sale Fonksiyonları ---

    function buyTokensPreSale(uint256 usdAmount, string memory affiliateCode) external payable nonReentrant whenNotPaused {
        require(preSaleSoldTokens < PRESALE_TOKENS, "Pre-Sale sold out");
        require(usdAmount >= minPurchaseAmount && usdAmount <= maxPurchaseAmount, "Purchase amount out of limits");

        uint256 tokensToBuy = calculateTokensPreSale(usdAmount);
        
        // Bellek optimizasyonu: userPurchaseAmounts için bellek değişkeni ekledik
        uint256 userPurchaseAmount = userPurchaseAmounts[msg.sender].add(usdAmount);
        require(userPurchaseAmount <= maxPurchaseAmount, "Exceeds maximum purchase limit per user");
        userPurchaseAmounts[msg.sender] = userPurchaseAmount;

        preSaleSoldTokens = preSaleSoldTokens.add(tokensToBuy);
        require(preSaleSoldTokens <= PRESALE_TOKENS, "Exceeds Pre-Sale token limit");

        _transfer(address(this), msg.sender, tokensToBuy);

        if (bytes(affiliateCode).length > 0) {
            address affiliate = affiliateOwners[affiliateCode];
            require(affiliate != address(0), "Invalid affiliate code");

            uint256 affiliateReward = tokensToBuy.mul(affiliateRewardPercentage).div(100);
            _transfer(address(this), affiliate, affiliateReward);
            emit AffiliateRewardPaid(affiliate, affiliateReward);
        }

        emit PreSale(msg.sender, tokensToBuy, affiliateCode);
    }

    // --- Airdrop Fonksiyonları ---

    /**
     * @dev Airdrop süresini başlatır ve bitiş zamanını ayarlar.
     * @param _startTime Airdrop başlangıç zamanı.
     * @param _endTime Airdrop bitiş zamanı.
     */
    function startAirdrop(uint256 _startTime, uint256 _endTime) external onlyOwner {
        require(_startTime < _endTime, "Invalid airdrop period");
        require(_startTime > block.timestamp, "Start time must be in the future");
        require(!airdropActive, "Airdrop already active");

        airdropStartTime = _startTime;
        airdropEndTime = _endTime;
        airdropActive = true;

        emit AirdropStarted(_startTime, _endTime);
    }

    /**
     * @dev Airdrop süresini bitirir.
     */
    function endAirdrop() external onlyOwner {
        require(airdropActive, "Airdrop is not active");
        require(block.timestamp > airdropEndTime, "Airdrop period not finished");

        airdropActive = false;

        emit AirdropEnded();
    }

    /**
     * @dev Airdrop için uygun adresleri belirler.
     * @param recipients Airdrop yapılacak adresler.
     */
    function setAirdropEligible(address[] memory recipients) external onlyOwner {
        require(airdropActive, "Airdrop must be active");

        for (uint256 i = 0; i < recipients.length; i++) {
            airdropEligible[recipients[i]] = true;
        }
    }

    /**
     * @dev Airdrop ile tokenları dağıtır.
     * @param recipients Airdrop yapılacak adresler.
     * @param amount Her alıcıya dağıtılacak token miktarı.
     */
    function distributeAirdrop(address[] memory recipients, uint256 amount) external onlyOwner nonReentrant {
        require(airdropActive, "Airdrop is not active");
        require(block.timestamp >= airdropStartTime && block.timestamp <= airdropEndTime, "Airdrop period is over");

        uint256 length = recipients.length; // Döngü içinde tekrar tekrar depodan okunmayı engelledik
        for (uint256 i = 0; i < length; i++) {
            if (airdropEligible[recipients[i]]) {
                _transfer(address(this), recipients[i], amount);
                emit AirdropDistributed(recipients[i], amount);
                airdropEligible[recipients[i]] = false;
            }
        }
    }

    // --- Takım Tokenları Serbest Bırakma ---

    function releaseTeamTokens() external onlyOwner {
        require(block.timestamp >= teamTokenReleaseTime, "Tokens are still locked");
        require(balanceOf(address(this)) >= TEAM_ALLOCATION, "Insufficient tokens for team");

        _transfer(address(this), owner(), TEAM_ALLOCATION);
        emit TeamTokensReleased(TEAM_ALLOCATION);
    }

    // --- Satışların Tamamlanması ---

    function endSale() external onlyOwner {
        if (privateSaleSoldTokens == PRIVATE_SALE_TOKENS) {
            _pause(); // Private Sale tamamlandıysa kontratı duraklat
            emit PrivateSaleCompleted();
        } else if (preSaleSoldTokens == PRESALE_TOKENS) {
            _pause(); // Pre-Sale tamamlandıysa kontratı duraklat
            emit PreSaleCompleted();
        }
    }

    // --- Vesting Fonksiyonları ---

    function createVestingSchedule(address beneficiary, uint256 amount, uint256 startTime, uint256 duration, uint256 interval) internal {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        schedule.totalAmount = schedule.totalAmount.add(amount);
        schedule.startTime = startTime;
        schedule.duration = duration;
        schedule.interval = interval;
    }

    function releaseVestedTokens() external nonReentrant {
        VestingSchedule storage schedule = vestingSchedules[msg.sender];
        require(block.timestamp >= schedule.startTime, "Vesting has not started yet");

        uint256 vestedAmount = schedule.totalAmount.mul(block.timestamp.sub(schedule.startTime)).div(schedule.duration);
        uint256 releasableAmount = vestedAmount.sub(schedule.releasedAmount);

        require(releasableAmount > 0, "No tokens available for release");

        schedule.releasedAmount = schedule.releasedAmount.add(releasableAmount);
        _transfer(address(this), msg.sender, releasableAmount);

        emit VestedTokensReleased(msg.sender, releasableAmount);
    }

    // --- Token ve Fon Çekme (Withdraw Tokens and Funds) ---

    function withdrawTokens(uint256 amount) external onlyOwner nonReentrant {
        require(balanceOf(address(this)) >= amount, "Insufficient tokens in contract");
        _transfer(address(this), owner(), amount);
    }

    function withdrawFunds() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");

        (bool success, ) = owner().call{value: balance}("");
        require(success, "Withdraw failed");
    }

    // --- Acil Durum Durdurma ---

    function emergencyPause() external onlyOwner {
        _pause(); // Kontratı duraklatır
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // --- Satın Alım Miktarı Hesaplama ---

    function calculateTokensPrivateSale(uint256 usdAmount) internal view returns (uint256) {
        uint256 tokenRange = privateSaleEndPrice.sub(privateSaleStartPrice);
        uint256 currentPrice = privateSaleStartPrice.add(
            tokenRange.mul(privateSaleSoldTokens).div(PRIVATE_SALE_TOKENS)
        );
        require(currentPrice >= privateSaleStartPrice && currentPrice <= privateSaleEndPrice, "Invalid price calculation");

        uint256 tokens = usdAmount.div(currentPrice);
        return tokens;
    }

    function calculateTokensPreSale(uint256 usdAmount) internal view returns (uint256) {
        uint256 tokenRange = preSaleEndPrice.sub(preSaleStartPrice);
        uint256 currentPrice = preSaleStartPrice.add(
            tokenRange.mul(preSaleSoldTokens).div(PRESALE_TOKENS)
        );
        require(currentPrice >= preSaleStartPrice && currentPrice <= preSaleEndPrice, "Invalid price calculation");

        uint256 tokens = usdAmount.div(currentPrice);
        return tokens;
    }

    fallback() external payable {
        revert("Direct ETH transfers not allowed.");
    }

    receive() external payable {
        revert("Direct ETH transfers not allowed.");
    }
}
