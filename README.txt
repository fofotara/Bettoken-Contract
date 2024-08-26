BETTOKEN 




# Bettoken Smart Contract

Bettoken, Ethereum blockchain üzerinde geliştirilmiş, özel ve halka açık satışları destekleyen bir ERC-20 token kontratıdır. Bu kontrat, yatırımcılara token satın alımında çeşitli satış aşamaları sunar ve belirli bir süre için token stake etme ve vesting yapma özelliklerine sahiptir.

## Kontrat Özellikleri

- **ERC20 Uyumluluğu**: Bettoken, ERC20 standartlarına uygun olarak geliştirilmiştir.
- **Satış Aşamaları**: Özel (Private Sale) ve Halka Açık (Pre-Sale) satış aşamaları sunar.
- **Vesting ve Stake**: Kullanıcılar, belirli bir süre için token stake edebilir ve vesting periyodu sonunda token'larını alabilirler.
- **Oracle Desteği**: Fiyat bilgilerini almak için birden fazla Chainlink Price Oracle kullanır.
- **BSC Bridge**: Token'ların Binance Smart Chain (BSC) ile Ethereum arasında köprü (bridge) oluşturularak transfer edilmesine olanak tanır.

## Fonksiyonlar

### 1. `constructor(address[] memory _priceFeeds)`
Kontratın başlatıcısıdır. Total Supply miktarını mint eder ve belirtilen Chainlink oracle adreslerini kullanarak fiyat verilerini almaya başlar.

**Parametreler:**
- `_priceFeeds`: Fiyat verilerini almak için kullanılacak Chainlink oracle adreslerinin listesi.

### 2. `getLatestPrice() public view returns (uint256)`
Birden fazla Chainlink oracle'dan gelen fiyat verilerini alır ve ortalamasını döndürür.

**Dönüş Değeri:**
- Oracle'lardan alınan fiyatların ortalaması (`uint256`).

### 3. `startPrivateSale() external onlyOwner`
Private Sale aşamasını başlatır. Bu fonksiyon yalnızca kontrat sahibi tarafından çağrılabilir ve yalnızca kontrat NONE aşamasında iken çalıştırılabilir.

**Koşullar:**
- Satış aşaması `NONE` olmalıdır.
- Satış başlamadan önce satılmış token olmamalıdır.

### 4. `startPreSale() external onlyOwner`
Pre-Sale aşamasını başlatır. Bu fonksiyon yalnızca Private Sale tamamlandıktan sonra başlatılabilir.

**Koşullar:**
- Satış aşaması `PRIVATE` olmalıdır.
- Private Sale sırasında belirlenen tüm token'lar satılmış olmalıdır.

### 5. `buyTokens(uint256 usdAmount) external payable nonReentrant`
Kullanıcıların token satın almasını sağlar. Özel veya halka açık satış aşamasında çağrılabilir.

**Parametreler:**
- `usdAmount`: Satın almak istediğiniz token miktarı (USD cinsinden).

**Koşullar:**
- Satış aşaması aktif olmalıdır (Private Sale veya Pre-Sale).
- Satış aşamasına göre gerekli minimum ve maksimum satın alım limitleri sağlanmalıdır.

### 6. `calculatePrivateSaleTokens(uint256 usdAmount) internal view returns (uint256)`
Özel satış aşamasında belirtilen USD miktarına karşılık gelen token miktarını hesaplar.

**Parametreler:**
- `usdAmount`: Satın alınacak token'lar için harcanacak USD miktarı.

**Dönüş Değeri:**
- Belirtilen miktarda USD karşılığında alınabilecek token miktarı (`uint256`).

### 7. `calculatePreSaleTokens(uint256 usdAmount) internal view returns (uint256)`
Halka açık satış aşamasında belirtilen USD miktarına karşılık gelen token miktarını hesaplar.

**Parametreler:**
- `usdAmount`: Satın alınacak token'lar için harcanacak USD miktarı.

**Dönüş Değeri:**
- Belirtilen miktarda USD karşılığında alınabilecek token miktarı (`uint256`).

### 8. `stakeTokens(uint256 amount) external onlyOwner nonReentrant`
Kullanıcıların belirli bir süre boyunca token stake etmelerini sağlar. Bu fonksiyon yalnızca kontrat sahibi tarafından çalıştırılabilir.

**Parametreler:**
- `amount`: Stake edilecek token miktarı.

