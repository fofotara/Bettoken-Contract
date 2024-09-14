# Bettoken Akıllı Kontratı

Bu kontrat, **Bettoken** adında bir ERC20 tabanlı token yönetim kontratıdır. Kontratta airdrop, private sale, pre-sale, vesting gibi işlemleri gerçekleştiren fonksiyonlar bulunur.

## Kontrat Özeti

- **Toplam Arz (TOTAL_SUPPLY)**: 1 milyar BETT token.
- **Airdrop**: Token dağılımının %5'i airdrop ve bonuslar için ayrılmıştır.
- **Private Sale**: Token dağılımının %3.88'i private sale için ayrılmıştır.
- **Pre-Sale**: Token dağılımının %16.11'i pre-sale için ayrılmıştır.

---

## Fonksiyonlar

### 1. **addToWhitelist**

Whitelist'e bir adres ekler.

**Girişler**:
- `_address (address)`: Whitelist'e eklenecek adres.

**Çıkışlar**: Yok.

---

### 2. **removeFromWhitelist**

Whitelist'ten bir adresi çıkarır.

**Girişler**:
- `_address (address)`: Whitelist'ten çıkarılacak adres.

**Çıkışlar**: Yok.

---

### 3. **buyTokensPrivateSale**

Private sale'de token satın alınmasını sağlar. Yalnızca whitelist'teki adresler tarafından kullanılabilir.

**Girişler**:
- `usdAmount (uint256)`: Satın alınacak token miktarını belirtir.
- `affiliateCode (string)`: Affiliate kodu. İsteğe bağlıdır.

**Çıkışlar**: Yok.

---

### 4. **buyTokensPreSale**

Pre-sale'de token satın alınmasını sağlar.

**Girişler**:
- `usdAmount (uint256)`: Satın alınacak token miktarını belirtir.
- `affiliateCode (string)`: Affiliate kodu. İsteğe bağlıdır.

**Çıkışlar**: Yok.

---

### 5. **startAirdrop**

Airdrop dönemini başlatır.

**Girişler**:
- `_startTime (uint256)`: Airdrop'un başlama zamanı (timestamp).
- `_endTime (uint256)`: Airdrop'un bitiş zamanı (timestamp).

**Çıkışlar**: Yok.

---

### 6. **endAirdrop**

Airdrop'u sonlandırır.

**Girişler**: Yok.

**Çıkışlar**: Yok.

---

### 7. **setAirdropEligibleBatch**

Airdrop için uygun olan adresleri toplu olarak belirler.

**Girişler**:
- `recipients (address[])`: Uygun olan adreslerin listesi.
- `batchSize (uint256)`: Batch boyutu.
- `batchIndex (uint256)`: İşlenecek batch'in indeksi.

**Çıkışlar**: Yok.

---

### 8. **distributeAirdropBatch**

Airdrop tokenlarını toplu olarak dağıtır.

**Girişler**:
- `recipients (address[])`: Token alacak adreslerin listesi.
- `amount (uint256)`: Her bir adres için dağıtılacak token miktarı.
- `batchSize (uint256)`: Batch boyutu.
- `batchIndex (uint256)`: İşlenecek batch'in indeksi.

**Çıkışlar**: Yok.

---

### 9. **releaseTeamTokens**

Takım tokenlarını serbest bırakır. Sadece takım tokenlarının kilit süresi dolduğunda kullanılabilir.

**Girişler**: Yok.

**Çıkışlar**: Yok.

---

### 10. **endSale**

Satışı sonlandırır. Satış bittiğinde kontrat duraklatılır.

**Girişler**: Yok.

**Çıkışlar**: Yok.

---

### 11. **createVestingSchedule**

Bir kullanıcı için vesting takvimi oluşturur. Bu fonksiyon `internal` olarak tanımlandığı için yalnızca kontrat içinden çağrılabilir.

**Girişler**:
- `beneficiary (address)`: Tokenların sahibi.
- `amount (uint256)`: Vesting yapılacak token miktarı.
- `startTime (uint256)`: Vesting başlangıç zamanı.
- `duration (uint256)`: Vesting süresi.
- `interval (uint256)`: Vesting'in gerçekleşeceği aralık.

**Çıkışlar**: Yok.

---

### 12. **releaseVestedTokens**

Vesting altında olan tokenları serbest bırakır.

**Girişler**: Yok.

**Çıkışlar**: Yok.

---

### 13. **withdrawTokens**

Kontrattaki tokenları çekmeye yarar.

**Girişler**:
- `amount (uint256)`: Çekilecek token miktarı.

**Çıkışlar**: Yok.

---

### 14. **withdrawFunds**

Kontrattaki ETH fonlarını çekmeye yarar.

**Girişler**: Yok.

**Çıkışlar**: Yok.

---

### 15. **emergencyPause**

Acil durumlar için kontratı duraklatır. Bu işlem, yalnızca kontrat sahibi tarafından çağrılabilir.

**Girişler**: Yok.

**Çıkışlar**: Yok.

---

### 16. **unpause**

Durdurulan kontratı tekrar çalışır hale getirir. Bu işlem, yalnızca kontrat sahibi tarafından çağrılabilir.

**Girişler**: Yok.

**Çıkışlar**: Yok.

---

### 17. **calculateTokensPrivateSale**

Private sale sırasında token miktarını hesaplar. Bu fonksiyon `internal` olup yalnızca kontrat içinde çağrılabilir.

**Girişler**:
- `usdAmount (uint256)`: USD cinsinden satın alma miktarı.

**Çıkışlar**:
- `(uint256)`: Hesaplanan token miktarı.

---

### 18. **calculateTokensPreSale**

Pre-sale sırasında token miktarını hesaplar. Bu fonksiyon `internal` olup yalnızca kontrat içinde çağrılabilir.

**Girişler**:
- `usdAmount (uint256)`: USD cinsinden satın alma miktarı.

**Çıkışlar**:
- `(uint256)`: Hesaplanan token miktarı.

---

### 19. **getTotalPrivateSaleSoldTokens**

Private sale sırasında satılan toplam token miktarını döndürür.

**Girişler**: Yok.

**Çıkışlar**:
- `(uint256)`: Satılan toplam token miktarı.

---

### 20. **getTotalPreSaleSoldTokens**

Pre-sale sırasında satılan toplam token miktarını döndürür.

**Girişler**: Yok.

**Çıkışlar**:
- `(uint256)`: Satılan toplam token miktarı.

---

### 21. **getAffiliateReward**

Belirli bir affiliate adresine ait ödül miktarını döndürür.

**Girişler**:
- `affiliate (address)`: Affiliate adresi.

**Çıkışlar**:
- `(uint256)`: Affiliate ödül miktarı.

---

### 22. **fallback**

ETH transferlerini reddeder. Harici bir transfer işlemi gerçekleştiğinde çağrılır.

**Girişler**: Yok.

**Çıkışlar**: Yok.

---

### 23. **receive**

ETH transferlerini reddeder. ETH transferi gönderildiğinde çağrılır.

**Girişler**: Yok.

**Çıkışlar**: Yok.
