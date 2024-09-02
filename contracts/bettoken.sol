// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Bettoken is ERC20, Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    uint256 public constant TOTAL_SUPPLY = 200_000_000 * 10 ** 18;

    // Private Sale variables
    uint256 public privateSaleTarget = 1_000_000 * 10 ** 18;
    uint256 public privateSaleTokens = 38_835_764 * 10 ** 18;
    uint256 public privateSaleStartPrice = 0.001 * 10 ** 18;
    uint256 public privateSaleEndPrice = 0.0505 * 10 ** 18;
    uint256 public privateSaleSoldTokens = 0;

    // Pre-Sale variables
    uint256 public preSaleTarget = 19_000_000 * 10 ** 18;
    uint256 public preSaleTokens = 161_164_236 * 10 ** 18;
    uint256 public preSaleStartPrice = 0.0505 * 10 ** 18;
    uint256 public preSaleEndPrice = 0.1 * 10 ** 18;
    uint256 public preSaleSoldTokens = 0;

    // Sale States
    enum SaleStage { NONE, PRIVATE, PRESALE }
    SaleStage public stage = SaleStage.NONE;

    // Vesting Parameters
    struct VestingSchedule {
        uint256 totalAmount;
        uint256 releasedAmount;
        uint256 startTime;
        uint256 duration;
        uint256 interval;
    }

    mapping(address => VestingSchedule) public vestingSchedules;

    uint256 public vestingDuration = 180 days;
    uint256 public stakeDuration = 365 days;

    AggregatorV3Interface[] public priceFeeds;

    uint256 public constant TIME_LOCK = 1 days;
    uint256 public lastActionTime;

    // Event Definitions
    event PrivateSale(address indexed buyer, uint256 amount);
    event PreSale(address indexed buyer, uint256 amount);
    event TokensStaked(address indexed staker, uint256 amount, uint256 releaseTime);
    event VestedTokensReleased(address indexed beneficiary, uint256 amount);
    event StageChanged(SaleStage newStage);
    event FundsWithdrawn(address indexed owner, uint256 amount);

    /**
     * @dev Constructor to initialize the Bettoken contract.
     * @param _priceFeeds An array of Chainlink price feed addresses.
     * 
     * TR: Bettoken kontratını başlatan yapıcı fonksiyon.
     * @param _priceFeeds Chainlink fiyat beslemelerinin adreslerini içeren bir dizi.
     */
    constructor(address[] memory _priceFeeds) ERC20("Bettoken", "BETT") Ownable(msg.sender) {
        _mint(address(this), TOTAL_SUPPLY);
        for (uint256 i = 0; i < _priceFeeds.length; i++) {
            priceFeeds.push(AggregatorV3Interface(_priceFeeds[i]));
        }
    }

    /**
     * @dev Gets the latest price from multiple Chainlink oracles and calculates the average.
     * The average price from the oracles.
     *
     * TR: Birden fazla Chainlink oracle'dan en son fiyatı alır ve ortalamasını hesaplar.
     * @return Oracle'lardan gelen ortalama fiyat.
     */
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
        return totalPrice.div(priceFeeds.length).mul(10 ** 10);
    }

    /**
    * @dev Returns the total supply of the token.
    * 
    * TR: Token'ın toplam arzını döner.
    */
    function getTotalSupply() external pure returns (uint256) {
        return TOTAL_SUPPLY;
    }
    /**
     * @dev Starts the private sale stage.
     *
     * TR: Özel satış aşamasını başlatır.
     */
    function startPrivateSale() external onlyOwner {
        require(stage == SaleStage.NONE, "Private Sale can only start from NONE stage.");
        require(privateSaleSoldTokens == 0, "Private Sale tokens should be unsold at start.");
        require(preSaleSoldTokens == 0, "Pre-Sale should not have started before Private Sale.");
        require(block.timestamp >= lastActionTime + TIME_LOCK, "Time lock in effect");

        stage = SaleStage.PRIVATE;
        lastActionTime = block.timestamp;
        emit StageChanged(stage);
    }

    /**
     * @dev Starts the pre-sale stage.
     *
     * TR: Ön satış aşamasını başlatır.
     */
    function startPreSale() external onlyOwner {
        require(stage == SaleStage.PRIVATE, "Pre-Sale can only start after Private Sale.");
        require(privateSaleSoldTokens == privateSaleTokens, "Private Sale must be completed before starting Pre-Sale.");
        require(block.timestamp >= lastActionTime + TIME_LOCK, "Time lock in effect");
        
        stage = SaleStage.PRESALE;
        lastActionTime = block.timestamp;
        emit StageChanged(stage);
    }

    /**
     * @dev Allows users to buy tokens during the sale stages.
     * @param usdAmount The amount in USD to purchase tokens.
     *
     * TR: Kullanıcıların satış aşamalarında token satın almasına izin verir.
     * @param usdAmount Token satın almak için gerekli USD miktarı.
     */
    function buyTokens(uint256 usdAmount) external payable nonReentrant whenNotPaused {
        require(stage != SaleStage.NONE, "No sale is active.");

        uint256 latestPrice = getLatestPrice();
        require(latestPrice > 0, "Invalid price from oracle");

        uint256 tokensToBuy;
        if (stage == SaleStage.PRIVATE) {
            require(privateSaleSoldTokens < privateSaleTokens, "Private Sale sold out.");
            tokensToBuy = calculateTokens(usdAmount.mul(latestPrice).div(1 ether), privateSaleStartPrice, privateSaleEndPrice, privateSaleSoldTokens, privateSaleTokens);
            privateSaleSoldTokens = privateSaleSoldTokens.add(tokensToBuy);
            require(privateSaleSoldTokens <= privateSaleTokens, "Exceeds Private Sale token limit.");
            createVestingSchedule(msg.sender, tokensToBuy, block.timestamp.add(stakeDuration), vestingDuration, 30 days);
            emit PrivateSale(msg.sender, tokensToBuy);
        } else if (stage == SaleStage.PRESALE) {
            require(preSaleSoldTokens < preSaleTokens, "Pre-Sale sold out.");
            require(usdAmount >= 100 * 10 ** 18 && usdAmount <= 3_000 * 10 ** 18, "Purchase amount out of limits.");
            tokensToBuy = calculateTokens(usdAmount.mul(latestPrice).div(1 ether), preSaleStartPrice, preSaleEndPrice, preSaleSoldTokens, preSaleTokens);
            preSaleSoldTokens = preSaleSoldTokens.add(tokensToBuy);
            require(preSaleSoldTokens <= preSaleTokens, "Exceeds Pre-Sale token limit.");
            _transfer(address(this), msg.sender, tokensToBuy);
            emit PreSale(msg.sender, tokensToBuy);
        }

        if ((stage == SaleStage.PRIVATE && privateSaleSoldTokens == privateSaleTokens) ||
            (stage == SaleStage.PRESALE && preSaleSoldTokens == preSaleTokens)) {
            _pause();
        }
    }

    /**
     * @dev Calculates the number of tokens that can be purchased based on the USD amount.
     * @param usdAmount The amount of USD used for purchase.
     * @param startPrice The starting price of the token.
     * @param endPrice The ending price of the token.
     * @param soldTokens The number of tokens already sold.
     * @param totalTokens The total number of tokens available for sale.
     * The number of tokens that can be purchased.
     *
     * TR: USD miktarına göre satın alınabilecek token sayısını hesaplar.
     * @param usdAmount Satın alma için kullanılan USD miktarı.
     * @param startPrice Token'ın başlangıç fiyatı.
     * @param endPrice Token'ın bitiş fiyatı.
     * @param soldTokens Zaten satılmış olan token sayısı.
     * @param totalTokens Satış için mevcut toplam token sayısı.
     * @return Satın alınabilecek token sayısı.
     */
    function calculateTokens(uint256 usdAmount, uint256 startPrice, uint256 endPrice, uint256 soldTokens, uint256 totalTokens) internal pure returns (uint256) {
        require(usdAmount > 0, "USD amount must be greater than 0");
        require(totalTokens > 0, "Total tokens must be greater than 0");
        require(soldTokens <= totalTokens, "Sold tokens exceed available tokens");

        uint256 tokenRange = endPrice.sub(startPrice);
        uint256 currentPrice = startPrice.add(
            tokenRange.mul(soldTokens).div(totalTokens)
        );

        require(currentPrice >= startPrice && currentPrice <= endPrice, "Invalid token price calculated");

        uint256 tokens = usdAmount.div(currentPrice);
        require(tokens > 0, "Calculated tokens must be greater than 0");

        return tokens;
    }

    /**
     * @dev Creates a vesting schedule for the beneficiary.
     * @param beneficiary The address of the beneficiary.
     * @param amount The amount of tokens to be vested.
     * @param startTime The start time of the vesting.
     * @param duration The total duration of the vesting.
     * @param interval The interval at which the tokens are released.
     *
     * TR: Yararlanıcı için bir vesting planı oluşturur.
     * @param beneficiary Yararlanıcının adresi.
     * @param amount Vesting yapılacak token miktarı.
     * @param startTime Vesting'in başlama zamanı.
     * @param duration Vesting'in toplam süresi.
     * @param interval Tokenların serbest bırakılma aralığı.
     */
    function createVestingSchedule(address beneficiary, uint256 amount, uint256 startTime, uint256 duration, uint256 interval) internal {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        schedule.totalAmount = schedule.totalAmount.add(amount);
        schedule.startTime = startTime;
        schedule.duration = duration;
        schedule.interval = interval;
    }

    /**
     * @dev Releases the vested tokens for the caller.
     *
     * TR: Çağrıcı için vesting yapılmış tokenları serbest bırakır.
     */
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

    /**
     * @dev Halts all token sales and pauses the contract.
     *
     * TR: Tüm token satışlarını durdurur ve kontratı duraklatır.
     */
    function haltSales() external onlyOwner {
        require(privateSaleSoldTokens == privateSaleTokens || preSaleSoldTokens == preSaleTokens, 
                "Sales targets not yet met.");
        stage = SaleStage.NONE;
        _pause();
        emit StageChanged(stage);
    }

    /**
     * @dev Withdraws tokens from the contract in case of an emergency.
     * @param tokenAddress The address of the token to withdraw.
     * @param amount The amount of tokens to withdraw.
     *
     * TR: Acil durumda kontrattan token çeker.
     * @param tokenAddress Çekilecek token'ın adresi.
     * @param amount Çekilecek token miktarı.
     */
    function emergencyWithdraw(address tokenAddress, uint256 amount) external onlyOwner nonReentrant {
        require(block.timestamp >= lastActionTime + TIME_LOCK, "Time lock in effect");
        IERC20(tokenAddress).transfer(owner(), amount);
        lastActionTime = block.timestamp;
        emit FundsWithdrawn(owner(), amount);
    }

    /**
     * @dev Withdraws funds from the contract.
     *
     * TR: Kontrattan fon çeker.
     */
    function withdrawFunds() external onlyOwner nonReentrant {
        require(block.timestamp >= lastActionTime + TIME_LOCK, "Time lock in effect");
        uint256 amount = address(this).balance;
        payable(owner()).transfer(amount);
        lastActionTime = block.timestamp;
        emit FundsWithdrawn(owner(), amount);
    }

    /**
     * @dev Pauses the contract.
     *
     * TR: Kontratı duraklatır.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     *
     * TR: Kontratı duraklatmadan çıkarır.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    fallback() external payable {
        revert("Direct ETH transfers not allowed.");
    }

    receive() external payable {
        revert("Direct ETH transfers not allowed.");
    }
}
