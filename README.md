
# Bettoken Smart Contract

This repository contains the `Bettoken` smart contract, a token contract built on the Ethereum blockchain. The contract is designed to handle private and pre-sale stages, with vesting and staking mechanisms for purchased tokens. It also utilizes Chainlink Price Feeds to ensure reliable token pricing during sales.

## Contract Overview

The `Bettoken` contract is an ERC20 token with additional features:

- **Private Sale**: A stage where a fixed number of tokens are sold at a price that increases linearly.
- **Pre-Sale**: A subsequent stage where tokens are sold at a higher price, also increasing linearly.
- **Vesting**: Purchased tokens during the private sale are vested and gradually released to the buyer.
- **Staking**: The contract allows for tokens to be staked with a fixed vesting schedule.
- **Emergency Withdraw**: Allows the owner to withdraw tokens or funds in case of an emergency.
- **Price Feed**: Chainlink Price Feeds are integrated to fetch the latest price data to determine token purchase rates.
- **Time-lock Mechanism**: Critical functions such as starting sales and withdrawals are time-locked to ensure security.

## Features

### 1. Sale Stages

- **Private Sale**: Tokens are sold at a starting price that gradually increases until the private sale token supply is depleted.
- **Pre-Sale**: Once the private sale is complete, the pre-sale begins at a higher starting price with a similar linear price increase.

### 2. Vesting

- Tokens purchased during the private sale are vested and released gradually according to the vesting schedule defined in the contract.

### 3. Staking

- The contract supports staking of tokens, allowing users to lock their tokens for a set period.

### 4. Emergency Withdrawals

- The contract includes emergency withdrawal mechanisms that allow the owner to withdraw tokens or funds if necessary, subject to a time lock.

### 5. Chainlink Price Feeds

- Chainlink Price Feeds are used to fetch the latest price data, which is used to calculate the token price during sales.

### 6. Pausable Contract

- The contract can be paused or unpaused by the owner to prevent or allow token purchases.

## Functions

### Constructor

```solidity
constructor(address[] memory _priceFeeds) ERC20("Bettoken", "BETT") Ownable(msg.sender)
```

Initializes the contract with the provided Chainlink price feeds and mints the total token supply.

### Start Private Sale

```solidity
function startPrivateSale() external onlyOwner
```

Starts the private sale stage if all conditions are met.

### Start Pre-Sale

```solidity
function startPreSale() external onlyOwner
```

Starts the pre-sale stage after the private sale has been completed.

### Buy Tokens

```solidity
function buyTokens(uint256 usdAmount) external payable nonReentrant whenNotPaused
```

Allows users to buy tokens during the active sale stage.

### Calculate Tokens

```solidity
function calculateTokens(uint256 usdAmount, uint256 startPrice, uint256 endPrice, uint256 soldTokens, uint256 totalTokens) internal pure returns (uint256)
```

Calculates the number of tokens that can be purchased based on the USD amount and current sale parameters.

### Create Vesting Schedule

```solidity
function createVestingSchedule(address beneficiary, uint256 amount, uint256 startTime, uint256 duration, uint256 interval) internal
```

Creates a vesting schedule for a beneficiary.

### Release Vested Tokens

```solidity
function releaseVestedTokens() external nonReentrant
```

Releases vested tokens to the caller based on their vesting schedule.

### Halt Sales

```solidity
function haltSales() external onlyOwner
```

Halts all token sales and pauses the contract.

### Emergency Withdraw

```solidity
function emergencyWithdraw(address tokenAddress, uint256 amount) external onlyOwner nonReentrant
```

Allows the owner to withdraw tokens from the contract in case of an emergency.

### Withdraw Funds

```solidity
function withdrawFunds() external onlyOwner nonReentrant
```

Allows the owner to withdraw ETH from the contract.

### Pause/Unpause Contract

```solidity
function pause() external onlyOwner
function unpause() external onlyOwner
```

Allows the owner to pause or unpause the contract.

## Events

- `PrivateSale(address indexed buyer, uint256 amount)`: Emitted when a purchase is made during the private sale.
- `PreSale(address indexed buyer, uint256 amount)`: Emitted when a purchase is made during the pre-sale.
- `TokensStaked(address indexed staker, uint256 amount, uint256 releaseTime)`: Emitted when tokens are staked.
- `VestedTokensReleased(address indexed beneficiary, uint256 amount)`: Emitted when vested tokens are released.
- `StageChanged(SaleStage newStage)`: Emitted when the sale stage is changed.
- `FundsWithdrawn(address indexed owner, uint256 amount)`: Emitted when funds are withdrawn from the contract.

## Security Features

- **Time-lock Mechanism**: Critical functions are subject to a time lock to prevent rapid changes that could compromise security.
- **Pausable**: The contract can be paused by the owner to prevent unauthorized or unexpected actions.
- **Non-reentrancy**: All critical functions are protected against reentrancy attacks.


# Bettoken Smart Contract

