# Bettoken Akıllı Kontratı

Bu doküman, Bettoken (BETT) adlı ERC20 token'ı yöneten akıllı kontratın işlevlerini detaylı olarak açıklamaktadır. Bettoken, piyasa, takım, ön satış, özel satış ve airdrop gibi farklı dağıtım senaryolarını destekler. Ayrıca stake etme ve vesting gibi işlevler sunar.

## Kontratın Genel Özellikleri

- **Token İsmi**: Bettoken
- **Sembol**: BETT
- **Toplam Arz**: 1,000,000,000 BETT
- **Standartlar**: ERC20, ERC20Pausable, ERC20Permit
- **Gelişmiş Güvenlik Özellikleri**: ReentrancyGuard, Ownable

## Dağıtım Detayları

- **Piyasa için Ayrılan**: 500,000,000 BETT (%50)
- **Takım için Ayrılan**: 100,000,000 BETT (%10)
- **Ön Satış için Ayrılan**: 150,000,000 BETT (%15)
- **Özel Satış için Ayrılan**: 50,000,000 BETT (%5)
- **Airdrop ve Bonuslar için Ayrılan**: 50,000,000 BETT (%5)
- **Yakılacak Tokenlar**: 150,000,000 BETT (%15)

## Fonksiyonlar

### Whitelist Fonksiyonları

1. **`addToWhitelist(address user)`**: Bir adresi whitelist'e ekler. Yalnızca kontrat sahibi bu işlemi yapabilir.
2. **`removeFromWhitelist(address user)`**: Bir adresi whitelist'ten çıkarır. Yalnızca kontrat sahibi bu işlemi yapabilir.
3. **`addToWhitelistBulk(address[] calldata users)`**: Birden fazla adresi whitelist'e toplu olarak ekler. Yalnızca kontrat sahibi bu işlemi yapabilir.
4. **`isWhitelisted(address user)`**: Belirli bir adresin whitelist'te olup olmadığını kontrol eder.

### Private Sale Fonksiyonları

1. **`buyTokensPrivateSale(uint256 usdAmount, string calldata affiliateCode)`**: Kullanıcıların private sale döneminde BETT token satın almasına olanak tanır. Yalnızca whitelist'te olan adresler bu işlemi yapabilir.
   - Minimum yatırım miktarı: 1000 USD
   - Tokenlar, USD cinsinden belirtilen miktara göre hesaplanır.
   - Affiliate kodu kullanılarak ödül kazanılabilir.

2. **`completePrivateSale()`**: Private sale dönemini tamamlar. Yalnızca kontrat sahibi bu işlemi yapabilir.

### Pre-Sale Fonksiyonları

1. **`buyTokensPreSale(uint256 usdAmount, string calldata affiliateCode)`**: Kullanıcıların pre-sale döneminde BETT token satın almasına olanak tanır.
   - Minimum yatırım miktarı: 100 USD
   - Maksimum yatırım miktarı: 3000 USD
   - Kullanıcılar, pre-sale döneminde maksimum satın alım miktarını geçemez.

2. **`completePreSale()`**: Pre-sale dönemini tamamlar. Yalnızca kontrat sahibi bu işlemi yapabilir.

### Stake ve Vesting Fonksiyonları

1. **`stakeTokens(uint256 amount)`**: Kullanıcıların tokenlarını stake etmelerini sağlar. Stake edilen tokenlar, belirli bir süre sonra vesting sürecine girer.
   - Minimum stake süresi: 1 yıl
   - Vesting süresi: 6 ay

2. **`releaseVestedTokens()`**: Kullanıcıların vesting süreci sona erdiğinde tokenlarını serbest bırakmalarını sağlar.

### Token Yakımı

1. **`addToPendingBurn(uint256 amount)`**: Yakılacak token miktarını bekleyen listeye ekler. Yalnızca kontrat sahibi bu işlemi yapabilir.
2. **`burnPendingTokens()`**: Bekleyen tokenları yakar. Yalnızca kontrat sahibi bu işlemi yapabilir.

### Token ve Fon Çekme Fonksiyonları

1. **`withdrawTokens(uint256 amount)`**: Kontrattaki tokenları çekmek için kullanılır. Yalnızca kontrat sahibi bu işlemi yapabilir.
2. **`withdrawFunds()`**: Kontrattaki fonları (ETH) çekmek için kullanılır. Yalnızca kontrat sahibi bu işlemi yapabilir.

### Acil Durum Durdurma

1. **`emergencyPause()`**: Kontratı acil durumlarda duraklatmak için kullanılır. Yalnızca kontrat sahibi bu işlemi yapabilir.
2. **`unpause()`**: Duraklatılmış kontratı yeniden etkinleştirir. Yalnızca kontrat sahibi bu işlemi yapabilir.

### Satın Alım Miktarı Hesaplama

1. **`calculateTokensPrivateSale(uint256 usdAmount)`**: Private sale sırasında USD miktarına göre satın alınacak token miktarını hesaplar.
2. **`calculateTokensPreSale(uint256 usdAmount)`**: Pre-sale sırasında USD miktarına göre satın alınacak token miktarını hesaplar.

## Güvenlik Önlemleri

- **ReentrancyGuard**: Yeniden giriş saldırılarına karşı koruma sağlamak için kullanılır.
- **CEI Prensibi**: Check-Effects-Interactions (Kontrol-Etkiler-Etkileşimler) deseni kullanılarak fonksiyonlar yapılandırılmıştır. Bu, fonksiyon içindeki dış etkileşimlerin minimum riskle gerçekleştirilmesini sağlar.
- **nonReentrant Modifier**: ReentrancyGuard ile birlikte, kritik fonksiyonlarda yeniden giriş saldırılarına karşı ekstra güvenlik sağlar.

## Kullanılan Kütüphaneler ve Modüller

- **OpenZeppelin ERC20**: Token standardı.
- **OpenZeppelin Ownable**: Yalnızca kontrat sahibinin belirli işlemleri gerçekleştirmesini sağlar.
- **OpenZeppelin ReentrancyGuard**: Reentrancy saldırılarını önlemek için kullanılır.
- **OpenZeppelin ERC20Pausable**: Kontratı duraklatma ve yeniden etkinleştirme özellikleri sunar.
- **OpenZeppelin ERC20Permit**: Onayları zincir üzerinde imzalama özelliği sunar (EIP-2612).

## Notlar

- **Affiliate Sistemi**: Kullanıcılar affiliate kodu kullanarak token satın alabilir ve bu kodu paylaşarak ödül kazanabilir.
- **Yakılacak Tokenlar**: Tokenların belirli bir kısmı, arzı azaltmak için yakılmak üzere ayrılmıştır.
- **Takım Tokenları**: Takım tokenları 1 yıl süreyle kilitlenmiştir ve bu sürenin sonunda serbest bırakılır.

## Lisans

Bu kontrat MIT lisansı ile lisanslanmıştır.