**Koşullar:**
- Stake edilecek miktar sıfırdan büyük olmalıdır.
- Kullanıcının yeterli bakiyesi olmalıdır.

### 9. `releaseVestedTokens() external nonReentrant`
Vesting süresi dolmuş olan token'ların serbest bırakılmasını sağlar.

**Koşullar:**
- Vesting süresi dolmuş olmalıdır.
- Kullanıcının serbest bırakılacak token miktarı olmalıdır.

### 10. `haltSales() external onlyOwner`
Tüm satışları durdurur ve satış aşamasını `NONE` durumuna geçirir.

**Koşullar:**
- Satış aşaması `PRIVATE` veya `PRESALE` olmalıdır.
- Tüm token'lar satılmış olmalıdır.

### 11. `emergencyWithdraw(address tokenAddress, uint256 amount) external onlyOwner nonReentrant`
Acil durumlarda belirtilen adresteki token'ların kontrat sahibine çekilmesini sağlar.

**Parametreler:**
- `tokenAddress`: Çekilmek istenen token'ın kontrat adresi.
- `amount`: Çekilmek istenen token miktarı.

### 12. `withdrawFunds() external onlyOwner nonReentrant`
Kontratta biriken tüm ETH bakiyesini kontrat sahibine çeker.

**Koşullar:**
- Yalnızca kontrat sahibi tarafından çalıştırılabilir.

### 13. `fallback() external payable`
Herhangi bir işlemde ETH gönderilmeye çalışılırsa bu fonksiyon devreye girer ve işlemi reddeder.

### 14. `receive() external payable`
ETH'nin doğrudan kontrata gönderilmesini engellemek için çalışır.

## BSC Bridge (Köprü) Fonksiyonu

Bettoken kontratı, Binance Smart Chain (BSC) ile Ethereum arasında köprü oluşturarak token transferi yapma yeteneğine sahiptir. Bu işlem, token'ların bir zincirden diğerine taşınmasını sağlar. Aşağıda, köprü fonksiyonlarının nasıl çalıştığı açıklanmıştır.

### BSC Bridge Mekanizması

#### 1. **Token Locking (Ethereum'da Kilitleme)**
Ethereum ağında bir köprü kontratı, token'ları kilitleyerek BSC'ye transfer etmek için hazırlık yapar.

#### 2. **Token Minting (BSC'de Mintleme)**
Kilitleme işlemi tamamlandığında, BSC'de bir karşılık token mint edilir. Bu token'lar, Ethereum'da kilitlenen token'larla birebir karşılık gelir.

#### 3. **Token Unlocking (BSC'de Kilit Açma)**
Kullanıcılar BSC'de mint ettikleri token'ları Ethereum'daki asıl token'larla değiştirmek istediklerinde, BSC'deki token'lar yakılır ve Ethereum'daki token'lar serbest bırakılır.

#### 4. **Token Releasing (Ethereum'da Serbest Bırakma)**
Kilit açma işlemi BSC'de tamamlandıktan sonra, Ethereum ağında kilitlenen token'lar serbest bırakılır ve kullanıcıya iade edilir.

### BSC Bridge İçin Kullanılan Fonksiyonlar

Köprü mekanizmasını Ethereum ve BSC arasında kurmak için kullanılacak belirli fonksiyonlar vardır. Aşağıda bu fonksiyonlar listelenmiştir:

- **lockTokens**: Token'ları Ethereum'da kilitler ve BSC'de mint edilmesi için hazırlık yapar.
- **releaseTokens**: Ethereum'da kilitli token'ları serbest bırakır.
- **mintTokens**: BSC'de kilitli token'lara karşılık gelen yeni token'ları mint eder.
- **burnTokens**: BSC'de mint edilen token'ları yakar ve Ethereum'da kilitli token'ların serbest bırakılması için hazırlık yapar.

