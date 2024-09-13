# Bettoken Smart Contract

Bu README dosyası, Bettoken akıllı kontratının fonksiyonlarını ve kullanımını açıklar.

## Kontrat Genel Bakış

Bettoken, ERC20 token standardını uygulayan, özel satış ve ön satış mekanizmaları içeren, affiliate sistemine sahip ve whitelist özelliği bulunan bir Ethereum akıllı kontratıdır.

## Fonksiyonlar

### Yapıcı (Constructor)

```solidity
constructor()
```

- Kontratı başlatır ve toplam token arzını (1 milyar BETT) oluşturur.
- Tüm tokenleri kontrat adresine mint eder.

### White List Fonksiyonları

#### addToWhiteList

```solidity
function addToWhiteList(address account) external onlyOwner
```

- Bir adresi whitelist'e ekler.
- Sadece kontrat sahibi tarafından çağrılabilir.

#### removeFromWhiteList

```solidity
function removeFromWhiteList(address account) external onlyOwner
```

- Bir adresi whitelist'ten çıkarır.
- Sadece kontrat sahibi tarafından çağrılabilir.

### Affiliate Sistem Fonksiyonları

#### addAffiliate

```solidity
function addAffiliate(address affiliate, string memory code) external onlyOwner
```

- Yeni bir affiliate adresi ve kodu ekler.
- Sadece kontrat sahibi tarafından çağrılabilir.

#### removeAffiliate

```solidity
function removeAffiliate(address affiliate) external onlyOwner
```

- Bir affiliate adresini ve kodunu siler.
- Sadece kontrat sahibi tarafından çağrılabilir.

### Satış Fonksiyonları

#### buyTokensPrivateSale

```solidity
function buyTokensPrivateSale(uint256 usdAmount, string memory affiliateCode) external payable nonReentrant whenNotPaused
```

- Özel satış sırasında token satın almak için kullanılır.
- Alıcı whitelist'te olmalıdır.
- Affiliate kodu kullanılabilir.

#### buyTokensPreSale

```solidity
function buyTokensPreSale(uint256 usdAmount, string memory affiliateCode) external payable nonReentrant whenNotPaused
```

- Ön satış sırasında token satın almak için kullanılır.
- Minimum ve maksimum satın alma miktarı sınırlamaları vardır.
- Affiliate kodu kullanılabilir.

### Token Hesaplama Fonksiyonları

#### calculateTokensPrivateSale

```solidity
function calculateTokensPrivateSale(uint256 usdAmount) public view returns (uint256)
```

- Özel satış sırasında belirli bir USD miktarı için alınabilecek token miktarını hesaplar.

#### calculateTokensPreSale

```solidity
function calculateTokensPreSale(uint256 usdAmount) public view returns (uint256)
```

- Ön satış sırasında belirli bir USD miktarı için alınabilecek token miktarını hesaplar.

## Önemli Notlar

- Kontrat, OpenZeppelin kütüphanelerini kullanarak güvenlik özelliklerini (ReentrancyGuard, Pausable) ve standart token fonksiyonlarını (ERC20, ERC20Permit) uygular.
- Token dağıtımı farklı kategorilere ayrılmıştır: piyasa, takım, ön satış, airdrop ve yakma.
- Affiliate sistemi, satışları teşvik etmek için kullanılır ve başarılı referanslar için ödüller verir.
- Whitelist sistemi, özel satışa katılımı kontrol etmek için kullanılır.
- Satış fiyatları, satılan token miktarına göre dinamik olarak artar.

Bu README, Bettoken akıllı kontratının temel işlevlerini ve özelliklerini özetlemektedir. Daha detaylı bilgi için lütfen kontrat kodunu inceleyin.