Bettoken, ERC20 standardına dayalı, özel ve ön satışları destekleyen bir akıllı sözleşmedir. Sözleşme, kullanıcıların token satın almasına, vesting (hakediş) planları oluşturmasına, stake etmelerine ve fonları çekmelerine olanak tanır. Ayrıca Chainlink oracle'ları aracılığıyla fiyat verilerini entegre eder.

## Özellikler

- **ERC20 Token Standardı**: Bettoken, OpenZeppelin tarafından sağlanan ERC20 standardına dayanır.
- **Sahiplik Yönetimi (Ownable)**: OpenZeppelin'in Ownable modülü, yalnızca sahibin belirli işlemleri yapmasına izin verir.
- **Güvenlik ve Reentrancy Koruması (ReentrancyGuard)**: Tekrar saldırılarını (reentrancy attacks) önlemek için ReentrancyGuard kullanılır.
- **Pausable**: Sözleşme, gerektiğinde tüm işlemleri duraklatabilir (pause) veya duraklatmayı kaldırabilir (unpause).
- **Vesting**: Tokenler belirli bir süre boyunca hakediş (vesting) planı kapsamında kilitlenebilir.
- **Chainlink Oracle Entegrasyonu**: Fiyat verilerini Chainlink oracle'ları üzerinden alır ve bu verileri kullanarak satış fiyatlarını belirler.

## ABI (Application Binary Interface)

Sözleşmenin ABI'si aşağıdaki fonksiyonları içerir. Bu fonksiyonlar, sözleşmenin harici olarak çağrılabilir işlevlerini temsil eder.

### OpenZeppelin ERC20 Fonksiyonları

- **`name()`**: Token'ın adını döndürür.
- **`symbol()`**: Token'ın sembolünü döndürür.
- **`decimals()`**: Token'ın ondalık basamak sayısını döndürür.
- **`totalSupply()`**: Toplam arzı döndürür.
- **`balanceOf(address account)`**: Belirtilen adresin bakiyesini döndürür.
- **`transfer(address recipient, uint256 amount)`**: Tokenları bir adrese transfer eder.
- **`allowance(address owner, address spender)`**: Belirtilen harcama yetkisini döndürür.
- **`approve(address spender, uint256 amount)`**: Belirtilen miktarda token harcamak için onay verir.
- **`transferFrom(address sender, address recipient, uint256 amount)`**: Onaylanan tokenları bir adresten başka bir adrese transfer eder.

### Ownable Fonksiyonları

- **`owner()`**: Sözleşmenin sahibini döndürür.
- **`transferOwnership(address newOwner)`**: Sahipliği yeni bir adrese devreder.

### ReentrancyGuard Fonksiyonları

- **`nonReentrant()`**: Tekrar saldırılarına karşı koruma sağlar. Bu işlev, diğer harici işlev çağrılarını engellemek için kullanılabilir.

### Pausable Fonksiyonları

- **`pause()`**: Sözleşmeyi duraklatır.
- **`unpause()`**: Sözleşmeyi duraklatmadan çıkarır.

### Bettoken Özel Fonksiyonları

- **`constructor(address[] memory _priceFeeds)`**: Bettoken sözleşmesini başlatır ve Chainlink fiyat beslemelerini ayarlar.
- **`getLatestPrice()`**: Birden fazla Chainlink oracle'dan en son fiyatı alır ve ortalamasını döndürür.
- **`getTotalSupply()`**: Token'ın toplam arzını döndürür.
- **`startPrivateSale()`**: Özel satış aşamasını başlatır.
- **`startPreSale()`**: Ön satış aşamasını başlatır.
- **`buyTokens(uint256 usdAmount)`**: Belirtilen USD miktarına göre token satın alır.
- **`calculateTokens(uint256 usdAmount, uint256 startPrice, uint256 endPrice, uint256 soldTokens, uint256 totalTokens)`**: Satın alınabilecek token sayısını hesaplar.
- **`createVestingSchedule(address beneficiary, uint256 amount, uint256 startTime, uint256 duration, uint256 interval)`**: Belirtilen adres için bir hakediş planı oluşturur.
- **`releaseVestedTokens()`**: Çağrıcı için hakediş yapılmış tokenları serbest bırakır.
- **`haltSales()`**: Tüm token satışlarını durdurur ve sözleşmeyi duraklatır.
- **`emergencyWithdraw(address tokenAddress, uint256 amount)`**: Acil durumda belirtilen tokenları kontrattan çeker.
- **`withdrawFunds()`**: Sözleşmeden fonları çeker.

## Fonksiyonların Açıklamaları

### getLatestPrice()
- **Açıklama**: Birden fazla Chainlink oracle'dan en son fiyatı alır ve ortalamasını hesaplar.
- **Dönüş Tipi**: `uint256`
- **Örnek Kullanım**:
  ```solidity
  uint256 latestPrice = bettoken.getLatestPrice();


## License

This project is licensed under the MIT License.