## Lisans
Bu proje [MIT Lisansı](https://opensource.org/licenses/MIT) altında lisanslanmıştır.




1. Constructor (constructor(address _priceOracle)):
İşlevi: Kontrat ilk kez dağıtıldığında çalışır. Token adını ("Bettoken") ve sembolünü ("BETT") ayarlayarak toplam arzı belirler ve kontrata mint eder. Ayrıca, price oracle adresini ayarlamak için kullanılır.
Parametre:
_priceOracle: Fiyat verilerini almak için kullanılacak oracle kontratının adresi.
2. startPrivateSale():
İşlevi: Private Sale (Özel Satış) aşamasını başlatır. Bu fonksiyon sadece kontrat sahibi (owner) tarafından çağrılabilir.
Koşul: Sadece SaleStage.NONE durumunda çalıştırılabilir, yani henüz bir satış aşaması başlatılmamış olmalıdır.
3. startPreSale():
İşlevi: Pre-Sale (Ön Satış) aşamasını başlatır. Bu fonksiyon da sadece kontrat sahibi tarafından çağrılabilir.
Koşul: Özel Satış aşamasının tamamlanmış olması ve tüm özel satış tokenlerinin satılmış olması gereklidir (privateSaleSoldTokens == privateSaleTokens).
4. buyTokens(uint256 usdAmount):
İşlevi: Kullanıcıların USD cinsinden belirli bir tutar karşılığında token satın almasını sağlar. Satış aşamasına göre (Private Sale veya Pre-Sale) tokenleri satın alır.
Koşul: Satış aşaması başlamış olmalıdır (SaleStage.PRIVATE veya SaleStage.PRESALE).
Oracle Entegrasyonu: Bu fonksiyon, oracle’dan en son fiyat verisini alarak token fiyatını hesaplar ve kullanıcının satın alacağı token miktarını belirler.
5. calculatePrivateSaleTokens(uint256 usdAmount):
İşlevi: Özel Satış sırasında satın alınacak token miktarını hesaplar. USD cinsinden verilen tutara göre token sayısını belirler.
Koşul: Verilen USD tutarı (usdAmount) ve satılabilir token miktarı doğrulanır.
6. calculatePreSaleTokens(uint256 usdAmount):
İşlevi: Ön Satış sırasında satın alınacak token miktarını hesaplar. USD cinsinden verilen tutara göre token sayısını belirler.
Koşul: Verilen USD tutarı (usdAmount) ve satılabilir token miktarı doğrulanır.
7. stakeTokens(uint256 amount):
İşlevi: Kullanıcıların ellerindeki tokenleri kontrata stake etmelerini sağlar. Stake edilen tokenler için bir vesting süresi başlatılır.
Koşul: Kullanıcının staking işlemi için yeterli miktarda tokeni olmalıdır.
8. releaseVestedTokens():
İşlevi: Kullanıcıların vesting süresi tamamlandıktan sonra tokenlerini geri almalarını sağlar. Bu fonksiyon, vesting süresi dolduktan sonra çalıştırılabilir.
Koşul: Vesting süresi dolmuş olmalı ve kullanıcı için vesting bakiyesi sıfır olmamalıdır.
9. haltSales():
İşlevi: Satış sürecini durdurur. Özel veya Ön Satışta satılması gereken tüm tokenler satıldığında bu fonksiyon çalıştırılabilir. Sadece kontrat sahibi tarafından çağrılabilir.
10. withdrawFunds():
İşlevi: Kontrata yatırılan fonları (ETH) kontrat sahibine çeker. Satış işlemlerinden elde edilen ETH bakiyesi bu fonksiyon aracılığıyla kontrat sahibine aktarılır.
Koşul: Sadece kontrat sahibi bu fonksiyonu çağırabilir.
11. fallback():
İşlevi: Kontrata doğrudan ETH gönderilmesini engeller. Bu fonksiyon çalıştırıldığında işlem geri alınır (revert edilir).
12. receive():
İşlevi: ETH'nin doğrudan kontrata gönderilmesini engeller. Bu fonksiyon çalıştırıldığında işlem geri alınır (revert edilir).
Özet:
Satış Fonksiyonları: startPrivateSale, startPreSale, buyTokens, calculatePrivateSaleTokens, calculatePreSaleTokens
Staking Fonksiyonları: stakeTokens, releaseVestedTokens
Yönetim Fonksiyonları: haltSales, withdrawFunds
Güvenlik ve Oracle Fonksiyonları: getLatestPrice, fallback, receive
Bu fonksiyonlar, kontratın token satışını, staking işlemlerini ve yönetimsel işlevlerini yönetmek için kullanılır. Her bir fonksiyon, belirli bir işlevi yerine getirir ve belirli kurallar altında çalışır. Bu kontrat, temel olarak bir token satışı ve staking mekanizması sağlamak için tasarlanmıştır.