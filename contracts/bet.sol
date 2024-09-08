// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Bettoken is ERC20, Ownable, ReentrancyGuard, Pausable {

    // Total Supply tanımı
    uint256 public constant TOTAL_SUPPLY = 200_000_000 * 10 ** 18;

    // Private Sale değişkenleri
    uint256 public privateSaleTokens = 38_835_764 * 10 ** 18;
    uint256 public privateSaleStartPrice = 0.001 * 10 ** 18; // 0.001 USD başlangıç fiyatı
    uint256 public privateSaleEndPrice = 0.0505 * 10 ** 18; // 0.0505 USD bitiş fiyatı
    uint256 public privateSaleSoldTokens = 0;
    uint256 public privateSaleStartTime; // Private sale başlangıç zamanı

    // Private Sale için limitler
    uint256 public maxTokensPerUser = 1000 * 10 ** 18; // Maksimum satın alınabilecek token miktarı
    uint256 public minimumUsdAmount = 50 * 10 ** 18;   // Minimum satın alınabilecek USD miktarı
    uint256 public minTokensPerUserPrivateSale = 100 * 10 ** 18;  // En az alınabilecek token miktarı (sadece private sale için)
    uint256 public maxTokensPerTransactionPrivateSale = 500 * 10 ** 18; // Bir işlemde alınabilecek en fazla token miktarı (sadece private sale için)

    // Stake ve Vesting süreleri
    uint256 public stakeDuration = 365 days; // 1 yıllık stake süresi
    uint256 public vestingDuration = 180 days; // 6 aylık vesting süresi
    uint256 public vestingInterval = 30 days; // 30 günlük serbest bırakma aralığı

    // Vesting Planı yapısı
    struct VestingSchedule {
        uint256 totalAmount;
        uint256 releasedAmount;
        uint256 startTime;
        uint256 duration;
        uint256 interval;
    }

    mapping(address => VestingSchedule) public vestingSchedules;

    // Affiliate ve Whitelist için değişkenler
    mapping(address => bool) public whitelist; // Whitelist için mapping
    mapping(address => string) public userToAffiliateCode; // Kullanıcının affiliate kodu
    mapping(string => address) public affiliateCodes; // Affiliate kodu ile adres eşleşmesi
    uint256 public affiliateRewardPercentage = 5; // Affiliate ödül yüzdesi (%5)

    // Satış aşaması değişkeni
    bool public privateSaleActive = false; // Private Sale aktif mi değil mi

    // Etkinlikler
    event PrivateSaleStarted(uint256 affiliateRewardPercentage, uint256 startTime);
    event PrivateSale(address indexed buyer, uint256 amount);
    event AffiliateRewardPaid(address indexed affiliate, uint256 reward);
    event TokensStaked(address indexed staker, uint256 amount, uint256 releaseTime);
    event VestedTokensReleased(address indexed beneficiary, uint256 amount);
    event PrivateSaleEnded();
    event WhitelistedAddressRemoved(address indexed _address);
    event WhitelistedAddressAdded(address indexed _address);
    event TokensWithdrawn(uint256 amount);
    event ETHWithdrawn(uint256 amount);

    // Yapıcı fonksiyon
    constructor() ERC20("Bettoken", "BETT") Ownable(msg.sender) {
        _mint(address(this), TOTAL_SUPPLY);
    }

    /**
     * @dev Whitelist'e adres ekler. Bu fonksiyon sadece kontrat sahibi tarafından çağrılabilir.
     * @param _address Whitelist'e eklenecek adres.
     */
    function addToWhitelist(address _address) external onlyOwner {
        whitelist[_address] = true;
        emit WhitelistedAddressAdded(_address); // Event tetikle
    }

    /**
     * @dev Whitelist'ten adres çıkarır. Bu fonksiyon sadece kontrat sahibi tarafından çağrılabilir.
     * @param _address Whitelist'ten çıkarılacak adres.
     */
    function removeFromWhitelist(address _address) external onlyOwner {
        require(whitelist[_address], "Address not in whitelist");
        whitelist[_address] = false;
        emit WhitelistedAddressRemoved(_address); // Event tetikle
    }

    /**
     * @dev Affiliate kodu atar. Bu fonksiyon sadece kontrat sahibi tarafından çağrılabilir.
     * @param user Affiliate kodu atanacak kullanıcı.
     * @param code Kullanıcıya atanacak affiliate kodu.
     */
    function addAffiliate(address user, string calldata code) external onlyOwner {
        require(bytes(userToAffiliateCode[user]).length == 0, "This address already has an affiliate code.");
        require(bytes(code).length >= 3 && bytes(code).length <= 20, "Affiliate code must be between 3 and 20 characters.");
        require(affiliateCodes[code] == address(0), "Affiliate code already taken");
        affiliateCodes[code] = user;
        userToAffiliateCode[user] = code;
    }

    /**
     * @dev Private Sale'i başlatır ve affiliate ödül yüzdesini belirler.
     * @param _affiliateRewardPercentage Affiliate ödül yüzdesi.
     */
    function startPrivateSale(uint256 _affiliateRewardPercentage) external onlyOwner {
        require(!privateSaleActive, "Private Sale already active");
        require(_affiliateRewardPercentage > 0 && _affiliateRewardPercentage <= 100, "Invalid percentage");

        affiliateRewardPercentage = _affiliateRewardPercentage; // Affiliate yüzdesini ayarla
        privateSaleActive = true; // Private Sale aktif
        privateSaleStartTime = block.timestamp; // Başlangıç zamanını kaydet

        emit PrivateSaleStarted(affiliateRewardPercentage, privateSaleStartTime); // Satış başlama olayını tetikle
    }

    /**
     * @dev Private Sale'in başlangıç zamanını döner.
     * @return Private Sale başlangıç zamanı (timestamp).
     */
    function getPrivateSaleStartTime() external view returns (uint256) {
        require(privateSaleActive, "Private Sale has not started.");
        return privateSaleStartTime;
    }

    /**
     * @dev Token satın alma işlemi yapar. Private Sale sırasında whitelist'e ekli kullanıcılar satın alabilir.
     * @param usdAmount Satın alınacak token miktarı (USD cinsinden).
     * @param affiliateCode Kullanıcı tarafından girilen affiliate kodu (isteğe bağlı).
     */
    function buyTokens(uint256 usdAmount, string calldata affiliateCode) external payable nonReentrant whenNotPaused {
        require(privateSaleActive, "Private Sale is not active");
        require(whitelist[msg.sender], "You are not whitelisted");
        require(privateSaleSoldTokens < privateSaleTokens, "Private Sale sold out.");

        require(usdAmount >= minimumUsdAmount, "Amount is below minimum purchase limit");

        uint256 tokensToBuy = calculateTokens(usdAmount);

        // Private Sale için minimum ve maksimum token limitlerini kontrol et
        require(tokensToBuy >= minTokensPerUserPrivateSale, "Amount is below the minimum token limit for Private Sale");
        require(tokensToBuy <= maxTokensPerTransactionPrivateSale, "Amount exceeds the maximum token limit per transaction for Private Sale");

        require(tokensToBuy <= maxTokensPerUser, "Exceeds maximum token purchase limit");
        
        privateSaleSoldTokens = privateSaleSoldTokens + tokensToBuy;

        // Private Sale hedefi tamamlandı mı kontrol et
        if (privateSaleSoldTokens >= privateSaleTokens) {
            privateSaleActive = false;
            emit PrivateSaleEnded(); // Satış bitti olayı tetikle
        }

        require(privateSaleSoldTokens <= privateSaleTokens, "Exceeds Private Sale token limit.");

        if (bytes(affiliateCode).length > 0) {
            address affiliate = affiliateCodes[affiliateCode];
            require(affiliate != address(0), "Invalid affiliate code");
            
            uint256 affiliateReward = tokensToBuy * affiliateRewardPercentage / 100;
            _transfer(address(this), affiliate, affiliateReward);
            emit AffiliateRewardPaid(affiliate, affiliateReward);
        }

        createVestingSchedule(msg.sender, tokensToBuy, block.timestamp + stakeDuration, vestingDuration, vestingInterval);
        emit TokensStaked(msg.sender, tokensToBuy, block.timestamp + stakeDuration);
    }

    /**
     * @dev USD miktarına göre satın alınabilecek token miktarını hesaplar.
     * @param usdAmount Satın alınacak token miktarının hesaplanacağı USD miktarı.
     * @return Satın alınacak token miktarı.
     */
    function calculateTokens(uint256 usdAmount) public view returns (uint256) {
        uint256 currentPrice = privateSaleStartPrice + (
            (privateSaleEndPrice - privateSaleStartPrice) * privateSaleSoldTokens / privateSaleTokens
        );
        uint256 tokens = usdAmount / currentPrice;
        return tokens;
    }

    /**
     * @dev Belirtilen kullanıcı için bir vesting planı oluşturur.
     * @param beneficiary Vesting planı yapılacak adres.
     * @param amount Vesting planına eklenecek token miktarı.
     * @param startTime Vesting'in başlayacağı zaman (timestamp).
     * @param duration Vesting süresi.
     * @param interval Vesting serbest bırakma aralığı.
     */
    function createVestingSchedule(
        address beneficiary,
        uint256 amount,
        uint256 startTime,
        uint256 duration,
        uint256 interval
    ) internal {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        schedule.totalAmount = schedule.totalAmount + amount;
        schedule.startTime = startTime;
        schedule.duration = duration;
        schedule.interval = interval;
    }

    /**
     * @dev Vesting yapılmış tokenları serbest bırakır.
     */
    function releaseVestedTokens() external nonReentrant {
        VestingSchedule storage schedule = vestingSchedules[msg.sender];
        require(block.timestamp >= schedule.startTime, "Vesting has not started yet");

        uint256 vestedAmount = schedule.totalAmount * (block.timestamp - schedule.startTime) / schedule.duration;
        uint256 releasableAmount = vestedAmount - schedule.releasedAmount;

        require(releasableAmount > 0, "No tokens available for release");

        schedule.releasedAmount = schedule.releasedAmount + releasableAmount;
        _transfer(address(this), msg.sender, releasableAmount);
        emit VestedTokensReleased(msg.sender, releasableAmount);
    }

    /**
     * @dev Private Sale'i sonlandırır. Bu fonksiyon sadece kontrat sahibi tarafından çağrılabilir.
     */
    function endPrivateSale() external onlyOwner {
        require(privateSaleActive, "Private Sale is not active");
        privateSaleActive = false;
        emit PrivateSaleEnded();
    }

    /**
     * @dev Kontratta bulunan tokenları çekmeye yarar. Bu fonksiyon sadece kontrat sahibi tarafından çağrılabilir.
     */
    function withdrawTokens() external onlyOwner {
        uint256 balance = balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        _transfer(address(this), owner(), balance);
        emit TokensWithdrawn(balance);
    }

    /**
     * @dev Kontratta bulunan ETH'yi çekmeye yarar. Bu fonksiyon sadece kontrat sahibi tarafından çağrılabilir.
     */
    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        (bool success, ) = owner().call{value: balance}("");
        require(success, "Transfer failed");
        emit ETHWithdrawn(balance);
    }

    /**
     * @dev Affiliate ödül yüzdesini değiştirir. Bu fonksiyon sadece kontrat sahibi tarafından çağrılabilir.
     * @param _percentage Yeni affiliate ödül yüzdesi.
     */
    function setAffiliateRewardPercentage(uint256 _percentage) external onlyOwner {
        require(_percentage > 0 && _percentage <= 100, "Invalid percentage");
        affiliateRewardPercentage = _percentage;
    }

    /**
     * @dev Private Sale için minimum ve maksimum token limitlerini ayarlar. Bu fonksiyon sadece kontrat sahibi tarafından çağrılabilir.
     * @param _minTokensPrivateSale Private Sale sırasında alınabilecek en az token miktarı.
     * @param _maxTokensPrivateSale Private Sale sırasında bir işlemde alınabilecek en fazla token miktarı.
     */
    function setPrivateSaleTokenLimits(uint256 _minTokensPrivateSale, uint256 _maxTokensPrivateSale) external onlyOwner {
        require(_minTokensPrivateSale > 0, "Minimum token limit must be greater than zero");
        require(_maxTokensPrivateSale > _minTokensPrivateSale, "Maximum token limit must be greater than minimum");
        minTokensPerUserPrivateSale = _minTokensPrivateSale;
        maxTokensPerTransactionPrivateSale = _maxTokensPrivateSale;
    }
}
