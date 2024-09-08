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

    // Affiliate ödül yüzdesi
    uint256 public affiliateRewardPercentage; // Affiliate ödül yüzdesi (%5 olarak varsayılan)

    // Pre-Sale değişkenleri
    uint256 public preSaleTokens = 161_164_236 * 10 ** 18; // Pre-Sale sırasında satılacak BETT miktarı
    uint256 public preSaleTargetFunds = 19_000_000 * 10 ** 18; // Hedeflenen fon miktarı (19 milyon USD)
    uint256 public preSaleStartPrice = 0.0505 * 10 ** 18; // Pre-Sale başlangıç fiyatı
    uint256 public preSaleEndPrice = 0.1 * 10 ** 18; // Pre-Sale bitiş fiyatı
    uint256 public preSaleSoldTokens = 0;
    uint256 public preSaleStartTime; // Pre-Sale başlangıç zamanı
    bool public preSaleActive = false; // Pre-Sale aktif mi?

    // Pre-Sale satın alma sınırları
    uint256 public minPurchaseAmountPreSale = 100 * 10 ** 18; // Minimum satın alma miktarı (100 USD)
    uint256 public maxPurchaseAmountPreSale = 3000 * 10 ** 18; // Maksimum satın alma miktarı (3000 USD)

    // Vesting Planı yapısı
    struct VestingSchedule {
        uint256 totalAmount;
        uint256 releasedAmount;
        uint256 startTime;
        uint256 duration;
        uint256 interval;
    }

    mapping(address => VestingSchedule) public vestingSchedules;

    // Satış aşaması değişkeni
    bool public privateSaleActive = false; // Private Sale aktif mi değil mi

    // Etkinlikler
    event PrivateSaleStarted(uint256 affiliateRewardPercentage, uint256 startTime);
    event PrivateSale(address indexed buyer, uint256 amount);
    event AffiliateRewardPaid(address indexed affiliate, uint256 reward);
    event TokensStaked(address indexed staker, uint256 amount, uint256 releaseTime);
    event VestedTokensReleased(address indexed beneficiary, uint256 amount);
    event PrivateSaleEnded();
    event PreSaleStarted(uint256 startTime);
    event PreSaleEnded();
    event TokensWithdrawn(uint256 amount);
    event ETHWithdrawn(uint256 amount);

    // Yapıcı fonksiyon
    constructor() ERC20("Bettoken", "BETT") Ownable(msg.sender) {
        _mint(address(this), TOTAL_SUPPLY);
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
     * @dev Private Sale sırasında token satın alımını gerçekleştirir.
     */
    function buyTokensPrivateSale(uint256 usdAmount) external payable nonReentrant whenNotPaused {
        require(privateSaleActive, "Private Sale is not active");
        require(usdAmount >= 50 * 10 ** 18, "Minimum USD amount required is 50 USD");
        uint256 tokensToBuy = calculateTokensPrivateSale(usdAmount);
        require(tokensToBuy <= 1000 * 10 ** 18, "Exceeds maximum token purchase limit");

        privateSaleSoldTokens += tokensToBuy;

        if (privateSaleSoldTokens >= privateSaleTokens) {
            privateSaleActive = false;
            emit PrivateSaleEnded();
        }

        createVestingSchedule(msg.sender, tokensToBuy, block.timestamp + 365 days, 180 days, 30 days);
    }


    /**
     * @dev Pre-Sale'i başlatır.
     */
    function startPreSale() external onlyOwner {
        require(!preSaleActive, "Pre-Sale is already active");
        preSaleActive = true;
        preSaleStartTime = block.timestamp;
        emit PreSaleStarted(preSaleStartTime);
    }

    /**
     * @dev Pre-Sale sırasında token satın alımını gerçekleştirir.
     */
    function buyTokensPreSale(uint256 usdAmount) external payable nonReentrant whenNotPaused {
        require(preSaleActive, "Pre-Sale is not active");
        require(usdAmount >= minPurchaseAmountPreSale, "Amount is below minimum purchase limit");
        require(usdAmount <= maxPurchaseAmountPreSale, "Amount exceeds maximum purchase limit");

        uint256 tokensToBuy = calculateTokensPreSale(usdAmount);
        require(preSaleSoldTokens + tokensToBuy <= preSaleTokens, "Exceeds Pre-Sale token limit");

        preSaleSoldTokens += tokensToBuy;

        if (preSaleSoldTokens >= preSaleTokens) {
            preSaleActive = false;
            emit PreSaleEnded();
        }

        _transfer(address(this), msg.sender, tokensToBuy);
    }

    /**
     * @dev Pre-Sale için token fiyatını USD cinsinden hesaplar.
     * @param usdAmount Satın alınacak token miktarının hesaplanacağı USD miktarı.
     * @return Satın alınacak token miktarı.
     */
    function calculateTokensPreSale(uint256 usdAmount) public view returns (uint256) {
        uint256 currentPrice = preSaleStartPrice + (
            (preSaleEndPrice - preSaleStartPrice) * preSaleSoldTokens / preSaleTokens
        );
        uint256 tokens = usdAmount / currentPrice;
        return tokens;
    }

    /**
     * @dev Private Sale için token fiyatını USD cinsinden hesaplar.
     */
    function calculateTokensPrivateSale(uint256 usdAmount) public view returns (uint256) {
        uint256 currentPrice = privateSaleStartPrice + (
            (privateSaleEndPrice - privateSaleStartPrice) * privateSaleSoldTokens / privateSaleTokens
        );
        uint256 tokens = usdAmount / currentPrice;
        return tokens;
    }

    /**
     * @dev Vesting programı oluşturur.
     */
    function createVestingSchedule(
        address beneficiary,
        uint256 amount,
        uint256 startTime,
        uint256 duration,
        uint256 interval
    ) internal {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        schedule.totalAmount += amount;
        schedule.startTime = startTime;
        schedule.duration = duration;
        schedule.interval = interval;
    }

    /**
     * @dev Private Sale'i sonlandırır.
     */
    function endPrivateSale() external onlyOwner {
        require(privateSaleActive, "Private Sale is not active");
        privateSaleActive = false;
        emit PrivateSaleEnded();
    }

    /**
     * @dev Pre-Sale'i sonlandırır.
     */
    function endPreSale() external onlyOwner {
        require(preSaleActive, "Pre-Sale is not active");
        preSaleActive = false;
        emit PreSaleEnded();
    }

    /**
     * @dev Kontratta bulunan tokenları çekmeye yarar.
     */
    function withdrawTokens() external onlyOwner {
        uint256 balance = balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        _transfer(address(this), owner(), balance);
        emit TokensWithdrawn(balance);
    }

    /**
     * @dev Kontratta bulunan ETH'yi çekmeye yarar.
     */
    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        (bool success, ) = owner().call{value: balance}("");
        require(success, "Transfer failed");
        emit ETHWithdrawn(balance);
    }
}
