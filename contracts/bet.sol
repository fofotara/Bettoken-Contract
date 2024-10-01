// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

/**
@title Bettoken
*/
contract Bettoken is ERC20, Ownable, ReentrancyGuard, Pausable, ERC20Permit {

    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 10 ** 18;

    // Token Dağılımı
    uint256 public constant MARKET_ALLOCATION = 500_000_000 * 10 ** 18;   // %50 Piyasa için
    uint256 public constant TEAM_ALLOCATION = 100_000_000 * 10 ** 18;     // %10 Takım için (kilitli)
    uint256 public constant PRESALE_ALLOCATION = 200_000_000 * 10 ** 18;  // %20 Ön Satış
    uint256 public constant AIRDROP_ALLOCATION = 50_000_000 * 10 ** 18;   // %5 Airdrop ve Bonuslar
    uint256 public constant BURN_ALLOCATION = 150_000_000 * 10 ** 18;     // %15 Yakılacak Tokenlar

    // Stake ve Vesting Süreleri
    uint256 public constant STAKE_DURATION = 365 days; // 1 yıl staking
    uint256 public constant VESTING_DURATION = 180 days; // 6 ay vesting

    uint256 public preSaleEndTime; // Pre-sale bitiş tarihi
    bool public preSaleCompleted;  // Pre-sale tamamlanma durumu

    // Kullanıcıların stake bilgileri
    mapping(address => uint256) public stakes;
    mapping(address => uint256) public stakeStartTime;
    mapping(address => uint256) public vestingReleaseTime;

    // Event Definitions
    event PrivateSale(address indexed buyer, uint256 amount, string affiliateCode);
    event PreSaleCompleted();
    event TokensStaked(address indexed staker, uint256 amount, uint256 releaseTime);
    event VestedTokensReleased(address indexed beneficiary, uint256 amount);

    constructor() 
        ERC20("Bettoken", "BETT")
        ERC20Permit("Bettoken")
        Ownable(msg.sender)
    {
        _mint(address(this), TOTAL_SUPPLY);
        _transfer(address(this), msg.sender, MARKET_ALLOCATION);
        _transfer(address(this), msg.sender, PRESALE_ALLOCATION);
        _transfer(address(this), msg.sender, AIRDROP_ALLOCATION);
    }

    // --- Pre-Sale Tamamlama Fonksiyonu ---
    /**
     * @dev Pre-Sale tamamlandığında staking süresi başlar.
     */
    function completePreSale() external onlyOwner {
        require(!preSaleCompleted, "Pre-Sale already completed");
        preSaleEndTime = block.timestamp;
        preSaleCompleted = true;
        emit PreSaleCompleted();
    }

    // --- Stake Etme Fonksiyonu ---
    /**
     * @dev Private Sale tamamlandıktan sonra kullanıcıların tokenlarını stake etmesine izin verir.
     * Pre-Sale tamamlandıktan sonra stake süresi başlar.
     * @param amount Stake edilecek token miktarı.
     */
    function stakeTokens(uint256 amount) external nonReentrant whenNotPaused {
        require(preSaleCompleted, "Pre-Sale must be completed before staking");
        require(amount > 0, "Stake amount must be greater than zero");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance to stake");

        _transfer(msg.sender, address(this), amount);
        stakes[msg.sender] += amount;
        stakeStartTime[msg.sender] = block.timestamp;
        vestingReleaseTime[msg.sender] = block.timestamp + STAKE_DURATION + VESTING_DURATION;

        emit TokensStaked(msg.sender, amount, vestingReleaseTime[msg.sender]);
    }

    // --- Stake ve Vesting Çözme (Serbest Bırakma) Fonksiyonu ---
    /**
     * @dev Kullanıcılar stake süresi ve ardından vesting süresi sonunda tokenlarını serbest bırakabilir.
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

    // --- Diğer Fonksiyonlar ---
    // Diğer mevcut fonksiyonlar (Private sale, airdrop, yakma vs.) aynı kalabilir.
}
